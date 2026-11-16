> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# Conferência da onda 4: o que o redator declarou e o que os três conferentes acharam

## Redator

Aplicados: 114; com ajuste da triagem: 55; não aplicados: 0.

Dúvidas que ele deixou para a sessão principal:

1. Releitura final incompleta no DESIGN.md: li de ponta a ponta o LEIA-ME e o DESIGN ate o comeco do Apendice A (corrigi 6 pontos); o resto do Apendice A, os Apendices B, C e D e a secao 'Decisoes de projeto e por que' so foram conferidos por grep (parametros, referencias, frases velhas). Vale uma leitura desses trechos.
2. Metodo: troquei secoes inteiras com um script (tmp/REDATOR/trocar.mjs) a partir de arquivos por secao em tmp/REDATOR, em vez de Edit direto no DESIGN.md. O efeito e o mesmo (secao por secao sobre a copia), mas nao foi o Edit pedido.
3. Intervalo do veredito AUCTION: V3A-14 pede Wilson de 80% e V3B-10 pede 90%; a triagem nao decide. Adotei 80% (o V3A traz a conta), com faixa de 80 a 95% no Apendice B.
4. Cotas do foco: V3B-04 (8/4/4/4 mais vigilia) contra V4-11 (8/6/6 com prioridade por idade). Fiquei com as cotas do V3B-04, vigilia de ate 8 chaves e a prioridade por idade do V4-11 dentro de cada cota.
5. Deriva e historico (V3A-13, V3B-13, V4-09, V8-12 divergem): mantive 'dias', criei 'blocos' e 'giro'; a deriva so suspende compra e sai do EV (V3B-13); a formula de custo de carregar do V3A-13 ficou registrada para a fase 3.
6. Venda inferida: alem do par valido da T5, incluí do V3A-01 a exigencia de coorte com idade conhecida, e usei o casamento de repostagem sem nome do R9 2.3 eliminando a perda inteira (o R9 da peso 0,5). E mais restritivo que a T5 sozinha.
7. Numeros que precisei propor sem valor na triagem nem nos pareceres, todos marcados como proposta (DD10) ou escolha de projeto: piso absoluto do deposito perdido no dia (8 prata), k_t = 1 hora e peso 0,3 na triagem de giro, limites dos 8 baldes da cauda, anel de 500 acoes para os personagens que nao sao o negociador (T12 invalida os 200 'outside' do V4-07), tolerancia de divergencia de 10%, faixas do Apendice B que o R9 12-C nao cobre.
8. Numeracao criada por mim: hipoteses H-26 a H-39, decisoes DD13 (gatilho), DD14 (reservas) e DD15 (assinatura de vendedor), passos S11 a S13. Os comandos da sonda foram renumerados de 1 a 16 (os rotulos D1 e D2 do parecer V1 colidiam com a retirada de D1 a D6) e ganharam o 15 (tela, V5-10) e o 16 (cotacao, V6-07); os degraus da fase 3 viraram 'degrau 0 a 3' pelo mesmo motivo.
9. Telas: troquei 'pays if 1 in 6 sells' do V5-14 por '1 in 5' (N = piso de 1/P*, arredonda contra o leilao); o exemplo do bilhete virou Linen Cloth x16, porque com 4 teclas (V4-10) o x14 ficava abaixo do tiquete; a banca passou a incluir os depositos em leiloes ativos para o cabecalho fechar (V3A-17); 'budget used' ficou em 0.4 com definicao.
10. LEIA-ME: 3.800 palavras pelo wc, no teto da faixa, das quais cerca de 680 sao os desenhos das telas. As datas da linha do tempo sao hipotese minha, derivada das duracoes por onda, e estao marcadas assim. O fato sobre prazo de 30 dias da API de dados (V2-14) nao tem arquivo na lista de fontes: ficou escrito como 'a conferir na leitura dos termos'.

## Conferente C1

Conferidos: 55; aplicados: 55.

Contradições novas:

1. Apêndice B: `ritmo.acoes_min` tem faixa de 1 a 20, o que age como teto duro de 20 ações/min. A seção 0, a seção 9.2 e a regra 13 dizem que ritmo não é teto duro e que o máximo é o ritmo sustentado medido na S4.
2. Seção 17, onda 2: `Teclas` fica 'só de navegação (L, N, U, I, O, K, H, visões)'. Mas a visão Session, que também é da onda 2, tem o botão `[Y] save now`, e a seção 11.2 liga `Y` ao salvar. A tecla Y não tem onda definida em 4.1 e 17 para o salvamento.
3. Seção 18, abertura: 'a opção recomendada é o padrão do Config.lua'. Mas a DD3 diz que, sem a escolha do dono, a linha de commodity mostra `PICK RULE`, e a DD4(b) é 'sem recomendação'. O LEIA-ME parte 5 chama `igualar` de 'padrão já marcado' e, na mesma linha, de PICK RULE sem escolha: a regra tem padrão ou não?
4. Seção 9.4 e seção 8.2: a rajada pede `H` para rearmar, e `H` também é Hold, que 'solta ou rearma as teclas de ação' (11.2). Rearmar e soltar são o mesmo botão, e o texto não diz como `H` distingue os dois casos. A tecla tem dois sentidos.
5. Seção 5.2 diz que a opção (b) da DD13 é 'recomendada a partir da fase 2'. A DD13 marca 'Quando: onda 5', e o LEIA-ME põe o gatilho em 'ficam para mais tarde'. Mas a S11, que testa a vigília com presença, está marcada 'pode rodar desde a onda 2', antes de a DD13 ser decidida.
6. A numeração das hipóteses mudou em relação aos pareceres. O V7-20 pedia H-26 para `timeLeftSeconds` de leilão vendido, mas no texto final H-26 é o foco de teclado e `timeLeftSeconds` é H-27. A MUDANCAS.md acerta (H-27). Se o LEIA-ME ou o relatório citar H-26 para essa hipótese, vai divergir.

