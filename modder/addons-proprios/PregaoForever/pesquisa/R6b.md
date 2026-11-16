> Relatório de pesquisa de 2026-11-16, da onda 1 do design do PregaoForever, gravado como estava (foto do dia). `<espelho>`, `<dados>` e `<tmp>` eram pastas temporárias da sessão; o Apêndice D do `DESIGN.md` diz como refazê-las. Onde este relatório e o `DESIGN.md` divergem, vale o `DESIGN.md`.

# R6b: fontes externas de preço, companheiros e punições (WoW Forever)

Data da pesquisa: 2026-11-16. Nenhuma autenticação. Nada escrito fora deste relatório e da pasta de temporários. Os scripts .ps1 do projeto não foram rodados. O jogo não foi tocado.

Legenda de marcas: `local` = lido nesta máquina; `pagina` = página ou arquivo remoto aberto (URL e data); `busca` = só resumo de busca; `inferencia` = conclusão minha.

Observação de método: "Forever" saiu em 2026-11-04. Nenhum fato do Forever abaixo vem de memória. Quando a fonte é de retail ou de Classic, está marcado.

---

## 1. Sites e APIs de terceiros com preço ou histórico de leilão

### 1.1 Quem cobre o Forever e de onde vem o dado

| Fonte | O que cobre | Origem do dado (o que a página diz) | Termos / atribuição | Marca |
|---|---|---|---|---|
| auctionhouse.fyi (`https://auctionhouse.fyi/docs/api`, lido 2026-11-16) | Forever, 6 mercados (Normal e PvP/RP, Alliance e Horde) | "WoW: Forever has no auction house API, so the prices here come from player-sourced uploads." Upload pelo addon gratuito e app de desktop. Base `https://auctionhouse.fyi/api/v1`. Leitura pública sem chave. | Sem termos nem licença na página. Rate limit "not stated". "Not affiliated with Blizzard Entertainment." | pagina |
| TheWoWDB (`https://thewowdb.com/`, lido 2026-11-16) | Forever, Retail, MoP (Classic Era/TBC/WotLK: "No Auction House prices yet: Blizzard publishes no auction data for this client.") | Forever: "Blizzard's own Forever auction data covers every Blizzard auction house and TheWoWDB reads it hourly." Casas fora desse feed vêm de upload de jogadores via addon. | "We are not affiliated with Blizzard", "unaffiliated fan project". Preços podem atrasar; "always verify in game". | pagina |
| forevermastery (`https://forevermastery.com/en/prices`, lido 2026-11-16) | Forever | "Blizzard's API publishes every WoW Forever auction house every hour." Fonte mostrada: "Blizzard API + 1 player". Última atualização na página: 2026-11-16 04:58 UTC. | "This fan site is not affiliated with or endorsed by Blizzard." Scans de jogador guardados 3 dias. | pagina |
| wowauctions.net (`https://www.wowauctions.net/auctionHouse/forever-us`, lido 2026-11-16) | Forever US, 8 realms | "Blizzard's official auction data, not from addon scans." "updated every hour". Sem data absoluta. | "Not affiliated with Blizzard Entertainment." Sem página de termos aberta. | pagina |
| Undermine Exchange (`https://undermine.exchange/api.html`, lido 2026-11-16) | Só Retail: "covering all items on all realms for the latest version of World of Warcraft (Retail, not Classic)." Forever não é citado. | Snapshots "roughly hourly, but it's not guaranteed". Fonte: API Community da Blizzard. | Sem licença/atribuição declarada. "WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND". Chave ligada ao Patreon. Limite: "sliding window of 3,000 points per hour"; endpoints custam 1 a 5 pontos. | pagina |
| TSM Public Web API (`https://support.tradeskillmaster.com/api-documentation/tsm-public-web-api`, lido 2026-11-16; artigo "Updated at July 5th, 2026") | Não diz; o artigo traz CSV em public-data.tradeskillmaster.com. Forever não é citado. | "TSM publishes pricing data as plain CSV files". | "The files are static and public with no API key, sign-in, or rate limits." Sem termos. | pagina |
| Saddlebag Exchange (addon, CurseForge, busca) | Retail (não verificado para Forever) | Addon gera JSON "for our bot and website functions. You open your Auctions tab so the data populates, then copy the JSON to the website or the Discord bot." | Repositório `ff14-advanced-market-search/SaddlebagExchangeWoW`, último commit 2026-10-15 (`gh api`, pagina). | busca (descrição) + pagina (README via gh) |
| ahprice / AZPC / Playfulls / wow-forever.gg / Blackwater Exchange / timesaver.gg | Forever (listados em busca) | Não abertos individualmente; a busca diz que ahprice e AZPC são addons que alimentam preços a partir de scans próprios. | Não verificado. | busca |
| NexusHub, wowauctions (Classic), saddlebag site | Classic (busca) | Não verificado se cobrem Forever. | Não verificado. | busca (não encontrado para Forever) |

