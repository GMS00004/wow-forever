> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# PregaoForever, projeto D4: sobreviver primeiro

Data: 2026-11-16. Etapa de design, sem código de addon. Ângulo deste projeto: o lucro vem de não perder.

Como ler. Fato do jogo ou da API vem com a origem entre parênteses: `base 2.7` é o item 2.7 da base de fatos; `R9 5.1` é a seção do relatório; `espelho` é o código da Blizzard no espelho do build 70938. O que não tem origem vem marcado **H:** (hipótese a medir), com o jeito de medir. Valores do motor são iniciais e vêm do R9 (tudo `inferencia`, base 10), salvo onde digo que troquei.

---

## 1. Tese

**De onde vem o lucro com 5 ouro.** O capital é de 50.912 cobre somando quatro personagens (base 4.1), num mega-reino com milhões de personagens (base 1.2) e concorrentes com varredura completa, sniper e postagem assistida (base 5.1 a 5.3). Nesse cenário o dono não ganha por velocidade nem por profundidade de capital. Ganha por três coisas:

1. **Não pagar os vazamentos.** Com banca pequena os custos fixos dominam: depósito perdido quando o leilão expira ou é cancelado (base 1.7; hoje o mínimo é 1 prata, 0,2% do capital inteiro por postagem, e passa a 1 cobre na manutenção de 17/11), corte da casa (5% na leitura provável da tabela do cliente, base 1.4, a medir) e a deriva do mercado. A mediana listada caiu 41% na semana 2 (base 6.1; preço listado de sites que vendem ouro: vale como direção). São cerca de 7% por dia composto: uma posição carregada por 24 horas parte devendo perto de 12%, corte mais deriva, antes de qualquer depósito.
2. **Vender bem o que os próprios personagens produzem.** É a única linha com fonte já aprovada pelo dono (vender no leilão os verdes bons, base 4.5) e a única sem desembolso além do depósito. Cada venda própria também é a medida mais limpa de corte, depósito, atraso do correio e chance de venda (R9 2.9, 3.7).
3. **Arbitragem de saída certa e, só depois, margem medida.** Um arremate abaixo do preço que o vendedor NPC paga não tem risco de preço (R9 5.4). Flip e sniper só entram quando o próprio diário mostrar margem depois de custos: as fontes públicas são do Classic ou de fã e nenhuma mede o Forever (base 6.5).

**Por que este desenho captura isso.** Todo cobre passa por um núcleo de risco (o Cofre), que conhece a banca e o que está preso em leilão, correio e depósito, e nega a ordem em caso de dúvida. Toda estratégia percorre quatro níveis (desligada, papel, micro, plena) e só sobe com evidência medida e aprovação do dono. Todo estimador entra pelo lado conservador. Toda ação é uma tecla do dono, com um bilhete que mostra o pior caso antes.

**Como sai dos 5 ouro, sem promessa.** Três pernas, nesta ordem: (a) venda do estoque próprio com preço, duração e lote calculados; (b) arbitragem contra o vendedor em lotes micro; (c) compra para revenda liberada por evidência. Os tetos são frações da banca e crescem com ela. Aritmética do teto, como ilustração e não previsão: com 10% da banca por item e margem líquida de 10%, um giro completo rende 1% da banca, e o ouro de cada venda volta pelo correio com atraso de cerca de 1 hora (base 1.8). Não há base factual para prometer riqueza com esse capital; há para prometer que um erro não acaba com o jogo.

**O que este ângulo sacrifica.**

- Velocidade: duas teclas por compra e releitura antes de agir. Perde arremates para quem compra com um toque.
- Oportunidade: recusa reset, formação de mercado, lance, casa neutra, equipamento para revenda e varredura completa.
- Crescimento: Kelly fixo em 0,25 e teto de 2% da banca por ordem em micro.
- Dados: a varredura só roda em fôlegos pedidos pelo dono, o que piora a medida de liquidez (R9 2.2).
- Tempo: semanas em papel antes de a maioria das estratégias tocar em ouro.
- Conveniência: nenhum ajuste dentro do jogo; disjuntor travado só destrava por arquivo.

---

## 2. Escopo

### Fase 1: sobreviver e medir

- Sonda dos parâmetros do jogo (seção 8.4), diário de calibração e relatório de sessão.
- Varredura por fôlego: consulta resumida e escada dos itens em foco; histórico próprio de preço, porque não há fonte pública de histórico do Forever (base 5.5).
- Estimadores robustos a isca, parede e dado velho, incompleto ou vazio.
- Cofre completo: banca, exposições, tetos, disjuntores, licenças, conciliação.
- VENDA (postar o estoque próprio) e cancelamento, com tecla do dono, em micro.
- VENDEDOR (arremate abaixo do preço de venda ao NPC), em micro, com lote de confirmação por item.
- FLIP e SNIPER só em papel.
- Correio só por leitura: o addon lê as faturas e concilia; quem pega a carta é o dono.

### Fase 2: a evidência libera a compra

- FLIP e SNIPER rasos de commodity passam a micro e depois a plena, cada um pelo seu portão.
- CONVERSÃO das receitas que o personagem logado conhece, em papel e depois micro.
- Tabela adimensional de P(venda) (R9 3.2 f), detectores de regime com histórico, marca de guerra por item.
- Mesa fora do jogo: replay, backtest conservador, relatório semanal.

### Fase 3: escala condicionada

- Sazonalidade por hora e dia, com três semanas ou mais de histórico próprio (nenhuma fonte mede isso no Forever, R8b 1).
- Abertura de raide em 2026-12-09 (base 6.4), medida em papel.
- Lance com teto de ouro preso, varredura completa e dados externos: cada um só com resultado da sonda e decisão do dono.

### Nunca

Agir sem tecla; encadear duas ações num toque; repetir ação por tecla segurada ou roda; reenviar ação sem eco; clicar botão da Blizzard por código; pegar correio ou negociar com vendedor por código; reset; formação de mercado; casa neutra; comprar com dado vencido; afrouxar teto ou subir licença dentro do jogo; mexer na marca de ausente; configuração na tela; rede. Os porquês estão na seção 7.6.

---

## 3. Arquitetura

### 3.1 Invariantes

São o contrato do addon. Os checadores e a bancada conferem cada um (seção 8).

| # | Invariante |
|---|---|
| I1 | Uma tecla aceita gera no máximo uma chamada de função de ação. |
| I2 | Função de ação só é chamada de dentro do `OnClick` de um botão do addon, em `Acoes.lua`. Nunca de timer, `OnUpdate` ou evento. |
| I3 | Toda chamada de ação vem depois de `Cofre.autoriza` no mesmo quadro e é registrada no Livro antes de qualquer outra coisa. |
| I4 | Nenhuma ordem passa dos tetos duros de `Tetos.lua`, qualquer que seja a configuração. A configuração só aperta. |
| I5 | Ação sem eco vira estado INCERTO e bloqueia o item até conciliar. Nunca há reenvio. |
| I6 | Foto incompleta, vencida ou vazia suspeita não atualiza estimador nem gera sinal. |
| I7 | O nível efetivo de uma estratégia só desce dentro do jogo. Subir é edição de arquivo. |

"Função de ação" são as 7 com `HasRestrictions` (`PostItem`, `PostCommodity`, `ConfirmPostItem`, `ConfirmPostCommodity`, `PlaceBid`, `StartCommoditiesPurchase`, `CancelAuction`; base 2.12) mais `ConfirmCommoditiesPurchase`. A wiki diz que esta última não exige evento de hardware (base 2.13); o design a trata como se exigisse. É a regra de conformidade daqui: onde a base diz "não se sabe se pode", o addon age como se não pudesse.

### 3.2 Módulos e ordem de carga

Pasta `wow/modder/addons-proprios/PregaoForever`; TOC com `## Interface: 16001`, `## Author: Bruno`, `## SavedVariables: PregaoForeverDB` e dependências opcionais ElvUI, Auctionator, Syndicator e Baganator; convenções da base 4.8. Ordem de carga:

| # | Arquivo | Responsabilidade |
|---|---|---|
| 1 | `Nucleo.lua` | `ns`, embrulho `xpcall`, barramento, relógios (`GetServerTime` e `GetTime`, base 3.3), cobre inteiro, anéis, log. |
| 2 | `Tetos.lua` | Tetos duros como constantes. Não é configuração. |
| 3 | `Config.lua` | Do agente: banca, piso pessoal, licença máxima por estratégia, itens reservados, margem absoluta. |
| 4 | `Parametros.lua` | Da mesa: números calibrados, com amostras e data. Fora da faixa segura, vale o padrão conservador. |
| 5 | `Banco.lua` | Esquema das SavedVariables, migração, poda, medidor de tamanho. |
| 6 | `Fila.lua` | Porteiro do throttle: fila única, orçamento por fôlego, vigia de travamento. |
| 7 | `Escada.lua` | Resposta em degraus, sem as unidades próprias, com marca de completude; foto compacta. |
| 8 | `Varredura.lua` | Máquina de varrer (resumo e foco). |
| 9 | `Estimadores.lua` | Preço robusto, nível no tempo, diferença de escadas, liquidez mínima, alarmes. |
| 10 | `Motor.lua` | P(venda), valor de liquidação, candidatos, teste de compra, regra de cancelar. |
| 11 | `Estrategias.lua` | Registro, nível e gerador de sinal de cada estratégia. |
| 12 | `Cofre.lua` | Banca, exposições, tetos, disjuntores, licença efetiva, `autoriza(ordem)`, conciliação. |
| 13 | `Livro.lua` | Diário de ações, lotes por PEPS, sinais com desfecho, amostras de calibração. |
| 14 | `Acoes.lua` | Único arquivo que chama função de ação. Máquinas de comprar, postar e cancelar. |
| 15 | `Teclas.lua` | Botões nomeados e `SetOverrideBindingClick` com a janela aberta (base 3.4, 8.1); filtro de repetição. |
| 16 | `Correio.lua` | Lê cabeçalhos e faturas; concilia. Não pega nada. |
| 17 | `Sonda.lua` | Roteiros de medida que gravam em `calib`. |
| 18 | `Interop.lua` | Pontes com `pcall`: Auctionator, Syndicator, Baganator, ElvUI (base 7). |
| 19 | `Visual.lua`, `Alertas.lua` | Cópia do kit `ns.ui` do dono (base 7.5); `FlashClientIcon`, `PlaySound` e faixa de texto (base 3.6). |
| 20 | `Janela.lua`, `TelaMesa`, `TelaVender`, `TelaLivro`, `TelaRisco`, `TelaSessao`, `TelaCorreio` | Casca, abas e telas. |
| 21 | `PregaoForever.lua` | Eventos de vida e `/pregao`. |

