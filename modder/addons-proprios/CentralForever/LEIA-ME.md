# CentralForever

## O que é

CentralForever é a central de combate do dono, na versão 0.1.0 (2026-11-16): uma faixa no canto inferior direito da tela com o DPS da luta, o dano da luta, o dano acumulado, o tempo e o threat. Só exibe; nada se configura no jogo, e tudo fica no `Config.lua`. Ainda não rodou no jogo: passou nos checadores e numa bancada fora do jogo, e falta o primeiro teste em luta.

## O que aparece

A central tem dois cartões. O da direita (270 unidades de largura) é o do dano. O da esquerda (132) é o do threat, e só aparece quando há o que mostrar (seção "Threat por papel"). Os dois ficam a 4 unidades da borda direita e 31 da inferior, acima da faixa de datatexts do ElvUI.

No cartão do dano, o DPS fica grande à esquerda, com o rótulo embaixo. À direita estão FIGHT, TOTAL e o tempo, com os valores alinhados à direita numa coluna e o rótulo de cada um logo à direita do próprio valor.

| Campo | Rótulo na tela | De onde vem | Formato |
|---|---|---|---|
| DPS | `DPS` | dano por segundo do jogador na luta atual (sessão Current do medidor da Blizzard) | inteiro |
| FIGHT | `FIGHT` | dano total do jogador na luta atual (sessão Current) | abreviado |
| TOTAL | `TOTAL` | dano acumulado do jogador (sessão Overall) | abreviado |
| tempo | sem rótulo | duração da luta: a do medidor da Blizzard, se ela vier legível; se não, o relógio do próprio addon | `m:ss` |

Ao começar uma luta nova, DPS e FIGHT vão a `0` e o tempo a `0:00`, e ficam assim até a linha do jogador aparecer no medidor. Se a sessão do medidor não puder ser lida, os campos mostram `--`. Se o medidor da Blizzard não está disponível, os campos de dano mostram `--` e o threat segue.

TOTAL é o acumulado do medidor da Blizzard, e zera quando o medidor zera: com `/central reset` (fora de combate) ou sozinho ao entrar numa instância nova, nos personagens com o CVar `damageMeterResetOnNewInstance` ligado.

## Threat por papel

O papel de cada personagem é `dps` ou `tanque` (seção "Como mudar"). A palavra do estado fica na linha 1 do cartão, a linha 2 mostra a porcentagem ou um nome, e a régua embaixo mostra a porcentagem de 0 a 100, com uma marca em 80.

### Estados do dps

| Palavra | Quando aparece | Linha 2 | Cor |
|---|---|---|---|
| `SAFE` | o resto, inclusive alvo que não está na tabela de threat (aí a linha 2 fica vazia) | porcentagem | sem moldura, texto cinza |
| `CLOSE` | porcentagem chega a 80 (sai abaixo de 75) | porcentagem | moldura âmbar de 2, texto âmbar |
| `HIGH` | você está acima de quem segura o alvo, ou a porcentagem chega a 95 (sai abaixo de 90) | porcentagem | moldura vermelha de 3, texto vermelho claro |
| `ON YOU` | você segura o alvo; ou o alvo é de outro, mas você tem threat alto (2 ou 3 contra qualquer inimigo) | porcentagem, ou `other` no segundo caso | cartão cheio vermelho-alaranjado, texto branco |

### Estados do tanque

| Palavra | Quando aparece | Linha 2 | Cor |
|---|---|---|---|
| `LOST` | você perdeu o alvo para outro (estado 0 ou 1 no alvo) | nome de quem tem o alvo agora, se houver | cartão cheio vermelho-alaranjado, texto branco |
| `LOOSE` | uma unidade do grupo ou o pet está com um mob solto (estado 2 ou 3 contra qualquer inimigo) | nome dela | moldura vermelha de 3, texto vermelho claro |
| `SLIPPING` | você segura o alvo sem folga (estado 2); ou um desafiante chega a 80 (sai abaixo de 75); ou, em chefe sem porcentagem legível, o líder a partir de 2 | nome e porcentagem do desafiante | moldura âmbar de 2, texto âmbar |
| `HELD` | você segura o alvo com folga (estado 3), sem nada acima | nome e porcentagem do maior desafiante, se houver | sem moldura, texto azul |

Desafiante é uma unidade da lista de `threat.unidades` (pet e grupo) que também tem threat no alvo. Alvo hostil sem entrada na tabela de threat, no tanque, mostra `--` como palavra, sem moldura.

### Quando o cartão aparece e quando some

