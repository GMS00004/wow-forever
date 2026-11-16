-- Paginacao do resumo: 480 linhas por pedido ate HasFullBrowseResults; ADDED traz so a pagina nova.
local mercado = {}
for i = 1, 1200 do mercado[tostring(30000 + i)] = { { preco = 100 + i, qtd = 1, donos = 1 } } end

return {
  id = "auto-04", grupo = "autoteste",
  descricao = "resumo de 1200 linhas em tres paginas (480, 480, 240)",
  inicio = { mercado = mercado },
  passos = {
    { abrir_leilao = true },
    { tecla = "L" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.contar("SendBrowseQuery"), 1, "um pedido de resumo")
    b.igual(b.contar("RequestMoreBrowseResults"), 2, "duas paginas a mais")
    b.igual(#b.eventos("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED"), 1, "UPDATED uma vez")
    local add = b.eventos("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
    b.igual(#add, 2, "ADDED duas vezes")
    b.igual(#add[1].args[1], 480, "primeiro ADDED com 480 linhas")
    b.igual(#add[2].args[1], 240, "segundo ADDED com 240 linhas")
    b.igual(#b.ns.brinquedo.resumo, 1200, "o addon acumulou as 1200 linhas")
    b.verdadeiro(C_AuctionHouse.HasFullBrowseResults(), "HasFullBrowseResults no fim")
    b.igual(#C_AuctionHouse.GetBrowseResults(), 1200, "GetBrowseResults devolve a lista inteira")
    b.igual(b.ns.brinquedo.resumo[1].itemKey.itemID, 30001, "ordem por itemID")
    b.igual(b.ns.brinquedo.resumo[1200].itemKey.itemID, 31200, "ultima linha")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
