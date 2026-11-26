# Biblioteca comum do wow-modder (gerenciador de addons do WoW Forever). Contrato: CONTRATO.md (v1.2).
# Uso: . (Join-Path $PSScriptRoot 'wow-comum.ps1')   -- so define funcoes e faz o Add-Type do zip.
# Windows PowerShell 5.1. Salvar em UTF-8 com BOM.
#
# Decisoes onde o contrato nao bastou (ver relatorio da T4):
#  - Get-TocDoForever.Arquivo e o caminho completo; Test-AddonForever.Toc e so o nome do arquivo (para as linhas toc=<n>).
#  - Get-HashPasta: o texto e uma linha "<rel>|<bytes>|<sha256>" por arquivo, cada uma terminada em LF,
#    ordenadas pelo caminho relativo (ordinal).
#  - Backup-Wtf zipa com WTF como pasta de topo do zip (Backup-Pastas); info.txt fica ao lado do zip.
#  - Install-AddonDeFonte para 'zip:': a versao e a "## Version" do TOC da primeira pasta, ou 'zip-<8 hex do sha256 do zip>'.
#  - -Forcar so passa pela incompatibilidade de TOC; conflito de pasta com outro manifesto e sempre RECUSA.
#  - Listas (Find-WowInstalacao, Find-PastasDeAddon, Get-Manifestos) saem DESENROLADAS (sem ',@'): em 5.1, @(f) sobre 'return ,@(..)'
#    aninha a lista (Count 1 mesmo vazia). Quem chama envolve com @(...), como manda o contrato.
#  - Os fluxos imprimem com Write-Host (os testes capturam com 6>&1); Invoke-ScriptWow imprime os textos que o bloco devolver.

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$script:WowFerramentas = $PSScriptRoot

# ------------------------------------------------------------------ erros

function Stop-Wow {
    param([Parameter(Mandatory)][string]$Tipo, [Parameter(Mandatory)][string]$Mensagem)
    throw "${Tipo}: $Mensagem"
}

function Invoke-ScriptWow {
    param([Parameter(Mandatory)][scriptblock]$Bloco)
    $codigo = 0
    try {
        $saida = @(& $Bloco)
        foreach ($item in $saida) {
            if ($item -is [int]) { $codigo = $item }
            elseif ($item -is [string]) { Write-Host $item }
        }
    }
    catch {
        $msg = [string]$_.Exception.Message
        if ($msg -match '^(?s)PREREQ: (.*)$') { Write-Host ("PREREQ " + $Matches[1]); return 2 }
        if ($msg -match '^(?s)RECUSA: (.*)$') { Write-Host ("RECUSA " + $Matches[1]); return 1 }
        if ($msg -match '^(?s)ERRO: (.*)$') { $msg = $Matches[1] }
        Write-Host ("ERRO " + $msg)
        return 3
    }
    return $codigo
}

function Write-Linha {
    param([string]$Texto)
    Write-Host $Texto
}

function Get-AgoraIso { (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz') }

# ------------------------------------------------------------------ texto preservando codificacao
# Copiadas de C:\Users\PC-AVELL\.claude\skills\tuning-grafico\scripts\lib-comum.ps1 (linhas ~65 a 116); nao ha dot-source.

# Le um arquivo de texto detectando a codificacao pelo BOM (UTF-8, UTF-16 LE/BE).
# Sem BOM: tenta UTF-8 estrito e cai para ANSI se houver byte invalido.
# Devolve linhas, codificacao, se havia BOM, quebra de linha e se terminava com quebra,
# para que a escrita devolva o arquivo byte a byte igual fora das linhas alteradas.
function Read-TextoPreservando {
    param([Parameter(Mandatory)][string]$Path)
    $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).ProviderPath)
    $enc = $null; $bom = $false; $offset = 0
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $enc = New-Object Text.UTF8Encoding($true); $bom = $true; $offset = 3
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $enc = New-Object Text.UnicodeEncoding($false, $true); $bom = $true; $offset = 2
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $enc = New-Object Text.UnicodeEncoding($true, $true); $bom = $true; $offset = 2
    } else {
        try {
            $estrito = New-Object Text.UTF8Encoding($false, $true)
            [void]$estrito.GetString($bytes)
            $enc = New-Object Text.UTF8Encoding($false)
        } catch {
            $enc = [Text.Encoding]::Default
        }
    }
    $texto = $enc.GetString($bytes, $offset, $bytes.Length - $offset)
    $quebra = if ($texto.Contains("`r`n")) { "`r`n" } else { "`n" }
    $finalComQuebra = $texto.EndsWith("`n")
    $corpo = if ($finalComQuebra) { $texto.Substring(0, $texto.Length - $quebra.Length) } else { $texto }
    if ($texto.Length -eq 0) { $linhas = @() } else { $linhas = $corpo -split "`r?`n" }
    return [pscustomobject]@{
        Linhas         = [string[]]$linhas
        Encoding       = $enc
        Bom            = $bom
        Quebra         = $quebra
        FinalComQuebra = $finalComQuebra
    }
}

function Write-TextoPreservando {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)]$Arquivo)
    $texto = ($Arquivo.Linhas -join $Arquivo.Quebra)
    if ($Arquivo.FinalComQuebra) { $texto += $Arquivo.Quebra }
    $corpo = $Arquivo.Encoding.GetBytes($texto)
    # Nao use "$pre = if (...) { ... } else { [byte[]]@() }": array vazio saindo de um if vira $null.
    [byte[]]$pre = New-Object byte[] 0
    if ($Arquivo.Bom) { $pre = $Arquivo.Encoding.GetPreamble() }
    $saida = New-Object byte[] ($pre.Length + $corpo.Length)
    [Array]::Copy($pre, 0, $saida, 0, $pre.Length)
    [Array]::Copy($corpo, 0, $saida, $pre.Length, $corpo.Length)
    [IO.File]::WriteAllBytes((Resolve-Path -LiteralPath $Path).ProviderPath, $saida)
}

# ------------------------------------------------------------------ json

function Write-JsonUtf8 {
    param([Parameter(Mandatory)]$Objeto, [Parameter(Mandatory)][string]$Caminho)
    $dir = [IO.Path]::GetDirectoryName($Caminho)
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
    [System.IO.File]::WriteAllText($Caminho, ($Objeto | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding $false))
}

function Read-JsonUtf8 {
    param([Parameter(Mandatory)][string]$Caminho)
    Get-Content -LiteralPath $Caminho -Raw -Encoding UTF8 | ConvertFrom-Json
}

# ------------------------------------------------------------------ versao e instalacao

function ConvertTo-WowInterface {
    param([Parameter(Mandatory)][string]$Versao)
    $p = @($Versao.Trim().Split('.'))
    $n = @(0, 0, 0)
    for ($i = 0; $i -lt 3; $i++) {
        if ($i -lt $p.Count) {
            $v = 0
            if ([int]::TryParse(($p[$i] -replace '\D.*$', ''), [ref]$v)) { $n[$i] = $v }
        }
    }
    return [int]($n[0] * 10000 + $n[1] * 100 + $n[2])
}

function ConvertTo-WowVersaoCurta {
    param([Parameter(Mandatory)][string]$Versao)
    $p = @($Versao.Trim().Split('.'))
    $n = @('0', '0', '0')
    for ($i = 0; $i -lt 3; $i++) {
        if ($i -lt $p.Count -and $p[$i] -match '^\d+') { $n[$i] = [string][int]$Matches[0] }
    }
    return ($n -join '.')
}

