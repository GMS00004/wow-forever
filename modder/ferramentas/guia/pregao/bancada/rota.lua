-- Falsos da modalidade de rota do CompraForever (CONTRATO 12.9): profissao por cenario, receitas com amarela/cinza/pontos/foco/
-- ferramentas/encantar, subida de pericia no craft, UnitLevel, GetProfessions e afins, requisitos, StopRecipeRepeat, treinador
-- (so leitura), caixa de correio, reload_real, inicio.dados e __bancada.fixture("eng150").
-- Fengari (Lua 5.3). So ASCII. Carregado depois de compra.lua e antes de executor.lua. Todo campo novo e opcional: sem eles o
-- comportamento e o de compra.lua.
--
-- Campos de `inicio`: profissoes = { { id, nome, nivel, max } }, nivel (UnitLevel, padrao 60), perto = { Anvil = true },
--   pericia_modo = "nunca" | "sempre" | "roteiro" | "aleatorio", pericia_roteiro = { true, false, ... } (um por craft que deu
--   certo; sobe se true e a chance for > 0), semente_pericia, ordem_pericia = { "CHAT_MSG_SKILL", "SKILL_LINES_CHANGED",
--   "TRADE_SKILL_LIST_UPDATE" }, eventos_pericia = false, apis_prof = "nil", dados = { ... } (mesclado em CompraForeverDados),
--   correio[i].anexo = { itemID, qtd } (carta inicial com anexo). Parametro novo: craft_lote = "todos" | "um".
-- Receita (inicio.receitas, definir_receitas): amarela, cinza, pontos, prof (linha: numero ou nome), foco, ferramentas = { ids },
--   encantar = true (sem produto), aprende, treino (custo; aparece no treinador).
-- Passos: abrir_profissao = { nome = ... }, abrir_treinador, fechar_treinador, treinar = { magia }, treinar_rank = cap,
--   abrir_correio, fechar_correio, pegar_correio = true | n, reload_real.
-- Injecao: interromper_craft(k). B.ROTA e o estado; B.C.subidas guarda as subidas de pericia.

local B = __bancada
local A, J, C = B.A, B.J, B.C
local def = B.itemDef
local floor, min, max = math.floor, math.min, math.max
local registrar = B.registrar

A.P.craft_lote = "todos"

local EVENTOS_PERICIA = { "CHAT_MSG_SKILL", "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE" }
local NBOLSAS = 5

local R = {
  profs = nil, sel = nil, nivel = 60, perto = {}, apisNil = false,
  modo = "nunca", roteiro = {}, lcg = 1.0, nCasts = 0, ordem = EVENTOS_PERICIA, eventos = true,
  extra = {}, interromper = nil,
  treinadorAberto = false, correioAberto = false,
}
B.ROTA = R
C.subidas = {}
C.recusas = {}

-- ---------------------------------------------------------------------------
-- Utilidades
-- ---------------------------------------------------------------------------
local function ehLista(t) return type(t) == "table" and t[1] ~= nil end

-- mescla `over` em `dest`: tabelas com chaves se fundem; listas, tabelas vazias e valores simples substituem
local function mesclar(dest, over)
  for k, v in pairs(over) do
    if type(v) == "table" and next(v) ~= nil and not ehLista(v) and type(dest[k]) == "table" and not ehLista(dest[k]) then
      mesclar(dest[k], v)
    else
      dest[k] = B.copiaProfunda(v)
    end
  end
  return dest
end
B.mesclar = mesclar

local function copiaRasa(t)
  local c = {}
  for k, v in pairs(t) do c[k] = v end
  return c
end

-- ---------------------------------------------------------------------------
-- Bolsas (copia das de compra.lua: sao locais la)
-- ---------------------------------------------------------------------------
local function itemEm(bag, slot)
  local b = A.bolsas[bag]
  return b and b[slot] or nil
end

local function contar(id)
  local n = 0
  for bag = 0, NBOLSAS - 1 do
    for s = 1, A.P.tamanho_bolsa do
      local it = itemEm(bag, s)
      if it and it.itemID == id then n = n + it.qtd end
    end
  end
  return n
end

local function capacidade(id)
  local pilha = def(id).pilha
  local cap = 0
  for bag = 0, NBOLSAS - 1 do
    for s = 1, A.P.tamanho_bolsa do
      local it = itemEm(bag, s)
      if not it then cap = cap + pilha
      elseif it.itemID == id then cap = cap + max(0, pilha - it.qtd) end
    end
  end
  return cap
end

