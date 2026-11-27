> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# D5-ouro: PregaoForever em fatia fina, a régua e a fila para sair de 5 ouro

Data: 2026-11-16. Etapa de design: nenhuma linha de addon foi escrita. Ângulo: a fatia mais fina que faz ouro esta semana com 5 ouro e personagens de nível baixo.

Como ler. `(base N.M)` e `(Rxx §n)` apontam o fato na base de fatos ou num relatório. **H:** marca hipótese, sempre seguida do jeito de medir. Números de configuração (limiares, tetos, teclas) são escolhas de projeto: vivem no `Config.lua` e não são fatos do jogo. Itens e valores desenhados nas telas são ilustrativos.

## 1. Tese

### 1.1 De onde vem o lucro

O mercado é um mega-reino por conjunto de regras, com mais de 200 mil leilões numa varredura relatada (base 1.2), oferta listada subindo 63% e mediana caindo 41% na segunda semana (base 6.1), e ferramentas prontas nas mãos dos concorrentes: TSM 4.15, ForeverFlip, snipers e varredores (base 5.1 a 5.3). Para quem tem pouco capital há três bolsos de lucro. Os 50.912 cobre do dono (base 4.1) alcançam os dois primeiros já, e o terceiro só com prova:

1. **Erro abaixo do piso.** Anúncio abaixo do que o vendedor NPC paga pelo item. O lucro por unidade é pequeno e certo: sem corte, sem depósito, sem espera de venda (R9 §5.4). O capital volta no tempo de ir ao correio e ao vendedor.
2. **Preço certo no que o dono já tem.** Drops, verdes e sobras de coleta de quatro personagens (base 4.2). Em risco fica só o depósito. O ganho é a diferença entre vender bem e vender mal: leilão ou vendedor, que duração, que preço. Pesa esta semana porque o depósito mínimo cai de 1 prata para 1 cobre na manutenção de 17/11 (base 1.7).
3. **Vão de preço em commodity barata.** Comprar a frente da escada e repostar no vão (R8a ficha 2; R9 §5.3). Cabe em 5 ouro só em lote pequeno e prende o capital até vender mais cerca de 1 hora de correio (base 1.8).

Fora do alcance de 5 ouro: reset (R9 §6.3: valor esperado negativo em item líquido no modelo pessimista; R8a ficha 4: folclore), formação de mercado (sem fonte, R8a ficha 3), sniper de item caro e estoque para a raide de 9/12 (base 6.4).

**A tese.** Com 5 ouro o gargalo é giro, não informação: lucro do dia = capital × margem × voltas. A frente da fila é de quem tem capital e repostagem barata (R9 §3.1: a posição na frente é passageira; R9 §9.3: guerra de cobertura é desgaste, e cada repostagem nossa custa uma tecla, base 2.13). O dono não vence essa guerra hoje. Ele ganha onde o dinheiro volta rápido e o risco é zero ou medido. Por isso o desenho ordena as oportunidades pelo **tempo até o dinheiro voltar** e pelo **cobre por tecla**, e não pela margem.

A segunda metade da tese: ninguém sabe quanto isso rende no Forever. A base não tem medida de lucro de leilão com banca pequena; os números de ouro por hora que existem são de farm, estimados por quem vende ouro (R5b §2c). Então o primeiro produto não é o motor, é a **régua**: um razão que mede cobre por tecla, cobre por hora e voltas do capital, por estratégia e por ferramenta, e troca cada estimativa do jogo por número lido.

### 1.2 Construir contra adotar, peça por peça

O que a base não descreve de uma ferramenta não instalada é incógnita, não defeito dela.

| Peça | Existe pronta | Veredito | Motivo |
|---|---|---|---|
| Preço por item, último mínimo visto | Auctionator 341, instalado, com API pública e cerca de 6.600 itens (base 7.1, 4.3) | Adotar | Custo zero; prévia de preço por `pcall` |
| Postar e cancelar o próprio estoque | Auctionator, TSM 4.15, ForeverFlip, aux-forever (base 5.1 a 5.3) | Adotar hoje; tecla própria só na onda 4 | Faz ouro hoje sem código |
| Varredura completa, sniper, ofertas | ForeverFlip (MIT), sniper do autor do Auctionator (base 5.2, 5.3) | Não construir; reavaliar na fase 3 | `ReplicateItems` não respondeu na máquina do dono em 14/11 e os relatos dão uma por 15 minutos (base 2.5); com 5 ouro o sniper não tem o que comprar |
| Contabilidade | Módulo do ForeverFlip; addon do autor do Auctionator, com issues abertas de Forever (R6a §2.2) | Construir, pequeno | Precisa medir por estratégia e por tecla e ler corte, depósito e correio como parâmetros |
| Fila do que fazer agora, sob banca pequena e tempo de caixa | Não consta na base | Construir | É o diferencial |
| As quatro regras do dono juntas: configuração em arquivo, tela de 5 linhas, estratégia com fonte e desligada, uma tecla por ação | A base não descreve ferramenta que atenda às quatro; o TSM pede do jogador expressões de preço por grupo de itens (base 5.8) | Construir | Regras 3 e 4 do projeto |

O veredito honesto: quase tudo o que um terminal de trading faz já existe, e uma das ferramentas tem licença MIT (base 5.2). O menor addon próprio que dá ao dono algo novo é **régua mais fila**: cerca de 3 mil linhas de Lua (estimativa), sem varredura completa, sem base de preços além de um anel curto, sem tela de configuração. A régua lê eventos do jogo, então mede igualmente o que o dono fizer pelo Auctionator, pela tela da Blizzard ou pela fila própria, e a escolha entre adotar e construir sai de um número (decisão 3).

### 1.3 Por que este desenho captura o lucro

- A consulta resumida devolve o menor preço e a quantidade de cada chave de item (base 2.1); um autor relata 7.718 itens em 8,5 segundos e 16 pedidos (base 2.6, não conferido). Uma tecla, cerca de 10 segundos para o resumo e mais alguns para as escadas dos candidatos. **H:** tempo e pedidos valem na conta do dono. Medir: a primeira varredura grava os dois.
- O preço de vendedor é lido do cliente na hora (`C_Item.GetItemInfo`, 11º retorno, base 3.2), que é o que a base 6.3 pede depois das baixas por hotfix. **H:** o valor lido já reflete o hotfix. Medir: ouro recebido no vendedor contra o previsto, por item.
- A fila tem no máximo 5 linhas que cabem na banca agora, cada uma com a sua tecla, e o razão fecha cada lote com o ouro recebido de fato.

### 1.4 O que os fatos sustentam e o que não sustentam

Sustentam: um mercado enorme e em queda (base 6.1); preços de vendedor que a Blizzard mexeu (base 6.3); uma API que deixa ler tudo o que a fase 1 precisa (base 2.1, 2.3, 2.9, 2.10, 3.1). Não sustentam: taxa de retorno, contagem de anúncios abaixo do vendedor, nem a prova de que a tecla por binding satisfaz o evento de hardware (base 11.1). Por isso não há meta de ouro prometida. Há marcos de banca (15 ouro abre a fase 2 ao vivo, 60 ouro abre a fase 3) e, em cada etapa, um resultado medido e um limiar de parada (parte 9). A montaria do nível 40 custa cerca de 100 ouro (base 6.2), pouco mais de quatro dobras da banca; a régua dirá na primeira semana quanto tempo custa uma dobra.

### 1.5 O que este ângulo sacrifica

