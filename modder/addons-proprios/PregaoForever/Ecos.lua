-- Ecos.lua (PregaoForever): so observacao. Todo eco de leilao sem acao do addon em voo vira uma linha 'outside' no Livro
-- e o lote correspondente. Nao chama funcao de acao nem de consulta. Contrato: ARQUITETURA.md, secao 3.8.
local _, ns = ...
ns.ecos = ns.ecos or {}
local E = ns.ecos

-- auctionID -> { chave, qtd, preco, deposito }: so memoria, para o cancelamento saber de que leilao se trata
local memo = {}
local din = { atual = nil, anterior = nil, quando = nil }
local compra = { pendente = false, ultima = nil }

function E.emVoo()
  return nil
end

-- soma dos depositos pagos nos leiloes que ainda estao ativos (acrescimo ao contrato, para a banca)
function E.depositos()
  local soma = 0
  for _, m in pairs(memo) do soma = soma + (m.deposito or 0) end
  return soma
end

-- chave do item de um leilao proprio visto nesta sessao, ou nil (acrescimo ao contrato, para a visao Mine)
function E.chaveDoLeilao(auctionID)
  local m = memo[auctionID]
  if m and m.chave and m.chave ~= '' then return m.chave end
  return nil
end

local function chaveDe(itemKey)
  if type(itemKey) ~= 'table' or not itemKey.itemID then return '' end
  if ns.itens and ns.itens.chave then
    local ok, c = pcall(ns.itens.chave, itemKey)
    if ok and c then return c end
  end
  if (itemKey.itemLevel or 0) > 0 then
    return ns.txt(itemKey.itemID) .. ':' .. ns.txt(itemKey.itemLevel) .. ':' .. ns.txt(itemKey.itemSuffix or 0)
  end
  return ns.txt(itemKey.itemID)
end

-- le a lista de leiloes proprios que o cliente ja tem (nao e consulta: nada e pedido ao servidor)
local function lerProprios(podar)
  local api = C_AuctionHouse
  if not (api and api.GetNumOwnedAuctions and api.GetOwnedAuctionInfo) then return end
  local n = api.GetNumOwnedAuctions() or 0
  local vistos = {}
  for i = 1, n do
    local info = api.GetOwnedAuctionInfo(i)
    if info and info.auctionID then
      local m = memo[info.auctionID] or {}
      m.chave = chaveDe(info.itemKey)
      m.qtd = info.quantity or 1
      m.preco = info.buyoutAmount or info.bidAmount or 0
      memo[info.auctionID] = m
      vistos[info.auctionID] = true
    end
  end
  if podar then
    for id in pairs(memo) do
      if not vistos[id] then memo[id] = nil end
    end
  end
end

