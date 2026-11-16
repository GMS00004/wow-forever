-- Painel do correio: MAIL_SHOW abre, MAIL_CLOSED fecha, Dismiss e Save now sao botoes clicaveis (sem teclas).
return {
  id = "telas-13", grupo = "unid-telas",
  descricao = "painel do correio com falso de ns.correio.painel: estados, Dismiss e Save now",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { chamar = function(b)
        b.ns.correio = { painel = function()
          return {
            mostradas = 11, total = 11, maisCartas = false,
            faturas = {
              { tipo = "seller", bid = 15000, consignment = 750, deposit = 1000 },
              { tipo = "seller", bid = 0, consignment = 0, deposit = 0 },
              { tipo = "buyer", count = 3 },
              { tipo = "expired", count = 2, deposit = 400 },
            },
            aCaminho = { { etaHour = 21, etaMin = 40 } },
          }
        end }
      end },
    { evento = { "MAIL_SHOW" } },
    { avancar = 1 },
    { chamar = function(b)
        b.verdadeiro(PregaoForeverCorreio:IsShown(), "painel aberto")
        b.igual(b.contar("SetOverrideBindingClick"), 0, "o painel do correio nao tem teclas")
        local l = b.ns.__correio.linhas
        b.verdadeiro(string.find(l[1], "STATE  READY - 11 letters read. Take your mail now.", 1, true) ~= nil, "STATE: " .. l[1])
        b.verdadeiro(string.find(l[2], "SOLD (2)", 1, true) ~= nil, "SOLD: " .. l[2])
        b.verdadeiro(string.find(l[2], "deposits back 10s", 1, true) ~= nil, "deposits back: " .. l[2])
        b.verdadeiro(string.find(l[3], "EXPIRED (1)  2 items back   deposits lost 4s", 1, true) ~= nil, "EXPIRED: " .. l[3])
        b.verdadeiro(string.find(l[4], "BOUGHT (1)  3 items to collect", 1, true) ~= nil, "BOUGHT: " .. l[4])
        b.verdadeiro(string.find(l[5], "PENDING (1)  sale pending, gold arrives at 21:40", 1, true) ~= nil, "PENDING: " .. l[5])
        b.verdadeiro(string.find(l[6], "CHECK  waiting for you to take the mail", 1, true) ~= nil, "CHECK: " .. l[6])
        b.igual(b.ns.__correio.estado, "READY", "estado em palavra")
      end },
    { clique = "PregaoForeverCorreioDispensar" },
    { chamar = function(b)
        b.falso(PregaoForeverCorreio:IsShown(), "Dismiss fecha o painel")
        b.ns.correio.painel = function() return { mostradas = 11, total = 14, maisCartas = true, faturas = {}, aCaminho = 0 } end
      end },
    { evento = { "MAIL_SHOW" } },
    { avancar = 1 },
    { chamar = function(b)
        b.verdadeiro(PregaoForeverCorreio:IsShown(), "reabre no proximo MAIL_SHOW")
        local l = b.ns.__correio.linhas
        b.verdadeiro(string.find(l[1], "MORE MAIL WAITING - 11 of 14 letters shown", 1, true) ~= nil, "MORE MAIL WAITING: " .. l[1])
        b.verdadeiro(string.find(l[6], "not closed: the box shows less than the total", 1, true) ~= nil, "CHECK nao fecha: " .. l[6])
        b.igual(b.ns.__correio.estado, "MORE MAIL WAITING", "estado em palavra")
      end },
    { clique = "PregaoForeverCorreioSalvar" },
  },
  conferir = function(b)
    b.igual(b.contar("ReloadUI"), 1, "Save now recarregou com tudo em repouso")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
