-- Falso do WoW para a bancada do PregaoForever: itens, bolsas, casa de leilao, throttle, dinheiro, correio.
-- Sequencia de eventos pela tabela nominal do DESIGN.md (secao 16); a real sai das sondas S2, S4 e S8.
-- Fengari (Lua 5.3). So ASCII. Carregado depois de nucleo.lua.

local B = __bancada
local J = B.J
local registrar = B.registrar
local pack, unpack = table.pack, table.unpack
local floor, ceil, min, max = math.floor, math.ceil, math.min, math.max

local A = {
  aberto = false, epoca = 0, fila = {}, ocupado = false, preso = false, travado = false, descartar = 0,
  inj = {}, mercado = {}, proprios = {}, bolsas = {}, itens = {}, naoCarregados = {}, correio = {},
  busca = {}, browse = nil, cotacao = nil, postPendente = nil, proxId = 1000, depositoNulo = false,
  P = {
    pagina_resumo = 480,    -- linhas por pedido do resumo (base 2.6)
    pagina_escada = 50,     -- linhas por pagina da busca por item
    t_envio = 0.1,          -- fila -> SENT (s)
    t_resposta = 0.3,       -- SENT -> RESPONSE_RECEIVED (s)
    t_pronto = 0.1,         -- resposta -> SYSTEM_READY (s)
    t_acao = 0.3,           -- latencia do eco de uma acao (s)
    deposito_pct = 0.15,    -- fracao do preco de vendedor por 12 h
    corte_pct = 0.05,       -- corte da casa na fatura
    atraso_correio = 3600,  -- segundos entre a venda e o ouro
    pagina_correio = 50,    -- cartas mostradas pela caixa
    tamanho_bolsa = 16,
  },
}
B.A = A

-- ---------------------------------------------------------------------------
-- Itens
-- ---------------------------------------------------------------------------
local PADRAO = {
  [2589] = { nome = "Linen Cloth", vend = 13, pilha = 20, qual = 1, nivel = 5 },
  [2592] = { nome = "Wool Cloth", vend = 41, pilha = 20, qual = 1, nivel = 10 },
  [4306] = { nome = "Silk Cloth", vend = 120, pilha = 20, qual = 1, nivel = 20 },
  [2318] = { nome = "Light Leather", vend = 6, pilha = 20, qual = 1, nivel = 5 },
  [2319] = { nome = "Medium Leather", vend = 25, pilha = 20, qual = 1, nivel = 10 },
  [4234] = { nome = "Heavy Leather", vend = 49, pilha = 20, qual = 1, nivel = 20 },
}

local function def(id)
  local d = A.itens[id] or PADRAO[id] or {}
  local r = {
    nome = d.nome or ("Item " .. tostring(id)), vend = d.vend or 0, pilha = d.pilha or 1, qual = d.qual or 1,
    nivel = d.nivel or 1, tipo = d.tipo or "Miscellaneous", sub = d.sub or "Junk",
  }
  if d.commodity ~= nil then r.commodity = d.commodity else r.commodity = r.pilha > 1 end
  return r
end
B.itemDef = def

local function link(id) return "|cffffffff|Hitem:" .. tostring(id) .. "::::::::60:::::::|h[" .. def(id).nome .. "]|h|r" end

local function idDeLink(x)
  if type(x) == "number" then return x end
  if type(x) == "string" then
    local n = string.match(x, "item:(%d+)")
    if n then return tonumber(n) end
    local m = tonumber(x)
    if m then return m end
  end
  return nil
end

function B.mudarDinheiro(delta)
  J.dinheiro = J.dinheiro + delta
  B.disparar("PLAYER_MONEY")
end

-- ---------------------------------------------------------------------------
-- Bolsas, ItemLocation, C_Container, C_Item
-- ---------------------------------------------------------------------------
local function itemEm(bag, slot)
  local b = A.bolsas[bag]
  return b and b[slot] or nil
end

local function tamanhoDaBolsa(bag)
  if type(bag) ~= "number" or bag < 0 or bag > 4 then return 0 end
  return A.P.tamanho_bolsa
end

C_Container = {}
B.def(C_Container, "C_Container", "GetContainerNumSlots", function(bag) return tamanhoDaBolsa(bag) end)
B.def(C_Container, "C_Container", "GetContainerItemInfo", function(bag, slot)
  local it = itemEm(bag, slot)
  if not it then return nil end
  local d = def(it.itemID)
  return {
    iconFileID = 134400, stackCount = it.qtd, isLocked = false, quality = d.qual, isReadable = false, hasLoot = false,
    hyperlink = link(it.itemID), isFiltered = false, hasNoValue = d.vend == 0, itemID = it.itemID, isBound = false,
  }
end)
B.def(C_Container, "C_Container", "GetContainerItemLink", function(bag, slot)
  local it = itemEm(bag, slot)
  return it and link(it.itemID) or nil
end)
B.def(C_Container, "C_Container", "GetContainerItemID", function(bag, slot)
  local it = itemEm(bag, slot)
  return it and it.itemID or nil
end)
B.def(C_Container, "C_Container", "GetContainerNumFreeSlots", function(bag)
  local n = tamanhoDaBolsa(bag)
  local livres = 0
  for s = 1, n do if not itemEm(bag, s) then livres = livres + 1 end end
  return livres, 0
end)

