local _, ns = ...
function ns.pintar(texto, ativo)
  texto:SetText(ativo and "Active" or "Idle")
  texto:SetTextColor(0, 1, 0)
end
