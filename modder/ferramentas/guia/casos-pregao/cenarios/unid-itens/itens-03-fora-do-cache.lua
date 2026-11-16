-- Itens.lua: item fora do cache devolve nil e pede a carga uma vez; a resposta ITEM_DATA_LOAD_RESULT grava o item depois.
return {
  id = "itens-03-fora-do-cache", grupo = "unid-itens",
  descricao = "item sem cache: info nil, uma carga pedida, ITEM_DATA_LOAD_RESULT grava a memoria",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0,
    itens = { [6541] = { nome = "Test Ring", vend = 40, pilha = 1, qual = 3, nivel = 18, commodity = false, nao_carregado = true } },
  },
  passos = {
    { chamar = function(b)
        b.__M = { itens = {}, dias = {}, blocos = {}, calib = {} }
        b.ns.banco = { memoria = function() return b.__M end }
        b.__r1 = b.ns.itens.info('6541:18:845')
        b.__antes = b.__M.itens['6541:18:845']
      end },
    { avancar = 1 },
    { chamar = function(b)
        b.__r2 = b.ns.itens.info('6541:18:845')
      end },
  },
  conferir = function(b)
    b.igual(b.__r1, nil, 'item fora do cache: info devolve nil')
    b.igual(b.__antes, nil, 'nada gravado antes da carga')
    b.igual(b.contar('C_Item.RequestLoadItemDataByID'), 1, 'uma carga pedida, e so uma (a resposta nao pede outra)')
    b.igual(b.__M.itens['6541:18:845'], { vend = 40, tipo = 'i', pilha = 1, conf = 0 }, 'a resposta do cliente gravou o item na memoria')
    b.igual(b.__r2 ~= nil and b.__r2.vend, 40, 'depois da carga, info le o preco de vendedor')
    b.igual(b.__r2.tipo, 'i', 'tipo de item')
    b.igual(#b.violacoes(), 0, 'sem violacao')
  end,
}
