-- Ponta a ponta: linhas gravadas pelo banco, com o leilao aberto, sobrevivem ao /reload e voltam iguais.
return {
  id = "dados-02", grupo = "dados",
  descricao = "gravar linhas pelo banco com o leilao aberto, reload, e ler de volta iguais",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
        local bk = b.ns.banco
        b.__linhas = {}
        for i = 1, 3 do
          local s = bk.seq()
          local linha = bk.cod.lote({ seq = s, t = 1794874100 + i, chave = '6541:18:845', qtd = 1, custo = 0,
            origem = 'coletado', estado = 'postado', tFecho = 0, resultado = 0 })
          b.igual(bk.gravar('lotes', linha), true, "gravou o lote " .. i)
          b.__linhas[#b.__linhas + 1] = linha
        end
      end },
    { reload = true },
  },
  conferir = function(b)
    local eu = b.ns.pers()
    b.igual(b.db().pers[eu].lotes, b.__linhas, "as linhas de lote voltam iguais")
    b.igual(b.db().fim, b.db().seq, "saida limpa: fim igual ao seq")
    b.igual(b.ns.banco.fimSujo, false, "sem fim sujo")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
