# Teste de addon-fontes.ps1 e addon-atualizar.ps1 (contrato §9.6 e §9.7). Sem rede: respostas simuladas e zips locais.
param([switch]$Manter)
$ErrorActionPreference = 'Stop'
$Aqui = $PSScriptRoot
. (Join-Path $Aqui '_assert.ps1')
. (Join-Path $Aqui '_preparar.ps1')
. (Join-Path $Aqui '..\wow-comum.ps1')

$FontesScript = [IO.Path]::GetFullPath((Join-Path $Aqui '..\addon-fontes.ps1'))
$AtualizarScript = [IO.Path]::GetFullPath((Join-Path $Aqui '..\addon-atualizar.ps1'))

# ---------------------------------------------------------------- ajudantes locais

function Get-Linhas {
    param([string]$Texto)
    return @($Texto -split "`n" | ForEach-Object { $_.TrimEnd() })
}

function Tem-LinhaLike {
    param([string]$Texto, [string]$Padrao)
    return (@(Get-Linhas $Texto | Where-Object { $_ -cmatch $Padrao }).Count -gt 0)
}

function Get-ManifestoJson {
    param($A, [string]$Slug)
    $p = Join-Path $A.Estado "addons\$Slug.json"
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return $null }
    return (Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json)
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

# Resposta de releases/latest sem release.json, com um asset zip.
function New-GhSemRelease {
    param([string]$Tag, [string]$NomeZip, [string]$ZipLocal)
    return [pscustomobject]@{
        tag_name     = $Tag
        published_at = '2026-10-25T12:00:00Z'
        assets       = @([pscustomobject]@{ name = $NomeZip; browser_download_url = $ZipLocal })
    }
}

function Escrever-Manifesto {
    param($A, [string]$Slug, [string]$Json)
    $dir = Join-Path $A.Estado 'addons'
    [void](New-Item -ItemType Directory -Path $dir -Force)
    [System.IO.File]::WriteAllText((Join-Path $dir "$Slug.json"), $Json, (New-Object System.Text.UTF8Encoding $false))
}

# ---------------------------------------------------------------- 1. addon-fontes com GitHub e release.json

$a1 = New-AmbienteTeste 'atu-fontes-gh'
$zip1 = New-ZipAddonA $a1 '1.1.0' 'AddonA-1.1.0.zip'
$rl1 = [pscustomobject]@{ releases = @([pscustomobject]@{
    name = 'AddonA'; version = '1.1.0'; filename = 'AddonA-1.1.0.zip'; nolib = $false
    metadata = @([pscustomobject]@{ flavor = 'forever'; interface = 16001 }) }) }
$gh1 = [pscustomobject]@{
    tag_name = 'v1.1.0'; published_at = '2026-10-25T12:00:00Z'
    assets = @(
        [pscustomobject]@{ name = 'AddonA-1.1.0.zip'; browser_download_url = $zip1 },
        [pscustomobject]@{ name = 'release.json'; browser_download_url = 'https://github.com/dono/exemplo/releases/download/v1.1.0/release.json' }) }
Set-RespostasSimuladas -Ambiente $a1 -Arquivos @{ 'github-dono_exemplo.json' = $gh1; 'github-dono_exemplo-release.json' = $rl1 }

$r = Invoke-ScriptTeste -Script $FontesScript -Argumentos (@('-Fonte', 'github:dono/exemplo') + $a1.ArgsComuns)
Assert-Igual 0 $r.Codigo 'addon-fontes github: codigo 0'
Assert-Verdade (Tem-LinhaLike $r.Saida '^FONTE tipo=github id=dono/exemplo versao=1\.1\.0 .* compativel=sim ') 'addon-fontes github: linha FONTE com versao do release.json e compativel=sim'

