# Teste de ponta a ponta dos CLIs addon-instalar.ps1 e addon-remover.ps1 (contrato §9.1 e §9.2).
# Roda os scripts como processo filho. Sem rede: so zips locais gerados aqui.
param([switch]$Manter)
$ErrorActionPreference = 'Stop'
$Aqui = $PSScriptRoot
. (Join-Path $Aqui '_assert.ps1')
. (Join-Path $Aqui '_preparar.ps1')

$Instalar = [IO.Path]::GetFullPath((Join-Path $Aqui '..\addon-instalar.ps1'))
$Remover = [IO.Path]::GetFullPath((Join-Path $Aqui '..\addon-remover.ps1'))

# ---------------------------------------------------------------- ajudantes locais

function Tem-Linha {
    param([string]$Saida, [string]$Padrao)
    return (@($Saida -split "`r?`n" | Where-Object { $_ -match $Padrao }).Count -gt 0)
}

function Get-AddOnsDe {
    param($Amb)
    return (Join-Path $Amb.Raiz "$($Amb.Flavor)\Interface\AddOns")
}

function Get-ManifestoJson {
    param($Amb, [string]$Slug)
    $p = Join-Path $Amb.Estado "addons\$Slug.json"
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return $null }
    return (Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Get-EntradasZipTeste {
    param([string]$Zip)
    $z = [System.IO.Compression.ZipFile]::OpenRead($Zip)
    try { return @($z.Entries | ForEach-Object { $_.FullName }) } finally { $z.Dispose() }
}

function New-ZipDePastaTeste {
    param([Parameter(Mandatory)][string]$Pasta, [Parameter(Mandatory)][string]$Zip)
    if (Test-Path -LiteralPath $Zip) { Remove-Item -LiteralPath $Zip -Force }
    $full = (Resolve-Path -LiteralPath $Pasta).ProviderPath
    $pai = [IO.Path]::GetDirectoryName($full)
    $arq = [System.IO.Compression.ZipFile]::Open($Zip, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($f in @(Get-ChildItem -LiteralPath $full -Recurse -File)) {
            $rel = $f.FullName.Substring($pai.Length + 1).Replace('\', '/')
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($arq, $f.FullName, $rel)
        }
    } finally { $arq.Dispose() }
    return $Zip
}

# Copia a AddonA da fontes-fixture para o tmp do teste, troca o ## Version e gera o zip.
function New-ZipAddonAVersao {
    param($Amb, [string]$Versao)
    $dir = Join-Path $Amb.Base 'variante'
    [void](New-Item -ItemType Directory -Path $dir -Force)
    Copy-Item -LiteralPath (Join-Path $Aqui 'fontes-fixture\AddonA') -Destination $dir -Recurse -Force
    $pasta = Join-Path $dir 'AddonA'
    $toc = Join-Path $pasta 'AddonA.toc'
    $txt = [System.IO.File]::ReadAllText($toc)
    $novo = $txt -replace '## Version:\s*\S+', "## Version: $Versao"
    [System.IO.File]::WriteAllText($toc, $novo, (New-Object System.Text.UTF8Encoding $false))
    $zips = Join-Path $Amb.Base 'zips'
    [void](New-Item -ItemType Directory -Path $zips -Force)
    return (New-ZipDePastaTeste -Pasta $pasta -Zip (Join-Path $zips "addona-$Versao.zip"))
}

function Invoke-Instalar {
    param([string[]]$Argumentos)
    return (Invoke-ScriptTeste -Script $Instalar -Argumentos $Argumentos)
}

function Invoke-Remover {
    param([string[]]$Argumentos)
    return (Invoke-ScriptTeste -Script $Remover -Argumentos $Argumentos)
}

# ---------------------------------------------------------------- casos

try {

# 1. Previa de um zip com AddonA: nada gravado.
$amb = New-AmbienteTeste -Nome 'instalar-previa'
$zip = New-ZipDeFixture -Ambiente $amb -Addons @('AddonA') -Nome 'addona.zip'
$r = Invoke-Instalar (@('-Fonte', "zip:$zip", '-Slug', 'addona') + $amb.ArgsComuns)
Assert-Igual 0 $r.Codigo 'previa: codigo 0'
Assert-Verdade (Tem-Linha $r.Saida '^PREVIA ') 'previa: linha PREVIA'
Assert-Verdade (Tem-Linha $r.Saida '^PASTA nome=AddonA ') 'previa: linha PASTA'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path (Get-AddOnsDe $amb) 'AddonA'))) 'previa: nao criou a pasta AddonA'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $amb.Estado 'addons\addona.json'))) 'previa: nao gravou manifesto'
Assert-Igual 0 @(Get-ChildItem -LiteralPath $amb.Backups -Recurse -File).Count 'previa: nao gravou backup'

