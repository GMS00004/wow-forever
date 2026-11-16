local _, ns = ...
local banco = PregaoForeverDB or {}
local function registrar(seller)
  banco.ultimo = seller
end
