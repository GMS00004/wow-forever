-- Executor de cenarios da bancada do PregaoForever: carrega o addon, roda os passos, monta a tabela b e o resultado.
-- Recebe do node: __ADDON ({ arquivos = { { nome, texto } } }). Fengari (Lua 5.3). So ASCII.

local B = __bancada
local unpack = table.unpack
local pack = table.pack
local floor = math.floor

B.fimDaMontagem()
B.baseG = {}
B.cargaFalhou = {}
B.falhas = {}

-- ---------------------------------------------------------------------------
-- Texto e igualdade para as asserções
-- ---------------------------------------------------------------------------
local function curto(v, prof)
  prof = prof or 0
  local t = type(v)
  if t == "string" then return string.format("%q", v) end
  if t ~= "table" then return tostring(v) end
  if prof >= 2 then return "{...}" end
  local ks = {}
  for k in pairs(v) do ks[#ks + 1] = k end
  table.sort(ks, function(a, b)
    if type(a) ~= type(b) then return type(a) < type(b) end
    if type(a) == "number" or type(a) == "string" then return a < b end
    return tostring(a) < tostring(b)
  end)
  local out = {}
  for i, k in ipairs(ks) do
    if i > 8 then out[#out + 1] = "..." break end
    out[#out + 1] = (type(k) == "number" and "" or (tostring(k) .. "=")) .. curto(v[k], prof + 1)
  end
  return "{" .. table.concat(out, ", ") .. "}"
end

local function igualProfundo(a, c, vistos)
  if a == c then return true end
  if type(a) ~= "table" or type(c) ~= "table" then return false end
  vistos = vistos or {}
  if vistos[a] == c then return true end
  vistos[a] = c
  for k, v in pairs(a) do if not igualProfundo(v, c[k], vistos) then return false end end
  for k in pairs(c) do if a[k] == nil then return false end end
  return true
end

local function falhar(msg)
  B.falhas[#B.falhas + 1] = msg
end

-- ---------------------------------------------------------------------------
-- A tabela b que o cenario recebe (contrato, secao 5 do ARQUITETURA.md)
-- ---------------------------------------------------------------------------
local b = {}
B.b = b
b.ns = nil
function b.db() return rawget(_G, "PregaoForeverDB") end
function b.tela() return b.ns and b.ns.__tela end
function b.contar(nome) return B.cont[nome] or 0 end
function b.chamadas(nome) return B.regs[nome] or {} end
function b.eventos(nome)
  if nome == nil then return B.ev end
  local out = {}
  for _, e in ipairs(B.ev) do if e.nome == nome then out[#out + 1] = e end end
  return out
end
function b.agora() return B.agora() end
function b.violacoes() return B.violacoes end
function b.erros() return B.erros end
function b.igual(obtido, esperado, msg)
  if igualProfundo(obtido, esperado) then return true end
  falhar(tostring(msg or "igual") .. ": esperado " .. curto(esperado) .. ", obtido " .. curto(obtido))
  return false
end
function b.verdadeiro(x, msg)
  if x then return true end
  falhar(tostring(msg or "verdadeiro") .. ": esperado verdadeiro, obtido " .. curto(x))
  return false
end
function b.falso(x, msg)
  if not x then return true end
  falhar(tostring(msg or "falso") .. ": esperado falso, obtido " .. curto(x))
  return false
end

-- ---------------------------------------------------------------------------
-- Carga do addon, SV e reload
-- ---------------------------------------------------------------------------
local function carregarAddon()
  local ns = {}
  B.ns = ns
  b.ns = ns
  for _, f in ipairs(__ADDON.arquivos) do
    local fn, err = load(f.texto, "=" .. f.nome, "t")
    if not fn then
      B.cargaFalhou[#B.cargaFalhou + 1] = f.nome .. ": " .. tostring(err)
      return false
    end
    local ok, e = xpcall(fn, function(m) return tostring(m) end, "PregaoForever", ns)
    if not ok then
      B.cargaFalhou[#B.cargaFalhou + 1] = f.nome .. ": " .. tostring(e)
      return false
    end
  end
  return true
end

local function ciclo(recarga)
  B.disparar("ADDON_LOADED", "PregaoForever")
  B.disparar("PLAYER_LOGIN")
  B.disparar("PLAYER_ENTERING_WORLD", not recarga, recarga)
end

local function recarregar()
  B.reloadPendente = false
  B.disparar("PLAYER_LOGOUT")
  local texto = B.serializarSV()
  B.cancelarTimersDoAddon()
  B.limparQuadrosDoAddon()
  B.limparGanchos()
  EventRegistry.callbacks = {}
  for k in pairs(SlashCmdList) do SlashCmdList[k] = nil end
  B.bindings = {}
  B.clique = nil
  for k in pairs(_G) do
    if not B.baseG[k] then _G[k] = nil end
  end
  local fn, err = load(texto, "=sv", "t")
  if not fn then error("SV serializado nao recarrega: " .. tostring(err), 0) end
  fn()
  if not carregarAddon() then error("addon nao recarregou: " .. B.cargaFalhou[#B.cargaFalhou], 0) end
  ciclo(true)
end

-- ---------------------------------------------------------------------------
-- Passos
-- ---------------------------------------------------------------------------
local PASSOS = {}

PASSOS.abrir_leilao = function() B.abrirLeilao() end
PASSOS.fechar_leilao = function() B.fecharLeilao() end
PASSOS.avancar = function(seg)
  if type(seg) ~= "number" or seg < 0 then error("avancar: segundos invalidos: " .. tostring(seg), 0) end
  B.rodarAte(B.agoraUs() + seg * 1000000.0)
end
PASSOS.ate_ocioso = function()
  local ini = B.agoraUs()
  while B.pendentes() do
    if B.agoraUs() - ini > 600 * 1000000.0 then error("ate_ocioso: ainda ha timer ou resposta pendente depois de 600 s", 0) end
    local prox = B.proximaHora()
    local alvo = B.agoraUs()
    if prox and prox > alvo then alvo = prox end
    B.rodarAte(alvo)
  end
end
PASSOS.tecla = function(x)
  local nome = "PregaoForeverTecla" .. tostring(x)
  local e = B.quadroPorNome(nome)
  if not e then error("tecla " .. tostring(x) .. ": o botao " .. nome .. " nao existe", 0) end
  B.ultimaTecla = B.agoraUs()
  if not e.desab then B.despacharClique(e, true) end
end
PASSOS.clique = function(nome)
  local e = B.quadroPorNome(nome)
  if not e then error("clique: o botao " .. tostring(nome) .. " nao existe", 0) end
  if not e.desab then B.despacharClique(e, string.sub(nome, 1, 13) == "PregaoForever") end
end
PASSOS.injetar = function(spec) B.injetar(spec) end
PASSOS.evento = function(spec)
  if type(spec) == "string" then spec = { spec } end
  B.disparar(unpack(spec, 1, spec.n or #spec))
end
PASSOS.reload = function() recarregar() end
PASSOS.salvar_sv = function(nome)
  if type(nome) ~= "string" or nome == "" then error("salvar_sv: precisa de um nome", 0) end
  B.saidas[#B.saidas + 1] = { nome = nome .. "-sv.lua", texto = B.serializarSV() }
end
PASSOS.chamar = function(fn)
  if type(fn) ~= "function" then error("chamar: precisa de uma funcao", 0) end
  fn(b)
end

local ORDEM = { "abrir_leilao", "fechar_leilao", "avancar", "ate_ocioso", "tecla", "clique", "injetar", "evento", "reload", "salvar_sv", "chamar" }

local function rodarPasso(p, i)
  if type(p) ~= "table" then error("passo " .. i .. " nao e tabela", 0) end
  for _, nome in ipairs(ORDEM) do
    if p[nome] ~= nil then
      PASSOS[nome](p[nome])
      if B.reloadPendente then recarregar() end
      return
    end
  end
  local ks = {}
  for k in pairs(p) do ks[#ks + 1] = tostring(k) end
  table.sort(ks)
  error("passo " .. i .. " desconhecido (chaves: " .. table.concat(ks, ",") .. ")", 0)
end

-- ---------------------------------------------------------------------------
-- JSON do resultado
-- ---------------------------------------------------------------------------
local function esc(s)
  s = string.gsub(s, "\\", "\\\\")
  s = string.gsub(s, "\"", "\\\"")
  s = string.gsub(s, "\n", "\\n")
  s = string.gsub(s, "\r", "\\r")
  s = string.gsub(s, "\t", "\\t")
  s = string.gsub(s, "[%z\1-\31]", function(c) return string.format("\\u%04x", string.byte(c)) end)
  return s
end
local function json(v)
  local t = type(v)
  if t == "nil" then return "null" end
  if t == "boolean" then return v and "true" or "false" end
  if t == "number" then return string.format("%.14g", v) end
  if t == "string" then return "\"" .. esc(v) .. "\"" end
  if t ~= "table" then return "null" end
  if v[1] ~= nil or next(v) == nil then
    local o = {}
    for i = 1, #v do o[i] = json(v[i]) end
    return "[" .. table.concat(o, ",") .. "]"
  end
  local o = {}
  for k, x in pairs(v) do o[#o + 1] = "\"" .. esc(tostring(k)) .. "\":" .. json(x) end
  table.sort(o)
  return "{" .. table.concat(o, ",") .. "}"
end

-- ---------------------------------------------------------------------------
-- Execucao de um cenario
-- ---------------------------------------------------------------------------
local function resultado(status, motivo, extra)
  local r = extra or {}
  r.status = status
  r.motivo = motivo
  r.saidas = B.saidas
  local ns_ = {}
  for k in pairs(B.naoSimuladas) do ns_[#ns_ + 1] = k end
  table.sort(ns_)
  r.nao_simuladas = ns_
  r.carga = B.cargaFalhou
  return json(r)
end

function B.rodar(textoCenario, nomeArquivo)
  local chunk, err = load(textoCenario, "=" .. nomeArquivo, "t")
  if not chunk then return resultado("cenario", "cenario nao compila: " .. tostring(err)) end
  local ok, c = pcall(chunk)
  if not ok then return resultado("cenario", "cenario deu erro ao carregar: " .. tostring(c)) end
  if type(c) ~= "table" or type(c.id) ~= "string" then return resultado("cenario", "o arquivo de cenario precisa devolver uma tabela com id") end
  local extra = { id = c.id, grupo = c.grupo, esperado_falha = c.esperado_falha }

  local ok2, e2 = pcall(function()
    B.configurar(c.inicio)
    for k in pairs(_G) do B.baseG[k] = true end
    local ini = c.inicio or {}
    if ini.sv ~= nil then rawset(_G, "PregaoForeverDB", B.copiaProfunda(ini.sv)) end
    if ini.sv_char ~= nil then rawset(_G, "PregaoForeverCharDB", B.copiaProfunda(ini.sv_char)) end
  end)
  if not ok2 then return resultado("cenario", "estado inicial invalido: " .. tostring(e2), extra) end

  if not carregarAddon() then return resultado("carga", B.cargaFalhou[#B.cargaFalhou], extra) end
  local passosOk, passosErro = pcall(function()
    ciclo(false)
    for i, p in ipairs(c.passos or {}) do rodarPasso(p, i) end
  end)
  if #B.cargaFalhou > 0 then return resultado("carga", B.cargaFalhou[#B.cargaFalhou], extra) end
  if not passosOk then
    falhar("passo: " .. tostring(passosErro))
  elseif type(c.conferir) == "function" then
    local ok3, e3 = xpcall(c.conferir, function(m) return tostring(m) end, b)
    if not ok3 then falhar("conferir deu erro: " .. tostring(e3)) end
  end
  if #B.erros > 0 and not c.aceita_erros then
    falhar("erro de Lua capturado (" .. #B.erros .. "): " .. B.erros[1])
  end
  if #B.violacoes > 0 and not c.aceita_violacoes then
    local v = B.violacoes[1]
    falhar("violacao " .. v.tipo .. " (" .. #B.violacoes .. "): " .. v.msg)
  end
  if #B.falhas > 0 then
    extra.falhas = B.falhas
    return resultado("falha", B.falhas[1] .. (#B.falhas > 1 and (" (+" .. (#B.falhas - 1) .. " falha(s))") or ""), extra)
  end
  return resultado("ok", nil, extra)
end

function B.listaDeInjecoes() return table.concat(B.nomesDeInjecao(), ", ") end
