---
frente: waylaid-crates
status: ativa
atualizado: 2026-11-18T01:36-03:00
maquina: Avell
temas: [jogos, analise-dados]
proximo_passo: "T1: gerador ferramentas\\compra\\gerar-caixas.mjs que grava addons-proprios\\CompraForever\\Caixas.lua com as 30 caixas tipadas"
decisoes_abertas: 2
commit: 5f1c42f
sensivel: false
---

> Frente: waylaid-crates · Atualizado: 18/11/2026 01:36 · Máquina: Avell

> **O que é esta frente.** Pedido do dono em 18/11/2026: "quero que nosso addon fodastico de auction house também trackeie waylaid crates e os mats correspondentes". O addon é o **CompraForever**, addon próprio do WoW Forever, que mora em `C:\GMS\Claude Code Projects\wow\modder\addons-proprios\CompraForever\` e está ligado ao jogo por junction. O fluxo dele: na AH, o dono clica Scan, o painel mostra o plano e um botão faz uma ação por clique (cotar, confirmar, comprar no vendedor, craftar, vender). A frente acrescenta as **Waylaid Crates**: caixas que se enchem com um pacote de materiais e se entregam em troca de **Merchant's Favor**.
>
> **Leia isto e mais estes arquivos para retomar do zero:**
> - `C:\GMS\Claude Code Projects\wow\CLAUDE.md` (limites fixos e estilo de resposta);
> - `C:\GMS\Claude Code Projects\wow\modder\.claude\agents\wow-modder.md` (o agente);
> - `addons-proprios\CompraForever\CONTRATO.md` (seções 1 a 9: arquivos, Dados, Núcleo, Planejador, Scanner, Compra, Painel, sonda e bancada);
> - `C:\GMS\Claude Code Projects\wow\comum\referencia\profissoes-forever.md`, seção "Waylaid Crates (conferido em 2026-11-18)", com a tabela das 30 caixas e dos pacotes;
> - `comum\referencia\api-forever.md` §3g (API do leilão do Forever: o que é restrito a clique).
>
> **Não releia nem refaça:** a pesquisa do sistema de caixas (já está na referência, com fontes) e o desenho do CompraForever 0.1.0 (já validado no jogo pelo dono: "Ficou EXCEPCIONAL").
>
> ⚠️ **Limites fixos (CLAUDE.md da pasta wow):** só a API oficial; nada de automação: **um clique de hardware faz no máximo uma ação de leilão** (invariante I1 da bancada). Encher a caixa e entregá-la são ações do dono, guiadas por passos. Sem código de addon de terceiro como referência (regra do dono de 16/11/2026). Ler preço pela API pública do Auctionator é permitido: o GuiaForever já faz isso, em `Crafts.lua`.
>
> ⚠️ **O Favor por caixa vem de relatos de jogadores** (outof.games), não da Blizzard. Confira no jogo na primeira entrega.

## Estado em uma tela

- **Status:** só o plano, nenhum código escrito. O dono escolheu "Só o plano" para a execução e "Orçamento de Favor" para o botão (observado em 18/11/2026).
- **Personagem:** Hexumlite Bull, Night Elf Hunter, Leatherworking 205 e Skinning; nível abaixo de 35 (dito pelo dono em 18/11/2026). Por isso as caixas Artisan (nível 35) ficam fora por enquanto. Ele tem umas 180 Heavy Leather sobrando, compradas a 1s 68c, que enchem a Expert Textiles (20 Heavy Leather, nível 20) (inferido: conta da sessão de 17/11/2026).
- **O que se sabe das caixas** (detalhe e fontes na referência):

  | Fato | Valor |
  |---|---|
  | Caixa genérica | `Waylaid Crate` 248549; ao usar, vira uma tipada |
  | Caixas tipadas | 30 ids, de 248682 a 248713; empilham até 5; vendem na AH |
  | Pacotes | lista no tooltip: "Fill the crate with any bundle from the following list: - 20 Wool Cloth - 40 Silk Cloth - 20 Medium Leather" |
  | Favor (relatos) | Apprentice 5/10, Journeyman 10/20, Expert 15/30, Artisan 20/40 (coleta/fabricado); a primeira caixa abre uma missão de 50 Favor |
  | Entrega (Aliança) | Marcy Baker, Azeroth Commerce Authority, Three Corners, Redridge Mountains |

- **Ranking com os preços da exportação das 21:45 de 17/11/2026** (observado em 18/11/2026; o script foi feito na hora, não está no repo): Apprentice Fabrics 1s 60c por Favor (12s a caixa e 2 Cured Light Hide); Journeyman Herbs 1s 70c; Journeyman Fabrics 2s 12c (2 Cured Medium Hide, que o dono faz); Expert Textiles cerca de 2s 40c usando a Heavy Leather que ele já tem.

## O que já foi feito (não refazer)

1. Pesquisa do sistema, com os tooltips das 30 caixas tipadas, gravada em `comum\referencia\profissoes-forever.md`, seção "Waylaid Crates", com fonte e data (observado em 18/11/2026). Sem commit ainda.
2. Ranking de custo por Favor feito fora do jogo a partir de `dados\pregao\precos.json` (observado em 18/11/2026).

## Decisões abertas

1. **Favor real por caixa:** os números são de relatos de jogadores. Opções: (a) tabela fixa com esses números e uma marca de "relato", corrigida quando o dono entregar uma caixa; (b) o addon aprender sozinho, lendo a moeda Merchant's Favor antes e depois da entrega (`C_CurrencyInfo`). Falta descobrir o id da moeda. Recomendação: (a) agora e (b) depois.
2. **Caixas de fabricado e profissão:** a allthings.how (beta) diz que as caixas de fabricado pedem a profissão correspondente. O tooltip não mostra isso. Conferir no jogo com a Journeyman Fabrics (o Leatherworking faz o Cured Medium Hide). Até lá, mostrar todas.

## Próximos passos concretos

| # | Tarefa | Modelo/esforço | Depende de | Pronto quando |
|---|---|---|---|---|
| T1 | `ferramentas\compra\gerar-caixas.mjs`: lê os tooltips (`https://nether.wowhead.com/forever/tooltip/item/<id>`, ids 248682 a 248713, só os que têm "following list") e o `ItemSparse` do cache (`dados\pregao\cache\ItemSparse-1.60.1.70938.csv`) para nome → id dos materiais, e grava `addons-proprios\CompraForever\Caixas.lua` (global do addon por `ns`: `id, nome, tier, tipo (coleta/fabricado), nivel, favor, favorFonte = "relato", pacotes = { { {id,qtd}, ... }, ... }`), só ASCII, e entra no TOC depois de `Dados.lua` | sonnet/low | nada | 30 caixas; todo material com id; `checar-lua` ok |
| T2 | Planejador de caixas, Lua puro, em `Caixas.lua` ou num módulo novo `Favor.lua`: `ns.planejarCaixas(entrada)`. Por caixa tipada que o nível permite: a caixa sai da bolsa (custo 0) ou da escada da AH; o pacote mais barato usa primeiro a bolsa (`ns.estoque`), depois a escada, depois o vendedor, e por fim fabrica um nível (Cured X Hide pela receita do `Dados.lua`). Saída: ranking por custo por Favor e lista de compra até o orçamento `config.favor` (padrão 0, que só mostra). Casos de teste no molde de `ferramentas\compra\testar-planejador.mjs` | sessão principal | T1 | casos passando |
| T3 | Scanner: escolher até 6 caixas candidatas pelo preço do Auctionator (`Auctionator.API.v1.GetAuctionPriceByItemID`, com `pcall`, só idade 0) ou pelo último scan, e acrescentar à busca dirigida só essas caixas e os materiais do pacote mais barato de cada uma, mais os pacotes das caixas que já estão na bolsa. Sem isso seriam 30 caixas e mais de 80 materiais, e a busca dirigida leva até 6s por id (`TEMPO_ID`) | sonnet/medium | T1 | bancada com 0 erros |
| T4 | Painel e botão: seção CRATES com cor própria, etiquetas [CRATE] e [BAGS], custo por Favor e "Turn in: Marcy Baker, Three Corners"; comando `/compra favor 1g` em `Nucleo.lua` (`PADROES.favor = 0`); em `Compra.lua`, as compras das caixas e dos pacotes entram na fila depois do plano de ouro, com as mesmas regras (commodity em 2 cliques, item por lote com o buyout exato, preço que sobe refaz). A caixa tipada empilha até 5, então provavelmente é commodity: conferir com `/compra sonda` | sessão principal | T2, T3 | a bancada desenha a seção e compra sem erro |
| T5 | Cenários de bancada `compra-12` em diante: caixa da bolsa, caixa da AH, pacote com estoque, orçamento que acaba, fabricar Cured Hide | sonnet/medium | T4 | `RESUMO cenarios=N erros=0` |
| T6 | `LEIA-ME.md` (seção Crates e comando), `CONTRATO.md` (seção nova), `estado\estado.md` (versão 0.2.0 e diário) | haiku/low | T4 | conferido pela sessão principal |
| T7 | Teste no jogo com o dono: Scan, comprar uma caixa e o pacote, encher, entregar à Marcy Baker e anotar o Favor recebido | dono e sessão principal | T5, T6 | Favor real gravado na referência |

