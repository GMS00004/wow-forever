local _, ns = ...
local function auraAtiva(nome)
  local ok, r = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", nome, "HELPFUL")
  if not ok then return nil end
  if issecretvalue and issecretvalue(r) then return nil end
  return r ~= nil
end
