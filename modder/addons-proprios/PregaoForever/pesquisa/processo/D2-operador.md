> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# D2-operador: PregaoForever, o terminal de uma tecla

Data: 2026-11-16. Projetista D2, ângulo do operador. Só design: nenhuma linha de código de addon.

Como ler. `(base N.M)` cita a base de fatos; `(R9 4.1)`, `(R1b 14)` citam os relatórios; `(espelho: arquivo:linha)` cita o código da Blizzard no espelho. `[H]` marca hipótese a medir, sempre com o jeito de medir. Os números das telas são ilustrativos. O texto de tela é em inglês; o resto, em português. `[TECLA K]` marca o ponto exato em que entra a tecla do dono.

## 1. Tese

### 1.1 De onde vem o lucro

O mercado é um só por conjunto de regras: cerca de 3,6 milhões de personagens e mais de 200 mil leilões numa varredura (base 1.2). O preço listado está caindo (mediana 41% menor na semana 2, com 63% mais unidades; base 6.1) e os concorrentes já chegam com ferramenta: TSM 4.15, ForeverFlip, aux, snipers (base 5.1 a 5.3). Nesse mercado a informação não é vantagem. Todos leem a mesma API, sob o mesmo teto de 100 buscas por minuto (base 2.2) e sob a mesma exigência de uma ação por tecla ou clique (base 2.12 e 2.13; a confirmar no jogo, base 11.1). Entre quem joga dentro das regras, o recurso escasso é igual para todos: a atenção e as teclas de uma pessoa (inferência).

O lucro de um operador humano vaza por três lugares que nenhum modelo de preço conserta:

1. **Tempo até a tecla.** Guias do Forever dizem que a cobertura de preço chega em minutos e citam bots no beta (R8b ficha 1 e recomendação R6). Uma oferta mal precificada dura pouco [H: medir nas próprias fotos a vida mediana das ofertas com desconto, o `τ_vida` de R9 10.2]. No UI padrão, comprar uma commodity pede escolher a linha, informar a quantidade, clicar em comprar e clicar de novo no diálogo (R1b 4), com o ponteiro arrastado numa tela remota.
2. **Erro de dedo e de modo.** Preço errado, quantidade errada, ação no cartão errado. Com 50.912 cobre de banca (base 4.1), um erro de 50 prata custa 10% do capital.
3. **Fadiga.** Horas de tela remota pioram os dois anteriores.

A conta que este projeto otimiza: lucro por hora = decisões boas por hora × valor esperado por decisão − custo dos erros. O R9 já aponta para ela: ordena as recomendações por valor esperado por clique (R9 5.1) e desconta o custo de atenção `κ` dentro do valor de liquidação (R9 4.1). Este desenho leva a ideia até o fim: o custo de cada tecla é medido no diário, e a interface existe para baixá-lo.

### 1.2 Por que este desenho o captura

- Toda oportunidade vira um **cartão** já calculado, numa **fila** ordenada por valor esperado por tecla. O dono responde sim ou não.
- **Uma tecla por ação.** `K` compra, posta, cancela ou coleta o cartão da cabeça; `L` pula. Compra de item sai em 1 tecla; commodity e postagem com aviso saem em 2; nada passa de 2.
- **Nenhum número é digitado.** O terminal não tem caixa de texto: preço e quantidade vêm do motor e só mudam por degraus.
- **O dono é o relógio.** A varredura só roda com tecla recente dele (o pulso), o que cumpre a base 8.2 sem nada que evite a marca de ausente.
- **Sessão em voltas** (leilão, correio, leilão), com orçamento de teclas por volta e pausa sugerida por bloco.

[H] Meta de vazão: 6 a 10 ações por minuto nos trechos de fila, contra 1 a 2 no UI padrão por acesso remoto. Medir: cronometrar 10 compras no UI da Blizzard e 10 no terminal em modo treino (seção 8).

Sobre os 5 ouro: o projeto não promete enriquecimento. Dez por cento de margem girando a banca inteira uma vez rendem 50 prata. O que os fatos sustentam é uma escada (seção 2): vender bem o que os quatro personagens já coletam (base 4.2), operar contra o vendedor, que não tem risco de preço, e só depois girar commodities baratas, com corte e depósito medidos. Se a medição mostrar poucos cartões bons por hora, o projeto diz isso cedo (seção 11).

### 1.3 O que o ângulo sacrifica

- **Profundidade do motor.** Sem sazonalidade, perfil de concorrente, reset nem grafo de receitas nas fases 1 e 2. Jogadas lentas (estocar para a raide de 09/12, base 6.4) ficam de fora.
- **Cobertura de dados.** A varredura presa ao pulso não tira foto quando o dono não está. O histórico tem buracos e o ciclo semanal demora a aparecer.
- **Exploração livre.** O terminal não busca por texto nem navega categorias; para olhar o mercado, o dono usa o UI da Blizzard.
- **Aprendizado do dono.** A leitura mínima esconde o porquê. O cartão mostra os números, mas não ensina o mercado.
- **Dependência de execução.** A vantagem está em agir rápido e certo, que é onde um bot vence um humano. Se as boas ofertas somem em segundos, uma tecla não basta.
- **Viés de volume.** Otimizar decisões por minuto empurra para muitas operações pequenas. Por isso a métrica de sessão é lucro por tecla, não ações por minuto.

## 2. Escopo

| Fase | O addon faz | Liga quando |
|---|---|---|
| 1. Sonda e liquidação | Terminal, teclas, filas, gatilho, diário e sonda (base 11). Fila POST para o que está nas bolsas, com regra de preço de fonte aprovada (E2). Fila MAIL (uma tecla no botão Open All da Blizzard) e livro-caixa com corte e depósito lidos da fatura. Fila BUY em modo treino (cartão real, a tecla só registra) e, se o dono aprovar, E1 (vendedor) ao vivo. Aba BOOK e fechamento de sessão. | Bancada e checadores com 0 erro; decisões 1 a 4 da seção 10 |
| 2. Giro | BUY ao vivo: sniper de commodity (E3) e flip (E4), com V, λ, P e W* (seção 4) e tetos de Kelly. Fila CANCEL pela regra `Δ_canc` (R9 4.6). Estoque dos outros personagens pelo Syndicator (base 7.2). Calibração semanal pela mesa. Guarda de regime. | Corte, depósito e devoluções medidos; 3 sessões de sombra; `η_real` medido |
| 3. Profundidade | Conversão com as receitas dos quatro personagens (E5), lance (E6), tabela de P(venda), sazonalidade com dado próprio, calendário de eventos e, se o dono quiser, radar externo pela API de dados da Blizzard (base 5.4). | Banca e histórico que justifiquem; decisão do dono |

**O addon nunca:**

1. Chama compra, lance, postagem ou cancelamento fora do tratador da tecla do dono, nem duas vezes por tecla.
2. Simula entrada, repete tecla, liga ação à roda do mouse, move o personagem ou fala no chat.
3. Tem algo que evite a marca de ausente: sem pulso do dono, não consulta nem age.
4. Chama `ReplicateItems` nas fases 1 e 2 (uma por 15 minutos, resposta incerta, a recusa conta para a janela; base 2.5).
5. Tem caixa de texto ou opção dentro do jogo.
6. Negocia com item da própria conta (`containsAccountItem`, base 2.3), propõe preço fora da banda de mercado (seção 7) ou propõe reset (R9 6.3; só folclore, R8a ficha 4).
7. Lê ou copia código de addon de terceiro.
8. Escreve na pasta do jogo.

**Saída dos 5 ouro.** Os personagens estão em nível baixo e o ouro está dividido em quatro (base 4.1, 4.2): o primeiro capital vem de E2, a venda do que eles já coletam, e de E1. Os tetos são frações da banca B (seção 7), então o tamanho das operações cresce sozinho. Marcos: abaixo de 10 ouro, só E1, E2 e E3 em commodity de preço unitário baixo; de 10 a 100, E4; acima de 100, E5 e E6. Os marcos são hipótese de processo e mudam no `Config.lua`.

## 3. Arquitetura

### 3.1 Módulos, em ordem de carga

