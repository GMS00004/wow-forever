-- Busca de commodity: NEW_RESULTS_RECEIVED(itemKey), COMMODITY_SEARCH_RESULTS_UPDATED(itemID) e um BROWSE_RESULTS_UPDATED espurio.
return {
  id = "auto-02", grupo = "autoteste",
  descricao = "SendSearchQuery de commodity: sequencia, resultados ordenados e donos",
  inicio = {
    mercado = { ["2589"] = { { preco = 11, qtd = 40, donos = 1 }, { preco = 9, qtd = 14, donos = 2 }, { preco = 15, qtd = 3, donos = 1 } } },
  },
  passos = {
    { abrir_leilao = true },
    { tecla = "C" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    local nomes = {}
    for i = 2, #b.eventos() do
      local e = b.eventos()[i]
      if string.find(e.nome, "^AUCTION_HOUSE_THROTTLED") or e.nome == "AUCTION_HOUSE_NEW_RESULTS_RECEIVED" or string.find(e.nome, "RESULTS_UPDATED$") then nomes[#nomes + 1] = e.nome end
    end
    b.igual(nomes, {
      "AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED", "AUCTION_HOUSE_THROTTLED_MESSAGE_SENT",
      "AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED", "AUCTION_HOUSE_NEW_RESULTS_RECEIVED",
      "COMMODITY_SEARCH_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_THROTTLED_SYSTEM_READY",
    }, "sequencia da busca de commodity")
    local novo = b.eventos("AUCTION_HOUSE_NEW_RESULTS_RECEIVED")[1]
    b.igual(novo.args[1].itemID, 2589, "NEW_RESULTS_RECEIVED traz a itemKey")
    b.igual(b.eventos("COMMODITY_SEARCH_RESULTS_UPDATED")[1].args[1], 2589, "COMMODITY_SEARCH_RESULTS_UPDATED traz o itemID")
    b.igual(C_AuctionHouse.GetNumCommoditySearchResults(2589), 3, "tres degraus")
    local d1 = C_AuctionHouse.GetCommoditySearchResultInfo(2589, 1)
    b.igual(d1.unitPrice, 9, "o primeiro degrau e o mais barato")
    b.igual(d1.quantity, 14, "quantidade do primeiro degrau")
    b.igual(d1.totalNumberOfOwners, 2, "donos do primeiro degrau")
    b.igual(#d1.owners, 2, "owners e uma lista de nomes (o addon nunca deve grava-los)")
    b.igual(C_AuctionHouse.GetCommoditySearchResultInfo(2589, 3).unitPrice, 15, "o ultimo degrau e o mais caro")
    b.igual(C_AuctionHouse.GetCommoditySearchResultsQuantity(2589), 57, "quantidade total")
    b.verdadeiro(C_AuctionHouse.HasFullCommoditySearchResults(2589), "resultado completo")
    b.verdadeiro(C_AuctionHouse.GetCommoditySearchResultInfo(2589, 4) == nil, "indice fora da lista devolve nil")
  end,
}
