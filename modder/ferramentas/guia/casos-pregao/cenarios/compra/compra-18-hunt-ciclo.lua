-- Caca (secao 13): o mercado do print do dono (26/11/2026). Isca sozinha nao dispara; pilha no alvo dispara e leva a
-- isca mais barata junto; compra em dois cliques e busca encadeada; outro comprou antes: cancela e busca; trava.
local function textos()
  local out = {}
  for _, r in ipairs({ CompraForeverPainel:GetRegions() }) do
    local t = r:GetText()
    if t and t ~= "" then out[#out + 1] = t end
  end
  return out
end
local function tem(b, trecho, msg)
  local lista = textos()
  for _, t in ipairs(lista) do
    if string.find(t, trecho, 1, true) then return end
  end
  b.verdadeiro(false, msg .. " (texto '" .. trecho .. "' nao achado em: " .. table.concat(lista, " | ") .. ")")
end

return {
  id = "compra-18", grupo = "compra",
  descricao = "caca: isca de 1 ou 2 nao dispara, pilha no alvo compra tudo ate ela, dois cliques, busca encadeada, cotacao acima cancela e busca, trava",
  inicio = {
    dinheiro = 100000,
    itens = {
      [4304] = { nome = "Thick Leather", vend = 70, pilha = 20 },
    },
    mercado = {
      ["4304"] = { { id = 9001, preco = 400, qtd = 1 }, { id = 9002, preco = 650, qtd = 1 }, { id = 9003, preco = 685, qtd = 736 },
                   { id = 9004, preco = 698, qtd = 2 }, { id = 9005, preco = 699, qtd = 272 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
      SlashCmdList.COMPRAFOREVER("hunt 4304 5s20c 10g")
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Hunt Thick Leather <= 5s 20c", "botao de busca")
      tem(b, "HUNT Thick Leather <= 5s 20c  (lots of 3+)", "linha da caca")
      tem(b, "Click to search", "sem busca ainda")
      b.igual(b.contar("SendSearchQuery"), 0, "nada sem clique")
    end },
    -- clique 1: busca; so a isca de 1 a 4s esta no alvo
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("SendSearchQuery"), 1, "uma busca no clique")
      b.igual(CompraForeverAcao:GetText(), "Hunting Thick Leather...", "texto durante a busca")
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Hunt Thick Leather <= 5s 20c", "isca sozinha nao dispara")
      tem(b, "Now 4s x1, 6s 50c x1, 6s 85c x736, 6s 98c x2, 6s 99c x272", "escada na tela")
      b.igual(b.contar("StartCommoditiesPurchase"), 0, "nada cotado")
    end },
    -- os robos cobrem a isca: 80 a 5s 19c
    { chamar = function(b)
      table.insert(__bancada.A.mercado[4304], 2, { id = 9010, preco = 519, qtd = 80 })
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("SendSearchQuery"), 2, "segunda busca")
      b.igual(CompraForeverAcao:GetText(), "Buy 81 Thick Leather (4g 19s 20c) [HUNT]", "pilha no alvo: leva a isca de baixo junto")
    end },
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "um Start")
      b.igual(b.chamadas("StartCommoditiesPurchase")[1].args[2], 81, "Start de 81")
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 0, "nada confirmado no clique de cotar")
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Confirm 81 Thick Leather (4g 19s 20c)", "Confirm")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      local c = CompraForeverCharDB.caca
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 1, "um Confirm")
      b.igual(GetMoney(), 100000 - 41920, "dinheiro")
      b.igual(c.qtd, 81, "qtd da caca")
      b.igual(c.gasto, 41920, "gasto da caca")
      b.igual(#c.log, 1, "uma compra no registro")
      b.igual(b.contar("SendSearchQuery"), 3, "busca encadeada depois da compra")
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Hunt Thick Leather <= 5s 20c", "sobrou so acima do alvo")
      tem(b, "Bought 81 avg 5s 18c | spent 4g 19s 20c of 10g", "media na tela")
      b.igual(b.ns.sessao.comprado[4304], 81, "comprado na sessao")
    end },
    -- outro comprou antes: a busca mostra 50 a 5s 10c, a cotacao acha 50 a 5s 15c
    { chamar = function(b)
      table.insert(__bancada.A.mercado[4304], 1, { id = 9020, preco = 510, qtd = 50 })
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Buy 50 Thick Leather (2g 55s) [HUNT]", "50 a 5s 10c")
      table.remove(__bancada.A.mercado[4304], 1)
      table.insert(__bancada.A.mercado[4304], 1, { id = 9021, preco = 515, qtd = 50 })
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 2, "segundo Start")
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 1, "nada confirmado acima do visto")
      b.igual(b.contar("SendSearchQuery"), 5, "cotacao acima: busca de novo, encadeada")
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Buy 50 Thick Leather (2g 57s 50c) [HUNT]", "a nova pilha a 5s 15c")
    end },
    -- trava: 5g com 4g 19s 20c gastos deixa 80s 80c, ou 15 unidades a 5s 15c
    { chamar = function(b)
      SlashCmdList.COMPRAFOREVER("hunt 4304 5s20c 5g")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Buy 15 Thick Leather (77s 25c) [HUNT]", "trava corta a quantidade")
      SlashCmdList.COMPRAFOREVER("hunt 4304 5s20c 4g")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Hunt cap reached (4g 19s 20c of 4g)", "trava estourada")
      b.falso(CompraForeverAcao:IsEnabled(), "botao parado na trava")
    end },
    -- busca velha nao cota: depois de 10 s o clique busca de novo
    { chamar = function(b)
      SlashCmdList.COMPRAFOREVER("hunt 4304 5s20c 10g")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 12 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Hunt Thick Leather <= 5s 20c", "escada velha: volta a buscar")
      SlashCmdList.COMPRAFOREVER("hunt off")
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "caca desligada: botao volta ao normal")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao (toda busca no rastro de um clique)")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
