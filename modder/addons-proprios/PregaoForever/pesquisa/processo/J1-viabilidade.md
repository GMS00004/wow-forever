> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# J1-viabilidade: parecer do juiz de engenharia e verdade dos fatos

Data: 2026-11-16. Lente: cada mecanismo cabe na API como a base a descreve? Throttle, evento de hardware, tamanho das SavedVariables, orçamento de Lua por quadro, taint e bancada foram tratados com realismo? Onde o projeto depende de incógnita, há medida e caminho alternativo?

## 0. Como julguei

- Li a base inteira e os seis projetos por inteiro.
- Conferi na fonte as citações que sustentam mecanismo: R1a (contrato, enum de erro, eventos 4, 8, 10, 13, 27 a 29, 35; funções 6, 63, 79, 86), R1b (seções 3 a 16), R1c (correio, relógio, `ReloadUI`, `C_UI.Reload`, `GetTimePreciseSec`), R4a e R4b (ferramentas, fengari 5.3, BoP, arquivo de 561 KB), R8a e R8b (fichas e recomendações citadas), R9 (0.3, 3.2, 5.1, 5.7, 7.2, 11), R5a 2.5, 3.2 e 4.2, R6a 2.1 e 2.10, R6b incógnita 4, R10a.
- Conferi no espelho as linhas citadas: `Blizzard_MailFrame/MailFrame.lua` 271, 573 a 576, 790, 1631 a 1634; `MailFrame.xml` 444; `Blizzard_AuctionHouseBuyDialog.lua` 3; `Shared/Blizzard_AuctionHouseUtil.lua` 391 a 400; `Blizzard_AuctionHouseTableBuilder.lua` 1095 e 1144; `AuctionHouseDocumentation.lua` (as 7 marcas `HasRestrictions`, `SearchForItemKeys`, `minPrice`).
- Resultado geral: as citações dos seis projetos são reais. Não achei função, evento ou linha inventada. Os defeitos de fato são de outro tipo: incógnita tratada como fato, número derivado atribuído à base, e citação que não diz o que o texto diz.
- Escala. Em "risco", nota alta quer dizer bem protegido.

## 1. Notas

| Projeto | Viabilidade | Lucro | Aderência | Risco | Testabilidade |
|---|---|---|---|---|---|
| D1-quant | 6 | 5 | 7 | 7 | 8 |
| D2-operador | 6 | 6 | 8 | 6 | 8 |
| D3-mesa | 6 | 5 | 6 | 6 | 8 |
| D4-risco | 8 | 4 | 7 | 9 | 9 |
| D5-ouro | 8 | 6 | 7 | 7 | 8 |
| D6-concorrencia | 4 | 5 | 6 | 6 | 7 |

### D1-quant

- **Viabilidade 6.** Tudo cabe na API e é o projeto que melhor escreve incógnita: doze hipóteses numeradas (H-01 a H-12), cada uma com medida e caminho alternativo (seções 3.3 a 3.6 e 8.4). Perde por tamanho: 30 arquivos, mais de cem parâmetros, banco com teto de 8 MB (3.6), e o motor inteiro depende de a inferência de vendas funcionar (H-04, cadência de 6 fotos por hora em 150 itens).
- **Lucro 5.** O lado vendedor sai cedo e não pede capital (1.2), mas a compra só abre no portão G3 (40 postagens resolvidas, 25 sinais de sombra; 4.6). O próprio projeto diz que na fase 1 "o ouro novo vem do personagem, não do pregão".
- **Aderência 7.** Verbos em teclas separadas e confirmação em tecla distinta (6.2), sem caixa de texto, telas dentro das 5 linhas (6.3). São 12 teclas e telas densas de número para uso por stream.
- **Risco 7.** Estado `INCERTO` com reconciliação (3.5), duas chaves para ligar estratégia (3.7), duas testemunhas (4.3). O risco que sobra é de modelo: R9 sem revisor multiplicado por cem parâmetros (risco 4 do próprio projeto).
- **Testabilidade 8.** Bancada com falha injetada, propriedades do motor puro, replay progressivo, simulação de recuperação e `checar-acoes.mjs` (8.1 a 8.3). O aceite da compra pede dezenas de desfechos reais que a banca demora a produzir.

