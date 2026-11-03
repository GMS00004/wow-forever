# Muda CVars no Config.wtf (contrato §9.4). Sem -Aplicar, so imprime a previa.
# Uso: wtf-cvar.ps1 -Valores '<nome>=<valor>;<nome>=<valor>' [-Aplicar] mais -Raiz -Flavor -Instalacao -Estado -Backups (ver CONTRATO.md §3).
param(
    [string]$Valores,
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
    if (-not $Valores) { Stop-Wow ERRO "falta -Valores (use 'nome=valor;nome=valor')" }
    $pares = [ordered]@{}
    foreach ($par in @($Valores -split ';')) {
        if (-not $par.Trim()) { continue }
        $i = $par.IndexOf('=')
        if ($i -lt 1) { Stop-Wow ERRO "par inválido (use nome=valor): $par" }
        $pares[$par.Substring(0, $i).Trim()] = $par.Substring($i + 1)
    }
    if ($pares.Count -eq 0) { Stop-Wow ERRO "nenhum par nome=valor em -Valores" }
    $tabela = @{}
    foreach ($k in $pares.Keys) { $tabela[$k] = $pares[$k] }

    $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups
    $cfg = Join-Path $ctx.WTF 'Config.wtf'
    if (-not (Test-Path -LiteralPath $cfg -PathType Leaf)) { Stop-Wow PREREQ 'Config.wtf não existe: entre no jogo uma vez' }

    $atuais = Get-CVarsWtf -Arquivo $cfg
    foreach ($nome in $pares.Keys) {
        $at = '(ausente)'
        if ($atuais.ContainsKey($nome)) { $at = [string]$atuais[$nome] }
        Write-Linha "CVAR nome=$nome atual=$at novo=$($pares[$nome])"
    }

    if (-not $Aplicar) {
        Write-Linha 'Prévia apenas; rode com -Aplicar para gravar.'
    } else {
        Assert-JogoFechado -Raiz $ctx.Raiz

        $dir = Join-Path $ctx.Backups 'cvars'
        if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
        $copia = Join-Path $dir ((Get-CarimboBackup) + '-Config.wtf')
        $n = 2
        while (Test-Path -LiteralPath $copia) {
            $copia = Join-Path $dir ("{0}-{1}-Config.wtf" -f (Get-CarimboBackup), $n)
            $n++
        }
        Copy-Item -LiteralPath $cfg -Destination $copia
        Limit-Itens -Pasta $dir -Manter 20

        Set-CVarWtf -Arquivo $cfg -Valores $tabela
        Add-Registro -Contexto $ctx -Acao 'cvar' -Slug '-' -Detalhe ("alterados=" + ($pares.Keys -join ',') + " copia=$copia")
        Write-Linha "OK cvar gravadas=$($pares.Count) copia=$copia"
    }
    0
})
