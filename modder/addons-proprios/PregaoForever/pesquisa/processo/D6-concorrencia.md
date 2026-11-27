> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# D6-concorrencia: NichoForever, o addon que escolhe onde lutar

Data: 2026-11-16. Projetista D6 (ângulo: seleção de mercado e concorrência). Etapa de design: nenhuma linha de código de addon.

Como ler. `base X.Y` é um item da base de fatos; `R9 3.2`, `R8a F17`, `R1b 14` são relatórios; `espelho` é código da Blizzard que eu li no espelho. **[H]** marca hipótese a medir, sempre com o jeito de medir. Todo limiar é valor inicial de `Config.lua` ou `Calibrado.lua`, nunca fato do jogo. Nomes de item e números dentro das telas são ilustrativos.

Nome proposto: **NichoForever** (comando `/nicho`). PregaoForever serve; proponho a troca porque o nome diz a única coisa que este projeto faz diferente: antes de dizer a que preço postar, ele diz em que mercado vale a pena estar.

## 1. Tese

**O campo.** A casa de leilões é uma só por conjunto de regras e região: cerca de 3,6 milhões de personagens contados em 15/11 e mais de 200 mil leilões numa varredura (base 1.2). Os concorrentes têm ferramenta: TSM 4.15, ForeverFlip (varredura, sniper, postagem e cancelamento quando coberto), aux-forever, Auctioneer, um sniper do autor do Auctionator (base 5.1 a 5.3; R6a 2.10). Os preços listados caíram 41% na mediana da semana 2, com 63% mais unidades à venda (base 6.1).

**Por que não dá para ganhar na velocidade.** Três resultados do modelo do R9 (inferência conferida por simulação, não fato do jogo; base 10) valem para qualquer mercado líquido: em regime estacionário a oferta nova é maior ou igual à demanda, então a posição na frente é passageira (R9 3.1); contra um concorrente que cobre com tempo médio `τ_r`, a chance de vender antes de ser coberto é `(λ_p·τ_r / (1 + λ_p·τ_r))^(q+1)` (R9 3.2e); e guerra de cobertura é guerra de desgaste, porque cada repostagem nossa custa uma ação do dono (R9 9.3). A regra do projeto (uma tecla por compra, postagem e cancelamento) fixa esse custo. [H] Ele ainda pode ser maior: o cliente tem o evento `AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE(purchasedItemDeliveryDelay, cancelledItemDeliveryDelay)` (R1a, evento 10) e os assuntos de correio "Auction canceled" e "Auction won" (base 1.8), o que sugere que item cancelado ou comprado volta pelo correio, com atraso; medir com um cancelamento na sonda. Se for assim, cada rodada de guerra custa cancelar, ir à caixa de correio, pegar e postar.

**De onde vem o lucro, então.** De quatro assimetrias que dependem de dado, não de reflexo:

1. **Terreno**: itens em que a demanda chega mais rápido do que os concorrentes reagem. A medida é a razão de reação `RR = λ_p·τ_r` (vendas esperadas antes de alguém cobrir). Com `RR ≥ 1` cobrir funciona; com `RR ≪ 1` não funciona para ninguém que pague por ação.
2. **Hora**: blocos do dia em que os cobridores daquele item não estão presentes e ainda há demanda. Nenhuma fonte mede ciclo de hora no Forever (base 6.5; R8b ficha 1); o addon mede o do próprio mercado.
3. **Posição**: preços em que o cobridor não segue (abaixo do piso observado dele), à frente de uma parede, ou dentro de um vão da escada (R9 4.3, 9.3).
4. **Custo real**: corte, depósito por duração e devolução medidos na fatura (base 3.1). A Blizzard não publicou esses números (base 1.4), e são eles que decidem se um nicho de margem fina fecha.

**Por que este desenho captura isso.** O addon é um funil de seleção: triagem larga e barata pela consulta resumida (base 2.1), escadas dos candidatos, e vigília densa de poucos nichos para medir quem cobre, em quanto tempo, até que preço e em que horas. O produto central é a **ficha de terreno** de cada nicho, com veredito (`GO`, `PROBE`, `WATCH`, `AVOID`) e motivo. Postar, comprar e cancelar só existem dentro de nichos aprovados, e a regra de saída (coberto duas vezes pelo mesmo vendedor, recuar) faz parte do motor.

**Com 5 ouro e personagens baixos** (50.912 cobre, quatro personagens, base 4.1 e 4.2). Não prometo curva de lucro: não há fato que sustente uma. O caminho é em degraus e cada um só abre com número medido: (a) a fase 1 não põe ouro em risco além de depósitos, que o jogo informa antes por `CalculateItemDeposit` (base 1.4); ela escolhe onde, quando e a que preço vender o que os quatro personagens já produzem, e monta o mapa de concorrentes; (b) a compra só liga quando o modo sombra mostrar, em 30 sinais ou mais, retorno realizado de ao menos metade do previsto; (c) o capital por nicho começa em um quarto da banca. Aritmética ilustrativa, não previsão: girar 3 ouro por dia com 15% líquido dá 45 prata por dia. O ângulo combina com pouco capital porque nicho é mercado pequeno, e é isso que 5 ouro conseguem ocupar.

**O que este ângulo sacrifica.**

- **Velocidade**: nenhum sniper de casa inteira; pechincha que dura segundos fica para os outros.
- **Cobertura**: não é banco de preços de todo o leilão; só guarda escadas dos candidatos. O tooltip de preço continua sendo do Auctionator (base 7.1).
- **Volume**: nicho tem teto baixo; a escala vem do número de nichos, e cada um pede dias de observação.
- **Sofisticação do preço**: troco a tabela adimensional de `P(venda)` do R9 por fórmulas fechadas com recalibração por nicho; aceito erro maior em mercado líquido porque não pretendo estar lá.
- **Tempo até a primeira compra**: dias. O dono que quer comprar hoje vai achar lento.
- **Dependência de um campo**: se o servidor não preencher `owners` (base 2.4, 11.5), o mapa de concorrentes cai para assinaturas e perde metade do valor.
- **Conversão e produção**: só aparecem na fase 3, como uma classe de nicho; outro projetista as trata melhor.

## 2. Escopo

**Fase 1, Reconhecimento (sem ouro em risco além de depósitos).**
- Sonda da API (parte 8) e gravação dos parâmetros medidos.
- Rodada de leitura por tecla: consulta resumida completa, escadas de candidatos, vigília de até 10 nichos.
- Diferença de escadas, vendas inferidas, mapa de concorrentes (cobridor rápido, de sessão, âncora, estoque fundo), paredes e iscas (R9 2 e 9).
- Radar e ficha de terreno, com veredito e motivo.
- Postar e cancelar por tecla o que o dono já tem; postagem-sonda de 1 unidade para medir quem cobre.
- Carteira: leilões próprios, faturas do correio (só leitura), resultado da sessão.
- Diário de calibração.

**Fase 2, Ocupação (compra por tecla, só em nicho aprovado).**
- Modo sombra primeiro: os sinais de compra são gravados sem ordem até o aceite.
- Compra de commodity (duas teclas) e arremate de item (uma tecla).
- Regras antiguerra, trégua, janela de hora, tetos e disjuntores de risco.
- Estratégias ligadas uma a uma pelo agente, no arquivo, depois do ok do dono.

**Fase 3, Expansão.**
- Mesa externa: arquivo das fotos, replay, calibração, relatório de nichos.
- Nichos de conversão com as receitas do personagem logado (`C_TradeSkillUI.GetRecipeSchematic`, base 3.7) e o grafo estático (base 9.2).
- Opcional, com decisão do dono: listagens horárias da Game Data API (base 5.4) para ver as horas em que ele não joga.
- Itens raros e de chave fina (verdes com sufixo), se a sonda resolver a chave (base 2.15).

**O que o addon nunca faz.**
- Agir sem tecla ou clique do dono: nenhuma das 7 funções restritas (base 2.12) sai de timer, evento ou `OnUpdate`; nunca `:Click()` em botão, nunca macro, nunca ação ligada à roda do mouse.
- Qualquer coisa cuja finalidade seja evitar a marca de ausente (base 8.2).
- Guardar teclas em fila: tecla apertada com a porta fechada se perde.
- Repetir sozinho uma ação que falhou.
- Reset de mercado, compra em massa da escada, casa neutra, lance (fora do desenho; parte 5).
- Falar com concorrente, denunciar, sussurrar; compartilhar dado em rede; usar nome de vendedor fora da tela de análise.
- Abrir tela de configuração no jogo; mostrar fonte na tela.
- Tocar em quadro da Blizzard fora de `hooksecurefunc`, `HookScript` e `EventRegistry`; usar código de addon de terceiro (base 4.8, 7).

## 3. Arquitetura

### 3.1 Módulos e ordem de carga

Lua 5.1, ASCII, `local _, ns = ...`, globais só `NichoForever*`, `SLASH_NICHOFOREVER*` e `BINDING_*`, toda função de evento, timer ou clique em `xpcall` (base 4.8). TOC: `## Interface: 16001`, `## Author: Guilherme`, `## SavedVariables: NichoForeverDB`, `## OptionalDeps: Auctionator, Syndicator, ElvUI`.

