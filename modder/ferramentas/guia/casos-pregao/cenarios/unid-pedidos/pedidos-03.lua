-- Uma consulta em voo por vez, e so a resposta da chave pedida fecha a espera.
local function tecla(b)
  __bancada.ultimaTecla = __bancada.agoraUs()
  b.ns.pedidos.tecla()
end
return {
  id = "pedidos-03", grupo = "unid-pedidos",
  descricao = "enviar com uma consulta em voo recusa; a segunda sai depois da resposta; ordem das chamadas",
  inicio = { mercado = { ["2589"] = { { preco = 9, qtd = 14 } }, ["2592"] = { { preco = 30, qtd = 5 } } } },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
        local ns = b.ns
        b.__ok = {}
        tecla(b)
        ns.pedidos.abrirFolego(function() end)
        b.__a = { ns.pedidos.enviar({ tipo = "busca", chave = "2589", sorts = {},
          aoResponder = function() b.__ok[#b.__ok + 1] = "2589" end }) }
        b.__b = { ns.pedidos.enviar({ tipo = "busca", chave = "2592", sorts = {},
          aoResponder = function() b.__ok[#b.__ok + 1] = "2592" end }) }
        b.__voo = ns.pedidos.estado().emVoo
        b.__cont0 = b.contar("SendSearchQuery")
      end },
    { avancar = 2 },
    { chamar = function(b)
        local ns = b.ns
        b.__voo2 = ns.pedidos.estado().emVoo
        b.__c = { ns.pedidos.enviar({ tipo = "busca", chave = "2592", sorts = {},
          aoResponder = function() b.__ok[#b.__ok + 1] = "2592" end }) }
      end },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.__a[1], true, "a primeira entra")
    b.igual(b.__b[1], false, "a segunda, com uma em voo, recusa")
    b.igual(b.__b[2], "em_voo", "motivo: em voo")
    b.igual(b.__voo, true, "estado mostra uma em voo")
    b.igual(b.__cont0, 1, "uma so chamada ao cliente")
    b.igual(b.__voo2, false, "respondida: nada em voo")
    b.igual(b.__c[1], true, "depois da resposta a seguinte entra")
    b.igual(b.__ok, { "2589", "2592" }, "cada resposta foi para o seu pedido, em ordem")
    b.igual(b.contar("SendSearchQuery"), 2, "duas consultas no total")
    local ch = b.chamadas("SendSearchQuery")
    b.verdadeiro(ch[2].hora == nil or ch[2].hora >= ch[1].hora, "a segunda saiu depois da primeira")
    b.igual(b.ns.pedidos.estado().buscas, 2, "duas buscas contadas")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