Leitura: há dois relatos incompatíveis. auctionhouse.fyi afirma que Forever não tem API de leilão. wowauctions.net, forevermastery e TheWoWDB afirmam que a Blizzard publica o leilão do Forever por hora. A fonte da Blizzard não pôde ser aberta (ver seção 2). Isso fica como incógnita.

### 1.2 Termos da Blizzard para dado de API

| Afirmação | Evidência | Marca | Confiança |
|---|---|---|---|
| Os termos da API de desenvolvedor proíbem data mining, scraping, crawling e consultas automatizadas, exceto as autorizadas pelas APIs. | Trecho citado num post do fórum da Blizzard (`https://us.forums.blizzard.com/en/blizzard/t/confusion-on-terminology-surrounding-automation/44564`), resultado de busca, não aberto. | busca | média-baixa (o texto oficial não foi aberto) |
| A seção 2(b) proíbe cobrar prêmio por app que usa a API. | `https://us.forums.blizzard.com/en/blizzard/t/can-i-add-value-for-my-paid-community/14212`, resumo de busca. | busca | média-baixa |
| Exige conta Battle.net com autenticador e aceite dos termos. | Resumo de busca de vários fóruns. | busca | média |

---

## 2. A API oficial da Blizzard (Game Data API) para leilão do Forever

### 2.1 O que a própria Blizzard publica para o Forever (interface)

O repositório `Gethe/wow-ui-source`, branch `forever`, cujo último commit é `1.60.1 (70938)` de 2026-11-13 (`gh api repos/Gethe/wow-ui-source/commits?sha=forever`, pagina), contém a documentação gerada de API que a interface do cliente usa. Essa build é a mesma citada no brief.

| Fato | Evidência | Marca | Confiança |
|---|---|---|---|
| A documentação do beta de build 70938 define o namespace `C_AuctionHouse` com `Environment = "All"`. | `Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua`, linhas 1 a 10, branch forever (`https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua`). | pagina | alta |
| Funções de compra e venda com `HasRestrictions = true` e `SecretArguments = "AllowedWhenUntainted"`: `PlaceBid` (linha 852), `PostCommodity` (864), `PostItem` (883), `ConfirmPostCommodity` (94), `ConfirmPostItem` (108), `StartCommoditiesPurchase` (1079), `CancelAuction` (60). `ConfirmCommoditiesPurchase` (83) tem só `SecretArguments`. | Mesmo arquivo. | pagina | alta |
| Eventos de throttle de mensagem do leilão: `AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED`, `_QUEUED`, `_RESPONSE_RECEIVED`, `_SENT`, `_SYSTEM_READY`, e a função `C_AuctionHouse.IsThrottledMessageSystemReady` (retorna `canSendThrottledMessage`). | Mesmo arquivo, linhas 825 a 830 e 1284 a 1310. | pagina | alta (existência); média (finalidade, que é inferida pelo nome) |
| Existe `C_AuctionHouse.SupportsCopperValues` (retorna bool). | Mesmo arquivo, linha 1091 a 1096. | pagina | alta (existência) |
| Não há tag de hardware event no documento gerado. A restrição de hardware event está só na wiki (ver seção 4). | Busca por "hardware" no arquivo: zero resultados. | pagina | alta |

