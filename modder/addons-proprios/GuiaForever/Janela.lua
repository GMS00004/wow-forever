-- GuiaForever: janela J 1.2, a casca (cabecalho de estado, trilho de navegacao, busca, sub-abas,
-- redimensionar, "Show all"). Nao constroi conteudo de aba: os construtores ficam em
-- ns.abasConstrutores (Abas.lua e modulos) e o desenho em ns.ui.desenhar (Visual.lua).
-- Tambem: botao do livro perto do minimapa e tecla J.
-- Contrato: ARQUITETURA.md, secoes 1 e 11.

local _, ns = ...

local LARG_TRILHO, ALT_CAB, ALT_NAV = 150, 48, 34
local LARG_PADRAO, ALT_PADRAO = 820, 600
local MIN_W, MIN_H, MAX_W, MAX_H = 700, 460, 1200, 900
local PONTO = "\194\183" -- ponto medio (UTF-8)
local MSG_REINICIO = "GuiaForever 1.2: restart the game to load the new window (/reload does not load new files)."

local ABAS = {
  { id = "agora", rotulo = "Now", icone = "Interface\\Icons\\INV_Misc_Book_09", subs = {} },
  { id = "pet", rotulo = "Pet", icone = "Interface\\Icons\\Ability_Hunter_BeastCall", subs = {} },
  { id = "familias", rotulo = "Families", icone = "Interface\\Icons\\Ability_Hunter_BeastTaming", subs = {} },
  { id = "talentos", rotulo = "Talents", icone = "Interface\\Icons\\Ability_Marksmanship", subs = {} },
  { id = "combate", rotulo = "Combat", icone = "Interface\\Icons\\Ability_ImpalingBolt", subs = {
    { id = "rotacao", rotulo = "Rotation" }, { id = "teclas", rotulo = "Keys" },
    { id = "armas", rotulo = "Weapons" }, { id = "atributos", rotulo = "Stats" },
  } },
  { id = "profissoes", rotulo = "Professions", icone = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01", subs = {
    { id = "minhas", rotulo = "Mine" }, { id = "zona", rotulo = "Zone" }, { id = "treinos", rotulo = "Trainers" },
  } },
  { id = "crafts", rotulo = "Crafts", icone = "Interface\\Icons\\INV_Misc_ArmorKit_17", subs = {} },
  { id = "ajuda", rotulo = "Help", icone = "Interface\\Icons\\INV_Misc_QuestionMark", subs = {
    { id = "perguntas", rotulo = "Questions" }, { id = "addons", rotulo = "Addons" }, { id = "sinais", rotulo = "Signs" },
  } },
}
ns.abas = ABAS -- o /guia confere os ids na hora do comando
-- ids antigos (10 abas) -> { aba, sub }; vale para ns.abrirAba e para o /guia
ns.apelidosAba = {
  nivel = { aba = "agora" }, pets = { aba = "pet" },
  armas = { aba = "combate", sub = "armas" }, rotacao = { aba = "combate", sub = "rotacao" },
  teclas = { aba = "combate", sub = "teclas" },
  prof = { aba = "profissoes", sub = "minhas" }, zona = { aba = "profissoes", sub = "zona" },
  treinos = { aba = "profissoes", sub = "treinos" },
  addons = { aba = "ajuda", sub = "addons" },
}

local janela, rolagem, conteudo, trilho, caixaBusca, caixaTudo, dicaBusca, subtitulo
local botoesNav = {}
local etiquetas = {}
local modoSimples = false
local abaAtual
local tudo = false      -- chave "Show all"
local textoBusca = ""   -- busca ativa (minuscula); "" = sem busca
local ultimaChave

local function seguro(fn, ...)
  if type(fn) ~= "function" then return false end
  local n = select("#", ...)
  local args = { ... }
  return xpcall(function() return fn(unpack(args, 1, n)) end, geterrorhandler())
end

local function agendar(chave, segundos, fn)
  if ns.agendar then ns.agendar(chave, segundos, fn) else seguro(fn) end
end

