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

local function sabeSkinning()
  if not ns.minhasProfissoes then return false end
  local ok, lista = pcall(ns.minhasProfissoes)
  if not (ok and type(lista) == "table") then return false end
  for _, pr in ipairs(lista) do
    if pr.nome == "Skinning" then return true end
  end
  return false
end

local agendar -- definida mais abaixo; os ganchos do criarQuadro a chamam

-- Quadros que o ElvUI pode empilhar embaixo do minimapa: o painel Guild/Friends
-- e as barras de dados. O rastreador desce para baixo do ultimo da pilha que
-- estiver visivel (0.9.1: no print do dono de 06/11, 22h56, a barra de
-- reputacao, logo abaixo do painel, cobria a linha do Leatherworking).
local SOB_MINIMAPA = { "MinimapPanel", "ElvUI_ReputationBar", "ElvUI_HonorBar", "ElvUI_AzeriteBar", "ElvUI_ThreatBar" }
local FOLGA = 12 -- distancia maxima, em unidades da UI, entre um quadro e o de cima na pilha

-- borda em pixels de tela, para comparar quadros com escalas diferentes
local function borda(f, lado)
  local v = f[lado](f)
  local s = f:GetEffectiveScale()
  return v and s and v * s
end

local function ancora()
  local mapa = _G.Minimap
  if not (mapa and mapa:IsVisible()) then return nil end
  local esq, dir, base = borda(mapa, "GetLeft"), borda(mapa, "GetRight"), borda(mapa, "GetBottom")
  if not (esq and dir and base) then return mapa end
  local folga = FOLGA * UIParent:GetEffectiveScale()
  local atual, usados, mudou = mapa, {}, true
  while mudou do
    mudou = false
    for _, nome in ipairs(SOB_MINIMAPA) do
      local f = _G[nome]
      if f and not usados[nome] and f.IsVisible and f:IsVisible() then
        local l, r, b, t = borda(f, "GetLeft"), borda(f, "GetRight"), borda(f, "GetBottom"), borda(f, "GetTop")
        -- na coluna do minimapa, encostado (ou quase) embaixo do ultimo da pilha
        if l and r and b and t and r > esq and l < dir and t <= base + folga and t >= base - folga and b < base then
          atual, base, usados[nome], mudou = f, b, true, true
        end
      end
    end
  end
  return atual
end

local function posicionar()
  local a = ancora()
  quadro:ClearAllPoints()
  if a then quadro:SetPoint("TOP", a, "BOTTOM", 0, -4)
  else quadro:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -230) end
end