Inferência: o documento de build 70938 traz as mesmas flags de restrição que a wiki atribui a `PlaceBid` e `StartCommoditiesPurchase`, mas a flag de hardware event não aparece nele. Não dá para confirmar pelo documento se o Forever aplica hardware event a essas funções.

### 2.2 Endpoint de leilão do Forever (comunidade, não Blizzard)

| Fato | Evidência | Marca | Confiança |
|---|---|---|---|
| Blizzard não documenta a API do Forever ainda. | Post de 2026-11-05 no fórum: "Since the Forever API isn't documented yet" (`https://us.forums.blizzard.com/en/blizzard/t/wow-forever-api-what-works-so-far-plus-a-ts-client/60334`). | pagina (post de jogador) | média |
| Leilões "live as of today (Nov 6)". Rotas por ruleset: `/data/wow/ruleset/{id}/auctions/` (com barra final; sem barra dá 404), e depois uma rota por casa e por commodities. Casas 110 a 121 e 123 a 125. | Mesmo post, de 2026-11-06. | pagina (post de jogador) | média-baixa |
| Namespaces que funcionam: `static-forever-{region}`, `dynamic-forever-{region}`, `profile-forever-{region}` e `static-1.60.1_70399-forever-{region}`. Regiões US, EU, KR e TW. | Mesmo post. | pagina (post de jogador) | média-baixa |
| Retorna 404: índice de realms, `/data/wow/auctions/commodities` (rota antiga), ruleset 999. Casas 112, 115 e 118 vêm sem campo `auctions`. | Mesmo post. | pagina (post de jogador) | média-baixa |
| O endpoint de itens da casa do Forever dá 404 para 652 de 1.515 IDs numa casa da Aliança da UE. | Mesmo post. | pagina (post de jogador) | baixa (um caso) |
| Repositório de SDK e PR de terceiros confirmam namespaces e rulesets (não verificados). | `https://github.com/Everloot/everloot/pull/867`, `https://github.com/SideQuest-Guild/wow-forever-sdk`, `https://github.com/jkc-be/goldbook/issues/67`. | busca | baixa |

Issue #67 do goldbook (aberta 2026-10-28, fechada pelo dono em 2026-11-06 com checklist não marcado) diz: "This issue is blocked until a Forever namespace exists **and** its auction endpoint returns listings." O dono escreveu em 2026-11-06 que o relato da comunidade "was written by an unofficial source" e "nothing in it is official" (`https://github.com/jkc-be/goldbook/issues/67`, pagina).

Cadência e limite de taxa do endpoint do Forever: não encontrados. As regras gerais de cadência e limite do endpoint de leilão da Blizzard para Retail e Classic também não foram abertas (ver seção de incógnitas).

### 2.3 Tentativa na documentação oficial do portal

`https://community.developer.battle.net/documentation/world-of-warcraft/auction-house-api` é uma casca JavaScript: a página não traz o conteúdo. `https://community.developer.battle.net/documentation/world-of-warcraft` deu o mesmo resultado. Não foi possível ler a documentação oficial dos endpoints de leilão, nem o namespace nem a frequência. Registro: não achei documentação oficial de leilão do Forever com as buscas feitas.

---

## 3. Aplicativos companheiros e como trocam dados com o jogo

