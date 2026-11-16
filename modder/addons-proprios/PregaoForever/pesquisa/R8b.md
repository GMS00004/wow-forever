> Relatório de pesquisa de 2026-11-16, da onda 1 do design do PregaoForever, gravado como estava (foto do dia). `<espelho>`, `<dados>` e `<tmp>` eram pastas temporárias da sessão; o Apêndice D do `DESIGN.md` diz como refazê-las. Onde este relatório e o `DESIGN.md` divergem, vale o `DESIGN.md`.

# R8b: estratégias de tempo e de economia de lançamento no leilão (WoW Forever)

Data da pesquisa: 2026-11-16. Só fontes públicas abertas nesta sessão ou arquivos locais lidos. Nada foi escrito no jogo. Pasta do jogo lida só em leitura: `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/`.

Leitura geral antes das fichas: quase toda a orientação de tempo e de lançamento para o Forever vem de guias de ouro (comerciais) ou de guias fãs, muitos escritos sobre o beta (build 70888 e anteriores). Não encontrei nenhuma fonte com dados medidos de ciclo horário ou semanal no Forever, nem de lançamento de servidor com números no Classic 2019 ou na Season of Discovery. Onde a fonte é só opinião, a ficha diz isso.

Fontes usadas e a marca de cada uma:

| Sigla | Fonte | Data | Natureza |
|---|---|---|---|
| MM | mmonster.co, guia de ouro do Forever (`https://mmonster.co/wow-forever/guides/gold`) | atualizado 2026-11-05 (build beta 70888) | guia de ouro, possivelmente comercial |
| LF | lfcarry.com, guia de economia do Forever (`https://lfcarry.com/guides/wow-forever-gold-economy`) | atualizado 2026-11-07 | vende ouro e boost (interesse comercial) |
| FG | theforeverguides.com, guia do leilão (`https://theforeverguides.com/gold-making/auction-house/`) | site atualizado 2026-11-05 | fã, com marcas beta / Classic / sem rótulo |
| U4N | u4n.com, guia do leilão (Aiden Gray) (`https://www.u4n.com/news/wow-forever-auction-house-guide-commodities-auctionator-and-why-undercutting-has-changed.html`) | publicado 2026-10-05, atualizado 2026-11-16 | vende ouro (interesse comercial) |
| FW | foreverwisp.com, bug do depósito (`https://www.foreverwisp.com/guides/wow-forever-auction-house-deposit-bug`) | revisado 2026-11-11 | editorial, cita relatos de beta |
| BLZ-F | fórum oficial, tópico "Auction house deposit fee not changed" (`https://eu.forums.blizzard.com/en/wow/t/auction-house-deposit-fee-not-changed-even-though-patch-notes-says-so/641712`) | 2026-11-11 | relatos de jogadores, sem resposta da Blizzard |
| WIKI | warcraft.wiki.gg, "Auction House" (`https://warcraft.wiki.gg/wiki/Auction_House`) | editado 2026-09-29 | referência geral, retail, sem regra específica de Forever |
| TG | TheGamer, Patricio Kobek (`https://www.thegamer.com/blizzard-black-lotus-mafia-takedown-world-of-warcraft-classic-economics/`) | 2020-06-20 | Classic (Vanilla), dados reportados sem fonte |
| AMS | almarsguides.com, fases do leilão Classic (`https://almarsguides.com/wow/farming/classic/auctionhouse/`, `.../phases/phase3/`) | sem data, copyright 2026 | guia fã, Classic sem versão nomeada, sem dados |
| FORUM-2020 | fórum oficial, "Naxx Consumes, ~1200 gold a week" (`https://us.forums.blizzard.com/en/wow/t/naxx-consumes-1200-gold-a-week/758093`) | 2020-12-05 | Classic, anedotas |
| UNDM | undermine.exchange, API (`https://undermine.exchange/api.html`) | sem data | rastreador, cobre só retail |

---

## 1. Arbitragem no tempo: ciclo por hora, dia da semana, noite de raide e reset

### O que as fontes afirmam

