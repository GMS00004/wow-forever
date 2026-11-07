-- Exemplo de Ajuda.lua com id repetido (caso de teste do checador)
GuiaForeverAjuda = {
  HUNTER = {
    { id = "pet-feed", aba = "pet", pergunta = "Como alimentar o pet?",
      linhas = { { texto = "Use Feed Pet com comida da lista do pet.", fonte = "Method" } } },
    { id = "pet-feed", aba = "pet", pergunta = "Outra pergunta sobre comida?",
      linhas = { { texto = "Carne serve para a maioria das familias.", fonte = "Method" } } },
  },
  SHAMAN = {
    { id = "totem-base", aba = "combate", pergunta = "Qual totem colocar primeiro?",
      linhas = { { texto = "Totem de agua no inicio do combate.", fonte = "Method" } } },
  },
}
