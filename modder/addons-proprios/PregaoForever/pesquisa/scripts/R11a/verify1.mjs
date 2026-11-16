import { load } from './csv.mjs';
const PROF={164:'BS',165:'LW',171:'Alch',182:'Herb',186:'Min',197:'Tail',202:'Eng',333:'Ench',393:'Skin',129:'FA',185:'Cook',356:'Fish'};
const sla=load('SkillLineAbility'),sr=load('SpellReagents'),se=load('SpellEffect'),sp=load('ItemSparse'),it=load('Item'),sl=load('SkillLine');
console.log('rows',sla.rows.length,sr.rows.length,se.rows.length,sp.rows.length,it.rows.length);
const reag=new Map();
for(const r of sr.rows){let n=0;for(let i=0;i<8;i++)if(Number(r[sr.idx['Reagent_'+i]])>0)n++;if(n)reag.set(r[sr.idx.SpellID],1);}
console.log('spells w reagents',reag.size, 'distinct spellIDs',new Set(sr.rows.map(r=>r[sr.idx.SpellID])).size);
const cr=new Map();let c24=0;
for(const r of se.rows){if(r[se.idx.Effect]==='24'){c24++;cr.set(r[se.idx.SpellID],(cr.get(r[se.idx.SpellID])||[]).concat([[r[se.idx.EffectItemType],r[se.idx.EffectBasePointsF],r[se.idx.EffectMiscValue_0]]]));}}
console.log('eff24 rows',c24,'spells',cr.size);
const pairs=new Set(),cnt={},cc={};let raw=0,created=0;
for(const r of sla.rows){const s=r[sla.idx.SkillLine];if(!PROF[s])continue;const spell=r[sla.idx.Spell];if(!reag.has(spell))continue;raw++;const k=s+'_'+spell;if(pairs.has(k))continue;pairs.add(k);cnt[PROF[s]]=(cnt[PROF[s]]||0)+1;if(cr.has(spell)){created++;cc[PROF[s]]=(cc[PROF[s]]||0)+1;}}
console.log('raw',raw,'pairs',pairs.size,'created',created,JSON.stringify(cnt),JSON.stringify(cc));
for(const s of [2659,2660,2329,3275]){console.log(s,JSON.stringify(cr.get(String(s))));}
const nm=new Map(sp.rows.map(r=>[r[sp.idx.ID],r[sp.idx.Display_lang]]));
console.log(nm.get('2841'),nm.get('2862'),nm.get('2454'));
const x=sp.rows.find(r=>r[sp.idx.ID]==='2842');console.log(['SellPrice','BuyPrice','Stackable','OverallQualityID','ItemLevel','RequiredLevel','Bonding'].map(k=>k+'='+x[sp.idx[k]]).join(' '));
const bond={},q={};for(const r of sp.rows){bond[r[sp.idx.Bonding]]=(bond[r[sp.idx.Bonding]]||0)+1;q[r[sp.idx.OverallQualityID]]=(q[r[sp.idx.OverallQualityID]]||0)+1;}
console.log('bonding',JSON.stringify(bond),'quality',JSON.stringify(q));
for(const r of sl.rows)if(r[sl.idx.ID]>=2937&&r[sl.idx.ID]<=2948)console.log(r[sl.idx.ID],r[sl.idx.DisplayName_lang],r[sl.idx.ParentSkillLineID]);
// misc0==item?
let eq=0,tot=0;for(const [s,a] of cr){for(const e of a){tot++;if(e[0]===e[2])eq++;}}console.log('misc0==itemtype',eq,'of',tot);
const vals={};for(const [s,a] of cr)for(const e of a)vals[e[1]]=(vals[e[1]]||0)+1;console.log(JSON.stringify(vals));
