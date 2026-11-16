-- Ponta a ponta: duas mensagens descartadas encerram o folego.
return {
  id = "folego-05", grupo = "folego",
  descricao = "mensagem_descartada x2: o folego acaba no segundo descarte, sem mais consulta",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    mercado = { ["2589"] = { { preco = 9, qtd = 14, donos = 2 } }, ["2592"] = { { preco = 30, qtd = 5 } } } },
  passos = {
    { abrir_leilao = true },
    { injetar = { "mensagem_descartada", 2 } },
    { tecla = "L" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED"), 2, "dois descartes")
    b.igual(b.ns.pedidos.estado().fase, "PARADO", "pedidos parado")
    b.igual(b.ns.pedidos.estado().motivo, "descartada", "motivo: descartada")
    b.igual(b.ns.varredura.estado().fase, "PARADO", "varredura parada")
    b.igual(b.contar("SendSearchQuery"), 0, "nenhuma busca depois dos dois descartes")
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
