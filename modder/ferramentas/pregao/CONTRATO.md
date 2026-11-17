# Contrato das ferramentas de crafts do PregaoForever (fora do jogo)

Data: 2026-11-16. Estas ferramentas respondem, fora do jogo, quais receitas de Leatherworking pagam: vendendo o
item ao vendedor, subindo a perícia sem perder ouro, ou vendendo no leilão. Só leem; nada compra, posta ou vende.
É a estratégia `conversao` do `DESIGN.md` do PregaoForever, antecipada em modo leitura.

## 1. Regras

- Node 24, módulos `.mjs`, sem dependência e sem `npm install`. Funções comuns em `comum.mjs` (não editar).
- Saída de terminal só em ASCII. Dinheiro sempre em cobre, inteiro; na tela, pelo `moeda()` do `comum.mjs`.
- Dados baixados e gerados ficam em `wow/modder/dados/pregao/`, que está fora do git.
- O nome da pasta da conta do jogo não é gravado em nenhum arquivo: use `pastaSavedVariables()`.
- Nenhum script escreve na pasta do jogo.
- Código de terceiro não é referência. Do Auctionator só se lê o que ele expõe: a tabela de preços de vendedor
  em texto no arquivo dele e a exportação feita pela API pública (seção 4).

## 2. Arquivos

| Arquivo | Quem escreve | O que é |
|---|---|---|
| `comum.mjs` | sessão principal | caminhos, `lerCsv`, `tabela`, `pastaSavedVariables`, `moeda`, `lerJson`, `gravarJson` |
| `gerar-receitas.mjs` | tarefa 1 | grava `dados/pregao/receitas-lw.json` |
| `baixar-precos.mjs` | tarefa 2 | grava `dados/pregao/precos.json` |
| `crafts.mjs` | tarefa 3 | exporta `calcular()` e imprime a lista |
| `testes/caso-base.json`, `testes/testar-crafts.mjs` | sessão principal | casos de preço fixo da tarefa 3 (não editar) |
| `rota.mjs` | tarefa R2 | exporta `calcularRota()` e imprime a rota de uma perícia a outra (seção 6) |
| `testes/caso-rota.json`, `testes/testar-rota.mjs` | sessão principal | casos de preço fixo da rota (não editar) |

## 3. `receitas-lw.json` (tarefa 1)

Tabelas do cliente, pelo `tabela(nome)` do `comum.mjs` (build 1.60.1.70938):

- `SkillLineAbility`: linhas com `SkillLine` igual a `165` (Leatherworking). `Spell` é a magia da receita;
  `TrivialSkillLineRankLow` é a perícia em que a receita fica amarela; `TrivialSkillLineRankHigh`, a em que fica
  cinza; `NumSkillUps`, os pontos por subida.
- `SpellEffect`: a linha com `SpellID` da magia e `Effect` igual a `24` (criar item). `EffectItemType` é o item
  criado; `EffectBasePointsF` é a quantidade (0 vira 1). Havendo mais de uma linha `24`, vale a de menor
  `EffectIndex`. Magia sem linha `24` fica fora e entra na contagem `semItem`.
- `SpellReagents`: a linha com `SpellID` da magia. `Reagent_0` a `Reagent_7` e `ReagentCount_0` a
  `ReagentCount_7`; par com item 0 ou quantidade 0 é ignorado. Magia sem reagente fica fora (`semReagente`).
- `SpellName`: `Name_lang` por `ID`, o nome da receita.
- `ItemSparse`: por `ID`, `Display_lang`, `SellPrice`, `BuyPrice`, `Stackable`, `Bonding`, `OverallQualityID`,
  `RequiredSkillRank`. Produto ou reagente que não existe nesta tabela derruba a receita (`semItemSparse`).
- Item de receita: `ItemEffect` com `TriggerType` igual a `6` e `SpellID` da magia; `ItemXItemEffect` liga
  `ItemEffectID` ao `ItemID`. Sem item, o campo `itemReceita` é `null` (receita de treinador ou sem dado).

Forma do arquivo:

```json
{
  "esquema": 1, "build": "1.60.1.70938", "geradoEm": "2026-11-16T17:30:00.000Z",
  "profissao": { "id": 165, "nome": "Leatherworking" },
  "contagem": { "receitas": 0, "semItem": 0, "semReagente": 0, "semItemSparse": 0, "comItemReceita": 0 },
  "receitas": [
    { "magia": 7149, "nome": "Barbaric Leggings",
      "produto": { "id": 5963, "qtd": 1 },
      "reagentes": [ { "id": 4234, "qtd": 10 }, { "id": 2321, "qtd": 2 }, { "id": 1206, "qtd": 1 } ],
      "amarela": 165, "cinza": 185, "pontos": 1,
      "itemReceita": { "id": 5973, "nome": "Pattern: Barbaric Leggings", "periciaExigida": 145, "compra": 650 } }
  ],
  "itens": {
    "5963": { "nome": "Barbaric Leggings", "vende": 3151, "compra": 15756, "pilha": 1, "vinculo": 2, "qualidade": 2 }
  }
}
```

