local _, ns = ...

local P = {}
ns.painel = P
local alfa = 1

-- metodo definido no proprio addon (R14)
function P:ajustaAlfa(a)
  alfa = a
  self.quadro:SetAlpha(alfa)
end

function P.criar()
  local f = CreateFrame("Frame", "CentralForeverPainel", UIParent)
  f:SetSize(436, 76)
  f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -8, 8)
  f:EnableMouse(false)
  local fundo = f:CreateTexture(nil, "BACKGROUND")
  fundo:SetAllPoints(f)
  fundo:SetColorTexture(0, 0, 0, 0.6)
  local fs = f:CreateFontString(nil, "OVERLAY")
  fs:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
  fs:SetJustifyH("RIGHT")
  fs:SetWordWrap(false)
  local barra = CreateFrame("StatusBar", nil, f)
  barra:SetMinMaxValues(0, 100)
  P.quadro = f
  P.dps = fs
  P.barra = barra
  P:ajustaAlfa(1)
  return true
end

function P.mostrar(s)
  if ns.segredo and ns.segredo.mostrarInteiro and P.dps then ns.segredo.mostrarInteiro(P.dps, s) end
  if P.quadro then P.quadro:SetShown(true) end
end