A janela é própria e abre e fecha com `AUCTION_HOUSE_SHOW` e `AUCTION_HOUSE_CLOSED`; aba dentro do `AuctionHouseFrame` causa taint que atinge as bolsas (base 7, último parágrafo). O leilão da Blizzard continua ao lado, intacto.

### 3.3 Fluxo dos dados

```
tecla L -> Fila -> Varredura -> Escada (foto) -> Banco.fotos
                                     |
                                     v
                               Estimadores (estado por item) -> Estrategias (sinais)
                                                                     |
                 Tela <- bilhete <- Cofre.autoriza(ordem) <----------+
                   |
   tecla B/P/C e Y -> Acoes -> API -> evento de eco -> Livro -> Cofre (concilia) -> Banco
                                   +-> sem eco -> INCERTO -> conciliar -> Livro
```

Nenhuma seta sai de Estimadores, Motor ou Estrategias para Acoes. O caminho até a API passa sempre por uma tecla e pelo Cofre.

### 3.4 Fila e throttle

Toda mensagem ao servidor sai por `Fila.lua`, uma por vez.

- Pré-condições: leilão aberto, `IsThrottledMessageSystemReady()` verdadeiro (base 2.14), nenhum pedido pendente da mesma classe, saldo no orçamento do fôlego.
- **Fôlego.** A tecla L concede um orçamento: uma varredura resumida e até 40 buscas de escada, ou 180 segundos. Depois a varredura para e a tela pede a tecla de novo. A base manda o fluxo pedir uma tecla por ciclo e proíbe evitar a ausência por automação (base 8.2); varredura que roda sozinha por horas também é o que mais se parece com robô.
- Busca exata: 30 por minuto, 30% do limite documentado de 100 (base 2.2). A consulta resumida não tem limite escrito (base 2.2); começa em uma varredura a cada 10 minutos. H: custo real pela sonda (base 11.3); as medidas de um autor de addon (7.718 itens em 8,5 s; uma busca a cada 0,4 s; base 2.6) não foram conferidas.
- Vigia, pelos eventos `AUCTION_HOUSE_THROTTLED_*` (base 2.14): PRONTO, ENVIADO, ESPERA, DESCARTADO, TRAVADO. Sem resposta em 10 s, a foto é incompleta. "Não pronto" por mais de 20 s vira TRAVADO, porque a fila pode travar quando uma resposta nunca chega (base 2.14): o addon para de consultar, bloqueia ações e pede ao dono que reabra o leilão. Dois `_DROPPED` encerram o fôlego.

### 3.5 Máquinas de estado

Em todas: `Y` só é aceita se o bilhete está na tela há pelo menos 700 ms e não expirou (20 s); tecla repetida em menos de 500 ms é ignorada (seção 6.4).

**Varrer**

```
OCIOSO --[L]--> RESUMO (SendBrowseQuery por categoria, ordenado por preco)
RESUMO --pagina--> RESUMO (RequestMoreBrowseResults ate HasFullBrowseResults)
RESUMO --completo--> TRIAGEM (candidatos; itens em foco por prioridade)
RESUMO --BROWSE_FAILURE ou 10 s--> marca incompleta -> TRIAGEM com o que e valido
TRIAGEM --> FOCO (SendSearchQuery do proximo item; RequestMore ate HasFull*)
FOCO --resultado completo--> grava foto -> Estimadores -> FOCO (proximo)
FOCO --10 s ou parcial--> foto incompleta (nao atualiza nada) -> FOCO (proximo)
FOCO --orcamento ou tempo esgotado--> OCIOSO ("Press L")
qualquer --TRAVADO ou leilao fechado--> OCIOSO, fila zerada
```

Funções da base 2.1 e 2.2; eventos em R1a 4. Consultas não são funções de ação, e o código da Blizzard também as dispara de eventos (R1b 14). Ainda assim, cada fôlego nasce de uma tecla.

**Comprar commodity** (duas teclas: cotar e confirmar)

```
SINAL --[B], escada com mais de 30 s--> RELENDO (so consulta) -> SINAL reavaliado
SINAL --[B], escada fresca, Cofre autoriza--> COTANDO: StartCommoditiesPurchase   <- tecla B
COTANDO --COMMODITY_PRICE_UPDATED(total)--> total <= limite ? COTADO : RECUSADO
COTANDO --PRICE_UNAVAILABLE ou 5 s--> RECUSADO
RECUSADO --> CancelCommoditiesPurchase -> SINAL ("Quote above limit")
COTADO --[Y] dentro da validade--> CONFIRMANDO: ConfirmCommoditiesPurchase         <- tecla Y
COTADO --[N] ou cotacao vencida--> CancelCommoditiesPurchase -> SINAL
CONFIRMANDO --COMMODITY_PURCHASE_SUCCEEDED--> FEITO -> Livro, confere GetMoney
CONFIRMANDO --COMMODITY_PURCHASE_FAILED--> FALHOU (sem gasto) -> SINAL
CONFIRMANDO --10 s sem eco--> INCERTO
```

Sequência, validade (`GetQuoteDurationRemaining`) e eventos são os da base 2.7 e do R1b 4. O UI da Blizzard aceita a cotação até 5% acima (base 2.7); aqui a tolerância é zero. `CancelCommoditiesPurchase` não gasta nada e a própria Blizzard o chama fora de clique (R1b 4, passo 8); por isso sai sem tecla.

**Comprar item** (duas teclas: armar e executar)

```
SINAL --[B]--> RELENDO: atualiza a busca do item e confere auctionID e arremate
RELENDO --mesmo id, mesmo preco, Cofre autoriza--> ARMADO (bilhete)
RELENDO --sumiu ou mudou--> SINAL ("Gone")
ARMADO --[Y]--> ENVIANDO: PlaceBid(auctionID, arremate)                           <- tecla Y
ENVIANDO --AUCTION_HOUSE_PURCHASE_COMPLETED(id)--> FEITO
ENVIANDO --AUCTION_HOUSE_SHOW_ERROR--> FALHOU (ItemNotFound conta como "ja tinha sumido")
ENVIANDO --10 s sem eco--> INCERTO
```

Arremate é `PlaceBid` com o valor do arremate (base 2.8). O erro "item not found" em leilão que ainda aparece é defeito ativo (base 1.11); a máquina o trata como desfecho normal.

**Postar** (duas teclas; três se o jogo pedir confirmação)

```
ITEM --[P], escada com mais de 30 s--> RELENDO -> ITEM reavaliado
ITEM --[P], escada fresca--> ARMADO: preco, duracao, lote, deposito lido da API, Cofre
ARMADO --[Y]--> ENVIANDO: PostCommodity ou PostItem                                <- tecla Y
ENVIANDO --needsConfirmation falso + AUCTION_CREATED(id)--> FEITO
ENVIANDO --needsConfirmation verdadeiro + POST_WARNING--> AVISO
AVISO --[Y] depois de 1,5 s--> ConfirmPostCommodity ou ConfirmPostItem             <- tecla Y
AVISO --[N] ou 20 s--> ABORTADO (nada postado)
ENVIANDO --POST_ERROR ou SHOW_ERROR--> FALHOU
ENVIANDO --10 s sem eco--> INCERTO
```

Postagem em dois passos e `AUCTION_HOUSE_AUCTION_CREATED` são da base 2.9; o evento de erro, do R1b 6. O que dispara o aviso não está no espelho (R1b, incógnita 7): cada aviso é gravado com o bilhete, para a mesa descobrir a regra. O depósito vem de `CalculateItemDeposit` ou `CalculateCommodityDeposit` (base 1.4). Equipamento posta com quantidade 1 por tecla; o multisell (R1b 6) fica fora da fase 1.

**Cancelar**

```
LEILAO --[C]--> ARMADO: CanCancelAuction, GetCancelCost, deposito em risco, ganho esperado
ARMADO --[Y]--> ENVIANDO: CancelAuction(id)                                        <- tecla Y
ENVIANDO --AUCTION_CANCELED(id)--> FEITO
ENVIANDO --SHOW_ERROR--> FALHOU      ENVIANDO --10 s sem eco--> INCERTO
```

