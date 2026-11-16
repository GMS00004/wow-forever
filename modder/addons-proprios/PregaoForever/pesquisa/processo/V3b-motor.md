> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# Parecer V3b-motor: o motor contra os dados que a coleta grava

Data: 2026-11-16. Revisor da lente "motor contra os dados que existem de verdade". Li inteiros o design (`SINTESE.v1.md`), a base de fatos, o `R1a.md` e o `R1b.md`; do `R9.md`, as seções 0 a 2, 4, 5, 9 a 12 e as incógnitas; do D1 a seção 4.3 a 4.5 e do D6 a seção 4.2 a 4.3 (origem da triagem, das duas testemunhas e das bordas lentas). As contas citadas estão em `<tmp>/V3b-motor/contas.mjs` (só aritmética). Nada foi testado no jogo. Linhas do design citadas como `S:nnn`; do R9, `R9:nnn`.

Como li a coleta (design 5.1 a 5.3 e 6): cada fôlego nasce de uma tecla `L`, faz no máximo 20 buscas em até 60 s e para; o resumo entra uma vez a cada 10 minutos; a escada de commodity vira 12 degraus `preco:quantidade:donos` mais a cauda em 8 baldes; os leilões de item guardam `auctionID`, arremate, lance, faixa de tempo, quantidade e marcas de dono; do resumo fica o último inteiro e, por dia, o mínimo e a quantidade de até 1.500 chaves; nenhuma identificação de vendedor. Entre dois fôlegos não há consulta nenhuma (regra 9, I9).

## 1. Cada estimador e cada regra: os dados bastam?

Legenda do veredito: **sim** (calculável com o que a coleta grava, erro pequeno ou conhecido), **parcial** (calculável, mas com erro grande ou com uma peça sem definição), **não** (não sai dos dados gravados, ou depende de estimador que o próprio design deixou fora).

### 1.1 Coleta e triagem (seção 5.1)

| Estimador ou regra | Veredito | O que é identificável, o que não é, erro esperado |
|---|---|---|
| Foco, ordens 1 e 2 (bolsas, leilões próprios) | sim | Vêm do cliente, sem inferência. |
| Foco, ordem 3 (`minPrice` abaixo do preço de vendedor de `Dados.lua`) | parcial | Calculável pelo resumo. Mas em item que não é commodity o `minPrice` pode ser o lance mínimo (H-07): aí a lista de chaves marcadas incha e come as 20 buscas. O design diz "tanto faz" (S:92), o que vale para o preço e não vale para o orçamento. Achado V3B-04. |
| Foco, ordem 4: `saida · minimo / (1 + k_t · tremor)` | não | Ver item 3. Falta o estado por chave no banco, falta `k_t`, e `saida` não mede giro. Achado V3B-03. |
| Permanência de uma chave no foco entre fôlegos | não | O design não diz que a mesma chave volta no fôlego seguinte. Sem isso não há par de fotos, e sem par não há diferença de escadas. Achado V3B-04. |
| Completude da escada | parcial | A API tem `HasFullCommoditySearchResults` e `RequestMoreCommoditySearchResults` (R1a funções 57 e 75): escada longa pode vir em páginas. O design trata "parcial" como foto que não atualiza nada (S:239) e não tem hipótese sobre paginação nem sobre a ordem das linhas. Achado V3B-15. |

### 1.2 O que cada foto permite (seção 5.3)

| Estimador | Veredito | Comentário |
|---|---|---|
| Frente e fila na frente de um preço | sim | 12 degraus bastam para a frente. A fila até um degrau além do 12º só sai em balde. |
| Número de donos por degrau de commodity (`totalNumberOfOwners`) | sim, com ressalva | É número, não nome, e a foto o guarda. A H-13 fala de `owners` e `timeLeftSeconds`; ninguém conferiu se a contagem vem preenchida. |
| Vendedores distintos numa escada de item | não | Cada leilão de item tem um dono; saber se 5 leilões são de 1 ou de 5 vendedores exige comparar nomes, que o design não lê. Achado V3B-06 e V3B-18. |
| Unidades próprias | sim em commodity (`numOwnerItems`); parcial em item | Em item há a marca `containsOwnerItem` por leilão. Unidades de outro personagem da conta só têm a marca booleana `containsAccountItem` (R1a estrutura `CommoditySearchResultInfo`), sem quantidade: não dá para subtrair. |
| Mínimo e quantidade do resumo | parcial | A linha do resumo inclui os leilões do próprio dono e só traz `containsOwnerItem` (R1a `BrowseResultInfo`). Nas chaves em que o dono vende, o mínimo diário e a quantidade ficam contaminados por ele. Entra nos achados V3B-03 e V3B-13. |

### 1.3 Motor da venda (seção 7.2)

| Estimador ou regra | Veredito | Comentário |
|---|---|---|
| Filtro de isca (5% da janela, salto de 15%) | parcial | "Janela" não está definida no design (no R9 é `N_ref`, que pede a taxa de venda ou `0,15 · Q_tot`). E o salto relativo de 15% não funciona em preço baixo: de 9 para 10 cobre o salto é de 11%, de 9 para 11 é de 22%; só a partir de 7 ticks de preço um tick fica abaixo de 15%. A faixa do dono é exatamente essa. Achado V3B-05. |
| Referência forte | parcial | "Commodity com escada completa" aceita escada de 1 unidade de 1 dono; "5 leilões" aceita 5 leilões do mesmo vendedor e não diz se conta leilão próprio ou só de lance. Achado V3B-06. |
| Referência fraca | não | O texto define quando ela existe e não diz o que o addon faz com ela. As "outras variantes do mesmo `itemID`" não vêm do plano C (busca por chave). Achado V3B-07. |
| `P*` | sim | Confere: 100/240 = 41,7% e 30/170 = 17,6% no exemplo da seção 3.1. Só usa números lidos. |
| Frequência medida por classe e duração (`sold 4 of 10`) | parcial | Identificável, com erro grande: 4 de 10 tem intervalo de 95% de 17% a 69%. "Classe" não está definida, a frequência não é condicionada à fila na frente e o desfecho de lote cancelado ou vendido em parte não tem regra. Achado V3B-10. |
| Veredito `AUCTION` (frequência acima de `P*`) | parcial | Herdou o erro acima: com 10 desfechos, `P*` de 18% contra "4 de 10" não se separa do ruído. |
| Regras em sombra (`cobrir`, `folga`, `W*`) | não | `W*` pede P(venda), que o design deixou fora. O desfecho hipotético de `cobrir` só é observável nas janelas com foto; o da regra real é observado nas 24 horas. Comparação torta. Achado V3B-11. |
| Ordem entre preços iguais (S10) | parcial | Identificável quando o degrau próprio está na frente e é consumido aos poucos, com fotos próximas. Cancelamento de terceiro no mesmo degrau confunde. Com ordem aleatória, 5 concordâncias seguidas saem ao acaso em 6% dos casos. Aceitável. |

### 1.4 Piso do vendedor (seção 7.3)

| Estimador ou regra | Veredito | Comentário |
|---|---|---|
| `EV = soma((v − p_j) · q_j)` sobre a escada fresca | sim | Preço de vendedor ao vivo e escada lida. É a conta mais limpa do design. |
| "Cobre disponível abaixo do vendedor por varredura" e "três varreduras de prova" | parcial | O resumo dá o mínimo e a quantidade total da chave, não a quantidade abaixo de `v`. O número só sai das escadas lidas, no máximo 20 por fôlego, depois das bolsas e dos leilões próprios. "Varredura" não está definida. Achado V3B-16. |
| Lote de confirmação conferido pela variação do dinheiro | sim | Medida direta. |

