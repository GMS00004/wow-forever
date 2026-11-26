# Jogador ativo deste PC (contrato §9.9): mostra, cria a partir de jogadores\_modelo ou troca o jogador ativo.
# Uso: jogador.ps1                               mostra o ativo e os disponíveis (só leitura)
#      jogador.ps1 -Novo <apelido> [-Aplicar]    cria jogadores\<apelido>\ a partir do modelo e passa a usá-lo
#      jogador.ps1 -Ativar <apelido> [-Aplicar]  passa a usar uma pasta de jogadores\ que já existe
# Sem -Aplicar, só mostra a prévia. Não toca na pasta do jogo.
param(
    [string]$Novo,
    [string]$Ativar,
    [switch]$Aplicar
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'wow-comum.ps1')

# Grava <repo>\jogador-ativo.txt (fora do git) com o apelido.
function Set-ArquivoJogadorAtivo {
    param([Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)][string]$Apelido)
    $texto = "# Jogador ativo deste PC (este arquivo fica fora do git). Troque com ferramentas\jogador.ps1 -Ativar <apelido>.`r`n$Apelido`r`n"
    [System.IO.File]::WriteAllText((Join-Path $Repo 'jogador-ativo.txt'), $texto, (New-Object System.Text.UTF8Encoding $false))
}

exit (Invoke-ScriptWow {
    if ($Novo -and $Ativar) { Stop-Wow RECUSA 'Use -Novo ou -Ativar, não os dois.' }
    $repo = Get-RaizRepo
    $jogadores = Join-Path $repo 'jogadores'
    $modelo = Join-Path $jogadores '_modelo'
    $atual = Get-JogadorAtivo
    $antes = '(nenhum)'
    if ($atual) { $antes = $atual.Apelido }

    # Sem -Novo nem -Ativar: só mostra.
    if (-not $Novo -and -not $Ativar) {
        if ($atual) { Write-Linha "JOGADOR ativo=$($atual.Apelido) pasta=$($atual.Pasta)" }
        else { Write-Linha 'JOGADOR ausente' }
        $disponiveis = @()
        if (Test-Path -LiteralPath $jogadores -PathType Container) {
            $disponiveis = @(Get-ChildItem -LiteralPath $jogadores -Directory | Where-Object { $_.Name -notlike '_*' } | ForEach-Object { $_.Name } | Sort-Object)
        }
        $lista = '(nenhum)'
        if ($disponiveis.Count -gt 0) { $lista = $disponiveis -join ',' }
        Write-Linha "JOGADORES disponiveis=$lista"
        return 0
    }

    $pedido = $Novo
    if ($Ativar) { $pedido = $Ativar }
    $apelido = $pedido.Trim().ToLowerInvariant()
    if ($apelido -notmatch '^[a-z0-9][a-z0-9-]{1,29}$') {
        Stop-Wow RECUSA "Apelido inválido: '$pedido' (de 2 a 30 letras minúsculas, números ou hífen, sem espaço nem acento)"
    }
    $destino = Join-Path $jogadores $apelido

    if ($Novo) {
        if (Test-Path -LiteralPath $destino) { Stop-Wow RECUSA "Já existe jogadores\$apelido; para usar essa pasta, rode com -Ativar $apelido" }
        if (-not (Test-Path -LiteralPath $modelo -PathType Container)) { Stop-Wow PREREQ "Modelo ausente: $modelo" }
        $arquivos = @(Get-ChildItem -LiteralPath $modelo -Recurse -File | ForEach-Object { $_.FullName.Substring($modelo.Length).TrimStart('\') } | Sort-Object)
        foreach ($a in $arquivos) { Write-Linha "ARQUIVO jogadores\$apelido\$a" }
        if (-not $Aplicar) {
            Write-Linha "PREVIA criar=jogadores\$apelido arquivos=$($arquivos.Count) ativo=$apelido antes=$antes"
            return 0
        }
        Copy-Item -LiteralPath $modelo -Destination $destino -Recurse
        Set-ArquivoJogadorAtivo -Repo $repo -Apelido $apelido
        Add-Registro -Contexto ([pscustomobject]@{ Registro = (Join-Path $destino 'estado\registro.md') }) -Acao 'jogador-novo' -Slug $apelido -Detalhe "criado a partir do modelo; antes=$antes"
        Write-Linha "CRIADO jogador=$apelido pasta=$destino arquivos=$($arquivos.Count)"
        Write-Linha "ATIVO jogador=$apelido antes=$antes"
        return 0
    }

    # -Ativar
    if (-not (Test-Path -LiteralPath $destino -PathType Container)) { Stop-Wow RECUSA "Não existe jogadores\$apelido; para criar, rode com -Novo $apelido" }
    if ($atual -and $atual.Apelido -eq $apelido) { Write-Linha "NADA jogador=$apelido motivo=ja-ativo"; return 0 }
    if (-not $Aplicar) {
        Write-Linha "PREVIA ativo=$apelido antes=$antes"
        return 0
    }
    Set-ArquivoJogadorAtivo -Repo $repo -Apelido $apelido
    Add-Registro -Contexto ([pscustomobject]@{ Registro = (Join-Path $destino 'estado\registro.md') }) -Acao 'jogador-ativar' -Slug $apelido -Detalhe "antes=$antes"
    Write-Linha "ATIVO jogador=$apelido antes=$antes"
    return 0
})