- MM (Forever, beta, unlabelled em parte): "Sell when players are online, in the evening and before raid nights." Também: "Post at peak hours, in the evening and before raid nights." Não dá horário nem ciclo.
- FG: "Prices move fast and undercuts land within minutes, so post in batches and recheck each session." e a janela "Sydney late morning to afternoon lines up with the US evening... This timing is our editorial advice, not data."
- AMS (Classic, versão não nomeada): "it's always best to buy from the AH on Mondays/Tuesdays", "it's always best to sell on Friday/Saturday", "The best time to buy is normally between 3 - 8am before anyone wakes up on Monday." Sem dado, sem amostra, sem fuso.
- AMS: "Demand and prices for raid consumables are expected to spike on raid day, as players buy at the last minute." Baseado na observação do autor.
- Reset: não achei reset semanal de raide publicado pela Blizzard para o Forever. Os sites de reset (busca) dão terça 15:00 UTC para US e quarta 04:00 UTC para EU, mas admitem que não é publicado para o Forever.

### Mecanismo

Jogadores que jogam à noite ou no fim de semana postam e compram mais. Consumíveis são comprados perto da raide. A fonte para isso é observação, não medição.

### Sinal mensurável no leilão

Preço mínimo por hora do dia e por dia da semana, por item de comando (commodity), por reino e por lado.

### Riscos

- Nenhuma fonte com dado medido para o Forever. As regras de "segunda para comprar, sexta para vender" são de Classic sem versão nomeada (AMS) e não foram conferidas.
- O guia AMS diz que o padrão "depende do item e do servidor", o que tira força de qualquer regra fixa.
- O ciclo é do beta/primeiras semanas, quando o volume é pequeno (LF: "Week 1 is a queue as much as a market").
- Rastreadores públicos de histórico (UNDM) cobrem só retail; não há fonte externa de histórico do Forever encontrada.

### Fontes

- MM: `https://mmonster.co/wow-forever/guides/gold` (lido 2026-11-16).
- FG: `https://theforeverguides.com/gold-making/auction-house/` (lido 2026-11-16).
- AMS: `https://almarsguides.com/wow/farming/classic/auctionhouse/` (lido 2026-11-16).

---

## 2. Economia de lançamento de servidor (materiais e oferta de ouro nas primeiras semanas)

### O que as fontes afirmam (Forever)

- MM: "Do not buy on the auction house in launch week, everything is overpriced." (nível 1-20).
- MM: "Sell everything raw in week one, and craft later when prices fall." e "The beta showed the curve: low materials lost 40 to 70 percent within two weeks of the first wave." e "Prices drop once the gatherers catch up." Tudo do beta.
- MM: "Sell raw in launch week, when every new crafter buys them" (Linen Cloth, Copper Ore, Peacebloom); "Copper and Tin are some of the best sellers of launch week."
- LF (2026-11-07): "Week 1 is a queue as much as a market." "Vendors set the price floor because nobody has anything else" e "Raw materials are worth more than finished goods until the mid brackets fill." Qualitativo, sem preço de leilão.
- FG: "Forever prices start from zero at launch and aren't mixed with other versions," e "treat early numbers as thin." Diz também que "Blizzard doesn't publish Forever AH prices" e "Beta prices don't carry over."

### O que as fontes afirmam (Classic, para comparação)

- Não encontrei nenhuma fonte com números de preço do leilão no lançamento do Classic (agosto de 2019), nem da Season of Discovery, nem do aniversário, em páginas abertas. A busca de TSM trouxe só notas de suporte a addon (2019) e um histórico de NexusHub que começou em março de 2020 (busca, não aberto), então não cobre a semana de lançamento.
- Do Classic, existe só o caso de Lótus Negro de 2020 (ver ficha 4) e o relato de fórum de dezembro de 2020 (FORUM-2020) de consumíveis sendo estocados na primeira semana, sem dados.

### Mecanismo

Fornecedores de graça (vendor) definem o piso; quem coleta chega primeiro e vende cru; depois que os coletores alcançam a oferta, o preço cai. A fonte MM diz isso com base no beta, sem número de amostra.

### Sinal mensurável no leilão

Mediana de preço por item de comando nos dias 0 a 14 depois do lançamento, por reino. Ponto de virada: quando o preço cai abaixo do valor de vendedor. O beta (MM) diz 40% a 70% em duas semanas para materiais baixos.

### Riscos

