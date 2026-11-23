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
| `naowh.mjs` | sessão principal, 2026-11-23 | lê a tabela de receitas e a lista de reagentes sem limite do Naowh Forever (seção 10.2) |
| `legado.mjs`, `testes/testar-legado.mjs` | sessão principal, 2026-11-23 | custo do 150 nas seis profissões de ofício e o teste de casos fixos (seção 10) |
| `estimativas.mjs` | sessão principal, 2026-11-23 | preços da hora, scan exportado e a conta do legado num comando (seção 10.8) |

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
node coletar-foto.mjs                   # guarda a foto publica da hora, sem sobrescrever as anteriores (secao 7)
node tendencia.mjs --item 4234          # curva de um item: fotos de hoje e ontem, diario, faixa e percentil (secao 9)
node tendencia.mjs --elasticidade       # ranking de materiais com gap de preco (secao 9)
node tendencia.mjs --vigia              # itens da lista de vigia do CompraForever (secao 9)
node testes/testar-coletor.mjs          # coletor, com --fonte e sem rede (secao 7)
node testes/testar-tendencia.mjs        # tendencia, com fotos falsas (secao 9)
node gerar-receitas.mjs --profissao todas   # as seis profissoes de oficio, com o Naowh (secao 10)
node rota.mjs --profissao enchanting --de 1 --ate 150 --desconto-vendedor 0   # rota de outra profissao
node legado.mjs                         # custo do 150 nas seis, comprando tudo, e o relatorio (secao 10)
node estimativas.mjs                    # precos da hora + scan exportado + conta ate o 225 com o marco 150 (secao 10.8)
node testes/testar-legado.mjs           # casos fixos do legado e do esquema 2 (secao 10.6)
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

`testes/checar-precos.mjs` também aceita até 25 horas cobertas num dia de `publico.horas` (o `<horas cobertas>` do
`us-111-sales.txt`, seção 4), porque a fonte pública declarou 24,12 horas para 2026-11-17.

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

## 6.4 Desconto de reputação no vendedor (2026-11-17)

Dito pelo dono em 2026-11-17: o Hexumlite tem 10% de desconto em todo item de vendedor de Darnassus, linhas
incluídas. `crafts.mjs` exporta `DESCONTO_VENDEDOR = 10` (o padrão das duas linhas de comando), `comDesconto(receitas,
pct)` e `lerDesconto(v)`. `comDesconto` é pura e devolve uma cópia das receitas com `itens[*].compra` e
`receitas[*].itemReceita.compra` vezes `(1 - pct / 100)`, arredondados; `vende` não muda (reputação só barateia a
compra); com `pct` 0 devolve as próprias receitas. `crafts.mjs` e `rota.mjs` aplicam o desconto às receitas lidas
antes de qualquer conta, então ele chega ao custo (candidato V), aos padrões de vendedor, ao `vendedor` de cada
`precosMat` do `RotaCrafts.lua` e, por ele, aos números vivos do J. Opção `--desconto-vendedor N` (inteiro de 0 a 99;
0 desliga) nas duas; o relatório termina com `desconto de vendedor: N% na compra`, e o cabeçalho do `RotaCrafts.lua`
diz `Vendor discount: N%.`. Suposição declarada: o desconto vale para todo item de vendedor, como se tudo fosse
comprado em Darnassus; na rota de 186 a 225 os itens de vendedor são o Fine Thread, o Silken Thread e o Salt da Cured
Medium Hide. O cache de vendedor do Auctionator (seção 3) guarda o último preço visto em qualquer vendedor: em
2026-11-17 ele tinha o Fine Thread e o Silken Thread a preço cheio e a Rune Thread com 10%. Teste: casos R1 a R3 do
`testes\testar-padroes.mjs`.

## 6.5 Receitas que pagam no vendedor e o fabricar ao vivo (2026-11-17)

Pedido do dono em 2026-11-17: "as receitas que são vendor net positive tem que ter um destaque diferenciado!! Pq meu
incentivo é fazer centenas delas!!", e, sobre a Mender's Mail Boots, que ele cura a Medium Hide em vez de comprar a
Cured Medium Hide.

`escolherRota` grava `rota.lucroNpc`: as receitas que não estão `fora`, fora de `--sem` e dentro de `--so`, com
`aprende < ate` e `lucroNpc > -0,15 * custo` aos preços da rota (o J mostra só as que pagam ao preço de agora), da
de maior `lucroNpc` para a menor, no máximo 15. Campos: `{ magia, nome, custo, vendaNpc, lucroNpc, limite (o ate do
calcular, 25% do listado do reagente mais escasso), aprende, aprendeEstimado, amarela, cinza, pontos, padrao =
{ situacao, preco, id, nome }, materiais = [{ id, nome, qtd por craft }] }` e os de `dadosVivos`. No Lua, a tabela
`lucroNpc` do `GuiaForeverRotaCrafts`.

