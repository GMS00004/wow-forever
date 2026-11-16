-- Banco: a gramatica da secao 4 volta ao mesmo texto em cada exemplo; versao desconhecida devolve nil; numero so por ns.txt.
return {
  id = "banco-01", grupo = "unid-banco",
  descricao = "cod e dec de cada exemplo da gramatica voltam ao mesmo texto; versao desconhecida devolve nil",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { chamar = function(b)
        local cod, dec = b.ns.banco.cod, b.ns.banco.dec
        local exemplos = {
          { 'itens', '1|13|c|20|1' },
          { 'dias', '1|20773:9:3120;20774:10:2890' },
          { 'blocos', '1|124640:9:3120;124641:9:3300' },
          { 'fotoC', '1|8841|1794873600|FE|214|9:14:2:0:0,10:200:5:0:0|0,0,0,0,0,0,0,0' },
          { 'fotoI', '1|8850|1794873700|F|2|1|771:20000:0:2:1:0:0,774:21500:0:3:1:0:0|0:0' },
          { 'sinal', '1|9002|1794874000|piso|1|2589|14|9|56|NEW|0|sold|52|7400' },
          { 'acao', '1|9010|1794874100|post|6541:18:845|1|20000|venda_verdes|key|31200|31170|created|1794874101||24:m:30:0|1794874058' },
          { 'lote', '1|9011|1794874100|6541:18:845|1|0|coletado|postado|0|0' },
          { 'fatura', '1|9050|1794880000|seller|6541:18:845|20000|20000|30|1000|0|0|0|1|0' },
          { 'fora', '1|9060|1794881000|1240|play' },
          { 'proprio', '1|771|1|1|3600|0|20000|1794874200' },
          { 'calib', '1|500|3|1|1794880000|70938' },
          { 'sessao', '1|9100|1794870000|1794875520|21:14:3:11|1075|2400|capital|' },
          { 'npc', '1|500|3|1794874300' },
          { 'sonda', '1|1794874400|70938|passo sem erro' },
          { 'log', '1|1794874500|info|loaded 0.1.0 mode leitura' },
        }
        for _, par in ipairs(exemplos) do
          local nome, linha = par[1], par[2]
          local t = dec[nome](linha)
          b.verdadeiro(t ~= nil, nome .. ": decodifica o exemplo")
          b.igual(cod[nome](t), linha, nome .. ": volta ao mesmo texto")
        end

        -- resumo: a tabela tem dados como uma string so, 1|chave=min:qtd;...
        local r = cod.resumo(dec.resumo({ t = 1, tr = 2, pedidos = 3, completa = 1, n = 2, dados = '1|2589=9:3120;2770=54:880' }))
        b.igual(r.dados, '1|2589=9:3120;2770=54:880', "resumo volta ao mesmo dados")

        -- calibracao com amostras (sexto campo, separado por ';')
        local c = dec.calib('1|500|3|1|1794880000|70938|5:70938:0;6:70938:1')
        b.igual(#c.amostras, 2, "calib com duas amostras")
        b.igual(cod.calib(c), '1|500|3|1|1794880000|70938|5:70938:0;6:70938:1', "calib com amostras volta igual")

        -- versao desconhecida e campos errados: nil
        b.igual(dec.itens('2|13|c|20|1'), nil, "itens de versao desconhecida")
        b.igual(dec.sinal('2|9002|1794874000|piso|1|2589|14|9|56|NEW|0|sold|52|7400'), nil, "sinal de versao desconhecida")
        b.igual(dec.resumo({ dados = '2|2589=9:3120' }), nil, "resumo de versao desconhecida")
        b.igual(dec.itens('1|13|x|20|1'), nil, "itens com tipo fora de c e i")
        b.igual(dec.dias('1|20773:9'), nil, "dias com um campo a menos")

        -- numero vira texto so por ns.txt (10 / 2 e 5.0 no fengari); barra no texto, no lugar de '|'
        b.igual(cod.npc({ compra = 10 / 2, disponivel = -1, t = 1794874300 }), '1|5|-1|1794874300', "numero vira texto inteiro")
        b.igual(cod.log({ t = 1794874500, nivel = 'info', texto = 'a|b' }), '1|1794874500|info|a/b', "barra no lugar de |")
      end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
