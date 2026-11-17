-- O mercado sobe entre o scan e a cotacao: o addon cancela, nao confirma e pede novo Scan.
return {
  id = "compra-05", grupo = "compra",
  descricao = "preco subiu: Cancel na cotacao acima de custo * 1,02 + 1, sem Confirm, texto Price rose, item fora do plano ate novo scan",
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
      -- o mercado sobe depois do scan
      for _, r in ipairs(__bancada.A.mercado[4461]) do r.preco = r.preco + 40 end
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "um Start")
      b.igual(b.contar("CancelCommoditiesPurchase"), 1, "cotacao cancelada")
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 0, "nunca confirmou")
      b.igual(CompraForeverAcao:GetText(), "Price rose: Scan again", "texto do botao")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado")
      b.igual(ns.proximaAcao().texto, "Price rose: Scan again", "proximaAcao")
      b.igual(GetMoney(), 51400, "dinheiro intacto")
      b.igual(ns.scan.escadas[4461], nil, "o item sai do plano ate novo scan")
      b.igual(#ns.plano.leilao, 0, "plano sem a compra")
      b.igual(ns.sessao.comprado[4461], nil, "nada comprado")
    end },
    -- novo scan: o preco novo entra no plano e a compra volta
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(ns.plano.leilao[1].custo, 8 * 170 + 4 * 200, "plano com o preco novo")
      b.igual(CompraForeverAcao:GetText(), "Buy 12 Raptor Hide (21s 60c)", "a compra volta")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
