local addon, ns = ...

-- Vigia: lista de itens com teto de compra, busca periodica com a AH aberta, alerta, oportunidade de compra e
-- historico de precos (CONTRATO secoes 5, 6 e 7). A compra em si e da Compra.lua (ns.vigiaOportunidade()).
-- CompraForeverDB.vigia = { itens = { [id] = { nome, teto, qtd } }, intervalo = 30, historico = { [id] = { { t, min, p25, unid } } } }

local min, max = math.min, math.max

local PADRAO_INTERVALO = 30
local PADRAO_QTD = 20
local MAX_HIST = 2000
local MAX_BUSCAS_MIN = 100     -- a documentacao da API pede no maximo 100 buscas por minuto

ns.vigia = { escadas = {}, em = nil, alerta = {} }
local V = ns.vigia

local ahAberta = false
local ciclo = 0                -- muda a cada reinicio: timers antigos se calam
local ultima = {}              -- id -> GetTime da ultima busca vigia

function ns.vigiaDB()
  local db = rawget(_G, "CompraForeverDB")
  return type(db) == "table" and db.vigia or nil
end

local function iniciarVigia()
  local db = CompraForeverDB
  if type(db.vigia) ~= "table" then db.vigia = {} end
  local v = db.vigia
  if type(v.itens) ~= "table" then v.itens = {} end
  if type(v.intervalo) ~= "number" then v.intervalo = PADRAO_INTERVALO end
  if type(v.historico) ~= "table" then v.historico = {} end
end

local function idsOrdenados(db)
  local ids = {}
  for id in pairs(db.itens) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

-- Lista, historico ---------------------------------------------------------------------------------------

function ns.vigiaNome(id)
  local d = rawget(_G, "CompraForeverDados")
  local it = d and d.itens and d.itens[id]
  if it and it.nome then return it.nome end
  local nome = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(id)
  if type(nome) == "string" and nome ~= "" then return nome end
  return "item " .. id
end

