-- Falsos de compra para a bancada: profissao (C_TradeSkillUI), vendedor (MerchantFrame, compra e venda), full scan
-- (ReplicateItems) e GetCoinTextureString. Coerentes com o estado de leilao.lua: dinheiro (B.J), bolsas (B.A.bolsas), itens.
-- Fengari (Lua 5.3). So ASCII. Carregado depois de leilao.lua e antes de executor.lua.
--
-- Passos de cenario que este arquivo registra (via B.PASSOS_EXTRA):
--   { abrir_vendedor = true | { { itemID = 2321, preco = 25 }, ... } }   MERCHANT_SHOW (true usa inicio.vendedor)
--   { fechar_vendedor = true }                                           MERCHANT_CLOSED
--   { abrir_profissao = true | { nome = "Leatherworking", nivel = 150, linked = false, guild = false, npc = false } }
--   { fechar_profissao = true }                                          TRADE_SKILL_CLOSE
--   { definir_receitas = { [magia] = { nome, produto, qtd, reagentes = { { itemID, qtd }, ... }, aprendida = true } } }
-- Tambem aceitos em `inicio`: receitas, vendedor, profissao. Parametros novos em inicio.parametros: t_vendedor, t_craft,
-- replicate_dura, replicate_passo.

local B = __bancada
local A, J = B.A, B.J
local def = B.itemDef
local floor, ceil, max = math.floor, math.ceil, math.max

A.P.t_vendedor = 0.2        -- latencia de uma compra ou venda no vendedor (s)
A.P.t_craft = 1.0           -- tempo de cada unidade craftada (s)
A.P.replicate_dura = 6      -- tempo ate a lista do full scan chegar inteira (s)
A.P.replicate_passo = 0.5   -- a lista cresce a cada passo (s)

local NBOLSAS = 5
local C = {
  vendedor = { aberto = false, lista = {} },
  prof = { aberta = false, nome = "Leatherworking", nivel = 150, linked = false, guild = false, npc = false },
  receitas = {},
  craftEpoca = 0,
}
B.C = C

-- ---------------------------------------------------------------------------
-- Bolsas (sem passar pelo registro de chamadas: e o servidor mexendo)
-- ---------------------------------------------------------------------------
local function itemEm(bag, slot)
  local b = A.bolsas[bag]
  return b and b[slot] or nil
end

local function contar(id)
  local n = 0
  for bag = 0, NBOLSAS - 1 do
    for s = 1, A.P.tamanho_bolsa do
      local it = itemEm(bag, s)
      if it and it.itemID == id then n = n + it.qtd end
    end
  end
  return n
end

-- quantas unidades de id ainda cabem nas bolsas
local function capacidade(id)
  local pilha = def(id).pilha
  local cap = 0
  for bag = 0, NBOLSAS - 1 do
    for s = 1, A.P.tamanho_bolsa do
      local it = itemEm(bag, s)
      if not it then cap = cap + pilha
      elseif it.itemID == id then cap = cap + max(0, pilha - it.qtd) end
    end
  end
  return cap
end

local function colocar(id, qtd, tocadas)
  local pilha = def(id).pilha
  local falta = qtd
  for bag = 0, NBOLSAS - 1 do
    for s = 1, A.P.tamanho_bolsa do
      if falta <= 0 then return end
      local it = itemEm(bag, s)
      if it and it.itemID == id and it.qtd < pilha then
        local n = math.min(falta, pilha - it.qtd)
        it.qtd = it.qtd + n
        falta = falta - n
        tocadas[bag] = true
      end
    end
  end
  for bag = 0, NBOLSAS - 1 do
    for s = 1, A.P.tamanho_bolsa do
      if falta <= 0 then return end
      if not itemEm(bag, s) then
        local n = math.min(falta, pilha)
        A.bolsas[bag] = A.bolsas[bag] or {}
        A.bolsas[bag][s] = { itemID = id, qtd = n }
        falta = falta - n
        tocadas[bag] = true
      end
    end
  end
end

local function tirar(id, qtd, tocadas)
  local falta = qtd
  for bag = 0, NBOLSAS - 1 do
    for s = 1, A.P.tamanho_bolsa do
      local it = itemEm(bag, s)
      if falta > 0 and it and it.itemID == id then
        local n = math.min(falta, it.qtd)
        it.qtd = it.qtd - n
        falta = falta - n
        if it.qtd <= 0 then A.bolsas[bag][s] = nil end
        tocadas[bag] = true
      end
    end
  end
end

local function avisar(tocadas)
  local algum = false
  for bag = 0, NBOLSAS - 1 do
    if tocadas[bag] then algum = true; B.disparar("BAG_UPDATE", bag) end
  end
  if algum then B.disparar("BAG_UPDATE_DELAYED") end
