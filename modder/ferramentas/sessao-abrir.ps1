# Abertura de sessao (contrato §9.8): jogador ativo, instalacao, jogo, backup do WTF, atualizacao dos aprovados e auditoria.
# Uso: sessao-abrir.ps1 mais -Raiz -Flavor -Instalacao -Estado -Backups (ver CONTRATO.md §3).
param(
    [string]$Raiz,
    [string]$Flavor,
    [string]$Instalacao,
    [string]$Estado,
    [string]$Backups
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'wow-comum.ps1')

$wtfBackup = Join-Path $PSScriptRoot 'wtf-backup.ps1'
$atualizar = Join-Path $PSScriptRoot 'addon-atualizar.ps1'
$auditar = Join-Path $PSScriptRoot 'addons-auditar.ps1'

# Parametros comuns recebidos, repassados aos filhos (o que nao veio fica para o filho resolver).
$argsComuns = @()
if ($Raiz) { $argsComuns += @('-Raiz', $Raiz) }
if ($Flavor) { $argsComuns += @('-Flavor', $Flavor) }
if ($Instalacao) { $argsComuns += @('-Instalacao', $Instalacao) }
if ($Estado) { $argsComuns += @('-Estado', $Estado) }
if ($Backups) { $argsComuns += @('-Backups', $Backups) }

# Roda um script deste conjunto como processo filho e devolve as linhas e o codigo (contrato §1.10).
function Invoke-Filho {
    param([Parameter(Mandatory)][string]$Script, [string[]]$Argumentos = @())
    $antes = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $saida = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Script @Argumentos 2>&1
        $codigo = $LASTEXITCODE
    } finally { $ErrorActionPreference = $antes }
    return [pscustomobject]@{ Linhas = @($saida | ForEach-Object { [string]$_ }); Codigo = $codigo }
}

# Motivo de uma falha numa linha curta (sem o prefixo PREREQ/RECUSA/ERRO).
function Get-MotivoCurto {
    param($Erro)
    $m = [string]$Erro.Exception.Message
    $m = $m -replace '^(PREREQ|RECUSA|ERRO): ', ''
    return (($m -replace '\s+', ' ').Trim())
}

exit (Invoke-ScriptWow {
    # 0. jogador ativo (so quando o estado ou a instalacao vem do padrao)
    if (-not $Estado -or -not $Instalacao) {
        $jog = Get-JogadorAtivo
        if (-not $jog -and -not $Estado) {
            Write-Linha 'JOGADOR ausente motivo=sem-jogador-ativo (crie com ferramentas\jogador.ps1 -Novo <apelido> -Aplicar)'
            return 2
        }
        if ($jog) { Write-Linha "JOGADOR ativo=$($jog.Apelido) pasta=$($jog.Pasta)" }
    }

    # 1. instalacao
    $ctx = $null
    try {
        $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups
    } catch {
        Write-Linha ('INSTALACAO ausente ' + (Get-MotivoCurto $_))
        return 2
    }
    $cli = Get-WowVersao -Raiz $ctx.Raiz -Flavor $ctx.Flavor
    if (-not $cli) {
        Write-Linha 'INSTALACAO ausente versao do cliente nao lida (.build.info / .flavor.info)'
        return 2
    }

    # 2. a Interface mudou desde a ultima sessao?
    $sessaoAnt = Get-SessaoJson -Contexto $ctx
    $mudou = $false
    $anterior = $null
    if ($sessaoAnt -and $sessaoAnt.PSObject.Properties['ultimaInterface']) {
        $anterior = [int]$sessaoAnt.ultimaInterface
        if ($anterior -ne [int]$cli.Interface) { $mudou = $true }
    }
    $mudouTxt = 'nao'
    if ($mudou) { $mudouTxt = 'sim' }
    $linhaInst = "INSTALACAO ok raiz=$($ctx.Raiz) flavor=$($ctx.Flavor) versao=$($cli.Versao) interface=$($cli.Interface) mudou=$mudouTxt"
    if ($mudou) { $linhaInst += " anterior=$anterior" }
    Write-Linha $linhaInst

    # 3. jogo
    $aberto = Test-JogoAberto -Raiz $ctx.Raiz
    if ($aberto) { Write-Linha 'JOGO aberto' } else { Write-Linha 'JOGO fechado' }

    $falhou = 0
    if ($aberto) {
        Write-Linha 'ATUALIZACAO adiada motivo=jogo-aberto'
    } else {
        # 4a. backup do WTF antes de qualquer mudanca
        $bk = Invoke-Filho -Script $wtfBackup -Argumentos (@('-Rotulo', 'abertura-de-sessao') + $argsComuns)
        if ($bk.Codigo -eq 0) {
            foreach ($l in $bk.Linhas) { if ($l -like 'BACKUP *') { Write-Linha $l } }
        } elseif ($bk.Codigo -eq 2) {
            Write-Linha 'BACKUP sem-wtf'
        } else {
            foreach ($l in $bk.Linhas) { Write-Linha $l }
            Write-Linha 'ATUALIZACAO adiada motivo=backup-falhou'
            $falhou++
        }

        # 4b. atualizacao dos aprovados (so se o backup nao falhou)
        if ($bk.Codigo -eq 0 -or $bk.Codigo -eq 2) {
            $at = Invoke-Filho -Script $atualizar -Argumentos (@('-Aplicar') + $argsComuns)
            if ($at.Codigo -eq 0 -or $at.Codigo -eq 1) {
                foreach ($l in $at.Linhas) {
                    if ($l -match '^(ATUALIZADO|FALHOU|MANUAL) ') { Write-Linha $l }
                }
                $falhou += @($at.Linhas | Where-Object { $_ -match '^FALHOU ' }).Count
            } else {
                foreach ($l in $at.Linhas) { Write-Linha $l }
                $falhou++
            }
        }
    }

    # 5. auditoria (roda com o jogo aberto ou fechado)
    $aud = Invoke-Filho -Script $auditar -Argumentos $argsComuns
    foreach ($l in $aud.Linhas) { Write-Linha $l }

    # 6. registro da sessao
    Save-SessaoJson -Contexto $ctx -Dados ([ordered]@{
        v               = 1
        ultimaInterface = [int]$cli.Interface
        ultimaVersao    = [string]$cli.Versao
        ultimaAbertura  = (Get-AgoraIso)
    })

    # 7. codigo
    if ($falhou -eq 0 -and $aud.Codigo -eq 0) { 0 } else { 1 }
})
