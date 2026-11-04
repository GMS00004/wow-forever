# CLI de Install-AddonDeFonte (contrato §9.1). Sem -Aplicar, so imprime a previa.
# Uso: addon-instalar.ps1 -Fonte <github:..|tukui:..|zip:<caminho>> -Slug <slug> [-Nome] [-Asset] [-Pagina] [-Forcar] [-SoCompativeis] [-Aplicar]
#      -SoCompativeis: instala só as pastas com TOC do Forever (pacotes como DBM e BigWigs trazem módulos do Midnight).
#      mais -Raiz -Flavor -Instalacao -Estado -Backups (ver CONTRATO.md §3).
param(
    [string]$Fonte,
    [string]$Slug,
    [string]$Nome,
    [string]$Asset,
    [string]$Pagina,
    [switch]$Forcar,
    [switch]$SoCompativeis,
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
    if (-not $Fonte) { Stop-Wow ERRO 'falta -Fonte' }
    if (-not $Slug) { Stop-Wow ERRO 'falta -Slug' }
    $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups
    $null = Install-AddonDeFonte -Contexto $ctx -Fonte $Fonte -Slug $Slug -Nome $Nome -Asset $Asset -Pagina $Pagina -Forcar:$Forcar -SoCompativeis:$SoCompativeis -Aplicar:$Aplicar
    0
})
