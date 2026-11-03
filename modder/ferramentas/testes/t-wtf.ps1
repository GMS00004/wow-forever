param([switch]$Manter)
$ErrorActionPreference = 'Stop'
$Aqui = $PSScriptRoot
. (Join-Path $Aqui '_assert.ps1')
. (Join-Path $Aqui '_preparar.ps1')
. (Join-Path $Aqui '..\wow-comum.ps1')

$bkScript = (Resolve-Path -LiteralPath (Join-Path $Aqui '..\wtf-backup.ps1')).ProviderPath
$rsScript = (Resolve-Path -LiteralPath (Join-Path $Aqui '..\wtf-restaurar.ps1')).ProviderPath
$cvScript = (Resolve-Path -LiteralPath (Join-Path $Aqui '..\wtf-cvar.ps1')).ProviderPath

# ---------------------------------------------------------------- ajudantes locais

function Get-Contexto {
    param($A)
    Get-WowContexto -Raiz $A.Raiz -Flavor $A.Flavor -Estado $A.Estado -Backups $A.Backups -Instalacao (Join-Path $A.Base 'inst.json')
}

function Get-Linhas {
    param([string]$Texto)
    return @($Texto -split "`n" | ForEach-Object { $_.TrimEnd() })
}

function Tem-Linha {
    param([string]$Texto, [string]$Linha)
    return (@(Get-Linhas $Texto | Where-Object { $_ -ceq $Linha }).Count -gt 0)
}

function Tem-LinhaLike {
    param([string]$Texto, [string]$Padrao)
    return (@(Get-Linhas $Texto | Where-Object { $_ -like $Padrao }).Count -gt 0)
}

function Get-Base64 {
    param([string]$Caminho)
    return [Convert]::ToBase64String([IO.File]::ReadAllBytes($Caminho))
}

function Get-EntradasZip {
    param([string]$Zip)
    $z = [System.IO.Compression.ZipFile]::OpenRead($Zip)
    try { return @($z.Entries | ForEach-Object { $_.FullName }) } finally { $z.Dispose() }
}

function Contar-Sessoes {
    param($C)
    $p = Join-Path $C.Backups 'sessoes'
    if (-not (Test-Path -LiteralPath $p)) { return 0 }
    return @(Get-ChildItem -LiteralPath $p -Directory).Count
}

function Contar-Registro {
    param($C, [string]$Acao)
    if (-not (Test-Path -LiteralPath $C.Registro)) { return 0 }
    return (@(Get-Content -LiteralPath $C.Registro -Encoding UTF8 | Where-Object { $_ -like "*| $Acao | *" })).Count
}