Funções da base 2.10. Leilão com `GetCancelCost` maior que zero não é armado. Repostar é outro ciclo de postagem. O cliente tem o assunto de correio "Auction canceled" (base 1.8). H: o item cancelado volta pelo correio; se for assim, cancelar e repostar custa uma ida à caixa, mais um motivo para não entrar em guerra de preço.

**INCERTO** (ação sem eco). As 7 funções falham em silêncio quando a precondição não vale: `FailureMode = "ReturnNothing"` (base 2.12). Resolução, sempre igual: (1) nenhum reenvio; (2) consultas de conciliação (`QueryOwnedAuctions`, dinheiro, bolsas); (3) o estado do jogo decide entre FEITO com "eco perdido" e NÃO EXECUTADA; sem decisão, o item fica bloqueado até a próxima abertura do leilão ou do correio. Três INCERTO na sessão ligam o disjuntor de ação muda (seção 7.3).

### 3.6 SavedVariables

Uma tabela de conta, `PregaoForeverDB`, com seção por personagem para o que é dinheiro. Só vai ao disco no `/reload`, no logout e ao fechar (base 3.9): daí o fechamento de sessão com reload (seção 6.3) e a regra de o estado do jogo valer mais que o Livro (seção 7.4).

| Chave | Conteúdo | Limite | Tamanho estimado |
|---|---|---|---|
| `calib` | amostras e valores medidos dos parâmetros do jogo | 200 amostras por parâmetro | 30 KB |
| `itens[chave]` | estado O(1) por item, cerca de 30 números (R9 11.3) | 1.500 itens | 0,6 MB |
| `dias[chave]` | anel de 30 dias: mediana, mínimo, máximo, vendas mínimas, exposição | 300 itens | 0,5 MB |
| `fotos[chave]` | escadas compactas em texto: 12 degraus e a cauda em baldes (R9 11.3) | 48 por item de foco, 40 itens | 0,7 MB |
| `sinais` | sinal, nível, bilhete, se executou, desfecho | anel de 3.000 | 0,5 MB |
| `pers[nome].livro` | ações com hora da tecla, eco, dinheiro antes e depois | anel de 2.000 | 0,45 MB |
| `pers[nome].lotes`, `.cofre` | lotes abertos; banca, pico, disjuntores travados, nível efetivo | 200 lotes | 35 KB |
| `sessoes`, `log`, `esquema` | resumo por sessão; últimas 300 linhas; versão do esquema | 60 sessões | 80 KB |

Total estimado: 2,9 MB. Teto: 4 MB, com medidor na tela de sessão; acima de 80% a poda começa pelas fotos já drenadas. A conta segue o R9 11.4 (40 degraus em texto, cerca de 640 bytes). H: tempo de reload com 3 MB, a medir. A chave do item é a `ItemKey` em texto (`itemID:itemLevel:itemSuffix`; base 2.15).

### 3.7 Parte fora do jogo: a mesa

Script do projeto em `wow/modder/ferramentas/pregao/mesa.mjs`. Lê e nunca escreve em `WTF`; escreve só na pasta de desenvolvimento do addon, que é o ciclo normal do projeto (base 4.11) e uma prática antiga de aplicativos companheiros (base 5.6).

Ciclo:

```
no jogo: [O] fecha a sessao -> [Y] reload            (SavedVariables vao ao disco; base 3.9)
na mesa: le PregaoForever.lua das SavedVariables -> arquiva as fotos em modder/dados/pregao/
         -> calibra -> grava Parametros.lua na pasta de desenvolvimento -> relatorio de sessao
no jogo: proximo reload ou login carrega o Parametros.lua novo
```

Contratos de dados:

| Arquivo | Quem escreve | Conteúdo | Defesa |
|---|---|---|---|
| SavedVariables | o addon | o esquema da seção 3.6 | a mesa recusa esquema desconhecido |
| `Parametros.lua` | a mesa | por parâmetro: valor, amostras, data; mais `drenado_ate` (até onde as fotos foram arquivadas) | o addon confere a faixa de cada valor e cai no padrão conservador; nenhum parâmetro alcança `Tetos.lua` |
| `Config.lua` | o agente, com aprovação do dono | banca, piso, licenças, reservas | licença acima do que a evidência sustenta não tem efeito |

A mesa roda o mesmo código de decisão do addon fora do jogo (R9, fecho). A bancada do projeto usa fengari, que é Lua 5.3 e não o 5.1 do jogo (R4a 4): `Estimadores.lua` e `Motor.lua` ficam no subconjunto comum, com regra no checador.

---

## 4. Motor

Regra de adoção: do R9 fica o que tem modo de falha limitado; o que depende de variância bem estimada, de foto densa ou de parâmetro ainda sem medida é trocado por um limite conservador. O R9 não passou por revisor matemático (base 10); por isso o motor nunca autoriza, só propõe ao Cofre.

### 4.1 O que adoto, simplifico ou troco

| Peça do R9 | Decisão | Por quê |
|---|---|---|
| Preço robusto da foto (média aparada das unidades mais baratas depois do filtro de isca) e nível no tempo por EWMA com corte de Huber (1.2) | **Adoto** | Defesa contra isca, cauda cara e foto ruim; estado O(1). |
| Fusão por precisão com o preço das vendas inferidas (1.2) | **Troco** por mínimo | A fusão só é boa com variâncias certas. `V_lo` = o menor entre o limite inferior do EWMA, a mediana do dia e o preço robusto da última foto. Erra para baixo. |
| Vendas pela diferença de escadas, fronteira F (2.1) | **Adoto** | Único jeito de ver venda alheia (base 5.8). |
| Correção ξ do viés (2.2) | **Fora da decisão** | `S_lo` é limite inferior (R9 2.1) e entra como `λ_lo` sem correção. O ξ fica para a mesa. |
| Expiração por coortes e repostagem sem nome (2.3) | **Adio** para a fase 2 | Pede foto densa; o fôlego não dá. |
| P(venda) por tabela adimensional (3.2 f) | **Adio** para a fase 2 | Depende de `ν`, que a fase 1 mede mal. |
| P(venda) na fase 1 | **Simplifico**: `P = η_P · P_dem(q, λ_lo, D)` | `P_dem` é exata sem cobertura (R9 3.2 a, b). O desconto `η_P` = 0,5 cobre a cobertura dos concorrentes até o diário dar a curva real. Empate Ω no pior caso, FIFO, até medir (R9 3.1; base 2.17). |
| Valor de liquidação `W*` (4.1) | **Adoto**, sem custo de atenção | É a moeda comum. O valor do tempo do dono é decisão dele: fica o ordenamento por ganho por tecla e uma margem absoluta no `Config.lua`. |
| Candidatos de preço (4.2) e duração (4.4) | **Adoto**, reduzidos | Cobrir ou igualar a frente depois da isca, `p_parede − tick`, âncoras em `V_lo`; nunca acima de parede (R9 9.3). Três durações, com o depósito lido da API. |
| Cancelar e repostar (4.6) | **Adoto**, com teto de cancelamentos | Depósito perdido no cancelamento (base 1.7) até medir. |
| Teste único de compra, saída na escada pós-compra (5.1) | **Adoto** inteiro | Separa pechincha de queda de regime. |
| Sniper de lance (5.6), reset (6) | **Recuso** | Seção 7.6. |
| Kelly (7.2), tetos (7.3), disjuntores (7.5) | **Adoto e aperto** | `k_K` fixo em 0,25. Kelly só diminui; quem autoriza são os tetos (tabela 4.2). |
| Sazonalidade (8.1) e quebra de regime (8.2) | **Desligo** a primeira até a fase 3; **adoto** a segunda | Com poucos dias as caixas sazonais ficam no prior (R9 8.5). Guarda extra: mediana diária caindo mais de 10% em dois dias suspende compra para revenda. |
| Perfil de concorrente por tempo de reação (9.2) | **Troco** por contagem própria | Se `owners` vem preenchido é incógnita (base 11.5). Leilão meu coberto em menos de 10 minutos, três vezes no dia: o item vira guerra e o conselho é sair (R9 9.3). |
| Isca e parede (9.2); backtest e modo sombra (10) | **Adoto** | Seções 7.5 e 8.2: sem preenchimento otimista, vendas sem ξ. |
| Fatiamento por quadro (11) | **Adoto** com máquina de estados | Fatia de 2 ms; corrotina no Forever é incógnita do R9. |

### 4.2 Valores iniciais

