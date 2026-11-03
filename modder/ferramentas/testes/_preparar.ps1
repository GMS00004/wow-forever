# Ajudantes de preparo dos testes. Uso: . (Join-Path $PSScriptRoot '_preparar.ps1')
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$script:TestesDir = $PSScriptRoot
$script:AmbientesCriados = New-Object System.Collections.ArrayList

function Clear-VariaveisWowAgente {
    foreach ($n in @('WOWAGENTE_JOGO_ABERTO', 'WOWAGENTE_RESPOSTAS', 'WOWAGENTE_FALHAR_COPIA')) {
        Remove-Item -LiteralPath "Env:\$n" -ErrorAction SilentlyContinue
    }
}

function New-AmbienteTeste {
    param([Parameter(Mandatory)][string]$Nome)
    Clear-VariaveisWowAgente
    $hex = [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $base = Join-Path (Join-Path $script:TestesDir 'tmp') "$Nome-$hex"
    [void](New-Item -ItemType Directory -Path $base -Force)
    Copy-Item -LiteralPath (Join-Path $script:TestesDir 'fixture\World of Warcraft') -Destination $base -Recurse
    $estado = Join-Path $base 'estado'
    $backups = Join-Path $base 'backups'
    [void](New-Item -ItemType Directory -Path $estado -Force)
    [void](New-Item -ItemType Directory -Path $backups -Force)
    $raiz = Join-Path $base 'World of Warcraft'
    [void]$script:AmbientesCriados.Add($base)
    return [pscustomobject]@{
        Base       = $base
        Raiz       = $raiz
        Flavor     = '_forever_'
        Estado     = $estado
        Backups    = $backups
        ArgsComuns = @('-Raiz', $raiz, '-Flavor', '_forever_', '-Estado', $estado, '-Backups', $backups)
    }
}

function New-ZipDeFixture {
    param([Parameter(Mandatory)]$Ambiente, [Parameter(Mandatory)][string[]]$Addons, [Parameter(Mandatory)][string]$Nome)
    $dir = Join-Path $Ambiente.Base 'zips'
    if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
    $zip = Join-Path $dir $Nome
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    $fontes = Join-Path $script:TestesDir 'fontes-fixture'
    $arq = [System.IO.Compression.ZipFile]::Open($zip, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($a in $Addons) {
            $raiz = (Resolve-Path -LiteralPath (Join-Path $fontes $a)).ProviderPath
            $pai = [IO.Path]::GetDirectoryName($raiz)
            foreach ($f in @(Get-ChildItem -LiteralPath $raiz -Recurse -File)) {
                $rel = $f.FullName.Substring((Resolve-Path -LiteralPath $fontes).ProviderPath.Length + 1).Replace('\', '/')
                [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($arq, $f.FullName, $rel)
            }
        }
    } finally { $arq.Dispose() }
    return $zip
}

function Set-RespostasSimuladas {
    param([Parameter(Mandatory)]$Ambiente, [Parameter(Mandatory)][hashtable]$Arquivos)
    $dir = Join-Path $Ambiente.Base 'respostas'
    if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
    foreach ($k in $Arquivos.Keys) {
        $c = $Arquivos[$k]
        if ($c -isnot [string]) { $c = $c | ConvertTo-Json -Depth 10 }
        [System.IO.File]::WriteAllText((Join-Path $dir $k), $c, (New-Object System.Text.UTF8Encoding $false))
    }
    $env:WOWAGENTE_RESPOSTAS = $dir
}

function Invoke-ScriptTeste {
    param([Parameter(Mandatory)][string]$Script, [string[]]$Argumentos = @())
    $antes = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $saida = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Script @Argumentos 2>&1
        $codigo = $LASTEXITCODE
    } finally { $ErrorActionPreference = $antes }
    $texto = (@($saida | ForEach-Object { [string]$_ }) -join "`n")
    return [pscustomobject]@{ Saida = $texto; Codigo = $codigo }
}

function Remove-AmbientesTeste {
    foreach ($b in @($script:AmbientesCriados.ToArray())) {
        if (Test-Path -LiteralPath $b) { Remove-Item -LiteralPath $b -Recurse -Force -ErrorAction SilentlyContinue }
    }
    $script:AmbientesCriados.Clear()
    Clear-VariaveisWowAgente
}
