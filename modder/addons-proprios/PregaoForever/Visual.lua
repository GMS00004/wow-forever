-- Visual.lua (PregaoForever): kit ns.ui, copia enxuta do kit do GuiaForever (cores, fontes, painel, botao)
-- so com o que as telas da onda 2 usam. Fontes: so objetos de fonte do cliente (regra 12), nunca arquivo.
-- Contrato: ARQUITETURA.md, secao 3.12. Nada aqui e protegido; quadros so nascem quando a janela desenha.
local _, ns = ...
ns.ui = ns.ui or {}
local ui = ns.ui

local WHITE = "Interface\\Buttons\\WHITE8X8"
local floor = math.floor

-- Leitura segura de outro modulo (so funcoes publicas do contrato): devolve nil se faltar ou der erro.
function ui.ler(modulo, nome, ...)
  local m = ns[modulo]
  if type(m) ~= "table" or type(m[nome]) ~= "function" then return nil end
  local ok, a, b = pcall(m[nome], ...)
  if ok then return a, b end
  return nil
end

-- Cores ----------------------------------------------------------------------
local CORES = {
  fundo = { 0.05, 0.05, 0.05, 0.92 },
  botao = { 1, 1, 1, 0.07 },
  cinza = { 0.65, 0.65, 0.65, 1 },
  texto = { 1, 1, 1, 1 },
  verde = { 0.3, 0.85, 0.3, 1 },
  vermelho = { 0.95, 0.3, 0.3, 1 },
  laranja = { 1, 0.55, 0.1, 1 },
  amarelo = { 1, 0.85, 0.1, 1 },
  azul = { 0.4, 0.7, 1, 1 },
  dourado = { 1, 0.82, 0, 1 },
}

function ui.cor(nome)
  local t = CORES[nome] or CORES.texto
  return t[1], t[2], t[3], t[4] or 1
end

function ui.hex(nome)
  local r, g, b = ui.cor(nome)
  return string.format("|cff%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

-- Fontes: objetos de fonte do cliente --------------------------------------------
local FONTES = {
  titulo = "GameFontNormalLarge",
  texto = "GameFontHighlight",
  menor = "GameFontHighlightSmall",
  secao = "GameFontNormalSmall",
}

function ui.fonte(nome)
  return FONTES[nome] or FONTES.texto
end

-- Texto -------------------------------------------------------------------------------
function ui.fs(pai, fonte, camada)
  local fs = pai:CreateFontString(nil, camada or "OVERLAY")
  local nome = ui.fonte(fonte or "menor")
  fs:SetFontObject(_G[nome] or nome)
  fs:SetJustifyH("LEFT")
  fs:SetWordWrap(false)
  return fs
end

-- Texto e cor juntos: estado nunca so em cor (regra 12).
function ui.texto(fs, texto, cor)
  fs:SetText(tostring(texto or ""))
  fs:SetTextColor(ui.cor(cor or "texto"))
end

-- Painel e botao ---------------------------------------------------------------------------
function ui.painel(f, estilo)
  if not f then return f end
  local r, g, b, a = ui.cor("fundo")
  if estilo == "botao" then r, g, b, a = ui.cor("botao") end
  pcall(function()
    if not f.SetBackdrop and Mixin and BackdropTemplateMixin then Mixin(f, BackdropTemplateMixin) end
    if f.SetBackdrop then
      f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
      f:SetBackdropColor(r, g, b, a)
      f:SetBackdropBorderColor(0, 0, 0, 1)
    end
  end)
  if ns.pontes and type(ns.pontes.elvui) == "function" then pcall(ns.pontes.elvui, f) end
  return f
end

-- Botao clicavel sempre com nome PregaoForever* e rotulo escrito (o clique e do chamador).
function ui.botao(pai, nome, rotulo, w, h)
  local b = CreateFrame("Button", nome, pai, "BackdropTemplate")
  b:SetSize(w or 60, h or 24)
  b.fs = ui.fs(b, "menor")
  b.fs:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.fs:SetJustifyH("CENTER")
  ui.texto(b.fs, rotulo, "texto")
  ui.painel(b, "botao")
  b:HookScript("OnEnter", ns.seguro(function(self)
    if self.SetBackdropColor then self:SetBackdropColor(1, 1, 1, 0.16) end
  end))
  b:HookScript("OnLeave", ns.seguro(function(self)
    if self.SetBackdropColor then self:SetBackdropColor(1, 1, 1, 0.07) end
  end))
  return b
end

-- Rotulo do botao; ativo = false pinta de cinza (a palavra do estado vai no proprio rotulo ou na linha).
function ui.rotular(b, rotulo, ativo)
  ui.texto(b.fs, rotulo, (ativo == false) and "cinza" or "texto")
end

-- Linhas de tela --------------------------------------------------------------------------------
-- Linha = { rot, palavra, cp, t, cols, botao, sel, cor, rc }:
--   rot  rotulo da secao (cinza)      palavra  palavra de estado, na cor cp      t  corpo
--   cols colunas fixas (texto ou { t, cor })   botao  texto do botao que fica por cima (so no plano)
function ui.corpo(l, colorido)
  local s = ""
  if l.palavra ~= nil and l.palavra ~= "" then
    if colorido then
      s = ui.hex(l.cp or "texto") .. tostring(l.palavra) .. "|r"
    else
      s = tostring(l.palavra)
    end
    if l.t ~= nil and l.t ~= "" then s = s .. " " end
  end
  if l.t ~= nil then s = s .. tostring(l.t) end
  if colorido and l.cor and l.cor ~= "texto" and (l.palavra == nil or l.palavra == "") and s ~= "" then
    s = ui.hex(l.cor) .. s .. "|r"
  end
  return s
end

function ui.coluna(c, colorido)
  if type(c) == "table" then
    local s = tostring(c.t or "")
    if colorido and c.cor and s ~= "" then s = ui.hex(c.cor) .. s .. "|r" end
    return s
  end
  return tostring(c or "")
end

-- Texto plano (sem codigo de cor) de uma linha, para ns.__tela.linhas e para a bancada.
function ui.plano(l)
  local partes = {}
  if l.rot ~= nil and l.rot ~= "" then partes[#partes + 1] = tostring(l.rot) end
  if l.cols then
    local cs = {}
    for i = 1, #l.cols do cs[#cs + 1] = ui.coluna(l.cols[i], false) end
    partes[#partes + 1] = table.concat(cs, "  ")
  else
    local c = ui.corpo(l, false)
    if c ~= "" then partes[#partes + 1] = c end
  end
  if l.botao ~= nil and l.botao ~= "" then partes[#partes + 1] = tostring(l.botao) end
  local s = table.concat(partes, "  ")
  if l.sel then s = "> " .. s else s = "  " .. s end
  return s
end
