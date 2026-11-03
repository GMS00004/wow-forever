# CLI de Remove-Addon (contrato §9.2). Sem -Aplicar, so imprime a previa.
# Uso: addon-remover.ps1 -Slug <slug> [-Aplicar] mais -Raiz -Flavor -Instalacao -Estado -Backups (ver CONTRATO.md §3).
param(
    [string]$Slug,
    [switch]$Aplicar,
    [string]$Raiz,
    [string]$Flavor,
    [string]$Instalacao,
    [string]$Estado,
    [string]$Backups
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'wow-comum.ps1')

# Os padroes de -Instalacao, -Estado e -Backups se resolvem em Get-WowContexto (vazios viram o padrao do contrato §3).
exit (Invoke-ScriptWow {
    if (-not $Slug) { Stop-Wow ERRO 'falta -Slug' }
    $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups
    $null = Remove-Addon -Contexto $ctx -Slug $Slug -Aplicar:$Aplicar
    0
})
