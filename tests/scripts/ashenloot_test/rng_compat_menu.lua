local core,menu=require('openmw.core'),require('openmw.menu');local pending,t=false,0
return{eventHandlers={Rng_SaveFixture=function()
 menu.saveGame('RNG compatibility fixture','rng-compat.omwsave');pending=true;t=0
end},engineHandlers={onFrame=function(dt)
 if pending then t=t+dt;if t>2 then print('[RNG COMPAT] OLD FIXTURE SAVED');core.quit();pending=false end end
end}}