| Parâmetro | R9 | Aqui | Motivo |
|---|---|---|---|
| Janela `H_ref`, apara `α_ap`, isca (`f_isca`, `g_isca`, `J_isca`), `τ_f`, `k_H`; idade para listar e para executar (`A_exec`) | 2 h; 0,2; 0,05, 0,15, 3; 3 h; 2,5; 10 min e 30 s | iguais | Sem evidência para mexer. |
| Quantil conservador `z_c` | 1,0 | 1,5 | O valor justo mede preço listado, não vendido (base 5.8). |
| Margem mínima `μ_min` | 0,10 | 0,15 | Corte provável mais um dia de deriva (base 1.4, 6.1). |
| Desconto do EV `η_real` | 0,5 | 0,5, nunca acima de 1 | Maldição do vencedor (R9 5.7). |
| Desconto de P, `η_P` | não tem | 0,5 | Seção 4.1. |
| Prazo máximo de venda `H_max` | 72 h | 24 h | Deriva de cerca de 7% ao dia (base 6.1). |
| Profundidade de flip `K_flip` | 5 | 2 | Só raso. |
| Captura da demanda `s_cap`; compra diária `x_vol` | 0,3; 0,25 | 0,2; 0,10 | Não ser o mercado. |
| Kelly `k_K` | 0,25, sobe a 0,5 | 0,25 fixo | Chance de a banca cair à metade: 0,8% (R9 7.2). |
| Tetos por item, categoria, total | 0,10; 0,30; 0,75 | 0,10; 0,25; 0,50 | O ouro vendido fica cerca de 1 h no correio (base 1.8). |
| Custo por ordem em micro | não tem | 2% da banca | Seção 7.2. |
| Perda do dia; por item; compras perdidas seguidas | 0,05; 0,01; 5 | 0,05; 0,01; 3 | |
| Corte `c` | a medir | prior 0,05 | Tabela do cliente (base 1.4). |
| Devolução do depósito (venda, expiração, cancelamento) | a medir | prior 0 nos três | Até medir, depósito conta como perdido. |

### 4.3 Regras de decisão

**Postar.** Para cada candidato de preço e cada duração: `W = p·(1 − c) − depósito não devolvido − ((1 − P)/P)·depósito perdido por ciclo − custo de carregar` (R9 4.1, sem a parcela de atenção). Vale o maior W. Se ele não supera o preço do vendedor mais a margem absoluta, ou se o tempo esperado de venda passa de 24 h, a linha diz `vendor it` ou `hold`.

**Comprar.** `EV = η_real · n · U_lcb − custo`, com `U_lcb` = o maior entre o preço do vendedor e o `W*` conservador **na escada que sobra depois da compra** (R9 5.1). Compra só se `EV ≥ max(margem absoluta, μ_min · custo)`, com `λ_lo` acima do mínimo, prazo de até 24 h e Cofre de acordo. Classe da saída: **A** (o vendedor paga mais que o custo), **B** (leilão com liquidez medida), **C** (o resto). Classe C nunca vira sinal.

**Cancelar.** `Δ_canc` do R9 4.6 com depósito perdido; só acima da histerese e dentro do teto diário de cancelamentos.

### 4.4 Como o diário troca estimativa por número

Cada parâmetro do jogo tem estado `prior` ou `medido(n, data)`. O addon grava a amostra crua; a mesa calcula e devolve em `Parametros.lua`. É o padrão do diário de calibração do projeto (base 4.9). A tela de risco mostra quantos já foram medidos.

| Parâmetro | Amostra gravada | Vira medido com |
|---|---|---|
| Depósito por duração e quantidade | a cada bilhete: item, duração, quantidade, preço de vendedor, depósito lido | 5 itens em 3 durações; confere 5%, 20% e 60% do preço de vendedor (base 1.4) |
| Corte `c` | fatura: arremate e consignação (base 3.1) | 3 vendas |
| Devolução do depósito | depósito da fatura e variação do dinheiro | 1 de cada desfecho |
| Atraso do correio | hora em que o leilão vira `Sold` (base 2.10) e hora do ouro | 5 vendas |
| Entrega de compra e de cancelamento | `AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE` (R1a, evento 10) e a chegada real | 3 de cada |
| Throttle e custo da varredura | carimbos dos eventos (base 2.14); pedidos e segundos | 5 fôlegos |
| Curva de P | P prevista e desfecho de cada postagem (R9 3.7) | 30 postagens |
| `η_real` por estratégia | previsto e realizado por lote fechado | 30 lotes |
| Taxa de "já tinha sumido" | sinais que sumiram entre a foto e a tecla | 30 sinais |
| Ω | teste do R9 (incógnita 1), com um segundo jogador | 5 repetições; até lá, pior caso |

---

## 5. Estratégias

Todas nascem desligadas. A licença máxima de cada uma está no `Config.lua`, escrito pelo agente depois da aprovação do dono. Níveis: 0 desligada, 1 papel, 2 micro, 3 plena. Nível efetivo = o menor entre a licença do dono, o nível conquistado pela evidência e o imposto pelos disjuntores.

Portões. E1 e E2 entram em micro pelas condições próprias (uma não compra, a outra tem saída certa); as que compram para revender passam pelo papel:

- **Papel para micro (E3 a E5):** 30 sinais fechados em papel, em 5 dias ou mais; resultado de papel positivo com preenchimento conservador, e ainda positivo sem os 3 melhores sinais; nenhuma perda de papel acima de 2% da banca; corte, depósito e devoluções em `medido`.
- **Micro para plena (todas):** 30 lotes reais fechados; realizado sobre previsto de 0,5 ou mais; resultado positivo; nenhum INCERTO sem solução; drawdown em micro de até 5%.
- A tela mostra `eligible`. Subir é editar o `Config.lua`. Descer é automático e fica travado.

### E1. VENDA: postar o estoque próprio

- **Fonte.** A única fonte de economia aprovada pelo dono: vender no leilão os verdes com bons atributos (base 4.5; R4b 4). Higiene de postagem do R8b, tabela 5: R7 (postar em lotes e rechecar a cada sessão), R8 (nunca listar abaixo do vendedor), R14 (lotes em tamanho de receita), R15 (leilão curto para o que vende rápido; sem dado). Sobre cobrir por 1 cobre ou deixar folga as fontes divergem (R8a ficha 2, F5; R8b R6): o addon escolhe pelo W medido, não por opinião.
- **Sinal e regra.** Item vendável nas bolsas com `W*` acima do preço do vendedor mais a margem absoluta (seção 4.3). Item reservado nunca aparece: o couro do Hexumlite segue o roteiro de Leatherworking por decisão do dono (base 4.5).
- **Risco.** Depósito perdido (base 1.7); queda de preço (base 6.1); "Internal Auction Error" ao postar equipamento abaixo do menor preço (base 1.11), por isso equipamento iguala a frente, que é o contorno relatado.
- **Condição para ligar.** Aprovação; depósito lido da API depois da manutenção de 17/11 (base 1.7); status de commodity medido (base 11.2). Começa em micro: até 5 leilões ativos e depósito em risco de até 1% da banca, até 10 desfechos.

### E2. VENDEDOR: arremate abaixo do preço que o NPC paga

- **Fonte.** R8a ficha 5 (mecanismo com fonte de baixa confiança, mais os fatos oficiais de mudança de preço de vendedor); regra em R9 5.4. Não há fonte pública do Forever para o fluxo (R8a ficha 5). A evidência própria é o **lote de confirmação**: a primeira compra de cada item é de 1 unidade; o dono vende ao NPC; o addon confere pela variação do dinheiro que o valor recebido bate com o lido. Só então o item aceita lote maior.
- **Sinal.** Preço unitário abaixo do preço de venda ao vendedor lido na hora (11º retorno de `C_Item.GetItemInfo`, base 3.2). A Blizzard baixou preços de vendedor em novembro: vale o preço do cliente no momento, nunca tabela (base 6.3).
- **Regra.** `EV = Σ (preço do vendedor − preço) · quantidade ≥ margem da ida ao NPC` (R9 5.4). Saída de classe A. O addon não vende ao NPC: marca o item na bolsa (Baganator, base 7.2) e lista o que levar.
- **Risco.** Preço lido errado; bolsa cheia; a compra chega pelo correio (assunto "Auction won", base 1.8; H: o atraso); concorrência de quem varre mais rápido. H: frequência do sinal, medida em papel.
- **Condição para ligar.** Aprovação; sonda de compra feita (seção 8.4); lote de confirmação por item.

### E3. FLIP raso de commodity

- **Fonte.** R8a ficha 2: guia genérico e guia de fã, baixa confiança; BlizzardWatch 2019 do Classic, média. Regra em R9 5.3.
- **Sinal.** Vão entre os degraus k e k+1, com k de até 2: `p_{k+1} / preço médio pago > (1 + μ_min)/(1 − c) + custos de postagem por unidade` (R9 5.3), com `λ_lo` medido e prazo de até 24 h.
- **Risco.** O vão fecha com oferta nova; deflação (base 6.1); isca (R8a ficha 1, F23); capital parado no correio.
- **Condição para ligar.** Portão de papel, parâmetros medidos, aprovação. Só commodity.

### E4. SNIPER de arremate

- **Fonte.** R8a ficha 1: a mecânica na documentação do TSM de 2022 (Classic) e um limiar de guia genérico de baixa confiança. Nenhuma fonte do Forever. Regra em R9 5.2.
- **Sinal.** Preço de até `a_max = U_lcb/(1 + μ_min)`, limiar derivado por item e não fração fixa (R9 5.2). Oferta funda no preço baixo é preço novo, não pechincha.
- **Risco.** Valor justo velho; concorrentes com sniper (base 5.2); "item not found" (base 1.11); latência do acesso remoto.
- **Condição para ligar.** Portão de papel e um critério de inviabilidade: "já tinha sumido" acima de 70% em 30 sinais declara a estratégia inviável para este operador.

### E5. CONVERSÃO: produzir com receita conhecida

