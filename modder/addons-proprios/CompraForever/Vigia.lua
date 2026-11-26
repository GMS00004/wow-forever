local addon, ns = ...

-- Vigia: lista de itens com teto de compra, busca periodica com a AH aberta, alerta, oportunidade de compra e
-- historico de precos (CONTRATO secoes 5, 6 e 7). A compra em si e da Compra.lua (ns.vigiaOportunidade()).
-- CompraForeverDB.vigia = { itens = { [id] = { nome, teto, qtd } }, intervalo = 30, historico = { [id] = { { t, min, p25, unid } } } }

local min, max, floor = math.min, math.max, math.floor

local PADRAO_INTERVALO = 30
local PADRAO_QTD = 20
local MAX_HIST = 2000
local MAX_BUSCAS_MIN = 100     -- a documentacao da API pede no maximo 100 buscas por minuto

ns.vigia = { escadas = {}, em = nil, alerta = {} }
local V = ns.vigia

local ahAberta = false
local ciclo = 0                -- muda a cada reinicio: timers antigos se calam
local ultima = {}              -- id -> GetTime da ultima busca vigia

function ns.vigiaDB()
  local db = rawget(_G, "CompraForeverDB")
  return type(db) == "table" and db.vigia or nil
end

local function iniciarVigia()
  local db = CompraForeverDB
  if type(db.vigia) ~= "table" then db.vigia = {} end
  local v = db.vigia
  if type(v.itens) ~= "table" then v.itens = {} end
  if type(v.intervalo) ~= "number" then v.intervalo = PADRAO_INTERVALO end
  if type(v.historico) ~= "table" then v.historico = {} end
end

local function idsOrdenados(db)
  local ids = {}
  for id in pairs(db.itens) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

-- Lista, historico ---------------------------------------------------------------------------------------

function ns.vigiaNome(id)
  local d = rawget(_G, "CompraForeverDados")
  local it = d and d.itens and d.itens[id]
  if it and it.nome then return it.nome end
  local nome = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(id)
  if type(nome) == "string" and nome ~= "" then return nome end
  return "item " .. id
end

