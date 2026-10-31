local core,world,I,types=require('openmw.core'),require('openmw.world'),require('openmw.interfaces'),require('openmw.types')
local storage=require('openmw.storage');local C,R=require('scripts.ashenloot.config'),require('scripts.ashenloot.rules')
local json=require('scripts.ashenloot_test.balance_json')
local stage,t,at,loaded,snapshot,itemIds=0,0,0,false,nil,{}
local function capture(A,p)
 local s=A.getState();local slot=A.delve.test.data().slots[1];local out={records={},items={},actors={},elites={},promotions=slot.promotions}
 for _,item in ipairs(types.Actor.inventory(p):getAll())do if s.records[item.recordId]then out.items[item.id]={record=item.recordId,count=item.count};out.records[item.recordId]=s.records[item.recordId]end end
 for _,a in ipairs(slot.objects)do if a:isValid()and a.count>0 then
  out.actors[a.id]=a.recordId;local e=s.elites[a.id]
  out.elites[a.id]=e and {name=e.name,rank=e.rank,worldBoss=e.worldBoss,modifiers=e.modifiers}or false
 end end
 return json(out)
end
return{engineHandlers={onUpdate=function(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local ok,e=pcall(function()
  local A=I.AshenLoot;local D=A.delve
  if loaded then
   if t>at then
    assert(R.stream,'fixture must be validated with new gameplay streams')
    assert(capture(A,p)==snapshot,'existing item/actor/promotion outcome changed on upgrade')
    print('[RNG COMPAT] ALL PASS old-version item metadata, IDs/counts, inhabitants, rank/name/modifier outcomes and promotion budget unchanged');core.quit();stage=99
   end
   return
  end
  if stage==0 and t>3 then
   storage.globalSection(C.groupKey('directorVoiceFrequency')):set('directorVoiceFrequency',0)
   for tier=3,5 do local id=A.test.giveLoot(p,'rng-old-fixture:'..tier,tier,nil,tier,nil,types.Actor.inventory(p));assert(id,'fixture gear failed');itemIds[#itemIds+1]=id end
   D.test.descend(p);stage=1
  elseif stage==1 then
   local slot=D.test.data().slots[1]
   if slot and slot.population and slot.population.done then
    storage.globalSection(C.groupKey('extraEncounters')):set('extraEncounters',false)
    D.test.cancelPlacement(slot,'compatibility fixture',true);stage=2;at=t+5
   end
  elseif stage==2 and t>at then
   snapshot=capture(A,p);assert(#itemIds==3,'fixture item count')
   stage=3;types.Player.sendMenuEvent(p,'Rng_SaveFixture')
  end
  if t>90 and stage~=99 then error('compatibility fixture timeout')end
 end)
 if not ok then print('[RNG COMPAT] FAIL '..tostring(e));core.quit()end
end,onSave=function()return{snapshot=snapshot,t=t}end,
onLoad=function(v)if v then snapshot=v.snapshot;t=v.t;loaded=true;at=t+5 end end}}
