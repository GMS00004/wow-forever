-- Ferramenta da rota (CONTRATO 12.4, passo 6; 12.5 vendedor): o Blacksmith Hammer (5956, 18 no vendedor, 16 com o desconto de 10%) entra
-- como linha de vendedor do passo 2 (Rough Copper Bomb) uma vez so; comprado, a linha some e nada mais e comprado; qualquer um dos
-- itens da ferramenta na bolsa (aqui o 260811) tambem dispensa a compra. O gasto do vendedor soma em rota[slug].gasto.
return {
  id = "rota-09", grupo = "rota",
  descricao = "martelo no vendedor uma vez so (BuyMerchantItem 1x), gasto gravado; ja na bolsa (ou outro item da ferramenta) nao compra",
  inicio = __bancada.fixture("eng150", {
    itens = { [260811] = { nome = "Arclight Spanner Hammer", vend = 3, pilha = 1 } },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { fechar_leilao = true },
    { abrir_vendedor = true },
    { chamar = function(b)
      local ns = b.ns
      local p = ns.plano
      b.igual(#p.vendedor, 1, "uma linha de vendedor")
      b.igual(p.vendedor[1], { id = 5956, nome = "Blacksmith Hammer", qtd = 1, custo = 16, tipo = "ferramenta", passo = 2 }, "o martelo")
      b.igual(p.rota.proximo, "ah", "as linhas de leilao vem antes do vendedor no NEXT")
      -- o vendedor e o contexto: vender antes de comprar, mas nao ha o que vender
      b.igual(CompraForeverAcao:GetText(), "Buy at vendor (16c)", "texto da compra no vendedor")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
      b.igual(b.contar("BuyMerchantItem"), 0, "nada comprado ainda")
    end },
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("BuyMerchantItem"), 1, "um BuyMerchantItem")
      b.igual(b.chamadas("BuyMerchantItem")[1].args, { 1, 1, n = 2 }, "indice 1, 1 unidade")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado enquanto compra")
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(C_Item.GetItemCount(5956), 1, "o martelo esta na bolsa")
      b.igual(GetMoney(), 500000 - 18, "o vendedor cobra o preco de tabela (18)")
      b.igual(ns.sessao.comprado[5956], 1, "sessao: comprado")
      b.igual(CompraForeverCharDB.rota.engineering.gasto, 16, "gasto da rota: o do plano (16)")
      b.igual(#ns.plano.vendedor, 0, "o plano refeito nao tem o martelo")
      -- sem acao possivel onde o dono esta, o botao mostra o NEXT, desligado (12.7)
      b.igual(CompraForeverAcao:GetText(), "NEXT: AH", "sem acao no vendedor: o botao mostra o NEXT")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado")
      b.igual(ns.plano.rota.vender, {}, "o martelo nao entra na venda")
    end },
    -- mais um clique (o dono insiste): nada e comprado de novo
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("BuyMerchantItem"), 1, "continua um BuyMerchantItem")
      b.igual(C_Item.GetItemCount(5956), 1, "continua um martelo")
    end },
    -- sem o 5956, mas com o 260811 (outro item da mesma ferramenta): ainda nao compra
    { injetar = { "bolsa_trocada", 0, 1, false } },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(5956), 0, "martelo saiu da bolsa")
    end },
    { injetar = { "bolsa_trocada", 0, 2, 260811, 1 } },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      ns.replanejar()
      b.igual(#ns.plano.vendedor, 0, "com o 260811 na bolsa nao ha linha de vendedor")
      b.igual(CompraForeverAcao:GetText(), "NEXT: AH", "nada a comprar no vendedor")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado")
      b.igual(b.contar("BuyMerchantItem"), 1, "continua um BuyMerchantItem")
    end },
    -- e sem nenhum dos dois, o martelo volta ao plano (uma linha so)
    { injetar = { "bolsa_trocada", 0, 2, false } },
    { chamar = function(b)
      local ns = b.ns
      ns.replanejar()
      b.igual(#ns.plano.vendedor, 1, "sem nenhum martelo a linha volta")
      b.igual(ns.plano.vendedor[1].id, 5956, "martelo")
      b.igual(ns.plano.vendedor[1].qtd, 1, "uma unidade so")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
  end,
}
