param([switch]$Manter)
$ErrorActionPreference = 'Stop'
$Aqui = $PSScriptRoot
. (Join-Path $Aqui '_assert.ps1')
. (Join-Path $Aqui '_preparar.ps1')
. (Join-Path $Aqui '..\wow-comum.ps1')

# ---------------------------------------------------------------- ajudantes locais

# Roda um bloco capturando o Write-Host (6>&1). Devolve @{Linhas; Resultado}.
function Invoke-Capturando {
    param([scriptblock]$Bloco)
    $o = @(& $Bloco 6>&1)
    $linhas = @($o | Where-Object { $_ -is [System.Management.Automation.InformationRecord] } | ForEach-Object { [string]$_.MessageData.Message })
    $res = @($o | Where-Object { $_ -isnot [System.Management.Automation.InformationRecord] }) | Select-Object -Last 1
    return @{ Linhas = $linhas; Resultado = $res }
}

# Roda um bloco que deve lancar erro e devolve a mensagem ('' se nao lancou).
function Get-MensagemErro {
    param([scriptblock]$Bloco)
    try { $null = & $Bloco 6>&1; return '' } catch { return [string]$_.Exception.Message }
}

function Get-Contexto {
    param($A)
    Get-WowContexto -Raiz $A.Raiz -Flavor $A.Flavor -Estado $A.Estado -Backups $A.Backups -Instalacao (Join-Path $A.Base 'inst.json')
}

function Get-EntradasZip {
    param([string]$Zip)
    $z = [System.IO.Compression.ZipFile]::OpenRead($Zip)
    try { return @($z.Entries | ForEach-Object { $_.FullName }) } finally { $z.Dispose() }
}

function Write-TocTeste {
    param([string]$Caminho, [string]$Texto)
    $dir = [IO.Path]::GetDirectoryName($Caminho)
    if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
    [System.IO.File]::WriteAllText($Caminho, $Texto, (New-Object System.Text.UTF8Encoding $true))
}

$fontes = Join-Path $Aqui 'fontes-fixture'
$respostasFixture = Join-Path $Aqui 'respostas'
$lib = (Resolve-Path -LiteralPath (Join-Path $Aqui '..\wow-comum.ps1')).ProviderPath

