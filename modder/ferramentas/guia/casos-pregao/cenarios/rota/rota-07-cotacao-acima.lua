-- Cotacao acima do limite da rota (CONTRATO 12.5): limite = min(qtd * teto, floor(custo * 1.05) + 1), com teto = floor(27 * 110 / 100) = 29
-- (Linen Cloth). O mercado do Linen e 200 unidades a 29 (o proprio limite): a linha planejada e 141 x 29 = 4089, e o limite da rota
-- e min(141 * 29 = 4089, 4294) = 4089. Depois do scan o mercado muda para 140 a 29 e 100 a 30: a cotacao de 141 e 140 * 29 + 30 = 4090,
-- 1 acima do limite da rota. A formula do lucro (floor(custo * 1.02) + 1 + lucro / 2 = 4171) aceitaria. A rota cancela, nao confirma,
-- busca so o item de novo e refaz o plano com o degrau de 30 fora do teto (so 140 unidades ate 29). Depois a cotacao de 140 a 29 (4060 =
-- o limite novo, 140 * 29) e aceita e confirmada.
return {
  id = "rota-07", grupo = "rota",
  descricao = "cotacao 1 acima do limite da rota (que o do lucro aceitaria): cancela, nao confirma, rebusca o item, replaneja; depois a cotacao dentro do limite confirma",
  inicio = __bancada.fixture("eng150", {
    mercado = { [2589] = { { preco = 29, qtd = 200 } } },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      local l = ns.plano.leilao[1]
      b.igual({ l.id, l.qtd, l.custo, l.teto, l.precoMax }, { 2589, 141, 141 * 29, 29, 29 }, "linha planejada: 141 Linen a 29, teto 29")
      b.igual(CompraForeverAcao:GetText(), "Buy 141 Linen Cloth (40s 89c)", "texto antes da cotacao")
      -- o mercado muda depois do scan: 140 a 29 e 100 a 30
      __bancada.A.mercado[2589] = { { id = 9001, preco = 29, qtd = 140, donos = 1 }, { id = 9002, preco = 30, qtd = 100, donos = 1 } }
      b.igual(ns.plano.leilao[1].custo * 1.05 > 4090, true, "o limite de 5% sozinho aceitaria 4090")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "um Start")
      b.igual(b.chamadas("StartCommoditiesPurchase")[1].args[2], 141, "Start de 141")
      b.igual(b.contar("CancelCommoditiesPurchase"), 1, "cotacao cancelada")
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 0, "nunca confirmou")
      b.igual(GetMoney(), 500000, "dinheiro intacto")
      b.igual(b.ns.sessao.comprado[2589], nil, "nada comprado")
      b.igual(CompraForeverCharDB.correio[2589], nil, "nada no correio gravado")
      b.igual((CompraForeverCharDB.rota.engineering or {}).gasto or 0, 0, "gasto da rota zero")
    end },
    -- rebusca so o Linen e refaz o plano
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("SendSearchQuery"), 13, "12 do scan + a rebusca do Linen")
      local ultima = b.chamadas("SendSearchQuery")[13]
      b.igual(ultima.args[1].itemID, 2589, "a rebusca e do Linen Cloth")
      local linha
      for _, l in ipairs(ns.plano.leilao) do if l.id == 2589 then linha = l end end
      b.verdadeiro(linha ~= nil, "linha do Linen no plano novo")
      b.igual({ linha.qtd, linha.custo, linha.teto }, { 140, 140 * 29, 29 }, "plano novo: so 140 ate o teto 29 (o degrau de 30 fica de fora)")
      b.igual(ns.plano.rota.curtos[1].id, 2589, "o Linen fica curto no passo seguinte")
      b.igual(ns.plano.rota.curtos[1].tipo, "preco", "curto por preco")
      b.igual(ns.plano.rota.curtos[1].cap, 29, "cap 29")
      b.igual(ns.plano.motivo, "preco", "motivo do plano: preco")
      b.igual(CompraForeverAcao:GetText(), "Buy 140 Linen Cloth (40s 60c)", "o botao volta com a quantidade e o preco novos")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    -- agora a cotacao (4060) cabe no limite novo (140 * 29)
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 2, "segundo Start")
      b.igual(b.chamadas("StartCommoditiesPurchase")[2].args[2], 140, "Start de 140")
      b.igual(b.contar("CancelCommoditiesPurchase"), 1, "nenhum cancelamento novo")
      b.igual(CompraForeverAcao:GetText(), "Confirm 140 Linen Cloth (40s 60c)", "aceita: texto de confirmar")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 1, "um Confirm")
      b.igual(GetMoney(), 500000 - 4060, "dinheiro")
      b.igual(CompraForeverCharDB.correio[2589], 140, "correio gravado")
      b.igual(CompraForeverCharDB.rota.engineering.gasto, 4060, "gasto da rota")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
  end,
}
