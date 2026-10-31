local core,self,I,types=require('openmw.core'),require('openmw.self'),require('openmw.interfaces'),require('openmw.types')
return {engineHandlers={onFrame=function()
 if I.UI.getMode()==I.UI.MODE.Interface then I.UI.removeMode(I.UI.MODE.Interface)end
 for _,name in ipairs({'health','fatigue'})do local s=types.Actor.stats.dynamic[name](self);s.base=1000000;s.current=1000000 end
end},eventHandlers={AshenLoot_DirectorVoice=function(e)core.sendGlobalEvent('Patron_Heard',e)end,
 Patron_Report=function()core.sendGlobalEvent('Patron_Report',I.AshenLootUI.getDirectorVoice())end}}