Fabricar: o reagente que o `calcular` escolheu fabricar (letra `F`) leva `fab = { qtd, mats }`, a receita de menor
custo por unidade que o faz (um nível), com `qtd` unidades por craft e os reagentes dela no formato de `precosMat`;
todo item de `precosMat` ganha também `nome`. A conta da ferramenta já usava o fabricar (o candidato `F` do
`crafts.mjs`): em 2026-11-17, a Cured Medium Hide da Mender's Mail Boots saía a 3s 15c fabricada (Medium Hide 2s 70c
mais Salt 45c) contra 4s 35c no leilão. Teste: casos V5, N1 e N2 do `testes\testar-padroes.mjs`.

## 7. `coletar-foto.mjs` e a pasta de fotos (2026-11-18)

Por quê: a foto pública (`us-111.txt`) é sobrescrita a cada `baixar-precos`. Só ficava a última hora, e a série
intradiária se perdia. `coletar-foto.mjs` guarda cada foto pública como veio, uma por snapshot, para a `tendencia.mjs`
(seção 9) ter a curva por hora.

Uso, a partir de `wow/modder/ferramentas/pregao`:

```
node coletar-foto.mjs                    # baixa a foto publica us-111 e guarda, se for nova
node coletar-foto.mjs --pasta <dir>      # guarda em outra pasta
node coletar-foto.mjs --fonte <dir>      # le index.txt e us-111.txt desse diretorio, sem rede (teste)
node testes/testar-coletor.mjs           # casos com --fonte, em pasta temporaria
```

| Opção | Padrão | Efeito |
|---|---|---|
| `--pasta <dir>` | `dados/pregao/publico/fotos` | pasta de destino |
| `--fonte <dir>` | nenhum: baixa de `URL_PUBLICA` | lê `index.txt` e `us-111.txt` do diretório, com uma tentativa só |

Um argumento desconhecido, ou uma opção sem valor, sai com `erro ...` e código 1.

Fluxo: lê o `index.txt` (exige a linha `#qmi 1`, `built=` numérico e a linha `file=us-111.txt` com `snapshot=` numérico
e `sha256=` de 64 caracteres hexadecimais). Confere o SHA-256 do `us-111.txt` contra essa linha. Sem `--fonte`, se não
bater, espera 20 s e baixa os dois de novo uma vez.

Formato da pasta (congelado):

| Arquivo | Conteúdo |
|---|---|
| `us-111-<snapshot>.txt.gz` | o texto cru de `us-111.txt`, em gzip (gunzip dá o arquivo idêntico) |
| `indice.txt` | uma linha por foto: `<snapshot> <built> <arquivo> <itens> <sha256>`. `itens` conta as linhas que começam com `c ` ou `i `. `sha256` é do texto cru, não do `.gz` |
| `coletor.log` | uma linha por execução: `<AAAA-MM-DD HH:MM:SS> <novo\|repetida\|erro> <detalhe>`, na hora local; guarda as últimas 2000 linhas |

Detalhes por tipo no log: `novo snapshot=<s> itens=<n>`; `repetida snapshot=<s> ja gravada`; `erro <mensagem>`. A
saída do terminal é a mesma linha, sem a data.

Idempotência: se o `snapshot` já está no `indice.txt` ou o `.gz` já existe, a execução sai `repetida` e não grava foto
nem linha de índice. Só o log cresce. O `.gz` é criado com `wx`, então nunca sobrescreve.

| Código | Quando |
|---|---|
| 0 | `novo` ou `repetida` |
| 1 | erro: argumento, HTTP, índice inválido, falha de gravação. Se o log não puder ser gravado, a saída traz `(log nao gravado: ...)` |
| 2 | SHA-256 não bate depois da tentativa (ou a única, com `--fonte`) |

Nos erros, nada é gravado na pasta de fotos.

`sha256`, `baixarTexto` e `lerKv` saíram de `baixar-precos.mjs` e agora vivem em `comum.mjs`, que `coletar-foto.mjs`
importa. `tendencia.mjs` ainda importa `lerCasa` de `baixar-precos.mjs`, então esse export precisa continuar.

`testes/testar-coletor.mjs` confere: a primeira execução grava (gunzip do `.gz` igual ao `us-111.txt`, `indice.txt`
com uma linha de 5 campos e o snapshot do índice); a segunda sai `repetida` e o log fica com 2 linhas; com um byte
alterado, sai com código 2 e nenhum `.gz` é gravado.

## 8. Tarefa agendada (`coletor-tarefa.ps1`)

Dois arquivos: `coletor-tarefa.ps1` gera e, se pedido, registra a tarefa. `coletor-oculto.vbs` é o lançador sem janela.

| Item | Valor |
|---|---|
| Nome | `GMS WoW Precos Hora` |
| Gatilho | diário, com repetição de 1 h durante 1 dia; `StartBoundary` é 00:50 do dia em que o script roda. Assim cai no minuto 50 de cada hora |
| Ação | `wscript.exe //B //Nologo "<pasta>\coletor-oculto.vbs" "<node>" "<pasta>\coletar-foto.mjs"` |
| Limites | 10 min de execução; `IgnoreNew` (uma instância por vez); `StartWhenAvailable`; `RunOnlyIfNetworkAvailable`; roda na bateria |
| Conta | `DOMINIO\usuario` atual, `InteractiveToken`, `LeastPrivilege` |

