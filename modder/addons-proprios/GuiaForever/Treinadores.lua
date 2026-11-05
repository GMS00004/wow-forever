-- GuiaForever: treinadores de classe e de profissao.
-- 1. Liga no Questie os icones do treinador de classe e das profissoes conhecidas
--    (uma vez por conta; o Questie carrega antes por causa do OptionalDeps do .toc).
-- 2. Liga no minimapa do jogo o rastreamento de treinadores (uma vez por personagem).
-- 3. Seta do TomTom para o treinador mais perto, da faccao do personagem
--    (/guia treinador classe|<profissao> e os botoes da aba Treinos).
-- NPCs: API publica do QuestieDB (LibQuestieDB, contrato 4); zona para mapa: ZoneDB
-- do Questie. Seta: TomTom:AddWaypoint(mapa, x, y, opcoes) com x e y de 0 a 1.

local _, ns = ...

local CONTRATO = 4
local MARCA_TREINADOR = 16 -- npcFlags: trainer

-- Trechos do subName (cliente enUS) de cada treinador de profissao.
local RAIZES = {
  Leatherworking = { "Leatherwork" },
  Skinning = { "Skinn" },
  Herbalism = { "Herbalis" },
  Enchanting = { "Enchant" },
  Alchemy = { "Alchem" },
  Tailoring = { "Tailor" },
  Mining = { "Mining", "Miner" },
  Blacksmithing = { "Blacksmith" },
  Engineering = { "Engineer" },
  Cooking = { "Cook" },
  ["First Aid"] = { "First Aid" },
  Fishing = { "Fish" },
}
local NOMES = {}
for nome in pairs(RAIZES) do NOMES[string.lower(nome)] = nome end

local function registro()
  GuiaForeverDB.treinadores = GuiaForeverDB.treinadores or {}
  return GuiaForeverDB.treinadores
end

-- 1. Questie ------------------------------------------------------------
local function ligarQuestie()
  local t = registro()
  if t.questie then return end -- ja feito, ou desfeito pelo dono
  local p = Questie and Questie.db and Questie.db.profile
  if type(p) ~= "table" or type(p.townsfolkConfig) ~= "table" then return end
  t.questie = {
    classe = p.townsfolkConfig["Class Trainer"] and true or false,
    conhecidas = p.townsfolkKnownProfessions and true or false,
  }
  p.townsfolkConfig["Class Trainer"] = true
  p.townsfolkKnownProfessions = true
  t.avisarQuestie = true
end
table.insert(ns.aoCarregar, ligarQuestie)

-- 2. Rastreamento do minimapa ----------------------------------------------
local function filtrosAlvo()
  local F = Enum and Enum.MinimapTrackingFilter
  if not F then return nil end
  local alvos = {}
  if F.TrainerClass then alvos[F.TrainerClass] = true end
  if F.TrainerProfession then alvos[F.TrainerProfession] = true end
  if not next(alvos) then return nil end
  return alvos
end

