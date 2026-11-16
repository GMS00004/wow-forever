// Fotografa cada quadro de telas.html (telas.html#next, #sell, ...) pelo Edge sem tela e grava em png\.
// Uso: node renderizar.mjs [id ...]   (sem argumento, todos)
// O tamanho de cada foto vem da propria pagina: no modo de foto ela grava data-w e data-h no body.
import { execFileSync } from "node:child_process";
import { mkdirSync, existsSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const aqui = dirname(fileURLToPath(import.meta.url));
const edge = ["C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", "C:/Program Files/Microsoft/Edge/Application/msedge.exe"].find(existsSync);
if (!edge) { console.error("RECUSA msedge.exe nao encontrado"); process.exit(2); }
const saida = join(aqui, "png");
mkdirSync(saida, { recursive: true });
const TODOS = ["lado", "next", "bilhetes", "sell", "mine", "risk", "session", "mail", "avisos", "teclas"];
const ids = process.argv.slice(2).length ? process.argv.slice(2) : TODOS;
const base = pathToFileURL(join(aqui, "telas.html")).href;
const comum = ["--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1", "--virtual-time-budget=3000",
  `--user-data-dir=${join(process.env.TEMP || aqui, "pregao-telas-edge")}`];
let falhas = 0;
for (const id of ids) {
  const url = `${base}#${id}`;
  let w = 620, h = 620;
  try {
    const dom = execFileSync(edge, [...comum, "--window-size=1600,1200", "--dump-dom", url], { encoding: "utf8", timeout: 60000, stdio: ["ignore", "pipe", "ignore"], maxBuffer: 64 * 1024 * 1024 });
    const mw = dom.match(/data-w="(\d+)"/), mh = dom.match(/data-h="(\d+)"/);
    if (mw && mh) { w = Number(mw[1]); h = Number(mh[1]); } else { console.log(`AVISO ${id}: a pagina nao informou o tamanho; usando ${w}x${h}`); }
  } catch { console.log(`AVISO ${id}: nao consegui medir; usando ${w}x${h}`); }
  const arq = join(saida, `${id}.png`);
  try { execFileSync(edge, [...comum, `--window-size=${w},${h}`, `--screenshot=${arq}`, url], { stdio: "ignore", timeout: 60000 }); } catch { /* confere abaixo */ }
  if (existsSync(arq) && statSync(arq).size > 2000) console.log(`OK ${id} ${w}x${h} ${arq}`); else { console.log(`FALHOU ${id}`); falhas++; }
}
process.exit(falhas ? 1 : 0);
