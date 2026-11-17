-- Falso do WoW para a bancada do PregaoForever: nucleo.
-- Registro de chamadas, relogio simulado, timers, eventos, quadros, utilidades de texto, serializacao de SV.
-- Roda no fengari (Lua 5.3), onde inteiros tem 32 bits: todo tempo aqui e float (microssegundos).
-- So ASCII. Carregado por bancada-pregao.mjs antes de leilao.lua e executor.lua.

local select, type, tostring, tonumber, pairs, ipairs = select, type, tostring, tonumber, pairs, ipairs
local pack, unpack = table.pack, table.unpack
local floor = math.floor
local oformat = string.format

local B = {
  cont = {},          -- nome -> numero de chamadas
  regs = {},          -- nome -> lista de registros { nome, t, args, n, clique }
  ev = {},            -- eventos disparados pelo falso, em ordem
  erros = {},         -- erros capturados pelo geterrorhandler
  violacoes = {},     -- { tipo, msg, t }
  naoSimuladas = {},  -- metodos de quadro que o falso so aceita sem efeito
  chat = {},          -- o que o addon imprimiu
  saidas = {},        -- arquivos que o executor pede ao node para gravar
  bindings = {},      -- dono -> tecla -> nome do botao
  cliqueSeq = 0,
  ultimaTecla = nil,
}
__bancada = B

-- ---------------------------------------------------------------------------
-- Registro das chamadas ao falso
-- ---------------------------------------------------------------------------
local T = 0.0           -- microssegundos simulados desde o inicio do cenario
local CPU = 0.0         -- microssegundos de "processamento" acumulados por GetTimePreciseSec
B.EPOCH = 1794862800    -- 2026-11-16 21:00:00 UTC

function B.agora() return T / 1000000 end
function B.agoraUs() return T end

