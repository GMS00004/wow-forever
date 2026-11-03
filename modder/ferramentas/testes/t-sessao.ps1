# Teste de sessao-abrir.ps1 (contrato §9.8). Roda os filhos (wtf-backup, addon-atualizar, addons-auditar). Sem rede.
param([switch]$Manter)
$ErrorActionPreference = 'Stop'
$Aqui = $PSScriptRoot
. (Join-Path $Aqui '_assert.ps1')
. (Join-Path $Aqui '_preparar.ps1')
. (Join-Path $Aqui '..\wow-comum.ps1')

$SessaoScript = [IO.Path]::GetFullPath((Join-Path $Aqui '..\sessao-abrir.ps1'))

# ---------------------------------------------------------------- ajudantes locais

function Get-Linhas {
    param([string]$Texto)
    return @($Texto -split "`n" | ForEach-Object { $_.TrimEnd() })
}

function Tem-LinhaLike {
    param([string]$Texto, [string]$Padrao)
    return (@(Get-Linhas $Texto | Where-Object { $_ -cmatch $Padrao }).Count -gt 0)
}

function Get-IndiceLinha {
    param([string]$Texto, [string]$Padrao)
    $ls = Get-Linhas $Texto
    for ($i = 0; $i -lt $ls.Count; $i++) { if ($ls[$i] -cmatch $Padrao) { return $i } }
    return -1
}

# Zip com a pasta AddonA (copia da fixture) com ## Version trocado.
function New-ZipAddonA {
    param($A, [string]$Versao, [string]$Nome)
    $dir = Join-Path $A.Base ("variante-" + $Versao)
    [void](New-Item -ItemType Directory -Path $dir -Force)
    Copy-Item -LiteralPath (Join-Path $Aqui 'fontes-fixture\AddonA') -Destination $dir -Recurse -Force
    $pasta = Join-Path $dir 'AddonA'
    $toc = Join-Path $pasta 'AddonA.toc'
    $txt = [System.IO.File]::ReadAllText($toc)
    $txt = $txt -replace '## Version:[^\r\n]*', "## Version: $Versao"
    [System.IO.File]::WriteAllText($toc, $txt, (New-Object System.Text.UTF8Encoding $false))

    $zipDir = Join-Path $A.Base 'zips'
    [void](New-Item -ItemType Directory -Path $zipDir -Force)
    $zip = Join-Path $zipDir $Nome
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    $arq = [System.IO.Compression.ZipFile]::Open($zip, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($f in @(Get-ChildItem -LiteralPath $pasta -Recurse -File)) {
            $rel = 'AddonA/' + $f.FullName.Substring($pasta.Length + 1).Replace('\', '/')
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($arq, $f.FullName, $rel)
        }
    } finally { $arq.Dispose() }
    return $zip
}

function New-GhSemRelease {
    param([string]$Tag, [string]$NomeZip, [string]$ZipLocal)
    return [pscustomobject]@{
        tag_name     = $Tag
        published_at = '2026-10-25T12:00:00Z'
        assets       = @([pscustomobject]@{ name = $NomeZip; browser_download_url = $ZipLocal })
    }
}

# Ambiente com o addon 'addona' instalado na 1.0.0 pela biblioteca; a fonte passa a oferecer a 1.1.0.
function New-Cenario {
    param([string]$Nome)
    $a = New-AmbienteTeste $Nome
    $env:WOWAGENTE_JOGO_ABERTO = '0'
    $zip10 = New-ZipAddonA $a '1.0.0' 'AddonA-1.0.0.zip'
    Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = (New-GhSemRelease '1.0.0' 'AddonA-1.0.0.zip' $zip10) }
    $ctx = Get-WowContexto -Raiz $a.Raiz -Flavor $a.Flavor -Estado $a.Estado -Backups $a.Backups -Instalacao (Join-Path $a.Base 'inst.json')
    $null = & { Install-AddonDeFonte -Contexto $ctx -Fonte 'github:dono/exemplo' -Slug 'addona' -Nome 'Addon A' -Aplicar } 6>&1
    $zip11 = New-ZipAddonA $a '1.1.0' 'AddonA-1.1.0.zip'
    Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = (New-GhSemRelease '1.1.0' 'AddonA-1.1.0.zip' $zip11) }
    return $a
}

function Get-SessaoArquivo {
    param($A)
    $p = Join-Path $A.Estado 'sessao.json'
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return $null }
    return (Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json)
}

# ---------------------------------------------------------------- 1. sem instalacao

$a1 = New-AmbienteTeste 'sessao-sem'
$semInst = Join-Path $a1.Base 'inexistente\inst.json'
$s1 = Invoke-ScriptTeste -Script $SessaoScript -Argumentos @('-Instalacao', $semInst, '-Estado', $a1.Estado, '-Backups', $a1.Backups)
Assert-Igual 2 $s1.Codigo 'sem instalacao: codigo 2'
Assert-Verdade (Tem-LinhaLike $s1.Saida '^INSTALACAO ausente ') 'sem instalacao: linha INSTALACAO ausente'

# ---------------------------------------------------------------- 2. jogo fechado, atualizacao aplicada