| # | Arquivo | Responsabilidade |
|---|---|---|
| 1 | `Config.lua` | Escrito pelo agente: teclas, tetos, estratégias (ligada, aprovadaEm), nichos aprovados, degrau de capital. Sem lógica. |
| 2 | `Calibrado.lua` | Escrito pela mesa: parâmetros do jogo e do motor, cada um com `origem` (estimado ou medido), `n` e data; `drenadoAte`. |
| 3 | `Estado.lua` | `ns`, `ns.seguro` (xpcall), eventos, relógio (`GetServerTime` carimba, `GetTime` mede duração; base 3.3), banco e migração, log de 60 linhas. |
| 4 | `Moeda.lua` | Cobre inteiro, arredondar ao tick, texto de preço; `SupportsCopperValues` (R1b 7). |
| 5 | `Chave.lua` | Identidade: `c:<itemID>` para commodity, `i:<itemID>:<nivel>:<sufixo>` para item (base 2.15); `GetItemKeyInfo` assíncrono; categoria. |
| 6 | `Fila.lua` | Orçamento da rodada, balde de pedidos, timeout, completude. Só roda dentro de rodada aberta por tecla. |
| 7 | `Varredura.lua` | Estágio A: consulta resumida completa e série por chave. |
| 8 | `Escada.lua` | Estágios B e C: busca por chave, escada compacta, donos, faixas de tempo. |
| 9 | `Diferenca.lua` | Fronteira, vendas inferidas, oferta nova por classe, repostagens (R9 2). |
| 10 | `Concorrentes.lua` | Perfil por dono ou assinatura, eventos de cobertura, `τ_r`, piso, presença por bloco, parede, isca, guerra em curso. |
| 11 | `Mercado.lua` | Estado O(1) por chave: valor, `λ`, `ν`, dispersão, fatores dos 12 blocos. |
| 12 | `Nicho.lua` | Ficha de terreno, índice, vetos, veredito, ciclo de vida. |
| 13 | `Motor.lua` | `P(venda)`, `W`, candidatos de preço, ordens de postar, cancelar e comprar. |
| 14 | `Estrategias.lua` | Catálogo: id, fonte (só no código), sinal, condição; todas nascem desligadas. |
| 15 | `Risco.lua` | Tetos, disjuntores, guarda de conformidade, cadência humana. |
| 16 | `Carteira.lua` | Lotes, leilões próprios, reconciliação, resultado. |
| 17 | `Correio.lua` | Leitura de cabeçalho e fatura; tomada por tecla (desligada de início). |
| 18 | `Acao.lua` | Único arquivo que chama as 7 funções restritas; máquinas de comprar, postar e cancelar. |
| 19 | `Teclas.lua` | Botões nomeados e teclas de sobreposição enquanto a janela está aberta. |
| 20 | `Diario.lua` | Diário de calibração, sonda, modo sombra. |
| 21 | `Interop.lua` | `Auctionator.API.v1` e Syndicator por `pcall` (base 7.1, 7.2). |
| 22 | `Visual.lua` | Cópia do kit `ns.ui` do GuiaForever, que é do dono (base 7.5). |
| 23 a 27 | `TelaRadar.lua`, `TelaNicho.lua`, `TelaMesa.lua`, `TelaLeiloes.lua`, `TelaSessao.lua` | Uma tela por arquivo; leem, não decidem. |
| 28 | `Alertas.lua` | Faixa na janela, `FlashClientIcon`, `PlaySound` (base 3.6). |
| 29 | `NichoForever.lua` | Arranque, `/nicho`, abre e fecha com `AUCTION_HOUSE_SHOW` e `AUCTION_HOUSE_CLOSED` (janela própria, sem aba; base 7). |

Arquivo novo pede reinício do jogo (R4a 6), então os 29 nascem como esqueleto na onda 0.

### 3.2 Fluxo dos dados

```
tecla U -> Fila -> Varredura (A) -- resumo por chave --> Nicho (triagem)
                -> Escada (B, C) -- foto --> Diferenca -- cobertura, repostagem --> Concorrentes
                                                       -- vendas, oferta nova --> Mercado
Mercado + Concorrentes --> Nicho (ficha, veredito) --> Motor (ordens) --> Risco (veta) --> TelaMesa
tecla P, B, C --> Acao --> eventos do jogo --> Carteira --> Diario
caixa de correio --> Correio (faturas) --> Carteira --> Diario
/reload --> SavedVariables --> mesa --> Calibrado.lua (pasta de desenvolvimento) --> /reload
```

### 3.3 Máquinas de estado

**Porta de ação** (vale para comprar, postar e cancelar). `aberta = IsThrottledMessageSystemReady() e nenhuma ação pendente e passou o intervalo mínimo desde a última`. O UI da Blizzard usa o mesmo predicado para habilitar o botão de postar (base 2.9). Com a porta fechada o botão mostra `WAIT` e a tecla não faz nada. A tecla do dono é o evento de hardware: `SetOverrideBindingClick(janela, true, tecla, nomeDoBotao, "LeftButton")` liga a tecla ao clique de um botão nosso só enquanto a janela está aberta (base 3.4, 8.1), e o `OnClick` chama a função restrita na mesma pilha, sem timer no meio. [H] Sobreposição satisfaz o evento de hardware no Forever (base 11.1): sonda S2; se não, o dono clica o mesmo botão com o mouse. As funções restritas falham em silêncio (`ReturnNothing`, base 2.12), então nenhuma máquina presume sucesso: toda ação tem evento de confirmação e timeout.

**Varrer** (consultas; nenhuma ação).

```
PARADO --tecla U--> RODADA_ABERTA
  A: se o resumo tem mais de T_A (15 min): SendBrowseQuery -> ESPERA_PAGINA
     BROWSE_RESULTS_UPDATED/ADDED -> LENDO -> (nao HasFullBrowseResults: RequestMoreBrowseResults -> ESPERA_PAGINA)
     completo -> grava a serie por chave
  B, C: para cada chave por prioridade, ate o orcamento: SendSearchQuery -> ESPERA_ESCADA
     ITEM_SEARCH_RESULTS_UPDATED ou COMMODITY_SEARCH_RESULTS_UPDATED -> (RequestMore* ate HasFull*) -> FOTO completa
  timeout T_resp, BROWSE_FAILURE ou resposta vazia onde havia oferta -> FOTO incompleta (nao alimenta estimador; R9 2.4)
  orcamento ou tempo esgotado -> FECHA --> PARADO   (nada se repete sozinho)
```

Funções e eventos conforme base 2.1 e 2.2 e R1a 6. Orçamento inicial: 40 buscas e 45 segundos por rodada, 60 buscas por minuto no máximo, abaixo das 100 por minuto que a documentação declara (base 2.2). [H] Uma consulta resumida completa custa perto de 8,5 segundos e 16 pedidos (relato de autor, base 2.6): sonda S4. As consultas não levam a marca de restrição e a própria Blizzard as dispara de eventos (base 2.12; R1b 14); mesmo assim cada rodada nasce de uma tecla, e isso é escolha de desenho (base 8.2).

**Comprar commodity** (duas teclas, como os dois cliques do UI da Blizzard; sequência da base 2.7 e do R1b 4).

```
LIVRE --tecla B--> pre-checagem (foto com idade <= A_exec? senao a tecla so refaz a busca e a ordem volta "REFRESHED")
      --> StartCommoditiesPurchase(itemID, n) --> COTANDO
COTANDO --COMMODITY_PRICE_UPDATED(unit, total)--> COTADO (mostra a cotacao e os segundos de GetQuoteDurationRemaining)
        total acima do teto da ordem, ou COMMODITY_PRICE_UNAVAILABLE --> CancelCommoditiesPurchase --> RECUSADA
COTADO --tecla B--> ConfirmCommoditiesPurchase(itemID, n) --> COMPRANDO
        cotacao a menos de 5 s do fim --> tecla desligada; ao expirar, CancelCommoditiesPurchase --> LIVRE
COMPRANDO --COMMODITY_PURCHASE_SUCCEEDED--> CONFIRMADA (lote na Carteira)
          --COMMODITY_PURCHASE_FAILED ou timeout--> INCERTA (confere GetMoney e a escada; nao repete)
```

O teto da ordem é mais apertado que a tolerância de 5% do UI da Blizzard (base 2.7). `ConfirmCommoditiesPurchase` não leva a marca de restrição (base 2.12), mas o desenho exige a segunda tecla de qualquer jeito. [H] O UI da Blizzard passa a `StartCommoditiesPurchase` um terceiro argumento (`unitPrice`) que a documentação não lista (R1b 4): conferir na sonda antes da fase 2.

**Arrematar item** (uma tecla por leilão). `LIVRE --tecla B--> PlaceBid(auctionID, buyoutAmount) --> ENVIADA --AUCTION_HOUSE_PURCHASE_COMPLETED(auctionID)--> CONFIRMADA`; `AUCTION_HOUSE_SHOW_ERROR` (por exemplo `ItemNotFound`, erro ativo no Forever, base 1.11) leva a `RECUSADA`, conta em "já tinha sumido" e a escada é refeita na próxima rodada (base 2.8).

