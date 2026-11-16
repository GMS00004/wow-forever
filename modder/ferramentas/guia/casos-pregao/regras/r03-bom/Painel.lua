local _, ns = ...
local quadro = CreateFrame("Frame")
quadro:SetScript("OnEvent", ns.seguro(function(self, evento) ns.tratar(evento) end))
C_Timer.After(1, ns.seguro(function() ns.atualizar() end))