$rj = Invoke-ScriptTeste -Script $FontesScript -Argumentos (@('-Fonte', 'github:dono/exemplo', '-Json') + $a1.ArgsComuns)
Assert-Igual 0 $rj.Codigo 'addon-fontes -Json: codigo 0'
$obj1 = $null
try { $obj1 = $rj.Saida.Trim() | ConvertFrom-Json } catch { $obj1 = $null }
Assert-Verdade ($null -ne $obj1) 'addon-fontes -Json: JSON valido'
if ($obj1) {
    Assert-Igual '1.1.0' $obj1.versao 'addon-fontes -Json: versao'
    Assert-Igual $true $obj1.compativel 'addon-fontes -Json: compativel'
}

# ---------------------------------------------------------------- 2. addon-fontes com Tukui

$a2 = New-AmbienteTeste 'atu-fontes-tk'
$zip2 = New-ZipAddonA $a2 '3.4.5' 'Exemplo-3.4.5.zip'
$tk1 = [pscustomobject]@{ id = 1; slug = 'exemplo'; name = 'Exemplo'; version = '3.4.5'; url = $zip2
    last_update = '2026-10-25'; patch = [string[]]@('1.60.1', '1.15.9') }
Set-RespostasSimuladas -Ambiente $a2 -Arquivos @{ 'tukui-exemplo.json' = $tk1 }
$t1 = Invoke-ScriptTeste -Script $FontesScript -Argumentos (@('-Fonte', 'tukui:exemplo') + $a2.ArgsComuns)
Assert-Igual 0 $t1.Codigo 'addon-fontes tukui com 1.60.1: codigo 0'
Assert-Verdade (Tem-LinhaLike $t1.Saida '^FONTE tipo=tukui id=exemplo versao=3\.4\.5 .* compativel=sim ') 'addon-fontes tukui com patch 1.60.1: compativel=sim'

$tk2 = [pscustomobject]@{ id = 1; slug = 'exemplo'; name = 'Exemplo'; version = '3.4.5'; url = $zip2
    last_update = '2026-10-25'; patch = [string[]]@('1.15.9') }
Set-RespostasSimuladas -Ambiente $a2 -Arquivos @{ 'tukui-exemplo.json' = $tk2 }
$t2 = Invoke-ScriptTeste -Script $FontesScript -Argumentos (@('-Fonte', 'tukui:exemplo') + $a2.ArgsComuns)
Assert-Igual 0 $t2.Codigo 'addon-fontes tukui sem 1.60.1: codigo 0'
Assert-Verdade (Tem-LinhaLike $t2.Saida '^FONTE tipo=tukui id=exemplo .* compativel=nao ') 'addon-fontes tukui sem patch 1.60.1: compativel=nao'

# ---------------------------------------------------------------- 3. addon-fontes sem instalacao configurada

$a3 = New-AmbienteTeste 'atu-fontes-sem'
$zip3 = New-ZipAddonA $a3 '1.1.0' 'AddonA-1.1.0.zip'
$gh3 = New-GhSemRelease '1.1.0' 'AddonA-1.1.0.zip' $zip3
Set-RespostasSimuladas -Ambiente $a3 -Arquivos @{ 'github-dono_exemplo.json' = $gh3 }
$semInst = Join-Path $a3.Base 'inexistente\inst.json'
$s3 = Invoke-ScriptTeste -Script $FontesScript -Argumentos @('-Fonte', 'github:dono/exemplo', '-Instalacao', $semInst, '-Estado', $a3.Estado, '-Backups', $a3.Backups)
Assert-Igual 0 $s3.Codigo 'addon-fontes sem instalacao: codigo 0'
Assert-Verdade (Tem-LinhaLike $s3.Saida '^FONTE tipo=github id=dono/exemplo versao=1\.1\.0 .* compativel=\? ') 'addon-fontes sem instalacao: compativel=?'

# ---------------------------------------------------------------- 4. addon-atualizar: previa e aplicacao

