---
frente: custo-legacy-profissoes
status: ativa
atualizado: 2026-11-26T12:55-03:00
maquina: Avell
temas: [jogos, analise-dados]
proximo_passo: "Modo LW 250 feito em 26/11 (CompraForever 0.4.1, rota regerada ate o 250 com a foto publica das 11h26; Tigerseye normal). Falta o teste no jogo: /reload, /compra mode lw 250, alvos de compra no diario do estado.md de 26/11; depois ler a SV e gravar o observado"
decisoes_abertas: 3
commit: 990b5e2
sensivel: false
---
> Frente: custo-legacy-profissoes · Atualizado: 24/11/2026 00:30 · Máquina: Avell

# Custo das profissões de ofício (Legacy points), as estimativas e a modalidade de rota do CompraForever

> O que é: a conta de quanto custa levar cada profissão de ofício (Alchemy, Blacksmithing, Enchanting, Engineering,
> Leatherworking e Tailoring) ao 150, ao 225 e além, comprando todo o material; o fluxo para atualizar a conta depois de
> um scan do leilão; e a modalidade de rota do CompraForever 0.3.0, que segue essa conta no jogo (compra, craft e venda,
> um clique por ação).
>
> Leia junto: `addons-proprios\CompraForever\CONTRATO.md` seção 12 (a modalidade de rota; 12.7 tem a âncora do painel e
> o texto do Scan corrigidos em 23/11 à noite) e `ferramentas\pregao\CONTRATO.md` seção 10 (10.10: `rotas.json`, teto,
> intermediários e crédito); o diário de 23 e 24/11 no `estado\estado.md`; o relatório
> `dados\pregao\relatorios\lw250-caminho-2026-11-23.md` (fora do git). Com isso você retoma do zero.
>
> Não refazer: as seis profissões no `gerar-receitas.mjs`, a tabela do Naowh, os objetos de acampamento, o custo de
> tempo por craft, a reprecificação pelo livro, o crédito dos intermediários, o bloco `rotas` do `Dados.lua`, a
> modalidade de rota inteira (já rodou no jogo: Engineering do 1 ao 150) e o estudo do Leatherworking do 225 ao 250.
>
> ⚠️ Estado sujo, de propósito: às 22h20 de 23/11 o agente refez a conta com a Tigerseye a 12s, sem o dono pedir. O
> `dados\pregao\precos.json` está com a Tigerseye (item 818) a 1200c, e o `Dados.lua` (sem commit, `git status` com ` M`)
> e o `rotas.json` têm a rota que saiu disso (sem as Goggles). O dono pediu para não refazer a rota, e o classificador do
> modo auto barrou a volta. A volta sai junto com o modo LW 250, com o ok dele. Até lá, não rode `estimativas.mjs`,
> nem com `--sem-baixar`. Cópia do `precos.json` original no scratchpad da sessão de 23/11, que pode ter sumido.

## Estado em uma tela

- Ferramenta: `C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao`. `estimativas.mjs` baixa os preços, lê o
  Full do CompraForever (vale 6 horas), roda o `legado.mjs --ate 225 --marcos 150 --rotas ...`, gera o `Dados.lua` e
  confere. O `legado.mjs` sem `--rotas` só grava um relatório e não toca no addon.
- Addon: CompraForever 0.3.0 (`addons-proprios\CompraForever`, junction no AddOns), modos Profit, `<Prof> 150` e
  `<Prof> 225`. Em 23/11 à noite rodou no jogo e levou a Engineering do Ignatius do 1 ao 150 (observado pelo dono).
- Ignatius: Engineering 150, Mining 22, sem Blacksmithing (o dono subiu só a Engineering, pelo custo; sonda das 21h14
  `[local]`).
- Hexumlite: Leatherworking 225 (dito pelo dono). Quer o 250 no nível 35 para o Salt Shaker (cooldown do Refined Deeprock
  Salt, que estava entre 47g 32s e 50g no Full das 21h11 de 23/11).