try {

# ---------------------------------------------------------------- versao e conversoes
Assert-Igual 16001 (ConvertTo-WowInterface '1.60.1.123') 'ConvertTo-WowInterface 1.60.1.123'
Assert-Igual 120105 (ConvertTo-WowInterface '12.1.5.6') 'ConvertTo-WowInterface 12.1.5.6'
Assert-Igual '1.60.1' (ConvertTo-WowVersaoCurta '1.60.1.123') 'ConvertTo-WowVersaoCurta'

$a = New-AmbienteTeste 'versao'
$v = Get-WowVersao -Raiz $a.Raiz -Flavor $a.Flavor
Assert-Igual 'wow_forever' $v.Produto 'Get-WowVersao produto'
Assert-Igual '1.60.1.65432' $v.Versao 'Get-WowVersao versao'
Assert-Igual 16001 $v.Interface 'Get-WowVersao interface'
$vc = Get-WowVersao -Raiz $a.Raiz -Flavor '_classic_era_'
Assert-Igual '1.15.9.65000' $vc.Versao 'Get-WowVersao classic_era'
Assert-Igual 11509 $vc.Interface 'Get-WowVersao classic_era interface'
Remove-Item -LiteralPath (Join-Path $a.Raiz '_forever_\.flavor.info') -Force
$v2 = Get-WowVersao -Raiz $a.Raiz -Flavor $a.Flavor
Assert-Igual '1.60.1.65432' $v2.Versao 'Get-WowVersao fallback sem .flavor.info'
Assert-Igual 'wow_forever' $v2.Produto 'Get-WowVersao fallback produto'
Remove-Item -LiteralPath (Join-Path $a.Raiz '.build.info') -Force
Assert-Verdade ($null -eq (Get-WowVersao -Raiz $a.Raiz -Flavor $a.Flavor)) 'Get-WowVersao sem .build.info devolve nulo'

# ---------------------------------------------------------------- contexto e instalacao
$a = New-AmbienteTeste 'contexto'
$instJson = Join-Path $a.Base 'comum\instalacao.json'
$msg = Get-MensagemErro { Get-WowContexto -Instalacao $instJson -Estado $a.Estado -Backups $a.Backups }
Assert-Verdade ($msg -like 'PREREQ: Instalação não configurada*') 'Get-WowContexto sem instalacao: PREREQ'
Set-WowInstalacao -Raiz $a.Raiz -Flavor $a.Flavor -Instalacao $instJson
$j = Get-Content -LiteralPath $instJson -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-Igual 1 $j.v 'Set-WowInstalacao v'
Assert-Igual $a.Flavor $j.flavor 'Set-WowInstalacao flavor'
$ctx = Get-WowContexto -Instalacao $instJson -Estado $a.Estado -Backups $a.Backups
Assert-Igual $a.Raiz $ctx.Raiz 'Get-WowContexto raiz vem do instalacao.json'
Assert-Igual (Join-Path $a.Raiz '_forever_\Interface\AddOns') $ctx.AddOns 'Get-WowContexto AddOns'
Assert-Igual (Join-Path $a.Raiz '_forever_\WTF') $ctx.WTF 'Get-WowContexto WTF'
Assert-Verdade (Test-Path -LiteralPath (Join-Path $a.Estado 'addons') -PathType Container) 'Get-WowContexto cria Estado\addons'
$msg = Get-MensagemErro { Get-WowContexto -Raiz (Join-Path $a.Base 'nao-existe') -Flavor '_forever_' -Estado $a.Estado -Backups $a.Backups }
Assert-Verdade ($msg -like 'PREREQ:*') 'Get-WowContexto raiz inexistente: PREREQ'
$msg = Get-MensagemErro { Get-WowContexto -Raiz $a.Raiz -Flavor '_nao_' -Estado $a.Estado -Backups $a.Backups }
Assert-Verdade ($msg -like 'PREREQ:*') 'Get-WowContexto flavor inexistente: PREREQ'
$fi = @(Find-WowInstalacao)
Assert-Verdade ($fi -is [array]) 'Find-WowInstalacao devolve lista'

# ---------------------------------------------------------------- Stop-Wow e Invoke-ScriptWow (processo filho)
$a = New-AmbienteTeste 'erros'
$scr = Join-Path $a.Base 'scr.ps1'
$corpo = "param([string]`$Modo)`r`n`$ErrorActionPreference = 'Stop'`r`n. '$lib'`r`n" +
    "exit (Invoke-ScriptWow { switch (`$Modo) { 'ok' { 'linha livre'; 0 } 'cod' { 7 } 'prereq' { Stop-Wow PREREQ 'falta algo' } 'recusa' { Stop-Wow RECUSA 'nao pode' } 'erro' { throw 'boom' } } })`r`n"
[System.IO.File]::WriteAllText($scr, $corpo, (New-Object System.Text.UTF8Encoding $true))
$r = Invoke-ScriptTeste -Script $scr -Argumentos @('ok')
Assert-Igual 0 $r.Codigo 'Invoke-ScriptWow ok: codigo'
Assert-Verdade ($r.Saida -match 'linha livre') 'Invoke-ScriptWow imprime o texto do bloco'
$r = Invoke-ScriptTeste -Script $scr -Argumentos @('cod')
Assert-Igual 7 $r.Codigo 'Invoke-ScriptWow devolve o inteiro do bloco'
$r = Invoke-ScriptTeste -Script $scr -Argumentos @('prereq')
Assert-Igual 2 $r.Codigo 'Invoke-ScriptWow PREREQ: codigo 2'
Assert-Verdade ($r.Saida -match '(?m)^PREREQ falta algo') 'Invoke-ScriptWow PREREQ: linha'
$r = Invoke-ScriptTeste -Script $scr -Argumentos @('recusa')
Assert-Igual 1 $r.Codigo 'Invoke-ScriptWow RECUSA: codigo 1'
Assert-Verdade ($r.Saida -match '(?m)^RECUSA nao pode') 'Invoke-ScriptWow RECUSA: linha'
$r = Invoke-ScriptTeste -Script $scr -Argumentos @('erro')
Assert-Igual 3 $r.Codigo 'Invoke-ScriptWow erro: codigo 3'
Assert-Verdade ($r.Saida -match '(?m)^ERRO boom') 'Invoke-ScriptWow erro: linha'

# ---------------------------------------------------------------- jogo aberto
$a = New-AmbienteTeste 'jogo'
$env:WOWAGENTE_JOGO_ABERTO = '1'
Assert-Verdade (Test-JogoAberto -Raiz $a.Raiz) 'Test-JogoAberto com env=1'
$msg = Get-MensagemErro { Assert-JogoFechado -Raiz $a.Raiz }
Assert-Verdade ($msg -like 'RECUSA: Jogo aberto*') 'Assert-JogoFechado recusa com env=1'
$env:WOWAGENTE_JOGO_ABERTO = '0'
Assert-Verdade (-not (Test-JogoAberto -Raiz $a.Raiz)) 'Test-JogoAberto com env=0'
Assert-Igual '' (Get-MensagemErro { Assert-JogoFechado -Raiz $a.Raiz }) 'Assert-JogoFechado passa com env=0'
Remove-Item -LiteralPath Env:\WOWAGENTE_JOGO_ABERTO
Assert-Verdade (-not (Test-JogoAberto -Raiz $a.Raiz)) 'Test-JogoAberto real: nenhum processo na fixture'

# ---------------------------------------------------------------- TOC
$a = New-AmbienteTeste 'toc'
$toc = Join-Path $a.Base 'toc\ElvUI\ElvUI_Camelot.toc'
Write-TocTeste $toc ("## Interface: 11509, 16001, @toc-version@`r`n## Title: ElvUI Título [AllowLoadGameType classic, forever]`r`n" +
    "## Version: 1.2`r`n## AllowLoadGameType: mainline`r`n## Dependencies: Ace3, LibStub`r`n## RequiredDeps: Foo`r`nElvUI.lua`r`n")
$ti = Get-TocInfo -Arquivo $toc
Assert-Igual @(11509, 16001) $ti.Interfaces 'Get-TocInfo Interface ignora placeholder'
Assert-Verdade ($ti.Titulo -like 'ElvUI Título*') 'Get-TocInfo Title com acento (UTF-8 com BOM)'
Assert-Igual '1.2' $ti.Versao 'Get-TocInfo Version'
Assert-Igual @('classic', 'forever', 'mainline') (@($ti.AllowLoadGameType) | Sort-Object) 'Get-TocInfo AllowLoadGameType (Title + linha)'
Assert-Igual @('Ace3', 'LibStub', 'Foo') $ti.Dependencias 'Get-TocInfo Dependencies e RequiredDeps'
$ta = Get-TocInfo -Arquivo (Join-Path $fontes 'AddonA\AddonA.toc')
Assert-Igual @(16001) $ta.Interfaces 'Get-TocInfo AddonA'
Assert-Igual 0 @($ta.Dependencias).Count 'Get-TocInfo sem dependencias'

$tf = Get-TocDoForever -PastaAddon (Join-Path $fontes 'AddonForeverToc')
Assert-Igual 'forever' $tf.Tipo 'Get-TocDoForever prefere o _Camelot.toc: tipo'
Assert-Igual 'AddonForeverToc_Camelot.toc' ([IO.Path]::GetFileName($tf.Arquivo)) 'Get-TocDoForever prefere o _Camelot.toc: arquivo'
Assert-Igual @(16001) $tf.Info.Interfaces 'Get-TocDoForever interfaces do Camelot'
Assert-Igual 2 @($tf.TocsPresentes).Count 'Get-TocDoForever TocsPresentes'
$tg = Get-TocDoForever -PastaAddon (Join-Path $fontes 'AddonA')
Assert-Igual 'generico' $tg.Tipo 'Get-TocDoForever generico'
$pastaVazia = Join-Path $a.Base 'vazia\SemToc'
[void](New-Item -ItemType Directory -Path $pastaVazia -Force)
$tn = Get-TocDoForever -PastaAddon $pastaVazia
Assert-Igual 'nenhum' $tn.Tipo 'Get-TocDoForever nenhum'
Assert-Verdade ($null -eq $tn.Info) 'Get-TocDoForever nenhum: Info nulo'

$ok = Test-AddonForever -PastaAddon (Join-Path $fontes 'AddonA') -Interface 16001
Assert-Verdade $ok.Compativel 'Test-AddonForever compativel'
Assert-Igual 'AddonA.toc' $ok.Toc 'Test-AddonForever Toc'
$ruim = Test-AddonForever -PastaAddon (Join-Path $fontes 'AddonClassic') -Interface 16001
Assert-Verdade (-not $ruim.Compativel) 'Test-AddonForever incompativel'
Assert-Igual 'TOC sem a Interface 16001 (tem: 11509)' $ruim.Motivo 'Test-AddonForever motivo'
Assert-Verdade (Test-AddonForever -PastaAddon (Join-Path $fontes 'AddonForeverToc') -Interface 16001).Compativel 'Test-AddonForever usa o Camelot (16001)'
Assert-Verdade (-not (Test-AddonForever -PastaAddon $pastaVazia -Interface 16001).Compativel) 'Test-AddonForever sem TOC'

# ---------------------------------------------------------------- zip, pastas, hash
$a = New-AmbienteTeste 'pastas'
$zipMulti = New-ZipDeFixture -Ambiente $a -Addons @('AddonMulti', 'AddonMulti_Options') -Nome 'multi.zip'
$zipEmb = New-ZipDeFixture -Ambiente $a -Addons @('Embrulho') -Nome 'embrulho.zip'
$x = Expand-ZipTemp -Zip $zipMulti
Assert-Verdade ($x -like (Join-Path $env:TEMP 'wow-agentes\x-*')) 'Expand-ZipTemp usa TEMP\wow-agentes\x-*'
$multi = @(Find-PastasDeAddon -Pasta $x)
Assert-Igual @('AddonMulti', 'AddonMulti_Options') @($multi | ForEach-Object { $_.Nome }) 'Find-PastasDeAddon multi'
Remove-Temp -Pasta $x
Assert-Verdade (-not (Test-Path -LiteralPath $x)) 'Remove-Temp apaga'
$msg = Get-MensagemErro { Remove-Temp -Pasta $a.Base }
Assert-Verdade ($msg -like 'ERRO:*') 'Remove-Temp recusa caminho fora de TEMP\wow-agentes'
Assert-Verdade (Test-Path -LiteralPath $a.Base) 'Remove-Temp nao apagou o caminho recusado'
$x = Expand-ZipTemp -Zip $zipEmb
$emb = @(Find-PastasDeAddon -Pasta $x)
Assert-Igual @('AddonB') @($emb | ForEach-Object { $_.Nome }) 'Find-PastasDeAddon embrulho'
Remove-Temp -Pasta $x
$vazio = Join-Path $a.Base 'dir-vazio'
[void](New-Item -ItemType Directory -Path $vazio -Force)
Assert-Igual 0 @(Find-PastasDeAddon -Pasta $vazio).Count 'Find-PastasDeAddon sem addon'

$h1 = Get-HashPasta -Pasta (Join-Path $fontes 'AddonMulti')
$h2 = Get-HashPasta -Pasta (Join-Path $fontes 'AddonMulti')
Assert-Igual $h1 $h2 'Get-HashPasta deterministico'
Assert-Verdade ($h1 -match '^[0-9a-f]{64}$') 'Get-HashPasta e sha256 hex minusculo'
$copia = Join-Path $a.Base 'copia\AddonMulti'
Copy-Item -LiteralPath (Join-Path $fontes 'AddonMulti') -Destination $copia -Recurse
Assert-Igual $h1 (Get-HashPasta -Pasta $copia) 'Get-HashPasta nao depende do local'
Add-Content -LiteralPath (Join-Path $copia 'AddonMulti.lua') -Value '-- mudou'
Assert-Verdade ($h1 -ne (Get-HashPasta -Pasta $copia)) 'Get-HashPasta muda com o conteudo'
$sig = Get-AssinaturaPasta -Pasta (Join-Path $fontes 'AddonMulti')
Assert-Verdade ($sig -match '^2\|\d+$') 'Get-AssinaturaPasta formato <arquivos>|<bytes>'

# junction
$alvo = Join-Path $a.Base 'alvo-junction'
[void](New-Item -ItemType Directory -Path $alvo -Force)
Set-Content -LiteralPath (Join-Path $alvo 'dentro.lua') -Value 'x'
$hospedeira = Join-Path $a.Base 'hospedeira'
[void](New-Item -ItemType Directory -Path $hospedeira -Force)
Set-Content -LiteralPath (Join-Path $hospedeira 'um.lua') -Value 'x'
$jn = Join-Path $hospedeira 'jn'
[void](New-Item -ItemType Junction -Path $jn -Target $alvo)
Assert-Verdade (Test-Junction -Caminho $jn) 'Test-Junction verdadeiro'
Assert-Verdade (-not (Test-Junction -Caminho $hospedeira)) 'Test-Junction falso'
Assert-Verdade ((Get-AssinaturaPasta -Pasta $hospedeira) -like '1|*') 'Get-AssinaturaPasta nao desce em junction'
$hAntes = Get-HashPasta -Pasta $hospedeira
Assert-Verdade ($hAntes -match '^[0-9a-f]{64}$') 'Get-HashPasta com junction'
$zj = Join-Path $a.Base 'bj.zip'
[void](Backup-Pastas -Pastas @($hospedeira) -Zip $zj)
Assert-Verdade (-not (@(Get-EntradasZip $zj) -contains 'hospedeira/jn/dentro.lua')) 'Backup-Pastas nao desce em junction'
[System.IO.Directory]::Delete($jn)
Assert-Verdade (Test-Path -LiteralPath (Join-Path $alvo 'dentro.lua')) 'Directory.Delete na junction preserva o alvo'

# Backup-Pastas
Assert-Verdade ($null -eq (Backup-Pastas -Pastas @() -Zip (Join-Path $a.Base 'nada.zip'))) 'Backup-Pastas lista vazia devolve nulo'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $a.Base 'nada.zip'))) 'Backup-Pastas lista vazia nao cria zip'
$zb = Join-Path $a.Base 'bk\x.zip'
[void](Backup-Pastas -Pastas @((Join-Path $fontes 'AddonMulti'), (Join-Path $fontes 'AddonA')) -Zip $zb)
$ent = @(Get-EntradasZip $zb)
Assert-Verdade ($ent -contains 'AddonMulti/AddonMulti.toc') 'Backup-Pastas pasta de topo AddonMulti'
Assert-Verdade ($ent -contains 'AddonA/AddonA.lua') 'Backup-Pastas pasta de topo AddonA'