- **Profundidade estatística.** Sem valor justo, tabela de probabilidade de venda, sazonalidade ou perfil de concorrente nas fases 1 e 2.
- **Cobertura.** Sem varredura completa nem histórico largo: a fase 1 vê menor preço, quantidade e a escada de poucos itens.
- **Teto.** Lucro de piso é cobre e prata. A fatia fina não é "day trading pesado"; é a escada para chegar lá com dinheiro do próprio mercado.
- **Tempo do dono.** O piso exige ir ao correio e ao vendedor. Se o cobre por hora perder para jogar e coletar, sobra um otimizador de venda do próprio estoque.
- **Reescrita.** Parte do motor da fase 1 será trocada quando a banca crescer. Mitigação: contrato por módulo e dado bruto dos itens em foco gravado desde o primeiro dia.

## 2. Escopo

- **Fase 1, Piso (esta semana; liga com a decisão 1 do dono).** Sonda dos parâmetros do jogo. Varredura resumida por tecla. Lista do piso (leilão abaixo do vendedor) com compra por tecla. Veredito de venda do próprio estoque (leilão, vendedor ou guardar) com preço, duração e depósito lidos, e postagem por tecla. Leilões próprios: estado e cancelamento por tecla. Correio: lê as faturas. Razão, diário e painel de sessão.
- **Fase 2, Vão (liga com banca de 15 ouro, parâmetros medidos e prova em sombra).** Escadas dos itens em foco (até 40 chaves). Flip no vão, primeiro em sombra. Conversão com as profissões do personagem logado. Cancelar e repostar pela regra do R9 §4.6 com números medidos. Valor de triagem pelo próprio anel de mínimos diários.
- **Fase 3, Pregão (liga com banca de 60 ouro e 14 dias de anel).** Sniper com valor próprio, lance em leilão acabando, tempo, estoque para raide, mesa externa de calibração, e a decisão de aproveitar código MIT ou adotar ferramenta pronta.

**Nunca faz, em fase nenhuma:** agir sem tecla ou clique do dono; mais de uma ação restrita por tecla; chamar ação a partir de timer, evento ou `OnUpdate`; ligar ação à roda do mouse; simular entrada; qualquer coisa que evite a marca de ausente; contornar função protegida, evento de hardware ou valor secreto; vender ao vendedor, comprar do vendedor, enviar correio ou ouro por código; ler código de addon de terceiro; configurar algo por tela dentro do jogo; mostrar fonte na tela; postar preço fora de mercado; comprar leilão da própria conta; transmitir dados para fora do jogo.

## 3. Arquitetura

### 3.1 Módulos e ordem de carga

Pasta `wow/modder/addons-proprios/PregaoForever`; TOC com `## Interface: 16001`, `## Author: Guilherme`, `## SavedVariables: PregaoForeverDB` e `## OptionalDeps: Auctionator, Syndicator, Baganator, ElvUI` (base 4.8). Todos os arquivos, inclusive os das fases 2 e 3 como esqueleto vazio, entram no `.toc` na onda 1: arquivo novo ou `.toc` alterado pede reinício do jogo, `.lua` alterado só pede `/reload` (R4a §6).

Ordem de carga; os arquivos 1 a 21 são da fase 1.

1. `Config.lua`: única configuração, escrita pelo agente (estratégias ligadas, limites, teclas, reservas).
2. `Nucleo.lua`: `ns`, `ns.seguro` (xpcall), barramento de eventos, relógio, dinheiro, anéis, migração do banco, log de 60 linhas.
3. `Parametros.lua`: parâmetros do jogo com origem (estimado ou medido, n amostras).
4. `Triagem.lua`: dado gerado do `ItemSparse` (base 9.1), preço de vendedor por item. Só triagem; o preço que decide é lido ao vivo.
5. `Pedidos.lua`: porta única das consultas. Uma por vez, espera resposta ou prazo, respeita throttle e orçamento, grava a cadência.
6. `Itens.lua`: cache de item (preço de vendedor ao vivo, pilha, qualidade, commodity ou item, carga assíncrona).
7. `Carteira.lua`: ouro livre, preso em leilões, em trânsito no correio; estoque marcado; slots livres.
8. `Varredura.lua`: máquina da consulta resumida.
9. `Escada.lua`: foto da escada de um item (commodity ou leilões), em texto compacto.
10. `Estrategias.lua`: registro das estratégias (sinal, regra, condição, modo sombra). Todas nascem desligadas.
11. `Motor.lua`: contas (valor de uma tentativa, ponto de equilíbrio, valor esperado), lote, montagem da fila.
12. `Guardas.lua`: tetos, disjuntores, recusas, checagens contra padrão de RMT.
13. `Acoes.lua`: fronteira do evento de hardware. O único arquivo que chama as 7 funções restritas e `ConfirmCommoditiesPurchase`.
14. `Correio.lua`: lê cabeçalhos e faturas da caixa e casa com o razão.
15. `Razao.lua`: lotes, ações, sessões, resultado por estratégia e por tecla; diário de calibração.
16. `Sonda.lua`: mede as incógnitas da base 11 e preenche `Parametros`.
17. `Pontes.lua`: interoperação por `pcall` com `Auctionator.API.v1`, Syndicator, Baganator e a skin do ElvUI (base 7).
18. `Visual.lua`: cópia do kit visual do dono (`ns.ui`, base 7.5).
19. `Tela.lua`: janela própria, visões, alertas.
20. `Teclas.lua`: bindings de sobreposição enquanto a janela está aberta.
21. `Comandos.lua`: `/pregao`, `/pregao probe`, `/pregao end`.
22. `Sombra.lua` (fase 2): preenchimento hipotético do modo sombra.
23. `Conversao.lua` (fase 2): custo recursivo raso.
24. `Valor.lua` (fase 3): valor justo.
25. `Lances.lua` (fase 3): lance.

### 3.2 Fluxo dos dados

```
tecla F5 -> Varredura -> Pedidos -> C_AuctionHouse (leitura) -> eventos
   -> resumo (menor preco, quantidade) x Triagem -> candidatos
   -> Escada (ate 20 fotos) + Itens (preco de vendedor ao vivo)
   -> Estrategias (sinais) -> Motor (valor, lote) -> Guardas -> fila (5 linhas)
   -> Tela  --tecla F6 do dono-->  Acoes (1 funcao restrita)
   -> eventos de resultado -> Razao + Carteira + Sonda -> Motor recalcula
correio aberto -> Correio (faturas) -> Razao (fecha lotes) -> Parametros
```

A janela é própria: abre com `AUCTION_HOUSE_SHOW`, fecha com `AUCTION_HOUSE_CLOSED` e não cria aba no `AuctionHouseFrame`, que traz risco de taint nas bolsas (base 7, último parágrafo). **H:** como a lista da Blizzard relê `GetBrowseResults()` a cada evento de resultado (R1b §8), a aba de busca dela passa a mostrar a nossa varredura, e uma consulta de outro addon no meio reinicia a lista. Medir: lista que encolhe entre duas respostas marca a varredura como incompleta.

### 3.3 Máquinas de estado

Regra comum: **foto velha, a tecla atualiza; foto fresca, a tecla age.** Nenhuma tecla gasta sobre dado com mais de 30 segundos. Toda ação restrita sai de dentro do `OnClick` de um botão comum, `PregaoForeverBotaoAgir`, que a tecla aciona por `SetOverrideBindingClick` (base 3.4, 8.1). `Acoes.lua` abre uma ficha no começo do clique e a consome na primeira chamada restrita; segunda chamada no mesmo clique é erro de programa. Pressão a menos de 250 ms da anterior é ignorada, e tecla presa vale uma ação.