Pasta `wow/modder/addons-proprios/PregaoForever/`. TOC: `## Interface: 16001`, `## Author: Guilherme`, `## SavedVariables: PregaoForeverDB`, `## SavedVariablesPerCharacter: PregaoForeverCharDB`, `## OptionalDeps: Auctionator, Syndicator, Baganator, ElvUI` (base 4.8). Todo arquivo abre com `local _, ns = ...`; toda função de evento, timer ou clique roda em `xpcall` (base 4.8).

| # | Arquivo | Responsabilidade |
|---|---|---|
| 1 | `Config.lua` | Escrito pelo agente: teclas, tetos, lista de foco, estratégias (todas `ligada = false`, cada uma com o campo `fonte`), parâmetros do motor. Nunca gravado pelo jogo. |
| 2 | `Calibragem.lua` | Saída da mesa: parâmetros medidos, cada um `{valor, n, medidoEm}`. Existe desde o início no TOC (arquivo novo pede reinício do jogo; R4a 6); só o conteúdo muda. |
| 3 | `Nucleo.lua` | `ns.seguro` (xpcall), barramento de eventos, relógio (`GetServerTime`, `GetTime`), dinheiro, criação e migração das SavedVariables, `ns.log` de 60 linhas. |
| 4 | `Diario.lua` | Diário de calibração e registro do operador (anéis de tamanho fixo). |
| 5 | `Catalogo.lua` | Chave de item em texto (`id:nivel:sufixo`), preço de vendedor lido na hora (11º retorno de `C_Item.GetItemInfo`, base 3.2), estado de commodity por item, categorias. |
| 6 | `Interop.lua` | Chamadas com `pcall` a `Auctionator.API.v1` (preço como ponto de partida), Syndicator (contagem em outros personagens) e Baganator (marca no canto do item) (base 7.1, 7.2). |
| 7 | `Pedidos.lua` | Cano único de consultas sob throttle: um pedido em voo, prazo, repetição, orçamento por minuto e a regra do pulso. |
| 8 | `Fotos.lua` | Escada compacta, anel por item, diferença entre fotos (R9 2.5). |
| 9 | `Motor.lua` | Estimadores e valor de liquidação (seção 4). Sem efeito colateral: recebe foto e estado, devolve números. |
| 10 | `Estrategias.lua` | Registro das estratégias; cada uma transforma números do motor em propostas; respeita `ligada` e `sombra`. |
| 11 | `Risco.lua` | Banca, tetos, disjuntores, banda de preço. Confere a proposta ao criar o cartão e de novo na tecla. |
| 12 | `Carteira.lua` | Leilões próprios, lotes com custo (PEPS), livro-caixa. |
| 13 | `Correio.lua` | Leitura de cabeçalhos e faturas; conciliação com o livro. |
| 14 | `Varredura.lua` | Máquina de estados da volta de varredura. |
| 15 | `Filas.lua` | Filas BUY, POST, CANCEL, MAIL; ciclo de vida do cartão; pré-olhada do cartão da cabeça; trata os eventos de resposta. |
| 16 | `Gatilho.lua` | Único arquivo que chama as oito funções de ação. Só é alcançado pelo clique do botão ligado à tecla. |
| 17 | `Teclas.lua` | Bindings de sobreposição enquanto o terminal está aberto, anti-repique, detector de tecla presa. |
| 18 | `Alertas.lua` | Faixa na tela, som e ícone; escuta os avisos de venda e expiração (base 2.11). |
| 19 | `Visual.lua` | Kit visual reusado do GuiaForever (`ns.ui`, base 7.5). |
| 20 | `Tela.lua` | A janela: cabeçalho, cartão, lista, rodapé; uma função de desenho por fila. |
| 21 | `Sessao.lua` | Voltas, blocos, estatística do operador, fechamento. |
| 22 | `Sonda.lua` | Roteiro de medição da base 11, um passo por tecla. |
| 23 | `Comandos.lua` | `/pregao` (`open`, `probe`, `train`). |

### 3.2 Fluxo dos dados

```
[tecla do dono] -> Teclas -> pulso -> Varredura -> Pedidos -> C_AuctionHouse (consultas)
       eventos de resultado -> Fotos -> Motor -> Estrategias -> Risco -> Filas -> Tela
[TECLA K] -> Teclas -> Gatilho -> Risco (de novo) -> C_AuctionHouse (uma ação)
       eventos de resposta -> Filas (avança) -> Carteira (livro) -> Diario -> Tela
[caixa de correio] -> Correio (lê faturas) -> Carteira -> Diario
[TECLA C] -> ReloadUI -> SavedVariables no disco -> mesa -> Calibragem.lua -> próximo reload
```

### 3.3 Três regras de estrutura

1. **Só o `Gatilho.lua` age.** `PlaceBid`, `StartCommoditiesPurchase`, `ConfirmCommoditiesPurchase`, `PostItem`, `PostCommodity`, `ConfirmPostItem`, `ConfirmPostCommodity` e `CancelAuction` só aparecem nele. O arquivo não tem `C_Timer`, `OnUpdate` nem `RegisterEvent`: a única entrada é o `OnClick` do botão `PregaoForeverBotaoAcao`, ligado à tecla por `SetOverrideBindingClick` (base 3.4, 8.1). Um checador estático garante isso (seção 8). Os eventos de resposta são tratados em `Filas.lua`, que não pode agir.
2. **Uma chamada restrita por clique.** O tratador marca `emTecla` ao entrar, conta as chamadas e recusa a segunda. Qualquer caminho que chegue a uma função de ação sem `emTecla` dá erro no próprio addon, antes da API.
3. **Sem pulso, sem pedido.** `Pedidos.lua` só envia se a última tecla do terminal tem menos de `T_pulso` (90 s). Abrir o leilão ou a caixa de correio é ação do dono e vale como pulso.

### 3.4 Máquinas de estado

**Pedidos (comum a todas).** `LIVRE -> EM_VOO -> LIVRE`. Antes de enviar: pulso vivo e orçamento do minuto (inicial 40 buscas por minuto, abaixo do teto documentado de 100; base 2.2). Em voo: espera o evento de resposta por até 10 s; repete até 2 vezes; 3 falhas seguidas abrem o disjuntor de API (seção 7). Prioridade: 1 pré-olhada do cartão da cabeça, 2 leilões próprios, 3 itens em foco, 4 resumo. A cadência real do throttle é incógnita (base 2.14); os carimbos de `AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED`, `_SENT`, `_RESPONSE_RECEIVED` e `_SYSTEM_READY` vão para o diário e fixam o orçamento. [H] O UI da Blizzard e outros addons de leilão abertos gastam do mesmo throttle; medir uma volta com e sem eles.

**Varrer.**

| Estado | O que faz | Sai por |
|---|---|---|
| V0 PARADA | nada | [TECLA N], ou o dono abrir o leilão (`AUCTION_HOUSE_SHOW`) |
| V1 RESUMO | `SendBrowseQuery` e `RequestMoreBrowseResults` até `HasFullBrowseResults` (base 2.1); guarda menor preço e quantidade por chave | resultado completo; `AUCTION_HOUSE_BROWSE_FAILURE` (R1b 8) |
| V2 PRÓPRIOS | `QueryOwnedAuctions` (base 2.10) | `OWNED_AUCTIONS_UPDATED` |
| V3 FOCO | uma `SendSearchQuery` por item, por prioridade (itens cujo resumo mudou mais que `θ_gat` passam à frente; R9 11.5); cada resposta vira foto, diferença, números e cartões | fim da lista, do orçamento da volta ou do pulso |
| V4 PRONTA | só a pré-olhada do cartão da cabeça | [TECLA N] |

Os cartões aparecem durante V3, sem esperar o fim. Custo estimado de V1: 7.718 itens em 8,5 s e 16 pedidos; V3: um item a cada 0,4 s (base 2.6; medida de terceiro, a conferir, base 11.3).

**Pré-olhada.** Quando um cartão vira cabeça, `Filas` pede de novo a busca daquele item. O cartão fica `LIVE` enquanto a foto tem menos de `A_exec` (30 s, R9 tabela C); passado isso fica `STALE` e a tecla `K` só refaz a busca. A consulta nunca nasce dentro da tecla de ação: a tecla só age.

**Comprar item.**