### D2-operador

- **Viabilidade 6.** O caminho da tecla é o mais realista dos seis: uma chamada restrita por clique, `Gatilho.lua` sem timer nem evento (3.3), teste de tecla segurada pelo acesso remoto (S2) e plano B de cursor estacionado (6.2). Faltam: orçamento de Lua por quadro (não aparece em lugar nenhum), a incógnita da gravação das SavedVariables, e a meta de 6 a 10 ações por minuto (1.2) depende de um throttle que a base dá como desconhecido (base 2.14).
- **Lucro 6.** Liquidação do estoque próprio e vendedor na fase 1, com o custo de cada tecla medido (4.2). A tese aposta em execução rápida, que é onde o próprio projeto admite que um bot vence (1.3).
- **Aderência 8.** É o melhor desenho para operar por stream: uma tela, três zonas fixas, eco imediato, `T_ver` com a latência no arquivo, sem animação, ritmo de sessão (6.1, 6.5, 6.6).
- **Risco 6.** Guardas conferidas de novo na tecla (7.1) e `NO ANSWER` com conciliação (3.4). Contra: a mesma tecla `K` compra, posta, cancela e aciona o Open All; item sai em uma tecla; e o projeto mesmo diz que a interface rápida multiplica o erro de um motor mínimo (risco 3).
- **Testabilidade 8.** Casos de operador com teclas patológicas, seis invariantes, 200 rodadas aleatórias, quadros em HTML para o dono e modo treino antes de ouro (8).

### D3-mesa

- **Viabilidade 6.** Os contratos de dados são os mais sólidos (sequência e recibo, sentinela, gravação atômica, três modos de degradação; 3.5 e 3.6) e ele levanta incógnitas que ninguém mais viu: `PostItem` direto da bolsa, arquivo de dados quebrado isolando os outros, `/reload` fechando a casa (S1, S6). Perde porque a arquitetura depende de `/reload` no meio da sessão a cada 30 a 40 minutos, de um processo vigia e de dois idiomas; e porque dá a ação por falha em 5 s e rearma a tecla (3.4 d).
- **Lucro 5.** A fase 1 não tem tecla de ação: o dono posta pela tela da Blizzard e o addon só mostra (2). Conserta a conta de compra do R9, o que deixa sinal de compra existir (4, linha do `η_real`).
- **Aderência 6.** O ritual de sync com tela de carga por acesso remoto e sync duplo na abertura pesa (3.7); cerca de 20 teclas. A pauta do dia e a ficha de evidência por estratégia servem bem ao jeito de o dono decidir (3.8).
- **Risco 6.** Limite de cotação mais duro que o da Blizzard e modo `NO DESK` (7). Contra: falha em 5 s sem conciliar, ficha velha lida como nova, e a banca soma o ouro de quatro personagens (7, linha Banca).
- **Testabilidade 8.** Bandeira de hardware na bancada, `checar-mesa.mjs` com teste de ida e volta entre Lua e Node, replay determinístico, simulações do R9 como regressão (8).

### D4-risco

