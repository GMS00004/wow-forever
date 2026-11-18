-- Categorias: cor pelo tamanho do lucro e etiqueta pelo tipo de cada linha.
return {
  id = "compra-11", grupo = "compra",
  descricao = "categorias do painel: cabecalho BIG, small ou skip pela cor do lucro e etiqueta [BAGS] quando o craft usa material da bolsa",
  inicio = {
    dinheiro = 51400,
    itens = {
      [4461] = { nome = "Raptor Hide", vend = 208, pilha = 10 },
      [4234] = { nome = "Heavy Leather", vend = 150, pilha = 20 },
      [2321] = { nome = "Fine Thread", vend = 25, pilha = 20 },
      [4455] = { nome = "Raptor Hide Harness", vend = 3096, pilha = 1 },
    },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4234, qtd = 8 },
      { bolsa = 0, slot = 2, itemID = 2321, qtd = 4 },
    },
    receitas = {
      [4096] = { nome = "Raptor Hide Harness", produto = 4455, qtd = 1, reagentes = { { 4461, 6 }, { 4234, 4 }, { 2321, 2 } } },
    },
    sv_char = { conhecidas = { quem = "Hexumlite", em = 1, ids = { [4096] = true }, n = 1 } },
    mercado = {
      ["4461"] = { { preco = 130, qtd = 8 }, { preco = 160, qtd = 100 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      local cfg = ns.config()
      local function tem(trecho)
        for _, l in ipairs(ns.montarLinhas()) do
          if string.find(l, trecho, 1, true) then return true end
        end
        return false
      end
      -- o Heavy Leather vem da bolsa: a linha e [BAGS]
      b.verdadeiro(tem("[BAGS] 2x Raptor Hide Harness"), "linha [BAGS] com o craft")
      cfg.grande, cfg.pequena = 1, 1
      b.verdadeiro(tem("|cff33ff33BIG +"), "cabecalho BIG em verde com limite baixo")
      cfg.grande, cfg.pequena = 10000000, 1
      b.verdadeiro(tem("|cffffd100small +"), "cabecalho small em amarelo")
      cfg.grande, cfg.pequena = 10000000, 10000000
      b.verdadeiro(tem("|cff999999skip +"), "cabecalho skip em cinza")
      b.verdadeiro(tem("(not worth it)"), "skip diz que nao vale")
      cfg.grande, cfg.pequena = 10000, 3000
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
