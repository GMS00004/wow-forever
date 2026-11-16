-- Throttle que nao fica pronto por mais de throttle_travado_s vira TRAVADO, com a faixa, e nada sai.
return {
  id = "pedidos-06", grupo = "unid-pedidos",
  descricao = "throttle travado: depois de 30 s a fase e TRAVADO, a faixa liga, nenhuma consulta sai; reabrir limpa",
  inicio = { mercado = { ["2589"] = { { preco = 9, qtd = 14 } } } },
  passos = {
    { abrir_leilao = true },
    { injetar = "throttle_travado" },
    { chamar = function(b)
        __bancada.ultimaTecla = __bancada.agoraUs()
        b.ns.pedidos.tecla()
        b.__aberto = b.ns.varredura.tecla()
      end },
    { avancar = 20 },
    { chamar = function(b)
        b.__fase20 = b.ns.pedidos.estado().fase
        b.__faixa20 = b.ns.faixaLigada("travado")
        b.__vf20 = b.ns.varredura.estado().fase
      end },
    { avancar = 15 },
    { chamar = function(b)
        b.__fase35 = b.ns.pedidos.estado().fase
        b.__faixa35 = b.ns.faixa
        b.__vf35 = b.ns.varredura.estado().fase
        b.__cntAntes = b.contar("QueryOwnedAuctions")
        b.__nova = { b.ns.varredura.tecla() }
        b.__enviar = { b.ns.pedidos.enviar({ tipo = "busca", chave = "2589" }) }
      end },
    { fechar_leilao = true },
    { abrir_leilao = true },
    { chamar = function(b)
        b.__faixaFim = b.ns.faixaLigada("travado")
        b.__faseFim = b.ns.pedidos.estado().fase
        __bancada.ultimaTecla = __bancada.agoraUs()
        b.ns.pedidos.tecla()
        b.__reabre = b.ns.varredura.tecla()
      end },
  },
  conferir = function(b)
    b.igual(b.__aberto, true, "a tecla abriu o folego")
    b.igual(b.__fase20, "ABERTO", "aos 20 s ainda ABERTO")
    b.igual(b.__faixa20, false, "sem faixa de travado aos 20 s")
    b.igual(b.__vf20, "PROPRIOS", "varredura espera no PROPRIOS")
    b.igual(b.__fase35, "TRAVADO", "aos 35 s TRAVADO")
    b.igual(b.__faixa35, "API STALLED - close and reopen the auction house", "faixa de travado")
    b.igual(b.__vf35, "PARADO", "varredura parou")
    b.igual(b.__nova[2], "travado", "nova tecla recusada: travado")
    b.igual(b.__enviar[1], false, "enviar recusado")
    b.igual(b.__cntAntes, 0, "nenhuma consulta saiu com o throttle travado")
    b.igual(b.__faixaFim, false, "fechar e reabrir limpa a faixa de travado")
    b.igual(b.__faseFim, "PARADO", "pedidos PARADO depois de reabrir")
    b.igual(b.__reabre, true, "um folego novo abre")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
