-- CentralForever/Ameaca.lua: decide o estado do threat (modos dps e tanque) e devolve a "visao" que o
-- Painel desenha. Nao toca em widget. Todo valor de combate chega por ns.segredo como caixa
-- ({ cru, s, tem, n }); aqui se decide so com os campos s, tem e n. Contrato: CONTRATO.md, secoes 3.6 e 6.
-- Regras: Lua 5.1, so ASCII, texto do jogo em ingles (vem do Config), nenhuma global nova.
local _, ns = ...

ns.ameaca = ns.ameaca or {}
local A = ns.ameaca

-- ---------------------------------------------------------------------------
-- Estado do modulo
-- ---------------------------------------------------------------------------

local nomeJog, classeJog          -- lidos uma vez
local tevePet = false             -- teve pet nesta luta
local unidadesVivas = {}          -- unidades de cfg.threat.unidades que existem
local listaFeita = false
local ultimoAlvo = nil            -- hora da ultima troca de alvo
local ultimoPulso = nil           -- hora do ultimo pulso
local mostrado = nil              -- estado hoje mostrado (com histerese)
local candAnt = nil               -- ultimo candidato visto
local candDesde = 0               -- desde quando o candidato e o mesmo
local semDesde = nil              -- desde quando nao ha o que dizer
local sondado = false             -- as sondas da primeira leitura ja foram ao diario

-- prioridade de cada estado (para piorar na hora e melhorar so depois de estavel)
local NIVEL = {
  NEUTRO = 0, SAFE = 1, HELD = 1, CLOSE = 2, SLIPPING = 2,
  HIGH = 3, LOOSE = 3, ON_YOU = 4, LOST = 4,
}
-- estados que pulsam ao entrar
local PULSA = { HIGH = true, ON_YOU = true, SLIPPING = true, LOOSE = true, LOST = true }

-- padroes de codigo para chave ausente no Config
local PALAVRAS_PADRAO = {
  SAFE = "SAFE", CLOSE = "CLOSE", HIGH = "HIGH", ON_YOU = "ON YOU",
  HELD = "HELD", SLIPPING = "SLIPPING", LOOSE = "LOOSE", LOST = "LOST",
  NEUTRO = "THREAT",
}
local LIMIARES_PADRAO = {
  perto = { entra = 80, sai = 75 },
  alto = { entra = 95, sai = 90 },
  desafiante = { entra = 80, sai = 75 },
}
local UNIDADES_PADRAO = { "pet", "party1", "party2", "party3", "party4",
                          "partypet1", "partypet2", "partypet3", "partypet4" }

-- ---------------------------------------------------------------------------
-- Apoio
-- ---------------------------------------------------------------------------

local function th()
  local c = ns.cfg
  if type(c) == "table" and type(c.threat) == "table" then
    return c.threat
  end
  return {}
end

local function numCfg(chave, padrao)
  local v = th()[chave]
  if type(v) == "number" then
    return v
  end
  return padrao
end

local function textoVazio()
  local c = ns.cfg
  if type(c) == "table" and type(c.vazio) == "string" then
    return c.vazio
  end
  return "--"
end

local function textoOutro()
  local v = th().outro
  if type(v) == "string" then
    return v
  end
  return "other"
end

local function palavraDe(estado)
  local p = th().palavras
  if type(p) == "table" and type(p[estado]) == "string" then
    return p[estado]
  end
  return PALAVRAS_PADRAO[estado] or textoVazio()
end

-- caixa de um valor (sem ns.segredo, nada e lido)
local function caixaDe(v)
  local S = ns.segredo
  if S and S.caixa then
    return S.caixa(v)
  end
  return { cru = nil, s = true, tem = false, n = nil }
end

local function caixaVazia()
  return { cru = nil, s = false, tem = false, n = nil }
end

-- o numero legivel da caixa, ou nil
local function numero(caixa)
  if type(caixa) == "table" and type(caixa.n) == "number" then
    return caixa.n
  end
  return nil
