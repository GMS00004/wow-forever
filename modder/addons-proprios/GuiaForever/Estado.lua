-- GuiaForever: Base comum: eventos, estado do jogo, seta, teclas e filtro (tarefa A5; contrato em ARQUITETURA.md, secao 3).
-- Este arquivo nao chama Agora, Pet, Arvore nem Tooltips: quem usa a base sao eles (regra 3).
-- Nada de alterar teclas ou macros aqui (regra 4) e nenhuma API que vira secreta (regra 5).

local _, ns = ...

-- Utilidades ------------------------------------------------------------------

local function emCombate()
  return InCombatLockdown and InCombatLockdown() and true or false
end

-- No Lua 5.1 o xpcall nao repassa argumentos: por isso o fechamento (regra 10: erro vai para o BugSack).
local function seguro(fn, ...)
  if type(fn) ~= "function" then return false end
  local n = select("#", ...)
  local args = { ... }
  return xpcall(function() return fn(unpack(args, 1, n)) end, geterrorhandler())
end

-- Eventos (ns.ao) ---------------------------------------------------------------

local quadro = CreateFrame("Frame")
local ouvintes = {} -- evento -> lista de fn, na ordem de registro

quadro:SetScript("OnEvent", function(_, evento, ...)
  local lista = ouvintes[evento]
  if not lista then return end
  -- copia: um ouvinte que registra outro durante o evento nao mexe na iteracao
  local copia = {}
  for i = 1, #lista do copia[i] = lista[i] end
  for i = 1, #copia do seguro(copia[i], evento, ...) end
end)

