-- UIForever: aplica no login o layout do ElvUI, as teclas, o conteudo das
-- barras por classe e o minimapa grande, tudo vindo de Config.lua.
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

local function acaoNoSlot(slot)
  local tipo, id = GetActionInfo(slot)
  if tipo == "spell" then return "magia", nomeDaMagia(id), id end
  if tipo == "macro" then return "macro", GetActionText(slot), id end
  return tipo, nil, id
end

local function limparSlot(slot)
  ClearCursor()
  PickupAction(slot)
  ClearCursor()
end

local barrasPendentes = false
local barrasAgendadas = false

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

  local magias = magiasConhecidas()
  local colocados, limpos, falhas = 0, 0, {}
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
      local tipo, nome, id = acaoNoSlot(slot)
      if not querTipo then
        if tipo then limparSlot(slot); limpos = limpos + 1 end
      elseif not (tipo == querTipo and nome == querNome and (querTipo == "macro" or id == querId)) then
        ClearCursor()
        if querTipo == "macro" then PickupMacro(querId) else pegarMagia(querId) end
        if GetCursorInfo and GetCursorInfo() then
          PlaceAction(slot)
          ClearCursor()
          colocados = colocados + 1
        else
          falhas[#falhas + 1] = querNome
        end
      end
    end
  end
  if colocados + limpos > 0 then
    registrar("barras (" .. classe .. "): " .. colocados .. " colocados, " .. limpos .. " limpos")
  end
  if #falhas > 0 then
    registrar("barras: nao consegui pegar " .. table.concat(falhas, ", "))
  end
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
registrarEvento("LEARNED_SPELL_IN_TAB")
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
    else
      registrar("ElvUI ausente")
    end

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
      aplicarBarras()
      if (UIForeverCharDB.resumo or 0) > 0 then
        msg("layout do ElvUI aplicado (" .. UIForeverCharDB.resumo .. " ajustes).")
        UIForeverCharDB.resumo = 0
      end
    end)

  elseif evento == "PLAYER_REGEN_ENABLED" then
    if teclasPendentes then aplicarTeclas() end
    if barrasPendentes then agendarBarras() end

  elseif evento == "PLAYER_LOGOUT" then
    if UIForeverDB.mmGrande and E and E.db and E.db.general and E.db.general.minimap then
      E.db.general.minimap.scale = UIForeverDB.mmNormal or 1
      UIForeverDB.mmGrande = false
    end

  else -- macros ou magias mudaram
    if entrou then agendarBarras() end
  end
end)
