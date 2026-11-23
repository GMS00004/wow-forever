-- rota-20 (CONTRATO 12.5): a bolsa enche no meio do craft (tamanho_bolsa = 1: 5 espacos, 4 ocupados, sobra 1 espaco de 20
-- Rough Dynamite = 10 crafts). O servidor responde "Inventory is full" no 11o craft: a pendencia termina, o botao volta com a
-- mensagem e o texto do craft, e o addon nao tenta de novo sozinho; o progresso dos 10 crafts conta.
local B = __bancada
return {
  id = "rota-20", grupo = "rota",
  descricao = "bolsa enche no meio do craft: botao volta com a mensagem, sem tentar de novo sozinho",
  inicio = B.fixture("eng150", {
    parametros = { tamanho_bolsa = 1 },
    profissoes = { { id = 202, nome = "Engineering", nivel = 40, max = 75 } },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4357, qtd = 20 }, { bolsa = 1, slot = 1, itemID = 2589, qtd = 20 },
      { bolsa = 2, slot = 1, itemID = 2319, qtd = 1 }, { bolsa = 3, slot = 1, itemID = 2592, qtd = 1 },
    },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 40, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.ns.espacosLivres(), 1, "um espaco livre")
      b.igual(CompraForeverAcao:GetText(), "Craft 20 Rough Dynamite", "lote de 20")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 1, "um CraftRecipe")
      b.igual(C_Item.GetItemCount(4358), 20, "so 10 crafts coubam: 20 Rough Dynamite")
      b.igual(C_Item.GetItemCount(4357), 10, "10 de po sobram")
      b.igual(#b.eventos("UI_ERROR_MESSAGE"), 1, "o servidor avisou uma vez")
      b.igual(b.ns.mensagem(), "Inventory is full", "a mensagem do servidor fica no painel")
      b.igual(CompraForeverCharDB.rota.engineering.craftado[3919], 10, "contador: 10 crafts")
      b.igual(CompraForeverAcao:GetText(), "Craft 10 Rough Dynamite", "o botao volta com o craft que cabe nos materiais")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado de novo")
    end },
    -- nao tenta de novo sozinho
    { avancar = 60 },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 1, "ainda um CraftRecipe: nada de nova tentativa sozinho")
      b.igual(C_Item.GetItemCount(4358), 20, "nada mudou nas bolsas")
      b.igual(b.ns.mensagem(), "Inventory is full", "mensagem segue ate a proxima acao")
    end },
    -- o dono libera um espaco (joga fora o Wool) e clica de novo: o craft sai e a mensagem some
    { injetar = { "bolsa_trocada", 3, 1, nil, nil } },
    { chamar = function(b) b.igual(b.ns.espacosLivres(), 1, "o dono liberou um espaco (so o Wool saiu: o do Rough Dynamite cheio ficou)") end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 2, "o clique do dono fez o segundo CraftRecipe")
      b.igual(b.chamadas("CraftRecipe")[2].args, { 3919, 10, n = 2 }, "10 vezes")
      b.igual(C_Item.GetItemCount(4358), 40, "40 Rough Dynamite")
      b.igual(b.ns.mensagem(), nil, "mensagem limpa")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
  end,
}
