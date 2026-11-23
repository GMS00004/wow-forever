-- Dados.lua REAL (sem inicio.dados), Engineering 1-150: so conferencias estruturais, porque a rota real muda a cada rodada de precos.
-- O mercado do falso e montado a partir dos proprios dados (a fonte L de cada item, 90% do teto, muitas unidades), o modo vem do
-- comando /compra mode eng 150 e a pericia do sv_char. Confere: o plano nao quebra, tem linhas de leilao que existem nos dados
-- com teto = floor(teto * 110 / 100) > 0, passos e crafts batem com os passos da rota abaixo do alvo, o scan dirigido busca os ids
-- do plano e o botao de acao tem a primeira compra.
local MOTIVOS = { fim = true, limite = true, dinheiro = true, espaco = true, preco = true, semPreco = true, bloqueio = true }

local function montarMercado(b)
  local A = __bancada.A
  local dados = CompraForeverDados.rotas
  local rota = dados.profs.engineering
  local n = 0
  for _, t in ipairs(rota.trechos) do
    local ids = {}
    for id in pairs(t.fontes) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
      local f = t.fontes[id]
      local it = dados.itens[id]
      A.itens[id] = A.itens[id] or { nome = it and it.nome or ("Item " .. id), vend = it and it.vende or 0, pilha = it and it.pilha or 20 }
      if f.f == "L" or (f.f == "F" and f.teto) then
        local teto = f.teto or math.max(1, math.floor((f.custo or 1) / math.max(1, f.qtd or 1)))
        local pilha = (it and it.pilha) or 20
        n = n + 1
        local preco = math.max(1, math.floor(teto * 0.9))
        if pilha > 1 then
          A.mercado[id] = { { id = 800000 + n, preco = preco, qtd = 100000, donos = 1 } }
        else
          A.mercado[id] = { { id = 800000 + n, preco = preco, qtd = 1, donos = 1 }, { id = 900000 + n, preco = preco, qtd = 1, donos = 1 },
            { id = 950000 + n, preco = preco, qtd = 1, donos = 1 } }
        end
      end
    end
  end
  b.verdadeiro(n > 0, "o mercado montado dos dados reais tem itens (" .. n .. ")")
end

return {
  id = "rota-25", grupo = "rota",
  descricao = "Dados.lua real, Engineering 150: linhas batem com os dados, tetos positivos, passos da rota, scan dirigido, sem erro",
  inicio = {
    dinheiro = 5000000,
    nivel = 10,
    parametros = { tamanho_bolsa = 40 },
    profissoes = { { id = 202, nome = "Engineering", nivel = 1, max = 75 } },
    perto = { Anvil = true },
    sv_char = { versao = 2, modo = { tipo = "lucro" },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
      montarMercado(b)
      SlashCmdList.COMPRAFOREVER("mode eng 150")
      b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 150 }, "modo Eng 150")
      local dados = CompraForeverDados.rotas
      b.verdadeiro(dados ~= nil and dados.profs.engineering ~= nil, "os dados reais tem a rota da Engineering")
      b.verdadeiro(#dados.profs.engineering.trechos >= 1, "a rota tem trechos")
    end },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { chamar = function(b)
      local ns = b.ns
      local p = ns.plano
      local R = p.rota
      local dados = CompraForeverDados.rotas
      local rota = dados.profs.engineering
      b.verdadeiro(p ~= nil and p.modo == 2, "plano de rota")
      b.igual(R.estado, "ok", "estado ok")
      b.igual(R.alvo, 150, "alvo 150")
      b.verdadeiro(R.limite >= 75, "limite do nivel positivo: " .. tostring(R.limite))
      b.verdadeiro(MOTIVOS[p.motivo] == true, "motivo conhecido: " .. tostring(p.motivo))
      b.verdadeiro(R.atual ~= nil and R.atual.faltam > 0, "ha um passo atual com crafts")
      b.verdadeiro(R.restante > 0, "restante positivo")
      b.verdadeiro(#R.scan > 0, "o scan dirigido tem ids")

      -- passos: os da rota que comecam abaixo do alvo, na ordem, com ate cortado no alvo
      local esperado = {}
      for _, t in ipairs(rota.trechos) do
        for _, s in ipairs(t.passos) do
          if s.de < 150 then esperado[#esperado + 1] = s end
        end
      end
      b.igual(#R.passos, #esperado, "passos do plano = passos da rota abaixo do alvo")
      for i, s in ipairs(esperado) do
        local x = R.passos[i]
        b.igual({ x.magia, x.de, x.ate > 150 and 150 or x.ate }, { s.magia, s.de, math.min(s.ate, 150) }, "passo " .. i)
        b.verdadeiro(x.n >= 0, "n do passo " .. i .. " nao negativo")
      end

      -- linhas de leilao: existem nos dados (fonte L ou F com teto), tetos positivos
      b.verdadeiro(#p.leilao > 0, "ha linhas de leilao")
      local fontes = {}
      for _, t in ipairs(rota.trechos) do
        for id, f in pairs(t.fontes) do fontes[id] = fontes[id] or f end
      end
      local gasto, ultimoPasso = 0, 0
      for i, l in ipairs(p.leilao) do
        local f = fontes[l.id]
        b.verdadeiro(f ~= nil and (f.f == "L" or (f.f == "F" and f.teto ~= nil)), "linha " .. i .. " (" .. tostring(l.nome) .. ") esta nos dados como L ou F com teto")
        b.verdadeiro(l.qtd > 0 and l.custo > 0, "linha " .. i .. ": quantidade e custo positivos")
        b.verdadeiro(l.teto > 0, "linha " .. i .. ": teto positivo")
        if f and f.teto then b.igual(l.teto, math.floor(f.teto * 110 / 100), "linha " .. i .. ": teto = floor(teto * 110 / 100)") end
        b.verdadeiro(l.passo >= ultimoPasso, "linha " .. i .. ": ordem de passo")
        ultimoPasso = l.passo
        gasto = gasto + l.custo
      end
      for _, v in ipairs(p.vendedor) do
        b.verdadeiro(fontes[v.id] ~= nil and fontes[v.id].f == "V", "linha de vendedor " .. tostring(v.nome) .. " e fonte V nos dados")
        gasto = gasto + v.custo
      end
      b.igual(p.totais.gasto, gasto, "gasto = soma das linhas")
      b.verdadeiro(p.totais.gasto <= GetMoney(), "gasto dentro do dinheiro")
      b.verdadeiro(#p.crafts >= 1, "ha crafts no trecho de compra")
      for i, c in ipairs(p.crafts) do b.verdadeiro(c.n > 0, "craft " .. i .. " com n positivo") end
      b.verdadeiro(R.chega > 1 and R.chega <= 150, "chega entre 2 e 150: " .. tostring(R.chega))

      -- botao de acao e Scan dirigido
      b.igual(b.contar("SendSearchQuery"), #R.scan, "uma busca por id do plano")
      local texto = CompraForeverAcao:GetText()
      b.verdadeiro(string.find(texto, "^Buy ") ~= nil, "o botao de acao comeca a comprar: " .. tostring(texto))
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
  end,
}
