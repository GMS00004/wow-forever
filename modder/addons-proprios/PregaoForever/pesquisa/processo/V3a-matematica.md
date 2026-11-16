> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# V3a-matematica: parecer da lente matemática sobre o design PregaoForever (SINTESE.v1)

Data: 2026-11-16. Revisor: lente matemática. Li inteiros o design, a base de fatos e o R9, e rodei o `simB.mjs` do autor do R9 (os números da tabela 0.3 do R9 se reproduzem). Scripts meus, todos em `<tmp>/V3a-matematica/`: `pstar.mjs`, `escadas.mjs`, `portao.mjs`, `portao2.mjs` (rodam com `node`, semente fixa).

## Resumo do veredito

A matemática da fase 1 fecha: `W1`, `P*`, o piso do vendedor e os exemplos numéricos batem com a conta refeita. A cadeia de evidência da fase 2 não fecha em três pontos: a venda inferida não é limite inferior em mercado de pouca demanda (e ela destrava compra real pela classe B), o portão conta só o que fechou (estratégia perdedora passa em 100% das simulações) e o papel não tem regra para o buraco entre sessões (mede de 0,25 a 23 vezes a verdade). Além disso, a regra de cancelar e o `W*` em sombra pedem uma P(venda) que o próprio design deixou de fora.

## Item 1. Derivações refeitas, com veredito

| Derivação | Veredito | Como conferi |
|---|---|---|
| `W1` e `P*` (design 7.2) | **Fecha.** Faltam guardas de casos-limite (V3A-10). | Álgebra refeita: `W1 = v` dá `P·[p(1−c) − v + (rs−rx)·du] = (1−rx)·du`. Monte Carlo de 400 mil ciclos (`pstar.mjs`, bloco 1): no `P*` o ganho sobre o vendedor é zero tanto no ciclo "posta uma vez, se expirar vende ao NPC" quanto em "reposta até vender" (−0,18 e +0,15 cobre com `du = 100`; +0,17 e −0,06 com `du = 30`). O `P*` é o mesmo ponto de equilíbrio para qualquer número de repostagens, o que torna o número da tela robusto. |
| `W` e `W*` (R9 4.1) | **Fecha como álgebra, depende de hipóteses nomeadas**: mercado estacionário entre ciclos, repostagem imediata depois da expiração, P conhecida. Com P incerta a fórmula superestima (V3A-16). | O número de ciclos é geométrico de média `1/P`; o tempo total `E[min(T,D)]/P` sai da identidade de Wald. Monte Carlo confere `W` com P fixa. Com P por item sorteada de uma Beta de média 0,40, `W(P média)` dá 145,0 e a simulação dá 99,9 (Beta(2,3)) e −58,1 (Beta(1;1,5)): `E[1/P] > 1/E[P]`. |
| Regra de cancelar `Δ_canc` (R9 4.6) | **A álgebra fecha; a regra não é calculável no design e tem erro de unidade** (V3A-04). | Diferença direta `EV_cancela − EV_fica` contra a fórmula em 100 mil sorteios: erro máximo 2,3e−13. Mas `κ_cancel` é por ação e os outros termos são por unidade (a 4.1 divide `κ_post` por `n`; a 4.6 não). E a regra pede P, `W*` e `h`, que o design não tem nas fases 1 e 2. |
| Teste de compra (R9 5.1) e a mudança da 7.4 | **A mudança do design está certa** (a forma do R9 exige saída de 2,3 vezes o custo). **O parâmetro `η_real` no ganho depende de hipótese** (erro proporcional ao ganho, não ao preço de saída) e o estimador não está definido (V3A-06). | R9: `0,5·n·U ≥ 1,15·Custo`, ou `n·U ≥ 2,3·Custo`. Design: `n·U ≥ (1 + μ/η)·Custo = 1,30·Custo` mais `2·teclas·tíquete`. |
| Piso do vendedor (design 7.3) | **Fecha.** O teto da cotação admite compra abaixo do tíquete (V3A-12). | `EV = Σ(v − p_j)·q_j`; exemplo da tela: 14 × (13 − 9) = 56. |
| Filtro de isca e preço robusto (R9 1.2 e 1.3) | **Não fecha em escada rasa**: o pseudocódigo divide zero por zero quando a escada tem menos unidades que a apara inferior; a "janela" não está definida na fase 1 (V3A-11); em escada de unidade única o filtro vira "ignore o mais barato" (V3A-15). | Conta à mão: `Q_tot = 1`, `N_ref = max(5, teto(0,15)) = 5`, `lo = 1`, `hi = 4`; a unidade ocupa a posição [0,1): `dentro = min(1,4) − max(0,1) = 0`; `soma/peso = 0/0`. |
| Venda inferida (R9 2.1 a 2.4) | **A proposição da fronteira fecha; a afirmação "é limite inferior" não fecha** fora de mercado líquido (V3A-01) nem atravessando buraco de sessão (V3A-03). | `escadas.mjs`, blocos A e C (abaixo). |
| Limiar do sniper (R9 5.2) | **Não fecha com a 7.4**: três limiares diferentes para o mesmo teste (V3A-05). | `a_max`: R9 5.2 dá `U/1,15 = 0,870·U`; R9 5.1 dá `0,435·U`; o teste da 7.4 dá `0,5·U/0,65 = 0,769·U`. |
| Vão (R9 5.3) | **Não fecha com a 7.4**: a razão mínima citada na 3.2 é 1,21 e a que sai do teste da 7.4 é 1,37 (V3A-05). | `(1 + μ)/(1 − c) = 1,15/0,95 = 1,211`; `(1 + μ/η)/(1 − c) = 1,30/0,95 = 1,368`. |

