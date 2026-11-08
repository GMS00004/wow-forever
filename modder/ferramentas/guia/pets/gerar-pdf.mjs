#!/usr/bin/env node
// Gera o PDF do guia de habilidades de pet (guia.json) para celular.
// Uso: node gerar-pdf.mjs [--json guia.json] [--html saida.html] [--pdf saida.pdf]
// Sem dependencias. Imprime o HTML pelo Microsoft Edge sem tela.

import { readFileSync, writeFileSync, mkdirSync, rmSync, statSync, existsSync } from 'node:fs';
import { spawn } from 'node:child_process';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const AQUI = dirname(fileURLToPath(import.meta.url));
const PADRAO = {
  json: join(AQUI, 'guia.json'),
  html: join(tmpdir(), 'guia-pets-cacador.html'),
  pdf: 'P:\\Meu Drive\\WoW Forever\\Guias\\guia-pets-cacador.pdf',
};
const EDGE = [
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
];
const ESPERA_MAX_MS = 180000;

function lerArgs(argv) {
  const out = { ...PADRAO };
  for (let i = 0; i < argv.length; i += 2) {
    const chave = argv[i];
    const valor = argv[i + 1];
    if (!['--json', '--html', '--pdf'].includes(chave) || valor === undefined) {
      throw new Error(`argumento invalido: "${chave ?? ''}" (use --json, --html, --pdf, cada um com valor)`);
    }
    out[chave.slice(2)] = valor;
  }
  return out;
}

const esc = (v) =>
  String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
const txt = (v) => (v === null || v === undefined || v === '' ? '-' : esc(v));
const lista = (arr) => (Array.isArray(arr) && arr.length ? arr.map(esc).join(', ') : '-');
const ordenaSaltii = (ps) => [...(ps ?? [])].sort((a, b) => Number(!!b.s) - Number(!!a.s));
const marcaSaltii = (p) => (p.s ? ' <span class="src">(Saltii)</span>' : '');

const CSS = `
@page { size: 125mm 260mm; margin: 6mm; }
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body { font-family: Arial, Helvetica, sans-serif; font-size: 10.5pt; line-height: 1.3; color: #111; background: #fff; }
h1 { font-size: 20pt; margin: 0 0 3mm; }
h2 { font-size: 14pt; margin: 0 0 2mm; border-bottom: 0.6pt solid #333; padding-bottom: 1mm; }
h3 { font-size: 11.5pt; margin: 4mm 0 1.5mm; }
h4 { font-size: 10.5pt; margin: 3mm 0 1mm; }
p { margin: 1mm 0 2mm; }
ul { margin: 1mm 0 2mm 4mm; padding: 0; }
li { margin-bottom: 1.2mm; }
.cover { padding-top: 60mm; }
.cover p { font-size: 11pt; color: #444; margin: 1mm 0; }
.new { break-before: page; page-break-before: always; }
.src { color: #777; font-size: 8.5pt; }
.muted { color: #777; }
.meta { color: #333; font-size: 9.5pt; }
table { width: 100%; border-collapse: collapse; font-size: 9pt; margin: 1mm 0 2mm; }
th, td { border-bottom: 0.4pt solid #bbb; padding: 0.8mm 1mm; text-align: left; vertical-align: top; }
th { background: #eee; font-weight: bold; }
thead { display: table-header-group; }
tr { break-inside: avoid; page-break-inside: avoid; }
td div { margin: 0 0 0.6mm; }
`;

function renderCapa(g) {
  return `<section class="cover">
<h1>Hunter Pet Abilities - WoW Forever</h1>
<p>Generated: ${txt(g.gerado)}</p>
<p>Build: ${txt(g.build)}</p>
</section>`;
}

function renderRegras(g) {
  const regras = g.regras ?? [];
  const corpo = regras.length
    ? `<ul>${regras.map((x) => `<li>${txt(x.t)} <span class="src">${txt(x.f)}</span></li>`).join('')}</ul>`
    : '<p class="muted">No rules written yet.</p>';
  return `<section><h2 class="new">How pet abilities work</h2>${corpo}</section>`;
}

