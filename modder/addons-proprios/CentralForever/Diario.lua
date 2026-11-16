-- CentralForever/Diario.lua: diario de sondas em CentralForeverDB.diario (carga, lutas,
-- entradas avulsas). Nunca recebe caixa nem valor secreto: so S.tipo(caixa), booleanos,
-- numeros legiveis e textos do addon. Contrato: CONTRATO.md, secoes 3.4 e 10.
local _, ns = ...

ns.diario = ns.diario or {}
local D = ns.diario

local atual -- registro da luta em andamento
local cargaFeita = false

local function ligado()
  local s = ns.cfg and ns.cfg.sondas
  if s and s.ligado == false then return false end
  return true
end

local function legivel(v)
  if issecretvalue then
    local ok, s = pcall(issecretvalue, v)
    if ok and s then return false end
  end
  return true
end

-- valor simples e legivel (boolean, number ou string)
local function simples(v)
  local t = type(v)
  if t ~= "boolean" and t ~= "number" and t ~= "string" then return false end
  return legivel(v)
end

local function quando()
  return date("%Y-%m-%d %H:%M:%S")
end

local function empurra(lista, item, max)
  lista[#lista + 1] = item
  while #lista > max do table.remove(lista, 1) end
end

-- banco do diario, so depois do ADDON_LOADED
local function dia()
  if not ns.pronto or not ns.db then return nil end
  return ns.db().diario
end

-- copia so valores simples (e subtabelas de um nivel) de src para dst
local function mescla(dst, src)
  if type(src) ~= "table" then return end
  for k, v in pairs(src) do
    if type(k) == "string" then
      if simples(v) then
        dst[k] = v
      elseif type(v) == "table" and legivel(v) then
        local sub = type(dst[k]) == "table" and dst[k] or {}
        for k2, v2 in pairs(v) do
          if type(k2) == "string" and simples(v2) then sub[k2] = v2 end
        end
        dst[k] = sub
      end
    end
  end
end

local function texto(v)
  if type(v) == "string" and legivel(v) then return v end
  return nil
end

local function chamar(fn, ...)
  if type(fn) ~= "function" then return false end
  return pcall(fn, ...)
end

-- ---------------------------------------------------------------------------
-- Entradas avulsas
-- ---------------------------------------------------------------------------

function D.anota(tipo, t)
  if not ligado() then return end
  local d = dia()
  if not d then return end
  local e = { quando = quando(), pers = ns.chave() }
  mescla(e, t)
  e.tipo = tostring(tipo)
  local max = (ns.cfg.sondas or {}).maxEntradas or 300
  empurra(d.avulsas, e, max)
end

-- ---------------------------------------------------------------------------
-- Luta
-- ---------------------------------------------------------------------------

function D.abrirLuta(t)
  if not ligado() then return end
  if not dia() then return end
  local r = { quando = quando(), pers = ns.chave() }
  local ok, zona = chamar(GetZoneText)
  r.zona = (ok and texto(zona)) or "?"
  local ok2, inst = chamar(IsInInstance)
  r.instancia = (ok2 and inst) and true or false
  r.chefe = false
  r.eventosDano = 0
  r.eventosAmeaca = 0
  r.pulsos = 0
  mescla(r, t)
  atual = r
end

function D.marca(grupo, campo, valor)
  if not ligado() or not atual then return end
  if type(campo) ~= "string" or not simples(valor) then return end
  local alvo = atual
  if grupo then
    if type(grupo) ~= "string" then return end
    alvo = atual[grupo]
    if type(alvo) ~= "table" then
      alvo = {}
      atual[grupo] = alvo
    end
  end
  if alvo[campo] == nil then alvo[campo] = valor end
end

function D.conta(campo, n)
  if not ligado() or not atual then return end
  if type(campo) ~= "string" then return end
  if n == nil then n = 1 end
  if type(n) ~= "number" or not legivel(n) then return end
  atual[campo] = (atual[campo] or 0) + n
end

function D.fecharLuta(t)
  if not ligado() or not atual then return end
  local d = dia()
  if not d then
    atual = nil
    return
  end
  mescla(atual, t)
  local max = (ns.cfg.sondas or {}).maxLutas or 30
  empurra(d.lutas, atual, max)
  atual = nil
end

-- ---------------------------------------------------------------------------
-- Carga: o que este cliente tem e a largura do pior caso de cada campo
-- ---------------------------------------------------------------------------

local NUMEROS = { 0, 7, 99, 999, 1000, 1234, 9999, 12345, 123456, 999999, 1234567 }

-- texto legivel do formatador ou "?"
local function formata(fn, n)
  if type(fn) ~= "function" then return "?" end
  local ok, r = pcall(fn, n)
  if ok and type(r) == "string" and legivel(r) then return r end
  return "?"
end

local function existe(tabela, nome)
  return type(tabela) == "table" and type(tabela[nome]) == "function"
end

-- devolve larguras, arquivo de fonte usado e o quadro escondido
local function medirLarguras()
  local larg = {}
  local ok, quadro = chamar(CreateFrame, "Frame", nil, UIParent)
  if not ok or type(quadro) ~= "table" then return larg, nil, nil end
  pcall(quadro.Hide, quadro)

  local cfg = ns.cfg
  local fonteCfg = cfg.fonte or {}
  local tam = cfg.tamanhos or {}
  local contorno = fonteCfg.contorno or ""
  local arquivos = {}
  if ns.painel and ns.painel.arquivoFonte then
    local okp, a = pcall(ns.painel.arquivoFonte)
    if okp and texto(a) then arquivos[#arquivos + 1] = a end
  end
  if texto(fonteCfg.arquivo) then arquivos[#arquivos + 1] = fonteCfg.arquivo end
  if texto(STANDARD_TEXT_FONT) then arquivos[#arquivos + 1] = STANDARD_TEXT_FONT end

  local campos = {
    { "dps", "88888", tam.dps or 38 },
    { "luta", "888.8K", tam.luta or 20 },
    { "total", "888.8K", tam.total or 16 },
    { "tempo", "88:88", tam.tempo or 16 },
    { "palavra", "SLIPPING", tam.palavra or 24 },
  }
  local fonteUsada
  for _, c in ipairs(campos) do
    local okf, fs = pcall(quadro.CreateFontString, quadro, nil, "OVERLAY")
    if okf and type(fs) == "table" then
      local posta = false
      for _, arq in ipairs(arquivos) do
        local oks, r = pcall(fs.SetFont, fs, arq, c[3], contorno)
        if oks and r then
          posta = true
          fonteUsada = fonteUsada or arq
          break
        end
      end
      if posta then
        pcall(fs.SetPoint, fs, "TOPLEFT", quadro, "TOPLEFT", 0, 0)
        pcall(fs.SetText, fs, c[2])
        local okw, w = pcall(fs.GetStringWidth, fs)
        if okw and type(w) == "number" and legivel(w) then
          larg[c[1]] = math.floor(w * 10 + 0.5) / 10
        end
      end
    end
  end
  return larg, fonteUsada, quadro
end

function D.carga()
  if not ligado() or cargaFeita then return end
  if ns.emCombate() then return end
  local d = dia()
  if not d then return end
  cargaFeita = true

  local e = { quando = quando(), versao = ns.VERSAO }

  -- build
  local okb, versao, numero, _, interface = chamar(GetBuildInfo)
  if okb then
    e.build = {
      versao = texto(versao) or "?",
      numero = texto(numero) or "?",
      interface = (type(interface) == "number") and interface or nil,
    }
  end

  -- personagem
  local okn, nome = chamar(UnitName, "player")
  e.nome = (okn and texto(nome)) or "?"
  local okc, _, classe = chamar(UnitClass, "player")
  e.classe = (okc and texto(classe)) or "?"
  if ns.ameaca and ns.ameaca.papel then
    local okr, papel = pcall(ns.ameaca.papel)
    if okr and texto(papel) then e.papel = papel end
  end

  -- disponibilidade do medidor
  if ns.segredo and ns.segredo.disponivel then
    local okd, disp, motivo = pcall(ns.segredo.disponivel)
    if okd then
      e.disponivel = disp and true or false
      e.motivo = texto(motivo)
    end
  end

  -- CVars
  e.cvar = {}
  if type(C_CVar) == "table" and type(C_CVar.GetCVar) == "function" then
    local nomes = { "damageMeterEnabled", "damageMeterResetOnNewInstance" }
    for _, n in ipairs(nomes) do
      local okv, v = pcall(C_CVar.GetCVar, n)
      if okv and texto(v) then e.cvar[n] = v end
    end
  end

  -- larguras (num quadro escondido proprio, fora de combate)
  local okl, larg, fonteUsada, quadro = pcall(medirLarguras)
  if okl then
    e.larguras = larg
    e.fonte = fonteUsada
  else
    e.larguras = {}
  end

  -- o que existe neste cliente
  local alfa = false
  if okl and type(quadro) == "table" then
    local okt, tex = pcall(quadro.CreateTexture, quadro)
    if okt and type(tex) == "table" and type(tex.SetAlphaFromBoolean) == "function" then
      alfa = true
    end
  end
  e.tem = {
    issecretvalue = type(issecretvalue) == "function",
    canaccesstable = type(canaccesstable) == "function",
    medidor = type(C_DamageMeter) == "table",
    arredondar = existe(C_StringUtil, "RoundToNearestString"),
    embrulhar = existe(C_StringUtil, "WrapString"),
    abreviar = type(AbbreviateNumbers) == "function",
    alfaBooleano = alfa,
    restricoes = type(C_RestrictedActions) == "table",
  }

  -- formatadores com numeros literais
  local redondo = type(C_StringUtil) == "table" and C_StringUtil.RoundToNearestString or nil
  e.formatos = {}
  for _, n in ipairs(NUMEROS) do
    e.formatos[#e.formatos + 1] = {
      n = n,
      inteiro = formata(redondo, n),
      abrev = formata(AbbreviateNumbers, n),
      grande = formata(AbbreviateLargeNumbers, n),
    }
  end

  d.carga[ns.chave()] = e
end
