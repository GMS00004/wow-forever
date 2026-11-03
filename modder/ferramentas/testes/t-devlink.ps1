param([switch]$Manter)
$ErrorActionPreference = 'Stop'
$Aqui = $PSScriptRoot
. (Join-Path $Aqui '_assert.ps1')
. (Join-Path $Aqui '_preparar.ps1')
. (Join-Path $Aqui '..\wow-comum.ps1')

# dev-link.ps1 roda como processo filho. O alvo e sempre uma COPIA do modelo dentro do tmp do teste.
$devlink = (Resolve-Path -LiteralPath (Join-Path $Aqui '..\dev-link.ps1')).ProviderPath
$modeloReal = (Resolve-Path -LiteralPath (Join-Path $Aqui '..\..\addons-proprios\_modelo\Modelo')).ProviderPath

# Cria uma copia do modelo em <base>\proprios\Modelo e devolve o caminho.
function New-CopiaDoModelo {
    param($Ambiente)
    $pai = Join-Path $Ambiente.Base 'proprios'
    [void](New-Item -ItemType Directory -Path $pai -Force)
    Copy-Item -LiteralPath $modeloReal -Destination $pai -Recurse
    return (Join-Path $pai 'Modelo')
}

function Get-AddOnsDo {
    param($Ambiente)
    return (Join-Path $Ambiente.Raiz '_forever_\Interface\AddOns')
}

function Get-RegistroTexto {
    param($Ambiente)
    $reg = Join-Path $Ambiente.Estado 'registro.md'
    if (-not (Test-Path -LiteralPath $reg)) { return '' }
    return [System.IO.File]::ReadAllText($reg, [Text.Encoding]::UTF8)
}

try {

# New-AmbienteTeste limpa as WOWAGENTE_*; por isso o jogo fechado e definido logo depois de cada ambiente.
$a = New-AmbienteTeste 'devlink'
$env:WOWAGENTE_JOGO_ABERTO = '0'
$pasta = New-CopiaDoModelo $a
$addons = Get-AddOnsDo $a
$argsPrevia = @(@('-Pasta', $pasta) + $a.ArgsComuns)
$r = Invoke-ScriptTeste -Script $devlink -Argumentos $argsPrevia
Assert-Igual 0 $r.Codigo 'previa ligar: codigo 0'
Assert-Verdade ($r.Saida -like '*DEV acao=ligar nome=Modelo*') 'previa ligar: linha DEV acao=ligar'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $addons 'Modelo'))) 'previa ligar: nada criado no AddOns'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $a.Estado 'addons\dev-modelo.json'))) 'previa ligar: sem manifesto'
Assert-Verdade ((Get-RegistroTexto $a) -notmatch 'dev-link') 'previa ligar: sem registro'

# ---------------------------------------------------------------- 2. ligar com -Aplicar
$r = Invoke-ScriptTeste -Script $devlink -Argumentos @(@('-Pasta', $pasta, '-Aplicar') + $a.ArgsComuns)
Assert-Igual 0 $r.Codigo 'aplicar ligar: codigo 0'
Assert-Verdade ($r.Saida -like '*OK ligado slug=dev-modelo*') 'aplicar ligar: linha OK ligado'
$destino = Join-Path $addons 'Modelo'
Assert-Verdade (Test-Junction -Caminho $destino) 'aplicar ligar: destino e junction'
Assert-Verdade (Test-Path -LiteralPath (Join-Path $destino 'Modelo.toc')) 'aplicar ligar: junction enxerga o TOC do alvo'
$m = Get-Manifesto -Contexto (Get-WowContexto -Raiz $a.Raiz -Flavor $a.Flavor -Estado $a.Estado -Backups $a.Backups) -Slug 'dev-modelo'
Assert-Verdade ($null -ne $m) 'aplicar ligar: manifesto dev-modelo gravado'
Assert-Igual 'dev' $m.fonte.tipo 'aplicar ligar: fonte.tipo=dev'
Assert-Verdade ($m.fonte.id -ieq $pasta) 'aplicar ligar: fonte.id e o alvo'
Assert-Igual '0.1.0' $m.versao 'aplicar ligar: versao vem do TOC'
Assert-Igual 'instalado' $m.estadoInstalacao 'aplicar ligar: estadoInstalacao=instalado'
Assert-Verdade ((Get-RegistroTexto $a) -match '\| dev-link \| dev-modelo') 'aplicar ligar: registro dev-link'

# ---------------------------------------------------------------- 3. ligar de novo: nada a fazer
$r = Invoke-ScriptTeste -Script $devlink -Argumentos @(@('-Pasta', $pasta, '-Aplicar') + $a.ArgsComuns)
Assert-Igual 0 $r.Codigo 'ligar de novo: codigo 0'
Assert-Verdade ($r.Saida -like '*OK nada a fazer*') 'ligar de novo: OK nada a fazer'
$contagemDevLink = @([regex]::Matches((Get-RegistroTexto $a), 'dev-link \| dev-modelo')).Count
Assert-Igual 1 $contagemDevLink 'ligar de novo: registro nao duplica'

