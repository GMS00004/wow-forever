-- Brinquedo: as consultas ao leilao e a leitura do correio. Cada funcao e chamada por um botao ou pelo cenario.
local _, ns = ...
local br = ns.brinquedo

function br.consultaBrowse()
  C_AuctionHouse.SendBrowseQuery({ searchString = "", sorts = {}, filters = {} })
end
function br.maisBrowse() C_AuctionHouse.RequestMoreBrowseResults() end
function br.consultaCommodity(id) C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(id), {}, true) end
function br.maisCommodity(id) C_AuctionHouse.RequestMoreCommoditySearchResults(id) end
function br.consultaItem(itemKey) C_AuctionHouse.SendSearchQuery(itemKey, {}, true) end
function br.proprios() C_AuctionHouse.QueryOwnedAuctions({}) end

-- uma acao (as 8 funcoes de acao so tem efeito dentro de clique de botao PregaoForever*)
function br.acaoPostar()
  local loc = ItemLocation:CreateFromBagAndSlot(0, 1)
  return C_AuctionHouse.PostCommodity(loc, 2, 1, 10)
end
function br.acaoDupla()
  br.acaoPostar()
  C_AuctionHouse.CancelAuction(1)
end

-- correio: devolve os retornos crus da fatura da carta i, e quantos eram
function br.fatura(i)
  local r = { GetInboxInvoiceInfo(i) }
  return r, select("#", GetInboxInvoiceInfo(i))
end
function br.cabecalho(i) return { GetInboxHeaderInfo(i) } end
