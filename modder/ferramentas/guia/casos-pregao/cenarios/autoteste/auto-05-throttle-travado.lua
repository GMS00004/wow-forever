-- Throttle travado: a mensagem fica na fila, o sistema nunca fica pronto; ao liberar, a fila anda.
return {
  id = "auto-05", grupo = "autoteste",
  descricao = "throttle_travado segura a fila; throttle_livre solta",
  inicio = { mercado = { ["2589"] = { { preco = 9, qtd = 14 } } } },
  passos = {
    { abrir_leilao = true },
    { injetar = "throttle_travado" },
    { tecla = "L" },
    { avancar = 40 },
    { chamar = function(b)
        b.igual(C_AuctionHouse.IsThrottledMessageSystemReady(), false, "travado: nao esta pronto")
        b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED"), 1, "a mensagem entrou na fila")
        b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_MESSAGE_SENT"), 0, "mas nunca foi enviada")
        b.igual(#b.eventos("AUCTION_HOUSE_NEW_RESULTS_RECEIVED"), 0, "nem respondida")
        b.igual(#b.ns.brinquedo.resumo, 0, "o addon nao viu resumo")
      end },
    { injetar = "throttle_livre" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_MESSAGE_SENT"), 1, "depois de liberar a mensagem sai")
    b.igual(#b.eventos("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED"), 1, "e a resposta chega")
    b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_SYSTEM_READY"), 1, "e o sistema fica pronto")
    b.verdadeiro(C_AuctionHouse.IsThrottledMessageSystemReady(), "pronto no fim")
    b.verdadeiro(b.agora() >= 40, "o relogio andou os 40 s")
  end,
}