`receitas` vem ordenada por `amarela` e depois por `nome`. `itens` traz todo produto e todo reagente citado, com a
chave em texto. `vende` é o `SellPrice`. `compra` é o preço por unidade no vendedor:
`Math.ceil(BuyPrice / VendorStackCount)`, com `VendorStackCount` 0 valendo 1 (o `BuyPrice` da tabela é o preço do
lote de `VendorStackCount` unidades). `vinculo` é `Bonding`; `qualidade` é `OverallQualityID`; `pilha` é
`Stackable`. Todos numéricos e inteiros.

Neste build, 110 receitas caem em `semItemSparse`: o produto existe na tabela `Item`, mas não no `ItemSparse`, e
nenhum deles está listado no leilão (conferido em 2026-11-16). Sobram 482 receitas.

Conferência da tabela contra o jogo (`--conferir-vendedor`): o arquivo `Auctionator.lua` da pasta SavedVariables
tem o bloco `AUCTIONATOR_VENDOR_PRICE_CACHE = {`, com uma linha `["<itemID>"] = <cobre>,` por item que o dono já
viu à venda num vendedor, até a primeira linha que é só `}` (a linha `["__dbversion"]` não é item). O valor é o
preço por unidade que o vendedor cobra, já com o desconto de reputação. Compare cada um com o preço por unidade
da tabela, `BuyPrice / VendorStackCount` do `ItemSparse` inteiro (sem arredondar; não só os itens de
Leatherworking): `igual` (diferença de até 1 cobre); `desconto` (bate, com até 1 cobre de diferença, com o preço
por unidade vezes 0,95, 0,90, 0,85 ou 0,80); senão `divergente`. Imprima uma linha
`comparados=<n> iguais=<n> desconto=<n> divergentes=<n>` e depois as divergências (id, nome, tabela, jogo), no
máximo 30 linhas. Esta conferência não cobre o `SellPrice`: esse só o tooltip do jogo confirma. Em 2026-11-16 o
resultado é 386 comparados, 227 iguais, 159 com desconto e 0 divergentes.

## 4. `precos.json` (tarefa 2)

Fontes, baixadas para `dados/pregao/publico/` a partir de `URL_PUBLICA` do `comum.mjs`:

- `index.txt`: a linha `file=us-111.txt ... snapshot=<epoch> ... sha256=<hex>` e a linha
  `art=us-111-sales.txt bytes=<n> sha256=<hex>`. Confira o SHA-256 dos dois arquivos baixados. Se não bater, baixe
  o índice e o arquivo de novo uma vez (o índice e o arquivo podem ser de horas diferentes); se ainda não bater,
  saia com código 2 sem gravar `precos.json`.
- `us-111.txt`: cabeçalho `chave=valor`; depois linhas
  `<tipo> <itemID> <min> <p25> <mediana> <unidades> <lotes> <baratos>`, com `tipo` `c` (empilhável) ou `i`
  (item), preços por unidade em cobre e `baratos` uma lista `precoxqtd` separada por vírgula.
- `us-111-sales.txt`: linhas `d <AAAAMMDD> <horas cobertas>` e `s <itemID> <AAAAMMDD>:<unidades>,...`
  (unidades que saíram do leilão no dia; estimativa do autor do arquivo, método não documentado).
- `vendors.txt`: a linha `v=` é a lista dos itens vendidos por vendedor, em números de base 36 separados por
  vírgula, cada um a diferença para o item anterior (soma acumulada a partir de 0). Validação obrigatória: o
  total bate com `vendor_items=`, todo item de `canary_vendor=` está na lista e nenhum de `canary_clean=` está.
  Se a validação falhar, `vendedor` sai `null` e o script avisa.
- Exportação do Auctionator: o arquivo `GuiaForever.lua` da pasta SavedVariables. Se houver o bloco
  `["ah"] = {`, dentro dele há `["em"] = <epoch>,` e o bloco `["p"] = {` com linhas `["<itemID>"] = <numero>,`.
  O número é `preco + idadeEmDias / 1000`: `preco = Math.floor(v)`, `idadeDias = Math.round((v - preco) * 1000)`.
  Ache o fim de cada bloco contando chaves. Sem o bloco, `auctionator` sai `null` (não é erro).

