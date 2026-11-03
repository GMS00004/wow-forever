param(
    [string]$Pasta,
    [switch]$Remover,
    [switch]$Aplicar,
    [string]$Raiz,
    [string]$Flavor,
    [string]$Instalacao,
    [string]$Estado,
    [string]$Backups
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'wow-comum.ps1')

# dev-link.ps1: liga uma pasta de addon proprio a <AddOns> por junction (ou desliga). Contrato §9.5.
# Sem -Aplicar so mostra a previa. Os padroes (Raiz, Flavor, Estado, Backups, Instalacao) se resolvem em Get-WowContexto.

exit (Invoke-ScriptWow {
    if (-not $Pasta) { Stop-Wow PREREQ 'informe -Pasta <pasta do addon em addons-proprios>' }
    if (-not (Test-Path -LiteralPath $Pasta -PathType Container)) { Stop-Wow PREREQ "pasta do addon inexistente: $Pasta" }
    $origem = (Resolve-Path -LiteralPath $Pasta).ProviderPath.TrimEnd('\')
    $nome = [IO.Path]::GetFileName($origem)
    # slug do manifesto: minusculas, e qualquer caractere fora de [a-z0-9-] (ex.: "_", acento) vira "-"
    $slug = 'dev-' + (($nome.ToLowerInvariant() -replace '[^a-z0-9-]', '-') -replace '-{2,}', '-').Trim('-')
    if ($slug -notmatch '^dev-[a-z0-9-]+$') { Stop-Wow ERRO "nome de pasta sem letras ou numeros: $nome" }

    $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups
    $destino = Join-Path $ctx.AddOns $nome
    $toc = Get-TocDoForever -PastaAddon $origem
    if ($toc.Tipo -eq 'nenhum') { Stop-Wow RECUSA "pasta sem .toc, nao e um addon: $origem" }
    $atual = Get-Manifesto -Contexto $ctx -Slug $slug
    $ehDev = ($atual -and ($atual.fonte.tipo -eq 'dev'))

    if (-not $Remover) {
        $existe = Test-Path -LiteralPath $destino
        if ($existe -and (Test-Junction -Caminho $destino)) {
            if ($ehDev -and ($atual.estadoInstalacao -eq 'instalado') -and ([string]$atual.fonte.id -ieq $origem)) {
                Write-Linha "OK nada a fazer slug=$slug nome=$nome"
                return 0
            }
            Stop-Wow RECUSA "destino ja e junction sem o dev-link deste alvo: $destino"
        }
        if ($existe) { Stop-Wow RECUSA "destino $destino ja existe como pasta comum; nada foi alterado" }
        $dono = Get-DonoDaPasta -Contexto $ctx -Nome $nome
        if ($dono -and ($dono -ne $slug)) { Stop-Wow RECUSA "pasta $nome pertence ao addon $dono" }

        Write-Linha "DEV acao=ligar nome=$nome alvo=$origem"
        if (-not $Aplicar) { Write-Linha 'Prévia apenas; rode com -Aplicar para ligar.'; return 0 }
        Assert-JogoFechado -Raiz $ctx.Raiz

        if (-not (Test-Path -LiteralPath $ctx.AddOns)) { [void](New-Item -ItemType Directory -Path $ctx.AddOns -Force) }
        [void](New-Item -ItemType Junction -Path $destino -Target $origem)

        $agora = Get-AgoraIso
        $instaladoEm = $agora
        if ($ehDev -and $atual.instaladoEm) { $instaladoEm = [string]$atual.instaladoEm }
        $versao = 'dev'
        if ($toc.Info -and $toc.Info.Versao) { $versao = [string]$toc.Info.Versao }
        $interfaces = @()
        if ($toc.Info) { $interfaces = @($toc.Info.Interfaces) }
        $manifesto = [ordered]@{
            v                = 1
            slug             = $slug
            nome             = $nome
            versao           = $versao
            fonte            = [ordered]@{ tipo = 'dev'; id = $origem; asset = $null; pagina = $null }
            pastas           = @([ordered]@{
                nome       = $nome
                toc        = [IO.Path]::GetFileName($toc.Arquivo)
                interfaces = [int[]]$interfaces
                assinatura = (Get-AssinaturaPasta -Pasta $origem)
                sha256     = (Get-HashPasta -Pasta $origem)
            })
            aprovado         = $true
            estadoInstalacao = 'instalado'
            instaladoEm      = $instaladoEm
            atualizadoEm     = $agora
            removidoEm       = $null
            backupAnterior   = $null
            maquina          = $env:COMPUTERNAME
        }
        Save-Manifesto -Contexto $ctx -Manifesto $manifesto
        Add-Registro -Contexto $ctx -Acao 'dev-link' -Slug $slug -Detalhe "nome=$nome alvo=$origem"
        Write-Linha "OK ligado slug=$slug nome=$nome alvo=$origem"
        return 0
    }

    # ---- remover: so a junction; o alvo nunca e tocado
    $existe = Test-Path -LiteralPath $destino
    if ($existe -and (-not (Test-Junction -Caminho $destino))) {
        Stop-Wow RECUSA "destino $destino e pasta comum: dev-link so remove junction; nada foi alterado"
    }
    $ativo = ($ehDev -and ($atual.estadoInstalacao -eq 'instalado'))
    if ((-not $existe) -and (-not $ativo)) {
        Write-Linha "OK nada a fazer slug=$slug nome=$nome"
        return 0
    }
    $alvoTxt = '(sem manifesto)'
    if ($ehDev) { $alvoTxt = [string]$atual.fonte.id }
    Write-Linha "DEV acao=remover nome=$nome alvo=$alvoTxt"
    if (-not $Aplicar) { Write-Linha 'Prévia apenas; rode com -Aplicar para remover a junction (o alvo fica intacto).'; return 0 }
    Assert-JogoFechado -Raiz $ctx.Raiz

    if ($existe) { [System.IO.Directory]::Delete($destino) }
    if ($ativo) {
        $atual.estadoInstalacao = 'removido'
        $atual.removidoEm = Get-AgoraIso
        Save-Manifesto -Contexto $ctx -Manifesto $atual
    }
    Add-Registro -Contexto $ctx -Acao 'dev-unlink' -Slug $slug -Detalhe "nome=$nome alvo=$alvoTxt"
    Write-Linha "OK desligado slug=$slug nome=$nome"
    return 0
})