```
VARRER (base 2.1)                                   1 tecla = 1 varredura
PARADA --[F5]--> PEDINDO   SendBrowseQuery (texto vazio, ordem por preco)
PEDINDO --BROWSE_RESULTS_UPDATED/_ADDED--> LENDO   (500 linhas por quadro)
LENDO --falta resultado--> PEDINDO   RequestMoreBrowseResults, 1 por resposta
LENDO --HasFullBrowseResults--> TRIANDO --> PRONTA (t, completa)
* --BROWSE_FAILURE | sem resposta em 60 s | lista encolheu--> INCOMPLETA
     (nao gera sinal; a tela pede F5 de novo)
* --AUCTION_HOUSE_CLOSED--> PARADA

COMPRAR COMMODITY (base 2.7)                        2 teclas: cotar, comprar
PARADA --[F6, tecla 1 do dono]--> guardas; escada fresca?
     velha : Pedidos refaz a escada; linha volta a PARADA ("Refreshed")
     fresca: StartCommoditiesPurchase(itemID, n) --> COTANDO
COTANDO --COMMODITY_PRICE_UPDATED--> COTADA  (total, teto, segundos restantes)
COTANDO --PRICE_UNAVAILABLE | 5 s--> FALHOU
COTADA  --total > teto--> RECUSADA   CancelCommoditiesPurchase; recalcula
COTADA  --[F6, tecla 2 do dono]--> ConfirmCommoditiesPurchase --> COMPRANDO
COTADA  --[F7] | cotacao venceu | janela fechou--> CancelCommoditiesPurchase
COMPRANDO --PURCHASE_SUCCEEDED--> FEITA   razao, carteira, escada nova
COMPRANDO --PURCHASE_FAILED | SHOW_ERROR | 10 s--> FALHOU

COMPRAR ITEM (base 2.8)                             1 tecla
PARADA --[F6, tecla do dono]--> PlaceBid(auctionID, arremate) --> COMPRANDO
COMPRANDO --PURCHASE_COMPLETED(auctionID)--> FEITA
COMPRANDO --SHOW_ERROR | 10 s--> FALHOU

POSTAR (base 2.9)                                   1 tecla; 2 se houver aviso
PARADA --[F6, tecla 1 do dono]--> IsSellItemValid, status de commodity,
     deposito lido <= ouro, IsThrottledMessageSystemReady, escada fresca
     falta algo: mostra o motivo, nada e chamado, espera nova tecla
     tudo certo: PostCommodity ou PostItem --> needsConfirmation?
       nao: POSTANDO
       sim: AVISADA --[F6, tecla 2 do dono]--> ConfirmPost* --> POSTANDO
            AVISADA --[F7] | 20 s--> CancelSell --> PARADA
POSTANDO --AUCTION_HOUSE_AUCTION_CREATED--> FEITA   razao guarda id, preco,
     duracao, deposito e fila na frente
POSTANDO --POST_ERROR | SHOW_ERROR | 10 s--> FALHOU

CANCELAR (base 2.10)                                1 tecla
PARADA --[F6, tecla do dono]--> CanCancelAuction, GetCancelCost <= teto
     --> CancelAuction(id) --> CANCELANDO
CANCELANDO --AUCTION_CANCELED(id)--> FEITA
CANCELANDO --SHOW_ERROR | 10 s--> FALHOU
```

Os eventos de falha usados acima, `IsSellItemValid` e `CancelSell` estão no contrato (R1a §1 e §4).

Throttle: `Pedidos.lua` só envia com `IsThrottledMessageSystemReady()` verdadeiro, mantém uma consulta pendente por vez, limita `SendSearchQuery` a 60 por minuto (o documento da função fala em 100, base 2.2) e grava os cinco eventos de throttle com hora (base 2.14). Se o sistema ficar "não pronto" por 30 segundos (relato de fila travada, base 2.14), a tela diz `Throttle stuck: close and reopen the Auction House` e nada é reenviado. Na postagem, throttle não pronto consome a tecla sem agir, e quando o sistema fica pronto o addon **não** dispara sozinho: o dono aperta de novo.

Ação sem resposta: as 7 funções restritas não dão erro quando a precondição falha, só não fazem nada (base 2.12). O prazo de 10 segundos vira `No response` no diário, sem nova tentativa automática; três seguidas abrem o disjuntor. Repostar não é uma ação: é cancelar (uma tecla), recolher o item no correio (clique do dono) e postar (uma tecla).

### 3.4 SavedVariables

Um banco de conta, porque os quatro personagens estão na mesma facção e na mesma casa (base 4.2, 1.3).

```lua
PregaoForeverDB = {
  esquema = 1,
  par     = { corte = { v = 0.05, n = 0, medido = false }, ... },
  itens   = { [itemID] = "vend:conf:tipo:pilha" },      -- so itens tocados
  resumo  = { t = 0, completa = false, n = 0, dados = "..." },
  dias    = { [chave] = "dia:min:qtd;..." },             -- 14 dias, 1.500 chaves
  escadas = { [chave] = { "t|p:q:n,p:q:n" } },           -- 16 fotos, 40 chaves
  razao   = { lotes = {}, acoes = {}, sessoes = {} },
  sombra  = {},  diario = {},  bruto = {},  log = {},
}
```

Tamanho estimado:

- `resumo`, a última varredura: 7.718 chaves (base 2.6) × 12 bytes = 95 KB.
- `dias`: 1.500 chaves × 14 dias × 10 bytes = 210 KB.
- `escadas`: 40 chaves × 16 fotos × 200 bytes (12 degraus, R9 §11.4) = 130 KB.
- `razao`: 2.000 ações × 80 bytes mais 500 lotes × 120 bytes = 220 KB.
- `sombra`: 1.000 sinais × 100 bytes = 100 KB.
- `diario` (400 linhas, como o `MAX_DIARIO` do projeto, R4a §7) e `log`: 40 KB.
- `bruto`, 3 varreduras cruas para replay, só na primeira semana: 285 KB.
- **Total: cerca de 1,1 MB, com teto duro de 2 MB e poda do mais antigo.**

Referência: o arquivo do Auctionator do dono tem 561 KB (R4b §2). **H:** 1 MB a mais não alonga o `/reload` de forma perceptível. Medir: cronometrar antes e depois. O banco só vai ao disco no `/reload`, no logout e ao fechar (base 3.9): a tela mostra `Unsaved: N actions`, e o fecho de sessão é um `/reload` pedido pelo dono. Se o cliente cair, o razão se reconcilia no próximo login pelo ouro, pelos leilões próprios e pelo correio, e marca as linhas como `unreconciled`.

### 3.5 Parte fora do jogo

Não há aplicativo companheiro. A parte de fora é a sessão do agente, com dois contratos.

**Entrada: `Config.lua`.** O agente edita o arquivo na pasta de desenvolvimento, ligada ao jogo por junction criada uma vez com o jogo fechado (base 4.9), e o dono dá `/reload`, o ciclo normal do projeto (base 4.11).

```lua
local _, ns = ...
ns.cfg = {
  versao = 1,
  teclas = { varrer = "F5", agir = "F6", pular = "F7", visao = "F8" },
  estrategias = {
    piso         = { ligada = false, sombra = true },
    venda_verdes = { ligada = false },
    venda_sobras = { ligada = false },
    vao          = { ligada = false, sombra = true, banca_min = 150000 },
    conversao    = { ligada = false, sombra = true },
  },
  limites = { lote = 0.20, risco = 0.50, reserva = 0.20, perda_dia = 0.10,
              ticket = 15, margem = 0.15 },
  reservas = {},        -- [itemID] = quantidade que nunca vai a venda
  venda = { equipamento = "igualar", commodity = "cobrir" },
}
```

**Saída: `PregaoForeverDB`.** Depois de um `/reload`, o agente lê o arquivo de SavedVariables, só leitura, com `ler-diario.mjs`, ferramenta nova do projeto que converte o banco em JSON.

