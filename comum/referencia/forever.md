# WoW Forever: fatos conferidos

Cada fato leva a marca de como foi lido e a data. `[página]` é página aberta (pelo WebFetch, que resume a página); `[busca]` é só o resumo de uma busca; `[local]` é lido na máquina. Fato de terceiro é pista até ser conferido no cliente ou no TOC.

## Lançamento e conteúdo (lido em 2026-11-03)

| Fato | Marca | Fonte |
|---|---|---|
| Lançamento mundial em 2026-11-04 às 23:00 UTC (20h de Brasília) | [página] | Warcraft Wiki, Patch 1.60.1 |
| Nível máximo 60, "indefinidamente" | [página] | Warcraft Wiki |
| Raça nova Skyborne. Corrigido em 2026-11-04: o anúncio da Blizzard dá ao Skyborne da Aliança (High Order) Druid, Hunter, Mage, Rogue e Warrior, e ao da Horda (Windshaper) Druid, Hunter, Rogue, Shaman e Warrior; a facção se escolhe na criação; zona inicial Zephras Isle, níveis 1 a 12; o druida tem formas próprias da raça. A linha antiga dizia "Aliança: mago; Horda: xamã", o que estava incompleto | [página] | Blizzard News, "WoW: Forever Meet the New Skyborne" (sem data na página); antes, Warcraft Wiki |
| Especialização dupla no nível 40, no treinador, por 10 de ouro | [página] | Warcraft Wiki |
| Raides abrem em 2026-12-09; Hardcore no inverno 2026/2027 | [página] | Warcraft Wiki (roadmap) |
| Coleções da conta inteira; alternância de modelos SD/HD | [página] | Warcraft Wiki |
| Acesso com assinatura ativa do WoW; Windows e macOS | [busca] | Gfinity, TechSpot |
| Requisitos: 128 GB livres em SSD (mínimo e recomendado); o tamanho do download não foi divulgado | [busca] | fórum da Blizzard (tópico 2351543), esports.gg |

## Addons (lido em 2026-11-03)

| Fato | Marca | Fonte |
|---|---|---|
| Versão de jogo 1.60.1 e Interface 16001; o Classic Era é 11509, e addon só do Classic Era não carrega no Forever | [página] | Endgame Tools (atualizado em 03/11), Forever Mastery (31/10) |
| A interface do Forever é a moderna, do Midnight: segundo um representante da Blizzard citado pela fonte, compartilha a arquitetura de UI do Mainline, incluindo "the vast majority of APIs available in 12.1.5" | [página] | Endgame Tools |
| Valem as restrições de combate do Midnight ("secret values"): o addon exibe dado de combate, mas não decide com ele | [página] | Endgame Tools; Forever Mastery (cita Icy Veins de 17/09) |
| Pasta dos addons: `World of Warcraft\_forever_\Interface\AddOns` (criar `Interface` e `AddOns` se faltarem); o beta usava `_classic_beta_`, que o jogo final não lê | [página] | Endgame Tools |
| Um guia escreve `World of Warcraft/forever/`, sem os sublinhados: conflito, a conferir na instalação | [busca] | Mobalytics |
| Arquivo só do Forever: sufixo `_Forever.toc` ou `_Camelot.toc`, ou `[AllowLoadGameType camelot]` dentro de um `.toc` comum; o número da Interface pode mudar no lançamento | [página] | Forever Mastery |
| Addon novo pede reinício completo do jogo; `/reload` não basta para arquivo novo | [página] | Forever Mastery |
| Para conferir a Interface no jogo: `/dump select(4, GetBuildInfo())` | [página] | Endgame Tools |
| Política de addons da Blizzard: grátis, sem versão paga, código legível; não há política própria do Forever publicada | [página] | Forever Mastery |
| Segundo o Massively OP (15/09), a Blizzard vai restringir addons que automatizam comunicação ou marcação | [página] | Forever Mastery |
| O app da CurseForge reconhece o Forever (escanear jogos ou apontar a pasta à mão); o WowUp não tem suporte confirmado | [busca] | blog da CurseForge, Mobalytics |
| Em 31/10, 71 de 82 addons populares tinham versão Forever; Skada e Recount aparecem como "Built into the game" | [página] | Forever Mastery |
| Com versão Forever (03/11): Questie (desde 12.0.1), Details!, DBM (desde 12.1.10), Leatrix Plus (arquivos `-forever`), Auctionator, TomTom, Bartender4; ElvUI 16.00 (13/10) pela Tukui | [página] | Endgame Tools, Forever Mastery |
| Sem versão Forever (31/10 e 03/11): WeakAuras, OmniCC, TradeSkillMaster, AdiBags, Shadowed Unit Frames, Spy, Nova World Buffs, WoW-Pro Guides, Zygor (app próprio, pago) | [página] | Forever Mastery, Endgame Tools |

## Instalação real (lido no Avell em 2026-11-03) `[local]`

