-- rota-12 (CONTRATO 12.5 e 12.7): o passo atual pede uma receita que o personagem nao aprendeu (Rough Copper Bomb, treinador
-- por 130 cobre): "Train Rough Copper Bomb (<custo>)", dica TRAIN, botao desligado, nenhum CraftRecipe e nenhum
-- BuyTrainerService. O dono treina no treinador (o falso so le); depois disso o craft sai.
local B = __bancada
return {
  id = "rota-12", grupo = "rota",
  descricao = "receita nao conhecida: Train <receita> (<custo>), nenhum craft; depois de treinar, Craft",
  inicio = B.fixture("eng150", {
    profissoes = { { id = 202, nome = "Engineering", nivel = 59, max = 75 } },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 2840, qtd = 20 }, { bolsa = 0, slot = 2, itemID = 4359, qtd = 20 },
      { bolsa = 0, slot = 3, itemID = 4357, qtd = 20 }, { bolsa = 0, slot = 4, itemID = 4357, qtd = 20 },
      { bolsa = 0, slot = 5, itemID = 2589, qtd = 20 }, { bolsa = 0, slot = 6, itemID = 5956, qtd = 1 },
    },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 59, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      local R = ns.plano.rota
      b.igual(R.estado, "ok", "rota ok")
      b.igual(R.atual.magia, 3923, "passo atual: Rough Copper Bomb")
      b.igual(R.treinar[1].magia, 3923, "plano: a primeira a treinar e a do passo atual")
      b.igual(R.treinar[1].custo, 130, "custo do treino")
      b.igual(R.proximo, "trainer", "proximo: treinador")
      local txt = "Train Rough Copper Bomb (" .. ns.moeda(130) .. ")"
      b.igual(ns.proximaAcao().texto, txt, "texto da acao")
      b.igual(CompraForeverAcao:GetText(), txt, "texto do botao")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado: o addon nao treina")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 5 },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 0, "nenhum CraftRecipe com a receita nao conhecida")
      b.igual(C_Item.GetItemCount(4360), 0, "nada craftado")
    end },
    -- o treinador: o painel aparece com as dicas, o botao so mostra o NEXT
    { fechar_profissao = true },
    { abrir_treinador = true },
    { chamar = function(b)
      b.verdadeiro(CompraForeverPainel:IsShown(), "painel visivel no treinador")
      local _, rel = CompraForeverPainel:GetPoint(1)
      b.verdadeiro(rel == ClassTrainerFrame, "painel ancorado no treinador")
      b.falso(CompraForeverAcao:IsEnabled(), "sem acao possivel no treinador")
    end },
    { treinar = { magia = 3923 } },
    { fechar_treinador = true },
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(ns.plano.rota.treinar[1].magia, 3924, "a Rough Copper Bomb saiu da lista de treino (a primeira agora e a Copper Tube)")
      b.igual(ns.plano.rota.atual.magia, 3923, "continua no Rough Copper Bomb")
      b.igual(CompraForeverAcao:GetText(), "Craft 7 Rough Copper Bomb", "agora o craft")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 1, "um CraftRecipe")
      b.igual(b.chamadas("CraftRecipe")[1].args, { 3923, 7, n = 2 }, "3923 sete vezes")
      b.igual(C_Item.GetItemCount(4360), 14, "14 Rough Copper Bomb")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
  end,
}
