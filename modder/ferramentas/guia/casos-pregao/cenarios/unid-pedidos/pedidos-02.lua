-- Folego aberto por ns.pedidos.tecla() + ns.varredura.tecla(): proprios, resumo, triagem do piso e foco, com falsos do Banco/Escada/Cofre.
local function falsos(b)
  local ns = b.ns
  b.__casa, b.__pers, b.__resumos, b.__gravadas, b.__conc, b.__linhas = {}, {}, {}, {}, 0, {}
  ns.banco.casa = function() return b.__casa end
  ns.banco.pers = function() return b.__pers end
  ns.banco.cod = {
    resumo = function(t) b.__resumos[#b.__resumos + 1] = t return t end,
    proprio = function(t) b.__linhas[#b.__linhas + 1] = t return t end,
  }
  ns.escada.fotoC = function(id) return { id = id, marcas = "FE" } end
  ns.escada.fotoI = function(k) return { id = k.itemID, marcas = "FE" } end
  ns.escada.gravar = function(chave, foto) b.__gravadas[#b.__gravadas + 1] = chave end
  ns.cofre.conciliar = function(j) b.__conc = b.__conc + 1 end
end
local function tecla(b)
  __bancada.ultimaTecla = __bancada.agoraUs()
  b.ns.pedidos.tecla()
end
return {
  id = "pedidos-02", grupo = "unid-pedidos",
  descricao = "uma tecla abre um folego: PROPRIOS, RESUMO, TRIAGEM e FOCO, e concilia so no primeiro folego",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    mercado = { ["2589"] = { { preco = 9, qtd = 14, donos = 2 } }, ["2592"] = { { preco = 30, qtd = 5 } },
      ["4306"] = { { preco = 200, qtd = 3 } } },
    proprios = { { itemID = 2589, qtd = 5, preco = 9 } } },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
        falsos(b)
        tecla(b)
        b.__r1 = { b.ns.varredura.tecla() }
        b.__fase1 = b.ns.varredura.estado().fase
        b.__ped1 = b.ns.pedidos.estado().fase
      end },
    { ate_ocioso = true },
    { chamar = function(b)
        b.__conc1 = b.__conc
        b.__est1 = b.ns.varredura.estado()
        b.__resumos1 = #b.__resumos
        b.__nlin1 = #b.__linhas
        b.__npers1 = #b.__pers.proprios
        b.__grav1 = { table.unpack(b.__gravadas) }
        tecla(b)
        b.__r2 = { b.ns.varredura.tecla() }
        b.__r3 = { b.ns.varredura.tecla() }   -- ja varrendo
      end },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.__r1[1], true, "a tecla abriu o folego")
    b.igual(b.__fase1, "PROPRIOS", "logo depois da tecla: PROPRIOS")
    b.igual(b.__ped1, "ABERTO", "pedidos ABERTO")
    b.igual(b.__conc1, 1, "conciliou no primeiro folego")
    b.igual(b.__est1.fase, "PARADO", "fim: PARADO")
    b.igual(b.__est1.total, 2, "foco de duas chaves (piso 2592, proprio 2589)")
    b.igual(b.__est1.feitas, 2, "as duas feitas")
    b.igual(b.__grav1, { "2592", "2589" }, "fotos gravadas na ordem de envio: piso, depois proprios")
    b.igual(b.__resumos1, 1, "um resumo guardado")
    b.igual(b.__resumos[1].n, 3, "resumo com tres chaves")
    b.igual(b.__resumos[1].completa, true, "resumo completo")
    b.igual(b.__resumos[1].pedidos, 1, "um pedido de resumo")
    b.igual(b.__nlin1, 1, "um leilao proprio gravado")
    b.igual(b.__linhas[1].qtd, 5, "com a quantidade")
    b.igual(b.__npers1, 1, "pers().proprios escrito")
    b.igual(b.__r2[1], true, "a segunda tecla abre outro folego")
    b.igual(b.__r3[2], "varrendo", "tecla com varredura em curso nao abre outro")
    b.igual(b.contar("QueryOwnedAuctions"), 2, "proprios em todo folego")
    b.igual(b.contar("SendBrowseQuery"), 1, "resumo so uma vez: o ultimo tem menos de 10 min")
    b.igual(b.__conc, 1, "nao concilia de novo no segundo folego")
    b.igual(b.contar("SendSearchQuery"), 4, "dois por folego")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
