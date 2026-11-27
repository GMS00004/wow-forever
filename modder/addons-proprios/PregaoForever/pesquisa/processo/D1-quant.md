> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# PregaoForever, projeto D1-quant: o motor é o produto

Data: 2026-11-16. Etapa: só design, nenhuma linha de código de addon. Ângulo: quantitativo, levado até o fim.

Como ler. `(base 2.7)` cita a base de fatos; `(R9 4.1)`, `(R1b 6)`, `(R8a ficha 5)` citam os relatórios. `[H-nn]` marca hipótese a medir; a medida vem junto ou na seção 8.4. Os números nos desenhos de tela são inventados. Tudo o que vem da R9 é modelo conferido só em mercado sintético, ainda sem revisor matemático (base 10).

---

## 1. Tese

### 1.1 De onde vem o lucro

O mercado é um só por conjunto de regras e região, com mais de 200 mil leilões numa varredura (base 1.2). A concorrência está equipada: TSM 4.15, ForeverFlip com sniper e postagem, aux, Auctioneer (base 5.1 a 5.3). Essas ferramentas já resolvem "ver primeiro" e "cobrir o menor preço". Nessa corrida o dono perde por construção: age uma tecla por vez (base 4.4), por acesso remoto (base 4.11), contra quem fica o dia inteiro na casa e contra os robôs relatados no beta (R8b ficha 5, R6).

O que nenhuma ferramenta vê é a venda dos outros; o preço público é preço listado, e a própria TSM avisa disso (base 5.8). Daí saem três erros de quem opera pelo menor preço, e é neles que este projeto procura o lucro:

1. Tomar o menor preço por valor. Uma unidade de isca move o mínimo à vontade (R9 1.1). Quem posta por ele vende abaixo do que a demanda paga; quem compra por ele compra o preço novo achando que é pechincha.
2. Ignorar a chance de venda. O depósito se perde quando o leilão expira ou é cancelado (base 1.7, a medir), e quando a oferta que cobre supera a demanda a chance de vender cai exponencialmente com a fila (R9 3.2 d).
3. Ignorar o custo de carregar num mercado em queda. Na semana 2 a mediana dos itens caiu 41% e as unidades listadas subiram 63% (base 6.1, preço listado, direção apenas).

A tese: o lucro é a soma das decisões com valor esperado positivo depois de corte, depósito, espera e incerteza, e a decisão certa mais frequente é não agir. A vantagem possível do dono não é velocidade nem capital; é estar calibrado onde os outros estimam: valor justo com intervalo, taxa de venda inferida entre fotos e chance de venda pela posição na fila.

### 1.2 Como se sai de 5 ouro sem prometer nada

Com 50.912 cobre (base 4.1) o recurso que aperta é o capital, antes da atenção. Três consequências de desenho:

- O primeiro produto do motor é o lado vendedor: precificar o que o dono decide vender (preço, duração, lote, ficar ou cancelar). Isso não pede capital, e cada venda própria é o dado de calibração mais limpo, porque dispensa inferência (R9 2.9). A fonte de economia aprovada já aponta para vender verdes bons no leilão (base 4.5); o addon não escolhe o que vender, calcula o preço do que o dono põe na fila.
- O lado comprador nasce em modo sombra (R9 10.4): o motor grava o que recomendaria e o que teria acontecido. Só vira ação por portões de calibração (seção 4.6) e por aprovação do dono, estratégia por estratégia.
- A fila de decisões sai pelo retorno por unidade do recurso escasso: capital-hora com banca pequena, tecla quando a banca crescer (seção 4.3, item 3).

Aritmética ilustrativa, com números inventados: banca de 5 ouro, teto de 10% por item, margem líquida de 15% e giro de um dia e meio dão cerca de 7 pratas por posição por giro; com metade da banca empregada, algo como 25 pratas por dia se tudo acertar, e a R9 já parte de metade do previsto (`η_real = 0,5`). Nessa escala o ouro novo vem do personagem, não do pregão; o que a fase 1 compra é medida. O projeto não promete riqueza: promete saber, com números do próprio dono, se existe valor esperado positivo depois dos custos, e em quais itens.

### 1.3 Por que este desenho captura a tese

- Uma moeda só: o valor de liquidação `W*` precifica postar, comprar, cancelar e marcar estoque (R9 4.1, QNT-07).
- Um teste só de compra: custo contra a saída conservadora calculada na escada que sobra depois da compra (R9 5.1, QNT-09), o que separa pechincha de queda de regime.
- Tudo que o motor afirma vira previsão gravada e depois cobrada pelo desfecho (seção 4.5). Parâmetro sem medida aparece na tela como estimativa.
- O mesmo código Lua de decisão roda no jogo e na mesa (R9, fora do escopo), então o backtest testa o motor que opera.

### 1.4 O que este ângulo sacrifica

- Tempo até o primeiro ouro: semanas de coleta e sombra antes da primeira compra recomendada.
- Cobertura: cerca de 150 itens em foco, não a casa inteira; o motor não disputa a última página nem varre tudo.
- Interface: terminal fino, sem gráfico, sem busca livre, sem digitação de preço. Quem quiser outro preço usa a tela da Blizzard.
- Simplicidade: 30 arquivos, uma mesa fora do jogo, um ciclo com `/reload` e mais de cem parâmetros, com risco real de ajuste excessivo.
- Mercados ralos (raros, receitas, azuis de mundo): sem taxa de venda mensurável o motor se cala, e é aí que os guias apontam as maiores vendas unitárias (R8b ficha 4).
- Oportunismo: o motor recusa negócio bom que não consegue provar.

---

## 2. Escopo

### Fase 1: medir (ondas 0 a 4)

- Sonda dos parâmetros do jogo (base 11) e gravador de fotos: painel da consulta resumida e escadas dos itens em foco.
- Motor de valor, liquidez e chance de venda rodando sobre as fotos.
- Lado vendedor completo: recomendar preço, duração e lote; postar e cancelar com uma tecla por ação (depende da decisão D1, seção 10).
- Carteira, razão contábil pelo correio e diário de calibração.
- Sinais de compra só em sombra. Mesa fora do jogo: arquivo das fotos, calibração, backtest, relatório de sessão.

### Fase 2: operar com valor esperado (onda 5)

- Compra por tecla, na ordem dos portões: arbitragem contra o vendedor primeiro, depois sniper e flip quando o portão G3 abrir.
- Tamanho de posição por Kelly fracionado, tetos e disjuntores (R9 7).
- Revisão de leilões próprios por `Δ_canc` (R9 4.6).

### Fase 3: escalar (onda 6)

- Sazonalidade, alarmes de regime, perfis de concorrentes, conversão por receita, calendário (raides em 2026-12-09, base 6.4).
- Dados externos como fotos adicionais para a mesa (base 5.4), se o dono decidir (D9).
- Análise de reset só como relatório da mesa.

### O que o addon nunca faz

- Agir sem tecla: nenhuma compra, lance, postagem ou cancelamento sai de timer, evento ou laço. Tecla presa não repete ação e tecla apertada durante uma ação em voo é descartada, nunca enfileirada.
- Simular entrada, mexer em estado de ausência, chamar `ReplicateItems` em laço ou como base do desenho (base 2.5).
- Contornar função protegida, evento de hardware ou secret value (base 4.4).
- Ler ou copiar código de addon de terceiros; deles só a interface pública com `pcall` (base 7).
- Ter configuração dentro do jogo (base 4.7).
- Postar preço muito fora do mercado, comprar leilão da própria conta ou montar transferência de ouro entre personagens pelo leilão (base 1.10).
- Escrever no chat, mandar correio, enviar dados a qualquer serviço.
- Opinar sobre o que comprar: estratégia sem fonte e sem aprovação fica desligada (base 4.5).

---

## 3. Arquitetura

### 3.1 Três camadas

1. **Jogo** (addon): coleta, decide, mostra, executa por tecla.
2. **Mesa** (Node com fengari, fora do jogo): arquiva, calibra, faz backtest, devolve parâmetros. Padrão antigo de aplicativo companheiro com `/reload` (base 5.6).
3. **Configuração** (agente): `Config.lua` escrito pelo agente; nada se ajusta no jogo.

O addon mora em `wow/modder/addons-proprios/PregaoForever` (base 4.8), ligado ao jogo por `dev-link.ps1`, que exige o jogo fechado uma vez (base 4.9). Como arquivo novo e mudança de `.toc` pedem reinício do jogo (R4a 6), a onda 0 já cria todos os arquivos como esqueleto. Todos os `.lua` ficam na raiz do addon, porque `checar-lua.mjs` só lê o primeiro nível (R4a 3).

### 3.2 Módulos e ordem de carga

TOC: `## Interface: 16001`, `## Author: Guilherme`, `## SavedVariables: PregaoForeverDB`, `## SavedVariablesPerCharacter: PregaoForeverCharDB`, `## OptionalDeps: Auctionator, Syndicator, ElvUI` (base 4.8). A numeração da tabela é a ordem de carga.

