> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# D3-mesa: PregaoForever, o terminal no jogo e a mesa fora dele

Data: 2026-11-16. Projeto independente, pelo ângulo "o addon é sensor e terminal; o cérebro mora fora do jogo". Só design: nenhuma linha de código de addon.

Como ler. Fato do jogo ou da API vem com a origem entre parênteses: `base N.M` (base de fatos) ou o relatório (`R9 4.1`, `R1b 14`). O que não tem origem está escrito como **hipótese**, com a medida que a confirma (`S0` a `S12`, as medidas da sonda, parte 8). "Regra N" é a regra N do dono no enunciado. Os itens e os números das telas desenhadas são ilustrativos.

Nomes. O addon é o **PregaoForever** (o pregão, dentro do jogo). A parte de fora é a **mesa**: scripts Node e sessões do Claude Code, em `wow/modder/ferramentas/pregao/`.

## 1. Tese

**De onde vem o lucro.** O mercado é um só por conjunto de regras e região, com milhões de personagens e mais de 200 mil leilões numa varredura (base 1.2). Nele já operam ferramentas maduras: TSM 4.15 em beta, o ForeverFlip (varredura, sniper, postagem, contabilidade), aux, Auctioneer e outros (base 5.1 a 5.3). Disso saem três consequências.

1. O erro de preço óbvio dura segundos, e neste projeto a corrida de reflexo está perdida por construção: cada ação custa uma tecla do dono (base 4.4), a tecla atravessa um acesso remoto (base 4.11) e a compra de commodity tem cotação e confirmação (base 2.7). Velocidade não é a vantagem.
2. O que sobra é o que as ferramentas dos outros não têm. Nenhuma vê as vendas alheias (base 5.8), não existe histórico público de preço do Forever (base 5.5) e os números que decidem a conta (corte, depósito, ordem entre preços iguais) não foram publicados (base 1.4, 2.17). Quem mede isso no próprio mercado, todo dia, sabe o que o preço mínimo não diz: quanto vende por hora, a que preço sai de verdade e quanto custa errar.
3. O mercado está com preço em queda e oferta em alta (base 6.1): estoque parado perde valor. Giro vale mais que margem, e a decisão que mais rende é a de venda (preço, duração e lote de cada postagem), antes da pechincha.

A tese: **o lucro vem de vender melhor e de comprar só onde a saída foi medida**, em itens escolhidos por taxa de venda e concorrência fraca. É vantagem de informação lenta (dias de série, calibração, escolha de nicho) aplicada com execução fresca (a escada dos últimos 30 segundos).

**Por que este desenho a captura.** A parte lenta não cabe no jogo: Lua 5.1, uma thread, poucos milissegundos por quadro (R9 11.1), sem como testar uma regra contra o passado e sem onde guardar meses de escada. Cabe numa mesa fora do jogo, que guarda o histórico inteiro, roda os estimadores pesados (R9 seções 1, 2, 8 e 9), o backtest (R9 10) e a calibração, e devolve um arquivo de dados pequeno. O jogo fica com o que só ele faz: ler a escada fresca, passar uma régua leve sobre ela e executar com a tecla do dono. Entre uma sessão e outra a mesa tem tempo ilimitado, e é aí que um analista estuda o mercado do dono. É a regra dele de "nada configurado dentro do jogo" (base 4.7) levada adiante: a configuração e a inteligência chegam por arquivo.

**Com 5 ouro** (base 4.1). A fase 1 não arrisca nada. Depois, o capital define o universo: só entram itens cujo lote cabe no teto por item, com tetos fixos no lugar de Kelly (parte 4). Não há promessa de retorno. A meta da fase 1 é medida calibrada; o relatório diz, com os números do próprio dono, se cada estratégia paga depois de corte, depósito e teclas. Se a sombra mostrar que nenhuma paga, o projeto entrega um terminal de venda e um livro-caixa, e diz isso.

**O que este ângulo sacrifica.**

1. Inteligência atrasada em um bloco: o que a mesa aprende só entra no jogo no `/reload` seguinte (base 3.9). Dentro do bloco o addon não aprende; só confere se a ficha envelheceu. Sem a mesa, o terminal cai para um modo conservador e avisa.
2. O `/reload` vira ritual: tela de carga por acesso remoto e, por hipótese, a janela do leilão fechada (S6).
3. Mais peças: um processo vigia no Avell, dois idiomas (Lua e Node) e contratos de dados que podem divergir.
4. O sniper de reflexo fica de fora de propósito. O addon só nomeia pechincha por um gatilho pré-calculado e exige escada fresca antes da tecla.

## 2. Escopo

**Fase 1: sensor, caderno e sombra.** Não gasta ouro e não tem tecla de ação.
- Varre por tecla: resumo do leilão, escadas dos itens em foco e leilões próprios (base 2.1, 2.3, 2.4, 2.10).
- Lê avisos de venda, expiração e lance (base 2.11) e as faturas do correio (base 3.1); monta o livro-caixa.
- Roda a sonda (parte 8) e grava cada medida.
- A mesa ingere, estima, publica fichas e escreve o relatório do dia.
- A régua trabalha em **sombra**: mostra e grava o que recomendaria; o dono age pela tela da Blizzard ou pelo addon que já usa. Única exceção: a postagem de teste da sonda S1.

**Fase 2: terminal de venda e primeira compra.**
- Teclas de postar, cancelar e recolher o correio (pelo botão Open All da própria Blizzard).
- Tecla de compra, só para estratégias aprovadas pelo dono e que passaram pela sombra (parte 5).
- Guardas, tetos, disjuntores e resultado do dia.

**Fase 3: mesa cheia.**
- Conversão por profissão (base 9.2), espera sazonal, perfis de concorrentes, lance em leilão que acaba.
- API de dados da Blizzard de hora em hora, se o dono autorizar (base 5.4).
- `ReplicateItems`, só se a sonda S8 mostrar que responde (base 2.5); compressão do diário com `C_EncodingUtil` (base 3.3).

**O que ele nunca faz.**
- Agir sem tecla: nenhuma compra, lance, postagem, cancelamento ou coleta sai de timer, evento ou laço (regra 1).
- Mais de uma ação por tecla; repetir sozinho uma ação que falhou; enfileirar ações.
- Usar a roda do mouse para ação: a TSM relata que a Blizzard quebrou a macro de roda (base 5.1).
- Evitar a marca de ausente; simular entrada; mandar mensagem de chat.
- Chamar função de ação fora do clique, nem para testar (regra 2): a sonda só faz o teste positivo.
- Ler o código ou as SavedVariables de addons de terceiros; só as interfaces públicas, com `pcall` (base 7).
- Mudar CVar ou binding permanente do dono (base 4.7); gravar na pasta do jogo.
- Compartilhar dados com outros jogadores (a mesa é local; ver o ponto de privacidade em base 7.3).
- Postar ou comprar a preço muito fora do mercado (base 1.10); operar reset (parte 5).

## 3. Arquitetura

### 3.1 O que roda onde

| Onde | Peça | Papel |
|---|---|---|
| Jogo | PregaoForever (Lua) | Sensor, régua leve e terminal de teclas, com a casa de leilões ou o correio abertos (**hipótese**, S3: consulta só responde com a casa aberta). |
| Avell, fora do jogo | `vigiar.mjs` (caminho quente) | A cada `/reload` ou logout: ingere as SavedVariables, atualiza os estimadores e publica os arquivos da mesa. Determinístico. |
| Avell ou Acer | `fechar-dia.mjs` e sessão do Claude Code (caminho frio) | Entre sessões: backtest, sombra, calibração, relatório, propostas ao dono. |
| Opcional | `coletar-api.mjs` | Fotos de hora em hora pela API de dados da Blizzard, se autorizado. |

Regra: o caminho quente nunca depende de um modelo de linguagem. O Claude é o analista do caminho frio: investiga, explica, propõe e, com o sim do dono, edita o `Config.lua`.

### 3.2 Módulos do addon, na ordem de carga

Convenções da base 4.8: Lua 5.1, ASCII, nomes em português, `local _, ns = ...`, globais só com prefixo `PregaoForever`, toda função de evento, timer ou clique dentro de `xpcall`. TOC: `## Interface: 16001`, `## Author: Guilherme`, `## SavedVariables: PregaoForeverDB`, `## OptionalDeps: Auctionator, Syndicator, ElvUI`.

