-- rota-14 (CONTRATO 12.4): perícia 40 no Rough Dynamite (30/60): 78 crafts no primeiro passo (nao os 119 do 1), e as
-- quantidades do plano seguem: 92 Rough Blasting Powder (78 + 2 x 7) e 100 Linen Cloth (78 + 7 + 15). Com os materiais nas
-- bolsas, o craft anda em lotes de 20 e o ultimo leva so o que ha (18).
local B = __bancada

local f = B.fixture("eng150", {
  profissoes = { { id = 202, nome = "Engineering", nivel = 40, max = 75 } },
  sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
    prof = { engineering = { pericia = 40, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
})

return {
  id = "rota-14", grupo = "rota",
  descricao = "pericia 40: 78 crafts no primeiro passo, quantidades do plano, lotes de 20 e o ultimo de 18",
  inicio = f,
  passos = {
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      local P = ns.plano
      local R = P.rota
      b.igual(R.pericia, 40, "pericia 40 no plano")
      b.igual(R.atual.magia, 3919, "passo atual: Rough Dynamite")
      b.igual({ R.atual.de, R.atual.ate, R.atual.faltam }, { 1, 59, 78 }, "78 crafts que faltam no primeiro passo")
      b.igual({ R.passos[1].n, R.passos[1].estado }, { 78, "agora" }, "passo 1 no plano")
      b.igual({ P.crafts[1].magia, P.crafts[1].n, P.crafts[1].de, P.crafts[1].ate }, { 3919, 78, 1, 59 }, "crafts do plano")
      b.igual(R.passos[2].n, 7, "segundo passo: 7 crafts")
      local qtd = {}
      for _, l in ipairs(P.leilao) do qtd[l.id] = l.qtd end
      b.igual(qtd[4357], 92, "Rough Blasting Powder: 78 + 2 x 7")
      b.igual(qtd[2589], 100, "Linen Cloth: 78 + 7 + 15")
      b.verdadeiro(P.leilao[1].passo == 1, "as linhas comecam pelo passo 1")
      b.igual(CompraForeverAcao:GetText():sub(1, 4), "Buy ", "a acao e comprar no leilao")
    end },
    { fechar_leilao = true },
    -- os materiais do primeiro passo chegam: 78 po e 78 linho
    { injetar = { "bolsa_trocada", 0, 1, 4357, 20 } }, { injetar = { "bolsa_trocada", 0, 2, 4357, 20 } },
    { injetar = { "bolsa_trocada", 0, 3, 4357, 20 } }, { injetar = { "bolsa_trocada", 0, 4, 4357, 18 } },
    { injetar = { "bolsa_trocada", 0, 5, 2589, 20 } }, { injetar = { "bolsa_trocada", 0, 6, 2589, 20 } },
    { injetar = { "bolsa_trocada", 0, 7, 2589, 20 } }, { injetar = { "bolsa_trocada", 0, 8, 2589, 18 } },
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.ns.plano.rota.atual.faltam, 78, "ainda 78 que faltam (a pericia nao mudou)")
      b.igual(CompraForeverAcao:GetText(), "Craft 20 Rough Dynamite", "lote de 20")
    end },
    { clique = "CompraForeverAcao" }, { ate_ocioso = true },
    { clique = "CompraForeverAcao" }, { ate_ocioso = true },
    { clique = "CompraForeverAcao" }, { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 3, "tres lotes")
      for i = 1, 3 do b.igual(b.chamadas("CraftRecipe")[i].args, { 3919, 20, n = 2 }, "lote " .. i .. " de 20") end
      b.igual(C_Item.GetItemCount(4357), 18, "sobram 18 de po")
      b.igual(CompraForeverAcao:GetText(), "Craft 18 Rough Dynamite", "o ultimo lote leva so o que ha")
    end },
    { clique = "CompraForeverAcao" }, { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.chamadas("CraftRecipe")[4].args, { 3919, 18, n = 2 }, "ultimo lote de 18")
      b.igual(C_Item.GetItemCount(4358), 156, "156 Rough Dynamite")
      b.igual(CompraForeverCharDB.rota.engineering.craftado[3919], 78, "contador: 78 crafts")
      b.igual(b.ns.plano.rota.atual.faltam, 78, "faltam segue a pericia (nao subiu)")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
  end,
}
