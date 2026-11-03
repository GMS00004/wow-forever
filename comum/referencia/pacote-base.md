# Pacote base do WoW Forever (candidatos verificados)

Levantamento de 2026-11-03 (subagente de pesquisa T1, conferido pela sessão principal nas fontes brutas onde a coluna Evidência diz "conferido"). É a lista que o `wow-modder` apresenta no bootstrap como decisão; nada aqui está instalado. Versões mudam toda semana: o instalador lê a versão na hora.

## Como cada fonte se baixa

- **Automático (GitHub):** a release traz um `release.json` do empacotador com a lista de flavors por arquivo. O instalador escolhe o arquivo que tem `{"flavor":"forever","interface":16001}`. Conferido no BugSack (v12.1.9) e no DBM (12.1.19) em 2026-11-03.
- **Automático (Tukui):** `https://api.tukui.org/v1/addon/<slug>` devolve `version`, `url`, `last_update` e `patch`. O campo `patch` do ElvUI lista `1.60.1`, e a `url` leva um token que muda, então ela é lida na hora de baixar. Conferido em 2026-11-03.
- **Manual (só CurseForge):** o dono baixa o arquivo do flavor Forever na página, e o agente instala do zip (`zip:`). Esses addons não se atualizam sozinhos: a abertura da sessão lembra de conferir a página.

## Candidatos

| Papel | Addon | Fonte | Evidência de Forever | Marca | Observação |
|---|---|---|---|---|---|
| Diagnóstico | BugSack | GitHub `funkydude/BugSack` | conferido: TOC com 16001; `release.json` com forever 16001 | [base] | um zip para todos os flavors |
| Diagnóstico | !BugGrabber | só CurseForge (https://www.curseforge.com/wow/addons/bug-grabber) | página lista o flavor Forever; TOC não lido | [base] | o BugSack costuma usá-lo como coletor; o TOC do BugSack não declara a dependência no cabeçalho: conferir na instalação |
| Base de UI | ElvUI | Tukui `elvui` (o GitHub `tukui-org/ElvUI` não publica release) | conferido: `patch` inclui 1.60.1; TOC com 16001 e `[AllowLoadGameType camelot]` no título | [base] | escolha do dono; dispensa Bartender4 e addon de bolsa |
| Quests | Questie | GitHub `Questie/Questie` | conferido: `Questie_Camelot.toc` com Interface 16001 (v12.4.0) | [base] | a tag tem `+` no nome (`bundle/v12.4.0+v1.0.10`); na URL o `+` vira `%2B` |
| Quests | Forever Quests | só CurseForge (https://www.curseforge.com/wow/addons/forever-quests) | página mostra o flavor WoW Forever; TOC não lido | [opcional] | marca as quests novas do Forever nas dicas do Questie; licença "All Rights Reserved" |
| Navegação | TomTom | só CurseForge (o GitHub `jnwhiteh/TomTom` dá 404) | página lista o flavor Forever; TOC não lido | [opcional] | setas e waypoints |
| Chefes | DBM | GitHub `DeadlyBossMods/DeadlyBossMods` | conferido: `release.json` com forever 16001; TOC do DBM-Core com 16001 | [escolha um] | o DBM-Core exige `DBM-StatusBarTimers` (confirmar que vem no zip) |
| Chefes | BigWigs | GitHub `BigWigsMods/BigWigs` | release.json com forever 16001, segundo a T1 | [escolha um] | alternativa ao DBM; não instalar os dois |
| Dano | Details! | só CurseForge (o GitHub não tem release desde 2021) | `Details_Camelot.toc` com 16001, segundo a T1 | [base] | o jogo também tem medidor próprio (Skada e Recount aparecem como embutidos) |
| Economia | Auctionator | só CurseForge e Wago (o GitHub oficial não foi achado) | página lista o flavor Forever; TOC não lido | [base] | o TSM ainda não tem versão Forever |
| PvP | Capping | GitHub `BigWigsMods/Capping` | TOC e `release.json` com 16001, segundo a T1 | [opcional] | risco: os módulos não têm a marca camelot; testar no cliente antes de confiar |
| PvP | Peralex BG | só CurseForge | página lista o flavor Forever | [opcional] | alternativa ao Capping |
| Qualidade de vida | Leatrix Plus | só CurseForge | página lista arquivo `-forever` (1.60.25-forever, 21/10) | [opcional] | |

Fora do Forever (sem evidência): BattleGroundEnemies (TOC só 110200), GladiusEx (fork sem release, TOC só 11.x).

## Limites deste levantamento

- Onde a evidência é "segundo a T1", a linha do TOC foi lida por um resumo de modelo (WebFetch) e não pela sessão; o instalador confere o TOC de verdade antes de instalar.
- Dos 13 candidatos, 7 são só da CurseForge. Cada atualização deles depende de um clique do dono.
