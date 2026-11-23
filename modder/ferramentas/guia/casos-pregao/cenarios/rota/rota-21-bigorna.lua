-- rota-21 (CONTRATO 12.5): Rough Copper Bomb pede a Anvil por perto (GetRecipeRequirements com met = false): longe, o botao
-- mostra "Need Anvil nearby", desligado, e nenhum CraftRecipe sai; perto, o craft sai e o servidor nao reclama.
local B = __bancada
return {
  id = "rota-21", grupo = "rota",
  descricao = "bigorna: Need Anvil nearby longe; perto, crafta",
  inicio = B.fixture("eng150", {
    perto = {},
    profissoes = { { id = 202, nome = "Engineering", nivel = 59, max = 75 } },
    receitas = { [3923] = { aprendida = true } },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 2840, qtd = 20 }, { bolsa = 0, slot = 2, itemID = 4359, qtd = 20 },
      { bolsa = 0, slot = 3, itemID = 4357, qtd = 20 }, { bolsa = 0, slot = 4, itemID = 4357, qtd = 20 },
      { bolsa = 0, slot = 5, itemID = 2589, qtd = 20 }, { bolsa = 0, slot = 6, itemID = 5956, qtd = 1 },
    },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 59, max = 75, ids = { [3919] = true, [3923] = true }, n = 2, em = 1 } } },
  }),
  passos = {
    -- a janela da profissao existe: o painel fica na tela e o relogio dele (OnUpdate) refresca o botao
    { chamar = function(b) CreateFrame("Frame", "ProfessionsFrame", UIParent) end },
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      local R = b.ns.plano.rota
      b.igual(R.atual.magia, 3923, "passo atual: Rough Copper Bomb")
      b.igual(R.dicas[1], "ANVIL", "dica ANVIL no plano")
      b.igual(C_TradeSkillUI.GetRecipeRequirements(3923), { { name = "Anvil", met = false } }, "o jogo diz: longe da bigorna")
      b.igual(b.ns.proximaAcao().texto, "Need Anvil nearby", "texto da acao")
      b.igual(CompraForeverAcao:GetText(), "Need Anvil nearby", "texto do botao")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 5 },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 0, "longe da bigorna: nenhum CraftRecipe")
      b.igual(#b.eventos("UI_ERROR_MESSAGE"), 0, "e o servidor nao precisou reclamar")
    end },
    -- o dono chega perto da bigorna
    { chamar = function(b) B.ROTA.perto.Anvil = true end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Craft 7 Rough Copper Bomb", "perto: o craft")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 1, "um CraftRecipe")
      b.igual(b.chamadas("CraftRecipe")[1].args, { 3923, 7, n = 2 }, "3923 sete vezes")
      b.igual(C_Item.GetItemCount(4360), 14, "14 Rough Copper Bomb")
      b.igual(#b.eventos("UI_ERROR_MESSAGE"), 0, "sem erro do servidor")
      b.igual(CompraForeverCharDB.rota.engineering.craftado[3923], 7, "contador: 7 crafts")
    end },
    -- vai embora: o texto volta
    { chamar = function(b) B.ROTA.perto.Anvil = false end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Need Anvil nearby", "longe de novo: Need Anvil nearby")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado de novo")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
  end,
}
