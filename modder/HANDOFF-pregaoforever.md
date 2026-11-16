---
frente: pregaoforever
status: ativa
atualizado: 2026-11-16T18:10-03:00
maquina: Avell
temas: [jogos, workflow]
proximo_passo: "Dono, depois da manutenção de 17/11: repetir os comandos 8, 11 e 12 da S0, fazer a S9 e os dois L do S4 sem o Auctionator, e a primeira sessão de linha de base; agente lê o banco e confere a correção do Ecos"
decisoes_abertas: 3
commit: ea69e41
sensivel: false
---

> Frente: pregaoforever · Atualizado: 16/11/2026 18:10 · Máquina: Avell

> **O que é esta frente.** O PregaoForever é o addon de casa de leilões do Bruno (o dono) para o WoW Forever, feito pelo agente wow-modder. Em 16/11/2026 saíram o design (manhã) e, à tarde, as ondas 0, 1 e 2: o addon 0.1.0 existe, está ligado ao jogo e roda em **modo leitura** (a régua mede, a fila ainda não existe, nenhuma função de ação no código). A frente segue na onda 2 no jogo (sondas e sessões de linha de base), que decide a DD12 (construir a mão ou não).
>
> **Leia isto mais três arquivos e você retoma do zero:** `C:\GMS\Claude Code Projects\wow\CLAUDE.md` (limites fixos e formato do relatório de sessão), `addons-proprios\PregaoForever\ARQUITETURA.md` (contrato congelado das ondas 1 e 2, com a seção "Mudanças do contrato" no fim) e `addons-proprios\PregaoForever\pesquisa\sonda\onda2-2026-11-16.md` (o que já foi medido no jogo). O `DESIGN.md` (44 mil palavras) só por faixa: `Grep -n "^## \|^### "` e leia a seção que a tarefa pede; a onda 3 está na seção 17.
>
> **Não refaça:** o design, a pesquisa, o contrato, os 28 arquivos, o checador, a bancada, o leitor e os 80 cenários. Tudo passa (observado em 16/11/2026).
>
> ⚠️ **A correção do `Ecos.lua` e do `Sonda.lua` (commit `ea69e41`) ainda não rodou no jogo.** No cliente real, o eco de compra chegou antes do `PLAYER_MONEY` e o cliente disparou `AUCTION_CANCELED` para o leilão comprado; isso deu uma compra com valor 0, um cancelamento falso no Livro e um "canceled" falso na `sonda.S9` do banco atual. A S9 de verdade ainda não foi feita (inferido: banco das 18:04 de 16/11/2026).
>
> ⚠️ **Antes da manutenção de 17/11 o próprio jogo avisa** que leilão não vendido até a manutenção volta e perde o depósito (texto `CONFIRM_AUCTION_POSTING_TEXT`, lido na S0). Depois dela o depósito mínimo cai de 1 prata para 1 cobre (inferido: base 1.7 do design; a releitura é o próximo passo).
>
> ⚠️ **Código de addon de terceiro não é referência** (Auctionator, Syndicator e Baganator pedem isso num `AGENTS.md`); o dono ratificou em 16/11/2026. A ponte do Auctionator usa só `Auctionator.API.v1.GetAuctionPriceByItemID` e `GetAuctionAgeByItemID`, as duas que a frente crafts-que-pagam conferiu no jogo.

## Estado em uma tela

