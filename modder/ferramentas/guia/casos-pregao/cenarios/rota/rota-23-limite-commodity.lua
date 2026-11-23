-- Limite de quantidade da commodity (falso), CONTRATO 12.5/12.9: o leilao nao entrega a quantidade pedida (o mercado do Linen Cloth
-- encolheu para 100 unidades depois do scan: a cotacao de 141 fica indisponivel) ou responde com erro. O addon mostra a mensagem,
-- nao confirma nada, nao gasta, e cada clique faz no maximo UMA acao de leilao (nunca dois Start no mesmo clique); depois, com o
-- mercado de volta, a compra segue (Start, Confirm).
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
local ACOES = { "StartCommoditiesPurchase", "ConfirmCommoditiesPurchase", "PlaceBid", "PostCommodity", "PostItem", "CancelAuction" }
-- nenhuma acao de leilao divide o clique com outra
local function umaPorClique(b, msg)
  local por = {}
  for _, nome in ipairs(ACOES) do
    for _, c in ipairs(b.chamadas(nome)) do
      por[c.clique or 0] = (por[c.clique or 0] or 0) + 1
    end
  end
  local max = 0
  for _, n in pairs(por) do if n > max then max = n end end
  b.verdadeiro(max <= 1, msg .. " (maximo de acoes num clique: " .. max .. ")")
end

return {
  id = "rota-23", grupo = "rota",
  descricao = "limite de quantidade da commodity: cotacao indisponivel e erro de leilao mostram mensagem, sem gasto, um Start por clique; depois a compra segue",
  inicio = __bancada.fixture("eng150", {
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Buy 141 Linen Cloth (29s 61c)", "texto antes")
      -- o mercado encolhe depois do scan: 100 unidades, menos que as 141 da linha
      __bancada.A.mercado[2589] = { { id = 9001, preco = 21, qtd = 100, donos = 1 } }
    end },
    -- 1: cotacao indisponivel
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "um Start no clique")
      b.igual(b.chamadas("StartCommoditiesPurchase")[1].args, { 2589, 141, n = 2 }, "Start de 141 Linen")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado enquanto cota")
    end },
    { avancar = 1 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(ns.mensagem(), "Quote unavailable: try again", "mensagem da cotacao indisponivel")
      tem(b, "Quote unavailable: try again", "a mensagem aparece no painel")
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 0, "nada confirmado")
      b.igual(GetMoney(), 500000, "dinheiro intacto")
      b.igual(CompraForeverCharDB.correio[2589], nil, "nada no correio gravado")
      b.igual((CompraForeverCharDB.rota.engineering or {}).gasto or 0, 0, "gasto da rota zero")
      b.falso(ns.compraOcupada(), "a compra nao fica presa")
      b.igual(CompraForeverAcao:GetText(), "Buy 141 Linen Cloth (29s 61c)", "o botao volta com a mesma linha")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado de novo")
      b.verdadeiro(CompraForeverModo:IsEnabled(), "Modo habilitado de novo")
      b.igual(#ns.plano.leilao, 12, "a linha continua no plano")
    end },
    -- 2: de novo (outro clique, outro Start), mesma mensagem
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 2, "dois Start em dois cliques")
      b.verdadeiro(b.chamadas("StartCommoditiesPurchase")[1].clique ~= b.chamadas("StartCommoditiesPurchase")[2].clique, "cliques diferentes")
      b.igual(b.ns.mensagem(), "Quote unavailable: try again", "a mesma mensagem")
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 0, "nada confirmado")
    end },
    -- 3: erro do leilao na resposta ao Start
    { injetar = { "erro_leilao", "Unavailable" } },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 3, "terceiro Start (barrado pelo leilao)")
      b.igual(b.ns.mensagem(), "Auction error: try again", "mensagem do erro de leilao")
      tem(b, "Auction error: try again", "a mensagem aparece no painel")
      b.falso(b.ns.compraOcupada(), "a compra nao fica presa")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado de novo")
      b.igual(GetMoney(), 500000, "dinheiro intacto")
      umaPorClique(b, "nunca dois Start no mesmo clique")
    end },
    -- 4: o mercado volta (200 unidades): a compra segue em dois cliques
    { chamar = function(b)
      __bancada.A.mercado[2589] = { { id = 9003, preco = 21, qtd = 200, donos = 1 } }
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 4, "quarto Start")
      b.igual(CompraForeverAcao:GetText(), "Confirm 141 Linen Cloth (29s 61c)", "agora cota e pede confirmacao")
      b.igual(b.ns.mensagem(), nil, "sem mensagem de erro")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 1, "um Confirm")
      b.igual(GetMoney(), 500000 - 2961, "dinheiro")
      b.igual(CompraForeverCharDB.correio[2589], 141, "correio gravado")
      b.igual(CompraForeverCharDB.rota.engineering.gasto, 2961, "gasto da rota")
      umaPorClique(b, "nunca dois Start no mesmo clique")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
  end,
}
