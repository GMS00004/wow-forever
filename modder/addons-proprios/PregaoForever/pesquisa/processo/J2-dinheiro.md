> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# J2-dinheiro: parecer pela lente "ouro de verdade"

Data: 2026-11-16. Juiz J2. Li a base de fatos inteira e os seis projetos por inteiro; conferi citações no espelho da Blizzard e nos relatórios R1a, R1b, R1c, R4a, R4b, R5a, R5b, R6a, R8a, R8b e R9. Não li código de addon de terceiros.

Pergunta da lente: com 5 ouro, nível baixo, mega-reino e concorrentes com ferramenta, que projeto põe mais ouro por hora de atenção na mão do dono, com que evidência e em quanto tempo.

## 0. O que os fatos dizem antes de julgar

Três fatos pesam em todas as notas de lucro.

1. **Nenhum projeto tem evidência de ouro.** A base não tem medida de lucro de leilão com banca pequena no Forever (base 6.5; R5b 2c só traz estimativa de farm de quem vende ouro). Por isso julgo cada projeto por quanto custa e quanto demora para ele *produzir* a evidência, e não pelo que promete.
2. **Com 5 ouro o que aperta é capital e giro, não tecla nem modelo.** Um giro completo da banca a 10% a 15% de margem rende 50 a 75 prata, e o ouro de cada venda volta pelo correio em cerca de 1 hora (base 1.8). Os próprios projetos fazem essa conta: D1 chega a 25 prata por dia "se tudo acertar" (§1.2), D2 a 50 prata por giro (§1.2), D4 a 1% da banca por giro (§1), D6 a 45 prata por dia (§1). Nessa escala, o ouro vem de vender bem o que quatro coletores produzem; a compra para revenda é complemento até a banca crescer.
3. **A faixa do dono não está em queda.** A base 6.1 resume "mediana caiu 41%, 34 de 46 materiais baixaram". O relatório por trás (R5b 2a) mostra que os materiais de nível baixo subiram na mesma semana: Copper Ore +41%, Copper Bar +93%, Peacebloom +80%, Light Leather +19%. E listam bem acima do vendedor: Copper Ore cerca de 13 vezes, Light Leather 3,6 vezes, Linen Cloth 2,3 vezes (R5b 2b, valores de vendedor da beta, a conferir). Duas consequências: supor deflação geral é erro para este dono, e anúncio de material abaixo do preço de vendedor deve ser raro.

## 1. Notas

| Projeto | Viabilidade | Lucro | Aderência | Risco | Testabilidade |
|---|---|---|---|---|---|
| D1-quant | 6 | 4 | 6 | 7 | 8 |
| D2-operador | 7 | 6 | 8 | 6 | 8 |
| D3-mesa | 5 | 3 | 6 | 7 | 7 |
| D4-risco | 7 | 5 | 8 | 9 | 9 |
| D5-ouro | 8 | 8 | 8 | 7 | 8 |
| D6-concorrencia | 5 | 5 | 6 | 7 | 7 |

Em risco, nota alta quer dizer que o projeto se protege bem.

### D1-quant

- **Viabilidade 6.** Cabe na API e cita certo, mas são 30 arquivos, uma mesa e mais de cem parâmetros sobre um R9 sem revisor (§1.4, §11 risco 4). A inferência de vendas depende de a primeira página da escada vir ordenada e completa (`[H-04]`, §3.4), que ninguém mediu.
- **Lucro 4.** O próprio projeto diz que na fase 1 "o ouro novo vem do personagem, não do pregão" (§1.2). A tecla de vender só chega na onda 3, depois do motor puro e da mesa; a primeira compra, na onda 5, depois de cinco sessões de sombra (§9). E o motor se cala no que a única fonte aprovada manda vender: verde aparece como `NO DATA` e não é postado (§1.4, §6.3 tela SELL, §7.3).
- **Aderência 6.** Regras 1, 3 e 8 bem cumpridas. A tela é a mais carregada das seis (colunas `gain`, `chance`, `data`, painel WHY, §6.3), com 12 teclas. A tecla `C` pega correio por código (§6.2), o que encosta na decisão do dono de 2026-11-06 (base 4.6), embora venha como decisão D6. A exploração `TEST` (§4.3 item 5) gasta ouro do dono em experimento sem fonte.
- **Risco 7.** Portões G0 a G5, duas chaves por estratégia, estado `INCERTO` que bloqueia, `LEDGER MISMATCH` que suspende compra (§4.6, §3.5, §6.4). O risco que sobra é de modelo: erro de sinal produz recomendação confiante e errada (§11 risco 4).
- **Testabilidade 8.** Propriedades do motor puro, simulação de recuperação e portões com número (§8.1, §4.3 item 7, §4.6). A prova, porém, leva semanas de desfechos reais (§9, nota final).

