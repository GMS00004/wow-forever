-- Reload: o que o banco gravou volta igual depois do /reload; fim == seq na saida limpa.
return {
  id = "banco-03", grupo = "unid-banco",
  descricao = "linhas gravadas e memoria sobrevivem ao /reload; fim igual ao seq; fecho do personagem grava o seq",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { chamar = function(b)
        local bk = b.ns.banco
        b.__livro = {}
        b.__seqs = 0
        for i = 1, 3 do
          local s = bk.seq()
          b.__seqs = b.__seqs + 1
          local linha = bk.cod.acao({ seq = s, t = 1794874100 + i, verbo = 'post', chave = '6541:18:845', qtd = 1,
            preco = 20000 + i, estrategia = 'venda_verdes', origem = 'key', antes = 31200, depois = 31170,
            eco = 'created', tEco = 1794874101, erro = '', bilhete = { 24, 'm', 30, 0 }, fotoEm = 1794874058 })
          b.igual(bk.gravar('livro', linha), true, "gravou a acao " .. i)
          b.__livro[#b.__livro + 1] = linha
        end
        local s1 = bk.seq()
        b.__seqs = b.__seqs + 1
        b.__sinal = bk.cod.sinal({ seq = s1, t = 1794874000, estrategia = 'piso', nivel = 1, chave = '2589', qtd = 14,
          preco = 9, previsto = 56, motivo = 'NEW', executou = 0, desfecho = 'sold', realizado = 52, exposicao = 7400 })
        bk.gravar('sinais', b.__sinal)
        local s2 = bk.seq()
        b.__seqs = b.__seqs + 1
        b.__fotoC = bk.cod.fotoC({ seq = s2, t = 1794874200, marcas = 'F', qtot = 214,
          degraus = { { preco = 9, qtd = 14, donos = 2, proprias = 0, conta = 0 } }, cauda = { 0, 0, 0, 0, 0, 0, 0, 0 } })
        bk.gravar('fotos:2589', b.__fotoC)
        local m = bk.memoria()
        m.itens['2589'] = { vend = 13, tipo = 'c', pilha = 20, conf = 1 }
        m.dias['2589'] = { [20773] = { min = 9, qtd = 3120 }, [20774] = { min = 10, qtd = 2890 } }
        m.blocos['2589'] = { [124640] = { min = 9, qtd = 3120 } }
        m.calib['frete'] = { valor = 500, n = 3, medido = 1, em = 1794880000, build = 70938, amostras = {} }
      end },
    { reload = true },
  },
  conferir = function(b)
    local db = b.db()
    local eu = b.ns.pers()
    b.igual(db.pers[eu].livro, b.__livro, "anel livro volta igual")
    b.igual(db.sinais, { b.__sinal }, "anel sinais volta igual")
    b.igual(db.casas[b.ns.casa()].fotos['2589'], { b.__fotoC }, "anel de fotos volta igual")
    b.igual(db.seq, b.__seqs + 1, "seq conta as gravacoes e a linha da sessao fechada no reload")
    b.igual(db.fim, db.seq, "fim igual ao seq na saida limpa")
    b.igual(db.pers[eu].fecho.seq, db.seq, "fecho do personagem com o seq")
    b.igual(b.ns.banco.fimSujo, false, "sem fim sujo")
    b.igual(b.ns.banco.carregado, true, "carregado depois do reload")
    local m = b.ns.banco.memoria()
    b.igual(m.itens['2589'], { vend = 13, tipo = 'c', pilha = 20, conf = 1 }, "itens decodificados de volta")
    b.igual(m.dias['2589'], { [20773] = { min = 9, qtd = 3120 }, [20774] = { min = 10, qtd = 2890 } }, "dias decodificados de volta")
    b.igual(m.blocos['2589'], { [124640] = { min = 9, qtd = 3120 } }, "blocos decodificados de volta")
    b.igual(m.calib['frete'], { valor = 500, n = 3, medido = 1, em = 1794880000, build = 70938, amostras = {} }, "calib de volta")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
