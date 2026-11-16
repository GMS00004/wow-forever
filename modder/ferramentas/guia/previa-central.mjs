// Previa da central de combate (CentralForever): PNG em tamanho real sobre o recorte do print do dono.
// Le as fotos da bancada (visual\cache\central-C*.json: arvore de quadros), resolve ancoras, monta HTML e
// fotografa pelo Edge sem tela (como visual\renderizar.mjs). 1 unidade de UI = 1,3125 px (2560x1440, escala 0.7).
// Uso: node previa-central.mjs        Saida: 0 se todas as imagens foram geradas, 1 se alguma falhou.
// Contrato: addons-proprios\CentralForever\CONTRATO.md, secoes 5 e 11.5.
import { execFileSync } from "node:child_process";
import { mkdirSync, existsSync, readFileSync, writeFileSync, rmSync, openSync, readSync, closeSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { tmpdir } from "node:os";

const aqui = dirname(fileURLToPath(import.meta.url));
const cache = join(aqui, "visual", "cache");
const pastaPng = join(aqui, "visual", "png");
const pastaHtml = join(cache, "previa");
const FUNDO = existsSync(join(pastaPng, "canto-base-limpo.png")) ? join(pastaPng, "canto-base-limpo.png") : join(pastaPng, "canto-base.png");
const FONTES = {
  expressway: { arq: "C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/ElvUI/Game/Shared/Media/Fonts/Expressway.ttf", fam: "FExp" },
  atkinson: { arq: join(cache, "fontes", "AtkinsonHyperlegibleMono-Bold.ttf").replaceAll("\\", "/"), fam: "FAtk" },
};
const S = 1.3125;          // px por unidade de UI
const LARG = 1000, ALT = 600;
const edge = ["C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", "C:/Program Files/Microsoft/Edge/Application/msedge.exe"].find(existsSync);
if (!edge) { console.error("RECUSA msedge.exe nao encontrado"); process.exit(2); }
for (const f of [FUNDO, ...Object.values(FONTES).map((x) => x.arq)]) if (!existsSync(f)) { console.error(`RECUSA falta ${f}`); process.exit(2); }
mkdirSync(pastaPng, { recursive: true });
mkdirSync(pastaHtml, { recursive: true });
const comum = ["--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
  "--force-device-scale-factor=1", "--virtual-time-budget=6000", `--user-data-dir=${join(process.env.TEMP || tmpdir(), "central-previa-edge")}`];

// ---------- fotos ----------
const ESTADOS = [
  ["cacador-safe", "C02", "cacador SAFE"], ["cacador-close", "C09", "cacador CLOSE"], ["cacador-onyou", "C10", "cacador ON YOU"],
  ["tanque-held", "C12", "tanque HELD"], ["tanque-slipping", "C12", "tanque SLIPPING"], ["tanque-lost", "C13", "tanque LOST"],
  ["pos-luta", "C03", "pos-luta"], ["resumo", "C03", "resumo (so texto)"],
];
const cacheJson = {};
function foto(nome) {
  const e = ESTADOS.find((x) => x[0] === nome);
  const arq = join(cache, `central-${e[1]}.json`);
  cacheJson[arq] ??= JSON.parse(readFileSync(arq, "utf8"));
  const f = cacheJson[arq].fotos.find((x) => x.nome === nome);
  if (!f) throw new Error(`foto ${nome} nao existe em ${arq}`);
  return f;
}

// ---------- resolucao de ancoras (x: unidades, direita da tela = 0, esquerda negativa; y: para cima, a partir do chao) ----------
const faltas = new Set();
const HX = { LEFT: "L", RIGHT: "R", TOP: "C", BOTTOM: "C", CENTER: "C" };
function partesPonto(p) {
  const h = p.includes("LEFT") ? "L" : p.includes("RIGHT") ? "R" : "C";
  const v = p.includes("TOP") ? "T" : p.includes("BOTTOM") ? "B" : "M";
  return [h, v];
}
function indexar(arvore) {
  const porId = new Map(), porNome = new Map(), pais = new Map();
  const visita = (q, pai) => {
    porId.set(q.id, q); if (q.nome) porNome.set(q.nome, q); pais.set(q, pai);
    for (const r of q.regioes || []) { porId.set(r.id, r); pais.set(r, q); }
    for (const c of q.filhos || []) visita(c, q);
  };
  for (const q of arvore) visita(q, null);
  return { porId, porNome, pais };
}
function retangulo(obj, ix, memo = new Map()) {
  if (memo.has(obj)) return memo.get(obj);
  let ret = null;
  if (obj.nome === "UIParent") ret = { l: -(obj.largura ?? 3657), r: 0, b: 0, t: obj.altura ?? 2057 };
  else if (obj.ponto && obj.ponto.length) {
    const L = [], R = [], C = [], T = [], B = [], M = [];
    const pontos = [];
    for (const p of obj.ponto) {
      if (p.ponto === "ALL") { pontos.push({ ponto: "TOPLEFT", rel: p.rel, relPonto: "TOPLEFT", x: 0, y: 0 }, { ponto: "BOTTOMRIGHT", rel: p.rel, relPonto: "BOTTOMRIGHT", x: 0, y: 0 }); }
      else pontos.push(p);
    }
    for (const p of pontos) {
      const alvoObj = p.rel ? (p.rel.startsWith("#") ? ix.porId.get(Number(p.rel.slice(1))) : ix.porNome.get(p.rel)) : ix.pais.get(obj);
      if (!alvoObj) { faltas.add(`ancora de ${obj.id} aponta para "${p.rel}" que nao esta na arvore`); continue; }
      const a = retangulo(alvoObj, ix, memo);
      if (!a) continue;
      const [oh, ov] = partesPonto(p.ponto), [th, tv] = partesPonto(p.relPonto || p.ponto);
      const ax = (th === "L" ? a.l : th === "R" ? a.r : (a.l + a.r) / 2) + (p.x || 0);
      const ay = (tv === "B" ? a.b : tv === "T" ? a.t : (a.b + a.t) / 2) + (p.y || 0);
      (oh === "L" ? L : oh === "R" ? R : C).push(ax);
      (ov === "T" ? T : ov === "B" ? B : M).push(ay);
    }
    const eixo = (mn, mx, md, tam, nome) => {
      if (mn.length && mx.length) return [mn[0], mx[0]];
      if (tam == null) { faltas.add(`${nome} do objeto ${obj.id} (${obj.tipo}) nao esta na arvore`); return null; }
      if (mn.length) return [mn[0], mn[0] + tam];
      if (mx.length) return [mx[0] - tam, mx[0]];
      if (md.length) return [md[0] - tam / 2, md[0] + tam / 2];
      return null;
    };
    const ex = eixo(L, R, C, obj.largura, "largura");
    const ey = eixo(B, T, M, obj.altura, "altura");
    if (ex && ey) ret = { l: ex[0], r: ex[1], b: ey[0], t: ey[1] };
  }
  memo.set(obj, ret);
  return ret;
}

// campos de dano pela estrutura (nao por id): no quadro que tem o texto "DPS", os textos alinhados a direita
// que nao sao rotulos, na ordem da arvore = dps, luta, total, tempo. Threat: os dois primeiros textos centralizados = palavra, linha2.
function campos(ix, painel) {
  const dano = [], threat = [];
  const rec = (q) => {
    const fs = (q.regioes || []).filter((r) => r.tipo === "FontString" && r.texto != null);
    if (fs.some((r) => r.texto === "DPS")) dano.push(...fs.filter((r) => r.justifyH === "RIGHT" && !["DPS", "FIGHT", "TOTAL"].includes(r.texto)));
    else { const c = fs.filter((r) => r.justifyH === "CENTER"); if (c.length >= 2 && !threat.length) threat.push(c[0], c[1]); }
    for (const f of q.filhos || []) rec(f);
  };
  rec(painel);
  return { dano, threat };
}
const AMOSTRA = ["412", "45.6K", "1.24M", "1:23"];
const COM_AMOSTRA = new Set(["cacador-close", "cacador-onyou", "tanque-held", "tanque-slipping", "tanque-lost", "cacador-safe"]);

// ---------- foto -> lista de itens a desenhar ----------
const ORDEM_CAMADA = { BACKGROUND: 0, BORDER: 1, ARTWORK: 2, OVERLAY: 3 };
function itens(f, { fundoDano = false } = {}) {
  const ix = indexar(f.arvore), memo = new Map(), out = [];
  const painel = ix.porNome.get("CentralForeverPainel");
  const amostra = new Map();
  if (COM_AMOSTRA.has(f.nome)) {
    const { dano } = campos(ix, painel);
    if (dano.length === 4 && ["0", "", "--"].includes(String(dano[0].texto))) dano.forEach((r, i) => amostra.set(r.id, AMOSTRA[i]));
  }
  const forcados = new Set();
  if (fundoDano) {
    // fundo e borda escondidos (visivel falso) em quadros efetivamente visiveis passam a visiveis
    const rec = (q) => { if (q.visivelEfetivo) for (const r of q.regioes || []) if (r.tipo === "Texture" && r.visivel === false && !r.animacoes) forcados.add(r.id); for (const c of q.filhos || []) rec(c); };
    rec(painel);
  }
  const vis = (o) => (o.visivelEfetivo || forcados.has(o.id)) && (o.alfaEfetivo ?? 1) > 0;
  const emiteRegiao = (r) => {
    if (!vis(r)) return;
    const ret = retangulo(r, ix, memo);
    if (!ret) return;
    const op = (r.alfaEfetivo ?? 1);
    if (r.tipo === "Texture") {
      if (!r.cor) { faltas.add(`cor da textura ${r.id}`); return; }
      out.push({ k: "rect", ...ret, cor: r.cor, op });
    } else if (r.tipo === "FontString") {
      if (amostra.has(r.id)) r = { ...r, texto: amostra.get(r.id) };
      if (r.texto == null || r.texto === "") return;
      if (!r.fonte || !r.fonte.tamanho) { faltas.add(`tamanho da fonte do texto ${r.id} ("${r.texto}")`); return; }
      if (!r.justifyH) faltas.add(`justifyH do texto ${r.id}: usei CENTER (padrao do jogo)`);
      out.push({ k: "texto", ...ret, texto: String(r.texto), tam: r.fonte.tamanho, cor: r.cor || [1, 1, 1, 1], op, j: r.justifyH || "CENTER" });
    }
  };
  const quadro = (q) => {
    if (q.tipo === "StatusBar") {
      if (!vis(q)) return;
      const ret = retangulo(q, ix, memo);
      const regs = [...(q.regioes || [])].sort((a, b) => (ORDEM_CAMADA[a.camada] ?? 2) - (ORDEM_CAMADA[b.camada] ?? 2));
      for (const r of regs) if ((ORDEM_CAMADA[r.camada] ?? 2) < 2) emiteRegiao(r);
      if (ret && q.valor != null && q.max != null && q.min != null) {
        const p = Math.max(0, Math.min(1, (q.valor - q.min) / (q.max - q.min)));
        out.push({ k: "rect", l: ret.l, r: ret.l + (ret.r - ret.l) * p, b: ret.b, t: ret.t, cor: q.cor || [1, 1, 1, 1], op: q.alfaEfetivo ?? 1 });
      } else faltas.add("valor/min/max da regua");
      for (const r of regs) if ((ORDEM_CAMADA[r.camada] ?? 2) >= 2) emiteRegiao(r);
    } else {
      if (!q.visivelEfetivo) return;
      for (const r of [...(q.regioes || [])].sort((a, b) => (ORDEM_CAMADA[a.camada] ?? 2) - (ORDEM_CAMADA[b.camada] ?? 2))) emiteRegiao(r);
    }
    for (const c of q.filhos || []) quadro(c);
  };
  quadro(painel);
  return { itens: out, painel: retangulo(painel, ix, memo) };
}

// ---------- HTML ----------
const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const rgb = (c) => `rgb(${Math.round(c[0] * 255)},${Math.round(c[1] * 255)},${Math.round(c[2] * 255)})`;
const px = (n) => `${+n.toFixed(3)}px`;
const X = (u) => LARG + u * S;           // x em unidades (direita = 0) -> px
const Y = (u) => ALT - u * S;            // y em unidades (do chao) -> px
const SOMBRA = "-1.3px -1.3px 0 #000,0 -1.3px 0 #000,1.3px -1.3px 0 #000,-1.3px 0 0 #000,1.3px 0 0 #000,-1.3px 1.3px 0 #000,0 1.3px 0 #000,1.3px 1.3px 0 #000";
const JUST = { LEFT: "flex-start", RIGHT: "flex-end", CENTER: "center" };

function cena(lista, extras = "") {
  let h = `<img src="${pathToFileURL(FUNDO).href}" style="position:absolute;left:0;top:0;width:${LARG}px;height:${ALT}px">`;
  for (const i of lista) {
    const box = `left:${px(X(i.l))};top:${px(Y(i.t))};width:${px((i.r - i.l) * S)};height:${px((i.t - i.b) * S)}`;
    if (i.k === "rect") {
      const a = (i.cor[3] ?? 1) * i.op;
      h += `<div style="position:absolute;${box};background:${rgb(i.cor)};opacity:${+a.toFixed(4)}"></div>`;
    } else {
      const a = (i.cor[3] ?? 1) * i.op;
      h += `<div class="t" style="${box};justify-content:${JUST[i.j]};font-size:${px(i.tam * S)};color:${rgb(i.cor)};opacity:${+a.toFixed(4)}"><span>${esc(i.texto)}</span></div>`;
    }
  }
  return h + extras;
}
function pagina(corpo, w, h, fontesUsadas) {
  const faces = fontesUsadas.map((n) => `@font-face{font-family:"${FONTES[n].fam}";src:url("${pathToFileURL(FONTES[n].arq).href}");font-weight:normal;font-style:normal}`).join("\n");
  return `<!doctype html><html><head><meta charset="utf-8"><style>
${faces}
html,body{margin:0;padding:0;background:#0b0b0b;overflow:hidden}
body{width:${w}px;height:${h}px;position:relative;font-family:"Segoe UI",Arial,sans-serif}
.cena{position:absolute;width:${LARG}px;height:${ALT}px;overflow:hidden}
.t{position:absolute;display:flex;align-items:center;white-space:nowrap;line-height:1;font-synthesis:none;text-shadow:${SOMBRA}}
.t span{display:block}
.FExp{font-family:"FExp"} .FAtk{font-family:"FAtk"}
.leg{position:absolute;color:#ddd;font-size:13px;line-height:1.3;white-space:nowrap}
.ref{position:absolute;box-sizing:border-box;border:1px dashed;font-size:10px;line-height:11px;padding:1px 2px;white-space:nowrap}
</style></head><body>${corpo}</body></html>`;
}
const cenaDiv = (fonte, lista, extras, style = "") => `<div class="cena ${FONTES[fonte].fam}" style="${style}">${cena(lista, extras)}</div>`;

// ---------- Edge ----------
const geradas = [], falhas = [];
function pngTamanho(arq) {
  const fd = openSync(arq, "r"), b = Buffer.alloc(24); readSync(fd, b, 0, 24, 0); closeSync(fd);
  return [b.readUInt32BE(16), b.readUInt32BE(20)];
}
function fotografar(nomeHtml, html, w, h, nomePng, fontes) {
  const arqHtml = join(pastaHtml, `${nomeHtml}.html`);
  writeFileSync(arqHtml, html, "utf8");
  const arq = join(pastaPng, nomePng);
  try {
    if (existsSync(arq)) rmSync(arq);
    execFileSync(edge, [...comum, `--window-size=${w},${h}`, `--screenshot=${arq}`, pathToFileURL(arqHtml).href], { stdio: "ignore", timeout: 90000 });
  } catch { /* checado abaixo */ }
  if (existsSync(arq)) {
    const [pw, ph] = pngTamanho(arq);
    if (pw !== w || ph !== h) console.log(`AVISO ${nomePng} saiu ${pw}x${ph}, esperado ${w}x${h}`);
    geradas.push(nomePng); console.log(`OK ${nomePng} (${pw}x${ph})`);
  } else { falhas.push(nomePng); console.log(`FALHOU ${nomePng}`); }
}

// ---------- refs e tooltip ----------
const REFS = [
  ["datatexts", 4, 476, 4, 27, "#ff5ad1"], ["barra 6", 4, 194, 264, 294, "#ffd34a"],
  ["quadro do alvo", 425, 755, 139, 221, "#4ad8ff"], ["alvo-do-alvo e foco", 455, 725, 60, 114, "#7dff6a"],
];
const caixaPx = (r1, r2, y1, y2) => `left:${px(X(-r2))};top:${px(Y(y2))};width:${px((r2 - r1) * S)};height:${px((y2 - y1) * S)}`;
function extrasTooltip() {
  let h = "";
  // tooltip simulado: 250 x 300, canto inferior direito a 4 da borda e 126 do chao; barra de vida de 12 logo abaixo
  h += `<div style="position:absolute;${caixaPx(4, 254, 126, 426)};box-sizing:border-box;background:rgba(10,10,14,.93);border:1px solid #6e6e78"></div>`;
  h += `<div class="leg" style="left:${px(X(-254) + 8)};top:${px(Y(426) + 6)};color:#9a9aa5;font-size:11px">tooltip simulado 250 x 300</div>`;
  h += `<div style="position:absolute;${caixaPx(4, 254, 114, 126)};box-sizing:border-box;background:#2f8f3a;border:1px solid #000"></div>`;
  for (const [nome, r1, r2, y1, y2, cor] of REFS)
    h += `<div class="ref" style="${caixaPx(r1, r2, y1, y2)};border-color:${cor};color:${cor}">${nome}</div>`;
  return h;
}

// ---------- imagens ----------
const nomesFontes = Object.keys(FONTES);
const sets = {};      // [nomeFoto] -> { itens, painel }
for (const [n] of ESTADOS) sets[n] = itens(foto(n));
sets["resumo-fundo"] = itens(foto("resumo"), { fundoDano: true });
const painelRet = sets["cacador-close"].painel;

for (const fn of nomesFontes) {
  for (const [n] of ESTADOS) fotografar(`central-${n}-${fn}`, pagina(cenaDiv(fn, sets[n].itens, "", "left:0;top:0"), LARG, ALT, [fn]), LARG, ALT, `central-${n}-${fn}.png`);
  fotografar(`central-resumo-fundo-${fn}`, pagina(cenaDiv(fn, sets["resumo-fundo"].itens, "", "left:0;top:0"), LARG, ALT, [fn]), LARG, ALT, `central-resumo-fundo-${fn}.png`);
  fotografar(`central-tooltip-${fn}`, pagina(cenaDiv(fn, sets["cacador-close"].itens, extrasTooltip(), "left:0;top:0"), LARG, ALT, [fn]), LARG, ALT, `central-tooltip-${fn}.png`);
}

// recorte do painel com margem: 620 x 130 px, encostado na direita da tela
const RW = 620, RH = 130, LEG = 230, GAP = 8;
const rx = LARG - RW;
const ry = Math.round(Y(painelRet.b) + 16 - RH);      // painel ~ 16 px acima do fim do recorte
const recorte = (fn, lista, left, top, extras = "") =>
  `<div style="position:absolute;left:${left}px;top:${top}px;width:${RW}px;height:${RH}px;overflow:hidden;outline:1px solid #444">` +
  cenaDiv(fn, lista, extras, `left:${-rx}px;top:${-Math.max(0, Math.min(ALT - RH, ry))}px`) + `</div>`;
const todosEstados = [...ESTADOS.map((e) => [e[0], e[2], sets[e[0]].itens]), ["resumo-fundo", "resumo (com fundo)", sets["resumo-fundo"].itens]];
for (const fn of nomesFontes) {
  let corpo = "", y = GAP;
  for (const [n, leg, lista] of todosEstados) {
    corpo += recorte(fn, lista, GAP, y);
    corpo += `<div class="leg" style="left:${GAP * 2 + RW}px;top:${y + 8}px"><b>${n}</b><br>${leg}<br>${fn}</div>`;
    y += RH + GAP;
  }
  corpo += `<div class="leg" style="left:${GAP}px;top:${y + 2}px">damage numbers are samples (combat states; pos-luta and resumo are real)</div>`;
  y += 24;
  fotografar(`central-folha-${fn}`, pagina(corpo, RW + LEG + GAP * 2, y, [fn]), RW + LEG + GAP * 2, y, `central-folha-${fn}.png`);
}
{
  let corpo = "", y = GAP;
  for (const n of ["cacador-close", "tanque-slipping"])
    for (const fn of nomesFontes) {
      corpo += recorte(fn, sets[n].itens, GAP, y);
      corpo += `<div class="leg" style="left:${GAP * 2 + RW}px;top:${y + 8}px"><b>${n}</b><br>${fn}</div>`;
      y += RH + GAP;
    }
  const w = RW + LEG + GAP * 2;
  fotografar("central-fontes", pagina(corpo, w, y, nomesFontes), w, y, "central-fontes.png");
}

// ---------- teste ESTOURO ----------
const arvC = indexar(foto("cacador-close").arvore);
const cc = campos(arvC, arvC.porNome.get("CentralForeverPainel"));
const CAMPOS = [["dps", cc.dano[0], "88888"], ["luta", cc.dano[1], "888.8K"], ["total", cc.dano[2], "888.8K"], ["tempo", cc.dano[3], "88:88"], ["palavra", cc.threat[0], "SLIPPING"], ["linha2", cc.threat[1], "Voidwal 100%"]];
const medir = CAMPOS.map(([nome, r, texto]) => {
  const id = r?.id;
  if (!r || !r.fonte?.tamanho || r.largura == null) { faltas.add(`campo ${nome} (id ${id}) sem tamanho de fonte ou largura na arvore`); return null; }
  return { nome, texto, tam: r.fonte.tamanho, caixa: r.largura };
}).filter(Boolean);
let estouro = 0;
{
  let spans = "";
  for (const fn of nomesFontes) for (const m of medir)
    spans += `<span class="m" data-k="${m.nome};${fn}" data-tam="${m.tam}" data-fam="${FONTES[fn].fam}" data-texto="${esc(m.texto)}" style="font-family:'${FONTES[fn].fam}';font-size:${m.tam * S}px">${esc(m.texto)}</span><br>`;
  const js = `
  var els=[].slice.call(document.querySelectorAll('.m'));
  Promise.all(els.map(function(e){return document.fonts.load(e.style.fontSize+' "'+e.getAttribute('data-fam')+'"', e.getAttribute('data-texto'));})).then(function(){
    var linhas=els.map(function(e){return e.getAttribute('data-k')+';'+e.getBoundingClientRect().width.toFixed(3)+';'+document.fonts.check(e.style.fontSize+' "'+e.getAttribute('data-fam')+'"');});
    var p=document.createElement('pre');p.id='res';p.textContent=linhas.join('|');document.body.appendChild(p);
  });`;
  const html = `<!doctype html><html><head><meta charset="utf-8"><style>
${nomesFontes.map((n) => `@font-face{font-family:"${FONTES[n].fam}";src:url("${pathToFileURL(FONTES[n].arq).href}")}`).join("\n")}
.m{white-space:nowrap;display:inline-block;line-height:1}</style></head><body>${spans}<script>${js}</script></body></html>`;
  const arqM = join(pastaHtml, "medir.html");
  writeFileSync(arqM, html, "utf8");
  let dom = "";
  try { dom = execFileSync(edge, [...comum, "--window-size=800,600", "--dump-dom", pathToFileURL(arqM).href], { encoding: "utf8", timeout: 90000, stdio: ["ignore", "pipe", "ignore"] }); } catch { /* sem medicao */ }
  const m = dom.match(/<pre id="res">([^<]*)<\/pre>/);
  if (!m) { console.log("ESTOURO: medicao falhou (sem resultado no DOM)"); falhas.push("medicao"); }
  else {
    for (const l of m[1].split("|")) {
      const [campo, fn, w, ok] = l.split(";");
      const c = medir.find((x) => x.nome === campo);
      const caixaPx2 = c.caixa * S, larg = Number(w);
      const estoura = larg > caixaPx2 + 0.01;
      if (estoura) estouro++;
      console.log(`${campo.padEnd(8)} ${fn.padEnd(10)} "${c.texto}" ${c.tam}u  largura ${larg.toFixed(1)} px  caixa ${caixaPx2.toFixed(1)} px (${c.caixa}u)  ${estoura ? "ESTOURA" : "cabe"}${ok === "true" ? "" : "  (AVISO: fonte nao carregou, medida invalida)"}`);
    }
  }
}
console.log(`ESTOURO ${estouro}`);

// ---------- teste SOBREPOSICAO ----------
let sobre = 0;
{
  const p = painelRet;
  console.log(`painel (arvore): x ${(-p.r).toFixed(0)}..${(-p.l).toFixed(0)} da borda direita, y ${p.b}..${p.t} do chao`);
  for (const [nome, r1, r2, y1, y2] of REFS) {
    const sx = -p.r < r2 && r1 < -p.l, sy = p.b < y2 && y1 < p.t;
    const so = sx && sy;
    if (so) sobre++;
    console.log(`${nome.padEnd(20)} x ${r1}-${r2} y ${y1}-${y2}  ${so ? "SOBREPOE" : "livre"}`);
  }
}
console.log(`SOBREPOSICAO ${sobre}`);
for (const f of faltas) console.log(`FALTA NA ARVORE: ${f}`);
console.log(`imagens geradas: ${geradas.length}`);
console.log(geradas.join("\n"));
process.exit(falhas.length ? 1 : 0);
