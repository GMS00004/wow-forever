-- rota-19 (CONTRATO 12.5): Enchanting em rota propria (inicio.dados.rotas, ids ficticios): o passo de encantamento (receita
-- `encantar = true`, sem produto) mostra "Enchant manually (<n> left)", botao desligado, nenhum CraftRecipe nem CraftEnchant;
-- o passo da varinha (receita com produto) crafta normal pelo CraftRecipe.
--   passo 1: 900001 Minor Bracer Enchant 1-40 (encantar)    passo 2: 900002 Practice Wand 40-60 (produto 900103)
local B = __bancada

local function faltam(amarela, cinza, de, ate)
  local t = 0
  for x = de, ate - 1 do
    local c = x < amarela and 1 or (x >= cinza and 0 or (cinza - x) / (cinza - amarela))
    t = t + 1 / c
  end
  return math.ceil(t - 1e-9)
end

local itens = {
  [900101] = { nome = "Strange Dust Test", vende = 10, pilha = 20, vinculo = 0 },
  [900102] = { nome = "Test Essence", vende = 20, pilha = 20, vinculo = 0 },
  [900103] = { nome = "Practice Wand", vende = 500, pilha = 1, vinculo = 0 },
}

return {
  id = "rota-19", grupo = "rota",
  descricao = "Enchanting: passo de encantamento sem CraftRecipe nem CraftEnchant; varinha crafta normal",
  inicio = {
    dinheiro = 100000, nivel = 10, perto = {},
    profissoes = { { id = 333, nome = "Enchanting", nivel = 1, max = 75 } },
    itens = {
      [900101] = { nome = "Strange Dust Test", vend = 10, pilha = 20 },
      [900102] = { nome = "Test Essence", vend = 20, pilha = 20 },
      [900103] = { nome = "Practice Wand", vend = 500, pilha = 1 },
    },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 900101, qtd = 20 }, { bolsa = 0, slot = 2, itemID = 900101, qtd = 20 },
      { bolsa = 0, slot = 3, itemID = 900101, qtd = 20 }, { bolsa = 0, slot = 4, itemID = 900101, qtd = 20 },
      { bolsa = 0, slot = 5, itemID = 900102, qtd = 20 }, { bolsa = 0, slot = 6, itemID = 900102, qtd = 20 },
      { bolsa = 0, slot = 7, itemID = 900102, qtd = 20 }, { bolsa = 0, slot = 8, itemID = 900102, qtd = 20 },
    },
    receitas = {
      [900001] = { nome = "Minor Bracer Enchant", reagentes = { { 900101, 1 } }, encantar = true, amarela = 1, cinza = 70, pontos = 1,
        prof = 333 },
      [900002] = { nome = "Practice Wand", produto = 900103, qtd = 1, reagentes = { { 900102, 2 }, { 900101, 1 } }, amarela = 40,
        cinza = 80, pontos = 1, prof = 333 },
    },
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "enchanting", alvo = 60 },
      prof = { enchanting = { pericia = 1, max = 75, ids = { [900001] = true, [900002] = true }, n = 2, em = 1 } } },
    dados = { rotas = {
      versao = 1, geradoEm = B.EPOCH - 3600, fonte = { tipo = "full", em = B.EPOCH - 7200, n = 6944 }, credito = true,
      itens = itens,
      profs = { enchanting = {
        nome = "Enchanting", curto = "Ench", linha = 333,
        ranks = { { nome = "Journeyman Enchanting", cap = 150, pericia = 50, custo = 500, nivel = 10 } },
        receitas = {
          [900001] = { nome = "Minor Bracer Enchant", encantar = true, reagentes = { { 900101, 1 } }, amarela = 1, cinza = 70,
            pontos = 1, aprende = 1, origem = "inicial" },
          [900002] = { nome = "Practice Wand", produto = 900103, qtd = 1, reagentes = { { 900102, 2 }, { 900101, 1 } },
            amarela = 40, cinza = 80, pontos = 1, aprende = 1, origem = "inicial" },
        },
        trechos = { { de = 1, ate = 60, chegou = 60, totais = { custo = 0, crafts = 0, craftsExtra = 0 },
          passos = { { magia = 900001, de = 1, ate = 40, crafts = faltam(1, 70, 1, 40) },
                     { magia = 900002, de = 40, ate = 60, crafts = faltam(40, 80, 40, 60) } },
          fontes = {} } },
      } },
    } },
  },
  passos = {
    { abrir_profissao = { nome = "Enchanting" } },
    { avancar = 1 },
    { chamar = function(b)
      local R = b.ns.plano.rota
      local n1 = faltam(1, 70, 1, 40)
      b.igual(R.estado, "ok", "rota ok")
      b.igual({ R.atual.magia, R.atual.encantar }, { 900001, true }, "passo atual: o encantamento")
      b.igual(R.atual.faltam, n1, "faltam os crafts da formula")
      b.verdadeiro(n1 > 20, "mais que um lote: o texto nao e de craft")
      b.igual(b.ns.proximaAcao().texto, "Enchant manually (" .. n1 .. " left)", "texto da acao")
      b.igual(CompraForeverAcao:GetText(), "Enchant manually (" .. n1 .. " left)", "texto do botao")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desligado: o addon nao encanta")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 5 },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 0, "nenhum CraftRecipe do encantamento")
      b.igual(b.contar("CraftEnchant"), 0, "nenhum CraftEnchant")
      b.igual(C_Item.GetItemCount(900101), 80, "nenhum material consumido")
    end },
    -- o dono encanta a mao ate o 40: o passo da varinha
    { chamar = function(b) B.ROTA.profs[1].nivel = 40 end },
    { evento = "SKILL_LINES_CHANGED" },
    { avancar = 1 },
    { chamar = function(b)
      local R = b.ns.plano.rota
      b.igual(R.pericia, 40, "pericia 40 gravada")
      b.igual(R.atual.magia, 900002, "passo atual: a varinha")
      b.igual(R.atual.encantar, false, "varinha nao e encantamento")
      b.igual(CompraForeverAcao:GetText(), "Craft 20 Practice Wand", "craft normal da varinha")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    { clique = "CompraForeverAcao" },
    { ate_ocioso = true },
    { chamar = function(b)
      b.igual(b.contar("CraftRecipe"), 1, "um CraftRecipe")
      b.igual(b.chamadas("CraftRecipe")[1].args, { 900002, 20, n = 2 }, "so a varinha, 20 vezes")
      b.igual(b.contar("CraftEnchant"), 0, "ainda nenhum CraftEnchant")
      b.igual(C_Item.GetItemCount(900103), 20, "20 Practice Wand")
      b.igual(C_Item.GetItemCount(900102), 40, "essencia: 2 por varinha")
      local c = CompraForeverCharDB.rota.enchanting
      b.igual(c.craftado[900002], 20, "contador: 20 varinhas")
      b.igual(c.craftado[900001], nil, "contador: nenhum craft de encantamento do addon")
      b.igual(c.credito[900103], 20, "credito de venda das varinhas")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nenhum BuyTrainerService")
    for _, c in ipairs(b.chamadas("CraftRecipe")) do b.verdadeiro(c.args[1] ~= 900001, "CraftRecipe nunca pede o encantamento") end
  end,
}
