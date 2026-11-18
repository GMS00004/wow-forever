<#
coletor-tarefa.ps1 - gera (e, se pedido, registra) a tarefa do Agendador "GMS WoW Precos Hora", que roda de hora
em hora, no minuto 50, o coletor coletar-foto.mjs sem janela:
  wscript.exe //B //Nologo "<esta pasta>\coletor-oculto.vbs" "<node>" "<esta pasta>\coletar-foto.mjs"
  -Simular (padrao): grava o XML em -Saida e imprime o que faria; nao toca no Agendador.
  -Registrar: registra ou substitui a tarefa, so se nao existir ou se a definicao difere.
  -Remover:   remove a tarefa.
  -Node:      caminho do node.exe (padrao C:\Program Files\nodejs\node.exe).
  -Saida:     pasta do XML gerado (padrao %TEMP%\gms-wow-precos).
Windows PowerShell 5.1. So ASCII.
#>
[CmdletBinding()]
param(
    [switch]$Simular,
    [switch]$Registrar,
    [switch]$Remover,
    [string]$Node = 'C:\Program Files\nodejs\node.exe',
    [string]$Saida = ''
)
$ErrorActionPreference = 'Stop'

function ConvertTo-Xml1 {
    param([string]$s)
    return [System.Security.SecurityElement]::Escape($s)
}

function New-Assinatura {
    # Esquema de comparacao: so os campos que importam (o Agendador acrescenta elementos padrao ao exportar).
    # StartBoundary e de proposito fora da assinatura: muda todo dia e nao altera a agenda.
    param([string]$XmlTexto)
    $x = New-Object System.Xml.XmlDocument
    $x.LoadXml($XmlTexto)
    $ns = New-Object System.Xml.XmlNamespaceManager($x.NameTable)
    $ns.AddNamespace('t', 'http://schemas.microsoft.com/windows/2004/02/mit/task')
    $p = New-Object System.Collections.ArrayList
    $cmd = $x.SelectSingleNode('//t:Actions/t:Exec/t:Command', $ns)
    $arg = $x.SelectSingleNode('//t:Actions/t:Exec/t:Arguments', $ns)
    [void]$p.Add('cmd=' + $(if ($cmd) { $cmd.InnerText } else { '' }) + ' ' + $(if ($arg) { $arg.InnerText } else { '' }))
    foreach ($g in @($x.SelectNodes('//t:Triggers/*', $ns))) {
        $f = @($g.LocalName)
        foreach ($nome in @('Interval', 'Duration', 'DaysInterval', 'Enabled')) {
            $n = $g.SelectSingleNode('.//t:' + $nome, $ns)
            if ($n) { $f += ($nome + '=' + ($n.InnerText -replace '\s+', ' ').Trim()) }
        }
        [void]$p.Add('gat=' + ($f -join ';'))
    }
    foreach ($nome in @('MultipleInstancesPolicy', 'DisallowStartIfOnBatteries', 'StopIfGoingOnBatteries', 'StartWhenAvailable', 'RunOnlyIfNetworkAvailable', 'Enabled', 'Hidden', 'WakeToRun', 'ExecutionTimeLimit', 'Priority')) {
        $n = $x.SelectSingleNode('//t:Settings/t:' + $nome, $ns)
        [void]$p.Add($nome + '=' + $(if ($n) { $n.InnerText.ToLowerInvariant() } else { '' }))
    }
    foreach ($nome in @('UserId', 'LogonType', 'RunLevel')) {
        $n = $x.SelectSingleNode('//t:Principals/t:Principal/t:' + $nome, $ns)
        [void]$p.Add($nome + '=' + $(if ($n) { $n.InnerText } else { '' }))
    }
    return ($p -join "`n")
}

