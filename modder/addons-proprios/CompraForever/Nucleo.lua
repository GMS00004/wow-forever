local addon, ns = ...

-- Nucleo: eventos, SavedVariables, config, receitas conhecidas, dinheiro e bolsas, moeda, /compra, replanejar
-- (CONTRATO secao 3). Os outros modulos falam por `ns`.

local floor, max = math.floor, math.max

local PADROES = { reserva = 0, desconto = 10, lucroMin = 50, margemMin = 5, grande = 10000, pequena = 3000 }
local PROF = "Leatherworking"

-- Eventos --------------------------------------------------------------------------------------------

local ouvintes = {}
local quadro = CreateFrame("Frame")

function ns.ao(evento, fn)
  local l = ouvintes[evento]
  if not l then
    l = {}
    ouvintes[evento] = l
    quadro:RegisterEvent(evento)
  end
  l[#l + 1] = fn
end

quadro:SetScript("OnEvent", function(_, evento, ...)
  local l = ouvintes[evento]
  if not l then return end
  for i = 1, #l do l[i](...) end
end)

-- Moeda e valores ------------------------------------------------------------------------------------

function ns.moeda(cobre)
  cobre = tonumber(cobre)
  if not cobre or cobre < 0 then return "-" end
  cobre = floor(cobre)
  local g, s, c = floor(cobre / 10000), floor((cobre % 10000) / 100), cobre % 100
  local p = {}
  if g > 0 then p[#p + 1] = g .. "g" end
  if s > 0 then p[#p + 1] = (g > 0 and string.format("%02d", s) or tostring(s)) .. "s" end
  if c > 0 or #p == 0 then p[#p + 1] = ((g > 0 or s > 0) and string.format("%02d", c) or tostring(c)) .. "c" end
  return table.concat(p, " ")
end

-- "1g20s", "50s", "30c" ou numero puro (cobre); nil se nao entender
function ns.lerValor(texto)
  if type(texto) == "number" then return floor(texto) end
  if type(texto) ~= "string" then return nil end
  local t = string.lower((string.gsub(texto, "%s+", "")))
  if t == "" then return nil end
  if string.find(t, "^%d+$") then return tonumber(t) end
  local total, n = 0, 0
  local resto = string.gsub(t, "(%d+)([gsc])", function(num, u)
    n = n + 1
    total = total + tonumber(num) * (u == "g" and 10000 or (u == "s" and 100 or 1))
    return ""
  end)
  if n == 0 or resto ~= "" then return nil end
  return total
end

-- SavedVariables e config ----------------------------------------------------------------------------

function ns.config()
  return (CompraForeverDB and CompraForeverDB.config) or PADROES
end

local function iniciarSV()
  if type(CompraForeverDB) ~= "table" then CompraForeverDB = {} end
  if type(CompraForeverDB.config) ~= "table" then CompraForeverDB.config = {} end
  for k, v in pairs(PADROES) do
    if CompraForeverDB.config[k] == nil then CompraForeverDB.config[k] = v end
  end
  if type(CompraForeverDB.ultimoFull) ~= "number" then CompraForeverDB.ultimoFull = 0 end
  if type(CompraForeverCharDB) ~= "table" then CompraForeverCharDB = {} end
end

ns.ao("ADDON_LOADED", function(nome)
  if nome == addon then iniciarSV() end
end)

-- Dinheiro, bolsas, estoque --------------------------------------------------------------------------

function ns.dinheiro()
  return max(0, GetMoney() - (ns.config().reserva or 0))
end

function ns.espacosLivres()
  local n = 0
  for b = 0, 4 do n = n + (C_Container.GetContainerNumFreeSlots(b) or 0) end
  return n
end

function ns.estoque(id)
  return C_Item.GetItemCount(id) or 0
end

-- Receitas conhecidas --------------------------------------------------------------------------------

local function ehLW(info)
  return type(info) == "table" and (info.professionName == PROF or info.parentProfessionName == PROF)
end

-- copia da leitura do GuiaForever (Crafts.lua): so a janela do proprio personagem e so Leatherworking
local function gravarConhecidas()
  local T = C_TradeSkillUI
  if type(T) ~= "table" or not T.GetAllRecipeIDs or not T.GetRecipeInfo then return end
  if T.IsTradeSkillReady and not T.IsTradeSkillReady() then return end
  if (T.IsTradeSkillLinked and T.IsTradeSkillLinked()) or (T.IsTradeSkillGuild and T.IsTradeSkillGuild())
    or (T.IsNPCCrafting and T.IsNPCCrafting()) then return end
  local base = T.GetBaseProfessionInfo and T.GetBaseProfessionInfo()
  local filho = T.GetChildProfessionInfo and T.GetChildProfessionInfo()
  if not (ehLW(base) or ehLW(filho)) then return end
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
  if type(CompraForeverCharDB) ~= "table" then return end
  CompraForeverCharDB.conhecidas = {
    quem = UnitName("player"), em = time(), pericia = tonumber(info.skillLevel), ids = ids, n = n,
  }
  ns.replanejar()
end

local agendado = false
local function agendarGravar()
  if agendado then return end
  agendado = true
  C_Timer.After(0.5, function()
    agendado = false
    gravarConhecidas()
  end)
end

ns.ao("TRADE_SKILL_SHOW", agendarGravar)
ns.ao("TRADE_SKILL_LIST_UPDATE", agendarGravar)
ns.ao("TRADE_SKILL_DATA_SOURCE_CHANGED", agendarGravar)

-- reserva: a gravacao mais nova do GuiaForever para este personagem
local function conhecidasDoGuia()
  local g = rawget(_G, "GuiaForeverDB")
  local ps = type(g) == "table" and g.personagens
  if type(ps) ~= "table" then return nil end
  local quem, melhor = UnitName("player"), nil
  for _, p in pairs(ps) do
    local k = type(p) == "table" and p.receitasLW
    if type(k) == "table" and type(k.ids) == "table" and k.quem == quem and (k.n or 0) > 0
      and (not melhor or (k.em or 0) > (melhor.em or 0)) then
      melhor = k
    end
  end
  return melhor
end

-- { [magia] = true } (vazio se nada conhecido) e a origem: "proprio" | "guia" | nil
function ns.conhecidas()
  local k = type(CompraForeverCharDB) == "table" and CompraForeverCharDB.conhecidas
  if type(k) == "table" and type(k.ids) == "table" and (k.n or 0) > 0 then return k.ids, "proprio" end
  local r = conhecidasDoGuia()
  if r then return r.ids, "guia" end
  return {}, nil
end

-- Plano ----------------------------------------------------------------------------------------------

function ns.replanejar()
  local sc = ns.scan
  if not sc or not ns.planejar then
    ns.plano = nil
    if type(CompraForeverCharDB) == "table" then CompraForeverCharDB.plano = nil end
    if ns.atualizarPainel then ns.atualizarPainel() end
    return nil
  end
  local dados = rawget(_G, "CompraForeverDados") or {}
  local receitas, fabrica = dados.receitas or {}, dados.fabrica or {}
  local conhecidas = ns.conhecidas()
  local envolvidos = {}
  local function reagentesDe(magia)
    local r = receitas[magia]
    if r then
      for _, rg in ipairs(r.reagentes) do envolvidos[rg[1]] = true end
    end
  end
  for magia in pairs(conhecidas) do reagentesDe(magia) end
  for _, magia in pairs(fabrica) do
    if conhecidas[magia] then reagentesDe(magia) end
  end
  local estoque = {}
  for id in pairs(envolvidos) do
    local q = ns.estoque(id)
    if q > 0 then estoque[id] = q end
  end
  local cfg = ns.config()
  local plano = ns.planejar({
    dinheiro = ns.dinheiro(), espacos = ns.espacosLivres(), conhecidas = conhecidas, dados = dados,
    desconto = cfg.desconto, lucroMin = cfg.lucroMin, margemMin = cfg.margemMin,
    escadas = sc.escadas or {}, estoque = estoque, revenda = sc.tipo == "full" and sc.revenda or nil,
  })
  plano.em = time()
  ns.plano = plano
  if type(CompraForeverCharDB) == "table" then CompraForeverCharDB.plano = plano end
  if ns.atualizarPainel then ns.atualizarPainel() end
  return plano
end

-- /compra --------------------------------------------------------------------------------------------

local function dizer(texto)
  print("CompraForever: " .. texto)
end

local function comando(msg)
  msg = strtrim(msg or "")
  local sub, arg = string.match(msg, "^(%S+)%s*(.-)$")
  sub = sub and string.lower(sub) or ""
  local cfg = ns.config()
  if sub == "" then
    if ns.alternarPainel then ns.alternarPainel() else dizer("panel not available") end
  elseif sub == "reserva" or sub == "lucro" or sub == "grande" or sub == "pequena" then
    local campo = (sub == "reserva" and "reserva") or (sub == "lucro" and "lucroMin") or sub
    if arg == "" then
      dizer(sub .. " is " .. ns.moeda(cfg[campo]))
      return
    end
    local v = ns.lerValor(arg)
    if not v then dizer("invalid value (use copper, 1g20s, 50s or 30c)") return end
    cfg[campo] = v
    dizer(sub .. " set to " .. ns.moeda(v))
    ns.replanejar()
    if ns.atualizarPainel then ns.atualizarPainel() end
  elseif sub == "desconto" then
    if arg == "" then dizer("desconto is " .. cfg.desconto .. "%") return end
    local v = tonumber(arg)
    if not v or v < 0 or v > 99 then dizer("desconto must be 0-99") return end
    cfg.desconto = floor(v)
    dizer("desconto set to " .. cfg.desconto .. "%")
    ns.replanejar()
  elseif sub == "sonda" then
    if ns.sonda then ns.sonda() else dizer("probe not available") end
  else
    dizer("/compra [reserva <valor> | desconto <0-99> | lucro <valor> | grande <valor> | pequena <valor> | sonda]")
  end
end

SLASH_COMPRAFOREVER1 = "/compra"
SlashCmdList.COMPRAFOREVER = comando