function Get-WowVersao {
    param([Parameter(Mandatory)][string]$Raiz, [Parameter(Mandatory)][string]$Flavor)
    $info = Join-Path (Join-Path $Raiz $Flavor) '.flavor.info'
    $build = Join-Path $Raiz '.build.info'
    if (-not (Test-Path -LiteralPath $build -PathType Leaf)) { return $null }

    $produto = $null
    if (Test-Path -LiteralPath $info -PathType Leaf) {
        $ls = @(Get-Content -LiteralPath $info -Encoding UTF8 | Where-Object { $_ -and $_.Trim() })
        if ($ls.Count -ge 2) { $produto = $ls[1].Trim() }
    }

    $linhas = @(Get-Content -LiteralPath $build -Encoding UTF8 | Where-Object { $_ -and $_.Trim() })
    if ($linhas.Count -lt 2) { return $null }
    $cab = @($linhas[0].Split('|') | ForEach-Object { ($_ -split '!')[0].Trim() })
    $iV = [array]::IndexOf($cab, 'Version')
    $iP = [array]::IndexOf($cab, 'Product')
    $iA = [array]::IndexOf($cab, 'Active')
    if ($iV -lt 0 -or $iP -lt 0) { return $null }

    $rows = @()
    for ($i = 1; $i -lt $linhas.Count; $i++) {
        $c = @($linhas[$i].Split('|'))
        if ($c.Count -le [Math]::Max($iV, $iP)) { continue }
        $ativo = $true
        if ($iA -ge 0 -and $c.Count -gt $iA) { $ativo = ($c[$iA].Trim() -eq '1') }
        $rows += [pscustomobject]@{ Versao = $c[$iV].Trim(); Produto = $c[$iP].Trim(); Ativo = $ativo }
    }

    $achado = $null
    if ($produto) { $achado = @($rows | Where-Object { $_.Produto -eq $produto }) | Select-Object -First 1 }
    if (-not $achado) {
        # "wowf" é o código real do produto do Forever (lido no Avell em 2026-11-03)
        $achado = @($rows | Where-Object { $_.Ativo -and $_.Produto -match 'forever|camelot|^wowf$' }) | Select-Object -First 1
    }
    if (-not $achado) { return $null }
    return [pscustomobject]@{
        Produto   = $achado.Produto
        Versao    = $achado.Versao
        Interface = (ConvertTo-WowInterface $achado.Versao)
    }
}

# ------------------------------------------------------------------ jogador ativo (contrato §3 e §7)
# Raiz do repositório: <ferramentas>\..\.. (nos testes, $env:WOWAGENTE_REPO).
function Get-RaizRepo {
    if ($env:WOWAGENTE_REPO) { return [IO.Path]::GetFullPath($env:WOWAGENTE_REPO) }
    return [IO.Path]::GetFullPath((Join-Path $script:WowFerramentas '..\..'))
}

