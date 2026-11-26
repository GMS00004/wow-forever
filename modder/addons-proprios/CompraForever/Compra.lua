local addon, ns = ...

-- Compra: acoes de um clique (CONTRATO secao 6). ns.proximaAcao() devolve { texto, executar } (ou so { texto } quando
-- ha algo em andamento, e nil quando nao ha o que fazer). Cada executar() roda dentro do OnClick do botao de acao.
-- Decisoes:
-- * O que o leilao entrega chega pelo correio: ns.estoque passa a somar o comprado que ainda nao apareceu nas bolsas
--   (S.correio), senao o plano refeito compraria tudo de novo. A contagem real das bolsas fica em estoqueBolsa.
-- * Vendedor, craft e venda sao assincronos: estado.pend mede o efeito pela contagem nas bolsas (BAG_UPDATE_DELAYED)
--   e so devolve o botao quando terminar (ou no prazo, ou em UI_ERROR_MESSAGE).
-- * Preco subiu: a escada do item sai de ns.scan ate o proximo scan (o plano refeito nao o usa).
-- * Correio gravado (secao 12.6): S.correio e o visto sao as tabelas de CompraForeverCharDB (ligadas no ADDON_LOADED),
--   entao um /reload depois de uma compra grande nao faz recomprar o que esta na caixa.
-- * Modalidade de rota (secao 12.5): plano com modo = 2. Leilao na ordem do passo, cotacao limitada pelo teto da rota;
--   no vendedor vende antes de comprar, e so o que o addon craftou na rota (contador gravado); o craft anda em lotes de
--   ate 20 do passo atual, intermediarios primeiro, e para quando a pericia chega ao fim do passo. Encantamento sem item
--   fica a mao.

local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil

local TOLERANCIA = 1.02
local LOTE_ROTA = 20             -- crafts do passo atual por clique, na rota
local IDADE_CAIXA = 60           -- s: entrada do correio mais nova que isso nao baixa pela contagem da caixa
local VALIDADE_CORREIO = 30 * 86400

ns.sessao = { comprado = {}, craftado = {}, vendido = {}, lotes = {}, principal = {}, revenda = {}, correio = {}, vigiaComprado = {}, postado = {} }
local S = ns.sessao
local estado = {}          -- cot, lote, busca, pend, msg, aviso
local aberto = { ah = false, vend = false, prof = false, mail = false, trainer = false }
local visto = {}           -- id -> contagem nas bolsas na ultima conciliacao do correio (gravado: correioVisto)
local correioEm = {}       -- id -> hora da ultima compra que foi para o correio (gravado: correioEm)

local function dados() return rawget(_G, "CompraForeverDados") or {} end
local function atualizar() if ns.atualizarPainel then ns.atualizarPainel() end end

local estoqueBolsa = ns.estoque
ns.estoqueBolsa = estoqueBolsa
function ns.estoque(id)
  return estoqueBolsa(id) + (S.correio[id] or 0)
end

-- Rota: dados e contadores (secoes 12.1 e 12.2) -------------------------------------------------------

local function rotaPlano()
  local p = ns.plano
  if p and p.modo == 2 and type(p.rota) == "table" then return p, p.rota end
  return nil
end

local function rotaDados(slug)
  local r = dados().rotas
  local pr = r and r.profs
  return slug and pr and pr[slug] or nil
end

local function itemRota(id)
  local r = dados().rotas
  return r and r.itens and r.itens[id] or nil
end

-- CompraForeverCharDB.rota[slug], criado se faltar
local function contadores(slug)
  if not slug or type(CompraForeverCharDB) ~= "table" then return nil end
  local db = CompraForeverCharDB
  if type(db.rota) ~= "table" then db.rota = {} end
  local c = db.rota[slug]
  if type(c) ~= "table" then c = {}; db.rota[slug] = c end
  if type(c.credito) ~= "table" then c.credito = {} end
  if type(c.vendido) ~= "table" then c.vendido = {} end
  if type(c.craftado) ~= "table" then c.craftado = {} end
  if type(c.gasto) ~= "number" then c.gasto = 0 end
  if type(c.inicio) ~= "number" then c.inicio = time() end
  return c
end

local function somarGasto(valor)
  local _, R = rotaPlano()
  if not R or type(valor) ~= "number" or valor <= 0 then return end
  local c = contadores(R.prof)
  if c then c.gasto = c.gasto + floor(valor) end
end

-- Contexto -------------------------------------------------------------------------------------------

local function ehLW(info)
  return type(info) == "table" and (info.professionName == "Leatherworking" or info.parentProfessionName == "Leatherworking")
end

-- a janela de profissao aberta e do proprio personagem, pronta
local function janelaPronta()
  if not aberto.prof then return false end
  local T = C_TradeSkillUI
  if type(T) ~= "table" then return false end
  if T.IsTradeSkillReady and not T.IsTradeSkillReady() then return false end
  if (T.IsTradeSkillLinked and T.IsTradeSkillLinked()) or (T.IsTradeSkillGuild and T.IsTradeSkillGuild())
    or (T.IsNPCCrafting and T.IsNPCCrafting()) then return false end
  return true
end

-- slug da profissao da janela (secao 12.3); sem o Nucleo novo, so Leatherworking, como antes
local function slugJanela()
  if not janelaPronta() then return nil end
  if ns.slugDaJanela then return ns.slugDaJanela() end
  local T = C_TradeSkillUI
  if ehLW(T.GetBaseProfessionInfo and T.GetBaseProfessionInfo()) or ehLW(T.GetChildProfessionInfo and T.GetChildProfessionInfo()) then
    return "leatherworking"
  end
  return nil
end

