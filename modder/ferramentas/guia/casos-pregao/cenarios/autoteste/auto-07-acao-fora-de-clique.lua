-- Funcao de acao fora de clique de botao PregaoForever*: nao faz nada e conta violacao (inclusive de botao com outro nome).
return {
  id = "auto-07", grupo = "autoteste",
  descricao = "acao fora de clique (e em clique de botao sem o prefixo) conta violacao e nao tem efeito",
  aceita_violacoes = true,
  inicio = {
    dinheiro = 40000,
    bolsas = { { bolsa = 0, slot = 1, itemID = 2589, qtd = 20 } },
  },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b) b.ns.brinquedo.acaoPostar() end },            -- fora de qualquer clique
    { clique = "BrinquedoOutroBotao" },                                    -- clique de botao sem o prefixo
    { ate_ocioso = true },
  },
  conferir = function(b)
    local v = b.violacoes()
    b.igual(#v, 2, "duas violacoes")
    b.igual(v[1].tipo, "hardware", "a primeira e de hardware")
    b.igual(v[2].tipo, "hardware", "a segunda tambem")
    b.igual(b.contar("PostCommodity"), 2, "as duas chamadas ficam registradas")
    b.igual(#b.eventos("AUCTION_HOUSE_AUCTION_CREATED"), 0, "nenhum leilao criado")
    b.igual(GetMoney(), 40000, "dinheiro intacto")
    b.igual(C_Item.GetStackCount(ItemLocation:CreateFromBagAndSlot(0, 1)), 20, "bolsa intacta")
    b.igual(C_AuctionHouse.GetNumOwnedAuctions(), 0, "sem leilao proprio")
  end,
}
