-- GuiaForever: guia de habilidades de pet por familia (aba "Families") e a secao
-- "Next ability upgrades" da aba Pet. Os dados vem de PetGuia.lua (GuiaForeverPetGuia, gerado);
-- o estado vem do jogo (familia, nivel e livro do pet). So leitura: nada compra ou treina.
-- Contrato: ARQUITETURA.md, secoes 1, 10 e 11.

local _, ns = ...

local CONTRATO = 4
local ESCOLHA_PROF = 3 -- professores mostrados por habilidade em "Next ability upgrades"

local function guia() return GuiaForeverPetGuia end

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

-- Texto da janela: sem nome de fonte (C1) e sem "*" (C5) -------------------------------------------

local FONTES = { "LudiDeo", "Saltii", "Kargoz", "Petopia", "Gladius", "MetaGoblin", "Method", "Source" }

-- limpa o texto dos dados; devolve nil se ainda sobrar nome de fonte
local function limpo(t)
  if type(t) ~= "string" then return nil end
  t = t:gsub("%s*%(%*[^)]*%)", "")
  t = t:gsub(";%s*LudiDeo says[^.;]*", "")
  t = t:gsub("%s*%(LudiDeo[^)]*%)", "")
  t = t:gsub("%*", "")
  t = t:gsub("%s+$", "")
  for _, f in ipairs(FONTES) do
    if t:find(f, 1, true) then return nil end
  end
  return t
end

local ICONES_FAMILIA = {
  ["Cat"] = "Cat", ["Raptor"] = "Raptor", ["Wind Serpent"] = "WindSerpent", ["Scorpid"] = "Scorpid",
  ["Boar"] = "Boar", ["Carrion Bird"] = "Vulture", ["Bear"] = "Bear", ["Gorilla"] = "Gorilla",
  ["Turtle"] = "Turtle", ["Spider"] = "Spider", ["Crab"] = "Crab", ["Hyena"] = "Hyena",
  ["Crocolisk"] = "Crocolisk", ["Bat"] = "Bat", ["Bird of Prey"] = "Owl", ["Tallstrider"] = "TallStrider",
  ["Wolf"] = "Wolf", ["Fox"] = "Wolf", ["Core Hound"] = "CoreHound",
}

local function iconeFamilia(nome)
  local n = ICONES_FAMILIA[tostring(nome)]
  if not n then return nil end
  return "Interface\\Icons\\Ability_Hunter_Pet_" .. n
end

local ETAPAS = { "Stable your pet", "Tame the teacher", "Fight until learned", "Abandon it", "Teach at Beast Training" }

local function iconeRank1(h)
  local r = h and h.ranks and h.ranks[1]
  return r and r.id or nil
end

