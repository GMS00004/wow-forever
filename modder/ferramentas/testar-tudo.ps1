# Roda todas as checagens que não dependem do jogo (contrato §11): as suítes de PowerShell, os checadores e as
# bancadas dos addons em Node e os testes das ferramentas de preço. É o mesmo comando do CI.
# Uso: testar-tudo.ps1 [-Rapido] [-So powershell|node]
#   -Rapido  pula a matriz das incógnitas do CentralForever (rodar-central.mjs --matriz, uns dois minutos)
#   -So      roda só um dos dois grupos
# Precisa do Node 20 ou mais novo e de "npm ci" em ferramentas\guia. As checagens que leem a lista da API do Forever
# rodam se ferramentas\guia\api-forever existir (node ferramentas\guia\baixar-api-forever.mjs); as que precisam de
# dados baixados do jogo (modder\dados) rodam se o arquivo de que precisam existir. As outras saem como PULADO, com
# o motivo. Achado conhecido, com issue aberta, sai como CONHECIDO e não reprova. Uma checagem usa rede: o
# pregao-tendencia baixa a tabela ItemSparse do wago.tools na primeira vez e guarda em modder\dados\pregao\cache.
# Saída: uma linha por checagem (OK, FALHA, PULADO ou CONHECIDO) e o resumo
# "TESTES ok=<n> falhas=<n> pulados=<n> conhecidos=<n>". Código: 0 sem falha, 1 com falha, 2 sem Node ou sem npm ci.
param(
    [switch]$Rapido,
    [ValidateSet('', 'powershell', 'node')][string]$So = ''
)
$ErrorActionPreference = 'Stop'
$Ferramentas = $PSScriptRoot
$Modder = Split-Path -Parent $Ferramentas
$Guia = Join-Path $Ferramentas 'guia'
$Pregao = Join-Path $Ferramentas 'pregao'
$Api = Join-Path $Guia 'api-forever'
$Dados = Join-Path $Modder 'dados\pregao'
$contagem = @{ ok = 0; falhas = 0; pulados = 0; conhecidos = 0 }

function New-Checagem {
    param([string]$Nome, [string]$Pasta, [string[]]$Argumentos, [string]$Precisa = '', [string]$Conhecido = '')
    return [pscustomobject]@{ Nome = $Nome; Pasta = $Pasta; Argumentos = $Argumentos; Precisa = $Precisa; Conhecido = $Conhecido }
}

function Invoke-Checagem {
    param([string]$Nome, [string]$Pasta, [string]$Exe, [string[]]$Argumentos, [string]$Conhecido = '')
    $antes = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $inicio = Get-Date
    Push-Location -LiteralPath $Pasta
    try {
        $saida = & $Exe @Argumentos 2>&1
        $codigo = $LASTEXITCODE
    } finally {
        Pop-Location
        $ErrorActionPreference = $antes
    }
    $seg = [int][Math]::Round(((Get-Date) - $inicio).TotalSeconds)
    $linhas = @($saida | ForEach-Object { ([string]$_).TrimEnd() } | Where-Object { $_ -match '\S' })
    $ultima = ''
    if ($linhas.Count -gt 0) { $ultima = $linhas[$linhas.Count - 1] }
    if ($ultima.Length -gt 110) { $ultima = $ultima.Substring(0, 110) + '...' }
    if ($codigo -eq 0) {
        $contagem.ok++
        $extra = ''
        if ($Conhecido) { $extra = ' (o achado conhecido sumiu: tire a marca no testar-tudo.ps1)' }
        Write-Host ('OK        {0,-24} {1,4}s  {2}{3}' -f $Nome, $seg, $ultima, $extra)
    } elseif ($Conhecido) {
        $contagem.conhecidos++
        Write-Host ('CONHECIDO {0,-24} {1,4}s  {2}' -f $Nome, $seg, $Conhecido)
    } else {
        $contagem.falhas++
        Write-Host ('FALHA     {0,-24} {1,4}s  {2}' -f $Nome, $seg, $ultima)
        foreach ($l in @($linhas | Where-Object { $_ -match '^FALHA|FALHOU|ERRO|Error' } | Select-Object -First 12)) { Write-Host "          $l" }
    }
}