| # | Arquivo | Responsabilidade |
|---|---|---|
| 1 | `Config.lua` | Escrito pelo agente: tetos, estratégias (todas desligadas), teclas, calendário, foco manual |
| 2 | `Mesa.lua` | Escrito pela mesa: parâmetros calibrados, portões, confirmação de drenagem |
| 3 | `TabelaP.lua` | Tabela adimensional de P(venda), calculada uma vez na mesa (R9 3.2 f) |
| 4 | `Receitas.lua` | Grafo de receitas, cerca de 130 KB (base 9.2); fase 3 |
| 5 | `Nucleo.lua` | `ns`, relógio, eventos, `xpcall` em evento, timer e clique (base 4.8), log, fatiador de CPU |
| 6 | `Visual.lua` | Kit visual do dono, reusado do GuiaForever (base 7.5) |
| 7 | `MotorBase.lua` | Matemática pura: normal acumulada, logit, quantis, anéis |
| 8 | `MotorValor.lua` | Preço robusto da foto, níveis, intervalo, deriva (R9 1) |
| 9 | `MotorLiquidez.lua` | Diferença de escadas, fronteira, taxas de venda e de oferta (R9 2) |
| 10 | `MotorVenda.lua` | P(venda) e tempo esperado (R9 3) |
| 11 | `MotorPostagem.lua` | `W`, candidatos, duração, lote, regra de cancelar (R9 4) |
| 12 | `MotorSinais.lua` | Teste único de compra, vendedor, conversão (R9 5) |
| 13 | `MotorRisco.lua` | Banca, Kelly, tetos, disjuntores, preço-sombra do capital (R9 7) |
| 14 | `MotorRegime.lua` | Sazonalidade, CUSUM, alarme de amplitude (R9 8) |
| 15 | `MotorRivais.lua` | Parede, isca, tempo de reação (R9 9) |
| 16 | `Pedidos.lua` | Fila única de consultas sob throttle, um pedido em voo, prazos |
| 17 | `Varredura.lua` | Agendador do painel e das escadas; portão de presença |
| 18 | `Fotos.lua` | Escada compacta, anéis por item, buffer bruto a drenar |
| 19 | `Carteira.lua` | Lotes (PEPS), leilões próprios, bolsas, banca |
| 20 | `Razao.lua` | Faturas, caixa, resultado realizado, conferência ao cobre |
| 21 | `Correio.lua` | Leitura da caixa e das faturas |
| 22 | `Diario.lua` | Previsão, ação e desfecho, com hora |
| 23 | `Ponte.lua` | Interoperação em tempo de execução, com `pcall` (base 7) |
| 24 | `Acoes.lua` | O único arquivo que chama funções de ação; máquinas de estado; tudo dentro de `OnClick` |
| 25 | `Teclas.lua` | Bindings de sobreposição com o terminal aberto |
| 26 | `Alertas.lua` | Faixa na tela, som, ícone piscando |
| 27 | `Terminal.lua` | Janela própria, que abre com `AUCTION_HOUSE_SHOW` e fecha com `AUCTION_HOUSE_CLOSED` (base 7) |
| 28 | `Telas.lua` | As cinco telas |
| 29 | `Sonda.lua` | Medições da seção 8.4 |
| 30 | `Comandos.lua` | `/pregao` (abrir, sonda, estado); nenhuma opção |

Regra de pureza: os arquivos `Motor*.lua` não tocam nenhuma global do jogo; recebem e devolvem tabelas, o que permite rodá-los no fengari da mesa e da bancada (base 4.9). A bancada roda Lua 5.3 e o jogo, 5.1 (R4a 4); um checador novo barra o que diverge entre as duas.

### 3.3 Fluxo dos dados

```
tecla do dono -> Teclas -> presença renovada
Varredura -> Pedidos -> C_AuctionHouse (consultas) -> eventos -> Fotos
Fotos -> MotorLiquidez (diferença) -> MotorValor -> MotorVenda -> MotorPostagem / MotorSinais -> MotorRisco
MotorRisco -> fila de decisões -> Telas
tecla do dono -> Acoes (OnClick) -> C_AuctionHouse (ação) -> eventos -> Carteira, Diario
correio aberto pelo dono -> Correio -> Razao -> Diario (desfecho)
/reload -> SavedVariables no disco -> mesa -> Mesa.lua -> próximo /reload
```

O cálculo pesado é fatiado: 2 ms por quadro, medidos em tempo e não em quadros (R9 11.1), porque em segundo plano o cliente é limitado, por padrão, a 30 quadros por segundo (base 3.8). `[H-01]` corrotinas e `debugprofilestop` servem ao fatiador; medida: teste de carga na onda 1; a alternativa é máquina de estados explícita (R9 11.6).

### 3.4 Pedidos e throttle

- Um pedido em voo por vez. Tipos: `PAINEL` (`SendBrowseQuery` e `RequestMoreBrowseResults` até `HasFullBrowseResults`, base 2.1), `ESCADA` (`SendSearchQuery`, base 2.2), `PROPRIOS` (`QueryOwnedAuctions`, base 2.10).
- Balde de fichas: 60 buscas por minuto de início, abaixo do limite documentado de 100 (base 2.2); o valor medido substitui.
- Só envia com `IsThrottledMessageSystemReady()` verdadeiro e grava a hora dos cinco eventos de throttle (base 2.14). `[H-02]` a prontidão vale também para consultas (o UI da Blizzard só a confere ao postar, R1b 8).
- Prazo de resposta de 10 s (`T_resp`); falha descarta a foto e três seguidas abrem o disjuntor de dados. "Não pronto" por mais de 30 s vira `THROTTLE_PRESO`: para tudo e avisa (a fila travada é relatada, base 2.14).
- `[H-03]` consulta fora de clique funciona (a Blizzard as chama de evento e de `OnShow`, R1b 14). Se a sonda negar, cada ronda sai direto da tecla.
- Foto da frente: a foto guarda a primeira página da escada e o preço de corte até onde ela é completa; a diferença entre fotos só vale abaixo do menor dos dois cortes. `[H-04]` a primeira página vem em ordem crescente de preço e cobre pelo menos 12 degraus; medida: comparar com a paginação completa em dez itens.

**Portão de presença.** O agendador só emite consultas enquanto a última tecla do dono no terminal tem menos de 90 s. Parou de teclar, o motor para de consultar. Nada no addon existe para evitar a marca de ausente; o portão existe para o contrário e segue a orientação de uma tecla por ciclo (base 8.2).

### 3.5 Máquinas de estado

Invariantes das quatro:

- Uma ação em voo de cada vez.
- Toda chamada às sete funções com `HasRestrictions` (base 2.12) e à `ConfirmCommoditiesPurchase` fica dentro do `OnClick` de um botão de `Acoes.lua`, acionado pela tecla do dono por binding de sobreposição (base 8.1). `[H-05]` esse clique satisfaz o evento de hardware (base 2.13, não testado no Forever).
- Timer e evento só mudam estado, nunca chamam ação.
- Prazo estourado leva a `INCERTO`, que bloqueia ações novas até reconciliar por dinheiro (`GetMoney`), bolsas e `QueryOwnedAuctions`.

```
VARRER (leitura; sem tecla por pedido, com portão de presença)
OCIOSO   --presente, fila não vazia, throttle pronto, ficha no balde-->  ENVIADO
ENVIADO  --evento de resultado-->  LENDO  --falta página necessária-->  PAGINANDO --> LENDO
LENDO    --até o corte-->  GRAVA (completa = sim)  --> OCIOSO
ENVIADO/PAGINANDO  --T_resp, BROWSE_FAILURE ou MESSAGE_DROPPED-->  FALHA (recuo) --> OCIOSO
qualquer --não pronto por 30 s-->  THROTTLE_PRESO      qualquer --AUCTION_HOUSE_CLOSED--> OCIOSO
```

Eventos de resultado e de falha das consultas: R1a 4 e 6.

```
COMPRAR commodity (duas teclas: [O] pede a cotação, [P] confirma)
PRONTO   --[O], com foto dentro de A_exec, caixa, tetos e disjuntores-->  COTANDO
            (StartCommoditiesPurchase dentro do OnClick)
PRONTO   --[O] com foto vencida-->  só pede a foto nova ("Refreshed, press [O] again")
COTANDO  --COMMODITY_PRICE_UPDATED e o EV recalculado ainda passa-->  COTADO (total e segundos na tela)
COTANDO  --PRICE_UNAVAILABLE, EV não passa ou prazo-->  ABORTA (CancelCommoditiesPurchase) --> PRONTO
COTADO   --[P], depois da trava de leitura de 400 ms-->  CONFIRMANDO
            (ConfirmCommoditiesPurchase dentro do OnClick)
COTADO   --cotação vencida ou [H]-->  ABORTA
CONFIRMANDO --PURCHASE_SUCCEEDED-->  REGISTRA (custo pelo delta de dinheiro) --> PRONTO
CONFIRMANDO --PURCHASE_FAILED ou SHOW_ERROR-->  FALHOU (conta para N_seq, pede foto) --> PRONTO
CONFIRMANDO --prazo-->  INCERTO
```

