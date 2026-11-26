local addon, ns = ...

-- Nucleo: eventos, SavedVariables, config, receitas conhecidas, dinheiro e bolsas, moeda, /compra, replanejar
-- (CONTRATO secao 3). Os outros modulos falam por `ns`.

local floor, max = math.floor, math.max

local PADROES = { duracao = 3, reserva = 0, desconto = 10, lucroMin = 50, margemMin = 5, grande = 10000, pequena = 3000,
  tolerancia = 10, margem = 0 }

-- Profissoes da modalidade de rota (CONTRATO 12.3)
ns.PROFS = {
  { slug = "alchemy", nome = "Alchemy", curto = "Alch", linha = 171 },
  { slug = "blacksmithing", nome = "Blacksmithing", curto = "BS", linha = 164 },
  { slug = "enchanting", nome = "Enchanting", curto = "Ench", linha = 333 },
  { slug = "engineering", nome = "Engineering", curto = "Eng", linha = 202 },
  { slug = "leatherworking", nome = "Leatherworking", curto = "LW", linha = 165 },
  { slug = "tailoring", nome = "Tailoring", curto = "Tail", linha = 197 },
}

local function profPorSlug(slug)
  for _, p in ipairs(ns.PROFS) do
    if p.slug == slug then return p end
  end
  return nil
end

-- Eventos --------------------------------------------------------------------------------------------

local ouvintes = {}
local quadro = CreateFrame("Frame")

