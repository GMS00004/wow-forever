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
  if nivel < MIN_NIVEL then return "Sem talento ainda (o primeiro vem no nivel " .. MIN_NIVEL .. ")" end
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
    if e.nivel == nivel then linhas[#linhas + 1] = "Magia: " .. comFonte(e) end
  end
  for _, par in ipairs({ { "armas", "Arma" }, { "pets", "Pet" }, { "rotacao", "Rotacao" } }) do
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
      linhas[#linhas + 1] = "Agora (nivel " .. nivel .. "): " .. (entrada(nivel) or "?")
    end
    local prox = entrada(nivel + 1)
    if prox then
      linhas[#linhas + 1] = "Proximo (nivel " .. (nivel + 1) .. "): " .. prox
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
      msg("nivel " .. nivel .. ": " .. #extras .. " dica(s) novas. J, o botao do livro ou /guia abrem o guia.")
    elseif ns.dicas() then
      msg("J, o botao do livro ou /guia abrem o guia.")
    end
  else
    for _, l in ipairs(extras) do msg(l) end
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
  if emCombate() then
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
  if emCombate() then
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
  local chave = chavePersonagem()
  if not chave then return end
  local perfil = chaves[chave]
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

  reg.versao = conj.versao or 1
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
  -- desfeito marcado: o login nao recria sozinho (so o /guia macros).
  GuiaForeverDB.macros[chave] = { desfeito = true, criadas = {}, teclas = {} }
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
local ABAS = { nivel = true, talentos = true, armas = true, pets = true, rotacao = true, prof = false, treinos = true }

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
  elseif arg == "treinadores desfazer" then
    if ns.desfazerTreinadores then ns.desfazerTreinadores() end
  elseif arg == "tecla desfazer" then
    if ns.desfazerTecla then ns.desfazerTecla() end
  elseif arg == "rastreador" then
    if ns.alternarRastreador then ns.alternarRastreador() end
  elseif arg:sub(1, 10) == "treinador " then
    if ns.setaTreinador then ns.setaTreinador(strtrim and strtrim(arg:sub(11)) or arg:sub(11)) end
  elseif ABAS[arg] then
    if ns.abrirAba then ns.abrirAba(arg) end
  elseif arg == "" then
    if ns.alternarJanela then ns.alternarJanela() end
  else
    msg("comandos: /guia (janela), /guia nivel|talentos|armas|pets|rotacao|treinos, /guia prof, /guia tudo, "
      .. "/guia treinador classe|<profissao>, /guia rastreador (mostra ou esconde as metas de profissao), "
      .. "/guia macros, /guia graficos, e os desfazer: "
      .. "/guia macros desfazer, /guia graficos desfazer, /guia treinadores desfazer, /guia tecla desfazer")
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
      msg("sem guia de talentos para a classe " .. tostring(classe) .. "; a aba Treinos funciona (J ou /guia).")
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
