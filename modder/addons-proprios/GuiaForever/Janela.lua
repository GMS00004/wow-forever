-- GuiaForever: janela J, a segunda camada do guia (o "agora" fica no painel Agora.lua).
-- 6 abas (Now, Pet, Talents, Combat, Professions, Help), busca, secoes recolhiveis, a fonte
-- de cada linha no tooltip e a caixa "Show all". Tambem: botao do livro perto do minimapa e
-- tecla J. Os dados vem de Dados.lua, Dicas.lua, Ajuda.lua, Profissoes*.lua e dos modulos
-- Teclas, Zona e Treinadores; as funcoes compartilhadas ficam em `ns`.
-- Contrato: ARQUITETURA.md, secoes 1 e 8.

local _, ns = ...

local LARGURA, ALTURA = 760, 600
local ABAS = {
  { id = "agora", rotulo = "Now" },
  { id = "pet", rotulo = "Pet" },
  { id = "talentos", rotulo = "Talents" },
  { id = "combate", rotulo = "Combat" },
  { id = "profissoes", rotulo = "Professions" },
  { id = "ajuda", rotulo = "Help" },
}
ns.abas = ABAS -- o /guia confere os nomes na hora do comando
-- ids antigos (10 abas) -> ids novos; vale para ns.abrirAba e para o /guia
ns.apelidosAba = {
  nivel = "agora", pets = "pet",
  armas = "combate", rotacao = "combate", teclas = "combate",
  prof = "profissoes", zona = "profissoes", treinos = "profissoes",
  addons = "ajuda",
}
local CINZA, AMARELO = "|cff999999", "|cffffd100"
local VERDE, VERMELHO = "|cff33ff33", "|cffff4040"
local CORES = { vermelho = "|cffe63333", laranja = "|cffff8c1a", amarelo = "|cffffd91a", azul = "|cff4d99ff" }
local ICONE_MAIS, ICONE_MENOS = "Interface\\Buttons\\UI-PlusButton-Up", "Interface\\Buttons\\UI-MinusButton-Up"

local janela, rolagem, conteudo, titulo, caixaBusca, caixaTudo
local botoesAba = {}
local poolTexto, poolBotao, poolLinha, poolCab = {}, {}, {}, {}
local abaAtual
local tudo = false      -- caixa "Show all"
local textoBusca = ""   -- busca ativa (minuscula); "" = sem busca
local seqBusca = 0

local function seguro(fn, ...)
  if type(fn) ~= "function" then return false end
  local n = select("#", ...)
  local args = { ... }
  return xpcall(function() return fn(unpack(args, 1, n)) end, geterrorhandler())
end

