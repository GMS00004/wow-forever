local _, ns = ...
function ns.tecla_postar(item)
  if not Cofre.autoriza("postar") then return end
  if not Livro.intencao("postar") then return end
  C_AuctionHouse.PostItem(item, 2, 1, 100, 200)
end
function ns.ciclo()
  ns.tecla_postar(nil)
end
