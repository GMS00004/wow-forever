#!/usr/bin/env node
// Gera guia.json e PetGuia.lua (GuiaForeverPetGuia) a partir dos dados de pets.
// Uso: node gerar-guia.mjs --pasta <pasta pets> --petopia <abilities.html> --lua <PetGuia.lua>
// Contrato: addons-proprios\GuiaForever\ARQUITETURA.md, secao 10.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const args = {};
for (let i = 2; i < process.argv.length; i++) {
  const a = process.argv[i];
  if (a.startsWith('--')) args[a.slice(2)] = process.argv[++i];
}
const aqui = path.dirname(fileURLToPath(import.meta.url));
const pasta = path.resolve(args.pasta || aqui);
const luaSaida = args.lua ? path.resolve(args.lua) : null;
const petopiaArq = args.petopia ? path.resolve(args.petopia) : null;
if (!luaSaida || !petopiaArq) {
  console.error('Uso: node gerar-guia.mjs --pasta <pasta pets> --petopia <html> --lua <saida.lua>');
  process.exit(2);
}

const ler = (n, obrigatorio = true) => {
  const p = path.join(pasta, n);
  if (!fs.existsSync(p)) {
    if (obrigatorio) { console.error('Falta ' + p); process.exit(2); }
    return null;
  }
  return JSON.parse(fs.readFileSync(p, 'utf8'));
};
const cli = ler('habilidades.json');
const prof = ler('professores.json');
const feras = ler('feras.json');
const saltii = ler('saltii.json', false);
const textos = ler('textos.json', false);
const html = fs.readFileSync(petopiaArq, 'utf8');
const lidoPetopia = (() => {
  const p = path.join(path.dirname(petopiaArq), 'petopia-lido.json');
  try { return JSON.parse(fs.readFileSync(p, 'utf8')).lidoEm; } catch { return null; }
})();

// ---------- ASCII ----------
const TRANSL = { '‘': "'", '’': "'", '“': '"', '”': '"', '–': '-', '—': '-', '…': '...', ' ': ' ', 'ß': 'ss', 'æ': 'ae', 'Æ': 'AE', 'ø': 'o', 'Ø': 'O' };
function asc(s) {
  if (typeof s !== 'string') return s;
  let r = s.replace(/[^\x00-\x7f]/g, (c) => TRANSL[c] ?? c);
  r = r.normalize('NFD').replace(/[̀-ͯ]/g, '');
  return r.replace(/[^\x20-\x7e]/g, (c) => (c === '\n' || c === '\t' ? ' ' : '?'));
}
function limpa(o) {
  if (typeof o === 'string') return asc(o);
  if (Array.isArray(o)) return o.map(limpa);
  if (o && typeof o === 'object') return Object.fromEntries(Object.entries(o).map(([k, v]) => [k, limpa(v)]));
  return o;
}
const corta = (s, n = 160) => {
  s = s.replace(/\s+/g, ' ').trim();
  if (s.length <= n) return s;
  const c = s.slice(0, n - 3);
  const sp = c.lastIndexOf(' ');
  return (sp > n * 0.6 ? c.slice(0, sp) : c).replace(/[ ,;:]+$/, '') + '...';
};

