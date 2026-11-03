# Backup do WTF em zip (contrato §9.4). Com o jogo aberto roda, mas avisa.
# Uso: wtf-backup.ps1 [-Rotulo <texto>] mais -Raiz -Flavor -Instalacao -Estado -Backups (ver CONTRATO.md §3).
param(
    [string]$Rotulo,
    [string]$Raiz,
    [string]$Flavor,
    [string]$Instalacao,
    [string]$Estado,
    [string]$Backups
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'wow-comum.ps1')

exit (Invoke-ScriptWow {
    $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups
    if (Test-JogoAberto -Raiz $ctx.Raiz) {
        Write-Linha 'Jogo aberto: o backup pega o último estado salvo pelo jogo.'
    }
    $zip = Backup-Wtf -Contexto $ctx -Rotulo $Rotulo
    Write-Linha "BACKUP ok caminho=$zip"
    Add-Registro -Contexto $ctx -Acao 'backup-wtf' -Slug '-' -Detalhe "rotulo=$Rotulo caminho=$zip"
    0
})
