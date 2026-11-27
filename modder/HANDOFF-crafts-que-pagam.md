---
frente: crafts-que-pagam
status: ativa
atualizado: 2026-11-16T18:07-03:00
maquina: Avell
temas: [jogos, analise-dados]
proximo_passo: "Dono: /reload no Hexumlite, conferir a rota em J > Professions > Mine e dizer quais dos quatro padrões não tem"
decisoes_abertas: 1
commit: 9c4a125
sensivel: false
---

> Frente: crafts-que-pagam · Atualizado: 16/11/2026 18:07 · Máquina: Avell

> **O que é esta frente.** Ferramentas Node, fora do jogo, que dizem quais receitas de Leatherworking do WoW Forever pagam e, desde 16/11/2026 à tarde, qual rota de perícia seguir. Moram em `C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao\`. Dão a lista (`crafts.mjs`: vendedor, perícia, leilão) e a rota (`rota.mjs`: a mais barata de uma perícia a outra, no pior caso). A rota também é gravada no addon próprio GuiaForever, na janela J. Só leem: nada compra, posta ou vende.
>
> **Leia isto mais um arquivo e você retoma do zero:** `C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao\CONTRATO.md` (seções 4.1 "Uso", 4.2 "Histórico diário", 5 "crafts.mjs" e 6 "rota.mjs"). Os limites fixos do projeto estão em `C:\GMS\Claude Code Projects\wow\CLAUDE.md`.
>
> **Não releia nem refaça:** o `DESIGN.md` do PregaoForever (esta frente não depende dele), a identificação da casa de leilão (é a `us-111`, conferida), a conferência das tabelas do cliente contra o jogo e o roteamento da onda R1/R2 (já executada e aprovada no gate).
>
> ⚠️ **Decisão do dono em 16/11/2026, restrição fixa:** "Não vou seguir mais nenhum roteiro de ninguém. Agora sou eu que crio os roteiros. Nossa tool é suprema." Vale só para o Leatherworking do Hexumlite Bull (escolha do dono). A rota sai da ferramenta e o dono aprova. O ReptilioPlays ficou só como dado de referência: treinadores, padrões, Merchant's Favor e requisitos de tier.
>
> ⚠️ **O trabalho da tarde de 16/11/2026 está sem commit, só no disco do Avell.** O dono escolheu fechar depois, com diário, commit por caminho, `/sb` e este handoff. A lista de arquivos está em "Estado do repo".
>
> ⚠️ **Preço envelhece rápido.** A exportação do Auctionator vale 6 horas, e o arquivo público atrasa cerca de uma hora. A rota do J fica com os preços do dia em que foi gerada.
>
> ⚠️ **A ferramenta não sabe quais receitas o personagem tem nem onde se compra cada padrão.** Receita de treinador tem a perícia de aprender estimada (`~`). A chance de ponto usa a fórmula do Classic, que não foi conferida no Forever.

## Estado em uma tela

- **Projeto:** `C:\GMS\Claude Code Projects\wow`, agente wow-modder (subpasta `modder`). **Ferramentas:** `modder\ferramentas\pregao\`. **Dados gerados:** `modder\dados\pregao\`, fora do git.
- **Jogo:** WoW Forever, cliente 1.60.1 build 70938 (inferido: handoff de 16/11/2026 15:14). Personagem: Hexumlite Bull, Leatherworking 186 (inferido: dito pelo dono em 16/11/2026).
- **Status:** a lista e a rota prontas; a rota está no J (GuiaForever 1.3.2), sem teste no jogo (não testado). Checadores: `testar-crafts` e `testar-rota` com erros=0, `checar-precos` com erros=0 e historico=6979 (observado em 16/11/2026).
- **Rota no J (preços da foto pública das 16h17 e da exportação das 15h04 de 16/11/2026):**

  | Faixa | Receita | Crafts | O NPC devolve do custo |
  |---|---|---|---|
  | 186-190 | Dusky Boots | 4 | 88% |
  | 190-200 | Swift Boots | 11 | 84% |
  | 200-205 | Skycaller's Mail Boots | 5 | 114% |
  | 205-225 | Wild Leather Vest | 21 | 92% |

  No total, 41 crafts e 27g 73s de materiais. No pior caso (tudo vendido ao NPC), a perda é de 2g 36s 66c, ou seja, 91% do custo volta. Se tudo vender no leilão, sobra 3g 81s 40c (observado em 16/11/2026). As quatro receitas pedem padrão.
- **O que falta, em uma frase:** o dono testar a rota no J e dizer quais padrões não tem; depois, fechar a sessão (commit, `/sb`, diário).

## O que já foi feito (não refazer)

1. **Entrevista com o dono** (16/11/2026). As decisões estão em `estado\estado.md`, na tabela "Decisões do dono": lista fora do jogo agora e painel depois; os três objetivos (vendedor, perícia, leilão); todas as receitas de Leatherworking; coluna de liquidez com aviso; execução por subagentes econômicos.
2. **Contrato e módulo comum:** `CONTRATO.md` e `comum.mjs`.
3. **`gerar-receitas.mjs`:** 482 receitas de Leatherworking das tabelas do cliente, gravadas em `dados\pregao\receitas-lw.json`.
4. **`baixar-precos.mjs`:** foto pública da hora (com SHA-256), saídas por dia, lista de itens de vendedor e exportação do Auctionator, gravados em `dados\pregao\precos.json`. **Desde 16/11/2026, também o histórico diário** `us-111-history.txt`: preço mínimo, preço do meio e unidades listadas por dia, armadura incluída. São 6.979 itens, de 11/11 a 15/11, gravados em `publico.historico` (observado em 16/11/2026).
5. **`crafts.mjs`:** a lista em até 40 linhas.
6. **Testes:** `testar-crafts.mjs` (4 casos, 131 campos), `checar-receitas.mjs` e `checar-precos.mjs`. Este último confere também o histórico, conforme a seção 4.2.
7. **Teste da exportação no jogo** (16/11/2026, 15h04): 6.876 preços (observado em 16/11/2026).
8. **Consulta da tarde de 16/11/2026 (perícia 186):**
   - O histórico mostrou que as Azure (no topo do lucro no leilão) têm mercado raso, de 1 a 6 listadas por dia, e preço caindo pela metade em quatro dias, e o NPC paga 0c por elas.
   - Só os Thick Armor Kit têm estimativa de venda (cerca de 256 e 376 por dia).
   - O Wild Leather Vest (aprende 200; laranja até 220, amarelo até 230) leva de 200 a 225 em cerca de 26 crafts (observado em 16/11/2026).
9. **Decisão do dono gravada** (ver o banner) em `estado\estado.md`, `..\jogadores\guilherme\jogador.md`, `..\comum\fontes\profissoes\roteiros.md`, `..\comum\fontes\profissoes\reptilio-leatherworking.md` e `..\jogadores\guilherme\personagens\hexumlite-bull.md`.
10. **`rota.mjs`** (onda R1/R2 com subagentes Haiku; contrato na seção 6): sobe um ponto por vez e, em cada ponto, escolhe a receita de menor `(custo - vendaNpc) / chance`. Cada receita tem um teto de crafts de 25% do listado do reagente mais escasso. Uso: `--de`, `--ate`, `--sem`, `--so`, `--lua`. Testes: `testes\caso-rota.json` e `testar-rota.mjs`, com 4 casos e 112 campos, conferidos à mão e por uma referência (observado em 16/11/2026).
11. **GuiaForever 1.3.2:** a rota da ferramenta entrou em `addons-proprios\GuiaForever\ProfissoesB.lua`, no lugar das faixas do ReptilioPlays. Ganhou as linhas extras "1-186 done" e "225-300 next route", e "Route patterns" virou "Pattern locations (reference)". Conferido: a sintaxe pelo `ferramentas\guia\checar-lua.mjs` e a leitura dos passos pela regra do J, com os totais da faixa Expert iguais aos da ferramenta (observado em 16/11/2026).
12. **Rotas mais rígidas, só com venda ao NPC:** com receitas que devolvem 90%, 95% ou 100% do custo, nenhuma sai do 186, porque entre 186 e 200 não há receita que dê ponto com retorno de 90% ou mais (observado em 16/11/2026). A rota atual já é a de venda ao NPC. Substitutas de 200 a 205, se faltar o padrão da Skycaller's Mail Boots: Mender's Mail Boots (104%), Prowler's Leather Shoes (95%), Skycaller's Leather Shoes (95%) e Mender's Leather Shoes (90%) (observado em 16/11/2026).
13. **Registros:** `estado\estado.md` (decisão, alteração de UI, duas pendências novas, GuiaForever 1.3.2 na tabela de addons; a pendência da rota do ReptilioPlays saiu) e duas linhas em `C:\GMS\Claude Code Projects\skill-review\reviews\calibracao.jsonl` (R1 e R2).
14. **Commits anteriores:** `7a357d0`, `286e013` e `bd46e09` em `C:\GMS`, sem push (inferido: handoff de 16/11/2026 15:14).
15. **Second brain:** `/sb` da manhã concluído (inferido: handoff de 16/11/2026 15:14). ⚠️ A página do vault sobre a lista diz que o arquivo público não traz liquidez de armadura. O `us-111-history.txt` corrige isso, e o `/sb` desta tarde ainda vai registrar a correção.

## Decisões abertas

1. **Onde nasce o painel dentro do jogo** (sem mudança desde 16/11/2026, 15:14). Há duas opções:
   - (a) um addon mínimo próprio agora, só com a aba de crafts;
   - (b) a aba entra na onda 2 do PregaoForever, depois das decisões e da onda 0 daquela frente.

   Não decida pelo dono.

## Próximos passos concretos

1. **Dono:** `/reload` no Hexumlite e abrir J > Professions > Mine, conferir as quatro faixas e os totais, e dizer quais padrões não tem. Para cada padrão que faltar, o agente roda `node rota.mjs --de <perícia> --ate 225 --sem "<receita>"`, mostra a prévia e troca no J com o ok.
2. **Agente, no fechamento** (o dono escolheu fechar depois), nesta ordem:
   - a entrada do diário em `estado\estado.md`;
   - o commit por caminho com os arquivos de "Estado do repo";
   - o `/sb`, com o histórico diário e as lições desta tarde (Gotchas);
   - a atualização deste handoff.
3. **Dono:** rodar o atalho Sincronizar. Em 16/11/2026, o `main` de `C:\GMS` estava 5 commits atrás do remoto, e o notebook do escritório não tinha feito o sync de saída (observado em 16/11/2026).
4. **Quando o dono pedir preços novos:** ele faz a varredura e a exportação no jogo (roteiro em "Como retomar"); o agente roda `baixar-precos` e `rota`, mostra a prévia e troca no J.
5. **Aos 225, já com o Artisan (perícia 200 e nível 35):** gerar a rota de 225 a 300 com uma exportação nova e trocar a linha "next route" no J.
6. **Só se o dono pedir:**
   - um modo "lucro no leilão" na rota (oferecido em 16/11/2026, sem resposta);
   - o painel no jogo (decisão aberta 1);
   - outras profissões (o gerador só lê a linha 165);
   - nomes no lugar de ids nas divergências.

## Como retomar (comandos exatos)

Abra a sessão em `C:\GMS\Claude Code Projects\wow\modder`. O pré-requisito é o Node (v24 no Avell). Nenhum comando escreve na pasta do jogo.

Conferir que está tudo de pé (Bash):

```bash
cd "/c/GMS/Claude Code Projects/wow/modder/ferramentas/pregao"
node testes/testar-crafts.mjs && node testes/testar-rota.mjs && node testes/checar-receitas.mjs
node baixar-precos.mjs && node testes/checar-precos.mjs
```

O esperado é `erros=0` nas quatro linhas finais e a linha `historico: dias=... itens=... ignoradas=0`.

Uma consulta, do começo ao fim:

1. No jogo, com o leilão aberto, clique em **Scan auction house** (Auctionator) e espere terminar.
2. Cole no chat o comando da seção 4 do `CONTRATO.md` (a linha que começa em `/run local A,t,n=Auctionator.API.v1`). Deve aparecer um número seguido de `ok /reload`.
3. Digite `/reload`.
4. Fora do jogo:

```
cd "C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao"
node baixar-precos.mjs
node crafts.mjs --pericia 186
node rota.mjs --de 186 --ate 225
node rota.mjs --de 186 --ate 225 --lua
```

Para trocar a rota no J, substitua em `addons-proprios\GuiaForever\ProfissoesB.lua`, no bloco `["Leatherworking"]`, as linhas de `passos` entre "Done before the tool route" e "Next route" pela saída do `--lua`. Atualize também `data = "prices of ..."`. Depois confira com `node ferramentas\guia\checar-lua.mjs addons-proprios\GuiaForever` (código 0). O dono dá `/reload`.

## Gotchas

- **O release público é regravado aos poucos, e o `index.txt` sobe por último.** No meio da atualização, o SHA-256 não bate e o `baixar-precos` sai com código 2, sem gravar nada. Isso é o contrato funcionando, não um bug. Tente de novo em alguns minutos; em 16/11/2026 alinhou depois de cerca de 5 minutos (observado em 16/11/2026).
- **Barra invertida dentro de um heredoc do Git Bash pode sumir**, e `\r` vira retorno de carro. Um comentário Lua com `ferramentas\pregao\rota.mjs` quebrou o `ProfissoesB.lua` (`'}' expected`), e o checador pegou. Em texto que vai para Lua, use `/` ou edite pelo Edit (observado em 16/11/2026).
- **`ferramentas\guia\rodar-janela.mjs` não cobre a aba de profissões:** passou até com o `ProfissoesB.lua` quebrado. Confira a rota pelo `checar-lua.mjs` e pela regra do J (`partesPasso` e `lerMateriais` em `Abas.lua`).
- **O histórico tem 5 dias, não 30,** porque o jogo é novo (de 11/11 a 15/11 em 16/11/2026) e é refeito uma vez por dia, perto da meia-noite UTC. Ele mostra anúncios, não vendas.
- **O teto de crafts vale por receita.** Reagente comum a duas receitas não soma entre elas: Wildvine e Heavy Leather podem passar de 25% somando a rota inteira.
- **O banco de preços do Auctionator no disco é um bloco codificado.** O caminho é o comando de exportação pela API pública.
- **O `BuyPrice` do `ItemSparse` é o preço do lote.** O mesmo vale para o `AUCTIONATOR_VENDOR_PRICE_CACHE`, que é o que o vendedor cobra (ver o CONTRATO, seção 3).
- **Não identifique a casa pública por contagem contra um arquivo velho** (a `us-110` foi escolhida por engano em 16/11/2026).
- **Outra sessão no mesmo repositório,** na frente `pregaoforever`: há código novo do PregaoForever sem commit, um `estado\addons\dev-pregaoforever.json` e linhas no `estado\registro.md`. Commit só por caminho. O `estado\estado.md` e o `HANDOFFS.md` são compartilhados: confira o diff antes de commitar.
- **Não copie o nome real da pasta da conta** para um arquivo do projeto; use `pastaSavedVariables()`.

## Estado do repo e da plataforma

- **`C:\GMS`** (branch `main`), HEAD `9c4a125`. O último commit desta frente é `bd46e09` "docs: handoff crafts-que-pagam". O `main` estava 5 commits atrás do remoto (observado em 16/11/2026).
- **Sem commit, desta frente** (o que entra no commit do fechamento):
  - `modder\ferramentas\pregao\CONTRATO.md`, `baixar-precos.mjs`, `rota.mjs` (novo), `testes\checar-precos.mjs`, `testes\caso-rota.json` (novo) e `testes\testar-rota.mjs` (novo);
  - `modder\addons-proprios\GuiaForever\ProfissoesB.lua` e `GuiaForever.toc`;
  - `jogadores\guilherme\estado\estado.md`;
  - `jogadores\guilherme\jogador.md`, `comum\fontes\profissoes\roteiros.md`, `comum\fontes\profissoes\reptilio-leatherworking.md` e `jogadores\guilherme\personagens\hexumlite-bull.md`;
  - este arquivo e o `modder\HANDOFFS.md`.

  As duas linhas novas de `C:\GMS\Claude Code Projects\skill-review\reviews\calibracao.jsonl` estão em outro repositório.
- **Não é desta frente:** todo o `addons-proprios\PregaoForever\` novo ou alterado, `estado\registro.md`, `estado\addons\dev-pregaoforever.json` e `ferramentas\guia\casos-pregao\` e `ferramentas\guia\pregao\`.
- **Invisível ao repositório:**
  - a chave `ah` no banco do GuiaForever, nas SavedVariables (a exportação das 15h04);
  - `modder\dados\pregao\` (só no Avell; refaz com os comandos acima);
  - os arquivos de análise da tarde no scratchpad da sessão (descartáveis).
- **Fonte externa:** `RuslanMunasipov/quest-murder-prices`, release `current`, de terceiro. Sem ele, a lista e a rota rodam só com a exportação do Auctionator, mas sem histórico, sem `p25` e sem liquidez (não testado).

## Referências rápidas

| Preciso de | Onde |
|---|---|
| Regras de cálculo, formatos, comando de exportação e rota | `ferramentas\pregao\CONTRATO.md` (seções 3, 4, 4.1, 4.2, 5 e 6) |
| Decisões do dono, alterações de UI, pendências e diário | `estado\estado.md` (linhas de 16/11/2026) |
| A rota no jogo | `addons-proprios\GuiaForever\ProfissoesB.lua`, bloco `["Leatherworking"]` |
| Como o J lê a rota | `addons-proprios\GuiaForever\Abas.lua` (`partesPasso`, `lerMateriais`, `totaisPorFaixa`) |
| A outra frente do mesmo addon | `HANDOFF-pregaoforever.md`, nesta pasta |
| Treinadores e padrões (referência) | `..\comum\fontes\profissoes\reptilio-leatherworking.md` |
| Limites fixos do projeto | `C:\GMS\Claude Code Projects\wow\CLAUDE.md` |