Aparece em combate, com grupo ou pet (ou se teve pet nesta luta), e quando tem algo a dizer: um alvo hostil vivo, ou um estado geral 2 ou 3 legível (no tanque, de um aliado). Solo, sem pet, nunca aparece. Some quando passam 2 s sem nada a dizer, com fade de 0,4 s, e fica escondido fora de combate. O cartão do dano não muda de lugar quando o do threat some.

### Pulso

Um clarão branco de 0,3 s no cartão. Dispara quando o estado piora para `HIGH`, `ON YOU`, `SLIPPING`, `LOOSE` ou `LOST` vindo de um estado menos grave, com leitura legível. Fica mudo por 0,5 s depois de trocar de alvo e por 8 s depois do último pulso. Piorar é imediato; melhorar só depois de 1 s estável (`melhoraSeg`).

### Quando a API não entrega o número

Contra chefe, a porcentagem do threat pode vir secreta (seção 4 do contrato, a confirmar no jogo). Então:

- o estado ainda dá a palavra e a cor. No dps, 0 vira `SAFE`, 1 vira `HIGH`, 2 e 3 viram `ON YOU`. No tanque, 3 vira `HELD` ou `SLIPPING` (pelo líder), 2 vira `SLIPPING`, 0 e 1 viram `LOST`. `CLOSE` não aparece. A linha 2 e a régua mostram o valor, com cor neutra.
- se o estado também vier secreto, aparece `THREAT` em cor neutra, sem moldura. O texto `ON YOU` aparece pela própria API, que diz se você está segurando.
- no tanque, se a porcentagem de algum desafiante vier secreta, a linha 2 e a régua ficam vazias, porque não se mostra a porcentagem de uma unidade qualquer.

## Fora de combate

Ao sair da luta, o cartão do dano fica parado com os números da luta enquanto o addon guarda o resumo: 1 s de espera e até 8 tentativas, a cada 0,2 s. Depois, mais 3 s. Se a captura não der certo, os números ficam como estavam.

Então o cartão vira o resumo da última luta (DPS, FIGHT, TOTAL e tempo): só texto, sem fundo (`resumo.fundo = false`), com alfa 0,65 e fade de 1 s (escolha do dono na prévia de 2026-11-16: sem caixa, e mais forte que os 0,45 iniciais). O resumo fica guardado por personagem.

Ao entrar no jogo, a amostra de login dura 4 s (`login.mostrarSeg`): o cartão mostra o último resumo parado e depois vira o resumo apagado. Sem resumo guardado, o cartão some.

## Arquivos

Pasta `addons-proprios\CentralForever`.

| Arquivo | O que tem |
|---|---|
| `CentralForever.toc` | Interface 16001 (tem de bater com a do cliente), dependência opcional do ElvUI, SavedVariables `CentralForeverDB` e a ordem de carga |
| `Config.lua` | tudo o que se muda; só dados |
| `Nucleo.lua` | nome e versão, `ns.seguro`, registro de eventos (`ns.ao`), tique, mensagens, log, banco de dados por personagem, enumerações e o disjuntor por recurso |
| `Segredo.lua` | o único que chama as APIs de combate e lê o valor cru; as caixas e os ralos de exibição |
| `Diario.lua` | o diário no `CentralForeverDB` (carga, lutas e entradas avulsas) e a medição das larguras do pior caso |
| `Medidor.lua` | o dano: DPS, FIGHT, TOTAL, tempo e o resumo guardado ao fim da luta |
| `Ameaca.lua` | o threat: papel, estados, pulso e a visão que o painel mostra |
| `Painel.lua` | os quadros e os textos, criados uma vez; modos e cores do cartão de threat |
| `Convivencia.lua` | a janela nativa da Blizzard (CVar `damageMeterEnabled`) e a reserva |
| `Estados.lua` | a máquina de estados, os eventos, o tique e o `/central` |
| `CONTRATO.md` | o contrato entre os módulos e as ferramentas: regras, eventos, estados, funções de cada módulo e o formato do `CentralForeverDB`. É a fonte da verdade do addon |

## Como mudar

Tudo se muda no `Config.lua`. Mudou só um `.lua` que já existe: `/reload` no jogo. Arquivo novo ou `.toc` novo: reinicie o jogo. Chave que faltar num Config antigo usa o padrão do código.

