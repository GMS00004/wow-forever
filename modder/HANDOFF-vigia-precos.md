---
frente: vigia-precos
status: ativa
atualizado: 2026-11-26T03:45-03:00
maquina: Avell
temas: [jogos, analise-dados, monitoramento]
proximo_passo: "Caça e isca do CompraForever 0.4.0 rodaram no jogo (289 Thick Leather a 4s27c de média). Próxima sessão: commit pendente se o dono não respondeu; ideias opcionais na tarefa #2 do TaskHub (aviso de pausa das iscas, nomes dos vendedores, custo efetivo no painel, som na trava)"
decisoes_abertas: 3
commit: 6c41d9e
sensivel: false
---

> Frente: vigia-precos · Atualizado: 26/11/2026 03:45 · Máquina: Avell

> **O que é esta frente.** Registro de preços e tendências da casa de leilão (AH) do WoW Forever para o Guilherme (o dono), em duas pontas: dentro do jogo, o addon próprio **CompraForever 0.2.0** ganhou a vigia de preços (seção WATCH: itens com teto, busca periódica, alerta e compra em 2 cliques, histórico na SavedVariables) e a postagem no leilão (seção SELL); fora do jogo, um **coletor horário** guarda a foto pública de preços da casa `us-111` e a ferramenta **`tendencia.mjs`** mostra curva do dia, percentil do preço de agora e ranking de elasticidade (swing trade de materiais). Motivo do dono em 18/11/2026: a Thick Leather (4304) cai de 6s para 3s40c por segundos e ele perdeu 4g por não estar olhando; quer "registrar preços e averiguar tendências de mercado de uma forma mais eficiente".
>
> **Pedido novo do dono (26/11/2026, madrugada, na AH): o botão caçador de preço.** Tarefa #2 do TaskHub (id `51d5afbc-64ee-4753-88eb-6d564ec870b9`, Entrada, cinco passos), ligada a esta frente. Um material de altíssima liquidez de cada vez (couro, tecido, minério de profissão), com o preço-alvo do dono (ex.: Thick Leather a 5s20c ou 5s30c); ele spama o botão e cada clique atualiza só aquele item e, havendo quantidade no alvo ou abaixo, compra tudo até o alvo, até ele parar de clicar. Motivo: atualizando à mão, ele comprou 80 unidades a 5s de média com a prateleira em 7s a 7s50c e, logo depois, uma pilha de Thick Leather a 3s50c; e viu a cascata dos vendedores automáticos (alguém posta 1 ou 2 couros a 5s20c, os robôs cobrem a 5s19c com as pilhas inteiras). **Ressalva do dono:** lote de 1 ou 2 unidades não dispara compra, porque é a isca que faz os outros postarem pilhas grandes baratas. Desenho preliminar (do agente, ainda sem contrato): um clique sem resultado novo busca só o item; com lotes de 3 ou mais no alvo, cota (`StartCommoditiesPurchase`) a quantidade do mais barato até antes do primeiro lote pequeno; com a cotação na tela, confirma (`ConfirmCommoditiesPurchase`) se o preço ainda está no alvo, senão cancela, e encadeia a busca seguinte. Nenhum laço sozinho: parou de clicar, parou tudo (fecha a decisão aberta 1 só para este modo). Limite da API: a compra de commodity leva sempre do mais barato para cima, então a isca só fica de fora quando está acima das pilhas. ~~(o caso normal)~~ Corrigido em 26/11/2026 por um print do dono (Thick Leather, n=1): os lotes pequenos estavam abaixo das pilhas (1 a 4s00c, 1 a 6s50c, 2 a 6s98c logo abaixo de 272 a 6s99c, 2 a 7s02c logo abaixo de 381 a 7s03c), então a regra vira "lote pequeno sozinho não dispara compra"; quando uma pilha de 3 ou mais está no alvo, os lotes pequenos mais baratos entram na mesma compra. Falta conferir no espelho da API se a busca de commodity devolve um lote por anúncio, para ler o tamanho de cada lote. Decisões do dono na decisão aberta 4.
>
> **Fechamento da madrugada (26/11/2026, 03h45; leia isto primeiro).** A caça e a isca rodaram no cliente real. SV das 03h31: 289 Thick Leather em 27 compras por 12g 34s 40c (4s27c de média), 130 iscas postadas a 4s10c; nas últimas 100 tentativas cronometradas, 21 compras, 35 recusas e 44 cotações acima do visto. Cotação com mediana de 0,65 s e compra recusada de 0,86 s; a fila do cliente fica ocupada com a compra pendente, então a ideia do dono de soltar o botão 1 s depois do confirmar não teria ganho (contrato 13.4). O "Internal auction error" é o texto do cliente para a compra recusada (`COMMODITY_PURCHASE_FAILED`). Regra de jogo do dono: até 3 iscas; se as 3 forem compradas na hora, pausa de 1 a 2 min (diz ter ~40% de sucesso assim); depois decidiu também caçar sem isca, esperando ondas de outros vendedores. Recusados por automação: macro de vários cliques e turbo no mouse, e tecla segurada que repete. Horário de venda pelas 77 fotos de 19 a 26/11: madrugada mais cara, tarde mais barata, manhã sem dado. Backup do WTF no fim: `%LOCALAPPDATA%\wow-agentes\backups\sessoes\2026-11-26_0339\WTF.zip`. Contrato do addon, seções 13 a 13.4; cenários `compra-17` a `compra-22` (bancada `compra` 23 e `rota` 29, 0 erros). Ideias opcionais, só se o dono pedir (passos da tarefa #2): aviso "Pause 2 min" das iscas, nomes dos vendedores das linhas baratas (robô ou gente), custo efetivo com as iscas no painel, som quando a trava é atingida.
>
> **Construído na mesma madrugada (26/11/2026, 01h25 às 01h45): CompraForever 0.4.0 com a caça.** O dono quis testar na hora; o agente decidiu a decisão 4 pelos padrões que recomendou (alvo lote a lote, trava digitada com o alvo e 5g de padrão, comando `/compra hunt`) e o dono confirma ou corrige depois do teste. Contrato na seção 13 do `CONTRATO.md` do addon; uso no `LEIA-ME.md`; cenários `compra-17` e `compra-18`; sem arquivo novo no TOC (basta `/reload`). Tecla: `/compra key BUTTON4` (o botão lateral do mouse, direto, só com a AH aberta); macro de vários cliques no mouse fica fora (fato em `comum\referencia\forever.md`, marca [busca]). **No jogo (01h50):** a tecla de espaço clicou depois do segundo `/reload` (corrigido o caso do reload com a AH aberta); o dono ainda não pegou compra pela caça. **Isca (02h05, ainda não rodou no jogo):** `/compra bait <item> <preço> [qtd]` e `/compra baitkey E`, botão próprio que posta a quantidade fixa (1 por padrão); a linha de commodity com anúncio do dono conta `quantity - numOwnerItems`, a conta da UI da Blizzard (seção 13.1 do contrato). O dono postou sem querer 95 Thick Leather a 5s pela tela da Blizzard, e não foi o addon.
>
> **Leia isto mais estes arquivos e você retoma do zero:** `C:\GMS\Claude Code Projects\wow\CLAUDE.md` (limites fixos e formato do relatório de sessão); `addons-proprios\CompraForever\LEIA-ME.md` (uso para o dono) e `CONTRATO.md` (seções 3, 5, 6, 7, 9 e 10: vigia, venda, decisões e pendências); `ferramentas\pregao\CONTRATO.md` seções 7 a 9 (coletor, tarefa agendada, tendência); `comum\referencia\api-forever.md` §3g.1 (assinaturas de postagem).
>
> **Não refaça:** o design do CompraForever 0.1.0 (validado no jogo pelo dono em 17/11/2026), a vigia e a venda (bancada com 17 cenários e 0 erros em 18/11/2026), o coletor e a tarefa agendada (registrada e disparada com sucesso no Avell em 18/11/2026), a `tendencia.mjs` (31 casos de teste), a pesquisa das assinaturas de postagem (lida da documentação gerada do cliente em 18/11/2026).
>
> ⚠️ **Nada da 0.2.0 rodou no jogo ainda.** O TOC ganhou `Vigia.lua` e `Venda.lua`: é preciso **reiniciar o jogo**, `/reload` não basta.
> ⚠️ **A vigia busca sem tecla do dono** enquanto a AH está aberta (a bancada marca a regra I9, herdada do PregaoForever; os cenários 13 a 15 aceitam só essa violação). O dono ainda não decidiu se o addon pausa a vigia depois de N minutos sem tecla (decisão aberta 1). Limites fixos do projeto: só API oficial, um clique de hardware = no máximo uma ação de leilão; busca não é ação.
> ⚠️ **Código de addon de terceiro não é referência** (Auctionator, Syndicator, Baganator pedem isso num `AGENTS.md`; o dono ratificou em 16/11/2026). A API veio do espelho `Ketho/wow-ui-source-forever`, branch `forever`.
> ⚠️ **A duração `/compra duration 1-3` não foi conferida no jogo**: as durações do Forever são 2 h, 8 h e 24 h (sonda S0 de 16/11/2026), mas qual índice é qual, ninguém viu.

## Estado em uma tela

- **Addon:** `C:\GMS\Claude Code Projects\wow\modder\addons-proprios\CompraForever\`, 0.2.0, ligado ao jogo por junction do `dev-link.ps1` (slug `dev-compraforever`). Interface 16001. Arquivos novos: `Vigia.lua` (316 linhas) e `Venda.lua` (~280). SV: `CompraForeverDB.vigia = { itens = { [id] = { nome, teto, qtd, venda } }, intervalo = 30, historico = { [id] = { { t, min, p25, unid } } } }` (anel de 2.000 por item); `config.duracao = 3`.
- **Fora do jogo:** `ferramentas\pregao\coletar-foto.mjs`, `coletor-tarefa.ps1` + `coletor-oculto.vbs`, `tendencia.mjs`; testes `testes\testar-coletor.mjs` (14 casos) e `testes\testar-tendencia.mjs` (31 casos), ambos com erros=0 (observado em 18/11/2026).
- **Tarefa agendada `GMS WoW Precos Hora`** registrada no Avell, minuto 50 de cada hora, estado Ready; disparada à mão às 13:41 com resultado 0 e a linha `repetida` no log (observado em 18/11/2026). Só no Avell: `dados\pregao` fica fora do git.
- **Fotos guardadas:** 1 (`us-111-1795019101.txt.gz`, snapshot 12:25 local, 6.620 itens) em `modder\dados\pregao\publico\fotos\` (observado em 18/11/2026). O `gapH` da elasticidade só entra com 12 fotos ou mais.
- **Números que motivaram a frente (preços de 18/11/2026, 12:25):** Nightscape Pants (14 Thick Leather + 4 Silken Thread, NPC paga 87s08c; Silken Thread no vendedor com 10% a 4s50c) empata com a Thick Leather a 4s93c; a 4s dá +13s08c por calça, a 3s40c +21s48c (20 calças, +4g30s). O mínimo diário da Thick Leather ficou abaixo do empate em 3 dos últimos 4 dias (3s66c dia 14, 3s32c dia 16, 3s22c dia 17) com mediana entre 6s20c e 7s70c e 7 a 10 mil unidades vendidas por dia. Mender's Mail Boots: 3s60c por bota, limite de ~14 crafts pela Iridescent Pearl, uns 50s no total menos 10s a 13s do Tanning Rack: abaixo da régua de 1g do dono.
- **Desde 23/11/2026 o addon está na 0.3.0** (modalidade de rota, frente `custo-legacy-profissoes`); pelo `estado\estado.md` de 26/11/2026, a vigia e a venda da 0.2.0 seguem sem teste no jogo registrado.
- **0.4.0 (26/11/2026):** caça (`/compra hunt`, `/compra key`), isca (`/compra bait`, `/compra baitkey`), linha com anúncio do dono por `quantity - numOwnerItems`, corrida perdida que busca de novo, busca parada que se refaz no aperto e cronômetro em `CompraForeverCharDB.caca.tempos`. Rodou no jogo.
- **O que falta, em uma frase:** a vigia periódica da 0.2.0 (WATCH) e a decisão da pausa sem tecla continuam sem teste no jogo; a caça está pronta e em uso; o resto são ideias opcionais da tarefa #2.

## O que já foi feito (não refazer)

1. **Levantamento (18/11/2026, manhã):** estado das frentes `crafts-que-pagam` e `waylaid-crates`; preços de hoje por `baixar-precos.mjs`; números da Nightscape Pants e da Mender's; ranking de elasticidade preliminar (Thick Leather, Rugged Leather, Mithril Ore, Bolt of Runecloth, Elemental Earth, Thorium Ore). Achado lateral: o release público tem `us-111-flip.txt` e `us-111-plan.txt`, não documentados (parecem candidatos a flip e planos de craft do autor); colunas não decifradas.
2. **Plano com roteamento** (scratchpad da sessão; resumo no diário de `estado\estado.md`, 18/11/2026), executado por subagentes econômicos em 3 ondas com gate: T1 coletor (haiku), T2 tarefa agendada (haiku), T3 tendência (haiku), T4 Vigia (sonnet), T5 docs fora do jogo (haiku), T6 Venda (sonnet), T8 docs do addon (haiku). Nenhum escalonamento. Calibração em `C:\GMS\Claude Code Projects\skill-review\reviews\calibracao.jsonl` (commit `37b09c8` naquele repo).
3. **CompraForever 0.2.0:** `Vigia.lua` (comandos `/compra watch <item> <teto> [qtd]`, `unwatch`, `watch every <s>`; busca periódica por `ns.buscarVigia` do `Scanner.lua`, sessão tipo `vigia` que não toca em `ns.scan` nem replaneja; alerta `PlaySound(RAID_WARNING)` + `RaidNotice_AddMessage` na passagem para "abaixo do teto"; `ns.vigiaOportunidade()` vira linha `[WATCH]` antes do plano em `Compra.lua`, limite da cotação `teto * qtd`, "Price rose above watch" invalida a escada; intervalo efetivo `max(intervalo, n * 0,6 s)` para ficar sob 100 buscas/min); `Venda.lua` (`/compra sell <item> <piso|off>`, `/compra post <item> <preco|auto> [qtd]`, `post`, `post clear`, `/compra duration 1-3`; sugestão automática para vigiado com piso e estoque; `PostCommodity`/`PostItem` por pilha e por clique, `Confirm post` após `AUCTION_HOUSE_POST_WARNING`; conclusão por `AUCTION_HOUSE_AUCTION_CREATED`, ou por `OWNED_AUCTIONS_UPDATED` só se a pilha saiu da bolsa ou encolheu); painel com seções WATCH e SELL, `MAX_LINHAS = 30`. Cenários `compra-12` a `compra-16` em `ferramentas\guia\casos-pregao\cenarios\compra\`; `PlaySound` contável no falso (`ferramentas\guia\pregao\bancada\nucleo.lua`). Bancada `--cenarios compra`: 17/0; os outros grupos (PregaoForever) seguem 0 erros (observado em 18/11/2026).
4. **Coletor e tarefa:** formato congelado da pasta de fotos (`us-111-<snapshot>.txt.gz` = texto cru gzip; `indice.txt` com `<snapshot> <built> <arquivo> <itens> <sha256 do texto cru>`; `coletor.log` até 2.000 linhas; idempotente; saída 0 novo/repetida, 2 sha, 1 outro). `sha256`, `baixarTexto`, `lerKv` movidos para `comum.mjs`. `checar-precos` aceita até 25 h num dia (a fonte declarou 24,12 h para 17/11).
5. **`tendencia.mjs`:** `--item <id|nome>` (fotos de hoje e ontem, diário, faixa de 7 dias, percentil inclusivo do mínimo de agora, vendas/dia), `--elasticidade [--min-vendas 800] [--linhas 25]` (gap, ganho com taxa de 5%, gapH com p25 a partir de 12 fotos), `--vigia` (lê o bloco `["vigia"]["itens"]` da SV `CompraForever.lua`); opções `--pasta`, `--precos`, `--sv`, `--hoje`.
6. **Documentação:** `CompraForever\LEIA-ME.md` e `CONTRATO.md` v0.2 (seção 10 com decisões e pendências); `ferramentas\pregao\CONTRATO.md` seções 7 a 9; `comum\referencia\api-forever.md` §3g.1; `estado\estado.md` (decisão, 6 pendências, diário de 18/11/2026); `estado\addons\dev-compraforever.json` em 0.2.0.
7. **Commit** `6c41d9e` em `C:\GMS` (`feat(wow): CompraForever 0.2.0 (vigia de precos e postagem) e coletor horario de precos`), sem push.

## Decisões abertas

1. **Pausar a vigia sem tecla do dono?** Hoje a busca periódica roda enquanto a AH está aberta, sem exigir tecla (I9 da bancada). Opções: (a) manter; (b) pausar depois de N minutos sem tecla ou clique, com uma linha "Watch paused: press any key" no painel; (c) exigir um clique no Scan para cada ciclo. O limite 2 do `CLAUDE.md` da pasta wow (nada de automação ou bot) pesa a favor de (b).
2. **`C_Container.UseContainerItem` na venda ao vendedor** (`Compra.lua`): o `checar-combate.mjs` reprova como R9 ("chamada proibida pelo contrato"), pré-existente da 0.1.0. Ou o contrato do checador ganha exceção para a venda com o vendedor aberto, ou a venda sai do addon.
3. **Métrica do ranking de elasticidade:** o mínimo diário pode ser um lote de 1 unidade mal precificado (Waylaid Crates a 50c no topo). O `gapH` com p25 corrige, mas só a partir de 12 fotos. Decidir se o ranking padrão passa a exigir fotos (ou um mínimo de unidades no degrau mais barato).
4. ~~**Botão caçador, antes do contrato**~~ Fechada pelo agente em 26/11/2026 com os padrões que recomendou (o dono pediu para testar na hora): alvo lote a lote (a cotação só passa se `total <= custo` da escada), trava digitada com o alvo (5g de padrão), alvo pelo `/compra hunt`, lote mínimo fixo em 3, sem aviso de erro de digitação (a trava protege). O dono confirma ou corrige depois do teste. O preço-alvo é sempre do dono.

## Próximos passos concretos

1. **Dono, no jogo (depende de reiniciar o jogo):** `/compra watch` com a Thick Leather colada do inventário (shift-clique) e teto `4s90c`; esperar a seção WATCH mostrar `now`; quando alertar, dois cliques no botão `Buy ... [WATCH]`; conferir o som e o aviso na tela. Depois `/compra sell [Thick Leather] 6s` e, com estoque, o botão `Post ... [SELL]` (um clique por pilha; `Confirm post` se o cliente pedir); anotar qual duração o leilão mostrou para `duration 3`. Se der erro: BugSack.
2. **Agente, depois do teste:** ler a SV (`CompraForever.lua` na pasta de SavedVariables, por `pastaSavedVariables()`; nunca copiar o nome da pasta da conta para um arquivo do projeto) e rodar `node tendencia.mjs --vigia`; gravar o observado em `estado\estado.md` e no `CONTRATO.md` seção 10 (duração confirmada; `OWNED_AUCTIONS_UPDATED` no cliente real).
3. **Agente, se o dono escolher (b) na decisão 1:** implementar a pausa em `Vigia.lua` (sinal de presença: clique nos botões do addon ou um frame com `OnKeyDown` sem propagação) e cenário na bancada.
4. **Amanhã (19/11/2026), com 12 ou mais fotos:** `node tendencia.mjs --elasticidade --linhas 25` e `--item 4304`; comparar com o ranking preliminar; decidir a métrica (decisão 3).
5. **Caça (tarefa #2 do TaskHub), já construída:** o dono, com a AH aberta, `/reload`, `/compra key BUTTON4`, `/compra hunt [Thick Leather] <alvo> <trava>` e aperta; se der erro, BugSack. Depois, o agente lê `CompraForeverCharDB.caca` (gasto, quantidade, registro) na SavedVariables por personagem, confere se o cliente real fez o que a bancada supõe (uma página basta para a ponta barata; `COMMODITY_PRICE_UPDATED` antes do `Confirm`; a busca encadeada sem o I9 do cliente reclamar; a tecla do mouse clicando o botão) e grava em `estado\estado.md` e no `CONTRATO.md` seção 13.
6. **Só se o dono pedir:** `rota.mjs` marcar as 48 receitas que pedem Tanning Rack (lista em `comum\referencia\profissoes-forever.md`, seção Tanning Rack) e aplicar a régua "só se passar de 1g"; decifrar `us-111-flip.txt` e `us-111-plan.txt`; registrar a tarefa agendada também no Acer.

## Como retomar (comandos exatos)

Abra a sessão em `C:\GMS\Claude Code Projects\wow\modder`. Node v24 no Avell; Git Bash para os comandos abaixo.

Bateria inteira (observado com erros=0 em 18/11/2026):

```bash
cd "/c/GMS/Claude Code Projects/wow/modder"
node ferramentas/guia/checar-lua.mjs addons-proprios/CompraForever | grep -v '^ok'
node ferramentas/guia/checar-combate.mjs addons-proprios/CompraForever --toc --prefixos CompraForever,SLASH_COMPRAFOREVER | tail -1   # 1 erro pre-existente (UseContainerItem)
node ferramentas/guia/pregao/bancada-pregao.mjs --addon addons-proprios/CompraForever --cenarios compra | tail -1   # RESUMO cenarios=17 erros=0
node ferramentas/compra/testar-planejador.mjs | tail -1
cd ferramentas/pregao
node testes/testar-coletor.mjs && node testes/testar-tendencia.mjs && node testes/checar-precos.mjs
```

Preços e tendência:

```bash
cd "/c/GMS/Claude Code Projects/wow/modder/ferramentas/pregao"
node baixar-precos.mjs            # pode sair 2 por alguns minutos enquanto o release publico e regravado
node coletar-foto.mjs             # novo | repetida | erro
node tendencia.mjs --item 4304
node tendencia.mjs --elasticidade --linhas 25
node tendencia.mjs --vigia
```

Tarefa agendada (PowerShell):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao\coletor-tarefa.ps1"              # simula e compara
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao\coletor-tarefa.ps1" -Remover
Get-Content "C:\GMS\Claude Code Projects\wow\modder\dados\pregao\publico\fotos\coletor.log" -Tail 5
```

Desligar o addon (jogo fechado): `& "C:\GMS\Claude Code Projects\wow\modder\ferramentas\dev-link.ps1" -Pasta "C:\GMS\Claude Code Projects\wow\modder\addons-proprios\CompraForever" -Remover -Aplicar`.

## Gotchas

- **Reiniciar o jogo** depois de arquivo novo no TOC; `/reload` não carrega `Vigia.lua` nem `Venda.lua`.
- **`ate_ocioso` da bancada nunca termina** com a AH aberta e item vigiado (o timer da vigia é perpétuo): os cenários usam `avancar <s>`.
- **I9 na bancada:** cenário com vigia ativa precisa de `aceita_violacoes = true` e, no `conferir`, exigir zero violações dos outros tipos (I1, hardware).
- **Preço no `/compra post` sem espaço** (`6s09c`, não `6s 09c`): o parse é `<preco> [qtd]`.
- **O release público é regravado aos poucos:** `baixar-precos` e `coletar-foto` saem com 2 quando o SHA não bate; o coletor espera 20 s e tenta mais uma vez. Não é bug.
- **`conhost`/`-WindowStyle Hidden` abrem janela no Windows 11 desta máquina;** a tarefa usa `wscript //B` com o `.vbs`. O resultado da tarefa no Agendador é sempre 0: diagnóstico pelo `coletor.log`.
- **O painel mostra "Scanning" por alguns segundos a cada ciclo da vigia** e o botão de ação fica "Scanning..." nesse intervalo.
- **A vigia zera escadas e alertas a cada abertura da AH**; o histórico na SV fica.
- **Outra sessão no mesmo repositório** (frente `waylaid-crates`, mesmo addon): commit por caminho; confira o `git status` antes.

## Estado do repo e da plataforma

- **`C:\GMS`** (branch `main`): HEAD `6c41d9e` "feat(wow): CompraForever 0.2.0 (vigia de precos e postagem) e coletor horario de precos". Sem push. A máquina "escritorio" não fez o sync de saída desde 16/11/2026 (aviso de sincronização de 18/11/2026): rode o Sincronizar antes de trabalhar no outro notebook.
- **Commitados logo depois deste texto:** este handoff e o `HANDOFFS.md` (`docs: handoff vigia-precos`).
- **26/11/2026:** a atualização do pedido do botão caçador (este handoff, o `HANDOFFS.md` e o `estado\estado.md`) depende do ok do dono para o commit; a tarefa #2 vive no TaskHub (log de eventos no Google Drive), fora do repositório.
- **Invisível ao repositório:** a tarefa agendada `GMS WoW Precos Hora` no Agendador do Avell; `modder\dados\pregao\` (fotos, `precos.json`, cache das tabelas do cliente); a junction `Interface\AddOns\CompraForever`; a SV `CompraForeverDB` (ainda sem o bloco `vigia`, que nasce no primeiro login com a 0.2.0).
- **Fonte externa:** `RuslanMunasipov/quest-murder-prices`, release `current` (foto perto do minuto 25 UTC, índice uns 15 min depois). Terceiro, sem garantia.

## Referências rápidas

| Preciso de | Onde |
|---|---|
| Uso do addon para o dono (comandos, fluxo WATCH/SELL) | `addons-proprios\CompraForever\LEIA-ME.md` |
| Contrato do addon, SV, ordem de `acaoLeilao`, cenários, decisões (seção 10) | `addons-proprios\CompraForever\CONTRATO.md` |
| Coletor, tarefa agendada e tendência | `ferramentas\pregao\CONTRATO.md`, seções 7 a 9 |
| Assinaturas de postagem e eventos | `comum\referencia\api-forever.md`, §3g.1 |
| Tanning Rack e as 48 receitas | `comum\referencia\profissoes-forever.md`, seção Tanning Rack |
| Diário, decisões e pendências | `estado\estado.md` (linhas de 18/11/2026) |
| Frentes vizinhas | `HANDOFF-crafts-que-pagam.md`, `HANDOFF-waylaid-crates.md`, `HANDOFF-pregaoforever.md` |
| Limites fixos e relatório de sessão | `C:\GMS\Claude Code Projects\wow\CLAUDE.md` |
