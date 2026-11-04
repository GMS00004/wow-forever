# WoW Forever: fatos conferidos

Cada fato leva a marca de como foi lido e a data. `[página]` é página aberta (pelo WebFetch, que resume a página); `[busca]` é só o resumo de uma busca; `[local]` é lido na máquina. Fato de terceiro é pista até ser conferido no cliente ou no TOC.

## Lançamento e conteúdo (lido em 2026-11-03)

| Fato | Marca | Fonte |
|---|---|---|
| Lançamento mundial em 2026-11-04 às 23:00 UTC (20h de Brasília) | [página] | Warcraft Wiki, Patch 1.60.1 |
| Nível máximo 60, "indefinidamente" | [página] | Warcraft Wiki |
| Raça nova Skyborne (Aliança: mago; Horda: xamã) | [página] | Warcraft Wiki |
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
