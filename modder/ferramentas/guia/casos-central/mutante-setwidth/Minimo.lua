-- MUTANTE (A2): SetWidth com valor secreto. Copia do minimo com UMA violacao, marcada com "-- VIOLACAO".
local _, ns = ...

CentralForeverConfig = { threat = { pulsoMinSeg = 8 } }
ns.cfg = CentralForeverConfig
ns.painel = {}
local P = ns.painel

local raiz, texto, barra, anim
local sujo = false
local ultimoPulso = -100
local ticker

function P.criar()
  if raiz then return true end
  raiz = CreateFrame("Frame", "CentralForeverPainel", UIParent)
  raiz:SetSize(200, 60)
  raiz:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -4, 31)
  raiz:SetFrameStrata("MEDIUM")
  texto = raiz:CreateFontString(nil, "OVERLAY")
  texto:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
  texto:SetPoint("CENTER", raiz, "CENTER", 0, 0)
  texto:SetText("--")
  barra = CreateFrame("StatusBar", nil, raiz)
  barra:SetSize(100, 6)
  barra:SetPoint("BOTTOM", raiz, "BOTTOM", 0, 4)
  barra:SetMinMaxValues(0, 100)
  barra:SetValue(0)
  local pulso = raiz:CreateTexture(nil, "ARTWORK")
  pulso:SetAllPoints(raiz)
  pulso:SetColorTexture(1, 1, 1, 0.3)
  pulso:SetAlpha(0)
  anim = pulso:CreateAnimationGroup()
  local a = anim:CreateAnimation("Alpha")
  a:SetFromAlpha(0)
  a:SetToAlpha(1)
  a:SetDuration(0.3)
  a:SetOrder(1)
  return true
end

function P.existe() return raiz ~= nil end

local function atualizar()
  if not raiz then return end
  if sujo then
    sujo = false
    local ok, sessao = pcall(C_DamageMeter.GetCombatSessionFromType, Enum.DamageMeterSessionType.Current, Enum.DamageMeterType.DamageDone)
    if ok and type(sessao) == "table" then
      local fontes = sessao.combatSources
      if canaccesstable(fontes) then
        for _, f in ipairs(fontes) do
          if f.isLocalPlayer == true then
            texto:SetText(AbbreviateNumbers(f.amountPerSecond))
            barra:SetWidth(f.totalAmount) -- VIOLACAO
            break
          end
        end
      end
    end
  end
  local _, estado, pct = UnitDetailedThreatSituation("player", "target")
  barra:SetValue(pct)
  local sit = UnitThreatSituation("player", "target")
  if not issecretvalue(sit) and sit and sit >= 2 and GetTime() - ultimoPulso >= 8 then
    ultimoPulso = GetTime()
    anim:Stop()
    anim:Play()
  end
end

local quadro = CreateFrame("Frame")
quadro:RegisterEvent("ADDON_LOADED")
quadro:RegisterEvent("PLAYER_ENTERING_WORLD")
quadro:RegisterEvent("PLAYER_REGEN_DISABLED")
quadro:RegisterEvent("PLAYER_REGEN_ENABLED")
quadro:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
quadro:SetScript("OnEvent", function(_, evento, arg)
  if evento == "ADDON_LOADED" then
    if arg == "CentralForever" then
      CentralForeverDB = CentralForeverDB or { lutas = 0 }
    end
  elseif evento == "PLAYER_ENTERING_WORLD" then
    P.criar()
  elseif evento == "PLAYER_REGEN_DISABLED" then
    if not ticker then ticker = C_Timer.NewTicker(0.25, atualizar) end
  elseif evento == "PLAYER_REGEN_ENABLED" then
    if ticker then ticker:Cancel() ticker = nil end
    CentralForeverDB.lutas = CentralForeverDB.lutas + 1
  elseif evento == "DAMAGE_METER_COMBAT_SESSION_UPDATED" then
    sujo = true
  end
end)
