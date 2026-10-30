-- Pure rules shared by runtime and offline checks.
local M={hub='Seyda Neen, Shrine of the Unending Dream',bossEvery=3}
function M.isFloor(cell)
    return cell and not cell.isExterior and (cell.name or ''):match('^Dreamforged Depth %d%d$')~=nil
end
function M.theme(depth) return math.floor((depth-1)/3)%4+1 end
function M.layout(depth) return (depth-1)%12+1 end
function M.boss(depth) return depth%M.bossEvery==0 end
function M.scaling(depth) return 1+0.08*(depth-1),1+0.04*(depth-1),1+0.05*(depth-1) end
return M
