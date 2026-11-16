> Relatório de pesquisa de 2026-11-16, da onda 1 do design do PregaoForever, gravado como estava (foto do dia). `<espelho>`, `<dados>` e `<tmp>` eram pastas temporárias da sessão; o Apêndice D do `DESIGN.md` diz como refazê-las. Onde este relatório e o `DESIGN.md` divergem, vale o `DESIGN.md`.

# R8a: Catálogo de estratégias de leilão com fonte pública (WoW Forever / Classic)

Data da pesquisa: 2026-11-16. Escopo: fichas das 8 estratégias do Faça, fecho e incógnitas.
Regra desta pesquisa: nenhuma estratégia entra aqui por opinião. Cada ficha diz o que a fonte afirma, a marca da evidência e o que ficou sem fonte.

Legenda das marcas: `local` = lido nesta máquina (não houve arquivo local relevante); `pagina` = página aberta com WebFetch (URL e data de leitura, que é 2026-11-16 em todas, salvo indicação); `busca` = só o resumo de um WebSearch, sem abrir a página; `inferencia` = conclusão minha.

Versão: o brief fala em build 70938 do cliente 1.60.1. A página da API no warcraft.wiki.gg marca a versão Forever como 1.60.1 (69913). A diferença de build não foi resolvida (ver Desvios).

---

## Fontes principais (lista de referência)

| Id | Fonte | Autor / marca | Data (da página) | Marca | Nota |
|---|---|---|---|---|---|
| F1 | https://support.tradeskillmaster.com/tsm-addon-documentation/tsm-addon-sniper-operations | TradeSkillMaster, docs | "Updated at March 6th, 2022" | pagina | Cobre Classic; é doc de 2022 |
| F2 | https://support.tradeskillmaster.com/tsm-addon-documentation/1072146-tsm-addon-auctioning-operations | TradeSkillMaster, docs | "updated March 6th, 2022" | pagina | Lógica de postagem (min/max/normal) |
| F3 | https://hearthproof.com/economy/auction-house/ | Hearthproof (site de fã) | "compiled Nov 14 2026 (v1.19)" | pagina | Cita posts da Blizzard; não verificado direto |
| F4 | https://loreforeverwow.com/guides/wow-forever-auction-house | Lore Forever (site de fã) | "Reviewed October 23, 2026" | pagina | Assume regras da Classic |
| F5 | https://warcraftforever.games/guides/auction-house | Warcraft Forever (site de fã) | "Updated 2026-09-19" | pagina | Dados de um addon próprio do autor, beta |
| F6 | https://eu.forums.blizzard.com/en/wow/t/wow-forever-hotfixes-november-10-2026/639885/1 | Blizzard, fórum oficial (Kaivax) | posts de 2026-11-05, 11-10 e 11-12 | pagina | Post oficial de hotfix; a página não rotula staff |
| F7 | https://www.foreverwisp.com/guides/wow-forever-auction-house-deposit-vendor-price-changes | ForeverWisp (site de fã) | "reviewed 11 Nov 2026" | pagina | Resume o post de 10/11 da Blizzard |
| F8 | https://tradeskillmaster.com/news | TradeSkillMaster, notícia | 2026-11-11 | pagina | TSM 4.15 em beta com Forever |
| F9 | https://www.foreverbase.org/en/addons/catalog/tsm/ | Foreverbase (site de fã) | "checked Nov 5, 2026" | pagina | Verificação de addons |
| F10 | https://wowcalc.net/en/forever/wiki/addons/tradeskillmaster | Wowcalc (site de fã) | "Verified Oct 29, 2026" | pagina | Desatualizado: diz "no Forever version yet" |
| F11 | https://www.curseforge.com/wow/addons/arbitrage | addon "Arbitrage", autor do addon | arquivo Forever v0.7.0 em 2026-11-15 | pagina | Descrição de cálculo de lucro de craft |
| F12 | https://warcraft.wiki.gg/wiki/API:C_AuctionHouse.StartCommoditiesPurchase | Warcraft Wiki (wiki comunitária) | "last edited 10 August 2026" | pagina | Página da API, tag Forever 1.60.1 (69913) |
| F13 | https://warcraft.wiki.gg/wiki/API:C_AuctionHouse.CalculateCommodityDeposit | Warcraft Wiki | "last edited 10 August 2026" | pagina | Durações 1/2/3 = 12/24/48 h |
| F14 | https://warcraft.wiki.gg/wiki/Auction_House | Warcraft Wiki | "last edited 29 Sep 2026", marcado "outdated" | pagina | Histórico de patches; não é Classic/Forever |
| F15 | https://us.forums.blizzard.com/en/wow/t/please-reinstate-the-classic-auction-house/2391410 | jogadores, fórum oficial | 2026-10-24/25 | pagina | Feedback de jogadores; sem staff |
| F16 | https://warcraft.wiki.gg/wiki/Disenchanting_tables | Warcraft Wiki | "last edited 5 March 2021", marcado "outdated" | pagina | Pré-BfA |
| F17 | https://www.gigwise.com/?p=42523 | guia sem autor identificado | página de 2025-10-21 | pagina | "WoW Classic" sem versão |
| F18 | https://blizzardwatch.com/2019/05/29/beginners-guide-grubbing-slaughtering-ruthless-ah-speculation-gold-wow-classic/ | Matthew Rossi, BlizzardWatch | "August 28, 2019" no texto (a URL diz 2019/05/29) | pagina | Classic 2019 |
| F19 | https://www.engadget.com/2011-08-19-neutral-auction-house-sniping.html | Basil Berntsen, WoW Insider (republicado no Engadget) | 2011-08-19 | pagina | Não é Forever nem Classic |
| F20 | https://www.engadget.com/2011/04/28/gold-capped-buy-low-sell-high/ | Basil Berntsen, WoW Insider | 2011-04-28 | pagina | Cataclysm |
| F21 | https://warcraft.wiki.gg/wiki/User:FuzzicalLogic/Guides/Auction_House_Guide | usuário da wiki | última edição 2011-06-27 | pagina | Era WotLK, inferência |
| F22 | https://almarsguides.com/WoW/Farming/Classic/AuctionHouse/Phases/Phase3 | Almar's Guides | sem data | pagina | Fase BWL da Classic; sem versão declarada |
| F23 | https://us.forums.blizzard.com/en/wow/t/for-new-ah-sellers-a-reminder-about-how-the-auction-house-works/1260791 | jogador, fórum oficial | 2022-06-10 | pagina | Post de jogador; versão não declarada |
| F24 | https://www.wowhead.com/classic/pt/news/wowhead-economy-weekly-wrap-up-320-338240 | SamadanPlaysWoW, Wowhead | "Criado 24/3/2024" | pagina | Corpo do texto não lido |

