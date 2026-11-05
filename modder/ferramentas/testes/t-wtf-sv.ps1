param([switch]$Manter)
$ErrorActionPreference = 'Stop'
$Aqui = $PSScriptRoot
. (Join-Path $Aqui '_assert.ps1')
. (Join-Path $Aqui '_preparar.ps1')
. (Join-Path $Aqui '..\wow-comum.ps1')

$svScript = (Resolve-Path -LiteralPath (Join-Path $Aqui '..\wtf-sv.ps1')).ProviderPath

# ---------------------------------------------------------------- ajudantes locais

function Get-Contexto {
    param($A)
    Get-WowContexto -Raiz $A.Raiz -Flavor $A.Flavor -Estado $A.Estado -Backups $A.Backups -Instalacao (Join-Path $A.Base 'inst.json')
}

function Tem-LinhaLike {
    param([string]$Texto, [string]$Padrao)
    return (@($Texto -split "`n" | ForEach-Object { $_.TrimEnd() } | Where-Object { $_ -like $Padrao }).Count -gt 0)
}

function Get-Base64 {
    param([string]$Caminho)
    return [Convert]::ToBase64String([IO.File]::ReadAllBytes($Caminho))
}

function Contar-Registro {
    param($C, [string]$Acao)
    if (-not (Test-Path -LiteralPath $C.Registro)) { return 0 }
    return (@(Get-Content -LiteralPath $C.Registro -Encoding UTF8 | Where-Object { $_ -like "*| $Acao | *" })).Count
}

function Contar-Sessoes {
    param($C)
    $p = Join-Path $C.Backups 'sessoes'
    if (-not (Test-Path -LiteralPath $p)) { return 0 }
    return @(Get-ChildItem -LiteralPath $p -Directory).Count
}

# Escapa um argumento para a linha de comando nativa (aspas e barras antes de aspas), como o -File do powershell.exe espera.
function ConvertTo-ArgNativo {
    param([string]$S)
    return ([regex]::Replace($S, '(\\*)"', '$1$1\"'))
}

function Invoke-Sv {
    param($A, [string]$Arquivo, [string]$Valores, [switch]$Aplicar)
    $args2 = @($A.ArgsComuns) + @('-Arquivo', $Arquivo, '-Valores', (ConvertTo-ArgNativo $Valores))
    if ($Aplicar) { $args2 += '-Aplicar' }
    return (Invoke-ScriptTeste -Script $svScript -Argumentos $args2)
}

$Q = [char]34
$B = [char]92

# Fixture: UTF-8 sem BOM, CRLF, com chaves e aspas escapadas dentro de strings.
$luaLea = @(
    'LeaPlusDB = {',
    '["AutomateQuests"] = "Off",',
    '["FasterLooting"] = "Off",',
    ('["Texto"] = "a } b ' + $B + $Q + ' c { d",'),
    ('["Barra"] = "x' + $B + $B + '",'),
    '["a}b"] = 1,',
    '["Num"] = 5,',
    '["Flag"] = false,',
    '}',
    'RXPSettings = {',
    '["profileKeys"] = {',
    '["Fulano - Reino"] = "Fulano - Reino",',
    '},',
    '["profiles"] = {',
    '["Fulano - Reino"] = {',
    '["xpBarColor"] = "x",',
    '["enableTalentGuides"] = true,',
    '},',
    '["Beltrano - Reino"] = {',
    '["xpBarColor"] = "y",',
    '},',
    '},',
    ('["nome"] = "A' + [char]0x00E7 + 'ao",'),
    '}',
    ''
) -join "`r`n"

function New-AmbienteSv {
    param([string]$Nome)
    $a = New-AmbienteTeste $Nome
    $ctx = Get-Contexto $a
    $dir = Join-Path $ctx.WTF 'Account\CONTA1\SavedVariables'
    $f = Join-Path $dir 'Teste.lua'
    [IO.File]::WriteAllBytes($f, (New-Object System.Text.UTF8Encoding $false).GetBytes($luaLea))
    return [pscustomobject]@{ A = $a; Ctx = $ctx; Dir = $dir; Arq = $f }
}

