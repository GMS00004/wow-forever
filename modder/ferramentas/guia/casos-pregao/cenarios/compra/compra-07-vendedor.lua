-- Vendedor: um clique compra a linha do plano (Fine Thread); depois de craftar, um clique vende so os produtos do plano.
-- Nas bolsas: Raptor Hide e Heavy Leather para 2 crafts, um Harness antigo (nao e da sessao) e Light Leather (fora do plano).
return {
  id = "compra-07", grupo = "compra",
  descricao = "vendedor: compra a linha do plano num clique; vende so o craftado na sessao; Harness antigo e Light Leather ficam",
  inicio = {
    dinheiro = 20000,
    itens = {
      [4461] = { nome = "Raptor Hide", vend = 208, pilha = 10 },
      [4234] = { nome = "Heavy Leather", vend = 150, pilha = 20 },
      [2321] = { nome = "Fine Thread", vend = 25, pilha = 20 },
      [2318] = { nome = "Light Leather", vend = 15, pilha = 20 },
      [4455] = { nome = "Raptor Hide Harness", vend = 3096, pilha = 1 },
    },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4461, qtd = 12 },
      { bolsa = 0, slot = 2, itemID = 4234, qtd = 8 },
      { bolsa = 0, slot = 3, itemID = 4455, qtd = 1 },
      { bolsa = 0, slot = 4, itemID = 2318, qtd = 5 },
    },
    receitas = {
      [4096] = { nome = "Raptor Hide Harness", produto = 4455, qtd = 1, reagentes = { { 4461, 6 }, { 4234, 4 }, { 2321, 2 } } },
    },
    vendedor = { { itemID = 2321, preco = 90 } },
    sv_char = { conhecidas = { quem = "Hexumlite", em = 1, ids = { [4096] = true }, n = 1 } },
  },
  passos = {
    -- scan sem anuncios: o plano usa so o estoque e o vendedor
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { fechar_leilao = true },
    { abrir_vendedor = true },
    { chamar = function(b)
      local ns = b.ns
      local p = ns.plano
      b.igual(p.vendedor[1].id, 2321, "plano: Fine Thread no vendedor")
      b.igual(p.vendedor[1].qtd, 4, "plano: 4 Fine Thread")
      b.igual(p.crafts[1].n, 2, "plano: 2 crafts")
      local pt, rel, relPonto, x, y = CompraForeverPainel:GetPoint(1)
      b.igual({ pt, rel == MerchantFrame, relPonto, x, y }, { "TOPLEFT", true, "TOPRIGHT", 4, 0 }, "painel ancorado no vendedor")
      b.verdadeiro(CompraForeverPainel:IsShown(), "painel visivel")
      b.igual(CompraForeverAcao:GetText(), "Buy thread/dye at vendor (3s 60c)", "texto da compra no vendedor")
    end },
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("BuyMerchantItem"), 1, "um BuyMerchantItem")
      b.igual(b.chamadas("BuyMerchantItem")[1].args, { 1, 4, n = 2 }, "indice 1, 4 unidades")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado enquanto compra")
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(C_Item.GetItemCount(2321), 4, "4 Fine Thread nas bolsas")
      b.igual(GetMoney(), 20000 - 360, "dinheiro")
      b.igual(ns.sessao.comprado[2321], 4, "sessao: comprado")
      b.igual(#ns.plano.vendedor, 0, "plano refeito sem a linha do vendedor")
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "nada a vender ainda")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado")
    end },
    -- craftar
    { fechar_vendedor = true },
    { chamar = function(b) CreateFrame("Frame", "ProfessionsFrame", UIParent) end },
    { abrir_profissao = true },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Craft 2 Raptor Hide Harness", "texto do craft")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(C_Item.GetItemCount(4455), 3, "2 craftados mais o antigo")
      b.igual(ns.sessao.craftado[4096], 2, "sessao: 2 craftados")
      b.igual(ns.sessao.principal[4096], true, "receita principal")
    end },
    { fechar_profissao = true },
    -- vender
    { abrir_vendedor = true },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Sell 2 items (+61s 92c)", "texto da venda: so os 2 craftados")
    end },
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("UseContainerItem"), 2, "2 UseContainerItem")
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(GetMoney(), 20000 - 360 + 2 * 3096, "dinheiro depois da venda")
      b.igual(C_Item.GetItemCount(4455), 1, "o Harness antigo continua na bolsa")
      b.igual(C_Item.GetItemCount(2318), 5, "Light Leather (fora do plano) continua")
      b.igual(ns.sessao.vendido[4455], 2, "sessao: vendido")
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "nada mais a vender")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