O UI da Blizzard aceita cotação até 5% acima (base 2.7); o motor é mais estrito: recalcula o valor esperado com o total cotado e aborta se o sinal deixou de passar. A cotação vale pelo que `GetQuoteDurationRemaining` disser (base 2.7).

```
COMPRAR item ou dar lance (uma tecla; duas se o custo passa de 5% da banca)
PRONTO  --[O]-->  ENVIADO (PlaceBid(auctionID, valor) dentro do OnClick; arremate = lance igual ao arremate, base 2.8)
PRONTO  --[O] com bilhete grande-->  ARMADO (nada é chamado)  --[P]-->  ENVIADO
ENVIADO --PURCHASE_COMPLETED(auctionID) ou BID_ADDED-->  REGISTRA --> PRONTO
ENVIADO --SHOW_ERROR (por exemplo ItemNotFound, base 1.11)-->  FALHOU      ENVIADO --prazo--> INCERTO
```

```
POSTAR (uma tecla; duas se o jogo pedir confirmação)
PRONTO  --[L], com IsThrottledMessageSystemReady, foto dentro de A_exec, depósito lido <= caixa,
          preço dentro da faixa de mercado-->  ENVIADO (PostItem ou PostCommodity dentro do OnClick)
ENVIADO --needsConfirmation e POST_WARNING-->  AVISO ("Game asks to confirm")
AVISO   --[P]-->  CONFIRMANDO (ConfirmPostItem ou ConfirmPostCommodity dentro do OnClick)
ENVIADO/CONFIRMANDO --AUCTION_HOUSE_AUCTION_CREATED(auctionID)-->  REGISTRA (previsão no diário) --> PRONTO
ENVIADO/CONFIRMANDO --POST_ERROR ou SHOW_ERROR-->  FALHOU (mostra; nada é repetido)      --prazo--> INCERTO
```

O fluxo em dois passos e o evento de criação são os da base 2.9. As duas confirmações também têm `HasRestrictions` (base 2.12), por isso a segunda tecla. No caminho de item, a quantidade maior que 1 passa pelo multisell do próprio jogo (eventos `AUCTION_MULTISELL_*`, R1b 6): é uma ação, como no botão da Blizzard.

```
CANCELAR (uma tecla; duas se houver custo)
PRONTO  --[M], com CanCancelAuction, foto fresca e GetCancelCost = 0-->  ENVIADO (CancelAuction dentro do OnClick)
PRONTO  --[M] com custo > 0-->  ARMADO (mostra o custo)  --[P]-->  ENVIADO
ENVIADO --AUCTION_CANCELED(auctionID)-->  REGISTRA (desfecho "cancelado") --> PRONTO
ENVIADO --SHOW_ERROR-->  FALHOU      ENVIADO --prazo-->  INCERTO
```

Funções e evento do cancelamento: base 2.10.

### 3.6 SavedVariables

```lua
PregaoForeverDB = {
  v = 1,
  sonda   = {},  -- parametros do jogo medidos, com data e n                       ~5 KB
  itens   = {},  -- foco: estado (~30 numeros) + anel de 64 fotos x 8 + 30 dias x 8
                 --   150 itens x ~7 KB                                            ~1,0 MB
  painel  = {},  -- consulta resumida: nivel, ruido, hora, quantidade por chave
                 --   ~8 mil itens x ~70 B                                         ~0,6 MB
  cat     = {},  -- deriva e sazonalidade por categoria                           ~60 KB
  bruto   = {},  -- escadas compactas a drenar, com numero de sequencia     teto 4,0 MB
  diario  = {},  -- previsoes, acoes e desfechos, com sequencia             teto 0,8 MB
  razao   = {},  -- lotes, faturas, caixa                                   teto 0,8 MB
  rivais  = {},  -- fase 3                                                  teto 0,4 MB
  sessoes = {}, log = {},                                                       -- ~60 KB
}
PregaoForeverCharDB = { leiloes = {}, bolsa = {}, banca = {} }                  -- ~50 KB
```

Alvo de 6 MB, teto de 8 MB. Contas: uma escada de 40 degraus ocupa cerca de 640 bytes em texto (R9 11.4); a foto da frente (12 degraus mais a cauda em 8 baldes) fica perto de 0,4 KB. Com 150 itens a 6 fotos por hora são 0,36 MB por hora, e o teto de 4 MB cobre cerca de 11 horas sem drenar. Do painel de 7.718 itens (base 2.6) o jogo guarda só o estado por chave.

As SavedVariables só vão ao disco no `/reload`, no logout e ao fechar (base 3.9): uma queda do jogo perde o que não foi salvo, por isso a tela pede `SAVE` a 70% do buffer ou a cada 45 minutos. Buffer cheio descarta primeiro as fotos de menor prioridade e grava o buraco, que não conta como exposição (R9 2.4).

- `[H-06]` o `/reload` com 8 MB leva poucos segundos; medida: hora em `PLAYER_LOGOUT` contra hora em `ADDON_LOADED` (os dois eventos estão na lista oficial do projeto, `api-forever/Events.lua`).
- `[H-07]` `C_EncodingUtil.CompressString` com Base64 (base 3.3) reduz o bruto a um terço; medida na onda 1.
- Os SavedVariables dos addons do dono gravam nesta build (o projeto os lê, base 4.1); há relato contrário de build anterior (R6b 6, incógnita 4), e a onda 1 confere no primeiro `/reload`.

### 3.7 A mesa e o ciclo com /reload

Pasta proposta: `wow/modder/ferramentas/pregao/`. Um comando, `node mesa.mjs ciclo`, com cinco passos:

1. **Ler**: abre `WTF/Account/<conta>/SavedVariables/PregaoForever.lua` só para leitura; nada é escrito na pasta do jogo.
2. **Arquivar**: anexa fotos, diário e razão a arquivos JSONL por dia, pela sequência, de forma idempotente.
3. **Calibrar**: seção 4.5.
4. **Testar**: backtest progressivo com o mesmo Lua do motor (R9 10).
5. **Gravar**: `Mesa.lua` na pasta de desenvolvimento, por arquivo temporário e renomeação, e o relatório da sessão. Editar o próprio addon nessa pasta com o jogo aberto é o ciclo normal do projeto (base 4.11).

Contrato do `Mesa.lua`:

```lua
local _, ns = ...
ns.mesa = {
  v = 1, geradoEm = 0, origem = "mesa 0.1.0",
  drenado = { bruto = 0, diario = 0, razao = 0 },   -- ate qual sequencia o arquivo ja guardou
  jogo    = { corte = { valor = nil, n = 0, ate = "" } },  -- nil = ainda estimativa
  motor   = { xi_a = { valor = 0.5, n = 0 }, eta = { vendedor = 1.0, sniper = 0.5 } },
  itens   = {},                                      -- ajustes por chave
  portoes = { G1 = false, G2 = false, G3 = false, G4 = false },
}
```

Na carga o addon confere versão e idade, aceita cada valor só dentro da faixa da tabela da R9 12 C (fora dela usa o padrão e registra) e apaga do buffer as linhas com sequência até `drenado`. Sem mesa nada se perde, só acumula. Uma estratégia só opera com duas chaves: `Config.lua` diz que o dono aprovou e `Mesa.lua` diz que o portão de calibração abriu.

Ciclo: `[U]` na tela HEALTH faz o `/reload` e o disco recebe as SavedVariables (base 3.9); a mesa roda; o `/reload` seguinte carrega os parâmetros novos, com atraso de um ciclo.

---

## 4. Motor

### 4.1 O que adoto da R9 sem mudar

| Peça | Onde | Por quê |
|---|---|---|
| `W*` como moeda comum; candidatos finitos; preço ótimo independe do custo pago | R9 4.1 a 4.3 | Uma conta só para postar, comprar, cancelar e marcar estoque |
| Teste único de compra, na escada pós-compra, com quantis conservadores | R9 5.1 | Mata a pechincha que é preço novo |
| Preço robusto da foto: média aparada das unidades baratas depois do filtro de isca | R9 1.2 | O mínimo é manipulável |
| Vendas pela fronteira entre fotos, como limite inferior, com `ξ` e censura | R9 2.1 a 2.4 | Única janela para a venda alheia (base 5.8) |
| Gama-Poisson com esquecimento e sobredispersão | R9 2.4 | Intervalo honesto com pouca amostra |
| Tabela adimensional de P(venda), mais recalibração logística | R9 3.2 f | Fórmula fechada erra até 0,27 com lote grande (QNT-05) |
| Cancelar se e só se `Δ_canc > m_hist` | R9 4.6 | Evita guerra de cobertura por reflexo |
| Kelly com incerteza, seis tetos, disjuntores de perda e de dados | R9 7 | Sobrevivência antes de retorno |
| Backtest progressivo e modo sombra | R9 10 | Evidência antes de arriscar ouro (base 4.5) |