### D2-operador

- **Viabilidade 7.** Arquitetura enxuta, um arquivo que age, checador claro (§3.3). A meta de 6 a 10 ações por minuto (§1.2) depende de um throttle cuja cadência é incógnita (base 2.14) e de a tecla ligada ao `OpenAllMail` da Blizzard funcionar sem taint (§6.4 D), ambos marcados `[H]`.
- **Lucro 6.** É o melhor em custo de atenção na renda certa: um cartão por pilha, uma tecla por postagem, uma tecla para o correio, POST sem teto por volta (§6.5). A fase 1 já tem venda e arbitragem de vendedor (§2). Perde pontos porque otimiza a tecla quando o que aperta é o capital: com 10% por ação e 75% de exposição (§7.2), a banca se esgota em menos de 8 compras e só volta com o correio. O próprio projeto admite (§11 risco 2).
- **Aderência 8.** A tela mais limpa: uma zona de estado, um cartão de 3 linhas, lista de 5 (§6.3). É o mais rigoroso na regra 3: reconhece que o `W*` do R9 não tem fonte pública e o deixa em sombra até vencer a regra com fonte (§5, item c). Melhores adaptações remotas: `T_ver` com latência, cabeça da fila fixa, disjuntor de tecla presa, cursor estacionado como plano B (§3.4, §6.6, §6.2).
- **Risco 6.** Guardas conferidas ao criar o cartão e de novo na tecla (§7.1), primeira semana com exposição de até 1 ouro (§8). Mas compra de item sai em 1 tecla e a interface rápida multiplica erro de um motor sem revisão (§11 risco 3).
- **Testabilidade 8.** Casos de operador com teclas patológicas, seis invariantes, 200 rodadas aleatórias, quadros em HTML para o dono e modo treino antes de ouro (§8).

### D3-mesa

- **Viabilidade 5.** Dois programas, um vigia no Avell, quatro arquivos gerados, contrato com recibo e sentinela, sync por `/reload` a cada 30 a 40 minutos e sync duplo na abertura (§3.1, §3.6, §3.7). Tudo depende de S6 (gravação confiável, tempo de reload, a casa fechar ou não), que é hipótese.
- **Lucro 3.** A fase 1 não tem tecla de ação e pede sete dias de fotos antes do portão (§2, §8 critério de aceite); postar por tecla só na onda 4, comprar na onda 5 depois de 30 sinais em sombra (§9). O ritual de reload é atenção gasta sem ouro. O que salva é a qualidade da decisão entre sessões (pauta, mapa do que cabe no bolso, §3.8).
- **Aderência 6.** Leva a regra 4 adiante com coerência (configuração e inteligência por arquivo). Mas impõe um ritual pesado numa sessão remota, um processo vigia permanente e a tecla `M` no botão da Blizzard (§3.4).
- **Risco 7.** Modos `DESK OK`, `DESK STALE`, `NO DESK` (§3.6), cotação acima do total mostrado recusa (§3.4), hash em vez de nome de vendedor (§3.6). Risco próprio: arquivo velho lido como novo (§11 risco 5).
- **Testabilidade 7.** Bandeira de hardware na bancada, teste de ida e volta entre Lua e Node, replay determinístico, ficha de evidência por estratégia (§8, §3.8). A prova só começa depois de uma semana de dados.

### D4-risco