local function colocar(id, qtd, tocadas)
  local pilha = def(id).pilha
  local falta = qtd
  for bag = 0, NBOLSAS - 1 do
    for s = 1, A.P.tamanho_bolsa do
      if falta <= 0 then return end
      local it = itemEm(bag, s)
      if it and it.itemID == id and it.qtd < pilha then
        local n = min(falta, pilha - it.qtd)
        it.qtd = it.qtd + n
        falta = falta - n
        tocadas[bag] = true
      end
    end
  end
  for bag = 0, NBOLSAS - 1 do
    for s = 1, A.P.tamanho_bolsa do
      if falta <= 0 then return end
      if not itemEm(bag, s) then
        local n = min(falta, pilha)
        A.bolsas[bag] = A.bolsas[bag] or {}
        A.bolsas[bag][s] = { itemID = id, qtd = n }
        falta = falta - n
        tocadas[bag] = true
      end
    end
  end
end

local function tirar(id, qtd, tocadas)
  local falta = qtd
  for bag = 0, NBOLSAS - 1 do
    for s = 1, A.P.tamanho_bolsa do
      local it = itemEm(bag, s)
      if falta > 0 and it and it.itemID == id then
        local n = min(falta, it.qtd)
        it.qtd = it.qtd - n
        falta = falta - n
        if it.qtd <= 0 then A.bolsas[bag][s] = nil end
        tocadas[bag] = true
      end
    end
  end
end

local function avisar(tocadas)
  local algum = false
  for bag = 0, NBOLSAS - 1 do
    if tocadas[bag] then algum = true; B.disparar("BAG_UPDATE", bag) end
  end
  if algum then B.disparar("BAG_UPDATE_DELAYED") end
end

-- ---------------------------------------------------------------------------
-- Receitas: campos novos ficam em R.extra[magia]; a normalizacao de compra.lua exige `produto`
-- ---------------------------------------------------------------------------
local CAMPOS_EXTRA = { "amarela", "cinza", "pontos", "prof", "foco", "ferramentas", "encantar", "aprende", "treino" }

-- devolve a tabela de receitas aceita por compra.lua (copia, sem tocar a do cenario) e guarda os extras
local function sanearReceitas(tab)
  if type(tab) ~= "table" then return tab end
  local out = {}
  for magia, spec in pairs(tab) do
    local c = type(spec) == "table" and copiaRasa(spec) or spec
    if type(spec) == "table" then
      local x = {}
      for _, k in ipairs(CAMPOS_EXTRA) do x[k] = spec[k] end
      R.extra[tonumber(magia)] = x
      if spec.encantar and spec.produto == nil then c.produto = 0 end
    end
    out[magia] = c
  end
  return out
end

local function ajustarEncantos(tab)
  for magia in pairs(tab or {}) do
    local x = R.extra[tonumber(magia)]
    local r = C.receitas[tonumber(magia)]
    if x and r and x.encantar then r.produto = nil end
  end
end

-- ---------------------------------------------------------------------------
-- Profissao
-- ---------------------------------------------------------------------------
local function nivelEMax()
  if R.profs and R.sel then return R.sel.nivel, R.sel.max end
  return C.prof.nivel, 300
end

local function definirNivel(n)
  if R.profs and R.sel then R.sel.nivel = n end
  C.prof.nivel = n
end

local function achar(nome)
  for _, p in ipairs(R.profs or {}) do
    if p.nome == nome then return p end
  end
  return nil
end

local function profBate(x)
  if not x or x.prof == nil or not (R.profs and R.sel) then return true end
  return x.prof == R.sel.id or x.prof == R.sel.nome
end

local function TS(nome, fn) B.def(C_TradeSkillUI, "C_TradeSkillUI", nome, fn) end

