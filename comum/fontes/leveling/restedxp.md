tema: leveling
fonte: RestedXP (addon RXPGuides, rotas grátis do Forever)
url: https://github.com/RestedXP/RXPGuides
data: 2026-11-04
seguir: as rotas grátis do Forever até o nível 20/21 e, depois, o guia pago, comprado pelo dono em 2026-11-13 (ativação abaixo; quais rotas vieram e por qual facção se confere depois da importação). Ignorar os guias de talento do addon, que no Forever carregam as builds do Classic Era.

# RestedXP: rotas grátis do Forever

Escolha do dono em 2026-11-04 para os dois personagens principais.

## O que vem no addon (lido `[página]` no GitHub, arquivos brutos pelo curl, sem resumo de modelo; versão v4.11.30 de 2026-11-03)

O `GuideList-forever.xml` só carrega no Forever (`[AllowLoadGameType camelot]` no TOC) e traz, para a Aliança, as rotas `Alliance-1-10_NightElf`, `Alliance-1-13_Human`, `Alliance-1-14_DwarfGnome` e `Alliance-11-20`, cada uma também numa variante com dungeons (pasta `dungeon\`), além das rotas de mago. O `release.json` da versão declara o flavor `forever` com a Interface 16001, então o modder instala e atualiza pelo GitHub.

| Personagem | Rota |
|---|---|
| Hexumlite Bull (Night Elf Hunter) | `Alliance-1-10_NightElf`, depois `Alliance-11-20` |
| Rurik Thunderfist (Dwarf Shaman) | `Alliance-1-14_DwarfGnome`, depois `Alliance-11-20` |

## Guia pago (comprado em 2026-11-13)

A compra não traz addon novo nem zip: o guia chega como um código de importação (import string) gerado no site para o Battle.net do dono e colado no RestedXP já instalado (passos e fontes em `..\..\referencia\forever.md`, seção Addons). As rotas importadas ficam nas SavedVariables da conta (`RXPDB`), então o backup do WTF as guarda. Pendente: importar no jogo e anotar aqui quais rotas apareceram.

## Cuidado com os talentos do addon

O TOC carrega `Guides/Talents/classic.xml` com `[AllowLoadGameType vanilla,camelot]`, ou seja, as builds de talento do Classic Era também no Forever, e o módulo de talentos só se desliga sozinho em versão de jogo acima de 50000 (o Forever é 16001). Como o Forever reescreveu boa parte dos talentos, a opção `enableTalentGuides` do addon deve ficar desligada. Lido `[página]` (arquivos brutos no GitHub) em `Talents.lua` e `RXPGuides.toc`, v4.11.30; conferir no disco depois da instalação.