end

-- ---------------------------------------------------------------------------
-- Moeda
-- ---------------------------------------------------------------------------
function GetCoinTextureString(cobre, altura)
  B.registrar("GetCoinTextureString", nil, cobre, altura)
  local c = floor(math.abs(tonumber(cobre) or 0))
  local h = altura or 14
  local g, s, cu = floor(c / 10000), floor((c % 10000) / 100), c % 100
  local partes = {}
  if g > 0 then partes[#partes + 1] = string.format("%d|TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:2:0|t", g, h, h) end
  if s > 0 then partes[#partes + 1] = string.format("%d|TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:2:0|t", s, h, h) end
  if cu > 0 or c == 0 then partes[#partes + 1] = string.format("%d|TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:2:0|t", cu, h, h) end
  return table.concat(partes, " ")
end

-- ---------------------------------------------------------------------------
-- Profissao
-- ---------------------------------------------------------------------------
local function normalizarReceita(magia, spec)
  if type(magia) ~= "number" or type(spec) ~= "table" then error("receita invalida: " .. tostring(magia), 0) end
  if type(spec.produto) ~= "number" then error("receita " .. magia .. " sem produto", 0) end
  local r = { magia = magia, nome = spec.nome or ("Recipe " .. magia), produto = spec.produto, qtd = spec.qtd or 1,
    aprendida = spec.aprendida ~= false, reagentes = {} }
  for i, rg in ipairs(spec.reagentes or {}) do
    local id, n = rg[1] or rg.itemID, rg[2] or rg.qtd
    if type(id) ~= "number" or type(n) ~= "number" then error("receita " .. magia .. ": reagente " .. i .. " invalido", 0) end
    r.reagentes[#r.reagentes + 1] = { id, n }
  end
  return r
end

local function definirReceitas(tab)
  for magia, spec in pairs(tab or {}) do C.receitas[tonumber(magia)] = normalizarReceita(tonumber(magia), spec) end
end

C_TradeSkillUI = {}
local function TS(nome, fn) B.def(C_TradeSkillUI, "C_TradeSkillUI", nome, fn) end

TS("IsTradeSkillReady", function() return C.prof.aberta end)
TS("IsTradeSkillLinked", function() return C.prof.linked end)
TS("IsTradeSkillGuild", function() return C.prof.guild end)
TS("IsNPCCrafting", function() return C.prof.npc end)
TS("GetAllRecipeIDs", function()
  local ids = {}
  if not C.prof.aberta then return ids end
  for magia in pairs(C.receitas) do ids[#ids + 1] = magia end
  table.sort(ids)
  return ids
end)
TS("GetRecipeInfo", function(id)
  local r = C.receitas[id]
  if not r or not C.prof.aberta then return nil end
  return { recipeID = id, name = r.nome, learned = r.aprendida }
end)
local function infoProf()
  if not C.prof.aberta then return { professionID = 0, skillLevel = 0, maxSkillLevel = 0, skillModifier = 0 } end
  return { professionID = 165, professionName = C.prof.nome, skillLevel = C.prof.nivel, maxSkillLevel = 300, skillModifier = 0 }
end
TS("GetBaseProfessionInfo", infoProf)
TS("GetChildProfessionInfo", infoProf)

-- uma unidade: confere reagentes e espaco, consome e entrega o produto
local function umCraft(r)
  for _, rg in ipairs(r.reagentes) do
    if contar(rg[1]) < rg[2] then return false, "Missing reagents" end
  end
  local tocadas = {}
  for _, rg in ipairs(r.reagentes) do tirar(rg[1], rg[2], tocadas) end
  if capacidade(r.produto) < r.qtd then
    for _, rg in ipairs(r.reagentes) do colocar(rg[1], rg[2], tocadas) end
    avisar(tocadas)
    return false, "Inventory is full"
  end
  colocar(r.produto, r.qtd, tocadas)
  avisar(tocadas)
  return true
end

TS("CraftRecipe", function(magia, n)
  if not C.prof.aberta then
    B.violar("profissao", "CraftRecipe com a janela de profissao fechada")
    return
  end
  local r = C.receitas[magia]
  if not r or not r.aprendida then
    B.violar("profissao", "CraftRecipe de receita desconhecida ou nao aprendida: " .. tostring(magia))
    return
  end
  if type(n) ~= "number" or n < 1 then n = 1 end
  C.craftEpoca = C.craftEpoca + 1   -- um pedido novo substitui o que sobrava do anterior
  local ep = C.craftEpoca
  for k = 1, floor(n) do
    B.agendar(A.P.t_craft * k, function()
      if ep ~= C.craftEpoca then return end
      local ok, motivo = umCraft(r)
      if not ok then
        C.craftEpoca = C.craftEpoca + 1
        B.disparar("UI_ERROR_MESSAGE", 0, motivo)
      end
    end)
  end
end)

local function abrirProfissao(spec)
  if type(spec) == "table" then
    for _, k in ipairs({ "nome", "nivel", "linked", "guild", "npc" }) do
      if spec[k] ~= nil then C.prof[k] = spec[k] end
    end
  end
  if C.prof.aberta then return end
  C.prof.aberta = true
  B.disparar("TRADE_SKILL_SHOW")
end
local function fecharProfissao()
  if not C.prof.aberta then return end
  C.prof.aberta = false
  C.craftEpoca = C.craftEpoca + 1
  B.disparar("TRADE_SKILL_CLOSE")
end

-- ---------------------------------------------------------------------------
-- Vendedor
-- ---------------------------------------------------------------------------
MerchantFrame = CreateFrame("Frame", "MerchantFrame", UIParent)
MerchantFrame:SetSize(336, 447)
MerchantFrame:Hide()

local function normalizarLista(lista)
  local out = {}
  for i, m in ipairs(lista or {}) do
    local id, preco = m.itemID or m[1], m.preco or m[2]
    if type(id) ~= "number" or type(preco) ~= "number" then error("vendedor: linha " .. i .. " invalida (precisa de itemID e preco)", 0) end
    out[#out + 1] = { itemID = id, preco = preco }
  end
  return out
end

B.def(_G, nil, "GetMerchantNumItems", function()
  return C.vendedor.aberto and #C.vendedor.lista or 0
end)
B.def(_G, nil, "GetMerchantItemID", function(i)
  local m = C.vendedor.aberto and C.vendedor.lista[i] or nil
  return m and m.itemID or nil
end)
B.def(_G, nil, "GetMerchantItemMaxStack", function(i)
  local m = C.vendedor.aberto and C.vendedor.lista[i] or nil
  return m and def(m.itemID).pilha or 0
end)

B.def(_G, nil, "BuyMerchantItem", function(i, qtd)
  local V = C.vendedor
  if not V.aberto then B.violar("vendedor", "BuyMerchantItem com o vendedor fechado") return end
  local m = V.lista[i]
  if not m then B.violar("vendedor", "BuyMerchantItem com indice inexistente: " .. tostring(i)) return end
  if qtd == nil then qtd = 1 end
  if type(qtd) ~= "number" or qtd < 1 or qtd ~= floor(qtd) then
    B.violar("vendedor", "BuyMerchantItem com quantidade invalida: " .. tostring(qtd))
    return
  end
  if qtd > def(m.itemID).pilha then
    B.violar("vendedor", "BuyMerchantItem acima do GetMerchantItemMaxStack: " .. qtd .. " > " .. def(m.itemID).pilha)
    return
  end
  B.agendar(A.P.t_vendedor, function()
    if not V.aberto then return end
    local custo = m.preco * qtd
    if J.dinheiro < custo then B.disparar("UI_ERROR_MESSAGE", 0, "Not enough money") return end
    if capacidade(m.itemID) < qtd then B.disparar("UI_ERROR_MESSAGE", 0, "Inventory is full") return end
    local tocadas = {}
    colocar(m.itemID, qtd, tocadas)
    B.mudarDinheiro(-custo)
    avisar(tocadas)
  end)
end)

-- com o vendedor aberto, usar um item da bolsa vende a pilha inteira
B.def(C_Container, "C_Container", "UseContainerItem", function(bag, slot)
  if not C.vendedor.aberto then return end   -- sem vendedor o item seria usado; o falso nao simula uso
  local it = itemEm(bag, slot)
  if not it then return end
  local id = it.itemID
  B.agendar(A.P.t_vendedor, function()
    local atual = itemEm(bag, slot)
    if not C.vendedor.aberto or not atual or atual.itemID ~= id then return end
    local vend = def(id).vend
    if vend <= 0 then B.disparar("UI_ERROR_MESSAGE", 0, "Item cannot be sold") return end
    local qtd = atual.qtd
    A.bolsas[bag][slot] = nil
    B.mudarDinheiro(vend * qtd)
    avisar({ [bag] = true })
  end)
end)

local function abrirVendedor(spec)
  if type(spec) == "table" then C.vendedor.lista = normalizarLista(spec) end
  if C.vendedor.aberto then return end
  C.vendedor.aberto = true
  MerchantFrame:Show()
  B.disparar("MERCHANT_SHOW")
end
local function fecharVendedor()
  if not C.vendedor.aberto then return end
  C.vendedor.aberto = false
  MerchantFrame:Hide()
  B.disparar("MERCHANT_CLOSED")
end

-- ---------------------------------------------------------------------------
-- Full scan
-- ---------------------------------------------------------------------------
local R = { lista = {}, visivel = 0, epoca = 0 }

local function fotoDoMercado()
  local ids = {}
  for id in pairs(A.mercado) do ids[#ids + 1] = id end
  table.sort(ids)
  local out = {}
  for _, id in ipairs(ids) do
    local d = def(id)
    local rows = {}
    for _, r in ipairs(A.mercado[id]) do rows[#rows + 1] = r end
    table.sort(rows, function(a, c)
      if a.preco ~= c.preco then return a.preco < c.preco end
      return a.id < c.id
    end)
    for _, r in ipairs(rows) do
      local qtd = r.qtd or 1
      local buyout = d.commodity and (r.preco * qtd) or r.preco
      out[#out + 1] = { itemID = id, nome = d.nome, qtd = qtd, qual = d.qual, nivel = r.nivel or d.nivel,
        minBid = r.lance or buyout, buyout = buyout, dono = r.proprio and J.personagem or "Vendedor1" }
    end
  end
  return out
end

B.def(C_AuctionHouse, "C_AuctionHouse", "ReplicateItems", function()
  if not A.aberto then B.violar("fechado", "ReplicateItems com o leilao fechado") return end
  local semEvento = false
  if (A.inj.replicate_sem_evento or 0) > 0 then
    A.inj.replicate_sem_evento = A.inj.replicate_sem_evento - 1
    semEvento = true
  end
  R.epoca = R.epoca + 1
  local ep = R.epoca
  R.lista, R.visivel = fotoDoMercado(), 0
  local total = #R.lista
  local dura, passo = A.P.replicate_dura, A.P.replicate_passo
  local passos = max(1, ceil(dura / passo))
  for k = 1, passos do
    B.agendar(dura * k / passos, function()
      if ep ~= R.epoca then return end
      R.visivel = (k == passos) and total or floor(total * k / passos)
      if k == passos and not semEvento then B.disparar("REPLICATE_ITEM_LIST_UPDATE") end
    end)
  end
end)
B.def(C_AuctionHouse, "C_AuctionHouse", "GetNumReplicateItems", function()
  if not A.aberto then return 0 end
  return R.visivel
end)
-- indice a partir de 0; 18 retornos (3 = quantidade, 10 = buyout total, 17 = itemID)
B.def(C_AuctionHouse, "C_AuctionHouse", "GetReplicateItemInfo", function(i)
  if not A.aberto or type(i) ~= "number" or i < 0 or i + 1 > R.visivel then return nil end
  local e = R.lista[i + 1]
  return e.nome, 134400, e.qtd, e.qual, true, e.nivel, 0, e.minBid, 0, e.buyout, 0, nil, nil, e.dono, nil, 0, e.itemID, true
end)

local fecharLeilaoOrig = B.fecharLeilao
function B.fecharLeilao()
  fecharLeilaoOrig()
  R.epoca = R.epoca + 1
  R.lista, R.visivel = {}, 0
end

B.INJECOES.replicate_sem_evento = function(n) A.inj.replicate_sem_evento = (A.inj.replicate_sem_evento or 0) + (n or 1) end

-- ---------------------------------------------------------------------------
-- Estado inicial e passos
-- ---------------------------------------------------------------------------
local configurarOrig = B.configurar
function B.configurar(ini)
  configurarOrig(ini)
  ini = ini or {}
  C.craftEpoca = C.craftEpoca + 1
  C.receitas = {}
  definirReceitas(ini.receitas)
  C.vendedor = { aberto = false, lista = normalizarLista(ini.vendedor) }
  C.prof = { aberta = false, nome = "Leatherworking", nivel = 150, linked = false, guild = false, npc = false }
  for k, v in pairs(ini.profissao or {}) do C.prof[k] = v end
  R.epoca = R.epoca + 1
  R.lista, R.visivel = {}, 0
end

B.PASSOS_EXTRA = {
  abrir_vendedor = function(spec) abrirVendedor(spec) end,
  fechar_vendedor = function() fecharVendedor() end,
  abrir_profissao = function(spec) abrirProfissao(spec) end,
  fechar_profissao = function() fecharProfissao() end,
  definir_receitas = function(tab)
    if type(tab) ~= "table" then error("definir_receitas: precisa de uma tabela magia -> receita", 0) end
    definirReceitas(tab)
  end,
}

return B
