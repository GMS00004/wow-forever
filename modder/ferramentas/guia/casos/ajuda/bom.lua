-- Exemplo de Ajuda.lua valido (caso de teste do checador)
GuiaForeverAjuda = {
  HUNTER = {
    { id = "pet-feed", aba = "pet", pergunta = "Como alimentar o pet?",
      linhas = {
        { texto = "Use Feed Pet com comida da lista do pet.", fonte = "Method" },
        { texto = "Carne serve para a maioria das familias.", fonte = "RestedXP" },
      } },
    { id = "talentos-hawk", aba = "talentos", pergunta = "Quando pegar Summon Hawk?",
      linhas = { { texto = "Na faixa de nivel 25, como talento novo.", fonte = "Naowh" } } },
  },
  SHAMAN = {
    { id = "totem-base", aba = "combate", pergunta = "Qual totem colocar primeiro?",
      linhas = { { texto = "Totem de agua no inicio do combate.", fonte = "leak" } } },
  },
}
