-- Fumaca dos falsos da modalidade de rota (bancada\rota.lua), pelas proprias APIs do falso, sem logica de rota do addon:
-- profissao por cenario, receitas com requisitos, subida de pericia, StopRecipeRepeat, craft_lote, interromper_craft,
-- encantamento, treinador (so leitura), correio, reload_real e inicio.dados.
local function ultimo(b, nome)
  local l = b.eventos(nome)
  return l[#l]
end
local function tipos(b)
  local t = {}
  for _, v in ipairs(b.violacoes()) do t[#t + 1] = v.tipo end
  return t
end

return {
  id = "rota-00b", grupo = "rota",
  descricao = "falsos da rota: profissoes, pericia, requisitos, treinador, correio, reload_real, inicio.dados",
  aceita_violacoes = true,
  inicio = {
    dinheiro = 1000, nivel = 12, perto = {},
    profissoes = { { id = 202, nome = "Engineering", nivel = 1, max = 75 }, { id = 164, nome = "Blacksmithing", nivel = 300, max = 300 } },
    pericia_modo = "roteiro",
    pericia_roteiro = { true, false, true, false, false, false, false, true },
    dados = { bancada_teste = { x = 1 } },
    itens = {
      [100] = { nome = "Blacksmith Hammer", pilha = 1 }, [101] = { nome = "Ore", pilha = 20 }, [102] = { nome = "Bar", pilha = 20 },
      [103] = { nome = "Dust", pilha = 20 }, [104] = { nome = "Trinket", pilha = 1 },
    },
    bolsas = { { bolsa = 0, slot = 1, itemID = 101, qtd = 20 }, { bolsa = 0, slot = 2, itemID = 103, qtd = 1 }, { bolsa = 0, slot = 4, itemID = 101, qtd = 20 } },
    receitas = {
      [1] = { nome = "Make Bar", produto = 102, qtd = 1, reagentes = { { 101, 1 } }, amarela = 10, cinza = 20, pontos = 1, prof = 202,
        foco = "Anvil", ferramentas = { 100 }, aprende = 5, treino = 50 },
      [2] = { nome = "Enchant Thing", reagentes = { { 103, 1 } }, encantar = true, prof = 202 },
      [3] = { nome = "Smith Thing", produto = 102, reagentes = { { 101, 1 } }, prof = 164 },
      [4] = { nome = "Trained Later", produto = 102, reagentes = { { 101, 1 } }, prof = 202, aprendida = false, aprende = 20, treino = 70 },
      [5] = { nome = "Big Points", produto = 102, reagentes = { { 101, 1 } }, amarela = 100, cinza = 200, pontos = 5, prof = 202 },
      [7] = { nome = "Half Chance", produto = 102, reagentes = { { 101, 1 } }, amarela = 0, cinza = 200, pontos = 1, prof = 202 },
    },
    correio = {
      { assunto = "A", anexo = { itemID = 101, qtd = 3 } },
      { assunto = "B", anexo = { itemID = 102, qtd = 2 } },
      { assunto = "C", anexo = { itemID = 104, qtd = 6 } },
    },
    vendedor = {},
  },
  passos = {
    -- 4: listas de profissao e nivel, com a janela fechada
    { chamar = function(b)
      b.igual({ GetProfessions() }, { 1, 2, n = nil }, "GetProfessions")
      b.igual({ GetProfessionInfo(1) }, { "Engineering", 134400, 1, 75, 0, 0, 202, 0 }, "GetProfessionInfo")
      b.igual(C_TradeSkillUI.GetProfessionInfoBySkillLineID(164).professionName, "Blacksmithing", "por linha")
      b.igual(C_TradeSkillUI.GetProfessionInfoBySkillLineID(999), nil, "linha desconhecida")
      b.igual(C_SkillInfo.GetNumSkillLines(), 2, "GetNumSkillLines")
      b.igual(C_SkillInfo.GetSkillLineInfoByID(202).skillLevel, 1, "GetSkillLineInfoByID")
      b.igual(UnitLevel("player"), 12, "UnitLevel")
      b.igual(C_TradeSkillUI.GetBaseProfessionInfo().professionID, 0, "janela fechada")
      __bancada.ROTA.apisNil = true
      b.igual({ GetProfessions() }, {}, "apis_prof nil: GetProfessions")
      b.igual(GetProfessionInfo(1), nil, "apis_prof nil: GetProfessionInfo")
      b.igual(C_TradeSkillUI.GetProfessionInfoBySkillLineID(202), nil, "apis_prof nil: por linha")
      b.igual(C_SkillInfo.GetNumSkillLines(), nil, "apis_prof nil: GetNumSkillLines")
      b.igual(C_SkillInfo.GetSkillLineInfoByID(202), nil, "apis_prof nil: GetSkillLineInfoByID")
      __bancada.ROTA.apisNil = false
    end },
    -- 1 e 2: janela da profissao escolhida, receitas dela, dificuldade, requisitos
    { abrir_profissao = { nome = "Engineering" } },
    { chamar = function(b)
      for _, f in ipairs({ C_TradeSkillUI.GetBaseProfessionInfo, C_TradeSkillUI.GetChildProfessionInfo }) do
        local i = f()
        b.igual({ i.professionID, i.professionName, i.skillLevel, i.maxSkillLevel, i.parentProfessionID, i.parentProfessionName },
          { 202, "Engineering", 1, 75, 202, "Engineering" }, "info da profissao aberta")
      end
      b.igual(C_TradeSkillUI.GetAllRecipeIDs(), { 1, 2, 4, 5, 7 }, "so as receitas da profissao aberta")
      local ri = C_TradeSkillUI.GetRecipeInfo(1)
      b.igual({ ri.relativeDifficulty, ri.numSkillUps, ri.learned }, { 0, 1, true }, "GetRecipeInfo novo")
      b.igual(C_TradeSkillUI.GetRecipeInfo(3), nil, "receita de outra profissao")
      b.igual(C_TradeSkillUI.GetRecipeRequirements(1), { { name = "Anvil", met = false } }, "requisito longe")
      b.igual(C_TradeSkillUI.GetRecipeRequirements(2), {}, "sem foco")
    end },
    -- 2 e 5: sem martelo, depois sem bigorna
    { chamar = function(b) C_TradeSkillUI.CraftRecipe(1, 1) end },
    { avancar = 1.5 },
    { chamar = function(b)
      b.igual(ultimo(b, "UI_ERROR_MESSAGE").args[2], "Requires Blacksmith Hammer", "falta a ferramenta")
      b.igual(b.contar("BAG_UPDATE"), 0, "nada consumido")
    end },
    { injetar = { "bolsa_trocada", 0, 3, 100, 1 } },
    { chamar = function(b) C_TradeSkillUI.CraftRecipe(1, 1) end },
    { avancar = 1.5 },
    { chamar = function(b)
      b.igual(ultimo(b, "UI_ERROR_MESSAGE").args[2], "Requires Anvil", "falta a bigorna")
      __bancada.ROTA.perto.Anvil = true
      b.igual(C_TradeSkillUI.GetRecipeRequirements(1), { { name = "Anvil", met = true } }, "requisito perto")
    end },
    -- 3: tres crafts, roteiro true/false/true: duas subidas, eventos, SUCCEEDED
    { chamar = function(b) C_TradeSkillUI.CraftRecipe(1, 3) end },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(C_TradeSkillUI.GetBaseProfessionInfo().skillLevel, 3, "pericia 1 -> 3 e gravada na janela")
      b.igual(#__bancada.C.subidas, 2, "duas subidas registradas")
      b.igual(__bancada.C.subidas[2], { magia = 1, de = 2, para = 3, prof = "Engineering" }, "subida registrada")
      local ch = b.eventos("CHAT_MSG_SKILL")
      b.igual(#ch, 2, "dois CHAT_MSG_SKILL")
      b.igual(ch[2].args[1], "Your skill in Engineering has increased to 3.", "texto do chat")
      b.igual(#b.eventos("SKILL_LINES_CHANGED"), 2, "SKILL_LINES_CHANGED")
      b.igual(#b.eventos("TRADE_SKILL_LIST_UPDATE"), 2, "TRADE_SKILL_LIST_UPDATE")
      local su = b.eventos("UNIT_SPELLCAST_SUCCEEDED")
      b.igual(#su, 3, "um SUCCEEDED por craft")
      b.igual({ su[1].args[1], su[1].args[3] }, { "player", 1 }, "SUCCEEDED do jogador, com a magia")
      b.igual(C_Item.GetItemCount(102), 3, "3 Bar")
      b.igual(C_Item.GetItemCount(101), 37, "37 Ore")
    end },
    -- 5: StopRecipeRepeat cancela o resto do lote
    { chamar = function(b) C_TradeSkillUI.CraftRecipe(1, 5) end },
    { avancar = 2.5 },
    { chamar = function(b) C_TradeSkillUI.StopRecipeRepeat() end },
    { avancar = 10 },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(102), 5, "so 2 dos 5 crafts aconteceram")
      b.igual(#b.eventos("UPDATE_TRADESKILL_CAST_STOPPED"), 1, "UPDATE_TRADESKILL_CAST_STOPPED")
    end },
    -- 5: craft_lote = "um"
    { chamar = function(b) __bancada.A.P.craft_lote = "um"; C_TradeSkillUI.CraftRecipe(1, 4) end },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(102), 6, "o servidor fez um so")
      __bancada.A.P.craft_lote = "todos"
    end },
    -- 5: interromper_craft(1)
    { injetar = { "interromper_craft", 1 } },
    { chamar = function(b) C_TradeSkillUI.CraftRecipe(1, 3) end },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(102), 7, "um craft e a interrupcao")
      local it = b.eventos("UNIT_SPELLCAST_INTERRUPTED")
      b.igual(#it, 1, "UNIT_SPELLCAST_INTERRUPTED")
      b.igual(it[1].args[1], "player", "do jogador")
    end },
    -- 3: nunca acima do maximo
    { chamar = function(b)
      __bancada.ROTA.sel.nivel = 73
      C_TradeSkillUI.CraftRecipe(5, 1)
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(C_TradeSkillUI.GetBaseProfessionInfo().skillLevel, 75, "73 + 5 limitado ao maximo 75")
      b.igual(__bancada.C.subidas[#__bancada.C.subidas].para, 75, "subida registrada no maximo")
    end },
    -- 3: modo "sempre" so sobe com chance > 0; ordem e desligamento dos eventos
    { chamar = function(b)
      local R = __bancada.ROTA
      R.modo = "sempre"
      R.sel.nivel = 74
      R.ordem = { "TRADE_SKILL_LIST_UPDATE", "CHAT_MSG_SKILL", "SKILL_LINES_CHANGED" }
      R.marca = #b.eventos()
      C_TradeSkillUI.CraftRecipe(7, 1)
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      local R = __bancada.ROTA
      b.igual(R.sel.nivel, 75, "sempre: subiu")
      local nomes = {}
      for i = R.marca + 1, #b.eventos() do
        local n = b.eventos()[i].nome
        if n == "TRADE_SKILL_LIST_UPDATE" or n == "CHAT_MSG_SKILL" or n == "SKILL_LINES_CHANGED" then nomes[#nomes + 1] = n end
      end
      b.igual(nomes, { "TRADE_SKILL_LIST_UPDATE", "CHAT_MSG_SKILL", "SKILL_LINES_CHANGED" }, "ordem_pericia")
      R.sel.nivel = 70
      R.eventos = false
      R.marca = #b.eventos()
      C_TradeSkillUI.CraftRecipe(7, 1)
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      local R = __bancada.ROTA
      b.igual(R.sel.nivel, 71, "sobe sem eventos")
      local algum = false
      for i = R.marca + 1, #b.eventos() do
        local n = b.eventos()[i].nome
        if n == "TRADE_SKILL_LIST_UPDATE" or n == "CHAT_MSG_SKILL" or n == "SKILL_LINES_CHANGED" then algum = true end
      end
      b.falso(algum, "eventos_pericia = false")
      R.eventos = true
      -- aleatorio: a propria LCG, igual a conta feita aqui
      R.modo = "aleatorio"
      R.sel.nivel = 50
      R.sel.max = 75
      R.lcg = 8.0
      R.subidasAntes = #__bancada.C.subidas
      C_TradeSkillUI.CraftRecipe(7, 6)
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      local R = __bancada.ROTA
      local x, s, esperado = 8.0, 50, 0
      for _ = 1, 6 do
        x = (x * 48271.0) % 2147483647.0
        if x / 2147483647.0 < (200 - s) / 200 then s = s + 1; esperado = esperado + 1 end
      end
      b.igual(R.sel.nivel, 50 + esperado, "aleatorio segue a LCG propria")
      b.igual(#__bancada.C.subidas - R.subidasAntes, esperado, "subidas do aleatorio registradas")
    end },
    -- 4: apis_prof ja conferido; nivel do personagem muda o treino do rank
    -- 7: treinador so de leitura
    { abrir_treinador = true },
    { chamar = function(b)
      b.igual(#b.eventos("TRAINER_SHOW"), 1, "TRAINER_SHOW")
      b.verdadeiro(ClassTrainerFrame:IsShown(), "ClassTrainerFrame na tela")
      b.igual(GetNumTrainerServices(), 2, "dois servicos (receitas com treino)")
      b.igual({ GetTrainerServiceInfo(1) }, { "Make Bar", "", "used" }, "servico 1")
      b.igual({ GetTrainerServiceInfo(2) }, { "Trained Later", "", "available" }, "servico 2")
      BuyTrainerService(2)
      b.igual(C_TradeSkillUI.GetRecipeInfo(4).learned, false, "o addon nao treina")
    end },
    { treinar = { magia = 4 } },
    { chamar = function(b)
      b.igual(C_TradeSkillUI.GetRecipeInfo(4).learned, true, "treinada pelo dono")
      b.igual(#b.eventos("NEW_RECIPE_LEARNED"), 1, "NEW_RECIPE_LEARNED")
      b.igual(b.eventos("NEW_RECIPE_LEARNED")[1].args[1], 4, "da magia 4")
      b.igual({ GetTrainerServiceInfo(2) }, { "Trained Later", "", "used" }, "servico usado")
      __bancada.ROTA.antesRank = #b.eventos("SKILL_LINES_CHANGED")
    end },
    { treinar_rank = 150 },
    { chamar = function(b)
      b.igual(C_TradeSkillUI.GetBaseProfessionInfo().maxSkillLevel, 150, "rank 150 com nivel 12")
      b.igual(#b.eventos("SKILL_LINES_CHANGED"), __bancada.ROTA.antesRank + 1, "SKILL_LINES_CHANGED do treino")
    end },
    { treinar_rank = 225 },
    { chamar = function(b)
      b.igual(C_TradeSkillUI.GetBaseProfessionInfo().maxSkillLevel, 150, "225 recusado com nivel 12")
      b.igual(#__bancada.C.recusas, 1, "recusa registrada")
    end },
    { fechar_treinador = true },
    { chamar = function(b)
      b.igual(#b.eventos("TRAINER_CLOSED"), 1, "TRAINER_CLOSED")
      b.igual(GetNumTrainerServices(), 0, "treinador fechado")
    end },
    -- 6: encantamento
    { chamar = function(b)
      C_TradeSkillUI.CraftEnchant(2)
      C_TradeSkillUI.CraftRecipe(2, 1)
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(103), 1, "nada consumido no encantamento")
      b.igual(tipos(b), { "treino", "encanto", "encanto" }, "violacoes ate aqui")
    end },
    -- 8: correio
    { abrir_correio = true },
    { chamar = function(b)
      b.igual(#b.eventos("MAIL_SHOW"), 1, "MAIL_SHOW")
      b.igual(#b.eventos("MAIL_INBOX_UPDATE"), 1, "MAIL_INBOX_UPDATE")
      b.igual({ GetInboxNumItems() }, { 3, 3 }, "tres cartas")
      b.igual({ GetInboxItem(1, 1) }, { "Ore", 101, 134400, 3, 1, true }, "anexo da carta 1")
      __bancada.ROTA.oreAntes = C_Item.GetItemCount(101)
      TakeInboxItem(1, 1)
      AutoLootMailItem(1)
      b.igual(C_Item.GetItemCount(101), __bancada.ROTA.oreAntes, "o addon nao pega")
    end },
    { pegar_correio = 1 },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(101), __bancada.ROTA.oreAntes + 3, "carta A pega pelo dono")
      b.igual({ GetInboxNumItems() }, { 2, 2 }, "carta vazia some")
      b.verdadeiro(#b.eventos("BAG_UPDATE") > 0 and #b.eventos("BAG_UPDATE_DELAYED") > 0, "BAG_UPDATE e BAG_UPDATE_DELAYED")
      __bancada.ROTA.barrasAntes = C_Item.GetItemCount(102)
      __bancada.A.P.tamanho_bolsa = 1
    end },
    { pegar_correio = true },
    { chamar = function(b)
      b.igual(ultimo(b, "UI_ERROR_MESSAGE").args[2], "Inventory is full", "bolsa cheia")
      b.igual({ GetInboxNumItems() }, { 1, 1 }, "a carta C fica")
      __bancada.A.P.tamanho_bolsa = 16
      b.igual(C_Item.GetItemCount(102), __bancada.ROTA.barrasAntes + 2, "carta B pega")
      b.igual(C_Item.GetItemCount(104), 0, "carta C nao cabe")
    end },
    { fechar_correio = true },
    { chamar = function(b) b.igual(#b.eventos("MAIL_CLOSED"), 1, "MAIL_CLOSED") end },
    -- 9: reload_real fecha tudo sem eventos; inicio.dados volta depois do reload
    { chamar = function(b)
      b.igual(CompraForeverDados.bancada_teste.x, 1, "inicio.dados mesclado")
      CompraForeverDados.bancada_teste.x = 5
    end },
    { abrir_leilao = true },
    { abrir_vendedor = true },
    { abrir_treinador = true },
    { abrir_correio = true },
    { chamar = function(b)
      local n = {}
      for _, e in ipairs({ "AUCTION_HOUSE_CLOSED", "MERCHANT_CLOSED", "TRADE_SKILL_CLOSE", "MAIL_CLOSED", "TRAINER_CLOSED" }) do n[e] = #b.eventos(e) end
      __bancada.ROTA.fechados = n
      b.verdadeiro(C_TradeSkillUI.IsTradeSkillReady(), "profissao aberta antes")
    end },
    { reload_real = true },
    { chamar = function(b)
      local n = __bancada.ROTA.fechados
      for e, antes in pairs(n) do b.igual(#b.eventos(e), antes, "sem evento de fechar: " .. e) end
      b.falso(C_TradeSkillUI.IsTradeSkillReady(), "profissao fechada")
      b.falso(MerchantFrame:IsShown(), "vendedor fechado")
      b.falso(MailFrame:IsShown(), "correio fechado")
      b.falso(ClassTrainerFrame:IsShown(), "treinador fechado")
      b.falso(AuctionHouseFrame:IsShown(), "leilao fechado")
      b.igual(GetNumTrainerServices(), 0, "treinador fechado (API)")
      b.igual(CompraForeverDados.bancada_teste.x, 1, "inicio.dados mesclado de novo depois do reload")
      b.verdadeiro(#b.eventos("PLAYER_ENTERING_WORLD") >= 2, "o reload aconteceu")
    end },
    -- fixture
    { chamar = function(b)
      local f = __bancada.fixture("eng150", { dinheiro = 1, perto = { Anvil = false } })
      b.igual({ f.dinheiro, f.nivel, f.perto.Anvil, f.profissoes[1].id }, { 1, 10, false, 202 }, "fixture com over")
      local p = f.dados.rotas.profs.engineering
      b.igual({ #p.trechos[1].passos, f.mercado[2838][3].preco, f.vendedor[1].preco, p.trechos[1].fontes[4377].magia }, { 9, 354, 18, 3945 }, "fixture")
    end },
  },
  conferir = function(b)
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 1, "um BuyTrainerService (so o do teste)")
    b.igual(tipos(b), { "treino", "encanto", "encanto", "correio", "correio" }, "so as violacoes provocadas")
  end,
}
