-- Reproduz o que o cliente real fez em 2026-11-16 (SavedVariables das 18:04): comprar um item pela tela da Blizzard
-- disparou AUCTION_HOUSE_PURCHASE_COMPLETED antes do PLAYER_MONEY e, no mesmo segundo, AUCTION_CANCELED para o mesmo
-- leilao. O Livro tem de ter uma compra com o valor pago e nenhum cancelamento; a S9 nao pode contar "canceled".
return {
  id = "livro-15", grupo = "unid-livro",
  descricao = "compra por fora: eco antes do dinheiro e cancelado do leilao comprado nao vira cancelamento",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 56580 },
  passos = {
    { avancar = 1 },
    { abrir_leilao = true },
    { avancar = 1 },
    { evento = { "AUCTION_HOUSE_PURCHASE_COMPLETED", 777001 } },
    { injetar = { "dinheiro_muda", -300 } },
    { evento = { "AUCTION_CANCELED", 777001 } },
    { avancar = 3 },
  },
  conferir = function(b)
    local p = b.db().pers.Hexumlite
    local compras, cancelamentos, valor = 0, 0, nil
    for _, l in ipairs(p.livro or {}) do
      local a = b.ns.banco.dec.acao(l)
      if a and a.verbo == "buy" then compras = compras + 1; valor = a.antes - a.depois end
      if a and a.verbo == "cancel" then cancelamentos = cancelamentos + 1 end
    end
    b.igual(compras, 1, "uma compra")
    b.igual(valor, 300, "a compra registra os 3 prata pagos, mesmo com o eco antes do PLAYER_MONEY")
    b.igual(cancelamentos, 0, "o cancelado do leilao comprado nao vira cancelamento")
    local s9 = b.db().sonda and b.db().sonda.S9
    b.verdadeiro(s9 == nil or string.find(s9, "canceled", 1, true) == nil, "a S9 nao conta o cancelado da compra: " .. tostring(s9))
    b.igual(#b.erros(), 0, "nenhum erro de Lua")
  end,
}
