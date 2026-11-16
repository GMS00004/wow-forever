-- SetOverrideBindingClick / ClearOverrideBindings no abrir e fechar do leilao, fora de combate; foco de caixa de texto.
return {
  id = "auto-19", grupo = "autoteste",
  descricao = "bindings so fora de combate; GetCurrentKeyBoardFocus controlavel",
  inicio = {},
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
        b.igual(b.contar("SetOverrideBindingClick"), 1, "o addon ligou a tecla ao abrir o leilao")
        local a = b.chamadas("SetOverrideBindingClick")[1].args
        b.igual(a[3], "L", "tecla L")
        b.igual(a[4], "PregaoForeverTeclaL", "para o botao PregaoForeverTeclaL")
      end },
    { fechar_leilao = true },
    { chamar = function(b) b.igual(b.contar("ClearOverrideBindings"), 1, "soltou ao fechar") end },
    { injetar = "combate_on" },
    { abrir_leilao = true },
    { chamar = function(b) b.igual(b.contar("SetOverrideBindingClick"), 1, "em combate o brinquedo nao liga (nada de violacao)") end },
    { injetar = "foco_texto" },
    { chamar = function(b) b.verdadeiro(GetCurrentKeyBoardFocus() ~= nil, "foco numa caixa de texto") end },
    { injetar = "foco_livre" },
  },
  conferir = function(b)
    b.verdadeiro(GetCurrentKeyBoardFocus() == nil, "sem foco")
    b.igual(#b.violacoes(), 0, "sem violacao")
    -- chamar a funcao de binding em combate e violacao (o cliente a bloqueia)
    b.igual(#b.eventos("AUCTION_HOUSE_CLOSED"), 1, "um fechamento")
    b.igual(#b.eventos("AUCTION_HOUSE_SHOW"), 2, "duas aberturas")
  end,
}
