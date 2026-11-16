local _, ns = ...
function ns.precoTSM(item)
  return TSM_API.GetCustomPriceValue("DBMarket", item)
end
