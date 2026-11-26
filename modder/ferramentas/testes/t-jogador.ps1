param([switch]$Manter)
$ErrorActionPreference = 'Stop'
$Aqui = $PSScriptRoot
. (Join-Path $Aqui '_assert.ps1')
. (Join-Path $Aqui '_preparar.ps1')
. (Join-Path $Aqui '..\wow-comum.ps1')

# jogador.ps1 e sessao-abrir.ps1 rodam como processo filho contra um repositório falso em <base>\repo
# ($env:WOWAGENTE_REPO, herdado pelos filhos), com um modelo mínimo em jogadores\_modelo.
$jogadorScript = (Resolve-Path -LiteralPath (Join-Path $Aqui '..\jogador.ps1')).ProviderPath
$sessaoScript = (Resolve-Path -LiteralPath (Join-Path $Aqui '..\sessao-abrir.ps1')).ProviderPath
$utf8 = New-Object System.Text.UTF8Encoding $false

function Tem-Linha {
    param([string]$Saida, [string]$Regex)
    return [bool](@($Saida -split "`n" | Where-Object { $_ -match $Regex }).Count)
}

function Get-MensagemDoErro {
    param([scriptblock]$Bloco)
    try { [void](& $Bloco); return '' } catch { return [string]$_.Exception.Message }
}