- **Viabilidade 8.** O mais conservador diante de incógnita: trata `ConfirmCommoditiesPurchase` como restrita (3.1), toda ação tem eco ou vira `INCERTO` (3.5), throttle com vigia e estado `TRAVADO` (3.4), foto vazia suspeita (7.4). É o único que marca como hipótese a leitura da fatura antes de abrir a carta (6.3 D, passo 5). Falhas: deriva de 7% ao dia atribuída à base (1 e 4.2), nada sobre a gravação das SavedVariables, e herda a conta de compra do R9 sem corrigir.
- **Lucro 4.** Duas teclas por compra, três por postagem com aviso, 2% da banca por ordem em micro (7.2) e semanas em papel. O risco 1 do projeto é ele mesmo: "pode não fazer quase nada".
- **Aderência 7.** Cumpre todas as regras com folga e só `Y` movimenta ouro (6.1). Custa em teclas por stream e recusa boa parte do que o pedido chama de day trading pesado.
- **Risco 9.** Sete invariantes como contrato, Cofre que nega na dúvida, tetos como constantes que a configuração só aperta, licença que só desce dentro do jogo, disjuntor de restrição de conta (3.1, 7.2, 7.3).
- **Testabilidade 9.** 24 cenários nomeados, 10.000 roteiros aleatórios com as mesmas conferências, papel do addon igual ao papel do replay, checador com um caso bom e um ruim por regra, aceite por degrau (8.1 a 8.5).

### D5-ouro

- **Viabilidade 8.** O menor: 21 arquivos na fase 1, cerca de 1,1 MB, quatro teclas, sem aplicativo companheiro, só consulta resumida e poucas escadas (3.1, 3.4, 6.1). Pré-checagens tiradas do contrato (`IsSellItemValid`, depósito nulo; 3.3 e 7) e a hipótese, que só ele tem, de a lista da Blizzard reler a nossa varredura (3.2). Falhas: ação sem resposta vira `FALHOU` e a tecla volta a valer, sem conciliar (3.3); não prevê o clique do mouse no próprio botão se o binding falhar (risco 2); usa `CancelSell` com semântica presumida.
- **Lucro 6.** É o único com ouro na primeira semana e com linha de base medida antes de construir (onda 2). O próprio projeto diz que lucro de piso é cobre e prata e que a fatia fina não é day trading pesado (1.5).
- **Aderência 7.** Quatro teclas sem modificador e telas dentro da regra (6). Fica longe do "ir ao extremo" do pedido, e a tecla F6 muda de sentido conforme a linha.
- **Risco 7.** Lote de sondagem de 2%, teto de cotação do motor, throttle não pronto consome a tecla sem disparar depois (3.3, 4.2). Perda diária de 10% abaixo de 15 ouro e a falta de conciliação pesam contra.
- **Testabilidade 8.** Marcador de tecla na bancada, replay, checador novo e, o melhor do projeto, resultado medido e limiar de parada por onda (9, colunas "Resultado medido" e "Para se").

### D6-concorrencia

- **Viabilidade 4.** O valor do projeto depende de duas coisas que a base dá como incógnita: `owners` preenchido (base 11.5) e fotos a cada 5 minutos ou menos para medir tempo de reação (4.2, estágio C). O próprio projeto diz que, sem os nomes, sobra algo que "não justifica um addon separado" (risco 1). Motor pesado dentro do jogo (diferença, concorrentes, mercado e nicho sobre 150 candidatos) sem nenhuma linha sobre orçamento por quadro; banco de 4,3 a 8 MB com nomes de jogadores (3.4). A favor: S3 no começo da sonda, com o aviso de que é a medida que decide.
- **Lucro 5.** Se existirem nichos sem cobridor, o ganho por tecla é bom; se não, a fase 1 só vende o que o dono já tem. Primeira compra em dias, no mínimo.
- **Aderência 6.** Radar por veredito é organizado e legível (6.2). Troca o nome, mostra nomes de jogadores na tela e usa cerca de 20 teclas.
- **Risco 6.** Regras antiguerra e trégua (4.4), guardas de preço, `INCERTA`. Contra: 25% da banca por nicho, maldição do vencedor na seleção (risco 4 do projeto) e limiares próprios sem fonte.
- **Testabilidade 7.** Mercado sintético com agentes plantados e aceite numérico (Brier até 0,22, acerto de cobertura de 70%; 8). A medida central tem resolução limitada pelo intervalo entre fotos (risco 2).

## 2. Contradições com a base e fatos sem base

Critério: fato do jogo que não está na base nem em relatório conta como inventado.