-- prof: a janela aberta e a da profissao do modo (no lucro, Leatherworking, como antes)
function ns.contexto()
  local slug = slugJanela()
  local doModo = (ns.profDoModo and ns.profDoModo()) or "leatherworking"
  return { ah = aberto.ah, vend = aberto.vend, prof = slug ~= nil and slug == doModo, profSlug = slug,
           mail = aberto.mail, trainer = aberto.trainer }
end

-- cotacao, lote, busca de item ou pendencia no meio: a vigia nao busca agora
function ns.compraOcupada()
  return (estado.cot or estado.lote or estado.busca or estado.pend) ~= nil or (ns.vendaOcupada and ns.vendaOcupada()) == true
end

function ns.mensagem()
  local a = estado.aviso
  if a and a.scan == ns.scan then return a.texto end
  return estado.msg or (ns.venda and ns.venda.msg) or (ns.caca and ns.caca.msg)
end

-- Registro do que foi comprado --------------------------------------------------------------------------

local function consumirEm(l, qtd, leilao)
  if leilao then
    for i, d in ipairs(l) do
      if d.leilao == leilao then table.remove(l, i) break end
    end
    return
  end
  local falta, i = qtd, 1
  while falta > 0 and l[i] do
    local d = l[i]
    if d.inteiro then
      i = i + 1
    elseif d.qtd <= falta then
      falta = falta - d.qtd
      table.remove(l, i)
    else
      d.qtd = d.qtd - falta
      falta = 0
    end
  end
end

-- consome da escada do scan e da escada da vigia (podem ser a mesma tabela: consome uma vez so)
local function consumir(id, qtd, leilao)
  local sc = ns.scan
  local a = sc and sc.escadas and sc.escadas[id]
  local b = ns.vigia and ns.vigia.escadas and ns.vigia.escadas[id]
  if a then consumirEm(a, qtd, leilao) end
  if b and b ~= a then consumirEm(b, qtd, leilao) end
end

local function compraFeita(id, qtd, leilao, vigia, valor, caca)
  S.comprado[id] = (S.comprado[id] or 0) + qtd
  if vigia then S.vigiaComprado[id] = (S.vigiaComprado[id] or 0) + qtd end
  S.correio[id] = (S.correio[id] or 0) + qtd
  correioEm[id] = time()
  visto[id] = estoqueBolsa(id)
  for _, r in ipairs(ns.plano and ns.plano.revenda or {}) do
    if r.id == id then S.revenda[id] = true end
  end
  if not vigia and not caca then somarGasto(valor) end
  consumir(id, qtd, leilao)
  estado.msg = nil
  if ns.vigiaAvaliar then ns.vigiaAvaliar() end
  if (vigia or caca) and not ns.scan then atualizar() else ns.replanejar() end
end

-- o que o correio ja entregou deixa de contar como pendente
local function conciliarCorreio()
  for id, q in pairs(S.correio) do
    local c = estoqueBolsa(id)
    local antes = visto[id] or c
    if c > antes then
      q = max(0, q - (c - antes))
      S.correio[id] = q > 0 and q or nil
    end
    visto[id] = c
  end
end

-- correio gravado (secao 12.6): as tabelas da sessao passam a ser as do personagem; entrada com mais de 30 dias sai
local function ligarCorreio()
  local db = CompraForeverCharDB
  if type(db) ~= "table" then return end
  if type(db.correio) ~= "table" then db.correio = {} end
  if type(db.correioVisto) ~= "table" then db.correioVisto = {} end
  if type(db.correioEm) ~= "table" then db.correioEm = {} end
  for id, q in pairs(S.correio) do
    if db.correio[id] == nil then db.correio[id] = q end
  end
  S.correio = db.correio
  visto = db.correioVisto
  correioEm = db.correioEm
  local agora = time()
  for id, em in pairs(correioEm) do
    if type(em) ~= "number" or agora - em > VALIDADE_CORREIO then
      S.correio[id], correioEm[id], visto[id] = nil, nil, nil
    end
  end
end

ns.ao("ADDON_LOADED", function(nome)
  if nome == addon then ligarCorreio() end
end)

-- caixa de correio aberta e inteira na tela: o pendente de cada item nao passa do que os anexos somam (so para baixo, e
-- so nas entradas com mais de IDADE_CAIXA segundos, para nao apagar uma carta ainda a caminho)
local function conciliarCaixa()
  local fn, fi = rawget(_G, "GetInboxNumItems"), rawget(_G, "GetInboxItem")
  if type(fn) ~= "function" or type(fi) ~= "function" then return end
  local ok, n, total = pcall(fn)
  if not ok or type(n) ~= "number" then return end
  if type(total) == "number" and total > n then return end
  local anexos = rawget(_G, "ATTACHMENTS_MAX_RECEIVE")
  if type(anexos) ~= "number" or anexos < 1 then anexos = 16 end
  local conta = {}
  for i = 1, n do
    for j = 1, anexos do
      local ok2, _, id, _, q = pcall(fi, i, j)
      if ok2 and type(id) == "number" then conta[id] = (conta[id] or 0) + (tonumber(q) or 1) end
    end
  end
  local agora, mudou = time(), false
  for id, q in pairs(S.correio) do
    local em = correioEm[id] or 0
    local tem = conta[id] or 0
    if agora - em >= IDADE_CAIXA and tem < q then
      S.correio[id] = tem > 0 and tem or nil
      mudou = true
    end
  end
  if mudou then ns.replanejar() end
end

-- Pendencia medida pelas bolsas ----------------------------------------------------------------------------

-- pericia da janela de profissao aberta (a do filho, senao a da base), ou nil
local function periciaJanela()
  local T = C_TradeSkillUI
  if type(T) ~= "table" then return nil end
  for _, f in ipairs({ T.GetChildProfessionInfo, T.GetBaseProfessionInfo }) do
    if type(f) == "function" then
      local ok, info = pcall(f)
      if ok and type(info) == "table" and type(info.skillLevel) == "number" and info.skillLevel > 0 then return info.skillLevel end
    end
  end
  return nil