```
I0 LIVE --[TECLA K]--> Risco.conferir --> PlaceBid(auctionID, arremate) (base 2.8) --> I1 SENT
I1 SENT --AUCTION_HOUSE_PURCHASE_COMPLETED(auctionID)--> DONE (livro, próximo cartão)
I1 SENT --AUCTION_HOUSE_SHOW_ERROR(erro)--> FAILED (ItemNotFound = GONE)
I1 SENT --10 s sem evento--> NO ANSWER (não repete; concilia pelo dinheiro e pelo correio)
```

**Comprar commodity.**

```
C0 LIVE --[TECLA K]--> Risco.conferir --> StartCommoditiesPurchase(itemID, qtd) (base 2.7) --> C1 QUOTING
C1 --COMMODITY_PRICE_UPDATED(unit, total), total <= teto do cartão--> C2 QUOTED (mostra o total cotado e GetQuoteDurationRemaining)
C1 --total > teto, ou COMMODITY_PRICE_UNAVAILABLE--> CancelCommoditiesPurchase() --> PRICE MOVED
C2 QUOTED --[TECLA K]--> ConfirmCommoditiesPurchase(itemID, qtd) --> C3 SENT
C2 QUOTED --[TECLA L] ou cotação vencida--> CancelCommoditiesPurchase() --> volta a C0
C3 SENT --COMMODITY_PURCHASE_SUCCEEDED--> DONE      C3 --COMMODITY_PURCHASE_FAILED--> FAILED
```

O teto do cartão é o `a_max` do motor vezes a quantidade (R9 5.2), nunca acima da tolerância de 5% que o próprio UI aceita (base 2.7; espelho: `Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseBuyDialog.lua:3`). `CancelCommoditiesPurchase` não está entre as sete funções restritas (base 2.12): só desiste de uma cotação, e pode sair de evento.

**Postar.**

```
P0 LIVE (escada com menos de 60 s; depósito lido por CalculateItemDeposit ou CalculateCommodityDeposit, base 1.4;
         IsThrottledMessageSystemReady verdadeiro, base 2.9)
P0 --[TECLA K]--> Risco.conferir --> PostCommodity(...) ou PostItem(...) (base 2.9)
      devolveu false --> P2 CREATING
      devolveu true  --> P1 WARNING (espera AUCTION_HOUSE_POST_WARNING; o cartão mostra o aviso)
P1 WARNING --[TECLA K]--> ConfirmPostCommodity(...) ou ConfirmPostItem(...) --> P2 CREATING
P2 --AUCTION_HOUSE_AUCTION_CREATED(auctionID)--> DONE (Carteira guarda id, preço, fila, depósito pago)
P2 --AUCTION_HOUSE_POST_ERROR ou AUCTION_HOUSE_SHOW_ERROR (R1b 6)--> FAILED
```

O preço respeita o menor passo aceito: cobre se `SupportsCopperValues()` for verdadeiro, prata inteira se não (R1b 7).

**Cancelar.**

```
K0 LIVE (CanCancelAuction verdadeiro; GetCancelCost no cartão; base 2.10)
K0 --[TECLA K]--> Risco.conferir --> CancelAuction(auctionID) --> K1 SENT
K1 --AUCTION_CANCELED(auctionID)--> DONE (lote marcado "in mail")      K1 --erro ou 10 s--> FAILED / NO ANSWER
```

O item cancelado volta pelo correio [H: o cliente tem o assunto "Auction canceled" (base 1.8) e o evento `AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE` traz atrasos de compra e de cancelamento (R1a evento 10); medir o atraso na sonda]. Repostar é outro cartão, na fila POST, depois da volta do correio. O addon nunca reposta sozinho.

**Regras comuns às quatro.** (a) `T_ver`: a tecla `K` não vale nos primeiros 400 ms de um cartão ou de um estado novo, mais a latência do acesso remoto informada no `Config.lua`. (b) Em `QUOTING`, `SENT` e `CREATING`, teclas extras são ignoradas e contadas. (c) O cartão da cabeça não é trocado por reordenação: só sai por ação, pulo ou invalidação visível. (d) Uma função restrita que falha não dá erro, só não faz nada (base 2.12): por isso todo estado de espera tem prazo e o desfecho `NO ANSWER`.

### 3.5 SavedVariables

Linhas em texto (`"t;campo;campo"`) no lugar de tabelas, para não gerar lixo (R9 11.3) e encolher o arquivo.

| Chave | Conteúdo | Tamanho estimado |
|---|---|---|
| `PregaoForeverDB.resumo` | por chave de item: último menor preço, quantidade, hora, média móvel | 8 mil itens × 40 B = 320 KB |
| `.radar` | 600 itens candidatos × 30 dias (mínimo, mediana, máximo, contagem) | 500 KB |
| `.fotos` | 80 itens em foco × anel de 64 fotos × 220 B (8 degraus exatos mais cauda em baldes) | 1,1 MB |
| `.estado` | 80 itens × cerca de 30 números (R9 11.3) | 40 KB |
| `.livro` | 14 dias × cerca de 300 linhas × 90 B | 380 KB |
| `.acoes` | registro do operador: 7 dias × 800 cartões × 60 B | 340 KB |
| `.diario` | sinais de calibração, anel de 400 | 60 KB |
| `.sessoes`, `.sonda`, `.log`, `.arquivadoAte`, `.carimbo` | resumos, medições, 60 linhas de log | 50 KB |
| `PregaoForeverCharDB` | leilões próprios, lotes, correio lido | 30 KB por personagem |

Total perto de 2,8 MB; teto de 5 MB, com aparo dos anéis mais antigos. [H] O tempo de `/reload` cresce com o arquivo (R9 11.6): medir na sonda com 1, 3 e 5 MB; alvo de até 5 s no Avell.

### 3.6 A mesa (fora do jogo)

A mesa é um conjunto de scripts em `wow/modder/ferramentas/pregao/`, rodados pela sessão do agente, nunca pelo addon.

| Contrato | Direção | Regra |
|---|---|---|
| `WTF/Account/<conta>/SavedVariables/PregaoForever.lua` | jogo para mesa | Só leitura. Vale o que estava na memória no último `/reload`, logout ou saída (base 3.9); o campo `carimbo` diz até onde vai. |
| `Calibragem.lua` | mesa para jogo | Gravado na pasta de desenvolvimento, que o jogo enxerga pela junction do `dev-link` (base 4.9); entra no `/reload` seguinte. É o ciclo normal do projeto (base 4.11). |
| `Config.lua` | agente para jogo | Idem. Toda mudança de tecla, teto, foco ou estratégia passa por aqui. |
| arquivo morto em `wow/modder/dados/pregao/` | mesa | Fotos e livro antigos saem das SavedVariables: a mesa copia, grava `arquivadoAte` na `Calibragem.lua`, e o addon apaga da memória o que é anterior. |

Ciclo: [TECLA C] na volta do correio chama `ReloadUI` (R1c 13) [H: se a chamada não for aceita a partir do addon, a tela pede `/reload`; medir na sonda]. O arquivo vai para o disco, a mesa recalcula e o resultado entra no reload seguinte. O ponto de salvamento também limita a uma volta a perda de registro numa queda do cliente ou do acesso remoto.

## 4. Motor

O motor é o mínimo que alimenta as filas. Três níveis: M0 (fase 1) só usa regras com fonte e custos medidos; M1 (fase 2) calcula V, λ, P e W*; M2 (fase 3) recebe a tabela de P e a conversão.

### 4.1 O que fica do R9