Ciclo: sessão do dono, `/reload`, o agente lê e calcula, escreve `Config.lua`, o dono dá `/reload`. O que é **leitura do cliente** (corte na fatura, depósito, atraso do correio) o addon adota sozinho e mostra na visão Probe; o que é **juízo** (limiar, margem, ligar estratégia) só muda pelo `Config.lua`, com aprovação do dono.

## 4. Motor

### 4.1 O que vem do R9

| Peça do R9 | Destino | Motivo |
|---|---|---|
| Valor de liquidação como moeda comum (§4.1) | **Simplificado** para o valor de uma tentativa (4.2) | Sem P calibrada, o termo (1−P)/P explode; a fonte aprovada só sustenta "verde bom vai ao leilão" (base 4.5) |
| Preço não depende do custo de aquisição (§4.1) | **Adotado** | Marca o estoque pelo mercado de agora |
| Arbitragem contra o vendedor (§5.4) | **Adotado** como está | É a estratégia da fase 1 |
| Teste único de compra, com saída na escada pós-compra (§5.1) | **Adotado** na fase 2 | Separa pechincha de preço novo |
| Fila por valor esperado por clique (§5.1) | **Adotado**, com restrição de capital | A tecla é o segundo gargalo; o capital é o primeiro |
| Desconto do realizado sobre o previsto (§5.7) | **Adotado** | 1,0 no piso (sem risco de preço), 0,5 no resto; o razão troca |
| Modo sombra (§10.4) e disjuntores (§7.5) | **Adotados** | A sombra é como o dado do addon vira evidência (regra 3); disjuntores na parte 7 |
| Vendas mínimas pela diferença de escadas (§2.1) | **Adotado** na fase 2, só nos itens em foco, sem a correção de viés | O limite inferior basta para dizer se vende |
| Valor justo com média aparada, EWMA e Huber (§1) | **Trocado**, na fase 2, pela mediana dos mínimos diários do anel (ideia pública do aux, base 5.8) | Só há mínimo e quantidade para a maioria dos itens. É triagem; quem decide gasto é a escada |
| Kelly (§7.2) | **Trocado** por frações fixas | Com média e variância sem medir, Kelly é sensível demais (R9 §7.7) |
| Custo de atenção em cobre por segundo (§12.C) | **Trocado** por tíquete mínimo por tecla | O alvo de ouro por hora do dono é desconhecido; o razão mede segundos por ação |
| Tabela de P(venda), sazonalidade, regime, concorrentes, reset (§3.2f, §6, §8, §9) | **Fora** das fases 1 e 2 | Pedem semanas de fotos densas |

### 4.2 As contas da fase 1

Notação: preços em cobre; `v` = preço de vendedor por unidade, lido ao vivo; `c` = corte; `d` = depósito do lote, sempre lido de `CalculateItemDeposit` ou `CalculateCommodityDeposit` (base 1.4), nunca estimado; `du = d/n`; `rs`, `rx` = fração do depósito devolvida na venda e na expiração.

**Piso (comprar no leilão e vender ao vendedor).** Sobre a escada fresca, comprar os degraus enquanto `p_j <= v − folga`:

```
EV     = soma( (v − p_j) · q_j )                 sem corte, sem deposito
teclas = 2 por compra de commodity, 1 por leilao de item, +1 clique de venda por pilha
aceita se  EV / teclas >= ticket   e   custo <= ouro livre − reserva
teto da cotacao = n · (v − folga)       acima disso a tecla 2 e recusada
```

O teto é o do motor, não os 5% que a tela da Blizzard tolera (base 2.7; `MAXIMUM_PREVIEW_PRICE_DIFFERENTIAL = 1.05` no espelho, `Blizzard_AuctionHouseBuyDialog.lua:3`): no piso, qualquer alta come o lucro inteiro.

**Venda do próprio estoque (uma tentativa, com saída no vendedor).**

```
W1(p, D) = P · ( p·(1−c) − (1−rs)·du ) + (1−P) · ( v − (1−rx)·du )
postar se  max sobre (p, D) de W1  >=  v + max(ticket/n, margem · v)
ponto de equilibrio (rs = 1, rx = 0):   P* = du / ( p·(1−c) − v + du )
```

A tela mostra `P*` em palavras (`needs 18%`), o número que o dono consegue julgar. Exemplo com a leitura provável da base 1.4 e 1.7 (**H**, medir pelo depósito lido): verde com `v` de 50 cobre e menor preço de 2 prata, 24 horas. Hoje o depósito seria o mínimo de 1 prata, e `P* = 100/(190 − 50 + 100) = 42%`. Depois de 17/11, 60% de 50 cobre dá 30 cobre, e `P* = 30/170 = 18%`. A manutenção muda o veredito de muitos itens baratos; a sonda relê o depósito na primeira sessão depois dela.

Candidatos de preço: cobrir o primeiro degrau por um tick ou igualá-lo (R9 §4.2, reduzido a dois). Equipamento sempre iguala, porque postar abaixo do menor preço dá "Internal Auction Error" e o contorno relatado é igualar (base 1.11). O tick é 1 cobre se `SupportsCopperValues()` for verdadeiro, senão 1 prata (R1b §7). Duração: a de maior `W1` entre os índices 1, 2 e 3 (2, 8 e 24 horas, base 1.5).

**Ordenação da fila.** `giro = EV / (custo · T_caixa)`, com `T_caixa` medido: no piso, o tempo de correio e vendedor da sessão; na venda, o tempo até vender mais o atraso do correio. Entram as linhas que passam no tíquete, por ordem de EV por tecla e desempate por giro, até esgotar o ouro livre.

**Tamanho.** Lote de até 20% da banca; soma em risco de preço de até 50%; 20% de reserva para depósitos; o piso pode usar o resto, por não ter risco de preço. Primeira compra de cada item no piso: lote de sondagem de até 2% da banca, até o preço de vendedor do item ser confirmado numa venda real.

### 4.3 Valores iniciais e a troca por número medido

- **Corte `c`:** 0,05, a leitura provável da base 1.4. Medido na primeira fatura (`consignment / bid`); vale a mediana com n ≥ 3.
- **`rs`, `rx` e reembolso no cancelamento:** 1, 0 e 0, a regra do Classic repetida pelas fontes (base 1.7). Medidos no primeiro leilão vendido, expirado e cancelado.
- **Atraso do correio:** 60 minutos (base 1.8). Medido na primeira venda (`moneyDelay` da fatura e hora observada).
- **Entrega do item comprado:** **H:** imediata. Existe o evento `AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE` (R1a §4, evento 10). Medir: primeira compra.
- **Ordem entre preços iguais:** pior caso (R9 §12.A), por ser incógnita (base 2.17). Medida com 5 observações passivas concordantes.
- **P de vender na frente em 2, 8 e 24 horas:** 0,25, 0,45 e 0,65. **Sem fonte: hipótese.** Trocada pela frequência própria por classe e duração, com prior de peso 4.
- **Idade máxima da foto:** 30 segundos (R9 §12.C). Calibrada pela taxa de "já tinha sumido".
- **Tíquete por tecla e margem das linhas com risco:** 15 cobre e 0,15 (o R9 usa 0,10), escolhas de projeto. Calibrados pelo cobre por tecla medido e pelo realizado sobre o previsto.
- **Perda máxima do dia:** 10% da banca abaixo de 15 ouro e 5% acima (o R9 §7.5 usa 5%). Decisão do dono.
- **Prazos de cotação, resposta, varredura e throttle preso:** 5, 10, 60 e 30 segundos, escolhas de projeto. Trocados por duas vezes o percentil 95 medido.

O diário de calibração segue o padrão do projeto (base 4.9): o addon grava o sinal cru do cliente e o número medido substitui a estimativa. Os sinais gravados:

