-- Fim sujo: fim diferente do seq ou dinheiro diferente do fecho marca ns.banco.fimSujo e registra no log; o banco segue.
return {
  id = "banco-06", grupo = "unid-banco",
  descricao = "fim sujo: fim diferente de seq e dinheiro diferente do fecho marcam fimSujo e registram no log; o banco segue",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912,
    sv_char = { bancoDesde = 1794800000 },
    sv = {
      esquema = 1, epoca = 1794800000, seq = 7, recibo = 0, fim = 5, calib = {}, casas = {}, sinais = {},
      pers = { Hexumlite = { fecho = { dinheiro = 1000, t = 1794800000, seq = 5 } } },
      sessoes = {}, sonda = {}, log = {}, sobrescritos = {}, salvoEm = 1794800000,
    },
  },
  passos = {},
  conferir = function(b)
    b.igual(b.ns.banco.carregado, true, "carregou o banco existente")
    b.igual(b.ns.banco.fimSujo, true, "fim sujo marcado")
    b.verdadeiro(b.db().seq >= 7, "o banco segue do seq que tinha, sem voltar")
    local registro = table.concat(b.ns.registro:itens(), "\n")
    b.verdadeiro(string.find(registro, "saida sem fecho limpo", 1, true) ~= nil, "registrado no log")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