local LocMT = {}
LocMT.__index = {
  GetBagAndSlot = function(self) return self.bagID, self.slotIndex end,
  IsBagAndSlot = function(self) return self.bagID ~= nil end,
  HasAnyLocation = function(self) return self.bagID ~= nil end,
  IsValid = function(self) return self.bagID ~= nil end,
}
ItemLocation = {}
function ItemLocation:CreateFromBagAndSlot(bag, slot)
  registrar("CreateFromBagAndSlot", "ItemLocation.CreateFromBagAndSlot", bag, slot)
  return setmetatable({ bagID = bag, slotIndex = slot }, LocMT)
end
function ItemLocation:CreateEmpty() return setmetatable({}, LocMT) end

local function itemDeLoc(loc)
  if type(loc) ~= "table" or loc.bagID == nil then return nil end
  return itemEm(loc.bagID, loc.slotIndex)
end

C_Item = {}
B.def(C_Item, "C_Item", "DoesItemExist", function(loc) return itemDeLoc(loc) ~= nil end)
B.def(C_Item, "C_Item", "GetItemID", function(loc) local it = itemDeLoc(loc) return it and it.itemID or nil end)
B.def(C_Item, "C_Item", "GetItemLink", function(loc) local it = itemDeLoc(loc) return it and link(it.itemID) or nil end)
B.def(C_Item, "C_Item", "GetItemName", function(loc) local it = itemDeLoc(loc) return it and def(it.itemID).nome or nil end)
B.def(C_Item, "C_Item", "GetStackCount", function(loc) local it = itemDeLoc(loc) return it and it.qtd or 0 end)
B.def(C_Item, "C_Item", "GetItemQuality", function(loc) local it = itemDeLoc(loc) return it and def(it.itemID).qual or nil end)
B.def(C_Item, "C_Item", "GetItemCount", function(id)
  id = idDeLink(id)
  local n = 0
  for b = 0, 4 do for s = 1, tamanhoDaBolsa(b) do
    local it = itemEm(b, s)
    if it and it.itemID == id then n = n + it.qtd end
  end end
  return n
end)

local function infoDeItem(x)
  local id = idDeLink(x)
  if not id or A.naoCarregados[id] then return nil end
  local d = def(id)
  -- nome, link, qualidade, nivel, nivel minimo, tipo, subtipo, pilha, equipLoc, icone, preco de vendedor (11o), ...
  return d.nome, link(id), d.qual, d.nivel, 1, d.tipo, d.sub, d.pilha, "", 134400, d.vend, 7, 0, 0, 0, nil, false
end
B.def(C_Item, "C_Item", "GetItemInfo", infoDeItem)
B.def(C_Item, "C_Item", "GetItemInfoInstant", function(x)
  local id = idDeLink(x)
  if not id then return nil end
  local d = def(id)
  return id, d.tipo, d.sub, "", 134400, 7, 0
end)
B.def(C_Item, "C_Item", "RequestLoadItemDataByID", function(id)
  id = idDeLink(id)
  if not id then return end
  B.agendar(0.2, function()
    A.naoCarregados[id] = nil
    B.disparar("ITEM_DATA_LOAD_RESULT", id, true)
  end)
end)
GetItemInfo = function(x) registrar("GetItemInfo", nil, x) return infoDeItem(x) end

-- ---------------------------------------------------------------------------
-- Casa de leilao: chaves, mercado, resultados
-- ---------------------------------------------------------------------------
Enum.ItemCommodityStatus = { Unknown = 0, Item = 1, Commodity = 2 }
Enum.AuctionHouseError = {
  DatabaseError = 0, NotEnoughMoney = 1, ItemNotFound = 2, ItemHasQuote = 3, BidIncrement = 4, HigherBid = 5,
  BidOwn = 6, RestrictedAccountTrial = 7, HasRestriction = 8, IsBusy = 9, Unavailable = 10, UsedCharges = 11,
}

local function chaveItem(k) return tostring(k.itemID) .. ":" .. tostring(k.itemLevel or 0) .. ":" .. tostring(k.itemSuffix or 0) end
local function novaItemKey(id, nivel, sufixo) return { itemID = id, itemLevel = nivel or 0, itemSuffix = sufixo or 0, battlePetSpeciesID = 0 } end

local function ordenarRows(rows)
  table.sort(rows, function(a, b)
    if a.preco ~= b.preco then return a.preco < b.preco end
    return a.id < b.id
  end)
  return rows
end

local function donos(r)
  local t = {}
  for i = 1, (r.donos or 1) do t[i] = "Vendedor" .. tostring(i) end
  return t
end

local function infoCommodity(id, r)
  return {
    itemID = id, quantity = r.qtd, unitPrice = r.preco, auctionID = r.id, owners = donos(r),
    totalNumberOfOwners = r.donos or 1, containsOwnerItem = r.proprio == true, containsAccountItem = false,
    numOwnerItems = r.proprio and r.qtd or 0, timeLeftSeconds = r.tempo_s or 7200, timeLeft = 2,
  }
end

local function infoItem(id, r)
  return {
    itemKey = novaItemKey(id, r.nivel, r.sufixo), owners = donos(r), totalNumberOfOwners = r.donos or 1,
    timeLeft = 2, timeLeftSeconds = r.tempo_s or 7200, quantity = r.qtd or 1, buyoutAmount = r.preco, bidAmount = r.lance,
    containsOwnerItem = r.proprio == true, containsAccountItem = false, auctionID = r.id, itemLink = link(id),
  }
end

