-- Anel cheio: o anel de fotos (16 por chave) sobrescreve o mais velho; sem recibo anota em sobrescritos; com recibo, nao.
return {
  id = "banco-05", grupo = "unid-banco",
  descricao = "anel cheio sobrescreve o mais velho e anota em sobrescritos; o recibo que cobre o seq evita a anotacao",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { chamar = function(b)
        local bk = b.ns.banco
        local function foto(s)
          return bk.cod.fotoC({ seq = s, t = 1794873600 + s, marcas = 'F', qtot = 1, degraus = {},
            cauda = { 0, 0, 0, 0, 0, 0, 0, 0 } })
        end
        for _ = 1, 17 do
          local s = bk.seq()
          b.igual(bk.gravar('fotos:2589', foto(s)), true, "gravou a foto " .. s)
        end
        local casa = b.ns.casa()
        local ring = b.db().casas[casa].fotos['2589']
        b.igual(#ring, 16, "o anel tem 16 fotos")
        b.igual(string.match(ring[1], '^1|(%d+)|'), '2', "a mais velha (seq 1) saiu")
        b.igual(b.db().sobrescritos[casa .. '/fotos:2589'], { 1, 1 }, "seq 1 anotado em sobrescritos, sem recibo")

        -- com recibo 3, sair o seq 2 nao e perda: a anotacao fica como estava
        b.ns.calibrado = { esquema = 1, geradoEm = 0, recibo = 3, epoca = 0, valores = {},
          sentinela = 'PREGAO-CALIBRADO-FIM' }
        local s = bk.seq()
        bk.gravar('fotos:2589', foto(s))
        b.igual(string.match(ring[1], '^1|(%d+)|'), '3', "a seq 2 saiu do anel")
        b.igual(#ring, 16, "o anel continua com 16")
        b.igual(b.db().sobrescritos[casa .. '/fotos:2589'], { 1, 1 }, "com recibo, a anotacao nao cresce")
      end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
