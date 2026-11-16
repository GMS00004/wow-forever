-- Leitor do Calibrado: desk() segue a tabela de modos (secao 12); param() so usa o valor calibrado dentro da faixa.
return {
  id = "banco-07", grupo = "unid-banco",
  descricao = "desk() pela tabela de modos (neutro, fresco, velho, sem sentinela, ausente, outro esquema); param() dentro da faixa",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { chamar = function(b)
        local ns = b.ns
        local bk = ns.banco
        local SENT = 'PREGAO-CALIBRADO-FIM'
        -- o Calibrado.lua neutro: geradoEm = 0, idade enorme, DESK STALE pela tabela
        b.igual(bk.desk(), "DESK STALE", "calibrado neutro (geradoEm 0) e DESK STALE")
        ns.calibrado = { esquema = 1, geradoEm = ns.servidor() - 3 * 86400, recibo = 0, epoca = 0, valores = {}, sentinela = SENT }
        b.igual(bk.desk(), "DESK OK", "3 dias: DESK OK")
        ns.calibrado.geradoEm = ns.servidor() - 8 * 86400
        b.igual(bk.desk(), "DESK STALE", "8 dias: DESK STALE")
        ns.calibrado = { esquema = 1, geradoEm = ns.servidor(), recibo = 0, epoca = 0, valores = {} }
        b.igual(bk.desk(), "NO DESK", "sem sentinela (truncado): NO DESK")
        ns.calibrado = nil
        b.igual(bk.desk(), "NO DESK", "ausente: NO DESK")
        ns.calibrado = { esquema = 2, geradoEm = ns.servidor(), recibo = 0, epoca = 0, valores = {}, sentinela = SENT }
        b.igual(bk.desk(), "NO DESK", "outro esquema: NO DESK")

        -- param: teto_mb tem faixa 1 a 5 no Apendice B; dentro vale o calibrado, fora vale o do Config (3)
        ns.calibrado = { esquema = 1, geradoEm = ns.servidor(), recibo = 0, epoca = 0,
          valores = { ['banco.teto_mb'] = { valor = 2 } }, sentinela = SENT }
        b.igual(bk.param('banco.teto_mb'), 2, "dentro da faixa vale o calibrado")
        ns.calibrado.valores['banco.teto_mb'] = { valor = 9 }
        b.igual(bk.param('banco.teto_mb'), 3, "fora da faixa vale o do Config")
        ns.calibrado = nil
        b.igual(bk.param('banco.teto_mb'), 3, "sem Calibrado valido vale o do Config")
      end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