| # | Arquivo | Responsabilidade |
|---|---|---|
| 1 | `Config.lua` | Configuração escrita pelo agente: estratégias (todas desligadas), tetos, teclas, cadências. Nunca gerada pela mesa. |
| 2 | `MesaTabela.lua` | Gerado. Tabela adimensional de P(venda) (R9 3.2 f). |
| 3 | `MesaFichas.lua` | Gerado. Uma ficha por item. |
| 4 | `MesaPlano.lua` | Gerado. Foco do dia, calibração, sazonalidade, parâmetros do jogo medidos, recibo. |
| 5 | `MesaReceitas.lua` | Gerado, fase 3. Grafo de receitas (cerca de 130 KB, base 9.2). |
| 6 | `Nucleo.lua` | `ns`, eventos, `ns.seguro` (xpcall), relógio (`GetServerTime`, `GetTimePreciseSec`, R1c 5), fatiador por orçamento de tempo, log de 60 linhas. |
| 7 | `Formato.lua` | Linhas compactas, dinheiro, chave de item em texto `id:nivel:sufixo` (base 2.15), hash do nome de vendedor. |
| 8 | `Diario.lua` | Caixa de saída: número de sequência, gravação, aplicação do recibo, teto de tamanho. |
| 9 | `Mesa.lua` | Valida cabeçalho e sentinela dos arquivos gerados, monta `ns.ficha(chave)`, calcula a idade, decide o modo (`DESK OK`, `DESK STALE`, `NO DESK`). |
| 10 | `Fila.lua` | Única dona das consultas: uma em voo, orçamento por minuto, timeout, leitura do throttle. |
| 11 | `Varredura.lua` | Máquina de varrer; grava as fotos. |
| 12 | `Escada.lua` | Normaliza escada de commodity e de item, subtrai as unidades próprias, marca isca (R9 1.3). |
| 13 | `Regua.lua` | Motor leve e puro, sem API do jogo: P pela tabela, W, candidatos, regra de cancelar, teste de compra, tetos. Roda igual na mesa. |
| 14 | `Carteira.lua` | Lotes, leilões próprios, ouro por personagem, resultado do dia. |
| 15 | `Guardas.lua` | Tetos, disjuntores, recusas (parte 7). |
| 16 a 18 | `Compra.lua`, `Postagem.lua`, `Cancelamento.lua` | Máquinas de ação. Só estes arquivos podem citar as 7 funções restritas (base 2.12) e `ConfirmCommoditiesPurchase`. |
| 19 | `Correio.lua` | Lê as faturas; liga a tecla ao botão Open All da Blizzard. |
| 20 | `Sonda.lua` | Medidas do jogo. |
| 21 | `Teclas.lua` | Bindings de sobreposição, um botão por ação. |
| 22 a 26 | `Visual.lua`, `Janela.lua`, `Telas.lua`, `Alertas.lua`, `Comandos.lua` | Kit visual do dono reaproveitado (base 7.5), casca, telas, alertas e `/pregao`. |

O conjunto de arquivos é fixo desde a primeira instalação: arquivo novo ou TOC alterado pedem reinício do jogo, e `.lua` alterado só pede `/reload` (R4a 6). Por isso a mesa só reescreve o conteúdo de arquivos que já existem.

Interoperação, só em tempo de execução e com `pcall`: `Auctionator.API.v1` (último mínimo e idade do preço, semente de valor para item nunca varrido, base 7.1), Syndicator (contagem e ouro por personagem, para a banca dos quatro, base 7.2) e o módulo de skins do ElvUI (base 7.5). A janela é própria e abre e fecha com `AUCTION_HOUSE_SHOW` e `AUCTION_HOUSE_CLOSED`; aba dentro do `AuctionHouseFrame` causa taint (base 7).

### 3.3 Fluxo dos dados

```
JOGO   eventos C_AuctionHouse -> Fila -> Varredura -> Escada -> Diario (caixa de saida)
                                              |
                 ficha da mesa + escada fresca -> Regua -> Telas -> TECLA DO DONO
                                                             -> Compra | Postagem | Cancelamento -> Diario
       /reload ou logout grava PregaoForeverDB em WTF/.../SavedVariables/PregaoForever.lua

MESA   vigiar -> ingerir (bruto/AAAA-MM-DD.jsonl) -> estimar (estado.json)
              -> publicar (Mesa*.lua na pasta de desenvolvimento do addon, gravacao atomica)
       /reload seguinte carrega os Mesa*.lua
```

Há dois canais e nenhum outro. Do addon para a mesa: as SavedVariables, que só vão ao disco no `/reload`, no logout e ao fechar o jogo (base 3.9). Da mesa para o addon: arquivos `.lua` de dados na pasta de desenvolvimento, ligada ao jogo por junction (base 4.9), que o `/reload` relê (R4a 6). A mesa nunca escreve em `WTF` nem na pasta do jogo.

### 3.4 Máquinas de estado

Regras comuns. (a) Uma máquina ativa por vez; tecla apertada com máquina ocupada é ignorada e aparece como `ignored (busy)`. (b) Nada se repete sozinho: `FALHOU` só sai por uma tecla nova. (c) As funções de ação são chamadas apenas dentro do `OnClick` do botão que o binding de sobreposição clica; a tecla do dono é o evento de hardware (base 8.1; confirmar em S1). (d) As 7 funções restritas falham sem erro quando a condição não vale (base 2.12): toda ação tem prazo de 5 s e, sem o evento esperado, vira `FALHOU (no response)`.

**Varrer** (consultas em base 2.1, 2.2 e 2.10; throttle em base 2.14). Consulta não leva a marca de restrição (base 2.12), mas cada volta nasce de uma tecla e termina sozinha: o fluxo pede uma tecla por ciclo, como a base 8.2 exige.

```
PARADO --[TECLA Y]--> PROPRIOS: QueryOwnedAuctions -> OWNED_AUCTIONS_UPDATED
 -> RESUMO: SendBrowseQuery; enquanto nao HasFullBrowseResults: RequestMoreBrowseResults
 -> FOCO: por prioridade (R9 11.5), uma consulta em voo: SendSearchQuery -> le a escada em fatias
          (RequestMore* ate HasFull*) -> grava a foto, marcada completa ou incompleta
 -> FIM: grava o resumo da volta, mostra "Scan done", volta a PARADO
saidas: orcamento da volta esgotado | 90 s | AUCTION_HOUSE_CLOSED -> FIM
        consulta sem resposta em 10 s -> foto incompleta e segue; 3 seguidas -> TRAVADO
        IsThrottledMessageSystemReady() falso por 30 s, ou 3 MESSAGE_DROPPED -> TRAVADO (alerta, sem repetir)
```

Orçamento inicial: 40 buscas por minuto, abaixo da metade do limite documentado de 100 (base 2.2), e 40 buscas por volta. O resumo completo entra em toda volta se S3 confirmar a ordem de grandeza relatada (7.718 itens em 8,5 s, base 2.6); senão, a cada N voltas. Foto incompleta nunca atualiza estimador (R9 1.5).

**Comprar commodity** (base 2.7; eventos em R1a 4). Duas teclas, como os dois cliques da tela da Blizzard.

```
PRONTO (linha selecionada; foto <= 30 s; guardas ok)
 --[TECLA B]--> COTANDO: StartCommoditiesPurchase(itemID, n)
     COMMODITY_PRICE_UPDATED(unit, total): total <= limite mostrado -> COTADO (mostra total e validade)
                                           total >  limite          -> CancelCommoditiesPurchase -> RECUSADO
     COMMODITY_PRICE_UNAVAILABLE | 5 s -> FALHOU
 COTADO --[TECLA B]--> COMPRANDO: ConfirmCommoditiesPurchase(itemID, n)
     COMMODITY_PURCHASE_SUCCEEDED -> registra o lote -> PRONTO
     COMMODITY_PURCHASE_FAILED | AUCTION_HOUSE_SHOW_ERROR | 5 s -> FALHOU (conta para o disjuntor)
 COTADO --[TECLA K | cotacao vence]--> CancelCommoditiesPurchase -> PRONTO
```

