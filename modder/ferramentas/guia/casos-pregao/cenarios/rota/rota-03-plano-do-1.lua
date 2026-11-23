-- Plano da Engineering do 1 ao 150 com bolsa e dinheiro de sobra (CONTRATO 12.4): as 12 linhas de leilao na ordem do primeiro uso
-- (passo, depois custo maior), o Blacksmith Hammer no vendedor, todos os passos em crafts, teto da linha = floor(teto * 110 / 100).
-- Numeros do fixture eng150: cada item tem tres degraus de 200 unidades a 80%, 90% e 100% do teto; o scan dirigido le a escada.
-- Linha: { id, qtd, teto do fixture, passo do primeiro uso }.
local LINHAS = {
  { 2589, 141, 27, 1 }, { 4357, 133, 14, 1 },
  { 2840, 105, 110, 2 }, { 4359, 17, 120, 2 },
  { 2880, 15, 94, 3 },
  { 2836, 19, 92, 4 },
  { 4364, 130, 97, 5 },
  { 2841, 17, 185, 6 },
  { 4404, 26, 69, 7 },
  { 2838, 48, 354, 8 }, { 2592, 30, 144, 8 },
  { 2319, 6, 120, 9 },
}

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

return {
  id = "rota-03", grupo = "rota",
  descricao = "plano do 1 ao 150: 12 linhas de leilao na ordem do primeiro uso, martelo no vendedor, 9 passos de craft, tetos com tolerancia",
  inicio = __bancada.fixture("eng150", {
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { abrir_leilao = true },
    -- sem scan: o plano existe (sem escada: nenhuma linha) e o botao de acao nao tem o que fazer
    { chamar = function(b)
      b.falso(CompraForeverAcao:IsEnabled(), "sem scan o botao de acao fica desabilitado")
    end },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      local p = ns.plano
      b.verdadeiro(p ~= nil and p.modo == 2, "plano de rota")
      local R = p.rota
      b.igual(R.estado, "ok", "estado ok")
      b.igual(R.prof, "engineering", "slug")
      b.igual(R.pericia, 1, "pericia 1")
      b.igual(R.max, 75, "max 75")
      b.igual(R.alvo, 150, "alvo 150")
      b.igual(R.limite, 150, "limite 150 (nivel 10 deixa o Journeyman)")
      b.igual(p.motivo, "fim", "motivo: fim")
      b.igual(R.chega, 150, "a compra leva ao alvo")
      b.igual(R.proximo, "ah", "proximo: AH")
      b.igual(R.atual, { i = 1, magia = 3919, nome = "Rough Dynamite", de = 1, ate = 59, faltam = 119, encantar = false }, "passo atual")
      b.igual(R.curtos, {}, "nenhum item curto")
      b.falso(R.velho, "fonte nao velha")
      b.igual(R.vender, {}, "nada a vender")
      b.igual(R.reservar, {}, "nada na bolsa para reservar")

      -- passos: crafts da formula (Rough Dynamite 119 do 1; os outros da mesma formula, com o credito do Heavy Blasting Powder)
      local esperado = { { 3919, 1, 59, 119 }, { 3923, 59, 65, 7 }, { 3924, 65, 75, 10 }, { 3929, 75, 91, 19 }, { 3931, 91, 100, 15 },
        { 8334, 100, 105, 5 }, { 3937, 105, 125, 26 }, { 3946, 125, 145, 24 }, { 3953, 145, 150, 6 } }
      b.igual(#R.passos, 9, "9 passos")
      b.igual(#p.crafts, 9, "9 crafts no plano")
      for i, e in ipairs(esperado) do
        local x = R.passos[i]
        b.igual({ x.magia, x.de, x.ate, x.n }, e, "passo " .. i)
        b.igual(x.estado, i == 1 and "agora" or "compra", "estado do passo " .. i)
        local c = p.crafts[i]
        b.igual({ c.magia, c.de, c.ate, c.n }, e, "craft " .. i)
      end

      -- as 12 linhas de leilao, na ordem do primeiro uso
      b.igual(#p.leilao, 12, "12 linhas de leilao")
      local gasto = 0
      for i, l in ipairs(LINHAS) do
        local id, qtd, teto, passo = l[1], l[2], l[3], l[4]
        local r = p.leilao[i]
        local unit = math.floor(teto * 80 / 100)   -- o degrau mais barato do fixture (200 unidades) cobre qualquer linha
        b.igual({ r.id, r.qtd, r.passo }, { id, qtd, passo }, "linha " .. i .. " (id, qtd, passo)")
        b.igual(r.teto, math.floor(teto * 110 / 100), "teto da linha " .. i .. " = floor(teto * 110 / 100)")
        b.igual(r.custo, qtd * unit, "custo da linha " .. i)
        b.igual(r.precoMax, unit, "preco maximo pago na linha " .. i)
        b.falso(r.inteiro, "commodity: linha " .. i .. " nao e lote inteiro")
        gasto = gasto + r.custo
      end

      -- o martelo no vendedor (preco 18 com o desconto da config)
      local desc = ns.config().desconto
      local martelo = math.floor(18 * (100 - desc) / 100)
      b.igual(#p.vendedor, 1, "uma linha de vendedor")
      b.igual(p.vendedor[1], { id = 5956, nome = "Blacksmith Hammer", qtd = 1, custo = martelo, tipo = "ferramenta", passo = 2 }, "martelo")
      gasto = gasto + martelo
      b.igual(p.totais.gasto, gasto, "gasto total")
      b.igual(R.restante, gasto, "restante = gasto (nada na bolsa)")
      b.igual(p.totais.espacos, 42, "pico de espacos: as 42 pilhas que chegam")
      b.igual(p.fabricar, {}, "fabricar vazio")
      b.igual(p.revenda, {}, "revenda vazia")

      -- ids do scan dirigido: os 12 de leilao, ordenados; sem o martelo (vendedor) e sem o Heavy Blasting Powder (fabricado)
      b.igual(R.scan, { 2319, 2589, 2592, 2836, 2838, 2840, 2841, 2880, 4357, 4359, 4364, 4404 }, "ids do scan")

      -- receitas a treinar, por aprende (todas as da rota, menos a inicial)
      local m = {}
      for i, t in ipairs(R.treinar) do m[i] = t.magia end
      b.igual(m, { 3923, 3924, 3929, 3931, 8334, 3937, 3945, 3946, 3953 }, "receitas a treinar")
      b.igual(R.treinar[1], { magia = 3923, nome = "Rough Copper Bomb", custo = 130, aprende = 30, origem = "treinador" }, "primeira a treinar")
      b.igual(R.rank, nil, "Journeyman so quando a pericia chega ao 50")
      b.igual(R.dicas, {}, "Rough Dynamite nao pede foco")

      -- botao de acao: a primeira linha
      b.igual(CompraForeverAcao:GetText(), "Buy 141 Linen Cloth (29s 61c)", "texto do botao de acao")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao de acao habilitado")
    end },
    { avancar = 1 },
    { chamar = function(b)
      tem(b, "NEXT: AH", "NEXT: AH")
      tem(b, "Engineering 1/75 -> 150", "linha da profissao")
      tem(b, "Now Rough Dynamite 1-59: 119 left", "passo atual")
      tem(b, "BUY to 150 (target)", "chega ao alvo")
      tem(b, "141 Linen Cloth <= 29c  29s 61c", "linha de leilao 1")
      tem(b, "133 Rough Blasting Powder <= 15c  14s 63c", "linha de leilao 2")
      tem(b, "48 Heavy Stone <= 3s 89c  1g 35s 84c", "linha do Heavy Stone")
      tem(b, "+1 more", "12 linhas e o resto: o martelo")
      tem(b, "TRAIN Rough Copper Bomb 1s 30c", "dica de treino")
      tem(b, "[CRAFT] 119x Rough Dynamite 1-59", "craft 1")
      tem(b, "[CRAFT] 7x Rough Copper Bomb 59-65", "craft 2")
      tem(b, "[CRAFT] 10x Copper Tube 65-75", "craft 3")
      tem(b, "Spend 4g 93s 90c | left ~4g 93s 90c", "gasto")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
  end,
}
