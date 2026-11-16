-- Sonda.lua e cartao da sonda: ns.janela.abrir('sonda'); S1 carimba o clique de salvar e o ADDON_LOADED seguinte.
return {
  id = "telas-09", grupo = "unid-telas",
  descricao = "cartao da sonda abre por ns.janela.abrir('sonda'); a S1 grava o clique e o carregamento seguinte",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { chamar = function(b)
        b.falso(PregaoForeverJanela:IsShown(), "fora do leilao a janela comeca fechada")
        b.ns.janela.abrir("sonda")
      end },
    { avancar = 1 },
    { chamar = function(b)
        b.verdadeiro(PregaoForeverJanela:IsShown(), "abriu fora do leilao")
        b.igual(b.contar("SetOverrideBindingClick"), 0, "fora do leilao nao ha binding")
        b.igual(b.tela().visao, "sonda", "visao sonda")
        b.igual(b.tela().selecionada, 1, "passo 1")
        local t = table.concat(b.tela().linhas, "\n")
        for _, rot in ipairs({ "STEP", "DO", "READS", "RESULT", "LIMIT" }) do
          b.verdadeiro(string.find(t, rot, 1, true) ~= nil, "rotulo " .. rot)
        end
        b.verdadeiro(string.find(t, "S1 (1 of 7)", 1, true) ~= nil, "S1, passo 1 de 7")
        b.verdadeiro(string.find(t, "waiting for the game", 1, true) ~= nil, "sem resultado ainda")
        b.verdadeiro(PregaoForeverSondaPular:IsShown() and PregaoForeverSondaSalvar:IsShown(), "botoes Skip step e Save now")
        b.igual(b.tela().estado, "READY", "passo pronto")
        local ids = {}
        for i = 1, #b.ns.sonda.passos do ids[i] = b.ns.sonda.passos[i].id end
        b.igual(ids, { "S1", "S3", "S4", "S5", "S9", "S12", "S13" }, "os sete passos da onda 2")
      end },
    { tecla = "N" },
    { avancar = 0.1 },
    { chamar = function(b)
        b.verdadeiro(b.ns.janela.aberta(), "o clique so vale com a janela aberta")
      end },
    { clique = "PregaoForeverSondaPular" },
    { avancar = 0.1 },
    { chamar = function(b)
        b.igual(b.tela().selecionada, 3, "Skip step vai ao passo seguinte (S4)")
        b.verdadeiro(string.find(table.concat(b.tela().linhas, "\n"), "S4 (3 of 7)", 1, true) ~= nil, "cartao do S4")
        b.ns.telas.mostrar("sonda")
        b.ns.sonda.atual = 1
        -- espia so o cod.sonda, sem trocar o resto do banco (o fechar da sessao usa os outros cod)
        local original = b.ns.banco.cod.sonda
        b.ns.banco.cod.sonda = function(t)
          b.__cod = t
          return original(t)
        end
      end },
    { clique = "PregaoForeverSondaSalvar" },
    -- o ReloadUI recarregou o addon com o banco gravado
    { avancar = 1 },
  },
  conferir = function(b)
    b.igual(b.contar("ReloadUI"), 1, "Save now recarregou uma vez")
    b.verdadeiro(b.__cod ~= nil and string.find(b.__cod.resultado, "^click=%d+$") ~= nil, "cod.sonda recebeu o carimbo do clique")
    local s1 = b.db().sonda.S1
    b.verdadeiro(string.find(s1, "^1|%d+|70938|click=%d+ load=%d+ gap=%d+s$") ~= nil, "S1 com clique e carregamento: " .. tostring(s1))
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
