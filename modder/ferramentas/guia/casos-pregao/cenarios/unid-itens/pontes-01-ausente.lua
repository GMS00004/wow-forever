-- Pontes: com nenhum addon de terceiro carregado, cada ponte devolve nil e nada da erro de Lua.
return {
  id = "pontes-01-ausente", grupo = "unid-itens",
  descricao = "Auctionator, Syndicator e ElvUI ausentes: nil sem erro",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0 },
  passos = {
    { avancar = 1 },
    { chamar = function(b)
        b.__r = {
          a1 = b.ns.pontes.auctionator(2589),
          a2 = b.ns.pontes.auctionator('6541:18:845'),
          s = b.ns.pontes.syndicator(2589),
          e = b.ns.pontes.elvui(nil),
        }
      end },
  },
  conferir = function(b)
    local r = b.__r
    b.igual(r.a1, nil, 'Auctionator ausente: nil')
    b.igual(r.a2, nil, 'chave com sufixo: nil')
    b.igual(r.s, nil, 'Syndicator sem chamada: nil')
    b.igual(r.e, nil, 'ElvUI sem chamada: nil')
    b.igual(#b.erros(), 0, 'nenhum erro de Lua com o addon ausente')
    b.igual(#b.violacoes(), 0, 'sem violacao')
  end,
}
