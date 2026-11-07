-- GuiaForever: Pet: provedor do painel, macro feed_Pet e treinador de pet (tarefa A7; contrato em ARQUITETURA.md, secao 6).
-- Nenhum outro arquivo depende deste existir (regra 3). Dados lidos com checagem de nil:
-- GuiaForeverPet (Dados.lua) e petTreino (Dicas.lua). Quadros da Blizzard so por hook (regra 6).
-- O guia marca e o dono clica: nada de BuyTrainerService nem de magia pelo codigo (regra 7).

local _, ns = ...

local ID_FEED = 6991
local ID_CALL = 883
local NIVEL_MIN = 10
local NOME_MACRO = "feed_Pet"

-- Utilidades ------------------------------------------------------------------

local function emCombate()
  return InCombatLockdown and InCombatLockdown() and true or false
end

-- Lua 5.1: xpcall nao repassa argumentos, por isso o fechamento (regra 10).
local function seguro(fn, ...)
  if type(fn) ~= "function" then return false end
  local n = select("#", ...)
  local args = { ... }
  return xpcall(function() return fn(unpack(args, 1, n)) end, geterrorhandler())
end

local function estadoPet()
  return (ns.estado and ns.estado.pet) or {}
end

local function classeAtiva()
  return ns.estado and ns.estado.classe == "HUNTER"
end

local function dadosPet()
  local classe = (ns.estado and ns.estado.classe) or "HUNTER"
  local t = GuiaForeverPet and GuiaForeverPet[classe]
  if type(t) == "table" then return t end
  return {}
end

local function planoTreino()
  local classe = (ns.estado and ns.estado.classe) or "HUNTER"
  local d = GuiaForeverDicas and GuiaForeverDicas[classe]
  local t = d and d.petTreino
  if type(t) == "table" then return t end
  return {}
end

local function idMagia(chave, padrao)
  local m = dadosPet().magias
  local v = type(m) == "table" and m[chave]
  if type(v) == "number" then return v end
  return padrao
end

local function nomeDoPet()
  return estadoPet().nome or "Pet"
end

local function aparar(s)
  return (tostring(s or ""):gsub("%s+$", ""))
end

local function atualizarPainelAgora()
  if ns.agora and ns.agora.atualizar then ns.agora.atualizar() end
end

local function nomeEmMinuscula(s)
  return type(s) == "string" and string.lower(s) or ""
end

-- Dieta e vendedores ---------------------------------------------------------------

local PALAVRAS_DIETA = {
  meat = { "meat", "butcher" },
  fish = { "fish" },
  bread = { "baker", "bread" },
  fruit = { "fruit" },
  fungus = { "mushroom" },
  cheese = { "cheese" },
}