// ---------- Petopia ----------
const ent = (s) => s.replace(/&#0*39;|&apos;/g, "'").replace(/&quot;/g, '"').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&nbsp;/g, ' ');
const petopia = {}; // "Hab" -> { rank -> {pet, pt, efeito} }
for (const li of html.match(/<li id=[^>]*class=.abilityrank classic[^]*?<\/li>/g) || []) {
  const m = li.match(/abilityrankname[^>]*>([^<]*)<\/span>: Pet Level (\d+), Cost (\d+) TP\./);
  if (!m) continue;
  const nm = ent(m[1]).match(/^(.*) (\d+)$/);
  if (!nm) continue;
  const d = li.match(/abilityrankdesc[^>]*>([^]*?)<\/span>\s*<span class='abilitysource/);
  const efeito = d ? ent(d[1].replace(/<[^>]+>/g, '')).replace(/\s+/g, ' ').trim() : '';
  (petopia[nm[1]] ??= {})[Number(nm[2])] = { pet: Number(m[2]), pt: Number(m[3]), efeito };
}

// ---------- listas ----------
const ORDEM = ['Cat', 'Raptor', 'Wind Serpent', 'Scorpid', 'Boar', 'Carrion Bird', 'Bear', 'Gorilla', 'Turtle', 'Spider', 'Crab', 'Hyena', 'Crocolisk', 'Bat', 'Bird of Prey', 'Tallstrider', 'Wolf', 'Fox', 'Core Hound'];
const TECNICAS = new Set(['Tamed Pet Passive (DND)', 'Hunter Pet Scaling', 'Summoning']);
const DESCARTE_GERAL = new Set(['Pet Hardiness', 'Pet Aggression', 'Pet Recovery', 'Pet Resistance', 'Intimidation']);
const TREINADOR = ['Growl', 'Great Stamina', 'Natural Armor', 'Fire Resistance', 'Frost Resistance', 'Arcane Resistance', 'Nature Resistance', 'Shadow Resistance'];
const BASE = ['Bite', 'Claw', 'Dash', 'Dive'];
const divergencias = [];
const descartados = [];
const fam19 = new Map(cli.familias.map((f) => [f.nome, f]));
for (const n of ORDEM) if (!fam19.has(n)) { console.error('Familia ausente no cliente: ' + n); process.exit(2); }

const sFam = saltii?.familias || {};
const doadores = saltii?.doadores || {};
const raros = saltii?.raros || [];

// ---------- familias ----------
const familias = [];
for (const nome of ORDEM) {
  const c = fam19.get(nome);
  const proprias = c.habilidades.filter((h) => !TECNICAS.has(h));
  const unicaCli = proprias.find((h) => !BASE.includes(h));
  const ordenadas = [...BASE.filter((b) => proprias.includes(b)), ...proprias.filter((h) => !BASE.includes(h))];
  const f = { nome };
  const sf = sFam[nome];
  f.papel = sf?.papel ?? undefined;
  f.unica = sf?.unica ?? unicaCli;
  f.dieta = c.dieta;
  f.habilidades = [...ordenadas, 'Cower'];
  f.notas = [];
  if (nome === 'Core Hound') f.notas.push({ t: 'Not confirmed in the game yet; Saltii lists 18 families.', f: 'Petopia' });
  for (const n of textos?.familias?.[nome]?.notas || []) f.notas.push({ t: n.t, f: n.f });
  f.rapidas = [];
  const vistos = new Set();
  for (const r of raros.filter((x) => x.familia === nome)) {
    f.rapidas.push({ n: r.n, nv: String(r.nv), z: r.z, f: 'Saltii' });
    vistos.add(r.n);
  }
  const lista = Object.entries(feras.feras)
    .filter(([, b]) => b.familia === nome && typeof b.velocidade === 'number' && b.velocidade < 2.0 && b.min != null)
    .sort((a, b) => a[1].velocidade - b[1].velocidade || a[1].min - b[1].min || a[1].nome.localeCompare(b[1].nome));
  let n5 = 0;
  for (const [id, b] of lista) {
    if (n5 >= 5) break;
    if (vistos.has(b.nome)) continue;
    vistos.add(b.nome);
    n5++;
    f.rapidas.push({ npc: Number(id), n: b.nome, nv: nv(b.min, b.max), z: b.zona, v: b.velocidade, f: b.fontes.join('+') });
  }
  familias.push(f);
}
function nv(min, max) { if (min == null) return max == null ? "?" : String(max); return min === max || max == null ? String(min) : `${min}-${max}`; }

// ---------- habilidades ----------
const porNomeFera = new Map();
for (const [id, b] of Object.entries(feras.feras)) (porNomeFera.get(b.nome) ?? porNomeFera.set(b.nome, []).get(b.nome)).push([Number(id), b]);

const nomes = new Set();
for (const f of familias) for (const h of f.habilidades) nomes.add(h);
for (const h of TREINADOR) nomes.add(h);
const habilidades = {};
let ranksComProf = 0, ranksTotal = 0, saltiiMarcados = 0, saltiiAcrescentados = 0;
const saltiiSemRank = [];

function efeitoBase(nome, rankMax) {
  const t = textos?.habilidades?.[nome];
  if (t?.t) return { desc: asc(t.t), descf: t.f };
  const e = petopia[nome]?.[rankMax]?.efeito;
  return e ? { desc: corta(e), descf: 'Petopia' } : null;
}

for (const nome of [...nomes]) {
  const cl = cli.habilidades[nome];
  const pt = petopia[nome] || {};
  const numeros = new Set([...(cl?.ranks || []).map((r) => r.rank), ...Object.keys(pt).map(Number)]);
  const ranks = [];
  for (const r of [...numeros].sort((a, b) => a - b)) {
    const rc = cl?.ranks.find((x) => x.rank === r);
    const rp = pt[r];
    let pet = rc?.nivelPet ?? null, pts = rc?.pt ?? null, id = rc?.spellId ?? null, fonte = null;
    if (rc && rp) {
      if (pet != null && rp.pet !== pet) divergencias.push(`${nome} ${r}: nivel do pet cliente ${pet} x Petopia ${rp.pet} (vale o cliente)`);
      if (pts != null && rp.pt !== pts) divergencias.push(`${nome} ${r}: pontos cliente ${pts} x Petopia ${rp.pt} (vale o cliente)`);
      if (pet == null) pet = rp.pet;
      if (pts == null) pts = rp.pt;
    } else if (!rc && rp) {
      pet = rp.pet; pts = rp.pt; fonte = 'Petopia';
    }
    if (pet == null) { descartados.push(`${nome} ${r}: sem nivel do pet em nenhuma fonte`); continue; }
    const o = { r, pet, pt: pts ?? 0 };
    if (id != null) o.id = id;
    if (fonte) o.f = fonte;
    ranks.push(o);
  }
  const trein = TREINADOR.includes(nome);
  const fams = trein || nome === 'Cower' ? 'all' : familias.filter((f) => f.habilidades.includes(nome)).map((f) => f.nome);
  const h = {};
  const ef = efeitoBase(nome, ranks.length ? ranks[ranks.length - 1].r : 0) || efeitoBase(nome, Math.max(0, ...Object.keys(pt).map(Number)));
  if (ef) { h.desc = ef.desc; h.descf = ef.descf; }
  h.treinador = trein;
  h.familias = fams;
  if (!trein) {
    for (const rk of ranks) {
      ranksTotal++;
      const chave = `${nome} ${rk.r}`;
      const lista = [];
      const base = (prof.ranks[chave]?.professores || []).map((p) => ({
        npc: p.npcId, n: p.nome, nv: nv(p.min, p.max), z: p.zona, fam: p.familia,
        v: p.velocidade ?? feras.feras[p.npcId]?.velocidade, f: (p.fontes || []).join('+'), ok: p.confirmado,
      }));
      const doa = doadores[chave] || [];
      for (const d of doa) {
        const ex = base.find((b) => b.n === d.n);
        if (ex) {
          ex.s = true; saltiiMarcados++;
          // sem nivel ou zona no professor casado: vale o do cartao do Saltii
          if (!ex.nv || ex.nv === '?') ex.nv = String(d.nv);
          if (!ex.z) ex.z = d.z;
          continue;
        }
        const cand = porNomeFera.get(d.n) || [];
        const fera = cand[0];
        const it = { n: d.n, nv: String(d.nv), z: d.z, f: 'Saltii', s: true };
        if (fera) { it.npc = fera[0]; it.fam = fera[1].familia; it.v = fera[1].velocidade; }
        base.push(it);
        saltiiAcrescentados++;
        saltiiMarcados++;
      }
      const minNv = (x) => { const n = parseInt(String(x.nv), 10); return Number.isNaN(n) ? 999 : n; };
      base.sort((a, b) => (b.s ? 1 : 0) - (a.s ? 1 : 0) || minNv(a) - minNv(b) || a.n.localeCompare(b.n));
      for (const b of base) {
        const o = {};
        if (b.npc != null) o.npc = b.npc;
        o.n = b.n; o.nv = b.nv; o.z = b.z;
        if (b.fam) o.fam = b.fam;
        if (b.v != null) o.v = b.v;
        o.f = b.f;
        if (b.s) o.s = true;
        if (b.ok != null) o.ok = b.ok;
        lista.push(o);
      }
      if (lista.length) { rk.prof = lista; ranksComProf++; }
    }
  } else ranksTotal += ranks.length;
  h.ranks = ranks;
  habilidades[nome] = h;
}
for (const chave of Object.keys(doadores)) {
  const m = chave.match(/^(.*) (\d+)$/);
  if (!m || !habilidades[m[1]]?.ranks.some((r) => r.r === Number(m[2]))) saltiiSemRank.push(chave);
}

// ---------- regras, fontes ----------
const regras = (textos?.regras || []).map((x) => ({ t: x.t, f: x.f, ...(x.essencial ? { e: true } : {}) }));
const hoje = new Date().toISOString().slice(0, 10);
const fontes = [
  { id: 'Client', nome: 'WoW Forever game client data (wago.tools DB2)', url: 'https://wago.tools/db2', data: `build ${cli.build}` },
  { id: 'FHP', nome: 'Forever-Hunter-Pets (MIT)', url: prof.fontes.fhp.repo, data: `sha ${prof.fontes.fhp.sha}` },
  { id: 'Petopia', nome: 'Petopia Forever', url: prof.fontes.petopia.url, data: (lidoPetopia || prof.fontes.petopia.lidoEm || hoje).slice(0, 10) },
];
if (saltii) {
  const sf = saltii.fonte;
  if (sf && typeof sf === 'object') fontes.push({ id: 'Saltii', nome: sf.titulo || sf.nome || 'Saltii (video cards)', url: sf.url || '', data: sf.publicado || sf.data || '' });
  else fontes.push({ id: 'Saltii', nome: typeof sf === 'string' ? sf : 'Saltii (video cards)', url: '', data: '' });
}
// as fontes descritas no textos.json entram antes das so citadas, para ficarem com nome e url
for (const x of textos?.fontes || []) if (!fontes.some((y) => y.id === x.id)) fontes.push(x);
const idsF = new Set(fontes.map((x) => x.id));
const usadas = [];
for (const r of regras) usadas.push(r.f);
for (const f of Object.values(textos?.familias || {})) for (const n of f.notas || []) usadas.push(n.f);
for (const h of Object.values(textos?.habilidades || {})) usadas.push(h.f);
for (const id of usadas) if (id && !idsF.has(id)) { idsF.add(id); fontes.push({ id, nome: id, url: '', data: '' }); }

const guia = limpa({
  gerado: hoje, build: cli.build, fontes, regras, familias, habilidades,
});
// campos extras so no JSON (nao vao para o Lua)
const guiaJson = { ...guia, divergencias, descartados, saltiiSemRank };
fs.writeFileSync(path.join(pasta, 'guia.json'), JSON.stringify(guiaJson, null, 1) + '\n');

// ---------- Lua ----------
const KW = new Set(['and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 'until', 'while']);
const q = (s) => '"' + s.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"';
const chaveLua = (k) => (/^[A-Za-z_]\w*$/.test(k) && !KW.has(k) ? k : '[' + q(k) + ']');
function lua(v, ind) {
  const pad = '  '.repeat(ind), pad1 = '  '.repeat(ind + 1);
  if (v === null || v === undefined) return 'nil';
  if (typeof v === 'string') return q(v);
  if (typeof v === 'number' || typeof v === 'boolean') return String(v);
  if (Array.isArray(v)) {
    if (!v.length) return '{}';
    if (v.every((x) => typeof x !== 'object')) return '{ ' + v.map((x) => lua(x, 0)).join(', ') + ' }';
    return '{\n' + v.map((x) => pad1 + lua(x, ind + 1) + ',').join('\n') + '\n' + pad + '}';
  }
  const es = Object.entries(v).filter(([, x]) => x !== undefined);
  if (!es.length) return '{}';
  const simples = es.every(([, x]) => x === null || typeof x !== 'object' || (Array.isArray(x) && x.every((y) => typeof y !== 'object')));
  const itens = es.map(([k, x]) => chaveLua(k) + ' = ' + lua(x, ind + 1));
  if (simples && itens.join(', ').length < 110) return '{ ' + itens.join(', ') + ' }';
  return '{\n' + itens.map((s) => pad1 + s + ',').join('\n') + '\n' + pad + '}';
}
const { gerado, build, ...resto } = guia;
const cab = [
  '-- PetGuia.lua: ARQUIVO GERADO, nao edite a mao.',
  '-- Gerado por ferramentas\\guia\\pets\\gerar-guia.mjs em ' + new Date().toISOString().slice(0, 16).replace('T', ' ') + ' (UTC).',
  '-- Fontes: habilidades.json, professores.json, feras.json' + (saltii ? ', saltii.json' : '') + (textos ? ', textos.json' : '') + ' e a pagina abilities.php da Petopia.',
  '-- Contrato: ARQUITETURA.md, secao 10.2. Para regerar: node gerar-guia.mjs --pasta <pets> --petopia <html> --lua <este arquivo>.',
  '',
].join('\n');
const corpo = lua({ gerado, build, ...resto }, 0);
const saida = cab + 'GuiaForeverPetGuia = ' + corpo + '\n';
fs.writeFileSync(luaSaida, saida);

// ---------- relatorio ----------
console.log(`guia.json e ${luaSaida} escritos (${saida.length} bytes de Lua).`);
console.log(`saltii.json: ${saltii ? 'usado' : 'AUSENTE (gerado sem ele)'}; textos.json: ${textos ? 'usado' : 'ausente (regras e notas vazias)'}`);
console.log(`familias ${familias.length}, habilidades ${Object.keys(habilidades).length}, ranks ${ranksTotal}, ranks com professor ${ranksComProf}`);
console.log(`Saltii: ${saltiiMarcados} marcados (${saltiiAcrescentados} acrescentados); chaves sem rank: ${saltiiSemRank.length ? saltiiSemRank.join(', ') : 'nenhuma'}`);
console.log(`Divergencias cliente x Petopia: ${divergencias.length}`);
for (const d of divergencias) console.log('  ' + d);
console.log(`Ranks descartados: ${descartados.length}`);
for (const d of descartados) console.log('  ' + d);
