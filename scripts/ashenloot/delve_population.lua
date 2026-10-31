-- Connected authored tiles supply broad pockets; physics/view validation is still mandatory.
local M={}
local function distance(a,b)local x,y=a[1]-b[1],a[2]-b[2];return math.sqrt(x*x+y*y)end
function M.points(layout)
    local tiles={};for _,t in ipairs(layout.tiles)do tiles[t[1]..','..t[2]]=true end
    local groups={};for i in ipairs(layout.anchors)do groups[i]={}end
    for _,t in ipairs(layout.tiles)do
        local open=true
        for dx=-1,1 do for dy=-1,1 do if not tiles[(t[1]+dx)..','..(t[2]+dy)]then open=false end end end
        local p={t[1]*512+256,t[2]*512+256,8}
        if open and distance(p,layout.entry)>=2400 and distance(p,layout.exit)>=1100 then
            local group,best=1,math.huge
            for i,a in ipairs(layout.anchors)do local d=distance(p,a);if d<best then best=d;group=i end end
            groups[group][#groups[group]+1]={p=p,d=best}
        end
    end
    for _,g in ipairs(groups)do table.sort(g,function(a,b)if a.d~=b.d then return a.d<b.d end;return a.p[1]*100000+a.p[2]<b.p[1]*100000+b.p[2]end)end
    local result={}
    for n=1,16 do for _,g in ipairs(groups)do if g[n]then result[#result+1]=g[n].p end end end
    return result
end
return M
