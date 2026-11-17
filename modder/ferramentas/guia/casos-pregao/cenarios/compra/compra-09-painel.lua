-- Painel: ancora na AH, esconde ao fechar, botao de acao desabilitado sem scan, "Nothing pays now" com plano vazio,
-- linhas e totais com plano, recarga do Full scan em mm:ss e o /compra.
local function textos()
  local out = {}
  for _, r in ipairs({ CompraForeverPainel:GetRegions() }) do
    local t = r:GetText()
    if t and t ~= "" then out[#out + 1] = t end
  end
  return out
end
local function tem(b, lista, trecho, msg)
  for _, t in ipairs(lista) do
    if string.find(t, trecho, 1, true) then return true end
  end
  b.verdadeiro(false, msg .. " (texto '" .. trecho .. "' nao achado em: " .. table.concat(lista, " | ") .. ")")
  return false
end

return {
  id = "compra-09", grupo = "compra",
  descricao = "painel: ancora na AH, esconde, acao desabilitada sem scan, Nothing pays now, plano com linhas e totais, recarga do Full",
  inicio = {
    dinheiro = 51400,
    itens = {
      [4461] = { nome = "Raptor Hide", vend = 208, pilha = 10 },
      [4234] = { nome = "Heavy Leather", vend = 150, pilha = 20 },
      [2321] = { nome = "Fine Thread", vend = 25, pilha = 20 },
      [4455] = { nome = "Raptor Hide Harness", vend = 3096, pilha = 1 },
    },
    receitas = {
      [4096] = { nome = "Raptor Hide Harness", produto = 4455, qtd = 1, reagentes = { { 4461, 6 }, { 4234, 4 }, { 2321, 2 } } },
    },
    sv_char = { conhecidas = { quem = "Hexumlite", em = 1, ids = { [4096] = true }, n = 1 } },
  },
  passos = {
    { chamar = function(b)
      b.falso(CompraForeverPainel:IsShown(), "painel escondido sem janela aberta")
      b.igual(CompraForeverPainel:GetWidth(), 300, "300 de largura")
    end },
    { abrir_leilao = true },
    { chamar = function(b)
      b.verdadeiro(CompraForeverPainel:IsShown(), "painel aparece com a AH")
      local pt, rel, relPonto, x, y = CompraForeverPainel:GetPoint(1)
      b.igual({ pt, rel == AuctionHouseFrame, relPonto, x, y }, { "TOPLEFT", true, "TOPRIGHT", 4, 0 }, "ancorado na AH")
      b.falso(CompraForeverAcao:IsEnabled(), "sem scan o botao de acao fica desabilitado")
      b.verdadeiro(CompraForeverScan:IsEnabled(), "Scan habilitado com a AH aberta")
      b.igual(CompraForeverScan:GetText(), "Scan", "texto do Scan")
      b.igual(CompraForeverFull:GetText(), "Full scan", "texto do Full")
      b.verdadeiro(CompraForeverFull:IsEnabled(), "Full habilitado")
      tem(b, textos(), "Money 5g 14s", "dinheiro")
      tem(b, textos(), "Bags free 80", "bolsas livres")
      tem(b, textos(), "No scan yet", "sem scan")
    end },
    { fechar_leilao = true },
    { chamar = function(b)
      b.falso(CompraForeverPainel:IsShown(), "painel some com a AH fechada")
      b.falso(CompraForeverScan:IsEnabled(), "Scan desabilitado sem AH")
    end },
    -- plano vazio: scan sem anuncios e sem estoque
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { chamar = function(b)
      b.falso(CompraForeverScan:IsEnabled(), "Scan desabilitado durante a busca")
    end },
    { avancar = 1 },
    { chamar = function(b)
      tem(b, textos(), "Scanning", "progresso do scan")
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      tem(b, textos(), "Nothing pays now", "plano vazio")
      tem(b, textos(), "Scan ", "hora e tipo do scan")
      tem(b, textos(), "targeted", "tipo do scan")
      b.falso(CompraForeverAcao:IsEnabled(), "sem acao")
      b.verdadeiro(CompraForeverScan:IsEnabled(), "Scan volta")
    end },
    -- plano com compras: anuncios novos, estoque nas bolsas, outro scan
    { chamar = function(b)
      __bancada.A.mercado[4461] = { { id = 7001, preco = 130, qtd = 8 }, { id = 7002, preco = 160, qtd = 100 } }
    end },
    { injetar = { "bolsa_trocada", 0, 1, 4234, 8 } },
    { injetar = { "bolsa_trocada", 0, 2, 2321, 4 } },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local t = textos()
      tem(b, t, "2x Raptor Hide Harness +41s 52c", "linha do craft")
      tem(b, t, "12 Raptor Hide <= 1s 60c  16s 80c", "linha da compra")
      tem(b, t, "Spend 16s 80c, profit +41s 52c", "totais")
      b.verdadeiro(CompraForeverPainel:IsShown(), "painel ainda visivel")
      b.igual(CompraForeverAcao:GetText(), "Buy 12 Raptor Hide (16s 80c)", "texto do botao de acao")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "acao habilitada")
    end },
    -- recarga do Full scan
    { clique = "CompraForeverFull" },
    { ate_ocioso = true },
    { chamar = function(b)
      local t = CompraForeverFull:GetText()
      b.verdadeiro(string.find(t, "^Full scan 1[45]:%d%d$") ~= nil, "recarga em mm:ss: " .. tostring(t))
      b.falso(CompraForeverFull:IsEnabled(), "Full desabilitado na recarga")
    end },
    { avancar = 901 },
    { chamar = function(b)
      b.igual(CompraForeverFull:GetText(), "Full scan", "recarga acabou")
      b.verdadeiro(CompraForeverFull:IsEnabled(), "Full habilitado")
    end },
    -- /compra esconde e mostra
    { chamar = function(b)
      SlashCmdList.COMPRAFOREVER("")
      b.falso(CompraForeverPainel:IsShown(), "/compra esconde")
      SlashCmdList.COMPRAFOREVER("")
      b.verdadeiro(CompraForeverPainel:IsShown(), "/compra mostra")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
