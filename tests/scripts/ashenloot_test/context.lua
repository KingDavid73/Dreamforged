local core,world,I,types=require('openmw.core'),require('openmw.world'),require('openmw.interfaces'),require('openmw.types')
local util,storage=require('openmw.util'),require('openmw.storage')
local C=require('scripts.ashenloot.config');local Context=require('scripts.ashenloot.encounter_context')
local layouts=require('scripts.ashenloot.delve_layouts')
local stage,t,at,report,loaded,fixture=0,0,0,nil,false,nil
local function check(v,s)assert(v,s);print('[CONTEXT FIX] PASS '..s)end
local function expect(p,context)
 local d=I.AshenLoot.progression.debugState(p)
 check(d.context==context,'actual location policy '..context)
 check(report and report.visible and report.state and report.state.context==context and report.state.cellId==p.cell.id,'rendered HUD follows '..context)
 local text=table.concat(report.lines,' | ')
 if context=='wilderness' then check(text:find('Pressure',1,true) and text:find('Boss cycle',1,true),'wilderness retains pressure/cycle HUD')
 else check(not text:find('Pressure',1,true) and not text:find('Boss cycle',1,true) and d.pressure==nil,'no wilderness metrics in '..context)end
 if context=='delve' then check(text:find('Depth 1',1,true) and text:find('Enemies',1,true) and text:find('Guardian',1,true),'dungeon HUD uses actual floor counters')end
 return d
end
local function travel(p,name)
 -- Authored base-game floor positions; unloaded cell:getAll() may be empty.
 local cell=world.getCellByName(name)
 local pos=name=='Addamasartus' and util.vector3(1250,650,500)or util.vector3(100,-100,220)
 p:teleport(cell,pos,{onGround=true});report=nil;at=t+5
end
local function run(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local A=I.AshenLoot;local P,D=A.progression,A.delve
 if stage==0 and t>3 then
  check(Context.kind({name=layouts[1].name})=='delve','authored floor recognized')
  check(Context.kind({name='Dreamforged Depth 99'})=='interior','unowned matching name is not a generated floor')
  check(Context.kind({name=Context.hub,isExterior=true})=='wilderness','exterior classification has priority')
  check(Context.get({name='office'},false).id=='interior_safe' and Context.get({name='cave'},true).interiorPacks,'ordinary interior policies remain distinct')
  storage.globalSection(C.groupKey('directorDebugView')):set('directorDebugView',true)
  local safe=P.test.context(p.cell);check(safe.id=='refuge' and not safe.progression and not safe.rerunInterior,'shrine refuge explicitly safe')
  fixture=world.createObject('df_delve_enemy_rat',1);fixture:teleport(p.cell,p.position+util.vector3(600,0,0))
  check(P.test.rerunDungeon(p.cell,{},true)==0,'refuge cannot reset as a hostile shrine')
  stage=1;at=t+5
 elseif stage==1 and t>at then
  check(fixture.cell==p.cell and fixture.enabled and fixture.count>0,'refuge fixture is actually present')
  check(not A.eligible(fixture),'refuge actors excluded from promotions and automatic progression')
  P.prepare(fixture,true);check(not A.getState().director.actors[fixture.id],'refuge prepare cannot create director actor')
  fixture:remove();p:sendEvent('ContextTest_Report',{});stage=2;at=t+1
 elseif stage==2 and t>at then
  expect(p,'refuge');travel(p,"Seyda Neen, Census and Excise Office");stage=3
 elseif stage==3 and t>at then p:sendEvent('ContextTest_Report',{});stage=4;at=t+1
 elseif stage==4 and t>at then expect(p,'interior_safe');travel(p,'Addamasartus');stage=5
 elseif stage==5 and t>at then p:sendEvent('ContextTest_Report',{});stage=6;at=t+1
 elseif stage==6 and t>at then
  expect(p,'interior_hostile');p:teleport('',util.vector3(-7500,-68000,500),{onGround=true});report=nil;stage=7;at=t+5
 elseif stage==7 and t>at then p:sendEvent('ContextTest_Report',{});stage=8;at=t+1
 elseif stage==8 and t>at then expect(p,'wilderness');D.test.descend(p);report=nil;stage=9;at=t+5
 elseif stage==9 and t>at then p:sendEvent('ContextTest_Report',{});stage=10;at=t+1
 elseif stage==10 and t>at then
  local d=expect(p,'delve');local slot=D.test.data().slots[1]
  check(d.alive==D.test.aliveCount(slot) and d.cap==8 and d.depth==1,'HUD counters match live dungeon state')
  check(not P.test.context(p.cell).interiorPacks and not P.test.context(p.cell).randomBosses,'generated floors bypass legacy packs and random bosses')
  check(P.test.rerunDungeon(p.cell,{},true)==0,'generated floor cannot use ordinary interior reset')
  local outdoor=A.getState().director.outdoor;local pressure,cycle=outdoor.pressure,outdoor.bossProgress
  P.victoryRespite(slot.objects[1],nil);P.victoryRespite(slot.objects[1],{worldBoss=true})
  check(outdoor.pressure==pressure and outdoor.bossProgress==cycle,'dungeon kills cannot change wilderness pressure or boss cycle')
  slot.nextWave=core.getSimulationTime();stage=11;at=t+55
 elseif stage==11 then
  local slot=D.test.data().slots[1]
  if (slot.waves or 0)>0 then
   slot.nextWave=core.getSimulationTime()+200;stage=111;at=t+1
  elseif t>at then error('dedicated wave timeout '..tostring(slot.lastPlacementFailure))end
 elseif stage==111 and t>at then
  local slot=D.test.data().slots[1]
  check(D.test.aliveCount(slot)>4 and D.test.aliveCount(slot)<=8,'dedicated dungeon wave still spawns real bounded actors')
  D.test.retreat(p);report=nil;stage=12;at=t+5
 elseif stage==12 and t>at then p:sendEvent('ContextTest_Report',{});stage=13;at=t+1
 elseif stage==13 and t>at then
  expect(p,'refuge');D.test.resume(p);stage=14;at=t+5
 elseif stage==14 and t>at then
  p:sendEvent('AshenLoot_DirectorDebug',{context='wilderness',contextLabel='WRONG STALE CELL',cellId='stale-cell',pressure=100})
  stage=15;at=t+2
 elseif stage==15 and t>at then p:sendEvent('ContextTest_Report',{});stage=16;at=t+1
 elseif stage==16 and t>at then
  expect(p,'delve');check(not table.concat(report.lines,' '):find('WRONG STALE CELL',1,true),'old-cell debug event rejected')
  stage=17;types.Player.sendMenuEvent(p,'AshenLoot_TestSave')
 elseif stage==17 and loaded and t>at then p:sendEvent('ContextTest_Report',{});stage=18;at=t+1
 elseif stage==18 and t>at then
  expect(p,'delve');check(P.debugState(p).depth==1,'save/load rebinds dungeon debug provider')
  print('[CONTEXT FIX] ALL PASS explicit policies, rendered HUD, natural wave, portal and save/load');stage=99;core.quit()
 end
 if t>160 and stage~=99 then error('context test timeout stage '..stage)end
end
return {engineHandlers={onUpdate=function(dt)local ok,e=pcall(run,dt);if not ok then print('[CONTEXT FIX] FAIL '..tostring(e));core.quit()end end,
 onSave=function()return{stage=stage,t=t,at=at}end,
 onLoad=function(d)if d then stage=d.stage;t=d.t;at=t+5;loaded=true end end},
 eventHandlers={ContextTest_Report=function(e)report=e end}}