**Comuns a vários**

1. **Fatura lida antes de abrir a carta, tratada como fato.** D1 6.4 D ("Read 7 of 7, safe to collect"), D2 6.4 D, D3 3.4 (Recolher o correio), D5 6.3 D ("Safe to collect") e D6 6.3. A base 3.1 só diz o que a fatura traz. No espelho, a Blizzard chama `GetInboxInvoiceInfo(InboxFrame.openMailID)` depois de `GetInboxText` da carta aberta (`MailFrame.lua` 573 a 576 e 790). Se a função responde para carta não aberta é incógnita. Só o D4 a marca (6.3 D, passo 5; sonda, passo 6).
2. **Roda do mouse.** D1 6.2, D2 7.6, D3 2, D4 6.4 e D5 7 citam a base 5.1 para não ligar ação à roda. A base 5.1 fala da macro de roda do "Destroy" da TSM, não de ação de leilão. A recusa vale como escolha de desenho; como fato, a citação não sustenta. O D2 acrescenta "uma roda solta gera dezenas de eventos por gesto", sem fonte.
3. **Conta de compra do R9 adotada sem conferir.** D1 4.1, D2 4.1, D4 4.3 e D6 4.5 usam `EV = η_real · n · U_lcb − custo` (R9 5.1) com `η_real` de 0,5. Nessa forma só passa saída maior que duas vezes o custo, o que contradiz a definição do próprio R9 5.7 (razão entre ganho realizado e previsto). Só o D3 viu e trocou (4, linha "5.1 Lugar do desconto").

**D1-quant**

4. 6.2 e 6.4 D, tecla `C`: `TakeInboxMoney` e `AutoLootMailItem` por tecla aparecem sem marca de hipótese. A base 3.1 só diz que são globais antigas sem documentação; se exigem evento de hardware ou aceitam chamada de addon não está em lugar nenhum.
5. 3.5, postagem de item com quantidade maior que 1 pelo multisell "como uma ação": o R1b 6 descreve os eventos, não o que `PostItem` faz com a quantidade no Forever. Vale como hipótese e toca a regra de uma postagem por tecla.

**D2-operador**

6. 1.1: "todos leem a mesma API, sob o mesmo teto de 100 buscas por minuto". A base 2.2 limita só a busca por item, e a base 2.5 e 5.2 mostram concorrente com varredura completa por `ReplicateItems`.
7. 6.7: cita a base 3.6 para dizer que som e ícone podem não atravessar o acesso remoto. A base 3.6 não diz isso; é inferência do R10a 4.
8. 7.1, banda de preço "POST até 1,5 × V" valendo na fase 1, quando o motor M0 (4) não calcula V. É contradição interna, não com a base.
9. Não trata a incógnita da gravação das SavedVariables (R6b, incógnita 4). A S8 mede só o tempo do reload.

**D3-mesa**

10. 7, linha Banca: soma o ouro dos quatro personagens pelo Syndicator. A base 4.2 diz que não há banco de conta: o personagem logado não gasta o ouro dos outros, e os tetos sairiam maiores que o caixa real.
11. 3.4 d: ação sem evento em 5 s vira `FALHOU` e uma tecla nova a repete. A base 2.14 diz que a cadência do throttle é desconhecida, e o R1b 4 e 5 mostra a própria Blizzard esperando com spinner depois de 2 s. Resposta lenta mais tecla nova dá ação em dobro.

**D4-risco**

12. 1 e 4.2: "deriva de cerca de 7% ao dia (base 6.1)". A base 6.1 dá queda de 41% da mediana listada numa semana, de sites que vendem ouro, "tratar como direção". O número diário é conta do projetista e fixa `H_max` em 24 h e `μ_min` em 0,15.
13. 7.6: estende a decisão do dono de 2026-11-06 (base 4.6: funções que compram ou gastam) a pegar correio. A lista proibida do projeto (R4a, regra 7) não tem função de correio. É restrição a mais, apresentada como se viesse da base.
14. Não trata a incógnita da gravação das SavedVariables (R6b, incógnita 4).