Fontes só por busca (sem abrir a página): ver as marcas `busca` em cada ficha.

---

## 1. Sniper de leilão mal precificado

**Mecanismo.** O lucro vem de comprar um anúncio abaixo do preço de mercado antes de quem o compraria. Do outro lado está o vendedor que precificou errado ou tem pouca atenção. Quem "vence" é quem vê o anúncio primeiro.

**Pré-condições.** Capital para comprar em um lote (o preço por unidade é o que importa para commodities). Acesso à varredura da casa. Tempo de reação. Liquidez suficiente para revender depois (ver ficha 2).

**Sinal mensurável.** A varredura precisa trazer, por anúncio: preço unitário, quantidade, momento da postagem (ou se é da última página, que tem os anúncios mais novos) e um preço de referência de mercado por item. A referência aparece nas fontes como "valor de mercado" ou "Region Market Value" (F17, marca pagina: "buy listings up to 70% of market value", sem versão declarada). Também aparece como "menos de cinco vezes o valor de vendedor" como zona de cuidado (F17). Um addon de Forever usa "rolling market values" e marca dados finos ou velhos como incertos (F11).

**Execução (como as fontes descrevem).**
- O TSM Sniper, na Classic, "will repeatedly search the last page of the Auction House until stopped" e lembra que "The last page of the Auction House contains items that have just been posted" (F1, marca pagina, doc de 2022). Na documentação, o único limite documentado de preço é o "Maximum price", que aceita strings personalizadas. O padrão está marcado "Coming SoonTM" (F1).
- Compra de commodity não é um clique só. A API `C_AuctionHouse.StartCommoditiesPurchase` "requires a hardware event i.e. keyboard/mouse input" e a compra é finalizada por `ConfirmCommoditiesPurchase` (F12, marca pagina). Isso vale como restrição de design (ver implicações).
- A ordem de venda é "cheapest listing sells first" (F5, pagina), e um post de jogador de 2022 descreve a fila como "Last-In-First-Out" para o mesmo preço (F23, pagina, jogador).

