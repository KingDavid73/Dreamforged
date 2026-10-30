-- Explicit encounter ownership. Ordinary interiors retain their location/actor
-- eligibility checks; generated floors never inherit those legacy spawn paths.
local M={hub='Seyda Neen, Shrine of the Unending Dream'}
local floors={}
for _,layout in ipairs(require('scripts.ashenloot.delve_layouts'))do floors[layout.name]=true end
local policies={
    wilderness={id='wilderness',label='Wilderness',progression=true,outdoor=true,randomBosses=true,legacyBossAdds=true,replacement=true},
    interior_hostile={id='interior_hostile',label='Hostile interior',progression=true,interiorPacks=true,interiorBoss=true,randomBosses=true,legacyBossAdds=true,rerunInterior=true,replacement=true},
    interior_safe={id='interior_safe',label='Safe interior',progression=true},
    delve={id='delve',label='Generated dungeon',progression=true,dungeonDirector=true,scheduledGuardian=true},
    refuge={id='refuge',label='Refuge'},
    unknown={id='unknown',label='Unknown location'},
}
function M.kind(cell)
    if not cell then return 'unknown' end
    if cell.isExterior then return 'wilderness' end
    if cell.name==M.hub then return 'refuge' end
    if floors[cell.name] then return 'delve' end
    return 'interior'
end
function M.get(cell,hostileInterior)
    local kind=M.kind(cell)
    if kind=='interior' then return policies[hostileInterior and 'interior_hostile' or 'interior_safe'] end
    return policies[kind]
end
return M