| Aplicativo | O que a fonte diz | Marca | Confiança |
|---|---|---|---|
| WeakAuras Companion (`https://github.com/WeakAuras/WeakAuras-Companion`, README via `gh api`, lido 2026-11-16) | "The WeakAuras Companion is a cross-platform ... application built to provide the missing link between Wago and the WeakAuras World of Warcraft addon." "Click on 'Fetch Updates', this is also done automatically once every hour." "Restart World of Warcraft or reload your UI. The first time you start WeakAuras Companion, you will have to restart the game for it to be able to load the addon." O README não diz como grava no addon (não há menção a SavedVariables nem a arquivo). | pagina | alta (o que diz); não diz o mecanismo |
| Raider.IO (README do addon via `gh api repos/raiderio/raiderio-addon`, lido 2026-11-16) | O addon diz "keep this data in sync" com o Desktop Client. "Desktop client updates scores 4 times a day" (e outras linhas de 8 vezes por dia). O TOC lista `## Interface: ... 16001 ...` e muitos `SavedVariables` (RaiderIO_Config, RaiderIO_GameData etc.). | pagina | alta (o que diz) |
| Raider.IO: reload depois do cliente | Suporte do Raider.IO: após "Refresh Addon" no cliente, usar `/console reloadui` ou reiniciar o WoW. Resumo de busca de `https://support.raider.io/kb/raider-dot-io-mythic-plus-addon`. | busca | média |
| TSM 4.15 (`https://tradeskillmaster.com/news/tsm-4-15-brings-wow-forever-support-plus-new-desktop-app-1180`, lido 2026-11-16) | "We can confirm that the major 4.15 update does support WoW: Forever." App desktop novo, "rebuilt from the ground up to support Windows, Mac, and Linux." O texto não diz como o app recebe dado do jogo. | pagina | alta (o que diz) |
| TSM AppHelper (busca) | "AppHelper is a companion module to the TradeSkillMaster Desktop Application that allows it to put AuctionDB and other data sources into the game." | busca | média-baixa |
| ForeverSVFix (`https://github.com/nobewayo/ForeverSVFix`, README via `gh api`, lido 2026-11-16) | App de terceiros para restaurar SavedVariables no Forever. Passo: "Close World of Warcraft completely." Depois "start ForeverSVFix -> Apply / Refresh -> Check installation -> close ForeverSVFix -> start WoW". Cria "directory links" que addons podem substituir. "There is no background service or process that needs to remain running." | pagina | alta (o que diz) |
| Blizzard e companheiros | Nenhum texto oficial da Blizzard encontrado sobre companheiros de terceiros no Forever. A regra geral da Blizzard para software de terceiro que modifica o cliente vem de um post de 2025-08-05 de Kaivax, fora do Forever: "The use of third-party software that modifies the World of Warcraft game client is against our Terms of Service." Não cita addons nem AH. | pagina (`https://us.forums.blizzard.com/en/wow/t/prohibitions-on-third-party-software/2142972`) | alta (texto); pré-Forever |

Padrões observados (inferência, com base nas fontes acima): o companheiro grava arquivo na pasta do jogo e pede reload ou reinício (WeakAuras, Raider.IO), ou exige o jogo fechado para fazer a escrita (ForeverSVFix). Nenhuma fonte lida diz que o jogo precisa estar aberto ou fechado durante a escrita do dado de leilão do TSM.

---

## 4. Punição por addon de leilão e por sniper ou macro de roda do mouse

### 4.1 Punições documentadas no Forever (pelo que foi lido)