| Fato | Valor |
|---|---|
| Pasta do jogo | `C:\Program Files (x86)\World of Warcraft`, com o grupo Usuários em controle total (grava sem administrador) |
| Pasta do Forever | `_forever_` (o executável é `_forever_\Wow.exe`) |
| Código do produto (`.flavor.info` e `.build.info`) | `wowf` |
| Versão do cliente antes do lançamento | 1.60.1.70755, Interface 16001 |
| `Battle.net.config` | `DefaultInstallPath` vem como `C:\/Program Files (x86)` (barra escapada) |

## Pacotes de addon (lido em 2026-11-03, noite) `[local]`

- O DBM (12.1.19) e o BigWigs (v427.8) trazem no mesmo zip módulos do Midnight (Interface 120105 e 120107). Instale com `-SoCompativeis`.
- Os módulos de chefe para o Forever estão em pacotes separados. O `DBM-Vanilla` (r835) e o `DBM-Dungeons` (270) têm build do Forever, e o segundo traz o `DBM-Party-Forever`. O `BigWigs_Classic` (v12.1.2) e o `LittleWigs` (v12.1.22) não têm.
- O `release.json` do Questie não traz `version`; a versão vem do `tag_name` (`bundle/v12.5.0+v1.0.10`).
- O TOC do BugSack declara o `!BugGrabber` como `OptionalDeps`.

## Classes e talentos (lido em 2026-11-04)

| Fato | Marca | Fonte |
|---|---|---|
| Dwarf Shaman é uma das seis combinações novas de raça e classe, e o Dwarf é a única raça da Aliança com xamã | [busca] | Icy Veins, Gamer-Guides e outros sites de guia |
| O Forever mantém o formato do Classic (3 árvores, 51 pontos, 5 pontos por linha), mas reescreveu boa parte dos talentos: build do Classic Era não serve | [busca] | wowforevertalents.com, classicwowforever.com, metabot.gg |
| Post da Blizzard de 2026-11-03 (Kaivax, "Beta Development Notes"), Shaman: Improved Ghost Wolf da linha 2 para a 4; Stormstrike com 150% de dano normalizado e recarga de 6 s; Flurry 6/12/18/24/30%; Mental Dexterity dá AP igual a 50/100/150% do Intellect; Maelstrom Weapon com o dobro de chance; Lava Burst removido e trocado por Call of Thunder; Elemental Mastery virou Lightning Mastery; Totemic Projection virou Totemic Call, com recarga de 30 s | [página] | fórum da Blizzard, tópico 2360696 |
| O mesmo post, Hunter: Pathfinding da linha 2 para a 3; Hunter's Mark não acumula ranks diferentes; Aimed Shot, Arcane Shot e Serpent Sting mais fortes; Aspect of the Hawk com valores 20/35/50/70/90/110; todas as armadilhas com recarga compartilhada de 30 s | [página] | fórum da Blizzard, tópico 2360696 |
| A build de leveling da Method fica no atributo `data-talent` da página: a parte depois do `;` tem uma letra (alfabeto base64) por ponto, do nível 10 ao 60, e cada letra indexa a lista de talentos da classe ordenada pelo id do nó, em `/dfc/ForeverTalentsData-1.60.1-custom.json`. Quando a Method remove um nó da tabela, as builds salvas antes ficam deslocadas | [página] | method.gg, lido bruto pela sessão |
| O tooltip da Wowhead do Forever devolve o nome atual de uma magia: `https://nether.wowhead.com/forever/tooltip/spell/<id>` | [página] | Wowhead |

## Bestiário, loot e modelo de criatura (lido em 2026-11-07)

Levantamento para o pedido do dono de um bestiário dentro do jogo (buscar qualquer inimigo pelo nome e ver onde vive, o loot e o modelo animado) e das loot tables de dungeon. As linhas `[página]` são páginas da CurseForge ou do GitHub lidas pelo WebFetch ou pelo `gh`; a compatibilidade real se confere no TOC depois de baixar.

