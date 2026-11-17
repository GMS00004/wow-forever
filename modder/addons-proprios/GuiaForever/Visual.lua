-- GuiaForever: ns.ui, a aparencia da janela J (1.2): skin do ElvUI com reserva propria,
-- fontes, cores, icones e o desenhista dos blocos.
-- Contrato: ARQUITETURA.md, secoes 11.4 e 11.5.
-- Nada aqui e protegido (sem regra de combate). Os quadros so nascem quando a janela desenha.
-- Dos metodos de quadro, so GetStringHeight, GetStringWidth, GetWidth e GetHeight viram numero (sempre com "or 0").

local _, ns = ...
ns.ui = ns.ui or {}
local ui = ns.ui

local max, min, floor, ceil = math.max, math.min, math.floor, math.ceil
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ICO_PADRAO = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Utilidades ------------------------------------------------------------------

-- Regra 10: erro de callback vai para o BugSack, sem popup.
local function seguro(fn, ...)
  if type(fn) ~= "function" then return false end
  local n = select("#", ...)
  local args = { ... }
  return xpcall(function() return fn(unpack(args, 1, n)) end, geterrorhandler())
end

local function dbtab(nome)
  if type(GuiaForeverDB) ~= "table" then return nil end
  if type(GuiaForeverDB[nome]) ~= "table" then GuiaForeverDB[nome] = {} end
  return GuiaForeverDB[nome]
end

local function atualizarCtx(ctx)
  if type(ctx) == "table" and type(ctx.atualizar) == "function" then seguro(ctx.atualizar) end
end

local function limpar(s)
  s = tostring(s or "")
  s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  return s
end

local function vis(o, cond)
  if cond then o:Show() else o:Hide() end
end

-- Cores ------------------------------------------------------------------------

local CORES = {
  fundo = { 0.05, 0.05, 0.05, 0.92 },
  borda = { 0, 0, 0, 1 },
  zebra = { 1, 1, 1, 0.035 },
  cinza = { 0.6, 0.6, 0.6, 1 },
  texto = { 1, 1, 1, 1 },
  verde = { 0.3, 0.85, 0.3, 1 },
  vermelho = { 0.9, 0.2, 0.2, 1 },
  laranja = { 1, 0.55, 0.1, 1 },
  amarelo = { 1, 0.85, 0.1, 1 },
  azul = { 0.3, 0.6, 1, 1 },
  dourado = { 1, 0.82, 0, 1 },
}
local RESERVA_DEST = { 0.67, 0.83, 0.45, 1 }
local destCache = nil

local function corDestaque()
  if destCache then return destCache end
  local r, g, b
  pcall(function()
    local _, token = UnitClass("player")
    if token and C_ClassColor and C_ClassColor.GetClassColor then
      local c = C_ClassColor.GetClassColor(token)
      if c then r, g, b = c.r, c.g, c.b end
    end
  end)
  if type(r) == "number" and type(g) == "number" and type(b) == "number" then
    destCache = { r, g, b, 1 }
    return destCache
  end
  return RESERVA_DEST
end

function ui.cor(nome)
  local t = (nome == "destaque") and corDestaque() or CORES[nome] or CORES.texto
  return t[1], t[2], t[3], t[4] or 1
end