- Todo número de decaimento é do beta. O próprio MM diz "Expect the same curve at launch", o que é hipótese.
- Fontes de ouro (MM, LF, U4N) têm interesse comercial em vender ouro e ajuda.
- O lançamento foi em 2026-11-04 (LF, MM, U4N); a janela de medição real é pequena (hoje é dia 12 de lançamento).

### Fontes

- MM: `https://mmonster.co/wow-forever/guides/gold` (lido 2026-11-16, trecho da seção Auction house e Launch week).
- LF: `https://lfcarry.com/guides/wow-forever-gold-economy` (lido 2026-11-16).
- FG: `https://theforeverguides.com/gold-making/auction-house/` (lido 2026-11-16).
- FORUM-2020: `https://us.forums.blizzard.com/en/wow/t/naxx-consumes-1200-gold-a-week/758093` (lido 2026-11-16).

---

## 3. Choque de demanda na abertura de raide (consumíveis, encantamentos, resistências)

### O que as fontes afirmam

- AMS (Classic, sem versão nomeada, sem dados): "Fire Resist gear is near-worthless after Ahn'Qiraj" ("By the time Ahn'Qiraj is released almost no one cares about Fire Resist gear anymore and the value of it plummits."). "The nature potions aren't going to be used until Ahn'Qiraj, at which point the price of Elemental Earth will skyrocket." ("skyrocket" não é quantificado.) "Demand shifts from fire to nature resistance in Phase 4." Tudo previsão do autor.
- AMS: "Some guilds will use a lot less consumables during this phase." (previsão).
- FORUM-2020 (Classic, dezembro de 2020): "~99% of the playerbase is running naxx, so everyone is buying consumes" (estimativa sem fonte). Preço de flask e Lótus Negro: "completely out of control", sem número. Um relato: "dropping 40-60g for stack of either herb" (estimativa de um jogador). Outro: "People are using consumables by habit in Naxxramas when it's super not necessary."
- MM (Forever): "Sell when players are online, in the evening and before raid nights." (ver ficha 1, sem número.)
- Forever: não achei relato medido de consumíveis ou resistências ao abrir raide no Forever. A data da primeira raide (unlock) não está confirmada. Um site cita 2026-12-09, sem confirmação (busca, não aberto).
- Sobre encantamentos: não achei fonte aberta com números nem relato de choque de demanda por encantamento.

### Mecanismo

Quando um conteúdo abre, o item que ele usa sobe de preço. Itens da raide antiga caem. Quem tem estoque ganha com a alta, quem compra à última hora paga mais (AMS: "paying more").

### Sinal mensurável no leilão

Preço mediano e volume (quantidade de lotes) de cada consumível e de cada resistência nos 7 dias antes e nos 3 dias depois da abertura da raide. Medição de sustentação: se o preço volta ao piso em uma semana.

### Riscos

- Tudo de Classic é sem dado. O único número (Lótus Negro, ficha 4) é de 2020 e de outro jogo.
- Fontes de 2020 mostram que decisões de patch podem mudar a demanda por consumível de uma vez.
- Não há data de raide confirmada no Forever (ver incógnitas).

### Fontes

- AMS (fase 3): `https://almarsguides.com/wow/farming/classic/auctionhouse/phases/phase3/` (lido 2026-11-16).
- FORUM-2020: `https://us.forums.blizzard.com/en/wow/t/naxx-consumes-1200-gold-a-week/758093` (lido 2026-11-16).
- Data de raide não confirmada: busca de "WoW Forever weekly reset time raid lockout" (busca, 2026-11-16); o site wowforevertierlist.com diz que a Blizzard não publicou reset nem bloqueio.

---

## 4. Receitas, plantas e itens raros de mundo como mercado

### O que as fontes afirmam

