# Ajudantes de verificacao dos testes. Uso: . (Join-Path $PSScriptRoot '_assert.ps1')
$script:AssertTotal = 0
$script:AssertFalhas = New-Object System.Collections.ArrayList

function ConvertTo-TextoComparavel {
    param($Valor)
    if ($null -eq $Valor) { return '<nulo>' }
    return (@($Valor | ForEach-Object { [string]$_ }) -join ',')
}

function Assert-Igual {
    param($Esperado, $Obtido, [Parameter(Mandatory)][string]$Descricao)
    $script:AssertTotal++
    $e = ConvertTo-TextoComparavel $Esperado
    $o = ConvertTo-TextoComparavel $Obtido
    if ($e -cne $o) { [void]$script:AssertFalhas.Add("$Descricao (esperado: [$e] obtido: [$o])") }
}

function Assert-Verdade {
    param($Condicao, [Parameter(Mandatory)][string]$Descricao)
    $script:AssertTotal++
    if (-not $Condicao) { [void]$script:AssertFalhas.Add($Descricao) }
}

function Get-Resultado {
    return [pscustomobject]@{ Total = $script:AssertTotal; Falhas = @($script:AssertFalhas.ToArray()) }
}
