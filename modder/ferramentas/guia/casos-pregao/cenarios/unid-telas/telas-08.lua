-- Visao Session com o Y de salvar: so com tudo em repouso; so na visao Session; chama ReloadUI e nenhuma funcao de acao.
return {
  id = "telas-08", grupo = "unid-telas",
  descricao = "Session com o Y de salvar: bloqueado fora do repouso, ReloadUI em repouso, Y morto em Mine",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { abrir_leilao = true },
    { avancar = 1 },
    { tecla = "Y" },
    { chamar = function(b)
        b.igual(b.contar("ReloadUI"), 0, "Y em Mine nao salva")
        b.falso(PregaoForeverTeclaY:IsShown(), "o botao Y so aparece na Session")
        b.ns.telas.mostrar("session")
        b.verdadeiro(PregaoForeverTeclaY:IsShown(), "o botao Y aparece na Session")
        b.igual(b.tela().estado, "READY", "bilhete pronto em repouso")
        local t = table.concat(b.tela().linhas, "\n")
        b.verdadeiro(string.find(t, "[Y] save now (reloads the interface)", 1, true) ~= nil, "rotulo do bilhete")
        b.ns.pedidos.estado = function() return { fase = "ABERTO", buscas = 3, emVoo = false } end
        b.ns.sujo("tela")
      end },
    { avancar = 1 },
    { chamar = function(b)
        b.igual(b.tela().estado, "SAVE BLOCKED", "folego aberto bloqueia")
        local t = table.concat(b.tela().linhas, "\n")
        b.verdadeiro(string.find(t, "SAVE BLOCKED - finish or cancel first", 1, true) ~= nil, "texto do quadro aprovado")
      end },
    { tecla = "Y" },
    { chamar = function(b)
        b.igual(b.contar("ReloadUI"), 0, "bloqueado: nada de ReloadUI")
        b.ns.pedidos.estado = function() return { fase = "PARADO" } end
        b.ns.sujo("tela")
      end },
    { avancar = 1 },
    { chamar = function(b)
        b.igual(b.tela().estado, "READY", "em repouso de novo")
      end },
    { tecla = "Y" },
  },
  conferir = function(b)
    b.igual(b.contar("ReloadUI"), 1, "Y em repouso chamou ReloadUI uma vez")
    b.igual(b.contar("PostItem") + b.contar("PostCommodity") + b.contar("PlaceBid") + b.contar("CancelAuction"), 0, "nenhuma acao")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