- **Fonte.** R8a ficha 6: o addon Arbitrage descreve o cálculo e o que deixa de fora; a tabela de desencanto é anterior ao BfA. Custo recursivo como ideia pública (base 5.8); grafo de receitas do cliente (base 9.2); regra em R9 5.5.
- **Sinal.** `Lucro − z_c·σ ≥ max(margem absoluta, μ_min · custo dos insumos)`, com a absorção do produto limitada por `λ_lo`.
- **Risco.** Produto sem liquidez; equipamento fabricado é BoP (R4b 5e), então só produto negociável entra; desencanto está fora do cliente (base 9.3) e espera contagem própria.
- **Condição para ligar.** Fase 2; só receita que `C_TradeSkillUI.GetRecipeSchematic` devolve para o personagem logado (base 3.7); portão de papel. Quem fabrica é o dono.

### Sem fonte, ou com fonte fraca: o dado próprio vira a evidência

| Ideia | O que a pesquisa achou | O que o addon faz |
|---|---|---|
| Formação de mercado; lance em leilão acabando | Sem fonte (R8a ficha 3); regra de retail (R8a ficha 7) | Recusa. |
| Reset | Relato de jogador (R8a ficha 4); valor esperado negativo em item líquido no modelo pessimista (R9 6.3) | Recusa. Varrida de terceiro é registrada só para proteger a medida de liquidez. |
| Ciclo de hora e dia | Nenhuma fonte com dado medido (R8b 1) | Guarda o preço robusto por hora dos itens em foco por 3 semanas; a mesa testa fora da amostra e leva ao dono. |
| Abertura de raide | Só previsão de autor do Classic (R8b 3) | Mede em papel os 7 dias antes e os 3 depois de 2026-12-09 (base 6.4). |
| NPC de estoque limitado para o leilão | Sem fonte do Forever (R8a 9.3) | Anota `numAvailable` quando o dono abre um vendedor (base 3.7); nunca compra do NPC. |

---

## 6. Interface

Texto em inglês, sem fonte na tela, cada seção com até 5 linhas e `Show N more` (base 4.7). Sem caixa de texto: com o foco numa caixa as teclas de atalho não disparam (base 3.4). Linhas e botões com 24 px ou mais, contraste de 4,5:1, estado sempre em palavra e nunca só em cor, nada que só exista em tooltip (base 8.4).

### 6.1 Teclas

Todas saem da lista livre da base 4.10 (padrões do cliente não conferidos). Valem só com a janela aberta, por binding de sobreposição (base 3.4, 8.1). Nenhuma é de movimento ou de habilidade.

| Tecla | Função | Gasta ouro? |
|---|---|---|
| `L` | Look: um fôlego de varredura | não |
| `N` | Next ou No: próxima linha; desarma o bilhete; dispensa alerta | não |
| `I` | Info: abre ou fecha a conta da linha | não |
| `B` | Buy: relê, ou arma e pede a cotação | não |
| `P` | Post: relê, ou arma o bilhete de postagem | não |
| `C` | Cancel: arma o bilhete de cancelamento | não |
| `Y` | Yes: executa o bilhete armado | **sim** |
| `H` | Halt: trava o modo só venda até o fim da sessão | não |
| `O` | Over: fecha a sessão (só na aba Session) | não |
| `F1` a `F5` | abas | não |
| roda do mouse | move a seleção | não |

Só `Y` movimenta ouro. O `B` da commodity chama `StartCommoditiesPurchase`, que só pede a cotação (base 2.7).

### 6.2 Telas

**DESK** (F1): varrer, decidir e comprar.

```
+- PregaoForever ----------------------- [F1 DESK]  F2 SELL  F3 BOOK  F4 RISK  F5 SESSION -+
| MODE  MICRO     BANK 4g 00s   FREE 3g 12s   IN MAIL 0s   AT RISK 6%   DAY +0s 00c        |
| API   READY     DATA 0m 42s old             [L] look again (40 items, about 30 s)        |
+------------------------------------------------------------------------------------------+
| SIGNALS (7)                        pay        exit             edge      state           |
| > VENDOR  Light Leather x12      4s 92c     vendor 7s 20c    +2s 28c    LIVE micro       |
|   FLIP    Copper Bar x20        21s 00c     resell ~6 h      +2s 10c    PAPER            |
|   SELL    Heavy Hide x4 (bags)      -       post 0s 96c ea   +3s 31c    LIVE micro       |
|   Show 4 more                                                                            |
+------------------------------------------------------------------------------------------+
| TICKET  none         [B] buy selected   [N] next   [I] why   [H] halt buying             |
+------------------------------------------------------------------------------------------+
| HELD BACK (4)  Wool Cloth: falling 3 days  -  Silk Cloth: stale data  -  Show 2 more     |
+------------------------------------------------------------------------------------------+
```

O bilhete, depois de `B` num sinal real de commodity:

```
| TICKET  QUOTE OK   BUY Light Leather x12                                                 |
|   pay 4s 92c total (0s 41c each)    limit 4s 92c    1.2% of bank                         |
|   exit  vendor 7s 20c  SURE         worst case   0s 00c                                  |
|   [Y] BUY NOW  (quote valid 12 s)   [N] cancel                                           |
```

Em sinal de papel, `B` grava a compra de papel e o bilhete diz `PAPER - no gold moved`.

**SELL** (F2): postar.

```
| BAGS TO SELL (6)             have   post each   time   deposit   chance   net if sold    |
| > Heavy Hide                   4     0s 96c     8 h    0s 02c     61%      +3s 31c       |
|   Medium Leather              20     0s 58c     8 h    0s 08c     55%     +10s 60c       |
|   Wolf Meat                   10     vendor it                             +1s 20c       |
|   Bandit Cloak of the Monkey   1     no reference - price it yourself                    |
|   Show 2 more                                                                            |
| KEPT (2)   Light Leather: reserved for crafting  -  Show 1 more                          |
| TICKET  none         [P] post selected   [N] next   [I] why                              |
```

**BOOK** (F3): leilões próprios, cancelar e repostar.

```
| MY AUCTIONS (5)   deposits at risk 0s 14c     price     left      ahead    advice        |
| > Medium Leather x20                        0s 58c     2-12 h    140 un   CANCEL +1s 90c |
|   Heavy Hide x4                             0s 96c     2-12 h      0 un   KEEP           |
|   Copper Bar x10                            1s 40c     SOLD - gold arrives in 41 min     |
|   Show 2 more                                                                            |
| TODAY   cancels 1 of 2 on this item    deposits lost 0s 03c of 4s 00c allowed            |
| TICKET  none         [C] cancel selected   [N] next   [I] why                            |
```

**RISK** (F4): o Cofre.

```
| BANK      trading 4g 00s    floor 1g 09s (never used)    peak 4g 00s    drawdown 0%      |
| EXPOSURE  stock 6% of 50%   biggest item 2% of 10%   deposits 0.3% of 3%   in mail 0%    |
| BREAKERS  day loss OK    drawdown OK    data OK    api OK    unknown actions 0 of 3      |
| LICENCES             allowed    earned    now                                            |
|   SELL own stock     MICRO      MICRO     MICRO    8 of 10 results                       |
|   VENDOR             MICRO      MICRO     MICRO    4 items confirmed                     |
|   FLIP               PAPER      PAPER     PAPER    12 of 30 paper signals                |
|   SNIPE              PAPER      PAPER     PAPER    gone rate 64%                         |
|   Show 1 more                                                                            |
| MEASURED  7 of 10 game numbers    Show list                                              |
```

**MAIL**: janela pequena, aberta com `MAIL_SHOW` (R1c 1).

```
+- PregaoForever MAIL ---------------------------------------------+
| STATE    READY - snapshot done (12 letters). Take your mail now. |
| SOLD (5)      +14s 20c    cut 0s 75c    deposits back 0s 10c     |
| EXPIRED (2)   2 items back              deposits lost 0s 04c     |
| BOUGHT (3)    3 items to collect                                 |
| PENDING (2)   +6s 10c arriving in 12 to 41 min                   |
| CHECK    waiting for you to take the mail        [N] dismiss     |
+------------------------------------------------------------------+
```

**SESSION** (F5): fechar.

```
| SESSION  1 h 52 m     actions 14 (buy 3, post 8, cancel 3)     unknown 0                 |
| RESULT   realized +9s 40c    stock marked +1s 10c    deposits lost 0s 06c                |
| LEARNED  deposit 6   cut 2   mail delay 2   sale chance 8   gone rate 11                 |
| STORAGE  2.1 MB of 4 MB      last save 52 min ago - unsaved work                         |
| [O] close session and save (reloads the interface)                                       |
```

### 6.3 Fluxos tecla por tecla

**A. Varrer, decidir e comprar.**

1. O dono fala com o leiloeiro. A janela abre e as teclas ligam.
2. `L`. Um fôlego roda; a linha `DATA` mostra a idade.
3. Roda do mouse ou `N` até o sinal. `I` mostra a conta: escada, valor conservador, saída, tetos consumidos.
4. `B`. Escada com mais de 30 s: só relê, e a linha volta reavaliada (apertar `B` de novo). Fresca: commodity pede a cotação (**tecla do dono, `StartCommoditiesPurchase`**); item relê o leilão e arma.
5. Bilhete na tela: total, limite, fração da banca, saída, pior caso.
6. `Y`: **tecla do dono, `ConfirmCommoditiesPurchase` ou `PlaceBid`**. `N` desiste.
7. Resultado em uma linha: `BOUGHT`, `GONE`, `FAILED` ou `UNKNOWN - checking`.

**B. Postar.**

