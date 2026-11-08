# Monta o Kit do WoW Forever para o amigo do Bruno: copia da pasta AddOns desta maquina as pastas
# escolhidas (ja filtradas para o Forever e auditadas), soma o addon proprio !KitAmigo, embute o
# instalador (kit\instalar.ps1) num INSTALAR.bat de arquivo unico e grava Kit-WoW-Forever.zip no Drive.
# Mesmo nome de arquivo a cada geracao: o link compartilhado do Drive continua valendo.
# So le a pasta do jogo; grava no -Destino. Sem -Aplicar, so previa.
# Uso: kit-amigo.ps1 [-Destino <dir>] [-Aplicar] mais -Raiz -Flavor -Instalacao -Estado -Backups (CONTRATO.md §3).
param(
    [string]$Destino,
    [switch]$Aplicar,
    [string]$Raiz,
    [string]$Flavor,
    [string]$Instalacao,
    [string]$Estado,
    [string]$Backups
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'wow-comum.ps1')

# Escolha do dono em 2026-11-08: base (RestedXP, Questie, Leatrix, Pawn, Auctionator) e os opcionais
# Baganator e DBM com dungeons (sem raides). O amigo nao fala ingles: sairam o Naowh Training (so em
# ingles), o Forever Quests (so texto em ingles nas dicas) e a voz do DBM (DBM-VPVEM, fala em ingles).
# O RestedXP fica por pedido do dono, mesmo com a rota do Forever sem traducao (a seta guia sem ler).
$PASTAS_TERCEIROS = @(
    'RXPGuides', 'Questie', 'QuestieDB', 'Leatrix_Plus', 'Pawn', 'Auctionator',
    'Baganator', 'Syndicator',
    'DBM-Core', 'DBM-GUI', 'DBM-StatusBarTimers', 'DBM-Party-Vanilla', 'DBM-Party-Forever', 'DBM-Azeroth'
)
$PASTAS_PROPRIAS = @('!KitAmigo')

$CABECALHO = @'
@echo off
title Kit do WoW Forever
echo Instalando o Kit do WoW Forever. Nao feche esta janela.
set "KITWOW_BAT=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:KITWOW_BAT,[Text.Encoding]::UTF8); $i=$t.IndexOf('#'+'KITWOW-PS1'); Invoke-Expression $t.Substring($i)"
exit /b %errorlevel%
#KITWOW-PS1
'@