# ---------------------------------------------------------------- Limit-Itens
$a = New-AmbienteTeste 'limit'
$lim = Join-Path $a.Base 'lim'
[void](New-Item -ItemType Directory -Path $lim -Force)
1..5 | ForEach-Object { Set-Content -LiteralPath (Join-Path $lim ("f{0:00}.txt" -f $_)) -Value 'x' }
[void](New-Item -ItemType Directory -Path (Join-Path $lim 'f00-dir') -Force)
Limit-Itens -Pasta $lim -Manter 2
Assert-Igual @('f04.txt', 'f05.txt') (@(Get-ChildItem -LiteralPath $lim | ForEach-Object { $_.Name }) | Sort-Object) 'Limit-Itens mantem os mais recentes pelo nome'
Limit-Itens -Pasta (Join-Path $a.Base 'nao-existe') -Manter 2
Assert-Verdade $true 'Limit-Itens com pasta inexistente nao falha'

# ---------------------------------------------------------------- Install-Pastas
$a = New-AmbienteTeste 'instpastas'
$ctx = Get-Contexto $a
$zipMulti = New-ZipDeFixture -Ambiente $a -Addons @('AddonMulti', 'AddonMulti_Options') -Nome 'multi.zip'
$x = Expand-ZipTemp -Zip $zipMulti
$origem = @(Find-PastasDeAddon -Pasta $x)
# estado anterior: AddonMulti antigo com arquivo velho, mais uma pasta que sumiu na versao nova
$velho = Join-Path $ctx.AddOns 'AddonMulti'
[void](New-Item -ItemType Directory -Path $velho -Force)
Set-Content -LiteralPath (Join-Path $velho 'velho.lua') -Value 'velho'
$sumiu = Join-Path $ctx.AddOns 'AddonSumiu'
[void](New-Item -ItemType Directory -Path $sumiu -Force)
Set-Content -LiteralPath (Join-Path $sumiu 'x.lua') -Value 'x'
$hashAntes = Get-HashPasta -Pasta $ctx.AddOns
$antesNomes = @(Get-ChildItem -LiteralPath $ctx.AddOns -Force | ForEach-Object { $_.Name } | Sort-Object)

$env:WOWAGENTE_FALHAR_COPIA = 'AddonMulti_Options'
$msg = Get-MensagemErro { Install-Pastas -Origem $origem -AddOns $ctx.AddOns -RemoverTambem @('AddonSumiu') }
Remove-Item -LiteralPath Env:\WOWAGENTE_FALHAR_COPIA
Assert-Verdade ($msg -like 'ERRO:*') 'Install-Pastas com falha simulada lanca ERRO'
Assert-Igual $hashAntes (Get-HashPasta -Pasta $ctx.AddOns) 'Install-Pastas rollback: AddOns igual por hash'
Assert-Igual $antesNomes (@(Get-ChildItem -LiteralPath $ctx.AddOns -Force | ForEach-Object { $_.Name } | Sort-Object)) 'Install-Pastas rollback: mesmos nomes (sem wowbak)'

Install-Pastas -Origem $origem -AddOns $ctx.AddOns -RemoverTambem @('AddonSumiu')
Assert-Verdade (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonMulti\AddonMulti.toc')) 'Install-Pastas copiou AddonMulti'
Assert-Verdade (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonMulti_Options\AddonMulti_Options.toc')) 'Install-Pastas copiou AddonMulti_Options'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonMulti\velho.lua'))) 'Install-Pastas substituiu a pasta antiga'
Assert-Verdade (-not (Test-Path -LiteralPath $sumiu)) 'Install-Pastas removeu a pasta de -RemoverTambem'
Assert-Igual 0 @(Get-ChildItem -LiteralPath $ctx.AddOns -Force | Where-Object { $_.Name -like '*.wowbak-*' }).Count 'Install-Pastas apaga os .wowbak no sucesso'
Remove-Temp -Pasta $x

# destino que e junction: RECUSA e nada muda
$alvoJ = Join-Path $a.Base 'meu-addon'
[void](New-Item -ItemType Directory -Path $alvoJ -Force)
Set-Content -LiteralPath (Join-Path $alvoJ 'dev.lua') -Value 'dev'
[void](New-Item -ItemType Junction -Path (Join-Path $ctx.AddOns 'AddonA') -Target $alvoJ)
$x = Expand-ZipTemp -Zip (New-ZipDeFixture -Ambiente $a -Addons @('AddonA') -Nome 'a.zip')
$msg = Get-MensagemErro { Install-Pastas -Origem @(Find-PastasDeAddon -Pasta $x) -AddOns $ctx.AddOns }
Assert-Verdade ($msg -like 'RECUSA:*') 'Install-Pastas recusa destino que e junction'
Assert-Verdade (Test-Path -LiteralPath (Join-Path $alvoJ 'dev.lua')) 'Install-Pastas nao tocou no alvo da junction'
$msg = Get-MensagemErro { Remove-PastasAddon -Nomes @('AddonA') -AddOns $ctx.AddOns }
Assert-Verdade ($msg -like 'RECUSA:*') 'Remove-PastasAddon recusa junction'
Remove-Temp -Pasta $x
[System.IO.Directory]::Delete((Join-Path $ctx.AddOns 'AddonA'))
Assert-Verdade (Test-Path -LiteralPath (Join-Path $alvoJ 'dev.lua')) 'alvo da junction intacto'

