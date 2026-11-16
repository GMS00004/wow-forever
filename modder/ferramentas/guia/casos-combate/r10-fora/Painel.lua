local _, ns = ...
-- R10: funcao da secao 2 chamada fora de Segredo.lua
local function ler()
  return UnitThreatSituation("player", "target")
end
