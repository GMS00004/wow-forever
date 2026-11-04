# Contrato das ferramentas do wow-modder

Versão 1.1, 2026-11-03. **Congelado durante a construção (ondas 2 a 4): só a sessão principal altera.** Quem implementa segue este contrato à risca; onde ele não bastar, decida o mínimo e relate o desvio.

## 0. Adendo da versão 1.1 (depois da T4; vale por cima do resto)

A biblioteca `wow-comum.ps1` já existe e passou em 256 verificações. Leia as funções que você for usar antes de usá-las.

1. **Listas (substitui o §1.4 e os `,@(...)` do §8):** as funções devolvem a lista desenrolada, sem a vírgula, e quem chama **sempre** envolve o resultado em `@(...)`, por exemplo `$pastas = @(Find-PastasDeAddon -Pasta $x)`. Nunca escreva `$x = f` seguido de `$x[0]` sem o `@()`.
2. **Saída e código de saída:** as funções de fluxo imprimem com `Write-Host`. Todo CLI termina com `exit (Invoke-ScriptWow { ... })`: o `Invoke-ScriptWow` devolve o código e não chama `exit`.
   - Dentro do bloco, cada string devolvida é impressa, e o último `[int]` devolvido vira o código de saída. Qualquer outro objeto é descartado.
   - Cuidado com métodos que devolvem inteiro sem você pedir (`ArrayList.Add`, `List.Remove` e afins): use `[void]`, ou um inteiro solto vira código de saída.
   - Para capturar, no mesmo processo, a saída de uma função (nos testes): `$linhas = & { Install-AddonDeFonte ... } 6>&1`.
3. **`-Forcar`** libera só a incompatibilidade de TOC e a reinstalação da mesma versão. Um conflito de pasta com outro manifesto é sempre `RECUSA`.
4. **Versão de fonte `zip:`:** vale o `## Version` do TOC da primeira pasta do zip; sem ele, `zip-<8 hex do sha256 do zip>`. O "nada a fazer" se decide depois de extrair.
5. **Campos:** `(Get-TocDoForever ...).Arquivo` é o caminho completo; `(Test-AddonForever ...).Toc` é só o nome do arquivo.
6. **`Backup-Wtf`:** o zip leva `WTF/` como pasta de topo, e o `info.txt` fica ao lado do zip, na pasta da sessão. Se já existir uma pasta com a mesma hora e minuto, o nome ganha o sufixo `-ss` (segundos).
7. **`Get-WowContexto`** só completa os campos que faltarem a partir do `instalacao.json`.
8. **Ajudantes que os CLIs podem usar:** `Write-Linha`, `Get-AgoraIso`, `Read-JsonUtf8`, `Write-JsonUtf8`, `Get-CarimboBackup` e `Backup-PastasDoAddon`.
9. **`-SoCompativeis`** (em `Install-AddonDeFonte` e no `addon-instalar.ps1`; acrescentado em 2026-11-03, depois da primeira instalação real) instala só as pastas cujo TOC tem a Interface do cliente. As outras aparecem na prévia como `PASTA nome=<n> acao=ignorar motivo=<m>`; se nenhuma pasta servir, `RECUSA`. A escolha fica no manifesto como `fonte.soCompativeis`, e as atualizações seguintes reaplicam o filtro sem o parâmetro. É o caso dos pacotes de várias versões do jogo, como o DBM, que traz módulos do Midnight. `-Forcar` continua instalando tudo, sem filtro.
10. **Testes de uma tarefa da onda 3 não dependem dos CLIs de outra tarefa da mesma onda.** Prepare o estado pela biblioteca (dot-source de `wow-comum.ps1` e chamada das funções) ou escrevendo os arquivos à mão conforme o §6.

## 1. Convenções (Windows PowerShell 5.1)