# ---------------------------------------------------------------- manifestos, registro, sessao
$a = New-AmbienteTeste 'estado'
$ctx = Get-Contexto $a
Assert-Igual 0 @(Get-Manifestos -Contexto $ctx).Count 'Get-Manifestos vazio'
Assert-Verdade ($null -eq (Get-Manifesto -Contexto $ctx -Slug 'nao')) 'Get-Manifesto inexistente'
$mf = [ordered]@{ v = 1; slug = 'um'; nome = 'Um'; versao = '1'; estadoInstalacao = 'instalado'
    pastas = @([ordered]@{ nome = 'Pasta1'; toc = 'Pasta1.toc'; interfaces = [int[]]@(16001); assinatura = '1|2'; sha256 = 'x' }) }
Save-Manifesto -Contexto $ctx -Manifesto $mf
Assert-Igual 1 @(Get-Manifestos -Contexto $ctx).Count 'Get-Manifestos com um'
$lido = Get-Manifesto -Contexto $ctx -Slug 'um'
Assert-Igual 'Pasta1' @($lido.pastas)[0].nome 'Save-Manifesto/Get-Manifesto ida e volta'
Assert-Igual @(16001) @(@($lido.pastas)[0].interfaces) 'manifesto: interfaces de um item continua lista'
Assert-Igual 'um' (Get-DonoDaPasta -Contexto $ctx -Nome 'pasta1') 'Get-DonoDaPasta (sem diferenciar maiusculas)'
Assert-Verdade ($null -eq (Get-DonoDaPasta -Contexto $ctx -Nome 'Outra')) 'Get-DonoDaPasta sem dono'
$mf.estadoInstalacao = 'removido'
Save-Manifesto -Contexto $ctx -Manifesto $mf
Assert-Verdade ($null -eq (Get-DonoDaPasta -Contexto $ctx -Nome 'Pasta1')) 'Get-DonoDaPasta ignora removidos'
Add-Registro -Contexto $ctx -Acao 'instalar' -Slug 'um' -Detalhe 'teste'
Add-Registro -Contexto $ctx -Acao 'remover' -Slug 'um' -Detalhe 'teste2'
$reg = Get-Content -LiteralPath $ctx.Registro -Encoding UTF8
Assert-Verdade (@($reg | Where-Object { $_ -match '^- \d{4}-\d\d-\d\d \d\d:\d\d \| instalar \| um \| teste$' }).Count -eq 1) 'Add-Registro formato da linha'
Assert-Verdade ($reg[0] -like '# *') 'Add-Registro cria o cabecalho'
Assert-Verdade (@($reg | Where-Object { $_ -like '- *' }).Count -eq 2) 'Add-Registro acrescenta (append-only)'
Assert-Verdade ($null -eq (Get-SessaoJson -Contexto $ctx)) 'Get-SessaoJson sem arquivo'
Save-SessaoJson -Contexto $ctx -Dados ([ordered]@{ v = 1; ultimaInterface = 16001; ultimaVersao = '1.60.1.1'; ultimaAbertura = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz') })
Assert-Igual 16001 (Get-SessaoJson -Contexto $ctx).ultimaInterface 'Save-SessaoJson/Get-SessaoJson'

# ---------------------------------------------------------------- Config.wtf
$a = New-AmbienteTeste 'cvar'
$cfg = Join-Path $a.Raiz '_forever_\WTF\Config.wtf'
$cv = Get-CVarsWtf -Arquivo $cfg
Assert-Igual 'ptBR' $cv['textLocale'] 'Get-CVarsWtf textLocale'
Assert-Igual '1' $cv['gxWindow'] 'Get-CVarsWtf gxWindow'
Set-CVarWtf -Arquivo $cfg -Valores @{ gxWindow = '0'; novaCVar = 'abc' }
$bytes = [IO.File]::ReadAllBytes($cfg)
$texto = [Text.Encoding]::UTF8.GetString($bytes)
Assert-Verdade ($texto.Contains('SET gxWindow "0"')) 'Set-CVarWtf troca o valor'
Assert-Verdade ($texto.Contains('SET novaCVar "abc"')) 'Set-CVarWtf acrescenta a que falta'
Assert-Verdade ($texto.Contains('SET textLocale "ptBR"')) 'Set-CVarWtf preserva as demais'
Assert-Igual '' ($texto.Replace("`r`n", '').Replace("`n", '|') -replace '[^|]', '') 'Set-CVarWtf nao deixa LF solto (so CRLF)'
Assert-Verdade ($texto.EndsWith("`r`n")) 'Set-CVarWtf preserva a quebra final'
Assert-Verdade (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF)) 'Set-CVarWtf nao introduz BOM'
Assert-Igual 4 @($texto -split "`r`n" | Where-Object { $_ }).Count 'Set-CVarWtf: 4 linhas'
# UTF-8 com BOM e LF
$cfg2 = Join-Path $a.Base 'Config-bom.wtf'
[System.IO.File]::WriteAllText($cfg2, ("SET textLocale `"ptBR`"`nSET nome `"Jo" + [char]0x00E3 + "o`"`n"), (New-Object System.Text.UTF8Encoding $true))
Set-CVarWtf -Arquivo $cfg2 -Valores @{ textLocale = 'enUS' }
$b2 = [IO.File]::ReadAllBytes($cfg2)
Assert-Verdade ($b2[0] -eq 0xEF -and $b2[1] -eq 0xBB -and $b2[2] -eq 0xBF) 'Set-CVarWtf preserva o BOM'
$t2 = [Text.Encoding]::UTF8.GetString($b2, 3, $b2.Length - 3)
Assert-Verdade (-not $t2.Contains("`r")) 'Set-CVarWtf preserva LF'
Assert-Verdade ($t2.Contains('SET textLocale "enUS"') -and $t2.Contains("Jo$([char]0x00E3)o")) 'Set-CVarWtf preserva acentos'

# ---------------------------------------------------------------- Backup-Wtf
$a = New-AmbienteTeste 'bkwtf'
$ctx = Get-Contexto $a
$sess = Join-Path $ctx.Backups 'sessoes'
[void](New-Item -ItemType Directory -Path $sess -Force)
1..25 | ForEach-Object { [void](New-Item -ItemType Directory -Path (Join-Path $sess ("2020-01-01_00{0:00}" -f $_)) -Force) }
$zipw = Backup-Wtf -Contexto $ctx -Rotulo 'teste de rotulo'
Assert-Verdade (Test-Path -LiteralPath $zipw -PathType Leaf) 'Backup-Wtf criou o zip'
Assert-Igual 'WTF.zip' ([IO.Path]::GetFileName($zipw)) 'Backup-Wtf nome do zip'
Assert-Verdade (@(Get-EntradasZip $zipw) -contains 'WTF/Config.wtf') 'Backup-Wtf contem WTF/Config.wtf'
Assert-Verdade (@(Get-EntradasZip $zipw) -contains 'WTF/Account/CONTA1/SavedVariables/Exemplo.lua') 'Backup-Wtf contem SavedVariables'
$infoTxt = Get-Content -LiteralPath (Join-Path ([IO.Path]::GetDirectoryName($zipw)) 'info.txt') -Raw -Encoding UTF8
Assert-Verdade ($infoTxt -like '*teste de rotulo*') 'Backup-Wtf grava info.txt com o rotulo'
Assert-Igual 20 @(Get-ChildItem -LiteralPath $sess).Count 'Backup-Wtf limita a 20 sessoes'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $sess '2020-01-01_0001'))) 'Backup-Wtf apagou a mais antiga'
Assert-Verdade (Test-Path -LiteralPath (Split-Path -Parent $zipw)) 'Backup-Wtf manteve a nova'
$zipw2 = Backup-Wtf -Contexto $ctx
Assert-Verdade ($zipw2 -ne $zipw) 'Backup-Wtf no mesmo minuto nao sobrescreve'
$b = New-AmbienteTeste 'bkwtf-sem'
Remove-Item -LiteralPath (Join-Path $b.Raiz '_forever_\WTF') -Recurse -Force
$ctxb = Get-Contexto $b
$msg = Get-MensagemErro { Backup-Wtf -Contexto $ctxb }
Assert-Verdade ($msg -like 'PREREQ: WTF ainda não existe*') 'Backup-Wtf sem WTF: PREREQ'

