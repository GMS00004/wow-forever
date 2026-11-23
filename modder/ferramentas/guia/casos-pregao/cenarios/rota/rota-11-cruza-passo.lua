-- rota-11 (CONTRATO 12.5, craft na rota): a pericia chega ao `ate` do passo no meio do lote de 20 (57 -> 59 em 2 crafts, modo
-- "sempre"): pcall(StopRecipeRepeat), a pendencia termina e o botao passa ao passo seguinte. Repetido por cada evento de
-- pericia sozinho (CHAT_MSG_SKILL, SKILL_LINES_CHANGED, TRADE_SKILL_LIST_UPDATE) e com todos.
local B = __bancada

local BOLSA = {
  { 1, 4357, 20 }, { 2, 4357, 20 }, { 3, 2589, 20 }, { 4, 2589, 20 }, { 5, 2840, 20 }, { 6, 4359, 20 }, { 7, 5956, 1 },
}

local FASES = {
  { nome = "todos os eventos", ordem = { "CHAT_MSG_SKILL", "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE" } },
  { nome = "so CHAT_MSG_SKILL", ordem = { "CHAT_MSG_SKILL" } },
  { nome = "so SKILL_LINES_CHANGED", ordem = { "SKILL_LINES_CHANGED" } },
  { nome = "so TRADE_SKILL_LIST_UPDATE", ordem = { "TRADE_SKILL_LIST_UPDATE" } },
}

local passos = {}
local function P(p) passos[#passos + 1] = p end

for i, f in ipairs(FASES) do
  local pref = f.nome .. ": "
  local antes = {}
  if i > 1 then P({ fechar_profissao = true }) end
  P({ chamar = function(b)
    B.ROTA.ordem = f.ordem
    B.ROTA.profs[1].nivel = 57
    for slot = 1, 14 do B.injetar({ "bolsa_trocada", 0, slot, nil, nil }) end
    for _, x in ipairs(BOLSA) do B.injetar({ "bolsa_trocada", 0, x[1], x[2], x[3] }) end
    antes.crafts = b.contar("CraftRecipe")
    antes.stops = b.contar("StopRecipeRepeat")
    antes.craftado = (CompraForeverCharDB.rota and CompraForeverCharDB.rota.engineering
      and CompraForeverCharDB.rota.engineering.craftado[3919]) or 0
  end })
  P({ abrir_profissao = { nome = "Engineering" } })
  P({ avancar = 1 })
  P({ chamar = function(b)
    local R = b.ns.plano.rota
    b.igual(R.atual.magia, 3919, pref .. "passo atual: Rough Dynamite")
    b.igual(R.pericia, 57, pref .. "pericia 57")
    b.igual(CompraForeverAcao:GetText(), "Craft 20 Rough Dynamite", pref .. "lote de 20")
  end })
  P({ clique = "CompraForeverAcao" })
  P({ ate_ocioso = true })
  P({ chamar = function(b)
    b.igual(b.contar("CraftRecipe") - antes.crafts, 1, pref .. "um CraftRecipe")
    b.igual(b.chamadas("CraftRecipe")[b.contar("CraftRecipe")].args, { 3919, 20, n = 2 }, pref .. "pediu 20")
    b.igual(b.contar("StopRecipeRepeat") - antes.stops, 1, pref .. "StopRecipeRepeat uma vez")
    b.igual(C_TradeSkillUI.GetBaseProfessionInfo().skillLevel, 59, pref .. "pericia 59 na janela")
    b.igual(C_Item.GetItemCount(4358), 4, pref .. "so 2 crafts aconteceram (4 Rough Dynamite)")
    b.igual(C_Item.GetItemCount(4357), 38, pref .. "po consumido so dos 2 crafts")
    b.igual(CompraForeverCharDB.rota.engineering.craftado[3919] - antes.craftado, 2, pref .. "contador: 2 crafts")
    b.igual(CompraForeverCharDB.prof.engineering.pericia, 59, pref .. "pericia gravada: 59")
    b.igual(b.ns.plano.rota.atual.magia, 3923, pref .. "plano passou ao Rough Copper Bomb")
    b.igual(b.ns.plano.rota.atual.de, 59, pref .. "passo de 59")
    b.igual(CompraForeverAcao:GetText(), "Craft 7 Rough Copper Bomb", pref .. "botao no passo seguinte")
    b.verdadeiro(CompraForeverAcao:IsEnabled(), pref .. "botao habilitado")
  end })
end

-- sem nenhum evento de pericia o addon nao tem como saber no meio do lote: o lote de 20 vai ate o fim, um so CraftRecipe,
-- sem StopRecipeRepeat e sem erro
do
  local antes = {}
  P({ fechar_profissao = true })
  P({ chamar = function(b)
    B.ROTA.eventos = false
    B.ROTA.profs[1].nivel = 57
    for slot = 1, 14 do B.injetar({ "bolsa_trocada", 0, slot, nil, nil }) end
    for _, x in ipairs(BOLSA) do B.injetar({ "bolsa_trocada", 0, x[1], x[2], x[3] }) end
    antes.crafts = b.contar("CraftRecipe")
    antes.stops = b.contar("StopRecipeRepeat")
    antes.craftado = CompraForeverCharDB.rota.engineering.craftado[3919]
  end })
  P({ abrir_profissao = { nome = "Engineering" } })
  P({ avancar = 1 })
  P({ clique = "CompraForeverAcao" })
  P({ ate_ocioso = true })
  P({ chamar = function(b)
    local pref = "sem eventos: "
    b.igual(b.contar("CraftRecipe") - antes.crafts, 1, pref .. "um CraftRecipe")
    b.igual(b.contar("StopRecipeRepeat") - antes.stops, 0, pref .. "nenhum StopRecipeRepeat (nada avisou)")
    b.igual(C_Item.GetItemCount(4358), 40, pref .. "o lote de 20 foi ate o fim")
    b.igual(CompraForeverCharDB.rota.engineering.craftado[3919] - antes.craftado, 20, pref .. "contador: 20 crafts")
    b.verdadeiro(#B.C.subidas >= 3, pref .. "a pericia subiu na janela sem evento")
  end })
end

return {
  id = "rota-11", grupo = "rota",
  descricao = "craft: a pericia cruza o fim do passo no meio do lote: para (StopRecipeRepeat) e passa ao seguinte, por evento",
  inicio = B.fixture("eng150", {
    profissoes = { { id = 202, nome = "Engineering", nivel = 57, max = 75 } },
    receitas = { [3923] = { aprendida = true } },
    pericia_modo = "sempre",
    bolsas = { { bolsa = 0, slot = 1, itemID = 4357, qtd = 20 }, { bolsa = 0, slot = 2, itemID = 4357, qtd = 20 },
      { bolsa = 0, slot = 3, itemID = 2589, qtd = 20 }, { bolsa = 0, slot = 4, itemID = 2589, qtd = 20 },
      { bolsa = 0, slot = 5, itemID = 2840, qtd = 20 }, { bolsa = 0, slot = 6, itemID = 4359, qtd = 20 },
      { bolsa = 0, slot = 7, itemID = 5956, qtd = 1 } },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 57, max = 75, ids = { [3919] = true, [3923] = true }, n = 2, em = 1 } } },
  }),
  passos = passos,
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
  end,
}