- **Viabilidade 7.** Cabe na API e é o que menos supõe: onde a base diz "não se sabe", age como se não pudesse (§3.1). Ponto fraco: a conciliação do Cofre depende de mecânicas de correio ainda não medidas (§11 risco 4).
- **Lucro 5.** Protege os 5 ouro melhor que todos e tem venda e vendedor em micro cedo. Mas cobra duas teclas por ação até para postar e cancelar (§3.5), começa com até 5 leilões ativos (§5 E1), limita a ordem a 2% da banca (§7.2) e passa semanas em papel. O projeto admite que "pode não fazer quase nada" (§11 risco 1).
- **Aderência 8.** A conformidade mais forte: correio só por leitura, nada de clique em botão da Blizzard, nível só desce dentro do jogo, tudo por arquivo (§7.6, I7). Custa atenção: o dobro de teclas numa sessão remota.
- **Risco 9.** Cofre, tetos como constantes, nove disjuntores, lote de confirmação, classes de saída, `INCERTO` sem reenvio (§7, §5 E2, §4.3, §3.5). É a referência.
- **Testabilidade 9.** Sete invariantes conferidos por checador e por 10.000 roteiros aleatórios, portões papel, micro e plena com número (§3.1, §8.1, §5).

### D5-ouro

- **Viabilidade 8.** O menor escopo: sem mesa, sem varredura completa, uma consulta resumida e até 20 escadas por tecla (§3.2). As contas conferem (§4.2: `P*` de 42% hoje e 18% depois de 17/11, refiz). Ponto fraco: calendário de cinco dias para 21 módulos, bancada e três checadores (§9) e a suposição de que postar pelo Auctionator funciona no Forever.
- **Lucro 8.** É o único que põe ouro na mão antes de existir addon (onda 0, §9) e o único que mede o que as ferramentas prontas rendem para decidir entre adotar e construir (§1.2, decisão 3). Ordena por tempo até o dinheiro voltar e cobre por tecla (§1.1, §4.2), que é a restrição real com 5 ouro. Cada onda tem resultado medido e critério de parada (§9). Não é 10 porque o teto é cobre e prata e porque a estratégia de entrada (piso) provavelmente rende pouco.
- **Aderência 8.** Quatro teclas vizinhas sem modificador, telas simples, correio só lido, venda ao vendedor por clique do dono (§6, §7). Ressalva: uma tecla modal (F6) compra, posta e cancela conforme a linha em destaque.
- **Risco 7.** Ficha de tecla, foto fresca, teto de cotação mais duro que o da Blizzard, lote de sondagem de 2%, disjuntores (§7). Menos rigor que o D4: frações fixas, perda diária de 10% abaixo de 15 ouro (§4.3) e priors de P sem fonte (declarados).
- **Testabilidade 8.** Bancada com marcador de tecla, `checar-acoes.mjs` com alcance de chamadas, replay, sonda na ordem da base 11 e critérios de morte numéricos por onda (§8, §9).

### D6-concorrencia

- **Viabilidade 5.** O produto central depende de `owners` vir preenchido (base 11.5) e de fotos a cada 5 minutos, cada rodada pedida por tecla (§4.2 C). Em commodity, degrau com vários donos vira "assinatura" (§4.2 B). O projeto diz que S3 "decide o valor deste projeto" (§8).
- **Lucro 5.** A tese de terreno é a teoria de vantagem mais plausível para um humano lento entre concorrentes com ferramenta, e as regras antiguerra poupam depósito e tecla (§4.4). Mas antes do ouro vem muita atenção gasta em observar (20 nichos com ficha e 3 postagens-sonda para o aceite da fase 1, §8), a compra só liga depois de 30 sinais em sombra, e os mercados de material de nível baixo tendem a sair como `AVOID`.
- **Aderência 6.** A tela de nicho é a mais densa (escada, rivais com nome, matriz de horas, plano, §6.2). Guarda nomes de jogadores (decisão 5). O E7 alterna tipos de passo de preço com os itens do dono, o que precisa de aprovação explícita.
- **Risco 7.** Nove vetos com motivo, G1 a G5, cadência humana, tetos (§4.3, §4.4, §7). Contra: 25% da banca por nicho (§4.6) concentra demais com 5 ouro.
- **Testabilidade 7.** Mercado sintético com agentes plantados e metas numéricas de aceite (§8). O replay não avalia outra cadência nem a reação dos outros (§8), e tudo cai se S3 for negativa.

## 2. Afirmações de fato conferidas contra a base

