-- GuiaForever 1.4: aba Crafts da janela J (a rota de Leatherworking da ferramenta, com icones) e o
-- registro das receitas conhecidas, lido da janela de profissao quando o dono a abre (so leitura).
-- Contrato: ARQUITETURA.md, secao 13. Dados: RotaCrafts.lua (GuiaForeverRotaCrafts), gerado por
-- ferramentas/pregao/rota.mjs --addon. O codigo nao escolhe receita: so mostra a rota dos dados (regra 11).

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

local function listaMateriais(mats, fator)
  local r = {}
  for _, m in ipairs(type(mats) == "table" and mats or {}) do
    local qtd = math.floor((tonumber(m.qtd) or 0) * (fator or 1) + 0.5)
    r[#r + 1] = { id = m.id, nome = m.nome, qtd = qtd, tem = temItem(m.id) }
  end
  return r
end

-- Bloco de um passo: cartao da receita e a fileira de materiais.
local function blocoPasso(b, p, agora, feito)
  local st = situacao(p)
  local sub = moeda(p.custo) .. " each, worst case " .. comSinal(p.piorCaso)
  if tonumber(p.seVender) and p.seVender ~= p.piorCaso then sub = sub .. ", if sold " .. comSinal(p.seVender) end
  add(b, {
    t = "receita", tam = agora and "grande" or "pequeno", destaque = agora or nil, apagado = feito or nil,
    icone = tonumber(p.produto) and ("item:" .. p.produto) or ICONE_PROF, itemId = tonumber(p.produto),
    s = tostring(p.nome) .. "  x" .. tostring(p.crafts), sub = sub,
    faixa = tostring(p.de) .. "-" .. tostring(p.ate), pilula = { s = st.pil, cor = st.cor },
  })
  if not feito then add(b, { t = "materiais", recuo = 12, lista = listaMateriais(p.materiais) }) end
end

-- Aba Crafts ---------------------------------------------------------------------------------------

AB.crafts = function(b, ctx)
  local R = rota()
  if not R then
    add(b, { t = "vazio", s = "No crafting route yet. Ask the agent to make one with fresh prices." })
    return
  end
  local per = pericia()
  local t = type(R.totais) == "table" and R.totais or {}
  local padroes = tonumber(t.padroes) or 0
  local linhas = {
    tostring(t.crafts or "?") .. " crafts, skill " .. R.de .. " to " .. R.ate,
    "Materials " .. moeda(t.custo) .. (padroes > 0 and (", patterns " .. moeda(padroes)) or ""),
    "Worst case " .. comSinal((tonumber(t.piorCaso) or 0) - padroes) .. ", if all sells " .. comSinal(t.seVender),
    "Prices of " .. tostring(R.precos or "?"),
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

  if ctx and ctx.tudo and idx > 1 then
    add(b, { t = "sec", s = "Done", id = "crafts:feito", aberta = false, qtd = idx - 1 })
    for i = 1, idx - 1 do blocoPasso(b, R.passos[i], false, true) end
  end

  local p = R.passos[idx]
  if p then
    add(b, { t = "sec", s = "Now", id = "crafts:agora" })
    if per and per < R.de then
      add(b, { t = "nota", s = "Your skill is below the start of this route (" .. R.de .. ")." })
    end
    blocoPasso(b, p, true, false)
  end

  if idx < #R.passos then
    add(b, { t = "sec", s = "Next", id = "crafts:prox", qtd = (#R.passos - idx) .. " steps" })
    for i = idx + 1, #R.passos do blocoPasso(b, R.passos[i], false, false) end
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
  local soma, ordem = {}, {}
  for i = idx, #R.passos do
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
    add(b, { t = "sec", s = "Shopping list", id = "crafts:compras", qtd = "rest of the route" })
    add(b, { t = "materiais", titulo = "On the icon: what the rest of the route needs. Below: what you have (bags and bank) / needed.",
             lista = listaMateriais(lista) })
  end

  add(b, { t = "sec", s = "About this route", id = "crafts:sobre", aberta = false })
  add(b, { t = "nota", s = "Worst case = you sell every craft to a vendor. Prices are a snapshot: they get old in a few hours." })
  add(b, { t = "nota", s = "Known recipes are read when you open your Leatherworking window." })
  add(b, { t = "nota", s = "The chance of a skill point uses the Classic formula, not yet checked on Forever." })
end

-- a aba so aparece com rota nos dados e para quem tem Leatherworking
function ns.craftsVisivel()
  return rota() ~= nil and pericia() ~= nil
end