### Casos-limite do `P*` (`pstar.mjs`, bloco 3)

| Caso | Denominador | `P*` |
|---|---|---|
| p no piso `v/(1−c)`, `rs = 1`, `rx = 0` | 30 | 1 (certo: no piso só empata com venda certa) |
| p no piso, `rs = 0`, `rx = 0` | 0 | divisão por zero |
| p = 60, v = 50, du = 30, `rs = 0` | 7 | 4,29 ("needs 429%") |
| depósito zero | 140 | 0 |
| v = 0 e depósito de 1 cobre | 191 | 0,5% |
| p abaixo do piso (40 contra v = 50) | 18 | 1,67 |
| v maior que o preço de leilão (v = 300, p = 200, du = 180) | 70 | 2,57 |

O piso `v/(1−c)` só é o piso certo com `rs = 1`. Em geral é `(v + (1−rs)·du)/(1−c)`. A H-09 deixa `rs` em aberto, então o código precisa da forma geral e de uma guarda para denominador menor ou igual a zero e `P*` maior ou igual a 1.

### Fórmula que une `W1` e `W` (para a sombra)

Com `A = p(1−c) − (1−rs)·du` e `L = (1−rx)·du`, o valor de "repostar até K vezes e depois vender ao NPC" é `V_K = P·A + (1−P)·(V_{K−1} − L)`, `V_0 = v`. `K = 1` é o `W1` do design; `K` infinito é o `W` do R9 sem cliques e sem custo de carregar. Para todo K, `V_K ≥ v` se e só se `P ≥ P*`. Não divide por P.

### Venda inferida e papel: saída do `escadas.mjs`

Mercado sintético no molde do `simB.mjs` (prioridade de preço, durações de 2, 8 e 24 h, cancelamento com repostagem), 1.500 horas por configuração. `S_lo` é a conta do R9 2.1 sem o casamento de repostagem.

**Bloco A, fotos regulares.**

| Mercado | Fotos | `S_lo` / vendas reais | Parte de `S_lo` que não foi venda | P(classe B: 3 intervalos em 24 h com venda inferida no preço da frente ou acima) |
|---|---|---|---|---|
| Líquido (30 un/h) | 5 / 15 / 60 min | 0,84 / 0,66 / 0,42 | 1% / 1% / 5% | 0,95 / 0,93 / 0,89 |
| Lento (3 un/h) | 5 / 15 / 60 min | 0,99 / 0,92 / 0,69 | 3% / 4% / 8% | 0,89 / 0,88 / 0,82 |
| Ralo (0,3 un/h de demanda, 1,5 de oferta) | 5 / 15 / 60 min | 1,14 / 1,11 / 0,94 | 15% / 20% / 34% | 0,95 / 0,93 / 0,80 |
| Quase morto (0,03 un/h, 1 de oferta) | 5 / 15 / 60 min | 2,83 / 2,89 / 4,04 | 66% / 70% / 82% | 0,13 / 0,14 / 0,24 |
| Morto (demanda zero) | 5 / 15 / 60 min | 83 / 98 / 159 unidades "vendidas" contra zero | 100% | 0,04 / 0,06 / 0,09 |

Leitura: em mercado líquido o R9 está certo (limite inferior, 83% a 5 min e 40% a 60 min). Em mercado de pouca demanda a frente some por expiração e cancelamento, e a conta vira superestimativa: de 2,8 a 4 vezes as vendas reais. Um item sem nenhum comprador ganha a testemunha da classe B em 4% a 9% dos instantes, e um item quase morto em 13% a 24%. Um estimador que só conta sumiço de coorte com idade conhecida e que não cruza 2, 8 ou 24 h corta de 83 a 159 unidades falsas para 16 a 24 (o resto é cancelamento na frente, que pede o casamento de repostagem do R9 2.3).

**Bloco B, papel contra a verdade com fotos regulares** (lote fantasma a um tick abaixo da frente, 24 h, sem impacto): papel sobre real de 0,93 a 0,99 no líquido, 0,77 a 0,95 no lento, 0,64 a 0,86 no ralo (conservador, como o design quer) e de 1,9 a 2,75 no quase morto (otimista).

**Bloco C, fotos só durante a sessão** (4 h por dia, uma foto a cada 10 min; lote de 24 h):

| Mercado | Lote | Real (fração vendida) | Papel, buraco descartado | Papel, buraco contado |
|---|---|---|---|---|
| Líquido | 5 / 40 un | 1,00 / 0,99 | 0,92 / 0,70 | 0,97 / 0,95 |
| Lento | 5 / 40 un | 0,93 / 0,70 | 0,71 / 0,18 | 0,91 / 0,53 |
| Ralo | 5 / 40 un | 0,36 / 0,06 | 0,09 / 0,01 | 0,62 / 0,25 |
| Quase morto | 5 / 40 un | 0,07 / 0,01 | 0,02 / 0,00 | 0,58 / 0,19 |