O limite é mais duro que o da Blizzard, que aceita alta de até 5% (base 2.7): aqui a cotação acima do total mostrado recusa a compra. Desistir de uma cotação não é ação de mercado: a própria Blizzard chama `CancelCommoditiesPurchase` de evento e de temporizador (R1b 14).

**Comprar item** (base 2.8). Uma tecla por leilão.

```
PRONTO --[TECLA B]--> COMPRANDO: PlaceBid(auctionID, buyoutAmount)
     AUCTION_HOUSE_PURCHASE_COMPLETED(auctionID) -> registra -> PRONTO
     AUCTION_HOUSE_SHOW_ERROR (ItemNotFound: ja tinha sumido, base 1.11) | 5 s -> FALHOU
```

**Postar** (base 2.9; eventos em R1a 4). Um lote por tecla; segunda tecla só quando o jogo pede confirmação.

```
PRONTO (lote selecionado; item na bolsa; deposito lido de Calculate*Deposit; IsThrottledMessageSystemReady)
 --[TECLA P]--> POSTANDO: PostCommodity(...) ou PostItem(...)   (caminho por GetItemCommodityStatus, base 2.15)
     needsConfirmation -> AUCTION_HOUSE_POST_WARNING -> AVISO (mostra o aviso)
         --[TECLA P]--> ConfirmPostCommodity | ConfirmPostItem        --[TECLA K]--> PRONTO
     AUCTION_HOUSE_AUCTION_CREATED(auctionID) -> registra (fila, P prevista) -> PRONTO
     AUCTION_HOUSE_POST_ERROR | SHOW_ERROR | 5 s -> FALHOU
```

Em equipamento, o candidato "cobrir" é trocado por "igualar" enquanto o erro relatado ao postar abaixo do menor preço persistir (base 1.11). **Hipótese** (S1): `PostItem` aceita o item direto da bolsa por `ItemLocation`, sem passar pelo painel de venda da Blizzard.

**Cancelar** (base 2.10).

```
PRONTO (leilao selecionado; CanCancelAuction; GetCancelCost mostrado)
 --[TECLA C]--> CANCELANDO: CancelAuction(auctionID)
     AUCTION_CANCELED(auctionID) -> registra, marca "collect at mailbox" -> PRONTO
     AUCTION_HOUSE_SHOW_ERROR | 5 s -> FALHOU
```

Repostar não é uma ação: é cancelar (tecla C), recolher no correio (tecla M) e postar (tecla P). O correio existe para leilão cancelado (assunto "Auction canceled", base 1.8); o atraso é **hipótese** (S5). Esse custo de três teclas e uma caminhada entra no motor como custo de cancelar (parte 4).

**Recolher o correio.** A tecla M clica o botão `OpenAllMail` da própria Blizzard (existe no espelho: `Blizzard_MailFrame/MailFrame.xml:444`), por `SetOverrideBindingClick` (base 3.4). O addon não chama `TakeInboxMoney`; antes e depois ele lê as faturas com `GetInboxInvoiceInfo`, que traz lance, arremate, depósito e consignação (base 3.1). **Hipótese** (S5): o clique por binding num botão da Blizzard funciona e não causa taint; se não, a alternativa é uma tecla por carta com `AutoLootMailItem` (R1c 1).

### 3.5 SavedVariables: esquema e tamanho

```
PregaoForeverDB = {
  esquema = 1,
  casa    = { regras, faccao, casaID },          -- qual mercado (base 1.2, 1.3)
  seq     = 18342,                               -- contador monotonico de registros
  recibo  = 18100,                               -- ultimo recibo da mesa ja aplicado
  bloco   = { id, inicio, build, interface },
  saida   = { "seq|t|tipo|...", ... },           -- caixa de saida: uma linha de texto por registro
  carteira = { lotes = {...}, leiloes = {...}, ouro = {...} },
  medidas  = { ... },                            -- parametros do jogo medidos pela sonda
  guardas  = { dia, resultado, perdidas_seguidas, pausado },
  log      = { ... 60 linhas ... },
  fim      = 18342,                              -- sentinela: arquivo inteiro
}
```

Texto em linhas, e não tabelas aninhadas: cada número em tabela custa 16 bytes de memória (R9 11.4).

| Parte | Estimativa | Base da conta |
|---|---|---|
| Foto inteira do resumo | cerca de 140 KB | 7.718 itens (base 2.6) × 18 bytes |
| Foto do resumo por diferença | 15 a 40 KB | **hipótese**: 10% a 30% das linhas mudam por volta (S3) |
| Escadas de foco, por volta | cerca de 16 KB | 40 itens × 12 degraus exatos mais cauda em baldes (R9 11.3) |
| Ações, avisos, throttle | 2 KB por volta | cerca de 100 bytes por registro |
| Caixa de saída por hora de pregão ativo | 0,4 a 0,7 MB | 12 voltas por hora |
| Parte fixa (carteira, medidas, log) | cerca de 50 KB | 200 lotes × 120 bytes e afins |
| Teto da caixa de saída | 4 MB | aviso em 60%; no teto, descarta primeiro as fotos por diferença |

A primeira foto de cada bloco é inteira. O efeito do tamanho no tempo do `/reload` é medido em S6.

### 3.6 Contratos de dados

**Do addon para a mesa: registros da caixa de saída.** Formato `seq|tempoDoServidor|tipo|campos`.

| Tipo | Conteúdo |
|---|---|
| `F` | Foto do resumo: por chave de item, menor preço e quantidade total (base 2.1); inteira ou por diferença; `completa`. |
| `E` | Escada de commodity: degraus `preco:quantidade:donos`, unidades próprias por degrau, hora do pedido e da resposta, `completa` (base 2.3; R9 1.6). |
| `L` | Leilões de item: id, arremate, lance, faixa de tempo, hash do dono (base 2.4). |
| `P` | Leilões próprios: id, estado (Active ou Sold), quantidade, tempo, lance, arremate (base 2.10). |
| `R` | Recomendação mostrada: candidatos, W de cada um, escolhido (R9 4.8). Existe mesmo em sombra. |
| `A` | Ação do dono: tecla, função chamada, evento de resposta, latência, recomendação que seguiu ou ignorou. |
| `N` | Aviso do jogo: vendido, expirado, lance superado, ganho, com `auctionID` (base 2.11). |
| `C` | Fatura do correio: tipo, lance, arremate, depósito, consignação, atraso (base 3.1). |
| `T` | Throttle e tempos de consulta (base 2.14). |
| `M` | Medida da sonda. |
| `X` | Erro do leilão (código de `AUCTION_HOUSE_SHOW_ERROR`), disparo de guarda ou disjuntor. |

Nome de vendedor nunca é gravado: o `Formato` guarda um hash curto. Perfil de concorrente precisa de identidade estável, não de nome, e nenhum arquivo ou relatório passa a mirar um jogador. O arquivo morto da mesa fica fora do git.

**Da mesa para o addon: arquivos gerados.** Cada um começa com um cabeçalho e termina com uma sentinela:

```
ns.mesa.cab.fichas = { esquema = 1, gerado = 1794800000, ate_seq = 18342, linhas = 1840, duracao_ms = 9200 }
ns.mesa.fichas = { "bloco de ate 200 fichas, uma por linha", ... }
ns.mesa.fim.fichas = true
```

- **Ficha** (uma linha por item): chave; classe de liquidez; `V`, `σ_V`, `σ_h`, `σ_stat` (R9 1.2); `λ`, `λ_lo`, `ν`, `ν_hi`, `φ_λ`, `φ_ν`, `l_f` (R9 2.4); `π_cobre`, `π_iguala`, `ε_d` (R9 3.1); gatilho de compra para o resumo; teto e piso de postagem; hora da última foto usada; número de fotos e de vendas; marcas (`raso`, `so-resumo`, `congelado`, `cobridor rapido` com `τ_r`). Cerca de 90 bytes; 2.000 itens dão cerca de 180 KB.
- **Tabela**: 6.270 entradas de P em milésimos mais os eixos A, ρ, β, ℓ (R9 0.3, 3.2 f); cerca de 25 KB.
- **Plano**: recibo `{ bloco, seq }`; lista de foco com a cadência de cada item; `η_real` por estratégia; `a0_cal` e `a1_cal` por classe; 42 fatores sazonais globais e por categoria (R9 8.1); itens e categorias congelados; parâmetros do jogo medidos; pauta do dia em códigos e números (o texto em inglês mora no addon, para o checador de tela valer).

