-- Ponta a ponta: banco perdido com bancoDesde do personagem. O leilao abre em leitura, com a faixa do banco, e nada e recriado.
return {
  id = "dados-03", grupo = "dados",
  descricao = "banco perdido com bancoDesde: modo leitura e faixa DATABASE NOT LOADED, nada recriado com o leilao aberto",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912,
    sv_char = { bancoDesde = 1794800000 },
  },
  passos = {
    { abrir_leilao = true },
    { avancar = 5 },
    { evento = { "PLAYER_LOGOUT" } },
  },
  conferir = function(b)
    b.igual(b.ns.modo(), "leitura", "modo leitura")
    b.igual(b.ns.faixa, "DATABASE NOT LOADED - tell the agent", "faixa do banco")
    b.igual(b.ns.banco.carregado, false, "banco nao carregou")
    b.verdadeiro(b.db() == nil, "PregaoForeverDB nao foi recriada")
    b.igual(b.contar("SendBrowseQuery"), 0, "sem consulta sem tecla")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
