-- CentralForever/Painel.lua: os quadros, textos e animacoes da central de combate.
-- O contrato deste arquivo esta em CONTRATO.md (secoes 3.7, 5 e 6). Medidas, cores e textos
-- vem de ns.cfg. O Painel nunca le valor, nunca mede texto e nunca le alfa de volta: o alfa e
-- um numero do proprio addon, guardado em variavel local. Os valores possivelmente secretos
-- entram nos campos pelos ralos de ns.segredo (outro arquivo).
-- Regras: Lua 5.1, so ASCII, texto do jogo em ingles, global so com prefixo CentralForever.
local _, ns = ...

local P = ns.painel or {}
ns.painel = P

local ARQ_TEXTURA = "Interface\\Buttons\\WHITE8X8"

-- Estado local do painel ------------------------------------------------------------------

local criado = false
local raiz, cartaoDano, cartaoThreat, driver
local campos = {}            -- dps, luta, total, tempo
local fundoDano = {}         -- fundo e bordas do cartao de dano (escondidos no resumo)
local palavra, linha2, regua, filhoOnYou, filhoNeutro
local molduras = { [2] = {}, [3] = {} }
local preenchimento, pulsoTex, pulsoAnim
local arquivoFonte = nil
local modoAtual = nil
local ultimoEstado = nil

-- Objetos com alfa comandado: { frame, alfa (numero nosso), para (alvo), de, t, dur, ativo }
local objRaiz = { alfa = 0, para = 0 }
local objThreat = { alfa = 0, para = 0 }
local ativos = {}

-- Config com padrao ------------------------------------------------------------------------

local function cfg()
  return ns.cfg or {}
end

local function sub(nome)
  local t = cfg()[nome]
  if type(t) == "table" then return t end
  return {}
end

local function num(tab, chave, padrao)
  local v = tab[chave]
  if type(v) == "number" then return v end
  return padrao
end

local PADRAO_COR = {
  fundo = { 0.051, 0.051, 0.051, 0.80 },
  borda = { 0, 0, 0, 1 },
  dps = { 1, 1, 1 },
  luta = { 1, 1, 1 },
  total = { 0.784, 0.784, 0.784 },
  tempo = { 0.651, 0.651, 0.651 },
  rotulo = { 0.651, 0.651, 0.651 },
  trilho = { 0.149, 0.149, 0.149 },
  marca = { 1, 1, 1, 0.35 },
  neutro = { 0.651, 0.651, 0.651 },
  ambar = { 1, 0.690, 0 },
  vermelhao = { 1, 0.125, 0 },
  vermelhaoTexto = { 1, 0.416, 0.302 },
  cheio = { 0.851, 0.102, 0 },
  azul = { 0.361, 0.784, 1 },
  branco = { 1, 1, 1 },
  pulso = { 1, 1, 1, 0.35 },
}

local function cor(nome)
  local c = sub("cores")[nome]
  if type(c) ~= "table" then c = PADRAO_COR[nome] or { 1, 1, 1 } end
  return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
end

local function vazio()
  local v = cfg().vazio
  if type(v) == "string" then return v end
  return "--"
end

-- Fonte ------------------------------------------------------------------------------------

