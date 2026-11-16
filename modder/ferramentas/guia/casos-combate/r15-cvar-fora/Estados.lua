local _, ns = ...
-- R15: SetCVar fora de Convivencia.lua (mesmo com guarda e com o CVar certo)
local function esconder()
  if ns.emCombate() then return end
  C_CVar.SetCVar("damageMeterEnabled", "0")
end