function ui.hex(nome)
  local r, g, b = ui.cor(nome)
  return string.format("|cff%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

-- ElvUI (sempre em pcall, com checagem de existencia) --------------------------------

local function elv()
  local E
  pcall(function()
    local g = _G.ElvUI
    if type(g) == "table" then E = g[1] end
  end)
  if type(E) == "table" then return E end
  return nil
end

local function skins()
  local E = elv()
  if not E then return nil end
  local S
  pcall(function()
    if type(E.GetModule) == "function" then S = E:GetModule("Skins", true) end
  end)
  if type(S) == "table" then return S end
  return nil
end

-- Chama S:<metodo>(...) em pcall. Devolve true so se existiu e nao falhou.
local function skinE(metodo, ...)
  local S = skins()
  if not S or type(S[metodo]) ~= "function" then return false end
  local n = select("#", ...)
  local args = { ... }
  local ok = pcall(function() S[metodo](S, unpack(args, 1, n)) end)
  return ok
end

-- Fontes -----------------------------------------------------------------------------

local ARQ_PT = "Interface\\AddOns\\ElvUI\\Game\\Shared\\Media\\Fonts\\PTSansNarrow.ttf"
local ARQ_EXP = "Interface\\AddOns\\ElvUI\\Game\\Shared\\Media\\Fonts\\Expressway.ttf"

local FONTES = {
  titulo = { "GuiaForeverFonteTitulo", 17, "pt", "" },
  nav = { "GuiaForeverFonteNav", 15, "pt", "" },
  cartao = { "GuiaForeverFonteCartao", 15, "pt", "" },
  texto = { "GuiaForeverFonteTexto", 14, "pt", "" },
  menor = { "GuiaForeverFonteMenor", 12, "pt", "" },
  mini = { "GuiaForeverFonteMini", 11, "pt", "" },
  detalhe = { "GuiaForeverFonteDetalhe", 20, "pt", "" },
  secao = { "GuiaForeverFonteSecao", 12, "exp", "" },
  numero = { "GuiaForeverFonteNumero", 12, "exp", "" },
  tecla = { "GuiaForeverFonteTecla", 12, "exp", "OUTLINE" },
}
local fontesFeitas = {}

local function arquivosFonte(tipo)
  local lista = {}
  local nomeLsm = (tipo == "exp") and "Expressway" or "PT Sans Narrow"
  pcall(function()
    local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
    if lsm and type(lsm.Fetch) == "function" then
      local p = lsm:Fetch("font", nomeLsm, true)
      if type(p) == "string" and p ~= "" then lista[#lista + 1] = p end
    end
  end)
  if elv() then lista[#lista + 1] = (tipo == "exp") and ARQ_EXP or ARQ_PT end
  lista[#lista + 1] = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
  return lista
end

function ui.fonte(nome)
  local def = FONTES[nome] or FONTES.texto
  local gname = def[1]
  if fontesFeitas[gname] then return gname end
  if not CreateFont then return "GameFontNormal" end
  local ok, f = pcall(function() return _G[gname] or CreateFont(gname) end)
  if not ok or not f then return "GameFontNormal" end
  local aplicou = false
  for _, arq in ipairs(arquivosFonte(def[3])) do
    local ok2, r = pcall(function() return f:SetFont(arq, def[2], def[4]) end)
    if ok2 and r ~= false then aplicou = true break end
  end
  if not aplicou and GameFontNormal then pcall(function() f:SetFontObject(GameFontNormal) end) end
  pcall(function() f:SetShadowColor(0, 0, 0, 1) end)
  pcall(function() f:SetShadowOffset(1, -1) end)
  pcall(function() f:SetTextColor(1, 1, 1, 1) end)
  fontesFeitas[gname] = true
  return gname
end

-- Icones --------------------------------------------------------------------------------

function ui.icone(x)
  local r
  if type(x) == "number" then
    pcall(function()
      if C_Spell and C_Spell.GetSpellTexture then r = C_Spell.GetSpellTexture(x) end
    end)
    if r == nil then
      pcall(function()
        if GetSpellTexture then r = GetSpellTexture(x) end
      end)
    end
  elseif type(x) == "string" then
    if x:find("^Interface") then
      r = x
    elseif x:find("^macro:") then
      pcall(function()
        if GetMacroInfo then
          local _, ic = GetMacroInfo(x:sub(7))
          r = ic
        end
      end)
    elseif x:find("^item:") then
      -- icone de item pelo id (1.4): vem dos dados do cliente, sem esperar o cache do item
      local id = tonumber(x:sub(6))
      if id then
        pcall(function()
          if C_Item and C_Item.GetItemIconByID then r = C_Item.GetItemIconByID(id) end
        end)
      end
    end
  end
  if type(r) ~= "number" and type(r) ~= "string" then return ICO_PADRAO end
  if r == "" then return ICO_PADRAO end
  return r
end

-- Dinheiro em cobre -> texto com as moedas do jogo (1.4); sem a API, "1g 02s 03c". Negativo com "-".
function ui.moeda(cobre)
  local n = tonumber(cobre)
  if not n then return "-" end
  local neg = n < 0
  n = math.floor(math.abs(n) + 0.5)
  local s
  pcall(function()
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then s = C_CurrencyInfo.GetCoinTextureString(n) end
  end)
  if type(s) ~= "string" or s == "" then
    local g, p, c = math.floor(n / 10000), math.floor((n % 10000) / 100), n % 100
    local t = {}
    if g > 0 then t[#t + 1] = g .. "g" end
    if g > 0 or p > 0 then t[#t + 1] = (g > 0 and string.format("%02d", p) or tostring(p)) .. "s" end
    t[#t + 1] = ((g > 0 or p > 0) and string.format("%02d", c) or tostring(c)) .. "c"
    s = table.concat(t, " ")
  end
  return (neg and "-" or "") .. s
end

-- Painel e skins ---------------------------------------------------------------------------

local function backdropPlano(f, r, g, b, a)
  pcall(function()
    if not f.SetBackdrop and Mixin and BackdropTemplateMixin then Mixin(f, BackdropTemplateMixin) end
    if f.SetBackdrop then
      f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
      f:SetBackdropColor(r, g, b, a)
      f:SetBackdropBorderColor(0, 0, 0, 1)
    end
  end)
end

function ui.painel(f, estilo)
  if not f then return f end
  if elv() and f.SetTemplate then
    local ok = pcall(function()
      if estilo == "janela" then f:SetTemplate("Transparent") else f:SetTemplate() end
    end)
    if ok then return f end
  end
  if estilo == "campo" then
    backdropPlano(f, 0, 0, 0, 0.5)
  elseif estilo == "cartao" then
    backdropPlano(f, 1, 1, 1, 0.05)
  else
    local r, g, b, a = ui.cor("fundo")
    backdropPlano(f, r, g, b, a)
  end
  return f
end

local function planoBotao(b)
  if b._gfPlano then return end
  b._gfPlano = true
  pcall(function()
    for _, k in ipairs({ "Left", "Middle", "Right" }) do
      if b[k] then b[k]:SetAlpha(0) end
    end
    if b.SetNormalTexture then b:SetNormalTexture("") end
    if b.SetPushedTexture then b:SetPushedTexture("") end
    if b.SetHighlightTexture then b:SetHighlightTexture("") end
  end)
  backdropPlano(b, 1, 1, 1, 0.07)
  pcall(function()
    if b.HookScript then
      b:HookScript("OnEnter", function(self)
        if self.SetBackdropColor then self:SetBackdropColor(1, 1, 1, 0.14) end
      end)
      b:HookScript("OnLeave", function(self)
        if self.SetBackdropColor then self:SetBackdropColor(1, 1, 1, 0.07) end
      end)
    end
  end)
end

function ui.skinBotao(b)
  if not b then return end
  if skinE("HandleButton", b) then return end
  planoBotao(b)
end

function ui.skinRolagem(sf)
  if not sf then return end
  local barra
  pcall(function()
    barra = sf.ScrollBar
    if not barra and sf.GetName then
      local n = sf:GetName()
      if n then barra = _G[n .. "ScrollBar"] end
    end
  end)
  if barra then skinE("HandleScrollBar", barra) end
end

function ui.skinBusca(eb)
  if not eb then return end
  if skinE("HandleEditBox", eb) then return end
  ui.painel(eb, "campo")
  pcall(function()
    if eb.SetTextInsets then eb:SetTextInsets(6, 6, 0, 0) end
  end)
end

function ui.skinCaixa(cb)
  if not cb then return end
  skinE("HandleCheckBox", cb)
end

function ui.skinFechar(b)
  if not b then return end
  skinE("HandleCloseButton", b)
end

-- Pecas pequenas ------------------------------------------------------------------------------

local function tex(f, camada, sub)
  return f:CreateTexture(nil, camada or "ARTWORK", nil, sub or 0)
end

local function novoFs(f, fonte, cor, camada)
  local fs = f:CreateFontString(nil, camada or "OVERLAY")
  local nome = ui.fonte(fonte or "texto")
  fs:SetFontObject(_G[nome] or nome)
  fs:SetTextColor(ui.cor(cor or "texto"))
  fs:SetJustifyH("LEFT")
  return fs
end

local function larg(fs) return fs:GetStringWidth() or 0 end
local function alt(fs) return fs:GetStringHeight() or 0 end

local function bordas(f)
  local lados = {}
  local function t() local x = f:CreateTexture(nil, "BORDER"); x:SetColorTexture(0, 0, 0, 1); return x end
  local a = t(); a:SetHeight(1); a:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0); a:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
  local b = t(); b:SetHeight(1); b:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0); b:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
  local c = t(); c:SetWidth(1); c:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0); c:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
  local d = t(); d:SetWidth(1); d:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0); d:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
  lados[1], lados[2], lados[3], lados[4] = a, b, c, d
  return lados
end

local function novoIcone(f, tam)
  local preto = f:CreateTexture(nil, "BACKGROUND", nil, -1)
  preto:SetColorTexture(0, 0, 0, 1)
  local t = f:CreateTexture(nil, "ARTWORK")
  t:SetSize(tam, tam)
  preto:SetPoint("TOPLEFT", t, "TOPLEFT", -1, 1)
  preto:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 1, -1)
  t.preto = preto
  return t
end

local function mostraIcone(t, cond)
  if cond then t:Show(); t.preto:Show() else t:Hide(); t.preto:Hide() end
end

local function redondo(f, t)
  if not f.CreateMaskTexture then return end
  pcall(function()
    local m = f:CreateMaskTexture()
    m:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m:SetAllPoints(t)
    t:AddMaskTexture(m)
  end)
end

local ESTADO_TEX = {
  feito = "Interface\\RaidFrame\\ReadyCheck-Ready",
  falta = "Interface\\RaidFrame\\ReadyCheck-NotReady",
  travado = "Interface\\Buttons\\LockButton-Locked-Up",
}

-- Ponto central (cx) do slot; textura de 16 (ou 8 se for ponto de cor).
local function aplicaEstado(t, estado, f, cx)
  if not estado then t:Hide() return false end
  t:ClearAllPoints()
  t:SetPoint("CENTER", f, "LEFT", cx, 0)
  t:Show()
  if ESTADO_TEX[estado] then
    t:SetSize(16, 16)
    t:SetTexture(ESTADO_TEX[estado])
    t:SetTexCoord(0, 1, 0, 1)
    t:SetVertexColor(1, 1, 1, 1)
  else
    t:SetSize(8, 8)
    if estado == "agora" then t:SetColorTexture(ui.cor("dourado")) else t:SetColorTexture(0.45, 0.45, 0.45, 1) end
  end
  return true
end

-- Tooltip ----------------------------------------------------------------------------------

function ui.tooltip(dono, titulo, dica)
  if not GameTooltip or not dono then return end
  if dica == nil and titulo == nil then return end
  GameTooltip:SetOwner(dono, "ANCHOR_RIGHT")
  GameTooltip:SetText(limpar(titulo), 1, 1, 1, 1, true)
  local function linha(l)
    l = tostring(l)
    if l:find("^Source") then return end
    GameTooltip:AddLine(l, 0.9, 0.9, 0.9, true)
  end
  if type(dica) == "string" then
    linha(dica)
  elseif type(dica) == "table" then
    for _, l in ipairs(dica) do linha(l) end
  end
  GameTooltip:Show()
end

-- Tooltip de item (1.4): o do jogo pelo id, mais as linhas da dica. Em combate, so o texto.
function ui.tooltipItem(dono, id, titulo, dica)
  if not GameTooltip or not dono then return end
  local ok = false
  if not (InCombatLockdown and InCombatLockdown()) and GameTooltip.SetItemByID and tonumber(id) then
    GameTooltip:SetOwner(dono, "ANCHOR_RIGHT")
    ok = pcall(GameTooltip.SetItemByID, GameTooltip, tonumber(id))
  end
  if not ok then
    ui.tooltip(dono, titulo, dica)
    return
  end
  if type(dica) == "string" then
    GameTooltip:AddLine(dica, 0.9, 0.9, 0.9, true)
  elseif type(dica) == "table" then
    for _, l in ipairs(dica) do GameTooltip:AddLine(tostring(l), 0.9, 0.9, 0.9, true) end
  end
  GameTooltip:Show()
end

function ui.selecionado(id, padrao)
  local s = type(GuiaForeverDB) == "table" and GuiaForeverDB.sel
  if type(s) == "table" and s[id] ~= nil then return s[id] end
  return padrao
end

-- Botao e etiqueta --------------------------------------------------------------------------

function ui.botao(pai, rotulo, acao)
  local b = CreateFrame("Button", nil, pai, "BackdropTemplate")
  b:SetHeight(22)
  b.fs = novoFs(b, "menor", "texto")
  b.fs:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.fs:SetJustifyH("CENTER")
  b:SetScript("OnClick", function(self)
    if self.acao then seguro(self.acao) end
  end)
  function b:Definir(r, a)
    self.fs:SetText(tostring(r or ""))
    self.acao = a
    local w = max(larg(self.fs) + 20, 40)
    self:SetWidth(w)
    self.larg = w
  end
  b:Definir(rotulo or "", acao)
  ui.skinBotao(b)
  return b
end

function ui.etiqueta(pai)
  local f = CreateFrame("Frame", nil, pai)
  f:SetHeight(22)
  local bg = tex(f, "BACKGROUND", -2)
  bg:SetAllPoints()
  bg:SetColorTexture(1, 1, 1, 0.06)
  bordas(f)
  f.ic = tex(f, "ARTWORK")
  f.ic:SetSize(18, 18)
  f.fs = novoFs(f, "menor", "texto")
  f.fs:SetWordWrap(false)
  f.nm = novoFs(f, "numero", "texto")
  f.nm:SetWordWrap(false)
  function f:Definir(icone, s, n, cor, antes)
    local x = 6
    if icone ~= nil then
      self.ic:ClearAllPoints()
      self.ic:SetPoint("LEFT", self, "LEFT", x, 0)
      self.ic:SetTexture(ui.icone(icone))
      if type(icone) == "string" and not icone:find("Icons") and icone:find("^Interface") then
        self.ic:SetTexCoord(0, 1, 0, 1)
      else
        self.ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      end
      self.ic:Show()
      x = x + 22
    else
      self.ic:Hide()
    end
    local temN = n ~= nil and tostring(n) ~= ""
    if temN then
      self.nm:SetText(tostring(n))
      self.nm:SetTextColor(ui.cor(cor or "texto"))
    end
    local function colocar(fs, ativo)
      if not ativo then fs:Hide() return end
      fs:ClearAllPoints()
      fs:SetPoint("LEFT", self, "LEFT", x, 0)
      fs:Show()
      x = x + max(larg(fs), 6) + 5
    end
    self.fs:SetText(s ~= nil and tostring(s) or "")
    if antes then
      colocar(self.nm, temN)
      colocar(self.fs, s ~= nil)
    else
      colocar(self.fs, s ~= nil)
      colocar(self.nm, temN)
    end
    local w = max(x + 1, 24)
    self:SetWidth(w)
    self.larg = w
  end
  return f
end

local function novaTecla(pai)
  local f = CreateFrame("Frame", nil, pai)
  f:SetHeight(20)
  local bg = tex(f, "BACKGROUND", -2)
  bg:SetAllPoints()
  bg:SetColorTexture(1, 1, 1, 0.09)
  bordas(f)
  f.fs = novoFs(f, "tecla", "texto")
  f.fs:SetPoint("CENTER", f, "CENTER", 0, 0)
  f.fs:SetJustifyH("CENTER")
  function f:Definir(s)
    self.fs:SetText(tostring(s or ""))
    local w = max(larg(self.fs) + 12, 20)
    self:SetWidth(w)
    self.larg = w
  end
  return f
end

-- Base de linha clicavel (item, linha de tabela, item de lista) -----------------------------

local function entrar(self)
  if self.hl and (self.clicavel or self.dica ~= nil or self.itemId) then self.hl:Show() end
  if self.itemId then
    ui.tooltipItem(self, self.itemId, self.tit, self.dica)
  elseif self.dica ~= nil then
    ui.tooltip(self, self.tit, self.dica)
  end
end

local function sair(self)
  if self.hl then self.hl:Hide() end
  if GameTooltip then GameTooltip:Hide() end
end

local function novaBase(pai)
  local f = CreateFrame("Button", nil, pai)
  f.zeb = tex(f, "BACKGROUND", -3)
  f.zeb:SetAllPoints()
  f.zeb:SetColorTexture(ui.cor("zebra"))
  f.hl = tex(f, "BACKGROUND", -2)
  f.hl:SetAllPoints()
  f.hl:SetColorTexture(1, 1, 1, 0.08)
  f.hl:Hide()
  f:SetScript("OnEnter", function(self) seguro(entrar, self) end)
  f:SetScript("OnLeave", function(self) seguro(sair, self) end)
  f:SetScript("OnClick", function(self)
    if self.aoClicar then seguro(self.aoClicar) end
  end)
  return f
end

local function posiciona(f, pai, x, y, w, h)
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", pai, "TOPLEFT", x, -y)
  f:SetSize(w, h)
end

local function configBase(f, bl, titulo, zebra)
  f.dica = bl.dica
  f.tit = titulo
  f.itemId = tonumber(bl.itemId)
  f.aoClicar = bl.aoClicar
  f.clicavel = type(bl.aoClicar) == "function"
  f:EnableMouse(f.clicavel or bl.dica ~= nil or f.itemId ~= nil)
  f.hl:Hide()
  vis(f.zeb, zebra)
  f:SetAlpha(bl.apagado and 0.55 or 1)
end

-- Botao e tecla do lado direito. Devolve a margem direita ocupada.
local function direita(f, bl, dir)
  if bl.botao and type(bl.botao) == "table" then
    f.bot:Definir(bl.botao.rotulo, bl.botao.acao)
    f.bot:ClearAllPoints()
    f.bot:SetPoint("RIGHT", f, "RIGHT", -dir, 0)
    f.bot:Show()
    dir = dir + (f.bot.larg or 40) + 6
  else
    f.bot:Hide()
  end
  if bl.tecla ~= nil and tostring(bl.tecla) ~= "" then
    f.tecla:Definir(bl.tecla)
    f.tecla:ClearAllPoints()
    f.tecla:SetPoint("RIGHT", f, "RIGHT", -dir, 0)
    f.tecla:Show()
    dir = dir + (f.tecla.larg or 20) + 6
  else
    f.tecla:Hide()
  end
  return dir
end

-- Fluxo de etiquetas (passos, checklist, etiquetas, perfil, titulo) -----------------------------

local function novoSep(fl)
  local s = novoFs(fl, "menor", "cinza")
  s:SetText(">")
  return s
end

-- Devolve a altura usada. x0, y0: canto do fluxo dentro de fl.
local function fluxo(fl, defs, x0, y0, largura, sep)
  fl.et = fl.et or {}
  fl.sp = fl.sp or {}
  for _, s in ipairs(fl.sp) do s:Hide() end
  local x, y = 0, 0
  local n = #defs
  for i, d in ipairs(defs) do
    local e = fl.et[i]
    if not e then
      e = ui.etiqueta(fl)
      fl.et[i] = e
    end
    e:Definir(d.icone, d.s, d.n, d.cor, d.antes)
    local w = e.larg or 40
    if x > 0 then
      local sw = sep and 16 or 6
      if x + sw + w > largura then
        x = 0
        y = y + 26
      else
        if sep then
          local s = fl.sp[i]
          if not s then
            s = novoSep(fl)
            fl.sp[i] = s
          end
          s:ClearAllPoints()
          s:SetPoint("LEFT", fl, "TOPLEFT", x0 + x + 4, -(y0 + y + 11))
          s:Show()
        end
        x = x + sw
      end
    end
    e:ClearAllPoints()
    e:SetPoint("TOPLEFT", fl, "TOPLEFT", x0 + x, -(y0 + y))
    e:Show()
    x = x + w
  end
  for i = n + 1, #fl.et do fl.et[i]:Hide() end
  if n == 0 then return 0 end
  return y + 22
end

local function novoFluxo(p)
  local f = CreateFrame("Frame", nil, p)
  f.et, f.sp = {}, {}
  return f
end

-- Pools e despacho --------------------------------------------------------------------------

local desenhistas = {}

local function pegar(E, tipo, criar)
  local p = E.pool[tipo]
  if not p then
    p = {}
    E.pool[tipo] = p
  end
  local n = (E.n[tipo] or 0) + 1
  E.n[tipo] = n
  local f = p[n]
  if not f then
    f = criar(E.conteudo)
    p[n] = f
  end
  f:Show()
  return f
end

local function secId(bl) return bl.id or ("sec:" .. tostring(bl.s)) end

local function secAberta(bl)
  local db = type(GuiaForeverDB) == "table" and GuiaForeverDB.secoes
  local v = type(db) == "table" and db[secId(bl)]
  if v == nil then return bl.aberta ~= false end
  return v and true or false
end

local function dbMais(id)
  local m = type(GuiaForeverDB) == "table" and GuiaForeverDB.mais
  return type(m) == "table" and id ~= nil and m[id] and true or false
end

-- "Show N more" / "Show less" -----------------------------------------------------------------

local function alternarMais(self)
  local db = dbtab("mais")
  if db and self.id ~= nil then db[self.id] = (not db[self.id]) and true or nil end
  atualizarCtx(self.ctx)
end

local function novoMais(p)
  local b = CreateFrame("Button", nil, p)
  b:SetHeight(20)
  b.fs = novoFs(b, "menor", "destaque")
  b.fs:SetPoint("LEFT", b, "LEFT", 6, 0)
  b:SetScript("OnClick", function(self) seguro(alternarMais, self) end)
  return b
end

local function configMais(b, pai, id, ctx, aberto, escondidos, x, y)
  b.id, b.ctx = id, ctx
  if aberto then b.fs:SetText("Show less") else b.fs:SetText("Show " .. tostring(escondidos) .. " more") end
  local w = larg(b.fs) + 14
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", pai, "TOPLEFT", x, -y)
  b:SetWidth(max(w, 60))
  b:Show()
end

-- sec ----------------------------------------------------------------------------------------

local function alternarSecao(self)
  local db = dbtab("secoes")
  if db and self.id ~= nil then db[self.id] = not self.aberta end
  atualizarCtx(self.ctx)
end

desenhistas.sec = function(E, bl, y)
  local f = pegar(E, "sec", function(p)
    local b = CreateFrame("Button", nil, p)
    b.seta = tex(b, "ARTWORK")
    b.seta:SetSize(12, 12)
    b.seta:SetPoint("LEFT", b, "LEFT", 2, 0)
    b.t = novoFs(b, "secao", "destaque")
    b.t:SetPoint("LEFT", b, "LEFT", 20, 0)
    b.q = novoFs(b, "secao", "cinza")
    b.fio = tex(b, "ARTWORK")
    b.fio:SetHeight(1)
    b.fio:SetColorTexture(1, 1, 1, 0.1)
    b:SetScript("OnClick", function(self) seguro(alternarSecao, self) end)
    return b
  end)
  local margem = (y > 0) and 12 or 0
  local aberta = secAberta(bl)
  f.id, f.aberta, f.ctx = secId(bl), aberta, E.ctx
  posiciona(f, E.conteudo, 0, y + margem, E.larg, 22)
  f.seta:SetTexture(aberta and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
  f.t:SetTextColor(ui.cor("destaque"))
  f.t:SetText(string.upper(tostring(bl.s or "")))
  local ancora = f.t
  if bl.qtd ~= nil then
    f.q:ClearAllPoints()
    f.q:SetPoint("LEFT", f.t, "RIGHT", 8, 0)
    f.q:SetText(tostring(bl.qtd))
    f.q:Show()
    ancora = f.q
  else
    f.q:Hide()
  end
  f.fio:ClearAllPoints()
  f.fio:SetPoint("LEFT", ancora, "RIGHT", 8, 0)
  f.fio:SetPoint("RIGHT", f, "RIGHT", 0, 0)
  return margem + 22 + 4
end

desenhistas.cab = function(E, bl, y)
  return desenhistas.sec(E, { s = bl.s, id = bl.id, aberta = bl.aberta, qtd = bl.resumo }, y)
end

-- card -----------------------------------------------------------------------------------------

desenhistas.card = function(E, bl, y)
  local f = pegar(E, "card", function(p)
    local c = novaBase(p)
    c.zeb:SetColorTexture(1, 1, 1, 0.04)
    c.faixa = tex(c, "ARTWORK")
    c.faixa:SetWidth(4)
    c.faixa:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
    c.faixa:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 0, 0)
    bordas(c)
    c.ic = novoIcone(c, 28)
    c.t = novoFs(c, "cartao", "texto")
    c.s = novoFs(c, "menor", "cinza")
    c.tecla = novaTecla(c)
    c.bot = ui.botao(c, "")
    return c
  end)
  local w = E.larg
  configBase(f, bl, bl.s, true)
  f.faixa:SetColorTexture(ui.cor(bl.cor or "destaque"))
  local x = 12
  if bl.icone ~= nil then
    f.ic:ClearAllPoints()
    f.ic:SetPoint("LEFT", f, "LEFT", x, 0)
    f.ic:SetTexture(ui.icone(bl.icone))
    f.ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    mostraIcone(f.ic, true)
    x = x + 38
  else
    mostraIcone(f.ic, false)
  end
  local dir = direita(f, bl, 8)
  local tw = max(w - x - dir - 4, 40)
  f.t:SetWidth(tw)
  f.t:SetText(tostring(bl.s or ""))
  local th = max(alt(f.t), 17)
  local sh = 0
  if bl.sub ~= nil and tostring(bl.sub) ~= "" then
    f.s:SetWidth(tw)
    f.s:SetText(tostring(bl.sub))
    sh = max(alt(f.s), 15)
    f.s:Show()
  else
    f.s:Hide()
  end
  local h = max(42, th + sh + 12)
  local off = (h - th - sh) / 2
  f.t:ClearAllPoints()
  f.t:SetPoint("TOPLEFT", f, "TOPLEFT", x, -off)
  f.s:ClearAllPoints()
  f.s:SetPoint("TOPLEFT", f, "TOPLEFT", x, -(off + th))
  posiciona(f, E.conteudo, 0, y, w, h)
  return h + 4
end

-- item -------------------------------------------------------------------------------------------

desenhistas.item = function(E, bl, y)
  local f = pegar(E, "item", function(p)
    local c = novaBase(p)
    c.dst = tex(c, "ARTWORK")
    c.dst:SetWidth(2)
    c.dst:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
    c.dst:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 0, 0)
    c.nvBg = tex(c, "ARTWORK", -1)
    c.nvBg:SetSize(30, 20)
    c.nvBg:SetColorTexture(1, 1, 1, 0.08)
    c.nv = novoFs(c, "numero", "texto")
    c.nv:SetWidth(30)
    c.nv:SetJustifyH("CENTER")
    c.est = tex(c, "ARTWORK")
    c.ic = novoIcone(c, 20)
    c.fs = novoFs(c, "texto", "texto")
    c.tecla = novaTecla(c)
    c.bot = ui.botao(c, "")
    return c
  end)
  local w = E.larg
  E.zeb = not E.zeb
  configBase(f, bl, bl.s, E.zeb)
  vis(f.dst, bl.destaque)
  f.dst:SetColorTexture(ui.cor("destaque"))
  local x = 6
  if bl.nivel ~= nil then
    local tem = tostring(bl.nivel) ~= ""
    f.nvBg:ClearAllPoints()
    f.nvBg:SetPoint("LEFT", f, "LEFT", x, 0)
    f.nv:ClearAllPoints()
    f.nv:SetPoint("CENTER", f.nvBg, "CENTER", 0, 0)
    f.nv:SetText(tostring(bl.nivel))
    vis(f.nvBg, tem)
    vis(f.nv, tem)
    x = x + 38
  else
    f.nvBg:Hide()
    f.nv:Hide()
  end
  if aplicaEstado(f.est, bl.estado, f, x + 8) then x = x + 22 end
  if bl.icone ~= nil then
    f.ic:ClearAllPoints()
    f.ic:SetPoint("LEFT", f, "LEFT", x, 0)
    f.ic:SetTexture(ui.icone(bl.icone))
    f.ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    mostraIcone(f.ic, true)
    x = x + 28
  else
    mostraIcone(f.ic, false)
  end
  local dir = direita(f, bl, 6)
  local tw = max(w - x - dir - 4, 40)
  local s = tostring(bl.s or "")
  if bl.sub ~= nil and tostring(bl.sub) ~= "" then s = s .. "  " .. ui.hex("cinza") .. tostring(bl.sub) .. "|r" end
  if bl.estado == "travado" and bl.nivelTrava ~= nil then s = s .. "  " .. ui.hex("cinza") .. "Lv " .. tostring(bl.nivelTrava) .. "|r" end
  f.fs:SetWidth(tw)
  f.fs:SetText(s)
  local sh = max(alt(f.fs), 14)
  local h = max(28, sh + 10)
  f.fs:ClearAllPoints()
  f.fs:SetPoint("TOPLEFT", f, "TOPLEFT", x, -((h - sh) / 2))
  posiciona(f, E.conteudo, 0, y, w, h)
  return h + 1
end

desenhistas.linha = function(E, bl, y)
  return desenhistas.item(E, {
    s = bl.s, sub = bl.sub, dica = bl.dica, aoClicar = bl.aoClicar, icone = bl.icone, apagado = bl.apagado,
  }, y)
end

-- nota / texto / vazio ------------------------------------------------------------------------------

desenhistas.nota = function(E, bl, y)
  local f = pegar(E, "nota", function(p)
    local c = novaBase(p)
    c.fs = novoFs(c, "texto", "texto")
    c.fs:SetPoint("TOPLEFT", c, "TOPLEFT", 8, -5)
    return c
  end)
  E.zeb = not E.zeb
  configBase(f, bl, bl.s, E.zeb)
  local w = E.larg
  f.fs:SetWidth(max(w - 16, 40))
  f.fs:SetText(tostring(bl.s or ""))
  local h = max(alt(f.fs), 16) + 10
  posiciona(f, E.conteudo, 0, y, w, h)
  return h + 1
end

desenhistas.texto = function(E, bl, y)
  return desenhistas.nota(E, { s = bl.s, dica = bl.dica }, y)
end

desenhistas.vazio = function(E, bl, y)
  local f = pegar(E, "vazio", function(p)
    local c = CreateFrame("Frame", nil, p)
    c.fs = novoFs(c, "texto", "cinza")
    c.fs:SetPoint("LEFT", c, "LEFT", 8, 0)
    return c
  end)
  f.fs:SetWidth(max(E.larg - 16, 40))
  f.fs:SetText(tostring(bl.s or ""))
  posiciona(f, E.conteudo, 0, y, E.larg, 24)
  return 26
end

desenhistas.espaco = function()
  return 8
end

-- tabela --------------------------------------------------------------------------------------------

local ALINHA = { esq = "LEFT", centro = "CENTER", dir = "RIGHT" }

local function novaCelula(row)
  local c = {}
  c.est = row:CreateTexture(nil, "ARTWORK")
  c.ic = novoIcone(row, 20)
  c.fs = novoFs(row, "texto", "texto")
  c.fs:SetWordWrap(false)
  return c
end

desenhistas.tabela = function(E, bl, y)
  local tf = pegar(E, "tabela", function(p)
    local f = CreateFrame("Frame", nil, p)
    f.cab, f.lin = {}, {}
    return f
  end)
  local cols = bl.colunas or {}
  local linhas = bl.linhas or {}
  local w = E.larg
  local temBot = false
  for _, l in ipairs(linhas) do
    if l.botao then temBot = true break end
  end
  local BOTW = 90
  local fixo = temBot and BOTW or 0
  local livres = 0
  for _, c in ipairs(cols) do
    if type(c.largura) == "number" then fixo = fixo + c.largura else livres = livres + 1 end
  end
  local lw = livres > 0 and max(w - fixo, 0) / livres or 0
  local xs, ws = {}, {}
  local x = 0
  for i, c in ipairs(cols) do
    local cw = type(c.largura) == "number" and c.largura or lw
    xs[i], ws[i] = x, cw
    x = x + cw
  end
  local xb = x
  for i, c in ipairs(cols) do
    local fs = tf.cab[i]
    if not fs then
      fs = novoFs(tf, "secao", "cinza")
      fs:SetWordWrap(false)
      tf.cab[i] = fs
    end
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", tf, "TOPLEFT", xs[i] + 6, -2)
    fs:SetWidth(max(ws[i] - 12, 10))
    fs:SetJustifyH(ALINHA[c.alinha] or "LEFT")
    fs:SetText(string.upper(tostring(c.s or "")))
    fs:Show()
  end
  for i = #cols + 1, #tf.cab do tf.cab[i]:Hide() end

  local lim = bl.limite or 6
  local n = #linhas
  local mais = dbMais(bl.id)
  local mostrar = (mais or n <= lim) and n or lim
  for r = 1, mostrar do
    local l = linhas[r]
    local row = tf.lin[r]
    if not row then
      row = novaBase(tf)
      row.cel = {}
      row.bot = ui.botao(row, "")
      tf.lin[r] = row
    end
    local primeira = l.celulas and l.celulas[1]
    local tit = type(primeira) == "table" and primeira.s or primeira
    configBase(row, { dica = l.dica, apagado = l.apagado }, tit, r % 2 == 0)
    posiciona(row, tf, 0, 18 + (r - 1) * 30, w, 30)
    row:Show()
    for j, c in ipairs(cols) do
      local cel = row.cel[j]
      if not cel then
        cel = novaCelula(row)
        row.cel[j] = cel
      end
      local v = l.celulas and l.celulas[j]
      local d = type(v) == "table" and v or { s = v }
      local xx = xs[j] + 6
      if d.estado then
        aplicaEstado(cel.est, d.estado, row, xx + 8)
        xx = xx + 22
      else
        cel.est:Hide()
      end
      if d.icone ~= nil then
        cel.ic:ClearAllPoints()
        cel.ic:SetPoint("LEFT", row, "LEFT", xx, 0)
        cel.ic:SetTexture(ui.icone(d.icone))
        cel.ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        mostraIcone(cel.ic, true)
        xx = xx + 26
      else
        mostraIcone(cel.ic, false)
      end
      local nome = ui.fonte(d.numero and "numero" or "texto")
      cel.fs:SetFontObject(_G[nome] or nome)
      cel.fs:SetTextColor(ui.cor(d.cor or "texto"))
      cel.fs:ClearAllPoints()
      cel.fs:SetPoint("LEFT", row, "LEFT", xx, 0)
      cel.fs:SetWidth(max(xs[j] + ws[j] - xx - 6, 10))
      cel.fs:SetJustifyH(ALINHA[c.alinha] or "LEFT")
      cel.fs:SetText(d.s ~= nil and tostring(d.s) or "")
      cel.fs:Show()
    end
    for j = #cols + 1, #row.cel do
      local cel = row.cel[j]
      cel.est:Hide()
      mostraIcone(cel.ic, false)
      cel.fs:Hide()
    end
    if l.botao and type(l.botao) == "table" then
      row.bot:Definir(l.botao.rotulo, l.botao.acao)
      row.bot:ClearAllPoints()
      row.bot:SetPoint("LEFT", row, "LEFT", xb + 4, 0)
      row.bot:Show()
    else
      row.bot:Hide()
    end
  end
  for r = mostrar + 1, #tf.lin do tf.lin[r]:Hide() end
  local h = 18 + mostrar * 30
  if n > lim then
    if not tf.mais then tf.mais = novoMais(tf) end
    configMais(tf.mais, tf, bl.id, E.ctx, mais, n - lim, 0, h + 2)
    h = h + 24
  elseif tf.mais then
    tf.mais:Hide()
  end
  posiciona(tf, E.conteudo, 0, y, w, h)
  return h + 4
end

-- passos / checklist / etiquetas --------------------------------------------------------------------

desenhistas.passos = function(E, bl, y)
  local fl = pegar(E, "passos", novoFluxo)
  local defs = {}
  for i, t in ipairs(bl.lista or {}) do
    defs[i] = { s = t, n = i, cor = "destaque", antes = true }
  end
  local h = fluxo(fl, defs, 0, 0, E.larg, true)
  posiciona(fl, E.conteudo, 0, y, E.larg, max(h, 1))
  return h + 6
end

desenhistas.checklist = function(E, bl, y)
  local fl = pegar(E, "checklist", novoFluxo)
  local defs = {}
  for i, it in ipairs(bl.itens or {}) do
    local s = tostring(it.s or "")
    if it.sub ~= nil and tostring(it.sub) ~= "" then s = s .. " " .. ui.hex("cinza") .. tostring(it.sub) .. "|r" end
    defs[i] = { icone = it.feito and ESTADO_TEX.feito or ESTADO_TEX.falta, s = s }
  end
  local h = fluxo(fl, defs, 0, 0, E.larg, false)
  posiciona(fl, E.conteudo, 0, y, E.larg, max(h, 1))
  return h + 6
end

local function defsEtiquetas(lista)
  local defs = {}
  for i, t in ipairs(lista or {}) do
    if type(t) == "table" then
      defs[i] = { icone = t.icone, s = t.s, n = t.n, cor = t.cor }
    else
      defs[i] = { s = t }
    end
  end
  return defs
end

desenhistas.etiquetas = function(E, bl, y)
  local fl = pegar(E, "etiquetas", function(p)
    local f = novoFluxo(p)
    f.rot = novoFs(f, "menor", "cinza")
    f.rot:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -4)
    return f
  end)
  local x0 = 0
  if bl.rotulo ~= nil and tostring(bl.rotulo) ~= "" then
    fl.rot:SetText(tostring(bl.rotulo))
    fl.rot:Show()
    x0 = larg(fl.rot) + 10
  else
    fl.rot:Hide()
  end
  local h = fluxo(fl, defsEtiquetas(bl.lista), x0, 0, max(E.larg - x0, 40), false)
  h = max(h, 22)
  posiciona(fl, E.conteudo, 0, y, E.larg, h)
  return h + 6
