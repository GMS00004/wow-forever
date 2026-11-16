> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# PregaoForever: design único do addon de trading (síntese)

Data: 2026-11-16. Etapa de design: nenhuma linha de código de addon foi escrita. Este texto vai à revisão adversarial, depois ao dono, e por fim a uma sessão nova do agente, que o usa como contrato de implementação sem nenhum outro contexto.

**Como ler.** `(base 2.7)` é o item 2.7 da base de fatos; `(R9 5.1)` e `(R8a ficha 5)` são relatórios da pesquisa; `(D4 3.1)` é a seção de um dos seis projetos, D1 a D6; `(J2)` é um parecer; `DD3` é a decisão do dono número 3 (seção 18). **H-nn** marca hipótese a medir, listada na seção 2.2. **[TECLA x]** marca o ponto em que entra a tecla do dono. Número de configuração é escolha de projeto, não fato do jogo. Itens e valores das telas desenhadas são ilustrativos.

**De onde veio.** A espinha é o projeto D4: invariantes, Cofre, tetos duros, licença por nível e estado INCERTO. J1 e J3 pediram o D4 como base e J2 pediu o D5, mas os três querem a mesma soma. Fico com o D4 na estrutura porque invariante atravessa todo arquivo e não se enxerta depois; a ordem de entrega do D5 se enxerta, e conserta o defeito mais grave do D4, que é fazer pouco. Os demais enxertos e a resposta a cada ponto dos juízes estão na última seção.

## 0. Resumo

**O que o addon é.** Um terminal de leilão com três peças. A **régua** é o livro que mede cobre por ação, por hora e por estratégia, e troca cada estimativa do jogo por número lido. A **fila** mostra até cinco linhas do que vale fazer agora com a banca que existe. A **mão** executa: cada compra, postagem e cancelamento sai de uma tecla do dono, uma por ação, depois de passar pelo **Cofre**, o núcleo de risco, que nega na dúvida.

**De onde vem o lucro, sem promessa.** Com 50.912 cobre somando quatro personagens (base 4.1), o que aperta é capital e giro, não tecla nem modelo. Um giro completo da banca a 10% ou 15% de margem rende de 50 a 75 prata, e o ouro de cada venda volta pelo correio em cerca de 1 hora (base 1.8). A ordem das fontes de ganho é esta:

1. **Vender bem o que os quatro personagens já produzem** (base 4.2): leilão ou vendedor, a que preço, por quanto tempo. Só o depósito fica em risco, e é a única linha com fonte de economia já aprovada pelo dono (base 4.5).
2. **Arbitragem de saída certa**: arrematar abaixo do preço que o vendedor NPC paga. Mede-se de graça nas primeiras varreduras e só liga se o número mandar.
3. **Compra para revenda**, só em **papel** (sinal registrado, sem gastar ouro) até o diário do próprio addon mostrar margem depois de corte, depósito e teclas.

O que os fatos sustentam dizer ao dono: com 5 ouro o addon não o deixa rico por trading. Ele vende melhor o que os personagens produzem, mede o mercado e prova, com números dele, se e quando comprar para revender paga.

**O que ele nunca faz.** Agir sem tecla ou clique do dono; fazer mais de uma ação por tecla; chamar ação de timer, evento ou `OnUpdate`; repetir sozinho uma ação que falhou; simular entrada; ter algo que evite a marca de ausente; contornar função protegida, evento de hardware ou secret value; pegar correio, vender ou comprar no NPC por código; ter configuração, caixa de texto ou fonte na tela; ler código de addon de terceiro; gravar nome de jogador; enviar dado para fora do jogo; propor preço fora do mercado; ligar estratégia sem fonte aprovada.

**O que o dono decide antes da primeira linha de código.** São oito pontos: tecla para postar e cancelar (DD1a); tecla para comprar (DD1b); correio (DD1c); coexistência com o Auctionator e o ForeverGuide (DD2); fontes e regra de preço da venda (DD3); negociador, banca e piso pessoal (DD4); mapa de teclas (DD5); e nome (DD6). As opções e a recomendação de cada um estão na seção 18.

## 1. Regras que valem para todo arquivo

O `ARQUITETURA.md` do addon abre com estas regras, no formato dos outros addons do projeto (R4a 2). O checador novo confere as que são estáticas (seção 16).

| # | Regra |
|---|---|
| 1 | Lua 5.1, só ASCII, comentários em português sem acento. Nomes de arquivo e de função em português, sem acento; APIs e eventos com o nome do cliente (base 4.8). |
| 2 | Todo arquivo abre com `local _, ns = ...`. Globais só com os prefixos `PregaoForever`, `SLASH_PREGAOFOREVER` e `BINDING_`. |
| 3 | Toda função de evento, timer ou clique roda em `xpcall(fn, geterrorhandler())`, pelo embrulho `ns.seguro`. |
| 4 | Quadro da Blizzard só por `hooksecurefunc`, `HookScript`, `EventRegistry` ou `TooltipDataProcessor`. Nenhuma aba no `AuctionHouseFrame`, que causaria taint: a janela é própria (base 4.8; base 7). |
| 5 | Addon de terceiro só por chamada em tempo de execução, com `pcall`, em `Pontes.lua`. Código de terceiro não é lido nem copiado (base 7). |
| 6 | As oito **funções de ação** só aparecem em `Acoes.lua`, dentro de funções de prefixo `tecla_`, chamadas apenas pelo `OnClick` de botões do addon. `Acoes.lua` não tem `C_Timer`, `OnUpdate` nem `RegisterEvent`; as respostas são tratadas em `Ecos.lua`, que não pode agir. |
| 7 | Uma tecla aceita gera no máximo uma chamada de função de ação. |
| 8 | Toda chamada de ação vem, no mesmo clique, depois de `Cofre.autoriza` e de `Livro.intencao`. |
| 9 | Nenhuma consulta ao servidor fora de um **fôlego**: uma rodada limitada de consultas que nasce de uma tecla do dono e termina sozinha. Uma consulta em voo por vez, todas por `Pedidos.lua`. |
| 10 | Proibidos no addon inteiro: `TakeInboxMoney`, `TakeInboxItem`, `AutoLootMailItem`, `SendMail`, `BuyMerchantItem`, `UseContainerItem`, `SetCVar`, `SetBinding`, `SaveBindings`, `RunScript`, `loadstring`, `:Click(`, `EditBox`, `SendChatMessage`, mensagem de addon e tecla `MOUSEWHEEL` em botão de ação. `ReplicateItems` só em `Sonda.lua`. `SetOverrideBindingClick` só aponta para botão `PregaoForever*`. |
| 11 | Nada se configura no jogo. `/pregao` abre a janela, mostra o estado e inicia a sonda. A configuração vive no `Config.lua`, escrito pelo agente (base 4.7). |
| 12 | Texto de tela em inglês, sem fonte e sem acento; cada seção com até 5 linhas e `Show N more`; estado sempre em palavra, nunca só em cor; nada que só exista em tooltip (base 4.7, 8.4). |
| 13 | Só `Tetos.lua` define teto duro; a configuração só aperta. O nível de uma estratégia só desce dentro do jogo; subir é edição de arquivo. |
| 14 | Os arquivos puros (`Estimadores.lua`, `Motor.lua`, `Sombra.lua`) não tocam global do jogo e ficam no subconjunto comum a Lua 5.1 e 5.3, porque a bancada roda em fengari, que é 5.3 (R4a 4). |
| 15 | Tempo por relógio (`GetTime`, `GetServerTime`), nunca por contagem de quadros; trabalho pesado em fatias de 2 ms (base 3.3, 3.8; R9 11.1). |
| 16 | Binding e ação só fora de combate e sem restrição de addon ativa (base 3.4, 2.16). |
| 17 | Dinheiro em cobre inteiro. Depósito sempre lido de `CalculateItemDeposit` ou `CalculateCommodityDeposit`; preço de vendedor sempre lido de `C_Item.GetItemInfo` na hora (base 1.4, 3.2, 6.3). |
| 18 | Todos os `.lua` na raiz do addon e no `.toc` desde a onda 1: o `checar-lua.mjs` só lê o primeiro nível (R4a 3) e arquivo novo pede reinício do jogo (R4a 6). TOC com `## Interface: 16001`, `## Author: Bruno`, `## SavedVariables: PregaoForeverDB` (base 4.8). |
| 19 | Nem o addon nem a mesa escrevem na pasta do jogo. A ligação é a junction do `dev-link.ps1`, feita uma vez com o jogo fechado; depois, editar na pasta de desenvolvimento e dar `/reload` (base 4.4, 4.9, 4.11). |
| 20 | Nome de jogador nunca é gravado. |

**Funções de ação** são as 7 que levam `HasRestrictions` (`PostItem`, `PostCommodity`, `ConfirmPostItem`, `ConfirmPostCommodity`, `PlaceBid`, `StartCommoditiesPurchase`, `CancelAuction`; base 2.12) mais `ConfirmCommoditiesPurchase`. A wiki diz que esta última não exige evento de hardware (base 2.13); o design a trata como se exigisse. É a regra de conformidade do D4: onde a base diz "não se sabe se pode", o addon age como se não pudesse.

## 2. Fatos em que o design se apoia e o que falta medir

### 2.1 Fatos

A tabela reúne os fatos que moldam o desenho inteiro; os demais vêm citados no ponto em que são usados.

| Assunto | Fato usado | Base |
|---|---|---|
| Mercado | Um mega-reino por conjunto de regras e região, com mais de 200 mil leilões numa varredura relatada; casa separada por facção é inferência. | 1.2, 1.3 |
| Taxas | A tabela do cliente tem `DepositRate 5` e `ConsignmentRate 5`; a fórmula é inferência. O **depósito** (pago ao postar) vem das funções de cálculo e o **corte** (a parte da venda que a casa retém), da fatura do correio. | 1.4 |
| Durações | 2, 8 e 24 horas, índices 1, 2 e 3; quatro faixas de tempo restante. | 1.5, 1.6 |
| Depósito mínimo | 1 prata até 17/11, depois 1 cobre. Volta na venda e se perde na expiração e no cancelamento (regra do Classic, a medir). | 1.7 |
| Correio | O ouro da venda chega com cerca de 1 hora de atraso. Ler a caixa usa globais antigas sem documentação; a fatura traz lance, arremate, depósito e consignação. | 1.8, 3.1 |
| Consulta resumida | Por chave de item: `minPrice`, `totalQuantity` e `containsOwnerItem`, sem a **escada** (a lista de preços e quantidades à venda); sem limite escrito. | 2.1, 2.2 |
| Busca por item | 100 por minuto pela documentação. Devolve a escada de uma **commodity** (item empilhável vendido por quantidade), por degrau, ou os leilões de um item, um a um. | 2.2 a 2.4 |
| Compra | Commodity: pedir cotação, receber o total por evento, confirmar; a tela da Blizzard tolera cotação 5% acima. Item: `PlaceBid` com o valor do arremate. | 2.7, 2.8 |
| Postagem | `PostItem` e `PostCommodity` devolvem `needsConfirmation`; há um evento de leilão criado, feito para addons. | 2.9 |
| Leilões próprios | Consulta, estado Active ou Sold, custo e função de cancelar. Avisos de venda e expiração chegam mesmo com o leilão fechado. | 2.10, 2.11 |
| Ações | As 7 funções restritas não dão erro quando a condição falha: só não fazem nada. A wiki diz que exigem tecla ou clique; nada foi testado no Forever. | 2.12, 2.13 |
| Chave de item | `itemID`, `itemLevel`, `itemSuffix`; como um verde com sufixo aparece é incógnita. | 2.15 |
| Cliente | Preço de vendedor no 11º retorno de `C_Item.GetItemInfo`. Binding de sobreposição liga tecla a botão enquanto a janela está aberta e não muda em combate. Foco em caixa de texto engole as teclas. Em segundo plano, 30 quadros por segundo. SavedVariables só vão ao disco no `/reload`, no logout e ao fechar. | 3.2, 3.4, 3.8, 3.9, 8.1 |
| Dono | Quatro personagens da Aliança, sem banco de conta. Em 2026-11-06 proibiu, no outro addon, funções que compram ou gastam por código. Nada configurado no jogo; decide vendo quadro. | 4.2, 4.6, 4.7 |
| Gameplay | Nenhum agente opina; a única fonte de economia aprovada é o vídeo do Studen Albatroz (verde bom vai ao leilão; não vale vender todo o couro). | 4.5 |

Um cuidado: a base 6.1 resume a semana 2 como queda de 41% na mediana listada e manda tratar como direção. O relatório por trás mostra os materiais de nível baixo subindo na mesma semana e listando bem acima do vendedor (R5b 2a, 2b). O design não supõe deflação geral nem taxa diária de queda: mede a deriva por categoria (seção 7.4) e espera que anúncio de material abaixo do vendedor seja raro.

### 2.2 O que falta medir no jogo

