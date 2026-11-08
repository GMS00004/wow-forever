-- UIForever: aplica no login o layout do ElvUI, as teclas, o conteudo das
-- barras por classe, as opcoes do menu (CVars), a barra de experiencia da
-- Blizzard (com a XP das quests do log) e o minimapa grande, tudo
-- vindo de Config.lua.
-- So API oficial, nada em combate. Diario das acoes em UIForeverDB.log
-- (o modder le no arquivo de SavedVariables com o jogo fechado).

local NOME = "UIForever"
local cfg = UIForeverConfig
local f = CreateFrame("Frame")
local E -- ElvUI

local function msg(texto)
  print("|cff66ccffUIForever|r: " .. texto)
end

local function registrar(texto)
  UIForeverDB.log = UIForeverDB.log or {}
  local log = UIForeverDB.log
  log[#log + 1] = date("%Y-%m-%d %H:%M:%S") .. " " .. texto
  while #log > 60 do table.remove(log, 1) end
end

local function emCombate()
  return InCombatLockdown and InCombatLockdown()
end

local function depois(seg, fn)
  if C_Timer and C_Timer.After then C_Timer.After(seg, fn) else fn() end
end

local function copiar(v)
  if type(v) ~= "table" then return v end
  local t = {}
  for k, x in pairs(v) do t[k] = copiar(x) end
  return t
end

local function serializar(v)
  if type(v) ~= "table" then return type(v) .. ":" .. tostring(v) end
  local chaves = {}
  for k in pairs(v) do chaves[#chaves + 1] = tostring(k) end
  table.sort(chaves)
  local partes = {}
  for _, k in ipairs(chaves) do partes[#partes + 1] = k .. "=" .. serializar(v[k]) end
  return "{" .. table.concat(partes, ",") .. "}"
end

local function separar(caminho)
  local t = {}
  for parte in string.gmatch(caminho, "[^%.]+") do t[#t + 1] = parte end
  return t
end

---------------------------------------------------------------------------
-- 1. Perfil do ElvUI, gravado na tabela crua antes de o ElvUI montar a tela
---------------------------------------------------------------------------

local function gravarNoPerfil(perfil, caminho, valor)
  local partes = separar(caminho)
  local t = perfil
  for i = 1, #partes - 1 do
    local k = partes[i]
    if type(t[k]) ~= "table" then t[k] = {} end
    t = t[k]
  end
  t[partes[#partes]] = copiar(valor)
end

local function prepararPerfilElvUI()
  if not (ElvDB and ElvDB.profiles and E and E.mynameRealm) then
    registrar("ElvUI sem banco de dados; perfil nao aplicado")
    return
  end
  ElvDB.profileKeys = ElvDB.profileKeys or {}
  local chave = E.mynameRealm
  local nomePerfil = ElvDB.profileKeys[chave]

  -- Personagem novo: usa o perfil compartilhado e pula o assistente do ElvUI.
  if not nomePerfil and UIForeverDB.perfil and ElvDB.profiles[UIForeverDB.perfil] then
    nomePerfil = UIForeverDB.perfil
    ElvDB.profileKeys[chave] = nomePerfil
    registrar("personagem novo " .. chave .. " ligado ao perfil " .. nomePerfil)
    if ElvPrivateDB and UIForeverDB.privadoModelo then
      ElvPrivateDB.profileKeys = ElvPrivateDB.profileKeys or {}
      ElvPrivateDB.profiles = ElvPrivateDB.profiles or {}
      if not ElvPrivateDB.profileKeys[chave] then
        ElvPrivateDB.profileKeys[chave] = chave
        ElvPrivateDB.profiles[chave] = copiar(UIForeverDB.privadoModelo)
        UIForeverCharDB.configurarChat = true
        registrar("perfil privado copiado do modelo (sem assistente)")
      end
    end
  end
  if not nomePerfil or not ElvDB.profiles[nomePerfil] then
    registrar("sem perfil do ElvUI para " .. tostring(chave) .. "; fica para o proximo login")
    return
  end

  -- Primeiro personagem configurado: vira o perfil compartilhado e o modelo privado.
  if not UIForeverDB.perfil then UIForeverDB.perfil = nomePerfil end
  if not UIForeverDB.privadoModelo and ElvPrivateDB and ElvPrivateDB.profileKeys then
    local p = ElvPrivateDB.profileKeys[chave]
    local priv = p and ElvPrivateDB.profiles and ElvPrivateDB.profiles[p]
    if priv and priv.install_complete then UIForeverDB.privadoModelo = copiar(priv) end
  end

  local perfil = ElvDB.profiles[nomePerfil]

  -- Minimapa que ficou grande num logout sem volta: volta ao normal.
  if UIForeverDB.mmGrande then
    gravarNoPerfil(perfil, "general.minimap.scale", UIForeverDB.mmNormal or 1)
    UIForeverDB.mmGrande = false
  end

  UIForeverDB.aplicado = UIForeverDB.aplicado or {}
  local reg = UIForeverDB.aplicado[nomePerfil] or {}
  UIForeverDB.aplicado[nomePerfil] = reg
  local n = 0
  for _, item in ipairs(cfg.elvui) do
    local caminho, valor = item[1], item[2]
    local s = serializar(valor)
    if reg[caminho] ~= s then
      gravarNoPerfil(perfil, caminho, valor)
      reg[caminho] = s
      n = n + 1
    end
  end
  if n > 0 then
    registrar("ElvUI: " .. n .. " ajustes no perfil " .. nomePerfil)
    UIForeverCharDB.resumo = (UIForeverCharDB.resumo or 0) + n
  end
end

---------------------------------------------------------------------------
-- 1b. Fontes de numero da Blizzard (Config.lua, fonteNumeros)
---------------------------------------------------------------------------
-- O ElvUI 16.01 poe estas fontes na fonte geral em E:UpdateBlizzardFonts
-- (General\Fonts.lua, "number fonts"). Aqui so a fonte muda; tamanho e
-- contorno ficam os que o ElvUI deu. Roda depois de cada chamada dele.

local FONTES_NUMERO = {
  "Number11Font", "Number12Font", "Number12Font_o1", "Number13Font",
  "Number13FontGray", "Number13FontWhite", "Number13FontYellow",
  "Number14FontGray", "Number14FontWhite", "Number15Font", "Number18Font",
  "Number18FontWhite", "NumberFontNormal", "NumberFontNormalSmall",
  "NumberFont_OutlineThick_Mono_Small", "NumberFont_Outline_Huge",
  "NumberFont_Outline_Large", "NumberFont_Outline_Med", "NumberFont_Shadow_Med",
  "NumberFont_Shadow_Small", "NumberFont_Small", "UserScaledFontNumberNormalRight",
  "UserScaledFontNumberNormalRightGray", "UserScaledFontNumberNormalRightGreen",
  "UserScaledFontNumberNormalRightRed", "UserScaledFontNumberNormalRightYellow",
}

local fonteNumerosAvisada = false

local function aplicarFonteNumeros()
  local c = cfg.fonteNumeros
  if not (c and c.ligado and c.fonte) then return end
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  local caminho = LSM and LSM:Fetch("font", c.fonte, true)
  if not caminho then
    registrar("fonte dos numeros: " .. tostring(c.fonte) .. " nao registrada no LibSharedMedia")
    return
  end
  local n = 0
  for _, nome in ipairs(FONTES_NUMERO) do
    local obj = _G[nome]
    if obj and obj.GetFont and obj.SetFont then
      local _, tamanho, contorno = obj:GetFont()
      if tamanho and tamanho > 0 then
        obj:SetFont(caminho, tamanho, contorno or "")
        n = n + 1
      end
    end
  end
  if not fonteNumerosAvisada then
    registrar("fonte dos numeros da Blizzard: " .. c.fonte .. " em " .. n .. " fontes")
    fonteNumerosAvisada = true
  end
end

---------------------------------------------------------------------------
-- 2. Teclas
---------------------------------------------------------------------------

local teclasPendentes = false

local function aplicarTeclas()
  if emCombate() then teclasPendentes = true; return end
  teclasPendentes = false
  if not (SetBinding and GetBindingAction and SaveBindings) then
    registrar("API de teclas indisponivel")
    return
  end
  local n, falhas = 0, {}
  for _, par in ipairs(cfg.teclas) do
    local tecla, comando = par[1], par[2]
    if GetBindingAction(tecla) ~= comando then
      pcall(SetBinding, tecla, comando)
      if GetBindingAction(tecla) == comando then n = n + 1 else falhas[#falhas + 1] = tecla end
    end
  end
  if n > 0 then
    local conjunto = (GetCurrentBindingSet and GetCurrentBindingSet()) or 1
    SaveBindings(conjunto)
    registrar("teclas: " .. n .. " definidas (conjunto " .. conjunto .. ")")
    msg(n .. " teclas definidas.")
  end
  if #falhas > 0 then
    registrar("teclas que falharam: " .. table.concat(falhas, ", "))
  end
end

---------------------------------------------------------------------------
-- 3. Conteudo das barras por classe
---------------------------------------------------------------------------

local function nomeDaMagia(id)
  if not id then return nil end
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  if GetSpellInfo then return (GetSpellInfo(id)) end
end

-- nome -> id da magia (o rank mais alto conhecido), lido do livro de magias.
local function magiasConhecidas()
  local mapa = {}
  if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and Enum and Enum.SpellBookSpellBank then
    local banco = Enum.SpellBookSpellBank.Player
    local tipoMagia = Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
      local linha = C_SpellBook.GetSpellBookSkillLineInfo(i)
      if linha and linha.itemIndexOffset and linha.numSpellBookItems then
        for s = linha.itemIndexOffset + 1, linha.itemIndexOffset + linha.numSpellBookItems do
          local info = C_SpellBook.GetSpellBookItemInfo(s, banco)
          if info and info.spellID and info.name and not info.isPassive
            and (tipoMagia == nil or info.itemType == tipoMagia) then
            mapa[info.name] = info.spellID
          end
        end
      end
    end
  elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo then
    local livro = BOOKTYPE_SPELL or "spell"
    for t = 1, GetNumSpellTabs() do
      local _, _, offset, num = GetSpellTabInfo(t)
      for s = offset + 1, offset + num do
        local tipo, id = GetSpellBookItemInfo(s, livro)
        local nome = GetSpellBookItemName and GetSpellBookItemName(s, livro) or nomeDaMagia(id)
        if tipo == "SPELL" and id and nome then mapa[nome] = id end
      end
    end
  end
  return mapa
end

local function pegarMagia(id)
  if C_Spell and C_Spell.PickupSpell then C_Spell.PickupSpell(id)
  elseif PickupSpell then PickupSpell(id) end
end

-- O nome da macro no botao: o Forever documenta C_ActionBar.GetActionText; a
-- global GetActionText funciona no jogo (o diario mostra macros postas), mas nao
-- esta nas listas oficiais, entao fica de reserva (achado do checar-combate, 2026-11-06).
local function textoDaAcao(slot)
  if C_ActionBar and C_ActionBar.GetActionText then return C_ActionBar.GetActionText(slot) end
  if GetActionText then return GetActionText(slot) end
end

local function acaoNoSlot(slot)
  local tipo, id = GetActionInfo(slot)
  if tipo == "spell" then return "magia", nomeDaMagia(id), id end
  if tipo == "macro" then return "macro", textoDaAcao(slot), id end
  return tipo, nil, id
end

-- fora-de-combate (so o aplicarBarras chama, e ele sai em combate)
local function limparSlot(slot)
  ClearCursor()
  PickupAction(slot)
  ClearCursor()
end

local barrasPendentes = false
local barrasAgendadas = false

-- Ajusta a barra 5 do ElvUI ao numero de magias da lista (minimo 1) e manda o
-- ElvUI redesenhar. fora-de-combate: o ElvUI mexe em estado seguro ao redesenhar.
local function ajustarBarraRecargas(n)
  if emCombate() then barrasPendentes = true; return end
  local db = E and E.db and E.db.actionbar and E.db.actionbar.bar5
  if not db then return end
  local alvo = math.max(1, n or 0)
  if db.buttons == alvo and db.buttonsPerRow == alvo then return end
  db.buttons = alvo
  db.buttonsPerRow = alvo
  local AB = E.GetModule and E:GetModule("ActionBars", true)
  if AB and AB.PositionAndSizeBar and AB.handledBars and AB.handledBars.bar5 then
    local ok, erro = pcall(AB.PositionAndSizeBar, AB, "bar5")
    if not ok then registrar("erro ao redesenhar a barra 5: " .. tostring(erro)) end
  end
  registrar("barra 5: " .. alvo .. " botoes")
end

local function aplicarBarras()
  barrasAgendadas = false
  local _, classe = UnitClass("player")
  local plano = cfg.barras[classe]
  if not plano then return end
  if emCombate() or (GetCursorInfo and GetCursorInfo()) then barrasPendentes = true; return end
  barrasPendentes = false
  if not (GetActionInfo and PlaceAction and PickupAction and ClearCursor) then
    registrar("API de barra indisponivel")
    return
  end

  -- Dono do botao (0.2.0, pedido do dono em 2026-11-05: o que ele arrastava
  -- sumia). O UIForever so mexe num slot enquanto o conteudo dele for o que o
  -- proprio UIForever pos (UIForeverCharDB.slots[slot]). O que o dono arrastar
  -- para o slot, ou tirar dele, fica; slot vazio que o UIForever nunca preencheu
  -- recebe a acao do plano quando ela existir.
  UIForeverCharDB.slots = UIForeverCharDB.slots or {}
  local meus = UIForeverCharDB.slots
  local magias = magiasConhecidas()
  local colocados, limpos, falhas = 0, 0, {}

  -- Barra 5 compacta (0.6.0): os slots 49 a 59 nao tem plano fixo. As magias
  -- conhecidas de cfg.barraRecargas[classe], na ordem, ocupam os slots seguidos
  -- a partir do 49; os outros ficam sem plano (a regra do botao do dono vale).
  local lista = cfg.barraRecargas and cfg.barraRecargas[classe]
  local nRecargas
  if lista then
    local copia = {}
    for slot, entrada in pairs(plano) do
      if slot < 49 or slot > 59 then copia[slot] = entrada end
    end
    plano = copia
    nRecargas = 0
    for _, nome in ipairs(lista) do
      if magias[nome] and nRecargas < 11 then
        nRecargas = nRecargas + 1
        plano[48 + nRecargas] = { magia = nome }
      end
    end
  end

  -- fora-de-combate (o aplicarBarras sai no comeco quando ha combate)
  local function colocar(slot, querTipo, querNome, querId)
    ClearCursor()
    if querTipo == "macro" then PickupMacro(querId) else pegarMagia(querId) end
    if GetCursorInfo and GetCursorInfo() then
      PlaceAction(slot)
      ClearCursor()
      colocados = colocados + 1
      return true
    end
    falhas[#falhas + 1] = querNome
    return false
  end

  for _, faixa in ipairs(cfg.gerenciados) do
    for slot = faixa[1], faixa[2] do
      local entrada = plano[slot]
      local querTipo, querNome, querId
      if entrada then
        local idx = entrada.macro and GetMacroIndexByName and GetMacroIndexByName(entrada.macro) or 0
        if idx and idx > 0 then
          querTipo, querNome, querId = "macro", entrada.macro, idx
        elseif entrada.magia and magias[entrada.magia] then
          querTipo, querNome, querId = "magia", entrada.magia, magias[entrada.magia]
        end
      end
      local quer = querTipo and (querTipo .. ":" .. querNome)
      local tipo, nome, id = acaoNoSlot(slot)
      local atual = tipo and (tostring(tipo) .. ":" .. tostring(nome))
      local meu = meus[slot]

      if atual and atual == quer then
        -- ja e a acao do plano; troca so o rank, e so se o slot ja era do UIForever
        if querTipo == "magia" and id ~= querId and meu == quer then
          colocar(slot, querTipo, querNome, querId)
        end
        meus[slot] = quer
      elseif atual and atual ~= meu then
        -- o dono pos outra coisa aqui: nao mexe
      elseif atual then
        -- conteudo do UIForever, e o plano mudou
        if quer then
          if colocar(slot, querTipo, querNome, querId) then meus[slot] = quer end
        else
          limparSlot(slot); limpos = limpos + 1
          meus[slot] = nil
        end
      elseif meu then
        -- vazio, mas o UIForever ja preencheu antes: o dono tirou, fica vazio
      elseif quer then
        if colocar(slot, querTipo, querNome, querId) then meus[slot] = quer end
      end
    end
  end
  if colocados + limpos > 0 then
    registrar("barras (" .. classe .. "): " .. colocados .. " colocados, " .. limpos .. " limpos")
  end
  if #falhas > 0 then
    registrar("barras: nao consegui pegar " .. table.concat(falhas, ", "))
  end
  -- livro de magias ainda vazio: nao encolhe a barra por engano
  if nRecargas and next(magias) ~= nil then ajustarBarraRecargas(nRecargas) end
end

local function agendarBarras()
  if barrasAgendadas then return end
  barrasAgendadas = true
  depois(1, aplicarBarras)
end

---------------------------------------------------------------------------
-- 4. Minimapa grande (Shift+M, pelo Bindings.xml)
---------------------------------------------------------------------------

function UIForever_AlternarMinimapa()
  local M = E and E.GetModule and E:GetModule("Minimap", true)
  if not (M and M.db and M.UpdateSettings) then return end
  if UIForeverDB.mmGrande then
    M.db.scale = UIForeverDB.mmNormal or 1
    UIForeverDB.mmGrande = false
  else
    UIForeverDB.mmNormal = M.db.scale or 1
    M.db.scale = (UIForeverDB.mmNormal or 1) * (cfg.minimapaEscala or 2)
    UIForeverDB.mmGrande = true
  end
  M:UpdateSettings()
end

---------------------------------------------------------------------------
-- 5. Alca para arrastar a altura dos chats
---------------------------------------------------------------------------

local function criarAlca(painel, chaveAltura)
  if not painel or painel.UIForeverAlca then return end
  local CH = E:GetModule("Chat", true)
  if not CH then return end
  local alca = CreateFrame("Frame", nil, painel)
  alca:SetPoint("BOTTOMLEFT", painel, "TOPLEFT", 0, -3)
  alca:SetPoint("BOTTOMRIGHT", painel, "TOPRIGHT", 0, -3)
  alca:SetHeight(7)
  alca:SetFrameLevel(painel:GetFrameLevel() + 20)
  alca:EnableMouse(true)
  local linha = alca:CreateTexture(nil, "OVERLAY")
  linha:SetPoint("LEFT")
  linha:SetPoint("RIGHT")
  linha:SetHeight(2)
  linha:SetColorTexture(1, 1, 1, 0.5)
  linha:Hide()
  alca:SetScript("OnEnter", function(self)
    linha:Show()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Arraste para mudar a altura do chat")
    GameTooltip:Show()
  end)
  alca:SetScript("OnLeave", function()
    if not alca.arrastando then linha:Hide() end
    GameTooltip:Hide()
  end)
  alca:SetScript("OnMouseDown", function(self, botao)
    if botao ~= "LeftButton" then return end
    local _, y = GetCursorPosition()
    self.y0 = y
    self.h0 = E.db.chat[chaveAltura]
    self.arrastando = true
  end)
  alca:SetScript("OnMouseUp", function(self)
    self.arrastando = false
    if not self:IsMouseOver() then linha:Hide() end
  end)
  alca:SetScript("OnUpdate", function(self)
    if not self.arrastando then return end
    local _, y = GetCursorPosition()
    local escala = painel:GetEffectiveScale()
    local h = math.floor(self.h0 + (y - self.y0) / escala + 0.5)
    if h < cfg.chatAlturaMin then h = cfg.chatAlturaMin end
    if h > cfg.chatAlturaMax then h = cfg.chatAlturaMax end
    if h ~= E.db.chat[chaveAltura] then
      E.db.chat[chaveAltura] = h
      CH:PositionChats()
    end
  end)
  painel.UIForeverAlca = alca
end

---------------------------------------------------------------------------
-- 6. Opcoes do menu do jogo (CVars), uma vez por personagem
---------------------------------------------------------------------------

local cvarsPendentes = false

local function lerCVar(nome)
  local ok, v
  if C_CVar and C_CVar.GetCVar then ok, v = pcall(C_CVar.GetCVar, nome)
  elseif GetCVar then ok, v = pcall(GetCVar, nome) end
  if ok then return v end
end

local function aplicarCVars()
  if not cfg.cvars then return end
  if emCombate() then cvarsPendentes = true; return end
  cvarsPendentes = false
  local gravar = (C_CVar and C_CVar.SetCVar) or SetCVar
  if not gravar then
    registrar("API de CVar indisponivel")
    return
  end
  UIForeverCharDB.cvars = UIForeverCharDB.cvars or {}
  local reg = UIForeverCharDB.cvars
  local feitas, falhas = {}, {}
  for _, par in ipairs(cfg.cvars) do
    local nome, valor = par[1], tostring(par[2])
    if reg[nome] ~= valor then
      local antes = lerCVar(nome)
      pcall(gravar, nome, valor)
      if lerCVar(nome) == valor then
        reg[nome] = valor
        feitas[#feitas + 1] = nome .. " " .. tostring(antes) .. "->" .. valor
      else
        falhas[#falhas + 1] = nome
      end
    end
  end
  if #feitas > 0 then
    registrar("cvars: " .. table.concat(feitas, ", "))
    msg("opcoes do jogo ajustadas: " .. table.concat(feitas, ", "))
  end
  if #falhas > 0 then
    registrar("cvars que falharam: " .. table.concat(falhas, ", "))
  end
end

---------------------------------------------------------------------------
-- 7. Barra de experiencia da Blizzard, com a XP das quests do log
---------------------------------------------------------------------------
-- Pedido do dono em 2026-11-05: a barra com a cara original do jogo, mais a
-- XP das quests do log e o que falta para o proximo nivel.
-- O ElvUI 16.01 apaga o StatusTrackingBarManager da Blizzard quando as barras
-- de acao dele estao ligadas (AB:DisableBlizzard). Em vez de ressuscitar
-- aquele quadro (que e do Edit Mode), o UIForever cria uma barra nova com o
-- proprio modelo da Blizzard (ExpStatusBarTemplate, o mesmo que a barra
-- original usa no Forever) dentro de uma moldura igual a do container
-- original (atlas UI-HUD-ExperienceBar-Frame e 20 segmentos). O trecho das
-- quests usa o desenho da previsao do descanso, em outra cor. A barra de XP
-- do ElvUI fica desligada pelo Config.lua.

local barraXP -- a barra (ExpStatusBarTemplate)
local trechoQuests
local questsXP = { total = 0, prontas = 0, n = 0 }
local fXP = CreateFrame("Frame")
local xpAgendado = false

local function numero(v)
  if BreakUpLargeNumbers then return BreakUpLargeNumbers(v) end
  return tostring(v)
end

local function podeMostrarXP()
  if GameRulesUtil and GameRulesUtil.CanShowExperienceBar then
    return GameRulesUtil.CanShowExperienceBar()
  end
  local maximo = GetMaxPlayerLevel and GetMaxPlayerLevel() or 60
  return UnitLevel("player") < maximo and not (IsXPUserDisabled and IsXPUserDisabled())
end

local function somarQuests()
  local total, prontas, n = 0, 0, 0
  local Q = C_QuestLog
  if Q and Q.GetNumQuestLogEntries and Q.GetInfo and GetQuestLogRewardXP then
    for i = 1, Q.GetNumQuestLogEntries() do
      local info = Q.GetInfo(i)
      if info and not info.isHeader and not info.isHidden and info.questID then
        local xp = GetQuestLogRewardXP(info.questID) or 0
        if xp > 0 then
          total = total + xp
          n = n + 1
          if Q.ReadyForTurnIn and Q.ReadyForTurnIn(info.questID) then prontas = prontas + xp end
        end
      end
    end
  end
  questsXP.total, questsXP.prontas, questsXP.n = total, prontas, n
end

local function atualizarTrecho()
  if not (barraXP and trechoQuests) then return end
  local atual, maximo = UnitXP("player"), UnitXPMax("player")
  if not maximo or maximo <= 0 or questsXP.total <= 0 or not podeMostrarXP() then
    trechoQuests:Hide()
    return
  end
  local razao = math.min((atual + questsXP.total) / maximo, 1)
  trechoQuests:SetWidth(razao * barraXP:GetWidth())
  trechoQuests:SetTexCoord(0, razao, 0, 1) -- como a Blizzard faz na previsao do descanso
  trechoQuests:Show()
  -- o trecho mais curto (quests ou descanso) fica por cima, para os dois aparecerem
  local descanso = GetXPExhaustion and GetXPExhaustion() or 0
  local questsPorCima = questsXP.total <= descanso
  trechoQuests:SetDrawLayer("ARTWORK", questsPorCima and -1 or -2)
  if barraXP.ExhaustionLevelFillBar then
    barraXP.ExhaustionLevelFillBar:SetDrawLayer("ARTWORK", questsPorCima and -2 or -1)
  end
end

-- Linhas a mais no tooltip que a propria barra da Blizzard abre (XP e descanso).
local function linhasDoTooltip()
  if not (barraXP and podeMostrarXP()) then return end
  local tt = (GetAppropriateTooltip and GetAppropriateTooltip()) or GameTooltip
  if not tt then return end
  local atual, maximo = UnitXP("player"), UnitXPMax("player")
  if not maximo or maximo <= 0 then return end
  if not tt:IsShown() then
    if GameTooltip_SetDefaultAnchor then GameTooltip_SetDefaultAnchor(tt, UIParent)
    else tt:SetOwner(barraXP, "ANCHOR_TOP") end
    tt:AddLine("XP: " .. numero(atual) .. " / " .. numero(maximo), 1, 1, 1)
  end
  local falta = maximo - atual
  tt:AddLine(" ")
  tt:AddDoubleLine("Falta para o nivel " .. (UnitLevel("player") + 1) .. ":",
    numero(falta) .. string.format(" (%.1f%%)", falta / maximo * 100), 1, 0.82, 0, 1, 1, 1)
  if questsXP.total > 0 then
    tt:AddDoubleLine("XP das quests do log (" .. questsXP.n .. "):", numero(questsXP.total), 1, 0.82, 0, 1, 1, 1)
    if questsXP.prontas > 0 then
      tt:AddDoubleLine("   prontas para entregar:", numero(questsXP.prontas), 0.8, 0.8, 0.8, 1, 1, 1)
    end
    local resto = falta - questsXP.total
    if resto > 0 then
      tt:AddDoubleLine("Falta depois de entregar todas:", numero(resto), 1, 0.82, 0, 1, 1, 1)
    else
      tt:AddLine("As quests do log ja fecham o nivel (sobram " .. numero(-resto) .. ").", 0.25, 1, 0.25)
    end
  else
    tt:AddLine("Nenhuma quest do log da XP (ou os dados ainda nao chegaram).", 0.6, 0.6, 0.6)
  end
  tt:Show()
end

local function agendarXP()
  if xpAgendado then return end
  xpAgendado = true
  depois(0.3, function()
    xpAgendado = false
    if not barraXP then return end
    barraXP:GetParent():SetShown(podeMostrarXP())
    somarQuests()
    atualizarTrecho()
  end)
end

local function criarBarraXP()
  local c = cfg.barraXP
  if barraXP or not (c and c.ligada) then return end
  local largura, altura = c.largura or 1192, c.altura or 17

  local cont = CreateFrame("Frame", "UIForeverBarraXP", UIParent)
  cont:SetFrameStrata("MEDIUM") -- como o container da Blizzard: moldura por cima da barra (LOW)
  cont:SetSize(largura, altura)
  local ancora = _G.ElvUI_ExperienceBarHolder
  if c.ponto then
    cont:SetPoint(c.ponto[1], c.ponto[2], c.ponto[3], c.ponto[4], c.ponto[5])
  elseif ancora then
    cont:SetPoint("BOTTOM", ancora, "BOTTOM", 0, 0) -- onde estava a barra do ElvUI
  else
    cont:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 44)
  end

  local ok, barra = pcall(CreateFrame, "Frame", "UIForeverBarraXPBarra", cont, "ExpStatusBarTemplate")
  if not ok or not barra or not barra.StatusBar then
    cont:Hide()
    registrar("barra de XP: modelo ExpStatusBarTemplate indisponivel (" .. tostring(barra) .. ")")
    msg("nao consegui criar a barra de experiencia da Blizzard; avise o modder.")
    return
  end

  local moldura = cont:CreateTexture(nil, "OVERLAY")
  moldura:SetAtlas("UI-HUD-ExperienceBar-Frame")
  moldura:SetAllPoints(cont)
  local segmentos = c.segmentos or 20
  for i = 1, segmentos - 1 do
    local okD, d = pcall(CreateFrame, "Frame", nil, cont, "StatusBarDividerTemplate")
    if okD and d then d:SetPoint("LEFT", cont, "LEFT", largura / segmentos * i, 0) end
  end

  local ajuste = STATUS_BAR_SIZE_ADJUSTMENT or 3
  local w, h = largura - ajuste, altura - ajuste
  barra:ClearAllPoints()
  barra:SetPoint("BOTTOMLEFT", cont, "BOTTOMLEFT", 1, ajuste - 1)
  barra:SetSize(w, h)
  barra.StatusBar:SetSize(w, h)

  local cor = c.corQuests or { r = 1, g = 0.82, b = 0, a = 0.7 }
  trechoQuests = barra:CreateTexture(nil, "ARTWORK", nil, -2)
  trechoQuests:SetAtlas("UI-HUD-ExperienceBar-Fill-Prediction")
  trechoQuests:SetDesaturated(true)
  trechoQuests:SetVertexColor(cor.r, cor.g, cor.b)
  trechoQuests:SetAlpha(cor.a or 1)
  trechoQuests:SetPoint("BOTTOMLEFT", barra, "BOTTOMLEFT", 0, 0)
  local hPrev = barra.ExhaustionLevelFillBar and barra.ExhaustionLevelFillBar:GetHeight()
  trechoQuests:SetHeight((hPrev and hPrev > 0) and hPrev or h)
  trechoQuests:Hide()

  barra:HookScript("OnEnter", linhasDoTooltip)
  if barra.ExhaustionTick then barra.ExhaustionTick:HookScript("OnEnter", linhasDoTooltip) end

  barraXP = barra
  barra:Show()
  if barra.UpdateStatusBarTextures then
    pcall(barra.UpdateStatusBarTextures, barra, (GetRestState and GetRestState()) == 1)
  end
  if barra.UpdateAll then pcall(barra.UpdateAll, barra) end
  cont:SetShown(podeMostrarXP())
  somarQuests()
  atualizarTrecho()

  fXP:SetScript("OnEvent", agendarXP)
  for _, evento in ipairs({ "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP",
      "UPDATE_EXHAUSTION", "ENABLE_XP_GAIN", "DISABLE_XP_GAIN", "PLAYER_MAX_LEVEL_UPDATE" }) do
    pcall(fXP.RegisterEvent, fXP, evento)
  end
  registrar("barra de XP da Blizzard criada (" .. largura .. "x" .. altura .. ", "
    .. (c.ponto and "ponto do Config" or (ancora and "lugar da barra do ElvUI" or "ponto padrao")) .. ")")
end

---------------------------------------------------------------------------
-- 8. Margem das janelas do jogo (0.6.0, pedido do dono em 2026-11-06)
---------------------------------------------------------------------------
-- O Forever posiciona vendedor, missao, treinador, talentos e livro a partir
-- de uma margem publica, SetUIPanelLayoutAttribute("LEFT_OFFSET", x), padrao
-- 16 (Blizzard_UIParentPanelManager, Shared\UIPanelLayoutFrame.lua e
-- UIParentPanelManager.lua, linhas 616-725). O UIForever poe essa margem na
-- borda direita da coluna do RestedXP (RXPFrame) com o painel Agora do
-- GuiaForever embaixo, em unidades do UIParent. Contrato: GuiaForever,
-- ARQUITETURA.md, secao 9.

local MARGEM_PADRAO = 16
local margemPendente = false
local margemAgendada = false
local ganchosMargem = false

local function seguro(fn)
  return function(...) return xpcall(fn, geterrorhandler(), ...) end
end

local function calcularMargem()
  local c = cfg.margemJanelas
  if not (c and c.ligado) then return MARGEM_PADRAO end
  local rxp = _G.RXPFrame
  if not (rxp and rxp.GetLeft and rxp.GetWidth and rxp.GetEffectiveScale) then return MARGEM_PADRAO end
  local esquerda = rxp:GetLeft()
  local escalaUI = UIParent:GetEffectiveScale()
  local escalaRxp = rxp:GetEffectiveScale()
  if not (esquerda and escalaUI and escalaUI > 0 and escalaRxp and escalaRxp > 0) then return MARGEM_PADRAO end
  local larguraRxp = (rxp:GetWidth() or 0) * escalaRxp / escalaUI
  local larguraAgora = c.larguraMinima or 360
  local agora = _G.GuiaForeverAgora
  if agora and agora.GetWidth and agora.GetEffectiveScale then
    local escalaAgora = agora:GetEffectiveScale() or escalaUI
    larguraAgora = (agora:GetWidth() or 0) * escalaAgora / escalaUI
  end
  local v = esquerda * escalaRxp / escalaUI + math.max(larguraRxp, larguraAgora)
  if v ~= v or v < 0 then return MARGEM_PADRAO end
  return math.floor(v + (c.folga or 8))
end

-- fora-de-combate
local function aplicarMargem()
  if emCombate() then margemPendente = true; return end
  margemPendente = false
  if not (SetUIPanelLayoutAttribute and GetUIPanelLayoutAttribute) then return end
  local novo = calcularMargem()
  local antes = GetUIPanelLayoutAttribute("LEFT_OFFSET")
  if antes == novo then return end
  SetUIPanelLayoutAttribute("LEFT_OFFSET", novo)
  registrar("margem das janelas: " .. tostring(antes) .. " -> " .. novo)
end

local function agendarMargem()
  if margemAgendada then return end
  margemAgendada = true
  depois(0.2, seguro(function()
    margemAgendada = false
    aplicarMargem()
  end))
end

function UIForever_AtualizarMargem()
  agendarMargem()
end

local function instalarGanchosMargem()
  if ganchosMargem then return end
  local rxp = _G.RXPFrame
  if not (rxp and rxp.HookScript) then return end
  ganchosMargem = true
  pcall(rxp.HookScript, rxp, "OnMouseUp", agendarMargem)
  pcall(rxp.HookScript, rxp, "OnSizeChanged", agendarMargem)
end

---------------------------------------------------------------------------
-- 9. Chat da esquerda no painel de baixo (0.6.0)
---------------------------------------------------------------------------
-- Por que o ChatFrame1 aparece solto no meio da tela. No Forever o chat padrao
-- e do Edit Mode: EditModeSystemMixin:ApplySystemAnchor (Blizzard_EditMode,
-- Shared\EditModeSystemTemplates.lua, 350-383) faz ClearAllPoints e SetPoint na
-- ancora do layout salvo, e FCF_RestorePositionAndDimensions deixa o chat padrao
-- para o Edit Mode (Blizzard_ChatFrameBase, Mainline\FloatingChatFrame.lua,
-- 1475-1478). O ElvUI so devolve o chat ao LeftChatPanel pelo CH:PositionChat
-- (Chat.lua, 1603-1607), e so se o CH:FindChatWindows (1389-1434) o escolher
-- como janela da esquerda. Em E.Modern o ElvUI nao escuta o PLAYER_ENTERING_WORLD
-- (4149-4150); so religa depois do EditModeManagerFrame:UpdateLayoutInfo (4110),
-- por ResnapDock, que chama CH:Unsnapped (1528-1534) e zera o panelSnapLeftID.
-- Sem o id, o FindChatWindows so escolhe o chat se ele SOBREPOR o painel
-- (1408, E:FramesOverlap); se o Edit Mode o deixou em outro lugar, a janela da
-- esquerda fica nula, o PositionChat nao ancora nada e o chat fica onde o Edit
-- Mode o pos. E nada religa se o Edit Mode reancorar o chat sem passar pelo
-- UpdateLayoutInfo.
-- Correcao: depois de cada ApplySystemAnchor do ChatFrame1 e de cada
-- UpdateLayoutInfo (e uma vez no login), se o ChatFrame1 e o chat principal do
-- dock e nao esta no LeftChatPanel, o UIForever grava o id dele como janela da
-- esquerda e chama o CH:PositionChat do proprio ElvUI. Nao mexe em aba, canal
-- nem no layout do Edit Mode, e nao refaz as janelas (nada de E:SetupChat).

local chatPendente = false
local chatAgendado = false
local ganchoChatApply = false
local ganchoChatLayout = false

-- fora-de-combate
local function corrigirChat()
  if emCombate() then chatPendente = true; return end
  chatPendente = false
  if not cfg.chatNoPainel then return end
  local CH = E and E.GetModule and E:GetModule("Chat", true)
  local chat, painel = _G.ChatFrame1, _G.LeftChatPanel
  if not (CH and CH.PositionChat and CH.db and CH.Initialized and chat and painel) then return end
  if not (E.private and E.private.chat and E.private.chat.enable and CH.db.panelSnapping) then return end
  local dock = _G.GeneralDockManager
  if not (dock and dock.primary == chat and chat.isDocked) then return end
  local _, relativo = chat:GetPoint(1)
  if chat:GetParent() == painel and relativo == painel then return end
  if CH.RightChatWindow == chat or CH.db.panelSnapRightID == chat:GetID() then return end
  if CH.LeftChatWindow and CH.LeftChatWindow ~= chat then return end
  if CH.LeftChatWindow ~= chat then
    CH.LeftChatWindow = nil
    CH.db.panelSnapLeftID = chat:GetID()
  end
  local ok, erro = pcall(CH.PositionChat, CH, chat)
  if not ok then
    registrar("erro ao devolver o chat ao painel: " .. tostring(erro))
    return
  end
  local _, depoisRel = chat:GetPoint(1)
  registrar("chat da esquerda devolvido ao LeftChatPanel (ancora: " .. tostring(depoisRel == painel) .. ")")
end

local function agendarChat()
  if chatAgendado then return end
  chatAgendado = true
  depois(0.5, seguro(function()
    chatAgendado = false
    corrigirChat()
  end))
end

local function instalarGanchosChat()
  if not cfg.chatNoPainel then return end
  local chat = _G.ChatFrame1
  if not ganchoChatApply and chat and type(chat.ApplySystemAnchor) == "function" then
    ganchoChatApply = pcall(hooksecurefunc, chat, "ApplySystemAnchor", agendarChat)
  end
  local em = _G.EditModeManagerFrame
  if not ganchoChatLayout and em and type(em.UpdateLayoutInfo) == "function" then
    ganchoChatLayout = pcall(hooksecurefunc, em, "UpdateLayoutInfo", agendarChat)
  end
end

---------------------------------------------------------------------------
-- 10. Icones de cidade do Questie no minimapa (pedido do dono em 2026-11-08)
---------------------------------------------------------------------------
-- O Questie desenha vendedores, reparo, estalagem, voo e afins no mapa e no
-- minimapa (QuestieMenu, "Townsfolk"), lendo Questie.db.profile.townsfolkConfig
-- no QuestieMenu:OnLogin, no fim da inicializacao dele (QuestieInit, Stage3,
-- numa thread que comeca no PLAYER_LOGIN). O UIForever liga as categorias de
-- UIForeverConfig.questie antes disso, no proprio ADDON_LOADED: o Questie
-- carrega antes (ordem alfabetica) e o Questie.db nasce no OnInitialize dele.
-- Se o Questie.db ainda nao existir, tenta de novo 2 s depois de entrar no
-- mundo e, se o Questie ja tiver terminado de iniciar, pede o redesenho pelo
-- proprio QuestieMenu:OnLogin(true), como o Questie faz. Cada item so e gravado
-- quando entra no Config.lua (controle em UIForeverDB.questie).

local function aplicarQuestie(tarde)
  local c = cfg.questie
  if not (c and c.ligado) then return end
  local Q = _G.Questie
  local perfil = Q and Q.db and Q.db.profile
  if not perfil then return end
  UIForeverDB.questie = UIForeverDB.questie or {}
  local feito = UIForeverDB.questie
  local mudou = {}
  if type(perfil.townsfolkConfig) ~= "table" then perfil.townsfolkConfig = {} end
  for _, chave in ipairs(c.cidade or {}) do
    if feito["cidade:" .. chave] ~= true then
      perfil.townsfolkConfig[chave] = true
      feito["cidade:" .. chave] = true
      mudou[#mudou + 1] = chave
    end
  end
  if c.escalaMinimapa and feito.escalaMinimapa ~= c.escalaMinimapa then
    perfil.globalMiniMapTownsfolkScale = c.escalaMinimapa
    feito.escalaMinimapa = c.escalaMinimapa
    mudou[#mudou + 1] = "escala no minimapa " .. tostring(c.escalaMinimapa)
  end
  if #mudou == 0 then return end
  registrar("questie: " .. table.concat(mudou, ", "))
  if tarde and Q.started and _G.QuestieLoader and QuestieLoader.ImportModule then
    local ok, menu = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieMenu")
    if ok and menu and menu.OnLogin then
      local okL, erroL = pcall(menu.OnLogin, menu, true)
      if not okL then registrar("questie: erro ao redesenhar: " .. tostring(erroL)) end
    end
  end
end

---------------------------------------------------------------------------
-- 11. Dragao do elite no retrato do alvo (pedido do dono em 2026-11-08)
---------------------------------------------------------------------------
-- A arte e a regra do quadro de alvo da propria Blizzard no Forever
-- (Blizzard_UnitFrame, Camelot\TargetFrameUtils.lua, GetBossPortraitFrameData,
-- usada em Mainline\TargetFrame.lua): chefe = dourado com asas, raro e raro
-- elite = prateado com asas, elite = dragao dourado. No quadro da Blizzard o
-- retrato e um circulo de 58 a (-26, -19) do canto de cima a direita do
-- container, e o dragao prende o canto de cima a direita dele no do container,
-- com o deslocamento de cada arte; logo, em relacao ao centro do circulo, o
-- canto do dragao fica em (29 + 26 + dx, 29 + 19 + dy). Aqui o circulo e
-- imaginario, de 58 x escala, centrado no retrato do ElvUI, e a arte vira de
-- lado quando o retrato fica a esquerda do quadro, para as asas abrirem para
-- fora. UnitClassification e UnitIsBossMob nao devolvem valor secreto
-- (UnitDocumentation.lua do Forever, sem SecretWhen).
-- O quadro do alvo do ElvUI e seguro; o dragao nao se prende a ele: fica no
-- UIParent, num ponto calculado fora de combate (o quadro nao anda em combate),
-- e em combate so troca a arte e aparece ou some.

local ARTES_ELITE = {
  chefe = { "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged", 11, -4 },
  raro = { "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged", 8, -7 },
  elite = { "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold", 0, 1 },
}

local dragao
local geometriaAlvo -- centro do retrato em unidades do UIParent e o lado dele
local avisouAtlas = {}
local fElite = CreateFrame("Frame")
local dragaoInstalado = false

local function segredo(v)
  return issecretvalue and issecretvalue(v)
end

local function arteDoAlvo()
  if not UnitExists("target") then return nil end
  local chefe = UnitIsBossMob and UnitIsBossMob("target")
  if segredo(chefe) then return nil end
  if chefe then return ARTES_ELITE.chefe end
  local c = UnitClassification and UnitClassification("target")
  if c == nil or segredo(c) then return nil end
  if c == "worldboss" then return ARTES_ELITE.chefe end
  if c == "rare" or c == "rareelite" then return ARTES_ELITE.raro end
  if c == "elite" then return ARTES_ELITE.elite end
  return nil
end

-- fora-de-combate
local function lerGeometriaAlvo()
  if emCombate() then return end
  local quadro = _G.ElvUF_Target
  local retrato = quadro and quadro.Portrait
  local base = retrato and (retrato.backdrop or retrato)
  if not (base and base.GetCenter and quadro.GetCenter) then return end
  local bx, by = base:GetCenter()
  local qx = quadro:GetCenter()
  if not (bx and by and qx) or segredo(bx) or segredo(by) or segredo(qx) then return end
  local r = base:GetEffectiveScale() / UIParent:GetEffectiveScale()
  geometriaAlvo = { x = bx * r, y = by * r, esquerda = bx < qx }
end

local function atualizarDragao()
  local c = cfg.elite
  local arte = c and c.ligado and arteDoAlvo()
  if not arte then
    if dragao then dragao:Hide() end
    return
  end
  lerGeometriaAlvo()
  local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(arte[1])
  if not (geometriaAlvo and info and info.width and info.width > 0) then
    if not info and not avisouAtlas[arte[1]] then
      avisouAtlas[arte[1]] = true
      registrar("dragao do elite: atlas " .. arte[1] .. " nao existe neste cliente")
    end
    if dragao then dragao:Hide() end
    return
  end
  if not dragao then
    dragao = CreateFrame("Frame", "UIForeverDragaoElite", UIParent)
    dragao:SetFrameStrata("MEDIUM")
    dragao:SetFrameLevel(40)
    dragao.tex = dragao:CreateTexture(nil, "OVERLAY")
    dragao.tex:SetAllPoints(dragao)
  end
  local k = c.escala or 1
  local dx = (55 + arte[2]) * k + (c.x or 0)
  local dy = (48 + arte[3]) * k + (c.y or 0)
  dragao:SetSize(info.width * k, info.height * k)
  dragao:ClearAllPoints()
  local tex = dragao.tex
  tex:SetAtlas(arte[1])
  if geometriaAlvo.esquerda then
    dragao:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", geometriaAlvo.x - dx, geometriaAlvo.y + dy)
    local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = tex:GetTexCoord()
    tex:SetTexCoord(URx, URy, LRx, LRy, ULx, ULy, LLx, LLy)
  else
    dragao:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", geometriaAlvo.x + dx, geometriaAlvo.y + dy)
  end
  dragao:Show()
end

local function agendarDragao()
  -- um instante depois, para o quadro do alvo do ElvUI ja estar de pe
  depois(0.05, function()
    local ok, erro = pcall(atualizarDragao)
    if not ok then registrar("erro no dragao do elite: " .. tostring(erro)) end
  end)
end

local function instalarDragao()
  if dragaoInstalado or not (cfg.elite and cfg.elite.ligado) then return end
  dragaoInstalado = true
  fElite:SetScript("OnEvent", function(_, evento, unidade)
    if evento == "UNIT_CLASSIFICATION_CHANGED" and unidade ~= "target" then return end
    agendarDragao()
  end)
  for _, ev in ipairs({ "PLAYER_TARGET_CHANGED", "UNIT_CLASSIFICATION_CHANGED", "PLAYER_REGEN_ENABLED" }) do
    pcall(fElite.RegisterEvent, fElite, ev)
  end
  agendarDragao()
end

---------------------------------------------------------------------------
-- Eventos
---------------------------------------------------------------------------

local function registrarEvento(evento)
  pcall(f.RegisterEvent, f, evento)
end

registrarEvento("ADDON_LOADED")
registrarEvento("PLAYER_ENTERING_WORLD")
registrarEvento("PLAYER_REGEN_ENABLED")
registrarEvento("UPDATE_MACROS")
registrarEvento("SPELLS_CHANGED")
-- LEARNED_SPELL_IN_TAB nao existe no Forever (Events.lua); o LEARNED_SPELL_IN_SKILL_LINE abaixo cobre
registrarEvento("LEARNED_SPELL_IN_SKILL_LINE")
registrarEvento("PLAYER_LOGOUT")

local entrou = false

f:SetScript("OnEvent", function(_, evento, arg1)
  if evento == "ADDON_LOADED" then
    if arg1 ~= NOME then return end
    UIForeverDB = UIForeverDB or {}
    UIForeverCharDB = UIForeverCharDB or {}
    E = ElvUI and ElvUI[1]
    if E then
      local ok, erro = pcall(prepararPerfilElvUI)
      if not ok then registrar("erro no perfil do ElvUI: " .. tostring(erro)) end
      pcall(instalarGanchosChat)
      if cfg.fonteNumeros and cfg.fonteNumeros.ligado and type(E.UpdateBlizzardFonts) == "function" then
        hooksecurefunc(E, "UpdateBlizzardFonts", function()
          local okF, erroF = pcall(aplicarFonteNumeros)
          if not okF then registrar("erro na fonte dos numeros: " .. tostring(erroF)) end
        end)
      end
    else
      registrar("ElvUI ausente")
    end
    local okQ, erroQ = pcall(aplicarQuestie, false)
    if not okQ then registrar("erro no questie: " .. tostring(erroQ)) end

  elseif evento == "PLAYER_ENTERING_WORLD" then
    if entrou then return end
    entrou = true
    depois(2, function()
      if E then
        criarAlca(_G.LeftChatPanel, "panelHeight")
        criarAlca(_G.RightChatPanel, "panelHeightRight")
        if UIForeverCharDB.configurarChat and E.SetupChat and not emCombate() then
          local ok, erro = pcall(E.SetupChat, E, true)
          registrar(ok and "chat do personagem novo montado" or ("erro ao montar o chat: " .. tostring(erro)))
          UIForeverCharDB.configurarChat = false
        end
      end
      aplicarTeclas()
      aplicarCVars()
      aplicarBarras()
      local okXP, erroXP = pcall(criarBarraXP)
      if not okXP then registrar("erro na barra de XP: " .. tostring(erroXP)) end
      local okQ, erroQ = pcall(aplicarQuestie, true)
      if not okQ then registrar("erro no questie: " .. tostring(erroQ)) end
      local okD, erroD = pcall(instalarDragao)
      if not okD then registrar("erro no dragao do elite: " .. tostring(erroD)) end
      if (UIForeverCharDB.resumo or 0) > 0 then
        msg("layout do ElvUI aplicado (" .. UIForeverCharDB.resumo .. " ajustes).")
        UIForeverCharDB.resumo = 0
      end
      if E then
        pcall(instalarGanchosChat)
        agendarChat()
      end
    end)
    -- margem das janelas: 3 s depois de entrar no mundo
    depois(3, seguro(function()
      instalarGanchosMargem()
      aplicarMargem()
    end))

  elseif evento == "PLAYER_REGEN_ENABLED" then
    if teclasPendentes then aplicarTeclas() end
    if cvarsPendentes then aplicarCVars() end
    if barrasPendentes then agendarBarras() end
    if margemPendente then agendarMargem() end
    if chatPendente then agendarChat() end

  elseif evento == "PLAYER_LOGOUT" then
    if UIForeverDB.mmGrande and E and E.db and E.db.general and E.db.general.minimap then
      E.db.general.minimap.scale = UIForeverDB.mmNormal or 1
      UIForeverDB.mmGrande = false
    end

  else -- macros ou magias mudaram
    if entrou then agendarBarras() end
  end
end)