try {
    $amb = New-AmbienteTeste -Nome 'jogador'
    $repo = Join-Path $amb.Base 'repo'
    $modelo = Join-Path $repo 'jogadores\_modelo'
    [void](New-Item -ItemType Directory -Path (Join-Path $modelo 'estado\addons') -Force)
    [System.IO.File]::WriteAllText((Join-Path $modelo 'jogador.md'), "# Jogador`r`n", $utf8)
    [System.IO.File]::WriteAllText((Join-Path $modelo 'estado\estado.md'), "- Bootstrap: pendente`r`n", $utf8)
    [System.IO.File]::WriteAllText((Join-Path $modelo 'estado\addons\.gitkeep'), '', $utf8)
    $env:WOWAGENTE_REPO = $repo
    $ativoArq = Join-Path $repo 'jogador-ativo.txt'

    # ------------------------------------------------------------ 1. sem jogador ativo
    $r = Invoke-ScriptTeste -Script $jogadorScript
    Assert-Igual 0 $r.Codigo 'sem jogador: codigo 0'
    Assert-Verdade (Tem-Linha $r.Saida '^JOGADOR ausente$') 'sem jogador: linha JOGADOR ausente'
    Assert-Verdade (Tem-Linha $r.Saida '^JOGADORES disponiveis=\(nenhum\)$') 'sem jogador: nenhum disponivel (o _modelo nao conta)'
    Assert-Verdade ($null -eq (Get-JogadorAtivo)) 'sem jogador: Get-JogadorAtivo devolve $null'
    Assert-Verdade ($null -eq (Get-InstalacaoPadrao)) 'sem jogador: Get-InstalacaoPadrao devolve $null'

    $r = Invoke-ScriptTeste -Script $sessaoScript -Argumentos @('-Raiz', $amb.Raiz, '-Flavor', $amb.Flavor, '-Backups', $amb.Backups)
    Assert-Igual 2 $r.Codigo 'sessao sem jogador: codigo 2'
    Assert-Verdade (Tem-Linha $r.Saida '^JOGADOR ausente motivo=sem-jogador-ativo') 'sessao sem jogador: linha JOGADOR ausente'
    $msg = Get-MensagemDoErro { Get-WowContexto -Raiz $amb.Raiz -Flavor $amb.Flavor -Backups $amb.Backups }
    Assert-Verdade ($msg -like 'PREREQ: Nenhum jogador ativo*') 'Get-WowContexto sem jogador e sem -Estado: PREREQ'
    $msg = Get-MensagemDoErro { Set-WowInstalacao -Raiz $amb.Raiz -Flavor $amb.Flavor }
    Assert-Verdade ($msg -like 'PREREQ: Nenhum jogador ativo*') 'Set-WowInstalacao sem jogador e sem -Instalacao: PREREQ'

    # ------------------------------------------------------------ 2. apelido invalido e previa
    $r = Invoke-ScriptTeste -Script $jogadorScript -Argumentos @('-Novo', 'a b')
    Assert-Igual 1 $r.Codigo 'apelido invalido: codigo 1'
    Assert-Verdade (Tem-Linha $r.Saida '^RECUSA Apelido') 'apelido invalido: linha RECUSA'
    $r = Invoke-ScriptTeste -Script $jogadorScript -Argumentos @('-Novo', 'ana', '-Ativar', 'ana')
    Assert-Igual 1 $r.Codigo 'novo e ativar juntos: codigo 1'

    $r = Invoke-ScriptTeste -Script $jogadorScript -Argumentos @('-Novo', 'Ana')
    Assert-Igual 0 $r.Codigo 'novo previa: codigo 0'
    Assert-Verdade (Tem-Linha $r.Saida '^PREVIA criar=jogadores\\ana arquivos=3 ativo=ana antes=\(nenhum\)$') 'novo previa: linha PREVIA (apelido em minusculas)'
    Assert-Verdade (Tem-Linha $r.Saida '^ARQUIVO jogadores\\ana\\estado\\estado\.md$') 'novo previa: lista os arquivos do modelo'
    Assert-Verdade (-not (Test-Path -LiteralPath (Join-Path $repo 'jogadores\ana'))) 'novo previa: pasta nao criada'
    Assert-Verdade (-not (Test-Path -LiteralPath $ativoArq)) 'novo previa: jogador-ativo.txt nao criado'

    # ------------------------------------------------------------ 3. -Novo -Aplicar
    $r = Invoke-ScriptTeste -Script $jogadorScript -Argumentos @('-Novo', 'Ana', '-Aplicar')
    Assert-Igual 0 $r.Codigo 'novo: codigo 0'
    Assert-Verdade (Tem-Linha $r.Saida '^CRIADO jogador=ana ') 'novo: linha CRIADO'
    Assert-Verdade (Tem-Linha $r.Saida '^ATIVO jogador=ana antes=\(nenhum\)$') 'novo: linha ATIVO'
    Assert-Verdade (Test-Path -LiteralPath (Join-Path $repo 'jogadores\ana\estado\estado.md') -PathType Leaf) 'novo: estado.md copiado do modelo'
    $j = Get-JogadorAtivo
    Assert-Igual 'ana' $j.Apelido 'novo: Get-JogadorAtivo apelido'
    Assert-Igual (Join-Path $repo 'jogadores\ana') $j.Pasta 'novo: Get-JogadorAtivo pasta'
    $reg = [System.IO.File]::ReadAllText((Join-Path $repo 'jogadores\ana\estado\registro.md'), [Text.Encoding]::UTF8)
    Assert-Verdade ($reg -match '\| jogador-novo \| ana \|') 'novo: registro com jogador-novo'
    $r = Invoke-ScriptTeste -Script $jogadorScript -Argumentos @('-Novo', 'ana', '-Aplicar')
    Assert-Igual 1 $r.Codigo 'novo repetido: codigo 1'

    # ------------------------------------------------------------ 4. padroes pela pasta do jogador ativo
    $ctx = Get-WowContexto -Raiz $amb.Raiz -Flavor $amb.Flavor -Backups $amb.Backups
    Assert-Igual (Join-Path $repo 'jogadores\ana\estado') $ctx.Estado 'padrao: Estado na pasta do jogador'
    Assert-Igual (Join-Path $repo 'jogadores\ana\instalacao.json') (Get-InstalacaoPadrao) 'padrao: instalacao.json na pasta do jogador'
    $msg = Get-MensagemDoErro { Get-WowContexto -Backups $amb.Backups }
    Assert-Verdade ($msg -like 'PREREQ: Instala*') 'padrao: sem instalacao.json do jogador, PREREQ de instalacao'
    Set-WowInstalacao -Raiz $amb.Raiz -Flavor $amb.Flavor
    Assert-Verdade (Test-Path -LiteralPath (Join-Path $repo 'jogadores\ana\instalacao.json') -PathType Leaf) 'padrao: Set-WowInstalacao grava na pasta do jogador'
    $ctx = Get-WowContexto -Backups $amb.Backups
    Assert-Igual $amb.Raiz $ctx.Raiz 'padrao: Get-WowContexto le a raiz do instalacao.json do jogador'

    $env:WOWAGENTE_JOGO_ABERTO = '1'
    $r = Invoke-ScriptTeste -Script $sessaoScript -Argumentos @('-Backups', $amb.Backups)
    Remove-Item -LiteralPath 'Env:\WOWAGENTE_JOGO_ABERTO' -ErrorAction SilentlyContinue
    Assert-Verdade (Tem-Linha $r.Saida '^JOGADOR ativo=ana ') 'sessao com jogador: linha JOGADOR ativo'
    Assert-Verdade (Tem-Linha $r.Saida '^INSTALACAO ok ') 'sessao com jogador: INSTALACAO ok pelo instalacao.json do jogador'
    Assert-Verdade (Test-Path -LiteralPath (Join-Path $repo 'jogadores\ana\estado\sessao.json') -PathType Leaf) 'sessao com jogador: sessao.json na pasta do jogador'

    # ------------------------------------------------------------ 5. -Ativar
    $r = Invoke-ScriptTeste -Script $jogadorScript -Argumentos @('-Ativar', 'beto')
    Assert-Igual 1 $r.Codigo 'ativar inexistente: codigo 1'
    [void](Invoke-ScriptTeste -Script $jogadorScript -Argumentos @('-Novo', 'beto', '-Aplicar'))
    Assert-Igual 'beto' (Get-JogadorAtivo).Apelido 'segundo jogador: beto fica ativo'
    $r = Invoke-ScriptTeste -Script $jogadorScript -Argumentos @('-Ativar', 'ana')
    Assert-Verdade (Tem-Linha $r.Saida '^PREVIA ativo=ana antes=beto$') 'ativar previa: linha PREVIA'
    Assert-Igual 'beto' (Get-JogadorAtivo).Apelido 'ativar previa: nada muda'
    $r = Invoke-ScriptTeste -Script $jogadorScript -Argumentos @('-Ativar', 'ana', '-Aplicar')
    Assert-Igual 0 $r.Codigo 'ativar: codigo 0'
    Assert-Verdade (Tem-Linha $r.Saida '^ATIVO jogador=ana antes=beto$') 'ativar: linha ATIVO'
    Assert-Igual 'ana' (Get-JogadorAtivo).Apelido 'ativar: ana ativa'
    $r = Invoke-ScriptTeste -Script $jogadorScript -Argumentos @('-Ativar', 'ana', '-Aplicar')
    Assert-Verdade (Tem-Linha $r.Saida '^NADA jogador=ana motivo=ja-ativo$') 'ativar de novo: linha NADA'
    $r = Invoke-ScriptTeste -Script $jogadorScript
    Assert-Verdade (Tem-Linha $r.Saida '^JOGADORES disponiveis=ana,beto$') 'listar: dois disponiveis, sem o _modelo'

    # ------------------------------------------------------------ 6. caminho completo no jogador-ativo.txt
    $fora = Join-Path $amb.Base 'fora\carla'
    [void](New-Item -ItemType Directory -Path $fora -Force)
    [System.IO.File]::WriteAllText($ativoArq, "# comentario`r`n`r`n$fora`r`n", $utf8)
    $j = Get-JogadorAtivo
    Assert-Igual 'carla' $j.Apelido 'caminho completo: o apelido e o nome da pasta'
    Assert-Igual $fora $j.Pasta 'caminho completo: a pasta e a do arquivo'
}
finally {
    if (-not $Manter) { Remove-AmbientesTeste }
    Remove-Item -LiteralPath 'Env:\WOWAGENTE_REPO' -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath 'Env:\WOWAGENTE_JOGO_ABERTO' -ErrorAction SilentlyContinue
}

$res = Get-Resultado
if ($res.Falhas.Count -gt 0) {
    foreach ($f in $res.Falhas) { Write-Output "FALHOU: $f" }
    exit 1
}
Write-Output "OK $($res.Total) verificacoes"
exit 0
