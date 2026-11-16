-- Itens.lua: preco de vendedor lido ao vivo a cada info (regra 17); conf fica se o preco nao mudou.
return {
  id = "itens-02-vendedor-ao-vivo", grupo = "unid-itens",
  descricao = "info le o preco de vendedor na hora; o preco mudado aparece e conf some",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0,
    itens = { [2589] = { nome = "Linen Cloth", vend = 13, pilha = 20, qual = 1, nivel = 5, commodity = true } },
  },
  passos = {
    { chamar = function(b)
        b.__M = { itens = { ['2589'] = { vend = 13, tipo = 'c', pilha = 20, conf = 1 } }, dias = {}, blocos = {}, calib = {} }
        b.ns.banco = { memoria = function() return b.__M end }
        b.__r1 = b.ns.itens.info('2589')
      end },
    { chamar = function(b)
        b.__M.itens['2589'].conf = 1
        __bancada.A.itens[2589].vend = 20
        b.__r2 = b.ns.itens.info('2589')
      end },
  },
  conferir = function(b)
    b.igual(b.__r1, { vend = 13, tipo = 'c', pilha = 20, conf = 1, nome = 'Linen Cloth' }, 'preco igual ao do cache: conf do NPC fica')
    b.igual(b.__r2, { vend = 20, tipo = 'c', pilha = 20, conf = 0, nome = 'Linen Cloth' }, 'preco mudado no cliente: vale o novo, conf zera')
    b.igual(b.__M.itens['2589'], { vend = 20, tipo = 'c', pilha = 20, conf = 0 }, 'memoria do item gravada com o preco lido')
    b.igual(b.contar('C_Item.GetItemInfo') >= 2, true, 'duas leituras ao vivo pelo cliente')
    b.igual(b.contar('C_Item.RequestLoadItemDataByID'), 0, 'item no cache: nenhuma carga pedida')
    b.igual(#b.violacoes(), 0, 'sem violacao')
  end,
}
