local _, ns = ...

-- so usa ns.segredo, nunca as funcoes da secao 2 nem o campo cru
local E = {}
ns.estados = E
local tique

function E.entrar()
  if tique then return end
  tique = ns.tique(0.25, function()
    if ns.segredo and ns.segredo.estado then ns.segredo.estado("player", "target") end
  end)
end

function E.sair()
  if tique then tique:Cancel() end
  tique = nil
end

ns.ao("PLAYER_ENTERING_WORLD", function() E.sair() end)
ns.ao("PLAYER_REGEN_DISABLED", function() E.entrar() end)
ns.ao("PLAYER_REGEN_ENABLED", function() E.sair() end)
ns.ao("ADDON_RESTRICTION_STATE_CHANGED", function() end)
ns.ao("DAMAGE_METER_COMBAT_SESSION_UPDATED", function() end)
ns.ao("DAMAGE_METER_RESET", function() end)
ns.ao("UNIT_THREAT_LIST_UPDATE", function() end)
ns.ao("PLAYER_TARGET_CHANGED", function() end)
ns.ao("GROUP_ROSTER_UPDATE", function() end)
ns.ao("UNIT_PET", function() end)

SLASH_CENTRALFOREVER1 = "/central"
SlashCmdList["CENTRALFOREVER"] = function(texto)
  if texto == "reset" and ns.segredo then ns.segredo.zerar() end
end
