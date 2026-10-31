local core,world,I=require('openmw.core'),require('openmw.world'),require('openmw.interfaces')
local N=require('scripts.ashenloot.narration');local storage,C=require('openmw.storage'),require('scripts.ashenloot.config')
local t,stage,at,heard=0,0,0,nil
return{engineHandlers={onUpdate=function(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local ok,e=pcall(function()
  local now=core.getSimulationTime()
  if stage==0 and t>3 then
   storage.globalSection(C.groupKey('directorVoiceFrequency')):set('directorVoiceFrequency',100)
   assert(N.render('sleep','fixture',nil,nil,'refuge').speaker=='Fa-Nuit-Hen','refuge rest escaped patron context')
   assert(not N.emitPressure({},C,p,now,100,3),'pressure leaked into refuge')
   assert(N.emit({},C,p,now,'sleep',nil,true),'actual refuge rest event failed')
   stage=1;at=t+1
  elseif stage==1 and t>at then
   assert(heard and heard.speaker=='Fa-Nuit-Hen','actual refuge rest speaker incorrect')
   p:sendEvent('Patron_Report',{});stage=2
  end
 end)
 if not ok then print('[PATRON REFUGE] FAIL '..tostring(e));core.quit()end
end},eventHandlers={Patron_Heard=function(e)heard=e end,Patron_Report=function(e)
 if not(e.visible and e.message and e.message.speaker=='Fa-Nuit-Hen')then print('[PATRON REFUGE] FAIL caption card')else print('[PATRON REFUGE] ALL PASS configured release routes refuge rest to patron, blocks outdoor pressure and renders actual card')end
 core.quit()
end}}