O comando que o dono cola no chat do jogo, depois da varredura completa do Auctionator (248 caracteres; o
limite do jogo é 255). Na primeira vez o jogo pergunta "Allow custom scripts?": responder Yes e colar de novo.
Deve aparecer um número seguido de `ok /reload`; o `/reload` grava o arquivo no disco.

```
/run local A,t,n=Auctionator.API.v1,{},0 local f,g=A.GetAuctionPriceByItemID,A.GetAuctionAgeByItemID for i=1,3e5 do local p=f("P",i) if p then t[i..""]=p+(g and g("P",i) or 0)/1e3 n=n+1 end end GuiaForeverDB.ah={em=time(),p=t} print(n,"ok /reload")
```

Ele só lê preço pela API pública do Auctionator e grava na chave `ah` do banco do GuiaForever. Rodou no jogo
em 2026-11-16 às 15h04 e exportou 6.876 preços, 6.654 deles com idade 0. Se um dia der erro,
`/run for k in pairs(Auctionator.API.v1) do print(k) end` lista os nomes reais.

A casa pública do dono é a `us-111`: em 2026-11-16, o percentil 25 e a mediana de Heavy Leather do arquivo das
14h17 (2s 11c e 2s 12c, com 7.115 unidades) batem com a tela do leilão dele (2s 11c e 2s 13c, com 7.229). A
`us-110` foi escolhida primeiro por engano, comparando a tela com um arquivo duas horas mais velho. A
exportação do Auctionator confirmou: dos 6.448 itens em comum, 86% diferem em até 5% do mínimo da `us-111`, com
diferença mediana zero; nas outras três casas da Aliança a diferença mediana fica entre 22% e 40%.

## 4.1 Uso

A partir de `wow/modder/ferramentas/pregao`:

```
node baixar-precos.mjs                  # baixa a foto publica da hora e le a exportacao do Auctionator
node crafts.mjs --pericia 180           # a lista, em ate 40 linhas
node crafts.mjs --pericia 180 --todas   # sem o filtro de pericia de aprender
node gerar-receitas.mjs                 # so quando o build do cliente mudar (BUILD em comum.mjs)
node rota.mjs --de 186 --ate 225        # a rota mais barata no pior caso (secao 6)
node rota.mjs --de 186 --ate 225 --sem "Dusky Boots" --lua   # sem uma receita, no formato do J
node testes/testar-rota.mjs             # casos de preco fixo da rota
node testes/testar-padroes.mjs          # padroes: situacao, escolha, RotaCrafts.lua e receitas conhecidas (secao 6.1)
```

Forma do arquivo:

```json
{
  "esquema": 1, "geradoEm": "2026-11-16T17:30:00.000Z",
  "publico": {
    "casa": "us-111", "foto": 1794849465,
    "itens": { "4234": { "tipo": "c", "min": 219, "p25": 236, "med": 250, "unid": 7069, "lotes": 271,
                         "baratos": [[219, 2], [224, 2]] } },
    "saidas": { "4234": { "20261115": 12185 } },
    "horas": { "20261115": 24 }
  },
  "auctionator": { "em": 1794850000, "itens": { "4234": { "preco": 209, "idadeDias": 0 } } },
  "vendedor": [159, 2320]
}
```

O script imprime uma linha por fonte: hora da foto pública e itens lidos; dias de saída; itens de vendedor; e,
do Auctionator, a hora da exportação, o total de preços e quantos têm idade 0, ou "sem exportacao".

## 4.2 Histórico diário (tarefa R1, 2026-11-16)

O mesmo release público tem `<CASA_PUBLICA>-history.txt` (em `URL_PUBLICA`), refeito uma vez por dia, com até
30 dias (o README diz 30; em 2026-11-16 o arquivo tinha 5, de 11/11 a 15/11, por o jogo ser novo): por item e por dia, o preço mínimo, a mediana e as unidades listadas (o README do repositório
diz que a API da Blizzard só dá anúncios, não vendas). Vale também para item não empilhável (armadura), que o
`-sales.txt` não cobre. O `index.txt` não lista esse arquivo, então não há SHA-256 para conferir.

- Baixe para `dados/pregao/publico/` a cada execução do `baixar-precos.mjs`.
- Valide: a primeira linha é `#qmh 1`; existe a linha `market=<CASA_PUBLICA>`; existe a linha
  `days=<AAAAMMDD> <AAAAMMDD>`. Depois, linhas `<tipo> <itemID> <dia>;<dia>;...`, com `tipo` `c` ou `i` e cada
  `<dia>` no formato `<AAAAMMDD>:<min>:<mediana>:<unidades>` (cobre por unidade, inteiros). Linha que não segue o
  formato é ignorada e contada.
