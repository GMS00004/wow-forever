-- CentralForever/Nucleo.lua: base do addon. Eventos, log, banco salvo, disjuntor e
-- enumeradores. Nao chama nenhum outro modulo sem checar que ele existe.
-- Contrato: CONTRATO.md, secoes 1, 3.2 e 10. Lua 5.1, so ASCII.
local _, ns = ...

ns.NOME = "CentralForever"
ns.VERSAO = "0.1.0"
ns.cfg = CentralForeverConfig or {}
ns.desligado = {}
ns.pronto = false

-- true se o valor pode ser lido (nao e secreto). Sem issecretvalue, tudo e legivel.
local function legivel(v)
  if issecretvalue then
    local ok, s = pcall(issecretvalue, v)
    if ok and s then return false end
  end
  return true
end

-- ---------------------------------------------------------------------------
-- Execucao protegida e tempo
-- ---------------------------------------------------------------------------

function ns.seguro(fn)
  return function(...)
    return xpcall(fn, geterrorhandler(), ...)
  end
end

function ns.depois(seg, fn)
  if C_Timer and C_Timer.After then
    C_Timer.After(seg, ns.seguro(fn))
  end
end

function ns.tique(seg, fn)
  if C_Timer and C_Timer.NewTicker then
    return C_Timer.NewTicker(seg, ns.seguro(fn))
  end
  return nil
end

function ns.emCombate()
  if InCombatLockdown and InCombatLockdown() then return true end
  return false
end

function ns.msg(texto)
  print("|cff66ccffCentralForever|r: " .. texto)
end

-- ---------------------------------------------------------------------------
-- Eventos: um unico quadro escondido, varios handlers por evento
-- ---------------------------------------------------------------------------

local quadro = CreateFrame("Frame")
quadro:Hide()
local handlers = {}

quadro:SetScript("OnEvent", function(_, evento, ...)
  local lista = handlers[evento]
  if not lista then return end
  local n = #lista
  for i = 1, n do
    xpcall(lista[i], geterrorhandler(), evento, ...)
  end
end)

function ns.ao(evento, fn)
  if type(evento) ~= "string" or type(fn) ~= "function" then return end
  local lista = handlers[evento]
  if not lista then
    lista = {}
    handlers[evento] = lista
    pcall(quadro.RegisterEvent, quadro, evento)
  end
  lista[#lista + 1] = fn
end

-- ---------------------------------------------------------------------------
-- Enumeradores, com reserva numerica
-- ---------------------------------------------------------------------------

local function pegar(tabela, nome, padrao)
  if type(tabela) == "table" then
    local v = tabela[nome]
    if type(v) == "number" then return v end
  end
  return padrao
end

do
  local E = Enum or {}
  local sessao = E.DamageMeterSessionType
  local tipo = E.DamageMeterType
  local restricao = E.AddOnRestrictionType
  local estado = E.AddOnRestrictionState
  ns.enum = {
    sessao = {
      Overall = pegar(sessao, "Overall", 0),
      Current = pegar(sessao, "Current", 1),
      Expired = pegar(sessao, "Expired", 2),
    },
    tipo = { DamageDone = pegar(tipo, "DamageDone", 0) },
    restricao = { Combat = pegar(restricao, "Combat", 0) },
    estado = {
      Inactive = pegar(estado, "Inactive", 0),
      Activating = pegar(estado, "Activating", 1),
      Active = pegar(estado, "Active", 2),
    },
  }
end

-- ---------------------------------------------------------------------------
-- Banco salvo
-- ---------------------------------------------------------------------------

function ns.db()
  CentralForeverDB = CentralForeverDB or {}
  local db = CentralForeverDB
  db.v = db.v or 1
  db.log = db.log or {}
  db.personagens = db.personagens or {}
  db.diario = db.diario or {}
  local d = db.diario
  d.v = d.v or 1
  d.carga = d.carga or {}
  d.lutas = d.lutas or {}
  d.avulsas = d.avulsas or {}
  return db
end

local chaveCache

function ns.chave()
  if chaveCache then return chaveCache end
  local nome, reino
  local ok1, n = pcall(UnitName, "player")
  if ok1 and legivel(n) and type(n) == "string" then nome = n end
  local ok2, r = pcall(GetRealmName)
  if ok2 and legivel(r) and type(r) == "string" then reino = r end
  if nome and reino and nome ~= "" and reino ~= "" then
    chaveCache = tostring(nome) .. "-" .. tostring(reino)
    return chaveCache
  end
  return "?"
end

function ns.dbPersonagem()
  local db = ns.db()
  local k = ns.chave()
  local p = db.personagens[k]
  if not p then
    p = {}
    db.personagens[k] = p
  end
  return p
end

function ns.log(texto)
  if not ns.pronto then return end
  local db = ns.db()
  local max = (ns.cfg.log or {}).max or 80
  local log = db.log
  log[#log + 1] = date("%Y-%m-%d %H:%M:%S") .. " " .. tostring(texto)
  while #log > max do table.remove(log, 1) end
end

-- ---------------------------------------------------------------------------
-- Disjuntor: conta erros por recurso e desliga ao chegar ao limite
-- ---------------------------------------------------------------------------

local erros = {}

function ns.falhou(recurso, erro)
  recurso = tostring(recurso or "?")
  if ns.desligado[recurso] then return true end
  erros[recurso] = (erros[recurso] or 0) + 1
  local limite = (ns.cfg.disjuntor or {}).erros or 3
  if erros[recurso] < limite then return false end
  ns.desligado[recurso] = true
  local texto = "?"
  if legivel(erro) and type(erro) == "string" then texto = erro end
  if #texto > 120 then texto = string.sub(texto, 1, 120) end
  ns.log("recurso desligado: " .. recurso .. " (" .. texto .. ")")
  if ns.diario and ns.diario.anota then
    ns.diario.anota("desligado", { recurso = recurso, erros = erros[recurso], erro = texto })
  end
  return true
end

-- ---------------------------------------------------------------------------
-- Carga do addon
-- ---------------------------------------------------------------------------

ns.ao("ADDON_LOADED", function(_, nome)
  if nome ~= ns.NOME then return end
  ns.cfg = CentralForeverConfig or ns.cfg
  ns.db()
  ns.pronto = true
end)