Por que minuto 50: a foto pública sai perto do minuto 25 UTC e o índice uns 15 min depois. Às hh:50, a foto e o
índice já estão lá.

Por que `wscript` e não `powershell -WindowStyle Hidden`: no Windows 11 desta máquina, o `-WindowStyle Hidden` abre
janela e a execução morre. O `coletor-oculto.vbs` roda o node com janela oculta e espera o fim (`Run ..., 0, True`).
Ele sai com código 0 mesmo se o coletor falhar, e sai em silêncio se o `.mjs` não existir. O resultado de cada execução
está no `coletor.log`, não no "Último resultado" do Agendador.

Parâmetros:

| Parâmetro | Efeito |
|---|---|
| `-Simular` (padrão) | grava o XML em `-Saida` e imprime `TAREFA`, `ACAO`, `XML`, `EXISTE` e, se a tarefa existe, `DIFERE`. Não toca no Agendador |
| `-Registrar` | cria a tarefa, ou substitui se a definição difere. Se for igual, imprime `IGUAL (nada feito)` |
| `-Remover` | remove a tarefa. Imprime `REMOVIDA` ou `NAO EXISTIA` |
| `-Node <caminho>` | `node.exe`; padrão `C:\Program Files\nodejs\node.exe` |
| `-Saida <pasta>` | pasta do XML gerado; padrão `%TEMP%\gms-wow-precos` |

`-Registrar` com `-Remover` dá erro. Qualquer erro imprime `ERRO <mensagem>` e sai com código 1.

Comparação por assinatura: a definição atual e a nova são comparadas só nos campos que importam. São a ação (comando e
argumentos), cada gatilho (tipo, `Interval`, `Duration`, `DaysInterval`, `Enabled`), os itens escolhidos de `Settings`
e o usuário, o `LogonType` e o `RunLevel`. Ficam fora o `StartBoundary`, que muda todo dia, e os elementos padrão que o
Agendador acrescenta ao exportar. Se a comparação falhar, a tarefa é tratada como diferente e é registrada de novo.

A tarefa vale só na máquina em que foi registrada (o Avell). A pasta `dados\pregao` fica fora do git, e o
registro não vai junto com o projeto. Em outra máquina, rode o `-Simular` e depois o `-Registrar` de lá.

## 9. `tendencia.mjs`

Três modos, um por vez:

```
node tendencia.mjs --item <id|nome>                                  # curva de um item
node tendencia.mjs --elasticidade [--min-vendas 800] [--linhas 25]   # ranking de materiais com gap de preco
node tendencia.mjs --vigia                                           # lista de vigia do CompraForever
node testes/testar-tendencia.mjs                                     # casos com fotos, precos e SavedVariables falsos
```

| Opção | Padrão | Efeito |
|---|---|---|
| `--pasta <dir>` | `dados/pregao/publico/fotos` | pasta das fotos horárias (seção 7) |
| `--precos <arq>` | `dados/pregao/precos.json` | o `precos.json` da seção 4 |
| `--sv <CompraForever.lua>` | `CompraForever.lua` na pasta SavedVariables da conta | a vigia |
| `--hoje AAAA-MM-DD` | hoje, na hora local | o dia de referência; dias depois dele são ignorados |

Erro de uso (modo ausente ou repetido, valor que falta, `--min-vendas` ou `--linhas` não inteiro) sai com código 2 e
mostra a linha de uso. Dado ausente ou item ambíguo sai com código 1. A saída é só ASCII, sem acento.

Janelas: `janela` são os últimos 4 dias do histórico até `--hoje`; `faixa` são os últimos 7. As vendas por dia são a
média das saídas da janela, com dia sem registro contando zero. Os preços vêm do `publico.historico` (diário) e do
`publico.itens` (agora).

Estatística: quantil por interpolação linear (tipo 7); a mediana é o quantil 0,5. Percentil de `x` é a porcentagem
inteira dos valores menores ou iguais a `x`, inclusive; lista vazia dá `-`.

**Modo `--item <id|nome>`.** O nome é buscado, sem acento e sem caixa, só entre os itens que têm dado no `precos.json`.
Um nome exato e único vence; um só candidato também vence; senão lista até 10 candidatos e sai com código 1. Linhas:

- `agora`: min, p25, med e unid do `publico.itens`, com a hora da foto.
- A tabela das fotos de hoje e de ontem: dia, hora, min, p25, med, unid e lotes do item em cada foto.
- `diario (historico)`: dia, min, mediana, unidades listadas e saídas do dia.
- `faixa 7 dias`: o menor min e a mediana das medianas dos últimos 7 dias.
- O percentil de `agora.min` entre os `min` de todas as fotos do item. Sem fotos, entre os `min` do histórico, com o
  sufixo `(base: diario)`.