local function criarQuadro()
  if quadro then return end
  quadro = CreateFrame("Frame", "GuiaForeverRastreadorQuadro", UIParent)
  quadro:SetSize(220, 14)
  quadro:SetFrameStrata("LOW")
  quadro:EnableMouse(true)
  posicionar()
  -- a barra de reputacao aparece quando uma faccao passa a ser acompanhada;
  -- quando um quadro da pilha aparece ou some, o rastreador se reposiciona
  for _, nome in ipairs(SOB_MINIMAPA) do
    local f = _G[nome]
    if f and f.HookScript then
      f:HookScript("OnShow", function() agendar() end)
      f:HookScript("OnHide", function() agendar() end)
    end
  end
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
    if sabeSkinning() and ns.bichosDaZona and ns.colorirBicho then
      local partes = {}
      for _, b in ipairs(ns.bichosDaZona(3)) do partes[#partes + 1] = ns.colorirBicho(b.cor, b.nome) end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Skin here: " .. (#partes > 0 and table.concat(partes, ", ") or "no skinnable creature known here"), 1, 1, 1, true)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(CINZA .. "Sources: wow-professions (Skinning), ReptilioPlays (Leatherworking). /guia tracker hides it." .. FIM, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  quadro:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Fonte das linhas do rastreador: GameFontHighlightSmall com tamanho 13, criada uma vez.
-- Sem CreateFont (ou se falhar), volta para a fonte da Blizzard.
local nomeFonte
local function fonteRastreador()
  if nomeFonte then return nomeFonte end
  nomeFonte = "GameFontHighlightSmall"
  if CreateFont and GameFontHighlightSmall then
    pcall(function()
      local f = _G.GuiaForeverFonteRastreador or CreateFont("GuiaForeverFonteRastreador")
      f:SetFontObject(GameFontHighlightSmall)
      local arq, _, flags = f:GetFont()
      if arq then f:SetFont(arq, 13, flags) end
      if _G.GuiaForeverFonteRastreador then nomeFonte = "GuiaForeverFonteRastreador" end
    end)
  end
  return nomeFonte
end

local ALTURA_LINHA = 17 -- 13 de fonte com folga

local function texto(i)
  if not textos[i] then
    local t = quadro:CreateFontString(nil, "OVERLAY", fonteRastreador())
    t:SetPoint("TOP", quadro, "TOP", 0, -(i - 1) * ALTURA_LINHA)
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
    quadro:SetHeight(n * ALTURA_LINHA + 2)
    posicionar()
    quadro:Show()
  end
end

function agendar()
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

-- Provedor "profissao" do painel Agora: profissao no teto do treino e abaixo da meta da area.
-- Zona.lua e Agora.lua carregam depois deste arquivo no .toc (Agora nao existe aqui), entao o
-- registro so acontece em PLAYER_LOGIN.
local function itensTeto(ctx)
  local faixa = faixaAtual()
  if not faixa then return {} end
  local planejadas = (GuiaForeverProfissoesPlanejadas and ns.classe and GuiaForeverProfissoesPlanejadas[ns.classe()]) or {}
  local nivel = (ctx and ctx.nivel) or (UnitLevel and UnitLevel("player")) or 1
  local conhecidas = {}
  for _, pr in ipairs(ns.minhasProfissoes and ns.minhasProfissoes() or {}) do conhecidas[pr.nome] = pr end
  local treinos = ns.TREINOS or {}
  local r = {}
  for _, nome in ipairs(planejadas) do
    local meta = faixa.metas[nome]
    local pr = conhecidas[nome]
    if meta and pr and pr.maximo and pr.maximo > 0 and pr.pericia >= pr.maximo and pr.maximo < meta then
      local prox
      for _, tr in ipairs(treinos) do
        if tr.vai > pr.maximo then prox = tr; break end
      end
      if prox then
        local texto, botao
        if nivel >= prox.nivel then
          texto = nome .. " capped at " .. pr.maximo .. ": train " .. prox.nome
          botao = { rotulo = "Arrow", acao = function() if ns.setaTreinador then ns.setaTreinador(nome) end end }
        else
          texto = nome .. " capped at " .. pr.maximo .. ": " .. prox.nome .. " at level " .. prox.nivel
        end
        r[#r + 1] = {
          chave = "prof:teto:" .. nome, prio = 70, cor = "laranja", texto = texto,
          dica = { "Goal for this area: " .. meta .. ", current cap " .. pr.maximo .. ".",
            "Next training: " .. prox.nome .. " (character level " .. prox.nivel .. ")." },
          fonte = "GuiaForever profession goals", aba = "prof", botao = botao,
        }
      end
    end
  end
  return r
end

local function registrarProvedor()
  if not (ns.agora and ns.agora.provedor) then return end
  ns.agora.provedor({
    id = "profissao",
    eventos = { "SKILL_LINES_CHANGED", "ZONE_CHANGED_NEW_AREA", "PLAYER_LEVEL_UP", "CHAT_MSG_SKILL" },
    itens = itensTeto,
  })
end
local evProvedor = CreateFrame("Frame")
evProvedor:RegisterEvent("PLAYER_LOGIN")
evProvedor:SetScript("OnEvent", function(self)
  self:UnregisterEvent("PLAYER_LOGIN")
  pcall(registrarProvedor)
end)

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
