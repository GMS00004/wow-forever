-- GuiaForever: construtores das abas da janela J (1.2), mais ns.abasEstado e ns.abaVisivel.
-- Contrato: ARQUITETURA.md, secoes 11.1 a 11.4. Cada construtor so devolve blocos; o Visual.lua desenha.
-- Curadoria: a janela nunca mostra a fonte (C1); a aba comeca pelo que da para fazer agora, o resto
-- fica recolhido ou a um clique (C3, C4); sem "Show all", so o relevante e o do nivel atual ou proximo (C7).

local _, ns = ...
ns.abasConstrutores = ns.abasConstrutores or {}
local AB = ns.abasConstrutores

local ICONE_PADRAO = "Interface\\Icons\\Ability_Marksmanship"
local FONTES_TEXTO = { "Method", "Kargoz", "MetaGoblin", "DoubleZug", "Gladius", "LudiDeo",
                       "Perfect Gaming Weather", "Deadmanfred", "Jurdi", "DwarfLord" }

-- Utilidades --------------------------------------------------------------------------------

local function nivelJogador(ctx)
  return (ctx and ctx.nivel) or (UnitLevel and UnitLevel("player")) or 1
end

local function add(b, bloco) b[#b + 1] = bloco end

local function sec(b, s, id, aberta, qtd, limite)
  add(b, { t = "sec", s = s, id = id, aberta = aberta, qtd = qtd, limite = limite })
end

local function vazio(b, s) add(b, { t = "vazio", s = s }) end

-- tira o nome da fonte que sobrar dentro de um texto de dados (C1)
local function semFonte(s)
  s = tostring(s or "")
  for _, n in ipairs(FONTES_TEXTO) do
    s = s:gsub("^" .. n .. ":%s*", "")
    s = s:gsub("%s*%(" .. n .. "[^%)]*%)", "")
    s = s:gsub(",%s*" .. n .. "%)", ")")
  end
  return s
end

local function cortar(s, max)
  if #s <= max then return s end
  local c = s:sub(1, max - 3)
  local ate = c:match("^(.*)%s+%S*$")
  if ate and #ate > max / 2 then c = ate end
  return c .. "..."
end

-- devolve s (ate maxS), sub (ate maxSub) e dica (o texto inteiro, quando foi cortado)
local function dividir(texto, maxS, maxSub)
  texto = semFonte(texto)
  maxS = maxS or 60
  maxSub = maxSub or 80
  if #texto <= maxS then return texto, nil, nil end
  local ant, resto = texto:match("^(.-):%s+(.+)$")
  if ant and #ant >= 12 and #ant <= maxS then return ant, cortar(resto, maxSub), texto end
  return cortar(texto, maxS), nil, texto
end

-- passo de roteiro de profissao -> receita, quantidade, materiais. Formatos das fontes:
-- "Embossed Leather Gloves (15x): 45 Light Leather, 15 Coarse Thread" e
-- "Smoked Bear Meat: 35 crafts with 35 Bear Meat". Outro formato (coleta: "Herbs: ...")
-- volta inteiro como receita, sem quantidade nem materiais.
local function partesPasso(texto)
  texto = semFonte(texto)
  local receita, qtd, mats = texto:match("^(.-)%s*%((%d+)x%):%s*(.+)$")
  if receita then return receita, qtd, mats end
  receita, qtd, mats = texto:match("^(.-):%s*(%d+) crafts with%s+(.+)$")
  if receita then return receita, qtd, mats end
  return texto, nil, nil
end

-- faixas de treino das profissoes (teto de pericia de cada uma)
local FAIXAS_PROF = {
  { nome = "Apprentice", de = 1, ate = 75 },
  { nome = "Journeyman", de = 75, ate = 150 },
  { nome = "Expert", de = 150, ate = 225 },
  { nome = "Artisan", de = 225, ate = 300 },
}

-- "45 Light Leather, 15 Coarse Thread" ou "25 Crawler Meat + 25 Mild Spices" -> { { nome, qtd } }.
-- O que esta entre parenteses (alternativa, "quantity unknown") fica de fora da soma.
local function lerMateriais(mats)
  local lista = {}
  local limpo = (tostring(mats or ""):gsub("%b()", ""))
  for parte in string.gmatch(limpo .. ",", "([^,%+]+)[,%+]") do
    local q, nome = parte:match("^%s*(%d+)%s+(.-)%s*$")
    if q and nome ~= "" then lista[#lista + 1] = { nome = nome, qtd = tonumber(q) } end
  end
  return lista
end

-- Soma os materiais dos passos de cada faixa (o passo entra na faixa em que comeca). Na faixa
-- atual conta so o que falta: os passos que terminam acima da pericia (o passo em que voce esta
-- conta inteiro). Faixas ja feitas so com "Show all". Cada faixa: { nome, faixa, aberta, linhas },
-- com os materiais em pares (quantidade e nome, duas vezes por linha).
local function totaisPorFaixa(passos, pericia, tudo)
  local saida = {}
  local abertas = 0
  for _, f in ipairs(FAIXAS_PROF) do
    if tudo or pericia < f.ate then
      local atual = pericia >= f.de and pericia < f.ate
      local soma, ordem = {}, {}
      for _, p in ipairs(passos) do
        if p.de >= f.de and p.de < f.ate and (tudo or not atual or p.ate > pericia) then
          local _, _, mats = partesPasso(p.texto)
          for _, m in ipairs(lerMateriais(mats)) do
            if not soma[m.nome] then soma[m.nome] = 0; ordem[#ordem + 1] = m.nome end
            soma[m.nome] = soma[m.nome] + m.qtd
          end
        end
      end
      if #ordem > 0 then
        local linhas = {}
        for i = 1, #ordem, 2 do
          local a, c = ordem[i], ordem[i + 1]
          linhas[#linhas + 1] = { celulas = {
            { s = tostring(soma[a]), numero = true }, a,
            c and { s = tostring(soma[c]), numero = true } or "", c or "",
          } }
        end
        local faixa = (atual and not tudo) and (pericia .. "-" .. f.ate .. " (from your skill)") or (f.de .. "-" .. f.ate)
        local futura = pericia < f.de
        if futura then abertas = abertas + 1 end
        saida[#saida + 1] = {
          nome = f.nome, faixa = faixa, linhas = linhas,
          -- a faixa atual e a proxima abrem; as outras ficam recolhidas
          aberta = atual or (futura and abertas <= 1) or false,
        }
      end
    end
  end
  return saida
end

local function faixaTxt(e)
  if e.de == e.ate then return tostring(e.de) end
  return tostring(e.de) .. "-" .. tostring(e.ate)
end

local function noIntervalo(e, n) return e.de <= n and n <= e.ate end

local function relev(e, aba, ctx)
  if not ns.relevante then return true end
  return ns.relevante(e, { aba = aba, tudo = ctx and ctx.tudo })
end

local function temTag(e, tag)
  if type(e.tags) ~= "table" then return false end
  for _, t in ipairs(e.tags) do if t == tag then return true end end
  return false
end

-- ordena por prio (1 primeiro) mantendo a ordem original dentro da mesma prio
local function porPrio(lista)
  local r = {}
  for i, e in ipairs(lista) do r[i] = { e = e, i = i } end
  table.sort(r, function(a, c)
    local pa, pc = a.e.prio or 2, c.e.prio or 2
    if pa ~= pc then return pa < pc end
    return a.i < c.i
  end)
  local saida = {}
  for i, x in ipairs(r) do saida[i] = x.e end
  return saida
end

local function abrir(ctx, aba, sub)
  if ctx and ctx.abrir then ctx.abrir(aba, sub)
  elseif ns.abrirAba then ns.abrirAba(aba, sub) end
end

local function atualizar(ctx)
  if ctx and ctx.atualizar then ctx.atualizar()
  elseif ns.atualizarJanela then ns.atualizarJanela() end
end

-- chama um modulo irmao (regra 3): se faltar ou der erro, a aba mostra um vazio em vez de quebrar
local function chamar(b, nome, ctx, msgFalta)
  local fn = ns[nome]
  if type(fn) ~= "function" then vazio(b, msgFalta); return end
  local sub = {}
  local ok = xpcall(function() fn(sub, ctx) end, geterrorhandler())
  if ok then
    for _, x in ipairs(sub) do b[#b + 1] = x end
  else
    vazio(b, msgFalta .. " (see BugSack)")
  end
end

local function primeiraLinha(d)
  if type(d) == "table" then d = d[1] end
  if type(d) ~= "string" then return nil end
  d = semFonte(d)
  -- "Natural Armor: Natural Armor: train it..." (rotulo repetido pelo provedor) vira um so
  d = d:gsub("^(.-):%s*%1:%s*", "%1: ")
  if #d > 80 then return nil end
  return d
end

-- Icone do talento: C_Traits -> spellID. Cache por nome; reserva fixa (tudo em pcall).
local mapaTalentos = nil
local iconeCache = {}

local function carregarTalentos()
  if mapaTalentos then return mapaTalentos end
  local mapa, n = {}, 0
  pcall(function()
    local cfg = C_ClassTalents.GetActiveConfigID()
    if not cfg then return end
    local info = C_Traits.GetConfigInfo(cfg)
    local arvore = info and info.treeIDs and info.treeIDs[1]
    if not arvore then return end
    for _, nodeID in ipairs(C_Traits.GetTreeNodes(arvore) or {}) do
      local no = C_Traits.GetNodeInfo(cfg, nodeID)
      for _, entradaID in ipairs((no and no.entryIDs) or {}) do
        local ent = C_Traits.GetEntryInfo(cfg, entradaID)
        local def = ent and ent.definitionID and C_Traits.GetDefinitionInfo(ent.definitionID)
        if def and def.spellID then
          local nome = ns.nomeMagia and ns.nomeMagia(def.spellID)
          if type(nome) == "string" then mapa[string.lower(nome)] = def.spellID; n = n + 1 end
          if type(def.overrideName) == "string" then mapa[string.lower(def.overrideName)] = def.spellID; n = n + 1 end
        end
      end
    end
  end)
  if n > 0 then mapaTalentos = mapa end -- vazio: tenta de novo na proxima vez
  return mapa
end

local function iconeTalento(nome)
  if type(nome) ~= "string" then return ICONE_PADRAO end
  local k = string.lower(nome)
  if iconeCache[k] then return iconeCache[k] end
  local id = carregarTalentos()[k]
  if id then iconeCache[k] = id; return id end
  return ICONE_PADRAO
end

-- Now ---------------------------------------------------------------------------------------

AB.agora = function(b, ctx)
  local n = nivelJogador(ctx)
  local itens, ocultos = {}, {}
  if ns.agora and ns.agora.itens then
    local ok, r = pcall(ns.agora.itens)
    if ok and type(r) == "table" then itens = r end
  end
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

  sec(b, "Now", "agora:itens", nil, #visiveis)
  if #visiveis == 0 then vazio(b, "Nothing needs you right now.") end
  for _, it in ipairs(visiveis) do
    local s, sub0, dica0 = dividir(it.texto, 60, 80)
    local sub = primeiraLinha(it.dica) or sub0
    local dica = it.dica
    if dica0 and not dica then dica = dica0 end
    local card = { t = "card", cor = it.cor, icone = it.icone, s = s, sub = sub, dica = dica }
    -- a tecla de um aviso de tecla nova ("teclas:<k>:<nivel>:<i>") vira a tecla desenhada
    local k = type(it.chave) == "string" and it.chave:match("^teclas:(.-):%d+:%d+$")
    if k then card.tecla = k end
    if type(it.botao) == "table" and type(it.botao.acao) == "function" then
      card.botao = { rotulo = tostring(it.botao.rotulo or "Go"), acao = it.botao.acao }
    end
    if it.aba then
      local aba = it.aba
      card.aoClicar = function() abrir(ctx, aba) end
    end
    add(b, card)
  end

  -- Coming up: os proximos 2 niveis (5 com "Show all")
  local ate = n + ((ctx and ctx.tudo) and 5 or 2)
  local prox = {}
  local plano
  if ns.arvore and ns.arvore.plano then
    local ok, r = pcall(ns.arvore.plano)
    if ok and type(r) == "table" then plano = r end
  end
  for l = n + 1, ate do
    local e = plano and plano[l]
    if e then
      local it = { nivel = l }
      local rs, rsub, rdica
      if e.opcoes and ns.arvore and ns.arvore.resumoOpcoes then
        local ok, a, b2, c2 = pcall(ns.arvore.resumoOpcoes, e)
        if ok then rs, rsub, rdica = a, b2, c2 end
      end
      if rs then
        it.s, it.sub, it.dica = cortar(semFonte("Talent: " .. rs), 60), rsub, rdica
        it.icone = iconeTalento(e.opcoes[1] and e.opcoes[1].nome)
      elseif e.tbd then
        it.s, it.icone = "Talent: your pick, sources differ", ICONE_PADRAO
        it.dica = "The sources differ on this point. Open the Talents tab for the options."
      else
        local s, sub, dica = dividir("Talent: " .. tostring(e.texto or e.nome))
        it.s, it.sub, it.dica, it.icone = s, sub, dica, iconeTalento(e.nome)
      end
      prox[#prox + 1] = it
    end
  end
  local d = ns.dicas and ns.dicas()
  if d and d.magias then
    for _, e in ipairs(d.magias) do
      if e.nivel and e.nivel > n and e.nivel <= ate and relev(e, "agora", ctx) then
        local s, sub, dica = dividir("New spell: " .. tostring(e.texto))
        prox[#prox + 1] = { nivel = e.nivel, s = s, sub = sub, dica = dica, icone = e.id or ICONE_PADRAO }
      end
    end
  end
  if d and type(d.marcos) == "table" then
    for _, e in ipairs(d.marcos) do
      if type(e) == "table" and type(e.nivel) == "number" and e.nivel > n and e.nivel <= ate and e.texto then
        local s, sub, dica = dividir("Milestone: " .. tostring(e.texto))
        prox[#prox + 1] = { nivel = e.nivel, s = s, sub = sub, dica = dica, icone = e.id or ICONE_PADRAO }
      end
    end
  end
  local teclas = GuiaForeverTeclas and ns.classe and GuiaForeverTeclas[ns.classe()]
  if teclas then
    for _, e in ipairs(teclas) do
      if e.n and e.n > n and e.n <= ate then
        local s, _, dica = dividir(tostring(e.s))
        prox[#prox + 1] = { nivel = e.n, s = s, sub = "New key", dica = dica, tecla = tostring(e.rot or e.k),
                            icone = e.id or e.icone or ICONE_PADRAO }
      end
    end
  end
  for i, x in ipairs(prox) do x.ordem = i end
  table.sort(prox, function(a, c)
    if a.nivel ~= c.nivel then return a.nivel < c.nivel end
    return a.ordem < c.ordem
  end)
  sec(b, "Coming up", "agora:prox", nil, "levels " .. (n + 1) .. "-" .. ate)
  if #prox == 0 then vazio(b, "Nothing new in the next levels.") end
  local ultimo
  for _, x in ipairs(prox) do
    add(b, {
      t = "item", nivel = (x.nivel ~= ultimo) and x.nivel or "", icone = x.icone,
      s = x.s, sub = x.sub, tecla = x.tecla, dica = x.dica,
    })
    ultimo = x.nivel
  end

  -- Hidden: o que o dono escondeu no painel, mais o treino que ele pulou (Agora.lua, dbPulados)
  local pulados = {}
  if ns.agora and ns.agora.pulados then
    local ok, r = pcall(ns.agora.pulados)
    if ok and type(r) == "table" then pulados = r end
  end
  local nOcultos = #escondidos + (#pulados > 0 and 1 or 0)
  sec(b, "Hidden", "agora:ocultos", false, nOcultos > 0 and (nOcultos .. " hidden") or nil)
  if nOcultos == 0 then vazio(b, "Nothing hidden.") end
  if #pulados > 0 then
    local dicaP = { "Skipped from the Now panel; it comes back only for new spells." }
    for _, nome in ipairs(pulados) do dicaP[#dicaP + 1] = nome end
    add(b, {
      t = "item", icone = "Interface\\Icons\\INV_Misc_Book_11", apagado = true,
      s = "Skipped training: " .. #pulados .. (#pulados == 1 and " spell" or " spells"),
      dica = dicaP,
      botao = { rotulo = "Show again", acao = function()
        if ns.agora and ns.agora.desfazerPulo then ns.agora.desfazerPulo() end
        atualizar(ctx)
      end },
    })
  end
  for _, it in ipairs(escondidos) do
    local chave = it.chave
    local s, _, dica = dividir(it.texto)
    add(b, {
      t = "item", icone = it.icone, s = s, dica = dica or it.dica, apagado = true,
      botao = { rotulo = "Show again", acao = function()
        if ns.agora and ns.agora.mostrar then ns.agora.mostrar(chave) end
        atualizar(ctx)
      end },
    })
  end
end

-- Pet ---------------------------------------------------------------------------------------

local FELICIDADE = { [1] = "Unhappy", [2] = "Content", [3] = "Happy" }
local COR_FELIC = { [1] = "vermelho", [2] = "amarelo", [3] = "verde" }

local function dadosDePet()
  local d = ns.dicas and ns.dicas()
  if d and ((d.pets and #d.pets > 0) or (d.petTreino and #d.petTreino > 0)) then return d end
  return nil
end

AB.pet = function(b, ctx)
  local n = nivelJogador(ctx)
  local d = dadosDePet()
  if not d then vazio(b, "This class has no pet."); return end
  local p = ns.estado and ns.estado.pet

  if not p or not p.existe then
    vazio(b, "No pet out. Call your pet to see its card.")
  else
    local fam
    if UnitCreatureFamily then
      local ok, f = pcall(UnitCreatureFamily, "pet")
      if ok and type(f) == "string" then fam = f end
    end
    local sub = tostring(p.nome or "Pet") .. (p.nivel and (", level " .. p.nivel) or "") .. (p.morto and " (dead)" or "")
    local barras = {}
    if p.felicidade then
      local pct = type(p.danoPct) == "number" and (" - " .. p.danoPct .. "% damage") or ""
      barras[#barras + 1] = {
        s = (FELICIDADE[p.felicidade] or tostring(p.felicidade)) .. pct,
        valor = p.felicidade, max = 3, cor = COR_FELIC[p.felicidade] or "verde",
      }
    end
    if type(p.pontosTotal) == "number" and type(p.pontosUsados) == "number" then
      barras[#barras + 1] = {
        s = "Training points - " .. (p.pontosTotal - p.pontosUsados) .. " free of " .. p.pontosTotal,
        valor = p.pontosTotal - p.pontosUsados, max = p.pontosTotal, cor = "azul",
      }
    end
    local etiquetas = {}
    if type(p.dieta) == "table" then
      for _, v in ipairs(p.dieta) do etiquetas[#etiquetas + 1] = tostring(v) end
    end
    add(b, {
      t = "perfil", retrato = "pet", icone = "Interface\\Icons\\Ability_Hunter_BeastCall",
      titulo = fam or tostring(p.nome or "Pet"), sub = { sub }, barras = barras, etiquetas = etiquetas,
    })
    if ns.blocosProximosRanks then
      chamar(b, "blocosProximosRanks", ctx, "Next ability upgrades unavailable")
    end
  end

  if p and p.existe and d.petTreino and #d.petTreino > 0 then
    local itens, faltam = {}, 0
    for _, e in ipairs(d.petTreino) do
      if (ctx and ctx.tudo) or e.de <= n + 1 then
        local sabe = ns.petConhece and ns.petConhece(e.habilidade) and true or false
        if not sabe then faltam = faltam + 1 end
        itens[#itens + 1] = { s = tostring(e.habilidade), feito = sabe, sub = (not sabe) and "pet trainer" or nil }
      end
    end
    if #itens > 0 then
      sec(b, "Training plan", "pet:treino", faltam > 0, faltam > 0 and (faltam .. " to learn") or "all learned")
      add(b, { t = "checklist", itens = itens })
    end
  end

  if d.pets and #d.pets > 0 then
    local lista = {}
    for _, e in ipairs(d.pets) do
      local vale = (ctx and ctx.tudo) or (e.de <= n + 1 and e.ate >= n)
      if vale and relev(e, "pet", ctx) then lista[#lista + 1] = e end
    end
    lista = porPrio(lista)
    sec(b, "Pet tips", "pet:dicas", nil, #lista > 0 and #lista or nil)
    if #lista == 0 then vazio(b, "No pet tips for now. Turn on Show all to see the rest.") end
    for _, e in ipairs(lista) do
      local s, sub, dica = dividir(e.texto)
      add(b, { t = "item", nivel = faixaTxt(e), s = s, sub = sub, dica = dica, destaque = (e.prio == 1) or nil })
    end
  end
end

-- Families: so repassa ------------------------------------------------------------------------

AB.familias = function(b, ctx)
  chamar(b, "blocosFamilias", ctx, "Families module not loaded")
end

-- Talents -----------------------------------------------------------------------------------

AB.talentos = function(b, ctx)
  local dados = ns.dados and ns.dados()
  if not dados then vazio(b, "No talent guide for this class."); return end
  local n = nivelJogador(ctx)
  local livres = ns.pontosLivres and ns.pontosLivres() or nil
  local MIN, MAX = ns.MIN_NIVEL or 10, ns.MAX_NIVEL or 60

  -- primeiro ponto ainda por gastar: o do plano (ns.arvore.proximo) ou, sem ele, o nivel atual
  local ini = n + 1
  local prox
  if ns.arvore and ns.arvore.proximo then
    local ok, r = pcall(ns.arvore.proximo)
    if ok and type(r) == "table" and type(r.nivel) == "number" then prox = r end
  end
  local podeGastar = n >= MIN and (livres == nil or livres > 0)
  if prox then ini = prox.nivel elseif podeGastar then ini = n end
  if ini < MIN then ini = MIN end
  local nAgora = prox and livres or (podeGastar and (livres or 1)) or 0

  -- opcoes lado a lado (12.3): so existem quando a classe tem dados.opcoes
  local decisoes = {}
  local planoOp
  if type(dados.opcoes) == "table" and ns.arvore then
    if ns.arvore.decisoes then
      local ok, r = pcall(ns.arvore.decisoes)
      if ok and type(r) == "table" then decisoes = r end
    end
    if ns.arvore.plano then
      local ok, r = pcall(ns.arvore.plano)
      if ok and type(r) == "table" then planoOp = r end
    end
  end

  sec(b, "Next points", "talentos:prox")
  local k = 0
  for l = ini, MAX do
    if k >= 5 then break end
    local v = dados.ordem and dados.ordem[l]
    if v then
      local it = { t = "item", nivel = l, estado = (k < nAgora) and "agora" or "depois" }
      local e = planoOp and planoOp[l]
      local rs, rsub, rdica
      if v == "TBD" and e and e.opcoes and ns.arvore.resumoOpcoes then
        local ok, a, b2, c2 = pcall(ns.arvore.resumoOpcoes, e)
        if ok then rs, rsub, rdica = a, b2, c2 end
      end
      if rs then
        it.s, it.sub, it.dica = cortar(semFonte(rs), 60), rsub, rdica
        it.icone = iconeTalento(e.opcoes[1] and e.opcoes[1].nome)
      elseif v == "TBD" then
        it.s, it.icone = "Your pick: sources differ", ICONE_PADRAO
        it.dica = { "The sources differ on this point.", "See Open (below) for the options, then choose in the talent tree." }
      else
        local nome = v:match("^(.-)%s+%d+/%d+$") or v
        it.s, it.icone = v, iconeTalento(nome)
      end
      add(b, it)
      k = k + 1
    end
  end
  if k == 0 then vazio(b, "Nothing to show (guide max level).") end

  -- Your pick: uma secao por decisao com nivel ainda por gastar, colunas lado a lado (12.3)
  for _, dec in ipairs(decisoes) do
    local niveis = {}
    for l in pairs(dec.niveis or {}) do
      if type(l) == "number" and ((ctx and ctx.tudo) or l >= ini) then niveis[#niveis + 1] = l end
    end
    table.sort(niveis)
    if #niveis > 0 then
      sec(b, cortar("Your pick: " .. tostring(dec.s), 60), "talentos:op:" .. tostring(dec.id), true)
      for _, c in ipairs(dec.colunas or {}) do
        local texto1
        for _, l in ipairs(niveis) do
          texto1 = texto1 or (dec.niveis[l] and dec.niveis[l][c.id])
        end
        local nome1 = texto1 and (texto1:match("^(.-)%s+%d+/%d+$") or texto1)
        add(b, {
          t = "item", icone = iconeTalento(nome1),
          s = cortar(tostring(c.id) .. ": " .. tostring(c.s), 60),
          sub = c.sub and cortar(c.sub, 80) or nil,
        })
      end
      local colunas, linhas = { { s = "Level", largura = 50 } }, {}
      for _, c in ipairs(dec.colunas or {}) do
        colunas[#colunas + 1] = { s = tostring(c.id) .. " " .. tostring(c.s) }
      end
      for _, l in ipairs(niveis) do
        local celulas = { tostring(l) }
        for _, c in ipairs(dec.colunas or {}) do
          celulas[#celulas + 1] = (dec.niveis[l] and dec.niveis[l][c.id]) or ""
        end
        linhas[#linhas + 1] = { celulas = celulas }
      end
      add(b, { t = "tabela", id = "talentos:op:" .. tostring(dec.id) .. ":tab", limite = 6,
               colunas = colunas, linhas = linhas })
    end
  end

  local d = ns.dicas and ns.dicas()
  local ate = n + ((ctx and ctx.tudo) and 10 or 2)
  sec(b, "New spells", "talentos:magias")
  local achou, ultimo = false, nil
  if d and d.magias then
    for _, e in ipairs(d.magias) do
      if e.nivel and e.nivel >= n and e.nivel <= ate and relev(e, "talentos", ctx) then
        local s, sub, dica = dividir(e.texto)
        add(b, {
          t = "item", nivel = (e.nivel ~= ultimo) and e.nivel or "", icone = e.id or ICONE_PADRAO,
          s = s, sub = sub, dica = dica,
        })
        ultimo, achou = e.nivel, true
      end
    end
  end
  if not achou then vazio(b, "No new spells in these levels.") end

  if dados.lei then
    sec(b, "Core", "talentos:lei", false, "definitely in")
    for _, s in ipairs(dados.lei) do add(b, { t = "nota", s = semFonte(s) }) end
  end
  if dados.aberto then
    sec(b, "Open", "talentos:aberto", false, "your pick")
    for _, a in ipairs(dados.aberto) do
      local ops = {}
      for _, o in ipairs(a.opcoes or {}) do ops[#ops + 1] = semFonte(o) end
      local junto = table.concat(ops, " | ")
      add(b, {
        t = "item", icone = iconeTalento(a.ponto), s = tostring(a.ponto),
        sub = cortar(junto, 80), dica = ops,
      })
    end
  end
  if NaowhForever and NaowhForever.OpenTrainingWindow then
    add(b, { t = "botao", s = "Open Naowh planner", f = function()
      if NaowhForever and NaowhForever.OpenTrainingWindow then
        pcall(NaowhForever.OpenTrainingWindow, nivelJogador(ctx), "spells")
      end
    end })
  end
end

-- Combat ------------------------------------------------------------------------------------

AB.combate = function(b, ctx)
  local n = nivelJogador(ctx)
  local sub = (ctx and ctx.sub) or "rotacao"
  add(b, {
    t = "segs", aba = "combate", atual = sub,
    opcoes = {
      { id = "rotacao", s = "Rotation" }, { id = "teclas", s = "Keys" },
      { id = "armas", s = "Weapons" }, { id = "atributos", s = "Stats" },
    },
  })
  local d = ns.dicas and ns.dicas()

  if sub == "teclas" then
    chamar(b, "blocosTeclas", ctx, "Keys unavailable")
    return
  end
  if not d then vazio(b, "No tips for this class."); return end

  if sub == "rotacao" then
    local lista = {}
    for _, e in ipairs(d.rotacao or {}) do
      if ((ctx and ctx.tudo) or noIntervalo(e, n)) and relev(e, "combate", ctx) then lista[#lista + 1] = e end
    end
    lista = porPrio(lista)
    sec(b, "Rotation", "combate:rotacao", nil, #lista > 0 and #lista or nil)
    if #lista == 0 then vazio(b, "No rotation tip for this range.") end
    for _, e in ipairs(lista) do
      local s, sb, dica = dividir(e.texto)
      local it = { t = "item", s = s, sub = sb, dica = dica, destaque = (e.prio == 1) or nil }
      if ctx and ctx.tudo then it.nivel = faixaTxt(e) end
      add(b, it)
    end
    local notas = {}
    for _, e in ipairs(d.notas or {}) do
      if relev(e, "combate", ctx) then notas[#notas + 1] = e end
    end
    if #notas > 0 then
      sec(b, "Notes", "combate:notas", false, #notas)
      for _, e in ipairs(notas) do add(b, { t = "nota", s = semFonte(e.texto) }) end
    end

  elseif sub == "armas" then
    local lista = {}
    for _, e in ipairs(d.armas or {}) do
      if ((ctx and ctx.tudo) or noIntervalo(e, n)) and relev(e, "combate", ctx) then lista[#lista + 1] = e end
    end
    sec(b, "Weapons", "combate:armas", nil, #lista > 0 and #lista or nil)
    if #lista == 0 then vazio(b, "No weapon tip for this range.") end
    for _, e in ipairs(lista) do
      local s, sb, dica = dividir(e.texto)
      if temTag(e, "grupo") then sb = sb and cortar("dungeon - " .. sb, 80) or "dungeon" end
      add(b, { t = "item", nivel = faixaTxt(e), s = s, sub = sb, dica = dica })
    end

  elseif sub == "atributos" then
    sec(b, "Stats", "combate:atributos")
    local achou = false
    for _, e in ipairs(d.atributos or {}) do
      if relev(e, "combate", ctx) then add(b, { t = "nota", s = semFonte(e.texto) }); achou = true end
    end
    if not achou then vazio(b, "No stat tip for this class.") end
  end
end

-- Professions -------------------------------------------------------------------------------

local ICONES_PROF = {
  Skinning = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
  Leatherworking = "Interface\\Icons\\INV_Misc_ArmorKit_17",
  Mining = "Interface\\Icons\\Trade_Mining",
  Herbalism = "Interface\\Icons\\Trade_Herbalism",
  Alchemy = "Interface\\Icons\\Trade_Alchemy",
  Blacksmithing = "Interface\\Icons\\Trade_BlackSmithing",
  Engineering = "Interface\\Icons\\Trade_Engineering",
  Enchanting = "Interface\\Icons\\Trade_Engraving",
  Tailoring = "Interface\\Icons\\Trade_Tailoring",
  Cooking = "Interface\\Icons\\INV_Misc_Food_15",
  Fishing = "Interface\\Icons\\Trade_Fishing",
  ["First Aid"] = "Interface\\Icons\\Spell_Holy_Heal",
}

AB.profissoes = function(b, ctx)
  local sub = (ctx and ctx.sub) or "minhas"
  add(b, {
    t = "segs", aba = "profissoes", atual = sub,
    opcoes = { { id = "minhas", s = "Mine" }, { id = "zona", s = "Zone" }, { id = "treinos", s = "Trainers" } },
  })
  if sub == "zona" then
    chamar(b, "blocosZona", ctx, "Zone tab unavailable")
    return
  elseif sub == "treinos" then
    chamar(b, "blocosTreinos", ctx, "Trainers unavailable")
    return
  end

  local lista = ns.minhasProfissoes and ns.minhasProfissoes() or {}
  if #lista == 0 then
    vazio(b, "No profession with a leveling route learned yet. Where to learn: Trainers.")
    add(b, { t = "botao", s = "Open Trainers", f = function() abrir(ctx, "profissoes", "treinos") end })
    return
  end
  sec(b, "Mine", "profissoes:minhas", nil, #lista)
  for _, pr in ipairs(lista) do
    local idx = ns.indicePasso(pr.tab, pr.pericia)
    local passo = pr.tab.passos[idx]
    local teto = pr.maximo or (passo and passo.ate) or 75
    local linhas = {}
    if passo then
      local receita, qtd, mats = partesPasso(passo.texto)
      if mats then
        linhas[#linhas + 1] = cortar("Now: " .. receita .. (qtd and (" x" .. qtd) or ""), 80)
        linhas[#linhas + 1] = cortar("Needs: " .. mats, 80)
      else
        linhas[#linhas + 1] = cortar("Now: " .. receita, 80)
      end
    end
    add(b, {
      t = "perfil", icone = ICONES_PROF[pr.nome] or "Interface\\Icons\\INV_Misc_Book_09",
      titulo = pr.nome, sub = linhas,
      barras = { { s = pr.pericia .. "/" .. teto, valor = pr.pericia, max = teto,
                   cor = (pr.pericia >= teto) and "laranja" or "verde" } },
    })
  end

  -- Roteiro consultavel (dono, 2026-11-08: "quais sao as proximas receitas que eu preciso
  -- proximos niveis [...] de uma forma que for consultavel, sem clutter"): uma secao recolhivel
  -- por profissao, com o passo atual e os seguintes numa tabela de 3 colunas; os passos ja
  -- feitos so com "Show all". O desenhista mostra 4 linhas e guarda o resto em "Show N more".
  for _, pr in ipairs(lista) do
    local passos = pr.tab.passos or {}
    local idx = ns.indicePasso(pr.tab, pr.pericia)
    local ini = (ctx and ctx.tudo) and 1 or idx
    -- profissao de fabrica (passos com materiais) ganha 3 colunas; de coleta, 2
    local fabrica = false
    for _, p in ipairs(passos) do
      local _, _, m = partesPasso(p.texto)
      if m then fabrica = true; break end
    end
    local linhasTab = {}
    for i = ini, #passos do
      local p = passos[i]
      local receita, qtd, mats = partesPasso(p.texto)
      local feito = i < idx
      local faixa = { s = p.de .. "-" .. p.ate, numero = true }
      if i == idx then faixa.estado = "agora" elseif feito then faixa.estado = "feito" end
      local celulas
      if fabrica then
        celulas = {
          faixa,
          (qtd and (cortar(receita, 34) .. " x" .. qtd)) or cortar(receita, 40),
          { s = cortar(mats or "", 46), cor = "cinza" },
        }
      else
        celulas = { faixa, cortar(receita, 80) }
      end
      linhasTab[#linhasTab + 1] = { celulas = celulas, apagado = feito, dica = semFonte(p.texto) }
    end
    if #linhasTab > 0 then
      local id = "profissoes:rota:" .. tostring(pr.nome)
      local colunas = { { s = "Skill", largura = 70, alinha = "centro" }, { s = "Make" }, { s = "Materials" } }
      if not fabrica then colunas = { { s = "Skill", largura = 70, alinha = "centro" }, { s = "What to gather" } } end
      sec(b, pr.nome .. " route", id, nil, (#passos - idx) .. " steps to go")
      add(b, { t = "tabela", id = id .. ":tab", limite = 4, colunas = colunas, linhas = linhasTab })
      -- total de materiais por faixa de treino (dono, 2026-11-08: "a quantidade total de
      -- ingredientes que eu preciso para evoluir de cada faixa da profissao. De crafting")
      if fabrica then
        for _, t in ipairs(totaisPorFaixa(passos, pr.pericia, ctx and ctx.tudo)) do
          local idT = id .. ":tot:" .. t.nome
          sec(b, t.nome .. " materials", idT, t.aberta, pr.nome .. " " .. t.faixa)
          add(b, {
            t = "tabela", id = idT .. ":tab", limite = 6,
            colunas = { { s = "Qty", largura = 50, alinha = "dir" }, { s = "Material" },
                        { s = "Qty", largura = 50, alinha = "dir" }, { s = "Material" } },
            linhas = t.linhas,
          })
        end
      end
    end
  end
end

-- Help --------------------------------------------------------------------------------------

-- Nome, o que faz, como abrir. Comandos lidos no codigo de cada addon instalado (2026-11-06 e 2026-11-07).
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
  { "UIForever", "this layout, keys, number fonts", "automatic on login" },
}

local function cor(nome)
  if ns.ui and ns.ui.hex then
    local ok, h = pcall(ns.ui.hex, nome)
    if ok and type(h) == "string" then return h end
  end
  return ""
end

local function colorido(nome, texto)
  local h = cor(nome)
  if h == "" then return texto end
  return h .. texto .. (ns.FIM or "|r")
end

AB.ajuda = function(b, ctx)
  local sub = (ctx and ctx.sub) or "perguntas"
  add(b, {
    t = "segs", aba = "ajuda", atual = sub,
    opcoes = { { id = "perguntas", s = "Questions" }, { id = "addons", s = "Addons" }, { id = "sinais", s = "Signs" } },
  })

  if sub == "perguntas" then
    local lista = GuiaForeverAjuda and ns.classe and GuiaForeverAjuda[ns.classe()]
    if type(lista) ~= "table" or #lista == 0 then
      vazio(b, "No questions answered for this class yet.")
      return
    end
    for i, q in ipairs(lista) do
      if type(q) == "table" and q.pergunta then
        sec(b, tostring(q.pergunta), "ajuda:q:" .. tostring(q.id or i), false)
        for _, ln in ipairs(q.linhas or {}) do
          if type(ln) == "table" and ln.texto then add(b, { t = "nota", s = semFonte(ln.texto) }) end
        end
      end
    end

  elseif sub == "addons" then
    local linhas = {}
    for _, a in ipairs(ADDONS) do
      local s, _, dica = dividir(a[2], 90)
      linhas[#linhas + 1] = { celulas = { a[1], s, a[3] }, dica = { a[2] } }
      if dica == nil then linhas[#linhas].dica = nil end
    end
    add(b, {
      t = "tabela", id = "ajuda:addons", limite = 6,
      colunas = {
        { s = "Addon", largura = 160 }, { s = "What it gives you" }, { s = "Open", largura = 190 },
      },
      linhas = linhas,
    })

  else
    sec(b, "Panel colors", "ajuda:cores")
    add(b, { t = "item", s = colorido("vermelho", "Red"), sub = "Something is hurting you right now." })
    add(b, { t = "item", s = colorido("laranja", "Orange"), sub = "An errand in town." })
    add(b, { t = "item", s = colorido("amarelo", "Yellow"), sub = "Do it when convenient." })
    add(b, { t = "item", s = colorido("azul", "Blue"), sub = "Information." })
    sec(b, "Marks in the game windows", "ajuda:marcas")
    add(b, { t = "item", s = colorido("dourado", "NOW"), sub = "Talent tree: the next point to spend." })
    add(b, { t = "item", s = colorido("dourado", "PLAN"), sub = "Pet trainer: the next pet ability to train." })
    add(b, { t = "item", s = colorido("dourado", "ALL"), sub = "Talent tree: the talent is in your Core list." })
    add(b, { t = "item", s = colorido("dourado", "?"), sub = "Talent tree: the plan has no fixed pick; see Open." })
    add(b, { t = "item", s = colorido("dourado", "Numbers"), sub = "Talent tree: levels that take the remaining ranks; a check is done." })
    local classeS = ns.dados and ns.dados()
    if classeS and type(classeS.opcoes) == "table" then
      add(b, { t = "item", s = colorido("dourado", "A B C"),
               sub = "Talent tree: options side by side; pick one, see Talents." })
    end
  end
end

-- Estado do cabecalho e visibilidade das abas -----------------------------------------------

local function temDadosDePet()
  if dadosDePet() then return true end
  local classe = ns.classe and ns.classe()
  return GuiaForeverPetGuia ~= nil and classe == "HUNTER"
end

function ns.abaVisivel(id)
  if id == "pet" or id == "familias" then return temDadosDePet() end
  if id == "crafts" then return ns.craftsVisivel ~= nil and ns.craftsVisivel() or false end
  return true
end

function ns.abasEstado()
  local r = {}
  -- 1. pontos de talento livres
  local livres = ns.pontosTalento and ns.pontosTalento() or nil
  if type(livres) == "number" then
    r[#r + 1] = {
      icone = ICONE_PADRAO, s = "Talent", n = livres,
      cor = (livres > 0) and "laranja" or nil, aba = "talentos",
    }
  end
  -- 2. o pet (so para quem tem dados de pet)
  local p = ns.estado and ns.estado.pet
  if p and p.existe and temDadosDePet() then
    local fam
    if UnitCreatureFamily then
      local ok, f = pcall(UnitCreatureFamily, "pet")
      if ok and type(f) == "string" then fam = f end
    end
    local felic = FELICIDADE[p.felicidade or 0]
    r[#r + 1] = {
      icone = "Interface\\Icons\\Ability_Hunter_BeastCall", s = fam or tostring(p.nome or "Pet"),
      n = tostring(p.nivel or "") .. (felic and (" " .. felic) or ""),
      cor = COR_FELIC[p.felicidade or 0], aba = "pet",
    }
  end
  -- 3. a profissao que trava (pericia no teto) ou a primeira
  local lista = ns.minhasProfissoes and ns.minhasProfissoes() or {}
  local escolhida, trava
  for _, pr in ipairs(lista) do
    if pr.maximo and pr.pericia >= pr.maximo then escolhida, trava = pr, true; break end
  end
  escolhida = escolhida or lista[1]
  if escolhida then
    local passo = escolhida.tab.passos[ns.indicePasso(escolhida.tab, escolhida.pericia)]
    local teto = escolhida.maximo or (passo and passo.ate) or 75
    r[#r + 1] = {
      icone = ICONES_PROF[escolhida.nome] or "Interface\\Icons\\INV_Misc_Book_09",
      s = escolhida.nome, n = escolhida.pericia .. "/" .. teto,
      cor = trava and "laranja" or nil, aba = "profissoes", sub = "minhas",
    }
  end
  while #r > 3 do r[#r] = nil end
  return r
end
