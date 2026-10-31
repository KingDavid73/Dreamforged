local core,world,I,types=require('openmw.core'),require('openmw.world'),require('openmw.interfaces'),require('openmw.types')
local util=require('openmw.util');local P=require('scripts.ashenloot.delve_pacing');local Population=require('scripts.ashenloot.delve_population')
local layouts=require('scripts.ashenloot.delve_layouts')
local stage,t,at,limit,checked=0,0,0,0,0
local waveBase,arrivals,seen=0,0,{};local maxNear,maxAlive=0,0
local walked,loaded=false,false;local matrix={3,4,7,10,25,30};local matrixIndex=0;local deadline,nextKill=0,0
local function path(layout,from,to)
 local tiles={};for _,a in ipairs(layout.tiles)do tiles[a[1]..','..a[2]]=a end
 local start=math.floor(from.x/512)..','..math.floor(from.y/512);local goal=math.floor(to[1]/512)..','..math.floor(to[2]/512)
 local queue,parents={start},{[start]=false}
 for _,key in ipairs(queue)do
  if parents[goal]~=nil then break end
  local a=tiles[key]
  for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}})do local k=(a[1]+d[1])..','..(a[2]+d[2]);if tiles[k]and parents[k]==nil then parents[k]=key;queue[#queue+1]=k end end
 end
 local result={};local key=goal
 while key do local a=tiles[key];table.insert(result,1,{a[1]*512+256,a[2]*512+256,8});key=parents[key]end
 return result
end
local function kill(actor)
 if actor:isValid()and actor.count>0 and not types.Actor.isDead(actor)then
  if not actor:hasScript('scripts/ashenloot_test/enemy_actor.lua')then actor:addScript('scripts/ashenloot_test/enemy_actor.lua')end
  actor:sendEvent('EnemyTest_Health',0)
 end
end
local function check(v,s)assert(v,s);print('[DENSITY] PASS '..s)end
local function pure()
 for _,l in ipairs(layouts)do check(#Population.points(l)>=32,'authored broad-pocket candidates '..l.name)end
 local s=P.new(0);local phases={}
 for n=1,240 do
  local busy=n%80<45;P.step(s,n,{nearby=busy and 4 or 0,incoming=0,health=1,kills=busy and 1 or 0})
  phases[s.phase]=true
 end
 check(phases.build and phases.peak and phases.fade and phases.relax,'strong-player simulation cycles all pacing states')
 s=P.new(0);P.step(s,1,{nearby=4,incoming=2,health=.2,loss=.25})
 check(s.blocked and s.phase=='fade','struggling-player simulation stops admission before recovery clock')
 P.step(s,2,{nearby=0,incoming=0,health=.2});check(s.phase=='relax','recovery clock starts after threats resolve')
 P.step(s,40,{nearby=0,incoming=0,health=.2});check(s.blocked,'depleted player keeps recovery after timer')
 P.step(s,100,{nearby=0,incoming=0,health=1});P.step(s,106,{nearby=0,incoming=0,health=1});check(s.phase=='build','healed player resumes building')
 check(P.capacity({nearbyCap=8},32,0,0,0)==2,'distant ambient population reserves reinforcement capacity')
 check(P.capacity({nearbyCap=8},32,6,2,2)==0 and P.capacity({},48,0,0,0)==0 and P.capacity({},32,0,6,6)==0,'nearby, incoming and floor caps each stop admission')
end
local function run(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local A=I.AshenLoot;local D=A.delve;local d=D.test.data();local slot=d.slots[1];local now=core.getSimulationTime()
 for _,s in pairs(d.slots)do assert(D.test.aliveCount(s)<=48,'floor live cap exceeded')end
 if slot and p.cell.name==slot.cell then
  local o=D.test.observation(slot,p);maxNear=math.max(maxNear,o.nearby);maxAlive=math.max(maxAlive,D.test.aliveCount(slot))
  for _,a in ipairs(slot.objects)do local info=D.context(a);if info and info.reinforcement and a:isValid()and a.count>0 and not types.Actor.isDead(a)and(a.position-p.position):length()<1800 and not seen[a.id]then seen[a.id]=true;arrivals=arrivals+1 end end
 end
 if stage==0 and t>3 then pure();D.test.descend(p);stage=1;limit=t+60
 elseif stage==1 then
  if slot.population and slot.population.done then
   check(slot.population.made==24,'new floor has 24 validated ambient enemies')
   check(D.test.aliveCount(slot)>=24,'ambient actors actually present')
   print('[DENSITY] population validations='..slot.population.validations..' meanMs='..slot.population.validationMs/slot.population.validations..' maxMs='..slot.population.maxValidationMs)
   p:sendEvent('Density_Bounds',slot.objects)
   stage=2;at=t+45
  elseif t>limit then error('population timeout '..tostring(slot.population and slot.population.made))end
 elseif stage==2 and t>at then
  check((slot.waves or 0)>=1,'stationary player receives natural reinforcement groups')
  check(arrivals>=1,'reinforcement actually arrives within encounter range')
  print('[DENSITY] stationary waves='..(slot.waves or 0)..' arrivals='..arrivals..' maxNearby='..maxNear..' maxAlive='..maxAlive..' phase='..slot.pacing.phase)
  waveBase=slot.waves or 0;p:sendEvent('Density_Health',.2);stage=3;at=t+5
 elseif stage==3 and t>at then
  check(slot.pacing.blocked and (slot.pacing.phase=='fade'or slot.pacing.phase=='relax'),'actual low health stops new pressure')
  check((slot.waves or 0)==waveBase and not slot.pending,'no new reinforcement group during low health')
  p:sendEvent('Density_Health',1);stage=4;at=t+3
 elseif stage==4 and t>at then
  check(checked>=24,'ambient and wave positions independently checked outside rendered view')
  p:sendEvent('Density_Walk',path(layouts[1],p.position,layouts[1].anchors[1]));stage=5;limit=t+65
 elseif stage==5 then
  if t>nextKill then
   for _,actor in ipairs(slot.objects)do if actor:isValid()and actor.count>0 and(actor.position-p.position):length()<1000 then kill(actor)end end
   nextKill=t+2
  end
  if walked then
   check(walked>2000,'player physically traverses broad connected space')
   print('[DENSITY] moving distance='..walked..' maxNearby='..maxNear..' waves='..(slot.waves or 0)..' promotions='..(slot.promotions or 0))
   check((slot.promotions or 0)<=2,'higher population does not multiply promoted enemies')
   for _,actor in ipairs(slot.objects)do if actor:isValid()and actor.count>0 then kill(actor)end end
   stage=6;at=t+3;limit=t+65
  elseif t>limit then error('physical traversal timed out '..tostring(p.position))end
 elseif stage==6 and t>at then
  if slot.pacing.phase=='relax' then
   check(slot.pacing.blocked,'quiet recovery starts after actual threats die')
   deadline=slot.pacing.untilTime;waveBase=slot.waves;stage=7;limit=t+65
  elseif t>limit then error('no actual recovery after cleared threats')end
 elseif stage==7 then
  if now<deadline then assert((slot.waves or 0)==waveBase,'wave spawned during recovery window')end
  if slot.pacing.phase=='build' then
   check(now>=deadline,'full recovery window precedes new build')
   D.test.retreat(p);stage=8;at=t+3
  elseif t>limit then error('recovered player never resumes build')end
 elseif stage==8 and t>at then D.test.resume(p);stage=9;at=t+3
 elseif stage==9 and t>at then
  check(slot.nextWave>now,'portal resume keeps grace period')
  stage=10;types.Player.sendMenuEvent(p,'AshenLoot_TestSave')
 elseif stage==10 and loaded and t>at then
  check(slot.population.done and slot.population.made==24 and not slot.populationPending,'save/load preserves population and clears request')
  stage=11;at=t+3
 elseif stage==11 and t>at then
  matrixIndex=matrixIndex+1
  if matrixIndex>#matrix then
   check(checked>=150,'all-theme accepted spawns independently outside rendered view')
   print('[DENSITY] ALL PASS ambient density, arrivals, physical traversal, actual recovery, portals, save/load, themes and depth');stage=99;core.quit();return
  end
  local depth=matrix[matrixIndex];d.depth=depth-1
  if depth>=25 then d.baseline=50;p:sendEvent('Density_Level',50)end
  D.test.descend(p);stage=12;limit=t+90
 elseif stage==12 then
  local depth=matrix[matrixIndex];local s=d.slots[(depth-1)%12+1]
  if s and s.population and s.population.done then
   check(s.population.made==P.ambientTarget(depth),'full ambient population at depth '..depth)
   check(D.test.aliveCount(s)>=s.population.target,'actual living population depth '..depth)
   print('[DENSITY] depth='..depth..' actors='..D.test.aliveCount(s)..' meanMs='..s.population.validationMs/s.population.validations..' maxMs='..s.population.maxValidationMs)
   p:sendEvent('Density_Bounds',s.objects)
   if depth%3==0 then
    check(s.boss and A.getState().elites[s.boss.id]and A.getState().elites[s.boss.id].worldBoss,'scheduled guardian remains a World Boss depth '..depth)
   end
   if depth==3 then
    local exit=layouts[3].exit;p:teleport(s.cell,util.vector3(exit[1]-1200,exit[2],8),{onGround=true})
    stage=13;at=t+3;limit=t+50
   else stage=11;at=t+3 end
  elseif t>limit then error('theme population timeout depth '..depth..' made '..tostring(s and s.population and s.population.made))end
 elseif stage==13 then
  local s=d.slots[3]
  if t>at then
   for _,actor in ipairs(s.objects)do if actor~=s.boss then kill(actor)end end
   s.nextAdds=now;at=t+3
  end
  if (s.addsMade or 0)>=4 then
   check(not D.test.beginPlacement(s,3,p,true),'guardian four-add cumulative bound retained')
   kill(s.boss);stage=14;at=t+3
  elseif t>limit then error('guardian adds timeout '..tostring(s.addsMade)..' '..tostring(s.lastPlacementFailure))end
 elseif stage==14 and t>at then
  local s=d.slots[3];check(s.bossDefeated and s.pacing.phase=='relax' and s.nextWave>now,'guardian defeat grants quiet recovery')
  stage=11;at=t+3
 end
 if t>650 and stage~=99 then error('density timeout stage '..stage)end
end
return {engineHandlers={onUpdate=function(dt)local ok,e=pcall(run,dt);if not ok then print('[DENSITY] FAIL '..tostring(e));core.quit()end end,
 onSave=function()return{stage=stage,t=t,at=at,checked=checked,maxNear=maxNear,maxAlive=maxAlive}end,
 onLoad=function(v)if v then stage=v.stage;t=v.t;at=t+4;checked=v.checked;maxNear=v.maxNear;maxAlive=v.maxAlive;loaded=true end end},eventHandlers={
 Density_Walked=function(n)walked=n end,
 Density_Bounds=function(e)print('[DENSITY] actual half-bounds width='..e.largest..' height='..e.tallest..' blocked='..e.blocked);assert(e.blocked==0,'actor clearance failed')end,
 Density_Checked=function(n)checked=checked+n end,
 Dreamforged_DelveAnchor=function(e)if e.clear and e.positions then e.player:sendEvent('Density_Check',e)end end,
 Dreamforged_DelvePopulation=function(e)if #e.positions>0 then e.player:sendEvent('Density_Check',e)end end}}