O dono costuma pedir execução por subagentes econômicos (skill `executar-plano`). Pergunte o modo de execução antes de começar. Toda chamada `Agent` leva `model` e `effort` explícitos. Com o VS Code em modo de plano, os subagentes herdam esse modo e não conseguem gravar: peça ao dono para desligá-lo antes.

## Como retomar (comandos exatos)

A partir de `C:\GMS\Claude Code Projects\wow\modder`:

```
node ferramentas\guia\checar-lua.mjs addons-proprios\CompraForever
node ferramentas\guia\pregao\bancada-pregao.mjs --addon addons-proprios\CompraForever --cenarios compra
node ferramentas\compra\testar-planejador.mjs
node ferramentas\pregao\baixar-precos.mjs        (preços: foto pública e exportação do Auctionator)
```

Exportação do Auctionator (o dono cola no chat do jogo depois do full scan e dá `/reload`): o comando está em `ferramentas\pregao\CONTRATO.md`, seção 4.

Tooltip de uma caixa: `curl -s https://nether.wowhead.com/forever/tooltip/item/248705`.

## Gotchas

- O full scan do Auctionator sozinho não chega às ferramentas: é preciso o comando de exportação e um `/reload`, que grava o bloco `ah` em `GuiaForever.lua` (observado em 17/11/2026).
- `checar-lua.mjs` só checa sintaxe; o comportamento se prova na bancada (fengari) e no jogo.
- Nunca copie o nome real da pasta da conta para um arquivo do projeto: use `pastaSavedVariables()` de `ferramentas\pregao\comum.mjs`.
- Sem pasta de backup nem commit sem o ok do dono. O jogo pode estar aberto: código de addon próprio se edita em `addons-proprios` e recarrega com `/reload`; arquivo novo no TOC pede reiniciar o jogo.
- A lentidão do Scan (cerca de 2 min para uns 20 ids) segue aberta: falta o dono rodar `/compra sonda` com a AH aberta. Isso pesa mais com as caixas (inferido: diário de 17/11/2026).

