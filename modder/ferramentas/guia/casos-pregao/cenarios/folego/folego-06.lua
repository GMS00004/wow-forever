-- Ponta a ponta: resumo paginado lido uma vez, guardado inteiro no banco; segundo L dentro de 10 min nao refaz o resumo.
local mercado = {}
for i = 1, 1200 do mercado[tostring(30000 + i)] = { { preco = 100 + i, qtd = 1, donos = 1 } } end
return {
  id = "folego-06", grupo = "folego",
  descricao = "1200 linhas em tres paginas: GetBrowseResults uma vez, resumo no banco com n=1200; L de novo em 5 min nao pede resumo; em 11 min pede",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000, mercado = mercado },
  passos = {
    { abrir_leilao = true },
    { tecla = "L" },
    { ate_ocioso = true },
    { chamar = function(b)
        b.__r1 = b.ns.banco.casa().resumo
        b.__browse1 = b.contar("SendBrowseQuery")
      end },
    { avancar = 300 },
    { tecla = "L" },
    { ate_ocioso = true },
    { chamar = function(b) b.__browse2 = b.contar("SendBrowseQuery") end },
    { avancar = 660 },
    { tecla = "L" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.__browse1, 1, "primeiro folego: um resumo")
    b.igual(b.__browse2, 1, "segundo folego (5 min): sem resumo novo")
    b.igual(b.contar("SendBrowseQuery"), 2, "terceiro folego (16 min): resumo novo")
    b.igual(b.contar("RequestMoreBrowseResults"), 4, "duas paginas a mais em cada resumo")
    b.igual(b.contar("GetBrowseResults"), 2, "GetBrowseResults uma vez por resumo")
    b.verdadeiro(b.__r1 ~= nil, "resumo guardado no banco")
    b.igual(b.__r1.n, 1200, "com as 1200 linhas")
    b.igual(b.__r1.completa, true, "completo")
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
