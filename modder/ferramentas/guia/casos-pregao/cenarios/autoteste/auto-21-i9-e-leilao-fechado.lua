-- I9: consulta sem tecla do dono ha mais de T_pulso conta violacao; consulta com o leilao fechado tambem; fechar zera a fila.
return {
  id = "auto-21", grupo = "autoteste",
  descricao = "consulta sem tecla (I9) e consulta com o leilao fechado contam violacao; fechar no meio zera a fila",
  aceita_violacoes = true,
  inicio = { mercado = { ["2589"] = { { preco = 9, qtd = 14 } } } },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b) b.ns.brinquedo.consultaBrowse() end },       -- sem tecla nenhuma: I9
    { ate_ocioso = true },
    { tecla = "C" },                                                      -- com tecla: ok
    { ate_ocioso = true },
    { avancar = 95 },                                                      -- passa de T_pulso (90 s)
    { chamar = function(b) b.ns.brinquedo.consultaCommodity(2589) end }, -- I9 de novo
    { ate_ocioso = true },
    { tecla = "L" },
    { avancar = 0.15 },                                                    -- a mensagem ja foi enviada, a resposta ainda nao
    { fechar_leilao = true },
    { ate_ocioso = true },
    { chamar = function(b) b.ns.brinquedo.proprios() end },              -- leilao fechado
  },
  conferir = function(b)
    local v = b.violacoes()
    b.igual(#v, 3, "tres violacoes")
    b.igual(v[1].tipo, "I9", "primeira: I9")
    b.igual(v[2].tipo, "I9", "segunda: I9")
    b.igual(v[3].tipo, "fechado", "terceira: leilao fechado")
    b.igual(#b.eventos("AUCTION_HOUSE_CLOSED"), 1, "CLOSED")
    -- o resumo do L nunca respondeu: fechar descartou a mensagem em voo
    b.igual(#b.eventos("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED"), 3, "o resumo do primeiro pedido e os dois espurios das buscas de commodity; o do L foi descartado")
    b.igual(b.contar("QueryOwnedAuctions"), 1, "a chamada ao leilao fechado fica registrada")
    b.igual(C_AuctionHouse.IsThrottledMessageSystemReady(), false, "fechado nao esta pronto")
  end,
}