**Postar** (uma tecla por lote; duas se o jogo pedir confirmação).

```
LIVRE --tecla P--> pre-checagem (IsSellItemValid, deposito lido de Calculate*Deposit <= GetMoney, foto fresca, guarda de preco)
      --> PostItem ou PostCommodity
      retorno needsConfirmation = true --> ESPERA_AVISO --AUCTION_HOUSE_POST_WARNING--> PEDE_CONFIRMACAO
PEDE_CONFIRMACAO --tecla P--> ConfirmPostItem ou ConfirmPostCommodity --> ENVIADA
ENVIADA --AUCTION_HOUSE_AUCTION_CREATED(auctionID)--> CONFIRMADA (leilao na Carteira, com fila e P prevista)
        --AUCTION_HOUSE_POST_ERROR ou SHOW_ERROR--> RECUSADA (equipamento abaixo do menor preco: oferece igualar; base 1.11)
        --timeout--> INCERTA --> QueryOwnedAuctions --> reconcilia; nunca reenvia sozinho
```

Sequência conforme base 2.9; `IsSellItemValid` está no contrato (R1a, função 63). `AUCTION_HOUSE_AUCTION_CREATED` é documentado pela Blizzard como feito para addons (base 2.9).

**Cancelar** (uma tecla por leilão). `LIVRE --tecla C--> CanCancelAuction e GetCancelCost (custo na linha de assinatura) --> CancelAuction(auctionID) --> ENVIADA --AUCTION_CANCELED(auctionID)--> CONFIRMADA`; timeout leva a `INCERTA` e a `QueryOwnedAuctions` (base 2.10).

**Throttle.** `AUCTION_HOUSE_THROTTLED_SYSTEM_READY` reabre a porta; `AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED` com ação pendente leva direto a `INCERTA`. Se a fila ficar em "não pronta" por mais de 30 segundos (relato de trava, base 2.14), a tela diz `Throttle stuck: close and reopen the auction house` e o addon não tenta contornar. Consulta pausa enquanto há ação pendente.

### 3.4 SavedVariables

Um banco de conta, `NichoForeverDB`, com subtabela por personagem para ouro e leilões. Só vai para o disco no `/reload`, no logout e ao fechar (base 3.9).

```
NichoForeverDB = {
  versao, criadoEm,
  resumo    = { vetores paralelos por chave: preco minimo (EWMA), ultimo minimo, quantidade, tremor, saida, n, visto },
  escadas   = { [chave] = anel de fotos: t, fonte, completa, 12 degraus (preco, qtd, n donos, dono se unico), cauda em 8 baldes },
  donos     = { [chave] = { [dono ou assinatura] = eventos de cobertura, tau, piso, estilo, presenca[12], classe } },
  nichos    = { [chave] = ficha, veredito, motivo, estado do ciclo de vida, historico de transicoes },
  mercado   = { [chave] = cerca de 30 numeros: valor, lambda, nu, dispersoes, fatores de bloco },
  carteira  = { [personagem] = { lotes, leiloes, faturas, ouro } },
  sombra    = anel de sinais nao executados com o preenchimento hipotetico,
  diario    = anel de registros { t, tipo, chave, previsto, medido },
  sessoes   = anel de 60 resumos de sessao,
  sonda     = respostas das incognitas da base 11,
}
```

| Tabela | Conta | Tamanho em texto |
|---|---|---|
| `resumo` | até 8.000 chaves × 7 números (a ordem de grandeza vem do relato de 7.718 itens, base 2.6) | 1,0 MB |
| `escadas` | 150 candidatos × 32 fotos × cerca de 300 bytes; os 10 em foco guardam 96 | 1,6 MB |
| `donos` | 150 × até 20 perfis × 120 bytes | 0,4 MB |
| `nichos` e `mercado` | 300 × 700 bytes | 0,2 MB |
| `carteira` | 2.000 registros × 200 bytes | 0,4 MB |
| `sombra` e `diario` | 4.000 registros × 150 bytes | 0,6 MB |
| `sessoes` e `sonda` | | 0,1 MB |
| **Total** | alvo 4,3 MB; alerta em 6 MB; em 8 MB as escadas mais velhas fora do foco são cortadas | |

A referência de 640 bytes por escada de 40 degraus é do R9 11.4; uso 12 degraus mais cauda. [H] Tempo de `/reload` com 4 MB: medir com `debugprofilestop` (base 3.3) na sonda S10. [H] As SavedVariables persistem no build atual (há relatos contraditórios, R6b incógnita 4): primeira conferência da sonda (S1).

### 3.5 Parte fora do jogo (a mesa)

Fase 3, em `ferramentas/nicho/mesa/`, Node como as demais ferramentas do projeto (base 4.9).

- **Entrada**: `WTF/Account/<conta>/SavedVariables/NichoForever.lua`, só leitura, válido depois de um `/reload`.
- **Saída**: `Calibrado.lua` na pasta de desenvolvimento do addon, que a junction liga ao jogo; editar ali e dar `/reload` é o ciclo normal (regra 6; base 4.11). A mesa nunca escreve em `WTF` nem na pasta do jogo.
- **Arquivo**: `mesa/arquivo/AAAA-MM-DD.jsonl`, uma foto por linha (`t, chave, fonte, completa, degraus, cauda`). Depois de conferir o arquivo, a mesa grava `drenadoAte` em `Calibrado.lua`; na carga seguinte o próprio addon apaga as escadas anteriores a essa hora fora do foco.
- **Ciclo**: jogar, tecla de salvar (`/reload`), `node mesa/drenar.mjs`, `node mesa/calibrar.mjs`, `/reload`. Na prática, uma vez no fim de cada sessão.

## 4. Motor

### 4.1 O que adoto, simplifico e troco do R9

| Peça do R9 | Destino | Por quê |
|---|---|---|
| Fronteira e diferença de escadas (2.1 a 2.5), correção `ξ` | Adoto | É a única janela para a venda dos outros e para os eventos de cobertura. |
| Preço robusto com filtro de isca (1.2) | Adoto a foto; simplifico o tempo | Valor = mediana dos `m_k` das últimas fotos independentes, intervalo por MAD. Sem EWMA duplo nem Huber: em nicho há poucas fotos e a mediana erra menos. |
| Concorrente reativo `P_ciclo` (3.2e) e classes (9.2) | Adoto e ponho no centro | É a pergunta do projeto. |
| Tabela adimensional de `P` (3.2f) | Troco | Fases 1 e 2 usam `min(P_dem, P_GI, P_∞)` (erro de até 0,27 com lotes grandes, R9 0.3) e, com 30 desfechos próprios por classe de nicho, uma tabela empírica 3 × 3 (fila em unidades de demanda × razão de cobertura). A tabela simulada só entra na fase 3 se o Brier pedir. |
| `W(p, D)` e candidatos finitos (4.1, 4.2) | Adoto, com filtro de concorrência | Parte 4.4. |
| Cancelar e repostar (4.6) | Adoto, com teto de repostagens e trégua | O `Δ_canc` não enxerga o desgaste acumulado. |
| Teste único de compra na escada pós-compra (5.1) | Adoto | Separa pechincha de preço novo. |
| Sniper de lance (5.6), reset (6) | Fora | Lance não se testa com fotos (R9 10.2); reset tem valor esperado negativo em item líquido (R9 6.3) e só folclore como fonte (base 6.5). |
| Kelly (7.2) | Troco por tetos fixos | Com 5 ouro o que limita é o teto por nicho; a frente não passou por revisor matemático (base 10). Kelly volta acima de 50 ouro. |
| Sazonalidade de 42 caixas (8.1) | Simplifico para 12 | 6 blocos de 4 horas × dia útil ou fim de semana, com encolhimento para a categoria: só há fotos nas horas em que o dono joga (R9 8.5). |
| Detector de amplitude por categoria (8.2c) | Adoto | Funciona com pouco dado. |
| Agendador por capital exposto (11.5) | Troco | Prioridade = valor da informação para a seleção (parte 4.2). |

### 4.2 O funil de seleção

**Estágio A, triagem** (toda chave, uma consulta resumida por rodada no máximo). A consulta resumida dá `minPrice` e `totalQuantity` por chave, sem escada (base 2.1). Por chave, entre a varredura `k−1` e a `k`, com `Δ` em horas:

```
queda   = 1 se o minimo caiu ate g_cob (3%)        -- cobertura fina
tremor  = media movel de queda / Δ                 -- coberturas finas por hora
saida   = media movel de max(0, Q_{k-1} − Q_k) / Δ -- unidades que saem por hora (venda + cancelamento + expiracao)
triagem = saida · minimo / (1 + k_t · tremor)      -- cobre que gira por hora, descontado pela disputa
```

Entram como candidatos as 150 chaves de maior `triagem` com preço unitário entre `preco_min` e `w_item·B`, preço acima do de vendedor (`C_Item.GetItemInfo`, 11º retorno; base 3.2) e saída positiva em duas varreduras. [H] `tremor` e `saida` são substitutos baratos do número de cobridores e da demanda: o diário compara cada um com o valor medido nos estágios B e C; se a correlação de postos ficar abaixo de 0,4 depois de 30 nichos, a triagem vira só filtro de preço e quantidade. [H] `SearchForItemKeys(itemKeys, sorts)` (R1a, função 79) devolve o resumo de uma lista de chaves num pedido só, o que deixaria a triagem dos candidatos quase de graça: sonda S4.

