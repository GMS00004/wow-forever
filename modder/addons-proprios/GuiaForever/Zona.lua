-- GuiaForever: aba Zone. Na zona onde o jogador esta, lista cada bicho esfolavel com a
-- pericia de Skinning que ele pede e ate onde da ponto; linha no tooltip dos bichos;
-- diario de calibracao (skinCores, skinLog) e bichos aprendidos (skinAprendidos).
-- Dados: SkinDB.lua (cmangos/classic-db, GPL-3.0); locais e niveis: QuestieDB (LibQuestieDB,
-- contrato 4) e ZoneDB do Questie. Nada roda em combate; se a API negar o dado, fica sem ele.

local _, ns = ...

local CONTRATO = 4
local MAX_DIARIO = 400

-- ESTIMATIVA: nenhuma fonte aberta da os numeros; e a regra dos nos de coleta, a confirmar
-- com o diario (skinCores e skinLog). Distancia acima da pericia minima em que a cor muda.
local FAIXAS = { laranja = 25, amarelo = 50, verde = 100 }

local COR_HEX = {
  laranja = "ff8000", amarelo = "ffff00", verde = "40c040", vermelho = "ff3030", cinza = "9d9d9d",
}
local ROTULO = {
  laranja = "ORANGE", amarelo = "YELLOW", verde = "GREEN", vermelho = "RED", cinza = "GREY",
}
local ORDEM = { laranja = 1, amarelo = 2, verde = 3, vermelho = 4, cinza = 5 }

-- Treinos: pericia pedida, onde vai, nivel do personagem (nivel: addon Naowh, inferencia).
local TREINOS = {
  { nome = "Journeyman", pede = 50, vai = 150, nivel = 10 },
  { nome = "Expert", pede = 125, vai = 225, nivel = 20 },
  { nome = "Artisan", pede = 200, vai = 300, nivel = 35 },
}

local function db()
  GuiaForeverDB = GuiaForeverDB or {}
  return GuiaForeverDB
end

-- Regra de pericia minima (wow.gg/professions/forever/skinning, 04/11/2026).
local function periciaMinima(nivel)
  if nivel <= 10 then return 1 end
  if nivel <= 20 then return (nivel - 10) * 10 end
  return nivel * 5
end
ns.periciaMinimaEsfolar = periciaMinima

local function corDe(pericia, minima)
  if pericia < minima then return "vermelho" end
  local d = pericia - minima
  if d < FAIXAS.laranja then return "laranja" end
  if d < FAIXAS.amarelo then return "amarelo" end
  if d < FAIXAS.verde then return "verde" end
  return "cinza"
end

local function colorir(cor, s)
  return "|cff" .. COR_HEX[cor] .. s .. "|r"
end

local function aprendidos()
  local d = db()
  d.skinAprendidos = d.skinAprendidos or {}
  return d.skinAprendidos
end

local function periciaSkinning()
  local ok, lista = pcall(ns.minhasProfissoes)
  if ok and type(lista) == "table" then
    for _, pr in ipairs(lista) do
      if pr.nome == "Skinning" then return pr.pericia, pr.maximo, true end
    end
  end
  return 0, nil, false
end

local function contar(t)
  local n = 0
  for _ in pairs(t or {}) do n = n + 1 end
  return n
end

-- Indice por mapa --------------------------------------------------------
local indice

local function prontoQuestie()
  if not (LibQuestieDB and LibQuestieDB.Npc and LibQuestieDB.RequireContract) then
    return nil, "QuestieDB is not loaded."
  end
  local ok, motivo = pcall(LibQuestieDB.RequireContract, CONTRATO)
  if not ok then return nil, tostring(motivo) end
  if not (Questie and Questie.API and Questie.API.isReady) then
    return nil, "Questie is still loading; try again in a few seconds."
  end
  local ZoneDB = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("ZoneDB")
  if not (ZoneDB and ZoneDB.GetUiMapIdByAreaId) then
    return nil, "Questie zone map is not available."
  end
  return ZoneDB
end

local function lerNpc(Npc, id, campo)
  local ok, v = pcall(Npc.Get, id, campo)
  if ok then return v end
  return nil
