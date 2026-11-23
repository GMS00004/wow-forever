-- rota-13 (CONTRATO 12.4 passo 3 e 12.5): perícia no teto do rank (75/75): "<rank> needs level <n>" enquanto o nivel nao
-- chega; depois "Train Journeyman Engineering (<custo>)" e dica TRAIN; treinado, o craft sai. No alvo 225, com o 150/150,
-- o Expert pede nivel 20. O falso so le o treinador: o dono treina (treinar_rank).
local B = __bancada

local f = B.fixture("eng150", {
  nivel = 5,
  profissoes = { { id = 202, nome = "Engineering", nivel = 75, max = 75 } },
  receitas = { [3929] = { aprendida = true }, [3953] = { aprendida = true } },
  bolsas = {
    { bolsa = 0, slot = 1, itemID = 2836, qtd = 20 }, { bolsa = 0, slot = 2, itemID = 2841, qtd = 20 },
    { bolsa = 0, slot = 3, itemID = 2841, qtd = 20 }, { bolsa = 0, slot = 4, itemID = 2319, qtd = 20 },
    { bolsa = 0, slot = 5, itemID = 2592, qtd = 20 },
  },
  sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
    prof = { engineering = { pericia = 75, max = 75, ids = { [3919] = true, [3929] = true, [3953] = true }, n = 3, em = 1 } } },
})
-- trecho 150-225 so com o passo que o cenario usa (a fixture tem so o 1-150); o cinza do Bronze Framework sobe a 260 para a
-- receita render ate o 225
f.dados.rotas.profs.engineering.receitas[3953].cinza = 260
f.dados.rotas.profs.engineering.trechos[2] = {
  de = 150, ate = 225, chegou = 225, fontes = {}, totais = { custo = 0, crafts = 60, craftsExtra = 0 },
  passos = { { magia = 3953, de = 150, ate = 225, crafts = 60 } },
}

return {
  id = "rota-13", grupo = "rota",
  descricao = "teto do rank: needs level, Train Journeyman, dica TRAIN, depois craft; Expert pede nivel 20",
  inicio = f,
  passos = {
    -- nivel 5: o Journeyman pede 10
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      local R = ns.plano.rota
      b.igual(R.limite, 75, "limite 75: o nivel 5 so deixa o Apprentice")
      b.igual({ R.rank.nome, R.rank.custo, R.rank.pericia, R.rank.nivel, R.rank.cap, R.rank.bloqueado },
        { "Journeyman Engineering", 500, 50, 10, 150, true }, "rank bloqueado pelo nivel")
      b.igual(R.proximo, "trainer", "proximo: treinador")
      b.igual(CompraForeverAcao:GetText(), "Journeyman Engineering needs level 10", "texto: nivel exigido")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 3 },
    { chamar = function(b) b.igual(b.contar("CraftRecipe"), 0, "nenhum CraftRecipe") end },
    -- o dono tenta treinar sem o nivel: o falso recusa e a pericia nao muda
    { fechar_profissao = true },
    { abrir_treinador = true },
    { treinar_rank = 150 },
    { fechar_treinador = true },
    { chamar = function(b)
      b.igual(#B.C.recusas, 1, "o treinador recusou o Journeyman no nivel 5")
      B.ROTA.nivel = 10
    end },
    -- nivel 10: pode treinar
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(ns.plano.rota.rank.bloqueado, false, "rank liberado no nivel 10")
      b.igual(ns.plano.rota.limite, 150, "limite 150 (o teto do rank vem do max, nao do nivel)")
      local txt = "Train Journeyman Engineering (" .. ns.moeda(500) .. ")"
      b.igual(CompraForeverAcao:GetText(), txt, "texto: treinar o rank")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado: o addon nao treina")
    end },
    { fechar_profissao = true },
    { abrir_treinador = true },
    { treinar_rank = 150 },
    { fechar_treinador = true },
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(CompraForeverCharDB.prof.engineering.max, 150, "max gravado: 150")
      b.igual(ns.plano.rota.atual.magia, 3929, "passo atual: Coarse Blasting Powder")
      b.igual(CompraForeverAcao:GetText(), "Craft 19 Coarse Blasting Powder", "treinado, o craft sai")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 1, "um CraftRecipe")
      b.igual(b.chamadas("CraftRecipe")[1].args[1], 3929, "a magia do passo")
    end },
    -- alvo 225, 150/150, nivel 10: o Expert pede nivel 20
    { fechar_profissao = true },
    { chamar = function(b)
      B.ROTA.profs[1].nivel = 150
      b.ns.definirModo({ tipo = "rota", prof = "engineering", alvo = 225 })
    end },
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      local R = ns.plano.rota
      b.igual(R.alvo, 225, "alvo 225")
      b.igual({ R.rank.nome, R.rank.custo, R.rank.pericia, R.rank.nivel, R.rank.cap, R.rank.bloqueado },
        { "Expert Engineering", 5000, 125, 20, 225, true }, "Expert bloqueado pelo nivel 10")
      b.igual(CompraForeverAcao:GetText(), "Expert Engineering needs level 20", "texto: Expert pede nivel 20")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado")
      B.ROTA.nivel = 20
    end },
    { fechar_profissao = true },
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(ns.plano.rota.rank.bloqueado, false, "Expert liberado no nivel 20")
      b.igual(CompraForeverAcao:GetText(), "Train Expert Engineering (" .. ns.moeda(5000) .. ")", "texto: treinar o Expert")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
  end,
}