Cada hipótese tem a medida da **sonda** (o roteiro de medidas no jogo, Apêndice A) e o que o design faz se ela for negada.

| # | Hipótese | Sonda | Se for negada |
|---|---|---|---|
| H-01 | O clique de um botão do addon acionado por binding de sobreposição satisfaz as funções de ação (base 11.1). | S2 | O dono clica o mesmo botão com o mouse. Se nem isso valer, fica o modo leitura. |
| H-02 | Uma pressão gera um clique só; tecla segurada não repete, local e pelo acesso remoto. | S2 | As guardas de repetição cobrem os dois casos. |
| H-03 | As SavedVariables gravam no `/reload` nesta build (há relatos contrários de builds antigas, R6b incógnita 4). | S1 | O projeto para: sem gravação não há régua. |
| H-04 | Empilháveis são commodity; um verde com sufixo tem chave própria (base 11.2). | S0, S3 | O caminho de postagem segue `GetItemCommodityStatus` item a item; verde sem chave separável fica sem referência. |
| H-05 | A consulta resumida inteira custa segundos e poucos pedidos, e pode ser repetida a cada 10 minutos (base 2.6 é relato; base 11.3). | S4 | Resumo por categoria, em rodízio, ou um por sessão. |
| H-06 | Consulta fora de clique funciona, e a prontidão do throttle vale para consultas (a Blizzard as chama de evento, R1b 14; inferência). | S4 | Cada consulta do fôlego sai direto de uma tecla. |
| H-07 | O `minPrice` do resumo, em item que não é commodity, é o menor arremate. | S4 | Tanto faz: o resumo só faz triagem e a escada reconfere. |
| H-08 | A tela da Blizzard e outro addon de leilão abertos interferem nas respostas (a lista da Blizzard relê os resultados a cada evento, R1b 8). | S4 | Vale a regra de descarte da seção 5.2. |
| H-09 | O depósito cobrado é o lido; o corte é o da tabela; o depósito volta na venda e se perde nos outros desfechos (base 11.6). | S6 | O medido substitui o de partida; nada no código assume fórmula. |
| H-10 | Item cancelado e item comprado chegam pelo correio, com atraso (existe o evento `AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE`, R1a evento 10; a base 1.8 só dá os assuntos). | S6, S8 | Se chegam direto à bolsa, cancelar fica mais barato. |
| H-11 | A fatura pode ser lida antes de a carta ser aberta (no espelho a Blizzard só chama `GetInboxInvoiceInfo` com a carta aberta: `MailFrame.lua` 573 a 576 e 790). | S7 | A conciliação usa cabeçalhos e a variação do dinheiro. |
| H-12 | O atraso do correio da venda é de cerca de 1 hora (base 11.10). | S7 | O caixa projetado usa o medido. |
| H-13 | `owners` e `timeLeftSeconds` vêm preenchidos (base 11.5). | S5 | Nada nas fases 1 e 2 depende deles. |
| H-14 | Entre preços iguais vende primeiro o mais antigo, o pior caso para quem iguala (base 2.17). | S10 | O medido troca o pior caso. |
| H-15 | `PostItem` aceita o item direto da bolsa por `ItemLocation`; o que a quantidade maior que 1 faz não foi visto (multisell, R1b 6). | S2 | O dono posta pelo painel da Blizzard e o addon aconselha. |
| H-16 | Deixar um aviso de postagem sem confirmar não deixa nada pendente; o que dispara o aviso é desconhecido (R1b incógnita 7). | passiva | Cada aviso é gravado para descobrir a regra. |
| H-17 | `StartCommoditiesPurchase` funciona com dois argumentos (a tela da Blizzard passa um terceiro, R1b 4). | S8 | Passa-se o preço unitário como terceiro. |
| H-18 | A cotação dura o bastante para ler e confirmar pelo acesso remoto (R1b incógnita 6). | S8 | Commodity por tecla fica inviável; sobram item e venda. |
| H-19 | `ReloadUI` chamado do clique de um botão do addon é aceito, e o `/reload` é rápido com 1, 3 e 5 MB (R1c 13 só confirma que a função existe). | S1 | A tela pede `/reload` digitado; o teto do banco não sobe. |
| H-20 | `debugprofilestop` ou `GetTimePreciseSec` medem a fatia de 2 ms (R1c 5). | S1 | Fatia por contagem de linhas. |
| H-21 | O preço de vendedor lido do cliente é o que o NPC paga (base 6.3). | lote de confirmação | O item sai da arbitragem. |
| H-22 | Uma oferta abaixo do vendedor vive mais que o tempo de reação do dono. | papel | A arbitragem de vendedor não liga. |
| H-23 | Personagem de nível baixo usa o leilão (R5a 2.5 não achou restrição). | S0 | Muda a escolha do negociador. |
| H-24 | Tempos de ausência com o leilão aberto (base 11.9). | o dono anota | O addon não mede nem interfere. |
| H-25 | Os eventos de leilão criado, cancelado e comprado chegam ao addon também quando a ação parte de outra tela. | S9 | A régua só mede o que passa pelo addon e pelo correio. |

## 3. Tese de mercado e estratégias

### 3.1 Tese

O mercado é um só por conjunto de regras, enorme (base 1.2), e os concorrentes chegam com varredura completa, sniper e postagem assistida (base 5.1 a 5.3). O dono age uma tecla por vez, por acesso remoto (base 4.11). A corrida de reflexo está perdida por construção e o design não a disputa. Sobram três coisas que dependem de dado e de disciplina:

1. **Custo real medido.** A Blizzard não publicou corte, depósito nem devolução (base 1.4). Em item barato é o depósito que decide entre leilão e vendedor. Exemplo com a leitura provável da base 1.4 e 1.7, que é hipótese (H-09): um verde com preço de vendedor de 50 cobre e menor preço de 2 prata, por 24 horas, precisa hoje de 42% de chance de venda para empatar com o vendedor (depósito mínimo de 1 prata) e de 18% depois de 17/11 (depósito de 30 cobre).
2. **Venda calibrada do próprio estoque.** Nenhuma ferramenta vê a venda dos outros (base 5.8). As vendas do próprio dono são o dado mais limpo que existe sobre chance de venda, corte e tempo até o ouro voltar.
3. **Capital que não se perde.** Com 5 ouro, um erro de 50 prata custa 10% da banca.

### 3.2 Estratégias

Todas nascem com `licenca = 0`. A fonte fica no `ARQUITETURA.md` e em comentário de `Estrategias.lua`, nunca na tela. Calcular preço e ponto de equilíbrio não é estratégia: é conta sobre o que o dono decidiu vender. Os catálogos são R8a (fichas 1 a 8) e R8b (recomendações R1 a R15).

| Id | Estratégia | Fonte | Sinal mensurável | Regra | Risco | Condição para ligar |
|---|---|---|---|---|---|---|
| `venda_verdes` | Vender no leilão os verdes bons | Vídeo do Studen Albatroz, a única fonte aprovada (base 4.5). Quais verdes são bons é juízo do dono: o addon lista e ele posta ou pula. | Ponto de equilíbrio `P*` contra a frequência de venda medida | Seção 7.2. Equipamento sempre iguala (base 1.11). | Depósito perdido (base 1.7); erro ao postar (base 1.11); verde sem referência (H-04) | DD1a; H-01 confirmada; depósito lido depois de 17/11 |
| `venda_sobras` | Vender sobras de coleta | R8b R4 (vender cru), R7 (lotes e rechecagem), R8 (nunca abaixo do vendedor), R14 (lote em tamanho de receita), R15 (leilão curto para o que gira). Guias de fã ou comerciais, do beta. | O mesmo, mais a quantidade na frente | Seção 7.2. A lista `reservas` protege o que alimenta as profissões: o couro do Hexumlite segue o roteiro de Leatherworking (R4b 4). | Preço em movimento; cobertura em minutos (R8b R7, editorial) | O dono aprova a fonte e escolhe a regra de preço (DD3) |
| `piso` | Arrematar abaixo do preço que o vendedor paga | R8a ficha 5: confiança baixa e nenhuma fonte do Forever para o fluxo. A conta é aritmética (R9 5.4). | Cobre disponível abaixo do preço de vendedor por varredura; taxa de "já sumiu" | Seção 7.3. O addon não vende ao NPC: marca o item e o dono clica. | Preço de vendedor mudado por hotfix (base 6.3); bolsa cheia; concorrentes com o mesmo recurso (R6a) | DD1b; S8; três varreduras de prova em papel; lote de confirmação por item |
| `vao` | Comprar a frente da escada e repostar no vão | R8a ficha 2 (fã e guia genérico; alerta de isca em F23) | Razão entre o degrau seguinte e o preço médio pago acima de `(1 + margem)/(1 − c)` mais custos (R9 5.3); venda inferida no preço de saída | Seção 7.4; só commodity, até 2 degraus | O vão fecha com oferta nova; estoque parado; isca | Portão de papel; corte e devoluções medidos; banca de 15 ouro; aprovação |
| `sniper` | Arrematar abaixo do valor medido, por nomeação | R8a ficha 1 (documentação do TSM de 2022, do Classic; nenhuma fonte do Forever) | Preço até o limiar derivado por item (R9 5.2), com a saída calculada na escada que sobra | Seção 7.4. O resumo nomeia, uma busca confirma, o teste completo roda antes de armar a tecla. | Valor velho; preço novo confundido com pechincha; outros snipers; "item not found" (base 1.11) | Portão de papel; "já sumiu" até 70% em 30 sinais; aprovação |
| `conversao` | Produzir com receita do personagem logado | R8a ficha 6 (descrição pública do addon Arbitrage; tabelas antigas) | Lucro da receita com insumo e produto lidos das escadas (R9 5.5) | Só receita que `C_TradeSkillUI.GetRecipeSchematic` devolve (base 3.7) e produto que não vincula (R4b 5e). Quem fabrica é o dono. | Produto sem saída; rendimento desconhecido em 526 receitas (base 9.2) | Fase 3 |

**Só medição, sem ordem de compra.** Hora e dia da semana: nenhuma fonte mede o ciclo no Forever (R8b ficha 1; base 6.5); o addon guarda o menor preço por bloco de 4 horas e, com três semanas, a mesa mostra se há ciclo. Abertura das raides em 2026-12-09 (base 6.4): só previsão de autor (R8b ficha 3); fica uma lista de observação. Vendedor com estoque limitado: sem fonte do Forever (R8a 9.3); quando o dono abre um vendedor, o addon anota `numAvailable` (base 9.3).

**Fora, com motivo.** Reset: só folclore (R8a ficha 4), valor esperado negativo em item líquido no modelo pessimista (R9 6.3), e é o padrão mais parecido com o sinal da base 1.10. Formação de mercado com spread: sem fonte (R8a ficha 3). Lance em leilão acabando: fonte do retail (R8a ficha 7) e sem teste possível por fotos (R9 10.2). Casa neutra: fonte de fã e taxas de 25 e 15 na tabela (R8a ficha 8; base 1.4). Equipamento para revenda: a fonte desaconselha (R8a F18) e a chave é incerta (base 2.15).

### 3.3 O modo papel: como o dado do addon vira evidência

Cada estratégia tem uma **licença** em quatro níveis: 0 desligada, 1 papel, 2 micro, 3 plena. O nível em vigor é o menor entre a licença que o dono aprovou no `Config.lua`, o nível que a evidência sustenta e o imposto pelos disjuntores. São as duas chaves do D1 na forma do D4. A evidência é avaliada na carga do addon; dentro do jogo o nível só desce.

- **Papel.** O sinal aparece na fila com a marca `PAPER`. A tecla de compra não chama função de ação: relê a escada, grava se a oferta ainda estava lá e registra a ordem de papel. `Sombra.lua` calcula o desfecho com preenchimento conservador: a compra só conta se a oferta estava na releitura; a venda só conta pelas **vendas inferidas** (as que se deduzem da diferença entre duas fotos da escada) com prioridade pior que a do lote (R9 10.2).
- **Papel para micro** (`vao`, `sniper`): 30 sinais fechados em 5 dias ou mais; resultado positivo, e ainda positivo sem os 3 melhores sinais; razão entre realizado e previsto de 0,5 ou mais; corte e devoluções medidos. Para `piso`: três varreduras em horários diferentes com valor por tecla acima do dobro do tíquete (o valor mínimo por tecla, seção 7.5). Em micro, cada ordem tem o teto da seção 9.2.
- **Micro para plena**: 30 lotes reais fechados; realizado sobre previsto de 0,5 ou mais; resultado positivo; nenhum INCERTO sem solução. Em plena vale só o teto por item.
- As vendas entram direto em micro, porque não compram: só o depósito fica em risco.
- A tela mostra `eligible`. Subir é uma linha no `Config.lua`, escrita pelo agente depois do sim do dono, com a data em `aprovadaEm` e o registro em `estado.md`.

A regra de preço por `W*` (o valor de liquidação do R9 4.1) não tem fonte pública e o R9 não tem revisor (base 10). Ela roda só em **sombra**: o addon grava o desfecho hipotético de cada regra não escolhida e, com 50 desfechos por classe, o dono decide com a comparação na mão (D2 5).

