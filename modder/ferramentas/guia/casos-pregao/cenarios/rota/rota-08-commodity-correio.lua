-- Commodity em dois cliques no modo de rota (CONTRATO 12.5 e 12.6): Start (cota) e Confirm; o texto muda entre eles, o Modo fica
-- desligado enquanto a compra esta aberta; a compra chega pelo correio (S.correio = CompraForeverCharDB.correio), a linha sai do plano,
-- o gasto soma em rota[slug].gasto; o dono pega a carta e o pendente zera sem a linha voltar.
local function textos()
  local out = {}
  for _, r in ipairs({ CompraForeverPainel:GetRegions() }) do
    local t = r:GetText()
    if t and t ~= "" then out[#out + 1] = t end
  end
  return out
end
local function tem(b, trecho, msg)
  for _, t in ipairs(textos()) do
    if string.find(t, trecho, 1, true) then return true end
  end
  b.verdadeiro(false, msg .. " (texto '" .. trecho .. "' nao achado em: " .. table.concat(textos(), " | ") .. ")")
  return false
end
local function linha(plano, id)
  for _, l in ipairs(plano.leilao) do if l.id == id then return l end end
  return nil
end

return {
  id = "rota-08", grupo = "rota",
  descricao = "commodity em dois cliques na rota: Start, Confirm, correio gravado, gasto, linha sai do plano, NEXT mailbox, carta pega pelo dono",
  inicio = __bancada.fixture("eng150", {
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      ns.planoAntes = ns.plano
      b.igual(#ns.plano.leilao, 12, "12 linhas antes")
      b.igual(CompraForeverAcao:GetText(), "Buy 141 Linen Cloth (29s 61c)", "texto antes da cotacao")
      b.verdadeiro(CompraForeverModo:IsEnabled(), "Modo habilitado antes")
    end },
    -- clique 1: cota
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "um Start")
      b.igual(b.chamadas("StartCommoditiesPurchase")[1].args[1], 2589, "Start do Linen Cloth")
      b.igual(b.chamadas("StartCommoditiesPurchase")[1].args[2], 141, "Start de 141")
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 0, "nada confirmado no clique 1")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado enquanto cota")
      b.falso(CompraForeverModo:IsEnabled(), "Modo desligado com a compra aberta (ns.compraOcupada)")
      b.verdadeiro(b.ns.compraOcupada(), "compra ocupada")
      CompraForeverModo:GetScript("OnClick")(CompraForeverModo, "LeftButton")
      b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 150 }, "clique no Modo ocupado nao troca")
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Confirm 141 Linen Cloth (29s 61c)", "o texto vira Confirm")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado para confirmar")
      b.igual(GetMoney(), 500000, "nada pago ainda")
    end },
    -- clique 2: confirma
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 1, "um Confirm")
      b.igual(b.chamadas("ConfirmCommoditiesPurchase")[1].args[2], 141, "Confirm de 141")
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "ainda um Start")
      b.igual(GetMoney(), 500000 - 2961, "dinheiro")
      b.igual(C_Item.GetItemCount(2589), 0, "o leilao entrega pelo correio: nada nas bolsas ainda")
      b.igual(ns.estoque(2589), 141, "o estoque conta o comprado a caminho")
      b.igual(ns.estoqueBolsa(2589), 0, "estoque das bolsas zero")
      -- gravado no personagem (12.2, 12.6)
      b.igual(CompraForeverCharDB.correio[2589], 141, "correio gravado")
      b.igual(CompraForeverCharDB.correioVisto[2589], 0, "correioVisto gravado")
      b.verdadeiro(type(CompraForeverCharDB.correioEm[2589]) == "number", "correioEm gravado")
      b.igual(CompraForeverCharDB.rota.engineering.gasto, 2961, "gasto da rota")
      b.igual(CompraForeverCharDB.rota.engineering.credito, {}, "nada craftado ainda")
      b.verdadeiro(ns.plano ~= ns.planoAntes, "plano refeito")
      b.igual(ns.plano.modo, 2, "plano de rota")
      b.falso(linha(ns.plano, 2589) ~= nil, "a linha do Linen saiu do plano")
      b.igual(#ns.plano.leilao, 11, "11 linhas")
      b.igual(ns.plano.rota.proximo, "mail", "proximo: o correio (o passo atual pede o Linen)")
      b.igual(ns.plano.rota.restante, 49390 - 2961, "restante sem o Linen")
      b.igual(ns.plano.totais.gasto, 49390 - 2961, "gasto do plano sem o Linen")
      b.igual(CompraForeverAcao:GetText(), "Buy 133 Rough Blasting Powder (14s 63c)", "a proxima linha")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
      b.verdadeiro(CompraForeverModo:IsEnabled(), "Modo habilitado de novo")
    end },
    { avancar = 1 },
    { chamar = function(b)
      tem(b, "NEXT: mailbox (141 items)", "NEXT: mailbox")
      tem(b, "Mailbox: 141 bought items to collect", "linha do correio")
    end },
    -- o dono pega a carta: o pendente zera e a linha nao volta
    { fechar_leilao = true },
    { abrir_correio = true },
    { chamar = function(b)
      b.igual({ GetInboxNumItems() }, { 1, 1 }, "uma carta")
      b.igual(CompraForeverCharDB.correio[2589], 141, "a caixa tem os 141: o pendente continua")
      b.verdadeiro(CompraForeverPainel:IsShown(), "painel aparece na caixa de correio")
      b.igual(b.contar("TakeInboxItem") + b.contar("AutoLootMailItem"), 0, "o addon nao pega nada")
    end },
    { pegar_correio = true },
    { chamar = function(b)
      local ns = b.ns
      b.igual(C_Item.GetItemCount(2589), 141, "141 Linen nas bolsas")
      b.igual(CompraForeverCharDB.correio[2589], nil, "pendente zerado")
      b.igual(ns.estoque(2589), 141, "estoque sem contar em dobro")
      b.falso(linha(ns.plano, 2589) ~= nil, "a linha do Linen nao volta")
      b.igual(#ns.plano.leilao, 11, "11 linhas")
      b.igual(CompraForeverCharDB.rota.engineering.gasto, 2961, "gasto continua")
    end },
    -- de volta ao leilao: sem correio pendente, o NEXT deixa de ser a caixa de correio
    { fechar_correio = true },
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      b.verdadeiro(ns.plano.rota.proximo ~= "mail", "sem correio pendente o plano nao manda mais ao correio (proximo = " .. tostring(ns.plano.rota.proximo) .. ")")
      for _, t in ipairs(textos()) do
        b.falso(string.find(t, "NEXT: mailbox", 1, true) ~= nil, "o painel nao diz mais NEXT: mailbox (" .. t .. ")")
        b.falso(string.find(t, "bought items to collect", 1, true) ~= nil, "sem a linha do correio (" .. t .. ")")
      end
      tem(b, "NEXT: AH", "NEXT: AH")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
    b.igual(b.contar("TakeInboxItem") + b.contar("AutoLootMailItem"), 0, "o addon nunca pega o correio")
  end,
}
