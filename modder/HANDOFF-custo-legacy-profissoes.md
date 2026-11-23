---
frente: custo-legacy-profissoes
status: ativa
atualizado: 2026-11-23T19:35-03:00
maquina: Avell
temas: [jogos, analise-dados]
proximo_passo: "Dono, no jogo com o Ignatius: /reload, /compra sonda prof na janela de Engineering, e subir a Engineering até 150 pela modalidade de rota do CompraForever 0.3.0 (botão de modo 'Eng 150'); agente lê a sonda nas SavedVariables e corrige o que o teste mostrar"
decisoes_abertas: 1
commit: c4b553d
sensivel: false
---
> Frente: custo-legacy-profissoes · Atualizado: 23/11/2026 19:35 · Máquina: Avell
>
> Novo desde 16:52: o Full do CompraForever gravou e foi lido (18h00, 6.944 itens), e a frente ganhou o CompraForever
> 0.3.0 com a modalidade de rota (compra, craft e venda pela rota da ferramenta, as seis profissões, 150 e 225). Leia
> junto a seção 12 do `addons-proprios\CompraForever\CONTRATO.md` e a 10.10 do `ferramentas\pregao\CONTRATO.md`; o diário
> de 23/11 (17h55) no `estado\estado.md` tem o caminho inteiro. O resto deste arquivo é a foto das 16:52.

# Custo das profissões de ofício até o 150 e o 225 (Legacy points) e as estimativas