**Riscos e modos de falha.**
- Concorrência com outros snipers: o TSM Sniper repete a busca, então outros também a repetem (F1).
- Anúncio "isca" de vendedor: um post de 2022 descreve vendedores que anunciam alguns itens bem abaixo do mercado para atrair compradores e depois revendem o resto mais caro (F23, jogador, marca pagina; "Underpriced bait").
- Dado de referência ruim: o addon de Forever marca como incerto o cálculo com dados finos, velhos ou voláteis (F11).

**Fontes.**
| Fonte | O que afirma | Marca | Confiança |
|---|---|---|---|
| F1, TSM Sniper, doc 2022-03-06 | Sniper repete a busca na última página da casa; só limite de preço máximo documentado | pagina | alta (fato de doc, Classic, 2022) |
| F12, API StartCommoditiesPurchase, wiki de 2026-08-10 | Exige evento de hardware | pagina | média (wiki comunitária) |
| F17, Gigwise, 2025-10-21 | Compra até 70% do valor de mercado; cuidado abaixo de 5x o valor de vendedor | pagina | baixa (guia genérico, sem versão) |
| F23, jogador, 2022-06-10 | Isca de preço baixo; LIFO | pagina | baixa (jogador) |
| Sniper "dead" (F24) | Resumo do wrap-up de 2024: sniping existe na Classic por causa da última página | busca | baixa (não lido) |

Nenhuma fonte de Forever sobre sniping foi encontrada. Ver Incógnitas.

---

## 2. Flip: comprar barato e revender ao valor de mercado

**Mecanismo.** Compra-se abaixo do valor de mercado e revende-se perto dele. O lucro líquido é valor de venda menos preço de compra, menos a comissão da casa, menos o depósito perdido se o anúncio expirar ou for cancelado. A comissão de 5% aparece na wiki F14 (pagina, sobre retail, aplicada a todas as casas) e em fontes de fã de Forever (F5, pagina, 5% facção e 15% neutra). A Blizzard não confirmou o número de Forever, ver abaixo.

**Pré-condições.** Capital para estoque. Liquidez: a taxa de venda do item (o quanto ele vende por dia). Ver a ficha 3 e a ficha 4 para o risco de estoque parado.

**Sinal mensurável.** Preço do anúncio vs. valor de mercado, com histórico de vendas, e a taxa de venda. O addon Arbitrage, de Forever, usa "rolling market values" e diz que "listing deposits, available material depth, sale rate, inventory, and recipe cooldowns are not" incluídos no cálculo de lucro (F11, pagina). Isso indica que o lucro bruto de um flip sem depósito e sem taxa de venda é uma estimativa.

**Execução (fontes).**
- Relistar ao preço de mercado ou um pouco abaixo. Um guia de Classic diz "list items for 5-10% above this number" (F17, pagina, Market Value). Já F5 aconselha "Undercut by a copper, not by half" (pagina, Forever, guia de fã).
- Se o item expirar duas vezes, vender ao vendedor. Esta regra vem da página Wowpedia "Working the Auction House" (busca, sem versão).
- Um post de jogador de 2022 diz que cortar o preço "até o lucro ser zero" faz perder dinheiro, "unless bots are present" (F23, pagina, jogador).

