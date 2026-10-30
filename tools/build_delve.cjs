// Deterministic, connected open-plan dungeon cells. Requires only Node and Morrowind.esm.
const fs = require('fs'), path = require('path'), assert = require('assert');
const root = path.resolve(__dirname, '..');
const master = process.env.MORROWIND_ESM || 'F:/Morrowind Data Files/Data Files/Morrowind.esm';
const esm = fs.readFileSync(master);
function sub(t,b) { if(typeof b==='string')b=Buffer.from(b+'\0','latin1'); const h=Buffer.alloc(8);h.write(t);h.writeUInt32LE(b.length,4);return Buffer.concat([h,b]); }
function rec(t,...parts) { const b=Buffer.concat(parts),h=Buffer.alloc(16);h.write(t);h.writeUInt32LE(b.length,4);return Buffer.concat([h,b]); }
function nums(vals,float=false) { const b=Buffer.alloc(vals.length*4);vals.forEach((v,i)=>float?b.writeFloatLE(v,i*4):b.writeInt32LE(v,i*4));return b; }
function parse(b) { let r=[];for(let p=0;p<b.length;){const n=b.readUInt32LE(p+4),e=p+16+n;assert(e<=b.length);let s=[];for(let o=p+16;o<e;){let z=b.readUInt32LE(o+4);s.push([b.toString('ascii',o,o+4),b.subarray(o+8,o+8+z)]);o+=8+z;}r.push({tag:b.toString('ascii',p,p+4),s});p=e;}return r; }
const records=parse(esm), str=b=>b.toString('latin1').replace(/\0.*$/s,''), get=(r,t)=>r.s.find(s=>s[0]===t)?.[1];
const byId=new Map(records.filter(r=>get(r,'NAME')).map(r=>[str(get(r,'NAME')).toLowerCase(),r]));
let result=[], ref=1;
function clone(tag,id,base,name,omit=[]) {const r=records.find(r=>r.tag===tag&&get(r,'NAME')&&str(get(r,'NAME')).toLowerCase()===base.toLowerCase());assert(r,base);result.push(rec(tag,...r.s.filter(([t])=>!['NAME','FNAM','SCRI',...omit].includes(t)).map(([t,b])=>sub(t,b)),sub('NAME',id),sub('FNAM',name)));}
function object(tag,id,name,model) {result.push(rec(tag,sub('NAME',id),sub('MODL',model),...(name?[sub('FNAM',name)]:[])));}
function placed(id,x,y,z=0,scale=1,angle=0) {return Buffer.concat([sub('FRMR',nums([ref++])),sub('NAME',id),...(scale!==1?[sub('XSCL',nums([scale],true))]:[]),sub('DATA',nums([x,y,z,0,0,angle],true))]);}
const meshDir=path.join(root,'meshes','dreamforged');fs.mkdirSync(meshDir,{recursive:true});
// Each mesh has ordinary solid collision geometry, no ceiling, and low boundaries.
function mesh(name,boxes,texture) {
 let v=[],normal=[],uv=[];const faces=[[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]],ns=[[0,0,-1],[0,0,1],[0,-1,0],[1,0,0],[0,1,0],[-1,0,0]];
 for(const [x,y,z,w,d,h] of boxes){const p=[[x,y,z],[x+w,y,z],[x+w,y+d,z],[x,y+d,z],[x,y,z+h],[x+w,y,z+h],[x+w,y+d,z+h],[x,y+d,z+h]];faces.forEach((f,i)=>{for(const j of [0,1,2,0,2,3]){let a=p[f[j]];v.push(...a);normal.push(...ns[i]);uv.push((i<2?a[0]:i%2?a[1]:a[0])/512,(i<2?a[1]:a[2])/512);}});}
 const n=v.length/3;
 const source=(id,a,stride,params)=>`<source id="${id}"><float_array id="${id}-a" count="${a.length}">${a.join(' ')}</float_array><technique_common><accessor source="#${id}-a" count="${a.length/stride}" stride="${stride}">${params.map(p=>`<param name="${p}" type="float"/>`).join('')}</accessor></technique_common></source>`;
 const xml=`<?xml version="1.0"?><COLLADA xmlns="http://www.collada.org/2005/11/COLLADASchema" version="1.4.1"><asset><created>2026-10-29T00:00:00Z</created><modified>2026-10-29T00:00:00Z</modified><unit name="unit" meter="1"/><up_axis>Z_UP</up_axis></asset><library_images><image id="tex"><init_from>textures/${texture}</init_from></image></library_images><library_effects><effect id="fx"><profile_COMMON><newparam sid="surface"><surface type="2D"><init_from>tex</init_from></surface></newparam><newparam sid="sampler"><sampler2D><source>surface</source><wrap_s>WRAP</wrap_s><wrap_t>WRAP</wrap_t></sampler2D></newparam><technique sid="common"><lambert><emission><color>0 0 0 1</color></emission><ambient><color>1 1 1 1</color></ambient><diffuse><texture texture="sampler" texcoord="UVMap"/></diffuse></lambert></technique></profile_COMMON></effect></library_effects><library_materials><material id="mat"><instance_effect url="#fx"/></material></library_materials><library_geometries><geometry id="geo"><mesh>${source('pos',v,3,['X','Y','Z'])}${source('norm',normal,3,['X','Y','Z'])}${source('uv',uv,2,['S','T'])}<vertices id="verts"><input semantic="POSITION" source="#pos"/></vertices><triangles material="stone" count="${n/3}"><input semantic="VERTEX" source="#verts" offset="0"/><input semantic="NORMAL" source="#norm" offset="1"/><input semantic="TEXCOORD" source="#uv" offset="2" set="0"/><p>${Array.from({length:n},(_,i)=>`${i} ${i} ${i}`).join(' ')}</p></triangles></mesh></geometry></library_geometries><library_visual_scenes><visual_scene id="scene"><node id="solid"><instance_geometry url="#geo"><bind_material><technique_common><instance_material symbol="stone" target="#mat"><bind_vertex_input semantic="UVMap" input_semantic="TEXCOORD" input_set="0"/></instance_material></technique_common></bind_material></instance_geometry></node></visual_scene></library_visual_scenes><scene><instance_visual_scene url="#scene"/></scene></COLLADA>`;
 fs.writeFileSync(path.join(meshDir,name+'.dae'),xml);
 object('STAT','df_mesh_'+name,'','dreamforged/'+name+'.dae');
}
const themes=[['Cave','tx_natural_cavern_wall00.dds','ex_nord_rock_01'],['Ancestral Tomb','tx_daed_stone_02.dds','in_dae_pillar_tall.max'],['Dwemer','tx_dwrv_floor00.dds','in_dwrv_gear00'],['Daedric','tx_dae_floor_01.dds','ex_dae_pillar_02']];
function cell(name,refs) {result.push(rec('CELL',sub('NAME',name),sub('DATA',nums([1,0,0])),sub('AMBI',Buffer.concat([Buffer.from([85,85,90,0,155,145,130,0,25,25,30,0]),nums([0.6],true)])),...refs));}
mesh('hub',[[-1536,-1024,-80,3072,3072,80],[-1600,-1088,0,3200,64,240],[-1600,2048,0,3200,64,240],[-1600,-1024,0,64,3072,240],[1536,-1024,0,64,3072,240]],'tx_dwrv_floor00.dds');
mesh('gateway',[[-420,-130,0,170,260,800],[250,-130,0,170,260,800],[-420,-130,800,840,260,160]],'tx_daed_stone_02.dds');
object('ACTI','df_delve_enter','Shrine of the Unending Dream','d/Ex_DAE_door_load_oval.NIF');
object('ACTI','df_delve_descend','Descend into the Unending Dream','f/Furn_shrine_vivec_01.NIF');
object('ACTI','df_delve_retreat','Return to the Shrine','f/Furn_shrine_tribunal_01.NIF');
object('ACTI','df_delve_resume','Return through your Portal','f/Furn_shrine_vivec_01.NIF');
object('ACTI','df_delve_exit','Seyda Neen','d/Ex_DAE_door_load_oval.NIF');
clone('NPC_','df_delve_attendant','eldafire','Nerethi, Maelstrom Herald',['NPCS','AIDT','AI_W']);
clone('NPC_','df_delve_broker','elone','Velyna, Broker of Dreams',['NPCS','AIDT','AI_W']);
// Private combat archetypes avoid suite-added population/AI/stat scripts without
// changing the original records. IDs remain stable across plugin rebuilds.
const enemyThemes=require('./delve-enemies.json');
const enemyId=id=>'df_delve_enemy_'+id.replace(/[^a-z0-9]/g,'_');
for(const id of new Set(enemyThemes.flatMap(t=>[...t.ordinary,...t.boss]))){
 const base=records.find(r=>r.tag==='CREA'&&get(r,'NAME')&&str(get(r,'NAME')).toLowerCase()===id);assert(base,'Missing dungeon creature '+id);
 clone('CREA',enemyId(id),id,str(get(base,'FNAM')),['AIDT','AI_W','AI_T','AI_F','AI_E','AI_A','DODT','DNAM','FLAG']);
 const ai=Buffer.alloc(12);ai[2]=100; // fight 100, flee 0, no services
 // Explicit terrestrial movement: some original skeleton records omit Walks.
 // Flag definitions: OpenMW components/esm3/loadcrea.hpp.
 const flags=Buffer.from(get(base,'FLAG'));flags.writeUInt32LE((flags.readUInt32LE()&~0x82)|0x40); // walking, nonessential, no respawn
 const original=result.pop();const body=original.subarray(16);
 result.push(rec('CREA',body,sub('AIDT',ai),sub('FLAG',flags)));
}
fs.writeFileSync(path.join(root,'scripts/ashenloot/delve_enemies.lua'),
 '-- Generated by tools/build_delve.cjs from tools/delve-enemies.json.\nreturn {\n'+enemyThemes.map(t=>
 ` {name='${t.name}',ordinary={${t.ordinary.map(id=>`'${enemyId(id)}'`).join(',')}},boss={${t.boss.map(id=>`'${enemyId(id)}'`).join(',')}}},`).join('\n')+'\n}\n');