| Peça do R9 | Decisão | Como fica | Por quê |
|---|---|---|---|
| Valor de liquidação W e W* (4.1, 4.2) | adota | Moeda comum de POST, BUY e CANCEL. Candidatos: 8 degraus × 3 durações. | É a peça que transforma tecla em custo. |
| Ordem por valor esperado por clique (5.1) | adota e estende | EV dividido pelas teclas reais do cartão: 1 item, 2 commodity, mais 1 se houver aviso, mais a parcela da ida ao correio. | O gargalo é a tecla. |
| Saída calculada na escada pós-compra (5.1) | adota | Igual. | Separa pechincha de preço novo sem modelo extra. |
| Preço robusto da foto (1.2) | adota | Média aparada das unidades mais baratas, com filtro de isca. | Custo O(J), estado O(1). |
| Combinação no tempo (1.2) | simplifica | Só o nível rápido (EWMA com corte de Huber). Sem `x̂_T`, sem nível lento; `σ = max(σ_e, σ_cat)`. | Poucos dias de dado. |
| Vendas pela diferença de escadas (2.1 a 2.4) | adota só no foco | Fronteira F, `S_lo`, correção ξ inicial; Gama-Poisson com `φ_λ` fixo em 2 [H: medir a dispersão quando houver 200 intervalos]. | Só o foco tem fotos densas. |
| P(venda) (3.2) | simplifica | M0: não usa. M1: reserva fechada `P_fb = min(P_GI, P_dem, P_∞)` mais a recalibração logística. M2: tabela. | A tabela pede a mesa; o diário corrige o erro da reserva. |
| Cancelar e repostar (4.6) | adota com custo a mais | `Δ_canc` com `κ_cancel + κ_post` e a parcela da volta do correio. | O item cancelado passa pelo correio. |
| Kelly e os seis tetos (7.2, 7.3) | adota | `k_K = 0,25`. | Com banca pequena, quem manda são os tetos. |
| Disjuntores (7.5) | adota | Perda do dia, perda por item, compras sumidas em sequência. | |
| Sazonalidade (8.1) | corta | `s_bin = 1`. | Nenhuma fonte mede ciclo no Forever (base 6.5); o addon só acumula a série. |
| Quebra de regime (8.2) | simplifica | Detector de amplitude por categoria e a guarda `k_crash` do sniper. | É o que funciona com pouco dado (R9 8.2 c). |
| Perfil de concorrente (9) | troca | Um número por item: `t_frente`, quanto tempo um leilão próprio fica na frente depois de postado. | Perfil por dono pede nomes (incógnita, base 11.5) e fotos densas. |
| Agendador (11.5) | troca | Mesma prioridade; a capacidade é o orçamento da volta; a pré-olhada passa na frente. | Varredura presa ao pulso. |
| Reset (6) | corta | | Valor esperado negativo em item líquido (R9 6.3); capital. |
| Backtest (10) | só na mesa | Replay das fotos, com o mesmo `Motor.lua`. | |
| Conversão (5.5) e lance (5.6) | fase 3 | | |

A especificação do R9 ainda não passou por revisor matemático (base 10). Por isso M1 nasce em sombra e só vai ao vivo com `η_real` medido.

### 4.2 O que este ângulo acrescenta: o modelo do operador

O `Diario` grava, por cartão: tipo, hora em que virou cabeça, hora da tecla, desfecho, teclas usadas, teclas ignoradas e se foi desfeito. Daí saem:

- `T_dec` por tipo de cartão (mediana do tempo até a tecla) e `T_resp` por ação (tecla até o evento de resposta).
- `κ_tipo = ω_t × (T_dec + T_resp)`. Inicial: os do R9, 3 s para compra, 4 s para postagem, 3 s para cancelamento (R9 tabela C). Depois de 50 cartões por tipo, vale o medido.
- Limiar do cartão: `EV >= max(M_abs, μ_min × custo)`, com `M_abs = 5 × κ` do ciclo (R9 tabela C). Quando o dono fica mais rápido, `κ` cai e o limiar cai junto: o motor passa a mostrar cartões menores só para quem consegue cobrá-los.
- `ω_t`, o valor da hora: lucro por hora realizado nas últimas 5 sessões. Inicial: decisão do dono (seção 10).
- Fadiga: se a mediana de `T_dec` do bloco passa de 1,3 vez a do primeiro bloco, ou a taxa de desfazer dobra, a aba BOOK sugere pausa [H: limiares a calibrar com 10 sessões].

### 4.3 Valores iniciais

Do R9 tabela C: `H_ref` 2 h; `α_ap` 0,2; `g_isca` 0,15; `f_isca` 0,05; `τ_f` 3 h; `k_H` 2,5; `z_c` 1,0; `μ_min` 0,10; `η_real` 0,5; `k_K` 0,25; `w_item` 0,10; `w_cat` 0,30; `w_tot` 0,75; `ℓ_dia` 0,05; `N_seq` 5; `A_exec` 30 s; `k_crash` 3. Deste projeto [H]: `T_ver` 400 ms; `T_pulso` 90 s; teto de 15 cartões BUY e 8 CANCEL por volta; `K_lvl` 8; 80 itens em foco. Corte, depósito e devoluções não têm valor inicial: enquanto não forem medidos, E3 e E4 não ligam (a leitura provável de 5% da base 1.4 só aparece em sombra).

### 4.4 Diário de calibração: como a estimativa vira número

| Parâmetro | Sinal gravado | Onde nasce |
|---|---|---|
| Corte `c` | `consignment` dividido pelo arremate em cada fatura de venda (`GetInboxInvoiceInfo`; espelho: `Blizzard_MailFrame/MailFrame.lua:790`) | Correio |
| Depósito `d(i, D, n)` | `CalculateItemDeposit` e `CalculateCommodityDeposit` nas 3 durações a cada cartão POST, sem postar; e a diferença de `GetMoney` na postagem | Filas, Gatilho |
| Devoluções `r_s`, `r_x`, `r_c` | campo `deposit` da fatura na venda; ausência de crédito no expirado e no cancelado | Correio |
| Atraso do correio | hora do aviso de venda com `auctionID` (base 2.11) contra `moneyDelay` e a hora prevista da fatura | Alertas, Correio |
| Orçamento de consultas | carimbos dos eventos de throttle; `T_resp` por tipo de pedido | Pedidos |
| Taxa de "já sumiu" e desvio da cotação | desfecho GONE por estratégia; cotação contra o preço do cartão | Filas |
| P(venda) | por postagem: preço, fila na frente, duração e desfecho com hora (R9 3.6) | Carteira |
| `t_frente` | a cada volta, posição dos leilões próprios na escada | Varredura |
| `κ`, `T_dec`, erros | registro do operador | Diario |
| ξ | subamostragem de séries densas (R9 2.9) | mesa |

A mesa calcula medianas e grava `{valor, n, medidoEm}` na `Calibragem.lua`. O addon usa o medido quando `n` passa do mínimo do parâmetro; até lá o número em tela leva `~` na frente. Uma estratégia declara os parâmetros de que depende e não liga enquanto algum estiver estimado.

## 5. Estratégias

Todas nascem com `ligada = false`. O campo `fonte` fica no `Config.lua` e no `ARQUITETURA.md`, nunca na tela. `sombra = true` faz a estratégia gerar cartões fantasma, gravados com o desfecho hipotético (R9 10.4), sem aparecer na fila.

