# Pacote base do WoW Forever (candidatos verificados)

Levantamento de 2026-11-03 (subagente de pesquisa T1, conferido pela sessão principal nas fontes brutas onde a coluna Evidência diz "conferido"). É a lista que o `wow-modder` apresenta no bootstrap como decisão; o que foi instalado está na seção "Decisão do dono". Versões mudam toda semana: o instalador lê a versão na hora.

## Como cada fonte se baixa

- **Automático (GitHub):** a release traz um `release.json` do empacotador com a lista de flavors por arquivo. O instalador escolhe o arquivo que tem `{"flavor":"forever","interface":16001}`. Conferido no BugSack (v12.1.9) e no DBM (12.1.19) em 2026-11-03.
- **Automático (Tukui):** `https://api.tukui.org/v1/addon/<slug>` devolve `version`, `url`, `last_update` e `patch`. O campo `patch` do ElvUI lista `1.60.1`, e a `url` leva um token que muda, então ela é lida na hora de baixar. Conferido em 2026-11-03.
- **Manual (só CurseForge):** o dono baixa o arquivo do flavor Forever na página, e o agente instala do zip (`zip:`). Esses addons não se atualizam sozinhos: a abertura da sessão lembra de conferir a página.

## Decisão do dono (2026-11-03, noite)

- **Instalado pelo agente:** BugSack, ElvUI, Questie e o DBM completo: o núcleo com `-SoCompativeis`, o `DBM-Vanilla` (raides Classic) e o `DBM-Dungeons` (dungeons, com `DBM-Party-Forever`). A auditoria fechou com 14 pastas e nenhuma diferença.
- **Baixados da CurseForge pelo dono e instalados pelo agente (2026-11-04, `zip:`):** !BugGrabber v12.1.1, Auctionator 341, Forever Quests 1.5.2, TomTom v4.4.0 e Leatrix Plus 1.60.25. Cada zip trouxe uma pasta só, todas com 16001 no TOC; a auditoria fechou com 19 pastas e nenhuma diferença.
- **Rota de leveling (2026-11-04):** RestedXP Guides, pelo GitHub `RestedXP/RXPGuides`, com as rotas grátis do Forever até o 20; os guias de talento dele ficam desligados (são do Classic Era).
- **Fora, por escolha:** Details! (o jogo tem medidor próprio) e Capping.
- **Fora, por não ter versão Forever:** o BigWigs, cujos módulos de conteúdo ainda não têm build do Forever.

## Candidatos

| Papel | Addon | Fonte | Evidência de Forever | Marca | Observação |
|---|---|---|---|---|---|
| Diagnóstico | BugSack | GitHub `funkydude/BugSack` | conferido: TOC com 16001; `release.json` com forever 16001 | [base] | um zip para todos os flavors |
| Diagnóstico | !BugGrabber | só CurseForge (https://www.curseforge.com/wow/addons/bug-grabber) | conferido `[local]` 2026-11-04: `!BugGrabber.toc` com 16001 (v12.1.1) | [base] | coletor do BugSack: o TOC do BugSack lista `!BugGrabber` em `## OptionalDeps` (lido `[local]` em 2026-11-04) |
| Base de UI | ElvUI | Tukui `elvui` (o GitHub `tukui-org/ElvUI` não publica release) | conferido: `patch` inclui 1.60.1; TOC com 16001 e `[AllowLoadGameType camelot]` no título | [base] | escolha do dono; dispensa Bartender4 e addon de bolsa |
| Quests | Questie | GitHub `Questie/Questie` | conferido: `Questie_Camelot.toc` com Interface 16001 (v12.4.0) | [base] | a tag tem `+` no nome (`bundle/v12.4.0+v1.0.10`); na URL o `+` vira `%2B` |
| Quests | Forever Quests | só CurseForge (https://www.curseforge.com/wow/addons/forever-quests) | conferido `[local]` 2026-11-04: `ForeverQuests.toc` só com 16001 (1.5.2) | [opcional] | marca as quests novas do Forever nas dicas do Questie; licença "All Rights Reserved" |
| Navegação | TomTom | só CurseForge (o GitHub `jnwhiteh/TomTom` dá 404) | conferido `[local]` 2026-11-04: `TomTom.toc` com 16001 (v4.4.0) | [opcional] | setas e waypoints; Alt + botão direito no mapa-múndi cria a seta (padrão `worldmap.create_modifier = "A"` no `core\settings.lua`, módulo `map_click.lua`), confirmado pelo dono no jogo em 2026-11-08 |
| Chefes | DBM | GitHub `DeadlyBossMods/DeadlyBossMods` | conferido: `release.json` com forever 16001; TOC do DBM-Core com 16001 | [escolha um] | o DBM-Core exige `DBM-StatusBarTimers` (confirmar que vem no zip) |
| Chefes | BigWigs | GitHub `BigWigsMods/BigWigs` | release.json com forever 16001, segundo a T1 | [escolha um] | alternativa ao DBM; não instalar os dois |
| Dano | Details! | só CurseForge (o GitHub não tem release desde 2021) | `Details_Camelot.toc` com 16001, segundo a T1 | [base] | o jogo também tem medidor próprio (Skada e Recount aparecem como embutidos) |
| Economia | Auctionator | só CurseForge e Wago (o GitHub oficial não foi achado) | conferido `[local]` 2026-11-04: `Auctionator.toc` com 16001 (341) | [base] | o TSM ainda não tem versão Forever |
| PvP | Capping | GitHub `BigWigsMods/Capping` | TOC e `release.json` com 16001, segundo a T1 | [opcional] | risco: os módulos não têm a marca camelot; testar no cliente antes de confiar |
| PvP | Peralex BG | só CurseForge | página lista o flavor Forever | [opcional] | alternativa ao Capping |
| Qualidade de vida | Leatrix Plus | só CurseForge | conferido `[local]` 2026-11-04: o arquivo `-forever` (1.60.25) traz `Leatrix_Plus.toc` só com 16001 | [opcional] | |
| Treino e profissões | Naowh Forever (núcleo, Training e Professions) | GitHub `naowh-gaming/NaowhForever` (também na CurseForge, `naowhforever`) | conferido `[página]` e `[local]` 2026-11-06: 1.2.11 de 06/11, `release.json` com forever 16001, os 13 TOCs com 16001; licença "todos os direitos reservados" (não copiar código) | [opcional] | 13 módulos num zip, um por pasta, cada um dependente só do núcleo. Instalados com `-SoPastas` só o núcleo, o Training (o Training Planner: magias por nível, custo e rota até o 60, aba Builds com as builds do Naowh) e o Professions (janela de receitas com as que faltam, cor de cada receita, lista de compras, ícone e aviso de nó de erva e minério). De fora por repetirem papel: QoL (Leatrix), Combat (Swing Timer nativo), Utilities (barras e macros, choca com o UIForever), BiS (Pawn), DamageMeter, DungeonJournal (150 MB), Discovery |

Fora do Forever (sem evidência): BattleGroundEnemies (TOC só 110200), GladiusEx (fork sem release, TOC só 11.x).

## Limites deste levantamento

- Onde a evidência é "segundo a T1", a linha do TOC foi lida por um resumo de modelo (WebFetch) e não pela sessão; o instalador confere o TOC de verdade antes de instalar.
- Dos 13 candidatos, 7 são só da CurseForge. Cada atualização deles depende de um clique do dono.