const light=Buffer.alloc(24);light.writeFloatLE(0,0);light.writeInt32LE(0,4);light.writeInt32LE(-1,8);light.writeInt32LE(850,12);light.writeUInt32LE(0x00ffb080,16);light.writeInt32LE(0,20);
result.push(rec('LIGH',sub('NAME','df_delve_glow'),sub('MODL','l/Light_Com_Candle_01.NIF'),sub('FNAM','Dreamlight'),sub('LHDT',light)));
// Clone a valid empty container for broker escrow; never placed in an accessible cell.
const cont=records.find(r=>r.tag==='CONT'&&!get(r,'SCRI'));
result.push(rec('CONT',...cont.s.filter(([t])=>!['NAME','FNAM','NPCO','SCRI'].includes(t)).map(([t,b])=>sub(t,b)),sub('NAME','df_delve_escrow'),sub('FNAM','Broker Escrow')));
const journal=[['The Unending Dream',0],['Near Seyda Neen I met Nerethi, a stranger claiming to serve the Demiprince Fa-Nuit-Hen. She offers passage to the Unending Dream, a shifting proving ground beyond Mundus. Its rewards must be earned in combat.',10],['Nerethi transported me to a refuge beyond Mundus and taught me Dream Portal, a spell that returns here without disturbing my Mark. A broker trades generated equipment for forging coins. Every third depth holds a World Boss.',20],['I defeated the guardian of the third depth. The passage continues. Velyna can now offer a new selection of gear; every further guardian victory refreshes her stock.',100]];
result.push(rec('DIAL',sub('NAME','df_unending_dream'),sub('DATA',Buffer.from([4]))));
journal.forEach(([text,index],i)=>{const data=Buffer.alloc(12);data.writeInt32LE(4,0);data.writeInt32LE(index,4);result.push(rec('INFO',sub('INAM','df_delve_j'+i),sub('PNAM',i?'df_delve_j'+(i-1):''),sub('NNAM',i<journal.length-1?'df_delve_j'+(i+1):''),sub('DATA',data),sub('NAME',text),...(i===0?[sub('QSTN',Buffer.from([1]))]:[])));});
let layouts=[];
for(let theme=0;theme<4;theme++)for(let variant=0;variant<3;variant++){
 const index=theme*3+variant+1,seed=7907+index*31;let rngState=seed;const rand=n=>{rngState=(Math.imul(rngState,1664525)+1013904223)>>>0;return rngState%n;};
 const grid=new Set(),key=(x,y)=>`${x},${y}`;const rect=(x,y,w,h)=>{for(let a=x;a<x+w;a++)for(let b=y;b<y+h;b++)grid.add(key(a,b));};
 const centers=[[3,3],[10,3],[17,5],[4,12],[11,12],[17,17],[7,19]].map(([x,y],i)=>[x+rand(3)-1,y+rand(3)-1]);
 centers.forEach(([x,y])=>rect(x-2,y-2,5+rand(2),5+rand(2)));
 const edges=[[0,1],[1,2],[0,3],[3,4],[4,5],[4,6],[1,4],[2,5]];
 edges.forEach(([a,b])=>{let [x,y]=centers[a],[tx,ty]=centers[b];while(x!==tx){rect(x-1,y-1,3,3);x+=Math.sign(tx-x);}while(y!==ty){rect(x-1,y-1,3,3);y+=Math.sign(ty-y);}rect(x-1,y-1,3,3);});
 const start=centers[0],queue=[start],dist=new Map([[key(...start),0]]);
 for(let i=0;i<queue.length;i++){const [x,y]=queue[i];for(let [dx,dy]of [[1,0],[-1,0],[0,1],[0,-1]]){let k=key(x+dx,y+dy);if(grid.has(k)&&!dist.has(k)){dist.set(k,dist.get(key(x,y))+1);queue.push([x+dx,y+dy]);}}}
 assert.equal(dist.size,grid.size,'Disconnected floor');const end=centers.reduce((best,c)=>dist.get(key(...c))>dist.get(key(...best))?c:best,start);assert(dist.get(key(...end))>=15);
 const boxes=[];for(const k of grid){let [x,y]=k.split(',').map(Number);boxes.push([x*512,y*512,-80,512,512,80]);for(let [dx,dy]of [[1,0],[-1,0],[0,1],[0,-1]])if(!grid.has(key(x+dx,y+dy))){if(dx)boxes.push([(x+(dx>0?1:0))*512-32,y*512,0,64,512,220]);else boxes.push([x*512,(y+(dy>0?1:0))*512-32,0,512,64,220]);}}
 const meshName='floor_'+index;mesh(meshName,boxes,themes[theme][1]);
 const name='Dreamforged Depth '+String(index).padStart(2,'0'),pos=c=>[c[0]*512+256,c[1]*512+256,8];const entry=pos(start),exit=pos(end);
 const anchors=centers.slice(1).map(pos);const refs=[placed('df_mesh_'+meshName,0,0),placed('df_delve_retreat',entry[0]-650,entry[1],0,0.5),placed('df_delve_descend',exit[0]+650,exit[1],0,0.5)];
 // Dressing stays off the centre walk lanes. No randomly blocking obstacles.
 centers.forEach((c,i)=>{refs.push(placed(themes[theme][2],c[0]*512-350,c[1]*512-350,0,0.35));refs.push(placed('df_delve_glow',c[0]*512-250,c[1]*512-250,150));});
 cell(name,refs);layouts.push({index,theme:theme+1,name,entry,exit,anchors,walkable:grid.size,distance:dist.get(key(...end))});
}
cell('Seyda Neen, Shrine of the Unending Dream',[placed('df_mesh_hub',0,0),placed('df_delve_exit',0,-850,0),placed('df_delve_descend',-700,1200,0),placed('df_delve_resume',700,1200,0),placed('df_delve_broker',850,200,4),placed('furn_de_p_table_01',850,650,0),placed('df_delve_glow',-800,800,120),placed('df_delve_glow',800,800,120)]);
const hedr=Buffer.alloc(300);hedr.writeFloatLE(1.3);hedr.write('Dreamforged',8);hedr.write('The Unending Dream: generated open-plan depths, shrine and quest.',40);hedr.writeUInt32LE(result.length,296);const size=Buffer.alloc(8);size.writeBigUInt64LE(BigInt(esm.length));
fs.writeFileSync(path.join(root,'Dreamforged-Delve.esp'),Buffer.concat([rec('TES3',sub('HEDR',hedr),sub('MAST','Morrowind.esm'),sub('DATA',size)),...result]));
const lua='-- Generated by tools/build_delve.cjs. Positions are validated walkable centres.\nreturn {\n'+layouts.map(l=>` {name='${l.name}',theme=${l.theme},entry={${l.entry}},exit={${l.exit}},anchors={${l.anchors.map(a=>'{'+a+'}').join(',')}}},`).join('\n')+'\n}\n';
fs.writeFileSync(path.join(root,'scripts/ashenloot/delve_layouts.lua'),lua);
fs.writeFileSync(path.join(root,'tests/delve-layouts.json'),JSON.stringify(layouts,null,2));
console.log(`Built ${layouts.length} connected floors, ${result.length} records, ${ref-1} placed references.`);
