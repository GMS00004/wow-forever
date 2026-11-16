-- Janela.lua: a janela abre com o leilao e fecha com ele, a direita do AuctionHouseFrame, no tamanho do Config.
return {
  id = "telas-01", grupo = "unid-telas",
  descricao = "a janela abre no AUCTION_HOUSE_SHOW, fica a direita do leilao e fecha no AUCTION_HOUSE_CLOSED",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { chamar = function(b)
        b.verdadeiro(PregaoForeverJanela ~= nil, "o quadro existe depois da carga")
        b.falso(PregaoForeverJanela:IsShown(), "fechada antes do leilao")
        b.falso(b.ns.janela.aberta(), "ns.janela.aberta() falso antes do leilao")
      end },
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
        b.verdadeiro(PregaoForeverJanela:IsShown(), "aberta com o leilao")
        b.verdadeiro(b.ns.janela.aberta(), "ns.janela.aberta() verdadeiro")
        b.igual(PregaoForeverJanela:GetWidth(), 520, "largura do Config")
        b.igual(PregaoForeverJanela:GetHeight(), 500, "altura do Config")
        local ponto, rel, relPonto = PregaoForeverJanela:GetPoint(1)
        b.igual(ponto, "TOPLEFT", "ancora no canto de cima")
        b.verdadeiro(rel == AuctionHouseFrame, "ancorada ao AuctionHouseFrame")
        b.igual(relPonto, "TOPRIGHT", "a direita do leilao")
        b.igual(b.tela().visao, "mine", "visao inicial da onda 2")
        b.verdadeiro(#b.tela().linhas > 0, "a tela desenhou linhas")
      end },
    { fechar_leilao = true },
    { avancar = 1 },
  },
  conferir = function(b)
    b.falso(PregaoForeverJanela:IsShown(), "fechada com o leilao")
    b.falso(b.ns.janela.aberta(), "ns.janela.aberta() falso depois de fechar")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