- Grave em `publico.historico` um objeto `{ "<itemID>": [[AAAAMMDD, min, mediana, unidades], ...] }`, com os dias
  em ordem crescente e todos os valores inteiros, e em `publico.historicoDias` o par `[primeiro, ultimo]` da linha
  `days=`, como inteiros.
- Download que falha ou validação que não passa: `historico` e `historicoDias` saem `null`, o script avisa numa
  linha e segue gravando o resto (não é erro de saída).
- Linha impressa: `historico: dias=<primeiro>-<ultimo> itens=<n> ignoradas=<n>` ou
  `historico: indisponivel (<motivo>)`.

`testes/checar-precos.mjs` passa a conferir, quando `historico` não é `null`: pelo menos 5.000 itens; o item 4234
com pelo menos 3 dias; toda entrada com 4 inteiros, data de 8 dígitos dentro de `historicoDias`, `min` maior que
0, `min` menor ou igual à mediana e unidades maiores ou iguais a 0; dias em ordem crescente sem repetição. A linha
final ganha `historico=<n>` (ou `historico=null`).

## 5. `crafts.mjs` (tarefa 3)

`export function calcular(receitas, precos, opcoes)`, pura (sem ler arquivo, sem relógio). `receitas` e `precos`
têm as formas das seções 3 e 4; `opcoes` é `{ pericia, agora }`, com `agora` em epoch de segundos. Devolve
`{ pericia, linhas, semPreco }`: uma linha por receita, na ordem de `receitas.receitas`, e a contagem das linhas
sem preço. O arquivo só roda a linha de comando quando chamado direto
(`import.meta.url === pathToFileURL(process.argv[1]).href`).

**Preço de leilão de um item, `pl(id)`:**
1. Auctionator, se `precos.auctionator` existe, tem o item com `idadeDias` 0 e `agora - em` é de até 21.600 s:
   `{ preco, fonte: 'A' }`.
2. Senão, o `min` público: `{ preco, fonte: 'P' }`.
3. Senão, `null`.

**Preço conservador, `pc(id)`:** o maior entre `pl(id).preco` e o `p25` público, quando o item tem dado público;
sem dado público, o próprio `pl(id).preco`.

**Custo unitário, `cu(id, modo)`**, com `modo` `'min'` (usa `pl`) ou `'cons'` (usa `pc`). Candidatos:
- `L`, leilão: o preço do modo, se existir.
- `V`, vendedor: `itens[id].compra`, se `precos.vendedor` contém o item e `compra` é maior que 0.
- `F`, fabricar: se existe receita cujo produto é o item, a soma de `qtd * cu(reagente, modo)` dividida pela
  quantidade do produto, com todos os reagentes com preço. Entre várias receitas, a mais barata. Profundidade
  máxima 3; um item que já está no caminho da recursão não entra de novo.
Vale o menor; no empate, a ordem `L`, `V`, `F`. Sem candidato, `null`.

**Campos de cada linha:**

| Campo | Regra |
|---|---|
| `magia`, `nome`, `produtoId`, `qtd` | da receita |
| `semPreco` | `true` se algum reagente tem `cu` nulo no modo `'min'`; os campos de dinheiro e `ate` saem `null` |
| `fontes` | por reagente direto, a letra escolhida no modo `'min'`: `{ "4234": "L" }` |
| `custo`, `custoCons` | `Math.round` da soma de `qtd * cu` dos reagentes diretos, em cada modo |
| `vendaNpc` | `qtd do produto * itens[produto].vende` |
| `lucroNpc`, `lucroNpcCons` | `vendaNpc - custo`, `vendaNpc - custoCons` |
| `ate` | menor `Math.floor(0.25 * unid / qtd)` entre os reagentes diretos cuja letra no modo `'cons'` é `L` e que têm dado público; sem nenhum, `null` |
| `cor` | com `s = pericia`: `laranja` se `s < amarela`; `amarela` se `s < (amarela + cinza) / 2`; `verde` se `s < cinza`; senão `cinza` |
| `chance` | `laranja`: 1; `cinza`: 0; nas outras, `(cinza - s) / (cinza - amarela)`, limitado a 0 e 1. Com `pontos` 0, vale 0 |
| `custoPonto` | `(custo - vendaNpc) / (chance * pontos)` se `chance` é maior que 0; senão `null`. Negativo quer dizer que a subida dá ouro |
| `precoLeilao`, `fontePrecoLeilao` | `pl(produto)`; `null` se `itens[produto].vinculo` é 1 ou se não há preço |
| `lucroLeilao` | `Math.round(qtd * precoLeilao * 0.95) - custo`; `null` sem preço |
| `saiDia` | média das unidades de `publico.saidas[produto]` nos dias com `publico.horas` de 23 ou mais (dia sem valor conta 0); `null` se o produto não está em `saidas` ou não há dia completo |
| `listados` | `publico.itens[produto].unid`, ou `null` |
| `divergencias` | ids, entre reagentes diretos e produto, em que há preço `A` válido e `min` público e a diferença passa de 20% do `min` público |
| `aprende`, `aprendeEstimado` | com `itemReceita`: `itemReceita.periciaExigida` e `false`. Sem `itemReceita`: `Math.max(1, amarela - 25)` e `true` (a perícia de aprender no treinador não está nas tabelas do cliente; 25 é o percentil 90 da diferença medida nas 388 receitas com item) |
| `podeFazer` | `aprende <= pericia` |
| `ralo` | `true` se há `precoLeilao` e `listados` é `null` ou menor que 5; senão `false` |