| Id | Estratégia | Fonte | Sinal mensurável | Regra | Risco | Condição para ligar |
|---|---|---|---|---|---|---|
| E1 | Leilão abaixo do preço de venda ao vendedor | R8a ficha 5: os fatos de preço são da Blizzard (F6); não há fonte do Forever para o fluxo. FG, R8b recomendação R8 ("never list below vendor price"), indica que essas ofertas existem. | `minPrice` do resumo menor que o preço de vendedor lido do cliente na hora (base 3.2) | `EV = Σ (v_sell − p_j)·q_j − κ_buy·teclas − κ_npc` (R9 5.4); sem corte e sem depósito. A venda ao vendedor é clique do dono: o addon só marca o item na bolsa (Baganator, base 7.2) e soma o total | Preço de vendedor muda por hotfix (base 6.3), por isso a leitura é na hora; espaço de bolsa; ida ao vendedor | Aprovação do dono; a sonda vende 1 item e confere o ouro recebido com o preço lido |
| E2 | Liquidar o que é do dono | Studen dica 4, a única fonte aprovada (base 4.5): verdes bons vão ao leilão. Regras de preço: nunca abaixo do vendedor (FG, R8b R8); cobrir por um cobre (F5, R8a ficha 2); deixar folga real (MM, R8b R6, beta); igualar (contorno do erro de equipamento, base 1.11); lote em tamanho de receita (FG, R8b R14); duração curta para o que gira e 24 h para raro (MM, R8b R15). | Escada do item, preço de vendedor, depósito nas 3 durações | O dono escolhe a regra de preço por classe de item. Antes do cartão: se o líquido esperado não passa do vendedor, o cartão diz VENDOR e não posta. | Depósito perdido na expiração (base 1.7); preço em queda (base 6.1) | Aprovação da regra. Equipamento fica em igualar enquanto o erro da base 1.11 existir |
| E3 | Sniper de commodity | R8a ficha 1: mecânica na documentação da TSM (F1, 2022); limiar só em guia genérico (F17). Nenhuma fonte do Forever. | Degraus da frente com preço até `a_max = U_lcb/(1 + μ_min) − κ_buy/n`, saída calculada na escada que sobra (R9 5.2) | R9 5.1, com a guarda `k_crash` | Isca (F23); preço novo confundido com pechincha (base 6.1); erro "item not found" (base 1.11); bots | Corte e depósito medidos; 3 sessões de sombra com taxa de "já sumiu" abaixo de 50% e `η_real` medido; aprovação |
| E4 | Flip no vão | R8a ficha 2 (fonte de fã e guia genérico) | `p_{k+1}/p̄_k > (1 + μ_min)/(1 − c)` mais custos de postagem; `λ_p − ν_f` no preço de repostagem (R9 5.3) | `k* = argmax EV_k`, com `k <= K_flip` | O vão fecha com oferta nova; guerra de cobertura | E3 ligada há 2 semanas; `t_frente` medido no item; regra de empate medida ou pior caso (base 2.17) |
| E5 | Conversão (produzir, desencantar) | R8a ficha 6: descrição pública do addon Arbitrage (F11); tabela de desencanto antiga (F16) | Custo recursivo dos insumos contra o valor do produto (R9 5.5), com o grafo de receitas do cliente (base 9.2) | Lucro menos `z_c·σ` acima do limiar | Rendimento de desencanto não existe no cliente (base 9.3); produto sem liquidez | Fase 3; rendimentos medidos no diário |
| E6 | Lance em leilão que acaba | R8a ficha 7: wiki do retail; guia de fã diz que quase ninguém dá lance | Lance mínimo baixo na faixa Short (base 1.6) | R9 5.6 | Ouro preso; prorrogação desconhecida; não dá para testar em sombra com fotos (R9 10.2) | Fase 3; só com diário próprio de lances de valor mínimo |

**Ficam fora, e por quê.** Reset: só folclore (R8a ficha 4) e valor esperado negativo em item líquido (R9 6.3). Formação de mercado com spread: sem fonte (R8a ficha 3). Casa neutra entre facções: fonte de fã, corte maior e visibilidade entre facções não confirmada (R8a ficha 8; base 1.3). Ciclo de hora e de dia: nenhuma fonte mede (R8b ficha 1). Abertura de raide: só previsão sem dado (R8b ficha 3).

**Onde não há fonte, o dado do addon vira evidência assim.** (a) O resumo de cada volta alimenta a série por hora no `radar`; com 3 semanas, a mesa mostra se existe ciclo e de que tamanho. (b) Toda postagem grava o desfecho hipotético de cada regra de preço não escolhida (o lote teria vendido se as vendas inferidas com prioridade pior chegassem a ele; R9 10.2); com 50 postagens por classe, a mesa compara o líquido por unidade de cada regra. (c) A regra W* do R9 não tem fonte pública: roda só em sombra até vencer a regra com fonte nesse registro. Nos três casos a mesa entrega o número e o dono decide.

## 6. Interface

### 6.1 Princípios

1. **Uma tela, três zonas fixas**: estado em cima, cartão no meio, lista embaixo. Nada muda de lugar; o olho não procura.
2. **O verbo manda.** `K` sempre faz o que está escrito em letras grandes no cartão (BUY, POST, CANCEL, OPEN ALL). O terminal nunca troca de fila sozinho.
3. **Leitura zero.** O cartão tem 3 linhas de número. Cada seção tem até 5 linhas e "Show N more" (base 4.7). Nenhuma fonte na tela.
4. **Sem caixa de texto.** Com o foco numa caixa as teclas não disparam (base 3.4); sem caixa, o terminal nunca engole tecla, e digitar no chat nunca compra nada.
5. **Eco imediato.** A tecla aceita muda a palavra de estado no mesmo quadro (LIVE, SENT, DONE), para o dono não repetir por dúvida.
6. **Janela própria**, aberta em `AUCTION_HOUSE_SHOW` e `MAIL_SHOW` (R1c 1) e fechada com eles; nenhuma aba no quadro da Blizzard, que causaria taint (base 7).

### 6.2 Teclas

Só teclas livres pelos arquivos do projeto (base 4.10) [H: conferir os padrões do cliente em Options > Keybindings, R4b incógnita 4]. São bindings de sobreposição, que só valem com o terminal aberto (base 8.1). Nenhuma é tecla de combate: em combate o binding não muda (base 3.4), então nada que o dono use para lutar pode ficar preso.

| Tecla | Nome | Faz | Função restrita |
|---|---|---|---|
| `K` | ACT | Executa o cartão da cabeça | sim, uma por tecla |
| `L` | SKIP | Pula o cartão; numa cotação, desiste | não |
| `H` | BACK | Traz de volta o último cartão pulado | não |
| `I` / `M` | MORE / LESS | Troca o candidato de preço (POST) ou a quantidade (BUY: tudo, metade, um quarto) | não |
| `U` / `O` | PREV / NEXT | Troca de fila: BUY, POST, CANCEL, BOOK | não |
| `N` | SCAN | Pulso: nova volta de varredura | não, só consulta |
| `Y` | BLOCK | Tira o item das filas até a virada do dia | não |
| `B` | ROWS | "Show N more" da lista | não |
| `C` | SAVE | Ponto de salvamento (reload) | não |
| `P` | PAUSE | Esconde o terminal e solta todas as teclas | não |

Todas têm botão clicável de pelo menos 32 px. Se a sonda mostrar que a tecla não satisfaz o evento de hardware (base 11.1), o plano B é o **cursor estacionado**: o botão ACT fica sempre no mesmo ponto da tela, o clique esquerdo age e o direito pula; continua um gesto por ação, sem viagem de ponteiro.

### 6.3 Telas

Fila BUY, cartão de item pronto:

```
+--------------------------------------------------------------------+
| PREGAO   [BUY 7]   POST 3   CANCEL 2   BOOK        KEYS LIVE  LAP 4 |
| Gold 5g 09s    Free 3g 81s    At risk 1g 28s    Scan 0:12 ago   OK  |
+--------------------------------------------------------------------+
| BUY 1/7                                    SNIPE   grade A   LIVE   |
|                                                                    |
|   Light Leather                                          x 40      |
|   38c each     =     15s 20c                                       |
|   Exit 61c     Net +5s 92c                    sells ~14/h          |
|                                                                    |
|   [K] BUY          [L] skip          [I/M] qty 40 > 20 > 10        |
+--------------------------------------------------------------------+
| NEXT                                                               |
|  2  Copper Ore       x 60    1s 10c ea    +4s 40c    A             |
|  3  Wool Cloth       x 20       72c ea    +2s 05c    B             |
|  4  Peacebloom       x 35       31c ea    +1s 12c    B             |
|  5  Linen Cloth      x 80       12c ea    +0s 96c    A             |
|  Show 2 more                                                       |
+--------------------------------------------------------------------+
| K act   L skip   H back   U/O queue   N scan   Y block   P pause   |
+--------------------------------------------------------------------+
```

`grade` resume a qualidade do dado: A = taxa de venda medida e foto recente; B = poucas fotos; C não entra na fila BUY, salvo E1, que não depende de valor justo.

Commodity depois da primeira tecla (o segundo `K` só vale depois de `T_ver`):

```
| BUY 1/7                                              QUOTED   8s    |
|   Light Leather                                          x 40      |
|   QUOTE  15s 60c      card 15s 20c   +2.6%   limit 16s 00c         |
|   >>> PRESS K AGAIN TO BUY <<<                 [L] cancel          |
```

Fila POST:

```
| POST 2/3                                    MATCH   grade B   LIVE  |
|   Heavy Leather  (bags)                                  x 20      |
|   1s 85c each   =   37s 00c        8h        deposit 24c           |
|   Front 1s 85c x 12, 2 sellers       ahead of you: 12 (worst case) |
|   [K] POST     [L] skip     [I/M] price 1s 85c > 1s 84c > 1s 70c   |
```

Fila CANCEL:

```
| CANCEL 1/2                                 BURIED   grade B   LIVE  |
|   Wool Cloth x 20        posted 3h10 ago at 80c                    |
|   Now 52 ahead at 71c       sale chance ~6%                        |
|   Cancel and repost at 70c:  +1s 40c vs wait    fee 0    via mail  |
|   [K] CANCEL          [L] keep                                     |
```

Correio:

```
+--------------------------------------------------------------------+
| PREGAO   MAIL                                     KEYS LIVE  LAP 4  |
+--------------------------------------------------------------------+
| INBOX 12                                                           |
|   Sold       5     +3g 41s 07c       cut 5.0% (measured)           |
|   Won        4     items                                           |
|   Returned   2     expired 1, canceled 1                           |
|   Other      1     not auction mail                                |
|   [K] OPEN ALL                               bags free 14          |
+--------------------------------------------------------------------+
| After collecting:   [C] save                                       |
+--------------------------------------------------------------------+
```

Aba BOOK, que também é a tela de fechamento:

```
| SESSION 1h42     laps 9     keys 212     actions 131    errors 0    |
|   Realized +41s 20c     Marked +12s 05c                            |
|   Per hour +31s         Per key +25c                               |
|   Gone before key 6 of 19          Skipped 22                      |
| OPEN POSITIONS                                                     |
|   Light Leather   x 40   cost 15s 20c   listed 61c   front   0:22  |
|   Copper Ore      x 60   cost 1g 06s    in mail                    |
|   Show 3 more                                                      |
| LIMITS   day loss 0 / 25s     per item 50s     exposure 1g 28s     |
|   [K] CLOSE SESSION                                                |
```

A tela da sonda (`/pregao probe`) tem a mesma casca: um passo por cartão, com o que o dono vai fazer e o que será medido.

### 6.4 Fluxos tecla por tecla

**A. Varrer, decidir e comprar.**
1. O dono clica no leiloeiro (ação dele). O terminal abre em BUY; a interação vale como pulso e a varredura começa.
2. O primeiro cartão aparece enquanto a varredura segue [H: medir o tempo até o primeiro cartão; alvo de 2 s].
3. Cartão LIVE.
   - Item: [TECLA K] dispara `PlaceBid`. SENT, DONE, próximo cartão. 1 tecla.
   - Commodity: [TECLA K] dispara `StartCommoditiesPurchase`. QUOTED mostra o total real. [TECLA K] dispara `ConfirmCommoditiesPurchase`. DONE. 2 teclas.
4. `L` pula, `H` traz de volta, `I`/`M` mudam a quantidade antes do `K`, `Y` bloqueia o item.
5. Fila vazia: "Queue empty. N scan, O post (3)". [TECLA N] abre nova volta.

**B. Postar.**
1. `O` até POST. Cada pilha postável das bolsas é um cartão, com preço, duração e depósito já lidos.
2. `I`/`M` trocam o candidato de preço (opcional).
3. [TECLA K] dispara `PostCommodity` ou `PostItem`. Se o jogo pedir confirmação, o cartão vira WARNING e [TECLA K] dispara `ConfirmPostCommodity` ou `ConfirmPostItem`. DONE. 1 tecla, 2 com aviso. Um cartão é uma chamada: postar várias unidades iguais de um item usa a quantidade da própria função (R1b 6).

**C. Cancelar e repostar.**
1. `O` até CANCEL. Um cartão por leilão próprio que passou na regra.
2. [TECLA K] dispara `CancelAuction`. DONE; o lote fica "in mail". 1 tecla por leilão.
3. Volta do correio (fluxo D): o item volta às bolsas.
4. De novo no leiloeiro, o item é um cartão novo na fila POST; [TECLA K] posta (fluxo B).

**D. Recolher o correio.**
1. O dono anda até a caixa e clica nela (ação dele). O terminal troca para MAIL e lê cabeçalhos e faturas, só leitura.
2. [TECLA K]: a tecla está ligada ao botão `OpenAllMail` da própria Blizzard (espelho: `Blizzard_MailFrame/MailFrame.xml:444`); é o jogo que recolhe, pelo laço dele, e para quando as bolsas enchem (espelho: `MailFrame.lua:1632`). [H: ligar a tecla a um botão da Blizzard funciona para addon e sem taint; a própria Blizzard liga um botão de controle a essa mesma ação (espelho: `MailFrame.lua:271`). Testar na sonda; se não funcionar, o dono clica no botão.]
3. O livro confere o ouro recebido com as faturas lidas.
4. [TECLA C], opcional: ponto de salvamento.

**E. Fechar a sessão.**
1. `O` até BOOK.
2. [TECLA K] em CLOSE SESSION: grava o resumo e recarrega a interface. Não é ação de leilão.
3. A mesa lê o arquivo; a sessão do agente escreve o relatório de sessão do projeto (base 4.7) e atualiza a `Calibragem.lua`.

### 6.5 Ritmo de uma sessão longa

- **Volta**: perna do leilão (varrer, postar, comprar, cancelar) e perna do correio. [H] Duração de 5 a 8 minutos; medir. Os cancelamentos são agrupados no fim da perna do leilão, porque cada um só rende depois do correio.
- **Orçamento por volta**: até 15 cartões BUY e 8 CANCEL; POST sem teto (é o que libera capital). O que sobra espera a volta seguinte, já reordenado.
- **Bloco**: 6 a 8 voltas, perto de 50 minutos. No fim do bloco a aba BOOK mostra o resultado e sugere pausa. Nada é imposto.
- **Sem espera morta**: enquanto um pedido está em voo, o dono pode pular e seguir; nenhuma tela trava.
- **Ausência**: sem tecla por 90 s o terminal para e mostra "Paused. Press N". Não há nada que mantenha a sessão viva sem o dono (base 8.2).

### 6.6 Adaptações para o acesso remoto

- Teclado primeiro; o mouse é opcional. Nenhuma informação só em tooltip (base 8.4).
- Texto grande e de alto contraste (4,5:1), respeitando a escala de fonte do usuário (R10a 4); estado sempre em palavra e forma, nunca só em cor (base 8.4).
- Sem animação nem transição: troca seca de estado, que sobrevive à compressão do vídeo.
- Tempo por `GetTime`, nunca por contagem de quadros: com a janela sem foco o cliente cai para 30 quadros por segundo por padrão (base 3.8).
- **Tecla presa ou repetida.** [H: medir na sonda se segurar a tecla repete o clique do binding, localmente e pelo acesso remoto.] Mesmo que repita: uma chamada por clique, teclas ignoradas durante a espera, `T_ver` em cada cartão novo e um disjuntor: 6 teclas `K` em menos de 2 s soltam as teclas e pedem `P` para rearmar.
- **Latência**: `Config.remoto.latencia_ms` entra em `T_ver`, para a tecla nunca agir sobre um cartão que o dono ainda não viu.

### 6.7 Alertas

| Evento | Sinal |
|---|---|
| Venda, expiração, lance superado (`AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION`, chega com o leilão fechado; base 2.11) | Linha no terminal e contador no cabeçalho; faixa central para venda grande |
| Disjuntor aberto, API sem resposta, throttle travado, leilão restrito | Faixa central fixa com palavra e forma, e as teclas de ação soltas |
| Fim de bloco, sinal de fadiga | Linha na aba BOOK |
| Pulso vencido | "Paused. Press N" |

A faixa central usa `RaidWarningUtil.AddMessage`; som e ícone (`PlaySound`, `FlashClientIcon`) são reforço, porque podem não atravessar o acesso remoto (base 3.6).

## 7. Risco e conformidade

### 7.1 Guardas, conferidas ao criar o cartão e de novo na tecla