Blocos de texto, e não uma tabela por item, mantêm a carga leve; o `Mesa.lua` desempacota em fatias.

**Recibo.** Ao carregar, o addon apaga da caixa de saída tudo com `seq` até o do recibo. Se a mesa não rodou, nada se apaga e nada se perde: a entrega é "pelo menos uma vez", e o `ingerir` descarta `seq` repetido.

**Validação e degradação.**

| Situação no carregamento | Modo | Efeito |
|---|---|---|
| Cabeçalho, sentinela e contagem conferem; idade dentro do limite | `DESK OK` | Régua completa. |
| Idade acima de `T_velha` (24 h), ou recibo dois blocos atrás | `DESK STALE` | Sinais de compra desligados; venda segue, com aviso e incerteza inflada. |
| Arquivo ausente, truncado ou de outro esquema | `NO DESK` | Só escada e depósito na tela; nenhuma recomendação de preço. |

**Hipótese** (S6): um arquivo de dados com erro de sintaxe não impede a carga dos seguintes; sem a sentinela dele, o modo é `NO DESK`.

**Gravação atômica.** O `publicar` escreve num temporário e renomeia sobre o arquivo final; o jogo só lê no `/reload`. O `ingerir` espera a data do arquivo de SavedVariables estabilizar, confere a sentinela `fim` e tenta de novo se o texto não fechar. O parser é o `luaparse` que o projeto já tem (R4a 3): lê a tabela como dado, sem executar nada.

### 3.7 O ciclo com `/reload`

| Momento | Dono | Addon | Mesa |
|---|---|---|---|
| Entre sessões | joga outra coisa ou dorme | fechado | `fechar-dia`: backtest, calibração, relatório; `publicar` o plano |
| Login | entra | carrega o plano; mostra pauta e idade | parada |
| Abertura | Y, depois sync duplo | primeira foto inteira; sync | caminho quente sobre o mercado de agora |
| Bloco (30 a 40 min) | Y a cada poucos minutos; B, P, C | varre, recomenda, executa, grava | parada |
| Sync | F9 | fecha o bloco, `C_UI.Reload()` | ingere, estima, publica (alvo de 30 s, **hipótese**, S6) |
| Fecho | F6, depois logout | resumo; o logout grava tudo | caminho frio |

O sync é uma tecla que chama `C_UI.Reload()` (R1c 13). O sync simples deixa a inteligência um bloco atrás. O **sync duplo** (um sync, esperar a contagem da tela, tirada do `duracao_ms` do último cabeçalho, e outro sync) entrega a análise do bloco recém-fechado. O sync também é a única proteção contra queda do jogo: sem ele, uma queda perde o bloco inteiro (base 3.9). Nesta máquina as SavedVariables de outros addons trazem dados recentes (R4b 2), mas há relatos conflitantes sobre a gravação em builds anteriores do Forever (R6b 6, incógnita 4): S6 confere isso antes de qualquer outra coisa.

### 3.8 O que o dono ganha com o analista entre sessões

1. **Pauta do dia**: o que vendeu e expirou desde ontem, o que postar, quais itens vigiar e por quê, com os números medidos.
2. **Ficha de evidência por estratégia**: o sinal medido, o resultado em sombra e no replay das fotos (sem ouro, com a régua do próprio addon), a condição de ligar cumprida ou não. É o que ele aprova ou recusa.
3. **Diário de calibração**: cada estimativa do jogo trocada por número medido, com data e amostra.
4. **Ciclo de hora e de dia do mercado dele**, que nenhuma fonte pública mede (base 6.5).
5. **Mapa do que cabe no bolso**: os itens cujo lote cabe no teto de capital e têm taxa de venda mínima.
6. **Autópsia** de cada lote perdedor: qual previsão errou (valor, taxa, fila ou execução).

## 4. Motor

Princípio: um só código de decisão, dois hospedeiros. A `Regua.lua` é pura; a mesa a executa no fengari que o projeto já usa (R4a 3) para o backtest e para calcular os gatilhos. É a recomendação que o próprio R9 deixa no fim. Os estimadores vivem só na mesa.

| R9 | Decisão | Onde | Por quê |
|---|---|---|---|
| 1. Valor justo e volatilidade | **Adota** inteiro | mesa | Precisa da série inteira. O jogo recebe `V` e as três dispersões e só aplica a idade: `V_lo = V·exp(−z_c·√(σ_V² + min(σ_h²·idade, σ_stat²)))`. |
| 1. Item só com resumo | **Simplifica**: EWMA do menor preço, marca `so-resumo`, σ larga | mesa | O resumo dá mínimo e quantidade, sem escada (base 2.1). Serve para nomear e para a arbitragem de vendedor, não para postar. |
| 2. Vendas pela diferença de escadas | **Adota** fronteira, correção ξ, Gama-Poisson e censuras | mesa | É a informação que ninguém mais tem (base 5.8). |
| 2.3 Expiração por coortes e repostagem sem nome | **Adia** para a fase 3; até lá, uma taxa única γ para o sumiço atrás da fronteira | mesa | Depende de S4 e pesa pouco no começo. |
| 3. P(venda) | **Adota** a tabela adimensional e a recalibração logística; **troca** as fórmulas fechadas por uma reserva só, `P_dem`, exibida como "upper bound" | tabela na mesa, consulta no jogo | As fechadas erram até 0,27 com lotes grandes (R9 0.3); a tabela é dado, não código. |
| 3.1 Regra de empate Ω | **Adota** o pior caso (FIFO) até S7 medir | parâmetro | A base 2.17 só tem fonte secundária dizendo o contrário. |
| 4. W, candidatos finitos, duração, lote | **Adota**, com 8 degraus candidatos, três durações e lotes `{n*, estoque}` | jogo | Precisa da escada fresca. Cerca de 700 avaliações de P por item (estimativa a partir de R9 11.2), em fatias de 2 ms. |
| 4.6 Cancelar e repostar | **Adota** `Δ_canc`, com `κ_cancel` de três teclas e a ida ao correio | jogo | Com esse custo, repostar é exceção; a régua tende a duração curta e lote pequeno (R9 4.4, 4.5). |
| 5.1 a 5.4 Teste único de compra, na escada pós-compra | **Adota** | jogo, com `V_lo`, `λ_lo`, `ν_hi` da ficha | Separa pechincha de queda de regime. |
| 5.1 Lugar do desconto `η_real` | **Troca**: desconta o ganho, não a saída inteira: `EV = η_real·(n·U_lcb − Custo) − teclas` | jogo | Na fórmula do R9 5.1, com 0,5 inicial só passaria margem acima de 100%. O R9 define `η_real` de dois jeitos (4.8 e 5.7); fica o de 5.7, ganho realizado sobre ganho previsto. |
| 5.2 Sniper | **Troca** a varredura contínua por nomeação: mínimo do resumo abaixo do gatilho leva a uma busca, e o teste completo roda antes de armar a tecla | gatilho na mesa | Não disputa reflexo (parte 1). |
| 5.5 Conversão | **Adota** na fase 3; a recursão de custo roda na mesa | mesa e jogo | Recursão pesada; o jogo só reconfere com a escada fresca. |
| 5.6 Lance | **Adia**, nasce desligado | fase 3 | Não tem backtest possível (R9 10.2). |
| 6. Reset | **Só análise** no relatório; nunca vira sinal | mesa | Valor esperado negativo em item líquido no modelo pessimista (R9 6.3) e sem fonte boa (R8a ficha 4). |
| 7. Kelly | **Troca** por tetos fixos e lote de sondagem até haver 30 lotes fechados por estratégia; Kelly aparece só como informação | jogo | Kelly é muito sensível a retorno superestimado (R9 7.7), e `η_real` começa sem dado. |
| 8. Sazonalidade e regime | **Adota** o encolhimento hierárquico e o detector de amplitude por categoria | mesa | Com poucos dias é o único que funciona (R9 8.2 c). O jogo recebe fatores e a lista de congelados. |
| 9. Concorrentes | **Adota** na fase 3, se S4 mostrar donos visíveis | mesa | O jogo só recebe a classe e `τ_r`, e troca P por `P_ciclo` (R9 3.2 e). |
| 10. Backtest e sombra | **Adota**, com as duas variantes de preenchimento | mesa | É o produto central deste ângulo. |