-- dinheiro antes e depois do eco, nas duas ordens. Se o PLAYER_MONEY acabou de chegar, fn(antes, depois) roda na
-- hora. Se o eco chegou primeiro (foi o que o cliente real fez numa compra em 2026-11-16), fn espera o proximo
-- PLAYER_MONEY, ou ESPERA_DINHEIRO segundos se ele nao vier (acao que nao mexe no dinheiro).
local ESPERA_DINHEIRO = 1
local esperando = {}
local function comDinheiro(fn)
  if din.quando and din.anterior and ns.mono() - din.quando <= 1 then
    local antes = din.anterior
    din.quando = nil
    fn(antes, GetMoney())
    return
  end
  local antes = GetMoney()
  local feito = false
  local function rodar()
    if feito then return end
    feito = true
    fn(antes, GetMoney())
  end
  esperando[#esperando + 1] = rodar
  ns.depois(ESPERA_DINHEIRO, rodar)
end

-- leiloes comprados nesta sessao: o cliente tambem dispara AUCTION_CANCELED para o leilao que o dono comprou
local comprados = {}
local ultimaCompra = nil
function E.eraCompra(auctionID)
  if auctionID and comprados[auctionID] then return true end
  if auctionID and memo[auctionID] then return false end
  return ultimaCompra ~= nil and (ns.mono() - ultimaCompra) <= 3
end

local function acharLote(estado, chave, qtd)
  if chave == '' then return nil end
  local ab = ns.livro.abertos()
  for i = 1, #ab do
    local l = ab[i]
    if l.estado == estado and l.chave == chave and (qtd == nil or l.qtd == qtd) then return l end
  end
  return nil
end

local function linha(verbo, chave, qtd, preco, eco, antes, depois)
  return ns.livro.acao({
    verbo = verbo, chave = chave, qtd = qtd, preco = preco, origem = 'outside',
    antes = antes, depois = depois, eco = eco, tEco = ns.servidor(),
  })
end

local function aoCriado(_, auctionID)
  lerProprios(false)
  local m = memo[auctionID] or {}
  memo[auctionID] = m
  local chave, qtd = m.chave or '', m.qtd or 1
  comDinheiro(function(antes, depois)
    m.deposito = math.max(0, antes - depois)
    linha('post', chave, qtd, m.preco or 0, 'created', antes, depois)
    local maos = acharLote('maos', chave, qtd)
    if maos then
      ns.livro.lote({ seq = maos.seq, estado = 'postado' })
    else
      ns.livro.lote({ chave = chave, qtd = qtd, custo = 0, origem = 'coletado', estado = 'postado' })
    end
  end)
end

local function aoCancelado(_, auctionID)
  -- no cliente real a compra chegou antes deste evento, entao a decisao e na hora
  if E.eraCompra(auctionID) then
    ns.log('info', 'canceled event of a bought auction ignored')
    return
  end
  local m = memo[auctionID] or {}
  local chave = m.chave or ''
  local antes = GetMoney()
  if din.quando and din.anterior and ns.mono() - din.quando <= 1 then antes = din.anterior end
  din.quando = nil
  linha('cancel', chave, m.qtd or 1, m.preco or 0, 'cancelled', antes, GetMoney())
  local l = acharLote('postado', chave, nil)
  if l then ns.livro.fecharLote(l.seq, 'retirado', 0) end
  memo[auctionID] = nil
end

local function registrarCompra(chave, qtd, eco)
  ultimaCompra = ns.mono()
  comDinheiro(function(antes, depois)
    local total = math.max(0, antes - depois)
    local un = 0
    if qtd > 0 then un = math.floor(total / qtd) end
    linha('buy', chave, qtd, un, eco, antes, depois)
    ns.livro.lote({ chave = chave, qtd = qtd, custo = total, origem = 'comprado', estado = 'maos' })
  end)
end

local function aoCompradoItem(_, auctionID)
  if auctionID then comprados[auctionID] = true end
  registrarCompra('', 1, 'bought')
end

local function aoCompraComumOk()
  if compra.ultima and ns.mono() - compra.ultima <= 0.5 then return end
  compra.pendente = true
  ns.depois(0, function()
    if compra.pendente then
      compra.pendente = false
      registrarCompra('', 1, 'purchased')
    end
  end)
end

local function aoCompradoComum(_, itemID, quantidade)
  compra.pendente = false
  compra.ultima = ns.mono()
  registrarCompra(ns.txt(itemID or 0), quantidade or 1, 'purchased')
end

local function aoProprios()
  lerProprios(true)
end

local function aoDinheiro()
  din.anterior = din.atual
  din.atual = GetMoney()
  din.quando = ns.mono()
  -- ecos que chegaram antes deste PLAYER_MONEY: rodam agora, com o dinheiro novo, e consomem a variacao
  if #esperando > 0 then
    local lista = esperando
    esperando = {}
    for i = 1, #lista do lista[i]() end
    din.quando = nil
  end
end

local function aoEntrar()
  if din.atual == nil then din.atual = GetMoney() end
end

ns.ao('PLAYER_LOGIN', aoEntrar)
ns.ao('PLAYER_ENTERING_WORLD', aoEntrar)
ns.ao('PLAYER_MONEY', aoDinheiro)
ns.ao('AUCTION_HOUSE_AUCTION_CREATED', aoCriado)
ns.ao('AUCTION_CANCELED', aoCancelado)
ns.ao('AUCTION_HOUSE_PURCHASE_COMPLETED', aoCompradoItem)
ns.ao('COMMODITY_PURCHASE_SUCCEEDED', aoCompraComumOk)
ns.ao('COMMODITY_PURCHASED', aoCompradoComum)
ns.ao('OWNED_AUCTIONS_UPDATED', aoProprios)
