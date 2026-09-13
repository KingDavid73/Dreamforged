-- One-shot local ground probe for generated loot. OpenMW 0.51 exposes the
-- nearby/physics API to local scripts, while object teleportation remains a
-- global-script operation.
local core=require('openmw.core')
local self=require('openmw.self')
local nearby=require('openmw.nearby')
local util=require('openmw.util')

local elapsed,done=0,false

local function findGround(pos)
    local collision=nearby.COLLISION_TYPE.World+nearby.COLLISION_TYPE.HeightMap
    -- The high probe handles exterior slopes; the lower retry avoids an
    -- interior ceiling masking the floor. Reject near-vertical wall hits.
    for _,probe in ipairs({{512,512},{128,1024}}) do
        local hit=nearby.castRay(pos+util.vector3(0,0,probe[1]),
            pos-util.vector3(0,0,probe[2]),{collisionType=collision})
        if hit and hit.hit and hit.hitPos
            and (not hit.hitNormal or hit.hitNormal.z>=0.20) then
            return hit.hitPos
        end
    end
end

return {
    engineHandlers={onUpdate=function(dt)
        if done or not self:isActive() then return end
        elapsed=elapsed+dt
        -- Wait one frame for the global teleport to become visible locally.
        if elapsed<0.05 then return end
        done=true
        local position=findGround(self.position)
        if position then position=position+util.vector3(0,0,8) end
        core.sendGlobalEvent('AshenLoot_AlignGroundDropResult',
            {id=self.id,position=position})
    end},
}