TS("GetAllRecipeIDs", function()
  local ids = {}
  if not C.prof.aberta then return ids end
  for magia in pairs(C.receitas) do
    if profBate(R.extra[magia]) then ids[#ids + 1] = magia end
  end
  table.sort(ids)
  return ids
end)

local function dificuldade(x, s)
  if not x or not x.amarela or not x.cinza then return nil end
  if s < x.amarela then return 0 end
  if s >= x.cinza then return 3 end
  if s < (x.amarela + x.cinza) / 2 then return 1 end
  return 2
end

TS("GetRecipeInfo", function(id)
  local r = C.receitas[id]
  if not r or not C.prof.aberta or not profBate(R.extra[id]) then return nil end
  local info = { recipeID = id, name = r.nome, learned = r.aprendida }
  local x = R.extra[id]
  if x and (x.amarela or x.cinza or x.pontos) then
    info.relativeDifficulty = dificuldade(x, (nivelEMax()))
    info.numSkillUps = x.pontos or 0
  end
  return info
end)

local function infoProf()
  if not C.prof.aberta then return { professionID = 0, skillLevel = 0, maxSkillLevel = 0, skillModifier = 0 } end
  if R.profs and R.sel then
    local p = R.sel
    return { professionID = p.id, professionName = p.nome, skillLevel = p.nivel, maxSkillLevel = p.max, skillModifier = 0,
      parentProfessionID = p.id, parentProfessionName = p.nome }
  end
  return { professionID = 165, professionName = C.prof.nome, skillLevel = C.prof.nivel, maxSkillLevel = 300, skillModifier = 0 }
end
TS("GetBaseProfessionInfo", infoProf)
TS("GetChildProfessionInfo", infoProf)

function UnitLevel(tok)
  registrar("UnitLevel", nil, tok)
  if tok == "player" then return R.nivel end
  return nil
end

-- listas de profissoes (nil sem inicio.profissoes ou com apis_prof = "nil")
local function temApis() return R.profs ~= nil and not R.apisNil end

B.def(_G, nil, "GetProfessions", function()
  if not temApis() then return nil end
  local n = #R.profs
  return n >= 1 and 1 or nil, n >= 2 and 2 or nil, n >= 3 and 3 or nil, n >= 4 and 4 or nil, n >= 5 and 5 or nil
end)
B.def(_G, nil, "GetProfessionInfo", function(i)
  if not temApis() then return nil end
  local p = R.profs[i]
  if not p then return nil end
  return p.nome, 134400, p.nivel, p.max, 0, 0, p.id, 0
end)
TS("GetProfessionInfoBySkillLineID", function(id)
  if not temApis() then return nil end
  local p
  for _, q in ipairs(R.profs) do if q.id == id then p = q end end
  if not p then return nil end
  return { professionID = p.id, professionName = p.nome, skillLevel = p.nivel, maxSkillLevel = p.max, skillModifier = 0,
    parentProfessionID = p.id, parentProfessionName = p.nome }
end)
C_SkillInfo = {}
B.def(C_SkillInfo, "C_SkillInfo", "GetNumSkillLines", function()
  if not temApis() then return nil end
  return #R.profs
end)
B.def(C_SkillInfo, "C_SkillInfo", "GetSkillLineInfoByID", function(id)
  if not temApis() then return nil end
  for _, p in ipairs(R.profs) do
    if p.id == id then
      return { skillLineID = p.id, skillLineName = p.nome, professionName = p.nome, skillLevel = p.nivel, maxSkillLevel = p.max, skillModifier = 0 }
    end
  end
  return nil
end)

-- requisitos de proximidade
TS("GetRecipeRequirements", function(magia)
  local x = R.extra[magia]
  if x and x.foco then return { { name = x.foco, met = R.perto[x.foco] == true } } end
  return {}
end)

-- ---------------------------------------------------------------------------
-- Craft: ferramenta, foco, pericia, eventos, lote, interrupcao
-- ---------------------------------------------------------------------------
-- chance de subir, igual ao CONTRATO 12.4
local function chance(x, s)
  local pontos = x and x.pontos or 0
  if pontos <= 0 then return 0 end
  local am = x.amarela or 0
  local ci = x.cinza or am
  if s < am then return 1 end
  if s >= ci then return 0 end
  return (ci - s) / (ci - am)
end
B.rotaChance = chance

local function sorteio()
  R.lcg = (R.lcg * 48271.0) % 2147483647.0
  return R.lcg / 2147483647.0
end

local function subirPericia(magia, x)
  R.nCasts = R.nCasts + 1
  local s, teto = nivelEMax()
  local ch = chance(x, s)
  local sobe
  if R.modo == "sempre" then
    sobe = ch > 0
  elseif R.modo == "roteiro" then
    sobe = R.roteiro[R.nCasts] == true and ch > 0
  elseif R.modo == "aleatorio" then
    sobe = sorteio() < ch
  else
    sobe = false
  end
  if not sobe or s >= teto then return end
  local novo = min(teto, s + (x.pontos or 1))
  definirNivel(novo)
  C.subidas[#C.subidas + 1] = { magia = magia, de = s, para = novo, prof = R.sel and R.sel.nome or C.prof.nome }
  if not R.eventos then return end
  local nome = R.sel and R.sel.nome or C.prof.nome
  for _, ev in ipairs(R.ordem) do
    if ev == "CHAT_MSG_SKILL" then
      B.disparar(ev, "Your skill in " .. nome .. " has increased to " .. tostring(novo) .. ".", "")
    else
      B.disparar(ev)
    end
  end
end

-- motivo de falha por ferramenta ou foco, ou nil
local function faltaRequisito(x)
  if x and type(x.ferramentas) == "table" and #x.ferramentas > 0 then
    local tem = false
    for _, id in ipairs(x.ferramentas) do if contar(id) > 0 then tem = true end end
    if not tem then return "Requires " .. def(x.ferramentas[1]).nome end
  end
  if x and x.foco and R.perto[x.foco] ~= true then return "Requires " .. x.foco end
  return nil
end

-- uma unidade: confere reagentes e espaco, consome e entrega o produto (se houver)
local function umCraft(r)
  for _, rg in ipairs(r.reagentes) do
    if contar(rg[1]) < rg[2] then return false, "Missing reagents" end
  end
  local tocadas = {}
  for _, rg in ipairs(r.reagentes) do tirar(rg[1], rg[2], tocadas) end
  if r.produto then
    if capacidade(r.produto) < r.qtd then
      for _, rg in ipairs(r.reagentes) do colocar(rg[1], rg[2], tocadas) end
      avisar(tocadas)
      return false, "Inventory is full"
    end
    colocar(r.produto, r.qtd, tocadas)
  end
  avisar(tocadas)
  return true
end

TS("CraftRecipe", function(magia, n)
  if not C.prof.aberta then
    B.violar("profissao", "CraftRecipe com a janela de profissao fechada")
    return
  end
  local r = C.receitas[magia]
  if not r or not r.aprendida then
    B.violar("profissao", "CraftRecipe de receita desconhecida ou nao aprendida: " .. tostring(magia))
    return
  end
  local x = R.extra[magia] or {}
  if x.encantar then
    B.violar("encanto", "CraftRecipe de receita de encantamento sem item: " .. tostring(magia))
    return
  end
  if type(n) ~= "number" or n < 1 then n = 1 end
  if A.P.craft_lote == "um" then n = 1 end
  local lim = R.interromper
  R.interromper = nil
  C.craftEpoca = C.craftEpoca + 1   -- um pedido novo substitui o que sobrava do anterior
  local ep = C.craftEpoca
  local guid = "Cast-3-1-1-" .. tostring(magia) .. "-" .. tostring(ep)
  for k = 1, floor(n) do
    B.agendar(A.P.t_craft * k, function()
      if ep ~= C.craftEpoca then return end
      if lim and k == lim + 1 then
        C.craftEpoca = C.craftEpoca + 1
        B.disparar("UNIT_SPELLCAST_INTERRUPTED", "player", guid, magia)
        return
      end
      local ok, motivo
      local falta = faltaRequisito(x)
      if falta then ok, motivo = false, falta else ok, motivo = umCraft(r) end
      if not ok then
        C.craftEpoca = C.craftEpoca + 1
        B.disparar("UI_ERROR_MESSAGE", 0, motivo)
        return
      end
      subirPericia(magia, x)
      B.disparar("UNIT_SPELLCAST_SUCCEEDED", "player", guid, magia)
    end)
  end
end)

TS("StopRecipeRepeat", function()
  C.craftEpoca = C.craftEpoca + 1
  B.disparar("UPDATE_TRADESKILL_CAST_STOPPED")
end)

TS("CraftEnchant", function(magia)
  B.violar("encanto", "CraftEnchant(" .. tostring(magia) .. ")")
end)

B.INJECOES.interromper_craft = function(k) R.interromper = k or 1 end

-- ---------------------------------------------------------------------------
-- Treinador (so leitura)
-- ---------------------------------------------------------------------------
ClassTrainerFrame = CreateFrame("Frame", "ClassTrainerFrame", UIParent)
ClassTrainerFrame:SetSize(338, 424)
ClassTrainerFrame:Hide()
MailFrame = CreateFrame("Frame", "MailFrame", UIParent)
MailFrame:SetSize(384, 512)
MailFrame:Hide()

local function listaTreino()
  local out = {}
  for magia, r in pairs(C.receitas) do
    local x = R.extra[magia]
    if x and x.treino ~= nil and profBate(x) then out[#out + 1] = { magia = magia, r = r, x = x } end
  end
  table.sort(out, function(a, b)
    local pa, pb = a.x.aprende or 0, b.x.aprende or 0
    if pa ~= pb then return pa < pb end
    return a.magia < b.magia
  end)
  return out
end

B.def(_G, nil, "GetNumTrainerServices", function()
  if not R.treinadorAberto then return 0 end
  return #listaTreino()
end)
B.def(_G, nil, "GetTrainerServiceInfo", function(i)
  if not R.treinadorAberto then return nil end
  local e = listaTreino()[i]
  if not e then return nil end
  local tipo
  if e.r.aprendida then tipo = "used"
  elseif (e.x.aprende or 0) <= (nivelEMax()) then tipo = "available"
  else tipo = "unavailable" end
  return e.r.nome, "", tipo
end)
B.def(_G, nil, "BuyTrainerService", function(i)
  B.violar("treino", "BuyTrainerService(" .. tostring(i) .. ")")
end)

local function abrirTreinador()
  if R.treinadorAberto then return end
  R.treinadorAberto = true
  ClassTrainerFrame:Show()
  B.disparar("TRAINER_SHOW")
end
local function fecharTreinador()
  if not R.treinadorAberto then return end
  R.treinadorAberto = false
  ClassTrainerFrame:Hide()
  B.disparar("TRAINER_CLOSED")
end

local function treinar(spec)
  local magia = type(spec) == "table" and spec.magia or spec
  local r = C.receitas[tonumber(magia)]
  if not r then error("treinar: receita desconhecida: " .. tostring(magia), 0) end
  r.aprendida = true
  B.disparar("NEW_RECIPE_LEARNED", r.magia)
  B.disparar("TRADE_SKILL_LIST_UPDATE")
end

local NIVEL_DO_CAP = { [75] = 1, [150] = 10, [225] = 20, [300] = 35 }
local function treinarRank(cap)
  if type(cap) ~= "number" or not NIVEL_DO_CAP[cap] then error("treinar_rank: cap invalido (75, 150, 225 ou 300): " .. tostring(cap), 0) end
  if not R.profs then error("treinar_rank: precisa de inicio.profissoes", 0) end
  local p = R.sel or R.profs[1]
  if R.nivel < NIVEL_DO_CAP[cap] then
    C.recusas[#C.recusas + 1] = { cap = cap, nivel = R.nivel, prof = p.nome }
    return
   end
  p.max = cap
  B.disparar("SKILL_LINES_CHANGED")
end

-- ---------------------------------------------------------------------------
-- Correio (sobre as cartas de leilao.lua)
-- ---------------------------------------------------------------------------
B.def(_G, nil, "TakeInboxItem", function(i, j)
  B.violar("correio", "TakeInboxItem(" .. tostring(i) .. ", " .. tostring(j) .. ")")
end)
B.def(_G, nil, "AutoLootMailItem", function(i)
  B.violar("correio", "AutoLootMailItem(" .. tostring(i) .. ")")
end)

local function abrirCorreio()
  if R.correioAberto then return end
  R.correioAberto = true
  MailFrame:Show()
  B.disparar("MAIL_SHOW")
  B.disparar("MAIL_INBOX_UPDATE")
end
local function fecharCorreio()
  if not R.correioAberto then return end
  R.correioAberto = false
  MailFrame:Hide()
  B.disparar("MAIL_CLOSED")
end

-- o dono pega as cartas na ordem da caixa: anexo vai para as bolsas, ouro para a carteira; carta vazia some
local function pegarCorreio(spec)
  if not R.correioAberto then error("pegar_correio: a caixa de correio nao esta aberta", 0) end
  local limite
  if spec == true then limite = math.huge else limite = tonumber(spec) end
  if not limite then error("pegar_correio: precisa de true ou de um numero", 0) end
  local feitas, tocadas, cheio = 0, {}, false
  local i = 1
  while i <= #A.correio and feitas < limite do
    local c = A.correio[i]
    local tem = c.anexo ~= nil or (c.dinheiro or 0) > 0
    if tem then
      if c.anexo then
        if capacidade(c.anexo.itemID) < c.anexo.qtd then cheio = true break end
        colocar(c.anexo.itemID, c.anexo.qtd, tocadas)
        c.anexo = nil
        c.itens = 0
      end
      if (c.dinheiro or 0) > 0 then
        local d = c.dinheiro
        c.dinheiro = 0
        B.mudarDinheiro(d)
      end
      feitas = feitas + 1
    end
    if not c.anexo and (c.dinheiro or 0) == 0 and tem then table.remove(A.correio, i) else i = i + 1 end
  end
  avisar(tocadas)
  if cheio then B.disparar("UI_ERROR_MESSAGE", 0, "Inventory is full") end
  if feitas > 0 then B.disparar("MAIL_INBOX_UPDATE") end
end

-- ---------------------------------------------------------------------------
-- reload_real: fecha o estado das janelas sem evento e roda o reload de verdade
-- ---------------------------------------------------------------------------
local function esconder(frame)
  local e = B.E[frame]
  if e then e.visivel = false end
end

local function reloadReal()
  local disparar = B.disparar
  B.disparar = function() end
  local ok, err = pcall(function()
    if A.aberto then
      esconder(AuctionHouseFrame)
      B.fecharLeilao()
    end
    C.vendedor.aberto = false
    esconder(MerchantFrame)
    C.prof.aberta = false
    C.craftEpoca = C.craftEpoca + 1
    R.correioAberto = false
    esconder(MailFrame)
    R.treinadorAberto = false
    esconder(ClassTrainerFrame)
  end)
  B.disparar = disparar
  if not ok then error(err, 0) end
  B.recarregar()
end

-- ---------------------------------------------------------------------------
-- inicio.dados
-- ---------------------------------------------------------------------------
function B.aposCarregar(ini)
  if type(ini) ~= "table" or type(ini.dados) ~= "table" then return end
  local atual = rawget(_G, "CompraForeverDados")
  if type(atual) ~= "table" then atual = {}; rawset(_G, "CompraForeverDados", atual) end
  mesclar(atual, ini.dados)
end

-- ---------------------------------------------------------------------------
-- Estado inicial e passos
-- ---------------------------------------------------------------------------
local configurarOrig = B.configurar
function B.configurar(ini)
  ini = ini or {}
  R.extra = {}
  R.interromper = nil
  R.treinadorAberto, R.correioAberto = false, false
  R.nCasts = 0
  C.subidas, C.recusas = {}, {}
  local c2 = ini
  if ini.receitas ~= nil then
    c2 = copiaRasa(ini)
    c2.receitas = sanearReceitas(ini.receitas)
  end
  configurarOrig(c2)
  ajustarEncantos(ini.receitas)

  R.profs, R.sel = nil, nil
  if ini.profissoes ~= nil then
    if type(ini.profissoes) ~= "table" then error("bancada: inicio.profissoes precisa ser uma lista", 0) end
    R.profs = {}
    for i, p in ipairs(ini.profissoes) do
      if type(p.id) ~= "number" or type(p.nome) ~= "string" then error("bancada: inicio.profissoes[" .. i .. "] precisa de id e nome", 0) end
      R.profs[i] = { id = p.id, nome = p.nome, nivel = p.nivel or 1, max = p.max or 75 }
    end
  end
  R.nivel = ini.nivel or 60
  R.perto = B.copiaProfunda(ini.perto or {})
  R.apisNil = ini.apis_prof == "nil"
  R.modo = ini.pericia_modo or "nunca"
  if R.modo ~= "nunca" and R.modo ~= "sempre" and R.modo ~= "roteiro" and R.modo ~= "aleatorio" then
    error("bancada: inicio.pericia_modo desconhecido: " .. tostring(R.modo), 0)
  end
  R.roteiro = ini.pericia_roteiro or {}
  R.lcg = ((tonumber(ini.semente_pericia) or 1) % 2147483646) + 1.0
  R.eventos = ini.eventos_pericia ~= false
  R.ordem = EVENTOS_PERICIA
  if ini.ordem_pericia ~= nil then
    for _, ev in ipairs(ini.ordem_pericia) do
      local ok = false
      for _, e in ipairs(EVENTOS_PERICIA) do if e == ev then ok = true end end
      if not ok then error("bancada: inicio.ordem_pericia com evento desconhecido: " .. tostring(ev), 0) end
    end
    R.ordem = ini.ordem_pericia
  end
  -- cartas iniciais com anexo (cartaDeInicio de leilao.lua nao copia o anexo)
  for i, c in ipairs(ini.correio or {}) do
    if c.anexo and A.correio[i] then
      A.correio[i].anexo = { itemID = c.anexo.itemID, qtd = c.anexo.qtd or 1 }
      A.correio[i].itens = 1
    end
  end
end

local PX = B.PASSOS_EXTRA
local abrirOrig = PX.abrir_profissao
PX.abrir_profissao = function(spec)
  if R.profs then
    local p
    if type(spec) == "table" and spec.nome ~= nil then
      p = achar(spec.nome)
      if not p then error("abrir_profissao: " .. tostring(spec.nome) .. " nao esta em inicio.profissoes", 0) end
    else
      p = R.sel or R.profs[1]
      if not p then error("abrir_profissao: inicio.profissoes esta vazio", 0) end
    end
    R.sel = p
    local s = { nome = p.nome, nivel = p.nivel }
    if type(spec) == "table" then
      for _, k in ipairs({ "linked", "guild", "npc" }) do s[k] = spec[k] end
    end
    return abrirOrig(s)
  end
  return abrirOrig(spec)
end

local definirOrig = PX.definir_receitas
PX.definir_receitas = function(tab)
  if type(tab) ~= "table" then return definirOrig(tab) end
  definirOrig(sanearReceitas(tab))
  ajustarEncantos(tab)
end

PX.abrir_treinador = function() abrirTreinador() end
PX.fechar_treinador = function() fecharTreinador() end
PX.treinar = function(spec) treinar(spec) end
PX.treinar_rank = function(cap) treinarRank(cap) end
PX.abrir_correio = function() abrirCorreio() end
PX.fechar_correio = function() fecharCorreio() end
PX.pegar_correio = function(spec) pegarCorreio(spec) end
PX.reload_real = function() reloadReal() end

-- ---------------------------------------------------------------------------
-- Fixture: Engineering do 1 ao 150 (CONTRATO 12.1), do relatorio legado-225-2026-11-23-1801
-- ---------------------------------------------------------------------------
local function fixtureEng150()
  -- id = { nome, vende (ao vendedor), pilha }
  local ITENS = {
    [2589] = { "Linen Cloth", 13, 20 }, [2592] = { "Wool Cloth", 33, 20 }, [2319] = { "Medium Leather", 50, 20 },
    [2836] = { "Coarse Stone", 15, 20 }, [2838] = { "Heavy Stone", 60, 20 }, [2840] = { "Copper Bar", 10, 20 },
    [2841] = { "Bronze Bar", 50, 20 }, [2880] = { "Weak Flux", 25, 10 }, [4357] = { "Rough Blasting Powder", 4, 20 },
    [4358] = { "Rough Dynamite", 30, 20 }, [4359] = { "Handful of Copper Bolts", 12, 20 }, [4360] = { "Rough Copper Bomb", 60, 10 },
    [4361] = { "Copper Tube", 120, 20 }, [4364] = { "Coarse Blasting Powder", 12, 20 }, [4365] = { "Coarse Dynamite", 75, 20 },
    [4370] = { "Large Copper Bomb", 175, 10 }, [4377] = { "Heavy Blasting Powder", 150, 20 }, [4378] = { "Heavy Dynamite", 350, 20 },
    [4382] = { "Bronze Framework", 600, 20 }, [4404] = { "Silver Contact", 25, 20 }, [5956] = { "Blacksmith Hammer", 3, 1 },
    [6712] = { "Practice Lock", 12, 1 },
  }
  -- magia = { nome, produto, qtd, reagentes, amarela, cinza, aprende, treino, origem, foco/ferramenta }
  local RECEITAS = {
    [3919] = { "Rough Dynamite", 4358, 2, { { 4357, 1 }, { 2589, 1 } }, 30, 60, 1, nil, "inicial", false },
    [3923] = { "Rough Copper Bomb", 4360, 2, { { 2840, 1 }, { 4359, 1 }, { 4357, 2 }, { 2589, 1 } }, 60, 90, 30, 130, "treinador", true },
    [3924] = { "Copper Tube", 4361, 1, { { 2840, 2 }, { 2880, 1 } }, 80, 110, 50, 150, "treinador", true },
    [3929] = { "Coarse Blasting Powder", 4364, 1, { { 2836, 1 } }, 85, 95, 75, 250, "treinador", false },
    [3931] = { "Coarse Dynamite", 4365, 2, { { 4364, 3 }, { 2589, 1 } }, 90, 105, 75, 250, "treinador", false },
    [8334] = { "Practice Lock", 6712, 1, { { 2841, 1 }, { 4359, 2 }, { 2880, 1 } }, 115, 130, 100, 300, "treinador", true },
    [3937] = { "Large Copper Bomb", 4370, 3, { { 2840, 3 }, { 4364, 4 }, { 4404, 1 } }, 105, 155, 105, 450, "treinador", true },
    [3946] = { "Heavy Dynamite", 4378, 3, { { 4377, 2 }, { 2592, 1 } }, 125, 145, 125, 500, "treinador", false },
    [3953] = { "Bronze Framework", 4382, 1, { { 2841, 2 }, { 2319, 1 }, { 2592, 1 } }, 145, 195, 145, 600, "treinador", false },
    [3945] = { "Heavy Blasting Powder", 4377, 1, { { 2838, 1 } }, 125, 145, 125, 500, "treinador", false },
  }
  local PASSOS = {
    { 3919, 1, 59, 119 }, { 3923, 59, 65, 7 }, { 3924, 65, 75, 10 }, { 3929, 75, 91, 19 }, { 3931, 91, 100, 15 },
    { 8334, 100, 105, 5 }, { 3937, 105, 125, 26 }, { 3946, 125, 145, 72 }, { 3953, 145, 150, 6 },
  }
  -- compras no leilao: id = { qtd, custo pelo livro, teto por unidade }
  local LEILAO = {
    [2838] = { 144, 50944, 354 }, [4364] = { 130, 12608, 97 }, [2840] = { 105, 11550, 110 }, [2592] = { 78, 11232, 144 },
    [2589] = { 141, 3807, 27 }, [2841] = { 17, 3145, 185 }, [4359] = { 17, 2040, 120 }, [4357] = { 133, 1809, 14 },
    [4404] = { 26, 1794, 69 }, [2836] = { 19, 1709, 92 }, [2880] = { 15, 1410, 94 }, [2319] = { 6, 720, 120 },
  }
  local AGORA = B.EPOCH

  local itens, ritens = {}, {}
  for id, d in pairs(ITENS) do
    itens[id] = { nome = d[1], vend = d[2], pilha = d[3], commodity = d[3] > 1 }
    ritens[id] = { nome = d[1], vende = d[2], pilha = d[3], vinculo = 0 }
  end

  local receitas, rreceitas = {}, {}
  for magia, d in pairs(RECEITAS) do
    local reag, rreag = {}, {}
    for i, rg in ipairs(d[4]) do reag[i] = { rg[1], rg[2] }; rreag[i] = { rg[1], rg[2] } end
    local x = {
      nome = d[1], produto = d[2], qtd = d[3], reagentes = reag, aprendida = d[9] == "inicial",
      amarela = d[5], cinza = d[6], pontos = 1, prof = 202, aprende = d[7], treino = d[8],
    }
    local rr = {
      nome = d[1], produto = d[2], qtd = d[3], reagentes = rreag, amarela = d[5], cinza = d[6], pontos = 1,
      aprende = d[7], origem = d[9],
    }
    if d[8] then rr.treino = d[8] end
    if d[10] then
      x.foco, x.ferramentas = "Anvil", { 5956 }
      rr.foco = "Anvil"
      rr.ferramentas = { { nome = "Blacksmith Hammer", itens = { 5956, 260811, 285280, 285281 } } }
    end
    receitas[magia] = x
    rreceitas[magia] = rr
  end

  local passos, fontes = {}, {}
  for i, p in ipairs(PASSOS) do passos[i] = { magia = p[1], de = p[2], ate = p[3], crafts = p[4] } end
  local mercado = {}
  for id, d in pairs(LEILAO) do
    fontes[id] = { f = "L", qtd = d[1], custo = d[2], teto = d[3] }
    local teto = d[3]
    mercado[id] = {
      { preco = floor(teto * 0.8), qtd = 200 }, { preco = floor(teto * 0.9), qtd = 200 }, { preco = teto, qtd = 200 },
    }
  end
  fontes[4377] = { f = "F", magia = 3945, qtd = 144 }
  fontes[5956] = { f = "V", qtd = 1, preco = 18 }

  return {
    dinheiro = 500000,
    nivel = 10,
    itens = itens,
    bolsas = {},
    receitas = receitas,
    mercado = mercado,
    vendedor = { { itemID = 5956, preco = 18 } },
    profissoes = { { id = 202, nome = "Engineering", nivel = 1, max = 75 } },
    perto = { Anvil = true },
    dados = {
      rotas = {
        versao = 1, geradoEm = AGORA - 3600, fonte = { tipo = "full", em = AGORA - 7200, n = 6944 }, credito = true,
        itens = ritens,
        profs = {
          engineering = {
            nome = "Engineering", curto = "Eng", linha = 202,
            ranks = {
              { nome = "Journeyman Engineering", cap = 150, pericia = 50, custo = 500, nivel = 10 },
              { nome = "Expert Engineering", cap = 225, pericia = 125, custo = 5000, nivel = 20 },
            },
            receitas = rreceitas,
            trechos = {
              { de = 1, ate = 150, chegou = 150, passos = passos, fontes = fontes,
                totais = { custo = 105916, crafts = 279, craftsExtra = 144 } },
            },
          },
        },
      },
    },
  }
end

local FIXTURES = { eng150 = fixtureEng150 }

function B.fixture(nome, over)
  local f = FIXTURES[nome]
  if not f then error("bancada: fixture desconhecida: " .. tostring(nome), 2) end
  local ini = f()
  if over ~= nil then mesclar(ini, over) end
  return ini
end

return B