- **Addon:** `C:\GMS\Claude Code Projects\wow\modder\addons-proprios\PregaoForever\`, 0.1.0, 28 arquivos, ligado ao jogo por junction do `dev-link.ps1` (slug `dev-pregaoforever`). Interface 16001, build 70938 (observado em 16/11/2026, S0).
- **Modo:** `leitura`. Negociador `Hexumlite` (chave `UnitName('player')`), ouro reunido nele, piso pessoal zero. Banca lida no jogo: 5g 62s 80c (observado em 16/11/2026).
- **Testes fora do jogo:** 80 cenários da bancada (9 grupos), auto-teste da bancada (21), checadores `checar-lua`, `checar-combate --toc` e `checar-pregao` com 0 erro, 29 casos do checador, `checar-dados-pregao` e a ida e volta do leitor (23 tipos) passam (observado em 16/11/2026).
- **No jogo:** janela abre com o leilão; L, F3 e F5 funcionam pelo acesso remoto; banco grava limpo no `/reload` (186 registros, 0 inválido no `ler-pregao.mjs`); S0 completa; S1 parcial; S12 feito; S4 3 de 5; S13 primeira metade (observado em 16/11/2026).
- **Falta:** releitura do depósito depois da manutenção, S9, S4 sem Auctionator, segunda metade do S13, enchimento do S1, três sessões de linha de base e, com elas, a DD12.

## O que já foi feito (não refazer)

1. **Design** (manhã de 16/11/2026): `DESIGN.md`, `LEIA-ME.md`, `MUDANCAS.md` e `pesquisa\` (base de fatos, relatórios, scripts de conferência, quadros). Commits `c2957db` e `02de5cf`.
2. **Decisões do dono** (16/11/2026): DD1a sim; DD1b sim em dois tempos; DD3 itens 1 e 3 nos padrões (venda dos verdes ligada, regra `igualar`); DD4 negociador Hexumlite, ouro reunido, piso zero; DD9 e DD14 nos padrões; código de terceiro não é lido; DD5 com o mapa da seção 11.2 e `P` em dois tempos. Todas gravadas no `Config.lua` e no cabeçalho do `ARQUITETURA.md`.
3. **Onda 1:** `ARQUITETURA.md` (regras e gramática copiadas por script do DESIGN, contrato por módulo, formato dos cenários), `.toc`, esqueletos, `Tetos.lua`, `Config.lua` (Apêndice B inteiro, mais `janela = { w = 520, h = 500, escala = 1 }`), `Calibrado.lua` neutro, `Dados.lua` (11.967 preços de vendedor do `ItemSparse` 70938; `ns.vend[1179] = 6` confere com o jogo), em `ferramentas\guia\pregao\`: `checar-pregao.mjs`, `rodar-casos-pregao.mjs`, `gerar-dados-pregao.mjs`, `checar-dados-pregao.mjs`, `bancada-pregao.mjs` e o falso em `bancada\`; casos em `ferramentas\guia\casos-pregao\`; 18 quadros em `pesquisa\telas\` com o tamanho em `:root { --W; --H; --S }` do `telas.html`.
4. **Onda 2:** corpos de `Nucleo`, `Banco`, `Itens`, `Escada`, `Pontes`, `Pedidos`, `Varredura`, `Livro`, `Ecos`, `Cofre`, `Correio`, `Visual`, `Janela`, `Teclas`, `Telas`, `Sonda` e `PregaoForever.lua`; `ler-pregao.mjs`. Integração na sessão principal (formatos do painel do correio, lista de ações da sessão, anel de fotos no leitor, prioridade das faixas). Commit `9c4a125`.
5. **Primeira noite no jogo:** S0 em `pesquisa\sonda\S0-2026-11-16.md`; S1, S4, S12, S13 e o banco da noite em `pesquisa\sonda\onda2-2026-11-16.md`. Correções da noite (Ecos, Sonda, Mine com nome do item e "no auctions posted") com os cenários `livro-15` e `folego-10`. Commit `ea69e41`.
6. **Registros:** diário e pendências em `estado\estado.md` (entrada de 16/11/2026, 15h20 às 18h10; sem commit, porque o arquivo tem alterações da frente crafts-que-pagam); 11 linhas em `C:\GMS\Claude Code Projects\skill-review\reviews\calibracao.jsonl` (commit `b8d3190` naquele repositório).
7. **Guia de uso para o dono** (16/11/2026, depois do /sb): página publicada como artifact em https://claude.ai/artifact/SVhE5CoGUNKXxN2sWGTf1p, com cópia do HTML em `addons-proprios\PregaoForever\guia\guia-pregaoforever.html`. Para atualizar a mesma página numa sessão nova, publique a cópia editada passando a URL em `url`; sem a URL, sai um artifact novo.

## Decisões abertas

1. **DD10, números de política** (tetos, margem mínima, ritmo de partida, disjuntores): todos proposta do design, sem fonte de economia. Precisa de resposta antes da onda 3.
2. **DD3 itens 2 e 4:** aprovar ou não os guias de fã para a venda das sobras de coleta, e a duração e o tamanho do lote delas. Enquanto isso, a linha de commodity mostra `PICK RULE`, sem tecla.
3. **DD14, a lista de reservas:** o agente propõe pelos roteiros de profissão e o dono aprova; hoje `reservas = {}`, e toda sobra de coleta fica em `KEPT`.

As que podem esperar, todas com padrão no `DESIGN.md` seção 18: DD2, DD7, DD8, DD11, DD12 (fim da onda 2, com os números), DD13, DD15 e DD1c.

## Próximos passos concretos

1. **Dono, no jogo, depois da manutenção de 17/11:** comandos 8, 11 e 12 da S0 (depósito); com um verde com sufixo no slot 1 da mochila, os comandos 8 e 13; S9 (postar 1 unidade barata em 2 horas pela tela da Blizzard e cancelar na aba Auctions; a Session deve contar 2 ações outside); os dois L do S4 sem o Auctionator (`/run C_AddOns.DisableAddOn("Auctionator")`, `/reload`; religar com `EnableAddOn`); cronometrar do L até `SCAN IDLE`.
2. **Dono:** primeira sessão de linha de base: vender pela tela da Blizzard com a janela aberta; no fim, F5 e Y.
3. **Agente, depois de cada sessão:** ler o banco (comando abaixo), conferir que a compra por fora tem o valor pago e nenhum cancelamento falso (correção de `ea69e41`), gravar as medidas em `pesquisa\sonda\`, escrever o relatório de sessão em `addons-proprios\PregaoForever\relatorios\`.
4. **Agente, consertos da onda 2:** dar chave à compra por fora (hoje vem vazia: `AUCTION_HOUSE_PURCHASE_COMPLETED` só traz o `auctionID`; a fatura `buyer` do correio traz o item); `dias` também a partir do resumo (hoje só das buscas por item); enchimento `sonda.lastro` para o S1 (reload com 1, 3 e 5 MB); segunda metade do S13 (SavedVariables truncado, com o jogo fechado, pelo `wtf-sv.ps1`, backup e ok do dono); o quadro "Favorite Patterns" do Auctionator abre por cima do canto da janela; a bancada ainda não simula processo de venda nem injeções de arquivo. Antes de lançar subagentes, propor o plano com roteamento e perguntar o modo de execução (regra do dono).
5. **Depois de três sessões de linha de base:** DD12 com os números; se for construir, onda 3 (seção 17 do DESIGN: `Estimadores`, `Motor`, `Estrategias`, `Cofre` com tetos, `Acoes` e `Ecos` de postar e cancelar, botões de ação, `Alertas`, visões Next, Sell e Risk), que pede a DD10 antes.

## Como retomar (comandos exatos)

Abra a sessão em `C:\GMS\Claude Code Projects\wow\modder` (ou em `random_shit\modder`, que é onde esta sessão rodou; os caminhos abaixo são absolutos). Node v24, git e Edge no Avell.

Bateria inteira (Bash, a partir de `C:\GMS\Claude Code Projects\wow\modder\ferramentas\guia`):

```bash
cd "/c/GMS/Claude Code Projects/wow/modder/ferramentas/guia"
A=../../addons-proprios/PregaoForever
for g in unid-nucleo unid-banco unid-itens unid-pedidos unid-livro unid-telas dados folego fatura; do node pregao/bancada-pregao.mjs --cenarios $g | tail -1; done
node pregao/bancada-pregao.mjs --auto-teste | tail -1
node checar-lua.mjs $A | grep -v '^ok'
node checar-combate.mjs $A --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER,BINDING_ | tail -1
node pregao/checar-pregao.mjs $A | tail -1
node pregao/rodar-casos-pregao.mjs | tail -1
node pregao/checar-dados-pregao.mjs | tail -1
node pregao/ler-pregao.mjs --ida-e-volta | tail -1
```

Ler o banco do jogo depois de um `/reload` (só leitura; nunca imprima nem copie o nome da pasta da conta):

```bash
cd "/c/GMS/Claude Code Projects/wow/modder/ferramentas/guia"
P=$(node -e 'const fs=require("fs"),p=require("path");const r="C:/Program Files (x86)/World of Warcraft/_forever_/WTF/Account";for(const c of fs.readdirSync(r)){const f=p.join(r,c,"SavedVariables","PregaoForever.lua");if(fs.existsSync(f)){console.log(f);break}}')
node pregao/ler-pregao.mjs "$P" | grep -v '^copia\|^json\|^arquivo:'
```

A cópia crua e o JSON vão para `wow\modder\dados\pregao\arquivo\` e `json\` (fora do git).

Ligar ou desligar a pasta do jogo (PowerShell, jogo fechado; sem `-Aplicar` é só prévia):

```powershell
& "C:\GMS\Claude Code Projects\wow\modder\ferramentas\dev-link.ps1" -Pasta "C:\GMS\Claude Code Projects\wow\modder\addons-proprios\PregaoForever" -Aplicar
& "C:\GMS\Claude Code Projects\wow\modder\ferramentas\dev-link.ps1" -Pasta "C:\GMS\Claude Code Projects\wow\modder\addons-proprios\PregaoForever" -Remover -Aplicar
```

Trocar o tamanho da janela depois de medir: `janela = { w, h, escala }` no `Config.lua` e `/reload`. Os quadros: `:root { --W; --H; --S }` no topo de `pesquisa\telas\telas.html` e `node renderizar.mjs` em `pesquisa\telas`.

## Gotchas

- **Subagentes em paralelo na mesma pasta se atropelam.** Na onda 1, o A2 sobrescreveu com um provisório o `Dados.lua` que o A4 tinha gerado. Contorno usado na onda 2: cada tarefa numa cópia própria da pasta (`--addon <cópia>`) e só no fim copia os seus arquivos de volta.
- **Cenário de unidade escrito contra falsos quebra na integração.** Asserção `ns.faixa == nil` falha quando o Cofre real liga "Press L to reconcile"; troca de `ns.banco.cod` inteiro derruba o fechamento da sessão. Confira faixas por `ns.faixaLigada(nome)` e espie só a função que precisa.
- **O contrato tem de fixar o formato do retorno, não só o nome.** `Correio.painel()` devolvia números e as Telas esperavam listas; hoje `faturas` e `aCaminho` são listas, e `nFaturas` e `ouro` são os números do Cofre.
- **Os exemplos da gramática não pegam tudo.** A ida e volta com o SavedVariables gravado pela bancada achou o anel de fotos (lista) e a lista de ações da sessão; rode `dados-04` e o `ler-pregao.mjs` no arquivo gerado depois de mexer no Banco.
- **Ordem real dos eventos no cliente:** eco de compra antes do `PLAYER_MONEY`; `AUCTION_CANCELED` também para o leilão comprado (observado em 16/11/2026, uma compra). O Ecos agora trata as duas ordens.
- **Print Screen pelo acesso remoto:** não testado; o dono colou os resultados no chat. `/run Screenshot()` tira a captura de dentro do jogo e grava em `_forever_\Screenshots`, que o agente lê.
- **Outra sessão no mesmo repositório (frente crafts-que-pagam).** Ela usa `ferramentas\pregao` e `dados\pregao\cache` e mexe no `estado.md`, no `HANDOFFS.md` e no GuiaForever. Commit só por caminho; o addon e as ferramentas dele ficam em `addons-proprios\PregaoForever` e `ferramentas\guia\pregao`.
- **O `ler-pregao.mjs` grava cópia e JSON a cada leitura.** Em teste com arquivo falso, apague o que ele gravou em `dados\pregao\arquivo` e `json`.

## Estado do repo e da plataforma

- **`C:\GMS`** (branch `main`): `ea69e41` "fix(wow): PregaoForever, primeira noite no jogo: ecos de compra, Mine e sonda", sobre `9c4a125` "feat(wow): PregaoForever ondas 1 e 2, regua em modo leitura". Sem push. No começo da sessão o `main` estava 5 commits atrás do remoto e a máquina "escritorio" sem sync de saída (inferido: aviso de sincronização de 16/11/2026); rode o Sincronizar antes de trabalhar em outra máquina.
- **Sem commit:** `estado\estado.md` (minha entrada de diário e pendências, misturada com as da frente crafts-que-pagam) e este handoff com o `HANDOFFS.md`.
- **Invisível ao repositório:** a junction `Interface\AddOns\PregaoForever` no Avell; o banco `PregaoForeverDB` (271 KB) nas SavedVariables do Avell, com `sonda.S1`, `S9` (falso), `S12` e `S13`; o backup do `dev-link.ps1` em `%LOCALAPPDATA%\wow-agentes\backups\`; as cópias de trabalho dos subagentes no scratchpad da sessão, que um reinício apaga.

## Referências rápidas

| Preciso de | Onde |
|---|---|
| Limites e relatório de sessão do WoW | `C:\GMS\Claude Code Projects\wow\CLAUDE.md` |
| Contrato dos módulos, gramática do banco, formato dos cenários | `addons-proprios\PregaoForever\ARQUITETURA.md` |
| Ondas, portões e linha do tempo | `DESIGN.md`, seção 17 |
| Decisões do dono e padrões | `DESIGN.md`, seção 18; `Config.lua` |
| Comandos da S0 e passos da sonda | `DESIGN.md`, Apêndice A |
| Parâmetros e faixas | `DESIGN.md`, Apêndice B |
| O que já foi medido no jogo | `addons-proprios\PregaoForever\pesquisa\sonda\` |
| Quadros das telas | `addons-proprios\PregaoForever\pesquisa\telas\telas.html` |
| Pendências e diário | `estado\estado.md` |
| Como o dono usa o que já funciona (teclas, telas, painel do correio, sonda) | https://claude.ai/artifact/SVhE5CoGUNKXxN2sWGTf1p e `addons-proprios\PregaoForever\guia\guia-pregaoforever.html` |