1. Sem módulos externos. Todo `.ps1` salvo em **UTF-8 com BOM**; sem BOM, o 5.1 lê o arquivo como ANSI e quebra acentos (vault: PowerShell 5.1 Traps §9).
2. Nada de `[CmdletBinding()]` nos scripts, e nenhum valor padrão de `param()` usa `$PSScriptRoot` ou variável da biblioteca: os padrões se resolvem **no corpo**, depois do dot-source (Traps §3).
3. Todo script começa com `param(...)`, depois `$ErrorActionPreference = 'Stop'` e `. (Join-Path $PSScriptRoot 'wow-comum.ps1')`, e roda o corpo dentro de `Invoke-ScriptWow { ... }` (§4).
4. Lista que pode vir vazia ou com um item: funções devolvem `,@(...)` e quem chama envolve em `@(...)`. Nunca atribua o resultado de um `if` que pode devolver array vazio (vira `$null`, Traps §2).
5. Rede: antes de qualquer chamada, `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12` e `$ProgressPreference = 'SilentlyContinue'` (a barra de progresso deixa o download dezenas de vezes mais lento). Use `Invoke-RestMethod`/`Invoke-WebRequest -UseBasicParsing` com o cabeçalho `User-Agent: wow-modder`, sem e-mail, sem conta e sem chave.
6. Zip: `Add-Type -AssemblyName System.IO.Compression.FileSystem` e as classes `ZipFile`/`ZipArchive`, nunca `Expand-Archive`. Extração sempre num caminho curto (MAX_PATH): `$env:TEMP\wow-agentes\x-<8 hex>`.
7. **Junction:** nunca `Remove-Item -Recurse` num caminho que pode ser junction (no 5.1 isso apaga o conteúdo do alvo). Teste com `Test-Junction`; para remover uma junction, `[System.IO.Directory]::Delete($caminho)` sem recursão. Cópia, hash e assinatura nunca descem em junction.
8. JSON: grave com `[System.IO.File]::WriteAllText($p, ($obj | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding $false))`; leia com `Get-Content -Raw -Encoding UTF8 | ConvertFrom-Json`.
9. Datas: ISO 8601 local, `(Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')`. Carimbo de pasta de sessão `yyyy-MM-dd_HHmm`; de backup de addon `yyyy-MM-dd_HHmmss`.
10. Chamar outro script deste conjunto como processo filho: `$saida = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File <script> <args> 2>&1; $codigo = $LASTEXITCODE`. Capture a saída inteira numa variável **antes** de ler `$LASTEXITCODE` (nada de `| Select-Object -First n`, Traps §10). Em volta de executável nativo com `2>&1`, use `$ErrorActionPreference = 'Continue'` localmente.
11. Variáveis de ambiente de teste (nunca definidas fora dos testes):
    - `WOWAGENTE_JOGO_ABERTO`: `1` força "jogo aberto", `0` força "fechado"; ausente, a detecção é real.
    - `WOWAGENTE_RESPOSTAS`: pasta com respostas gravadas (§10.4); definida, nenhuma chamada de rede acontece.
    - `WOWAGENTE_FALHAR_COPIA`: nome de uma pasta de addon; `Install-Pastas` lança erro ao chegar nela (testa o rollback).

## 2. Layout

```
modder\
  ferramentas\
    wow-comum.ps1          biblioteca (só define funções)            T4
    addon-instalar.ps1     CLI de Install-AddonDeFonte                T5
    addon-remover.ps1      CLI de Remove-Addon                        T5
    addons-auditar.ps1     auditoria da pasta AddOns (só leitura)     T6
    wtf-backup.ps1         zip do WTF                                 T6
    wtf-restaurar.ps1      restaura um backup do WTF                  T6
    wtf-cvar.ps1           muda CVars no Config.wtf                   T6
    dev-link.ps1           junction de addon próprio                  T8
    addon-fontes.ps1       consulta a fonte de um addon (só leitura)  T7
    addon-atualizar.ps1    atualiza os aprovados                      T7
    sessao-abrir.ps1       abertura de sessão                         T7
    testes\
      _assert.ps1  _preparar.ps1                                      T4
      fixture\  fontes-fixture\  respostas\                          T4
      t-comum.ps1 (T4)  t-instalar.ps1 (T5)  t-auditar.ps1 t-wtf.ps1 (T6)
      t-devlink.ps1 (T8)  t-atualizar.ps1 t-sessao.ps1 (T7)
      tmp\                 (gitignored) cópias de trabalho dos testes
  estado\  addons\<slug>.json  registro.md  sessao.json
  addons-proprios\  _modelo\                                         T8
```

## 3. Parâmetros comuns e caminhos

Todos os scripts aceitam:

| Parâmetro | Padrão (resolvido no corpo) |
|---|---|
| `-Raiz <dir>` | `raiz` de `-Instalacao` |
| `-Flavor <nome>` | `flavor` de `-Instalacao` |
| `-Instalacao <arquivo>` | `<ferramentas>\..\..\comum\instalacao.json` |
| `-Estado <dir>` | `<ferramentas>\..\estado` |
| `-Backups <dir>` | `$env:LOCALAPPDATA\wow-agentes\backups` |
| `-Aplicar` (só nos que gravam) | ausente: só prévia |

Os testes passam sempre `-Raiz`, `-Flavor`, `-Estado` e `-Backups` apontando para `testes\tmp\...`.

Pastas derivadas: `PastaFlavor = <Raiz>\<Flavor>`, `AddOns = <PastaFlavor>\Interface\AddOns`, `WTF = <PastaFlavor>\WTF`. Backups: `<Backups>\sessoes\<carimbo>\WTF.zip` (mantém 20), `<Backups>\addons\<slug>\<carimbo>.zip` (mantém 3 por addon), `<Backups>\cvars\<carimbo>-Config.wtf` (mantém 20).

## 4. Erros e códigos de saída

| Código | Quando | Prefixo da linha |
|---|---|---|
| 0 | ok (inclusive prévia) | `OK` |
| 1 | recusa (jogo aberto, TOC incompatível, conflito) ou diferença na auditoria | `RECUSA` |
| 2 | pré-requisito ausente (sem instalação configurada, sem WTF, sem manifesto) | `PREREQ` |
| 3 | erro de rede ou de arquivo | `ERRO` |