end

local function montarIndice()
  if indice then return indice end
  local ZoneDB, motivo = prontoQuestie()
  if not ZoneDB then return nil, motivo end
  local Npc = LibQuestieDB.Npc
  local letra = (UnitFactionGroup("player") == "Horde") and "H" or "A"
  local idx = {}
  local ids, vistos = {}, {}
  for id in pairs(GuiaForeverSkinDB or {}) do
    if not vistos[id] then vistos[id] = true; ids[#ids + 1] = id end
  end
  for id in pairs(aprendidos()) do
    id = tonumber(id)
    if id and not vistos[id] then vistos[id] = true; ids[#ids + 1] = id end
  end
  for _, id in ipairs(ids) do
    local base = GuiaForeverSkinDB and GuiaForeverSkinDB[id]
    local apr = aprendidos()[id] or aprendidos()[tostring(id)]
    local amigo = lerNpc(Npc, id, "friendlyToFaction")
    if not (type(amigo) == "string" and amigo:find(letra, 1, true)) then
      local spawns = lerNpc(Npc, id, "spawns")
      if type(spawns) == "table" then
        local nome = lerNpc(Npc, id, "name") or (base and base[1]) or (apr and apr.nome) or ("NPC " .. id)
        local mn = lerNpc(Npc, id, "minLevel")
        local mx = lerNpc(Npc, id, "maxLevel")
        if type(mn) ~= "number" then mn = (base and base[2]) or (apr and apr.nivel) end
        if type(mx) ~= "number" then mx = (base and base[3]) or (apr and apr.nivel) end
        if type(mn) == "number" and type(mx) == "number" and mx > 0 then
          if mn < 1 then mn = mx end
          local porMapa = {}
          for areaId, pontos in pairs(spawns) do
            local okM, mapa = pcall(ZoneDB.GetUiMapIdByAreaId, ZoneDB, areaId)
            if okM and mapa and type(pontos) == "table" then
              local lista = porMapa[mapa]
              if not lista then lista = {}; porMapa[mapa] = lista end
              for _, pt in ipairs(pontos) do
                local x, y = pt[1], pt[2]
                if type(x) == "number" and type(y) == "number" and x >= 0 and y >= 0 then
                  lista[#lista + 1] = { x / 100, y / 100 }
                end
              end
            end
          end
          for mapa, lista in pairs(porMapa) do
            if #lista > 0 then
              idx[mapa] = idx[mapa] or {}
              idx[mapa][#idx[mapa] + 1] = { id = id, nome = nome, min = mn, max = mx, pontos = lista }
            end
          end
        end
      end
    end
  end
  indice = idx
  return indice
end

local function mapaDaZona(idx)
  local ok, m = pcall(C_Map.GetBestMapForUnit, "player")
  if not ok or not m then return nil end
  local atual = m
  for _ = 0, 3 do
    if idx[atual] then return atual, m end
    local okI, info = pcall(C_Map.GetMapInfo, atual)
    local pai = okI and info and info.parentMapID
    if not pai or pai == 0 then break end
    atual = pai
  end
  return nil, m
end

local function nomeMapa(m)
  local ok, info = pcall(C_Map.GetMapInfo, m)
  return (ok and info and info.name) or ("map " .. tostring(m))
end

-- Seta do TomTom ----------------------------------------------------------
local uidAtual

local function setaBicho(e, mapa)
  if ns.emCombate() then ns.msg("zone: in combat, try again out of combat."); return end
  local px, py
  local ok, p = pcall(C_Map.GetPlayerMapPosition, mapa, "player")
  if ok and p then
    local okXY, x, y = pcall(p.GetXY, p)
    if okXY then px, py = x, y end
  end
  local melhor, melhorD
  for _, pt in ipairs(e.pontos) do
    if px and py then
      local d = (pt[1] - px) ^ 2 + (pt[2] - py) ^ 2
      if not melhorD or d < melhorD then melhor, melhorD = pt, d end
    else
      melhor = melhor or pt
    end
  end
  if not melhor then ns.msg("zone: no spawn point for " .. e.nome .. "."); return end
  local onde = string.format("%s, %s %.1f %.1f", e.nome, nomeMapa(mapa), melhor[1] * 100, melhor[2] * 100)
  if TomTom and TomTom.AddWaypoint then
    if uidAtual and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, uidAtual) end
    local okW, uid = pcall(TomTom.AddWaypoint, TomTom, mapa, melhor[1], melhor[2], {
      title = e.nome .. " (skinning)", from = "GuiaForever", persistent = false, crazy = true,
    })
    if okW then
      uidAtual = uid
      ns.msg("arrow to " .. onde)
      return
    end
  end
  ns.msg(onde .. ". No TomTom: /way #" .. mapa .. string.format(" %.1f %.1f", melhor[1] * 100, melhor[2] * 100))
end

-- Aba Zone ------------------------------------------------------------------
local function linhaFaixas(minima)
  return string.format("orange to %d, yellow to %d, green to %d, grey from %d (estimated)",
    minima + FAIXAS.laranja, minima + FAIXAS.amarelo, minima + FAIXAS.verde, minima + FAIXAS.verde)
end

local function linhaRota(b, T, tab, pericia, rotulo)
  if not (tab and tab.passos and ns.indicePasso) then return end
  local i = ns.indicePasso(tab, pericia)
  local passo = tab.passos[i]
  if passo then T(b, rotulo .. ": " .. passo.texto .. " (" .. passo.de .. "-" .. passo.ate .. ")") end
end

function ns.blocosZona(b)
  local T, cab, B = ns.blocoTexto, ns.blocoCabecalho, ns.blocoBotao
  local pericia, maximo, tem = periciaSkinning()
  local idx, motivo = montarIndice()
  local mapaIdx, mapaReal = nil, nil
  if idx then mapaIdx, mapaReal = mapaDaZona(idx) end
  local nomeZona = mapaReal and nomeMapa(mapaReal) or "unknown zone"
  T(b, ns.COR .. nomeZona .. ns.FIM .. "  Skinning " .. pericia .. "/" .. tostring(maximo or "?"))
  if not tem then
    T(b, "You do not have Skinning (shown with skill 0). Trainers: Trainers tab.")
  end
  for _, tr in ipairs(TREINOS) do
    if not maximo or maximo < tr.vai then
      T(b, "|cff999999" .. tr.nome .. " Skinning needs skill " .. tr.pede .. " (goes to " .. tr.vai
        .. "), character level " .. tr.nivel .. " (level per Naowh)|r")
    end
  end
  if maximo and maximo < 300 and pericia >= maximo then
    local prox
    for _, tr in ipairs(TREINOS) do
      if tr.vai > maximo then prox = tr; break end
    end
    T(b, colorir("vermelho", "Capped at " .. maximo .. ": train " .. (prox and prox.nome or "the next rank")))
  end

  if not idx then
    T(b, motivo or "Index unavailable.")
  elseif not mapaIdx then
    T(b, "No skinnable creature known in " .. nomeZona .. ".")
  else
    local itens = {}
    for _, e in ipairs(idx[mapaIdx]) do
      local minimaMax = periciaMinima(e.max)
      local minimaMin = periciaMinima(e.min)
      local cor = corDe(pericia, minimaMax)
      local corMin = corDe(pericia, minimaMin)
      itens[#itens + 1] = { e = e, minima = minimaMax, cor = cor, corMin = corMin }
    end
    table.sort(itens, function(a, c)
      if ORDEM[a.cor] ~= ORDEM[c.cor] then return ORDEM[a.cor] < ORDEM[c.cor] end
      if a.e.max ~= c.e.max then return a.e.max < c.e.max end
      return a.e.nome < c.e.nome
    end)
    cab(b, "Skinnable creatures here (" .. #itens .. ")")
    local uteis = {}
    for _, it in ipairs(itens) do
      local e = it.e
      local niv = (e.min == e.max) and tostring(e.max) or (e.min .. "-" .. e.max)
      local estado = ROTULO[it.cor]
      if it.corMin ~= it.cor then
        estado = estado .. ", higher levels; lowest level " .. ROTULO[it.corMin]
      end
      T(b, colorir(it.cor, e.nome .. " (lvl " .. niv .. "): needs " .. it.minima .. " | "
        .. linhaFaixas(it.minima) .. " - " .. estado))
      if it.cor == "laranja" or it.cor == "amarelo" then uteis[#uteis + 1] = it end
    end
    if #uteis == 0 then
      for _, it in ipairs(itens) do
        if it.cor == "verde" then uteis[#uteis + 1] = it end
      end
    end
    if #uteis > 0 then
      T(b, " ")
      for i = 1, math.min(6, #uteis) do
        local e = uteis[i].e
        B(b, "Arrow: " .. e.nome, function() setaBicho(e, mapaIdx) end)
      end
    else
      cab(b, "No useful creature here for your skill")
      linhaRota(b, T, ns.tabelaProf("Skinning"), pericia, "Source route (wow-professions)")
    end
  end

  local okL, lista = pcall(ns.minhasProfissoes)
  if okL and type(lista) == "table" then
    for _, pr in ipairs(lista) do
      if pr.nome == "Leatherworking" then
        T(b, " ")
        linhaRota(b, T, pr.tab, pr.pericia, "Leatherworking " .. pr.pericia .. " - source route (wow-professions)")
      end
    end
  end

  local d = db()
  T(b, " ")
  T(b, "|cff999999Journal: " .. contar(d.skinCores) .. " colors, " .. contar(d.skinLog) .. " skill gains, "
    .. contar(d.skinAprendidos) .. " learned creatures. Ranges marked estimated are to be confirmed."
    .. " Sources: skill rule wow.gg (Nov 4, 2026); creatures cmangos classic-db; locations and levels Questie|r")
end

-- Tooltip ---------------------------------------------------------------------
local function idDoGuid(guid)
  if type(guid) ~= "string" then return nil end
  local tipo, _, _, _, _, id = strsplit("-", guid)
  if tipo == "Creature" or tipo == "Vehicle" then return tonumber(id) end
  return nil
end

local function dadosDoId(id)
  local base = GuiaForeverSkinDB and GuiaForeverSkinDB[id]
  if base then return base[1], base[2], base[3], true end
  local apr = aprendidos()[id]
  if apr then return apr.nome, apr.nivel, apr.nivel, true end
  return nil, nil, nil, false
end

local function empurrar(lista, v)
  lista[#lista + 1] = v
  while #lista > MAX_DIARIO do table.remove(lista, 1) end
end

local function textoLinha(i)
  local fs = _G["GameTooltipTextLeft" .. i]
  if not fs then return nil end
  local ok, t = pcall(fs.GetText, fs)
  if not ok then return nil end
  if issecretvalue and issecretvalue(t) then return nil end
  if type(t) ~= "string" then return nil end
  return t, fs
end

local ultimaCor -- guid:pericia da ultima cor gravada no diario

local function aoTooltip(tt)
  if tt ~= GameTooltip then return end
  if (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) then return end
  local okU, _, unit = pcall(tt.GetUnit, tt)
  if not okU or not unit then return end
  local okG, guid = pcall(UnitGUID, unit)
  if not okG or not guid then return end
  if issecretvalue and issecretvalue(guid) then return end
  local id = idDoGuid(guid)
  if not id then return end

  local skinnable = _G.UNIT_SKINNABLE_LEATHER or "Skinnable"
  local achouLinha, fsLinha = false, nil
  local nLinhas = tt:NumLines() or 0
  for i = 2, nLinhas do
    local t, fs = textoLinha(i)
    if t and t:find(skinnable, 1, true) then achouLinha, fsLinha = true, fs; break end
  end

  local okM, morto = pcall(UnitIsDead, unit)
  local nivelU
  local okL, lv = pcall(UnitLevel, unit)
  if okL and type(lv) == "number" and lv > 0 and not (issecretvalue and issecretvalue(lv)) then nivelU = lv end

  local _, mn, mx, conhecido = dadosDoId(id)
  if not conhecido and okM and morto and achouLinha then
    local okN, n = pcall(UnitName, unit)
    if not (okN and type(n) == "string" and not (issecretvalue and issecretvalue(n))) then n = "NPC " .. id end
    aprendidos()[id] = { nome = n, nivel = nivelU or 0 }
    indice = nil
    mn, mx, conhecido = nivelU, nivelU, true
  end

  local pericia = periciaSkinning()

  -- diario: cor da linha Skinnable do cadaver (uma vez por bicho e pericia: o tooltip de
  -- unidade se refaz varias vezes enquanto o mouse esta em cima)
  if achouLinha and fsLinha and conhecido then
    local chave = guid .. ":" .. tostring(pericia)
    if chave ~= ultimaCor then
      local okC, r, g, bl = pcall(fsLinha.GetTextColor, fsLinha)
      if okC and type(r) == "number" and not (issecretvalue and issecretvalue(r)) then
        ultimaCor = chave
        local d = db()
        d.skinCores = d.skinCores or {}
        empurrar(d.skinCores, { id = id, nivel = nivelU or mx, pericia = pericia, r = r, g = g, b = bl })
      end
    end
  end

  if conhecido and mx and mx > 0 then
    local nivel = nivelU or mx
    local minima = periciaMinima(nivel)
    local cor = corDe(pericia, minima)
    tt:AddLine(colorir(cor, string.format("Skinning: needs %d - %s (yellow to %d, grey from %d, est.)",
      minima, ROTULO[cor], minima + FAIXAS.amarelo, minima + FAIXAS.verde)))
    tt:Show()
  end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
  pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Unit, function(tt)
    pcall(aoTooltip, tt)
  end)
end

-- Eventos -----------------------------------------------------------------
local pendente

local function nomeMagia(spellID)
  if C_Spell and C_Spell.GetSpellName then
    local ok, n = pcall(C_Spell.GetSpellName, spellID)
    if ok and n then return n end
  end
  if GetSpellInfo then
    local ok, n = pcall(GetSpellInfo, spellID)
    if ok and n then return n end
  end
  return nil
end

local function ehSkinning(spellID)
  if not spellID or (issecretvalue and issecretvalue(spellID)) then return false end
  return nomeMagia(spellID) == "Skinning"
end

-- Nivel do cadaver: quem esfola clicando nem sempre esta com ele no alvo, entao vale
-- primeiro o cadaver sob o mouse, depois o da interacao suave, depois o alvo.
local function nivelDoCadaver()
  for _, u in ipairs({ "mouseover", "softinteract", "target" }) do
    local okE, existe = pcall(UnitExists, u)
    local okD, morto = pcall(UnitIsDead, u)
    if okE and existe and okD and morto then
      local okL, lv = pcall(UnitLevel, u)
      if okL and type(lv) == "number" and not (issecretvalue and issecretvalue(lv)) and lv > 0 then return lv end
    end
  end
  return nil
end

local function novoPendente()
  return { nivel = nivelDoCadaver(), antes = periciaSkinning() }
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:RegisterEvent("SKILL_LINES_CHANGED")
for _, e in ipairs({ "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED" }) do
  pcall(ev.RegisterUnitEvent, ev, e, "player")
end
ev:SetScript("OnEvent", function(_, evento, ...)
  if evento == "ZONE_CHANGED_NEW_AREA" or evento == "SKILL_LINES_CHANGED" then
    if ns.atualizarJanela then pcall(ns.atualizarJanela) end
    return
  end
  if ns.emCombate() then return end
  if evento == "UNIT_SPELLCAST_SENT" then
    local _, _, _, spellID = ...
    if ehSkinning(spellID) then pendente = novoPendente() end
  elseif evento == "UNIT_SPELLCAST_START" then
    local _, _, spellID = ...
    if ehSkinning(spellID) and not pendente then pendente = novoPendente() end
  elseif evento == "UNIT_SPELLCAST_SUCCEEDED" then
    local _, _, spellID = ...
    if ehSkinning(spellID) and pendente then
      local p = pendente
      pendente = nil
      if C_Timer and C_Timer.After then
        C_Timer.After(1, function()
          local depois = periciaSkinning()
          local d = db()
          d.skinLog = d.skinLog or {}
          empurrar(d.skinLog, { nivel = p.nivel, antes = p.antes, depois = depois })
        end)
      end
    end
  end
end)