local function rowsDe(chave, id, nivel, sufixo)
  local out = {}
  for _, r in ipairs(A.mercado[id] or {}) do
    if chave == "c" or ((r.nivel or 0) == (nivel or 0) and (r.sufixo or 0) == (sufixo or 0)) then out[#out + 1] = r end
  end
  return ordenarRows(out)
end

-- linhas do resumo: um BrowseResultInfo por itemKey, ordenado por itemID e nivel
local function montarResumo(query)
  local filtro = query and type(query.searchString) == "string" and string.lower(query.searchString) or ""
  local grupos, ordem = {}, {}
  for id, rows in pairs(A.mercado) do
    local nome = string.lower(def(id).nome)
    if filtro == "" or string.find(nome, filtro, 1, true) then
      for _, r in ipairs(rows) do
        local com = def(id).commodity
        local k = com and novaItemKey(id) or novaItemKey(id, r.nivel, r.sufixo)
        local ch = chaveItem(k)
        local g = grupos[ch]
        if not g then
          g = { itemKey = k, totalQuantity = 0, minPrice = nil, containsOwnerItem = false }
          grupos[ch] = g
          ordem[#ordem + 1] = g
        end
        g.totalQuantity = g.totalQuantity + (r.qtd or 1)
        if not g.minPrice or r.preco < g.minPrice then g.minPrice = r.preco end
        if r.proprio then g.containsOwnerItem = true end
      end
    end
  end
  table.sort(ordem, function(a, b)
    if a.itemKey.itemID ~= b.itemKey.itemID then return a.itemKey.itemID < b.itemKey.itemID end
    if a.itemKey.itemLevel ~= b.itemKey.itemLevel then return a.itemKey.itemLevel < b.itemKey.itemLevel end
    return a.itemKey.itemSuffix < b.itemKey.itemSuffix
  end)
  return ordem
end

-- ---------------------------------------------------------------------------
-- Throttle: fila, uma mensagem por vez, travado e descartada injetaveis
-- ---------------------------------------------------------------------------
local processar

local function terminar(ep)
  B.agendar(A.P.t_pronto, function()
    if ep ~= A.epoca then return end
    if A.travado then A.preso = true return end
    A.ocupado = false
    B.disparar("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
    processar()
  end)
end

processar = function()
  if A.ocupado or A.travado or #A.fila == 0 or not A.aberto then return end
  local msg = table.remove(A.fila, 1)
  A.ocupado = true
  local ep = A.epoca
  B.agendar(A.P.t_envio, function()
    if ep ~= A.epoca then return end
    if A.descartar > 0 then
      A.descartar = A.descartar - 1
      B.disparar("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED")
      terminar(ep)
      return
    end
    B.disparar("AUCTION_HOUSE_THROTTLED_MESSAGE_SENT")
    B.agendar(A.P.t_resposta, function()
      if ep ~= A.epoca then return end
      B.disparar("AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED")
      msg.resposta()
      terminar(ep)
    end)
  end)
end

local function umaVez(nome)
  local n = A.inj[nome]
  if n and n > 0 then A.inj[nome] = n - 1 return true end
  return false
end

-- uma consulta ao leilao: confere I9, enfileira e escalona o evento QUEUED
local function enviar(nome, resposta)
  if not A.aberto then
    B.violar("fechado", nome .. " com o leilao fechado")
    return
  end
  local tp = (B.ns and type(B.ns.cfg) == "table" and tonumber(B.ns.cfg.T_pulso)) or 90
  if not B.ultimaTecla or (B.agoraUs() - B.ultimaTecla) / 1000000 > tp then
    B.violar("I9", nome .. " sem tecla do dono nos ultimos " .. tostring(tp) .. " s")
  end
  local ep = A.epoca
  A.fila[#A.fila + 1] = { nome = nome, resposta = resposta }
  B.agendar(0, function()
    if ep == A.epoca then B.disparar("AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED") end
  end)
  processar()
end

C_AuctionHouse = {}
local function AH(nome, fn) B.def(C_AuctionHouse, "C_AuctionHouse", nome, fn) end

AH("IsThrottledMessageSystemReady", function()
  return A.aberto and not A.ocupado and #A.fila == 0 and not A.travado
end)

AH("MakeItemKey", function(id, nivel, sufixo, pet) return { itemID = id, itemLevel = nivel or 0, itemSuffix = sufixo or 0, battlePetSpeciesID = pet or 0 } end)

-- ---------------------------------------------------------------------------
-- Consultas
-- ---------------------------------------------------------------------------
AH("SendBrowseQuery", function(query)
  local sem, falha, encolhe = umaVez("sem_resposta"), umaVez("browse_falha"), umaVez("lista_encolhe")
  enviar("SendBrowseQuery", function()
    if sem then return end
    if falha then B.disparar("AUCTION_HOUSE_BROWSE_FAILURE") return end
    local linhas = montarResumo(query)
    if encolhe then
      local novas = {}
      for i = 1, floor(#linhas * 0.8) do novas[i] = linhas[i] end
      linhas = novas
    end
    A.browse = { linhas = linhas, mostradas = min(A.P.pagina_resumo, #linhas) }
    B.disparar("AUCTION_HOUSE_NEW_RESULTS_RECEIVED")
    B.disparar("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
  end)
end)

AH("GetBrowseResults", function()
  local out = {}
  if A.browse then for i = 1, A.browse.mostradas do out[i] = A.browse.linhas[i] end end
  return out
end)
AH("HasFullBrowseResults", function() return not A.browse or A.browse.mostradas >= #A.browse.linhas end)

AH("RequestMoreBrowseResults", function()
  local sem, nao = umaVez("sem_resposta"), umaVez("pagina_nao_chega")
  local br = A.browse
  if not br or br.mostradas >= #br.linhas then return end
  enviar("RequestMoreBrowseResults", function()
    if sem or nao or br ~= A.browse then return end
    local ini, fim = br.mostradas + 1, min(br.mostradas + A.P.pagina_resumo, #br.linhas)
    local add = {}
    for i = ini, fim do add[#add + 1] = br.linhas[i] end
    br.mostradas = fim
    B.disparar("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", add)
  end)
end)

-- busca por item (commodity ou item): estado por chave
local function chaveBusca(ehCom, id, k)
  if ehCom then return "c" .. tostring(id) end
  return "i" .. chaveItem(k)
end

local function montarBusca(ehCom, id, k)
  local rows = rowsDe(ehCom and "c" or "i", id, k and k.itemLevel, k and k.itemSuffix)
  local out = {}
  for i, r in ipairs(rows) do out[i] = ehCom and infoCommodity(id, r) or infoItem(id, r) end
  return out
end

local function consultaBusca(nome, k, ehCom)
  local id = k.itemID
  local sem, vazia, outra, semFrente, atualizado = umaVez("sem_resposta"), umaVez("busca_vazia"), umaVez("busca_outra_chave"), umaVez("busca_sem_frente"), umaVez("item_atualizado")
  enviar(nome, function()
    if sem then return end
    local rows = vazia and {} or montarBusca(ehCom, id, k)
    local est = { rows = rows, mostradas = min(A.P.pagina_escada, #rows), ocultas = 0 }
    if semFrente and #rows > 1 then est.ocultas = min(A.semFrenteN or 3, #rows - 1) end
    A.busca[chaveBusca(ehCom, id, k)] = est
    local kEv = k
    if outra then kEv = novaItemKey(id + 1, k.itemLevel, k.itemSuffix) end
    B.disparar("AUCTION_HOUSE_NEW_RESULTS_RECEIVED", kEv)
    if ehCom then
      B.disparar("COMMODITY_SEARCH_RESULTS_UPDATED", kEv.itemID)
      B.disparar("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")   -- espurio: a lista do resumo muda junto
    else
      if atualizado then B.disparar("ITEM_SEARCH_RESULTS_UPDATED", kEv, A.proxId) end
      B.disparar("ITEM_SEARCH_RESULTS_UPDATED", kEv)
    end
  end)
end

local function ehComDeKey(k) return def(k.itemID).commodity end

AH("SendSearchQuery", function(k, sorts, separar)
  if type(k) ~= "table" then error("bancada: SendSearchQuery sem itemKey", 2) end
  consultaBusca("SendSearchQuery", k, ehComDeKey(k))
end)
AH("SendSellSearchQuery", function(k, sorts, separar)
  if type(k) ~= "table" then error("bancada: SendSellSearchQuery sem itemKey", 2) end
  consultaBusca("SendSellSearchQuery", k, ehComDeKey(k))
end)
AH("RefreshCommoditySearchResults", function(id)
  consultaBusca("RefreshCommoditySearchResults", novaItemKey(id), true)
end)
AH("RefreshItemSearchResults", function(k)
  consultaBusca("RefreshItemSearchResults", k, false)
end)

local function maisBusca(nome, k, ehCom)
  local sem, nao = umaVez("sem_resposta"), umaVez("pagina_nao_chega")
  local est = A.busca[chaveBusca(ehCom, k.itemID, k)]
  if not est then return end
  if est.mostradas >= #est.rows and est.ocultas == 0 then return end
  enviar(nome, function()
    if sem or nao or est ~= A.busca[chaveBusca(ehCom, k.itemID, k)] then return end
    if est.ocultas > 0 then est.ocultas = 0 else est.mostradas = min(est.mostradas + A.P.pagina_escada, #est.rows) end
    if ehCom then B.disparar("COMMODITY_SEARCH_RESULTS_ADDED", k.itemID) else B.disparar("ITEM_SEARCH_RESULTS_ADDED", k) end
  end)
end
AH("RequestMoreCommoditySearchResults", function(id) maisBusca("RequestMoreCommoditySearchResults", novaItemKey(id), true) end)
AH("RequestMoreItemSearchResults", function(k) maisBusca("RequestMoreItemSearchResults", k, false) end)

local function visiveis(ehCom, id, k)
  local est = A.busca[chaveBusca(ehCom, id, k)]
  if not est then return nil end
  return est
end
AH("GetNumCommoditySearchResults", function(id)
  local e = visiveis(true, id) if not e then return 0 end
  return max(0, e.mostradas - e.ocultas)
end)
AH("GetCommoditySearchResultInfo", function(id, i)
  local e = visiveis(true, id) if not e then return nil end
  if i < 1 or i > e.mostradas - e.ocultas then return nil end
  return e.rows[e.ocultas + i]
end)
AH("GetCommoditySearchResultsQuantity", function(id)
  local e = visiveis(true, id) if not e then return 0 end
  local q = 0
  for i = e.ocultas + 1, e.mostradas do q = q + e.rows[i].quantity end
  return q
end)
AH("HasFullCommoditySearchResults", function(id)
  local e = visiveis(true, id) if not e then return false end
  return e.mostradas >= #e.rows and e.ocultas == 0
end)
AH("GetNumItemSearchResults", function(k)
  local e = visiveis(false, k.itemID, k) if not e then return 0 end
  return max(0, e.mostradas - e.ocultas)
end)
AH("GetItemSearchResultInfo", function(k, i)
  local e = visiveis(false, k.itemID, k) if not e then return nil end
  if i < 1 or i > e.mostradas - e.ocultas then return nil end
  return e.rows[e.ocultas + i]
end)
AH("GetItemSearchResultsQuantity", function(k)
  local e = visiveis(false, k.itemID, k) if not e then return 0 end
  return max(0, e.mostradas - e.ocultas)
end)
AH("HasFullItemSearchResults", function(k)
  local e = visiveis(false, k.itemID, k) if not e then return false end
  return e.mostradas >= #e.rows and e.ocultas == 0
end)

-- leiloes proprios
AH("QueryOwnedAuctions", function(sorts)
  local sem = umaVez("sem_resposta")
  enviar("QueryOwnedAuctions", function()
    if sem then return end
    B.disparar("OWNED_AUCTIONS_UPDATED")
  end)
end)
AH("GetNumOwnedAuctions", function() return #A.proprios end)
AH("HasFullOwnedAuctionResults", function() return true end)
AH("GetOwnedAuctionInfo", function(i)
  local r = A.proprios[i]
  if not r then return nil end
  local com = def(r.itemID).commodity
  return {
    auctionID = r.id, itemKey = novaItemKey(r.itemID), itemLink = link(r.itemID), status = r.status or 0, quantity = r.qtd,
    timeLeftSeconds = r.tempo_s or 43200, timeLeft = 3, buyoutAmount = r.preco, bidAmount = r.lance, bidder = nil,
    itemName = def(r.itemID).nome, isCommodity = com,
  }
end)

-- ---------------------------------------------------------------------------
-- Itens e depositos
-- ---------------------------------------------------------------------------
local HORAS = { [1] = 12, [2] = 24, [3] = 48 }
local function deposito(id, duracao, qtd)
  if A.depositoNulo then return 0 end
  return floor(def(id).vend * (qtd or 1) * A.P.deposito_pct * (HORAS[duracao] or 12) / 12)
end

AH("GetItemKeyFromItem", function(loc)
  local it = itemDeLoc(loc)
  if not it then return nil end
  return novaItemKey(it.itemID, def(it.itemID).commodity and 0 or def(it.itemID).nivel, 0)
end)
AH("GetItemCommodityStatus", function(loc)
  local it = itemDeLoc(loc)
  if not it then return Enum.ItemCommodityStatus.Unknown end
  if A.naoCarregados[it.itemID] then return Enum.ItemCommodityStatus.Unknown end
  return def(it.itemID).commodity and Enum.ItemCommodityStatus.Commodity or Enum.ItemCommodityStatus.Item
end)
AH("GetItemKeyInfo", function(k)
  if type(k) ~= "table" or A.naoCarregados[k.itemID] then return nil end
  local d = def(k.itemID)
  return { itemName = d.nome, battlePetLink = nil, appearanceLink = nil, quality = d.qual, iconFileID = 134400, isPet = false, isCommodity = d.commodity, isEquipment = false }
end)
AH("CalculateItemDeposit", function(loc, duracao, qtd)
  local it = itemDeLoc(loc)
  if not it then error("bancada: CalculateItemDeposit pede um ItemLocation com item na bolsa", 2) end
  return deposito(it.itemID, duracao, qtd)
end)
AH("CalculateCommodityDeposit", function(id, duracao, qtd)
  return deposito(id, duracao, qtd)
end)

-- ---------------------------------------------------------------------------
-- Correio
-- ---------------------------------------------------------------------------
local function cartaDeInicio(c)
  local f = c.fatura
  return {
    remetente = c.remetente or "Auction House", assunto = c.assunto or "Auction", dinheiro = c.dinheiro or 0, cod = c.cod or 0,
    dias = c.dias or 30, itens = c.itens or 0, lida = c.lida or false, devolvida = c.devolvida or false,
    textoCriado = c.texto_criado or false, texto = c.texto or "", fatura = f and {
      tipo = f.tipo or "seller", item = f.item or "Item", jogador = f.jogador or "Compradorfalso", lance = f.lance or 0,
      compra = f.compra or 0, deposito = f.deposito or 0, corte = f.corte or 0, atraso = f.atraso or 0,
      hora = f.hora or 0, min = f.min or 0, qtd = f.qtd or 1, comercio = f.comercio ~= false,
    } or nil,
  }
end

function GetInboxNumItems()
  registrar("GetInboxNumItems")
  return min(#A.correio, A.P.pagina_correio), #A.correio
end
function GetInboxHeaderInfo(i)
  registrar("GetInboxHeaderInfo", nil, i)
  local c = A.correio[i]
  if not c or i > A.P.pagina_correio then return nil end
  return 134400, "Interface\\Icons\\INV_Letter_15", c.remetente, c.assunto, c.dinheiro, c.cod, c.dias, c.itens, c.lida, c.devolvida, c.textoCriado, not c.fatura, false
end
function GetInboxText(i)
  registrar("GetInboxText", nil, i)
  local c = A.correio[i]
  if not c then return nil end
  c.lida = true
  c.textoCriado = true
  return c.texto, "Interface\\Icons\\INV_Letter_15", false, c.fatura ~= nil, false
end
function GetInboxInvoiceInfo(i)
  registrar("GetInboxInvoiceInfo", nil, i)
  local c = A.correio[i]
  if not c or not c.fatura then return nil end
  local f = c.fatura
  return f.tipo, f.item, f.jogador, f.lance, f.compra, f.deposito, f.corte, f.atraso, f.hora, f.min, f.qtd, f.comercio
end
function GetInboxItem(i, n)
  registrar("GetInboxItem", nil, i, n)
  local c = A.correio[i]
  if not c or not c.anexo or n ~= 1 then return nil end
  local d = def(c.anexo.itemID)
  return d.nome, c.anexo.itemID, 134400, c.anexo.qtd, d.qual, true
end
function GetInboxItemLink(i, n)
  registrar("GetInboxItemLink", nil, i, n)
  local c = A.correio[i]
  if not c or not c.anexo or n ~= 1 then return nil end
  return link(c.anexo.itemID)
end
function CheckInbox()
  registrar("CheckInbox")
  B.agendar(0.5, function() B.disparar("MAIL_INBOX_UPDATE") end)
end

local function entregarCarta(c)
  table.insert(A.correio, 1, cartaDeInicio(c))
  if c.anexo then A.correio[1].anexo = c.anexo; A.correio[1].itens = 1 end
end

-- ---------------------------------------------------------------------------
-- Acoes (as 8 que exigem clique de hardware de botao PregaoForever*)
-- ---------------------------------------------------------------------------
local function erroLeilao(codigo)
  B.agendar(A.P.t_acao, function()
    B.disparar("AUCTION_HOUSE_SHOW_ERROR", Enum.AuctionHouseError[codigo] or codigo)
  end)
end

local function acao(nome, fn)
  AH(nome, function(...)
    local c = B.clique
    if not (c and c.hw) then
      B.violar("hardware", nome .. " fora de clique de botao PregaoForever*")
      return nil
    end
    c.acoes = c.acoes + 1
    if c.acoes > 1 then
      B.violar("I1", nome .. ": segunda funcao de acao no mesmo clique (id " .. tostring(c.id) .. ")")
      return nil
    end
    if not A.aberto then return nil end
    if A.inj.erro_leilao then
      local cod = A.inj.erro_leilao
      A.inj.erro_leilao = nil
      erroLeilao(cod)
      return nil
    end
    return fn(...)
  end)
end

local function removerDaBolsa(loc, qtd)
  local it = itemDeLoc(loc)
  it.qtd = it.qtd - qtd
  if it.qtd <= 0 then A.bolsas[loc.bagID][loc.slotIndex] = nil end
  B.disparar("BAG_UPDATE", loc.bagID)
  B.disparar("BAG_UPDATE_DELAYED")
end

local function postar(nome, loc, duracao, qtd, preco, lance, confirmado)
  local it = itemDeLoc(loc)
  local sem, nada = umaVez("sem_resposta"), umaVez("retorno_nada")
  if not it or it.qtd < (qtd or 1) then erroLeilao("ItemNotFound") return end
  if not confirmado and umaVez("post_pede_confirmacao") then
    A.postPendente = { loc = loc, duracao = duracao, qtd = qtd, preco = preco, lance = lance }
    B.agendar(A.P.t_acao, function() B.disparar("AUCTION_HOUSE_POST_WARNING") end)
    return true
  end
  if umaVez("post_erro") then
    B.agendar(A.P.t_acao, function() B.disparar("AUCTION_HOUSE_POST_ERROR") end)
    if nada then return end
    return false
  end
  local dep = deposito(it.itemID, duracao, qtd)
  if J.dinheiro < dep then erroLeilao("NotEnoughMoney") return false end
  local multi = umaVez("post_multisell")
  local id = it.itemID
  B.agendar(A.P.t_acao, function()
    if multi then B.disparar("AUCTION_MULTISELL_START", 1) end
    local atual = itemDeLoc(loc)
    if not atual or atual.itemID ~= id or atual.qtd < qtd then return end   -- a bolsa mudou entre a ordem e o servidor
    removerDaBolsa(loc, qtd)
    if dep > 0 then B.mudarDinheiro(-dep) end
    A.proxId = A.proxId + 1
    local p = { id = A.proxId, itemID = id, qtd = qtd, preco = preco, lance = lance, status = 0, duracao = duracao, deposito = dep }
    A.proprios[#A.proprios + 1] = p
    local lista = A.mercado[id]
    if not lista then lista = {}; A.mercado[id] = lista end
    lista[#lista + 1] = { id = p.id, preco = preco, qtd = qtd, donos = 1, proprio = true, lance = lance, nivel = def(id).commodity and 0 or def(id).nivel, sufixo = 0 }
    if not sem then
      B.disparar("AUCTION_HOUSE_AUCTION_CREATED", p.id)
      B.disparar("OWNED_AUCTIONS_UPDATED")
    end
  end)
  if nada then return end
  return false
end

acao("PostCommodity", function(loc, duracao, qtd, preco) return postar("PostCommodity", loc, duracao, qtd, preco, nil, false) end)
acao("PostItem", function(loc, duracao, qtd, lance, compra) return postar("PostItem", loc, duracao, qtd or 1, compra or lance, lance, false) end)
acao("ConfirmPostCommodity", function(loc, duracao, qtd, preco)
  local p = A.postPendente
  A.postPendente = nil
  if not p then return end
  return postar("ConfirmPostCommodity", loc or p.loc, duracao or p.duracao, qtd or p.qtd, preco or p.preco, p.lance, true)
end)
acao("ConfirmPostItem", function(loc, duracao, qtd, lance, compra)
  local p = A.postPendente
  A.postPendente = nil
  if not p then return end
  return postar("ConfirmPostItem", loc or p.loc, duracao or p.duracao, qtd or p.qtd, compra or p.preco, lance or p.lance, true)
end)

local function cotar(id, qtd)
  local rows = rowsDe("c", id)
  local falta, total = qtd, 0
  for _, r in ipairs(rows) do
    if falta <= 0 then break end
    local n = min(falta, r.qtd)
    total = total + n * r.preco
    falta = falta - n
  end
  if falta > 0 then return nil end
  return floor(total / qtd), total
end

acao("StartCommoditiesPurchase", function(id, qtd)
  local sem, indisp = umaVez("sem_resposta"), umaVez("cotacao_indisponivel")
  B.agendar(A.P.t_acao, function()
    if sem then return end
    local un, total = cotar(id, qtd)
    if indisp or not un then B.disparar("COMMODITY_PRICE_UNAVAILABLE") return end
    A.cotacao = { itemID = id, qtd = qtd, total = total, unit = un }
    B.disparar("COMMODITY_PRICE_UPDATED", un, total)
  end)
end)

local function removerDoMercado(id, qtd)
  local falta = qtd
  for _, r in ipairs(rowsDe("c", id)) do
    if falta <= 0 then break end
    local n = min(falta, r.qtd)
    r.qtd = r.qtd - n
    falta = falta - n
  end
  local novos = {}
  for _, r in ipairs(A.mercado[id] or {}) do if r.qtd > 0 then novos[#novos + 1] = r end end
  A.mercado[id] = novos
end

acao("ConfirmCommoditiesPurchase", function(id, qtd)
  local sem, falha = umaVez("sem_resposta"), umaVez("compra_falha")
  local c = A.cotacao
  B.agendar(A.P.t_acao, function()
    if sem then return end
    if falha or not c or c.itemID ~= id or c.qtd ~= qtd or J.dinheiro < c.total then
      B.disparar("COMMODITY_PURCHASE_FAILED")
      return
    end
    A.cotacao = nil
    removerDoMercado(id, qtd)
    B.mudarDinheiro(-c.total)
    entregarCarta({ assunto = "Auction won: " .. def(id).nome, anexo = { itemID = id, qtd = qtd },
      fatura = { tipo = "buyer", item = def(id).nome, jogador = "Vendedor1", lance = c.total, compra = c.total, qtd = qtd, comercio = true } })
    B.disparar("COMMODITY_PURCHASE_SUCCEEDED")
    B.disparar("COMMODITY_PURCHASED", id, qtd)
  end)
end)

acao("PlaceBid", function(auctionID, valor)
  local sem = umaVez("sem_resposta")
  B.agendar(A.P.t_acao, function()
    local achada, idItem
    for id, rows in pairs(A.mercado) do
      for i, r in ipairs(rows) do if r.id == auctionID then achada, idItem = i, id end end
    end
    if not achada then erroLeilao("ItemNotFound") return end
    local r = A.mercado[idItem][achada]
    if valor < r.preco then erroLeilao("BidIncrement") return end
    if J.dinheiro < r.preco then erroLeilao("NotEnoughMoney") return end
    table.remove(A.mercado[idItem], achada)
    B.mudarDinheiro(-r.preco)
    entregarCarta({ assunto = "Auction won: " .. def(idItem).nome, anexo = { itemID = idItem, qtd = r.qtd or 1 },
      fatura = { tipo = "buyer", item = def(idItem).nome, jogador = "Vendedor1", lance = r.preco, compra = r.preco, qtd = r.qtd or 1, comercio = false } })
    if not sem then B.disparar("AUCTION_HOUSE_PURCHASE_COMPLETED", auctionID) end
  end)
end)

acao("CancelAuction", function(auctionID)
  local sem = umaVez("sem_resposta")
  B.agendar(A.P.t_acao, function()
    local pos
    for i, p in ipairs(A.proprios) do if p.id == auctionID then pos = i end end
    if not pos then erroLeilao("ItemNotFound") return end
    local p = table.remove(A.proprios, pos)
    local rows = A.mercado[p.itemID] or {}
    for i, r in ipairs(rows) do if r.id == p.id then table.remove(rows, i) break end end
    entregarCarta({ assunto = "Auction cancelled: " .. def(p.itemID).nome, anexo = { itemID = p.itemID, qtd = p.qtd } })
    if not sem then
      B.disparar("AUCTION_CANCELED", auctionID)
      B.disparar("OWNED_AUCTIONS_UPDATED")
    end
  end)
end)

-- as 8 funcoes de acao, na ordem do contrato (usado pela auto-conferencia)
B.FUNCOES_DE_ACAO = { "PostItem", "PostCommodity", "ConfirmPostItem", "ConfirmPostCommodity", "PlaceBid", "StartCommoditiesPurchase", "ConfirmCommoditiesPurchase", "CancelAuction" }

-- ---------------------------------------------------------------------------
-- Abrir e fechar o leilao
-- ---------------------------------------------------------------------------
function B.abrirLeilao()
  A.aberto = true
  AuctionHouseFrame:Show()
  B.disparar("AUCTION_HOUSE_SHOW")
end
function B.fecharLeilao()
  if not A.aberto then return end
  A.aberto = false
  A.epoca = A.epoca + 1
  A.fila, A.ocupado, A.preso, A.travado, A.descartar = {}, false, false, false, 0
  A.browse, A.busca, A.cotacao, A.postPendente = nil, {}, nil, nil
  AuctionHouseFrame:Hide()
  B.disparar("AUCTION_HOUSE_CLOSED")
end

-- ---------------------------------------------------------------------------
-- Estado inicial do cenario
-- ---------------------------------------------------------------------------
function B.configurar(ini)
  ini = ini or {}
  J.personagem = ini.personagem or "Hexumlite"
  J.reino = ini.reino or "Forever"
  J.faccao = ini.faccao or "Alliance"
  J.dinheiro = ini.dinheiro or 0
  if ini.hora then B.EPOCH = ini.hora end
  if ini.fuso then B.fuso = ini.fuso end
  B.semear(ini.semente or 1)
  for k, v in pairs(ini.parametros or {}) do
    if A.P[k] == nil then error("bancada: parametro desconhecido em inicio.parametros: " .. tostring(k), 0) end
    A.P[k] = v
  end
  for id, d in pairs(ini.itens or {}) do
    A.itens[tonumber(id)] = d
    if d.nao_carregado then A.naoCarregados[tonumber(id)] = true end
  end
  A.bolsas = {}
  for _, b in ipairs(ini.bolsas or {}) do
    A.bolsas[b.bolsa] = A.bolsas[b.bolsa] or {}
    A.bolsas[b.bolsa][b.slot] = { itemID = b.itemID, qtd = b.qtd or 1 }
  end
  A.mercado = {}
  for chave, rows in pairs(ini.mercado or {}) do
    local id = tonumber(chave)
    local lista = {}
    for _, r in ipairs(rows) do
      A.proxId = A.proxId + 1
      local c = B.copiaProfunda(r)
      c.id = c.id or A.proxId
      c.qtd = c.qtd or 1
      c.donos = c.donos or 1
      lista[#lista + 1] = c
    end
    A.mercado[id] = lista
  end
  A.proprios = {}
  for _, p in ipairs(ini.proprios or {}) do
    A.proxId = A.proxId + 1
    local c = B.copiaProfunda(p)
    c.id = c.id or A.proxId
    c.qtd = c.qtd or 1
    A.proprios[#A.proprios + 1] = c
  end
  A.correio = {}
  for _, c in ipairs(ini.correio or {}) do A.correio[#A.correio + 1] = cartaDeInicio(c) end
  if ini.combate then B.combate = true end
end

-- ---------------------------------------------------------------------------
-- Injecoes
-- ---------------------------------------------------------------------------
local INJ = {}
B.INJECOES = INJ

INJ.throttle_travado = function() A.travado = true end
INJ.throttle_livre = function()
  A.travado = false
  if A.preso then
    A.preso = false
    A.ocupado = false
    B.disparar("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
  end
  processar()
end
INJ.mensagem_descartada = function(n) A.descartar = A.descartar + (n or 1) end
for _, nome in ipairs({ "browse_falha", "sem_resposta", "lista_encolhe", "pagina_nao_chega", "busca_outra_chave", "busca_vazia",
  "busca_sem_frente", "item_atualizado", "post_pede_confirmacao", "post_erro", "post_multisell", "retorno_nada",
  "cotacao_indisponivel", "compra_falha" }) do
  INJ[nome] = function(n) A.inj[nome] = (A.inj[nome] or 0) + (n or 1) end
end
INJ.busca_sem_frente = function(n) A.inj.busca_sem_frente = (A.inj.busca_sem_frente or 0) + 1; A.semFrenteN = n or 3 end
INJ.sem_eco = function(n) A.inj.sem_resposta = (A.inj.sem_resposta or 0) + (n or 1) end
INJ.erro_leilao = function(codigo) A.inj.erro_leilao = codigo or "ItemNotFound" end
INJ.deposito_nulo = function() A.depositoNulo = true end
INJ.deposito_normal = function() A.depositoNulo = false end
INJ.combate_on = function()
  if B.combate then return end
  B.combate = true
  B.disparar("PLAYER_REGEN_DISABLED")
end
INJ.combate_off = function()
  if not B.combate then return end
  B.combate = false
  B.disparar("PLAYER_REGEN_ENABLED")
end
INJ.foco_texto = function() B.focoTexto(true) end
INJ.foco_livre = function() B.focoTexto(false) end
INJ.fechar_leilao = function() B.fecharLeilao() end
INJ.dinheiro_muda = function(delta) B.mudarDinheiro(delta or 0) end
INJ.bolsa_trocada = function(bolsa, slot, itemID, qtd)
  A.bolsas[bolsa] = A.bolsas[bolsa] or {}
  A.bolsas[bolsa][slot] = itemID and { itemID = itemID, qtd = qtd or 1 } or nil
  B.disparar("BAG_UPDATE", bolsa)
  B.disparar("BAG_UPDATE_DELAYED")
end
INJ.limpar = function() A.inj = {}; A.descartar = 0 end

function B.injetar(spec)
  local nome, args
  if type(spec) == "table" then nome, args = spec[1], spec else nome, args = spec, { spec } end
  local f = INJ[nome]
  if not f then error("injecao desconhecida: " .. tostring(nome), 0) end
  f(unpack(args, 2))
end

function B.nomesDeInjecao()
  local l = {}
  for k in pairs(INJ) do l[#l + 1] = k end
  table.sort(l)
  return l
end

return B