## 4. Arquitetura

### 4.1 Módulos e ordem de carga

Pasta `wow/modder/addons-proprios/PregaoForever`, TOC conforme a regra 18, com `## OptionalDeps: Auctionator, Syndicator, Baganator, ElvUI`. Os 28 arquivos nascem como esqueleto na onda 1. A numeração é a ordem de carga.

| # | Arquivo | Responsabilidade |
|---|---|---|
| 1 | `Nucleo.lua` | `ns`, `ns.seguro`, eventos, relógios, cobre inteiro, anéis, log de 60 linhas, fatiador de 2 ms |
| 2 | `Tetos.lua` | Tetos duros como constantes |
| 3 | `Config.lua` | Do agente: modo, negociador, piso pessoal, teclas, licenças com `aprovadaEm`, regra de preço, limites, reservas, latência do acesso remoto |
| 4 | `Calibrado.lua` | Parâmetros medidos (valor, amostras, data), escrito pelo agente ou pela mesa; nasce neutro |
| 5 | `Dados.lua` | Gerado das tabelas do cliente, só para triagem (seção 13) |
| 6 | `Receitas.lua` | Fase 3; esqueleto vazio |
| 7 | `Banco.lua` | Esquema das SavedVariables, migração, poda, medidor, sequência e recibo |
| 8 | `Itens.lua` | Chave de item em texto; cache de item (preço de vendedor ao vivo, commodity ou item) |
| 9 | `Pedidos.lua` | Porta única das consultas: fôlego, orçamento, vigia do throttle |
| 10 | `Varredura.lua` | Máquina de varrer |
| 11 | `Escada.lua` | Resposta em degraus, sem as unidades próprias, com marca de completude; foto compacta |
| 12 | `Estimadores.lua` | Puro: referência com filtro de isca, parede, diferença de escadas, frequências, deriva |
| 13 | `Motor.lua` | Puro: valor de uma tentativa, ponto de equilíbrio, candidatos, teste de compra, ordem da fila |
| 14 | `Sombra.lua` | Puro: desfecho hipotético do papel e das regras não escolhidas |
| 15 | `Estrategias.lua` | Registro, licença em vigor e gerador de sinal de cada estratégia |
| 16 | `Cofre.lua` | Banca, estados do ouro, tetos, disjuntores, `autoriza(ordem)`, conciliação |
| 17 | `Livro.lua` | Régua: ações, lotes, sinais com desfecho, sessões, amostras de calibração |
| 18 | `Acoes.lua` | Único arquivo que chama as funções de ação; só o lado do clique |
| 19 | `Ecos.lua` | Eventos de resposta e prazos das ações; não pode agir |
| 20 | `Teclas.lua` | Botões nomeados, bindings com a janela aberta, filtro de repetição, pausa |
| 21 | `Correio.lua` | Lê cabeçalhos e faturas, concilia; não pega nada |
| 22 | `Sonda.lua` | Roteiro de medição, um passo por cartão |
| 23 | `Pontes.lua` | Interoperação com `pcall` (seção 14) |
| 24 | `Visual.lua` | Cópia do kit `ns.ui` do GuiaForever, que é do dono (base 7.5) |
| 25 | `Alertas.lua` | Faixa de texto, `FlashClientIcon`, `PlaySound` (base 3.6) |
| 26 | `Janela.lua` | Casca: abre com `AUCTION_HOUSE_SHOW`, fecha com `AUCTION_HOUSE_CLOSED` |
| 27 | `Telas.lua` | As cinco visões, o painel do correio e o cartão da sonda |
| 28 | `PregaoForever.lua` | Eventos de vida e `/pregao` |

### 4.2 Fluxo dos dados

```
[TECLA L] -> Teclas -> Pedidos (folego) -> Varredura -> Escada (foto) -> Banco
                                               |
                               Estimadores -> Motor -> Estrategias (sinais)
                                                            |
             Telas <- bilhete <- Cofre.autoriza(ordem) <----+
               |
[TECLA B, P, C, Y] -> Teclas -> Acoes (OnClick: Cofre, Livro.intencao, 1 funcao de acao)
                          evento de eco -> Ecos -> Livro -> Cofre (concilia) -> Telas
                          sem eco no prazo -> INCERTO -> conciliacao -> Livro
[caixa de correio aberta pelo dono] -> Correio (so le) -> Livro -> Cofre
[TECLA Y na visao Session] -> ReloadUI -> SavedVariables no disco
                          -> agente ou mesa -> Config.lua, Calibrado.lua -> proximo /reload
```

O **bilhete** é o resumo de uma ordem que gasta (total, teto, fração da banca, saída), mostrado antes da tecla que a executa. O **eco** é o evento do jogo que confirma uma ação. Nenhuma seta sai de `Estimadores`, `Motor` ou `Estrategias` para `Acoes`: o caminho até a API passa sempre por uma tecla e pelo Cofre.

### 4.3 Modos e máquinas de estado

O campo `modo` do `Config.lua` tem três valores. Em `leitura`, os botões de ação nem são ligados: a fila aponta, o dono age pela tela da Blizzard e a régua mede. Em `papel`, toda licença fica limitada a papel. Em `vivo`, valem as licenças de cada estratégia.

As máquinas são sete, todas explícitas, sem corrotina: Pedidos, Varrer (seção 5.2), Comprar commodity, Comprar item, Postar, Cancelar e INCERTO (seção 8.3). Uma ação em voo por vez. Timer e evento só mudam estado; nunca chamam ação.

## 5. Coleta

### 5.1 Planos de varredura

| Plano | Consulta | Traz | Quando |
|---|---|---|---|
| A, resumo | `SendBrowseQuery` com texto vazio; `RequestMoreBrowseResults` até `HasFullBrowseResults` (base 2.1) | menor preço e quantidade total por chave | Uma vez por fôlego, se o último tem mais de 10 minutos |
| B, próprios | `QueryOwnedAuctions` (base 2.10) | estado, quantidade, tempo e preço de cada leilão do dono | Todo fôlego |
| C, foco | `SendSearchQuery` por chave (base 2.2) | escada de commodity ou leilões de item | Até 20 chaves por fôlego |
| D, cabeça | uma `SendSearchQuery` da linha selecionada | a escada fresca daquela linha | Quando uma tecla de ação encontra foto vencida |

`ReplicateItems` não é usada nas fases 1 e 2 (base 2.5).

**O foco.** As até 20 chaves do plano C saem nesta ordem: itens vendáveis nas bolsas, não reservados; chaves com leilão próprio ativo; chaves cujo `minPrice` ficou abaixo do preço de vendedor de `Dados.lua` (triagem do `piso`); e, na fase 2, as de maior giro pela triagem barata do D6, `saida · minimo / (1 + k_t · tremor)`, calculada só com a diferença entre resumos. Essa fórmula é hipótese, a conferir contra o que as escadas medem.

### 5.2 A agenda sob throttle

O fôlego responde à base 8.2 (uma tecla por ciclo) e ao risco de um laço de consultas rodar horas sem o dono.

```
PARADO --[TECLA L]--> PROPRIOS (QueryOwnedAuctions -> OWNED_AUCTIONS_UPDATED)
PROPRIOS --> RESUMO (plano A, se vencido; le em fatias de 500 linhas)
RESUMO --completo--> TRIAGEM (monta o foco)
RESUMO --BROWSE_FAILURE, 10 s sem resposta ou lista que encolheu--> incompleto -> TRIAGEM
TRIAGEM --> FOCO (plano C, uma chave por vez)
FOCO --resposta completa--> grava a foto -> Estimadores -> FOCO (proxima)
FOCO --10 s ou parcial--> foto incompleta (nao atualiza nada) -> FOCO (proxima)
FOCO --20 buscas, 60 s ou fim da lista--> PARADO ("Press L")
qualquer --TRAVADO ou AUCTION_HOUSE_CLOSED--> PARADO, fila zerada
```

Regras de `Pedidos.lua`:

- Só envia com `IsThrottledMessageSystemReady()` verdadeiro (H-06), uma consulta em voo, até 30 buscas por minuto, que são 30% do limite documentado (base 2.2). O medido na sonda troca esses números.
- Vigia pelos eventos `AUCTION_HOUSE_THROTTLED_*` (base 2.14). "Não pronto" por mais de 30 s vira `TRAVADO`: o addon para de consultar, bloqueia ações e pede ao dono que feche e reabra o leilão. Dois `_DROPPED` encerram o fôlego.
- Convívio (H-08). O evento de busca traz a chave ou o `itemID` (R1a, eventos 39 e 44): resposta que não é do pedido em voo é descartada. O resumo não traz identificação: lista que encolhe ou muda de ordem entre duas respostas marca o resumo como incompleto.
- Uma tecla de ação também abre um fôlego curto: uma releitura antes de agir (plano D) ou até duas consultas de conciliação depois. **Foto velha, a tecla atualiza; foto fresca, a tecla age** (D5).
- Opção desligada por padrão, `folego.renova_com_tecla`: qualquer tecla do terminal dentro do fôlego o estende, até 180 s. Serve à inferência de vendas da fase 2.

### 5.3 O que cada foto grava

A **foto** é o registro de uma resposta do leilão, com hora e marca de completude.

| Foto | Campos |
|---|---|
| Resumo | hora do pedido e da resposta, pedidos gastos, `completa`; por chave, menor preço e quantidade. Guarda-se o último inteiro e, por dia, o mínimo e a quantidade de até 1.500 chaves. |
| Escada de commodity | até 12 degraus `preco:quantidade:donos`, a cauda em 8 baldes, as unidades próprias por degrau (`numOwnerItems`) e a marca de conta própria |
| Leilões de item | por leilão: `auctionID`, arremate, lance, faixa de tempo, quantidade, marcas de dono e de conta |
| Próprios | `auctionID`, estado, quantidade, tempo, lance, arremate |

Nome de vendedor não entra; de `owners` e `timeLeftSeconds` só se grava se vieram preenchidos (H-13). Foto incompleta, vencida ou vazia onde havia oferta não atualiza estimador nem gera sinal (R9 1.5). Zero linhas onde a foto anterior tinha oferta é **vazia suspeita**: é descartada, nunca lida como "tudo vendeu".

## 6. Banco

Uma tabela de conta, `PregaoForeverDB`, com seção por personagem para o que é dinheiro. Linhas em texto compacto no lugar de tabelas aninhadas, para encolher o arquivo (R9 11.3).

```lua
PregaoForeverDB = {
  esquema = 1,
  seq     = 0,      -- contador monotonico dos registros
  recibo  = 0,      -- ate qual seq o arquivo de fora ja guardou
  calib   = {},     -- [parametro] = { amostras, n, v, medido, em }
  itens   = {},     -- [chave] = "vend:tipo:pilha:conf"   (so itens tocados)
  resumo  = {},     -- ultimo resumo: t, completa, n, dados
  dias    = {},     -- [chave] = "dia:min:qtd;..."        (14 dias)
  fotos   = {},     -- [chave] = { "t|c|p:q:n,..." }      (anel por chave de foco)
  sinais  = {},     -- anel: sinal, nivel, bilhete, executou, desfecho
  pers    = {},     -- [nome] = { livro, lotes, proprios, cofre, correio }
  sessoes = {}, sonda = {}, log = {},
  fim     = 0,      -- sentinela: igual a seq quando o arquivo esta inteiro
}
```

| Chave | Limite | Tamanho estimado |
|---|---|---|
| `resumo` | 1 foto de cerca de 8 mil chaves (ordem de grandeza da base 2.6) × 14 bytes | 110 KB |
| `dias` | 1.500 chaves × 14 dias × 10 bytes | 210 KB |
| `fotos` | fase 1: 40 chaves × 16 fotos × 200 bytes; fase 2: 48 fotos de 300 bytes | 130 KB; 580 KB |
| `sinais` | anel de 2.000 × 120 bytes | 240 KB |
| `pers[nome].livro`, `.lotes` | anel de 2.000 ações × 100 bytes; 300 lotes | 240 KB |
| `calib`, `sessoes`, `sonda`, `log`, `itens` | 100 amostras por parâmetro; 60 sessões | 140 KB |

Total estimado: 1,1 MB na fase 1 e 1,6 MB na fase 2. Teto de 3 MB, que só sobe depois de a sonda medir o `/reload` com 1, 3 e 5 MB (H-19).

**Poda.** Anéis de tamanho fixo. Acima de 80% do teto saem primeiro as fotos com `seq` até o `recibo`, depois os dias além de 14. Lote aberto e ação sem conciliação nunca são podados.

**Gravação.** O banco só vai ao disco no `/reload`, no logout e ao fechar (base 3.9). A visão Session mostra `unsaved N actions, M min` e sugere salvar aos 45 minutos ou 50 ações. Se o cliente cair, o Cofre reconstrói a posição na abertura seguinte pelo que o jogo diz (dinheiro, leilões próprios, bolsas, faturas) e marca as linhas como `unreconciled`. O estado do jogo vale mais que o Livro.