end

-- titulo --------------------------------------------------------------------------------------------

desenhistas.titulo = function(E, bl, y)
  local f = pegar(E, "titulo", function(p)
    local c = novoFluxo(p)
    c.ic = novoIcone(c, 40)
    c.ic:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
    c.t = novoFs(c, "detalhe", "texto")
    c.t:SetPoint("TOPLEFT", c, "TOPLEFT", 50, -2)
    return c
  end)
  if bl.icone ~= nil then
    f.ic:SetTexture(ui.icone(bl.icone))
    f.ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  end
  mostraIcone(f.ic, bl.icone ~= nil)
  local x0 = (bl.icone ~= nil) and 50 or 0
  f.t:ClearAllPoints()
  f.t:SetPoint("TOPLEFT", f, "TOPLEFT", x0, -2)
  f.t:SetWidth(max(E.larg - x0, 40))
  f.t:SetText(tostring(bl.s or ""))
  local fh = fluxo(f, defsEtiquetas(bl.etiquetas), x0, 30, max(E.larg - x0, 40), false)
  local h = max(44, (fh > 0) and (30 + fh) or 30)
  posiciona(f, E.conteudo, 0, y, E.larg, h)
  return h + 8
end

-- grade -----------------------------------------------------------------------------------------------

local function novoTile(p)
  local f = CreateFrame("Button", nil, p)
  f:SetSize(46, 60)
  f.glow = f:CreateTexture(nil, "BACKGROUND", nil, -3)
  f.glow:SetSize(50, 50)
  f.glow:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
  f.preto = f:CreateTexture(nil, "BACKGROUND", nil, -2)
  f.preto:SetSize(48, 48)
  f.preto:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
  f.preto:SetColorTexture(0, 0, 0, 1)
  f.ic = f:CreateTexture(nil, "ARTWORK")
  f.ic:SetSize(46, 46)
  f.ic:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  f.k = novoFs(f, "tecla", "texto")
  f.k:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -1)
  f.lv = novoFs(f, "numero", "texto")
  f.lv:SetPoint("CENTER", f.ic, "CENTER", 0, 0)
  f.lv:SetJustifyH("CENTER")
  f.nm = novoFs(f, "mini", "cinza")
  f.nm:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -48)
  f.nm:SetWidth(46)
  f.nm:SetJustifyH("CENTER")
  f.nm:SetWordWrap(false)
  f.nm:SetMaxLines(1)
  f.tagBg = f:CreateTexture(nil, "OVERLAY", nil, 1)
  f.tagBg:SetSize(26, 12)
  f.tagBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", 3, 6)
  f.tag = novoFs(f, "mini", "texto", "OVERLAY")
  f.tag:SetPoint("CENTER", f.tagBg, "CENTER", 0, 0)
  f.tag:SetJustifyH("CENTER")
  f.tag:SetTextColor(0, 0, 0, 1)
  f.tag:SetText("NEW")
  f:SetScript("OnEnter", function(self) seguro(entrar, self) end)
  f:SetScript("OnLeave", function(self) seguro(sair, self) end)
  return f
