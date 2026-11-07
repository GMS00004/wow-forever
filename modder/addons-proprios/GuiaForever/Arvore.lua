-- GuiaForever: Plano de talentos e marcas na arvore (tarefas A6 e B1; contrato em ARQUITETURA.md, secao 5).
-- Fase A: o plano e o proximo ponto. Fase B (no fim do arquivo): marcas na arvore de talentos do jogo.
-- Nenhum outro arquivo depende deste existir (regra 3); este usa apenas a base (Estado.lua).

local _, ns = ...

ns.arvore = ns.arvore or {}
local A = ns.arvore

-- "Deadly Aspects 2/5" vira { nome, rank, max, texto }; "TBD" vira { tbd = true };
-- texto fora desse padrao fica com nome = texto.
local function lerEntrada(texto)
  if type(texto) ~= "string" then return nil end
  if string.upper(texto) == "TBD" then return { tbd = true } end
  local nome, rank, max = string.match(texto, "^(.-)%s+(%d+)/(%d+)$")
  if nome and nome ~= "" then
    return { nome = nome, rank = tonumber(rank), max = tonumber(max), texto = texto }
  end
  return { nome = texto, texto = texto }
end

-- [nivel] = entrada, a partir de GuiaForeverDados[classe].ordem.
function A.plano()
  local plano = {}
  local classe = (ns.estado and ns.estado.classe) or (ns.classe and ns.classe())
  local dados = classe and GuiaForeverDados and GuiaForeverDados[classe]
  local ordem = dados and dados.ordem
  if type(ordem) ~= "table" then return plano end
  for nivel, texto in pairs(ordem) do
    if type(nivel) == "number" then
      local e = lerEntrada(texto)
      if e then plano[nivel] = e end
    end
  end
  return plano
end

-- O proximo ponto a gastar: gastos = (nivel - 9) - pontos livres; a entrada e a do nivel 10 + gastos.
-- nil sem ponto livre, sem plano ou quando o jogo nao diz quantos pontos sobram.
function A.proximo()
  local livres = ns.pontosTalento and ns.pontosTalento()
  if type(livres) ~= "number" or livres <= 0 then return nil end
  local nivel = ns.estado and ns.estado.nivel
  if type(nivel) ~= "number" then return nil end
  local gastos = (nivel - 9) - livres
  if gastos < 0 then return nil end
  local alvo = 10 + gastos
  local e = A.plano()[alvo]
  if not e then return nil end
  local r = { nivel = alvo }
  for k, v in pairs(e) do r[k] = v end
  return r
end

-- Fase B: marcas na arvore de talentos (Blizzard_PlayerSpells) ------------------------------------
-- So marca; quem compra o ponto e o dono, com o clique (regra 7). Nada de SetScript em quadro da
-- Blizzard nem campo novo em tabela dela (regra 6): so HookScript, EventRegistry e tabelas fracas.
-- Entra quando o proprio jogo carrega o addon da janela; nunca o carregamos nem abrimos (regra 6).

local COR_NOW = { 1, 0.82, 0 }
local COR_NIVEL = { 0.7, 0.7, 0.7 }
local COR_ALL = { 0.2, 0.9, 0.8 }
local COR_ABERTO = { 1, 0.7, 0.1 }

local marcas = setmetatable({}, { __mode = "k" })     -- botao -> { quadro, texto, check }
local dadosBotao = setmetatable({}, { __mode = "k" }) -- botao -> { plano, aberto } (para o tooltip)
local ganchos = setmetatable({}, { __mode = "k" })    -- botao -> true (OnEnter ja enganchado)
local instalado = false
local dono = {}      -- dono dos callbacks do EventRegistry
local faixa          -- quadro da faixa no alto do TalentsFrame

local function emCombate()
  return InCombatLockdown and InCombatLockdown() and true or false
end

-- No Lua 5.1 o xpcall nao repassa argumentos: por isso o fechamento (regra 10).
local function seguro(fn, ...)
  local n = select("#", ...)
  local args = { ... }
  return xpcall(function() return fn(unpack(args, 1, n)) end, geterrorhandler())
