-- rota-17 (CONTRATO 12.6 e 12.2): /reload no meio da rota. O pedido de po ja foi comprado no leilao e esta a caminho pelo
-- correio; os contadores de venda (credito, vendido), de craft e o gasto estao gravados. Depois do reload_real: o correio
-- continua contado (nada recomprado, nem com um scan novo), os contadores sobrevivem, o craft e liberado so quando o dono
-- pega o correio (alguns segundos depois), e a conciliacao zera o correio.
local B = __bancada

local f = B.fixture("eng150", {
  profissoes = { { id = 202, nome = "Engineering", nivel = 40, max = 75 } },
  bolsas = {
    { bolsa = 0, slot = 1, itemID = 2589, qtd = 20 }, { bolsa = 0, slot = 2, itemID = 2589, qtd = 20 },
    { bolsa = 0, slot = 3, itemID = 2589, qtd = 20 }, { bolsa = 0, slot = 4, itemID = 2589, qtd = 18 },
    { bolsa = 0, slot = 5, itemID = 4358, qtd = 10 }, { bolsa = 0, slot = 6, itemID = 4361, qtd = 3 },
  },
  sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
    prof = { engineering = { pericia = 40, max = 75, ids = { [3919] = true }, n = 1, em = 1 } },
    rota = { engineering = { credito = { [4358] = 10, [4361] = 3, [4370] = 7 }, vendido = { [4358] = 5 }, craftado = { [3919] = 5 },
      gasto = 100, inicio = 1 } } },
})
-- so o po tem fonte (leilao): o trecho de compra para no passo 2 por falta de preco e a unica linha e a do po
f.dados.rotas.profs.engineering.trechos[1].fontes = { [4357] = { f = "L", qtd = 119, custo = 1809, teto = 14 } }

local function contadores()
  local c = CompraForeverCharDB.rota.engineering
  return { c.credito[4358], c.credito[4361], c.credito[4370], c.vendido[4358], c.vendido[4361], c.craftado[3919] }
end

return {
  id = "rota-17", grupo = "rota",
  descricao = "reload_real no meio: correio nao recomprado, contadores de venda e gasto sobrevivem",
  inicio = f,
  passos = {
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local P = b.ns.plano
      b.igual(#P.leilao, 1, "uma linha de leilao")
      b.igual({ P.leilao[1].id, P.leilao[1].qtd }, { 4357, 78 }, "78 Rough Blasting Powder")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "um Start")
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 1, "um Confirm")
      b.igual(CompraForeverCharDB.correio[4357], 78, "correio gravado: 78 po a caminho")
      b.verdadeiro(CompraForeverCharDB.rota.engineering.gasto > 100, "gasto da rota somou a compra")
      b.igual(#b.ns.plano.leilao, 0, "plano refeito sem a linha")
    end },
    { fechar_leilao = true },
    -- vende o craftado antes do reload
    { abrir_vendedor = true },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Sell 13 items (+" .. b.ns.moeda(10 * 30 + 3 * 120) .. ")", "venda dos 10 Rough Dynamite e das 3 Copper Tube")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { fechar_vendedor = true },
    { chamar = function(b)
      b.igual(contadores(), { 0, 0, 7, 15, 3, 5 }, "contadores antes do reload: credito 0, 0 e 7, vendido 15 e 3, craftado 5")
      local g = CompraForeverCharDB.rota.engineering.gasto
      B.gasto_antes = g
      b.verdadeiro(g > 100, "gasto antes do reload")
      B.dinheiro_antes = GetMoney()
    end },
    -- reload no meio
    { reload_real = true },
    { avancar = 3 },
    { chamar = function(b)
      b.igual(contadores(), { 0, 0, 7, 15, 3, 5 }, "contadores depois do reload")
      b.igual(CompraForeverCharDB.rota.engineering.gasto, B.gasto_antes, "gasto sobreviveu")
      b.igual(CompraForeverCharDB.correio[4357], 78, "correio sobreviveu ao reload")
      local P = b.ns.plano
      b.igual(P and P.modo, 2, "plano de rota logo depois do reload, sem scan (12.3: craft e venda funcionam logo depois de um /reload)")
      b.igual(P and #P.leilao, 0, "sem linha de leilao: o correio conta como estoque")
    end },
    { avancar = 30 },
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Take mail first (78 items)", "craft pede o correio primeiro")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado")
    end },
    { fechar_profissao = true },
    -- de novo no leilao, com scan: nada de recomprar
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(#b.ns.plano.leilao, 0, "depois do scan: ainda sem linha de leilao")
      b.falso(string.find(CompraForeverAcao:GetText(), "^Buy") ~= nil, "nenhuma compra oferecida")
    end },
    { fechar_leilao = true },
    -- alguns segundos depois o dono abre a caixa e pega
    { avancar = 90 },
    { abrir_correio = true },
    { chamar = function(b)
      b.igual(CompraForeverCharDB.correio[4357], 78, "a carta ainda tem o anexo: o correio segue contado")
    end },
    { pegar_correio = true },
    { ate_ocioso = true },
    { fechar_correio = true },
    { abrir_profissao = { nome = "Engineering" } },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(C_Item.GetItemCount(4357), 78, "78 po nas bolsas")
      b.igual(CompraForeverCharDB.correio[4357] or 0, 0, "correio conciliado: zero")
      b.igual(CompraForeverAcao:GetText(), "Craft 20 Rough Dynamite", "agora o craft")
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "ainda um so Start (nada recomprado)")
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 1, "ainda um so Confirm")
      b.igual(contadores(), { 0, 0, 7, 15, 3, 5 }, "contadores de venda intactos")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
    b.igual(b.contar("TakeInboxItem") + b.contar("AutoLootMailItem"), 0, "o addon nao pega o correio")
  end,
}
