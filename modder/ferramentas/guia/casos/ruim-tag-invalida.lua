-- Exemplo de Dicas.lua valido (caso de teste do checador)
GuiaForeverDicas = {
  HUNTER = {
    personagem = "Hexumlite Bull",
    magias = {
      { nivel = 6, texto = "Arcane Shot e Hunter's Mark", fonte = "Method" },
      { nivel = 12, texto = "Multi-Shot no grupo", fonte = "DoubleZug" },
      { nivel = 18, texto = "Multi-Shot em grupo", fonte = "Naowh", tags = { "grupo", "xyz" }, magia = "Multi-Shot", prio = 1 },
    },
    armas = { { de = 1, ate = 10, texto = "Arco de pratica", fonte = "Gladius (beta)", raca = "NightElf", zona = "Teldrassil", prio = 2 } },
    pets = { { de = 10, ate = 10, texto = "Pet de dano", fonte = "RestedXP", tags = { "escolhapet" }, requer = "Call Pet" } },
    rotacao = { { de = 1, ate = 4, texto = "Tiro duplo e Arcane Shot", fonte = "Kargoz (beta)", tags = { "pvp" } } },
    atributos = { { texto = "Agilidade acima de tudo", fonte = "MetaGoblin (beta)", raca = "Dwarf" } },
    notas = { { texto = "Veja o guia \"base\"\nna primeira linha", fonte = "Method", zona = "Elwynn Forest" } },
    petTreino = {
      { de = 10, ate = 20, habilidade = "Bite", texto = "Treine Bite assim que o pet chegar ao nivel 10.", fonte = "RestedXP" },
      { de = 20, ate = 30, habilidade = "Charge", texto = "Charge fica util em luta de dano.", fonte = "Naowh" },
    },
  },
  SHAMAN = {
    personagem = 'Rurik Thunderfist',
    magias = { { nivel = 10, texto = "Lightning Bolt", fonte = 'LudiDeo (beta)' } },
    armas = { { de = 1, ate = 60, texto = "Totem de arma", fonte = "Method" } },
    pets = {},
    rotacao = { { de = 1, ate = 60, texto = "Choque e raio", fonte = "Gladius (beta)" } },
    atributos = { { texto = "Inteligencia", fonte = "Method" } },
    notas = { { texto = "Sem nota extra", fonte = "leak" } },
  },
}