- MM (Forever, beta): "At the beta cap of 30 they were the biggest single sales on the auction house, 70g to 250g for the best ones." (drops azuis BoE). Também: "prices fall once many players reach the level."
- MM (beta): "Pristine Leather, Frilled Lichen and Pyrite 'rose to 2 to 4 times their price in the beta.'" Também: "Linen and Wool both fell close to their vendor price within two weeks." e "Silk lost more than half its price once the first tailors had leveled."
- FG: sobre Scarce materials: "Their sources aren't confirmed yet, so expect thin supply." (Não confirmado.) "Crates divert raw materials away from the AH, which can push those prices up." (Sem rótulo.)
- MM e LF: Lótus Negro e Cristal Arcano vendidos a 50g pelo Mister Graphed (Mercado Negro, Powderfuse Port), e "A vendor at Powderfuse Port sells Black Lotus for 50g, so its price has a ceiling." (MM). FG: "Nobody pays more than that on the auction house, so your own Lotus and Crystals always sell under it." e "In the beta both traded far under the cap with few sales: 50g is a ceiling, not a price."
- TG (Classic, 2020-06-20, dados reportados): "Black Lotus is the rarest herb and is needed for the strongest flasks." Após a mudança de 28 de maio de 2020 (mais nós de spawn, mortos não veem spawn), os preços caíram: "reports of 40 gold or lower, 'a drop of around 87%'." A base de 300 ouro é "could list Black Lotus on the Auction House for around 300 gold a piece", sem fonte. O autor diz "What we are seeing is a new equilibrium between supply and demand."

### Mecanismo

Item de mundo tem oferta fixa (spawn, drop). O mercado sobe quando a oferta é pouca; cai quando alguém muda o spawn ou quando a demanda some (item de conteúdo passado). Mercado do Mercado Negro tem teto de vendedor (50g), o que limita a alta.

### Sinal mensurável no leilão

Volume de lotes e preço por faixa de nível (MM: "prices fall once many players reach the level") para cada item raro. Taxa de venda: quantos lotes vendem em 24 ou 48 horas (ver a duração de leilão na ficha de incógnitas).

### Riscos

- Os números de beta (MM) são de uma fase sem preço real.
- Mudanças de spawn ou de drop podem quebrar a tese de um item de uma vez (TG: queda de 87%).
- Dados de drop do addon são do Classic, não verificados para o Forever.

### Fontes

- MM: `https://mmonster.co/wow-forever/guides/gold` (lido 2026-11-16).
- FG: `https://theforeverguides.com/gold-making/auction-house/` (lido 2026-11-16).
- TG: `https://www.thegamer.com/blizzard-black-lotus-mafia-takedown-world-of-warcraft-classic-economics/` (lido 2026-11-16; artigo de 2020-06-20 por Patricio Kobek).

---

## 5. O que os guias e vídeos de ouro do Forever recomendam para o leilão

Vídeos: não abri nenhum vídeo. Não há vídeo lido nesta pesquisa.

Recomendações listadas, uma por linha, com a fonte e a marca de confiança.

| # | Recomendação | Fonte | Marca | Observação |
|---|---|---|---|---|
| R1 | "Do not buy on the auction house in launch week, everything is overpriced." | MM (Níveis 1-20, Save) | pagina | beta-era, sem número |
| R2 | Guardar drops azuis para o leilão: "Keep every blue BoE drop for the auction house." | MM (FAQ) | pagina | beta |
| R3 | "Never vendor a blue BoE drop." | MM (FAQ) | pagina | beta |
| R4 | Vender cru na primeira semana; craftar depois que o preço cair: "Sell everything raw in week one, and craft later when prices fall." | MM | pagina | beta |
| R5 | "Sell when players are online, in the evening and before raid nights." | MM | pagina | sem horário |
| R6 | Deixar margem para a última oferta, em vez de um cobre abaixo: "leave a real gap to the last price instead of a single copper." | MM (flipping) | pagina | relato de bots no beta |
| R7 | Postar em lotes e rechecar a cada sessão: "post in batches and recheck each session." | FG | pagina | editorial, sem dado |
| R8 | Nunca listar abaixo do vendedor: "never list below vendor price" | FG (Fees) | pagina | sem rótulo |
| R9 | Verificar o leilão antes de vender item craftado: "a crafted item's vendor price is no longer a safe floor, so check the AH before you vendor it." | FG | pagina | inferência do editor sobre notas de 15 de outubro |
| R10 | Não usar a taxa da casa de leilão em "neutra": "the neutral houses ... keep 15 percent", e a sugestão de não usar as casas neutras (cross-faction) | FG, MM | pagina | conflito com a correção de 15 de novembro |
| R11 | Comandos (materiais, consumíveis) se compram pela quantidade; itens equipáveis por lote | U4N | pagina | confirma o modelo do Blizzard (sem citação direta) |
| R12 | Desfazer e refazer listagem para bater um vendedor não ajuda em comandos: "Undercutting by the smallest possible amount isn't automatically useful anymore." | U4N | pagina | editorial |
| R13 | Auctionator: pesquisar materiais na janela de profissão e comparar com o custo do item final | U4N | pagina | recurso de addon, não de mercado |
| R14 | Lotes de tamanho de receita: "list in recipe sizes" (compradores não dividem pilha) | FG | pagina | regra de pilha |
| R15 | Lotes de 24h só para item raro; leilões curtos para venda rápida: "Short auctions for fast sellers, 24 hours only for rare items." | MM | pagina | sem fonte |

