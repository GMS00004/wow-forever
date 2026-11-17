-- Compra de commodity em dois cliques: cotar (Start) e confirmar (Confirm); o botao muda de texto entre eles.
-- Receita 4096 com estoque de 4234 (8) e 2321 (4) nas bolsas: so o Raptor Hide (commodity) vem do leilao.
return {
  id = "compra-04", grupo = "compra",
  descricao = "commodity: clique 1 cota, texto vira Confirm, clique 2 confirma; dinheiro, correio e plano refeito",
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
    { chamar = function(b)
      b.falso(CompraForeverAcao:IsEnabled(), "sem scan o botao de acao fica desabilitado")
    end },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      local p = ns.plano
      b.verdadeiro(p ~= nil and p.leilao[1] ~= nil, "plano com a compra de Raptor Hide")
      ns.planoAntes = p
      b.igual(p.leilao[1].qtd, 12, "12 Raptor Hide no plano")
      b.igual(p.leilao[1].custo, 1680, "custo planejado 8 x 130 + 4 x 160")
      local a = ns.proximaAcao()
      b.igual(a.texto, "Buy 12 Raptor Hide (16s 80c)", "texto antes da cotacao")
      b.igual(CompraForeverAcao:GetText(), "Buy 12 Raptor Hide (16s 80c)", "texto do botao")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "um Start")
      b.igual(b.chamadas("StartCommoditiesPurchase")[1].args[1], 4461, "Start do id 4461")
      b.igual(b.chamadas("StartCommoditiesPurchase")[1].args[2], 12, "Start de 12")
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 0, "nada confirmado no clique 1")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado enquanto cota")
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Confirm 12 Raptor Hide (16s 80c)", "o texto vira Confirm")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado para confirmar")
      b.igual(GetMoney(), 51400, "nada pago ainda")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 1, "um Confirm")
      b.igual(b.chamadas("ConfirmCommoditiesPurchase")[1].args[2], 12, "Confirm de 12")
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "ainda um Start")
      b.igual(GetMoney(), 51400 - 1680, "dinheiro")
      b.igual(C_Item.GetItemCount(4461), 0, "o leilao entrega pelo correio: nada nas bolsas ainda")
      b.igual(ns.espacosLivres(), 78, "bolsas livres iguais")
      b.igual(ns.estoque(4461), 12, "estoque conta o comprado a caminho")
      b.igual(ns.sessao.comprado[4461], 12, "sessao: comprado")
      b.verdadeiro(ns.plano ~= ns.planoAntes, "plano refeito")
      b.igual(#ns.plano.leilao, 0, "nada mais a comprar")
      b.igual(ns.plano.crafts[1].n, 2, "ainda 2 crafts, agora com o estoque")
      b.igual(ns.scan.escadas[4461], { { preco = 160, qtd = 96, leilao = 1002, inteiro = false } }, "escada consumida do degrau mais barato")
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "sem acao no leilao")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado")
    end },
    -- o correio entrega: o estoque nao conta em dobro
    { injetar = { "bolsa_trocada", 0, 3, 4461, 10 } },
    { injetar = { "bolsa_trocada", 0, 4, 4461, 2 } },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(4461), 12, "12 nas bolsas")
      b.igual(b.ns.estoque(4461), 12, "estoque sem contar em dobro")
      b.igual(b.ns.sessao.correio[4461], nil, "nada mais a caminho")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