Leitura: descartando o intervalo que atravessa as 20 horas sem foto (o `Δ_max` do R9 2.4, que o design não trouxe), o papel vê um quarto da venda real fora do mercado líquido, e a razão de 0,5 do portão fica inalcançável para uma estratégia boa. Contando o buraco, o papel fica de 1,75 a 23 vezes otimista em mercado ralo. O design não diz qual das duas vale.

## Item 2. Fórmulas erradas ou incompletas

Cada uma tem exemplo numérico e forma correta na tabela dos achados: V3A-01 (venda inferida), V3A-04 (cancelar; unidade de `κ_cancel`), V3A-05 (limiares), V3A-06 (`η_real`), V3A-10 (`P*` e piso), V3A-11 (preço robusto), V3A-12 (teto da cotação), V3A-13 (deriva), V3A-16 (`W*`).

Dois exemplos que não cabem na tabela:

- **Unidade de `κ_cancel`** (R9 4.6). Lote de 20 unidades a 176 cobre, P = 0, 12 h restantes, `h = 0,002·V` por hora, `κ_cancel` = 45 cobre. Por lote: `h·T_m = 0,002 × 3.520 × 12 = 84,5` contra 45: cancelar (+39,5). Como está escrito, por unidade: `0,002 × 176 × 12 = 4,2` contra 45: não cancelar (−40,8). A decisão inverte. E com `h = 0` a regra nunca manda cancelar com P = 0: todo o "+36c if reposted" da tela sai de um custo de capital (`ρ_cap`) que o Apêndice B do design não declara.
- **`η_real` depende da margem do sinal.** Se a saída realizada fica 10% abaixo da prevista, a razão entre ganho realizado e previsto é 0,70 num sinal de 50% de margem, 0,57 num de 30% e 0,23 num de 15%. Com 20% de queda: 0,40, 0,13 e −0,53. Um `η_real` medido em sinais gordos não vale para sinais magros. O desconto estável é o da saída: `δ = 1 − Σ saída realizada / Σ saída prevista`. `δ = 0,115` reproduz o limiar de hoje (`0,885 × 1,30 = 1,15`).

## Item 3. Exemplos numéricos do design

| Onde | Número do design | Conta refeita | Fecha? |
|---|---|---|---|
| 3.1, hoje | 42% | `du` = 100 (mínimo de 1 prata): `100/(190 − 50 + 100) = 41,7%` | sim |
| 3.1, depois de 17/11 | 18%, depósito de 30 cobre | 60% de 50 = 30; `30/(190 − 50 + 30) = 17,6%` | sim |
| 11.3 Sell, Bandit Cloak | depósito 30c, needs 18% | igual ao de cima | sim |
| 11.3 Sell, Copper Ore x20, 8 h | depósito 20c, needs 1% | 20% de (20 × 5) = 20; `du` = 1; `1/(102,6 − 5 + 1) = 1,01%` | sim |
| 11.3 Sell, Ring | depósito 2c / 9c / 27c, vendor 45c | 5%, 20% e 60% de 45 = 2,25 / 9 / 27 | sim |
| 11.3 bilhete Linen x14 | pay 1s 26c, cap 1s 68c, 0.3%, exit 1s 82c, +56c | 14 × 9 = 126; 14 × 12 = 168; 126/40.000 = 0,315%; 14 × 13 = 182; 182 − 126 = 56 | sim |
| 11.3 Mine | deposits lost 3c of 8s allowed | 2% de 4 ouro = 8 prata | sim |
| 11.3 Session | 49 ações; +22c por ação; +7s 01c por hora | 21 + 14 + 3 + 11 = 49; 1.075/49 = 21,9; 1.075/(92/60) = 701 | sim |
| 11.3 Mail | +14s 20c, cut 75c | bruto 1.495, 5% = 74,7 (se +14s 20c for líquido) | sim |
| 11.3 cabeçalho | BANK 4g 00s, FREE 3g 12s, IN MAIL 0s, AT RISK 6% | 4g 00s − 3g 12s = 88s; 6% de 4g = 24s; sobram 64s sem estado | **não** (V3A-17) |
| 11.5 e 9.4 | UNEXPLAINED 3s 10c liga o disjuntor; gatilho de 1% de B | 1% de 4 ouro = 4s; 3s 10c = 0,78% | **não** (V3A-17) |
| 11.3 Session | capital turns 1.4 | 1,4 giro de 4 ouro = 5,6 ouro vendidos em 92 min, com resultado de 10s 75c (1,9%) e teto de estoque de 2 ouro | **não fecha sem definição** (V3A-17) |
| 0, resumo | giro da banca a 10% ou 15% rende de 50 a 75 prata | com 5,09 ouro: 51 a 76. Com a banca do design (4 ouro) e o teto de estoque de 50%: 20 a 30 | **não** com os tetos (V3A-18) |
| 11.3 bilhete Linen no teto | cap 1s 68c | no teto o lucro é 14 cobre em 3 teclas = 4,7 por tecla, abaixo do tíquete de 15 | **não** com a 7.3 (V3A-12) |