-- Blocos: { t = "texto", s } | { t = "cab", s, id, resumo, aberta, nivel }
-- | { t = "linha", s, fonte, dica } | { t = "botao", s, f } | { t = "espaco" }
local function T(b, s) b[#b + 1] = { t = "texto", s = s } end
local function cab(b, s) T(b, " "); T(b, ns.COR .. s .. ns.FIM) end
ns.blocoTexto, ns.blocoCabecalho = T, cab
ns.blocoBotao = function(b, s, f) b[#b + 1] = { t = "botao", s = s, f = f } end

-- aberta: false fecha a secao na primeira vez (o dono muda com um clique; fica em GuiaForeverDB.secoes)
local function SEC(b, s, id, aberta, resumo, nivel)
  b[#b + 1] = { t = "cab", s = s, id = id, aberta = aberta, resumo = resumo, nivel = nivel or 1 }
end
local function L(b, s, fonte, dica) b[#b + 1] = { t = "linha", s = s, fonte = fonte, dica = dica } end
local function BT(b, s, f) b[#b + 1] = { t = "botao", s = s, f = f } end
local function ESP(b) b[#b + 1] = { t = "espaco" } end

local function nivelJogador() return UnitLevel("player") or 1 end
local function noIntervalo(e, n) return e.de <= n and n <= e.ate end
local function faixaTxt(e)
  if e.de == e.ate then return "Level " .. e.de end
  return "Levels " .. e.de .. "-" .. e.ate
end

-- ns.relevante (Estado.lua) filtra; sem ele, tudo passa. "Show all" liga ctx.tudo.
local function relevante(e, aba)
  if not ns.relevante then return true end
  return ns.relevante(e, { aba = aba, tudo = tudo })
end

-- tira os codigos de cor para buscar e para o titulo do tooltip
local function limpar(s)
  return (tostring(s):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function acrescentar(b, sub)
  for _, x in ipairs(sub) do b[#b + 1] = x end
end

-- Abas ---------------------------------------------------------------
local construtores = {}

-- Now: o que o painel mostra, mais o que vem a seguir e o que foi escondido.
construtores.agora = function(b)
  local n = nivelJogador()
  local itens = {}
  if ns.agora and ns.agora.itens then
    local ok, r = pcall(ns.agora.itens)
    if ok and type(r) == "table" then itens = r end
  end
  local ocultos = {}
  if ns.agora and ns.agora.ocultos then
    local ok, r = pcall(ns.agora.ocultos)
    if ok and type(r) == "table" then ocultos = r end
  end
  local visiveis, escondidos = {}, {}
  for _, it in ipairs(itens) do
    if ocultos[it.chave] ~= nil and ocultos[it.chave] == tostring(it.texto) then
      escondidos[#escondidos + 1] = it
    else
      visiveis[#visiveis + 1] = it
    end
  end

  SEC(b, "Now (" .. #visiveis .. ")", "agora:itens", true)
  if #visiveis == 0 then L(b, "Nothing needs you right now.") end
  for _, it in ipairs(visiveis) do
    L(b, (CORES[it.cor] or "") .. tostring(it.texto) .. (CORES[it.cor] and ns.FIM or ""), it.fonte, it.dica)
    if type(it.botao) == "table" and type(it.botao.acao) == "function" then
      BT(b, tostring(it.botao.rotulo or "Go"), it.botao.acao)
    end
  end

  -- Coming up: os proximos 2 niveis (talento do plano, magias e teclas que chegam)
  SEC(b, "Coming up (levels " .. (n + 1) .. "-" .. (n + 2) .. ")", "agora:prox", true)
  local prox = {}
  local plano
  if ns.arvore and ns.arvore.plano then
    local ok, r = pcall(ns.arvore.plano)
    if ok and type(r) == "table" then plano = r end
  end
  for l = n + 1, n + 2 do
    local e = plano and plano[l]
    if e then
      local txt = e.tbd and "your pick, sources differ" or tostring(e.texto or e.nome)
      prox[#prox + 1] = { nivel = l, s = "Level " .. l .. ": Talent: " .. txt, fonte = "your build sheet" }
    end
  end
  local d = ns.dicas()
  if d and d.magias then
    for _, e in ipairs(d.magias) do
      if e.nivel and e.nivel > n and e.nivel <= n + 2 and relevante(e, "agora") then
        prox[#prox + 1] = { nivel = e.nivel, s = "Level " .. e.nivel .. ": " .. tostring(e.texto), fonte = e.fonte }
      end
    end
  end
  local teclas = GuiaForeverTeclas and GuiaForeverTeclas[ns.classe()]
  if teclas then
    for _, e in ipairs(teclas) do
      if e.n and e.n > n and e.n <= n + 2 then
        prox[#prox + 1] = { nivel = e.n, s = "Level " .. e.n .. ": Key " .. tostring(e.k) .. " = " .. tostring(e.s), fonte = e.f }
      end
    end
  end
  for i, x in ipairs(prox) do x.ordem = i end
  table.sort(prox, function(a, c)
    if a.nivel ~= c.nivel then return a.nivel < c.nivel end
    return a.ordem < c.ordem
  end)
  if #prox == 0 then L(b, "Nothing new in the next 2 levels from your sources.") end
  for _, x in ipairs(prox) do L(b, x.s, x.fonte) end

  -- Hidden: o que o dono escondeu no painel
  SEC(b, "Hidden", "agora:ocultos", false, #escondidos > 0 and (#escondidos .. " hidden") or nil)
  if #escondidos == 0 then L(b, "Nothing hidden.") end
  for _, it in ipairs(escondidos) do
    L(b, tostring(it.texto), it.fonte, it.dica)
    local chave = it.chave
    BT(b, "Show again", function()
      if ns.agora and ns.agora.mostrar then ns.agora.mostrar(chave) end
      if ns.atualizarJanela then ns.atualizarJanela() end
    end)
  end
end

local FELICIDADE = { [1] = "Unhappy", [2] = "Content", [3] = "Happy" }

construtores.pet = function(b)
  local n = nivelJogador()
  local d = ns.dicas()
  if not d then L(b, "No tips for this class."); return end
  if not (d.pets and #d.pets > 0) and not (d.petTreino and #d.petTreino > 0) then
    L(b, "This class has no pet.")
    return
  end
  local p = ns.estado and ns.estado.pet

  SEC(b, "Your pet", "pet:estado", true)
  if not p or not p.existe then
    L(b, "No pet out.", "game")
  else
    L(b, tostring(p.nome or "Pet") .. (p.nivel and (", level " .. p.nivel) or "") .. (p.morto and " (dead)" or ""), "game")
    if p.felicidade then
      local pct = type(p.danoPct) == "number" and (" (" .. p.danoPct .. "% damage)") or ""
      L(b, "Happiness: " .. (FELICIDADE[p.felicidade] or tostring(p.felicidade)) .. pct, "game")
    end
    if type(p.dieta) == "table" and #p.dieta > 0 then
      local nomes = {}
      for _, v in ipairs(p.dieta) do nomes[#nomes + 1] = tostring(v) end
      L(b, "Diet: " .. table.concat(nomes, ", "), "game")
    end
    if type(p.pontosTotal) == "number" and type(p.pontosUsados) == "number" then
      L(b, "Training points: " .. (p.pontosTotal - p.pontosUsados) .. " free (" .. p.pontosUsados .. " of " .. p.pontosTotal .. " used)", "game")
    end
  end

  if d.petTreino and #d.petTreino > 0 then
    local faltam = 0
    local linhas = {}
    for _, e in ipairs(d.petTreino) do
      local sabe = ns.petConhece and ns.petConhece(e.habilidade) and true or false
      if not sabe and e.de <= n then faltam = faltam + 1 end
      local marca = sabe and (VERDE .. "[v]" .. ns.FIM) or (VERMELHO .. "[x]" .. ns.FIM)
      linhas[#linhas + 1] = { s = marca .. " Level " .. e.de .. ": " .. tostring(e.texto), fonte = e.fonte }
    end
    SEC(b, "Training plan", "pet:treino", faltam > 0, faltam > 0 and (faltam .. " to learn") or "all learned")
    for _, x in ipairs(linhas) do L(b, x.s, x.fonte) end
  end

  if d.pets and #d.pets > 0 then
    SEC(b, "Pet tips", "pet:dicas", true)
    local achou = false
    for _, e in ipairs(d.pets) do
      if relevante(e, "pet") then
        local linha = faixaTxt(e) .. ": " .. tostring(e.texto)
        if noIntervalo(e, n) then linha = ns.COR .. "> " .. ns.FIM .. linha end
        L(b, linha, e.fonte)
        achou = true
      end
    end
    if not achou then L(b, "No pet tips for now. Tick Show all to see the rest.") end
  end
end

construtores.talentos = function(b)
  local dados = ns.dados()
  if not dados then L(b, "No talent guide for this class."); return end
  local n = nivelJogador()
  local livres = ns.pontosLivres()
  local ini = n + 1
  if n >= ns.MIN_NIVEL and (livres == nil or livres > 0) then ini = n end
  if ini < ns.MIN_NIVEL then ini = ns.MIN_NIVEL end

  SEC(b, "Next 5 points", "talentos:prox", true, dados.personagem)
  local k = 0
  for l = ini, ns.MAX_NIVEL do
    if k >= 5 then break end
    local v = dados.ordem[l] or "?"
    local dica = (v == "TBD") and "TBD: the sources differ on this point. See the Open list below." or nil
    L(b, "Level " .. l .. ": " .. v, "your build sheet", dica)
    k = k + 1
  end
  if k == 0 then L(b, "Nothing to show (guide max level).") end

  local d = ns.dicas()
  SEC(b, "Spells (level " .. n .. " to " .. (n + 2) .. ")", "talentos:magias", true)
  local achou = false
  if d and d.magias then
    for _, e in ipairs(d.magias) do
      if e.nivel and e.nivel >= n and e.nivel <= n + 2 and relevante(e, "talentos") then
        L(b, "Level " .. e.nivel .. ": " .. tostring(e.texto), e.fonte)
        achou = true
      end
    end
  end
  if not achou then L(b, "Nothing new in spells from the sources for these levels.") end

  if dados.lei then
    SEC(b, "Core (definitely in)", "talentos:lei", false)
    for _, s in ipairs(dados.lei) do L(b, "- " .. s, "your build sheet") end
  end
  if dados.aberto then
    SEC(b, "Open (owner decides)", "talentos:aberto", false)
    for _, a in ipairs(dados.aberto) do
      L(b, AMARELO .. tostring(a.ponto) .. ns.FIM, "your build sheet")
      for _, o in ipairs(a.opcoes or {}) do L(b, "    " .. tostring(o)) end
      ESP(b)
    end
  end
  if NaowhForever and NaowhForever.OpenTrainingWindow then
    ESP(b)
    BT(b, "Open Naowh planner", function()
      if NaowhForever and NaowhForever.OpenTrainingWindow then
        pcall(NaowhForever.OpenTrainingWindow, nivelJogador(), "spells")
      end
    end)
  end
  ESP(b)
  T(b, CINZA .. "Full order in chat: /guia all" .. ns.FIM)
end

construtores.combate = function(b)
  local n = nivelJogador()
  local d = ns.dicas()
  if not d then L(b, "No tips for this class."); return end

  SEC(b, "Rotation", "combate:rotacao", true, "your range")
  local achou = false
  for _, e in ipairs(d.rotacao or {}) do
    if noIntervalo(e, n) and relevante(e, "combate") then
      L(b, faixaTxt(e) .. ": " .. tostring(e.texto), e.fonte)
      achou = true
    end
  end
  if not achou then L(b, "No source for this range.") end

  SEC(b, "Keys", "combate:teclas", true)
  if ns.blocosTeclas then
    local sub = {}
    local ok = xpcall(function() ns.blocosTeclas(sub) end, geterrorhandler())
    if ok then acrescentar(b, sub) else L(b, "Keys unavailable (see BugSack).") end
  else
    L(b, "Keys unavailable.")
  end

  if d.armas and #d.armas > 0 then
    SEC(b, "Weapons for this range", "combate:armas", true)
    local ach = false
    for _, e in ipairs(d.armas) do
      if noIntervalo(e, n) and relevante(e, "combate") then
        L(b, tostring(e.texto), e.fonte)
        ach = true
      end
    end
    if not ach then L(b, "No source for this range.") end
  end

  if d.atributos and #d.atributos > 0 then
    SEC(b, "Stats", "combate:atributos", true)
    for _, e in ipairs(d.atributos) do
      if relevante(e, "combate") then L(b, tostring(e.texto), e.fonte) end
    end
  end

  if d.notas and #d.notas > 0 then
    SEC(b, "Notes", "combate:notas", false)
    for _, e in ipairs(d.notas) do
      if relevante(e, "combate") then L(b, tostring(e.texto), e.fonte) end
    end
  end
end

construtores.profissoes = function(b)
  SEC(b, "My professions", "prof:minhas", true)
  local lista = ns.minhasProfissoes()
  if #lista == 0 then
    L(b, "No profession with a leveling route learned yet. Where to learn: Trainers, below.")
  end
  for _, pr in ipairs(lista) do
    local idx = ns.indicePasso(pr.tab, pr.pericia)
    L(b, ns.COR .. ns.linhaProf(pr, idx) .. ns.FIM, pr.tab.fonte)
    local prox = pr.tab.passos[idx + 1]
    if prox then L(b, "   Next (" .. prox.de .. "-" .. prox.ate .. "): " .. tostring(prox.texto), pr.tab.fonte) end
  end

  SEC(b, "Zone", "prof:zona", true)
  if ns.blocosZona then
    local sub = {}
    local ok = xpcall(function() ns.blocosZona(sub) end, geterrorhandler())
    if ok then acrescentar(b, sub) else L(b, "Zone unavailable (see BugSack).") end
  else
    L(b, "Zone tab unavailable.")
  end

  SEC(b, "Trainers", "prof:treinos", false)
  if ns.blocosTreinos then
    local sub = {}
    local ok = xpcall(function() ns.blocosTreinos(sub) end, geterrorhandler())
    if ok then acrescentar(b, sub) else L(b, "Trainers unavailable (see BugSack).") end
  else
    L(b, "Trainers unavailable.")
  end
end

-- Aba Addons (dono, 2026-11-06, noite: "nao estou sabendo acessar todas as
-- funcionalidades"). Os comandos foram lidos no codigo de cada addon instalado
-- (SLASH_ e RegisterChatCommand) na mesma noite. Nome, o que faz, como abrir.
-- 2026-11-07 (1.0.1): marcas de recompensa do RestedXP, pular magia no Naowh e
-- precos no tooltip do Auctionator, lidos no codigo instalado a partir do video
-- do Studen Albatroz (comum\fontes\economia\studen-ouro-leveling.md).
-- 2026-11-07 (noite): Forever Guide 1.38.5, comandos lidos no codigo instalado
-- (Dungeons.lua:2906 /fguide, ItemSearch.lua:1816 /flfind).
local ADDONS = {
  { "GuiaForever", "the guide: your next steps, pet, talents, combat and professions", "J, /guia or the book button by the minimap" },
  { "Naowh Training Planner", "what to train now, its cost and the nearest trainer; right-click a spell to skip it and see the gold you save", "/nftraining" },
  { "Naowh Forever", "options of the Naowh modules; its profession window replaces the game's", "/nf" },
  { "RestedXP Guides", "the step-by-step route (window at the top left); when a quest lets you choose a reward, a vendor icon marks the one that sells for most and the RestedXP logo marks its upgrade pick (it may disagree with Pawn)", "/rxp" },
  { "Questie", "quests, trainers and services on the map and minimap", "M (map); /questie for options" },
  { "Forever Quests", "marks Forever's new quests in Questie's tooltips", "automatic" },
  { "Baganator", "all your bags in one window, with search", "B" },
  { "Syndicator", "your other characters' items in Baganator's search", "automatic" },
  { "Auctionator", "prices and quick selling at the auction house; item tooltips show the vendor and the auction price (auction only for items it has already seen)", "opens with the auctioneer; /atr" },
  { "TomTom", "arrow to a map coordinate", "/way 57 61" },
  { "GatherMate2", "gathering nodes you have already seen, on the map", "M (map); /gathermate" },
  { "Leatrix Plus", "sells junk, repairs and loots fast (already on)", "/ltp" },
  { "Pawn", "green arrow in the tooltip when an item is an upgrade", "hover an item; /pawn" },
  { "Deadly Boss Mods", "boss alerts and timers", "automatic in dungeons; /dbm" },
  { "Forever Guide", "dungeon loot tables (bosses with 3D model, trash, drop chances), where any item drops, rares with alerts", "/fguide (or the compass button); /flfind <item>" },
  { "BugSack", "addon errors", "/bugsack" },
  { "UIForever", "this layout, keys, rotation cooldown bar under your character, number fonts", "automatic on login" },
}

construtores.ajuda = function(b)
  SEC(b, "Questions", "ajuda:perguntas", true)
  local lista = GuiaForeverAjuda and GuiaForeverAjuda[ns.classe()]
  if type(lista) ~= "table" or #lista == 0 then
    L(b, "No questions answered for this class yet.")
  else
    for i, q in ipairs(lista) do
      if type(q) == "table" and q.pergunta then
        SEC(b, tostring(q.pergunta), "ajuda:q:" .. tostring(q.id or i), false, nil, 2)
        for _, ln in ipairs(q.linhas or {}) do
          if type(ln) == "table" and ln.texto then L(b, tostring(ln.texto), ln.fonte) end
        end
      end
    end
  end

  SEC(b, "Addons", "ajuda:addons", false, "what each one gives you and how to open it")
  for _, a in ipairs(ADDONS) do
    T(b, AMARELO .. a[1] .. ns.FIM .. ": " .. a[2])
    T(b, CINZA .. "   Open: " .. ns.FIM .. a[3])
  end

  SEC(b, "Colors and signs", "ajuda:cores", false)
  L(b, CORES.vermelho .. "Red" .. ns.FIM .. ": something is hurting you right now.")
  L(b, CORES.laranja .. "Orange" .. ns.FIM .. ": an errand in town.")
  L(b, CORES.amarelo .. "Yellow" .. ns.FIM .. ": do it when convenient.")
  L(b, CORES.azul .. "Blue" .. ns.FIM .. ": information.")
  ESP(b)
  L(b, AMARELO .. "NOW" .. ns.FIM .. " (talent tree): the next point to spend.")
  L(b, AMARELO .. "PLAN" .. ns.FIM .. " (pet trainer window): the next pet ability to train.")
  L(b, AMARELO .. "ALL" .. ns.FIM .. " (talent tree): the talent is in the Core list (definitely in).")
  L(b, AMARELO .. "?" .. ns.FIM .. " (talent tree): the sources differ; the Open list shows each source's pick.")
  L(b, AMARELO .. "Numbers" .. ns.FIM .. " (talent tree): the levels when the plan takes the remaining ranks; a check means done.")
end

-- Busca ----------------------------------------------------------------
local function casa(s, q)
  if s == nil then return false end
  return string.find(string.lower(limpar(s)), q, 1, true) ~= nil
end

local function rodar(id, b)
  local fn = construtores[id] or construtores.agora
  local ok = xpcall(function() fn(b) end, geterrorhandler())
  if not ok then T(b, "This tab hit an error (see BugSack).") end
end

-- monta os blocos de todas as abas e fica so com as linhas que contem `q`, agrupadas por aba
local function blocosBusca(q)
  local saida = {}
  for _, aba in ipairs(ABAS) do
    local sub = {}
    rodar(aba.id, sub)
    local achados, secao, emitida = {}, nil, false
    for _, bl in ipairs(sub) do
      if bl.t == "cab" then
        secao, emitida = bl, false
        if casa(bl.s, q) then
          achados[#achados + 1] = { t = "texto", s = CINZA .. limpar(bl.s) .. ns.FIM }
          emitida = true
        end
      elseif bl.t == "texto" or bl.t == "linha" then
        if casa(bl.s, q) or casa(bl.fonte, q) then
          if secao and not emitida then
            achados[#achados + 1] = { t = "texto", s = CINZA .. limpar(secao.s) .. ns.FIM }
            emitida = true
          end
          achados[#achados + 1] = bl
        end
      end
    end
    if #achados > 0 then
      saida[#saida + 1] = { t = "texto", s = " " }
      saida[#saida + 1] = { t = "texto", s = ns.COR .. aba.rotulo .. ns.FIM }
      acrescentar(saida, achados)
    end
  end
  if #saida == 0 then saida[1] = { t = "texto", s = "No match for \"" .. q .. "\"." } end
  return saida
end

-- Desenho ------------------------------------------------------------
-- Fontes da janela (CreateFont): texto 14 e titulos 16. Sem CreateFont (ou se falhar), a da Blizzard.
local fonteT, fonteTit = "GameFontHighlightSmall", "GameFontNormal"
local fontesProntas = false
local function criarFontes()
  if fontesProntas then return end
  fontesProntas = true
  if not (CreateFont and GameFontHighlightSmall and GameFontNormal) then return end
  pcall(function()
    local f = _G.GuiaForeverFonteTexto or CreateFont("GuiaForeverFonteTexto")
    f:SetFontObject(GameFontHighlightSmall)
    local arq, _, flags = f:GetFont()
    if arq then f:SetFont(arq, 14, flags) end
    if _G.GuiaForeverFonteTexto then fonteT = "GuiaForeverFonteTexto" end
  end)
  pcall(function()
    local f = _G.GuiaForeverFonteTitulo or CreateFont("GuiaForeverFonteTitulo")
    f:SetFontObject(GameFontNormal)
    local arq, _, flags = f:GetFont()
    if arq then f:SetFont(arq, 16, flags) end
    if _G.GuiaForeverFonteTitulo then fonteTit = "GuiaForeverFonteTitulo" end
  end)
end

local atualizar -- definida adiante

local function secaoAberta(bl)
  local db = GuiaForeverDB and GuiaForeverDB.secoes
  local v = db and db[bl.id]
  if v == nil then return bl.aberta ~= false end
  return v and true or false
end

local function alternarSecao(id, aberta)
  if not GuiaForeverDB then return end
  GuiaForeverDB.secoes = GuiaForeverDB.secoes or {}
  GuiaForeverDB.secoes[id] = not aberta
  atualizar()
end

local function tooltipLinha(dono)
  local fonte, dica = dono.fonte, dono.dica
  if fonte == nil and dica == nil then return end
  GameTooltip:SetOwner(dono, "ANCHOR_RIGHT")
  GameTooltip:SetText(limpar(dono.texto or ""), 1, 1, 1, 1, true)
  if type(dica) == "string" then
    GameTooltip:AddLine(dica, 0.9, 0.9, 0.9, true)
  elseif type(dica) == "table" then
    for _, l in ipairs(dica) do GameTooltip:AddLine(tostring(l), 0.9, 0.9, 0.9, true) end
  end
  if fonte ~= nil then GameTooltip:AddLine("Source: " .. tostring(fonte), 0.6, 0.6, 0.6, true) end
  GameTooltip:Show()
end

local function novoCab(i)
  local c = CreateFrame("Button", nil, conteudo)
  c:SetHeight(24)
  c:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  local ic = c:CreateTexture(nil, "ARTWORK")
  ic:SetSize(16, 16)
  ic:SetPoint("LEFT", c, "LEFT", 2, 0)
  local fs = c:CreateFontString(nil, "OVERLAY", fonteTit)
  fs:SetPoint("LEFT", ic, "RIGHT", 6, 0)
  fs:SetJustifyH("LEFT")
  c.icone, c.rotulo = ic, fs
  c:SetScript("OnClick", function(self) seguro(alternarSecao, self.id, self.aberta) end)
  poolCab[i] = c
  return c
end

local function novaLinha(i)
  local f = CreateFrame("Frame", nil, conteudo)
  local hl = f:CreateTexture(nil, "BACKGROUND")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.08)
  hl:Hide()
  local fs = f:CreateFontString(nil, "OVERLAY", fonteT)
  fs:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -1)
  fs:SetJustifyH("LEFT")
  fs:SetJustifyV("TOP")
  f.hl, f.fs = hl, fs
  f:SetScript("OnEnter", function(self)
    if self.fonte == nil and self.dica == nil then return end
    self.hl:Show()
    seguro(tooltipLinha, self)
  end)
  f:SetScript("OnLeave", function(self)
    self.hl:Hide()
    GameTooltip:Hide()
  end)
  poolLinha[i] = f
  return f
end

local function novoBotao(i)
  local bt = CreateFrame("Button", nil, conteudo, "UIPanelButtonTemplate")
  bt:SetSize(260, 22)
  poolBotao[i] = bt
  return bt
end

local function novoTexto(i)
  local fs = conteudo:CreateFontString(nil, "OVERLAY", fonteT)
  fs:SetJustifyH("LEFT")
  fs:SetJustifyV("TOP")
  poolTexto[i] = fs
  return fs
end

local function desenhar(blocos)
  criarFontes()
  local y = -4
  local larg = LARGURA - 60
  local nT, nB, nL, nC = 0, 0, 0, 0
  local recuo = 4
  local pula = nil -- nivel da secao recolhida que esconde os blocos seguintes
  for _, bl in ipairs(blocos) do
    local t = bl.t
    if t == "cab" then
      local niv = bl.nivel or 1
      if not (pula and niv > pula) then
        pula = nil
        local id = bl.id or ("cab:" .. tostring(bl.s))
        local aberta = secaoAberta({ id = id, aberta = bl.aberta })
        nC = nC + 1
        local c = poolCab[nC] or novoCab(nC)
        local x = 4 + 14 * (niv - 1)
        if y < -4 then y = y - 6 end
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", conteudo, "TOPLEFT", x, y)
        c:SetSize(larg - x, 24)
        c.id, c.aberta = id, aberta
        c.icone:SetTexture(aberta and ICONE_MENOS or ICONE_MAIS)
        local s = tostring(bl.s)
        if not aberta and bl.resumo then s = s .. CINZA .. "   " .. tostring(bl.resumo) .. ns.FIM end
        c.rotulo:SetText(s)
        c:Show()
        y = y - 26
        recuo = x + 18
        if not aberta then pula = niv end
      end
    elseif pula then
      -- dentro de uma secao recolhida: nao desenha
    elseif t == "linha" then
      nL = nL + 1
      local f = poolLinha[nL] or novaLinha(nL)
      local w = larg - recuo
      f.texto, f.fonte, f.dica = bl.s, bl.fonte, bl.dica
      f:EnableMouse(bl.fonte ~= nil or bl.dica ~= nil)
      f.hl:Hide()
      f.fs:SetWidth(w - 4)
      f.fs:SetText(tostring(bl.s))
      local h = (f.fs:GetStringHeight() or 14) + 3
      f:ClearAllPoints()
      f:SetPoint("TOPLEFT", conteudo, "TOPLEFT", recuo, y)
      f:SetSize(w, h)
      f:Show()
      y = y - h - 2
    elseif t == "botao" then
      nB = nB + 1
      local bt = poolBotao[nB] or novoBotao(nB)
      bt:ClearAllPoints()
      bt:SetPoint("TOPLEFT", conteudo, "TOPLEFT", recuo, y)
      bt:SetText(tostring(bl.s))
      local f = bl.f
      bt:SetScript("OnClick", function() seguro(f) end)
      bt:Show()
      y = y - 26
    elseif t == "espaco" then
      y = y - 8
    else
      nT = nT + 1
      local fs = poolTexto[nT] or novoTexto(nT)
      fs:ClearAllPoints()
      fs:SetPoint("TOPLEFT", conteudo, "TOPLEFT", recuo, y)
      fs:SetWidth(larg - recuo)
      fs:SetText(tostring(bl.s))
      fs:Show()
      y = y - (fs:GetStringHeight() or 14) - 3
    end
  end
  for i = nT + 1, #poolTexto do poolTexto[i]:Hide() end
  for i = nB + 1, #poolBotao do poolBotao[i]:Hide() end
  for i = nL + 1, #poolLinha do poolLinha[i]:Hide() end
  for i = nC + 1, #poolCab do poolCab[i]:Hide() end
  conteudo:SetHeight(math.max(-y + 6, 10))
end

local function marcarAba()
  for id, bt in pairs(botoesAba) do
    if id == abaAtual and textoBusca == "" then bt:LockHighlight() else bt:UnlockHighlight() end
  end
end

atualizar = function()
  if not janela or not janela:IsShown() then return end
  local blocos
  if textoBusca ~= "" then
    blocos = blocosBusca(textoBusca)
  else
    blocos = {}
    rodar(abaAtual, blocos)
  end
  desenhar(blocos)
  local d = ns.dicas()
  titulo:SetText("GuiaForever" .. (d and d.personagem and (" - " .. d.personagem) or ""))
  marcarAba()
end
ns.atualizarJanela = atualizar

local function salvarPosicao()
  local p, _, rp, x, y = janela:GetPoint()
  GuiaForeverDB.pos = { p, rp, x, y }
end

local function resolverAba(id)
  if construtores[id] then return id end
  return ns.apelidosAba[id] or "agora"
end

local function limparBusca()
  textoBusca = ""
  if caixaBusca and caixaBusca:GetText() ~= "" then caixaBusca:SetText("") end
end

local function aoMudarBusca(self)
  local q = string.lower(strtrim and strtrim(self:GetText() or "") or (self:GetText() or ""))
  if string.len(q) < 2 then q = "" end
  if q == textoBusca then return end
  textoBusca = q
  if rolagem then rolagem:SetVerticalScroll(0) end
  atualizar()
end

local function criarJanela()
  if janela then return end
  criarFontes()
  GuiaForeverDB = GuiaForeverDB or {}
  janela = CreateFrame("Frame", "GuiaForeverJanela", UIParent, "BackdropTemplate")
  janela:SetSize(LARGURA, ALTURA)
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
  titulo = janela:CreateFontString(nil, "OVERLAY", fonteTit)
  titulo:SetPoint("TOPLEFT", 14, -12)
  local fechar = CreateFrame("Button", nil, janela, "UIPanelCloseButton")
  fechar:SetPoint("TOPRIGHT", -2, -2)

  -- busca (a partir de 2 letras mostra as linhas de todas as abas que contem o texto)
  caixaBusca = CreateFrame("EditBox", nil, janela, "SearchBoxTemplate")
  caixaBusca:SetSize(220, 22)
  caixaBusca:SetPoint("TOPRIGHT", janela, "TOPRIGHT", -40, -10)
  caixaBusca:SetAutoFocus(false)
  if caixaBusca.Instructions and caixaBusca.Instructions.SetText then
    caixaBusca.Instructions:SetText("Search")
  end
  caixaBusca:HookScript("OnTextChanged", function(self)
    seqBusca = seqBusca + 1
    local meu = seqBusca
    if C_Timer and C_Timer.After then
      C_Timer.After(0.25, function()
        if meu == seqBusca then seguro(aoMudarBusca, self) end
      end)
    else
      seguro(aoMudarBusca, self)
    end
  end)
  caixaBusca:HookScript("OnEscapePressed", function(self)
    self:SetText("")
    self:ClearFocus()
  end)
  caixaBusca:HookScript("OnEnterPressed", function(self) self:ClearFocus() end)

  local x = 10
  for _, aba in ipairs(ABAS) do
    local bt = CreateFrame("Button", nil, janela, "UIPanelButtonTemplate")
    bt:SetSize(100, 24)
    bt:SetPoint("TOPLEFT", janela, "TOPLEFT", x, -38)
    bt:SetText(aba.rotulo)
    local id = aba.id
    bt:SetScript("OnClick", function()
      abaAtual = id
      GuiaForeverDB.aba = id
      limparBusca()
      if rolagem then rolagem:SetVerticalScroll(0) end
      atualizar()
    end)
    botoesAba[id] = bt
    x = x + 102
  end

  -- Show all: volta PvP, grupo, fim de jogo e escolha de pet (ctx.tudo)
  caixaTudo = CreateFrame("CheckButton", nil, janela, "UICheckButtonTemplate")
  caixaTudo:SetSize(26, 26)
  caixaTudo:SetPoint("TOPLEFT", janela, "TOPLEFT", x + 12, -37)
  caixaTudo:SetChecked(false)
  local rotuloTudo = caixaTudo:CreateFontString(nil, "OVERLAY", fonteT)
  rotuloTudo:SetPoint("LEFT", caixaTudo, "RIGHT", 2, 0)
  rotuloTudo:SetText("Show all")
  caixaTudo:SetScript("OnClick", function(self)
    tudo = self:GetChecked() and true or false
    seguro(atualizar)
  end)
  caixaTudo:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Show all", 1, 1, 1)
    GameTooltip:AddLine("Also shows PvP, group, end-game and pet-choice tips that are hidden for now.", 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
  end)
  caixaTudo:SetScript("OnLeave", function() GameTooltip:Hide() end)

  rolagem = CreateFrame("ScrollFrame", "GuiaForeverRolagem", janela, "UIPanelScrollFrameTemplate")
  rolagem:SetPoint("TOPLEFT", janela, "TOPLEFT", 10, -70)
  rolagem:SetPoint("BOTTOMRIGHT", janela, "BOTTOMRIGHT", -30, 10)
  conteudo = CreateFrame("Frame", nil, rolagem)
  conteudo:SetSize(LARGURA - 50, 10)
  rolagem:SetScrollChild(conteudo)

  local pos = GuiaForeverDB.pos
  janela:ClearAllPoints()
  if pos and pos[1] then
    janela:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3] or 0, pos[4] or 0)
  else
    janela:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
  janela:SetScript("OnShow", function() seguro(atualizar) end)
  janela:SetScript("OnHide", function()
    tudo = false
    if caixaTudo then caixaTudo:SetChecked(false) end
    if caixaBusca then caixaBusca:ClearFocus() end
    GameTooltip:Hide()
  end)
  if UISpecialFrames then tinsert(UISpecialFrames, "GuiaForeverJanela") end -- Esc fecha
  abaAtual = resolverAba(GuiaForeverDB.aba or "agora")
  janela:Hide()
end

function ns.alternarJanela()
  criarJanela()
  if janela:IsShown() then janela:Hide() else janela:Show() end
end

-- aceita os ids novos e os antigos (ns.apelidosAba)
function ns.abrirAba(id)
  criarJanela()
  id = resolverAba(id)
  abaAtual = id
  GuiaForeverDB.aba = id
  limparBusca()
  rolagem:SetVerticalScroll(0)
  if janela:IsShown() then atualizar() else janela:Show() end
end

-- Atalho de tecla (Bindings.xml) e nomes no menu de teclas.
BINDING_HEADER_GUIAFOREVER = "GuiaForever"
_G["BINDING_NAME_GUIAFOREVER_JANELA"] = "Open/close the guide"
function GuiaForever_AlternarJanela() ns.alternarJanela() end

-- Botao do livro -------------------------------------------------------
local function criarBotao()
  if _G.GuiaForeverBotao then return end
  local bt = CreateFrame("Button", "GuiaForeverBotao", UIParent)
  bt:SetSize(28, 28)
  bt:SetFrameStrata("MEDIUM")
  bt:SetClampedToScreen(true)
  bt:SetMovable(true)
  bt:EnableMouse(true)
  bt:RegisterForDrag("LeftButton")
  bt:RegisterForClicks("LeftButtonUp")
  local icone = bt:CreateTexture(nil, "ARTWORK")
  icone:SetAllPoints()
  icone:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  bt:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  bt:SetScript("OnDragStart", bt.StartMoving)
  bt:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    GuiaForeverDB.botao = { p, rp, x, y }
  end)
  bt:SetScript("OnClick", function() ns.alternarJanela() end)
  bt:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("GuiaForever")
    GameTooltip:AddLine("Click: open/close the guide (J key)", 1, 1, 1)
    GameTooltip:AddLine("Drag to move", 1, 1, 1)
    GameTooltip:Show()
  end)
  bt:SetScript("OnLeave", function() GameTooltip:Hide() end)
  local pos = GuiaForeverDB.botao
  bt:ClearAllPoints()
  if pos and pos[1] then
    bt:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3] or 0, pos[4] or 0)
  elseif Minimap then
    bt:SetPoint("TOPRIGHT", Minimap, "BOTTOMLEFT", -2, -2)
  else
    bt:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -220)
  end
end

-- Tecla J: liga uma vez por personagem, so se estiver livre.
local function ligarTecla()
  if not (GetBindingAction and SetBinding and SaveBindings) then return end
  local chave = ns.chavePersonagem()
  if not chave or ns.emCombate() then return end
  GuiaForeverDB.tecla = GuiaForeverDB.tecla or {}
  if GuiaForeverDB.tecla[chave] then return end
  local ja = GetBindingKey and GetBindingKey("GUIAFOREVER_JANELA")
  if ja then
    GuiaForeverDB.tecla[chave] = { existente = ja }
    return
  end
  local atual = GetBindingAction("J") or ""
  if atual == "" then
    if pcall(SetBinding, "J", "GUIAFOREVER_JANELA") then
      pcall(SaveBindings, (GetCurrentBindingSet and GetCurrentBindingSet()) or 1)
      GuiaForeverDB.tecla[chave] = { ligada = "J" }
      ns.msg("the J key opens/closes the guide (undo: /guia key undo).")
    end
  else
    GuiaForeverDB.tecla[chave] = { ocupada = atual }
    ns.msg("the J key is already bound to " .. atual .. "; open the guide with the book button or /guia, "
      .. "or pick a key in Options > Key Bindings > AddOns > GuiaForever.")
  end
end

function ns.desfazerTecla()
  local chave = ns.chavePersonagem()
  local r = chave and GuiaForeverDB.tecla and GuiaForeverDB.tecla[chave]
  if not r or not r.ligada then ns.msg("key: nothing to undo for this character."); return end
  if ns.emCombate() then ns.msg("key: in combat, try again out of combat."); return end
  if GetBindingAction(r.ligada) == "GUIAFOREVER_JANELA" then
    pcall(SetBinding, r.ligada)
    pcall(SaveBindings, (GetCurrentBindingSet and GetCurrentBindingSet()) or 1)
  end
  GuiaForeverDB.tecla[chave] = { desfeito = true }
  ns.msg("key " .. r.ligada .. " released (the book button and /guia still work).")
end

table.insert(ns.aoEntrar, ligarTecla)

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  GuiaForeverDB = GuiaForeverDB or {}
  criarBotao()
end)
