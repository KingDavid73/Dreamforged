local core,world,I,types=require('openmw.core'),require('openmw.world'),require('openmw.interfaces'),require('openmw.types')
local storage,util=require('openmw.storage'),require('openmw.util')
local C=require('scripts.ashenloot.config');local json=require('scripts.ashenloot_test.balance_json')
local dropFocus=core.contentFiles.has('balance-drops.omwscripts')
local rows=dropFocus and {{level=1,depth=1,legacy=true},{level=1,depth=1},{level=25,depth=12},{level=100,depth=30}}or{{level=1,depth=1},{level=25,depth=12},{level=100,depth=30}}
local row,mode,rank,stage,t,at=1,1,0,0,0,0
local actors,beforeInventory,beforeLoose={}, {},{};local sample
local groundByActor={};local wrapped=false
local modes={'forced','world-low','world-high','dense-natural'}
local function inventory(actor)
 local result={};for _,item in ipairs(types.Actor.inventory(actor):getAll())do result[item.recordId]=(result[item.recordId]or 0)+item.count end;return result
end
local function remove(actor)if actor:isValid()and actor.count>0 then actor:remove()end end
local function classify(s,item,count,out)
 local m=s.records[item.recordId]
 local kind
 if m then local tier=m.mythic and 7 or m.tier;kind='equipment';out.tiers[tier]=(out.tiers[tier]or 0)+count
 elseif s.spellTomesByRecord and s.spellTomesByRecord[item.recordId]then kind='tomes'
 elseif types.Potion.objectIsInstance(item)then kind='potions'
 elseif types.Book.objectIsInstance(item)then kind='scrolls'
 elseif types.Weapon.objectIsInstance(item)then kind='ammunition'
 else kind='other'end
 out[kind]=(out[kind]or 0)+count;out.stacks[kind]=(out.stacks[kind]or 0)+1
