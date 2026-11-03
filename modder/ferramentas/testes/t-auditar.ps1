param([switch]$Manter)
$ErrorActionPreference = 'Stop'
$Aqui = $PSScriptRoot
. (Join-Path $Aqui '_assert.ps1')
. (Join-Path $Aqui '_preparar.ps1')
. (Join-Path $Aqui '..\wow-comum.ps1')

$aud = (Resolve-Path -LiteralPath (Join-Path $Aqui '..\addons-auditar.ps1')).ProviderPath
$fontes = Join-Path $Aqui 'fontes-fixture'
$juncoes = New-Object System.Collections.ArrayList

# ---------------------------------------------------------------- ajudantes locais

function Get-Contexto {
    param($A)
    Get-WowContexto -Raiz $A.Raiz -Flavor $A.Flavor -Estado $A.Estado -Backups $A.Backups -Instalacao (Join-Path $A.Base 'inst.json')
}

function Get-Linhas {
    param([string]$Texto)
    return @($Texto -split "`n" | ForEach-Object { $_.TrimEnd() })
}

function Tem-Linha {
    param([string]$Texto, [string]$Linha)
    return (@(Get-Linhas $Texto | Where-Object { $_ -ceq $Linha }).Count -gt 0)
}

function Tem-LinhaLike {
    param([string]$Texto, [string]$Padrao)
    return (@(Get-Linhas $Texto | Where-Object { $_ -like $Padrao }).Count -gt 0)
}

function Invoke-Auditoria {
    param($A, [string[]]$Extra = @())
    return (Invoke-ScriptTeste -Script $aud -Argumentos (@($A.ArgsComuns) + $Extra))
}

# Instala um addon da fixture pela biblioteca (nunca pelo addon-instalar.ps1).
function Instalar-Fixture {
    param($A, $Ctx, [string]$Slug, [string]$Addon)
    $env:WOWAGENTE_JOGO_ABERTO = '0'
    $zip = New-ZipDeFixture -Ambiente $A -Addons @($Addon) -Nome "$Slug.zip"
    $null = & { Install-AddonDeFonte -Contexto $Ctx -Fonte "zip:$zip" -Slug $Slug -Aplicar } 6>&1
}

# Cria uma junction em AddOns apontando para uma pasta de addon dentro do tmp do teste.
function Criar-Junction {
    param($A, $Ctx, [string]$Nome, [string]$Dentro)
    $alvo = Join-Path $A.Base $Dentro
    [void](New-Item -ItemType Directory -Path (Split-Path -Parent $alvo) -Force)
    Copy-Item -LiteralPath (Join-Path $fontes 'AddonA') -Destination $alvo -Recurse
    $jn = Join-Path $Ctx.AddOns $Nome
    [void](New-Item -ItemType Junction -Path $jn -Target $alvo)
    [void]$juncoes.Add($jn)
    return $alvo
}

# Junctions nunca saem por Remove-Item -Recurse: apaga-se a junction sem recursao antes de limpar o tmp.
function Remove-Juncoes {
    foreach ($j in @($juncoes.ToArray())) {
        if ((Test-Path -LiteralPath $j) -and (Test-Junction -Caminho $j)) { [System.IO.Directory]::Delete($j) }
    }
    $juncoes.Clear()
}

