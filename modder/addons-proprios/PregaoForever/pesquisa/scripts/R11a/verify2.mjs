import { load } from './csv.mjs';
import { readFileSync } from 'node:fs';
const PROF={164:1,165:1,171:1,182:1,186:1,197:1,202:1,333:1,393:1,129:1,185:1,356:1};
const sla=load('SkillLineAbility'),sr=load('SpellReagents'),se=load('SpellEffect');
const reag=new Set();for(const r of sr.rows){for(let i=0;i<8;i++)if(Number(r[sr.idx['Reagent_'+i]])>0){reag.add(r[sr.idx.SpellID]);break;}}
const cr=new Set();for(const r of se.rows)if(r[se.idx.Effect]==='24')cr.add(r[se.idx.SpellID]);
let raw=0,rc=0;const seen=new Map();
for(const r of sla.rows){if(!PROF[r[sla.idx.SkillLine]]||!reag.has(r[sla.idx.Spell]))continue;raw++;if(cr.has(r[sla.idx.Spell]))rc++;const k=r[sla.idx.SkillLine]+'_'+r[sla.idx.Spell];seen.set(k,(seen.get(k)||0)+1);}
console.log('raw',raw,'rawcreate',rc,'dups',[...seen].filter(x=>x[1]>1));
const us=new Set([...seen.keys()].map(k=>k.split('_')[1]));console.log('uniqspells',us.size);
const t=readFileSync('recipes_estimate.lua','utf8');console.log('lua spell entries',(t.match(/\n?\[\d+\]=\{\d+,\d+,\{/g)||[]).length, t.length);
const h=sla.header;console.log(h.slice(0,16).join(','));
