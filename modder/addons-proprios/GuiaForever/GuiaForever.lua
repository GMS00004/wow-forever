-- GuiaForever: mostra o proximo talento do personagem. Logica; os dados ficam em Dados.lua.

local NOME = "GuiaForever"
local MIN_NIVEL, MAX_NIVEL = 10, 60
local COR = "|cff33ff99"
local FIM = "|r"

local dados -- dados da classe do personagem
local janela, texto

local function msg(s)
  print(COR .. "GuiaForever:" .. FIM .. " " .. s)
end

local function pontosLivres()
  if UnitCharacterPoints then
    local ok, p = pcall(UnitCharacterPoints, "player")
    if ok and type(p) == "number" then return p end
  end
  return nil -- desconhecido
end

local function entrada(nivel)
  if not dados then return nil end
  if nivel < MIN_NIVEL then return "Sem talento ainda (o primeiro vem no nivel " .. MIN_NIVEL .. ")" end
  if nivel > MAX_NIVEL then return nil end
  return dados.ordem[nivel]
end

-- Profissoes -----------------------------------------------------------
local ultimaFaixa = {} -- nome -> indice do ultimo passo mostrado
local logado = false

local function tabelaProf(nome)
  return (GuiaForeverProfissoesA and GuiaForeverProfissoesA[nome])
      or (GuiaForeverProfissoesB and GuiaForeverProfissoesB[nome])
end

