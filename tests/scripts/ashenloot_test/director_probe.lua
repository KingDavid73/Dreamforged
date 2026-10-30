local core,world,types,I=require('openmw.core'),require('openmw.world'),require('openmw.types'),require('openmw.interfaces')
local layouts,util=require('scripts.ashenloot.delve_layouts'),require('openmw.util')
local t,stage,at,probe=0,0,0,0
local responses,references,actors={},{},{}
local iso=core.contentFiles.has('isowind.omwscripts')
local function line(s)print('[DIRECTOR DIAG] '..(iso and 'ISO ' or 'CONTROL ')..s)end
local function dump(slot,label)
 local diag=slot.diagnostics or {};line(label..' depth='..slot.depth..' waves='..(slot.waves or 0)..' objects='..#slot.objects..' adds='..(slot.addsMade or 0)..' requests='..(slot.request or 0))
 local keys={};for k in pairs(diag.counts or {})do keys[#keys+1]=k end;table.sort(keys)
 for _,k in ipairs(keys)do line('gate '..k..'='..diag.counts[k])end
 for _,a in ipairs(diag.candidates or {})do line('candidate '..a.index..' distance='..a.distance..' occupied='..tostring(a.occupied)..' range='..tostring(a.inRange))end
 local r=diag.lastResponse;if r then line('last response token='..r.token..' clear='..tostring(r.clear)..' reason='..tostring(r.reason)..' ground='..tostring(r.ground)..' visible='..tostring(r.visible)..' occupied='..tostring(r.occupied))end
 for _,h in ipairs(diag.history or {})do line('history '..h.time..' '..h.status..' '..tostring(h.detail))end
end
local function run(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local A=I.AshenLoot;local D=A.delve;local d=D.test.data();local slot=d.slots[1]
 if stage==0 and t>3 then line('settings enabled='..tostring(require('scripts.ashenloot.config').enabled)..' extra='..tostring(require('scripts.ashenloot.config').extraEncounters));D.test.descend(p);stage=1;at=t+6
 elseif stage==1 and t>at then
  slot.nextWave=core.getSimulationTime()+120
  probe=probe+1;local a=layouts[1].anchors[probe];local token='probe:'..probe
  local e={token=token,depth=1,position=util.vector3(a[1],a[2],a[3])}
  p:sendEvent('Dreamforged_DelveCheckAnchor',e);p:sendEvent('DirectorProbe_Compare',e)
  if probe==6 then stage=2;at=t+2 else at=t+2 end
 elseif stage==2 and t>at then
  for n=1,6 do
   local r,v=responses['probe:'..n],references['probe:'..n];assert(r and v,'probe response missing '..n)
   local c=r.camera
   line('probe '..n..' ground='..tostring(r.ground)..' legacyVisible='..tostring(r.visible)..' referenceVisible='..tostring(v.visible)..' x='..v.x..' y='..v.y..' reason='..tostring(r.reason)..' fovDeg='..math.deg(c.fov)..' eventFovDeg='..tostring(c.receivedFov and math.deg(c.receivedFov))..' referenceFovDeg='..math.deg(v.fov)..' baseDeg='..math.deg(c.baseFov)..' rayHalfDeg='..tostring(c.viewportHalfAngle and math.deg(c.viewportHalfAngle)))
  end
  if core.contentFiles.has('director-quick.omwscripts')then line('QUICK COMPLETE');core.quit();stage=99;return end;line('observing runtime scheduler for 45 seconds');slot.nextWave=core.getSimulationTime();stage=3;at=t+45
 elseif stage==3 and t>at then
  dump(slot,'idle floor');line('world debug='..tostring(A.getState().director.outdoor.debug.status))
  for i=5,#slot.objects do local o=slot.objects[i];if o:isValid() then o:addScript('scripts/ashenloot_test/enemy_actor.lua');o:sendEvent('EnemyTest_Inspect')end end
  stage=4;at=t+3
 elseif stage==4 and t>at then
  for id,r in pairs(actors)do line('reinforcement actor='..id..' combat='..tostring(r.combat)..' fight='..r.fight..' flee='..r.flee)end
  if not iso then line('COMPLETE');core.quit();stage=99;return end
  D.test.descend(p);stage=5;at=t+3
 elseif stage==5 and t>at then D.test.descend(p);stage=6;at=t+4
 elseif stage==6 and t>at then
  local boss=d.slots[3].boss;assert(boss,'missing boss fixture')
  p:teleport(boss.cell,boss.position+util.vector3(300,0,0),{onGround=true});stage=7;at=t+30
 elseif stage==7 and t>at then dump(d.slots[3],'boss floor');line('COMPLETE');core.quit();stage=99
 end
 if t>140 and stage~=99 then error('timeout stage '..stage)end
end
return {engineHandlers={onUpdate=function(dt)local ok,e=pcall(run,dt);if not ok then line('FAIL '..tostring(e));core.quit()end end},
 eventHandlers={Dreamforged_DelveAnchor=function(e)if type(e.token)=='string' then responses[e.token]=e end end,
 DirectorProbe_Reference=function(e)references[e.token]=e end,
 EnemyTest_Report=function(e)actors[e.id]=e end}}
