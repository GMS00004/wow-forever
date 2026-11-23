-- rota-16 (CONTRATO 12.4 passo 7 e 12.5): a venda ao vendedor so leva o que o addon craftou e ainda nao vendeu (credito),
-- menos o que os passos seguintes pedem; nunca a ferramenta, o objeto, a materia-prima nem o que o dono ja tinha.
--   Rough Dynamite (40 creditados, 40 na bolsa): vende os 40.
--   Coarse Blasting Powder (60 creditados, 60 na bolsa): os passos 3931 e 3937 pedem mais de 60: nenhum e vendido.
--   Copper Tube (4 creditados, 10 na bolsa em duas pilhas, 6 do dono + 4 craftadas): so a pilha de 4.
--   Martelo e Linen Cloth (credito falso) e Copper Bar (sem credito): ficam.
local B = __bancada
return {
  id = "rota-16", grupo = "rota",
  descricao = "venda guarda o que os passos pedem, a ferramenta, a materia-prima e o que o addon nao craftou",
  inicio = B.fixture("eng150", {
    dinheiro = 1000,
    profissoes = { { id = 202, nome = "Engineering", nivel = 91, max = 150 } },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4358, qtd = 20 }, { bolsa = 0, slot = 2, itemID = 4358, qtd = 20 },
      { bolsa = 0, slot = 3, itemID = 4364, qtd = 20 }, { bolsa = 0, slot = 4, itemID = 4364, qtd = 20 },
      { bolsa = 0, slot = 5, itemID = 4364, qtd = 20 },
      { bolsa = 0, slot = 6, itemID = 4361, qtd = 6 }, { bolsa = 0, slot = 7, itemID = 4361, qtd = 4 },
      { bolsa = 0, slot = 8, itemID = 5956, qtd = 1 }, { bolsa = 0, slot = 9, itemID = 2589, qtd = 20 },
      { bolsa = 0, slot = 10, itemID = 2589, qtd = 20 }, { bolsa = 0, slot = 11, itemID = 2589, qtd = 10 },
      { bolsa = 0, slot = 12, itemID = 2840, qtd = 20 },
    },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 91, max = 150, ids = { [3919] = true, [3931] = true }, n = 2, em = 1 } },
      rota = { engineering = { credito = { [4358] = 40, [4364] = 60, [4361] = 4, [5956] = 1, [2589] = 50 },
        vendido = {}, craftado = {}, gasto = 0, inicio = 1 } } },
  }),
  passos = {
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      local V = b.ns.plano.rota.vender
      b.igual(V[4358], 40, "Rough Dynamite: todo o credito")
      b.igual(V[4361], 4, "Copper Tube: so as 4 craftadas")
      b.igual(V[4364] or 0, 0, "Coarse Blasting Powder: reservado para os passos seguintes")
      b.igual(V[5956], nil, "martelo: nunca")
      b.igual(V[2589], nil, "Linen Cloth: materia-prima, nunca")
      b.igual(V[2840], nil, "Copper Bar: nunca")
      b.verdadeiro((b.ns.plano.rota.reservar[4364] or 0) >= 60, "reservar guarda o Coarse Blasting Powder")
    end },
    { fechar_profissao = true },
    { abrir_vendedor = true },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Sell 44 items (+" .. b.ns.moeda(40 * 30 + 4 * 120) .. ")", "Sell 44 items")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("UseContainerItem"), 3, "tres pilhas: 20 + 20 + a de 4")
      b.igual(GetMoney(), 1000 + 40 * 30 + 4 * 120, "dinheiro")
      b.igual(C_Item.GetItemCount(4358), 0, "Rough Dynamite vendido")
      b.igual(C_Item.GetItemCount(4361), 6, "ficam as 6 Copper Tube do dono")
      b.igual(C_Item.GetItemCount(4364), 60, "Coarse Blasting Powder fica")
      b.igual(C_Item.GetItemCount(5956), 1, "martelo fica")
      b.igual(C_Item.GetItemCount(2589), 50, "Linen Cloth fica")
      b.igual(C_Item.GetItemCount(2840), 20, "Copper Bar fica")
      local c = CompraForeverCharDB.rota.engineering
      b.igual({ c.credito[4358], c.vendido[4358] }, { 0, 40 }, "contadores do Rough Dynamite")
      b.igual({ c.credito[4361], c.vendido[4361] }, { 0, 4 }, "contadores da Copper Tube")
      b.igual({ c.credito[4364], c.credito[5956], c.credito[2589] }, { 60, 1, 50 }, "o resto do credito intacto")
      b.igual(b.ns.plano.rota.vender[4361] or 0, 0, "plano refeito: nada mais a vender da Copper Tube")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
  end,
}