# 2. -Aplicar com AddonA: instala, manifesto aprovado, registro.
$amb = New-AmbienteTeste -Nome 'instalar'
$zip = New-ZipDeFixture -Ambiente $amb -Addons @('AddonA') -Nome 'addona.zip'
$r = Invoke-Instalar (@('-Fonte', "zip:$zip", '-Slug', 'addona', '-Aplicar') + $amb.ArgsComuns)
Assert-Igual 0 $r.Codigo 'aplicar: codigo 0'
Assert-Verdade (Tem-Linha $r.Saida '^OK instalado slug=addona versao=1\.0\.0') 'aplicar: linha OK instalado'
Assert-Verdade (Test-Path -LiteralPath (Join-Path (Get-AddOnsDe $amb) 'AddonA') -PathType Container) 'aplicar: pasta AddonA existe'
$m = Get-ManifestoJson $amb 'addona'
Assert-Verdade ($null -ne $m) 'aplicar: manifesto existe'
Assert-Igual 'instalado' $m.estadoInstalacao 'aplicar: estadoInstalacao instalado'
Assert-Igual $true $m.aprovado 'aplicar: aprovado'
Assert-Igual '1.0.0' $m.versao 'aplicar: versao 1.0.0'
Assert-Verdade (Get-Content -LiteralPath (Join-Path $amb.Estado 'registro.md') -Raw -Encoding UTF8 | Select-String -Pattern '\| instalar \| addona \|' -Quiet) 'aplicar: registro tem instalar'

# 3. Reinstalar a mesma versao sem -Forcar: nada a fazer.
$r = Invoke-Instalar (@('-Fonte', "zip:$zip", '-Slug', 'addona', '-Aplicar') + $amb.ArgsComuns)
Assert-Igual 0 $r.Codigo 'nada a fazer: codigo 0'
Assert-Verdade (Tem-Linha $r.Saida '^OK nada a fazer slug=addona versao=1\.0\.0') 'nada a fazer: linha OK nada a fazer'

# 4. Atualizar para 1.1.0 (variante gerada do TOC da fixture): backup, versao nova, instaladoEm preservado.
$antes = Get-ManifestoJson $amb 'addona'
$zip110 = New-ZipAddonAVersao -Amb $amb -Versao '1.1.0'
$r = Invoke-Instalar (@('-Fonte', "zip:$zip110", '-Slug', 'addona', '-Aplicar') + $amb.ArgsComuns)
Assert-Igual 0 $r.Codigo 'atualizar: codigo 0'
Assert-Verdade (Tem-Linha $r.Saida '^OK atualizado slug=addona de=1\.0\.0 para=1\.1\.0') 'atualizar: linha OK atualizado de=1.0.0 para=1.1.0'
$zipsBackup = @(Get-ChildItem -LiteralPath (Join-Path $amb.Backups 'addons\addona') -Filter '*.zip' -File -ErrorAction SilentlyContinue)
Assert-Verdade ($zipsBackup.Count -ge 1) 'atualizar: zip de backup em backups\addons\addona'
$depois = Get-ManifestoJson $amb 'addona'
Assert-Igual '1.1.0' $depois.versao 'atualizar: manifesto com a versao nova'
Assert-Igual ([string]$antes.instaladoEm) ([string]$depois.instaladoEm) 'atualizar: instaladoEm preservado'
Assert-Verdade ($null -ne $depois.backupAnterior) 'atualizar: backupAnterior preenchido'

