-- Visao Mine com falsos de banco e cofre: secao de cinco linhas com Show N more, N/U, I, O e K.
return {
  id = "telas-12", grupo = "unid-telas",
  descricao = "Mine: cinco linhas por secao e Show 2 more; N, U, I, O e K mexem so na tela",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { chamar = function(b)
        local ns = b.ns
        ns.banco.pers = function()
          return { proprios = {
            ["771"] = "1|771|0|20|36000|0|35200|1794874200",
            ["772"] = "1|772|1|1|3600|0|20000|1794874200",
            ["773"] = "1|773|0|10|50000|0|9000|1794874200",
            ["774"] = "1|774|0|1|1000|0|5000|1794874200",
            ["775"] = "1|775|0|5|20000|0|2500|1794874200",
          } }
        end
        ns.cofre = { banca = function()
          return { B = 40000, livre = 31286, stock = 0, estoque = 640, deposito = 14, correio = 230 }
        end, disjuntores = function() return { "BUYING HALTED - 3 items gone in a row" } end }
      end },
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
        local t = b.tela().linhas
        local txt = table.concat(t, "\n")
        b.verdadeiro(string.find(txt, "BUDGET  4g   FREE 3g 12s 86c   STOCK 6s 40c   DEPOSITS 14c   IN MAIL 2s 30c", 1, true) ~= nil, "linha BUDGET")
        b.verdadeiro(string.find(txt, "MY AUCTIONS (5)  deposits at risk 14c", 1, true) ~= nil, "cabecalho com a contagem")
        b.verdadeiro(string.find(txt, "Show 2 more", 1, true) ~= nil, "Show 2 more")
        b.verdadeiro(string.find(txt, "Auction 774", 1, true) == nil, "o quarto leilao ficou no Show 2 more")
        b.verdadeiro(string.find(txt, "BREAKERS BUYING HALTED - 3 items gone in a row", 1, true) ~= nil, "disjuntor ligado na linha de estado")
        b.verdadeiro(string.find(txt, "Auction 772 x1  SOLD", 1, true) ~= nil, "leilao vendido em palavra")
        b.igual(b.tela().selecionada, 1, "a primeira linha vem selecionada")
        b.verdadeiro(string.find(txt, "> Auction 771 x20", 1, true) ~= nil, "seta na linha selecionada")
        b.falso(string.find(txt, "LIMITS", 1, true) ~= nil, "sem LIMITS")
        b.falso(string.find(txt, "STAND DOWN", 1, true) ~= nil, "sem STAND DOWN")
      end },
    { tecla = "N" },
    { avancar = 0.5 },
    { tecla = "N" },
    { avancar = 0.5 },
    { tecla = "N" },
    { avancar = 0.5 },
    { tecla = "N" },
    { avancar = 0.5 },
    { chamar = function(b)
        b.igual(b.tela().selecionada, 3, "N para na ultima linha visivel")
      end },
    { tecla = "U" },
    { avancar = 0.5 },
    { tecla = "I" },
    { avancar = 0.5 },
    { chamar = function(b)
        b.igual(b.tela().selecionada, 2, "U volta uma linha")
        local txt = table.concat(b.tela().linhas, "\n")
        b.verdadeiro(string.find(txt, "WHY  Auction 772 x1", 1, true) ~= nil, "I mostra a conta da linha")
        b.verdadeiro(string.find(txt, "state SOLD", 1, true) ~= nil, "conta com o estado")
      end },
    { tecla = "O" },
    { avancar = 0.5 },
    { chamar = function(b)
        local txt = table.concat(b.tela().linhas, "\n")
        b.verdadeiro(string.find(txt, "Show less", 1, true) ~= nil, "O mostra o resto")
        b.verdadeiro(string.find(txt, "Auction 775", 1, true) ~= nil, "a quinta linha aparece")
      end },
    { tecla = "K" },
    { avancar = 0.5 },
  },
  conferir = function(b)
    local txt = table.concat(b.tela().linhas, "\n")
    b.verdadeiro(string.find(txt, "MY AUCTIONS (4)", 1, true) ~= nil, "K tirou a linha da lista")
    b.verdadeiro(string.find(txt, "Auction 772", 1, true) == nil, "a linha pulada sumiu")
    b.igual(b.contar("CancelAuction") + b.contar("PostItem") + b.contar("PlaceBid"), 0, "so leitura")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
