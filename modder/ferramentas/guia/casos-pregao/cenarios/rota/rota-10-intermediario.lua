-- rota-10 (CONTRATO 12.5, craft na rota): o intermediario (Heavy Blasting Powder, fonte F) vem antes do principal (Heavy
-- Dynamite), so na quantidade que o lote de 20 pede (40 po), nao no que a bolsa permite (60 Heavy Stone).
local B = __bancada
return {
  id = "rota-10", grupo = "rota",
  descricao = "craft: Make 40 Heavy Blasting Powder antes de Craft 20 Heavy Dynamite; so o que o lote pede",
  inicio = B.fixture("eng150", {
    profissoes = { { id = 202, nome = "Engineering", nivel = 125, max = 150 } },
    receitas = { [3945] = { aprendida = true }, [3946] = { aprendida = true } },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 2838, qtd = 20 }, { bolsa = 0, slot = 2, itemID = 2838, qtd = 20 },
      { bolsa = 0, slot = 3, itemID = 2838, qtd = 20 }, { bolsa = 0, slot = 4, itemID = 2592, qtd = 20 },
    },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 125, max = 150, ids = { [3919] = true, [3945] = true, [3946] = true }, n = 3, em = 1 } } },
  }),
  passos = {
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      local R = b.ns.plano.rota
      b.igual(R.estado, "ok", "rota ok")
      b.igual(R.atual.magia, 3946, "passo atual: Heavy Dynamite")
      b.igual(R.atual.de, 125, "passo de 125")
      b.verdadeiro(R.atual.faltam >= 20, "faltam ao menos 20 crafts")
      b.igual(b.ns.proximaAcao().texto, "Make 40 Heavy Blasting Powder", "primeiro o intermediario, so os 40 que o lote pede")
      b.igual(CompraForeverAcao:GetText(), "Make 40 Heavy Blasting Powder", "texto do botao")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 1, "um CraftRecipe")
      b.igual(b.chamadas("CraftRecipe")[1].args, { 3945, 40, n = 2 }, "o intermediario primeiro: 40 vezes")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado enquanto crafta")
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(4377), 40, "40 Heavy Blasting Powder")
      b.igual(C_Item.GetItemCount(2838), 20, "sobram 20 Heavy Stone (nao fez po demais)")
      b.igual(b.ns.proximaAcao().texto, "Craft 20 Heavy Dynamite", "agora o principal")
      b.igual(CompraForeverAcao:GetText(), "Craft 20 Heavy Dynamite", "texto do botao")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 2, "dois CraftRecipe")
      b.igual(b.chamadas("CraftRecipe")[2].args, { 3946, 20, n = 2 }, "o principal: 20 vezes")
      b.igual(C_Item.GetItemCount(4378), 60, "60 Heavy Dynamite")
      b.igual(C_Item.GetItemCount(4377), 0, "po consumido")
      b.igual(C_Item.GetItemCount(2592), 0, "Wool Cloth consumido")
      local c = CompraForeverCharDB.rota.engineering
      b.igual(c.craftado[3945], 40, "contador: 40 do intermediario")
      b.igual(c.craftado[3946], 20, "contador: 20 do principal")
      b.igual(c.credito[4378], 60, "credito de venda do Heavy Dynamite")
      b.igual(#B.C.subidas, 0, "a pericia nao mexeu (modo nunca)")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
  end,
}
