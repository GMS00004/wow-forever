-- Funcao de acao dentro de clique de botao PregaoForever*: tem efeito, nao conta violacao, e o eco vem na ordem da tabela.
return {
  id = "auto-08", grupo = "autoteste",
  descricao = "PostCommodity em clique de PregaoForeverTeclaP: deposito, bolsa, AUCTION_CREATED e OWNED_AUCTIONS_UPDATED",
  inicio = {
    dinheiro = 40000,
    bolsas = { { bolsa = 0, slot = 1, itemID = 2589, qtd = 20 } },
  },
  passos = {
    { abrir_leilao = true },
    { tecla = "P" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(b.contar("PostCommodity"), 1, "uma chamada")
    b.igual(b.chamadas("PostCommodity")[1].clique, 1, "a chamada registra o id do clique")
    b.igual(#b.eventos("AUCTION_HOUSE_AUCTION_CREATED"), 1, "um eco de leilao criado")
    b.igual(#b.eventos("OWNED_AUCTIONS_UPDATED"), 1, "e o aviso dos proprios")
    b.verdadeiro(b.eventos("AUCTION_HOUSE_AUCTION_CREATED")[1].t <= b.eventos("OWNED_AUCTIONS_UPDATED")[1].t, "nesta ordem")
    -- deposito: floor(13 * 1 * 0,15 * 24/12) = 3
    b.igual(GetMoney(), 39997, "o deposito saiu do dinheiro")
    b.igual(C_Item.GetStackCount(ItemLocation:CreateFromBagAndSlot(0, 1)), 19, "uma unidade saiu da bolsa")
    b.igual(C_AuctionHouse.GetNumOwnedAuctions(), 1, "um leilao proprio")
    local info = C_AuctionHouse.GetOwnedAuctionInfo(1)
    b.igual(info.buyoutAmount, 10, "preco unitario do leilao proprio")
    b.igual(#b.eventos("PLAYER_MONEY"), 1, "PLAYER_MONEY pelo deposito")
  end,
}
