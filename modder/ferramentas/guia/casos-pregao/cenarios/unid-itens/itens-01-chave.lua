-- Itens.lua: chave de commodity (so o itemID) e de item com sufixo (itemID:nivel:sufixo), e o itemKey de volta.
return {
  id = "itens-01-chave", grupo = "unid-itens",
  descricao = "chave: commodity e item com sufixo, ida e volta pelo itemKey",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0 },
  passos = {
    { avancar = 1 },
    { chamar = function(b)
        local it = b.ns.itens
        b.__r = {
          com = it.chave({ itemID = 2589, itemLevel = 0, itemSuffix = 0 }, true),
          item = it.chave({ itemID = 6541, itemLevel = 18, itemSuffix = 845 }, false),
          semFlag = it.chave({ itemID = 6541, itemLevel = 18, itemSuffix = 845 }),
          chaveItem = it.itemKey('6541:18:845'),
          chaveCom = it.itemKey('2589'),
          ruim = it.itemKey('abc'),
          voltaItem = it.chave(it.itemKey('6541:18:845'), false),
        }
      end },
  },
  conferir = function(b)
    local r = b.__r
    b.igual(r.com, '2589', 'commodity: so o itemID')
    b.igual(r.item, '6541:18:845', 'item: itemID:nivel:sufixo')
    b.igual(r.semFlag, '6541:18:845', 'sem o flag, nivel diferente de zero vira item')
    b.igual(r.chaveItem, { itemID = 6541, itemLevel = 18, itemSuffix = 845, battlePetSpeciesID = 0 }, 'itemKey de item com sufixo')
    b.igual(r.chaveCom, { itemID = 2589, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 }, 'itemKey de commodity')
    b.igual(r.ruim, nil, 'texto que nao e chave devolve nil')
    b.igual(r.voltaItem, '6541:18:845', 'ida e volta da chave de item')
    b.igual(#b.violacoes(), 0, 'sem violacao')
  end,
}
