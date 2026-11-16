-- Escada.fotoC: commodity com unidades proprias removidas dos degraus, marcas F e E, qtot; leitura com item proprio nao entra em dias nem blocos.
return {
  id = "escada-01-commodity-proprias", grupo = "unid-itens",
  descricao = "foto de commodity: sem as unidades proprias, marcas FE, qtot; item proprio nao atualiza dias",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0,
    mercado = {
      ["2589"] = {
        { preco = 9, qtd = 14, donos = 2 },
        { preco = 9, qtd = 6, donos = 1, proprio = true },
        { preco = 10, qtd = 200, donos = 5 },
      },
    },
  },
  passos = {
    { chamar = function(b)
        b.__M = { itens = {}, dias = {}, blocos = {}, calib = {} }
        b.__G = { gravados = {}, seq = 0 }
        b.ns.banco = {
          seq = function() b.__G.seq = b.__G.seq + 1; return b.__G.seq end,
          cod = { fotoC = function(t) return t end, fotoI = function(t) return t end },
          gravar = function(anel, linha) b.__G.gravados[#b.__G.gravados + 1] = { anel = anel, linha = linha } end,
          memoria = function() return b.__M end,
        }
      end },
    { abrir_leilao = true },
    { chamar = function(b)
        __bancada.ultimaTecla = __bancada.agoraUs()
        C_AuctionHouse.SendSearchQuery({ itemID = 2589, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 }, {}, false)
      end },
    { avancar = 2 },
    { chamar = function(b)
        b.__foto = b.ns.escada.fotoC(2589)
        b.ns.escada.gravar('2589', b.__foto)
      end },
  },
  conferir = function(b)
    local f = b.__foto
    b.igual(f.marcas, 'FE', 'frente (ordem crescente) e escada completa')
    b.igual(f.qtot, 214, 'quantidade total sem a unidade propria (14 + 200)')
    b.igual(f.degraus, {
      { preco = 9, qtd = 14, donos = 2, proprias = 6, conta = 0 },
      { preco = 10, qtd = 200, donos = 5, proprias = 0, conta = 0 },
    }, 'degraus sem as 6 unidades proprias; proprias guardadas no degrau')
    b.igual(f.cauda, { 0, 0, 0, 0, 0, 0, 0, 0 }, 'sem cauda abaixo de 12 degraus')
    b.igual(b.__G.gravados[1].anel, 'fotos:2589', 'gravada no anel da chave')
    b.igual(b.__G.gravados[1].linha.marcas, 'FE', 'a linha e a foto')
    b.igual(next(b.__M.dias), nil, 'leitura com item proprio nao entra em dias')
    b.igual(next(b.__M.blocos), nil, 'nem em blocos')
    b.igual(#b.violacoes(), 0, 'sem violacao')
  end,
}