Estes quatro campos saem preenchidos também nas linhas `semPreco`.

**Linha de comando:** `node crafts.mjs --pericia 180 [--linhas 8] [--todas]`. Lê `ARQ_RECEITAS` e `ARQ_PRECOS`, usa
a hora atual e imprime, em ASCII e em no máximo 40 linhas. Sem `--todas`, as três seções só mostram linhas com
`podeFazer`; com `--todas`, mostram todas.

1. Cabeçalho: perícia; hora e idade da foto pública (por exemplo `foto publica 14:17 (ha 35 min)`); hora e idade
   da exportação do Auctionator, ou "sem exportacao".
2. `PAGAM NO VENDEDOR`: linhas com `lucroNpc >= 0`, da maior para a menor; colunas receita, cor, custo, vendedor,
   lucro, lucro conservador e `ate`. Depois uma linha com quantas empatam (lucro menor que 0 e de até 2% do
   custo).
3. `SOBEM A PERICIA`: linhas com `chance > 0`, do menor `custoPonto` para o maior; colunas receita, cor, aprende,
   chance em %, custo por ponto, lucro no vendedor e lucro no leilão (`lucroLeilao`, ou `-` sem preço). A coluna
   aprende mostra o número seguido de `i` quando a
   receita vem de item (`145 i`) e precedido de `~` quando é estimado (`~140`).
4. `PAGAM NO LEILAO (se vender)`: linhas com `lucroLeilao > 0`, da maior para a menor; colunas receita, cor,
   chance em %, preço, fonte, lucro, listados e `saiDia`. Linha `ralo` leva `*` depois do número de listados.
5. Rodapé: quantas receitas ficaram sem preço; os itens com divergência entre as duas fontes; e os avisos fixos:
   "chance de ponto: formula do Classic, nao conferida no Forever", "corte de 5% do leilao: inferido do cliente",
   "V = vendedor, pode ter estoque limitado", "saidas por dia: estimativa de terceiro",
   "~ = pericia de aprender estimada", "* = menos de 5 listados". Sem `--todas`, o rodapé também diz quantas
   receitas ficaram fora por perícia (`fora por pericia: N (use --todas)`). A lista de divergências mostra no
   máximo 6 ids de item e, se houver mais, termina em `e mais N`.

Cada seção mostra até `--linhas` (padrão 8) e, se houver mais, a linha `mais N`. Ao lado do custo, as letras das
fontes na ordem dos reagentes (por exemplo `LVL`).

## 6. `rota.mjs` (tarefa R2, 2026-11-16)

Decisão do dono em 2026-11-16: o Leatherworking do Hexumlite não segue roteiro de terceiro; a rota sai desta
ferramenta e o dono aprova ou muda. `rota.mjs` propõe a rota mais barata de uma perícia a outra, com os preços do
dia, e a escreve também no formato do roteiro do GuiaForever.

`export function calcularRota(receitas, precos, opcoes)`, pura (sem ler arquivo, sem relógio). `opcoes` é
`{ de, ate, agora, sem, so }`: `de` e `ate` inteiros com `de < ate`; `agora` em epoch de segundos; `sem` uma lista de
nomes de receita a tirar (vazia por padrão); `so` uma lista de nomes, ou `null` (sem restrição). Nome compara
exato, sem diferenciar maiúsculas.

**Constantes por receita.** Chame uma vez `calcular(receitas, precos, { pericia: de, agora })` do `crafts.mjs` e use
de cada linha `custo`, `vendaNpc`, `lucroLeilao`, `ate`, `aprende`, `aprendeEstimado`, `listados`, `saiDia` e
`semPreco` (nenhum deles depende da perícia). Da receita, `amarela`, `cinza`, `pontos`, `reagentes` e `itemReceita`.

