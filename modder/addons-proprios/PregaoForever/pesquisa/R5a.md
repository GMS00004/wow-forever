> Relatório de pesquisa de 2026-11-16, da onda 1 do design do PregaoForever, gravado como estava (foto do dia). `<espelho>`, `<dados>` e `<tmp>` eram pastas temporárias da sessão; o Apêndice D do `DESIGN.md` diz como refazê-las. Onde este relatório e o `DESIGN.md` divergem, vale o `DESIGN.md`.

# R5a: regras da casa de leilões do WoW Forever (Classic+)

Data de leitura de todas as fontes: 2026-11-16. Marcas: **local** (lido nesta máquina), **pagina** (página aberta, com URL e data), **busca** (só o resumo de uma busca, sem abrir a página), **inferencia** (conclusão minha).

Regra de leitura usada: quando a Blizzard publicou algo (fórum oficial, EULA), priorizei o texto da Blizzard. Sites de guia e de notícia foram tratados como fonte secundária. Onde divergem, registro as duas.

Ponto central: a Blizzard ainda **não publicou** taxas, durações nem limites do leilão do Forever. Quase todos os números de taxa e de duração que circulam são o Classic copiado por sites de guia.

---

## Resumo do que já está confirmado (e do que não)

- Confirmado pela Blizzard: depósito mínimo passa de 1 prata para 1 cobre, mas **ainda não está em vigor em 2026-11-16**. A Blizzard adiou para a manutenção semanal de 17/11 (EU 18/11) e não há data posterior confirmada.
- Confirmado pela Blizzard: **Temporary Economy Hold** restringe o leilão, o correio, o banco de guilda e o comércio em contas suspeitas de RMT.
- Confirmado pela Blizzard: **sem pedido de lance em grupo (GDKP)**, sem cross-faction, e Hardcore fora do lançamento.
- Não confirmado: corte da casa (5% / 15%), durações (2/8/24 ou 12/24/48), fórmula do depósito, limite de leilões, incremento de lance, WoW Token no Forever.
- Restrições de API (hwevent / noscript) de `C_AuctionHouse` aparecem numa página do wiki que cita o build do Forever, mas sem aviso específico do Forever.

---

## 1. Estrutura

### 1.1 Reino, ruleset e casas

