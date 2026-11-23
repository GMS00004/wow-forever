-- rota-15 (CONTRATO 12.4 portao "feito" e 12.5): pericia 150/150 com alvo 150: "Done: Engineering 150", nada a comprar
-- (nem linhas de leilao, nem de vendedor), so a venda do que o addon craftou (30 Heavy Dynamite creditados): o Bronze
-- Framework e o martelo que estao na bolsa ficam.
local B = __bancada
return {
  id = "rota-15", grupo = "rota",
  descricao = "alvo atingido: Done, sem compra, so a venda do craftado creditado",
  inicio = B.fixture("eng150", {
    dinheiro = 1000,
    profissoes = { { id = 202, nome = "Engineering", nivel = 150, max = 150 } },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4378, qtd = 20 }, { bolsa = 0, slot = 2, itemID = 4378, qtd = 10 },
      { bolsa = 0, slot = 3, itemID = 4382, qtd = 5 }, { bolsa = 0, slot = 4, itemID = 5956, qtd = 1 },
    },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 150, max = 150, ids = { [3919] = true }, n = 1, em = 1 } },
      rota = { engineering = { credito = { [4378] = 30 }, vendido = {}, craftado = { [3946] = 10 }, gasto = 0, inicio = 1 } } },
  }),
  passos = {
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      local R = ns.plano.rota
      b.igual(R.estado, "feito", "estado feito")
      b.igual(R.proximo, "done", "proximo: done")
      b.igual(ns.plano.motivo, "fim", "motivo: fim")
      b.igual({ #ns.plano.leilao, #ns.plano.vendedor, #ns.plano.crafts }, { 0, 0, 0 }, "nada a comprar nem craftar")
      b.igual(R.vender, { [4378] = 30 }, "so o creditado: 30 Heavy Dynamite")
      b.igual(CompraForeverAcao:GetText(), "Done: Engineering 150", "texto do botao")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 3 },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 0, "nenhum craft")
      b.igual(b.contar("UseContainerItem"), 0, "nada vendido sem o vendedor")
    end },
    { fechar_profissao = true },
    { abrir_vendedor = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(CompraForeverAcao:GetText(), "Sell 30 items (+" .. ns.moeda(30 * 350) .. ")", "venda: so os 30 creditados")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("UseContainerItem"), 2, "duas pilhas vendidas")
      b.igual(b.contar("BuyMerchantItem"), 0, "nenhuma compra no vendedor")
      b.igual(GetMoney(), 1000 + 30 * 350, "dinheiro")
      b.igual(C_Item.GetItemCount(4378), 0, "Heavy Dynamite vendido")
      b.igual(C_Item.GetItemCount(4382), 5, "o Bronze Framework (nao craftado pelo addon) ficou")
      b.igual(C_Item.GetItemCount(5956), 1, "o martelo ficou")
      local c = CompraForeverCharDB.rota.engineering
      b.igual({ c.credito[4378], c.vendido[4378] }, { 0, 30 }, "contadores: credito 0, vendido 30")
      b.igual(CompraForeverAcao:GetText(), "DONE: Engineering 150", "nada mais a vender: o botao mostra o DONE")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado")
    end },
    { fechar_vendedor = true },
    { abrir_leilao = true },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "DONE: Engineering 150", "no leilao: sem acao, o botao mostra o DONE")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado no leilao")
      for _, n in ipairs({ "StartCommoditiesPurchase", "ConfirmCommoditiesPurchase", "PlaceBid", "SendSearchQuery", "SendBrowseQuery" }) do
        b.igual(b.contar(n), 0, "nenhum " .. n)
      end
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
  end,
}