local function listaDieta()
  local r = {}
  local d = estadoPet().dieta
  if type(d) == "table" then
    for _, t in ipairs(d) do
      if type(t) == "string" then r[#r + 1] = t end
    end
  end
  return r
end

local function textoDieta()
  local d = listaDieta()
  if #d == 0 then return "food" end
  return table.concat(d, " or ")
end

local function ladoDoJogador()
  local f = ns.estado and ns.estado.faccao
  if f == "Alliance" then return "A" end
  if f == "Horde" then return "H" end
  return nil
end

local function ladoOk(lado)
  if lado == "Alliance" then lado = "A" elseif lado == "Horde" then lado = "H" end
  if type(lado) ~= "string" or lado == "" then return true end
  local meu = ladoDoJogador()
  if not meu then return true end
  return string.find(lado, meu, 1, true) ~= nil
end

-- Candidatos do Naowh (TownNPCs[uiMapID] = lista de { x, y, categoria, nome, titulo, classe, lado }).
local function candidatosNaowh(filtro)
  local out = {}
  seguro(function()
    local nw = _G.NaowhForever
    local tab = type(nw) == "table" and nw.TownNPCs
    if type(tab) ~= "table" then return end
    for mapa, lista in pairs(tab) do
      if type(mapa) == "number" and type(lista) == "table" then
        for _, e in ipairs(lista) do
          if type(e) == "table" and type(e[1]) == "number" and type(e[2]) == "number"
             and ladoOk(e[7]) and filtro(e) then
            out[#out + 1] = { mapa = mapa, x = e[1] / 100, y = e[2] / 100, npc = e[4], titulo = e[5], fonte = "Naowh" }
          end
        end
      end
    end
  end)
  return out
end

local function tiposDaEntrada(e)
  local v = e.dieta or e.tipo or e.tipos
  if type(v) == "string" then return { v } end
  if type(v) == "table" then return v end
  return nil
end

local function dietaCasa(tipos)
  if not tipos then return true end -- entrada sem marca de dieta serve para qualquer pet
  local d = listaDieta()
  if #d == 0 then return true end
  for _, a in ipairs(tipos) do
    for _, b in ipairs(d) do
      if nomeEmMinuscula(a) == nomeEmMinuscula(b) then return true end
    end
  end
  return false
end

local function candidatosDados(lista, comFiltroDieta)
  local out = {}
  if type(lista) ~= "table" then return out end
  for _, e in ipairs(lista) do
    if type(e) == "table" and type(e.mapa) == "number" and type(e.x) == "number" and type(e.y) == "number"
       and ladoOk(e.lado or e.faccao) and (not comFiltroDieta or dietaCasa(tiposDaEntrada(e))) then
      out[#out + 1] = { mapa = e.mapa, x = e.x, y = e.y, npc = e.npc, titulo = e.titulo, fonte = e.fonte }
    end
  end
  return out
end

local function candidatosTreinador()
  local c = candidatosNaowh(function(e) return e[5] == "Pet Trainer" end)
  if #c > 0 then return c end
  return candidatosDados(dadosPet().treinadores, false)
end

local function tituloCasaDieta(titulo)
  local t = nomeEmMinuscula(titulo)
  if t == "" then return false end
  local d = listaDieta()
  if #d == 0 then return true end
  for _, tipo in ipairs(d) do
    local chave = nomeEmMinuscula(tipo)
    local palavras = PALAVRAS_DIETA[chave] or { chave }
    for _, p in ipairs(palavras) do
      if string.find(t, p, 1, true) then return true end
    end
  end
  return false
end

local function candidatosVendedor()
  local c = candidatosNaowh(function(e)
    return (e[3] == "food" or e[3] == "vendor") and tituloCasaDieta(e[5])
  end)
  if #c > 0 then return c end
  local com = dadosPet().comida
  return candidatosDados(type(com) == "table" and com.vendedores or nil, true)
end

-- O mais perto pelo ns.distancia; sem distancia (outro continente), o do mapa atual, ou o primeiro.
local function maisPerto(lista)
  local melhor, dMelhor = nil, nil
  for _, c in ipairs(lista) do
    local d = ns.distancia and ns.distancia(c.mapa, c.x, c.y)
    if d and (dMelhor == nil or d < dMelhor) then melhor, dMelhor = c, d end
  end
  if melhor then return melhor end
  for _, c in ipairs(lista) do
    if ns.estado and c.mapa == ns.estado.mapa then return c end
  end
  return lista[1]
end

local function setaPara(lista, rotulo)
  local c = maisPerto(lista)
  if not c then
    if ns.msg then ns.msg("no " .. rotulo .. " in the guide data yet.") end
    return
  end
  local titulo = rotulo .. (c.npc and (": " .. c.npc) or "")
  if ns.seta and ns.seta(c.mapa, c.x, c.y, titulo) then
    if ns.msg then ns.msg("arrow set to " .. titulo .. ".") end
  end
end

-- Comida na bolsa -----------------------------------------------------------------------------

local bemAlimentado = {} -- itemID -> true se o tooltip tem "Well Fed"
local comidaCache = nil
local comidaSuja = true

local function temWellFed(id)
  local v = bemAlimentado[id]
  if v ~= nil then return v end
  if emCombate() then return false end -- sem cache: o tooltip nao e lido em combate
  if not (C_TooltipInfo and C_TooltipInfo.GetItemByID) then return false end
  local ok, dado = pcall(C_TooltipInfo.GetItemByID, id)
  if not ok or type(dado) ~= "table" or type(dado.lines) ~= "table" then return false end
  local achou = false
  for _, l in ipairs(dado.lines) do
    local t = type(l) == "table" and l.leftText
    if type(t) == "string" and not (issecretvalue and issecretvalue(t)) and string.find(t, "Well Fed", 1, true) then
      achou = true
      break
    end
  end
  bemAlimentado[id] = achou
  return achou
end

local function reservado(id, nome)
  local com = dadosPet().comida
  local lista = type(com) == "table" and com.reservados
  if type(lista) ~= "table" then return false end
  for _, r in ipairs(lista) do
    if r == id or (type(r) == "string" and nomeEmMinuscula(r) == nomeEmMinuscula(nome)) then return true end
  end
  return false
end

local function nivelDoPet()
  return estadoPet().nivel or (ns.estado and ns.estado.nivel) or 1
end

local function nivelDoItem(id)
  if not (C_Item and C_Item.GetItemInfo) then return 0 end
  local ok, _, _, _, nivel = pcall(C_Item.GetItemInfo, id)
  if ok and type(nivel) == "number" then return nivel end
  return 0 -- item ainda fora do cache do cliente
end

local function varrerComida()
  local nivelPet = nivelDoPet()
  local res = { total = 0, melhor = nil, nivelPet = nivelPet }
  if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo
          and C_PetInfo and C_PetInfo.CanPetEatItem) then
    return res
  end
  local porId = {}
  for bolsa = 0, 5 do
    local n = C_Container.GetContainerNumSlots(bolsa) or 0
    for slot = 1, n do
      local info = C_Container.GetContainerItemInfo(bolsa, slot)
      if type(info) == "table" and type(info.itemID) == "number" then
        local e = porId[info.itemID]
        if e then
          e.qtd = e.qtd + (tonumber(info.stackCount) or 1)
        else
          local ok, come = pcall(C_PetInfo.CanPetEatItem, info.itemID)
          porId[info.itemID] = {
            id = info.itemID, nome = info.itemName, icone = info.iconFileID,
            qtd = tonumber(info.stackCount) or 1, come = ok and come and true or false,
          }
        end
      end
    end
  end
  for id, e in pairs(porId) do
    if e.come and e.nome and not reservado(id, e.nome) and not temWellFed(id) then
      e.nivelItem = nivelDoItem(id)
      if e.nivelItem <= nivelPet then
        res.total = res.total + e.qtd
        local m = res.melhor
        if not m or e.nivelItem > m.nivelItem or (e.nivelItem == m.nivelItem and e.qtd > m.qtd) then
          res.melhor = e
        end
      end
    end
  end
  return res
end

local function comidaAtual()
  if comidaSuja or not comidaCache or comidaCache.nivelPet ~= nivelDoPet() then
    local ok, r = pcall(varrerComida)
    if ok then
      comidaCache = r
      comidaSuja = false
    else
      comidaCache = comidaCache or { total = 0, melhor = nil, nivelPet = nivelDoPet() }
      if ns.log then ns.log("pet: varredura da bolsa: " .. tostring(r)) end
    end
  end
  return comidaCache
end

-- Macro gerenciada ---------------------------------------------------------------------------

local function maxMacrosPersonagem()
  if Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_CHARACTER_MACROS then
    return Constants.MacroConsts.MAX_CHARACTER_MACROS
  end
  return 18
end

-- fora-de-combate (so macroGerenciada chama, depois da guarda de combate)
local function criarComIcone(nome, icone, corpo)
  for _, ic in ipairs({ icone or false, "INV_MISC_QUESTIONMARK", 134400 }) do
    if ic then
      local ok, idx = pcall(CreateMacro, nome, ic, corpo, true)
      if ok and type(idx) == "number" and idx > 0 then return idx end
    end
  end
  return nil
end

-- Cria ou atualiza uma macro do personagem sem pisar na edicao do dono. Devolve true se a macro ficou com o corpo pedido.
function ns.macroGerenciada(nome, icone, corpo)
  if emCombate() then return false end
  if type(nome) ~= "string" or type(corpo) ~= "string" then return false end
  if not (CreateMacro and EditMacro and GetMacroIndexByName and GetNumMacros and GetMacroInfo) then return false end
  local chave = ns.chavePersonagem and ns.chavePersonagem()
  if not chave then return false end
  GuiaForeverDB = GuiaForeverDB or {}
  GuiaForeverDB.macros = GuiaForeverDB.macros or {}
  local reg = GuiaForeverDB.macros[chave]
  if type(reg) ~= "table" then reg = {}; GuiaForeverDB.macros[chave] = reg end
  reg.criadas = reg.criadas or {}
  reg.gerenciadas = reg.gerenciadas or {}

  local idx = GetMacroIndexByName(nome) or 0
  if idx <= 0 then
    if reg.desfeito then return false end -- o dono desfez as macros: so o /guia macros as recria
    local _, nPersonagem = GetNumMacros()
    if (tonumber(nPersonagem) or 0) >= maxMacrosPersonagem() then
      if ns.log then ns.log("macro " .. nome .. ": sem vaga nas macros do personagem") end
      return false
    end
    if not criarComIcone(nome, icone, corpo) then return false end
    reg.criadas[nome] = corpo
    reg.gerenciadas[nome] = corpo
    return true
  end

  local _, _, atual = GetMacroInfo(idx)
  local ultimo = reg.gerenciadas[nome]
  if ultimo == nil or aparar(atual) ~= aparar(ultimo) then
    if ns.log then ns.log("macro " .. nome .. ": editada pelo dono, deixada como esta") end
    return false
  end
  if aparar(corpo) == aparar(atual) then return true end
  local ok = pcall(EditMacro, idx, nome, nil, corpo)
  if not ok then return false end
  reg.gerenciadas[nome] = corpo
  if reg.criadas[nome] ~= nil then reg.criadas[nome] = corpo end -- o /guia macros undo compara com este corpo
  return true
end

local function corpoFeed(comida)
  local feed = (ns.nomeMagia and ns.nomeMagia(idMagia("feed", ID_FEED))) or "Feed Pet"
  local linhas = {
    "#showtooltip " .. feed,
    "/stopmacro [nopet][@pet,dead][combat]",
    "/cast " .. feed,
  }
  if comida and comida.nome then linhas[#linhas + 1] = "/use " .. comida.nome end
  return table.concat(linhas, "\n")
end

-- fora-de-combate (chamada so por ns.foraDeCombate; ns.macroGerenciada abre com a guarda)
local function refazerMacroFeed()
  if emCombate() then return end
  if not classeAtiva() then return end
  local feedId = idMagia("feed", ID_FEED)
  if not (ns.conhece and ns.conhece(feedId)) then return end
  local c = comidaAtual()
  local corpo
  if c.melhor then
    corpo = corpoFeed(c.melhor)
  else
    -- sem comida comestivel: a macro que existe fica com o ultimo corpo; se nao existe, nasce sem a linha /use
    if (GetMacroIndexByName and GetMacroIndexByName(NOME_MACRO) or 0) > 0 then return end
    corpo = corpoFeed(nil)
  end
  ns.macroGerenciada(NOME_MACRO, (ns.iconeMagia and ns.iconeMagia(feedId)) or 134400, corpo)
end

local function pedirMacroFeed()
  ns.agendar("pet:macro", 1.0, function()
    ns.foraDeCombate("pet:macro", refazerMacroFeed)
  end)
end

ns.ao("BAG_UPDATE_DELAYED", function()
  comidaSuja = true
  pedirMacroFeed()
end)
ns.ao("UNIT_PET", function(_, unidade)
  if unidade and unidade ~= "player" then return end
  comidaSuja = true
  pedirMacroFeed()
end)
-- aprender o Feed Pet (ou logar) tambem refaz: sem isto a macro so nasceria na proxima troca de bolsa
ns.ao("SPELLS_CHANGED", function()
  comidaSuja = true
  pedirMacroFeed()
end)
ns.ao("PLAYER_LOGIN", function() pedirMacroFeed() end)

-- Provedor do painel Agora ---------------------------------------------------------------------

local rastro = { semPetDesde = nil, felic = nil, felicDesde = nil }

local function observar(agora)
  local p = estadoPet()
  local ausente = (not p.existe) or p.morto
  local impedido = (IsMounted and IsMounted()) or (UnitOnTaxi and UnitOnTaxi("player"))
                   or (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))
  if ausente and not impedido then
    rastro.semPetDesde = rastro.semPetDesde or agora
  else
    rastro.semPetDesde = nil
  end
  local f = (p.existe and not p.morto) and p.felicidade or nil
  if f ~= rastro.felic then
    rastro.felic = f
    rastro.felicDesde = agora
  end
end

local function reavaliarEm(chave, segundos)
  ns.agendar("pet:espera:" .. chave, segundos + 0.3, atualizarPainelAgora)
end

local function botaoTecla(nomeMacro, texto)
  local tecla = ns.teclaDe and ns.teclaDe(nomeMacro)
  if not tecla then return nil end
  return { rotulo = tecla, acao = function()
    if ns.msg then ns.msg(texto .. " (" .. tecla .. ")") end
  end }
end

local function botaoSeta(listaFn, rotulo)
  return { rotulo = "Arrow", acao = function() seguro(function() setaPara(listaFn(), rotulo) end) end }
end

local function textoFelicidade(f)
  if f == 1 then return "Unhappy" end
  return "Content"
end

local function autocastDoGrowl()
  if not GetPetActionInfo then return nil end
  local alvo = (ns.nomeMagia and ns.nomeMagia(idMagia("growl", 0))) or "Growl"
  for i = 1, 10 do
    local nome, _, ehToken, _, permitido, ligado = GetPetActionInfo(i)
    if type(nome) == "string" then
      if ehToken and type(_G[nome]) == "string" then nome = _G[nome] end
      if nome == alvo then
        if not permitido then return nil end
        return ligado and true or false
      end
    end
  end
  return nil
end

local function pontosLivres()
  local p = estadoPet()
  if type(p.pontosTotal) == "number" and type(p.pontosUsados) == "number" then
    return math.max(p.pontosTotal - p.pontosUsados, 0)
  end
  return nil
end

local function treinosPendentes()
  local out = {}
  local nivel = (ns.estado and ns.estado.nivel) or 1
  for _, e in ipairs(planoTreino()) do
    if type(e) == "table" and type(e.habilidade) == "string" and (tonumber(e.de) or 0) <= nivel
       and (not ns.relevante or ns.relevante(e, { aba = "pet" })) and not ns.petConhece(e.habilidade) then
      out[#out + 1] = e
    end
  end
  return out
end

local function itensDoPet()
  local itens = {}
  if not classeAtiva() then return itens end
  local e = ns.estado
  if (e.nivel or 1) < NIVEL_MIN then return itens end
  if emCombate() then return itens end

  local agora = GetTime()
  observar(agora)
  local p = estadoPet()
  local nome = nomeDoPet()
  local feedId = idMagia("feed", ID_FEED)
  local feedConhecido = ns.conhece(feedId)
  local iconeFeed = ns.iconeMagia and ns.iconeMagia(feedId)
  local f = rastro.felic

  -- 10: pet ausente ou morto ha 10 s
  if rastro.semPetDesde and ns.conhece(idMagia("call", ID_CALL)) then
    local falta = 10 - (agora - rastro.semPetDesde)
    if falta <= 0 then
      itens[#itens + 1] = {
        chave = "pet:ausente", prio = 10, cor = "vermelho",
        icone = ns.iconeMagia and ns.iconeMagia(idMagia("call", ID_CALL)),
        texto = p.morto and (nome .. " is dead: revive it") or "Pet is not out: call it",
        dica = { "The pet has been away for 10 seconds or more." },
        fonte = "GuiaForever", aba = "pet",
        botao = botaoTecla("pet_AllInOne", "Press your pet key"),
      }
    else
      reavaliarEm("ausente", falta)
    end
  end

  if p.existe and not p.morto and f then
    local comida = comidaAtual()
    if f < 3 and not feedConhecido then
      -- 20: sem Feed Pet
      local dica = { "Feed Pet is taught by a level-10 hunter quest (Naowh data)." }
      if e.raca == "NightElf" then
        dica[#dica + 1] = "Your route turns in Training the Beast to Jocaste, Darnassus (RestedXP)."
      end
      itens[#itens + 1] = {
        chave = "pet:semfeed", prio = 20, cor = (f == 1) and "vermelho" or "amarelo",
        icone = iconeFeed, texto = nome .. " is " .. textoFelicidade(f) .. ": no Feed Pet yet",
        dica = dica, fonte = "Naowh", aba = "pet",
        botao = { rotulo = "Why", acao = function()
          if ns.msg then
            for _, linha in ipairs(dica) do ns.msg(linha) end
          end
        end },
      }
    elseif f < 3 and feedConhecido then
      if comida.total <= 0 then
        -- 20: sem comida
        itens[#itens + 1] = {
          chave = "pet:semcomida", prio = 20, cor = (f == 1) and "vermelho" or "laranja",
          icone = iconeFeed, texto = nome .. " is " .. textoFelicidade(f) .. ": buy " .. textoDieta(),
          dica = { "No food in your bags that " .. nome .. " can eat.", "Diet (from the game): " .. textoDieta() .. "." },
          fonte = "GuiaForever", aba = "pet",
          botao = botaoSeta(candidatosVendedor, "Food vendor"),
        }
      elseif f == 1 then
        -- 20: infeliz com comida
        itens[#itens + 1] = {
          chave = "pet:infeliz", prio = 20, cor = "vermelho",
          icone = iconeFeed, texto = nome .. " is Unhappy: feed it now",
          dica = { "Use the feed_Pet macro: it feeds the best food in your bags." },
          fonte = "GuiaForever", aba = "pet",
          botao = botaoTecla(NOME_MACRO, "Feed " .. nome),
        }
      elseif rastro.felicDesde and (agora - rastro.felicDesde) >= 5 then
        -- 20: contente por 5 s
        itens[#itens + 1] = {
          chave = "pet:contente", prio = 20, cor = "amarelo",
          icone = iconeFeed, texto = nome .. " is Content: feed for Happy",
          dica = { "A fed pet does more damage." },
          fonte = "GuiaForever", aba = "pet",
          botao = botaoTecla(NOME_MACRO, "Feed " .. nome),
        }
      elseif rastro.felicDesde then
        reavaliarEm("contente", 5 - (agora - rastro.felicDesde))
      end
    end
  end

  -- 30: missao de pet pronta para entregar
  local missoes = dadosPet().missoes
  if type(missoes) == "table" then
    for _, m in ipairs(missoes) do
      if type(m) == "table" and type(m.id) == "number" and (not m.raca or m.raca == e.raca)
         and ns.missao(m.id) == "pronta" then
        itens[#itens + 1] = {
          chave = "pet:missao:" .. m.id, prio = 30, cor = "amarelo",
          icone = iconeFeed, texto = "Turn in " .. tostring(m.nome or "the pet quest") .. (m.npc and (": " .. m.npc) or ""),
          dica = { tostring(m.nome or "Pet quest") .. " is complete." },
          fonte = m.fonte or "GuiaForever", aba = "pet",
          botao = { rotulo = "Arrow", acao = function()
            if type(m.mapa) == "number" and type(m.x) == "number" and type(m.y) == "number" and ns.seta then
              ns.seta(m.mapa, m.x, m.y, m.npc or m.nome)
            end
          end },
        }
      end
    end
  end

  -- 40: treino de pet
  if p.existe and not p.morto then
    local pend = treinosPendentes()
    if #pend > 0 then
      local nomes = {}
      for i = 1, math.min(#pend, 2) do nomes[#nomes + 1] = pend[i].habilidade end
      local dica = {}
      for _, t in ipairs(pend) do
        dica[#dica + 1] = t.habilidade .. (t.texto and (": " .. t.texto) or "")
      end
      local livres = pontosLivres()
      if livres then dica[#dica + 1] = "Training points: " .. livres .. " free." end
      itens[#itens + 1] = {
        chave = "pet:treino", prio = 40, cor = "amarelo",
        icone = iconeFeed,
        texto = "Train " .. nome .. ": " .. table.concat(nomes, ", ") .. ((#pend > 2) and (" +" .. (#pend - 2)) or ""),
        dica = dica, fonte = pend[1].fonte or "GuiaForever", aba = "pet",
        botao = botaoSeta(candidatosTreinador, "Pet Trainer"),
      }
    end

    -- 90: autocast do Growl (so aviso)
    local ligado = autocastDoGrowl()
    local nomeGrowl = (ns.nomeMagia and ns.nomeMagia(idMagia("growl", 0))) or "Growl"
    if ligado ~= nil then
      if e.emGrupo and ligado then
        itens[#itens + 1] = {
          chave = "pet:autocast", prio = 90, cor = "azul", icone = iconeFeed,
          texto = nomeGrowl .. " autocast is on in a group",
          dica = { "Right-click " .. nomeGrowl .. " on the pet bar to turn it off." },
          fonte = "LudiDeo", aba = "pet",
        }
      elseif (not e.emGrupo) and not ligado then
        itens[#itens + 1] = {
          chave = "pet:autocast", prio = 90, cor = "azul", icone = iconeFeed,
          texto = nomeGrowl .. " autocast is off while solo",
          dica = { "Right-click " .. nomeGrowl .. " on the pet bar to turn it on." },
          fonte = "LudiDeo", aba = "pet",
        }
      end
    end
  end

  -- 80: comida acabando
  if p.existe and feedConhecido then
    local comida = comidaAtual()
    local jaAvisou = (f == 1 or f == 2) and comida.total <= 0
    if comida.total < 5 and not jaAvisou then
      itens[#itens + 1] = {
        chave = "pet:comida", prio = 80, cor = "laranja", icone = iconeFeed,
        texto = (comida.total <= 0) and ("No pet food left: buy " .. textoDieta())
                or ("Pet food is low: " .. comida.total .. " left"),
        dica = { "Diet (from the game): " .. textoDieta() .. "." },
        fonte = "GuiaForever", aba = "pet",
        botao = botaoSeta(candidatosVendedor, "Food vendor"),
      }
    end
  end

  return itens
end

if ns.agora and ns.agora.provedor then
  ns.agora.provedor({
    id = "pet",
    eventos = {
      "UNIT_PET", "UNIT_HAPPINESS", "PET_UI_UPDATE", "PET_BAR_UPDATE", "UNIT_PET_TRAINING_POINTS",
      "BAG_UPDATE_DELAYED", "SPELLS_CHANGED", "PLAYER_LEVEL_UP", "QUEST_LOG_UPDATE",
      "GROUP_ROSTER_UPDATE", "PLAYER_MOUNT_DISPLAY_CHANGED", "PLAYER_ALIVE", "PLAYER_UNGHOST",
    },
    itens = itensDoPet,
  })
end

-- Treinador de pet ----------------------------------------------------------------------------

local selos = setmetatable({}, { __mode = "k" }) -- botao da Blizzard -> selo nosso
local painel = nil
local treinadorInstalado = false

local function modoPet()
  if not (C_Trainer and C_Trainer.GetTrainerType and Enum and Enum.TrainerType) then return false end
  local ok, t = pcall(C_Trainer.GetTrainerType)
  return ok and t == Enum.TrainerType.Pet
end

local function planoRelevante()
  local out = {}
  for _, e in ipairs(planoTreino()) do
    if type(e) == "table" and type(e.habilidade) == "string" and (not ns.relevante or ns.relevante(e, { aba = "pet" })) then
      out[#out + 1] = e
    end
  end
  return out
end

local function chaveHabilidade(nome)
  local s = nomeEmMinuscula(nome)
  s = s:gsub("%s*%b()", ""):gsub("%s+rank%s+%d+$", ""):gsub("%s+%d+$", "")
  return s
end

-- skillIndex -> true para a proxima graduacao nao aprendida de cada habilidade do plano
local function graduacoesMarcadas()
  local marcados = {}
  if not (GetNumTrainerServices and GetTrainerServiceInfo) then return marcados end
  local nivel = (ns.estado and ns.estado.nivel) or 1
  local plano = {}
  for _, e in ipairs(planoRelevante()) do
    if (tonumber(e.de) or 0) <= nivel then plano[chaveHabilidade(e.habilidade)] = true end
  end
  if next(plano) == nil then return marcados end
  local melhor = {}
  local n = GetNumTrainerServices() or 0
  for i = 1, n do
    local nome, tipo, _, req = GetTrainerServiceInfo(i)
    if type(nome) == "string" and tipo ~= "used" then
      local chave = chaveHabilidade(nome)
      if plano[chave] then
        req = tonumber(req) or 0
        local m = melhor[chave]
        if not m or req < m.req or (req == m.req and i < m.idx) then melhor[chave] = { idx = i, req = req } end
      end
    end
  end
  for _, m in pairs(melhor) do marcados[m.idx] = true end
  return marcados
end

local function criarSelo(botao)
  local selo = CreateFrame("Frame", nil, botao)
  selo:SetFrameLevel((botao:GetFrameLevel() or 1) + 5)
  selo:SetSize(30, 12)
  local ancora = botao.icon or botao
  selo:SetPoint("BOTTOM", ancora, "BOTTOM", 0, 0)
  local fundo = selo:CreateTexture(nil, "BACKGROUND")
  fundo:SetAllPoints()
  fundo:SetColorTexture(0.2, 1, 0.6, 0.9)
  local txt = selo:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  txt:SetPoint("CENTER")
  txt:SetText("PLAN")
  txt:SetTextColor(0, 0, 0, 1)
  selos[botao] = selo
  return selo
end

local function criarPainel()
  if painel then return painel end
  local f = CreateFrame("Frame", "GuiaForeverPainelPet", UIParent, "BackdropTemplate")
  f:SetSize(270, 120)
  f:SetFrameStrata("HIGH")
  f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
  f:SetBackdropColor(0.06, 0.06, 0.06, 0.9)
  f:SetBackdropBorderColor(0, 0, 0, 1)
  f.titulo = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.titulo:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
  f.titulo:SetWidth(250)
  f.titulo:SetJustifyH("LEFT")
  f.corpo = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.corpo:SetPoint("TOPLEFT", f.titulo, "BOTTOMLEFT", 0, -6)
  f.corpo:SetWidth(250)
  f.corpo:SetJustifyH("LEFT")
  f.cinza = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  f.cinza:SetPoint("TOPLEFT", f.corpo, "BOTTOMLEFT", 0, -6)
  f.cinza:SetWidth(250)
  f.cinza:SetJustifyH("LEFT")
  f:Hide()
  painel = f
  return f
end

local ICONE_OK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14|t "
local ICONE_FALTA = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14|t "

local function atualizarPainelTreinador()
  local pronto = classeAtiva() and ClassTrainerFrame and ClassTrainerFrame.IsShown and ClassTrainerFrame:IsShown() and modoPet()
  if not pronto then
    if painel then painel:Hide() end
    return
  end
  local f = criarPainel()
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPRIGHT", 8, 0)
  local nivel = (ns.estado and ns.estado.nivel) or 1
  local plano = planoRelevante()
  local fontes, vistas = {}, {}
  for _, e in ipairs(plano) do
    if type(e.fonte) == "string" and not vistas[e.fonte] and #fontes < 2 then
      vistas[e.fonte] = true
      fontes[#fontes + 1] = e.fonte
    end
  end
  f.titulo:SetText("Pet plan (" .. (#fontes > 0 and table.concat(fontes, ", ") or "guide") .. ", level " .. nivel .. ")")
  local livres = pontosLivres()
  local linhas = { "Training points: " .. (livres and (livres .. " free") or "unknown") }
  if #plano == 0 then
    linhas[#linhas + 1] = "No pet plan in the guide data yet."
  end
  for _, e in ipairs(plano) do
    local sabe = ns.petConhece(e.habilidade)
    local marca = sabe and ICONE_OK or ICONE_FALTA
    local extra = ((tonumber(e.de) or 0) > nivel) and (" (level " .. e.de .. ")") or ""
    linhas[#linhas + 1] = marca .. e.habilidade .. extra
  end
  f.corpo:SetText(table.concat(linhas, "\n"))
  f.cinza:SetText("In groups: Growl off, Cower on (LudiDeo)")
  f:SetHeight(10 + f.titulo:GetStringHeight() + 6 + f.corpo:GetStringHeight() + 6 + f.cinza:GetStringHeight() + 10)
  f:Show()
end

local function aoIniciarBotao(botao, dados)
  if type(botao) ~= "table" then return end
  local d = type(dados) == "table" and (dados.data or dados) or nil
  local marcar = false
  if d and d.skillIndex and classeAtiva() and modoPet() then
    marcar = graduacoesMarcadas()[d.skillIndex] and true or false
  end
  local selo = selos[botao]
  if marcar then
    selo = selo or criarSelo(botao)
    selo:Show()
  elseif selo then
    selo:Hide()
  end
  ns.agendar("pet:painelTreinador", 0.05, atualizarPainelTreinador)
end

local function instalarTreinador()
  if treinadorInstalado then return end
  if type(ClassTrainerFrame_InitServiceButton) ~= "function" then return end
  treinadorInstalado = true
  hooksecurefunc("ClassTrainerFrame_InitServiceButton", function(botao, dados)
    seguro(aoIniciarBotao, botao, dados)
  end)
  if ClassTrainerFrame and ClassTrainerFrame.HookScript then
    ClassTrainerFrame:HookScript("OnShow", function() seguro(atualizarPainelTreinador) end)
    ClassTrainerFrame:HookScript("OnHide", function() if painel then painel:Hide() end end)
  end
end

ns.ao("ADDON_LOADED", function(_, nomeAddon)
  if nomeAddon == "Blizzard_TrainerUI" then instalarTreinador() end
end)
ns.ao("PLAYER_LOGIN", instalarTreinador)
ns.ao("TRAINER_SHOW", function() ns.agendar("pet:painelTreinador", 0.1, atualizarPainelTreinador) end)
ns.ao("TRAINER_UPDATE", function() ns.agendar("pet:painelTreinador", 0.1, atualizarPainelTreinador) end)
ns.ao("UNIT_PET_TRAINING_POINTS", function() ns.agendar("pet:painelTreinador", 0.1, atualizarPainelTreinador) end)
ns.ao("TRAINER_CLOSED", function() if painel then painel:Hide() end end)

-- O addon pode carregar com o Blizzard_TrainerUI ja na memoria (um /reload com a janela usada antes)
seguro(instalarTreinador)
