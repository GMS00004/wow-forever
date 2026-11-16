-- Resumo paginado: GetBrowseResults uma vez, no UPDATED; as paginas somam pelo payload de ADDED.
local function falsos(b)
  local ns = b.ns
  b.__casa, b.__pers, b.__resumos = {}, {}, {}
  ns.banco.casa = function() return b.__casa end
  ns.banco.pers = function() return b.__pers end
  ns.banco.cod = { resumo = function(t) b.__resumos[#b.__resumos + 1] = t return t end, proprio = function(t) return t end }
  ns.escada.fotoC = function(id) return { id = id, marcas = "FE" } end
  ns.escada.fotoI = function(k) return { id = k.itemID, marcas = "FE" } end
  ns.escada.gravar = function() end
  ns.cofre.conciliar = function() end
end
local mercado = {}
for i = 1, 1200 do mercado[tostring(30000 + i)] = { { preco = 100 + i, qtd = 1, donos = 1 } } end
return {
  id = "pedidos-09", grupo = "unid-pedidos",
  descricao = "1200 linhas em tres paginas: GetBrowseResults uma vez, 1200 linhas guardadas, completa",
  inicio = { mercado = mercado },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
        falsos(b)
        __bancada.ultimaTecla = __bancada.agoraUs()
        b.ns.pedidos.tecla()
        b.__r = b.ns.varredura.tecla()
      end },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.__r, true, "tecla abriu")
    b.igual(b.contar("SendBrowseQuery"), 1, "um pedido de resumo")
    b.igual(b.contar("RequestMoreBrowseResults"), 2, "duas paginas a mais")
    b.igual(b.contar("GetBrowseResults"), 1, "GetBrowseResults uma vez so")
    b.igual(#b.eventos("AUCTION_HOUSE_BROWSE_RESULTS_ADDED"), 2, "dois ADDED")
    local r = b.__resumos[1]
    b.verdadeiro(r ~= nil, "resumo guardado")
    b.igual(r.n, 1200, "as 1200 linhas: 480 do UPDATED mais 480 e 240 dos ADDED")
    b.igual(#r.dados, 1200, "dados com 1200 entradas")
    b.igual(r.completa, true, "completo")
    b.igual(r.pedidos, 3, "tres pedidos")
    b.igual(r.dados[1].chave, "30001", "primeira chave")
    b.igual(r.dados[1].min, 101, "minimo da primeira")
    b.igual(r.dados[1200].chave, "31200", "ultima chave")
    b.igual(b.ns.varredura.estado().fase, "PARADO", "fim parado")
    b.verdadeiro(b.ns.varredura.estado().idadeResumo ~= nil, "idade do resumo conhecida")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
