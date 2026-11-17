local addon, ns = ...

-- Compra: acoes de um clique (CONTRATO secao 6). ns.proximaAcao() devolve { texto, executar } (ou so { texto } quando
-- ha algo em andamento, e nil quando nao ha o que fazer). Cada executar() roda dentro do OnClick do botao de acao.
-- Decisoes:
-- * O que o leilao entrega chega pelo correio: ns.estoque passa a somar o comprado que ainda nao apareceu nas bolsas
--   (S.correio), senao o plano refeito compraria tudo de novo. A contagem real das bolsas fica em estoqueBolsa.
-- * Vendedor, craft e venda sao assincronos: estado.pend mede o efeito pela contagem nas bolsas (BAG_UPDATE_DELAYED)
--   e so devolve o botao quando terminar (ou no prazo, ou em UI_ERROR_MESSAGE).
-- * Preco subiu: a escada do item sai de ns.scan ate o proximo scan (o plano refeito nao o usa).

local floor, min, max = math.floor, math.min, math.max

local TOLERANCIA = 1.02

ns.sessao = { comprado = {}, craftado = {}, vendido = {}, lotes = {}, principal = {}, revenda = {}, correio = {} }
local S = ns.sessao
local estado = {}          -- cot, lote, busca, pend, msg, aviso
local aberto = { ah = false, vend = false, prof = false }
local visto = {}           -- id -> contagem nas bolsas na ultima conciliacao do correio

local function dados() return rawget(_G, "CompraForeverDados") or {} end
local function atualizar() if ns.atualizarPainel then ns.atualizarPainel() end end

local estoqueBolsa = ns.estoque
function ns.estoque(id)
  return estoqueBolsa(id) + (S.correio[id] or 0)
end

-- Contexto -------------------------------------------------------------------------------------------

local function ehLW(info)
  return type(info) == "table" and (info.professionName == "Leatherworking" or info.parentProfessionName == "Leatherworking")
end

local function profissaoLW()
  if not aberto.prof then return false end
  local T = C_TradeSkillUI
  if type(T) ~= "table" then return false end
  if T.IsTradeSkillReady and not T.IsTradeSkillReady() then return false end
  if (T.IsTradeSkillLinked and T.IsTradeSkillLinked()) or (T.IsTradeSkillGuild and T.IsTradeSkillGuild())
    or (T.IsNPCCrafting and T.IsNPCCrafting()) then return false end
  return ehLW(T.GetBaseProfessionInfo and T.GetBaseProfessionInfo()) or ehLW(T.GetChildProfessionInfo and T.GetChildProfessionInfo())
end

function ns.contexto()
  return { ah = aberto.ah, vend = aberto.vend, prof = profissaoLW() }
end

function ns.mensagem()
  local a = estado.aviso
  if a and a.scan == ns.scan then return a.texto end
  return estado.msg
end

-- Registro do que foi comprado --------------------------------------------------------------------------

local function consumir(id, qtd, leilao)
  local sc = ns.scan
  local l = sc and sc.escadas and sc.escadas[id]
  if not l then return end
  if leilao then
    for i, d in ipairs(l) do
      if d.leilao == leilao then table.remove(l, i) break end
    end
    return
  end
  local falta, i = qtd, 1
  while falta > 0 and l[i] do
    local d = l[i]
    if d.inteiro then
      i = i + 1
    elseif d.qtd <= falta then
      falta = falta - d.qtd
      table.remove(l, i)
    else
      d.qtd = d.qtd - falta
      falta = 0
    end
  end
end

local function compraFeita(id, qtd, leilao)
  S.comprado[id] = (S.comprado[id] or 0) + qtd
  S.correio[id] = (S.correio[id] or 0) + qtd
  visto[id] = estoqueBolsa(id)
  for _, r in ipairs(ns.plano and ns.plano.revenda or {}) do
    if r.id == id then S.revenda[id] = true end
  end
  consumir(id, qtd, leilao)
  estado.msg = nil
  ns.replanejar()