**Valores iniciais.** Os da tabela C do R9 (entre eles `A_exec` 30 s, `η_real` 0,5, `μ_min` 0,10 e `ℓ_dia` 0,05, que dá 25 prata por dia no começo), com estas trocas:

| Parâmetro | R9 | Aqui | Motivo |
|---|---|---|---|
| `w_item`, `w_cat`, `w_tot` | 0,10; 0,30; 0,75 | 0,20; 0,40; 0,60 | Com 5 ouro, 10% por item compra pouco mais que um lote; a reserva maior cobre depósitos. Decisão do dono (parte 10). |
| `k_K` | 0,25 | só exibido | Ver a linha de Kelly. |
| `ω_t` (valor do tempo) | informado pelo dono | 1 ouro por hora | Ponto de partida baixo para não zerar todo sinal; sobe com o lucro por hora medido. |
| `T_q` | 2 ms | 2 ms | Medido por `GetTimePreciseSec`; com o limite de 30 quadros em segundo plano (base 3.8) o fatiador conta tempo, não quadros. |

Corte, depósito, devoluções, durações, tick e Ω não têm valor inicial assumido: entram como "a medir", e a régua usa sempre o depósito que `Calculate*Deposit` devolve na hora (base 1.4). Antes da medida do corte, a régua mostra o líquido com a leitura provável de 5% (base 1.4) e a marca `est.`.

**Diário de calibração: como a estimativa vira número medido.** O addon grava o sinal; a mesa calcula; o arquivo `calibracao.md` registra data, amostra, valor antigo e novo.

| Parâmetro | Sinal gravado | Regra de troca | Quem aplica |
|---|---|---|---|
| Corte `c` | fatura: arremate e consignação (base 3.1) | 3 faturas concordantes | mesa, direto (fato do jogo) |
| Depósito e devoluções `r_s`, `r_x`, `r_c` | `Calculate*Deposit` por duração; fatura de venda, de expiração e de cancelamento | um de cada desfecho | mesa, direto |
| Ω | qual de dois lotes próprios no mesmo preço vende primeiro (S7) | 5 de 5 iguais; senão "aleatória" | mesa, direto |
| ξ (vendas subcontadas) | fotos densas subamostradas (R9 2.9) | uma sessão densa por classe de liquidez | mesa, dentro da faixa do R9 |
| `a0_cal`, `a1_cal` | P prevista contra o desfecho de cada postagem | 50 postagens por classe | mesa, dentro da faixa |
| `η_real` | resultado realizado contra o previsto, por estratégia | 30 lotes fechados | mesa, dentro da faixa |
| Buscas por minuto; custo de cada tecla | registros `T`; latência entre tecla e resposta | uma sessão; 20 ações de cada tipo | mesa, direto |
| Tetos, margens, estratégias ligadas | resultado e calibração | nunca automático | proposta no relatório; o dono decide; o agente edita o `Config.lua` |

A separação é a regra 3 aplicada: fato do jogo e ajuste estatístico a mesa troca sozinha, dentro de faixas; o que é decisão de risco ou de estratégia fica com o dono.

## 5. Estratégias

Todas nascem com `ligada = false` no `Config.lua`. O addon mede e calcula; a fonte fica no arquivo e no relatório, nunca na tela. "Ligar" exige as duas coisas: o dono aprovar a fonte e a condição medida estar cumprida.

| # | Estratégia | Fonte | Sinal mensurável | Regra | Risco | Condição para ligar |
|---|---|---|---|---|---|---|
| E1 | Venda calibrada do que o dono já tem | Fonte aprovada: vídeo do Studen, dica 4 (base 4.5; R4b 4). Regras de apoio: não listar abaixo do vendedor, lotes em tamanho de receita, leilão curto para o que vende rápido (R8b 5: R8, R14, R15); margem real em vez de um cobre (R8b 5: R6; a fonte F5 do R8a ficha 2 diz o oposto, por isso o W decide) | W de cada candidato na escada fresca; P calibrada | Postar no candidato de maior W; não postar se `W* ≤ vendedor` (R9 4.3) | Queda de regime (base 6.1); erro ao postar equipamento abaixo do mínimo (base 1.11) | S1, S2 e S5 feitas; dono autoriza a tecla P |
| E2 | Leilão abaixo do preço de vendedor | R8a ficha 5 (preços de vendedor mudados por hotfix, F6; zona de cuidado, F17). O R8a registra que não há fonte do Forever para o fluxo; a conta é aritmética | Menor preço do resumo abaixo do preço de venda ao vendedor lido do cliente na hora (base 3.2, 6.3) | R9 5.4: comprar enquanto o preço for menor que o do vendedor e o ganho cobrir a ida ao vendedor | Hotfix de preço (base 6.3); item que vira vinculado ao vender (R8a ficha 5): equipamento fica fora | 20 sinais em sombra, com a taxa de "já tinha sumido" medida |
| E3 | Compra abaixo do valor medido (sniper por nomeação) | R8a ficha 1: documentação do TSM Sniper (Classic, 2022) e guia genérico; sem fonte do Forever | Saída conservadora na escada pós-compra contra o custo (R9 5.1) | Comprar se o ganho esperado passar das margens e dos tetos | Valor velho, isca (R8a ficha 1), regime caindo | 30 sinais em sombra; `η_real` em sombra maior que 0; previsão de venda dentro do alvo |
| E4 | Flip no vão da escada | R8a ficha 2 (guias de Classic e de fã; aviso de não comprar equipamento, F18) | Vão entre degraus e `λ_p − ν_f` no preço de repostagem (R9 5.3) | Comprar os degraus 1 a k e repostar abaixo do degrau seguinte | O vão fecha com oferta nova; estoque parado | Como E3, e só commodity |
| E5 | Conversão por profissão | R8a ficha 6 (descrição pública do addon Arbitrage, F11; tabela de desencanto antiga, F16) | Lucro da receita com custo na profundidade e saída conservadora (R9 5.5) | Só receitas que os personagens do dono conhecem (base 3.7, 4.2) e produto que não vincula ao pegar (o equipamento fabricado vincula, R4b 5e) | Rendimento não medido no Forever (base 9.3); preço de vendedor muda | Fase 3; 10 execuções medidas por receita |
| E6 | Espera pela hora ou pelo dia | R8b ficha 1: conselho de guia sem medida; nenhuma fonte mede o ciclo no Forever (base 6.5) | Fator sazonal por caixa de 4 horas e dia (R9 8.1), com intervalo de confiança | Usar `W_espera` (R9 4.3) só nas caixas cujo fator se separa de 1 | Só há fotos nas horas em que o dono joga (R9 8.5) | Fase 3; duas semanas com o intervalo excluindo 1 |
| E7 | Abertura de raide em 2026-12-09 | R8b ficha 3: previsão de autor e anedota de fórum; data em base 6.4 | Preço e quantidade de uma cesta de consumíveis, 7 dias antes e 3 depois | Só medir e relatar; nenhuma compra para estoque | Folclore sem número | Não liga por este design: o dono escolhe uma fonte antes |

**Ficam de fora, e por quê.**
- **Lance em leilão que acaba**: fonte fraca, do retail (R8a ficha 7), e sem backtest possível (R9 10.2). Fica para a fase 3, desligado; só o diário de lances próprios o avaliaria.
- **Formação de mercado com spread**: sem fonte pública (R8a ficha 3; base 6.5). Como o dado próprio vira evidência: a mesa simula, no replay, postar dos dois lados em itens de foco e relata o resultado conservador; só depois disso o dono teria o que avaliar.
- **Reset**: folclore (R8a ficha 4), valor esperado negativo em item líquido (R9 6.3), capital que não existe. A mesa só detecta resets de terceiros como evento (R9 2.4) para congelar o item.
- **Arbitragem entre facções pela casa neutra**: fonte de fã, corte provável de 15% (base 1.4; R8a ficha 8), e os quatro personagens são da Aliança (base 4.2).

## 6. Interface