function Get-TextoArq {
    param([string]$Caminho)
    return [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($Caminho))
}

try {

# ---------------------------------------------------------------- 1. previa
$e = New-AmbienteSv 'sv-previa'
$antes = Get-Base64 $e.Arq
$r = Invoke-Sv $e.A 'Teste.lua' 'LeaPlusDB.AutomateQuests="On";LeaPlusDB.AutoSellJunk=true;LeaPlusDB.Num=7'
Assert-Igual 0 $r.Codigo 'previa: codigo 0'
Assert-Verdade (Tem-LinhaLike $r.Saida ('SV arquivo=Teste.lua caminho=LeaPlusDB.AutomateQuests atual="Off" novo="On"')) 'previa: linha de troca'
Assert-Verdade (Tem-LinhaLike $r.Saida 'SV arquivo=Teste.lua caminho=LeaPlusDB.AutoSellJunk atual=(ausente) novo=true') 'previa: linha de chave ausente'
Assert-Verdade (Tem-LinhaLike $r.Saida 'SV arquivo=Teste.lua caminho=LeaPlusDB.Num atual=5 novo=7') 'previa: linha de numero'
Assert-Igual $antes (Get-Base64 $e.Arq) 'previa: arquivo nao muda'
Assert-Igual 0 (Contar-Sessoes $e.Ctx) 'previa: nao cria backup'
Assert-Igual 0 (Contar-Registro $e.Ctx 'sv') 'previa: sem registro'

# ---------------------------------------------------------------- 2. troca de valor existente
$e = New-AmbienteSv 'sv-troca'
$env:WOWAGENTE_JOGO_ABERTO = '0'
$r = Invoke-Sv $e.A 'Teste.lua' 'LeaPlusDB.AutomateQuests="On"' -Aplicar
Assert-Igual 0 $r.Codigo 'troca: codigo 0'
Assert-Verdade (Tem-LinhaLike $r.Saida 'OK sv arquivo=Teste.lua alteradas=1') 'troca: linha OK'
$esperado = $luaLea.Replace('["AutomateQuests"] = "Off",', '["AutomateQuests"] = "On",')
Assert-Igual ([Convert]::ToBase64String((New-Object System.Text.UTF8Encoding $false).GetBytes($esperado))) (Get-Base64 $e.Arq) 'troca: so a linha mudou (byte a byte)'
Assert-Igual 1 (Contar-Sessoes $e.Ctx) 'troca: backup do WTF feito'
Assert-Igual 1 (Contar-Registro $e.Ctx 'sv') 'troca: registro sv'
Assert-Verdade (Tem-LinhaLike $r.Saida 'BACKUP ok caminho=*') 'troca: linha BACKUP repassada'

# ---------------------------------------------------------------- 3. insercao de chave ausente (antes do } da tabela)
$e = New-AmbienteSv 'sv-insere'
$r = Invoke-Sv $e.A 'Teste.lua' 'LeaPlusDB.AutoSellJunk=true' -Aplicar
Assert-Igual 0 $r.Codigo 'insere: codigo 0'
$esperado = $luaLea.Replace("[`"Flag`"] = false,`r`n}`r`nRXPSettings", "[`"Flag`"] = false,`r`n[`"AutoSellJunk`"] = true,`r`n}`r`nRXPSettings")
Assert-Igual ([Convert]::ToBase64String((New-Object System.Text.UTF8Encoding $false).GetBytes($esperado))) (Get-Base64 $e.Arq) 'insere: linha nova antes do } e o resto igual (byte a byte)'

# ---------------------------------------------------------------- 4. * sobre dois perfis (um troca, outro insere)
$e = New-AmbienteSv 'sv-estrela'
$r = Invoke-Sv $e.A 'Teste.lua' 'RXPSettings.profiles.*.enableTalentGuides=false'
Assert-Igual 0 $r.Codigo 'estrela previa: codigo 0'
Assert-Verdade (Tem-LinhaLike $r.Saida 'SV arquivo=Teste.lua caminho=RXPSettings.profiles.Fulano - Reino.enableTalentGuides atual=true novo=false') 'estrela previa: perfil com a chave'
Assert-Verdade (Tem-LinhaLike $r.Saida 'SV arquivo=Teste.lua caminho=RXPSettings.profiles.Beltrano - Reino.enableTalentGuides atual=(ausente) novo=false') 'estrela previa: perfil sem a chave'
$r = Invoke-Sv $e.A 'Teste.lua' 'RXPSettings.profiles.*.enableTalentGuides=false' -Aplicar
Assert-Igual 0 $r.Codigo 'estrela aplicar: codigo 0'
Assert-Verdade (Tem-LinhaLike $r.Saida 'OK sv arquivo=Teste.lua alteradas=2') 'estrela aplicar: duas alteracoes'
$esperado = $luaLea.Replace('["enableTalentGuides"] = true,', '["enableTalentGuides"] = false,')
$esperado = $esperado.Replace("[`"xpBarColor`"] = `"y`",`r`n},", "[`"xpBarColor`"] = `"y`",`r`n[`"enableTalentGuides`"] = false,`r`n},")
Assert-Igual ([Convert]::ToBase64String((New-Object System.Text.UTF8Encoding $false).GetBytes($esperado))) (Get-Base64 $e.Arq) 'estrela aplicar: resultado esperado (byte a byte)'