**Estágio B, observação** (150 candidatos). Fotos da escada com cadência `Δ_alvo ≤ 0,4·l_f/λ` (R9 2.2). Cada par de fotos completas dá vendas inferidas (limite inferior, corrigido por `ξ`), oferta nova por classe (cobre, iguala, atrás), repostagens e sumiços atrás da fronteira (R9 2.1 a 2.5). O que identifica cada vendedor:

- **Item**: `owners` por leilão (base 2.4). O UI da Blizzard tem coluna "Seller" e mostra o nome quando a linha tem um dono só e "%d Sellers" quando tem vários (espelho: `Blizzard_AuctionHouseUtil.lua:391-400`, `Blizzard_AuctionHouseTableBuilder.lua:1095` e `1144`; `GlobalStrings` linhas 1243 e 1257). [H] O servidor do Forever preenche os nomes (base 11.5): sonda S3.
- **Commodity**: `owners` e `totalNumberOfOwners` por degrau (base 2.3). Degrau de um dono só vira perfil com nome; degrau de vários, ou nome ausente, vira **assinatura** (tamanho do lote, terminação do preço, distância de cobertura), com peso probabilístico (R9 9.1, 2.3).

**Estágio C, vigília** (até 10 nichos em foco). Fotos a cada rodada, com intervalo de 5 minutos ou menos, para medir tempo de reação: não se distingue reação mais rápida que o intervalo entre fotos (R9 9.2). Mede-se de dois jeitos: **passivo** (um vendedor que estava na frente é coberto por outro e volta à frente; intervalo censurado, R9 9.2) e **ativo**, a **postagem-sonda**: o dono posta 1 unidade (uma tecla) num preço candidato e as fotos seguintes dizem em quanto tempo foi coberto, por quem, e se vendeu. Custo: o depósito daquela unidade, lido antes. É o jeito de o dado do addon virar evidência antes de arriscar ouro.

**Prioridade da fila** (substitui R9 11.5): `prioridade = peso · (1 − exp(−idade/Δ_alvo))`, com `peso` maior para (1) nicho com leilão próprio ativo, (2) evento de cobertura aberto, que precisa da próxima foto para fechar o intervalo, (3) nicho a menos de 20% de um limiar de veto, (4) candidato novo. Itens vetados por motivo estrutural só voltam a ser fotografados uma vez por dia.

### 4.3 Ficha de terreno, índice e veredito

Por nicho (chave × bloco de hora):

```
RR  = λ_p · τ_r do cobridor mais rapido presente no bloco     (razao de reacao; sem cobridor: infinito)
ρ   = ν_f / λ_p na frente                                     (R9 3.1)
K_r = cobridores rapidos ativos no bloco (τ_r <= R_fast, com n_r eventos; R9 9.2)
HHI = concentracao da janela de referencia (R9 9.2)
IT  = η_real · n · (W*_lcb − a) / teclas                      [cobre por tecla]
      a      = custo medio de entrada (compra) ou a melhor alternativa do que ja se tem (vendedor)
      teclas = compras + lotes postados + 2·E[repostagens] + coletas no correio
```

`W*_lcb` é o valor de liquidação conservador do R9 4.1 e 5.1, com `P` da parte 4.1 (ou `P_ciclo` se há cobridor rápido). `IT` (índice de terreno) é a moeda de comparação entre nichos: o gargalo do dono é a tecla (R9 5.1 ordena por EV por clique), e ele paga uma por ação.

**Vetos** (qualquer um tira o `GO`; o motivo aparece em uma frase):

| Veto | Condição inicial | Texto na tela |
|---|---|---|
| V1 dado ralo | menos de 8 fotos completas, de 3 horas de exposição ou de 2 sessões | `not enough data yet` |
| V2 cobridor rápido | `K_r ≥ 1` e `RR < 0,3` | `fast undercutter (reacts ~Xm)` |
| V3 oferta vence | `ρ` no quantil alto acima de 1,5 | `supply outruns demand` |
| V4 sem giro | `λ_lo < 2/H_max` (R9 5.2) | `too slow to sell` |
| V5 estoque fundo | dono que repõe o mesmo degrau 3 vezes em 24 h (R9 9.2) na frente | `deep stock ahead` |
| V6 regime | alarme de amplitude da categoria ou varrida recente (R9 8.2, 2.4) | `market moving, wait` |
| V7 guerra | 3 coberturas alternadas entre 2 donos em 30 minutos | `price war in progress` |
| V8 capital | um lote mínimo custa mais que `w_item·B` | `too big for current gold` |
| V9 chave | item cuja chave não separa variações (base 2.15) | `item variants not separable` |

**Veredito**: `AVOID` (veto estrutural V2 a V5, V8, V9), `WATCH` (V1, V6, V7), `PROBE` (sem veto, `IT` acima do mínimo, mas sem medida ativa de cobertura), `GO` (sem veto, `IT ≥ IT_min`, sondado ou com 5 eventos passivos de cobertura). **Ciclo de vida**: `candidato → observado → sondado → aprovado → ativo → tregua → aposentado`. Só `aprovado` gera ordem, e a aprovação é uma linha em `Config.lua` escrita pelo agente depois do ok do dono. Cada transição grava data e motivo.

### 4.4 Preço, duração e as regras antiguerra

Candidatos do R9 4.2 (cobrir o degrau j, igualar o degrau j, âncoras de valor), cada um avaliado por `W`, com este filtro:

1. **Frente da parede**: `p_parede − passo`, quando o tempo de consumo até a parede cabe em `H_max`; nunca acima dela (R9 9.3).
2. **Igualar a frente**: sempre candidato. Fila pelo pior caso (FIFO) enquanto a ordem entre preços iguais for incógnita (base 2.17; R9 3.1).
3. **Cobrir**: só sem cobridor rápido presente no bloco; passo de `Config.lua`.
4. **Abaixo do piso** do cobridor (`Ψ = 0`, R9 3.1): só se `W` ainda for o maior, e marcado na tela como `DEEP`.
5. **Esperar**: `W_espera` no bloco em que os cobridores do item costumam estar ausentes (R9 4.3).

**Antiguerra** (acima do `Δ_canc` do R9 4.6):

- G1: no máximo 2 cancelamentos com repostagem por item por bloco de 4 horas.
- G2: coberto 2 vezes pelo mesmo dono em menos de `R_fast`, o candidato "cobrir" sai do item e o nicho entra em `tregua` por 4 horas; a ordem vira `stand down`.
- G3: piso duro. Nunca abaixo de `max(preço de vendedor, custo de reposição) / (1 − c)` mais margem (R9 4.2).
- G4: nenhuma repostagem com mais de 2% de queda num passo, salvo o candidato `DEEP`.
- G5: histerese de cancelamento em 3% de `W`, três vezes o inicial do R9, para a decisão não oscilar.

Duração e lote: `W` para cada duração (2, 8 e 24 horas, base 1.5), com o depósito lido na hora; lote `n* = λ_p · T_frente` (R9 4.5), porque estoque inteiro à mostra é uma parede que convida cobertura.

### 4.5 Compra e tamanho

Regra única do R9 5.1: comprar se `η_real · n · U_lcb(escada pós-compra) − custo − teclas·κ ≥ max(M_abs, μ_min·custo)`. Tamanho: `n = min(s_cap·λ_lo·H_max − estoque, w_item·B/a, x_vol·λ·24 − comprado hoje, folga de w_tot·B)` (R9 7.3 sem o termo de Kelly). Só em nicho `ativo`, com foto de idade até `A_exec`, e nunca do dono de estoque fundo que repõe (R9 6.4, condição 6, aplicada ao flip).

### 4.6 Valores iniciais

| Parâmetro | Inicial | Origem |
|---|---|---|
| `H_ref`, `N_min`, `f_isca`, `g_isca`, `α_ap`, `K_lvl` | 2 h; 5; 0,05; 0,15; 0,2; 12 | R9 12-C |
| `ξ_a`, `ξ_b`, `u_alvo`, `π_cf` | 0,5; 0,8; 0,4; 0,05 | R9 12-C |
| `R_fast`, `n_r`, `k_wall`, `f_wall`, `HHI_max` | 10 min; 3; 4; 0,25; 0,5 | R9 12-C |
| `μ_min`, `η_real`, `z_c`, `s_cap`, `x_vol`, `A_exec` | 0,10; 0,5; 1,0; 0,3; 0,25; 30 s | R9 12-C |
| `H_max` | 24 h (R9 parte de 72 h) | meu: preço listado em queda (base 6.1), estoque parado custa |
| `w_item`, `w_tot` | 0,25 e 0,75 | topo da faixa do R9 para `w_item`: com 5 ouro a concentração é forçada; cai para 0,10 acima de 50 ouro |
| `ℓ_dia`, `ℓ_item`, `N_seq` | 0,05; 0,01; 5 | R9 12-C |
| Vetos: `RR` 0,3 e 1,0; `ρ` 1,5; guerra 3 em 30 min | | meus, a calibrar |
| Rodada: 40 buscas, 45 s; foco 10; candidatos 150; `T_A` 15 min | | meus, dependem da sonda (base 11.3) |
| `valor_tecla` (κ) e `IT_min` | 50 cobre e 1 prata por tecla | preferência do dono (decisão 10) |
| Corte, depósito, devolução, tick, ordem de empate | pior caso até medir; 5% só como pista (base 1.4) | sonda |