Janela própria, em inglês, sem fonte na tela, cada seção com até 5 linhas e `Show N more` (base 4.7). Sem caixa de texto: com o foco numa caixa as teclas não disparam (base 3.4), e não há o que digitar.

### 6.1 Teclas

Todas por `SetOverrideBindingClick`, válidas só com a janela aberta e limpas com `ClearOverrideBindings` ao fechar (base 3.4, 4.10). Escolhidas entre as livres pelos arquivos (base 4.10); os padrões do cliente ficam por conferir em S0.

| Tecla | Ação | É ação de leilão? |
|---|---|---|
| F1 a F4 | Abas Desk, Buy, Sell, Orders | não |
| F6 | Tela de fecho da sessão | não |
| U / N | Linha de cima / de baixo | não |
| O | Show N more / less | não |
| I | Painel Why (os números da linha) | não |
| Y | Uma volta de varredura | consulta |
| B | Buy: cotar e, na segunda, confirmar; em item, arrematar | **sim** |
| P | Post: postar o lote; segunda só se houver aviso | **sim** |
| C | Cancel: cancelar o leilão selecionado | **sim** |
| M | Mail: clicar o Open All da Blizzard | **sim** |
| K | Skip: dispensar a recomendação (fica registrada) | não |
| H | Hold: pausar e retomar os sinais | não |
| F9 | Sync: recarrega; pede a segunda tecla em 3 s como confirmação | não |

Binding não muda em combate (base 3.4): a janela só liga as teclas fora de combate e fica em leitura se houver restrição ativa (`C_RestrictedActions`, base 2.16).

### 6.2 Telas

**Desk (F1): a pauta que a mesa mandou.**

```
+---------------------------------------------------------------------------+
| PREGAO  [F1 Desk]  F2 Buy  F3 Sell  F4 Orders        Gold 5g 09s  Hold OFF |
+---------------------------------------------------------------------------+
| DESK OK   synced 21:04 (block 3)   desk age 6 min                         |
| TODAY                                                                     |
|  1  Post       14 lots ready, 3 items                             > F3    |
|  2  Watch      38 items in focus, scan every 5 min                > Y     |
|  3  Frozen     Cloth (price regime changed)                               |
|  4  Forecast   31 lots closed, sale chance on target                      |
|  5  Shadow     Buy signals 12, would have filled 5                        |
|     Show 2 more [O]                                                       |
| SESSION   scans 14   unsynced 0.8 of 4.0 MB   next sync in 12 min         |
+---------------------------------------------------------------------------+
| Y Scan   F9 Sync   H Hold                       last key: Y  scanning 9/40 |
+---------------------------------------------------------------------------+
```

**Buy (F2): sinais e a compra em duas teclas.**

```
| BUY   scan 21:07   38 of 38 complete   photo age 12 s                     |
|    Item             Ask      Limit    Qty  Exp.gain  Sells in  Signal     |
|  > Light Leather    1s 20c   1s 31c   40    8s 40c   3 h       FLIP       |
|    Copper Bar       2s 05c   2s 10c   20    2s 60c   2 h       VALUE      |
|    Wool Cloth       0s 31c   0s 33c   60    1s 20c   vendor    VENDOR     |
|    Show 4 more [O]                                                        |
| WHY [I]  exit 1s 62c net  |  sale chance 71% in 8 h  |  cap 20% ok        |
| STATE    READY   press B to quote 40 x Light Leather, max 52s 40c         |
| B Quote/Confirm   K Skip   U/N Select   Y Rescan            last key: N   |
```

Depois da primeira tecla a linha de estado troca para `QUOTED 48s 00c, valid 23 s   press B to confirm, K to drop`.

**Sell (F3): o que há na bolsa e como postar.**

```
| SELL   6 items in bags   deposit shown is the game's own number           |
|    Item             Have  Lot  Price    Time  Deposit  Chance  Net/unit   |
|  > Light Leather     86   20   1s 58c   8 h   0s 12c   74%     1s 44c     |
|    Copper Bar        40   20   2s 28c   8 h   0s 20c   61%     2s 05c     |
|    Rough Stone       60    -   below vendor: do not post                  |
|    Show 3 more [O]                                                        |
| WHY [I]  front 1s 59c x 140  |  ahead of you 0  |  net is est. (fee 5%)   |
| STATE    READY   press P to post 20 x Light Leather at 1s 58c for 8 h     |
| P Post   K Skip   U/N Select                               last key: F3   |
```

**Orders (F4): leilões próprios e o conselho de cada um.**

```
| ORDERS   12 active   2 sold, payment pending   1 advice                   |
|    Item             Lot  Price    Left     Ahead  Chance  Advice          |
|  > Copper Bar        20  2s 30c   Long     260     9%     CANCEL, REPOST  |
|    Light Leather     20  1s 58c   Medium     0    81%     KEEP            |
|    Show 10 more [O]                                                       |
| WHY [I]  repost at 2s 21c is worth 14c more per unit after 3 key costs    |
| STATE    READY   press C to cancel 20 x Copper Bar (cancel cost 0c)       |
| C Cancel   K Skip   U/N Select                              last key: U   |
```

**Mail (abre com a caixa de correio, evento `MAIL_SHOW`, R1c 1).**

```
| MAIL   7 auction mails   4 sold   2 expired   1 canceled      +36s 12c    |
|    Sold      Light Leather x20   +30s 02c   fee 1s 58c   deposit back     |
|    Expired   Rough Stone x20     item back  deposit lost 8c               |
|    Show 5 more [O]                                                        |
| STATE    READY   press M to open all                                      |
```

**Close (F6): o fecho da sessão.**

```
| CLOSE SESSION                                                             |
|  Result today    +14s 20c   (realized +9s 40c, stock mark +4s 80c)        |
|  Actions         buys 3   posts 14   cancels 2   mails 7                  |
|  Open orders     12 lots, 3 will expire in the next 2 h                   |
|  Unsynced        1.1 MB, saved when you log out                           |
|  Next            full desk report after logout                            |
| F9 Sync now, or log out                                                   |
```

### 6.3 Fluxos tecla por tecla

1. **Varrer, decidir e comprar.** Abrir a casa, a janela abre sozinha → `Y` (uma volta; a barra mostra `scanning 9/40`) → `F2` → `N` até a linha → `I` se quiser os números → `B` (cota; o addon confere o total contra o limite) → `B` (confirma) → estado `BOUGHT`, próxima linha. Foto com mais de 30 s: o `B` não cota, mostra `photo too old, press Y`.
2. **Postar.** `F3` → `N` até o lote → `P` (posta um lote) → se o jogo avisar, `P` de novo ou `K` → `POSTED`, a seleção desce. Catorze lotes são catorze teclas, pelo menos.
3. **Cancelar e repostar.** `F4` → `N` até a linha com `CANCEL, REPOST` → `C` → ir à caixa de correio → `M` → voltar à casa → `F3` → `P`.
4. **Recolher o correio.** Abrir a caixa → o painel Mail lista as faturas → `M` → o painel confere o que entrou contra o livro-caixa e mostra a diferença, se houver.
5. **Fechar a sessão.** `F6` → conferir os números → `F9` (ou sair do jogo, que também grava) → a mesa roda o caminho frio; o relatório fica pronto para a próxima sessão do Claude Code.

### 6.4 Adaptações para o acesso remoto

- **Teclado primeiro.** Tudo o que importa tem tecla; o mouse por stream é impreciso. Alvos de clique com pelo menos 24 px, contraste de 4,5:1, estado sempre em palavra (`READY`, `QUOTED`, `FAILED`), nunca só cor, e nada que exista apenas em tooltip (base 8.4).
- **Eco de tecla.** O rodapé mostra a última tecla recebida e o que ela disparou. Com latência, é o que evita a segunda tecla por dúvida.
- **Uma tecla, uma ação.** Intervalo mínimo de 400 ms entre ações; tecla com máquina ocupada é descartada, nunca enfileirada. **Hipótese** (S1): tecla segurada não repete o clique do binding; a guarda vale nos dois casos.
- **Ausência.** O addon não toca na marca de ausente. Mostra há quanto tempo foi a última tecla e deixa a volta de varredura terminar e parar; a referência de 5 minutos é de wiki antiga (base 8.2), e S9 mede.

### 6.5 Alertas

