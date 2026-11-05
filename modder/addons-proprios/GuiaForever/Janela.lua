-- GuiaForever: janela com abas e rolagem, botao do livro perto do minimapa e tecla J.
-- Os textos vem de Dados.lua (talentos), Dicas.lua (dicas por nivel), Profissoes*.lua
-- e Treinadores.lua (aba Treinos); as funcoes compartilhadas ficam em `ns`.

local _, ns = ...

local LARGURA, ALTURA = 470, 460
local ABAS = {
  { id = "nivel", rotulo = "Nivel" },
  { id = "talentos", rotulo = "Talentos" },
  { id = "armas", rotulo = "Armas" },
  { id = "pets", rotulo = "Pets" },
  { id = "rotacao", rotulo = "Rotacao" },
  { id = "prof", rotulo = "Prof." },
  { id = "treinos", rotulo = "Treinos" },
}
local CINZA, AMARELO = "|cff999999", "|cffffd100"

local janela, rolagem, conteudo, titulo
local botoesAba = {}
local poolTexto, poolBotao = {}, {}
local abaAtual

-- Blocos: { t = "texto", s = ... } ou { t = "botao", s = rotulo, f = funcao }
local function T(b, s) b[#b + 1] = { t = "texto", s = s } end
local function cab(b, s) T(b, " "); T(b, ns.COR .. s .. ns.FIM) end
ns.blocoTexto, ns.blocoCabecalho = T, cab
ns.blocoBotao = function(b, s, f) b[#b + 1] = { t = "botao", s = s, f = f } end

local function nivelJogador() return UnitLevel("player") or 1 end
local function noIntervalo(e, n) return e.de <= n and n <= e.ate end
local function faixaTxt(e)
  if e.de == e.ate then return "Nivel " .. e.de end
  return "Niveis " .. e.de .. "-" .. e.ate
end

local function listaFaixas(b, lista, n, vazio)
  if not lista or #lista == 0 then T(b, vazio or "Sem fonte."); return end
  for _, e in ipairs(lista) do
    local linha = faixaTxt(e) .. ": " .. ns.comFonte(e)
    if noIntervalo(e, n) then linha = ns.COR .. "> " .. ns.FIM .. linha end
    T(b, linha)
  end
end

-- Abas ---------------------------------------------------------------
local construtores = {}

construtores.nivel = function(b)
  local n = nivelJogador()
  local d, dados = ns.dicas(), ns.dados()
  T(b, ns.COR .. "Nivel " .. n .. (d and d.personagem and (" - " .. d.personagem) or "") .. ns.FIM)
  if dados then
    local livres = ns.pontosLivres()
    if n >= ns.MIN_NIVEL and (livres == nil or livres > 0) then
      T(b, "Talento agora: " .. (ns.entrada(n) or "?"))
    end
    local prox = ns.entrada(n + 1)
    if prox then T(b, "Talento no " .. (n + 1) .. ": " .. prox) end
  end
  if not d then T(b, "Sem dicas para esta classe. Treinadores: aba Treinos."); return end
  cab(b, "Magias (este nivel e os 2 proximos)")
  local achou = false
  for _, e in ipairs(d.magias or {}) do
    if e.nivel >= n and e.nivel <= n + 2 then
      T(b, "Nivel " .. e.nivel .. ": " .. ns.comFonte(e)); achou = true
    end
  end
  if not achou then T(b, "Nada novo de magia nas fontes para estes niveis.") end
  for _, par in ipairs({ { "armas", "Armas desta faixa" }, { "pets", "Pets desta faixa" }, { "rotacao", "Rotacao desta faixa" } }) do
    local lista = d[par[1]] or {}
    if #lista > 0 then
      cab(b, par[2])
      local ach = false
      for _, e in ipairs(lista) do
        if noIntervalo(e, n) then T(b, ns.comFonte(e)); ach = true end
      end
      if not ach then T(b, "Sem fonte para esta faixa.") end
    end
  end
  if d.atributos and #d.atributos > 0 then
    cab(b, "Atributos")
    for _, e in ipairs(d.atributos) do T(b, ns.comFonte(e)) end
  end
end

construtores.talentos = function(b)
  local dados = ns.dados()
  if not dados then T(b, "Sem guia de talentos para esta classe."); return end
  local n = nivelJogador()
  local livres = ns.pontosLivres()
  local ini = n + 1
  if n >= ns.MIN_NIVEL and (livres == nil or livres > 0) then ini = n end
  if ini < ns.MIN_NIVEL then ini = ns.MIN_NIVEL end
  T(b, ns.COR .. (dados.personagem or "") .. " - proximos 5 pontos" .. ns.FIM)
  local k = 0
  for l = ini, ns.MAX_NIVEL do
    if k >= 5 then break end
    T(b, "Nivel " .. l .. ": " .. (dados.ordem[l] or "?"))
    k = k + 1
  end
  if k == 0 then T(b, "Nada a mostrar (nivel maximo do guia).") end
  if dados.lei then
    cab(b, "Lei (entra com certeza)")
    for _, s in ipairs(dados.lei) do T(b, "- " .. s) end
  end
  if dados.aberto then
    cab(b, "Aberto (o dono decide)")
    for _, a in ipairs(dados.aberto) do
      T(b, AMARELO .. a.ponto .. ns.FIM)
      for _, o in ipairs(a.opcoes) do T(b, "   " .. o) end
    end
  end
  T(b, " ")
  T(b, CINZA .. "Ordem completa no chat: /guia tudo" .. ns.FIM)
end

local function abaDeFaixas(chave, nomeAba, vazio)
  return function(b)
    local d = ns.dicas()
    if not d then T(b, "Sem dicas para esta classe."); return end
    T(b, ns.COR .. nomeAba .. ns.FIM .. CINZA .. "  (> = sua faixa)" .. ns.FIM)
    listaFaixas(b, d[chave], nivelJogador(), vazio)
  end
end
construtores.armas = abaDeFaixas("armas", "Armas por faixa de nivel")
construtores.pets = abaDeFaixas("pets", "Pets: o que domar e onde", "Esta classe nao tem pet.")

construtores.rotacao = function(b)
  local d = ns.dicas()
  if not d then T(b, "Sem dicas para esta classe."); return end
  T(b, ns.COR .. "Rotacao por faixa" .. ns.FIM .. CINZA .. "  (> = sua faixa)" .. ns.FIM)
  listaFaixas(b, d.rotacao, nivelJogador())
  if d.atributos and #d.atributos > 0 then
    cab(b, "Prioridade de atributos")
    for _, e in ipairs(d.atributos) do T(b, ns.comFonte(e)) end
  end
  if d.notas and #d.notas > 0 then
    cab(b, "Notas")
    for _, e in ipairs(d.notas) do T(b, ns.comFonte(e)) end
  end
end

construtores.prof = function(b)
  local lista = ns.minhasProfissoes()
  if #lista == 0 then
    T(b, "Nenhuma profissao com roteiro aprendida ainda.")
    T(b, "Onde aprender: aba Treinos.")
    return
  end
  for _, pr in ipairs(lista) do
    local idx = ns.indicePasso(pr.tab, pr.pericia)
    T(b, ns.COR .. ns.linhaProf(pr, idx) .. ns.FIM)
    local prox = pr.tab.passos[idx + 1]
    if prox then T(b, "   Proximo (" .. prox.de .. "-" .. prox.ate .. "): " .. prox.texto) end
    if pr.tab.fonte then T(b, CINZA .. "   Fonte: " .. pr.tab.fonte .. ns.FIM) end
  end
end

construtores.treinos = function(b)
  if ns.blocosTreinos then
    ns.blocosTreinos(b)
  else
    T(b, "Treinadores indisponiveis.")
  end
end

-- Desenho ------------------------------------------------------------
local function desenhar(blocos)
  local y = -4
  local it, ib = 0, 0
  local largura = LARGURA - 60
  for _, bl in ipairs(blocos) do
    if bl.t == "botao" then
      ib = ib + 1
      local bt = poolBotao[ib]
      if not bt then
        bt = CreateFrame("Button", nil, conteudo, "UIPanelButtonTemplate")
        bt:SetSize(260, 20)
        poolBotao[ib] = bt
      end
      bt:ClearAllPoints()
      bt:SetPoint("TOPLEFT", conteudo, "TOPLEFT", 4, y)
      bt:SetText(bl.s)
      bt:SetScript("OnClick", bl.f)
      bt:Show()
      y = y - 24
    else
      it = it + 1
      local fs = poolTexto[it]
      if not fs then
        fs = conteudo:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        fs:SetWidth(largura)
        poolTexto[it] = fs
      end
      fs:ClearAllPoints()
      fs:SetPoint("TOPLEFT", conteudo, "TOPLEFT", 4, y)
      fs:SetText(bl.s)
      fs:Show()
      y = y - (fs:GetStringHeight() or 12) - 3
    end
  end
  for i = it + 1, #poolTexto do poolTexto[i]:Hide() end
  for i = ib + 1, #poolBotao do poolBotao[i]:Hide() end
  conteudo:SetHeight(math.max(-y + 6, 10))
end

local function marcarAba()
  for id, bt in pairs(botoesAba) do
    if id == abaAtual then bt:LockHighlight() else bt:UnlockHighlight() end
  end
end

local function atualizar()
  if not janela or not janela:IsShown() then return end
  local blocos = {}
  local fn = construtores[abaAtual] or construtores.nivel
  fn(blocos)
  desenhar(blocos)
  local d = ns.dicas()
  titulo:SetText("GuiaForever" .. (d and d.personagem and (" - " .. d.personagem) or ""))
  marcarAba()
end
ns.atualizarJanela = atualizar

local function salvarPosicao()
  local p, _, rp, x, y = janela:GetPoint()
  GuiaForeverDB.pos = { p, rp, x, y }
end

local function criarJanela()
  if janela then return end
  janela = CreateFrame("Frame", "GuiaForeverJanela", UIParent, "BackdropTemplate")
  janela:SetSize(LARGURA, ALTURA)
  janela:SetFrameStrata("MEDIUM")
  janela:SetClampedToScreen(true)
  janela:SetMovable(true)
  janela:EnableMouse(true)
  janela:RegisterForDrag("LeftButton")
  janela:SetScript("OnDragStart", janela.StartMoving)
  janela:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    salvarPosicao()
  end)
  if janela.SetBackdrop then
    janela:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 14,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
  end
  titulo = janela:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titulo:SetPoint("TOPLEFT", 12, -10)
  local fechar = CreateFrame("Button", nil, janela, "UIPanelCloseButton")
  fechar:SetPoint("TOPRIGHT", -2, -2)

  local x = 10
  for _, aba in ipairs(ABAS) do
    local bt = CreateFrame("Button", nil, janela, "UIPanelButtonTemplate")
    bt:SetSize(62, 20)
    bt:SetPoint("TOPLEFT", janela, "TOPLEFT", x, -30)
    bt:SetText(aba.rotulo)
    local id = aba.id
    bt:SetScript("OnClick", function()
      abaAtual = id
      GuiaForeverDB.aba = id
      if rolagem then rolagem:SetVerticalScroll(0) end
      atualizar()
    end)
    botoesAba[id] = bt
    x = x + 64
  end

  rolagem = CreateFrame("ScrollFrame", "GuiaForeverRolagem", janela, "UIPanelScrollFrameTemplate")
  rolagem:SetPoint("TOPLEFT", janela, "TOPLEFT", 10, -56)
  rolagem:SetPoint("BOTTOMRIGHT", janela, "BOTTOMRIGHT", -30, 10)
  conteudo = CreateFrame("Frame", nil, rolagem)
  conteudo:SetSize(LARGURA - 50, 10)
  rolagem:SetScrollChild(conteudo)

  local pos = GuiaForeverDB.pos
  janela:ClearAllPoints()
  if pos and pos[1] then
    janela:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3] or 0, pos[4] or 0)
  else
    janela:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
  janela:SetScript("OnShow", atualizar)
  if UISpecialFrames then tinsert(UISpecialFrames, "GuiaForeverJanela") end -- Esc fecha
  abaAtual = GuiaForeverDB.aba or "nivel"
  janela:Hide()