function ns.ao(evento, fn)
  local l = ouvintes[evento]
  if not l then
    l = {}
    ouvintes[evento] = l
    pcall(quadro.RegisterEvent, quadro, evento)
  end
  l[#l + 1] = fn
end

quadro:SetScript("OnEvent", function(_, evento, ...)
  local l = ouvintes[evento]
  if not l then return end
  for i = 1, #l do l[i](...) end
end)

-- Moeda e valores ------------------------------------------------------------------------------------

function ns.moeda(cobre)
  cobre = tonumber(cobre)
  if not cobre or cobre < 0 then return "-" end
  cobre = floor(cobre)
  local g, s, c = floor(cobre / 10000), floor((cobre % 10000) / 100), cobre % 100
  local p = {}
  if g > 0 then p[#p + 1] = g .. "g" end
  if s > 0 then p[#p + 1] = (g > 0 and string.format("%02d", s) or tostring(s)) .. "s" end
  if c > 0 or #p == 0 then p[#p + 1] = ((g > 0 or s > 0) and string.format("%02d", c) or tostring(c)) .. "c" end
  return table.concat(p, " ")
end

-- "1g20s", "50s", "30c" ou numero puro (cobre); nil se nao entender
function ns.lerValor(texto)
  if type(texto) == "number" then return floor(texto) end
  if type(texto) ~= "string" then return nil end
  local t = string.lower((string.gsub(texto, "%s+", "")))
  if t == "" then return nil end
  if string.find(t, "^%d+$") then return tonumber(t) end
  local total, n = 0, 0
  local resto = string.gsub(t, "(%d+)([gsc])", function(num, u)
    n = n + 1
    total = total + tonumber(num) * (u == "g" and 10000 or (u == "s" and 100 or 1))
    return ""
  end)
  if n == 0 or resto ~= "" then return nil end
  return total
end

-- SavedVariables e config ----------------------------------------------------------------------------

function ns.config()
  return (CompraForeverDB and CompraForeverDB.config) or PADROES
end

local function iniciarSV()
  if type(CompraForeverDB) ~= "table" then CompraForeverDB = {} end
  if type(CompraForeverDB.config) ~= "table" then CompraForeverDB.config = {} end
  for k, v in pairs(PADROES) do
    if CompraForeverDB.config[k] == nil then CompraForeverDB.config[k] = v end
  end
  if type(CompraForeverDB.ultimoFull) ~= "number" then CompraForeverDB.ultimoFull = 0 end
  if type(CompraForeverCharDB) ~= "table" then CompraForeverCharDB = {} end
  local c = CompraForeverCharDB
  local novo = c.versao == nil
  if type(c.modo) ~= "table" or type(c.modo.tipo) ~= "string" then c.modo = { tipo = "lucro" } end
  for _, k in ipairs({ "prof", "rota", "correio", "correioVisto", "correioEm" }) do
    if type(c[k]) ~= "table" then c[k] = {} end
  end
  if novo then
    local k = c.conhecidas
    if type(k) == "table" and type(k.ids) == "table" and not c.prof.leatherworking then
      local ids = {}
      for id, v in pairs(k.ids) do ids[id] = v end
      c.prof.leatherworking = { pericia = k.pericia, ids = ids, n = k.n, em = k.em, idsEm = k.em }
    end
    c.versao = 2
  end
end

ns.ao("ADDON_LOADED", function(nome)
  if nome == addon then iniciarSV() end
end)

-- Dinheiro, bolsas, estoque --------------------------------------------------------------------------

function ns.dinheiro()
  return max(0, GetMoney() - (ns.config().reserva or 0))
end

function ns.espacosLivres()
  local n = 0
  for b = 0, 4 do n = n + (C_Container.GetContainerNumFreeSlots(b) or 0) end
  return n
end

function ns.estoque(id)
  return C_Item.GetItemCount(id) or 0
end

-- Receitas conhecidas --------------------------------------------------------------------------------

function ns.slugDe(info)
  if type(info) ~= "table" then return nil end
  for _, p in ipairs(ns.PROFS) do
    if info.professionName == p.nome or info.parentProfessionName == p.nome
      or info.professionID == p.linha or info.parentProfessionID == p.linha then
      return p.slug
    end
  end
  return nil
end

-- slug da janela de profissao do proprio personagem, pronta; e a info usada (a do filho, senao a da base)
function ns.slugDaJanela()
  local T = C_TradeSkillUI
  if type(T) ~= "table" then return nil end
  if T.IsTradeSkillReady and not T.IsTradeSkillReady() then return nil end
  if (T.IsTradeSkillLinked and T.IsTradeSkillLinked()) or (T.IsTradeSkillGuild and T.IsTradeSkillGuild())
    or (T.IsNPCCrafting and T.IsNPCCrafting()) then return nil end
  local filho = T.GetChildProfessionInfo and T.GetChildProfessionInfo()
  local slug = ns.slugDe(filho)
  if slug then return slug, filho end
  local base = T.GetBaseProfessionInfo and T.GetBaseProfessionInfo()
  slug = ns.slugDe(base)
  if slug then return slug, base end
  return nil
end

local function tabelaChar(k)
  if type(CompraForeverCharDB) ~= "table" then return nil end
  if type(CompraForeverCharDB[k]) ~= "table" then CompraForeverCharDB[k] = {} end
  return CompraForeverCharDB[k]
end

-- copia da leitura do GuiaForever (Crafts.lua): so a janela do proprio personagem
local function gravarConhecidas()
  local T = C_TradeSkillUI
  if type(T) ~= "table" or not T.GetAllRecipeIDs or not T.GetRecipeInfo then return end
  local slug, info = ns.slugDaJanela()
  if not slug then return end
  local ids, n = {}, 0
  local lista = T.GetAllRecipeIDs()
  for _, id in ipairs(type(lista) == "table" and lista or {}) do
    local r = T.GetRecipeInfo(id)
    if type(r) == "table" and r.learned then
      ids[id] = true
      n = n + 1
    end
  end
  if n == 0 then return end
  local prof = tabelaChar("prof")
  if not prof then return end
  local agora = time()
  local ant = prof[slug]
  prof[slug] = {
    pericia = tonumber(info.skillLevel) or (ant and ant.pericia), max = tonumber(info.maxSkillLevel) or (ant and ant.max),
    em = agora, ids = ids, n = n, idsEm = agora,
  }
  if slug == "leatherworking" then
    CompraForeverCharDB.conhecidas = {
      quem = UnitName("player"), em = agora, pericia = tonumber(info.skillLevel), ids = ids, n = n,
    }
  end
  ns.replanejar()
end

-- Pericia sem a janela (reserva): so atualiza profissao ja gravada; a janela aberta sempre vence
local function aplicarPericia(slug, pericia, maximo, soAlta)
  local prof = type(CompraForeverCharDB) == "table" and CompraForeverCharDB.prof
  local reg = type(prof) == "table" and prof[slug]
  if type(reg) ~= "table" then return false end
  local mudou = false
  if type(pericia) == "number" and pericia ~= reg.pericia and (not soAlta or pericia > (reg.pericia or 0)) then
    reg.pericia = pericia
    mudou = true
  end
  if type(maximo) == "number" and maximo > 0 and maximo ~= reg.max then
    reg.max = maximo
    mudou = true
  end
  if mudou then reg.em = time() end
  return mudou
end

local function lerPericiaReserva()
  local janela = ns.slugDaJanela()
  local mudou = false
  local T = C_TradeSkillUI
  if type(T) == "table" and type(T.GetProfessionInfoBySkillLineID) == "function" then
    for _, p in ipairs(ns.PROFS) do
      if p.slug ~= janela then
        local ok, info = pcall(T.GetProfessionInfoBySkillLineID, p.linha)
        if ok and type(info) == "table" and type(info.skillLevel) == "number"
          and (info.professionName == p.nome or info.professionID == p.linha or ns.slugDe(info) == p.slug) then
          if aplicarPericia(p.slug, info.skillLevel, tonumber(info.maxSkillLevel), false) then mudou = true end
        end
      end
    end
  end
  local GP, GPI = rawget(_G, "GetProfessions"), rawget(_G, "GetProfessionInfo")
  if type(GP) == "function" and type(GPI) == "function" then
    local lista = { pcall(GP) }
    if lista[1] then
      for k = 2, 9 do
        local idx = lista[k]
        if type(idx) == "number" then
          local r = { pcall(GPI, idx) }
          if r[1] then
            for _, p in ipairs(ns.PROFS) do
              if p.slug ~= janela and (r[2] == p.nome or r[8] == p.linha) and type(r[4]) == "number" then
                if aplicarPericia(p.slug, r[4], tonumber(r[5]), false) then mudou = true end
              end
            end
          end
        end
      end
    end
  end
  return mudou
end

local agendado = false
local function agendarGravar()
  if agendado then return end
  agendado = true
  C_Timer.After(0.5, function()
    agendado = false
    gravarConhecidas()
    if lerPericiaReserva() then ns.replanejar() end
  end)
end

ns.ao("TRADE_SKILL_SHOW", agendarGravar)
ns.ao("TRADE_SKILL_LIST_UPDATE", agendarGravar)
ns.ao("TRADE_SKILL_DATA_SOURCE_CHANGED", agendarGravar)
ns.ao("NEW_RECIPE_LEARNED", agendarGravar)
ns.ao("LEARNED_SPELL_IN_SKILL_LINE", agendarGravar)
ns.ao("SKILL_LINES_CHANGED", agendarGravar)
ns.ao("PLAYER_ENTERING_WORLD", agendarGravar)

ns.ao("CHAT_MSG_SKILL", function(texto)
  if type(texto) ~= "string" then return end
  local ok, nome, nivel = pcall(string.match, texto, "Your skill in (.+) has increased to (%d+)")
  if not ok or not nome then return end
  for _, p in ipairs(ns.PROFS) do
    if p.nome == nome and aplicarPericia(p.slug, tonumber(nivel), nil, true) then
      ns.replanejar()
      return
    end
  end
end)

-- reserva: a gravacao mais nova do GuiaForever para este personagem
local function conhecidasDoGuia()
  local g = rawget(_G, "GuiaForeverDB")
  local ps = type(g) == "table" and g.personagens
  if type(ps) ~= "table" then return nil end
  local quem, melhor = UnitName("player"), nil
  for _, p in pairs(ps) do
    local k = type(p) == "table" and p.receitasLW
    if type(k) == "table" and type(k.ids) == "table" and k.quem == quem and (k.n or 0) > 0
      and (not melhor or (k.em or 0) > (melhor.em or 0)) then
      melhor = k
    end
  end
  return melhor
end

-- { [magia] = true } (vazio se nada conhecido) e a origem: "proprio" | "guia" | nil
function ns.conhecidas()
  local k = type(CompraForeverCharDB) == "table" and CompraForeverCharDB.conhecidas
  if type(k) == "table" and type(k.ids) == "table" and (k.n or 0) > 0 then return k.ids, "proprio" end
  local r = conhecidasDoGuia()
  if r then return r.ids, "guia" end
  return {}, nil
end

-- Plano ----------------------------------------------------------------------------------------------

function ns.modo()
  local m = type(CompraForeverCharDB) == "table" and CompraForeverCharDB.modo
  if type(m) == "table" and type(m.tipo) == "string" then return m end
  return { tipo = "lucro" }
end

function ns.profDoModo()
  local m = ns.modo()
  if m.tipo == "rota" then return m.prof end
  return "leatherworking"
end

local function rotasDados()
  local d = rawget(_G, "CompraForeverDados")
  return type(d) == "table" and type(d.rotas) == "table" and d.rotas or {}
end

-- Alvos da modalidade de rota (secao 12.3): 150 e 225 sempre; os de cima so quando a rota gerada chega la
-- (o ate de algum trecho de rotas.profs[slug]), porque sem trecho o plano so diria "lacuna".
local ALVOS = { 150, 225, 250 }
local function alvosDe(slug)
  local rotas = rotasDados()
  local p = type(rotas.profs) == "table" and rotas.profs[slug]
  local topo = 225
  if type(p) == "table" and type(p.trechos) == "table" then
    for _, t in ipairs(p.trechos) do
      if type(t) == "table" and type(t.ate) == "number" and t.ate > topo then topo = t.ate end
    end
  end
  local lista = {}
  for _, a in ipairs(ALVOS) do
    if a <= topo then lista[#lista + 1] = a end
  end
  return lista
end
ns.alvosDe = alvosDe

function ns.modosDisponiveis()
  local lista = { { tipo = "lucro" } }
  local rotas = rotasDados()
  local prof = type(CompraForeverCharDB) == "table" and type(CompraForeverCharDB.prof) == "table" and CompraForeverCharDB.prof or {}
  local algum = next(prof) ~= nil
  for _, p in ipairs(ns.PROFS) do
    if type(rotas.profs) == "table" and rotas.profs[p.slug] and (not algum or prof[p.slug]) then
      for _, a in ipairs(alvosDe(p.slug)) do
        lista[#lista + 1] = { tipo = "rota", prof = p.slug, alvo = a }
      end
    end
  end
  return lista
end

function ns.rotuloModo(m)
  if type(m) ~= "table" or m.tipo ~= "rota" then return "Profit" end
  local p = profPorSlug(m.prof)
  return (p and p.curto or tostring(m.prof)) .. " " .. tostring(m.alvo or 150)
end

function ns.definirModo(m)
  if type(m) ~= "table" or type(CompraForeverCharDB) ~= "table" then return end
  if m.tipo == "rota" then
    CompraForeverCharDB.modo = { tipo = "rota", prof = m.prof, alvo = m.alvo or 150 }
  else
    CompraForeverCharDB.modo = { tipo = "lucro" }
  end
  ns.replanejar()
  if ns.atualizarPainel then ns.atualizarPainel() end
end

-- todos os itens que a rota da profissao cita (para estoque e correio)
local idsRotaCache = setmetatable({}, { __mode = "k" })
local function idsDaRota(rota)
  local c = idsRotaCache[rota]
  if c then return c end
  local set = {}
  for _, r in pairs(rota.receitas or {}) do
    if r.produto then set[r.produto] = true end
    if r.padrao then set[r.padrao] = true end
    for _, rg in ipairs(r.reagentes or {}) do set[rg[1]] = true end
    for _, f in ipairs(r.ferramentas or {}) do
      for _, id in ipairs(f.itens or {}) do set[id] = true end
    end
    if type(r.acampamento) == "table" then
      for _, id in ipairs(r.acampamento.itens or {}) do set[id] = true end
    end
  end
  for _, t in ipairs(rota.trechos or {}) do
    for id in pairs(t.fontes or {}) do set[id] = true end
  end
  c = {}
  for id in pairs(set) do c[#c + 1] = id end
  table.sort(c)
  idsRotaCache[rota] = c
  return c
end

function ns.entradaRota()
  local m = ns.modo()
  local slug = m.prof
  local rotas = rotasDados()
  local rota = type(rotas.profs) == "table" and rotas.profs[slug] or nil
  local cdb = CompraForeverCharDB
  local reg = type(cdb.prof) == "table" and cdb.prof[slug] or nil
  if type(cdb.rota) ~= "table" then cdb.rota = {} end
  if type(cdb.rota[slug]) ~= "table" then cdb.rota[slug] = {} end
  local rr = cdb.rota[slug]
  for _, k in ipairs({ "credito", "vendido", "craftado" }) do
    if type(rr[k]) ~= "table" then rr[k] = {} end
  end
  rr.gasto = rr.gasto or 0
  rr.inicio = rr.inicio or time()
  local contagem = ns.estoqueBolsa or ns.estoque
  local pend = ns.sessao and ns.sessao.correio or cdb.correio or {}
  local bolsa, correio = {}, {}
  if rota then
    for _, id in ipairs(idsDaRota(rota)) do
      bolsa[id] = contagem(id) or 0
      correio[id] = pend[id] or 0
    end
  end
  local nivel = nil
  local UL = rawget(_G, "UnitLevel")
  if type(UL) == "function" then
    local ok, v = pcall(UL, "player")
    if ok and type(v) == "number" then nivel = v end
  end
  local cfg = ns.config()
  return {
    prof = slug, rota = rota, itens = rotas.itens, alvo = m.alvo or 150, pericia = reg and reg.pericia, max = reg and reg.max,
    nivel = nivel, conhecidas = reg and reg.ids, bolsa = bolsa, correio = correio,
    dinheiro = ns.dinheiro(), espacos = ns.espacosLivres(), desconto = cfg.desconto, tolerancia = cfg.tolerancia,
    margem = cfg.margem, escadas = ns.scan and ns.scan.escadas or {}, credito = rotas.credito ~= false,
    credVenda = rr.credito, fonte = rotas.fonte, ultimoFull = CompraForeverDB.ultimoFull, agora = time(),
  }
end

function ns.replanejar()
  if ns.modo().tipo == "rota" then
    local plano = nil
    if ns.planejarRota then plano = ns.planejarRota(ns.entradaRota()) end
    ns.plano = plano
    if ns.atualizarPainel then ns.atualizarPainel() end
    return plano
  end
  local sc = ns.scan
  if not sc or not ns.planejar then
    ns.plano = nil
    if type(CompraForeverCharDB) == "table" then CompraForeverCharDB.plano = nil end
    if ns.atualizarPainel then ns.atualizarPainel() end
    return nil
  end
  local dados = rawget(_G, "CompraForeverDados") or {}
  local receitas, fabrica = dados.receitas or {}, dados.fabrica or {}
  local conhecidas = ns.conhecidas()
  local envolvidos = {}
  local function reagentesDe(magia)
    local r = receitas[magia]
    if r then
      for _, rg in ipairs(r.reagentes) do envolvidos[rg[1]] = true end
    end
  end
  for magia in pairs(conhecidas) do reagentesDe(magia) end
  for _, magia in pairs(fabrica) do
    if conhecidas[magia] then reagentesDe(magia) end
  end
  local estoque = {}
  for id in pairs(envolvidos) do
    local q = ns.estoque(id)
    if q > 0 then estoque[id] = q end
  end
  local cfg = ns.config()
  local plano = ns.planejar({
    dinheiro = ns.dinheiro(), espacos = ns.espacosLivres(), conhecidas = conhecidas, dados = dados,
    desconto = cfg.desconto, lucroMin = cfg.lucroMin, margemMin = cfg.margemMin,
    escadas = sc.escadas or {}, estoque = estoque, revenda = sc.tipo == "full" and sc.revenda or nil,
  })
  plano.em = time()
  ns.plano = plano
  if type(CompraForeverCharDB) == "table" then CompraForeverCharDB.plano = plano end
  if ns.atualizarPainel then ns.atualizarPainel() end
  return plano
end

-- /compra --------------------------------------------------------------------------------------------

local function dizer(texto)
  print("CompraForever: " .. texto)
end

-- "<item> resto": item e um id numerico ou um link de item colado no chat (o nome do link tem espacos)
local function lerItem(arg)
  local id = string.match(arg, "|Hitem:(%d+)")
  if id then
    local nome = string.match(arg, "%[(.-)%]")
    local _, fim = string.find(arg, "|h%[.-%]|h")
    local resto = fim and string.sub(arg, fim + 1) or ""
    resto = strtrim((string.gsub(resto, "^|r", "")))
    return tonumber(id), nome, resto
  end
  local num, resto = string.match(arg, "^(%d+)%s*(.-)$")
  if num then return tonumber(num), nil, resto end
  return nil
end

local function comandoVigia(sub, arg)
  local db = ns.vigiaDB()
  if sub == "unwatch" then
    local id = lerItem(arg)
    if not id then dizer("usage: /compra unwatch <item id or link>") return end
    if ns.vigiaTirar(id) then dizer("unwatched " .. id) else dizer("not watched: " .. id) end
    return
  end
  if arg == "" then
    local lista = ns.vigiaListar()
    if #lista == 0 then dizer("watch list is empty") return end
    for _, x in ipairs(lista) do
      dizer(x.nome .. " (" .. x.id .. ") <= " .. ns.moeda(x.teto) .. ", buy " .. x.qtd .. ", last " .. ns.moeda(ns.vigiaUltimo(x.id)))
    end
    dizer("every " .. db.intervalo .. " s")
    return
  end
  local seg = string.match(string.lower(arg), "^every%s+(%S+)$")
  if seg then
    local n = tonumber(seg)
    if not n or n < 10 or n > 300 then dizer("every must be 10 to 300 seconds") return end
    ns.vigiaCada(floor(n))
    dizer("watch every " .. floor(n) .. " s")
    return
  end
  local id, nome, resto = lerItem(arg)
  local t, q = string.match(resto or "", "^(%S+)%s*(%S*)$")
  local teto = t and ns.lerValor(t)
  local qtd = nil
  if q and q ~= "" then
    qtd = tonumber(q)
    if not qtd or qtd < 1 or qtd ~= floor(qtd) then teto = nil end
  end
  if not id or not teto or teto < 1 then
    dizer("usage: /compra watch <item id or link> <max price> [qty] | watch every <10-300 s>")
    return
  end
  local it, novo = ns.vigiaPor(id, nome, teto, qtd)
  dizer((novo and "watching " or "updated ") .. it.nome .. " (" .. id .. ") <= " .. ns.moeda(it.teto) .. ", buy " .. it.qtd)
end

local function comandoVenda(sub, arg)
  if sub == "post" then
    if arg == "" then
      local lista = ns.vendaPendentes()
      if #lista == 0 then dizer("post queue is empty") return end
      for _, x in ipairs(lista) do
        dizer(x.qtd .. " " .. x.nome .. " @ " .. ns.moeda(x.preco) .. (x.auto and " (auto)" or ""))
      end
      return
    end
    if string.lower(arg) == "clear" then
      ns.vendaLimpar()
      dizer("post queue cleared")
      return
    end
    local id, nome, resto = lerItem(arg)
    local t, q = string.match(resto or "", "^(%S+)%s*(%S*)$")
    local auto = t and string.lower(t) == "auto"
    local preco = t and (auto and true or ns.lerValor(t))
    local qtd = nil
    if q and q ~= "" then
      qtd = tonumber(q)
      if not qtd or qtd < 1 or qtd ~= floor(qtd) then preco = nil end
    end
    if not id or not preco or (preco ~= true and preco < 1) then
      dizer("usage: /compra post <item id or link> <price|auto> [qty] | post | post clear")
      return
    end
    local p, erro = ns.vendaPedir(id, nome, preco ~= true and preco or nil, qtd)
    if not p then dizer(erro) return end
    dizer("queued " .. (qtd or "all") .. " " .. p.nome .. " @ " .. ns.moeda(p.preco))
    return
  end
  -- sell
  local id, _, resto = lerItem(arg)
  local piso = resto and (string.lower(resto) == "off" and "off" or ns.lerValor(resto))
  if not id or not piso or (piso ~= "off" and piso < 1) then
    dizer("usage: /compra sell <item id or link> <floor price|off>")
    return
  end
  if not ns.vendaPiso(id, piso ~= "off" and piso or nil) then dizer("watch it first") return end
  dizer(piso == "off" and ("sell floor off for " .. id) or ("sell floor for " .. id .. " is " .. ns.moeda(piso)))
end

-- /compra hunt (secao 13): <item> <alvo> [trava] liga ou ajusta; sem argumento mostra; off desliga com o resumo
local function resumoCaca(c)
  local media = c.qtd > 0 and ns.moeda(floor(c.gasto / c.qtd + 0.5)) or "-"
  return c.nome .. " (" .. c.id .. ") <= " .. ns.moeda(c.alvo) .. ", bought " .. c.qtd .. " avg " .. media .. ", spent "
    .. ns.moeda(c.gasto) .. " of " .. ns.moeda(c.trava)
end

local function comandoCaca(arg)
  local a = strtrim(arg or "")
  local baixo = string.lower(a)
  if a == "" then
    local c = ns.cacaDB()
    if not c then dizer("hunt is off. usage: /compra hunt <item id or link> <price> [cap] | hunt off") return end
    dizer("hunting " .. resumoCaca(c))
    return
  end
  if baixo == "off" or baixo == "stop" then
    local c = ns.cacaDesligar()
    if not c then dizer("hunt is off") return end
    dizer("hunt off: " .. resumoCaca(c))
    if ns.atualizarPainel then ns.atualizarPainel() end
    return
  end
  local id, nome, resto = lerItem(a)
  local t, q = string.match(resto or "", "^(%S+)%s*(%S*)$")
  local alvo = t and ns.lerValor(t)
  local trava = nil
  if q and q ~= "" then
    trava = ns.lerValor(q)
    if not trava or trava < 1 then alvo = nil end
  end
  if not id or not alvo or alvo < 1 then
    dizer("usage: /compra hunt <item id or link> <price> [cap] | hunt off")
    return
  end
  local c, mesmo = ns.cacaLigar(id, nome, alvo, trava)
  local tecla = type(CompraForeverDB) == "table" and CompraForeverDB.tecla
  dizer((mesmo and "hunt updated: " or "hunting ") .. c.nome .. " (" .. id .. ") <= " .. ns.moeda(c.alvo) .. ", cap "
    .. ns.moeda(c.trava) .. ((trava == nil and not mesmo) and " (default)" or "") .. ". Click the action button"
    .. (tecla and (" or press " .. tecla) or ""))
  if ns.atualizarPainel then ns.atualizarPainel() end
end

-- /compra key <TECLA|off>: tecla que clica o botao de acao, so com a AH aberta
local function comandoTecla(arg)
  local a = strtrim(arg or "")
  local db = CompraForeverDB
  if a == "" then
    dizer("key " .. (db.tecla or "none") .. " (only while the AH is open)")
    return
  end
  if string.lower(a) == "off" then
    db.tecla = nil
    if ns.aplicarTecla then ns.aplicarTecla() end
    dizer("key off")
    return
  end
  if not string.match(a, "^[%w%-]+$") then
    dizer("usage: /compra key <KEY like BUTTON4, F9 or CTRL-F> | key off")
    return
  end
  if string.upper(a) == db.teclaIsca then dizer(string.upper(a) .. " is already the bait key") return end
  db.tecla = string.upper(a)
  if ns.aplicarTecla then ns.aplicarTecla() end
  dizer("key " .. db.tecla .. " clicks the action button while the AH is open")
end

-- /compra bait <item> <preco> [qtd]: isca a preco fixo no botao proprio; sem argumento mostra; off desliga
local function comandoIsca(arg)
  local a = strtrim(arg or "")
  local baixo = string.lower(a)
  if a == "" then
    local i = ns.iscaDB()
    if not i then dizer("bait is off. usage: /compra bait <item id or link> <price> [qty] | bait off") return end
    dizer("bait " .. i.qtd .. " " .. i.nome .. " (" .. i.id .. ") @ " .. ns.moeda(i.preco) .. ", posted " .. (i.postadas or 0))
    return
  end
  if baixo == "off" or baixo == "stop" then
    local i = ns.iscaDesligar()
    if not i then dizer("bait is off") return end
    dizer("bait off: " .. i.nome .. ", posted " .. (i.postadas or 0))
    return
  end
  local id, nome, resto = lerItem(a)
  local t, q = string.match(resto or "", "^(%S+)%s*(%S*)$")
  local preco = t and ns.lerValor(t)
  local qtd = nil
  if q and q ~= "" then
    qtd = tonumber(q)
    if not qtd or qtd < 1 or qtd > 20 or qtd ~= floor(qtd) then preco = nil end
  end
  if not id or not preco or preco < 1 then
    dizer("usage: /compra bait <item id or link> <price> [qty 1-20] | bait off")
    return
  end
  local i = ns.iscaLigar(id, nome, preco, qtd)
  local tecla = type(CompraForeverDB) == "table" and CompraForeverDB.teclaIsca
  dizer("bait " .. i.qtd .. " " .. i.nome .. " (" .. id .. ") @ " .. ns.moeda(i.preco) .. ". Click the Bait button"
    .. (tecla and (" or press " .. tecla) or ""))
end

-- /compra baitkey <TECLA|off>: tecla do botao da isca, so com a AH aberta (nao pode ser a do botao de acao)
local function comandoTeclaIsca(arg)
  local a = strtrim(arg or "")
  local db = CompraForeverDB
  if a == "" then
    dizer("bait key " .. (db.teclaIsca or "none") .. " (only while the AH is open)")
    return
  end
  if string.lower(a) == "off" then
    db.teclaIsca = nil
    if ns.aplicarTecla then ns.aplicarTecla() end
    dizer("bait key off")
    return
  end
  if not string.match(a, "^[%w%-]+$") then
    dizer("usage: /compra baitkey <KEY like E, F9 or CTRL-B> | baitkey off")
    return
  end
  local k = string.upper(a)
  if k == db.tecla then dizer(k .. " is already the action key") return end
  db.teclaIsca = k
  if ns.aplicarTecla then ns.aplicarTecla() end
  dizer("bait key " .. k .. " clicks the Bait button while the AH is open")
end

local function achaProf(txt)
  txt = string.lower(txt or "")
  for _, p in ipairs(ns.PROFS) do
    if txt == p.slug or txt == string.lower(p.nome) or txt == string.lower(p.curto) then return p end
  end
  return nil
end

local function comandoModo(arg)
  local a, b = string.match(strtrim(arg or ""), "^(%S*)%s*(%S*)$")
  a = string.lower(a or "")
  if a == "" then
    dizer("mode " .. ns.rotuloModo(ns.modo()))
    local t = {}
    for _, m in ipairs(ns.modosDisponiveis()) do t[#t + 1] = ns.rotuloModo(m) end
    dizer("available: " .. table.concat(t, ", "))
    return
  end
  if a == "profit" or a == "lucro" then
    ns.definirModo({ tipo = "lucro" })
    dizer("mode Profit")
    return
  end
  local p = achaProf(a)
  if not p then
    dizer("usage: /compra mode [profit | <profession> [150|225|250]]")
    return
  end
  local alvos = alvosDe(p.slug)
  local alvo = alvos[1]
  if b ~= "" then
    alvo = tonumber(b)
    local ok = false
    for _, a in ipairs(alvos) do
      if a == alvo then ok = true end
    end
    if not ok then
      local txt = tostring(alvos[#alvos])
      if #alvos > 1 then txt = table.concat(alvos, ", ", 1, #alvos - 1) .. " or " .. txt end
      dizer("target must be " .. txt)
      return
    end
  end
  local rotas = rotasDados()
  if not (type(rotas.profs) == "table" and rotas.profs[p.slug]) then
    dizer("no route for " .. p.nome .. ": ask for an estimate")
    return
  end
  local visto = type(CompraForeverCharDB.prof) == "table" and CompraForeverCharDB.prof[p.slug]
  if not visto then dizer(p.nome .. " not seen on this character: open it once") end
  ns.definirModo({ tipo = "rota", prof = p.slug, alvo = alvo })
  dizer("mode " .. ns.rotuloModo(ns.modo()))
end

local function comandoPassos()
  local m = ns.modo()
  if m.tipo ~= "rota" then dizer("steps: not in a route mode") return end
  local pl = ns.plano
  if not (type(pl) == "table" and pl.modo == 2 and type(pl.rota) == "table" and pl.rota.prof == m.prof) then
    pl = ns.replanejar()
  end
  local passos = type(pl) == "table" and type(pl.rota) == "table" and pl.rota.passos
  if type(passos) ~= "table" or #passos == 0 then dizer("no steps") return end
  dizer(ns.rotuloModo(m) .. " steps")
  for _, x in ipairs(passos) do
    local est = x.estado == "feito" and "done" or (x.estado == "agora" and "now" or "next")
    dizer(est .. " " .. tostring(x.nome) .. " " .. x.de .. "-" .. x.ate .. " (" .. (x.n or 0) .. ")")
  end
end

local function comando(msg)
  msg = strtrim(msg or "")
  local sub, arg = string.match(msg, "^(%S+)%s*(.-)$")
  sub = sub and string.lower(sub) or ""
  local cfg = ns.config()
  if sub == "" then
    if ns.alternarPainel then ns.alternarPainel() else dizer("panel not available") end
  elseif sub == "reserva" or sub == "lucro" or sub == "grande" or sub == "pequena" then
    local campo = (sub == "reserva" and "reserva") or (sub == "lucro" and "lucroMin") or sub
    if arg == "" then
      dizer(sub .. " is " .. ns.moeda(cfg[campo]))
      return
    end
    local v = ns.lerValor(arg)
    if not v then dizer("invalid value (use copper, 1g20s, 50s or 30c)") return end
    cfg[campo] = v
    dizer(sub .. " set to " .. ns.moeda(v))
    ns.replanejar()
    if ns.atualizarPainel then ns.atualizarPainel() end
  elseif sub == "desconto" then
    if arg == "" then dizer("desconto is " .. cfg.desconto .. "%") return end
    local v = tonumber(arg)
    if not v or v < 0 or v > 99 then dizer("desconto must be 0-99") return end
    cfg.desconto = floor(v)
    dizer("desconto set to " .. cfg.desconto .. "%")
    ns.replanejar()
  elseif sub == "tolerance" or sub == "margin" then
    local campo, lim = sub == "tolerance" and "tolerancia" or "margem", sub == "tolerance" and 100 or 50
    if arg == "" then dizer(sub .. " is " .. (cfg[campo] or 0) .. "%") return end
    local v = tonumber(arg)
    if not v or v < 0 or v > lim then dizer(sub .. " must be 0-" .. lim) return end
    cfg[campo] = floor(v)
    dizer(sub .. " set to " .. cfg[campo] .. "%")
    ns.replanejar()
  elseif sub == "mode" then
    comandoModo(arg)
  elseif sub == "steps" then
    comandoPassos()
  elseif sub == "sonda" then
    if string.lower(arg) == "prof" then
      if ns.sondaProf then ns.sondaProf() else dizer("probe not available") end
    elseif ns.sonda then ns.sonda() else dizer("probe not available") end
  elseif sub == "watch" or sub == "unwatch" then
    if not (ns.vigiaDB and ns.vigiaDB()) then dizer("watch not available") return end
    comandoVigia(sub, arg)
  elseif sub == "post" or sub == "sell" then
    if not (ns.vendaPedir and ns.vigiaDB and ns.vigiaDB()) then dizer("post not available") return end
    comandoVenda(sub, arg)
  elseif sub == "hunt" then
    if not ns.cacaLigar then dizer("hunt not available") return end
    comandoCaca(arg)
  elseif sub == "key" then
    comandoTecla(arg)
  elseif sub == "bait" then
    if not ns.iscaLigar then dizer("bait not available") return end
    comandoIsca(arg)
  elseif sub == "baitkey" then
    comandoTeclaIsca(arg)
  elseif sub == "duration" then
    if arg == "" then dizer("dur " .. (cfg.duracao or 3)) return end
    local v = tonumber(arg)
    if not v or v < 1 or v > 3 or v ~= floor(v) then dizer("duration must be 1-3") return end
    cfg.duracao = v
    dizer("dur " .. v)
  else
    dizer("/compra [reserva <valor> | desconto <0-99> | lucro <valor> | grande <valor> | pequena <valor> | mode [profit|<prof> [150|225|250]] | tolerance [0-100] | margin [0-50] | steps | sonda [prof] | watch | unwatch | hunt | key | bait | baitkey | post | sell | duration]")
  end
end

SLASH_COMPRAFOREVER1 = "/compra"
SlashCmdList.COMPRAFOREVER = comando
