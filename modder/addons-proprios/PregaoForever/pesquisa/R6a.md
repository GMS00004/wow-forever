> Relatório de pesquisa de 2026-11-16, da onda 1 do design do PregaoForever, gravado como estava (foto do dia). `<espelho>`, `<dados>` e `<tmp>` eram pastas temporárias da sessão; o Apêndice D do `DESIGN.md` diz como refazê-las. Onde este relatório e o `DESIGN.md` divergem, vale o `DESIGN.md`.

# R6a: TradeSkillMaster, addons de leilão e de contabilidade no WoW Forever

Data das leituras: 2026-11-16. Cliente de referência do brief: 1.60.1, Interface 16001, tipo camelot.
Marcas: local = lido nesta máquina; pagina = página ou arquivo remoto aberto (URL e data); busca = só resumo de busca, página não aberta; inferencia = conclusão minha.
Nada foi lido na pasta do jogo nem nas pastas do projeto: nesta pesquisa não há fato de marca local.

---

## 1. TradeSkillMaster e o Forever

| Fato | Fonte | Data | Marca | Confiança |
|---|---|---|---|---|
| O post oficial da TSM diz: "We can confirm that the major 4.15 update does support WoW: Forever", e usável "from launch day on November 4th". | https://tradeskillmaster.com/news/tsm-4-15-brings-wow-forever-support-plus-new-desktop-app-1180 (cabeçalho "Sunday, November 1st 2026") | lido 2026-11-16 | pagina | alta |
| O mesmo post diz que o 4.15 entrou em beta na data do post e que a versão final sairia junto com o lançamento do Forever. O post não cita número de interface. | mesma URL | lido 2026-11-16 | pagina | alta |
| O post anuncia o novo app de desktop da TSM (Windows, Mac, Linux). Ele NÃO confirma explicitamente a cobertura de dados de preço de leilão do Forever. | mesma URL | lido 2026-11-16 | pagina | alta (ausência) |
| Página de compatibilidade (Foreverbase) diz "Yes, TradeSkillMaster works in WoW Forever", versão "v4.15.3, released Nov 5, 2026", e que a arquivo Forever tem interface 16001 (não o Classic). Diz também que os preços de mercado vêm do app TSM Desktop; sem ele, o addon usa só as varreduras do próprio jogador. | https://foreverbase.org/en/addons/catalog/tsm/ | lido 2026-11-16 (página datada de 5 Nov) | pagina | média |
| Página wowcalc marca TSM como "Not verified" e diz "There is no Forever version of TradeSkillMaster yet" (verificado em 29 Oct). Está DESATUALIZADA frente ao post oficial de 1 Nov e à página de 5 Nov. O app de preços ("The TSM Desktop App ... its free tier covers 10 realms") aparece aqui. | https://wowcalc.net/en/forever/wiki/addons/tradeskillmaster | lido 2026-11-16 | pagina | baixa (desatualizada) |
| Páginas de 'Oct 2026' dizendo que a TSM não tem build Forever (wowforevertierlist, forevermastery etc.) são anteriores ao lançamento e ao 4.15. | busca (resumos) | 2026-11-16 | busca | baixa |

Veredito: há anúncio oficial da TSM (site) de suporte ao Forever, a partir do 4.15. Não há recusa oficial. Não achei a página de CurseForge da TSM (404 em WebFetch) e não li o TOC da TSM (sem repositório público achado; a TSM não aparece no GitHub pelo gh com TOC lido).

Cobertura de dados de preço no Forever: o post oficial não confirma. Os terceiros (Foreverbase) dizem que o preço vem do app TSM Desktop, sem dizer se o servidor do Forever está coberto por ele. Tratar como **não confirmado**.

---

## 2. Addons com build para o Forever (uma linha por addon pedido)

Colunas: TOC (Interface) / Versão e data / Download / Licença / Notas. Quando não há TOC lido, o campo diz isso.