try {

# ---------------------------------------------------------------- 1. AddOns vazio
$a = New-AmbienteTeste 'aud-vazio'
$r = Invoke-Auditoria $a
Assert-Igual 0 $r.Codigo 'vazio: codigo 0'
Assert-Verdade (Tem-Linha $r.Saida 'AUDITORIA addons=0 desconhecidas=0 faltando=0 alteradas=0 incompativeis=0 dependencias=0 junctions=0') 'vazio: AUDITORIA tudo zero'

# pasta AddOns inexistente conta como zero addons
$b = New-AmbienteTeste 'aud-sem-addons'
Remove-Item -LiteralPath (Join-Path $b.Raiz '_forever_\Interface\AddOns') -Recurse -Force
$r = Invoke-Auditoria $b
Assert-Igual 0 $r.Codigo 'AddOns inexistente: codigo 0'
Assert-Verdade (Tem-Linha $r.Saida 'AUDITORIA addons=0 desconhecidas=0 faltando=0 alteradas=0 incompativeis=0 dependencias=0 junctions=0') 'AddOns inexistente: AUDITORIA zerada'

# ---------------------------------------------------------------- 2. addon instalado pela biblioteca
$a = New-AmbienteTeste 'aud-ok'
$ctx = Get-Contexto $a
Instalar-Fixture $a $ctx 'addona' 'AddonA'
Assert-Verdade (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonA\AddonA.toc')) 'preparo: AddonA instalado'
$r = Invoke-Auditoria $a
Assert-Igual 0 $r.Codigo 'instalado: codigo 0'
Assert-Verdade (Tem-Linha $r.Saida 'AUDITORIA addons=1 desconhecidas=0 faltando=0 alteradas=0 incompativeis=0 dependencias=0 junctions=0') 'instalado: AUDITORIA sem diferenca'

# ---------------------------------------------------------------- 3. pasta desconhecida
$a = New-AmbienteTeste 'aud-desc'
$ctx = Get-Contexto $a
Instalar-Fixture $a $ctx 'addona' 'AddonA'
Copy-Item -LiteralPath (Join-Path $fontes 'Embrulho\AddonB') -Destination $ctx.AddOns -Recurse
$r = Invoke-Auditoria $a
Assert-Igual 1 $r.Codigo 'desconhecida: codigo 1'
Assert-Verdade (Tem-Linha $r.Saida 'DESCONHECIDA nome=AddonB') 'desconhecida: linha DESCONHECIDA'
Assert-Verdade (Tem-Linha $r.Saida 'AUDITORIA addons=2 desconhecidas=1 faltando=0 alteradas=0 incompativeis=0 dependencias=0 junctions=0') 'desconhecida: AUDITORIA conta 1'

# ---------------------------------------------------------------- 4. pasta faltando
$a = New-AmbienteTeste 'aud-falt'
$ctx = Get-Contexto $a
Instalar-Fixture $a $ctx 'addona' 'AddonA'
Remove-Item -LiteralPath (Join-Path $ctx.AddOns 'AddonA') -Recurse -Force
$r = Invoke-Auditoria $a
Assert-Igual 1 $r.Codigo 'faltando: codigo 1'
Assert-Verdade (Tem-Linha $r.Saida 'FALTANDO slug=addona nome=AddonA') 'faltando: linha FALTANDO'
Assert-Verdade (Tem-Linha $r.Saida 'AUDITORIA addons=0 desconhecidas=0 faltando=1 alteradas=0 incompativeis=0 dependencias=0 junctions=0') 'faltando: AUDITORIA conta 1'

# ---------------------------------------------------------------- 5. pasta alterada (assinatura muda)
$a = New-AmbienteTeste 'aud-alt'
$ctx = Get-Contexto $a
Instalar-Fixture $a $ctx 'addona' 'AddonA'
Add-Content -LiteralPath (Join-Path $ctx.AddOns 'AddonA\AddonA.lua') -Value '-- mudou'
$r = Invoke-Auditoria $a
Assert-Igual 1 $r.Codigo 'alterada: codigo 1'
Assert-Verdade (Tem-Linha $r.Saida 'ALTERADA slug=addona nome=AddonA') 'alterada: linha ALTERADA'
Assert-Verdade (Tem-Linha $r.Saida 'AUDITORIA addons=1 desconhecidas=0 faltando=0 alteradas=1 incompativeis=0 dependencias=0 junctions=0') 'alterada: AUDITORIA conta 1'

# ---------------------------------------------------------------- 6. incompativel
$a = New-AmbienteTeste 'aud-inc'
$ctx = Get-Contexto $a
Instalar-Fixture $a $ctx 'addona' 'AddonA'
Copy-Item -LiteralPath (Join-Path $fontes 'AddonClassic') -Destination $ctx.AddOns -Recurse
$r = Invoke-Auditoria $a
Assert-Igual 1 $r.Codigo 'incompativel: codigo 1'
Assert-Verdade (Tem-Linha $r.Saida 'INCOMPATIVEL nome=AddonClassic toc=AddonClassic.toc interfaces=11509 cliente=16001') 'incompativel: linha INCOMPATIVEL'
Assert-Verdade (Tem-Linha $r.Saida 'DESCONHECIDA nome=AddonClassic') 'incompativel: sem dono, tambem DESCONHECIDA'
Assert-Verdade (Tem-Linha $r.Saida 'AUDITORIA addons=2 desconhecidas=1 faltando=0 alteradas=0 incompativeis=1 dependencias=0 junctions=0') 'incompativel: AUDITORIA conta 1'

# ---------------------------------------------------------------- 7. dependencia inexistente
$a = New-AmbienteTeste 'aud-dep'
$ctx = Get-Contexto $a
Instalar-Fixture $a $ctx 'addondep' 'AddonDep'
$r = Invoke-Auditoria $a
Assert-Igual 1 $r.Codigo 'dependencia: codigo 1'
Assert-Verdade (Tem-Linha $r.Saida 'DEPENDENCIA nome=AddonDep requer=AddonInexistente') 'dependencia: linha DEPENDENCIA'
Assert-Verdade (Tem-Linha $r.Saida 'AUDITORIA addons=1 desconhecidas=0 faltando=0 alteradas=0 incompativeis=0 dependencias=1 junctions=0') 'dependencia: AUDITORIA conta 1'

# ---------------------------------------------------------------- 8. junction sem manifesto
$a = New-AmbienteTeste 'aud-jn'
$ctx = Get-Contexto $a
$alvo = Criar-Junction $a $ctx 'AddonJ' 'alvo-addon\AddonJ'
$r = Invoke-Auditoria $a
Assert-Igual 1 $r.Codigo 'junction sem manifesto: codigo 1'
Assert-Verdade (Tem-Linha $r.Saida "JUNCTION nome=AddonJ alvo=$alvo sem-manifesto") 'junction sem manifesto: linha JUNCTION'
Assert-Verdade (Tem-Linha $r.Saida 'AUDITORIA addons=1 desconhecidas=0 faltando=0 alteradas=0 incompativeis=0 dependencias=0 junctions=1') 'junction sem manifesto: AUDITORIA conta 1'
Assert-Verdade (Test-Path -LiteralPath (Join-Path $alvo 'AddonA.toc')) 'junction: o alvo continua intacto'
Remove-Juncoes

# junction com manifesto dev (JSON escrito a mao, conforme o contrato §6) nao e apontada
$a = New-AmbienteTeste 'aud-dev'
$ctx = Get-Contexto $a
$alvo = Criar-Junction $a $ctx 'AddonK' 'alvo-dev\AddonK'
$alvoJson = $alvo.Replace('\', '\\')
$json = @"
{
  "v": 1,
  "slug": "dev-addonk",
  "nome": "AddonK",
  "versao": "dev",
  "fonte": { "tipo": "dev", "id": "$alvoJson", "asset": null, "pagina": null },
  "pastas": [ { "nome": "AddonK", "toc": "AddonK.toc", "interfaces": [16001], "assinatura": "0|0", "sha256": "" } ],
  "aprovado": true,
  "estadoInstalacao": "instalado",
  "instaladoEm": "2026-11-03T10:00:00-03:00",
  "atualizadoEm": "2026-11-03T10:00:00-03:00",
  "removidoEm": null,
  "backupAnterior": null,
  "maquina": "TESTE"
}
"@
[System.IO.File]::WriteAllText((Join-Path $ctx.Estado 'addons\dev-addonk.json'), $json, (New-Object System.Text.UTF8Encoding $false))
$r = Invoke-Auditoria $a
Assert-Igual 0 $r.Codigo 'junction dev: codigo 0'
Assert-Verdade (-not (Tem-LinhaLike $r.Saida '*AddonK*')) 'junction dev: nenhuma linha sobre AddonK'
Assert-Verdade (Tem-Linha $r.Saida 'AUDITORIA addons=1 desconhecidas=0 faltando=0 alteradas=0 incompativeis=0 dependencias=0 junctions=0') 'junction dev: AUDITORIA zerada'
Remove-Juncoes

# ---------------------------------------------------------------- 9. troca de um byte sem mudar o tamanho
$a = New-AmbienteTeste 'aud-hash'
$ctx = Get-Contexto $a
Instalar-Fixture $a $ctx 'addona' 'AddonA'
$lua = Join-Path $ctx.AddOns 'AddonA\AddonA.lua'
$bytes = [IO.File]::ReadAllBytes($lua)
$bytes[0] = [byte]([int]$bytes[0] -bxor 1)
[IO.File]::WriteAllBytes($lua, $bytes)
$r = Invoke-Auditoria $a
Assert-Igual 0 $r.Codigo 'hash: sem -HashCompleto, codigo 0'
Assert-Verdade (-not (Tem-LinhaLike $r.Saida 'ALTERADA*')) 'hash: sem -HashCompleto nao mostra ALTERADA'
$r = Invoke-Auditoria $a @('-HashCompleto')
Assert-Igual 1 $r.Codigo 'hash: com -HashCompleto, codigo 1'
Assert-Verdade (Tem-Linha $r.Saida 'ALTERADA slug=addona nome=AddonA') 'hash: com -HashCompleto mostra ALTERADA'

# ---------------------------------------------------------------- 10. sem instalacao configurada
$a = New-AmbienteTeste 'aud-prereq'
$r = Invoke-ScriptTeste -Script $aud -Argumentos @('-Instalacao', (Join-Path $a.Base 'nao-existe.json'), '-Estado', $a.Estado, '-Backups', $a.Backups)
Assert-Igual 2 $r.Codigo 'sem instalacao: codigo 2'
Assert-Verdade (Tem-LinhaLike $r.Saida 'PREREQ *') 'sem instalacao: linha PREREQ'

} finally {
    Remove-Juncoes
    if (-not $Manter) { Remove-AmbientesTeste }
}

$res = Get-Resultado
if ($res.Falhas.Count -gt 0) {
    foreach ($f in $res.Falhas) { Write-Output "FALHOU: $f" }
    exit 1
}
Write-Output "OK $($res.Total) verificacoes"
exit 0
