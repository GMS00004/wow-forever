-- Teclas.lua: L chama ns.varredura.tecla() depois de ns.pedidos.tecla(); o erro de uma funcao nao derruba a tela.
return {
  id = "telas-14", grupo = "unid-telas",
  descricao = "L chama a varredura depois do pedidos.tecla; os outros modulos ausentes nao quebram a tecla",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { abrir_leilao = true },
    { avancar = 1 },
    { tecla = "L" },
    { chamar = function(b)
        b.__ordem = {}
        b.ns.pedidos.tecla = function() b.__ordem[#b.__ordem + 1] = "pedidos" end
        b.ns.varredura = {
          tecla = function() b.__ordem[#b.__ordem + 1] = "varredura" end,
          estado = function() return { fase = "RESUMO", feitas = 3, total = 20, idadeResumo = 42 } end,
        }
        b.ns.sujo("tela")
      end },
    { avancar = 1 },
    { tecla = "L" },
    { avancar = 1 },
    { chamar = function(b)
        b.igual(b.__ordem, { "pedidos", "varredura" }, "primeiro a presenca, depois a funcao da tecla")
        local txt = table.concat(b.tela().linhas, "\n")
        b.verdadeiro(string.find(txt, "PRICES  42s old", 1, true) ~= nil, "idade do resumo na linha de estado")
        -- com a varredura no meio de uma fase, salvar fica bloqueado
        b.ns.telas.mostrar("session")
        b.igual(b.tela().estado, "SAVE BLOCKED", "varredura fora do repouso bloqueia o Y")
      end },
  },
  conferir = function(b)
    b.igual(#b.erros(), 0, "nenhum erro")
    b.verdadeiro(b.contar("SendBrowseQuery") <= 1, "so o primeiro L, real, consultou; a tela nao consulta sozinha")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