function renderIndice(g) {
  const linhas = (g.familias ?? [])
    .map((f) => `<tr><td>${txt(f.nome)}</td><td>${txt(f.papel)}</td><td>${txt(f.unica)}</td></tr>`)
    .join('');
  return `<section><h3>Families</h3><table><thead><tr><th>Family</th><th>Role</th><th>Unique ability</th></tr></thead><tbody>${linhas}</tbody></table></section>`;
}

function celulaProfessores(ps) {
  if (!ps.length) return '<span class="muted">no known teacher yet</span>';
  const mostra = ps
    .slice(0, 4)
    .map((p) => `<div>${txt(p.n)}${marcaSaltii(p)}, ${txt(p.nv)}, ${txt(p.z)}</div>`)
    .join('');
  const resto = ps.length - 4;
  return mostra + (resto > 0 ? `<div class="muted">+${resto} more</div>` : '');
}

function renderProgressao(f, H) {
  const habs = (f.habilidades ?? []).filter((n) => H[n] && !H[n].treinador);
  if (!habs.length) return '<p class="muted">No trainable abilities.</p>';
  return habs
    .map((nome) => {
      const linhas = (H[nome].ranks ?? [])
        .map((r) => {
          const ps = ordenaSaltii(r.prof);
          return `<tr><td>${txt(r.r)}</td><td>${txt(r.pet)}</td><td>${txt(r.pt)}</td><td>${celulaProfessores(ps)}</td></tr>`;
        })
        .join('');
      return `<h4>${txt(nome)}</h4><table><thead><tr><th>Rank</th><th>Pet lvl</th><th>TP</th><th>Teachers</th></tr></thead><tbody>${linhas}</tbody></table>`;
    })
    .join('');
}

function renderFamilia(f, H) {
  const notas = f.notas ?? [];
  const notasHtml = notas.length
    ? `<ul>${notas.map((x) => `<li>${txt(x.t)} <span class="src">${txt(x.f)}</span></li>`).join('')}</ul>`
    : '<p class="muted">none yet</p>';
  const rapidas = f.rapidas ?? [];
  const rapidasHtml = rapidas.length
    ? `<table><thead><tr><th>Name</th><th>Lvl</th><th>Zone</th><th>Speed</th><th>Source</th></tr></thead><tbody>${rapidas
        .map((r) => `<tr><td>${txt(r.n)}</td><td>${txt(r.nv)}</td><td>${txt(r.z)}</td><td>${txt(r.v)}</td><td>${txt(r.f)}</td></tr>`)
        .join('')}</tbody></table>`
    : '<p class="muted">none yet</p>';
  return `<section>
<h2 class="new">${txt(f.nome)}</h2>
<p class="meta">Role: ${txt(f.papel)}. Unique ability: ${txt(f.unica)}. Diet: ${lista(f.dieta)}.</p>
<p><b>Abilities:</b> ${lista(f.habilidades)}</p>
<h3>Notes</h3>${notasHtml}
<h3>Quick tames</h3>${rapidasHtml}
<h3>Progression</h3>${renderProgressao(f, H)}
</section>`;
}

function renderHabilidades(H) {
  const nomes = Object.keys(H)
    .filter((n) => !H[n].treinador)
    .sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
  const blocos = nomes.map((nome) => {
    const h = H[nome];
    const linhas = [];
    for (const r of h.ranks ?? []) {
      const ps = ordenaSaltii(r.prof);
      const rotulo = `Rank ${txt(r.r)}<br>Pet lvl ${txt(r.pet)}<br>${txt(r.pt)} TP`;
      if (!ps.length) {
        linhas.push(`<tr><td>${rotulo}</td><td colspan="5" class="muted">no known teacher yet</td></tr>`);
        continue;
      }
      ps.forEach((p, i) => {
        const celRank = i === 0 ? `<td rowspan="${ps.length}">${rotulo}</td>` : '';
        linhas.push(
          `<tr>${celRank}<td>${txt(p.n)}${marcaSaltii(p)}</td><td>${txt(p.fam)}</td><td>${txt(p.nv)}</td><td>${txt(p.z)}</td><td>${txt(p.v)}</td></tr>`,
        );
      });
    }
    const quem = h.familias === 'all' ? 'all families' : lista(h.familias);
    return `<h3>${txt(nome)}</h3>
<p>${txt(h.desc)} <span class="src">Desc source: ${txt(h.descf)}</span></p>
<p class="meta">Learned by: ${quem}</p>
<table><thead><tr><th>Rank</th><th>Teacher</th><th>Family</th><th>Lvl</th><th>Zone</th><th>Speed</th></tr></thead><tbody>${linhas.join('')}</tbody></table>`;
  });
  return `<section><h2 class="new">Abilities</h2>${blocos.join('')}</section>`;
}

