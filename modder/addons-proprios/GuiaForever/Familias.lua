-- GuiaForever: guia de habilidades de pet por familia (aba "Families") e a secao
-- "Next ability upgrades" da aba Pet. Os dados vem de PetGuia.lua (GuiaForeverPetGuia, gerado);
-- o estado vem do jogo (familia, nivel e livro do pet). So leitura: nada compra ou treina.
-- Contrato: ARQUITETURA.md, secoes 1 e 10.

local _, ns = ...

local VERDE, CINZA = "|cff33ff33", "|cff999999"
local CONTRATO = 4
local ESCOLHA_PROF = 3 -- professores mostrados por habilidade em "Next ability upgrades"

local function guia() return GuiaForeverPetGuia end

local function fim() return ns.FIM or "|r" end
local function cor(s) return (ns.COR or "") .. s .. fim() end
local function sSec(b, s, id, aberta, resumo, nivel)
  b[#b + 1] = { t = "cab", s = s, id = id, aberta = aberta, resumo = resumo, nivel = nivel or 1 }
end
local function sLinha(b, s, fonte, dica) b[#b + 1] = { t = "linha", s = s, fonte = fonte, dica = dica } end
local function sTexto(b, s) b[#b + 1] = { t = "texto", s = s } end
local function sBotao(b, s, f) b[#b + 1] = { t = "botao", s = s, f = f } end

-- Ranks do pet ativo ---------------------------------------------------------------------

local sujo = true
local cacheRanks = {}
local indiceGuia, indiceId, indiceNome

local function indexar(g)
  if indiceGuia == g then return end
  indiceGuia, indiceId, indiceNome = g, {}, {}
  if type(g.habilidades) ~= "table" then return end
  for nome, h in pairs(g.habilidades) do
    indiceNome[string.lower(nome)] = nome
    if type(h.ranks) == "table" then
      for _, r in ipairs(h.ranks) do
        if type(r.id) == "number" then indiceId[r.id] = { nome, r.r } end
      end
    end
  end
end

local function reconstruir()
  local res = {}
  local g = guia()
  if g and UnitExists and UnitExists("pet") and C_SpellBook and C_SpellBook.HasPetSpells
     and C_SpellBook.GetSpellBookItemInfo and Enum and Enum.SpellBookSpellBank then
    indexar(g)
    local banco = Enum.SpellBookSpellBank.Pet
    local n = C_SpellBook.HasPetSpells()
    if type(n) == "number" and banco ~= nil then
      for s = 1, n do
        local info = C_SpellBook.GetSpellBookItemInfo(s, banco)
        if info then
          local nome, r
          local pelaId = type(info.spellID) == "number" and indiceId[info.spellID]
          if pelaId then
            nome, r = pelaId[1], pelaId[2]
          elseif type(info.name) == "string" then
            nome = indiceNome[string.lower(info.name)]
            if nome then
              local num = type(info.subName) == "string" and info.subName:match("(%d+)")
              if num then
                r = tonumber(num)
              else
                local h = g.habilidades[nome]
                if h and h.ranks and #h.ranks == 1 then r = h.ranks[1].r end
              end
            end
          end
          if nome and r and (res[nome] == nil or r > res[nome]) then res[nome] = r end
        end
      end
    end
  end
  cacheRanks, sujo = res, false
end

function ns.petRanks()
  if sujo then
    if not pcall(reconstruir) then cacheRanks, sujo = {}, false end
  end
  return cacheRanks
end

for _, ev in ipairs({ "UNIT_PET", "PET_BAR_UPDATE", "SPELLS_CHANGED", "UNIT_PET_TRAINING_POINTS" }) do
  if ns.ao then ns.ao(ev, function() sujo = true end) end
end

-- Utilidades dos dados ------------------------------------------------------------------

local function acharFamilia(g, nome)
  if type(nome) ~= "string" or type(g.familias) ~= "table" then return nil end
  local baixo = string.lower(nome)
  for _, f in ipairs(g.familias) do
    if string.lower(tostring(f.nome)) == baixo then return f end
  end
  return nil
end

local function acharRank(h, r)
  if not (h and type(h.ranks) == "table") then return nil end
  for _, x in ipairs(h.ranks) do
    if x.r == r then return x end
  end
  return nil
end

-- nivel maximo da fera: o numero depois do hifen em nv, ou o unico
local function nivelMax(p)
  local n = tostring(p.nv or ""):match("(%d+)%s*$")
  return tonumber(n)
end

local function podeDomar(p)
  local m = nivelMax(p)
  if not m then return false end
  return m <= (UnitLevel("player") or 1)
end

local function txtProf(p)
  local z = p.z and (", " .. tostring(p.z)) or ""
  return tostring(p.n) .. " (" .. tostring(p.nv) .. z .. ")" .. (p.s and " *" or "")
end

-- o maior rank acima do atual que o pet ja pode treinar (comprar um rank maior devolve os pontos
-- do menor, Petopia); sem nenhum, o rank seguinte
local function alvoRank(h, atual, nivelPet)
  local melhor
  for _, x in ipairs(h.ranks or {}) do
    if type(x.r) == "number" and x.r > atual and (x.pet or 0) <= nivelPet then
      if not melhor or x.r > melhor.r then melhor = x end
    end
  end
  return melhor or acharRank(h, atual + 1)
end

local function txtPt(r)
  local pt = r.pt and (", " .. r.pt .. " TP") or ""
  return "pet " .. tostring(r.pet) .. pt
end

-- Posicao de um professor pelo QuestieDB (mesmo caminho de Treinadores.lua e Zona.lua) --------------

local cacheSpawn = {}

local function questiePronto()
  if not (LibQuestieDB and LibQuestieDB.Npc and LibQuestieDB.RequireContract) then return nil end
  local ok = pcall(LibQuestieDB.RequireContract, CONTRATO)
  if not ok then return nil end
  if not (Questie and Questie.API and Questie.API.isReady) then return nil end
  local ZoneDB = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("ZoneDB")
  if not (ZoneDB and ZoneDB.GetUiMapIdByAreaId) then return nil end
  return ZoneDB
end

local function pontoDoProf(npc)
  if type(npc) ~= "number" then return nil end
  local c = cacheSpawn[npc]
  if c == nil then
    local ZoneDB = questiePronto()
    if not ZoneDB then return nil end -- nao guarda: o Questie pode ainda carregar
    c = false
    local ok, spawns = pcall(LibQuestieDB.Npc.Get, npc, "spawns")
    if ok and type(spawns) == "table" then
      local lista = {}
      for areaId, pontos in pairs(spawns) do
        local okM, mapa = pcall(ZoneDB.GetUiMapIdByAreaId, ZoneDB, areaId)
        if okM and mapa and type(pontos) == "table" then
          for _, pt in ipairs(pontos) do
            local x, y = pt[1], pt[2]
            if type(x) == "number" and type(y) == "number" and x >= 0 and y >= 0 then
              lista[#lista + 1] = { mapa = mapa, x = x / 100, y = y / 100 }
            end
          end
        end
      end
      if #lista > 0 then c = lista end
    end
    cacheSpawn[npc] = c
  end
  if not c then return nil end
  -- o mais perto do jogador no mesmo continente; sem distancia, o primeiro
  local melhor, md
  if ns.distancia then
    for _, pt in ipairs(c) do
      local ok, d = pcall(ns.distancia, pt.mapa, pt.x, pt.y)
      if ok and type(d) == "number" and (md == nil or d < md) then melhor, md = pt, d end
    end
  end
  return melhor or c[1]
end

local function botaoSeta(b, p)
  local pt = pontoDoProf(p.npc)
  if not pt then return end
  local titulo = tostring(p.n)
  sBotao(b, "Arrow: " .. titulo, function()
    if ns.seta then ns.seta(pt.mapa, pt.x, pt.y, titulo) end
  end)
end

-- Next ability upgrades -------------------------------------------------------------------

local ROTA = "Route: stable your pet, tame the teacher, fight with it until you learn the rank, abandon it, call your pet back and teach the rank at Beast Training."

function ns.blocosProximosRanks(b)
  sSec(b, "Next ability upgrades", "pet:proximos", true)
  local g = guia()
  if not g then sLinha(b, "Pet guide data not loaded."); return end
  if not (UnitExists and UnitExists("pet")) then sLinha(b, "No pet out.", "game"); return end
  local nomeFam = UnitCreatureFamily and UnitCreatureFamily("pet")
  local fam = acharFamilia(g, nomeFam)
  if not fam then
    sLinha(b, "Pet family not in the guide" .. (nomeFam and (": " .. tostring(nomeFam)) or "") .. ".", "game")
    return
  end
  local nivelPet, nivelJog = UnitLevel("pet") or 0, UnitLevel("player") or 1
  sLinha(b, cor(tostring(fam.nome)) .. ", pet level " .. nivelPet .. " (you: level " .. nivelJog .. ")", "game")
  local ranks = ns.petRanks()
  local maximas, mostradas = 0, 0
  for _, nome in ipairs(fam.habilidades or {}) do
    local h = g.habilidades and g.habilidades[nome]
    if h and not h.treinador then
      local atual = ranks[nome] or 0
      local prox = alvoRank(h, atual, nivelPet)
      if not prox then
        if atual > 0 then maximas = maximas + 1 end
      else
        mostradas = mostradas + 1
        local de = atual > 0 and ("rank " .. atual .. " -> " .. prox.r) or ("not learned -> rank " .. prox.r)
        local pode = nivelPet >= (prox.pet or 0)
        local estado = pode and (VERDE .. "can train now" .. fim()) or ("needs pet level " .. tostring(prox.pet))
        sLinha(b, nome .. ": " .. de .. " (" .. txtPt(prox) .. ") - " .. estado, "pet guide", h.desc)
        local profs = {}
        local baixo, baixoNv
        for _, p in ipairs(prox.prof or {}) do
          if podeDomar(p) then
            if #profs < ESCOLHA_PROF then profs[#profs + 1] = p end
          else
            local m = nivelMax(p)
            if m and (baixoNv == nil or m < baixoNv) then baixo, baixoNv = p, m end
          end
        end
        if #profs > 0 then
          for _, p in ipairs(profs) do
            sLinha(b, "   Tame: " .. txtProf(p), p.f or "pet guide",
              p.fam and ("Family: " .. tostring(p.fam)) or nil)
            botaoSeta(b, p)
          end
        elseif baixo then
          sLinha(b, "   " .. CINZA .. "No teacher you can tame yet. Lowest: " .. txtProf(baixo) .. fim(),
            baixo.f or "pet guide")
        end
      end
    end
  end
  if mostradas == 0 then
    sLinha(b, "No upgrades listed" .. (maximas > 0 and ": all known abilities are at top rank." or "."), "pet guide")
  elseif maximas > 0 then
    sLinha(b, CINZA .. maximas .. " more at top rank." .. fim())
  end
  sLinha(b, CINZA .. "* = the Saltii pick." .. fim(), "Saltii")
  sTexto(b, CINZA .. ROTA .. fim())
end

-- Aba Families ----------------------------------------------------------------------------------

local function partesProf(r, maximo)
  local partes, resto = {}, {}
  for i, p in ipairs(r.prof or {}) do
    if i <= maximo then partes[#partes + 1] = txtProf(p) else resto[#resto + 1] = txtProf(p) end
  end
  return partes, resto
end

local function blocoFamilia(b, g, fam)
  local resumo = {}
  if fam.papel then resumo[#resumo + 1] = tostring(fam.papel) end
  if fam.unica then resumo[#resumo + 1] = tostring(fam.unica) end
  if type(fam.dieta) == "table" and #fam.dieta > 0 then resumo[#resumo + 1] = table.concat(fam.dieta, "/") end
  local id = "fam:" .. tostring(fam.nome)
  sSec(b, tostring(fam.nome), id, false, table.concat(resumo, ", "))
  if fam.papel then sLinha(b, "Role: " .. tostring(fam.papel), "pet guide") end
  if fam.unica then sLinha(b, "Unique ability: " .. tostring(fam.unica), "pet guide") end
  if type(fam.dieta) == "table" and #fam.dieta > 0 then
    sLinha(b, "Diet: " .. table.concat(fam.dieta, ", "), "pet guide")
  end
  if type(fam.habilidades) == "table" and #fam.habilidades > 0 then
    sLinha(b, "Abilities: " .. table.concat(fam.habilidades, ", "), "pet guide")
  end
  for _, n in ipairs(fam.notas or {}) do sLinha(b, tostring(n.t), n.f) end
  for _, r in ipairs(fam.rapidas or {}) do
    local v = r.v and (", speed " .. tostring(r.v)) or ""
    sLinha(b, "Fast: " .. tostring(r.n) .. " (" .. tostring(r.nv) .. (r.z and (", " .. tostring(r.z)) or "") .. v .. ")", r.f)
  end
  -- progressao por ultimo: a subsecao recolhida esconde os blocos que vierem depois dela
  sSec(b, tostring(fam.nome) .. " progression", id .. ":prog", false, nil, 2)
  for _, nome in ipairs(fam.habilidades or {}) do
    local h = g.habilidades and g.habilidades[nome]
    if h and type(h.ranks) == "table" then
      for _, r in ipairs(h.ranks) do
        local partes, resto = partesProf(r, 1)
        local alvo = #partes > 0 and (": " .. partes[1]) or (h.treinador and ": pet trainer" or "")
        sLinha(b, nome .. " " .. tostring(r.r) .. " - " .. txtPt(r) .. alvo, "pet guide",
          #resto > 0 and ("Also: " .. table.concat(resto, "; ")) or nil)
      end
    end
  end
end

local function nomesOrdenados(t)
  local l = {}
  for k in pairs(t or {}) do l[#l + 1] = k end
  table.sort(l)
  return l
end

local function blocoHabilidades(b, g)
  local nomes = nomesOrdenados(g.habilidades)
  sSec(b, "Abilities", "hab:todas", false, #nomes .. " abilities")
  for _, nome in ipairs(nomes) do
    local h = g.habilidades[nome]
    sSec(b, nome, "hab:" .. nome, false, h.treinador and "pet trainer" or nil, 2)
    if h.desc then sLinha(b, tostring(h.desc), "pet guide") end
    if h.familias == "all" then
      sLinha(b, "Learned by: all families", "pet guide")
    elseif type(h.familias) == "table" and #h.familias > 0 then
      sLinha(b, "Learned by: " .. table.concat(h.familias, ", "), "pet guide")
    end
    for _, r in ipairs(h.ranks or {}) do
      local partes, resto = partesProf(r, 4)
      local alvo = #partes > 0 and (": " .. table.concat(partes, "; ")) or (h.treinador and ": pet trainer" or "")
      sLinha(b, "Rank " .. tostring(r.r) .. " - " .. txtPt(r) .. alvo, "pet guide",
        #resto > 0 and ("Also: " .. table.concat(resto, "; ")) or nil)
    end
  end
end

local function blocoTreinador(b, g)
  local nomes = {}
  for _, nome in ipairs(nomesOrdenados(g.habilidades)) do
    if g.habilidades[nome].treinador then nomes[#nomes + 1] = nome end
  end
  sSec(b, "Pet trainer", "hab:treinador", false, #nomes .. " abilities")
  for _, nome in ipairs(nomes) do
    local partes = {}
    for _, r in ipairs(g.habilidades[nome].ranks or {}) do
      partes[#partes + 1] = "rank " .. tostring(r.r) .. " level " .. tostring(r.pet) .. (r.pt and (" (" .. r.pt .. " TP)") or "")
    end
    sLinha(b, nome .. ": " .. table.concat(partes, ", "), "pet guide", g.habilidades[nome].desc)
  end
end

function ns.blocosFamilias(b)
  local g = guia()
  if not g then sLinha(b, "Pet guide data not loaded."); return end

  if type(g.regras) == "table" and #g.regras > 0 then
    sSec(b, "How pet abilities work", "fam:regras", true)
    for _, r in ipairs(g.regras) do sLinha(b, tostring(r.t), r.f) end
  end

  ns.blocosProximosRanks(b)

  for _, fam in ipairs(g.familias or {}) do blocoFamilia(b, g, fam) end

  if type(g.habilidades) == "table" then
    blocoHabilidades(b, g)
    blocoTreinador(b, g)
  end

  sSec(b, "Sources", "fam:fontes", false)
  if g.gerado then
    sLinha(b, "Data generated " .. tostring(g.gerado) .. (g.build and (", client build " .. tostring(g.build)) or ""))
  end
  for _, f in ipairs(g.fontes or {}) do
    sLinha(b, tostring(f.nome) .. (f.data and (" (" .. tostring(f.data) .. ")") or ""), f.id, f.url)
  end
end
