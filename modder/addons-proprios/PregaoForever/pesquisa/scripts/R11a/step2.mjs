import { load } from './csv.mjs';

const PROF_PRIMARY = { 164: 'Blacksmithing', 165: 'Leatherworking', 171: 'Alchemy', 182: 'Herbalism', 186: 'Mining', 197: 'Tailoring', 202: 'Engineering', 333: 'Enchanting', 393: 'Skinning', 129: 'First Aid', 185: 'Cooking', 356: 'Fishing' };
const PROF_CHILD = { 2937: 'Alchemy', 2938: 'Blacksmithing', 2939: 'Cooking', 2940: 'Enchanting', 2941: 'Engineering', 2942: 'First Aid', 2943: 'Fishing', 2944: 'Herbalism', 2945: 'Leatherworking', 2946: 'Mining', 2947: 'Skinning', 2948: 'Tailoring' };
const PROF = { ...PROF_PRIMARY, ...PROF_CHILD };

// SkillLineAbility
const sla = load('SkillLineAbility');
console.log('SLA rows', sla.rows.length, 'header', sla.header.join(','));
const slaSample = sla.rows.filter(r => PROF[r[sla.idx.SkillLine]]).slice(0, 3);
console.log('SLA sample prof rows (first 3):');
for (const r of slaSample) console.log(r.join(' | '));
const slaByProf = {};
for (const r of sla.rows) {
  const s = r[sla.idx.SkillLine];
  if (!PROF[s]) continue;
  slaByProf[s] ??= [];
  slaByProf[s].push(r);
}
console.log('SLA rows per profession skill line:');
for (const s of Object.keys(slaByProf)) console.log(s, PROF[s], slaByProf[s].length);

// SpellReagents
const sr = load('SpellReagents');
const reagentsBySpell = new Map();
for (const r of sr.rows) {
  const spell = r[sr.idx.SpellID];
  const list = [];
  for (let i = 0; i < 8; i++) {
    const id = Number(r[sr.idx['Reagent_' + i]]);
    const cnt = Number(r[sr.idx['ReagentCount_' + i]]);
    if (id > 0) list.push({ item: id, count: cnt });
  }
  if (list.length) reagentsBySpell.set(spell, list);
}
console.log('SpellReagents rows', sr.rows.length, 'spells with >=1 reagent', reagentsBySpell.size);

// SpellEffect
const se = load('SpellEffect');
console.log('SpellEffect rows', se.rows.length);
const CREATE_ITEM = '24';
const createBySpell = new Map();
const effTypeCount = {};
for (const r of se.rows) {
  const eff = r[se.idx.Effect];
  effTypeCount[eff] = (effTypeCount[eff] || 0) + 1;
  if (eff === CREATE_ITEM) {
    const spell = r[se.idx.SpellID];
    if (!createBySpell.has(spell)) createBySpell.set(spell, []);
    createBySpell.get(spell).push({
      itemType: r[se.idx.EffectItemType],
      basePointsF: r[se.idx.EffectBasePointsF],
      misc0: r[se.idx.EffectMiscValue_0],
      effIndex: r[se.idx.EffectIndex],
      difficulty: r[se.idx.DifficultyID],
      dieSides: 'n/a',
    });
  }
}
console.log('Effect 24 count rows', (effTypeCount[CREATE_ITEM] || 0), 'spells with create_item', createBySpell.size);

// Sample create item effects for first recipe spells
const spellName = load('SpellName');
const nameOf = new Map(spellName.rows.map(r => [r[0], r[1]]));
const isn = load('ItemSparse');
const itemName = new Map(isn.rows.map(r => [r[isn.idx.ID], r[isn.idx.Display_lang]]));

// recipe spells per profession
const recipes = {};
const seen = new Set();
for (const r of sla.rows) {
  const s = r[sla.idx.SkillLine];
  if (!PROF[s]) continue;
  const spell = r[sla.idx.Spell];
  const key = PROF[s];
  recipes[key] ??= { total_sla: 0, with_reagents: 0, with_create: 0, without_create: 0, sample_create: [], sample_enchant: [] };
  recipes[key].total_sla++;
  if (!reagentsBySpell.has(spell)) continue;
  recipes[key].with_reagents++;
  if (createBySpell.has(spell)) {
    recipes[key].with_create++;
    if (recipes[key].sample_create.length < 3) {
      const ce = createBySpell.get(spell)[0];
      recipes[key].sample_create.push({ sla: r.join(' | '), spell, spellName: nameOf.get(spell), itemType: ce.itemType, itemName: itemName.get(ce.itemType), basePointsF: ce.basePointsF, reagents: reagentsBySpell.get(spell) });
    }
  } else {
    recipes[key].without_create++;
    if (recipes[key].sample_enchant.length < 3) recipes[key].sample_enchant.push({ spell, spellName: nameOf.get(spell), reagents: reagentsBySpell.get(spell) });
  }
}
console.log(JSON.stringify(recipes, null, 1));

// Dedup per spell across profession rows
const uniqueRecipeSpells = new Set();
for (const r of sla.rows) {
  if (!PROF[r[sla.idx.SkillLine]]) continue;
  if (reagentsBySpell.has(r[sla.idx.Spell])) uniqueRecipeSpells.add(r[sla.idx.Spell]);
}
let uc = 0, ue = 0;
for (const sp of uniqueRecipeSpells) (createBySpell.has(sp) ? uc++ : ue++);
console.log('unique recipe spells', uniqueRecipeSpells.size, 'create', uc, 'no-create', ue);
