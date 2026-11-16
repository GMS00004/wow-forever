-- Brinquedo da bancada do PregaoForever: registra eventos, guarda um registro deles e grava algo no SV.
-- Lua 5.1 no subconjunto comum com a 5.3. So ASCII.
local _, ns = ...
ns.brinquedo = ns.brinquedo or {}
local br = ns.brinquedo

br.log = {}      -- eventos que o quadro recebeu: { nome, args, n }
br.resumo = {}   -- linhas do resumo acumuladas (GetBrowseResults uma vez; ADDED soma)
br.paginas = 0
br.auto = false  -- se verdadeiro, pede a pagina seguinte do resumo enquanto nao estiver completo

local EVENTOS = {
  "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT", "PLAYER_MONEY",
  "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "BAG_UPDATE", "ITEM_DATA_LOAD_RESULT",
  "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED",
  "AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED", "AUCTION_HOUSE_THROTTLED_MESSAGE_SENT",
  "AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED", "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED",
  "AUCTION_HOUSE_THROTTLED_SYSTEM_READY", "AUCTION_HOUSE_NEW_RESULTS_RECEIVED",
  "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_ADDED", "AUCTION_HOUSE_BROWSE_FAILURE",
  "COMMODITY_SEARCH_RESULTS_UPDATED", "COMMODITY_SEARCH_RESULTS_ADDED",
  "ITEM_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_ADDED", "OWNED_AUCTIONS_UPDATED",
  "AUCTION_HOUSE_AUCTION_CREATED", "AUCTION_CANCELED", "AUCTION_HOUSE_PURCHASE_COMPLETED", "AUCTION_HOUSE_SHOW_ERROR",
  "COMMODITY_PRICE_UPDATED", "COMMODITY_PRICE_UNAVAILABLE", "COMMODITY_PURCHASE_SUCCEEDED", "COMMODITY_PURCHASED",
  "COMMODITY_PURCHASE_FAILED", "MAIL_SHOW", "MAIL_INBOX_UPDATE",
}

local quadro = CreateFrame("Frame", "PregaoForeverBrinquedoQuadro")
br.quadro = quadro
for i = 1, #EVENTOS do quadro:RegisterEvent(EVENTOS[i]) end

quadro:SetScript("OnEvent", function(self, ev, ...)
  br.log[#br.log + 1] = { nome = ev, args = { ... }, n = select("#", ...) }
  if ev == "ADDON_LOADED" then
    if (...) ~= "PregaoForever" then return end
    PregaoForeverDB = PregaoForeverDB or {}
    PregaoForeverDB.cargas = (PregaoForeverDB.cargas or 0) + 1
    PregaoForeverDB.marca = PregaoForeverDB.marca or "primeira"
    PregaoForeverCharDB = PregaoForeverCharDB or {}
    PregaoForeverCharDB.pers = GetUnitName("player")
  elseif ev == "PLAYER_LOGOUT" then
    PregaoForeverDB.saidas = (PregaoForeverDB.saidas or 0) + 1
  elseif ev == "AUCTION_HOUSE_SHOW" then
    if not InCombatLockdown() then SetOverrideBindingClick(quadro, true, "L", "PregaoForeverTeclaL") end
  elseif ev == "AUCTION_HOUSE_CLOSED" then
    if not InCombatLockdown() then ClearOverrideBindings(quadro) end
  elseif ev == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then
    br.resumo = C_AuctionHouse.GetBrowseResults()
    br.paginas = 1
    if br.auto and not C_AuctionHouse.HasFullBrowseResults() then C_AuctionHouse.RequestMoreBrowseResults() end
  elseif ev == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
    local add = ...
    for i = 1, #add do br.resumo[#br.resumo + 1] = add[i] end
    br.paginas = br.paginas + 1
    if br.auto and not C_AuctionHouse.HasFullBrowseResults() then C_AuctionHouse.RequestMoreBrowseResults() end
  end
end)