- `vendas/dia`: a média das saídas dos 4 dias da janela.

Sem fotos, a linha é `sem fotos horarias ainda (coletor)`.

**Modo `--elasticidade`.** Candidatos: item com vendas por dia na janela de pelo menos `--min-vendas` (800) e mediana
das medianas diárias da janela de pelo menos 150 cobre. Para cada um:

- `gap%`: mediana, nos dias da janela com med maior que 0, de `(med - min) / med`, em %.
- `ganho/un`: mediana, nos dias da janela, de `med * 0,95 - min`. O 0,95 é o corte de 5% do leilão.
- `score = ganho * ln(vendas/dia)`. O ranking sai do maior para o menor score, até `--linhas` (25).
- `gapH%`: só quando a pasta tem 12 fotos ou mais (conta todas as fotos da pasta) e o item tem p25 nelas. Então é
  (mediana dos p25 horários menos o quantil 0,1 dos p25 horários) dividido pela mediana dos p25. Senão, `-`.
- `agora min/p25`, e `dias min/med` com os dias da janela.

Linha de rodapé: `fonte: diario <primeiro>-<ultimo>, fotos=<n>`. Sem candidato:
`nenhum item passa o filtro (...)`.

Ressalva: o mínimo diário pode ser um lote de 1 unidade mal precificado. As Waylaid Crates aparecem no topo do ranking
por isso. Por isso o `gapH` usa o p25, e não o min.

**Modo `--vigia`.** Lê `["vigia"]["itens"]` do `CompraForever.lua` (SavedVariables): cada `[<id>] = { ["nome"], ["teto"] }`.
O nome é opcional (sem ele, usa o nome das receitas ou do ItemSparse), e entrada sem `teto` é ignorada. Sem o bloco,
a saída é `vigia vazia`. Para cada item: `teto`, o preço agora (ou `sem preco`), quantas fotos de hoje têm min igual ou
abaixo do teto (`abaixo do teto em X de Y fotos de hoje`) e o percentil do min atual entre todas as fotos (ou o
diário, com `(base: diario)`).

Teste: `node testes/testar-tendencia.mjs` monta quatro fotos sintéticas (ontem às 20:00, hoje às 08:00, 12:00 e 16:00),
um `precos.json` e um `CompraForever.lua` em pasta temporária, e confere os três modos com os números que o código
calcula (percentil 50%, gap 22,8, ganho 1s 09c, `gapH` como traço com quatro fotos, vigia com 2 de 3 abaixo do teto).

## 10. As seis profissões de ofício e o custo do Legacy point (2026-11-23)

Pedido do dono em 2026-11-23: quanto custa levar cada profissão de ofício ao 150 (1 Legacy point por profissão, para
a conta inteira) comprando todo o material, e quanto volta vendendo o que foi feito no vendedor ou no leilão, com dado
público do leilão. Decisões dele: a perícia de aprender e o custo do treino vêm da tabela do Naowh Forever; execução na
sessão principal. A rota do J (Leatherworking, `receitas-lw.json`) não muda: sem `--profissao`, tudo funciona como
antes, e a rota de 189 a 225 saiu idêntica antes e depois (conferido em 2026-11-23, builds 70938 e 71037).

### 10.1 `receitas-<slug>.json` (esquema 2)

`node gerar-receitas.mjs --profissao <nome|todas> [--sem-naowh]` grava um arquivo por profissão de `PROFISSOES`
(`comum.mjs`): Alchemy 171, Blacksmithing 164, Enchanting 333, Engineering 202, Leatherworking 165 e Tailoring 197, os
IDs da tabela `SkillLine` do cliente. O formato é o da seção 3, com `esquema: 2` e:

| Campo | Regra |
|---|---|
| `receitas[].inicial` | `AcquireMethod` 1 da `SkillLineAbility`: vem com a profissão (aprende na perícia 1) |
| fora | `AcquireMethod` 3 nunca se aprende (na Alchemy, 9 receitas: as seis poções de cura que foram para o First Aid, a Potion of Poison Cleansing, a Purification Potion e a magia 6619, sem nome); conta `nunca` |
| `produto: null`, `encantamento: true` | magia sem efeito 24 e com efeito 53 ou 54 (encanta um item); conta `encantamentos` |
| `receitas[].ferramentas` | `SpellTotems`: `{ categoria, nome, itens }` por `RequiredTotemCategoryID_N` (vale todo item do `ItemSparse.TotemCategoryID` de mesmo tipo cuja máscara contém a pedida: a Runed Silver Rod serve onde se pede a Copper) e `{ categoria: null, itens: [id] }` por `Totem_N`; os itens entram em `itens` |
| `receitas[].naowh` | `{ aprende, origem, custo, lados }` do Naowh (seção 10.2); sem `itemReceita` no cliente, o `recipe` do Naowh vira o `itemReceita` (conta `padraoDoNaowh`) |
| `naowh` | `{ versao, ranks: [{ cap, pericia, custo, nivel, nome }], comDado, semDado, divergenciasCor, padraoDoNaowh }`, ou `null` |

