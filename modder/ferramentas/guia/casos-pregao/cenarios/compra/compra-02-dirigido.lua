-- Busca dirigida: receita 4096 (4461 commodity, 4234 item de leilao inteiro, 2321 de vendedor que nao se busca).
-- Nos Dados reais o Heavy Leather (4234) tem preco de vendedor e por isso nao entraria na lista; o cenario tira o
-- vendedor dele para exercitar o caminho de item.
return {
  id = "compra-02", grupo = "compra",
  descricao = "scanDirigido: commodity e item, escadas em ordem, vendedor nao buscado, dono ignorado, plano com a receita",
  inicio = {
    dinheiro = 51400,
    itens = {
      [4461] = { nome = "Raptor Hide", vend = 208, pilha = 10 },
      [4234] = { nome = "Heavy Leather", vend = 150, pilha = 20, commodity = false },
      [2321] = { nome = "Fine Thread", vend = 25, pilha = 20 },
      [4455] = { nome = "Raptor Hide Harness", vend = 3096, pilha = 1 },
    },
    receitas = {
      [4096] = { nome = "Raptor Hide Harness", produto = 4455, qtd = 1, reagentes = { { 4461, 6 }, { 4234, 4 }, { 2321, 2 } } },
    },
    mercado = {
      ["4461"] = { { preco = 130, qtd = 50 }, { preco = 100, qtd = 30, donos = 2 }, { preco = 90, qtd = 5, proprio = true } },
      ["4234"] = { { preco = 2800, qtd = 4 }, { preco = 1200, qtd = 4 }, { preco = 500, qtd = 1, proprio = true } },
      ["2321"] = { { preco = 20, qtd = 10 } },
    },
  },
  passos = {
    { abrir_profissao = true },
    { avancar = 1 },
    { fechar_profissao = true },
    { chamar = function(b) CompraForeverDados.itens[4234].vendedor = nil end },
    { abrir_leilao = true },
    { tecla_dono = true },
    { chamar = function(b)
      b.igual(b.ns.idsDirigido(), { 4234, 4461 }, "ids da busca")
      local ok, motivo = b.ns.scanDirigido(function(scan, m) b.ns.terminou = { scan = scan, m = m, t = b.agora() } end)
      b.verdadeiro(ok, "scanDirigido comecou: " .. tostring(motivo))
      local ok2, m2 = b.ns.scanDirigido()
      b.falso(ok2, "segunda busca enquanto ocupado")
      b.igual(m2, "busy", "motivo busy")
      b.verdadeiro(b.ns.scanEstado.ocupado, "ocupado")
      b.igual(b.ns.scanEstado.total, 2, "total")
    end },
    { ate_ocioso = true },
  },
  conferir = function(b)
    local ns = b.ns
    b.verdadeiro(ns.terminou ~= nil and ns.terminou.scan == ns.scan, "aoTerminar chamado com o scan")
    local sc = ns.scan
    b.verdadeiro(sc ~= nil, "ns.scan existe")
    if not sc then return end
    b.igual(sc.tipo, "dirigido", "tipo")
    b.igual(sc.semResposta, {}, "todos responderam")
    b.igual(sc.revenda, nil, "sem revenda no dirigido")
    b.igual(ns.scanEstado, { ocupado = false, feito = 2, total = 2 }, "estado final")
    -- commodity: crescente, sem o anuncio do dono (90)
    local c = sc.escadas[4461]
    b.igual(#c, 2, "degraus de 4461")
    b.igual(c[1].preco, 100, "4461 mais barato primeiro")
    b.igual(c[1].qtd, 30, "4461 qtd")
    b.igual(c[1].inteiro, false, "commodity nao e inteiro")
    b.verdadeiro(c[1].leilao ~= nil, "auctionID")
    b.igual(c[2].preco, 130, "4461 segundo degrau")
    -- item: preco por unidade = buyout / qtd, inteiro
    local i = sc.escadas[4234]
    b.igual(#i, 2, "degraus de 4234 (sem o do dono)")
    b.igual(i[1].preco, 300, "4234: 1200 / 4")
    b.igual(i[1].qtd, 4, "4234 qtd")
    b.igual(i[1].inteiro, true, "item e inteiro")
    b.igual(i[2].preco, 700, "4234: 2800 / 4")
    -- vendedor nao foi buscado
    b.igual(sc.escadas[2321], nil, "2321 nao tem escada")
    local buscas = b.chamadas("SendSearchQuery")
    b.igual(#buscas, 2, "duas buscas")
    local ids = {}
    for k, r in ipairs(buscas) do ids[k] = r.args[1].itemID end
    b.igual(ids, { 4234, 4461 }, "ids buscados, em ordem")
    -- plano
    local p = ns.plano
    b.verdadeiro(p ~= nil, "ns.plano existe")
    if p then
      b.verdadeiro(p.crafts[1] ~= nil and p.crafts[1].magia == 4096, "plano tem a receita 4096")
      b.verdadeiro(p.totais.lucro > 0, "lucro positivo")
      b.verdadeiro(type(p.em) == "number", "plano.em")
      b.igual(CompraForeverCharDB.plano, p, "plano gravado no CharDB")
      local achou = {}
      for _, l in ipairs(p.leilao) do achou[l.id] = l end
      b.verdadeiro(achou[4461] ~= nil and achou[4234] ~= nil, "compras de 4461 e 4234 no leilao")
      b.verdadeiro(achou[4234] and achou[4234].inteiro, "4234 comprado inteiro")
      local v = {}
      for _, l in ipairs(p.vendedor) do v[l.id] = true end
      b.verdadeiro(v[2321], "2321 vem do vendedor")
    end
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