### 1.5 Compra para revenda (seção 7.4)

| Estimador ou regra | Veredito | Comentário |
|---|---|---|
| Venda inferida pela diferença de escadas | parcial, e errada como está escrita | Ver item 2. O design adota só a seção 2.1 do R9, sem o teto de intervalo, sem a regra de expiração e sem a censura. Achado V3B-01. |
| Saída conservadora: mediana dos mínimos diários | parcial | Sai de `dias`, se a chave estiver entre as 1.500 (o design não diz como se escolhem). Sem número mínimo de dias. O mínimo do dia depende de quantos resumos houve no dia e inclui o leilão do próprio dono. |
| Saída conservadora: "preço robusto da última foto" | não, como está | O estimador não está definido no design nem listado em `Estimadores.lua` (S:170). No R9 ele pede a janela `N_ref` e a apara. |
| "Líquido de um depósito" | não em item que o dono não tem | `CalculateItemDeposit` recebe um `ItemLocation` (R1a função 2): só calcula para item que está na bolsa. Para o item de um sinal de compra o depósito não pode ser lido, e a regra 17 proíbe fórmula. Achado V3B-09. |
| Classe A (o vendedor paga mais que o custo) | sim | |
| Classe B (venda inferida em 3 intervalos das últimas 24 h) | parcial | "Intervalo" não está definido. Herdou o defeito da venda inferida: expiração de leilão de 2 horas na frente conta como venda. Achado V3B-01. |
| Bordas lentas (vida das ofertas contra o tempo de reação) | não, pelas fotos | Fotos separadas por minutos não medem vida de segundos; e o sinal só aparece se a vida já foi medida, mas a vida só se mede com sinais. Achado V3B-12. |
| Guarda de regime ("oferta funda") | não | No R9 5.2 o limiar é `k_crash · λ · H_ref`: pede a taxa de venda. O design não dá número nem definição. Achado V3B-14. |
| Deriva por categoria | parcial | Ver item 2. O banco só guarda o último resumo e o mínimo por dia. Achado V3B-13. |
| `Δ_canc` do R9 4.6 | não | Pede P(venda) do leilão ativo e `W*` da repostagem; o design deixou os dois fora (S:307). Achado V3B-08. |
| `η_real` (realizado sobre previsto, 30 lotes) | parcial | Calculável. Falta dizer se "previsto" é o ganho antes ou depois de multiplicar por `η_real`, e se a razão é de somas ou média de razões. Com 30 lotes de cauda longa o erro da razão é da ordem de 0,2 a 0,3. |
| "Já sumiu" (30 sinais) | sim | Contagem direta na releitura. Em 21 de 30 o intervalo é de 52% a 83%. |
| `T_caixa` na ordem da fila | não | Se for por item, pede o tempo até vender, que não é estimado. Se for uma constante (o atraso do correio), não muda a ordem. Entra no V3B-17. |

### 1.6 Tetos e antiguerra (seções 9.2 e 9.3)

| Regra | Veredito | Comentário |
|---|---|---|
| Tetos em fração da banca | sim | A parcela "estoque a valor de saída conservador" herda as ressalvas da saída. |
| Compra diária até 10% do "volume diário mínimo medido" | não | Volume diário não sai de 1 a 3 horas de fotos por dia sem extrapolar, e o design não diz como. Entra no V3B-17. |
| G1 (2 cancelamentos com repostagem em 4 h) | sim | Contagem do Livro. |
| G2 (coberto 2 vezes em menos de 10 minutos) | parcial | "Coberto" só se vê numa foto: a resolução é o intervalo entre fôlegos. Coberto aos 3 minutos e visto aos 15 não conta. Com a H-10 valendo, o ciclo cancelar, receber e repostar não cabe em 10 minutos. Achado V3B-20. |
| Parede | não | Sem limiar numérico; no R9 9.2 depende de `λ · H_ref`. Em item, "poucos donos" pede identidade. Achado V3B-14. |
| Deriva abaixo de −10% em dois dias | parcial | Ver V3B-13. |

### 1.7 Diário de calibração (seção 7.6)

| Linha | Veredito | Comentário |
|---|---|---|
| Corte, depósito, devoluções | sim | Leitura exata; o depósito só para item na bolsa. |
| Atraso do correio (aviso de venda até a fatura) | parcial | O addon só vê a fatura quando o dono abre a caixa: mede a hora em que ele foi ao correio, não a chegada. A própria tela Mine já mostra `gold arrives in about 41 min` (S:626), que só pode vir do `timeLeftSeconds` do leilão vendido (R1b 10, incógnita 17), sem hipótese registrada. Achado V3B-19. |
| Entrega de compra e de cancelamento | sim | O evento traz os dois atrasos (R1a evento 10). |
| Cadência do fôlego, "já sumiu", ordem entre preços iguais | sim | |
| Frequência de venda | parcial | Ver 1.3. |
| Tempo por ação | parcial | "Linha aparecer até a tecla" inclui o tempo em que o dono estava olhando outra coisa; pede mediana e teto. A coluna "partida" traz 15 cobre numa linha cuja unidade é segundo. |

## 2. A venda inferida com fôlegos manuais

### 2.1 Que cadência o dono mantém

O design não dá a cadência; ela decorre das regras. Um fôlego são 20 buscas a 30 por minuto, 40 s (conta 10 do script), e depois o addon para até a próxima `L`. O dono também posta, compra, anda até o correio (o ouro volta em cerca de 1 hora, base 1.8) e o leilão fechado zera a fila (S:241). Três regimes plausíveis, que são estimativa minha e não fato:

| Regime | Intervalo entre fotos da mesma chave | Quando acontece |
|---|---|---|
| Vigília (o dono só aperta `L`) | 1 a 3 minutos | Blocos de 10 a 20 minutos com o leilão aberto |
| Operação normal (postar, comprar, correio) | 5 a 20 minutos | O grosso da sessão |
| Entre sessões | 8 a 20 horas | Toda noite |

Com 1 a 3 horas de fôlegos densos por dia, a coleta enxerga de 4% a 12% das horas do dia (conta 9). E as 20 buscas são divididas com as bolsas, os leilões próprios e a triagem do piso: para as chaves de giro da fase 2 sobra o resto, sem cota e sem garantia de repetição (V3B-04).

### 2.2 Que fração das vendas se recupera

O R9 0.3 (R9:44) mede, em mercado sintético com escada inteira e fotos regulares: 96% a 1 minuto, 83% a 5, 66% a 15, 52% a 30 e 40% a 60, num mercado de 30 unidades por hora; 98%, 91%, 80% e 66% (5, 15, 30 e 60 minutos) num de 3 por hora. Quatro coisas afastam o design desses números, todas para pior ou para o lado errado:

1. **O mercado do Forever não é o do sintético.** É um mega-reino (base 1.2). O que manda é `u = λ · Δ / l_f` (R9 2.2). Uma commodity que venda 600 unidades por hora em lotes de 20 pede foto a cada 0,8 minuto para manter o viés em 20%; a 3 minutos a fórmula do próprio R9 dá 59% recuperado e a 10 minutos, 36% (contas 3 e 4; extrapola a fórmula além da faixa simulada, serve só de ordem de grandeza). Ninguém mediu `λ` no Forever.
2. **Só 12 degraus.** Numa commodity líquida a frente inteira de 12 degraus pode girar entre duas fotos. Aí não há sobrevivente, o intervalo é censurado (R9 2.4, R9:287) e o que se sabe é só "pelo menos o que se via". O design não diz o que faz nesse caso.
3. **Expiração conta como venda.** A proposição da fronteira diz que o que some abaixo de F é venda "salvo cancelamento ou expiração na frente" (R9:214). No Forever há leilão de 2 horas (base 1.5), e a fonte que o design usa manda leilão curto no que gira (R8b R15, S:129). Com tempo restante uniforme, 8% dos leilões de 2 horas expiram num intervalo de 10 minutos, 25% em 30 minutos e 50% em 60 (conta 5). O R9 tem a regra para item (2.3, pela faixa de tempo) e o teto `Δ_max` (2.4); o design adotou só a 2.1 (S:307) e não tem `Δ_max` em lugar nenhum. A foto de item já guarda a faixa de tempo, mas nenhuma regra a usa.
4. **Intervalo entre sessões.** Sem `Δ_max`, a primeira foto do dia faz par com a última da véspera: quase tudo expirou ou foi cancelado, e a diferença lê isso como venda ou como "tudo girou".

O que é identificável, então: um limite inferior das vendas **dentro das janelas observadas**, em chaves que ficaram no foco em fôlegos seguidos, com intervalos curtos, e desde que se desconte a expiração. Fora disso o número não é limite inferior de nada: pode errar para cima.

### 2.3 Efeito na classe B

A classe B torna um sinal executável com ouro real. Como escrita (S:362), ela pede "venda inferida no preço de saída ou acima em 3 intervalos das últimas 24 horas". Problemas: (a) "intervalo" sem definição aceita o par da noite; (b) expiração de leilão curto na frente vale como testemunha; (c) nada exige que as 3 testemunhas venham de momentos diferentes: 3 fôlegos em 4 minutos são, na prática, uma observação só (R9 1.2 trata fotos próximas como quase a mesma foto, R9:94); (d) a venda inferida acontece em preço até F; quando a saída é ancorada na mediana dos mínimos diários ela fica perto ou abaixo da frente e a condição vira "houve alguma venda", que é fraca mas legítima; quando a saída fica acima da frente (o caso do `vao`, que reposta no degrau seguinte), a testemunha legítima é rara e a ilegítima (sumiço de degrau mais alto por expiração ou intervalo longo) é a que aparece. É o achado V3B-01, o único que classifico como bloqueante: é o ponto em que um estimador errado libera compra.

### 2.4 Efeito na deriva

A deriva não usa a diferença de escadas; usa o resumo. O defeito dela é outro (V3B-13): o banco só guarda o último resumo inteiro, então "resumos separados por 6 horas ou mais" só existe no primeiro resumo de cada sessão, contra o último da véspera. Sai uma amostra por sessão, tirada em horas diferentes do dia (o efeito de hora, que ninguém mediu, entra como deriva), sobre o `minPrice`, que é o número mais sujeito a isca (R9 1.1, R9:58). A mediana entre centenas de chaves tira o ruído de cada item, não o efeito comum de hora. Serve como alarme grosso; não serve como custo de carregar com número, e o design nem dá a fórmula desse custo: o `EV` da seção 7.4 não tem termo de deriva.

### 2.5 O modo papel mede o que promete?

A promessa (S:17, S:19): o papel prova, com os números do dono, se comprar para revender paga. O que `Sombra.lua` mede de fato, com esta coleta, é a soma de três coisas: o mérito do sinal, a cobertura de tempo do dono e os defeitos da venda inferida. O design não separa as três.

**Onde engana para cima (parece melhor do que é):**

1. **Compra.** A oferta que ainda está lá na releitura é a que ninguém quis (R9 10.2, R9:1097; o design reconhece no risco 5). Além disso, no papel a tecla `B` faz uma releitura e conta; ao vivo há releitura, cotação, `T_ver` e `Y`. O "já sumiu" do papel subestima o do vivo, e o portão do `sniper` (até 70%) usa o do papel.
2. **Preço de compra.** O papel usa o preço listado; ao vivo a commodity é comprada pela cotação, que pode vir acima.
3. **Venda.** Expiração e intervalo longo contados como venda (2.2). Vale também para as testemunhas.
4. **Reação dos concorrentes.** O lote de papel não aparece na escada, então ninguém o cobre. O R9 desconta isso com `π_react` (R9:1102, 1106); o design não tem o parâmetro.
5. **Lote aberto.** Não há regra de marcação do lote de papel que não vendeu. Marcado a valor de saída, vira ganho não realizado.

**Onde engana para baixo (parece pior do que é):**

1. **Cobertura de tempo.** O lote de papel só "vende" quando há par de fotos da chave. Com 4% a 12% do dia observado, um lote de 24 horas postado no fim da sessão passa 20 horas sem testemunha possível e fecha como não vendido. Em commodity muito líquida o lote pequeno ainda enche dentro da janela; em item de giro médio, não.
2. **Subcontagem.** `S_lo` sem a correção `ξ` (escolha conservadora declarada), mais a censura dos 12 degraus.
3. **Chave que sai do foco.** Se a chave do sinal não volta nos fôlegos seguintes, o lote nunca fecha, ou fecha como perda.
4. **Depósito.** Para item que o dono não tem, o depósito não pode ser lido (V3B-09): o papel ou fica sem o custo ou usa fórmula.

Saldo: o sinal das duas direções não se cancela de forma conhecida. O portão "30 sinais fechados, resultado positivo, razão de 0,5" (S:144) pode reprovar uma estratégia boa por falta de cobertura e pode aprovar uma ruim por expiração lida como venda. O critério do risco 5 (micro divergindo do papel em mais de 2 vezes) só dispara depois de gastar ouro. É o achado V3B-02. O que conserta: fechar o lote de papel por **exposição observada**, não por relógio; três desfechos (vendeu, não vendeu com exposição suficiente, inconclusivo), só os dois primeiros contando nos 30; e uma sessão de calibração densa na sonda, que é a calibração que o R9 chama de mais importante (2.9, R9:344) e que o design deixou fora.

Um ponto de mecânica: o replay tem de dar igual ao papel do addon (S:768). Isso só é possível se o addon calcular a diferença sobre a foto compacta (12 degraus e baldes), a mesma que a mesa lê, e não sobre a escada inteira em memória. O design não diz qual. E o anel de fotos é de tamanho fixo (S:297) enquanto o contrato diz que foto sem recibo não se apaga (S:712): numa sessão longa sem a mesa, um dos dois cede.

## 3. A triagem do foco

A fórmula `saida · minimo / (1 + k_t · tremor)` aparece no design em uma linha (S:226), com "calculada só com a diferença entre resumos". A definição das peças só existe no D6 4.2 (linhas 236 a 243), que a sessão de implementação não terá:

```
queda   = 1 se o minimo caiu ate g_cob (3%)
tremor  = media movel de queda / Δ                   coberturas finas por hora
saida   = media movel de max(0, Q_{k-1} − Q_k) / Δ   unidades que saem por hora
```

**Está definida o bastante para implementar?** Não. Faltam no design: a definição de `saida` e de `tremor`; `g_cob`; a constante da média móvel; o valor de `k_t` (nem o D6 dá; lá ele é saída de uma calibração); a unidade de `k_t` (horas); o que fazer com intervalo longo, resumo incompleto e chave que sumiu do resumo.

**É calculável só com resumos?** Em princípio sim, mas não com o banco do design. Em campos do resumo: `minimo` = `minPrice` da chave; `Q` = `totalQuantity`; `Δ` = diferença entre as horas de resposta de dois resumos completos. `saida` e `tremor` são médias móveis **por chave**, então pedem dois acumuladores por chave, para cerca de 8 mil chaves. O banco guarda o último resumo a 14 bytes por chave (S:288), que é mínimo e quantidade, e mais nada por chave. Sem os acumuladores só dá para calcular a diferença de um único par, e só dentro da sessão.