function ns.vigiaListar()
  local db = ns.vigiaDB()
  local lista = {}
  if not db then return lista end
  for _, id in ipairs(idsOrdenados(db)) do
    local it = db.itens[id]
    lista[#lista + 1] = { id = id, nome = it.nome, teto = it.teto, qtd = it.qtd }
  end
  return lista
end

-- ultimo preco minimo visto (cobre) ou nil
function ns.vigiaUltimo(id)
  local esc = V.escadas[id]
  if esc and esc[1] then return esc[1].preco end
  local db = ns.vigiaDB()
  local h = db and db.historico[id]
  local e = h and h[#h]
  if e and (e.min or 0) > 0 then return e.min end
  return nil
end

-- nome == nil: mantem o nome atual ou resolve pelo id. qtd == nil: mantem a atual ou usa o padrao.
function ns.vigiaPor(id, nome, teto, qtd)
  local db = ns.vigiaDB()
  if not db then return nil end
  local it = db.itens[id]
  local novo = it == nil
  if not it then
    it = {}
    db.itens[id] = it
  end
  it.nome = nome or it.nome or ns.vigiaNome(id)
  it.teto = teto
  it.qtd = qtd or it.qtd or PADRAO_QTD
  ns.vigiaReiniciar()
  return it, novo
end

function ns.vigiaTirar(id)
  local db = ns.vigiaDB()
  if not db or not db.itens[id] then return false end
  db.itens[id] = nil
  V.escadas[id] = nil
  V.alerta[id] = nil
  ultima[id] = nil
  return true
end

function ns.vigiaCada(seg)
  local db = ns.vigiaDB()
  if not db then return false end
  db.intervalo = seg
  ns.vigiaReiniciar()
  return true
end

-- preco da unidade na posicao 25% da escada acumulada por quantidade
local function p25De(esc)
  local total = 0
  for _, d in ipairs(esc) do total = total + d.qtd end
  if #esc == 0 or total == 0 then return 0 end
  if #esc == 1 then return esc[1].preco end
  local alvo, soma = total * 0.25, 0
  for _, d in ipairs(esc) do
    soma = soma + d.qtd
    if soma >= alvo then return d.preco end
  end
  return esc[#esc].preco
end

local function gravarHistorico(db, id, esc, em)
  local h = db.historico[id]
  if not h then
    h = {}
    db.historico[id] = h
  end
  local unid = 0
  for _, d in ipairs(esc) do unid = unid + d.qtd end
  h[#h + 1] = { t = em, min = esc[1] and esc[1].preco or 0, p25 = p25De(esc), unid = unid }
  while #h > MAX_HIST do table.remove(h, 1) end
end

-- Oportunidade -------------------------------------------------------------------------------------------

-- linha no formato de plano.leilao para o item, ou nil se nenhum degrau custa o teto ou menos
local function linhaDe(id, it, esc)
  if not esc or not it.teto then return nil end
  local barato = {}
  for _, d in ipairs(esc) do
    if d.preco <= it.teto then barato[#barato + 1] = d end
  end
  if #barato == 0 then return nil end
  local alvo = it.qtd or PADRAO_QTD
  local row = { id = id, nome = it.nome, precoMax = it.teto, vigia = true }
  if not barato[1].inteiro then
    local falta, custo, qtd = alvo, 0, 0
    for _, d in ipairs(barato) do
      local n = min(d.qtd, falta)
      custo = custo + n * d.preco
      qtd = qtd + n
      falta = falta - n
      if falta <= 0 then break end
    end
    row.qtd, row.custo, row.inteiro = qtd, custo, false
  else
    -- leilao inteiro: lote a lote (um PlaceBid por clique) ate juntar a quantidade pedida
    local lotes, qtd, custo = {}, 0, 0
    for _, d in ipairs(barato) do
      lotes[#lotes + 1] = d
      qtd = qtd + d.qtd
      custo = custo + (d.total or d.preco * d.qtd)
      if qtd >= alvo then break end
    end
    row.qtd, row.custo, row.inteiro, row.lotes = qtd, custo, true, lotes
  end
  return row
end

local function todasOportunidades()
  local db = ns.vigiaDB()
  local out = {}
  if not db then return out end
  for _, id in ipairs(idsOrdenados(db)) do
    local it = db.itens[id]
    local esc = V.escadas[id]
    local row = linhaDe(id, it, esc)
    if row then out[#out + 1] = { row = row, rel = esc[1].preco / max(1, it.teto) } end
  end
  table.sort(out, function(a, b)
    if a.rel ~= b.rel then return a.rel < b.rel end
    return a.row.id < b.row.id
  end)
  return out
end

function ns.vigiaOportunidade()
  local o = todasOportunidades()[1]
  return o and o.row or nil
end

local function alertar(row, preco)
  PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959)
  local texto = row.nome .. " at " .. ns.moeda(preco) .. " (watch <= " .. ns.moeda(row.precoMax) .. ")"
  if RaidNotice_AddMessage and RaidWarningFrame then
    local cor = ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] or { r = 1, g = 1, b = 1 }
    RaidNotice_AddMessage(RaidWarningFrame, texto, cor)
  else
    print("CompraForever: " .. texto)
  end
end

-- alerta so na passagem de "sem oportunidade" para "com oportunidade", por id
function ns.vigiaAvaliar()
  local db = ns.vigiaDB()
  if not db then return end
  local tem = {}
  for _, o in ipairs(todasOportunidades()) do
    local id = o.row.id
    tem[id] = true
    if not V.alerta[id] then
      V.alerta[id] = true
      alertar(o.row, V.escadas[id][1].preco)
    end
  end
  for id in pairs(V.alerta) do
    if not tem[id] then V.alerta[id] = nil end
  end
end

-- o preco subiu na cotacao: a escada guardada ficou velha
function ns.vigiaInvalidar(id)
  V.escadas[id] = nil
  V.alerta[id] = nil
end

-- grava no historico e guarda as escadas dos ids vigiados; sem = ids que nao responderam (ficam como estavam)
function ns.vigiaRegistrar(escadas, em, sem)
  local db = ns.vigiaDB()
  if not db or type(escadas) ~= "table" then return end
  local pular = {}
  for _, id in ipairs(sem or {}) do pular[id] = true end
  em = em or time()
  local houve = false
  for _, id in ipairs(idsOrdenados(db)) do
    local esc = escadas[id]
    if esc and not pular[id] then
      V.escadas[id] = esc
      gravarHistorico(db, id, esc, em)
      houve = true
    end
  end
  if houve then V.em = em end
  ns.vigiaAvaliar()
  if ns.atualizarPainel then ns.atualizarPainel() end
end

-- Busca periodica ------------------------------------------------------------------------------------------

local tick

local function agendar(seg)
  local tok = ciclo
  C_Timer.After(seg, function() tick(tok) end)
end

tick = function(tok)
  if tok ~= ciclo or not ahAberta then return end
  local db = ns.vigiaDB()
  if not db then return end
  local todos = idsOrdenados(db)
  if #todos == 0 then return end
  local intervalo = max(db.intervalo or PADRAO_INTERVALO, #todos * 60 / MAX_BUSCAS_MIN)
  local agora = GetTime()
  local ids, resta = {}, nil
  for _, id in ipairs(todos) do
    local r = intervalo - (agora - (ultima[id] or -1e9))
    if r <= 0 then ids[#ids + 1] = id else resta = min(resta or r, r) end
  end
  if #ids == 0 then
    agendar(max(0.5, resta or 1))
    return
  end
  if (ns.scanEstado and ns.scanEstado.ocupado) or (ns.compraOcupada and ns.compraOcupada()) then
    agendar(2)
    return
  end
  local t0 = agora
  local ok = ns.buscarVigia and ns.buscarVigia(ids, function(escadas, sem)
    if escadas then
      ns.vigiaRegistrar(escadas, time(), sem)
      if tok == ciclo then agendar(max(1, intervalo - (GetTime() - t0))) end
    elseif tok == ciclo then
      agendar(2)
    end
  end)
  if not ok then
    agendar(2)
    return
  end
  for _, id in ipairs(ids) do ultima[id] = t0 end
end

-- recomeca o ciclo: primeira busca 2 s depois (ids ja buscados esperam o intervalo)
function ns.vigiaReiniciar()
  ciclo = ciclo + 1
  local db = ns.vigiaDB()
  if ahAberta and db and next(db.itens) then agendar(2) end
end

-- Caca (pedido do dono em 2026-11-26; CONTRATO secao 13) ---------------------------------------------------
-- Um material por vez, com alvo por unidade e trava de gasto. Cada clique no botao de acao faz uma coisa so: busca o
-- item (busca nao e acao), cota os lotes no alvo ou confirma (Compra.lua). Nada busca sozinho fora do rastro de um
-- clique: depois de uma compra ou de uma cotacao recusada, a busca seguinte vai encadeada no mesmo evento.
-- CompraForeverCharDB.caca = { id, nome, alvo, trava, gasto, qtd, inicio, log = { { t, qtd, total } } }

local MIN_LOTE = 3             -- lote de 1 ou 2 unidades e isca (o dono): sozinho nao dispara compra
local TRAVA_PADRAO = 50000     -- 5g quando o dono nao diz a trava
local VALIDADE = 10            -- s: busca mais velha que isso nao cota, busca de novo
local PARADA = 2               -- s: busca da caca sem resposta ha mais que isso pode ser refeita por um aperto
local MAX_LOG = 200

ns.caca = { escada = nil, em = nil, buscando = false, msg = nil, buscas = 0, ultimaBusca = nil, perdidas = 0, resposta = nil }
local C = ns.caca
ns.CACA_MIN_LOTE, ns.CACA_TRAVA_PADRAO = MIN_LOTE, TRAVA_PADRAO

function ns.cacaDB()
  local db = rawget(_G, "CompraForeverCharDB")
  local c = type(db) == "table" and db.caca
  if type(c) == "table" and type(c.id) == "number" and type(c.alvo) == "number" then return c end
  return nil
end

-- mesmo item: mantem o gasto, a quantidade e o registro (o dono so trocou o alvo ou a trava); item novo: zera
function ns.cacaLigar(id, nome, alvo, trava)
  if type(CompraForeverCharDB) ~= "table" then CompraForeverCharDB = {} end
  local velho = ns.cacaDB()
  local c
  if velho and velho.id == id then
    c = velho
    c.alvo = alvo
    if trava then c.trava = trava end
  else
    c = { id = id, nome = nome or ns.vigiaNome(id), alvo = alvo, trava = trava or TRAVA_PADRAO, gasto = 0, qtd = 0,
          inicio = time(), log = {} }
    CompraForeverCharDB.caca = c
  end
  if nome then c.nome = nome end
  if not (velho and velho.id == id) then C.buscas, C.perdidas, C.ultimaBusca = 0, 0, nil end
  C.escada, C.em, C.buscando, C.msg = nil, nil, false, nil
  return c, velho ~= nil and velho.id == id
end

function ns.cacaDesligar()
  local c = ns.cacaDB()
  if type(CompraForeverCharDB) == "table" then CompraForeverCharDB.caca = nil end
  C.escada, C.em, C.buscando, C.msg = nil, nil, false, nil
  return c
end

function ns.cacaInvalidar()
  C.escada, C.em = nil, nil
end

-- busca so o item da caca (uma pagina, a ponta barata); a resposta vira C.escada
function ns.cacaBuscar()
  local cc = ns.cacaDB()
  if not cc or C.buscando or not ns.buscarCaca then return false end
  C.buscando, C.msg = true, nil
  C.buscas, C.ultimaBusca = (C.buscas or 0) + 1, GetTime()
  local id = cc.id
  local ok, motivo = ns.buscarCaca(id, function(escadas, sem)
    C.buscando = false
    local semResposta = false
    for _, s in ipairs(type(sem) == "table" and sem or {}) do
      if s == id then semResposta = true end
    end
    if type(escadas) == "table" and escadas[id] and not semResposta then
      C.escada, C.em = escadas[id], GetTime()
      if C.ultimaBusca then C.resposta = C.em - C.ultimaBusca end
    else
      C.escada, C.em = nil, nil
      C.msg = semResposta and "No answer: click again" or nil
    end
    if ns.atualizarPainel then ns.atualizarPainel() end
  end)
  if not ok then
    C.buscando = false
    C.msg = motivo == "busy" and "Busy: click again" or nil
  end
  return ok
end

-- o dono apertou com a busca parada ha mais de PARADA s: descarta a velha e manda outra
function ns.cacaReiniciar()
  if ns.abortarBuscaCaca then ns.abortarBuscaCaca() end
  C.buscando = false
  ns.cacaBuscar()
end

-- tempos de uma cotacao ou compra da caca (secao 13.4): o ultimo vai para o painel; os ultimos 100, para a SV em ms
local MAX_TEMPOS = 100
function ns.cacaTempo(t)
  C.tempo = t
  local cc = ns.cacaDB()
  if not cc then return end
  if type(cc.tempos) ~= "table" then cc.tempos = {} end
  local l05, l10
  for _, x in ipairs(t.livre or {}) do
    if x.em == 0.5 then l05 = x.livre else l10 = x.livre end
  end
  local function ms(x) return x and floor(x * 1000 + 0.5) or nil end
  cc.tempos[#cc.tempos + 1] = { t = time(), res = t.res, cota = ms(t.cota), compra = ms(t.compra), l05 = l05, l10 = l10 }
  while #cc.tempos > MAX_TEMPOS do table.remove(cc.tempos, 1) end
end

-- a compra da caca deu certo: registra e ja busca de novo (encadeado no clique de confirmar)
function ns.cacaComprou(qtd, total)
  local cc = ns.cacaDB()
  if not cc then return end
  cc.gasto = cc.gasto + (total or 0)
  cc.qtd = cc.qtd + (qtd or 0)
  cc.log[#cc.log + 1] = { t = time(), qtd = qtd, total = total }
  while #cc.log > MAX_LOG do table.remove(cc.log, 1) end
  C.escada, C.em = nil, nil
  ns.cacaBuscar()
end

-- a cotacao veio acima do que a busca mostrou (outro comprou antes): busca de novo, encadeado no clique de cotar
function ns.cacaPrecoMudou()
  C.escada, C.em = nil, nil
  ns.cacaBuscar()
  C.msg = "Price moved: hunting again"
end

-- a confirmacao falhou (outro comprou antes): conta e busca de novo, encadeado no clique de confirmar, para o
-- aperto seguinte ja cotar
function ns.cacaPerdeu()
  C.perdidas = (C.perdidas or 0) + 1
  C.escada, C.em = nil, nil
  ns.cacaBuscar()
  C.msg = "Someone bought first: hunting again"   -- depois da busca, que limpa a mensagem ao comecar
end

-- quanto da escada comprar: do mais barato ate o ultimo lote de MIN_LOTE ou mais no alvo. Lote pequeno acima dele
-- fica (isca); lote pequeno abaixo entra, porque a compra de commodity leva sempre do mais barato para cima.
-- Devolve a linha de compra, ou nil e o motivo ("bait", "cap", "item", "none").
function ns.cacaPlano(esc, alvo, limite)
  if type(esc) ~= "table" or #esc == 0 then return nil, "none" end
  if esc[1].inteiro then return nil, "item" end
  local ultimo, isca = 0, false
  for i, d in ipairs(esc) do
    if d.preco > alvo then break end
    if d.qtd >= MIN_LOTE then ultimo = i else isca = true end
  end
  if ultimo == 0 then return nil, isca and "bait" or "none" end
  local qtd, custo = 0, 0
  for i = 1, ultimo do
    local d = esc[i]
    local n = d.qtd
    if custo + n * d.preco > limite then n = floor((limite - custo) / d.preco) end
    if n > 0 then
      qtd, custo = qtd + n, custo + n * d.preco
    end
    if n < d.qtd then break end
  end
  if qtd == 0 then return nil, "cap" end
  return { qtd = qtd, custo = custo, precoMax = esc[ultimo].preco }
end

-- acao da caca para o botao: { texto, executar } ou nil sem caca ligada
function ns.cacaAcao()
  local cc = ns.cacaDB()
  if not cc then return nil end
  if C.buscando then
    if C.ultimaBusca and (GetTime() - C.ultimaBusca) > PARADA then
      return { texto = "Hunting " .. cc.nome .. "... (press to retry)", reiniciar = true }
    end
    return { texto = "Hunting " .. cc.nome .. "..." }
  end
  local fresca = C.escada and C.em and (GetTime() - C.em) <= VALIDADE
  if fresca then
    local dinheiro = (ns.dinheiro and ns.dinheiro() or 0) - ((ns.config and ns.config().reserva) or 0)
    local limite = max(0, min(cc.trava - cc.gasto, dinheiro))
    local p, motivo = ns.cacaPlano(C.escada, cc.alvo, limite)
    if p then
      local row = { id = cc.id, nome = cc.nome, qtd = p.qtd, custo = p.custo, precoMax = p.precoMax, caca = true,
                    inteiro = false }
      return { texto = "Buy " .. p.qtd .. " " .. cc.nome .. " (" .. ns.moeda(p.custo) .. ") [HUNT]", row = row }
    end
    if motivo == "item" then return { texto = "Hunt: " .. cc.nome .. " is not a commodity" } end
    if motivo == "cap" then
      return { texto = "Hunt cap reached (" .. ns.moeda(cc.gasto) .. " of " .. ns.moeda(cc.trava) .. ")" }
    end
  end
  return { texto = "Hunt " .. cc.nome .. " <= " .. ns.moeda(cc.alvo), buscar = true }
end

-- linhas do painel durante a caca (no lugar do plano)
function ns.cacaLinhas()
  local cc = ns.cacaDB()
  if not cc then return nil end
  local L = {}
  L[#L + 1] = "HUNT " .. cc.nome .. " <= " .. ns.moeda(cc.alvo) .. "  (lots of " .. MIN_LOTE .. "+)"
  local media = cc.qtd > 0 and floor(cc.gasto / cc.qtd + 0.5) or nil
  L[#L + 1] = "Bought " .. cc.qtd .. (media and (" avg " .. ns.moeda(media)) or "") .. " | spent " .. ns.moeda(cc.gasto)
    .. " of " .. ns.moeda(cc.trava)
  if (C.buscas or 0) > 0 and C.ultimaBusca then
    L[#L + 1] = "Searches " .. C.buscas .. " | lost " .. (C.perdidas or 0)
      .. (C.resposta and (" | resp " .. string.format("%.1f", C.resposta) .. " s") or "") .. " | last " .. string.format("%.1f", GetTime() - C.ultimaBusca) .. " s ago"
  end
  local tp = C.tempo
  if tp then
    local function seg(x) return x and string.format("%.1fs", x) or "-" end
    local fila = {}
    for _, x in ipairs(tp.livre or {}) do fila[#fila + 1] = (x.em == 0.5 and "0.5s " or "1s ") .. (x.livre and "free" or "busy") end
    L[#L + 1] = "Quote " .. seg(tp.cota) .. " | buy " .. seg(tp.compra) .. " | queue " .. (#fila > 0 and table.concat(fila, " ") or "-")
  end
  local esc = C.escada
  if esc and esc[1] then
    local partes = {}
    for i = 1, min(6, #esc) do partes[#partes + 1] = ns.moeda(esc[i].preco) .. " x" .. esc[i].qtd end
    L[#L + 1] = "Now " .. table.concat(partes, ", ")
  elseif C.em == nil and not C.buscando then
    L[#L + 1] = "Click to search"
  end
  return L
end

ns.ao("ADDON_LOADED", function(nome)
  if nome == addon then iniciarVigia() end
end)

ns.ao("AUCTION_HOUSE_SHOW", function()
  ahAberta = true
  V.escadas, V.alerta = {}, {}
  C.escada, C.em, C.buscando, C.msg = nil, nil, false, nil
  ns.vigiaReiniciar()
end)

ns.ao("AUCTION_HOUSE_CLOSED", function()
  ahAberta = false
  ciclo = ciclo + 1
end)
