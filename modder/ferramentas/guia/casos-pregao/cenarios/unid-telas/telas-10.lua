-- As telas desenham sem erro com os outros modulos ausentes (so os esqueletos da onda 1): tracos no lugar dos numeros.
return {
  id = "telas-10", grupo = "unid-telas",
  -- os modulos que perdem as funcoes podem errar; o que se confere e que nenhum erro vem da interface
  aceita_erros = true,
  descricao = "Session, Mine, sonda e painel do correio desenham sem erro com os outros modulos ausentes",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { chamar = function(b)
        local ns = b.ns
        -- com o addon inteiro carregado, o cenario tira ele mesmo as funcoes que a tela le
        ns.livro.sessao, ns.cofre.banca, ns.cofre.disjuntores, ns.correio.painel = nil, nil, nil, nil
        ns.varredura.estado, ns.pedidos.estado, ns.banco.naoSalvo = nil, nil, nil
      end },
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
        b.ns.telas.mostrar("session")
        local t = table.concat(b.tela().linhas, "\n")
        b.verdadeiro(string.find(t, "BUDGET  -   FREE -   STOCK -   DEPOSITS -   IN MAIL -", 1, true) ~= nil, "orcamento em tracos")
        b.verdadeiro(string.find(t, "SESSION  -", 1, true) ~= nil, "sessao em traco")
        b.verdadeiro(string.find(t, "PRICES  not read yet", 1, true) ~= nil, "precos ainda nao lidos")
        b.verdadeiro(string.find(t, "MODE  READ ONLY", 1, true) ~= nil, "modo em palavra")
        b.ns.telas.mostrar("mine")
        t = table.concat(b.tela().linhas, "\n")
        b.verdadeiro(string.find(t, "deposits at risk -", 1, true) ~= nil, "deposito em traco")
        b.ns.telas.mostrar("sonda")
        b.ns.telas.redesenharCorreio()
        b.igual(b.ns.__correio.linhas[1], "  STATE  -", "correio sem modulo")
      end },
    { evento = { "MAIL_SHOW" } },
    { avancar = 1 },
    { chamar = function(b)
        b.verdadeiro(PregaoForeverCorreio:IsShown(), "painel do correio abriu")
        b.verdadeiro(b.ns.janela.correioAberto(), "correioAberto")
      end },
    { evento = { "MAIL_CLOSED" } },
    { avancar = 1 },
  },
  conferir = function(b)
    b.falso(PregaoForeverCorreio:IsShown(), "painel fechou com MAIL_CLOSED")
    local daTela = {}
    for _, e in ipairs(b.erros()) do
      for _, arq in ipairs({ "Telas.lua", "Janela.lua", "Visual.lua", "Teclas.lua", "Sonda.lua" }) do
        if string.find(tostring(e), arq, 1, true) then daTela[#daTela + 1] = e end
      end
    end
    b.igual(daTela, {}, "nenhum erro de Lua vindo da interface")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