$a4 = New-AmbienteTeste 'atu-run'
$env:WOWAGENTE_JOGO_ABERTO = '0'
$zip10 = New-ZipAddonA $a4 '1.0.0' 'AddonA-1.0.0.zip'
Set-RespostasSimuladas -Ambiente $a4 -Arquivos @{ 'github-dono_exemplo.json' = (New-GhSemRelease '1.0.0' 'AddonA-1.0.0.zip' $zip10) }

# instalacao inicial pela biblioteca (versao 1.0.0)
$ctx4 = Get-WowContexto -Raiz $a4.Raiz -Flavor $a4.Flavor -Estado $a4.Estado -Backups $a4.Backups -Instalacao (Join-Path $a4.Base 'inst.json')
$null = & { Install-AddonDeFonte -Contexto $ctx4 -Fonte 'github:dono/exemplo' -Slug 'addona' -Nome 'Addon A' -Aplicar } 6>&1
$m0 = Get-ManifestoJson $a4 'addona'
Assert-Igual '1.0.0' $m0.versao 'preparo: addona instalado na 1.0.0'

# a fonte passa a ter a 1.1.0
$zip11 = New-ZipAddonA $a4 '1.1.0' 'AddonA-1.1.0.zip'
Set-RespostasSimuladas -Ambiente $a4 -Arquivos @{ 'github-dono_exemplo.json' = (New-GhSemRelease '1.1.0' 'AddonA-1.1.0.zip' $zip11) }

$pv = Invoke-ScriptTeste -Script $AtualizarScript -Argumentos (@('-Slug', 'addona') + $a4.ArgsComuns)
Assert-Igual 0 $pv.Codigo 'addon-atualizar previa: codigo 0'
Assert-Verdade (Tem-LinhaLike $pv.Saida '^ATUALIZAR slug=addona de=1\.0\.0 para=1\.1\.0$') 'addon-atualizar previa: linha ATUALIZAR'
$m1 = Get-ManifestoJson $a4 'addona'
Assert-Igual '1.0.0' $m1.versao 'addon-atualizar previa: manifesto continua na 1.0.0'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $a4.Backups 'addons'))) 'addon-atualizar previa: nenhum backup criado'

$ap = Invoke-ScriptTeste -Script $AtualizarScript -Argumentos (@('-Slug', 'addona', '-Aplicar') + $a4.ArgsComuns)
Assert-Igual 0 $ap.Codigo 'addon-atualizar -Aplicar: codigo 0'
Assert-Verdade (Tem-LinhaLike $ap.Saida '^ATUALIZADO slug=addona de=1\.0\.0 para=1\.1\.0$') 'addon-atualizar -Aplicar: linha ATUALIZADO'
Assert-Verdade (-not (Tem-LinhaLike $ap.Saida '^(PREVIA|PASTA|OK) ')) 'addon-atualizar -Aplicar: saida da instalacao nao repassada'
$m2 = Get-ManifestoJson $a4 'addona'
Assert-Igual '1.1.0' $m2.versao 'addon-atualizar -Aplicar: manifesto na 1.1.0'
Assert-Verdade ($null -ne $m2.backupAnterior -and (Test-Path -LiteralPath $m2.backupAnterior)) 'addon-atualizar -Aplicar: backup da versao anterior existe'
$toc4 = Get-Content -LiteralPath (Join-Path $a4.Raiz "$($a4.Flavor)\Interface\AddOns\AddonA\AddonA.toc") -Raw -Encoding UTF8
Assert-Verdade ($toc4 -match '## Version: 1\.1\.0') 'addon-atualizar -Aplicar: pasta AddOns na 1.1.0'

# ---------------------------------------------------------------- 5. mesma versao: nada a fazer

$same = Invoke-ScriptTeste -Script $AtualizarScript -Argumentos (@('-Aplicar') + $a4.ArgsComuns)
Assert-Igual 0 $same.Codigo 'mesma versao: codigo 0'
Assert-Verdade (-not (Tem-LinhaLike $same.Saida '^ATUALIZAR ')) 'mesma versao: nenhuma linha ATUALIZAR'