**Chance de ponto na perícia `s`,** a mesma regra do `crafts.mjs`: `pontos` 0 dá 0; `s < amarela` dá 1;
`s >= cinza` dá 0; senão `(cinza - s) / (cinza - amarela)`, limitado a 0 e 1.

**Um ponto por vez,** para `s` de `de` até `ate - 1`, com `n[r]` (crafts esperados já usados da receita `r`) começando
em 0:
1. Candidatas: receitas sem `semPreco`, com `vendaNpc` não nulo, `aprende <= s`, chance em `s` maior que 0, nome
   fora de `sem`, nome em `so` quando `so` não é `null`, e com `n[r] + e <= ate` da linha quando `ate` não é `null`,
   em que `e = 1 / (chance * pontos)` é o número esperado de crafts para o ponto.
2. Custo do ponto, no pior caso (tudo vendido ao vendedor): `k = (custo - vendaNpc) * e`. Vence o menor `k`; no
   empate (diferença menor que 1e-9), o maior `lucroLeilao` (nulo perde para qualquer número); depois, a menor `magia`.
3. Soma `e` em `n[r]` da vencedora e registra o ponto `s` para ela.
4. Sem candidata: a rota para. `parou` vira `{ pericia: s, motivo: 'sem receita' }` e `chegou` vira `s`.

O limite `ate` vale por receita e para a rota inteira; reagente comum a duas receitas não soma entre elas (limitação
declarada no rodapé).

**Passos.** Pontos seguidos da mesma receita formam um passo: `de` é o primeiro ponto, `ate` o último mais 1.
`esperado` é a soma dos `e` do passo e `crafts` é `Math.ceil(esperado - 1e-9)`.

**Devolve** `{ de, ate, chegou, parou, passos, totais }`. `chegou` é `ate` quando a rota termina, e `parou` é `null`.
Cada passo:

| Campo | Regra |
|---|---|
| `de`, `ate`, `magia`, `nome` | do passo e da receita |
| `crafts`, `esperado` | como acima |
| `custo`, `vendaNpc`, `lucroLeilao`, `aprende`, `aprendeEstimado`, `listados`, `saiDia` | da linha do `calcular` |
| `itemReceita` | `true` se a receita tem `itemReceita` (precisa do padrão), senão `false` |
| `piorCaso` | `crafts * (vendaNpc - custo)`; negativo é perda |
| `seVender` | `crafts * lucroLeilao`; com `lucroLeilao` nulo, igual a `piorCaso` |
| `materiais` | por reagente direto da receita, na ordem dela: `{ id, nome, qtd: qtd do reagente * crafts }`; `nome` de `receitas.itens`, ou o id em texto |
| `historico` | os últimos 4 itens de `precos.publico.historico[produto]` (como estão, `[dia, min, mediana, unidades]`), ou `null` sem histórico |

`totais`: `{ crafts, custo, piorCaso, seVender }`, com `custo` a soma de `crafts * custo` e os outros a soma dos
campos dos passos.

**Linha de comando:** `node rota.mjs --de 186 --ate 225 [--sem "A,B"] [--so "A,B"] [--lua]`. Os nomes separados por
vírgula, sem espaços nas pontas. Lê `ARQ_RECEITAS` e `ARQ_PRECOS` e usa a hora atual. Argumento errado, `de >= ate`
ou nome de `--sem`/`--so` que não existe em nenhuma receita: mensagem e código 2. Saída em ASCII.

Sem `--lua`, no máximo 40 linhas:
1. `ROTA - Leatherworking - de <de> a <ate>` e a linha de horas igual à do `crafts.mjs` (foto pública e Auctionator).
2. Tabela dos passos, com colunas faixa (`186-195`), receita, crafts, aprende (`175 i` ou `~180`, como no
   `crafts.mjs`), custo por craft, pior caso, se vender, listados e `ultimos dias` (as unidades dos dias do
   `historico` separadas por `/`, ou `-`). Até 20 passos; havendo mais, a linha `mais N passos`.
3. Se parou: `parou em <s>: nenhuma receita da ponto com os filtros e limites`.
4. `total: <crafts> crafts | materiais <custo> | pior caso <piorCaso> | se tudo vender <seVender>`.
5. `materiais:` e a soma por reagente de todos os passos (`312 Thick Leather, 52 Wildvine`), em ordem decrescente de
   quantidade, quebrada em até 4 linhas de 110 caracteres; o que não couber vira `e mais N`.
6. Rodapé: `precisa do padrao: <receitas com itemReceita, separadas por virgula>` (ou `nenhuma`); com `ate > 225`,
   `acima de 225 pede o Artisan (pericia 200 e nivel 35)`; e os avisos fixos
   `aviso: chance de ponto: formula do Classic, nao conferida no Forever | ~ = pericia de aprender estimada` e
   `aviso: limite por receita: 25% do listado de cada reagente; reagente comum a duas receitas nao soma`.