**Riscos e modos de falha.**
- Estoque parado: BlizzardWatch (F18, pagina, Classic 2019) diz que mesmo com a comissão, vender materiais "pays better" que vender ao vendedor. Ao mesmo tempo, o guia dele avisa para não comprar gear na casa, porque é "a trap that mainly benefits other players" (F18).
- Comissão e depósito: em Forever, a comissão não está confirmada pela Blizzard. F3 diz que "Blizzard has published nothing on fees, durations or limits in Forever" (pagina, fã). F5 (fã) diz 5% na facção e 15% na neutra. F4 (fã) assume "Classic rules with no reported Forever change". Não há fonte da Blizzard para o número de Forever.
- Depósito: F6 (Blizzard, 2026-11-12) diz que a mudança de depósito mínimo "was temporarily removed" e voltaria na manutenção semanal de 18 de novembro. F3 e F7 dizem que o mínimo é 1 prata até a manutenção de 17 de novembro (dos EUA) e 1 cobre depois. Há conflito de data (ver Incógnitas).

**Fontes.**
| Fonte | O que afirma | Marca | Confiança |
|---|---|---|---|
| F1 e F2, docs TSM 2022 | Auctioning: min, max, normal; o cálculo do preço normal não se refere a valor de mercado | pagina | média (2022, Classic) |
| F3, Hearthproof, nov 2026 | Forever sem taxa publicada pela Blizzard; comissão "as in Classic" | pagina | média (fã) |
| F5, Warcraft Forever, set 2026 | 5% facção, 15% neutra; "Undercut by a copper" | pagina | baixa (fã) |
| F11, Arbitrage, nov 2026 | Lucro por craft com valor rolante; excluí depósito e taxa de venda | pagina | média (addon, em desenvolvimento) |
| F18, BlizzardWatch, 2019 | Vender material vale mais que vendedor; não comprar gear na casa | pagina | média (Classic 2019) |
| F17, Gigwise, 2025 | Comprar a até 70% do mercado; carteira de materiais como ponto de partida | pagina | baixa (genérico) |

---

## 3. Formação de mercado em commodity líquida (comprar na baixa e revender no spread)

**Resultado: sem fonte pública que descreva a formação de mercado no sentido de oferecer dos dois lados e capturar o spread.**

O que achei, e não é a mesma coisa:
- F20, Engadget / WoW Insider, 2011-04-28, Cataclysm (pagina): "Buy low, sell normal" e que comprar a preço bom permite revender "as quickly as someone who makes or farms the item" com lucro. Não fala de spread nem de ordens nos dois lados.
- F21 (pagina, wiki de 2011): o autor diz que "this practice does not directly apply to an economy as a whole" (buy low sell high). Não é fonte a favor da estratégia, é um aviso.
- F5 (pagina, fã): "Undercut by a copper". Isso é ordem de postagem, não formação de mercado.
- F3 (pagina, Hearthproof): stackable goods são vendidos "Priced per unit. The buyer types a quantity and gets the cheapest units first, from several sellers if need be." Isso é uma descrição da regra de compra por unidade de Forever (BETA, do próprio site). É o único ponto de Forever sobre commodities e é útil para o desenho de spread.
- F13 (pagina, API): a API tem `CalculateCommodityDeposit(itemID, duration, quantity)`, com custo de depósito para postar commodity.

Buscas sem resultado para "market making" ou "liquidity provider" em WoW ou Forever. Registrado: não achei.

Inferência minha (não é fato): um formador de mercado precisa de postagens contínuas e de capital parado. O depósito por postagem e a comissão tornam o spread estreito. Isso precisa de fonte antes de virar regra de design.

---

## 4. Reset de mercado raso (comprar tudo e repostar mais caro)

**Mecanismo.** Compra-se a oferta inteira de um item raso e reposta-se mais alta. Quem perde é quem vendeu barato. O lucro só existe se houver demanda real.

**Pré-condições.** Capital grande para comprar todos os anúncios. Demanda que sustente o preço. Um mercado com poucos vendedores.

**Sinal mensurável.** Número de anúncios por item e preço de mínimo, para medir quanto custa comprar toda a oferta. Também a taxa de venda, para testar a demanda.

**Execução e fontes.**
- F23 (pagina, jogador, 2022): "Reaper describes lowering prices, buying the cheap stock, and dumping it back once others try to reset the market". É um post de jogador, não de fonte oficial.
- Um guia de busca (CG Magazine, busca, sem data) diz que comprar tudo e repostar ao dobro "only works if demand exists" e que errar a demanda deixa a pessoa "stuck holding the bag" (busca).
- Um comentário de Wowhead Classic (busca) afirma que cornering exige "deep coffers" e é "one of the easiest ways to make a very expensive mistake" (busca).