-- Blocos compativeis (Teclas, Zona e Treinadores ainda os usam; o desenhista os aceita)
local function T(b, s) b[#b + 1] = { t = "texto", s = s } end
local function cab(b, s) T(b, " "); T(b, ns.COR .. s .. ns.FIM) end
ns.blocoTexto, ns.blocoCabecalho = T, cab
ns.blocoBotao = function(b, s, f) b[#b + 1] = { t = "botao", s = s, f = f } end

local function nivelJogador() return UnitLevel("player") or 1 end

-- tira os codigos de cor para buscar
local function limpar(s)
  return (tostring(s):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

-- Abas ---------------------------------------------------------------
local function acharAba(id)
  for _, a in ipairs(ABAS) do
    if a.id == id then return a end
  end
end

local function temSub(aba, sub)
  for _, s in ipairs(aba.subs) do
    if s.id == sub then return true end
  end
  return false
end

-- id novo ou antigo -> aba e sub (sub pode ser nil)
local function resolver(id)
  local a = acharAba(id)
  if a then return a, nil end
  local ap = ns.apelidosAba[id]
  if type(ap) == "table" then return acharAba(ap.aba) or ABAS[1], ap.sub end
  if type(ap) == "string" then return acharAba(ap) or ABAS[1], nil end
  return ABAS[1], nil
end

local function subAtual(aba)
  if #aba.subs == 0 then return nil end
  local db = GuiaForeverDB and GuiaForeverDB.sub
  local s = type(db) == "table" and db[aba.id]
  if s and temSub(aba, s) then return s end
  return aba.subs[1].id
end

local function larguraArea()
  local w = janela and janela:GetWidth() or LARG_PADRAO
  return w - LARG_TRILHO - 44
end

local atualizar -- definida adiante

local function ctxPara(aba, sub)
  return {
    nivel = nivelJogador(),
    classe = ns.classe and ns.classe() or nil,
    tudo = tudo,
    sub = sub,
    largura = larguraArea(),
    atualizar = function() if atualizar then atualizar() end end,
    abrir = function(a, s) if ns.abrirAba then ns.abrirAba(a, s) end end,
  }
end

local function construir(aba, sub, ctx)
  local fn = ns.abasConstrutores and ns.abasConstrutores[aba.id]
  if type(fn) ~= "function" then return { { t = "vazio", s = "This tab is not ready yet." } } end
  local b = {}
  local ok = xpcall(function() fn(b, ctx) end, geterrorhandler())
  if not ok then return { { t = "vazio", s = "This tab hit an error (see BugSack)." } } end
  return b
end

-- itens do contador do Now: os do painel menos os escondidos (mesma regra do painel)
local function contarAgora()
  local itens, ocultos = {}, {}
  if ns.agora and ns.agora.itens then
    local ok, r = pcall(ns.agora.itens)
    if ok and type(r) == "table" then itens = r end
  end
  if ns.agora and ns.agora.ocultos then
    local ok, r = pcall(ns.agora.ocultos)
    if ok and type(r) == "table" then ocultos = r end
  end
  local n = 0
  for _, it in ipairs(itens) do
    if not (ocultos[it.chave] ~= nil and ocultos[it.chave] == tostring(it.texto)) then n = n + 1 end
  end
  return n
end

local function estadoAbas()
  if type(ns.abasEstado) ~= "function" then return {} end
  local ok, r = xpcall(ns.abasEstado, geterrorhandler())
  if ok and type(r) == "table" then return r end
  return {}
end

local function abaVisivel(id)
  if type(ns.abaVisivel) ~= "function" then return true end
  local ok, r = xpcall(ns.abaVisivel, geterrorhandler(), id)
  if not ok then return true end
  return r and true or false
end

-- Busca ----------------------------------------------------------------
local function txtCelula(v)
  if type(v) == "table" then return v.s ~= nil and tostring(v.s) or "" end
  if v == nil then return "" end
  return tostring(v)
end

-- junta em `saida` os textos pesquisaveis de um bloco: { s, sub }
local function textosDoBloco(bl, saida)
  if type(bl) ~= "table" then return end
  local t = bl.t
  if t == "segs" or t == "botao" or t == "vazio" or t == "espaco" then return end
  local function add(s, sub)
    if s == nil or tostring(s) == "" then return end
    saida[#saida + 1] = { s = tostring(s), sub = (sub ~= nil and tostring(sub) ~= "") and tostring(sub) or nil }
  end
  if t == "tabela" then
    for _, ln in ipairs(bl.linhas or {}) do
      local partes = {}
      for _, c in ipairs(ln.celulas or {}) do
        local x = txtCelula(c)
        if x ~= "" then partes[#partes + 1] = x end
      end
      if #partes > 0 then add(partes[1], table.concat(partes, " - ", 2)) end
    end
  elseif t == "duas" then
    for _, e in ipairs(bl.lista or {}) do add(e.s, e.sub) end
    for _, x in ipairs(bl.detalhe or {}) do textosDoBloco(x, saida) end
  elseif t == "checklist" then
    for _, e in ipairs(bl.itens or {}) do add(e.s, e.sub) end
  elseif t == "grade" then
    for _, k in ipairs(bl.teclas or {}) do
      if type(k) == "table" then add(k.nome or k.k) end
    end
  elseif t == "regua" then
    for _, ln in ipairs(bl.linhas or {}) do add(ln.nome) end
  elseif t == "passos" then
    for _, x in ipairs(bl.lista or {}) do add(x) end
  elseif t == "perfil" then
    add(bl.titulo)
  else
    add(bl.s or bl.nome, bl.sub or (bl.s and bl.nome or nil))
  end
end

local function cortar(s, max)
  if #s <= max then return s end
  local c = max - 3
  while c > 0 do
    local by = string.byte(s, c + 1)
    if by and by >= 128 and by < 192 then c = c - 1 else break end
  end
  return string.sub(s, 1, c) .. "..."
end

-- roda os construtores de todas as abas e sub-abas e devolve a lista de blocos do resultado
function ns.buscarJanela(texto)
  local q = string.lower(strtrim and strtrim(tostring(texto or "")) or tostring(texto or ""))
  if string.len(q) < 2 then return {} end
  local saida = {}
  for _, aba in ipairs(ABAS) do
    local subs = #aba.subs > 0 and aba.subs or { { id = nil, rotulo = nil } }
    for _, sb in ipairs(subs) do
      local ctx = ctxPara(aba, sb.id)
      local blocos = construir(aba, sb.id, ctx)
      local textos = {}
      for _, bl in ipairs(blocos) do textosDoBloco(bl, textos) end
      local itens, vistos = {}, {}
      for _, x in ipairs(textos) do
        local s = limpar(x.s)
        local sub = x.sub and limpar(x.sub) or nil
        local alvo = string.lower(s .. " " .. (sub or ""))
        if string.find(alvo, q, 1, true) and not vistos[alvo] then
          vistos[alvo] = true
          local dica = nil
          if #s > 60 then dica = s; s = cortar(s, 60) end
          if sub and #sub > 80 then sub = cortar(sub, 80) end
          local abaId, subId = aba.id, sb.id
          itens[#itens + 1] = {
            t = "item", s = s, sub = sub, dica = dica,
            aoClicar = function() if ns.abrirAba then ns.abrirAba(abaId, subId) end end,
          }
        end
      end
      if #itens > 0 then
        local rotulo = aba.rotulo .. (sb.rotulo and (" " .. PONTO .. " " .. sb.rotulo) or "")
        saida[#saida + 1] = { t = "sec", s = rotulo, id = "busca:" .. aba.id .. (sb.id and (":" .. sb.id) or ""), qtd = #itens, limite = 30 }
        for _, it in ipairs(itens) do saida[#saida + 1] = it end
      end
    end
  end
  if #saida == 0 then saida[1] = { t = "vazio", s = "No match for \"" .. q .. "\"." } end
  return saida
end

-- Janela -------------------------------------------------------------
local function salvarPosicao()
  if not janela then return end
  local p, _, rp, x, y = janela:GetPoint()
  GuiaForeverDB = GuiaForeverDB or {}
  GuiaForeverDB.pos = { p, rp, x, y }
end

local function salvarTamanho()
  if not janela or modoSimples then return end
  local w, h = janela:GetSize()
  GuiaForeverDB = GuiaForeverDB or {}
  GuiaForeverDB.janela = { w = math.floor((w or LARG_PADRAO) + 0.5), h = math.floor((h or ALT_PADRAO) + 0.5) }
end

local function tamanhoSalvo()
  local j = GuiaForeverDB and GuiaForeverDB.janela
  local w = type(j) == "table" and tonumber(j.w) or LARG_PADRAO
  local h = type(j) == "table" and tonumber(j.h) or ALT_PADRAO
  return math.max(MIN_W, math.min(MAX_W, w)), math.max(MIN_H, math.min(MAX_H, h))
end

local function posicionar()
  local pos = GuiaForeverDB.pos
  janela:ClearAllPoints()
  if pos and pos[1] then
    janela:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3] or 0, pos[4] or 0)
  else
    janela:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
end

local function tornarMovel(f)
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    salvarPosicao()
  end)
end

local function limparBusca()
  textoBusca = ""
  if caixaBusca and caixaBusca:GetText() ~= "" then caixaBusca:SetText("") end
end

local function aoMudarBusca()
  if not caixaBusca then return end
  local q = string.lower(strtrim and strtrim(caixaBusca:GetText() or "") or (caixaBusca:GetText() or ""))
  if string.len(q) < 2 then q = "" end
  if q == textoBusca then return end
  textoBusca = q
  atualizar()
end

-- cabecalho, etiquetas e trilho (so estado; o conteudo vem do desenhista)
local function atualizarCabecalho()
  local nome = (UnitName and UnitName("player")) or "?"
  local classe = UnitClass and (UnitClass("player")) or ""
  subtitulo:SetText(tostring(nome) .. " " .. PONTO .. " " .. tostring(classe) .. " " .. PONTO .. " level " .. nivelJogador())
  local est = estadoAbas()
  local prev
  for i = 1, 3 do
    local et, e = etiquetas[i], est[i]
    if e then
      et:Definir(e.icone, e.s, e.n, e.cor)
      et.alvo = e
      et:ClearAllPoints()
      if prev then
        et:SetPoint("RIGHT", prev, "LEFT", -6, 0)
      else
        et:SetPoint("RIGHT", caixaBusca, "LEFT", -12, 0)
      end
      et:Show()
      prev = et
    else
      et.alvo = nil
      et:Hide()
    end
  end
end

local function atualizarTrilho()
  local y = 8
  local contador = contarAgora()
  for _, aba in ipairs(ABAS) do
    local bt = botoesNav[aba.id]
    if bt then
      if abaVisivel(aba.id) then
        bt:ClearAllPoints()
        bt:SetPoint("TOPLEFT", trilho, "TOPLEFT", 0, -y)
        y = y + ALT_NAV
        local ativo = (aba.id == abaAtual and textoBusca == "")
        if ativo then bt.fundo:Show(); bt.faixa:Show() else bt.fundo:Hide(); bt.faixa:Hide() end
        bt.faixa:SetColorTexture(ns.ui.cor("destaque"))
        if aba.id == "agora" and contador > 0 then bt.num:SetText(tostring(contador)) else bt.num:SetText("") end
        bt:Show()
      else
        bt:Hide()
      end
    end
  end
end

atualizar = function()
  if not janela or modoSimples or not janela:IsShown() then return end
  local aba = acharAba(abaAtual) or ABAS[1]
  local sub = subAtual(aba)
  local ctx = ctxPara(aba, sub)
  local blocos
  if textoBusca ~= "" then
    blocos = ns.buscarJanela(textoBusca)
  else
    blocos = construir(aba, sub, ctx)
  end
  conteudo:SetWidth(ctx.largura)
  seguro(function()
    local h = ns.ui.desenhar(conteudo, blocos, ctx.largura, ctx)
    conteudo:SetHeight(math.max(tonumber(h) or 10, 10))
  end)
  local chave = aba.id .. "|" .. tostring(sub) .. "|" .. textoBusca
  if chave ~= ultimaChave then
    ultimaChave = chave
    if rolagem then rolagem:SetVerticalScroll(0) end
  end
  seguro(atualizarCabecalho)
  seguro(atualizarTrilho)
end
ns.atualizarJanela = atualizar

local function criarNav(aba)
  local UI = ns.ui
  local bt = CreateFrame("Button", nil, trilho)
  bt:SetSize(LARG_TRILHO, ALT_NAV)
  bt.fundo = bt:CreateTexture(nil, "BACKGROUND")
  bt.fundo:SetAllPoints()
  bt.fundo:SetColorTexture(1, 1, 1, 0.07)
  bt.fundo:Hide()
  bt.hover = bt:CreateTexture(nil, "BACKGROUND")
  bt.hover:SetAllPoints()
  bt.hover:SetColorTexture(1, 1, 1, 0.04)
  bt.hover:Hide()
  bt.faixa = bt:CreateTexture(nil, "ARTWORK")
  bt.faixa:SetWidth(3)
  bt.faixa:SetPoint("TOPLEFT", bt, "TOPLEFT", 0, 0)
  bt.faixa:SetPoint("BOTTOMLEFT", bt, "BOTTOMLEFT", 0, 0)
  bt.faixa:SetColorTexture(UI.cor("destaque"))
  bt.faixa:Hide()
  local ic = bt:CreateTexture(nil, "ARTWORK")
  ic:SetSize(20, 20)
  ic:SetPoint("LEFT", bt, "LEFT", 12, 0)
  ic:SetTexture(UI.icone(aba.icone))
  ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  bt.rot = bt:CreateFontString(nil, "OVERLAY", UI.fonte("nav"))
  bt.rot:SetPoint("LEFT", ic, "RIGHT", 8, 0)
  bt.rot:SetJustifyH("LEFT")
  bt.rot:SetText(aba.rotulo)
  bt.num = bt:CreateFontString(nil, "OVERLAY", UI.fonte("numero"))
  bt.num:SetPoint("RIGHT", bt, "RIGHT", -10, 0)
  bt.num:SetTextColor(UI.cor("laranja"))
  local id = aba.id
  bt:SetScript("OnClick", function() seguro(function() ns.abrirAba(id) end) end)
  bt:SetScript("OnEnter", function(self) self.hover:Show() end)
  bt:SetScript("OnLeave", function(self) self.hover:Hide() end)
  botoesNav[id] = bt
end

-- quadro simples para o jogo aberto antes de Visual.lua entrar no .toc
local function criarSimples()
  modoSimples = true
  janela = CreateFrame("Frame", "GuiaForeverJanela", UIParent, "BackdropTemplate")
  janela:SetSize(520, 64)
  tornarMovel(janela)
  if janela.SetBackdrop then
    janela:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 14,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
  end
  local fs = janela:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetPoint("TOPLEFT", janela, "TOPLEFT", 14, -14)
  fs:SetWidth(492)
  fs:SetJustifyH("LEFT")
  fs:SetText(MSG_REINICIO)
  posicionar()
  if UISpecialFrames then tinsert(UISpecialFrames, "GuiaForeverJanela") end -- Esc fecha
  janela:Hide()
end

local function criarJanela()
  if janela then return end
  GuiaForeverDB = GuiaForeverDB or {}
  local UI = ns.ui
  if not (type(UI) == "table" and type(UI.desenhar) == "function") then
    criarSimples()
    return
  end

  janela = CreateFrame("Frame", "GuiaForeverJanela", UIParent, "BackdropTemplate")
  local w, h = tamanhoSalvo()
  janela:SetSize(w, h)
  tornarMovel(janela)
  UI.painel(janela, "janela")
  janela:SetResizable(true)
  if janela.SetResizeBounds then
    janela:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
  else
    if janela.SetMinResize then janela:SetMinResize(MIN_W, MIN_H) end
    if janela.SetMaxResize then janela:SetMaxResize(MAX_W, MAX_H) end
  end

  -- cabecalho
  local livro = janela:CreateTexture(nil, "ARTWORK")
  livro:SetSize(28, 28)
  livro:SetPoint("TOPLEFT", janela, "TOPLEFT", 12, -10)
  livro:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  livro:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local titulo = janela:CreateFontString(nil, "OVERLAY", UI.fonte("titulo"))
  titulo:SetPoint("TOPLEFT", janela, "TOPLEFT", 48, -7)
  titulo:SetJustifyH("LEFT")
  titulo:SetText("GuiaForever")
  subtitulo = janela:CreateFontString(nil, "OVERLAY", UI.fonte("menor"))
  subtitulo:SetPoint("TOPLEFT", janela, "TOPLEFT", 48, -27)
  subtitulo:SetJustifyH("LEFT")
  subtitulo:SetTextColor(UI.cor("cinza"))

  local fechar = CreateFrame("Button", nil, janela, "UIPanelCloseButton")
  fechar:SetSize(28, 28)
  fechar:SetPoint("TOPRIGHT", janela, "TOPRIGHT", -6, -10)
  UI.skinFechar(fechar)

  -- busca (a partir de 2 letras mostra os achados de todas as abas)
  caixaBusca = CreateFrame("EditBox", nil, janela, "BackdropTemplate")
  caixaBusca:SetSize(150, 24)
  caixaBusca:SetPoint("RIGHT", fechar, "LEFT", -6, 0)
  caixaBusca:SetAutoFocus(false)
  caixaBusca:SetFontObject(UI.fonte("texto"))
  UI.skinBusca(caixaBusca)
  dicaBusca = caixaBusca:CreateFontString(nil, "OVERLAY", UI.fonte("menor"))
  dicaBusca:SetPoint("LEFT", caixaBusca, "LEFT", 8, 0)
  dicaBusca:SetTextColor(UI.cor("cinza"))
  dicaBusca:SetText("Search")
  caixaBusca:SetScript("OnTextChanged", function(self)
    if (self:GetText() or "") == "" then dicaBusca:Show() else dicaBusca:Hide() end
    agendar("janela:busca", 0.25, aoMudarBusca)
  end)
  caixaBusca:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    self:ClearFocus()
  end)
  caixaBusca:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

  for i = 1, 3 do
    local et = UI.etiqueta(janela)
    et:EnableMouse(true)
    et:SetScript("OnMouseUp", function(self)
      local e = self.alvo
      if e and e.aba then seguro(function() ns.abrirAba(e.aba, e.sub) end) end
    end)
    et:Hide()
    etiquetas[i] = et
  end

  -- trilho
  trilho = CreateFrame("Frame", nil, janela)
  trilho:SetPoint("TOPLEFT", janela, "TOPLEFT", 1, -ALT_CAB)
  trilho:SetPoint("BOTTOMLEFT", janela, "BOTTOMLEFT", 1, 1)
  trilho:SetWidth(LARG_TRILHO)
  local fundoTrilho = trilho:CreateTexture(nil, "BACKGROUND")
  fundoTrilho:SetAllPoints()
  fundoTrilho:SetColorTexture(0, 0, 0, 0.28)
  local bordaTrilho = trilho:CreateTexture(nil, "BORDER")
  bordaTrilho:SetWidth(1)
  bordaTrilho:SetPoint("TOPRIGHT", trilho, "TOPRIGHT", 0, 0)
  bordaTrilho:SetPoint("BOTTOMRIGHT", trilho, "BOTTOMRIGHT", 0, 0)
  bordaTrilho:SetColorTexture(0, 0, 0, 1)
  for _, aba in ipairs(ABAS) do criarNav(aba) end

  -- Show all: volta PvP, grupo, fim de jogo e escolha de pet (ctx.tudo)
  caixaTudo = CreateFrame("CheckButton", nil, trilho, "UICheckButtonTemplate")
  caixaTudo:SetSize(24, 24)
  caixaTudo:SetPoint("BOTTOMLEFT", trilho, "BOTTOMLEFT", 10, 10)
  caixaTudo:SetChecked(false)
  UI.skinCaixa(caixaTudo)
  local rotuloTudo = trilho:CreateFontString(nil, "OVERLAY", UI.fonte("nav"))
  rotuloTudo:SetPoint("LEFT", caixaTudo, "RIGHT", 6, 0)
  rotuloTudo:SetText("Show all")
  caixaTudo:SetScript("OnClick", function(self)
    tudo = self:GetChecked() and true or false
    seguro(atualizar)
  end)
  caixaTudo:SetScript("OnEnter", function(self)
    seguro(function()
      UI.tooltip(self, "Show all", "Also shows PvP, group, end-game and pet-choice tips that are hidden for now.")
    end)
  end)
  caixaTudo:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- area com rolagem
  rolagem = CreateFrame("ScrollFrame", "GuiaForeverRolagem", janela, "UIPanelScrollFrameTemplate")
  rolagem:SetPoint("TOPLEFT", trilho, "TOPRIGHT", 16, -12)
  rolagem:SetPoint("BOTTOMRIGHT", janela, "BOTTOMRIGHT", -28, 12)
  UI.skinRolagem(rolagem)
  conteudo = CreateFrame("Frame", nil, rolagem)
  conteudo:SetSize(larguraArea(), 10)
  rolagem:SetScrollChild(conteudo)

  -- alca de redimensionar no canto
  local alca = CreateFrame("Button", nil, janela)
  alca:SetSize(16, 16)
  alca:SetPoint("BOTTOMRIGHT", janela, "BOTTOMRIGHT", -2, 2)
  alca:SetFrameLevel((janela:GetFrameLevel() or 1) + 10)
  alca:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  alca:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  alca:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  alca:SetScript("OnMouseDown", function(_, botao)
    if botao == "LeftButton" then janela:StartSizing("BOTTOMRIGHT") end
  end)
  alca:SetScript("OnMouseUp", function()
    janela:StopMovingOrSizing()
    salvarTamanho()
    salvarPosicao()
    agendar("janela:tamanho", 0.05, atualizar)
  end)
  janela:SetScript("OnSizeChanged", function()
    if not conteudo then return end
    conteudo:SetWidth(larguraArea())
    agendar("janela:tamanho", 0.1, function()
      salvarTamanho()
      atualizar()
    end)
  end)

  posicionar()
  janela:SetScript("OnShow", function() seguro(atualizar) end)
  janela:SetScript("OnHide", function()
    tudo = false
    if caixaTudo then caixaTudo:SetChecked(false) end
    if caixaBusca then caixaBusca:ClearFocus() end
    GameTooltip:Hide()
  end)
  if UISpecialFrames then tinsert(UISpecialFrames, "GuiaForeverJanela") end -- Esc fecha
  abaAtual = (resolver(GuiaForeverDB.aba or "agora")).id
  janela:Hide()
end

function ns.alternarJanela()
  criarJanela()
  if janela:IsShown() then janela:Hide() else janela:Show() end
end

-- aceita os ids novos e os antigos (ns.apelidosAba); sub opcional
function ns.abrirAba(id, sub)
  criarJanela()
  if modoSimples then
    janela:Show()
    return
  end
  local aba, subAp = resolver(id)
  abaAtual = aba.id
  GuiaForeverDB.aba = aba.id
  local s = sub or subAp
  if s and temSub(aba, s) then
    GuiaForeverDB.sub = GuiaForeverDB.sub or {}
    GuiaForeverDB.sub[aba.id] = s
  end
  limparBusca()
  if janela:IsShown() then atualizar() else janela:Show() end
end

-- Atalho de tecla (Bindings.xml) e nomes no menu de teclas.
BINDING_HEADER_GUIAFOREVER = "GuiaForever"
_G["BINDING_NAME_GUIAFOREVER_JANELA"] = "Open/close the guide"
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
    GameTooltip:AddLine("Click: open/close the guide (J key)", 1, 1, 1)
    GameTooltip:AddLine("Drag to move", 1, 1, 1)
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
      ns.msg("the J key opens/closes the guide (undo: /guia key undo).")
    end
  else
    GuiaForeverDB.tecla[chave] = { ocupada = atual }
    ns.msg("the J key is already bound to " .. atual .. "; open the guide with the book button or /guia, "
      .. "or pick a key in Options > Key Bindings > AddOns > GuiaForever.")
  end
end

function ns.desfazerTecla()
  local chave = ns.chavePersonagem()
  local r = chave and GuiaForeverDB.tecla and GuiaForeverDB.tecla[chave]
  if not r or not r.ligada then ns.msg("key: nothing to undo for this character."); return end
  if ns.emCombate() then ns.msg("key: in combat, try again out of combat."); return end
  if GetBindingAction(r.ligada) == "GUIAFOREVER_JANELA" then
    pcall(SetBinding, r.ligada)
    pcall(SaveBindings, (GetCurrentBindingSet and GetCurrentBindingSet()) or 1)
  end
  GuiaForeverDB.tecla[chave] = { desfeito = true }
  ns.msg("key " .. r.ligada .. " released (the book button and /guia still work).")
end

table.insert(ns.aoEntrar, ligarTecla)

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  GuiaForeverDB = GuiaForeverDB or {}
  criarBotao()
end)