### 4.7 Diário de calibração

`Diario.lua` grava pares `previsto, medido`; a mesa (ou uma sessão do agente lendo as SavedVariables depois de um `/reload`) troca o valor em `Calibrado.lua` e muda `origem` para `medido`. A tela de sessão mostra `measured N of M`.

| O que se mede | Como | O que troca |
|---|---|---|
| Corte e devolução do depósito | fatura do correio (`GetInboxInvoiceInfo`: lance, arremate, depósito, consignação; base 3.1) em venda, expiração e cancelamento | `c`, `r_s`, `r_x`, `r_c` |
| Depósito por duração e quantidade | `CalculateItemDeposit` e `CalculateCommodityDeposit` antes de cada postagem | fórmula do depósito (base 1.4) |
| Subcontagem das vendas | vigília densa reamostrada a 5, 15, 30 e 60 minutos (R9 2.9) | `ξ_a`, `ξ_b` |
| `P(venda)` | P prevista × desfecho de cada postagem; Brier por classe de nicho (R9 3.7) | `a0_cal`, `a1_cal`, tabela 3 × 3 |
| "Serei coberto em 10 minutos" | previsão por postagem × foto seguinte (R9 9.5) | `R_fast`, `n_r`, limiares de `RR` |
| Substitutos da triagem | `tremor` × `K_r`, `saida` × `λ` | `k_t` ou o abandono da fórmula |
| Sinais de sombra | preenchimento hipotético conservador (R9 10.2) | `η_real` por estratégia |
| Ordem entre preços iguais | venda própria num degrau igualado, com as unidades alheias mais antigas intactas na foto seguinte | `Ω` (base 11.7) |
| Tempo por ação e taxa de "já tinha sumido" | carimbos de tecla e de evento | `κ`, `A_exec` |
| Atraso do correio | aviso de venda (`AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION`, base 2.11) até a fatura | giro do capital (base 11.10) |

## 5. Estratégias

Todas nascem com `ligada = false`. A fonte fica no código e no `ARQUITETURA.md`; a tela nunca a mostra. Só o vídeo do Studen Albatroz é fonte de economia aprovada hoje (base 4.5); as outras precisam do ok do dono.

| Id | Estratégia | Fonte | Sinal mensurável | Regra | Risco | Condição para ligar |
|---|---|---|---|---|---|---|
| E1 | Vender o que se tem no nicho certo (materiais crus, verdes bons) | Studen, dica 4, aprovada (base 4.5; R4b 4). R8b R4 e R2 (MM: vender cru, guardar azul BoE; beta). R8a F18 (material no leilão paga mais que vendedor; Classic 2019) | `W*_lcb` contra o preço de vendedor; veredito do nicho | Postar se `W*_lcb > vendedor + margem` e o nicho não está em `AVOID`; senão a tela mostra as duas saídas e o dono decide | Depósito perdido; preço em queda (base 6.1) | Fase 1, com depósito e corte medidos |
| E2 | Piso de vendedor: nunca listar abaixo; comprar abaixo e vender ao NPC | Piso: R8b R8 (FG). Compra: R8a ficha 5 diz que não há fonte do fluxo no Forever; a conta é do R9 5.4 | Preço de leilão menor que o de vendedor lido na hora (base 3.2, 6.3) | Piso sempre ativo como guarda. Compra: `EV ≥ M_npc` (R9 5.4) | Preço de vendedor muda por hotfix (base 6.3); regra de vínculo ao vender (R8a ficha 5, F3) | Piso: fase 1. Compra: sem fonte de fluxo; liga só depois de 20 ocorrências no modo sombra com vida mediana maior que o tempo de reação do dono |
| E3 | Flip de vão em nicho sem cobridor | R8a ficha 2 (F17, guia genérico: comprar até 70% do mercado; F18 avisa contra equipamento). Cálculo R9 5.3 | Vão `p_{k+1}/p̄_k` acima da condição necessária do R9 5.3, `RR ≥ 1`, sem estoque fundo | Comprar os k degraus de maior `EV_k`, repostar no vão | O vão fecha com oferta nova; estoque parado | Fase 2: 30 sinais de sombra com `η_real ≥ 0,5` e nicho `aprovado` |
| E4 | Sniper de nicho (só dentro do foco) | R8a ficha 1 (F1, doc do TSM de 2022; F17; F23 avisa de isca). Nenhuma fonte do Forever | Degrau com preço até `a_max` (R9 5.2), fora do filtro de isca | Comprar até `a_max`; guarda de regime compra só o lote de sondagem | Isca; valor velho; outros snipers; erro "item not found" (base 1.11) | Fase 2, depois de E3; desliga sozinho se "já tinha sumido" passar de 60% |
| E5 | Hora de postar | R8b ficha 1 (MM: à noite e antes de raide; FG marca como editorial; AMS: ciclo semanal do Classic, sem dado). Nenhuma medição no Forever (base 6.5) | Fator de `λ` e presença de cobridores em cada um dos 12 blocos | `W_espera` do melhor bloco contra `W` de agora | Só há dado das horas em que o dono joga (R9 8.5) | Três observações por bloco no nicho; antes disso a ficha mostra `-` |
| E6 | Não entrar em guerra de cobertura (G1 a G5) | R8a F23 (jogador: cortar até o lucro zero perde dinheiro "unless bots are present"). R8b R7 (FG: "undercuts land within minutes"), R6 (MM: deixar distância real), R12 (U4N). Modelo R9 9.3 | Eventos de cobertura por dono; `RR` | Parte 4.4 | Recuar cedo demais de quem não era rápido | Fase 1, junto com a postagem |
| E7 | Passo de cobertura: igualar, 1 cobre ou distância real | As fontes se contradizem: R8a F5 ("by a copper, not by half"), R8b R6 ("leave a real gap"), R8b R12; a ordem de empate é incógnita (base 2.17) | Desfecho das próprias postagens por tipo de passo | Sem medida, igualar (é também o contorno do erro de equipamento, base 1.11); alternar os três tipos e adotar o de maior venda antes de cobertura | Amostra pequena; `Ω` desconhecida | Fase 1; decisão depois de 20 postagens por tipo |
| E8 | Duração curta para o que gira rápido | R8b R15 (MM, sem fonte própria); R9 4.4 | `P(D)` satura cedo; depósito por duração | Escolher a duração de maior `W` | Fórmula do depósito não publicada (base 1.4) | Depois da sonda S5 |
| E9 | Lote em tamanho de receita | R8b R14 (FG) | Item empilhável que não é commodity | Lotes múltiplos da receita | Em commodity o comprador escolhe a quantidade (base 2.7) | Só se a sonda S3 mostrar empilhável como item (base 2.15) |

**Fora, com motivo**: reset (R8a ficha 4, só relato de jogador; R9 6.3); formação de mercado com spread (R8a ficha 3, sem fonte); casa neutra (R8a ficha 8; taxas da tabela 25 e 15, base 1.4); sniper de lance (R8a ficha 7, fonte do retail); estoque para a abertura das raides de 9/12 (R8b ficha 3, sem dado; é a aposta mais anunciada pelos guias, o oposto de um nicho). Para esta última o addon só oferece uma lista de observação sem ordem de compra.

## 6. Interface

Janela própria, em inglês, sem caixa de texto (com foco numa caixa as teclas não disparam; base 3.4), sem opção alguma. Cada seção tem até 5 linhas e `Show N more`. Estado nunca só por cor: toda linha tem etiqueta de texto (`GO`, `WALL`, `FRONT`). Nada depende de tooltip (base 8.4).

### 6.1 Teclas (valem só com a janela aberta; base 4.10, 8.1)

| Tecla | Função | Tipo |
|---|---|---|
| `U` | Uma rodada de leitura | consulta |
| `N`, `H`, roda do mouse | Linha seguinte e anterior | navegação |
| `O` | Abrir a ficha do nicho | navegação |
| `F1` a `F5` | Radar, Niche, Desk, Auctions, Session | navegação |
| `B` | Comprar a ordem em destaque (commodity: cotar, depois confirmar) | **ação** |
| `P` | Postar a ordem em destaque (de novo se o jogo pedir confirmação) | **ação** |
| `C` | Cancelar o leilão em destaque | **ação** |
| `K` | Pular a ordem | navegação |
| `L` | Pôr o nicho em trégua por 4 horas (estado temporário, não configuração) | navegação |
| `M` | Pegar uma correspondência (na caixa de correio; desligada de início) | **ação** |
| `F12` | Salvar agora (`/reload`) | sistema |

