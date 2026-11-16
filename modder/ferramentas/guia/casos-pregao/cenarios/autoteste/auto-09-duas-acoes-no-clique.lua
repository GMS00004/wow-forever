-- I1: a segunda funcao de acao no mesmo clique conta violacao e nao tem efeito.
return {
  id = "auto-09", grupo = "autoteste",
  descricao = "duas acoes num clique: a segunda e violacao I1",
  aceita_violacoes = true,
  inicio = {
    dinheiro = 40000,
    bolsas = { { bolsa = 0, slot = 1, itemID = 2589, qtd = 20 } },
    proprios = { { itemID = 2589, qtd = 5, preco = 12 } },
  },
  passos = {
    { abrir_leilao = true },
    { tecla = "D" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    local v = b.violacoes()
    b.igual(#v, 1, "uma violacao")
    b.igual(v[1].tipo, "I1", "do tipo I1")
    b.igual(b.contar("PostCommodity"), 1, "a primeira passou")
    b.igual(b.contar("CancelAuction"), 1, "a segunda foi chamada")
    b.igual(#b.eventos("AUCTION_CANCELED"), 0, "mas nao teve efeito")
    b.igual(#b.eventos("AUCTION_HOUSE_AUCTION_CREATED"), 1, "a primeira teve")
    b.igual(b.chamadas("PostCommodity")[1].clique, b.chamadas("CancelAuction")[1].clique, "as duas no mesmo clique")
  end,
}
