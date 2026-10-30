-- Pure rules shared by runtime and offline checks.
local Context=require('scripts.ashenloot.encounter_context')
local M={hub=Context.hub,bossEvery=3}
function M.isFloor(cell)
    return Context.kind(cell)=='delve'
end
function M.theme(depth) return math.floor((depth-1)/3)%4+1 end
function M.layout(depth) return (depth-1)%12+1 end
function M.boss(depth) return depth%M.bossEvery==0 end
function M.scaling(depth) return 1+0.08*(depth-1),1+0.04*(depth-1),1+0.05*(depth-1) end
return M