| Guarda | Regra |
|---|---|
| Frescor | Foto do item com menos de `A_exec`; senão `K` só atualiza. |
| Dinheiro | `GetMoney()` (R1c 4) cobre o total mais a reserva de depósito (5% de B). |
| Tetos | Seção 7.2. |
| Banda de preço | POST entre o piso (vendedor dividido por `1 − c`) e 1,5 × V; BUY nunca acima de V. Fora da banda o cartão não existe. |
| Conta própria | Leilão com `containsOwnerItem` ou `containsAccountItem` nunca vira cartão (base 2.3, 2.4). |
| Estado do jogo | Leilão aberto; fora de combate; nenhuma restrição de addon ativa (`C_RestrictedActions`, base 2.16); para postar, throttle pronto (base 2.9). |
| Parâmetro medido | A estratégia só gera cartão se os parâmetros de que depende estão medidos. |
| Anti-surpresa | `T_ver`, uma chamada por clique, cabeça fixa (seção 3.4). |
| Duas teclas | Total acima de 10% de B pede segundo `K` em até 3 s. |
| Sequência | 5 compras GONE seguidas pausam a fila BUY (R9 7.5). |

### 7.2 Tetos iniciais (frações da banca B, marcada a valor de liquidação; R9 7.1)

Por ação 0,10; por item 0,10; por categoria 0,30; exposição total 0,75; perda do dia 0,05 (modo só venda até a virada); perda por item 0,01 (item bloqueado por 24 h); Kelly a 0,25 (R9 7.2, 7.3, 7.5). O dono pode sobrepor qualquer bloqueio pelo UI da Blizzard; o terminal não oferece atalho para isso.

### 7.3 Quando a API falha ou devolve nada

| Sintoma | O que o addon faz |
|---|---|
| Consulta sem resposta em 10 s | Repete até 2 vezes; 3 falhas seguidas param a varredura, com a faixa "AH not answering"; só volta com [TECLA N]. |
| Throttle "não pronto" por mais de 30 s (base 2.14) | Para e pede ao dono fechar e reabrir o leilão. |
| Resultado parcial ou escada vazia | Foto marcada incompleta: não atualiza estimador (R9 1.5) e não gera cartão. |
| Ação sem evento de volta em 10 s (falha muda, base 2.12) | Cartão em NO ANSWER; nunca repete sozinho; concilia pelo dinheiro, pelos leilões próprios e pelo correio. Três seguidas soltam as teclas de ação: "Actions not going through". |
| "Item not found" ao comprar (base 1.11) | Cartão GONE; conta para a sequência. |
| "Internal Auction Error" ao postar equipamento abaixo do menor preço (base 1.11) | Para equipamento só existe o candidato igualar enquanto `erro_interno_equip = true` no `Config.lua`. |
| Cotação acima do teto ou indisponível | Desiste da cotação; cartão PRICE MOVED. |
| `C_Item.GetItemInfo` sem dado (base 3.2) | Pede o dado e segura o cartão; sem preço de vendedor não há cartão. |
| `AUCTION_HOUSE_DISABLED` (R1b 15) ou erro `HasRestriction` (R1a 3) | Para tudo, faixa "Auction house restricted", sem nova tentativa; pode ser um Economy Hold (base 1.10). |
| `timeLeftSeconds` ou `owners` vazios (base 2.3, 2.4) | São opcionais; nada nas fases 1 e 2 depende deles. |

### 7.4 Não parecer RMT

O suporte apontou dois sinais: comprar ou vender item barato por muito ouro e preço muito fora do mercado (base 1.10). O desenho os evita por construção: a banda de preço impede cartão de venda muito acima do valor justo e de compra acima dele; nenhum cartão envolve item da própria conta; o addon não envia ouro nem item por correio e não troca; o livro guarda cada operação com preço e referência de mercado da hora, o que serve de explicação se houver um bloqueio por engano. O ritmo é humano por construção: uma ação por tecla, sem repetição e sem laço.

### 7.5 Acesso remoto

O EULA proíbe serviço de nuvem ou streaming não autorizado a partir de servidor de terceiros e não há posição oficial sobre o acesso remoto ao próprio PC (base 8.3). O addon é indiferente ao meio: toda tecla é tecla do dono. A escolha da ferramenta e a consulta ao suporte são decisão do dono (seção 10).

### 7.6 O que o addon se recusa a fazer

A lista da seção 2 e mais: aceitar roda do mouse como tecla de ação, mesmo sendo binding válido (base 3.4), porque uma roda solta gera dezenas de eventos por gesto e a TSM relata que a Blizzard quebrou a macro de roda dela (base 5.1); agir com o terminal escondido; trocar de fila sozinho; ligar estratégia sem `fonte` preenchida e aprovação registrada; fazer o teste negativo da base 11.1 (chamar ação fora de tecla), porque esse caminho não existe no código.

## 8. Testes

**Bancada com leilão falso.** A bancada atual não simula leilão, dinheiro nem ticker repetido (base 4.9). A nova fica em `wow/modder/ferramentas/pregao/` e reaproveita o método (fengari, API simulada, saída em HTML): um `C_AuctionHouse` falso com as funções e os eventos do contrato (R1a), throttle com fila e prazo, relógio determinístico, dinheiro, correio com fatura e timers que repetem. As oito funções de ação só funcionam dentro de `__tecla(fn)`; fora dele não fazem nada, como no cliente (base 2.12), e a bancada conta a violação. Falhas injetáveis: sem resposta, `DROPPED`, resultado parcial, `ItemNotFound`, `POST_WARNING`, cotação 6% acima, campos nulos.

**Casos de operador** (o teste próprio deste ângulo). Sequências de teclas, inclusive patológicas: duplo toque, tecla presa a 30 repetições por segundo, `K` durante SENT, `K` 50 ms depois da troca de cartão, `K` e `L` alternados às cegas. Invariantes: (I1) chamadas de ação menores ou iguais aos cliques de `K`; (I2) nenhuma ação antes de `T_ver`; (I3) nenhum leilão ou cartão acionado duas vezes; (I4) gasto dentro dos tetos; (I5) sem pulso, zero consulta; (I6) compra de item em 1 tecla, commodity em 2. Mais 200 rodadas de teclas aleatórias com semente.

**Quadros para o dono.** A bancada desenha cada tela e cada estado de cartão em HTML, porque o dono decide vendo quadro (base 4.7).

**Replay das fotos gravadas.** A mesa roda o mesmo `Motor.lua` e as mesmas estratégias sobre as fotos, em ordem de tempo, com os parâmetros da época (R9 10.1). Dois usos: regressão (os cartões gerados têm de ser os gravados no registro) e avaliação em sombra, nas variantes conservadora e central (R9 10.2).

**Checadores estáticos.** `checar-lua.mjs` (sintaxe, ASCII) e `checar-combate.mjs --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER` (base 4.9). Regra nova, R10: os oito nomes de ação só em `Gatilho.lua`; `Gatilho.lua` sem `C_Timer`, `OnUpdate` e `RegisterEvent`; `ReplicateItems`, `SendChatMessage` e funções de movimento em lugar nenhum; nenhuma caixa de texto; `MOUSEWHEEL` fora da lista de teclas de ação. Casos de teste do checador na pasta de casos, no padrão do projeto.

**Sonda no jogo**, um passo por tecla, na ordem:

| # | Mede | Como | Base |
|---|---|---|---|
| S1 | A tecla ligada ao botão satisfaz as funções de ação? | Postar 1 item barato, cancelar, comprar 1 unidade da commodity mais barata, tudo pelo caminho de produção. Só o teste positivo. | 11.1 |
| S2 | Tecla segurada repete o clique? Local e remoto | Segurar `K` 3 s num cartão de treino e contar os cliques | seção 6.6 |
| S3 | Empilháveis são commodity? Como aparece um verde com sufixo? | `GetItemCommodityStatus` nas bolsas; chaves do resumo | 11.2 |
| S4 | Tempo e pedidos do resumo completo; cadência do throttle | Carimbos de uma volta | 11.3 |
| S5 | Depósito por duração e quantidade; corte; devoluções; menor passo de preço | Calculadoras sem postar; faturas de uma venda, um expirado e um cancelado; `SupportsCopperValues` (R1b 7) | 11.6 |
| S6 | Atraso do correio na venda, na compra e no cancelamento | Avisos contra faturas | 11.10 |
| S7 | `owners` e `timeLeftSeconds` vêm preenchidos? | Leitura de 20 escadas | 11.5 |
| S8 | Tempo de reload com 1, 3 e 5 MB; reload por tecla | Ponto de salvamento | seção 3.5 |
| S9 | Quando a marca de ausente aparece com o leilão aberto | Observação passiva: tempo desde a última tecla | 11.9 |
| S10 | Ordem entre preços iguais | Dois lotes de 1 unidade e um comprador combinado (R9 incógnita 1) | 11.7 |

