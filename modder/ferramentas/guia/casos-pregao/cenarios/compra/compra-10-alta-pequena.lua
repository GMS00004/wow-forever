-- O mercado sobe um pouco entre o scan e a cotacao: a leva ainda paga, entao o addon pede Confirm e compra.
return {
  id = "compra-10", grupo = "compra",
  descricao = "alta pequena: a cotacao passa do planejado mas cabe em 2% + metade do lucro; o addon pede Confirm e compra",
  inicio = {
    dinheiro = 51400,
    itens = {
      [4461] = { nome = "Raptor Hide", vend = 208, pilha = 10 },
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
      ["4461"] = { { preco = 130, qtd = 8 }, { preco = 160, qtd = 100 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.ns.plano.leilao[1].custo, 1680, "custo planejado")
      -- o mercado sobe 40c por unidade: total 2160 contra 1680 planejado, dentro do limite
      for _, r in ipairs(__bancada.A.mercado[4461]) do r.preco = r.preco + 40 end
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("CancelCommoditiesPurchase"), 0, "nao cancelou")
      b.igual(CompraForeverAcao:GetText(), "Confirm 12 Raptor Hide (21s 60c)", "pede confirmacao com o total novo")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 1, "confirmou")
      b.igual(GetMoney(), 51400 - 2160, "pagou o total novo")
      b.igual(b.ns.sessao.comprado[4461], 12, "comprou as 12")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
