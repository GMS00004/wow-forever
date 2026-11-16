-- Nucleo.lua (PregaoForever): ns, ns.seguro, eventos, os tres relogios da regra 15, cobre inteiro, aneis,
-- log de 60 linhas, fatiador de 2 ms, faixa de estado e bandeira suja. Publica direto em ns.
-- Contrato: ARQUITETURA.md, secao 3.1. Nenhuma funcao aqui chama funcao de acao nem de consulta.
local _, ns = ...
ns.NOME = "PregaoForever"
ns.VERSAO = "0.1.0"

-- ---------- embrulho de erro (regra 3): mesma pilha, sem timer ----------
function ns.seguro(fn)
  return function(...)
    return xpcall(fn, geterrorhandler(), ...)
  end
end

-- ---------- eventos: um quadro escondido so do Nucleo ----------
local quadro = CreateFrame("Frame")
local tratadores = {}

local function despacho(_, evento, ...)
  local lista = tratadores[evento]
  if not lista then return end
  for i = 1, #lista do
    lista[i](evento, ...)
  end
end
quadro:SetScript("OnEvent", ns.seguro(despacho))

-- fn recebe (evento, ...). Varios fn por evento, na ordem de registro; cada um no seu xpcall.
function ns.ao(evento, fn)
  local lista = tratadores[evento]
  if not lista then
    lista = {}
    tratadores[evento] = lista
    pcall(quadro.RegisterEvent, quadro, evento)
  end
  lista[#lista + 1] = ns.seguro(fn)
end

function ns.depois(seg, fn)
  C_Timer.After(seg, ns.seguro(fn))
end

-- ---------- relogios (regra 15) ----------
function ns.servidor() return GetServerTime() end
function ns.mono() return GetTime() end
function ns.fino()
  if GetTimePreciseSec then return GetTimePreciseSec() end
  if debugprofilestop then return debugprofilestop() / 1000 end
  return nil
end

function ns.diaMercado(t)
  return math.floor(t / 86400)
end

-- dia de risco: data local com virada na hora do Config (6 de partida). Unica leitura da hora local.
function ns.diaRisco()
  local hora = 6
  if ns.cfg and ns.cfg.disjuntores and ns.cfg.disjuntores.dia_risco_hora then
    hora = ns.cfg.disjuntores.dia_risco_hora
  end
  local agora = GetServerTime()
  local d = date('*t', agora)
  if d.hour < hora then
    d = date('*t', agora - 86400)
  end
  return string.format('%04d-%02d-%02d', d.year, d.month, d.day)
end

-- ---------- numeros e dinheiro (regra 14 e 17) ----------
function ns.int(x) return math.floor(x) end
function ns.txt(x) return string.format('%d', math.floor(x)) end

function ns.dinheiro(c)
  c = math.floor(c or 0)
  local sinal = ''
  if c < 0 then
    sinal = '-'
    c = -c
  end
  local g = math.floor(c / 10000)
  local s = math.floor((c - g * 10000) / 100)
  local k = c - g * 10000 - s * 100
  local partes = {}
  if g > 0 then partes[#partes + 1] = string.format('%dg', g) end
  if s > 0 then partes[#partes + 1] = string.format('%ds', s) end
  if k > 0 or #partes == 0 then partes[#partes + 1] = string.format('%dc', k) end
  return sinal .. table.concat(partes, ' ')
end

-- ---------- aneis ----------
local Anel = {}
Anel.__index = Anel
function Anel:por(v)
  local d = self.dados
  d[#d + 1] = v
  if #d > self.max then table.remove(d, 1) end
end
function Anel:itens()
  local r = {}
  for i = 1, #self.dados do r[i] = self.dados[i] end
  return r
end
function Anel:tamanho() return #self.dados end

function ns.anel(max)
  return setmetatable({ max = max or 60, dados = {} }, Anel)
end

-- ---------- log de 60 linhas, no formato 1|t|nivel|texto (o Banco copia para o disco) ----------
ns.registro = ns.anel(60)
function ns.log(nivel, texto)
  local limpo = (string.gsub(tostring(texto or ''), '[|\r\n]', '/'))
  ns.registro:por('1|' .. ns.txt(GetServerTime()) .. '|' .. tostring(nivel or 'info') .. '|' .. limpo)
end

-- ---------- fatiador: trabalho pesado em fatias de cfg.fatia.ms ----------
-- Chama fn(i) para i = 1..n; fim() no fim. Devolve um objeto com :parar().
function ns.fatiar(n, fn, fim)
  local i = 1
  local parado = false
  local alca = {}
  function alca:parar() parado = true end
  local function passo()
    if parado then return end
    local cfg = (ns.cfg and ns.cfg.fatia) or {}
    local orcamento = (cfg.ms or 2) / 1000
    local maxLinhas = cfg.linhas or 500
    local t0 = ns.fino()
    local feitas = 0
    while i <= n do
      fn(i)
      i = i + 1
      feitas = feitas + 1
      if t0 then
        local dt = ns.fino() - t0
        if dt < 0 or dt >= orcamento then break end
      elseif feitas >= maxLinhas then
        break
      end
    end
    if parado then return end
    if i <= n then
      ns.depois(0, passo)
    elseif fim then
      fim()
    end
  end
  passo()
  return alca
end

-- ---------- jogo e personagem ----------
function ns.emCombate() return InCombatLockdown() and true or false end
function ns.msg(texto) print('|cff66ccffPregaoForever|r: ' .. tostring(texto)) end
function ns.pers() return (UnitName('player')) end
function ns.casa()
  return tostring(GetNormalizedRealmName() or '?') .. ':' .. tostring(UnitFactionGroup('player') or '?')
end

-- ---------- Config e modo ----------
function ns.configOk()
  return type(ns.cfg) == 'table' and ns.cfg.esquema == 1
end

function ns.modo()
  if not ns.configOk() then return 'leitura' end
  if ns.banco and ns.banco.carregado == false then return 'leitura' end
  return ns.cfg.modo or 'leitura'
end

-- ---------- bandeira suja: cada parte roda no maximo uma vez por quadro ----------
local sujas = {}
local ouvintes = {}
local agendado = false

local function limparSujas()
  agendado = false
  local partes = {}
  for p in pairs(sujas) do partes[#partes + 1] = p end
  table.sort(partes)
  sujas = {}
  for i = 1, #partes do
    local lista = ouvintes[partes[i]]
    if lista then
      for j = 1, #lista do lista[j](partes[i]) end
    end
  end
end

function ns.sujo(parte)
  sujas[parte or 'tela'] = true
  if not agendado then
    agendado = true
    ns.depois(0, limparSujas)
  end
end

function ns.aoSujo(parte, fn)
  local lista = ouvintes[parte]
  if not lista then
    lista = {}
    ouvintes[parte] = lista
  end
  lista[#lista + 1] = ns.seguro(fn)
end

-- ---------- faixa de estado: a de maior prioridade fica em ns.faixa ----------
-- pausa e held antes de reconciliar: com as teclas paradas nem o L responde, e o dono precisa ver por que
local ORDEM_FAIXA = { 'config', 'banco', 'restricao', 'travado', 'pausa', 'held', 'reconciliar' }
local faixas = {}

function ns.marcarFaixa(nome, texto)
  faixas[nome] = texto
  ns.faixa = nil
  for i = 1, #ORDEM_FAIXA do
    local f = faixas[ORDEM_FAIXA[i]]
    if f then
      ns.faixa = f
      break
    end
  end
  if not ns.faixa then
    local nomes = {}
    for k in pairs(faixas) do nomes[#nomes + 1] = k end
    table.sort(nomes)
    for i = 1, #nomes do
      if faixas[nomes[i]] then
        ns.faixa = faixas[nomes[i]]
        break
      end
    end
  end
  ns.sujo('tela')
end

function ns.faixaLigada(nome)
  return faixas[nome] ~= nil
end