**O que as duas peças medem de verdade:**

- `saida` é a queda **líquida** da quantidade total, retificada. Em regime estável entra tanto quanto sai (R9 3.1, R9:379), a variação líquida oscila em torno de zero e `max(0, ·)` devolve a parte positiva do ruído. Um vendedor que cancela 2.000 unidades ou uma leva que expira pontua mais que um item que vende 500 por hora com reposição. Ela mede oscilação de estoque listado, não giro. E conta como saída o cancelamento e a venda do próprio dono.
- `tremor` conta quedas de até 3% do mínimo. Em preço baixo isso não existe: a 9 cobre o menor passo possível é 11%; um tick só fica dentro de 3% a partir de 34 ticks de preço (conta 6). Nos itens do dono o `tremor` nasce zero e a fórmula vira `saida · minimo`.
- O produto por `minimo` favorece item caro, que é o que a banca de 5 ouro não alcança. O D6 tinha o filtro de preço entre `preco_min` e `w_item · B`; o design não o trouxe.

O design diz que a fórmula "é hipótese, a conferir contra o que as escadas medem", mas não a lista como H-nn, não diz a medida e não diz o que acontece se ela falhar. O D6 dizia: correlação de postos contra o medido abaixo de 0,4 depois de 30 nichos, a triagem vira filtro de preço e quantidade. É o achado V3B-03.

## 4. A referência e o filtro de isca: onde enganam

Conferi a regra da seção 7.2 (S:313) caso a caso.

| Caso | O que acontece com a regra do design | O que o design faz | Falta |
|---|---|---|---|
| **Isca clássica** (1 unidade barata, salto grande) | O filtro tira o degrau; a frente passa a ser o seguinte. | Não ancora preço nela (S:511). | "Janela" sem definição; número máximo de degraus de isca (o `J_isca` = 3 do R9) ausente. |
| **Item barato, preço em cobre** | Qualquer primeiro degrau pequeno seguido do preço vizinho passa por isca: 9 para 11 cobre é salto de 22%. Se `SupportsCopperValues()` for falso e o tick for 1 prata, o mesmo vale até 7 prata. | Nada: o filtro é só relativo. | Guarda em ticks. V3B-05. |
| **Item com poucos leilões** | Com janela mínima, a cota de isca é 1 unidade: o leilão mais barato vira isca sempre que o segundo estiver 15% acima, o que em verde de nível baixo é o normal. A frente vira o segundo preço. | `igualar` posta no segundo preço. | Dizer se o filtro vale para item. V3B-05. |
| **Escada rala de commodity** | 1 degrau de 1 unidade de 1 dono é "commodity com escada completa": referência forte. Se for um anúncio absurdo, `igualar` o copia, e a faixa "até 3 vezes a referência" não protege, porque é medida contra ele mesmo. | A diferença de mais de 3 vezes contra o Auctionator "marca dado suspeito" (S:731), sem dizer o efeito. | Mínimo de unidades e de donos. V3B-06. |
| **Monopólio em item** | 5 leilões do mesmo vendedor valem como referência forte. | Nada: não há identidade. | Contagem de donos distintos. V3B-06, V3B-18. |
| **Parede na frente** | A frente é a parede. `igualar` deixa o lote atrás dela inteira no pior caso de ordem; `cobrir` fica na frente. | "Nunca propõe preço acima dela" (S:511), o que os três candidatos já garantem. O `P*` não muda e a frequência exibida não vê a fila. | Mostrar a fila na frente de cada candidato na visão Sell; definir parede com número. V3B-10, V3B-14. |
| **Item com sufixo** | 5 leilões da mesma chave (item, nível, sufixo) é raro em verde de sufixo aleatório: a maioria cai em "fraca" ou "nenhuma". É justamente a única estratégia com fonte aprovada (`venda_verdes`). | "Fraca" não tem comportamento escrito; `NO REFERENCE` não tem tecla. | Comportamento da fraca; de onde vêm as variantes; medir na onda 2 que fração dos verdes tem referência forte. V3B-07. |
| **Equipamento e o erro de postagem** | O contorno é igualar o "menor preço" (base 1.11). A tela da Blizzard busca equipamento pela chave sem nível e sem sufixo (R1b 8, `SendSellSearchQuery`), então o "menor preço" do erro pode ser o do `itemID` inteiro, não o da chave. | Iguala a frente da chave. | Hipótese nova e leitura das duas escadas. V3B-07. |
| **Preço em queda** | Para postar não engana: a tecla relê foto com mais de 30 s. Para comprar, a mediana dos mínimos diários fica acima do mercado, mas o `min` com o preço da foto corrige. A frequência `sold x of 10` foi medida no preço de ontem. | Suspende compra com deriva de −10% em dois dias. | A deriva tem o problema do item 2.4. V3B-13. |
| **Leilão do próprio dono na frente** | Commodity: as unidades próprias saem da escada (S:169), a frente é a dos outros e `cobrir` não cobre a si mesmo. Correto. Item: a foto guarda a marca, mas a seção 7.2 não diz que leilão próprio sai da frente nem da contagem de 5. No resumo, o mínimo da chave é o do próprio dono. | Só diz que leilão com a marca "nunca vira linha" de compra (S:743). | Uma frase na 7.2. V3B-06. |
| **Leilão de outro personagem da conta** | Commodity: só a marca booleana por degrau, sem quantidade; a frente pode ser do próprio alt e o addon manda cobrir. | Nada. | Degrau com `containsAccountItem` não serve de frente para `cobrir`. V3B-06. |
| **Leilão só de lance** | Não tem arremate; não é oferta comprável ao preço. | Nada. | Fica fora da contagem e da frente (R9 1.5, R9:183). V3B-06. |

## 5. O que do R9 ficou fora e o que entrou

### 5.1 Ficou fora e deveria entrar junto com o que foi adotado

| Peça do R9 | Por quê | Custo |
|---|---|---|
| 2.3 e 2.4: expiração pela faixa de tempo em item; teto `Δ_max`; censura sem sobrevivente, sem estoque e de varrida | Sem elas a 2.1, que foi adotada, erra para cima (item 2.2). O dado já está na foto. | Regras e três parâmetros |
| 2.9: calibração por série densa e subamostragem | É a única forma de saber quanto a cadência real do dono recupera. Custa zero ouro: 30 a 60 minutos de `folego.renova_com_tecla` em 5 chaves. | Um passo novo na sonda |
| 1.5: marca de escada rasa (`N_min`) | É o que falta na referência forte. | Um parâmetro |
| 10.2 e 10.3: `π_react`, as duas variantes de preenchimento, a lista de vieses | O design cita 10.2 e leva só a metade. | Texto na seção 3.3 |
| 3.1: a fila `q(p)` no pior caso de ordem, como número cru | Não é modelo: é leitura da escada. Condiciona a frequência e dá sentido à parede. | Uma coluna |
| Incógnitas 2, 5, 6 e 8 (R9:1417 a 1423): a compra de commodity leva sempre o mais barato; a escada vem completa; as unidades próprias vêm marcadas; como aparece a venda parcial de um lote | Sustentam a fronteira, a foto e o fecho de lote. Não estão nas hipóteses H-01 a H-25. | Quatro linhas na 2.2 e na sonda (a S8 já compra uma commodity) |

### 5.2 Entrou e não deveria, ou não como está

