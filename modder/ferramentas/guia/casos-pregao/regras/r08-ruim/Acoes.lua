local _, ns = ...
function ns.tecla_postar(item)
  C_AuctionHouse.PostItem(item, 2, 1, 100, 200)
  if not Cofre.autoriza("postar") then return end
  if not Livro.intencao("postar") then return end
end