end

local function minuscula(t)
  return type(t) == "string" and string.lower(t) or nil
end

-- "15-16" ou "10,12-13" a partir de uma lista de niveis em ordem.
local function formatarNiveis(niveis)
  local partes, i = {}, 1
  while i <= #niveis do
    local j = i
    while niveis[j + 1] == niveis[j] + 1 do j = j + 1 end
    partes[#partes + 1] = (j > i) and (niveis[i] .. "-" .. niveis[j]) or tostring(niveis[i])
    i = j + 1
  end
  return table.concat(partes, ",")
end

-- chave minuscula do talento -> { nome, entradas = { { nivel, rank, max }... } } (so o plano decidido).
local function grupos(plano)
  local g, niveis = {}, {}
  for nivel in pairs(plano) do niveis[#niveis + 1] = nivel end
  table.sort(niveis)
  for _, nivel in ipairs(niveis) do
    local e = plano[nivel]
    if e and not e.tbd and e.nome then
      local k = minuscula(e.nome)
      g[k] = g[k] or { nome = e.nome, entradas = {} }
      table.insert(g[k].entradas, { nivel = nivel, rank = e.rank, max = e.max })
    end
  end
  return g
end

local function dadosClasse()
  local classe = (ns.estado and ns.estado.classe) or (ns.classe and ns.classe())
  return classe and GuiaForeverDados and GuiaForeverDados[classe] or nil
end

-- Nomes do talento de um no (entrada ativa ou primeira; nome da magia e nome proprio) e rank atual.
local function infoDoNo(cfg, nodeID)
  local ok, res = pcall(function()
    local no = C_Traits.GetNodeInfo(cfg, nodeID)
    if type(no) ~= "table" then return nil end
    local entradaID = (no.activeEntry and no.activeEntry.entryID) or (no.entryIDs and no.entryIDs[1])
    local nomes = {}
    if entradaID then
      local ent = C_Traits.GetEntryInfo(cfg, entradaID)
      local defID = ent and ent.definitionID
      local def = defID and C_Traits.GetDefinitionInfo(defID)
      if def then
        local n1 = def.spellID and ns.nomeMagia and ns.nomeMagia(def.spellID)
        if n1 then nomes[#nomes + 1] = n1 end
        if def.overrideName then nomes[#nomes + 1] = def.overrideName end
      end
    end
    local rank = no.currentRank
    if type(rank) ~= "number" then rank = no.activeRank end
    return { nomes = nomes, rank = type(rank) == "number" and rank or 0 }
  end)
  if ok then return res end
  return nil
end

-- Marca de um botao: quadro filho, no canto de cima a direita.
local function obterMarca(botao)
  local m = marcas[botao]
  if m then return m end
  local q = CreateFrame("Frame", nil, botao)
  q:SetSize(40, 16)
  q:SetPoint("TOPRIGHT", botao, "TOPRIGHT", 6, 6)
  q:SetFrameLevel((botao:GetFrameLevel() or 1) + 20)
  local t = q:CreateFontString(nil, "OVERLAY")
  t:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
  t:SetPoint("RIGHT", q, "RIGHT", 0, 0)
  local c = q:CreateTexture(nil, "OVERLAY")
  c:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
  c:SetSize(18, 18)
  c:SetPoint("RIGHT", q, "RIGHT", 0, 0)
  c:Hide()
  q:Hide()
  m = { quadro = q, texto = t, check = c }
  marcas[botao] = m
  return m
end

local function mostrarTexto(botao, texto, cor)
  local m = obterMarca(botao)
  m.check:Hide()
  m.texto:SetText(texto)
  m.texto:SetTextColor(cor[1], cor[2], cor[3])
  m.texto:Show()
  m.quadro:Show()
end

local function mostrarCheck(botao)
  local m = obterMarca(botao)
  m.texto:SetText("")
  m.texto:Hide()
  m.check:Show()
  m.quadro:Show()
end

local function esconderTodas()
  for _, m in pairs(marcas) do m.quadro:Hide() end
end

local function talentos()
  local pv = PlayerSpellsFrame
  return pv and pv.TalentsFrame or nil
end

-- Texto da faixa; nil quando nao ha plano.
local function textoFaixa(plano, prox)
  if prox then
    local agora = prox.tbd and "your pick (sources differ)" or prox.texto
    local fim = "Plan: " .. tostring(agora) .. " now"
    local niveis = {}
    for nivel in pairs(plano) do
      if type(nivel) == "number" and nivel > prox.nivel then niveis[#niveis + 1] = nivel end
    end
    table.sort(niveis)
    for _, nivel in ipairs(niveis) do
      local e = plano[nivel]
      if e and not e.tbd and e.nome and e.nome ~= prox.nome then
        return fim .. ", " .. e.nome .. " at " .. nivel
      end
    end
    return fim
  end
  local nivel = ns.estado and ns.estado.nivel
  if type(nivel) ~= "number" then return nil end
  local n = math.max(nivel + 1, 10)
  local e = plano[n]
  if not e then return nil end
  return "Plan: next point at level " .. n .. ": " .. (e.tbd and "your pick (sources differ)" or e.texto)
end

local function atualizarFaixa(quadro, plano, prox)
  if not faixa then
    faixa = CreateFrame("Frame", nil, quadro)
    faixa:SetSize(420, 20)
    faixa:SetPoint("TOP", quadro, "TOP", 0, -8)
    faixa:SetFrameLevel((quadro:GetFrameLevel() or 1) + 50)
    faixa.texto = faixa:CreateFontString(nil, "OVERLAY")
    faixa.texto:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    faixa.texto:SetPoint("CENTER", faixa, "CENTER", 0, 0)
    faixa.texto:SetTextColor(COR_NOW[1], COR_NOW[2], COR_NOW[3])
  end
  local t = textoFaixa(plano, prox)
  if t then
    faixa.texto:SetText(t)
    faixa:Show()
  else
    faixa:Hide()
  end
end

-- Tooltip: no maximo 2 linhas, so se o GameTooltip for deste botao e fora de combate.
local function aoEntrar(botao)
  if emCombate() then return end
  local d = dadosBotao[botao]
  if not d or not GameTooltip or GameTooltip:GetOwner() ~= botao then return end
  local linhas = 0
  if d.plano then
    GameTooltip:AddLine(d.plano, COR_NOW[1], COR_NOW[2], COR_NOW[3])
    linhas = linhas + 1
  end
  if d.aberto and linhas < 2 then
    GameTooltip:AddLine(d.aberto, COR_ABERTO[1], COR_ABERTO[2], COR_ABERTO[3], true)
    linhas = linhas + 1
  end
  if linhas > 0 then GameTooltip:Show() end
end

local function enganchar(botao)
  if ganchos[botao] or not botao.HookScript then return end
  ganchos[botao] = true
  botao:HookScript("OnEnter", function(self) seguro(aoEntrar, self) end)
end

local function marcarBotao(botao, cfg, ctx)
  local id = botao.GetNodeID and botao:GetNodeID()
  if not id then return end
  local info = infoDoNo(cfg, id)
  if not info then return end
  enganchar(botao)
  local d = {}
  dadosBotao[botao] = d

  local grupo, ab
  for _, n in ipairs(info.nomes) do
    local k = minuscula(n)
    if not grupo and ctx.g[k] then grupo = ctx.g[k] end
    if not ab and ctx.abertos[k] then ab = ctx.abertos[k] end
  end
  if ab and ab.opcoes then
    local txt = table.concat(ab.opcoes, "; ")
    if string.len(txt) > 120 then txt = string.sub(txt, 1, 117) .. "..." end
    d.aberto = "Sources differ: " .. txt
  end

  if grupo then
    local pend, ultimo = {}, grupo.entradas[#grupo.entradas]
    for _, e in ipairs(grupo.entradas) do
      local feito = (e.rank and info.rank >= e.rank) or (not e.rank and info.rank >= 1)
      if not feito then pend[#pend + 1] = e end
    end
    if #pend > 0 then
      local p = pend[1]
      d.plano = "Plan: level " .. p.nivel .. (p.rank and (", " .. p.rank .. "/" .. (p.max or "?")) or "")
    else
      d.plano = "Plan: done at level " .. ultimo.nivel
        .. (ultimo.rank and (", " .. ultimo.rank .. "/" .. (ultimo.max or "?")) or "")
    end
    local ehProximo = false
    if ctx.nomeProx then
      for _, n in ipairs(info.nomes) do
        if minuscula(n) == ctx.nomeProx then ehProximo = true end
      end
    end
    if ehProximo then
      mostrarTexto(botao, "NOW", COR_NOW)
    elseif #pend == 0 then
      mostrarCheck(botao)
    else
      local niveis = {}
      for _, e in ipairs(pend) do niveis[#niveis + 1] = e.nivel end
      mostrarTexto(botao, formatarNiveis(niveis), COR_NIVEL)
    end
  elseif ab then
    mostrarTexto(botao, "?", COR_ABERTO)
  elseif ctx.temTbd then
    local consenso = false
    for _, n in ipairs(info.nomes) do
      local k = minuscula(n)
      if k and string.len(k) >= 4 then
        for _, t in ipairs(ctx.leiMin) do
          if string.find(t, k, 1, true) then consenso = true end
        end
      end
    end
    if consenso then mostrarTexto(botao, "ALL", COR_ALL) end
  end
end

local function atualizar()
  local quadro = talentos()
  if not quadro or not quadro:IsShown() or emCombate() then return end
  if not (C_Traits and C_Traits.GetNodeInfo and C_Traits.GetEntryInfo and C_Traits.GetDefinitionInfo) then return end
  local cfg = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
  if not cfg and quadro.GetConfigID then cfg = quadro:GetConfigID() end
  if not cfg or not quadro.EnumerateAllTalentButtons then return end

  esconderTodas()
  local plano = A.plano()
  local prox = A.proximo()
  local dados = dadosClasse() or {}
  local ctx = { g = grupos(plano), abertos = {}, leiMin = {}, temTbd = false }
  for _, e in pairs(plano) do
    if e.tbd then ctx.temTbd = true end
  end
  for i, t in ipairs(dados.lei or {}) do ctx.leiMin[i] = minuscula(t) or "" end
  for _, a in ipairs(dados.aberto or {}) do
    if a.ponto then ctx.abertos[minuscula(a.ponto)] = a end
  end
  ctx.nomeProx = prox and prox.nome and minuscula(prox.nome) or nil

  for botao in quadro:EnumerateAllTalentButtons() do
    seguro(marcarBotao, botao, cfg, ctx)
  end
  atualizarFaixa(quadro, plano, prox)
end

local function pedirAtualizacao()
  if emCombate() then return end
  local quadro = talentos()
  if not quadro or not quadro:IsShown() then return end
  if ns.agendar then
    ns.agendar("arvore:marcas", 0.15, function() seguro(atualizar) end)
  else
    seguro(atualizar)
  end
end

local function instalar()
  if instalado then return end
  local quadro = talentos()
  if not quadro then return end
  instalado = true
  quadro:HookScript("OnShow", function() pedirAtualizacao() end)
  if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback("TalentFrameBase.ButtonsUpdated", function() pedirAtualizacao() end, dono)
    EventRegistry:RegisterCallback("TalentFrameBase.ConfigUpdated", function() pedirAtualizacao() end, dono)
  end
  pedirAtualizacao()
end

if ns.ao then
  ns.ao("ADDON_LOADED", function(_, nome)
    if nome == "Blizzard_PlayerSpells" then instalar() end
  end)
  ns.ao("PLAYER_LEVEL_UP", pedirAtualizacao)
  ns.ao("TRAIT_TREE_CURRENCY_INFO_UPDATED", pedirAtualizacao)
  ns.ao("PLAYER_REGEN_ENABLED", pedirAtualizacao)
end
if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_PlayerSpells") then
  seguro(instalar)
end
