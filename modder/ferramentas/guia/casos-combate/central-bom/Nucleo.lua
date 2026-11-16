local _, ns = ...

CentralForeverConfig = CentralForeverConfig or {}
CentralForeverDB = CentralForeverDB or {}
ns.cfg = CentralForeverConfig

local ouvintes = {}
local quadro = CreateFrame("Frame")

function ns.seguro(fn)
  return function(...) return xpcall(fn, geterrorhandler(), ...) end
end

function ns.emCombate()
  return InCombatLockdown() and true or false
end

function ns.ao(evento, fn)
  ouvintes[evento] = ouvintes[evento] or {}
  tinsert(ouvintes[evento], fn)
  pcall(quadro.RegisterEvent, quadro, evento)
end

ns.ao("ADDON_LOADED", function(_, nome)
  if nome ~= "CentralForever" then return end
  ns.pronto = true
end)
