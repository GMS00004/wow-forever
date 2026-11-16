-- Poda: acima do gatilho (80% do teto), sai primeiro o que tem seq ate o recibo; com o recibo cobrindo tudo, nada vai a sobrescritos.
return {
  id = "banco-08", grupo = "unid-banco",
  descricao = "acima do gatilho a poda tira fotos; com recibo que cobre o seq, nada e anotado em sobrescritos e o medidor fica abaixo do gatilho",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { chamar = function(b)
        local ns = b.ns
        local bk = ns.banco
        -- teto de teste de 0,001 MB (1049 bytes): gatilho de 80%, cerca de 839 bytes
        ns.cfg.banco.teto_mb = 0.001
        ns.calibrado = { esquema = 1, geradoEm = 0, recibo = 20, epoca = 0, valores = {},
          sentinela = 'PREGAO-CALIBRADO-FIM' }
        for i = 1, 20 do
          local s = bk.seq()
          bk.gravar('fotos:2589', bk.cod.fotoC({ seq = s, t = 1794873600 + i, marcas = 'F', qtot = 1, degraus = {},
            cauda = { 0, 0, 0, 0, 0, 0, 0, 0 } }))
        end
        b.__casa = ns.casa()
      end },
  },
  conferir = function(b)
    local ring = b.db().casas[b.__casa].fotos['2589']
    b.verdadeiro(#ring < 16, "a poda tirou fotos do anel")
    b.verdadeiro(b.ns.banco.medidor() <= 0.001 * 1048576 * 0.8, "medidor abaixo do gatilho")
    b.igual(b.db().sobrescritos[b.__casa .. '/fotos:2589'], nil, "nada foi anotado: o recibo cobre tudo")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