## Conferente C2

Conferidos: 59; aplicados: 58.

Pendentes:

- V4-07 (parcial), em DESIGN.md seção 6.2, tabela de tamanhos, linha 'pers de cada outro personagem': A tabela traz os valores medidos e a linha do correio, mas os personagens que não negociam ficaram com anel de 500 ações, 100 lotes e 100 faturas. A correção pedia só um anel de 200 ações 'outside'.

Contradições novas:

1. Duas réguas para 'o sinal ainda está lá'. A seção 7.4 e o Apêndice B exigem sobrevivência acima de 0,5 por faixa de desconto para gerar sinal executável em micro. A seção 3.2 (sniper) e o Apêndice B exigem 'já sumiu' de até 70% em 30 sinais, o que equivale a sobrevivência de pelo menos 0,3. As duas medem a mesma releitura da tecla B com limiares incompatíveis. Falta dizer qual vale para o sniper.
2. As seções 9.2 e 1 contradizem a regra 13. A regra 13 diz que o Config.lua só aperta e o teto duro é só do Tetos.lua. O piso absoluto dos tetos de depósito (cofre.piso_teto_deposito, faixa de 0 a 1 ouro, e o equivalente do perdido no dia) está no Config.lua e pode ficar acima da fração dura de B. A coluna 'Duro' da 9.2 diz 'o maior entre 5% e o piso absoluto', então o piso entra no teto duro mas sai de um arquivo que não pode subir teto.
3. A tabela de ritmo e a tabela de parâmetros divergem. A seção 9.2 diz que ritmo.acoes_min sobe por portão medido até o ritmo sustentado na sonda. O Apêndice B limita ritmo.acoes_min a 1 a 20, sem relação com o valor sustentado, enquanto ritmo.buscas_min tem 'máximo igual ao sustentado na S4'. Os dois parâmetros têm regra de máximo diferente.
4. A vigília com presença (opção b da DD13) é exigida pela S11 desde a onda 2: 'com a vigília com presença ligada só durante o passo'. Mas a DD13 só se decide na onda 5 e a H-31 (consulta não mexe na marca de ausente) só é medida na própria S11. A S11 usa o gatilho que a DD13 ainda não aprovou e que a H-31 ainda não confirmou.

## Conferente C3

Conferidos: 55; aplicados: 54.

Pendentes:

- V8-13 (parcial), em DESIGN.md 11.4, fluxo C (Cancelar e repostar), passo 2: Dizer, depois do cancelamento concluído, que a linha sai, a seguinte sobe para a posição do cursor com a marca NEXT e T_ver recomeça. Isso está em 8.2 e nos fluxos A.6 e B.5, mas não no fluxo C.

Contradições novas:

1. Teclas onda 2: 4.1 (linha 20) e 17 (onda 2) limitam Teclas à navegação (L, N, U, I, O, K, H e visões), sem Y nem M. Mas a visão Session da onda 2 salva com Y (11.2, 11.4 E) e a S1 (onda 2) precisa da 'tecla de salvar'. Falta Y de salvar na onda 2 ou usar o botão Save now.
2. Regra 19 (DESIGN.md linha 56) diz que o addon, o agente e a mesa escrevem só na pasta de desenvolvimento. Mas o addon grava SavedVariables em WTF (pelo cliente) e a seção 12 manda a mesa gravar o arquivo morto em wow/modder/dados/pregao/, fora da pasta do addon.
3. Regra de preço: o Apêndice B (linha 1836) diz 'sem padrão: PICK RULE'. A seção 18 diz que a recomendação é o padrão do Config.lua, e a DD3 e o LEIA-ME (parte 5) marcam 'igualar' como padrão. Falta dizer se o padrão é igualar ou PICK RULE até o sim do dono.
4. Decisões antes do código: a seção 0 e o LEIA-ME falam em seis decisões (DD1a, DD1b, DD3, DD4, DD9, DD14). Mas a DD6 (nome) está marcada 'antes da onda 1' e o portão da onda 1 pede DD5 e DD6; a DD10 só vale 'antes da onda 3'. O LEIA-ME manda o nome para 'mais tarde'.
5. Visão Risk (11.3 e LEIA-ME 6): EXPOSURE mostra 3 tetos e 'Show 6 more', ou seja 9. A tabela de 9.2 tem 10 tetos de exposição (o V5-13 contava 10), então o certo seria 'Show 7 more'.
6. Seção 17.1, tabela de banco: degraus 0 e 1 com 48 fotos por chave. A seção 6.2 diz 16 fotos por chave na fase 1 e 48 só na fase 2, e o degrau 0 cobre as fases 1 e 2.
7. Seção 0 (linha 13) e LEIA-ME 2 dão 20 a 30 prata por giro com 4 ouro e 50% em estoque. O parecer V8-07 e a conta da seção 9.2 apontavam 20 a 31 prata. É só arredondamento, mas dois números circulam no texto.
8. INCERTO (8.3, linha 915): fala em reconciliar 'depois da próxima abertura do leilão ou do correio (Press L to reconcile)'. Mas 11.2 e 11.3 dizem que o painel do correio não tem tecla, e a regra 9 só permite consulta por fôlego com L no leilão. Falta dizer que a conciliação após abrir o correio só acontece no próximo L, com o leilão aberto.

O destino de cada ponto está na seção "Conferência final" do `MUDANCAS.md`.