function Skip-Checagem {
    param([string]$Nome, [string]$Motivo)
    $contagem.pulados++
    Write-Host ('PULADO    {0,-24}        {1}' -f $Nome, $Motivo)
}

# ------------------------------------------------------------ suítes de PowerShell (Windows PowerShell 5.1)
if ($So -ne 'node') {
    $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    foreach ($t in @(Get-ChildItem -LiteralPath (Join-Path $Ferramentas 'testes') -Filter 't-*.ps1' | Sort-Object Name)) {
        Invoke-Checagem -Nome $t.BaseName -Pasta $Ferramentas -Exe $ps -Argumentos @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $t.FullName)
    }
}

# ------------------------------------------------------------ checadores, bancadas e ferramentas em Node
if ($So -ne 'powershell') {
    $node = Get-Command node -ErrorAction SilentlyContinue
    if (-not $node) { Write-Host 'PREREQ Node não encontrado: instale o Node 20 ou mais novo (https://nodejs.org)'; exit 2 }
    if (-not (Test-Path -LiteralPath (Join-Path $Guia 'node_modules\luaparse'))) {
        Write-Host 'PREREQ dependências do Node ausentes: rode "npm ci" em modder\ferramentas\guia'
        exit 2
    }
    $A = '..\..\addons-proprios'
    $lista = @(
        (New-Checagem 'lua-GuiaForever' $Guia @('checar-lua.mjs', "$A\GuiaForever", '--globais')),
        (New-Checagem 'lua-CentralForever' $Guia @('checar-lua.mjs', "$A\CentralForever")),
        (New-Checagem 'lua-CompraForever' $Guia @('checar-lua.mjs', "$A\CompraForever")),
        (New-Checagem 'lua-UIForever' $Guia @('checar-lua.mjs', "$A\UIForever")),
        (New-Checagem 'lua-PregaoForever' $Guia @('checar-lua.mjs', "$A\PregaoForever")),
        (New-Checagem 'lua-KitAmigo' $Guia @('checar-lua.mjs', "$A\!KitAmigo")),
        (New-Checagem 'lua-Modelo' $Guia @('checar-lua.mjs', "$A\_modelo\Modelo")),
        (New-Checagem 'dicas-GuiaForever' $Guia @('checar-dicas.mjs', "$A\GuiaForever\Dicas.lua")),
        (New-Checagem 'ajuda-GuiaForever' $Guia @('checar-ajuda.mjs', "$A\GuiaForever\Ajuda.lua")),
        (New-Checagem 'combate-GuiaForever' $Guia @('checar-combate.mjs', "$A\GuiaForever", '--toc') 'api' 'R1 em GuiaForever.lua:331: CreateMacro por pcall, com a guarda de combate em quem chama (issue #6)'),
        (New-Checagem 'combate-CentralForever' $Guia @('checar-combate.mjs', "$A\CentralForever", '--toc', '--perfil', 'central') 'api'),
        (New-Checagem 'combate-PregaoForever' $Guia @('checar-combate.mjs', "$A\PregaoForever", '--toc', '--prefixos', 'PregaoForever,SLASH_PREGAOFOREVER,BINDING_') 'api'),
        (New-Checagem 'casos-checar-lua' $Guia @('rodar-casos.mjs')),
        (New-Checagem 'casos-combate' $Guia @('rodar-casos-combate.mjs') 'api'),
        (New-Checagem 'casos-segredo' $Guia @('rodar-casos-segredo.mjs')),
        (New-Checagem 'bancada-central' $Guia @('rodar-central.mjs') 'api'),
        (New-Checagem 'bancada-central-matriz' $Guia @('rodar-central.mjs', '--matriz') 'api'),
        (New-Checagem 'bancada-central-auto' $Guia @('rodar-central.mjs', '--autoteste') 'api'),
        (New-Checagem 'doc-blizzard' $Guia @('conferir-doc.mjs') 'doc'),
        (New-Checagem 'janela-GuiaForever' $Guia @('rodar-janela.mjs', '--estrito', '--abrir', '--desenhar')),
        (New-Checagem 'casos-pregao' $Guia @('pregao\rodar-casos-pregao.mjs')),
        (New-Checagem 'bancada-pregao-auto' $Guia @('pregao\bancada-pregao.mjs', '--auto-teste')),
        (New-Checagem 'checar-PregaoForever' $Guia @('pregao\checar-pregao.mjs', "$A\PregaoForever")),
        (New-Checagem 'bancada-compra' $Modder @('ferramentas\guia\pregao\bancada-pregao.mjs', '--addon', 'addons-proprios\CompraForever', '--cenarios', 'compra')),
        (New-Checagem 'bancada-compra-rota' $Modder @('ferramentas\guia\pregao\bancada-pregao.mjs', '--addon', 'addons-proprios\CompraForever', '--cenarios', 'rota')),
        (New-Checagem 'planejador-compra' $Modder @('ferramentas\compra\testar-planejador.mjs')),
        (New-Checagem 'dados-CompraForever' $Modder @('ferramentas\compra\checar-dados.mjs')),
        (New-Checagem 'pregao-rota' $Pregao @('testes\testar-rota.mjs')),
        (New-Checagem 'pregao-padroes' $Pregao @('testes\testar-padroes.mjs')),
        (New-Checagem 'pregao-tendencia' $Pregao @('testes\testar-tendencia.mjs')),
        (New-Checagem 'pregao-crafts' $Pregao @('testes\testar-crafts.mjs')),
        (New-Checagem 'pregao-legado' $Pregao @('testes\testar-legado.mjs')),
        (New-Checagem 'dados-pregao' $Guia @('pregao\checar-dados-pregao.mjs') 'dados:precos.json'),
        (New-Checagem 'rota-compra' $Modder @('ferramentas\compra\testar-rota.mjs') 'dados:receitas-engineering.json'),
        (New-Checagem 'pregao-coletor' $Pregao @('testes\testar-coletor.mjs') 'dados:publico\index.txt'),
        (New-Checagem 'pregao-precos' $Pregao @('testes\checar-precos.mjs') 'dados:precos.json'),
        (New-Checagem 'pregao-receitas' $Pregao @('testes\checar-receitas.mjs') 'dados:receitas-lw.json')
    )
    foreach ($c in $lista) {
        if ($Rapido -and $c.Nome -eq 'bancada-central-matriz') { Skip-Checagem $c.Nome 'pulada com -Rapido'; continue }
        if ($c.Precisa -eq 'api' -and -not (Test-Path -LiteralPath (Join-Path $Api 'GlobalAPI.lua'))) {
            Skip-Checagem $c.Nome 'sem a lista da API (rode node baixar-api-forever.mjs em ferramentas\guia)'; continue
        }
        if ($c.Precisa -eq 'doc' -and -not (Test-Path -LiteralPath (Join-Path $Api 'doc\DamageMeterDocumentation.lua'))) {
            Skip-Checagem $c.Nome 'sem a documentação da API (rode node baixar-api-forever.mjs em ferramentas\guia)'; continue
        }
        if ($c.Precisa -like 'dados:*') {
            $arq = Join-Path $Dados $c.Precisa.Substring(6)
            if (-not (Test-Path -LiteralPath $arq)) { Skip-Checagem $c.Nome ('sem dados baixados do jogo (falta modder\dados\pregao\' + $c.Precisa.Substring(6) + ')'); continue }
        }
        Invoke-Checagem -Nome $c.Nome -Pasta $c.Pasta -Exe $node.Source -Argumentos $c.Argumentos -Conhecido $c.Conhecido
    }
}

Write-Host ''
Write-Host ('TESTES ok={0} falhas={1} pulados={2} conhecidos={3}' -f $contagem.ok, $contagem.falhas, $contagem.pulados, $contagem.conhecidos)
if ($contagem.falhas -gt 0) { exit 1 }
exit 0