1. `F2`. A lista vem das bolsas; os reservados ficam em `KEPT`.
2. `P` no item: relê se preciso; depois arma com preço, duração, lote, depósito e chance.
3. `Y`: **tecla do dono, `PostCommodity` ou `PostItem`**.
4. Se o jogo pedir confirmação, a faixa `GAME ASKS TO CONFIRM` repete os números. Depois de 1,5 s, `Y` de novo: **tecla do dono, `ConfirmPost...`**. `N` aborta.
5. `POSTED`, e a linha vai para a aba Book.

**C. Cancelar e repostar.**

1. `F3`. Cada leilão traz o conselho: `KEEP`, `CANCEL` com o ganho esperado, ou `LET EXPIRE`.
2. `C` no leilão: bilhete com o depósito que se perde, o custo de cancelar e o ganho esperado.
3. `Y`: **tecla do dono, `CancelAuction`**.
4. Quando o item volta, aparece na aba Sell com a marca `returned`. Repostar é o fluxo B, com as teclas dele.

**D. Recolher o correio.**

1. O dono abre a caixa. A janela MAIL mostra `WAIT - reading (7 of 12)` e depois `READY`.
2. O addon já fotografou cabeçalhos e faturas: lance, arremate, depósito e consignação (base 3.1), mais o atraso e a hora estimada de entrega (espelho, `Blizzard_MailFrame/MailFrame.lua`:576 e :790).
3. **O dono clica no `Open All Mail` da própria Blizzard** (espelho, `Blizzard_MailFrame/MailFrame.xml`:444), ou abre carta por carta. O addon não chama `TakeInboxMoney`, `TakeInboxItem` nem `AutoLootMailItem`.
4. O addon compara a variação do dinheiro com as faturas: `RECONCILED 12 of 12` ou `UNEXPLAINED 3s 10c`.
5. `N` dispensa. H: a fatura pode ser lida antes de a carta ser aberta; se não puder, a conciliação usa só a variação do dinheiro, carta por carta.

**E. Fechar a sessão.**

1. `F5`: resumo, pendências (INCERTO, depósitos em risco, ouro no correio) e o que foi aprendido.
2. `O`: grava o registro da sessão e pede confirmação.
3. `Y`: reload da interface, para as SavedVariables irem ao disco (base 3.9). H: `ReloadUI` funciona a partir do clique de um botão do addon; se não, a tela pede que o dono digite `/reload`.
4. A mesa lê, calibra, escreve `Parametros.lua` e a entrada do diário do projeto (base 4.7).

### 6.4 Acesso remoto

- **Filtro de repetição.** Tecla igual em menos de 500 ms é ignorada; tecla segurada não repete. A repetição nas ferramentas de acesso remoto não está coberta pelas fontes (R10a 1.1).
- **Tempo de leitura e validade.** `Y` só vale 700 ms depois de o bilhete aparecer, e o bilhete expira em 20 s: um `Y` preso na fila de um travamento do stream não confirma o que o dono não viu.
- **Roda só para seleção.** É tecla de binding válida (base 3.4), mas a TSM relata que a Blizzard quebrou a macro de roda (base 5.1): nenhuma ação vai nela.
- **Idade visível.** Acima de 10 minutos a linha `DATA` diz `STALE` e os sinais somem.
- **Relógio, não quadro.** Sem foco, o limite de fundo é de 30 quadros por segundo (base 3.8); os tempos vêm de `GetTime`.
- **Alerta sem depender de som.** O som pode não atravessar o stream (R10a 4): todo alerta tem faixa de texto que fica até o `N`.
- **Ausência.** Parado, o fôlego acaba e nada mais roda; a marca de ausente e a saída por inatividade seguem o curso do jogo (base 8.2).
- **Combate.** Mudar binding em combate falha (base 3.4): as ações ficam bloqueadas e a faixa diz `IN COMBAT - trading paused`.
- **Plano B.** Se o binding de sobreposição não satisfizer o evento de hardware (base 11.1), cada ação vira clique do dono no botão.

### 6.5 Alertas

| Evento | Origem | Forma |
|---|---|---|
| Venda, expiração | `AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION`, que chega com o leilão fechado (base 2.11) | Faixa, som e ícone piscando (base 3.6) |
| Disjuntor ligado | Cofre | Faixa fixa `BUYING HALTED: day loss limit`, até o `N` |
| API travada ou ação muda | Fila, Acoes | Faixa `API STALLED - close and reopen the auction house` |
| Dinheiro sem explicação | Cofre | Faixa `UNEXPLAINED 3s 10c - paper mode until reviewed` |

---

## 7. Risco e conformidade

### 7.1 A banca

- `banca de trading` = o menor entre (banca inicial do `Config.lua` mais o resultado realizado) e (`GetMoney()` do personagem, R1c 4, menos o piso pessoal). O piso é ouro que o addon trata como inexistente.
- Estados do ouro: livre; em estoque comprado, marcado a valor de liquidação conservador e nunca a custo (R9 7.1); em depósito em risco; em correio; em cotação.
- O ouro de outros personagens e o do banco da guilda (que não é do dono, base 4.1) nunca entram. Os 50.912 cobre somam quatro personagens (base 4.1): a banca real é a de quem negocia.

### 7.2 Tetos

Constantes em `Tetos.lua`. A configuração pode baixar cada um, nunca subir.

| Teto | Valor |
|---|---|
| Custo por ordem, nível micro | 2% da banca |
| Exposição por estratégia em micro | 6% da banca |
| Custo acumulado por item, nível pleno | 10% da banca |
| Por categoria | 25% |
| Estoque comprado total | 50% |
| Depósito em risco simultâneo | 3% |
| Depósito perdido no dia | 1% |
| Cancelamentos por item por dia | 2 |
| Compra diária de um item | 10% do volume diário mínimo medido |
| Ações por minuto | 10 |
| Buscas exatas por minuto | 30 |
| Preço de postagem | entre o piso do vendedor e 2 vezes o valor conservador |
| Prazo esperado de venda de item comprado | 24 h |

Kelly (R9 7.2) roda por baixo e só reduz. Com a banca de hoje quem manda são os tetos.

### 7.3 Disjuntores

| Disjuntor | Gatilho | Efeito | Destrava |
|---|---|---|---|
| Perda do dia | −5% da banca (R9 7.5); −1% num item | modo só venda; item bloqueado por 24 h | virada do dia |
| Drawdown | −15% contra o pico; −25% | compra cai para papel; nenhuma compra | edição do `Config.lua` |
| Dado ruim | 3 fotos incompletas seguidas, 2 vazias suspeitas, ou 30% dos itens de uma categoria fora de 2 desvios (R9 8.2 c) | compra suspensa no escopo | fôlego limpo ou 4 h |
| Compras perdidas | 3 "já tinha sumido" seguidas | compra suspensa | próximo fôlego |
| Ação muda | 3 INCERTO na sessão | ações bloqueadas | reabrir o leilão |
| Restrição de conta | `AUCTION_HOUSE_SHOW_ERROR` com `HasRestriction` ou `RestrictedAccountTrial` (R1a 3) | ações bloqueadas, faixa fixa | sessão do agente |
| Halt | tecla `H` | só venda | nova sessão |
| Dinheiro sem explicação | desvio da conciliação acima de 1% da banca | compra em papel | sessão do agente |
| Calendário | datas do `Config.lua`: manutenção semanal, raides em 2026-12-09 (base 6.4) | compra para revenda suspensa | fim da janela |

O disjuntor de restrição existe por causa do Temporary Economy Hold (base 1.10): se a conta perder o leilão no meio da sessão, o addon para limpo e não repete nada.

### 7.4 Quando a API falha ou devolve nada

| Falha | Como aparece | Resposta |
|---|---|---|
| Função de ação que não faz nada (`ReturnNothing`, base 2.12) | sem evento de eco | INCERTO; conciliar; nunca reenviar |
| Throttle que não volta (base 2.14) | "não pronto" por mais de 20 s | TRAVADO; parar; pedir para reabrir o leilão |
| Resposta parcial ou mensagem descartada | `HasFull*` falso no prazo; `_DROPPED` | foto incompleta; não atualiza nada (R9 1.5) |
| Mercado vazio em vez de erro (relato de terceiros, R6a 2.1) | zero linhas onde havia oferta | foto vazia suspeita: descartada, não conta como "tudo vendeu" |
| `timeLeftSeconds` nulo, `owners` vazio (base 2.3, 2.4) | campo ausente | campo opcional; a peça que dependia dele desliga |
| Dado de item não carregado (base 3.2) | `C_Item.GetItemInfo` devolve nada | sem preço de vendedor não há sinal de classe A; pede a carga e espera |
| "Item not found" e "Internal Auction Error" (base 1.11) | erro na compra; erro na postagem | "já tinha sumido"; equipamento passa a igualar |
| Valores sem cobre | `SupportsCopperValues()` falso (R1b 7) | postagem arredondada para prata inteira; arremate sempre no valor listado |
| Queda do cliente antes do reload | o Livro da sessão se perde (base 3.9) | na abertura seguinte o Cofre reconstrói a posição pelo jogo (dinheiro, leilões próprios, bolsas, faturas) e registra o desvio |

Segunda opinião: com o Auctionator carregado, o valor conservador é comparado com o último mínimo visto por ele, pela API pública e com `pcall` (base 7.1). Diferença de mais de 3 vezes marca dado suspeito. É interoperação, não fonte de preço.

### 7.5 Isca, parede e dado ruim

