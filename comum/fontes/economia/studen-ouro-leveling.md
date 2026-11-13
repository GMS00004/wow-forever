tema: economia
fonte: Studen Albatroz (YouTube), "I Made 74 GOLD in 2 Days Without Crafting or Fishing! WoW Forever"
url: https://www.youtube.com/watch?v=UI0W2Qswhfo
data: 2026-11-07
seguir: decisão do dono em 2026-11-07 ("Minhas decisões"): valem as dicas de recompensa de missão, de treino e de itens verdes (2 a 4), que já estão nos addons instalados; a dica 1 (Skinning em todos e vender todo o couro) não vale, e o couro do Hexumlite segue o roteiro do Leatherworking. A dica 5 depende do guia pago e fica de fora.

# Studen Albatroz: ouro durante o leveling, sem profissão de produção

Vídeo de 8:30, publicado em 2026-11-07, gravado no segundo dia do Forever com um personagem no nível 37 e 74 de ouro. A transcrição foi lida inteira pela sessão (legenda automática em inglês, baixada pelo yt-dlp) e não fica no repositório. Marca: `[página]` (transcrição e descrição). Quase um terço do vídeo é propaganda do guia de ouro pago dele (Gumroad, com cupom) e do Discord VIP; os pontos de farm concretos estão lá e em outros vídeos dele, não neste.

## As dicas

| Tempo | Dica | Detalhe dito no vídeo |
|---|---|---|
| 02:03 | Skinning em todo personagem que sobe de nível, esfolar tudo (inclusive os corpos que outros deixaram no começo) e vender o couro direto no vendedor | Segundo ele, no nível dele o couro está saindo no leilão por quase o preço do vendedor e, com a taxa do leilão, às vezes dá prejuízo; não guardar para uso próprio nem para vender mais caro depois |
| 03:38 | Não treinar magia ou grau de magia que não vai usar no leveling | Exemplos só de mago (Mage Armor, graus altos de Amplify e Dampen Magic, Frost Ward): o ouro economizado agora pesa mais do que no 60 |
| 04:50 | Na recompensa de missão com escolha, pegar a que vende por mais, a não ser que alguma seja melhoria | A diferença pode ser grande (ele cita 20 contra 70 de prata) |
| 05:39 | Vender no leilão os itens verdes com atributos bons (of the Tiger, of the Monkey), não no vendedor | Exemplo: 11 de prata no vendedor e 35 no leilão; a taxa de postagem é baixa e os reinos são grandes ("Giga Realms"), então vende |
| 06:51 | Onde a missão tem renascimento rápido de bichos, ficar uns 15 minutos depois de terminar | XP, ouro, pano e itens BoE juntos; os lugares estão no guia pago e nos vídeos dele do 6 ao 25 |

## O que os addons instalados já fazem (lido no código em 2026-11-07, `[local]`; nada disto foi visto no jogo)

| Dica | Addon | Como aparece |
|---|---|---|
| Recompensa que vende por mais | RestedXP Guides v4.11.33 | Na janela de entrega com escolha, um ícone de vendedor no canto de baixo do item que vende por mais e o logo do RestedXP no canto de cima do que ele calcula como melhoria (`evaluateQuestChoices` e `handleQuestComplete` em `RXPGuides.lua`). Opções "Quest Sellable Recommendation" e "Quest Reward Recommendation", ligadas por padrão (`SettingsPanel.lua`, linhas 228 e 229) e não alteradas nas SavedVariables do dono. Some quando a automação de missões do RestedXP está desligada, com o Ctrl apertado ou com o guia escondido. A escolha automática ("Quest Reward Automation") vem desligada. O cálculo de melhoria é do próprio RestedXP, não das fontes do dono, e pode discordar da seta do Pawn |
| Não treinar o que não usa | Naowh Forever, módulo Training | No `/nftraining`, botão direito numa magia a pula ("Skip" ou "Skip All Ranks"); o planejador mostra quanto se economiza ("Skipping these saves") e há um painel ao lado do treinador de classe com as magias do nível já marcadas, o total e "Learn Selected" |
| Verde no leilão ou no vendedor | Auctionator 341 | O tooltip do item traz o preço do vendedor e o do leilão (`vendor_tooltips` e `auction_tooltips`, ligados por padrão em `Source\Config\Main.lua`); o do leilão só aparece para item que o Auctionator já viu numa busca ou varredura |

## Conflitos com as decisões do dono

1. Skinning em todo personagem contra a regra do dono de 2026-11-04 de não repetir profissão entre os personagens da conta (`..\..\jogador.md`): o Rurik, o Fingolfin e o paladino têm outras profissões.
2. Vender todo o couro contra o Leatherworking do Hexumlite, que consome o couro pelo roteiro de Leatherworking (desde 2026-11-13 o do ReptilioPlays, `..\profissoes\reptilio-leatherworking.md`, que substituiu o da Gfinity; metas de 75, 100 e 125 por área em `..\profissoes\roteiros.md`). O autor não tem profissão de produção, por isso a dica não considera esse caso.

Decisão do dono em 2026-11-07, para os dois conflitos: valem as decisões dele (profissões sem repetir e o couro do Hexumlite para o Leatherworking).