## 7. Motor

### 7.1 Princípios

O motor propõe; quem autoriza é o Cofre. Como o R9 não passou por revisor (base 10), dele só decide o que tem modo de falha limitado. Leitura do cliente (corte, devolução, atraso, cadência) o addon adota sozinho quando a amostra fecha; ajuste estatístico a mesa troca dentro da faixa da tabela do R9 12-C; teto, margem, regra de preço e licença só mudam pelo `Config.lua`, com o sim do dono.

Do R9 entram na fase 1 a arbitragem contra o vendedor (5.4) e o filtro de isca (1.2); na fase 2, o teste de compra na escada pós-compra (5.1), as vendas pela diferença de escadas (2.1) e a regra de cancelar (4.6). O valor de liquidação `W*` (4.1) fica em sombra. Tabela de P(venda), sazonalidade, perfis de concorrente e Kelly ficam fora das fases 1 e 2: pedem fotos densas, nomes que são incógnita ou retorno bem estimado.

### 7.2 Venda do próprio estoque (fase 1)

Notação: preços em cobre; `v` é o preço de vendedor lido ao vivo; `c`, o corte; `d`, o depósito do lote lido da API; `du = d/n`; `rs` e `rx`, a fração do depósito devolvida na venda e na expiração.

**Referência.** A frente é o primeiro degrau depois do filtro de **isca**: degrau com menos de 5% da quantidade da janela seguido de salto de 15% ou mais não é frente (R9 1.2). A referência é **forte** quando a escada da mesma chave tem 5 leilões ou mais, ou é commodity com escada completa; **fraca** quando só existem outras variantes do mesmo `itemID` ou o último mínimo que o Auctionator viu (base 7.1); **nenhuma** no resto. Sem referência o addon não propõe preço: a linha diz `NO REFERENCE` e mostra o preço de vendedor e o depósito por duração.

**Candidatos.** São as regras que têm fonte; a escolha é do dono, por classe de item, no `Config.lua`.

| Regra | Preço | Fonte |
|---|---|---|
| `igualar` | o da frente | Contorno do erro de equipamento (base 1.11); em equipamento é a única |
| `cobrir` | a frente menos um tick | R8a ficha 2, F5 |
| `folga` | a frente menos a folga do `Config.lua` | R8b R6; a fonte não dá o tamanho da folga |

O **tick**, o menor passo de preço, é 1 cobre se `SupportsCopperValues()` for verdadeiro, senão 1 prata (R1b 7). Nenhum candidato fica abaixo de `v / (1 − c)` (R8b R8) nem acima de 3 vezes a referência. As fontes se contradizem sobre cobrir (R8a F5 contra R8b R6 e R12) e a ordem entre preços iguais é incógnita (base 2.17): por isso o addon não escolhe.

**Ponto de equilíbrio.** Para o candidato `p`, a duração `D` e a chance de venda `P`:

```
W1(p, D) = P · ( p·(1−c) − (1−rs)·du ) + (1−P) · ( v − (1−rx)·du )
P*       = (1−rx)·du / ( p·(1−c) − v + (rs−rx)·du )
```

`P*` é a chance de venda a partir da qual o leilão paga mais que vender ao NPC agora. A tela o mostra em palavras (`needs 18%`), o número que o dono consegue julgar (D5). O addon não inventa chance de venda: ao lado aparece a frequência medida das vendas próprias por classe e duração (`sold 4 of 10`), quando houver 10 desfechos.

**Veredito.** `VENDOR` quando nenhum candidato fica acima do piso de preço; `AUCTION` quando a frequência medida supera `P*`; `YOUR CALL` enquanto não há frequência. Em verde, a fonte aprovada já diz leilão (base 4.5), e o `P*` serve para o dono pesar o depósito.

**Duração e lote.** A duração por classe é escolha do dono (R8b R15 é a fonte que existe); a linha mostra o `P*` das três. Commodity posta o lote da pilha numa chamada; item posta 1 unidade por tecla (H-15).

### 7.3 Piso do vendedor

Sobre a escada fresca, comprar os degraus enquanto `p_j <= v − 1 tick`:

```
EV     = soma( (v − p_j) · q_j )            sem corte, sem deposito
teclas = 2 por compra + 1 clique de venda por pilha no NPC
aceita se  EV / teclas >= tiquete  e  Cofre.autoriza
teto da cotacao = n · (v − 1 tick)          acima disso a confirmacao e recusada
```

O teto é o do motor, não os 5% que a tela da Blizzard tolera (base 2.7): aqui qualquer alta come o lucro. A primeira compra de cada item é o **lote de confirmação**, de até 2% da banca: o dono vende ao NPC com o próprio clique e o addon confere, pela variação do dinheiro, se o recebido bate com o lido (H-21). Só então o item aceita lote maior.

### 7.4 Compra para revenda (fase 2, em papel primeiro)

```
U_lcb = max( saida conservadora por unidade na escada que sobra depois da compra , v )
EV    = η_real · ( n · U_lcb − Custo ) − teclas · tiquete
comprar se  EV >= μ_min · Custo  e  Cofre.autoriza  e  foto com ate 30 s
```

A conta do R9 5.1 multiplica a saída inteira por `η_real`; com o valor inicial de 0,5 só passaria compra com saída maior que o dobro do custo, o que contradiz a definição do R9 5.7 (razão entre ganho realizado e previsto). Aqui o desconto incide sobre o ganho, como no D3. `η_real` vale 1,0 no piso e 0,5 no resto, até o Livro medir.

- **Saída conservadora**: o menor entre a mediana dos mínimos diários do anel e o preço robusto da última foto (ideias públicas, base 5.8), líquido de corte e de um depósito.
- **Classe da saída**: A, o vendedor paga mais que o custo; B, houve venda inferida no preço de saída ou acima em 3 intervalos das últimas 24 horas (as duas testemunhas do D1); C, o resto. Classe C nunca é executável: aparece como `UNPROVEN`, só em papel.
- **Bordas lentas**: o sinal só aparece se a vida medida das ofertas daquela faixa de desconto passa do tempo de reação medido do dono (D1 4.3).
- **Guarda de regime**: oferta funda no preço baixo é preço novo, não pechincha (R9 5.2); compra-se só o lote de confirmação.
- **Deriva medida**: mediana, entre os itens da categoria, da variação do menor preço entre resumos separados por 6 horas ou mais. Entra como custo de carregar (D1 4.3).
- **Cancelar**: a regra `Δ_canc` do R9 4.6, com o custo de três ações e uma ida ao correio se a H-10 valer, e só dentro do teto antiguerra (seção 9.3).

### 7.5 Ordem da fila e custo da atenção

Entram as linhas que passam no **tíquete**, o valor mínimo por tecla (15 cobre de partida). Postagens vêm primeiro, por valor por tecla, porque liberam capital. Depois as compras: por `EV / (Custo · T_caixa)` enquanto a banca for menor que 15 ouro, e por valor por tecla acima disso (D5; preço-sombra do capital do D1). Cancelamentos por último, agrupados, porque só rendem depois do correio (D2). `T_caixa` é o tempo medido até o dinheiro voltar. Depois de 3 a 5 sessões, o agente propõe trocar o tíquete pelo lucro por hora realizado vezes o tempo medido por ação.

### 7.6 Diário de calibração

Padrão do projeto (base 4.9): o addon grava o sinal cru e o número medido substitui a estimativa.

| Parâmetro | Partida | Sinal gravado | Vira medido com |
|---|---|---|---|
| Corte `c` | 0,05 (base 1.4, inferência) | consignação sobre arremate, na fatura | 3 faturas |
| Depósito | nenhuma: sempre lido | valor lido nas três durações; variação do dinheiro ao postar | 5 itens |
| Devolução `rs`, `rx` e no cancelamento | 1, 0 e 0 (base 1.7); no Cofre todo depósito conta como em risco | fatura e dinheiro em cada desfecho | 1 de cada |
| Atraso do correio | 60 min (base 1.8) | hora do aviso de venda e hora da fatura | 5 vendas |
| Entrega de compra e de cancelamento | pelo correio (H-10) | evento de atraso e chegada real | 3 de cada |
| Cadência e custo do fôlego | 30 buscas por minuto | carimbos dos eventos de throttle | 5 fôlegos |
| Frequência de venda | nenhuma | preço, fila na frente, duração e desfecho de cada postagem | 10 por classe e duração |
| "Já sumiu" | nenhuma | sinais que sumiram entre a foto e a tecla | 30 sinais |
| `η_real` | 1,0 no piso; 0,5 no resto | previsto e realizado por lote fechado | 30 lotes |
| Ordem entre preços iguais | pior caso | quantidade própria contra a do degrau em fotos seguidas | 5 observações concordantes |
| Tempo por ação | tíquete de 15 cobre | segundos entre a linha aparecer e a tecla, e entre a tecla e o eco | 3 sessões |

## 8. Execução

### 8.1 Invariantes

São o contrato de `Acoes.lua`, `Ecos.lua` e `Cofre.lua`; o checador e a bancada conferem cada um.

| # | Invariante |
|---|---|
| I1 | Uma tecla aceita gera no máximo uma chamada de função de ação. |
| I2 | Função de ação só é chamada de dentro do `OnClick` de um botão do addon, em `Acoes.lua`. |
| I3 | Toda chamada vem depois de `Cofre.autoriza` no mesmo clique e entra no Livro antes (intenção) e depois (eco). |
| I4 | Nenhuma ordem passa dos tetos de `Tetos.lua`. |
| I5 | Ação sem eco vira INCERTO e bloqueia. Nunca há reenvio. |
| I6 | Foto incompleta, vencida ou vazia suspeita não atualiza estimador nem gera sinal. |
| I7 | O nível em vigor de uma estratégia só desce dentro do jogo. |
| I8 | Nenhuma tecla age sobre o que o dono não teve tempo de ver: a linha ou o bilhete precisa estar na tela, sem mudar, há pelo menos `T_ver`. A seleção nunca muda sozinha. |
| I9 | Nenhuma consulta sai fora de um fôlego aberto por tecla. |

### 8.2 O caminho da tecla

Cada verbo tem um botão do addon (`PregaoForeverBotaoComprar`, `...Postar`, `...Cancelar`, `...Sim`) e uma tecla ligada a ele por `SetOverrideBindingClick` enquanto a janela está aberta (base 3.4, 8.1). O clique do mouse no mesmo botão percorre o mesmo código. A tecla do dono é o evento de hardware (H-01). Dentro do `OnClick`, nesta ordem: guardas, `Cofre.autoriza`, `Livro.intencao`, uma função de ação, estado `ENVIANDO`.

Guardas de dedo, pensadas para o acesso remoto:

- **Vê e assina** (D6): `T_ver` de 1 segundo mais a latência de `Config.remoto.latencia_ms` (D2). Linha que mudou mostra `UPDATED` e reinicia a contagem.
- **Repetição**: a mesma tecla de ação em menos de 400 ms é ignorada; tecla com máquina ocupada é descartada, nunca enfileirada (H-02).
- **Rajada**: 6 teclas de ação em 2 segundos soltam os bindings e pedem `H` para rearmar (D2).
- **Throttle não pronto** numa postagem consome a tecla sem agir; quando o sistema fica pronto, o addon não dispara sozinho (D5).
- **Validade**: bilhete armado expira em 20 s; a confirmação de commodity desliga com menos de 5 s de cotação.

### 8.3 Máquinas de ação

**Comprar commodity** (duas teclas: cotar e confirmar; base 2.7).

```
SINAL --[TECLA B], foto com mais de 30 s--> releitura -> SINAL ("REFRESHED")
SINAL --[TECLA B], foto fresca, Cofre autoriza--> COTANDO: StartCommoditiesPurchase(itemID, n)
COTANDO --COMMODITY_PRICE_UPDATED, total <= teto--> COTADO (bilhete: total, teto, validade)
COTANDO --total > teto, PRICE_UNAVAILABLE ou 5 s--> CancelCommoditiesPurchase -> SINAL ("PRICE MOVED")
COTADO --[TECLA Y], depois de T_ver--> CONFIRMANDO: ConfirmCommoditiesPurchase(itemID, n)
COTADO --[TECLA N] ou cotacao vencida--> CancelCommoditiesPurchase -> SINAL
CONFIRMANDO --COMMODITY_PURCHASE_SUCCEEDED--> FEITO (custo pela variacao do dinheiro)
CONFIRMANDO --COMMODITY_PURCHASE_FAILED--> FALHOU (sem gasto) -> SINAL
CONFIRMANDO --prazo do eco--> INCERTO
```

`CancelCommoditiesPurchase` não leva a marca de restrição e a própria Blizzard a chama de evento e de temporizador (base 2.12; R1b 14): por isso sai sem tecla. A confirmação nunca sai sem tecla, mesmo que a API permita (base 2.13): seria o addon gastando sozinho.

