tema: profissoes
fonte: Gfinity (Herbalism, Cooking, First Aid, Enchanting, Leatherworking, Alchemy, Tailoring) e wow-professions.com (Mining, Skinning, Blacksmithing)
url: ver a tabela abaixo
data: 2026-11-05
seguir: o roteiro de perícia 1 a 300 de cada profissão, escolha do dono em 2026-11-05 ("Gfinity + wow-professions"). Os passos estão no addon próprio GuiaForever (`..\..\modder\addons-proprios\GuiaForever\ProfissoesA.lua` e `ProfissoesB.lua`) e aparecem no jogo com `/guia prof`.

# Roteiros de profissão

Os guias foram escritos no beta; nenhum tem data posterior ao lançamento (04/11), e a faixa de 225 a 300 aparece como não testada em vários deles. Os passos foram extraídos das páginas por subagentes (WebFetch, que reorganiza as tabelas), em português sem acentos, e as zonas da Horda foram retiradas.

| Profissão | Fonte | Data na página |
|---|---|---|
| Herbalism | https://www.gfinityesports.com/article/world-of-warcraft-forever-herbalism-guide-1-300-leveling-herb-map | 21/10/2026 |
| Cooking | https://www.gfinityesports.com/article/world-of-warcraft-forever-cooking-guide-1-300-leveling-trainers | 22/10/2026, atualizado 26/10 |
| First Aid | https://www.gfinityesports.com/article/world-of-warcraft-forever-first-aid-guide-1-300-leveling-trainers | 23/10/2026 |
| Enchanting | https://www.gfinityesports.com/article/world-of-warcraft-forever-enchanting-guide-1-300-leveling-trainers | 21/10/2026 |
| Leatherworking | https://www.gfinityesports.com/article/world-of-warcraft-forever-leatherworking-guide-1-300-leveling-trainers | 21/10/2026 |
| Alchemy | https://www.gfinityesports.com/article/world-of-warcraft-forever-alchemy-guide-1-300-leveling-trainers | 19/10/2026 |
| Tailoring | https://www.gfinityesports.com/article/world-of-warcraft-forever-tailoring-guide-1-300-leveling-trainers | 19/10/2026 |
| Mining | https://www.wow-professions.com/forever/mining-leveling-guide | sem data |
| Skinning | https://www.wow-professions.com/forever/skinning-leveling-guide | sem data |
| Blacksmithing | https://www.wow-professions.com/forever/blacksmithing-leveling-guide | sem data; 215 a 300 marcado como não testado |

## Pontos incertos

- Alchemy: a Gfinity manda fazer poções de cura, mas outras fontes (e o levantamento de `..\..\referencia\profissoes-forever.md`) dizem que elas passaram para o First Aid no Forever. Conferir no treinador.
- First Aid: a página da Gfinity se contradiz no livro de Expert (perícia 125 ou 150).
- Mining: a página dá os níveis de treino de dois jeitos (75/150/225 na introdução, 50/125/200 nas seções).
- Leatherworking: "Embossed Leather Pants" aparece em duas faixas seguidas; pode ser erro da fonte.
- Alternativas com "ou" ficaram com a primeira receita.

## Metas por área de quest (rastreador do GuiaForever, 2026-11-06)

Escolha do dono em 2026-11-06: o rastreador de profissões mostra a meta de cada área "pelo nível da área, a partir das fontes dele". Os números por faixa saem destas fontes e foram aprovados por ele; a ligação de cada zona a uma faixa é do agente, pelo nível típico dos bichos da zona, e está a conferir.

| Faixa de nível da área | Skinning (wow-professions, por nível de bicho) | Leatherworking (Gfinity, pelo couro da faixa) |
|---|---|---|
| 1–10 | 75 (bichos de nível 1–2 até 75; também o teto do Apprentice) | 75 (teto do Apprentice; o Journeyman pede nível 10) |
| 10–20 | 125 (bichos de nível 10–20, de 75 a 125) | 100 (Light Leather até 100) |
| 20–30 | 150 (bichos de nível 25–27, de 125 a 150) | 150 (Medium Leather de 100 a 150) |

Os números estão em `..\..\modder\addons-proprios\GuiaForever\Dados.lua` (`GuiaForeverRastreador`).
