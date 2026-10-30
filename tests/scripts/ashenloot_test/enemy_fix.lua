local core,world,types,I=require('openmw.core'),require('openmw.world'),require('openmw.types'),require('openmw.interfaces')
local util=require('openmw.util');local themes=require('scripts.ashenloot.delve_enemies')
local stage,time,nextAt,loaded=0,0,0,false
local probes={};local living,corpse,originalAlive,originalDead
local function check(v,s) assert(v,s);print('[ENEMY FIX] PASS '..s) end
local function run(dt)
 time=time+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local A=I.AshenLoot;local D=A.delve;local d=D.test.data();local s=A.getState()
 if stage==0 and time>3 then
  for theme,pool in ipairs(themes) do
   local seen={};local random=require('scripts.ashenloot.rules').rng('selection:'..theme);for depth=1,80 do for sample=1,32 do seen[D.test.selectEnemy(theme,false,random,depth,false)]=true end end
   local count=0;for id in pairs(seen) do count=count+1;check(not A.progression.test.safeRecord(types.Creature.records[id]),'private archetype excluded from world pool '..id) end
   check(count==#pool.ordinary,'all ordinary archetypes reachable '..pool.name)
   local id=D.test.selectEnemy(theme,true,random,1,false);local curated=false;for _,bossId in ipairs(pool.boss)do if id==bossId then curated=true end end;check(curated,'explicit boss '..pool.name)
   for _,list in ipairs({pool.ordinary,pool.boss}) do for _,id in ipairs(list) do local r=types.Creature.records[id];check(r and not r.mwscript and not r.isEssential and not r.isRespawning and r.canWalk,'safe combat record '..id) end end
  end
  require('scripts.ashenloot_test.enemy_depth_checks')(D,check);D.test.descend(p);stage=1;nextAt=time+4
 elseif stage==1 and time>nextAt then
  local slot=d.slots[1];check(#slot.objects==4,'first floor has four actual creatures')
  -- Simulate an old saved floor: one surviving guar guardian and one dead guar.
  originalAlive=slot.objects[1];originalDead=slot.objects[2]
  local function legacy(old,index,boss)
   local o=world.createObject(types.Creature.records['guar_pack'] and 'guar_pack' or 'rat',1);local id=old.id;local pos=old.position;old:remove()
   d.actors[id]=nil;s.director.actors[id]=nil;s.director.generated[id]=nil;s.director.spawnLevels[id]=nil;s.elites[id]=nil
   slot.objects[index]=o;slot.ids[index]=o.id;d.actors[o.id]={depth=1,index=1,level=1,boss=boss}
   s.director.generated[o.id]='delve';s.director.spawnLevels[o.id]=1;s.director.actors[o.id]={level=1,cell=slot.cell}
   o:addScript('scripts/ashenloot_test/enemy_actor.lua');o:teleport(slot.cell,pos,{onGround=true});return o
  end
  living=legacy(originalAlive,1,true);corpse=legacy(originalDead,2,false)
  slot.boss=living;slot.selectionVersion=2
  living:sendEvent('EnemyTest_Health',0.5);corpse:sendEvent('EnemyTest_Health',0)
  stage=2;nextAt=time+3
 elseif stage==2 and time>nextAt then
  check(types.Actor.isDead(corpse),'legacy corpse fixture is dead')
  -- Persist the legacy state before repair, proving migration works after load.
  d.slots[1].selectionVersion=1
  types.Player.sendMenuEvent(p,'AshenLoot_TestSave');stage=3
 elseif stage==3 and loaded then
  local slot=d.slots[1]
  if slot.selectionVersion~=2 or time<nextAt then return end
  check(#slot.objects==4,'migration preserves population')
  check(not living:isValid() or not living.enabled,'replaced guar removed from active world');check(slot.objects[1]~=living and slot.objects[1].recordId==themes[1].boss[1],'saved live guar guardian replaced with cave boss')
  check(slot.boss==slot.objects[1] and d.actors[slot.boss.id].boss,'guardian identity preserved')
  check(corpse:isValid() and slot.objects[2]==corpse and types.Actor.isDead(corpse),'dead guar corpse preserved')
  check(not d.actors[living.id] and not s.director.generated[living.id] and not s.elites[living.id],'old guardian bookkeeping removed')
  check(s.elites[slot.boss.id] and s.elites[slot.boss.id].worldBoss,'replacement receives world boss promotion')
  local hp=types.Actor.stats.dynamic.health(slot.boss);print('[ENEMY FIX] migrated health current='..hp.current..' base='..hp.base..' modifier='..hp.modifier);check(hp.current<(hp.base+hp.modifier)*0.75,'migration does not heal surviving enemy to full')
  local id=slot.boss.id;D.test.migrateSelection(slot,1);check(slot.boss.id==id,'migration is idempotent')
  stage=4;nextAt=time+3
 elseif stage==4 and time>nextAt then
  local slot=d.slots[1];local actor=slot.objects[3]
  p:teleport(slot.cell,actor.position+util.vector3(150,0,0),{onGround=true})
  actor:addScript('scripts/ashenloot_test/enemy_actor.lua');stage=5;nextAt=time+5
 elseif stage==5 and time>nextAt then
  d.slots[1].objects[3]:sendEvent('EnemyTest_Inspect');stage=6;nextAt=time+4
 elseif stage==6 then
  local actor=d.slots[1].objects[3];local report=probes[actor.id]
  if not report then if time>nextAt then error('missing combat report') end;return end
  check(report.fight==100 and report.flee==0,'dungeon actor remains hostile and does not flee')
  check(report.combat,'dungeon creature actually enters combat near player')
  D.test.descend(p);stage=7;nextAt=time+3
 elseif stage==7 and time>nextAt then
  local index=require('scripts.ashenloot.delve_rules').layout(d.depth);local slot=d.slots[index]
  check(#slot.objects>=4,'floor populated at depth '..d.depth)
  local allowed={};local theme=require('scripts.ashenloot.delve_layouts')[index].theme;for _,actor in ipairs(slot.objects)do local e=D.test.selection.describe(actor.recordId);allowed[actor.recordId]=e and e.theme==theme;local info=d.actors[actor.id];check(info and info.level==math.max(1,math.floor(d.baseline+(slot.depth-1)*1.25)),'single existing scaling target at depth '..d.depth)end
  for _,actor in ipairs(slot.objects) do if actor~=slot.boss then check(allowed[actor.recordId],'themed ordinary at depth '..d.depth..' '..actor.recordId) end end
  if d.depth%3==0 then check(slot.boss and s.elites[slot.boss.id] and s.elites[slot.boss.id].worldBoss,'real guardian at depth '..d.depth) end
  if d.depth==12 then print('[ENEMY FIX] ALL PASS');core.quit();stage=99
  else D.test.descend(p);nextAt=time+3 end
 end
 if time>110 and stage~=99 then error('timeout stage '..stage) end
end
return {engineHandlers={onUpdate=function(dt)local ok,e=pcall(run,dt);if not ok then print('[ENEMY FIX] FAIL '..tostring(e));core.quit() end end,
 onSave=function()return {stage=stage,time=time,nextAt=nextAt,living=living,corpse=corpse}end,
 onLoad=function(v)stage,time,nextAt,living,corpse=v.stage,v.time,v.nextAt,v.living,v.corpse;loaded=true;nextAt=time+5 end},
 eventHandlers={EnemyTest_Report=function(e)probes[e.id]=e end}}
