-- GuiaForever: talento e dicas por nivel, profissoes, perfil grafico e macros.
-- Logica; os dados ficam em Dados.lua, Dicas.lua e Profissoes*.lua. A janela fica
-- em Janela.lua e os treinadores em Treinadores.lua; os tres compartilham `ns`.

local NOME, ns = ...
NOME = NOME or "GuiaForever"
ns = ns or {}
local MIN_NIVEL, MAX_NIVEL = 10, 60
local COR = "|cff33ff99"
local FIM = "|r"
ns.MIN_NIVEL, ns.MAX_NIVEL, ns.COR, ns.FIM = MIN_NIVEL, MAX_NIVEL, COR, FIM
-- Ganchos: Janela.lua e Treinadores.lua acrescentam funcoes a estas listas.
ns.aoCarregar = ns.aoCarregar or {} -- no ADDON_LOADED do GuiaForever (depois do Questie)
ns.aoEntrar = ns.aoEntrar or {}     -- 8 s depois do PLAYER_LOGIN

local dados -- talentos da classe do personagem (GuiaForeverDados)

local function msg(s)
  print(COR .. "GuiaForever:" .. FIM .. " " .. s)
end
ns.msg = msg

local function classeJogador()
  return select(2, UnitClass("player"))
end
ns.classe = classeJogador

ns.dados = function() return dados end
ns.dicas = function()
  return GuiaForeverDicas and GuiaForeverDicas[classeJogador()]
end

local function pontosLivres()
  if UnitCharacterPoints then
    local ok, p = pcall(UnitCharacterPoints, "player")
    if ok and type(p) == "number" then return p end
  end
  return nil -- desconhecido
end
ns.pontosLivres = pontosLivres

local function entrada(nivel)
  if not dados then return nil end
  if nivel < MIN_NIVEL then return "No talent yet (the first one comes at level " .. MIN_NIVEL .. ")" end
  if nivel > MAX_NIVEL then return nil end
  return dados.ordem[nivel]
end
ns.entrada = entrada

local function chavePersonagem()
  local nome = UnitName and UnitName("player")
  local reino = GetRealmName and GetRealmName()
  if not nome or not reino then return nil end
  return nome .. " - " .. reino
end
ns.chavePersonagem = chavePersonagem

local function emCombate()
  return InCombatLockdown and InCombatLockdown()
end
ns.emCombate = emCombate

-- Profissoes -----------------------------------------------------------
local ultimaFaixa = {} -- nome -> indice do ultimo passo mostrado
local logado = false

local function tabelaProf(nome)
  return (GuiaForeverProfissoesA and GuiaForeverProfissoesA[nome])
      or (GuiaForeverProfissoesB and GuiaForeverProfissoesB[nome])
end
ns.tabelaProf = tabelaProf

