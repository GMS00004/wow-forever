local addon, ns = ...

-- Venda: postagem no leilao pelo botao de acao (CONTRATO secoes 6 e 7). Fila de pedidos (/compra post), sugestao
-- automatica para itens vigiados com piso de venda (/compra sell) e UM PostCommodity/PostItem por clique (o Confirm...
-- vem no clique seguinte quando o cliente pede). Regra de preco "igualar": no Forever, leilao postado depois ao mesmo
-- preco vende primeiro; postamos no menor preco atual, sem baixar dele.
-- ns.venda = { fila = { { id, nome, preco, qtd } }, em = { p, loc, fase, t0 } } (sessao; nao vai para SV)

local min = math.min

local PRAZO = 15
local PADRAO_DURACAO = 3

ns.venda = { fila = {}, em = nil, msg = nil }
local W = ns.venda

local function dados() return rawget(_G, "CompraForeverDados") or {} end
local function atualizar() if ns.atualizarPainel then ns.atualizarPainel() end end

local function duracao()
  local d = ns.config().duracao
  if type(d) ~= "number" or d < 1 or d > 3 then return PADRAO_DURACAO end
  return d
end

function ns.vendaOcupada() return W.em ~= nil end

-- Precos e bolsas ---------------------------------------------------------------------------------------

-- menor preco atual visto (cobre): a escada da vigia ou a do scan (as duas ja excluem o proprio dono)
local function menorPreco(id)
  local v = ns.vigia and ns.vigia.escadas and ns.vigia.escadas[id]
  if v and v[1] then return v[1].preco end
  local s = ns.scan and ns.scan.escadas and ns.scan.escadas[id]
  if s and s[1] then return s[1].preco end
  return nil
end