| Fato | Evidência | Marca | Confiança |
|---|---|---|---|
| Temporary Economy Hold (Kaivax, 2026-10-13): conta suspeita de RMT perde uso de trade, correio, guild bank e Leilão enquanto a checagem roda. "merely having a Temporary Economy Hold will leave no permanent strikes against your account." | `https://us.forums.blizzard.com/en/wow/t/2381433` (texto do post oficial não aberto diretamente; lido via guia que cita o post, `https://www.foreverwisp.com/guides/wow-forever-temporary-economy-hold-trade-mail-auction-house`, 2026-10-15). Post aberto diretamente em 2026-11-16 via WebFetch: "You will have restricted use of trade, mail, guild banks and the Auction House while this economic hold is in place." | pagina | alta |
| Customer Support, 2026-11-10: "For the Auction House normal use is always fine." Gatilhos citados: "selling/buying a cheap item for a lot of gold" e "a price way outside of market value that causes concerns." O post não cita addons, macros, sniping nem automação. | `https://us.forums.blizzard.com/en/wow/t/2409104/61` (aberto diretamente, post #61, 2026-11-10 20:51). | pagina | alta |
| Customer Support, 2026-11-10: contas banidas e depois reativadas foram "false positives. A mistake was made, and it was caught quickly and overturned." Anunciado por resumo de guia que cita o post 2409104/59 (não aberto diretamente). | `https://www.forevermastery.com/en/guides/wow-forever-gold-rules` (tabela com citações). | pagina (secundária) | média |
| Oct 9, 2026 (dev de podcast): Blizzard "closed almost 1,600 gold-selling or botting accounts" no beta. | Mesmo guia (forevermastery). Post oficial não aberto. | pagina (secundária) | média |
| Gold de intermediário tem "an extremely high likelihood" de ser gold comprado (Kaivax, 2026-10-27). | Mesmo guia, citando `https://us.forums.blizzard.com/en/wow/t/2394005/1` (não aberto). | pagina (secundária) | média |

Nenhuma punição documentada no Forever por addon de leilão dentro das regras, nem por sniper de addon, foi encontrada nas fontes lidas. A única menção a punição em conta por AH é a de cheap-item e preço fora de mercado, que é comportamento de venda, não de addon.

### 4.2 Roda do mouse e tecla repetida

| Afirmação | Evidência | Marca | Confiança |
|---|---|---|---|
| Wiki: APIs que exigem hardware event são chamadas de "hwevent": "APIs which require a hardware event (like the user clicking a button)". Chamar fora de clique dispara ADDON_ACTION_BLOCKED. | `https://warcraft.wiki.gg/wiki/Category:API_functions/restricted`, "last edited 27 August 2026". Não menciona roda do mouse nem repetição de tecla. | pagina | alta (definição); média (aplicação ao Forever) |
| `C_AuctionHouse.PostCommodity`, `StartCommoditiesPurchase` e `PlaceBid` estão marcadas com "#hwevent - This requires a hardware event i.e. keyboard/mouse input." | `https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.PostCommodity`, `https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.StartCommoditiesPurchase`, `https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.PlaceBid`. Desde Patch 8.3.0 (2020-01-14), "Added. Requires a hardware event." `PlaceBid` e `PostCommodity` também têm "Protected when called from a (macro) script" desde 9.1.5 (2021-11-02). Versão Forever da wiki: 1.60.1 (69913). | pagina | alta (texto da wiki); média (vale para o Forever) |
| `ConfirmCommoditiesPurchase` não tem nota de hardware event na wiki. | `https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.StartCommoditiesPurchase` (texto: "Note that C_AuctionHouse.StartCommoditiesPurchase requires a hardware event."). A página própria de Confirm não foi aberta. | pagina | média |
| Roda do mouse como hardware event: a wiki diz "keyboard/mouse input", sem tratar da roda. Não encontrei decisão oficial. | Busca e leitura da wiki acima. Fórum de 2022 sobre roda ("Free spinning mouse scrollwheel and hardware automation bans", `https://us.forums.blizzard.com/en/wow/t/free-spinning-mouse-scrollwheel-and-hardware-automation-bans/1187254`): nenhuma resposta de staff da Blizzard; "Blizzard's general rule is one keypress for one action." é de jogador. | pagina (fórum sem staff) | baixa |
| TSM 4.15 (Forever): "Since Blizzard broke the functionality we used to enable the Destroy scrollwheel macro." O texto não diz por que a Blizzard mudou isso. | `https://tradeskillmaster.com/news/tsm-4-15-brings-wow-forever-support-plus-new-desktop-app-1180` (aberto). Data no cabeçalho da página: "Sunday, November 1st 2026"; data na listagem de notícias: Nov 11, 2026 (conflito de datas). | pagina | alta (citação); baixa (causa) |
| Histórico de hardware event no leilão em 2010 (patch 4.0.1 exige um hardware event por ação de leilão; addons de fila perderam função). | Resumo de busca de fórum (`https://us.forums.blizzard.com/en/wow/t/auction-house-changes-yay-or-nah/557006?page=62`), pré-Forever. | busca | baixa (pré-Forever) |

### 4.3 O que a Blizzard disse sobre addon e automação no Forever

| Fato | Evidência | Marca | Confiança |
|---|---|---|---|
| Addons são permitidos no Forever. O representante disse no Discord de UI que o Forever usa a arquitetura de UI do Mainline e "most APIs in 12.1.5". | Resumo de `https://www.icy-veins.com/wow-forever/news/addons-in-wow-forever-blizzard-devs-just-addressed-the-big-question/` (página 403; resumo de busca). | busca | média |
| Blizzard disse (Midnight, retail, Ion Hazzikostas): "Addons should no longer offer a competitive advantage in WoW combat." Segredos (secret values) limitam o que o addon "knows" no combate. Nada sobre AH, roda ou macro. | `https://news.blizzard.com/en-us/article/24246290` (aberto; sem data na página). Wowhead (manchete de 2026-09-16) diz que as mudanças do Midnight valem para o Forever, sem texto (`https://www.wowhead.com/news/wow-forever-will-have-addon-changes-from-midnight-382921`). | pagina | média (aplicação ao Forever é busca) |
| Nenhum post oficial da Blizzard trata de addon de leilão, sniping ou roda do mouse no Forever. Os posts oficiais lidos (2381433, 2409104/61, 2409104/59 via guia, 2394005 via guia) não citam addons. | Leituras acima. | pagina | média (negativo: não achei) |
| Post de 2026-11-13 sobre automação de leilão ("Auction house being automated by something"): nenhuma resposta de staff da Blizzard; só jogadores. | `https://us.forums.blizzard.com/en/wow/t/auction-house-being-automated-by-something/2413977` (aberto). | pagina | alta (negativo: sem staff) |
| Auctionator (retail, 2024-06-02): thread sem resposta de staff; a Blizzard não se pronunciou. Jogadores dizem que addon que usa a API sem automação é aceito. | `https://us.forums.blizzard.com/en/wow/t/will-i-get-banned-for-using-auctionator/1868149` (aberto). | pagina | alta (negativo) |

---

## 5. Interpretação para o design (inferência)

Estas conclusões são minhas, com base nas seções acima.

1. A flag de hardware event de `PostCommodity`, `StartCommoditiesPurchase` e `PlaceBid` está na wiki (pagina) e as mesmas funções têm `HasRestrictions` no documento de build 70938 (pagina). Isso sugere que compra e venda em lote por tecla repetida ou roda do mouse têm risco de falha ou de bloqueio, e que o desenho deve exigir um clique por ação.
2. A Blizzard tem o hold de leilão (pagina). Acesso ao AH pode ser cortado no meio da sessão. O addon deve parar de forma limpa nesse caso e não tentar repetir.
3. Para o preço, a fonte de Blizzard do Forever é incerta (seção 2 e seção 1.1). Antes de contar com um feed externo, o desenho deve ter um leitor local do AH (C_AuctionHouse, dentro do cliente) como fonte principal.
4. Persistência: o SavedVariables do Forever é um ponto aberto (seção 6, incógnita 4). Não convém guardar histórico de preço só nele até confirmar. O companheiro que escreve arquivo na pasta do addon pede jogo fechado (ForeverSVFix) ou reload/reinício (WeakAuras, Raider.IO).
5. Dados de terceiros: o termo de API de desenvolvedor (busca) proíbe scraping e consulta automatizada. Um addon que puxa dado de endpoint da Blizzard pelo PC do dono precisa de checagem antes.
6. Comportamento de venda: a Blizzard citou como suspeito o item barato vendido por muito ouro e o preço muito fora do mercado. O desenho deve evitar esses padrões, ou registrar alerta, e não automatizar a venda.

---

## 6. Incógnitas (com o jeito de conferir no jogo ou na fonte)

1. **O hardware event vale no Forever para compra em lote?** Conferir com um clique manual de cada função num teste de conta própria, sem loop. Ver se aparece ADDON_ACTION_BLOCKED no chat ou no log de erros. Não automatizar.
2. **A roda do mouse conta como hardware event?** Testar um botão de ação ligado à roda, com um clique e uma ação de leilão (sem repetição), e observar ADDON_ACTION_BLOCKED. Não fazer repetição. A TSM diz que a Blizzard quebrou a macro de roda; confirmar no jogo se ela ainda funciona.
3. **Existe API oficial de leilão do Forever?** Abrir `https://community.developer.battle.net/documentation/world-of-warcraft` no navegador (não pelo WebFetch) e procurar Forever ou ruleset. Conferir também `https://us.forums.blizzard.com/en/blizzard/t/wow-forever-api-what-works-so-far-plus-a-ts-client/60334` com um teste de uma consulta de leitura (sem loop), usando a própria chave.
4. **O SavedVariables grava e carrega na build 70938?** No jogo: `/reload`, sair e entrar, depois ver o arquivo `WTF/Account/<conta>/SavedVariables/<addon>.lua` (data e conteúdo). A issue #34 (`https://github.com/ClassicWoWCommunity/forever-bugs/issues/34`) diz que foi corrigida na build 70009 (relato de jogador), mas o README do Auctioneer-Forever, conferido na build 69977, diz o contrário. O README do ForeverSVFix também tem os dois textos. Não há confirmação oficial.
5. **PlaceBid aceita cobre?** A wiki diz que aceita só ouro e "silently fails for non-zero copper counts" (página de retail). `C_AuctionHouse.SupportsCopperValues` existe no documento do Forever. Conferir com `/run print(C_AuctionHouse.SupportsCopperValues())` (leitura, não ação).
6. **Qual fonte de preço está certa?** Comparar um item em dois sites (ex.: wowauctions.net e TheWoWDB) com a casa de leilão aberta no jogo, no mesmo horário. Confirmar a fonte "Blizzard feed" contra o que o jogo mostra.
7. **Como o app do TSM recebe dado do jogo no Forever?** O AppHelper escreve no jogo? Precisa de reload? Não encontrei fonte; ler o AppHelper (TSM é fechado; conferir a documentação de suporte da TSM) ou observar no jogo.
8. **O Forever tem termos próprios sobre addon de leilão?** Não encontrei texto oficial do Forever. Conferir o Blizzard Developer API Terms e os termos de uso do Forever na página oficial, com a leitura completa (não resumo).
9. **As mudanças do Midnight valem para o AH do Forever?** Wowhead (manchete) e Icy Veins (403) não foram lidos por completo. Conferir o post oficial do Midnight (`news.blizzard.com`) e o post do Forever com data.
10. **Tempo de liberação do hold e do appeal.** Customer Support disse "usually a few days at least" (2409104/66, não aberto diretamente). Conferir o post e medir na prática se houver caso.

---

## Registro de buscas sem resultado

- Blizzard Game Data API do Forever (documentação oficial de endpoint, namespace e cadência): não achei texto oficial legível; o portal é JavaScript.
- Termos de uso da API de desenvolvedor de 2026: não achei texto oficial aberto; só citações de fórum.
- Punição por addon de leilão dentro das regras no Forever: não achei.
- Punição por sniper com roda do mouse no Forever: não achei.
- Decisão oficial sobre roda do mouse como hardware event: não achei.
- wowauctions.net: termos e API não achados; a página foi lida (fonte "Blizzard's official auction data").
- NexusHub e saddlebag site para Forever: não verificados.

---

## Desvios

- O prompt do sistema pede que eu não escreva relatório em .md, mas a tarefa pede este arquivo. Escrevi o arquivo porque a tarefa exige o caminho dele; o resumo também vai no resultado estruturado.
- `auctionhouse.fyi` e `thewowdb`, `forevermastery`, `wowauctions.net` dizem coisas opostas sobre a fonte de Blizzard do Forever. Não resolvi; ficou como incógnita 3 e 6.
- ForeverSVFix e a issue #34 se contradizem sobre a correção do SavedVariables. Não resolvi; incógnita 4.
- Não acessei o portal da Blizzard que pede login (redirect do Support). Não me autentiquei.
- Bloqueios não contornados: AHledger (HTTP 429), Icy Veins (403), warcraftlogs.com/help (403), PCGamer (texto cortado no resumo). Os itens que dependiam deles viraram busca ou ficaram de fora.
- Wowhead, CurseForge e mobalytics não foram consultados por 403 ou por resumo insuficiente.
