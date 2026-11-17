-- Reagente em leiloes inteiros: um PlaceBid por clique, lote a lote, ate completar.
return {
  id = "compra-06", grupo = "compra",
  descricao = "item: lote a lote, um PlaceBid por clique (preco * qtd), texto lot k/n, escada consumida, plano refeito",
  inicio = {
    dinheiro = 51400,
    itens = {
      [4461] = { nome = "Raptor Hide", vend = 208, pilha = 10, commodity = false },
      [4234] = { nome = "Heavy Leather", vend = 150, pilha = 20 },
      [2321] = { nome = "Fine Thread", vend = 25, pilha = 20 },
      [4455] = { nome = "Raptor Hide Harness", vend = 3096, pilha = 1 },
    },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4234, qtd = 8 },
      { bolsa = 0, slot = 2, itemID = 2321, qtd = 4 },
    },
    receitas = {
      [4096] = { nome = "Raptor Hide Harness", produto = 4455, qtd = 1, reagentes = { { 4461, 6 }, { 4234, 4 }, { 2321, 2 } } },
    },
    sv_char = { conhecidas = { quem = "Hexumlite", em = 1, ids = { [4096] = true }, n = 1 } },
    mercado = {
      ["4461"] = {
        { preco = 600, qtd = 4 }, { preco = 520, qtd = 4 }, { preco = 560, qtd = 4 }, { preco = 340, qtd = 2 },
        { preco = 9000, qtd = 4 },
      },
    },
  },
  passos = {
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      local row = ns.plano.leilao[1]
      b.verdadeiro(row ~= nil and row.inteiro, "plano com a compra inteira de Raptor Hide")
      b.igual(row.qtd, 12, "12 unidades")
      b.igual(#row.lotes, 3, "3 lotes de 4 (o lote de 2 e o caro ficam de fora)")
      b.igual(ns.proximaAcao().texto, "Buy Raptor Hide lot 1/3 (5s 20c)", "primeiro lote: o mais barato por unidade")
      b.igual(ns.sessao.comprado[4461], nil, "nada comprado")
    end },
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("PlaceBid"), 1, "um PlaceBid no clique")
      local c = b.chamadas("PlaceBid")[1]
      b.igual(c.args[2], 520, "lance = preco * qtd")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado ate a resposta")
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(GetMoney(), 51400 - 520, "dinheiro depois do lote 1")
      b.igual(b.contar("PlaceBid"), 1, "ainda um PlaceBid")
      b.igual(ns.sessao.comprado[4461], 4, "sessao: 4 comprados")
      b.igual(ns.sessao.lotes[4461], 1, "sessao: 1 lote")
      b.igual(CompraForeverAcao:GetText(), "Buy Raptor Hide lot 2/3 (5s 60c)", "proximo lote")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("PlaceBid"), 2, "dois PlaceBid")
      b.igual(GetMoney(), 51400 - 520 - 560, "dinheiro depois do lote 2")
      b.igual(CompraForeverAcao:GetText(), "Buy Raptor Hide lot 3/3 (6s)", "ultimo lote")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("PlaceBid"), 3, "tres PlaceBid, um por clique")
      b.igual(GetMoney(), 51400 - 1680, "dinheiro final")
      b.igual(ns.sessao.comprado[4461], 12, "12 comprados")
      b.igual(ns.sessao.lotes[4461], 3, "3 lotes")
      b.igual(ns.estoque(4461), 12, "estoque conta o que vem pelo correio")
      b.igual(#ns.plano.leilao, 0, "nada mais a comprar")
      b.igual(ns.plano.crafts[1].n, 2, "2 crafts com o estoque")
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "sem acao")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado")
      local sobra = ns.scan.escadas[4461]
      b.igual(#sobra, 2, "restam os dois leiloes que ficaram de fora")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