function ns.ao(evento, fn)
  if type(evento) ~= "string" or type(fn) ~= "function" then return end
  if not ouvintes[evento] then
    ouvintes[evento] = {}
    -- pcall: evento que o cliente nao conhece nao pode quebrar o carregamento
    pcall(quadro.RegisterEvent, quadro, evento)
  end
  local lista = ouvintes[evento]
  lista[#lista + 1] = fn
end

-- Debounce e fila de combate -------------------------------------------------------

local pendentes = {} -- chave -> ficha do timer vigente (o ultimo pedido vence)

function ns.agendar(chave, segundos, fn)
  local ficha = {}
  pendentes[chave] = ficha
  if not (C_Timer and C_Timer.After) then
    pendentes[chave] = nil
    seguro(fn)
    return
  end
  C_Timer.After(segundos or 0, function()
    if pendentes[chave] ~= ficha then return end -- um pedido mais novo ocupou a chave
    pendentes[chave] = nil
    seguro(fn)
  end)
end

local fila = {}      -- chave -> fn guardada para depois do combate
local ordemFila = {} -- chaves na ordem em que chegaram

function ns.foraDeCombate(chave, fn)
  if not emCombate() then
    fila[chave] = nil -- a execucao de agora substitui o que estava guardado
    seguro(fn)
    return
  end
  if fila[chave] == nil then ordemFila[#ordemFila + 1] = chave end
  fila[chave] = fn
end

ns.ao("PLAYER_REGEN_ENABLED", function()
  if emCombate() then return end
  -- esvazia antes de rodar: uma fn que se reagenda nao entra em laco
  local chaves, fns = ordemFila, fila
  ordemFila, fila = {}, {}
  for i = 1, #chaves do
    local c = chaves[i]
    if fns[c] then seguro(fns[c]) end
  end
end)

-- Banco do addon ------------------------------------------------------------------

function ns.log(texto)
  GuiaForeverDB = GuiaForeverDB or {}
  local l = GuiaForeverDB.log
  if type(l) ~= "table" then l = {}; GuiaForeverDB.log = l end
  l[#l + 1] = date("%Y-%m-%d %H:%M:%S") .. " " .. tostring(texto)
  while #l > 60 do table.remove(l, 1) end
end

function ns.dbPersonagem()
  GuiaForeverDB = GuiaForeverDB or {}
  if type(GuiaForeverDB.personagens) ~= "table" then GuiaForeverDB.personagens = {} end
  -- chave nula so ocorre muito cedo (sem nome/reino): usa uma reserva em vez de quebrar quem chama
  local chave = (ns.chavePersonagem and ns.chavePersonagem()) or "desconhecido"
  local t = GuiaForeverDB.personagens[chave]
  if type(t) ~= "table" then t = {}; GuiaForeverDB.personagens[chave] = t end
  return t
end

-- Magias: nome e icone ---------------------------------------------------------------

function ns.nomeMagia(id)
  if not id then return nil end
  if C_Spell and C_Spell.GetSpellName then
    local ok, n = pcall(C_Spell.GetSpellName, id)
    if ok and n then return n end
  end
  if GetSpellInfo then
    local ok, n = pcall(GetSpellInfo, id)
    if ok and n then return n end
  end
  return nil
end

function ns.iconeMagia(id)
  if not id then return nil end
  if C_Spell and C_Spell.GetSpellTexture then
    local ok, t = pcall(C_Spell.GetSpellTexture, id)
    if ok and t then return t end
  end
  if GetSpellInfo then
    local ok, _, _, icone = pcall(GetSpellInfo, id)
    if ok and icone then return icone end
  end
  return nil
end

-- Livro de magias ----------------------------------------------------------------------

local livroJogador = nil -- nome em minuscula -> id; nil = precisa varrer
local livroPet = nil     -- nome em minuscula -> true
local livroPetSujo = true

local function bancoDe(qual)
  return Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank[qual]
end

-- Varredura no modelo do UIForever (magiasConhecidas), mas guarda tambem as passivas: "requer" pode ser uma delas.
local function varrerLivroJogador()
  local mapa = {}
  local banco = bancoDe("Player")
  local tipoMagia = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
  if banco and C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines
     and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemInfo then
    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
      local linha = C_SpellBook.GetSpellBookSkillLineInfo(i)
      if linha and linha.itemIndexOffset and linha.numSpellBookItems then
        for s = linha.itemIndexOffset + 1, linha.itemIndexOffset + linha.numSpellBookItems do
          local info = C_SpellBook.GetSpellBookItemInfo(s, banco)
          if info and info.spellID and info.name and (tipoMagia == nil or info.itemType == tipoMagia) then
            mapa[string.lower(info.name)] = info.spellID
          end
        end
      end
    end
  end
  livroJogador = mapa
end

local function reconstruirLivro()
  local ok, err = pcall(varrerLivroJogador)
  if not ok then
    livroJogador = livroJogador or {}
    ns.log("livro de magias: " .. tostring(err))
  end
  livroPetSujo = true -- o do pet e relido sob demanda
end

function ns.conhece(magia)
  if type(magia) == "number" then
    if C_SpellBook and C_SpellBook.IsSpellKnown then
      local ok, r = pcall(C_SpellBook.IsSpellKnown, magia)
      return ok and r and true or false
    end
    return false
  end
  if type(magia) ~= "string" then return false end
  if livroJogador == nil then reconstruirLivro() end -- primeiro uso antes do login
  return livroJogador[string.lower(magia)] ~= nil
end

local function varrerLivroPet()
  local mapa = {}
  local banco = bancoDe("Pet")
  if banco and C_SpellBook and C_SpellBook.HasPetSpells and C_SpellBook.GetSpellBookItemInfo then
    local n = C_SpellBook.HasPetSpells()
    if type(n) == "number" then
      for s = 1, n do
        local info = C_SpellBook.GetSpellBookItemInfo(s, banco)
        if info and info.name then mapa[string.lower(info.name)] = true end
      end
    end
  end
  -- reserva: nomes da barra do pet (a primeira posicao devolve o nome, ou o token localizado)
  if GetPetActionInfo then
    for i = 1, 10 do
      local nome, _, ehToken = GetPetActionInfo(i)
      if type(nome) == "string" then
        if ehToken and type(_G[nome]) == "string" then nome = _G[nome] end
        mapa[string.lower(nome)] = true
      end
    end
  end
  livroPet = mapa
  livroPetSujo = false
end

function ns.petConhece(nome)
  if type(nome) ~= "string" then return false end
  if livroPetSujo or livroPet == nil then
    if not pcall(varrerLivroPet) then livroPet = livroPet or {}; livroPetSujo = false end
  end
  return livroPet[string.lower(nome)] == true
end

-- Talentos ---------------------------------------------------------------------------------

function ns.pontosTalento()
  if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits
          and C_Traits.GetConfigInfo and C_Traits.GetTreeCurrencyInfo) then
    return nil
  end
  local ok, r = pcall(function()
    local cfg = C_ClassTalents.GetActiveConfigID()
    if not cfg then return nil end
    local info = C_Traits.GetConfigInfo(cfg)
    local arvore = info and info.treeIDs and info.treeIDs[1]
    if not arvore then return nil end
    local moedas = C_Traits.GetTreeCurrencyInfo(cfg, arvore, false)
    local q = moedas and moedas[1] and moedas[1].quantity
    if type(q) == "number" then return q end
    return nil
  end)
  if ok then return r end
  return nil
end

-- Missoes -----------------------------------------------------------------------------------

function ns.missao(id)
  if not (id and C_QuestLog) then return "fora" end
  local ok, r = pcall(function()
    if C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(id) then return "feita" end
    local nolog = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(id)
    local andando = nolog or (C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(id))
    if not andando then return "fora" end
    if C_QuestLog.IsComplete and C_QuestLog.IsComplete(id) then return "pronta" end
    return "andando"
  end)
  if ok and r then return r end
  return "fora"
end

-- Estado do jogo (ns.estado) ----------------------------------------------------------------

-- Um unico objeto, alterado no lugar: quem guardou `ns.estado` ou `ns.estado.pet` ve sempre o valor novo.
local estado = {
  nivel = 1, classe = nil, raca = nil, faccao = nil, emGrupo = false,
  mapa = nil, zona = nil, continente = nil,
  pet = { existe = false, morto = false, nome = nil, felicidade = nil, danoPct = nil,
          dieta = nil, pontosTotal = nil, pontosUsados = nil, nivel = nil },
}
ns.estado = estado

local nivelDeLevelUp = nil -- o PLAYER_LEVEL_UP traz o nivel certo antes do UnitLevel atualizar

local function acharContinente(mapa)
  local tipoContinente = Enum and Enum.UIMapType and Enum.UIMapType.Continent
  if not (mapa and tipoContinente and C_Map and C_Map.GetMapInfo) then return nil end
  for _ = 1, 10 do -- limite de subida: nunca laco infinito
    local info = C_Map.GetMapInfo(mapa)
    if not info then return nil end
    if info.mapType == tipoContinente then return mapa end
    if not info.parentMapID or info.parentMapID == 0 then return nil end
    mapa = info.parentMapID
  end
  return nil
end

local function atualizarPet(p)
  p.existe = UnitExists("pet") and true or false
  p.morto = p.existe and UnitIsDead("pet") and true or false
  p.nome = p.existe and UnitName("pet") or nil
  p.nivel = p.existe and UnitLevel("pet") or nil
  p.felicidade, p.danoPct = nil, nil
  if p.existe and C_PetInfo and C_PetInfo.GetPetHappiness then
    local f, d = C_PetInfo.GetPetHappiness()
    p.felicidade, p.danoPct = f, d
  end
  p.dieta = nil
  if C_PetInfo and C_PetInfo.GetPetFoodTypes then p.dieta = C_PetInfo.GetPetFoodTypes() end
  p.pontosTotal, p.pontosUsados = nil, nil
  if C_PetInfo and C_PetInfo.GetPetTrainingPoints then
    p.pontosTotal, p.pontosUsados = C_PetInfo.GetPetTrainingPoints()
  end
end

local function atualizarEstado()
  local nivel = UnitLevel("player") or estado.nivel
  if nivelDeLevelUp then
    if nivel >= nivelDeLevelUp then nivelDeLevelUp = nil else nivel = nivelDeLevelUp end
  end
  estado.nivel = nivel
  estado.classe = select(2, UnitClass("player")) or estado.classe
  estado.raca = select(2, UnitRace("player")) or estado.raca
  estado.faccao = UnitFactionGroup("player") or estado.faccao
  estado.emGrupo = ((IsInGroup and IsInGroup()) or (IsInRaid and IsInRaid())) and true or false
  if C_Map and C_Map.GetBestMapForUnit then
    local m = C_Map.GetBestMapForUnit("player")
    if m then
      if m ~= estado.mapa or estado.continente == nil then estado.continente = acharContinente(m) end
      estado.mapa = m
    end
  end
  local z = GetRealZoneText and GetRealZoneText()
  if z and z ~= "" then estado.zona = z end
  local ok, err = pcall(atualizarPet, estado.pet)
  if not ok then ns.log("estado do pet: " .. tostring(err)) end
end

-- Todos os eventos passam pelo mesmo debounce curto: rajadas viram uma leitura so.
local function pedirAtualizacao()
  ns.agendar("estado:atualizar", 0.2, atualizarEstado)
end

local function pedirLivro()
  ns.agendar("estado:livro", 0.5, reconstruirLivro)
end

local eventosEstado = {
  "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "GROUP_ROSTER_UPDATE",
  "UNIT_PET", "UNIT_HAPPINESS", "PET_UI_UPDATE", "PET_BAR_UPDATE",
  "UNIT_PET_TRAINING_POINTS", "TRAIT_TREE_CURRENCY_INFO_UPDATED", "QUEST_LOG_UPDATE",
}
for _, e in ipairs(eventosEstado) do
  ns.ao(e, function(evento, unidade)
    -- eventos de unidade chegam de todo mundo: so interessa o jogador e o pet dele
    if (evento == "UNIT_PET" or evento == "UNIT_HAPPINESS") and unidade
       and unidade ~= "player" and unidade ~= "pet" then
      return
    end
    pedirAtualizacao()
  end)
end

ns.ao("PLAYER_LEVEL_UP", function(_, nivel)
  nivel = tonumber(nivel)
  if nivel then nivelDeLevelUp = nivel; estado.nivel = nivel end
  pedirAtualizacao()
end)

ns.ao("PLAYER_LOGIN", function()
  atualizarEstado()
  pedirLivro()
end)

-- A varredura do livro de magias so acontece nestes tres pontos (login, SPELLS_CHANGED e aprender magia).
ns.ao("SPELLS_CHANGED", function() pedirLivro(); livroPetSujo = true; pedirAtualizacao() end)
ns.ao("LEARNED_SPELL_IN_SKILL_LINE", function() pedirLivro() end)

-- Leitura inicial: o addon pode carregar ja com o personagem no mundo (um /reload).
pcall(atualizarEstado)

-- Filtro das dicas (secao 7) -------------------------------------------------------------------

function ns.relevante(e, ctx)
  if type(e) ~= "table" then return true end
  local tudo = ctx and ctx.tudo
  local aba = ctx and ctx.aba
  local tags = e.tags
  if type(tags) == "table" then
    for _, t in ipairs(tags) do
      if (t == "pvp" or t == "fimdejogo") and not tudo then return false end
      if t == "grupo" and not estado.emGrupo and not tudo then return false end
      if t == "escolhapet" and aba ~= "pet" and not tudo then return false end
    end
  end
  if e.raca and e.raca ~= estado.raca then return false end -- raca vale mesmo com "tudo"
  if e.zona and e.zona ~= estado.zona and not tudo then return false end
  if e.requer and not ns.conhece(e.requer) then return false end -- magia que falta vale mesmo com "tudo"
  return true
end

-- Seta -----------------------------------------------------------------------------------------

local uidTomTom = nil
local setaNativa = false

function ns.limparSeta()
  if uidTomTom ~= nil then
    if TomTom and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, uidTomTom) end
    uidTomTom = nil
  end
  if setaNativa then
    -- so apaga a nativa se foi o guia quem a pos: o ponto do proprio dono nao e tocado
    if C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
    setaNativa = false
  end
end

function ns.seta(mapa, x, y, titulo)
  if type(mapa) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return false end
  ns.limparSeta() -- uma seta do guia por vez
  if TomTom and TomTom.AddWaypoint then
    local ok, uid = pcall(TomTom.AddWaypoint, TomTom, mapa, x, y, {
      title = titulo, from = "GuiaForever", persistent = false, crazy = true, cleardistance = 10,
    })
    if ok and uid then uidTomTom = uid; return true end
  end
  -- UiMapPoint nao esta nas listas do Forever: confere antes de usar
  if C_Map and C_Map.CanSetUserWaypointOnMap and C_Map.SetUserWaypoint
     and UiMapPoint and UiMapPoint.CreateFromCoordinates
     and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
    local ok = pcall(function()
      if not C_Map.CanSetUserWaypointOnMap(mapa) then error("mapa sem ponto do usuario") end
      C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapa, x, y))
      C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end)
    if ok then setaNativa = true; return true end
  end
  local txt = string.format("/way #%d %.1f %.1f", mapa, x * 100, y * 100)
  if titulo then txt = txt .. " " .. titulo end
  if ns.msg then ns.msg(txt) else print(txt) end
  return false
