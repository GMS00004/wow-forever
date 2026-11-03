# Auditoria da pasta AddOns (contrato §9.3). So leitura; roda com o jogo aberto.
# Uso: addons-auditar.ps1 [-HashCompleto] mais -Raiz -Flavor -Instalacao -Estado -Backups (ver CONTRATO.md §3).
param(
    [switch]$HashCompleto,
    [string]$Raiz,
    [string]$Flavor,
    [string]$Instalacao,
    [string]$Estado,
    [string]$Backups
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'wow-comum.ps1')

# Alvo de uma junction, sem o prefixo \??\ que algumas APIs devolvem.
function Get-AlvoJunction {
    param([Parameter(Mandatory)][string]$Caminho)
    $alvo = $null
    try { $alvo = [string](@((Get-Item -LiteralPath $Caminho -Force).Target) | Select-Object -First 1) } catch { }
    if (-not $alvo) { return '(desconhecido)' }
    return ($alvo -replace '^\\\?\?\\', '')
}

function Test-MesmoCaminho {
    param([string]$A, [string]$B)
    if (-not $A -or -not $B) { return $false }
    $x = [IO.Path]::GetFullPath($A).TrimEnd('\')
    $y = [IO.Path]::GetFullPath($B).TrimEnd('\')
    return [string]::Equals($x, $y, [StringComparison]::OrdinalIgnoreCase)
}

exit (Invoke-ScriptWow {
    $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups
    $cli = Get-WowVersao -Raiz $ctx.Raiz -Flavor $ctx.Flavor
    if (-not $cli) { Stop-Wow PREREQ 'Não consegui ler a versão do cliente (.build.info / .flavor.info).' }

    $todos = @(Get-Manifestos -Contexto $ctx)
    $instalados = @($todos | Where-Object { $_.estadoInstalacao -eq 'instalado' })

    $pastasAddon = @()
    if (Test-Path -LiteralPath $ctx.AddOns -PathType Container) {
        $pastasAddon = @(Get-ChildItem -LiteralPath $ctx.AddOns -Directory -Force)
    }
    $nomesAddOns = @($pastasAddon | ForEach-Object { $_.Name })

    $contDesc = 0; $contFalt = 0; $contAlt = 0; $contInc = 0; $contDep = 0; $contJun = 0

    foreach ($d in $pastasAddon) {
        $caminho = $d.FullName
        $nome = $d.Name

        # 1. junction: so e aceita se casa com um manifesto dev instalado
        if (Test-Junction -Caminho $caminho) {
            $alvo = Get-AlvoJunction -Caminho $caminho
            $dev = @($instalados | Where-Object { $_.fonte -and $_.fonte.tipo -eq 'dev' -and (Test-MesmoCaminho $_.fonte.id $alvo) })
            if ($dev.Count -gt 0) { continue }
            Write-Linha "JUNCTION nome=$nome alvo=$alvo sem-manifesto"
            $contJun++
            continue
        }

        # 2. pasta sem dono (a assinatura so existe com manifesto; TOC e dependencias seguem valendo)
        $slug = Get-DonoDaPasta -Contexto $ctx -Nome $nome
        if (-not $slug) {
            Write-Linha "DESCONHECIDA nome=$nome"
            $contDesc++
        } else {
            $pm = @($instalados | Where-Object { $_.slug -eq $slug }) | Select-Object -First 1
            $pasta = @(@($pm.pastas) | Where-Object { $_.nome -ieq $nome }) | Select-Object -First 1

            # 3. assinatura (ou hash completo)
            if ($pasta) {
                if ($HashCompleto) {
                    $atual = Get-HashPasta -Pasta $caminho
                    $esperado = [string]$pasta.sha256
                } else {
                    $atual = Get-AssinaturaPasta -Pasta $caminho
                    $esperado = [string]$pasta.assinatura
                }
                if ($atual -ne $esperado) {
                    Write-Linha "ALTERADA slug=$slug nome=$nome"
                    $contAlt++
                }
            }
        }

        # 4. compatibilidade com o cliente
        $compat = Test-AddonForever -PastaAddon $caminho -Interface $cli.Interface
        $t = Get-TocDoForever -PastaAddon $caminho
        if (-not $compat.Compativel) {
            $tocNome = $compat.Toc
            if (-not $tocNome) { $tocNome = '(nenhum)' }
            $ints = '(nenhuma)'
            if ($t.Info -and @($t.Info.Interfaces).Count -gt 0) { $ints = (@($t.Info.Interfaces) -join ',') }
            Write-Linha "INCOMPATIVEL nome=$nome toc=$tocNome interfaces=$ints cliente=$($cli.Interface)"
            $contInc++
        }

        # 5. dependencias declaradas no TOC escolhido
        if ($t.Info) {
            foreach ($dep in @($t.Info.Dependencias)) {
                if ($nomesAddOns -notcontains $dep) {
                    Write-Linha "DEPENDENCIA nome=$nome requer=$dep"
                    $contDep++
                }
            }
        }
    }

    # pastas de manifesto instalado que sumiram do disco
    foreach ($m in $instalados) {
        foreach ($p in @($m.pastas)) {
            if (-not (Test-Path -LiteralPath (Join-Path $ctx.AddOns ([string]$p.nome)))) {
                Write-Linha "FALTANDO slug=$($m.slug) nome=$($p.nome)"
                $contFalt++
            }
        }
    }

    $total = $contDesc + $contFalt + $contAlt + $contInc + $contDep + $contJun
    Write-Linha ("AUDITORIA addons={0} desconhecidas={1} faltando={2} alteradas={3} incompativeis={4} dependencias={5} junctions={6}" -f $pastasAddon.Count, $contDesc, $contFalt, $contAlt, $contInc, $contDep, $contJun)
    if ($total -eq 0) { 0 } else { 1 }
})
