---
frente: pregaoforever
status: ativa
atualizado: 2026-11-16T13:11-03:00
maquina: Avell
temas: [jogos, workflow]
proximo_passo: "Dono: ler o LEIA-ME.md do PregaoForever, responder as seis decisões de antes do código e colar no jogo os 16 comandos de leitura do Apêndice A do DESIGN.md"
decisoes_abertas: 8
commit: 02de5cf
sensivel: false
---

> Frente: pregaoforever · Atualizado: 16/11/2026 13:11 · Máquina: Avell

> **O que é esta frente.** O PregaoForever é um addon de casa de leilões para o WoW Forever, do Bruno (o dono), feito pelo agente wow-modder. Em 16/11/2026 ficou pronto só o **design**: nenhuma linha de addon foi escrita e nada rodou no jogo. A frente continua na implementação, em ondas, depois que o dono decidir e medir.
>
> **Leia isto mais três arquivos e você retoma do zero:** `C:\GMS\Claude Code Projects\wow\CLAUDE.md` (limites fixos do projeto), `addons-proprios\PregaoForever\LEIA-ME.md` (texto do dono, 4,3 mil palavras, leia inteiro) e `addons-proprios\PregaoForever\DESIGN.md` (contrato de implementação). O `DESIGN.md` tem 44 mil palavras em 2.004 linhas longas: nunca leia inteiro. Liste os títulos com `Grep -n "^## \|^### "` e leia por faixa; comece pelas seções 0, 1, 17 e 18 e pelos Apêndices A e D.
>
> **Não releia nem refaça:** a pesquisa, os seis projetos, a revisão e as duas varreduras (seis ondas de Workflow, 68 tarefas, cerca de 26,9 milhões de tokens). A pasta `pesquisa\processo\` é material superado, guardado só para rastreio. Não escreva código de addon antes das seis decisões do dono e da onda 0.
>
> ⚠️ **Nada foi testado no jogo.** Tudo o que depende do jogo é hipótese numerada (H-01 a H-39) com o passo de sonda que a mede. A principal: se a tecla do dono, ligada a um botão do addon, satisfaz as funções de postar e comprar (H-01). Se não valer nem com o mouse, sobram a régua e a fila, sem a mão.
>
> ⚠️ **Código de addon de terceiro não é referência.** O Auctionator, o Syndicator e o Baganator trazem um `AGENTS.md` pedindo que agentes de IA não usem o repositório. Não leia esse código nem mande subagente ler; a convivência é só pela interface pública, lida no jogo com `/dump`. É decisão do agente, ainda sem resposta do dono (decisão aberta 7).
>
> ⚠️ **Os commits desta frente estão só no Avell, sem push.** Em outra máquina, rode o Sincronizar antes; sem isso a pasta `PregaoForever` não existe.
>
> ⚠️ **Todo número de política do design é proposta** (tetos, margem mínima, ritmo), sem fonte de economia, à espera do dono (decisão DD10). A regra do projeto continua valendo: gameplay vem das fontes que o dono escolheu, e o agente não dá opinião própria.

## Estado em uma tela

- **Projeto:** `C:\GMS\Claude Code Projects\wow`, agente wow-modder (subpasta `modder`). **Pasta do addon:** `C:\GMS\Claude Code Projects\wow\modder\addons-proprios\PregaoForever\`, sem `.toc`, não ligada ao jogo.
- **Jogo:** WoW Forever, cliente 1.60.1 build 70938, Interface 16001, só no notebook Avell (inferido: base de fatos de 16/11/2026). O dono vai operar o Avell pelo Acer, em acesso remoto.
- **Status:** design concluído e commitado em 16/11/2026. Conferências por script passaram sobre o texto final (observado em 16/11/2026). Nenhum código, nenhum teste no jogo (não testado).
- **O addon em uma frase:** terminal de leilão em três peças: a régua mede cada ação, a fila mostra até cinco linhas do que fazer, e a mão age por uma tecla do dono por ação, depois de um núcleo de risco (o Cofre).
- **Conclusão do próprio design:** com 5 ouro (50.912 cobre somando quatro personagens) o addon não deixa ninguém rico por trading. Ele vende melhor o que os personagens produzem e prova, com números do dono, se comprar para revender paga. Construir a mão ou adotar ferramenta pronta se decide com número, depois de três sessões medidas (decisão DD12).
- **O que falta, em uma frase:** o dono ler, decidir seis pontos e colar 16 comandos de leitura no jogo; só então começa a onda 1 (contrato e esqueletos).

## O que já foi feito (não refazer)

1. **Pesquisa** (25 recortes e 6 céticos): `pesquisa\base-de-fatos.md` e 16 relatórios (`pesquisa\R*.md`). Nove recortes que descreviam código de addon de terceiro ficaram fora de propósito.
2. **Design:** seis projetos independentes, três juízes e uma síntese; depois nove revisores adversariais (169 achados) e um redator. Resultado: `DESIGN.md`, `LEIA-ME.md` e `MUDANCAS.md` na pasta do addon.
3. **Conferência e duas varreduras de consistência** por sete lentes só-leitura: a primeira achou 53 pontos distintos (1 bloqueante), a segunda 28 (nenhum bloqueante). Todos corrigidos; não houve terceira rodada (observado em 16/11/2026).
4. **Conferências por script sobre o texto final** (observado em 16/11/2026): os 169 ids de achado estão no `MUDANCAS.md`; toda hipótese, decisão, passo de sonda e invariante citado tem definição; os 507 nomes de função, evento, enum e texto do cliente citados existem no espelho da interface da Blizzard, nas listas do projeto ou no arquivo de textos (os 16 que não batem são prefixos, tabelas do cliente e nomes do próprio addon); os 16 comandos da sonda têm de 54 a 245 caracteres e sintaxe fechada; as tabelas da escada de capital foram refeitas por script independente. Existir no espelho prova que o nome é real, não que a assinatura está certa.
5. **Quadros das telas:** `pesquisa\telas\telas.html`, dez PNG em `pesquisa\telas\png\` e o `renderizar.mjs` que os refaz pelo Edge sem tela. É a primeira versão, no tamanho hipotético de 520 por 500 unidades.
6. **Scripts de conferência guardados:** `pesquisa\scripts\conferencia\` (seis scripts, um `LEIA-ME.md` e os cinco arquivos de trocas). Rodam a partir dali (observado em 16/11/2026).
7. **Registros:** linha do PregaoForever no índice `addons-proprios\LEIA-ME.md`; status, três pendências do dono e entrada no diário em `estado\estado.md`; 68 linhas em `C:\GMS\Claude Code Projects\skill-review\reviews\calibracao.jsonl`; ingest no second brain (duas páginas novas no vault GMS-SB).
8. **Commits, todos locais e sem push:** `c2957db` e `02de5cf` em `C:\GMS`; `745ea08` no repositório `skill-review`; `b39eb85` no vault.

## Decisões abertas

As seis primeiras precisam de resposta antes da primeira linha de código. A tabela completa, com o padrão de cada uma, está na parte 5 do `LEIA-ME.md` e na seção 18 do `DESIGN.md`. Não decida pelo dono: o padrão só vale se ele disser "pode seguir".

1. **DD1a, postar e cancelar por tecla.** Sim, só neste addon, uma tecla por ação e dentro de tetos; ou não, e o addon fica em modo leitura (aponta e mede, o dono age pela tela da Blizzard). Em 06/11/2026 ele proibiu, no outro addon, funções que gastam por código.
2. **DD1b, comprar por tecla.** Sim, em dois tempos e só nas estratégias que ele ligar; só papel (registra sem gastar); ou não.
3. **DD3, fontes e regra de preço da venda.** Ligar a venda dos verdes (única fonte já aprovada, o vídeo do Studen Albatroz); aprovar ou não os guias de fã para as sobras de coleta; regra de preço entre igualar (o texto do próprio cliente diz que não é preciso cobrir), cobrir por um cobre ou deixar folga. Duração e tamanho do lote das sobras não têm padrão.
4. **DD4, negociador, ouro e piso.** Qual personagem compra (sem padrão); reunir ou não o ouro nele (sem padrão: reunido, a banca é de cerca de 4 ouro; sem reunir, de cerca de 27 prata); piso pessoal de 1 ouro ou zero.
5. **DD9, acesso remoto e os termos.** Perguntar ao suporte por escrito antes de sessões longas, ou operar sem perguntar: não há posição oficial sobre acesso remoto ao próprio PC.
6. **DD14, reservas.** O agente propõe a lista do que não vai à venda a partir dos roteiros de profissão, e o dono aprova; ou uma lista dele.
7. **Ratificar a decisão sobre código de terceiros.** O agente decidiu não usar código de addon de terceiro como referência por causa do aviso `AGENTS.md`. O dono foi informado em 16/11/2026 e não se pronunciou.
8. **As que podem esperar, todas com padrão:** mapa de teclas (DD5, depois da sonda e dos quadros), nome (DD6, fica PregaoForever se ele não pedir outro), convivência com Auctionator e ForeverGuide (DD2), mesa externa (DD7), credencial da API de dados (DD8), números de política (DD10, antes da onda 3), construir ou adotar (DD12, fim da onda 2), gatilho da varredura (DD13, onda 5), correio e vendedor por tecla (DD1c), várias unidades por tecla (DD11) e assinatura de vendedor (DD15).

## Próximos passos concretos

1. **Dono:** ler o `LEIA-ME.md` e responder as seis decisões (itens 1 a 6 acima).
2. **Dono, no jogo, no Avell:** com o leilão aberto, colar os 16 comandos de leitura do Apêndice A do `DESIGN.md`, um por vez. No primeiro o jogo pergunta "Allow custom scripts?": responder Yes e colar de novo. O comando 16 pede o preparo descrito junto dele. Guardar a resposta de cada um (captura de tela serve).
3. **Dono:** em Options, Keybindings, anotar o que B, C, H, I, K, L, M, N, O, P, U e Y fazem hoje, e apertar F1 a partir do Acer para ver se o jogo reage.
4. **Dono:** depois da manutenção de 17/11/2026, repetir os comandos 8, 11 e 12, que leem o depósito (o mínimo cai de 1 prata para 1 cobre por anúncio da Blizzard).
5. **Dono:** abrir `pesquisa\telas\telas.html` e dizer o que mudar nos quadros.
6. **Agente, depois dos passos 1 a 3:** gravar as respostas dos comandos e as decisões em `estado\estado.md` e fechar a onda 0.
7. **Agente, onda 1 (contrato):** `ARQUITETURA.md`, gramática do banco congelada, `.toc` e 28 esqueletos, `Tetos.lua`, `Config.lua` com tudo desligado, `Calibrado.lua` neutro, scripts de dados, `checar-pregao.mjs`, bancada com leilão falso e maquetes das telas no tamanho medido. Depende do passo 6. Antes de lançar subagentes, propor o plano com roteamento e perguntar o modo de execução (regra do dono; a guarda bloqueia Workflow sem isso).
8. **Ondas 2 a 6:** seção 17 do `DESIGN.md`, cada uma com portão do dono no jogo.

## Como retomar (comandos exatos)

Abra a sessão em `C:\GMS\Claude Code Projects\wow\modder` (é a pasta que já abre com o agente wow-modder). Pré-requisitos: Node (v24 no Avell), git e Edge; jogo fechado para qualquer coisa que escreva na pasta do jogo.

Ler o contrato por partes:

```
Grep -n "^## \|^### " em C:\GMS\Claude Code Projects\wow\modder\addons-proprios\PregaoForever\DESIGN.md
Read com offset e limit nas seções 0, 1, 17, 18 e nos Apêndices A e D
```

Conferir o design depois de qualquer edição do `DESIGN.md` ou do `LEIA-ME.md` (Bash, a partir da pasta dos scripts):

```bash
cd "/c/GMS/Claude Code Projects/wow/modder/addons-proprios/PregaoForever/pesquisa/scripts/conferencia"
node gate-final.mjs ../../.. ../../processo/achados-todos.md
node conferir-comandos.mjs ../../../DESIGN.md
node conferir-escada.mjs
```

Editar o `DESIGN.md` com segurança: escreva um arquivo de trocas (blocos `<<<`, texto antigo, `===`, texto novo, `>>>`) e rode primeiro sem `--aplicar`:

```bash
node aplicar-trocas.mjs ../../../DESIGN.md <arquivo de trocas>
node aplicar-trocas.mjs ../../../DESIGN.md <arquivo de trocas> --aplicar
```

Conferir nomes de API (pede baixar o espelho e o arquivo de textos, que não ficam no repositório):

```bash
git clone --depth 1 --branch forever https://github.com/Ketho/wow-ui-source-forever <pasta temporária>/espelho
node conferir-nomes.mjs <pasta temporária>/espelho/Interface/AddOns ../../../../../ferramentas/guia/api-forever <enUS.lua do GlobalStrings> ../../../DESIGN.md
```

O espelho usado foi o commit `bebcb6bf309cf41b41bd74f8ca651e6a105b2676` (1.60.1, build 70938); o arquivo de textos é `Resources/GlobalStrings/enUS.lua` do repositório `Ketho/BlizzardInterfaceResources`, branch `forever`. Resultado esperado: 16 nomes fora do conjunto, os mesmos do item 4 de "O que já foi feito".

Refazer os quadros: `node renderizar.mjs` dentro de `pesquisa\telas`.

## Gotchas

- **Limite de uso de 5 horas.** Uma onda de nove revisores Fable e Opus morreu inteira com "You've hit your 5-hour limit" e perdeu oito pareceres. Contorno: mandar cada agente gravar o arquivo cedo e ir completando, passar por `args` só os que faltam e não repetir quando o erro é de limite.
- **Haiku em Workflow não gravou o relatório `.md`.** Seis de 18 devolveram o texto na resposta alegando regra do ambiente. Contorno que funcionou: pedir o relatório na própria resposta e gravá-lo por script a partir do `journal.jsonl`.
- **Antes de mandar ler código de terceiro,** procure `AGENTS.md` nas pastas. O brief da pesquisa já listava esse arquivo e ninguém o abriu antes; custou nove recortes.
- **Arquivo lido enquanto um agente de fundo o reescreve é foto velha.** Só apareceu porque uma troca por casamento exato casou zero vezes. Espere o agente terminar antes de ler.
- **Varredura por lentes dá falso positivo em número medido.** Três lentes refizeram como produto os tamanhos da seção 6.2, que são medida de um arquivo gerado. Diga às lentes o que é medida.
- **Outra sessão no mesmo repositório.** Commit só por caminho, e não toque em arquivo compartilhado (`estado.md`, índice) enquanto ela estiver ativa.
- **Não copie o nome real da pasta da conta** (`WTF\Account\...`) para relatório nem script; o `gate-final.mjs` procura esse padrão.

## Estado do repo e da plataforma

- **`C:\GMS`** (branch `main`): `02de5cf` "docs(wow): registra o PregaoForever no indice e no diario do modder e guarda os scripts de conferencia", sobre `c2957db` "docs(wow): design do PregaoForever, addon de leilao (contrato, leia-me, pesquisa e quadros)". Sem push. No começo da sessão o repositório estava 1 commit atrás do remoto e a máquina "escritorio" não tinha feito sync de saída (inferido: aviso de sincronização de 16/11/2026).
- **Este handoff e o `HANDOFFS.md` da pasta** foram gravados depois do `02de5cf` e commitados em seguida, em 16/11/2026, como `docs: handoff pregaoforever`, com o ok do dono e também sem push.
- **Invisível ao repositório:** nada foi instalado nem ligado no jogo; a pasta do jogo e as SavedVariables não foram tocadas. O espelho da interface, as tabelas do cliente e os arquivos de tokens da sessão ficaram numa pasta temporária do Avell, que um reinício apaga. Os transcritos dos seis workflows estão em `C:\Users\PC-AVELL\.claude\projects\C--GMS-Claude-Code-Projects-random-shit-modder\65b696b0-b8cd-44b5-8cea-535f4273fb76\`, só no Avell.
- **Pendente de outra frente do mesmo agente:** o teste no jogo da CentralForever 0.1.0 (pendências do `estado\estado.md`).

## Referências rápidas

| Preciso de | Onde |
|---|---|
| Limites fixos e formato do relatório de sessão do WoW | `C:\GMS\Claude Code Projects\wow\CLAUDE.md` |
| O que o dono precisa ler e decidir | `addons-proprios\PregaoForever\LEIA-ME.md` (parte 5: decisões; parte 4: primeiro dia) |
| Regras, hipóteses, módulos, ondas e decisões completas | `addons-proprios\PregaoForever\DESIGN.md` (seções 1, 2.2, 4.1, 17 e 18) |
| Os 16 comandos de leitura para colar no jogo | `DESIGN.md`, Apêndice A |
| De onde baixar o espelho, os textos e as tabelas do cliente | `DESIGN.md`, Apêndice D |
| Fatos do leilão com fonte | `addons-proprios\PregaoForever\pesquisa\base-de-fatos.md` |
| O que mudou em cada revisão | `addons-proprios\PregaoForever\MUDANCAS.md` |
| Quadros das telas | `addons-proprios\PregaoForever\pesquisa\telas\telas.html` |
| Scripts de conferência e como usar | `addons-proprios\PregaoForever\pesquisa\scripts\conferencia\LEIA-ME.md` |
| Pendências e diário do agente | `estado\estado.md` |
| Lições desta sessão no second brain | `C:\GMS\Claude Code Projects\Obsidian\GMS-SB\wiki\hot.md` e as duas páginas "PregaoForever ..." |
