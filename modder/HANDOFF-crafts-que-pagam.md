---
frente: crafts-que-pagam
status: ativa
atualizado: 2026-11-16T15:14-03:00
maquina: Avell
temas: [jogos, analise-dados]
proximo_passo: "Dono: usar a lista por alguns dias (varredura do Auctionator, comando de exportação, /reload, baixar-precos e crafts) e dizer o que faltou ou errou"
decisoes_abertas: 1
commit: 286e013
sensivel: false
---

> Frente: crafts-que-pagam · Atualizado: 16/11/2026 15:14 · Máquina: Avell

> **O que é esta frente.** Uma lista, fora do jogo, de quais receitas de Leatherworking do WoW Forever pagam: vendendo o item ao vendedor, subindo a perícia sem perder ouro, ou vendendo no leilão. São ferramentas Node em `C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao\`, feitas em 16/11/2026 e testadas com dado real e no jogo. É a estratégia "conversão" do PregaoForever, antecipada em modo leitura: nada compra, posta ou vende.
>
> **Leia isto mais um arquivo e você retoma do zero:** `C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao\CONTRATO.md` (regras de cálculo, formato dos arquivos, o comando de exportação e a seção 4.1, "Uso"). Os limites fixos do projeto estão em `C:\GMS\Claude Code Projects\wow\CLAUDE.md`.
>
> **Não releia nem refaça:** o `DESIGN.md` do PregaoForever (44 mil palavras; esta frente não depende dele para rodar), a identificação da casa de leilão (é a `us-111`, conferida) e a conferência das tabelas do cliente contra o jogo.
>
> ⚠️ **Preço envelhece rápido.** A lista só usa a exportação do Auctionator com até 6 horas, e o arquivo público atrasa cerca de uma hora. Antes de decidir um craft, refaça a varredura e a exportação.
>
> ⚠️ **A lista não sabe quais receitas o personagem tem.** Ela filtra pela perícia de aprender, que é exata só para receita que vem de item (388 de 482) e estimada nas de treinador ("amarela menos 25"). Linha marcada `i` exige o padrão.
>
> ⚠️ **Código de addon de terceiro não é referência.** Do Auctionator só se usa a API pública, pelo comando colado no jogo, e um bloco de preços de vendedor legível no arquivo dele. Mesma regra da frente `pregaoforever`.
>
> ⚠️ **Os commits desta frente estão só no Avell, sem push.** Em outra máquina, rode o Sincronizar antes. A pasta `dados\pregao\` não vai pelo git: lá ela se refaz com os dois primeiros comandos de "Como retomar".

## Estado em uma tela

- **Projeto:** `C:\GMS\Claude Code Projects\wow`, agente wow-modder (subpasta `modder`). **Ferramentas:** `modder\ferramentas\pregao\`. **Dados gerados:** `modder\dados\pregao\` (fora do git).
- **Jogo:** WoW Forever, cliente 1.60.1 build 70938 (observado em 16/11/2026, no `.build.info`). Personagem: Hexumlite Bull, Leatherworking 186 (inferido: dito pelo dono em 16/11/2026).
- **Status:** pronto e em uso. Os três checadores passam com erro zero (observado em 16/11/2026). O comando de exportação rodou no jogo e trouxe 6.876 preços (observado em 16/11/2026).
- **Fontes de preço, aprovadas pelo dono em 16/11/2026:** a varredura completa do Auctionator, como preço principal, e o arquivo público por hora `RuslanMunasipov/quest-murder-prices`, casa `us-111`, para profundidade, liquidez e conferência.
- **Última lista (perícia 186, varredura das 15h04 de 16/11/2026):** no vendedor só pagam Raptor Hide Harness (3s 66c) e Barbaric Leggings (81c), as duas já cinza; 14 receitas dão ponto e têm lucro no leilão se venderem; a mais barata por ponto é a Dusky Boots (observado em 16/11/2026).
- **O que falta, em uma frase:** o dono usar a lista e dizer o que faltou; depois, o painel dentro do jogo, que pede plano próprio.

## O que já foi feito (não refazer)

1. **Entrevista com o dono** (16/11/2026). Decisões fechadas, gravadas em `estado\estado.md`, tabela "Decisões do dono": lista fora do jogo agora e painel depois; os três objetivos (vendedor, perícia, leilão); todas as receitas de Leatherworking; coluna de liquidez com aviso; execução por subagentes econômicos; painel só depois de usar a lista.
2. **Contrato e módulo comum:** `ferramentas\pregao\CONTRATO.md` e `comum.mjs` (caminhos, leitor de CSV, download das tabelas do cliente com cache, pasta SavedVariables sem gravar o nome da conta).
3. **`gerar-receitas.mjs`:** tira das tabelas do cliente as 482 receitas de Leatherworking, com reagentes, produto, faixas de cor, item de receita e preços de vendedor; grava `dados\pregao\receitas-lw.json`. O modo `--conferir-vendedor` compara o preço de compra da tabela com o que o Auctionator viu em vendedores: 386 comparados, 227 iguais, 159 com desconto de reputação, nenhum divergente (observado em 16/11/2026).
4. **`baixar-precos.mjs`:** baixa a foto pública da hora (com SHA-256), as saídas por dia e a lista de itens de vendedor, lê a exportação do Auctionator e grava `dados\pregao\precos.json`.
5. **`crafts.mjs`:** função pura `calcular()` e a linha de comando que imprime a lista em até 40 linhas. Custo pelo menor entre leilão, vendedor e fabricar o intermediário.
6. **Testes e checadores** em `ferramentas\pregao\testes\`: `testar-crafts.mjs` (4 casos de preço fixo, 131 campos), `checar-receitas.mjs`, `checar-precos.mjs` (observado em 16/11/2026: os três com `erros=0`).
7. **Teste no jogo** (16/11/2026, 15h04): o dono rodou a varredura completa e colou o comando; o chat mostrou `6876 ok /reload`. A casa `us-111` ficou confirmada: 86% dos 6.448 itens em comum a até 5% da varredura. O tooltip da Barbaric Leggings mostra 31s 51c, igual à tabela (observado em 16/11/2026).
8. **Registros:** `estado\estado.md` (decisão, uma pendência recorrente do dono, a pendência do painel e duas entradas no diário); três linhas em `C:\GMS\Claude Code Projects\skill-review\reviews\calibracao.jsonl` (466 a 468); entrada nova no `.gitignore` da raiz para `wow/modder/dados/`.
9. **Commits, locais e sem push:** `7a357d0` e `286e013` em `C:\GMS`.
10. **Second brain:** `/sb` concluído em 16/11/2026. Destilado e adendo em `C:\GMS\Claude Code Projects\Obsidian\GMS-SB\raw\` (`2026-11-16-crafts-pregaoforever-precos-leilao.md` e `-adendo.md`); duas páginas novas no vault ("Leatherworking Crafts List Outside the Game ..." e a página da sessão) e dois reforços em `AI-Assisted Work Process.md`. O checador estrutural do vault deu 0 erros (observado em 16/11/2026).

## Decisões abertas

1. **Onde nasce o painel dentro do jogo.** O dono escolheu em 16/11/2026 que o painel é a primeira fatia do PregaoForever, em modo leitura. Falta decidir, quando o plano for pedido: (a) um addon mínimo próprio agora, só com a aba de crafts, que não espera as seis decisões da frente `pregaoforever` mas cria estrutura que a onda 1 dela vai refazer; ou (b) a aba entra na onda 2 do PregaoForever (a régua), com `.toc`, kit visual e pontes já no contrato, e espera as decisões e a onda 0 daquela frente. Não decida pelo dono.

## Próximos passos concretos

1. **Dono:** usar a lista por alguns dias e dizer o que faltou ou errou. O roteiro de cada consulta está em "Como retomar".
2. **Dono:** rodar o atalho Sincronizar. Em 16/11/2026 o `main` de `C:\GMS` estava 8 commits à frente e 5 atrás do remoto (observado em 16/11/2026).
3. **Agente, quando o dono pedir:** plano do painel dentro do jogo, com roteamento por tarefa e a decisão aberta 1 levada a ele antes de qualquer código. O painel lê do jogo as receitas que o personagem sabe e o preço de venda ao vendedor, o que tira as duas estimativas da lista de fora. Ligar addon novo exige o jogo fechado.
4. **Agente, só se o dono pedir:** outras profissões (o gerador hoje só lê a linha 165, Leatherworking); nomes no lugar de ids na linha de divergências; liquidez de armadura, que o arquivo público não traz.

## Como retomar (comandos exatos)

Abra a sessão em `C:\GMS\Claude Code Projects\wow\modder`. Pré-requisito: Node (v24 no Avell). Nenhum comando escreve na pasta do jogo.

Conferir que está tudo de pé (Bash):

```bash
cd "/c/GMS/Claude Code Projects/wow/modder/ferramentas/pregao"
node gerar-receitas.mjs && node testes/checar-receitas.mjs
node baixar-precos.mjs && node testes/checar-precos.mjs
node testes/testar-crafts.mjs
```

Resultado esperado: três linhas finais com `erros=0`; `receitas=482`; a linha `auctionator:` com a hora da exportação, ou `sem exportacao` se o dono ainda não exportou.

Uma consulta, do começo ao fim:

1. No jogo, com o leilão aberto: **Scan auction house** (botão do Auctionator) e esperar terminar.
2. Colar no chat o comando da seção 4 do `CONTRATO.md` (linha que começa em `/run local A,t,n=Auctionator.API.v1`). Deve aparecer um número seguido de `ok /reload`.
3. Digitar `/reload`.
4. Fora do jogo (PowerShell ou Bash), trocando 186 pela perícia atual:

```
cd "C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao"
node baixar-precos.mjs
node crafts.mjs --pericia 186
```

`--linhas 10` mostra mais linhas por seção; `--todas` tira o filtro de perícia de aprender. `node gerar-receitas.mjs` só precisa rodar de novo quando o build do cliente mudar (constante `BUILD` em `comum.mjs`).

## Gotchas

- **O banco de preços do Auctionator no disco é um bloco codificado.** Não tente ler `AUCTIONATOR_PRICE_DATABASE` do arquivo; o caminho é o comando de exportação pela API pública.
- **`AUCTIONATOR_VENDOR_PRICE_CACHE` é o preço que o vendedor cobra,** por unidade e com desconto de reputação, não o que ele paga. Serve para conferir o preço de compra da tabela, não o de venda.
- **O `BuyPrice` do `ItemSparse` é o preço do lote** de `VendorStackCount` unidades. Sem dividir, 52 itens pareciam divergir do jogo.
- **Não identifique a casa pública por contagem contra arquivo velho.** A sessão escolheu a `us-110` assim e errou: em duas horas a 110 foi de 7.069 para 4.028 unidades de Heavy Leather e a 111 de 3.154 para 7.115. Compare percentil e mediana com o arquivo da mesma hora, ou a varredura inteira contra cada casa.
- **110 receitas das tabelas não existem no jogo** (produto sem linha no `ItemSparse`). Se a contagem voltar a 592, o filtro quebrou.
- **As saídas por dia do arquivo público só cobrem item empilhável** (27 produtos de Leatherworking). Para armadura a coluna fica vazia.
- **Abra a sessão em `wow\modder`, não em `random_shit\modder`.** A sessão de 16/11/2026 abriu na pasta errada e teve de usar caminho absoluto em tudo.
- **Outra sessão no mesmo repositório** (a frente `pregaoforever`): commit só por caminho, e `estado\estado.md` e `HANDOFFS.md` são compartilhados; edite-os no fim, com a outra sessão parada.
- **Não copie o nome real da pasta da conta** (`WTF\Account\...`) para arquivo do projeto; use `pastaSavedVariables()` do `comum.mjs`.

## Estado do repo e da plataforma

- **`C:\GMS`** (branch `main`): `286e013` "feat(wow): lista de crafts cruza pericia com leilao; exportacao do Auctionator conferida no jogo", sobre `7a357d0` "feat(wow): lista de crafts de Leatherworking que pagam, fora do jogo (PregaoForever)". Sem push; 8 à frente e 5 atrás do remoto (observado em 16/11/2026). Este handoff e o `HANDOFFS.md` foram gravados depois do `286e013`.
- **Invisível ao repositório:**
  - o banco do GuiaForever nas SavedVariables do jogo ganhou a chave `ah`, com cerca de 6,9 mil preços, escrita pelo comando de exportação; cada exportação a substitui;
  - `modder\dados\pregao\` (tabelas do cliente em cache, arquivos públicos, `receitas-lw.json`, `precos.json`) só existe no Avell e se refaz pelos comandos acima;
  - as três linhas do `calibracao.jsonl` estão no repositório `skill-review`, sem commit desta sessão;
  - o ingest no vault GMS-SB (oito arquivos tocados) ficou sem commit desta sessão; o Sincronizar o leva.
- **Fonte externa:** o arquivo público depende de um repositório de terceiro continuar publicando. Sem ele, a lista ainda roda só com a exportação do Auctionator, mas sem o lucro conservador, sem "até" e sem liquidez (não testado).

## Referências rápidas

| Preciso de | Onde |
|---|---|
| Regras de cálculo, formato dos arquivos e o comando de exportação | `ferramentas\pregao\CONTRATO.md` (seções 3, 4, 4.1 e 5) |
| Decisões do dono, pendências e diário | `estado\estado.md` (linhas de 16/11/2026) |
| A outra frente do mesmo addon | `HANDOFF-pregaoforever.md`, nesta pasta |
| O desenho do PregaoForever (estratégia `conversao`, mesa externa, dados estáticos) | `addons-proprios\PregaoForever\DESIGN.md`, seções 3.2, 12 e 13 |
| Fatos do leilão com fonte | `addons-proprios\PregaoForever\pesquisa\base-de-fatos.md` |
| Roteiro de Leatherworking que o dono segue | `addons-proprios\GuiaForever\ProfissoesB.lua` |
| Limites fixos do projeto | `C:\GMS\Claude Code Projects\wow\CLAUDE.md` |
