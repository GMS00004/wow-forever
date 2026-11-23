-- Full scan sem o evento REPLICATE_ITEM_LIST_UPDATE: termina pela contagem estavel, recarga de 900 s, abortar ao fechar a AH.
local ini, ini_t, ant = nil, nil, nil
return {
  id = "compra-03", grupo = "compra",
  descricao = "fullScan com replicate_sem_evento: contagem estavel, escadas, ultimoFull, recarga e aborto ao fechar a AH",
  inicio = {
    dinheiro = 100000,
    itens = { [7000] = { nome = "Fancy Gem", vend = 1000, pilha = 1 } },
    mercado = {
      ["2589"] = { { preco = 11, qtd = 40 }, { preco = 9, qtd = 14, donos = 2 }, { preco = 5, qtd = 3, proprio = true } },
      ["2592"] = { { preco = 35, qtd = 5 } },
      ["7000"] = { { preco = 1500, qtd = 1 }, { preco = 300, qtd = 1 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { tecla_dono = true },
    { injetar = "replicate_sem_evento" },
    { chamar = function(b)
      ini, ini_t = b.agora(), time()
      local ok = b.ns.fullScan(function(scan, m) b.ns.terminou = { scan = scan, m = m, t = b.agora() } end)
      b.verdadeiro(ok, "fullScan comecou")
      b.verdadeiro(b.ns.scanEstado.ocupado, "ocupado")
      local ok2, m2 = b.ns.fullScan()
      b.falso(ok2, "segundo fullScan enquanto ocupado")
      b.igual(m2, "busy", "motivo busy")
    end },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      local fim = ns.terminou
      b.verdadeiro(fim ~= nil and fim.scan == ns.scan, "aoTerminar chamado com o scan")
      b.igual(#b.eventos("REPLICATE_ITEM_LIST_UPDATE"), 0, "o evento nao chegou")
      b.verdadeiro(fim ~= nil and fim.t - ini >= 7.5 and fim.t - ini <= 9, "terminou pela contagem estavel (~8 s): " .. tostring(fim and (fim.t - ini)))
      local sc = ns.scan
      b.igual(sc.tipo, "full", "tipo")
      b.igual(sc.escadas[2589], {
        { preco = 9, qtd = 14, inteiro = true }, { preco = 11, qtd = 40, inteiro = true },
      }, "escada de 2589: crescente, sem o dono")
      b.igual(sc.escadas[2592], { { preco = 35, qtd = 5, inteiro = true } }, "escada de 2592")
      b.igual(sc.escadas[7000][1].preco, 300, "escada de 7000")
      b.igual(sc.revenda[2589], 13, "revenda 2589")
      b.igual(sc.revenda[7000], 1000, "revenda 7000")
      b.igual(ns.scanEstado.ocupado, false, "livre")
      b.igual(CompraForeverDB.ultimoFull, ini_t, "ultimoFull gravado no pedido")
      -- livro do full no SavedVariables (CONTRATO secao 11): unidades;lotes;preco:qtd, sem o dono
      local fu = CompraForeverDB.full
      b.verdadeiro(type(fu) == "table" and fu.n == 3, "CompraForeverDB.full com 3 itens")
      b.igual(fu and fu.em, sc.em, "hora do full no livro")
      b.igual(fu and fu.itens[2589], "54;2;9:14,11:40", "livro de 2589")
      b.igual(fu and fu.itens[2592], "5;1;35:5", "livro de 2592")
      b.igual(fu and fu.itens[7000], "2;2;300:1,1500:1", "livro de 7000")
      -- revenda entra no plano so no full
      local p = ns.plano
      b.verdadeiro(p ~= nil, "ns.plano existe")
      b.verdadeiro(p and p.revenda[1] ~= nil and p.revenda[1].id == 7000, "plano revende a gema")
      ant = sc
      -- recarga
      local ok, m, resta = ns.fullScan()
      b.falso(ok, "segunda chamada recusada")
      b.igual(m, "cooldown", "motivo")
      b.verdadeiro(resta > 800 and resta <= 900, "restante: " .. tostring(resta))
      b.igual(#b.chamadas("ReplicateItems"), 1, "um unico ReplicateItems")
    end },
    { avancar = 901 },
    { tecla_dono = true },
    { chamar = function(b)
      b.ns.terminou = nil
      local ok = b.ns.fullScan(function(scan, m) b.ns.terminou = { scan = scan, m = m } end)
      b.verdadeiro(ok, "depois de 900 s o full scan volta")
    end },
    { avancar = 2 },
    { fechar_leilao = true },
    { ate_ocioso = true },
  },
  conferir = function(b)
    local ns = b.ns
    b.verdadeiro(ns.terminou ~= nil and ns.terminou.scan == nil and ns.terminou.m == "closed", "aoTerminar(nil, closed)")
    b.verdadeiro(ns.scan == ant, "mantem o scan anterior")
    b.igual(CompraForeverDB.full and CompraForeverDB.full.em, ant.em, "o full abortado nao troca o livro gravado")
    b.igual(ns.scanEstado.ocupado, false, "livre depois do aborto")
    b.igual(#b.chamadas("ReplicateItems"), 2, "dois ReplicateItems")
    local ok, m = ns.fullScan()
    b.falso(ok, "AH fechada recusa")
    b.igual(m, "closed", "motivo")
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
