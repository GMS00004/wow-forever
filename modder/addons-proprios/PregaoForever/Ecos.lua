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

-- dinheiro antes e depois do eco: o PLAYER_MONEY que acabou de chegar e o que o eco explica
local function antesDepois()
  local depois = GetMoney()
  local antes = depois
  if din.quando and din.anterior and ns.mono() - din.quando <= 1 then antes = din.anterior end
  din.quando = nil
  return antes, depois
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
  local antes, depois = antesDepois()
  m.deposito = math.max(0, antes - depois)
  linha('post', chave, qtd, m.preco or 0, 'created', antes, depois)
  local maos = acharLote('maos', chave, qtd)
  if maos then
    ns.livro.lote({ seq = maos.seq, estado = 'postado' })
  else
    ns.livro.lote({ chave = chave, qtd = qtd, custo = 0, origem = 'coletado', estado = 'postado' })
  end
end

local function aoCancelado(_, auctionID)
  local m = memo[auctionID] or {}
  local chave = m.chave or ''
  local antes, depois = antesDepois()
  linha('cancel', chave, m.qtd or 1, m.preco or 0, 'cancelled', antes, depois)
  local l = acharLote('postado', chave, nil)
  if l then ns.livro.fecharLote(l.seq, 'retirado', 0) end
  memo[auctionID] = nil
end

local function registrarCompra(chave, qtd, eco)
  local antes, depois = antesDepois()
  local total = math.max(0, antes - depois)
  local un = 0
  if qtd > 0 then un = math.floor(total / qtd) end
  linha('buy', chave, qtd, un, eco, antes, depois)
  ns.livro.lote({ chave = chave, qtd = qtd, custo = total, origem = 'comprado', estado = 'maos' })
end

local function aoCompradoItem()
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