end

-- o que o correio ja entregou deixa de contar como pendente
local function conciliarCorreio()
  for id, q in pairs(S.correio) do
    local c = estoqueBolsa(id)
    local antes = visto[id] or c
    if c > antes then
      q = max(0, q - (c - antes))
      S.correio[id] = q > 0 and q or nil
    end
    visto[id] = c
  end
end

-- Pendencia medida pelas bolsas ----------------------------------------------------------------------------

local function terminarPend()
  local p = estado.pend
  if not p then return end
  estado.pend = nil
  ns.replanejar()
end

local function progresso()
  local p = estado.pend
  if not p then return end
  local tudo = true
  for _, it in ipairs(p.itens) do
    local d = floor(((estoqueBolsa(it.id) - it.base) * it.sinal) / it.por)
    d = max(0, min(d, it.meta))
    if d > it.creditado then
      it.credito(d - it.creditado)
      it.creditado = d
    end
    if d < it.meta then tudo = false end
  end
  if tudo then terminarPend() end
end

local function iniciarPend(texto, itens, prazo)
  local p = { texto = texto, itens = itens }
  for _, it in ipairs(itens) do
    it.base, it.creditado, it.sinal, it.por = estoqueBolsa(it.id), 0, it.sinal or 1, it.por or 1
  end
  estado.pend = p
  C_Timer.After(prazo, function()
    if estado.pend == p then
      progresso()
      if estado.pend == p then terminarPend() end
      atualizar()
    end
  end)
end

-- Leilao ---------------------------------------------------------------------------------------------

local function textoLote(row)
  local feitos = S.lotes[row.id] or 0
  return "Buy " .. row.nome .. " lot " .. (feitos + 1) .. "/" .. (feitos + #row.lotes)
end

local function buscarItem(row)
  local b = { id = row.id, nome = row.nome }
  estado.busca = b
  estado.msg = nil
  local ordem = Enum and Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0
  C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(row.id), { { sortOrder = ordem, reverseSort = false } }, false)
  C_Timer.After(8, function()
    if estado.busca == b then
      estado.busca = nil
      estado.msg = "No answer: try again"
      atualizar()
    end
  end)
end

local function iniciarCotacao(row)
  local c = { id = row.id, nome = row.nome, qtd = row.qtd, custo = row.custo, fase = "cotando", row = row }
  estado.cot = c
  estado.msg = nil
  C_Timer.After(20, function()
    if estado.cot == c and c.fase ~= "confirmar" then
      estado.cot = nil
      estado.msg = "No answer: try again"
      atualizar()
    end
  end)
  C_AuctionHouse.StartCommoditiesPurchase(row.id, row.qtd)
end

local function confirmar()
  local c = estado.cot
  if not c or c.fase ~= "confirmar" then return end
  c.fase = "comprando"
  estado.msg = nil
  C_AuctionHouse.ConfirmCommoditiesPurchase(c.id, c.qtd)
end

-- buyout exato do leilao (o preco por unidade e arredondado para baixo; lance abaixo do buyout viraria lance, nao compra)
local function buyoutDe(id, leilao)
  local l = ns.scan and ns.scan.escadas and ns.scan.escadas[id]
  for _, d in ipairs(l or {}) do
    if d.leilao == leilao then return d.total end
  end
  return nil
end

local function comprarLote(row, lote)
  local valor = buyoutDe(row.id, lote.leilao)
  if not valor then buscarItem(row) return end   -- sem o buyout exato: busca o item de novo, sem comprar
  local l = { id = row.id, nome = row.nome, leilao = lote.leilao, qtd = lote.qtd }
  estado.lote = l
  estado.msg = nil
  C_Timer.After(15, function()
    if estado.lote == l then
      estado.lote = nil
      estado.msg = "No answer: try again"
      atualizar()
    end
  end)
  C_AuctionHouse.PlaceBid(lote.leilao, valor)