### 4.2 O que simplifico, e quando volta

| Peça da R9 | Simplificação | Volta quando |
|---|---|---|
| Sazonalidade em 42 caixas (8.1) | Fator 1 em tudo; os dados são gravados desde o primeiro dia. Nenhuma fonte mede ciclo de hora ou dia no Forever (base 6.5) | A mesa mostrar ganho fora da amostra |
| Três dispersões (1.2) | Fase 1 usa ruído de foto e o prior da categoria; a dispersão de longo prazo pede 7 dias | Sete dias de fotos por item |
| Perfis de concorrentes (9) | Só parede e isca, lidas da escada | Sonda confirmar nomes em `owners` (base 11.5) |
| Reset (6) | Só relatório da mesa sobre varridas de terceiros | Cinco episódios por categoria (R9 6.6), e mesmo assim desligado |
| Sniper de lance (5.6) | Fora; só diário das faixas de tempo | Fonte e dados (seção 5) |
| Conversão recursiva (5.5) | Só receitas do personagem logado (`C_TradeSkillUI.GetRecipeSchematic`, base 3.7) sobre o grafo estático (base 9.2); desencanto fora, porque o cliente não traz rendimento (base 9.3) | Fase 3 |

### 4.3 O que troco ou acrescento

1. **Deriva explícita no valor.** A R9 supõe nível lento (H1.4) e teto de reversão à média. O servidor tem 12 dias e os materiais caem (base 6.1; R8b ficha 2 cita queda de 40% a 70% em duas semanas no beta). Acrescento a inclinação por categoria `b_g`: mediana, entre os itens da categoria, de `Δ ln(preço mínimo) / Δt` entre painéis separados por 6 horas ou mais, suavizada em 3 dias (`τ_b`). A mediana de centenas de itens resiste à isca que estraga o mínimo de um item só; o item herda a da categoria, encolhida pelos próprios dados. O valor de saída é calculado no instante esperado da venda, `V · exp(b · min(T_tot, 72 h))`, e o custo de carregar vira `h = V · (ρ_cap + max(0, −b))`: quem compra para revender em 48 horas num mercado em queda paga a queda. `[H-08]` a deriva de ontem prevê a de hoje; medida: erro de previsão um dia à frente, com e sem o termo.

2. **O painel como estimador de primeira classe.** A consulta resumida devolve preço mínimo e quantidade total de toda chave (base 2.1), e é barata pelo relato de campo (base 2.6, não conferido). Dela saem a deriva por categoria, o detector de amplitude (R9 8.2 c), o gatilho de foto (R9 11.5) e a escolha do universo em foco, que a R9 não define: entram os itens com giro estimado alto, preço unitário que cabe no teto por item e os que têm leilão próprio ou estoque.

3. **Preço-sombra do capital.** A R9 ordena por valor esperado por tecla (5.1). Com 5 ouro quem aperta é o caixa. A nota passa a ser `EV / (custo das teclas + ρ_B · Custo · T_tot)`, onde `ρ_B` é o retorno por hora do melhor negócio recusado por falta de caixa (média móvel, com piso em `ρ_cap`). Com banca pequena a fila sai por retorno do capital-hora; com banca folgada `ρ_B` cai e a fórmula volta ao valor esperado por tecla.

4. **Duas testemunhas.** Preço listado não é preço vendido (base 5.8). Um sinal de compra só é executável se o preço de saída tiver venda inferida recente no mesmo patamar ou acima: pelo menos 3 intervalos com venda nas últimas 24 horas (o `n_T_min` da R9) e saída abaixo do nível das vendas inferidas mais meio desvio. Sem isso o sinal aparece como `UNPROVEN` e só alimenta a sombra.

5. **Exploração dentro da indiferença.** Entre candidatos de postagem cujo `W` fica a até 2% do melhor, o motor escolhe o da célula (fila, cobertura) com menos desfechos no diário. O custo esperado fica limitado a 2% e a curva de P(venda) passa a ser medida em vez de extrapolada. A linha sai marcada `TEST`. Depende da decisão D7.

6. **Só bordas lentas.** O dono reage em segundos, por vídeo remoto, e a pechincha que dura é a que ninguém quis (R9 10.3). O sinal só aparece se a sobrevivência estimada da oferta no tempo de reação medido passar de 0,5, com a vida das ofertas por faixa de desconto tirada das fotos (R9 10.2). O motor desiste, por desenho, da disputa de milissegundos.

7. **Mesa no limite.** Fora do jogo: a tabela de P por simulação; `ξ` por subamostragem; ajuste hierárquico das elasticidades; reamostragem em blocos de um dia para o intervalo de cada métrica; e a simulação de recuperação, que gera mercado sintético com os parâmetros ajustados e confere se os estimadores os devolvem. Parâmetro que não se recupera volta ao prior.

### 4.4 Valores iniciais

Os da tabela da R9 12 C, com estas trocas:

| Parâmetro | R9 | Aqui | Motivo |
|---|---|---|---|
| `z_c` (quantil conservador) | 1,0 | 1,28 | Modelo sem revisão e servidor novo |
| `μ_min` (margem mínima) | 0,10 | 0,15 | Corte e depósito ainda são pista |
| `H_max` (prazo para vender) | 72 h | 48 h | Deriva negativa |
| `w_tot` (estoque total) | 0,75 | 0,50 | Reserva maior no começo |
| `η_real` | 0,5 | 0,5 em sniper e flip; 1,0 em vendedor | Vendedor não tem risco de preço (R9 5.4) |
| `N_foco` | derivado | até 150 | Buffer e balde de fichas |
| `ε_exp` (exploração) | não existe | 0,02 | Item 5 |
| `ω_t` (valor do tempo) | meta do dono | 0 na fase 1 | Decisão D4 |

Parâmetros do jogo: nenhum valor assumido. Pistas até a medida: corte de 5% (base 1.4), durações de 2, 8 e 24 horas (base 1.5), depósito devolvido na venda e perdido na expiração e no cancelamento (base 1.7), ordem entre preços iguais no pior caso (R9 3.1; base 2.17). O depósito nunca vem de fórmula: é lido de `CalculateItemDeposit` ou `CalculateCommodityDeposit` na hora (base 1.4). O preço de vendedor é lido de `C_Item.GetItemInfo` na hora, nunca de tabela (base 3.2 e 6.3).

### 4.5 Diário de calibração: de estimativa a número medido

O projeto já tem o padrão (base 4.9). Aqui ele é o centro: toda linha abaixo nasce como estimativa, e a tela HEALTH mostra qual já foi medida.

| Estimativa | Sinal gravado no jogo | Métrica na mesa | O que troca |
|---|---|---|---|
| Corte | Fatura do correio: arremate e consignação (base 3.1) | Razão exata por venda | `jogo.corte`, depois de 3 vendas iguais |
| Depósito cobrado | Valor lido antes de postar contra o delta de `GetMoney` | Diferença em cobre | Alarme se divergir (há relato de beta, R8b FW) |
| Devolução do depósito | Fatura e dinheiro em venda, expiração e cancelamento | Três desfechos baratos | `r_s`, `r_x`, `r_c` |
| Ordem entre preços iguais | Dois lotes próprios no mesmo preço, postados com uma hora de diferença; qual vende primeiro | Dez pares | `Ω` |
| Cadência do throttle | Hora dos cinco eventos (base 2.14) | Consultas sustentadas por minuto | Balde de fichas |
| Vendas subcontadas | Série densa (1 a 2 min) de alguns itens | Subamostragem a 5, 15, 30 e 60 min (R9 2.9) | `ξ_a`, `ξ_b` |
| Taxa de venda | Venda própria enquanto na frente | Taxa de execução contra a taxa inferida | Prior da categoria |
| P(venda) | Previsão por postagem e desfecho (R9 3.6) | Brier e curva de confiabilidade por célula | `a0_cal`, `a1_cal` |
| Intervalo do valor | Preço de cada venda própria e inferida | Cobertura contra a nominal | `k_IC` |
| Deriva | Painel por categoria | Erro um dia à frente | `τ_b`, ou desliga o termo |
| Valor esperado de compra | Sinal, execução ou sombra, e vendas do lote | Realizado sobre previsto, por estratégia | `η_real` |
| Tempo de reação | Hora do sinal na tela e hora da tecla | Mediana por tipo de ação | `δ_react` e o custo das teclas |
| Vida das ofertas | Sinal de sombra presente ou não na foto seguinte | Vida mediana por faixa de desconto | Filtro de borda lenta |
| Atraso do correio | Aviso de venda no chat (base 2.11) até a fatura | Minutos | Caixa projetado (base 1.8) |

### 4.6 Escada de habilitação