B, C, H, K, L, M, N, O, P, U e F1 a F12 estão livres pelos arquivos do dono, sem conferência dos padrões do cliente (base 4.10); a sobreposição devolve a tecla ao fechar a janela. A roda só navega: nenhuma ação é ligada a ela. [H] `ReloadUI` chamado do clique de um botão funciona (R1c 13 confirma só que existe): sonda S10; se não, a tela diz `Type /reload`.

### 6.2 Telas

```
+----------------------------------------------------------------------------+
| NICHOFOREVER   [F1 Radar]  F2 Niche  F3 Desk  F4 Auctions  F5 Session      |
| Gold 5g 09s    Posted 0     Stock 0        Scan: complete, 2m ago    [U]   |
+----------------------------------------------------------------------------+
| GO (2)                                    per key    rivals       best time|
| > Medium Leather    sell 20 owned         + 1s 80c   2 slow       now      |
|   Copper Bar        gap 18%, buy 15       + 1s 10c   1 slow       20-24    |
+----------------------------------------------------------------------------+
| PROBE (3)   needs a 1-unit test post                                       |
|   Coarse Thread     looks open            + 0s 90c   none seen    -        |
|   Show 2 more                                                              |
+----------------------------------------------------------------------------+
| WATCH (12)                                                                 |
|   Tin Ore           not enough data yet (photos 3 of 8)                    |
|   Show 11 more                                                             |
+----------------------------------------------------------------------------+
| AVOID (41)                                                                 |
|   Copper Ore        fast undercutter (reacts ~2m)                          |
|   Linen Cloth       supply outruns demand                                  |
|   Show 39 more                                                             |
+----------------------------------------------------------------------------+
| [U] scan   [N] next   [H] back   [O] open niche          Next photo 1:20   |
+----------------------------------------------------------------------------+
```

```
+----------------------------------------------------------------------------+
| NICHE  Medium Leather         GO       + 1s 80c per key        [F1] back   |
+----------------------------------------------------------------------------+
| LADDER                                                                     |
|   1s 14c   x 12    1 seller    Thornw       BAIT                           |
|   1s 31c   x 40    3 sellers                FRONT                          |
|   1s 32c   x 260   1 seller    Grubb        WALL                           |
|   1s 60c   x 18    2 sellers                                               |
|   Show 8 more                                                              |
+----------------------------------------------------------------------------+
| RIVALS                                                                     |
|   Grubb     deep stock    reacts ~3h    floor 1s 20c    here now: no       |
|   Thornw    undercutter   reacts ~40m   floor unknown   here now: yes      |
|   Show 2 more                                                              |
+----------------------------------------------------------------------------+
| HOURS    sales per hour / fast rivals seen                                 |
|            00-04   04-08   08-12   12-16   16-20   20-24                   |
|   Mon-Fri    -       -      2/0     3/1     6/2     9/1                    |
|   Sat-Sun    -       -       -      5/0     8/1      -                     |
+----------------------------------------------------------------------------+
| PLAN                                                                       |
|   Post 20 at 1s 31c, 8 hours. Sell chance 62%. Deposit 12c.                |
|   If the same seller undercuts twice: stand down until 20:00.              |
+----------------------------------------------------------------------------+
```

```
+----------------------------------------------------------------------------+
| DESK   3 orders                                        Throttle: READY     |
+----------------------------------------------------------------------------+
| > POST    Medium Leather  x 20   1s 31c each   8h      deposit 12c         |
|   BUY     Copper Bar      x 15   up to 1s 40c  total up to 21s 00c         |
|   CANCEL  Tin Ore         x 10   undercut twice by one seller: stand down  |
+----------------------------------------------------------------------------+
| LAST    Posted Medium Leather x 20        CONFIRMED  14:02:11              |
+----------------------------------------------------------------------------+
| [P] will post: Medium Leather x 20 at 1s 31c each, 8h, deposit 12c         |
| [K] skip   [N] next                                                        |
+----------------------------------------------------------------------------+
```

```
+----------------------------------------------------------------------------+
| AUCTIONS   6 active   1 sold (payout in about 42m)                         |
+----------------------------------------------------------------------------+
|   Medium Leather x 20   1s 31c   FRONT       7h left    keep               |
|   Tin Ore x 10          1s 80c   BEHIND 2    undercut by Xyl 3m ago  hold  |
|   Copper Bar x 15       1s 95c   FRONT       2h left    keep               |
|   Light Leather x 40      54c    BEHIND 1    repost advised (1 of 2 left)  |
|   Show 2 more                                                              |
+----------------------------------------------------------------------------+
| [C] will cancel: Light Leather x 40 (cancel cost 0)                        |
+----------------------------------------------------------------------------+
```

```
+----------------------------------------------------------------------------+
| SESSION  1h 12m    keys 86    actions 14                                   |
+----------------------------------------------------------------------------+
| RESULT   sold + 14s 20c    deposits lost 1s 05c    stock value 38s 00c     |
| NICHES   active 2    standing down 1    retired 0                          |
| CHECKS   measured 9 of 21        house cut: measured        tie order: no  |
| ALERTS   Tin Ore: price war in progress, niche paused                      |
|          Data is 34m old on 2 niches                                       |
+----------------------------------------------------------------------------+
| [F12] save now (reloads the interface)                                     |
+----------------------------------------------------------------------------+
```

Na caixa de correio abre só uma faixa: `MAIL  3 sales  + 41s 10c   2 returned items   [M] take next`.

### 6.3 Fluxos, tecla por tecla

**Varrer, decidir e comprar** (fase 2).
1. O dono fala com o leiloeiro; `AUCTION_HOUSE_SHOW` abre a janela e liga as teclas.
2. `U`: uma rodada (resumo, se tem mais de 15 minutos, e fotos do foco). Nenhuma ação.
3. O Radar se reordena. `N` ou a roda move; `O` abre a ficha; `F1` volta.
4. `F3`: a mesa mostra as ordens; a linha de assinatura diz o que a próxima tecla fará.
5. **`B`** (tecla do dono): commodity chama `StartCommoditiesPurchase`; a mesa mostra `QUOTE 1s 38c x 15 = 20s 70c, 22s left`.
6. **`B`** (tecla do dono): `ConfirmCommoditiesPurchase`; a mesa mostra `BOUGHT` e cria a ordem de postar correspondente, sem postar. Item não commodity: um **`B`** por leilão, direto no `PlaceBid`.
7. [H] Se a compra chega pelo correio, a ordem de postar fica `WAITING FOR MAIL`.

**Postar.** `F3`; a ordem `POST` em destaque (o item precisa estar na bolsa; o Syndicator diz se está em outro personagem, base 7.2); **`P`** (tecla do dono) chama `PostItem` ou `PostCommodity`; se o jogo pedir confirmação aparece `Game asks to confirm` e **`P`** de novo confirma; `CONFIRMED` com o `auctionID`. Cada lote é uma tecla.

**Cancelar e repostar.** `F4`; linha `BEHIND, repost advised (1 of 2 left)`; **`C`** (tecla do dono) chama `CancelAuction`; ao `AUCTION_CANCELED` o item volta (bolsa ou correio [H]); a mesa cria a ordem `POST` com o preço novo; **`P`** (tecla do dono). Esgotado o limite G1, ou disparada a G2, a linha vira `stand down` e nenhuma tecla de cancelar é oferecida naquele item até a trégua acabar.

**Recolher o correio.** Na caixa, `MAIL_SHOW` abre a faixa; o addon lê cabeçalhos e faturas (só leitura) e grava venda, depósito e corte. De início o dono usa o botão `Open All Mail` da própria Blizzard (espelho: `Blizzard_MailFrame/MailFrame.xml:444`). Se ele ligar a tomada por tecla, cada **`M`** (tecla do dono) pega uma correspondência (`TakeInboxMoney` ou `AutoLootMailItem`, globais que o `MailFrame.lua` da Blizzard usa; base 3.1).

**Fechar a sessão.** `F5`; o addon consulta os leilões próprios e reconcilia com a Carteira; `F12` recarrega e grava (base 3.9); a mesa ou o agente lê o arquivo e devolve `Calibrado.lua`; o relatório de sessão do projeto sai dali (base 4.7).

### 6.4 Adaptações para acesso remoto

- **O que você vê é o que você assina**: a tecla de ação só vale se a ordem em destaque está na tela, sem mudar, há pelo menos 1 segundo. Ordem que mudou de preço pisca `UPDATED` e espera. Isso cobre o atraso do stream.
- **Antirrepique**: segunda batida da mesma tecla de ação em menos de 400 ms é ignorada. [H] Tecla presa não repete o clique de sobreposição: sonda S2.
- **Cotação**: a confirmação desliga com menos de 5 segundos de cotação restante.
- **Legibilidade**: linha de 28 px ou mais e botões de 32 px, contraste 4,5:1, fonte que respeita a escala do usuário (base 8.4; R10a 4).
- **Alerta que não depende de som**: faixa de texto na janela, `FlashClientIcon` e `PlaySound` juntos (base 3.6); o som pode não atravessar o stream (R10a 4).
- **Relógio**: tudo por `GetTime`, nunca por contagem de quadros; em segundo plano o cliente cai para 30 quadros por segundo por padrão (base 3.8).
- **Ausência**: não há função com essa finalidade. A rodada por tecla e as ações por tecla são o fluxo natural (base 8.2); o tempo real até a marca é só anotado pela sonda (base 11.9).

