# Consulta a fonte de um addon (contrato §9.6). So leitura.
# Uso: addon-fontes.ps1 -Fonte <github:owner/repo|tukui:slug> [-Asset <regex>] [-Json] mais -Raiz -Flavor -Instalacao -Estado -Backups (ver CONTRATO.md §3).
# Com a instalacao configurada, checa a compatibilidade; sem ela, consulta sem checar (compativel=?).
param(
    [string]$Fonte,
    [string]$Asset,
    [switch]$Json,
    [string]$Raiz,
    [string]$Flavor,
    [string]$Instalacao,
    [string]$Estado,
    [string]$Backups
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'wow-comum.ps1')

exit (Invoke-ScriptWow {
    if (-not $Fonte) { Stop-Wow ERRO 'falta -Fonte' }

    $cli = $null
    try {
        $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups
        $cli = Get-WowVersao -Raiz $ctx.Raiz -Flavor $ctx.Flavor
    } catch {
        $cli = $null
    }

    $iface = 0
    $versaoJogo = $null
    if ($cli) {
        $iface = [int]$cli.Interface
        $versaoJogo = ConvertTo-WowVersaoCurta $cli.Versao
    }

    $info = Get-FonteAddon -Fonte $Fonte -Asset $Asset -Interface $iface -VersaoJogo $versaoJogo

    $compat = $null
    if ($cli -and $null -ne $info.Compativel) { $compat = [bool]$info.Compativel }

    if ($Json) {
        $obj = [ordered]@{
            tipo       = $info.Tipo
            id         = $info.Id
            versao     = $info.Versao
            data       = $info.Data
            asset      = $info.Asset
            compativel = $compat
            url        = $info.Url
            motivo     = $info.Motivo
        }
        Write-Linha ($obj | ConvertTo-Json -Depth 5 -Compress)
    } else {
        $c = '?'
        if ($compat -eq $true) { $c = 'sim' }
        elseif ($compat -eq $false) { $c = 'nao' }
        Write-Linha "FONTE tipo=$($info.Tipo) id=$($info.Id) versao=$($info.Versao) data=$($info.Data) asset=$($info.Asset) compativel=$c url=$($info.Url)"
    }
    0
})