end

-- fim de um lote da rota: a pericia gravada sobe para a da janela, mesmo sem evento de pericia (secao 12.5)
local function periciaDoLote(pr)
  if not (pr and pr.slug) or type(CompraForeverCharDB) ~= "table" then return end
  if not (janelaPronta() and slugJanela() == pr.slug) then return end
  local n = periciaJanela()
  local prof = CompraForeverCharDB.prof
  local reg = type(prof) == "table" and prof[pr.slug]
  if n and type(reg) == "table" and n > (reg.pericia or 0) then
    reg.pericia = n
    reg.em = time()
  end
end

local function terminarPend()
  local p = estado.pend
  if not p then return end
  estado.pend = nil
  if p.rota then periciaDoLote(p.rota) end
  ns.replanejar()
end

local function progresso()
  local p = estado.pend
  if not p then return end
  local tudo = true
  for _, it in ipairs(p.itens) do
    local d = floor(((estoqueBolsa(it.id) - it.base) * it.sinal) / it.por)
    d = max(0, min(d, it.meta))
    if d > it.creditado then
      it.credito(d - it.creditado)
      it.creditado = d
    end
    if d < it.meta then tudo = false end
  end
  if tudo then terminarPend() end
end

local function iniciarPend(texto, itens, prazo)
  local p = { texto = texto, itens = itens }
  for _, it in ipairs(itens) do
    it.base, it.creditado, it.sinal, it.por = estoqueBolsa(it.id), 0, it.sinal or 1, it.por or 1
  end
  estado.pend = p
  C_Timer.After(prazo, function()
    if estado.pend == p then
      progresso()
      if estado.pend == p then terminarPend() end
      atualizar()
    end
  end)
end

-- Leilao ---------------------------------------------------------------------------------------------

local function textoLote(row)
  local feitos = S.lotes[row.id] or 0
  return "Buy " .. row.nome .. " lot " .. (feitos + 1) .. "/" .. (feitos + #row.lotes)
end

local function buscarItem(row)
  local b = { id = row.id, nome = row.nome }
  estado.busca = b
  estado.msg = nil
  local ordem = Enum and Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0
  C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(row.id), { { sortOrder = ordem, reverseSort = false } }, false)
  C_Timer.After(8, function()
    if estado.busca == b then
      estado.busca = nil
      estado.msg = "No answer: try again"
      atualizar()
    end
  end)
end

local function iniciarCotacao(row)
  local c = { id = row.id, nome = row.nome, qtd = row.qtd, custo = row.custo, fase = "cotando", row = row, t0 = GetTime() }
  estado.cot = c
  estado.msg = nil
  C_Timer.After(20, function()
    if estado.cot == c and c.fase ~= "confirmar" then
      estado.cot = nil
      estado.msg = "No answer: try again"
      atualizar()
    end
  end)
  C_AuctionHouse.StartCommoditiesPurchase(row.id, row.qtd)
end

