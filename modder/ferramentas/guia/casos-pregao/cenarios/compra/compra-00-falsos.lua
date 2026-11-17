-- Fumaca dos falsos de compra (profissao, vendedor, venda, full scan), sem depender do CompraForever.
-- Compra 2 Fine Thread no vendedor, crafta 1 Raptor Hide Harness (6 Raptor Hide, 4 Heavy Leather, 2 Fine Thread),
-- vende o Harness no vendedor e faz um ReplicateItems no leilao.
return {
  id = "compra-00", grupo = "compra",
  descricao = "vendedor: compra 2 e vende 1; profissao: crafta 1; leilao: ReplicateItems com a lista chegando aos poucos",
  inicio = {
    dinheiro = 100000,
    itens = {
      [2321] = { nome = "Fine Thread", vend = 5, pilha = 20 },
      [4461] = { nome = "Raptor Hide", vend = 30, pilha = 20 },
      [4455] = { nome = "Raptor Hide Harness", vend = 3000, pilha = 1 },
    },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4461, qtd = 6 },
      { bolsa = 0, slot = 2, itemID = 4234, qtd = 4 },
    },
    receitas = {
      [4096] = { nome = "Raptor Hide Harness", produto = 4455, qtd = 1, reagentes = { { 4461, 6 }, { 4234, 4 }, { 2321, 2 } } },
    },
    vendedor = { { itemID = 2321, preco = 25 } },
    mercado = {
      ["2589"] = { { preco = 9, qtd = 14, donos = 2 }, { preco = 11, qtd = 40 } },
      ["2592"] = { { preco = 35, qtd = 5 } },
    },
  },
  passos = {
    { abrir_vendedor = true },
    { chamar = function(b)
      b.igual(MerchantFrame:IsShown(), true, "MerchantFrame aberto")
      b.igual(GetMerchantNumItems(), 1, "uma linha no vendedor")
      b.igual(GetMerchantItemID(1), 2321, "a linha 1 e o Fine Thread")
      b.igual(GetMerchantItemMaxStack(1), 20, "pilha maxima 20")
      BuyMerchantItem(1, 2)
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(2321), 2, "2 Fine Thread nas bolsas")
      b.igual(GetMoney(), 99950, "dinheiro depois da compra (2 x 25)")
    end },
    { fechar_vendedor = true },
    { abrir_profissao = true },
    { chamar = function(b)
      b.verdadeiro(C_TradeSkillUI.IsTradeSkillReady(), "profissao pronta")
      b.falso(C_TradeSkillUI.IsTradeSkillLinked() or C_TradeSkillUI.IsTradeSkillGuild() or C_TradeSkillUI.IsNPCCrafting(), "janela propria")
      b.igual(C_TradeSkillUI.GetBaseProfessionInfo().professionName, "Leatherworking", "profissao")
      b.igual(C_TradeSkillUI.GetChildProfessionInfo().skillLevel, 150, "pericia")
      b.igual(C_TradeSkillUI.GetAllRecipeIDs(), { 4096 }, "receitas")
      b.igual(C_TradeSkillUI.GetRecipeInfo(4096).learned, true, "receita aprendida")
      C_TradeSkillUI.CraftRecipe(4096, 1)
    end },
    { avancar = 2 },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(4455), 1, "1 Harness craftado")
      b.igual(C_Item.GetItemCount(4461), 0, "Raptor Hide consumido")
      b.igual(C_Item.GetItemCount(4234), 0, "Heavy Leather consumido")
      b.igual(C_Item.GetItemCount(2321), 0, "Fine Thread consumido")
    end },
    { fechar_profissao = true },
    { abrir_vendedor = true },
    { chamar = function(b)
      local achou
      for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
          if C_Container.GetContainerItemID(bag, slot) == 4455 then achou = { bag, slot } end
        end
      end
      b.verdadeiro(achou ~= nil, "Harness numa bolsa")
      C_Container.UseContainerItem(achou[1], achou[2])
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(4455), 0, "Harness vendido")
      b.igual(GetMoney(), 102950, "dinheiro depois da venda (+3000)")
      b.igual((C_Container.GetContainerNumFreeSlots(0)), 16, "bolsa 0 vazia de novo")
    end },
    { fechar_vendedor = true },
    { abrir_leilao = true },
    { chamar = function(b)
      b.igual(C_AuctionHouse.GetNumReplicateItems(), 0, "lista vazia antes")
      C_AuctionHouse.ReplicateItems()
    end },
    { avancar = 3 },
    { chamar = function(b)
      local n = C_AuctionHouse.GetNumReplicateItems()
      b.verdadeiro(n > 0 and n < 3, "lista parcial depois de 3 s: " .. tostring(n))
      b.igual(#b.eventos("REPLICATE_ITEM_LIST_UPDATE"), 0, "sem evento antes do fim")
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(C_AuctionHouse.GetNumReplicateItems(), 3, "lista inteira")
      b.igual(#b.eventos("REPLICATE_ITEM_LIST_UPDATE"), 1, "um evento no fim")
      local r = { C_AuctionHouse.GetReplicateItemInfo(0) }
      b.igual(#r, 18, "18 retornos")
      b.igual(r[3], 14, "quantidade (3o)")
      b.igual(r[10], 126, "buyout total (10o)")
      b.igual(r[17], 2589, "itemID (17o)")
      b.igual(C_AuctionHouse.GetReplicateItemInfo(3), nil, "fora do alcance")
      b.igual(select(11, C_Item.GetItemInfo(4455)), 3000, "preco de venda ao vendedor (11o)")
      b.verdadeiro(string.find(GetCoinTextureString(102950), "10", 1, true) ~= nil, "GetCoinTextureString")
    end },
  },
  conferir = function(b)
    b.igual(GetMoney(), 102950, "dinheiro final")
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