**Comprar item** (duas teclas: armar e executar; base 2.8). É o ritmo da tela da Blizzard, que só chama `PlaceBid` no aceite de um popup (R1b 14).

```
SINAL --[TECLA B]--> RELENDO (so consulta: confere auctionID e arremate)
RELENDO --mesmo leilao e preco, Cofre autoriza--> ARMADO (bilhete)
RELENDO --sumiu ou mudou--> SINAL ("GONE")
ARMADO --[TECLA Y]--> ENVIANDO: PlaceBid(auctionID, arremate)
ENVIANDO --AUCTION_HOUSE_PURCHASE_COMPLETED(auctionID)--> FEITO
ENVIANDO --AUCTION_HOUSE_SHOW_ERROR--> FALHOU (ItemNotFound conta como "ja sumiu"; base 1.11)
ENVIANDO --prazo do eco--> INCERTO
```

**Postar** (uma tecla; duas se o jogo pedir confirmação; base 2.9).

```
ITEM --[TECLA P], foto com mais de 30 s--> releitura -> ITEM ("REFRESHED")
ITEM --[TECLA P], foto fresca--> pre-checagens: IsSellItemValid, deposito lido e coberto,
        IsThrottledMessageSystemReady, faixa de preco, Cofre autoriza
        --> ENVIANDO: PostCommodity ou PostItem (caminho por GetItemCommodityStatus)
ENVIANDO --needsConfirmation falso e AUCTION_HOUSE_AUCTION_CREATED(id)--> FEITO
ENVIANDO --needsConfirmation verdadeiro e AUCTION_HOUSE_POST_WARNING--> AVISO (repete os numeros)
AVISO --[TECLA Y], depois de T_ver--> ConfirmPostCommodity ou ConfirmPostItem -> ENVIANDO
AVISO --[TECLA N] ou 20 s--> ABORTADO (nada e chamado; H-16)
ENVIANDO --AUCTION_HOUSE_POST_ERROR ou SHOW_ERROR--> FALHOU
ENVIANDO --prazo do eco--> INCERTO
```

`IsSellItemValid` está no contrato (R1a, função 63). Função de depósito que devolve nada bloqueia a postagem (`Deposit unknown`).

**Cancelar** (uma tecla; duas se houver custo; base 2.10).

```
LEILAO --[TECLA C], CanCancelAuction, GetCancelCost = 0, teto antiguerra livre--> ENVIANDO: CancelAuction(id)
LEILAO --[TECLA C], custo > 0--> ARMADO (bilhete com o custo) --[TECLA Y]--> ENVIANDO
ENVIANDO --AUCTION_CANCELED(id)--> FEITO      --SHOW_ERROR--> FALHOU      --prazo--> INCERTO
```

Repostar não é uma ação: é cancelar, receber o item de volta (bolsa ou correio, H-10) e postar, cada passo com a sua tecla.

**INCERTO.** As funções de ação falham em silêncio (base 2.12), a cadência do throttle é desconhecida (base 2.14) e a própria Blizzard mostra um aguarde depois de 2 s (R1b 4). Por isso prazo estourado nunca vira "falhou, aperte de novo". O estado bloqueia toda ação nova enquanto concilia: `QueryOwnedAuctions`, dinheiro e bolsas decidem entre `FEITO (eco perdido)` e `NAO EXECUTADA`. Sem decisão, o item fica bloqueado até a próxima abertura do leilão ou do correio e as outras linhas voltam. Três INCERTO na sessão ligam o disjuntor de ação muda.

## 9. Risco e carteira

### 9.1 A banca

- A **banca** `B` é o `GetMoney()` do personagem logado menos o **piso pessoal** do `Config.lua` (ouro que o addon trata como inexistente), mais o ouro de vendas já confirmadas a caminho do correio, mais o estoque comprado, marcado a valor de saída conservador e nunca a custo (R9 7.1).
- O ouro dos outros três personagens e o do banco da guilda nunca entram: não há banco de conta (base 4.1, 4.2).
- Estados do ouro: livre; em estoque comprado; em depósito em risco; em correio; em cotação.
- Lotes saem por ordem de entrada. Item da lista `reservas` nunca vira linha de venda.

### 9.2 Tetos

Constantes de `Tetos.lua`, em fração de `B`. O `Config.lua` pode baixar cada um, nunca subir.

| Teto | Duro | De partida |
|---|---|---|
| Lote de confirmação (primeira compra de um item) | 2% | 2% |
| Custo por ordem em micro | 10% | 5% |
| Custo acumulado por item | 20% | 10% |
| Estoque com risco de preço, total | 50% | 50% |
| Depósito em risco ao mesmo tempo | 5% | 5% |
| Depósito perdido no dia | 2% | 2% |
| Perda do dia | 5% | 5% |
| Compra diária de um item (fase 2) | 10% do volume diário mínimo medido | igual |
| Ações por minuto; buscas por minuto | 10; 30 | iguais |
| Preço de postagem | entre `v/(1−c)` e 3 vezes a referência | igual |

Compra de classe A já confirmada não conta no teto de risco de preço, mas conta no teto por item e no espaço de bolsa. Kelly (R9 7.2) não dimensiona nada: com retorno sem medir ele é sensível demais (R9 7.7).

### 9.3 Antiguerra e mercado adverso

- **G1**: no máximo 2 cancelamentos com repostagem por item em 4 horas.
- **G2**: leilão próprio coberto 2 vezes em menos de 10 minutos, no mesmo item: o candidato `cobrir` sai, o item entra em trégua por 4 horas e a linha diz `STAND DOWN`. A contagem é só dos próprios leilões; não usa nome de vendedor.
- **Parede** (degrau grande, de poucos donos): o addon nunca propõe preço acima dela e nunca a compra. A isca nunca serve de âncora.
- Deriva da categoria abaixo de −10% em dois dias suspende a compra para revenda naquela categoria.

G1 e G2 vêm do D6, apoiados em R8a F23 e R8b R7 (relatos de guia) e no modelo do R9 9.3. São guarda de depósito, não estratégia.

### 9.4 Disjuntores

O **disjuntor** é uma trava automática que suspende um tipo de ação até a condição de destrava.

| Disjuntor | Gatilho | Efeito | Destrava |
|---|---|---|---|
| Perda do dia | resultado do dia em −5% de `B`; −1% num item | só venda; item bloqueado por 24 h | virada do dia |
| Ação muda | 3 INCERTO na sessão | ações bloqueadas | reabrir o leilão e conciliar |
| Dado ruim | 2 fôlegos incompletos seguidos ou foto vazia suspeita | compra suspensa | fôlego limpo |
| Compras perdidas | 3 "já sumiu" seguidas | compra suspensa | próximo fôlego |
| Throttle travado | "não pronto" por 30 s (base 2.14) | consultas e ações param | fechar e reabrir o leilão |
| Restrição de conta | `AUCTION_HOUSE_SHOW_ERROR` com `HasRestriction` ou `RestrictedAccountTrial`, ou `AUCTION_HOUSE_DISABLED` (R1a 3; R1b 15) | tudo para, faixa fixa, nenhuma nova tentativa | sessão do agente |
| Dinheiro sem explicação | desvio da conciliação acima de 1% de `B` | compra cai para papel | sessão do agente |
| Rajada; Halt | 6 teclas de ação em 2 s; tecla `H` | bindings de ação soltos | tecla `H` |

O disjuntor de restrição responde ao Temporary Economy Hold (base 1.10); se é assim que ele aparece não há como testar.

## 10. Contabilidade

O `Livro.lua` é a régua. Ele mede o que o dono faz por qualquer caminho: os eventos de criação, cancelamento e compra e os avisos de venda são do cliente (base 2.9 a 2.11), então a ação feita pela tela da Blizzard ou por outro addon também vira linha, marcada `outside` (H-25). É o que dá a linha de base antes de existir tecla própria e o que permite comparar construir com adotar.

| Registro | Campos |
|---|---|
| Ação | `seq`, hora da tecla, verbo, chave, quantidade, preço, estratégia, bilhete, dinheiro antes e depois, eco e hora do eco, origem (`key`, `mouse` ou `outside`) |
| Lote | chave, quantidade, custo, origem (comprado, coletado), estado (em mão, postado, vendido, no NPC, retirado), fechamento |
| Sinal | estratégia, nível, previsto, se executou, desfecho real ou de papel |
| Fatura | tipo, lance, arremate, depósito, consignação, atraso (base 3.1) |
| Sessão | duração, ações por verbo, resultado, parâmetros em vigor |

**Fechamento de lote.** Venda no leilão fecha pela fatura; venda ao NPC fecha pela variação do dinheiro com o vendedor aberto (`MERCHANT_SHOW` e `PLAYER_MONEY`, R1c); item que o dono usa ou guarda fecha como `withdrawn`, sem resultado.

**Medidas.** Resultado realizado e estoque marcado; cobre por ação e por hora; voltas do capital; depósitos perdidos; fração vendida por classe e duração; taxa de "já sumiu"; tudo por estratégia e por origem.

**Conciliação.** No leilão: dinheiro, leilões próprios e bolsas contra o Livro, a cada fôlego. No correio: a soma das faturas contra a variação do dinheiro. O resultado é `RECONCILED 12 of 12` ou `UNEXPLAINED 3s 10c`; o segundo liga o disjuntor.

**Relatório de sessão.** Depois do `/reload` de fecho, o agente lê o banco e escreve o relatório que o projeto pede (base 4.7): resultado, o que vendeu e expirou, a ficha de evidência de cada estratégia (sinal medido, papel, condição de ligar cumprida ou não), a autópsia de cada lote perdedor e a pauta da próxima sessão (D3 3.8).

## 11. Interface

### 11.1 Princípios

Janela própria ao lado do leilão da Blizzard, que continua intacto. Três zonas fixas: estado em cima, lista no meio, bilhete embaixo. Linhas de 28 px, botões de 32 px, contraste de 4,5:1, sem animação (base 8.4). Sem caixa de texto: com o foco numa caixa as teclas não disparam (base 3.4). A bancada desenha cada visão e cada estado em HTML e o dono os aprova antes do jogo, porque ele decide vendo quadro (base 4.7).

### 11.2 Teclas

Todas saem da lista livre da base 4.10, cujos padrões do cliente ninguém conferiu: a sonda S0 confere e o mapa final é a decisão DD5. Valem só com a janela aberta. A roda do mouse não é ligada a nada, por escolha de desenho: um gesto solto nunca vira ação.

| Tecla | Faz | Função de ação |
|---|---|---|
| `L` | Look: um fôlego de varredura | nenhuma (consultas) |
| `N` / `U` | Próxima linha / anterior; `N` também desarma o bilhete e dispensa alerta | nenhuma |
| `I` / `O` | Info, a conta da linha / Show N more | nenhuma |
| `B` | Buy: relê; cota a commodity; arma o item | `StartCommoditiesPurchase`, só em commodity |
| `P` | Post: relê ou posta a linha | `PostItem` ou `PostCommodity` |
| `C` | Cancel: cancela o leilão da linha | `CancelAuction` |
| `Y` | Yes: executa o bilhete que está na tela | `ConfirmCommoditiesPurchase`, `PlaceBid`, `ConfirmPost*`, cancelamento com custo |
| `H` | Hold: solta ou rearma as teclas de ação | nenhuma |
| `F1` a `F5` | Visões Next, Sell, Mine, Risk, Session | nenhuma |

Comprar, postar e cancelar ficam em teclas diferentes, para a memória do dedo não trocar um verbo por outro; confirmar tem uma tecla só. Toda tecla tem botão clicável com o rótulo dela.

### 11.3 Telas

Visão **Next** (F1), a que abre:

```
+- PregaoForever ------------------- [F1 NEXT]  F2 SELL  F3 MINE  F4 RISK  F5 SESSION -+
| MODE LIVE   BANK 4g 00s   FREE 3g 12s   IN MAIL 0s   AT RISK 6%   KEYS ON           |
| DATA 0m 42s old, complete                                    [L] look again         |
+--------------------------------------------------------------------------------------+
| NEXT (7)                                                                             |
| > POST    Bandit Cloak x1      24h   2s 00c      needs 18%    sold 4 of 10           |
|   POST    Copper Ore x20        8h   1s 08c ea   needs 1%     YOUR CALL              |
|   BUY     Linen Cloth x14      9c ea   vendor 13c   +56c      PAPER                  |
|   CANCEL  Tin Ore x20          340 ahead   +36c if reposted                          |
|   VENDOR  Ruined Pelt x5       25c ea   auction pays less                            |
|   Show 2 more                                                                        |
+--------------------------------------------------------------------------------------+
| TICKET  none                   [P] post selected   [N] next   [I] why                |
+--------------------------------------------------------------------------------------+
| L look  N next  U back  I why  O more  B buy  P post  C cancel  Y yes  H hold        |
| last key: N                                                                          |
+--------------------------------------------------------------------------------------+
```