Venda, expiração e lance superado chegam por evento mesmo com a casa fechada (base 2.11). Cada alerta sai por três vias: mensagem central (`RaidWarningUtil.AddMessage`), `FlashClientIcon` e `PlaySound` (base 3.6). O som pode não atravessar o stream (R10a 4), por isso nunca é a única via.

| Alerta | Quando |
|---|---|
| `SOLD` / `EXPIRED` / `OUTBID` | aviso do jogo (base 2.11) |
| `DESK STALE` | idade da mesa acima do limite |
| `SYNC SOON` | caixa de saída em 60%, ou 40 min de bloco |
| `THROTTLE STUCK` | fila do jogo parada (base 2.14) |
| `HOLD ON` | disjuntor disparou; mostra qual |
| `AH RESTRICTED` | erro de restrição ou leilão desativado (parte 7) |

## 7. Risco e conformidade

**Guardas** (todas em `Guardas.lua`; cada disparo vira registro `X`).

| Guarda | Regra |
|---|---|
| Foto fresca | Compra só com escada de até 30 s; senão a tecla pede nova varredura. |
| Preço-limite | Cotação acima do total mostrado recusa a compra (mais duro que os 5% da Blizzard, base 2.7). |
| Tetos | Por item, por categoria, total, por dias de volume e por fração do volume diário (R9 7.3). |
| Banca | Ouro dos quatro personagens pelo Syndicator, se presente (base 7.2), mais estoque marcado a valor de liquidação (R9 7.1). |
| Perda do dia | Em −5% da banca, modo só venda até a virada; perda por item bloqueia o item por 24 h (R9 7.5). |
| Compras perdidas | 5 "já tinha sumido" seguidas pausam os sinais (R9 7.5; o erro existe no Forever, base 1.11). |
| Dados e ritmo | Fotos incompletas em sequência, throttle travado, mesa velha ou relógio incoerente suspendem a compra; 400 ms entre ações. |
| Piso e teto de postagem | Nunca abaixo do preço de vendedor dividido por (1 − corte) (R8b 5: R8); nunca acima do teto da ficha. |

**Quando a API falha ou devolve nada.**
- Ação sem resposta (base 2.12), consulta sem resposta e throttle parado (base 2.14) seguem as regras de 3.4: prazo, estado de falha, nenhuma repetição. Duas ações seguidas sem resposta ligam o Hold; foto incompleta nunca é lida como mercado vazio (R9 1.5); com a fila parada, o conserto é do dono (fechar e abrir a casa).
- `AUCTION_HOUSE_SHOW_ERROR` com `HasRestriction`, `Unavailable` ou `IsBusy`, ou `AUCTION_HOUSE_DISABLED` (R1a 3 e 4): o terminal para limpo e mostra `AH RESTRICTED`. É o comportamento certo diante de um Economy Hold (base 1.10): parar, não insistir.
- Mesa ausente ou inválida: modo `NO DESK` (3.6).

**Como não parecer RMT** (base 1.10: os sinais citados pelo suporte são item barato por muito ouro e preço muito fora do mercado).
- Toda compra é, por construção, abaixo do valor medido; a régua não tem caminho para comprar acima dele.
- Postagem acima do teto da ficha é recusada, com o motivo na tela.
- O relatório aponta concentração: se um mesmo vendedor (pelo hash) passar de uma fração das compras, a mesa avisa.
- O ritmo é o de uma pessoa: uma tecla por ação, sem rajada.

**O que o addon se recusa a fazer**: agir com a janela fechada; comprar com ficha congelada ou velha; postar abaixo do vendedor; dar lance ou comprar em nome de um plano que o dono não ligou no `Config.lua`; continuar depois de um erro de restrição; usar `ReplicateItems` fora da sonda nas fases 1 e 2 (uma chamada recusada conta para a janela de 15 minutos, base 2.5).

**API de dados da Blizzard.** Só com credencial e autorização do dono (base 5.4). As rotas são relato de comunidade e os termos só foram vistos por resumo de busca (R6b 1.2, 2.2): ler os termos na íntegra antes da primeira chamada (S12). A credencial fica fora do repositório.

## 8. Testes

**Bancada com leilão falso.** A bancada atual não simula leilão, dinheiro nem ticker repetido (base 4.9; R4a 4). O `leilao-falso.mjs` acrescenta um `C_AuctionHouse` falso (resumo paginado, busca com throttle configurável, cotação e compra, `PlaceBid`, postagem com e sem confirmação, leilões próprios, cancelamento, eventos), dinheiro, bolsas, correio com faturas, relógio do servidor, ticker repetido e bindings.
- **Bandeira de hardware.** A bancada só marca "dentro de tecla" enquanto despacha um clique simulado. Qualquer chamada às 7 funções restritas, a `ConfirmCommoditiesPurchase` ou ao clique do Open All fora da bandeira reprova o teste. É a regra 1 virada em teste executável.
- **Falhas injetadas.** Resposta que nunca chega, função que devolve nada, fila travada, cotação 6% acima, erro `ItemNotFound`, arquivo da mesa truncado ou de outro esquema.
- Limite conhecido: o fengari é Lua 5.3, não 5.1 (R4a 4); o `checar-lua` cobre a sintaxe.

**Replay das fotos gravadas.** `replay.mjs` repassa o arquivo morto em ordem de tempo pela mesma `Regua.lua`, com validação progressiva e as duas variantes de preenchimento (R9 10.2, 10.3). Determinismo: a mesma entrada produz as mesmas recomendações. As simulações do R9 (R9 0.3) viram teste de regressão dos estimadores.

**Checadores estáticos.**
- `checar-lua.mjs` e `checar-combate.mjs --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER,BINDING_` (base 4.9).
- `checar-pregao.mjs`, novo: (1) funções de ação só nos arquivos 16 a 19 e só dentro de função marcada `-- tecla-do-dono`; (2) proibidos `C_Timer`, `OnUpdate` e laços nos arquivos de ação; `ReplicateItems` só em `Sonda.lua`; nada de `SetCVar`, `SetBinding`, `SendChatMessage`; (3) texto de tela sem "Source" e sem acento; (4) acesso a addon de terceiro só pela lista de interfaces públicas e com `pcall`.
- `checar-mesa.mjs`, novo: esquema, cabeçalho, sentinela, contagem e faixas dos `Mesa*.lua`. Um teste de ida e volta garante que o empacotador em Lua e o leitor em Node concordam linha a linha.

**A sonda no jogo.** Ordem pela seção 11 da base, com as medidas próprias deste ângulo logo no começo.

| # | O que medir | Como | Base |
|---|---|---|---|
| S0 | Leituras sem ação: durações, faixas de tempo, cobre, commodity por item da bolsa, depósito por duração, teclas padrão | comandos de R1b 16, colados pelo dono | 11.2, 11.6 |
| S1 | A tecla serve: um binding de sobreposição dispara `PostCommodity` ou `PostItem` de um item barato, direto da bolsa | uma postagem, uma tecla; só o teste positivo | 11.1 |
| S6 | O ciclo da mesa: o `/reload` grava o arquivo? em quanto tempo? com 0,5, 2 e 4 MB? a casa fecha? o arquivo de dados alterado entra sem reiniciar? um arquivo quebrado isola? | três `/reload` cronometrados com a mesa vigiando | 3.9 |
| S2 | Commodity de verdade e chave de um verde com sufixo | `GetItemCommodityStatus`, uma busca de cada tipo | 11.2 |
| S3 | Resumo completo: tempo, pedidos, repetição, cadência do throttle | registros `T` de uma sessão | 11.3 |
| S4 | `owners` e `timeLeftSeconds` vêm preenchidos? | campos de uma escada e de uma lista | 11.5 |
| S5 | Depósito real, corte na fatura, devolução ao vender, expirar e cancelar; atraso do correio | três leilões baratos, um por desfecho | 11.6, 11.10 |
| S7 | Ω | dois lotes próprios de 1 unidade no mesmo preço, em horas diferentes; ver qual vende; 5 vezes | 11.7 |
| S9 | Ausência com a casa aberta | registrar a última tecla e a hora em que a marca aparece | 11.9 |
| S10, S11 | Atraso entre o aviso de venda e a fatura; a casa da Aliança mostra leilão da Horda? | avisos `N` contra registros `C`; observação | 11.10, 11.8 |
| S8 | `ReplicateItems` responde? | uma chamada, fase 3 | 11.4 |
| S12 | API de dados: uma leitura com a chave do dono | fase 3, se autorizado | 5.4 |