# ---------------------------------------------------------------- 4. destino ja e pasta comum: codigo 1
$b = New-AmbienteTeste 'devlink-comum'
$env:WOWAGENTE_JOGO_ABERTO = '0'
$pastaB = New-CopiaDoModelo $b
$addonsB = Get-AddOnsDo $b
$comum = Join-Path $addonsB 'Modelo'
[void](New-Item -ItemType Directory -Path $comum -Force)
[System.IO.File]::WriteAllText((Join-Path $comum 'x.txt'), 'nao mexer', (New-Object System.Text.UTF8Encoding $false))
$r = Invoke-ScriptTeste -Script $devlink -Argumentos @(@('-Pasta', $pastaB, '-Aplicar') + $b.ArgsComuns)
Assert-Igual 1 $r.Codigo 'pasta comum: codigo 1'
Assert-Verdade ($r.Saida -like 'RECUSA*') 'pasta comum: linha RECUSA'
Assert-Verdade (-not (Test-Junction -Caminho $comum)) 'pasta comum: continua pasta comum'
Assert-Verdade (Test-Path -LiteralPath (Join-Path $comum 'x.txt')) 'pasta comum: arquivo preservado'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $b.Estado 'addons\dev-modelo.json'))) 'pasta comum: sem manifesto'

# ---------------------------------------------------------------- 5. jogo aberto com -Aplicar: codigo 1
$c = New-AmbienteTeste 'devlink-aberto'
$pastaC = New-CopiaDoModelo $c
$env:WOWAGENTE_JOGO_ABERTO = '1'
$r = Invoke-ScriptTeste -Script $devlink -Argumentos @(@('-Pasta', $pastaC, '-Aplicar') + $c.ArgsComuns)
$env:WOWAGENTE_JOGO_ABERTO = '0'
Assert-Igual 1 $r.Codigo 'jogo aberto: codigo 1'
Assert-Verdade ($r.Saida -like '*RECUSA*Jogo aberto*') 'jogo aberto: RECUSA Jogo aberto'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path (Get-AddOnsDo $c) 'Modelo'))) 'jogo aberto: nada criado'

# ---------------------------------------------------------------- 6. remover: junction sai, alvo fica
$r = Invoke-ScriptTeste -Script $devlink -Argumentos @(@('-Pasta', $pasta, '-Remover') + $a.ArgsComuns)
Assert-Igual 0 $r.Codigo 'remover previa: codigo 0'
Assert-Verdade ($r.Saida -like '*DEV acao=remover*') 'remover previa: linha DEV acao=remover'
Assert-Verdade (Test-Junction -Caminho $destino) 'remover previa: junction continua'

$r = Invoke-ScriptTeste -Script $devlink -Argumentos @(@('-Pasta', $pasta, '-Remover', '-Aplicar') + $a.ArgsComuns)
Assert-Igual 0 $r.Codigo 'remover aplicar: codigo 0'
Assert-Verdade ($r.Saida -like '*OK desligado slug=dev-modelo*') 'remover aplicar: linha OK desligado'
Assert-Verdade (-not (Test-Path -LiteralPath $destino)) 'remover aplicar: junction removida'
Assert-Verdade (Test-Path -LiteralPath (Join-Path $pasta 'Modelo.toc')) 'remover aplicar: alvo TOC intacto'
Assert-Verdade (Test-Path -LiteralPath (Join-Path $pasta 'Modelo.lua')) 'remover aplicar: alvo LUA intacto'
$m = Get-Manifesto -Contexto (Get-WowContexto -Raiz $a.Raiz -Flavor $a.Flavor -Estado $a.Estado -Backups $a.Backups) -Slug 'dev-modelo'
Assert-Igual 'removido' $m.estadoInstalacao 'remover aplicar: manifesto marcado removido'
Assert-Verdade ((Get-RegistroTexto $a) -match '\| dev-unlink \| dev-modelo') 'remover aplicar: registro dev-unlink'

# ---------------------------------------------------------------- 7. o TOC do modelo passa com a Interface 16001
$t = Test-AddonForever -PastaAddon $modeloReal -Interface 16001
Assert-Verdade $t.Compativel 'TOC do modelo: compativel com 16001'
Assert-Igual 'Modelo.toc' $t.Toc 'TOC do modelo: arquivo Modelo.toc'

} finally {
    # Junction de teste sai sem recursao antes da limpeza (Remove-Item -Recurse seguiria a junction).
    foreach ($amb in @($a, $b, $c)) {
        if ($amb) {
            $j = Join-Path (Get-AddOnsDo $amb) 'Modelo'
            if (Test-Junction -Caminho $j) { [System.IO.Directory]::Delete($j) }
        }
    }
    if (-not $Manter) { Remove-AmbientesTeste }
    Remove-Item -LiteralPath 'Env:\WOWAGENTE_JOGO_ABERTO' -ErrorAction SilentlyContinue
}

$res = Get-Resultado
if ($res.Falhas.Count -gt 0) {
    foreach ($f in $res.Falhas) { Write-Output "FALHOU: $f" }
    exit 1
}
Write-Output "OK $($res.Total) verificacoes"
exit 0