local function listaFontes()
  local lista = {}
  pcall(function()
    local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
    if lsm and type(lsm.Fetch) == "function" then
      local nome = sub("fonte").nome
      if type(nome) == "string" then
        local p = lsm:Fetch("font", nome, true)
        if type(p) == "string" and p ~= "" then lista[#lista + 1] = p end
      end
    end
  end)
  local arq = sub("fonte").arquivo
  if type(arq) == "string" and arq ~= "" then lista[#lista + 1] = arq end
  lista[#lista + 1] = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
  return lista
end

local function contorno()
  local c = sub("fonte").contorno
  if type(c) == "string" then return c end
  return "OUTLINE"
end

-- Poe a fonte no texto. Na primeira vez, descobre qual arquivo funciona.
local function poeFonte(fs, tamanho)
  if arquivoFonte then
    pcall(function() fs:SetFont(arquivoFonte, tamanho, contorno()) end)
  else
    for _, arq in ipairs(listaFontes()) do
      local ok, r = pcall(function() return fs:SetFont(arq, tamanho, contorno()) end)
      if ok and r ~= false then
        arquivoFonte = arq
        break
      end
    end
    if not arquivoFonte then
      arquivoFonte = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    end
  end
  pcall(function() fs:SetShadowColor(0, 0, 0, 0) end)
  pcall(function() fs:SetShadowOffset(0, 0) end)
end

-- Pecas de construcao ----------------------------------------------------------------------

-- Cria um texto com largura e altura fixas, sem quebra de linha.
local function novoTexto(pai, tamanho, largura, altura, justH, nomeCor)
  local fs = pai:CreateFontString(nil, "OVERLAY")
  poeFonte(fs, tamanho)
  fs:SetSize(largura, altura)
  fs:SetJustifyH(justH)
  fs:SetJustifyV("MIDDLE")
  fs:SetWordWrap(false)
  fs:SetTextColor(cor(nomeCor))
  fs:SetText("")
  return fs
end

-- Quatro texturas de borda de espessura esp, nas bordas do quadro.
local function novasBordas(pai, esp, nomeCor, camada, nivel)
  local r, g, b, a = cor(nomeCor)
  local t = {}
  for i = 1, 4 do
    local x = pai:CreateTexture(nil, camada)
    x:SetDrawLayer(camada, nivel)
    x:SetColorTexture(r, g, b, a)
    t[i] = x
  end
  t[1]:SetPoint("TOPLEFT", pai, "TOPLEFT", 0, 0)
  t[1]:SetPoint("TOPRIGHT", pai, "TOPRIGHT", 0, 0)
  t[1]:SetHeight(esp)
  t[2]:SetPoint("BOTTOMLEFT", pai, "BOTTOMLEFT", 0, 0)
  t[2]:SetPoint("BOTTOMRIGHT", pai, "BOTTOMRIGHT", 0, 0)
  t[2]:SetHeight(esp)
  t[3]:SetPoint("TOPLEFT", pai, "TOPLEFT", 0, 0)
  t[3]:SetPoint("BOTTOMLEFT", pai, "BOTTOMLEFT", 0, 0)
  t[3]:SetWidth(esp)
  t[4]:SetPoint("TOPRIGHT", pai, "TOPRIGHT", 0, 0)
  t[4]:SetPoint("BOTTOMRIGHT", pai, "BOTTOMRIGHT", 0, 0)
  t[4]:SetWidth(esp)
  return t
end

local function mostraLista(lista, mostrar)
  for i = 1, #lista do
    if mostrar then lista[i]:Show() else lista[i]:Hide() end
  end
end

-- Fade proprio --------------------------------------------------------------------------------

local function rodaFade(_, dt)
  for i = #ativos, 1, -1 do
    local o = ativos[i]
    o.t = o.t + dt
    local k = 1
    if o.dur > 0 and o.t < o.dur then k = o.t / o.dur end
    o.alfa = o.de + (o.para - o.de) * k
    o.frame:SetAlpha(o.alfa)
    if k >= 1 then
      o.ativo = false
      table.remove(ativos, i)
      if o.para <= 0 then o.frame:Hide() end
    end
  end
  if #ativos == 0 and driver then driver:SetScript("OnUpdate", nil) end
end

local function tiraDosAtivos(o)
  if not o.ativo then return end
  for i = #ativos, 1, -1 do
    if ativos[i] == o then table.remove(ativos, i) end
  end
  o.ativo = false
end

-- Leva o objeto ao alfa "para" em "seg" segundos (sem seg, de uma vez).
local function fade(o, para, seg)
  if not o.frame then return end
  if o.para == para then return end
  o.para = para
  o.de = o.alfa
  if para > 0 then o.frame:Show() end
  if type(seg) ~= "number" or seg <= 0 then
    tiraDosAtivos(o)
    o.alfa = para
    o.frame:SetAlpha(para)
    if para <= 0 then o.frame:Hide() end
    return
  end
  o.t = 0
  o.dur = seg
  if not o.ativo then
    o.ativo = true
    ativos[#ativos + 1] = o
  end
  if driver then driver:SetScript("OnUpdate", rodaFade) end
end

-- Estilos do threat -----------------------------------------------------------------------------

-- mold: espessura da moldura (0 = nenhuma); cheio: preenchimento; texto e barra: nome da cor
local ESTILOS = {
  SAFE = { mold = 0, cheio = false, texto = "neutro", barra = "neutro" },
  CLOSE = { mold = 2, cheio = false, texto = "ambar", barra = "ambar" },
  SLIPPING = { mold = 2, cheio = false, texto = "ambar", barra = "ambar" },
  HIGH = { mold = 3, cheio = false, texto = "vermelhaoTexto", barra = "vermelhao" },
  LOOSE = { mold = 3, cheio = false, texto = "vermelhaoTexto", barra = "vermelhao" },
  ON_YOU = { mold = 0, cheio = true, texto = "branco", barra = "branco" },
  LOST = { mold = 0, cheio = true, texto = "branco", barra = "branco" },
  HELD = { mold = 0, cheio = false, texto = "azul", barra = "azul" },
  NEUTRO = { mold = 0, cheio = false, texto = "neutro", barra = "neutro" },
}

local function aplicaEstilo(estado)
  local e = ESTILOS[estado] or ESTILOS.NEUTRO
  mostraLista(molduras[2], e.mold == 2)
  mostraLista(molduras[3], e.mold == 3)
  if e.cheio then preenchimento:Show() else preenchimento:Hide() end
  palavra:SetTextColor(cor(e.texto))
  linha2:SetTextColor(cor(e.texto))
  regua:SetStatusBarColor(cor(e.barra))
end

-- Criacao ---------------------------------------------------------------------------------------

function P.existe()
  return criado
end

function P.arquivoFonte()
  return arquivoFonte
end

local function montaDano(larg, alt)
  local c = CreateFrame("Frame", nil, raiz)
  c:SetSize(larg, alt)
  c:SetPoint("BOTTOMRIGHT", raiz, "BOTTOMRIGHT", 0, 0)
  c:EnableMouse(false)

  local fundo = c:CreateTexture(nil, "BACKGROUND")
  fundo:SetDrawLayer("BACKGROUND", 0)
  fundo:SetAllPoints(c)
  fundo:SetColorTexture(cor("fundo"))
  fundoDano[1] = fundo
  local esp = num(sub("borda"), "fina", 1)
  local bs = novasBordas(c, esp, "borda", "BORDER", 0)
  for i = 1, #bs do fundoDano[#fundoDano + 1] = bs[i] end

  local tam = sub("tamanhos")
  local cx = sub("caixas")
  local caixaDps = num(cx, "dps", 116)
  local caixaValor = num(cx, "valor", 76)
  local caixaRotulo = num(cx, "rotulo", 46)
  local tamRotulo = num(tam, "rotulo", 13)
  local rot = sub("rotulos")

  -- DPS grande, a esquerda, com o rotulo embaixo
  local dps = novoTexto(c, num(tam, "dps", 38), caixaDps, num(tam, "dps", 38) + 6, "RIGHT", "dps")
  dps:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 8, 8 + tamRotulo + 4)
  campos.dps = dps
  local rd = novoTexto(c, tamRotulo, caixaDps, tamRotulo + 2, "RIGHT", "rotulo")
  rd:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 8, 8)
  rd:SetText(rot.dps or "DPS")

  -- FIGHT, TOTAL e tempo: os valores alinhados a direita numa coluna comum, e o rotulo de cada
  -- um logo a direita do proprio valor (o rotulo tem de ficar colado no numero dele, nao no DPS)
  local direita = -(8 + caixaRotulo + 4)
  local luta = novoTexto(c, num(tam, "luta", 20), caixaValor, 24, "RIGHT", "luta")
  luta:SetPoint("TOPRIGHT", c, "TOPRIGHT", direita, -8)
  campos.luta = luta
  local rl = novoTexto(c, tamRotulo, caixaRotulo, 24, "LEFT", "rotulo")
  rl:SetPoint("TOPLEFT", luta, "TOPRIGHT", 4, 0)
  rl:SetText(rot.luta or "FIGHT")

  local total = novoTexto(c, num(tam, "total", 16), caixaValor, 18, "RIGHT", "total")
  total:SetPoint("TOPRIGHT", c, "TOPRIGHT", direita, -32)
  campos.total = total
  local rt = novoTexto(c, tamRotulo, caixaRotulo, 18, "LEFT", "rotulo")
  rt:SetPoint("TOPLEFT", total, "TOPRIGHT", 4, 0)
  rt:SetText(rot.total or "TOTAL")

  local tempo = novoTexto(c, num(tam, "tempo", 16), caixaValor, 18, "RIGHT", "tempo")
  tempo:SetPoint("TOPRIGHT", c, "TOPRIGHT", direita, -50)
  campos.tempo = tempo

  return c
end

local function montaThreat(larg, alt)
  local c = CreateFrame("Frame", nil, raiz)
  c:SetSize(larg, alt)
  c:SetPoint("BOTTOMLEFT", raiz, "BOTTOMLEFT", 0, 0)
  c:EnableMouse(false)

  local fundo = c:CreateTexture(nil, "BACKGROUND")
  fundo:SetDrawLayer("BACKGROUND", 0)
  fundo:SetAllPoints(c)
  fundo:SetColorTexture(cor("fundo"))

  preenchimento = c:CreateTexture(nil, "BACKGROUND")
  preenchimento:SetDrawLayer("BACKGROUND", 1)
  preenchimento:SetAllPoints(c)
  preenchimento:SetColorTexture(cor("cheio"))
  preenchimento:Hide()

  local bd = sub("borda")
  novasBordas(c, num(bd, "fina", 1), "borda", "BORDER", 0)
  molduras[2] = novasBordas(c, num(bd, "perto", 2), "ambar", "BORDER", 1)
  molduras[3] = novasBordas(c, num(bd, "alto", 3), "vermelhao", "BORDER", 1)
  mostraLista(molduras[2], false)
  mostraLista(molduras[3], false)

  -- pulso: textura sobre o cartao, alfa 0, com animacao de ida e volta (valores literais)
  pulsoTex = c:CreateTexture(nil, "ARTWORK")
  pulsoTex:SetDrawLayer("ARTWORK", 0)
  pulsoTex:SetAllPoints(c)
  pulsoTex:SetColorTexture(cor("pulso"))
  pulsoTex:SetAlpha(0)
  local meio = num(sub("threat"), "pulsoSeg", 0.3) / 2
  pulsoAnim = pulsoTex:CreateAnimationGroup()
  local subida = pulsoAnim:CreateAnimation("Alpha")
  subida:SetFromAlpha(0)
  subida:SetToAlpha(1)
  subida:SetDuration(meio)
  subida:SetOrder(1)
  local descida = pulsoAnim:CreateAnimation("Alpha")
  descida:SetFromAlpha(1)
  descida:SetToAlpha(0)
  descida:SetDuration(meio)
  descida:SetOrder(2)
  pulsoAnim:SetToFinalAlpha(true)

  local tam = sub("tamanhos")
  local larguraTexto = num(sub("caixas"), "threat", 124)
  palavra = novoTexto(c, num(tam, "palavra", 24), larguraTexto, 26, "CENTER", "neutro")
  palavra:SetPoint("TOP", c, "TOP", 0, -5)
  linha2 = novoTexto(c, num(tam, "linha2", 18), larguraTexto, 20, "CENTER", "neutro")
  linha2:SetPoint("TOP", c, "TOP", 0, -30)

  -- regua: StatusBar com minimo e maximo literais do Config, trilho e marca
  local rg = sub("regua")
  local rLarg = num(rg, "largura", 120)
  local rAlt = num(rg, "altura", 6)
  local escala = num(sub("threat"), "escala", 100)
  regua = CreateFrame("StatusBar", nil, c)
  regua:SetSize(rLarg, rAlt)
  regua:SetPoint("BOTTOM", c, "BOTTOM", 0, 8)
  regua:SetStatusBarTexture(ARQ_TEXTURA)
  regua:SetMinMaxValues(0, escala)
  regua:SetValue(0)
  regua:SetStatusBarColor(cor("neutro"))
  local trilho = regua:CreateTexture(nil, "BACKGROUND")
  trilho:SetAllPoints(regua)
  trilho:SetColorTexture(cor("trilho"))
  local marca = regua:CreateTexture(nil, "OVERLAY")
  marca:SetSize(2, rAlt + 4)
  marca:SetPoint("CENTER", regua, "LEFT", rLarg * num(rg, "marca", 80) / escala, 0)
  marca:SetColorTexture(cor("marca"))

  -- Estado NEUTRO (status secreto): dois textos filhos no lugar da palavra, acesos por
  -- ns.segredo.mostrarSe com o booleano de isTanking. Um mostra "ON YOU" quando e verdadeiro;
  -- o outro mostra a palavra neutra quando e falso. Comecam com alfa 0 e nunca tem fade.
  local pal = sub("threat").palavras
  if type(pal) ~= "table" then pal = {} end
  filhoOnYou = novoTexto(c, num(tam, "palavra", 24), larguraTexto, 26, "CENTER", "vermelhaoTexto")
  filhoOnYou:SetPoint("TOP", c, "TOP", 0, -5)
  filhoOnYou:SetText(pal.ON_YOU or "ON YOU")
  filhoOnYou:SetAlpha(0)
  filhoNeutro = novoTexto(c, num(tam, "palavra", 24), larguraTexto, 26, "CENTER", "neutro")
  filhoNeutro:SetPoint("TOP", c, "TOP", 0, -5)
  filhoNeutro:SetText(pal.NEUTRO or "THREAT")
  filhoNeutro:SetAlpha(0)

  return c
end

function P.criar()
  if criado then return true end
  -- A criacao acontece uma vez, na carga, mesmo que a carga caia em combate (/reload no meio
  -- da luta). Depois disso nada mais e criado (regra 13).
  if not CreateFrame or not UIParent then return false end

  local cf = cfg()
  local alt = num(cf, "altura", 76)
  local pt = cf.ponto
  if type(pt) ~= "table" then pt = { "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -4, 31 } end
  local ancora = UIParent
  if type(pt[2]) == "string" and pt[2] ~= "UIParent" and _G[pt[2]] then ancora = _G[pt[2]] end

  raiz = CreateFrame("Frame", "CentralForeverPainel", UIParent)
  raiz:SetSize(num(cf, "largura", 406), alt)
  raiz:SetPoint(pt[1] or "BOTTOMRIGHT", ancora, pt[3] or "BOTTOMRIGHT", pt[4] or -4, pt[5] or 31)
  raiz:SetFrameStrata(type(cf.strata) == "string" and cf.strata or "MEDIUM")
  raiz:SetFrameLevel(num(cf, "nivel", 20))
  raiz:EnableMouse(false)
  raiz:SetAlpha(0)
  raiz:Hide()

  driver = CreateFrame("Frame", nil, UIParent)

  cartaoDano = montaDano(num(sub("cartaoDano"), "largura", 270), alt)
  cartaoThreat = montaThreat(num(sub("cartaoThreat"), "largura", 132), alt)
  cartaoThreat:SetAlpha(0)
  cartaoThreat:Hide()

  objRaiz.frame = raiz
  objThreat.frame = cartaoThreat
  objRaiz.alfa, objRaiz.para = 0, 0
  objThreat.alfa, objThreat.para = 0, 0

  criado = true
  return true
end

-- Campos -----------------------------------------------------------------------------------------

function P.campo(nome)
  return campos[nome]
end

-- Texto legivel do proprio addon (nunca valor de API)
function P.texto(nome, texto)
  local fs = campos[nome]
  if fs then fs:SetText(texto or "") end
end

-- Threat -----------------------------------------------------------------------------------------

function P.threatOculto(seg)
  if not criado then return end
  ultimoEstado = nil
  fade(objThreat, 0, seg)
end

function P.threat(visao)
  if not criado then return end
  if type(visao) ~= "table" or not visao.visivel then
    P.threatOculto(num(sub("threat"), "fadeSeg", 0.4))
    return
  end
  local S = ns.segredo

  fade(objThreat, 1, num(sub("entrada"), "fadeSeg", 0.15))

  -- cor e forma so quando o estado muda
  local estado = visao.estado or "NEUTRO"
  if estado ~= ultimoEstado then
    aplicaEstilo(estado)
    ultimoEstado = estado
  end

  -- no estado NEUTRO a palavra e dos dois textos filhos (abaixo); a principal fica vazia
  if type(visao.onYou) == "table" then
    palavra:SetText("")
  else
    palavra:SetText(visao.palavra or vazio())
  end

  -- linha 2
  local l2 = visao.linha2
  local modo = type(l2) == "table" and l2.modo or "nada"
  if modo == "pct" then
    if type(l2.caixa) == "table" and S and S.mostrarPct then
      S.mostrarPct(linha2, l2.caixa)
    else
      linha2:SetText(vazio())
    end
  elseif modo == "texto" then
    linha2:SetText(l2.texto or "")
  else
    linha2:SetText("")
  end

  -- regua
  if type(visao.barra) == "table" and S and S.mostrarBarra then
    S.mostrarBarra(regua, visao.barra)
  else
    regua:SetValue(0)
  end

  -- textos filhos do estado NEUTRO
  if type(visao.onYou) == "table" and S and S.mostrarSe then
    S.mostrarSe(filhoOnYou, visao.onYou, false)
    S.mostrarSe(filhoNeutro, visao.onYou, true)
  else
    filhoOnYou:SetAlpha(0)
    filhoNeutro:SetAlpha(0)
  end

  -- pulso
  if visao.pulso then
    pulsoAnim:Stop()
    pulsoAnim:Play()
  end
end

-- Modos ------------------------------------------------------------------------------------------

local function visaoAmostra()
  local pal = sub("threat").palavras
  local p = type(pal) == "table" and pal.CLOSE or "CLOSE"
  return {
    visivel = true,
    estado = "CLOSE",
    palavra = p,
    linha2 = { modo = "texto", texto = "87%" },
    barra = nil,
    onYou = nil,
    pulso = false,
  }
end

local function fundoDanoVisivel(sim)
  mostraLista(fundoDano, sim)
end

function P.modo(m, seg)
  if not criado then return end
  local anterior = modoAtual
  modoAtual = m
  local entradaSeg = num(sub("entrada"), "fadeSeg", 0.15)

  if m == "oculto" then
    P.threatOculto(seg or 0)
    fade(objRaiz, 0, seg or num(sub("resumo"), "fadeSeg", 1.0))

  elseif m == "combate" then
    fundoDanoVisivel(true)
    if anterior ~= "combate" then P.threatOculto(0) end
    fade(objRaiz, 1, seg or entradaSeg)

  elseif m == "pos" then
    fundoDanoVisivel(true)
    P.threatOculto(0)
    fade(objRaiz, 1, seg or entradaSeg)

  elseif m == "resumo" then
    fundoDanoVisivel(sub("resumo").fundo == true)
    P.threatOculto(0)
    fade(objRaiz, num(sub("resumo"), "alfa", 0.45), seg or num(sub("resumo"), "fadeSeg", 1.0))

  elseif m == "amostra" then
    fundoDanoVisivel(true)
    P.texto("dps", "412")
    P.texto("luta", "45.6K")
    P.texto("total", "1.24M")
    P.texto("tempo", "1:23")
    fade(objRaiz, 1, seg or entradaSeg)
    P.threat(visaoAmostra())
    regua:SetValue(87)
  end
end
