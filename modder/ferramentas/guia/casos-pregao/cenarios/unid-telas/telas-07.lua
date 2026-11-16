-- Teclas.lua e Telas.lua: F3 e F5 trocam a visao e ns.__tela acompanha; Mine sem LIMITS e sem STAND DOWN.
return {
  id = "telas-07", grupo = "unid-telas",
  descricao = "F3 e F5 trocam a visao e ns.__tela acompanha",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
        b.igual(b.tela().visao, "mine", "abre em Mine")
        local t = table.concat(b.tela().linhas, "\n")
        b.verdadeiro(string.find(t, "MY AUCTIONS (0)", 1, true) ~= nil, "secao MY AUCTIONS da Mine")
        b.falso(string.find(t, "LIMITS", 1, true) ~= nil, "Mine sem LIMITS")
        b.falso(string.find(t, "STAND DOWN", 1, true) ~= nil, "Mine sem STAND DOWN")
        b.verdadeiro(string.find(t, "TICKET", 1, true) ~= nil, "zona do bilhete")
        b.igual(PregaoForeverTeclaF3.fs:GetText(), "[F3 MINE]", "a aba ativa vai em palavra")
      end },
    { tecla = "F5" },
    { avancar = 0.1 },
    { chamar = function(b)
        b.igual(b.tela().visao, "session", "F5 abre Session")
        local t = table.concat(b.tela().linhas, "\n")
        b.verdadeiro(string.find(t, "SESSION", 1, true) ~= nil, "rotulo SESSION")
        b.verdadeiro(string.find(t, "RESULT", 1, true) ~= nil, "rotulo RESULT")
        b.verdadeiro(string.find(t, "STORAGE", 1, true) ~= nil, "rotulo STORAGE")
        b.verdadeiro(string.find(t, "BY PLAN", 1, true) ~= nil, "rotulo BY PLAN")
        b.verdadeiro(string.find(t, "CHECKS", 1, true) ~= nil, "rotulo CHECKS")
        b.igual(PregaoForeverTeclaF5.fs:GetText(), "[F5 SESSION]", "aba ativa em palavra")
      end },
    { avancar = 1 },
    { tecla = "F3" },
    { avancar = 0.1 },
    { chamar = function(b)
        b.igual(b.tela().visao, "mine", "F3 volta a Mine")
      end },
    { avancar = 1 },
    { chamar = function(b)
        b.ns.telas.mostrar("session")
        b.igual(b.tela().visao, "session", "mostrar('session')")
        b.falso(b.ns.telas.mostrar("risk"), "visao que nao existe na onda 2 e recusada")
        b.igual(b.tela().visao, "session", "a tela nao muda")
      end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