> O que é: a conta de quanto custa levar cada profissão de ofício (Alchemy, Blacksmithing, Enchanting, Engineering,
> Leatherworking e Tailoring) ao 150 e ao 225, comprando todo o material, e quanto volta vendendo o que sobra no
> vendedor ou no leilão; e o fluxo para atualizar essas estimativas depois de um scan do leilão.
>
> Leia junto: `ferramentas\pregao\CONTRATO.md`, seção 10 (10.1 a 10.9); `addons-proprios\CompraForever\CONTRATO.md`,
> seção 11; o relatório mais recente em `dados\pregao\relatorios\` (fora do git). Com isso você retoma do zero.
>
> Não refazer: as seis profissões no `gerar-receitas.mjs`, a tabela do Naowh como fonte de perícia e treino, os
> objetos de acampamento, o custo de tempo por craft e a reprecificação pelo livro de ofertas. Tudo isso está testado
> e commitado.
>
> ⚠️ A gravação do Full do CompraForever (0.2.1) ainda não rodou no jogo: o código já carregou no `/reload` das 16h50
> de 23/11/2026, mas nenhum Full foi feito desde então (`CompraForever.lua` sem o bloco `["full"]`).
>
> ⚠️ A rota do J (Leatherworking do Hexumlite) não usa nada disto: sem `--profissao`, `rota.mjs` e `crafts.mjs`
> leem o `receitas-lw.json` e saem idênticos ao de antes (observado em 23/11/2026).

## Estado em uma tela

- Ferramenta: `C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao`. `legado.mjs` faz a conta,
  `estimativas.mjs` atualiza num comando, `naowh.mjs` lê a tabela do Naowh, e `gerar-receitas.mjs --profissao todas`
  gera os `receitas-<slug>.json` (esquema 2). Tabelas do cliente do build 1.60.1.71037.
- Último resultado (observado em 23/11/2026 16:45), com o scan do Auctionator das 16h44 e a foto pública das
  16h25, em `dados\pregao\relatorios\legado-225-2026-11-23-1645.md`:

| Profissão | Compra do 1 ao 150 | Compra do 150 ao 225 | Compra até 225 | Líquido no vendedor | Líquido no leilão (teto) |
|---|---|---|---|---|---|
| Engineering | 10g 12s | 18g 08s | 28g 21s | −84s | +1g 18s |
| Alchemy | 2g 65s | 4g 49s | 7g 14s | −5g 38s | −3g 92s |
| Enchanting | 4g 40s | 10g 51s | 14g 91s | −9g 91s | −9g 46s |
| Tailoring | 12g 29s | 51g 70s | 63g 98s | −23g 65s | −12g 56s |
| Leatherworking (150 já feito) | 9g 54s | 63g 97s | 73g 51s | −23g 14s | −17g 42s |
| Blacksmithing | 11g 62s | 77g 02s | 88g 65s | −31g 45s | −22g 16s |
| As seis | 50g 63s | 225g 77s | 276g 40s | −94g 38s | −64g 34s |

- Ignatius Stonejaw (nível 10): Engineering + Blacksmithing desde 23/11/2026, decisão do dono; a conta não tem
  minerador. Até o 225, as duas juntas dão 116g 85s de compra e −32g 30s no vendedor (observado em 23/11/2026).
- Falta só o teste da gravação do Full do CompraForever no jogo e, se o dono quiser, a rota real das duas profissões
  do Ignatius.

## O que já foi feito (não refazer)

1. Conta do 1 ao 150 nas seis (`legado.mjs`), com estoque entre os passos, compra pelo livro de ofertas,
   ferramentas (Blacksmith Hammer, Runed Rods, Arclight Spanner), padrões, treino pelo Naowh, reagente de vendedor só
   da lista sem limite do Naowh e 10c de tempo por craft. Commit `fdc8d93`.
2. Extensão até o 225 por marco (`--marcos 150`), `--feito`, `--treino-ate 200`, objetos de acampamento (Tanning
   Rack, Spinning Wheel, Fermenter, Anarchist's Workbench) e fabricar só por receita sem padrão. Commit `5f3d79f`.
3. `estimativas.mjs` (preços da hora, scans exportados e a conta até o 225 num comando); `baixar-precos.mjs` mantém
   a foto anterior quando a da hora não confere; CompraForever 0.2.1 grava o livro do Full em `CompraForeverDB.full`,
   e a ferramenta usa esse livro por 6 horas. Commit `c4b553d`.
4. Análise para o paladino, até o 300 comprando tudo: o Blacksmithing custa 492g 68s, com 388g em barra e pedra (930
   Thorium Bars do 225 ao 300); a Engineering, 77g 39s, com 58g em barra e pedra (observado em 23/11/2026).
5. Ficha do Ignatius, `comum\jogador.md`, `comum\referencia\profissoes-forever.md` (receitas, ferramentas e objetos
   por perto, com fonte e data) e `estado\estado.md` atualizados.

## Decisões abertas

1. O treinador Artisan ensina receita acima do 200 a quem ainda não tem o Artisan? O Telonis (Expert de
   Leatherworking) só ensina até o 200 (visto pelo dono em 17/11/2026). Isso pesa na faixa do 200 ao 225: com
   `--treino-ate 200`, o Tailoring vai a −35g 70s e o Blacksmithing a −33g 20s (com a foto das 15h25). O dono confere
   no jogo.
2. Fechada em 23/11/2026 (noite): o dono escolheu a rota da ferramenta ("Rota da ferramenta"), que o CompraForever 0.3.0
   segue na modalidade de rota.

## Próximos passos

0. (Novo, 19:35) Teste no jogo do CompraForever 0.3.0 com o Ignatius: `/reload`; `/compra sonda prof` na janela de
   Engineering; botão de modo até "Eng 150"; Scan, comprar, correio, martelo no vendedor, treinador, craft perto da
   bigorna, venda. Engineering 1-150 pela conta das 19h31: 5g 28s de compra (era 10g 59s antes do crédito dos
   intermediários). O Full das 18h00 vale até 00h00; depois, Full novo, `/reload` e "atualiza".
1. Feito em 23/11/2026 18:00 (o `estimativas.mjs` leu o livro do Full).
2. Agente: `node estimativas.mjs`. A saída deve ter `compraforever: full scan <hora> itens=<n>` e
   `full scan do CompraForever de HH:MM (... itens): vale no lugar da foto publica e do Auctionator`. Se não tiver,
   ler o bloco `["full"]` do `CompraForever.lua` na pasta SavedVariables e o `BugGrabber.lua`.
3. Se o dono der as perícias atuais do Rurik (Enchanting), do Fingolfin (Alchemy, Tailoring) e do Ignatius
   (Engineering, Blacksmithing): `node estimativas.mjs --de "Enchanting=N,Alchemy=N,..."`.
4. Depois da decisão aberta 2: a rota do Ignatius, se for a da ferramenta, com
   `node rota.mjs --profissao engineering --de <pericia> --ate 150 --desconto-vendedor 0` e o mesmo para
   `blacksmithing`.

## Como retomar (comandos exatos)

```
cd "C:\GMS\Claude Code Projects\wow\modder\ferramentas\pregao"
node estimativas.mjs                       # precos da hora + scans exportados + conta ate o 225 com o marco 150
node estimativas.mjs --treino-ate 200      # a variante segura (treinador so ate o 200)
node estimativas.mjs --sem-baixar          # refaz a conta sem rede, com o precos.json do disco
node legado.mjs --ate 300 --marcos 150,225 --profissoes blacksmithing,engineering
node gerar-receitas.mjs --profissao todas  # so se o build do cliente mudar (BUILD em comum.mjs)
node testes/testar-legado.mjs              # 9 casos, 39 campos
```

Da pasta `C:\GMS\Claude Code Projects\wow\modder`: a bancada do CompraForever,
`node ferramentas\guia\pregao\bancada-pregao.mjs --addon addons-proprios\CompraForever --cenarios compra` (17
cenários, 0 erros, observado em 23/11/2026).

Alternativa ao Full, pelo scan do próprio Auctionator: o dono cola no chat do jogo e dá `/reload`.

```
/run local A,t,n=Auctionator.API.v1,{},0 local f,g=A.GetAuctionPriceByItemID,A.GetAuctionAgeByItemID for i=1,3e5 do local p=f("P",i) if p then t[i..""]=p+(g and g("P",i) or 0)/1e3 n=n+1 end end GuiaForeverDB.ah={em=time(),p=t} print(n,"ok /reload")
```

## Gotchas

- O Full do CompraForever não alimenta o banco do Auctionator: exportar pelo `/run` depois dele dá só preço velho
  (`idade0=0` na linha do `baixar-precos.mjs`; observado em 23/11/2026 16h38).
- A foto pública às vezes não confere (SHA-256) entre o minuto 25 e o 45 da hora: o `baixar-precos.mjs` mantém a
  anterior e relê as exportações do jogo (observado em 23/11/2026 16h40).
- O SavedVariables só vai ao disco no `/reload` ou ao sair do jogo.
- Heredoc longo no Bash (Git Bash) quebrou duas vezes com `unexpected EOF while looking for matching` ao editar estes
  arquivos: grave o texto num arquivo com o Write e rode `node <arquivo>` ou `cat <arquivo> >> <destino>`.
- A rota escolhe por preço mínimo, mas a compra anda no livro: sem a reprecificação, o Leatherworking dava −6g 97s
  com 2.053 crafts (fabricando 1.626 Light Leather de retalho). Não tire o custo de tempo nem a reprecificação sem
  conferir a seção 10.3 do contrato.

## Estado do repo e do jogo

- Repositório `C:\GMS` (gms-raiz), branch `main`, último commit `c4b553d` ("feat(wow): CompraForever 0.2.1 grava o
  livro do Full; estimativas.mjs usa o livro e o scan"), sem push.
- Fora do git: `dados\pregao\precos.json` (foto pública das 16h25 e o scan do Auctionator das 16h44), os
  `receitas-*.json` e os relatórios em `dados\pregao\relatorios\`.
- No jogo: o CompraForever está ligado por junction a `addons-proprios\CompraForever`; o código 0.2.1 carregou no
  `/reload` das 16h50 de 23/11/2026. O Naowh Forever está na 1.4.7 (atualizado na abertura de 23/11/2026).

## Referências rápidas

| Preciso de | Onde |
|---|---|
| Regras da conta (marcos, tempo, livro, objetos) | `ferramentas\pregao\CONTRATO.md`, seção 10 |
| Formato do livro do Full | `addons-proprios\CompraForever\CONTRATO.md`, seção 11 |
| Fatos de receita, ferramenta e objeto por perto | `..\comum\referencia\profissoes-forever.md`, seção de 23/11/2026 |
| Decisão do Ignatius | `..\comum\personagens\ignatius-stonejaw.md`, seção Profissões |
| Diário da sessão | `estado\estado.md`, entradas de 23/11/2026 |