**Riscos e modos de falha.**
- Capital parado e demanda mal lida (busca, CG Magazine).
- A Blizzard limitou ações em massa no BC Classic: um atraso para quem lista, dá lance, compra ou cancela muitos leilões (busca, mein-mmo.de, sem leitura da página; a fonte oficial não foi aberta).
- Forever: nenhuma fonte de Forever sobre limite de compra em massa ou de ações por minuto foi achada.

**Fontes.**
| Fonte | O que afirma | Marca | Confiança |
|---|---|---|---|
| F23, jogador, 2022-06-10 | Padrão de compra e repost (Reaper) | pagina | baixa (jogador) |
| CG Magazine, mastering-the-auction-house | Repost ao dobro só com demanda | busca | baixa |
| Wowhead Classic comentário | Cornering caro | busca | baixa |
| mein-mmo.de, BC Classic throttle | Atraso para ações em massa | busca | média (notícia, não lida) |

---

## 5. Arbitragem contra o vendedor (leilão abaixo do preço de vendedor) e revenda de item de vendedor com estoque limitado

**Mecanismo.** Um anúncio abaixo do preço que o vendedor NPC cobra cria uma janela: compra-se na casa e revende-se, ou compra-se do vendedor e revende-se na casa. A margem depende de o preço do vendedor ficar fixo e do depósito ser ligado ao valor de venda ao vendedor.

**Pré-condições.** Acesso ao vendedor e a um item com estoque. Para o item de estoque limitado, nenhuma fonte de Forever foi achada.

**Sinal mensurável.** Preço do anúncio vs. preço de vendedor (valor de venda ao vendedor). O addon Vendor Price Plus mostra "vendor, per-unit, and stack prices" (busca, CurseForge, sem leitura). Better Vendor Price mostra valor por unidade e por pilha em tooltips (busca).

**Fatos de Forever sobre preço de vendedor (Blizzard, pagina, F6 e F7):**
- 2026-11-05 (Kaivax): "Mild Spices now sell to vendors for 1 copper each (was 2 copper)."
- 2026-11-10 (Kaivax): "Minor Arcane Elixir sell value reduced to 5 copper (was 25 copper)." e "Iron Grenades vendor price reduced to 1 silver 25 copper (was 5 silver)." e "Reduced the price vendors pay for some crafted armor items from Leatherworking, Tailoring, and Blacksmithing."
- Hearthproof (F3) cita a Blizzard: "All crafted common and uncommon quality wands now sell at vendors for 1 copper." e "When selling to a vendor a BoE item which has an appearance you have not collected, the item will now become soulbound."

**Execução (fonte).** Não há fonte pública de Forever sobre o fluxo de compra no vendedor para revenda na casa. F9 e F3 mencionam "Vendor Price Plus" como ferramenta de leitura de valor de vendedor (pagina). O AHledger diz ter um recurso de "vendor flips" que mostra o lucro por compra no vendedor (busca, sem leitura: a página do AHledger deu HTTP 429).

**Riscos e modos de falha.**
- A Blizzard muda preço de vendedor por hotfix (três mudanças em Forever só em novembro, F6). A margem pode sumir de um dia para o outro.
- Vincular ao vendedor: alguns itens vão para "soulbound" ao vender (F3, Blizzard), o que muda o que pode ser revendido.
- Estoque limitado: nenhuma fonte achada para Forever.

**Fontes.**
| Fonte | O que afirma | Marca | Confiança |
|---|---|---|---|
| F6, Blizzard forum hotfixes | Datas e valores de vendedor (nov 2026) | pagina | alta (texto oficial, sem staff rotulado) |
| F3, Hearthproof | Citação de Blizzard sobre wands e BoE | pagina | média |
| F17, Gigwise 2025 | Cuidado abaixo de 5x o valor de vendedor | pagina | baixa |
| F9, Foreverbase | Vendor Price Plus | busca | baixa |

---

## 6. Arbitragem de conversão: produzir, desencantar, fundir minério, cortar pano