local function guardar(chave, rec)
  B.cont[chave] = (B.cont[chave] or 0) + 1
  local l = B.regs[chave]
  if not l then l = {}; B.regs[chave] = l end
  l[#l + 1] = rec
end

local function registrar(nome, qual, ...)
  local rec = { nome = nome, t = T / 1000000, args = pack(...), n = select("#", ...), clique = B.clique and B.clique.id or nil }
  guardar(nome, rec)
  if qual then guardar(qual, rec) end
  return rec
end
B.registrar = registrar

-- define tab[nome] como wrapper que registra a chamada (sob o nome puro e sob o qualificado) e chama fn
function B.def(tab, prefixo, nome, fn)
  local qual = prefixo and (prefixo .. "." .. nome) or nil
  tab[nome] = function(...)
    registrar(nome, qual, ...)
    return fn(...)
  end
end

function B.violar(tipo, msg)
  B.violacoes[#B.violacoes + 1] = { tipo = tipo, msg = msg, t = T / 1000000 }
end

-- ---------------------------------------------------------------------------
-- Erros
-- ---------------------------------------------------------------------------
local function manipulador(e)
  local texto
  if type(e) == "string" then texto = e else texto = "erro nao textual (" .. type(e) .. ")" end
  B.erros[#B.erros + 1] = texto
  return e
end
function geterrorhandler() return manipulador end
function seterrorhandler() end
local function chamar(fn, ...) return xpcall(fn, manipulador, ...) end
B.chamar = chamar
B.manipulador = manipulador

-- ---------------------------------------------------------------------------
-- Ajustes de Lua 5.1 (o que o WoW poe no ambiente) sem esconder o que a 5.3 muda:
-- nao existem unpack global, loadstring, table.getn, bit. Isso e de proposito.
-- ---------------------------------------------------------------------------
tinsert, tremove, sort = table.insert, table.remove, table.sort
strlen, strsub, strlower, strupper, strfind, strmatch, strrep, strbyte, strchar = string.len, string.sub, string.lower, string.upper, string.find, string.match, string.rep, string.byte, string.char
gsub, gmatch, format = string.gsub, string.gmatch, string.format
floor, ceil, abs, max, min, sqrt = math.floor, math.ceil, math.abs, math.max, math.min, math.sqrt

function strtrim(s, chars)
  chars = chars or " \t\r\n"
  local c = "[" .. string.gsub(chars, "[%^%]%-%%]", "%%%0") .. "]"
  local r = string.gsub(tostring(s), "^" .. c .. "+", "")
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
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
table.wipe = wipe
function Mixin(obj, ...)
  for i = 1, select("#", ...) do for k, v in pairs((select(i, ...))) do obj[k] = v end end
  return obj
end
function print(...)
  local t = {}
  for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
  B.chat[#B.chat + 1] = table.concat(t, " ")
end

-- aleatorio deterministico (semente do cenario)
local semente = 1
function B.semear(s) semente = (tonumber(s) or 1) % 2147483629 + 1 end
function math.randomseed(s) B.semear(s) end
local function proximoAleatorio()
  semente = (semente * 48271) % 2147483647
  return semente / 2147483647
end
function math.random(a, b)
  local r = proximoAleatorio()
  if a == nil then return r end
  if b == nil then a, b = 1, a end
  return a + floor(r * (b - a + 1))
end
random = math.random
B.aleatorio = proximoAleatorio

-- ---------------------------------------------------------------------------
-- Hora: GetTime, GetServerTime, GetTimePreciseSec, date, time
-- ---------------------------------------------------------------------------
B.fuso = 0  -- horas somadas ao UTC para date('*t') (hora local da maquina)

local function civil(dias)
  local z = dias + 719468
  local era = floor(z / 146097)
  local doe = z - era * 146097
  local yoe = floor((doe - floor(doe / 1460) + floor(doe / 36524) - floor(doe / 146096)) / 365)
  local y = yoe + era * 400
  local doy = doe - (365 * yoe + floor(yoe / 4) - floor(yoe / 100))
  local mp = floor((5 * doy + 2) / 153)
  local d = doy - floor((153 * mp + 2) / 5) + 1
  local m = mp + 3
  if m > 12 then m = m - 12 end
  if m <= 2 then y = y + 1 end
  return y, m, d
end

local function segundosServidor() return B.EPOCH + floor(T / 1000000) end

local function soContar(n) B.cont[n] = (B.cont[n] or 0) + 1 end
function GetTime()
  soContar("GetTime")
  return 1000 + T / 1000000
end
function GetServerTime()
  soContar("GetServerTime")
  return segundosServidor()
end
function GetTimePreciseSec()
  soContar("GetTimePreciseSec")
  CPU = CPU + 50  -- cada leitura "gasta" 50 microssegundos, para o fatiamento por tempo andar
  return 1000 + (T + CPU) / 1000000
end
function debugprofilestop()
  soContar("debugprofilestop")
  CPU = CPU + 50
  return (T + CPU) / 1000
end
function time(t)
  if type(t) == "table" then return segundosServidor() end
  return segundosServidor()
end
function date(f, t)
  f = f or "%c"
  if string.sub(f, 1, 1) == "!" then f = string.sub(f, 2) end
  t = floor((t or segundosServidor()) + B.fuso * 3600)
  local dias = floor(t / 86400)
  local resto = t - dias * 86400
  local y, m, d = civil(dias)
  local H, M, S = floor(resto / 3600), floor((resto % 3600) / 60), resto % 60
  if f == "*t" then return { year = y, month = m, day = d, hour = H, min = M, sec = S, wday = (dias + 4) % 7 + 1, yday = 1, isdst = false } end
  local mapa = { Y = oformat("%04d", y), y = oformat("%02d", y % 100), m = oformat("%02d", m), d = oformat("%02d", d), H = oformat("%02d", H), M = oformat("%02d", M), S = oformat("%02d", S) }
  mapa.c = mapa.Y .. "-" .. mapa.m .. "-" .. mapa.d .. " " .. mapa.H .. ":" .. mapa.M .. ":" .. mapa.S
  return (string.gsub(f, "%%(%a)", function(c) return mapa[c] or ("%" .. c) end))
end

-- ---------------------------------------------------------------------------
-- Timers no relogio simulado
-- ---------------------------------------------------------------------------
local timers = {}
local seqTimer = 0
local PASSO_ONUPDATE = 50000.0
local ultimoTick = 0.0
local MIN_QUADRO = 16667.0  -- C_Timer.After(0) so dispara no proximo quadro (60 por segundo)

local function novoTimer(seg, fn, repete, iter, interno)
  if type(fn) ~= "function" then error("bancada: C_Timer com callback que nao e funcao", 3) end
  seqTimer = seqTimer + 1
  local us = (tonumber(seg) or 0) * 1000000.0
  if not interno and us < MIN_QUADRO then us = MIN_QUADRO end
  if interno and us < 0 then us = 0.0 end
  local reg = { due = T + us, seq = seqTimer, fn = fn, intervalo = repete and us or nil, restam = iter, cancelado = false, interno = interno }
  local obj = {}
  obj.Cancel = function() reg.cancelado = true end
  obj.IsCancelled = function() return reg.cancelado end
  reg.obj = obj
  timers[#timers + 1] = reg
  return obj, reg
end

C_Timer = {}
B.def(C_Timer, "C_Timer", "After", function(seg, fn) novoTimer(seg, fn, false) end)
B.def(C_Timer, "C_Timer", "NewTimer", function(seg, fn) return (novoTimer(seg, fn, false)) end)
B.def(C_Timer, "C_Timer", "NewTicker", function(seg, fn, iter) return (novoTimer(seg, fn, true, iter)) end)

-- agenda uma acao do proprio falso (resposta do servidor); nao e timer do addon
function B.agendar(seg, fn) return novoTimer(seg, fn, false, nil, true) end

function B.cancelarTimersDoAddon()
  for i = 1, #timers do
    if not timers[i].interno then timers[i].cancelado = true end
  end
end

local function proximoTimer()
  local melhor
  for i = 1, #timers do
    local r = timers[i]
    if not r.cancelado and (not melhor or r.due < melhor.due or (r.due == melhor.due and r.seq < melhor.seq)) then melhor = r end
  end
  return melhor
end

-- ha timer de disparo unico ainda por vir (do addon ou do falso)? Tickers nao contam.
function B.pendentes()
  for i = 1, #timers do
    local r = timers[i]
    if not r.cancelado and not r.intervalo then return true end
  end
  return false
end
function B.proximaHora()
  local r = proximoTimer()
  return r and r.due or nil
end
function B.timersDoAddon()
  local n = 0
  for i = 1, #timers do
    local r = timers[i]
    if not r.cancelado and not r.interno then n = n + 1 end
  end
  return n
end

-- ---------------------------------------------------------------------------
-- Eventos e quadros
-- ---------------------------------------------------------------------------
local E = setmetatable({}, { __mode = "k" })   -- widget -> dados
local frames = {}                              -- quadros (dados) em ordem de criacao
local proximoId = 0
local IMPL = {}
B.E = E

local function chamarScript(e, nome, ...)
  local fn = e.scripts[nome]
  if fn then chamar(fn, e.w, ...) end
  local hs = e.hooks[nome]
  if hs then
    for i = 1, #hs do chamar(hs[i], e.w, ...) end
  end
end

function B.disparar(nome, ...)
  B.ev[#B.ev + 1] = { nome = nome, t = T / 1000000, args = pack(...), n = select("#", ...) }
  local lista = {}
  for i = 1, #frames do lista[i] = frames[i] end
  for i = 1, #lista do
    local e = lista[i]
    if e.eventos[nome] and not e.removido then chamarScript(e, "OnEvent", nome, ...) end
  end
end

local function visivelEfetivo(e)
  while e do
    if not e.visivel then return false end
    e = e.pai
  end
  return true
end

local function existeOnUpdate()
  for i = 1, #frames do
    local e = frames[i]
    if (e.scripts.OnUpdate or (e.hooks.OnUpdate and #e.hooks.OnUpdate > 0)) and not e.removido and visivelEfetivo(e) then return true end
  end
  return false
end

local function tickOnUpdate(dt)
  local lista = {}
  for i = 1, #frames do lista[i] = frames[i] end
  for i = 1, #lista do
    local e = lista[i]
    if not e.removido and visivelEfetivo(e) and (e.scripts.OnUpdate or e.hooks.OnUpdate) then chamarScript(e, "OnUpdate", dt / 1000000) end
  end
end

-- avanca o relogio ate `dest` (microssegundos), rodando timers vencidos e OnUpdate, em ordem
function B.rodarAte(dest)
  local guarda = 0
  while true do
    guarda = guarda + 1
    if guarda > 200000 then error("bancada: laco de timers (mais de 200000 passos)", 0) end
    local r = proximoTimer()
    local cand, qual = dest, "fim"
    if r and r.due <= cand then cand, qual = r.due, "timer" end
    if existeOnUpdate() then
      if ultimoTick < T then ultimoTick = T end
      local tk = ultimoTick + PASSO_ONUPDATE
      if tk < cand then cand, qual = tk, "tick" end
    end
    if cand > T then T = cand end
    if qual == "timer" then
      if r.intervalo then
        r.due = r.due + r.intervalo
        if r.restam then
          r.restam = r.restam - 1
          if r.restam <= 0 then r.cancelado = true end
        end
      else
        r.cancelado = true
      end
      seqTimer = seqTimer + 1
      r.seq = seqTimer
      chamar(r.fn, r.obj)
    elseif qual == "tick" then
      local dt = T - ultimoTick
      ultimoTick = T
      tickOnUpdate(dt)
    else
      break
    end
  end
  if dest > T then T = dest end
  local novos = {}
  for i = 1, #timers do
    if not timers[i].cancelado then novos[#novos + 1] = timers[i] end
  end
  timers = novos
end

-- ---------------------------------------------------------------------------
-- Widgets
-- ---------------------------------------------------------------------------
local MT = {}
local cacheM = {}
local PADRAO_GET = { GetAlpha = 1, GetScale = 1, GetEffectiveScale = 1, GetFrameLevel = 1, GetFrameStrata = "MEDIUM", GetValue = 0, GetNumLines = 0 }
local VERBOS_COM_EFEITO_PROPRIO = { Raise = true, Lower = true }

local function generico(k, e, ...)
  local prefixo, resto = string.match(k, "^(%u%l+)(.*)$")
  if prefixo == "Set" then
    e.v[resto] = pack(...)
    return
  elseif prefixo == "Get" then
    local v = e.v[resto]
    if v then return unpack(v, 1, v.n) end
    return PADRAO_GET[k]
  elseif prefixo == "Is" or prefixo == "Has" then
    return false
  end
  B.naoSimuladas[k] = true
  return nil
end

MT.__index = function(_, k)
  if type(k) ~= "string" then return nil end
  local f = cacheM[k]
  if f then return f end
  if not string.find(k, "^%u") then return nil end
  f = function(self, ...)
    local e = E[self]
    if not e then error("bancada: metodo " .. k .. " chamado sem o objeto (use ':')", 2) end
    B.cont[k] = (B.cont[k] or 0) + 1
    local impl = IMPL[k]
    if impl then return impl(self, e, ...) end
    return generico(k, e, ...)
  end
  cacheM[k] = f
  return f
end

local function novoWidget(tipo, nome, pai, sistema)
  proximoId = proximoId + 1
  local w = {}
  local e = {
    w = w, tipo = tipo, nome = nome, id = proximoId, pai = pai, filhos = {}, regioes = {}, pontos = {},
    scripts = {}, hooks = {}, eventos = {}, v = {}, visivel = true, sistema = sistema or false,
    texto = "", removido = false,
  }
  E[w] = e
  setmetatable(w, MT)
  return w, e
end

local function ehQuadro(tipo) return tipo ~= "FontString" and tipo ~= "Texture" and tipo ~= "MaskTexture" and tipo ~= "Font" end

local function nomeGlobal(nome, w)
  if nome == nil then return end
  if type(nome) ~= "string" then error("bancada: nome de quadro nao textual", 3) end
  rawset(_G, nome, w)
end

local sistemaAtivo = true  -- quadros criados durante a montagem do falso nao sao do addon

function CreateFrame(tipo, nome, pai, template)
  registrar("CreateFrame", nil, tipo, nome, pai, template)
  if type(tipo) ~= "string" then error("bancada: CreateFrame sem tipo", 2) end
  local pe
  if pai ~= nil then pe = E[pai]; if not pe then error("bancada: CreateFrame com pai que nao e quadro", 2) end end
  if pe == nil and UIParent and tipo ~= "Font" then pe = E[UIParent] end
  local w, e = novoWidget(tipo, nome, pe, sistemaAtivo)
  if pe then pe.filhos[#pe.filhos + 1] = e end
  e.template = template
  frames[#frames + 1] = e
  nomeGlobal(nome, w)
  return w
end

function CreateFont(nome)
  registrar("CreateFont", nil, nome)
  local w, e = novoWidget("Font", nome, nil, sistemaAtivo)
  nomeGlobal(nome, w)
  return w
end

local function criarRegiao(tipo, e, nome)
  local w, re = novoWidget(tipo, nome, e, sistemaAtivo)
  e.regioes[#e.regioes + 1] = re
  nomeGlobal(nome, w)
  return w
end

IMPL.CreateFontString = function(_, e, nome) return criarRegiao("FontString", e, nome) end
IMPL.CreateTexture = function(_, e, nome) return criarRegiao("Texture", e, nome) end
IMPL.CreateMaskTexture = function(_, e, nome) return criarRegiao("MaskTexture", e, nome) end
IMPL.GetName = function(_, e) return e.nome end
IMPL.GetObjectType = function(_, e) return e.tipo end
IMPL.IsObjectType = function(_, e, t) return e.tipo == t or (t == "Frame" and ehQuadro(e.tipo)) end
IMPL.GetParent = function(_, e) return e.pai and e.pai.w or nil end
IMPL.SetParent = function(_, e, pai)
  if e.pai then
    for i, x in ipairs(e.pai.filhos) do if x == e then table.remove(e.pai.filhos, i) break end end
    for i, x in ipairs(e.pai.regioes) do if x == e then table.remove(e.pai.regioes, i) break end end
  end
  if pai == nil then e.pai = nil return end
  local pe = E[pai]
  if not pe then error("bancada: SetParent com pai que nao e quadro", 2) end
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
IMPL.GetNumRegions = function(_, e) return #e.regioes end

IMPL.SetScript = function(_, e, nome, fn)
  if fn ~= nil and type(fn) ~= "function" then error("bancada: SetScript(" .. tostring(nome) .. ") precisa de funcao ou nil", 2) end
  e.scripts[nome] = fn
end
IMPL.GetScript = function(_, e, nome) return e.scripts[nome] end
IMPL.HasScript = function() return true end
IMPL.HookScript = function(_, e, nome, fn)
  if type(fn) ~= "function" then error("bancada: HookScript(" .. tostring(nome) .. ") precisa de funcao", 2) end
  local l = e.hooks[nome]
  if not l then l = {}; e.hooks[nome] = l end
  l[#l + 1] = fn
end

IMPL.RegisterEvent = function(_, e, ev)
  if type(ev) ~= "string" then error("bancada: RegisterEvent com evento nao textual", 2) end
  e.eventos[ev] = true
  return true
end
IMPL.RegisterUnitEvent = IMPL.RegisterEvent
IMPL.UnregisterEvent = function(_, e, ev) e.eventos[ev] = nil end
IMPL.UnregisterAllEvents = function(_, e) e.eventos = {} end
IMPL.IsEventRegistered = function(_, e, ev) return e.eventos[ev] == true end

IMPL.SetPoint = function(_, e, ponto, a, b, c, d)
  if type(ponto) ~= "string" then error("bancada: SetPoint com ponto invalido", 2) end
  local rel, relP, x, y = nil, nil, 0, 0
  if type(a) == "number" then
    x, y = a, b or 0
  elseif a ~= nil then
    rel = a
    if type(b) == "number" then x, y, relP = b, c or 0, ponto else relP, x, y = b or ponto, c or 0, d or 0 end
  end
  local novo = { ponto = ponto, rel = rel, relPonto = relP, x = x, y = y }
  for i, p in ipairs(e.pontos) do
    if p.ponto == ponto then e.pontos[i] = novo return end
  end
  e.pontos[#e.pontos + 1] = novo
end
IMPL.ClearAllPoints = function(_, e) e.pontos = {} end
IMPL.SetAllPoints = function(_, e, rel) e.pontos = { { ponto = "ALL", rel = rel, x = 0, y = 0 } } end
IMPL.GetNumPoints = function(_, e) return #e.pontos end
IMPL.GetPoint = function(_, e, i)
  local p = e.pontos[i or 1]
  if not p then return nil end
  return p.ponto, p.rel, p.relPonto or p.ponto, p.x, p.y
end
IMPL.SetSize = function(_, e, l, a) e.largura, e.altura = l, a end
IMPL.SetWidth = function(_, e, l) e.largura = l end
IMPL.SetHeight = function(_, e, a) e.altura = a end
IMPL.GetWidth = function(_, e) return e.largura or 0 end
IMPL.GetHeight = function(_, e) return e.altura or 0 end
IMPL.GetSize = function(_, e) return e.largura or 0, e.altura or 0 end
IMPL.GetLeft = function() return 0 end
IMPL.GetBottom = function() return 0 end
IMPL.GetRight = function(_, e) return e.largura or 0 end
IMPL.GetTop = function(_, e) return e.altura or 0 end
IMPL.GetCenter = function(_, e) return (e.largura or 0) / 2, (e.altura or 0) / 2 end
IMPL.GetStringWidth = function(_, e) return #e.texto * 6 end
IMPL.GetStringHeight = function(_, e)
  local n = 1
  for _ in string.gmatch(e.texto, "\n") do n = n + 1 end
  return 12 * n
end
IMPL.GetUnboundedStringWidth = IMPL.GetStringWidth
IMPL.GetTextWidth = IMPL.GetStringWidth
IMPL.SetFont = function() return true end

IMPL.SetText = function(_, e, t)
  if t == nil then t = "" end
  e.texto = tostring(t)
end
IMPL.SetFormattedText = function(_, e, f, ...) e.texto = string.format(f, ...) end
IMPL.GetText = function(_, e) return e.texto end
IMPL.GetFontString = function(self, e)
  if not e.fs then e.fs = criarRegiao("FontString", e, nil) end
  return e.fs
end

local function mostrar(e, b)
  if b == e.visivel then return end
  e.visivel = b
  chamarScript(e, b and "OnShow" or "OnHide")
end
IMPL.Show = function(_, e) mostrar(e, true) end
IMPL.Hide = function(_, e) mostrar(e, false) end
IMPL.SetShown = function(_, e, b) mostrar(e, b and true or false) end
IMPL.IsShown = function(_, e) return e.visivel end
IMPL.IsVisible = function(_, e) return visivelEfetivo(e) end
IMPL.Enable = function(_, e) e.desab = false end
IMPL.Disable = function(_, e) e.desab = true end
IMPL.SetEnabled = function(_, e, b) e.desab = not b end
IMPL.IsEnabled = function(_, e) return not e.desab end

-- clique de software: roda o OnClick, nao cria bandeira de hardware
IMPL.Click = function(_, e, botao)
  if e.desab then return end
  chamarScript(e, "PreClick", botao or "LeftButton", false)
  chamarScript(e, "OnClick", botao or "LeftButton", false)
  chamarScript(e, "PostClick", botao or "LeftButton", false)
end

-- caixa de texto e foco
local foco = nil
IMPL.SetFocus = function(_, e) foco = e end
IMPL.ClearFocus = function(_, e) if foco == e then foco = nil end end
IMPL.HasFocus = function(_, e) return foco == e end
function GetCurrentKeyBoardFocus()
  registrar("GetCurrentKeyBoardFocus")
  return foco and foco.w or nil
end
-- (a caixa de texto falsa e criada com os quadros do sistema, mais abaixo)
function B.focoTexto(sim)
  foco = sim and E[B.editBoxFalso] or nil
end

-- chamada pela bancada: clique com a bandeira de hardware
function B.despacharClique(e, hardware)
  B.cliqueSeq = B.cliqueSeq + 1
  B.clique = { id = B.cliqueSeq, botao = e.nome, hw = hardware, acoes = 0 }
  chamarScript(e, "PreClick", "LeftButton", false)
  chamarScript(e, "OnClick", "LeftButton", false)
  chamarScript(e, "PostClick", "LeftButton", false)
  B.clique = nil
end

function B.quadroPorNome(nome)
  local w = rawget(_G, nome)
  if w and E[w] then return E[w] end
  return nil
end

-- tira do mundo os quadros do addon (reload); os do sistema ficam, sem os ganchos do addon
function B.limparQuadrosDoAddon()
  local ficam = {}
  for i = 1, #frames do
    local e = frames[i]
    if e.sistema then
      e.scripts = {}; e.hooks = {}; e.eventos = {}
      ficam[#ficam + 1] = e
    else
      e.removido = true
      e.visivel = false
    end
  end
  frames = ficam
  foco = nil
  for _, e in ipairs(frames) do
    local fs, rs = {}, {}
    for _, f in ipairs(e.filhos) do if f.sistema then fs[#fs + 1] = f end end
    for _, r in ipairs(e.regioes) do if r.sistema then rs[#rs + 1] = r end end
    e.filhos, e.regioes = fs, rs
  end
end

function B.fimDaMontagem() sistemaAtivo = false end

-- quadros do sistema
UIParent = CreateFrame("Frame", "UIParent")
E[UIParent].pai = nil
UIParent:SetSize(1920, 1080)
AuctionHouseFrame = CreateFrame("Frame", "AuctionHouseFrame", UIParent)
AuctionHouseFrame:SetSize(840, 440)
AuctionHouseFrame:Hide()
GameTooltip = CreateFrame("GameTooltip", "GameTooltip", UIParent)
B.editBoxFalso = CreateFrame("EditBox", "PregaoBancadaEditBox", UIParent)
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end
function GetCursorPosition() return 0, 0 end
function PlaySound() end

-- ---------------------------------------------------------------------------
-- Ganchos, bindings, combate, recarga
-- ---------------------------------------------------------------------------
local ganchos = {}   -- [tabela][nome] = { originais = fn, lista = { fn } }
function hooksecurefunc(a, b, c)
  local tab, nome, fn
  if type(a) == "string" then tab, nome, fn = _G, a, b else tab, nome, fn = a, b, c end
  if type(fn) ~= "function" or type(tab[nome]) ~= "function" then error("bancada: hooksecurefunc sobre algo que nao e funcao: " .. tostring(nome), 2) end
  ganchos[tab] = ganchos[tab] or {}
  local g = ganchos[tab][nome]
  if not g then
    g = { original = tab[nome], lista = {} }
    ganchos[tab][nome] = g
    tab[nome] = function(...)
      local r = pack(g.original(...))
      for i = 1, #g.lista do chamar(g.lista[i], ...) end
      return unpack(r, 1, r.n)
    end
  end
  g.lista[#g.lista + 1] = fn
end
function B.limparGanchos()
  for tab, porNome in pairs(ganchos) do
    for nome, g in pairs(porNome) do g.lista = {} end
  end
end
function securecall(fn, ...) if type(fn) == "string" then fn = _G[fn] end return fn(...) end

EventRegistry = { callbacks = {} }
function EventRegistry:RegisterCallback(nome, fn, dono)
  local l = self.callbacks[nome] or {}
  self.callbacks[nome] = l
  l[#l + 1] = { fn = fn, dono = dono }
end
function EventRegistry:UnregisterCallback(nome, dono)
  local l = self.callbacks[nome]
  if not l then return end
  for i = #l, 1, -1 do if l[i].dono == dono then table.remove(l, i) end end
end
function EventRegistry:TriggerEvent(nome, ...)
  local l = self.callbacks[nome]
  if not l then return end
  for i = 1, #l do chamar(l[i].fn, l[i].dono, ...) end
end
TooltipDataProcessor = { AddTooltipPostCall = function() end }
SlashCmdList = {}

function SetOverrideBindingClick(dono, prioridade, tecla, botao, mouse)
  registrar("SetOverrideBindingClick", nil, dono, prioridade, tecla, botao, mouse)
  if InCombatLockdown() then
    B.violar("combate", "SetOverrideBindingClick(" .. tostring(tecla) .. ") em combate")
    return
  end
  if not B.temPrefixo(botao) then
    B.violar("binding", "SetOverrideBindingClick aponta para botao que nao e " .. B.nomeAddon() .. "*: " .. tostring(botao))
  end
  local d = B.bindings[dono]
  if not d then d = {}; B.bindings[dono] = d end
  d[tecla] = botao
end
function ClearOverrideBindings(dono)
  registrar("ClearOverrideBindings", nil, dono)
  if InCombatLockdown() then
    B.violar("combate", "ClearOverrideBindings em combate")
    return
  end
  B.bindings[dono] = nil
end
function SetOverrideBinding(dono, prioridade, tecla, comando)
  registrar("SetOverrideBinding", nil, dono, prioridade, tecla, comando)
  B.violar("binding", "SetOverrideBinding fora da forma Click: " .. tostring(comando))
end

B.combate = false
function InCombatLockdown()
  registrar("InCombatLockdown")
  return B.combate
end

function ReloadUI()
  registrar("ReloadUI")
  B.reloadPendente = true
end

-- ---------------------------------------------------------------------------
-- Nome do addon carregado (vem do .toc, via __ADDON, que o node cria depois deste arquivo: leitura sempre tardia)
-- ---------------------------------------------------------------------------
function B.nomeAddon() return (type(__ADDON) == "table" and __ADDON.nome) or "PregaoForever" end
function B.temPrefixo(s)
  local p = B.nomeAddon()
  return type(s) == "string" and string.sub(s, 1, #p) == p
end
function B.svPrimeira() return (type(__ADDON) == "table" and __ADDON.svs and __ADDON.svs[1]) or "PregaoForeverDB" end
function B.svCharPrimeira() return (type(__ADDON) == "table" and __ADDON.svs_char and __ADDON.svs_char[1]) or "PregaoForeverCharDB" end
function B.svNomes()
  local out = {}
  if type(__ADDON) == "table" and __ADDON.svs then
    for _, n in ipairs(__ADDON.svs) do out[#out + 1] = n end
    for _, n in ipairs(__ADDON.svs_char or {}) do out[#out + 1] = n end
    return out
  end
  return { "PregaoForeverDB", "PregaoForeverCharDB" }
end

-- ---------------------------------------------------------------------------
-- Serializacao de SavedVariables (formato do WoW)
-- ---------------------------------------------------------------------------
local function esc(s)
  s = string.gsub(s, "\\", "\\\\")
  s = string.gsub(s, "\"", "\\\"")
  s = string.gsub(s, "\n", "\\n")
  s = string.gsub(s, "\r", "\\r")
  s = string.gsub(s, "[%z\1-\8\11\12\14-\31]", function(c) return oformat("\\%d", string.byte(c)) end)
  return s
end
local function numTexto(v)
  if v ~= v or v == math.huge or v == -math.huge then return "0" end
  -- o WoW (Lua 5.1) grava 5.0 como 5; aqui tambem
  if v == floor(v) and v > -1e15 and v < 1e15 then return oformat("%d", v) end
  return oformat("%.14g", v)
end
local function chavesOrdenadas(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks, function(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return ta < tb end
    if ta == "number" or ta == "string" then return a < b end
    return tostring(a) < tostring(b)
  end)
  return ks
end
local function serie(v, nivel, vistos, caminho)
  local t = type(v)
  if t == "nil" then return "nil" end
  if t == "boolean" then return v and "true" or "false" end
  if t == "number" then return numTexto(v) end
  if t == "string" then return "\"" .. esc(v) .. "\"" end
  if t ~= "table" then return "nil" end   -- funcao, userdata e thread nao vao ao disco
  if vistos[v] then return "nil" end
  vistos[v] = true
  local pad = string.rep("\t", nivel + 1)
  local linhas = {}
  for _, k in ipairs(chavesOrdenadas(v)) do
    local kt = type(k)
    local ks
    if kt == "number" then ks = "[" .. numTexto(k) .. "]" elseif kt == "string" then ks = "[\"" .. esc(k) .. "\"]" end
    local vt = type(v[k])
    if ks and vt ~= "function" and vt ~= "userdata" and vt ~= "thread" then
      local comentario = kt == "number" and (" -- " .. ks) or ""
      linhas[#linhas + 1] = pad .. ks .. " = " .. serie(v[k], nivel + 1, vistos) .. "," .. comentario
    end
  end
  vistos[v] = nil
  if #linhas == 0 then return "{}" end
  return "{\n" .. table.concat(linhas, "\n") .. "\n" .. string.rep("\t", nivel) .. "}"
end
B.serie = serie

function B.serializarSV()
  local out = {}
  for _, nome in ipairs(B.svNomes()) do
    local v = rawget(_G, nome)
    if v ~= nil then out[#out + 1] = nome .. " = " .. serie(v, 0, {}) .. "\n" end
  end
  return table.concat(out)
end

function B.copiaProfunda(v, vistos)
  if type(v) ~= "table" then return v end
  vistos = vistos or {}
  if vistos[v] then return vistos[v] end
  local c = {}
  vistos[v] = c
  for k, x in pairs(v) do c[B.copiaProfunda(k, vistos)] = B.copiaProfunda(x, vistos) end
  return c
end

-- ---------------------------------------------------------------------------
-- Jogador, reino, addons, versao
-- ---------------------------------------------------------------------------
B.J = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0 }
local J = B.J

function UnitName(tok)
  registrar("UnitName", nil, tok)
  if tok == "player" then return J.personagem, nil end
  return nil
end
function GetUnitName(tok)
  registrar("GetUnitName", nil, tok)
  if tok == "player" then return J.personagem end
  return nil
end
function GetRealmName() registrar("GetRealmName") return J.reino end
function GetNormalizedRealmName()
  registrar("GetNormalizedRealmName")
  return (string.gsub(J.reino, "[%s%-]", ""))
end
function UnitFactionGroup(tok)
  registrar("UnitFactionGroup", nil, tok)
  if tok == "player" then return J.faccao, J.faccao end
  return nil
end
function UnitClass(tok) if tok == "player" then return "Warrior", "WARRIOR", 1 end end
function UnitGUID(tok) if tok == "player" then return "Player-1-00000001" end end
function GetLocale() return "enUS" end
function IsLoggedIn() return true end
function GetBuildInfo() return "1.60.1", "70938", "Nov 16 2026", 16001 end
function IsAddOnLoaded() return false end
C_AddOns = {
  IsAddOnLoaded = function() return false end,
  GetAddOnMetadata = function(_, campo)
    if campo == "Version" then return "0.1.0" end
    if campo == "Title" then return B.nomeAddon() end
    return nil
  end,
}
GetAddOnMetadata = C_AddOns.GetAddOnMetadata
Enum = Enum or {}

function GetMoney()
  registrar("GetMoney")
  return J.dinheiro
end

return B
