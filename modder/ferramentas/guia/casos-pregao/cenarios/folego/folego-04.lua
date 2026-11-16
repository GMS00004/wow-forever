-- Ponta a ponta: throttle travado vira TRAVADO com a faixa; fechar e reabrir o leilao limpa.
return {
  id = "folego-04", grupo = "folego",
  descricao = "throttle_travado: em 30 s a faixa API STALLED liga e nada sai; fechar e reabrir limpa e o L volta a funcionar",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    mercado = { ["2589"] = { { preco = 9, qtd = 14, donos = 2 } } } },
  passos = {
    { abrir_leilao = true },
    { injetar = "throttle_travado" },
    { tecla = "L" },
    { avancar = 40 },
    { chamar = function(b)
        b.__faixa = b.ns.faixa
        b.__fase = b.ns.pedidos.estado().fase
        b.__consultas = b.contar("QueryOwnedAuctions") + b.contar("SendBrowseQuery") + b.contar("SendSearchQuery")
        b.__tela = b.tela() and b.tela().faixa
      end },
    { fechar_leilao = true },
    { abrir_leilao = true },
    { chamar = function(b) b.__faixa2 = b.ns.faixa end },
    { tecla = "L" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.__fase, "TRAVADO", "TRAVADO")
    b.igual(b.__faixa, "API STALLED - close and reopen the auction house", "faixa de travado")
    b.igual(b.__consultas, 0, "nenhuma consulta com o throttle travado")
    b.verdadeiro(b.__faixa2 ~= "API STALLED - close and reopen the auction house", "reabrir limpa a faixa de travado")
    b.igual(b.contar("QueryOwnedAuctions"), 1, "o L depois de reabrir consulta")
    b.igual(b.ns.pedidos.estado().fase, "PARADO", "pedidos parado no fim")
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
