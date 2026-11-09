local _, ns = ...
-- excecao do R2 (12.4): guarda de combate + issecretvalue
local function auraAtiva(nome)
  if ns.emCombate() then return nil end
  local ok, r = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", nome, "HELPFUL")
  if not ok then return nil end
  if issecretvalue and issecretvalue(r) then return nil end
  return r ~= nil
end