| Portão | Abre | Condição conferível |
|---|---|---|
| G0 | Terminal em leitura | Sonda P2, P3 e P5 preenchidas; zero erro no BugGrabber (instalado, R4b 2) em uma sessão |
| G1 | Postar e cancelar por tecla | G0, sonda P1 positiva e decisão D1 |
| G2 | Compra contra o vendedor | G1, três conferências do preço de vendedor na janela do NPC, aprovação da estratégia |
| G3 | Sniper e flip ao vivo | Corte e devoluções medidos; 40 postagens próprias resolvidas com Brier melhor que a linha ingênua; cobertura do intervalo entre 0,80 e 0,97 para nominal de 0,90 em 30 preços; 25 sinais de sombra com limite inferior de `η_real` acima de zero; backtest conservador com mediana positiva; aprovação de cada estratégia |
| G4 | `k_K` até 0,5 | Duas semanas dentro das metas (R9 7.7) |
| G5 | Sazonalidade e espera | Ganho fora da amostra |

Se G3 nunca abrir, o addon continua útil como precificador do lado vendedor e o projeto registra por quê.

---

## 5. Estratégias

Todas nascem desligadas em `Config.lua`. O cálculo de postagem não é estratégia: é medida e conta sobre o que o dono decidiu vender. Sobre ele as fontes públicas se contradizem ("Undercut by a copper", R8a F5; "leave a real gap", R8b R6; cobrir pouco "isn't automatically useful anymore" em commodity, R8b R12), então o motor não embute nenhuma dessas regras: mede qual candidato dá o maior `W` em cada item.

| # | Estratégia | Fonte | Sinal mensurável | Regra | Risco | Condição para ligar |
|---|---|---|---|---|---|---|
| E1 | Leilão abaixo do preço de vendedor | R8a ficha 5; R8b R8 | Arremate menor que o preço de vendedor lido na hora (base 3.2) | Comprar se o ganho cobre teclas e a ida ao NPC (R9 5.4); só tetos, sem Kelly | Hotfix de preço de vendedor (base 6.3); espaço de bolsa | G2 |
| E2 | Sniper de arremate mal precificado | R8a ficha 1 (doc da TSM de 2022, guia genérico; nenhuma fonte do Forever) | Preço abaixo de `a_max`, derivado por item (R9 5.2) | Teste único, duas testemunhas, borda lenta, lote de sondagem na guarda de regime | Isca de vendedor (R8a F23); valor velho; robôs | G3 |
| E3 | Flip no vão | R8a ficha 2 (fã e guia genérico) | Vão entre degraus maior que corte, depósito e margem (R9 5.3) | Mesmo teste com profundidade pequena; lote até a parcela da demanda | O vão fecha com oferta nova; estoque parado (R8a F18) | G3 |
| E4 | Conversão por receita | R8a ficha 6 (addon Arbitrage; tabelas antigas) | Lucro menos incerteza, com custo na profundidade (R9 5.5) | Só receita do personagem logado; limite pela absorção do produto | Produto sem liquidez; hotfix; rendimento não medido | Fase 3, depois de G3 |
| E5 | Queda de materiais no lançamento | R8b ficha 2 (guias sobre o beta); base 6.1 | Deriva por categoria | Não é operação: entra no custo de carregar e bloqueia compra que não paga a queda | Curva do beta não se repetir | Aprovação do dono (D3); `[H-08]` decide se fica |
| E6 | Hora e dia da semana | R8b ficha 1 (opinião; nenhuma medida) | Preço e taxa por bloco de 4 horas | Nenhuma até a mesa medir | Padrão inexistente em servidor novo | G5 |
| E7 | Abertura de raide | R8b ficha 3 (previsões sem dados); base 6.4 | Preço e volume de consumíveis 7 dias antes e 3 depois | O calendário só arma o motor: Kelly pela metade e intervalo inflado (R9 8.2 d). Estocar fica fora | Demanda mudar por patch | O dado desta abertura vira evidência para a próxima |

Não entram, e por quê:

- **E8, reset de mercado raso** (R8a ficha 4: folclore e post de jogador). A R9 6.3 dá valor esperado negativo em item líquido, e comprar tudo para repostar caro é o padrão que mais se parece com manipulação. Fica só o relatório da mesa sobre varridas de terceiros.
- **E9, formação de mercado no spread.** Sem fonte (R8a ficha 3). O dado próprio vira evidência assim: a sombra grava a captura hipotética de ida e volta, a mesa relata, e o dono decide qual fonte seguir (base 4.5).
- **E10, lance em leilão acabando** (R8a ficha 7: wiki do retail). Prorrogação e incremento são desconhecidos; o diário só grava as faixas de tempo.
- **E11, casa neutra e entre facções** (R8a ficha 8: fã e fonte de 2011). Sem dado do Forever (base 1.3, 11.8).
- **E12, raros, receitas e azuis** (R8b ficha 4, beta). Taxa de venda abaixo do mínimo: o motor mostra referência com intervalo largo e nenhum sinal de compra.
- **Vendedor com estoque limitado** (R8a ficha 5, sem fonte do Forever). O cliente só mostra o estoque atual (base 9.3); a série gravada vira a evidência.

---

## 6. Interface

### 6.1 Princípios

- Terminal fino: cada linha é uma decisão do motor com o número que a justifica. Em inglês, sem fonte na tela, no máximo 5 linhas por seção com `Show N more` (base 4.7).
- Janela própria que abre e fecha com o leilão, sem aba no quadro da Blizzard (base 7).
- Nenhuma caixa de texto: com foco numa caixa as teclas não disparam (base 3.4). Preço e quantidade vêm do motor; `[Y]` alterna entre os três melhores candidatos.
- Toda ação tem botão visível com o rótulo da tecla; o clique do mouse no botão vale igual.

### 6.2 Teclas

Proposta com as doze letras que os arquivos dão como livres (base 4.10), a conferir contra os padrões do cliente pela sonda e a aprovar pelo dono (D5). São bindings de sobreposição: valem só com o terminal aberto e somem ao fechar (base 3.4 e 8.1), sem mexer nos bindings salvos. Mudar binding em combate falha (base 3.4): o terminal só liga as teclas fora de combate.

| Tecla | Função | Chama ação do jogo? |
|---|---|---|
| `I` / `K` | Linha acima / abaixo | Não |
| `N` / `B` | Próxima tela / anterior | Não |
| `U` | Atualizar a foto do item em foco; em QUEUE sem foco, pedir o painel; em HEALTH, salvar | Não (consulta ou `/reload`) |
| `Y` | Alternar o candidato | Não |
| `H` | Dispensar a recomendação (grava "recusou") | Não |
| `O` | BUY ou BID | Sim: `StartCommoditiesPurchase` ou `PlaceBid` |
| `L` | POST | Sim: `PostItem` ou `PostCommodity` |
| `M` | CANCEL | Sim: `CancelAuction` |
| `P` | CONFIRM, a segunda tecla | Sim: `ConfirmCommoditiesPurchase`, `ConfirmPost*`, ou a ação armada |
| `C` | COLLECT, uma carta por tecla, com o correio aberto | Sim: `TakeInboxMoney` ou `AutoLootMailItem` |

Compra, venda e cancelamento ficam em teclas diferentes, para a memória do dedo não trocar uma pela outra. Confirmar fica em tecla distinta da que arma, para um toque duplo não confirmar sem leitura. A roda do mouse não aciona ação (a TSM relata que a Blizzard quebrou a macro de roda, base 5.1); só rola a lista.

### 6.3 Telas

QUEUE e BOOK estão desenhadas com a compra já liberada (fase 2); HEALTH, na fase 1.

**QUEUE: o que fazer agora.**

```
+- PregaoForever -------------------- [1 QUEUE] 2 BOOK  3 SELL  4 MINE  5 HEALTH -+
| Cash 4g 87s   Stock 61s   Day +3s 12c   Data FRESH 71/96   Buy: LIVE            |
+---------------------------------------------------------------------------------+
| DO NOW                                              gain     chance   data      |
| > 1 POST    Light Leather x20   1s 44c  8h          +21s     0.78     12s       |
|   2 CANCEL  Peacebloom x12      41c  310 ahead      +2s      0.04     40s       |
|   3 BUY     Linen Cloth x38     up to 31c           +1s 90c  0.71     STALE     |
|   4 VENDOR  Copper Ore x12      2c, vendor 4c       +24c     1.00     25s       |
|   5 KEEP    Coarse Thread x5    3 ahead             -        0.83     1m        |
|   Show 3 more                                                                   |
+---------------------------------------------------------------------------------+
| WHY (line 1)                                                                    |
|   Fair 1s 52c (1s 41c to 1s 63c)   Sells 34/h   Ahead of you: 0   Deposit 6c    |
|   Next best: MATCH 1s 45c, chance 0.61, +19s                                    |
+---------------------------------------------------------------------------------+
| [I][K] move  [U] refresh  [L] POST  [O] BUY  [M] CANCEL  [P] confirm  [H] skip  |
+---------------------------------------------------------------------------------+
```

**BOOK: a escada do item em foco.**