-- devolve lista { {nome=, pericia=, maximo=, tab=}, ... } das profissoes conhecidas
-- com roteiro; maximo e o teto do treino atual (75, 150, ...), quando a API o da
local function minhasProfissoes()
  local achadas, vistas = {}, {}
  local function add(nome, pericia, maximo)
    if type(nome) ~= "string" or vistas[nome] then return end
    local tab = tabelaProf(nome)
    if tab and tab.passos then
      vistas[nome] = true
      achadas[#achadas + 1] = { nome = nome, pericia = tonumber(pericia) or 0, maximo = tonumber(maximo), tab = tab }
    end
  end
  -- API do Forever: C_SkillInfo (a janela de pericias do camelot usa esta,
  -- Blizzard_UIPanels_Game/Camelot/SkillsFrame.lua). As globais antigas abaixo
  -- ficam de reserva; nao foi conferido se existem no cliente (2026-11-06).
  local SI = C_SkillInfo
  if SI and SI.GetNumSkillLines and SI.GetSkillLineInfo then
    local ok, n = pcall(SI.GetNumSkillLines)
    if ok and type(n) == "number" then
      for i = 1, n do
        local ok2, info = pcall(SI.GetSkillLineInfo, i)
        if ok2 and type(info) == "table" and not info.isHeader then add(info.name, info.rank, info.maxRank) end
      end
    end
  end
  if GetProfessions and GetProfessionInfo then
    local ok, lista = pcall(function() return { GetProfessions() } end)
    if ok and lista then
      for i = 1, 6 do
        local idx = lista[i]
        if idx then
          local ok2, nome, _, nivel, teto = pcall(GetProfessionInfo, idx)
          if ok2 then add(nome, nivel, teto) end
        end
      end
    end
  end
  -- As duas APIs juntas: Cooking e First Aid podem aparecer so na lista de pericias.
  if GetNumSkillLines and GetSkillLineInfo then
    local ok, n = pcall(GetNumSkillLines)
    if ok and type(n) == "number" then
      for i = 1, n do
        local ok2, nome, cabecalho, _, rank, _, _, teto = pcall(GetSkillLineInfo, i)
        if ok2 and not cabecalho then add(nome, rank, teto) end
      end
    end
  end
  return achadas
end
ns.minhasProfissoes = minhasProfissoes

local function indicePasso(tab, pericia)
  local p = tab.passos
  for i = 1, #p do
    if p[i].de <= pericia and pericia < p[i].ate then return i end
  end
  return #p
end
ns.indicePasso = indicePasso

local function linhaProf(pr, idx)
  local passo = pr.tab.passos[idx]
  return pr.nome .. " " .. pr.pericia .. "/" .. passo.ate .. ": " .. passo.texto
end
ns.linhaProf = linhaProf

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
  if #lista == 0 then msg("no profession with a leveling route found."); return end
  for _, pr in ipairs(lista) do
    local idx = indicePasso(pr.tab, pr.pericia)
    msg(linhaProf(pr, idx))
    local prox = pr.tab.passos[idx + 1]
    if prox then print("   Next (" .. prox.de .. "-" .. prox.ate .. "): " .. prox.texto) end
    if pr.tab.treino then
      for _, t in ipairs(pr.tab.treino) do print("   Training: " .. t) end
    end
    if pr.tab.fonte then print("   Source: " .. pr.tab.fonte .. " (" .. tostring(pr.tab.data) .. ")") end
  end
end

-- Dicas do nivel (Dicas.lua) ---------------------------------------------
local function comFonte(e)
  return e.texto .. " |cff999999(" .. tostring(e.fonte) .. ")|r"
end
ns.comFonte = comFonte

-- O que comeca exatamente neste nivel: magias do nivel e faixas que abrem nele.
local function dicasDoNivel(nivel)
  local d = ns.dicas()
  local linhas = {}
  if not d then return linhas end
  for _, e in ipairs(d.magias or {}) do
    if e.nivel == nivel then linhas[#linhas + 1] = "Spell: " .. comFonte(e) end
  end
  for _, par in ipairs({ { "armas", "Weapon" }, { "pets", "Pet" }, { "rotacao", "Rotation" } }) do
    for _, e in ipairs(d[par[1]] or {}) do
      if e.de == nivel then linhas[#linhas + 1] = par[2] .. ": " .. comFonte(e) end
    end
  end
  return linhas
end
ns.dicasDoNivel = dicasDoNivel

local function anunciar(nivel, login)
  local linhas = {}
  if dados and (nivel >= MIN_NIVEL or nivel + 1 == MIN_NIVEL) then
    local livres = pontosLivres()
    if nivel >= MIN_NIVEL and nivel <= MAX_NIVEL and (livres == nil or livres > 0) then
      linhas[#linhas + 1] = "Now (level " .. nivel .. "): " .. (entrada(nivel) or "?")
    end
    local prox = entrada(nivel + 1)
    if prox then
      linhas[#linhas + 1] = "Next (level " .. (nivel + 1) .. "): " .. prox
    end
  end
  if #linhas > 0 then
    for _, l in ipairs(linhas) do msg(l) end
    local grande = table.concat(linhas, "\n")
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
      UIErrorsFrame:AddMessage(grande, 0.2, 1, 0.6, 1, 6)
    elseif RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
      RaidNotice_AddMessage(RaidWarningFrame, grande, ChatTypeInfo["RAID_WARNING"])
    end
  end
  local extras = dicasDoNivel(nivel)
  if login then
    if #extras > 0 then
      msg("level " .. nivel .. ": " .. #extras .. " new tip(s). J, the book button or /guia opens the guide.")
    elseif ns.dicas() then
      msg("J, the book button or /guia opens the guide.")
    end
  else
    for _, l in ipairs(extras) do msg(l) end
  end
end

local function listarTudo()
  if not dados then msg("no data for this class."); return end
  msg((dados.personagem or "") .. " - full order")
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
  if emCombate() then
    msg("graphics: in combat, try again out of combat.")
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
    msg(a.cvar .. ": " .. tostring(antes) .. " -> " .. (ok and a.valor or "failed"))
  end
  g.versao = 1
end

local function desfazerGraficos()
  local g = GuiaForeverDB and GuiaForeverDB.graficos
  if not g or not g.anterior then msg("graphics: nothing saved to undo."); return end
  if emCombate() then
    msg("graphics: in combat, try again out of combat.")
    return
  end
  for cvar, v in pairs(g.anterior) do
    local atual = lerCVar(cvar)
    local ok = gravarCVar(cvar, v)
    msg(cvar .. ": " .. tostring(atual) .. " -> " .. (ok and tostring(v) or "failed"))
  end
end

local function listarGraficos()
  msg("graphics: target and current value")
  for _, a in ipairs(GuiaForeverGraficos or {}) do
    print("  " .. a.cvar .. ": target " .. a.valor .. ", current " .. tostring(lerCVar(a.cvar)))
  end
end

local function lembreteRestedXP()
  if type(RXPSettings) ~= "table" then return end
  local chaves = RXPSettings.profileKeys
  local perfis = RXPSettings.profiles
  if type(chaves) ~= "table" or type(perfis) ~= "table" then return end
  local chave = chavePersonagem()
  if not chave then return end
  local perfil = chaves[chave]
  local p = perfil and perfis[perfil]
  if type(p) ~= "table" then return end
  if p.enableTalentGuides ~= false then
    msg("RestedXP: turn off the Classic talent guides: /rxp, General tab, Talents section, untick Enable Talents Guides and /reload.")
  end
end

-- Macros -----------------------------------------------------------------
-- Cria as macros da classe como macros do personagem, sem sobrescrever macro
-- com o mesmo nome, e liga as teclas no conjunto de teclas do personagem
-- (os outros personagens da conta nao mudam). Guarda o que fez para desfazer.

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
  local classe = classeJogador()
  local conj = GuiaForeverMacros and GuiaForeverMacros[classe]
  if not conj then
    if not automatico then msg("macros: nothing defined for class " .. tostring(classe) .. ".") end
    return
  end
  if emCombate() then msg("macros: in combat, try again out of combat."); return end
  if not (CreateMacro and GetMacroIndexByName and GetNumMacros) then
    msg("macros: macro API unavailable on this client.")
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
      falhas[#falhas + 1] = m.nome .. " (no room in the character macros)"
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
                .. (atual ~= "" and (" (was: " .. atual .. ")") or "")
          end
        end
      end
    end
    if #teclas > 0 and SaveBindings then pcall(SaveBindings, conjuntoTeclasPersonagem()) end
  end

  reg.versao = conj.versao or 1
  reg.desfeito = nil
  GuiaForeverDB.macros[chave] = reg

  if #criadas > 0 then msg("macros created (" .. conj.fonte .. "): " .. table.concat(criadas, ", ")) end
  if #teclas > 0 then msg("keys for this character: " .. table.concat(teclas, "; ")) end
  if #falhas > 0 then msg("macros that failed: " .. table.concat(falhas, ", ")) end
  if #criadas > 0 or #teclas > 0 then
    msg("drag the others to your bars from /macro (character tab). Undo: /guia macros undo")
  elseif not automatico then
    msg("macros: all already exist (" .. table.concat(jaTinha, ", ") .. ").")
  end
end

local function desfazerMacros()
  if emCombate() then msg("macros: in combat, try again out of combat."); return end
  local chave = chavePersonagem()
  local reg = chave and GuiaForeverDB.macros and GuiaForeverDB.macros[chave]
  if not reg or (not next(reg.criadas or {}) and not next(reg.teclas or {})) then
    msg("macros: nothing saved to undo for this character.")
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
  -- desfeito marcado: o login nao recria sozinho (so o /guia macros).
  GuiaForeverDB.macros[chave] = { desfeito = true, criadas = {}, teclas = {} }
  msg("macros deleted: " .. (#apagadas > 0 and table.concat(apagadas, ", ") or "none")
      .. "; keys restored: " .. voltaram)
  if #mantidas > 0 then msg("kept because you edited them: " .. table.concat(mantidas, ", ")) end
end

local esperaCombate = CreateFrame("Frame")
esperaCombate:SetScript("OnEvent", function(self)
  self:UnregisterEvent("PLAYER_REGEN_ENABLED")
  criarMacros(true)
end)

local function macrosNoLogin()
  local classe = classeJogador()
  local conj = GuiaForeverMacros and GuiaForeverMacros[classe]
  if not conj then return end
  local chave = chavePersonagem()
  local reg = chave and GuiaForeverDB.macros and GuiaForeverDB.macros[chave]
  if reg and (reg.desfeito or (reg.versao or 0) >= (conj.versao or 1)) then return end
  if emCombate() then
    esperaCombate:RegisterEvent("PLAYER_REGEN_ENABLED")
  else
    criarMacros(true)
  end
end

-- Comandos ---------------------------------------------------------------
local ABAS = { nivel = true, talentos = true, armas = true, pets = true, rotacao = true, prof = false, treinos = true, zona = true, teclas = true }

-- Apelidos em ingles: cada subcomando em portugues continua valendo.
local APELIDO_1 = {
  level = "nivel", talents = "talentos", weapons = "armas", rotation = "rotacao",
  trainers = "treinos", zone = "zona", keys = "teclas", training = "treinos", all = "tudo", professions = "prof",
  tracker = "rastreador", graphics = "graficos", key = "tecla", trainer = "treinador",
}
local APELIDO_2 = { undo = "desfazer", apply = "aplicar", class = "classe" }

local function normalizarArg(arg)
  local a, b = arg:match("^(%S+)%s*(.-)$")
  if not a then return "" end
  a = APELIDO_1[a] or a
  if a == "treinador" then
    -- "trainer class|<profession>": o resto e o nome da profissao (nao traduzir)
    if b == "class" then b = "classe" end
  else
    b = APELIDO_2[b] or b
  end
  if a == "treinos" and b == "desfazer" then a = "treinadores" end -- "trainers undo"
  if b ~= "" then return a .. " " .. b end
  return a
end

SLASH_GUIAFOREVER1 = "/guia"
SlashCmdList["GUIAFOREVER"] = function(arg)
  arg = string.lower(strtrim and strtrim(arg or "") or (arg or ""))
  arg = normalizarArg(arg)
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
  elseif arg == "treinadores desfazer" then
    if ns.desfazerTreinadores then ns.desfazerTreinadores() end
  elseif arg == "tecla desfazer" then
    if ns.desfazerTecla then ns.desfazerTecla() end
  elseif arg == "rastreador" then
    if ns.alternarRastreador then ns.alternarRastreador() end
  elseif arg == "treinador" or arg:sub(1, 10) == "treinador " then
    if ns.setaTreinador then ns.setaTreinador(strtrim and strtrim(arg:sub(11)) or arg:sub(11)) end
  elseif ABAS[arg] then
    if ns.abrirAba then ns.abrirAba(arg) end
  elseif arg == "" then
    if ns.alternarJanela then ns.alternarJanela() end
  else
    msg("commands: /guia (window), /guia level|talents|weapons|pets|rotation|keys|trainers|zone, /guia prof, /guia all, "
      .. "/guia trainer class|<profession>, /guia tracker (shows or hides the profession goals), "
      .. "/guia macros, /guia graphics, and the undo ones: "
      .. "/guia macros undo, /guia graphics undo, /guia trainers undo, /guia key undo")
  end
end

local function atualizarJanelaDepois()
  if ns.atualizarJanela then
    if C_Timer and C_Timer.After then C_Timer.After(1, ns.atualizarJanela) else ns.atualizarJanela() end
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
      for _, fn in ipairs(ns.aoCarregar) do xpcall(fn, geterrorhandler()) end
    end
  elseif evento == "PLAYER_LOGIN" then
    GuiaForeverDB = GuiaForeverDB or {}
    local g = GuiaForeverDB.graficos
    if not (g and g.versao == 1) and not emCombate() then
      aplicarGraficos(true)
    end
    lembreteRestedXP()
    -- Espera as macros e as teclas do personagem carregarem (inclusive as do servidor).
    local function depois()
      macrosNoLogin()
      for _, fn in ipairs(ns.aoEntrar) do xpcall(fn, geterrorhandler()) end
    end
    if C_Timer and C_Timer.After then C_Timer.After(8, depois) else depois() end
    logado = true
    mostrarProfissoes(true)
    local classe = classeJogador()
    dados = GuiaForeverDados and GuiaForeverDados[classe]
    if not dados and not ns.dicas() then
      msg("no talent guide for class " .. tostring(classe) .. "; the Trainers tab works (J or /guia).")
      return
    end
    anunciar(UnitLevel("player") or 1, true)
  elseif evento == "SKILL_LINES_CHANGED" or evento == "TRADE_SKILL_LIST_UPDATE" then
    if logado then
      mostrarProfissoes(false)
      atualizarJanelaDepois()
    end
  elseif evento == "PLAYER_LEVEL_UP" then
    local nivel = tonumber(a1) or UnitLevel("player") or 1
    anunciar(nivel, false)
    atualizarJanelaDepois()
  end
end)
