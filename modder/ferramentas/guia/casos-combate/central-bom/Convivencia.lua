local _, ns = ...

local C = {}
ns.convivencia = C

-- a unica funcao protegida do addon: so este CVar, so fora de combate
function C.aplicar()
  if ns.emCombate() then return end
  C_CVar.SetCVar("damageMeterEnabled", "0")
end