**D5-ouro**

15. 3.3: `CancelSell` para desistir de uma postagem à espera de confirmação. O R1b 6 só mostra `CancelSell` no multisell; o efeito nesse outro estado é presumido, sem marca de hipótese.
16. 4.3: probabilidades iniciais de 0,25, 0,45 e 0,65 por duração. O projeto declara "sem fonte: hipótese", então não é fato inventado; registro porque decidem o veredito de venda da primeira semana.

**D6-concorrencia**

17. Fora o item 1, nenhuma contradição achada. As citações do espelho (coluna "Seller", `GetSellersString`) e do contrato conferem. O defeito é de dependência, não de fato: o centro do projeto é uma incógnita.

**Desvio de convenção.** D1 e D2 usam `SavedVariablesPerCharacter: PregaoForeverCharDB`; a base 4.8 fala em SavedVariables `<Nome>DB`. Os outros quatro guardam a parte por personagem dentro do banco de conta.

## 3. Defeito mais grave e enxertos

### D1-quant

**Defeito mais grave.** Peso e dependência: 30 arquivos e mais de cem parâmetros de um modelo sem revisor, com nove módulos `Motor*` que só valem se a venda alheia for inferível (H-04, cadência, commodity). Se a sonda negar, a maior parte do código fica sem função, e a primeira compra recomendada está a semanas.

**Enxertos.**
1. Hipóteses numeradas, cada uma com medida e caminho alternativo (3.3 a 3.6; 8.4): é o formato que a regra 8 pede.
2. Estado `INCERTO` com reconciliação por dinheiro, bolsas e `QueryOwnedAuctions`, bloqueando ação nova (3.5): única resposta segura à falha muda da base 2.12.
3. Duas chaves para ligar estratégia, aprovação no `Config.lua` e portão de calibração no arquivo da mesa (3.7 e 4.6): cumpre a regra 3 por construção.
4. Arquivos de motor puros, sem global do jogo, e checador que barra o que diverge entre Lua 5.1 e 5.3 (3.2; 8.3): é o que torna o replay confiável.
5. Tabela do diário de calibração, com o tempo de reação e a vida das ofertas medidos (4.5): transforma a latência do acesso remoto em parâmetro.
6. Duas testemunhas: sinal de compra só executável com venda inferida recente no patamar de saída (4.3, item 4): defesa direta contra preço listado que não vende (base 5.8).

### D2-operador

**Defeito mais grave.** A tese mede sucesso por vazão de teclas num terreno em que o throttle é incógnita e os bots vencem, e põe todos os verbos na mesma tecla `K` (comprar, postar, cancelar, Open All), o erro de modo que o próprio texto promete evitar. Não há orçamento de Lua por quadro.

**Enxertos.**
1. Sonda de tecla segurada, local e pelo acesso remoto, e disjuntor de rajada (8, S2; 6.6): nenhum outro mede o que o stream faz com a tecla.
2. Plano B de cursor estacionado, um gesto por ação sem viagem de ponteiro (6.2): caminho pronto se o binding não valer.
3. `T_ver` com a latência do acesso remoto no arquivo, eco no mesmo quadro e cabeça de fila que não troca sozinha (3.4; 6.1; 6.6).
4. Casos de operador com sequências patológicas e seis invariantes, mais rodadas aleatórias (8): prova a regra 1 pelo lado de quem digita.
5. `Gatilho.lua` sem `C_Timer`, `OnUpdate` nem `RegisterEvent`, com as respostas tratadas em outro arquivo e contador `emTecla` (3.3): regra estática simples de checar.
6. Modo treino, em que o cartão é real e a tecla só registra (2; 8), e a hipótese do throttle dividido com o UI da Blizzard e outros addons (3.4).

### D3-mesa