-- devolve lista { {nome=, pericia=, tab=}, ... } das profissoes conhecidas com roteiro
local function minhasProfissoes()
  local achadas, vistas = {}, {}
  local function add(nome, pericia)
    if type(nome) ~= "string" or vistas[nome] then return end
    local tab = tabelaProf(nome)
    if tab and tab.passos then
      vistas[nome] = true
      achadas[#achadas + 1] = { nome = nome, pericia = tonumber(pericia) or 0, tab = tab }
    end
  end
  if GetProfessions and GetProfessionInfo then
    local ok, lista = pcall(function() return { GetProfessions() } end)
    if ok and lista then
      for i = 1, 6 do
        local idx = lista[i]
        if idx then
          local ok2, nome, _, nivel = pcall(GetProfessionInfo, idx)
          if ok2 then add(nome, nivel) end
        end
      end
    end
  end
  -- As duas APIs juntas: Cooking e First Aid podem aparecer so na lista de pericias.
  if GetNumSkillLines and GetSkillLineInfo then
    local ok, n = pcall(GetNumSkillLines)
    if ok and type(n) == "number" then
      for i = 1, n do
        local ok2, nome, cabecalho, _, rank = pcall(GetSkillLineInfo, i)
        if ok2 and not cabecalho then add(nome, rank) end
      end
    end
  end
  return achadas
end

local function indicePasso(tab, pericia)
  local p = tab.passos
  for i = 1, #p do
    if p[i].de <= pericia and pericia < p[i].ate then return i end
  end
  return #p
end

local function linhaProf(pr, idx)
  local passo = pr.tab.passos[idx]
  return pr.nome .. " " .. pr.pericia .. "/" .. passo.ate .. ": " .. passo.texto
end

local function mostrarProfissoes(forcar)
  for _, pr in ipairs(minhasProfissoes()) do
    local idx = indicePasso(pr.tab, pr.pericia)
    if forcar or ultimaFaixa[pr.nome] ~= idx then
      msg(linhaProf(pr, idx))
    end
    ultimaFaixa[pr.nome] = idx
  end
end

local function listarProfissoes()
  local lista = minhasProfissoes()
  if #lista == 0 then msg("nenhuma profissao com roteiro encontrada."); return end
  for _, pr in ipairs(lista) do
    local idx = indicePasso(pr.tab, pr.pericia)
    msg(linhaProf(pr, idx))
    local prox = pr.tab.passos[idx + 1]
    if prox then print("   Proximo (" .. prox.de .. "-" .. prox.ate .. "): " .. prox.texto) end
    if pr.tab.treino then
      for _, t in ipairs(pr.tab.treino) do print("   Treino: " .. t) end
    end
    if pr.tab.fonte then print("   Fonte: " .. pr.tab.fonte .. " (" .. tostring(pr.tab.data) .. ")") end
  end
end

local function anunciar(nivel)
  if not dados then return end
  if not (nivel >= MIN_NIVEL or nivel + 1 == MIN_NIVEL) then return end
  local linhas = {}
  local livres = pontosLivres()
  if nivel >= MIN_NIVEL and nivel <= MAX_NIVEL and (livres == nil or livres > 0) then
    linhas[#linhas + 1] = "Agora (nivel " .. nivel .. "): " .. entrada(nivel)
  end
  local prox = entrada(nivel + 1)
  if prox then
    linhas[#linhas + 1] = "Proximo (nivel " .. (nivel + 1) .. "): " .. prox
  end
  if #linhas == 0 then return end
  for _, l in ipairs(linhas) do msg(l) end
  local grande = table.concat(linhas, "\n")
  if UIErrorsFrame and UIErrorsFrame.AddMessage then
    UIErrorsFrame:AddMessage(grande, 0.2, 1, 0.6, 1, 6)
  elseif RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
    RaidNotice_AddMessage(RaidWarningFrame, grande, ChatTypeInfo["RAID_WARNING"])
  end
end

local function atualizarJanela()
  if not janela or not dados then return end
  local nivel = UnitLevel("player") or 1
  local livres = pontosLivres()
  local ini = nivel + 1
  if nivel >= MIN_NIVEL and (livres == nil or livres > 0) then ini = nivel end
  if ini < MIN_NIVEL then ini = MIN_NIVEL end
  local t = {}
  t[#t + 1] = COR .. (dados.personagem or NOME) .. " - proximos 5 pontos" .. FIM
  local n = 0
  for l = ini, MAX_NIVEL do
    if n >= 5 then break end
    t[#t + 1] = "Nivel " .. l .. ": " .. (dados.ordem[l] or "?")
    n = n + 1
  end
  if n == 0 then t[#t + 1] = "Nada a mostrar (nivel maximo do guia)." end
  if dados.lei then
    t[#t + 1] = ""
    t[#t + 1] = COR .. "Lei (entra com certeza)" .. FIM
    for _, s in ipairs(dados.lei) do t[#t + 1] = "- " .. s end
  end
  if dados.aberto then
    t[#t + 1] = ""
    t[#t + 1] = COR .. "Aberto (o dono decide)" .. FIM
    for _, a in ipairs(dados.aberto) do
      t[#t + 1] = "|cffffd100" .. a.ponto .. FIM
      for _, o in ipairs(a.opcoes) do t[#t + 1] = "   " .. o end
    end
  end
  local profs = minhasProfissoes()
  if #profs > 0 then
    t[#t + 1] = ""
    t[#t + 1] = COR .. "Profissoes" .. FIM
    for _, pr in ipairs(profs) do
      local idx = indicePasso(pr.tab, pr.pericia)
      t[#t + 1] = linhaProf(pr, idx)
      local prox = pr.tab.passos[idx + 1]
      if prox then t[#t + 1] = "   Proximo (" .. prox.de .. "-" .. prox.ate .. "): " .. prox.texto end
    end
  end
  texto:SetText(table.concat(t, "\n"))
  local h = (texto:GetStringHeight() or 100) + 40
  local max = UIParent and UIParent:GetHeight() or 700
  if h > max - 60 then h = max - 60 end
  janela:SetHeight(h)
end

local function salvarPosicao()
  if not janela or not GuiaForeverDB then return end
  local p, _, rp, x, y = janela:GetPoint()
  GuiaForeverDB.pos = { p, rp, x, y }
end

local function criarJanela()
  if janela then return end
  janela = CreateFrame("Frame", "GuiaForeverJanela", UIParent, "BackdropTemplate")
  janela:SetSize(380, 200)
  janela:SetFrameStrata("MEDIUM")
  janela:SetClampedToScreen(true)
  janela:SetMovable(true)
  janela:EnableMouse(true)
  janela:RegisterForDrag("LeftButton")
  janela:SetScript("OnDragStart", janela.StartMoving)
  janela:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    salvarPosicao()
  end)
  if janela.SetBackdrop then
    janela:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 14,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
  end
  texto = janela:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  texto:SetPoint("TOPLEFT", 12, -12)
  texto:SetWidth(356)
  texto:SetJustifyH("LEFT")
  texto:SetJustifyV("TOP")
  local pos = GuiaForeverDB and GuiaForeverDB.pos
  janela:ClearAllPoints()
  if pos and pos[1] then
    janela:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3] or 0, pos[4] or 0)
  else
    janela:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
  janela:Hide()
end

local function alternarJanela()
  if not dados then msg("sem dados para esta classe."); return end
  criarJanela()
  if janela:IsShown() then
    janela:Hide()
  else
    atualizarJanela()
    janela:Show()
  end
end

local function listarTudo()
  if not dados then msg("sem dados para esta classe."); return end
  msg((dados.personagem or "") .. " - ordem completa")
  for l = MIN_NIVEL, MAX_NIVEL do
    print(COR .. l .. FIM .. ": " .. (dados.ordem[l] or "?"))
  end
end

-- Perfil grafico ------------------------------------------------------
local function lerCVar(nome)
  local ok, v
  if C_CVar and C_CVar.GetCVar then ok, v = pcall(C_CVar.GetCVar, nome)
  elseif GetCVar then ok, v = pcall(GetCVar, nome) end
  if ok then return v end
  return nil
end

local function gravarCVar(nome, valor)
  local ok
  if C_CVar and C_CVar.SetCVar then ok = pcall(C_CVar.SetCVar, nome, valor)
  elseif SetCVar then ok = pcall(SetCVar, nome, valor) end
  return ok and true or false
end

local function aplicarGraficos(guardarAnterior)
  local alvos = GuiaForeverGraficos
  if not alvos then return end
  if InCombatLockdown and InCombatLockdown() then
    msg("graficos: em combate, tente de novo fora dele.")
    return
  end
  GuiaForeverDB.graficos = GuiaForeverDB.graficos or {}
  local g = GuiaForeverDB.graficos
  if guardarAnterior or not g.anterior then
    g.anterior = {}
    for _, a in ipairs(alvos) do g.anterior[a.cvar] = lerCVar(a.cvar) end
  end
  for _, a in ipairs(alvos) do
    local antes = lerCVar(a.cvar)
    local ok = gravarCVar(a.cvar, a.valor)
    msg(a.cvar .. ": " .. tostring(antes) .. " -> " .. (ok and a.valor or "falhou"))
  end
  g.versao = 1
end

local function desfazerGraficos()
  local g = GuiaForeverDB and GuiaForeverDB.graficos
  if not g or not g.anterior then msg("graficos: nada guardado para desfazer."); return end
  if InCombatLockdown and InCombatLockdown() then
    msg("graficos: em combate, tente de novo fora dele.")
    return
  end
  for cvar, v in pairs(g.anterior) do
    local atual = lerCVar(cvar)
    local ok = gravarCVar(cvar, v)
    msg(cvar .. ": " .. tostring(atual) .. " -> " .. (ok and tostring(v) or "falhou"))
  end
end

local function listarGraficos()
  msg("graficos: alvo e valor atual")
  for _, a in ipairs(GuiaForeverGraficos or {}) do
    print("  " .. a.cvar .. ": alvo " .. a.valor .. ", atual " .. tostring(lerCVar(a.cvar)))
  end
end

local function lembreteRestedXP()
  if type(RXPSettings) ~= "table" then return end
  local chaves = RXPSettings.profileKeys
  local perfis = RXPSettings.profiles
  if type(chaves) ~= "table" or type(perfis) ~= "table" then return end
  local nome = UnitName and UnitName("player")
  local reino = GetRealmName and GetRealmName()
  if not nome or not reino then return end
  local perfil = chaves[nome .. " - " .. reino]
  local p = perfil and perfis[perfil]
  if type(p) ~= "table" then return end
  if p.enableTalentGuides ~= false then
    msg("RestedXP: desligue os guias de talento do Classic: /rxp, aba General, secao Talents, desmarque Enable Talents Guides e de /reload.")
  end
end

-- Macros -----------------------------------------------------------------
-- Cria as macros da classe como macros do personagem, sem sobrescrever macro
-- com o mesmo nome, e liga as teclas no conjunto de teclas do personagem
-- (os outros personagens da conta nao mudam). Guarda o que fez para desfazer.

local function chavePersonagem()
  local nome = UnitName and UnitName("player")
  local reino = GetRealmName and GetRealmName()
  if not nome or not reino then return nil end
  return nome .. " - " .. reino
end

local function emCombate()
  return InCombatLockdown and InCombatLockdown()
end

local function aparar(s)
  return (tostring(s or ""):gsub("%s+$", ""))
end

local function maxMacrosPersonagem()
  if Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_CHARACTER_MACROS then
    return Constants.MacroConsts.MAX_CHARACTER_MACROS
  end
  return 18
end

local function conjuntoTeclasPersonagem()
  return (Enum and Enum.BindingSet and Enum.BindingSet.Character) or 2
end

local function criarUmaMacro(m)
  for _, icone in ipairs({ m.icone, "INV_MISC_QUESTIONMARK", 134400 }) do
    if icone then
      local ok, idx = pcall(CreateMacro, m.nome, icone, m.corpo, true)
      if ok and type(idx) == "number" and idx > 0 then return idx end
    end
  end
  return nil
end

local function criarMacros(automatico)
  local classe = select(2, UnitClass("player"))
  local conj = GuiaForeverMacros and GuiaForeverMacros[classe]
  if not conj then
    if not automatico then msg("macros: nada definido para a classe " .. tostring(classe) .. ".") end
    return
  end
  if emCombate() then msg("macros: em combate, tente de novo fora dele."); return end
  if not (CreateMacro and GetMacroIndexByName and GetNumMacros) then
    msg("macros: API de macro indisponivel neste cliente.")
    return
  end
  local chave = chavePersonagem()
  if not chave then return end
  GuiaForeverDB.macros = GuiaForeverDB.macros or {}
  local reg = GuiaForeverDB.macros[chave] or {}
  reg.criadas = reg.criadas or {}
  reg.teclas = reg.teclas or {}

  local _, nPersonagem = GetNumMacros()
  nPersonagem = tonumber(nPersonagem) or 0
  local max = maxMacrosPersonagem()
  local criadas, jaTinha, falhas = {}, {}, {}
  for _, m in ipairs(conj.lista) do
    if (GetMacroIndexByName(m.nome) or 0) > 0 then
      jaTinha[#jaTinha + 1] = m.nome
    elseif nPersonagem >= max then
      falhas[#falhas + 1] = m.nome .. " (sem espaco nas macros do personagem)"
    elseif criarUmaMacro(m) then
      criadas[#criadas + 1] = m.nome
      reg.criadas[m.nome] = m.corpo
      nPersonagem = nPersonagem + 1
    else
      falhas[#falhas + 1] = m.nome
    end
  end

  local teclas = {}
  if SetBindingMacro and GetBindingAction then
    for _, m in ipairs(conj.lista) do
      if m.tecla and (GetMacroIndexByName(m.nome) or 0) > 0 then
        local atual = GetBindingAction(m.tecla) or ""
        local alvo = "MACRO " .. m.nome
        if atual ~= alvo then
          if reg.teclas[m.tecla] == nil then reg.teclas[m.tecla] = atual end
          if pcall(SetBindingMacro, m.tecla, m.nome) then
            teclas[#teclas + 1] = m.tecla .. " = " .. m.nome
                .. (atual ~= "" and (" (antes: " .. atual .. ")") or "")
          end
        end
      end
    end
    if #teclas > 0 and SaveBindings then pcall(SaveBindings, conjuntoTeclasPersonagem()) end
  end

  reg.versao = 1
  reg.desfeito = nil
  GuiaForeverDB.macros[chave] = reg

  if #criadas > 0 then msg("macros criadas (" .. conj.fonte .. "): " .. table.concat(criadas, ", ")) end
  if #teclas > 0 then msg("teclas deste personagem: " .. table.concat(teclas, "; ")) end
  if #falhas > 0 then msg("macros que falharam: " .. table.concat(falhas, ", ")) end
  if #criadas > 0 or #teclas > 0 then
    msg("arraste as outras para a barra pelo /macro (aba do personagem). Desfazer: /guia macros desfazer")
  elseif not automatico then
    msg("macros: todas ja existem (" .. table.concat(jaTinha, ", ") .. ").")
  end
end

local function desfazerMacros()
  if emCombate() then msg("macros: em combate, tente de novo fora dele."); return end
  local chave = chavePersonagem()
  local reg = chave and GuiaForeverDB.macros and GuiaForeverDB.macros[chave]
  if not reg or (not next(reg.criadas or {}) and not next(reg.teclas or {})) then
    msg("macros: nada guardado para desfazer neste personagem.")
    return
  end
  local apagadas, mantidas = {}, {}
  for nome, corpo in pairs(reg.criadas or {}) do
    local idx = GetMacroIndexByName(nome)
    if idx and idx > 0 then
      local _, _, corpoAtual = GetMacroInfo(idx)
      if aparar(corpoAtual) == aparar(corpo) then
        DeleteMacro(idx)
        apagadas[#apagadas + 1] = nome
      else
        mantidas[#mantidas + 1] = nome
      end
    end
  end
  local voltaram = 0
  for tecla, anterior in pairs(reg.teclas or {}) do
    local ok
    if anterior == "" then
      ok = pcall(SetBinding, tecla)
    elseif anterior:sub(1, 6) == "MACRO " then
      ok = pcall(SetBindingMacro, tecla, anterior:sub(7))
    else
      ok = pcall(SetBinding, tecla, anterior)
    end
    if ok then voltaram = voltaram + 1 end
  end
  if voltaram > 0 and SaveBindings then pcall(SaveBindings, conjuntoTeclasPersonagem()) end
  -- versao fica 1 e desfeito marcado: o login nao recria sozinho.
  GuiaForeverDB.macros[chave] = { versao = 1, desfeito = true, criadas = {}, teclas = {} }
  msg("macros apagadas: " .. (#apagadas > 0 and table.concat(apagadas, ", ") or "nenhuma")
      .. "; teclas devolvidas: " .. voltaram)
  if #mantidas > 0 then msg("mantidas porque voce editou: " .. table.concat(mantidas, ", ")) end
end

local esperaCombate = CreateFrame("Frame")
esperaCombate:SetScript("OnEvent", function(self)
  self:UnregisterEvent("PLAYER_REGEN_ENABLED")
  criarMacros(true)
end)

local function macrosNoLogin()
  local chave = chavePersonagem()
  local reg = chave and GuiaForeverDB.macros and GuiaForeverDB.macros[chave]
  if reg and reg.versao == 1 then return end
  if emCombate() then
    esperaCombate:RegisterEvent("PLAYER_REGEN_ENABLED")
  else
    criarMacros(true)
  end
end

SLASH_GUIAFOREVER1 = "/guia"
SlashCmdList["GUIAFOREVER"] = function(arg)
  arg = string.lower(strtrim and strtrim(arg or "") or (arg or ""))
  if arg == "macros" then
    criarMacros(false)
  elseif arg == "macros desfazer" then
    desfazerMacros()
  elseif arg == "graficos" then
    listarGraficos()
  elseif arg == "graficos desfazer" then
    desfazerGraficos()
  elseif arg == "graficos aplicar" then
    aplicarGraficos(false)
  elseif arg == "prof" then
    listarProfissoes()
  elseif arg == "tudo" then
    listarTudo()
  else
    alternarJanela()
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("SKILL_LINES_CHANGED")
pcall(f.RegisterEvent, f, "TRADE_SKILL_LIST_UPDATE")
f:SetScript("OnEvent", function(_, evento, a1)
  if evento == "ADDON_LOADED" then
    if a1 == NOME then
      GuiaForeverDB = GuiaForeverDB or {}
    end
  elseif evento == "PLAYER_LOGIN" then
    GuiaForeverDB = GuiaForeverDB or {}
    local g = GuiaForeverDB.graficos
    if not (g and g.versao == 1) and not (InCombatLockdown and InCombatLockdown()) then
      aplicarGraficos(true)
    end
    lembreteRestedXP()
    -- Espera as macros e as teclas do personagem carregarem (inclusive as do servidor).
    if C_Timer and C_Timer.After then C_Timer.After(8, macrosNoLogin) else macrosNoLogin() end
    logado = true
    mostrarProfissoes(true)
    local classe = select(2, UnitClass("player"))
    dados = GuiaForeverDados and GuiaForeverDados[classe]
    if not dados then
      msg("sem guia para a classe " .. tostring(classe) .. ".")
      return
    end
    anunciar(UnitLevel("player") or 1)
  elseif evento == "SKILL_LINES_CHANGED" or evento == "TRADE_SKILL_LIST_UPDATE" then
    if logado then
      mostrarProfissoes(false)
      if janela and janela:IsShown() then atualizarJanela() end
    end
  elseif evento == "PLAYER_LEVEL_UP" then
    local nivel = tonumber(a1) or UnitLevel("player") or 1
    anunciar(nivel)
    if janela and janela:IsShown() then atualizarJanela() end
  end
end)