- **Fatura de venda** (`bid`, `buyout`, `deposit`, `consignment`, `moneyDelay`, de `GetInboxInvoiceInfo`; base 3.1, ordem dos retornos no espelho em `Blizzard_MailFrame/MailFrame.lua:790`): corte, `rs` e atraso.
- **Depósito nos três índices de duração** e ouro antes e depois de postar e cancelar (`GetMoney`): confere a leitura de 5%, 20% e 60% (base 1.4), se o cobrado é o lido, e o custo de cancelar. O correio "Auction expired" (base 1.8) dá `rx`.
- **Hora de pedido e de resposta por tipo**, ação sem resposta e os eventos `ADDON_ACTION_BLOCKED` e `ADDON_ACTION_FORBIDDEN` (R1c, extra): prazos, cadência e a base 11.1.
- **Campos das escadas**: `owners` preenchido ou não, `timeLeftSeconds` nulo ou não (base 11.5), `isCommodity` por item (base 11.2), e a quantidade própria contra a do degrau em fotos seguidas (`numOwnerItems`, base 2.3), que revela a ordem entre preços iguais.
- **Ouro recebido no vendedor** contra o previsto (`PLAYER_MONEY`, R1c §4): preço de vendedor confirmado por item.
- **Segundos entre teclas**: o custo real de uma ação.

## 5. Estratégias

Todas nascem com `ligada = false`. A fonte fica no `Config.lua` e no `ARQUITETURA.md`, nunca na tela. "Sombra": o addon grava a recomendação e o que teria acontecido, sem o dono agir (R9 §10.4).

| Id | Estratégia e fase | Fonte | Sinal mensurável | Regra | Risco | Condição para ligar |
|---|---|---|---|---|---|---|
| E1 | **Piso do vendedor** (1) | R8a ficha 5 (guia genérico F17 e recurso "vendor flips" de terceiros: confiança baixa, nenhuma fonte de Forever). A conta é R9 §5.4 | Por varredura: cobre disponível abaixo do preço de vendedor e número de chaves; depois, taxa de "já tinha sumido" | 4.2, piso | Preço de vendedor mudado por hotfix (base 6.3); bug "item not found" (base 1.11); item sem valor de venda; bolsa cheia; tempo de ir ao vendedor | Aprovação do dono; 3 varreduras em horários diferentes com pelo menos 30 cobre disponíveis cada; preço de vendedor confirmado em 3 itens |
| E2a | **Venda de verdes** (1) | Vídeo do Studen Albatroz, a única fonte aprovada (base 4.5): verde bom vai ao leilão | `P*` do item contra a frequência de venda medida | 4.2, venda | Depósito perdido; erro ao postar equipamento abaixo do mínimo (base 1.11) | Fonte já aprovada; pede só o sim do dono |
| E2b | **Venda de sobras de coleta** (1) | R8b ficha 5: R4 (vender cru, do beta), R8 (nunca abaixo do vendedor), R7 (lotes e rechecagem), R15 (leilão curto para o que vende rápido). Guias de fã ou comerciais | Idem, mais a quantidade na frente | 4.2, venda; a lista `reservas` protege o que alimenta as profissões do dono (o couro do Hexumlite segue o roteiro do Leatherworking, R4b §4) | Queda de preço da semana (base 6.1); cobertura em minutos (R8b ficha 1, editorial) | O dono escolhe a fonte e aprova |
| E3 | **Flip no vão** (2) | R8a ficha 2 (fã F5, guia genérico F17, coluna de 2011 F20); alerta de isca em F23 | Razão entre o degrau seguinte e o preço médio pago acima de `(1 + margem)/(1 − c)` mais custos (R9 §5.3); vendas mínimas maiores que zero em duas diferenças de escada | Comprar até 20% da banca e repostar um tick abaixo do degrau seguinte | O vão fecha; isca com parede acima (R9 §9.2); depósito perdido | 30 sinais em sombra com realizado hipotético de pelo menos metade do previsto; banca de 15 ouro; corte, `rx` e ordem de empate medidos |
| E4 | **Conversão com profissão própria** (2) | R8a ficha 6 (addon Arbitrage F11; guias de outras versões) | Lucro do R9 §5.5 com insumo e produto lidos das escadas; receita de `C_TradeSkillUI.GetRecipeSchematic` (base 3.7) | Só produto que não vincula: equipamento fabricado vincula ao pegar (R4b §5e) | Produto sem saída; rendimento desconhecido em 526 receitas (base 9.2); preço de vendedor do produto baixado (base 6.3) | 20 sinais em sombra; o personagem tem a receita; aprovação |
| E5 | **Sniper por arremate** (3) | R8a ficha 1 (documentação do TSM de 2022; nenhuma fonte de Forever) | Preço contra o valor do próprio anel | R9 §5.2 | Valor velho; preço novo, não pechincha | 14 dias de anel; em sombra, menos de metade "já tinha sumido" |
| E6 | **Lance em leilão acabando** (3) | R8a ficha 7 (wiki do retail; fã) | Lance mínimo e faixa de tempo (base 1.6) | R9 §5.6 | Ouro preso; prorrogação desconhecida. Fotos não testam isso (R9 §10.2) | Só provas vivas de até 2% da banca |
| E7 | **Tempo** (3) | R8b ficha 1: opinião de guias, nenhuma medida | Mínimo por hora e dia no próprio anel | Nenhuma: por enquanto é medição | Regra importada de outra versão | 3 semanas de dados próprios |
| E8 | **Estoque para a raide de 9/12** (3) | R8b ficha 3; R5b §4 (inferência declarada de quem vende ouro) | Preço e quantidade nos 7 dias antes | Nenhuma por enquanto | Capital parado; demanda incerta | Banca de 60 ouro e fonte aprovada |

Sem fonte, e por isso sem código: formação de mercado com spread (R8a ficha 3), reset (ficha 4), arbitragem pela casa neutra (ficha 8) e revenda de item de vendedor com estoque limitado (ficha 5). Para a última, o próprio dado vira evidência sem arriscar ouro: quando o dono abre um vendedor, o addon grava `numAvailable` (base 9.3) e forma a série de reposição.

## 6. Interface

### 6.1 Janela e teclas

Janela própria de 440 px, encostada à direita do leilão da Blizzard, visível enquanto ele está aberto. Texto em inglês, sem caixa de texto e sem controle de opção. Cada seção tem até 5 linhas e um `Show N more`, que é alvo de clique. Linhas de 28 px e fonte de 14 pt para leitura por stream; estado sempre em palavra, nunca só em cor; nada essencial em tooltip (base 8.4).

Quatro teclas sem modificador (o acesso remoto pode trocar combinações com Alt, R10a §1.1), todas no `Config.lua`:

- **F5**, `Scan`: uma varredura resumida.
- **F6**, `Do`: o próximo passo da linha em destaque (o rodapé diz qual).
- **F7**, `Skip` ou `Abort`: pula a linha ou desfaz a cotação.
- **F8**, `View`: alterna Next, Floor, Sell, Mine, Ledger, Probe.

As teclas de função estão livres pelos arquivos do projeto, sem conferência dos padrões do cliente (base 4.10): decisão 6. Espaço ficou de fora porque o dono já o usa no Auctionator (R4b §6). A roda do mouse não é oferecida para ação (parte 7).

### 6.2 Telas

Visão Next, a que abre:

```
+--------------------------------------------------------------+
  PREGAO   Gold 5g 09s   Free 4g 12s   Listed 0   In mail 0
  Session 00:14   Keys 9   Net +1s 46c   Scan 2m ago, full
+--------------------------------------------------------------+
  NEXT
  > BUY    14 Linen Cloth       9c ea   cost 1s 26c    +56c
    BUY    12 Rough Stone       2c ea   cost 24c       +72c
    POST    1 Bandit Cloak      24h   4s 50c   needs 18%
    POST   20 Copper Ore         8h   1s 08c ea   needs 9%
    CANCEL  1 Tin Ore x20       behind 340   frees 36s
    Show 7 more
+--------------------------------------------------------------+
  To do: mailbox 5 items, vendor 3 lots +2s 10c
  [F6] Quote 14 Linen Cloth    [F7] Skip   [F8] View  [F5] Scan
  State: Ready                 Unsaved: 9 actions
+--------------------------------------------------------------+
```

Rodapé depois da primeira tecla numa compra de commodity:

```
  [F6] BUY NOW  14 x 9c = 1s 26c   cap 1s 40c   quote 11s
  State: Quoted                [F7] Abort
```

Visão Sell:

```
+--------------------------------------------------------------+
  SELL   bags of Hexumlite     12 sellable, 4 reserved
    Bandit Cloak      AUCTION  24h  4s 50c   needs 18%  dep 30c
    Copper Ore x20    AUCTION   8h  1s 08c   needs 9%   dep 4c
    Ruined Pelt x5    VENDOR   25c ea   auction pays less
    Light Leather x18 KEEP     reserved for crafting
    Wolf Meat x7      VENDOR   3c ea    no buyers seen
    Show 7 more
+--------------------------------------------------------------+
```

Visão Mine:

```
+--------------------------------------------------------------+
  MINE   6 active   1 sold, pays in 41m   0 bids
    Copper Ore x20    FRONT      1s 08c   5h left
    Tin Ore x20       BEHIND 340 1s 76c   2h left
    Bandit Cloak      FRONT      4s 50c   22h left
    Linen Bag         SOLD       2s 10c   pays in 41m
    Rough Stone x40   BEHIND 12  3c       7h left
    Show 1 more
+--------------------------------------------------------------+
```

Painel do correio:

```
+--------------------------------------------------------------+
  MAIL   ledger read 6 of 6
    2 sales          +3s 12c   cut 5.0%   deposit back 34c
    1 expired        Tin Ore x20    deposit lost 12c
    3 purchases      17 items, 2 lots for vendor
    Safe to collect: use Open All
+--------------------------------------------------------------+
```

Visão Ledger:

```
+--------------------------------------------------------------+
  LEDGER   session 01:32   keys 49   net +10s 75c
    Floor         31 keys   +5s 58c   18c per key   6 gone
    Sell greens    6 keys   +5s 80c   sold 2 of 5
    Sell extras    9 keys   -45c      sold 1 of 6, 2 expired
    Cancels        3 keys   deposit lost 18c
    Capital turned 1.4 times     per hour +7s 01c
  [F6] Close session and save (reload)
+--------------------------------------------------------------+
```

Visão Probe, a régua dos parâmetros:

```
+--------------------------------------------------------------+
  PROBE   9 of 14 measured
    Key press is accepted by the game    YES   (12 actions)
    Auction cut                          5.0%  measured, n=3
    Deposit 2h / 8h / 24h                read live, min 1c
    Sale mail delay                      58m   measured, n=2
    Same price order                     unknown, 1 of 5 seen
    Show 9 more
+--------------------------------------------------------------+
```

### 6.3 Fluxos tecla por tecla

**A. Varrer, decidir e comprar.**
1. O dono fala com o leiloeiro; a janela abre e as quatro teclas passam a valer.
2. **F5**. O estado mostra `Scan 9/16` por cerca de 10 segundos (**H**, base 2.6), e a fila aparece com a primeira linha em destaque.
3. **F6**. Se a escada tem mais de 30 segundos, a tecla só atualiza (`Refreshed`) e o dono aperta de novo.
4. **F6, tecla da cotação**: `StartCommoditiesPurchase`. O rodapé mostra total, teto e segundos da cotação.
5. **F6, tecla da compra**: `ConfirmCommoditiesPurchase`. A linha sai, o cabeçalho atualiza, a seguinte ganha o destaque. **F7** em qualquer ponto desfaz.
6. Item que não é commodity: não há cotação; **F6** é a tecla do arremate (`PlaceBid`).

Teclas por compra: 2 em commodity, 1 em item, mais 1 quando a foto estava velha.

**B. Postar.** **F8** até Sell, ou a própria linha POST na fila. **F6, tecla da postagem**: `PostItem` ou `PostCommodity` com o preço, a duração e o depósito que a linha mostra. Se o jogo pedir confirmação, o rodapé vira `Confirm post?` e **F6, tecla da confirmação**, chama `ConfirmPostItem` ou `ConfirmPostCommodity`. Linhas VENDOR e KEEP não têm tecla: o addon marca o item na bolsa (marca de canto do Baganator, base 7.2) e o dono vende com o próprio clique no vendedor.

**C. Cancelar e repostar.** A linha CANCEL só entra na fila quando a regra do R9 §4.6, com os números medidos, dá ganho; antes disso a visão Mine só informa a posição (`FRONT`, `BEHIND 340`). **F6, tecla do cancelamento**: `CancelAuction`. O item volta pelo correio (base 1.8); recolhido, vira linha POST, e **F6, tecla da postagem**, o reposta. O razão cobra o depósito perdido da estratégia que pediu o cancelamento.

**D. Recolher o correio.** O dono abre a caixa. O addon lê cabeçalhos e faturas e só então mostra `Safe to collect`. O dono clica no `Open All` da Blizzard (botão `OpenAllMail` no espelho, `Blizzard_MailFrame/MailFrame.xml:444`); o addon não pega ouro nem item (decisão 7). A variação da bolsa e do ouro fecha os lotes no razão.

**E. Fechar a sessão.** **F8** até Ledger; **F6** na linha `Close session and save` grava o registro e recarrega a interface, o que leva o banco ao disco (base 3.9). O agente lê o arquivo e devolve o relatório de sessão que o projeto pede (base 4.7).

### 6.4 Acesso remoto e alertas

- Quatro teclas vizinhas, sem modificador, sem arrastar, sem digitar, sem depender de passar o mouse. Toda tecla tem resposta local imediata (`Sent...`) antes de o servidor responder.
- O processamento é fatiado por relógio, não por quadro: com a janela do jogo sem foco o limite é de 30 quadros por segundo (base 3.8). **H:** com o stream, a janela do Avell mantém o foco. Medir: quadros por segundo na visão Probe.
- Com o foco numa caixa de texto da Blizzard as teclas não disparam (base 3.4); a janela mostra `Keys paused: click outside the search box`.
- Ausência: o desenho não tem nada que mexa com a marca de ausente. Cada ciclo pede teclas do dono, como a base 8.2 recomenda; os tempos reais (base 11.9) ficam para o dono anotar.
- Alertas com texto, ícone do cliente piscando e som, juntos (`FlashClientIcon` com `PlaySound`, base 3.6), porque o som pode não atravessar o stream: leilão vendido e expirado (os avisos chegam mesmo com o leilão fechado, base 2.11), disjuntor aberto, throttle preso, ação sem resposta, leilão indisponível.

## 7. Risco e conformidade

**Guardas, todas no caminho da tecla.**

- Ficha de tecla: uma chamada restrita por clique; sem ficha, `Acoes.lua` recusa.
- Foto fresca: nenhum gasto sobre escada com mais de 30 segundos.
- Teto de cotação: total cotado acima do teto do motor, a tecla 2 é recusada.
- Capital: custo dentro do ouro livre menos a reserva; lote até 20%; risco de preço até 50%.
- Lote de sondagem: até 2% da banca na primeira compra de cada item do piso.
- Bolsa: compra limitada pelos slots livres.
- Combate: com `InCombatLockdown()` a janela pausa e não mexe em binding (base 3.4).
- Banco: poda acima de 2 MB.

