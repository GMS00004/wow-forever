param([switch]$Manter)
$ErrorActionPreference = 'Stop'
$Aqui = $PSScriptRoot
. (Join-Path $Aqui '_assert.ps1')
. (Join-Path $Aqui '_preparar.ps1')
. (Join-Path $Aqui '..\wow-comum.ps1')

# Regressoes achadas fora dos testes simulados (teste de fumaca na rede, 2026-11-03).
try {
    $amb = New-AmbienteTeste -Nome 'regressao'

    # 1. release.json sem o campo "version" (formato do Questie): a versao cai no tag_name
    $base = 'https://github.com/dono/teste/releases/download/bundle/v9.9.9+v1.0.0'
    $rel = [pscustomobject]@{
        tag_name     = 'bundle/v9.9.9+v1.0.0'
        published_at = '2026-11-02T13:51:34Z'
        assets       = @(
            [pscustomobject]@{ name = 'Teste-v9.9.9+v1.0.0.zip'; browser_download_url = "$base/Teste-v9.9.9+v1.0.0.zip" },
            [pscustomobject]@{ name = 'release.json'; browser_download_url = "$base/release.json" }
        )
    }
    $rj = [pscustomobject]@{ releases = @([pscustomobject]@{
        filename = 'Teste-v9.9.9+v1.0.0.zip'; nolib = $false
        metadata = @(
            [pscustomobject]@{ flavor = 'classic'; interface = 11509 },
            [pscustomobject]@{ flavor = 'forever'; interface = 16001 }
        )
    }) }
    Set-RespostasSimuladas -Ambiente $amb -Arquivos @{ 'github-dono_teste.json' = $rel; 'github-dono_teste-release.json' = $rj }
    $f = Get-FonteAddon -Fonte 'github:dono/teste' -Interface 16001 -VersaoJogo '1.60.1'
    Assert-Igual 'bundle/v9.9.9+v1.0.0' ([string]$f.Versao) 'release.json sem version: a versao cai no tag_name'
    Assert-Igual 'Teste-v9.9.9+v1.0.0.zip' ([string]$f.Asset) 'release.json sem version: asset escolhido pelo flavor forever'
    Assert-Verdade ([bool]$f.Compativel) 'release.json sem version: compativel'
    Assert-Verdade ([string]$f.Url -match '%2B') 'release.json sem version: o + vira %2B na URL'
} finally {
    if (-not $Manter) { Remove-AmbientesTeste }
}

$res = Get-Resultado
if ($res.Falhas.Count -gt 0) {
    foreach ($x in $res.Falhas) { Write-Output "FALHOU: $x" }
    exit 1
}
Write-Output "OK $($res.Total) verificacoes"
exit 0
