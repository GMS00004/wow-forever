-- Dinheiro curto (CONTRATO 12.4, passo 6): 6000 de cobre. Precos do fixture: o degrau mais barato de cada item (200 unidades) a 80% do teto.
--   passo 1 (119 Rough Dynamite): 119 Linen (21) + 119 Rough Blasting Powder (11)                      = 2499 + 1309 = 3808
--   passo 2 (7 Rough Copper Bomb): 7 Copper Bar (88) + 7 Bolts (96) + 14 Powder (11) + 7 Linen (21) + martelo 16 = 1605  -> 5413
--   passo 3 (Copper Tube): por craft 2 Copper Bar (176) + 1 Weak Flux (75) = 251; (6000 - 5413) / 251 = 2,3 -> 2 crafts (502)
-- Gasto final 5915, pericia 65 + 2 crafts (chance 1 de 65 a 80) = 67, motivo dinheiro.
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
  id = "rota-05", grupo = "rota",
  descricao = "dinheiro curto (6000c): prefixo da rota (passos 1 e 2 e 2 crafts do 3), gasto 5915 dentro do dinheiro, motivo dinheiro",
  inicio = __bancada.fixture("eng150", {
    dinheiro = 6000,
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
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
      b.igual(p.motivo, "dinheiro", "motivo: dinheiro")
      b.igual(R.chega, 67, "chega ao 67")
      b.igual(#p.crafts, 3, "tres passos no trecho de compra")
      b.igual({ p.crafts[1].magia, p.crafts[1].n }, { 3919, 119 }, "passo 1 inteiro")
      b.igual({ p.crafts[2].magia, p.crafts[2].n }, { 3923, 7 }, "passo 2 inteiro")
      b.igual({ p.crafts[3].magia, p.crafts[3].n }, { 3924, 2 }, "2 crafts do Copper Tube")
      b.igual(p.totais.gasto, 5915, "gasto")
      b.verdadeiro(p.totais.gasto <= GetMoney(), "gasto dentro do dinheiro")
      local linhas = {}
      for _, l in ipairs(p.leilao) do linhas[l.id] = l.qtd end
      b.igual(linhas, { [2589] = 126, [4357] = 133, [2840] = 11, [4359] = 7, [2880] = 2 }, "quantidades por item")
      b.igual(#p.leilao, 5, "cinco linhas de leilao")
      b.igual(#p.vendedor, 1, "o martelo entra (passo 2)")
      b.igual(p.vendedor[1].id, 5956, "martelo")
      b.igual(R.passos[1].estado, "agora", "passo 1 agora")
      b.igual(R.passos[2].estado, "compra", "passo 2 compra")
      b.igual(R.passos[3].estado, "compra", "passo 3 compra (parcial)")
      b.igual(R.passos[4].estado, "depois", "passo 4 depois")
      b.igual(R.restante, 49390, "o restante e o da rota inteira")
      b.igual(R.curtos, {}, "sem item curto: o limite foi o dinheiro")
    end },
    { avancar = 1 },
    { chamar = function(b)
      tem(b, "BUY to 67 (money)", "linha BUY com o motivo")
      tem(b, "Spend 59s 15c | left ~4g 93s 90c", "gasto do trecho e restante")
      tem(b, "[CRAFT] 2x Copper Tube 65-75", "craft parcial")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
  end,
}