end
local function setup(p,A)
 local r=rows[row];local s=A.getState();local d=A.delve.test.data()
 d.baseline=r.level;d.slots[1]={depth=r.depth,cell='Dreamforged Depth 01',objects={},serial=0,nextWave=core.getSimulationTime()+1000,promotions=0}
 p:sendEvent('Balance_Level',r.level)
 actors={};beforeInventory={};beforeLoose={};groundByActor={};sample={mode=modes[mode],legacy=r.legacy,player=r.level,depth=r.depth,target=math.floor(r.level+(r.depth-1)*1.25),rank=rank,tiers={},stacks={},promotions={},health={},strength={},zeroAnyKills=0,zeroEquipmentKills=0}
 local count=mode==1 and (dropFocus and rank==0 and 60 or 6)or 48
 for i=1,count do
  local actor=world.createObject('df_delve_enemy_rat',1);actors[#actors+1]=actor
  s.elites[actor.id]=false;s.director.spawnLevels[actor.id]=sample.target
  s.director.generated[actor.id]=(mode==2 or mode==3)and'director'or'delve'
  if mode==1 or mode==4 then d.actors[actor.id]={depth=r.depth,index=1,level=sample.target,density=not r.legacy,boss=mode==1 and rank==4}end
  local columns=dropFocus and rank==0 and 10 or 8
  actor:teleport('Dreamforged Depth 01',util.vector3(4376+((i-1)%columns)*240,1504+math.floor((i-1)/columns)*300,8),{onGround=true})
  actor:addScript('scripts/ashenloot_test/enemy_actor.lua')
 end
 sample.n=count
end
local function run(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local A=I.AshenLoot;local s=A.getState();local r=rows[row]
 if not wrapped then
  local original=A.progression.ground
  A.progression.ground=function(item,actor,...)
   local result=original(item,actor,...)
   if result then groundByActor[actor.id]=groundByActor[actor.id]or {};table.insert(groundByActor[actor.id],item)end
   return result
  end
  wrapped=true
 end
 if stage==0 and t>3 then
  storage.globalSection(C.groupKey('extraEncounters')):set('extraEncounters',false)
  storage.globalSection(C.groupKey('directorVoiceFrequency')):set('directorVoiceFrequency',0)
  p:teleport('Dreamforged Depth 01',util.vector3(1792,2304,8),{onGround=true});setup(p,A);stage=1;at=t+3
 elseif stage==1 and t>at then
  for _,actor in ipairs(actors)do A.progression.prepare(actor,true)end
  stage=2;at=t+2
 elseif stage==2 and t>at then
  for i,actor in ipairs(actors)do
   if mode==1 then
    if rank>0 then A.test.encounter{actor=actor,force=true,rank=math.min(3,rank),worldBoss=rank==4}end
   else
    if mode==4 and (i==1 or i==25)then A.delve.test.data().slots[1].promotions=0 end
    s.elites[actor.id]=nil
    s.director.actors[actor.id].directorPressure=mode==3 and 100 or 0
    A.test.encounter{actor=actor,allowWorldBoss=(mode==2 or mode==3)and r.level>=C.worldBossMinLevel,worldBossChance=3}
   end
  end
  stage=3;at=t+2
 elseif stage==3 and t>at then
  for _,actor in ipairs(actors)do
   local elite=s.elites[actor.id];local tier=elite and (elite.worldBoss and 4 or elite.rank)or 0
   sample.promotions[tier]=(sample.promotions[tier]or 0)+1
   local hp=types.Actor.stats.dynamic.health(actor);sample.health[#sample.health+1]=hp.base+hp.modifier
   sample.strength[#sample.strength+1]=types.Actor.stats.attributes.strength(actor).base
   beforeInventory[actor.id]=inventory(actor)
  end
  if mode~=1 then print('[BALANCE LIVE] '..json(sample));stage=5
  else
   for id in pairs(s.director.loose)do beforeLoose[id]=true end
   for _,actor in ipairs(actors)do actor:sendEvent('EnemyTest_Health',0)end
   stage=4;at=t+2
  end
 elseif stage==4 and t>at then
  for _,actor in ipairs(actors)do A.test.death(actor)end
  stage=41;at=t+2
 elseif stage==41 and t>at then
  for _,actor in ipairs(actors)do
   assert(types.Actor.isDead(actor),'scripted kill not applied')
   local old=beforeInventory[actor.id]
   local any,equipment=false,false
   for _,item in ipairs(types.Actor.inventory(actor):getAll())do
    local count=item.count-(old[item.recordId]or 0)
    if count>0 then classify(s,item,count,sample);any=true;if s.records[item.recordId]then equipment=true end end
    old[item.recordId]=0
   end
   for _,item in ipairs(groundByActor[actor.id]or{})do if item:isValid()and item.count>0 then classify(s,item,item.count,sample);any=true;if s.records[item.recordId]then equipment=true end end end
   if not any then sample.zeroAnyKills=sample.zeroAnyKills+1 end
   if not equipment then sample.zeroEquipmentKills=sample.zeroEquipmentKills+1 end
  end
  print('[BALANCE LIVE] '..json(sample));stage=5
 end
 if stage==5 then
  for _,actor in ipairs(actors)do remove(actor)end
  for id,loose in pairs(s.director.loose)do if not beforeLoose[id]and type(loose)=='table'then if loose.item then remove(loose.item)end;if loose.light then remove(loose.light)end;s.director.loose[id]=nil end end
  if mode==1 then rank=rank+1;if rank>4 then rank=0;mode=mode+1 end else mode=mode+1 end
  if dropFocus and mode>1 then mode=#modes+1 end
  if mode>#modes then mode=1;row=row+1 end
  if row>#rows then print('[BALANCE LIVE] ALL PASS actual promotions, scaled actor stats and created reward categories');core.quit();stage=99;return end
  setup(p,A);stage=1;at=t+3
 end
 if t>400 and stage~=99 then error('live baseline timeout')end
end
return{engineHandlers={onUpdate=function(dt)local ok,e=pcall(run,dt);if not ok then print('[BALANCE LIVE] FAIL '..tostring(e));core.quit()end end}}