`ReplicateItems` (base 11.4) e a visão entre facções (base 11.8) não são medidos, porque o desenho não depende deles.

**Critério de aceite.** Bancada com 0 erro e os 6 invariantes em todos os casos; checadores com 0 erro; quadros aprovados pelo dono; S1 a S6 com número no diário; replay reproduzindo todos os cartões gravados; 3 sessões em modo treino com taxa de "já sumiu", `T_dec` e teclas por ação medidos; primeira semana ao vivo com exposição total de até 1 ouro.

## 9. Entrega em ondas

Roteamento no padrão do projeto: contrato e portões na sessão principal, dados em Haiku, código em Sonnet (R4a 7); o modelo final de cada tarefa sai da tabela do `executar-plano`.

| Onda | Tarefas | Modelo sugerido | Pronto quando |
|---|---|---|---|
| 0. Contrato | `ARQUITETURA.md` com tabela "API, Contrato" por módulo; esqueletos e TOC; `Config.lua` com tudo desligado; decisões 1 a 4 do dono | sessão principal | `node checar-lua.mjs <pasta>` e `node checar-combate.mjs <pasta> --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER` dão 0 erro |
| 1. Bancada | Leilão falso; regra R10 e seus casos; casos de operador | Sonnet, médio | `node rodar-pregao.mjs --autoteste` dá `RESUMO erros=0` com os esqueletos |
| 2. Mãos | `Nucleo`, `Diario`, `Pedidos`, `Teclas`, `Gatilho`, `Filas`, `Risco` (tetos fixos), `Tela`, `Visual`, `Alertas` | Sonnet, médio; `Gatilho` e `Risco` com portão na sessão principal | `node rodar-pregao.mjs --casos operador` com os 6 invariantes; quadros em HTML aprovados pelo dono |
| 3. Sonda | `Sonda`, `Correio`, `Carteira`; `pregao-ler.mjs` e `pregao-calibrar.mjs` | Sonnet; scripts da mesa em Haiku | Com o jogo fechado, `dev-link.ps1` em prévia e depois aplicado pelo dono; no jogo, S1 a S6 feitos; `node pregao-calibrar.mjs --conferir` lista 0 parâmetro obrigatório ainda estimado |
| 4. Olhos | `Catalogo`, `Fotos`, `Varredura`, `Motor` M0, `Estrategias` E1 e E2, `Sessao`; modo treino | Sonnet, alto para `Fotos` e `Motor` | `node pregao-replay.mjs --regressao` com 0 diferença; 3 sessões de treino gravadas |
| 5. Fase 1 ao vivo | Ligar E2 e, se aprovada, E1, com exposição de até 1 ouro | sessão principal | Uma semana com livro conciliado: diferença entre `GetMoney` e livro igual a 0 em todo fechamento |
| 6. Giro | `Motor` M1 em sombra, E3, E4 e fila CANCEL | Sonnet, alto; portão com revisão do motor | Cobertura do intervalo de V e curva de confiabilidade de P dentro do alvo (R9 1.7, 3.7); `η_real` por estratégia no relatório da mesa; aprovação do dono |
| 7. Profundidade | Tabela de P, E5, E6, sazonalidade | a definir | Critérios próprios, depois da fase 2 |

## 10. Decisões que ficam para o dono

1. **Agir por tecla.** Em 2026-11-06 o dono proibiu, no outro addon, funções que compram ou gastam por código (base 4.6). Aqui, comprar, postar e cancelar por uma tecla é a função central. Recomendação: autorizar só neste addon, só as oito funções, só dentro do `Gatilho.lua`, com a regra R10. Sem essa autorização o projeto vira lista de conferência e perde o motivo de existir.
2. **Commodity em 2 teclas ou em 1 com teto.** `ConfirmCommoditiesPurchase` não leva a marca de restrição (base 2.12), então o addon poderia confirmar sozinho abaixo do teto. Recomendação: 2 teclas. A cotação é o único momento em que o preço real aparece, e o segundo toque é a proteção de dedo mais barata que existe.
3. **Correio por Open All.** Uma tecla no botão da Blizzard recolhe tudo. Alternativa: o dono clica no botão. Recomendação: a tecla, depois do teste S1.
4. **Mapa de teclas.** Recomendação: o conjunto `K L H I M U O N Y B C P`, todo de teclas livres (base 4.10), conferido no teclado do Acer. Tomar o `J` do GuiaForever com o terminal aberto fecharia o bloco da mão direita; não recomendo sem pedido.
5. **Papel dos addons de leilão.** A curadoria não deixa dois addons no mesmo papel (base 4.12). Recomendação: PregaoForever como terminal; Auctionator só para tooltip e preço de partida pela API pública; no ForeverGuide, desligar o compartilhamento de varreduras (base 7.3).
6. **Fontes e ordem de ligar.** E1 e E3 não têm fonte do Forever; várias regras de E2 vêm de sites que vendem ouro (R8b). Recomendação de processo: aprovar E2 primeiro (a fonte já aprovada cobre os verdes), E1 depois do teste de venda da sonda, E3 só depois da sombra. A regra de preço de E2 é escolha do dono entre as que têm fonte.
7. **Tetos e valor da hora.** Recomendação: os tetos da seção 7.2 e um `ω_t` inicial dito pelo dono, trocado pelo lucro por hora medido depois de 5 sessões.
8. **Personagem operador e cidade.** Não há banco de conta (base 4.2) e o ouro está dividido em quatro. É decisão de gameplay; o desenho só pede um personagem parado perto de leiloeiro e caixa de correio.
9. **Acesso remoto.** Recomendação: Sunshine no Avell e Moonlight no Acer (R10a 1.2), com teste de teclado no jogo, e pergunta por escrito ao suporte da Blizzard antes da primeira sessão longa (base 8.3).
10. **Duração do bloco e da sessão.** Recomendação: blocos de 50 minutos, até 3 por sessão, só como sugestão em tela.

## 11. Os cinco maiores riscos deste projeto

1. **A tecla não vale como evento de hardware** (base 11.1). Se o clique de um binding de sobreposição não libera as funções de ação, cai o teclado e fica o cursor estacionado. Se nem o clique num botão do addon liberar, o projeto cai inteiro: só o UI da Blizzard poderia agir.
2. **O gargalo não é o dono.** Se as ofertas boas somem em segundos para bots, ou se com 5 ouro quase nenhum cartão passa do limiar depois de corte e depósito, a fila fica vazia e a velocidade não vale nada. O modo treino mede isso antes de qualquer ouro: cartões acima do limiar por hora e taxa de "já sumiu". Abaixo de uns poucos cartões bons por hora, o ângulo está errado e o esforço deve ir para o motor.
3. **Decisão ruim executada depressa.** Um motor mínimo, sobre um R9 ainda sem revisão matemática (base 10), erra; a interface rápida multiplica o erro, num mercado em que barato pode ser só o preço novo (base 6.1). As defesas são `η_real` em 0,5, tetos, sombra antes de ao vivo e perda diária. Se em 2 semanas o líquido por tecla for negativo com o motor calibrado, o desenho falhou.
4. **O elo remoto.** Tecla presa, latência variável, queda de sessão e a incerteza do EULA (base 8.3). Uma posição contrária da Blizzard derruba a operação remota, não o addon. Uma latência que obrigue a `T_ver` longo derruba a meta de vazão.
5. **A Blizzard muda o chão.** O depósito mínimo muda em 17/11 (base 1.7), há erros ativos no leilão (base 1.11), a TSM relata que a Blizzard quebrou a macro de roda dela (base 5.1) e um Economy Hold por engano congela leilão e correio com capital em trânsito (base 1.10). O diário detecta a mudança, mas cada uma custa uma rodada de sonda. E como o dado só existe quando o dono joga, o motor fica cego para o que acontece fora das sessões.
