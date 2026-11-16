-- Ambiente simulado do WoW Forever para a bancada da central (fengari, Lua 5.3).
-- Contrato: CentralForever\CONTRATO.md, secoes 4 e 11.4. So ASCII. Sintaxe compativel com o parser 5.1.
-- Carregado por chunk "=api-central", depois de bancada\segredo.lua. Recebe do executor:
--   __WIDGET_TEXTO (texto de api-forever\WidgetAPI.lua), __OPCOES ({ id, chaves, generico, matriz }) e
--   __ARQUIVOS (lista { nome, texto } dos .lua do .toc, ja reescritos pelo instrumentar).
-- Os cenarios (cenarios-central.lua) usam o que esta em __bancada.

local S = __seg
local unpack = table.unpack or unpack
local ofloor = math.floor
local oformat = string.format
local oselect = select
local ostring = tostring
local otype = type

local B = {}
__bancada = B
B.opcoes = rawget(_G, "__OPCOES") or {}
B.falhas = {}
B.vistas = {}
B.erros = {}
B.bancadaErros = {}
B.falhouChamadas = {}
B.chat = {}
B.fotos = {}
B.naoSimuladas = {}
B.ausentes = {}
B.contagem = {}
B.eventos = {}
B.avisos = {}
B.cargaFalhas = {}
B.lutas = {}
B.consultasMobAmigo = 0
B.consultasTokenProibido = 0
B.resetsEmCombate = 0
B.painelCriado = false

B.chavesPadrao = { U1 = "erro", U2 = "campos", U3 = "secreta", U4 = "legivel", U5 = "secreta", U6 = "nada", U7 = "dono", U8 = 0.6, U9 = "coleta", U10 = "existe" }
B.chaves = {}
for k, v in pairs(B.chavesPadrao) do B.chaves[k] = v end

-- ---------------------------------------------------------------------------
-- Utilidades
-- ---------------------------------------------------------------------------

-- valor real e se era secreto
local function R(v)
  if S.eh(v) then return S.real(v), true end
  return v, false
end

local function primeiraLinha(s)
  s = ostring(s)
  local i = string.find(s, "\n", 1, true)
  if i then s = string.sub(s, 1, i - 1) end
  return s
end

-- primeira linha de codigo que nao e da bancada
local function ondeAddon()
  local n = 2
  while true do
    local info = debug.getinfo(n, "Sl")
    if not info then return "?" end
    local src = info.short_src
    if info.what ~= "C" and src ~= "segredo" and src ~= "api-central" and src ~= "cenarios-central" then
      return src .. ":" .. info.currentline
    end
    n = n + 1
  end
end
B.ondeAddon = ondeAddon

