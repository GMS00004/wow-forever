-- CentralForever/Medidor.lua: DPS, dano da luta, dano acumulado, cronometro e o resumo depois da luta.
-- Os numeros de combate chegam como caixas ({ cru, s, tem, n }) por ns.segredo e vao aos campos do
-- painel pelos ralos; aqui so se decide com s, tem e n. Contrato: CONTRATO.md, secoes 3.5, 7 e 10.
-- Regras: Lua 5.1, so ASCII, texto do jogo em ingles, nenhuma global nova.
local _, ns = ...

ns.medidor = ns.medidor or {}
local M = ns.medidor

-- ---------------------------------------------------------------------------
-- Estado
-- ---------------------------------------------------------------------------

local inicio = nil        -- relogio proprio: hora em que a luta comecou
local temLinha = false    -- a linha do jogador apareceu alguma vez nesta luta
local sondado = false     -- as sondas da primeira leitura com linha ja foram ao diario
local sessaoMarcada = false
local geracao = 0         -- invalida tentativas de captura pendentes

-- ---------------------------------------------------------------------------
-- Apoio
-- ---------------------------------------------------------------------------

local function sub(nome)
  local c = ns.cfg
  if type(c) == "table" and type(c[nome]) == "table" then
    return c[nome]
  end
  return {}
end

local function textoVazio()
  local c = ns.cfg
  if type(c) == "table" and type(c.vazio) == "string" then
    return c.vazio
  end
  return "--"
end

local function textoTempoZero()
  local c = ns.cfg
  if type(c) == "table" and type(c.tempoZero) == "string" then
    return c.tempoZero
  end
  return "0:00"
end

local function formatoDe(campo, padrao)
  local f = sub("formato")[campo]
  if f == "inteiro" or f == "abrev" then
    return f
  end
  return padrao
end

local function idSessao(nome, padrao)
  local e = ns.enum
  if type(e) == "table" and type(e.sessao) == "table" and type(e.sessao[nome]) == "number" then
    return e.sessao[nome]
  end
  return padrao
end

-- marca no diario (guardado; o diario so aceita valores simples)
local function marca(grupo, campo, valor)
  if ns.diario and ns.diario.marca then
    pcall(ns.diario.marca, grupo, campo, valor)
  end
end

local function campo(nome)
  if ns.painel and ns.painel.campo then
    return ns.painel.campo(nome)
  end
  return nil
end

local function texto(nome, t)
  if ns.painel and ns.painel.texto then
    ns.painel.texto(nome, t)
  end
end

-- numero legivel (a caixa so entra aqui pelo campo n)
local function numeroDe(caixa)
  if type(caixa) == "table" and type(caixa.n) == "number" then
    return caixa.n
  end
  return nil
end

-- segundos legiveis em texto m:ss
local function formatarTempo(seg)
  if type(seg) ~= "number" or seg < 0 then
    seg = 0
  end
  seg = math.floor(seg)
  return string.format("%d:%02d", math.floor(seg / 60), seg % 60)
end

local function agoraDe(agora)
  if type(agora) == "number" then
    return agora
  end
  if GetTime then
    local ok, t = pcall(GetTime)
    if ok and type(t) == "number" then
      return t
    end
  end
  return 0
end

-- ---------------------------------------------------------------------------
-- Luta
-- ---------------------------------------------------------------------------

function M.aoEntrar(agora)
  geracao = geracao + 1
  temLinha = false
  sondado = false
  sessaoMarcada = false
  inicio = agoraDe(agora)
  texto("dps", "0")
  texto("luta", "0")
  texto("tempo", textoTempoZero())
end

-- sondas da primeira leitura da luta (o diario guarda so o primeiro valor de cada campo)
local function sondar(cur, ov)
  local S = ns.segredo
  if not sessaoMarcada then
    sessaoMarcada = true
    marca("dano", "sessao", cur.motivo)
  end
  if type(cur.fontes) == "number" then
    marca(nil, "fontes", cur.fontes)
  end
  if sondado or not cur.linha then
    return
  end
  sondado = true
  marca("dano", "linha", true)
  marca("dano", "dps", S.tipo(cur.dps))
  marca("dano", "total", S.tipo(cur.total))
  marca("dano", "geral", S.tipo(ov.total))
  marca("dano", "duracao", S.tipo(S.duracao(idSessao("Current", 1))))
end