**Defeito mais grave.** O canal único é o `/reload` no meio da sessão: fecha a casa, mostra tela de carga pelo stream e pede um vigia rodando. Sem ele o addon não aprende nada dentro do bloco. Junto, a ação dada por falha em 5 s sem conciliar.

**Enxertos.**
1. Contrato de dados: sequência monotônica com recibo (entrega pelo menos uma vez), sentinela de arquivo inteiro, gravação atômica, leitura por `luaparse` sem executar (3.5; 3.6).
2. Modos `DESK OK`, `DESK STALE` e `NO DESK`, com o que cada um desliga (3.6): arquivo velho nunca vira recomendação.
3. Correção do `η_real`: desconta o ganho, não a saída inteira (4): sem ela nenhum sinal de compra passa.
4. Incógnitas que só ele levanta: `PostItem` direto da bolsa por `ItemLocation`, arquivo de dados quebrado, `/reload` fechando a casa; e a S6 logo depois da S1 (3.4; 3.6; 8).
5. Bandeira de hardware na bancada e `checar-mesa.mjs` com teste de ida e volta (8).
6. Separação de quem troca o quê: fato do jogo e ajuste estatístico a mesa troca dentro de faixa; teto, margem e estratégia só o dono (4, fim); e hash do nome de vendedor (3.6).

### D4-risco

**Defeito mais grave.** Pode não operar: duas a três teclas por ação, 2% da banca por ordem e a conta de compra do R9 sem correção fazem o portão de papel de flip e sniper quase impossível de abrir. O dono passaria a operar por fora, onde nenhuma guarda vale (risco 1 do projeto).

**Enxertos.**
1. Invariantes I1 a I7 como contrato conferido por checador e bancada (3.1).
2. Cofre com licença em quatro níveis (desligada, papel, micro, plena); nível efetivo é o menor entre dono, evidência e disjuntor, e só desce dentro do jogo (5; 3.1 I7).
3. `Tetos.lua` como constantes que a configuração só aperta (7.2).
4. Lote de confirmação por item na compra para o vendedor: 1 unidade, venda ao NPC, conferência pelo dinheiro (5, E2): o dado próprio vira evidência com custo de cobres.
5. Bancada com 24 cenários e 10.000 roteiros aleatórios, e a regra de o papel do addon bater com o do replay (8.1; 8.2).
6. Correio só de leitura com a hipótese da fatura antes de abrir e o caminho alternativo (6.3 D), foto vazia suspeita (7.4) e a regra "onde a base diz que não se sabe se pode, age como se não pudesse" (3.1).

### D5-ouro

**Defeito mais grave.** Falha sem conciliação: ação sem resposta em 10 s vira `FALHOU` e a tecla volta a valer, com risco de compra em dobro; e não há o clique do mouse no próprio botão como caminho se o binding falhar. O teto de lucro é de cobres e o projeto assume que será reescrito.

**Enxertos.**
1. Onda 0 sem código: o dono cola hoje os comandos do R1b 16 e já mede depósito e commodity (9).
2. Régua primeiro: razão por estratégia e por tecla que mede também o que é feito pela tela da Blizzard ou por outro addon, dando linha de base (1.1; 9, onda 2).
3. Colunas "Resultado medido" e "Para se" em cada onda (9): critério de parada escrito antes de gastar.
4. "Foto velha, a tecla atualiza; foto fresca, a tecla age", ficha de tecla consumida na primeira chamada, e throttle não pronto que consome a tecla sem disparar depois (3.3).
5. Valor de uma tentativa com saída no vendedor e o ponto de equilíbrio dito em palavras, `needs 18%` (4.2): funciona sem probabilidade calibrada.
6. Hipótese da lista da Blizzard relendo a nossa varredura e de consulta de outro addon no meio (3.2); `IsSellItemValid` e depósito nulo nas pré-checagens (3.3; 7).

### D6-concorrencia

