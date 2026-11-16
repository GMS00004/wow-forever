local _, ns = ...
-- R15: em Convivencia.lua e com guarda, mas de outro CVar
local function mexer()
  if ns.emCombate() then return end
  C_CVar.SetCVar("damageMeterResetOnNewInstance", "1")
end
