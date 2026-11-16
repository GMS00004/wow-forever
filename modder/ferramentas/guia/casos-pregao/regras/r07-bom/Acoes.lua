local _, ns = ...
function ns.tecla_postar(item, tipo)
  if not Cofre.autoriza("postar") then return end
  if not Livro.intencao("postar") then return end
  if tipo == "item" then
    C_AuctionHouse.PostItem(item, 2, 1, 100, 200)
  else
    C_AuctionHouse.PostCommodity(item, 2, 5, 100)
  end
end