| Peça | Problema |
|---|---|
| `Δ_canc` (4.6) na fase 2 | Depende de P(venda) e de `W*`, os dois fora (V3B-08). |
| Guarda de regime (5.2) | Depende de `λ · H_ref` (V3B-14). |
| `W*` em sombra | Depende da tabela de P(venda), que está fora (V3B-11). |
| Venda inferida (2.1) como testemunha de execução | Só com as regras de 2.3 e 2.4 (V3B-01). |
| Bordas lentas (do D1) pelas fotos | A cadência não resolve segundos (V3B-12). |
| Triagem do D6 | Item 3 (V3B-03). |

### 5.3 Abrir mão de toda identificação de vendedor

A regra 20 ("nome de jogador nunca é gravado") é escolha do design (conflito 15), não regra do dono. O que o motor perde:

1. **Casar repostagem em item** (mesmo dono, id novo, preço menor; R9 2.3, R9:248). Sem isso não se separa "sumiu da frente porque vendeu" de "cancelou para repostar".
2. **Calibrar `π_cf`** (R9 2.9, R9:347): a calibração usa o reaparecimento do mesmo dono. Sem identidade o parâmetro fica no valor de partida para sempre.
3. **Concentração**: 5 leilões de 1 vendedor contra 5 de 5; parede em item; isca com parede do mesmo dono acima (R9 9.2).
4. **Tempo de reação por rival e número de cobridores rápidos** (R9 9.2 e 9.3). O G2 sem nome não distingue um cobridor que reagiu duas vezes de dois vendedores que chegaram por acaso.
5. **Estoque fundo** (reposição do mesmo degrau).

Em commodity quase nada se perde: a contagem de donos por degrau já vem como número. A perda é em item, que é onde está a estratégia aprovada.

**Uma assinatura que não guarda o nome recupera a função?** Em boa parte, e em dois níveis:

- **Contagem de donos distintos**, calculada na hora da foto e gravada como um número. Não guarda nome nem derivado de nome; resolve o item 3 acima já na fase 1. Cabe na regra 20 como está.
- **Assinatura numérica curta**: resumo de 16 bits do nome com um sal sorteado a cada sessão e nunca gravado. Dentro da sessão identifica "o mesmo vendedor" entre fotos, o que recupera os itens 1, 2 e 4. Com 16 bits, cerca de 55 personagens do reino caem em cada valor (conta 8), então o número não identifica ninguém; entre 50 vendedores de uma escada a chance de alguma colisão é de 1,9%. Sem o sal gravado não se liga uma sessão à outra. Tem de ser aritmética pura (regra 14).

Limites: tudo depende de `owners` vir preenchido (H-13); vários personagens do mesmo jogador continuam separados; e o item 5 pede identidade entre sessões, que este desenho não dá. Recomendo adotar a contagem já e levar a assinatura ao dono como decisão, porque muda a regra 20. Achados V3B-06 e V3B-18.

## 6. Parâmetros sem valor, sem unidade ou sem regra de calibração

### 6.1 Usados no texto e ausentes da seção 7.6, da 9.2 e do Apêndice B

| Parâmetro | Onde é usado | Falta |
|---|---|---|
| `k_t`, `g_cob`, constante da média móvel da triagem | 5.1 | valor, unidade, calibração |
| "Janela" do filtro de isca; máximo de degraus de isca | 7.2 | definição |
| Mínimo de unidades e de donos para referência forte em commodity | 7.2 | valor |
| `folga` | 7.2 | valor inicial (o texto diz que a fonte não dá) |
| Duração padrão por classe | 7.2 | valor inicial; a DD3 só pergunta a regra de preço |
| "Classe" (da frequência, da regra, da duração, dos 50 desfechos em sombra) | 7.2, 7.6, 3.3 | definição da partição |
| `Δ_max` (intervalo máximo de um par de fotos) | 7.4 | valor |
| Número de degraus (12) e de baldes (8); largura dos baldes | 5.3 | estão só na 5.3; a largura não existe |
| Classe B: 3 intervalos em 24 horas | 7.4 | fora do Apêndice B; "intervalo" sem definição |
| Dias mínimos para a mediana dos mínimos diários; regra das 1.500 chaves | 7.4, 5.3 | valor e regra |
| Parâmetros do "preço robusto" | 7.4 | definição |
| Bordas lentas: faixas de desconto, limiar | 7.4 | valor (no D1 era sobrevivência de 0,5) |
| Guarda de regime: o que é "funda" | 7.4 | valor |
| Deriva: 6 horas; −10% em dois dias; como vira custo | 7.4, 9.3 | fora do Apêndice B; sem fórmula e sem calibração |
| `Δ_canc`: custo de ação, custo de carregar, histerese | 7.4 | valores |
| Parede: tamanho e número de donos | 9.3 | valores |
| "Já sumiu" até 70% (portão do `sniper`); "sem os 3 melhores"; até 2 degraus no `vao` | 3.2, 3.3 | fora do Apêndice B |
| Prova do piso: "varredura", "horários diferentes" | 3.3 | definição |
| `T_caixa` | 7.5 | definição (por item ou global), valor de partida |
| Volume diário medido | 9.2 | estimador |
| Prazo da cotação (5 s em `COTANDO`) | 8.3 | fora do Apêndice B |
| `−1%` de perda num item | 9.4 | fora da tabela 9.2 |
| `π_react` | 3.3 (via R9 10.2) | ausente |

### 6.2 Com valor e sem regra de calibração

| Parâmetro | Observação |
|---|---|
| `remoto.latencia_ms` (150, "a medir") | O jogo não enxerga a latência do acesso remoto; ninguém diz quem mede nem como. |
| Faixas dos valores do `Calibrado.lua` | O design diz que cada valor tem faixa e que a mesa ajusta "dentro da faixa da tabela do R9 12-C" (S:305, S:708). A tabela não está no design, e a sessão de implementação não terá o R9. |
| `μ_min` 0,15; tíquete 15 cobre; filtro de isca; referência forte 5 | O R9 dá como calibrar o filtro (50 fotos rotuladas, R9:193); o design não traz. |
| Tetos da 9.2 | São escolha, corretamente fora da calibração; registro só que não há regra de revisão além da DD10. |

### 6.3 Com dois valores

| Parâmetro | Valores |
|---|---|
| Sugestão de salvar | 45 minutos ou 50 ações (S:299, S:876) contra "a cada 50 minutos" (S:690) |
| Grão do histórico de preço | "menor preço por bloco de 4 horas" (S:135) contra `dias` com um mínimo por dia (S:258, S:277). O bloco de 4 horas não tem lugar no banco. |
| Tempo por ação | A linha da 7.6 dá como partida "tíquete de 15 cobre": cobre numa grandeza em segundos. |
| Chaves com foto | Banco dimensionado para 40 chaves (S:290) contra foco de 20 por fôlego (S:221); sem regra que diga quais 40. |

## Veredito

O design se sustenta na fase 1 e não se sustenta, como está escrito, na fase 2. Na fase 1 o que decide é leitura direta (depósito, corte, preço de vendedor, escada fresca, `P*`), e os defeitos são de definição: filtro de isca em preço baixo, referência forte em escada rala, referência fraca sem comportamento, frequência com 10 amostras. Na fase 2 quase tudo depende da venda inferida, e a coleta por fôlego manual não a sustenta sem as regras de intervalo e de expiração que o R9 já tinha e o design não trouxe. O que mais preocupa é a classe B liberar compra com testemunha falsa (V3B-01) e o papel virar medida da presença do dono (V3B-02).

Pontos que a revisão não deve estragar:

1. Leitura direta acima de modelo: depósito, corte e preço de vendedor lidos na hora; `P*` em vez de chance de venda inventada.
2. `W*`, P(venda), Kelly e perfis fora das fases 1 e 2. A correção dos achados 08, 11 e 14 é tirar o que sobrou dessa dependência, não trazer os modelos de volta.
3. Foto incompleta, vencida ou vazia suspeita não atualiza nada (I6), e o resumo só faz triagem.
4. O piso do vendedor como primeira compra: é a única conta de compra que os dados fecham sem inferência.
5. Classe C nunca executável e o desconto `η_real` sobre o ganho, não sobre a saída.

Limites deste parecer: os regimes de cadência do item 2.1 e a raridade de verdes com 5 leilões da mesma chave são estimativa minha, não medida; a extrapolação da fórmula `ξ` para um mercado de 600 unidades por hora sai da faixa que o R9 simulou. Os valores numéricos que proponho nas correções (15 minutos, 25%, 3 vezes, cotas do fôlego) são escolha de projeto a calibrar, não fato.

## Tabela dos achados

| id | seção | gravidade | tipo | achado | evidência | correção |
|---|---|---|---|---|---|---|
| V3B-01 | 7.1 e 7.4 (S:307, S:362); 5.3 | bloqueante | fato_errado | A venda inferida entra só com a regra da fronteira (R9 2.1). Sem teto de intervalo, sem regra de expiração e sem censura, o sumiço por expiração de leilão de 2 ou 8 horas e o par de fotos entre sessões viram venda. Esse número libera compra executável (classe B) e fecha vendas no papel. | S:307 adota só '2.1'; `Δ_max` não aparece no design (busca: zero ocorrências); R9:214 ('salvo cancelamento ou expiração na frente'); R9:286-289 (censuras); R9:1320 (`Δ_max` entre 5 min e 2 h); base 1.5 (2, 8 e 24 h); conta 5: 25% dos leilões de 2 h expiram em 30 min e 50% em 60. | Na 7.4, depois de 'Classe da saída', acrescentar: um par de fotos só vale com as duas completas e intervalo de até `Δ_max` (partida 15 min; nunca entre sessões); sem sobrevivente nos 12 degraus o par é censurado e não é testemunha; em item, leilão visto por último na faixa Short não conta como venda; a classe B exige 3 pares válidos em 2 blocos separados por 30 min ou mais. Incluir `Δ_max` no Apêndice B. |
| V3B-02 | 3.3 (S:143-144); 16 (S:768); 19, risco 5 | importante | lacuna | O papel não tem regra de fecho. O lote hipotético só vende quando há par de fotos da chave, e a coleta cobre de 4% a 12% do dia; lote sem testemunha possível fecha como perda. O portão de 30 sinais mede a cobertura do dono junto com a estratégia e erra nas duas direções. | S:143 ('a venda só conta pelas vendas inferidas'); conta 9 (1 a 3 h de 24); R9:1099-1106; R9:1119 ('só há fotos nas horas em que o dono jogou'); R9:344 (calibração por série densa, ausente do design); nenhum texto sobre lote de papel não vendido. | Na 3.3, definir: o lote de papel acumula exposição observada (soma dos pares válidos da chave); fecha 'vendeu' ao encher, 'não vendeu' só com 2 h ou mais de exposição, senão 'inconclusivo', que não conta nos 30; lote aberto marca ao preço de vendedor; aplicar desconto de reação de 0,2 (R9 10.2). No Apêndice A, criar S11: série densa de 30 min em 5 chaves, subamostrada na cadência real. |
| V3B-03 | 5.1 (S:226) | importante | lacuna | A triagem do foco não é implementável: o design não define `saida` nem `tremor`, não dá `k_t`, e o banco não guarda os acumuladores por chave. `saida` mede queda líquida de estoque listado, não giro; `tremor` é zero em preço de cobre; o produto favorece item caro. | S:226 (única menção); D6 linhas 236-243 (definições e `g_cob` de 3%, sem valor de `k_t`); S:288 (resumo com 14 bytes por chave); R9:379 (oferta nova maior ou igual às vendas: a variação líquida oscila em torno de zero); conta 6 (um tick só cabe em 3% a partir de 34 ticks). | Na 5.1, trocar a fórmula por um filtro declarado: chaves com preço unitário até o teto por item, mínimo acima do preço de vendedor e quantidade positiva em 2 resumos, em rodízio. Registrar a fórmula do D6 como hipótese H-26, com as definições, `k_t`, os dois acumuladores por chave no banco e o critério de abandono (correlação de postos abaixo de 0,4 em 30 chaves). |
| V3B-04 | 5.1 (S:226); 5.2; H-07 (S:92) | importante | lacuna | As 20 buscas do fôlego não têm cota por classe nem permanência. Bolsas, leilões próprios e a triagem do piso podem consumir todas; a mesma chave de giro não tem garantia de voltar no fôlego seguinte. Sem par de fotos da mesma chave não há diferença de escadas, testemunha nem papel. | S:226 (ordem de preenchimento, sem cotas); S:221 ('Até 20 chaves por fôlego'); S:92 (H-07 'Tanto faz': se o `minPrice` for o lance mínimo, a lista do piso incha); S:290 (banco para 40 chaves, sem regra de quais). | Na 5.1, fixar cotas de partida (por exemplo 8 bolsas, 4 próprios, 4 piso, 4 giro, com a sobra redistribuída) e um conjunto de vigília: até 8 chaves fixadas no `Config.lua` ou com lote de papel aberto, que entram em todo fôlego antes das demais. Na H-07, trocar 'Tanto faz' por: a triagem do piso só usa chaves commodity até a S4 dizer o que é o `minPrice`. |
| V3B-05 | 7.2 (S:313); Ap. B (S:867) | importante | fato_errado | O filtro de isca usa salto relativo de 15% e uma 'janela' que o design não define. Em preço baixo o salto mínimo possível já passa de 15% (de 9 para 11 cobre são 22%), e em item com poucos leilões a cota de isca é 1 unidade: o mais barato legítimo vira isca. | Conta 6 (um tick só fica abaixo de 15% a partir de 7 ticks de preço); telas do próprio design com 9c, 13c, 25c e 3c (S:589-591, S:615); R9:65-73 (`N_ref`; `q_isca = max(1, f_isca · N_ref)`); S:323 (tick de 1 cobre ou de 1 prata). | Na 7.2, trocar a frase do filtro por: é isca o degrau cuja quantidade acumulada é até 5% da janela (janela = 15% da quantidade da escada, entre 5 e 2.000 unidades), seguido de salto de 15% ou mais e de pelo menos 3 ticks, olhando no máximo 3 degraus; o filtro só vale em commodity. Em item a frente é o menor arremate alheio. Repetir no Apêndice B. |
| V3B-06 | 7.2 (S:313); 9.2 (S:503) | importante | risco | A referência forte aceita commodity com 1 unidade de 1 dono e 5 leilões do mesmo vendedor; não exclui leilão próprio, de outro personagem da conta nem só de lance. O teto de 3 vezes a referência é medido contra ela mesma: um anúncio isolado e absurdo vira preço proposto dentro da faixa. | S:313 ('5 leilões ou mais, ou é commodity com escada completa'); S:503 (faixa até 3 vezes a referência); R9:177-183 (escada rasa, monopólio, leilão só de lance); R1a, estrutura `CommoditySearchResultInfo` (`containsAccountItem` booleano, sem quantidade); S:731 ('marca dado suspeito', sem efeito). | Na 7.2, redefinir forte: commodity com 5 unidades ou mais, de 2 donos ou mais, na janela; item com 5 arremates alheios de 3 donos distintos ou mais (contagem feita na hora da foto e gravada como número; se `owners` vier vazio, vale só o 5). Excluir leilão próprio, de conta e só de lance. Dado suspeito pelo Auctionator rebaixa a referência para fraca. |
| V3B-07 | 7.2 (S:313); 3.2 `venda_verdes`; 2.2 H-04 | importante | lacuna | A referência fraca não tem comportamento escrito, e as variantes do mesmo `itemID` não vêm da busca por chave. Verde de sufixo aleatório pode quase nunca ter 5 leilões da mesma chave (ninguém mediu): a única estratégia aprovada cairia em `NO REFERENCE`, sem tecla. O 'menor preço' do erro de postagem pode ser o do `itemID`. | S:313 (diz quando é fraca, não o que o addon faz); S:668 (linha `NO REFERENCE` sem tecla); R1b linha 225 (a tela da Blizzard busca equipamento com `SendSellSearchQuery`, chave sem nível e sem sufixo); base 1.11 e 2.15. | Na 7.2, escrever: com referência fraca a linha mostra `WEAK REFERENCE`, o mínimo e a mediana das variantes lidas do resumo, e não tem tecla. Em equipamento, o plano C lê também a escada do `itemID` por `SendSellSearchQuery`. Na 2.2, nova hipótese: o erro de postagem compara com o menor preço da chave ou do `itemID` (S3). Na onda 2, medir a fração dos verdes das bolsas com referência forte. |
| V3B-08 | 7.1 (S:307); 7.4 (S:366); 11.3 (S:625) | importante | contradicao_interna | A regra de cancelar `Δ_canc` foi adotada, mas depende de P(venda) do leilão ativo e de `W*`, que o mesmo parágrafo deixa fora ou em sombra. A visão Mine mostra `CANCEL +36c if reposted` sem haver estimador que produza o número. | R9:556-562 (`Δ_canc = P·(W* − p·(1−c)) + ...`); S:307 ('Tabela de P(venda) ... ficam fora das fases 1 e 2'; '`W*` (4.1) fica em sombra'); S:625 e S:671 (conselho com ganho esperado). | Na 7.4, trocar o item 'Cancelar' por: o addon não calcula ganho de cancelar. Mostra fatos lidos: unidades na frente, tempo restante, depósito que se perde e teclas do ciclo; o conselho é `KEEP`, `LET EXPIRE` ou `STAND DOWN`. `Δ_canc` vai para a lista de sombra da 3.3. Nas telas da 11.3 e no fluxo C, trocar `CANCEL +36c if reposted` por `340 ahead, 6h left`. |
| V3B-09 | 7.4 (S:361); regra 17 (S:47); 3.3 | importante | fato_errado | A saída 'líquida de um depósito' não é calculável para item que o dono ainda não tem: `CalculateItemDeposit` só aceita item que está na bolsa, e a regra 17 proíbe fórmula. O teste de compra do `sniper` em item e o papel ficam sem o custo do depósito. | R1a função 2 (`CalculateItemDeposit(item ItemLocation, duration, quantity)`) contra função 1 (`CalculateCommodityDeposit(itemID, ...)`); S:47 ('Depósito sempre lido'); S:361. | Na regra 17, acrescentar a exceção: para item que não está na bolsa, o depósito é estimado pela razão entre depósito e preço de vendedor medida no diário (linha 'Depósito' da 7.6, por duração), aparece marcado `est.` e não autoriza compra acima do lote de confirmação. Na S0, conferir se `CalculateCommodityDeposit` responde para item que não é commodity. |
| V3B-10 | 7.2 (S:332-334); 7.6 (S:384) | importante | risco | O veredito `AUCTION` compara `P*` com uma frequência de 10 desfechos por 'classe' e duração. Quatro em dez tem intervalo de 17% a 69%. 'Classe' não está definida, a frequência ignora a fila na frente, e o desfecho de lote cancelado ou vendido em parte não tem regra. | Conta 2 (Wilson a 95%: 4 de 10 dá 0,17 a 0,69; 12 de 30 dá 0,25 a 0,58); S:332 ('por classe e duração'); S:384 (grava 'fila na frente' e não a usa); R9:1423 (incógnita 8, venda parcial de lote). | Na 7.2, trocar o veredito: `AUCTION` só quando o limite inferior do intervalo de 90% da frequência supera `P*`; senão `YOUR CALL`, com a contagem. Definir classe (equipamento por qualidade; commodity) e desfecho (vendeu ou expirou; cancelado pelo dono fica fora; commodity conta por unidade). Mostrar na linha a fila na frente do candidato (`ahead 340`). |
| V3B-11 | 3.3 (S:149); 7.1 (S:307) | importante | contradicao_interna | A comparação de regras em sombra é torta: a regra escolhida tem o desfecho visto nas 24 horas; a hipotética, só nas janelas com foto. E `W*` em sombra pede a tabela de P(venda), que o design deixou fora. Com 50 desfechos o dono decidiria sobre evidência inclinada a favor do que já faz. | S:149; S:307 ('Tabela de P(venda) ... ficam fora'); R9:507-512 (`W` usa `P = P̄(n)` da seção 3); conta 9 (4% a 12% do dia observado). | Na 3.3, reescrever o parágrafo da sombra: o desfecho hipotético tem três valores, 'venderia' (a regra real, de prioridade pior, vendeu, ou houve venda observada com prioridade pior), 'não venderia' (a regra real, de prioridade melhor, não vendeu) e 'desconhecido'. Só os dois primeiros entram na comparação. `W*` sai da sombra das fases 1 e 2 e vai para a fase 3. |
| V3B-12 | 7.4 (S:363) | importante | lacuna | 'Bordas lentas' pede a vida das ofertas por faixa de desconto. Fotos a minutos de distância não medem vida de segundos, e a oferta já vista é a que durou. Há impasse: o sinal só aparece com a vida medida, e a vida só se mede com sinais. Faixas e limiar não existem. | S:363; D1 linhas 324 e 363 (sobrevivência acima de 0,5, pela foto seguinte); R9:1014 ('não se distingue reação mais rápida que Δ'); S:385 (o 'já sumiu' da releitura mede a sobrevivência no tempo de reação e não é ligado a esta regra). | Na 7.4, trocar o item por: a sobrevivência é a fração de sinais ainda presentes na releitura da tecla `B`, em 3 faixas de desconto (até 10%, de 10% a 30%, acima de 30%). Em papel o sinal sempre aparece. Em micro, a faixa só gera sinal executável com 15 releituras ou mais e sobrevivência acima de 0,5. Incluir os números no Apêndice B. |
| V3B-13 | 7.4 (S:365); 9.3 (S:512); 5.3 e 6 (S:258, S:277); 3.2 (S:135) | importante | contradicao_interna | A deriva pede resumos separados por 6 horas, mas o banco guarda só o último resumo e um mínimo por dia, que cai com o número de resumos e inclui o leilão do próprio dono. Ela 'entra como custo de carregar', mas o `EV` da 7.4 não tem o termo. O bloco de 4 horas da 3.2 não existe no banco. | S:258 e S:277 (`dias` = 'dia:min:qtd'); S:354-356 (`EV` sem termo de deriva); S:135 (bloco de 4 horas); R1a, estrutura `BrowseResultInfo` (`containsOwnerItem`, sem separar o próprio); D1 linha 314 (a fórmula que não veio). | Na 5.3 e na 6, trocar `dias` por blocos de 4 h (último mínimo e quantidade do bloco, 6 por dia) e excluir chave com `containsOwnerItem`. Na 7.4, definir: deriva = mediana, por classe de item, da variação do mínimo entre o mesmo bloco de dois dias seguidos, com 30 chaves ou mais. Ela só suspende compra (9.3); tirar 'entra como custo de carregar'. Refazer a conta de tamanho. |
| V3B-14 | 9.3 (S:511); 7.4 (S:364) | importante | lacuna | 'Parede' e 'oferta funda' (guarda de regime) não têm número. No R9 as duas dependem da taxa de venda, que a coleta mal estima; em item, 'poucos donos' pede identidade. Como estão, são regras que o implementador terá de inventar. | S:511 ('degrau grande, de poucos donos'); S:364; R9:1031 (`q_j ≥ max(k_wall·λ·H_ref, f_wall·N_ref)` e `n_j ≤ 2`); R9:640 (`k_crash·λ·H_ref`); Apêndice B sem nenhum dos dois. | Na 9.3, definir parede sem taxa: degrau de commodity com 25% ou mais da quantidade da escada e até 2 donos; em item não se marca parede. Na 7.4, definir a guarda de regime: se depois da compra ainda sobra, abaixo do preço de entrada, mais que 3 vezes o lote, compra-se só o lote de confirmação. Incluir os números no Apêndice B como escolha de projeto a calibrar. |
| V3B-15 | 5.2 (S:239); 5.3; 2.2 | importante | lacuna | O design não tem hipótese sobre paginação e ordem da resposta de busca. A API tem 'mais resultados' para commodity e para item. Se a escada longa vier em páginas e 'parcial' não atualizar nada, as commodities mais líquidas nunca terão foto válida; se a ordem não for por preço, os 12 degraus não são a frente. | R1a funções 57, 58, 75 e 76 (`HasFull...SearchResults`, `RequestMore...SearchResults`); R1b linhas 88 e 229 (lista de commodity sem ordenação; a tela pede mais ao rolar); R9:1420 (incógnita 5); S:239. | Na 2.2, nova hipótese: a primeira resposta de uma busca vem em ordem crescente de preço e traz ao menos os 12 primeiros degraus (S5). Na 5.3, definir duas marcas: 'frente completa' (primeira página recebida e em ordem: vale para referência, fila e fronteira) e 'escada completa' (`HasFull...` verdadeiro: vale para quantidade total e baldes). Sem a primeira, a foto não atualiza nada. |
| V3B-16 | 3.2 `piso` (S:130); 3.3 (S:144); 17, ondas 2 e 4 | importante | lacuna | A prova do `piso` ('cobre disponível abaixo do vendedor por varredura', 'três varreduras') não sai do resumo: ele dá o mínimo e a quantidade total da chave, não a quantidade abaixo do preço de vendedor. Só as escadas lidas dão o número, até 20 por fôlego. 'Varredura' não está definida. | Base 2.1 e R1a, estrutura `BrowseResultInfo` (`minPrice`, `totalQuantity`); S:130 (sinal mensurável do `piso`); S:144 e S:794 (três varreduras, dobro do tíquete); S:221 (20 chaves). | Na 3.3, definir: uma varredura de prova é um fôlego com resumo completo; o valor é a soma de `(v − p_j) · q_j` só das escadas lidas nesse fôlego, dividida pelas teclas; o relatório mostra também quantas chaves marcadas ficaram sem leitura. 'Horários diferentes' são blocos de 4 horas distintos. Chave que não é commodity só entra depois da S4 (H-07). |
| V3B-17 | Ap. B (S:853-876); 7.5 (S:370); 7.6; 9.2 (S:501); 12 (S:708) | importante | lacuna | O Apêndice B não traz a faixa de nenhum valor, embora o `Calibrado.lua` valide por faixa e o texto mande ajustar 'dentro da faixa do R9 12-C', que a sessão de implementação não terá. Mais de vinte parâmetros usados no texto não estão na tabela, e quatro aparecem com dois valores. | S:305 e S:708; item 6 deste parecer (lista completa); S:299 e S:876 contra S:690 (45 ou 50 minutos); S:135 contra S:277; S:388 (cobre em linha de segundos); S:370 (`T_caixa` sem definição); S:501 (volume diário sem estimador). | No Apêndice B, acrescentar as colunas 'unidade', 'faixa' e 'como calibrar', e as linhas da tabela 6.1 do parecer. Unificar a sugestão de salvar em 45 min ou 50 ações (corrigir a 11.5). Na 7.5, definir `T_caixa` como o atraso medido do correio e tirá-lo da ordem enquanto for constante. Na 9.2, definir o teto de volume como 10% das vendas inferidas na exposição observada do dia; sem 2 h de exposição, só o lote de confirmação. |
| V3B-18 | regra 20 (S:50); 5.3 (S:263); conflito 15 (S:926) | menor | melhoria | Abrir mão de toda identidade de vendedor tira do motor o casamento de repostagem em item, a calibração de `π_cf`, a concentração e o tempo de reação por rival. Uma contagem de donos distintos e uma assinatura curta com sal por sessão recuperam quase tudo sem gravar nome. O design não considera a alternativa. | R9:248 e R9:347 (critérios que usam o nome); R9:1003-1004 e R9:1076; conta 8 (16 bits: 55 personagens por valor; colisão de 1,9% entre 50 vendedores); S:926. | Na 5.3, acrescentar: de `owners` grava-se só a contagem de donos distintos da foto. Na 18, criar decisão do dono: permitir, na fase 2, assinatura numérica de 16 bits com sal sorteado por sessão e não gravado, usada só para casar o mesmo vendedor entre fotos da sessão. Ajustar a regra 20 para 'nome de jogador nunca é gravado nem mostrado'. |
| V3B-19 | 7.6 (S:381); 11.3 (S:626); 2.2 | menor | lacuna | O atraso do correio é medido do aviso de venda até a fatura, mas o addon só vê a fatura quando o dono abre a caixa: mede a ida ao correio. A tela Mine já mostra `gold arrives in about 41 min`, que depende do `timeLeftSeconds` do leilão vendido, sem hipótese registrada. | S:381; S:626; R1b seção 10, linha 297, e incógnita 17 ('Para vendidos, `timeLeftSeconds` é o tempo até o pagamento chegar', não conferido no jogo). | Na 2.2, nova hipótese: o `timeLeftSeconds` de um leilão com estado Sold é o tempo até o ouro chegar (S7). Na 7.6, trocar o sinal do atraso do correio por: `timeLeftSeconds` do leilão vendido na primeira leitura depois do aviso, mais o tempo decorrido desde o aviso; a hora da fatura fica como limite superior. |
| V3B-20 | 9.3 (S:510); Ap. B (S:875) | menor | lacuna | O G2 conta 'coberto 2 vezes em menos de 10 minutos', mas a cobertura só é vista numa foto: a resolução é o intervalo entre fôlegos. E, se o item cancelado volta pelo correio (H-10), o ciclo cancelar, receber e repostar não cabe em 10 minutos: a regra raramente dispara. | S:510; R9:1014 ('é preciso Δ ≤ R_fast/2'); S:95 (H-10); S:240 (o fôlego acaba e nada mais consulta). | Na 9.3, reescrever o G2: conta-se uma cobertura quando uma foto mostra oferta alheia nova abaixo do leilão próprio, com a hora da foto. Duas coberturas de postagens próprias do mesmo item em 60 minutos, cada uma vista até 10 minutos depois da postagem, tiram o `cobrir` e abrem a trégua. Atualizar a linha 'Antiguerra' do Apêndice B. |