Com `--lua`, só as linhas do roteiro, prontas para a tabela `passos` do `ProfissoesB.lua`, uma por passo, com 6
espaços na frente e o texto em inglês. Elas vêm de `export function textoLua(rota, quando)`, pura, que recebe o
resultado do `calcularRota` e o texto da hora (`AAAA-MM-DD HH:MM`) e devolve a lista de linhas (strings, sem quebra
de linha no fim). Exemplo de uma linha:

```
      { de = 186, ate = 194, texto = "Dusky Boots (8x): 64 Heavy Leather, 16 Shadowcat Hide, 8 Shadow Oil, 16 Silken Thread (pattern; worst case -44s 56c; if sold +2g 86s 08c)" },
```

O texto é `<nome> (<crafts>x): <qtd> <reagente>, ...` e depois, entre parênteses, as notas separadas por `; `:
`pattern` quando `itemReceita` é `true`; `worst case <piorCaso>`; e `if sold <seVender>` quando `lucroLeilao` não é
nulo. Dinheiro pelo `moeda()` do `comum.mjs`, com `+` na frente quando é maior que 0. Aspas e barras invertidas do
texto escapadas para Lua. A última linha é o comentário
`      -- route from the crafts tool (rota.mjs), prices of <AAAA-MM-DD HH:MM>`, com a hora da exportação do
Auctionator, ou da foto pública se não houver exportação. Se a rota parou, uma linha de comentário antes dela:
`      -- stopped at <s>: no recipe gives a point`.

## 6.1 Padrões: o que o personagem consegue fazer (2026-11-16, noite)

Pedido do dono em 2026-11-16, depois de achar que o padrão da Dusky Boots nem estava no leilão: a rota não pode
supor padrão na mão. `calcularRota` continua igual (é a rota "com todos os padrões"); a linha de comando passa a usar
`escolherRota`, que só deixa entrar o que dá para fazer.

`export function situacaoPadroes(receitas, precos, { agora, conhecidas })`, pura. Para cada receita, por `magia`:
- `conhecida`, se `conhecidas` (um `Set` de magias) tem a magia;
- `treinador`, se a receita não tem `itemReceita` (o custo do treino fica fora da conta);
- `vendedor`, se o padrão está em `precos.vendedor` e tem `compra` maior que 0 (preço = `compra`);
- `leilao`, se a exportação do Auctionator tem até 6 horas e o padrão com idade 0 (preço = o dela), ou se a foto
  pública tem o padrão (preço = `min`); `listados` = `unid` da foto, quando houver;
- `fora`, nos outros casos, com `visto` = o último dia do histórico (`{ dia, min, med, unid }`) ou `null`.

`export function escolherRota(receitas, precos, { de, ate, agora, sem, so, conhecidas })`, pura:
1. Receitas `fora` saem. As de `leilao` e `vendedor` que dão ponto na faixa (`aprende < ate` e `cinza > de`) são as
   compráveis.
2. Busca local: começa sem nenhum padrão comprável e, a cada volta, põe ou tira o padrão que mais melhora a nota;
   para quando nada melhora (no máximo 50 voltas). Nota: quem chega mais longe vence; no empate, o maior
   `piorCaso - soma dos preços dos padrões comprados` (cada padrão conta uma vez, mesmo em dois passos).
3. `livre` = a mesma rota com todos os padrões; o que ela usa e está `fora` vira `esperar`
   (`{ magia, nome, padrao: { id, nome }, visto }`): padrões que vale vigiar no leilão.
4. Cada passo ganha `padrao = { situacao, preco, id, nome, listados }`; `totais` ganha `padroes` e
   `piorCasoComPadroes`; a rota ganha `esperar` e `livre = { totais, chegou }`.

`calcularRota` aceita `opcoes.linhas` (o resultado de um `calcular()` já feito), para a busca não refazer a conta.

**Receitas conhecidas.** O GuiaForever 1.4 grava, quando o dono abre a janela de Leatherworking, o bloco
`GuiaForeverDB.personagens[<personagem>].receitasLW = { quem, em, pericia, max, ids = { [magia] = true }, n }`.
`export function lerConhecidas(texto)` lê o primeiro bloco `["receitasLW"]` do `GuiaForever.lua` (SavedVariables) e
devolve `{ quem, em, pericia, ids }` ou `null`. O arquivo só muda no disco depois de um `/reload` ou ao sair do jogo.