end

desenhistas.grade = function(E, bl, y)
  local g = pegar(E, "grade", function(p)
    local c = CreateFrame("Frame", nil, p)
    c.tl = {}
    c.tt = novoFs(c, "menor", "cinza")
    c.tt:SetPoint("TOPLEFT", c, "TOPLEFT", 2, 0)
    return c
  end)
  local w = E.larg
  local top = 0
  if bl.titulo ~= nil and tostring(bl.titulo) ~= "" then
    g.tt:SetText(tostring(bl.titulo))
    g.tt:Show()
    top = 18
  else
    g.tt:Hide()
  end
  local x, linha, usados = 0, 0, 0
  for _, t in ipairs(bl.teclas or {}) do
    if t == false then
      x = x + 10
    else
      if x > 0 and x + 46 > w then
        x = 0
        linha = linha + 1
      end
      usados = usados + 1
      local tl = g.tl[usados]
      if not tl then
        tl = novoTile(g)
        g.tl[usados] = tl
      end
      local estado = t.estado
      tl:ClearAllPoints()
      tl:SetPoint("TOPLEFT", g, "TOPLEFT", x, -(top + linha * 68 + 2))
      tl:Show()
      tl.ic:SetTexture(ui.icone(t.icone))
      tl.ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      local trav = estado == "travado"
      tl.ic:SetDesaturated(trav and true or false)
      if trav then tl.ic:SetVertexColor(0.35, 0.35, 0.35, 1) else tl.ic:SetVertexColor(1, 1, 1, 1) end
      tl.k:SetText(tostring(t.k or ""))
      tl.lv:SetText(trav and tostring(t.nivel or "") or "")
      tl.nm:SetText(tostring(t.nome or ""))
      local novo = estado == "novo"
      vis(tl.glow, novo)
      vis(tl.tagBg, novo)
      vis(tl.tag, novo)
      tl.glow:SetColorTexture(ui.cor("destaque"))
      tl.tagBg:SetColorTexture(ui.cor("destaque"))
      tl.dica = t.dica
      tl.tit = t.nome
      tl:EnableMouse(t.dica ~= nil)
      x = x + 52
    end
  end
  for i = usados + 1, #g.tl do g.tl[i]:Hide() end
  local h = top
  if usados > 0 then h = top + linha * 68 + 66 end
  posiciona(g, E.conteudo, 0, y, w, max(h, 1))
  return h + 6