```
+- PregaoForever --------------------- 1 QUEUE [2 BOOK] 3 SELL  4 MINE  5 HEALTH -+
| Linen Cloth    stackable    photo 12s ago (FRESH)    front complete: YES        |
+---------------------------------------------------------------------------------+
| LADDER                 qty    sellers   total    note                           |
|   29c                    4       1         4     BAIT                           |
|   31c                   38       3        42     buy up to here                 |
|   44c                  120       9       162     your exit: 43c                 |
|   45c                 2400       1      2562     WALL                           |
|   47c                  310       6      2872                                    |
|   Show 7 more                                                                   |
+---------------------------------------------------------------------------------+
| ESTIMATES                                                                       |
|   Fair value   41c (37c to 46c)        Trend  -2.1% a day (group)               |
|   Sales        at least 52/h (9 photos)   New supply  61/h                      |
|   Exit value   36c per unit after cut, deposit and wait                         |
|   Proof        sold at 43c or more in last 24h: YES (6 times)                   |
+---------------------------------------------------------------------------------+
| [I][K] move  [U] refresh  [O] BUY 38 up to 31c  [P] confirm  [H] skip           |
+---------------------------------------------------------------------------------+
```

**SELL: o que há nas bolsas e como postar.**

```
+- PregaoForever --------------------- 1 QUEUE  2 BOOK [3 SELL] 4 MINE  5 HEALTH -+
| BAGS                       plan       price    time   lot   chance   net each   |
| > 1 Light Leather x43      UNDERCUT   1s 44c   8h     x20   0.78     1s 31c     |
|   2 Peacebloom x12         MATCH      38c      24h    x12   0.55     31c        |
|   3 Copper Ore x9          WAIT       -        -      -     -        vendor 5c  |
|   4 Green item x1          NO DATA    -        -      -     -        -          |
|   Show 2 more                                                                   |
+---------------------------------------------------------------------------------+
| OPTIONS (line 1)                                                                |
|   a UNDERCUT  1s 44c  8h   x20   chance 0.78   net 1s 31c   BEST                |
|   b MATCH     1s 45c  8h   x20   chance 0.61   net 1s 27c                       |
|   c BEHIND    1s 52c  24h  x43   chance 0.33   net 1s 12c                       |
+---------------------------------------------------------------------------------+
| [I][K] move  [Y] next option  [U] refresh  [L] POST  [P] confirm                |
+---------------------------------------------------------------------------------+
```

**MINE: meus leilões e o correio.**

```
+- PregaoForever --------------------- 1 QUEUE  2 BOOK  3 SELL [4 MINE] 5 HEALTH -+
| MY AUCTIONS                price     left    ahead   chance   advice            |
| > 1 Light Leather x20      1s 44c    6h      0       0.81     KEEP              |
|   2 Peacebloom x12         41c       1h      310     0.04     CANCEL (+2s)      |
|   3 Linen Cloth x38        43c       21h     42      0.66     KEEP              |
|   4 Light Leather x20      SOLD      pay in 48m               +26s 90c          |
|   Show 1 more                                                                   |
+---------------------------------------------------------------------------------+
| MAIL                                                                            |
|   Waiting: 2 sales (+41s), 1 expired item     Open a mailbox to collect         |
+---------------------------------------------------------------------------------+
| [I][K] move  [U] refresh  [M] CANCEL  [P] confirm  [C] collect (at mailbox)     |
+---------------------------------------------------------------------------------+
```

**HEALTH: saúde do motor, calibração e guardas.**

```
+- PregaoForever --------------------- 1 QUEUE  2 BOOK  3 SELL  4 MINE [5 HEALTH] -+
| SESSION  1h 42m    actions 31    result +9s 40c    Sell: LIVE    Buy: SHADOW     |
+----------------------------------------------------------------------------------+
| DATA                                                                             |
|   Requests   OK    0.5s each    0 dropped    41 of 60 a minute                   |
|   Photos     96 items    fresh 71    stale 19    expired 6                       |
|   Unsaved    2.9 MB of 4.0 MB    saved 38m ago                                   |
+----------------------------------------------------------------------------------+
| CALIBRATION (14 days)                                                            |
|   Sell chance   said 0.62, happened 0.57   (48 posts)      OK                    |
|   Fair value    band held 86% of sales     (61 sales)      OK                    |
|   Buy signals   got 0.41 of predicted      (27 shadow)     NOT YET               |
|   Game numbers  cut MEASURED   deposit MEASURED   tie order UNKNOWN              |
+----------------------------------------------------------------------------------+
| GUARDS                                                                           |
|   Day loss 0.4% of 5%    Stock 31% of 50%    Trade Goods: PRICE ALERT 20:10      |
+----------------------------------------------------------------------------------+
| [U] SAVE (reload)   [P] CLOSE SESSION   [N][B] screens                           |
+----------------------------------------------------------------------------------+
```

### 6.4 Fluxos tecla por tecla

**A. Varrer, decidir e comprar (commodity).**
1. O dono fala com o leiloeiro; o terminal abre em QUEUE.
2. `[U]`: sai o painel resumido e, enquanto houver presença, as escadas do foco por prioridade.
3. `[K]` até a linha `BUY`. Se o dado está `STALE`, `[U]` refaz a foto do item.
4. `[O]`: **tecla do dono**; dentro do clique sai `StartCommoditiesPurchase`. A tela mostra "Quote 11s 78c for 38, 9s left".
5. `[P]`: **tecla do dono**, aceita só 400 ms depois da cotação; dentro do clique sai `ConfirmCommoditiesPurchase`.
6. Resultado na linha: `BOUGHT` (lote na carteira, custo pelo delta de dinheiro) ou `FAILED`. Nada é tentado de novo.
7. `[H-09]` a mercadoria chega às bolsas ou ao correio com atraso (existe `AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE`, R1a 4); a carteira marca o lote "em trânsito" até vê-lo.

Item não empilhável: no passo 4, `[O]` (**tecla do dono**) chama `PlaceBid` com o valor do arremate; se o bilhete passa de 5% da banca, `[O]` só arma e `[P]` chama.

**B. Postar.**
1. `[N]` até SELL. A lista vem das bolsas (`C_Container`, R1c 2), sem arrastar item.
2. `[K]` escolhe a linha; `[Y]` troca o candidato.
3. `[L]`: **tecla do dono**; dentro do clique sai `PostCommodity` ou `PostItem`. Com foto vencida a tecla só refaz a foto.
4. Se o jogo pedir confirmação, a tela mostra "Game asks to confirm"; `[P]`: **tecla do dono**, dentro do clique sai `ConfirmPost*`.
5. `POSTED` com o número do leilão; a previsão vai para o diário. No erro conhecido de equipamento abaixo do menor preço (base 1.11) a tela sugere `[Y]` até `MATCH`, e o dono decide.

**C. Cancelar e repostar.**
1. `[N]` até MINE; `[K]` até a linha `CANCEL`.
2. `[U]` refaz a foto (o cancelamento exige dado fresco).
3. `[M]`: **tecla do dono**; dentro do clique sai `CancelAuction`. Havendo custo (`GetCancelCost`), a tela o mostra e pede `[P]`: **tecla do dono**.
4. `[H-10]` o item cancelado volta pelo correio com atraso (mesmo evento de entrega) ou direto às bolsas; medida na sonda P6.
5. Quando o item aparece nas bolsas, SELL o traz no topo: `[L]` (e `[P]`), como no fluxo B. O tempo real deste ciclo alimenta o custo de cancelar no motor.

**D. Recolher o correio.**
1. O dono abre a caixa de correio. O addon lê cabeçalhos e faturas (`GetInboxHeaderInfo`, `GetInboxInvoiceInfo`, base 3.1) antes de qualquer coleta e mostra "Read 7 of 7, safe to collect".
2. Coleta por uma de duas vias, à escolha do dono (D6): o botão de abrir tudo da própria Blizzard, com um clique do dono (o laço é do UI dela: `OpenAllMailMixin` em `Blizzard_MailFrame/MailFrame.lua`, no espelho; se o botão aparece no Forever é item da sonda P8), ou `[C]`: **tecla do dono**, uma carta por tecla (`TakeInboxMoney` ou `AutoLootMailItem` dentro do clique).
3. A cada `MAIL_INBOX_UPDATE` (R1c 1) o addon relê.
4. O delta de `GetMoney` tem de bater com a soma das faturas; senão, `LEDGER MISMATCH` em HEALTH e as compras ficam suspensas até a mesa conferir.

**E. Fechar a sessão.**
1. `[N]` até HEALTH.
2. `[P]`: fecha a sessão no banco (resultado, contagens, parâmetros vigentes) e faz o `/reload` dentro do clique. `[H-11]` `ReloadUI` chamado de um clique de addon é aceito; se não for, a tela pede para digitar `/reload`.
3. A mesa roda o ciclo e grava `Mesa.lua` e o relatório da sessão no formato do projeto (base 4.7).
4. No meio de uma sessão longa, `[U]` em HEALTH faz só o salvamento.

### 6.5 Adaptações para acesso remoto