Recomendações de profissão (MM e LF): mineração e herborismo são "the strongest gold professions while you level" (LF). Couro médio "sells in volume" (LF). Barras: "among the fastest sellers on the beta auction houses" (LF). Essas são do beta.

---

## 6. Lista final de fontes candidatas para aprovação do dono (ordem de qualidade)

1. **warcraft.wiki.gg, "Auction House"** (`https://warcraft.wiki.gg/wiki/Auction_House`, editado em 2026-09-29). Cobre: corte de 5% para todas as casas, depósito 15/30/60% do valor de vendedor para 12/24/48h, mínimo de 1 prata, regra de commodity (Patch 9.2.7). É retail e não diz nada específico do Forever. Uso: mecanismo base, a confirmar no jogo.
2. **Fórum oficial, tópico do depósito** (`https://eu.forums.blizzard.com/en/wow/t/auction-house-deposit-fee-not-changed-even-though-patch-notes-says-so/641712`, 2026-11-11). Cobre: o depósito ainda mostra 1 prata após a nota de 10 de novembro. Sem resposta da Blizzard. Uso: relato de estado, não de regra.
4. **theforeverguides.com, guia do leilão** (`https://theforeverguides.com/gold-making/auction-house/`, site atualizado em 2026-11-05). Cobre: um leilão por ruleset, facção e região; marcações de beta, Classic e não confirmado com honestidade. Uso: principal guia de mecanismo.
5. **mmonster.co, guia de ouro do Forever** (`https://mmonster.co/wow-forever/guides/gold`, 2026-11-05, build beta 70888). Cobre: recomendações de tempo, preço do beta, Mercado Negro com teto de 50g, decaimento de materiais. Uso: fonte das recomendações R1-R6 e R15, com cuidado (beta).
6. **FORUM-2020, Naxx Consumes** (Classic, 2020-12-05). Anedota de consumíveis de raide, sem dados. Uso: contexto de demanda, não fato.
7. **TheGamer, Kobek, 2020-06-20** (Classic). Dado reportado da queda de Lótus Negro de 87% após mudança de spawn. Uso: caso de choque de oferta, marcado como reportado.
8. **foreverwisp.com, bug do depósito** (`https://www.foreverwisp.com/guides/wow-forever-auction-house-deposit-bug`, revisado 2026-11-11). Cobre: relato de depósito mostrado diferente do cobrado (beta, setembro). Uso: risco de depósito.
9. **u4n.com, guia de commodities** (`https://www.u4n.com/news/wow-forever-auction-house-guide-commodities-auctionator-and-why-undercutting-has-changed.html`, 2026-10-05 / 2026-11-16). Cobre: comando x equipamento, undercut em comandos. Interesse comercial declarado pelo próprio texto (vende ouro).
10. **lfcarry.com, guia de economia** (`https://lfcarry.com/guides/wow-forever-gold-economy`, 2026-11-07). Cobre: mercado da primeira semana e profissões. Vende ouro e boost.
11. **almarsguides.com, fases Classic** (`https://almarsguides.com/wow/farming/classic/auctionhouse/`). Cobre: ciclo semanal e demanda de resistência em Classic, sem dados e sem versão nomeada. Uso: só como hipótese a testar.
12. **undermine.exchange, API** (`https://undermine.exchange/api.html`). Cobre: histórico horário de 14 dias, só retail. Uso: não serve ao Forever, mas mostra o formato de coleta (snapshot horário, pode falhar em manutenção).