Conferi e batem: as linhas do espelho citadas por D2, D3, D4, D5 e D6 (`Blizzard_AuctionHouseBuyDialog.lua:3`, `MailFrame.xml:444`, `MailFrame.lua:271`, `:576`, `:790`, `:1632`, `Blizzard_AuctionHouseUtil.lua:391-400`, `Blizzard_AuctionHouseTableBuilder.lua:1095` e `:1144`); as funções e eventos do R1a (`IsSellItemValid` 63, `SearchForItemKeys` 79, `CancelSell`, evento 10, enum de erros); o terceiro argumento de `StartCommoditiesPurchase` (R1b 4); os números do R9 (6.270 entradas, erro 0,27, Kelly 0,25 com 0,8%, 640 bytes, custos de 4, 3 e 3 segundos); as citações do R4b (Espaço no Auctionator, equipamento fabricado BoP, couro do Hexumlite) e os códigos R4 a R15 do R8b. As contas de tamanho das SavedVariables dos seis fecham.

Contradições, contas que não fecham e fatos sem lastro:

| # | Projeto e seção | Problema | Referência |
|---|---|---|---|
| 1 | D1 §4.1, D2 §4.1 e §4.3, D4 §4.3, D6 §4.5 | Adotam a regra de compra do R9 5.1 com `η_real` = 0,5 multiplicando a saída inteira (`EV = η_real·n·U_lcb − custo`). Assim só passa compra cuja saída conservadora vale mais que o dobro do custo: flip e sniper nunca disparam, nem em sombra. O D3 demonstra o defeito e corrige. | R9 5.1 (linhas 607 e 625); D3 §4 |
| 2 | D6 §4.3 contra §4.5 | No índice `IT` o `η_real` multiplica o ganho; na regra de compra multiplica a saída. As duas contas do mesmo projeto não concordam. | R9 5.1 e 5.7 |
| 3 | D4 §1 e §4.2 | "Cerca de 7% por dia composto" e "parte devendo perto de 12%" viram premissa de `H_max` 24 h e `μ_min` 0,15. A base manda tratar a queda como direção (preço listado, sites que vendem ouro), e o R5b 2a mostra os materiais de nível baixo subindo na mesma semana. | base 6.1; R5b 2a |
| 4 | D6 §4.6 | `H_max` 24 h justificado por "preço listado em queda": mesma generalização do item 3. | base 6.1; R5b 2a |
| 5 | D5 §1.2 e §9 (onda 0) | "Postar e cancelar: adotar hoje" pelo Auctionator, sem marca de hipótese. A base só diz que ele roda e oferece preço por API; não há postagem registrada, e o R4b lista como incógnita se a tela de leilão dele abre no Forever. | base 7.1, 4.3; R4b incógnita 1 |
| 6 | D3 §7 (guarda Banca) | A banca soma o ouro dos quatro personagens pelo Syndicator. Não há banco de conta: os tetos seriam calculados sobre ouro que o negociador não alcança. | base 4.1, 4.2 |
| 7 | D4 §3.4 contra §6.2 | Teto de 30 buscas exatas por minuto e fôlego de 40 buscas dão pelo menos 80 segundos; a tela promete "40 items, about 30 s". | D4 §7.2 |
| 8 | D6 §11 risco 5 | "O ForeverFlip já cancela quando coberto, base 5.2": a base só diz "cancelamento". O detalhe existe, mas no R6a. Citação errada, fato com lastro. | base 5.2; R6a (linha 87) |
| 9 | D5 §11 risco 1 | "O ForeverFlip tem ofertas de vendedor" sem citação. Tem lastro no R6a ("deals (vendor e resale)"). | R6a (linha 87) |
| 10 | D4 §5 E1 | Atribui à base 4.5 a decisão "o couro do Hexumlite segue o roteiro de Leatherworking". A base 4.5 só diz que não vale vender todo o couro; a decisão está no R4b 4. | base 4.5; R4b 4 |
| 11 | D5 §3.3 e §6.3 C, D3 §3.4 | Tratam como fato que o item cancelado volta pelo correio. A base só dá o assunto "Auction canceled"; D1, D2, D4 e D6 marcam como hipótese. | base 1.8 |
| 12 | D2 §1.2 | Meta de 6 a 10 ações por minuto contra 1 a 2 no UI padrão: marcada `[H]`, mas sustenta a tese sem nenhuma medida, e os tetos do próprio projeto tornam a tecla um limite frouxo com 5 ouro. | base 2.14, 1.8; D2 §7.2 |
| 13 | D5 §4.3, D4 §4.1 | P de venda de 0,25, 0,45 e 0,65 (D5) e `η_P` de 0,5 (D4) são números sem fonte que decidem "leilão ou vendedor". Ambos declaram; o D5 atenua mostrando o `P*` de equilíbrio. | base 6.5 |
| 14 | D5 §5 E1 | A condição de ligar o piso ("pelo menos 30 cobre disponíveis" por varredura) vale duas teclas do próprio tíquete de 15 cobre. O que decide de fato é o critério de parada da onda 3. | D5 §4.3, §9 |

