-- reload: PLAYER_LOGOUT, serializa os SV, recria o ns, cancela timers e quadros do addon antigo e recarrega com o SV.
return {
  id = "auto-10", grupo = "autoteste",
  descricao = "reload preserva o SV, recria o ns e solta o que era do addon antigo",
  inicio = {
    sv = { antigo = "x", lista = { 1, 2, 3 }, num = 5, meio = 2.5 },
    sv_char = { velho = true },
  },
  passos = {
    { chamar = function(b)
        b.__nsAntigo = b.ns
        b.__botaoAntigo = PregaoForeverTeclaL
        PregaoForeverDB.nova = { a = 1, b = "dois" }
        C_Timer.After(5, function() PregaoForeverDB.tardio = true end)
      end },
    { reload = true },
    { avancar = 10 },
    { salvar_sv = "auto-10" },
  },
  conferir = function(b)
    local db = b.db()
    b.igual(db.cargas, 2, "o addon carregou duas vezes")
    b.igual(db.saidas, 1, "PLAYER_LOGOUT chegou ao addon antes de serializar")
    b.igual(db.antigo, "x", "campo antigo preservado")
    b.igual(db.lista, { 1, 2, 3 }, "lista preservada")
    b.igual(db.num, 5, "numero preservado")
    b.igual(db.meio, 2.5, "fracao preservada")
    b.igual(db.nova, { a = 1, b = "dois" }, "o que o addon gravou antes do reload esta la")
    b.igual(db.tardio, nil, "o timer do addon antigo morreu no reload")
    b.igual(PregaoForeverCharDB.velho, true, "o SV por personagem tambem")
    b.verdadeiro(b.__nsAntigo ~= b.ns, "o ns e outro")
    b.verdadeiro(b.__botaoAntigo ~= PregaoForeverTeclaL, "o botao e outro")
    b.igual(PregaoForeverTeclaL ~= nil, true, "o botao novo existe")
    b.igual(b.ns.brinquedo.log[1].nome, "ADDON_LOADED", "o addon novo recomecou pelo ADDON_LOADED")
    local ent = b.eventos("PLAYER_ENTERING_WORLD")
    b.igual(ent[2].args[2], true, "o segundo PLAYER_ENTERING_WORLD e isReloadingUi")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