function New-TarefaXml {
    param([string]$Usuario, [string]$Descricao, [string]$Argumentos, [string]$Inicio)
    $u = ConvertTo-Xml1 $Usuario
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-16"?>')
    [void]$sb.AppendLine('<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">')
    [void]$sb.AppendLine('  <RegistrationInfo>')
    [void]$sb.AppendLine('    <Description>' + (ConvertTo-Xml1 $Descricao) + '</Description>')
    [void]$sb.AppendLine('  </RegistrationInfo>')
    [void]$sb.AppendLine('  <Triggers>')
    [void]$sb.AppendLine('    <CalendarTrigger>')
    [void]$sb.AppendLine('      <Repetition>')
    [void]$sb.AppendLine('        <Interval>PT1H</Interval>')
    [void]$sb.AppendLine('        <Duration>P1D</Duration>')
    [void]$sb.AppendLine('        <StopAtDurationEnd>false</StopAtDurationEnd>')
    [void]$sb.AppendLine('      </Repetition>')
    [void]$sb.AppendLine('      <StartBoundary>' + $Inicio + '</StartBoundary>')
    [void]$sb.AppendLine('      <Enabled>true</Enabled>')
    [void]$sb.AppendLine('      <ScheduleByDay>')
    [void]$sb.AppendLine('        <DaysInterval>1</DaysInterval>')
    [void]$sb.AppendLine('      </ScheduleByDay>')
    [void]$sb.AppendLine('    </CalendarTrigger>')
    [void]$sb.AppendLine('  </Triggers>')
    [void]$sb.AppendLine('  <Principals>')
    [void]$sb.AppendLine('    <Principal id="Author">')
    [void]$sb.AppendLine('      <UserId>' + $u + '</UserId>')
    [void]$sb.AppendLine('      <LogonType>InteractiveToken</LogonType>')
    [void]$sb.AppendLine('      <RunLevel>LeastPrivilege</RunLevel>')
    [void]$sb.AppendLine('    </Principal>')
    [void]$sb.AppendLine('  </Principals>')
    [void]$sb.AppendLine('  <Settings>')
    [void]$sb.AppendLine('    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>')
    [void]$sb.AppendLine('    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>')
    [void]$sb.AppendLine('    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>')
    [void]$sb.AppendLine('    <StartWhenAvailable>true</StartWhenAvailable>')
    [void]$sb.AppendLine('    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>')
    [void]$sb.AppendLine('    <Enabled>true</Enabled>')
    [void]$sb.AppendLine('    <Hidden>false</Hidden>')
    [void]$sb.AppendLine('    <WakeToRun>false</WakeToRun>')
    [void]$sb.AppendLine('    <ExecutionTimeLimit>PT10M</ExecutionTimeLimit>')
    [void]$sb.AppendLine('    <Priority>7</Priority>')
    [void]$sb.AppendLine('  </Settings>')
    [void]$sb.AppendLine('  <Actions Context="Author">')
    [void]$sb.AppendLine('    <Exec>')
    [void]$sb.AppendLine('      <Command>wscript.exe</Command>')
    [void]$sb.AppendLine('      <Arguments>' + (ConvertTo-Xml1 $Argumentos) + '</Arguments>')
    [void]$sb.AppendLine('    </Exec>')
    [void]$sb.AppendLine('  </Actions>')
    [void]$sb.AppendLine('</Task>')
    return $sb.ToString()
}

try {
    if ($Registrar -and $Remover) { throw 'use -Registrar ou -Remover, nao os dois' }
    if ($Registrar) { $modo = 'Registrar' } elseif ($Remover) { $modo = 'Remover' } else { $modo = 'Simular' }
    if (-not $Saida) { $Saida = Join-Path $env:TEMP 'gms-wow-precos' }

    $nomeTarefa = 'GMS WoW Precos Hora'
    $vbs = Join-Path $PSScriptRoot 'coletor-oculto.vbs'
    $mjs = Join-Path $PSScriptRoot 'coletar-foto.mjs'
    $usuario = $env:USERDOMAIN + '\' + $env:USERNAME
    $descricao = 'Coleta de hora em hora da foto publica de precos do leilao do WoW Forever (coletar-foto.mjs)'
    $argumentos = '//B //Nologo "' + $vbs + '" "' + $Node + '" "' + $mjs + '"'
    $inicio = (Get-Date).Date.AddMinutes(50).ToString('s')

    $existe = Get-ScheduledTask -TaskName $nomeTarefa -ErrorAction SilentlyContinue

    if ($modo -eq 'Remover') {
        if ($existe) {
            Unregister-ScheduledTask -TaskName $nomeTarefa -Confirm:$false
            Write-Host 'REMOVIDA'
        } else {
            Write-Host 'NAO EXISTIA'
        }
        exit 0
    }

    if (-not (Test-Path -LiteralPath $Saida)) { New-Item -ItemType Directory -Path $Saida | Out-Null }
    $xml = New-TarefaXml -Usuario $usuario -Descricao $descricao -Argumentos $argumentos -Inicio $inicio
    $arq = Join-Path $Saida 'GMS-WoW-Precos-Hora.xml'
    [System.IO.File]::WriteAllText($arq, $xml, [System.Text.Encoding]::Unicode)

    $difere = $false
    if ($existe) {
        $difere = $true
        try { $difere = ((New-Assinatura $xml) -cne (New-Assinatura ([string](Export-ScheduledTask -TaskName $nomeTarefa)))) } catch { $difere = $true }
    }

    if ($modo -eq 'Simular') {
        Write-Host "TAREFA $nomeTarefa"
        Write-Host "ACAO wscript.exe $argumentos"
        Write-Host "XML $arq"
        Write-Host ('EXISTE ' + $(if ($existe) { 'sim' } else { 'nao' }))
        if ($existe) { Write-Host ('DIFERE ' + $(if ($difere) { 'sim' } else { 'nao' })) }
        exit 0
    }

    # -Registrar
    if ($existe -and -not $difere) {
        Write-Host 'IGUAL (nada feito)'
    } else {
        Register-ScheduledTask -TaskName $nomeTarefa -Xml (Get-Content -Raw -LiteralPath $arq) -Force | Out-Null
        Write-Host 'REGISTRADA'
    }
    exit 0
} catch {
    Write-Host ('ERRO ' + $_.Exception.Message)
    exit 1
}
