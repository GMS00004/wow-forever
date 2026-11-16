-- Mensagem descartada: QUEUED, DROPPED, READY, sem resposta; a seguinte passa normal.
return {
  id = "auto-06", grupo = "autoteste",
  descricao = "mensagem_descartada: DROPPED no lugar de SENT; a proxima consulta segue",
  inicio = { mercado = { ["2589"] = { { preco = 9, qtd = 14 } } } },
  passos = {
    { abrir_leilao = true },
    { injetar = "mensagem_descartada" },
    { tecla = "L" },
    { ate_ocioso = true },
    { chamar = function(b)
        b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED"), 1, "um DROPPED")
        b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_MESSAGE_SENT"), 0, "sem SENT")
        b.igual(#b.eventos("AUCTION_HOUSE_NEW_RESULTS_RECEIVED"), 0, "sem resposta")
        b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_SYSTEM_READY"), 1, "o sistema volta a ficar pronto")
      end },
    { tecla = "L" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED"), 1, "so uma foi descartada")
    b.igual(#b.eventos("AUCTION_HOUSE_NEW_RESULTS_RECEIVED"), 1, "a segunda foi respondida")
    b.igual(b.contar("SendBrowseQuery"), 2, "duas chamadas")
  end,
}
