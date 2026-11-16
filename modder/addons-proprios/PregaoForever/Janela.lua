-- Janela.lua (PregaoForever): PregaoForeverJanela a direita do leilao (tres zonas fixas: estado, lista, bilhete, mais o
-- rodape de botoes) e o painel do correio PregaoForeverCorreio. Abre no AUCTION_HOUSE_SHOW e fecha no AUCTION_HOUSE_CLOSED;
-- ns.janela.abrir(visao) tambem abre fora do leilao (so leitura, sem bindings). Onda 2: nenhum botao de acao.
-- Contrato: ARQUITETURA.md, secao 3.12. Quem desenha o conteudo e a Telas.lua, pelas funcoes pintar daqui.
local _, ns = ...
ns.janela = ns.janela or {}
local J = ns.janela

local LINHA, BARRA = 21, 26          -- altura da linha de lista; altura da barra de titulo
local N_ESTADO, N_BILHETE = 4, 3     -- linhas fixas das zonas de estado e de bilhete
local RODAPE = 36
local XCOL = { 20, 200, 285, 365 }   -- colunas fixas das linhas com cols

J.leilao = false   -- o leilao da Blizzard esta aberto (pelos eventos)
J.q = nil          -- quadros da janela
J.c = nil          -- quadros do painel do correio

local function tamanho()
  local c = ns.cfg and ns.cfg.janela
  return (c and c.w) or 520, (c and c.h) or 500, (c and c.escala) or 1
end

-- ---------- linhas (slots de texto) ----------
local function novoSlot(pai, y, w, comCols)
  local s = {}
  s.marc = ns.ui.fs(pai, "menor")
  s.marc:SetPoint("TOPLEFT", pai, "TOPLEFT", 6, -y)
  s.marc:SetWidth(12)
  s.rot = ns.ui.fs(pai, "menor")
  s.rot:SetPoint("TOPLEFT", pai, "TOPLEFT", 18, -y)
  s.rot:SetWidth(66)
  s.txt = ns.ui.fs(pai, "menor")
  s.txt:SetPoint("TOPLEFT", pai, "TOPLEFT", 86, -y)
  s.txt:SetWidth(w - 94)
  s.cols = {}
  if comCols then
    for i = 1, #XCOL do
      local fs = ns.ui.fs(pai, "menor")
      fs:SetPoint("TOPLEFT", pai, "TOPLEFT", XCOL[i], -y)
      fs:SetWidth((XCOL[i + 1] or (w - 8)) - XCOL[i] - 6)
      s.cols[i] = fs
    end
  end
  return s
end

local function limpaSlot(s)
  s.marc:Hide()
  s.rot:Hide()
  s.txt:Hide()
  for i = 1, #s.cols do s.cols[i]:Hide() end
end

local function pintaSlot(s, l)
  limpaSlot(s)
  if l.sel then
    ns.ui.texto(s.marc, ">", "dourado")
    s.marc:Show()
  end
  if l.cols then
    for i = 1, #s.cols do
      local c = l.cols[i]
      if c ~= nil then
        ns.ui.texto(s.cols[i], ns.ui.coluna(c, true), l.cor or "texto")
        s.cols[i]:Show()
      end
    end
    return
  end
  if l.rot ~= nil and l.rot ~= "" then
    ns.ui.texto(s.rot, l.rot, l.rc or "cinza")
    s.rot:Show()
  end
  local corpo = ns.ui.corpo(l, true)
  if corpo ~= "" then
    ns.ui.texto(s.txt, corpo, l.cor or "texto")
    s.txt:Show()
  end
end

local function zona(pai, y, n, w, comCols)
  local z = { y = y, slots = {} }
  for i = 1, n do z.slots[i] = novoSlot(pai, y + (i - 1) * LINHA, w, comCols) end
  return z
end

local function risco(pai, y, w)
  local t = pai:CreateTexture(nil, "ARTWORK")
  t:SetColorTexture(1, 1, 1, 0.12)
  t:SetPoint("TOPLEFT", pai, "TOPLEFT", 6, -y)
  t:SetSize(w - 12, 1)
  return t
end