### 2.1 Auctionator (principal)
- TOC: não lido. Repositório `Auctionator/Auctionator` retorna 404 no gh e no WebFetch, e não aparece entre os repositórios públicos da org `Auctionator`. O TOC não pôde ser conferido.
- CurseForge (pagina, lido 2026-11-16, https://www.curseforge.com/wow/addons/auctionator): arquivo id 9620638 com flavor "Forever + 5", data 14 Nov 2026; interface não mostrada; licença "All Rights Reserved"; o site diz que não há link de repositório (só wiki do GitHub).
- Busca (não aberta): um desenvolvedor afirma build Forever desde 21 Set; uma página de 16 Set (wowforeverbuilds.com, pagina lido 2026-11-16) diz "Forever support not confirmed" — desatualizada.
- Varredura: busca (resumo): "a full scan is throttled for more than 162 seconds and then returns an empty market instead of an error" — não aberto; origem: desenvolvedor não identificado.
- Issues de Forever, de desconexão ou de throttle: não consultadas (sem repositório público).

### 2.2 Journalator (contabilidade de vendas e compras)
- TOC: https://github.com/Auctionator/Journalator, arquivo `Journalator/Journalator.toc`, lido 2026-11-16 via gh: `## Interface: 120100, 16001, 50504, 38000, 20505, 11509`. Declara 16001 (e o tipo camelot não aparece no TOC).
- Commits "Forever: Update toc" em 2026-10-02 (gh commits).
- CurseForge (pagina): versão 12.1.0, 19 Oct 2026; flavor "WoW Forever" listado; licença MIT.
- Download: CurseForge (https://www.curseforge.com/wow/addons/journalator) e GitHub (releases).
- Issues abertas: #128 "Not supporting wow forever" (27 Set, aberta), #131 "Incompatible with WoW Forever" (10 Out, aberta). Comentário na #131 (usuário, 2026-11): "It's working for me in Forever, except it doesn't seem to track received mail, only sent." (pagina, não verificado).
- Função: registra vendas, postagens, compras, correio, etc.; exporta CSV (CurseForge, pagina).

### 2.3 Point Blank Sniper
- TOC: https://github.com/Auctionator/PointBlankSniper, arquivo `PointBlankSniper.toc`, lido 2026-11-16: `## Interface: 120100, 120105, 50503, 16001`. Depende de Auctionator (`RequiredDeps: Auctionator`); opcional TheUndermineJournal, OribosExchange.
- CurseForge (pagina): versão 12.1.5, 14 Oct 2026; flavor Forever listado; licença MIT.
- Descrição (pagina, CurseForge): "Sniper tool that scans the entire AH for a lot of different items (1k+) very quickly", "a full scan takes within 30 seconds on most realms" (afirmação do autor); "Limited support and updates".
- Issues: 24 abertas, nenhuma marcada como Forever (lido 2026-11-16 via gh).

### 2.4 Collectionator
- TOC: https://github.com/TheMouseNest/Collectionator, arquivo `Collectionator.toc`, lido 2026-11-16: `## Interface: 120105, 50504, 16001`; `RequiredDeps: Auctionator`.
- Último commit: 2026-11-08. Licença: MIT (LICENSE, 2020-2022 plusmouse).
- Descrição (README/repo, pagina): aba "Collecting" no leilão para navegar transmogs, mounts, pets, brinquedos e receitas não coletados em todos os alts.
- CurseForge: não lido. Releases: não listadas no gh.

### 2.5 Auctioneer (Auctioneer Suite)
- TOC: não lido. Não achei repositório público (gh search "Auctioneer Suite" e "auctioneer" não trazem a versão Forever; o repositório Norganna/Auctioneer retorna 404).
- CurseForge (pagina, https://www.curseforge.com/wow/addons/auctioneer-forever, lido 2026-11-16): "A comprehensive auction house addon for Forever", arquivo "Auctioneer Suite 4.0.7" (id 9642341), flavor Forever, game version 1.60.1, data 16 Nov 2026 (hoje); descrição cita escaneamento de mercado, análise de preço, automação de postagem e controle de inventário; licença GPLv2; sem link de repositório.

### 2.6 Aux (auxForever e o original)
- Original `shirsig/aux-addon` (gh, pagina): TOC `## Interface: 11508` (Classic Era). NÃO é build Forever.
- auxForever (`TylerHampton/aux-forever`), TOC `auxForever/auxForever.toc` lido 2026-11-16 via gh: `## Interface: 16001`, `## Version: forever-0.8.2`, autor shirsig, "re-imagined by a fan".
- Releases (gh release list, 2026-11-16): 0.8.2 em 10 Nov 2026 (pre-release no GitHub); CurseForge (pagina, https://www.curseforge.com/wow/addons/auxforever): "auxForever 0.8.2", flavour Forever, data Nov 10 2026, marcado "Latest release".
- Licença: CurseForge diz "All Rights Reserved". README do repo (pagina) diz que a licença MIT cobre só as mudanças; o código original do aux não tem arquivo de licença e o autor autorizou por e-mail ("you can feel free to use it, work on it and distribute it in any way you please"). Conflito entre as duas fontes.
- Download: CurseForge ou Releases do GitHub.
- Varredura: a documentação do repo (docs/forever-auction-house.md) é a fonte mais detalhada sobre o leilão do Forever (ver seção 3).

### 2.7 OribosExchange (preço de leilão em tooltip)
- TOC: https://github.com/ZiiMs/OribosExchange-Forever, arquivo `OribosExchange/OribosExchange.toc` lido 2026-11-16: `## Interface: 16001`; `## Version: 1.3.20261106-forever2.20261116044228`; notas: "WoW Forever edition, data from undermine.exchange ... Monday, November 9th, 2026"; autor Erorus (port Forever por ZiiMs); OptionalDeps Auctionator, AuctionLite, LibExtraTip.
- Repo atualizado 2026-11-12. Licença: LICENSE na raiz é LGPL-3.0 e há também LICENSE-GPL-3.0 (pagina; conferido nos arquivos).
- Problema de dados: issue #6 aberta em 2026-11-11: "Please do not scrape data from the `undermine.exchange/data/` path" (pagina, gh issue view).

### 2.8 CraftSim (custo de produção)
- CurseForge (pagina, https://www.curseforge.com/wow/addons/craftsim): versão 27.0.7 (Sep 28, 2026), flavor Retail (só Retail listado; "+18 versions" não detalhadas), licença MIT. Forever não aparece.
- TOC do repo (`derfloh205/CraftSim`, `CraftSim.toc`, lido 2026-11-16): `## Interface: 120005, 120007, 120100, 120105, 120150`; versão 27.0.8 no master. NÃO declara 16001.
- Conclusão: NÃO achei build Forever do CraftSim.
- Alternativas de custo de produção com Forever declarado: ProfitCraft (`hnatapeto/ProfitCraft`, TOC `## Interface: 16001, 120105`, versão 0.10.1, lido 2026-11-16; usa preços de TSM / Auc-Advanced / Auctionator; repo sem licença declarada; push 2026-11-15) e Dwarf Explorer's Bible (`masterred92/DwarfExplorersBible`, TOC `## Interface: 16001`, versão 1.1.0, MIT, push 2026-11-12; mostra o que um material vira, com preços de leilão).

### 2.9 LibAHTab
- TOC: https://github.com/TheMouseNest/LibAHTab, `LibAHTab.toc` lido 2026-11-16: `## Interface: 100000` (retail 10.0.0). NÃO declara 16001. Último commit 2026-11-04.
- O ForeverFlip (pagina, README) lista LibAHTab como dependência opcional "that puts the tab next to other addon tabs" e não exige. CurseForge do LibAHTab não lido.

### 2.10 Novos e nativos do Forever relacionados a leilão, flipping, sniper e ouro (achados na busca no GitHub)
Não achei nenhum addon "nativo do Forever" da Blizzard para sniper ou flipping: as ferramentas são de terceiros. Os achados mais relevantes:

- **ForeverFlip** (`Danissemo/ForeverFlip`, MIT, pagina lido 2026-11-16). TOC `ForeverFlip/ForeverFlip.toc`: `## Interface: 16001`, versão 2.3.0-beta.1; release beta de 15 Nov 2026. Faz varredura completa, sniper, deals (vendor e resale), posting, cancel de undercut, contabilidade e análise, com a regra "ForeverFlip never trades on its own" (README). Documento técnico em docs/how-it-works.md (copiado para o scratch, lido via Grep e Read). É o concorrente mais próximo do design do dono.
- **Forged Forever Auction House** (`chromag316/Forged_ForeverAuctionHouse`, pagina lido 2026-11-16): TOC `Interface: 16001`, versão 0.8.0, repo atualizado 2026-11-12; módulos FullScan, Market, Ledger, Strategy; sem licença lida.
- **AuctionHouse Forever** (CurseForge, pagina, https://www.curseforge.com/wow/addons/auctionhouse-forever): versão auctionhouse-v2.4.4-forever, flavour Forever, 17 Oct 2026; scan 15 min com contagem regressiva; MIT; repo `severd8/auctionhouseforever`; aviso "HEAVY DEVELOPMENT IN PROGRESS".
- **Price Scanner Forever** (CurseForge, pagina, https://www.curseforge.com/wow/addons/price-scanner-forever): versão 1.0.9, 14 Nov 2026, flavour Forever, beta; escaneia só no clique; não compra nem posta; licença "All Rights Reserved"; sem repo.
- **AHledger** (`DeepCapt/ahledger-sync`, README, pagina): addon que lê o leilão pela API que a Blizzard dá a todos os addons (a mesma usada por Auctionator e TSM); o app de sincronização envia varreduras para api.ahledger.com e baixa tabelas de preço a cada 30 min. Não lido o TOC do addon.
- **ForeverAuctionator** (`Flurry2005/ForeverAuctionator-Releases`, README de 2 linhas, pagina): "the WoW: Forever auction house addon and companion app". Sem TOC lido.
- **Blizzard Game Data API para o Forever** (`RuslanMunasipov/quest-murder-prices`, README, pagina): fonte "the Blizzard Game Data API (World of Warcraft Forever auction houses), read about once an hour"; a API dá listagens, não vendas (afirmação do autor).
- Outros achados sem leitura de TOC: AuctionMin Forever (warperia, busca), Companion (BootyBayBroker, busca), ForeverMarket (ShadowHexYT, busca), Mr-Dangles/AHPriceTracker (busca no gh, sem TOC).
- WOW4E_AH_Trader (`1nd1v1d/WOW4E_AH_Trader`): TOC `Interface: 11200`, não Forever. TWOW AH Trader (no mesmo repo): `Interface: 11200`, não Forever.

---

## 3. O que a página do Forever Guide descreve sobre a varredura de leilão

Há duas páginas que podem ser o "Forever Guide". Li as duas e nenhuma descreve o mecanismo de varredura em detalhe:

- https://theforeverguides.com/gold-making/auction-house/ (lido 2026-11-16; "Site updated 5 Nov 2026"): não descreve varredura. Diz que os preços vêm de varreduras que os jogadores enviam com addon ("Each builds prices from scans that players upload with an addon, so treat early numbers as thin"); diz "Pick one scanner to start. Auctionator is the lightest."; e, não confirmado, "Addon developers report Forever uses the modern AH window, not the Classic one, so older Classic auction addons may break".
- https://wowforeverguides.com/addons/developers (lido 2026-11-16; publicada 27 Set, atualizada 11 Nov): é o guia de desenvolvedores de addons. Diz Interface 16001 (para a beta, "reported"), tipo camelot, uso da família de API Mainline, e lançamento em 4 Nov 2026. Não menciona C_AuctionHouse nem varredura completa. Diz também que COMBAT_LOG_EVENT_UNFILTERED não está disponível aos addons no Forever e que WOW_PROJECT_ID é 18 no build 70338.

Quem descreve a varredura em detalhe é a documentação de terceiros, de dois addons (auxForever e ForeverFlip). Estes fatos são de autores de addon e não são da Blizzard. Ver as seções 3.1 e 3.2.

### 3.1 auxForever (docs/forever-auction-house.md, pagina, https://github.com/TylerHampton/aux-forever, lido 2026-11-16)
- Rotas: "Full scan (`ReplicateItems`) works: whole house in one go, one row per auction ... [Seen]" (marca do autor: vista no jogo).
- "Full scan allowed once every 15 minutes per account. [Outside] (retail's rule ...) ... the real limit on Forever has never been tried. [Unknown]".
- Pesquisa por item: "item searches about one every 0.4 seconds because of the game's request limit (`IsThrottledMessageSystemReady`), 335 items in 3m 13s".
- "Full scan time since launch: one player saw more than 5 minutes before the list arrived ... [Outside]"; aux passou a esperar até 10 min (versão 0.8.2).
- Do README: "To get good prices in tooltips and recipe costs, run a Full scan ... on each visit to the auction house."

### 3.2 ForeverFlip (docs/how-it-works.md, pagina, lido 2026-11-16)
- "`C_AuctionHouse.ReplicateItems` returns every auction of the house. The server allows this once per 15 minutes per account (`S.COOLDOWN = 900`)."
- "WoW Forever does not always send `REPLICATE_ITEM_LIST_UPDATE`, so the job also polls the number of replicated auctions once a second." "Since launch the answer can take minutes, so the job waits up to 10 minutes."
- "(seen in game: three unanswered calls in a row, each sooner than 15 minutes after the one before)" e "the server counts its 15 minutes from every call, answered or not" — alegação do autor, sem prova externa.
- Fila de itens: "the item data is requested up to 100 items every 0.1 seconds while fewer than 400 are unanswered".
- Browse: "7718 items took 8.5 seconds over 16 requests".
- Limite de busca exata: "one exact search at a time with pacing, at most 100 per minute".
- "A full scan on a busy realm returns more than 200 000 auctions."

Marca de todos os itens da seção 3.2: pagina (autor afirma ter visto no jogo; não verificado por mim).

---

## Incógnitas

1. Build e TOC do Auctionator no Forever (repo não público; só CurseForge com flavor "Forever + 5" e interface não mostrada). Como conferir: `/dump select(4, GetBuildInfo())` no jogo e ler a pasta `Interface/AddOns/Auctionator/Auctionator.toc` depois de instalar o arquivo do CurseForge.
2. Cobertura de preço da TSM no reino do dono: o app TSM Desktop cobre o Forever? Quantos reinos? Como conferir: instalar a TSM Forever, abrir o TSM Desktop e ver se o reino aparece com dados.
3. Limite de 15 min por conta: o servidor do Forever aplica mesmo, e uma chamada recusada conta para a janela? Só ForeverFlip e aux afirmam. Como conferir: rodar uma varredura completa e uma segunda em menos de 15 min, e ver a mensagem.
4. Tempo real da resposta da varredura completa no Forever (de segundos a 10 min?). Como conferir: `/ff diag` (ForeverFlip) ou o log de tempo do auxForever 0.8.2.
5. Build exato do cliente de referência: o brief diz 1.60.1 build 70938; o aux-forever cita build 70338; o wowcalc e a Quest Murder Gold citam 1.60.1.70888. Como conferir: `/run print(select(2, GetBuildInfo()), select(4, GetBuildInfo()))` no jogo.
6. Se o último a entrar vende primeiro no mesmo preço (no Forever: incógnita, aux E6). Como conferir: experimento com duas contas, como descrito no docs do aux-forever.
7. Se a Blizzard permite confirmação de compra de commodity sem clique (incógnita no aux-forever). Como conferir: testar com um addon de teste de leitura, sem automatizar a compra.

---

## Desvios

- O brief pede a "página do Forever Guide" no singular; não estava claro qual. Li theforeverguides.com (gold-making/auction-house) e wowforeverguides.com (addons/developers). Nenhuma descreve a varredura em detalhe. A descrição detalhada veio da documentação de dois addons (aux-forever e ForeverFlip).
- O build de referência do brief (70938) não aparece em nenhuma fonte que li; as fontes dão 70338, 70888 e 1.60.1 sem build.
- Não li o TOC da TSM nem de Auctioneer (sem repositório público achado).
- Não li a pasta do jogo nem as pastas do projeto. Não há fato marcado como local nesta pesquisa.
- Não abri as páginas de busca (resumos) de terceiros; os fatos marcados busca não foram usados em nenhuma conclusão de design.
- Fora do escopo, uma linha: o Quest Murder Gold lê o leilão do Forever pela Blizzard Game Data API (listagens, não vendas) e a documentação do aux-forever diz que o Forever usa a janela de leilão moderna, o que pode quebrar addons de Classic.