- **Isca.** Degrau com pouca quantidade seguido de salto (R9 1.2). Fica fora do valor justo e nunca serve de âncora para postar: a "frente" é o primeiro degrau depois dela. O padrão de plantar isca para os outros cobrirem tem fonte (R8a ficha 1, F23). A isca só é comprada se o teste passar na escada pós-compra.
- **Parede.** Degrau grande com um ou dois donos (R9 9.2). O addon nunca posta acima dela, pode postar um tick abaixo e nunca a compra.
- **Equipamento.** Como um verde com sufixo aparece na chave é incógnita (base 2.15). Enquanto for, o addon não compra equipamento para revenda e só propõe preço para equipamento próprio quando a escada da mesma chave tem 5 ou mais leilões. Sem isso a linha diz `no reference - price it yourself` e o dono posta pelo leilão da Blizzard.

### 7.6 Como não parecer RMT, e o que o addon se recusa a fazer

O suporte da Blizzard disse que o uso normal do leilão é sempre permitido e que os sinais suspeitos são comprar ou vender item barato por muito ouro e preço muito fora do mercado (base 1.10). Não foi achado relato de punição por addon de leilão dentro das regras (base 5.7). O desenho fica longe dos dois sinais:

- Só compra abaixo do valor conservador e só posta até 2 vezes esse valor; item sem referência não recebe preço do addon.
- Recusa leilão marcado `containsOwnerItem` ou `containsAccountItem` (base 2.3, 2.4): nada de mover ouro entre personagens pelo leilão.
- Ritmo humano: uma tecla por ação e teto de ações por minuto.
- O Livro guarda cada ação com a hora da tecla, o bilhete e o eco: é o registro para mostrar ao suporte, se um dia for preciso.

| O addon se recusa a | Por quê |
|---|---|
| Agir por timer, evento ou em cadeia | Regra do dono (base 4.4, 4.6); o UI da Blizzard só chama as 7 funções de dentro de um clique (base 2.13). |
| Confirmar a compra de commodity dentro do evento da cotação | A wiki diz que a API permite (base 2.13). Seria compra sem tecla dedicada: zona cinzenta. |
| Reenviar ação sem eco | Risco de ação em dobro; a falha silenciosa é documentada (base 2.12). |
| Chamar `:Click()` em botão da Blizzard | Simula entrada; a wiki registra que isso quebra o leilão (R5a 4.2). |
| Pegar correio, vender ou comprar no NPC, enviar correio | O dono proibiu em 2026-11-06 funções que compram ou gastam por código (base 4.6). Ele usa o botão da Blizzard. |
| `ReplicateItems` (fases 1 e 2) | Uma por 15 minutos por conta, resposta que pode não vir, chamada recusada conta para a janela, e já deixou de responder nesta conta (base 2.5). |
| Reset e compra de parede | Só folclore como fonte (base 6.5); valor esperado negativo no modelo pessimista (R9 6.3); preço muito fora do mercado é sinal citado pelo suporte (base 1.10). |
| Formação de mercado; lance (fases 1 e 2) | Sem fonte (base 6.5); ouro preso sem saída e prorrogação desconhecida (R8a ficha 7). |
| Casa neutra e entre facções | Corte de 15% e depósito de 25% na tabela (base 1.4); visibilidade entre facções não confirmada (base 1.3). |
| Comprar equipamento para revenda | Chave de item incerta (base 2.15); a fonte desaconselha (R8a F18). |
| Comprar com escada velha, incompleta ou em alarme; usar o piso pessoal; subir licença ou afrouxar teto no jogo | I4, I6 e I7; seção 7.1. |
| Ter configuração ou caixa de texto na tela | Preferência do dono (base 4.7); foco de teclado (base 3.4). |
| Testar na sonda uma ação sem tecla | O resultado não muda o desenho, e o teste encosta na regra de não contornar evento de hardware. |
| Usar dados externos sem decisão do dono | Rota não documentada e credencial do dono (base 5.4). |
| Ler código ou SavedVariables de addon de terceiro | Base 7. Só API pública em tempo de execução, com `pcall`. |
| Mexer na marca de ausente; enviar dado para fora | Base 8.2. O addon não tem rede nem canal de chat. |

---

## 8. Testes

### 8.1 Bancada com leilão falso

`ferramentas/pregao/bancada-leilao.mjs`, em fengari. A bancada atual não simula leilão, dinheiro nem ticker repetido (base 4.9): esta nasce com `C_AuctionHouse` falso (funções e eventos do contrato em R1a), dinheiro, bolsas, correio com fatura, relógio controlado, ticker que repete e throttle com fila. Cada cenário é um roteiro: mercado, teclas do dono com hora, falhas injetadas.

Cenários mínimos (24): compra normal de commodity e de item; cotação que sobe, fica indisponível ou vence; item que sumiu; `ItemNotFound`; ação muda de cada uma das 7 funções; throttle travado; duas mensagens descartadas; resposta parcial; mercado vazio suspeito; aviso de postagem com `Y` e com `N`; erro de postagem; cancelamento com custo; `Y` repetido em 100 ms; `Y` antes de 700 ms; leilão fechado no meio de uma ação.

Conferências: I1 a I7; chamadas de ação em número menor ou igual ao de teclas aceitas; gasto dentro dos tetos; Livro igual à verdade do simulador; estado final seguro (nenhum bilhete armado, nenhuma cotação aberta). Mais um teste por propriedade: 10.000 roteiros com falhas e teclas ao acaso, com as mesmas conferências.

### 8.2 Replay das fotos

`ferramentas/pregao/replay.mjs` repassa as fotos arquivadas em ordem de tempo com o mesmo `Estimadores.lua` e `Motor.lua`, enxergando só o passado (R9 10.1). Preenchimento conservador: compra só se a oferta ainda estava na foto seguinte; venda só pelas vendas mínimas com prioridade pior, sem ξ (R9 10.2). O papel do replay tem de bater com o que o addon gravou no jogo para a mesma janela. Linhas de base: não fazer nada, e entrada ao acaso com os mesmos tetos (R9 10.4).

### 8.3 Checadores estáticos

- `node checar-lua.mjs <pasta>`: sintaxe 5.1 e ASCII (base 4.9).
- `node checar-combate.mjs <pasta> --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER` (base 4.9).
- Novo, `checar-pregao.mjs`:
  1. as 8 funções de ação só aparecem em `Acoes.lua`, dentro de função com prefixo `tecla_`;
  2. nenhuma `tecla_` é referenciada em `C_Timer`, `OnUpdate` ou `OnEvent`, só em `OnClick` (I2);
  3. cada `tecla_` chama `Cofre.autoriza` antes e `Livro.registra` depois (I3);
  4. lista proibida: `ReplicateItems`, `TakeInboxMoney`, `TakeInboxItem`, `AutoLootMailItem`, `SendMail`, `BuyMerchantItem`, `UseContainerItem`, `SetCVar`, `RunScript`, `loadstring`, `:Click(`, `EditBox` e qualquer envio de mensagem de addon. A lista proibida do projeto hoje não tem função de leilão (R4a 3);
  5. `Estimadores.lua` e `Motor.lua` no subconjunto comum a Lua 5.1 e 5.3;
  6. só `Tetos.lua` define teto.
- Um caso bom e um ruim por regra em `casos-pregao/`, no padrão do projeto.

### 8.4 A sonda no jogo

Ordem pelo peso para este ângulo, a partir da base 11. Cada passo é leitura ou uma ação barata com tecla do dono. Nenhum passo testa o caminho sem tecla.

| # | O que medir | Como | Base |
|---|---|---|---|
| 1 | Binding de sobreposição satisfaz o evento de hardware? | O dono posta um item barato por 2 h com `P` e `Y`. Leilão criado: satisfaz. Se não, repete com clique do mouse no botão. | 11.1 |
| 2 | Depósito, corte e devolução | O mesmo item em três desfechos (vendido, expirado, cancelado), lendo a calculadora, a fatura e o dinheiro. Depois da manutenção de 17/11. | 11.6 |
| 3 | Empilháveis são commodity? Como o verde entra na chave? | `GetItemCommodityStatus` nos itens da bolsa; `GetItemKeyInfo` de um verde visto. | 11.2 |
| 4 | Varredura resumida e throttle | 5 fôlegos cronometrados, com os eventos de throttle. | 11.3 |
| 5 | `owners` e `timeLeftSeconds` vêm preenchidos? | Leitura de 20 escadas. | 11.5 |
| 6 | Atraso do correio; a fatura lê sem abrir a carta? | Com as vendas do passo 2. | 11.10 |
| 7 | Compra: sequência, eco, entrega | Uma commodity de poucos cobres e um item barato, com `B` e `Y`. | 2.7, 2.8 |
| 8 | Cancelado volta por correio? | Com o cancelamento do passo 2. | 1.8 |
| 9 | Ausência com o leilão aberto; Ω | O dono anota quando a marca aparece numa pausa natural. Ω fica para depois: pede um segundo jogador (R9, incógnita 1). | 11.9, 11.7 |
| fora | `ReplicateItems`; facções | Não medidos nas fases 1 e 2. | 11.4, 11.8 |

Os comandos de leitura da seção 16 do R1b servem de conferência cruzada para os passos 3 e 4.

### 8.5 Critério de aceite