end

local function acaoLeilao()
  local cot = estado.cot
  if cot then
    if cot.fase == "confirmar" then
      return { texto = "Confirm " .. cot.qtd .. " " .. cot.nome .. " (" .. ns.moeda(cot.total) .. ")", executar = confirmar }
    end
    return { texto = (cot.fase == "cotando" and "Quoting " or "Buying ") .. cot.qtd .. " " .. cot.nome }
  end
  if estado.lote then return { texto = "Buying " .. estado.lote.nome } end
  if estado.busca then return { texto = "Searching " .. estado.busca.nome } end
  if ns.scanEstado and ns.scanEstado.ocupado then return { texto = "Scanning..." } end
  for _, row in ipairs(ns.plano and ns.plano.leilao or {}) do
    if row.qtd > 0 then
      local lote = row.inteiro and row.lotes[1]
      if not row.inteiro then
        return { texto = "Buy " .. row.qtd .. " " .. row.nome .. " (" .. ns.moeda(row.custo) .. ")",
                 executar = function() iniciarCotacao(row) end }
      elseif lote and lote.leilao then
        return { texto = textoLote(row) .. " (" .. ns.moeda(lote.preco * lote.qtd) .. ")",
                 executar = function() comprarLote(row, lote) end }
      elseif lote then
        return { texto = "Refresh " .. row.nome, executar = function() buscarItem(row) end }
      end
    end
  end
  local a = estado.aviso
  if a and a.scan == ns.scan then return { texto = a.texto } end
  return nil
end

ns.ao("COMMODITY_PRICE_UPDATED", function(unit, total)
  local c = estado.cot
  if not c or c.fase ~= "cotando" then return end
  if total <= c.custo * TOLERANCIA + 1 then
    c.fase, c.total = "confirmar", total
  else
    C_AuctionHouse.CancelCommoditiesPurchase()
    estado.cot = nil
    local sc = ns.scan
    if sc and sc.escadas then sc.escadas[c.id] = nil end
    estado.aviso = { texto = "Price rose: Scan again", scan = sc }
    ns.replanejar()
  end
  atualizar()
end)

ns.ao("COMMODITY_PRICE_UNAVAILABLE", function()
  if not estado.cot then return end
  estado.cot = nil
  estado.msg = "Quote unavailable: try again"
  atualizar()
end)

ns.ao("COMMODITY_PURCHASE_SUCCEEDED", function()
  local c = estado.cot
  if not c or c.fase ~= "comprando" then return end
  estado.cot = nil
  compraFeita(c.id, c.qtd, nil)
end)

ns.ao("COMMODITY_PURCHASE_FAILED", function()
  if not estado.cot then return end
  estado.cot = nil
  estado.msg = "Purchase failed: try again"
  atualizar()
end)

ns.ao("AUCTION_HOUSE_PURCHASE_COMPLETED", function(leilao)
  local l = estado.lote
  if not l or l.leilao ~= leilao then return end
  estado.lote = nil
  S.lotes[l.id] = (S.lotes[l.id] or 0) + 1
  compraFeita(l.id, l.qtd, l.leilao)
end)

ns.ao("AUCTION_HOUSE_SHOW_ERROR", function(codigo)
  local l = estado.lote
  if estado.cot then
    estado.cot = nil
  elseif l then
    estado.lote = nil
    local E = Enum and Enum.AuctionHouseError
    if E and codigo == E.ItemNotFound then   -- o lote saiu do ar: nao tenta de novo
      consumir(l.id, l.qtd, l.leilao)
      estado.msg = "Lot gone: next"
      ns.replanejar()
      return
    end
  elseif not estado.busca then
    return
  end
  estado.busca = nil
  estado.msg = "Auction error: try again"
  atualizar()
end)

