> Relatório de pesquisa de 2026-11-16, da onda 1 do design do PregaoForever, gravado como estava (foto do dia). `<espelho>`, `<dados>` e `<tmp>` eram pastas temporárias da sessão; o Apêndice D do `DESIGN.md` diz como refazê-las. Onde este relatório e o `DESIGN.md` divergem, vale o `DESIGN.md`.

# Relatório R4a: regras, convenções e ativos do wow-modder para o addon de day trading

Escopo: só leitura. Nenhum arquivo foi escrito, nenhum `.ps1` foi rodado, a pasta do jogo não foi tocada. Este relatório não foi gravado em `.md` porque a instrução de sistema proíbe relatório em `.md`; o conteúdo completo está aqui e no resultado estruturado. Abreviações não são usadas: os caminhos são absolutos, e a raiz do projeto é `C:/GMS/Claude Code Projects/wow`.

Marcas: [local] lido nesta máquina; [busca] listagem ou grep sem abrir o arquivo inteiro; [inferencia] conclusão minha.

## 1. Restrições de design

### 1.1 Limites fixos

Arquivo `C:/GMS/Claude Code Projects/wow/CLAUDE.md`, linhas 25 a 28 [local]:

1. Só addon pela API oficial do jogo.
2. Nada de alterar arquivo do cliente (modelo, textura, executável, dados), automação ou bot, leitura de memória, unlocker ou injeção.
3. Nunca contornar os "secret values" de combate nem as funções protegidas, nem em addon próprio.
4. Na pasta do jogo só se escreve em `<pasta do Forever>\Interface\AddOns` e `<pasta do Forever>\WTF`, pelos scripts do modder, com o jogo fechado e backup antes.

Esses limites não têm data no arquivo. O limite 2 é o que mais pesa para leilão: compra ou postagem automática cai em "automação ou bot" [inferencia].

### 1.2 Fronteira de gameplay (texto exato)

`CLAUDE.md`, linha 15 [local]:

