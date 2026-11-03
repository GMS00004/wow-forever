# Restaura um backup do WTF (contrato §9.4). Sem -Aplicar, so imprime a previa.
# Uso: wtf-restaurar.ps1 -De <pasta da sessao ou zip> [-Aplicar] mais -Raiz -Flavor -Instalacao -Estado -Backups (ver CONTRATO.md §3).
param(
    [string]$De,
    [switch]$Aplicar,
    [string]$Raiz,
    [string]$Flavor,
    [string]$Instalacao,
    [string]$Estado,
    [string]$Backups
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'wow-comum.ps1')

exit (Invoke-ScriptWow {
    if (-not $De) { Stop-Wow PREREQ 'falta -De <pasta da sessao ou zip do backup>' }
    $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups

    if (Test-Path -LiteralPath $De -PathType Container) {
        $sessao = [IO.Path]::GetFullPath($De)
        $zip = Join-Path $sessao 'WTF.zip'
        $info = Join-Path $sessao 'info.txt'
    } elseif (Test-Path -LiteralPath $De -PathType Leaf) {
        $zip = [IO.Path]::GetFullPath($De)
        $info = Join-Path ([IO.Path]::GetDirectoryName($zip)) 'info.txt'
    } else {
        Stop-Wow PREREQ "backup não encontrado: $De"
    }
    if (-not (Test-Path -LiteralPath $zip -PathType Leaf)) { Stop-Wow PREREQ "zip do backup não encontrado: $zip" }

    $infoCaminho = '(sem info.txt)'
    if (Test-Path -LiteralPath $info -PathType Leaf) {
        $infoCaminho = $info
        Get-Content -LiteralPath $info -Encoding UTF8 | ForEach-Object { Write-Linha ('  ' + $_) }
    }
    Write-Linha "PREVIA acao=restaurar-wtf de=$zip data=$infoCaminho"

    if (-not $Aplicar) {
        Write-Linha 'Prévia apenas; rode com -Aplicar para restaurar.'
    } else {
        Assert-JogoFechado -Raiz $ctx.Raiz

        # backup do estado atual antes de tudo (so se o WTF existe)
        $antes = $null
        if (Test-Path -LiteralPath $ctx.WTF -PathType Container) {
            $antes = Backup-Wtf -Contexto $ctx -Rotulo 'antes-de-restaurar'
        }

        $tmp = Expand-ZipTemp -Zip $zip
        try {
            if (-not (Test-Path -LiteralPath (Join-Path $tmp 'WTF') -PathType Container)) {
                Stop-Wow ERRO 'o zip do backup não tem a pasta WTF'
            }
            $bak = $null
            if (Test-Path -LiteralPath $ctx.WTF) {
                $bak = "$($ctx.WTF).wowbak-$(Get-CarimboBackup)"
                [System.IO.Directory]::Move($ctx.WTF, $bak)
            }
            try {
                Copy-PastaSemJunction -Origem (Join-Path $tmp 'WTF') -Destino $ctx.WTF
            }
            catch {
                $erro = $_.Exception.Message
                if ((Test-Path -LiteralPath $ctx.WTF) -and -not (Test-Junction -Caminho $ctx.WTF)) {
                    Remove-Item -LiteralPath $ctx.WTF -Recurse -Force -ErrorAction SilentlyContinue
                }
                if ($bak) { [System.IO.Directory]::Move($bak, $ctx.WTF) }
                Stop-Wow ERRO "restauração desfeita: $erro"
            }
            if ($bak) {
                if (Test-Junction -Caminho $bak) { [System.IO.Directory]::Delete($bak) }
                else { Remove-Item -LiteralPath $bak -Recurse -Force }
            }
        }
        finally {
            Remove-Temp -Pasta $tmp
        }

        Add-Registro -Contexto $ctx -Acao 'restaurar-wtf' -Slug '-' -Detalhe "de=$zip antes=$antes"
        Write-Linha "OK restaurado de=$zip"
    }
    0
})
