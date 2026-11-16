-- Simulador de "valor secreto" do WoW Forever para a bancada (fengari, Lua 5.3).
-- Contrato: CentralForever\CONTRATO.md, secoes 4 e 11.2. Sintaxe mantida compativel com o parser 5.1.
-- Carregado por chunk de nome "=segredo": os erros apontam a linha do primeiro quadro que nao e deste arquivo.

local otype, otostring, otonumber = type, tostring, tonumber
local opairs, oipairs, onext = pairs, ipairs, next
local orawget, orawequal = rawget, rawequal
local oformat = string.format
local ofloor = math.floor
local unpack = table.unpack or unpack
local osetmetatable, oselect, oerror, ogetinfo = setmetatable, select, error, debug.getinfo

local S = {}
__seg = S
S.violacoes = {}
S.modo = { formatoErra = true }

-- valor real de cada segredo: tabela fraca, nunca no objeto
local real = osetmetatable({}, { __mode = "k" })
local MT = {}

local function onde()
  local nivel = 1
  while true do
    local info = ogetinfo(nivel, "Sl")
    if not info then return "?" end
    if info.what ~= "C" and info.short_src ~= "segredo" then
      return info.short_src .. ":" .. info.currentline
    end
    nivel = nivel + 1
  end
end

local function viola(texto)
  local m = "bancada: " .. texto .. " (" .. onde() .. ")"
  S.violacoes[#S.violacoes + 1] = m
  oerror(m, 0)
end

local function criar(tipo, v)
  local o = osetmetatable({}, MT)
  real[o] = { tipo = tipo, valor = v }
  return o
end

local function val(v)
  local r = real[v]
  if r then return r.valor end
  return v
end

local function algum(...)
  for i = 1, oselect("#", ...) do
    if real[(oselect(i, ...))] then return true end
  end
  return false
end

S.numero = function(v) return criar("number", v) end
S.texto = function(v) return criar("string", v) end
S.bool = function(v) return criar("boolean", v) end
S.tabela = function(t) return criar("table", t) end
S.eh = function(v) return real[v] ~= nil end
S.real = function(v) return val(v) end
S.algum = algum
S.recusa = function(nome, ...)
  if algum(...) then viola(otostring(nome) .. " recusou segredo") end
end

-- ---------- metametodos ----------
MT.__metatable = "bancada: travada"
local proibidos = { "add", "sub", "mul", "div", "mod", "pow", "unm", "idiv", "lt", "le", "len", "index", "newindex", "call", "eq", "tostring" }
for _, nome in oipairs(proibidos) do
  MT["__" .. nome] = function() viola(nome .. " com valor secreto") end
end
MT.__concat = function(a, b)
  if S.modo.formatoErra then viola("concat com valor secreto") end
  return criar("string", otostring(val(a)) .. otostring(val(b)))
end

-- ---------- globais trocadas ----------
type = function(v)
  local r = real[v]
  if r then return r.tipo end
  return otype(v)
end

tostring = function(v)
  local r = real[v]
  if r then
    if S.modo.formatoErra then viola("tostring com valor secreto") end
    return criar("string", otostring(r.valor))
  end
  return otostring(v)
end

tonumber = function(v, base)
  if real[v] or real[base] then viola("tonumber com valor secreto") end
  return otonumber(v, base)
end

rawequal = function(a, b)
  if real[a] or real[b] then viola("rawequal com valor secreto") end
  return orawequal(a, b)
end

rawget = function(t, k)
  if real[t] or real[k] then viola("rawget com valor secreto") end
  return orawget(t, k)
end

next = function(t, k)
  if real[t] or real[k] then viola("next com valor secreto") end
  return onext(t, k)
end

pairs = function(t)
  if real[t] then viola("pairs com valor secreto") end
  return opairs(t)
end

ipairs = function(t)
  if real[t] then viola("ipairs com valor secreto") end
  return oipairs(t)
end

local function formatar(fmt, ...)
  if algum(fmt, ...) then
    if S.modo.formatoErra then viola("string.format com valor secreto") end
    local n = oselect("#", ...)
    local args = {}
    for i = 1, n do args[i] = val((oselect(i, ...))) end
    return criar("string", oformat(val(fmt), unpack(args, 1, n)))
  end
  return oformat(fmt, ...)
end
string.format = formatar
format = formatar

do
  local nomes = {}
  for nome, f in opairs(math) do
    if otype(f) == "function" then nomes[#nomes + 1] = nome end
  end
  for _, nome in oipairs(nomes) do
    local f = math[nome]
    math[nome] = function(...)
      if algum(...) then viola("math." .. nome .. " com valor secreto") end
      return f(...)
    end
  end
end

-- ---------- predicados do jogo ----------
issecretvalue = function(v) return real[v] ~= nil end
issecrettable = function(t)
  local r = real[t]
  return r ~= nil and r.tipo == "table"
end
canaccessvalue = function(v) return real[v] == nil end
canaccesstable = function(t) return real[t] == nil end
hasanysecretvalues = function(...) return algum(...) end
scrubsecretvalues = function(...)
  local n = oselect("#", ...)
  local t = {}
  for i = 1, n do
    local v = (oselect(i, ...))
    if real[v] then t[i] = nil else t[i] = v end
  end
  return unpack(t, 1, n)
end

-- ---------- globais do codigo reescrito ----------
__B = function(x)
  if real[x] then viola("teste booleano com valor secreto") end
  return x
end
__EQ = function(a, b)
  if real[a] or real[b] then viola("comparacao com valor secreto") end
  return a == b
end
__K = function(k)
  if real[k] then viola("chave de tabela com valor secreto") end
  return k
end

-- ---------- formatadores do jogo: aceitam segredo ----------
local function numero(v)
  local r = val(v)
  if otype(r) == "string" then r = otonumber(r) end
  return r or 0
end

local function saida(secreto, texto)
  if secreto then return criar("string", texto) end
  return texto
end

local function inteiro(n) return oformat("%d", ofloor(n + 0.5)) end

local function milhar(n)
  local s = inteiro(n)
  local k
  repeat
    s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
  until k == 0
  return s
end

AbbreviateNumbers = function(v)
  local n = numero(v)
  local t
  if n < 1000 then t = inteiro(n)
  elseif n < 1000000 then t = oformat("%.1fK", n / 1000)
  else t = oformat("%.2fM", n / 1000000) end
  return saida(real[v] ~= nil, t)
end

AbbreviateLargeNumbers = function(v)
  local n = numero(v)
  local t
  if n < 1000 then
    if n == ofloor(n) then t = oformat("%d", n) else t = oformat("%.1f", n) end
  elseif n < 1000000 then t = milhar(n)
  else t = oformat("%.1fM", n / 1000000) end
  return saida(real[v] ~= nil, t)
end

BreakUpLargeNumbers = function(v)
  return saida(real[v] ~= nil, milhar(numero(v)))
end

C_StringUtil = {
  RoundToNearestString = function(v) return saida(real[v] ~= nil, inteiro(numero(v))) end,
  FloorToNearestString = function(v) return saida(real[v] ~= nil, oformat("%d", ofloor(numero(v)))) end,
  TruncateWhenZero = function(v)
    local n = numero(v)
    local t
    if n == 0 then t = ""
    elseif n == ofloor(n) then t = oformat("%d", n)
    else t = otostring(n) end
    return saida(real[v] ~= nil, t)
  end,
  WrapString = function(infix, prefix, suffix)
    local i = val(infix)
    local t
    if i == nil or i == "" then
      t = ""
    else
      local p, s = val(prefix), val(suffix)
      if p == nil then p = "" end
      if s == nil then s = "" end
      t = otostring(p) .. otostring(i) .. otostring(s)
    end
    return saida(algum(infix, prefix, suffix), t)
  end,
}