> Gameplay (builds, talentos e rotação, leveling e rota de quests, economia e profissões, táticas de dungeon e raide) vem das fontes que o dono escolheu, em `comum\fontes\`, e nenhum agente dá opinião própria de gameplay. Quando uma decisão depende de gameplay e não há fonte, pergunte ao dono qual fonte seguir.

`C:/GMS/Claude Code Projects/wow/modder/.claude/agents/wow-modder.md`, linha 16, repete a regra e cita "economia e profissões". Em `C:/GMS/Claude Code Projects/wow/comum/fontes/economia/` existe uma única fonte, `studen-ouro-leveling.md`, com "seguir" a decidir (`C:/GMS/Claude Code Projects/wow/jogadores/guilherme/estado/estado.md`, linha 155, 2026-11-07) [local]. Portanto a estratégia de compra e venda não tem fonte aprovada.

### 1.3 Nada configurado dentro do jogo

- `C:/GMS/Claude Code Projects/wow/modder/addons-proprios/UIForever/LEIA-ME.md`, linha 3, diz que o addon aplica a UI no login "para o dono não configurar nada dentro do jogo" (2026-11-05). É paráfrase do modder, sem citação direta do dono [local].
- `C:/GMS/Claude Code Projects/wow/modder/addons-proprios/UIForever/Config.lua`, linhas 1 a 2, diz a mesma coisa no cabeçalho [local].
- `wow-modder.md`, linha 82: "Dentro do jogo você não clica: dê passos numerados e curtos." (regra do agente, sem data) [local].

### 1.4 Texto do jogo em inglês

- `C:/GMS/Claude Code Projects/wow/modder/addons-proprios/GuiaForever/ARQUITETURA.md`, linha 16 (regra 1): "Texto que aparece no jogo em inglês; comentários em português sem acento" [local].
- `C:/GMS/Claude Code Projects/wow/modder/addons-proprios/GuiaForever/LEIA-ME.md`, linha 62: "Desde a 0.7.0, todo o texto do jogo está em inglês." O trecho está na seção 1.0 (2026-11-06). O número "0.7.0" não casa com a numeração atual 1.x; não verifiquei a origem [local].
- Exceção: o `!KitAmigo` é em português porque "o amigo não fala inglês" (`estado.md`, linha 163, 2026-11-08) [local].

### 1.5 Sem despejo de informação e sem fonte na tela

- `ARQUITETURA.md`, linha 326 (C1): "A janela nunca mostra a fonte. Bloco não tem campo `fonte`, e nenhum texto, sub ou dica contém "Source" ou o nome de uma fonte entre parênteses." [local]
- `ARQUITETURA.md`, linha 327 (C2): cada seção mostra no máximo 5 linhas (6 em tabela), com "Show N more" [local].
- `GuiaForever/LEIA-ME.md`, linha 21, na seção 1.2 (2026-11-08): decisões do dono, "nada de fonte na tela e nada de despejar informação". A citação do dono é: "Só quero que esteja organizado e estruturado para eu acompanhar bem". Esta linha é paráfrase do modder misturada à citação; a citação é literal [local].
- `estado/estado.md`, linha 160 (2026-11-08 tarde): "nem ligo mais pra fonte dela" [local].

### 1.6 Registro para uma sessão nova

- Abertura (`wow-modder.md`, linhas 43 a 52): roda a auditoria e responde em até 5 linhas.
- Fechamento (`wow-modder.md`, linhas 108 a 110): entrada do diário em `estado/estado.md`, com data, o que mudou, decisões e pendências.
- Diário do addon: `UIForeverDB.log`, últimas 60 linhas, em `WTF/Account/<conta>/SavedVariables/UIForever.lua`; leia com o jogo fechado (`UIForever/LEIA-ME.md`, linha 63) [local].
- GuiaForever: `ns.log` grava até 60 linhas em `GuiaForeverDB.log` (`ARQUITETURA.md`, linha 65) [local].

### 1.7 Relatório de sessão

`CLAUDE.md`, linhas 43 a 56 [local]: todo trabalho que mudou algo termina com relatório, antes da pergunta de commit, mesmo sem pedido. Partes na ordem: Resumo, No jogo, Addons, Bastidores, Decisões, Testar no próximo login, Pendências e Registro. Vazias são omitidas. Pedido do dono de 2026-11-06 (linha 45). Commit só com ok do dono (linha 37).

### 1.8 Regra do que o addon escreve

- `UIForever/LEIA-ME.md`, linha 16: "Cada valor só é gravado quando muda no `Config.lua` (controle em `UIForeverDB.aplicado`); fora isso, o que o dono mudar pelo jogo fica."
- Linha 21: o addon só troca ou esvazia um slot enquanto o conteúdo for o que ele mesmo pôs. Origem: "relato do dono em 2026-11-05" (linha 22).
- Linha 24: CVars são gravadas uma vez por personagem; o que o dono muda depois no menu fica.
- Linha 49: `/uif bars` "é o único caminho que passa por cima do botão do dono, e só roda quando o dono digita."
- Linha 37: barra 5 desligada em 2026-11-15, citação do dono: "não preciso dessa barra". O addon acatou com `actionbar.bar5.enabled = false`.
- `UIForever/Config.lua`, linhas 10 a 11, repete a regra no código.

### 1.9 Idioma e estilo dos arquivos

| Aspecto | Regra ou fato | Evidência | Marca |
|---|---|---|---|
| Só ASCII | Regra escrita para GuiaForever: "Lua 5.1 e só ASCII, sem acento nem em comentário" | `GuiaForever/ARQUITETURA.md`, linha 16; `ferramentas/guia/checar-lua.mjs`, linha 17 (ERRO fora do ASCII) | [local] |
| Só ASCII na prática | Zero arquivos `.lua` em `addons-proprios` com caractere fora do ASCII (busca em todos os `.lua`, incluindo `UIForever`, `Modelo` e `!KitAmigo`) | busca por byte não ASCII em `C:/GMS/Claude Code Projects/wow/modder/addons-proprios` | [local] |
| Comentários | Português sem acento | `GuiaForever/GuiaForever.lua`, linhas 1 a 3 ("Logica; os dados ficam em Dados.lua") | [local] |
| Arquivos | Nomes em português (Estado, Janela, Agora, Visual) | listagem de `GuiaForever/` | [local] |
| Funções | Português, namespace `ns` (`ns.foraDeCombate`, `ns.teclaDe`, `ns.relevante`); UIForever usa `aplicarBarras`, `montarPlano`, `somarQuests` | `GuiaForever/Estado.lua`, linhas 1 a 3; `UIForever/UIForever.lua`, linhas 308, 339, 706 | [local] |
| APIs e eventos | Nomes do cliente, em inglês | `ARQUITETURA.md`, seção 1 | [local] |
| Cabeçalho do arquivo | `local _, ns = ...` | `ARQUITETURA.md`, linha 17 (regra 2) | [local] |
| Globais | Só com prefixo `GuiaForever`, `SLASH_GUIAFOREVER` ou `BINDING_` | `ARQUITETURA.md`, linha 17 | [local] |
| Modelo | Comentário em português, "Modelo de addon do dono." | `addons-proprios/_modelo/Modelo/Modelo.lua`, linha 1 | [local] |

Não existe regra escrita de ASCII para UIForever nem para o Modelo. Na prática os arquivos cumprem a regra.

## 2. Formato do ARQUITETURA.md do GuiaForever

Arquivo: `C:/GMS/Claude Code Projects/wow/modder/addons-proprios/GuiaForever/ARQUITETURA.md` (58 KB, 564 linhas). Ele se declara "o contrato entre os módulos: quem muda uma API aqui muda o contrato junto" (linha 3).

| Seção | Linha | Tipo de conteúdo |
|---|---|---|
| Cabeçalho (objetivo, quatro peças) | 1 a 10 | Texto de objetivo |
| 1. Regras que valem para todo arquivo | 12 a 26 | Tabela de 11 regras numeradas |
| Assinaturas conferidas no espelho | 28 a 43 | Tabela função / retorno, com data |
| 2. Ordem de carga do `.toc` | 44 a 46 | Lista ordenada de arquivos e `OptionalDeps` |
| 3. `Estado.lua`: base comum | 48 a 69 | Tabela API / contrato, lista de eventos |
| 4. `Agora.lua`: o painel | 71 a 134 | Tabela API, tabela de campos do item, tabela de aspectos, tabela de prioridades, tabela de provedores |
| 5. `Arvore.lua` | 135 a 138 | Prosa curta com contrato |
| 6. `Pet.lua` e `Tooltips.lua` | 139 a 190 | Tabelas de itens e fases; regra de macro com corpo em bloco |
| 7. Dados | 191 a 235 | Tabela de campos opcionais, lista de 6 casos de relevância, esquema em bloco, regras de fonte |
| 8. Janela J e comandos | 236 a 262 | Tabela de ids de aba e de apelidos antigos |
| 9. UIForever 0.6.0 | 263 a 266 | Contrato em prosa (margem) |
| 10. Guia de pets | 267 a 317 | Subseções 10.1 (arquivos), 10.2 (esquema), 10.3 (API), 10.4 (PDF) |
| 11. Janela J 1.2 | 318 a 447 | Subseções 11.1 (curadoria C1 a C7), 11.2 (casca, medidas), 11.3 (construtores), 11.4 (tabela de tipos de bloco), 11.5 (`ns.ui`), 11.6 a 11.7 (dados e chaves), 11.8 (banco), 11.9 (como ficou) |
| 12. Paladino (1.3) | 448 a 564 | Subseções 12.1 a 12.7; 12.4 traz a exceção de combate |

Padrão reaproveitável: cada módulo tem uma tabela "API | Contrato"; as regras são numeradas; o esquema de dados vem em bloco de código; a seção "Como ficou" registra o que mudou depois da execução (linhas 431 e 549).

### Regras de combate impostas

- Regra 4 (linha 19): em combate, proibido `CreateMacro`, `EditMacro`, `DeleteMacro`, `SetBinding*`, `SaveBindings`, `PickupAction`, `PlaceAction`, `SetCVar`, `SetAttribute` e `SetUIPanelLayoutAttribute`. Use `ns.foraDeCombate`, ou `if ns.emCombate() then ... return end`, ou o comentário `-- fora-de-combate` na linha de cima.
- Regra 5 (linha 20): proibido ler API que vira secreta: `UnitAttackSpeed`, `UnitRangedDamage`, `UnitRangedAttackPower`, `GetUnitSpeed`, `C_Spell.GetSpellCooldown`, `GetSpellCharges`, `C_UnitAuras.*`. Proibidos eventos quentes: `COMBAT_LOG_EVENT_UNFILTERED`, `UNIT_AURA`, `SPELL_UPDATE_COOLDOWN`. Em tooltip, sair se `InCombatLockdown()` ou se `issecretvalue` disser que o dado é secreto.
- Exceção da 12.4 (linha 505): `C_UnitAuras.GetAuraDataBySpellName` e `GetPlayerAuraBySpellID` só fora de combate, numa função com a guarda da regra 4 e com `issecretvalue`.
- Regra 6 (linha 21): quadro da Blizzard só por `hooksecurefunc`, `HookScript`, `EventRegistry` ou `TooltipDataProcessor`; nada de `SetScript` em quadro alheio.
- Regra 10 (linha 25): função de evento, timer ou clique roda em `xpcall(fn, geterrorhandler())`.
- Regra 7 (linha 22): proibidos `C_Traits.PurchaseRank`, `CommitConfig`, `BuyTrainerService`, `CastSpell*` e `UseContainerItem`, por decisão do dono de 2026-11-06. "O guia marca e o dono clica."
- Regra 9 (linha 24): addon de terceiro só por chamada em tempo de execução, com `pcall`.

Essas regras são checadas por `checar-combate.mjs` (R1 a R9, ver item 3).

## 3. Checadores estáticos

Todos ficam em `C:/GMS/Claude Code Projects/wow/modder/ferramentas/guia/`. `package.json` declara `luaparse` 0.3.1 (dependência) e `fengari` ^0.1.5 (dev); `node_modules` já existe [local]. O comando para rodar é `node <script> ...` a partir dessa pasta.

| Script | O que confere | Comando | O que um addon novo precisa |
|---|---|---|---|
| `checar-lua.mjs` (58 linhas) | Sintaxe Lua 5.1 via luaparse (linha 19); ASCII (linha 17); escape inválido em string (linhas 21 a 45); globais com `--globais` (linhas 47 a 56) | `node checar-lua.mjs <pasta> [--globais]` | Só uma pasta com `.lua` na raiz (lê só o primeiro nível, linha 15). Serve para qualquer addon. |
| `checar-combate.mjs` (329 linhas) | R1 protegida sem guarda (linhas 280 a 286); R2 API secreta (287 a 290); R3 `SetScript` global alheio (253 a 255); R4 global fora dos prefixos (232 a 241); R5 evento quente (257 a 272); R6 evento inexistente (270); R7 API fora da lista sem guarda (295 a 309); R8 template (274 a 278); R9 proibida (291); `--toc` confere `.toc` e pasta (313 a 323) | `node checar-combate.mjs <pasta> [--toc] [--prefixos A,B]` | (a) Globais com os prefixos `GuiaForever`, `UIForever`, `SLASH_GUIAFOREVER`, `SLASH_UIFOREVER`, `BINDING_` (linha 23), ou passados em `--prefixos`. Inferência pelo código: `SLASH_NOVO1` daria R4 sem `--prefixos SLASH_NOVO`. (b) Listas em `api-forever/` (linhas 29 a 34). (c) `.toc` com todos os `.lua`. (d) `PROIBIDAS` (linhas 48 a 49) não tem nenhuma função de leilão; compra ou postagem não seria apontada. |
| `checar-dicas.mjs` | Esquema de `Dicas.lua` (`GuiaForeverDicas`); classes fixas em linha 9 (HUNTER, SHAMAN, PALADIN); listas e campos (linhas 11 a 24) | `node checar-dicas.mjs <Dicas.lua>` | Não serve sem o mesmo esquema de dados; não é genérico. |
| `checar-ajuda.mjs` | Esquema de `Ajuda.lua`; classes (linha 10), abas fixas (linha 11), lista de fontes (linhas 14 a 25) | `node checar-ajuda.mjs <Ajuda.lua>` | Idem: específico do GuiaForever. |
| `rodar-casos.mjs` | Roda os casos de `casos/` contra `checar-dicas` e `checar-ajuda` (linhas 10 a 17) | `node rodar-casos.mjs` | Testa os checadores, não o addon. |
| `rodar-casos-combate.mjs` | Roda `checar-combate` em `casos-combate/` (linhas 9 a 17), incluindo `prefixos` (linha 15) e `toc` (linha 16) | `node rodar-casos-combate.mjs` | Testa o checador. |
| `rodar-janela.mjs` (72 KB) | Banco de prova da janela J (item 4) | `node rodar-janela.mjs [--estrito] [--abrir] [--desenhar] ...` | Não serve a outro addon: caminho fixo em linha 35 e `GuiaForever.toc` fixo em linha 942. Precisa ser adaptado. |

Fora desta lista, em `visual/` (`renderizar.mjs`, `magias.mjs`) e `pets/` (seis checadores, `LEIA-ME.md` linhas 152 a 158), não li os scripts.

Lacuna para leilão: a lista de API (`api-forever/GlobalAPI.lua`) tem os nomes de `C_AuctionHouse`, mas nenhum checador confere se a compra ou a postagem exige clique do dono (ver item 4 e implicação 2).

## 4. Bancada: `rodar-janela.mjs`

Cabeçalho (linhas 1 a 26): roda os `.lua` do `.toc` no fengari (Lua 5.3 em JavaScript) com a API do jogo simulada num estado fixo. Lua 5.3 não é o 5.1 do jogo; diferenças que o banco não esconde estão nas linhas 24 a 26.

### O que simula

- Relógio e fila de timers: `GetTime` (linha 149); `enfileirar` (linhas 150 a 153); `C_Timer.After`, `NewTimer` e `NewTicker` (linhas 160 a 164); `NewTicker` "roda uma vez só" (linha 163); `__esvaziar` ordena por tempo e sequência e roda (linhas 165 a 174); `Cancel` (linhas 156 a 157).
- Quadros falsos: `novoQuadro` (linhas 188 a 192); métodos de quadro (linhas 195 a 257); método desconhecido com maiúscula devolve nada (linha 183); `CreateFrame` (linhas 259 a 266); `CreateFont` (linhas 267 a 271).
- Eventos: `RegisterEvent` (linhas 199 a 205); `__disparar` chama `OnEvent` e os ganchos (linhas 274 a 287).
- Ganchos: `hooksecurefunc` embrulha a global (linhas 289 a 299).
- Combate: `InCombatLockdown()` sempre devolve falso (linha 300). Combate não é simulado.
- Estado fixo do personagem: caçador Night Elf nível 16 em Darkshore, ou paladino Human nível 27 em Elwynn com a flag `--classe PALADIN` (linhas 330 a 369). `GetBuildInfo` devolve build `70790` (linha 313), desatualizada.
- APIs por tabela (`mkapi`, linhas 444 a 450): `C_SpellBook` (455), `C_Spell` (468), `C_PetInfo` (472), `C_ClassTalents` (479), `C_Traits` (480), `C_SkillInfo` (484), `C_QuestLog` (496), `C_Map` (502), `C_Minimap` (522), `C_Item` (528, só `GetItemInfo` devolve nil), `C_Container` (529 a 532, sem slots e sem itens), `C_CVar` (533), `C_AddOns` (534), `C_Trainer` (535), `C_TooltipInfo` (536, só `GetItemByID`).
- Só no paladino ou no filho do caçador: `C_UnitAuras`, `issecretvalue` e as APIs de macro (linhas 541 a 570).
- Sequência fixa de eventos (linhas 649 a 656): `ADDON_LOADED`, `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `SPELLS_CHANGED`, `UNIT_PET`, `PET_BAR_UPDATE`, `QUEST_LOG_UPDATE`.
- Globais não definidas que o código lê são anotadas em `__acessados` (linhas 581 a 584).

