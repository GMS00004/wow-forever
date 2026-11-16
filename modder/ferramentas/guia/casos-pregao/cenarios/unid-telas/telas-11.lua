-- Todo botao tem nome PregaoForever* e rotulo clicavel escrito; nenhum botao de acao.
return {
  id = "telas-11", grupo = "unid-telas",
  descricao = "nenhum botao sem nome PregaoForever*, todo botao com rotulo, nenhum botao de acao",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { abrir_leilao = true },
    { evento = { "MAIL_SHOW" } },
    { avancar = 1 },
  },
  conferir = function(b)
    local cs = b.chamadas("CreateFrame")
    local botoes = {}
    for i = 1, #cs do
      local a = cs[i].args
      if a[1] == "Button" then
        b.verdadeiro(type(a[2]) == "string" and string.sub(a[2], 1, 13) == "PregaoForever", "botao sem nome PregaoForever*: " .. tostring(a[2]))
        botoes[#botoes + 1] = a[2]
      end
    end
    b.verdadeiro(#botoes >= 15, "botoes criados: " .. #botoes)
    local esperados = { "PregaoForeverTeclaL", "PregaoForeverTeclaN", "PregaoForeverTeclaU", "PregaoForeverTeclaI",
      "PregaoForeverTeclaO", "PregaoForeverTeclaK", "PregaoForeverTeclaH", "PregaoForeverTeclaF3",
      "PregaoForeverTeclaF5", "PregaoForeverTeclaY", "PregaoForeverCorreioDispensar", "PregaoForeverCorreioSalvar" }
    for _, nome in ipairs(esperados) do
      local f = _G[nome]
      b.verdadeiro(f ~= nil, "existe " .. nome)
      if f then
        b.verdadeiro(f.fs ~= nil and f.fs:GetText() ~= "", "rotulo clicavel em " .. nome)
        b.verdadeiro(f:GetScript("OnClick") ~= nil, "OnClick em " .. nome)
      end
    end
    b.verdadeiro(_G.PregaoForeverTeclaP == nil and _G.PregaoForeverTeclaB == nil and _G.PregaoForeverTeclaC == nil
      and _G.PregaoForeverTeclaM == nil and _G.PregaoForeverTeclaF1 == nil and _G.PregaoForeverTeclaF2 == nil
      and _G.PregaoForeverTeclaF4 == nil, "nenhum botao de acao nem de visao da onda 3")
    b.igual(b.contar("EnableKeyboard"), 0, "nenhuma caixa de texto nem teclado capturado")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