# ---------------------------------------------------------------- 6 e 7. manifesto zip (MANUAL) e dev (ignorado)

$zipJson = @'
{
  "v": 1,
  "slug": "zipaddon",
  "nome": "Zip Addon",
  "versao": "1.0.0",
  "fonte": { "tipo": "zip", "id": "C:\\zips\\zipaddon.zip", "asset": null, "pagina": "https://www.curseforge.com/wow/addons/zipaddon" },
  "pastas": [],
  "aprovado": true,
  "estadoInstalacao": "instalado",
  "instaladoEm": "2026-11-01T10:00:00-03:00",
  "atualizadoEm": "2026-11-01T10:00:00-03:00",
  "removidoEm": null,
  "backupAnterior": null,
  "maquina": "PC-AVELL"
}
'@
Escrever-Manifesto $a4 'zipaddon' $zipJson

$devJson = @'
{
  "v": 1,
  "slug": "devaddon",
  "nome": "Dev Addon",
  "versao": "dev",
  "fonte": { "tipo": "dev", "id": "C:\\dev\\devaddon", "asset": null, "pagina": null },
  "pastas": [],
  "aprovado": true,
  "estadoInstalacao": "instalado",
  "instaladoEm": "2026-11-01T10:00:00-03:00",
  "atualizadoEm": "2026-11-01T10:00:00-03:00",
  "removidoEm": null,
  "backupAnterior": null,
  "maquina": "PC-AVELL"
}
'@
Escrever-Manifesto $a4 'devaddon' $devJson

$zz = Invoke-ScriptTeste -Script $AtualizarScript -Argumentos $a4.ArgsComuns
Assert-Igual 0 $zz.Codigo 'manifesto zip e dev: codigo 0'
Assert-Verdade (Tem-LinhaLike $zz.Saida '^MANUAL slug=zipaddon pagina=https://www\.curseforge\.com/wow/addons/zipaddon$') 'manifesto zip: linha MANUAL'
Assert-Verdade (-not ($zz.Saida -match 'devaddon')) 'manifesto dev: ignorado (nenhuma linha)'

# ---------------------------------------------------------------- 8. falha num addon nao para os outros

$falhaJson = @'
{
  "v": 1,
  "slug": "falha",
  "nome": "Falha",
  "versao": "1.0.0",
  "fonte": { "tipo": "github", "id": "dono/falha", "asset": null, "pagina": null },
  "pastas": [],
  "aprovado": true,
  "estadoInstalacao": "instalado",
  "instaladoEm": "2026-11-01T10:00:00-03:00",
  "atualizadoEm": "2026-11-01T10:00:00-03:00",
  "removidoEm": null,
  "backupAnterior": null,
  "maquina": "PC-AVELL"
}
'@
Escrever-Manifesto $a4 'falha' $falhaJson

$fl = Invoke-ScriptTeste -Script $AtualizarScript -Argumentos $a4.ArgsComuns
Assert-Igual 1 $fl.Codigo 'falha num addon: codigo 1'
Assert-Verdade (Tem-LinhaLike $fl.Saida '^FALHOU slug=falha motivo=.+') 'falha num addon: linha FALHOU para ele'
Assert-Verdade (Tem-LinhaLike $fl.Saida '^MANUAL slug=zipaddon ') 'falha num addon: os outros seguem (MANUAL depois da falha)'

# ---------------------------------------------------------------- fim

$res = Get-Resultado
if (-not $Manter) { Remove-AmbientesTeste }
if ($res.Falhas.Count -gt 0) {
    foreach ($f in $res.Falhas) { Write-Output "FALHOU: $f" }
    exit 1
}
Write-Output "OK $($res.Total) verificacoes"
exit 0