### Como carrega um addon

Lê o `.toc` do GuiaForever (linha 942), carrega cada `.lua` com `load` e o `ns` compartilhado (linhas 641 a 647 e 946 a 953), roda a sequência (linha 955), monta as abas (`__plano` e `__construir`, linhas 666 e 697), confere os blocos contra a seção 11 do `ARQUITETURA.md` (a partir da linha 963) e grava `real.json` e `real.html`. Saída 0, 1 ou 2 (linha 22).

### Globais que precisariam de versão falsa para uma casa de leilões

| Global | Onde está a lista no Forever | O que a bancada faz hoje |
|---|---|---|
| `C_AuctionHouse.*` (busca `SendBrowseQuery`, `SendSearchQuery`, `GetItemSearchResultInfo`, `GetCommoditySearchResultInfo`; venda `PostItem`, `PostCommodity`, `ConfirmPostItem`; compra `PlaceBid`, `StartCommoditiesPurchase`, `ConfirmCommoditiesPurchase`; `GetOwnedAuctions`, `CancelAuction`, `IsThrottledMessageSystemReady`, `MakeItemKey`, `GetItemKeyInfo`) | `ferramentas/guia/api-forever/GlobalAPI.lua`, linhas 331 a 416 [local] | Nada |
| `Enum.AuctionHouse*` (`SortOrder`, `Filter`, `TimeLeftBand`, `Error` e outros) | `api-forever/LuaEnum.lua`, linhas 365 a 446 [local] | `Enum` não tem nenhum (linhas 320 a 328) |
| `AuctionHouseFrame` e eventos `AUCTION_HOUSE_SHOW`, `CLOSED`, `BROWSE_RESULTS_UPDATED`, `THROTTLED_*` | `api-forever/Frames.lua`, linha 395; `Events.lua`, linhas 94 a 120 [local] | Nenhum evento de leilão é disparado |
| `GetMoney` e `C_CurrencyInfo.GetCoinTextureString` | `GlobalAPI.lua`, linhas 5611 e 1380 [local] | Ausentes |
| `C_Item.GetItemInfo` e `C_Item.RequestLoadItemDataByID` | `GlobalAPI.lua`, linhas 2525 e 2597 [local] | `GetItemInfo` devolve nil (linha 528); `RequestLoad...` ausente |
| `C_Container.GetContainerItemInfo` | `GlobalAPI.lua`, linha 1225 [local] | Vazio (linhas 529 a 532) |
| `GetServerTime` | `GlobalAPI.lua`, linha 5867 [local] | Ausente |
| `C_Timer.NewTicker` (repetição de varredura) | `GlobalAPI.lua`, linha 4175 [local] | Roda uma vez só (linha 163) |
| `InCombatLockdown` | — | Sempre falso (linha 300) |