| Quero mudar | Chave | Observação |
|---|---|---|
| ligar ou desligar | `ligado` | `false` tira o painel e devolve a janela nativa |
| lugar e tamanho | `ponto`, `largura`, `altura`, `vao`, `cartaoDano`, `cartaoThreat` | medidas em unidades da UI |
| tamanho das letras | `tamanhos` | `dps`, `luta`, `total`, `tempo`, `rotulo`, `palavra`, `linha2` |
| cores | `cores` | `cheio`, `ambar`, `vermelhao`, `vermelhaoTexto`, `azul`, `neutro`, `pulso` e as outras |
| palavras e textos | `threat.palavras`, `threat.outro`, `rotulos`, `vazio`, `tempoZero` | as palavras do threat, em inglês; `vazio` é `--` |
| formato dos números | `formato` | `inteiro` ou `abrev`, para `dps`, `luta` e `total` |
| limiares do threat | `threat.perto`, `threat.alto`, `threat.desafiante`, `threat.liderSlipping`, `threat.escala` | pares de `entra` e `sai`, em porcentagem |
| papel por classe | `papelClasse` | `PALADIN = "tanque"`; as outras classes seguem `papelPadrao` (`"dps"`) |
| papel por personagem | `papel` | pelo nome do personagem; sobrescreve a classe (vazio hoje) |
| janela nativa | `janelaNativa` | `"esconder"` ou `"deixar"`; ver a seção "Janela nativa da Blizzard" |
| diário | `sondas` | `ligado`, `maxLutas`, `maxEntradas` |
| resumo e amostra | `resumo`, `login`, `amostra` | alfa e fade do resumo; segundos do login e do `/central test` |

Os tempos do threat (`melhoraSeg`, `pulsoSeg`, `pulsoMinSeg`, `pulsoAposAlvoSeg`, `semAlvoSeg`, `fadeSeg`) ficam em `threat`, e a cadência do tique em `cadencia`.

## Comandos

| Comando | O que faz |
|---|---|
| `/central` | mostra o estado atual, o papel, se o medidor está disponível, o valor do CVar e quantas lutas há no diário |
| `/central test` (ou `teste`) | fora de combate, mostra a amostra com números de exemplo por 10 s e volta ao estado anterior |
| `/central meter` | mostra ou esconde a janela nativa da Blizzard para este personagem |
| `/central reset` | zera o medidor da Blizzard, fora de combate |

As respostas dos comandos saem em inglês.

## Janela nativa da Blizzard

- O addon controla o CVar `damageMeterEnabled`, que mostra ou esconde a janela nativa do medidor. Com `janelaNativa = "esconder"` (padrão), fora de combate ele põe o CVar em `0`. Com `"deixar"`, não mexe nele.
- O valor que estava antes fica guardado por personagem, em `cvarAntes` no `CentralForeverDB`. Ele volta quando o addon é desligado, quando `janelaNativa` é `"deixar"` ou quando o dono pede a janela com `/central meter`.
- Reserva: a central depende de o medidor coletar com a janela escondida. Só vale quando o próprio addon pôs o CVar em 0. Se três lutas seguidas, de pelo menos 10 s cada, passarem sem a linha do jogador, o addon devolve o CVar, avisa uma vez no chat e registra no diário. Uma luta sem dano não conta. Se a linha do jogador aparecer uma vez com o CVar em 0, a reserva nunca mais roda nesse personagem.
- O CVar só muda fora de combate. A reserva liga com `reservaCVar`, e `reservaLutas` e `reservaDurMin` ajustam os números.

## Diário e calibração

O addon grava no `CentralForeverDB` (SavedVariables):

- `log`: as últimas 80 linhas de texto.
- `diario.carga`: uma entrada por personagem a cada login, com a versão, o build do cliente, a classe, o papel, se o medidor está disponível, o valor dos CVars, as APIs que existem, os formatos de número e as larguras de texto do pior caso.
- `diario.lutas`: as últimas 30 lutas, com zona, instância, chefe, papel, duração, o que cada leitura deu, o resumo e os contadores.
- `diario.avulsas`: as últimas 300 entradas soltas (restrição, reset, nova sessão, bloqueio, desligado, reserva, erro).
- `personagens`: por personagem, o último resumo e o estado da janela nativa e da reserva.

Nunca entra valor secreto: o diário só recebe `secreto`, `legível` ou `nada`, booleanos, números legíveis e textos do addon. Três erros de um mesmo recurso (`disjuntor.erros`) desligam esse recurso e entram no diário. `sondas.ligado = false` desliga o diário.

Uma sessão futura lê o diário com `node ler-diario-central.mjs --sv <arquivo>`, a partir de `modder\ferramentas\guia` (`--bug` e `--taint` são opcionais). O relatório sai por seção: carga, formatos, lutas por contexto, entradas avulsas e erros.

## Valores secretos

