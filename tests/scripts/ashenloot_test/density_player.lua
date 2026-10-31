local core,self,I,types=require('openmw.core'),require('openmw.self'),require('openmw.interfaces'),require('openmw.types')
local util,camera,ui,nearby=require('openmw.util'),require('openmw.camera'),require('openmw.ui'),require('openmw.nearby')
local fraction=1;local views={};local walk,walkIndex,walkStart
local frameTimes={};local frameCell
local function capture(token)
 local f=camera.viewportToWorldVector(util.vector2(.5,.5)):normalize();local r=camera.viewportToWorldVector(util.vector2(1,.5)):normalize();local u=camera.viewportToWorldVector(util.vector2(.5,0)):normalize()
 views[token]={p=camera.getPosition(),f=f,r=(r-f*r:dot(f)):normalize(),u=(u-f*u:dot(f)):normalize(),tan=math.tan(camera.getFieldOfView()/2),aspect=ui.screenSize().x/ui.screenSize().y}
end
return {engineHandlers={onFrame=function()
 if self.cell then
  if frameCell~=self.cell.id then frameCell=self.cell.id;frameTimes={}end
  if #frameTimes<10000 then frameTimes[#frameTimes+1]=core.getRealFrameDuration()*1000 end
 end
 if I.UI.getMode()==I.UI.MODE.Interface then I.UI.removeMode(I.UI.MODE.Interface)end
 local hp=types.Actor.stats.dynamic.health(self);hp.base=1000000;hp.current=(hp.base+hp.modifier)*fraction
 local fatigue=types.Actor.stats.dynamic.fatigue(self);fatigue.base=1000000;fatigue.current=1000000
 if walk then
  local a=walk[walkIndex];local d=util.vector3(a[1],a[2],8)-self.position
  if d:length()<110 then
   walkIndex=walkIndex+1
   if walkIndex>#walk then
    self.controls.movement=0;self.controls.sideMovement=0;walk=nil
    core.sendGlobalEvent('Density_Walked',(self.position-walkStart):length())
   end
  else
   local length=math.sqrt(d.x*d.x+d.y*d.y);local dx,dy=d.x/length,d.y/length;local yaw=self.rotation:getYaw()
   self.controls.movement=dx*math.sin(yaw)+dy*math.cos(yaw)
   self.controls.sideMovement=dx*math.cos(yaw)-dy*math.sin(yaw);self.controls.run=true
   types.Actor.stats.attributes.speed(self).base=150
  end
 end
end},eventHandlers={
 Density_Health=function(f)fraction=f end,
 Density_Level=function(n)types.Actor.stats.level(self).current=n end,
 Density_Frames=function()
  table.sort(frameTimes);local sum=0;for _,n in ipairs(frameTimes)do sum=sum+n end
  core.sendGlobalEvent('Density_Frames',{count=#frameTimes,mean=sum/math.max(1,#frameTimes),p95=frameTimes[math.max(1,math.floor(#frameTimes*.95))],max=frameTimes[#frameTimes]})
 end,
 Density_HUD=function()core.sendGlobalEvent('Density_HUD',I.AshenLootUI.getDirectorDebug())end,
 Density_Walk=function(points)walk=points;walkIndex=1;walkStart=self.position end,
 Density_Bounds=function(actors)
  local largest,tallest,blocked=0,0,0
  for _,actor in ipairs(actors)do if actor:isValid()and actor.count>0 and actor.cell==self.cell then
   local bounds=types.Actor.getPathfindingAgentBounds(actor);local r=math.max(bounds.halfExtents.x,bounds.halfExtents.y)
   largest=math.max(largest,r);tallest=math.max(tallest,bounds.halfExtents.z)
   if nearby.castRay(actor.position+util.vector3(0,0,r+20),actor.position+util.vector3(0,0,math.max(r+40,bounds.halfExtents.z*2)),{radius=r,collisionType=nearby.COLLISION_TYPE.World+nearby.COLLISION_TYPE.Door}).hit then blocked=blocked+1 end
  end end
  core.sendGlobalEvent('Density_Bounds',{largest=largest,tallest=tallest,blocked=blocked})
 end,
 Dreamforged_DelvePopulation=function(e)capture(e.token)end,
 Dreamforged_DelveCheckAnchor=function(e)capture(e.token)end,
 Density_Check=function(e)
  local v=assert(views[e.token],'missing independent rendered snapshot')
  for _,p in ipairs(e.positions)do
   local d=util.vector3(p[1],p[2],p[3]+150)-v.p;local z=d:dot(v.f)
   assert(not(z>0 and math.abs(d:dot(v.r))<=z*v.tan*v.aspect and math.abs(d:dot(v.u))<=z*v.tan),'spawn inside rendered view')
  end
  views[e.token]=nil;core.sendGlobalEvent('Density_Checked',#e.positions)
 end}}
