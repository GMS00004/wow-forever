-- Busca de item (nao commodity): ITEM_SEARCH_RESULTS_UPDATED(itemKey), sem o evento espurio do resumo; variante com newAuctionID.
return {
  id = "auto-03", grupo = "autoteste",
  descricao = "SendSearchQuery de item: sequencia e a variante com newAuctionID",
  inicio = {
    itens = { [12345] = { nome = "Teste de Espada", vend = 500, pilha = 1, qual = 2, nivel = 20 } },
    mercado = { ["12345"] = {
      { preco = 3000, qtd = 1, nivel = 20, donos = 1 },
      { preco = 2500, qtd = 1, nivel = 20, donos = 1 },
      { preco = 9000, qtd = 1, nivel = 25, donos = 1 },
    } },
  },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b) b.ns.brinquedo.itemKey = C_AuctionHouse.MakeItemKey(12345, 20, 0) end },
    { tecla = "I" },
    { ate_ocioso = true },
    { injetar = "item_atualizado" },
    { tecla = "I" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    local ups = b.eventos("ITEM_SEARCH_RESULTS_UPDATED")
    b.igual(#ups, 3, "um evento na primeira busca e dois na variante")
    b.igual(ups[1].n, 1, "o evento normal so traz a itemKey")
    b.igual(ups[1].args[1].itemID, 12345, "itemKey do evento")
    b.igual(ups[2].n, 2, "a variante traz newAuctionID")
    b.verdadeiro(type(ups[2].args[2]) == "number", "newAuctionID e numero")
    b.igual(ups[3].n, 1, "e depois vem o evento verdadeiro")
    b.igual(#b.eventos("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED"), 0, "busca de item nao dispara o evento espurio do resumo")
    local k = b.ns.brinquedo.itemKey
    b.igual(C_AuctionHouse.GetNumItemSearchResults(k), 2, "so os leiloes do nivel 20")
    b.igual(C_AuctionHouse.GetItemSearchResultInfo(k, 1).buyoutAmount, 2500, "o mais barato primeiro")
    b.verdadeiro(C_AuctionHouse.HasFullItemSearchResults(k), "completo")
  end,
}
