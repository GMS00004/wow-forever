// Testes de tendencia.mjs: monta fotos, indice, precos.json e CompraForever.lua falsos em os.tmpdir()
// e roda os tres modos por spawnSync. Uso: node testes/testar-tendencia.mjs
import { mkdtemp, mkdir, writeFile, rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import zlib from 'node:zlib';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const TENDENCIA = path.resolve(AQUI, '..', 'tendencia.mjs');
const HOJE = '2026-11-18';

// Epoch em segundos da hora local (independe do fuso da maquina). Mes 10 = novembro.
const epoch = (dia, h, m = 0) => Math.floor(new Date(2026, 10, dia, h, m).getTime() / 1000);

// Fotos sinteticas: ontem 20:00 e hoje 08:00, 12:00, 16:00. Formato congelado: cabecalho, snapshot, linhas c|i.
const FOTOS = [
  { snap: epoch(17, 20), linhas: [['c', 4304, 500, 505, 620, 300, 30], ['c', 4234, 190, 192, 230, 400, 40]] },
  { snap: epoch(18, 8), linhas: [['c', 4304, 480, 485, 600, 310, 31], ['c', 4234, 200, 205, 240, 410, 41], ['i', 99999, 3000, 3000, 3000, 2, 2]] },
  { snap: epoch(18, 12), linhas: [['c', 4304, 600, 610, 640, 280, 28], ['c', 4234, 210, 215, 250, 390, 39]] },
  { snap: epoch(18, 16), linhas: [['c', 4304, 470, 475, 590, 320, 32], ['c', 4234, 180, 185, 220, 420, 42], ['i', 99999, 3100, 3100, 3100, 2, 2]] },
];

function textoFoto(f) {
  const cab = ['#qmh 1', 'region=us', 'house=111', `snapshot=${f.snap}`, `built=${f.snap + 30}`];
  const corpo = f.linhas.map((l) => `${l[0]} ${l[1]} ${l[2]} ${l[3]} ${l[4]} ${l[5]} ${l[6]} ${l[2]}x1`);
  return [...cab, ...corpo].join('\n') + '\n';
}

// precos.json minimo: 5 dias de historico (13 a 17/11), saidas e itens de agora.
// 4304: medianas 640,630,620,610,600; mins 500,520,480,470,450; saidas 14..17 = 900,1000,1100,1000 (media 1000).
// 4234: saidas 14..17 = 500,500,600,500 (media 525, abaixo de 800: fora do ranking).
// 99999: saidas altas mas sem historico: fora do ranking.
const PRECOS = {
  esquema: 1,
  geradoEm: '2026-11-18T16:00:00.000Z',
  publico: {
    casa: 'us-111',
    foto: epoch(18, 16),
    itens: {
      '4304': { tipo: 'c', min: 490, p25: 495, med: 600, unid: 1000, lotes: 100, baratos: [[490, 1]] },
      '4234': { tipo: 'c', min: 200, p25: 205, med: 230, unid: 4000, lotes: 200, baratos: [[200, 1]] },
      '99999': { tipo: 'i', min: 3100, p25: 3100, med: 3100, unid: 2, lotes: 2, baratos: [[3100, 1]] },
    },
    saidas: {
      '4304': { 20261113: 1000, 20261114: 900, 20261115: 1000, 20261116: 1100, 20261117: 1000 },
      '4234': { 20261113: 600, 20261114: 500, 20261115: 500, 20261116: 600, 20261117: 500 },
      '99999': { 20261114: 2000, 20261115: 2000, 20261116: 2000, 20261117: 2000 },
    },
    historico: {
      '4304': [
        [20261113, 500, 640, 900], [20261114, 520, 630, 800], [20261115, 480, 620, 850],
        [20261116, 470, 610, 700], [20261117, 450, 600, 650],
      ],
      '4234': [
        [20261113, 190, 240, 5000], [20261114, 195, 235, 4800], [20261115, 190, 232, 4900],
        [20261116, 188, 228, 4700], [20261117, 186, 226, 4600],
      ],
    },
    historicoDias: [20261113, 20261117],
  },
  auctionator: null,
  vendedor: null,
};

// CompraForever.lua falso: vigia de 4304 com teto 490.
const LUA = `CompraForeverDB = {
	["vigia"] = {
		["itens"] = {
			[4304] = {
				["nome"] = "Thick Leather",
				["teto"] = 490,
			},
		},
	},
}
`;

let casos = 0;
let erros = 0;
function confere(nome, ok, detalhe = '') {
  casos++;
  if (!ok) {
    erros++;
    console.log(`FALHA: ${nome}${detalhe ? ` (${detalhe})` : ''}`);
  }
}

function rodar(args) {
  const r = spawnSync(process.execPath, [TENDENCIA, ...args], { encoding: 'utf8' });
  return { codigo: r.status, texto: `${r.stdout}${r.stderr}` };
}

async function main() {
  const dir = await mkdtemp(path.join(os.tmpdir(), 'tendencia-'));
  try {
    const pastaFotos = path.join(dir, 'fotos');
    const pastaVazia = path.join(dir, 'vazia');
    await mkdir(pastaFotos);
    await mkdir(pastaVazia);

    const indice = [];
    for (const f of FOTOS) {
      const texto = textoFoto(f);
      const gz = zlib.gzipSync(Buffer.from(texto, 'utf8'));
      const arq = `us-111-${f.snap}.txt.gz`;
      await writeFile(path.join(pastaFotos, arq), gz);
      const sha = createHash('sha256').update(texto).digest('hex');
      indice.push(`${f.snap} ${f.snap + 30} ${arq} ${f.linhas.length} ${sha}`);
    }
    await writeFile(path.join(pastaFotos, 'indice.txt'), indice.join('\n') + '\n');

    const arqPrecos = path.join(dir, 'precos.json');
    await writeFile(arqPrecos, JSON.stringify(PRECOS));
    const arqLua = path.join(dir, 'CompraForever.lua');
    await writeFile(arqLua, LUA);

    const base = ['--precos', arqPrecos, '--hoje', HOJE];
    const comSv = ['--sv', arqLua];
    const comFotos = ['--pasta', pastaFotos, ...base, ...comSv];

    // (a) --item com as fotos: percentil de agora (490) entre os 4 minimos (500,480,600,470): 2 de 4 = 50%.
    let r = rodar(['--item', '4304', ...comFotos]);
    confere('item 4304 codigo 0', r.codigo === 0, `codigo ${r.codigo}`);
    confere('item 4304 cabecalho com id', r.texto.includes('(id 4304)'));
    confere('item 4304 agora min 4s 90c', r.texto.includes('agora: min 4s 90c'));
    confere('item 4304 percentil 50 com fotos', r.texto.includes('agora 4s 90c esta no percentil 50% dos minimos horarios\n'));
    confere('item 4304 vendas/dia 1000', r.texto.includes('vendas/dia (media 4 dias): 1000'));
    // faixa 7 dias: min dos minimos (450) e mediana das medianas (640,630,620,610,600 -> 620).
    confere('item 4304 faixa 7 dias', r.texto.includes('faixa 7 dias: min 4s 50c .. mediana 6s 20c'));
    confere('item 4304 tabela de fotos mostra ontem 20:00', r.texto.includes('2026-11-17  20:00'));
    confere('item 4304 tabela de fotos mostra hoje 16:00', r.texto.includes('2026-11-18  16:00'));
    confere('item 4304 sem a frase do coletor', !r.texto.includes('sem fotos horarias ainda'));

    // Busca por nome (nome real do ItemSparse: Thick Leather) e ambiguidade ("leather": 4304 e 4234).
    r = rodar(['--item', 'thick leather', ...comFotos]);
    confere('busca por nome codigo 0', r.codigo === 0, `codigo ${r.codigo}`);
    confere('busca por nome acha 4304', r.texto.includes('(id 4304)'));
    r = rodar(['--item', 'leather', ...comFotos]);
    confere('ambiguo sai 1', r.codigo === 1, `codigo ${r.codigo}`);
    confere('ambiguo lista 4304 e 4234', r.texto.includes('4304') && r.texto.includes('4234') && r.texto.includes('ambiguo'));

    // Sem fotos: frase do coletor, percentil pelo diario: 3 de 5 minimos (480,470,450) <= 490 = 60%.
    r = rodar(['--item', '4304', '--pasta', pastaVazia, ...base, ...comSv]);
    confere('sem fotos codigo 0', r.codigo === 0, `codigo ${r.codigo}`);
    confere('sem fotos frase do coletor', r.texto.includes('sem fotos horarias ainda (coletor)'));
    confere('sem fotos percentil 60 pelo diario', r.texto.includes('agora 4s 90c esta no percentil 60% dos minimos horarios (base: diario)'));

    // (b) elasticidade: so 4304 passa (4234 tem 525 vendas/dia, 99999 nao tem historico).
    // gap de 4304 por dia (14..17): 110/630, 140/620, 140/610, 150/600; mediana = 22.8%.
    // ganho por dia: 630*0.95-520=78.5, 109, 109.5, 120; mediana = 109.25 -> 1s 09c. gapH '-' (4 fotos < 12).
    r = rodar(['--elasticidade', '--linhas', '10', ...comFotos]);
    confere('elasticidade codigo 0', r.codigo === 0, `codigo ${r.codigo}`);
    const linhas = r.texto.split('\n');
    const linha4304 = linhas.find((l) => /^4304\s/.test(l));
    confere('ranking tem 4304', Boolean(linha4304));
    confere('ranking gap% 4304 = 22.8', Boolean(linha4304) && linha4304.includes('22.8'), linha4304);
    confere('ranking ganho 4304 = 1s 09c', Boolean(linha4304) && linha4304.includes('1s 09c'), linha4304);
    confere('ranking gapH 4304 e traco', Boolean(linha4304) && / 22\.8\s+-\s/.test(linha4304), linha4304);
    confere('ranking sem 4234', !linhas.some((l) => /^4234\s/.test(l)));
    confere('ranking sem 99999', !linhas.some((l) => /^99999\s/.test(l)));
    confere('ranking tem so 1 linha de item', linhas.filter((l) => /^\d+\s/.test(l)).length === 1);
    confere('fonte da elasticidade', r.texto.includes('fonte: diario 20261114-20261117, fotos=4'));

    r = rodar(['--elasticidade', '--linhas', '10', '--pasta', pastaVazia, ...base, ...comSv]);
    confere('elasticidade sem fotos fotos=0', r.texto.includes('fonte: diario 20261114-20261117, fotos=0'));

    // (c) vigia: teto 490; hoje 3 fotos (480, 600, 470): 2 <= 490; percentil 50% (todas as fotos).
    r = rodar(['--vigia', ...comFotos]);
    confere('vigia codigo 0', r.codigo === 0, `codigo ${r.codigo}`);
    confere('vigia linha do 4304', r.texto.includes('Thick Leather (id 4304): teto 4s 90c'));
    confere('vigia abaixo do teto em 2 de 3 fotos', r.texto.includes('abaixo do teto em 2 de 3 fotos de hoje'));
    confere('vigia percentil 50%', r.texto.includes('percentil 50%'));

    r = rodar(['--vigia', '--sv', path.join(dir, 'nao-existe.lua'), ...base]);
    confere('vigia sem arquivo sai 0 e vazia', r.codigo === 0 && r.texto.includes('vigia vazia'), `codigo ${r.codigo}`);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
  console.log(`testar-tendencia: casos=${casos} erros=${erros}`);
  process.exitCode = erros > 0 ? 1 : 0;
}

main().catch((e) => {
  console.log(`testar-tendencia: erro inesperado: ${e.message}`);
  process.exitCode = 1;
});
