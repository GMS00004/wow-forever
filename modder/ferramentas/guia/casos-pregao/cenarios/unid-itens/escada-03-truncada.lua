-- Escada.fotoC: resposta que nao chega completa (sem a marca E): cauda gravada como T e quantidade lida do visivel.
return {
  id = "escada-03-truncada", grupo = "unid-itens",
  descricao = "60 degraus com a escada incompleta: marca F sem E, cauda T, qtot do que chegou",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0,
    mercado = (function()
      local rows = {}
      for p = 10, 69 do rows[#rows + 1] = { preco = p, qtd = 1, donos = 1 } end
      return { ["2589"] = rows }
    end)(),
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
    b.igual(f.marcas, 'F', 'frente, sem escada completa')
    b.igual(f.cauda, 'T', 'cauda truncada')
    b.igual(f.qtot, 50, 'quantidade total do que chegou na primeira pagina (50 linhas)')
    b.igual(#f.degraus, 12, 'os 12 primeiros degraus continuam guardados')
    b.igual(b.__G.gravados[1].anel, 'fotos:2589', 'gravada mesmo sem a escada completa')
    b.igual(#b.violacoes(), 0, 'sem violacao')
  end,
}
