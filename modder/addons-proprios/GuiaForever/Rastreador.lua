-- GuiaForever: rastreador discreto de profissoes, embaixo do minimapa.
-- Uma linha por profissao planejada que tem meta na faixa da area atual
-- (GuiaForeverRastreador, em Dados.lua): pericia / meta, verde quando a meta foi
-- batida, e um aviso quando o teto do treino esta abaixo da meta. O mouse em
-- cima mostra a area, a faixa, o teto e o proximo passo do roteiro da
-- profissao. Pedido do dono em 2026-11-06. /guia rastreador mostra ou esconde.

local NOME, ns = ...
local cfg = GuiaForeverRastreador
if not cfg then return end

local VERDE, CINZA, AMARELO, FIM = "|cff40ff40", "|cff9d9d9d", "|cffffd100", "|r"

local quadro, textos = nil, {}
local agendado = false
local estado = {} -- o que a ultima atualizacao mostrou, para o tooltip

local function oculto()
  return GuiaForeverDB and GuiaForeverDB.rastreadorOculto
end

local function faixaAtual()
  local zona = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
  local id = cfg.zonas and cfg.zonas[zona]
  local origem = zona
  if not id then
    local nivel = UnitLevel("player") or 1
    for i, fx in ipairs(cfg.faixas) do
      if nivel >= fx.nivelDe and nivel <= fx.nivelAte then id = i; break end
    end
    origem = (zona ~= "" and (zona .. ", ") or "") .. "by level " .. nivel
  end
  return id and cfg.faixas[id], origem
end

local function ancora()
  local painel = _G.MinimapPanel
  if painel and painel:IsShown() then return painel end
  return _G.Minimap
end

local function criarQuadro()
  if quadro then return end
  quadro = CreateFrame("Frame", "GuiaForeverRastreadorQuadro", UIParent)
  quadro:SetSize(220, 14)
  quadro:SetFrameStrata("LOW")
  quadro:EnableMouse(true)
  local a = ancora()
  if a then quadro:SetPoint("TOP", a, "BOTTOM", 0, -4)
  else quadro:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -230) end
  quadro:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Profession goals for this area")
    GameTooltip:AddLine(CINZA .. "Area: " .. tostring(estado.origem) .. FIM)
    if estado.faixa then
      GameTooltip:AddLine(CINZA .. "Level range: " .. estado.faixa.nome .. FIM)
    end
    for _, l in ipairs(estado.linhas or {}) do
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(l.titulo, 1, 1, 1)
      for _, d in ipairs(l.detalhes) do GameTooltip:AddLine(d, 0.85, 0.85, 0.85, true) end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(CINZA .. "Sources: wow-professions (Skinning), Gfinity (Leatherworking). /guia tracker hides it." .. FIM, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  quadro:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function texto(i)
  if not textos[i] then
    local t = quadro:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("TOP", quadro, "TOP", 0, -(i - 1) * 13)
    t:SetJustifyH("CENTER")
    textos[i] = t
  end
  return textos[i]
end

local function atualizar()
  agendado = false
  if not cfg.ligado or oculto() then
    if quadro then quadro:Hide() end
    return
  end
  criarQuadro()
  if cfg.esconderEmCombate and InCombatLockdown and InCombatLockdown() then
    quadro:Hide()
    return
  end

  local faixa, origem = faixaAtual()
  estado = { origem = origem, faixa = faixa, linhas = {} }
  local conhecidas = {}
  for _, pr in ipairs(ns.minhasProfissoes and ns.minhasProfissoes() or {}) do conhecidas[pr.nome] = pr end
  local planejadas = (GuiaForeverProfissoesPlanejadas and ns.classe and GuiaForeverProfissoesPlanejadas[ns.classe()]) or {}

  local n = 0
  if faixa then
    for _, nome in ipairs(planejadas) do
      local meta = faixa.metas[nome]
      if meta then
        n = n + 1
        local pr = conhecidas[nome]
        local linha, det = nil, {}
        if not pr then
          linha = CINZA .. nome .. ": learn (/guia trainers)" .. FIM
          det[#det + 1] = "Not learned yet. Goal for this area: " .. meta .. "."
        else
          local cor = (pr.pericia >= meta) and VERDE or ""
          linha = cor .. nome .. " " .. pr.pericia .. " / " .. meta .. (cor ~= "" and FIM or "")
          if pr.maximo and pr.maximo > 0 and pr.maximo < meta then
            linha = linha .. AMARELO .. "  cap " .. pr.maximo .. FIM
            det[#det + 1] = "Your current training caps at " .. pr.maximo .. ": train the next rank to reach " .. meta .. "."
          end
          if pr.pericia >= meta then
            det[#det + 1] = "Goal for this area reached."
          else
            det[#det + 1] = (meta - pr.pericia) .. " points to go for this area's goal."
          end
          if ns.indicePasso and pr.tab and pr.tab.passos then
            local passo = pr.tab.passos[ns.indicePasso(pr.tab, pr.pericia)]
            if passo then det[#det + 1] = "Route " .. passo.de .. "-" .. passo.ate .. ": " .. passo.texto end
          end
        end
        texto(n):SetText(linha)
        texto(n):Show()
        estado.linhas[#estado.linhas + 1] = { titulo = nome, detalhes = det }
      end
    end
  end
  for i = n + 1, #textos do textos[i]:Hide() end
  if n == 0 then
    quadro:Hide()
  else
    quadro:SetHeight(n * 13 + 2)
    quadro:Show()
  end
end

local function agendar()
  if agendado then return end
  agendado = true
  if C_Timer and C_Timer.After then C_Timer.After(0.5, atualizar) else atualizar() end
end

function ns.alternarRastreador()
  GuiaForeverDB = GuiaForeverDB or {}
  GuiaForeverDB.rastreadorOculto = not GuiaForeverDB.rastreadorOculto
  print("|cff66ccffGuiaForever|r: profession tracker " .. (GuiaForeverDB.rastreadorOculto and "hidden." or "shown."))
  atualizar()
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL",
    "PLAYER_LEVEL_UP", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
  pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e)
  if e == "PLAYER_REGEN_DISABLED" then
    if cfg.esconderEmCombate and quadro then quadro:Hide() end
    return
  end
  agendar()
end)