**Mecanismo.** Um insumo vira um produto (craft, desencantamento, fundição, corte). O lucro é o valor do produto menos o custo dos insumos, menos comissões, menos tempo.

**Pré-condições.** Profissão ou acesso a ela; receitas aprendidas; capital para insumos. Nível de habilidade define quais itens podem ser desencantados (F16, pagina).

**Sinal mensurável.** Preço do produto na casa, preço mínimo por unidade dos insumos na varredura mais recente, e o valor de vendedor. O Arbitrage (F11, pagina) calcula "best case" pelo "latest scan's minimum material cost" e um "primary estimate" pelos "rolling market values".

**Tabela de desencantamento (F16, pagina, wiki "outdated", última edição 2021-03-05).** O texto da página diz "pre Battle for Azeroth and need to be updated". As linhas de item de nível 5 a 65 seguem a faixa de Classic, mas a página não diz isso. Exemplo de linha de verde de armadura, faixa 16-20: "Strange Dust 75% 2-3x / Greater Magic Essence 20% 1-2x / Small Glimmering Shard 5%". Azul (raro) faixa 1-25: "Small Glimmering Shard 100%". Inferência: a tabela é a referência de Classic, não de Forever. Não confirmado para Forever.

**Execução (fontes).**
- Desencantar greens em vez de anunciá-los. Um guia de TBC (busca, bittsguides) diz que greens vendem devagar e as taxas podem zerar o lucro, e que o custo deve ser "equal to or less than the average sales price x 0.95".
- Cataclysm (busca): margem alvo de pelo menos 30%, porque prospecção dá trabalho.
- Arbitrage (F11, pagina): ranking por lucro estimado por craft, com comissão, mas sem depósito, profundidade de insumos, taxa de venda, inventário e cooldown.

**Riscos e modos de falha.**
- Preço de saída mudar por hotfix de vendedor (F6, ex.: Iron Grenade de 5 prata para 1 prata 25 cobre).
- Dados de custo ruins: F11 marca incerto com dados finos.
- Os guias de TBC e Cataclysm (busca) não são de Forever. A margem deles não serve sem conferência.

**Fontes.**
| Fonte | O que afirma | Marca | Confiança |
|---|---|---|---|
| F16, wiki Disenchanting tables, 2021-03-05 | Tabela de desencantar, pré-BfA | pagina | média (desatualizada) |
| F11, Arbitrage | Cálculo e limites de lucro de craft | pagina | média (addon em desenvolvimento) |
| F6, Blizzard | Redução de preço de vendedor de itens fabricados | pagina | alta |
| TBC guide (bittsguides), busca | Custo ≤ 0.95 × média | busca | baixa |

---

## 7. Sniper de lance em leilão que está acabando

**Mecanismo.** Um comprador dá lance no último instante, antes que o leilão expire, pegando um item que os outros não viram. Em leilão com lance, o dinheiro fica em escrow até o fim (F14, pagina, sobre retail): "the amount is placed in escrow until the auction is over."

**Pré-condições.** Dinheiro para dar o lance. Tempo de reação. Conhecer o horário de fim (depende da duração, ver Incógnitas).

**Sinal mensurável.** Anúncio com lance e tempo restante pequeno. Para extensão automática, o sinal é a mudança do tempo restante depois de um lance.

**Execução e fontes.**
- F14 (pagina, wiki sobre retail, página marcada outdated): "Each time a bid is made on an item, a small amount of time is added to the remaining auction duration." A página atribui isso a um patch 1.1.0, sem versão de Forever ou Classic. O resumo da leitura não confirmou o ano desse patch. Marca: pagina, confiança baixa para Forever.
- F14 também diz: "you may be less likely to be outbid if bidding right before the server shuts down." (pagina).
- F5 (pagina, fã): "most buyers never bid", o que sugere que quase toda compra é por buyout e lance é raro.
- F3 (pagina, fã): "Commodities... Priced per unit" com buyout. Não diz se commodities aceitam lance. F3 declara que não sabe se "stackable goods can be bid on".
- Busca geral sobre sniping de leilão (busca) não é específica de WoW.

**Riscos e modos de falha.**
- A extensão de lance pode não existir em Forever. Não há fonte de Forever.
- Lance preso: "you can't cancel it; the only way of getting your money back is for someone else to outbid you" (F14, pagina, sobre retail).
- Duração conflitante muda o horário do último instante (ver Incógnitas).