**Alertas**: venda e expiração (chegam mesmo com o leilão fechado, base 2.11); coberto por cobridor rápido; mudança de veredito de nicho ativo; guerra em curso; throttle travado; disjuntor; suspeita de restrição da conta; banco perto do teto; dado velho.

## 7. Risco e conformidade

**Tetos e disjuntores** (R9 7.3, 7.5): 25% da banca por nicho, 75% no total (o resto é reserva), fração `s_cap` da demanda de `H_max` por item, fração `x_vol` do volume diário (não ser o mercado); perda do dia de 5% da banca suspende compra até a virada; 1% por item bloqueia o item por 24 horas; 5 compras seguidas "já tinha sumido" suspendem a estratégia. O dono pode sobrepor qualquer disjuntor, mas só pelo arquivo.

**Cadência humana**: pelo menos 1 segundo entre ações e no máximo 20 por minuto. A tecla fora disso se perde.

**Quando a API falha ou devolve nada.**

| Situação | Reação |
|---|---|
| Ação sem evento de resposta (falha silenciosa, base 2.12) | Estado `INCERTA`, reconciliação por consulta, ordem volta como `CHECK`; nunca reenvia |
| `AUCTION_HOUSE_SHOW_ERROR` | Texto do erro na mesa; `ItemNotFound` conta em "já tinha sumido"; `NotEnoughMoney` recalcula a banca; `IsBusy` e `DatabaseError` pedem nova tecla depois de 5 s (enum em R1a 3) |
| Erro `HasRestriction` ou `RestrictedAccountTrial`, ou `AUCTION_HOUSE_DISABLED` | Para todas as ordens, faixa `Auction house restricted for this account`, grava; não insiste. [H] É assim que uma restrição temporária da conta (base 1.10) apareceria; não há como testar |
| Consulta sem resposta, parcial ou vazia onde havia oferta | Foto incompleta: não alimenta estimador nem conta como exposição (R9 2.4); 3 seguidas fecham a rodada |
| Throttle travado (base 2.14) | Aviso para fechar e reabrir o leilão |
| Dado velho (idade acima de `A_exec`) | A tecla de ação só refaz a consulta |
| `owners` vazio, `timeLeftSeconds` nulo (base 2.3, 2.4) | Assinaturas e faixas de tempo; a ficha mostra `rivals: by pattern` |
| Varredura completa (`ReplicateItems`) | Não usada nas fases 1 e 2: uma por 15 minutos, pode não responder, chamada recusada conta (base 2.5). A consulta resumida basta para a triagem |

**Como não parecer RMT** (base 1.10: os sinais citados pelo suporte são comprar ou vender item barato por muito ouro e preço muito fora do mercado).
- Guarda de preço na postagem: recusa preço acima de 3 vezes o valor robusto do item ou, sem valor conhecido, acima de 20 vezes o preço de vendedor. O dono muda o limite só pelo arquivo.
- Guarda de preço na compra: recusa pagar mais que 1,2 vez o limite superior do valor. Nenhuma estratégia compra acima do mercado.
- Nunca compra leilão com `containsAccountItem` verdadeiro (base 2.3, 2.4): mover ouro entre personagens próprios pelo leilão a preço arbitrário é o desenho exato do sinal.
- Sem trocas combinadas, sem preço fora da escada, volume diário limitado por `x_vol`.
- Tudo auditável: cada ação grava tecla, hora, preço e valor de referência.

**Privacidade.** Os nomes de vendedores vêm do que o leilão mostra a qualquer jogador; ficam só no banco local, com expurgo de 30 dias. O ForeverGuide instalado compartilha varreduras por padrão (base 7.3); este addon não fala com ninguém.

**Acesso remoto.** O EULA proíbe nuvem e streaming de servidor de terceiros e não há posição oficial sobre o próprio PC (base 8.3). É risco do dono (decisão 9), fora do alcance do addon.

**O que o addon se recusa a fazer**: a lista "nunca" da parte 2, mais: chamar função restrita fora de clique, nem para testar; agir com a guarda de preço vetando; operar nicho não aprovado em arquivo; continuar depois de sinal de restrição da conta.

## 8. Testes

**Bancada com leilão falso.** A bancada atual não simula leilão, dinheiro nem ticker repetido (base 4.9). Nova, em `ferramentas/nicho/bancada/`:
- `leilao-falso.mjs`: `C_AuctionHouse` em fengari com consulta resumida paginada, escadas, eventos, throttle com fila que pode travar, limite de 100 buscas por minuto, e a marca "com ou sem evento de hardware" (sem ela as 7 funções não fazem nada, como o `ReturnNothing` da base 2.12); `GetMoney`, bolsas, correio com fatura, relógio e ticker que repete.
- Mercado sintético com agentes plantados: âncora, cobridor rápido com `τ_r` dado, cobridor de sessão, estoque fundo, parede, isca com parede do mesmo dono. As simulações do R9 (0.3) são o ponto de partida.
- Casos mínimos: cobridor plantado classificado em até 4 eventos; parede e isca marcadas; vendas inferidas dentro de ±20% com fotos a 5 minutos; G1 e G2 disparam; ação sem marca de hardware cai em `INCERTA` e não se repete; foto parcial não muda estimador; cotação acima do teto recusada; tecla com a porta fechada descartada.

**Replay das fotos gravadas.** `mesa/replay.mjs` repassa o arquivo em ordem de tempo rodando no fengari os mesmos `.lua` de decisão do addon (R9, "fora do escopo"); decisão em `t` só enxerga dado até `t` (R9 10.3). Saídas: veredito de cada nicho no tempo, sinais de sombra, e as métricas do R9 10.4 por tecla. O replay não avalia outra cadência de fotos nem a reação dos outros à nossa presença (R9 10.3).

**Checadores estáticos.**
- `node checar-lua.mjs <pasta> --globais` e `node checar-combate.mjs <pasta> --toc --prefixos NichoForever,SLASH_NICHOFOREVER,BINDING_NICHOFOREVER` (base 4.9; a lista de proibidas de hoje não tem função de leilão, R4a 3).
- Novo `checar-acao.mjs`: as 7 funções restritas, `TakeInboxMoney` e `AutoLootMailItem` só aparecem em `Acao.lua` e `Correio.lua`, só dentro de funções `aoClicar*`, nunca dentro de `C_Timer`, `OnUpdate` ou `OnEvent`; nenhum `:Click()`, `RunMacroText` ou `SendChatMessage`; `SetOverrideBindingClick` só aponta para botões `NichoForever*`; nenhuma tecla `MOUSEWHEEL*` em botão de ação; nenhum texto de tela com "Source"; nenhuma seção com mais de 5 linhas sem `Show N more`.

**Sonda no jogo** (ordem deste projeto; números da base 11 entre parênteses). Os comandos de leitura do R1b 16 cobrem S3 a S5 sem addon.

| # | O que medir | Como |
|---|---|---|
| S1 | SavedVariables persistem; build e Interface | gravar um carimbo, `/reload`, conferir (R6b incógnita 4) |
| S2 | Tecla de sobreposição satisfaz o evento de hardware (11.1); tecla presa repete? | uma postagem de item barato pela tecla `P` e a mesma pelo clique do mouse; escutar `ADDON_ACTION_BLOCKED` e `ADDON_ACTION_FORBIDDEN`. Nunca chamo a função fora de clique para ver o que acontece: se a tecla falhar e o mouse funcionar, a resposta está dada |
| S3 | `owners` vem com nomes e `timeLeftSeconds` vem para leilão alheio (11.5); empilhável é commodity; chave do verde com sufixo (11.2) | uma busca de commodity, uma de item, `GetItemCommodityStatus` nas bolsas. **É a medida que decide o valor deste projeto** |
| S4 | Tempo e pedidos da consulta resumida completa, repetição, cadência do throttle (11.3); `SearchForItemKeys` | três rodadas cronometradas, com os eventos `THROTTLED_*` registrados |
| S5 | Depósito por duração e quantidade, corte, devolução em venda, expiração e cancelamento (11.6); para onde vai o item cancelado | `Calculate*Deposit` nas três durações; um leilão barato em cada desfecho; faturas |
| S6 | Atraso do correio (11.10) e do item comprado | carimbos do aviso e da fatura |
| S7 | Ordem entre preços iguais (11.7) | passivo, pelo diário (parte 4.7); o teste ativo pede um segundo jogador |
| S8 | Tempo até a marca de ausente com o leilão aberto (11.9) | só anotar, sem evitar |
| S9 | `ReplicateItems` responde (11.4) | uma chamada por tecla, espera de até 10 minutos; último, porque o projeto não depende dela |
| S10 | Tempo de `/reload` com banco cheio; `ReloadUI` por botão | `debugprofilestop` |

A visibilidade entre facções (11.8) fica para outro projeto: não muda a seleção de nicho.

