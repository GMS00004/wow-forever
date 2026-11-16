-- Banco novo: sem SavedVariables, o ADDON_LOADED cria PregaoForeverDB com esquema, epoca e a marca bancoDesde do personagem.
return {
  id = "banco-02", grupo = "unid-banco",
  descricao = "sem SV, o ADDON_LOADED cria banco novo com esquema, epoca e bancoDesde",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {},
  conferir = function(b)
    local db = b.db()
    b.verdadeiro(db ~= nil, "banco criado no ADDON_LOADED")
    b.igual(db.esquema, 1, "esquema 1")
    b.igual(db.epoca, b.ns.servidor(), "epoca e a hora da criacao")
    b.igual(db.seq, 0, "seq zero")
    b.igual(db.fim, 0, "fim zero, igual ao seq: saida limpa")
    b.igual(PregaoForeverCharDB.bancoDesde, db.epoca, "bancoDesde do personagem igual a epoca")
    b.igual(b.ns.banco.carregado, true, "carregado")
    b.igual(b.ns.banco.fimSujo, false, "sem fim sujo num banco novo")
    b.igual(b.ns.faixa ~= "DATABASE NOT LOADED - tell the agent", true, "a faixa do banco nao aparece")
    b.igual(b.ns.modo(), "leitura", "modo leitura vindo do Config")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
