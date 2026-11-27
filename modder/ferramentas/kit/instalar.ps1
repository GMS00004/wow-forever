# Instalador do Kit do WoW Forever (para o amigo do Guilherme).
# Fonte do INSTALAR.bat: o kit-amigo.ps1 cola este texto depois de um cabecalho de cmd,
# e o cmd o executa pelo PowerShell (ver $CABECALHO no kit-amigo.ps1).
# So escreve em <WoW>\_forever_\Interface\AddOns, com o jogo fechado, e antes move as pastas
# que vai trocar para Interface\AddOns-backup-<data> (fora da AddOns, o jogo nao carrega).
# Variaveis de teste: KITWOW_DESTINO (pasta _forever_ falsa), KITWOW_SEM_JANELA=1 (sem janela),
# KITWOW_JOGO_ABERTO=1|0 (forca a deteccao), KITWOW_DOWNLOADS (pasta onde procurar o zip do kit).
# Codigos: 0 ok, 1 desistiu (jogo aberto), 2 faltou o jogo ou o kit, 3 erro.
$ErrorActionPreference = 'Stop'
$titulo = 'Kit do WoW Forever'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$semJanela = ($env:KITWOW_SEM_JANELA -eq '1')
if (-not $semJanela) { Add-Type -AssemblyName System.Windows.Forms }

function Avisar([string]$texto, [string]$icone = 'Information', [string]$botoes = 'OK') {
    Write-Host ''
    Write-Host $texto
    if ($semJanela) { return 'OK' }
    return [string][System.Windows.Forms.MessageBox]::Show($texto, $titulo, $botoes, $icone)
}