# ---------------------------------------------------------------- Get-FonteAddon simulado
$a = New-AmbienteTeste 'fontes'
$zipFonte = New-ZipDeFixture -Ambiente $a -Addons @('AddonForeverToc') -Nome 'exemplo.zip'
$gh = Get-Content -LiteralPath (Join-Path $respostasFixture 'github-exemplo.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$gh.assets[0].browser_download_url = $zipFonte
$rl = Get-Content -LiteralPath (Join-Path $respostasFixture 'release-exemplo.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = $gh; 'github-dono_exemplo-release.json' = $rl }
$f = Get-FonteAddon -Fonte 'github:dono/exemplo' -Interface 16001 -VersaoJogo '1.60.1'
Assert-Igual 'github' $f.Tipo 'Get-FonteAddon github tipo'
Assert-Igual 'dono/exemplo' $f.Id 'Get-FonteAddon github id'
Assert-Igual 'v1.2.3' $f.Versao 'Get-FonteAddon github versao (da release.json)'
Assert-Igual 'Exemplo-v1.2.3.zip' $f.Asset 'Get-FonteAddon github asset'
Assert-Igual $zipFonte $f.Url 'Get-FonteAddon github url'
Assert-Verdade ($f.Compativel -eq $true) 'Get-FonteAddon github release.json compativel'
Assert-Igual '2026-10-20T12:00:00Z' $f.Data 'Get-FonteAddon github data'
# release.json sem o flavor forever
$rl2 = Get-Content -LiteralPath (Join-Path $respostasFixture 'release-exemplo.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$rl2.releases[0].metadata[0].flavor = 'classic'; $rl2.releases[0].metadata[0].interface = 11509
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo-release.json' = $rl2 }
$f = Get-FonteAddon -Fonte 'github:dono/exemplo' -Interface 16001
Assert-Verdade ($f.Compativel -eq $false) 'Get-FonteAddon release.json sem forever: incompativel'
Assert-Igual 'release.json sem o flavor forever' $f.Motivo 'Get-FonteAddon release.json sem forever: motivo'
# release.json casa pela Interface mesmo sem o flavor forever
$rl2.releases[0].metadata[0].interface = 16001
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo-release.json' = $rl2 }
Assert-Verdade ((Get-FonteAddon -Fonte 'github:dono/exemplo' -Interface 16001).Compativel -eq $true) 'Get-FonteAddon release.json casa pela Interface'
# nolib e ignorado
$rl3 = [pscustomobject]@{ releases = @(
    [pscustomobject]@{ name = 'x'; version = 'v9-nolib'; filename = 'x-nolib.zip'; nolib = $true; metadata = @([pscustomobject]@{ flavor = 'forever'; interface = 16001 }) },
    [pscustomobject]@{ name = 'x'; version = 'v9'; filename = 'x.zip'; nolib = $false; metadata = @([pscustomobject]@{ flavor = 'forever'; interface = 16001 }) }) }
$ghn = [pscustomobject]@{ tag_name = 'v9'; published_at = '2026-10-01T00:00:00Z'; assets = @(
    [pscustomobject]@{ name = 'x-nolib.zip'; browser_download_url = 'C:\nolib.zip' },
    [pscustomobject]@{ name = 'x.zip'; browser_download_url = 'C:\x.zip' },
    [pscustomobject]@{ name = 'release.json'; browser_download_url = 'C:\r.json' }) }
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = $ghn; 'github-dono_exemplo-release.json' = $rl3 }
$f = Get-FonteAddon -Fonte 'github:dono/exemplo' -Interface 16001
Assert-Igual 'x.zip' $f.Asset 'Get-FonteAddon ignora release nolib'

# heuristica (sem release.json)
function New-GhSemRelease { param([string[]]$Nomes) [pscustomobject]@{ tag_name = 'v2.0'; published_at = '2026-10-02T00:00:00Z'
    assets = @($Nomes | ForEach-Object { [pscustomobject]@{ name = $_; browser_download_url = "https://github.com/dono/exemplo/releases/download/v2.0/$_" } }) } }
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = (New-GhSemRelease @('X-classic.zip', 'X-forever.zip', 'X-retail.zip')) }
Remove-Item -LiteralPath (Join-Path $env:WOWAGENTE_RESPOSTAS 'github-dono_exemplo-release.json') -Force
$f = Get-FonteAddon -Fonte 'github:dono/exemplo'
Assert-Igual 'X-forever.zip' $f.Asset 'Get-FonteAddon heuristica: forever|camelot'
Assert-Igual 'v2.0' $f.Versao 'Get-FonteAddon heuristica: versao = tag_name'
Assert-Verdade ($null -eq $f.Compativel) 'Get-FonteAddon heuristica: Compativel nulo'
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = (New-GhSemRelease @('X-classic.zip', 'X-mainline.zip', 'X-special.zip')) }
Assert-Igual 'X-special.zip' (Get-FonteAddon -Fonte 'github:dono/exemplo').Asset 'Get-FonteAddon heuristica: unico que sobra'
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = (New-GhSemRelease @('X-um.zip', 'X-dois.zip')) }
Assert-Igual 'X-dois.zip' (Get-FonteAddon -Fonte 'github:dono/exemplo' -Asset 'dois').Asset 'Get-FonteAddon heuristica: -Asset'
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = (New-GhSemRelease @('X-unico.zip', 'notas.txt')) }
Assert-Igual 'X-unico.zip' (Get-FonteAddon -Fonte 'github:dono/exemplo').Asset 'Get-FonteAddon heuristica: unico zip'
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = (New-GhSemRelease @('X-classic.zip', 'X-retail.zip', 'notas.txt')) }
$msg = Get-MensagemErro { Get-FonteAddon -Fonte 'github:dono/exemplo' }
Assert-Verdade ($msg -like 'RECUSA:*X-classic.zip*') 'Get-FonteAddon heuristica: nada serve gera RECUSA com os nomes'
# '+' vira %2B no caminho, nao na query
$ghp = [pscustomobject]@{ tag_name = 'v1+2'; published_at = '2026-10-02T00:00:00Z'; assets = @(
    [pscustomobject]@{ name = 'Q-v1+2.zip'; browser_download_url = 'https://github.com/dono/exemplo/releases/download/v1+2/Q-v1+2.zip?a=b+c' }) }
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = $ghp }
Assert-Igual 'https://github.com/dono/exemplo/releases/download/v1%2B2/Q-v1%2B2.zip?a=b+c' (Get-FonteAddon -Fonte 'github:dono/exemplo').Url 'Get-FonteAddon troca + por %2B so no caminho'

# Tukui
$tk = Get-Content -LiteralPath (Join-Path $respostasFixture 'tukui-exemplo.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$tk.url = $zipFonte
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'tukui-exemplo.json' = $tk }
$t = Get-FonteAddon -Fonte 'tukui:exemplo' -VersaoJogo '1.60.1'
Assert-Igual 'tukui' $t.Tipo 'Get-FonteAddon tukui tipo'
Assert-Igual '3.4.5' $t.Versao 'Get-FonteAddon tukui versao'
Assert-Igual '2026-10-25' $t.Data 'Get-FonteAddon tukui data'
Assert-Verdade ($t.Compativel -eq $true) 'Get-FonteAddon tukui compativel'
Assert-Igual $zipFonte $t.Url 'Get-FonteAddon tukui url'
$t = Get-FonteAddon -Fonte 'tukui:exemplo' -VersaoJogo '1.99.0'
Assert-Verdade ($t.Compativel -eq $false) 'Get-FonteAddon tukui incompativel'
Assert-Verdade ($t.Motivo -like '*1.99.0*1.60.1*') 'Get-FonteAddon tukui motivo'
Assert-Verdade ($null -eq (Get-FonteAddon -Fonte 'tukui:exemplo').Compativel) 'Get-FonteAddon tukui sem VersaoJogo: nulo'
$msg = Get-MensagemErro { Get-FonteAddon -Fonte 'tukui:sem-resposta' }
Assert-Verdade ($msg -like 'ERRO:*') 'Get-FonteAddon sem resposta simulada: ERRO'
$msg = Get-MensagemErro { Get-FonteAddon -Fonte 'xpto:abc' }
Assert-Verdade ($msg -like 'ERRO:*') 'Get-FonteAddon fonte invalida'

