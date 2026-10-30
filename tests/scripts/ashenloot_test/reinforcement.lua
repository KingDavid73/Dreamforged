local core,world,types,I=require('openmw.core'),require('openmw.world'),require('openmw.types'),require('openmw.interfaces')
local storage=require('openmw.storage');local previousExtra,previousEnabled;local lastMade;local capObserved=false
local util=require('openmw.util');local C=require('scripts.ashenloot.config');local layouts=require('scripts.ashenloot.delve_layouts')
local stage,t,at,limit,loaded=0,0,0,0,false
local checks,route,cam=0,false,nil;local reports={};local pursuing,initialDistance,oldToken,waveBase,baseline,modeIndex
local iso=core.contentFiles.has('isowind.omwscripts')
local function check(v,s)assert(v,s);print('[REINFORCEMENT FIX] PASS '..s)end
local function run(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local A=I.AshenLoot;local D=A.delve;local d=D.test.data();local slot=d.slots[1];local now=core.getSimulationTime()
 for _,s in pairs(d.slots)do assert(D.test.aliveCount(s)<=8,'live cap exceeded')end
 if stage==0 and t>3 then D.test.descend(p);stage=1;limit=t+65
 elseif stage==1 then
  if (slot.waves or 0)>0 then
   check(#slot.objects>4,'natural isometric/normal wave produces real actors');slot.nextWave=now+200
   for _,o in ipairs(slot.objects)do if d.actors[o.id].reinforcement then pursuing=o;break end end
   check(pursuing,'reinforcement metadata recorded');stage=2;at=t+2
  elseif t>limit then error('no initial wave: '..tostring(slot.lastPlacementFailure))end
 elseif stage==2 and t>at then
  initialDistance=(pursuing.position-p.position):length();pursuing:addScript('scripts/ashenloot_test/enemy_actor.lua');pursuing:sendEvent('EnemyTest_Inspect');stage=3;at=t+8
 elseif stage==3 and t>at then
  check(reports[pursuing.id] and reports[pursuing.id].combat,'reinforcement actively pursues player')
  check((pursuing.position-p.position):length()<initialDistance-100,'reinforcement moves toward encounter')
  waveBase=slot.waves;baseline=#slot.objects
  check(D.test.beginPlacement(slot,1,p,false),'second batch can be requested');oldToken=slot.pending.token
  D.test.retreat(p);D.anchor{player=p,depth=1,token=oldToken,clear=true}
  stage=4;at=t+2
 elseif stage==4 and t>at then
  check(p.cell.name==require('scripts.ashenloot.delve_rules').hub and not slot.pending and not slot.placement,'portal cancels in-flight placement')
  check(slot.waves==waveBase and #slot.objects==baseline,'late portal response cannot spawn')
  D.test.resume(p);stage=5;at=t+3
 elseif stage==5 and t>at then
  check(slot.nextWave>now,'portal resume grants recovery window')
  slot.pending={token='preload-sentinel',expires=now+120};slot.placement={bossAdd=false,expires=now+120}
  types.Player.sendMenuEvent(p,'AshenLoot_TestSave');stage=6
 elseif stage==6 and loaded and t>at then
  check(not slot.pending and not slot.placement,'save/load discards obsolete placement request')
  D.anchor{player=p,depth=1,token='preload-sentinel',clear=true};check(slot.waves==waveBase,'pre-load reply cannot duplicate a wave')
  p:sendEvent('ReinforcementTest_Route',{});stage=7;at=t+2
 elseif stage==7 and t>at then
  check(route,'authored route fallback passes physical checks and rejects off-floor destination')
  previousExtra=storage.globalSection(C.groupKey('extraEncounters')):get('extraEncounters')
  storage.globalSection(C.groupKey('extraEncounters')):set('extraEncounters',false);stage=71;at=t+2
 elseif stage==71 and t>at then
  check(not D.test.beginPlacement(slot,1,p,false),'extra encounter toggle blocks new groups')
  storage.globalSection(C.groupKey('extraEncounters')):set('extraEncounters',previousExtra)
  previousEnabled=storage.globalSection(C.groupKey('enabled')):get('enabled')
  storage.globalSection(C.groupKey('enabled')):set('enabled',false);stage=72;at=t+2
 elseif stage==72 and t>at then
  check(not D.test.beginPlacement(slot,1,p,false),'disabled mod blocks new groups')
  storage.globalSection(C.groupKey('enabled')):set('enabled',previousEnabled);stage=73;at=t+2
 elseif stage==73 and t>at then
  D.test.cancelPlacement(slot,'test cleanup');for _,o in ipairs(slot.objects)do if o:isValid() and o.count>0 then o:remove()end end
  slot.nextWave=now+200;stage=8;at=t+2
 elseif stage==8 and t>at then
  check(D.test.aliveCount(slot)==0,'removed valid references do not consume population capacity')
  check(D.test.beginPlacement(slot,1,p,false),'cleared floor can request another group')
  oldToken=slot.pending.token
  D.anchor{player=p,depth=1,token=oldToken,clear=false,reason='injected candidate rejection'}
  check(slot.pending and slot.pending.token~=oldToken,'rejected candidate immediately advances to a different request')
  local token=slot.pending.token;D.anchor{player=p,depth=1,token=oldToken,clear=true}
  check(slot.pending.token==token,'duplicate stale response cannot consume current request')
  waveBase=slot.waves;stage=9;limit=t+35
 elseif stage==9 then
  if slot.waves>waveBase then stage=91;at=t+1
  elseif t>limit then error('no post-clear wave: '..tostring(slot.lastPlacementFailure))end
 elseif stage==91 and t>at then
  check(D.test.aliveCount(slot)>0,'reinforcements resume after clearing the floor');modeIndex=1;stage=10;at=t+1
 elseif stage==10 and t>at then
  D.test.cancelPlacement(slot,'view switch test');for _,o in ipairs(slot.objects)do if o:isValid() and o.count>0 then o:remove()end end
  slot.nextWave=now+200;cam=nil
  p:sendEvent('ReinforcementTest_Camera',iso and {switch=true} or {mode=modeIndex==1 and 'third' or 'first'})
  stage=11;at=t+4
 elseif stage==11 and t>at then p:sendEvent('ReinforcementTest_CameraReport',{});stage=12;at=t+1
 elseif stage==12 and t>at then
  local wanted=modeIndex==1 and 'third' or modeIndex==2 and 'first' or 'iso';check(cam and cam.mode==wanted,'camera reaches '..wanted)
  check(D.test.beginPlacement(slot,1,p,false),'placement starts in '..wanted);waveBase=slot.waves;stage=13;limit=t+25
 elseif stage==13 then
  if slot.waves>waveBase then
   check(true,'safe wave succeeds in '..cam.mode)
   if modeIndex<(iso and 3 or 2)then modeIndex=modeIndex+1;stage=10;at=t+1
   elseif iso then p:sendEvent('ReinforcementTest_Camera',{zoom=-60});stage=14;at=t+3
   else stage=17;at=t+1 end
  elseif t>limit then error('view-mode wave failed: '..tostring(slot.lastPlacementFailure))end
 elseif stage==14 and t>at then
  cam=nil;p:sendEvent('ReinforcementTest_CameraReport',{});stage=15;at=t+1
 elseif stage==15 and t>at then
  check(cam and cam.mode=='iso' and cam.distance>1500,'isometric zoom-out changes view distance')
  p:sendEvent('ReinforcementTest_Camera',{zoom=60});stage=16;at=t+3
 elseif stage==16 and t>at then stage=17;at=t+1
 elseif stage==17 and t>at then D.test.descend(p);stage=18;at=t+3
 elseif stage==18 and t>at then D.test.descend(p);stage=19;at=t+4
 elseif stage==19 and t>at then
  local boss=d.slots[3].boss;check(boss~=nil,'guardian floor exists')
  p:teleport(boss.cell,boss.position+util.vector3(300,0,0),{onGround=true});stage=20;limit=t+35
 elseif stage==20 then
  local s=d.slots[3]
  if (s.addsMade or 0)>0 then
   check(s.addsMade<=4 and D.test.aliveCount(s)<=8,'boss adds spawn within cumulative and live caps')
   check((s.ordinaryWaves or 0)==0,'ordinary waves pause during nearby guardian')
   check(s.nextAdds-now>20,'successful boss add grants the normal add interval')
   stage=21;limit=t+30;s.nextAdds=now
  elseif t>limit then error('boss adds never placed: '..tostring(s.lastPlacementFailure))end
 end
 if stage==21 then
  local s=d.slots[3];local alive=D.test.aliveCount(s)
  if alive==8 and (s.addsMade or 0)<4 then
   check(not D.test.beginPlacement(s,3,p,true),'live cap prevents ninth actor during boss fight');capObserved=true
   for _,o in ipairs(s.objects)do if o~=s.boss and o:isValid() and o.enabled then o:remove();break end end
  end
  if (s.addsMade or 0)>=4 then
   check(not D.test.beginPlacement(s,3,p,true),'cumulative four-add budget blocks further adds')
   check(checks>=6,'independent rendered-view checks passed for accepted formation points')
   print('[REINFORCEMENT FIX] ALL PASS '..(iso and 'ISOWIND' or 'STOCK'));core.quit();stage=99
  elseif t>limit then error('boss cumulative budget test timed out '..tostring(s.addsMade))
  elseif not s.pending then s.nextAdds=now end
 end
 if t>280 and stage~=99 then error('overall timeout stage '..stage)end
end
return {engineHandlers={onUpdate=function(dt)local ok,e=pcall(run,dt);if not ok then print('[REINFORCEMENT FIX] FAIL stage '..stage..' '..tostring(e));core.quit()end end,
 onSave=function()return {stage=stage,t=t,pursuing=pursuing,waveBase=waveBase,baseline=baseline,checks=checks}end,
 onLoad=function(v)stage,t,pursuing,waveBase,baseline,checks=v.stage,v.t,v.pursuing,v.waveBase,v.baseline,v.checks;loaded=true;at=t+3 end},
 eventHandlers={EnemyTest_Report=function(e)reports[e.id]=e end,ReinforcementTest_Checked=function(n)checks=checks+n end,
 ReinforcementTest_CameraState=function(e)cam=e end,ReinforcementTest_RouteResult=function(e)route=e end,
 Dreamforged_DelveAnchor=function(e)if e.clear and e.positions then e.player:sendEvent('ReinforcementTest_Check',{token=e.token,positions=e.positions,fov=e.camera.fov})end end}}
