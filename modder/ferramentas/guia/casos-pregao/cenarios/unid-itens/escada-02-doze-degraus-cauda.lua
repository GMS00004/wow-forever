-- Escada.fotoC: mais de 12 degraus, a cauda em 8 baldes com limites no preco do 12o degrau; dias e blocos recebem o minimo e a quantidade.
return {
  id = "escada-02-doze-degraus-cauda", grupo = "unid-itens",
  descricao = "15 degraus: 12 guardados, cauda em baldes (1,05; 1,1; 1,2 do 12o), dias e blocos atualizados",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0,
    -- 12o degrau = 100. Limites da cauda: 105, 110, 120, 135, 150, 200, 300.
    -- Degraus alem do 12o: 105 (1), 106 (2), 111 (4), 121 (8), 136 (16), 151 (32), 301 (64).
    mercado = (function()
      local rows = {}
      for p = 89, 100 do rows[#rows + 1] = { preco = p, qtd = 10, donos = 3 } end
      local cauda = { { 105, 1 }, { 106, 2 }, { 111, 4 }, { 121, 8 }, { 136, 16 }, { 151, 32 }, { 301, 64 } }
      for i = 1, #cauda do rows[#rows + 1] = { preco = cauda[i][1], qtd = cauda[i][2], donos = 1 } end
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
    b.igual(#f.degraus, 12, 'so 12 degraus guardados')
    b.igual(f.degraus[1].preco, 89, 'primeiro degrau e o mais barato')
    b.igual(f.degraus[12].preco, 100, 'o 12o degrau e o preco 100')
    b.igual(f.qtot, 247, 'quantidade total inclui a cauda (120 + 1+2+4+8+16+32+64)')
    b.igual(f.cauda, { 1, 2, 4, 8, 16, 32, 0, 64 }, 'baldes: 105 ate 1,05; 106 ate 1,1; 111 ate 1,2; 121 ate 1,35; 136 ate 1,5; 151 ate 2; 301 no resto')
    b.igual(f.marcas, 'FE', 'frente e escada')
    b.igual(b.__M.dias['2589'][b.ns.diaMercado(f.t)], { min = 89, qtd = 247 }, 'dias: minimo do dia e quantidade')
    b.igual(b.__M.blocos['2589'][math.floor(f.t / 14400)], { min = 89, qtd = 247 }, 'blocos: ultimo minimo e quantidade')
    b.igual(#b.violacoes(), 0, 'sem violacao')
  end,
}