## 5. `dev-link.ps1` e scripts de WTF

Base comum (`ferramentas/wow-comum.ps1`): `Test-JogoAberto` (linhas 317 a 328) considera o jogo aberto se um processo tem caminho dentro da pasta do jogo, ou se a variável `WOWAGENTE_JOGO_ABERTO` diz isso. `Assert-JogoFechado` (linhas 330 a 333) recusa com `RECUSA`. A detecção roda na máquina onde o script roda, o Avell.

| Script | O que faz | Prévia | `-Aplicar` | Jogo fechado | Evidência |
|---|---|---|---|---|---|
| `dev-link.ps1 -Pasta <dir>` | Liga `addons-proprios\<nome>` a `AddOns\<nome>` por junction; manifesto `dev-<slug>` (slug em minúsculas, o que não é `[a-z0-9-]` vira `-`) | `DEV acao=ligar` (linhas 46 a 47) | cria junction (linha 51), grava manifesto (linhas 60 a 81) | `Assert-JogoFechado` (linha 48) | `dev-link.ps1`, linhas 22 a 23, 33 a 84 |
| Recusas do ligar | Destino pasta comum (42); junction de outro alvo (40); pasta sem `.toc` (29); nome de outro addon (44) | — | — | — | `dev-link.ps1`, linhas 29, 40, 42, 44 |
| `dev-link.ps1 -Remover` | Remove só a junction; `Directory.Delete` sem recursão, alvo intacto | `DEV acao=remover` (linha 99) | apaga junction e marca manifesto como removido (103 a 108) | linha 101 | `dev-link.ps1`, linhas 87 a 111; `CONTRATO.md`, §9.5 |
| `wtf-backup.ps1` | Zip do WTF em `Backups\sessoes\<carimbo>\WTF.zip`, guarda 20 | — (não grava no jogo) | sempre grava o zip | roda com jogo aberto, com aviso (linhas 16 a 18) | `wtf-backup.ps1`, linhas 14 a 23; `CONTRATO.md`, §3 |
| `wtf-cvar.ps1 -Valores 'nome=valor;...'` | Muda CVars no `Config.wtf` | `CVAR nome=... atual=... novo=...` (linhas 33 a 37) | copia `Config.wtf` para `Backups\cvars` (guarda 20), grava (linhas 44 a 57) | `Assert-JogoFechado` (linha 42); `PREREQ` sem `Config.wtf` (linha 30) | `wtf-cvar.ps1`, linhas 15 a 60 |
| `wtf-sv.ps1 -Arquivo <nome.lua> -Valores 'caminho=valor;...'` | Muda valores de SavedVariables de conta única; caminho por pontos, `*` para todas as chaves; sem interpretador Lua, preserva BOM e quebras | `SV arquivo=... caminho=... atual=... novo=...` (`CONTRATO.md`, linha 283) | roda `wtf-backup` antes (filho com rótulo `antes-de-sv`; falha = `ERRO`, nada gravado), grava, registra `sv` (`CONTRATO.md`, 284; script linha 333) | `Assert-JogoFechado` (`wtf-sv.ps1`, linha 321) | `CONTRATO.md`, linhas 278 a 284; liberado pelo dono em 2026-11-05 (`CLAUDE.md`, linha 86) |
| `wtf-restaurar.ps1 -De <pasta ou zip>` | Restaura um backup do WTF | `PREVIA acao=restaurar-wtf` (linha 36) | backup `antes-de-restaurar` (linha 46); move WTF para `.wowbak` e extrai (56 a 60); desfaz em erro (62 a 68); apaga `.wowbak` no sucesso (70 a 73) | `Assert-JogoFechado` (linha 41) | `wtf-restaurar.ps1`, linhas 15 a 83 |

