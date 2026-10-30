local core,world,I=require('openmw.core'),require('openmw.world'),require('openmw.interfaces')
local t=0
return {engineHandlers={onUpdate=function(dt)
 t=t+dt;if t<3 then return end
 local ok,e=pcall(function()
 assert(core.contentFiles.has('Dreamforged-Delve.esp'),'plugin missing')
 assert(I.AshenLoot.getState().version==35,'wrong installed script version')
 local d=I.AshenLoot.delve.test.data()
 assert(d.portalSpell and core.magic.spells.records[d.portalSpell].alwaysSucceedFlag,'installed portal not initialized')
 print('[DELVE INSTALLED] ALL PASS actual configured release and Isowind load together')
 end)
 if not ok then print('[DELVE INSTALLED] FAIL '..tostring(e)) end
 core.quit()
end}}
