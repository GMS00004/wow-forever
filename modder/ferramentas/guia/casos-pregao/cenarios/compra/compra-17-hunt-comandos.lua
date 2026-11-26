-- Caca (secao 13): /compra hunt liga, ajusta, mostra e desliga; /compra key liga a tecla so com a AH aberta.
local falas = {}
local function capturar()
  local antigo = print
  falas = {}
  print = function(...)
    local t = {}
    for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
    falas[#falas + 1] = table.concat(t, " ")
  end
  return function() print = antigo end
end
local function disse(b, trecho, msg)
  for _, f in ipairs(falas) do
    if string.find(f, trecho, 1, true) then return end
  end
  b.verdadeiro(false, msg .. " (nao achei '" .. trecho .. "' em: " .. table.concat(falas, " | ") .. ")")
end

return {
  id = "compra-17", grupo = "compra",
  descricao = "caca: /compra hunt (ligar, ajustar sem zerar, mostrar, uso errado, off com resumo, persiste no reload); /compra key so com a AH aberta",
  inicio = {
    dinheiro = 100000,
    itens = {
      [4304] = { nome = "Thick Leather", vend = 70, pilha = 20 },
      [8170] = { nome = "Rugged Leather", vend = 100, pilha = 20 },
    },
  },
  passos = {
    { chamar = function(b)
      local volta = capturar()
      SlashCmdList.COMPRAFOREVER("hunt")
      SlashCmdList.COMPRAFOREVER("hunt 4304 5s20c")
      volta()
      disse(b, "hunt is off. usage: /compra hunt", "sem caca")
      disse(b, "hunting Thick Leather (4304) <= 5s 20c, cap 5g (default). Click the action button", "ligou com a trava padrao")
      local c = CompraForeverCharDB.caca
      b.igual(c.id, 4304, "id")
      b.igual(c.alvo, 520, "alvo em cobre")
      b.igual(c.trava, 50000, "trava padrao 5g")
      b.igual(c.gasto, 0, "gasto zero")
      b.igual(c.qtd, 0, "qtd zero")
      b.igual(c.log, {}, "registro vazio")
    end },
    -- mesmo item: troca o alvo e a trava sem zerar o gasto
    { chamar = function(b)
      CompraForeverCharDB.caca.gasto, CompraForeverCharDB.caca.qtd = 1000, 2
      local volta = capturar()
      SlashCmdList.COMPRAFOREVER("hunt |cffffffff|Hitem:4304::::::::60:::::|h[Thick Leather]|h|r 5s30c 2g")
      SlashCmdList.COMPRAFOREVER("hunt")
      SlashCmdList.COMPRAFOREVER("hunt 4304")
      SlashCmdList.COMPRAFOREVER("hunt 4304 5s xyz")
      SlashCmdList.COMPRAFOREVER("hunt xyz 5s")
      volta()
      disse(b, "hunt updated: Thick Leather (4304) <= 5s 30c, cap 2g. Click the action button", "ajustou pelo link")
      disse(b, "hunting Thick Leather (4304) <= 5s 30c, bought 2 avg 5s, spent 10s of 2g", "mostra com a media")
      disse(b, "usage: /compra hunt <item id or link> <price> [cap]", "uso errado")
      local c = CompraForeverCharDB.caca
      b.igual(c.alvo, 530, "alvo novo")
      b.igual(c.trava, 20000, "trava nova")
      b.igual(c.gasto, 1000, "gasto mantido")
    end },
    -- item novo zera
    { chamar = function(b)
      SlashCmdList.COMPRAFOREVER("hunt 8170 11s")
      local c = CompraForeverCharDB.caca
      b.igual(c.id, 8170, "item novo")
      b.igual(c.gasto, 0, "gasto zerado no item novo")
      b.igual(c.nome, "Rugged Leather", "nome")
    end },
    -- a tecla: gravada fechada, ligada so com a AH aberta
    { chamar = function(b)
      local volta = capturar()
      SlashCmdList.COMPRAFOREVER("key")
      SlashCmdList.COMPRAFOREVER("key button4")
      SlashCmdList.COMPRAFOREVER("key a;b")
      volta()
      disse(b, "key none (only while the AH is open)", "sem tecla")
      disse(b, "key BUTTON4 clicks the action button while the AH is open", "gravou em maiusculas")
      disse(b, "usage: /compra key", "tecla invalida")
      b.igual(CompraForeverDB.tecla, "BUTTON4", "tecla gravada")
      b.verdadeiro(__bancada.bindings[CompraForeverPainel] == nil, "AH fechada: nada ligado")
    end },
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
      local d = __bancada.bindings[CompraForeverPainel]
      b.verdadeiro(d ~= nil, "AH aberta: tecla ligada")
      b.igual(d and d.BUTTON4, "CompraForeverAcao", "BUTTON4 clica o botao de acao")
      b.igual(CompraForeverAcao:GetText(), "Hunt Rugged Leather <= 11s", "botao da caca")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "habilitado")
      b.igual(b.contar("SendSearchQuery"), 0, "nada busca sem clique")
    end },
    { avancar = 30 },
    { chamar = function(b)
      b.igual(b.contar("SendSearchQuery"), 0, "caca nao busca sozinha")
    end },
    { fechar_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
      b.verdadeiro(__bancada.bindings[CompraForeverPainel] == nil, "AH fechada: tecla solta")
    end },
    { reload = true },
    { chamar = function(b)
      b.igual(b.ns.cacaDB() and b.ns.cacaDB().id, 8170, "caca persiste no reload")
      b.igual(CompraForeverDB.tecla, "BUTTON4", "tecla persiste")
      local volta = capturar()
      SlashCmdList.COMPRAFOREVER("hunt off")
      SlashCmdList.COMPRAFOREVER("hunt off")
      SlashCmdList.COMPRAFOREVER("key off")
      volta()
      disse(b, "hunt off: Rugged Leather (8170) <= 11s, bought 0 avg -, spent 0c of 5g", "resumo ao desligar")
      disse(b, "hunt is off", "off de novo")
      disse(b, "key off", "tecla desligada")
      b.verdadeiro(CompraForeverCharDB.caca == nil, "caca apagada")
      b.verdadeiro(CompraForeverDB.tecla == nil, "tecla apagada")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
