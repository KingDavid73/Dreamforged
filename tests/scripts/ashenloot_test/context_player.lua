local core,self,I,types=require('openmw.core'),require('openmw.self'),require('openmw.interfaces'),require('openmw.types')
return {engineHandlers={onFrame=function()
 if I.UI.getMode()==I.UI.MODE.Interface then I.UI.removeMode(I.UI.MODE.Interface)end
 for _,stat in ipairs({'health','fatigue'})do local v=types.Actor.stats.dynamic[stat](self);v.base=1000000;v.current=1000000 end
end},eventHandlers={ContextTest_Report=function()
 local d=I.AshenLootUI.getDirectorDebug()
 core.sendGlobalEvent('ContextTest_Report',{state=d.state,lines=d.lines,visible=d.visible})
end}}
