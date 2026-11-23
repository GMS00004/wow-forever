-- Teto em lotes inteiros (CONTRATO 12.4, passo 6, linha "L"): o Rough Blasting Powder (teto 14, limite floor(14 * 110 / 100) = 15) vira
-- item de leilao (commodity = false), com lotes de 50 a 12, 50 a 14, 30 a 15 e 100 a 16. A rota pede 133; o lote a 16 passa do
-- limite 15 e nao e comprado. Lotes inteiros (a sobra do ultimo lote vai ao estoque):
--   passo 1 usa 119: lotes de 50, 50 e 30 (130 comprados, sobra 11)
--   passo 2 pede 2 por craft: 11 de estoque dao 5 crafts (10); o passo inteiro (7 crafts) pede 14 e so ha o lote de 16 -> falta 3, "preco", cap 15
-- Plano: 119 Rough Dynamite e 5 Rough Copper Bomb (59 -> 63: 1 + 1 + 30/29 + 30/28 + 30/27 = 5,2 > 5 no x = 63), motivo "preco".
-- Todas as receitas da rota conhecidas: sem as dicas TRAIN (que ocupam as 4 dicas do painel antes da linha SHORT).
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

local TODAS = { [3919] = true, [3923] = true, [3924] = true, [3929] = true, [3931] = true, [8334] = true, [3937] = true,
  [3945] = true, [3946] = true, [3953] = true }

return {
  id = "rota-06", grupo = "rota",
  descricao = "teto em lotes inteiros: compra os lotes ate 15, para no degrau de 16, sobra de lote vai ao estoque, linha SHORT",
  inicio = __bancada.fixture("eng150", {
    itens = { [4357] = { nome = "Rough Blasting Powder", vend = 4, pilha = 20, commodity = false } },
    -- item (nao commodity): preco do leilao e o buyout do lote inteiro (600 / 50 = 12 por unidade)
    mercado = { [4357] = { { preco = 600, qtd = 50 }, { preco = 700, qtd = 50 }, { preco = 450, qtd = 30 }, { preco = 1600, qtd = 100 } } },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 1, max = 75, ids = TODAS, n = 10, em = 1 } } },
  }),
  passos = {
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      local p = ns.plano
      local R = p.rota
      b.igual(R.estado, "ok", "estado ok")
      b.igual(p.motivo, "preco", "motivo: preco")
      b.igual(R.chega, 63, "chega ao 63")
      b.igual(#p.crafts, 2, "dois passos no trecho")
      b.igual({ p.crafts[1].magia, p.crafts[1].n }, { 3919, 119 }, "passo 1 inteiro")
      b.igual({ p.crafts[2].magia, p.crafts[2].n }, { 3923, 5 }, "5 crafts do Rough Copper Bomb")
      local po
      for _, l in ipairs(p.leilao) do if l.id == 4357 then po = l end end
      b.verdadeiro(po ~= nil, "linha do Rough Blasting Powder")
      b.igual(po.qtd, 130, "130 comprados (lotes inteiros; sobra 11 para o estoque)")
      b.verdadeiro(po.inteiro, "lote inteiro")
      b.igual(#po.lotes, 3, "tres lotes: o de 16 fica de fora")
      b.igual({ po.lotes[1].preco, po.lotes[1].qtd }, { 12, 50 }, "lote 1")
      b.igual({ po.lotes[2].preco, po.lotes[2].qtd }, { 14, 50 }, "lote 2")
      b.igual({ po.lotes[3].preco, po.lotes[3].qtd }, { 15, 30 }, "lote 3")
      b.igual(po.custo, 50 * 12 + 50 * 14 + 30 * 15, "custo dos tres lotes")
      b.igual(po.precoMax, 15, "preco maximo 15")
      b.igual(po.teto, 15, "teto da linha: floor(14 * 110 / 100)")
      b.igual(R.curtos, { { id = 4357, nome = "Rough Blasting Powder", falta = 3, cap = 15, tipo = "preco" } }, "item curto: o passo inteiro (7 crafts) pede 14, ha 11 no estoque: falta 3 acima do cap 15")
      -- gasto: Linen 124 a 21, Powder 1750, Copper Bar 5 a 88, Bolts 5 a 96, martelo 16
      b.igual(p.totais.gasto, 124 * 21 + 1750 + 5 * 88 + 5 * 96 + 16, "gasto")
    end },
    { avancar = 1 },
    { chamar = function(b)
      tem(b, "BUY to 63 (price)", "linha BUY com o motivo")
      tem(b, "SHORT 3 Rough Blasting Powder > 15c: new estimate", "linha SHORT (vermelha)")
      tem(b, "130 Rough Blasting Powder <= 15c  17s 50c", "linha de leilao do lote inteiro")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
  end,
}