end

function ns.alternarJanela()
  criarJanela()
  if janela:IsShown() then janela:Hide() else janela:Show() end
end

function ns.abrirAba(id)
  criarJanela()
  if not construtores[id] then id = "nivel" end
  abaAtual = id
  GuiaForeverDB.aba = id
  rolagem:SetVerticalScroll(0)
  if janela:IsShown() then atualizar() else janela:Show() end
end

-- Atalho de tecla (Bindings.xml) e nomes no menu de teclas.
BINDING_HEADER_GUIAFOREVER = "GuiaForever"
_G["BINDING_NAME_GUIAFOREVER_JANELA"] = "Abrir e fechar o guia"
function GuiaForever_AlternarJanela() ns.alternarJanela() end

-- Botao do livro -------------------------------------------------------
local function criarBotao()
  if _G.GuiaForeverBotao then return end
  local bt = CreateFrame("Button", "GuiaForeverBotao", UIParent)
  bt:SetSize(28, 28)
  bt:SetFrameStrata("MEDIUM")
  bt:SetClampedToScreen(true)
  bt:SetMovable(true)
  bt:EnableMouse(true)
  bt:RegisterForDrag("LeftButton")
  bt:RegisterForClicks("LeftButtonUp")
  local icone = bt:CreateTexture(nil, "ARTWORK")
  icone:SetAllPoints()
  icone:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  bt:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  bt:SetScript("OnDragStart", bt.StartMoving)
  bt:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    GuiaForeverDB.botao = { p, rp, x, y }
  end)
  bt:SetScript("OnClick", function() ns.alternarJanela() end)
  bt:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("GuiaForever")
    GameTooltip:AddLine("Clique: abre e fecha o guia (tecla J)", 1, 1, 1)
    GameTooltip:AddLine("Arraste para mover", 1, 1, 1)
    GameTooltip:Show()
  end)
  bt:SetScript("OnLeave", function() GameTooltip:Hide() end)
  local pos = GuiaForeverDB.botao
  bt:ClearAllPoints()
  if pos and pos[1] then
    bt:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3] or 0, pos[4] or 0)
  elseif Minimap then
    bt:SetPoint("TOPRIGHT", Minimap, "BOTTOMLEFT", -2, -2)
  else
    bt:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -220)
  end