# ---------------------------------------------------------------- 5. booleano e numero (varios pares)
$e = New-AmbienteSv 'sv-tipos'
$r = Invoke-Sv $e.A 'Teste.lua' 'LeaPlusDB.Num=12;LeaPlusDB.Flag=true;LeaPlusDB.Dec=-1.5' -Aplicar
Assert-Igual 0 $r.Codigo 'tipos: codigo 0'
$esperado = $luaLea.Replace('["Num"] = 5,', '["Num"] = 12,').Replace('["Flag"] = false,', '["Flag"] = true,')
$esperado = $esperado.Replace("[`"Flag`"] = true,`r`n}", "[`"Flag`"] = true,`r`n[`"Dec`"] = -1.5,`r`n}")
Assert-Igual ([Convert]::ToBase64String((New-Object System.Text.UTF8Encoding $false).GetBytes($esperado))) (Get-Base64 $e.Arq) 'tipos: numero e booleano sem aspas (byte a byte)'

# ---------------------------------------------------------------- 6. strings com } e \" dentro nao enganam o leitor
$e = New-AmbienteSv 'sv-strings'
$r = Invoke-Sv $e.A 'Teste.lua' ('LeaPlusDB.Texto="novo ' + $B + $Q + ' } {";LeaPlusDB.Depois=1;LeaPlusDB.Barra="y"')  -Aplicar
Assert-Igual 0 $r.Codigo 'strings: codigo 0'
$esperado = $luaLea.Replace(('["Texto"] = "a } b ' + $B + $Q + ' c { d",'), ('["Texto"] = "novo ' + $B + $Q + ' } {",'))
$esperado = $esperado.Replace(('["Barra"] = "x' + $B + $B + '",'), '["Barra"] = "y",')
$esperado = $esperado.Replace("[`"Flag`"] = false,`r`n}", "[`"Flag`"] = false,`r`n[`"Depois`"] = 1,`r`n}")
Assert-Igual ([Convert]::ToBase64String((New-Object System.Text.UTF8Encoding $false).GetBytes($esperado))) (Get-Base64 $e.Arq) 'strings: troca e insercao certas apesar de } e \" nas strings'
# a chave com } no nome e uma segunda tabela global continuam acessiveis
$r = Invoke-Sv $e.A 'Teste.lua' 'LeaPlusDB.a}b=2;RXPSettings.nome="B"'
Assert-Verdade (Tem-LinhaLike $r.Saida 'SV arquivo=Teste.lua caminho=LeaPlusDB.a}b atual=1 novo=2') 'strings: chave com } no nome'
Assert-Verdade (Tem-LinhaLike $r.Saida 'SV arquivo=Teste.lua caminho=RXPSettings.nome atual="A*ao" novo="B"') 'strings: valor com acento lido'