O bilhete, depois de `B` numa commodity ao vivo (em papel ele diz `PAPER - no gold moved`):

```
| TICKET  QUOTE OK   BUY Linen Cloth x14                                               |
|   pay 1s 26c total (9c each)   cap 1s 68c   0.3% of bank   exit vendor 1s 82c SURE   |
|   [Y] BUY NOW (quote valid 12 s)          [N] cancel                                 |
```

Visão **Sell** (F2):

```
| BAGS TO SELL (6)           rule       price     time   deposit   needs   seen        |
| > Bandit Cloak x1          MATCH      2s 00c    24h    30c       18%     sold 4 of 10|
|   Copper Ore x20           UNDERCUT   1s 08c    8h     20c       1%      -           |
|   Wolf Meat x7             VENDOR     3c ea     auction pays less                    |
|   Ring of the Monkey x1    NO REFERENCE   vendor 45c   deposit 2c / 9c / 27c         |
|   Show 2 more                                                                        |
| KEPT (2)   Light Leather x18: reserved        Show 1 more                            |
```

Visão **Mine** (F3):

```
| MY AUCTIONS (5)   deposits at risk 14c       price     left     ahead    advice      |
| > Tin Ore x20                                1s 76c    2-12h    340 un   CANCEL +36c |
|   Linen Bag x1                               SOLD      gold arrives in about 41 min  |
|   Show 3 more                                                                        |
| TODAY   cancels 1 of 2 on this item       deposits lost 3c of 8s allowed             |
```

A visão **Risk** (F4) tem quatro seções: `BANK` (banca, piso, resultado do dia), `EXPOSURE` (cada teto no formato `6% of 50%`), `BREAKERS` (cada disjuntor em palavra) e `LICENCES` (por estratégia: permitida, conquistada, em vigor e o que falta, como `8 of 10 results`).

Visão **Session** (F5):

```
| SESSION  1h 32m   actions 49 (post 21, buy 14, cancel 3, outside 11)   unknown 0     |
| RESULT   realized +10s 75c   per action +22c   per hour +7s 01c   capital turns 1.4  |
| BY PLAN  Sell greens +5s 80c (sold 2 of 5)    Sell extras -45c    Show 2 more        |
| CHECKS   measured 7 of 12 game numbers        Show list                              |
| STORAGE  1.1 MB of 3 MB     unsaved 49 actions, 52 min                               |
| TICKET   [Y] save now (reloads the interface)                                        |
```

Painel **Mail**, aberto com `MAIL_SHOW` (R1c 1):

```
| STATE    READY - 12 letters read. Take your mail now.              |
| SOLD (5)      +14s 20c    cut 75c    deposits back 10c             |
| EXPIRED (2)   2 items back           deposits lost 4c              |
| BOUGHT (3)    3 items to collect     2 lots for the vendor         |
| CHECK    waiting for you to take the mail          [N] dismiss     |
```

### 11.4 Fluxos, tecla por tecla

**A. Varrer, decidir e comprar.**
1. O dono fala com o leiloeiro. A janela abre e as teclas ligam.
2. **[TECLA L]**: um fôlego (consultas). A linha `DATA` mostra idade e completude.
3. `N` ou `U` até a linha; `I` mostra a conta.
4. **[TECLA B]**. Foto com mais de 30 s: só relê. Foto fresca, commodity: chama `StartCommoditiesPurchase`, e o bilhete mostra total, teto, fração da banca, saída e validade. Foto fresca, item: só relê o leilão e arma o bilhete.
5. **[TECLA Y]**, depois de `T_ver`: `ConfirmCommoditiesPurchase` ou `PlaceBid`. `N` desiste.
6. Resultado em uma palavra: `BOUGHT`, `GONE`, `FAILED` ou `UNKNOWN - checking`. A seleção não anda sozinha.

**B. Postar.**
1. `F2`. A lista vem das bolsas; os reservados ficam em `KEPT`.
2. **[TECLA P]** na linha: relê, se preciso; com foto fresca chama `PostCommodity` ou `PostItem` com o preço, a duração e o depósito que a linha mostra há pelo menos `T_ver`.
3. Se o jogo pedir confirmação, a faixa `GAME ASKS TO CONFIRM` repete os números e **[TECLA Y]** chama `ConfirmPost*`. `N` aborta.
4. `POSTED`; a linha vai para a visão Mine. Linhas `VENDOR`, `KEPT` e `NO REFERENCE` não têm tecla de ação: o addon marca o item na bolsa e o dono vende, guarda ou posta pela tela da Blizzard.

**C. Cancelar e repostar.**
1. `F3`. Cada leilão traz o conselho: `KEEP`, `CANCEL` com o ganho esperado, `LET EXPIRE` ou `STAND DOWN`.
2. **[TECLA C]**: `CancelAuction`. Havendo custo, a tecla só arma e **[TECLA Y]** executa.
3. Quando o item volta (bolsa ou correio, H-10), aparece na visão Sell com a marca `returned`. Repostar é o fluxo B.

**D. Recolher o correio.**
1. O dono abre a caixa. O painel mostra `WAIT - reading (7 of 12)` e depois `READY`; se a H-11 não valer, `READY - headers only`.
2. **[CLIQUE DO DONO]** no `Open All Mail` da própria Blizzard (espelho: `Blizzard_MailFrame/MailFrame.xml:444`), ou carta por carta. O addon não pega ouro nem item.
3. O addon compara a variação do dinheiro e das bolsas com o que leu e fecha os lotes.

**E. Fechar a sessão.**
1. `F5`: resumo, pendências (INCERTO, depósitos em risco, ouro no correio) e o que foi medido.
2. **[TECLA Y]**: grava o registro e recarrega a interface, o que leva o banco ao disco (base 3.9). Se a H-19 falhar, a tela pede `/reload` digitado. No meio de uma sessão longa, a mesma tecla é o ponto de salvamento.

### 11.5 Operação remota, ritmo e alertas

- **Eco imediato.** A tecla aceita muda a palavra de estado no mesmo quadro (`SENT`), e o rodapé mostra a última tecla recebida: é o que evita a segunda tecla por dúvida.
- **Foco e combate.** Com o foco numa caixa de texto da Blizzard as teclas não disparam (base 3.4); se o addon conseguir ler onde está o foco (hipótese, a conferir na S2), a faixa diz `Keys paused: click outside the search box`. Em combate, a faixa diz `IN COMBAT - trading paused`.
- **Cursor estacionado.** Se a H-01 falhar para a tecla e valer para o mouse, os botões de ação ficam empilhados num ponto fixo: continua um gesto por ação, sem viagem de ponteiro (D2).
- **Ausência.** Parado, o fôlego acaba e nada mais roda. A marca de ausente e a saída por inatividade seguem o curso do jogo (base 8.2).
- **Ritmo.** Uma volta é a perna do leilão (varrer, postar, comprar, cancelar por último) mais a perna do correio. A cada 50 minutos a visão Session sugere salvar e pausar; nada é imposto.
- **Alertas.** Todo alerta tem faixa de texto que fica até o `N`; `FlashClientIcon` e `PlaySound` (base 3.6) são reforço, porque o som pode não atravessar o stream (R10a 4, inferência). São eles: `SOLD`, `EXPIRED` e `OUTBID` (avisos do jogo, que chegam com o leilão fechado, base 2.11); `BUYING HALTED` com o motivo; `API STALLED - close and reopen the auction house`; `AUCTION HOUSE RESTRICTED - actions paused`; `UNEXPLAINED 3s 10c - paper mode until reviewed`; `SAVE SOON`.

## 12. Mesa externa (opcional enquanto o dono não decidir)

A **mesa** é o que roda fora do jogo. A decisão DD7 escolhe entre três tamanhos; o addon funciona igual nos três, porque só conhece dois arquivos.

| Opção | O que roda | Quando |
|---|---|---|
| A, padrão | A sessão do agente, depois do `/reload` de fecho: `ler-pregao.mjs` converte o banco em JSON; o agente escreve o relatório e, com o sim do dono, o `Config.lua` e o `Calibrado.lua` | Fases 1 e 2 |
| B | `mesa.mjs`, rodada pelo agente no fecho: arquiva as fotos, roda o replay, calibra, gera o relatório | Fase 2 |
| C | Um vigia no Avell que roda a opção B a cada `/reload`, com o jogo aberto | Só se o dono pedir |

**Contratos de dados** (D3 3.6):

| Arquivo | Quem escreve | Defesa |
|---|---|---|
| SavedVariables `PregaoForever.lua` | o addon | A mesa só lê, com `luaparse` (R4a 3), sem executar; confere `fim == seq`; recusa esquema desconhecido; descarta `seq` repetido |
| `Calibrado.lua` | agente ou mesa | Cabeçalho (`esquema`, `geradoEm`, `recibo`) e sentinela; gravação por arquivo temporário e renomeação; cada valor tem faixa e, fora dela, vale o de partida; nenhum valor alcança `Tetos.lua` |
| `Config.lua` | o agente, com o sim do dono | Licença acima do que a evidência sustenta e teto acima do duro não têm efeito |
| arquivo morto em `wow/modder/dados/pregao/` | a mesa | Uma foto por linha, por dia; fora do git |

O `recibo` diz até qual `seq` o arquivo de fora já guardou; o addon só poda foto com `seq` até ele. A entrega é "pelo menos uma vez": se a mesa não rodou, nada se apaga.

**Modos diante do `Calibrado.lua`.** `DESK OK`: cabeçalho e sentinela conferem e a idade é de até 7 dias. `DESK STALE`: mais velho; a compra para revenda cai para papel. `NO DESK`: ausente, truncado ou de outro esquema; valem os números de partida e só as vendas e o papel funcionam.

**Dados externos.** Há relato de rotas da API oficial de dados com leilões por conjunto de regras, que pedem credencial de desenvolvedor do dono e que a Blizzard não documenta em página aberta (base 5.4). Ficam fora até a decisão DD8.

## 13. Dados estáticos

- **`Dados.lua`** (fase 1). `gerar-dados-pregao.mjs` lê o `ItemSparse` em CSV do build 70938 (base 9.1) e grava, por `itemID` com preço de venda maior que zero, uma linha compacta com `SellPrice`, `Stackable`, qualidade e classe. Tamanho: hipótese de 150 a 250 KB, a medir. Serve só à triagem do resumo; o preço que decide é o lido ao vivo (regra 17).
- **`checar-dados-pregao.mjs`** confere contagem, faixas e ASCII; a sonda S0 confere 20 itens contra o jogo.
- **`Receitas.lua`** (fase 3). Grafo de `SpellReagents`, `SpellEffect` e `SkillLineAbility`, cerca de 130 KB; as 526 linhas com quantidade zero pedem regra própria (base 9.2).
- **Fora do cliente**: rendimento de desencanto e estoque limitado de vendedores (base 9.3). O addon só os conhece medindo.

## 14. Interoperação com os addons instalados

Tudo em `Pontes.lua`, em tempo de execução, com `pcall`; com o addon ausente, a peça desliga e o resto segue (base 7).

| Addon | O que se usa | Para quê |
|---|---|---|
| Auctionator 341 | `Auctionator.API.v1`: último mínimo visto e idade do preço (base 7.1) | Referência fraca; segunda opinião (diferença de mais de 3 vezes marca dado suspeito) |
| Syndicator | Contagem de um item por personagem (base 7.2) | Dizer em qual personagem o item está |
| Baganator | Marca no canto do item da bolsa (base 7.2) | Marcar o que vai ao NPC e o que vai ao leilão |
| ElvUI | Módulo de skins (base 7.5) | Vestir a janela; o kit `Visual.lua` tem plano próprio se ele faltar |
| ForeverGuide, Naowh Forever | Nada | Do primeiro, só o aviso de privacidade ao dono: por padrão ele compartilha as varreduras (base 7.3) |

O BugGrabber, já instalado (R4b 2), é o juiz de "sessão sem erro de Lua".

## 15. Conformidade

**Política.** Só a API oficial de addons (base 4.4). O suporte disse que o uso normal do leilão é sempre permitido e que os sinais suspeitos são item barato por muito ouro e preço muito fora do mercado (base 1.10); não foi achado relato de punição por addon de leilão dentro das regras (base 5.7). O acesso remoto ao próprio PC não tem posição oficial (base 8.3): fica fora do addon e é a decisão DD9.

**Limites que afastam os dois sinais.** Preço de postagem sempre dentro da faixa da seção 9.2 e, sem referência, nenhum preço proposto. Nenhuma compra acima da referência. Leilão marcado `containsOwnerItem` ou `containsAccountItem` nunca vira linha (base 2.3, 2.4). Uma tecla por ação e teto de ações por minuto. O Livro guarda cada ação com a hora da tecla, o bilhete e o eco: é o registro para mostrar ao suporte, se preciso.

