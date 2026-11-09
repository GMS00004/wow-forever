-- Caso ruim: um marco do PALADIN sem o campo texto (o checador tem de barrar so isso)
GuiaForeverDicas = {
  HUNTER = {
    personagem = "Hexumlite Bull",
    magias = {
      { nivel = 6, texto = "Arcane Shot e Hunter's Mark", fonte = "Method" },
      { nivel = 12, texto = "Multi-Shot no grupo", fonte = "DoubleZug" },
      { nivel = 18, texto = "Multi-Shot em grupo", fonte = "Naowh", tags = { "grupo", "fimdejogo" }, magia = "Multi-Shot", prio = 1 },
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
  PALADIN = {
    personagem = "Ignatius Stonejaw",
    magias = {
      { nivel = 10, id = 25780, texto = "Righteous Fury: turn it on before a pull.", fonte = "Blizzard", magia = "Righteous Fury" },
      { nivel = 20, id = 26573, texto = "Consecration: only the first 4 enemies take full damage.", fonte = "Perfect Gaming Weather", magia = "Consecration" },
    },
    armas = { { de = 1, ate = 21, texto = "Two-hander until 21.", fonte = "Deadmanfred" } },
    pets = {},
    rotacao = { { de = 10, ate = 60, texto = "Righteous Fury on before every pull.", fonte = "Perfect Gaming Weather", prio = 1 } },
    atributos = { { texto = "For Protection, spell power comes first.", fonte = "Perfect Gaming Weather" } },
    notas = { { texto = "Blessing of Kings is the leveling blessing for Protection.", fonte = "Perfect Gaming Weather" } },
    lembretes = { { nivel = 10, magia = "Righteous Fury", id = 25780, texto = "Righteous Fury is off: turn it on before you pull.", fonte = "Jurdi" } },
    marcos = {
      { nivel = 12, fonte = "Deadmanfred" },
      { nivel = 20, ate = 30, id = 7328, magia = "Redemption", npc = "Duthorian Rall", mapa = 1453, x = 0.5048, y = 0.4749, texto = "Class quest at 20, from Duthorian Rall.", fonte = "Perfect Gaming Weather", tags = { "grupo" }, raca = "Human" },
    },
  },
}
