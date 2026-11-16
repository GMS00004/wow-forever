-- ItemLocation, C_Container e C_Item: item na bolsa, preco de vendedor no 11o retorno, item ainda nao carregado, depositos.
return {
  id = "auto-18", grupo = "autoteste",
  descricao = "ItemLocation:CreateFromBagAndSlot, C_Item, GetItemInfo(11), RequestLoadItemDataByID, depositos",
  inicio = {
    bolsas = { { bolsa = 0, slot = 1, itemID = 2589, qtd = 20 }, { bolsa = 1, slot = 3, itemID = 999, qtd = 1 } },
    itens = { [999] = { nome = "Raro", vend = 77, pilha = 1, nao_carregado = true } },
  },
  passos = {
    { chamar = function(b)
        local loc = ItemLocation:CreateFromBagAndSlot(0, 1)
        local vazio = ItemLocation:CreateFromBagAndSlot(0, 2)
        b.igual(C_Item.DoesItemExist(loc), true, "slot ocupado existe")
        b.igual(C_Item.DoesItemExist(vazio), false, "slot vazio nao existe")
        b.igual(C_Item.GetItemID(loc), 2589, "itemID")
        b.igual(C_Item.GetStackCount(loc), 20, "pilha")
        b.igual(C_Item.GetItemName(loc), "Linen Cloth", "nome")
        b.verdadeiro(string.find(C_Item.GetItemLink(loc), "item:2589", 1, true) ~= nil, "link")
        b.igual(select(11, C_Item.GetItemInfo(C_Item.GetItemLink(loc))), 13, "preco de vendedor no 11o retorno")
        b.igual(select(8, C_Item.GetItemInfo(2589)), 20, "pilha no 8o retorno")
        b.igual(C_Container.GetContainerNumSlots(0), 16, "tamanho da bolsa 0")
        b.igual(C_Container.GetContainerItemInfo(0, 1).stackCount, 20, "GetContainerItemInfo")
        b.verdadeiro(C_Container.GetContainerItemInfo(0, 2) == nil, "slot vazio")
        b.igual(C_AuctionHouse.GetItemCommodityStatus(loc), Enum.ItemCommodityStatus.Commodity, "linho e commodity")
        b.igual(C_AuctionHouse.GetItemKeyFromItem(loc).itemID, 2589, "itemKey da bolsa")
        b.igual(C_AuctionHouse.CalculateCommodityDeposit(2589, 2, 20), 78, "deposito de commodity: floor(13*20*0,15*2)")
        b.igual(C_AuctionHouse.CalculateItemDeposit(loc, 1, 5), 9, "deposito de item da bolsa: floor(13*5*0,15*1)")
        b.igual(pcall(C_AuctionHouse.CalculateItemDeposit, vazio, 1, 1), false, "deposito de item fora da bolsa nao responde")
        -- item ainda nao carregado
        local raro = ItemLocation:CreateFromBagAndSlot(1, 3)
        b.verdadeiro(C_Item.GetItemInfo(999) == nil, "999 ainda nao esta no cache")
        b.igual(C_AuctionHouse.GetItemCommodityStatus(raro), Enum.ItemCommodityStatus.Unknown, "estado desconhecido enquanto nao carrega")
        C_Item.RequestLoadItemDataByID(999)
      end },
    { ate_ocioso = true },
  },
  conferir = function(b)
    local ev = b.eventos("ITEM_DATA_LOAD_RESULT")
    b.igual(#ev, 1, "ITEM_DATA_LOAD_RESULT uma vez")
    b.igual(ev[1].args, { 999, true, n = 2 }, "com o itemID e sucesso")
    b.igual(select(11, C_Item.GetItemInfo(999)), 77, "depois do evento o preco de vendedor aparece")
    b.igual(b.contar("RequestLoadItemDataByID"), 1, "chamada contada")
    b.igual(b.contar("C_Item.GetItemInfo") >= 4, true, "tambem sob o nome qualificado")
  end,
}