local function falha(inv, msg)
  local chave = inv .. "|" .. msg
  if B.vistas[chave] then return end
  B.vistas[chave] = true
  B.falhas[#B.falhas + 1] = { inv = inv, msg = msg }
end
B.falha = falha

local function bancadaErro(msg)
  local m = "bancada: " .. msg .. " (" .. ondeAddon() .. ")"
  B.bancadaErros[#B.bancadaErros + 1] = m
  error(m, 0)
end
B.bancadaErro = bancadaErro

local function contar(nome)
  B.contagem[nome] = (B.contagem[nome] or 0) + 1
end

-- os argumentos de uma funcao que recusa segredo: chama __seg.recusa e corrige o local no texto
local function recusar(nome, ...)
  if oselect("#", ...) == 0 then return end
  if not S.algum(...) then return end
  pcall(S.recusa, nome, ...)
  local m = "bancada: " .. nome .. " recusou segredo (" .. ondeAddon() .. ")"
  S.violacoes[#S.violacoes] = m
  error(m, 0)
end

local function copiar(t)
  local c = {}
  for k, v in pairs(t) do c[k] = v end
  return c
end

local function permitida(nome)
  if otype(nome) ~= "string" then return false end
  if string.sub(nome, 1, 14) == "CentralForever" then return true end
  if string.sub(nome, 1, 20) == "SLASH_CENTRALFOREVER" then return true end
  if string.sub(nome, 1, 14) == "CENTRALFOREVER" then return true end
  return false
end

-- ---------------------------------------------------------------------------
-- Ajustes de Lua 5.1 no 5.3
-- ---------------------------------------------------------------------------

_G.unpack = table.unpack
table.getn = function(t) return #t end
tinsert, tremove, sort = table.insert, table.remove, table.sort
strlen, strsub, strlower, strupper, strfind, strmatch, strrep, strbyte, strchar = string.len, string.sub, string.lower, string.upper, string.find, string.match, string.rep, string.byte, string.char
gsub, gmatch = string.gsub, string.gmatch
floor, ceil, abs, max, min, sqrt, random = math.floor, math.ceil, math.abs, math.max, math.min, math.sqrt, math.random

function strtrim(s, chars)
  chars = chars or " \t\r\n"
  local c = "[" .. string.gsub(chars, "[%^%]%-%%]", "%%%0") .. "]"
  local r = string.gsub(ostring(s), "^" .. c .. "+", "")
  r = string.gsub(r, c .. "+$", "")
  return r
end

function strsplit(delim, s, n)
  if s == nil then return end
  local set = "[" .. string.gsub(delim, "[%^%]%-%%]", "%%%0") .. "]"
  local out, pos = {}, 1
  while true do
    if n and #out >= n - 1 then break end
    local a = string.find(s, set, pos)
    if not a then break end
    out[#out + 1] = string.sub(s, pos, a - 1)
    pos = a + 1
  end
  out[#out + 1] = string.sub(s, pos)
  return unpack(out)
end

function strjoin(delim, ...) return table.concat({ ... }, delim) end

function wipe(t)
  for k in pairs(t) do t[k] = nil end
  return t
end

function print(...)
  local t = {}
  for i = 1, oselect("#", ...) do t[#t + 1] = tostring((oselect(i, ...))) end
  B.chat[#B.chat + 1] = table.concat(t, " ")
end

-- data simulada: 2026-11-16 21:00:00 mais o relogio
local BASE_EPOCH = 1794862800

local function civil(dias)
  local z = dias + 719468
  local era = ofloor(z / 146097)
  local doe = z - era * 146097
  local yoe = ofloor((doe - ofloor(doe / 1460) + ofloor(doe / 36524) - ofloor(doe / 146096)) / 365)
  local y = yoe + era * 400
  local doy = doe - (365 * yoe + ofloor(yoe / 4) - ofloor(yoe / 100))
  local mp = ofloor((5 * doy + 2) / 153)
  local d = doy - ofloor((153 * mp + 2) / 5) + 1
  local m = mp + 3
  if m > 12 then m = m - 12 end
  if m <= 2 then y = y + 1 end
  return y, m, d
end

function date(f, t)
  f = f or "%c"
  if string.sub(f, 1, 1) == "!" then f = string.sub(f, 2) end
  t = ofloor(t or time())
  local dias = ofloor(t / 86400)
  local resto = t - dias * 86400
  local y, m, d = civil(dias)
  local H, M, Sg = ofloor(resto / 3600), ofloor((resto % 3600) / 60), resto % 60
  if f == "*t" then return { year = y, month = m, day = d, hour = H, min = M, sec = Sg } end
  local mapa = { Y = oformat("%04d", y), y = oformat("%02d", y % 100), m = oformat("%02d", m), d = oformat("%02d", d), H = oformat("%02d", H), M = oformat("%02d", M), S = oformat("%02d", Sg) }
  mapa.c = mapa.Y .. "-" .. mapa.m .. "-" .. mapa.d .. " " .. mapa.H .. ":" .. mapa.M .. ":" .. mapa.S
  local r = string.gsub(f, "%%(%a)", function(c) return mapa[c] or ("%" .. c) end)
  return r
end

-- ---------------------------------------------------------------------------
-- Relogio simulado e timers
-- ---------------------------------------------------------------------------

local T = 0            -- microssegundos desde o inicio do cenario
local PASSO = 50000    -- 0,05 s
local timers = {}
local seqTimer = 0

function GetTime() return 1000 + T / 1000000 end
function time(t)
  if t then return BASE_EPOCH end
  return BASE_EPOCH + ofloor(T / 1000000)
end
function B.agora() return T end
function B.agoraSeg() return T / 1000000 end

local function manipulador(e)
  local texto
  if S.eh(e) then texto = "<erro secreto>"
  elseif otype(e) == "string" then texto = primeiraLinha(e)
  else texto = "erro nao textual (" .. otype(e) .. ")" end
  B.erros[#B.erros + 1] = texto
  return e
end

function geterrorhandler() return manipulador end
function seterrorhandler() end

local function chamar(fn, ...)
  return xpcall(fn, manipulador, ...)
end
B.chamar = chamar

local function novoTimer(seg, fn, repete, iter, interno)
  if otype(fn) ~= "function" then bancadaErro("C_Timer: o callback nao e uma funcao") end
  seqTimer = seqTimer + 1
  local us = ofloor((tonumber(seg) or 0) * 1000000 + 0.5)
  if us < 1000 then us = 1000 end
  local reg = { due = T + us, seq = seqTimer, fn = fn, intervalo = repete and us or nil, restam = iter, cancelado = false, interno = interno }
  local obj = {}
  obj.Cancel = function() reg.cancelado = true end
  obj.IsCancelled = function() return reg.cancelado end
  reg.obj = obj
  timers[#timers + 1] = reg
  return obj, reg
end

C_Timer = {
  After = function(seg, fn) novoTimer(seg, fn, false) end,
  NewTimer = function(seg, fn) return (novoTimer(seg, fn, false)) end,
  NewTicker = function(seg, fn, iter) return (novoTimer(seg, fn, true, iter)) end,
}

-- agenda uma acao da bancada (nao conta como timer do addon)
function B.agendar(seg, fn)
  local _, reg = novoTimer(seg, fn, false, nil, true)
  return reg
end

function B.tickersAtivos()
  local n = 0
  for i = 1, #timers do
    local r = timers[i]
    if r.intervalo and not r.cancelado and not r.interno then n = n + 1 end
  end
  return n
end

function B.timersAtivos()
  local n = 0
  for i = 1, #timers do
    local r = timers[i]
    if not r.cancelado and not r.interno then n = n + 1 end
  end
  return n
end

local function rodarTimers()
  local guarda = 0
  while true do
    guarda = guarda + 1
    if guarda > 20000 then bancadaErro("laco de timers (mais de 20000 disparos num passo)") end
    local melhor
    for i = 1, #timers do
      local r = timers[i]
      if not r.cancelado and r.due <= T then
        if not melhor or r.due < melhor.due or (r.due == melhor.due and r.seq < melhor.seq) then melhor = r end
      end
    end
    if not melhor then break end
    if melhor.intervalo then
      melhor.due = melhor.due + melhor.intervalo
      seqTimer = seqTimer + 1
      melhor.seq = seqTimer
      if melhor.restam then
        melhor.restam = melhor.restam - 1
        if melhor.restam <= 0 then melhor.cancelado = true end
      end
    else
      melhor.cancelado = true
    end
    chamar(melhor.fn, melhor.obj)
  end
  local novos = {}
  for i = 1, #timers do
    if not timers[i].cancelado then novos[#novos + 1] = timers[i] end
  end
  timers = novos
end

-- ---------------------------------------------------------------------------
-- Estado do jogo simulado
-- ---------------------------------------------------------------------------

local CLASSES = {
  HUNTER = { "Hunter", 3 }, PALADIN = { "Paladin", 2 }, WARRIOR = { "Warrior", 1 }, PRIEST = { "Priest", 5 },
  WARLOCK = { "Warlock", 9 }, MAGE = { "Mage", 8 }, ROGUE = { "Rogue", 4 }, DRUID = { "Druid", 11 },
}

local NOMES_PADRAO = {
  party1 = "Kellan", party2 = "Mirela", party3 = "Tobias", party4 = "Zeca",
  partypet1 = "Voidwalker", partypet2 = "Lobo", partypet3 = "Gato", partypet4 = "Urso",
}

local J
local function jogoInicial()
  return {
    emCombate = false,
    nome = "Rastro",
    reino = "Reino",
    classe = "HUNTER",
    morto = false,
    pet = nil,
    grupo = {},
    alvo = nil,
    restricoes = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
    ameaca = {},
    cvars = { damageMeterEnabled = "1", damageMeterResetOnNewInstance = "1" },
    gravacoesCVar = {},
    zona = "Darkshore",
    instancia = false,
    medidorDisponivel = true,
    medidorMotivo = nil,
    resets = 0,
  }
end
J = jogoInicial()
B.J = J
B.NOMES_PADRAO = NOMES_PADRAO

local function emGrupo()
  for _ in pairs(J.grupo) do return true end
  return false
end

local function restrito()
  return J.restricoes[0] ~= 0 and B.chaves.U10 == "existe"
end
B.restrito = restrito

local function info(tok)
  if otype(tok) ~= "string" then return nil end
  if tok == "player" then
    return { nome = J.nome, amigo = true, morto = J.morto, hostil = false, classe = J.classe }
  elseif tok == "pet" then
    if J.pet and J.pet.existe then return { nome = J.pet.nome, amigo = true, morto = false, hostil = false } end
    return nil
  elseif tok == "target" then
    return J.alvo
  elseif J.grupo[tok] then
    return J.grupo[tok]
  end
  if tok == "targettarget" or string.sub(tok, 1, 9) == "nameplate" then
    B.consultasTokenProibido = B.consultasTokenProibido + 1
    B.avisos[#B.avisos + 1] = "token proibido " .. tok .. " (" .. ondeAddon() .. ")"
  end
  return nil
end

STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"

function InCombatLockdown() return J.emCombate end
function UnitAffectingCombat(tok)
  recusar("UnitAffectingCombat", tok)
  if tok == "player" then return J.emCombate end
  local u = info(tok)
  return (u ~= nil) and J.emCombate and (u.hostil == true)
end
function UnitExists(tok)
  recusar("UnitExists", tok)
  return info(tok) ~= nil
end
function UnitCanAttack(a, b)
  recusar("UnitCanAttack", a, b)
  local u = info(b)
  return (u ~= nil) and (u.hostil == true)
end
function UnitIsDeadOrGhost(tok)
  recusar("UnitIsDeadOrGhost", tok)
  local u = info(tok)
  return (u ~= nil) and (u.morto == true)
end
function UnitName(tok)
  recusar("UnitName", tok)
  local u = info(tok)
  if not u then return nil end
  return u.nome, nil
end
function UnitClass(tok)
  recusar("UnitClass", tok)
  local u = info(tok)
  if not u then return nil end
  local c = u.classe or "WARRIOR"
  local d = CLASSES[c] or CLASSES.WARRIOR
  return d[1], c, d[2]
end
function UnitClassification(tok)
  local u = info(tok)
  if not u then return nil end
  if u.chefe then return "worldboss" end
  return u.classificacao or "normal"
end
function UnitIsBossMob(tok)
  local u = info(tok)
  return (u ~= nil) and (u.chefe == true)
end
function IsInGroup() return emGrupo() end
function IsInInstance() return J.instancia, J.instancia and "party" or "none" end
function GetZoneText() return J.zona end
function GetRealmName() return J.reino end
function GetBuildInfo() return "1.60.1", "70938", "Nov 10 2026", 16001 end

Enum = {
  DamageMeterSessionType = { Overall = 0, Current = 1, Expired = 2 },
  DamageMeterType = { DamageDone = 0, Dps = 1, HealingDone = 2, Hps = 3, Absorbs = 4, Interrupts = 5, Dispels = 6, DamageTaken = 7, AvoidableDamageTaken = 8, Deaths = 9, EnemyDamageTaken = 10 },
  AddOnRestrictionType = { Combat = 0, Encounter = 1, ChallengeMode = 2, PvPMatch = 3, Map = 4, Chat = 5 },
  AddOnRestrictionState = { Inactive = 0, Activating = 1, Active = 2 },
}

C_RestrictedActions = {
  IsAddOnRestrictionActive = function(tipo)
    recusar("IsAddOnRestrictionActive", tipo)
    if B.emDespachoRestricao then return false end
    return J.restricoes[tipo] == 2
  end,
  GetAddOnRestrictionState = function(tipo)
    recusar("GetAddOnRestrictionState", tipo)
    return J.restricoes[tipo] or 0
  end,
}

-- CVars: so damageMeterEnabled e so fora de combate (A6)
local function getCVar(nome)
  recusar("GetCVar", nome)
  return J.cvars[nome]
end
local function setCVar(nome, valor)
  recusar("SetCVar", nome, valor)
  contar("SetCVar")
  local onde = ondeAddon()
  if nome ~= "damageMeterEnabled" then
    falha("A6", "A6: SetCVar(" .. ostring(nome) .. ") fora do permitido (" .. onde .. ")")
  end
  if J.emCombate then
    falha("A6", "A6: SetCVar em combate (" .. onde .. ")")
    return false
  end
  J.cvars[nome] = ostring(valor)
  J.gravacoesCVar[#J.gravacoesCVar + 1] = { nome = nome, valor = ostring(valor), t = T / 1000000, onde = onde }
  return true
end
C_CVar = { GetCVar = getCVar, SetCVar = setCVar }
GetCVar = getCVar
SetCVar = setCVar

-- funcoes protegidas: o addon nao faz nada pelo jogador (A6)
do
  local lista = { "CastSpellByName", "CastSpellByID", "TargetUnit", "ClearTarget", "AssistUnit", "FocusUnit", "RunMacro", "RunMacroText", "UseAction", "UseItemByName", "StartAttack", "PetAttack" }
  for _, nome in ipairs(lista) do
    _G[nome] = function()
      falha("A6", "A6: funcao protegida " .. nome .. " (" .. ondeAddon() .. ")")
    end
  end
end

-- ---------------------------------------------------------------------------
-- Threat
-- ---------------------------------------------------------------------------

local function soloSemPet()
  return (not emGrupo()) and not (J.pet and J.pet.existe)
end

local function entradaAmeaca(unit, mob)
  if not info(unit) then return nil end
  if mob ~= nil then
    if mob ~= "target" then
      B.consultasTokenProibido = B.consultasTokenProibido + 1
      B.avisos[#B.avisos + 1] = "threat com mob " .. ostring(mob) .. " (" .. ondeAddon() .. ")"
      return nil
    end
    local a = J.alvo
    if not a then return nil end
    if not a.hostil then
      B.consultasMobAmigo = B.consultasMobAmigo + 1
      return nil
    end
  end
  if soloSemPet() and unit == "player" and not (B.luta and B.luta.contexto and J.emCombate) then
    if B.chaves.U6 == "nada" then return nil end
    return J.ameaca.player or { estado = 3, pct = 100, tanque = true }
  end
  return J.ameaca[unit]
end

local function estadoSecreto() return restrito() and B.chaves.U4 == "secreto" end
local function pctSecreta()
  if not restrito() then return false end
  if J.alvo and J.alvo.chefe then return true end
  return B.chaves.U5 == "secreta"
end

local function segN(v)
  if v == nil then return nil end
  return S.numero(v)
end

function UnitThreatSituation(unit, mob)
  recusar("UnitThreatSituation", unit, mob)
  contar("UnitThreatSituation")
  local ent = entradaAmeaca(unit, mob)
  if not ent then return nil end
  local v
  if mob == nil then v = ent.geral
  else v = ent.estado end
  if v == nil and mob == nil then v = ent.estado end
  if v == nil then return nil end
  if estadoSecreto() then return S.numero(v) end
  return v
end

function UnitDetailedThreatSituation(unit, mob)
  recusar("UnitDetailedThreatSituation", unit, mob)
  contar("UnitDetailedThreatSituation")
  local ent = entradaAmeaca(unit, mob)
  if not ent then return end
  local tanque = ent.tanque
  if tanque == nil then tanque = false end
  local estado, pct = ent.estado, ent.pct
  local bruto = pct and pct * 100 or nil
  if restrito() then
    if J.alvo and J.alvo.chefe then
      return S.bool(tanque), segN(estado), segN(pct), segN(pct), segN(bruto)
    end
    local r1, r2, r3, r4, r5 = tanque, estado, pct, pct, bruto
    if B.chaves.U4 == "secreto" then r1 = S.bool(tanque); r2 = segN(estado) end
    if B.chaves.U5 == "secreta" then r3 = segN(pct); r4 = segN(pct); r5 = segN(bruto) end
    return r1, r2, r3, r4, r5
  end
  return tanque, estado, pct, pct, bruto
end

function UnitThreatLeadSituation(unit, mob)
  recusar("UnitThreatLeadSituation", unit, mob)
  contar("UnitThreatLeadSituation")
  local ent = entradaAmeaca(unit, mob)
  if not ent then return nil end
  local v = ent.lider
  if v == nil then
    if ent.tanque then v = 1 else v = 3 end
  end
  if estadoSecreto() then return S.numero(v) end
  return v
end

function UnitThreatPercentageOfLead(unit, mob)
  recusar("UnitThreatPercentageOfLead", unit, mob)
  contar("UnitThreatPercentageOfLead")
  local ent = entradaAmeaca(unit, mob)
  if not ent or ent.pct == nil then return nil end
  if pctSecreta() then return S.numero(ent.pct) end
  return ent.pct
end

-- ---------------------------------------------------------------------------
-- C_DamageMeter
-- ---------------------------------------------------------------------------

local med = {
  atual = nil,        -- sessao em curso ou a ultima luta
  expirada = nil,     -- a luta anterior
  overall = { jog = 0, pet = 0 },
  overallDur = 0,     -- segundos das lutas ja fechadas
  proximoId = 0,
  currentVazia = false,
}
B.med = med

local function duracaoDe(s)
  local fim = s.fim or T
  return (fim - s.ini) / 1000000
end

-- { jog, pet, dur, vazia } da sessao de um tipo, ou nil
local function sessaoDe(tipo)
  if tipo == 1 then
    if med.currentVazia then return { jog = 0, pet = 0, dur = 0, vazia = true, id = 0 } end
    if med.atual then return { jog = med.atual.jog, pet = med.atual.pet, dur = duracaoDe(med.atual), id = med.atual.id } end
    return nil
  elseif tipo == 0 then
    local dur = med.overallDur
    if med.atual and not med.atual.fim then dur = dur + duracaoDe(med.atual) end
    return { jog = med.overall.jog, pet = med.overall.pet, dur = dur, id = 0 }
  elseif tipo == 2 then
    local s = med.currentVazia and med.atual or med.expirada
    if s then return { jog = s.jog, pet = s.pet, dur = duracaoDe(s), id = s.id } end
    return nil
  end
  return nil
end

local function montarSessao(s)
  local r = restrito()
  local function nu(v)
    if r then return S.numero(v) end
    return v
  end
  local fontes = {}
  local dur = s.dur
  if dur < 1 then dur = 1 end
  local U7 = B.chaves.U7
  local totalJ = s.jog
  if U7 == "dono" then totalJ = totalJ + s.pet end
  if not s.vazia and totalJ > 0 then
    fontes[#fontes + 1] = {
      sourceGUID = "Player-1-00000001", name = J.nome, classFilename = J.classe, specIconID = 0,
      isLocalPlayer = true, totalAmount = nu(totalJ), amountPerSecond = nu(totalJ / dur),
    }
  end
  if not s.vazia and U7 == "propria" and s.pet > 0 then
    fontes[#fontes + 1] = {
      sourceGUID = "Pet-1-00000002", name = (J.pet and J.pet.nome) or "Fera", classFilename = "WARRIOR", specIconID = 0,
      isLocalPlayer = false, totalAmount = nu(s.pet), amountPerSecond = nu(s.pet / dur),
    }
  end
  local total = s.jog + s.pet
  local lista = fontes
  if r and B.chaves.U2 == "inacessivel" then lista = S.tabela(fontes) end
  return { combatSources = lista, maxAmount = nu(totalJ), totalAmount = nu(total), durationSeconds = nu(s.dur) }
end

local function tipoSessaoValido(t)
  if t ~= 0 and t ~= 1 and t ~= 2 then bancadaErro("sessionType invalido " .. ostring(t)) end
end

C_DamageMeter = {
  GetCombatSessionFromType = function(tipoSessao, tipo)
    recusar("GetCombatSessionFromType", tipoSessao, tipo)
    contar("GetCombatSessionFromType")
    tipoSessaoValido(tipoSessao)
    if not J.medidorDisponivel then return nil end
    local s = sessaoDe(tipoSessao)
    if not s then return nil end
    return montarSessao(s)
  end,
  GetCombatSessionFromID = function(id, tipo)
    recusar("GetCombatSessionFromID", id, tipo)
    contar("GetCombatSessionFromID")
    if med.atual and id == med.atual.id then return montarSessao(sessaoDe(1)) end
    if med.expirada and id == med.expirada.id then return montarSessao(sessaoDe(2)) end
    return nil
  end,
  GetSessionDurationSeconds = function(tipoSessao)
    recusar("GetSessionDurationSeconds", tipoSessao)
    contar("GetSessionDurationSeconds")
    tipoSessaoValido(tipoSessao)
    local s = sessaoDe(tipoSessao)
    if not s then return nil end
    if restrito() and B.chaves.U3 == "secreta" then return S.numero(s.dur) end
    return s.dur
  end,
  IsDamageMeterAvailable = function()
    contar("IsDamageMeterAvailable")
    if J.medidorDisponivel then return true, nil end
    return false, J.medidorMotivo or "indisponivel"
  end,
  ResetAllCombatSessions = function()
    contar("ResetAllCombatSessions")
    if J.emCombate then
      B.resetsEmCombate = B.resetsEmCombate + 1
      falha("AF", "afirma: ResetAllCombatSessions chamada em combate (" .. ondeAddon() .. ")")
    end
    J.resets = J.resets + 1
    med.atual = nil
    med.expirada = nil
    med.currentVazia = false
    med.overall = { jog = 0, pet = 0 }
    med.overallDur = 0
    B.disparar("DAMAGE_METER_RESET")
  end,
}

-- ---------------------------------------------------------------------------
-- Widgets estritos
-- ---------------------------------------------------------------------------

local API = (function()
  local texto = rawget(_G, "__WIDGET_TEXTO")
  if not texto then error("bancada: __WIDGET_TEXTO ausente", 0) end
  local f, err = load(texto, "=WidgetAPI.lua")
  if not f then error("bancada: WidgetAPI.lua nao compila: " .. ostring(err), 0) end
  return f()
end)()

local conjuntos = {}
local function conjunto(classe)
  if conjuntos[classe] then return conjuntos[classe] end
  local set = {}
  conjuntos[classe] = set
  local def = API[classe]
  if def then
    local herda = {}
    for _, h in ipairs(def.inherits or {}) do herda[#herda + 1] = h end
    -- WidgetAPI.lua marca Region como herdeira de si mesma: aqui herda de ScriptRegion
    if classe == "Region" then herda[#herda + 1] = "ScriptRegion" end
    for _, h in ipairs(herda) do
      if h ~= classe then
        for nome in pairs(conjunto(h)) do set[nome] = true end
      end
    end
    for _, nome in ipairs(def.methods or {}) do set[nome] = true end
  end
  return set
end

local E = setmetatable({}, { __mode = "k" })
B.E = E
local frames = {}
local proximoId = 0
local IMPL = {}
local mts = {}

local ACEITA = {
  SetText = true, SetFormattedText = true, SetTextColor = true,
  SetValue = true, SetMinMaxValues = true, SetStatusBarColor = true,
  SetAlpha = true, SetVertexColor = true, SetAlphaFromBoolean = true, SetVertexColorFromBoolean = true,
}
local A4 = { SetPoint = true, SetSize = true, SetWidth = true, SetHeight = true,
  CreateFrame = true, CreateTexture = true, CreateFontString = true, CreateAnimationGroup = true }

local function descreve(e)
  return e.tipo .. (e.nome and ("[" .. e.nome .. "]") or ("#" .. e.id))
end

-- invariantes A4 e A5, por chamada
local function verificar(nome, e)
  if nome == "GetText" or nome == "GetValue" or nome == "GetAlpha" then
    falha("A5", "A5: " .. nome .. " em " .. descreve(e) .. " (" .. ondeAddon() .. ")")
  elseif nome == "GetStringWidth" and J.emCombate then
    falha("A5", "A5: GetStringWidth em combate em " .. descreve(e) .. " (" .. ondeAddon() .. ")")
  end
  if B.painelCriado and J.emCombate and A4[nome] then
    falha("A4", "A4: " .. nome .. " em combate depois de criar o painel, em " .. descreve(e) .. " (" .. ondeAddon() .. ")")
  end
end

local function verificarCriacao(nome)
  if B.painelCriado and J.emCombate then
    falha("A4", "A4: " .. nome .. " em combate depois de criar o painel (" .. ondeAddon() .. ")")
  end
  contar(nome)
end

local function fazerMetodo(nome)
  local impl = IMPL[nome]
  local aceita = ACEITA[nome]
  return function(self, ...)
    local e = E[self]
    if not e then bancadaErro("metodo " .. nome .. " chamado sem o objeto (use ':')") end
    e.n[nome] = (e.n[nome] or 0) + 1
    contar(nome)
    if not aceita then recusar(nome, ...) end
    verificar(nome, e)
    if impl then return impl(self, e, ...) end
    return nil
  end
end

local function ausente(k)
  return setmetatable({}, { __call = function() bancadaErro("metodo inexistente " .. k) end })
end

local function mtDe(classe)
  if mts[classe] then return mts[classe] end
  local set = conjunto(classe)
  local cache = {}
  local mt = {}
  mt.__index = function(_, k)
    local f = cache[k]
    if f then return f end
    if otype(k) ~= "string" then return nil end
    if set[k] then
      f = fazerMetodo(k)
      cache[k] = f
      return f
    end
    if string.find(k, "^[A-Z]") then
      f = ausente(k)
      cache[k] = f
      return f
    end
    return nil
  end
  mts[classe] = mt
  return mt
end

local function novoWidget(classe, nome, pai)
  proximoId = proximoId + 1
  local w = {}
  local e = {
    w = w, tipo = classe, id = proximoId, nome = nome, pai = pai, filhos = {}, regioes = {}, pontos = {},
    alfa = 1, visivel = true, strata = pai and pai.strata or "MEDIUM", nivel = pai and (pai.nivel + 1) or 0,
    n = {}, escritas = {}, scripts = {}, eventos = {}, eventosUnit = {}, animacoes = {},
    recebeuSegredo = false, plays = 0, criadoT = T / 1000000,
  }
  E[w] = e
  setmetatable(w, mtDe(classe))
  return w, e
end

local function eFrame(w, quem)
  local e = E[w]
  if not e then bancadaErro(quem .. ": o objeto nao e um widget") end
  return e
end

local function nomeGlobal(nome, w)
  if nome == nil then return end
  if otype(nome) ~= "string" then bancadaErro("nome de widget nao textual") end
  if rawget(_G, nome) == nil and not permitida(nome) then
    falha("A7", "A7: global nova " .. nome .. " (quadro com nome, " .. ondeAddon() .. ")")
  end
  rawset(_G, nome, w)
end

local function ehQuadro(classe)
  return conjunto(classe).CreateFontString == true
end

function CreateFrame(tipo, nome, pai, template)
  recusar("CreateFrame", tipo, nome)
  if otype(tipo) ~= "string" or not API[tipo] or not ehQuadro(tipo) then
    bancadaErro("CreateFrame: tipo inexistente " .. ostring(tipo))
  end
  verificarCriacao("CreateFrame")
  local pe
  if pai ~= nil then pe = eFrame(pai, "CreateFrame") end
  local w, e = novoWidget(tipo, nome, pe)
  if pe then pe.filhos[#pe.filhos + 1] = e end
  frames[#frames + 1] = e
  if template ~= nil then B.naoSimuladas["template:" .. ostring(template)] = true end
  nomeGlobal(nome, w)
  return w
end

local function criarRegiao(classe, nome, pai, camada)
  local w, e = novoWidget(classe, nome, pai)
  e.camada = camada
  pai.regioes[#pai.regioes + 1] = e
  nomeGlobal(nome, w)
  return w, e
end

IMPL.CreateFontString = function(_, e, nome, camada, template)
  local w, fe = criarRegiao("FontString", nome, e, camada)
  fe.texto = ""
  if template ~= nil then fe.fonte = { template = ostring(template) } end
  return w
end

IMPL.CreateTexture = function(_, e, nome, camada)
  local w = criarRegiao("Texture", nome, e, camada)
  return w
end

IMPL.CreateAnimationGroup = function(_, e, nome)
  local w, ge = novoWidget("AnimationGroup", nome, e)
  e.animacoes[#e.animacoes + 1] = ge
  ge.itens = {}
  return w
end

IMPL.CreateAnimation = function(_, e, tipo, nome)
  contar("CreateAnimation")
  if otype(tipo) ~= "string" or not API[tipo] or not conjunto(tipo).SetOrder then bancadaErro("CreateAnimation: tipo inexistente " .. ostring(tipo)) end
  local w, ae = novoWidget(tipo, nome, e)
  ae.duracao = 0
  ae.ordem = 0
  e.itens[#e.itens + 1] = ae
  return w
end

-- ----- identidade, escritas de script -----
IMPL.GetName = function(_, e) return e.nome end
IMPL.GetObjectType = function(_, e) return e.tipo end
IMPL.IsObjectType = function(_, e, t) return e.tipo == t or (t == "Frame" and ehQuadro(e.tipo)) or (t == "Region" and not ehQuadro(e.tipo)) end
IMPL.GetParent = function(_, e) return e.pai and e.pai.w or nil end
IMPL.SetParent = function(_, e, pai)
  if e.pai then
    for i, x in ipairs(e.pai.filhos) do if x == e then table.remove(e.pai.filhos, i) break end end
    for i, x in ipairs(e.pai.regioes) do if x == e then table.remove(e.pai.regioes, i) break end end
  end
  if pai == nil then e.pai = nil return end
  local pe = eFrame(pai, "SetParent")
  e.pai = pe
  if ehQuadro(e.tipo) then pe.filhos[#pe.filhos + 1] = e else pe.regioes[#pe.regioes + 1] = e end
end
IMPL.GetChildren = function(_, e)
  local r = {}
  for i, x in ipairs(e.filhos) do r[i] = x.w end
  return unpack(r)
end
IMPL.GetNumChildren = function(_, e) return #e.filhos end
IMPL.GetRegions = function(_, e)
  local r = {}
  for i, x in ipairs(e.regioes) do r[i] = x.w end
  return unpack(r)
end

IMPL.SetScript = function(_, e, nome, fn)
  if fn ~= nil and otype(fn) ~= "function" then bancadaErro("SetScript: " .. ostring(nome) .. " precisa de funcao ou nil") end
  e.scripts[nome] = fn
end
IMPL.GetScript = function(_, e, nome) return e.scripts[nome] end
IMPL.HasScript = function() return true end
IMPL.HookScript = function() end

-- ----- eventos -----
IMPL.RegisterEvent = function(_, e, ev)
  if otype(ev) ~= "string" then bancadaErro("RegisterEvent: evento nao textual") end
  e.eventos[ev] = true
  return true
end
IMPL.RegisterUnitEvent = function(_, e, ev, ...)
  if otype(ev) ~= "string" then bancadaErro("RegisterUnitEvent: evento nao textual") end
  local un = e.eventosUnit[ev] or {}
  for i = 1, oselect("#", ...) do un[(oselect(i, ...))] = true end
  e.eventosUnit[ev] = un
  return true
end
IMPL.UnregisterEvent = function(_, e, ev) e.eventos[ev] = nil e.eventosUnit[ev] = nil end
IMPL.UnregisterAllEvents = function(_, e) e.eventos = {} e.eventosUnit = {} end
IMPL.IsEventRegistered = function(_, e, ev) return e.eventos[ev] == true or e.eventosUnit[ev] ~= nil end

-- ----- posicao, tamanho, visibilidade -----
local function descRel(rel)
  if rel == nil then return nil end
  if otype(rel) == "string" then return rel end
  local re = E[rel]
  if re then return re.nome or ("#" .. re.id) end
  return "?"
end

IMPL.SetPoint = function(_, e, ponto, a, b, c, d)
  if otype(ponto) ~= "string" then bancadaErro("SetPoint: ponto invalido") end
  local rel, relP, x, y = nil, nil, 0, 0
  if otype(a) == "number" then
    x, y = a, b or 0
  elseif a ~= nil then
    rel = a
    if otype(b) == "number" then
      x, y = b, c or 0
      relP = ponto
    else
      relP = b or ponto
      x = c or 0
      y = d or 0
    end
  end
  local novo = { ponto = ponto, rel = descRel(rel), relPonto = relP, x = x, y = y }
  for i, p in ipairs(e.pontos) do
    if p.ponto == ponto then e.pontos[i] = novo return end
  end
  e.pontos[#e.pontos + 1] = novo
end
IMPL.ClearAllPoints = function(_, e) e.pontos = {} end
IMPL.SetAllPoints = function(_, e, rel)
  e.pontos = { { ponto = "ALL", rel = descRel(rel) or (e.pai and (e.pai.nome or ("#" .. e.pai.id))) } }
end
IMPL.GetNumPoints = function(_, e) return #e.pontos end
IMPL.GetPoint = function(_, e, i)
  local p = e.pontos[i or 1]
  if not p then return nil end
  return p.ponto, nil, p.relPonto, p.x, p.y
end
IMPL.SetSize = function(_, e, l, a) e.largura = l e.altura = a end
IMPL.SetWidth = function(_, e, l) e.largura = l end
IMPL.SetHeight = function(_, e, a) e.altura = a end
IMPL.GetWidth = function(_, e) return e.largura or 0 end
IMPL.GetHeight = function(_, e) return e.altura or 0 end
IMPL.GetSize = function(_, e) return e.largura or 0, e.altura or 0 end
IMPL.SetScale = function(_, e, s) e.escala = s end
IMPL.GetScale = function(_, e) return e.escala or 1 end
IMPL.GetEffectiveScale = function() return 0.7 end
IMPL.EnableMouse = function(_, e, b) e.mouse = b end
IMPL.SetFrameStrata = function(_, e, s)
  local ok = { BACKGROUND = 1, LOW = 1, MEDIUM = 1, HIGH = 1, DIALOG = 1, FULLSCREEN = 1, FULLSCREEN_DIALOG = 1, TOOLTIP = 1 }
  if not ok[s] then bancadaErro("SetFrameStrata: strata invalido " .. ostring(s)) end
  e.strata = s
end
IMPL.GetFrameStrata = function(_, e) return e.strata end
IMPL.SetFrameLevel = function(_, e, n) e.nivel = n end
IMPL.GetFrameLevel = function(_, e) return e.nivel end
IMPL.SetDrawLayer = function(_, e, camada, nivel)
  local ok = { BACKGROUND = 1, BORDER = 1, ARTWORK = 1, OVERLAY = 1, HIGHLIGHT = 1 }
  if not ok[camada] then bancadaErro("SetDrawLayer: camada invalida " .. ostring(camada)) end
  e.camada = camada
  e.subnivel = nivel
end
IMPL.GetDrawLayer = function(_, e) return e.camada, e.subnivel or 0 end

IMPL.Show = function(_, e) e.visivel = true end
IMPL.Hide = function(_, e) e.visivel = false end
IMPL.SetShown = function(_, e, b) e.visivel = b and true or false end
IMPL.IsShown = function(_, e) return e.visivel end

local function visivelEfetivo(e)
  while e do
    if not e.visivel then return false end
    e = e.pai
  end
  return true
end
B.visivelEfetivo = function(w) return visivelEfetivo(E[w]) end
IMPL.IsVisible = function(_, e) return visivelEfetivo(e) end

local function alfaEfetivo(e)
  local a = 1
  while e do
    a = a * (e.alfa or 1)
    e = e.pai
  end
  return a
end
B.alfaEfetivo = function(w) return alfaEfetivo(E[w]) end

-- ----- alfa e cores (ralos que aceitam segredo) -----
local function marca(e, s)
  if s then e.recebeuSegredo = true end
end

IMPL.SetAlpha = function(_, e, a)
  local v, s = R(a)
  if otype(v) ~= "number" then bancadaErro("SetAlpha: alfa nao numerico") end
  e.alfa = v
  marca(e, s)
end
IMPL.SetAlphaFromBoolean = function(_, e, b, aT, aF)
  local v, s = R(b)
  local at, as1 = R(aT)
  local af, as2 = R(aF)
  if at == nil then at = 255 end
  if af == nil then af = 0 end
  local alfa = v and at or af
  if alfa > 1 then alfa = 1 end
  e.alfa = alfa
  e.alfaPorBooleano = true
  marca(e, s or as1 or as2)
end
IMPL.GetAlpha = function(_, e)
  if e.recebeuSegredo then return S.numero(e.alfa) end
  return e.alfa
end
IMPL.GetEffectiveAlpha = function(_, e) return alfaEfetivo(e) end
IMPL.SetVertexColor = function(_, e, r, g, b, a)
  local r1, s1 = R(r)
  local g1, s2 = R(g)
  local b1, s3 = R(b)
  local a1, s4 = R(a)
  e.corVertice = { r1, g1, b1, a1 }
  marca(e, s1 or s2 or s3 or s4)
end
IMPL.SetVertexColorFromBoolean = function(_, e, b)
  local _, s = R(b)
  e.corPorBooleano = true
  marca(e, s)
end
IMPL.GetVertexColor = function(_, e)
  local c = e.corVertice or { 1, 1, 1, 1 }
  return c[1], c[2], c[3], c[4]
end
IMPL.SetColorTexture = function(_, e, r, g, b, a) e.cor = { r, g, b, a or 1 } end
IMPL.SetTexture = function(_, e, t) e.textura = t end
IMPL.GetTexture = function(_, e) return e.textura end
IMPL.SetTextColor = function(_, e, r, g, b, a)
  local r1, s1 = R(r)
  local g1, s2 = R(g)
  local b1, s3 = R(b)
  local a1, s4 = R(a)
  e.cor = { r1, g1, b1, a1 or 1 }
  marca(e, s1 or s2 or s3 or s4)
end
IMPL.GetTextColor = function(_, e)
  local c = e.cor or { 1, 1, 1, 1 }
  return c[1], c[2], c[3], c[4]
end
IMPL.SetStatusBarColor = function(_, e, r, g, b, a)
  local r1, s1 = R(r)
  local g1, s2 = R(g)
  local b1, s3 = R(b)
  local a1, s4 = R(a)
  e.cor = { r1, g1, b1, a1 or 1 }
  marca(e, s1 or s2 or s3 or s4)
end
IMPL.GetStatusBarColor = function(_, e)
  local c = e.cor or { 1, 1, 1, 1 }
  return c[1], c[2], c[3], c[4]
end

-- ----- texto -----
IMPL.SetFont = function(_, e, arq, tam, contorno)
  if otype(arq) ~= "string" then return false end
  if otype(tam) ~= "number" or tam <= 0 then bancadaErro("SetFont: tamanho invalido " .. ostring(tam)) end
  e.fonte = { arquivo = arq, tamanho = tam, contorno = contorno }
  return true
end
IMPL.SetFontObject = function(_, e, f) e.fonte = { objeto = ostring(f) } end
IMPL.GetFont = function(_, e)
  local f = e.fonte or {}
  return f.arquivo, f.tamanho, f.contorno
end
IMPL.SetJustifyH = function(_, e, v)
  if v ~= "LEFT" and v ~= "CENTER" and v ~= "RIGHT" then bancadaErro("SetJustifyH: valor invalido " .. ostring(v)) end
  e.justifyH = v
end
IMPL.SetJustifyV = function(_, e, v)
  if v ~= "TOP" and v ~= "MIDDLE" and v ~= "BOTTOM" then bancadaErro("SetJustifyV: valor invalido " .. ostring(v)) end
  e.justifyV = v
end
IMPL.SetWordWrap = function(_, e, b) e.wordWrap = b end
IMPL.SetShadowColor = function(_, e, r, g, b, a) e.sombra = { r, g, b, a } end
IMPL.SetShadowOffset = function(_, e, x, y) e.sombraOffset = { x, y } end

local function registrarEscrita(e)
  local ts = e.escritas
  ts[#ts + 1] = T
  e.nEscritas = (e.nEscritas or 0) + 1
  local n = #ts
  if n >= 5 then
    local dt = T - ts[n - 4]
    if dt < 1000000 then
      falha("A3", "A3: " .. descreve(e) .. " escrito 5 vezes em " .. oformat("%.2f", dt / 1000000) .. " s (" .. ondeAddon() .. ")")
    end
  end
  if n > 8 then table.remove(ts, 1) end
end

local function gravarTexto(e, v, s)
  if not e.fonte then bancadaErro("FontString sem fonte: chame SetFont antes de SetText") end
  if v == nil then v = "" end
  if otype(v) == "number" then v = oformat("%s", v) end
  e.texto = ostring(v)
  e.textoSecreto = s
  marca(e, s)
  registrarEscrita(e)
end

IMPL.SetText = function(_, e, texto)
  local v, s = R(texto)
  gravarTexto(e, v, s)
end
IMPL.SetFormattedText = function(_, e, fmt, ...)
  local f, s0 = R(fmt)
  local args, s = {}, s0
  local n = oselect("#", ...)
  for i = 1, n do
    local v, si = R((oselect(i, ...)))
    args[i] = v
    s = s or si
  end
  local ok, r = pcall(oformat, f, unpack(args, 1, n))
  gravarTexto(e, ok and r or ostring(f), s)
end
IMPL.ClearText = function(_, e) gravarTexto(e, "", false) end
IMPL.GetText = function(_, e)
  if e.recebeuSegredo then return S.texto(e.texto or "") end
  return e.texto or ""
end
IMPL.GetStringWidth = function(_, e)
  local tam = (e.fonte and e.fonte.tamanho) or 12
  local w = #(e.texto or "") * tam * 0.55
  if e.recebeuSegredo then return S.numero(w) end
  return w
end
IMPL.GetStringHeight = function(_, e)
  local tam = (e.fonte and e.fonte.tamanho) or 12
  if e.recebeuSegredo then return S.numero(tam) end
  return tam
end

-- ----- barra -----
IMPL.SetMinMaxValues = function(_, e, mn, mx)
  local a, s1 = R(mn)
  local b, s2 = R(mx)
  e.min, e.max = a, b
  marca(e, s1 or s2)
end
IMPL.GetMinMaxValues = function(_, e) return e.min or 0, e.max or 1 end
IMPL.SetValue = function(_, e, v)
  local x, s = R(v)
  if otype(x) ~= "number" then bancadaErro("SetValue: valor nao numerico") end
  e.valor = x
  marca(e, s)
end
IMPL.GetValue = function(_, e)
  if e.recebeuSegredo then return S.numero(e.valor or 0) end
  return e.valor or 0
end
IMPL.SetStatusBarTexture = function(_, e, t) e.textura = t end

-- ----- animacao -----
IMPL.SetDuration = function(_, e, d) e.duracao = d end
IMPL.GetDuration = function(_, e) return e.duracao or 0 end
IMPL.SetOrder = function(_, e, o) e.ordem = o end
IMPL.SetFromAlpha = function(_, e, a) e.de = a end
IMPL.SetToAlpha = function(_, e, a) e.para = a end
IMPL.SetToFinalAlpha = function(_, e, b) e.alfaFinal = b end

local function duracaoGrupo(ge)
  local porOrdem = {}
  for _, a in ipairs(ge.itens or {}) do
    local o = a.ordem or 0
    if (porOrdem[o] or 0) < (a.duracao or 0) then porOrdem[o] = a.duracao end
  end
  local soma = 0
  for _, d in pairs(porOrdem) do soma = soma + d end
  return soma
end

IMPL.Play = function(_, e)
  e.plays = e.plays + 1
  e.fimT = T + ofloor(duracaoGrupo(e) * 1000000)
  B.playsTotal = (B.playsTotal or 0) + 1
  if J.emCombate and B.luta then B.luta.pulsos = B.luta.pulsos + 1 end
end
IMPL.Stop = function(_, e) e.fimT = nil end
IMPL.Restart = function(w, e) IMPL.Play(w, e) end
IMPL.IsPlaying = function(_, e) return e.fimT ~= nil and T < e.fimT end

-- ----- botoes (so o que o texto precisa) -----
IMPL.StopAnimating = function() end

-- ---------------------------------------------------------------------------
-- Quadros nativos
-- ---------------------------------------------------------------------------

do
  local w, e = novoWidget("Frame", "UIParent", nil)
  e.largura, e.altura = 3657, 2057
  e.strata = "MEDIUM"
  e.nivel = 0
  frames[#frames + 1] = e
  rawset(_G, "UIParent", w)
  B.UIParentE = e
  local w2, e2 = novoWidget("Frame", "WorldFrame", nil)
  e2.largura, e2.altura = 3657, 2057
  frames[#frames + 1] = e2
  rawset(_G, "WorldFrame", w2)
end

SlashCmdList = setmetatable({}, {
  __newindex = function(t, k, v)
    if not permitida(k) then falha("A7", "A7: global nova SlashCmdList[" .. ostring(k) .. "] (" .. ondeAddon() .. ")") end
    rawset(t, k, v)
  end,
})

-- ---------------------------------------------------------------------------
-- Eventos e OnUpdate
-- ---------------------------------------------------------------------------

function B.disparar(ev, ...)
  B.eventos[ev] = (B.eventos[ev] or 0) + 1
  local lista = {}
  for i = 1, #frames do lista[i] = frames[i] end
  local antes = B.emDespachoRestricao
  if ev == "ADDON_RESTRICTION_STATE_CHANGED" then B.emDespachoRestricao = true end
  for i = 1, #lista do
    local e = lista[i]
    local recebe = e.eventos[ev] == true
    if not recebe then
      local un = e.eventosUnit[ev]
      if un and un[(...)] then recebe = true end
    end
    if recebe then
      local fn = e.scripts.OnEvent
      if fn then chamar(fn, e.w, ev, ...) end
    end
  end
  B.emDespachoRestricao = antes
end

local function rodarOnUpdate()
  local lista = {}
  for i = 1, #frames do lista[i] = frames[i] end
  for i = 1, #lista do
    local e = lista[i]
    local fn = e.scripts.OnUpdate
    if fn and visivelEfetivo(e) then chamar(fn, e.w, PASSO / 1000000) end
  end
end

-- anda o relogio em passos de 0,05 s
function B.avancar(seg)
  local n = ofloor(seg * 1000000 / PASSO + 0.5)
  for _ = 1, n do
    T = T + PASSO
    rodarTimers()
    rodarOnUpdate()
  end
end

-- ---------------------------------------------------------------------------
-- JSON e SavedVariables
-- ---------------------------------------------------------------------------

local function esc(s)
  s = string.gsub(s, "\\", "\\\\")
  s = string.gsub(s, "\"", "\\\"")
  s = string.gsub(s, "\n", "\\n")
  s = string.gsub(s, "\r", "\\r")
  s = string.gsub(s, "\t", "\\t")
  s = string.gsub(s, "[\1-\31]", function(c) return oformat("\\u%04x", string.byte(c)) end)
  return s
end

local function numTexto(v)
  if v ~= v or v == math.huge or v == -math.huge then return "null" end
  if math.type(v) == "integer" then return oformat("%d", v) end
  return oformat("%.14g", v)
end

local function chavesOrdenadas(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks, function(a, b)
    local ta, tb = otype(a), otype(b)
    if ta ~= tb then return ta < tb end
    if ta == "number" or ta == "string" then return a < b end
    return ostring(a) < ostring(b)
  end)
  return ks
end

local function json(v, vistos)
  vistos = vistos or {}
  if S.eh(v) then return "\"<segredo>\"" end
  local t = otype(v)
  if t == "nil" then return "null" end
  if t == "boolean" then return v and "true" or "false" end
  if t == "number" then return numTexto(v) end
  if t == "string" then return "\"" .. esc(v) .. "\"" end
  if t ~= "table" then return "\"<" .. t .. ">\"" end
  if vistos[v] then return "null" end
  vistos[v] = true
  local out = {}
  if next(v) == nil then
    out = "[]"
  elseif v[1] ~= nil then
    for i = 1, #v do out[i] = json(v[i], vistos) end
    out = "[" .. table.concat(out, ",") .. "]"
  else
    for _, k in ipairs(chavesOrdenadas(v)) do
      out[#out + 1] = "\"" .. esc(ostring(k)) .. "\":" .. json(v[k], vistos)
    end
    out = "{" .. table.concat(out, ",") .. "}"
  end
  vistos[v] = nil
  return out
end
B.json = json

local function serie(v, nivel, vistos)
  if S.eh(v) then return "nil" end
  local t = otype(v)
  if t == "nil" then return "nil" end
  if t == "boolean" then return v and "true" or "false" end
  if t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return "0" end
    return numTexto(v)
  end
  if t == "string" then return "\"" .. esc(v) .. "\"" end
  if t ~= "table" then return "nil" end
  if vistos[v] then return "nil" end
  vistos[v] = true
  local pad = string.rep("\t", nivel + 1)
  local linhas = {}
  for _, k in ipairs(chavesOrdenadas(v)) do
    if not S.eh(k) then
      local kt = otype(k)
      local ks
      if kt == "number" then ks = "[" .. numTexto(k) .. "]"
      elseif kt == "string" then ks = "[\"" .. esc(k) .. "\"]" end
      if ks then linhas[#linhas + 1] = pad .. ks .. " = " .. serie(v[k], nivel + 1, vistos) .. "," end
    end
  end
  vistos[v] = nil
  if #linhas == 0 then return "{}" end
  return "{\n" .. table.concat(linhas, "\n") .. "\n" .. string.rep("\t", nivel) .. "}"
end

function B.serializarDB()
  local db = rawget(_G, "CentralForeverDB")
  if db == nil then return "CentralForeverDB = nil\n" end
  return "CentralForeverDB = " .. serie(db, 0, {}) .. "\n"
end

-- ---------------------------------------------------------------------------
-- Arvore de quadros (para as fotos e para a previa)
-- ---------------------------------------------------------------------------

local function noDe(e)
  local no = {
    tipo = e.tipo, id = e.id, nome = e.nome,
    pai = e.pai and (e.pai.nome or ("#" .. e.pai.id)) or nil,
    ponto = e.pontos, largura = e.largura, altura = e.altura,
    strata = e.strata, nivel = e.nivel, camada = e.camada,
    alfa = e.alfa, alfaEfetivo = alfaEfetivo(e),
    visivel = e.visivel, visivelEfetivo = visivelEfetivo(e),
    cor = e.cor, corVertice = e.corVertice, texto = e.texto, fonte = e.fonte,
    justifyH = e.justifyH, valor = e.valor, min = e.min, max = e.max,
    recebeuSegredo = e.recebeuSegredo or nil, escritas = e.nEscritas, textoSecreto = e.textoSecreto or nil,
  }
  if #e.animacoes > 0 then
    local gs = {}
    for i, g in ipairs(e.animacoes) do gs[i] = { plays = g.plays } end
    no.animacoes = gs
  end
  if #e.regioes > 0 then
    local rs = {}
    for i, r in ipairs(e.regioes) do rs[i] = noDe(r) end
    no.regioes = rs
  end
  if #e.filhos > 0 then
    local fs = {}
    for i, f in ipairs(e.filhos) do fs[i] = noDe(f) end
    no.filhos = fs
  end
  return no
end

function B.arvore()
  local raizes = {}
  for i = 1, #frames do
    local e = frames[i]
    if e.pai == nil then raizes[#raizes + 1] = noDe(e) end
  end
  return raizes
end

function B.foto(nome)
  B.fotos[#B.fotos + 1] = { nome = nome, t = T / 1000000, arvore = B.arvore() }
end

-- ---------------------------------------------------------------------------
-- Globais: A7 e lista de nao simuladas
-- ---------------------------------------------------------------------------

function B.instalarGlobais()
  setmetatable(_G, {
    __index = function(_, k)
      if otype(k) == "string" and string.sub(k, 1, 2) ~= "__" and not B.ausentes[k] and not permitida(k) then
        B.naoSimuladas[k] = true
      end
      return nil
    end,
    __newindex = function(t, k, v)
      if not permitida(k) then
        falha("A7", "A7: global nova " .. ostring(k) .. " (" .. ondeAddon() .. ")")
      end
      rawset(t, k, v)
    end,
  })
end

-- ---------------------------------------------------------------------------
-- Carga do addon, jogo inicial e fim de cenario
-- ---------------------------------------------------------------------------

function B.aplicarJogo(jogo)
  jogo = jogo or {}
  J.classe = jogo.classe or "HUNTER"
  if jogo.pet then J.pet = { existe = true, nome = "Fera" } else J.pet = nil end
  J.grupo = {}
  for _, tok in ipairs(jogo.grupo or {}) do
    local nome = (jogo.nomes and jogo.nomes[tok]) or NOMES_PADRAO[tok] or tok
    J.grupo[tok] = { nome = nome, amigo = true, hostil = false, morto = false, classe = (string.find(tok, "pet", 1, true) and "WARLOCK" or "WARRIOR") }
  end
  for k, v in pairs(jogo.cvars or {}) do J.cvars[k] = v end
  if jogo.instancia then J.instancia = true end
  if jogo.emCombate then
    J.emCombate = true
    J.restricoes[0] = 2
    med.proximoId = med.proximoId + 1
    med.atual = { id = med.proximoId, jog = 0, pet = 0, ini = T }
    B.novaLuta()
  end
end

-- a luta so conta como "solo sem pet" para a API de threat se nao tinha pet nem grupo ao comecar
function B.novaLuta()
  B.luta = { ini = T, pulsos = 0, contexto = emGrupo() or (J.pet ~= nil and J.pet.existe == true) }
end

function B.carregarAddon()
  local ns = {}
  B.ns = ns
  local arqs = rawget(_G, "__ARQUIVOS") or {}
  for i = 1, #arqs do
    local a = arqs[i]
    local f, err = load(a.texto, "=" .. a.nome)
    if not f then
      B.cargaFalhas[#B.cargaFalhas + 1] = a.nome .. ": " .. primeiraLinha(err)
    else
      local ok, err2 = xpcall(f, function(m) return primeiraLinha(m) end, "CentralForever", ns)
      if not ok then B.cargaFalhas[#B.cargaFalhas + 1] = a.nome .. ": " .. primeiraLinha(err2) end
    end
    if a.nome == "Config.lua" and B.cenario and B.cenario.cfg and rawget(_G, "CentralForeverConfig") then
      local ok3, err3 = pcall(B.cenario.cfg, rawget(_G, "CentralForeverConfig"))
      if not ok3 then falha("AF", "afirma: o ajuste de config do cenario falhou: " .. primeiraLinha(err3)) end
    end
  end
end

-- liga os ganchos da bancada no que o addon publicou
function B.instalarGanchos()
  local ns = B.ns
  if otype(ns) ~= "table" then return end
  local P = ns.painel
  if otype(P) == "table" and otype(P.criar) == "function" and not P.__bancada then
    local orig = P.criar
    P.criar = function(...)
      local r = orig(...)
      if r == true then B.painelCriado = true end
      return r
    end
    P.__bancada = true
  end
  if otype(ns.falhou) == "function" and not B.falhouEmbrulhado then
    local orig = ns.falhou
    ns.falhou = function(recurso, erro)
      local txt = "?"
      if not S.eh(erro) and otype(erro) == "string" then txt = primeiraLinha(erro) end
      B.falhouChamadas[#B.falhouChamadas + 1] = ostring(recurso) .. ": " .. txt
      return orig(recurso, erro)
    end
    B.falhouEmbrulhado = true
  end
end

-- derruba a interface como o /reload: quadros, timers, eventos e globais do addon
function B.recarregar()
  local texto = B.serializarDB()
  frames = {}
  local internos = {}
  for i = 1, #timers do
    if timers[i].interno and not timers[i].cancelado then internos[#internos + 1] = timers[i] end
  end
  timers = internos
  local ue = B.UIParentE
  ue.filhos = {}
  ue.regioes = {}
  frames[1] = ue
  for _, nome in ipairs({ "CentralForeverPainel", "CentralForeverConfig", "CentralForeverDB", "SLASH_CENTRALFOREVER1" }) do rawset(_G, nome, nil) end
  for k in pairs(SlashCmdList) do rawset(SlashCmdList, k, nil) end
  B.painelCriado = false
  B.falhouEmbrulhado = false
  local env = {}
  local f = load(texto, "=CentralForever-sv", "t", env)
  if f then f() end
  rawset(_G, "CentralForeverDB", env.CentralForeverDB)
  B.carregarAddon()
  B.instalarGanchos()
  B.disparar("ADDON_LOADED", "CentralForever")
  B.disparar("PLAYER_ENTERING_WORLD", false, true)
  if B.ns and B.ns.painel and otype(B.ns.painel.existe) == "function" then
    local ok, r = pcall(B.ns.painel.existe)
    if ok and r == true then B.painelCriado = true end
  elseif rawget(_G, "CentralForeverPainel") then
    B.painelCriado = true
  end
end

local function varrerDB(v, caminho, vistos)
  if S.eh(v) then
    falha("A8", "A8: segredo guardado em " .. caminho)
    return
  end
  if otype(v) ~= "table" then return end
  if vistos[v] then return end
  vistos[v] = true
  for k, x in pairs(v) do
    if S.eh(k) then
      falha("A8", "A8: chave secreta em " .. caminho)
    else
      varrerDB(x, caminho .. "." .. ostring(k), vistos)
    end
  end
end

-- fecha a luta em curso para a conferencia do A9
function B.fecharLuta()
  local l = B.luta
  if not l or l.fim then return end
  l.fim = T
  B.lutas[#B.lutas + 1] = l
end

function B.conferirInvariantes()
  -- A1
  for _, m in ipairs(B.erros) do falha("A1", "A1: erro capturado: " .. m) end
  for _, m in ipairs(B.bancadaErros) do falha("A1", "A1: erro capturado: " .. m) end
  for _, m in ipairs(B.falhouChamadas) do falha("A1", "A1: ns.falhou(" .. m .. ")") end
  -- A2
  for _, m in ipairs(S.violacoes) do falha("A2", "A2: " .. m) end
  -- A8
  varrerDB(rawget(_G, "CentralForeverDB"), "CentralForeverDB", {})
  -- A9
  if J.emCombate then B.fecharLuta() end
  local cfg = rawget(_G, "CentralForeverConfig")
  local minimo = 8
  if otype(cfg) == "table" and otype(cfg.threat) == "table" and otype(cfg.threat.pulsoMinSeg) == "number" then minimo = cfg.threat.pulsoMinSeg end
  for i, l in ipairs(B.lutas) do
    local dur = (l.fim - l.ini) / 1000000
    local maximo = 1 + dur / minimo
    if l.pulsos > maximo then
      falha("A9", "A9: luta " .. i .. " com " .. l.pulsos .. " pulsos (maximo " .. oformat("%.2f", maximo) .. " em " .. oformat("%.1f", dur) .. " s)")
    end
  end
end

-- o que sai para o executor
function B.resultado(extra)
  local lista = {}
  for k in pairs(B.naoSimuladas) do lista[#lista + 1] = k end
  table.sort(lista)
  local r = {
    id = B.opcoes.id,
    titulo = B.cenario and B.cenario.titulo or "",
    chaves = B.chaves,
    afirmou = B.afirmar,
    falhas = B.falhas,
    cargaFalhou = B.cargaFalhas,
    chat = B.chat,
    avisos = B.avisos,
    naoSimuladas = lista,
    fotos = B.fotos,
    final = B.arvore(),
    tFinal = T / 1000000,
    sv = B.serializarDB(),
    contagem = B.contagem,
    eventos = B.eventos,
  }
  if extra then for k, v in pairs(extra) do r[k] = v end end
  return json(r)
end

-- roda um cenario inteiro e devolve o JSON do resultado
function B.executar()
  local op = B.opcoes
  local cenarios = rawget(_G, "__cenarios")
  local c = cenarios and cenarios.porId[op.id]
  if not c then error("bancada: cenario inexistente " .. ostring(op.id), 0) end
  B.cenario = c
  -- chaves U: padrao, depois as do cenario, depois as da matriz
  local ef = copiar(B.chavesPadrao)
  for k, v in pairs(c.chaves or {}) do ef[k] = v end
  local base = copiar(ef)
  for k, v in pairs(op.chaves or {}) do ef[k] = v end
  B.chaves = ef
  B.afirmar = not op.generico
  for k in pairs(ef) do
    if ef[k] ~= base[k] then B.afirmar = false end
  end
  S.modo.formatoErra = (ef.U1 == "erro")
  if ef.U10 == "nao" then
    for _, nome in ipairs({ "issecretvalue", "issecrettable", "canaccessvalue", "canaccesstable", "hasanysecretvalues", "scrubsecretvalues" }) do
      rawset(_G, nome, nil)
      B.ausentes[nome] = true
    end
  end
  B.ausentes.LibStub = true
  -- jogo e API ausente
  B.aplicarJogo(c.jogo)
  if c.dbInicial then rawset(_G, "CentralForeverDB", c.dbInicial) end
  if c.api then
    for _, nome in ipairs(c.api.sem or {}) do
      rawset(_G, nome, nil)
      B.ausentes[nome] = true
    end
    if c.api.medidorIndisponivel then
      J.medidorDisponivel = false
      J.medidorMotivo = c.api.medidorIndisponivel
    end
  end
  B.instalarGlobais()
  local p = __cenarios.passosDe(B)
  -- carga
  B.carregarAddon()
  B.instalarGanchos()
  if #B.cargaFalhas > 0 then return B.resultado() end
  B.disparar("ADDON_LOADED", "CentralForever")
  B.disparar("PLAYER_ENTERING_WORLD", true, false)
  if B.ns and B.ns.painel and otype(B.ns.painel.existe) == "function" then
    local ok, r = pcall(B.ns.painel.existe)
    if ok and r == true then B.painelCriado = true end
  elseif rawget(_G, "CentralForeverPainel") then
    B.painelCriado = true
  end
  -- passos
  local okp, errp = pcall(c.passos, p)
  if not okp then falha("AF", "afirma: o roteiro do cenario parou: " .. primeiraLinha(errp)) end
  -- fim: invariantes e afirmacoes
  B.conferirInvariantes()
  if B.afirmar and c.afirma then
    local a = __cenarios.afirmacoesDe(B, p)
    local oka, erra = pcall(c.afirma, a, p)
    if not oka then falha("AF", "afirma: a conferencia do cenario parou: " .. primeiraLinha(erra)) end
  end
  return B.resultado()
end