end

-- Distancia em jardas ate um ponto do mapa (mesmo continente) ---------------------------------------

function ns.distancia(mapa, x, y)
  if not (mapa and x and y and C_Map and C_Map.GetWorldPosFromMapPos
          and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition and CreateVector2D) then
    return nil
  end
  local ok, d = pcall(function()
    local meu = C_Map.GetBestMapForUnit("player")
    if not meu then return nil end
    local p = C_Map.GetPlayerMapPosition(meu, "player")
    if not p then return nil end
    local px, py = p:GetXY()
    local c1, w1 = C_Map.GetWorldPosFromMapPos(meu, CreateVector2D(px, py))
    local c2, w2 = C_Map.GetWorldPosFromMapPos(mapa, CreateVector2D(x, y))
    if not (c1 and c2 and w1 and w2) or c1 ~= c2 then return nil end -- continentes diferentes: sem distancia
    local ax, ay = w1:GetXY()
    local bx, by = w2:GetXY()
    return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
  end)
  if ok then return d end
  return nil
end

-- Tecla de uma magia ou macro nas barras --------------------------------------------------------------

-- Comando de teclado de cada bloco de 12 slots (contrato: slots 1 a 72).
local PREFIXOS_SLOT = {
  "ACTIONBUTTON", "ELVUIBAR2BUTTON", "MULTIACTIONBAR3BUTTON",
  "MULTIACTIONBAR4BUTTON", "MULTIACTIONBAR2BUTTON", "MULTIACTIONBAR1BUTTON",
}