Regra comum (`wow-modder.md`, linha 41): todo script que grava mostra prévia por padrão, só grava com `-Aplicar`, recusa com o jogo aberto e faz o próprio backup. Códigos: 0 ok, 1 recusa ou diferença, 2 pré-requisito, 3 erro (`CONTRATO.md`, §4).

Consequência para a operação remota [inferencia]: com o jogo aberto no Avell, nenhum desses scripts grava. Mudança de configuração do addon exige logout.

## 6. Convenções de TOC dos addons próprios

| Campo | GuiaForever | UIForever | Modelo |
|---|---|---|---|
| `## Interface` | 16001 (`GuiaForever.toc`, linha 1) | 16001 (`UIForever.toc`, linha 1) | 16001 (`Modelo.toc`, linha 1) |
| `## Title` | GuiaForever (linha 2) | UIForever (linha 2) | Modelo (linha 2) |
| `## Author` | Guilherme | Guilherme | Guilherme |
| `## Version` | 1.3.1 (linha 5) | 0.7.0 (linha 5) | 0.1.0 (linha 5) |
| `## SavedVariables` | `GuiaForeverDB` (linha 6) | `UIForeverDB` (linha 7) | nenhuma |
| `## SavedVariablesPerCharacter` | nenhuma | `UIForeverCharDB` (linha 8) | nenhuma |
| Dependências | `OptionalDeps`: Questie, QuestieDB, TomTom, NaowhForever, NaowhForever_Training, RXPGuides (linha 7) | `Dependencies: ElvUI` (linha 6) | nenhuma |
| Comando de barra | `/guia`: `SLASH_GUIAFOREVER1` (`GuiaForever.lua`, linhas 495 a 496) | `/uif` e `/uiforever` (`UIForever.lua`, linhas 537 a 538) | `/modelo` (`Modelo.lua`, linha 4) |
| Binding | `BINDING_NAME_GUIAFOREVER_JANELA` (`Janela.lua`, linha 640) | `UIFOREVER_MINIMAPA` (`Config.lua`, linha 5; `Bindings.xml`) | nenhum |
| Arquivos `.lua` | 22 (linhas 8 a 29) | 2 | 1 |