end

-- receita e materiais (aba Crafts, 1.4; ARQUITETURA.md, secao 13) ---------------------------------------

local function novaPilula(pai)
  local f = CreateFrame("Frame", nil, pai)
  f:SetHeight(20)
  f.bg = tex(f, "BACKGROUND", -1)
  f.bg:SetAllPoints()
  bordas(f)
  f.fs = novoFs(f, "menor", "texto")
  f.fs:SetPoint("CENTER", f, "CENTER", 0, 0)
  f.fs:SetJustifyH("CENTER")
  function f:Definir(s, cor)
    local r, g, b = ui.cor(cor or "cinza")
    self.bg:SetColorTexture(r, g, b, 0.18)
    self.fs:SetTextColor(r, g, b, 1)
    self.fs:SetText(tostring(s or ""))
    local w = larg(self.fs) + 16
    self:SetWidth(w)
    self.larg = w
  end
  return f
end

desenhistas.receita = function(E, bl, y)
  local f = pegar(E, "receita", function(p)
    local c = novaBase(p)
    c.zeb:SetColorTexture(1, 1, 1, 0.04)
    c.faixa = tex(c, "ARTWORK")
    c.faixa:SetWidth(4)
    c.faixa:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
    c.faixa:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 0, 0)
    bordas(c)
    c.ic = novoIcone(c, 36)
    c.t = novoFs(c, "cartao", "texto")
    c.s = novoFs(c, "menor", "cinza")
    c.nvBg = tex(c, "ARTWORK", -1)
    c.nvBg:SetColorTexture(1, 1, 1, 0.08)
    c.nv = novoFs(c, "numero", "texto")
    c.nv:SetJustifyH("CENTER")
    c.pil = novaPilula(c)
    return c
  end)
  local w = E.larg
  local grande = bl.tam ~= "pequeno"
  local tam = grande and 36 or 28
  configBase(f, bl, bl.s, true)
  f.faixa:SetColorTexture(ui.cor(bl.cor or (bl.destaque and "destaque" or "cinza")))
  local x = 12
  f.ic:SetSize(tam, tam)
  f.ic:ClearAllPoints()
  f.ic:SetPoint("LEFT", f, "LEFT", x, 0)
  f.ic:SetTexture(ui.icone(bl.icone))
  f.ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  mostraIcone(f.ic, true)
  x = x + tam + 10
  -- direita: a faixa de pericia numa caixa e, antes dela, a pilula do padrao
  local dir = 8
  if bl.faixa ~= nil and tostring(bl.faixa) ~= "" then
    f.nv:SetText(tostring(bl.faixa))
    local nw = larg(f.nv) + 14
    f.nvBg:SetSize(nw, 20)
    f.nvBg:ClearAllPoints()
    f.nvBg:SetPoint("RIGHT", f, "RIGHT", -dir, 0)
    f.nv:ClearAllPoints()
    f.nv:SetPoint("CENTER", f.nvBg, "CENTER", 0, 0)
    f.nvBg:Show()
    f.nv:Show()
    dir = dir + nw + 8
  else
    f.nvBg:Hide()
    f.nv:Hide()
  end
  if type(bl.pilula) == "table" and bl.pilula.s then
    f.pil:Definir(bl.pilula.s, bl.pilula.cor)
    f.pil:ClearAllPoints()
    f.pil:SetPoint("RIGHT", f, "RIGHT", -dir, 0)
    f.pil:Show()
    dir = dir + (f.pil.larg or 40) + 8
  else
    f.pil:Hide()
  end
  local tw = max(w - x - dir - 4, 40)
  f.t:SetWidth(tw)
  f.t:SetText(tostring(bl.s or ""))
  local th = max(alt(f.t), 17)
  local sh = 0
  if bl.sub ~= nil and tostring(bl.sub) ~= "" then
    f.s:SetWidth(tw)
    f.s:SetText(tostring(bl.sub))
    sh = max(alt(f.s), 15)
    f.s:Show()
  else
    f.s:Hide()
  end
  local h = max(grande and 56 or 44, th + sh + 14)
  local off = (h - th - sh) / 2
  f.t:ClearAllPoints()
  f.t:SetPoint("TOPLEFT", f, "TOPLEFT", x, -off)
  f.s:ClearAllPoints()
  f.s:SetPoint("TOPLEFT", f, "TOPLEFT", x, -(off + th))
  posiciona(f, E.conteudo, 0, y, w, h)
  return h + 4