**Disjuntores** (pausam as compras; vender e ler continuam): 3 ações sem resposta ou falhas seguidas; perda do dia acima do limite; 2 varreduras incompletas seguidas; throttle preso; evento `AUCTION_HOUSE_DISABLED` ou erro `HasRestriction`, `Unavailable` ou `IsBusy` (R1a §3 e §4). Este último caso cobre o Temporary Economy Hold (base 1.10): a tela diz `Auction House restricted: actions paused` e o addon não insiste.

**Quando a API falha ou devolve nada.**

- Ação restrita sem efeito (base 2.12): `No response` depois de 10 segundos; diário; sem nova tentativa.
- Varredura falha ou vem parcial: nenhum sinal sai dela; a tela pede F5.
- `C_Item.GetItemInfo` devolve nada (base 3.2; R1c §3): pede a carga do item; a linha só nasce com o preço de vendedor ao vivo.
- Função de depósito devolve nil (R1a §1): postagem bloqueada, `Deposit unknown`.
- Cotação indisponível, ou "item not found" em leilão ainda listado (base 1.11): escada refeita e contador próprio (`gone`), que calibra a idade da foto.
- Erro ao postar equipamento (base 1.11): equipamento só iguala; se o erro vier, a linha oferece nova tentativa por tecla.
- `owners` vazio ou `timeLeftSeconds` nulo (base 2.3, 2.4): nada da fase 1 depende deles; `ReplicateItems` nem é chamada.
- Fatura com número inesperado de retornos: só os cabeçalhos são usados; a divergência vai para o diário.
- Cliente caiu sem gravar: reconciliação no próximo login, com marca `unreconciled`.

**Como não parecer RMT** (base 1.10: os sinais citados são item barato por muito ouro e preço muito fora do mercado). O addon nunca sugere preço acima de 3 vezes o menor preço listado; sem escada de referência não sugere preço (`No reference`); nunca compra acima da referência; não compra leilão marcado como da própria conta (`containsAccountItem`, base 2.3 e 2.4); não envia ouro, correio a cobrar nem troca. O que ele faz é o uso normal que o suporte disse ser permitido (base 1.10), e não foi achado relato de punição por addon de leilão dentro das regras (base 5.7).

**O que o addon se recusa a fazer.** Tudo o que está na lista "nunca faz" da parte 2, e mais: repetir uma ação que falhou; continuar depois de um sinal de restrição; ligar estratégia sem fonte aprovada. Duas recusas têm motivo na base: a roda do mouse (a TSM diz que a Blizzard quebrou a função da macro de roda dela, base 5.1) e comprar ou vender no vendedor por código (decisão do dono de 2026-11-06 no outro addon, base 4.6).

## 8. Testes

**Bancada com leilão falso.** A bancada atual não simula leilão, dinheiro nem ticker repetido (base 4.9). Nasce `bancada-pregao.mjs`, em fengari, com mercado roteirizado em JSON (escadas por item, chegada de oferta e de compra no tempo), relógio controlado, ouro, bolsas, correio com faturas, vendedor, `NewTicker` repetido, throttle configurável e os modos de falha da parte 7. A peça central é o **marcador de tecla**: o leilão falso só aceita as 7 funções restritas e a confirmação de compra quando a pilha nasceu de um clique simulado, uma por clique; fora disso o caso falha. Casos mínimos: piso simples; cotação acima do teto; item sumido; postagem com aviso; postagem com throttle não pronto (a tecla não pode disparar depois, sozinha); cancelamento; correio com três faturas; disjuntor; tecla presa valendo uma ação.

**Replay.** `replay-pregao.mjs` lê `bruto` e `escadas` do arquivo de SavedVariables e roda o mesmo `Motor.lua` do jogo (R9, linha final). Confere se a fila reproduzida bate com a gravada e recalcula o modo sombra com preenchimento conservador: só pelas vendas inferidas com prioridade pior (R9 §10.2).

**Checadores estáticos.** `checar-lua.mjs` (sintaxe e ASCII) e `checar-combate.mjs --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER,BINDING_` (base 4.9). Novo `checar-acoes.mjs`, porque a lista de proibidas de hoje não tem função de leilão (R4a §3): (1) as 8 funções de ação só aparecem em `Acoes.lua`; (2) só dentro de funções marcadas `-- tecla-do-dono`, chamadas apenas pelo `OnClick` do botão de ação; (3) nenhuma função chamada por `C_Timer`, `OnUpdate` ou evento alcança uma delas; (4) nenhuma string de tela com nome de fonte; (5) nenhuma caixa de texto nem controle de opção; (6) proibidas no addon inteiro: `ReplicateItems`, `UseContainerItem`, `BuyMerchantItem`, `SendMail`, `TakeInboxMoney`, `TakeInboxItem`, `AutoLootMailItem`, `SetCVar` e binding de roda.

**Sonda no jogo, na ordem de peso da base 11.**

1. **11.1, a tecla por binding satisfaz o evento de hardware.** Primeira ação real: postar 1 unidade do item mais barato da bolsa com F6. Resposta, silêncio ou evento de bloqueio vão para o diário. Custo: um depósito.
2. **11.2, commodity ou item, e a chave do verde.** Passivo: status de cada item da bolsa e `isCommodity` das chaves varridas.
3. **11.3, tempo e pedidos da varredura, e o throttle.** O primeiro F5 e um segundo logo depois. Custo: 20 segundos.
4. **11.6, depósito, corte e reembolsos.** Depósito nos 3 índices; primeira fatura; primeiro expirado; primeiro cancelado. Custo: os depósitos.
5. **11.10, atraso do correio.** Primeira venda.
6. **11.5, `owners` e `timeLeftSeconds`.** Primeira escada.
7. **11.7, ordem entre preços iguais.** Passivo, quando houver lote próprio igualado.
8. **11.9, tempos de ausência.** O dono anota; o addon não mede nem interfere.

A 11.4 (`ReplicateItems`) e a 11.8 (casas de outra facção) ficam sem medida: a fatia fina não usa nenhuma das duas. Antes de haver addon, os comandos de leitura do R1b §16 (1 a 8 e 12) respondem parte dos itens 2 e 4 em dez minutos.

**Critério de aceite da fase 1.** Bancada e três checadores com zero erro; a sonda com os itens 1 a 5 medidos; uma sessão de 60 minutos sem erro de Lua no BugGrabber (instalado, R4b §2); toda ação do razão com a tecla que a originou; ouro do razão igual ao ouro do jogo depois da reconciliação.

## 9. Entrega em ondas

Modelo e esforço são sugestão, a confirmar pela tabela do `executar-plano`. A junction e o `.toc` completo são feitos uma vez, com o jogo fechado, pelo `dev-link.ps1` (base 4.9); dali em diante só `/reload`.