-- professores domaveis (o escolhido primeiro) e o mais baixo ainda fora do alcance
local function escolherProfs(r)
  local doma, baixo, baixoNv = {}, nil, nil
  for _, p in ipairs(r.prof or {}) do
    if podeDomar(p) then
      if p.s then table.insert(doma, 1, p) else doma[#doma + 1] = p end
    else
      local m = nivelMax(p)
      if m and (baixoNv == nil or m < baixoNv) then baixo, baixoNv = p, m end
    end
  end
  return doma, baixo, baixoNv
end

local function listaProfs(lista, maximo)
  local l = {}
  for i, p in ipairs(lista) do
    if i > maximo then break end
    local z = p.z and (", " .. tostring(p.z)) or ""
    l[#l + 1] = tostring(p.n) .. " (" .. tostring(p.nv) .. z .. ")"
  end
  return l
end

local function passosPet(b)
  b[#b + 1] = { t = "passos", lista = ETAPAS }
end

-- Next ability upgrades -------------------------------------------------------------------

function ns.blocosProximosRanks(b, ctx)
  ctx = ctx or { tudo = false }
  local g = guia()
  local nomeFam = UnitExists and UnitExists("pet") and UnitCreatureFamily and UnitCreatureFamily("pet")
  local fam = g and acharFamilia(g, nomeFam)
  b[#b + 1] = { t = "sec", s = "Next ability upgrades", id = "pet:proximos",
    qtd = fam and ("what your " .. tostring(fam.nome) .. " can learn now") or nil }
  if not g then b[#b + 1] = { t = "vazio", s = "Pet guide data not loaded." }; return end
  if not (UnitExists and UnitExists("pet")) then b[#b + 1] = { t = "vazio", s = "No pet out." }; return end
  if not fam then
    b[#b + 1] = { t = "vazio", s = "Pet family not in the guide." }
    return
  end
  local nivelPet = UnitLevel("pet") or 0
  local ranks = ns.petRanks()
  local grupos = { {}, {}, {} } -- com professor domavel, prontas sem professor, travadas
  for _, nome in ipairs(fam.habilidades or {}) do
    local h = g.habilidades and g.habilidades[nome]
    if h and not h.treinador then
      local atual = ranks[nome] or 0
      local prox = alvoRank(h, atual, nivelPet)
      if prox then
        local pode = nivelPet >= (prox.pet or 0)
        local doma, baixo, baixoNv = escolherProfs(prox)
        local celProf, botao
        local dica = {}
        if h.desc then dica[#dica + 1] = tostring(h.desc) end
        if #doma > 0 then
          local p = doma[1]
          celProf = tostring(p.n) .. " (" .. tostring(p.nv) .. ")"
          local z = p.z and (", " .. tostring(p.z)) or ""
          dica[#dica + 1] = "Teacher: " .. tostring(p.n) .. " (" .. tostring(p.nv) .. z .. ")"
            .. (p.s and " - recommended" or "")
          for i = 2, math.min(#doma, ESCOLHA_PROF + 1) do
            local o = doma[i]
            dica[#dica + 1] = "Also: " .. tostring(o.n) .. " (" .. tostring(o.nv) .. (o.z and (", " .. tostring(o.z)) or "") .. ")"
          end
          local pt = pontoDoProf(p.npc)
          if pt then
            local titulo = tostring(p.n)
            botao = { rotulo = "Arrow", acao = function()
              if ns.seta then ns.seta(pt.mapa, pt.x, pt.y, titulo) end
            end }
          end
        elseif baixo then
          celProf = { s = "none yet, first at " .. tostring(baixoNv) .. ": " .. tostring(baixo.n), cor = "cinza" }
          dica[#dica + 1] = "Lowest teacher: " .. tostring(baixo.n) .. " (" .. tostring(baixo.nv)
            .. (baixo.z and (", " .. tostring(baixo.z)) or "") .. ")"
        else
          celProf = { s = "pet trainer", cor = "cinza" }
        end
        local linha = {
          celulas = {
            { s = nome, icone = iconeRank1(h) },
            (atual > 0 and tostring(atual) or "-") .. " -> " .. tostring(prox.r),
            { s = tostring(prox.pet or "-"), numero = true },
            { s = tostring(prox.pt or "-"), numero = true },
            pode and { s = "ready", estado = "agora" } or { s = "pet " .. tostring(prox.pet), estado = "travado" },
            celProf,
          },
          dica = #dica > 0 and dica or nil,
          botao = botao,
          apagado = (not pode) or nil,
        }
        local gi = (not pode) and 3 or (#doma > 0 and 1 or 2)
        table.insert(grupos[gi], linha)
      end
    end
  end
  local linhas = {}
  for _, gr in ipairs(grupos) do
    for _, l in ipairs(gr) do linhas[#linhas + 1] = l end
  end
  if #linhas == 0 then
    b[#b + 1] = { t = "vazio", s = "Nothing to upgrade: your pet is at top rank." }
    return
  end
  b[#b + 1] = { t = "tabela", id = "pet:proximos:tab", limite = 6,
    colunas = {
      { s = "Ability", largura = 130 }, { s = "Rank", largura = 64 },
      { s = "Pet", largura = 44, alinha = "centro" }, { s = "TP", largura = 36, alinha = "centro" },
      { s = "Status", largura = 90 }, { s = "Teacher you can tame" },
    },
    linhas = linhas }
  passosPet(b)
end

-- Aba Families ----------------------------------------------------------------------------------

local function tierDe(fam)
  for _, n in ipairs(fam.notas or {}) do
    local t = tostring(n.t or "")
    local resto = t:match("^Tier %(LudiDeo%):%s*(.*)$")
    if resto then
      resto = limpo("Tier: " .. resto)
      if resto then return (resto:gsub("%.$", "")) end
    end
  end
  return nil
end

local function notasDe(fam)
  local l = {}
  for _, n in ipairs(fam.notas or {}) do
    local t = tostring(n.t or "")
    if not t:find("^Tier %(") then
      local c = limpo(t)
      if c and c ~= "" then l[#l + 1] = c end
    end
  end
  return l
end

local function marcasRank(h, tem, ehPet, nivelPet, alvo)
  local marcas = {}
  for _, r in ipairs(h.ranks or {}) do
    local estado = "depois"
    if ehPet then
      if r.r <= tem then
        estado = "tem"
      elseif alvo and r.r == alvo.r and (r.pet or 0) <= nivelPet then
        estado = "agora"
      end
    end
    local dica = { "Rank " .. tostring(r.r) .. ": pet level " .. tostring(r.pet) .. (r.pt and (", " .. r.pt .. " TP") or "") }
    for _, t in ipairs(listaProfs(r.prof or {}, 4)) do dica[#dica + 1] = t end
    marcas[#marcas + 1] = { nivel = r.pet, rank = r.r, estado = estado, dica = dica }
  end
  return marcas
end

local function detalheFamilia(b, g, fam, ehPet, ctx)
  local etq = {}
  if fam.papel then etq[#etq + 1] = tostring(fam.papel) end
  if fam.unica then etq[#etq + 1] = "unique: " .. tostring(fam.unica) end
  local tier = tierDe(fam)
  if tier then etq[#etq + 1] = tier end
  b[#b + 1] = { t = "titulo", icone = iconeFamilia(fam.nome), s = tostring(fam.nome), etiquetas = etq }
  if type(fam.dieta) == "table" and #fam.dieta > 0 then
    b[#b + 1] = { t = "etiquetas", rotulo = "Eats", lista = fam.dieta }
  end
  b[#b + 1] = { t = "sec", s = "Ranks by pet level", id = "fam:regua" }
  local ranks = ehPet and ns.petRanks() or {}
  local nivelPet = ehPet and (UnitLevel("pet") or 0) or 0
  local nivelJog = UnitLevel("player") or 1
  local linhas = {}
  for _, nome in ipairs(fam.habilidades or {}) do
    local h = g.habilidades and g.habilidades[nome]
    if h and not h.treinador and type(h.ranks) == "table" and #h.ranks > 0 then
      local tem = ranks[nome] or 0
      local alvo = ehPet and alvoRank(h, tem, nivelPet) or nil
      linhas[#linhas + 1] = { nome = nome, icone = iconeRank1(h), marcas = marcasRank(h, tem, ehPet, nivelPet, alvo) }
    end
  end
  if #linhas > 0 then
    b[#b + 1] = { t = "regua", min = 1, max = 60, atual = ehPet and nivelPet or nivelJog,
      rotuloAtual = ehPet and ("your pet " .. nivelPet) or ("you " .. nivelJog), linhas = linhas }
  else
    b[#b + 1] = { t = "vazio", s = "No trainable abilities listed." }
  end
  local notas = notasDe(fam)
  if #notas > 0 then
    b[#b + 1] = { t = "sec", s = "Notes", id = "fam:notas", qtd = tostring(#notas) }
    local maximo = ctx.tudo and #notas or math.min(3, #notas)
    for i = 1, maximo do b[#b + 1] = { t = "nota", s = notas[i] } end
  end
end

local function detalheRegras(b, g, ctx)
  b[#b + 1] = { t = "sec", s = "How abilities work", id = "fam:regras" }
  passosPet(b)
  for _, r in ipairs(g.regras or {}) do
    local t = tostring(r.t or "")
    if (r.e or ctx.tudo) and not t:find("^Step %d") then
      local c = limpo(t)
      if c and c ~= "" then b[#b + 1] = { t = "nota", s = c } end
    end
  end
end

local function nomesOrdenados(t)
  local l = {}
  for k in pairs(t or {}) do l[#l + 1] = k end
  table.sort(l)
  return l
end

local function faixa(a, z)
  if a == nil then return "-" end
  if z == nil or z == a then return tostring(a) end
  return tostring(a) .. "-" .. tostring(z)
end

local function limitesRanks(h)
  local rmin, rmax, pmin, pmax
  for _, r in ipairs(h.ranks or {}) do
    if type(r.r) == "number" then
      if not rmin or r.r < rmin then rmin = r.r end
      if not rmax or r.r > rmax then rmax = r.r end
    end
    if type(r.pet) == "number" then
      if not pmin or r.pet < pmin then pmin = r.pet end
      if not pmax or r.pet > pmax then pmax = r.pet end
    end
  end
  return rmin, rmax, pmin, pmax
end

local function detalheHabilidades(b, g)
  local nomes = {}
  for _, nome in ipairs(nomesOrdenados(g.habilidades)) do
    if not g.habilidades[nome].treinador then nomes[#nomes + 1] = nome end
  end
  b[#b + 1] = { t = "sec", s = "All abilities", id = "fam:habilidades", qtd = tostring(#nomes) }
  local linhas = {}
  for _, nome in ipairs(nomes) do
    local h = g.habilidades[nome]
    local quem, dicaFam
    if h.familias == "all" then
      quem = "all families"
    elseif type(h.familias) == "table" and #h.familias > 0 then
      if #h.familias <= 2 then quem = table.concat(h.familias, ", ") else quem = #h.familias .. " families" end
      dicaFam = "Learned by: " .. table.concat(h.familias, ", ")
    else
      quem = "-"
    end
    local rmin, rmax, pmin, pmax = limitesRanks(h)
    local dica = {}
    if h.desc then dica[#dica + 1] = tostring(h.desc) end
    if dicaFam then dica[#dica + 1] = dicaFam end
    for i, r in ipairs(h.ranks or {}) do
      if i > 6 then break end
      local p = r.prof and r.prof[1]
      dica[#dica + 1] = "Rank " .. tostring(r.r) .. ": pet " .. tostring(r.pet) .. (r.pt and (", " .. r.pt .. " TP") or "")
        .. (p and (", " .. tostring(p.n) .. " (" .. tostring(p.nv) .. ")") or "")
    end
    linhas[#linhas + 1] = {
      celulas = { { s = nome, icone = iconeRank1(h) }, quem, { s = faixa(rmin, rmax), numero = true },
        { s = faixa(pmin, pmax), numero = true } },
      dica = dica,
    }
  end
  b[#b + 1] = { t = "tabela", id = "fam:habilidades:tab", limite = 6,
    colunas = { { s = "Ability", largura = 150 }, { s = "Learned by", largura = 130 },
      { s = "Ranks", largura = 70, alinha = "centro" }, { s = "Pet levels", largura = 90, alinha = "centro" } },
    linhas = linhas }
end

local function detalheTreinador(b, g)
  local nomes = {}
  for _, nome in ipairs(nomesOrdenados(g.habilidades)) do
    if g.habilidades[nome].treinador then nomes[#nomes + 1] = nome end
  end
  b[#b + 1] = { t = "sec", s = "Pet trainer", id = "fam:treinador", qtd = tostring(#nomes) }
  local linhas = {}
  for _, nome in ipairs(nomes) do
    local h = g.habilidades[nome]
    local rmin, rmax = limitesRanks(h)
    local tmin, tmax
    local dica = {}
    if h.desc then dica[#dica + 1] = tostring(h.desc) end
    for _, r in ipairs(h.ranks or {}) do
      if type(r.pt) == "number" then
        if not tmin or r.pt < tmin then tmin = r.pt end
        if not tmax or r.pt > tmax then tmax = r.pt end
      end
      dica[#dica + 1] = "Rank " .. tostring(r.r) .. ": pet " .. tostring(r.pet) .. (r.pt and (", " .. r.pt .. " TP") or "")
    end
    linhas[#linhas + 1] = {
      celulas = { { s = nome, icone = iconeRank1(h) }, { s = faixa(rmin, rmax), numero = true },
        { s = faixa(tmin, tmax), numero = true } },
      dica = dica,
    }
  end
  b[#b + 1] = { t = "tabela", id = "fam:treinador:tab", limite = 6,
    colunas = { { s = "Ability", largura = 170 }, { s = "Ranks", largura = 80, alinha = "centro" },
      { s = "TP", largura = 80, alinha = "centro" } },
    linhas = linhas }
end

function ns.blocosFamilias(b, ctx)
  ctx = ctx or { tudo = false }
  local g = guia()
  if not g then b[#b + 1] = { t = "vazio", s = "Pet guide data not loaded." }; return end
  local lista = {}
  for _, fam in ipairs(g.familias or {}) do lista[#lista + 1] = fam end
  if #lista == 0 then b[#b + 1] = { t = "vazio", s = "No families in the guide." }; return end
  local nomePet = UnitExists and UnitExists("pet") and UnitCreatureFamily and UnitCreatureFamily("pet")
  local famPet = acharFamilia(g, nomePet)
  local itens = {}
  for _, fam in ipairs(lista) do
    itens[#itens + 1] = { id = tostring(fam.nome), s = tostring(fam.nome), sub = fam.papel and tostring(fam.papel) or nil,
      icone = iconeFamilia(fam.nome), marca = (famPet and fam == famPet) and "YOUR PET" or nil }
  end
  itens[#itens + 1] = { id = "@regras", s = "How abilities work", icone = "Interface\\Icons\\INV_Misc_Book_09" }
  itens[#itens + 1] = { id = "@habilidades", s = "All abilities", icone = "Interface\\Icons\\Ability_Hunter_BeastCall" }
  itens[#itens + 1] = { id = "@treinador", s = "Pet trainer", icone = "Interface\\Icons\\Ability_Hunter_BeastTraining" }
  local padrao = famPet and tostring(famPet.nome) or tostring(lista[1].nome)
  local atual = (ns.ui and ns.ui.selecionado) and ns.ui.selecionado("familias", padrao) or padrao
  local achou = false
  for _, it in ipairs(itens) do
    if it.id == atual then achou = true break end
  end
  if not achou then atual = padrao end

  local det = {}
  if atual == "@regras" then
    detalheRegras(det, g, ctx)
  elseif atual == "@habilidades" then
    detalheHabilidades(det, g)
  elseif atual == "@treinador" then
    detalheTreinador(det, g)
  else
    local fam = acharFamilia(g, atual)
    if fam then detalheFamilia(det, g, fam, famPet ~= nil and fam == famPet, ctx) end
  end
  b[#b + 1] = { t = "duas", id = "familias", lista = itens, atual = atual, detalhe = det }
end