**Critério de aceite.**
- Bancada: `node rodar-casos-nicho.mjs` imprime `RESUMO erros=0` com 25 casos ou mais.
- Checadores: os três com 0 erro.
- Replay: mesmas fotos, mesmos vereditos da gravação (determinismo).
- Jogo, fase 1: 3 sessões de 1 hora sem erro de Lua; toda ação do diário com `tecla = true` e menos de 50 ms entre a tecla e a chamada; diferença zero entre a Carteira e os leilões próprios mais as faturas; `Calibrado.lua` com corte, depósito e devolução `medido`; ao menos 20 nichos com ficha completa e 3 postagens-sonda fechadas.
- Jogo, fase 2 (para ligar a compra): 30 sinais de sombra com `η_real ≥ 0,5`; Brier de `P(venda)` até 0,22 em 30 postagens; acerto de "serei coberto em 10 minutos" de 70% ou mais.

## 9. Entrega em ondas

A coluna "quem" é sugestão de roteamento (sessão principal, Sonnet ou Haiku com esforço); a tabela da skill de execução do projeto decide. Cada onda fecha com portão da sessão principal.

| Onda | Tarefa | Quem | Depende | Pronto quando |
|---|---|---|---|---|
| 0 | T0.1 Decisões do dono 1 a 10 registradas | principal | - | cada decisão em `estado.md` com data |
| 0 | T0.2 `ARQUITETURA.md` com tabela "API, Contrato" por módulo; 29 esqueletos e TOC | principal | T0.1 | `node checar-combate.mjs <pasta> --toc --prefixos ...` com 0 erro |
| 0 | T0.3 Sonda S3 a S5 pelos comandos do R1b 16 | dono + principal | - | `Calibrado.lua` com esses campos `medido` |
| 1 | T1.1 `leilao-falso.mjs` e `rodar-casos-nicho.mjs` | sonnet/high | T0.2 | 8 casos de API falsa passam |
| 1 | T1.2 `checar-acao.mjs` e casos | sonnet/medium | T0.2 | casos bons passam, casos ruins acusam |
| 1 | T1.3 `Estado`, `Moeda`, `Chave`, `Fila` | sonnet/medium | T0.2 | casos de fila: orçamento, timeout, pausa por ação |
| 1 | T1.4 `Varredura`, `Escada` | sonnet/medium | T1.3 | bancada: resumo paginado completo; foto parcial marcada |
| 1 | T1.5 `Diario` com sonda S1, S4, S10 | sonnet/medium | T1.3 | no jogo: `/nicho sonda` grava S1 e S4 |
| 2 | T2.1 `Diferenca` | sonnet/high | T1.4 | vendas dentro de ±20% no sintético a 5 minutos |
| 2 | T2.2 `Concorrentes` | sonnet/high | T2.1 | cobridor, parede, isca e estoque fundo plantados são classificados |
| 2 | T2.3 `Mercado`, `Nicho` | sonnet/high | T2.2 | vetos V1 a V9 com caso cada; ciclo de vida sem transição ilegal |
| 2 | T2.4 `Visual`, `TelaRadar`, `TelaNicho`, `Teclas` de navegação | sonnet/medium | T2.3 | quadros renderizados aprovados pelo dono (ele decide vendo quadro, base 4.7) |
| 3 | T3.1 `Acao`: postar e cancelar | sonnet/high | T1.2, T2.3 | `checar-acao` 0 erro; bancada: sem marca de hardware nada acontece |
| 3 | T3.2 `Motor` (preço, duração, G1 a G5), `Risco`, `Estrategias` E1, E2 (piso), E6, E7, E8 | sonnet/high | T2.3 | casos de candidatos e de trégua passam |
| 3 | T3.3 `Carteira`, `Correio` (leitura), `TelaMesa`, `TelaLeiloes`, `TelaSessao`, `Alertas` | sonnet/medium | T3.1 | reconciliação zero na bancada |
| 3 | T3.4 Sonda S2, S5, S6 (S7 e S8 correm passivas; S9 por último) e aceite da fase 1 | dono + principal | T3.1 a T3.3 | critério de aceite da fase 1 |
| 4 | T4.1 `Acao`: comprar; modo sombra | sonnet/high | T3.4 | casos de cotação, teto e `INCERTA` passam |
| 4 | T4.2 E3, E4, E5 e tetos de capital | sonnet/medium | T4.1 | sombra grava preenchimento hipotético |
| 4 | T4.3 Aceite da fase 2 e primeira estratégia ligada | dono + principal | T4.2 | critério de aceite da fase 2; linha `aprovadaEm` no `Config.lua` |
| 5 | T5.1 Mesa: `drenar`, `calibrar`, `replay`, `relatorio` | sonnet/high | T3.4 | replay determinístico; `Calibrado.lua` gerado |
| 5 | T5.2 Nichos de conversão; estudo da Game Data API | haiku/medium (dados), sonnet/medium | T5.1, decisão 6 | custo recursivo confere com 10 receitas à mão |

## 10. Decisões que ficam para o dono

1. **Comprar, postar e cancelar por tecla do addon.** Em 2026-11-06 ele proibiu funções que gastam por código (base 4.6). Recomendo liberar com uma tecla por ação, começando só por postar e cancelar; a compra depende do aceite da fase 2.
2. **Fontes de estratégia.** Recomendo aprovar agora, além do Studen, as fontes de E1, do piso de E2, de E6, E7 e E8 (R8a F5, F18, F23; R8b MM, FG, U4N), sabendo que são guias de fã e de beta; E3, E4 e E5 só depois da evidência do próprio addon.
3. **Papel de leilão** (dois addons no mesmo papel não entram juntos, base 4.12). Recomendo manter o Auctionator na fase 1 como tooltip de preço e comparação, e decidir no aceite da fase 2; desligar no ForeverGuide o compartilhamento de varreduras (base 7.3).
4. **Leitura por tecla ou repetição automática limitada.** Recomendo uma tecla por rodada. Custa atenção, mas mantém o desenho sem laço algum.
5. **Guardar nomes de vendedores.** Recomendo sim, só local, com expurgo de 30 dias. Sem isso o projeto perde o diferencial.
6. **Game Data API com credencial de desenvolvedor** (base 5.4). Recomendo adiar para a fase 3 e ler os termos antes (R6b 1.2).
7. **Correio.** Recomendo começar com leitura das faturas e o botão de abrir tudo da Blizzard; a tecla `M` só se ele pedir.
8. **Teste negativo do evento de hardware** (chamar uma função restrita fora de clique para ver o que acontece). Recomendo não fazer: a sonda S2 responde o que importa.
9. **Acesso remoto.** Recomendo o caminho do R10a (Sunshine com Moonlight) e uma pergunta por escrito ao suporte (base 8.3).
10. **Valor da tecla e meta.** O motor precisa de quanto vale uma ação do dono. Recomendo começar com 50 cobre por tecla e `IT_min` de 1 prata, e rever com o lucro por hora medido.

Também é dele o nome (NichoForever ou PregaoForever) e o personagem que opera primeiro: o desenho aceita qualquer um, sem banco de conta (base 4.2).

## 11. Os cinco maiores riscos deste projeto

1. **Os nomes não vêm.** Se `owners` chegar vazio, ou se quase todo degrau de commodity tiver vários donos, o mapa de concorrentes vira estatística de assinatura e `τ_r` por rival deixa de existir. *Derruba*: S3 negativa nos dois casos. Sobra um seletor por `ρ`, parede e vão, que não justifica um addon separado.
2. **Cadência insuficiente para medir reação.** A resolução de `τ_r` é o intervalo entre fotos (R9 9.2), e ele depende do throttle e da tecla do dono. Um robô que cobre em 30 segundos e um humano que cobre em 4 minutos ficam iguais, e nicho com cobridor de sessão pode sair como aberto. *Derruba*: acerto de "serei coberto em 10 minutos" abaixo de 60% depois de 50 postagens.
3. **Nichos pequenos demais, ou inexistentes para 5 ouro.** Um mega-reino pode não ter mercado sem cobridor com giro que pague a sessão; a queda de preço (base 6.1) come a margem do que fica parado. *Derruba*: depois de 2 semanas, menos de 3 nichos `GO` simultâneos ou `IT` medido abaixo do `IT_min`.
4. **Maldição do vencedor na seleção.** Ordenar 150 candidatos por um índice feito de limites inferiores ruidosos escolhe justamente os superestimados (R9 5.7), e só há dado das horas em que o dono joga. *Derruba*: `η_real` de sombra abaixo de 0,3 de forma persistente, ou vereditos que mudam mais de 30% de uma sessão para outra.
5. **O custo da tecla e do ambiente.** Uma tecla por ação por acesso remoto, mais a ida ao correio se cancelado e comprado voltam por lá, pode tornar todo ciclo caro; a sobreposição pode não valer como evento de hardware (base 11.1); as ferramentas dos concorrentes evoluem (o ForeverFlip já cancela quando coberto, base 5.2) e fecham nichos; e uma restrição temporária da conta por falso positivo (base 1.10) para tudo. *Derruba*: S2 negativa para tecla e para clique, ou tempo por ciclo que deixe o lucro por hora medido abaixo do que o dono ganha jogando.