function Get-PastaForever {
    if ($env:KITWOW_DESTINO) { return $env:KITWOW_DESTINO }
    $raizes = New-Object System.Collections.ArrayList
    foreach ($chave in @('HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                         'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                         'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
        try {
            foreach ($e in @(Get-ItemProperty -Path $chave -ErrorAction SilentlyContinue)) {
                if ([string]$e.DisplayName -match 'World of Warcraft' -and $e.InstallLocation) { [void]$raizes.Add([string]$e.InstallLocation) }
            }
        } catch { }
    }
    $cfg = Join-Path $env:APPDATA 'Battle.net\Battle.net.config'
    if (Test-Path -LiteralPath $cfg -PathType Leaf) {
        try {
            $txt = [IO.File]::ReadAllText($cfg)
            if ($txt -match '"DefaultInstallPath"\s*:\s*"([^"]+)"') {
                $p = ($Matches[1] -replace '\\\\', '\').Replace('/', '\').TrimEnd('\')
                [void]$raizes.Add((Join-Path $p 'World of Warcraft'))
            }
        } catch { }
    }
    foreach ($d in @([IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' -and $_.IsReady })) {
        foreach ($sub in @('Program Files (x86)\World of Warcraft', 'Program Files\World of Warcraft', 'World of Warcraft',
                           'Games\World of Warcraft', 'Jogos\World of Warcraft', 'Blizzard\World of Warcraft', 'Battle.net\World of Warcraft')) {
            [void]$raizes.Add((Join-Path $d.RootDirectory.FullName $sub))
        }
    }
    $melhor = $null; $data = [datetime]::MinValue
    foreach ($r in @($raizes | Select-Object -Unique)) {
        try { $r = [IO.Path]::GetFullPath(([string]$r).Trim()).TrimEnd('\') } catch { continue }
        $f = Join-Path $r '_forever_'
        if (-not (Test-Path -LiteralPath $f -PathType Container)) { continue }
        $exe = Join-Path $f 'Wow.exe'
        $quando = [datetime]::MinValue
        if (Test-Path -LiteralPath $exe -PathType Leaf) { $quando = (Get-Item -LiteralPath $exe).LastWriteTime }
        if (-not $melhor -or $quando -gt $data) { $melhor = $f; $data = $quando }
    }
    return $melhor
}

function Test-JogoAberto([string]$forever) {
    if ($env:KITWOW_JOGO_ABERTO -eq '1') { return $true }
    if ($env:KITWOW_JOGO_ABERTO -eq '0') { return $false }
    $base = [IO.Path]::GetFullPath($forever).TrimEnd('\') + '\'
    foreach ($p in @(Get-Process -ErrorAction SilentlyContinue)) {
        $c = $null
        try { $c = $p.Path } catch { }
        if ($c -and $c.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) { return $true }
        if (-not $c -and $p.ProcessName -match '^Wow') { return $true }
    }
    return $false
}

function Get-PacoteDeAddons {
    $bat = $env:KITWOW_BAT
    if (-not $bat) { $bat = $PSCommandPath }
    $aqui = Join-Path (Split-Path -Parent $bat) 'arquivos\addons.zip'
    if (Test-Path -LiteralPath $aqui -PathType Leaf) { return @{ Zip = $aqui; Temp = $null } }

    # Rodou de dentro do zip, sem extrair: procura o kit baixado e tira dele o pacote.
    $lugares = New-Object System.Collections.ArrayList
    if ($env:KITWOW_DOWNLOADS) { [void]$lugares.Add($env:KITWOW_DOWNLOADS) }
    else {
        try { [void]$lugares.Add((New-Object -ComObject Shell.Application).Namespace('shell:Downloads').Self.Path) } catch { }
        [void]$lugares.Add((Join-Path $env:USERPROFILE 'Downloads'))
        [void]$lugares.Add([Environment]::GetFolderPath('Desktop'))
    }
    $zipKit = $null
    foreach ($l in @($lugares | Select-Object -Unique)) {
        if (-not $l -or -not (Test-Path -LiteralPath $l -PathType Container)) { continue }
        $z = Get-ChildItem -LiteralPath $l -Filter 'Kit-WoW-Forever*.zip' -File -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($z -and (-not $zipKit -or $z.LastWriteTime -gt $zipKit.LastWriteTime)) { $zipKit = $z }
    }
    if (-not $zipKit) { return $null }
    $temp = Join-Path $env:TEMP ('kitwow-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    [void](New-Item -ItemType Directory -Path $temp)
    $saida = Join-Path $temp 'addons.zip'
    $za = [IO.Compression.ZipFile]::OpenRead($zipKit.FullName)
    try {
        $e = @($za.Entries | Where-Object { $_.FullName -match '(^|[/\\])arquivos[/\\]addons\.zip$' }) | Select-Object -First 1
        if (-not $e) { return $null }
        [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $saida, $true)
    } finally { $za.Dispose() }
    return @{ Zip = $saida; Temp = $temp }
}

$pacote = $null
try {
    Write-Host 'Kit do WoW Forever: procurando o jogo...'

    # 1. O pacote de addons
    $pacote = Get-PacoteDeAddons
    if (-not $pacote) {
        [void](Avisar ("Não achei os arquivos do kit.`n`n" +
            "Clique com o botão direito no arquivo Kit-WoW-Forever que você baixou, escolha Extrair Tudo e depois Extrair. " +
            "Na pasta que abrir, dê dois cliques em INSTALAR.") 'Warning')
        exit 2
    }

    # 2. A pasta do jogo
    $forever = Get-PastaForever
    if (-not $forever -and -not $semJanela) {
        $r = Avisar ("Não achei o WoW Forever neste computador.`n`n" +
            "Se o jogo já está instalado, clique em Sim e escolha a pasta World of Warcraft.`n`n" +
            "Se ainda não instalou, clique em Não, instale o WoW Forever pelo Battle.net, abra o jogo uma vez e depois dê dois cliques no INSTALAR de novo.") 'Question' 'YesNo'
        if ($r -eq 'Yes') {
            $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
            $dlg.Description = 'Escolha a pasta World of Warcraft'
            if ([string]$dlg.ShowDialog() -eq 'OK') {
                $sel = $dlg.SelectedPath.TrimEnd('\')
                if ((Split-Path -Leaf $sel) -ieq '_forever_') { $forever = $sel }
                elseif (Test-Path -LiteralPath (Join-Path $sel '_forever_') -PathType Container) { $forever = Join-Path $sel '_forever_' }
            }
        }
    }
    if (-not $forever) {
        [void](Avisar ("Sem a pasta do WoW Forever não dá para instalar.`n`n" +
            "Instale o jogo pelo Battle.net, abra uma vez e rode o INSTALAR de novo. Se o jogo já estiver instalado, chame o Guilherme.") 'Warning')
        exit 2
    }
    Write-Host "Jogo achado em: $forever"

    # 3. Jogo fechado
    while (Test-JogoAberto $forever) {
        if ($semJanela) { [void](Avisar 'O jogo está aberto. Feche o WoW e rode o INSTALAR de novo.' 'Warning'); exit 1 }
        $r = Avisar ("O jogo está aberto.`n`nFeche o WoW (inclusive a tela de escolher personagem) e clique em Tentar novamente.") 'Warning' 'RetryCancel'
        if ($r -ne 'Retry') { exit 1 }
    }

    # 4. Permissão de escrita (pede administrador só se precisar)
    $addons = Join-Path $forever 'Interface\AddOns'
    $podeEscrever = $false
    try {
        [void](New-Item -ItemType Directory -Path $addons -Force)
        $teste = Join-Path $addons ('.kitwow-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        [IO.File]::WriteAllText($teste, 'x')
        Remove-Item -LiteralPath $teste -Force
        $podeEscrever = $true
    } catch { }
    if (-not $podeEscrever) {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $admin = (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $admin -and $env:KITWOW_BAT -and -not $semJanela) {
            [void](Avisar "O Windows vai pedir permissão para mexer na pasta do jogo. Clique em Sim.")
            try { Start-Process -FilePath $env:KITWOW_BAT -Verb RunAs; exit 0 }
            catch { [void](Avisar 'Sem a permissão não dá para instalar. Rode o INSTALAR de novo e clique em Sim.' 'Warning'); exit 2 }
        }
        [void](Avisar "Não consegui gravar na pasta do jogo:`n$addons`n`nChame o Guilherme." 'Error')
        exit 3
    }

    # 5. Guarda o que vai ser trocado e instala
    $za = [IO.Compression.ZipFile]::OpenRead($pacote.Zip)
    try {
        $pastas = @($za.Entries | ForEach-Object { ($_.FullName -replace '\\', '/').Split('/')[0] } | Where-Object { $_ } | Sort-Object -Unique)
    } finally { $za.Dispose() }
    Write-Host ("Instalando {0} addons. Não feche esta janela..." -f $pastas.Count)
    $backup = Join-Path $forever ('Interface\AddOns-backup-' + (Get-Date -Format 'yyyy-MM-dd_HHmmss'))
    $guardadas = 0
    foreach ($p in $pastas) {
        $alvo = Join-Path $addons $p
        if (Test-Path -LiteralPath $alvo) {
            if (-not (Test-Path -LiteralPath $backup)) { [void](New-Item -ItemType Directory -Path $backup) }
            Move-Item -LiteralPath $alvo -Destination (Join-Path $backup $p)
            $guardadas++
        }
    }
    [IO.Compression.ZipFile]::ExtractToDirectory($pacote.Zip, $addons)

    # 6. Confere
    $faltando = @($pastas | Where-Object { -not (Get-ChildItem -LiteralPath (Join-Path $addons $_) -Filter '*.toc' -File -ErrorAction SilentlyContinue) })
    if ($faltando.Count -gt 0) {
        [void](Avisar ("Algo não ficou certo nestas pastas: " + ($faltando -join ', ') + "`n`nTire uma foto desta mensagem e mande para o Guilherme.") 'Error')
        exit 3
    }
    $msg = "Pronto! O kit foi instalado ({0} pastas de addon).`n`nAgora abra o jogo pelo Battle.net. Quando você entrar com o personagem, vai aparecer uma janela de boas-vindas explicando tudo." -f $pastas.Count
    if ($guardadas -gt 0) { $msg += "`n`nOs addons antigos com o mesmo nome foram guardados em:`n$backup" }
    # o exit dentro do Invoke-Expression (INSTALAR.bat) não roda o finally: limpa antes
    if ($pacote.Temp -and (Test-Path -LiteralPath $pacote.Temp)) { Remove-Item -LiteralPath $pacote.Temp -Recurse -Force -ErrorAction SilentlyContinue }
    [void](Avisar $msg)
    exit 0
} catch {
    [void](Avisar ("Deu um erro na instalação:`n`n" + $_.Exception.Message + "`n`nTire uma foto desta mensagem e mande para o Guilherme.") 'Error')
    exit 3
} finally {
    if ($pacote -and $pacote.Temp -and (Test-Path -LiteralPath $pacote.Temp)) { Remove-Item -LiteralPath $pacote.Temp -Recurse -Force -ErrorAction SilentlyContinue }
}
