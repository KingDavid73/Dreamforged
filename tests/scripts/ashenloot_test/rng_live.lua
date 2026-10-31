local core,world,I,types=require('openmw.core'),require('openmw.world'),require('openmw.interfaces'),require('openmw.types')
local storage,util=require('openmw.storage'),require('openmw.util');local C,R=require('scripts.ashenloot.config'),require('scripts.ashenloot.rules')
local json=require('scripts.ashenloot_test.balance_json')
local t,stage,at,mode,batch=0,0,0,1,0;local actors={};local ground={};local wrapped=false
local stats={};local groupPromotions=0
local function remove(a)if a and a:isValid()and a.count>0 then a:remove()end end
local function create(p,A)
 local s=A.getState();local d=A.delve.test.data();actors={};ground={};batch=batch+1
 for i=1,50 do
  local a=world.createObject('df_delve_enemy_rat',1);actors[#actors+1]=a
  s.elites[a.id]=false;s.director.actors[a.id]={level=1,cell='dreamforged depth 01',directorPressure=mode==3 and 100 or 0}
  s.director.generated[a.id]=(mode==2 or mode==3)and'director'or'delve'
  if mode==1 or mode==4 then d.actors[a.id]={depth=1,index=1,level=1,density=true,boss=false}end
  a:teleport('Dreamforged Depth 01',util.vector3(4376+((i-1)%10)*240,1504+math.floor((i-1)/10)*300,8),{onGround=true})
  a:addScript('scripts/ashenloot_test/enemy_actor.lua')
 end
end
local function check(v,s)assert(v,s);print('[RNG LIVE] PASS '..s)end
return{engineHandlers={onUpdate=function(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local ok,e=pcall(function()
  local A=I.AshenLoot;local s=A.getState();local d=A.delve.test.data()
  if not wrapped then
   local original=A.progression.ground
   A.progression.ground=function(item,actor,...)
    local result=original(item,actor,...);if result then ground[actor.id]=ground[actor.id]or{};table.insert(ground[actor.id],item)end;return result
   end;wrapped=true
  end
  if stage==0 and t>3 then
   storage.globalSection(C.groupKey('extraEncounters')):set('extraEncounters',false)
   storage.globalSection(C.groupKey('directorVoiceFrequency')):set('directorVoiceFrequency',0)
   p:teleport('Dreamforged Depth 01',util.vector3(1792,2304,8),{onGround=true})
   d.baseline=1;d.slots[1]={depth=1,cell='Dreamforged Depth 01',objects={},serial=0,nextWave=10000,promotions=0}
   stats={mode=mode,n=0,eligible=0,equipment=0,tomes=0,potions=0,ranks={}}
   create(p,A);stage=1;at=t+1
  elseif stage==1 and t>at then
   for i,a in ipairs(actors)do
    stats.n=stats.n+1
    if mode==1 then
     if A.delve.rewardEligible(a)then stats.eligible=stats.eligible+1 end
     a:sendEvent('EnemyTest_Health',0)
    else
     if mode==4 and (stats.n-1)%24==0 then d.slots[1].promotions=0;groupPromotions=0 end
     local pressure=mode==3 and 100 or 0
     local chance=mode==4 and (groupPromotions<2 and math.min(.08,C.eliteChance)or 0)
        or math.max(.05,math.min(.85,C.eliteChance*(.65+pressure/100*1.35)))
     local expected=0
     if R.stream(a.id,'promotion-gate-v1')()<chance then
      local unique=mode==4 and C.uniquePercent or math.min(80,C.uniquePercent+pressure*.22)
      local elite=mode==4 and C.eliteTierPercent or math.min(95,C.eliteTierPercent+pressure*.38)
      expected=R.stream(a.id,'promotion-unique-v1')(100)<=unique and 3
         or R.stream(a.id,'promotion-elite-v1')(100)<=elite and 2 or 1
      if mode==4 then groupPromotions=groupPromotions+1 end
     end
     s.elites[a.id]=nil
     A.test.encounter{actor=a,allowWorldBoss=false}
     local got=s.elites[a.id];local rank=got and got.rank or 0
     assert(rank==expected,'live promotion stream/cap wiring mismatch '..mode..' '..a.id)
     stats.ranks[rank]=(stats.ranks[rank]or 0)+1
    end
   end
   stage=2;at=t+(mode==1 and 2 or .1)
  elseif stage==2 and t>at then
   if mode==1 then
    for _,a in ipairs(actors)do
     assert(types.Actor.isDead(a),'scripted ordinary kill not committed');A.test.death(a)
    end
    stage=3;at=t+1
   else stage=4 end
  elseif stage==3 and t>at then
   local function item(a)
    if s.records[a.recordId]then stats.equipment=stats.equipment+a.count
    elseif s.spellTomesByRecord and s.spellTomesByRecord[a.recordId]then stats.tomes=stats.tomes+a.count
    elseif types.Potion.objectIsInstance(a)then stats.potions=stats.potions+a.count end
   end
   for _,a in ipairs(actors)do
    assert(s.rewards[a.id],'ordinary death outcome not committed')
    for _,v in ipairs(ground[a.id]or{})do if v:isValid()and v.count>0 then item(v)end end
    for _,v in ipairs(types.Actor.inventory(a):getAll())do item(v)end
   end
   stage=4
  end
  if stage==4 then
   for _,a in ipairs(actors)do
    for _,v in ipairs(ground[a.id]or{})do remove(v)end
    remove(a);s.director.actors[a.id]=nil;d.actors[a.id]=nil;s.elites[a.id]=nil
   end
   for id,loose in pairs(s.director.loose)do if type(loose)=='table'and loose.item and loose.item.count==0 then remove(loose.light);s.director.loose[id]=nil end end
   if batch>=10 then
    if mode==1 then
     check(stats.eligible>=55 and stats.eligible<=115,'actual density eligibility near one sixth')
     check(stats.equipment+stats.tomes<=30,'actual ordinary equipment no longer follows old coupled ~10% rate')
    else check(stats.n==500,'500 actual promotion outcomes checked against independent streams and caps')end
    print('[RNG LIVE RESULTS] '..json(stats));mode=mode+1;batch=0
    if mode>4 then print('[RNG LIVE] ALL PASS 500 actual ordinary deaths and 1500 live promotion outcomes');core.quit();stage=99;return end
    stats={mode=mode,n=0,eligible=0,equipment=0,tomes=0,potions=0,ranks={}}
   end
   create(p,A);stage=1;at=t+1
  end
  if t>240 and stage~=99 then error('live RNG regression timed out')end
 end)
 if not ok then print('[RNG LIVE] FAIL '..tostring(e));core.quit()end
end}}