local function ajustarRastreio(ligar, quais)
  local mudados = {}
  if not (C_Minimap and C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingFilter
      and C_Minimap.GetTrackingInfo and C_Minimap.SetTracking) then
    return mudados
  end
  for i = 1, C_Minimap.GetNumTrackingTypes() do
    local okF, f = pcall(C_Minimap.GetTrackingFilter, i)
    local fid = okF and f and f.filterID
    if fid and quais[fid] then
      local okI, info = pcall(C_Minimap.GetTrackingInfo, i)
      if okI and info and ((info.active and true or false) ~= ligar) then
        if pcall(C_Minimap.SetTracking, i, ligar) then mudados[#mudados + 1] = fid end
      end
    end
  end
  return mudados
end

local function aoEntrar()
  local t = registro()
  if t.avisarQuestie then
    ns.msg("Questie: icones do treinador de classe e das profissoes conhecidas ligados no mapa (desfazer: /guia treinadores desfazer).")
    t.avisarQuestie = nil
  end
  local chave = ns.chavePersonagem()
  if not chave or ns.emCombate() then return end
  t.rastreio = t.rastreio or {}
  if t.rastreio[chave] then return end
  local alvos = filtrosAlvo()
  if not alvos then return end
  local mudados = ajustarRastreio(true, alvos)
  t.rastreio[chave] = { ligados = mudados }
  if #mudados > 0 then ns.msg("minimapa: rastreamento de treinadores de classe e de profissao ligado.") end
end
table.insert(ns.aoEntrar, aoEntrar)

-- 3. Treinador mais perto ------------------------------------------------
local cache, uidAtual

local function montarCache()
  if cache then return cache end
  if not (LibQuestieDB and LibQuestieDB.Npc and LibQuestieDB.RequireContract) then
    return nil, "o QuestieDB nao esta carregado"
  end
  local ok, motivo = LibQuestieDB.RequireContract(CONTRATO)
  if not ok then return nil, tostring(motivo) end
  if not (Questie and Questie.API and Questie.API.isReady) then
    return nil, "o Questie ainda esta carregando; tente de novo em alguns segundos"
  end
  local ZoneDB = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("ZoneDB")
  if not (ZoneDB and ZoneDB.GetUiMapIdByAreaId) then
    return nil, "o mapa de zonas do Questie nao esta disponivel"
  end
  local band = bit and bit.band
  if not band then return nil, "biblioteca bit indisponivel" end
  local letra = (UnitFactionGroup("player") == "Horde") and "H" or "A"
  local Npc = LibQuestieDB.Npc
  local lista = {}
  for _, id in ipairs(Npc.GetAllIds()) do
    local flags = Npc.Get(id, "npcFlags")
    if type(flags) == "number" and band(flags, MARCA_TREINADOR) ~= 0 then
      local amigo = Npc.Get(id, "friendlyToFaction")
      local sub = Npc.Get(id, "subName")
      if type(amigo) == "string" and amigo:find(letra, 1, true) and type(sub) == "string" then
        local spawns = Npc.Get(id, "spawns")
        if type(spawns) == "table" then
          local nome = Npc.Get(id, "name") or ("NPC " .. id)
          for areaId, pontos in pairs(spawns) do
            local okM, mapa = pcall(ZoneDB.GetUiMapIdByAreaId, ZoneDB, areaId)
            if okM and mapa and type(pontos) == "table" then
              for _, pt in ipairs(pontos) do
                local x, y = pt[1], pt[2]
                if type(x) == "number" and type(y) == "number" and x >= 0 and y >= 0 then
                  lista[#lista + 1] = { nome = nome, sub = sub, mapa = mapa, x = x / 100, y = y / 100 }
                end
              end
            end
          end
        end
      end
    end
  end
  cache = lista
  return cache
end

local function casa(sub, alvo)
  if alvo.classe then return sub:find(alvo.classe, 1, true) ~= nil end
  for _, r in ipairs(alvo.raizes) do
    if sub:find(r, 1, true) then return true end
  end
  return false
end

local function posMundo(mapa, x, y)
  local cont, w = C_Map.GetWorldPosFromMapPos(mapa, CreateVector2D(x, y))
  return cont, w
end

local function posJogador()
  local mapa = C_Map.GetBestMapForUnit("player")
  if not mapa then return nil end
  local p = C_Map.GetPlayerMapPosition(mapa, "player")
  if not p then return nil end
  local px, py = p:GetXY()
  return posMundo(mapa, px, py)
end

local function listaProfissoes()
  local nomes = {}
  for nome in pairs(RAIZES) do nomes[#nomes + 1] = string.lower(nome) end
  table.sort(nomes)
  return table.concat(nomes, ", ")
end

function ns.setaTreinador(arg)
  if ns.emCombate() then ns.msg("treinador: em combate, tente de novo fora dele."); return end
  arg = string.lower(arg or "")
  local alvo, rotulo
  if arg == "" or arg == "classe" then
    local nomeClasse = UnitClass("player")
    alvo, rotulo = { classe = nomeClasse }, "treinador de " .. tostring(nomeClasse)
  else
    local prof = NOMES[arg]
    if not prof then
      ns.msg("treinador: nao conheco '" .. arg .. "'. Use classe ou uma destas: " .. listaProfissoes() .. ".")
      return
    end
    alvo, rotulo = { raizes = RAIZES[prof] }, "treinador de " .. prof
  end
  local lista, motivo = montarCache()
  if not lista then ns.msg("treinador: " .. tostring(motivo) .. "."); return end

  local temPos, cont, w = pcall(posJogador)
  if not temPos then cont, w = nil, nil end
  local melhor, melhorD, primeiro
  for _, t in ipairs(lista) do
    if casa(t.sub, alvo) then
      primeiro = primeiro or t
      if cont and w then
        local okT, c2, w2 = pcall(posMundo, t.mapa, t.x, t.y)
        if okT and c2 == cont and w2 then
          local ax, ay = w:GetXY()
          local bx, by = w2:GetXY()
          local d = (ax - bx) ^ 2 + (ay - by) ^ 2
          if not melhorD or d < melhorD then melhor, melhorD = t, d end
        end
      end
    end
  end
  local e = melhor or primeiro
  if not e then ns.msg("treinador: nenhum " .. rotulo .. " da sua faccao no banco do Questie."); return end

  local info = C_Map.GetMapInfo and C_Map.GetMapInfo(e.mapa)
  local zona = (info and info.name) or ("mapa " .. e.mapa)
  local onde = string.format("%s (%s), %s %.1f %.1f", e.nome, e.sub, zona, e.x * 100, e.y * 100)
  local aviso = melhor and "" or " (nao achei um no seu continente)"
  if TomTom and TomTom.AddWaypoint then
    if uidAtual and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, uidAtual) end
    local ok, uid = pcall(TomTom.AddWaypoint, TomTom, e.mapa, e.x, e.y, {
      title = e.nome .. " (" .. e.sub .. ")", from = "GuiaForever", persistent = false, crazy = true,
    })
    if ok then
      uidAtual = uid
      ns.msg("seta para " .. onde .. aviso)
      return
    end
  end
  ns.msg(onde .. aviso .. ". Sem TomTom: /way #" .. e.mapa .. string.format(" %.1f %.1f", e.x * 100, e.y * 100))
end

-- Aba Treinos --------------------------------------------------------------
function ns.blocosTreinos(b)
  local T, cab, B = ns.blocoTexto, ns.blocoCabecalho, ns.blocoBotao
  local nomeClasse = UnitClass("player")
  T(b, ns.COR .. "Treinadores" .. ns.FIM)
  T(b, "Cada botao poe a seta do TomTom no treinador mais perto, da sua faccao.")
  B(b, "Seta: treinador de " .. tostring(nomeClasse), function() ns.setaTreinador("classe") end)
  local planejadas = (GuiaForeverProfissoesPlanejadas and GuiaForeverProfissoesPlanejadas[ns.classe()]) or {}
  local lista, vistas = {}, {}
  for _, p in ipairs(planejadas) do
    if not vistas[p] then vistas[p] = true; lista[#lista + 1] = p end
  end
  for _, pr in ipairs(ns.minhasProfissoes()) do
    if RAIZES[pr.nome] and not vistas[pr.nome] then vistas[pr.nome] = true; lista[#lista + 1] = pr.nome end
  end
  for _, prof in ipairs(lista) do
    cab(b, prof)
    B(b, "Seta: treinador de " .. prof, function() ns.setaTreinador(prof) end)
    local tab = ns.tabelaProf(prof)
    if tab and tab.treino then
      for _, s in ipairs(tab.treino) do T(b, "  " .. s) end
    end
  end
  cab(b, "No mapa e no minimapa")
  T(b, "Questie: icones do treinador de classe e das profissoes que voce ja tem (botao direito no icone do Questie muda isso).")
  T(b, "Minimapa: rastreamento de treinadores de classe e de profissao (botao direito no minimapa).")
  T(b, "Ctrl+clique num icone do Questie tambem poe a seta do TomTom.")
  T(b, "|cff999999Desfazer: /guia treinadores desfazer|r")
end

-- Desfazer -----------------------------------------------------------------
function ns.desfazerTreinadores()
  if ns.emCombate() then ns.msg("treinadores: em combate, tente de novo fora dele."); return end
  local t = registro()
  local partes = {}
  if t.questie and not t.questie.desfeito then
    local p = Questie and Questie.db and Questie.db.profile
    if type(p) == "table" and type(p.townsfolkConfig) == "table" then
      p.townsfolkConfig["Class Trainer"] = t.questie.classe
      p.townsfolkKnownProfessions = t.questie.conhecidas
      t.questie = { desfeito = true }
      partes[#partes + 1] = "Questie devolvido (vale depois de /reload)"
    end
  end
  local chave = ns.chavePersonagem()
  local r = chave and t.rastreio and t.rastreio[chave]
  if r and r.ligados and #r.ligados > 0 then
    local quais = {}
    for _, fid in ipairs(r.ligados) do quais[fid] = true end
    ajustarRastreio(false, quais)
    t.rastreio[chave] = { ligados = {}, desfeito = true }
    partes[#partes + 1] = "rastreamento do minimapa desligado"
  end
  if uidAtual and TomTom and TomTom.RemoveWaypoint then
    pcall(TomTom.RemoveWaypoint, TomTom, uidAtual)
    uidAtual = nil
  end
  ns.msg(#partes > 0 and ("treinadores: " .. table.concat(partes, "; ") .. ".") or "treinadores: nada para desfazer.")
end
