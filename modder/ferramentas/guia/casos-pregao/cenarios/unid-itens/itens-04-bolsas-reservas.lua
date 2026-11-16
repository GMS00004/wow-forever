-- Itens.bolsas: bolsas 0 a 4 com chave, quantidade e tipo; item da lista de reservas volta com reservado = true.
return {
  id = "itens-04-bolsas-reservas", grupo = "unid-itens",
  descricao = "bolsas lista commodities das bolsas; a reserva do personagem marca o item",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0,
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 2589, qtd = 20 },
      { bolsa = 0, slot = 2, itemID = 2592, qtd = 5 },
      { bolsa = 2, slot = 3, itemID = 2589, qtd = 7 },
    },
  },
  passos = {
    { chamar = function(b)
        b.ns.cfg.reservas = { Hexumlite = { 2589 } }
        b.__lista = b.ns.itens.bolsas()
      end },
  },
  conferir = function(b)
    b.igual(b.__lista, {
      { bolsa = 0, slot = 1, chave = '2589', qtd = 20, tipo = 'c', reservado = true },
      { bolsa = 0, slot = 2, chave = '2592', qtd = 5, tipo = 'c', reservado = false },
      { bolsa = 2, slot = 3, chave = '2589', qtd = 7, tipo = 'c', reservado = true },
    }, 'bolsas com a reserva marcada e a quantidade do slot')
    b.igual(#b.violacoes(), 0, 'sem violacao')
  end,
}