- Caminho do 225 ao 250 (relatório lw250, Full das 21h11, desconto de 10% de Darnassus): Nightscape Pants do 225 ao 241
  (31 crafts, treinador, 40s) e Heavy Scorpid Vest do 241 ao 250 (9 crafts, padrão no leilão a 1g); 69g 85s de compra,
  −27g 92s no vendedor. A mais barata de sete rotas. Tudo menos os treinos pode ser comprado antes do 35.

## O que já foi feito (não refazer)

1. Conta do 1 ao 150 e até o 225 nas seis (`legado.mjs`), `estimativas.mjs`, livro do Full. Commits `fdc8d93`,
   `5f3d79f` e `c4b553d`.
2. `legado.mjs` 10.10 (teto, fonte por trecho, crédito dos intermediários, `--rotas`) e CompraForever 0.3.0, a
   modalidade de rota. Commit `66d5aef`; R19 do `testar-rota` pela média em `f2b4784`; `ExitPlanMode` no agente e a
   seção 3g.0 do `api-forever.md` em `2ab8ee0`.
3. Teste no jogo, 23/11 à noite: Engineering do 1 ao 150 com o Ignatius pela modalidade de rota. Sonda de profissão lida
   e gravada no `..\comum\referencia\api-forever.md` com a marca `[local]` (todas as funções existem;
   `GetProfessionInfoBySkillLineID` devolve zeros, não `nil`, para profissão que o personagem não tem).
4. Correções do painel (commit `990b5e2`): só se prende a janela na tela, reavalia no `OnHide` e 0,1 s depois de cada
   evento (o painel ficava solto depois de fechar o treinador); na rota, o Scan sem nada para buscar diz `Nothing to buy
   for the route`. Cenário `rota-27`; bancada rota 29 e compra 17, 0 erros.
5. Estudo do Leatherworking do 225 ao 250 (agente Sonnet, 24/11 00h): sete rotas, sensibilidade à fonte de preço, lista
   de compras, treinos e padrões, e o que o CompraForever precisa para aceitar o alvo 250. Relatório
   `dados\pregao\relatorios\lw250-caminho-2026-11-23.md` e os parciais `lw250-*.md` (fora do git).
6. `/sb` de 23/11 à noite: destilado e adendo em `Obsidian\GMS-SB\raw\2026-11-23-compraforever-rota-no-jogo-*`, página
   da sessão nova e as da modalidade de rota e do processo de trabalho atualizadas; checador com 0 erros.

## Decisões abertas

1. O treinador Artisan ensina a Nightscape Pants (receita de perícia 210)? A rota do 225 ao 250 depende disso. Se não
   ensinar, a rota só com treinador até o 200 (rota E do relatório lw250) fica 6g 50s pior. O dono confere no Drakk
   Stonehand (Aerie Peak, pela fonte do Reptilio) ao pegar o Artisan. É a antiga decisão 1, mais estreita.
2. Comprar já ou perto do 35 os materiais do 225 ao 250 (Thick Leather, Rugged Leather, Heavy Scorpid Scale, linhas e o
   padrão da Vest). A Heavy Scorpid Scale é a mais escassa (678 à venda) e a que mais oscila (mediana de 73s no dia 16,
   22s no dia 23); o padrão da Vest custava de 32s a 50s antes do 1g de 23/11. Decisão de economia, é do dono.
3. Encantamento sem item (Enchanting): fica à mão na 0.3.0; um botão com `CraftEnchant` só depois de um teste no jogo.

Fechadas: a do `Dados.lua` das 20h49 (virou o estado sujo acima, a resolver junto com o LW 250) e a da rota da
ferramenta para o Ignatius (23/11).

## Próximos passos

1. Dono: avisar quando o Hexumlite estiver perto do nível 35. Agente: o modo LW 250 (ver `proximo_passo`), com um Full
   novo. Pelo relatório lw250, o planejador já aceita qualquer alvo, e o Artisan já está nos `ranks` do `rotas.json`.
   Bloqueiam as duas listas fixas do `Nucleo.lua` (`modosDisponiveis` por volta da linha 335, e o `/compra mode` por
   volta da 610, "target must be 150 or 225") e a rota gerada só até o 225 (o `Planejador.lua` devolve `lacuna` quando
   os passos acabam antes do alvo).