**Linha de comando:** `--conheco "A,B"` soma receitas conhecidas à mão (nomes, como `--sem`); `--todos-padroes` volta
ao `calcularRota` puro (sem ler as conhecidas); `--addon <arquivo>` grava o `RotaCrafts.lua` (seção 6.2). O
relatório ganha a linha `conhecidas: ...`, a linha `padroes a comprar: ...` (quando há), uma linha por receita da rota
com a situação do padrão, as linhas `esperar no leilao: ...` e `com todos os padroes na mao: pior caso ...`. No
`--lua`, a nota `pattern` vira `known`, `trainer`, `buy the pattern on the AH <preço>`, `pattern from a vendor <preço>`
ou, na segunda vez da mesma receita comprada, `same pattern as above`.

Teste: `node testes/testar-padroes.mjs` (24 campos sobre `caso-base.json`: as cinco situações, a escolha com o padrão
fora, conhecido e à venda, as notas do `--lua`, o `dadosAddon` e o `lerConhecidas`).

## 6.2 `RotaCrafts.lua`: os dados da aba Crafts do GuiaForever

`export function dadosAddon(rota, receitas, { quando, agora, conhecidasEm, conhecidasTxt })`, pura, devolve o texto do
arquivo `addons-proprios\GuiaForever\RotaCrafts.lua`, que define a global `GuiaForeverRotaCrafts`:
`{ profissao, de, ate, chegou, precos (texto da hora), geradoEm, conhecidasEm, totais = { crafts, custo, piorCaso,
seVender, padroes }, passos = { { de, ate, magia, produto (id do item feito), nome, crafts, custo, vendaNpc, piorCaso,
seVender, aprende, aprendeEstimado, padrao = { id, nome, situacao, preco, listados } ou { situacao },
materiais = { { id, nome, qtd } } } }, esperar = { { magia, nome, padrao (id), padraoNome, visto } }, parou }`.
Dinheiro em cobre (inteiro). Só ASCII. O arquivo é gerado: não se edita à mão.

Uso, depois de uma consulta (seção 4.1):

```
node rota.mjs --de <pericia> --ate 225 --addon ..\..\addons-proprios\GuiaForever\RotaCrafts.lua
node rota.mjs --de <pericia> --ate 225 --lua      # o texto da aba Professions > Mine, como antes
```

O dono dá `/reload` (arquivo já listado no `.toc`; só a primeira vez pediu reiniciar o jogo).

## 6.3 Números vivos no J (2026-11-17)

Pedido do dono em 2026-11-17: "tem como os números de custos e resultados no meu J serem dinâmicos?", com a escolha
"Vivos + aviso de troca". A escolha das receitas continua aqui fora (chance, limite de 25%, busca de padrões); o
GuiaForever 1.5 refaz no jogo só o dinheiro, com o preço de leilão do Auctionator (ARQUITETURA.md do GuiaForever,
seção 13.6). Para isso o `RotaCrafts.lua` leva, a mais:

- na linha do `calcular()` (`crafts.mjs`), o campo `reagentes`: `{ id, qtd, preco, letra }` por reagente, com o preço
  unitário e a letra (`L` leilão, `V` vendedor, `F` fabricar) do modo `min`;
- em cada passo do `calcularRota`, `produto`, `produtoQtd`, `vinculado` (produto com vínculo 1), `precoLeilao` (o do
  `calcular`) e `precosMat = [{ id, un, preco, letra, vendedor }]`, com `un` a quantidade por craft e `vendedor` o
  `compra` do item quando ele está em `precos.vendedor` (senão `null`);
- em cada passo do `escolherRota`, `alternativa`: a receita de menor `(custo - vendaNpc) * e + padrão` para os mesmos
  pontos do passo, em que `e` é a soma de `1 / (chance * pontos)` de `de` a `ate - 1`. Entram as que não estão `fora`,
  fora de `--sem` e dentro de `--so`, com `aprende <= de`, chance maior que 0 em todos os pontos e
  `crafts esperados já gastos pela rota antes do passo + e <= ate` da linha; o padrão conta quando a situação é
  `leilao` ou `vendedor`. Campos: `{ magia, nome, esperado, custo, vendaNpc, piorCaso, padrao = { situacao, preco,
  id, nome } }` e os mesmos `produto`, `produtoQtd`, `vinculado`, `precoLeilao` e `precosMat` do passo; `null` sem
  candidata.

No Lua, cada passo ganha `esperado` (3 casas), `produtoQtd`, `vinculado`, `precoLeilao`, `precosMat` e, quando há,
`alternativa`. Com os preços da própria rota, a alternativa não pode acender o aviso do J (conferido em 2026-11-17
nas faixas 186-225, 150-200, 200-225 e 160-186). Teste: `testes\testar-padroes.mjs`, casos V1 a V4.