-- ---------- a janela ----------
function J.garantir()
  if J.q then return J.q end
  local w, h, esc = tamanho()
  local f = CreateFrame("Frame", "PregaoForeverJanela", UIParent, "BackdropTemplate")
  f:SetSize(w, h)
  f:SetScale(esc)
  f:SetFrameStrata("HIGH")
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  ns.ui.painel(f, "janela")
  f:Hide()
  local q = { f = f, w = w, h = h }
  J.q = q

  q.nome = ns.ui.fs(f, "secao")
  q.nome:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -7)
  ns.ui.texto(q.nome, "PregaoForever", "dourado")

  -- botoes de tecla (Teclas.lua os cria; aqui so a posicao)
  local b = ns.teclas.criar(f)
  b.L:SetSize(110, 22)
  b.L:SetPoint("TOPLEFT", f, "TOPLEFT", w - 118, -(BARRA + 4 + 2 * LINHA - 2))
  b.F3:SetSize(66, 20)
  b.F3:SetPoint("TOPLEFT", f, "TOPLEFT", 206, -3)
  b.F5:SetSize(92, 20)
  b.F5:SetPoint("TOPLEFT", f, "TOPLEFT", 336, -3)
  -- abas ainda sem tecla (F1, F2 e F4 entram na onda 3): so texto
  q.abas = {}
  local mortas = { { "F1 NEXT", 112 }, { "F2 SELL", 160 }, { "F4 RISK", 276 } }
  for i = 1, #mortas do
    local fs = ns.ui.fs(f, "menor")
    fs:SetPoint("TOPLEFT", f, "TOPLEFT", mortas[i][2], -8)
    ns.ui.texto(fs, mortas[i][1], "cinza")
    q.abas[i] = fs
  end
  q.sondaAba = ns.ui.fs(f, "menor")
  q.sondaAba:SetPoint("TOPLEFT", f, "TOPLEFT", 436, -8)
  q.sondaAba:Hide()
  q.fechar = ns.ui.botao(f, "PregaoForeverJanelaFechar", "Close", 44, 20)
  q.fechar:SetPoint("TOPLEFT", f, "TOPLEFT", w - 50, -3)
  q.fechar:SetScript("OnClick", ns.seguro(function() J.fechar() end))

  -- zonas fixas
  local yEst = BARRA + 4
  q.estado = zona(f, yEst, N_ESTADO, w, false)
  local yLista = yEst + N_ESTADO * LINHA + 8
  local yBil = h - RODAPE - N_BILHETE * LINHA - 8
  local nLista = math.floor((yBil - 6 - yLista) / LINHA)
  q.lista = zona(f, yLista, nLista, w, true)
  q.bilhete = zona(f, yBil, N_BILHETE, w, false)
  q.linhasLista = nLista
  risco(f, BARRA, w)
  risco(f, yLista - 4, w)
  risco(f, yBil - 4, w)
  risco(f, h - RODAPE, w)

  -- Y de salvar (so na visao Session) e os dois botoes do cartao da sonda
  b.Y:SetSize(280, 22)
  b.Y:Hide()
  q.yBase = yBil
  q.pular = ns.ui.botao(f, "PregaoForeverSondaPular", "Skip step", 80, 22)
  q.pular:SetScript("OnClick", ns.seguro(function() ns.telas.proximoPasso() end))
  q.salvar = ns.ui.botao(f, "PregaoForeverSondaSalvar", "Save now", 80, 22)
  q.salvar:SetScript("OnClick", ns.seguro(function() J.salvar() end))
  q.pular:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -(yBil + LINHA - 2))
  q.salvar:SetPoint("TOPLEFT", f, "TOPLEFT", 94, -(yBil + LINHA - 2))
  q.pular:Hide()
  q.salvar:Hide()

  -- rodape: navegacao e a ultima tecla
  local x = 8
  local rod = { "N", "U", "I", "O", "K", "H" }
  for i = 1, #rod do
    local bt = b[rod[i]]
    bt:SetSize(66, 26)
    bt:SetPoint("TOPLEFT", f, "TOPLEFT", x, -(h - RODAPE + 5))
    x = x + 70
  end
  q.ultima = ns.ui.fs(f, "menor")
  q.ultima:SetPoint("TOPLEFT", f, "TOPLEFT", w - 118, -(h - RODAPE + 12))
  q.ultima:SetWidth(110)
  q.ultima:SetJustifyH("RIGHT")

  -- tique de 0,25 s: foco do teclado numa caixa de texto (com o foco na caixa a tecla nao chega ao addon)
  q.acum = 0
  f:SetScript("OnUpdate", ns.seguro(function(self, dt)
    q.acum = q.acum + (dt or 0)
    if q.acum < 0.25 then return end
    q.acum = 0
    ns.teclas.verFoco()
  end))
  return q
end

function J.quadro()
  return J.q and J.q.f or nil
end

function J.aberta()
  return J.q ~= nil and J.q.f:IsShown() and true or false
end

-- Ancora a direita do leilao da Blizzard (acima das bolsas); sem leilao, no meio da tela.
local function ancorar(q)
  q.f:ClearAllPoints()
  local ah = _G.AuctionHouseFrame
  if ah then
    q.f:SetPoint("TOPLEFT", ah, "TOPRIGHT", 4, 0)
  else
    q.f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
end

-- Abre (ou troca a visao). Bindings so se o leilao esta aberto.
function J.abrir(visao)
  local q = J.garantir()
  ancorar(q)
  q.f:Show()
  if visao ~= nil then
    ns.telas.mostrar(visao)
  elseif not ns.telas.visao then
    ns.telas.mostrar("mine")
  else
    ns.telas.redesenhar()
  end
  if J.leilao then ns.teclas.ligar() end
end

function J.fechar()
  if J.q then J.q.f:Hide() end
  ns.teclas.soltar()
end

-- Salvar: ReloadUI so com tudo em repouso; a S1 carimba a hora do clique.
function J.salvar()
  if not ns.teclas.repouso() then return false end
  if ns.sonda and ns.sonda.aoSalvar then ns.sonda.aoSalvar() end
  ReloadUI()
  return true
end

