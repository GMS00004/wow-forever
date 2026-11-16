-- Teclas.lua: bindings so com a janela aberta (so botoes PregaoForever*), soltos no fechar; F1, F2 e F4 sem binding.
return {
  id = "telas-02", grupo = "unid-telas",
  descricao = "bindings ligados so com a janela aberta e soltos no fechar",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { chamar = function(b)
        b.igual(b.contar("SetOverrideBindingClick"), 0, "nada ligado antes do leilao")
      end },
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
        local cs = b.chamadas("SetOverrideBindingClick")
        b.igual(#cs, 10, "dez teclas ligadas")
        local mapa = {}
        for i = 1, #cs do
          local a = cs[i].args
          b.verdadeiro(a[1] == PregaoForeverJanela, "dono dos bindings e a janela")
          b.verdadeiro(string.sub(a[4], 1, 13) == "PregaoForever", "so botao PregaoForever*")
          mapa[a[3]] = a[4]
        end
        b.igual(mapa.L, "PregaoForeverTeclaL", "L")
        b.igual(mapa.N, "PregaoForeverTeclaN", "N")
        b.igual(mapa.U, "PregaoForeverTeclaU", "U")
        b.igual(mapa.I, "PregaoForeverTeclaI", "I")
        b.igual(mapa.O, "PregaoForeverTeclaO", "O")
        b.igual(mapa.K, "PregaoForeverTeclaK", "K")
        b.igual(mapa.H, "PregaoForeverTeclaH", "H")
        b.igual(mapa.F3, "PregaoForeverTeclaF3", "F3")
        b.igual(mapa.F5, "PregaoForeverTeclaF5", "F5")
        b.igual(mapa.Y, "PregaoForeverTeclaY", "Y")
        b.verdadeiro(mapa.F1 == nil and mapa.F2 == nil and mapa.F4 == nil, "F1, F2 e F4 sem binding")
        b.verdadeiro(mapa.P == nil and mapa.B == nil and mapa.C == nil and mapa.M == nil, "nenhuma tecla de acao")
        b.igual(b.contar("ClearOverrideBindings"), 0, "nada solto com a janela aberta")
        b.verdadeiro(b.ns.teclas.ligado, "estado ligado")
      end },
    { fechar_leilao = true },
    { avancar = 1 },
  },
  conferir = function(b)
    b.igual(b.contar("ClearOverrideBindings"), 1, "soltou no fechar")
    b.falso(b.ns.teclas.ligado, "estado solto")
    b.igual(b.contar("SetOverrideBindingClick"), 10, "nenhuma tecla nova depois de fechar")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
