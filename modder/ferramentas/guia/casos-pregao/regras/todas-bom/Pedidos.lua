local _, ns = ...
function ns.pedirVenda(texto)
  C_AuctionHouse.SendSellSearchQuery(texto)
end