**Critério de aceite.**
- Fase 1: os checadores com zero erro; a bancada passa com zero chamada fora de tecla; S0, S1, S6, S2 e S3 registradas no diário; sete dias de fotos ingeridas sem buraco de sequência; a mesa publica em menos do tempo medido em S6 mais 50%; previsão de venda em sombra melhor que a linha de base ingênua (R9 10.4) no índice de Brier.
- Fase 2: 50 postagens com desfecho e a curva de confiabilidade dentro do alvo (R9 3.7); nenhuma ação registrada sem tecla correspondente no diário; livro-caixa batendo com o ouro do jogo.
- Fase 3: cada estratégia nova só entra com a ficha de evidência cumprida (parte 5).

## 9. Entrega em ondas

Padrão do projeto: a onda 0 é contrato e esqueleto na sessão principal; as seguintes são tarefas com o checador como critério de pronto (base 4.9; R4a 7). O roteamento é sugestão; o dono escolhe o modo de execução.

| Onda | Tarefa | Depende | Roteamento | Pronto quando |
|---|---|---|---|---|
| 0 | `ARQUITETURA.md` com a tabela API e contrato de cada módulo; esqueletos e TOC; esquema dos registros e dos `Mesa*.lua` | — | sessão principal | `node checar-combate.mjs <pasta> --toc --prefixos ...` dá 0 erro nos esqueletos |
| 0 | `checar-pregao.mjs` e `checar-mesa.mjs` com casos bons e ruins | contrato | sonnet/medium | `node rodar-casos-pregao.mjs` passa |
| 1 | `leilao-falso.mjs` com a bandeira de hardware e as falhas injetadas | contrato | sonnet/high | a suíte da bancada roda e reprova um caso plantado de chamada fora de tecla |
| 1 | `Nucleo`, `Formato`, `Diario`, `Fila`, `Varredura`, `Escada`, `Sonda` | contrato | sonnet/medium | bancada: uma volta grava registros `F`, `E`, `P`, `T` que o leitor da mesa aceita |
| 1 | `ingerir.mjs`, `publicar.mjs` em modo semente, `vigiar.mjs` | esquema | sonnet/medium | teste de ida e volta passa; `checar-mesa` dá 0 erro no que foi publicado |
| 1 | `Mesa.lua`, `Janela`, tela Desk, `Teclas` (Y, navegação, F9) | núcleo | sonnet/medium | bancada: os três modos (`DESK OK`, `STALE`, `NO DESK`) aparecem com os arquivos certos e errados |
| 2 | **No jogo, com o dono**: instalar por `dev-link` com o jogo fechado; S0, S1, S6, S2, S3 | onda 1 | sessão principal | cinco medidas no diário de calibração; decisão sobre o ciclo registrada |
| 3 | `estimar.mjs` (R9 1, 2, 8) com as simulações do R9 como regressão; `tabela.mjs` | arquivo morto | sonnet/high, revisão na sessão principal | erros das regressões dentro dos números de R9 0.3 |
| 3 | `Regua.lua` e `replay.mjs`; telas Buy, Sell e Orders em sombra; `Carteira`, `Correio` (leitura) | tabela, fichas | sonnet/high | replay determinístico; a bancada mostra recomendação sem nenhuma função de ação no código |
| 3 | `fechar-dia.mjs` e o relatório do dia | estimar | sonnet/medium | relatório gerado de sete dias de dados reais; **portão da fase 1** |
| 4 | `Guardas`, `Postagem`, `Cancelamento`, tecla M, alertas; S5, S7 | portão 1 e autorização do dono | sonnet/high | bancada com falhas injetadas passa; 10 postagens reais registradas com tecla e desfecho |
| 5 | `Compra`, E2 e as estratégias aprovadas | 30 sinais em sombra por estratégia | sonnet/high | ficha de evidência cumprida; **portão da fase 2** |
| 6 | Conversão, sazonal, concorrentes, API, lance | portão 2 | por tarefa | ficha de evidência de cada uma |

## 10. Decisões que ficam para o dono

| # | Decisão | Recomendação |
|---|---|---|
| 1 | Autorizar teclas que postam, cancelam e compram. No outro addon ele proibiu função que gasta por código (base 4.6). | Sim, por etapas: vender e cancelar na fase 2; comprar só depois da sombra. A tecla é dele, uma por ação. |
| 2 | Deixar a mesa gravar os `Mesa*.lua` na pasta de desenvolvimento com o jogo aberto, e um vigia rodando no Avell. | Sim. É o ciclo que o projeto já usa para editar addon (base 4.11); a pasta do jogo e o `WTF` continuam intocados. |
| 3 | Cadência do sync. | Duplo na abertura; simples a cada 30 a 40 min; rever com o custo medido em S6. |
| 4 | Fontes de estratégia (base 4.5): quais fichas do R8a e do R8b ele aceita como "pode testar em sombra". | Aceitar E2, E3 e E4 para sombra; E1 já tem fonte aprovada; E5 a E7 esperam a fase 3 e os dados. |
| 5 | Tetos de risco com 5 ouro e o valor do próprio tempo. | 20% por item, 60% no total, perda diária de 5%, 1 ouro por hora de partida. |
| 6 | Compra de commodity em duas teclas ou em uma com confirmação automática dentro do limite. | Duas. É o que a tela da Blizzard faz e é a guarda contra preço que andou. |
| 7 | API de dados da Blizzard com credencial dele. | Ler os termos, fazer uma chamada de teste e só então decidir; ela daria cobertura das horas em que ele não joga. |
| 8 | Curadoria: Auctionator e ForeverGuide já ocupam o papel de leilão (base 4.12); o ForeverGuide compartilha varreduras por padrão (base 7.3). | Manter o Auctionator até o portão da fase 2 (o addon usa a interface pública dele); desligar o compartilhamento do ForeverGuide; decidir a troca no portão. |
| 9 | Perguntar por escrito ao suporte sobre acesso remoto ao próprio PC: não há posição oficial (base 8.3). | Perguntar: custa pouco e fecha uma incerteza. A escolha da ferramenta está no R10a. |

## 11. Os cinco maiores riscos deste projeto

1. **A tecla não basta.** Se o binding de sobreposição não satisfizer a exigência das funções de ação, ou se elas falharem em silêncio no Forever (base 2.12, 2.13, 11.1), o terminal não executa. *O que derruba*: S1 negativa. *O que sobra*: sensor, mesa e sombra, com o dono clicando na tela da Blizzard.
2. **O ciclo com `/reload` não se sustenta.** Se as SavedVariables não forem gravadas de modo confiável (R6b 6), se o `/reload` por acesso remoto custar minutos ou fechar a casa a cada vez, o sync dentro da sessão morre e a mesa vira analista de um dia para o outro. *O que derruba o ângulo inteiro*: gravação não confiável; aí não há canal do addon para a mesa.
3. **A vantagem não existe nesta escala.** Com 5 ouro, corte, depósito e o custo de cada tecla podem comer toda a margem, e os concorrentes com ferramenta ficam com o resto. *Sinal*: `η_real` em sombra menor ou igual a zero em todas as estratégias de compra depois de duas semanas. O projeto continua valendo como terminal de venda e livro-caixa, mas não como "ficar rico".
4. **A inferência de vendas é fraca demais com as fotos que haverá.** As fotos dependem de uma tecla por volta e de o dono estar parado na casa; o viés cresce com o intervalo (R9 2.2), e o modelo todo é inferência sem revisor matemático (base 10). *O que derruba*: a previsão de venda não bater a linha de base em 50 postagens. *Saída*: regras simples calibradas só pelas vendas próprias.
5. **Operação e conformidade.** São dois programas, um vigia, contratos de dados e um ritual; um arquivo velho lido como novo recomenda preço errado, e um Economy Hold ou uma leitura dura dos termos (acesso remoto, API de dados) para tudo (base 1.10, 8.3). *O que derruba*: o dono sentir que o ritual custa mais atenção do que devolve em ouro. A defesa é o modo `NO DESK` sempre funcional e a medida do custo por tecla no próprio diário.
