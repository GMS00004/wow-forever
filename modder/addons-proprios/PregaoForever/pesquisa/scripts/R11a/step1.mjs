import { load } from './csv.mjs';

const sl = load('SkillLine');
console.log('SkillLine rows', sl.rows.length);
for (const r of sl.rows) {
  console.log([r[sl.idx.ID], r[sl.idx.DisplayName_lang], 'cat=' + r[sl.idx.CategoryID], 'parent=' + r[sl.idx.ParentSkillLineID], 'spellbook=' + r[sl.idx.SpellBookSpellID]].join(' | '));
}

const fa = load('Faction');
const want = ['1', '2', '3', '4', '5', '6', '369'];
console.log('--- Faction for AH FactionIDs');
for (const r of fa.rows) {
  if (want.includes(r[fa.idx.ID])) console.log(r[fa.idx.ID], '|', r[fa.idx.Name_lang], '| parent=' + r[fa.idx.ParentFactionID], '| flags=' + r[fa.idx.Flags]);
}