exit (Invoke-ScriptWow {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups
    if (-not $Destino) { $Destino = 'P:\Meu Drive\WoW Forever\Kit-amigo' }
    $kitFonte = Join-Path $PSScriptRoot 'kit'
    $proprios = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\addons-proprios'))
    $versao = Get-WowVersao -Raiz $ctx.Raiz -Flavor $ctx.Flavor
    if (-not $versao -or -not $versao.Interface) { Stop-Wow PREREQ 'Não consegui ler a Interface do cliente' }
    $interface = [int]$versao.Interface

    # 1. Origem de cada pasta e conferência do TOC
    $itens = New-Object System.Collections.ArrayList
    foreach ($p in $PASTAS_TERCEIROS) { [void]$itens.Add([pscustomobject]@{ Nome = $p; Caminho = (Join-Path $ctx.AddOns $p); Proprio = $false }) }
    foreach ($p in $PASTAS_PROPRIAS) { [void]$itens.Add([pscustomobject]@{ Nome = $p; Caminho = (Join-Path $proprios $p); Proprio = $true }) }
    $nomes = @($itens | ForEach-Object { $_.Nome })
    $problemas = 0
    $totalBytes = [long]0
    foreach ($it in $itens) {
        if (-not (Test-Path -LiteralPath $it.Caminho -PathType Container)) { Write-Linha "PASTA nome=$($it.Nome) acao=falta caminho=$($it.Caminho)"; $problemas++; continue }
        if (-not $it.Proprio -and (Test-Junction $it.Caminho)) { Write-Linha "PASTA nome=$($it.Nome) acao=recusa motivo=junction"; $problemas++; continue }
        $t = Get-TocDoForever -PastaAddon $it.Caminho
        $ok = ($t.Tipo -ne 'nenhum' -and @($t.Info.Interfaces) -contains $interface)
        $faltaDep = @()
        if ($t.Info) { $faltaDep = @(@($t.Info.Dependencias) | Where-Object { $_ -notlike 'Blizzard_*' -and $nomes -notcontains $_ }) }
        $bytes = [long](@(Get-ChildItem -LiteralPath $it.Caminho -Recurse -File -ErrorAction SilentlyContinue) | Measure-Object Length -Sum).Sum
        $totalBytes += $bytes
        $v = '-'; if ($t.Info -and $t.Info.Versao) { $v = $t.Info.Versao }
        $estado = 'ok'
        if (-not $ok) { $estado = "sem-interface-$interface"; $problemas++ }
        if ($faltaDep.Count -gt 0) { $estado = "falta-dependencia:" + ($faltaDep -join '+'); $problemas++ }
        Write-Linha ("PASTA nome={0} versao={1} mb={2:N1} toc={3}" -f $it.Nome, $v, ($bytes / 1MB), $estado)
    }
    Write-Linha ("KIT pastas={0} mb={1:N0} interface={2} destino={3}" -f $itens.Count, ($totalBytes / 1MB), $interface, $Destino)
    if ($problemas -gt 0) { Write-Linha "RECUSA $problemas pasta(s) com problema"; return 1 }
    foreach ($f in @('instalar.ps1')) {
        if (-not (Test-Path -LiteralPath (Join-Path $kitFonte $f) -PathType Leaf)) { Stop-Wow PREREQ "Falta $f em $kitFonte" }
    }
    $pdfs = @(Get-ChildItem -LiteralPath $kitFonte -Filter '*.pdf' -File | ForEach-Object { $_.FullName })
    if ($pdfs.Count -eq 0) { Write-Linha 'AVISO sem PDF na pasta kit: o zip sai sem guia' }
    foreach ($x in $pdfs) { Write-Linha ("GUIA " + [IO.Path]::GetFileName($x)) }
    if (-not $Aplicar) { Write-Linha 'PREVIA nada gravado; rode com -Aplicar'; return 0 }

    # 2. Montagem numa pasta curta
    $tmp = Join-Path $env:TEMP ('wow-agentes\k-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $raizKit = Join-Path $tmp 'Kit-WoW-Forever'
    $arquivos = Join-Path $raizKit 'arquivos'
    [void](New-Item -ItemType Directory -Path $arquivos -Force)
    try {
        $nivel = [IO.Compression.CompressionLevel]::Optimal
        $zipAddons = Join-Path $arquivos 'addons.zip'
        $fs = [IO.File]::Open($zipAddons, [IO.FileMode]::CreateNew)
        $za = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Create)
        $arqs = 0
        try {
            foreach ($it in $itens) {
                $base = [IO.Path]::GetFullPath($it.Caminho).TrimEnd('\')
                foreach ($arq in @(Get-ChildItem -LiteralPath $base -Recurse -File)) {
                    if ($it.Proprio -and $arq.Extension -ieq '.md') { continue }
                    $rel = $arq.FullName.Substring($base.Length + 1).Replace('\', '/')
                    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($za, $arq.FullName, "$($it.Nome)/$rel", $nivel)
                    $arqs++
                }
            }
        } finally { $za.Dispose(); $fs.Dispose() }

        $lista = @("Kit do WoW Forever, gerado em $(Get-AgoraIso) com a Interface $interface.", '')
        foreach ($it in $itens) {
            $t = Get-TocDoForever -PastaAddon $it.Caminho
            $lista += ("{0} {1}" -f $it.Nome, $t.Info.Versao)
        }
        [IO.File]::WriteAllText((Join-Path $arquivos 'versoes.txt'), ($lista -join "`r`n"), (New-Object System.Text.UTF8Encoding $false))

        $ps1 = [IO.File]::ReadAllText((Join-Path $kitFonte 'instalar.ps1'), [Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
        $bat = ($CABECALHO.TrimEnd() + "`n" + $ps1) -replace "`r`n", "`n" -replace "`n", "`r`n"
        [IO.File]::WriteAllText((Join-Path $raizKit 'INSTALAR.bat'), $bat, (New-Object System.Text.UTF8Encoding $false))
        foreach ($x in $pdfs) { Copy-Item -LiteralPath $x -Destination (Join-Path $raizKit ([IO.Path]::GetFileName($x))) }

        # Montado à mão: o CreateFromDirectory do .NET do PowerShell 5.1 grava os nomes com "\".
        $zipKit = Join-Path $tmp 'Kit-WoW-Forever.zip'
        $fs = [IO.File]::Open($zipKit, [IO.FileMode]::CreateNew)
        $za = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Create)
        try {
            foreach ($arq in @(Get-ChildItem -LiteralPath $raizKit -Recurse -File)) {
                $rel = 'Kit-WoW-Forever/' + $arq.FullName.Substring($raizKit.Length + 1).Replace('\', '/')
                [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($za, $arq.FullName, $rel, $nivel)
            }
        } finally { $za.Dispose(); $fs.Dispose() }

        # 3. Destino (sobrescreve no lugar, para o link do Drive continuar o mesmo)
        if (-not (Test-Path -LiteralPath $Destino)) { [void](New-Item -ItemType Directory -Path $Destino -Force) }
        $final = Join-Path $Destino 'Kit-WoW-Forever.zip'
        Copy-Item -LiteralPath $zipKit -Destination $final -Force
        foreach ($x in $pdfs) { Copy-Item -LiteralPath $x -Destination (Join-Path $Destino ([IO.Path]::GetFileName($x))) -Force }
        $msg = Join-Path $kitFonte 'mensagem-whatsapp.txt'
        if (Test-Path -LiteralPath $msg -PathType Leaf) { Copy-Item -LiteralPath $msg -Destination (Join-Path $Destino 'mensagem-whatsapp.txt') -Force }
        $mb = (Get-Item -LiteralPath $final).Length / 1MB
        Write-Linha ("KIT ok caminho={0} mb={1:N0} pastas={2} arquivos={3}" -f $final, $mb, $itens.Count, $arqs)
        Add-Registro -Contexto $ctx -Acao 'kit-amigo' -Slug '-' -Detalhe ("pastas={0} mb={1:N0} destino={2}" -f $itens.Count, $mb, $final)
    } finally {
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
    0
})