local NOME_MOD = { SHIFT = "Shift", CTRL = "Ctrl", ALT = "Alt", META = "Meta" }

local function encurtarTecla(tecla)
  local mods = {}
  while true do
    local m, resto = string.match(tecla, "^(%u+)%-(.+)$")
    if m and NOME_MOD[m] then
      mods[#mods + 1] = NOME_MOD[m]
      tecla = resto
    else
      break
    end
  end
  local base
  local botao = string.match(tecla, "^BUTTON(%d+)$")
  local num = string.match(tecla, "^NUMPAD(%d)$")
  if botao then base = "Mouse " .. botao
  elseif tecla == "MOUSEWHEELUP" then base = "Wheel up"
  elseif tecla == "MOUSEWHEELDOWN" then base = "Wheel down"
  elseif num then base = "Num " .. num
  elseif #tecla > 1 and not string.match(tecla, "^F%d+$") then
    base = string.sub(tecla, 1, 1) .. string.lower(string.sub(tecla, 2)) -- SPACE vira Space; F1 fica F1
  else
    base = tecla
  end
  mods[#mods + 1] = base
  return table.concat(mods, "+")
end

function ns.teclaDe(nome)
  if nome == nil or not (GetActionInfo and GetBindingKey) then return nil end
  local alvoTexto = type(nome) == "string" and string.lower(nome) or nil
  local alvoId = type(nome) == "number" and nome or nil
  for slot = 1, 72 do
    local tipo, id = GetActionInfo(slot)
    local casou = false
    if tipo == "macro" then
      local texto = GetActionText and GetActionText(slot)
      casou = alvoTexto ~= nil and type(texto) == "string" and string.lower(texto) == alvoTexto
    elseif tipo == "spell" then
      if alvoId then
        casou = (id == alvoId)
      elseif alvoTexto then
        local n = ns.nomeMagia(id)
        casou = type(n) == "string" and string.lower(n) == alvoTexto
      end
    end
    if casou then
      local bloco = math.floor((slot - 1) / 12) + 1
      local cmd = PREFIXOS_SLOT[bloco] .. (((slot - 1) % 12) + 1)
      local tecla = GetBindingKey(cmd)
      if tecla then return encurtarTecla(tecla) end
      -- sem tecla neste slot: segue procurando, a mesma macro pode estar em outro com tecla
    end
  end
  return nil
end
