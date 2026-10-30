local core,world,types=require('openmw.core'),require('openmw.world'),require('openmw.types')
local done=false
return {engineHandlers={onUpdate=function()
 if done or not world.players[1] then return end;done=true
 local ids={'rat','kwama forager','nix-hound','alit','skeleton','ancestral ghost','bonelord','centurion_spider','centurion_sphere','centurion_steam','scamp','clannfear','dremora','kagouti','bonewalker greater','daedroth'}
 for _,id in ipairs(ids) do
  local r=types.Creature.records[id]
  print('[ENEMY DIAG] '..id..' exists='..tostring(r~=nil)..' script='..tostring(r and r.mwscript)..' essential='..tostring(r and r.isEssential))
 end
 for _,r in pairs(types.Creature.records) do
  if not r.mwscript and not r.isEssential and r.canWalk and require('openmw.interfaces').AshenLoot.progression.test.safeRecord(r) then
   print('[ENEMY DIAG] first fallback='..r.id..' name='..r.name);break
  end
 end
 print('[ENEMY DIAG] COMPLETE');core.quit()
end}}