| Onda | Tarefas | Modelo sugerido | Depende de | Pronto quando | Resultado medido | Para se |
|---|---|---|---|---|---|---|
| 0, hoje, sem código | O dono cola os comandos 1 a 8 e 12 do R1b §16 com o leilão aberto; se quiser ouro já, posta os verdes pelo Auctionator instalado | Dono | Nada | Respostas anotadas | Tempo: 10 minutos. Depósito por duração e status de commodity de 10 itens | `/run` bloqueado: a leitura passa para dentro do addon |
| 1, contrato | `ARQUITETURA.md` com tabela "API, Contrato" por módulo; `.toc` com os 25 arquivos; `Config.lua`; `checar-acoes.mjs`; esqueleto da bancada | Sessão principal; checador em `sonnet/medium` | Decisões 1 e 2 | `node checar-lua.mjs <pasta>` e `node checar-combate.mjs <pasta> --toc --prefixos ...` com 0 erro; `node bancada-pregao.mjs --caso vazio` com `RESUMO erros=0` | Tempo: uma janela de jogo fechado, a única do projeto | Decisão 1 negada: o addon vira régua e conselheiro, sem `Acoes.lua` |
| 2, régua | `Nucleo`, `Parametros`, `Pedidos`, `Carteira`, `Correio`, `Razao`, `Sonda`, `Tela` (Probe e Ledger); `ler-diario.mjs` | `sonnet/medium`; ferramenta de leitura em `haiku/medium` | Onda 1 | Casos de correio e reconciliação passam na bancada; no jogo, `PregaoForeverDB.par` com o depósito dos 3 índices e, depois da primeira venda, corte e atraso com n ≥ 1 | Ouro: o razão mede uma sessão feita pelo Auctionator, em cobre por tecla e por hora. É a linha de base | O banco não chega ao disco depois do `/reload` (relatos conflitantes de builds antigos, R6b incógnita 4): parar e investigar |
| 3, piso | `Triagem` (gerador em `haiku/medium`), `Itens`, `Varredura`, `Escada`, `Estrategias`, `Motor`, `Guardas`, `Acoes` (compra), `Teclas`, `Tela` (Next e Floor) | `sonnet/high` para `Acoes` e `Motor`; resto `sonnet/medium` | Onda 2; sonda item 1 | Casos de piso passam; no jogo, uma compra completa com lote fechado no vendedor e diferença zero no razão | Ouro: cobre disponível abaixo do vendedor por varredura; cobre por tecla da E1 em 60 minutos | 3 varreduras em horários diferentes com menos de 30 cobre disponíveis, ou menos de 15 cobre por tecla: E1 desligada, segue a onda 4 |
| 4, venda | `Acoes` (postar e cancelar), `Tela` (Sell, Mine, painel do correio), `Pontes` | `sonnet/medium` | Onda 3 | Casos de postagem e cancelamento passam; no jogo, 10 postagens pela fila | Ouro: líquido das vendas contra o que o vendedor pagaria pelos mesmos itens; fração vendida por duração | Líquido abaixo do vendedor depois de 30 postagens: a regra de venda volta para a mesa |
| 5, vão em sombra | Anel de `escadas`, `Sombra.lua`, sinais E3 e E4 sem execução; relatório de evidência pelo `replay-pregao.mjs` | `sonnet/medium`; relatório na sessão principal | Onda 4 | 30 sinais em sombra gravados | Ouro hipotético: realizado sobre previsto em sombra | Abaixo de 0,5: E3 não liga; fica a fase 1 |
| 6 em diante | Fase 3: adotar, aproveitar código MIT ou construir | A definir | Banca de 60 ouro | Novo design | Comparação pela régua | A definir |

Calendário proposto: 16/11 onda 0; 17/11 manutenção e releitura do depósito (base 1.7); 17 e 18/11 ondas 1 e 2; 19 e 20/11 ondas 3 e 4; fim de semana de medição. Portões entre ondas na sessão principal, como o projeto já faz (R4a §7).

## 10. Decisões que ficam para o dono

1. **Liberar compra, postagem e cancelamento por tecla neste addon.** No outro addon, gastar por código foi proibido em 2026-11-06 (base 4.6). Recomendação: liberar só aqui, uma tecla por ação, com os tetos do `Config.lua`. Vender ao vendedor continua sendo clique do dono.
2. **Curadoria: dois addons já ocupam o papel de leilão** (base 4.12). Recomendação: manter o Auctionator (preço e postagem de hoje) e tratar o PregaoForever como mesa, um papel novo. Rever o Forever Guide, que por padrão compartilha as varreduras do dono com outros jogadores (base 7.3).
3. **Adotar ferramenta pronta em vez de construir** (base 5.1, 5.2). Recomendação: não instalar nada esta semana. Depois da onda 2, se quiser, uma sessão de teste com o ForeverFlip medida pela mesma régua, e decidir pelo número.
4. **Quais estratégias ligar.** Recomendação: E2a já (a fonte é a aprovada); E1 depois das três varreduras de prova; E2b quando o dono escolher a fonte, com a lista de reservas.
5. **Qual personagem opera, e se o ouro dos quatro vai para ele pelo correio.** Recomendação: um personagem parado numa capital com leilão, correio e vendedor próximos. **H:** personagem de nível baixo usa o leilão; não foi achada restrição de nível (R5a §2.5). Medir: abrir o leilão com ele.
6. **Teclas F5 a F8.** Recomendação: conferir os padrões do cliente em Options, Keybindings (R4b, incógnita 4) e aprovar ou trocar.
7. **Correio: `Open All` da Blizzard ou uma tecla por carta.** Recomendação: `Open All`, clique do dono, na fase 1. O addon só lê.
8. **Duas teclas na compra de commodity.** A confirmação não leva a marca de restrição (base 2.12, 2.13) e poderia sair sozinha. Recomendação: manter duas; o dono vê a cotação antes de gastar, e o addon nunca age fora de tecla.
9. **Tíquete mínimo por tecla e alvo de ouro por hora.** Recomendação: começar em 15 cobre e rever depois de duas sessões medidas.
10. **Acesso remoto e os termos da Blizzard** (base 8.3: sem posição oficial). Recomendação: fica fora do addon; pedir resposta por escrito ao suporte (R10a §3) antes de sessões longas.

## 11. Os cinco maiores riscos deste projeto

1. **O piso já está varrido.** O ForeverFlip tem "ofertas" de vendedor, há snipers, e a base não tem contagem de anúncios abaixo do vendedor. Se as três varreduras de prova mostrarem menos de 30 cobre, a E1 morre no primeiro dia e o "ouro esta semana" fica só com a venda do próprio estoque. Régua e venda não dependem do piso, mas o desenho perde a estratégia de entrada.
2. **A tecla não vale como evento de hardware, ou a ação silencia.** É a primeira incógnita da base 11 e não foi testada. Se o binding de sobreposição não satisfizer, `Acoes.lua` cai, e o addon vira fila que aponta e régua que mede, com o dono clicando na tela da Blizzard ou do Auctionator. A sonda descobre isso na primeira ação, ao custo de um depósito.
3. **Cobre por hora baixo demais.** Lucro de piso em itens de cobre, com duas teclas por compra, correio e ida ao vendedor por acesso remoto, pode perder para jogar e coletar. O critério está escrito: se depois de três sessões o cobre por hora do razão ficar abaixo do que o dono faz jogando, a fila de compra é desligada e fica o veredito de venda.
4. **A fatia fina não cresce.** Menor preço, quantidade e poucas escadas bastam para 5 ouro e não para 500. Quando a banca crescer, o motor do R9 pedirá dados que a fase 1 não coletou em largura, e a concorrência pronta já os tem. A aposta é que a decisão da fase 3 será melhor com três semanas de régua do que hoje. Se o dono quiser o terminal completo já, este projeto é o errado.
5. **Parâmetros errados nos primeiros dias, e conta em risco por motivo alheio ao addon.** Corte, reembolsos, ordem de empate e atraso do correio são estimativas até a primeira fatura, e a regra do depósito muda amanhã (base 1.7); um veredito errado custa depósitos. Fora do addon, o acesso remoto não tem posição oficial (base 8.3) e a Blizzard admite falso positivo no bloqueio de economia (R5a §3.2).

**O que derrubaria o projeto inteiro:** o dono negar a decisão 1 e também não querer um conselheiro sem tecla; a consulta resumida ser limitada a ponto de uma varredura por sessão ser o máximo (a fila envelhece e o piso some); ou a régua mostrar, na onda 2, que uma ferramenta adotada rende mais por tecla do que qualquer fila própria conseguiria. Nesse último caso o certo é adotar, e este design terá cumprido o papel ao custo de duas ondas.