function M.atualizar()
  local S = ns.segredo
  if not S or not S.sessao or not S.mostrarNumero then
    return { linha = false }
  end
  local cur = S.sessao(idSessao("Current", 1))
  local ov = S.sessao(idSessao("Overall", 0))
  if cur.linha then
    temLinha = true
  end

  -- sem linha mas com sessao lida: deixa o zero do inicio da luta; sessao ilegivel: vazio
  if cur.linha or not cur.ok then
    S.mostrarNumero(campo("dps"), cur.dps, formatoDe("dps", "inteiro"))
    S.mostrarNumero(campo("luta"), cur.total, formatoDe("luta", "abrev"))
  end
  if ov.linha or not ov.ok then
    S.mostrarNumero(campo("total"), ov.total, formatoDe("total", "abrev"))
  end

  local ok = pcall(sondar, cur, ov)
  if not ok and ns.falhou then
    pcall(ns.falhou, "sondas", "medidor")
  end
  return { linha = cur.linha == true }
end

function M.tempo(agora)
  local S = ns.segredo
  local seg = nil
  if S and S.duracao then
    seg = numeroDe(S.duracao(idSessao("Current", 1)))
  end
  if seg == nil and inicio ~= nil then
    seg = agoraDe(agora) - inicio
  end
  texto("tempo", formatarTempo(seg))
end

-- ---------------------------------------------------------------------------
-- Captura do resumo
-- ---------------------------------------------------------------------------

-- uma tentativa: devolve a tabela do resumo (sem o campo quando) e a fonte, ou nil
local function tentar(duracaoRelogio)
  local S = ns.segredo
  if not S or not S.sessao then
    return nil, "nenhuma"
  end
  local fonte = "current"
  local idFonte = idSessao("Current", 1)
  local sessao = S.sessao(idFonte)
  if not sessao.linha then
    fonte = "expired"
    idFonte = idSessao("Expired", 2)
    sessao = S.sessao(idFonte)
  end
  if not sessao.linha then
    return nil, "nenhuma"
  end
  local dps = numeroDe(sessao.dps)
  local luta = numeroDe(sessao.total)
  if dps == nil or luta == nil then
    return nil, "nenhuma"
  end
  local geral = numeroDe(S.sessao(idSessao("Overall", 0)).total)
  local dur = numeroDe(S.duracao(idFonte))
  if dur == nil then
    dur = duracaoRelogio
  end
  if type(dur) == "number" then
    dur = math.floor(dur + 0.5)
  end
  local r = { dps = dps, luta = luta, total = geral, dur = dur, quando = date("%Y-%m-%d %H:%M:%S") }
  return r, fonte
end

function M.aoSair(agora, feito)
  geracao = geracao + 1
  local minha = geracao
  local r = sub("resumo")
  local carencia = type(r.carenciaSeg) == "number" and r.carenciaSeg or 1.0
  local maximo = type(r.tentativas) == "number" and r.tentativas or 8
  local intervalo = type(r.intervaloSeg) == "number" and r.intervaloSeg or 0.2
  local duracaoRelogio = nil
  if inicio ~= nil then
    duracaoRelogio = agoraDe(agora) - inicio
  end
  local feitas = 0

  local function terminar(ok, fonte)
    marca("dano", "linha", temLinha)
    marca("resumo", "ok", ok)
    marca("resumo", "tentativas", feitas)
    marca("resumo", "fonte", fonte)
    if type(feito) == "function" then
      feito(ok)
    end
  end

  local passo
  passo = function()
    if minha ~= geracao then
      return
    end
    feitas = feitas + 1
    local res, fonte = tentar(duracaoRelogio)
    if res then
      local p = ns.dbPersonagem and ns.dbPersonagem() or nil
      if type(p) == "table" then
        p.ultima = res
      end
      terminar(true, fonte)
    elseif feitas >= maximo then
      terminar(false, "nenhuma")
    else
      ns.depois(intervalo, passo)
    end
  end

  ns.depois(carencia, passo)
end

function M.cancelarCaptura()
  geracao = geracao + 1
end

-- ---------------------------------------------------------------------------
-- Resumo guardado
-- ---------------------------------------------------------------------------

function M.mostrarResumo()
  local S = ns.segredo
  local u = nil
  if ns.dbPersonagem then
    local p = ns.dbPersonagem()
    if type(p) == "table" and type(p.ultima) == "table" then
      u = p.ultima
    end
  end
  if u == nil then
    texto("dps", textoVazio())
    texto("luta", textoVazio())
    texto("total", textoVazio())
    texto("tempo", textoVazio())
    return
  end
  if S and S.caixa and S.mostrarNumero then
    S.mostrarNumero(campo("dps"), S.caixa(u.dps), formatoDe("dps", "inteiro"))
    S.mostrarNumero(campo("luta"), S.caixa(u.luta), formatoDe("luta", "abrev"))
    S.mostrarNumero(campo("total"), S.caixa(u.total), formatoDe("total", "abrev"))
  end
  if type(u.dur) == "number" then
    texto("tempo", formatarTempo(u.dur))
  else
    texto("tempo", textoVazio())
  end
end

function M.temLinha()
  return temLinha == true
end