| Fato | Fonte | Data da página / lido | Marca |
|---|---|---|---|
| Não há lista de reinos. O jogador escolhe um **ruleset** por personagem: Normal, PvP, Roleplay, Roleplay-PvP; Hardcore fica para depois. | https://wowforeverguides.com/news/wow-forever-developer-qa-stream (transcrição do Q&A de 2026-09-17, minutagem 01:09:54 e 01:12:38; a citação é da transcrição, não de vídeo que eu tenha visto) | Q&A 2026-09-17; lido 2026-11-16 | pagina (transcrição secundária) |
| Blizzard: “we are going realmless but not regionless”; “in WoW forever you will be selecting a specific rule set rather than a realm.” | mesma página | 2026-09-17 | pagina (transcrição secundária) |
| Wiki: “Players are split up by ruleset (Normal/PvP/RP/RP-PvP/Hardcore) on one 'mega-realm' per ruleset per region”. Os termos da Blizzard são **mega-realm**, não “Giga”. | https://warcraft.wiki.gg/wiki/Forever (sem data visível; sem atribuição de fonte) | lido 2026-11-16 | pagina |
| Regiões: Americas/Oceania, Europa, Coreia, Taiwan. CN precisa de cliente de API próprio. | busca (resumo de busca sobre “realms and servers”); vman (fórum, 2026-11-05) para CN | 2026-11-16 | busca / pagina (vman) |
| Oceania compartilha a casa do ruleset com os EUA (“share a ruleset-wide auction house with US friends”). | transcrição Q&A (acima), 01:12:38 | 2026-09-17 | pagina (secundária) |
| Facções separadas. Sem cross-faction (“there's not going to be any cross faction play”). | transcrição Q&A, 01:25:40 | 2026-09-17 | pagina (secundária) |

**Casas e facções.** Há casas por facção e casas neutras, segundo guias (sem fonte oficial):
- Aliança: Ironforge, Stormwind e Darnassus compartilham uma casa.
- Horda: Orgrimmar, Thunder Bluff e Undercity compartilham uma casa.
- Neutras: Gadgetzan, Booty Bay e Everlook, com corte maior.
- Fonte: https://warcraftforever.games/guides/auction-house (atualizada em 2026-09-19; lido 2026-11-16), pagina, sem fonte citada para as regras. Hearthproof repete o mesmo mapa e diz que a regra é “Classic” (https://hearthproof.com/economy/auction-house/, v1.19 de 2026-11-14; lido 2026-11-16), pagina, marcado como Classic, não como Blizzard.
- Não há evidência de que as capitais compartilhem a mesma casa além do que o guia descreve. Não há casa de commodity de região inteira declarada pela Blizzard.

**Casa local (do jogo, do build instalado).** O log do cliente mostra registros de leilão validados em 2026-11-15 22:05:10:
- Tabela `AuctionHouse`: RecID 123, 124, 125 (local: `C:/Program Files (x86)/World of Warcraft/_forever_/Logs/Hotfix.log`, linhas 29879–29881).
- Tabela `AuctionHouseRedirect`: RecID 18 a 21 (mesmo arquivo, linhas 10507–10510).
- A API comunitária cita houses 110–121 e 123–125 (vman, 2026-11-06). O log local só mostra 123–125. Isso sugere que o cliente baixa só parte das casas. Inferência, não confirmada.

### 1.2 Giga Realms, tamanho e layers

- O termo do brief (“Giga Realms”) não aparece em nenhuma fonte. A Blizzard e a wiki usam “mega-realm” (wiki, pagina, acima).
- Número de reinos, tamanho e layers: **não achei**. Busca de “layers” nas fontes mostrou só o modelo antigo do Classic (mega-servers com layers). Nenhuma fonte confirma layers no Forever (busca, sem URL confirmada).
- Filas e capacidade: a Blizzard não deu números.

### 1.3 A pasta “91” no WTF (local)

Caminho: `C:/Program Files (x86)/World of Warcraft/_forever_/WTF/Account/<conta>/91/` (a conta numérica foi omitida aqui de propósito).

Fatos locais:
- A pasta `91` contém 4 subpastas de personagem no formato `Nome-Servidor`. O sufixo varia entre personagens (ex.: Ironjaw, Stonejaw, Bull, Thunderfist). Os nomes dos personagens não foram copiados.
- O addon GuiaForever grava um rótulo de reino fixo: `CAMWOW US1 Realm 7 PvE` (local: `.../WTF/Account/<conta>/SavedVariables/GuiaForever.lua`, linhas 77, 87, 93, 99 e outras). O sufixo “PvE” corresponde ao ruleset Normal, mas isso é inferência.
- Busca (um único relato de fórum): apagar o conteúdo da pasta `91` faz o jogo abrir a tela de seleção de ruleset. Relato não verificado. **Não testei e não apaguei nada.**

**O que a pasta 91 é:** não encontrei nenhuma fonte que explique o número. A melhor hipótese é um identificador numérico interno do cliente para o reino ou ruleset da conta. Inferência, confiança baixa.

---

## 2. Taxas e regras

### 2.1 Corte da casa (venda)

| Item | Achado | Fonte | Marca |
|---|---|---|---|
| 5% na casa de facção e 15% na neutra | Não confirmado. Fontes de guia dizem que é o Classic, e uma delas diz que é “from game files of client 1.60.1” (busca de resumo, Lore Forever / AHLedger). | warcraftforever.games (2026-09-19); hearthproof (Classic, marcado como suposição); space4games (Blizzard não menciona taxa de venda) | pagina (sem fonte oficial) / busca / inferência |
| Blizzard sobre o corte | “As far as we know, the cut the Auction House takes when an item sells stays the same.” (texto de guia, paráfrase, não é citação da Blizzard) | https://space4games.com/en/games-en/wow-forever-auction-house-deposit/ (artigo de 2026-11-10) | pagina (secundária) |

**Conclusão:** o corte é inferido do Classic. Não há fonte da Blizzard. **Tratar como incógnita.**

### 2.2 Depósito

**Mínimo (fato confirmado pela Blizzard):**
- Hotfix de 10/11: “Adjusted the minimum deposit amount to 1 copper (was 1 silver)”, listado em “With realm restarts” (citado num tópico do fórum: https://eu.forums.blizzard.com/en/wow/t/any-eta-on-ah-change/642107; lido 2026-11-16).
- Kaivax (Blizzard), post #7 do tópico de hotfix, 2026-11-12 00:48: “We've temporarily removed Auction House changes from yesterday's update, as they will go live with scheduled weekly maintenance on November 17. They will appear again in the hotfixes update thereafter.” (https://us.forums.blizzard.com/en/wow/t/wow-forever-hotfixes-november-10-2026/2403040; lido 2026-11-16). Pagina.
- Data de vigência: manutenção semanal de **17/11** (EU 18/11, segundo o artigo de 2026-11-10 e o site Seramate). Em 2026-11-14, jogadores relatavam ainda ver 1 prata no depósito (fórum). Pagina/busca.
- Hearthproof (v1.19, 2026-11-14) diz: “1 silver until the Nov 17 maintenance and 1 copper from then on”. Pagina.

**Fórmula e durações (conflito entre fontes):**

| Fonte | O que diz | Marca |
|---|---|---|
| Zierhut (Blizzard) em entrevista citada pelo Seramate/Wowhead, 2026-11-06 | O depósito deve voltar à “WoW Classic formula”. Tabela: 2 h = 5% do preço de vendedor; 8 h = 20%; 24 h = 60%. | https://seramate.com/news/forever/2026/11/06/forever-ah-minimum-deposit-copper-11353d96 (pagina secundária) |
| warcraftforever.games (2026-09-19) | Durações: “2, 8 or 24 hours. Longer listings cost a bigger deposit.” Fórmula: “scales with the item's vendor price and the duration”. Sem números. | pagina (sem fonte) |
| Hearthproof (2026-11-14) | Forever: “Three options: 12, 24 and 48 hours.” Classic: 2, 8 e 24. Marcado como cliente beta, não resolvido. | pagina, marca “Client (beta)” |
| Busca (Lore Forever, AHLedger) | 12, 24 e 48 horas na cliente. Outros guias (Warcraft Forever, Conquest Capped) dizem 2, 8 e 24. | busca |
| Auctionator (brief) | Brief diz que usa 2, 8 e 24 horas. **Não verifiquei** (não abri o código do Auctionator). | — |

**Devolução do depósito:** venda → depósito devolvido (mas o corte da venda ainda vale); cancelamento ou expiração → depósito perdido. Fonte: Hearthproof (“As in Classic”), warcraftforever ("refunded if the item sells, lost if it expires") e busca. Marca: pagina (sem fonte oficial), inferência do Classic.

### 2.3 Limite de leilões por personagem, lance mínimo e incremento

- **Limite por personagem:** não achei fonte. Hearthproof diz: “Not printed: deposit rates above the 1-copper minimum, and any listing cap.” Marca: pagina (secundária, admite a lacuna).
- **Lance mínimo e incremento:** não achei valor. Hearthproof: “Bid increment: Not stated anywhere on the page.” Marca: pagina.
- **Arremate obrigatório (buyout):** Forever, não declarado. Classic: buyout opcional (“A listing has a starting bid and an optional buyout”). Pagina (Hearthproof).
- **Lance em estoque empilhável:** Hearthproof: “Not printed: whether stackable goods can be bid on.” Pagina.

### 2.4 Correio e entrega do ouro

- Venda: o ouro chega pelo correio cerca de 1 hora depois (Classic). Forever: “about an hour after the sale, as in Classic” (Hearthproof, pagina). Há relato no fórum de que o correio do leilão chegou em 2 minutos e isso foi corrigido no hotfix de 10/11 (busca, resumo de notícia; URL não aberta).
- Forum (Hearthproof): “Two minutes to an hour, as seen on the sold tab.” Relato de jogador. Não confirmado.

### 2.5 Restrições (nível, conta nova, ouro)

- **Nível mínimo:** não há restrição declarada. Relatos de personagem nível 20 na Black Market em beta e de nível 38 no live (busca). Não achei regra oficial.
- **Conta nova:** há relato de filtros sociais e de comércio para contas novas (fórum, sem fonte oficial). Título do tópico: “Are there trade and social restrictions on new accounts?” (us.forums.blizzard.com/en/wow/t/are-there-trade-and-social-restrictions-on-new-accounts/2399157; lido por busca, não aberto). Marca: busca. Não confirmado.
- **Limite de ouro:** não achei.

### 2.6 Black Market (BMAH)

- Local: Powderfuse Port, Riverglades (guia). Marca: pagina (guia, sem fonte oficial).
- Itens são sorteados e vão para o maior lance, sem buyout (guia, de beta; a regra descrita pode ter mudado). Marca: busca.
- Dinheiro vai para o NPC, não para outro jogador (guia). Marca: busca.
- Blizzard não documentou a BMAH do Forever. Não achei fonte oficial.

---

## 3. WoW Token e medidas contra bot e RMT

### 3.1 WoW Token

- **Não achei** nenhuma página que cite o WoW Token no Forever. Hearthproof (2026-11-14), o guia mais detalhado que abri, não o menciona. Marca: pagina (ausência).
- Um post de fórum diz que o Token é a única compra de ouro autorizada (busca). É opinião de usuário, não da Blizzard.

### 3.2 Medidas contra RMT e bots (Blizzard)

- **Post oficial, 2026-10-01, 21:07 (Kaivax)**: “we have been continuously actioning accounts that were found to be botting to amass gold in the WoW: Forever Beta.” Penas: “the gold being removed, account suspensions, or permanent account closures.” Aviso: “Be wary of accepting gold from unknown or suspicious sources. If the provider is engaged in Real Money Transactions, you could put your account at risk of closure.” Fonte: https://eu.forums.blizzard.com/en/wow/t/actions-taken-against-botting-and-rmt/632993 (lido 2026-11-16). Pagina.
- **Temporary Economy Hold (Kaivax, 2026-10-13, 23:58)**. Texto, citado da página do fórum:
  - “You will have restricted use of trade, mail, guild banks and the Auction House while this economic hold is in place.”
  - Sem duração fixa. Removido “automatically when the actions that triggered it have been investigated and found false”, ou seguido de penas se houver RMT.
  - “merely having a Temporary Economy Hold will leave no permanent strikes against your account unless also later proven to be RMT motivated.”
  - “There may be false positives while things are fine tuned.”
  - “all of these systems will also be deployed to all versions of World of Warcraft if proven successful.”
  - Fonte: https://us.forums.blizzard.com/en/wow/t/temporary-economy-holds-for-rmt/2381433 (lido 2026-11-16). Pagina.
- **Q&A de 2026-09-17, 01:19:39**: “we are going to very aggressively punish gold buyers.” Sem GDKP (01:16:11). Transcrição secundária (wowforeverguides). Pagina.

---

## 4. Política de addons, jogar remoto e streaming

### 4.1 Política de addons

**Política geral (Blizzard, histórica; cópia de terceiro):** https://addonstudio.org/wiki/WoW:Blizzard_AddOn_Policy (wiki de terceiro, lido 2026-11-16). Regras listadas:
1. Addons gratuitos.
2. Código totalmente visível.
3. Não pode prejudicar realms ou outros jogadores.
4. Sem anúncio. Sem pedido de doação. Sem conteúdo ofensivo.
5. Deve seguir o ToU e o EULA.
6. A Blizzard pode desativar qualquer função de addon “as it sees fit”.

- Origem: Patch 3.1, revisões de 2009 e 2010. A referência oficial é um post de fórum da Blizzard de 2009 (“On 20 March, we released the new add-on development policy…”, busca). Marca: busca (a cópia que abri é de terceiro).
- Não achei o texto oficial atual (2018 ou posterior) do policy de addons. Marca: não achei.

**Forever (Blizzard, via entrevistas e Q&A; fontes secundárias):**
- “Forever uses the modern add-on API, not the classic one.” (transcrição Q&A, 01:20:52). Pagina secundária.
- “Blizzard has confirmed that Forever will use the same addon restrictions as current Retail” (elyxir.gg, 2026-09-18). Mesma restrição do Midnight: “any combat-related API limitation introduced in Midnight will also apply to Forever”. Pagina secundária (notícia de terceiro).
- Entrevista citada (mmonster): “addons that do the math for you will not be available in Forever” e “Addons that customise the interface stay allowed” (Q&A). Pagina secundária.
- Kotaku, citado em busca: combate e automação “computational add-ons” não estarão disponíveis. Busca.
- Dados de estatística em combate: escondidos de addons. Fonte: mmonster (sem fonte citada, marcado “Beta”); forum (queixa de usuário, 2026-11-07). Pagina/busca.
- Paid add-ons: a Blizzard não declarou nada específico sobre addons pagos no Forever (mmonster diz que não achou). Pagina.

### 4.2 Hardware event e noscript na API da casa de leilões

Página do wiki: https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.PostItem (lido 2026-11-16):
- A função é marcada `#hwevent`: “This requires a hardware event i.e. keyboard/mouse input.”
- Marcada `#noscript`: “This cannot be called directly from /run and /script, RunScript, or loadstring.”
- Marcada “This function is restricted.”
- A lista de builds inclui **forever 1.60.1 (69913)**. A página não diz se a restrição muda entre versões.
- Exemplo de código do próprio wiki: chamada direta `AuctionHouseFrame.ItemSellFrame.PostButton:Click()` “would brick the Auction House”. Clique automático não é suportado.
- Também em `C_AuctionHouse.SearchForFavorites`: “does not work and also bricks the AH in the process” quando chamada direto do /run (página restricted category: https://warcraft.wiki.gg/wiki/Category:API_functions/restricted, revisão de 2026-08-27). Pagina.
- Regra “uma ação por evento de hardware”: não achei texto oficial. Há um relato de fórum sobre o patch 9.1.5 (busca) e a documentação do MessageQueue (busca). A página `Hardware_event` do wiki deu 404 (duas tentativas). Marca: busca / não confirmado.
- Um post de blog de 2026 (busca) diz que `C_AuctionHouse.PlaceBid` também é hwevent. Não abri a página.

### 4.3 Jogar por acesso remoto ou streaming do próprio PC

- **EULA da Blizzard** (https://www.blizzard.com/en-us/legal/fba4d00f-c7e4-4883-b8b9-1b4500a402ea/blizzard-end-user-license-agreement, última revisão 2024-03-21; lido 2026-11-16). Seção 1.C.v, “Cloud Computing”: uso da Plataforma, incluindo um Jogo, “in connection with any unauthorized third-party 'cloud computing' services, 'cloud gaming' services … or any software or service designed to enable the unauthorized streaming or transmission of Game content”. Marca: pagina (texto primário, mas do EULA geral, não do WoW Terms of Use). Confiança alta no texto; a aplicação ao caso do dono é inferência.
- **Forum (busca, sem data confirmada):** um GM disse que remote desktop “similar setup as cloud gaming … not allowed according to our Terms of Use”. Marca: busca. Não consegui abrir a página com essa resposta. O tópico de 2021 que abri (`815702`, sem GM) e o de Parsec (`1020333`, sem GM) não têm resposta da Blizzard. Marca: pagina (ausência).
- Parsec para o próprio PC: opinião de usuários e da própria Parsec (busca). Não há posição oficial da Blizzard.
- Multiboxing: “is not a violation of our Terms of Use. Please note, however, that use of input broadcasting software may result in account penalties” (busca, citação de post da Blizzard, sem data). Marca: busca.
- **Não achei o WoW Terms of Use atual.** Esta é a lacuna principal da seção 4.3.

---

## 5. API oficial de dados (Game Data API)

- **Portal oficial:** develop.battle.net redireciona para community.developer.battle.net/documentation/world-of-warcraft/game-data-apis. A página abriu como casca HTML, sem texto de documentação. Marca: pagina (sem conteúdo utilizável).
- **Namespace do Forever:** não achei na documentação oficial que abri. Marca: não achei.
- **Namespaces citados por usuário (não oficial):** `static-forever-{region}` (dados estáticos, versão 1.60.1_70399 na data do post) e `/data/wow/ruleset/{id}/auctions/` no namespace dinâmico (com barra final). Post de 2026-11-05 e atualização de 2026-11-06 de vman-2993, no fórum da Blizzard: https://us.forums.blizzard.com/en/blizzard/t/wow-forever-api-what-works-so-far-plus-a-ts-client/60334. Marca: pagina; autor é usuário, e o post diz “Every technical claim below comes from vman-2993's own probing”. Confiança baixa.
- **Houses:** IDs 110–121 e 123–125 (mesmo post). Cada ruleset lista as mesmas casas (teste do autor). Não confirmado.
- **Commodities:** o endpoint `/data/wow/auctions/commodities` de 2026 retorna 404 (post de vman). A casa de commodities fica sob cada house. Não confirmado.
- **Frequência de atualização:** o post de 2022-08-18 de Korakk-1142 (https://us.forums.blizzard.com/en/blizzard/t/immediate-change-to-auction-apis-for-commodities-with-927/31522) diz “updating every hour (same cadence as the other auction data)”. Não há cargo de staff visível no post. Esse post é de **Classic/retail 2022**, não do Forever. Para o Forever, **não achei frequência**.
- **Autenticação:** não me autentiquei nem criei credencial. Nada foi chamado na API.
- **Relato de 404 em endpoints de leilão em Classic/TBC (2025–2026, fórum):** busca. O Forever ainda não tem histórico verificado.

---

## Incógnitas (com o jeito de conferir)

1. **Corte da casa (5% facção / 15% neutra):** ver a taxa mostrada na janela de postar do leilão, antes de confirmar a venda, na casa de facção e na neutra. Comparar com a conta. Não confiar em guia.
2. **Durações e depósito por duração (2/8/24 vs 12/24/48):** abrir a janela de postar, trocar a duração e anotar o depósito. Comparar com 5%/20%/60% do preço de vendedor.
3. **Valor efetivo do depósito de 1 cobre:** só depois de 17/11 (EU 18/11). Antes disso, o valor é 1 prata. Conferir listando um item barato e lendo a taxa.
4. **Limite de leilões por personagem e lance mínimo/incremento:** listar várias vezes e tentar dar lance em item de teste. Não achei fonte.
5. **Significado da pasta `91` no WTF:** comparar o conteúdo com o ruleset escolhido na tela de seleção (sem apagar a pasta, o jogo está aberto). Fazer cópia antes de qualquer mexida.
6. **Duração de Temporary Economy Hold e caminho de recurso:** o Blizzard não deu duração. Ver na conta se a restrição aparece e em que mensagem.
7. **Hardware event exato no Forever** para `C_AuctionHouse.PostItem` e `PlaceBid`: ler o FrameXML ou os arquivos do cliente em `_forever_/Interface`, ou testar uma única ação manual e observar se `ADDON_ACTION_BLOCKED` ou `ADDON_ACTION_FORBIDDEN` dispara. Não testei nada no jogo.
8. **Regra de remote play e streaming:** a EULA fala de serviço de nuvem não autorizado. Pedir resposta por escrito ao suporte da Blizzard e ler o WoW Terms of Use atual. Não achei o texto do WoW ToU.
9. **Existência do WoW Token no Forever:** conferir na loja/menu do jogo ou no suporte.
10. **Namespace e frequência da Game Data API para o Forever:** conferir a documentação oficial (página que não abri com texto) e, se o dono autorizar, uma chamada sem credencial nova.
11. **Mail do leilão (1 h ou 2 min):** vender um item de teste e medir.

---

## Desvios e observações

- **Build divergente.** `.build.info` local diz `1.60.1.70938`, Product `wowf`, Branch `us` (local: `C:/Program Files (x86)/World of Warcraft/.build.info`, linha 1). O brief bate. Outros builds citados: 70888 (hotfix de 10/11, fan database, busca), 69913 (wiki, lista de builds forever), 70399 (vman, API). Registrado como fato de build, peso detalhe.
- **Termo “Giga”.** O brief fala em “Giga Realms”. Nenhuma fonte usa “Giga”. A Blizzard e a wiki usam “mega-realm”.
- **Auctionator.** O brief afirma que o Auctionator do Forever usa 2, 8 e 24 horas. Não verifiquei o código nem a página do addon.
- **Hotfix de 10/11 e data de “17/11”.** O Kaivax diz “November 17”. Seramate diz “EU on Wednesday 18 November”. Não há conflito real (a EU tem a manutenção um dia depois), mas registro as duas.
- **Fontes bloqueadas.** Icy Veins deu 403 (não contornei). AHLedger deu 429. Space4games deu 429 numa tentativa anterior, mas o artigo foi aberto depois. Wowhead abriu só o título. CurseForge e Wowhead tabelas não abertos.
- **Local, sem valor de regra:** os logs do cliente e a estrutura WTF foram lidos só para confirmar build e tabelas. Não copiei nomes de personagens nem o número da conta.
- **Outras fontes da Blizzard que não consegui abrir:** o post de Zierhut e a entrevista do Kotaku (citados por terceiros).
- **Fora do escopo, uma linha:** o vídeo oficial do Q&A de 2026-09-17 não foi aberto. Só a transcrição de terceiro.
