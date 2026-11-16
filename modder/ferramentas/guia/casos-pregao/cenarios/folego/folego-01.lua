-- Ponta a ponta (todos os modulos): nada consulta antes do L; um L abre um folego completo e grava as fotos no banco.
local function nfotos(b, chave)
  local casa = b.ns.banco.casa()
  local f = casa.fotos and casa.fotos[chave]
  if type(f) ~= "table" then return 0 end
  if f.itens then return #f:itens() end
  return #f
end
return {
  id = "folego-01", grupo = "folego",
  descricao = "abrir o leilao e esperar nao consulta; o L abre um folego: proprios, resumo, buscas do piso; fotos gravadas",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    bolsas = { { bolsa = 0, slot = 1, itemID = 2589, qtd = 20 } },
    mercado = {
      ["2589"] = { { preco = 9, qtd = 14, donos = 2 }, { preco = 10, qtd = 200, donos = 3 } },
      ["2592"] = { { preco = 30, qtd = 5 } },
      ["4306"] = { { preco = 200, qtd = 3 } },
    } },
  passos = {
    { abrir_leilao = true },
    { avancar = 30 },
    { chamar = function(b)
        local n = 0
        for _, nome in ipairs({ "SendBrowseQuery", "RequestMoreBrowseResults", "SendSearchQuery", "SendSellSearchQuery",
          "RefreshCommoditySearchResults", "RefreshItemSearchResults", "RequestMoreCommoditySearchResults",
          "RequestMoreItemSearchResults", "QueryOwnedAuctions" }) do n = n + b.contar(nome) end
        b.__antes = n
      end },
    { tecla = "L" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.__antes, 0, "nada consultou antes do L")
    b.igual(b.contar("QueryOwnedAuctions"), 1, "proprios uma vez")
    b.igual(b.contar("SendBrowseQuery"), 1, "resumo uma vez")
    b.verdadeiro(b.contar("SendSearchQuery") >= 2, "buscas do foco (2589 das bolsas e 2592 do piso)")
    b.verdadeiro(nfotos(b, "2589") >= 1, "foto de 2589 gravada no banco")
    b.verdadeiro(nfotos(b, "2592") >= 1, "foto de 2592 gravada no banco")
    b.igual(b.ns.varredura.estado().fase, "PARADO", "varredura parada no fim")
    b.igual(b.ns.pedidos.estado().fase, "PARADO", "pedidos parado no fim")
    b.igual(#b.violacoes(), 0, "sem violacao (I9 incluido)")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