Não achei fato de jogo inventado sem marca além dos itens 5 e 11. Os seis são disciplinados na regra 8.

## 3. Defeito mais grave e enxertos

### D1-quant
**Defeito mais grave.** O primeiro ouro fica a semanas, e o motor se cala justamente no que a única fonte aprovada manda vender: verde sai como `NO DATA` (§1.4, §7.3). Soma-se o item 1 da tabela acima.

**Enxertos.**
1. Preço-sombra do capital (§4.3 item 3): ordenar por retorno de capital-hora com banca pequena e voltar a valor por tecla quando sobrar caixa. É a ordenação certa para 5 ouro.
2. Deriva por categoria medida no painel (§4.3 item 1), entrando no custo de carregar. Mede em vez de supor queda geral (ver item 3 da tabela).
3. Duas testemunhas (§4.3 item 4): só executar compra cuja saída tem venda inferida recente naquele preço. Ataca "preço listado não é preço vendido".
4. Só bordas lentas (§4.3 item 6): mostrar sinal apenas se a oferta sobrevive ao tempo de reação medido do dono.
5. Portões G0 a G5 com condição numérica e duas chaves por estratégia (§4.6, §3.7).
6. Motor em arquivos puros, sem global do jogo (§3.2), para a bancada e o replay rodarem o mesmo código.

### D2-operador
**Defeito mais grave.** Otimiza a tecla quando o que aperta é capital e giro; a meta de vazão não tem medida, e a interface rápida multiplica o erro de um motor sem revisão (§1.2, §7.2, §11 riscos 2 e 3).

**Enxertos.**
1. Modo treino (§2, §8): cartão real em que a tecla só registra. Mede cartões bons por hora e taxa de "já sumiu" antes de qualquer ouro.
2. Modelo do operador (§4.2): `T_dec` e `T_resp` por tipo de cartão no diário, e o custo da tecla sai do medido.
3. Guardas de dedo remoto (§3.4, §6.6): `T_ver` com latência do `Config.lua`, cabeça da fila que não troca sozinha, disjuntor de 6 teclas em 2 segundos.
4. `W*` só em sombra até vencer a regra com fonte, gravando o desfecho hipotético das regras não escolhidas (§5, itens b e c). É a leitura mais fiel da regra 3.
5. Quadros em HTML gerados pela bancada para o dono aprovar as telas (§8).
6. Ritmo de volta: cancelamentos agrupados no fim da perna do leilão e POST sem teto, porque é o que libera capital (§6.5).

### D3-mesa
**Defeito mais grave.** Fase 1 sem tecla de ação por pelo menos sete dias, mais um ritual de `/reload` a cada 30 a 40 minutos com vigia: o maior custo de atenção por ouro dos seis (§2, §3.7).

**Enxertos.**
1. `η_real` descontando o ganho e não a saída (§4, linha "5.1 Lugar do desconto"). Sem isso a compra do R9 não funciona.
2. Separação de quem troca o quê (§4, diário): fato do jogo a ferramenta troca sozinha; teto, margem e estratégia só o dono.
3. Contrato com recibo, sentinela e modos `DESK OK`, `STALE`, `NO DESK` (§3.6), para adotar quando a mesa existir.
4. Pauta do dia, ficha de evidência por estratégia e autópsia de lote perdedor no relatório de sessão (§3.8).
5. Sniper por nomeação (§4, linha 5.2): gatilho barato no resumo, uma busca, teste completo antes de armar a tecla.
6. Hash em vez de nome de vendedor (§3.6), se algum dia houver perfil de concorrente.

### D4-risco
**Defeito mais grave.** Pode não fazer quase nada: duas teclas até para postar, micro de 2% por ordem, e a regra de compra do item 1 da tabela. O ouro por hora de atenção fica perto de zero até a banca crescer por fora.