- Tudo por tecla; nenhum arrasto, nenhuma informação só em tooltip (base 8.4).
- Linha com 28 px de altura (alvo de pelo menos 24 px), contraste de 4,5:1, estado sempre em texto (`FRESH`, `STALE`, `SHADOW`), nunca só em cor (base 8.4).
- Fonte na escala do usuário e números em colunas fixas, a testar na tela do Acer, depois da compressão do vídeo (R10a 4).
- Trava de leitura de 400 ms antes de aceitar `[P]`; toque repetido em menos de 250 ms e tecla com ação em voo são descartados.
- Alerta nunca depende só de som, que pode não atravessar o stream (R10a 4, inferência).
- O tempo de reação é medido e entra no motor (seção 4.3, item 6): a latência remota vira parâmetro.
- Ausência: o addon não interfere. Sem teclas, o portão de presença para as consultas e a tela mostra `PAUSED`.

### 6.6 Alertas

Faixa no topo do terminal, mais `PlaySound` e `FlashClientIcon` (base 3.6), para: venda, expiração e lance superado (avisos do jogo com o número do leilão, que chegam mesmo com o leilão fechado, base 2.11); leilão próprio enterrado, visto na foto; disjuntor aberto; `THROTTLE_PRESO`; buffer a 70%; alarme de regime; `LEDGER MISMATCH`; leilão indisponível.

---

## 7. Risco e conformidade

### 7.1 Guardas e tetos

- Tetos de posição da R9 7.3: Kelly; por item (10% da banca); por categoria (30%); estoque total (50%); por dias de volume; por fração do volume diário, para não ser o mercado.
- Perda diária de 5% da banca leva a modo só venda; 2,5% avisa; perda de 1% num item bloqueia o item por 24 horas (R9 7.5). O dono sobrepõe por `Config.lua`, não pela tela.
- Disjuntores de dados: fotos incompletas em sequência, throttle anômalo, cinco compras seguidas que "já tinham sumido" (`N_seq`, R9 7.5), `LEDGER MISMATCH`, alarme de amplitude na categoria.
- Idade do dado: nada se executa com foto mais velha que 30 s (`A_exec`).
- Banca marcada a valor de liquidação conservador, nunca a custo (R9 7.1); só conta o ouro do personagem logado, porque não há banco de conta (base 4.2).

### 7.2 Quando a API falha ou devolve nada

| Situação | Comportamento |
|---|---|
| Função de ação não faz nada (`FailureMode = ReturnNothing`, base 2.12) | Prazo, estado `INCERTO`, reconciliação; a tela diz "No response from the game"; nenhuma repetição |
| `ADDON_ACTION_BLOCKED` ou `FORBIDDEN` (R1c, extra) | Registra, desliga todas as ações da sessão e pede a sonda |
| Consulta sem resposta, descartada ou parcial | Foto descartada; nunca atualiza estimador (R9 1.5) |
| `timeLeftSeconds` nulo ou `owners` vazio (base 2.3, 2.4) | Motor usa a faixa de tempo e a assinatura do degrau; perfis por nome ficam desligados |
| Informação de item ainda não carregada (base 2.15, 3.2) | Linha `LOADING`; sem decisão |
| "Internal Auction Error" e "item not found" (base 1.11) | Mostra, conta, sugere igualar no primeiro; o segundo alimenta o disjuntor de compras perdidas |
| Cotação subiu | Recalcula o valor esperado e aborta se não passa |
| `AUCTION_HOUSE_DISABLED`, ou erro `HasRestriction` ou `Unavailable` (R1a 3) | Para tudo com `AUCTION HOUSE UNAVAILABLE`. Pode ser o Economy Hold (base 1.10): o addon não insiste |
| Throttle preso | Para consultas; pede fechar e reabrir o leilão. `[H-12]` reabrir destrava |
| `Mesa.lua` ausente, velho ou inválido | Padrões da R9, portões fechados, aviso em HEALTH |

### 7.3 Não parecer RMT (base 1.10)

O suporte citou dois sinais: comprar ou vender item barato por muito ouro e preço muito fora do mercado. Guardas:

- Faixa de mercado na postagem: o addon recusa postar abaixo do preço de vendedor ("never list below vendor price", R8b R8) e acima de três vezes o topo do intervalo do valor justo. Sem valor justo medido, não posta: mostra `NO DATA`.
- Na compra, nunca acima do valor justo: o teste único já exige desconto.
- Nunca comprar leilão da própria conta: `containsOwnerItem` ou `containsAccountItem` (base 2.3, 2.4) bloqueia a linha.
- Nenhum fluxo de transferência entre personagens pelo leilão.
- Teto de fração do volume diário por item.
- Diário e razão completos. Num hold, o dono tem o registro de cada operação para mostrar ao suporte.
- Acesso remoto ao próprio PC não tem posição oficial (base 8.3); a escolha da ferramenta fica fora do addon (D8).

### 7.4 O que o addon se recusa a fazer

Além da lista da seção 2: repetir ação que falhou; executar com dado vencido; operar estratégia sem as duas chaves (aprovação do dono e portão); postar fora da faixa; comprar sem prova de venda; alterar binding salvo, CVar ou qualquer configuração do dono (base 4.7); chamar ação com restrição de addon ativa (`C_RestrictedActions`, base 2.16).

---

## 8. Testes

### 8.1 Bancada com leilão falso

A bancada atual não simula leilão, dinheiro nem ticker repetido (base 4.9). Estende-se com um `C_AuctionHouse` falso sobre um simulador de mercado com semente fixa (os simuladores da R9 0.3, hoje em pasta temporária, viram a base), mais `GetMoney`, correio, bolsas, relógio e ticker repetido. O falso injeta falhas por caso: resposta que não chega, página parcial, mensagem descartada, ação que não devolve nada, `POST_WARNING`, `POST_ERROR`, `ItemNotFound`, cotação 6% acima, `timeLeftSeconds` nulo, `owners` vazio, throttle preso, leilão fechado no meio.

- Casos por máquina de estado: cada transição da seção 3.5.
- Provas negativas: nenhuma função de ação é chamada fora de um clique simulado; tecla durante ação em voo não gera chamada; prazo leva a `INCERTO` e bloqueia; a razão fecha ao cobre depois de qualquer sequência.
- Propriedades do motor puro: P(venda) não cresce com a fila; `W` não cresce com o depósito; valor esperado de compra não cresce com o preço; duas fotos iguais dão zero venda; sumiço acima da fronteira nunca conta como venda (QNT-01); as conferências numéricas da R9 0.3 se repetem dentro da tolerância.

### 8.2 Replay das fotos gravadas

A mesa repassa o arquivo em ordem de tempo com o mesmo Lua do motor (R9 10.5), em validação progressiva (calibra em 7 dias, testa em 2, avança), nas variantes conservadora e central de preenchimento, com as linhas de base da R9 10.4 e intervalos por reamostragem. O relatório declara os vieses que não controla: só há fotos nas horas em que o dono jogou e a cadência é fixa (R9 10.3).

### 8.3 Checadores estáticos

- `checar-lua.mjs` na pasta do addon (sintaxe 5.1, ASCII).
- `checar-combate.mjs --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER,BINDING_` (API fora da lista, protegida sem guarda, eventos, TOC; base 4.9).
- Novo `checar-acoes.mjs`: os nomes das funções de ação (as sete com `HasRestrictions`, `ConfirmCommoditiesPurchase`, `TakeInboxMoney`, `TakeInboxItem`, `AutoLootMailItem`, `BuyMerchantItem`) só aparecem em `Acoes.lua` e só dentro de função registrada na tabela de cliques; `ReplicateItems` só em `Sonda.lua`; `Motor*.lua` não referencia global do jogo nem construção que divirja entre Lua 5.1 e 5.3.
- Casos bons e ruins para o checador novo, no padrão de `rodar-casos-combate.mjs`.

### 8.4 A sonda no jogo

Na ordem de peso da base 11. O que paga depósito espera a manutenção de 17/11, quando o mínimo cai de 1 prata para 1 cobre (base 1.7); o depósito é medido de novo depois dela.

| # | Medir | Como | Custo |
|---|---|---|---|
| P1 | A tecla por binding de sobreposição satisfaz as ações (`[H-05]`), e se a confirmação pede evento próprio | Uma postagem e um cancelamento de item barato, cada um pela tecla; observar criação, `ADDON_ACTION_BLOCKED` e `FORBIDDEN` | Um depósito |
| P2 | Empilháveis são commodity; como o verde com sufixo aparece na chave (base 11.2) | `GetItemCommodityStatus` nas bolsas e `GetItemKeyInfo` no painel; só leitura | Zero |
| P3 | Tempo e pedidos do painel completo; limite para repetir; cadência do throttle; `[H-02]`, `[H-03]`, `[H-04]` | Cronometrar pelos eventos, numa ronda | Zero |
| P4 | `ReplicateItems` responde (base 11.4) | Opcional: uma chamada, uma vez, pedida pelo dono; o desenho não depende dela | Zero |
| P5 | `owners` com nomes; `timeLeftSeconds` em leilão alheio (base 11.5) | Leitura de dez escadas | Zero |
| P6 | Depósito por duração e quantidade; corte na fatura; devolução em venda, expiração e cancelamento; `[H-09]`, `[H-10]` | Leitura de `CalculateItemDeposit`; três leilões baratos, um para cada desfecho | Três depósitos |
| P7 | Ordem entre preços iguais | Pares de lotes próprios no mesmo preço (seção 4.5) | Depósitos |
| P8 | Outros: `SupportsCopperValues` (R1b 7) e tick; duração da cotação; `[H-01]`, `[H-06]`, `[H-07]`, `[H-11]`, `[H-12]`; o que cada tecla proposta faz hoje; se o correio do Forever tem o botão de abrir tudo; atraso do correio | Leitura e cronômetro | Zero |

