local core,self,types,I=require('openmw.core'),require('openmw.self'),require('openmw.types'),require('openmw.interfaces')
local nearby,util,camera,ui,input,async=require('openmw.nearby'),require('openmw.util'),require('openmw.camera'),require('openmw.ui'),require('openmw.input'),require('openmw.async')
local refs={};local zoom,forcedMode;local timer=0
local iso=core.contentFiles.has('isowind.omwscripts')
if iso then input.bindAction('Zoom3rdPerson',async:callback(function(dt,value)if zoom then local v=zoom;zoom=nil;return v end;return value end),{})end
local function capture()
 local f=camera.viewportToWorldVector(util.vector2(.5,.5)):normalize();local r=camera.viewportToWorldVector(util.vector2(1,.5)):normalize();local u=camera.viewportToWorldVector(util.vector2(.5,0)):normalize()
 return {p=camera.getPosition(),f=f,r=(r-f*r:dot(f)):normalize(),u=(u-f*u:dot(f)):normalize(),tan=math.tan(camera.getFieldOfView()/2),aspect=ui.screenSize().x/ui.screenSize().y,fov=camera.getFieldOfView()}
end
return {engineHandlers={onFrame=function()
 if I.UI.getMode()==I.UI.MODE.Interface then I.UI.removeMode(I.UI.MODE.Interface)end
 if forcedMode then camera.setMode(forcedMode,true)end
end,onUpdate=function(dt)
 timer=timer+dt;if timer<1 then return end;timer=0
 for _,stat in ipairs({'health','fatigue'})do local v=types.Actor.stats.dynamic[stat](self);v.base=1000000;v.current=1000000 end
end},eventHandlers={
 Dreamforged_DelveCheckAnchor=function(e)refs[e.token]=capture()end,
 ReinforcementTest_Check=function(e)
  local v=refs[e.token];assert(v,'missing independent view snapshot')
  assert(math.abs(v.fov-e.fov)<.001,'validation FOV differs from rendered request FOV')
  for _,p in ipairs(e.positions)do
   local d=util.vector3(p[1],p[2],p[3]+150)-v.p;local z=d:dot(v.f)
   local visible=z>0 and math.abs(d:dot(v.r))<=z*v.tan*v.aspect and math.abs(d:dot(v.u))<=z*v.tan
   assert(not visible,'validated spawn point is inside rendered view')
  end
  refs[e.token]=nil;core.sendGlobalEvent('ReinforcementTest_Checked',#e.positions)
 end,
 ReinforcementTest_Camera=function(e)
  if e.switch and iso then input.activateTrigger('IsowindSwitchView')
  elseif e.mode then I.Camera.disableModeControl('ReinforcementTest');forcedMode=e.mode=='third' and camera.MODE.ThirdPerson or camera.MODE.FirstPerson end
  if e.zoom then zoom=e.zoom end
 end,
 ReinforcementTest_CameraReport=function()
  local mode=camera.getMode();core.sendGlobalEvent('ReinforcementTest_CameraState',{mode=mode==camera.MODE.Static and 'iso' or mode==camera.MODE.FirstPerson and 'first' or 'third',distance=(camera.getPosition()-self.position):length(),fov=camera.getFieldOfView()})
 end,
 ReinforcementTest_Route=function(e)
  local N=require('scripts.ashenloot.delve_navigation');local layouts=require('scripts.ashenloot.delve_layouts');local a=layouts[1].anchors[1]
  local ok,method=N.reachable(self.position,util.vector3(a[1],a[2],a[3]),{})
  assert(ok and method=='authored route','authored collision-checked fallback route failed')
  local bad=N.reachable(self.position,util.vector3(-1000,-1000,8),{})
  assert(not bad,'authored graph accepted destination outside floor')
  core.sendGlobalEvent('ReinforcementTest_RouteResult',true)
 end}}
