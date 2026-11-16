# CentralForever 0.1.0: contrato

Escrito em 2026-11-16 pela sessão principal, antes da execução do plano `C:\Users\PC-AVELL\.claude\plans\eu-quero-uma-central-fizzy-hopcroft.md`. Este arquivo é o contrato entre os módulos do addon e entre o addon e as ferramentas. Fica congelado durante as ondas: quem achar um erro aqui relata, não muda.

O que é: uma central de combate no canto inferior direito da tela, com o DPS da luta, o dano da luta, o dano acumulado, o tempo da luta e o threat. Pedido do dono em 2026-11-16: "extremamente boa de ver enquanto estou na gameplay intensa". O addon só exibe. Nada se configura dentro do jogo: tudo mora em `Config.lua`.

## 1. Regras que valem para todo arquivo

Valem as regras 1 a 11 da seção 1 de `..\GuiaForever\ARQUITETURA.md`, com o prefixo deste addon. Em resumo, e com o que é próprio daqui:

| # | Regra |
|---|---|
| 1 | Lua 5.1 e só ASCII, sem acento nem em comentário. Texto que aparece no jogo (painel, chat, `/central`) em inglês; comentários em português sem acento. Fim de linha LF. |
| 2 | Cada arquivo começa com `local _, ns = ...` e publica só em `ns`. Globais permitidas: `CentralForeverConfig`, `CentralForeverDB`, `SLASH_CENTRALFOREVER1`, `SlashCmdList["CENTRALFOREVER"]` e o quadro `CentralForeverPainel`. Nenhuma outra. |
| 3 | Nenhum arquivo depende de outro existir: toda chamada entre módulos é guardada (`if ns.painel and ns.painel.modo then ... end`). |
| 4 | Função protegida em combate: a única do addon é `C_CVar.SetCVar`, só em `Convivencia.lua`, numa função que começa com `if ns.emCombate() then ... return end`. |
| 5 | API de combate só em `Segredo.lua`, pela exceção 2 (seção 2). Nenhum evento quente (`COMBAT_LOG_EVENT_UNFILTERED`, `UNIT_AURA`, `SPELL_UPDATE_COOLDOWN`). |
| 6 | Nenhum quadro da Blizzard é tocado: nem `SetScript`, nem gancho, nem campo. A janela nativa do medidor sai pelo CVar dela. |
| 7 | O addon não faz nada pelo jogador: não lança magia, não troca alvo, não zera o medidor sozinho. |
| 8 | Nome de função, evento e método de widget conferido nas listas de `..\..\ferramentas\guia\api-forever\` (`GlobalAPI.lua`, `Events.lua`, `WidgetAPI.lua`). Assinatura conferida em `api-forever\doc\` (documentação gerada da Blizzard, baixada em 2026-11-16, build 70938). Função fora das listas só com checagem de existência. |
| 9 | Terceiros (ElvUI, LibSharedMedia) só por `pcall` e checagem de tipo. Nenhuma dependência dura. |
| 10 | Toda função chamada por evento, timer ou comando roda em `xpcall(fn, geterrorhandler())` (use `ns.seguro`). Toda chamada de API de combate roda em `pcall`. |
| 11 | O layout nunca mede: nada de `GetText`, `GetValue`, `GetMinMaxValues`, `GetStringWidth`, `GetStringHeight`, `GetAlpha`, `GetEffectiveAlpha`, `UIFrameFadeIn`, `UIFrameFadeOut`. Largura de campo é fixa; alfa é o que o addon mandou, guardado em variável dele. Única exceção: `GetStringWidth` em `Diario.lua`, fora de combate, num texto escondido que nunca recebe segredo. |
| 12 | Nada de `BackdropTemplate`: fundo e borda são texturas próprias (`CreateTexture` e `SetColorTexture`). |
| 13 | Tudo é criado uma vez por `ns.painel.criar()`, na carga (inclusive se a carga cair em combate, no `/reload` no meio da luta). Depois de criado o painel, o addon não cria quadro, textura, texto nem animação, e não chama `SetPoint`, `SetSize`, `SetWidth` nem `SetHeight`. Única exceção: o quadro escondido de medição do `Diario.lua`, criado fora de combate. |

## 2. Exceção 2 à regra 5 do projeto (aprovada pelo dono em 2026-11-16)

As funções `C_DamageMeter.GetCombatSessionFromType`, `C_DamageMeter.GetCombatSessionFromID`, `C_DamageMeter.GetSessionDurationSeconds`, `C_DamageMeter.ResetAllCombatSessions`, `UnitDetailedThreatSituation`, `UnitThreatSituation`, `UnitThreatLeadSituation` e `UnitThreatPercentageOfLead` podem ser mencionadas e chamadas somente em `CentralForever\Segredo.lua`, sempre em `pcall`, com argumentos literais ou tokens de unidade (nunca um valor que veio de outra API).

Cada retorno vira uma caixa (seção 4). O valor cru só é lido dentro de `Segredo.lua` e só para ser entregue a um ralo de exibição. Decisão (cor, palavra, pulso, conta do resumo, diário, visibilidade) só com os campos `s`, `tem` e `n` da caixa. Valor possivelmente secreto nunca entra em aritmética, comparação (nem com `nil`), teste booleano (`if x`, `not x`, `x and`, `x or`), concatenação, `tostring`, `string.format`, chave de tabela, SavedVariables, tamanho ou posição. Nunca o token `targettarget` nem token de nameplate.

Os outros addons próprios continuam proibidos de ler essas funções (regra 5 do `ARQUITETURA.md` e R2 do `checar-combate.mjs`).

## 3. Arquivos, ordem de carga e o que cada um publica

Ordem do `.toc`: `Config.lua`, `Nucleo.lua`, `Segredo.lua`, `Diario.lua`, `Medidor.lua`, `Ameaca.lua`, `Painel.lua`, `Convivencia.lua`, `Estados.lua`.

Quem registra evento: só `Estados.lua` (e o `Nucleo.lua`, para `ADDON_LOADED`). Os outros módulos só publicam funções. Assim a lista fechada de eventos (seção 8) mora num arquivo.

### 3.1 `Config.lua`

Global `CentralForeverConfig`, só dados. Já está completo; os módulos leem por `ns.cfg`. Nenhuma tarefa muda as chaves. Chave ausente tem padrão no código (`(ns.cfg.resumo or {}).alfa or 0.45`), porque o dono pode ter um Config antigo.

### 3.2 `Nucleo.lua` (publica direto em `ns`)

| Nome | O que faz |
|---|---|
| `ns.NOME`, `ns.VERSAO` | `"CentralForever"`, `"0.1.0"` |
| `ns.cfg` | `CentralForeverConfig` (ou `{}` se faltar) |
| `ns.seguro(fn)` | devolve uma função que chama `fn` por `xpcall(fn, geterrorhandler(), ...)` |
| `ns.ao(evento, fn)` | registra `fn(evento, ...)` para o evento. Um quadro escondido só do Núcleo; `RegisterEvent` em `pcall`; despacho em `xpcall`. Vários `fn` por evento, na ordem de registro. O primeiro argumento é sempre o nome literal do evento (o checador confere a lista). |
| `ns.depois(seg, fn)` | `C_Timer.After(seg, ns.seguro(fn))` |
| `ns.tique(seg, fn)` | `C_Timer.NewTicker(seg, ns.seguro(fn))`; devolve o objeto (tem `:Cancel()`) |
| `ns.emCombate()` | `InCombatLockdown()` como booleano |
| `ns.msg(texto)` | `print("|cff66ccffCentralForever|r: " .. texto)`; texto em inglês |
| `ns.log(texto)` | acrescenta `"AAAA-MM-DD HH:MM:SS texto"` em `CentralForeverDB.log`, com no máximo `cfg.log.max` linhas |
| `ns.db()` | `CentralForeverDB`, criando as tabelas da seção 10 que faltarem |
| `ns.chave()` | `"Nome-Reino"` do personagem (`UnitName("player")` e `GetRealmName()`, os dois passados por `tostring` só se legíveis; reserva `"?"`) |
| `ns.dbPersonagem()` | `ns.db().personagens[ns.chave()]`, criando |
| `ns.enum` | `{ sessao = { Overall = 0, Current = 1, Expired = 2 }, tipo = { DamageDone = 0 }, restricao = { Combat = 0 }, estado = { Inactive = 0, Activating = 1, Active = 2 } }`, lido de `Enum.DamageMeterSessionType`, `Enum.DamageMeterType`, `Enum.AddOnRestrictionType` e `Enum.AddOnRestrictionState` quando existem, senão os números acima |
| `ns.falhou(recurso, erro)` | conta um erro do recurso (texto curto, como `"sessao"`, `"ameaca"`, `"formato"`); ao chegar a `cfg.disjuntor.erros`, põe `ns.desligado[recurso] = true`, escreve uma linha no log e uma entrada avulsa `desligado` no diário |
| `ns.desligado` | tabela `{ [recurso] = true }`; quem lê o recurso confere antes |
| `ns.pronto` | `true` depois do `ADDON_LOADED` deste addon |

O Núcleo registra `ADDON_LOADED` (filtrando o nome do addon), garante o DB e marca `ns.pronto`. Não chama nenhum outro módulo.

### 3.3 `Segredo.lua` (publica `ns.segredo`, aqui chamado `S`)

O único arquivo que menciona as funções da seção 2 e o único que lê o campo `cru` de uma caixa.

Caixa: `S.caixa(v)` devolve `{ cru = v, s = <booleano: é secreto>, tem = <booleano: veio algo>, n = <o valor, quando legível; senão nil> }`. Ordem obrigatória dentro de `S.caixa`: primeiro `s` (por `issecretvalue`); só se `s` for falso é que se compara `v` com `nil`. Com `s` verdadeiro: `tem = true`, `n = nil`. Com `s` falso: `tem = (v ~= nil)`, `n = v`.

`S.legivel(v)`: `true` se o valor pode ser lido. Usa `issecretvalue` quando existe. Se `issecretvalue` não existir, o cliente não tem valores secretos e tudo é legível (emenda do portão da onda 1: com a regra conservadora, `isLocalPlayer` nunca seria lido e o painel ficaria sem dano). Se a chamada de `issecretvalue` falhar, o valor é tratado como secreto. Em tabela, o teste de segredo vem sempre antes de `type`.

| Função | Devolve |
|---|---|
| `S.sessao(tipoSessao)` | `{ ok = booleano, linha = booleano, dps = caixa, total = caixa, fontes = número ou nil, motivo = texto }`. O `motivo` é `"ok"`, `"desligado"`, `"ausente"` (a função não existe), `"falhou"`, `"nada"` (não veio tabela) ou `"inacessivel"` (tabela secreta); serve ao diário. Chama `C_DamageMeter.GetCombatSessionFromType(tipoSessao, ns.enum.tipo.DamageDone)`. `ok` é falso se a função não existe, o `pcall` falhou, o retorno não é tabela acessível, ou `combatSources` não é acessível (`canaccesstable`, quando existe). Percorre `combatSources` com `ipairs`; a linha do jogador é a primeira em que a caixa de `isLocalPlayer` tem `n == true`. `dps` é a caixa de `amountPerSecond`, `total` a de `totalAmount`. Sem linha: `linha = false` e caixas vazias. `fontes` é o tamanho da lista, se legível. |
| `S.duracao(tipoSessao)` | caixa de `C_DamageMeter.GetSessionDurationSeconds(tipoSessao)` |
| `S.disponivel()` | `ok, motivo`: `C_DamageMeter.IsDamageMeterAvailable()`; `ok` falso se a API não existe; `motivo` só se for texto legível |
| `S.estado(unidade, mob)` | caixa de `UnitThreatSituation(unidade, mob)`. `mob` pode ser `nil` (pior estado da unidade contra qualquer inimigo) |
| `S.detalhe(unidade, mob)` | `{ veio = booleano, tanque = caixa, pct = caixa }`, de `UnitDetailedThreatSituation(unidade, mob)`. `veio` sai de `select("#", ...)` maior que zero (a função pode não devolver nada). `tanque` é o 1º retorno e `pct` o 3º (`scaledPercentage`, 100 = ponto de puxar). |
| `S.lider(unidade, mob)` | caixa de `UnitThreatLeadSituation(unidade, mob)` (0 folga grande ... 3 pior caso ou não é o primeiro) |
| `S.nome(unidade)` | caixa do 1º retorno de `UnitName(unidade)` |
| `S.zerar()` | chama `C_DamageMeter.ResetAllCombatSessions()` em `pcall`, só fora de combate; devolve se chamou |
| `S.tipo(caixa)` | `"secreto"`, `"legivel"` ou `"nada"` (para o diário; nunca o valor) |

Ralos. Cada um roda em `pcall`, devolve `true` se escreveu, e chama `ns.falhou("formato", erro)` se errou. Com a caixa sem valor (`tem` falso), escrevem `cfg.vazio`.

| Ralo | Caminho |
|---|---|
| `S.mostrarInteiro(fs, caixa)` | `fs:SetText(C_StringUtil.RoundToNearestString(cru))`; reserva `AbbreviateNumbers(cru)`, depois `AbbreviateLargeNumbers(cru)` |
| `S.mostrarAbrev(fs, caixa)` | `fs:SetText(AbbreviateNumbers(cru))`; reserva `AbbreviateLargeNumbers(cru)` |
| `S.mostrarNumero(fs, caixa, formato)` | escolhe um dos dois acima por `formato` (`"inteiro"` ou `"abrev"`) |
| `S.mostrarPct(fs, caixa)` | `fs:SetText(C_StringUtil.WrapString(C_StringUtil.RoundToNearestString(cru), nil, "%"))` |
| `S.mostrarBarra(barra, caixa)` | `barra:SetValue(cru)` (o mínimo e o máximo são literais, postos pelo Painel na criação) |
| `S.mostrarSe(regiao, caixa, inverso)` | `regiao:SetAlphaFromBoolean(cru, 1, 0)`; com `inverso == true`, `(cru, 0, 1)` (aparece quando o booleano é falso). A região tem de ser filha própria, sem fade. Sem valor: `SetAlpha(0)`. |

O valor legível passa pelos mesmos ralos, para o número ter a mesma forma dentro e fora de combate.

### 3.4 `Diario.lua` (publica `ns.diario`, aqui `D`)

| Função | O que faz |
|---|---|
| `D.carga()` | fora de combate, uma vez por login: grava a entrada `carga` do personagem (seção 10) |
| `D.anota(tipo, t)` | entrada avulsa no anel `avulsas` (`quando` e `pers` postos aqui) |
| `D.abrirLuta(t)` | começa o registro da luta atual (contexto: zona, instância, chefe, papel) |
| `D.marca(grupo, campo, valor)` | grava no registro da luta atual; só o primeiro valor de cada campo vale (primeira leitura da luta), salvo contadores |
| `D.conta(campo, n)` | soma a um contador da luta atual (`eventosDano`, `eventosAmeaca`, `pulsos`, `escritas`) |
| `D.fecharLuta(t)` | completa (resumo, duração) e empurra para o anel `lutas` |

Com `cfg.sondas.ligado` falso, todas viram função vazia. O diário nunca recebe caixa: recebe `S.tipo(caixa)`, booleanos e números legíveis.

`D.carga()` mede as larguras num quadro escondido próprio, criado ali mesmo (fora de combate), com um FontString por campo na fonte `ns.painel.arquivoFonte()` (reserva: `cfg.fonte.arquivo`) e no tamanho do campo, com os textos do pior caso: `dps = "88888"`, `luta = "888.8K"`, `total = "888.8K"`, `tempo = "88:88"`, `palavra = "SLIPPING"`. Esse FontString nunca recebe valor de API. Os `formatos` saem de chamar `C_StringUtil.RoundToNearestString`, `AbbreviateNumbers` e `AbbreviateLargeNumbers` com números literais (0, 7, 99, 999, 1000, 1234, 9999, 12345, 123456, 999999, 1234567), cada um em `pcall`; o que não for texto legível vira `"?"`.

### 3.5 `Medidor.lua` (publica `ns.medidor`, aqui `M`)

| Função | O que faz |
|---|---|
| `M.aoEntrar(agora)` | luta nova: põe `0` no DPS e no FIGHT e `cfg.tempoZero` no tempo (textos do addon), guarda `agora` como início do relógio próprio |
| `M.atualizar()` | lê `S.sessao(Current)` e `S.sessao(Overall)` e escreve DPS, FIGHT e TOTAL pelos ralos, nos campos `ns.painel.campo(...)`. Devolve `{ linha = booleano }`. Na primeira leitura da luta, manda as sondas ao diário. |
| `M.tempo(agora)` | escreve o cronômetro `m:ss`. Fonte: `S.duracao(Current)` se a caixa for legível; senão `agora` menos o início guardado. |
| `M.aoSair(agora, feito)` | começa a captura do resumo: espera `cfg.resumo.carenciaSeg`, depois tenta até `cfg.resumo.tentativas` vezes, a cada `cfg.resumo.intervaloSeg`. Uma tentativa vale quando `S.sessao(Current)` tem linha com `dps.n` e `total.n` legíveis; se a Current vier sem linha, tenta `S.sessao(Expired)`. Ao conseguir, grava `ns.dbPersonagem().ultima = { dps, luta, total, dur, quando }` (`total` é o acumulado, da Overall; `dur` da duração legível ou do relógio próprio) e chama `feito(true)`. Esgotadas as tentativas, `feito(false)` e os textos ficam como estavam. |
| `M.cancelarCaptura()` | aborta a captura (voltou ao combate) |
| `M.mostrarResumo()` | escreve nos campos o resumo guardado (ou `cfg.vazio` em cada campo, se não há resumo) |
| `M.temLinha()` | booleano: a linha do jogador apareceu alguma vez nesta luta |

### 3.6 `Ameaca.lua` (publica `ns.ameaca`, aqui `A`)

| Função | O que faz |
|---|---|
| `A.papel()` | `"dps"` ou `"tanque"`: `cfg.papel[nome]`, senão `cfg.papelClasse[classe]`, senão `cfg.papelPadrao` |
| `A.aoEntrar(agora)`, `A.aoSair()` | começo e fim de luta (zera histerese, "teve pet", último pulso) |
| `A.aoAlvo(agora)` | `PLAYER_TARGET_CHANGED`: marca a hora (o pulso fica mudo por `cfg.threat.pulsoAposAlvoSeg`) |
| `A.aoGrupo()` | `GROUP_ROSTER_UPDATE` e `UNIT_PET`: refaz a lista de unidades que existem |
| `A.atualizar(agora)` | devolve a visão do threat (abaixo). Não toca em widget. |

Visão devolvida por `A.atualizar`:

```
{
  visivel = booleano,
  papel = "dps" | "tanque",
  estado = "SAFE" | "CLOSE" | "HIGH" | "ON_YOU" | "HELD" | "SLIPPING" | "LOOSE" | "LOST" | "NEUTRO",
  palavra = <texto legivel a mostrar na linha 1: cfg.threat.palavras[estado], ou cfg.vazio>,
  linha2 = { modo = "pct" | "texto" | "nada", caixa = <caixa da porcentagem>, texto = <texto legivel do addon> },
  barra = <caixa da porcentagem> ou nil,
  onYou = <caixa de isTanking> ou nil,   -- so no estado NEUTRO, para S.mostrarSe
  pulso = booleano,
}
```

O `estado` decide só cor e forma; a `palavra` já vem pronta. `linha2.modo`: `"pct"` manda a `caixa` para `S.mostrarPct`; `"texto"` escreve `texto` (texto legível montado pelo addon, por exemplo `other` ou `Voidwal 91%`); `"nada"` limpa a linha.

As regras de cada estado estão na seção 6.

### 3.7 `Painel.lua` (publica `ns.painel`, aqui `P`)

| Função | O que faz |
|---|---|
| `P.criar()` | cria tudo, uma vez, fora de combate; idempotente. Devolve `true` se o painel existe. |
| `P.campo(nome)` | o FontString de `"dps"`, `"luta"`, `"total"` ou `"tempo"` (para os ralos) |
| `P.texto(nome, texto)` | `SetText` de um texto legível do próprio addon num campo |
| `P.modo(m, seg)` | `"oculto"`, `"combate"`, `"pos"`, `"resumo"` ou `"amostra"` (seção 5.3); `seg` é a duração do fade |
| `P.threat(visao)` | aplica a visão do threat: palavra, cor, moldura, linha 2, régua, pulso. Os valores vão por `S.mostrarPct`, `S.mostrarBarra` e `S.mostrarSe`. |
| `P.threatOculto(seg)` | esconde o cartão de threat com fade |
| `P.existe()` | booleano |
| `P.arquivoFonte()` | o caminho do arquivo de fonte que funcionou (para o `Diario.lua` medir com a mesma fonte); `nil` antes de `P.criar()` |

### 3.8 `Convivencia.lua` (publica `ns.convivencia`, aqui `C`)

| Função | O que faz |
|---|---|
| `C.aplicar()` | fora de combate (em combate, fica pendente e o `Estados` chama de novo ao sair). Quer esconder a janela nativa quando `cfg.ligado`, `cfg.janelaNativa == "esconder"` e o dono não pediu para vê-la (`dbPersonagem().nativaVisivel` falso). Nesse caso: se `dbPersonagem().cvarAntes` é `nil`, guarda o valor atual de `damageMeterEnabled`; se o valor atual não é `"0"`, grava `"0"`. No caso contrário: se há `cvarAntes`, devolve esse valor e apaga o campo. |
| `C.alternar()` | `/central meter`: inverte `nativaVisivel` e chama `C.aplicar()` |
| `C.aoFimDeLuta(teveLinha, dur)` | Só age com o CVar em `"0"` e a janela escondida pelo addon. Se a linha do jogador apareceu (`teveLinha`), marca `dbPersonagem().coletaSemJanela = true` e zera `semLinha`: está provado que o motor coleta sem a janela, e a reserva nunca mais roda nesse personagem. Reserva (`cfg.reservaCVar`, só quando o addon é quem pôs o CVar em 0, isto é, `cvarAntes` diferente de `"0"`): cada luta de pelo menos `cfg.reservaDurMin` segundos (padrão 10) sem a linha soma 1 em `semLinha`; ao chegar a `cfg.reservaLutas` (padrão 3) seguidas, marca `reservaFeita = true`, põe `nativaVisivel = true`, chama `C.aplicar()`, registra no diário (`reserva`) e avisa uma vez no chat. Uma luta sem dano sozinha (puxar e fingir de morto) não dispara nada (emenda do portão da onda 2). |

Leitura do CVar por `C_CVar.GetCVar("damageMeterEnabled")` em `pcall`. Escrita só por `C_CVar.SetCVar("damageMeterEnabled", valor)`, com o nome literal.

### 3.9 `Estados.lua` (publica `ns.estados`)

Dono dos eventos, do tique e do `/central` (seções 8 e 9).

## 4. O que se pode fazer com um valor possivelmente secreto

Conferido em `api-forever\doc\` em 2026-11-16 (marca `SecretArguments = "AllowedWhenTainted"` = aceita segredo vindo de addon):

| Aceita | Recusa ou devolve segredo depois |
|---|---|
| `FontString:SetText`, `SetFormattedText`, `SetTextColor` | `SetShown`, `SetWidth`, `SetHeight`, `SetSize`, `SetPoint`, `SetScale`, `SetFrameLevel` |
| `StatusBar:SetValue`, `SetMinMaxValues`, `SetStatusBarColor` | `GetThreatStatusColor` |
| `Region:SetAlpha`, `SetVertexColor`, `SetAlphaFromBoolean`, `SetVertexColorFromBoolean` | `GetText`, `GetValue`, `GetAlpha` no objeto que recebeu segredo |
| `AbbreviateNumbers`, `AbbreviateLargeNumbers`, `BreakUpLargeNumbers` | os argumentos das próprias funções de `C_DamageMeter` e de threat |
| `C_StringUtil.RoundToNearestString`, `FloorToNearestString`, `WrapString`, `TruncateWhenZero` | `math.*`, aritmética, comparação, `..`, chave de tabela |

Quando cada dado vem secreto, pela documentação (a confirmar no jogo pelo diário):

| Dado | Marca | Leitura esperada |
|---|---|---|
| `GetCombatSessionFromType` (inteira) | `SecretWhenInCombat` | secreta com a restrição de combate ativa; `isLocalPlayer`, `classFilename` nunca secretos |
| `GetSessionDurationSeconds` | sem marca | legível |
| `UnitThreatSituation`, `UnitThreatLeadSituation` | `SecretWhenUnitThreatStateRestricted` | legíveis para jogador, pet ou aliado contra o alvo, inclusive chefe |
| `UnitDetailedThreatSituation` (inteira), `UnitThreatPercentageOfLead` | `SecretWhenUnitThreatValuesRestricted` | legíveis só contra alvo que não é chefe |
| `UnitName` | `SecretWhenUnitNameIdentityRestricted` | legível para jogador, grupo e pets do grupo |

## 5. Painel

### 5.1 Geometria (unidades da UI; todas as medidas vêm de `ns.cfg`)

```
   threat (132x76)       dano (270x76)
