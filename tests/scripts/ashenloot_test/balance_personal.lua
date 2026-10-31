local core,world,I,types=require('openmw.core'),require('openmw.world'),require('openmw.interfaces'),require('openmw.types')
local C=require('scripts.ashenloot.config');local json=require('scripts.ashenloot_test.balance_json')
local done=false
return{engineHandlers={onUpdate=function()
 if done or not world.players[1]or not I.AshenLoot then return end;done=true
 local ok,e=pcall(function()
  local A=I.AshenLoot;local p=world.players[1];local s=A.getState();local hp=types.Actor.stats.dynamic.health(p)
  local cfg={};for _,k in ipairs({'preset','eliteChance','normalDropChance','enemyHealth','enemyDamage','levelScaling','gearLevelInfluence','encounterDensity','directorIntensity','uniquePercent','eliteTierPercent','healingPercent','supplyPercent','ammunitionPercent','spellTomePercent','adaptiveLootDirector','lootDirectorStrength','lootDirectorReserve','lootDirectorSpreeChance','maxGeneratedItems'})do cfg[k]=C[k]end
  local inventory,tiers,equipped=0,{},{}
  for _,item in ipairs(types.Actor.inventory(p):getAll())do local meta=s.records[item.recordId];if meta then local tier=meta.mythic and 7 or meta.tier;inventory=inventory+item.count;tiers[tier]=(tiers[tier]or 0)+item.count end end
  for _,item in pairs(types.Actor.getEquipment(p))do local m=s.records[item.recordId];if m then equipped[#equipped+1]={tier=m.mythic and 7 or m.tier,level=m.level or m.dropLevel,baseQualityTier=m.baseQualityTier}end end
  local recordEntries=0;for _ in pairs(s.records)do recordEntries=recordEntries+1 end
  print('[BALANCE PERSONAL] '..json({level=types.Actor.stats.level(p).current,gearLevel=A.progression.gearLevel(),damage=A.progression.test.damageProfile(),health={base=hp.base,modifier=hp.modifier,current=hp.current},generatedRecordCount=s.count,recordEntries=recordEntries,generatedInventory=inventory,inventoryTiers=tiers,equipped=equipped,depth=s.delve and s.delve.depth,runBaseline=s.delve and s.delve.baseline,settings=cfg,rewardDirector=s.rewardDirector}))
  print('[BALANCE PERSONAL] ALL PASS isolated-copy readout');core.quit()
 end)
 if not ok then print('[BALANCE PERSONAL] FAIL '..tostring(e));core.quit()end
end}}
