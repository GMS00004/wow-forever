-- Craftar: com a profissao aberta, primeiro o intermediario de `fabricar` (Heavy Leather a partir de Medium Leather) e
-- depois a receita principal, cada uma na quantidade que os reagentes das bolsas permitem.
return {
  id = "compra-08", grupo = "compra",
  descricao = "craftar: um clique faz a receita de fabricar (4x), o seguinte faz a principal (1x); sessao e plano acompanham",
  inicio = {
    dinheiro = 20000,
    itens = {
      [4461] = { nome = "Raptor Hide", vend = 208, pilha = 10 },
      [4234] = { nome = "Heavy Leather", vend = 150, pilha = 20 },
      [2319] = { nome = "Medium Leather", vend = 60, pilha = 20 },
      [2321] = { nome = "Fine Thread", vend = 25, pilha = 20 },
      [4455] = { nome = "Raptor Hide Harness", vend = 3096, pilha = 1 },
    },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4461, qtd = 6 },
      { bolsa = 0, slot = 2, itemID = 2319, qtd = 22 },
      { bolsa = 0, slot = 3, itemID = 2321, qtd = 2 },
    },
    receitas = {
      [4096] = { nome = "Raptor Hide Harness", produto = 4455, qtd = 1, reagentes = { { 4461, 6 }, { 4234, 4 }, { 2321, 2 } } },
      [20649] = { nome = "Heavy Leather", produto = 4234, qtd = 1, reagentes = { { 2319, 5 } } },
    },
    sv_char = { conhecidas = { quem = "Hexumlite", em = 1, ids = { [4096] = true, [20649] = true }, n = 2 } },
  },
  passos = {
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { fechar_leilao = true },
    { chamar = function(b) CreateFrame("Frame", "ProfessionsFrame", UIParent) end },
    { abrir_profissao = true },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      local p = ns.plano
      b.verdadeiro(p ~= nil and p.fabricar[1] ~= nil, "plano tem fabricar")
      b.igual(p.fabricar[1].magia, 20649, "fabricar Heavy Leather")
      b.igual(p.fabricar[1].n, 4, "4 casts")
      b.igual(p.crafts[1].n, 1, "1 craft principal")
      local pt, rel, relPonto, x, y = CompraForeverPainel:GetPoint(1)
      b.igual({ pt, rel == ProfessionsFrame, relPonto, x, y }, { "TOPLEFT", true, "TOPRIGHT", 4, 0 }, "painel ancorado na profissao")
      b.igual(CompraForeverAcao:GetText(), "Craft 4 Heavy Leather", "primeiro o intermediario")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 1, "um CraftRecipe")
      b.igual(b.chamadas("CraftRecipe")[1].args, { 20649, 4, n = 2 }, "magia 20649, 4 vezes")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado enquanto crafta")
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(C_Item.GetItemCount(4234), 4, "4 Heavy Leather")
      b.igual(C_Item.GetItemCount(2319), 2, "sobram 2 Medium Leather")
      b.igual(ns.sessao.craftado[20649], 4, "sessao: 4 casts")
      b.igual(ns.sessao.principal[20649], nil, "intermediario nao e produto de venda")
      b.igual(#ns.plano.fabricar, 0, "plano refeito sem fabricar")
      b.igual(CompraForeverAcao:GetText(), "Craft 1 Raptor Hide Harness", "agora a receita principal")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("CraftRecipe"), 2, "dois CraftRecipe no total")
      b.igual(b.chamadas("CraftRecipe")[2].args, { 4096, 1, n = 2 }, "magia 4096, 1 vez")
      b.igual(C_Item.GetItemCount(4455), 1, "1 Harness")
      b.igual(C_Item.GetItemCount(4461), 0, "Raptor Hide consumido")
      b.igual(C_Item.GetItemCount(4234), 0, "Heavy Leather consumido")
      b.igual(ns.sessao.craftado[4096], 1, "sessao: 1 craft")
      b.igual(ns.sessao.principal[4096], true, "principal")
      b.falso(CompraForeverAcao:IsEnabled(), "nada mais a craftar")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
