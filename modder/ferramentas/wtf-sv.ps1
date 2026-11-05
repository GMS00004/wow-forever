# Muda valores em arquivos de SavedVariables (Lua gerado pelo jogo) (contrato §9.4). Sem -Aplicar, so imprime a previa.
# Uso: wtf-sv.ps1 -Arquivo <nome.lua> -Valores '<caminho>=<valor>;<caminho>=<valor>' [-Aplicar] mais -Raiz -Flavor -Instalacao -Estado -Backups (ver CONTRATO.md §3).
# Caminho: nomes separados por ponto, comecando pela tabela global (LeaPlusDB.AutoSellJunk, RXPSettings.profiles.*.chave); '*' vale para todas as chaves existentes do nivel.
# Valor: "texto" ou 'texto' (string Lua; o conteudo vai como esta, entao escape \" e \\ se precisar), true/false, numero.
param(
    [string]$Arquivo,
    [string]$Valores,
    [switch]$Aplicar,
    [string]$Raiz,
    [string]$Flavor,
    [string]$Instalacao,
    [string]$Estado,
    [string]$Backups
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'wow-comum.ps1')

# Leitor de Lua so para achar o valor certo: acompanha as chaves {} ignorando strings e comentarios. Nao interpreta nada, so devolve posicoes.
if (-not ('LuaSv' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Text;

public class SvEntry {
    public string Key; public int Start; public int End; public int ValStart; public int ValEnd;
    public char Kind; public List<SvEntry> Kids; public int Close;
}
public class SvResult {
    public string Text; public string Tipo; public string Erro;
    public List<string> Paths = new List<string>(); public List<string> Atuais = new List<string>();
}
public static class LuaSv {
    class Edit { public int Pos; public int Len; public string Txt; public int Ord; }

    static int LongOpen(string t, int p) {
        if (p >= t.Length || t[p] != '[') return -1;
        int q = p + 1; int lvl = 0;
        while (q < t.Length && t[q] == '=') { lvl++; q++; }
        if (q < t.Length && t[q] == '[') return lvl;
        return -1;
    }
    static int LongEnd(string t, int p, int lvl) {
        string fim = "]" + new string('=', lvl) + "]";
        int i = t.IndexOf(fim, p + lvl + 2, StringComparison.Ordinal);
        if (i < 0) throw new FormatException("bloco longo sem fim em " + p);
        return i + fim.Length;
    }
    static void SkipWs(string t, ref int p) {
        while (p < t.Length) {
            char c = t[p];
            if (c == ' ' || c == '\t' || c == '\r' || c == '\n') { p++; }
            else if (c == '-' && p + 1 < t.Length && t[p + 1] == '-') {
                p += 2;
                int lvl = LongOpen(t, p);
                if (lvl >= 0) { p = LongEnd(t, p, lvl); }
                else { while (p < t.Length && t[p] != '\n') p++; }
            } else break;
        }
    }
    static string ReadQuoted(string t, ref int p) {
        char q = t[p]; p++;
        StringBuilder sb = new StringBuilder();
        while (p < t.Length) {
            char c = t[p];
            if (c == '\\') {
                if (p + 1 >= t.Length) break;
                char d = t[p + 1];
                if (d >= '0' && d <= '9') {
                    int v = 0, n = 0, r = p + 1;
                    while (r < t.Length && n < 3 && t[r] >= '0' && t[r] <= '9') { v = v * 10 + (t[r] - '0'); r++; n++; }
                    sb.Append((char)v); p = r; continue;
                }
                if (d == 'n') sb.Append('\n'); else if (d == 't') sb.Append('\t'); else if (d == 'r') sb.Append('\r'); else sb.Append(d);
                p += 2; continue;
            }
            if (c == q) { p++; return sb.ToString(); }
            sb.Append(c); p++;
        }
        throw new FormatException("string sem fim");
    }
    static void ParseValue(string t, ref int p, SvEntry e) {
        if (p >= t.Length) throw new FormatException("valor ausente no fim do arquivo");
        e.ValStart = p;
        char c = t[p];
        if (c == '{') {
            e.Kind = 't'; p++;
            e.Kids = ParseEntries(t, ref p, false);
            if (p >= t.Length || t[p] != '}') throw new FormatException("tabela sem fim");
            e.Close = p; p++;
        } else if (c == '"' || c == '\'') {
            e.Kind = 's'; ReadQuoted(t, ref p);
        } else if (LongOpen(t, p) >= 0) {
            e.Kind = 's'; p = LongEnd(t, p, LongOpen(t, p));
        } else {
            e.Kind = 'o';
            while (p < t.Length) {
                char d = t[p];
                if (d == ',' || d == ';' || d == '}' || d == ' ' || d == '\t' || d == '\r' || d == '\n') break;
                if (d == '-' && p + 1 < t.Length && t[p + 1] == '-') break;
                p++;
            }
            if (p == e.ValStart) throw new FormatException("valor vazio em " + p);
        }
        e.ValEnd = p;
    }
    static List<SvEntry> ParseEntries(string t, ref int p, bool top) {
        List<SvEntry> lista = new List<SvEntry>();
        int idx = 0;
        while (true) {
            SkipWs(t, ref p);
            if (p >= t.Length) { if (top) break; throw new FormatException("tabela sem fim"); }
            if (t[p] == '}') { if (top) throw new FormatException("} sobrando em " + p); break; }
            SvEntry e = new SvEntry();
            e.Start = p;
            bool achouChave = false;
            if (t[p] == '[' && LongOpen(t, p) < 0) {
                p++; SkipWs(t, ref p);
                if (p < t.Length && (t[p] == '"' || t[p] == '\'')) { e.Key = ReadQuoted(t, ref p); }
                else { int s = p; while (p < t.Length && t[p] != ']') p++; e.Key = t.Substring(s, p - s).Trim(); }
                SkipWs(t, ref p);
                if (p >= t.Length || t[p] != ']') throw new FormatException("chave sem ] em " + p);
                p++; SkipWs(t, ref p);
                if (p >= t.Length || t[p] != '=') throw new FormatException("chave sem = em " + p);
                p++; SkipWs(t, ref p);
                achouChave = true;
            } else if (char.IsLetter(t[p]) || t[p] == '_') {
                int s = p;
                while (p < t.Length && (char.IsLetterOrDigit(t[p]) || t[p] == '_')) p++;
                string id = t.Substring(s, p - s);
                SkipWs(t, ref p);
                if (p < t.Length && t[p] == '=' && !(p + 1 < t.Length && t[p + 1] == '=')) {
                    p++; SkipWs(t, ref p); e.Key = id; achouChave = true;
                } else { p = s; }
            }
            if (!achouChave) { idx++; e.Key = idx.ToString(); }
            ParseValue(t, ref p, e);
            e.End = p;
            lista.Add(e);
            SkipWs(t, ref p);
            if (p < t.Length && (t[p] == ',' || t[p] == ';')) p++;
        }
        return lista;
    }

    static string Cam(string prefix, string seg) { return prefix.Length == 0 ? seg : prefix + "." + seg; }

    static string Visita(string t, SvEntry e, string cam, string[] segs, int i, string val, string eol, List<Edit> edits, SvResult r) {
        if (i == segs.Length - 1) {
            if (e.Kind == 't') return "o valor em " + cam + " e uma tabela; nao sera trocado";
            Edit ed = new Edit(); ed.Pos = e.ValStart; ed.Len = e.ValEnd - e.ValStart; ed.Txt = val; ed.Ord = edits.Count;
            edits.Add(ed);
            r.Paths.Add(cam); r.Atuais.Add(t.Substring(e.ValStart, e.ValEnd - e.ValStart));
            return null;
        }
        if (e.Kind != 't') return cam + " nao e tabela";
        return Walk(t, e.Kids, e, segs, i + 1, cam, val, eol, edits, r);
    }

    static string Walk(string t, List<SvEntry> lista, SvEntry pai, string[] segs, int i, string prefix, string val, string eol, List<Edit> edits, SvResult r) {
        string seg = segs[i]; bool ultimo = (i == segs.Length - 1);
        if (seg == "*") {
            foreach (SvEntry e in lista) {
                if (ultimo && e.Kind == 't') continue;
                if (!ultimo && e.Kind != 't') continue;
                string err = Visita(t, e, Cam(prefix, e.Key), segs, i, val, eol, edits, r);
                if (err != null) return err;
            }
            return null;
        }
        SvEntry achou = null;
        foreach (SvEntry e in lista) { if (e.Key == seg) { achou = e; break; } }
        string cam = Cam(prefix, seg);
        if (achou != null) return Visita(t, achou, cam, segs, i, val, eol, edits, r);
        if (!ultimo) return "caminho intermediario ausente: " + cam;
        if (pai == null) return "tabela global ausente: " + cam;
        Inserir(t, pai, seg, val, eol, edits);
        r.Paths.Add(cam); r.Atuais.Add(null);
        return null;
    }

    static void Inserir(string t, SvEntry pai, string seg, string val, string eol, List<Edit> edits) {
        string kv = "[\"" + seg.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"] = " + val + ",";
        int close = pai.Close;
        int ls = close; while (ls > 0 && t[ls - 1] != '\n') ls--;
        string fechaIndent = t.Substring(ls, close - ls);
        bool multilinha = fechaIndent.Trim().Length == 0;
        if (pai.Kids.Count > 0) {
            SvEntry u = pai.Kids[pai.Kids.Count - 1];
            string entre = t.Substring(u.End, close - u.End);
            if (entre.IndexOf(',') < 0 && entre.IndexOf(';') < 0) {
                Edit v = new Edit(); v.Pos = u.End; v.Len = 0; v.Txt = ","; v.Ord = edits.Count; edits.Add(v);
            }
        }
        Edit ed = new Edit(); ed.Len = 0; ed.Ord = edits.Count;
        if (multilinha) {
            string indent = fechaIndent;
            if (pai.Kids.Count > 0) {
                SvEntry u = pai.Kids[pai.Kids.Count - 1];
                int lk = u.Start; while (lk > 0 && t[lk - 1] != '\n') lk--;
                string pre = t.Substring(lk, u.Start - lk);
                if (pre.Trim().Length == 0) indent = pre;
            }
            ed.Pos = ls; ed.Txt = indent + kv + eol;
        } else {
            ed.Pos = close; ed.Txt = " " + kv;
        }
        edits.Add(ed);
    }

    public static SvResult Aplicar(string text, string path, string luaVal) {
        SvResult r = new SvResult(); r.Text = text;
        try {
            string[] segs = path.Split('.');
            if (segs.Length < 2) { r.Tipo = "ERRO"; r.Erro = "caminho precisa ser tabela.chave: " + path; return r; }
            foreach (string s in segs) { if (s.Length == 0) { r.Tipo = "ERRO"; r.Erro = "caminho com nome vazio: " + path; return r; } }
            int p = 0;
            List<SvEntry> raiz = ParseEntries(text, ref p, true);
            List<Edit> edits = new List<Edit>();
            string eol = text.Contains("\r\n") ? "\r\n" : "\n";
            string err = Walk(text, raiz, null, segs, 0, "", luaVal, eol, edits, r);
            if (err == null && r.Paths.Count == 0) err = "o caminho nao casa com nada: " + path;
            if (err != null) { r.Tipo = "RECUSA"; r.Erro = err; return r; }
            edits.Sort(delegate (Edit a, Edit b) { return a.Pos != b.Pos ? b.Pos.CompareTo(a.Pos) : b.Ord.CompareTo(a.Ord); });
            StringBuilder sb = new StringBuilder(text);
            foreach (Edit e in edits) { sb.Remove(e.Pos, e.Len); sb.Insert(e.Pos, e.Txt); }
            r.Text = sb.ToString();
        } catch (FormatException ex) {
            r.Tipo = "ERRO"; r.Erro = "Lua inesperado: " + ex.Message;
        }
        return r;
    }
}
'@
}

# Separa 'caminho=valor;caminho=valor' respeitando aspas (o ';' dentro de "..." ou '...' nao separa).
function Split-ParesSv {
    param([string]$Texto)
    $itens = New-Object System.Collections.Generic.List[string]
    $sb = New-Object System.Text.StringBuilder
    $q = [char]0
    for ($i = 0; $i -lt $Texto.Length; $i++) {
        $c = $Texto[$i]
        if ($q -ne [char]0) {
            [void]$sb.Append($c)
            if ($c -eq '\' -and ($i + 1) -lt $Texto.Length) { $i++; [void]$sb.Append($Texto[$i]) }
            elseif ($c -eq $q) { $q = [char]0 }
        } elseif ($c -eq '"' -or $c -eq "'") {
            $q = $c; [void]$sb.Append($c)
        } elseif ($c -eq ';') {
            $itens.Add($sb.ToString()); [void]$sb.Clear()
        } else { [void]$sb.Append($c) }
    }
    if ($q -ne [char]0) { Stop-Wow ERRO 'aspas sem fechar em -Valores' }
    $itens.Add($sb.ToString())
    return $itens.ToArray()
}

# Valor da linha de comando para o literal Lua.
function ConvertTo-ValorLua {
    param([string]$V)
    $V = $V.Trim()
    if ($V.Length -ge 2 -and $V.StartsWith('"') -and $V.EndsWith('"')) { return $V }
    if ($V.Length -ge 2 -and $V.StartsWith("'") -and $V.EndsWith("'")) {
        return '"' + $V.Substring(1, $V.Length - 2).Replace('"', '\"') + '"'
    }
    if ($V -ceq 'true' -or $V -ceq 'false') { return $V }
    if ($V -match '^-?\d+(\.\d+)?$') { return $V }
    Stop-Wow ERRO "valor inválido (use ""texto"", true, false ou número): $V"
}

exit (Invoke-ScriptWow {
    if (-not $Arquivo) { Stop-Wow ERRO 'falta -Arquivo (nome do .lua em SavedVariables)' }
    if (-not $Valores) { Stop-Wow ERRO "falta -Valores (use 'caminho=valor;caminho=valor')" }
    if ($Arquivo -ne [IO.Path]::GetFileName($Arquivo)) { Stop-Wow ERRO "-Arquivo é só o nome do arquivo, sem pasta: $Arquivo" }

    $pares = New-Object System.Collections.ArrayList
    foreach ($par in @(Split-ParesSv $Valores)) {
        if (-not $par.Trim()) { continue }
        $i = $par.IndexOf('=')
        if ($i -lt 1) { Stop-Wow ERRO "par inválido (use caminho=valor): $par" }
        [void]$pares.Add([pscustomobject]@{ Caminho = $par.Substring(0, $i).Trim(); Lua = (ConvertTo-ValorLua $par.Substring($i + 1)) })
    }
    if ($pares.Count -eq 0) { Stop-Wow ERRO 'nenhum par caminho=valor em -Valores' }

    $ctx = Get-WowContexto -Raiz $Raiz -Flavor $Flavor -Instalacao $Instalacao -Estado $Estado -Backups $Backups
    $contas = Join-Path $ctx.WTF 'Account'
    $dirsConta = @()
    if (Test-Path -LiteralPath $contas -PathType Container) { $dirsConta = @(Get-ChildItem -LiteralPath $contas -Directory) }
    if ($dirsConta.Count -eq 0) { Stop-Wow PREREQ 'nenhuma conta em WTF\Account: entre no jogo uma vez' }
    if ($dirsConta.Count -gt 1) { Stop-Wow PREREQ ('mais de uma conta em WTF\Account (' + (($dirsConta | ForEach-Object { $_.Name }) -join ', ') + '): o script só trabalha com uma') }
    $alvo = Join-Path (Join-Path $dirsConta[0].FullName 'SavedVariables') $Arquivo
    if (-not (Test-Path -LiteralPath $alvo -PathType Leaf)) { Stop-Wow PREREQ "arquivo não existe: $alvo" }

    # Texto exato do arquivo (codificacao e quebras de linha como estao).
    $arq = Read-TextoPreservando -Path $alvo
    $bytes = [IO.File]::ReadAllBytes($alvo)
    $off = 0
    if ($arq.Bom) { $off = $arq.Encoding.GetPreamble().Length }
    $texto = $arq.Encoding.GetString($bytes, $off, $bytes.Length - $off)

    $linhas = New-Object System.Collections.ArrayList
    $alteradas = 0
    foreach ($p in $pares) {
        $r = [LuaSv]::Aplicar($texto, $p.Caminho, $p.Lua)
        if ($r.Erro) { Stop-Wow $r.Tipo ("{0}: {1} (arquivo {2})" -f $p.Caminho, $r.Erro, $Arquivo) }
        $texto = $r.Text
        for ($k = 0; $k -lt $r.Paths.Count; $k++) {
            $at = '(ausente)'
            if ($null -ne $r.Atuais[$k]) { $at = $r.Atuais[$k] }
            [void]$linhas.Add("SV arquivo=$Arquivo caminho=$($r.Paths[$k]) atual=$at novo=$($p.Lua)")
            $alteradas++
        }
    }
    foreach ($l in $linhas) { Write-Linha $l }

    if (-not $Aplicar) {
        Write-Linha 'Prévia apenas; rode com -Aplicar para gravar.'
    } else {
        Assert-JogoFechado -Raiz $ctx.Raiz

        # backup do WTF inteiro antes de gravar (como o sessao-abrir.ps1), como processo filho
        $argsBk = @('-Rotulo', 'antes-de-sv')
        if ($Raiz) { $argsBk += @('-Raiz', $Raiz) }
        if ($Flavor) { $argsBk += @('-Flavor', $Flavor) }
        if ($Instalacao) { $argsBk += @('-Instalacao', $Instalacao) }
        if ($Estado) { $argsBk += @('-Estado', $Estado) }
        if ($Backups) { $argsBk += @('-Backups', $Backups) }
        $antesEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $saidaBk = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'wtf-backup.ps1') @argsBk 2>&1
            $codigoBk = $LASTEXITCODE
        } finally { $ErrorActionPreference = $antesEap }
        $linhaBk = @($saidaBk | ForEach-Object { [string]$_ } | Where-Object { $_ -like 'BACKUP *' })
        if ($codigoBk -ne 0) { Stop-Wow ERRO ("backup do WTF falhou (código $codigoBk): " + (@($saidaBk | ForEach-Object { [string]$_ }) -join ' | ')) }
        foreach ($l in $linhaBk) { Write-Linha $l }

        [byte[]]$pre = New-Object byte[] 0
        if ($arq.Bom) { $pre = $arq.Encoding.GetPreamble() }
        $corpo = $arq.Encoding.GetBytes($texto)
        $saida = New-Object byte[] ($pre.Length + $corpo.Length)
        [Array]::Copy($pre, 0, $saida, 0, $pre.Length)
        [Array]::Copy($corpo, 0, $saida, $pre.Length, $corpo.Length)
        [IO.File]::WriteAllBytes($alvo, $saida)

        Add-Registro -Contexto $ctx -Acao 'sv' -Slug '-' -Detalhe ("arquivo=$Arquivo alteradas=$alteradas caminhos=" + (($pares | ForEach-Object { $_.Caminho }) -join ','))
        Write-Linha "OK sv arquivo=$Arquivo alteradas=$alteradas"
    }
    0
})
