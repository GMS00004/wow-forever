local _, ns = ...
local quadro = CreateFrame("Frame")
quadro:SetScript("OnUpdate", ns.seguro(function(self, dt) ns.desenhar(dt) end))
C_Timer.After(2, ns.seguro(function() ns.mostrarEstado() end))
