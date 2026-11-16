local _, ns = ...
function ns.pintar(texto, ativo)
  if ativo then texto:SetTextColor(0, 1, 0) else texto:SetTextColor(1, 0, 0) end
end
