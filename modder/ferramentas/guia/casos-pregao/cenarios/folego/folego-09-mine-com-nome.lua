-- Ponta a ponta: depois do L, a visao Mine mostra o nome do item de cada leilao proprio (nao so o id do leilao).
return {
  id = "folego-09", grupo = "folego",
  descricao = "Mine mostra o nome do item do leilao proprio depois do primeiro folego",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912,
    itens = { [2589] = { nome = "Linen Cloth", vend = 13, pilha = 200 } },
    mercado = { ["2589"] = { { preco = 9, qtd = 14, donos = 2 } } },
    proprios = { { id = 1001, itemID = 2589, qtd = 20, preco = 180 } },
  },
  passos = {
    { avancar = 1 },
    { abrir_leilao = true },
    { avancar = 1 },
    { tecla = "L" },
    { ate_ocioso = true },
    { tecla = "F3" },
    { avancar = 1 },
  },
  conferir = function(b)
    b.igual(b.tela().visao, "mine", "visao Mine")
    local txt = table.concat(b.tela().linhas, "\n")
    b.verdadeiro(string.find(txt, "Linen Cloth x20", 1, true) ~= nil, "nome do item na linha do leilao: " .. txt)
    b.verdadeiro(string.find(txt, "Auction 1001", 1, true) == nil, "sem o id cru do leilao")
    b.igual(#b.erros(), 0, "nenhum erro de Lua")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
