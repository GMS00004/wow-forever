-- Ponta a ponta: sem leiloes proprios, a Mine diz "none read yet" antes do L e "no auctions posted" depois.
return {
  id = "folego-10", grupo = "folego",
  descricao = "Mine vazia distingue ainda nao lido de lido sem leiloes",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912,
    mercado = { ["2589"] = { { preco = 9, qtd = 14, donos = 2 } } },
  },
  passos = {
    { avancar = 1 },
    { abrir_leilao = true },
    { avancar = 1 },
    { tecla = "F3" },
    { avancar = 1 },
    { chamar = function(b) b.__antes = table.concat(b.tela().linhas, "\n") end },
    { tecla = "L" },
    { ate_ocioso = true },
    { avancar = 1 },
  },
  conferir = function(b)
    b.verdadeiro(string.find(b.__antes, "none read yet - press L", 1, true) ~= nil, "antes do L: ainda nao lido")
    local depois = table.concat(b.tela().linhas, "\n")
    b.verdadeiro(string.find(depois, "no auctions posted", 1, true) ~= nil, "depois do L: lido, sem leiloes: " .. depois)
    b.igual(#b.erros(), 0, "nenhum erro de Lua")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