`Stop-Wow -Tipo <PREREQ|RECUSA|ERRO> -Mensagem <texto>` lança `"<TIPO>: <texto>"`. `Invoke-ScriptWow -Bloco { ... }` roda o bloco e captura a exceção. A mensagem `PREREQ:` sai como linha `PREREQ <texto>` e `exit 2`; `RECUSA:` sai como `RECUSA <texto>` e `exit 1`; qualquer outra sai como `ERRO <texto>` e `exit 3`. Sem exceção, o código é o inteiro que o bloco devolver, ou 0.

## 5. Saída padronizada

Toda linha que o agente lê começa com um prefixo em maiúsculas seguido de espaço, e os dados vão em `chave=valor` quando couber. O texto livre para gente vem depois, em linhas sem prefixo.

`PREVIA` `PASTA` `OK` `RECUSA` `ERRO` `PREREQ` `FONTE` `ATUALIZAR` `ATUALIZADO` `FALHOU` `MANUAL` `INSTALACAO` `JOGO` `BACKUP` `AUDITORIA` `DESCONHECIDA` `FALTANDO` `ALTERADA` `INCOMPATIVEL` `DEPENDENCIA` `JUNCTION` `CVAR` `DEV`

## 6. Manifesto (`estado\addons\<slug>.json`)

```json
{
  "v": 1,
  "slug": "questie",
  "nome": "Questie",
  "versao": "bundle/v12.4.0+v1.0.10",
  "fonte": { "tipo": "github", "id": "Questie/Questie", "asset": null, "pagina": null },
  "pastas": [
    { "nome": "Questie", "toc": "Questie_Camelot.toc", "interfaces": [16001],
      "assinatura": "812|20480313", "sha256": "<hex>" }
  ],
  "aprovado": true,
  "estadoInstalacao": "instalado",
  "instaladoEm": "2026-11-04T18:00:00-03:00",
  "atualizadoEm": "2026-11-04T18:00:00-03:00",
  "removidoEm": null,
  "backupAnterior": null,
  "maquina": "PC-AVELL"
}
```

- `slug`: minúsculas, `[a-z0-9-]`; o arquivo se chama `<slug>.json`.
- `fonte.tipo` é um destes: `github` (`id` = `owner/repo`), `tukui` (`id` = slug da Tukui), `zip` (`id` = caminho do zip usado; `pagina` = URL da página, normalmente a da CurseForge) ou `dev` (`id` = caminho da pasta alvo da junction).
- `fonte.asset`: regex opcional para escolher o asset do GitHub.
- `estadoInstalacao`: `instalado` ou `removido`. Remover não apaga o manifesto.
- `aprovado`: `true` em toda instalação feita pelos scripts (o agente só roda `-Aplicar` depois do ok do dono).
- `instaladoEm` se preserva nas atualizações; `atualizadoEm` muda a cada instalação; `backupAnterior` aponta o zip da versão substituída.
- `assinatura` = `"<arquivos>|<bytes>"`; `sha256` = `Get-HashPasta`.

## 7. Outros arquivos de estado

- `estado\registro.md`: append-only, `- yyyy-MM-dd HH:mm | <acao> | <slug> | <detalhe>`. Ações: `instalar`, `atualizar`, `remover`, `backup-wtf`, `restaurar-wtf`, `cvar`, `dev-link`, `dev-unlink`.
- `estado\sessao.json`: `{ "v": 1, "ultimaInterface": 16001, "ultimaVersao": "1.60.1.12345", "ultimaAbertura": "<iso>" }`.
- `comum\instalacao.json`: `{ "v": 1, "raiz": "C:\\...\\World of Warcraft", "flavor": "_forever_", "maquina": "<COMPUTERNAME>", "confirmadoEm": "<iso>" }`.

## 8. `wow-comum.ps1`: funções

Carregar o arquivo só define funções e faz o `Add-Type` do zip.

**Erros:** `Stop-Wow` e `Invoke-ScriptWow` (§4).

**Contexto**
- `Get-WowContexto [-Raiz] [-Flavor] [-Instalacao] [-Estado] [-Backups]` devolve `[pscustomobject]@{Raiz; Flavor; PastaFlavor; AddOns; WTF; Estado; Manifestos; Registro; SessaoJson; Backups; Instalacao}`.
  - Com `Raiz` e `Flavor` vazios, lê `-Instalacao`. Sem arquivo ou sem os campos: `PREREQ` "Instalação não configurada: rode o bootstrap (Find-WowInstalacao e Set-WowInstalacao)".
  - `Raiz` ou `PastaFlavor` inexistente: `PREREQ`.
  - Cria `Estado\addons` se faltar. Nunca cria nada na pasta do jogo.

