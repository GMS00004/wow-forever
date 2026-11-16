-- Escada.fotoI: item com 33 leiloes: 30 mais baratos, resto agregado, donos distintos e nomesVieram, sem nenhum nome gravado.
return {
  id = "escada-04-item-nomes", grupo = "unid-itens",
  descricao = "foto de item: 30 leiloes, resto 3:3, donos distintos 2, nenhum nome na foto",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 0,
    itens = { [6541] = { nome = "Test Ring", vend = 40, pilha = 1, qual = 3, nivel = 18, commodity = false } },
    mercado = (function()
      local rows = {}
      for i = 1, 33 do
        rows[#rows + 1] = { preco = 20000 + i * 100, qtd = 1, donos = (i <= 3) and 2 or 1, nivel = 18, sufixo = 845 }
      end
      return { ["6541"] = rows }
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
        C_AuctionHouse.SendSearchQuery({ itemID = 6541, itemLevel = 18, itemSuffix = 845, battlePetSpeciesID = 0 }, {}, false)
      end },
    { avancar = 2 },
    { chamar = function(b)
        b.__foto = b.ns.escada.fotoI({ itemID = 6541, itemLevel = 18, itemSuffix = 845, battlePetSpeciesID = 0 })
        b.ns.escada.gravar('6541:18:845', b.__foto)
      end },
  },
  conferir = function(b)
    local f = b.__foto
    local function textos(v, acc)
      if type(v) == 'string' then acc[#acc + 1] = v
      elseif type(v) == 'table' then
        for k, x in pairs(v) do textos(k, acc); textos(x, acc) end
      end
      return acc
    end
    b.igual(f.marcas, 'FE', 'frente e escada completa')
    b.igual(f.donos, 2, 'donos distintos: Vendedor1 e Vendedor2, contados e nao gravados')
    b.igual(f.nomesVieram, 1, 'o booleano de que os nomes vieram')
    b.igual(#f.leiloes, 30, 'so os 30 mais baratos')
    b.igual(f.leiloes[1].arremate, 20100, 'o mais barato primeiro')
    b.igual(f.leiloes[30].arremate, 23000, 'o 30o mais barato')
    b.igual(f.resto, { contagem = 3, soma = 3 }, 'resto agregado: 3 leiloes, 3 unidades')
    local achados = 0
    local lista = textos(b.__G.gravados[1].linha, {})
    for i = 1, #lista do
      if string.find(lista[i], 'Vendedor', 1, true) then achados = achados + 1 end
    end
    b.igual(achados, 0, 'nenhum nome de jogador na linha gravada')
    b.igual(b.__G.gravados[1].anel, 'fotos:6541:18:845', 'anel da chave de item')
    b.igual(b.__M.dias['6541:18:845'][b.ns.diaMercado(f.t)], { min = 20100, qtd = 33 }, 'dias: minimo e quantidade da leitura sem proprio')
    b.igual(#b.violacoes(), 0, 'sem violacao')
  end,
}