+-----------+ +---------------------------+
|   CLOSE   | |            45.6K  FIGHT   |
|    87%    | |    412     1.24M  TOTAL   |
| ======:-- | |    DPS      1:23          |
+-----------+ +---------------------------+
```

- Contêiner `CentralForeverPainel`: `CreateFrame("Frame", "CentralForeverPainel", UIParent)`, tamanho `cfg.largura` x `cfg.altura`, ponto `cfg.ponto`, strata `cfg.strata`, nível `cfg.nivel`, `EnableMouse(false)`. Nunca filho do `RightChatPanel`.
- Cartão de dano: à direita do contêiner, `cfg.cartaoDano.largura` de largura, altura cheia. Cartão de threat: à esquerda, `cfg.cartaoThreat.largura`, com `cfg.vao` entre os dois.
- Cada cartão é um Frame com: textura de fundo (`cores.fundo`), quatro texturas de borda (preta, `borda.fina`), e os textos.
- Cartão de dano, por dentro (margem 8): à esquerda, o DPS (fonte `tamanhos.dps`, caixa `caixas.dps`, `JustifyH("RIGHT")`), com o rótulo `rotulos.dps` embaixo, alinhado à direita da mesma caixa. À direita, três linhas de valores alinhados à direita numa coluna comum (caixa `caixas.valor`), com o rótulo de cada um logo à direita do próprio valor, numa caixa `caixas.rotulo` que termina a 8 da borda do cartão: FIGHT (valor `tamanhos.luta`; rótulo `rotulos.luta`), TOTAL (valor `tamanhos.total`; rótulo `rotulos.total`) e o tempo (`tamanhos.tempo`, sem rótulo). O rótulo fica colado no número dele e nunca no DPS (emenda da prévia de 2026-11-16: com o rótulo à esquerda, FIGHT e TOTAL ficavam encostados no DPS e longe dos próprios valores). Medidas vigentes: contêiner 406 x 76, cartão de dano 270, caixas `dps` 116 e `valor` 76.
- Cartão de threat, por dentro: palavra (fonte `tamanhos.palavra`, caixa `caixas.threat`, centro), linha 2 (`tamanhos.linha2`, centro), régua embaixo (StatusBar `regua.largura` x `regua.altura`, `SetMinMaxValues(0, cfg.threat.escala)` com números literais do Config, trilho `cores.trilho`, uma marca vertical em `regua.marca`). Mais: quatro texturas de moldura colorida (largura mudada só fora de combate; em combate troca-se a cor e mostram-se ou escondem-se conjuntos já criados para as espessuras 2 e 3), uma textura de preenchimento cheio, uma textura de pulso com `AnimationGroup` (alfa 0 para `cores.pulso` e de volta, em `threat.pulsoSeg`), e um texto filho `ON YOU` separado só para `S.mostrarSe`.
- Todo texto: fonte `cfg.fonte` (ordem de tentativa: LibSharedMedia `Fetch("font", nome, true)`, depois `cfg.fonte.arquivo`, depois `STANDARD_TEXT_FONT`), contorno `cfg.fonte.contorno`, sem sombra, `SetWordWrap(false)`, largura fixa. O padrão de carga está em `..\GuiaForever\Visual.lua:125-175`.

### 5.2 O que nunca acontece

Nenhum texto é medido. Nenhuma largura muda com o valor. Nenhuma cor depende de valor secreto. O cartão de dano não muda de lugar quando o de threat some.

### 5.3 Modos (`P.modo`)

| Modo | Cartão de dano | Cartão de threat | Alfa do contêiner |
|---|---|---|---|
| `oculto` | escondido | escondido | 0 |
| `combate` | visível, com fundo e borda | conforme `P.threat` | 1 (fade de `entrada.fadeSeg`) |
| `pos` | visível, com fundo e borda, números parados | escondido | 1 |
| `resumo` | só os textos (fundo e borda escondidos, se `resumo.fundo` é falso) | escondido | `resumo.alfa` (fade de `resumo.fadeSeg`) |
| `amostra` | como `combate`, com números de exemplo postos por `P.texto` | estado `CLOSE` de exemplo | 1 |

O alfa é sempre o comandado pelo addon (variável local), animado por `AnimationGroup` de alfa com valores literais ou por um `OnUpdate` próprio que só roda durante o fade. Nunca `GetAlpha`.

## 6. Threat

Papel: `A.papel()`. O caçador é `dps`: a porcentagem dele já é medida contra quem segura o alvo (o pet).

Leituras, todas por `Segredo.lua`, com `"target"` como mob:

- estado no alvo: `S.estado("player", "target")` (0 não é o alvo e está abaixo; 1 não é o alvo e está acima de quem é; 2 é o alvo sem folga; 3 é o alvo com folga);
- porcentagem e `isTanking`: `S.detalhe("player", "target")`;
- estado geral: `S.estado("player", nil)` e, no tanque, `S.estado(unidade, nil)` de cada unidade de `cfg.threat.unidades` que existe;
- desafiantes (tanque): `S.detalhe(unidade, "target")` de cada unidade que existe;
- folga (tanque, com a porcentagem secreta): `S.lider("player", "target")`.

Quando o cartão aparece (`visivel`): em combate, e o jogador está em grupo (`IsInGroup()`) ou tem pet (`UnitExists("pet")`) ou teve pet nesta luta. Solo sem pet: nunca. Além disso é preciso ter o que dizer: alvo hostil vivo (`UnitExists("target")`, `UnitCanAttack("player", "target")`, não `UnitIsDeadOrGhost("target")`), ou o estado geral legível em 2 ou 3 (dps), ou um aliado com estado geral legível em 2 ou 3 (tanque). Sem nada a dizer por `cfg.threat.semAlvoSeg`, `visivel` vira falso (o Painel esconde com `cfg.threat.fadeSeg`).

Estados do modo dps, em ordem de prioridade:

| Estado | Condição (só com `n` legível) | Linha 2 | Visual |
|---|---|---|---|
| `ON_YOU` | estado no alvo 2 ou 3 | porcentagem | cartão cheio `cores.cheio`, texto `cores.branco` |
| `ON_YOU` | estado no alvo 0 ou 1 (ou sem alvo hostil) e estado geral 2 ou 3 | texto `cfg.threat.outro` | idem |
| `HIGH` | estado no alvo 1, ou porcentagem a partir de `alto.entra` (sai abaixo de `alto.sai`) | porcentagem | contorno 3 `cores.vermelhao`, texto `cores.vermelhaoTexto` |
| `CLOSE` | porcentagem a partir de `perto.entra` (sai abaixo de `perto.sai`) | porcentagem | contorno 2 `cores.ambar`, texto `cores.ambar` |
| `SAFE` | o resto, inclusive alvo sem entrada na tabela de threat (linha 2 `cfg.vazio`) | porcentagem | sem moldura, texto `cores.neutro` |

Estados do modo tanque, em ordem de prioridade:

| Estado | Condição (só com `n` legível) | Linha 2 | Visual |
|---|---|---|---|
| `LOST` | estado no alvo 0 ou 1 | nome de quem, na varredura, tem `tanque.n == true`; senão nada | cartão cheio `cores.cheio`, texto `cores.branco` |
| `LOOSE` | uma unidade da varredura com estado geral 2 ou 3 | nome dela | contorno 3 `cores.vermelhao`, texto `cores.vermelhaoTexto` |
| `SLIPPING` | estado no alvo 2; ou o maior desafiante legível a partir de `desafiante.entra` (sai abaixo de `desafiante.sai`); ou, sem porcentagem legível e com `usarLider`, `S.lider` legível a partir de `liderSlipping` | nome e porcentagem do desafiante, quando houver | contorno 2 `cores.ambar`, texto `cores.ambar` |
| `HELD` | estado no alvo 3, sem as condições acima | nome e porcentagem do maior desafiante, quando houver; senão nada | sem moldura, texto `cores.azul` |

Alvo hostil sem entrada na tabela de threat, no tanque: `estado = "SAFE"` (sem moldura, texto `cores.neutro`), `palavra = cfg.vazio`, `linha2.modo = "nada"`.

O "maior desafiante" só é escolhido quando todas as porcentagens lidas são legíveis (comparar exige `n`). Nome: `S.nome(unidade)`; se legível, corta em `cfg.threat.nomeMax` caracteres e junta a porcentagem arredondada como texto do addon (`linha2.modo = "texto"`, por exemplo `Voidwal 91%`). Se o nome não é legível, mostra só a porcentagem (`linha2.modo = "pct"`).

Degradação:

| Caso | O que mostra |
|---|---|
| estado legível, porcentagem secreta | palavra e cor pelo estado (dps: 0 `SAFE`, 1 `HIGH`, 2 e 3 `ON_YOU`; tanque: 3 `HELD` ou `SLIPPING` pelo líder, 2 `SLIPPING`, 0 e 1 `LOST`). `CLOSE` não existe. Linha 2 e régua exibidas pelo valor cru (`linha2.modo = "pct"`, `barra` com a caixa), cor neutra. |
| estado também secreto | `estado = "NEUTRO"`: cor neutra, sem moldura; linha 2 e régua pelo valor cru; `onYou` com a caixa de `isTanking`. Com `onYou` presente, o Painel esvazia a palavra principal e entrega a caixa a dois textos filhos no lugar dela: `ON YOU` por `S.mostrarSe(filho, caixa, false)` e `palavras.NEUTRO` por `S.mostrarSe(filho, caixa, true)`. Assim aparece um ou outro, sem o addon ler o booleano. |
| nada veio da API | como alvo sem entrada |

Histerese e ritmo: piorar é imediato; melhorar (voltar para um estado de prioridade menor) só depois de `cfg.threat.melhoraSeg` com a condição nova estável. A troca de alvo (`A.aoAlvo`) zera a histerese: o estado do alvo antigo não vale para o novo, que aparece na leitura seguinte, sem espera e sem pulso.

No tanque, se alguma porcentagem de desafiante vier secreta, não se sabe quem é o maior: a linha 2 e a régua ficam vazias (não se mostra a porcentagem de uma unidade qualquer).

Pulso: `pulso = true` na chamada em que o estado entra em `HIGH`, `ON_YOU`, `SLIPPING`, `LOOSE` ou `LOST` vindo de um estado de prioridade menor, desde que a decisão tenha vindo de valor legível, que tenham passado `cfg.threat.pulsoAposAlvoSeg` desde a última troca de alvo e `cfg.threat.pulsoMinSeg` desde o último pulso.

## 7. Dano

| Campo | Origem | Ralo |
|---|---|---|
| DPS | `S.sessao(Current).dps` | `S.mostrarNumero(P.campo("dps"), caixa, cfg.formato.dps)` |
| FIGHT | `S.sessao(Current).total` | `S.mostrarNumero(P.campo("luta"), caixa, cfg.formato.luta)` |
| TOTAL | `S.sessao(Overall).total` | `S.mostrarNumero(P.campo("total"), caixa, cfg.formato.total)` |
| tempo | `S.duracao(Current)` legível, ou relógio próprio | texto `m:ss` do addon, por `P.texto("tempo", ...)` |

"Com dados" quer dizer: a sessão tem a linha do jogador (`linha == true`). Não se testa valor.

Sem cor por valor. Sem contas em combate. O resumo (valores legíveis, depois do combate) fica em `ns.dbPersonagem().ultima` e é o que aparece fora de combate, no modo `resumo`.

TOTAL é o acumulado do medidor da Blizzard: zera quando o medidor zera (`/central reset`, ou sozinho ao entrar numa instância nova nos personagens com o CVar `damageMeterResetOnNewInstance` ligado).

## 8. Estados, eventos e cadência (`Estados.lua`)

Lista fechada de eventos, todos registrados por `ns.ao` em `Estados.lua` (o `Nucleo.lua` registra só `ADDON_LOADED`):

`PLAYER_ENTERING_WORLD`, `PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED`, `ADDON_RESTRICTION_STATE_CHANGED`, `DAMAGE_METER_COMBAT_SESSION_UPDATED`, `DAMAGE_METER_CURRENT_SESSION_UPDATED`, `DAMAGE_METER_RESET`, `UNIT_THREAT_LIST_UPDATE`, `UNIT_THREAT_SITUATION_UPDATE`, `PLAYER_TARGET_CHANGED`, `GROUP_ROSTER_UPDATE`, `UNIT_PET`, `PLAYER_LEVEL_UP`, `ADDON_ACTION_BLOCKED`.

| Estado | Painel | Entra por |
|---|---|---|
| `OCIOSO` | `oculto` | carga sem resumo; fim da amostra de login sem resumo |
| `EM_COMBATE` | `combate`, tique ligado | `PLAYER_REGEN_DISABLED`; `ADDON_RESTRICTION_STATE_CHANGED` com tipo Combat e estado Activating ou Active; carga com `InCombatLockdown()` verdadeiro |
| `SAINDO` | `pos`, threat escondido, tique desligado, captura do resumo rodando | `PLAYER_REGEN_ENABLED`; `ADDON_RESTRICTION_STATE_CHANGED` com tipo Combat e estado Inactive |
| `RESUMO` | `resumo` | `cfg.resumo.acesoSeg` depois de a captura terminar (com ou sem sucesso); fim da amostra de login com resumo |

Regras:

- `entrar()` e `sair()` são idempotentes: chamadas repetidas no mesmo estado não fazem nada. Os dois gatilhos de cada uma podem chegar em qualquer ordem.
- `ADDON_RESTRICTION_STATE_CHANGED(tipo, estado)`: só o tipo `ns.enum.restricao.Combat` move a máquina. Os outros tipos viram entrada avulsa `restricao` no diário, uma por mudança.
- Voltar ao combate durante `SAINDO` ou durante os `acesoSeg`: `M.cancelarCaptura()` e `entrar()`, sem passar pelo resumo.
- Com `cfg.ligado` falso: o painel nunca é criado, nenhum evento além de `PLAYER_ENTERING_WORLD` é tratado, e `C.aplicar()` devolve o CVar.
- Indisponível: se `S.disponivel()` devolve falso, o cartão de dano mostra `cfg.vazio` nos campos e o diário guarda o motivo; o threat segue.

`PLAYER_ENTERING_WORLD`: `P.criar()`, `C.aplicar()` e, 2 s depois e fora de combate, `D.carga()`. Se já está em combate, `entrar()`. Senão, amostra de login: `M.mostrarResumo()`, `P.modo("pos")` e, depois de `cfg.login.mostrarSeg`, `RESUMO` (se há resumo guardado) ou `OCIOSO`.

Eventos que só marcam "sujo" (o tique é quem lê): `DAMAGE_METER_COMBAT_SESSION_UPDATED` marca o dano; `UNIT_THREAT_LIST_UPDATE` e `UNIT_THREAT_SITUATION_UPDATE` marcam o threat, mas só se a unidade do evento é `player`, `pet`, `target` ou uma de `cfg.threat.unidades`; `PLAYER_TARGET_CHANGED` chama `A.aoAlvo` e marca o threat. `GROUP_ROSTER_UPDATE` e `UNIT_PET` chamam `A.aoGrupo`. `DAMAGE_METER_CURRENT_SESSION_UPDATED` marca o dano e vai para o diário: em luta, como contador `novasSessoes` do registro da luta; fora dela, como entrada avulsa `nova_sessao`. `DAMAGE_METER_RESET` marca o dano e vira entrada avulsa `reset`. `ADDON_ACTION_BLOCKED(addon, funcao)`: entrada avulsa `bloqueio` só quando o primeiro argumento é `"CentralForever"`.

Tique: `ns.tique(cfg.cadencia.tique, ...)`, criado em `entrar()` e cancelado em `sair()`. A cada tique: threat se está sujo ou se passaram `cadencia.threat` segundos desde a última leitura; dano se está sujo e passaram `cadencia.dano` segundos, ou se passou 1 s; tempo se o segundo mudou. Nenhum campo é escrito mais de 4 vezes por segundo.

## 9. Comando `/central` (`Estados.lua`)

`SLASH_CENTRALFOREVER1 = "/central"` e `SlashCmdList["CENTRALFOREVER"]`. Todas as respostas em inglês, por `ns.msg`.

| Argumento | O que faz |
|---|---|
| vazio | estado atual, papel, se o medidor está disponível, valor do CVar, quantas lutas no diário |
| `test` (aceita `teste`) | fora de combate: `P.modo("amostra")` por `cfg.amostra.seg` e volta ao estado anterior |
| `meter` | `C.alternar()` |
| `reset` | fora de combate: `S.zerar()` |

## 10. SavedVariables (`CentralForeverDB`)

```
CentralForeverDB = {
  v = 1,
  log = { "2026-11-16 21:03:11 texto", ... },
  personagens = {
    ["Nome-Reino"] = {
      classe = "HUNTER",
      ultima = { dps = 412, luta = 45600, total = 1240000, dur = 83, quando = "2026-11-16 21:10:02" },
      cvarAntes = "1",          -- so enquanto o addon mantem o CVar em 0
      nativaVisivel = false,
      coletaSemJanela = true,   -- a linha do jogador ja apareceu com o CVar em 0
      semLinha = 0,             -- lutas seguidas (longas) sem a linha, com o CVar em 0
      reservaFeita = false,
    },
  },
  diario = {
    v = 1,
    carga = {
      ["Nome-Reino"] = {
        quando = "...", versao = "0.1.0",
        build = { versao = "1.60.1", numero = "70938", interface = 16001 },
        nome = "o que UnitName devolveu", classe = "HUNTER", papel = "dps",
        disponivel = true, motivo = nil,
        cvar = { damageMeterEnabled = "0", damageMeterResetOnNewInstance = "1" },
        tem = { issecretvalue = true, canaccesstable = true, medidor = true, arredondar = true, embrulhar = true, abreviar = true, alfaBooleano = true, restricoes = true },
        formatos = { { n = 0, inteiro = "0", abrev = "0", grande = "0" }, ... },   -- para 0, 7, 99, 999, 1000, 1234, 9999, 12345, 123456, 999999, 1234567
        larguras = { dps = 111.2, luta = 61.0, total = 49.5, tempo = 40.1, palavra = 104.8 },   -- GetStringWidth do pior caso de cada campo
      },
    },
    lutas = {   -- anel de cfg.sondas.maxLutas
      {
        quando = "...", pers = "Nome-Reino", zona = "Darkshore", instancia = false, chefe = false, papel = "dps",
        dur = 83,
        dano = { sessao = "ok" | "inacessivel" | "falhou", linha = true, dps = "secreto", total = "secreto", geral = "secreto", duracao = "legivel" },
        ameaca = { estado = "legivel", pct = "legivel", tanque = "legivel", geral = "legivel", lider = "nada", veio = true, soloSemPet = false },
        resumo = { ok = true, tentativas = 1, fonte = "current" | "expired" | "nenhuma" },
        eventosDano = 41, eventosAmeaca = 60, pulsos = 1, fontes = 1, novasSessoes = 0,
      },
    },
    avulsas = {   -- anel de cfg.sondas.maxEntradas
      { quando = "...", pers = "...", tipo = "restricao" | "reset" | "nova_sessao" | "bloqueio" | "desligado" | "reserva" | "erro", ... },
    },
  },
}
```

Nunca entra valor secreto: só `S.tipo(caixa)`, booleanos, números legíveis e textos do addon.

## 11. Ferramentas (em `modder\ferramentas\guia\`)

### 11.1 `conferir-doc.mjs` (B1)

Lê `api-forever\doc\*.lua` e confere âncoras por expressão regular sobre o bloco de cada função (do `Name = "X"` até o próximo `Name = ` de função). Imprime `ok` ou `FALHA` por âncora e sai 1 se alguma falhar. Âncoras:

| Arquivo | Função ou campo | Tem de ter | Não pode ter |
|---|---|---|---|
| `DamageMeterDocumentation.lua` | `GetCombatSessionFromType` | `SecretWhenInCombat = true` | |
| idem | `GetCombatSessionFromID` | `SecretWhenInCombat = true` | |
| idem | `GetSessionDurationSeconds` | | `SecretWhen` |
| idem | `IsDamageMeterAvailable`, `ResetAllCombatSessions` | | `SecretWhen` |
| idem | campo `isLocalPlayer` | `NeverSecret = true` | |
| idem | campos `totalAmount`, `amountPerSecond` de `DamageMeterCombatSource` | | `NeverSecret` |
| `UnitDocumentation.lua` | `UnitDetailedThreatSituation` | `SecretWhenUnitThreatValuesRestricted = true`, `MayReturnNothing = true` | |
| idem | `UnitThreatSituation` | `SecretWhenUnitThreatStateRestricted = true` | `ValuesRestricted` |
| idem | `UnitThreatLeadSituation` | `SecretWhenUnitThreatStateRestricted = true` | |
| idem | `UnitThreatPercentageOfLead` | `SecretWhenUnitThreatValuesRestricted = true` | |
| idem | `UnitExists`, `UnitCanAttack`, `UnitAffectingCombat`, `UnitIsDeadOrGhost` | | `SecretWhen` |
| `ThreatDocumentation.lua` | `GetThreatStatusColor` | `SecretArguments = "AllowedWhenUntainted"` | |
| `SimpleFontStringAPIDocumentation.lua` | `SetText`, `SetFormattedText` | `SecretArguments = "AllowedWhenTainted"` | |
| `SimpleStatusBarAPIDocumentation.lua` | `SetValue`, `SetMinMaxValues`, `SetStatusBarColor` | `SecretArguments = "AllowedWhenTainted"` | |
| `SimpleRegionAPIDocumentation.lua` | `SetAlphaFromBoolean`, `SetVertexColorFromBoolean` | `SecretArguments = "AllowedWhenTainted"` | |
| `SimpleScriptRegionAPIDocumentation.lua` | `SetShown` | `SecretArguments = "AllowedWhenUntainted"` | |
| `LocalizationDocumentation.lua` | `AbbreviateNumbers`, `AbbreviateLargeNumbers` | `SecretArguments = "AllowedWhenTainted"` | |
| `StringUtilDocumentation.lua` | `RoundToNearestString`, `WrapString` | `SecretArguments = "AllowedWhenTainted"` | |
| `RestrictedActionsDocumentation.lua` | evento `ADDON_RESTRICTION_STATE_CHANGED` | payload `type` e `state`, nessa ordem | |

### 11.2 Simulador de valor secreto (B2)

`bancada\segredo.lua` (roda no fengari, Lua 5.3) e `bancada\instrumentar.mjs`; testes em `rodar-casos-segredo.mjs`, com os casos em `casos-segredo\`.

- O valor secreto é uma tabela vazia com metatabela travada; o valor real fica numa tabela fraca do simulador. Construtores: `segredo.numero(v)`, `segredo.texto(v)`, `segredo.bool(v)`, `segredo.tabela(t)`.
- Metamétodos que dão erro `"bancada: <operacao> com valor secreto"`: aritmética (`__add`, `__sub`, `__mul`, `__div`, `__mod`, `__pow`, `__unm`, `__idiv`), `__lt`, `__le`, `__concat`, `__len`, `__index`, `__newindex`, `__call`.
- Globais trocadas por versões que reconhecem o segredo: `type` (devolve o tipo do valor real), `tostring`, `string.format` e `format` (erro com segredo), `rawequal`, `rawget`, `next`, `pairs`, `ipairs` (erro em tabela secreta), `math.*` (erro), `tonumber` (erro).
- `issecretvalue(v)`, `issecrettable(t)`, `canaccessvalue(v)`, `canaccesstable(t)`, `scrubsecretvalues(...)`.
- O que metatabela não pega, a reescrita pega. `instrumentar.mjs` recebe o texto de um `.lua`, usa o `luaparse` (com `ranges`) e devolve o texto com: condição de `if`, `elseif`, `while` e `repeat ... until`, operando de `not` e lado esquerdo de `and` e `or` embrulhados em `__B(x)`; `a == b` e `a ~= b` trocados por `__EQ(a, b)` e `not __EQ(a, b)`; índice não literal `t[k]` trocado por `t[__K(k)]`. Cada uma devolve o próprio argumento e dá erro se receber segredo. A reescrita não cria quebra de linha (o erro aponta a linha original).
- Ralos simulados: aceitam segredo e marcam `recebeuSegredo` (guardando o valor real, para a prévia) os da coluna "Aceita" da seção 4; dão erro `"bancada: <metodo> recusou segredo"` os da coluna "Recusa". Depois de receber segredo, `GetText`, `GetValue`, `GetAlpha` e `GetStringWidth` do widget devolvem segredo.
- Casos (cerca de 40): cada operação proibida dá erro; cada ralo permitido passa; contágio; a linha do erro é a do arquivo original; `x = a or s` (lado direito) não dá erro; guardar segredo como valor de tabela e passar como argumento não dá erro.

### 11.3 Regras novas do `checar-combate.mjs` (B3)

Para todo addon:

- R2 passa a cobrir as funções da seção 2 (menos `ResetAllCombatSessions`, que vai para o R9).
- R9 ganha `C_DamageMeter.ResetAllCombatSessions`.
- Corrigir `chaveOrd` (faltam as barras invertidas em `\S` e `\d`).
- A leitura de argumentos pula também o valor de `--perfil`.

Com `--perfil central` (só para este addon):

| Regra | Cobra |
|---|---|
| prefixos | acrescenta `CentralForever` e `SLASH_CENTRALFOREVER` aos prefixos do R4 |
| R10 | qualquer menção (chamada, referência, argumento de `pcall`) a uma função da seção 2 fora de `Segredo.lua` é ERRO. Dentro de `Segredo.lua`, o R2 e o R9 não disparam para elas. |
| R11 | acesso ao campo `.cru` (ou `["cru"]`) fora de `Segredo.lua` é ERRO |
| R12 | chamada de `GetText`, `GetValue`, `GetMinMaxValues`, `GetStringWidth`, `GetStringHeight`, `GetAlpha`, `GetEffectiveAlpha` (métodos) ou de `UIFrameFadeIn`, `UIFrameFadeOut`, `UIFrameFade` é ERRO; exceção: `GetStringWidth` em `Diario.lua` |
| R14 | método chamado com `:` tem de existir em `api-forever\WidgetAPI.lua`, ou ser método de texto do Lua (`format`, `gsub`, `sub`, `lower`, `upper`, `match`, `find`, `rep`, `len`, `byte`, `gmatch`, `reverse`), ou `Cancel`, `IsCancelled`, `Fetch`, ou método definido no próprio addon. Senão ERRO. |
| R15 | `SetCVar` e `C_CVar.SetCVar` só em `Convivencia.lua`, com a guarda do R1 e com o primeiro argumento literal `"damageMeterEnabled"`; fora disso ERRO |
| R16 | texto literal `"targettarget"` ou que comece com `"nameplate"` é ERRO |
| R17 | evento registrado (por `ns.ao`, `RegisterEvent` ou `RegisterUnitEvent`) fora da lista fechada da seção 8 (mais `ADDON_LOADED`) é ERRO |

Casos novos em `casos-combate\`, um por regra (um que falha e, onde fizer sentido, um que passa), mais `central-bom` (0 erro com tudo o que o contrato permite). O cabeçalho do checador e a linha de uso mencionam o perfil e a exceção 2. Regressão obrigatória: os 16 casos antigos, o GuiaForever (`--toc`) e o UIForever (`--toc`) continuam com 0 erro.

### 11.4 Bancada da central (B5 e T1)

`rodar-central.mjs [--addon <pasta>] [--cenario <id>] [--matriz]`, com o ambiente em `bancada\api-central.lua` e os cenários em `bancada\cenarios-central.lua`. Padrão de `--addon`: `..\..\addons-proprios\CentralForever`. Carrega os `.lua` na ordem do `.toc`, cada um passado pelo `instrumentar.mjs`, com os varargs `("CentralForever", ns)`, num estado Lua novo por cenário.

API simulada: `C_DamageMeter` (sessões Current, Overall e Expired; linha do jogador e, opcionalmente, do pet; eventos), as quatro funções de threat por par de unidades, `UnitExists`, `UnitCanAttack`, `UnitIsDeadOrGhost`, `UnitAffectingCombat`, `UnitName`, `UnitClass`, `IsInGroup`, `InCombatLockdown`, `C_RestrictedActions`, `C_CVar`, `C_Timer` (com `NewTicker` de verdade e relógio simulado), `GetTime`, `CreateFrame` com widgets estritos (método que não está em `WidgetAPI.lua` dá erro), os formatadores, `issecretvalue` e vizinhos, `LibStub` ausente por padrão, `print`.

Passos de cenário: `alvo{...}`, `semAlvo()`, `entrarCombate()`, `dano{jogador = n, pet = n}`, `ameaca{unidade = {estado, pct, tanque}}`, `sairCombate{atrasoRestricao = s}`, `restricao{tipo, estado}`, `morrer()`, `petMorre()`, `recarregar()`, `comando(texto)`, `avancar(seg)`.

Chaves da matriz (o padrão é o pessimista; `--matriz` roda todos os cenários com cada chave trocada, uma por vez):

| Chave | Valores | Padrão |
|---|---|---|
| U1 | `string.format`, `..`, `tostring` com segredo: erro ou aceita | erro |
| U2 | sessão em combate: campos secretos, ou a tabela `combatSources` inacessível | campos |
| U3 | `GetSessionDurationSeconds` em combate: legível ou secreta | secreta |
| U4 | estado de threat: legível ou secreto | legível |
| U5 | porcentagem de threat fora de chefe: legível ou secreta | secreta |
| U6 | solo sem pet: a API de threat não devolve nada, ou devolve valores | nada |
| U7 | pet: na linha do dono, ou linha própria | linha do dono |
| U8 | atraso para a restrição sair: 0, 0,6 ou 5 s | 0,6 |
| U9 | CVar do medidor em 0: coleta, ou não coleta | coleta |
| U10 | `issecretvalue` existe (e há valores secretos), ou não existe (cliente sem valores secretos: a API devolve valores comuns e tudo é legível) | existe |

Invariantes de todo cenário (A0):

1. Nenhum erro capturado (pelo manipulador de erro, por `pcall` de ralo, ou erro `bancada:`).
2. Nenhum ralo que recusa recebeu segredo; nenhuma operação proibida com segredo.
3. Nenhum campo de texto escrito mais de 4 vezes por segundo simulado.
4. Depois de `ns.painel.criar()` devolver verdadeiro: zero `CreateFrame`, `CreateTexture`, `CreateFontString`, `CreateAnimationGroup`, `SetPoint`, `SetSize`, `SetWidth`, `SetHeight` em combate (o quadro de medição do `Diario.lua` só nasce fora de combate).
5. Zero `GetText`, `GetValue`, `GetAlpha` em qualquer widget; `GetStringWidth` só fora de combate.
6. `C_CVar.SetCVar` só com `damageMeterEnabled` e só fora de combate; nenhuma outra função protegida.
7. Nenhuma global nova além das permitidas (regra 2).
8. Nada de segredo no `CentralForeverDB` (varredura completa no fim).
9. Pulsos por luta: no máximo `1 + duracao / cfg.threat.pulsoMinSeg`.

Cenários (cada um afirma, além do A0, o que está na coluna):

| id | Cenário | Afirma |
|---|---|---|
| C01 | carga fora de combate, caçador com pet | painel criado uma vez no ponto do Config, pai `UIParent`; amostra de login por 4 s e depois `oculto` (sem resumo guardado); entrada `carga` no diário; CVar gravado em 0 e `cvarAntes` guardado |
| C02 | luta no mundo com tudo secreto (dano, DPS, porcentagem), estado legível | modo `combate`; DPS, FIGHT e TOTAL escritos só por ralo permitido, com `recebeuSegredo`; threat com palavra pelo estado; diário marca os campos como `secreto` |
| C03 | fim de luta com valores legíveis | até 1 s + 8 x 0,2 s depois de a restrição sair, `ultima` gravado com números; modo `pos` e, 3 s depois, `resumo`; threat escondido |
| C04 | chefe: detalhado todo secreto, `UnitThreatSituation` legível | palavra e cor pelo estado; nenhuma comparação com a porcentagem; régua e linha 2 por ralo |
| C05 | estado também secreto | estado `NEUTRO`; texto `ON YOU` filho recebeu `SetAlphaFromBoolean`; nenhuma decisão com o estado |
| C06 | sem alvo em combate | cartão de threat some depois de 2 s; dano continua |
| C07 | alvo amigo no meio da luta (paladino cura o parceiro) | nenhuma consulta de threat com mob amigo; cartão segue só pela consulta sem mob |
| C08 | solo sem pet | cartão de threat nunca aparece, nas duas variantes de U6 |
| C09 | caçador a 85% do pet | `CLOSE`; um pulso; nenhum outro enquanto fica acima |
| C10 | caçador puxa (estado 3) | `ON_YOU`, cartão cheio, um pulso |
| C11 | pet morre no meio da luta e o mob vem no caçador | cartão continua (teve pet nesta luta) e mostra `ON_YOU` |
| C12 | tanque segurando, `partypet1` a 92% | `SLIPPING`, linha 2 com nome e porcentagem do demônio |
| C13 | tanque perde o alvo para `party1` | `LOST`, linha 2 com o nome de `party1`, um pulso |
| C14 | tanque com mob solto em `party1` (estado geral 3), alvo do tanque seguro | `LOOSE`, linha 2 com o nome |
| C15 | tanque em chefe: porcentagens secretas, líder legível em 2 | `SLIPPING` pelo líder; linha 2 vazia e régua em 0 (nenhuma porcentagem de desafiante exibida) |
| C16 | troca de alvo a cada 1,5 s, alternando seguro e `ON_YOU` | palavra troca; zero pulso causado por troca de alvo |
| C17 | medidor indisponível (`IsDamageMeterAvailable` falso com motivo) | campos de dano em `--`; motivo no diário; threat funciona |
| C18 | API ausente (sem `C_DamageMeter`, sem `C_StringUtil`, sem `C_RestrictedActions`) | sem erro; reservas dos formatadores; diário anota o que falta |
| C19 | `/reload` em combate (carga com `InCombatLockdown` verdadeiro) | entra em `EM_COMBATE` sem evento; `C.aplicar` fica pendente e roda ao sair |
| C20 | restrição demora 5 s para sair | tentativas param em 8; `feito(false)`; nunca laço infinito; textos ficam |
| C21 | restrição de tipo Map e de tipo Chat ativando e desativando fora de combate | estado não muda; duas entradas avulsas `restricao` |
| C22 | Current vazia ao sair do combate, Expired com a luta | resumo vem de Expired (`fonte = "expired"`) |
| C23 | `combatSources` inacessível em combate (U2) | `sessao = "inacessivel"` no diário; campos em `--`; sem erro |
| C24 | rajada: 200 eventos por segundo de dano e de threat, com unidades de fora | escrita dentro do limite; unidades de fora não marcam sujo |
| C25 | pet como linha própria (U7) | só a linha do jogador é exibida; diário marca `fontes = 2` |
| C26 | três lutas seguidas de 12 s sem a linha do jogador, CVar em 0 posto pelo addon (U9 = não coleta) | depois da 1ª e da 2ª: nada muda (`semLinha` 1 e 2); depois da 3ª: reserva (CVar devolvido, `reservaFeita`, uma entrada `reserva`, um aviso no chat) |
| C27 | morte em combate e volta | sem erro; resumo sai |
| C28 | voltar ao combate durante `SAINDO` | captura cancelada; `EM_COMBATE` de novo; sem resumo parcial |
| C29 | `/central`, `/central test`, `/central meter`, `/central reset` fora de combate; `/central reset` em combate | respostas em inglês; `meter` alterna o CVar; `reset` em combate não chama a API |
| C30 | `cfg.ligado = false` | painel nunca criado; CVar devolvido |
| C31 | luta sem dano: uma luta curta (3 s) e uma longa (12 s) sem a linha do jogador, e depois uma luta normal | a reserva não dispara; CVar segue em 0; depois da luta normal `coletaSemJanela` é verdadeiro e `semLinha` volta a 0 |
| C32 | uma luta normal (com a linha) e depois três lutas de 12 s sem a linha | a reserva nunca dispara (`coletaSemJanela`); CVar segue em 0; nenhuma entrada `reserva` |
| C33 | caçador com dois mobs: alvo A em `ON_YOU`, troca para o alvo B seguro | na leitura seguinte à troca a palavra já é `SAFE` (sem a espera de `melhoraSeg`) e não há pulso |
| C34 | `DAMAGE_METER_CURRENT_SESSION_UPDATED` três vezes em luta e uma vez fora dela | o registro da luta tem `novasSessoes = 3`; há uma entrada avulsa `nova_sessao` |

Saídas: `visual\cache\central-<id>.json` (árvore de quadros de cada cenário no instante final e nos instantes marcados com `foto(nome)`: ponto, tamanho, strata, pai, alfa comandado, visibilidade, texto real de cada campo, cores) e `visual\cache\CentralForever-sv.lua` (o `CentralForeverDB` depois de C02 e C03, no formato de SavedVariables). Código de saída: 0 sem falha; 1 com falha; 2 se um arquivo não carregou.

Para provar a própria bancada: `casos-central\minimo\` (um addon de brinquedo que passa) e `casos-central\mutante-*\` (um por invariante: cada um quebra um invariante e a bancada tem de sair 1 apontando qual).

### 11.5 Prévia (B6) e leitor do diário (B7)

- `previa-central.mjs`: monta, a partir das fotos de `visual\cache\central-*.json`, um HTML em pixels reais (unidade x 1,3125) sobre `visual\png\canto-base.png` (recorte de 1000x600 px do canto inferior direito do print do dono) e fotografa pelo Edge sem tela, como o `visual\renderizar.mjs`. Estados: caçador `SAFE`, `CLOSE`, `ON_YOU`; tanque `HELD`, `SLIPPING` com nome, `LOST`; resumo fora de combate nas duas formas (só texto; com fundo); um tooltip alto no ponto novo. Duas fontes: Expressway e uma de largura fixa, se houver arquivo. Imprime `ESTOURO n` (texto do pior caso que não cabe na caixa) e `SOBREPOSICAO n` (painel contra os retângulos: datatexts x 4-476 y 4-27; barra 6 x 4-194 y 264-294; alvo a partir de 425 da borda, y 139-221; alvo-do-alvo e foco 455-725, y 60-114).
- `ler-diario-central.mjs --sv <arquivo> [--bug <BugGrabber.lua>] [--taint <taint.log>]`: carrega o SavedVariables no fengari e imprime um relatório por seção (carga, formatos, lutas por contexto com a contagem de `secreto`/`legivel`/`nada` de cada campo, avulsas, erros). Sai 0 se leu.

## 12. Assinaturas conferidas em `api-forever\doc\` (2026-11-16)

| Função | Retorno |
|---|---|
| `C_DamageMeter.GetCombatSessionFromType(sessionType, type)` | `{ combatSources = lista, maxAmount, totalAmount, durationSeconds? }`; cada fonte `{ sourceGUID?, name, classFilename, specIconID, totalAmount, amountPerSecond, isLocalPlayer, ... }` |
| `C_DamageMeter.GetSessionDurationSeconds(sessionType)` | número ou nil |
| `C_DamageMeter.IsDamageMeterAvailable()` | `isAvailable`, `failureReason` |
| `C_DamageMeter.ResetAllCombatSessions()` | nada |
| `UnitDetailedThreatSituation(unit, mobUnit)` | `isTanking`, `status`, `scaledPercentage`, `rawPercentage`, `rawThreat`; pode não devolver nada |
| `UnitThreatSituation(unit, mobUnit?)` | estado 0 a 3 ou nil |
| `UnitThreatLeadSituation(unit, mobUnit)` | 0 a 3 (0 nenhuma cor ... 3 vermelho; quem não é o primeiro recebe sempre 3); nil se o mob não existe |
| `C_RestrictedActions.IsAddOnRestrictionActive(type)` | booleano (sempre falso durante o despacho de `ADDON_RESTRICTION_STATE_CHANGED`) |
| evento `ADDON_RESTRICTION_STATE_CHANGED` | `type`, `state` |
| evento `DAMAGE_METER_COMBAT_SESSION_UPDATED` | `type`, `sessionID` (dois por atualização: o da Overall com `sessionID` 0 e o da sessão atual) |
| eventos `DAMAGE_METER_CURRENT_SESSION_UPDATED`, `DAMAGE_METER_RESET` | sem argumentos |
| eventos `UNIT_THREAT_LIST_UPDATE`, `UNIT_THREAT_SITUATION_UPDATE` | `unitTarget` |
| evento `ADDON_ACTION_BLOCKED` | nome do addon, nome da função |
| `C_StringUtil.RoundToNearestString(number)` | texto |
| `C_StringUtil.WrapString(infix, prefix?, suffix?)` | texto (vazio se `infix` é vazio) |
| `AbbreviateNumbers(number, options?)`, `AbbreviateLargeNumbers(number, options?)` | texto |
| `C_CVar.GetCVar(name)`, `C_CVar.SetCVar(name, value)` | texto ou nil; booleano |
| `Region:SetAlphaFromBoolean(value, alphaIfTrue, alphaIfFalse)` | os padrões da documentação são 255 e 0; passe sempre 1 e 0 |

## 13. Como ficou

Portão técnico da sessão principal em 2026-11-16 (madrugada). Nada rodou no jogo: o addon ainda não estava ligado ao cliente.

| Prova | Comando (a partir de `modder\ferramentas\guia`) | Resultado |
|---|---|---|
| sintaxe e ASCII | `node checar-lua.mjs ..\..\addons-proprios\CentralForever` | 9 arquivos ok |
| regras de combate e `.toc` | `node checar-combate.mjs ..\..\addons-proprios\CentralForever --toc --perfil central` | 0 erro, 0 aviso |
| bancada | `node rodar-central.mjs` | 34 cenários, 0 falha |
| matriz das incógnitas | `node rodar-central.mjs --matriz` | 408 execuções, 0 falha |
| a própria bancada | `node rodar-central.mjs --autoteste` | o addon de brinquedo passa e os 11 mutantes são acusados pelo invariante certo |
| casos dos checadores | `node rodar-casos-combate.mjs`, `node rodar-casos-segredo.mjs` | 29 e 44 casos como esperado |
| documentação da Blizzard | `node conferir-doc.mjs` | 30 de 30 âncoras |
| linha de base | checadores e `rodar-janela.mjs` do GuiaForever (caçador e paladino) e checadores do UIForever | iguais ao que eram antes da primeira edição |

Sabotagem feita pela sessão principal: 21 cópias do addon, cada uma com um defeito (vazar segredo como legível, comparar valor cru, ignorar o tipo da restrição, não usar a sessão Expired, pulsar na troca de alvo, reserva na primeira luta, entre outros). A bancada acusou as 21, cada uma no cenário esperado.

Emendas feitas nos portões, todas já no texto acima: sem `issecretvalue` tudo é legível (onda 1); o teste de segredo vem antes de `type` nas tabelas da API (onda 1); o painel é criado na carga mesmo em combate (onda 1); o estado `NEUTRO` usa dois textos filhos acesos pelo booleano (onda 1); a reserva do CVar pede três lutas longas seguidas sem a linha e nunca roda depois que a linha apareceu com o CVar em 0 (onda 2); a troca de alvo zera a histerese (onda 2); no tanque, porcentagem de desafiante secreta não é exibida (onda 2); `DAMAGE_METER_CURRENT_SESSION_UPDATED` em luta vira contador (onda 2).

Depois da prévia em imagem (`previa-central.mjs`), ainda em 2026-11-16: os rótulos FIGHT e TOTAL passaram para a direita dos valores e o cartão de dano foi a 270 (seção 5.1); o dono escolheu a fonte Expressway, o resumo só em texto com alfa 0,65 (`cfg.resumo.alfa`) e manteve os tamanhos; `S.estado` chama `UnitThreatSituation` com um argumento só quando não há mob. A matriz e os checadores foram rodados de novo sobre esse estado, com o mesmo resultado da tabela. O addon foi ligado ao jogo às 04h58 (`dev-link.ps1 -Aplicar`, com backup do WTF antes e auditoria limpa depois), junto com o UIForever 0.7.1.

O que nenhuma prova cobre: o comportamento real do cliente (o que vem secreto em cada contexto, o texto exato dos formatadores, se o motor coleta com o CVar em 0, a aparência no jogo). A bancada é Lua 5.3 com valor secreto simulado; o jogo é Lua 5.1. O diário do addon existe para fechar essa diferença depois da primeira sessão de jogo.
