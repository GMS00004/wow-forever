import { load } from './csv.mjs';
import { writeFileSync } from 'node:fs';

const PROF_PRIMARY = [164, 165, 171, 182, 186, 197, 202, 333, 393, 129, 185, 356];
const profSet = new Set(PROF_PRIMARY.map(String));

function pick(t, row, cols) {
  return cols.map(c => `${c}=${row[t.idx[c]]}`).join(' ; ');
}

// Samples of 3 rows, selected columns
const sampleCols = {
  ItemSparse: ['ID', 'Display_lang', 'SellPrice', 'BuyPrice', 'VendorStackCount', 'Stackable', 'MaxCount', 'OverallQualityID', 'ItemLevel', 'RequiredLevel', 'Bonding'],
  Item: ['ID', 'ClassID', 'SubclassID', 'InventoryType', 'CraftingQualityID', 'ItemSquishEraID'],
  ItemSubClass: ['ID', 'DisplayName_lang', 'ClassID', 'SubClassID'],
  SpellReagents: ['ID', 'SpellID', 'Reagent_0', 'Reagent_1', 'ReagentCount_0', 'ReagentCount_1'],
  SpellEffect: ['ID', 'SpellID', 'EffectIndex', 'Effect', 'EffectItemType', 'EffectBasePointsF', 'EffectMiscValue_0', 'DifficultyID'],
  SkillLineAbility: ['ID', 'SkillLine', 'Spell', 'MinSkillLineRank', 'TrivialSkillLineRankHigh', 'TrivialSkillLineRankLow', 'SkillupSkillLineID', 'AcquireMethod'],
  SkillLine: ['ID', 'DisplayName_lang', 'CategoryID', 'ParentSkillLineID'],
  SpellName: ['ID', 'Name_lang'],
  AuctionHouse: ['ID', 'Name_lang', 'FactionID', 'DepositRate', 'ConsignmentRate'],
};
for (const name of Object.keys(sampleCols)) {
  const t = load(name);
  console.log(`== ${name} rows=${t.rows.length} cols=${t.header.length}`);
  for (const r of t.rows.slice(0, 3)) console.log('  ' + pick(t, r, sampleCols[name]));
}

// item details for recipe products
const isp = load('ItemSparse');
const ids = ['2842', '2302', '2454', '4357', '2570', '2996', '2318', '2320', '2449', '765', '3371', '2840', '2589'];
console.log('== ItemSparse details for sample items');
for (const r of isp.rows) {
  if (ids.includes(r[isp.idx.ID])) console.log('  ' + pick(isp, r, ['ID', 'Display_lang', 'SellPrice', 'BuyPrice', 'VendorStackCount', 'Stackable', 'MaxCount', 'OverallQualityID', 'ItemLevel', 'RequiredLevel', 'Bonding', 'ContainerSlots', 'PriceVariance']));
}

// Lua estimate
const sla = load('SkillLineAbility');
const sr = load('SpellReagents');
const se = load('SpellEffect');
const reagents = new Map();
for (const r of sr.rows) {
  const list = [];
  for (let i = 0; i < 8; i++) {
    const id = Number(r[sr.idx['Reagent_' + i]]);
    const cnt = Number(r[sr.idx['ReagentCount_' + i]]);
    if (id > 0) list.push([id, cnt]);
  }
  if (list.length) reagents.set(r[sr.idx.SpellID], list);
}
const create = new Map();
for (const r of se.rows) {
  if (r[se.idx.Effect] === '24') {
    if (!create.has(r[se.idx.SpellID])) create.set(r[se.idx.SpellID], { item: Number(r[se.idx.EffectItemType]), qty: Number(r[se.idx.EffectBasePointsF]) });
  }
}
// build lines
const byProf = {};
const seenPair = new Set();
let nRecipes = 0;
for (const r of sla.rows) {
  const s = r[sla.idx.SkillLine];
  if (!profSet.has(s)) continue;
  const spell = r[sla.idx.Spell];
  if (!reagents.has(spell)) continue;
  const key = s + ':' + spell;
  if (seenPair.has(key)) continue;
  seenPair.add(key);
  const rg = reagents.get(spell).map(([i, c]) => `{${i},${c}}`).join(',');
  const cr = create.get(spell);
  const entry = `[${spell}]={${cr ? cr.item : 0},${cr ? cr.qty : 0},{${rg}}}`;
  (byProf[s] ??= []).push(entry);
  nRecipes++;
}
let lua = 'GF_RECIPES={\n';
for (const s of Object.keys(byProf)) lua += `[${s}]={${byProf[s].join(',')}},\n`;
lua += '}\n';
writeFileSync('<tmp>/R11a/recipes_estimate.lua', lua);
console.log('LUA recipes', nRecipes, 'bytes', Buffer.byteLength(lua, 'utf8'), 'KB', (Buffer.byteLength(lua, 'utf8') / 1024).toFixed(1));
console.log('sample line:', byProf['171'] ? byProf['171'][0] : 'none');
