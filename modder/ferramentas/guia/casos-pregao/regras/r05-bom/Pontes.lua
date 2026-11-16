local _, ns = ...
function ns.precoTSM(item)
  local ok, valor = pcall(function() return TSM_API.GetCustomPriceValue("DBMarket", item) end)
  if ok then return valor end
end