**Defeito mais grave.** O centro do projeto é uma incógnita (`owners`) somada a uma cadência de fotos que o throttle e a tecla por rodada podem não dar. O caminho alternativo, por assinatura, é fraco pela admissão do próprio texto. Motor pesado no jogo sem orçamento por quadro.

**Enxertos.**
1. Mercado sintético com agentes plantados (âncora, cobridor rápido, estoque fundo, parede, isca) na bancada (8): testa estimador contra verdade conhecida.
2. Regras antiguerra G1 a G5 e trégua (4.4): teto de repostagem que o `Δ_canc` do R9 não enxerga.
3. Postagem-sonda de 1 unidade como medida ativa de quem cobre e em quanto tempo (4.2, estágio C).
4. Triagem barata pela diferença entre resumos, com teste de correlação e regra de abandono (4.2, estágio A).
5. Veredito com motivo em uma frase por linha (4.3; 6.2): formato de tela que cumpre a regra 4.
6. Hipóteses de API: `SearchForItemKeys` em lote e o terceiro argumento de `StartCommoditiesPurchase` (4.2; 3.3); S2 testa tecla e mouse no mesmo passo (8).

## 4. Ordem pela minha lente

1. **D4-risco**: a engenharia mais defensiva e a bancada mais forte; erra para o lado seguro.
2. **D5-ouro**: o menor e o mais barato de provar; mede antes de construir.
3. **D1-quant**: o melhor tratamento formal de incógnita, pago com tamanho.
4. **D3-mesa**: os melhores contratos de dados, numa arquitetura que depende de `/reload` no meio da sessão.
5. **D2-operador**: o melhor caminho de tecla e de stream, com lacunas de engenharia fora dele.
6. **D6-concorrencia**: boa bancada, centro apoiado em incógnita.

D3 e D2 empatam em viabilidade, risco e testabilidade somados. Desempatei pela disciplina de fato: o D3 marca mais incógnitas e o D2 deixa sem tratar orçamento por quadro e gravação do banco.

## 5. Espinha recomendada

**Base: D4-risco.** É o único esqueleto em que a regra 1 e a regra 2 são invariantes testáveis, e o único que erra para o lado seguro quando a base não sabe. O que falta nele é andamento, e isso os outros dão.

**O que entra de cada um.**
- **D5**: a ordem de entrega. Onda 0 sem código, régua antes de motor, resultado medido e limiar de parada por onda, e a venda com saída no vendedor como motor da fase 1.
- **D2**: a operação. Cartão e fila com eco, `T_ver` com latência, sonda de tecla segurada, cursor estacionado, casos de operador e modo treino.
- **D3**: os contratos. Sequência e recibo, sentinela, modos de mesa, correção do `η_real`, hipótese do `PostItem` da bolsa.
- **D1**: o método. Hipóteses numeradas, motor puro com checador 5.1 e 5.3, duas chaves, diário de calibração, duas testemunhas.
- **D6**: bancada com agentes plantados e regras antiguerra já; ficha de terreno e mapa de concorrentes só na fase 3, se a sonda mostrar `owners`.

**Conflitos que a síntese precisa decidir, com a minha posição.**