**Instalação**
- `Find-WowInstalacao` devolve `,@(...)` de `{Raiz; Origem; Flavors=@({Nome; Produto; Versao; Interface})}`, sem caminhos repetidos (comparação sem diferenciar maiúsculas). Procura, nesta ordem:
  1. no registro de desinstalação (`HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*`, o mesmo sem `WOW6432Node` e o de `HKCU:`), entradas com `DisplayName -match 'World of Warcraft'`, usando `InstallLocation`;
  2. no `%APPDATA%\Battle.net\Battle.net.config`, o campo `DefaultInstallPath` (com `/` trocado por `\`) mais `\World of Warcraft`;
  3. nos caminhos comuns `C:\Program Files (x86)\World of Warcraft`, `C:\Program Files\World of Warcraft`, `D:\World of Warcraft`, `D:\Games\World of Warcraft`.

  Os flavors são as subpastas com `.flavor.info`. Só leitura.
- `Set-WowInstalacao -Raiz -Flavor [-Instalacao]` grava o `instalacao.json` (§7).
- `Get-WowVersao -Raiz -Flavor` devolve `{Produto; Versao; Interface}`, ou `$null` se nada casar:
  1. `<Raiz>\<Flavor>\.flavor.info`: das linhas não vazias, a primeira é o cabeçalho (`Product Flavor!STRING:0`) e a segunda é o código do produto.
  2. `<Raiz>\.build.info`: as colunas são separadas por `|`. A primeira linha é o cabeçalho, com `Nome!TIPO:n`, e o índice das colunas `Version`, `Product` e `Active` sai do nome antes do `!`.
  3. Vale a linha cujo `Product` é o produto do flavor. Sem `.flavor.info`, ou sem casamento, vale a linha com `Active` = `1` cujo `Product` contém `forever` ou `camelot`.
  4. `Interface = ConvertTo-WowInterface $Versao`.

  O código real do produto do Forever não é conhecido: nada pode fixá-lo.
- `ConvertTo-WowInterface -Versao` calcula `a*10000 + b*100 + c` com os três primeiros números (`'1.60.1.123'` dá 16001, `'12.1.5.6'` dá 120105).
- `ConvertTo-WowVersaoCurta -Versao` devolve `'a.b.c'`.

**Jogo aberto**
- `Test-JogoAberto -Raiz` devolve um booleano: respeita `WOWAGENTE_JOGO_ABERTO`; senão, verifica se há algum processo cujo `.Path` começa com `<Raiz>\` (OrdinalIgnoreCase). Ignora os processos sem `Path` acessível.
- `Assert-JogoFechado -Raiz`: com o jogo aberto, `RECUSA` "Jogo aberto: feche o WoW e rode de novo."

**TOC**
- `Get-TocInfo -Arquivo` devolve `{Arquivo; Interfaces=[int[]]; Titulo; Versao; AllowLoadGameType=[string[]]; Dependencias=[string[]]}`.
  - Lê linhas `## Chave: Valor`, sem diferenciar maiúsculas na chave.
  - `Interface`: lista por vírgula, só inteiros (placeholder como `@toc-version@` é ignorado).
  - `AllowLoadGameType`: vem da linha `## AllowLoadGameType:` e dos tokens `[AllowLoadGameType x, y]` em qualquer linha, inclusive no `## Title:` (o ElvUI faz isso).
  - `Dependencias`: `## Dependencies:` e `## RequiredDeps:`, por vírgula.
  - Lê o arquivo como UTF-8, com ou sem BOM.
- `Get-TocDoForever -PastaAddon` devolve `{Arquivo; Tipo; Info; TocsPresentes=[string[]]}`. `Nome` é o nome da pasta, sem diferenciar maiúsculas:
  1. Procura, nesta ordem, `<Nome>_Forever.toc`, `<Nome>-Forever.toc`, `<Nome>_Camelot.toc` e `<Nome>-Camelot.toc`; achou um, o `Tipo` é `forever`.
  2. Senão, procura `<Nome>.toc`, e o `Tipo` é `generico`.
  3. Senão, o `Tipo` é `nenhum` e `Info` fica `$null`.
- `Test-AddonForever -PastaAddon -Interface` devolve `{Compativel; Motivo; Toc}`. É compatível se o TOC escolhido existe e suas `Interfaces` contêm a `-Interface`. O `Motivo` vem em português, por exemplo "TOC sem a Interface 16001 (tem: 11509)".

**Zip, pastas e hash**
- `Expand-ZipTemp -Zip` extrai para uma pasta nova em `$env:TEMP\wow-agentes\x-<8 hex>` e devolve o caminho. `Remove-Temp -Pasta` apaga, e só aceita caminhos dentro de `$env:TEMP\wow-agentes`.
- `Find-PastasDeAddon -Pasta` devolve `,@({Nome; Caminho})`: as subpastas diretas que contêm algum `<NomeDaPasta>*.toc`. Se não houver nenhuma e existir exatamente uma subpasta (embrulho), repete dentro dela.
- `Get-AssinaturaPasta -Pasta` devolve `"<arquivos>|<bytes>"`. `Get-HashPasta -Pasta` devolve o sha256 (hex minúsculo) do texto formado por uma linha `<caminho relativo com />|<bytes>|<sha256 do arquivo>` por arquivo, em ordem ordinal. Nenhuma das duas desce em junction.
- `Test-Junction -Caminho` diz se o caminho é um ReparsePoint.
- `Backup-Pastas -Pastas <caminhos> -Zip <arquivo>` põe cada pasta como pasta de topo do zip. Lista vazia: não cria nada e devolve `$null`.
- `Install-Pastas -Origem <@({Nome;Caminho})> -AddOns <dir> [-RemoverTambem <nomes>]` é uma transação:
  1. Cria `AddOns` se faltar.
  2. Renomeia cada destino que já existe para `<nome>.wowbak-<carimbo>`; se o destino for junction, `RECUSA`.
  3. Renomeia do mesmo jeito cada pasta de `-RemoverTambem` (pasta antiga do mesmo addon que sumiu na versão nova).
  4. Copia cada origem para `<AddOns>\<Nome>`.
  5. Se qualquer passo falhar, apaga o que já foi copiado, desfaz os renomes e lança `ERRO`; com sucesso, apaga os `.wowbak-*`.

  Respeita `WOWAGENTE_FALHAR_COPIA`.
- `Remove-PastasAddon -Nomes -AddOns` apaga pastas comuns; diante de uma junction, `RECUSA`.
- `Limit-Itens -Pasta -Manter <n>` apaga os itens mais antigos (pela ordem do nome) além dos `n` mais recentes.

**Manifestos, registro, sessão**
- `Get-Manifestos -Contexto` devolve `,@(...)`. `Get-Manifesto -Contexto -Slug` devolve o manifesto ou `$null`. `Save-Manifesto -Contexto -Manifesto` grava o arquivo.
- `Get-DonoDaPasta -Contexto -Nome` devolve o slug do manifesto **instalado** que lista aquela pasta, ou `$null`.
- `Add-Registro -Contexto -Acao -Slug -Detalhe` acrescenta uma linha ao registro (§7) e cria o arquivo com cabeçalho se ele faltar.
- `Get-SessaoJson -Contexto` e `Save-SessaoJson -Contexto -Dados`.

**WTF e Config.wtf**
- Copie `Read-TextoPreservando` e `Write-TextoPreservando` de `C:\Users\PC-AVELL\.claude\skills\tuning-grafico\scripts\lib-comum.ps1` (por volta das linhas 65 a 116), com um comentário de origem. Não faça dot-source desse arquivo.
- `Get-CVarsWtf -Arquivo` devolve uma hashtable nome→valor das linhas `SET nome "valor"`.
- `Set-CVarWtf -Arquivo -Valores <hashtable>` troca o valor das linhas existentes e acrescenta as que faltam no fim, preservando a codificação e a quebra de linha. Não checa o jogo; quem chama checa.
- `Backup-Wtf -Contexto [-Rotulo]` zipa o WTF em `<Backups>\sessoes\<carimbo>\WTF.zip`, grava `info.txt` com o rótulo e a data, aplica `Limit-Itens` (20) e devolve o caminho. Sem WTF: `PREREQ` "WTF ainda não existe: entre no jogo uma vez".

**Fontes e download** (§10)
- `Get-FonteAddon -Fonte <'github:owner/repo'|'tukui:slug'> [-Asset <regex>] [-Interface <int>] [-VersaoJogo <a.b.c>]` devolve `{Tipo; Id; Versao; Data; Url; Asset; Compativel; Motivo}`.
- `Save-Download -Url -Destino` baixa o arquivo; no modo simulado, ou quando a URL é um caminho local ou `file:///`, copia. Em falha, `ERRO`.

**Fluxos**
- `Install-AddonDeFonte -Contexto -Fonte <'github:..'|'tukui:..'|'zip:<caminho>'> -Slug [-Nome] [-Asset] [-Pagina] [-Forcar] [-Aplicar]` (§9.1) devolve `{Slug; Acao ('criar'|'atualizar'|'nada'); VersaoAntes; VersaoDepois; Pastas; Backup; Aplicado}`.
- `Remove-Addon -Contexto -Slug [-Aplicar]` (§9.2).

## 9. Fluxos e scripts

### 9.1 Instalar ou atualizar (`Install-AddonDeFonte`; CLI `addon-instalar.ps1`)

CLI: `addon-instalar.ps1 -Fonte <...> -Slug <slug> [-Nome <nome>] [-Asset <regex>] [-Pagina <url>] [-Forcar] [-Aplicar]` mais os parâmetros comuns.

1. Lê a versão do cliente (`Get-WowVersao`); se vier `$null`, `PREREQ`.
2. Resolve a fonte. Para `github` e `tukui`, chama `Get-FonteAddon`; `Compativel = $false` gera `RECUSA`, a menos que haja `-Forcar`. Para `zip`, o arquivo tem de existir; senão, `PREREQ`.
3. Se já existe manifesto instalado com a mesma versão, sem `-Forcar`: imprime `OK nada a fazer slug=<s> versao=<v>`, a `Acao` é `nada` e o fluxo para.
4. Baixa (se não for zip) e extrai para o temp (`Expand-ZipTemp`), depois chama `Find-PastasDeAddon`. Nenhuma pasta encontrada: `RECUSA` "o zip não contém addon".
5. Para cada pasta, roda `Test-AddonForever` com a Interface do cliente. Qualquer pasta incompatível gera `RECUSA` com a lista, a menos que haja `-Forcar`.
6. Conflito: uma pasta que pertence a outro manifesto instalado (`Get-DonoDaPasta`) gera `RECUSA` "pasta X pertence ao addon Y".
7. Imprime a prévia (sempre): uma linha `PREVIA slug=<s> versao=<v> fonte=<tipo:id> acao=<criar|atualizar>` e, por pasta, uma linha `PASTA nome=<n> acao=<criar|substituir> toc=<arquivo> interfaces=<lista> compativel=<sim|nao>`. As pastas da versão antiga que somem na nova saem como `PASTA nome=<n> acao=remover`.
8. Sem `-Aplicar`: imprime "Prévia apenas; rode com -Aplicar para instalar.", apaga o temp e devolve com `Aplicado = $false`.
9. Com `-Aplicar`:
   1. `Assert-JogoFechado`.
   2. Backup das pastas que serão substituídas ou removidas em `<Backups>\addons\<slug>\<carimbo>.zip` e `Limit-Itens` (3).
   3. `Install-Pastas`.
   4. Grava o manifesto (§6).
   5. `Add-Registro` com a ação `instalar` ou `atualizar`.
   6. Apaga o temp.
   7. Imprime `OK instalado slug=<s> versao=<v>`, ou `OK atualizado slug=<s> de=<a> para=<b>`.

### 9.2 Remover (`Remove-Addon`; CLI `addon-remover.ps1 -Slug <s> [-Aplicar]`)

1. Sem manifesto instalado: `PREREQ`.
2. Manifesto do tipo `dev`: `RECUSA` "use dev-link.ps1 -Remover".
3. Prévia: uma linha `PREVIA slug=<s> acao=remover` e uma `PASTA nome=<n> acao=remover` por pasta.
4. Com `-Aplicar`: `Assert-JogoFechado`, backup em zip (como em 9.1), `Remove-PastasAddon`, manifesto com `estadoInstalacao=removido`, `removidoEm` e `backupAnterior` preenchidos, `Add-Registro remover` e a linha `OK removido slug=<s>`.

### 9.3 `addons-auditar.ps1 [-HashCompleto]` (só leitura; roda com o jogo aberto)

Para cada pasta do `AddOns`, nesta ordem de verificação:
- se é junction: casa com um manifesto `dev` instalado cujo `id` é o alvo; senão, `JUNCTION nome=<n> alvo=<a> sem-manifesto`;
- se não pertence a nenhum manifesto instalado: `DESCONHECIDA nome=<n>`;
- se a assinatura (ou o `sha256`, com `-HashCompleto`) difere do manifesto: `ALTERADA slug=<s> nome=<n>`;
- se não passa no `Test-AddonForever`: `INCOMPATIVEL nome=<n> toc=<t> interfaces=<l> cliente=<i>`;
- se o TOC escolhido declara uma dependência que não existe no `AddOns`: `DEPENDENCIA nome=<n> requer=<dep>`.

Para cada pasta listada num manifesto instalado que não existe no disco: `FALTANDO slug=<s> nome=<n>`.

No fim, a linha `AUDITORIA addons=<n> desconhecidas=<n> faltando=<n> alteradas=<n> incompativeis=<n> dependencias=<n> junctions=<n>`. Código 0 se tudo é zero, 1 se algo não é, 2 se falta pré-requisito. Pasta `AddOns` inexistente conta como zero addons, com código 0.

### 9.4 WTF

- `wtf-backup.ps1 [-Rotulo <texto>]` chama `Backup-Wtf`, imprime `BACKUP ok caminho=<zip>` e faz `Add-Registro backup-wtf`. Com o jogo aberto, roda mesmo assim, mas avisa que o backup pega o último estado salvo pelo jogo.
- `wtf-restaurar.ps1 -De <pasta da sessão ou zip> [-Aplicar]`:
  - prévia: `PREVIA acao=restaurar-wtf de=<zip> data=<info.txt>`;
  - com `-Aplicar`: `Assert-JogoFechado`, `Backup-Wtf -Rotulo antes-de-restaurar`, renomeia o WTF atual para `WTF.wowbak-<carimbo>` e extrai o backup como novo `WTF`; se falhar, desfaz; com sucesso, apaga o `.wowbak` e grava `Add-Registro restaurar-wtf`.
- `wtf-cvar.ps1 -Valores '<nome>=<valor>;<nome>=<valor>' [-Aplicar]`:
  - prévia: uma linha `CVAR nome=<n> atual=<a> novo=<b>` por CVar (`atual=(ausente)` quando não existe);
  - com `-Aplicar`: `Assert-JogoFechado`, copia o `Config.wtf` para `<Backups>\cvars\<carimbo>-Config.wtf` (`Limit-Itens` 20), chama `Set-CVarWtf` e grava `Add-Registro cvar`.
  - Sem `Config.wtf`: `PREREQ`.

### 9.5 `dev-link.ps1 -Pasta <dir do addon em addons-proprios> [-Remover] [-Aplicar]`

- **Ligar:** o nome é o da pasta; o destino é `<AddOns>\<nome>`.
  - Destino que existe como pasta comum gera `RECUSA`; destino que já é junction para o mesmo alvo dá `OK nada a fazer`.
  - Prévia: `DEV acao=ligar nome=<n> alvo=<a>`.
  - Com `-Aplicar`: `Assert-JogoFechado`, `New-Item -ItemType Junction`, manifesto `dev-<nome-em-minusculas>` (`fonte.tipo=dev`, `id=<alvo>`, versão = `Versao` do TOC ou `dev`) e `Add-Registro dev-link`.
- **Remover:** prévia, e com `-Aplicar`: `Assert-JogoFechado`, `[System.IO.Directory]::Delete` na junction (o alvo fica intacto), manifesto removido e `Add-Registro dev-unlink`.

### 9.6 `addon-fontes.ps1 -Fonte <github:..|tukui:..> [-Asset <regex>] [-Json]` (só leitura)

Usa a Interface e a versão do cliente se a instalação estiver configurada; se não estiver, consulta sem checar a compatibilidade. Imprime `FONTE tipo=<t> id=<i> versao=<v> data=<d> asset=<a> compativel=<sim|nao|?> url=<u>`; com `-Json`, imprime o objeto em JSON. Códigos: 0 ok, 1 nenhum asset serve, 3 rede.

### 9.7 `addon-atualizar.ps1 [-Slug <s>] [-Aplicar]`

Para cada manifesto instalado e aprovado (ou só o `-Slug`):
- `github` e `tukui`: `Get-FonteAddon`. Versão diferente da do manifesto dá a linha `ATUALIZAR slug=<s> de=<a> para=<b>`, e com `-Aplicar` roda `Install-AddonDeFonte -Aplicar`, imprimindo `ATUALIZADO slug=<s> de=<a> para=<b>`. Uma falha num addon (rede, recusa) imprime `FALHOU slug=<s> motivo=<m>` e não interrompe os outros.
- `zip`: imprime `MANUAL slug=<s> pagina=<url>`, sem verificar nada.
- `dev`: ignora.

Código 0 se nada falhou, 1 se algum `FALHOU`.

### 9.8 `sessao-abrir.ps1`

1. Chama `Get-WowContexto`. Sem instalação: `INSTALACAO ausente` e `exit 2`.
2. Chama `Get-WowVersao` e compara com o `sessao.json`. Imprime `INSTALACAO ok raiz=<r> flavor=<f> versao=<v> interface=<i> mudou=<sim|nao>`, com `anterior=<n>` quando mudou.
3. Imprime `JOGO aberto` ou `JOGO fechado`.
4. Com o jogo fechado:
   - roda o `wtf-backup.ps1` como processo filho e repassa a linha `BACKUP ...` (sem WTF, a linha é `BACKUP sem-wtf`);
   - roda a lógica do `addon-atualizar.ps1 -Aplicar` (como processo filho, repassando as linhas `ATUALIZADO`, `FALHOU` e `MANUAL`).

   Com o jogo aberto: `ATUALIZACAO adiada motivo=jogo-aberto`.
5. Roda o `addons-auditar.ps1` como processo filho e repassa todas as linhas dele.
6. Grava o `sessao.json`.
7. Sai com 0 se não houve `FALHOU` e a auditoria deu 0; senão, com 1.

## 10. Fontes

### 10.1 GitHub (`github:owner/repo`)

1. Busca `GET https://api.github.com/repos/<owner>/<repo>/releases/latest` e guarda `tag_name`, `published_at` e `assets[]` (`name`, `browser_download_url`).
2. Se há um asset `release.json` (formato do empacotador: `{"releases":[{"name","version","filename","nolib","metadata":[{"flavor","interface"}]}]}`), baixa-o e escolhe a primeira release, não `nolib`, cujo `metadata` tem `flavor == "forever"` ou `interface == <Interface do cliente>`. O asset é o de nome igual a `filename`, e a `Versao` é a `version` dele. Se nenhuma release serve, `Compativel = $false` com o motivo "release.json sem o flavor forever".
3. Sem `release.json`, a escolha segue esta ordem:
   1. o asset `.zip` que casa com `-Asset`;
   2. o asset cujo nome casa com `(?i)forever|camelot`;
   3. o único `.zip`;
   4. o único que sobra depois de excluir `(?i)classic|vanilla|bcc|tbc|wrath|wotlk|cata|mists|mop|mainline|retail|nolib`.

   Se nada servir, `RECUSA` com a lista de nomes. Neste caminho, `Versao = tag_name` e `Compativel` fica `$null` (só o TOC dirá).
4. Na URL, troque `+` por `%2B` no caminho, nunca na query (exemplo: o asset do Questie, `Questie-v12.4.0+v1.0.10.zip`).

### 10.2 Tukui (`tukui:slug`)

`GET https://api.tukui.org/v1/addon/<slug>` devolve `version`, `url`, `last_update` e `patch` (lista de versões de jogo). `Compativel` é verdadeiro se `patch` contém a `-VersaoJogo` (`a.b.c`, por exemplo `1.60.1`). A `url` leva um token que muda, então nunca entra no manifesto: ela é lida na hora do download.

### 10.3 Zip (`zip:<caminho>`)

É um arquivo local que o dono baixou (CurseForge). O caminho vai para `fonte.id` e a URL da página, se houver, para `fonte.pagina`.

### 10.4 Modo simulado (`WOWAGENTE_RESPOSTAS`)

Quando a variável está definida, nenhuma chamada de rede acontece; as respostas são lidas da pasta:
- `github-<owner>_<repo>.json` faz o papel da resposta de `releases/latest`;
- `github-<owner>_<repo>-release.json` faz o papel do `release.json`;
- `tukui-<slug>.json` faz o papel da resposta da Tukui.

Nos testes, as URLs dentro dessas respostas apontam para zips locais gerados pelo próprio teste, e `Save-Download` os copia.

## 11. Fixture e testes

**`testes\fixture\World of Warcraft\`** (versionada):
- `.build.info`: cabeçalho `Branch!STRING:0|Active!DEC:1|Build Key!HEX:16|Version!STRING:0|Product!STRING:0` e duas linhas, `us|1|aaaa|1.15.9.65000|wow_classic_era` e `us|1|bbbb|1.60.1.65432|wow_forever`. O código `wow_forever` é **inventado** para o teste.
- `_forever_\.flavor.info`: `Product Flavor!STRING:0` e `wow_forever`.
- `_forever_\Interface\AddOns\.gitkeep`.
- `_forever_\WTF\Config.wtf`, em CRLF, com `SET textLocale "ptBR"`, `SET gxWindow "1"` e `SET synchronizeMacros "1"`.
- `_forever_\WTF\Account\CONTA1\SavedVariables\Exemplo.lua`.
- `_classic_era_\.flavor.info` com `wow_classic_era`.

**`testes\fontes-fixture\`** (versionada; os testes geram os zips em `tmp`):
- `AddonA\AddonA.toc`: `## Interface: 16001`, `## Title: Addon A`, `## Version: 1.0.0`;
- `AddonClassic\AddonClassic.toc`: só `## Interface: 11509`;
- `AddonMulti\AddonMulti.toc` e `AddonMulti_Options\AddonMulti_Options.toc`, ambos 16001, que vão num zip só;
- `AddonForeverToc\AddonForeverToc.toc` (11509) com `AddonForeverToc_Camelot.toc` (16001);
- `AddonDep\AddonDep.toc` com 16001 e `## Dependencies: AddonInexistente`;
- `Embrulho\AddonB\AddonB.toc` com 16001, para o caso de embrulho.

Cada addon tem um `.lua` de uma linha.

**`testes\respostas\`** (versionada): exemplos no formato real, um `github-exemplo.json` (com um asset zip e um `release.json`), um `release-exemplo.json` (com `forever` 16001) e um `tukui-exemplo.json` (com `patch` contendo `1.60.1`). Os testes copiam esses arquivos para `tmp` com os nomes de §10.4 e reescrevem as URLs para os zips locais.

**Ajudantes (T4):**
- `testes\_assert.ps1` define `Assert-Igual -Esperado -Obtido -Descricao`, `Assert-Verdade -Condicao -Descricao` e `Get-Resultado` (o total e as falhas).
- `testes\_preparar.ps1` define:
  - `New-AmbienteTeste -Nome`: copia a fixture para `testes\tmp\<nome>-<8 hex>\`, cria `estado\` e `backups\`, limpa as variáveis `WOWAGENTE_*` e devolve `{Base; Raiz; Flavor; Estado; Backups; ArgsComuns}`. `ArgsComuns` é o array `-Raiz`, `-Flavor`, `-Estado`, `-Backups`, pronto para splatting.
  - `New-ZipDeFixture -Ambiente -Addons <nomes de fontes-fixture> -Nome <zip>`: gera o zip com aquelas pastas em `<Base>\zips\` e devolve o caminho.
  - `Set-RespostasSimuladas -Ambiente -Arquivos <hashtable nome→conteúdo>`.
  - `Invoke-ScriptTeste -Script -Argumentos`: roda como processo filho conforme §1.10 e devolve `{Saida; Codigo}`.

**Regras de cada `t-*.ps1`:**
- é autocontido e chama `. _assert.ps1` e `. _preparar.ps1`;
- testa os scripts como processo filho e as funções por dot-source;
- não usa rede e limpa o próprio `tmp` no fim (com `-Manter`, não limpa);
- termina com a linha `OK <n> verificacoes` e `exit 0`, ou com uma linha `FALHOU: <descricao>` por falha e `exit 1`.

## 12. Fora do escopo

- Download automático da CurseForge (sem chave; o dono clica).
- Edição de SavedVariables por script.
- Escrita de `macros-cache.txt` e `bindings-cache.wtf` (depende da sincronização com o servidor; o agente decide caso a caso).
- Agendamento no Windows.
- Qualquer escrita fora de `Interface\AddOns`, `WTF`, `estado\`, `comum\instalacao.json`, dos backups e do temp.
