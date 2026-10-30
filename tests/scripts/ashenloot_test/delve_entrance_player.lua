local core,types=require('openmw.core'),require('openmw.types')
return {eventHandlers={DelveEntrance_CheckGround=function(e)
 core.sendGlobalEvent('DelveEntrance_GroundResult',{grounded=types.Actor.isOnGround(e.actor)})
end}}
