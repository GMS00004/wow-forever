-- SendBrowseQuery dispara a sequencia nominal do DESIGN (secao 16) e o addon a recebe inteira, na mesma ordem.
local function seq(lista, padrao)
  local t = {}
  for _, e in ipairs(lista) do
    if string.find(e.nome, padrao) then t[#t + 1] = e.nome end
  end
  return t
end

return {
  id = "auto-01", grupo = "autoteste",
  descricao = "SendBrowseQuery: QUEUED, SENT, RESPONSE_RECEIVED, NEW_RESULTS_RECEIVED(nil), BROWSE_RESULTS_UPDATED, SYSTEM_READY",
  inicio = {
    dinheiro = 40000,
    mercado = {
      ["2589"] = { { preco = 9, qtd = 14, donos = 2 }, { preco = 11, qtd = 40, donos = 1 } },
      ["2592"] = { { preco = 35, qtd = 5, donos = 1 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { avancar = 1 },
    { tecla = "L" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    local esperado = {
      "AUCTION_HOUSE_SHOW",
      "AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED", "AUCTION_HOUSE_THROTTLED_MESSAGE_SENT",
      "AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED", "AUCTION_HOUSE_NEW_RESULTS_RECEIVED",
      "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_THROTTLED_SYSTEM_READY",
    }
    b.igual(seq(b.eventos(), "^AUCTION_HOUSE_"), esperado, "sequencia dos eventos disparados pelo falso")
    -- o addon do brinquedo recebeu a mesma sequencia
    b.igual(seq(b.ns.brinquedo.log, "^AUCTION_HOUSE_"), esperado, "sequencia recebida pelo addon")
    for _, e in ipairs(b.eventos("AUCTION_HOUSE_NEW_RESULTS_RECEIVED")) do b.igual(e.n, 0, "NEW_RESULTS_RECEIVED sem payload") end
    b.igual(b.contar("SendBrowseQuery"), 1, "uma chamada de SendBrowseQuery")
    b.igual(#b.chamadas("SendBrowseQuery"), 1, "um registro de SendBrowseQuery")
    b.verdadeiro(b.chamadas("SendBrowseQuery")[1].t >= 1, "a chamada veio depois do avancar 1")
    b.igual(#b.ns.brinquedo.resumo, 2, "o resumo trouxe os 2 itens")
    b.igual(b.ns.brinquedo.resumo[1].totalQuantity, 54, "quantidade total do primeiro item")
    b.igual(b.ns.brinquedo.resumo[1].minPrice, 9, "menor preco do primeiro item")
    b.verdadeiro(C_AuctionHouse.IsThrottledMessageSystemReady(), "throttle pronto no fim")
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.db().cliques, 1, "o clique do botao PregaoForeverTeclaL gravou no SV")
  end,
}