# Save-Download
$dl = Join-Path $a.Base 'dl\copia.zip'
Save-Download -Url $zipFonte -Destino $dl
Assert-Igual (Get-FileHash -LiteralPath $zipFonte -Algorithm SHA256).Hash (Get-FileHash -LiteralPath $dl -Algorithm SHA256).Hash 'Save-Download copia caminho local'
$dl2 = Join-Path $a.Base 'dl\copia2.zip'
Save-Download -Url ([Uri]$zipFonte).AbsoluteUri -Destino $dl2
Assert-Verdade (Test-Path -LiteralPath $dl2) 'Save-Download copia file:///'
$msg = Get-MensagemErro { Save-Download -Url 'https://exemplo.invalid/x.zip' -Destino (Join-Path $a.Base 'dl\nao.zip') }
Assert-Verdade ($msg -like 'ERRO:*') 'Save-Download simulado recusa URL remota'

# ---------------------------------------------------------------- Install-AddonDeFonte e Remove-Addon (zip)
$a = New-AmbienteTeste 'instalar'
$ctx = Get-Contexto $a
$zipA = New-ZipDeFixture -Ambiente $a -Addons @('AddonA') -Nome 'a.zip'
$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipA" -Slug 'addona' -Nome 'Addon A' -Pagina 'https://exemplo.invalid/a' }
Assert-Verdade ($r.Linhas -contains "PREVIA slug=addona versao=1.0.0 fonte=zip:$zipA acao=criar") 'previa: linha PREVIA'
Assert-Verdade ($r.Linhas -contains 'PASTA nome=AddonA acao=criar toc=AddonA.toc interfaces=16001 compativel=sim') 'previa: linha PASTA'
Assert-Verdade ($r.Linhas -contains 'Prévia apenas; rode com -Aplicar para instalar.') 'previa: aviso'
Assert-Verdade (-not $r.Resultado.Aplicado) 'previa: Aplicado falso'
Assert-Igual 'criar' $r.Resultado.Acao 'previa: Acao criar'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonA'))) 'previa nao grava a pasta'
Assert-Igual 0 @(Get-ChildItem -LiteralPath $ctx.Manifestos -Filter *.json).Count 'previa nao grava manifesto'
Assert-Verdade (-not (Test-Path -LiteralPath $ctx.Registro)) 'previa nao grava registro'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx.Backups 'addons'))) 'previa nao cria backup'