end

local function novoMat(p)
  local f = CreateFrame("Button", nil, p)
  f:SetSize(40, 58)
  f.ok = f:CreateTexture(nil, "BACKGROUND", nil, -3)
  f.ok:SetSize(44, 44)
  f.ok:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
  f.preto = f:CreateTexture(nil, "BACKGROUND", nil, -2)
  f.preto:SetSize(42, 42)
  f.preto:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
  f.preto:SetColorTexture(0, 0, 0, 1)
  f.ic = f:CreateTexture(nil, "ARTWORK")
  f.ic:SetSize(40, 40)
  f.ic:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  f.q = novoFs(f, "tecla", "texto")
  f.q:SetPoint("BOTTOMRIGHT", f.ic, "BOTTOMRIGHT", -2, 3)
  f.q:SetJustifyH("RIGHT")
  f.tem = novoFs(f, "mini", "cinza")
  f.tem:SetPoint("TOP", f.ic, "BOTTOM", 0, -3)
  f.tem:SetWidth(54)
  f.tem:SetJustifyH("CENTER")
  f.tem:SetWordWrap(false)
  f:SetScript("OnEnter", function(self) seguro(entrar, self) end)
  f:SetScript("OnLeave", function(self) seguro(sair, self) end)
  return f
end

desenhistas.materiais = function(E, bl, y)
  local g = pegar(E, "materiais", function(p)
    local c = CreateFrame("Frame", nil, p)
    c.tl = {}
    c.tt = novoFs(c, "menor", "cinza")
    c.tt:SetPoint("TOPLEFT", c, "TOPLEFT", 2, 0)
    return c
  end)
  local w = E.larg
  local top = 0
  if bl.titulo ~= nil and tostring(bl.titulo) ~= "" then
    g.tt:SetText(tostring(bl.titulo))
    g.tt:Show()
    top = 18
  else
    g.tt:Hide()
  end
  local x0 = tonumber(bl.recuo) or 0
  local x, linha, usados = x0, 0, 0
  for _, m in ipairs(bl.lista or {}) do
    if type(m) == "table" then
      if x > x0 and x + 40 > w then
        x = x0
        linha = linha + 1
      end
      usados = usados + 1
      local tl = g.tl[usados]
      if not tl then
        tl = novoMat(g)
        g.tl[usados] = tl
      end
      tl:ClearAllPoints()
      tl:SetPoint("TOPLEFT", g, "TOPLEFT", x, -(top + linha * 66 + 4))
      tl:Show()
      tl.ic:SetTexture(ui.icone(m.icone or ("item:" .. tostring(m.id))))
      tl.ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      local qtd = tonumber(m.qtd)
      tl.q:SetText(qtd and tostring(qtd) or "")
      local tem = tonumber(m.tem)
      local basta = tem ~= nil and qtd ~= nil and tem >= qtd
      if tem ~= nil and qtd ~= nil then
        tl.tem:SetText(tostring(tem) .. "/" .. tostring(qtd))
        tl.tem:SetTextColor(ui.cor(basta and "verde" or "laranja"))
      else
        tl.tem:SetText("")
      end
      vis(tl.ok, basta)
      tl.ok:SetColorTexture(ui.cor("verde"))
      tl.itemId = tonumber(m.id)
      tl.tit = m.nome
      tl.dica = m.dica
      tl:EnableMouse(true)
      x = x + 58
    end
  end
  for i = usados + 1, #g.tl do g.tl[i]:Hide() end
  local h = top
  if usados > 0 then h = top + linha * 66 + 62 end
  posiciona(g, E.conteudo, 0, y, w, max(h, 1))
  return h + 6
end

-- regua ---------------------------------------------------------------------------------------------------

local function novaMarca(rg)
  local m = CreateFrame("Button", nil, rg)
  m:SetSize(18, 18)
  m.glow = m:CreateTexture(nil, "BACKGROUND", nil, -2)
  m.glow:SetSize(26, 26)
  m.glow:SetPoint("CENTER", m, "CENTER", 0, 0)
  m.glow:SetColorTexture(ui.cor("dourado"))
  m.glow:SetAlpha(0.35)
  m.anel = m:CreateTexture(nil, "BACKGROUND", nil, -1)
  m.anel:SetAllPoints()
  m.cheio = m:CreateTexture(nil, "ARTWORK")
  m.cheio:SetSize(14, 14)
  m.cheio:SetPoint("CENTER", m, "CENTER", 0, 0)
  redondo(m, m.glow)
  redondo(m, m.anel)
  redondo(m, m.cheio)
  m.fs = novoFs(m, "numero", "texto", "OVERLAY")
  m.fs:SetPoint("CENTER", m, "CENTER", 0, 0)
  m.fs:SetJustifyH("CENTER")
  m:SetScript("OnEnter", function(self) seguro(entrar, self) end)
  m:SetScript("OnLeave", function(self) seguro(sair, self) end)
  return m
end

