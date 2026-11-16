// Rota de Leatherworking entre duas pericias, fora do jogo (PregaoForever).
// Contrato em CONTRATO.md, secao 6. Uso: node rota.mjs --de 186 --ate 225 [--sem "A,B"] [--so "A,B"] [--lua]
import { pathToFileURL } from 'node:url';
import { ARQ_RECEITAS, ARQ_PRECOS, lerJson, moeda } from './comum.mjs';
import { calcular } from './crafts.mjs';

const JANELA_AUCTIONATOR = 21600; // segundos: a exportacao do Auctionator so vale ate 6 horas (como no crafts.mjs)
const TOLERANCIA = 1e-9;
const MAX_PASSOS = 20;
const USO = 'uso: node rota.mjs --de 186 --ate 225 [--sem "A,B"] [--so "A,B"] [--lua]';

const chave = (id) => String(id);
const minusc = (s) => String(s).toLowerCase();

// Reagentes validos de uma receita: id diferente de 0 e quantidade maior que 0.
const reagentesDe = (r) => r.reagentes.filter((g) => Number(g.id) !== 0 && g.qtd > 0);

// Chance de subir a pericia s com uma craft da receita (mesma regra do crafts.mjs).
function chanceEm(r, s) {
  if (r.pontos === 0) return 0;
  if (s < r.amarela) return 1;
  if (s >= r.cinza) return 0;
  return Math.min(1, Math.max(0, (r.cinza - s) / (r.cinza - r.amarela)));
}

// Funcao pura: nao le arquivo e nao usa relogio. A hora vem em opcoes.agora (epoch em segundos).
export function calcularRota(receitas, precos, opcoes) {
  const { de, ate, agora } = opcoes;
  const sem = new Set((opcoes.sem || []).map(minusc));
  const so = opcoes.so == null ? null : new Set(opcoes.so.map(minusc));

  // Constantes por receita: calcular() nao depende da pericia para custo, venda, leilao, limite e aprende.
  const { linhas } = calcular(receitas, precos, { pericia: de, agora });
  const rec = receitas.receitas.map((r, i) => ({ r, l: linhas[i] }));

  // Um ponto por vez.
  const n = rec.map(() => 0);
  const pontos = [];
  let parou = null;
  let chegou = ate;
  for (let s = de; s < ate; s++) {
    const cands = [];
    rec.forEach(({ r, l }, i) => {
      if (l.semPreco || l.vendaNpc === null) return;
      if (l.aprende > s) return;
      const nome = minusc(r.nome);
      if (sem.has(nome) || (so !== null && !so.has(nome))) return;
      const c = chanceEm(r, s);
      if (!(c > 0)) return;
      const e = 1 / (c * r.pontos);
      if (l.ate !== null && n[i] + e > l.ate) return;
      cands.push({ i, e, k: (l.custo - l.vendaNpc) * e });
    });
    if (cands.length === 0) {
      parou = { pericia: s, motivo: 'sem receita' };
      chegou = s;
      break;
    }
    // Menor custo do ponto no pior caso; no empate, maior lucro no leilao (nulo perde); depois, menor magia.
    const minK = Math.min(...cands.map((c) => c.k));
    const [vence] = cands
      .filter((c) => c.k <= minK + TOLERANCIA)
      .sort((a, b) => {
        const la = rec[a.i].l.lucroLeilao, lb = rec[b.i].l.lucroLeilao;
        if (la !== lb) {
          if (la === null) return 1;
          if (lb === null) return -1;
          return lb - la;
        }
        return rec[a.i].r.magia - rec[b.i].r.magia;
      });
    n[vence.i] += vence.e;
    pontos.push({ s, i: vence.i, e: vence.e });
  }

  // Pontos seguidos da mesma receita formam um passo.
  const grupos = [];
  for (const p of pontos) {
    const ult = grupos[grupos.length - 1];
    if (ult && ult.i === p.i) {
      ult.ate = p.s + 1;
      ult.esperado += p.e;
    } else {
      grupos.push({ i: p.i, de: p.s, ate: p.s + 1, esperado: p.e });
    }
  }

  const passos = grupos.map((g) => {
    const { r, l } = rec[g.i];
    const crafts = Math.ceil(g.esperado - TOLERANCIA);
    const piorCaso = crafts * (l.vendaNpc - l.custo);
    const materiais = reagentesDe(r).map((x) => ({
      id: Number(x.id),
      nome: receitas.itens?.[chave(x.id)]?.nome ?? chave(x.id),
      qtd: x.qtd * crafts,
    }));
    const h = precos.publico?.historico?.[chave(r.produto.id)];
    return {
      de: g.de,
      ate: g.ate,
      magia: r.magia,
      nome: r.nome,
      crafts,
      esperado: g.esperado,
      custo: l.custo,
      vendaNpc: l.vendaNpc,
      lucroLeilao: l.lucroLeilao,
      aprende: l.aprende,
      aprendeEstimado: l.aprendeEstimado,
      itemReceita: r.itemReceita != null,
      listados: l.listados,
      saiDia: l.saiDia,
      piorCaso,
      seVender: l.lucroLeilao === null ? piorCaso : crafts * l.lucroLeilao,
      materiais,
      historico: Array.isArray(h) && h.length > 0 ? h.slice(-4) : null,
    };
  });

  const totais = passos.reduce(
    (t, p) => ({
      crafts: t.crafts + p.crafts,
      custo: t.custo + p.crafts * p.custo,
      piorCaso: t.piorCaso + p.piorCaso,
      seVender: t.seVender + p.seVender,
    }),
    { crafts: 0, custo: 0, piorCaso: 0, seVender: 0 },
  );

  return { de, ate, chegou, parou, passos, totais };
}

