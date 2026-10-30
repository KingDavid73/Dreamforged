local core,world,types,I,util=require('openmw.core'),require('openmw.world'),require('openmw.types'),require('openmw.interfaces'),require('openmw.util')
local time,stage,grounded=0,0,nil
return {engineHandlers={onUpdate=function(dt)
 time=time+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local ok,err=pcall(function()
  local D=I.AshenLoot.delve;local d=D.test.data()
  if stage==0 and time>2 then p:teleport('',util.vector3(-7500,-68500,700),{onGround=true});stage=1
  elseif stage==1 and time>7 and d.entranceVersion==2 then
   assert(#d.entrance==1 and d.entrance[1].recordId=='df_delve_attendant','Entrance is not NPC-only')
   local npc=d.entrance[1];assert(math.abs(npc.position.z-d.entrancePosition.z)<40,'Herald buried/floating against sampled terrain')
   if grounded==nil then p:sendEvent('DelveEntrance_CheckGround',{actor=npc});return end
   assert(grounded,'Herald is not standing on collision ground')
   print('[DELVE ENTRANCE] PASS NPC-only entrance, terrain height and grounded actor')
   -- Simulate an old saved gate, then verify migration removes it rather than spawning a duplicate.
   local old=world.createObject('df_delve_enter',1);old:teleport(p.cell,p.position)
   d.entrance[#d.entrance+1]=old;d.entranceVersion=1;stage=2
  elseif stage==2 and time>11 and d.entranceVersion==2 then
   assert(#d.entrance==1,'Old gate migration retained gate objects')
   print('[DELVE ENTRANCE] PASS legacy gateway migration')
   p:teleport('',d.entrancePosition+util.vector3(100,0,20));stage=3
  elseif stage==3 and time>13 then
   D.action{player=p,action='enter'};stage=4
  elseif stage==4 and time>16 then
   assert(p.cell.name=='Seyda Neen, Shrine of the Unending Dream','Herald transport failed')
   assert(types.Player.quests(p)['df_unending_dream'].stage>=20,'Herald quest entry missing')
   print('[DELVE ENTRANCE] ALL PASS NPC transport and quest');core.quit()
  elseif time>40 then error('Entrance test timed out at stage '..stage) end
 end)
 if not ok then print('[DELVE ENTRANCE] FAIL '..tostring(err));core.quit() end
end},eventHandlers={DelveEntrance_GroundResult=function(e)grounded=e.grounded end}}