Fontes de busca não abertas (só o resumo): ConquestCapped (guia com correção de 15 de novembro), space4games (depósito 1 cobre), iggm (depósito, 17 de novembro), warcraftmaps, loreforeverwow.com. Não entram na lista porque não as abri.

---

## Incógnitas (e como conferir no jogo)

1. **Depósito mínimo: 1 prata ou 1 cobre?** Notas de 10/11 dizem 1 cobre "with realm restarts"; relatos de 11/11 dizem que ainda cobra 1 prata; o adiamento para a manutenção semanal de 17/11 (NA) e 18/11 (EU) é citado por fontes de busca.
2. **Corte real de casa neutra e de casa de facção.** 5% (MM, FG) não é confirmado pela Blizzard para o Forever. Neutra 15% é de guia. A correção de 15/11 diz que as casas de capital são entre facções. Conferir: postar o mesmo item na casa de facção e na neutra e comparar o valor do correio.
3. **Duração e depósito.** Confirmar se o Forever tem 12, 24 e 48 horas (FG: "one September beta guide still lists 2, 8 or 24"). Conferir na aba Vender trocando a duração e lendo o depósito.
4. **Ciclo por hora e por dia da semana.** Sem fonte medida. Medir por 2 a 3 semanas, separando por hora e por dia; comparar a mediana do menor preço.
5. **Queda de preço de materiais na primeira semana (40% a 70% em 2 semanas, do beta).** Conferir no próprio reino: anotar o menor preço de 10 materiais de coleta por dia, a partir de 04/11, e comparar com a curva de MM.
6. **Data da primeira raide e o choque de consumíveis.** Não há data publicada no que li (wowforevertierlist.com: não publicada; um site cita 2026-12-09, sem confirmação). Conferir: a aba de raide no jogo (Raid Info) e, quando abrir, acompanhar o preço de flask e de resistência 7 dias antes e 3 dias depois.
7. **Teto de 50g do Lótus Negro e do Cristal Arcano no Mercado Negro (Mister Graphed, Powderfuse Port).** Duas fontes de guia (MM, LF) dizem 50g; não achei a tabela no addon (busca por Black Lotus em VendorListsData não deu linha). Conferir: falar com o vendedor no jogo, sem comprar.
8. **Materiais raros ("Scarce"; Pristine Leather, Frilled Lichen, Pyrite).** As fontes dizem que as origens não foram confirmadas. Conferir: tooltip do item e a lista de fontes do addon; medir a oferta de lotes por dia.
9. **Commodity ou item para materiais.** U4N diz que materiais e consumíveis são comprados por quantidade. Conferir: `C_AuctionHouse.GetItemCommodityStatus` num material.

---

## Desvios e bloqueios

- Não achei nenhuma fonte com números de preço de leilão no lançamento do Classic (2019) nem da Season of Discovery. Dot Esports (SoD) deu 403. A busca de r/woweconomy e de r/classicwow não trouxe thread com dados. Registro de "não achei".
- Bloqueios 403 ou 502: dotesports.com (SoD), icy-veins.com (depósito), massivelyop.com (depósito, 2026-11-11), epiccarry.com (guia de ouro), reddit.rtrace.io (r/woweconomy, 502). Não contornei. Wowhead e CurseForge não foram tentados.
- warcrafttavern.com redirecionou para barrens.chat (outro host, fora da lista do brief). Não segui. A ficha de preço de materiais de pré-lançamento (2019) fica como não lida.
- O mmonster diz "Values from the Forever game client" para o corte de 5% e 15%. Procurei no jogo: o único valor é o do addon de terceiros. Não há o valor no cliente. Marquei como incógnita, não como fato do cliente.
- Blizzard: as duas notícias oficiais linkadas pela U4N (`https://worldofwarcraft.blizzard.com/en-us/news/24301145` e `.../24304160`) não têm conteúdo de leilão (lidas 2026-11-16). A nota oficial de 10/11 não foi aberta; a informação do depósito vem de terceiros.
- Vídeos: nenhum lido. O brief pedia só vídeo com descrição lida; não entrou nenhum.
- Mantive as recomendações do beta com a marca "pagina" e a observação "beta". Não transformei nenhuma em regra de design.

---

## Incógnitas resumidas

As incógnitas estão na seção Incógnitas acima, cada uma com o jeito de conferir no jogo.
