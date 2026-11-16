local _, ns = ...

-- unico lugar onde se mede texto: fora de combate, num texto escondido que nunca recebe segredo
local D = {}
ns.diario = D

function D.carga()
  local quadro = CreateFrame("Frame")
  local fs = quadro:CreateFontString(nil, "OVERLAY")
  fs:SetText("88888")
  return fs:GetStringWidth()
end
