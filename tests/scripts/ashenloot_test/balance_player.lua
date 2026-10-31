local core,self,types,I=require('openmw.core'),require('openmw.self'),require('openmw.types'),require('openmw.interfaces')
local targetLevel
return{engineHandlers={onFrame=function()
 if I.UI.getMode()==I.UI.MODE.Interface then I.UI.removeMode(I.UI.MODE.Interface)end
 if targetLevel then types.Actor.stats.level(self).current=targetLevel end
 for _,name in ipairs({'health','fatigue'})do local s=types.Actor.stats.dynamic[name](self);s.base=1000000;s.current=1000000 end
end},eventHandlers={Balance_Level=function(n)targetLevel=n;types.Actor.stats.level(self).current=n end}}