2. Agente, com o ok do dono: o padrão `--feito` do `legado.mjs` ainda é `Leatherworking=150`, e o Hexumlite está no 225.
3. Dono, no próximo login: ver se o painel some junto com o treinador, o correio e o vendedor, e se o texto do Scan na
   rota mudou.
4. Se o dono der as perícias do Rurik (Enchanting) e do Fingolfin (Alchemy, Tailoring): a modalidade de rota já parte da
   perícia real.

## Como retomar (comandos exatos)

```
cd "C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao"
node estimativas.mjs                       # SO com o ok do dono (regrava Dados.lua e rotas.json); le o Full novo
node estimativas.mjs --ate 250 --marcos 150,225   # o LW 250 (o relatorio lw250 diz que a opcao passa ao legado; conferir)
node legado.mjs --ate 250 --de "Leatherworking=225" --profissoes leatherworking --desconto-vendedor 10 --relatorio <arq.md>   # so relatorio
node testes/testar-legado.mjs
```

Da pasta `C:\GMS\Claude Code Projects\wow\modder`:

```
node ferramentas\compra\testar-rota.mjs
node ferramentas\compra\checar-dados.mjs --exigir-full
node ferramentas\guia\pregao\bancada-pregao.mjs --addon addons-proprios\CompraForever --cenarios compra   # 17
node ferramentas\guia\pregao\bancada-pregao.mjs --addon addons-proprios\CompraForever --cenarios rota     # 29
```

## Gotchas

- Pergunta de informação do dono ("o que preciso comprar?") se responde pelo relatório que já existe. Recalcular
  regrava os arquivos que o addon em uso lê: só com o ok dele (23/11, 22h20).
- Chamada interrompida pode já ter gravado: confira o disco só lendo e diga ao dono o que já mudou.
- O `Dados.lua` entra no jogo no `/reload` e também na troca de personagem e no login. O aviso é "não dê /reload, não
  troque de personagem nem saia".
- Duas sessões na mesma pasta: antes de commitar, `git status` e `~/.claude/sessions/*.json`; commite só os próprios
  arquivos.
- O Full do CompraForever não alimenta o Auctionator; o SavedVariables só vai ao disco no `/reload` ou ao sair.
- O filtro do treinador do Forever pode mostrar só as receitas indisponíveis, e a janela de profissão lista as não
  aprendidas em "Learnable now": o dono achou que o addon treinava sozinho.
- Heredoc longo no Git Bash quebra; grave o texto com o Write e rode `node <arquivo>`.

## Estado do repo e do jogo

- Repositório `C:\GMS` (gms-raiz), branch `main`, último commit desta frente `990b5e2` ("fix(wow): CompraForever com
  painel preso so a janela na tela e texto do Scan na rota; Engineering 150 nas fichas"), mais o commit deste handoff;
  sem push. Sem commit, de propósito: `addons-proprios\CompraForever\Dados.lua` (rota com a Tigerseye a 12s).
- Fora do git: `dados\pregao\precos.json` (Full das 21h11 com a Tigerseye a 12s), `rotas.json`, os `receitas-*.json`
  e os relatórios, inclusive os `lw250-*.md`.
- No jogo: o código com as correções do painel carrega no próximo `/reload`.

## Referências rápidas

| Preciso de | Onde |
|---|---|
| Modalidade de rota (dados, planejador, ações, painel, bancada) | `addons-proprios\CompraForever\CONTRATO.md`, seção 12 |
| Como usar a modalidade (dono) | `addons-proprios\CompraForever\LEIA-ME.md`, seção "Modalidade de rota" |
| Regras da conta | `ferramentas\pregao\CONTRATO.md`, seção 10 |
| Caminho do Leatherworking do 225 ao 250 | `dados\pregao\relatorios\lw250-caminho-2026-11-23.md` |
| APIs de profissão do Forever, com a sonda | `..\comum\referencia\api-forever.md`, seção 3g.0 |
| Fichas | `..\jogadores\bruno\personagens\ignatius-stonejaw.md` e `hexumlite-bull.md`, seção Profissões |
| Second brain | `Obsidian\GMS-SB\wiki`: a página da sessão de 23/11 (noite) e "CompraForever Route Modality — ..." |
| Diário | `estado\estado.md`, entradas de 23 e 24/11 |