function renderTreinador(H) {
  const nomes = Object.keys(H)
    .filter((n) => H[n].treinador)
    .sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
  const blocos = nomes.map((nome) => {
    const h = H[nome];
    const linhas = (h.ranks ?? [])
      .map((r) => `<tr><td>${txt(r.r)}</td><td>${txt(r.pet)}</td><td>${txt(r.pt)}</td></tr>`)
      .join('');
    return `<h3>${txt(nome)}</h3>
<p>${txt(h.desc)}</p>
<table><thead><tr><th>Rank</th><th>Pet lvl</th><th>TP</th></tr></thead><tbody>${linhas}</tbody></table>`;
  });
  return `<section><h2>Pet trainer</h2>${blocos.join('')}</section>`;
}

function renderFontes(g) {
  const itens = (g.fontes ?? [])
    .map((f) => `<li><b>${txt(f.id)}</b>: ${txt(f.nome)}. ${txt(f.url)}. ${txt(f.data)}</li>`)
    .join('');
  return `<section><h2>Sources</h2><ul>${itens}</ul></section>`;
}

function renderHtml(g) {
  const H = g.habilidades ?? {};
  const corpo = [
    renderCapa(g),
    renderRegras(g),
    `<section>${renderIndice(g)}</section>`,
    ...(g.familias ?? []).map((f) => renderFamilia(f, H)),
    renderHabilidades(H),
    renderTreinador(H),
    renderFontes(g),
  ].join('\n');
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Hunter Pet Abilities - WoW Forever</title>
<style>${CSS}</style>
</head>
<body>
${corpo}
</body>
</html>
`;
}

function acharEdge() {
  const achado = EDGE.find((c) => existsSync(c));
  if (!achado) throw new Error(`msedge.exe nao encontrado em: ${EDGE.join(' ; ')}`);
  return achado;
}

// PDF completo: cabecalho %PDF-, fim %%EOF e tamanho estavel entre duas leituras.
function pdfCompleto(caminho) {
  if (!existsSync(caminho)) return false;
  const tam = statSync(caminho).size;
  if (tam < 1000) return false;
  const bytes = readFileSync(caminho);
  return bytes.subarray(0, 5).toString('latin1') === '%PDF-' && bytes.subarray(-64).toString('latin1').includes('%%EOF');
}

const dormir = (ms) => new Promise((r) => setTimeout(r, ms));

async function imprimirPdf(html, pdf) {
  const edge = acharEdge();
  rmSync(pdf, { force: true });
  let erroSpawn = null;
  const filho = spawn(
    edge,
    ['--headless=new', '--disable-gpu', '--no-pdf-header-footer', `--print-to-pdf=${pdf}`, pathToFileURL(html).href],
    { stdio: 'ignore', windowsHide: true },
  );
  filho.on('error', (e) => (erroSpawn = e));
  const fim = Date.now() + ESPERA_MAX_MS;
  while (Date.now() < fim) {
    if (pdfCompleto(pdf)) {
      filho.kill();
      return;
    }
    if (erroSpawn) throw erroSpawn;
    await dormir(500);
  }
  filho.kill();
  throw new Error(`o PDF nao apareceu em ${ESPERA_MAX_MS / 1000}s: ${pdf}`);
}

async function main() {
  const a = lerArgs(process.argv.slice(2));
  const g = JSON.parse(readFileSync(a.json, 'utf8'));
  const html = renderHtml(g);
  mkdirSync(dirname(a.html), { recursive: true });
  writeFileSync(a.html, html, 'utf8');
  mkdirSync(dirname(a.pdf), { recursive: true });
  await imprimirPdf(a.html, a.pdf);
  console.log(`HTML: ${a.html}`);
  console.log(`PDF: ${a.pdf} (${statSync(a.pdf).size} bytes)`);
}

main().catch((e) => {
  console.error(`erro: ${e.message}`);
  process.exit(1);
});