end

local function ehAlto(n)
  return n == 2 or n == 3
end

-- chama uma funcao do jogo que devolve booleano; passa o retorno por caixa e usa so n
local function booleano(fn, ...)
  if type(fn) ~= "function" then
    return false
  end
  local ok, v = pcall(fn, ...)
  if not ok then
    return false
  end
  return caixaDe(v).n == true
end

local function existe(unidade)
  return booleano(UnitExists, unidade)
end

local function alvoHostil()
  if not existe("target") then
    return false
  end
  if not booleano(UnitCanAttack, "player", "target") then
    return false
  end
  if booleano(UnitIsDeadOrGhost, "target") then
    return false
  end
  return true
end

local function emGrupo()
  return booleano(IsInGroup)
end

-- corta em max caracteres sem partir uma sequencia UTF-8
local function cortar(s, max)
  local i = 1
  local n = 0
  local tam = string.len(s)
  while i <= tam and n < max do
    local b = string.byte(s, i)
    local len = 1
    if b >= 240 then
      len = 4
    elseif b >= 224 then
      len = 3
    elseif b >= 192 then
      len = 2
    end
    i = i + len
    n = n + 1
  end
  return string.sub(s, 1, i - 1)
end

-- nome legivel da unidade, cortado em cfg.threat.nomeMax; nil se nao for legivel
local function nomeCurto(unidade)
  local S = ns.segredo
  if not S or not S.nome then
    return nil
  end
  local c = S.nome(unidade)
  if type(c.n) == "string" and c.n ~= "" then
    return cortar(c.n, numCfg("nomeMax", 7))
  end
  return nil
end

-- limiar de entrada ou de saida; usa o de saida se o estado mostrado esta na lista
local function limiar(nome, estadosSai)
  local t = th()[nome]
  local pad = LIMIARES_PADRAO[nome]
  local entra = pad.entra
  local sai = pad.sai
  if type(t) == "table" then
    if type(t.entra) == "number" then
      entra = t.entra
    end
    if type(t.sai) == "number" then
      sai = t.sai
    end
  end
  for _, e in ipairs(estadosSai) do
    if mostrado == e then
      return sai
    end
  end
  return entra
end

local function marca(grupo, campo, valor)
  if ns.diario and ns.diario.marca then
    pcall(ns.diario.marca, grupo, campo, valor)
  end
end

-- zera so a memoria da histerese (semDesde fica: o prazo sem alvo continua correndo)
local function zerarHisterese()
  mostrado = nil
  candAnt = nil
  candDesde = 0
end

-- ---------------------------------------------------------------------------
-- Papel
-- ---------------------------------------------------------------------------

local function lerIdentidade()
  if not nomeJog and UnitName then
    local ok, v = pcall(UnitName, "player")
    if ok then
      local c = caixaDe(v)
      if type(c.n) == "string" and c.n ~= "" then
        nomeJog = c.n
      end
    end
  end
  if not classeJog and UnitClass then
    local ok, _, token = pcall(UnitClass, "player")
    if ok then
      local c = caixaDe(token)
      if type(c.n) == "string" and c.n ~= "" then
        classeJog = c.n
      end
    end
  end
end

local function papelValido(p)
  return p == "dps" or p == "tanque"
end

function A.papel()
  lerIdentidade()
  local c = ns.cfg
  if type(c) ~= "table" then
    return "dps"
  end
  local p = nil
  if nomeJog and type(c.papel) == "table" then
    p = c.papel[nomeJog]
  end
  if not papelValido(p) and classeJog and type(c.papelClasse) == "table" then
    p = c.papelClasse[classeJog]
  end
  if not papelValido(p) then
    p = c.papelPadrao
  end
  if papelValido(p) then
    return p
  end
  return "dps"
end

-- ---------------------------------------------------------------------------
-- Luta, alvo e grupo
-- ---------------------------------------------------------------------------

