local core,self,types,I=require('openmw.core'),require('openmw.self'),require('openmw.types'),require('openmw.interfaces')
local camera,util,ui=require('openmw.camera'),require('openmw.util'),require('openmw.ui')
local timer=0
return {engineHandlers={onFrame=function()
 if I.UI.getMode()==I.UI.MODE.Interface then I.UI.removeMode(I.UI.MODE.Interface)end
end,onUpdate=function(dt)
 timer=timer+dt;if timer<1 then return end;timer=0
 local hp=types.Actor.stats.dynamic.health(self);hp.base=1000000;hp.current=1000000
end},eventHandlers={DirectorProbe_Compare=function(e)
 local centre=camera.viewportToWorldVector(util.vector2(.5,.5)):normalize()
 local rightRay=camera.viewportToWorldVector(util.vector2(1,.5)):normalize()
 local upRay=camera.viewportToWorldVector(util.vector2(.5,0)):normalize()
 local right=(rightRay-centre*rightRay:dot(centre)):normalize()
 local up=(upRay-centre*upRay:dot(centre)):normalize()
 local rel=e.position+util.vector3(0,0,80)-camera.getPosition()
 local z=rel:dot(centre);local screen=ui.screenSize();local tan=math.tan(camera.getFieldOfView()/2)
 local x,y=rel:dot(right)/math.max(.0001,z*tan*screen.x/screen.y),rel:dot(up)/math.max(.0001,z*tan)
 core.sendGlobalEvent('DirectorProbe_Reference',{token=e.token,visible=z>0 and math.abs(x)<=1 and math.abs(y)<=1,x=x,y=y,z=z,fov=camera.getFieldOfView()})
end}}
