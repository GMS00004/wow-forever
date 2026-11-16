-- Itens.lua (PregaoForever): chave de item em texto; leitura de item por ItemLocation da bolsa; preco de vendedor ao vivo pelo link (regra 17); carga assincrona por ITEM_DATA_LOAD_RESULT; bolsas com reservas. Publica ns.itens. Onda 2.
-- Contrato: ARQUITETURA.md, secoes 3.4 e 4. Pede dados de item ao cliente (C_Item.RequestLoadItemDataByID), que nao contam no folego (regra 9); nenhuma consulta ao leilao aqui.
local _, ns = ...
ns.itens = ns.itens or {}
local I = ns.itens

local pendentes = {}   -- itemID -> { chave = true }: chaves esperando a carga do cliente
local links = {}       -- chave -> link visto na bolsa; o GetItemInfo ao vivo usa o link (regra 17)

-- ---------- chave (secao 4) ----------
-- Commodity: so o itemID. Item: itemID:itemLevel:itemSuffix.
-- ehCom diz qual dos dois. Sem ele, vale nivel e sufixo zero como commodity (so para quem nao tem o dado).
function I.chave(itemKey, ehCom)
  local id = itemKey.itemID
  local nivel = itemKey.itemLevel or 0
  local suf = itemKey.itemSuffix or 0
  if ehCom == nil then ehCom = (nivel == 0 and suf == 0) end
  if ehCom then return ns.txt(id) end
  return ns.txt(id) .. ':' .. ns.txt(nivel) .. ':' .. ns.txt(suf)
end

-- separa o texto da chave: itemID e, se for item, nivel e sufixo (nil se o texto nao for chave)
local function partes(chave)
  local a = string.match(chave, '^(%d+)$')
  if a then return tonumber(a), nil, nil end
  local i, l, s = string.match(chave, '^(%d+):(%d+):(%d+)$')
  if i then return tonumber(i), tonumber(l), tonumber(s) end
  return nil, nil, nil
end

function I.itemKey(chave)
  local id, nivel, suf = partes(tostring(chave))
  if not id then return nil end
  return { itemID = id, itemLevel = nivel or 0, itemSuffix = suf or 0, battlePetSpeciesID = 0 }
end

-- ---------- memoria do banco (itens) ----------
local function memoriaItens()
  local b = ns.banco
  if not b or not b.memoria then return nil end
  local m = b.memoria()
  return m and m.itens or nil
end

-- ---------- bolsa: chave, quantidade e tipo de um ItemLocation ----------
-- Status desconhecido (o cliente ainda nao carregou o item) pede a carga e devolve nil.
function I.deLocal(loc)
  if not C_Item.DoesItemExist(loc) then return nil end
  local key = C_AuctionHouse.GetItemKeyFromItem(loc)
  if not key then return nil end
  local status = C_AuctionHouse.GetItemCommodityStatus(loc)
  local ehCom
  if status == Enum.ItemCommodityStatus.Commodity then
    ehCom = true
  elseif status == Enum.ItemCommodityStatus.Item then
    ehCom = false
  else
    C_Item.RequestLoadItemDataByID(key.itemID)
    return nil
  end
  local chave = I.chave(key, ehCom)
  local link = C_Item.GetItemLink(loc)
  if link then links[chave] = link end
  return chave, C_Item.GetStackCount(loc), ehCom and 'c' or 'i'
end

-- ---------- preco de vendedor ao vivo (regra 17) ----------
-- Le C_Item.GetItemInfo pelo link (ou pelo itemID, sem link visto). Sem o item no cache, devolve nil
-- e, se pedir, pede a carga; a resposta chega em ITEM_DATA_LOAD_RESULT.
local function lerInfo(chave, pedir)
  local id, nivel = partes(chave)
  if not id then return nil end
  local ehCom = (nivel == nil)
  local nome, _, _, _, _, _, _, pilha, _, _, vend = C_Item.GetItemInfo(links[chave] or id)
  if nome == nil or vend == nil then
    if pedir then
      local lista = pendentes[id]
      if not lista then
        lista = {}
        pendentes[id] = lista
      end
      lista[chave] = true
      C_Item.RequestLoadItemDataByID(id)
    end
    return nil
  end
  local tipo = ehCom and 'c' or 'i'
  local pil = pilha or 1
  local m = memoriaItens()
  local conf = 0
  local antes = m and m[chave]
  if antes and antes.vend == vend and antes.conf then conf = antes.conf end
  if m then m[chave] = { vend = vend, tipo = tipo, pilha = pil, conf = conf } end
  return { vend = vend, tipo = tipo, pilha = pil, conf = conf, nome = nome }
end

-- info(chave): { vend, tipo, pilha, conf, nome } ou nil (item fora do cache; a carga foi pedida)
function I.info(chave)
  return lerInfo(tostring(chave), true)
end

-- ---------- carga assincrona (ITEM_DATA_LOAD_RESULT) ----------
ns.ao('ITEM_DATA_LOAD_RESULT', function(_, itemID, sucesso)
  local lista = pendentes[itemID]
  if not lista then return end
  pendentes[itemID] = nil
  if not sucesso then return end
  local chaves = {}
  for c in pairs(lista) do chaves[#chaves + 1] = c end
  table.sort(chaves)
  for i = 1, #chaves do lerInfo(chaves[i], false) end
end)

-- ---------- bolsas ----------
-- Reservas do personagem (cfg.reservas[nome]): lista de itemID ou chave, em texto.
local function reservadosDoPersonagem()
  local set = {}
  local cfg = ns.cfg
  local lista = (cfg and cfg.reservas and cfg.reservas[ns.pers()]) or {}
  for i = 1, #lista do set[tostring(lista[i])] = true end
  return set
end

-- bolsas 0 a 4: { bolsa, slot, chave, qtd, tipo, reservado }; item reservado volta com reservado = true
function I.bolsas()
  local reservados = reservadosDoPersonagem()
  local saida = {}
  for bolsa = 0, 4 do
    local slots = C_Container.GetContainerNumSlots(bolsa) or 0
    for slot = 1, slots do
      local loc = ItemLocation:CreateFromBagAndSlot(bolsa, slot)
      local chave, qtd, tipo = I.deLocal(loc)
      if chave then
        local id = partes(chave)
        local reservado = (reservados[chave] or reservados[tostring(id)]) and true or false
        saida[#saida + 1] = { bolsa = bolsa, slot = slot, chave = chave, qtd = qtd, tipo = tipo, reservado = reservado }
      end
    end
  end
  return saida
end