try {

# ---------------------------------------------------------------- 1. wtf-backup
$a = New-AmbienteTeste 'wtf-bk'
$ctx = Get-Contexto $a
$argsBk = @($a.ArgsComuns) + @('-Rotulo', 'rotulo-teste')
$r = Invoke-ScriptTeste -Script $bkScript -Argumentos $argsBk
Assert-Igual 0 $r.Codigo 'backup: codigo 0'
Assert-Verdade (Tem-LinhaLike $r.Saida 'BACKUP ok caminho=*') 'backup: linha BACKUP ok'
$sessoes = @(Get-ChildItem -LiteralPath (Join-Path $a.Backups 'sessoes') -Directory)
Assert-Igual 1 $sessoes.Count 'backup: uma pasta de sessao'
$sessao1 = $sessoes[0].FullName
Assert-Verdade (Test-Path -LiteralPath (Join-Path $sessao1 'WTF.zip') -PathType Leaf) 'backup: WTF.zip na pasta da sessao'
Assert-Verdade (@(Get-EntradasZip (Join-Path $sessao1 'WTF.zip')) -contains 'WTF/Config.wtf') 'backup: zip tem WTF/Config.wtf'
Assert-Verdade (@(Get-EntradasZip (Join-Path $sessao1 'WTF.zip')) -contains 'WTF/Account/CONTA1/SavedVariables/Exemplo.lua') 'backup: zip tem SavedVariables'
$infoBk = Get-Content -LiteralPath (Join-Path $sessao1 'info.txt') -Raw -Encoding UTF8
Assert-Verdade ($infoBk -like '*rotulo-teste*') 'backup: info.txt com o rotulo'
Assert-Igual 1 (Contar-Registro $ctx 'backup-wtf') 'backup: registro backup-wtf'

# ---------------------------------------------------------------- 2. wtf-backup sem a pasta WTF
$b = New-AmbienteTeste 'wtf-bk-sem'
Remove-Item -LiteralPath (Join-Path $b.Raiz '_forever_\WTF') -Recurse -Force
$r = Invoke-ScriptTeste -Script $bkScript -Argumentos $b.ArgsComuns
Assert-Igual 2 $r.Codigo 'backup sem WTF: codigo 2'
Assert-Verdade (Tem-LinhaLike $r.Saida 'PREREQ *') 'backup sem WTF: linha PREREQ'

# ---------------------------------------------------------------- 3. wtf-restaurar
$a = New-AmbienteTeste 'wtf-rs'
$ctx = Get-Contexto $a
$cfg = Join-Path $ctx.WTF 'Config.wtf'
$original = Get-Base64 $cfg
$zipOrig = Backup-Wtf -Contexto $ctx -Rotulo 'original'
$sessaoOrig = Split-Path -Parent $zipOrig
[System.IO.File]::WriteAllText($cfg, "SET gxWindow `"0`"`r`nSET synchronizeMacros `"0`"`r`n", (New-Object System.Text.UTF8Encoding $false))
$alterado = Get-Base64 $cfg
$sessoesAntes = Contar-Sessoes $a

# previa: nada muda
$argsRs = @($a.ArgsComuns) + @('-De', $sessaoOrig)
$r = Invoke-ScriptTeste -Script $rsScript -Argumentos $argsRs
Assert-Igual 0 $r.Codigo 'restaurar previa: codigo 0'
Assert-Verdade (Tem-LinhaLike $r.Saida 'PREVIA acao=restaurar-wtf de=*') 'restaurar previa: linha PREVIA'
Assert-Igual $alterado (Get-Base64 $cfg) 'restaurar previa: Config.wtf nao muda'
Assert-Igual $sessoesAntes (Contar-Sessoes $a) 'restaurar previa: nao cria backup'
Assert-Igual 0 (Contar-Registro $ctx 'restaurar-wtf') 'restaurar previa: sem registro'

# -Aplicar: o conteudo original volta, com backup antes-de-restaurar
$env:WOWAGENTE_JOGO_ABERTO = '0'
$argsRsAp = @($a.ArgsComuns) + @('-De', $sessaoOrig, '-Aplicar')
$r = Invoke-ScriptTeste -Script $rsScript -Argumentos $argsRsAp
Assert-Igual 0 $r.Codigo 'restaurar -Aplicar: codigo 0'
Assert-Verdade (Tem-LinhaLike $r.Saida 'OK restaurado de=*') 'restaurar -Aplicar: linha OK'
Assert-Igual $original (Get-Base64 $cfg) 'restaurar -Aplicar: Config.wtf volta ao conteudo original'
$infosAntes = @(Get-ChildItem -LiteralPath (Join-Path $a.Backups 'sessoes') -Recurse -Filter info.txt |
    Where-Object { (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -like '*antes-de-restaurar*' })
Assert-Igual 1 $infosAntes.Count 'restaurar -Aplicar: backup com o rotulo antes-de-restaurar'
Assert-Igual 0 @(Get-ChildItem -LiteralPath $ctx.PastaFlavor -Filter 'WTF.wowbak-*' -Force).Count 'restaurar -Aplicar: nao sobra WTF.wowbak'
Assert-Igual 1 (Contar-Registro $ctx 'restaurar-wtf') 'restaurar -Aplicar: registro restaurar-wtf'

# com o jogo aberto: RECUSA e nada muda
$env:WOWAGENTE_JOGO_ABERTO = '1'
$antesJogo = Get-Base64 $cfg
$r = Invoke-ScriptTeste -Script $rsScript -Argumentos $argsRsAp
Assert-Igual 1 $r.Codigo 'restaurar jogo aberto: codigo 1'
Assert-Verdade (Tem-LinhaLike $r.Saida 'RECUSA *') 'restaurar jogo aberto: linha RECUSA'
Assert-Igual $antesJogo (Get-Base64 $cfg) 'restaurar jogo aberto: nada muda'

# ---------------------------------------------------------------- 4. wtf-cvar
$a = New-AmbienteTeste 'wtf-cv'
$ctx = Get-Contexto $a
$cfg = Join-Path $ctx.WTF 'Config.wtf'
$original = Get-Base64 $cfg
$argsCv = @($a.ArgsComuns) + @('-Valores', 'gxWindow=0;novaCvar=abc')

# previa
$r = Invoke-ScriptTeste -Script $cvScript -Argumentos $argsCv
Assert-Igual 0 $r.Codigo 'cvar previa: codigo 0'
Assert-Verdade (Tem-Linha $r.Saida 'CVAR nome=gxWindow atual=1 novo=0') 'cvar previa: linha de gxWindow'
Assert-Verdade (Tem-Linha $r.Saida 'CVAR nome=novaCvar atual=(ausente) novo=abc') 'cvar previa: nova CVar (ausente)'
Assert-Igual $original (Get-Base64 $cfg) 'cvar previa: Config.wtf nao muda'
Assert-Igual 0 (Contar-Registro $ctx 'cvar') 'cvar previa: sem registro'

# -Aplicar
$env:WOWAGENTE_JOGO_ABERTO = '0'
$r = Invoke-ScriptTeste -Script $cvScript -Argumentos ($argsCv + @('-Aplicar'))
Assert-Igual 0 $r.Codigo 'cvar -Aplicar: codigo 0'
$texto = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($cfg))
Assert-Verdade ($texto.Contains('SET gxWindow "0"')) 'cvar -Aplicar: gxWindow trocado'
Assert-Verdade ($texto.Contains('SET novaCvar "abc"')) 'cvar -Aplicar: novaCvar acrescentada'
Assert-Verdade ($texto.Contains('SET textLocale "ptBR"')) 'cvar -Aplicar: demais linhas preservadas'
Assert-Verdade (-not $texto.Replace("`r`n", '').Contains("`n")) 'cvar -Aplicar: CRLF preservado (nenhum LF sozinho)'
$copias = @(Get-ChildItem -LiteralPath (Join-Path $a.Backups 'cvars') -File)
Assert-Igual 1 $copias.Count 'cvar -Aplicar: uma copia em backups\cvars'
Assert-Verdade ($copias[0].Name -like '*-Config.wtf') 'cvar -Aplicar: nome da copia *-Config.wtf'
Assert-Igual $original (Get-Base64 $copias[0].FullName) 'cvar -Aplicar: a copia e o Config.wtf original'
Assert-Igual 1 (Contar-Registro $ctx 'cvar') 'cvar -Aplicar: registro cvar'
Assert-Verdade (Tem-LinhaLike $r.Saida 'OK cvar *') 'cvar -Aplicar: linha OK'

# com o jogo aberto: RECUSA e nada muda
$env:WOWAGENTE_JOGO_ABERTO = '1'
$antesJogo = Get-Base64 $cfg
$r = Invoke-ScriptTeste -Script $cvScript -Argumentos ($argsCv + @('-Aplicar'))
Assert-Igual 1 $r.Codigo 'cvar jogo aberto: codigo 1'
Assert-Verdade (Tem-LinhaLike $r.Saida 'RECUSA *') 'cvar jogo aberto: linha RECUSA'
Assert-Igual $antesJogo (Get-Base64 $cfg) 'cvar jogo aberto: Config.wtf nao muda'

# sem Config.wtf: PREREQ
$b = New-AmbienteTeste 'wtf-cv-sem'
Remove-Item -LiteralPath (Join-Path $b.Raiz '_forever_\WTF\Config.wtf') -Force
$env:WOWAGENTE_JOGO_ABERTO = '0'
$r = Invoke-ScriptTeste -Script $cvScript -Argumentos (@($b.ArgsComuns) + @('-Valores', 'gxWindow=0', '-Aplicar'))
Assert-Igual 2 $r.Codigo 'cvar sem Config.wtf: codigo 2'
Assert-Verdade (Tem-LinhaLike $r.Saida 'PREREQ *') 'cvar sem Config.wtf: linha PREREQ'

} finally {
    if (-not $Manter) { Remove-AmbientesTeste }
}

$res = Get-Resultado
if ($res.Falhas.Count -gt 0) {
    foreach ($f in $res.Falhas) { Write-Output "FALHOU: $f" }
    exit 1
}
Write-Output "OK $($res.Total) verificacoes"
exit 0