function ns.vigiaListar()
  local db = ns.vigiaDB()
  local lista = {}
  if not db then return lista end
  for _, id in ipairs(idsOrdenados(db)) do
    local it = db.itens[id]
    lista[#lista + 1] = { id = id, nome = it.nome, teto = it.teto, qtd = it.qtd }
  end
  return lista
end

-- ultimo preco minimo visto (cobre) ou nil
function ns.vigiaUltimo(id)
  local esc = V.escadas[id]
  if esc and esc[1] then return esc[1].preco end
  local db = ns.vigiaDB()
  local h = db and db.historico[id]
  local e = h and h[#h]
  if e and (e.min or 0) > 0 then return e.min end
  return nil
end

-- nome == nil: mantem o nome atual ou resolve pelo id. qtd == nil: mantem a atual ou usa o padrao.
function ns.vigiaPor(id, nome, teto, qtd)
  local db = ns.vigiaDB()
  if not db then return nil end
  local it = db.itens[id]
  local novo = it == nil
  if not it then
    it = {}
    db.itens[id] = it
  end
  it.nome = nome or it.nome or ns.vigiaNome(id)
  it.teto = teto
  it.qtd = qtd or it.qtd or PADRAO_QTD
  ns.vigiaReiniciar()
  return it, novo
end

function ns.vigiaTirar(id)
  local db = ns.vigiaDB()
  if not db or not db.itens[id] then return false end
  db.itens[id] = nil
  V.escadas[id] = nil
  V.alerta[id] = nil
  ultima[id] = nil
  return true
end

function ns.vigiaCada(seg)
  local db = ns.vigiaDB()
  if not db then return false end
  db.intervalo = seg
  ns.vigiaReiniciar()
  return true
end

-- preco da unidade na posicao 25% da escada acumulada por quantidade
local function p25De(esc)
  local total = 0
  for _, d in ipairs(esc) do total = total + d.qtd end
  if #esc == 0 or total == 0 then return 0 end
  if #esc == 1 then return esc[1].preco end
  local alvo, soma = total * 0.25, 0
  for _, d in ipairs(esc) do
    soma = soma + d.qtd
    if soma >= alvo then return d.preco end
  end
  return esc[#esc].preco
end

local function gravarHistorico(db, id, esc, em)
  local h = db.historico[id]
  if not h then
    h = {}
    db.historico[id] = h
  end
  local unid = 0
  for _, d in ipairs(esc) do unid = unid + d.qtd end
  h[#h + 1] = { t = em, min = esc[1] and esc[1].preco or 0, p25 = p25De(esc), unid = unid }
  while #h > MAX_HIST do table.remove(h, 1) end
end

-- Oportunidade -------------------------------------------------------------------------------------------

-- linha no formato de plano.leilao para o item, ou nil se nenhum degrau custa o teto ou menos
local function linhaDe(id, it, esc)
  if not esc or not it.teto then return nil end
  local barato = {}
  for _, d in ipairs(esc) do
    if d.preco <= it.teto then barato[#barato + 1] = d end
  end
  if #barato == 0 then return nil end
  local alvo = it.qtd or PADRAO_QTD
  local row = { id = id, nome = it.nome, precoMax = it.teto, vigia = true }
  if not barato[1].inteiro then
    local falta, custo, qtd = alvo, 0, 0
    for _, d in ipairs(barato) do
      local n = min(d.qtd, falta)
      custo = custo + n * d.preco
      qtd = qtd + n
      falta = falta - n
      if falta <= 0 then break end
    end
    row.qtd, row.custo, row.inteiro = qtd, custo, false
  else
    -- leilao inteiro: lote a lote (um PlaceBid por clique) ate juntar a quantidade pedida
    local lotes, qtd, custo = {}, 0, 0
    for _, d in ipairs(barato) do
      lotes[#lotes + 1] = d
      qtd = qtd + d.qtd
      custo = custo + (d.total or d.preco * d.qtd)
      if qtd >= alvo then break end
    end
    row.qtd, row.custo, row.inteiro, row.lotes = qtd, custo, true, lotes
  end
  return row
end

local function todasOportunidades()
  local db = ns.vigiaDB()
  local out = {}
  if not db then return out end
  for _, id in ipairs(idsOrdenados(db)) do
    local it = db.itens[id]
    local esc = V.escadas[id]
    local row = linhaDe(id, it, esc)
    if row then out[#out + 1] = { row = row, rel = esc[1].preco / max(1, it.teto) } end
  end
  table.sort(out, function(a, b)
    if a.rel ~= b.rel then return a.rel < b.rel end
    return a.row.id < b.row.id
  end)
  return out
end

function ns.vigiaOportunidade()
  local o = todasOportunidades()[1]
  return o and o.row or nil
end

local function alertar(row, preco)
  PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959)
  local texto = row.nome .. " at " .. ns.moeda(preco) .. " (watch <= " .. ns.moeda(row.precoMax) .. ")"
  if RaidNotice_AddMessage and RaidWarningFrame then
    local cor = ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] or { r = 1, g = 1, b = 1 }
    RaidNotice_AddMessage(RaidWarningFrame, texto, cor)
  else
    print("CompraForever: " .. texto)
  end
end

-- alerta so na passagem de "sem oportunidade" para "com oportunidade", por id
function ns.vigiaAvaliar()
  local db = ns.vigiaDB()
  if not db then return end
  local tem = {}
  for _, o in ipairs(todasOportunidades()) do
    local id = o.row.id
    tem[id] = true
    if not V.alerta[id] then
      V.alerta[id] = true
      alertar(o.row, V.escadas[id][1].preco)
    end
  end
  for id in pairs(V.alerta) do
    if not tem[id] then V.alerta[id] = nil end
  end
end

-- o preco subiu na cotacao: a escada guardada ficou velha
function ns.vigiaInvalidar(id)
  V.escadas[id] = nil
  V.alerta[id] = nil
end

-- grava no historico e guarda as escadas dos ids vigiados; sem = ids que nao responderam (ficam como estavam)
function ns.vigiaRegistrar(escadas, em, sem)
  local db = ns.vigiaDB()
  if not db or type(escadas) ~= "table" then return end
  local pular = {}
  for _, id in ipairs(sem or {}) do pular[id] = true end
  em = em or time()
  local houve = false
  for _, id in ipairs(idsOrdenados(db)) do
    local esc = escadas[id]
    if esc and not pular[id] then
      V.escadas[id] = esc
      gravarHistorico(db, id, esc, em)
      houve = true
    end
  end
  if houve then V.em = em end
  ns.vigiaAvaliar()
  if ns.atualizarPainel then ns.atualizarPainel() end
end

-- Busca periodica ------------------------------------------------------------------------------------------

local tick

local function agendar(seg)
  local tok = ciclo
  C_Timer.After(seg, function() tick(tok) end)
end

tick = function(tok)
  if tok ~= ciclo or not ahAberta then return end
  local db = ns.vigiaDB()
  if not db then return end
  local todos = idsOrdenados(db)
  if #todos == 0 then return end
  local intervalo = max(db.intervalo or PADRAO_INTERVALO, #todos * 60 / MAX_BUSCAS_MIN)
  local agora = GetTime()
  local ids, resta = {}, nil
  for _, id in ipairs(todos) do
    local r = intervalo - (agora - (ultima[id] or -1e9))
    if r <= 0 then ids[#ids + 1] = id else resta = min(resta or r, r) end
  end
  if #ids == 0 then
    agendar(max(0.5, resta or 1))
    return
  end
  if (ns.scanEstado and ns.scanEstado.ocupado) or (ns.compraOcupada and ns.compraOcupada()) then
    agendar(2)
    return
  end
  local t0 = agora
  local ok = ns.buscarVigia and ns.buscarVigia(ids, function(escadas, sem)
    if escadas then
      ns.vigiaRegistrar(escadas, time(), sem)
      if tok == ciclo then agendar(max(1, intervalo - (GetTime() - t0))) end
    elseif tok == ciclo then
      agendar(2)
    end
  end)
  if not ok then
    agendar(2)
    return
  end
  for _, id in ipairs(ids) do ultima[id] = t0 end
end

-- recomeca o ciclo: primeira busca 2 s depois (ids ja buscados esperam o intervalo)
function ns.vigiaReiniciar()
  ciclo = ciclo + 1
  local db = ns.vigiaDB()
  if ahAberta and db and next(db.itens) then agendar(2) end
end

ns.ao("ADDON_LOADED", function(nome)
  if nome == addon then iniciarVigia() end
end)

ns.ao("AUCTION_HOUSE_SHOW", function()
  ahAberta = true
  V.escadas, V.alerta = {}, {}
  ns.vigiaReiniciar()
end)

ns.ao("AUCTION_HOUSE_CLOSED", function()
  ahAberta = false
  ciclo = ciclo + 1
end)