-- ---------- pintura (chamada pela Telas.lua) ----------
function J.pintar(nome, linhas)
  local q = J.garantir()
  local z = q[nome]
  if not z then return end
  for i = 1, #z.slots do
    local l = linhas[i]
    if l then pintaSlot(z.slots[i], l) else limpaSlot(z.slots[i]) end
  end
end

function J.capacidade()
  return J.garantir().linhasLista
end

function J.pintarAbas(visao)
  local q = J.garantir()
  local b = ns.teclas.botoes
  ns.ui.rotular(b.F3, (visao == "mine") and "[F3 MINE]" or "F3 MINE", true)
  ns.ui.rotular(b.F5, (visao == "session") and "[F5 SESSION]" or "F5 SESSION", true)
  if visao == "sonda" then
    ns.ui.texto(q.sondaAba, "[PROBE]", "dourado")
    q.sondaAba:Show()
  else
    q.sondaAba:Hide()
  end
  local t = ns.teclas.ultimaTecla
  ns.ui.texto(q.ultima, t and ("last key: " .. t) or "", "cinza")
end

-- Y de salvar: modo = nil esconde; senao { linha = 1 ou 2, ativo = bool }
function J.pintarY(modo)
  local q = J.garantir()
  local y = ns.teclas.botoes.Y
  if not modo then
    y:Hide()
    return
  end
  y:ClearAllPoints()
  y:SetPoint("TOPLEFT", q.f, "TOPLEFT", 70, -(q.yBase + (modo.linha - 1) * LINHA - 2))
  ns.ui.rotular(y, ns.teclas.ROTULO.Y, modo.ativo)
  y:Show()
end

function J.pintarSonda(mostrar)
  local q = J.garantir()
  if mostrar then
    q.pular:Show()
    q.salvar:Show()
  else
    q.pular:Hide()
    q.salvar:Hide()
  end
end

-- ---------- painel do correio ----------
local N_CORREIO = 6

function J.garantirCorreio()
  if J.c then return J.c end
  local w = 520
  local h = BARRA + 8 + N_CORREIO * LINHA + 8 + 40
  local f = CreateFrame("Frame", "PregaoForeverCorreio", UIParent, "BackdropTemplate")
  f:SetSize(w, h)
  f:SetFrameStrata("HIGH")
  f:EnableMouse(true)
  ns.ui.painel(f, "janela")
  f:Hide()
  local c = { f = f, w = w, h = h }
  J.c = c
  c.nome = ns.ui.fs(f, "secao")
  c.nome:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -7)
  ns.ui.texto(c.nome, "PregaoForever   [MAIL]", "dourado")
  c.linhas = zona(f, BARRA + 6, N_CORREIO, w, false)
  risco(f, BARRA, w)
  risco(f, h - 40, w)
  c.dispensar = ns.ui.botao(f, "PregaoForeverCorreioDispensar", "Dismiss", 80, 26)
  c.dispensar:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -(h - 34))
  c.dispensar:SetScript("OnClick", ns.seguro(function() J.fecharCorreio() end))
  c.salvar = ns.ui.botao(f, "PregaoForeverCorreioSalvar", "Save now", 80, 26)
  c.salvar:SetPoint("TOPLEFT", f, "TOPLEFT", 94, -(h - 34))
  c.salvar:SetScript("OnClick", ns.seguro(function() J.salvar() end))
  c.nota = ns.ui.fs(f, "menor")
  c.nota:SetPoint("TOPLEFT", f, "TOPLEFT", w - 188, -(h - 27))
  c.nota:SetWidth(180)
  c.nota:SetJustifyH("RIGHT")
  ns.ui.texto(c.nota, "click: no keys here", "cinza")
  return c
end

function J.abrirCorreio()
  local c = J.garantirCorreio()
  c.f:ClearAllPoints()
  local mf = _G.MailFrame
  if mf then
    c.f:SetPoint("TOPLEFT", mf, "TOPRIGHT", 4, 0)
  else
    c.f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
  c.f:Show()
  ns.telas.redesenharCorreio()
end

function J.fecharCorreio()
  if J.c then J.c.f:Hide() end
end

function J.correioAberto()
  return J.c ~= nil and J.c.f:IsShown() and true or false
end

function J.pintarCorreio(linhas)
  local c = J.garantirCorreio()
  for i = 1, #c.linhas.slots do
    local l = linhas[i]
    if l then pintaSlot(c.linhas.slots[i], l) else limpaSlot(c.linhas.slots[i]) end
  end
end

-- ---------- eventos ----------
-- Os quadros nascem (escondidos) na carga, para os botoes existirem antes do primeiro leilao.
ns.ao("ADDON_LOADED", function(_, nome)
  if nome ~= ns.NOME then return end
  J.garantir()
end)

ns.ao("AUCTION_HOUSE_SHOW", function()
  J.leilao = true
  J.abrir()
end)

ns.ao("AUCTION_HOUSE_CLOSED", function()
  J.leilao = false
  J.fechar()
end)

ns.ao("MAIL_SHOW", function()
  J.abrirCorreio()
end)

ns.ao("MAIL_CLOSED", function()
  J.fecharCorreio()
end)
