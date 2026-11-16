-- Regra 16: leilao aberto ou fechado em combate deixa o binding pendente; roda no PLAYER_REGEN_ENABLED.
return {
  id = "telas-03", grupo = "unid-telas",
  descricao = "leilao aberto em combate deixa o binding pendente e liga no PLAYER_REGEN_ENABLED; fechar em combate solta depois",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912, combate = true },
  passos = {
    { avancar = 1 },
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
        b.verdadeiro(PregaoForeverJanela:IsShown(), "a janela abre mesmo em combate (so leitura)")
        b.igual(b.contar("SetOverrideBindingClick"), 0, "nenhum binding em combate")
        b.verdadeiro(b.ns.teclas.pendente, "ligar ficou pendente")
      end },
    { injetar = "combate_off" },
    { avancar = 1 },
    { chamar = function(b)
        b.igual(b.contar("SetOverrideBindingClick"), 10, "ligou ao sair do combate")
        b.falso(b.ns.teclas.pendente, "sem pendencia")
        b.verdadeiro(b.ns.teclas.ligado, "ligado")
      end },
    { injetar = "combate_on" },
    { fechar_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
        b.igual(b.contar("ClearOverrideBindings"), 0, "nao solta em combate")
        b.verdadeiro(b.ns.teclas.pendente, "soltar ficou pendente")
      end },
    { injetar = "combate_off" },
    { avancar = 1 },
  },
  conferir = function(b)
    b.igual(b.contar("ClearOverrideBindings"), 1, "soltou ao sair do combate")
    b.falso(b.ns.teclas.ligado, "solto")
    b.falso(b.ns.teclas.pendente, "sem pendencia no fim")
    b.igual(#b.violacoes(), 0, "nenhuma chamada de binding em combate")
  end,
}
