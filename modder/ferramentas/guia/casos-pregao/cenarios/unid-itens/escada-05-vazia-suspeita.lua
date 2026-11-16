-- Escada.fotoC: zero linhas onde a foto anterior tinha oferta e vazia suspeita: nao sai foto, nao grava, nao atualiza nada.
return {
  id = "escada-05-vazia-suspeita", grupo = "unid-itens",
  descricao = "foto vazia depois de foto com oferta: descartada, nada gravado",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0,
    mercado = { ["2589"] = { { preco = 9, qtd = 14, donos = 2 } } },
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
        b.__f1 = b.ns.escada.fotoC(2589)
        b.ns.escada.gravar('2589', b.__f1)
      end },
    { injetar = "busca_vazia" },
    { chamar = function(b)
        __bancada.ultimaTecla = __bancada.agoraUs()
        C_AuctionHouse.SendSearchQuery({ itemID = 2589, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 }, {}, false)
      end },
    { avancar = 2 },
    { chamar = function(b)
        b.__f2, b.__motivo = b.ns.escada.fotoC(2589)
        b.__ok2, b.__motivoG = b.ns.escada.gravar('2589', b.__f2)
      end },
  },
  conferir = function(b)
    b.igual(b.__f1 ~= nil and b.__f1.qtot, 14, 'primeira foto, com oferta, foi lida')
    b.igual(b.__f2, nil, 'a segunda, vazia, nao vira foto')
    b.igual(b.__motivo, 'vazia suspeita', 'o motivo e vazia suspeita')
    b.igual(b.__ok2, false, 'gravar nao grava foto nula')
    b.igual(#b.__G.gravados, 1, 'so a primeira foto foi gravada')
    b.igual(b.__M.dias['2589'] ~= nil and b.__M.dias['2589'][b.ns.diaMercado(b.__f1.t)].qtd, 14, 'a memoria ficou com a primeira leitura')
    b.igual(#b.violacoes(), 0, 'sem violacao')
  end,
}