**Fontes.**
| Fonte | O que afirma | Marca | Confiança |
|---|---|---|---|
| F14, Warcraft Wiki Auction House | Extensão de lance; escrow; lance preso | pagina | baixa (retail, sem versão clara) |
| F5, Warcraft Forever | Quase ninguém dá lance | pagina | baixa (fã) |
| F3, Hearthproof | Não sabe se commodities aceitam lance | pagina | média |

---

## 8. Arbitragem entre facções pela casa neutra

**Mecanismo.** A casa neutra aceita as duas facções. Se o preço de um item diferir entre facções (e o item puder ser levado para a casa neutra), há uma janela. A comissão é mais alta na neutra, então a janela precisa ser maior.

**Pré-condições.** Acesso às duas facções ou a um personagem da outra. Viagem até a casa neutra. Capital.

**Sinal mensurável.** Preço do item nas duas facções (dados de cada facção) e a comissão da neutra. A regra da neutra é cobrar mais.

**Fatos de Forever.**
- Neutras em Forever: "Gadgetzan, Booty Bay, and Everlook" é o que o F4 "expects... to work as they do in Classic", uma suposição, não um fato. O site howtovideogame diz "Each capital has a house, and the neutral houses are in Gadgetzan, Booty Bay, and Everlook" (busca).
- F5 (pagina, fã): "Both factions can use them, at a steeper cut — this is the only way to trade with the other side. Blizzard has not announced a cross-faction auction house for Forever." E: "a large price gap between the factions is worth the trip to Booty Bay".
- Comissão: F5 diz 15% na neutra e 5% na facção (pagina, fã). F3 diz que a comissão em Forever está "As in Classic", sem número de Forever (pagina).

**Fontes da estratégia em outros cenários (retail/Cataclysm, não Forever).**
- F19 (pagina, 2011-08-19, WoW Insider): a casa neutra "costs three times as much to use", com "that 15% AH cut", e vendedores que anunciam por 1 cobre para evitar a comissão ficam expostos a quem compra (sniper). A coluna não diz a versão e ela é de 2011.

**Riscos e modos de falha.**
- Comissão de 15% (fã) come a janela.
- Sem casa entre facções anunciada (F5), a janela depende de viajar até a neutra.
- F3 (pagina) diz que a Blizzard não explicou como funciona a casa do Black Market (Powderfuse Port, citada em busca). Essa casa não entra na conta de arbitragem entre facções até haver fonte.

**Fontes.**
| Fonte | O que afirma | Marca | Confiança |
|---|---|---|---|
| F5, Warcraft Forever | Neutra, comissão, sem cross-faction, "price gap" | pagina | baixa (fã) |
| F3, Hearthproof | Comissão "as in Classic", sem número de Forever | pagina | média |
| F4, Lore Forever | Neutras assumidas como Classic | pagina | baixa |
| F19, Engadget 2011 | Neutra 3x custo e 15% (2011) | pagina | baixa para Forever |

---

## 9. Fecho: fonte boa, folclore e o que é específico da Classic

### 9.1 Estratégias com fonte boa (fonte oficial ou documentação, com data)
- Sniper (ficha 1): doc do TSM 2022 e a API da Blizzard (pagina, wiki de 2026). Boa para a mecânica de varredura; fraca para o lucro, porque o doc não diz nada de limiar de lucro.
- Dados de Forever sobre taxa, depósito e preço de vendedor (fichas 2, 5, 8): fonte da Blizzard (F6, pagina) para os valores de vendedor. Para depósito e comissão, a fonte boa é da Blizzard, mas a página só diz que mudou; os números da comissão de Forever não têm fonte oficial.

### 9.2 Estratégias com fonte fraca ou só de fã/jogador
- Flip (ficha 2): comum, com fonte de fã e de guia genérico.
- Reset (ficha 4): fonte de jogador (F23) e busca. É folclore com um pouco de documento.
- Bid-sniping (ficha 7): fonte geral e wiki de retail; sem Forever.
- Neutral (ficha 8): fonte de fã para Forever; fonte de 2011 para o princípio.