Observação: `Interface 16001` também está no TOC do Auctionator (`estado/addons/auctionator.json`, linha 20). A linha 6 do `Modelo.toc` lembra que a Interface tem de bater com a do cliente.

Interface é lida do cliente, nunca de memória (`CLAUDE.md`, linha 21). Interface 16001 ficou sem mudança nas aberturas de 2026-11-06 e 2026-11-07 (`estado/estado.md`, linhas 150 e 156), e `estado/sessao.json` traz `ultimaInterface 16001` e `ultimaVersao 1.60.1.70862` (2026-11-08) [local].

Versão: o TOC repete a do LEIA-ME. Desvio: a barra 5 foi desligada em 2026-11-15 (`UIForever/LEIA-ME.md`, linha 37), mas o TOC continua em 0.7.0.

### Onde um addon novo mora e como se nomeia

- Mora em `addons-proprios/<Nome>`, copiado de `_modelo/Modelo` (`addons-proprios/LEIA-ME.md`, linhas 14 a 20).
- Liga ao jogo com `dev-link.ps1`, primeiro em prévia e depois com `-Aplicar`, com o jogo fechado (`LEIA-ME.md`, linhas 18 a 19).
- Ciclo: `/reload` para `.lua` alterado; reinício do jogo para `.toc` ou arquivo novo (`LEIA-ME.md`, linhas 22 a 26; `wow-modder.md`, linha 104).
- Padrão de nome: `<Nome>Forever` (GuiaForever, UIForever); modelo `Modelo`; o do amigo é `!KitAmigo`, com `!` (`LEIA-ME.md`, linha 40). O slug do `dev-link` do `!KitAmigo` seria `dev-kitamigo`, pelo código (`dev-link.ps1`, linhas 22 a 23) [inferencia].

