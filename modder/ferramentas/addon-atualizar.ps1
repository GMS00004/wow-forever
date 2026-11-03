# Atualiza os addons aprovados (contrato §9.7). Sem -Aplicar, so mostra o que mudaria.
# Uso: addon-atualizar.ps1 [-Slug <slug>] [-Aplicar] mais -Raiz -Flavor -Instalacao -Estado -Backups (ver CONTRATO.md §3).
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

# Motivo de uma falha numa linha curta (sem o prefixo PREREQ/RECUSA/ERRO).
function Get-MotivoCurto {
    param($Erro)
    $m = [string]$Erro.Exception.Message
    $m = $m -replace '^(PREREQ|RECUSA|ERRO): ', ''
    return (($m -replace '\s+', ' ').Trim())
}

exit (Invoke-ScriptWow {
    $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups
    $cli = Get-WowVersao -Raiz $ctx.Raiz -Flavor $ctx.Flavor
    if (-not $cli) { Stop-Wow PREREQ 'Não consegui ler a versão do cliente (.build.info / .flavor.info).' }
    $cliCurta = ConvertTo-WowVersaoCurta $cli.Versao

    $alvos = @(Get-Manifestos -Contexto $ctx | Where-Object { $_.estadoInstalacao -eq 'instalado' -and $_.aprovado -eq $true })
    if ($Slug) {
        $alvos = @($alvos | Where-Object { $_.slug -eq $Slug })
        if ($alvos.Count -eq 0) { Stop-Wow PREREQ "sem manifesto instalado e aprovado para o slug $Slug" }
    }

    $falhou = 0
    foreach ($m in $alvos) {
        $slugM = [string]$m.slug
        $tipo = [string]$m.fonte.tipo
        try {
            if ($tipo -eq 'dev') { continue }
            if ($tipo -eq 'zip') {
                Write-Linha "MANUAL slug=$slugM pagina=$($m.fonte.pagina)"
                continue
            }

            $fonte = "${tipo}:$([string]$m.fonte.id)"
            $info = Get-FonteAddon -Fonte $fonte -Asset ([string]$m.fonte.asset) -Interface ([int]$cli.Interface) -VersaoJogo $cliCurta
            $versaoAtual = [string]$m.versao
            $versaoNova = [string]$info.Versao
            if ($versaoNova -eq $versaoAtual) { continue }

            Write-Linha "ATUALIZAR slug=$slugM de=$versaoAtual para=$versaoNova"
            if ($info.Compativel -eq $false) {
                Write-Linha "FALHOU slug=$slugM motivo=incompativel"
                $falhou++
                continue
            }
            if (-not $Aplicar) { continue }

            $null = & {
                Install-AddonDeFonte -Contexto $ctx -Fonte $fonte -Slug $slugM -Nome ([string]$m.nome) `
                    -Asset ([string]$m.fonte.asset) -Pagina ([string]$m.fonte.pagina) -Aplicar
            } 6>&1
            Write-Linha "ATUALIZADO slug=$slugM de=$versaoAtual para=$versaoNova"
        }
        catch {
            Write-Linha ("FALHOU slug=$slugM motivo=" + (Get-MotivoCurto $_))
            $falhou++
        }
    }

    if ($falhou -gt 0) { 1 } else { 0 }
})