$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipA" -Slug 'addona' -Nome 'Addon A' -Pagina 'https://exemplo.invalid/a' -Aplicar }
Assert-Verdade ($r.Resultado.Aplicado) 'aplicar: Aplicado verdadeiro'
Assert-Verdade ($r.Linhas -contains 'OK instalado slug=addona versao=1.0.0') 'aplicar: linha OK instalado'
Assert-Verdade (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonA\AddonA.toc')) 'aplicar: gravou a pasta'
$m = Get-Manifesto -Contexto $ctx -Slug 'addona'
Assert-Igual 'instalado' $m.estadoInstalacao 'manifesto: estadoInstalacao'
Assert-Igual '1.0.0' $m.versao 'manifesto: versao'
Assert-Igual 'Addon A' $m.nome 'manifesto: nome'
Assert-Igual 'zip' $m.fonte.tipo 'manifesto: fonte.tipo'
Assert-Igual $zipA $m.fonte.id 'manifesto: fonte.id'
Assert-Igual 'https://exemplo.invalid/a' $m.fonte.pagina 'manifesto: fonte.pagina'
Assert-Igual 'AddonA' @($m.pastas)[0].nome 'manifesto: pasta'
Assert-Igual 'AddonA.toc' @($m.pastas)[0].toc 'manifesto: toc'
Assert-Igual @(16001) @(@($m.pastas)[0].interfaces) 'manifesto: interfaces'
Assert-Igual (Get-HashPasta -Pasta (Join-Path $ctx.AddOns 'AddonA')) @($m.pastas)[0].sha256 'manifesto: sha256 confere com o instalado'
Assert-Igual (Get-AssinaturaPasta -Pasta (Join-Path $ctx.AddOns 'AddonA')) @($m.pastas)[0].assinatura 'manifesto: assinatura confere'
Assert-Verdade ($m.aprovado -eq $true) 'manifesto: aprovado'
Assert-Verdade ($null -eq $m.removidoEm -and $null -eq $m.backupAnterior) 'manifesto: removidoEm e backupAnterior nulos na instalacao'
Assert-Verdade ($m.instaladoEm -match '^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d[+-]\d\d:\d\d$') 'manifesto: data ISO'
$reg = Get-Content -LiteralPath $ctx.Registro -Encoding UTF8
Assert-Verdade (@($reg | Where-Object { $_ -match '\| instalar \| addona \|' }).Count -eq 1) 'aplicar: registro instalar'

$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipA" -Slug 'addona' -Aplicar }
Assert-Igual 'nada' $r.Resultado.Acao 'mesma versao: Acao nada'
Assert-Verdade ($r.Linhas -contains 'OK nada a fazer slug=addona versao=1.0.0') 'mesma versao: linha OK nada a fazer'
Assert-Igual 1 @(Get-Content -LiteralPath $ctx.Registro | Where-Object { $_ -like '- *' }).Count 'mesma versao: nao registra'

# atualizacao (-Forcar na mesma versao) com backup em zip
Add-Content -LiteralPath (Join-Path $ctx.AddOns 'AddonA\AddonA.lua') -Value '-- alterado pelo jogador'
$instaladoEm = $m.instaladoEm
$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipA" -Slug 'addona' -Forcar -Aplicar }
Assert-Igual 'atualizar' $r.Resultado.Acao 'atualizacao: Acao'
Assert-Verdade ($r.Linhas -contains 'PASTA nome=AddonA acao=substituir toc=AddonA.toc interfaces=16001 compativel=sim') 'atualizacao: PASTA substituir'
Assert-Verdade ($r.Linhas -contains 'OK atualizado slug=addona de=1.0.0 para=1.0.0') 'atualizacao: linha OK atualizado'
Assert-Verdade ($r.Resultado.Backup -and (Test-Path -LiteralPath $r.Resultado.Backup -PathType Leaf)) 'atualizacao: backup em zip'
Assert-Verdade ($r.Resultado.Backup -like (Join-Path $ctx.Backups 'addons\addona\*.zip')) 'atualizacao: backup em Backups\addons\<slug>\'
Assert-Verdade (@(Get-EntradasZip $r.Resultado.Backup) -contains 'AddonA/AddonA.lua') 'atualizacao: o zip tem a pasta antiga'
$m = Get-Manifesto -Contexto $ctx -Slug 'addona'
Assert-Igual $r.Resultado.Backup $m.backupAnterior 'atualizacao: backupAnterior'
Assert-Igual $instaladoEm $m.instaladoEm 'atualizacao: instaladoEm preservado'
Assert-Verdade (-not ((Get-Content -LiteralPath (Join-Path $ctx.AddOns 'AddonA\AddonA.lua') -Raw) -like '*alterado*')) 'atualizacao: restaurou o conteudo do zip'
Assert-Verdade (@(Get-Content -LiteralPath $ctx.Registro | Where-Object { $_ -match '\| atualizar \| addona \|' }).Count -eq 1) 'atualizacao: registro atualizar'
# o backup limita a 3
1..4 | ForEach-Object { $null = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipA" -Slug 'addona' -Forcar -Aplicar }; Start-Sleep -Milliseconds 20 }
Assert-Igual 3 @(Get-ChildItem -LiteralPath (Join-Path $ctx.Backups 'addons\addona')).Count 'backups do addon limitados a 3'

# jogo aberto: RECUSA e nada muda
$zipC = New-ZipDeFixture -Ambiente $a -Addons @('AddonForeverToc') -Nome 'c.zip'
$env:WOWAGENTE_JOGO_ABERTO = '1'
$msg = Get-MensagemErro { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipC" -Slug 'aberto' -Aplicar }
Assert-Verdade ($msg -like 'RECUSA: Jogo aberto*') 'aplicar com jogo aberto: RECUSA'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonForeverToc'))) 'jogo aberto: nada gravado'
$null = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipC" -Slug 'aberto' }
Assert-Verdade $true 'jogo aberto: a previa funciona'
Remove-Item -LiteralPath Env:\WOWAGENTE_JOGO_ABERTO

# TOC incompativel: RECUSA; -Forcar deixa passar
$zipX = New-ZipDeFixture -Ambiente $a -Addons @('AddonClassic') -Nome 'classic.zip'
$msg = Get-MensagemErro { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipX" -Slug 'classico' -Aplicar }
Assert-Verdade ($msg -like 'RECUSA:*AddonClassic*Interface 16001*tem: 11509*') 'TOC incompativel: RECUSA com o motivo'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonClassic'))) 'TOC incompativel: nada gravado'
$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipX" -Slug 'classico' -Forcar }
Assert-Verdade ($r.Linhas -contains 'PASTA nome=AddonClassic acao=criar toc=AddonClassic.toc interfaces=11509 compativel=nao') 'TOC incompativel: previa marca compativel=nao'
$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipX" -Slug 'classico' -Forcar -Aplicar }
Assert-Verdade (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonClassic\AddonClassic.toc')) '-Forcar instala TOC incompativel'
Assert-Verdade ($r.Linhas -contains 'OK instalado slug=classico versao=zip-' -or @($r.Linhas | Where-Object { $_ -like 'OK instalado slug=classico versao=zip-*' }).Count -eq 1) 'zip sem Version: versao zip-<hash>'

# conflito de pasta com outro manifesto
$msg = Get-MensagemErro { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipA" -Slug 'outro' -Aplicar }
Assert-Igual 'RECUSA: pasta AddonA pertence ao addon addona' $msg 'conflito: RECUSA'
$msg = Get-MensagemErro { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipA" -Slug 'outro' -Forcar -Aplicar }
Assert-Verdade ($msg -like 'RECUSA: pasta AddonA pertence ao addon addona') 'conflito: -Forcar nao passa (decisao da T4)'
Assert-Verdade ($null -eq (Get-Manifesto -Contexto $ctx -Slug 'outro')) 'conflito: sem manifesto novo'

# zip sem addon / zip inexistente / slug invalido
$zipVazio = Join-Path $a.Base 'zips\vazio.zip'
$za = [System.IO.Compression.ZipFile]::Open($zipVazio, [System.IO.Compression.ZipArchiveMode]::Create)
$e = $za.CreateEntry('LEIAME.txt'); $sw = New-Object System.IO.StreamWriter($e.Open()); $sw.Write('oi'); $sw.Dispose(); $za.Dispose()
$msg = Get-MensagemErro { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipVazio" -Slug 'vazio' }
Assert-Verdade ($msg -like 'RECUSA: o zip não contém addon*') 'zip sem addon: RECUSA'
$msg = Get-MensagemErro { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$($a.Base)\nao-existe.zip" -Slug 'vazio' }
Assert-Verdade ($msg -like 'PREREQ:*') 'zip inexistente: PREREQ'
$msg = Get-MensagemErro { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipA" -Slug 'Slug Ruim' }
Assert-Verdade ($msg -like 'ERRO:*') 'slug invalido: ERRO'
$msgCli = Get-MensagemErro { Install-AddonDeFonte -Contexto (Get-Contexto (New-AmbienteTeste 'semver')) -Fonte "zip:$zipA" -Slug 'x' }
Assert-Verdade ($msgCli -eq '') 'previa em outro ambiente funciona'
$b = New-AmbienteTeste 'semver2'
Remove-Item -LiteralPath (Join-Path $b.Raiz '.build.info') -Force
$msg = Get-MensagemErro { Install-AddonDeFonte -Contexto (Get-Contexto $b) -Fonte "zip:$zipA" -Slug 'x' }
Assert-Verdade ($msg -like 'PREREQ:*') 'sem versao do cliente: PREREQ'

# multi e embrulho
$zipM = New-ZipDeFixture -Ambiente $a -Addons @('AddonMulti', 'AddonMulti_Options') -Nome 'multi.zip'
$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipM" -Slug 'multi' -Aplicar }
Assert-Verdade ((Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonMulti')) -and (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonMulti_Options'))) 'multi: instalou as duas pastas'
Assert-Igual 2 @((Get-Manifesto -Contexto $ctx -Slug 'multi').pastas).Count 'multi: manifesto com duas pastas'
Assert-Igual '2.0.0' (Get-Manifesto -Contexto $ctx -Slug 'multi').versao 'multi: versao do TOC da primeira pasta'
$zipE = New-ZipDeFixture -Ambiente $a -Addons @('Embrulho') -Nome 'embrulho.zip'
$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipE" -Slug 'embrulhado' -Aplicar }
Assert-Verdade (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonB\AddonB.toc')) 'embrulho: instalou AddonB'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'Embrulho'))) 'embrulho: nao instalou a pasta de embrulho'
# a pasta que some na versao nova sai como remover
$zipM2 = New-ZipDeFixture -Ambiente $a -Addons @('AddonMulti') -Nome 'multi2.zip'
$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipM2" -Slug 'multi' -Forcar -Aplicar }
Assert-Verdade ($r.Linhas -contains 'PASTA nome=AddonMulti_Options acao=remover') 'atualizacao: pasta que sumiu sai como remover'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonMulti_Options'))) 'atualizacao: removeu a pasta que sumiu'
Assert-Verdade (@(Get-EntradasZip $r.Resultado.Backup) -contains 'AddonMulti_Options/AddonMulti_Options.toc') 'atualizacao: backup guarda a pasta removida'

# ---------------------------------------------------------------- Install-AddonDeFonte (github e tukui simulados)
$a = New-AmbienteTeste 'instalar-gh'
$ctx = Get-Contexto $a
$z1 = New-ZipDeFixture -Ambiente $a -Addons @('AddonForeverToc') -Nome 'v1.zip'
$z2 = New-ZipDeFixture -Ambiente $a -Addons @('AddonForeverToc') -Nome 'v2.zip'
function New-GhUnico { param([string]$Tag, [string]$Zip) [pscustomobject]@{ tag_name = $Tag; published_at = '2026-10-02T00:00:00Z'
    assets = @([pscustomobject]@{ name = "ForeverToc-$Tag.zip"; browser_download_url = $Zip }) } }
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = (New-GhUnico 'v1' $z1) }
$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte 'github:dono/exemplo' -Slug 'gh' -Nome 'Exemplo GH' -Aplicar }
Assert-Verdade ($r.Linhas -contains 'OK instalado slug=gh versao=v1') 'github: instalou v1'
$m = Get-Manifesto -Contexto $ctx -Slug 'gh'
Assert-Igual 'github' $m.fonte.tipo 'github: manifesto fonte.tipo'
Assert-Igual 'dono/exemplo' $m.fonte.id 'github: manifesto fonte.id'
Assert-Igual @(16001) @(@($m.pastas)[0].interfaces) 'github: TOC Camelot (16001) em vez do generico'
$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte 'github:dono/exemplo' -Slug 'gh' -Aplicar }
Assert-Igual 'nada' $r.Resultado.Acao 'github: mesma versao nao baixa nem instala'
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = (New-GhUnico 'v2' $z2) }
$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte 'github:dono/exemplo' -Slug 'gh' -Aplicar }
Assert-Verdade ($r.Linhas -contains 'OK atualizado slug=gh de=v1 para=v2') 'github: atualizou v1 para v2'
Assert-Verdade (Test-Path -LiteralPath $r.Resultado.Backup -PathType Leaf) 'github: backup da v1'
Assert-Igual 'Exemplo GH' (Get-Manifesto -Contexto $ctx -Slug 'gh').nome 'github: nome preservado na atualizacao'
# fonte incompativel: RECUSA; -Forcar passa
$rlN = [pscustomobject]@{ releases = @([pscustomobject]@{ name = 'x'; version = 'v3'; filename = 'x.zip'; nolib = $false; metadata = @([pscustomobject]@{ flavor = 'classic'; interface = 11509 }) }) }
$ghN = [pscustomobject]@{ tag_name = 'v3'; published_at = '2026-10-03T00:00:00Z'; assets = @(
    [pscustomobject]@{ name = 'x.zip'; browser_download_url = $z2 }, [pscustomobject]@{ name = 'release.json'; browser_download_url = 'C:\r.json' }) }
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'github-dono_exemplo.json' = $ghN; 'github-dono_exemplo-release.json' = $rlN }
$msg = Get-MensagemErro { Install-AddonDeFonte -Contexto $ctx -Fonte 'github:dono/exemplo' -Slug 'gh' -Aplicar }
Assert-Verdade ($msg -like 'RECUSA:*release.json sem o flavor forever*') 'github incompativel: RECUSA'
$msg = Get-MensagemErro { Install-AddonDeFonte -Contexto $ctx -Fonte 'github:dono/exemplo' -Slug 'gh' -Forcar -Aplicar }
Assert-Verdade ($msg -like 'RECUSA:*' -or $msg -like 'ERRO:*') 'github incompativel + -Forcar sem asset utilizavel nao instala'

# Tukui
$tk = Get-Content -LiteralPath (Join-Path $respostasFixture 'tukui-exemplo.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$tk.url = (New-ZipDeFixture -Ambiente $a -Addons @('AddonA') -Nome 'tk.zip')
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'tukui-exemplo.json' = $tk }
$r = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte 'tukui:exemplo' -Slug 'tk' -Aplicar }
Assert-Verdade ($r.Linhas -contains 'OK instalado slug=tk versao=3.4.5') 'tukui: instalou'
$mt = Get-Manifesto -Contexto $ctx -Slug 'tk'
Assert-Igual 'tukui' $mt.fonte.tipo 'tukui: fonte.tipo'
Assert-Igual 'exemplo' $mt.fonte.id 'tukui: fonte.id'
Assert-Verdade (-not ((Get-Content -LiteralPath (Join-Path $ctx.Estado 'addons\tk.json') -Raw) -match 'token')) 'tukui: a URL com token nao vai para o manifesto'
$tk2 = Get-Content -LiteralPath (Join-Path $respostasFixture 'tukui-exemplo.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$tk2.url = $tk.url; $tk2.patch = @('1.15.9')
Set-RespostasSimuladas -Ambiente $a -Arquivos @{ 'tukui-outro.json' = $tk2 }
$msg = Get-MensagemErro { Install-AddonDeFonte -Contexto $ctx -Fonte 'tukui:outro' -Slug 'tk2' -Aplicar }
Assert-Verdade ($msg -like 'RECUSA:*1.60.1*') 'tukui incompativel: RECUSA'

# ---------------------------------------------------------------- Remove-Addon
$a = New-AmbienteTeste 'remover'
$ctx = Get-Contexto $a
$zipM = New-ZipDeFixture -Ambiente $a -Addons @('AddonMulti', 'AddonMulti_Options') -Nome 'multi.zip'
$null = Invoke-Capturando { Install-AddonDeFonte -Contexto $ctx -Fonte "zip:$zipM" -Slug 'multi' -Aplicar }
$hAddOns = Get-HashPasta -Pasta $ctx.AddOns
$r = Invoke-Capturando { Remove-Addon -Contexto $ctx -Slug 'multi' }
Assert-Verdade ($r.Linhas -contains 'PREVIA slug=multi acao=remover') 'remover: previa'
Assert-Verdade (($r.Linhas -contains 'PASTA nome=AddonMulti acao=remover') -and ($r.Linhas -contains 'PASTA nome=AddonMulti_Options acao=remover')) 'remover: previa por pasta'
Assert-Igual $hAddOns (Get-HashPasta -Pasta $ctx.AddOns) 'remover: a previa nao altera nada'
Assert-Igual 'instalado' (Get-Manifesto -Contexto $ctx -Slug 'multi').estadoInstalacao 'remover: previa nao altera o manifesto'
$env:WOWAGENTE_JOGO_ABERTO = '1'
$msg = Get-MensagemErro { Remove-Addon -Contexto $ctx -Slug 'multi' -Aplicar }
Remove-Item -LiteralPath Env:\WOWAGENTE_JOGO_ABERTO
Assert-Verdade ($msg -like 'RECUSA: Jogo aberto*') 'remover: jogo aberto recusa'
Assert-Igual $hAddOns (Get-HashPasta -Pasta $ctx.AddOns) 'remover: jogo aberto nao altera nada'
$r = Invoke-Capturando { Remove-Addon -Contexto $ctx -Slug 'multi' -Aplicar }
Assert-Verdade ($r.Linhas -contains 'OK removido slug=multi') 'remover: linha OK removido'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonMulti'))) 'remover: apagou a pasta'
Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $ctx.AddOns 'AddonMulti_Options'))) 'remover: apagou a outra pasta'
$m = Get-Manifesto -Contexto $ctx -Slug 'multi'
Assert-Igual 'removido' $m.estadoInstalacao 'remover: manifesto removido'
Assert-Verdade ($null -ne $m.removidoEm) 'remover: removidoEm preenchido'
Assert-Verdade ($m.backupAnterior -and (Test-Path -LiteralPath $m.backupAnterior -PathType Leaf)) 'remover: backupAnterior existe'
Assert-Verdade (@(Get-EntradasZip $m.backupAnterior) -contains 'AddonMulti/AddonMulti.toc') 'remover: backup tem as pastas'
Assert-Verdade ($null -eq (Get-DonoDaPasta -Contexto $ctx -Nome 'AddonMulti')) 'remover: pasta sem dono depois'
Assert-Verdade (@(Get-Content -LiteralPath $ctx.Registro | Where-Object { $_ -match '\| remover \| multi \|' }).Count -eq 1) 'remover: registro'
$msg = Get-MensagemErro { Remove-Addon -Contexto $ctx -Slug 'multi' -Aplicar }
Assert-Verdade ($msg -like 'PREREQ:*') 'remover: manifesto ja removido: PREREQ'
$msg = Get-MensagemErro { Remove-Addon -Contexto $ctx -Slug 'nunca-existiu' }
Assert-Verdade ($msg -like 'PREREQ:*') 'remover: sem manifesto: PREREQ'
$dev = [ordered]@{ v = 1; slug = 'dev-meu'; nome = 'Meu'; versao = 'dev'; fonte = [ordered]@{ tipo = 'dev'; id = 'C:\x'; asset = $null; pagina = $null }
    pastas = @([ordered]@{ nome = 'Meu'; toc = 'Meu.toc'; interfaces = [int[]]@(16001); assinatura = '0|0'; sha256 = '' }); estadoInstalacao = 'instalado' }
Save-Manifesto -Contexto $ctx -Manifesto $dev
$msg = Get-MensagemErro { Remove-Addon -Contexto $ctx -Slug 'dev-meu' -Aplicar }
Assert-Igual 'RECUSA: use dev-link.ps1 -Remover' $msg 'remover: manifesto dev recusa'

} finally {
    if (-not $Manter) { Remove-AmbientesTeste }
}

$res = Get-Resultado
if ($res.Falhas.Count -gt 0) {
    foreach ($f in $res.Falhas) { Write-Output "FALHOU: $f" }
    exit 1
}
Write-Output "OK $($res.Total) verificacoes"
exit 0