local function confirmar()
  local c = estado.cot
  if not c or c.fase ~= "confirmar" then return end
  c.fase = "comprando"
  estado.msg = nil
  c.tConf = GetTime()
  -- caca (secao 13.4): a fila do cliente esta livre com a compra pendente? Amostra a 0,5 s e a 1 s do aperto
  if c.row and c.row.caca then
    for _, dt in ipairs({ 0.5, 1 }) do
      C_Timer.After(dt, function()
        if estado.cot == c and c.fase == "comprando" then
          c.livre = c.livre or {}
          c.livre[#c.livre + 1] = { em = dt, livre = C_AuctionHouse.IsThrottledMessageSystemReady() == true }
          atualizar()
        end
      end)
    end
  end
  C_AuctionHouse.ConfirmCommoditiesPurchase(c.id, c.qtd)
end

-- tempos da caca (secao 13.4): cotacao, compra (aperto de confirmar ate a resposta) e a fila durante a compra
local function tempoCaca(c, res)
  if not (c and c.row and c.row.caca and ns.cacaTempo) then return end
  ns.cacaTempo({ cota = c.tCota, compra = c.tConf and (GetTime() - c.tConf) or nil, livre = c.livre, res = res })
end

-- buyout exato do leilao (o preco por unidade e arredondado para baixo; lance abaixo do buyout viraria lance, nao compra)
local function buyoutDe(id, leilao)
  local l = ns.scan and ns.scan.escadas and ns.scan.escadas[id]
  for _, d in ipairs(l or {}) do
    if d.leilao == leilao then return d.total end
  end
  return nil
end

local function comprarLote(row, lote)
  local valor = (row.vigia and lote.total) or buyoutDe(row.id, lote.leilao)
  if not valor then buscarItem(row) return end   -- sem o buyout exato: busca o item de novo, sem comprar
  local l = { id = row.id, nome = row.nome, leilao = lote.leilao, qtd = lote.qtd, vigia = row.vigia, valor = valor }
  estado.lote = l
  estado.msg = nil
  C_Timer.After(15, function()
    if estado.lote == l then
      estado.lote = nil
      estado.msg = "No answer: try again"
      atualizar()
    end
  end)
  C_AuctionHouse.PlaceBid(lote.leilao, valor)
end

local function acaoLeilao()
  local cot = estado.cot
  if cot then
    if cot.fase == "confirmar" then
      return { texto = "Confirm " .. cot.qtd .. " " .. cot.nome .. " (" .. ns.moeda(cot.total) .. ")", executar = confirmar }
    end
    return { texto = (cot.fase == "cotando" and "Quoting " or "Buying ") .. cot.qtd .. " " .. cot.nome }
  end
  if estado.lote then return { texto = "Buying " .. estado.lote.nome } end
  if estado.busca then return { texto = "Searching " .. estado.busca.nome } end
  -- caca ligada (secao 13): o botao e dela; na busca dela, o texto e o dela e nao "Scanning..."
  local ca = ns.cacaAcao and ns.cacaAcao()
  if ca and ns.caca and ns.caca.buscando then
    return { texto = ca.texto, executar = ca.reiniciar and function() ns.cacaReiniciar() end or nil }
  end
  if ns.scanEstado and ns.scanEstado.ocupado then return { texto = "Scanning..." } end
  -- postagem em andamento (Venda.lua): uma funcao de acao por clique, o Confirm no clique seguinte
  -- a postagem da isca e do botao dela (secao 13): nao toma o botao de acao
  local em = ns.venda and ns.venda.em
  if em and not em.p.isca then
    if em.fase == "confirmar" then
      return { texto = "Confirm post " .. em.p.qtd .. " " .. em.p.nome, executar = ns.vendaConfirmar }
    end
    return { texto = "Posting " .. em.p.nome }
  end
  -- caca: busca, cota ou mostra o motivo; vem antes da vigia, da venda e do plano
  if ca then
    if ca.row then return { texto = ca.texto, executar = function() iniciarCotacao(ca.row) end } end
    if ca.buscar then return { texto = ca.texto, executar = function() ns.cacaBuscar() end } end
    return { texto = ca.texto }
  end
  -- preco da vigia abaixo do teto: vem antes do plano
  local vrow = ns.vigiaOportunidade and ns.vigiaOportunidade()
  if vrow then
    if not vrow.inteiro then
      return { texto = "Buy " .. vrow.qtd .. " " .. vrow.nome .. " (" .. ns.moeda(vrow.custo) .. ") [WATCH]",
               executar = function() iniciarCotacao(vrow) end }
    end
    local lote = vrow.lotes[1]
    return { texto = textoLote(vrow) .. " (" .. ns.moeda(lote.preco * lote.qtd) .. ") [WATCH]",
             executar = function() comprarLote(vrow, lote) end }
  end
  -- postagem nova depois da oportunidade da vigia
  local p = ns.vendaProxima and ns.vendaProxima()
  if p then
    local dep = ns.vendaDeposito(p)
    return { texto = "Post " .. p.qtd .. " " .. p.nome .. " @ " .. ns.moeda(p.preco)
               .. (dep and (" (dep " .. ns.moeda(dep) .. ")") or "") .. " [SELL]",
             executar = function() ns.vendaExecutar(p) end }
  end
  -- compra primeiro o que custa mais: se um preco mudar depois, sobra menos comprado pela metade. Na rota, as linhas ja
  -- vem na ordem do passo (o trecho que cabe na bolsa e no dinheiro, secao 12.4).
  local ordem = {}
  for _, row in ipairs(ns.plano and ns.plano.leilao or {}) do ordem[#ordem + 1] = row end
  if not rotaPlano() then
    table.sort(ordem, function(x, y)
      if x.custo ~= y.custo then return x.custo > y.custo end
      return x.id < y.id
    end)
  end
  for _, row in ipairs(ordem) do
    if row.qtd > 0 then
      local lote = row.inteiro and row.lotes[1]
      if not row.inteiro then
        return { texto = "Buy " .. row.qtd .. " " .. row.nome .. " (" .. ns.moeda(row.custo) .. ")",
                 executar = function() iniciarCotacao(row) end }
      elseif lote and lote.leilao then
        return { texto = textoLote(row) .. " (" .. ns.moeda(lote.preco * lote.qtd) .. ")",
                 executar = function() comprarLote(row, lote) end }
      elseif lote then
        return { texto = "Refresh " .. row.nome, executar = function() buscarItem(row) end }
      end
    end
  end
  local a = estado.aviso
  if a and a.scan == ns.scan then return { texto = a.texto } end
  return nil
end

-- Quanto a cotacao pode passar do planejado: 2% mais metade do lucro do plano. Uma alta pequena come parte do lucro
-- mas ainda paga; nao vale largar a leva comprada pela metade por ela.
local function limiteCotacao(custo, row)
  if row and row.vigia then return row.precoMax * row.qtd end   -- vigia: o teto por unidade, sem folga
  if row and row.caca then return row.custo end   -- caca: nenhuma unidade acima do que a busca mostrou no alvo
  -- rota (secao 12.5): nunca acima do teto da rota (ja com a tolerancia) e no maximo 5% acima do planejado
  if row and row.teto and rotaPlano() then return min(row.qtd * row.teto, floor(custo * 1.05) + 1) end
  local lucro = ns.plano and ns.plano.totais and ns.plano.totais.lucro or 0
  return floor(custo * TOLERANCIA) + 1 + max(0, floor(lucro / 2))
end

ns.ao("COMMODITY_PRICE_UPDATED", function(unit, total)
  local c = estado.cot
  if not c or c.fase ~= "cotando" then return end
  c.tCota = GetTime() - (c.t0 or GetTime())
  if total <= limiteCotacao(c.custo, c.row) then
    c.fase, c.total = "confirmar", total
  elseif c.row and c.row.caca then
    -- outro comprou antes: cancela e busca de novo (encadeado no clique de cotar)
    tempoCaca(c, "moved")
    C_AuctionHouse.CancelCommoditiesPurchase()
    estado.cot = nil
    estado.msg = nil
    if ns.cacaPrecoMudou then ns.cacaPrecoMudou() end
  elseif c.row and c.row.vigia then
    -- acima do teto da vigia: so cancela; a escada guardada ficou velha e a proxima busca da vigia a refaz
    C_AuctionHouse.CancelCommoditiesPurchase()
    estado.cot = nil
    estado.msg = "Price rose above watch"
    if ns.vigiaInvalidar then ns.vigiaInvalidar(c.id) end
  else
    -- subiu demais: cancela, busca de novo so este item e refaz o plano com o que ja foi comprado em estoque
    C_AuctionHouse.CancelCommoditiesPurchase()
    estado.cot = nil
    local sc = ns.scan
    estado.aviso = { texto = "Price rose: re-checking " .. c.nome, scan = sc }
    local ok = ns.atualizarItens and ns.atualizarItens({ c.id }, function()
      estado.aviso = nil
      atualizar()
    end)
    if not ok then
      if sc and sc.escadas then sc.escadas[c.id] = nil end
      estado.aviso = { texto = "Price rose: Scan again", scan = sc }
      ns.replanejar()
    end
  end
  atualizar()
end)

-- a caca perde a escada quando a cotacao ou a compra falha: o proximo clique busca de novo
local function cacaFalhou(c)
  if c and c.row and c.row.caca and ns.cacaInvalidar then ns.cacaInvalidar() end
end

ns.ao("COMMODITY_PRICE_UNAVAILABLE", function()
  if not estado.cot then return end
  cacaFalhou(estado.cot)
  estado.cot = nil
  estado.msg = "Quote unavailable: try again"
  atualizar()
end)

ns.ao("COMMODITY_PURCHASE_SUCCEEDED", function()
  local c = estado.cot
  if not c or c.fase ~= "comprando" then return end
  estado.cot = nil
  local caca = c.row and c.row.caca
  tempoCaca(c, "ok")
  if caca and ns.cacaComprou then ns.cacaComprou(c.qtd, c.total) end
  compraFeita(c.id, c.qtd, nil, c.row and c.row.vigia, c.total, caca)
end)

ns.ao("COMMODITY_PURCHASE_FAILED", function()
  local c = estado.cot
  if not c then return end
  estado.cot = nil
  if c.row and c.row.caca and ns.cacaPerdeu then
    tempoCaca(c, "lost")
    estado.msg = nil
    ns.cacaPerdeu()
    atualizar()
    return
  end
  estado.msg = "Purchase failed: try again"
  atualizar()
end)

ns.ao("AUCTION_HOUSE_PURCHASE_COMPLETED", function(leilao)
  local l = estado.lote
  if not l or l.leilao ~= leilao then return end
  estado.lote = nil
  S.lotes[l.id] = (S.lotes[l.id] or 0) + 1
  compraFeita(l.id, l.qtd, l.leilao, l.vigia, l.valor)
end)

ns.ao("AUCTION_HOUSE_SHOW_ERROR", function(codigo)
  local l = estado.lote
  if estado.cot then
    local c = estado.cot
    estado.cot = nil
    -- caca: o erro do leilao na cotacao ou na confirmacao (no jogo, "Internal auction error" quando outro compra
    -- antes, visto pelo dono em 26/11/2026) conta como corrida perdida e busca de novo, como a compra recusada
    if c.row and c.row.caca and ns.cacaPerdeu then
      tempoCaca(c, "error")
      estado.msg = nil
      ns.cacaPerdeu()
      atualizar()
      return
    end
  elseif l then
    estado.lote = nil
    local E = Enum and Enum.AuctionHouseError
    if E and codigo == E.ItemNotFound then   -- o lote saiu do ar: nao tenta de novo
      consumir(l.id, l.qtd, l.leilao)
      estado.msg = "Lot gone: next"
      ns.replanejar()
      return
    end
  elseif not estado.busca then
    return
  end
  estado.busca = nil
  estado.msg = "Auction error: try again"
  atualizar()
end)

-- busca so do item (plano de full scan nao tem auctionID): troca a escada dele em ns.scan
ns.ao("ITEM_SEARCH_RESULTS_UPDATED", function(chave)
  local b = estado.busca
  if not b or type(chave) ~= "table" or chave.itemID ~= b.id then return end
  estado.busca = nil
  local A, sc, escada = C_AuctionHouse, ns.scan, {}
  for i = 1, A.GetNumItemSearchResults(chave) do
    local r = A.GetItemSearchResultInfo(chave, i)
    local q = r and r.quantity or 0
    if r and not r.containsOwnerItem and (r.buyoutAmount or 0) > 0 and q > 0 then
      escada[#escada + 1] = { preco = floor(r.buyoutAmount / q), qtd = q, leilao = r.auctionID, inteiro = true, total = r.buyoutAmount }
    end
  end
  table.sort(escada, function(x, y)
    if x.preco ~= y.preco then return x.preco < y.preco end
    return (x.leilao or 0) < (y.leilao or 0)
  end)
  if sc and sc.escadas then sc.escadas[b.id] = escada end
  ns.replanejar()
end)

-- Vendedor -------------------------------------------------------------------------------------------

local function indiceVendedor(id)
  for i = 1, (GetMerchantNumItems() or 0) do
    if GetMerchantItemID(i) == id then return i end
  end
  return nil
end

local function comprarVendedor()
  local itens, chamadas = {}, {}
  local _, R = rotaPlano()
  local cont = R and contadores(R.prof)
  for _, r in ipairs(ns.plano and ns.plano.vendedor or {}) do
    local i = indiceVendedor(r.id)
    if i and r.qtd > 0 then
      local id, unit = r.id, (r.custo or 0) / r.qtd
      itens[#itens + 1] = { id = id, meta = r.qtd, credito = function(d)
        S.comprado[id] = (S.comprado[id] or 0) + d
        if cont then cont.gasto = cont.gasto + floor(d * unit) end
      end }
      local resta = r.qtd
      local pilha = max(1, GetMerchantItemMaxStack(i) or 1)
      while resta > 0 do
        local n = min(resta, pilha)
        chamadas[#chamadas + 1] = { i, n }
        resta = resta - n
      end
    end
  end
  if #chamadas == 0 then return end
  estado.msg = nil
  iniciarPend("Buying at vendor...", itens, 3 + #chamadas)
  for _, c in ipairs(chamadas) do BuyMerchantItem(c[1], c[2]) end
end

-- preco de venda ao vendedor por unidade: na rota, pela tabela de itens da rota (secao 12.1); senao, a de lucro
local function vendeUn(id)
  if rotaPlano() then
    local it = itemRota(id)
    if it and it.vende then return it.vende end
  end
  local d = dados()
  return d.itens and d.itens[id] and d.itens[id].vende or 0
end

-- quanto de cada item pode ser vendido. Rota (secao 12.4): plano.rota.vender, que ja e o craftado pelo addon na rota
-- (gravado) menos o que os passos seguintes ainda pedem. Lucro: o craftado nesta sessao (ou o revendido comprado).
local function permitidos()
  local _, R = rotaPlano()
  local perm = {}
  if R then
    for id, n in pairs(R.vender or {}) do
      if type(n) == "number" and n > 0 then perm[id] = n end
    end
    return perm
  end
  local d = dados()
  for magia in pairs(S.principal) do
    local r = d.receitas and d.receitas[magia]
    if r then perm[r.produto] = (perm[r.produto] or 0) + (S.craftado[magia] or 0) * (r.qtd or 1) end
  end
  for id in pairs(S.revenda) do perm[id] = (perm[id] or 0) + (S.comprado[id] or 0) end
  for id, v in pairs(S.vendido) do
    if perm[id] then perm[id] = perm[id] - v end
  end
  return perm
end

-- produtos do plano que as bolsas 0-4 tem, limitados ao permitido
local function aVender()
  local perm = permitidos()
  local lista, n, valor = {}, 0, 0
  for b = 0, 4 do
    for s = 1, (C_Container.GetContainerNumSlots(b) or 0) do
      local id = C_Container.GetContainerItemID(b, s)
      local vende = id and vendeUn(id) or 0
      if id and vende > 0 and (perm[id] or 0) > 0 then
        local info = C_Container.GetContainerItemInfo(b, s)
        local q = info and info.stackCount or 1
        if q <= perm[id] then   -- UseContainerItem vende a pilha inteira: pilha maior que o permitido fica
          lista[#lista + 1] = { b = b, s = s, id = id, n = q }
          perm[id] = perm[id] - q
          n = n + q
          valor = valor + q * vende
        end
      end
    end
  end
  return lista, n, valor
end

local function vender()
  -- sem o vendedor aberto, UseContainerItem equiparia ou usaria o item: so vende com a janela dele na tela
  if not (aberto.vend and MerchantFrame and MerchantFrame:IsShown()) then return end
  local lista = aVender()
  if #lista == 0 then return end
  local por = {}
  for _, x in ipairs(lista) do por[x.id] = (por[x.id] or 0) + x.n end
  local _, R = rotaPlano()
  local cont = R and contadores(R.prof)
  local itens = {}
  for id, n in pairs(por) do
    itens[#itens + 1] = { id = id, meta = n, sinal = -1, credito = function(d)
      S.vendido[id] = (S.vendido[id] or 0) + d
      if cont then
        cont.credito[id] = max(0, (cont.credito[id] or 0) - d)
        cont.vendido[id] = (cont.vendido[id] or 0) + d
      end
    end }
  end
  estado.msg = nil
  iniciarPend("Selling...", itens, 3 + #lista)
  for _, x in ipairs(lista) do C_Container.UseContainerItem(x.b, x.s) end
end

local function linhasVendedor()
  local custo, n = 0, 0
  for _, r in ipairs(ns.plano and ns.plano.vendedor or {}) do
    if r.qtd > 0 and indiceVendedor(r.id) then
      custo = custo + r.custo
      n = n + 1
    end
  end
  return custo, n
end

local function acaoVendedor()
  if rotaPlano() then
    -- rota: vende primeiro (abre espaco e traz dinheiro), depois compra
    local _, itens, valor = aVender()
    if itens > 0 then
      return { texto = "Sell " .. itens .. " items (+" .. ns.moeda(valor) .. ")", executar = vender }
    end
    local custo, n = linhasVendedor()
    if n > 0 then return { texto = "Buy at vendor (" .. ns.moeda(custo) .. ")", executar = comprarVendedor } end
    return nil
  end
  local custo, n = linhasVendedor()
  if n > 0 then
    return { texto = "Buy thread/dye at vendor (" .. ns.moeda(custo) .. ")", executar = comprarVendedor }
  end
  local _, itens, valor = aVender()
  if itens > 0 then
    return { texto = "Sell " .. itens .. " items (+" .. ns.moeda(valor) .. ")", executar = vender }
  end
  return nil
end

-- Craftar ----------------------------------------------------------------------------------------------

local function vezes(r)
  local m
  for _, rg in ipairs(r.reagentes) do
    local k = floor(estoqueBolsa(rg[1]) / rg[2])
    if not m or k < m then m = k end
  end
  return m or 0
end

local function craftar(c, r, n, principal)
  local magia = c.magia
  estado.msg = nil
  iniciarPend("Crafting...", { { id = r.produto, meta = n, por = r.qtd or 1, credito = function(d)
    S.craftado[magia] = (S.craftado[magia] or 0) + d
    if principal then S.principal[magia] = true end
  end } }, 10 + 4 * n)
  C_TradeSkillUI.CraftRecipe(magia, n)
end

local function acaoCraft()
  local plano, d = ns.plano, dados()
  if not plano or not d.receitas then return nil end
  for pass = 1, 2 do
    local lista = pass == 1 and plano.fabricar or plano.crafts
    for _, c in ipairs(lista) do
      local r = d.receitas[c.magia]
      if r then
        local n = min(c.n, vezes(r))
        if n > 0 then
          return { texto = "Craft " .. n .. " " .. c.nome, executar = function() craftar(c, r, n, pass == 2) end }
        end
      end
    end
  end
  return nil
end

-- Craftar na rota (secao 12.5) -------------------------------------------------------------------------

-- a receita conhecida: a janela aberta diz (GetRecipeInfo); senao a gravada; a inicial vem com a profissao
local function conhecidaRota(slug, magia, r)
  if r and r.origem == "inicial" then return true end
  local T = C_TradeSkillUI
  if type(T) == "table" and T.GetRecipeInfo then
    local ok, info = pcall(T.GetRecipeInfo, magia)
    if ok and type(info) == "table" then return info.learned == true end
  end
  local db = CompraForeverCharDB
  local p = type(db) == "table" and type(db.prof) == "table" and db.prof[slug]
  return type(p) == "table" and type(p.ids) == "table" and p.ids[magia] == true
end

-- fonte de um item no trecho que contem a pericia `de`
local function fonteNoPasso(rr, de, id)
  for _, t in ipairs(rr and rr.trechos or {}) do
    if de >= t.de and de < t.ate then return t.fontes and t.fontes[id] or nil end
  end
  return nil
end

-- primeiro intermediario a fabricar para `n` crafts de `rec` (do nivel mais fundo), ou nil
local proximoFabrico
proximoFabrico = function(slug, rr, de, rec, n, prof)
  if prof >= 3 then return nil end
  for _, rg in ipairs(rec.reagentes or {}) do
    local id, q = rg[1], rg[2]
    local falta = q * n - estoqueBolsa(id)
    if falta > 0 then
      local f = fonteNoPasso(rr, de, id)
      local rf = f and f.f == "F" and f.magia and rr.receitas and rr.receitas[f.magia]
      if rf and conhecidaRota(slug, f.magia, rf) then
        local c = ceil(falta / max(1, rf.qtd or 1))
        local sub = proximoFabrico(slug, rr, de, rf, c, prof + 1)
        if sub then return sub end
        local k = min(c, vezes(rf))
        if k > 0 then return { magia = f.magia, r = rf, n = k } end
      end
    end
  end
  return nil
end

-- itens que o lote pede (reagentes da receita e dos intermediarios F), para o aviso do correio
local function idsDoLote(rr, de, rec, prof, acc)
  acc = acc or {}
  if prof >= 3 then return acc end
  for _, rg in ipairs(rec.reagentes or {}) do
    acc[rg[1]] = true
    local f = fonteNoPasso(rr, de, rg[1])
    local rf = f and f.f == "F" and f.magia and rr.receitas and rr.receitas[f.magia]
    if rf then idsDoLote(rr, de, rf, prof + 1, acc) end
  end
  return acc
end

-- o progresso da rota se mede pela queda do primeiro reagente que a receita nao produz (serve para produto que nao
-- empilha e para encantamento); sem reagente, pelo produto
local function craftarRota(slug, magia, r, n, principal, ate)
  local cont = contadores(slug)
  local function creditar(d)
    S.craftado[magia] = (S.craftado[magia] or 0) + d
    if cont then
      cont.craftado[magia] = (cont.craftado[magia] or 0) + d
      if r.produto then cont.credito[r.produto] = (cont.credito[r.produto] or 0) + d * (r.qtd or 1) end
    end
  end
  local rg
  for _, x in ipairs(r.reagentes or {}) do
    if x[1] ~= r.produto then rg = x break end
  end
  local item
  if rg then
    item = { id = rg[1], meta = n, sinal = -1, por = rg[2], credito = creditar }
  else
    item = { id = r.produto, meta = n, por = r.qtd or 1, credito = creditar }
  end
  estado.msg = nil
  iniciarPend(principal and "Crafting..." or "Making...", { item }, 10 + 6 * n)
  estado.pend.rota = { slug = slug, ate = ate, principal = principal, nome = ns.plano and ns.plano.rota and ns.plano.rota.nome }
  C_TradeSkillUI.CraftRecipe(magia, n)
end

local function acaoCraftRota()
  local _, R = rotaPlano()
  if not R then return nil end
  local slug = R.prof
  if R.estado == "feito" then return { texto = "Done: " .. tostring(R.nome or slug) .. " " .. tostring(R.alvo) } end
  -- rank no teto vem antes do passo: com o nivel curto, o limite corta todos os passos e nao ha passo atual
  local rk = R.rank
  if rk and R.max and R.pericia and R.pericia >= R.max then
    if rk.bloqueado then return { texto = tostring(rk.nome) .. " needs level " .. tostring(rk.nivel) } end
    return { texto = "Train " .. tostring(rk.nome) .. " (" .. ns.moeda(rk.custo or 0) .. ")" }
  end
  local atual = R.atual
  if not atual then return nil end
  local rr = rotaDados(slug)
  local r = rr and rr.receitas and rr.receitas[atual.magia]
  if not r then return nil end
  if not conhecidaRota(slug, atual.magia, r) then
    if r.padrao then
      local it = itemRota(r.padrao)
      local nomeP = (it and it.nome) or ("item " .. tostring(r.padrao))
      if estoqueBolsa(r.padrao) > 0 then return { texto = "Learn " .. nomeP } end
      return { texto = "Buy pattern " .. nomeP }
    end
    return { texto = "Train " .. tostring(r.nome or atual.nome) .. (r.treino and (" (" .. ns.moeda(r.treino) .. ")") or "") }
  end
  local T = C_TradeSkillUI
  if type(T) == "table" and type(T.GetRecipeRequirements) == "function" then
    local ok, reqs = pcall(T.GetRecipeRequirements, atual.magia)
    if ok and type(reqs) == "table" then
      for _, q in ipairs(reqs) do
        if type(q) == "table" and q.met == false then return { texto = "Need " .. tostring(q.name) .. " nearby" } end
      end
    end
  end
  if r.encantar or atual.encantar then
    return { texto = "Enchant manually (" .. tostring(atual.faltam or 0) .. " left)" }
  end
  local B = min(atual.faltam or LOTE_ROTA, LOTE_ROTA)
  if B < 1 then B = 1 end
  local fab = proximoFabrico(slug, rr, atual.de, r, B, 0)
  if fab then
    return { texto = "Make " .. fab.n .. " " .. tostring(fab.r.nome),
             executar = function() craftarRota(slug, fab.magia, fab.r, fab.n, false, atual.ate) end }
  end
  local n = min(B, vezes(r))
  if n > 0 then
    return { texto = "Craft " .. n .. " " .. tostring(r.nome or atual.nome),
             executar = function() craftarRota(slug, atual.magia, r, n, true, atual.ate) end }
  end
  local pend = 0
  for id in pairs(idsDoLote(rr, atual.de, r, 0)) do pend = pend + (S.correio[id] or 0) end
  if pend > 0 then return { texto = "Take mail first (" .. pend .. " items)" } end
  return { texto = "Buy mats at the AH" }
end

-- a pericia chegou ao fim do passo durante um lote da rota: para a repeticao (e parar, nao e acao) e devolve o botao
local function talvezParar(nivel)
  local p = estado.pend
  local pr = p and p.rota
  if not pr or not pr.ate then return end
  nivel = nivel or periciaJanela()
  if not nivel or nivel < pr.ate then return end
  local T = C_TradeSkillUI
  if type(T) == "table" and type(T.StopRecipeRepeat) == "function" then pcall(T.StopRecipeRepeat) end
  progresso()
  if estado.pend == p then terminarPend() end
  atualizar()
end

local function fimDoCraftRota()
  local p = estado.pend
  if not (p and p.rota) then return end
  progresso()
  if estado.pend == p then terminarPend() end
  atualizar()
end

-- Proxima acao -------------------------------------------------------------------------------------------

function ns.proximaAcao()
  if estado.pend then return { texto = estado.pend.texto } end
  local c = ns.contexto()
  local a
  if c.ah then a = acaoLeilao() end
  if not a and c.vend then a = acaoVendedor() end
  if not a and c.prof then
    if rotaPlano() then a = acaoCraftRota() else a = acaoCraft() end
  end
  return a
end

-- Eventos --------------------------------------------------------------------------------------------------

ns.ao("AUCTION_HOUSE_SHOW", function() aberto.ah = true end)
ns.ao("AUCTION_HOUSE_CLOSED", function()
  aberto.ah = false
  estado.cot, estado.lote, estado.busca = nil, nil, nil
end)
ns.ao("MERCHANT_SHOW", function() aberto.vend = true end)
ns.ao("MERCHANT_CLOSED", function() aberto.vend = false end)
ns.ao("TRADE_SKILL_SHOW", function() aberto.prof = true end)
ns.ao("TRADE_SKILL_CLOSE", function() aberto.prof = false end)
ns.ao("MAIL_SHOW", function()
  aberto.mail = true
  conciliarCaixa()
end)
ns.ao("MAIL_INBOX_UPDATE", function() if aberto.mail then conciliarCaixa() end end)
ns.ao("MAIL_CLOSED", function() aberto.mail = false end)
ns.ao("TRAINER_SHOW", function() aberto.trainer = true end)
ns.ao("TRAINER_CLOSED", function() aberto.trainer = false end)

-- pericia subiu durante um lote da rota (o texto enUS traz o nivel novo; so conta a profissao da rota)
ns.ao("CHAT_MSG_SKILL", function(texto)
  local p = estado.pend
  if not (p and p.rota) or type(texto) ~= "string" then return end
  local nome, n = string.match(texto, "Your skill in (.+) has increased to (%d+)")
  if nome and p.rota.nome and nome ~= p.rota.nome then return end
  talvezParar(tonumber(n))
end)
ns.ao("TRADE_SKILL_LIST_UPDATE", function() talvezParar() end)
ns.ao("SKILL_LINES_CHANGED", function() talvezParar() end)
ns.ao("UNIT_SPELLCAST_INTERRUPTED", function(unidade) if unidade == "player" then fimDoCraftRota() end end)
ns.ao("UPDATE_TRADESKILL_CAST_STOPPED", function() fimDoCraftRota() end)

-- na rota, o plano vale sem scan (secao 12.3): refaz ao entrar no mundo (depois de um /reload) e, sem acao em
-- andamento, meio segundo depois de a bolsa mudar (correio pego, compra no vendedor), para o NEXT seguir o dono
local replanAgendado = false
local function emRota() return ns.modo ~= nil and ns.modo().tipo == "rota" end
local function replanRotaDepois()
  if replanAgendado then return end
  replanAgendado = true
  C_Timer.After(0.5, function()
    replanAgendado = false
    if estado.pend or not emRota() then return end
    ns.replanejar()
  end)
end

ns.ao("PLAYER_ENTERING_WORLD", function()
  if not emRota() then return end
  ns.replanejar()
  replanRotaDepois()
end)

ns.ao("BAG_UPDATE_DELAYED", function()
  conciliarCorreio()
  progresso()
  if not estado.pend and emRota() then replanRotaDepois() end
end)

ns.ao("UI_ERROR_MESSAGE", function(_, texto)
  if not estado.pend then return end
  progresso()
  estado.msg = type(texto) == "string" and texto or "Action failed"
  terminarPend()
  atualizar()
end)