### 9.3 Sem fonte achada
- Formação de mercado (ficha 3): sem fonte de spread.
- Estoque limitado de vendedor em Forever (ficha 5): sem fonte.
- Sniping de Forever (ficha 1): sem fonte específica de Forever.

### 9.4 Específico de Classic (conferir no Forever)
- Comissão 5%/15% (Classic, F21/F5): Forever não confirmado.
- Durações: 12/24/48 h em Forever segundo F3 (pagina, marcado BETA) e segundo a API F13 (`duration` 1, 2, 3 = 12, 24, 48 h). Em contraste, F5 (fã, Forever) diz 2/8/24 h, e F3 cita 2/8/24 h como "Classic's" numa visão concorrente. Conflito. A API pesa a favor de 12/24/48, mas é inferência a partir de uma página da wiki.
- Depósito mínimo: 1 prata até a manutenção de 17/18 de novembro, depois 1 cobre (F3, F6, F7). Data conflitante.
- Vendedores e tabela de desencantar: tabela de pré-BfA (F16).
- Neutras: Gadgetzan, Booty Bay, Everlook (Classic, assumido em F4).
- Lance e extensão: regra de retail (F14), não confirmada.

---

## Incógnitas (com o jeito de conferir no jogo)

1. Comissão da casa em Forever (facção e neutra). Conferir: vender um item barato e comparar o valor recebido com o preço do anúncio; repetir na casa neutra.
2. Durações de anúncio em Forever (12/24/48 h, F3 e F13, ou 2/8/24 h, F5). Conferir: abrir o menu de duração ao postar e ler as opções.
3. Depósito mínimo depois da manutenção de 17 de novembro (NA) e 18 de novembro (EU, segundo F6). Conferir: ver o depósito no painel de postagem depois da manutenção, em um item de teste.
4. Extensão de lance em Forever: se um lance no último minuto estende o tempo. Conferir: dar um lance pequeno com pouco tempo sobrando, em conta própria, e ver o tempo restante do anúncio.
5. Commodities podem receber lance? (F3 não sabe.) Conferir: ver a aba de lance em um anúncio de commodity.
6. TSM 4.15 em Forever: se Sniper e Auctioning funcionam. Conferir: instalar a versão final do TSM quando sair (F8 diz beta em 2026-11-11) e ler as operações no jogo. Não instalar nada agora.
7. Limite de ações em massa (reset/cornering) em Forever. Conferir: notas de patch oficiais da Blizzard depois de cada hotfix.
8. Existência de estoque limitado de vendedor em Forever. Conferir: ler a lista de vendedores de cada cidade-capital no jogo.
9. Formação de mercado com spread: nenhuma fonte. Conferir só depois de haver fonte.
10. Localização e comissão das neutras (Gadgetzan, Booty Bay, Everlook e o Black Market em Powderfuse Port, F3 e busca). Conferir: visitar as casas no jogo.

---

## Não achado (registro)
- Formação de mercado com spread (ficha 3): nenhuma fonte.
- Sniping de Forever (ficha 1): nenhuma fonte específica.
- Estoque limitado de vendedor (ficha 5): nenhuma fonte.
- Lance de commodity (ficha 7): nenhuma fonte.
- Vídeos: nenhum vídeo foi usado. Não há fonte em vídeo.
- Não consultei AHledger (HTTP 429), Wowhead guia de casa de leilão (HTTP 404), Warcraft Tavern (redireciona para barrens.chat, HTTP 403) e o TSM guia de Forever (HTTP 403). Não tentei contornar.

---

## Desvios
- A build do brief é 70938 do 1.60.1. A wiki da API marca o Forever como 1.60.1 (69913). Não resolvi a diferença.
- O brief pede "fonte com URL ou o registro de que não achou" em cada ficha. Ficha 3 e ficha 5 (estoque limitado) não têm fonte de Forever; registrei.
- O BlizzardWatch aparece no link com data 2019-05-29, mas o texto da página diz 28 de agosto de 2019. Usei a data do texto.
- Algumas fontes de busca têm conteúdo de resumo gerado pelo buscador. Marquei como `busca` e não as usei como fato sem leitura.