-- pilhas do item nas bolsas 0-4: { { b, s, q } }
local function pilhas(id)
  local out = {}
  for b = 0, 4 do
    for s = 1, (C_Container.GetContainerNumSlots(b) or 0) do
      if C_Container.GetContainerItemID(b, s) == id then
        local info = C_Container.GetContainerItemInfo(b, s)
        out[#out + 1] = { b = b, s = s, q = info and info.stackCount or 1 }
      end
    end
  end
  return out
end

local function total(lista)
  local n = 0
  for _, x in ipairs(lista) do n = n + x.q end
  return n
end

-- true = leilao de item inteiro (PostItem); false = commodity
local function ehInteiro(id, q)
  local A = C_AuctionHouse
  if A and A.GetItemKeyInfo and A.MakeItemKey then
    local info = A.GetItemKeyInfo(A.MakeItemKey(id))
    if type(info) == "table" and type(info.isCommodity) == "boolean" then return not info.isCommodity end
  end
  local it = dados().itens and dados().itens[id]
  if it and (it.pilha or 1) > 1 then return false end
  return q <= 1
end

-- Piso, fila, sugestao --------------------------------------------------------------------------------------

-- piso == nil apaga; so para item ja vigiado
function ns.vendaPiso(id, piso)
  local db = ns.vigiaDB and ns.vigiaDB()
  local it = db and db.itens[id]
  if not it then return false end
  it.venda = piso
  atualizar()
  return true
end

local function naFila(id)
  for _, x in ipairs(W.fila) do
    if x.id == id then return true end
  end
  return false
end

-- preco == nil: auto. Devolve o pedido ou nil e a mensagem de recusa.
function ns.vendaPedir(id, nome, preco, qtd)
  local db = ns.vigiaDB and ns.vigiaDB()
  nome = nome or (db and db.itens[id] and db.itens[id].nome) or ns.vigiaNome(id)
  if preco == nil then
    preco = menorPreco(id)
    if not preco then return nil, "no price seen for " .. nome .. ": Scan or watch it first" end
  end
  local p = { id = id, nome = nome, preco = preco, qtd = qtd }
  W.fila[#W.fila + 1] = p
  atualizar()
  return p
end

function ns.vendaLimpar()
  W.fila = {}
  atualizar()
end

local function sugestoes()
  local out = {}
  local db = ns.vigiaDB and ns.vigiaDB()
  if not db then return out end
  local ids = {}
  for id, it in pairs(db.itens) do
    if it.venda then ids[#ids + 1] = id end
  end
  table.sort(ids)
  for _, id in ipairs(ids) do
    local preco = menorPreco(id)
    local n = total(pilhas(id))
    if n > 0 and preco and preco >= db.itens[id].venda and not naFila(id) then
      out[#out + 1] = { id = id, nome = db.itens[id].nome, preco = preco, qtd = n, auto = true }
    end
  end
  return out
end

-- lista para o painel: pedidos da fila e sugestoes { id, nome, qtd, preco, auto }
function ns.vendaPendentes()
  local out = {}
  for _, x in ipairs(W.fila) do
    out[#out + 1] = { id = x.id, nome = x.nome, preco = x.preco, qtd = x.qtd or total(pilhas(x.id)) }
  end
  for _, x in ipairs(sugestoes()) do out[#out + 1] = x end
  return out
end

local function montar(x, pedido)
  local pl = pilhas(x.id)
  if #pl == 0 then return nil end
  local pilha = pl[1]
  return {
    id = x.id, nome = x.nome, qtd = min(x.qtd or pilha.q, pilha.q), preco = x.preco,
    inteiro = ehInteiro(x.id, pilha.q), bolsa = pilha.b, slot = pilha.s, pedido = pedido,
  }
end

function ns.vendaProxima()
  for _, x in ipairs(W.fila) do
    local p = montar(x, x)
    if p then return p end
  end
  for _, x in ipairs(sugestoes()) do
    local p = montar(x, nil)
    if p then return p end
  end
  return nil
end

-- Postagem --------------------------------------------------------------------------------------------------

local function localizacao(p)
  return ItemLocation:CreateFromBagAndSlot(p.bolsa, p.slot)
end

-- deposito em cobre ou nil (desconhecido)
function ns.vendaDeposito(p)
  local A = C_AuctionHouse
  local d
  if p.inteiro then
    d = A.CalculateItemDeposit and A.CalculateItemDeposit(localizacao(p), duracao(), p.qtd)
  else
    d = A.CalculateCommodityDeposit and A.CalculateCommodityDeposit(p.id, duracao(), p.qtd)
  end
  return type(d) == "number" and d or nil
end

local function armar(em)
  local t0 = GetTime()
  em.t0 = t0
  C_Timer.After(PRAZO, function()
    if W.em == em and em.t0 == t0 and em.fase ~= "confirmar" then
      W.em = nil
      W.msg = "No answer: try again"
      atualizar()
    end
  end)
end

function ns.vendaExecutar(p)
  local A = C_AuctionHouse
  W.msg = nil
  local dep = ns.vendaDeposito(p)
  if dep and GetMoney() < dep then
    W.msg = "Not enough money for deposit"
    atualizar()
    return
  end
  local loc = localizacao(p)
  local antes = C_Container.GetContainerItemInfo(p.bolsa, p.slot)
  local em = { p = p, loc = loc, fase = "postando", pilhaAntes = antes and antes.stackCount or 0 }
  W.em = em
  armar(em)
  if p.inteiro then
    A.PostItem(loc, duracao(), p.qtd, p.preco, p.preco)
  else
    A.PostCommodity(loc, duracao(), p.qtd, p.preco)
  end
end

function ns.vendaConfirmar()
  local em = W.em
  if not em or em.fase ~= "confirmar" then return end
  local p, A = em.p, C_AuctionHouse
  em.fase, em.confirmado = "postando", true
  W.msg = nil
  armar(em)
  if p.inteiro then
    A.ConfirmPostItem(em.loc, duracao(), p.qtd, p.preco, p.preco)
  else
    A.ConfirmPostCommodity(em.loc, duracao(), p.qtd, p.preco)
  end
end

local function concluida()
  local em = W.em
  if not em then return end
  local p, S = em.p, ns.sessao
  W.em = nil
  S.postado[p.id] = (S.postado[p.id] or 0) + p.qtd
  local x = p.pedido
  if x then
    if x.qtd then x.qtd = x.qtd - p.qtd end
    if (x.qtd and x.qtd <= 0) or total(pilhas(p.id)) == 0 then
      for i, y in ipairs(W.fila) do
        if y == x then table.remove(W.fila, i) break end
      end
    end
  end
  atualizar()
end

local function falhou()
  if not W.em then return end
  W.em = nil
  W.msg = "Post failed: try again"
  atualizar()
end

ns.ao("AUCTION_HOUSE_POST_WARNING", function()
  local em = W.em
  if not em or em.fase ~= "postando" or em.confirmado then return end
  em.fase = "confirmar"
  atualizar()
end)

local function criada()
  local em = W.em
  if em and em.fase == "postando" then concluida() end
end

-- OWNED_AUCTIONS_UPDATED tambem dispara por outros motivos (a aba Auctions da Blizzard, por exemplo): so conclui
-- se a pilha postada saiu da bolsa ou encolheu
local function talvezCriada()
  local em = W.em
  if not em or em.fase ~= "postando" then return end
  local p = em.p
  local id = C_Container.GetContainerItemID(p.bolsa, p.slot)
  local info = C_Container.GetContainerItemInfo(p.bolsa, p.slot)
  local agora = (id == p.id and info and info.stackCount) or 0
  if agora < (em.pilhaAntes or 0) then concluida() end
end

ns.ao("AUCTION_HOUSE_AUCTION_CREATED", criada)
ns.ao("OWNED_AUCTIONS_UPDATED", talvezCriada)
ns.ao("AUCTION_HOUSE_POST_ERROR", falhou)
ns.ao("AUCTION_HOUSE_SHOW_ERROR", falhou)
ns.ao("AUCTION_HOUSE_CLOSED", function() W.em = nil end)