# ---------------------------------------------------------------- 7. jogo aberto: RECUSA e nada muda
$e = New-AmbienteSv 'sv-aberto'
$env:WOWAGENTE_JOGO_ABERTO = '1'
$antes = Get-Base64 $e.Arq
$r = Invoke-Sv $e.A 'Teste.lua' 'LeaPlusDB.Num=1' -Aplicar
Assert-Igual 1 $r.Codigo 'jogo aberto: codigo 1'
Assert-Verdade (Tem-LinhaLike $r.Saida 'RECUSA *') 'jogo aberto: linha RECUSA'
Assert-Igual $antes (Get-Base64 $e.Arq) 'jogo aberto: arquivo nao muda'
Assert-Igual 0 (Contar-Sessoes $e.Ctx) 'jogo aberto: sem backup'
Assert-Igual 0 (Contar-Registro $e.Ctx 'sv') 'jogo aberto: sem registro'
$env:WOWAGENTE_JOGO_ABERTO = '0'

# ---------------------------------------------------------------- 8. recusas e pre-requisitos
$e = New-AmbienteSv 'sv-recusas'
$antes = Get-Base64 $e.Arq
$r = Invoke-Sv $e.A 'Inexistente.lua' 'LeaPlusDB.Num=1' -Aplicar
Assert-Igual 2 $r.Codigo 'arquivo inexistente: codigo 2'
Assert-Verdade (Tem-LinhaLike $r.Saida 'PREREQ *') 'arquivo inexistente: linha PREREQ'

$r = Invoke-Sv $e.A 'Teste.lua' 'RXPSettings.profiles.*.naoExiste.x=1' -Aplicar
Assert-Igual 1 $r.Codigo '* intermediario sem caminho: codigo 1'
Assert-Verdade (Tem-LinhaLike $r.Saida 'RECUSA *') '* intermediario sem caminho: linha RECUSA'
$r = Invoke-Sv $e.A 'Teste.lua' 'LeaPlusDB.*.x=1' -Aplicar
Assert-Igual 1 $r.Codigo '* sem tabelas: codigo 1'
Assert-Verdade (Tem-LinhaLike $r.Saida 'RECUSA *') '* sem tabelas: linha RECUSA'
$r = Invoke-Sv $e.A 'Teste.lua' 'Inexistente.x=1' -Aplicar
Assert-Igual 1 $r.Codigo 'tabela global ausente: codigo 1'
$r = Invoke-Sv $e.A 'Teste.lua' 'RXPSettings.profiles=1' -Aplicar
Assert-Igual 1 $r.Codigo 'valor e tabela: codigo 1'
$r = Invoke-Sv $e.A 'Teste.lua' 'LeaPlusDB.Num=1;LeaPlusDB.Nao.x=2' -Aplicar
Assert-Igual 1 $r.Codigo 'segundo par recusado: codigo 1'
Assert-Igual $antes (Get-Base64 $e.Arq) 'recusas: arquivo nunca muda (inclusive o primeiro par valido)'
Assert-Igual 0 (Contar-Sessoes $e.Ctx) 'recusas: sem backup'
$r = Invoke-Sv $e.A 'Teste.lua' 'LeaPlusDB.Num=abc'
Assert-Igual 3 $r.Codigo 'valor invalido: codigo 3'
Assert-Verdade (Tem-LinhaLike $r.Saida 'ERRO *') 'valor invalido: linha ERRO'

# duas contas: PREREQ
$e2 = New-AmbienteSv 'sv-contas'
[void](New-Item -ItemType Directory -Path (Join-Path $e2.Ctx.WTF 'Account\CONTA2\SavedVariables') -Force)
$r = Invoke-Sv $e2.A 'Teste.lua' 'LeaPlusDB.Num=1'
Assert-Igual 2 $r.Codigo 'duas contas: codigo 2'
Assert-Verdade (Tem-LinhaLike $r.Saida 'PREREQ *') 'duas contas: linha PREREQ'

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
