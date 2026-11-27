# Créditos

Este repositório se apoia no trabalho de muita gente. As notas em `comum/fontes/` são resumos nas palavras de quem segue o guia, com o link do original; o conteúdo, as builds e as rotas são dos criadores. Se um guia ajudou você, apoie quem fez.

## Guias de gameplay (`comum/fontes/`)

| Criador | O quê | Original |
|---|---|---|
| Crix Forever | Warlock Demonology | [vídeo](https://www.youtube.com/watch?v=FRJVWrfOg8E) |
| Deadmanfred | Paladin Protection | [vídeo](https://www.youtube.com/watch?v=w8FqukiYxQM) |
| DoubleZug | Shaman, leveling | [vídeo](https://www.youtube.com/watch?v=i28JSChIvWE) |
| DwarfLord | Paladin Protection, tanque | [vídeo](https://www.youtube.com/watch?v=IcozH7KOZ50) |
| Gladius Gaming | Hunter, talentos e armas | [vídeo](https://www.youtube.com/watch?v=J1kDM4QI3Ks) |
| Jurdi | Paladin Protection e o retrabalho de talentos | [guia](https://www.youtube.com/watch?v=DTx_OO8qPFo), [retrabalho](https://www.youtube.com/watch?v=lQlHA-J4geA) |
| Kargoz | Hunter Beast Mastery e Warlock Demonology, 1 a 60 | [hunter](https://www.youtube.com/watch?v=rn6Cjl8zQbc), [warlock](https://www.youtube.com/watch?v=VI3h379QvSY) |
| leak (Leaku) | macros de Hunter | [vídeo](https://www.youtube.com/watch?v=_W3hOy-hxK0) |
| LudiDeo | pets de Hunter e a tier list de pets | [masterclass](https://www.youtube.com/watch?v=pCgIGcumOss), [tier list](https://www.youtube.com/watch?v=ZIiXgHdTkBI) |
| MetaGoblin | Hunter, leveling | [vídeo](https://www.youtube.com/watch?v=F2dBd9PP8q0) |
| Mewsquared | Warlock Demonology, leveling | [vídeo](https://www.youtube.com/watch?v=26sx8WGoUMk) |
| Perfect Gaming Weather | Paladin, leveling | [vídeo](https://www.youtube.com/watch?v=0EzsW9Q5cUw) |
| Saltii | pets de Hunter | [vídeo](https://www.youtube.com/watch?v=O-TbXGGHoAs) |
| Studen Albatroz | ouro no leveling | [vídeo](https://www.youtube.com/watch?v=UI0W2Qswhfo) |
| ReptilioPlays | Leatherworking 1 a 300 | [vídeo](https://www.youtube.com/watch?v=ECKmoBDhfM0) |
| RestedXP | rotas de leveling (addon RXPGuides) | [GitHub](https://github.com/RestedXP/RXPGuides) |
| Gfinity e outros | roteiros de profissão (ver `comum/fontes/profissoes/roteiros.md`) | links no arquivo |

## Dados e código de terceiros que as ferramentas usam

| Projeto | Para quê |
|---|---|
| [Ketho/BlizzardInterfaceResources](https://github.com/Ketho/BlizzardInterfaceResources) | as listas de funções, eventos, templates e CVars do cliente do Forever, que o `checar-combate.mjs` usa |
| [Ketho/wow-ui-source-forever](https://github.com/Ketho/wow-ui-source-forever) | o código da interface e a documentação gerada da Blizzard (as marcas de valor secreto) |
| [wago.tools](https://wago.tools) | as tabelas do cliente (itens, receitas, perícias) das ferramentas de preço |
| [RuslanMunasipov/quest-murder-prices](https://github.com/RuslanMunasipov/quest-murder-prices) | a foto pública de preços do leilão, por casa, a cada hora |
| Naowh Forever, de [naowh-gaming](https://github.com/naowh-gaming/NaowhForever) | a tabela de receitas, treinadores e custo de treino das profissões |
| [Questie](https://github.com/Questie/Questie) (QuestieDB) | a lista de vendedores de padrões e reagentes, e os NPCs dos treinadores |
| Petopia e Wowhead | habilidades e famílias de pets e dados de NPCs, para os geradores do guia de pets |
| [luaparse](https://github.com/fstirlitz/luaparse) e [fengari](https://github.com/fengari-lua/fengari) | ler e rodar Lua 5.1 no Node, nos checadores e nas bancadas |

## Addons de terceiros

Os addons do pacote base (ElvUI, Questie, Deadly Boss Mods, BugSack e BugGrabber, Auctionator, TomTom, Leatrix Plus, RestedXP, GatherMate2, Baganator e Syndicator, Pawn, Forever Guide, Forever Quests, Naowh Forever e outros) não estão neste repositório: o agente baixa cada um da fonte oficial (GitHub, Tukui, Wago ou CurseForge) e guarda só o manifesto na pasta do jogador. A lista, com as fontes, está em [comum/referencia/pacote-base.md](comum/referencia/pacote-base.md).

## Licença

O repositório é público e não tem licença aberta: o código é do Guilherme. Ler, aprender e mandar PR pode; reaproveitar o código em outro projeto pede a autorização dele. Contribuição por PR entra nas mesmas condições.