## Estado do repo

- Repositório `C:\GMS` (pasta `Claude Code Projects\wow`). Último commit: `5f1c42f` feat(wow): macro raptor_Mongoose do cacador no Q (GuiaForever 1.5.1, UIForever 0.7.2).
- Sem commit: a seção Waylaid Crates em `comum\referencia\profissoes-forever.md`, este handoff e o `HANDOFFS.md`.
- CompraForever 0.1.0 no jogo, com as categorias BIG, small e skip (commit `a0fd844`).

## Referências rápidas

| Preciso de | Onde |
|---|---|
| Caixas, pacotes, Favor e fontes | `comum\referencia\profissoes-forever.md`, seção Waylaid Crates |
| Contrato do CompraForever | `addons-proprios\CompraForever\CONTRATO.md` |
| Planejador atual (escadas, estoque, fabricar) | `addons-proprios\CompraForever\Planejador.lua` |
| Dados das receitas (fabricar Cured Hide) | `addons-proprios\CompraForever\Dados.lua`, gerado por `ferramentas\compra\gerar-dados.mjs` |
| Bancada e cenários | `ferramentas\guia\pregao\bancada-pregao.mjs`, `ferramentas\guia\casos-pregao\cenarios\compra\` |
| API do leilão e restrições | `comum\referencia\api-forever.md` §3g |
| Diário e pendências | `estado\estado.md` |