- **Para instalar:** os três checadores com saída 0 e a bancada com `RESUMO erros=0` nos 24 cenários e nos 10.000 roteiros.
- **Para a primeira postagem fora da sonda:** passos 1 a 3 gravados em `calib`.
- **Para a primeira compra fora da sonda:** passos 1 a 8 gravados; corte, depósito e devoluções em `medido`; duas sessões em papel sem INCERTO e com conciliação de correio exata.
- **Para cada subida de nível:** o portão da seção 5 e a aprovação do dono.

---

## 9. Entrega em ondas

Padrão do projeto: contrato e esqueletos na sessão principal, tarefas em subagentes, o checador como critério de pronto e um portão da sessão principal por onda (base 4.9; R4a 7). A coluna de modelo e esforço é sugestão de roteamento. O jogo está aberto: até o portão 1 nada toca a pasta do jogo; a ligação por `dev-link.ps1` pede o jogo fechado (base 4.9).

| Onda | Tarefa | Depende de | Modelo/esforço | Pronto quando |
|---|---|---|---|---|
| 0 | T0.1 `ARQUITETURA.md`: tabela "API e Contrato" por módulo, invariantes, esquemas | | sessão principal | o arquivo cita cada função de R1a que o addon usa |
| 0 | T0.2 Esqueletos, TOC, `Tetos.lua`, `Config.lua` com tudo desligado | T0.1 | sonnet/medium | `node checar-lua.mjs <pasta>` e `node checar-combate.mjs <pasta> --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER` com saída 0 |
| 0 | T0.3 `checar-pregao.mjs` e os casos | T0.1 | sonnet/high | `node rodar-casos-pregao.mjs` com `RESUMO erros=0` |
| 0 | T0.4 Bancada com leilão falso | T0.1 | sonnet/high | `node bancada-leilao.mjs --auto-teste` com `RESUMO erros=0` |
| 1 | T1.1 `Nucleo`, `Banco`, `Fila`, `Escada`, `Varredura` | T0.2, T0.4 | sonnet/medium | cenários de throttle e de varredura passam |
| 1 | T1.2 `Estimadores` | T1.1 | sonnet/high | casos numéricos fixos conferem (isca, parede, fronteira, foto incompleta) |
| 1 | T1.3 `Sonda` e `Correio`, só leitura | T1.1 | sonnet/medium | cenário de fatura passa |
| 1 | Portão 1 | | sessão principal | checadores com saída 0; instalar com o jogo fechado; `/pregao sonda` imprime os passos 3 a 5 como `ok` |
| 2 | T2.1 `Cofre`, `Livro` | T1.1 | sonnet/high | cenários de teto e disjuntor passam; 10.000 roteiros sem violar I4 |
| 2 | T2.2 `Motor`, `Estrategias`, tudo em papel | T1.2, T2.1 | sonnet/high | papel do addon igual ao papel do replay em dados sintéticos |
| 2 | T2.3 `Visual`, `Janela` e as telas | T2.1 | sonnet/medium | quadros renderizados aprovados pelo dono (base 4.7) |
| 2 | T2.4 `Alertas`, `Interop` | T2.3 | haiku/medium | checadores com saída 0 |
| 2 | Portão 2 | | sessão principal | duas sessões reais em papel sem erro de Lua; relatório de sessão gerado |
| 3 | T3.1 `Acoes`, `Teclas`: postar e cancelar | T2.1, T2.3 | sonnet/high | 24 cenários e 10.000 roteiros com `RESUMO erros=0`; `checar-pregao` com saída 0 |
| 3 | T3.2 Sonda com ação: passos 1, 2, 6 e 8 | T3.1 | sessão principal, com o dono no jogo | corte, depósito e devoluções em `medido` |
| 3 | T3.3 Comprar (commodity e item) | T3.1 | sonnet/high | cenários de compra passam; passo 7 da sonda gravado |
| 3 | Portão 3 | | sessão principal | aceite da primeira compra (seção 8.5); o dono aprova E1 e E2 em micro |
| 4 | T4.1 `mesa.mjs` | T2.2 | sonnet/medium | reload, mesa, reload: a aba Risk mostra mais parâmetros medidos |
| 4 | T4.2 `replay.mjs` e relatório semanal | T4.1 | sonnet/high | replay de uma semana real reproduz o papel do addon |
| 4 | T4.3 Dados estáticos: preço de vendedor e grafo de receitas (base 9.1, 9.2) | | haiku/medium | checador de dados com saída 0; tabela de até 150 KB |
| 5 | Fase 2: uma tarefa por estratégia | T4.2 | sonnet/high | portão de papel da estratégia e aprovação do dono |

---

## 10. Decisões que ficam para o dono

| # | Decisão | Recomendação |
|---|---|---|
| 1 | Liberar neste addon comprar, postar e cancelar por tecla, sabendo que em 2026-11-06 ele proibiu no outro addon funções que compram ou gastam por código (base 4.6). | Liberar com as condições deste projeto: duas teclas por ação, bilhete com o pior caso, nenhuma compra real antes da sonda e do papel. |
| 2 | Banca de trading e piso pessoal; qual personagem negocia; se junta o ouro dos quatro nele. | Um só personagem negociador, para a banca ser um único `GetMoney`. Banca de 4 ouro e piso de 1 ouro, se o ouro for reunido. Qual personagem é escolha de gameplay: fica com o dono. |
| 3 | Quais fichas dos catálogos R8a e R8b ele aprova como fonte. | Para micro: E1 (a fonte que ele já aprovou e a higiene do R8b) e E2 (R8a ficha 5). Só papel: E3, E4, E5. Recusadas: fichas 3, 4, 7 e 8 do R8a. |
| 4 | Números de perda e margem absoluta mínima por ação. | −5% no dia, −15% trava em papel, −25% trava tudo; margem absoluta depois de medir o depósito real. |
| 5 | Itens reservados para as profissões. | Começar pelo couro do Hexumlite (base 4.5) e completar com ele. |
| 6 | Correio: manter o addon só lendo. | Manter. Uma tecla por carta só se a conciliação por leitura não fechar. |
| 7 | Convivência com o Auctionator e o ForeverGuide, que já ocupam papel de leilão (base 4.12). | Manter o Auctionator na fase 1 como segunda opinião e decidir de novo no portão da fase 2. No ForeverGuide, que por padrão compartilha as varreduras do dono (base 7.3), desligar o compartilhamento. |
| 8 | Acesso remoto em sessões longas, sem posição oficial da Blizzard (base 8.3). | Pedir resposta por escrito ao suporte antes. A ferramenta é escolha dele (comparação em R10a). |
| 9 | Quando parar. | Se em três semanas de papel nenhuma estratégia de compra passar o portão, o addon fica como assistente de venda e de vendedor, e afrouxar se discute com os números na mesa. |
| 10 | Fase 3: lance, varredura completa, dados externos com credencial dele (base 5.4). | Decidir item a item, com o resultado da sonda. Hoje, nenhum. |

---

## 11. Os cinco maiores riscos deste projeto

1. **Ele pode não fazer quase nada.** Com 2% da banca por ordem (cerca de 8 prata em 4 ouro), concorrentes que varrem tudo (base 5.2) e duas teclas por compra, os sinais executáveis podem ficar perto de zero. O dono se frustra e passa a operar por fora, onde nenhuma guarda vale. *O que derruba:* duas semanas de papel com menos de um sinal viável por hora de sessão. Aí a tese é revista com o dono, não afrouxada em silêncio.

2. **A evidência de papel pode enganar nos dois sentidos.** O preenchimento conservador sofre de seleção adversa (o que sobra na foto seguinte é o que ninguém quis, R9 10.2) e a varredura por fôlego subconta vendas (o sintético recupera 40% a 66% com intervalos longos, R9 0.3). Estratégia boa pode nunca passar o portão; ruim pode passar por sorte. *O que derruba:* o realizado em micro divergir do papel por mais de 2 vezes, em qualquer direção.

3. **O caminho da tecla é uma hipótese.** Tudo depende de o binding de sobreposição satisfazer o evento de hardware e de a sequência cotar e confirmar funcionar como no espelho (base 11.1; nada foi testado no Forever, base 2.13). Se a latência do acesso remoto levar o "já tinha sumido" acima de 70%, sniper e flip morrem antes de nascer. *O que derruba:* o passo 1 da sonda falhar também com o clique do mouse.

4. **A conciliação pode travar o addon, ou errar calada.** Atraso do correio, devolução de depósito e entrega de compra e de cancelamento são incógnitas (base 11.6, 11.10). Se a mecânica real não couber no modelo, o disjuntor de dinheiro sem explicação dispara toda sessão e o addon vive em papel. Pior é o erro que não dispara: marca a banca errada e dimensiona tudo errado. *O que derruba:* três sessões seguidas com desvio sem explicação, com a sonda completa.

5. **O valor conservador pode não bastar num mercado em queda.** O valor justo mede preço listado, não vendido (base 5.8), e a deriva é da ordem de 7% ao dia (base 6.1, direção). O mínimo entre estimadores, o quantil de 1,5 e o prazo de 24 h são defesas de modelo, e os modelos do R9 não passaram por revisor nem foram conferidos no jogo (base 10). *O que derruba:* `η_real` abaixo de 0,3 em micro: o motor promete mais que o triplo do que entrega. Fora do alcance ficam um falso positivo do Economy Hold (a Blizzard admite que existem, R5a 3.2) e uma resposta negativa sobre acesso remoto: aí o addon só garante parar limpo e deixar o registro.