// ---------- roteiro em Lua ----------

// Dinheiro com sinal: "+" quando maior que 0.
const sinal = (v) => (v > 0 ? '+' : '') + moeda(v);

// Texto em Lua: aspas e barras invertidas escapadas.
const escapaLua = (t) => t.replace(/\\/g, '\\\\').replace(/"/g, '\\"');

// Linhas do roteiro para a tabela passos do ProfissoesB.lua. quando e "AAAA-MM-DD HH:MM".
export function textoLua(rota, quando) {
  const out = [];
  for (const p of rota.passos) {
    const mats = p.materiais.map((m) => `${m.qtd} ${m.nome}`).join(', ');
    const notas = [];
    if (p.itemReceita) notas.push('pattern');
    notas.push(`worst case ${sinal(p.piorCaso)}`);
    if (p.lucroLeilao !== null) notas.push(`if sold ${sinal(p.seVender)}`);
    const texto = `${p.nome} (${p.crafts}x): ${mats} (${notas.join('; ')})`;
    out.push(`      { de = ${p.de}, ate = ${p.ate}, texto = "${escapaLua(texto)}" },`);
  }
  if (rota.parou) out.push(`      -- stopped at ${rota.parou.pericia}: no recipe gives a point`);
  out.push(`      -- route from the crafts tool (rota.mjs), prices of ${quando}`);
  return out;
}

// ---------- linha de comando ----------

const ASCII = (s) => String(s).replace(/[^\x20-\x7e]/g, '?');
const celula = (s, n) => {
  const t = ASCII(s);
  return (t.length > n ? t.slice(0, n - 2) + '..' : t).padEnd(n);
};
const mo = (v) => moeda(v);

// Hora local HH:MM a partir de epoch em segundos.
function hora(epoch) {
  const d = new Date(epoch * 1000);
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

// Hora local AAAA-MM-DD HH:MM a partir de epoch em segundos.
function dataHora(epoch) {
  const d = new Date(epoch * 1000);
  const p = (v) => String(v).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

// Idade em "35 min" ou "2 h 05 min".
function idade(seg) {
  const s = Math.max(0, Math.floor(seg));
  const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
  return h ? `${h} h ${String(m).padStart(2, '0')} min` : `${m} min`;
}

// Coluna aprende: "175 i" quando vem do item, "~180" quando e estimada.
const aprendeTxt = (p) => (p.aprendeEstimado ? `~${p.aprende}` : `${p.aprende} i`);

// Linha da tabela: oito colunas com largura fixa e a ultima (ultimos dias) sem corte.
const LARGURAS = [7, 22, 6, 7, 14, 14, 14, 8];
const linhaTab = (cols) =>
  (cols.slice(0, LARGURAS.length).map((c, i) => celula(c, LARGURAS[i])).join(' ') + ' ' + cols[LARGURAS.length]).trimEnd();

// Cabecalho com foto publica e exportacao do Auctionator, igual ao crafts.mjs.
function horasTxt(precos, agora) {
  const foto = precos.publico?.foto;
  const fotoTxt = foto ? `foto publica ${hora(foto)} (ha ${idade(agora - foto)})` : 'foto publica sem data';
  let aucTxt = 'Auctionator: sem exportacao';
  if (precos.auctionator) {
    const seg = agora - precos.auctionator.em;
    aucTxt = `Auctionator: exportado ${hora(precos.auctionator.em)} (ha ${idade(seg)})`;
    if (seg > JANELA_AUCTIONATOR) aucTxt += ', velha: nao usada';
  }
  return `${fotoTxt} | ${aucTxt}`;
}

// Reagentes da rota somados por id, do que mais se usa para o que menos.
function agregaMateriais(passos) {
  const m = new Map();
  for (const p of passos) {
    for (const x of p.materiais) {
      const c = m.get(x.id) || { id: x.id, nome: x.nome, qtd: 0 };
      c.qtd += x.qtd;
      m.set(x.id, c);
    }
  }
  return [...m.values()].sort((a, b) => b.qtd - a.qtd || a.id - b.id);
}

// Quebra "312 Thick Leather, 52 Wildvine" em ate 4 linhas de 110 caracteres; o que nao couber vira "e mais N".
function quebrarMateriais(mats) {
  const itens = mats.map((m) => `${m.qtd} ${m.nome}`);
  const txt = (a) => a.join(', ');
  const L = [];
  let atual = [];
  let i = 0;
  for (; i < itens.length; i++) {
    const cand = [...atual, itens[i]];
    if (txt(cand).length <= 110) {
      atual = cand;
      continue;
    }
    if (L.length === 3) break; // a quarta linha e a atual e nao cabe mais nada
    L.push(txt(atual));
    atual = [itens[i]];
  }
  if (i === itens.length) {
    if (atual.length) L.push(txt(atual));
    return L;
  }
  const fim = [...atual];
  let N = itens.length - i;
  while (fim.length && txt(fim).length + `, e mais ${N}`.length > 110) {
    fim.pop();
    N++;
  }
  L.push(fim.length ? `${txt(fim)}, e mais ${N}` : `e mais ${N}`);
  return L;
}

function relatorio(res, precos, agora) {
  const out = [`ROTA - Leatherworking - de ${res.de} a ${res.ate}`, horasTxt(precos, agora)];

  out.push(linhaTab(['faixa', 'receita', 'crafts', 'aprende', 'custo/craft', 'pior caso', 'se vender', 'listados', 'ultimos dias']));
  if (res.passos.length === 0) out.push('nenhum passo');
  for (const p of res.passos.slice(0, MAX_PASSOS)) {
    out.push(linhaTab([
      `${p.de}-${p.ate}`,
      p.nome,
      String(p.crafts),
      aprendeTxt(p),
      mo(p.custo),
      mo(p.piorCaso),
      mo(p.seVender),
      String(p.listados ?? '-'),
      p.historico ? p.historico.map((h) => h[3]).join('/') : '-',
    ]));
  }
  if (res.passos.length > MAX_PASSOS) out.push(`mais ${res.passos.length - MAX_PASSOS} passos`);

  if (res.parou) out.push(`parou em ${res.parou.pericia}: nenhuma receita da ponto com os filtros e limites`);

  const t = res.totais;
  out.push(`total: ${t.crafts} crafts | materiais ${mo(t.custo)} | pior caso ${mo(t.piorCaso)} | se tudo vender ${mo(t.seVender)}`);

  const mats = quebrarMateriais(agregaMateriais(res.passos));
  if (mats.length === 0) {
    out.push('materiais: nenhum');
  } else {
    out.push('materiais:');
    out.push(...mats);
  }

  const comPadrao = [...new Set(res.passos.filter((p) => p.itemReceita).map((p) => p.nome))];
  out.push(`precisa do padrao: ${comPadrao.length ? comPadrao.join(', ') : 'nenhuma'}`);
  if (res.ate > 225) out.push('acima de 225 pede o Artisan (pericia 200 e nivel 35)');
  out.push('aviso: chance de ponto: formula do Classic, nao conferida no Forever | ~ = pericia de aprender estimada');
  out.push('aviso: limite por receita: 25% do listado de cada reagente; reagente comum a duas receitas nao soma');
  return out;
}

const nomesDe = (v) => v.split(',').map((s) => s.trim());

// Le --de, --ate, --sem, --so e --lua. Devolve { erro } se faltar ou vier errado.
function lerOpcoes(argv) {
  const op = { de: null, ate: null, sem: [], so: null, lua: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--lua') {
      op.lua = true;
    } else if (a === '--de' || a === '--ate') {
      const v = argv[++i];
      if (v === undefined || !/^\d+$/.test(v)) return { erro: `${a} pede um numero inteiro` };
      op[a.slice(2)] = Number(v);
    } else if (a === '--sem' || a === '--so') {
      const v = argv[++i];
      if (v === undefined) return { erro: `${a} pede uma lista de nomes separada por virgula` };
      if (a === '--sem') op.sem = nomesDe(v);
      else op.so = nomesDe(v);
    } else {
      return { erro: `argumento desconhecido: ${a}` };
    }
  }
  if (op.de === null) return { erro: 'falta --de' };
  if (op.ate === null) return { erro: 'falta --ate' };
  if (op.de >= op.ate) return { erro: '--de precisa ser menor que --ate' };
  return op;
}

async function lerEntrada(arq, script) {
  try {
    return await lerJson(arq);
  } catch (e) {
    if (e.code === 'ENOENT') {
      console.error(`falta ${arq}: rode antes ${script}`);
      process.exit(2);
    }
    throw e;
  }
}

async function linhaDeComando(argv) {
  const op = lerOpcoes(argv);
  if (op.erro) {
    console.error(`${op.erro}\n${USO}`);
    process.exit(2);
  }
  const receitas = await lerEntrada(ARQ_RECEITAS, 'gerar-receitas.mjs');
  const precos = await lerEntrada(ARQ_PRECOS, 'baixar-precos.mjs');

  const nomes = new Set(receitas.receitas.map((r) => minusc(r.nome)));
  for (const nome of [...op.sem, ...(op.so || [])]) {
    if (!nomes.has(minusc(nome))) {
      console.error(`nome de receita nao existe: ${nome}\n${USO}`);
      process.exit(2);
    }
  }

  const agora = Math.floor(Date.now() / 1000);
  const res = calcularRota(receitas, precos, { de: op.de, ate: op.ate, agora, sem: op.sem, so: op.so });

  if (op.lua) {
    const epoch = precos.auctionator ? precos.auctionator.em : precos.publico?.foto;
    const quando = epoch == null ? 'sem data' : dataHora(epoch);
    console.log(textoLua(res, quando).map(ASCII).join('\n'));
  } else {
    console.log(relatorio(res, precos, agora).map(ASCII).join('\n'));
  }
}

// So roda a linha de comando quando o arquivo e chamado direto.
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  linhaDeComando(process.argv.slice(2)).catch((e) => {
    console.error(`erro: ${e.message}`);
    process.exit(1);
  });
}
