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
| Cliente em português do Brasil (`ptBR`): sem confirmação oficial achada em 2026-11-08. A página do addon Map Fix Forever lista o `ptBR` entre os clientes do Forever que ele cobre | [busca] | [CurseForge, Map Fix Forever](https://www.curseforge.com/wow/addons/map-fix-forever) |
| Addons do kit do amigo em `ptBR` (2026-11-08): o Leatrix Plus da versão Forever trata o `ptBR` (link do Wowhead `forever/pt`) e tem o bloco `ptBR` traduzido (918 linhas, 53 iguais ao inglês); o Baganator tem 400 de 403 textos em `ptBR`; Pawn, Auctionator e DBM (`localization.br.lua`) têm tradução; o Questie tem `ptBR` nos objetivos do Forever. O RestedXP só traduz os nomes dos guias do Forever (`locale\ptBR.lua`); os passos da rota ficam em inglês (as traduções de passo em `lang\Guides-ptBR` são de guias do TBC da Horda). O Naowh Forever não tem tradução, e a voz `DBM-VPVEM` é em inglês | [local] | pastas instaladas no Avell |
| Segundo o Massively OP (15/09), a Blizzard vai restringir addons que automatizam comunicação ou marcação | [página] | Forever Mastery |
| Macro de teclado ou mouse por software do fabricante (Logitech, Razer, Corsair), lido em 2026-11-26: nenhuma página oficial da Blizzard achada; nos fóruns oficiais, a leitura corrente dos jogadores é "um aperto, uma ação", e uma tecla física que manda vários cliques ou várias teclas é tratada como automação; mapear um botão do mouse para uma única tecla do jogo é visto como seguro. O texto oficial de 2020 proíbe espelhar comandos entre contas (multibox) e não fala de macro de uma conta só. Para o projeto vale a regra mais estrita: uma tecla física = um clique | [busca] | fóruns da Blizzard: [chave que emula tecla](https://us.forums.blizzard.com/en/wow/t/blizzard-banning-all-software-that-emulates-a-key-input/956893), [macro de hardware e LER](https://us.forums.blizzard.com/en/wow/t/i-am-looking-for-an-official-interpretation-of-the-tos-on-the-usage-of-hardware-macros-to-avoid-rsi/1415005), [software Logitech](https://eu.forums.blizzard.com/en/wow/t/is-macro-software-illigal/546222) |
| O app da CurseForge reconhece o Forever (escanear jogos ou apontar a pasta à mão); o WowUp não tem suporte confirmado | [busca] | blog da CurseForge, Mobalytics |
| Guia pago do RestedXP (2026-11-13): não é addon. O RXPGuides v4.11.35 instalado tem a tela de importação (`/rxp import`, ou o botão direito na janela do guia, "Import guide"), recusa código feito para versão de addon mais velha que a dele (`GuideLoader.lua`, `ImportString`) e guarda as rotas importadas no `RXPDB` das SavedVariables. No site: cadastrar o Battle.net ID na conta antes, depois copiar o código na área Downloads; com o jogo online no Battle.net. Erros: "undefined" dentro do código (falta o Battle.net ID no site; gerar de novo), "Invalid Value" (o jogo sem conexão com o Battle.net; reiniciar), "Invalid Import String" (o ID não bate com a conta; suporte no Discord do RestedXP) | [local] e [página] | código do addon no Avell; kami-labs.fr, "Install RestedXP WoW Forever" (10/10/2026) |
| Wailing Caverns para a Aliança (2026-11-13): 5 quests, Deviate Hides (Nalpak) e Deviate Eradication (Ebru), na caverna da entrada; Smart Drinks (Mebok Mizzyrix, com quest anterior) e Trouble at the Docks (Bigglefuzz), em Ratchet; The Glowing Shard (item que cai lá dentro). Leaders of the Fang, Serpentbloom e a cadeia de Hamuul e Nara são só da Horda. O "RXP Forever Dungeon Quests (A)" do RestedXP pago não traz Wailing Caverns | [local] | `ForeverGuide\DungeonData.lua` (gerado do QuestieDB do Forever), campo `fa`; lista do RestedXP no print do dono |
| RestedXP Missed Quests (2026-11-20): addon de terceiro (autor Stefano), 0.4.2, uma pasta `RestedXPMissedQuests` com o TOC em Interface 16001, `OptionalDeps` RXPGuides, Questie e TomTom, e SavedVariables `RXPMissedDB`. Lê a rota carregada no RestedXP (`RXP.currentGuide`) e lista as quests que a rota ainda pede e que não estão no log; avisa no "Abandon quest?" por `hooksecurefunc`. A versão 0.3.x se chamava "RXP Missed Quests" (pasta `RXPMissedQuests`) | [local] | zip baixado pelo dono da [CurseForge](https://www.curseforge.com/wow/addons/restedxp-missed-quests) |
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
| O mesmo post (03/11), Paladin: Righteous Fury no nível 10 (era 16), com +33% em toda ameaça e +90% na sagrada; saíram Salvation, Mass Salvation, Revoke, Blessing of Light, Improved Seal of Fury e One-Handed Weapon Specialization; Judgement of Fury com 3 s (eram 4). A árvore de Prot foi refeita: Divine Intellect na linha 1, Sacred Duty na 2 (sem Stamina, reduz a Forbearance), Templar's Bulwark e Toughness na 3, Anticipation na 4, Holy Shield e Stoicism na 5, Iron Creed com 3 ranks, Shieldsworn (novo) na 7; Conviction e Sanctified Judgement na linha 2 de Ret, Unsealed Wrath como capstone de Ret | [página] | fórum da Blizzard, tópico 2360696 (JSON do tópico, lido pela sessão em 2026-11-08) |
| O mesmo post (03/11), Warlock: nenhuma mudança na árvore de Demonology; o demônio ganha 2 de vida por ponto de Stamina do warlock (eram 7,5); Spellstone só aumenta dano shadow; Drain Soul dá shard sem matar com chance bem menor. Antes, em 08/10: o bônus de dano do Demonic Brand só dá ameaça alta quando é dano shadow | [página] | fórum da Blizzard, tópico 2360696 |
| A árvore de talentos atual de cada classe sai do mesmo JSON da Method (`/dfc/ForeverTalentsData-1.60.1-custom.json`): cada classe tem um `treeID` (Paladin 1100, Warlock 1116), cada nó tem `x`, `y`, `maxRank` e o `spellID`; a linha é `(y - 2130) / 600 + 1` e a árvore vem do `curFlag` do nó. Conferido em 2026-11-08: Shieldsworn na linha 7 de Prot e Demonic Pact na 7 de Demonology, como nos vídeos de 03/11 em diante | [página] | method.gg, lido bruto pela sessão |
| A tabela `Talent` do cliente publicada no wago.tools (build 1.60.1.70862) não é a árvore do Forever: traz o Improved Ghost Wolf na linha 2 e o Stormstrike na 7, e não tem Shieldsworn nem Demonic Pact. Não usar para conferir build | [local] | `https://wago.tools/db2/Talent/csv?build=1.60.1.70862`, lido pela sessão em 2026-11-08 |
| O tooltip da Wowhead do Forever devolve o nome em português com `?locale=8` (ex.: Demonic Brand = "Marca Demoníaca", Soul Link = "Vínculo Anímico"); algumas magias voltam sem tradução (Curse of the Elements, 1490) | [página] | teste com `urllib` em 2026-11-08 |
| O tooltip da Wowhead do Forever responde "Entity not found" para vários ranks acima do 1 e para algumas magias de talento novas (ex.: 20911, 18748); o rank 1 costuma responder | [local] | teste com `curl` em 2026-11-08 |

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

## Pets do caçador (lido em 2026-11-07 e 2026-11-08)

Levantamento para o guia de habilidades de pet do GuiaForever (seção 10 do `ARQUITETURA.md` dele). Os dados gerados ficam em `modder\ferramentas\guia\pets\`.

| Fato | Marca | Fonte |
|---|---|---|
| O sistema continua o do Classic: domar a fera que sabe o rank, lutar até aprender, ensinar ao pet no Beast Training com pontos de treino; lealdade, felicidade, dieta e estábulo (2 guardados e 1 ativo) seguem | [página] | Petopia Forever (training.php), ForeverChanges (hunter-pets, 24/09), Warcraft Tavern |
| Notas de beta da Blizzard: em 24/09, Tame Beast deixou de funcionar em fera acima do seu nível; em 01/10, algumas feras tinham rank alto demais para o nível (corrigido); em 16/10, Dismember, Sonic Blast e Mine! enfraquecidos; em 03/11, o pet não perde mais a passiva inata de velocidade ao destreinar | [página] | us.forums.blizzard.com/t/2360696 (Kaivax) |
| Class Deep Dive de 30/09: família Fox com Trickster's Dance; Owl virou Bird of Prey; toda família aprende Bite ou Claw e Dash ou Dive; uma habilidade única por família; pet ganha atributo do equipamento do caçador e não recebe buff de jogador | [página] | worldofwarcraft.blizzard.com/news/24301515 |
| "Class Tuning Incoming – November 10" (06/11): os pets aguentam menos que o pretendido como tanque, e a Blizzard vai ajustar para perto do Classic Era, sem números ainda | [página] | us.forums.blizzard.com/t/2404092 |
| A velocidade de ataque é de cada fera (passiva inata Faster Attack I a VII ou Slower Attack II e III, base 2.0) e não se ensina | [página] | ForeverChanges, ConquestCapped (24/10) |
| As tabelas do cliente (produto `wowf`, build 1.60.1.70862) dão família, dieta, habilidade, rank, nível do pet e pontos de treino: CreatureFamily, SkillLineAbility (os pontos de treino ficam na coluna sem nome `Field_5_5_4_67090_014_1`), SpellLevels (BaseLevel, ou SpellLevel quando 0), Spell e SpellName; Bite dá níveis 1/8/16/24/32/40/48/56 e pontos 1/4/7/10/13/17/21/25. O cliente tem 19 famílias, com Core Hound (que a Petopia diz não ter sido vista) | [local] | wago.tools, CSV por `https://wago.tools/db2/<Tabela>/csv?build=1.60.1.70862` |
| Quem ensina cada rank não está no cliente (a tabela CreatureSpellData não existe no `wowf`); só em dados coletados por jogadores: o repositório Jazzman1976/Forever-Hunter-Pets (MIT, sha `ff5eefb`, de 07/11) e a Petopia Forever (sem licença aberta). Nos 76 ranks que as duas cobrem, nível do pet e custo batem | [local] | `modder\ferramentas\guia\pets\professores.json` |
| Addons prontos com ranks e professores: Hunter's Field Guide (Alezyzz, 0.7.0 de 07/11, Forever e Era, 639 feras), Hunter Pet Atlas (1.2.0 de 06/10, com pontos de treino e pinos no mapa), vanThos Pet Compendium (1.0.4 de 06/11) e Forever Bestiary (Pet Hunter) (0.7.0 de 20/10, sem atualização depois do lançamento) | [página] | páginas de cada um na CurseForge |

## Casas de leilão por ruleset (lido em 2026-11-26)

| Fato | Marca | Fonte |
|---|---|---|
| Sem reinos: uma casa de leilão por região, ruleset e facção, mais a Blackwater (neutra) de cada ruleset. Rulesets na API: 1 PvP, 2 Normal, 3 Roleplay, 15 Roleplay PvP; o Hardcore vem depois do lançamento | [página] | conquestcapped (wow-forever-auction-house, 16/11); repositório `jofri99/forever-ah-flip`, `docs/forever-api.md` (medido em 14/11); news.blizzard.com/article/24302070 |
| Números das casas, os mesmos nos EUA e na EU: Aliança 110, 111, 112, 119, 123; Horda 113, 114, 115, 120, 124; Blackwater 116, 117, 118, 121, 125; 112, 115 e 118 vazias, 122 não existe. O arquivo público `quest-murder-prices` traz `ruleset=1` em todas, então o campo não identifica o ruleset | [local] | `index.txt` e cabeçalhos de `us-*.txt` do release `current`, 26/11 |
| Horda: 113 é PvP e 114 é Normal, medido na EU contra os dados do TSM (100% dos preços iguais); outro coletor publica "EU PvP Horde (house 113)". O resto segue a posição no bloco de três (PvP, Normal, vazia): Aliança 110 PvP e 111 Normal, Blackwater 116 PvP e 117 Normal. 119 a 121 e 123 a 125 são os dois Roleplay, sem saber qual é qual. Nos EUA a ordem é inferida pela mesma numeração, não medida; bate com a casa do dono (us-111, conferida contra a tela dele em 16/11) ser a Aliança Normal | [página] | `jofri99/forever-ah-flip` `docs/forever-api.md`; `prismicious/forever-auction-feed` README |

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