end

-- Tecla J: liga uma vez por personagem, so se estiver livre.
local function ligarTecla()
  if not (GetBindingAction and SetBinding and SaveBindings) then return end
  local chave = ns.chavePersonagem()
  if not chave or ns.emCombate() then return end
  GuiaForeverDB.tecla = GuiaForeverDB.tecla or {}
  if GuiaForeverDB.tecla[chave] then return end
  local ja = GetBindingKey and GetBindingKey("GUIAFOREVER_JANELA")
  if ja then
    GuiaForeverDB.tecla[chave] = { existente = ja }
    return
  end
  local atual = GetBindingAction("J") or ""
  if atual == "" then
    if pcall(SetBinding, "J", "GUIAFOREVER_JANELA") then
      pcall(SaveBindings, (GetCurrentBindingSet and GetCurrentBindingSet()) or 1)
      GuiaForeverDB.tecla[chave] = { ligada = "J" }
      ns.msg("a tecla J abre e fecha o guia (desfazer: /guia tecla desfazer).")
    end
  else
    GuiaForeverDB.tecla[chave] = { ocupada = atual }
    ns.msg("a tecla J ja faz " .. atual .. "; abra o guia pelo botao do livro ou /guia, "
      .. "ou escolha uma tecla em Opcoes > Teclas > AddOns > GuiaForever.")
  end
end

function ns.desfazerTecla()
  local chave = ns.chavePersonagem()
  local r = chave and GuiaForeverDB.tecla and GuiaForeverDB.tecla[chave]
  if not r or not r.ligada then ns.msg("tecla: nada para desfazer neste personagem."); return end
  if ns.emCombate() then ns.msg("tecla: em combate, tente de novo fora dele."); return end
  if GetBindingAction(r.ligada) == "GUIAFOREVER_JANELA" then
    pcall(SetBinding, r.ligada)
    pcall(SaveBindings, (GetCurrentBindingSet and GetCurrentBindingSet()) or 1)
  end
  GuiaForeverDB.tecla[chave] = { desfeito = true }
  ns.msg("tecla " .. r.ligada .. " devolvida (o botao do livro e o /guia continuam).")
end

table.insert(ns.aoEntrar, ligarTecla)

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  GuiaForeverDB = GuiaForeverDB or {}
  criarBotao()
end)