## 7. Três ondas de execução e diário de calibração

### Padrão das três ondas

Não há regra normativa única que defina "três ondas". O padrão aparece em notas de diário e em contratos:

- `estado/estado.md`, linha 154 (2026-11-06, 22h30): contratos em `ARQUITETURA.md` e esqueletos no `.toc` feitos pela sessão principal; onda 1 com checadores de dados (Haiku), checador de combate e API (Sonnet), `Estado.lua` (Sonnet) e UIForever 0.6.0 (Sonnet); onda 2 com dados (Haiku), painel Agora (Sonnet), pet e treinador (Sonnet) e consertos (Haiku); onda 3 com marcas, tooltips, rastreador e calibração; "portões na sessão principal" corrigem o que sai.
- `estado/estado.md`, linha 160 (2026-11-08 tarde): GuiaForever 1.2.0 "em três ondas (contrato, T1 a T3, T4 a T7) e portão final; um banco de prova ... foi o critério de pronto de cada tarefa."
- `GuiaForever/ARQUITETURA.md`, linha 433 (11.9), mesmo padrão. Linha 551 (12.7): duas ondas para o paladino. `estado/estado.md`, linha 166: "duas ondas de subagentes (2 Haiku high, 4 Sonnet medium), sem escalonamento".
- `ferramentas/CONTRATO.md`, linhas 3 e 22: ondas 2 a 4 da construção das ferramentas, com o contrato congelado.

Resumo do padrão (inferido das notas): onda 0 é o contrato e os esqueletos, feitos pela sessão principal; ondas seguintes são subagentes por tarefa, com dados em Haiku e código em Sonnet; cada tarefa só está pronta quando o banco de prova ou o checador dá 0 erro (por exemplo `RESUMO erros=0`); um portão final na sessão principal roda tudo. Nada disso rodou no jogo até o momento em que a nota foi escrita.

### Diário de calibração

Arquivo: `GuiaForever/Zona.lua`.

- Cabeçalho (linhas 1 a 3): o diário de calibração grava `skinCores`, `skinLog` e `skinAprendidos`.
- Limite (linha 10): `MAX_DIARIO = 400`; `empurrar` corta o mais antigo (linhas 393 a 395).
- Estimativa e calibração (linhas 12 a 15): `FAIXAS = { laranja = 24, amarelo = 50, verde = 100 }`. Laranja foi calibrado por uma transição (nightsaber nível 6); amarelo e verde seguem estimados.

Os três sinais:

