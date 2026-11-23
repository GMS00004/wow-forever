-- rota-22 (CONTRATO 12.5, progresso do craft): o servidor faz um craft so por pedido (craft_lote = "um"), mesmo pedindo 20. O
-- progresso se mede pela queda do po (1 craft), nao pelos 20 pedidos: o contador grava 1, o botao fica desligado enquanto a
-- pendencia vive e volta, com a quantidade certa, quando ela termina; nada e craftado sozinho.
local B = __bancada
return {
  id = "rota-22", grupo = "rota",
  descricao = "servidor faz um craft so por pedido: progresso e botao continuam certos",
  inicio = B.fixture("eng150", {
    parametros = { craft_lote = "um" },
    profissoes = { { id = 202, nome = "Engineering", nivel = 40, max = 75 } },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4357, qtd = 20 }, { bolsa = 0, slot = 2, itemID = 4357, qtd = 20 },
      { bolsa = 0, slot = 3, itemID = 4357, qtd = 20 }, { bolsa = 0, slot = 4, itemID = 4357, qtd = 18 },
      { bolsa = 0, slot = 5, itemID = 2589, qtd = 20 }, { bolsa = 0, slot = 6, itemID = 2589, qtd = 20 },
      { bolsa = 0, slot = 7, itemID = 2589, qtd = 20 }, { bolsa = 0, slot = 8, itemID = 2589, qtd = 18 },
    },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 40, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { chamar = function(b) CreateFrame("Frame", "ProfessionsFrame", UIParent) end },
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Craft 20 Rough Dynamite", "lote de 20")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 2 },
    { chamar = function(b)
      b.igual(b.chamadas("CraftRecipe")[1].args, { 3919, 20, n = 2 }, "o pedido foi de 20")
      b.igual(C_Item.GetItemCount(4358), 2, "o servidor fez um so (2 Rough Dynamite)")
      b.igual(C_Item.GetItemCount(4357), 77, "um po consumido")
      b.igual(CompraForeverCharDB.rota.engineering.craftado[3919], 1, "progresso: 1 craft, nao 20")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado enquanto a pendencia vive")
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 1, "nenhum pedido novo sozinho")
      b.igual(CompraForeverCharDB.rota.engineering.craftado[3919], 1, "contador segue em 1")
      b.igual(CompraForeverCharDB.rota.engineering.credito[4358], 2, "credito: 2 Rough Dynamite")
      b.igual(CompraForeverAcao:GetText(), "Craft 20 Rough Dynamite", "o botao volta com o lote certo")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    -- o dono clica de novo: mais um, e a conta continua
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 2, "segundo pedido, do dono")
      b.igual(C_Item.GetItemCount(4358), 4, "4 Rough Dynamite")
      b.igual(CompraForeverCharDB.rota.engineering.craftado[3919], 2, "contador: 2")
      b.igual(CompraForeverCharDB.rota.engineering.credito[4358], 4, "credito: 4")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
  end,
}