desenhistas.regua = function(E, bl, y)
  local rg = pegar(E, "regua", function(p)
    local c = CreateFrame("Frame", nil, p)
    c.rot, c.fx, c.mk, c.tk = {}, {}, {}, {}
    c.hoje = c:CreateTexture(nil, "ARTWORK", nil, 2)
    c.hoje:SetWidth(1)
    c.hoje:SetColorTexture(ui.cor("dourado"))
    c.hojeT = novoFs(c, "mini", "dourado")
    c.leg = novoFs(c, "mini", "cinza")
    return c
  end)
  local w = E.larg
  local mn = tonumber(bl.min) or 1
  local mx = tonumber(bl.max) or (mn + 1)
  if mx <= mn then mx = mn + 1 end
  local x0, x1 = 78, max(w - 6, 100)
  local function px(n) return x0 + (((tonumber(n) or mn) - mn) / (mx - mn)) * (x1 - x0) end
  local linhas = bl.linhas or {}
  local nl = #linhas
  local nm = 0
  for i, l in ipairs(linhas) do
    local yc = 18 + (i - 1) * 30 + 15
    local r = rg.rot[i]
    if not r then
      r = CreateFrame("Frame", nil, rg)
      r.ic = novoIcone(r, 18)
      r.ic:SetPoint("LEFT", r, "LEFT", 0, 0)
      r.fs = novoFs(r, "texto", "texto")
      r.fs:SetPoint("LEFT", r, "LEFT", 24, 0)
      r.fs:SetWordWrap(false)
      rg.rot[i] = r
    end
    r:ClearAllPoints()
    r:SetPoint("LEFT", rg, "TOPLEFT", 0, -yc)
    r:SetSize(76, 26)
    r:Show()
    if l.icone ~= nil then
      r.ic:SetTexture(ui.icone(l.icone))
      r.ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
    mostraIcone(r.ic, l.icone ~= nil)
    r.fs:SetWidth(50)
    r.fs:SetText(tostring(l.nome or ""))
    local fx = rg.fx[i]
    if not fx then
      fx = rg:CreateTexture(nil, "ARTWORK", nil, -1)
      fx:SetHeight(2)
      fx:SetColorTexture(1, 1, 1, 0.12)
      rg.fx[i] = fx
    end
    fx:ClearAllPoints()
    fx:SetPoint("LEFT", rg, "TOPLEFT", x0, -yc)
    fx:SetWidth(max(x1 - x0, 1))
    fx:Show()
    for _, mc in ipairs(l.marcas or {}) do
      nm = nm + 1
      local m = rg.mk[nm]
      if not m then
        m = novaMarca(rg)
        rg.mk[nm] = m
      end
      m:ClearAllPoints()
      m:SetPoint("CENTER", rg, "TOPLEFT", px(mc.nivel), -yc)
      m:Show()
      local st = mc.estado
      vis(m.glow, st == "agora")
      if st == "tem" then
        m.anel:SetColorTexture(0, 0, 0, 1)
        m.cheio:SetColorTexture(ui.cor("destaque"))
        m.fs:SetTextColor(0, 0, 0, 1)
      elseif st == "agora" then
        m.anel:SetColorTexture(0, 0, 0, 1)
        m.cheio:SetColorTexture(ui.cor("dourado"))
        m.fs:SetTextColor(0, 0, 0, 1)
      else
        m.anel:SetColorTexture(0.45, 0.45, 0.45, 1)
        m.cheio:SetColorTexture(0.1, 0.1, 0.1, 1)
        m.fs:SetTextColor(ui.cor("cinza"))
      end
      m.fs:SetText(tostring(mc.rank or ""))
      m.dica = mc.dica
      m.tit = l.nome
      m:EnableMouse(mc.dica ~= nil)
    end
  end
  for i = nl + 1, #rg.rot do rg.rot[i]:Hide() end
  for i = nl + 1, #rg.fx do rg.fx[i]:Hide() end
  for i = nm + 1, #rg.mk do rg.mk[i]:Hide() end
  -- linha de hoje
  if bl.atual ~= nil then
    local ax = px(bl.atual)
    rg.hoje:ClearAllPoints()
    rg.hoje:SetPoint("TOPLEFT", rg, "TOPLEFT", ax, -14)
    rg.hoje:SetHeight(nl * 30 + 8)
    rg.hoje:Show()
    rg.hojeT:ClearAllPoints()
    rg.hojeT:SetPoint("TOPLEFT", rg, "TOPLEFT", ax + 4, -2)
    rg.hojeT:SetText(bl.rotuloAtual ~= nil and tostring(bl.rotuloAtual) or "")
    rg.hojeT:Show()
  else
    rg.hoje:Hide()
    rg.hojeT:Hide()
  end
  -- regua de niveis
  local yt = 18 + nl * 30 + 4
  local nt = 0
  local lv = ceil(mn / 10) * 10
  while lv <= mx do
    nt = nt + 1
    local t = rg.tk[nt]
    if not t then
      t = novoFs(rg, "mini", "cinza")
      t:SetJustifyH("CENTER")
      rg.tk[nt] = t
    end
    t:ClearAllPoints()
    t:SetPoint("TOP", rg, "TOPLEFT", px(lv), -yt)
    t:SetText(tostring(lv))
    t:Show()
    lv = lv + 10
  end
  for i = nt + 1, #rg.tk do rg.tk[i]:Hide() end
  rg.leg:ClearAllPoints()
  rg.leg:SetPoint("TOPLEFT", rg, "TOPLEFT", x0, -(yt + 18))
  rg.leg:SetText(ui.hex("destaque") .. "has it|r  /  " .. ui.hex("dourado") .. "can learn now|r  /  " .. ui.hex("cinza") .. "later|r")
  local h = yt + 18 + 16
  posiciona(rg, E.conteudo, 0, y, w, h)
  return h + 6
end

-- perfil ----------------------------------------------------------------------------------------------------

desenhistas.perfil = function(E, bl, y)
  local f = pegar(E, "perfil", function(p)
    local c = novoFluxo(p)
    c.zeb = tex(c, "BACKGROUND", -3)
    c.zeb:SetAllPoints()
    c.zeb:SetColorTexture(1, 1, 1, 0.04)
    bordas(c)
    c.anel = c:CreateTexture(nil, "ARTWORK", nil, -1)
    c.anel:SetSize(62, 62)
    c.anel:SetPoint("TOPLEFT", c, "TOPLEFT", 8, -8)
    c.anel:SetColorTexture(0, 0, 0, 1)
    c.ret = c:CreateTexture(nil, "ARTWORK")
    c.ret:SetSize(58, 58)
    c.ret:SetPoint("CENTER", c.anel, "CENTER", 0, 0)
    redondo(c, c.anel)
    redondo(c, c.ret)
    c.t = novoFs(c, "titulo", "texto")
    c.t:SetPoint("TOPLEFT", c, "TOPLEFT", 82, -10)
    c.s = novoFs(c, "menor", "cinza")
    c.bar = {}
    return c
  end)
  local w = E.larg
  local feito = false
  if bl.retrato and SetPortraitTexture and UnitExists then
    local ok = pcall(function()
      if UnitExists(bl.retrato) then
        SetPortraitTexture(f.ret, bl.retrato)
        feito = true
      end
    end)
    if not ok then feito = false end
  end
  if feito then
    f.ret:SetTexCoord(0, 1, 0, 1)
  else
    f.ret:SetTexture(ui.icone(bl.icone))
    f.ret:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  end
  local cw = 210
  f.t:SetWidth(max(w - 92, 40))
  f.t:SetText(tostring(bl.titulo or ""))
  local th = max(alt(f.t), 20)
  local sy = 10 + th + 2
  local sh = 0
  local linhasSub = bl.sub
  if type(linhasSub) == "table" and #linhasSub > 0 then
    f.s:ClearAllPoints()
    f.s:SetPoint("TOPLEFT", f, "TOPLEFT", 82, -sy)
    f.s:SetWidth(cw + 100)
    f.s:SetText(table.concat(linhasSub, "\n"))
    f.s:Show()
    sh = max(alt(f.s), 15)
  elseif type(linhasSub) == "string" then
    f.s:ClearAllPoints()
    f.s:SetPoint("TOPLEFT", f, "TOPLEFT", 82, -sy)
    f.s:SetWidth(cw + 100)
    f.s:SetText(linhasSub)
    f.s:Show()
    sh = max(alt(f.s), 15)
  else
    f.s:Hide()
  end
  local by = sy + sh + 6
  local nb = 0
  for _, b in ipairs(bl.barras or {}) do
    if nb >= 2 then break end
    nb = nb + 1
    local br = f.bar[nb]
    if not br then
      br = CreateFrame("Frame", nil, f)
      br:SetSize(cw, 16)
      br.bg = br:CreateTexture(nil, "BACKGROUND")
      br.bg:SetAllPoints()
      br.bg:SetColorTexture(0, 0, 0, 0.6)
      br.fill = br:CreateTexture(nil, "ARTWORK")
      br.fill:SetHeight(16)
      br.fill:SetPoint("TOPLEFT", br, "TOPLEFT", 0, 0)
      br.fs = novoFs(br, "menor", "texto", "OVERLAY")
      br.fs:SetPoint("CENTER", br, "CENTER", 0, 0)
      br.fs:SetJustifyH("CENTER")
      f.bar[nb] = br
    end
    local v, mxv = tonumber(b.valor) or 0, tonumber(b.max) or 1
    local fr = (mxv > 0) and min(max(v / mxv, 0), 1) or 0
    br:ClearAllPoints()
    br:SetPoint("TOPLEFT", f, "TOPLEFT", 82, -by)
    br.fill:SetWidth(max(cw * fr, 0.01))
    br.fill:SetColorTexture(ui.cor(b.cor or "verde"))
    br.fs:SetText(tostring(b.s or ""))
    br:Show()
    by = by + 20
  end
  for i = nb + 1, #f.bar do f.bar[i]:Hide() end
  local cx = 82 + cw + 24
  local fh = fluxo(f, defsEtiquetas(bl.etiquetas), cx, 10, max(w - cx - 10, 60), false)
  local h = max(78, by + 6, (fh > 0) and (fh + 20) or 0)
  posiciona(f, E.conteudo, 0, y, w, h)
  return h + 6
