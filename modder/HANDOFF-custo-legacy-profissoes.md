---
frente: custo-legacy-profissoes
status: ativa
atualizado: 2026-11-23T20:54-03:00
maquina: Avell
temas: [jogos, analise-dados]
proximo_passo: "Dono, no jogo com o Ignatius: /reload, /compra sonda prof na janela de Engineering e subir a Engineering até 150 pela modalidade de rota do CompraForever 0.3.0 (botão de modo 'Eng 150'); agente lê a sonda nas SavedVariables e corrige o que o teste mostrar"
decisoes_abertas: 3
commit: f2b4784
sensivel: false
---
> Frente: custo-legacy-profissoes · Atualizado: 23/11/2026 20:54 · Máquina: Avell

# Custo das profissões de ofício até o 150 e o 225 (Legacy points), as estimativas e a modalidade de rota do CompraForever

> O que é: a conta de quanto custa levar cada profissão de ofício (Alchemy, Blacksmithing, Enchanting, Engineering,
> Leatherworking e Tailoring) ao 150 e ao 225 comprando todo o material, o fluxo para atualizar a conta depois de um
> scan do leilão, e, desde 23/11/2026 (noite), a modalidade de rota do CompraForever 0.3.0, que segue essa conta no jogo
> (compra, craft e venda, um clique por ação).
>
> Leia junto: `addons-proprios\CompraForever\CONTRATO.md` seção 12 (a modalidade de rota, com as decisões da
> implementação em 12.4 e a ordem das dicas em 12.7) e `ferramentas\pregao\CONTRATO.md` seção 10 (10.10: `rotas.json`,
> teto, intermediários e crédito); o diário de 23/11/2026 (17h55) no `estado\estado.md`; o relatório mais recente em
> `dados\pregao\relatorios\` (fora do git). Com isso você retoma do zero.
>
> Não refazer: as seis profissões no `gerar-receitas.mjs`, a tabela do Naowh, os objetos de acampamento, o custo de
> tempo por craft, a reprecificação pelo livro, o crédito de perícia dos intermediários, o bloco `rotas` do `Dados.lua`
> e toda a modalidade de rota (planejador, ações, painel, bancada com 28 cenários). Tudo testado e commitado.
>
> ⚠️ Outra sessão do Claude (`modder-dd`) abriu nesta mesma pasta às 20h44 de 23/11/2026, com o jogo aberto, e às
> 20h49 a conta foi refeita com um Full novo (20h41, 6.977 itens): o `Dados.lua` e o `dados\pregao\rotas.json` foram
> regravados e o `Dados.lua` está modificado sem commit (observado em 23/11/2026 20:52). Confira em
> `~/.claude/sessions/*.json` se ela ainda está viva antes de escrever na pasta, e não commite o que é dela.
>
> ⚠️ Nada da modalidade de rota rodou no jogo até 20h54 de 23/11/2026 (inferido: nenhum relato do dono nesta sessão; o
> teste pode estar acontecendo na outra).

## Estado em uma tela

- Ferramenta: `C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao`. `estimativas.mjs` baixa os preços, lê o
  Full do CompraForever (vale 6 horas), roda o `legado.mjs --ate 225 --marcos 150 --rotas ...`, gera o `Dados.lua` do
  addon e confere (`checar-dados: ok`) (observado em 23/11/2026 19:31).
- Addon: CompraForever 0.3.0 (`addons-proprios\CompraForever`, junction no AddOns). Botão `CompraForeverModo` na
  fileira de cima: Profit (a de antes) ou `<Prof> 150/225`; `/compra mode eng 150`. Carrega com `/reload`.
- Conta mais nova, com o Full das 20h41 (`dados\pregao\relatorios\legado-225-2026-11-23-2049.md`, observado em
  23/11/2026 20:52): Engineering 1-150 5g 77s (384 crafts), 150-225 18g 56s; as seis até o 225, 262g 02s de compra e
  −84g 85s no vendedor (−64g 62s com o leilão como teto). Pela conta das 19h31 (Full das 18h00), a Engineering 1-150
  era 5g 28s; sem o crédito dos intermediários, com os mesmos preços, 10g 64s (observado em 23/11/2026 20:46).
- Ignatius Stonejaw (nível 10, Engineering + Blacksmithing): Journeyman pede nível 10 (ok); Expert pede nível 20, então
  o modo "Eng 225" para no 150 por enquanto.
- Falta: o teste no jogo da modalidade de rota e a leitura da sonda de profissão.

## O que já foi feito (não refazer)

1. Conta do 1 ao 150 nas seis (`legado.mjs`), com estoque entre os passos, livro de ofertas, ferramentas, padrões,
   treino pelo Naowh, reagente de vendedor só da lista sem limite e 10c de tempo por craft. Commit `fdc8d93`.
2. Extensão até o 225 por marco, `--feito`, `--treino-ate 200`, objetos de acampamento, fabricar só por receita sem
   padrão. Commit `5f3d79f`.
3. `estimativas.mjs`; CompraForever 0.2.1 grava o livro do Full. Commit `c4b553d`. A gravação rodou no jogo: Full de
   23/11/2026 18h00, 6.944 itens lidos, SavedVariables com 532.669 bytes (observado em 23/11/2026).
4. Análise para o paladino até o 300 (Blacksmithing 492g 68s, Engineering 77g 39s, pela conta antiga, sem crédito).
5. Fichas e referências de profissão atualizadas (antes de 23/11/2026, noite).
6. `legado.mjs` (seção 10.10): `livro()` com o preço da última unidade (teto), fonte de cada item por trecho, treino e
   ferramenta dos intermediários, crédito de perícia dos intermediários (`--sem-credito` volta à conta antiga),
   `avaliarTrechos`, `exportarRota` e `--rotas`; `testar-legado` com 13 casos e 0 erros. Commit `66d5aef`.
7. Gerador e checador do `Dados.lua` com o bloco `rotas` (6 profissões, 12 trechos, cerca de 74 passos) e o
   `estimativas.mjs` encadeado. Commit `66d5aef`.
8. CompraForever 0.3.0, a modalidade de rota (seção 12): planejador `ns.planejarRota`, núcleo (modo, perfis por
   profissão, SavedVariables v2, comandos), ações (leilão até o teto + 10%, vendedor que vende antes, craft em lotes de
   20 com os intermediários primeiro, correio gravado nos dois modos), painel (botão de modo, NEXT, dicas por
   urgência), sonda `/compra sonda prof`. Bancada: `--cenarios compra` 17 e `--cenarios rota` 28, 0 erros;
   `testar-rota.mjs` 20 casos, com a paridade Lua contra JS em todos os passos (observado em 23/11/2026). Commit `66d5aef`.
9. O R19 (tempo) do `testar-rota.mjs` passou a medir a média por replanejamento (25 ms), porque o teto fixo de 1 s
   falhava com a carga da máquina. Commit `f2b4784` (observado em 23/11/2026 20:50: média de 10 ms).
10. `ExitPlanMode` acrescentado à linha `tools:` do `.claude\agents\wow-modder.md` (a ferramenta apareceu na mesma
    sessão 26 s depois, observado em 23/11/2026 20:50) e a seção 3g.0 de `..\comum\referencia\api-forever.md` (funções
    de profissão pela documentação). Os dois sem commit.
11. `/sb` da sessão: destilado, adendo e tardio em `Obsidian\GMS-SB\raw\2026-11-23-compraforever-...`, ingest com 2
    páginas novas e 5 atualizadas, 0 erros no checador.

## Decisões abertas

1. O treinador Artisan ensina receita acima do 200 a quem ainda não tem o Artisan? O Telonis (Expert de
   Leatherworking) só ensina até o 200 (visto pelo dono em 17/11/2026). Pesa nas rotas até o 225 do CompraForever: se o
   Expert não ensinar, `node estimativas.mjs --treino-ate 200` refaz as rotas e o `Dados.lua`. O dono confere no jogo.
2. O `Dados.lua` regravado às 20h49 pela outra sessão (Full das 20h41): commitar como está, ou deixar o próximo
   "atualiza" regravar. O conteúdo é saída válida da cadeia (inferido: mesmo código, Full mais novo).
3. Encantamento sem item (Enchanting): fica à mão na 0.3.0; um botão com `CraftEnchant` no item equipado só depois de a
   sonda conferir no jogo. O dono decide depois do teste.
4. Fechada em 23/11/2026 (noite): rota da Engineering e do Blacksmithing do Ignatius pela ferramenta ("Rota da
   ferramenta"), seguida pela modalidade de rota.

## Próximos passos

1. Dono, no jogo com o Ignatius: `/reload`; abrir a janela de Engineering e rodar `/compra sonda prof`; na casa de
   leilão, botão de modo até "Eng 150", Scan e comprar seguindo o botão (commodity: Buy, depois Confirm; uns 53 espaços
   de bolsa para tudo, o addon divide em viagens); pegar o correio; "Buy at vendor" (Blacksmith Hammer, 18c); treinar à
   mão o que as linhas TRAIN pedem; craftar perto de uma bigorna ("Craft 20 Rough Dynamite"); "Sell N items" no
   vendedor. Parar e mandar na hora se houver erro de Lua, preço acima do máximo mostrado ou compra repetida.
2. Agente, depois do teste e de um `/reload`: ler `CompraForeverDB.sonda.linhas` no `CompraForever.lua` das
   SavedVariables (`C:\Program Files (x86)\World of Warcraft\_forever_\WTF\Account\<conta>\SavedVariables\`) e o
   `BugGrabber.lua`; gravar o que as APIs de profissão devolveram na seção 3g.0 do `api-forever.md` com a marca
   `[local]`; corrigir o que o teste mostrar (bancada antes de entregar).
3. Agente, com o ok do dono: commitar o `wow-modder.md`, o `api-forever.md` e este handoff; a decisão aberta 2 decide o
   `Dados.lua`.
4. O `estimativas.mjs` regrava o `Dados.lua` e o `rotas.json`: rode-o só quando o dono pedir "atualiza", e só se
   nenhuma outra sessão estiver viva nesta pasta (`~/.claude/sessions/*.json`, campo `cwd`). Em 23/11/2026, uma sessão
   aberta só com `/retomar` rodou este passo sozinha e regravou os dados enquanto outra trabalhava. O Full vale 6
   horas; depois disso a conta cai na foto pública (Full novo, `/reload`, "atualiza", `/reload`).
5. Se o dono der as perícias do Rurik (Enchanting), do Fingolfin (Alchemy, Tailoring) e do Ignatius: a modalidade de
   rota já parte da perícia real; para uma rota sob medida a partir de uma perícia, `node estimativas.mjs --de "Engineering=N"`.

## Como retomar (comandos exatos)

```
cd "C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao"
node estimativas.mjs                       # precos da hora + Full + conta ate o 225 + Dados.lua do addon conferido
node estimativas.mjs --sem-baixar          # refaz sem rede (nao le um Full novo: so o baixar-precos le)
node estimativas.mjs --treino-ate 200      # a variante segura do treinador
node legado.mjs --ate 225 --marcos 150 --profissoes engineering --sem-faixas --sem-credito --relatorio <arq.md>   # conta antiga, sem credito
node testes/testar-legado.mjs              # 13 casos, 78 campos
```

Da pasta `C:\GMS\Claude Code Projects\wow\modder`:

```
node ferramentas\compra\testar-rota.mjs     # 20 casos; R20 compara o Lua com o JS em todo passo do Dados.lua
node ferramentas\compra\testar-planejador.mjs
node ferramentas\compra\checar-dados.mjs --exigir-full
node ferramentas\guia\pregao\bancada-pregao.mjs --addon addons-proprios\CompraForever --cenarios compra   # 17
node ferramentas\guia\pregao\bancada-pregao.mjs --addon addons-proprios\CompraForever --cenarios rota     # 28
```

E de `ferramentas\guia`: `node checar-lua.mjs ..\..\addons-proprios\CompraForever`.

## Gotchas

- Duas sessões na mesma pasta: o `Dados.lua` e o `rotas.json` mudaram sem ação desta sessão (outra sessão rodou a
  conta). Antes de commitar, `git status` e `~/.claude/sessions/*.json`; commite só pelo caminho dos próprios arquivos
  (observado em 23/11/2026 20:52).
- O Full do CompraForever não alimenta o Auctionator, e o `--sem-baixar` não lê um Full novo (só o
  `baixar-precos.mjs` lê o SavedVariables).
- O SavedVariables só vai ao disco no `/reload` ou ao sair; o arquivo do CompraForever passa de 500 KB com o Full.
- O teste de tempo no fengari varia com a carga da máquina (0,7 s às 19h e 1,5 a 2,2 s às 20h45, mesmo código): use a
  média, não teto fixo.
- O `ExitPlanMode` (e a `Workflow`) dependem da linha `tools:` do agente `wow-modder`, não da extensão.
- O `rm -rf` com caminho em variável é barrado pelo Claude Code sem pessoa para aprovar; use `"${S:?}"` ou caminho
  literal (a reescrita não foi testada).
- Heredoc longo no Git Bash quebra; grave o texto com o Write e rode `node <arquivo>`.
- Sem a reprecificação pelo livro e sem o custo de tempo, a rota degenera (seção 10.3); sem o crédito, compra quase o
  dobro de Heavy Stone na Engineering (seção 10.10).

## Estado do repo e do jogo

- Repositório `C:\GMS` (gms-raiz), branch `main`, último commit `f2b4784` ("test(wow): R19 do testar-rota mede a media
  por replanejamento, nao um teto fixo"), antes `66d5aef` ("feat(wow): CompraForever 0.3.0 com a modalidade de rota;
  legado exporta a rota com teto e credito dos intermediarios"); sem push. Sem commit: `comum\referencia\api-forever.md`,
  `modder\.claude\agents\wow-modder.md` (desta sessão) e `addons-proprios\CompraForever\Dados.lua` (da outra sessão)
  (observado em 23/11/2026 20:54).
- Fora do git: `dados\pregao\precos.json` (Full das 20h41), `rotas.json`, os `receitas-*.json` e os relatórios.
- No jogo: o Wow.exe estava aberto às 20h5x de 23/11/2026; o `CompraForever.lua` da conta foi gravado às 20h48 com
  556.805 bytes (Full das 20h41) (observado em 23/11/2026). O código 0.3.0 carrega no próximo `/reload` (inferido: o
  TOC só mudou a versão).

## Referências rápidas

| Preciso de | Onde |
|---|---|
| Modalidade de rota (dados, planejador, ações, painel, bancada) | `addons-proprios\CompraForever\CONTRATO.md`, seção 12 |
| Como usar a modalidade (dono) | `addons-proprios\CompraForever\LEIA-ME.md`, seção "Modalidade de rota" |
| Regras da conta (marcos, tempo, livro, objetos, crédito, `rotas.json`) | `ferramentas\pregao\CONTRATO.md`, seção 10 |
| Formato do livro do Full | `addons-proprios\CompraForever\CONTRATO.md`, seção 11 |
| Funções de profissão do Forever (documentação) | `..\comum\referencia\api-forever.md`, seção 3g.0 |
| Fatos de receita, ferramenta e objeto por perto | `..\comum\referencia\profissoes-forever.md`, seção de 23/11/2026 |
| Decisão do Ignatius | `..\comum\personagens\ignatius-stonejaw.md`, seção Profissões |
| Plano desta noite | `C:\Users\PC-AVELL\.claude\plans\continue-coloquei-em-plan-indexed-nova-of-86a6c65b-8fed-4cb8-a2ab-26e6738f13ae.md` |
| Second brain | `Obsidian\GMS-SB\wiki`: "CompraForever Route Modality — ..." e a página do custo do Legacy point |
| Diário | `estado\estado.md`, entradas de 23/11/2026 |