| # | Conflito | Posição |
|---|---|---|
| 1 | Teclas por ação: uma tecla universal (D2 `K`, D5 `F6`), verbos separados (D1, D3, D6) ou duas sempre (D4) | Verbos separados. Uma tecla para postar, cancelar e arrematar item abaixo de um teto; segunda tecla na cotação de commodity, no aviso do jogo e acima do teto. O "duas sempre" do D4 mata o uso; a tecla universal convida erro de modo. |
| 2 | Ação sem resposta: `FALHOU` e tecla rearmada (D3 em 5 s, D5 em 10 s) ou `INCERTO` com conciliação (D1, D4, D6) | `INCERTO`. Com falha muda (base 2.12) e throttle desconhecido (base 2.14), rearmar a tecla é o caminho para ação em dobro. |
| 3 | Gatilho da varredura: portão de presença de 90 s (D1, D2) ou uma tecla por volta (D3, D4, D5, D6) | Fôlego com orçamento: qualquer tecla do terminal abre ou renova, com teto de tempo e de pedidos (D4 3.4). Dá a cadência que a inferência pede sem laço solto. |
| 4 | Correio: só leitura e clique do dono (D4, D5, D6), tecla ligada ao Open All da Blizzard (D2, D3) ou uma carta por tecla (D1) | Só leitura na fase 1. A sonda mede primeiro se a fatura lê sem abrir a carta e se o binding num botão da Blizzard funciona sem taint; a tecla entra depois, se passar. |
| 5 | Onde mora o motor: no jogo (D1, D2, D4, D6), fora (D3) ou quase nenhum (D5) | Decisão pura no jogo com estado pequeno; mesa só entre sessões, para arquivo, calibração e replay. `/reload` no meio da sessão é ponto de salvamento, não canal. |
| 6 | Banca: personagem logado (D1, D4) ou os quatro pelo Syndicator (D3) | Personagem logado. A base 4.2 diz que não há banco de conta. |
| 7 | Conta de compra: R9 5.1 como está (D1, D2, D4, D6) ou com o desconto no ganho (D3) | A do D3. A outra reprova tudo abaixo de 100% de margem. |
| 8 | Nomes de vendedor: guardar (D6), só hash (D3) ou nada | Hash no banco; nome só na tela, a partir da foto do momento. O módulo inteiro espera a sonda de `owners`. |
| 9 | Quantidade maior que 1 numa tecla em item (D1, D2) ou 1 por tecla (D4) | 1 por tecla na fase 1. O multisell entra na sonda e vira decisão do dono, porque toca a regra de uma postagem por tecla. |
| 10 | Fase 1 com tecla de ação: nenhuma (D3), postar e cancelar (D1, D4, D6), também comprar para o vendedor (D2, D5) | Postar e cancelar depois do primeiro passo da sonda; compra só para o vendedor, em micro, com lote de confirmação. |
| 11 | Ordem entre preços iguais: teste com segundo jogador (D2, D4) ou passivo (D3, D5, D6) | Passivo. Compra combinada entre conhecidos é o tipo de desenho que a base 1.10 manda evitar. |
| 12 | Tamanho do banco: 2 MB (D5) a 8 MB (D1) | Começar em até 3 MB e medir o reload com 1, 3 e 5 MB (D2, S8) antes de crescer. |
| 13 | Nome: PregaoForever ou NichoForever (D6) | PregaoForever. O nicho é um módulo, não o produto. |

## 6. Lacunas que nenhum projeto fecha (para a síntese escrever como hipótese a medir)

1. **Fatura antes de abrir a carta.** Só o D4 marca; tem de entrar na sonda de todos os fluxos de correio.
2. **Quantas vezes o clique por binding dispara.** Nenhum projeto pergunta se o clique sai ao apertar, ao soltar ou nos dois. Hipótese a medir junto com a tecla segurada; a guarda de uma chamada por clique cobre os dois casos.
3. **O que `minPrice` do resumo significa em item que não é commodity** (lance ou arremate). A base 2.1 diz só "menor preço". Todos reconferem na escada antes de gastar, o que basta; a triagem precisa dizer isso.
4. **Convívio com a tela da Blizzard e com o Auctionator abertos.** A regra de um pedido em voo só vale para os pedidos do próprio addon. D5 3.2 e D2 3.4 tocam no assunto; a síntese precisa de uma regra: resposta que não é do pedido em voo é descartada, e foto que encolhe é incompleta.
5. **Gravação das SavedVariables no build atual** (R6b, incógnita 4): primeira conferência da sonda, como fazem D3 e D6.
6. **Orçamento por quadro**: D1, D3 e D4 fixam 2 ms por relógio; D2 e D6 não dizem nada. A síntese deve levar o fatiador por tempo e a máquina de estados explícita como padrão, com corrotina só se a sonda confirmar (D1 H-01).