# 5. AddonClassic (incompativel): RECUSA; com -Forcar instala.
$amb = New-AmbienteTeste -Nome 'instalar-classic'
$zip = New-ZipDeFixture -Ambiente $amb -Addons @('AddonClassic') -Nome 'classic.zip'
$r = Invoke-Instalar (@('-Fonte', "zip:$zip", '-Slug', 'classic', '-Aplicar') + $amb.ArgsComuns)
Assert-Igual 1 $r.Codigo 'incompativel: codigo 1'
Assert-Verdade (Tem-Linha $r.Saida '^RECUSA ') 'incompativel: linha RECUSA'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path (Get-AddOnsDe $amb) 'AddonClassic'))) 'incompativel: nada instalado'
$r = Invoke-Instalar (@('-Fonte', "zip:$zip", '-Slug', 'classic', '-Forcar', '-Aplicar') + $amb.ArgsComuns)
Assert-Igual 0 $r.Codigo 'forcar: codigo 0'
Assert-Verdade (Test-Path -LiteralPath (Join-Path (Get-AddOnsDe $amb) 'AddonClassic') -PathType Container) 'forcar: pasta instalada'
Assert-Igual 'instalado' (Get-ManifestoJson $amb 'classic').estadoInstalacao 'forcar: manifesto instalado'

# 6. Conflito: a pasta AddonA ja pertence a outro slug.
$amb = New-AmbienteTeste -Nome 'instalar-conflito'
$zip = New-ZipDeFixture -Ambiente $amb -Addons @('AddonA') -Nome 'addona.zip'
$r = Invoke-Instalar (@('-Fonte', "zip:$zip", '-Slug', 'addona', '-Aplicar') + $amb.ArgsComuns)
Assert-Igual 0 $r.Codigo 'conflito: pre-condicao instalada'
$r = Invoke-Instalar (@('-Fonte', "zip:$zip", '-Slug', 'outro', '-Aplicar') + $amb.ArgsComuns)
Assert-Igual 1 $r.Codigo 'conflito: codigo 1'
Assert-Verdade (Tem-Linha $r.Saida '^RECUSA .*pertence ao addon addona') 'conflito: RECUSA pertence ao addon addona'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $amb.Estado 'addons\outro.json'))) 'conflito: nao gravou manifesto do outro'

# 7. Jogo aberto: a previa passa, -Aplicar recusa.
$amb = New-AmbienteTeste -Nome 'instalar-jogo'
$zip = New-ZipDeFixture -Ambiente $amb -Addons @('AddonA') -Nome 'addona.zip'
$env:WOWAGENTE_JOGO_ABERTO = '1'
try {
    $r = Invoke-Instalar (@('-Fonte', "zip:$zip", '-Slug', 'addona') + $amb.ArgsComuns)
    Assert-Igual 0 $r.Codigo 'jogo aberto: previa codigo 0'
    $r = Invoke-Instalar (@('-Fonte', "zip:$zip", '-Slug', 'addona', '-Aplicar') + $amb.ArgsComuns)
    Assert-Igual 1 $r.Codigo 'jogo aberto: -Aplicar codigo 1'
    Assert-Verdade (Tem-Linha $r.Saida '^RECUSA Jogo aberto') 'jogo aberto: linha RECUSA'
    Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path (Get-AddOnsDe $amb) 'AddonA'))) 'jogo aberto: nada instalado'
} finally {
    Remove-Item -LiteralPath 'Env:\WOWAGENTE_JOGO_ABERTO' -ErrorAction SilentlyContinue
}

# 8. AddonMulti e AddonMulti_Options num zip so: duas pastas no manifesto.
$amb = New-AmbienteTeste -Nome 'instalar-multi'
$zip = New-ZipDeFixture -Ambiente $amb -Addons @('AddonMulti', 'AddonMulti_Options') -Nome 'multi.zip'
$r = Invoke-Instalar (@('-Fonte', "zip:$zip", '-Slug', 'multi', '-Aplicar') + $amb.ArgsComuns)
Assert-Igual 0 $r.Codigo 'multi: codigo 0'
$m = Get-ManifestoJson $amb 'multi'
$nomesMulti = @(@($m.pastas) | ForEach-Object { [string]$_.nome })
Assert-Igual 2 $nomesMulti.Count 'multi: duas pastas no manifesto'
Assert-Verdade ($nomesMulti -contains 'AddonMulti') 'multi: manifesto lista AddonMulti'
Assert-Verdade ($nomesMulti -contains 'AddonMulti_Options') 'multi: manifesto lista AddonMulti_Options'