| Fato | Marca | Fonte |
|---|---|---|
| Nenhum addon do Forever junta busca de qualquer mob por nome, mapa de spawns, tabela de loot com chance e modelo 3D animado | [busca] e [página] | levantamento desta tabela |
| Forever Guide (LinFeiyizu, 1.38.5 de 07/11, 155 mil downloads, só CurseForge, sem GitHub nem Wago): 22 mil itens com todas as fontes e chance de drop, 404 raros (28 novos) com loot, spawns e alerta, cartões de chefe com modelo 3D, habilidades e loot das 35 dungeons (9 novas), com trash; dados do cliente 1.60.1, QuestieDB, ForeverChanges, Wowhead Forever, WoWSims e cmangos, com o dado Classic marcado. Traz também LFG, troca de layer, varredura de leilão e profissões. A página não descreve navegador de mob comum por nome | [página] | curseforge.com/wow/addons/forever-guide |
| Naowh Forever, módulo Dungeon Journal (1.2.16, Interface 16001, depende só do núcleo `NaowhForever`, já instalado): chefes de cada dungeon em ordem, com raros, baús e um cartão de trash, o loot com chance, quests da dungeon, mapa com os chefes, reputação e PvP, histórico de abates e saques; abre com `/nfjournal`; começa desligado. O loot vem da Wowhead Forever e da wowsrc.com, montado fora do jogo. O README não fala em modelo 3D | [página] | `NaowhForever_DungeonJournal` (TOC e README), GitHub naowh-gaming/NaowhForever, branch `main` |
| O mesmo README: o id do NPC sai do GUID, e o GUID de inimigo fica secreto em combate e em alguns lugares (conferir com `issecretvalue` antes de ler); dentro de dungeon, `UNIT_DIED` e `PARTY_KILL` escondem qual criatura morreu (visto no 1.60.1, Deadmines, 30/09); abate de chefe se conta pelo `ENCOUNTER_END` | [página] | idem |
| Forever Bestiary (Saul31322, 0.7.0 de 20/10, ainda do beta): só feras domáveis (606, 49 novas), modelo 3D girável, spawns, habilidades por rank; usa `/bestiary` e `/bestiario` | [página] | curseforge.com/wow/addons/forever-bestiary-pet-hunter |
| Forever Bestiary (Arxie, 1.2.1 de 03/11), Forever Bestiary (Ragunduh, 1.2 de 13/10), Mob Ledger (1.4.6 de 04/11), Explore Forever (1.0.1 de 05/11) e Forever Drops (05/11): só registram o que o jogador (ou a comunidade do addon) viu e saqueou; nenhum traz banco de loot completo nem modelo animado | [página] | páginas de cada um na CurseForge |
| RareNet (0.9.4 de 07/11, GPL-3.0, github.com/zyra-v21/wow-rarenet): só raros, com modelo 3D, spawns e loot (Forever e Classic) | [página] | curseforge.com/wow/addons/rarenet |
| WhatItDrops (1.4.0 de 22/10, GPL-3.0, github.com/SokratisV/WhatItDrops): loot do alvo e busca de criatura por nome, com dados da era TBC (o autor avisa que erra no Forever) | [página] | curseforge.com/wow/addons/whatitdrops |
| Lootwise (1.0.13 de 07/11, github.com/barbecue-citrus-varmint/lootwise): loot de chefe de dungeon com modelo 3D; sem mob comum | [página] | curseforge.com/wow/addons/lootwise |
| Loot fica no servidor: o cliente não diz quem dropa o quê, então todo addon de loot embarca dados ou aprende saqueando | [página] | README do `NaowhForever_DungeonJournal` |
| A API de modelo existe na lista oficial do Forever: `SetCreature`, `SetDisplayInfo`, `SetAnimation`, `HasAnimation`, `SetModelByCreatureDisplayID`. O `EJ_*` e o `C_EncounterJournal` também estão na lista, sem confirmação de que o cliente tenha dados de diário | [local] | `modder\ferramentas\guia\api-forever\WidgetAPI.lua` e `GlobalAPI.lua` (Ketho/BlizzardInterfaceResources, branch `forever`) |
| O QuestieDB do Forever (1.0.12) traz, de cada NPC, nome, níveis, rank, spawns por zona, rotas, quests e facção; o loot dele cobre só itens de quest (`classicItemDrops.lua`, chances da Wowhead) | [local] | `QuestieDB\src\meta\npcMeta.lua` e `support\Forever\DropTables` |
| A página de NPC da Wowhead Forever responde 403 ao cliente automático; o tooltip público (`nether.wowhead.com/forever/tooltip/npc/<id>`) responde com nome, nível, tipo, família e coordenadas | [local] | teste com `curl` em 2026-11-07 (npc 2032) |

## Fontes

- Warcraft Wiki, Patch 1.60.1: https://warcraft.wiki.gg/wiki/Patch_1.60.1
- Endgame Tools, addons do Forever: https://endgametools.com/en/wow-forever/news/wow-forever-addons
- Forever Mastery, compatibilidade: https://forevermastery.com/en/addons/forever-compatibility
- Gfinity, roadmap: https://www.gfinityesports.com/article/world-of-warcraft-forever-roadmap-guide
- TechSpot: https://www.techspot.com/news/113832-world-warcraft-forever-launches-november-4-new-race.html
- Blog da CurseForge: https://blog.curseforge.com/wow-forever-migrate-addons-beta-to-live/
- Mobalytics, instalar addons: https://mobalytics.gg/wow-forever/profile/broog/guides/how-to-install-addons-wow-forever
- Fórum da Blizzard, instalação de 128 GB: https://us.forums.blizzard.com/en/wow/t/2351543
- esports.gg, requisitos: https://esports.gg/guides/world-of-warcraft/can-your-pc-or-mac-run-wow-forever-here-are-the-system-requirements/
