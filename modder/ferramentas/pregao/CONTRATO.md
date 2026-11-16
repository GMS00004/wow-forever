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

Ele só lê preço pela API pública do Auctionator e grava na chave `ah` do banco do GuiaForever. Até 2026-11-16
só rodou num simulador, com um substituto da API; os dois nomes de função não foram lidos no jogo. Se der erro,
`/run for k in pairs(Auctionator.API.v1) do print(k) end` lista os nomes reais.

A casa pública do dono é a `us-111`: em 2026-11-16, o percentil 25 e a mediana de Heavy Leather do arquivo das
14h17 (2s 11c e 2s 12c, com 7.115 unidades) batem com a tela do leilão dele (2s 11c e 2s 13c, com 7.229). A
`us-110` foi escolhida primeiro por engano, comparando a tela com um arquivo duas horas mais velho. Com a
exportação do Auctionator, a linha de divergências da lista confirma ou desmente a casa.

## 4.1 Uso

A partir de `wow/modder/ferramentas/pregao`:

```
node baixar-precos.mjs                  # baixa a foto publica da hora e le a exportacao do Auctionator
node crafts.mjs --pericia 180           # a lista, em ate 40 linhas
node crafts.mjs --pericia 180 --todas   # sem o filtro de pericia de aprender
node gerar-receitas.mjs                 # so quando o build do cliente mudar (BUILD em comum.mjs)
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
   chance em %, custo por ponto e lucro no vendedor. A coluna aprende mostra o número seguido de `i` quando a
   receita vem de item (`145 i`) e precedido de `~` quando é estimado (`~140`).
4. `PAGAM NO LEILAO (se vender)`: linhas com `lucroLeilao > 0`, da maior para a menor; colunas receita, preço,
   fonte, lucro, listados e `saiDia`. Linha `ralo` leva `*` depois do número de listados.
5. Rodapé: quantas receitas ficaram sem preço; os itens com divergência entre as duas fontes; e os avisos fixos:
   "chance de ponto: formula do Classic, nao conferida no Forever", "corte de 5% do leilao: inferido do cliente",
   "V = vendedor, pode ter estoque limitado", "saidas por dia: estimativa de terceiro",
   "~ = pericia de aprender estimada", "* = menos de 5 listados". Sem `--todas`, o rodapé também diz quantas
   receitas ficaram fora por perícia (`fora por pericia: N (use --todas)`).

Cada seção mostra até `--linhas` (padrão 8) e, se houver mais, a linha `mais N`. Ao lado do custo, as letras das
fontes na ordem dos reagentes (por exemplo `LVL`).