Em combate, parte dos números chega como valor secreto: o addon pode exibir, mas não pode somar, comparar, concatenar nem usar como chave ou tamanho. Por isso só `Segredo.lua` chama as APIs de combate e lê o valor cru, e só para entregá-lo a um ralo de exibição (`SetText`, `SetValue`, `SetAlphaFromBoolean`). Os outros módulos decidem só pelos campos `s`, `tem` e `n` da caixa. O addon exibe, não calcula: nenhuma cor muda pelo valor, e nada é contado em combate. A exceção 2 da regra 5 do projeto, aprovada pelo dono em 2026-11-16, permite essas chamadas só em `Segredo.lua`, sempre em `pcall`.

## Como validar

Rode a partir de `modder\ferramentas\guia`:

```
node checar-lua.mjs ..\..\addons-proprios\CentralForever
node checar-combate.mjs ..\..\addons-proprios\CentralForever --toc --perfil central
node rodar-central.mjs
node rodar-central.mjs --matriz
node rodar-casos-combate.mjs
node rodar-casos-segredo.mjs
node conferir-doc.mjs
```

| Comando | O que confere |
|---|---|
| `checar-lua.mjs` | sintaxe, ASCII e globais do addon (regras 1 e 2) |
| `checar-combate.mjs ... --toc --perfil central` | as regras de API de combate com o perfil da central (R10 a R17): função de combate só em `Segredo.lua`, nada de medir texto, `SetCVar` só em `Convivencia.lua`, eventos só da lista fechada |
| `rodar-central.mjs` | a bancada: os cenários C01 a C34 com a API simulada. Sai 0 sem falha, 1 com falha e 2 se um arquivo não carregou |
| `rodar-central.mjs --matriz` | os cenários de novo, com cada chave U1 a U10 trocada (segredo ou não, CVar, atraso) |
| `rodar-casos-combate.mjs` | os casos do checador de combate, um por regra |
| `rodar-casos-segredo.mjs` | os casos do simulador de valor secreto |
| `conferir-doc.mjs` | as assinaturas da documentação da Blizzard (seção 12 do contrato) |

## Desfazer

Rápido: no `Config.lua`, `ligado = false`, e `/reload`. O painel deixa de ser criado e o addon não trata mais eventos. A janela nativa volta ao valor guardado em `cvarAntes`. Continua como está: o addon segue carregado e o `CentralForeverDB` (log, diário e último resumo) fica no arquivo. Continuam mudadas também as duas coisas que o UIForever faz no canto por causa da central (tabela abaixo): a barra de threat do ElvUI segue desligada e o tooltip segue nascendo mais alto.

Completo: faça antes o rápido, para o CVar voltar ao valor de antes enquanto o addon ainda existe. Depois, com o WoW fechado, tire a junction com `ferramentas\dev-link.ps1 -Pasta "addons-proprios\CentralForever" -Remover`, primeiro em prévia e depois com `-Aplicar`. Só a junction sai; a pasta em `addons-proprios` fica intacta. Por fim, no `UIForever\Config.lua`, escreva o valor antigo das duas linhas do canto. O UIForever não restaura valor quando a linha sai do arquivo, então apagar a linha não desfaz.

| Linha em `UIForeverConfig.elvui` | Valor com a central | Valor antigo |
|---|---|---|
| `databars.threat.enable` | `false` | `true` |
| `movers.TooltipMover` | `"BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-4,88"` | `"BOTTOMRIGHT,RightChatToggleButton,BOTTOMRIGHT,0,0"` |

Essas duas linhas entram no UIForever 0.7.1, junto com a ligação do addon ao jogo, e valem para os quatro personagens, que usam o mesmo perfil do ElvUI.

## Limites conhecidos

- Ainda não rodou no jogo. A seção 13 do contrato ("Como ficou") está em branco. Tudo foi conferido só pelos checadores e pela bancada.
- As leituras de valor secreto são as que a documentação diz (seção 4 do contrato). Falta confirmar no jogo, pelo diário: se a sessão de dano vem secreta em combate, se a duração vem legível, se o threat contra o alvo vem legível e se a porcentagem vem secreta contra chefe.
- Que o medidor coleta com a janela nativa escondida (CVar em 0) é o que fazem o Details e o QUI no cliente moderno, mas não foi visto no Forever; por isso existe a reserva, e o diário marca `coletaSemJanela` quando isso se confirma. Se o pet do caçador aparecer como linha própria no medidor, a central mostra só a do jogador.
- O addon não mede texto: os campos têm largura fixa, e o pior caso foi conferido só fora do jogo, com a prévia. Se a fonte Expressway não carregar, o texto usa outra fonte e pode passar da caixa.
- A posição e o tamanho foram pensados para a tela do dono (2560x1440 com escala 0,7, conforme o `Config.lua`). Em outra tela, ajuste pelo `Config.lua`.
- Os limiares e os tempos do threat ainda não foram vistos em luta. Ajuste depois do primeiro teste.
