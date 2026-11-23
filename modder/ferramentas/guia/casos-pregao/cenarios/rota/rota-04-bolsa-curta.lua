-- Bolsa curta (CONTRATO 12.4, passo 6): 2 espacos por bolsa = 10 livres, pico permitido = espacos - 2 = 8. So o comeco do passo 1 cabe:
-- k crafts do Rough Dynamite pedem k Linen Cloth + k Rough Blasting Powder (ceil(k/20) pilhas cada) e dao 2k Rough Dynamite
-- (ceil(k/10) pilhas, depois de consumir). Cabe enquanto 2 * ceil(k/20) <= 8 e ceil(k/10) <= 8: k = 80. Com 80 crafts a chance
-- do 1 ao 29 e 1 e depois cai ate 59 (amarela 30, cinza 60): a pericia chega a 54 (formula do 12.4, rAvancar).
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
  id = "rota-04", grupo = "rota",
  descricao = "bolsa curta (10 espacos): so o comeco do passo 1 (80 crafts), motivo espaco, chega ao 54, nenhum passo seguinte",
  inicio = __bancada.fixture("eng150", {
    parametros = { tamanho_bolsa = 2 },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { abrir_leilao = true },
    { chamar = function(b) b.igual(b.ns.espacosLivres(), 10, "10 espacos livres") end },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      local p = ns.plano
      local R = p.rota
      b.igual(R.estado, "ok", "estado ok")
      b.igual(p.motivo, "espaco", "motivo: espaco")
      b.igual(R.chega, 54, "a compra leva a pericia ao 54")
      b.igual(R.atual.faltam, 119, "o passo atual ainda precisa dos 119 crafts")
      b.igual(#p.crafts, 1, "so um passo no trecho de compra")
      b.igual({ p.crafts[1].magia, p.crafts[1].n, p.crafts[1].de }, { 3919, 80, 1 }, "80 crafts do Rough Dynamite")
      b.igual(#p.leilao, 2, "duas linhas de leilao")
      b.igual({ p.leilao[1].id, p.leilao[1].qtd, p.leilao[1].custo, p.leilao[1].passo }, { 2589, 80, 80 * 21, 1 }, "80 Linen Cloth a 21")
      b.igual({ p.leilao[2].id, p.leilao[2].qtd, p.leilao[2].custo, p.leilao[2].passo }, { 4357, 80, 80 * 11, 1 }, "80 Rough Blasting Powder a 11")
      b.igual(#p.vendedor, 0, "o martelo e do passo 2: fica de fora")
      b.igual(p.totais.gasto, 80 * 21 + 80 * 11, "gasto")
      b.igual(p.totais.espacos, 8, "pico de 8 espacos (o limite: 10 - 2)")
      b.igual(R.curtos, {}, "sem item curto (o limite foi espaco)")
      b.igual(R.passos[1].estado, "agora", "passo 1 agora")
      for i = 2, 9 do b.igual(R.passos[i].estado, "depois", "passo " .. i .. " depois") end
      b.igual(R.restante, 49390, "o restante e o da rota inteira")
      b.igual(R.proximo, "ah", "proximo: AH")
      b.igual(CompraForeverAcao:GetText(), "Buy 80 Linen Cloth (16s 80c)", "botao: a primeira linha")
    end },
    { avancar = 1 },
    { chamar = function(b)
      tem(b, "BUY to 54 (bags)", "linha BUY com o motivo")
      tem(b, "[CRAFT] 80x Rough Dynamite", "craft no painel")
      tem(b, "80 Linen Cloth <= 29c  16s 80c", "linha de leilao")
    end },
    { chamar = function(b) b.igual(b.contar("StartCommoditiesPurchase"), 0, "o plano nao compra sozinho") end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
  end,
}
