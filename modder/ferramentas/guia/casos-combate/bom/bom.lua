local _, ns = ...
local function emCombate() return InCombatLockdown and InCombatLockdown() end
ns.emCombate = emCombate

-- R1 forma 1: if com emCombate e return antes da chamada
local function macroA()
  if ns.emCombate() then return end
  CreateMacro("a", 1, "/cast Foo", true)
end

-- R1 forma 2: pcall dentro de funcao guardada
local function cvarB(n, v)
  if InCombatLockdown() then return false end
  return pcall(SetCVar, n, v)
end

-- R1 forma 3: comentario na linha de cima
-- fora-de-combate
local function bindC(k)
  SetBinding(k, nil)
end

-- R1: o comentario pode ficar na linha de cima da chamada
local function bindD(f)
  -- fora-de-combate
  f:SetAttribute("type", "macro")
end

-- R7 forma 1: if X and X.Y then ... X.Y(...)
local function petA()
  if C_Foo and C_Foo.Bar then return C_Foo.Bar(1) end
end

-- R7 forma 2: X and X.Y and X.Y(...)
local function petB()
  return C_Foo and C_Foo.Bar and C_Foo.Bar(2)
end

-- R7 forma 3: pcall(X.Y, ...) com X.Y checado antes
local function petC()
  if not (C_Foo and C_Foo.Bar) then return end
  return pcall(C_Foo.Bar, 3)
end

-- globais do proprio addon e de terceiros
function GuiaForever_Algo() return 1 end
local function terceiros()
  GuiaForever_Algo()
  if TomTom then TomTom:AddWaypoint(1, 0.5, 0.5, {}) end
  return math.floor(2.5) + strlen("x")
end

-- texto em string nao conta (corpo de macro)
local corpo = "/run SetCVar('x', 1) UnitAttackSpeed('pet') CastSpellByName('Foo') COMBAT_LOG_EVENT_UNFILTERED"

-- SetScript em quadro local; SlashCmdList; globais com prefixo
local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
f:SetScript("OnEvent", function() end)
f:RegisterEvent("PLAYER_LOGIN")
ns.ao("PLAYER_REGEN_ENABLED", function() end)
GuiaForeverDB = GuiaForeverDB or {}
SLASH_GUIAFOREVER1 = "/gf"
SlashCmdList["GUIAFOREVER"] = function() end
BINDING_HEADER_GUIAFOREVER = "GuiaForever"
_G["BINDING_NAME_GUIAFOREVER_X"] = "x"