**Enxertos.**
1. Cofre (§7.1): banca é o `GetMoney` de quem negocia menos um piso pessoal, com estados do ouro (livre, estoque, depósito em risco, correio, cotação).
2. Lote de confirmação de 1 unidade por item na arbitragem de vendedor (§5 E2): prova o preço de vendedor antes do lote maior.
3. Invariantes I1 a I7 conferidos por checador e por 10.000 roteiros aleatórios (§3.1, §8.1, §8.3).
4. Classes de saída A, B e C (§4.3): classe C nunca vira sinal.
5. Tetos de depósito em risco e de depósito perdido no dia, e teto de cancelamentos por item (§7.2).
6. Nível só desce dentro do jogo; subir é edição de arquivo, com papel, micro e plena (§3.1 I7, §5).

### D5-ouro
**Defeito mais grave.** Teto baixo e entrada frágil: o piso de vendedor provavelmente já está varrido e rende cobre, o calendário é otimista, e a fatia fina não coleta o dado que o motor vai pedir quando a banca crescer (§11 riscos 1 e 4).

**Enxertos.**
1. Régua agnóstica de ferramenta (§1.1, §1.2): cobre por tecla, por hora e voltas do capital, por estratégia, medindo também o que o dono faz pelo Auctionator ou pela tela da Blizzard.
2. `P*` em palavras, `needs 18%` (§4.2): mostra a chance de equilíbrio em vez de afirmar uma probabilidade sem fonte.
3. Ondas com "resultado medido" e "para se" (§9): critério de morte numérico por onda.
4. Onda 0 sem código pelos comandos do R1b 16, e releitura do depósito depois da manutenção de 17/11 (§9, §4.2).
5. Triagem estática do `ItemSparse` com preço de vendedor confirmado ao vivo, uma tecla por varredura (§3.1, §3.3).
6. `checar-acoes.mjs` com alcance de chamadas e ficha de tecla consumida na primeira chamada restrita (§8, §3.3).

### D6-concorrencia
**Defeito mais grave.** O valor inteiro depende de `owners` vir preenchido e de fotos a cada 5 minutos pedidas por tecla; antes disso é muita atenção em observar e pouco ouro (§8 S3, §11 riscos 1 e 2).

**Enxertos.**
1. Triagem barata pelo resumo (§4.2 A): `saida · minimo / (1 + k_t · tremor)` para escolher o foco sem gastar busca.
2. Antiguerra G1 e G2 (§4.4): no máximo 2 cancelamentos com repostagem por item em 4 horas, e trégua ao ser coberto duas vezes pelo mesmo vendedor.
3. Postagem-sonda de 1 unidade (§4.2 C): evidência de cobertura pelo custo de um depósito.
4. Vetos com motivo em uma frase (§4.3): a lista `AVOID` diz onde não gastar depósito.
5. E7 (§5): medir igualar, 1 cobre e folga pelos próprios desfechos, com aprovação do dono.
6. Lote `n*` do tamanho da demanda enquanto na frente, em vez do estoque inteiro (§4.4).

## 4. Ordem pela lente

1. **D5-ouro.** Evidência mais cedo e mais barata; ouro na mão antes do addon; mede se vale construir.
2. **D2-operador.** Menor custo de atenção na renda certa (vender o próprio estoque) e modo treino antes de ouro.
3. **D4-risco.** Pouco ouro, mas é o único que garante não perder a banca; a evidência por papel, micro e plena é a mais sólida.
4. **D6-concorrencia.** A tese mais plausível de onde está a vantagem, presa a uma incógnita e cara em atenção.
5. **D1-quant.** O motor mais completo e as melhores ideias de dinheiro (capital-hora, deriva, duas testemunhas), semanas longe do ouro.
6. **D3-mesa.** A mesma demora do D1, sem tecla na fase 1 e com o ritual mais caro.

Tempo até o primeiro ouro por tecla do addon, pelos planos de cada um: D5 em dias (onda 4; hoje mesmo sem addon); D2 depois de três sessões de treino (onda 5); D4, D6 e D1 na terceira onda, com compra só depois de semanas de papel ou sombra; D3 depois de sete dias de fotos (onda 4).

## 5. Espinha recomendada para a síntese

**Base: D5.** Fatia fina de régua mais fila, sem aplicativo companheiro na fase 1, ondas com resultado medido e critério de parada, marcos de banca (15 e 60 ouro) para abrir profundidade.