# Jogador ativo deste PC: a primeira linha útil de <repo>\jogador-ativo.txt (fora do git), que é o apelido
# de uma pasta em <repo>\jogadores\ ou um caminho completo. Devolve {Apelido; Pasta} ou $null.
function Get-JogadorAtivo {
    $arq = Join-Path (Get-RaizRepo) 'jogador-ativo.txt'
    if (-not (Test-Path -LiteralPath $arq -PathType Leaf)) { return $null }
    $linha = @([System.IO.File]::ReadAllLines($arq) | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') }) | Select-Object -First 1
    if (-not $linha) { return $null }
    if ([IO.Path]::IsPathRooted($linha)) {
        $pasta = [IO.Path]::GetFullPath($linha)
        $apelido = Split-Path -Leaf $pasta
    } else {
        $apelido = $linha
        $pasta = Join-Path (Join-Path (Get-RaizRepo) 'jogadores') $linha
    }
    return [pscustomobject]@{ Apelido = $apelido; Pasta = $pasta }
}

function Get-MensagemSemJogador {
    'Nenhum jogador ativo neste PC: crie a sua pasta com ferramentas\jogador.ps1 -Novo <apelido> -Aplicar (ou ative uma que já existe com -Ativar <apelido>)'
}

# Padrão do -Instalacao: <pasta do jogador ativo>\instalacao.json, ou $null sem jogador ativo.
function Get-InstalacaoPadrao {
    $j = Get-JogadorAtivo
    if (-not $j) { return $null }
    return (Join-Path $j.Pasta 'instalacao.json')
}

function ConvertTo-CaminhoNormal {
    # junta separadores repetidos ("C:\\Program Files", vindo do Battle.net.config) e tira a barra final
    param([string]$Caminho)
    $p = ([string]$Caminho).Trim()
    if (-not $p) { return '' }
    try { $p = [IO.Path]::GetFullPath($p) } catch { }
    return $p.TrimEnd('\')
}

function Find-WowInstalacao {
    $cands = New-Object System.Collections.ArrayList

    foreach ($chave in @('HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                         'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                         'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
        try {
            foreach ($e in @(Get-ItemProperty -Path $chave -ErrorAction SilentlyContinue)) {
                $dn = [string]$e.DisplayName
                $il = [string]$e.InstallLocation
                if ($dn -match 'World of Warcraft' -and $il) { [void]$cands.Add(@($il, 'registro')) }
            }
        } catch { }
    }

    if ($env:APPDATA) {
        $cfg = Join-Path $env:APPDATA 'Battle.net\Battle.net.config'
        if (Test-Path -LiteralPath $cfg -PathType Leaf) {
            try {
                $txt = [IO.File]::ReadAllText($cfg)
                if ($txt -match '"DefaultInstallPath"\s*:\s*"([^"]+)"') {
                    $p = ($Matches[1] -replace '\\\\', '\').Replace('/', '\').TrimEnd('\')
                    [void]$cands.Add(@((Join-Path $p 'World of Warcraft'), 'battlenet'))
                }
            } catch { }
        }
    }

    foreach ($p in @('C:\Program Files (x86)\World of Warcraft', 'C:\Program Files\World of Warcraft',
                     'D:\World of Warcraft', 'D:\Games\World of Warcraft')) {
        [void]$cands.Add(@($p, 'caminho-comum'))
    }

    $vistos = @{}
    $saida = New-Object System.Collections.ArrayList
    foreach ($c in $cands) {
        $raiz = ConvertTo-CaminhoNormal ([string]$c[0])
        if (-not $raiz) { continue }
        $k = $raiz.ToLowerInvariant()
        if ($vistos.ContainsKey($k)) { continue }
        $vistos[$k] = $true
        if (-not (Test-Path -LiteralPath $raiz -PathType Container)) { continue }
        $flavors = New-Object System.Collections.ArrayList
        foreach ($d in @(Get-ChildItem -LiteralPath $raiz -Directory -ErrorAction SilentlyContinue)) {
            $fi = Join-Path $d.FullName '.flavor.info'
            if (-not (Test-Path -LiteralPath $fi -PathType Leaf)) { continue }
            $v = Get-WowVersao -Raiz $raiz -Flavor $d.Name
            $prod = $null; $ver = $null; $int = $null
            if ($v) { $prod = $v.Produto; $ver = $v.Versao; $int = $v.Interface }
            [void]$flavors.Add([pscustomobject]@{ Nome = $d.Name; Produto = $prod; Versao = $ver; Interface = $int })
        }
        [void]$saida.Add([pscustomobject]@{ Raiz = $raiz; Origem = [string]$c[1]; Flavors = $flavors.ToArray() })
    }
    return $saida.ToArray()
}

function Set-WowInstalacao {
    param([Parameter(Mandatory)][string]$Raiz, [Parameter(Mandatory)][string]$Flavor, [string]$Instalacao)
    if (-not $Instalacao) { $Instalacao = Get-InstalacaoPadrao }
    if (-not $Instalacao) { Stop-Wow PREREQ (Get-MensagemSemJogador) }
    $obj = [ordered]@{
        v            = 1
        raiz         = $Raiz
        flavor       = $Flavor
        maquina      = $env:COMPUTERNAME
        confirmadoEm = (Get-AgoraIso)
    }
    Write-JsonUtf8 -Objeto $obj -Caminho $Instalacao
}

function Get-WowContexto {
    param([string]$Raiz, [string]$Flavor, [string]$Instalacao, [string]$Estado, [string]$Backups)
    # O que não veio por parâmetro sai da pasta do jogador ativo (jogadores\<apelido>\).
    $jog = $null
    if (-not $Instalacao -or -not $Estado) { $jog = Get-JogadorAtivo }
    if (-not $Instalacao -and $jog) { $Instalacao = Join-Path $jog.Pasta 'instalacao.json' }
    if (-not $Estado) {
        if (-not $jog) { Stop-Wow PREREQ (Get-MensagemSemJogador) }
        if (-not (Test-Path -LiteralPath $jog.Pasta -PathType Container)) {
            Stop-Wow PREREQ "Pasta do jogador ativo inexistente: $($jog.Pasta) (confira o jogador-ativo.txt ou rode ferramentas\jogador.ps1)"
        }
        $Estado = Join-Path $jog.Pasta 'estado'
    }
    if (-not $Backups) { $Backups = Join-Path $env:LOCALAPPDATA 'wow-agentes\backups' }

    if (-not $Raiz -or -not $Flavor) {
        if ($Instalacao -and (Test-Path -LiteralPath $Instalacao -PathType Leaf)) {
            $j = $null
            try { $j = Read-JsonUtf8 $Instalacao } catch { }
            if ($j) {
                if (-not $Raiz -and $j.PSObject.Properties['raiz']) { $Raiz = [string]$j.raiz }
                if (-not $Flavor -and $j.PSObject.Properties['flavor']) { $Flavor = [string]$j.flavor }
            }
        }
    }
    if (-not $Raiz -or -not $Flavor) {
        Stop-Wow PREREQ 'Instalação não configurada: rode o bootstrap (Find-WowInstalacao e Set-WowInstalacao)'
    }
    if (-not (Test-Path -LiteralPath $Raiz -PathType Container)) { Stop-Wow PREREQ "Pasta do jogo inexistente: $Raiz" }
    $pf = Join-Path $Raiz $Flavor
    if (-not (Test-Path -LiteralPath $pf -PathType Container)) { Stop-Wow PREREQ "Pasta do flavor inexistente: $pf" }

    $man = Join-Path $Estado 'addons'
    if (-not (Test-Path -LiteralPath $man)) { [void](New-Item -ItemType Directory -Path $man -Force) }

    return [pscustomobject]@{
        Raiz        = $Raiz
        Flavor      = $Flavor
        PastaFlavor = $pf
        AddOns      = (Join-Path $pf 'Interface\AddOns')
        WTF         = (Join-Path $pf 'WTF')
        Estado      = $Estado
        Manifestos  = $man
        Registro    = (Join-Path $Estado 'registro.md')
        SessaoJson  = (Join-Path $Estado 'sessao.json')
        Backups     = $Backups
        Instalacao  = $Instalacao
    }
}

# ------------------------------------------------------------------ jogo aberto

function Test-JogoAberto {
    param([Parameter(Mandatory)][string]$Raiz)
    if ($env:WOWAGENTE_JOGO_ABERTO -eq '1') { return $true }
    if ($env:WOWAGENTE_JOGO_ABERTO -eq '0') { return $false }
    $base = [IO.Path]::GetFullPath($Raiz).TrimEnd('\') + '\'
    foreach ($p in @(Get-Process -ErrorAction SilentlyContinue)) {
        $caminho = $null
        try { $caminho = $p.Path } catch { }
        if ($caminho -and $caminho.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Assert-JogoFechado {
    param([Parameter(Mandatory)][string]$Raiz)
    if (Test-JogoAberto -Raiz $Raiz) { Stop-Wow RECUSA 'Jogo aberto: feche o WoW e rode de novo.' }
}

# ------------------------------------------------------------------ TOC

function Get-TocInfo {
    param([Parameter(Mandatory)][string]$Arquivo)
    $texto = [IO.File]::ReadAllText($Arquivo, [Text.Encoding]::UTF8)   # detecta BOM; sem BOM le como UTF-8
    $interfaces = New-Object System.Collections.ArrayList
    $titulo = $null; $versao = $null
    $allow = New-Object System.Collections.ArrayList
    $deps = New-Object System.Collections.ArrayList

    foreach ($linha in ($texto -split "`r?`n")) {
        foreach ($m in [regex]::Matches($linha, '\[AllowLoadGameType\s+([^\]]*)\]', 'IgnoreCase')) {
            foreach ($t in ($m.Groups[1].Value -split '[,\s]+')) { if ($t.Trim()) { [void]$allow.Add($t.Trim()) } }
        }
        if ($linha -match '^\s*##\s*([^:]+?)\s*:\s*(.*?)\s*$') {
            $chave = $Matches[1].ToLowerInvariant(); $valor = $Matches[2]
            switch ($chave) {
                'interface' {
                    foreach ($t in ($valor -split ',')) {
                        if ($t.Trim() -match '^\d+$') { [void]$interfaces.Add([int]$t.Trim()) }
                    }
                }
                'title' { if ($null -eq $titulo) { $titulo = $valor } }
                'version' { if ($null -eq $versao) { $versao = $valor } }
                'allowloadgametype' {
                    foreach ($t in ($valor -split ',')) { if ($t.Trim()) { [void]$allow.Add($t.Trim()) } }
                }
                { $_ -in @('dependencies', 'requireddeps') } {
                    foreach ($t in ($valor -split ',')) { if ($t.Trim()) { [void]$deps.Add($t.Trim()) } }
                }
            }
        }
    }
    return [pscustomobject]@{
        Arquivo           = $Arquivo
        Interfaces        = [int[]]$interfaces.ToArray()
        Titulo            = $titulo
        Versao            = $versao
        AllowLoadGameType = [string[]]$allow.ToArray()
        Dependencias      = [string[]]$deps.ToArray()
    }
}

function Get-TocDoForever {
    param([Parameter(Mandatory)][string]$PastaAddon)
    $nome = [IO.Path]::GetFileName($PastaAddon.TrimEnd('\'))
    $presentes = @()
    if (Test-Path -LiteralPath $PastaAddon -PathType Container) {
        $presentes = @(Get-ChildItem -LiteralPath $PastaAddon -Filter '*.toc' -File | ForEach-Object { $_.Name })
    }
    $escolhido = $null; $tipo = 'nenhum'
    foreach ($c in @("${nome}_Forever.toc", "${nome}-Forever.toc", "${nome}_Camelot.toc", "${nome}-Camelot.toc")) {
        $achou = @($presentes | Where-Object { $_ -ieq $c }) | Select-Object -First 1
        if ($achou) { $escolhido = $achou; $tipo = 'forever'; break }
    }
    if (-not $escolhido) {
        $achou = @($presentes | Where-Object { $_ -ieq "$nome.toc" }) | Select-Object -First 1
        if ($achou) { $escolhido = $achou; $tipo = 'generico' }
    }
    $arq = $null; $info = $null
    if ($escolhido) {
        $arq = Join-Path $PastaAddon $escolhido
        $info = Get-TocInfo -Arquivo $arq
    }
    return [pscustomobject]@{
        Arquivo       = $arq
        Tipo          = $tipo
        Info          = $info
        TocsPresentes = [string[]]$presentes
    }
}

function Test-AddonForever {
    param([Parameter(Mandatory)][string]$PastaAddon, [Parameter(Mandatory)][int]$Interface)
    $t = Get-TocDoForever -PastaAddon $PastaAddon
    if ($t.Tipo -eq 'nenhum') {
        return [pscustomobject]@{ Compativel = $false; Motivo = 'nenhum TOC encontrado'; Toc = $null }
    }
    $leaf = [IO.Path]::GetFileName($t.Arquivo)
    if (@($t.Info.Interfaces) -contains $Interface) {
        return [pscustomobject]@{ Compativel = $true; Motivo = ''; Toc = $leaf }
    }
    $tem = 'nenhuma'
    if (@($t.Info.Interfaces).Count -gt 0) { $tem = (@($t.Info.Interfaces) -join ', ') }
    return [pscustomobject]@{ Compativel = $false; Motivo = "TOC sem a Interface $Interface (tem: $tem)"; Toc = $leaf }
}

# ------------------------------------------------------------------ zip, pastas, hash

function Get-PastaTempWow { Join-Path $env:TEMP 'wow-agentes' }

function New-NomeTemp {
    param([string]$Prefixo = 'x')
    $hex = [Guid]::NewGuid().ToString('N').Substring(0, 8)
    Join-Path (Get-PastaTempWow) "$Prefixo-$hex"
}

function Expand-ZipTemp {
    param([Parameter(Mandatory)][string]$Zip)
    $dest = New-NomeTemp 'x'
    [void](New-Item -ItemType Directory -Path $dest -Force)
    try { [System.IO.Compression.ZipFile]::ExtractToDirectory($Zip, $dest) }
    catch {
        $m = $_.Exception.Message
        Remove-Temp -Pasta $dest
        Stop-Wow ERRO "não foi possível extrair o zip ${Zip}: $m"
    }
    return $dest
}

function Remove-Temp {
    param([Parameter(Mandatory)][string]$Pasta)
    $base = [IO.Path]::GetFullPath((Get-PastaTempWow)).TrimEnd('\') + '\'
    $c = [IO.Path]::GetFullPath($Pasta)
    if (-not $c.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) {
        Stop-Wow ERRO "Remove-Temp recusou um caminho fora de $base : $c"
    }
    if (-not (Test-Path -LiteralPath $c)) { return }
    if (Test-Junction -Caminho $c) { [System.IO.Directory]::Delete($c); return }
    Remove-Item -LiteralPath $c -Recurse -Force -ErrorAction SilentlyContinue
}

function Test-Junction {
    param([Parameter(Mandatory)][string]$Caminho)
    if (-not (Test-Path -LiteralPath $Caminho)) { return $false }
    try {
        return (([int][IO.File]::GetAttributes($Caminho) -band [int][IO.FileAttributes]::ReparsePoint) -ne 0)
    } catch { return $false }
}

# Auxiliar: arquivos de uma pasta (recursivo), sem descer em junction. Devolve @({Relativo; Caminho; Bytes}).
function Get-ArquivosDaPasta {
    param([Parameter(Mandatory)][string]$Pasta)
    $base = [IO.Path]::GetFullPath($Pasta).TrimEnd('\')
    $res = New-Object System.Collections.ArrayList
    $pilha = New-Object System.Collections.Stack
    $pilha.Push($base)
    while ($pilha.Count -gt 0) {
        $dir = $pilha.Pop()
        $di = New-Object System.IO.DirectoryInfo $dir
        foreach ($e in $di.GetFileSystemInfos()) {
            if ($e -is [System.IO.DirectoryInfo]) {
                if (([int]$e.Attributes -band [int][IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
                $pilha.Push($e.FullName)
            } else {
                [void]$res.Add([pscustomobject]@{
                    Relativo = $e.FullName.Substring($base.Length + 1).Replace('\', '/')
                    Caminho  = $e.FullName
                    Bytes    = [long]$e.Length
                })
            }
        }
    }
    return $res.ToArray()
}

function Find-PastasDeAddon {
    param([Parameter(Mandatory)][string]$Pasta)
    $achadas = New-Object System.Collections.ArrayList
    $subs = @(Get-ChildItem -LiteralPath $Pasta -Directory | Where-Object { -not (Test-Junction -Caminho $_.FullName) })
    foreach ($d in $subs) {
        $tocs = @(Get-ChildItem -LiteralPath $d.FullName -File -ErrorAction SilentlyContinue |
                  Where-Object { $_.Name -like ($d.Name + '*.toc') })
        if ($tocs.Count -gt 0) { [void]$achadas.Add([pscustomobject]@{ Nome = $d.Name; Caminho = $d.FullName }) }
    }
    if ($achadas.Count -eq 0 -and $subs.Count -eq 1) {
        return @(Find-PastasDeAddon -Pasta $subs[0].FullName)
    }
    return $achadas.ToArray()
}

function Get-AssinaturaPasta {
    param([Parameter(Mandatory)][string]$Pasta)
    $arqs = @(Get-ArquivosDaPasta -Pasta $Pasta)
    $bytes = [long]0
    foreach ($a in $arqs) { $bytes += $a.Bytes }
    return ('{0}|{1}' -f $arqs.Count, $bytes)
}

function Get-HashPasta {
    param([Parameter(Mandatory)][string]$Pasta)
    $arqs = @(Get-ArquivosDaPasta -Pasta $Pasta)
    $chaves = New-Object string[] $arqs.Count
    $linhas = New-Object string[] $arqs.Count
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        for ($i = 0; $i -lt $arqs.Count; $i++) {
            $fs = [System.IO.File]::OpenRead($arqs[$i].Caminho)
            try { $h = $sha.ComputeHash($fs) } finally { $fs.Dispose() }
            $hex = [BitConverter]::ToString($h).Replace('-', '').ToLowerInvariant()
            $chaves[$i] = $arqs[$i].Relativo
            $linhas[$i] = '{0}|{1}|{2}' -f $arqs[$i].Relativo, $arqs[$i].Bytes, $hex
        }
        [Array]::Sort($chaves, $linhas, [StringComparer]::Ordinal)
        $texto = ''
        foreach ($l in $linhas) { $texto += $l + "`n" }
        $final = $sha.ComputeHash((New-Object System.Text.UTF8Encoding $false).GetBytes($texto))
    } finally { $sha.Dispose() }
    return [BitConverter]::ToString($final).Replace('-', '').ToLowerInvariant()
}

function Backup-Pastas {
    param([string[]]$Pastas, [Parameter(Mandatory)][string]$Zip)
    $lista = @($Pastas | Where-Object { $_ })
    if ($lista.Count -eq 0) { return $null }
    $dir = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Zip))
    if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
    if (Test-Path -LiteralPath $Zip) { Remove-Item -LiteralPath $Zip -Force }
    $arq = [System.IO.Compression.ZipFile]::Open($Zip, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($p in $lista) {
            if (Test-Junction -Caminho $p) { continue }
            $nome = [IO.Path]::GetFileName($p.TrimEnd('\'))
            [void]$arq.CreateEntry("$nome/")
            foreach ($a in @(Get-ArquivosDaPasta -Pasta $p)) {
                [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($arq, $a.Caminho, "$nome/$($a.Relativo)")
            }
        }
    } finally { $arq.Dispose() }
    return $Zip
}

# Auxiliar: copia uma pasta sem descer em junction.
function Copy-PastaSemJunction {
    param([Parameter(Mandatory)][string]$Origem, [Parameter(Mandatory)][string]$Destino)
    [void](New-Item -ItemType Directory -Path $Destino -Force)
    $base = [IO.Path]::GetFullPath($Origem).TrimEnd('\')
    $pilha = New-Object System.Collections.Stack
    $pilha.Push($base)
    while ($pilha.Count -gt 0) {
        $dir = $pilha.Pop()
        $di = New-Object System.IO.DirectoryInfo $dir
        foreach ($e in $di.GetFileSystemInfos()) {
            $rel = $e.FullName.Substring($base.Length + 1)
            $alvo = Join-Path $Destino $rel
            if ($e -is [System.IO.DirectoryInfo]) {
                if (([int]$e.Attributes -band [int][IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
                [void](New-Item -ItemType Directory -Path $alvo -Force)
                $pilha.Push($e.FullName)
            } else {
                [System.IO.File]::Copy($e.FullName, $alvo, $true)
            }
        }
    }
}

function Install-Pastas {
    param([Parameter(Mandatory)]$Origem, [Parameter(Mandatory)][string]$AddOns, [string[]]$RemoverTambem)
    $origens = @($Origem)
    $remover = @($RemoverTambem | Where-Object { $_ })
    if (-not (Test-Path -LiteralPath $AddOns)) { [void](New-Item -ItemType Directory -Path $AddOns -Force) }

    foreach ($n in (@($origens | ForEach-Object { $_.Nome }) + $remover)) {
        if (Test-Junction -Caminho (Join-Path $AddOns $n)) {
            Stop-Wow RECUSA "A pasta $n em AddOns é uma junction (addon de desenvolvimento); recuso substituir."
        }
    }

    $carimbo = (Get-Date).ToString('yyyy-MM-dd_HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 4)
    $renomeados = New-Object System.Collections.ArrayList   # @(original, backup)
    $copiados = New-Object System.Collections.ArrayList
    try {
        foreach ($n in (@($origens | ForEach-Object { $_.Nome }) + $remover)) {
            $dest = Join-Path $AddOns $n
            if (Test-Path -LiteralPath $dest) {
                $bak = "$dest.wowbak-$carimbo"
                [System.IO.Directory]::Move($dest, $bak)
                [void]$renomeados.Add(@($dest, $bak))
            }
        }
        foreach ($o in $origens) {
            if ($env:WOWAGENTE_FALHAR_COPIA -and $env:WOWAGENTE_FALHAR_COPIA -ieq $o.Nome) {
                throw "falha simulada ao copiar $($o.Nome)"
            }
            $dest = Join-Path $AddOns $o.Nome
            [void]$copiados.Add($dest)
            Copy-PastaSemJunction -Origem $o.Caminho -Destino $dest
        }
    }
    catch {
        $erro = $_.Exception.Message
        foreach ($c in $copiados) {
            if ((Test-Path -LiteralPath $c) -and -not (Test-Junction -Caminho $c)) {
                Remove-Item -LiteralPath $c -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        for ($i = $renomeados.Count - 1; $i -ge 0; $i--) {
            try { [System.IO.Directory]::Move($renomeados[$i][1], $renomeados[$i][0]) } catch { }
        }
        Stop-Wow ERRO "instalação desfeita: $erro"
    }
    foreach ($r in $renomeados) {
        if (-not (Test-Junction -Caminho $r[1])) { Remove-Item -LiteralPath $r[1] -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Remove-PastasAddon {
    param([Parameter(Mandatory)][string[]]$Nomes, [Parameter(Mandatory)][string]$AddOns)
    foreach ($n in $Nomes) {
        if (Test-Junction -Caminho (Join-Path $AddOns $n)) {
            Stop-Wow RECUSA "A pasta $n em AddOns é uma junction (addon de desenvolvimento); use dev-link.ps1 -Remover."
        }
    }
    foreach ($n in $Nomes) {
        $p = Join-Path $AddOns $n
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force }
    }
}

function Limit-Itens {
    param([Parameter(Mandatory)][string]$Pasta, [Parameter(Mandatory)][int]$Manter)
    if (-not (Test-Path -LiteralPath $Pasta -PathType Container)) { return }
    $itens = @(Get-ChildItem -LiteralPath $Pasta -Force)
    if ($itens.Count -le $Manter) { return }
    $nomes = New-Object string[] $itens.Count
    for ($i = 0; $i -lt $itens.Count; $i++) { $nomes[$i] = $itens[$i].Name }
    [Array]::Sort($nomes, $itens, [StringComparer]::Ordinal)
    $apagar = $itens.Count - $Manter
    for ($i = 0; $i -lt $apagar; $i++) {
        $it = $itens[$i]
        if ($it.PSIsContainer) {
            if (Test-Junction -Caminho $it.FullName) { [System.IO.Directory]::Delete($it.FullName) }
            else { Remove-Item -LiteralPath $it.FullName -Recurse -Force }
        } else { Remove-Item -LiteralPath $it.FullName -Force }
    }
}

# ------------------------------------------------------------------ manifestos, registro, sessao

function Get-Manifestos {
    param([Parameter(Mandatory)]$Contexto)
    $lista = New-Object System.Collections.ArrayList
    if (Test-Path -LiteralPath $Contexto.Manifestos -PathType Container) {
        foreach ($f in @(Get-ChildItem -LiteralPath $Contexto.Manifestos -Filter '*.json' -File | Sort-Object Name)) {
            [void]$lista.Add((Read-JsonUtf8 $f.FullName))
        }
    }
    return $lista.ToArray()
}

function Get-Manifesto {
    param([Parameter(Mandatory)]$Contexto, [Parameter(Mandatory)][string]$Slug)
    $p = Join-Path $Contexto.Manifestos "$Slug.json"
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return $null }
    return (Read-JsonUtf8 $p)
}

function Save-Manifesto {
    param([Parameter(Mandatory)]$Contexto, [Parameter(Mandatory)]$Manifesto)
    Write-JsonUtf8 -Objeto $Manifesto -Caminho (Join-Path $Contexto.Manifestos ("{0}.json" -f $Manifesto.slug))
}

function Get-DonoDaPasta {
    param([Parameter(Mandatory)]$Contexto, [Parameter(Mandatory)][string]$Nome)
    foreach ($m in @(Get-Manifestos -Contexto $Contexto)) {
        if ($m.estadoInstalacao -ne 'instalado') { continue }
        foreach ($p in @($m.pastas)) { if ($p.nome -ieq $Nome) { return [string]$m.slug } }
    }
    return $null
}

function Add-Registro {
    param([Parameter(Mandatory)]$Contexto, [Parameter(Mandatory)][string]$Acao, [Parameter(Mandatory)][string]$Slug, [string]$Detalhe = '')
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $dir = [IO.Path]::GetDirectoryName($Contexto.Registro)
    if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
    if (-not (Test-Path -LiteralPath $Contexto.Registro)) {
        [System.IO.File]::WriteAllText($Contexto.Registro, "# Registro de mudanças do wow-modder`r`n`r`n", $utf8)
    }
    $linha = '- {0} | {1} | {2} | {3}' -f (Get-Date).ToString('yyyy-MM-dd HH:mm'), $Acao, $Slug, $Detalhe
    [System.IO.File]::AppendAllText($Contexto.Registro, $linha + "`r`n", $utf8)
}

function Get-SessaoJson {
    param([Parameter(Mandatory)]$Contexto)
    if (-not (Test-Path -LiteralPath $Contexto.SessaoJson -PathType Leaf)) { return $null }
    return (Read-JsonUtf8 $Contexto.SessaoJson)
}

function Save-SessaoJson {
    param([Parameter(Mandatory)]$Contexto, [Parameter(Mandatory)]$Dados)
    Write-JsonUtf8 -Objeto $Dados -Caminho $Contexto.SessaoJson
}

# ------------------------------------------------------------------ WTF e Config.wtf

function Get-CVarsWtf {
    param([Parameter(Mandatory)][string]$Arquivo)
    $r = @{}
    foreach ($l in @((Read-TextoPreservando -Path $Arquivo).Linhas)) {
        if ($l -match '^\s*SET\s+(\S+)\s+"(.*)"\s*$') { $r[$Matches[1]] = $Matches[2] }
    }
    return $r
}

function Set-CVarWtf {
    param([Parameter(Mandatory)][string]$Arquivo, [Parameter(Mandatory)][hashtable]$Valores)
    $arq = Read-TextoPreservando -Path $Arquivo
    $linhas = New-Object System.Collections.Generic.List[string]
    foreach ($l in @($arq.Linhas)) { $linhas.Add([string]$l) }
    $vazio = ($linhas.Count -eq 0)
    foreach ($nome in @($Valores.Keys)) {
        $valor = [string]$Valores[$nome]
        $achou = $false
        for ($i = 0; $i -lt $linhas.Count; $i++) {
            if ($linhas[$i] -match '^(\s*SET\s+)(\S+)(\s+)"(.*)"\s*$' -and $Matches[2] -ieq $nome) {
                $linhas[$i] = $Matches[1] + $Matches[2] + $Matches[3] + '"' + $valor + '"'
                $achou = $true
            }
        }
        if (-not $achou) { $linhas.Add('SET ' + $nome + ' "' + $valor + '"') }
    }
    $arq.Linhas = [string[]]$linhas.ToArray()
    if ($vazio) { $arq.Quebra = "`r`n"; $arq.FinalComQuebra = $true }
    Write-TextoPreservando -Path $Arquivo -Arquivo $arq
}

function Backup-Wtf {
    param([Parameter(Mandatory)]$Contexto, [string]$Rotulo = '')
    if (-not (Test-Path -LiteralPath $Contexto.WTF -PathType Container)) {
        Stop-Wow PREREQ 'WTF ainda não existe: entre no jogo uma vez'
    }
    $raizSessoes = Join-Path $Contexto.Backups 'sessoes'
    $nome = (Get-Date).ToString('yyyy-MM-dd_HHmm')
    $dir = Join-Path $raizSessoes $nome
    if (Test-Path -LiteralPath $dir) {
        $nome = (Get-Date).ToString('yyyy-MM-dd_HHmm-ss')
        $dir = Join-Path $raizSessoes $nome
        $n = 2
        while (Test-Path -LiteralPath $dir) { $dir = Join-Path $raizSessoes ("{0}-{1}" -f $nome, $n); $n++ }
    }
    [void](New-Item -ItemType Directory -Path $dir -Force)
    $zip = Join-Path $dir 'WTF.zip'
    [void](Backup-Pastas -Pastas @($Contexto.WTF) -Zip $zip)
    $info = "rotulo: $Rotulo`r`ndata: $(Get-AgoraIso)`r`n"
    [System.IO.File]::WriteAllText((Join-Path $dir 'info.txt'), $info, (New-Object System.Text.UTF8Encoding $false))
    Limit-Itens -Pasta $raizSessoes -Manter 20
    return $zip
}

# ------------------------------------------------------------------ fontes e download

function Get-RespostaJson {
    param([Parameter(Mandatory)][string]$Url, [Parameter(Mandatory)][string]$ArquivoSimulado)
    if ($env:WOWAGENTE_RESPOSTAS) {
        $p = Join-Path $env:WOWAGENTE_RESPOSTAS $ArquivoSimulado
        if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Stop-Wow ERRO "resposta simulada ausente: $ArquivoSimulado" }
        return (Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json)
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    try { return (Invoke-RestMethod -Uri $Url -Headers @{ 'User-Agent' = 'wow-modder' } -UseBasicParsing) }
    catch { Stop-Wow ERRO "falha de rede em ${Url}: $($_.Exception.Message)" }
}

# Troca '+' por '%2B' no caminho da URL, nunca na query.
function ConvertTo-UrlSegura {
    param([string]$Url)
    if ($Url -notmatch '^https?://') { return $Url }
    $i = $Url.IndexOf('?')
    if ($i -lt 0) { return $Url.Replace('+', '%2B') }
    return $Url.Substring(0, $i).Replace('+', '%2B') + $Url.Substring($i)
}

function Get-FonteAddon {
    param([Parameter(Mandatory)][string]$Fonte, [string]$Asset, [int]$Interface = 0, [string]$VersaoJogo)
    if ($Fonte -notmatch '^(github|tukui):(.+)$') { Stop-Wow ERRO "fonte inválida (use github:owner/repo ou tukui:slug): $Fonte" }
    $tipo = $Matches[1]; $id = $Matches[2].Trim()

    if ($tipo -eq 'tukui') {
        $j = Get-RespostaJson -Url "https://api.tukui.org/v1/addon/$id" -ArquivoSimulado "tukui-$id.json"
        $patch = @($j.patch | Where-Object { $_ })
        $compat = $null; $motivo = ''
        if ($VersaoJogo) {
            $compat = ($patch -contains $VersaoJogo)
            if (-not $compat) { $motivo = "Tukui sem o patch $VersaoJogo (tem: " + ($patch -join ', ') + ')' }
        }
        $nomeAsset = $null
        if ($j.url) { $nomeAsset = [IO.Path]::GetFileName(([string]$j.url -split '\?')[0]) }
        return [pscustomobject]@{
            Tipo = 'tukui'; Id = $id; Versao = [string]$j.version; Data = [string]$j.last_update
            Url = [string]$j.url; Asset = $nomeAsset; Compativel = $compat; Motivo = $motivo
        }
    }

    if ($id -notmatch '^[^/\s]+/[^/\s]+$') { Stop-Wow ERRO "fonte github inválida (use github:owner/repo): $Fonte" }
    $owner, $repo = $id.Split('/')
    $rel = Get-RespostaJson -Url "https://api.github.com/repos/$owner/$repo/releases/latest" -ArquivoSimulado "github-${owner}_${repo}.json"
    $tag = [string]$rel.tag_name
    $data = [string]$rel.published_at
    $assets = @($rel.assets | Where-Object { $_ })

    $rj = @($assets | Where-Object { $_.name -ieq 'release.json' }) | Select-Object -First 1
    if ($rj) {
        $r = Get-RespostaJson -Url (ConvertTo-UrlSegura ([string]$rj.browser_download_url)) -ArquivoSimulado "github-${owner}_${repo}-release.json"
        $escolhida = $null
        foreach ($c in @($r.releases)) {
            if ($c.nolib) { continue }
            foreach ($m in @($c.metadata)) {
                if (([string]$m.flavor -ieq 'forever') -or ($Interface -gt 0 -and [string]$m.interface -eq [string]$Interface)) { $escolhida = $c; break }
            }
            if ($escolhida) { break }
        }
        if (-not $escolhida) {
            return [pscustomobject]@{ Tipo = 'github'; Id = $id; Versao = $tag; Data = $data; Url = $null; Asset = $null
                Compativel = $false; Motivo = 'release.json sem o flavor forever' }
        }
        # release.json de alguns empacotadores não traz "version" (o do Questie, visto em 2026-11-03): cai no tag_name
        $versaoRel = [string]$escolhida.version
        if (-not $versaoRel) { $versaoRel = $tag }
        $a = @($assets | Where-Object { $_.name -ieq [string]$escolhida.filename }) | Select-Object -First 1
        if (-not $a) {
            return [pscustomobject]@{ Tipo = 'github'; Id = $id; Versao = $versaoRel; Data = $data; Url = $null; Asset = [string]$escolhida.filename
                Compativel = $false; Motivo = "o asset $($escolhida.filename) não está no release" }
        }
        return [pscustomobject]@{ Tipo = 'github'; Id = $id; Versao = $versaoRel; Data = $data
            Url = (ConvertTo-UrlSegura ([string]$a.browser_download_url)); Asset = [string]$a.name; Compativel = $true; Motivo = '' }
    }

    $zips = @($assets | Where-Object { $_.name -match '(?i)\.zip$' })
    $pick = $null
    if ($Asset) { $pick = @($zips | Where-Object { $_.name -match $Asset }) | Select-Object -First 1 }
    if (-not $pick) {
        $f = @($zips | Where-Object { $_.name -match '(?i)forever|camelot' })
        if ($f.Count -ge 1) { $pick = $f[0] }
    }
    if (-not $pick -and $zips.Count -eq 1) { $pick = $zips[0] }
    if (-not $pick) {
        $resto = @($zips | Where-Object { $_.name -notmatch '(?i)classic|vanilla|bcc|tbc|wrath|wotlk|cata|mists|mop|mainline|retail|nolib' })
        if ($resto.Count -eq 1) { $pick = $resto[0] }
    }
    if (-not $pick) {
        Stop-Wow RECUSA ("nenhum asset serve em ${id}: " + ((@($assets | ForEach-Object { $_.name })) -join ', '))
    }
    return [pscustomobject]@{ Tipo = 'github'; Id = $id; Versao = $tag; Data = $data
        Url = (ConvertTo-UrlSegura ([string]$pick.browser_download_url)); Asset = [string]$pick.name; Compativel = $null; Motivo = '' }
}

function Save-Download {
    param([Parameter(Mandatory)][string]$Url, [Parameter(Mandatory)][string]$Destino)
    $dir = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Destino))
    if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
    $local = $null
    if ($Url -match '^file:///') { $local = ([Uri]$Url).LocalPath }
    elseif ($Url -notmatch '^https?://' -and (Test-Path -LiteralPath $Url -PathType Leaf)) { $local = $Url }
    if ($local) {
        if (-not (Test-Path -LiteralPath $local -PathType Leaf)) { Stop-Wow ERRO "arquivo local inexistente: $local" }
        Copy-Item -LiteralPath $local -Destination $Destino -Force
        return
    }
    if ($env:WOWAGENTE_RESPOSTAS) { Stop-Wow ERRO "modo simulado: a URL não é um arquivo local: $Url" }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    try { Invoke-WebRequest -Uri $Url -OutFile $Destino -UseBasicParsing -Headers @{ 'User-Agent' = 'wow-modder' } }
    catch { Stop-Wow ERRO "falha no download de ${Url}: $($_.Exception.Message)" }
}

# ------------------------------------------------------------------ fluxos

function Get-CarimboBackup { (Get-Date).ToString('yyyy-MM-dd_HHmmss') }

# Auxiliar: backup zip das pastas que existem em AddOns, em <Backups>\addons\<slug>\<carimbo>.zip (mantem 3).
function Backup-PastasDoAddon {
    param([Parameter(Mandatory)]$Contexto, [Parameter(Mandatory)][string]$Slug, [string[]]$Nomes)
    $existentes = @($Nomes | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $Contexto.AddOns $_)) } |
                    ForEach-Object { Join-Path $Contexto.AddOns $_ })
    if ($existentes.Count -eq 0) { return $null }
    $dir = Join-Path (Join-Path $Contexto.Backups 'addons') $Slug
    $zip = Join-Path $dir ((Get-CarimboBackup) + '.zip')
    $n = 2
    while (Test-Path -LiteralPath $zip) { $zip = Join-Path $dir ("{0}-{1}.zip" -f (Get-CarimboBackup), $n); $n++ }
    [void](Backup-Pastas -Pastas $existentes -Zip $zip)
    Limit-Itens -Pasta $dir -Manter 3
    return $zip
}

# Lista de nomes de pasta a partir de -SoPastas ("A,B;C" ou um array), sem vazios. Devolve a lista desenrolada.
function ConvertTo-ListaPastas {
    param([object[]]$Valor)
    $saida = @()
    foreach ($v in @($Valor)) {
        if ($null -eq $v) { continue }
        foreach ($p in ([string]$v -split '[,;]')) { $t = $p.Trim(); if ($t) { $saida += $t } }
    }
    return $saida
}

function Install-AddonDeFonte {
    param(
        [Parameter(Mandatory)]$Contexto,
        [Parameter(Mandatory)][string]$Fonte,
        [Parameter(Mandatory)][string]$Slug,
        [string]$Nome,
        [string]$Asset,
        [string]$Pagina,
        [switch]$Forcar,
        [switch]$SoCompativeis,
        [string[]]$SoPastas,
        [switch]$Aplicar
    )
    if ($Slug -notmatch '^[a-z0-9-]+$') { Stop-Wow ERRO "slug inválido (use minúsculas, números e hífen): $Slug" }

    # 1. versao do cliente
    $cli = Get-WowVersao -Raiz $Contexto.Raiz -Flavor $Contexto.Flavor
    if (-not $cli) { Stop-Wow PREREQ 'Não consegui ler a versão do cliente (.build.info / .flavor.info).' }

    $antigo = Get-Manifesto -Contexto $Contexto -Slug $Slug
    $antigoInstalado = ($antigo -and $antigo.estadoInstalacao -eq 'instalado')

    # 2. resolve a fonte
    $tipoFonte = $null; $idFonte = $null; $versao = $null; $info = $null; $zipLocal = $null; $tempDl = $null
    if ($Fonte -match '^zip:(.+)$') {
        $tipoFonte = 'zip'; $idFonte = $Matches[1].Trim()
        if (-not (Test-Path -LiteralPath $idFonte -PathType Leaf)) { Stop-Wow PREREQ "zip não encontrado: $idFonte" }
        $zipLocal = $idFonte
    } else {
        $info = Get-FonteAddon -Fonte $Fonte -Asset $Asset -Interface $cli.Interface -VersaoJogo (ConvertTo-WowVersaoCurta $cli.Versao)
        $tipoFonte = $info.Tipo; $idFonte = $info.Id; $versao = $info.Versao
        if ($info.Compativel -eq $false -and -not $Forcar) { Stop-Wow RECUSA "fonte incompatível: $($info.Motivo)" }
        # 3. nada a fazer (github e tukui; no zip a versao so se conhece depois de extrair)
        if ($antigoInstalado) {
            if ($antigo.versao -eq $versao -and -not $Forcar) {
                Write-Linha "OK nada a fazer slug=$Slug versao=$versao"
                return [pscustomobject]@{ Slug = $Slug; Acao = 'nada'; VersaoAntes = $versao; VersaoDepois = $versao; Pastas = @(); Backup = $null; Aplicado = $false }
            }
        }
    }

    $temp = $null
    try {
        # 4. baixa e extrai
        if (-not $zipLocal) {
            if (-not $info.Url) { Stop-Wow RECUSA "nenhum asset utilizável na fonte: $($info.Motivo)" }
            $tempDl = New-NomeTemp 'd'
            $zipLocal = Join-Path $tempDl 'addon.zip'
            Save-Download -Url $info.Url -Destino $zipLocal
        }
        $temp = Expand-ZipTemp -Zip $zipLocal
        $pastas = @(Find-PastasDeAddon -Pasta $temp)
        if ($pastas.Count -eq 0) { Stop-Wow RECUSA 'o zip não contém addon' }

        if ($tipoFonte -eq 'zip') {
            $t0 = Get-TocDoForever -PastaAddon $pastas[0].Caminho
            if ($t0.Info -and $t0.Info.Versao) { $versao = $t0.Info.Versao }
            else {
                $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipLocal).Hash.ToLowerInvariant()
                $versao = 'zip-' + $h.Substring(0, 8)
            }
            if ($antigoInstalado -and $antigo.versao -eq $versao -and -not $Forcar) {
                Write-Linha "OK nada a fazer slug=$Slug versao=$versao"
                return [pscustomobject]@{ Slug = $Slug; Acao = 'nada'; VersaoAntes = $versao; VersaoDepois = $versao; Pastas = @(); Backup = $null; Aplicado = $false }
            }
        }

        # 4b. lista de pastas: -SoPastas (ou a lista gravada no manifesto) instala só as pastas pedidas de um
        # pacote com muitos módulos (o Naowh Forever traz 13). As outras saem na prévia como ignorar.
        $soPastasLista = @(ConvertTo-ListaPastas -Valor $SoPastas)
        if ($soPastasLista.Count -eq 0 -and $antigo -and $antigo.fonte -and $antigo.fonte.PSObject.Properties['soPastas'] -and $antigo.fonte.soPastas) {
            $soPastasLista = @(ConvertTo-ListaPastas -Valor @($antigo.fonte.soPastas))
        }
        $foraDaLista = @()
        if ($soPastasLista.Count -gt 0) {
            $nomesPacote = @($pastas | ForEach-Object { $_.Nome })
            $faltamNaLista = @($soPastasLista | Where-Object { $nomesPacote -notcontains $_ })
            if ($faltamNaLista.Count -gt 0) { Stop-Wow RECUSA ("pasta da lista ausente no pacote: " + ($faltamNaLista -join ', ')) }
            $foraDaLista = @($pastas | Where-Object { $soPastasLista -notcontains $_.Nome } | ForEach-Object { $_.Nome })
            $pastas = @($pastas | Where-Object { $soPastasLista -contains $_.Nome })
        }

        # 5. compatibilidade de TOC
        # -SoCompativeis (ou o mesmo filtro gravado no manifesto) deixa de fora as pastas sem TOC do Forever,
        # como os módulos do Midnight que vêm no pacote do DBM e do BigWigs.
        $filtrar = [bool]$SoCompativeis
        if (-not $filtrar -and $antigo -and $antigo.fonte -and $antigo.fonte.PSObject.Properties['soCompativeis']) {
            $filtrar = [bool]$antigo.fonte.soCompativeis
        }
        $testes = @{}
        $incompat = @()
        $ignoradas = @()
        foreach ($p in $pastas) {
            $r = Test-AddonForever -PastaAddon $p.Caminho -Interface $cli.Interface
            $testes[$p.Nome] = $r
            if (-not $r.Compativel) {
                $incompat += ("{0}: {1}" -f $p.Nome, $r.Motivo)
                $ignoradas += [pscustomobject]@{ Nome = $p.Nome; Motivo = $r.Motivo }
            }
        }
        if ($filtrar -and $incompat.Count -gt 0 -and -not $Forcar) {
            $pastas = @($pastas | Where-Object { $testes[$_.Nome].Compativel })
            if ($pastas.Count -eq 0) { Stop-Wow RECUSA ("nenhuma pasta compatível: " + ($incompat -join '; ')) }
        } else {
            $ignoradas = @()
            if ($incompat.Count -gt 0 -and -not $Forcar) { Stop-Wow RECUSA ("TOC incompatível: " + ($incompat -join '; ')) }
        }

        # 6. conflitos
        foreach ($p in $pastas) {
            $dono = Get-DonoDaPasta -Contexto $Contexto -Nome $p.Nome
            if ($dono -and $dono -ne $Slug) { Stop-Wow RECUSA "pasta $($p.Nome) pertence ao addon $dono" }
            if (Test-Junction -Caminho (Join-Path $Contexto.AddOns $p.Nome)) {
                Stop-Wow RECUSA "pasta $($p.Nome) é uma junction (addon de desenvolvimento) em AddOns"
            }
        }

        # 7. previa
        $nomesNovos = @($pastas | ForEach-Object { $_.Nome })
        $removidas = @()
        if ($antigoInstalado) {
            $removidas = @(@($antigo.pastas) | ForEach-Object { [string]$_.nome } | Where-Object { $nomesNovos -inotcontains $_ })
        }
        $acao = 'criar'
        if ($antigoInstalado) { $acao = 'atualizar' }
        Write-Linha "PREVIA slug=$Slug versao=$versao fonte=${tipoFonte}:${idFonte} acao=$acao"
        foreach ($p in $pastas) {
            $r = $testes[$p.Nome]
            $acaoP = 'criar'
            if (Test-Path -LiteralPath (Join-Path $Contexto.AddOns $p.Nome)) { $acaoP = 'substituir' }
            $tocNome = $r.Toc; if (-not $tocNome) { $tocNome = '(nenhum)' }
            $ints = (@((Get-TocDoForever -PastaAddon $p.Caminho).Info.Interfaces) -join ',')
            $comp = 'nao'; if ($r.Compativel) { $comp = 'sim' }
            Write-Linha "PASTA nome=$($p.Nome) acao=$acaoP toc=$tocNome interfaces=$ints compativel=$comp"
        }
        foreach ($i in $ignoradas) { Write-Linha "PASTA nome=$($i.Nome) acao=ignorar motivo=$($i.Motivo)" }
        foreach ($n in $foraDaLista) { Write-Linha "PASTA nome=$n acao=ignorar motivo=fora-da-lista" }
        foreach ($n in $removidas) { Write-Linha "PASTA nome=$n acao=remover" }

        $versaoAntes = $null
        if ($antigoInstalado) { $versaoAntes = [string]$antigo.versao }

        # 8. sem -Aplicar
        if (-not $Aplicar) {
            Write-Linha 'Prévia apenas; rode com -Aplicar para instalar.'
            return [pscustomobject]@{ Slug = $Slug; Acao = $acao; VersaoAntes = $versaoAntes; VersaoDepois = $versao; Pastas = @($nomesNovos); Backup = $null; Aplicado = $false }
        }

        # 9. aplicar
        Assert-JogoFechado -Raiz $Contexto.Raiz
        $backup = Backup-PastasDoAddon -Contexto $Contexto -Slug $Slug -Nomes (@($nomesNovos) + @($removidas))
        Install-Pastas -Origem $pastas -AddOns $Contexto.AddOns -RemoverTambem $removidas

        $listaPastas = @()
        foreach ($p in $pastas) {
            $ti = Get-TocDoForever -PastaAddon $p.Caminho
            $tocLeaf = $null; $ints = [int[]]@()
            if ($ti.Arquivo) { $tocLeaf = [IO.Path]::GetFileName($ti.Arquivo); $ints = [int[]]@($ti.Info.Interfaces) }
            $listaPastas += [ordered]@{
                nome       = $p.Nome
                toc        = $tocLeaf
                interfaces = $ints
                assinatura = (Get-AssinaturaPasta -Pasta $p.Caminho)
                sha256     = (Get-HashPasta -Pasta $p.Caminho)
            }
        }
        $agora = Get-AgoraIso
        $instaladoEm = $agora
        if ($antigoInstalado -and $antigo.instaladoEm) { $instaladoEm = [string]$antigo.instaladoEm }
        $nomeLegivel = $Nome
        if (-not $nomeLegivel -and $antigo) { $nomeLegivel = [string]$antigo.nome }
        if (-not $nomeLegivel) { $nomeLegivel = $Slug }
        $assetManifesto = $null
        if ($Asset) { $assetManifesto = $Asset }
        $manifesto = [ordered]@{
            v                = 1
            slug             = $Slug
            nome             = $nomeLegivel
            versao           = $versao
            fonte            = [ordered]@{ tipo = $tipoFonte; id = $idFonte; asset = $assetManifesto; pagina = $(if ($Pagina) { $Pagina } else { $null }); soCompativeis = $filtrar; soPastas = $(if ($soPastasLista.Count -gt 0) { ,@($soPastasLista) } else { $null }) }
            pastas           = $listaPastas
            aprovado         = $true
            estadoInstalacao = 'instalado'
            instaladoEm      = $instaladoEm
            atualizadoEm     = $agora
            removidoEm       = $null
            backupAnterior   = $backup
            maquina          = $env:COMPUTERNAME
        }
        Save-Manifesto -Contexto $Contexto -Manifesto $manifesto

        if ($antigoInstalado) {
            Add-Registro -Contexto $Contexto -Acao 'atualizar' -Slug $Slug -Detalhe "de=$versaoAntes para=$versao fonte=${tipoFonte}:${idFonte}"
            Write-Linha "OK atualizado slug=$Slug de=$versaoAntes para=$versao"
        } else {
            Add-Registro -Contexto $Contexto -Acao 'instalar' -Slug $Slug -Detalhe "versao=$versao fonte=${tipoFonte}:${idFonte}"
            Write-Linha "OK instalado slug=$Slug versao=$versao"
        }
        return [pscustomobject]@{ Slug = $Slug; Acao = $acao; VersaoAntes = $versaoAntes; VersaoDepois = $versao; Pastas = @($nomesNovos); Backup = $backup; Aplicado = $true }
    }
    finally {
        if ($temp) { Remove-Temp -Pasta $temp }
        if ($tempDl) { Remove-Temp -Pasta $tempDl }
    }
}

function Remove-Addon {
    param([Parameter(Mandatory)]$Contexto, [Parameter(Mandatory)][string]$Slug, [switch]$Aplicar)
    $m = Get-Manifesto -Contexto $Contexto -Slug $Slug
    if (-not $m -or $m.estadoInstalacao -ne 'instalado') { Stop-Wow PREREQ "Sem manifesto instalado para o slug $Slug" }
    if ($m.fonte.tipo -eq 'dev') { Stop-Wow RECUSA 'use dev-link.ps1 -Remover' }

    $nomes = @(@($m.pastas) | ForEach-Object { [string]$_.nome })
    Write-Linha "PREVIA slug=$Slug acao=remover"
    foreach ($n in $nomes) { Write-Linha "PASTA nome=$n acao=remover" }
    if (-not $Aplicar) {
        Write-Linha 'Prévia apenas; rode com -Aplicar para remover.'
        return [pscustomobject]@{ Slug = $Slug; Pastas = @($nomes); Backup = $null; Aplicado = $false }
    }

    Assert-JogoFechado -Raiz $Contexto.Raiz
    $backup = Backup-PastasDoAddon -Contexto $Contexto -Slug $Slug -Nomes $nomes
    Remove-PastasAddon -Nomes $nomes -AddOns $Contexto.AddOns
    $m.estadoInstalacao = 'removido'
    $m.removidoEm = Get-AgoraIso
    $m.backupAnterior = $backup
    Save-Manifesto -Contexto $Contexto -Manifesto $m
    Add-Registro -Contexto $Contexto -Acao 'remover' -Slug $Slug -Detalhe ("pastas=" + ($nomes -join ','))
    Write-Linha "OK removido slug=$Slug"
    return [pscustomobject]@{ Slug = $Slug; Pastas = @($nomes); Backup = $backup; Aplicado = $true }
}