| Sinal | O que grava | Gatilho | Linhas |
|---|---|---|---|
| `skinCores` | Cor do cliente da linha "Skinnable" do cadáver, com id, nível, perícia e RGB | Uma vez por bicho e perícia, se a cor não for valor secreto | 445 a 458 (secreto checado na linha 451) |
| `skinLog` | Perícia antes e depois de uma esfola | `UNIT_SPELLCAST_SUCCEEDED` de Skinning, com 1 s de espera | 522 a 545 |
| `skinAprendidos` | Bichos aprendidos, com nome e nível | Ao encontrar a criatura | 436 a 438 |

Procedimento de calibração: "com o jogo fechado, ler `skinCores` e `skinLog` no `GuiaForever.lua` das SavedVariables e trocar as `FAIXAS` de `Zona.lua` pelos números reais" (`estado/estado.md`, linha 116, 2026-11-06). Resultado em 2026-11-07: laranja 24 por uma transição; amarelo e verde seguem estimados (`GuiaForever/LEIA-ME.md`, linha 138).

O diário é lido por arquivo, com o jogo fechado. Com a operação remota e o jogo aberto, esse ciclo não roda (ver implicação 3).

## Incógnitas

1. Lista da API e build atual. A lista é de build 70532 e o cliente de 70840 quando foi baixada (`ferramentas/guia/api-forever-baixar.txt`, linhas 1 a 3). O pedido cita build 70938. Como conferir: no jogo, `/dump C_AuctionHouse ~= nil` e `/dump select(4, GetBuildInfo())`; no Acer, rodar o comando de `api-forever-baixar.txt` de novo.
2. Valor secreto em `C_AuctionHouse`. Nenhum documento do projeto diz se alguma função devolve valor secreto. Como conferir: a doc `Blizzard_APIDocumentationGenerated` no espelho `Ketho/wow-ui-source-forever` (branch `forever`), e, no jogo, `issecretvalue` sobre o retorno.
3. Limite de frequência (throttle). A lista tem `C_AuctionHouse.IsThrottledMessageSystemReady` e eventos `AUCTION_HOUSE_THROTTLED_*`, mas não há fonte aberta sobre a cadência. Como conferir: na casa de leilão, chamar `C_AuctionHouse.IsThrottledMessageSystemReady()` e mandar duas buscas seguidas, e ver se o evento de throttle aparece no BugSack.
4. Sobreposição com o que já está instalado. Auctionator 341 e Forever Guide têm papel de preço e leilão (`estado/addons/auctionator.json`; `estado/estado.md`, linhas 30 e 121). Como conferir: abrir a casa com os três ativos e ver se há tooltip duplicado ou erro no BugSack. Se houver, a regra "dois addons no mesmo papel não entram juntos" (`wow-modder.md`, linha 76) decide.
5. Papel do addon: alerta ou ação. Comprar e postar por código vão contra o limite 2 e a regra 7 do GuiaForever (`ARQUITETURA.md`, linha 22). Cabe ao dono decidir se quer só aviso, e quais fontes de economia seguir (`comum/fontes/economia` tem uma fonte, com decisão pendente). Não há o que testar no jogo; é decisão do dono.
6. Diário com o jogo aberto. Os scripts recusam com o jogo aberto, e o projeto lê o diário só com o jogo fechado (`UIForever/LEIA-ME.md`, linha 63). Não verifiquei se o diário é gravado em disco sem logout. Como conferir: escrever uma linha no diário, dar `/reload`, e ver se o arquivo muda antes de sair do jogo.

## Desvios

1. O relatório R4a não foi gravado em `R4a.md`, porque a instrução de sistema proíbe relatório `.md`. O conteúdo está neste texto e no resultado estruturado.
2. O padrão "três ondas" não tem regra normativa única; montei o padrão a partir das notas de `estado/estado.md` e de `ARQUITETURA.md` (inferência).
3. Além da lista do briefing, li `estado/estado.md` (linhas 116, 150 a 166), `estado/addons/auctionator.json`, `estado/sessao.json`, `GuiaForever/Zona.lua` (trechos), `ferramentas/wtf-restaurar.ps1`, trechos de `ferramentas/wtf-sv.ps1` e de `ferramentas/wow-comum.ps1`, a listagem de `comum/` e `comum/fontes/`, e a lista da API por busca. Motivo: têm fatos dos itens 4, 5 e 7 e de PRJ-14.
4. Item 3: cobri os sete `.mjs` do topo de `ferramentas/guia/`. Os de `visual/` e `pets/` ficaram fora.
5. Item 2: não há seção de combate separada no `ARQUITETURA.md`; as regras de combate foram tiradas das regras 4 a 6, 10 e 12.4.
6. Não verifiquei a Interface ou o build no cliente; usei os registros do projeto.

## Resultado estruturado

Enviado em seguida pelo StructuredOutput, com o resumo, os 14 fatos (PRJ-01 a PRJ-14), as implicações, as incógnitas e os desvios acima.

Chamando o StructuredOutput agora.