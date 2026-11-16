-- Ponta a ponta: uma sessao curta com leilao, folego, uma venda por fora e correio grava um SV que o ler-pregao.mjs le.
-- O arquivo salvo (dados/pregao/bancada/dados-04-sv.lua) e a entrada da ida e volta da gramatica na mesa.
return {
  id = "dados-04", grupo = "dados",
  descricao = "sessao curta grava um SV completo e limpo para a mesa ler",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912,
    bolsas = { { bolsa = 0, slot = 1, itemID = 2589, qtd = 20 } },
    mercado = { ["2589"] = { { preco = 9, qtd = 14, donos = 2 }, { preco = 10, qtd = 200, donos = 5 } } },
  },
  passos = {
    { avancar = 1 },
    { abrir_leilao = true },
    { avancar = 1 },
    { tecla = "L" },
    { ate_ocioso = true },
    { fechar_leilao = true },
    { avancar = 5 },
    { reload = true },
    { avancar = 1 },
    { salvar_sv = "dados-04" },
  },
  conferir = function(b)
    local db = b.db()
    b.igual(db.esquema, 1, "esquema do banco")
    b.verdadeiro((db.seq or 0) > 0, "o banco gravou registros")
    b.igual(db.fim, db.seq, "saida limpa no reload")
    b.igual(#b.erros(), 0, "nenhum erro de Lua")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