**O que entra de cada um.**
- **D4**: o Cofre e os invariantes I1 a I7 como contrato do arquivo que age; lote de confirmação; classes de saída; tetos de depósito. É a camada de risco da espinha.
- **D2**: o cartão como unidade de tela, as guardas de dedo remoto, o modo treino, o modelo do operador e a regra "`W*` em sombra até vencer a regra com fonte".
- **D1**: preço-sombra do capital na ordenação da fila, deriva por categoria, duas testemunhas e bordas lentas como condições da fase 2; motor em arquivos puros.
- **D3**: a correção do `η_real`; a separação entre fato do jogo e juízo do dono; o contrato de mesa (recibo, sentinela, modos) guardado para a fase 3; pauta e ficha de evidência no relatório de sessão.
- **D6**: triagem pelo resumo, antiguerra G1 e G2, postagem-sonda e vetos com motivo. O mapa de concorrentes por nome fica condicionado à sonda de `owners`.

**Conflitos que a síntese precisa decidir, com a minha posição.**

1. **Fatia fina agora ou motor e mesa antes** (D5 contra D1 e D3). Posição: fatia fina. Motor fundo e mesa só por portão medido e por marco de banca; salvar por `/reload` no fecho da sessão, não a cada 30 minutos.
2. **Teclas por ação**: uma tecla modal (D5, D2), tecla por verbo (D1, D3, D6) ou armar e confirmar sempre (D4). Posição: tecla por verbo; segunda tecla só onde o jogo tem estado intermediário (cotação de commodity, aviso de postagem) e quando o bilhete passa de 5% a 10% da banca. Duas teclas para postar dobram o custo de atenção com só o depósito em risco.
3. **Correio**: leitura mais clique do dono no Open All (D4, D5), tecla ligada ao botão da Blizzard (D2, D3) ou `TakeInboxMoney` por tecla (D1, D6). Posição: leitura mais clique do dono na fase 1. Respeita a decisão de 2026-11-06 e evita taint; a tecla no botão só depois de testada na sonda e por decisão dele.
4. **Onde entra o `η_real`**: na saída (R9 5.1, seguido por D1, D2, D4, D6) ou no ganho (D3). Posição: no ganho, com 1,0 na arbitragem de vendedor.
5. **Tamanho e banca**: Kelly (D1, D2, D4) ou tetos fixos (D3, D5, D6); 10%, 20% ou 25% por item; banca de quem negocia (D4, D1) ou dos quatro personagens (D3). Posição: tetos fixos, 20% por linha depois de um lote de sondagem de 2%, 50% em risco de preço, banca igual ao `GetMoney` do negociador menos o piso. Kelly só como informação.
6. **Custo da atenção e ordenação**: zero (D1), tíquete de 15 cobre por tecla (D5), 1 ouro por hora (D3), 50 cobre por tecla com mínimo de 1 prata (D6), medido (D2). Posição: começar no tíquete do D5, medir segundos por ação como o D2 e trocar pelo lucro por hora realizado depois de três a cinco sessões; enquanto a banca for menor que 15 ouro, ordenar por capital-hora (D1).
7. **Preço de postagem**: `W*` decide (D1, D3, D4, D6), regra com fonte escolhida pelo dono (D2) ou configuração fixa com `P*` (D5). Posição: candidatos são as regras com fonte (igualar, cobrir um tick, folga); a tela mostra o `P*` de equilíbrio; a escolha por `W*` roda em sombra até 50 desfechos próprios; equipamento sempre iguala (base 1.11).
8. **Papel da arbitragem de vendedor**: estratégia de entrada (D5), micro com confirmação (D4), depois de sombra (D1, D3, D6). Posição: medir de graça nas primeiras varreduras (cobre disponível abaixo do vendedor e vida das ofertas) e ligar com o lote de confirmação do D4. Não é a tese: os concorrentes já têm o recurso (R6a) e os materiais listam bem acima do vendedor (R5b 2b).

Dois conflitos menores, fora da lista de oito: varredura por tecla de rodada (D3, D4, D5, D6) contra pulso de presença de 90 segundos (D1, D2), onde fico com uma tecla por rodada na fase 1; e nome de vendedor guardado (D6) contra hash (D3), onde fico com hash, só na fase 2 e só se a sonda mostrar `owners` preenchido.

**Aviso para a síntese.** O design único deve dizer ao dono, sem rodeio, o que os seis dizem em letras pequenas: com 5 ouro o addon não o deixa rico por trading; ele vende melhor o que os personagens produzem, mede o mercado e prova, com números dele, se e quando a compra para revenda paga.
