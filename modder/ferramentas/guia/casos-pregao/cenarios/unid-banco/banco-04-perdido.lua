-- Banco perdido: PregaoForeverDB nil com bancoDesde do personagem. Nada recriado, nada gravado no fechar.
return {
  id = "banco-04", grupo = "unid-banco",
  descricao = "banco nil com bancoDesde: carregado false, faixa do banco, nada recriado, nada gravado no fechar",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912,
    sv_char = { bancoDesde = 1794800000 },
  },
  passos = {
    { evento = { "PLAYER_LOGOUT" } },
  },
  conferir = function(b)
    b.igual(b.ns.banco.carregado, false, "nao carregou")
    b.igual(b.ns.modo(), "leitura", "modo leitura")
    b.igual(b.ns.faixa, "DATABASE NOT LOADED - tell the agent", "faixa do banco")
    b.verdadeiro(b.db() == nil, "PregaoForeverDB nao foi recriada, nem no logout")
    b.igual(PregaoForeverCharDB.bancoDesde, 1794800000, "marca do personagem intacta")
    b.igual(b.ns.banco.gravar('livro', '1|1|post|x'), false, "gravar nao grava")
    b.verdadeiro(b.ns.banco.seq() == nil, "seq nao avanca")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
