-- Ponta a ponta: abrir o leilao e esperar 60 s sem tecla. Nenhuma consulta da regra 9 pode sair; a faixa pede a conciliacao.
-- A saida anterior foi suja (fim diferente do seq e dinheiro diferente do fecho): e esse o caso em que a conciliacao vira faixa.
return {
  id = "dados-01", grupo = "dados",
  descricao = "abrir o leilao e avancar 60 s sem tecla: nenhuma consulta da regra 9 e ns.faixa = Press L to reconcile",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912,
    sv_char = { bancoDesde = 1794800000 },
    sv = {
      esquema = 1, epoca = 1794800000, seq = 7, recibo = 0, fim = 5, calib = {}, casas = {}, sinais = {},
      pers = { Hexumlite = { fecho = { dinheiro = 1000, t = 1794800000, seq = 5 } } },
      sessoes = {}, sonda = {}, log = {}, sobrescritos = {}, salvoEm = 1794800000,
    },
  },
  passos = {
    { abrir_leilao = true },
    { avancar = 60 },
  },
  conferir = function(b)
    local consultas = {
      "SendBrowseQuery", "RequestMoreBrowseResults", "SendSearchQuery", "SendSellSearchQuery",
      "RefreshCommoditySearchResults", "RefreshItemSearchResults", "RequestMoreCommoditySearchResults",
      "RequestMoreItemSearchResults", "QueryOwnedAuctions",
    }
    for _, nome in ipairs(consultas) do
      b.igual(b.contar(nome), 0, nome .. " nao saiu sem tecla")
    end
    b.igual(b.ns.faixa, "Press L to reconcile", "faixa de conciliacao depois do leilao aberto")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