function A.aoGrupo()
  local lista = {}
  local us = th().unidades
  if type(us) ~= "table" then
    us = UNIDADES_PADRAO
  end
  for _, u in ipairs(us) do
    if type(u) == "string" and existe(u) then
      lista[#lista + 1] = u
    end
  end
  unidadesVivas = lista
  listaFeita = true
  if existe("pet") then
    tevePet = true
  end
end

function A.aoEntrar(agora)
  zerarHisterese()
  semDesde = nil
  ultimoPulso = nil
  sondado = false
  tevePet = false
  A.aoGrupo()
end

function A.aoSair()
  zerarHisterese()
  semDesde = nil
  ultimoPulso = nil
  sondado = false
  tevePet = false
end

function A.aoAlvo(agora)
  -- alvo novo: o estado mostrado era do alvo antigo e nao vale mais (sem espera para "melhorar")
  zerarHisterese()
  if type(agora) == "number" then
    ultimoAlvo = agora
  elseif GetTime then
    local ok, t = pcall(GetTime)
    if ok and type(t) == "number" then
      ultimoAlvo = t
    end
  end
end

-- ---------------------------------------------------------------------------
-- Decisao do modo dps
-- ---------------------------------------------------------------------------

-- L = { eAlvo, det, geral, lider() }. Devolve o candidato e as partes da visao.
local function decidirDps(L, tAlvo)
  local pct = L.det.pct
  local pn = numero(pct)
  local barra = nil
  if pct.tem then
    barra = pct
  end
  local function linhaPct()
    if pct.tem then
      return { modo = "pct", caixa = pct }
    end
    return { modo = "texto", texto = textoVazio() }
  end

  -- estado do alvo secreto: nada se decide
  if tAlvo and L.eAlvo.s then
    local p = { linha2 = linhaPct(), barra = barra, legivel = false, algo = false }
    if L.det.tanque.tem then
      p.onYou = L.det.tanque
    end
    return "NEUTRO", p
  end

  local ea = nil
  if tAlvo then
    ea = numero(L.eAlvo)
  end
  local algo = ehAlto(numero(L.geral))

  if ehAlto(ea) then
    return "ON_YOU", { linha2 = linhaPct(), barra = barra, legivel = true, algo = algo }
  end
  if algo then
    return "ON_YOU", { linha2 = { modo = "texto", texto = textoOutro() }, barra = barra, legivel = true, algo = algo }
  end
  if ea == 1 or (pn and pn >= limiar("alto", { "HIGH" })) then
    return "HIGH", { linha2 = linhaPct(), barra = barra, legivel = true, algo = algo }
  end
  if pn and pn >= limiar("perto", { "CLOSE", "HIGH" }) then
    return "CLOSE", { linha2 = linhaPct(), barra = barra, legivel = true, algo = algo }
  end
  return "SAFE", { linha2 = linhaPct(), barra = barra, legivel = true, algo = algo }
end

-- ---------------------------------------------------------------------------
-- Decisao do modo tanque
-- ---------------------------------------------------------------------------

local function decidirTanque(L, tAlvo)
  local S = ns.segredo
  local pct = L.det.pct

  if tAlvo and L.eAlvo.s then
    local p = { linha2 = { modo = "nada" }, legivel = false, algo = false }
    if pct.tem then
      p.linha2 = { modo = "pct", caixa = pct }
      p.barra = pct
    end
    if L.det.tanque.tem then
      p.onYou = L.det.tanque
    end
    return "NEUTRO", p
  end

  local ea = nil
  if tAlvo then
    ea = numero(L.eAlvo)
  end

  -- varredura das unidades que existem
  local solto = nil
  local segurador = nil
  local desafios = {}
  for _, u in ipairs(unidadesVivas) do
    local gn = numero(S.estado(u, nil))
    if solto == nil and ehAlto(gn) then
      solto = u
    end
    if tAlvo then
      local d = S.detalhe(u, "target")
      if d.veio then
        desafios[#desafios + 1] = { u = u, pct = d.pct }
        if segurador == nil and d.tanque.n == true then
          segurador = u
        end
      end
    end
  end

  -- maior desafiante: so quando todas as porcentagens lidas sao legiveis
  local maior = nil
  local maiorU = nil
  local maiorCaixa = nil
  local primeiroSecreto = nil
  local todosLegiveis = true
  for i = 1, #desafios do
    local pc = desafios[i].pct
    if pc.tem then
      if pc.s then
        todosLegiveis = false
        if primeiroSecreto == nil then
          primeiroSecreto = pc
        end
      else
        local n = numero(pc)
        if n and (maior == nil or n > maior) then
          maior = n
          maiorCaixa = pc
          maiorU = desafios[i].u
        end
      end
    end
  end
  if not todosLegiveis then
    maior = nil
    maiorCaixa = nil
    maiorU = nil
  end
  -- com alguma porcentagem secreta nao se sabe quem e o maior: nao se mostra a de uma unidade qualquer
  local caixaBarra = maiorCaixa

  -- linha 2 do desafiante: nome e porcentagem, so a porcentagem, ou nada
  local function linhaDesafiante()
    if maior ~= nil then
      local nome = nomeCurto(maiorU)
      if nome then
        return { modo = "texto", texto = string.format("%s %d%%", nome, math.floor(maior + 0.5)) }
      end
      return { modo = "pct", caixa = maiorCaixa }
    end
    return { modo = "nada" }
  end

  local algo = solto ~= nil

  if ea == 0 or ea == 1 then
    local p = { linha2 = { modo = "nada" }, legivel = true, algo = algo }
    if segurador then
      local nome = nomeCurto(segurador)
      if nome then
        p.linha2 = { modo = "texto", texto = nome }
      end
    end
    if pct.tem then
      p.barra = pct
    end
    return "LOST", p
  end

  if solto ~= nil then
    local p = { linha2 = { modo = "nada" }, barra = caixaBarra, legivel = true, algo = algo }
    local nome = nomeCurto(solto)
    if nome then
      p.linha2 = { modo = "texto", texto = nome }
    end
    return "LOOSE", p
  end

  if ea == 2 or ea == 3 then
    local desliza = false
    if ea == 2 then
      desliza = true
    elseif maior ~= nil and maior >= limiar("desafiante", { "SLIPPING" }) then
      desliza = true
    elseif maior == nil and th().usarLider ~= false then
      local ld = numero(L.lider())
      if ld ~= nil and ld >= numCfg("liderSlipping", 2) then
        desliza = true
      end
    end
    local p = { linha2 = linhaDesafiante(), barra = caixaBarra, legivel = true, algo = algo }
    if desliza then
      return "SLIPPING", p
    end
    return "HELD", p
  end

  -- alvo hostil sem entrada na tabela de threat (ou sem alvo): nada a mostrar
  return "SAFE", { linha2 = { modo = "nada" }, legivel = true, algo = algo, palavraVazia = true }
end

-- ---------------------------------------------------------------------------
-- Leitura e visao
-- ---------------------------------------------------------------------------

local function visaoOculta(papel)
  return {
    visivel = false,
    papel = papel,
    estado = "NEUTRO",
    palavra = textoVazio(),
    linha2 = { modo = "nada" },
    barra = nil,
    onYou = nil,
    pulso = false,
  }
end

-- le o que o modo precisa. lider() e preguicoso e guarda o resultado.
local function ler(tAlvo)
  local S = ns.segredo
  local L = { eAlvo = caixaVazia(), det = { veio = false, tanque = caixaVazia(), pct = caixaVazia() } }
  L.geral = S.estado("player", nil)
  if tAlvo then
    L.eAlvo = S.estado("player", "target")
    L.det = S.detalhe("player", "target")
  end
  local liderCache = nil
  L.lider = function()
    if liderCache == nil then
      if tAlvo and S.lider then
        liderCache = S.lider("player", "target")
      else
        liderCache = caixaVazia()
      end
    end
    return liderCache
  end
  return L
end

-- sondas da primeira leitura da luta com alvo hostil
local function sondar(L, contexto)
  local S = ns.segredo
  marca("ameaca", "estado", S.tipo(L.eAlvo))
  marca("ameaca", "pct", S.tipo(L.det.pct))
  marca("ameaca", "tanque", S.tipo(L.det.tanque))
  marca("ameaca", "geral", S.tipo(L.geral))
  marca("ameaca", "lider", S.tipo(L.lider()))
  marca("ameaca", "veio", L.det.veio == true)
  marca("ameaca", "soloSemPet", not contexto)
  if UnitIsBossMob then
    local ok, v = pcall(UnitIsBossMob, "target")
    if ok then
      local c = caixaDe(v)
      if type(c.n) == "boolean" then
        marca("ameaca", "chefe", c.n)
      end
    end
  end
end

-- aplica a histerese: devolve true se subiu de prioridade (ou e o primeiro) nesta chamada
local function histerese(cand, agora)
  if mostrado == nil then
    mostrado = cand
    candAnt = cand
    candDesde = agora
    return true
  end
  if cand ~= candAnt then
    candAnt = cand
    candDesde = agora
  end
  local nc = NIVEL[cand] or 0
  local nm = NIVEL[mostrado] or 0
  if nc > nm then
    mostrado = cand
    return true
  end
  if nc == nm then
    mostrado = cand
    return false
  end
  if agora - candDesde >= numCfg("melhoraSeg", 1.0) then
    mostrado = cand
  end
  return false
end

function A.atualizar(agora)
  if type(agora) ~= "number" then
    agora = 0
  end
  local papel = A.papel()
  local S = ns.segredo
  if not S or not S.estado or not S.detalhe then
    return visaoOculta(papel)
  end
  if not listaFeita then
    A.aoGrupo()
  end

  local temPet = existe("pet")
  local contexto = emGrupo() or temPet or tevePet
  local tAlvo = alvoHostil()

  -- solo sem pet: o cartao nunca aparece; so a primeira leitura vai ao diario
  if not contexto then
    if tAlvo and not sondado then
      sondado = true
      pcall(sondar, ler(tAlvo), contexto)
    end
    zerarHisterese()
    semDesde = nil
    return visaoOculta(papel)
  end

  local L = ler(tAlvo)
  local cand, partes
  if papel == "tanque" then
    cand, partes = decidirTanque(L, tAlvo)
  else
    cand, partes = decidirDps(L, tAlvo)
  end

  if tAlvo and not sondado then
    sondado = true
    pcall(sondar, L, contexto)
  end

  -- tem o que dizer? senao, depois de semAlvoSeg o cartao some
  local visivel = true
  if tAlvo or partes.algo then
    semDesde = nil
  else
    if semDesde == nil then
      semDesde = agora
    end
    if agora - semDesde >= numCfg("semAlvoSeg", 2) then
      visivel = false
    end
  end
  if not visivel then
    zerarHisterese()
    return visaoOculta(papel)
  end

  local subiu = histerese(cand, agora)

  local pulso = false
  if subiu and PULSA[mostrado] and partes.legivel then
    local aposAlvo = numCfg("pulsoAposAlvoSeg", 0.5)
    local minimo = numCfg("pulsoMinSeg", 8)
    if (ultimoAlvo == nil or agora - ultimoAlvo >= aposAlvo)
      and (ultimoPulso == nil or agora - ultimoPulso >= minimo) then
      pulso = true
      ultimoPulso = agora
    end
  end

  local palavra = palavraDe(mostrado)
  if mostrado == cand and partes.palavraVazia then
    palavra = textoVazio()
  end
  local onYou = nil
  if mostrado == "NEUTRO" and cand == "NEUTRO" then
    onYou = partes.onYou
  end

  return {
    visivel = true,
    papel = papel,
    estado = mostrado,
    palavra = palavra,
    linha2 = partes.linha2,
    barra = partes.barra,
    onYou = onYou,
    pulso = pulso,
  }
end