| O addon se recusa a | Por quê |
|---|---|
| Agir por timer, evento ou em cadeia; reenviar ação sem eco | Regra do dono (base 4.4, 4.6); a falha silenciosa é documentada (base 2.12) |
| Confirmar compra de commodity sem tecla | A API talvez permita (base 2.13), e por isso mesmo seria gasto sem o dono. Não é oferecido nem como opção. |
| Chamar `:Click()`, usar macro ou ligar tecla a botão da Blizzard | Simula entrada; risco de taint não medido |
| Pegar correio; vender ou comprar no NPC | Recomendação DD1c; a decisão de 2026-11-06 proibiu funções que compram ou gastam por código (base 4.6). O NPC não terá tecla em nenhuma opção. |
| Testar na sonda uma ação fora de clique | O resultado não muda o desenho, e o teste encosta na regra de não contornar evento de hardware |
| Chamar `ReplicateItems` nas fases 1 e 2 | Base 2.5 |
| Reset, formação de mercado, lance, casa neutra, equipamento para revenda | Sem fonte ou com fonte fraca (seção 3.2) |
| Gravar ou mostrar nome de vendedor; ler ou reusar código de terceiro | Privacidade; base 7 |
| Mexer na marca de ausente, em CVar ou em binding salvo; enviar dado para fora | Base 8.2, 4.7 |
| Continuar depois de um sinal de restrição de conta | Base 1.10 |

## 16. Testes

**Bancada com leilão falso.** A bancada atual não simula leilão, dinheiro nem ticker repetido (base 4.9). Nasce `bancada-pregao.mjs`, em fengari, em `wow/modder/ferramentas/pregao/`, com um `C_AuctionHouse` falso (funções e eventos do contrato, R1a), throttle com fila que pode travar, dinheiro, bolsas, correio com fatura, vendedor, relógio controlado, ticker que repete e bindings.

- **Bandeira de hardware.** As funções de ação só funcionam enquanto a bancada despacha um clique simulado; fora dela não fazem nada, como no cliente (base 2.12), e a bancada conta a violação.
- **Falhas injetadas.** Resposta que não chega, página parcial, mensagem descartada, função que devolve nada, aviso e erro de postagem, `ItemNotFound`, cotação acima do teto ou indisponível, mercado vazio suspeito, throttle travado, leilão fechado no meio, depósito nulo, resposta de consulta alheia, `Calibrado.lua` truncado.
- **Cenários** (24 no mínimo): cada transição da seção 8.3; ação muda de cada uma das 7 funções; e os casos de operador do D2: duplo toque, tecla presa a 30 repetições por segundo, `Y` antes de `T_ver`, `Y` durante `ENVIANDO`, teclas alternadas às cegas.
- **Conferências.** I1 a I9; chamadas de ação em número menor ou igual ao de teclas aceitas; gasto dentro dos tetos; Livro igual à verdade do simulador; estado final seguro. Mais 10.000 roteiros aleatórios com semente.
- **Fase 2.** Mercado sintético com agentes plantados (cobridor rápido, estoque fundo, parede, isca), para testar os estimadores contra verdade conhecida (D6).

**Replay.** `replay-pregao.mjs` repassa as fotos gravadas, em ordem de tempo, pelos mesmos arquivos puros do addon, enxergando só o passado, com preenchimento conservador (R9 10.1, 10.2). O papel do replay tem de ser igual ao que o addon gravou na mesma janela. Linhas de base: não fazer nada, e entrada ao acaso com os mesmos tetos (R9 10.4).

**Checadores estáticos.** `node checar-lua.mjs <pasta>` e `node checar-combate.mjs <pasta> --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER,BINDING_` (base 4.9). Novo `checar-pregao.mjs`, porque a lista proibida do projeto não tem função de leilão (R4a 3): confere as regras 6, 8, 10, 12, 13 e 14, e que nenhuma função alcançada por timer, `OnUpdate` ou evento chega a uma `tecla_`. Um caso bom e um ruim por regra em `casos-pregao/`, rodados por `rodar-casos-pregao.mjs`.

**Sonda no jogo.** Apêndice A. Nenhum passo testa o caminho sem tecla, e os passos com tecla de ação só rodam depois da decisão DD1a.

**Critério de aceite.**

| Degrau | Exige |
|---|---|
| Instalar | Checadores com saída 0; bancada com `RESUMO erros=0` nos cenários e nos roteiros; quadros aprovados pelo dono |
| Primeira postagem fora da sonda | S1 a S4 gravadas; decisão DD1a |
| Primeira compra real | S6 a S8 gravadas; corte e devoluções medidos; duas sessões sem INCERTO pendente e com conciliação exata; decisão DD1b |
| Toda sessão | Zero erro no BugGrabber; toda ação do Livro com a tecla que a originou; Livro igual ao ouro do jogo |
| Subir de nível | Portão da seção 3.3 e a linha do dono no `Config.lua` |

## 17. Entrega em ondas

Padrão do projeto: contrato e esqueletos na sessão principal, tarefas em subagentes, checador ou bancada como critério de pronto e um portão da sessão principal por onda (base 4.9). A rota é sugestão de modelo e esforço; a tabela do `executar-plano` decide. Cada onda depende da anterior.

| Onda | Tarefas | Rota | Pronto quando | Mede | Para se |
|---|---|---|---|---|---|
| 0, sem código | O dono cola os comandos 1 a 8 e 12 do R1b 16 com o leilão aberto; decisões DD1 a DD6 gravadas em `estado.md` | dono e sessão principal | respostas anotadas | depósito por duração, commodity de 10 itens, teclas livres | `/run` bloqueado: a leitura passa para dentro do addon |
| 1, contrato | `ARQUITETURA.md` com tabela "API, Contrato" por módulo; `.toc` e 28 esqueletos; `Tetos.lua`; `Config.lua` com tudo desligado; `checar-pregao.mjs`; bancada; quadros; `dev-link.ps1` com o jogo fechado | sessão principal; bancada e checador em `sonnet/high`; `Dados.lua` em `haiku/medium` | checadores com 0 erro; `node rodar-casos-pregao.mjs` e `node bancada-pregao.mjs --auto-teste` com `RESUMO erros=0`; quadros aprovados | nada no jogo | o dono reprova os quadros: redesenhar antes de codar |
| 2, régua | `Nucleo`, `Banco`, `Itens`, `Pedidos`, `Varredura`, `Escada`, `Livro`, `Correio`, `Sonda`, `Pontes`, `Janela`, visões Session e Mine; `ler-pregao.mjs`; `modo = leitura` | `sonnet/medium`; `Pedidos` e `Livro` em `sonnet/high` | cenários de fôlego, throttle e fatura passam; no jogo, S1, S3 a S5 e S9 gravadas | linha de base: uma sessão em que o dono vende pela tela que já usa, em cobre por ação e por hora; cobre disponível abaixo do vendedor | H-03 negada: parar e investigar |
| 3, vender | `Estimadores`, `Motor` (venda), `Cofre`, `Acoes` e `Ecos` (postar, cancelar), `Teclas`, `Alertas`, visões Next, Sell e Risk; S2, S6, S7. Pede DD1a. | `Acoes`, `Ecos` e `Cofre` em `sonnet/high` com portão na sessão principal; resto `sonnet/medium` | cenários e 10.000 roteiros com `erros=0`; no jogo, 10 postagens por tecla com Livro conciliado | líquido das vendas contra o que o vendedor pagaria; fração vendida por duração; segundos por ação | S2 negativa também no mouse: fica o modo leitura. Líquido abaixo do vendedor depois de 30 postagens: a regra de venda volta à mesa. |
| 4, piso | `Acoes` (comprar), `Sombra`, `piso` em papel e depois micro; S8. Pede DD1b. | `sonnet/high` | cenários de compra passam; uma compra completa com lote fechado no NPC e diferença zero no Livro | valor por tecla do piso; vida das ofertas | três varreduras de prova abaixo do dobro do tíquete: `piso` fica desligado |
| 5, fase 2 | Anel de fotos, diferença de escadas, deriva, `vao` e `sniper` em papel, `replay-pregao.mjs`, `mesa.mjs`. Micro pede banca de 15 ouro. | `sonnet/high`; revisão do motor na sessão principal | replay igual ao papel do addon; 30 sinais de papel fechados | realizado sobre previsto em papel | abaixo de 0,5: as compras para revenda não ligam |
| 6, fase 3 | Novo design: conversão, hora e dia, dados externos, ou adotar ferramenta pronta. Pede banca de 60 ouro e três semanas de régua. | a definir | decisão do dono com os números | comparação pela régua | a definir |

A manutenção de 17/11 muda o depósito mínimo (base 1.7): a onda 0 relê o depósito depois dela. Entre as ondas 3 e 5 há uma espera que código não encurta: o diário precisa de desfechos reais.

## 18. Decisões do dono

Em todas, a opção recomendada é o padrão do `Config.lua` e a outra continua possível sem reescrever o addon.

| # | Decisão e opções | Recomendação | Como a outra opção fica possível |
|---|---|---|---|
| DD1a | Postar e cancelar por tecla, sim ou não. Em 2026-11-06 ele proibiu, no outro addon, funções que compram ou gastam por código (base 4.6). | Sim, só aqui, uma tecla por ação, com os tetos e o checador | `modo = "leitura"`: fila e régua, e ele age pela tela da Blizzard |
| DD1b | Comprar por tecla: sim, só papel, ou não | Sim, em dois tempos, depois da sonda, só nas estratégias que ele ligar | Licenças de compra limitadas a papel |
| DD1c | Correio: o addon só lê; uma tecla por carta; ou tecla no botão da Blizzard | Só ler. Fatura sem abrir a carta e binding em botão da Blizzard são incógnitas (H-11). | Tecla por carta exige tirar três nomes da regra 10: decisão posterior, com a sonda na mão |
| DD2 | Coexistência: Auctionator e ForeverGuide já ocupam o papel de leilão (base 4.12) | Manter o Auctionator (tooltip, segunda opinião) e tratar o PregaoForever como papel novo, de mesa de operação; desligar no ForeverGuide o compartilhamento de varreduras (base 7.3); rever no fim da onda 4 | `Pontes.lua` desliga sozinho se o addon faltar |
| DD3 | Fontes e regra de preço, por estratégia | Ligar `venda_verdes` (fonte já aprovada). Para `venda_sobras`, aprovar ou não as recomendações do R8b e escolher a regra por classe: equipamento `igualar`; commodity `igualar` até haver desfecho próprio. | Cada licença e cada regra é uma linha do `Config.lua` |
| DD4 | Negociador, banca e piso | Um só negociador, para a banca ser um único `GetMoney`; piso de 1 ouro. Qual personagem é escolha de jogo e fica com ele. | `Config.negociador`; com outro personagem logado o addon fica em leitura |
| DD5 | Teclas: o mapa da seção 11.2, teclas de função ou outro | O mapa proposto, depois de a sonda conferir os padrões do cliente e de ele ver os quadros | Todas as teclas vêm do `Config.lua` |
| DD6 | Nome: PregaoForever ou NichoForever | PregaoForever: o nicho seria um módulo, não o produto | Trocar antes da onda 1 não custa nada |
| DD7 | Mesa externa: A, B ou C (seção 12) | A agora; B na fase 2; C só se ele pedir | Os contratos são os mesmos nas três |
| DD8 | Credencial da API oficial de dados (base 5.4) | Não agora; ler os termos na íntegra antes de qualquer chamada; reavaliar na fase 3 | A mesa aceita fotos de outra origem como arquivo à parte |
| DD9 | Acesso remoto e os termos (base 8.3) | Perguntar ao suporte por escrito antes de sessões longas; a comparação de ferramentas está no R10a | Fora do addon |
| DD10 | Tíquete, tetos de partida, perda do dia, fôlego que renova | Os valores da seção 9.2; tíquete de 15 cobre; uma tecla por fôlego | Linhas do `Config.lua`, dentro dos tetos duros |
| DD11 | Quantidade maior que 1 numa tecla, em item (multisell) | 1 por tecla, porque o que a função faz com a quantidade não foi visto (H-15) | `Config.venda.lote_item`, depois da sonda |
| DD12 | Fase 3: construir, adotar ferramenta pronta ou parar | Decidir com três semanas de régua, não hoje | A régua mede qualquer ferramenta |

## 19. Riscos e o que derrubaria o design

