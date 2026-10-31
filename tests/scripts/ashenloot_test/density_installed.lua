local core,world,I,types=require('openmw.core'),require('openmw.world'),require('openmw.interfaces'),require('openmw.types')
local storage,C=require('openmw.storage'),require('scripts.ashenloot.config')
local stages={1,4,7,10,30};local index,t,stage,at,limit,checked,bounds=1,0,0,0,0,0,0
local hud=false
local function advance(D,d,p)
 index=index+1
 if index>#stages then
  assert(bounds==#stages and checked>=130 and hud,'installed view/bounds/HUD checks missing')
  print('[DENSITY INSTALLED] ALL PASS configured release, all palettes, depth30, actual actor bounds, rendered visibility and performance');core.quit();stage=99;return
 end
 d.depth=stages[index]-1
 if stages[index]>=25 then d.baseline=50;p:sendEvent('Density_Level',50)end
 D.test.descend(p);stage=1;limit=t+90
end
return {engineHandlers={onUpdate=function(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local ok,e=pcall(function()
  local D=I.AshenLoot.delve;local d=D.test.data()
  if stage==0 and t>3 then
   storage.globalSection(C.groupKey('directorDebugView')):set('directorDebugView',true)
   D.test.descend(p);stage=1;limit=t+90
  elseif stage==1 then
   local depth=stages[index];local s=d.slots[(depth-1)%12+1]
   if s and s.population and s.population.done then
    assert(s.population.made==D.test.pacing.ambientTarget(depth),'installed population shortfall')
    p:sendEvent('Density_Bounds',s.objects)
    print('[DENSITY INSTALLED] depth='..depth..' alive='..D.test.aliveCount(s)..' meanCheckMs='..s.population.validationMs/s.population.validations..' maxCheckMs='..s.population.maxValidationMs)
    stage=2;at=t+(index==1 and 38 or 2)
   elseif t>limit then error('installed population timeout depth '..depth)end
  elseif stage==2 and t>at then
   if index==1 then
    local s=d.slots[1];assert((s.waves or 0)>0,'installed scheduler placed no groups')
    p:sendEvent('Density_Frames',{})
    p:sendEvent('Density_HUD',{})
    print('[DENSITY INSTALLED] stationary owned='..D.test.aliveCount(s)..' waves='..s.waves..' phase='..s.pacing.phase)
    stage=21;at=t+1;return
   end
   advance(D,d,p)
  elseif stage==21 and t>at then assert(hud,'HUD response missing');advance(D,d,p)
  end
 end)
 if not ok then print('[DENSITY INSTALLED] FAIL '..tostring(e));core.quit()end
end},eventHandlers={
 Density_Checked=function(n)checked=checked+n end,
 Density_Bounds=function(e)
  print('[DENSITY INSTALLED] halfBounds width='..e.largest..' height='..e.tallest..' blocked='..e.blocked)
  if e.blocked>0 then print('[DENSITY INSTALLED] FAIL actor clearance');core.quit()end
  bounds=bounds+1
 end,
 Density_Frames=function(e)print('[DENSITY INSTALLED] frames='..e.count..' meanMs='..e.mean..' p95Ms='..e.p95..' maxMs='..e.max)end,
 Density_HUD=function(e)
  local text=table.concat(e.lines,' ')
  hud=e.visible and e.state and e.state.context=='delve' and e.state.cap==48 and text:find('Intensity',1,true)and not text:find('Pressure',1,true)
  if not hud then print('[DENSITY INSTALLED] FAIL actual pacing HUD');core.quit()end
  print('[DENSITY INSTALLED] actual HUD '..text)
 end,
 Dreamforged_DelvePopulation=function(e)if #e.positions>0 then e.player:sendEvent('Density_Check',e)end end,
 Dreamforged_DelveAnchor=function(e)if e.clear and e.positions then e.player:sendEvent('Density_Check',e)end end}}
