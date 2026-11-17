-- GuiaForever 1.5: aba Crafts da janela J (a rota de Leatherworking da ferramenta, com icones) e o
-- registro das receitas conhecidas, lido da janela de profissao quando o dono a abre (so leitura).
-- Desde a 1.5, custo, pior caso e "se vender" saem do preco de leilao do Auctionator (API publica, so
-- leitura) e se refazem quando ele atualiza o banco (pesquisa ou varredura); sem Auctionator, os da rota.
-- Contrato: ARQUITETURA.md, secoes 13 e 13.6. Dados: RotaCrafts.lua (GuiaForeverRotaCrafts), gerado por
-- ferramentas/pregao/rota.mjs --addon. O codigo nao escolhe receita: so mostra a rota dos dados (regra 11)
-- e avisa quando a alternativa que veio nos dados ficou mais barata com o preco de agora.

local _, ns = ...
ns.abasConstrutores = ns.abasConstrutores or {}
local AB = ns.abasConstrutores

local PROF = "Leatherworking"
local ICONE_PROF = "Interface\\Icons\\INV_Misc_ArmorKit_17"
local ICONE_TREINO = "Interface\\Icons\\INV_Misc_Book_11"

local function add(b, x) b[#b + 1] = x end

local function moeda(c)
  if ns.ui and ns.ui.moeda then return ns.ui.moeda(c) end
  return tostring(c)
end

local function comSinal(c)
  c = tonumber(c) or 0
  if c > 0 then return "+" .. moeda(c) end
  return moeda(c)
end

local function rota()
  local R = GuiaForeverRotaCrafts
  if type(R) == "table" and type(R.passos) == "table" and #R.passos > 0 then return R end
  return nil
end
ns.rotaCrafts = rota

-- Receitas conhecidas ------------------------------------------------------------------------------

local function conhecidasDB()
  local db = ns.dbPersonagem and ns.dbPersonagem()
  local k = type(db) == "table" and db.receitasLW
  if type(k) == "table" and type(k.ids) == "table" then return k end
  return nil
end

local function conhece(magia)
  local k = conhecidasDB()
  return k ~= nil and k.ids[magia] == true
end

local function ehLW(info)
  return type(info) == "table" and (info.professionName == PROF or info.parentProfessionName == PROF)
end

-- Le a janela de profissao aberta. So grava quando e a do proprio personagem e e Leatherworking.
local function gravarConhecidas()
  local T = C_TradeSkillUI
  if type(T) ~= "table" or type(T.GetAllRecipeIDs) ~= "function" or type(T.GetRecipeInfo) ~= "function" then return end
  if T.IsTradeSkillReady and not T.IsTradeSkillReady() then return end
  if (T.IsTradeSkillLinked and T.IsTradeSkillLinked()) or (T.IsTradeSkillGuild and T.IsTradeSkillGuild())
    or (T.IsNPCCrafting and T.IsNPCCrafting()) then return end
  local base = T.GetBaseProfessionInfo and T.GetBaseProfessionInfo()
  local filho = T.GetChildProfessionInfo and T.GetChildProfessionInfo()
  if not (ehLW(base) or ehLW(filho)) then
    -- calibragem: o nome que o cliente devolveu, uma vez por nome
    local nome = tostring(type(base) == "table" and base.professionName or "?") .. "/" ..
      tostring(type(filho) == "table" and filho.professionName or "?")
    local db = ns.dbPersonagem and ns.dbPersonagem()
    if type(db) == "table" and db.profVista ~= nome and ns.log then
      db.profVista = nome
      ns.log("crafts: profession window " .. nome)
    end
    return
  end
  local ids, n = {}, 0
  local lista = T.GetAllRecipeIDs()
  for _, id in ipairs(type(lista) == "table" and lista or {}) do
    local r = T.GetRecipeInfo(id)
    if type(r) == "table" and r.learned then
      ids[id] = true
      n = n + 1
    end
  end
  if n == 0 then return end
  local info = (ehLW(filho) and filho) or base
  local db = ns.dbPersonagem and ns.dbPersonagem()
  if type(db) ~= "table" then return end
  local antes = db.receitasLW
  db.receitasLW = {
    quem = UnitName and UnitName("player") or nil, em = time and time() or nil,
    pericia = tonumber(info.skillLevel), max = tonumber(info.maxSkillLevel), ids = ids, n = n,
  }
  if (type(antes) ~= "table" or antes.n ~= n) and ns.log then ns.log("crafts: " .. n .. " known Leatherworking recipes") end
  if ns.atualizarJanela then ns.atualizarJanela() end
end

local function agendarGravar()
  if ns.agendar then ns.agendar("crafts:conhecidas", 0.5, gravarConhecidas) else gravarConhecidas() end
end

if ns.ao then
  ns.ao("TRADE_SKILL_SHOW", agendarGravar)
  ns.ao("TRADE_SKILL_LIST_UPDATE", agendarGravar)
  ns.ao("TRADE_SKILL_DATA_SOURCE_CHANGED", agendarGravar)
end

-- Estado do jogador -------------------------------------------------------------------------------

local function pericia()
  local lista = ns.minhasProfissoes and ns.minhasProfissoes() or {}
  for _, pr in ipairs(lista) do
    if pr.nome == PROF and tonumber(pr.pericia) then return tonumber(pr.pericia) end
  end
  local k = conhecidasDB()
  if k and tonumber(k.pericia) then return tonumber(k.pericia) end
  return nil
end

-- bolsas e banco
local function temItem(id)
  local n
  pcall(function()
    if C_Item and C_Item.GetItemCount then n = C_Item.GetItemCount(id, true) end
  end)
  return tonumber(n)
end

local function diaTxt(dia)
  local s = tostring(dia or "")
  if #s ~= 8 then return s end
  return s:sub(5, 6) .. "/" .. s:sub(7, 8)
end

-- Padrao de um passo: pilula curta, cor, estado e a linha da secao Patterns.
local function situacao(p)
  local pd = type(p.padrao) == "table" and p.padrao or {}
  if conhece(p.magia) or pd.situacao == "conhecida" then
    return { pil = "Known", cor = "verde", estado = "feito", sub = "You know this recipe." }
  end
  if pd.situacao == "leilao" then
    local l = tonumber(pd.listados)
    return { pil = "AH " .. moeda(pd.preco), cor = "dourado", estado = "agora",
             sub = "Buy the pattern on the AH: " .. moeda(pd.preco) .. (l and (" (" .. l .. " listed)") or "") }
  end
  if pd.situacao == "vendedor" then
    return { pil = "Vendor " .. moeda(pd.preco), cor = "azul", estado = "agora",
             sub = "Buy the pattern from a vendor: " .. moeda(pd.preco) }
  end
  return { pil = "Trainer", cor = "azul", estado = "depois",
           sub = "Learn it at the Leatherworking trainer (skill " .. tostring(p.aprende or "?") .. ")." }
end

-- Precos vivos (1.5, ARQUITETURA.md 13.6) ---------------------------------------------------------

local CHAMADOR = "GuiaForever"
local MARGEM = 100 -- 1s: o aviso de troca so aparece se a alternativa poupa mais que isso no passo

local function apiAuctionator()
  local A = type(Auctionator) == "table" and type(Auctionator.API) == "table" and Auctionator.API.v1
  if type(A) == "table" and type(A.GetAuctionPriceByItemID) == "function" then return A end
  return nil
end

-- memo por desenho da aba: id -> preco (ou false) e a contagem do que veio vivo
local memo, contagem = {}, { vivos = 0, total = 0 }

-- Preco de leilao do Auctionator, so quando visto hoje (idade 0), como a ferramenta faz com a exportacao.
local function vivoDe(id)
  id = tonumber(id)
  if not id then return nil end
  if memo[id] ~= nil then return memo[id] or nil end
  local v = false
  local A = apiAuctionator()
  if A then
    local ok, preco = pcall(A.GetAuctionPriceByItemID, CHAMADOR, id)
    if ok and type(preco) == "number" and preco > 0 then
      local idade = 0
      if type(A.GetAuctionAgeByItemID) == "function" then
        local ok2, d = pcall(A.GetAuctionAgeByItemID, CHAMADOR, id)
        idade = ok2 and d or nil
      end
      if idade == 0 then v = preco end
    end
  end
  memo[id] = v
  contagem.total = contagem.total + 1
  if v then contagem.vivos = contagem.vivos + 1 end
  return v or nil
end

-- Preco unitario de um reagente: o menor entre o leilao (vivo; sem ele, o da rota quando a letra e L),
-- o vendedor e o fabricar (F, o da rota). A mesma regra do crafts.mjs.
local function unidade(g)
  local melhor
  local function cand(v)
    v = tonumber(v)
    if v and v > 0 and (melhor == nil or v < melhor) then melhor = v end
  end
  local vivo = vivoDe(g.id)
  if vivo then cand(vivo) elseif g.letra == "L" then cand(g.preco) end
  cand(g.vendedor)
  if g.letra == "F" then
    -- fabricar: a receita que faz o item, com o preco de agora dos reagentes dela (um nivel)
    local fab = type(g.fab) == "table" and type(g.fab.mats) == "table" and g.fab or nil
    if fab and #fab.mats > 0 then
      local s = 0
      for _, h in ipairs(fab.mats) do s = s + (tonumber(h.un) or 0) * unidade(h) end
      cand(s / math.max(1, tonumber(fab.qtd) or 1))
    else
      cand(g.preco)
    end
  end
  if melhor == nil then cand(g.preco) end
  return melhor or 0
end

-- O mais barato e fabricar? (para a dica do material)
local function fabricarVale(g)
  if type(g) ~= "table" or g.letra ~= "F" or type(g.fab) ~= "table" or type(g.fab.mats) ~= "table" then return nil end
  local s = 0
  for _, h in ipairs(g.fab.mats) do s = s + (tonumber(h.un) or 0) * unidade(h) end
  s = s / math.max(1, tonumber(g.fab.qtd) or 1)
  local comprar = vivoDe(g.id) or tonumber(g.vendedor)
  if comprar and comprar <= s then return nil end
  local nomes = {}
  for _, h in ipairs(g.fab.mats) do nomes[#nomes + 1] = tostring(h.nome or h.id) end
  return "Cheaper to make it yourself: " .. table.concat(nomes, " + ") .. " (" .. moeda(math.floor(s + 0.5)) .. " each"
    .. (comprar and (", buying it " .. moeda(comprar)) or "") .. ")."
end

-- Contas de um passo (ou da alternativa) com o preco de agora: custo por craft, pior caso e "se vender"
-- para n crafts, e k = perda esperada no pior caso para os pontos do passo (crafts esperados).
local function contas(p, n)
  n = tonumber(n) or tonumber(p.crafts) or 0
  local mats = type(p.precosMat) == "table" and p.precosMat or nil
  local venda = tonumber(p.vendaNpc) or 0
  local esperado = tonumber(p.esperado) or n
  if not mats or #mats == 0 then
    local custo = tonumber(p.custo) or 0
    return { custo = custo, piorCaso = tonumber(p.piorCaso) or 0, seVender = tonumber(p.seVender) or tonumber(p.piorCaso) or 0,
             k = esperado * (custo - venda) }
  end
  local soma = 0
  for _, g in ipairs(mats) do soma = soma + (tonumber(g.un) or 0) * unidade(g) end
  local custo = math.floor(soma + 0.5)
  local r = { custo = custo, piorCaso = n * (venda - custo), k = esperado * (custo - venda) }
  if not p.vinculado then
    local pl = vivoDe(p.produto) or tonumber(p.precoLeilao)
    if pl then r.seVender = n * (math.floor((tonumber(p.produtoQtd) or 1) * pl * 0.95 + 0.5) - custo) end
  end
  if r.seVender == nil then r.seVender = r.piorCaso end
  return r
end

-- Preco de um padrao a comprar: leilao (vivo, ou o da rota) ou vendedor; conhecido e treinador custam 0.
local function precoPadrao(magia, pd)
  if type(pd) ~= "table" or conhece(magia) then return 0 end
  if pd.situacao == "leilao" then return vivoDe(pd.id) or tonumber(pd.preco) or 0 end
  if pd.situacao == "vendedor" then return tonumber(pd.preco) or 0 end
  return 0
end

-- Aviso de troca: a alternativa dos dados, com o preco de agora, perde menos que o passo nos mesmos pontos.
local function avisoTroca(p, c, primeira)
  local a = type(p.alternativa) == "table" and p.alternativa or nil
  if not a then return nil end
  local ca = contas(a, a.esperado)
  local altK = ca.k + precoPadrao(a.magia, a.padrao)
  local meuK = c.k + (primeira and precoPadrao(p.magia, p.padrao) or 0)
  if altK < meuK - MARGEM then
    return { s = "Cheaper now: " .. tostring(a.nome),
             sub = tostring(p.de) .. "-" .. tostring(p.ate) .. ": about " .. comSinal(-altK) .. " vs "
               .. comSinal(-meuK) .. " today. Ask for a new route.",
             icone = tonumber(a.produto) and ("item:" .. a.produto) or ICONE_PROF, itemId = tonumber(a.produto) }
  end
  return nil
end

-- Avisa a janela quando o Auctionator atualiza o banco de precos (pesquisa no leilao ou varredura).
local registrado = false
local function registrarAuctionator()
  if registrado then return end
  local A = apiAuctionator()
  if not (A and type(A.RegisterForDBUpdate) == "function") then return end
  registrado = pcall(A.RegisterForDBUpdate, CHAMADOR, function()
    if ns.agendar and ns.atualizarJanela then ns.agendar("crafts:precos", 1, ns.atualizarJanela) end
  end)
end
if ns.aoEntrar then ns.aoEntrar[#ns.aoEntrar + 1] = registrarAuctionator end

local function listaMateriais(mats, fator, pm)
  local porId = {}
  for _, g in ipairs(type(pm) == "table" and pm or {}) do porId[g.id] = g end
  local r = {}
  for _, m in ipairs(type(mats) == "table" and mats or {}) do
    local qtd = math.floor((tonumber(m.qtd) or 0) * (fator or 1) + 0.5)
    r[#r + 1] = { id = m.id, nome = m.nome, qtd = qtd, tem = temItem(m.id), dica = fabricarVale(porId[m.id]) }
  end
  return r
end

-- Bloco de um passo: cartao da receita e a fileira de materiais.
local function blocoPasso(b, p, agora, feito, primeira)
  local st = situacao(p)
  local c = contas(p)
  -- lucro vendendo ao vendedor: faixa verde e o texto diz "vendor profit" (destaque pedido pelo dono)
  local pagaNpc = c.piorCaso > 0
  local sub = moeda(c.custo) .. " each, " .. (pagaNpc and "vendor profit " or "worst case ") .. comSinal(c.piorCaso)
  if c.seVender ~= c.piorCaso then sub = sub .. ", if sold " .. comSinal(c.seVender) end
  add(b, {
    t = "receita", tam = agora and "grande" or "pequeno", destaque = agora or nil, apagado = feito or nil,
    cor = (pagaNpc and not feito) and "verde" or nil,
    icone = tonumber(p.produto) and ("item:" .. p.produto) or ICONE_PROF, itemId = tonumber(p.produto),
    s = tostring(p.nome) .. "  x" .. tostring(p.crafts), sub = sub,
    faixa = tostring(p.de) .. "-" .. tostring(p.ate), pilula = { s = st.pil, cor = st.cor },
  })
  if not feito then
    local aviso = avisoTroca(p, c, primeira)
    if aviso then
      add(b, { t = "card", cor = "laranja", icone = aviso.icone, itemId = aviso.itemId, s = aviso.s, sub = aviso.sub })
    end
    add(b, { t = "materiais", recuo = 12, lista = listaMateriais(p.materiais, 1, p.precosMat) })
  end
end

-- Vendor profit (1.5, ARQUITETURA.md 13.7) ---------------------------------------------------------

-- cor da receita na pericia s (a do jogo), para saber se ainda da ponto
local function corPericia(v, s)
  s = tonumber(s)
  local am, ci = tonumber(v.amarela), tonumber(v.cinza)
  if not (s and am and ci) or (tonumber(v.pontos) or 0) == 0 then return "gray" end
  if s < am then return "orange" end
  if s < (am + ci) / 2 then return "yellow" end
  if s < ci then return "green" end
  return "gray"
end

-- quantas da para fazer agora com o que tem nas bolsas e no banco
local function daParaFazer(v)
  local n
  for _, m in ipairs(type(v.materiais) == "table" and v.materiais or {}) do
    local q = tonumber(m.qtd) or 0
    if q > 0 then
      local k = math.floor((temItem(m.id) or 0) / q)
      if n == nil or k < n then n = k end
    end
  end
  return n or 0
end

local MAX_VENDOR, COM_MATERIAIS = 8, 3

-- As receitas que voce ja pode fazer e que pagam no vendedor ao preco de agora, maior lucro por craft primeiro.
local function secaoVendor(b, R, per)
  local lista = {}
  for _, v in ipairs(type(R.lucroNpc) == "table" and R.lucroNpc or {}) do
    if conhece(v.magia) or (per and (tonumber(v.aprende) or 999) <= per) then
      local c = contas(v, 1)
      local lucro = (tonumber(v.vendaNpc) or 0) - c.custo
      if lucro > 0 then lista[#lista + 1] = { v = v, lucro = lucro } end
    end
  end
  table.sort(lista, function(a, c) return a.lucro > c.lucro end)
  add(b, { t = "sec", s = "Vendor profit", id = "crafts:vendedor", qtd = #lista > 0 and (#lista .. " pay now") or nil })
  if #lista == 0 then
    add(b, { t = "nota", s = "No recipe you can make pays at the vendor at today's prices." })
    return
  end
  for i, x in ipairs(lista) do
    if i > MAX_VENDOR then break end
    local v = x.v
    local st = situacao(v)
    local lim = tonumber(v.limite)
    local sub = "+" .. moeda(x.lucro) .. " each, " .. (lim and ("market ~" .. lim .. "/day") or "no market limit")
      .. ", can make " .. daParaFazer(v) .. " now"
    local padrao = precoPadrao(v.magia, v.padrao)
    if padrao > 0 then sub = sub .. ", pattern back in " .. math.ceil(padrao / x.lucro) end
    add(b, {
      t = "receita", tam = "pequeno", cor = "verde",
      icone = tonumber(v.produto) and ("item:" .. v.produto) or ICONE_PROF, itemId = tonumber(v.produto),
      s = tostring(v.nome), sub = sub, faixa = corPericia(v, per), pilula = { s = st.pil, cor = st.cor },
    })
    if i <= COM_MATERIAIS then
      add(b, { t = "materiais", recuo = 12, lista = listaMateriais(v.materiais, 1, v.precosMat) })
    end
  end
end

-- Totais da rota inteira com o preco de agora (padroes a comprar contados uma vez).
local function totaisVivos(R)
  local t = { crafts = 0, custo = 0, piorCaso = 0, seVender = 0, padroes = 0 }
  local vistos = {}
  for _, p in ipairs(R.passos) do
    local c = contas(p)
    local n = tonumber(p.crafts) or 0
    t.crafts = t.crafts + n
    t.custo = t.custo + n * c.custo
    t.piorCaso = t.piorCaso + c.piorCaso
    t.seVender = t.seVender + c.seVender
    local pd = type(p.padrao) == "table" and p.padrao or {}
    local chave = pd.id or ("magia:" .. tostring(p.magia))
    if not vistos[chave] then
      vistos[chave] = true
      t.padroes = t.padroes + precoPadrao(p.magia, pd)
    end
  end
  return t
end

-- Aba Crafts ---------------------------------------------------------------------------------------

AB.crafts = function(b, ctx)
  local R = rota()
  if not R then
    add(b, { t = "vazio", s = "No crafting route yet. Ask the agent to make one with fresh prices." })
    return
  end
  memo, contagem = {}, { vivos = 0, total = 0 }
  registrarAuctionator()
  local per = pericia()
  local t = totaisVivos(R)
  local padroes = t.padroes
  local precosTxt
  if contagem.vivos > 0 then
    precosTxt = "Live AH prices (Auctionator): " .. contagem.vivos .. " of " .. contagem.total .. " items seen today"
  else
    precosTxt = "Prices of " .. tostring(R.precos or "?") .. " (search the items on the AH to update)"
  end
  local linhas = {
    tostring(t.crafts) .. " crafts, skill " .. R.de .. " to " .. R.ate,
    "Materials " .. moeda(t.custo) .. (padroes > 0 and (", patterns " .. moeda(padroes)) or ""),
    "Worst case " .. comSinal(t.piorCaso - padroes) .. ", if all sells " .. comSinal(t.seVender),
    precosTxt,
  }
  local atual = per or R.de
  add(b, {
    t = "perfil", icone = ICONE_PROF, titulo = PROF .. " route", sub = linhas,
    barras = { { s = tostring(per or "?") .. "/" .. R.ate, valor = atual, max = R.ate,
                 cor = (atual >= R.ate) and "laranja" or "verde" } },
  })

  if atual >= R.ate then
    add(b, { t = "card", cor = "laranja", icone = ICONE_PROF, s = "Route done at " .. R.ate,
             sub = "Ask the agent for the next route with fresh prices." })
    return
  end

  local idx = #R.passos + 1
  for i, p in ipairs(R.passos) do
    if atual < p.ate then idx = i; break end
  end

  -- primeira vez de cada receita na rota: e nela que o preco do padrao conta
  local primeiraVez, jaVista = {}, {}
  for i, q in ipairs(R.passos) do
    if not jaVista[q.magia] then jaVista[q.magia] = true; primeiraVez[i] = true end
  end

  if ctx and ctx.tudo and idx > 1 then
    add(b, { t = "sec", s = "Done", id = "crafts:feito", aberta = false, qtd = idx - 1 })
    for i = 1, idx - 1 do blocoPasso(b, R.passos[i], false, true, primeiraVez[i]) end
  end

  local p = R.passos[idx]
  if p then
    add(b, { t = "sec", s = "Now", id = "crafts:agora" })
    if per and per < R.de then
      add(b, { t = "nota", s = "Your skill is below the start of this route (" .. R.de .. ")." })
    end
    blocoPasso(b, p, true, false, primeiraVez[idx])
  end

  secaoVendor(b, R, per)

  if idx < #R.passos then
    add(b, { t = "sec", s = "Next", id = "crafts:prox", qtd = (#R.passos - idx) .. " steps" })
    for i = idx + 1, #R.passos do blocoPasso(b, R.passos[i], false, false, primeiraVez[i]) end
  end

  -- padroes e receitas que faltam aprender, uma linha por receita
  local vistas, itens = {}, {}
  for i = idx, #R.passos do
    local q = R.passos[i]
    if not vistas[q.magia] then
      vistas[q.magia] = true
      local st = situacao(q)
      local pd = type(q.padrao) == "table" and q.padrao or {}
      itens[#itens + 1] = {
        t = "item", estado = st.estado,
        icone = tonumber(pd.id) and ("item:" .. pd.id) or ICONE_TREINO, itemId = tonumber(pd.id),
        s = tostring(pd.nome or q.nome), sub = st.sub,
      }
    end
  end
  for _, e in ipairs(type(R.esperar) == "table" and R.esperar or {}) do
    if not conhece(e.magia) then
      local v = type(e.visto) == "table" and e.visto or nil
      local visto = v and ("seen " .. diaTxt(v.dia) .. " at " .. moeda(v.min)) or "never seen there"
      itens[#itens + 1] = {
        t = "item", estado = "falta", icone = tonumber(e.padrao) and ("item:" .. e.padrao) or ICONE_TREINO,
        itemId = tonumber(e.padrao), s = tostring(e.padraoNome or e.nome),
        sub = "Not on the AH now; " .. visto .. ". Cheaper route if you find it.",
      }
    end
  end
  if #itens > 0 then
    -- o que pede acao primeiro: comprar agora, vigiar no leilao, aprender no treinador, ja sabe
    local ordemEstado = { agora = 1, falta = 2, depois = 3, feito = 4 }
    for i, it in ipairs(itens) do it._i = i end
    table.sort(itens, function(a, c)
      local pa, pc = ordemEstado[a.estado] or 5, ordemEstado[c.estado] or 5
      if pa ~= pc then return pa < pc end
      return a._i < c._i
    end)
    add(b, { t = "sec", s = "Patterns", id = "crafts:padroes", qtd = #itens, limite = 6 })
    for _, it in ipairs(itens) do
      it._i = nil
      add(b, it)
    end
  end

  -- lista de compras: o resto da rota somado
  local soma, ordem, precoMat = {}, {}, {}
  for i = idx, #R.passos do
    for _, g in ipairs(type(R.passos[i].precosMat) == "table" and R.passos[i].precosMat or {}) do
      if precoMat[g.id] == nil then precoMat[g.id] = g end
    end
    for _, m in ipairs(type(R.passos[i].materiais) == "table" and R.passos[i].materiais or {}) do
      if not soma[m.id] then
        soma[m.id] = { id = m.id, nome = m.nome, qtd = 0 }
        ordem[#ordem + 1] = m.id
      end
      soma[m.id].qtd = soma[m.id].qtd + (tonumber(m.qtd) or 0)
    end
  end
  if #ordem > 0 then
    table.sort(ordem, function(a, c) return soma[a].qtd > soma[c].qtd end)
    local lista = {}
    for _, id in ipairs(ordem) do lista[#lista + 1] = soma[id] end
    local itens = listaMateriais(lista)
    -- o que falta comprar (precisa menos o que tem), ao preco de agora
    local falta, semPreco = 0, false
    for _, m in ipairs(itens) do
      local g = precoMat[m.id]
      local n = math.max(0, (tonumber(m.qtd) or 0) - (tonumber(m.tem) or 0))
      if n > 0 then
        if g then falta = falta + n * unidade(g) else semPreco = true end
      end
    end
    add(b, { t = "sec", s = "Shopping list", id = "crafts:compras", qtd = "rest of the route" })
    add(b, { t = "nota", s = "Still to buy: " .. moeda(math.floor(falta + 0.5)) .. (semPreco and " (some items without a price)" or "")
             .. ", at " .. (contagem.vivos > 0 and "today's AH prices." or "the route's prices.") })
    add(b, { t = "materiais", titulo = "On the icon: what the rest of the route needs. Below: what you have (bags and bank) / needed.",
             lista = itens })
  end

  add(b, { t = "sec", s = "About this route", id = "crafts:sobre", aberta = false })
  add(b, { t = "nota", s = "Worst case = you sell every craft to a vendor. Costs use the Auctionator price of each item seen today (search it on the AH or scan); without it, the route's prices." })
  add(b, { t = "nota", s = "What you already bought counts at today's price (what it is worth now). An orange card means another recipe got cheaper for that range: ask the agent for a new route." })
  add(b, { t = "nota", s = "Known recipes are read when you open your Leatherworking window." })
  add(b, { t = "nota", s = "The chance of a skill point uses the Classic formula, not yet checked on Forever." })
end

-- a aba so aparece com rota nos dados e para quem tem Leatherworking
function ns.craftsVisivel()
  return rota() ~= nil and pericia() ~= nil
end