# 9. Remover: previa nao apaga; -Aplicar apaga, faz backup, marca removido e registra.
$amb = New-AmbienteTeste -Nome 'remover'
$zip = New-ZipDeFixture -Ambiente $amb -Addons @('AddonA') -Nome 'addona.zip'
$r = Invoke-Instalar (@('-Fonte', "zip:$zip", '-Slug', 'addona', '-Aplicar') + $amb.ArgsComuns)
Assert-Igual 0 $r.Codigo 'remover: pre-condicao instalada'
$pastaA = Join-Path (Get-AddOnsDe $amb) 'AddonA'
$r = Invoke-Remover (@('-Slug', 'addona') + $amb.ArgsComuns)
Assert-Igual 0 $r.Codigo 'remover previa: codigo 0'
Assert-Verdade (Tem-Linha $r.Saida '^PREVIA slug=addona acao=remover') 'remover previa: linha PREVIA'
Assert-Verdade (Tem-Linha $r.Saida '^PASTA nome=AddonA acao=remover') 'remover previa: linha PASTA'
Assert-Verdade (Test-Path -LiteralPath $pastaA -PathType Container) 'remover previa: pasta continua'
Assert-Igual 'instalado' (Get-ManifestoJson $amb 'addona').estadoInstalacao 'remover previa: manifesto continua instalado'
Assert-Igual 0 @(Get-ChildItem -LiteralPath $amb.Backups -Recurse -File).Count 'remover previa: nao gravou backup'
$r = Invoke-Remover (@('-Slug', 'addona', '-Aplicar') + $amb.ArgsComuns)
Assert-Igual 0 $r.Codigo 'remover -Aplicar: codigo 0'
Assert-Verdade (Tem-Linha $r.Saida '^OK removido slug=addona') 'remover -Aplicar: linha OK removido'
Assert-Verdade (-not (Test-Path -LiteralPath $pastaA)) 'remover -Aplicar: pasta apagada'
$m = Get-ManifestoJson $amb 'addona'
Assert-Igual 'removido' $m.estadoInstalacao 'remover -Aplicar: estadoInstalacao removido'
Assert-Verdade ($m.backupAnterior -and (Test-Path -LiteralPath $m.backupAnterior -PathType Leaf)) 'remover -Aplicar: zip de backup existe'
Assert-Verdade (@(Get-EntradasZipTeste $m.backupAnterior) -contains 'AddonA/AddonA.toc') 'remover -Aplicar: backup tem a pasta'
Assert-Verdade (Get-Content -LiteralPath (Join-Path $amb.Estado 'registro.md') -Raw -Encoding UTF8 | Select-String -Pattern '\| remover \| addona \|' -Quiet) 'remover -Aplicar: registro tem remover'

# 10. Remover um slug inexistente: PREREQ, codigo 2.
$amb = New-AmbienteTeste -Nome 'remover-inexistente'
$r = Invoke-Remover (@('-Slug', 'nunca-existiu') + $amb.ArgsComuns)
Assert-Igual 2 $r.Codigo 'remover inexistente: codigo 2'
Assert-Verdade (Tem-Linha $r.Saida '^PREREQ ') 'remover inexistente: linha PREREQ'

# 11. Sem instalacao configurada: sem -Raiz/-Flavor e -Instalacao apontando para arquivo inexistente.
$amb = New-AmbienteTeste -Nome 'sem-config'
$zip = New-ZipDeFixture -Ambiente $amb -Addons @('AddonA') -Nome 'addona.zip'
$inst = Join-Path $amb.Base 'nao-existe\instalacao.json'
$r = Invoke-Instalar @('-Fonte', "zip:$zip", '-Slug', 'addona', '-Estado', $amb.Estado, '-Backups', $amb.Backups, '-Instalacao', $inst)
Assert-Igual 2 $r.Codigo 'sem config: codigo 2'
Assert-Verdade (Tem-Linha $r.Saida '^PREREQ ') 'sem config: linha PREREQ'

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