end

-- segs ----------------------------------------------------------------------------------------------------------

desenhistas.segs = function(E, bl, y)
  local f = pegar(E, "segs", function(p)
    local c = CreateFrame("Frame", nil, p)
    c.bt = {}
    local bg = c:CreateTexture(nil, "BACKGROUND", nil, -4)
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 1)
    return c
  end)
  local x = 1
  local n = 0
  for _, o in ipairs(bl.opcoes or {}) do
    n = n + 1
    local b = f.bt[n]
    if not b then
      b = novaBase(f)
      b.t = novoFs(b, "texto", "cinza")
      b.t:SetPoint("CENTER", b, "CENTER", 0, 0)
      b.t:SetJustifyH("CENTER")
      b.sub = b:CreateTexture(nil, "ARTWORK")
      b.sub:SetHeight(2)
      b.sub:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
      b.sub:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
      f.bt[n] = b
    end
    local atual = o.id == bl.atual
    b.t:SetText(tostring(o.s or ""))
    b.t:SetTextColor(ui.cor(atual and "texto" or "cinza"))
    local bw = larg(b.t) + 28
    b.zeb:Show()
    b.zeb:SetColorTexture(1, 1, 1, atual and 0.09 or 0.03)
    vis(b.sub, atual)
    b.sub:SetColorTexture(ui.cor("destaque"))
    b.clicavel = true
    b.dica = nil
    b:EnableMouse(true)
    local aba, id, ctx = bl.aba, o.id, E.ctx
    b.aoClicar = function()
      local s = dbtab("sub")
      if s and aba ~= nil then s[aba] = id end
      atualizarCtx(ctx)
    end
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", f, "TOPLEFT", x, -1)
    b:SetSize(bw, 22)
    b:Show()
    x = x + bw + 1
  end
  for i = n + 1, #f.bt do f.bt[i]:Hide() end
  posiciona(f, E.conteudo, 0, y, x + 1, 24)
  return 34
end

-- duas --------------------------------------------------------------------------------------------------------------

local function novoItemLista(p)
  local b = novaBase(p)
  b.sel = tex(b, "BACKGROUND", -1)
  b.sel:SetAllPoints()
  b.sel:SetColorTexture(1, 1, 1, 0.08)
  b.faixa = tex(b, "ARTWORK")
  b.faixa:SetWidth(3)
  b.faixa:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
  b.faixa:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
  b.ic = novoIcone(b, 18)
  b.ic:SetPoint("LEFT", b, "LEFT", 8, 0)
  b.fs = novoFs(b, "texto", "texto")
  b.fs:SetWordWrap(false)
  b.sb = novoFs(b, "mini", "cinza")
  b.sb:SetPoint("RIGHT", b, "RIGHT", -6, 0)
  b.sb:SetJustifyH("RIGHT")
  b.tagBg = tex(b, "ARTWORK")
  b.tagBg:SetHeight(12)
  b.tag = novoFs(b, "mini", "texto", "OVERLAY")
  b.tag:SetTextColor(0, 0, 0, 1)
  b.tag:SetJustifyH("CENTER")
  return b
end

desenhistas.duas = function(E, bl, y)
  local d = pegar(E, "duas", function(p)
    local c = CreateFrame("Frame", nil, p)
    c.it = {}
    c.div = c:CreateTexture(nil, "ARTWORK")
    c.div:SetColorTexture(1, 1, 1, 0.06)
    c.det = CreateFrame("Frame", nil, c)
    return c
  end)
  local lw = tonumber(bl.largura) or 190
  local lista = bl.lista or {}
  local n = 0
  for _, it in ipairs(lista) do
    n = n + 1
    local b = d.it[n]
    if not b then
      b = novoItemLista(d)
      d.it[n] = b
    end
    local atual = it.id == bl.atual
    b.dica, b.tit = nil, it.s
    b:EnableMouse(true)
    b.clicavel = true
    b.zeb:Hide()
    vis(b.sel, atual)
    vis(b.faixa, atual)
    b.faixa:SetColorTexture(ui.cor("destaque"))
    local x = 8
    if it.icone ~= nil then
      b.ic:SetTexture(ui.icone(it.icone))
      b.ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      mostraIcone(b.ic, true)
      x = x + 26
    else
      mostraIcone(b.ic, false)
    end
    local dir = 6
    if it.marca ~= nil and tostring(it.marca) ~= "" then
      b.tag:SetText(tostring(it.marca))
      local tw = larg(b.tag) + 6
      b.tagBg:ClearAllPoints()
      b.tagBg:SetPoint("RIGHT", b, "RIGHT", -6, 0)
      b.tagBg:SetWidth(tw)
      b.tagBg:SetColorTexture(ui.cor("destaque"))
      b.tagBg:Show()
      b.tag:ClearAllPoints()
      b.tag:SetPoint("CENTER", b.tagBg, "CENTER", 0, 0)
      b.tag:Show()
      b.sb:Hide()
      dir = dir + tw + 6
    else
      b.tagBg:Hide()
      b.tag:Hide()
      if it.sub ~= nil and tostring(it.sub) ~= "" then
        b.sb:SetText(tostring(it.sub))
        b.sb:Show()
        dir = dir + larg(b.sb) + 6
      else
        b.sb:Hide()
      end
    end
    b.fs:ClearAllPoints()
    b.fs:SetPoint("LEFT", b, "LEFT", x, 0)
    b.fs:SetWidth(max(lw - x - dir, 20))
    b.fs:SetText(tostring(it.s or ""))
    local sid, did, ctx = it.id, bl.id, E.ctx
    b.aoClicar = function()
      local s = dbtab("sel")
      if s and did ~= nil then s[did] = sid end
      atualizarCtx(ctx)
    end
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", d, "TOPLEFT", 0, -((n - 1) * 25))
    b:SetSize(lw, 25)
    b:Show()
  end
  for i = n + 1, #d.it do d.it[i]:Hide() end
  local dw = max(E.larg - lw - 16, 50)
  d.det:ClearAllPoints()
  d.det:SetPoint("TOPLEFT", d, "TOPLEFT", lw + 14, 0)
  local dh = tonumber(ui.desenhar(d.det, bl.detalhe or {}, dw, E.ctx)) or 0
  d.det:SetSize(dw, max(dh, 1))
  local h = max(n * 25, dh, 1)
  d.div:ClearAllPoints()
  d.div:SetPoint("TOPLEFT", d, "TOPLEFT", lw + 4, 0)
  d.div:SetSize(1, h)
  posiciona(d, E.conteudo, 0, y, E.larg, h)
  return h + 6
end

-- botao -------------------------------------------------------------------------------------------------------------------

desenhistas.botao = function(E, bl, y)
  local b = pegar(E, "botao", function(p) return ui.botao(p, "") end)
  b:Definir(bl.s, bl.f)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", E.conteudo, "TOPLEFT", 0, -y)
  return 26
end

-- desenhar -------------------------------------------------------------------------------------------------------------------

local CONTA = { item = true, card = true, nota = true, linha = true, texto = true }

local function contarUnidades(blocos, i)
  local n = 0
  for j = i + 1, #blocos do
    local b = blocos[j]
    if type(b) == "table" then
      if b.t == "sec" or b.t == "cab" then break end
      if CONTA[b.t] then n = n + 1 end
    end
  end
  return n
end

function ui.desenhar(conteudo, blocos, largura, ctx)
  local g = conteudo._gf
  if type(g) ~= "table" then
    g = { pool = {} }
    conteudo._gf = g
  end
  local E = { conteudo = conteudo, larg = tonumber(largura) or 0, ctx = ctx, pool = g.pool, n = {}, zeb = false }
  local y = 0
  local sec = nil

  local function fecharSecao()
    if sec and sec.aberta and sec.total > sec.limite then
      local mais = dbMais(sec.id)
      local b = pegar(E, "mais", novoMais)
      configMais(b, conteudo, sec.id, ctx, mais, sec.total - sec.limite, 0, y)
      y = y + 24
    end
    sec = nil
  end

  blocos = type(blocos) == "table" and blocos or {}
  for i, bl in ipairs(blocos) do
    if type(bl) == "table" then
      local t = bl.t
      local pula = false
      if t == "sec" or t == "cab" then
        fecharSecao()
        E.zeb = false
        sec = {
          id = secId(bl), aberta = secAberta(bl), limite = tonumber(bl.limite) or 5, n = 0,
          total = contarUnidades(blocos, i),
        }
      elseif sec then
        if not sec.aberta then
          pula = true
        elseif CONTA[t] then
          sec.n = sec.n + 1
          if sec.n > sec.limite and not dbMais(sec.id) then pula = true end
        end
      end
      if not pula then
        local fn = desenhistas[t]
        local blk = bl
        if not fn then
          fn = desenhistas.vazio
          blk = { s = "Unknown block: " .. tostring(t) }
        end
        local ok, h = xpcall(function() return fn(E, blk, y) end, geterrorhandler())
        if ok then y = y + (tonumber(h) or 0) end
      end
    end
  end
  fecharSecao()
  for tipo, p in pairs(g.pool) do
    for i = (E.n[tipo] or 0) + 1, #p do p[i]:Hide() end
  end
  return y
end