Fora da sonda: o teste negativo (chamar uma ação sem tecla para ver o que acontece). O desenho não precisa dessa resposta, e obtê-la exigiria tentar agir sem o dono.

### 8.5 Critério de aceite

1. Checadores com zero erro e todos os casos da bancada passando.
2. Sonda P1 a P3 e P5 gravadas com valor e data.
3. Uma sessão real de uma hora sem erro no BugGrabber e sem ação em estado `INCERTO` não reconciliada.
4. Razão sem divergência depois de uma venda, uma expiração e um cancelamento reais.
5. Ciclo da mesa completo: `/reload`, arquivo, `Mesa.lua` novo, buffer drenado no `/reload` seguinte.
6. Em vídeo ou print da sessão, cada ação casa com uma tecla registrada no diário.

---

## 9. Entrega em ondas

Segue o padrão do projeto: contrato e esqueletos na sessão principal, subagentes por tarefa, checador ou bancada como critério de pronto, portão final na sessão principal (base 4.9). A coluna de rota é sugestão; a tabela da skill `executar-plano` decide.

| Onda | Tarefas | Rota sugerida | Pronto quando |
|---|---|---|---|
| 0. Contrato | `ARQUITETURA.md` com tabela "API, Contrato" por módulo; TOC com os 30 arquivos em esqueleto; `Config.lua` inicial; `checar-acoes.mjs` e seus casos | Sessão principal; checador em `sonnet/medium` | `node checar-lua.mjs <pasta>` e `node checar-combate.mjs <pasta> --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER,BINDING_` com zero erro; casos do checador novo em `RESUMO erros=0` |
| 1. Ver sem agir | `Nucleo`, `Pedidos`, `Varredura`, `Fotos`, `Sonda` (leitura), `Teclas`, `Terminal` com BOOK e HEALTH; leilão falso, lado de leitura | Código em `sonnet/medium`; casos em `haiku/medium` | Bancada com falhas injetadas em `erros=0`; no jogo, `PregaoForeverDB.sonda` com P2, P3 e P5; portão G0 |
| 2. Motor puro e mesa | `MotorBase`, `MotorValor`, `MotorLiquidez`, `MotorVenda`, `MotorPostagem`, `TabelaP`; mesa: ler, arquivar, replay | Motor em `sonnet/high`, com revisão matemática na sessão principal; mesa em `sonnet/medium` | Propriedades da seção 8.1 em `erros=0`; a diferença de escadas recupera a fração da R9 0.3 no sintético, dentro de 5 pontos; `node mesa.mjs ciclo --ensaio` fecha a ida e volta numa amostra gravada |
| 3. Vender com tecla | `Acoes` (postar, cancelar), `Carteira`, `Razao`, `Correio`, `Diario`, telas SELL e MINE; sonda P1 e P6 | `Acoes` na sessão principal; resto em `sonnet/medium` | Casos de máquina de estado em `erros=0`; `checar-acoes` zero; no jogo, uma postagem, uma venda, uma expiração e um cancelamento com `razao.divergencia == 0`; portão G1 |
| 4. Sombra e calibração | `MotorSinais` em sombra, `MotorRisco`, tela QUEUE, `Alertas`; mesa: calibrar, backtest, relatório | `sonnet/high` | Depois de cinco sessões: relatório de calibração gerado e tabela de portões calculada |
| 5. Comprar com tecla | `Acoes` (comprar): vendedor primeiro; sniper e flip quando G3 abrir | Sessão principal | Bancada em `erros=0`, com cotação que sobe e compra que some; dez compras reais reconciliadas; cada estratégia ligada por linha do dono em `Config.lua` |
| 6. Escalar | `MotorRegime`, `MotorRivais`, conversão com `Receitas.lua`, dados externos | `sonnet/high`; dados em `haiku/medium` | Cada peça só liga se a mesa mostrar ganho fora da amostra; senão fica desligada, com o relatório |

Entre as ondas 3 e 4 há uma espera que não se encurta com código: o diário precisa de desfechos reais.

---

## 10. Decisões que ficam para o dono

| # | Decisão | Recomendação |
|---|---|---|
| D1 | Liberar compra, postagem e cancelamento por tecla neste addon. Em 2026-11-06 o dono proibiu funções que compram ou gastam por código no outro addon ("O guia marca e o dono clica", base 4.6) | Liberar só em `Acoes.lua`, uma tecla por ação, duas na compra de commodity, com o checador novo como trava. Sem isso o projeto vira só leitura |
| D2 | Curadoria: Auctionator e ForeverGuide já ocupam o papel de leilão (base 4.12) | Manter o Auctionator na fase 1, como semente de preço pela API pública e para postagem manual fora do motor (base 7.1); decidir a troca quando G3 abrir. Rever o compartilhamento de varreduras do ForeverGuide (base 7.3) |
| D3 | Quais estratégias aprovar e com qual fonte (base 4.5) | Agora só E1 (vendedor) e a deriva E5 como cálculo. E2 e E3 só com o relatório do portão G3 na mão |
| D4 | Valor do tempo e limites de perda | Valor do tempo zero na fase 1 (as teclas compram medida); perda diária de 5% e estoque de 50% da banca |
| D5 | Mapa de teclas | As doze letras livres, depois que a sonda mostrar o que cada uma faz hoje; alternativa em F1 a F12 |
| D6 | Coleta do correio e operação da mesa | Correio pelo botão de abrir tudo da Blizzard, com o addon lendo antes; mesa rodada pelo agente a cada sessão, sem vigia de arquivo no começo |
| D7 | Orçamento de experimento (exploração e pares de teste) | Até 5% da banca por semana, sempre marcado `TEST` |
| D8 | Ferramenta de acesso remoto e consulta ao suporte (base 8.3) | Seguir o R10a (Sunshine com Moonlight) e pedir resposta por escrito ao suporte; fica fora do addon |
| D9 | Credencial de desenvolvedor para a API de dados (base 5.4) | Não agora; reavaliar na fase 3, depois de ler os termos |
| D10 | Qual personagem opera e onde fica | Pergunta aberta, por ser logística de jogo. O motor conta só o ouro e o estoque do personagem logado (base 4.2) |

---

## 11. Os cinco maiores riscos deste projeto

1. **Capital pequeno demais para o modelo importar.** Com 5 ouro o valor esperado por operação é de pratas, e a calibração pede dezenas de desfechos que a banca demora a produzir. O que derruba: três semanas sem 40 postagens resolvidas, ou `η_real` com intervalo que inclui zero. Saída: o addon fica como precificador do lado vendedor.

2. **A venda alheia pode não ser inferível no Forever.** Tudo depende da fronteira entre fotos (QNT-01). Se a escada não vier em ordem (`[H-04]`), se empilháveis não forem commodity (base 11.2) ou se a cadência possível ficar longe do intervalo alvo, a taxa de venda sai errada e arrasta P(venda), `W*` e os sinais. O que derruba: `ξ` instável na subamostragem, ou taxa inferida sem relação com as vendas próprias.

3. **Mercado que não fica parado.** Servidor de 12 dias, hotfixes de preço de vendedor (base 6.3), depósito mudando em 17/11 (base 1.7), raides em 09/12 (base 6.4). A janela de calibração pode nunca descrever a semana seguinte. O que derruba: três janelas de validação progressiva sem habilidade fora da amostra.

4. **Complexidade e erro de modelo.** Trinta arquivos, mais de cem parâmetros, matemática sem revisor (base 10). Um erro de sinal na conta do valor esperado produz recomendações confiantes e erradas. O que derruba: a simulação de recuperação falhar, ou a revisão achar defeito na proposição da fronteira ou na tabela de P. Mitigação parcial: quantis conservadores, duas testemunhas, sombra antes de ouro.

5. **A borda pode não existir depois dos custos, ou a operação pode não caber nas regras.** Os concorrentes calculam sinais parecidos (base 5.2), mais rápido; o que sobra para quem reage em segundos pode valer menos que corte e depósito. E a mecânica de tecla pode não ser a esperada: binding de sobreposição não aceito (`[H-05]`), throttle mais apertado, cotação que vence no tempo do vídeo remoto. O que derruba: sonda P1 negativa (o projeto vira só leitura), ou duas semanas de sombra com valor esperado hipotético menor ou igual a zero.
