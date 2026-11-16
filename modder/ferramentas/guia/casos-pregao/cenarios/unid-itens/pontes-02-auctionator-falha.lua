-- Pontes.auctionator: com o Auctionator presente (falso desta cena), a leitura certa devolve preco e idade; a API que falha devolve nil sem erro de Lua.
return {
  id = "pontes-02-auctionator-falha", grupo = "unid-itens",
  descricao = "Auctionator falso: leitura por itemID; API que erra vira nil",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0 },
  passos = {
    { chamar = function(b)
        Auctionator = { API = { v1 = {
          GetAuctionPriceByItemID = function(quem, id)
            if quem ~= 'P' then return nil end
            if id == 2589 then return 9 end
            error('falso: id sem preco')
          end,
          GetAuctionAgeByItemID = function(quem, id) return 0 end,
        } } }
        b.__ok = b.ns.pontes.auctionator(2589)
        b.__falha = b.ns.pontes.auctionator(4234)
        b.__sufixo = b.ns.pontes.auctionator('6541:18:845')
      end },
  },
  conferir = function(b)
    b.igual(b.__ok, { preco = 9, idadeDias = 0 }, 'preco e idade por itemID')
    b.igual(b.__falha, nil, 'a API que falha: nil, sem erro de Lua')
    b.igual(b.__sufixo, nil, 'chave com sufixo nao passa pela API: nil')
    b.igual(#b.erros(), 0, 'o erro da API ficou dentro do pcall')
    b.igual(#b.violacoes(), 0, 'sem violacao')
  end,
}
