local _, ns = ...
-- sem perfil: um addon comum nao pode ler o threat
local function ameaca()
  return UnitDetailedThreatSituation("player", "target")
end
