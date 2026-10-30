local core,self,nearby,util=require('openmw.core'),require('openmw.self'),require('openmw.nearby'),require('openmw.util')
local sent=false
local checked={}
return {engineHandlers={onFrame=function()
 local I=require('openmw.interfaces');if I.UI.getMode()==I.UI.MODE.Interface then I.UI.removeMode(I.UI.MODE.Interface) end
end,onUpdate=function()
 local layouts=require('scripts.ashenloot.delve_layouts')
 for _,l in ipairs(layouts) do
  if self.cell.name==l.name and not checked[l.name] then
   local status=nearby.findPath(self.position,util.vector3(l.exit[1],l.exit[2],l.exit[3]),{agentBounds=require('openmw.types').Actor.getPathfindingAgentBounds(self),includeFlags=nearby.NAVIGATOR_FLAGS.Walk})
   if status==nearby.FIND_PATH_STATUS.Success then checked[l.name]=true;print('[DELVE NAV] PASS '..l.name..' stairs connected') end
  end
 end
 if self.cell.name=='Dreamforged Depth 01' and not sent then
  local hit=nearby.castRay(self.position+util.vector3(0,0,100),self.position-util.vector3(0,0,200))
  core.sendGlobalEvent('DelveTest_Collision',{hit=hit.hit});sent=true
 end
end}}