1. **A tecla não vale.** A mão depende da H-01, que ninguém testou no Forever (base 2.13, 11.1). *Derruba a mão*: S2 negativa também com o clique do mouse. Sobram a fila e a régua.
2. **Pouco ouro por hora.** Com 5 ouro o ganho é de pratas, e o piso provavelmente já está varrido por quem tem ferramenta (R6a). *Derruba a compra*: três sessões com cobre por hora abaixo do que o dono faz jogando. O addon continua como assistente de venda e livro-caixa.
3. **As ferramentas prontas podem render mais.** *Derruba o projeto*: a régua da onda 2 mostrar que uma ferramenta adotada rende mais por ação do que a fila própria conseguiria. Aí o certo é adotar.
4. **A conciliação pode travar ou errar calada.** Atraso do correio, devoluções e entrega de compra são incógnitas (base 11.6, 11.10). *Derruba*: três sessões seguidas com dinheiro sem explicação depois da sonda completa.
5. **Evidência de papel que engana.** O preenchimento conservador sofre de seleção adversa e a varredura por fôlego subconta vendas (R9 10.2, 0.3). *Derruba a fase 2*: realizado em micro divergindo do papel por mais de 2 vezes, em qualquer direção.
6. **O chão muda.** Depósito novo em 17/11 (base 1.7), erros ativos (base 1.11), hotfix de preço de vendedor (base 6.3), throttle desconhecido (base 2.14), e um bloqueio de economia por engano congelaria leilão e correio com capital em trânsito (base 1.10). Cada mudança custa uma rodada de sonda.
7. **O dono operar por fora por frustração.** Guardas demais levam a agir pela tela da Blizzard, onde nenhuma vale. Por isso postar e cancelar custam uma tecla e a régua mede também o que é feito por fora.

**O que derrubaria o design inteiro:** a H-03 negada (sem gravação não há régua); o dono negar DD1a e DD1b e também não querer um conselheiro sem tecla; a consulta resumida ser tão limitada que um fôlego por sessão seja o máximo; ou uma resposta do suporte contrária ao acesso remoto, que derruba a operação, não o addon.

## Apêndice A: a sonda, em ordem

Cada passo é leitura ou uma ação barata com tecla do dono. O que paga depósito espera a manutenção de 17/11.

| # | Mede | Como | Custo | O que decide |
|---|---|---|---|---|
| S0 | Durações, cobre, commodity por item da bolsa, depósito por duração, padrões das teclas, uso do leilão pelo personagem (H-04, H-23) | Comandos 1 a 8 e 12 do R1b 16, colados pelo dono | 10 minutos | Caminho de postagem; mapa de teclas |
| S1 | O banco grava no `/reload`; tempo com 1, 3 e 5 MB; `ReloadUI` por botão; relógio fino (H-03, H-19, H-20) | Carimbo de `GetServerTime` no clique e em `ADDON_LOADED`; conferir o arquivo | 3 reloads | Se o projeto segue; teto do banco |
| S2 | A tecla satisfaz a ação; o clique sai ao apertar, ao soltar ou nos dois; tecla segurada repete, local e remoto; `PostItem` da bolsa (H-01, H-02, H-15) | Postar 1 item barato com `P` e cancelar com `C`; se falhar, repetir com o mouse; ouvir `ADDON_ACTION_BLOCKED` e `FORBIDDEN`; segurar uma tecla de navegação por 3 s | 1 depósito | Tecla, cursor estacionado ou leitura |
| S3 | Chave de um verde com sufixo; `isCommodity` das chaves (H-04) | Passivo, no primeiro fôlego | zero | Referência de equipamento |
| S4 | Tempo e pedidos do resumo; repetição; cadência do throttle; convívio com a tela da Blizzard e o Auctionator (H-05 a H-08) | 5 fôlegos cronometrados, com e sem a outra tela | zero | Orçamento do fôlego |
| S5 | `owners` e `timeLeftSeconds` preenchidos (H-13) | Leitura de 20 escadas | zero | Só a fase 3 |
| S6 | Depósito cobrado, corte, devolução em cada desfecho, destino do item cancelado (H-09, H-10) | O mesmo item barato vendido, expirado e cancelado | 3 depósitos | Custos da seção 7 |
| S7 | Fatura lida antes de abrir a carta; atraso do correio (H-11, H-12) | Com as vendas de S6 | zero | Conciliação do correio |
| S8 | Compra: argumentos, duração da cotação, eco, entrega (H-17, H-18, H-10) | Uma commodity de poucos cobres e um item barato | poucos cobres | Viabilidade da compra por tecla |
| S9 | Eventos de ação feita por fora chegam ao addon (H-25) | O dono posta e cancela pela tela da Blizzard | 1 depósito | Linha de base da régua |
| S10 | Ordem entre preços iguais (H-14) | Passivo: quantidade própria contra a do degrau em fotos seguidas. Sem comprador combinado. | zero | Igualar ou cobrir |

Ficam sem medida pelo addon: `ReplicateItems`, a visão entre facções (base 11.4, 11.8) e os tempos de ausência, que o dono anota (H-24).

## Apêndice B: tabela de parâmetros

Os parâmetros do jogo estão na seção 7.6 e os tetos, na seção 9.2. Os demais, todos do `Config.lua`:

| Parâmetro | Valor inicial | Origem |
|---|---|---|
| `modo` | `vivo` se DD1a for sim; senão `leitura` | seção 4.3 |
| `piso_pessoal` | 1 ouro | DD4 |
| `T_ver` | 1 s mais `remoto.latencia_ms` (150 de partida, a medir) | D6, D2 |
| Repetição ignorada; rajada | 400 ms; 6 teclas em 2 s | D2, D6 |
| Validade do bilhete; corte da confirmação | 20 s; menos de 5 s de cotação | D4, D6 |
| Idade máxima da foto para agir | 30 s | R9 12-C (`A_exec`) |
| Fôlego | 20 buscas ou 60 s; resumo a cada 10 min; 30 buscas por minuto | projeto; troca pela S4 |
| Prazo de consulta; prazo do eco; throttle travado | 10 s; 10 s; 30 s | projeto; troca pelo medido |
| Filtro de isca | menos de 5% da janela, salto de 15% | R9 12-C |
| Referência forte | 5 leilões na mesma chave | D4 |
| Faixa de postagem | de `v/(1−c)` a 3 vezes a referência | R8b R8; D5 |
| `tiquete` | 15 cobre por tecla | D5 |
| `μ_min`, a margem mínima de compra | 0,15 | D4, D5 |
| `η_real` | 1,0 no piso; 0,5 no resto | R9 5.7 |
| Portões | 30 sinais de papel em 5 dias; 30 lotes em micro; razão de 0,5 | D4 |
| Marcos de banca | 15 ouro; 60 ouro | D5 |
| Antiguerra | 2 cancelamentos em 4 h; coberto em 10 min; trégua de 4 h | D6; R9 12-C (`R_fast`) |
| Sugestão de salvar; teto do banco; `DESK STALE` | 45 min ou 50 ações; 3 MB; 7 dias | D1; J1; projeto |

## Apêndice C: glossário

| Termo | Sentido neste design |
|---|---|
| Ação | Uma das oito chamadas que compram, postam, confirmam ou cancelam |
| Banca; piso pessoal | O ouro que o addon pode arriscar; o ouro que ele não toca |
| Bilhete | O resumo de uma ordem que gasta, mostrado antes da tecla `Y` |
| Cofre | O módulo de risco que autoriza ou nega cada ordem |
| Commodity | Item empilhável que o leilão vende por quantidade |
| Corte; depósito | A parte da venda que a casa retém; o valor pago ao postar |
| Disjuntor | Trava automática que suspende um tipo de ação |
| Eco | O evento do jogo que confirma uma ação |
| Escada; degrau; vão | A lista de preços à venda de um item; cada preço dela; a distância entre dois degraus |
| Fôlego | Uma rodada limitada de consultas, aberta por uma tecla |
| Foto | O registro de uma resposta do leilão, com hora e completude |
| INCERTO | Estado de uma ação sem eco: bloqueia e concilia, nunca reenvia |
| Isca; parede | Degrau pequeno e barato seguido de salto; degrau grande, de poucos donos |
| Licença | O nível de uma estratégia: desligada, papel, micro ou plena |
| Livro, régua | O registro de ações, lotes e sessões, e as medidas que saem dele |
| Mesa | O que roda fora do jogo |
| Papel; sombra | Sinal registrado sem gastar ouro; regra alternativa calculada ao lado, sem virar conselho |
| Piso (estratégia) | Arrematar abaixo do preço que o vendedor NPC paga |
| `P*` | A chance de venda a partir da qual o leilão paga mais que o vendedor |
| Referência | O preço de mercado que o addon aceita como base: forte, fraca ou nenhuma |
| Sonda | O roteiro de medidas feitas no jogo |
| Tíquete | O valor mínimo que uma tecla precisa render para a linha entrar na fila |
| Venda inferida | Venda dos outros deduzida da diferença entre duas fotos da escada; é limite inferior |

## Conflitos abertos

O que os projetos e os juízes deixaram sem resolver, e como ficou.

| # | Ponto | Posições | Decisão e por quê |
|---|---|---|---|
| 1 | Espinha | J1, J3: D4. J2: D5. | D4 na estrutura, D5 na ordem de entrega: os três pedem a mesma soma. |
| 2 | Teclas por compra | J1: uma para item abaixo de um teto. J2: segunda só com estado intermediário ou bilhete grande. J3: dois tempos sempre. | Dois tempos em toda compra (J3): a regra 1 do dono pesa mais que a vazão, e com 5 ouro a tecla não é o gargalo (J2). Postar e cancelar em uma tecla. Rever com a taxa de erro medida em papel. |
| 3 | Tecla única ou por verbo | D2, D5: única. Os três juízes: por verbo. | Por verbo, com uma só tecla de confirmar. |
| 4 | Ação sem resposta | D3, D5: falhou, tecla rearmada. D1, D4, D6: INCERTO. | INCERTO: rearmar com falha muda e throttle desconhecido leva a ação em dobro (J1). |
| 5 | Gatilho da varredura | D1, D2: presença de 90 s. J2, J3: uma tecla por rodada. J1: fôlego que qualquer tecla renova. | Uma tecla por rodada; a renovação do J1 fica como opção desligada. |
| 6 | Correio | D2, D3: tecla no botão da Blizzard. D1, D6: tecla por carta. D4, D5: só leitura. | Só leitura, como recomendação DD1c. O J1 notou que estender a decisão de 2026-11-06 ao correio não vem da base: aqui o motivo são as incógnitas, não aquela decisão. |
| 7 | Confirmar commodity sem tecla | D2, D3, D5 oferecem. D4 e J3 recusam. | Recusada e não oferecida. |
| 8 | Conta de compra do R9 | D1, D2, D4, D6: desconto na saída. D3: no ganho. | No ganho; a outra reprova tudo abaixo de 100% de margem. |
| 9 | Preço de postagem | D1, D3, D4, D6: `W*` decide. D2: regra com fonte. D5: chance de venda sem fonte. | Regra com fonte escolhida pelo dono, `P*` na tela, `W*` em sombra. Nenhuma chance de venda sem medida aparece. |
| 10 | Queda de 7% ao dia | D4 e D6 fixaram prazos nela; os três juízes: a base 6.1 não autoriza. | Removida. A deriva é medida por categoria. |
| 11 | Banca | D3: os quatro personagens. | Só o logado (base 4.2). |
| 12 | Tamanho | D4: 2% por ordem. D6: 25% por nicho. J2: 20% por linha depois de sondagem de 2%. | Duro de 20% por item e 10% por ordem; partida de 10% e 5%; confirmação de 2%. |
| 13 | Arbitragem de vendedor | D5: estratégia de entrada. J2: medir de graça; não é a tese. | Medida na onda 2; ligada na onda 4 só se a prova passar. |
| 14 | Mesa e `/reload` | D3: vigia e sync a cada bloco. | Sem processo de fundo; `/reload` é ponto de salvamento. Os contratos do D3 valem desde já. |
| 15 | Nomes de vendedor e ficha de terreno | D6: guarda, mostra e dá veredito por nicho. | Nada gravado nem mostrado; a ficha, se existir, é relatório da mesa na fase 3. G1 e G2 entram sem nome. |
| 16 | Ordem entre preços iguais | D2, D4: teste com segundo jogador. | Só passivo: compra combinada é o desenho que a base 1.10 manda evitar. |
| 17 | Roda do mouse | Cinco projetos citam a base 5.1 para não usá-la. | A citação não sustenta o fato (J1). Fica como escolha de desenho. |
| 18 | Fatura antes de abrir a carta; item cancelado no correio | Tratados como fato por vários projetos. | Hipóteses H-11 e H-10, com caminho alternativo. |
| 19 | Treino dentro do jogo, exploração `TEST`, alternância de passos de preço | D2, D1, D6 | Treino vira `modo = "papel"` no arquivo. Experimento com o depósito do dono fica fora: as regras são comparadas em sombra. |
| 20 | Postar pelo Auctionator na onda 0; código de licença aberta na fase 3 | D5 | A postagem por ele no Forever não foi vista (base 4.3): a onda 0 fala só da tela da Blizzard. Reusar código de terceiro fica fora; adotar a ferramenta inteira é a decisão DD12. |

**Continua aberto, e só o jogo ou o dono fecha:** a H-01 (a tecla), a H-03 (a gravação), a H-11 (a fatura), a regra de preço em commodity, o valor do tempo do dono e o que fazer quando a banca chegar a 60 ouro. O R9 segue sem revisor matemático: nada dele decide gasto antes de vencer, no registro do próprio addon, a regra com fonte.