-- busca so do item (plano de full scan nao tem auctionID): troca a escada dele em ns.scan
ns.ao("ITEM_SEARCH_RESULTS_UPDATED", function(chave)
  local b = estado.busca
  if not b or type(chave) ~= "table" or chave.itemID ~= b.id then return end
  estado.busca = nil
  local A, sc, escada = C_AuctionHouse, ns.scan, {}
  for i = 1, A.GetNumItemSearchResults(chave) do
    local r = A.GetItemSearchResultInfo(chave, i)
    local q = r and r.quantity or 0
    if r and not r.containsOwnerItem and (r.buyoutAmount or 0) > 0 and q > 0 then
      escada[#escada + 1] = { preco = floor(r.buyoutAmount / q), qtd = q, leilao = r.auctionID, inteiro = true, total = r.buyoutAmount }
    end
  end
  table.sort(escada, function(x, y)
    if x.preco ~= y.preco then return x.preco < y.preco end
    return (x.leilao or 0) < (y.leilao or 0)
  end)
  if sc and sc.escadas then sc.escadas[b.id] = escada end
  ns.replanejar()
end)

-- Vendedor -------------------------------------------------------------------------------------------

local function indiceVendedor(id)
  for i = 1, (GetMerchantNumItems() or 0) do
    if GetMerchantItemID(i) == id then return i end
  end
  return nil
end

local function comprarVendedor()
  local itens, chamadas = {}, {}
  for _, r in ipairs(ns.plano and ns.plano.vendedor or {}) do
    local i = indiceVendedor(r.id)
    if i and r.qtd > 0 then
      local id = r.id
      itens[#itens + 1] = { id = id, meta = r.qtd, credito = function(d) S.comprado[id] = (S.comprado[id] or 0) + d end }
      local resta = r.qtd
      local pilha = max(1, GetMerchantItemMaxStack(i) or 1)
      while resta > 0 do
        local n = min(resta, pilha)
        chamadas[#chamadas + 1] = { i, n }
        resta = resta - n
      end
    end
  end
  if #chamadas == 0 then return end
  estado.msg = nil
  iniciarPend("Buying at vendor...", itens, 3 + #chamadas)
  for _, c in ipairs(chamadas) do BuyMerchantItem(c[1], c[2]) end
end

-- produtos do plano que as bolsas 0-4 tem, limitados ao craftado nesta sessao (ou ao revendido comprado)
local function aVender()
  local d = dados()
  local perm = {}
  for magia in pairs(S.principal) do
    local r = d.receitas and d.receitas[magia]
    if r then perm[r.produto] = (perm[r.produto] or 0) + (S.craftado[magia] or 0) * (r.qtd or 1) end
  end
  for id in pairs(S.revenda) do perm[id] = (perm[id] or 0) + (S.comprado[id] or 0) end
  for id, v in pairs(S.vendido) do
    if perm[id] then perm[id] = perm[id] - v end
  end
  local lista, n, valor = {}, 0, 0
  for b = 0, 4 do
    for s = 1, (C_Container.GetContainerNumSlots(b) or 0) do
      local id = C_Container.GetContainerItemID(b, s)
      local vende = id and d.itens and d.itens[id] and d.itens[id].vende or 0
      if id and vende > 0 and (perm[id] or 0) > 0 then
        local info = C_Container.GetContainerItemInfo(b, s)
        local q = info and info.stackCount or 1
        if q <= perm[id] then   -- UseContainerItem vende a pilha inteira: pilha maior que o permitido fica
          lista[#lista + 1] = { b = b, s = s, id = id, n = q }
          perm[id] = perm[id] - q
          n = n + q
          valor = valor + q * vende
        end
      end
    end
  end
  return lista, n, valor
end

local function vender()
  -- sem o vendedor aberto, UseContainerItem equiparia ou usaria o item: so vende com a janela dele na tela
  if not (aberto.vend and MerchantFrame and MerchantFrame:IsShown()) then return end
  local lista = aVender()
  if #lista == 0 then return end
  local por = {}
  for _, x in ipairs(lista) do por[x.id] = (por[x.id] or 0) + x.n end
  local itens = {}
  for id, n in pairs(por) do
    itens[#itens + 1] = { id = id, meta = n, sinal = -1, credito = function(d) S.vendido[id] = (S.vendido[id] or 0) + d end }
  end
  estado.msg = nil
  iniciarPend("Selling...", itens, 3 + #lista)
  for _, x in ipairs(lista) do C_Container.UseContainerItem(x.b, x.s) end
end

local function acaoVendedor()
  local custo, n = 0, 0
  for _, r in ipairs(ns.plano and ns.plano.vendedor or {}) do
    if r.qtd > 0 and indiceVendedor(r.id) then
      custo = custo + r.custo
      n = n + 1
    end
  end
  if n > 0 then
    return { texto = "Buy thread/dye at vendor (" .. ns.moeda(custo) .. ")", executar = comprarVendedor }
  end
  local _, itens, valor = aVender()
  if itens > 0 then
    return { texto = "Sell " .. itens .. " items (+" .. ns.moeda(valor) .. ")", executar = vender }
  end
  return nil
end

-- Craftar ----------------------------------------------------------------------------------------------

local function vezes(r)
  local m
  for _, rg in ipairs(r.reagentes) do
    local k = floor(estoqueBolsa(rg[1]) / rg[2])
    if not m or k < m then m = k end
  end
  return m or 0
end

local function craftar(c, r, n, principal)
  local magia = c.magia
  estado.msg = nil
  iniciarPend("Crafting...", { { id = r.produto, meta = n, por = r.qtd or 1, credito = function(d)
    S.craftado[magia] = (S.craftado[magia] or 0) + d
    if principal then S.principal[magia] = true end
  end } }, 10 + 4 * n)
  C_TradeSkillUI.CraftRecipe(magia, n)
end

local function acaoCraft()
  local plano, d = ns.plano, dados()
  if not plano or not d.receitas then return nil end
  for pass = 1, 2 do
    local lista = pass == 1 and plano.fabricar or plano.crafts
    for _, c in ipairs(lista) do
      local r = d.receitas[c.magia]
      if r then
        local n = min(c.n, vezes(r))
        if n > 0 then
          return { texto = "Craft " .. n .. " " .. c.nome, executar = function() craftar(c, r, n, pass == 2) end }
        end
      end
    end
  end
  return nil
end

-- Proxima acao -------------------------------------------------------------------------------------------

function ns.proximaAcao()
  if estado.pend then return { texto = estado.pend.texto } end
  local c = ns.contexto()
  local a
  if c.ah then a = acaoLeilao() end
  if not a and c.vend then a = acaoVendedor() end
  if not a and c.prof then a = acaoCraft() end
  return a
end

-- Eventos --------------------------------------------------------------------------------------------------

ns.ao("AUCTION_HOUSE_SHOW", function() aberto.ah = true end)
ns.ao("AUCTION_HOUSE_CLOSED", function()
  aberto.ah = false
  estado.cot, estado.lote, estado.busca = nil, nil, nil
end)
ns.ao("MERCHANT_SHOW", function() aberto.vend = true end)
ns.ao("MERCHANT_CLOSED", function() aberto.vend = false end)
ns.ao("TRADE_SKILL_SHOW", function() aberto.prof = true end)
ns.ao("TRADE_SKILL_CLOSE", function() aberto.prof = false end)

ns.ao("BAG_UPDATE_DELAYED", function()
  conciliarCorreio()
  progresso()
end)

ns.ao("UI_ERROR_MESSAGE", function(_, texto)
  if not estado.pend then return end
  progresso()
  estado.msg = type(texto) == "string" and texto or "Action failed"
  terminarPend()
  atualizar()
end)