$a2 = New-Cenario 'sessao-fechado'
$s2 = Invoke-ScriptTeste -Script $SessaoScript -Argumentos $a2.ArgsComuns
Assert-Igual 0 $s2.Codigo 'jogo fechado: codigo 0'
Assert-Verdade (Tem-LinhaLike $s2.Saida '^INSTALACAO ok .* interface=16001 mudou=nao$') 'jogo fechado: INSTALACAO ok com mudou=nao (primeira vez)'
Assert-Verdade (Tem-LinhaLike $s2.Saida '^JOGO fechado$') 'jogo fechado: linha JOGO fechado'
Assert-Verdade (Tem-LinhaLike $s2.Saida '^BACKUP ok caminho=') 'jogo fechado: linha BACKUP ok'
Assert-Verdade (Tem-LinhaLike $s2.Saida '^ATUALIZADO slug=addona de=1\.0\.0 para=1\.1\.0$') 'jogo fechado: linha ATUALIZADO'
Assert-Verdade (Tem-LinhaLike $s2.Saida '^AUDITORIA addons=1 desconhecidas=0 faltando=0 alteradas=0 incompativeis=0 dependencias=0 junctions=0$') 'jogo fechado: linha AUDITORIA limpa'
$iJ = Get-IndiceLinha $s2.Saida '^JOGO fechado$'
$iB = Get-IndiceLinha $s2.Saida '^BACKUP ok'
$iA = Get-IndiceLinha $s2.Saida '^ATUALIZADO '
$iU = Get-IndiceLinha $s2.Saida '^AUDITORIA '
Assert-Verdade (($iJ -ge 0) -and ($iJ -lt $iB) -and ($iB -lt $iA) -and ($iA -lt $iU)) 'jogo fechado: ordem JOGO, BACKUP, ATUALIZADO, AUDITORIA'
$sj2 = Get-SessaoArquivo $a2
Assert-Igual 16001 $sj2.ultimaInterface 'jogo fechado: sessao.json com ultimaInterface 16001'

# ---------------------------------------------------------------- 3. segunda execucao com o Forever em 1.60.2

$buildInfo = Join-Path $a2.Raiz '.build.info'
$bi = [System.IO.File]::ReadAllText($buildInfo)
$bi = $bi.Replace('1.60.1.65432', '1.60.2.65432')
[System.IO.File]::WriteAllText($buildInfo, $bi, (New-Object System.Text.UTF8Encoding $false))

$s3 = Invoke-ScriptTeste -Script $SessaoScript -Argumentos $a2.ArgsComuns
Assert-Igual 1 $s3.Codigo 'interface nova: codigo 1 (auditoria incompativel)'
Assert-Verdade (Tem-LinhaLike $s3.Saida '^INSTALACAO ok .* interface=16002 mudou=sim anterior=16001$') 'interface nova: INSTALACAO ok com mudou=sim anterior=16001'
Assert-Verdade (Tem-LinhaLike $s3.Saida '^INCOMPATIVEL nome=AddonA toc=AddonA\.toc interfaces=16001 cliente=16002$') 'interface nova: auditoria aponta INCOMPATIVEL'
Assert-Verdade (Tem-LinhaLike $s3.Saida '^AUDITORIA .* incompativeis=1 ') 'interface nova: AUDITORIA com incompativeis=1'
$sj3 = Get-SessaoArquivo $a2
Assert-Igual 16002 $sj3.ultimaInterface 'interface nova: sessao.json com ultimaInterface 16002'

# ---------------------------------------------------------------- 4. jogo aberto: atualizacao adiada

$a4 = New-Cenario 'sessao-aberto'
$env:WOWAGENTE_JOGO_ABERTO = '1'
$s4 = Invoke-ScriptTeste -Script $SessaoScript -Argumentos $a4.ArgsComuns
Assert-Verdade (Tem-LinhaLike $s4.Saida '^JOGO aberto$') 'jogo aberto: linha JOGO aberto'
Assert-Verdade (Tem-LinhaLike $s4.Saida '^ATUALIZACAO adiada motivo=jogo-aberto$') 'jogo aberto: ATUALIZACAO adiada'
Assert-Verdade (-not (Tem-LinhaLike $s4.Saida '^BACKUP ')) 'jogo aberto: nenhuma linha BACKUP'
Assert-Verdade (-not (Tem-LinhaLike $s4.Saida '^ATUALIZADO ')) 'jogo aberto: nenhuma atualizacao aplicada'
Assert-Verdade (Tem-LinhaLike $s4.Saida '^AUDITORIA ') 'jogo aberto: a auditoria roda mesmo assim'
$m4 = Get-Content -LiteralPath (Join-Path $a4.Estado 'addons\addona.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-Igual '1.0.0' $m4.versao 'jogo aberto: addon continua na 1.0.0'

# ---------------------------------------------------------------- 5. sem a pasta WTF

$a5 = New-Cenario 'sessao-sem-wtf'
Remove-Item -LiteralPath (Join-Path $a5.Raiz "$($a5.Flavor)\WTF") -Recurse -Force
$s5 = Invoke-ScriptTeste -Script $SessaoScript -Argumentos $a5.ArgsComuns
Assert-Igual 0 $s5.Codigo 'sem WTF: codigo 0'
Assert-Verdade (Tem-LinhaLike $s5.Saida '^BACKUP sem-wtf$') 'sem WTF: linha BACKUP sem-wtf'
Assert-Verdade (-not (Tem-LinhaLike $s5.Saida '^BACKUP ok')) 'sem WTF: nenhum BACKUP ok'

# ---------------------------------------------------------------- fim

$res = Get-Resultado
if (-not $Manter) { Remove-AmbientesTeste }
if ($res.Falhas.Count -gt 0) {
    foreach ($f in $res.Falhas) { Write-Output "FALHOU: $f" }
    exit 1
}
Write-Output "OK $($res.Total) verificacoes"
exit 0