## Item 4. Portões de evidência (design 3.3)

Modelo (`portao.mjs`, `portao2.mjs`; 20 mil réplicas por célula): 30 sinais; ganho previsto por sinal `m ≥ 0,30` do custo (é o que o teste da 7.4 exige); realizado `= k·m + σ·ruído`, em fração do custo. `k = 0` é estratégia sem valor; `k = 0,5` é a que entrega exatamente o `η_real` de partida; `k = 1` entrega o previsto.

**Probabilidade de passar no portão do design:**

| σ por sinal | k = −0,25 | k = 0 | k = 0,25 | k = 0,5 | k = 1 |
|---|---|---|---|---|---|
| 0,10, sinais independentes | 0% | 0% | 0% | 50,0% | 100% |
| 0,20, independentes | 0% | 0% | 0,7% | 50,0% | 100% |
| 0,35, independentes | 0% | 0,3% | 8,2% | 49,7% | 99,7% |
| 0,50, independentes | 0,2% | 2,6% | 16,5% | 50,6% | 97,4% |
| 0,35, 6 grupos item-dia com correlação 0,5 | 0,5% | 4,1% | 18,9% | 50,3% | 95,6% |
| 0,50, 6 grupos | 3,5% | 11,6% | 26,8% | 49,8% | 88,6% |
| 0,50, 3 grupos de 10 | 8,8% | 18,2% | 33,0% | 50,2% | 81,7% |

O que cada condição faz contra a estratégia sem valor (σ de 0,2 a 0,5, independentes): soma positiva passa 50%; soma sem os 3 melhores, 16%; razão de 0,5 ou mais, 0% a 1,4%. A razão faz quase todo o trabalho. A regra dos 3 melhores só pesa em cauda direita (loteria: perde 5% quase sempre e ganha 400% raramente; no ponto de média zero passa 5,3% sem a regra e 0,1% com ela), então vale manter.

Por número de grupos item-dia (σ = 0,5, correlação 0,5): estratégia sem valor passa 22,0% com 2 grupos, 18,0% com 3, 10,6% com 6, 8,1% com 8, 6,3% com 10, 3,9% com 15, 1,5% com 30.

**Conclusões.**

1. Contra estratégia sem valor e sinais independentes o portão é forte (0% a 2,6% de passagem por sorte). Não é o ponto fraco.
2. O limiar da razão (0,5) é igual ao `η_real` de partida (0,5). Uma estratégia que entrega exatamente o que o teste de compra supõe é reprovada em 50% das vezes; com `k = 0,65`, passa 80% a 99,8%.
3. Trinta sinais em poucos itens não são trinta evidências: com 2 ou 3 itens a passagem por sorte sobe para 18% a 22%.
4. **Sobrevivência.** O portão conta "sinais fechados" e "lotes fechados", e a seção 10 fecha lote por venda. Estratégia em que 60% dos lotes vendem com 80% do previsto e 40% encalham e acabam em −50% (média verdadeira de −0,008 por sinal): com só os fechados, passa em **100,0%** das réplicas; contando todo sinal com mais de 48 h, os encalhados marcados à saída conservadora, passa em 0,2%.
5. O erro de medida do papel (item 1, blocos B e C) é maior que o erro amostral: de 0,25 a 23 vezes.

**Portão melhor, sem aumentar muito a espera:** (a) contar todo sinal emitido há mais de `T_fecho`, aberto ou não, com o aberto marcado; (b) contar por grupo item-dia, com 10 grupos ou mais e nenhum item acima de 20% dos sinais; (c) manter "sem os 3 melhores" e somar "sem o melhor item"; (d) razão como razão de somas, com o previsto antes do `η`; (e) só entra lote de papel com a vida observada (regra de buraco). Testei também um limite inferior de 90% da média por grupo: com 6 grupos baixa a passagem por sorte de 11,6% para 7,1%, mas reprova a estratégia boa de 11,4% para 19,7%; com 3 grupos reprova 69%. Não recomendo: exigir mais grupos é mais barato que um teste t com poucos graus de liberdade.

## Item 5. Tetos (design 9.2) contra uma banca de 4 ouro

Em cobre, com `B = 40.000`: lote de confirmação 800 (8 prata); ordem em micro 2.000 de partida e 4.000 duro; por item 4.000 e 8.000; estoque total 20.000; depósito em risco 2.000; depósito perdido no dia 800; perda do dia 2.000; perda por item 400; dinheiro sem explicação 400. Os percentuais são coerentes entre si (o depósito em risco inteiro perdido é igual à perda do dia; o perdido no dia é 40% dele).

Depósito de 24 horas pela leitura provável da base 1.4 (60% do preço de vendedor), contra os tetos de depósito:

| v do item | Depósito 24 h | Simultâneos (teto de 2.000) | Expirações por dia (teto de 800) | Uma expiração passa de 1% (bloqueia o item)? | Até 17/11 (mínimo 1 prata): simultâneos, expirações |
|---|---|---|---|---|---|
| 50 c | 30 c | 66 | 26 | não | 20, 8 |
| 2 s | 1s 20c | 16 | 6 | não | 16, 6 |
| 5 s | 3 s | 6 | 2 | não | 6, 2 |
| 10 s | 6 s | 3 | 1 | sim | 3, 1 |
| 20 s | 12 s | 1 | 0 | sim | 1, 0 |

