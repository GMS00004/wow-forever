-- Pontes.lua (PregaoForever): conversa com addons de terceiro so por pcall (regra 5, secao 14). Com o addon ausente, ou a chamada falhando, devolve nil e o resto do addon segue. Publica ns.pontes. Onda 2.
-- So o Auctionator tem chamada: a parte que o CONTRATO.md da outra frente comprova no jogo. Syndicator e ElvUI ficam sem chamada: a assinatura se le no jogo por /dump, com o dono (secao 14).
local _, ns = ...
ns.pontes = ns.pontes or {}
local P = ns.pontes

-- Auctionator: Auctionator.API.v1.GetAuctionPriceByItemID(quem, itemID) e GetAuctionAgeByItemID(quem, itemID).
-- "P" e o identificador de quem chama, o mesmo que a exportacao conferida no jogo usou.
-- So commodity: a API conhecida recebe o itemID; chave com sufixo nao foi conferida, entao devolve nil.
-- Devolve { preco = cobre por unidade, idadeDias = dias } ou nil.
function P.auctionator(chave)
  local texto = tostring(chave)
  if string.find(texto, ':', 1, true) then return nil end
  local id = tonumber(texto)
  if not id then return nil end
  local ok, preco, idade = pcall(function()
    local api = Auctionator.API.v1
    return api.GetAuctionPriceByItemID('P', id), api.GetAuctionAgeByItemID('P', id)
  end)
  if not ok or type(preco) ~= 'number' then return nil end
  return { preco = preco, idadeDias = (type(idade) == 'number') and idade or nil }
end

-- Syndicator: sem chamada ainda. Assinatura a ler no jogo por /dump, com o dono.
function P.syndicator(chave)
  return nil
end

-- ElvUI: sem chamada ainda. Assinatura a ler no jogo por /dump, com o dono.
function P.elvui(quadro)
  return nil
end