Contagens em 2026-11-23 (build 1.60.1.71037, Naowh 1.4.7): alchemy 179 receitas (3 iniciais, 9 nunca), blacksmithing
419, enchanting 239 (179 encantamentos), engineering 242 (5 nunca), leatherworking 482, tailoring 405. O Naowh cobre
98% ou mais das receitas de cada profissão, com `divergenciasCor` 0 nas seis (amarela e cinza iguais às do cliente).
Do build 70938 para o 71037 só mudou a Orcish War Leggings (Blacksmithing ganhou item de receita).

### 10.2 `naowh.mjs`

Lê, na hora e sem copiar nada para o projeto, `<AddOns>\NaowhForever_Professions\Data\RecipeData.lua` ("by hand from
Wowhead Forever", README do autor) e `VendorReagents.lua` ("the reagents trade-goods vendors sell for gold without
limit"), com um leitor próprio do subconjunto de Lua desses arquivos (`lerTabelaLua`). `naowhDaProfissao(dados, id)`
devolve, por magia, `{ aprende (skill), origem (source: trainer, vendor, drop, quest, teacher, unknown), custo (cost, em
cobre), padrao (recipe), produto (item), amarela, cinza, lados }`, com `lados` as facções ("A", "H", "AH") dos
vendedores do padrão, e os `ranks` (Journeyman 500c, Expert 5.000c, Artisan 45.000 a 50.000c; o Apprentice não vem).

Regras que o esquema 2 liga (sem o campo, nada muda):

1. `crafts.mjs`, perícia de aprender: `inicial` dá 1; `origem` trainer dá a perícia do Naowh; senão a do item de
   receita; senão a do Naowh; senão a estimativa (amarela menos 25). Campos novos na linha: `aprendeFonte` (`inicial`,
   `naowh`, `item`, `estimada`) e `treino` (custo do Naowh quando a origem é trainer). Coluna aprende: `1 s` (vem com a
   profissão), `120 t` (treinador pelo Naowh), `145 i` (item), `~140` (estimada).
2. `rota.mjs`, `situacaoPadroes`: `inicial` é `conhecida`; origem trainer é `treinador` mesmo com item de receita;
   esquema 2 sem item e sem trainer (quest, drop, vendor, unknown ou sem dado) fica `fora`; padrão de vendedor só conta
   se algum vendedor do Naowh é da Aliança ou neutro.
3. Encantamento: venda 0, sem leilão, fora do candidato F; `dadosVivos`, `mapaFab` e o histórico aceitam produto nulo.

### 10.3 `legado.mjs`: rota, tempo e o custo do ponto

`node legado.mjs [--ate 150] [--marcos "150"] [--de "Enchanting=37,Alchemy=12"] [--feito "Leatherworking=150"]
[--treino-ate 200] [--profissoes "alchemy,tailoring"] [--desconto-vendedor 0] [--tempo-craft 10] [--relatorio <arq.md>]
[--sem-faixas]`. Com `--marcos`, cada trecho entre marcos é uma conta própria, partindo do marco anterior (do 1 ao 150
e do 150 ao 225, por exemplo), com o total por profissão; `--feito` marca como já feito o trecho que termina até a
perícia dada (padrão `Leatherworking=150`, o Hexumlite); `--treino-ate` tira as receitas de treinador que se aprendem
acima da perícia dada (seção 10.7). Por profissão, de 1 (ou do `--de`) a
150, `escolherRota` sem padrão na mão (iniciais, treinador e padrão à venda), com dois ganchos novos do `rota.mjs`:
`semMagias` (Set de magias fora) e `custoPonto(r, l, e)` (o custo do ponto; sem ele, o de sempre).

Achado de 2026-11-23: com o custo do ponto de sempre, `(custo - venda) * e`, receita que dá lucro no vendedor fica mais
"barata" quanto mais crafts pede, e a rota de 1 a 150 fazia 175 Linen Bags (Tailoring) e fabricava 1.626 Light
Leather de retalho (Leatherworking). No legado, o custo do ponto é `max(0, m - venda) * e + tempo * cpu * e`: o lucro
não vira motivo para craftar mais, e cada craft, inclusive o de reagente fabricado (`cpu`), custa `tempo` (padrão 10c,
`TEMPO_CRAFT`, algo como 1g 20s por hora a 20 crafts por minuto). O tempo só pesa na escolha; os totais são só ouro.

`custosComTempo` dá a fonte de cada item, L (leilão), V (vendedor) ou F (fabricar, até 3 níveis), pelo menor
`m + tempo * cpu`, e por receita `{ m, cpu }`. A rota escolhe pelo preço mínimo, mas a compra anda no livro de ofertas;
então a conta se refaz com cada item pelo preço médio do livro na quantidade que a rota anterior comprou (`ajuste`), até
a rota repetir (no máximo 4 vezes), e vale a de melhor nota (chega mais longe; depois, líquido no vendedor menos o tempo
dos crafts). Depois da rota, a busca de ferramentas tira as receitas de cada ferramenta paga e fica sem elas se a nota
melhora (em 2026-11-23, a Engineering até 150 dispensa a Arclight Spanner).

### 10.4 Balanço e livro de ofertas

`balanco(receitas, precos, rota, linhas, { agora, custos })`, puro, anda nos passos em ordem: a ferramenta, no primeiro
passo que pede, sai do estoque ou é obtida uma vez e fica (não se vende); cada reagente sai primeiro do estoque (o que um
passo anterior fez), depois pela fonte (F abre nos reagentes da receita e a sobra volta ao estoque); o produto vai para
o estoque. O que sobra no fim é a venda.

`custoLivro(pub, q)`: os 5 lotes mais baratos da foto e, depois deles, o preço sobe em linha reta até o p25 (25% das
unidades) e até a mediana (50%); acima disso fica na mediana. Aviso `metade` quando q passa da metade do que está à
venda, `falta` quando passa do total. Compra de leilão custa o maior entre o livro e o mínimo vezes q; de vendedor, o
preço dele.

Totais: `materiais` (livro), `materiaisMin` (tudo ao mínimo), `padroes` (cada um uma vez), `treino` (rank cujo teto
anterior a rota cruza, a partir do Apprentice 75, mais cada receita de treinador usada, pelo Naowh), `custoTotal`;
`vendaVendedor` (sobras pelo `SellPrice`) e `vendaLeilao` (cada sobra onde paga mais: mínimo de hoje vezes 0,95, só sem
vínculo, ou o vendedor), e os dois líquidos.

### 10.5 Vendedor no legado

`precosParaLegado`: reagente de vendedor só da lista sem limite do Naowh (32 itens em 2026-11-23: linhas, frascos,
tintas, sal, fluxos, varetas, madeira, carvão, temperos); ferramenta e padrão, de que basta uma unidade, pela lista
pública inteira. Motivo: a lista pública (QuestieDB) traz vendedor de estoque limitado, e a primeira conta comprou 79
Peacebloom de um deles.

### 10.6 Saída e teste

Terminal: uma linha por profissão, da de melhor líquido no vendedor para a pior, com faixa, crafts (rota e reagentes),
compra, volta no vendedor, líquido, teto no leilão e líquido. Relatório em
`dados\pregao\relatorios\legado-<ate>-<AAAA-MM-DD-HHMM>.md` (fora do git): a tabela e, por profissão, passos, lista de
compras (onde, total, à venda, saídas por dia, aviso), ferramentas, objetos de acampamento, fabricados, padrões, treino,
sobras e onde vender, e o custo a partir de 50, 75, 100, 125, 150, 175, 200, 250 e 275, os que caem dentro de cada
trecho; avisos no fim. Com `--marcos`, a tabela do topo tem uma linha por trecho, o total de cada profissão e as linhas
"Todas" e "Todas, sem o já feito".

`node testes/testar-legado.mjs`: 8 casos, 32 campos (livro de ofertas, crafts com esquema 2, situação dos padrões,
fabricar com e sem tempo, balanço de uma rota fixa com estoque, ferramenta, encantamento e treino, avaliação de ponta a
ponta, leitor do Naowh e lista de vendedor).

### 10.7 Até o 225: objetos de acampamento, fabricar sem padrão e o teto do treinador (2026-11-23, noite)

Pedido do dono: estender a conta até o 225. Três regras novas, que só mexem no legado (a rota do J não muda):

1. Objeto por perto. `gerar-receitas.mjs` grava `receitas[].foco = { id, nome, acampamento, itens }` a partir de
   `SpellCastingRequirements.RequiresSpellFocus` e `SpellFocusObject`. É objeto de acampamento quando há item com o mesmo
   nome no `ItemSparse` (Tanning Rack 279941, Spinning Wheel 279943, Fermenter 279970, Anarchist's Workbench 279989);
   Anvil e Forge as cidades têm e não contam. Até o 225: Anvil em 239 receitas de Blacksmithing e 71 de Engineering,
   Tanning Rack em 39 de Leatherworking, Spinning Wheel em 47 de Tailoring, Fermenter em 3 de Alchemy e Anarchist's
   Workbench em 7 de Engineering. No balanço, o item se compra e se gasta ao montar: passos seguidos que pedem o mesmo
   objeto usam o mesmo, e cada volta a ele monta um novo. Receita cujo objeto não tem preço fica fora desde o começo,
   e a busca de ferramentas também testa a rota sem as receitas de cada objeto. Quanto tempo um objeto montado dura não
   está no cliente.
2. Fabricar sem padrão. `fabricavel(receitas, r)`: no esquema 2, o candidato F só usa receita que vem com a profissão
   ou de treinador pelo Naowh (fabricar um Tanning Rack pediria o Blueprint, que a conta não paga).
3. Teto do treinador. O Telonis, Expert de Leatherworking, só ensina até a perícia 200 (visto pelo dono em 2026-11-17), e
   não há fonte de que o treinador Artisan ensine a quem não tem o Artisan. `--treino-ate 200` tira as receitas de
   treinador que se aprendem acima do 200: é a variante segura até o 225.

Resultado de 2026-11-23 (foto pública das 15h25, `--ate 225 --marcos 150`): Engineering 24g 26s de compra e +48s no
vendedor; Alchemy 6g 67s e -4g 78s; Enchanting 14g 97s e -10g 04s; Tailoring 65g 88s e -25g 62s; Leatherworking 62g 13s
e -26g 10s; Blacksmithing 91g 78s e -30g 79s. Com `--treino-ate 200`, só mudam o Tailoring (87g 24s e -35g 70s) e o
Blacksmithing (86g 42s e -33g 20s).

### 10.8 `estimativas.mjs`: atualizar num comando

Pedido do dono em 2026-11-23: "Gostaria que fosse fácil atualizar as estimativas de custos". `node estimativas.mjs`
roda o `baixar-precos.mjs` (foto pública da hora e a exportação do scan do Auctionator, seção 4), diz se o scan entra
(exportado há até 6 horas) ou não, e roda o `legado.mjs --ate 225 --marcos 150`. Qualquer opção do `legado.mjs` passa
adiante e substitui a do padrão (`node estimativas.mjs --treino-ate 200`); `--sem-baixar` refaz a conta sem rede, com o
`precos.json` que está no disco. O scan só chega à ferramenta pela exportação: o comando `/run` da seção 4 colado no
jogo e um `/reload` (o arquivo de SavedVariables só muda no disco no `/reload` ou ao sair).

Achado da mesma noite: o botão Full do CompraForever não alimenta o banco do Auctionator (o scan das 16h32 exportou só
preços de 1 a 3 dias atrás, com idade 0 em nenhum); só o scan do próprio Auctionator alimenta. Daí a seção 10.9.

Foto pública que não confere (`baixar-precos.mjs`, 2026-11-23): quando o SHA-256 não bate nem na segunda tentativa (o
autor troca o índice e o arquivo em horas diferentes, perto do minuto 25 a 45), o script fica com a foto pública do
`precos.json` anterior, relê só as exportações do jogo (Auctionator e full do CompraForever) e grava, com a linha
`AVISO ... mantida a foto publica de <hora>`. Sem `precos.json` anterior, nada é gravado, como antes (código 2).

### 10.9 O livro do full scan do CompraForever

Escolha do dono em 2026-11-23: "CompraForever guarda o Full". Desde a 0.2.1, o Full grava `CompraForeverDB.full`
(seção 11 do `CONTRATO.md` do CompraForever). `baixar-precos.mjs` lê o bloco (`lerFullCompra`) e grava
`precos.fullCompra = { em, n, itens: { "<id>": { unid, lotes, niveis: [[preco, qtd], ...] } } }`, ou `null`. No
`legado.mjs`, `comFullCompra(precos, agora)`: com o full de até 6 horas, cada item dele substitui o da foto pública
(`min` = o primeiro nível; `p25` e `med` pelas unidades acumuladas nos níveis; `unid` e `lotes` do livro inteiro;
`baratos` = os níveis, que o `custoLivro` percorre um a um); a exportação do Auctionator sai, e o relatório diz "full
scan do CompraForever". Item fora do full fica com a foto pública. A rota do J (`rota.mjs` direto) não usa o full.
Fluxo do dono: Full no painel, esperar terminar, `/reload`, "atualiza" (`node estimativas.mjs`). Teste: caso F1 do
`testes\testar-legado.mjs` (9 casos, 39 campos; 13 casos e 78 campos desde a seção 10.10).

### 10.10 A rota para o CompraForever: `rotas.json`, teto, intermediários e crédito (2026-11-23, noite)

Pedido do dono: comprar "ultra simples" ao subir qualquer das seis profissões, escolhendo a modalidade no CompraForever
(seção 12 do `CONTRATO.md` do addon). A conta de fora continua sendo a fonte única da rota; o addon refaz as
quantidades a partir da perícia real. Mudanças no `legado.mjs`, todas com teste no `testes\testar-legado.mjs`:

1. Teto por unidade. `livro(pub, q)` (exportado) devolve `{ custo, aviso, ultimo }`: `ultimo` é o preço da última
   unidade (o do último lote usado, ou o ponto da curva em `acc + resta`). `custoLivro(pub, q)` continua devolvendo só
   `{ custo, aviso }` (o caso L1 não muda). Na lista de compras, a linha de leilão ganha `teto = max(ultimo, minimo)` e a de
   vendedor ganha `preco` (o do vendedor por unidade).
2. Fonte de cada item. `balanco` devolve `fontes`: Map id -> `{ f: 'L'|'V'|'F', magia (na F), qtd, custo, teto, preco }`,
   do que o `obter()` e a ferramenta decidiram no trecho. Item F que também tem preço de leilão ganha `teto` pelo livro
   na quantidade fabricada. `treinoReceitas` ganha `magia`.
3. Intermediário fabricado (a lacuna de 2026-11-23: o Heavy Blasting Powder, de treinador por 500c e aprendido no 125,
   era fabricado 144 vezes sem treino na conta). A receita F de treinador que não é passo da rota entra uma vez em
   `treinoReceitas` (com `fabricado: true`) e no custo; a ferramenta e o objeto de acampamento dela passam pelo mesmo
   caminho dos passos; se o `aprende` dela passa do `de` do passo que a pede, o item é comprado (o ramo "F aqui so quando
   o limite de niveis cortou" já existente).
4. Crédito dos intermediários. Fabricar intermediário também dá ponto no jogo (o Heavy Blasting Powder tem amarela 125 e
   cinza 145, como o Heavy Dynamite). Depois do `escolherRota` e antes do `balanco`, `creditarIntermediarios(receitas,
   rota, custos)` refaz `esperado` e `crafts` de cada passo com o ganho do pacote: `ganho(x) = chance(m, x) * pontos(m) +
   soma de k * chance(f, x) * pontos(f)` sobre os reagentes de fonte F (até 3 níveis, `k` = reagentes pedidos / produto
   da receita F, só os que podem ser fabricados nesse `de`); `crafts = ceil(soma de 1/ganho - 1e-9)`. A escolha da receita
   de cada faixa não muda. `--sem-credito` desliga (a conta de antes). O relatório diz, acima dos passos, "crafts com o
   credito dos intermediarios". O addon usa a mesma fórmula (`ns.rotaFaltam`), e o `ferramentas\compra\testar-rota.mjs`
   (R20) confere que os dois dão o mesmo número.
5. Nível do personagem por rank: `naowh.ranks[].nivel` vem `null`; a exportação põe 10, 20 e 35 pelos tetos 150, 225 e
   300 (`comum\referencia\profissoes-forever.md:28`).
6. Exportação. `avaliarTrechos(receitas, precos, { de, ate, marcos, agora, tempo, treinoAte, faixas, credito })`
   (o laço de trechos do `linhaDeComando`) e `exportarRota(slug, receitas, segs)` viram exportações. `--rotas <arq>` grava,
   da mesma rodada que faz o relatório:

```json
{ "esquema": 1, "build": "1.60.1.71037", "geradoEm": 1795470000,
  "fonte": { "tipo": "full", "em": 1795467617, "n": 6944 },
  "tempo": 10, "credito": true, "treinoAte": null, "ate": 225, "marcos": [150],
  "itens": { "4357": { "nome": "Rough Blasting Powder", "vende": 4, "pilha": 20, "vinculo": 0 } },
  "profs": { "engineering": {
    "nome": "Engineering", "curto": "Eng", "linha": 202,
    "ranks": [ { "nome": "Journeyman Engineering", "cap": 150, "pericia": 50, "custo": 500, "nivel": 10 } ],
    "receitas": { "3919": { "nome": "Rough Dynamite", "produto": 4358, "qtd": 2, "reagentes": [[4357, 1], [2589, 1]],
                  "amarela": 30, "cinza": 60, "pontos": 1, "aprende": 1, "origem": "inicial", "treino": null } },
    "trechos": [ { "de": 1, "ate": 150, "chegou": 150,
                   "passos": [ { "magia": 3919, "de": 1, "ate": 59, "crafts": 119 } ],
                   "fontes": { "4357": { "f": "L", "qtd": 133, "custo": 1809, "teto": 14 } },
                   "totais": { "custo": 105916, "crafts": 279, "craftsExtra": 144 } } ] } } }
```

   `fonte` vem de `precos.fonteLeilao` (full), ou `{ tipo: 'publica', em: publico.foto }`. `origem` é `inicial`,
   `treinador`, `leilao` ou `vendedor` (a do padrão, ou o Naowh); `receitas` traz os passos, as receitas F e as que
   fabricam ferramenta ou objeto; `encantar: true` no encantamento sem produto; `foco` e `acampamento` como no esquema 2.
7. `estimativas.mjs` passa `--rotas <DADOS>\rotas.json` por padrão e, com o legado em 0, roda
   `..\compra\gerar-dados.mjs` (grava o bloco `rotas` no `Dados.lua` do CompraForever, ao lado dos dados de lucro, que
   ficam iguais; o `BUILD` passa a vir do `comum.mjs`) e `..\compra\checar-dados.mjs` (confere o bloco), e diz "de um
   /reload no jogo". Sai com o primeiro código diferente de 0. O Full só chega pelo `baixar-precos.mjs`: depois de um
   Full novo, `node estimativas.mjs` sem `--sem-baixar`.

O Full vale 6 horas (`comFullCompra`); depois disso a conta cai na foto pública, e agora isso fica escrito em
`rotas.fonte`, que o painel do addon mostra.