Respostas:

- **Algum teto torna a fase 1 impossível com 4 ouro?** Não. A sonda inteira (S2, S6, S9) perde no máximo 4 depósitos mínimos, 4 prata, 1% de B. Mas o teto de depósito perdido no dia é o que aperta: verde de v = 5 prata com P(venda) de 0,4 permite cerca de 3,3 postagens por dia, e os 10 desfechos por classe e duração da seção 7.6 levam 3 dias; com v = 10 prata, 6 dias. Item com depósito acima de 8 prata (v acima de 13s 34c a 24 h) não pode expirar nem uma vez no dia.
- **O que torna impossível é a banca não ser de 4 ouro.** `B` é o `GetMoney` do personagem logado menos o piso de 1 ouro (9.1; DD4). Os 50.912 cobre estão em quatro personagens (base 4.1). Com divisão igual, o negociador tem 1,27 ouro e `B` = 27 prata: depósito em risco de 1s 36c e perdido no dia de 54 cobre. Um verde de v = 2 prata a 24 h (depósito de 1s 20c) ocupa o teto sozinho e uma expiração estoura o dia. `B` = 4 ouro só existe se os outros três mandarem todo o ouro ao negociador.
- **Coerência com os valores absolutos:** 2% de 4 ouro = 8 prata confere com a tela (`3c of 8s allowed`). O gatilho de 1% (4 prata) não confere com o alerta `UNEXPLAINED 3s 10c`.

## Tabela dos achados

