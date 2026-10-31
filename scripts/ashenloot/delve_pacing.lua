-- Dungeon-only pacing. Time and observations are supplied by the running world.
local M={floorCap=48,incomingCap=6,nearRadius=1800,promotionCap=2}
function M.ambientTarget(depth)return math.min(32,24+math.floor((depth-1)/6)*2)end
function M.new(now)return {phase='build',phaseAt=now,intensity=0,lastAt=now,kills=0,damage=0}end
local function phase(s,name,now,reason)
    s.phase=name;s.phaseAt=now;s.reason=reason
    s.history=s.history or {};s.history[#s.history+1]={phase=name,at=now,reason=reason}
    if #s.history>32 then table.remove(s.history,1)end
    if name=='relax' then s.untilTime=now+25 end
end
function M.step(s,now,o)
    local dt=math.max(0,math.min(2,now-(s.lastAt or now)));s.lastAt=now
    s.damage=math.max(0,(s.damage or 0)-dt*.02)+(o.loss or 0)
    s.kills=math.max(0,(s.kills or 0)-dt*.2)+(o.kills or 0)
    local fighting=o.nearby>0 or o.incoming>0 or (o.combat or 0)>0
    s.intensity=math.min(100,math.max(0,(s.intensity or 0)-dt*(fighting and 1 or 6))
        +(o.loss or 0)*180+(o.kills or 0)*5+dt*(o.nearby*.5+(o.combat or 0)*.5))
    local stressed=o.health<.35 or s.damage>=.18
    if stressed then
        if s.phase~='fade' and s.phase~='relax' then phase(s,'fade',now,'Player needs recovery') end
        if s.phase=='relax' then s.untilTime=math.max(s.untilTime or 0,now+5)end
    end
    if s.phase=='build' and (s.intensity>=65 or o.nearby>=8 or now-s.phaseAt>=45)then
        phase(s,'peak',now,'Sustaining encounter peak')
    elseif s.phase=='peak' and (now-s.phaseAt>=8 or stressed)then
        phase(s,'fade',now,'Let existing threats resolve')
    elseif s.phase=='fade' and o.nearby<=2 and o.incoming==0 then
        phase(s,'relax',now,'Quiet recovery window')
    elseif s.phase=='relax' and not stressed and now>=(s.untilTime or 0)then
        phase(s,'build',now,'Building the next encounter')
    end
    local cap=s.phase=='peak' and 12 or 8
    s.nearbyCap=cap;s.nearby=o.nearby;s.incoming=o.incoming;s.health=o.health
    s.blocked=stressed or s.phase=='fade' or s.phase=='relax'
    return not s.blocked,cap
end
function M.capacity(s,alive,nearby,incoming,reinforcements)
    return math.max(0,math.min(2,M.floorCap-alive,(s.nearbyCap or 8)-nearby-incoming,M.incomingCap-(reinforcements or incoming)))
end
return M
