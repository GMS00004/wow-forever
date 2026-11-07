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

    # 2. caminho do Battle.net.config chega com barra dobrada ("C:\/Program Files" vira "C:\\Program Files")
    Assert-Igual 'C:\Program Files (x86)\World of Warcraft' (ConvertTo-CaminhoNormal 'C:\\Program Files (x86)\World of Warcraft\') 'caminho normalizado: barra dobrada e barra final'

    # 3. codigo real do produto do Forever e "wowf": o plano B (sem .flavor.info) tem de achar
    $bi = Join-Path $amb.Raiz '.build.info'
    $cab = 'Branch!STRING:0|Active!DEC:1|Build Key!HEX:16|Version!STRING:0|Product!STRING:0'
    [System.IO.File]::WriteAllText($bi, "$cab`nus|1|aaaa|1.15.9.65000|wow_classic_era`nus|1|bbbb|1.60.1.70755|wowf`n", (New-Object System.Text.UTF8Encoding $false))
    Remove-Item -LiteralPath (Join-Path $amb.Raiz '_forever_\.flavor.info') -Force
    $v = Get-WowVersao -Raiz $amb.Raiz -Flavor '_forever_'
    Assert-Igual '1.60.1.70755' ([string]$v.Versao) 'plano B sem .flavor.info acha o produto wowf'
    Assert-Igual 16001 ([int]$v.Interface) 'plano B: Interface 16001'

    # 4. -SoCompativeis: pacote misto (como o DBM, que traz modulos do Midnight) instala so o que serve ao Forever
    $paraTexto = { process { if ($_ -is [System.Management.Automation.InformationRecord]) { [string]$_.MessageData.Message } else { "$_" } } }
    $amb2 = New-AmbienteTeste -Nome 'regressao-filtro'
    $ctx2 = Get-WowContexto -Raiz $amb2.Raiz -Flavor $amb2.Flavor -Estado $amb2.Estado -Backups $amb2.Backups
    $zipMisto = @(New-ZipDeFixture -Ambiente $amb2 -Addons @('AddonA', 'AddonClassic') -Nome 'misto.zip')[-1]
    $msg = ''
    try { $null = & { Install-AddonDeFonte -Contexto $ctx2 -Fonte "zip:$zipMisto" -Slug 'misto' -Aplicar } 6>&1 } catch { $msg = $_.Exception.Message }
    Assert-Verdade ($msg -like 'RECUSA: TOC incompat*') 'sem -SoCompativeis: pacote misto recusado'
    $linhas = @(& { Install-AddonDeFonte -Contexto $ctx2 -Fonte "zip:$zipMisto" -Slug 'misto' -SoCompativeis -Aplicar } 6>&1 | & $paraTexto)
    Assert-Verdade (@($linhas | Where-Object { $_ -like 'PASTA nome=AddonClassic acao=ignorar*' }).Count -eq 1) 'com -SoCompativeis: AddonClassic aparece como ignorar'
    Assert-Verdade (Test-Path -LiteralPath (Join-Path $ctx2.AddOns 'AddonA')) 'com -SoCompativeis: AddonA instalado'
    Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx2.AddOns 'AddonClassic'))) 'com -SoCompativeis: AddonClassic fica fora'
    $m = Get-Manifesto -Contexto $ctx2 -Slug 'misto'
    Assert-Verdade ([bool]$m.fonte.soCompativeis) 'o manifesto grava soCompativeis'
    Assert-Igual 1 @($m.pastas).Count 'o manifesto lista so a pasta compativel'

    # atualizacao sem o parametro reaplica o filtro gravado no manifesto
    $src = Join-Path $amb2.Base 'src-v2'
    [void](New-Item -ItemType Directory -Path $src -Force)
    Copy-Item -LiteralPath (Join-Path $Aqui 'fontes-fixture\AddonA') -Destination $src -Recurse
    Copy-Item -LiteralPath (Join-Path $Aqui 'fontes-fixture\AddonClassic') -Destination $src -Recurse
    $toc = Join-Path $src 'AddonA\AddonA.toc'
    [System.IO.File]::WriteAllText($toc, ([System.IO.File]::ReadAllText($toc) -replace '## Version: 1\.0\.0', '## Version: 1.1.0'))
    $zip2 = Join-Path $amb2.Base 'misto-v2.zip'
    [System.IO.Compression.ZipFile]::CreateFromDirectory($src, $zip2)
    $linhas2 = @(& { Install-AddonDeFonte -Contexto $ctx2 -Fonte "zip:$zip2" -Slug 'misto' -Aplicar } 6>&1 | & $paraTexto)
    Assert-Verdade (@($linhas2 | Where-Object { $_ -like 'OK atualizado slug=misto*' }).Count -eq 1) 'atualizacao sem o parametro reaplica o filtro'
    Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx2.AddOns 'AddonClassic'))) 'atualizacao: AddonClassic continua fora'

    # 5. -SoPastas: pacote de muitos modulos (como o Naowh Forever) instala so as pastas da lista
    $amb3 = New-AmbienteTeste -Nome 'regressao-sopastas'
    $ctx3 = Get-WowContexto -Raiz $amb3.Raiz -Flavor $amb3.Flavor -Estado $amb3.Estado -Backups $amb3.Backups
    $zipMods = @(New-ZipDeFixture -Ambiente $amb3 -Addons @('AddonMulti', 'AddonMulti_Options', 'AddonClassic') -Nome 'mods.zip')[-1]
    $linhas3 = @(& { Install-AddonDeFonte -Contexto $ctx3 -Fonte "zip:$zipMods" -Slug 'mods' -SoPastas @('addonmulti') -Aplicar } 6>&1 | & $paraTexto)
    Assert-Verdade (@($linhas3 | Where-Object { $_ -like 'PASTA nome=AddonMulti_Options acao=ignorar motivo=fora-da-lista' }).Count -eq 1) 'com -SoPastas: modulo fora da lista aparece como ignorar'
    Assert-Verdade (@($linhas3 | Where-Object { $_ -like 'PASTA nome=AddonClassic acao=ignorar motivo=fora-da-lista' }).Count -eq 1) 'com -SoPastas: pasta incompativel fora da lista nao gera recusa'
    Assert-Verdade (Test-Path -LiteralPath (Join-Path $ctx3.AddOns 'AddonMulti')) 'com -SoPastas: pasta da lista instalada (nome sem diferenciar maiusculas)'
    Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx3.AddOns 'AddonMulti_Options'))) 'com -SoPastas: modulo fora da lista fica fora'
    $m3 = Get-Manifesto -Contexto $ctx3 -Slug 'mods'
    Assert-Igual 1 @($m3.pastas).Count 'com -SoPastas: o manifesto lista so a pasta pedida'
    Assert-Igual 'addonmulti' ([string]@($m3.fonte.soPastas)[0]) 'o manifesto grava soPastas'
    $soPastasJson = [System.IO.File]::ReadAllText((Join-Path $ctx3.Manifestos 'mods.json'))
    Assert-Verdade ($soPastasJson -match '"soPastas":\s*\[') 'soPastas com um nome so fica como lista no JSON'

    # atualizacao sem o parametro reaplica a lista; CLI aceita "A,B" numa string so
    $src3 = Join-Path $amb3.Base 'src-v2'
    [void](New-Item -ItemType Directory -Path $src3 -Force)
    foreach ($n in @('AddonMulti', 'AddonMulti_Options', 'AddonClassic')) { Copy-Item -LiteralPath (Join-Path $Aqui "fontes-fixture\$n") -Destination $src3 -Recurse }
    Add-Content -LiteralPath (Join-Path $src3 'AddonMulti\AddonMulti.lua') -Value '-- v2'
    $zip3 = Join-Path $amb3.Base 'mods-v2.zip'
    [System.IO.Compression.ZipFile]::CreateFromDirectory($src3, $zip3)
    $linhas4 = @(& { Install-AddonDeFonte -Contexto $ctx3 -Fonte "zip:$zip3" -Slug 'mods' -Forcar -Aplicar } 6>&1 | & $paraTexto)
    Assert-Verdade (@($linhas4 | Where-Object { $_ -like 'OK atualizado slug=mods*' }).Count -eq 1) 'atualizacao sem -SoPastas reaplica a lista'
    Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx3.AddOns 'AddonMulti_Options'))) 'atualizacao: modulo fora da lista continua fora'
    Assert-Igual 2 @(ConvertTo-ListaPastas -Valor 'A, B').Count 'CLI: "A, B" vira dois nomes'

    # nome da lista que nao esta no pacote: recusa
    $msg3 = ''
    try { $null = & { Install-AddonDeFonte -Contexto $ctx3 -Fonte "zip:$zip3" -Slug 'mods' -SoPastas 'AddonMulti,Sumiu' -Forcar } 6>&1 } catch { $msg3 = $_.Exception.Message }
    Assert-Verdade ($msg3 -like 'RECUSA: pasta da lista ausente no pacote: Sumiu*') 'nome da lista ausente no pacote: RECUSA'
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