| id | seção | gravidade | tipo | achado | evidência | correção |
|---|---|---|---|---|---|---|
| V3A-01 | 7.4 (classe B), 3.3 (papel), Apêndice C | bloqueante | fato_errado | A venda inferida não é limite inferior quando a demanda é baixa: a frente some por expiração e cancelamento e conta como venda. Ela é a testemunha da classe B, que torna a compra executável, e o preenchimento do papel. | `escadas.mjs` bloco A: `S_lo` de 2,8 a 4,0 vezes as vendas reais no mercado quase morto; 83 a 159 unidades "vendidas" com demanda zero; classe B falsa em 13% a 24% (quase morto) e 4% a 9% (morto). O `simB.mjs` do autor já dá 1,02 no mercado lento. Design, Apêndice C: "é limite inferior". | Na 7.4, 3.3 e Apêndice C, trocar "limite inferior" por "estimativa com viés nos dois sentidos". Venda inferida só conta se: as duas fotos distam até `Δ_max` (2 h); o sumiço não casa com repostagem (R9 2.3); a coorte tem idade conhecida e não cruza 2, 8 ou 24 h (em item, a faixa de tempo exclui expiração). Classe B exige intervalos em 2 dias distintos. |
| V3A-02 | 3.3, 10 | bloqueante | lacuna | Os portões contam só sinais e lotes fechados, e lote fecha por venda. O que encalha fica fora da conta. Uma estratégia perdedora com encalhe passa sempre. | Design 3.3: "30 sinais fechados", "30 lotes reais fechados"; seção 10: "Venda no leilão fecha pela fatura". `portao.mjs` bloco 3: média verdadeira −0,008 por sinal; passa 100,0% só com fechados e 0,2% contando os abertos marcados. R9 10.3 lista o viés de fim de amostra. | Na 3.3 e na 10: o portão conta todo sinal ou lote emitido há mais de `T_fecho` (72 h de partida, Apêndice B), fechado ou não; o aberto entra marcado a max(v, saída conservadora de hoje) menos custos. Escrever quando o lote de papel fecha: venda inferida completa, ou `T_fecho` com liquidação marcada. Vale para papel e para micro. |
| V3A-03 | 3.3, 16 (replay) | importante | lacuna | O design não diz o que o papel faz com o intervalo sem foto entre sessões. Descartando, o papel vê um quarto da venda real; contando, fica até 23 vezes otimista em mercado ralo. A razão de 0,5 do portão perde o sentido. | `escadas.mjs` bloco C (sessão de 4 h por dia): lote de 5 unidades, real 0,93 (lento), papel 0,71 descartando; real 0,36 (ralo), papel 0,09 descartando e 0,62 contando; quase morto: real 0,07, papel 0,58. R9 2.4 tem `Δ_max`; o design não o trouxe. | Na 3.3 e na 16: intervalo maior que `Δ_max` não gera venda inferida nem preenche papel. Lote de papel com trecho da vida sem foto fecha como `censored` e sai do realizado e do previsto. A ficha de evidência mostra a fração da vida observada, e o portão só conta lotes com vida observada inteira (na prática, duração de 2 h dentro da sessão). |
| V3A-04 | 7.1, 7.4 (cancelar), 11.3, 3.3 (sombra) | importante | contradicao_interna | A regra `Δ_canc` e o `W*` em sombra pedem P(venda), `W*` e custo de capital. O design exclui a tabela de P das fases 1 e 2, não inventa chance de venda e não declara `ρ_cap`. O conselho `CANCEL +36c` não é calculável. O R9 4.6 ainda soma `κ_cancel` por ação a termos por unidade. | Design 7.1: "Tabela de P(venda) ... ficam fora"; 7.2: "não inventa chance de venda"; Apêndice B sem `ρ_cap`. `pstar.mjs` bloco 6: lote de 20 a 176c, P = 0: +39,5 por lote, −40,8 por unidade como está escrito; com `h = 0`, nunca cancela. | Na 7.4, trocar a regra por conta por lote com o que se mede: `Δ = W1_lote(p', D', f_novo) + rc·d − [f_fica·(n·p·(1−c) + rs·d) + (1−f_fica)·(n·v + rx·d)] − tíquete·ações`, com `f_fica` e `f_novo` das frequências próprias por faixa de fila. Sem as duas, a linha diz `KEEP` sem valor. Declarar `ρ_cap` no Apêndice B ou tirar o termo de tempo. Na 3.3, dizer qual P alimenta o `W*`. |
| V3A-05 | 3.2 (linhas vao e sniper) contra 7.4 | importante | contradicao_interna | A tabela de estratégias cita os limiares do R9 5.2 e 5.3, que não são os que saem do teste da 7.4. O sinal de papel nasceria com um limiar e seria julgado por outro. | Sniper: R9 5.2 dá 0,870·U; R9 5.1 dá 0,435·U; a 7.4 dá `η·U/(η + μ) = 0,769·U`. Vão: R9 5.3 dá razão 1,211; a 7.4 dá `(1 + μ/η)/(1−c) = 1,368`. `pstar.mjs` bloco 7. A saída da 7.4 é a mediana dos mínimos diários, não `p_{k+1} − tick`. | Na 3.2, trocar as fórmulas citadas pelos limiares da 7.4: sniper compra até `a_max = U_lcb·η/(η + μ_min) − teclas·tíquete/(n·(η + μ_min))`; vão exige `saída·(1−c)/preço médio ≥ 1 + μ_min/η`. Na 7.4, dizer que a saída do vão é a saída conservadora e dar o número de teclas de uma compra para revenda (comprar, postar, correio). |
| V3A-06 | 7.4, 7.6, 3.3 | importante | lacuna | `η_real` (ganho realizado sobre previsto) não tem estimador definido e não é constante: para o mesmo erro de preço de saída, vale 0,70 em sinal de 50% de margem e 0,23 em sinal de 15%. Média de razões por sinal explode quando o previsto é pequeno. | Conta: saída 10% abaixo da prevista: `(0,9·1,5 − 1)/0,5 = 0,70`; `(0,9·1,3 − 1)/0,3 = 0,57`; `(0,9·1,15 − 1)/0,15 = 0,23`. Design 7.6: "previsto e realizado por lote fechado", sem fórmula. R9 5.1 e 5.7 se contradizem sobre onde o `η` incide. | Na 7.6 e 3.3: `η_real = Σ ganho realizado / Σ ganho previsto antes do desconto` (razão de somas, nunca média de razões), com os abertos marcados. Gravar também `δ = 1 − Σ saída realizada / Σ saída prevista`. Depois de 30 lotes, o teste da 7.4 passa a `n·U_lcb·(1−δ) − Custo − teclas·tíquete ≥ μ_min·Custo` (`δ = 0,115` dá o limiar de hoje). |
| V3A-07 | 3.3, Apêndice B | importante | risco | O portão trata 30 sinais como 30 evidências. Com poucos itens, estratégia sem valor passa por sorte em 18% a 22%. O limiar da razão (0,5) é igual ao `η_real` de partida: quem entrega exatamente o suposto é reprovado em metade das vezes. | `portao.mjs` e `portao2.mjs`: `k = 0`, σ = 0,5: 1,5% com 30 grupos, 8,1% com 8, 18,0% com 3, 22,0% com 2. `k = 0,5`: 50% em toda dispersão; `k = 0,65`: 80% a 99,8%. A razão sozinha faz o trabalho (soma positiva 50%, sem os 3 melhores 16%, razão 0% a 1,4%). | Na 3.3 e no Apêndice B: contar por grupo item-dia; exigir 10 grupos ou mais e nenhum item com mais de 20% dos sinais; manter "sem os 3 melhores" e somar "sem o melhor item"; escrever que a razão é de somas, com o previsto antes do `η`. Registrar como decisão do dono o limiar da razão, com a nota de que 0,5 reprova metade das estratégias que entregam 0,5. |
| V3A-08 | 3.3 (papel) | importante | lacuna | Nada impede que vários lotes de papel abertos no mesmo item sejam preenchidos pela mesma venda inferida. A demanda é contada uma vez por lote, e o papel de um item líquido passa sempre. | Conta: 30 sinais de 5 unidades no mesmo item num dia com 12 unidades de venda inferida: cada lote preenche 5, total de 150 unidades "vendidas" contra 12. O R9 10.2 limita ("Vale para lote ≤ s_cap·λ·Δ por intervalo"); o design não trouxe o limite. | Na 3.3: lotes de papel abertos na mesma chave consomem a venda inferida em fila, uma unidade inferida para uma unidade de papel, o lote mais antigo primeiro. A soma de papel aberto por chave fica dentro do teto de 10% do volume diário medido da seção 9.2, e o replay da seção 16 confere a mesma regra. |
| V3A-09 | 9.1, 9.2, 18 (DD4) | importante | risco | Os tetos de depósito são fração de `B`, e `B` é só o ouro do negociador menos 1 ouro de piso. Com o ouro dividido em quatro personagens, `B` é de 27 prata e a fase 1 não posta um verde de 2 prata por 24 h. Mesmo com 4 ouro, o perdido no dia segura a calibração. | Base 4.1: 50.912 cobre em quatro personagens. Design 9.1 e DD4. `portao2.mjs` bloco d: `B` = 4 ouro, v = 5s: 6 simultâneos, 2 expirações por dia; v = 10s: 1 expiração e item bloqueado (6s acima de 1%). `B` = 27 prata: tetos de 1s 36c e 54 cobre. Bloco e: 3 a 6 dias para 10 desfechos. | Na 9.2 e na DD4: mostrar os tetos de depósito em cobre para a banca real do negociador e dizer que 4 ouro pede juntar o ouro nele. Pôr como decisão do dono um piso absoluto para os tetos de depósito das vendas (exemplo: o maior entre 5% de B e 20 prata). Dizer que o Cofre nega a postagem cujo depósito, somado ao perdido no dia, passa do teto, e se depósito perdido conta no gatilho de 1% por item. |
| V3A-10 | 7.2, 9.2 (faixa de postagem) | importante | lacuna | O `P*` não tem guarda de caso-limite e o piso `v/(1−c)` só vale com `rs = 1`, que a H-09 deixa em aberto. Com `rs = 0` o piso dá divisão por zero e um preço pouco acima mostra "needs 429%". | `pstar.mjs` bloco 3: p no piso com `rs = 0`: denominador 0; p = 60, v = 50, du = 30: `P*` = 4,29; v maior que p: 2,57. Design 2.2, H-09: "nada no código assume fórmula". | Na 7.2 e 9.2: piso de preço `teto((v + (1−rs)·du)/(1−c))` no tick. Calcular por lote, em inteiros: `P* = (1−rx)·d / (n·p·(1−c) − n·v + (rs−rx)·d)`. Denominador menor ou igual a zero, ou `P*` maior ou igual a 1: veredito `VENDOR`, sem número. Depósito zero: `needs 0%`. Dizer que P é por unidade e que a devolução em venda parcial de lote é medida na S6. |
| V3A-11 | 7.2 (referência), 7.4 (preço robusto), Apêndice B | importante | lacuna | O filtro de isca usa "5% da janela" e a janela não está definida no design; na fase 1 não há taxa de venda para calculá-la. O pseudocódigo do preço robusto (R9 1.3) divide zero por zero em escada com menos unidades que a apara inferior, e apara só embaixo em escada rasa. | R9 1.2: `N_ref` depende de `λ`; item novo usa `f_0·Q_tot`. Conta: `Q_tot = 1`, `N_ref = 5`, `lo = 1`, `hi = 4`: `dentro = min(1,4) − max(0,1) = 0`, `soma/peso = 0/0`. Em Lua o resultado é NaN, e toda comparação com ele é falsa. | No Apêndice B e na 7.2: janela `N_ref = limita(teto(0,15·Q_tot), 5, 2.000)` enquanto não houver taxa de venda; isca é quantidade acumulada até `max(1, 0,05·N_ref)`, em até 3 degraus. Na 7.4: o preço robusto apara sobre `N_ef = min(N_ref, unidades depois da isca)`; `N_ef = 0` ou peso zero devolve "sem preço", e a bancada tem os casos de 1, 2 e 5 unidades. |
| V3A-12 | 7.3 | menor | contradicao_interna | O teto da cotação `n·(v − 1 tick)` aceita compra que não passa no critério da própria seção (`EV/teclas ≥ tíquete`). A conta também não tem o custo fixo da ida ao NPC, que o R9 5.4 tem (`M_npc`). | Tela 11.3: Linen x14, cap 1s 68c: lucro no teto de 182 − 168 = 14 cobre em 3 teclas = 4,7 por tecla, contra tíquete de 15. Teto coerente: 182 − 45 = 137. R9 5.4: "Limiar: EV ≥ M_npc (cobre a ida ao NPC e o espaço de bolsa)". | Na 7.3, trocar a linha do teto por `teto da cotação = min( n·(v − 1 tick), n·v − teclas·tíquete )` e corrigir o `cap` do bilhete da 11.3 para 1s 37c. Acrescentar ao EV um custo fixo por ida ao vendedor, do `Config.lua` (zero de partida, medido pelo tempo por ação da 7.6). |
| V3A-13 | 7.4 (deriva), 9.3 | menor | lacuna | A deriva é "variação do menor preço entre resumos separados por 6 horas ou mais", sem dividir pelo intervalo: variação de 6 h e de 30 h entram como a mesma grandeza. Também não há fórmula de como ela vira custo de carregar. | Design 7.4: "Entra como custo de carregar"; 9.3: "abaixo de −10% em dois dias". Conta: −5% em 6 h são −18,6% por dia; −5% em 30 h são −4,0% por dia. | Na 7.4: `deriva_dia` = mediana, por categoria, de `ln(min_b/min_a)/(t_b − t_a)` em dias, com pares de resumos completos separados por 6 a 48 h. Custo de carregar por unidade = `U_lcb·(1 − exp(min(0, deriva_dia)·T_caixa))`, com `T_caixa` em dias. Na 9.3: suspende quando `2·deriva_dia ≤ ln(0,9)`. |
| V3A-14 | 7.2 (veredito), 7.6 | menor | risco | O veredito `AUCTION` compara a frequência de 10 desfechos com o `P*`. Com chance real igual à metade da necessária, a tela diz `AUCTION` em 22% das vezes. O design não diz se leilão cancelado entra na frequência. | `pstar.mjs` bloco 5: `P*` = 0,176, n = 10: P real 0,088 passa 21,8%; 0,132 passa 38,8%. Wilson 80% para 4 de 10: 0,23 a 0,60. | Na 7.2: `AUCTION` quando o limite inferior de Wilson de 80% da frequência supera o `P*`; entre o limite e a frequência, `YOUR CALL`. Na 7.6: leilão cancelado pelo dono sai do numerador e do denominador (desfecho censurado), e a frequência é por classe, duração e regra de preço. |
| V3A-15 | 7.2 (referência) | menor | risco | Em escada de unidade única (equipamento), o filtro de isca tira o leilão mais barato sempre que o segundo estiver 15% acima, porque o limite de quantidade nunca é menor que 1. Com a regra `igualar`, o verde é postado acima do menor preço real. | R9 1.2: `q_isca = max(1, f_isca·N_ref)`. Conta: 5 leilões a 100, 150, 160, 170 e 200: `N_ref = 5`, `q_isca = 1`, salto de 50%: a frente vira 150. | Na 7.2: o filtro de isca só vale em escada com 20 unidades ou mais; abaixo disso a frente é o menor preço e a linha mostra o salto até o segundo (`next +50%`) para o dono julgar. Registrar como hipótese a medir se o menor preço de verde costuma vender. |
| V3A-16 | 3.3 (sombra), 7.1 | menor | melhoria | O `W` do R9 divide por P. Com P estimada, superestima o valor (desigualdade de Jensen) e vai a menos infinito com P perto de zero. A sombra compararia regras com uma conta enviesada para preço alto. | `pstar.mjs` bloco 4: P por item de média 0,40: fórmula 145,0; simulação 99,9 (Beta(2,3)) e −58,1 (Beta(1;1,5)). | Na 3.3, definir o valor da regra em sombra pela recursão finita `V_K = P·A + (1−P)·(V_{K−1} − L)`, `V_0 = v`, `A = p(1−c) − (1−rs)·du`, `L = (1−rx)·du`, com K do `Config.lua` (3 de partida). K = 1 é o `W1` da 7.2 e K infinito é o `W` do R9 4.1. |
| V3A-17 | 11.3, 11.5, 9.4, 10 | menor | contradicao_interna | Três números das telas não fecham: o cabeçalho (4g 00s contra 3g 12s livres e 6% em risco), o alerta `UNEXPLAINED 3s 10c` (abaixo do gatilho de 1%) e `capital turns 1.4` (5,6 ouro girados em 92 minutos com resultado de 10s 75c). | Contas: 4g 00s − 3g 12s = 88s; 6% de 4g = 24s; faltam 64s. 1% de 4g = 4s; 3s 10c = 0,78%. A seção 10 diz que qualquer `UNEXPLAINED` liga o disjuntor; a 9.4 diz 1%. | Na 11.3: fazer o cabeçalho fechar (FREE + IN MAIL + estoque + depósitos = BANK) ou mostrar a parcela que falta. Na 11.5: trocar o valor do alerta por um acima de 4s, ou alinhar a 9.4 e a 10 num só gatilho. Definir `capital turns` (custo do vendido sobre o estoque médio a custo) e pôr um número coerente. |
| V3A-18 | 0 (resumo) | menor | contradicao_interna | O resumo promete de 50 a 75 prata por giro da banca. A conta usa os 5,09 ouro dos quatro personagens; pelas regras do próprio design a banca é de 4 ouro no máximo e só metade pode ficar em estoque. | Design 9.1 (só o personagem logado, menos o piso), 9.2 (estoque total 50%), DD4 (piso de 1 ouro). Conta: 10% e 15% de 2 ouro = 20 e 30 prata (`portao2.mjs` bloco f). | Na seção 0, trocar a frase por: "Com a banca de até 4 ouro (5 menos o piso) e o teto de 50% em estoque, um giro do capital que pode ficar em estoque, a 10% ou 15% de margem líquida, rende de 20 a 30 prata, antes de depósitos perdidos." |
| V3A-19 | 7.4 (bordas lentas) | menor | lacuna | A regra compara a "vida medida das ofertas" com o tempo de reação do dono. A vida só se mede com a resolução do intervalo entre fotos (minutos), e a reação é de segundos: a comparação não distingue nada. | R9 9.2: "A resolução é limitada pela cadência das fotos: não se distingue reação mais rápida que Δ". Design 5.2: um fôlego por tecla, sem cadência fixa. | Na 7.4, trocar "vida medida das ofertas daquela faixa de desconto passa do tempo de reação medido" por "a taxa de 'já sumiu' medida na releitura da tecla, por faixa de desconto, é de até 70% em 30 sinais". É a mesma medida que a 3.2 já usa para ligar o sniper. |
