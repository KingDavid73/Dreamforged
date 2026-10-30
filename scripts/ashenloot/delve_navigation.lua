-- Prefer registered scene agents: the player-sized mesh can be absent indoors.
-- With no mesh, the generated floor's graph must pass physical route checks.
local nearby,types,self,util=require('openmw.nearby'),require('openmw.types'),require('openmw.self'),require('openmw.util')
local layouts=require('scripts.ashenloot.delve_layouts')
local M={};local maps={}
local function key(x,y)return x..','..y end
function M.agents()
    local result,seen={},{}
    for _,actor in ipairs(nearby.actors) do
        if actor:isValid() and actor.enabled and actor.cell and actor.cell.name==self.cell.name and actor.recordId~='player' then
            local bounds=types.Actor.getPathfindingAgentBounds(actor)
            local id=tostring(bounds.shapeType)..':'..tostring(bounds.halfExtents)
            if not seen[id] then seen[id]=true;result[#result+1]={bounds=bounds,id=actor.recordId,size=bounds.halfExtents:length()} end
        end
    end
    table.sort(result,function(a,b)return a.size>b.size end)
    result[#result+1]={bounds=types.Actor.getPathfindingAgentBounds(self),id='player'}
    return result
end
local function graphRoute(start,finish)
    if math.abs(start.z)>128 or math.abs(finish.z)>64 then return false end
    local name=self.cell.name;local tiles=maps[name]
    if not tiles then
        for _,layout in ipairs(layouts) do if layout.name==name and layout.tiles then
            tiles={};for _,t in ipairs(layout.tiles)do tiles[key(t[1],t[2])]=t end;maps[name]=tiles;break
        end end
    end
    if not tiles then return false end
    local from=key(math.floor(start.x/512),math.floor(start.y/512))
    local goal=key(math.floor(finish.x/512),math.floor(finish.y/512))
    if not tiles[from] or not tiles[goal] then return false end
    local blocked={}
    for attempt=1,4 do
        local queue,parents,head={from},{[from]=false},1
        while head<=#queue and parents[goal]==nil do
            local current=queue[head];head=head+1;local t=tiles[current]
            for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
                local nextKey=key(t[1]+d[1],t[2]+d[2])
                if tiles[nextKey] and parents[nextKey]==nil and not blocked[current..'>'..nextKey] then parents[nextKey]=current;queue[#queue+1]=nextKey end
            end
        end
        if parents[goal]==nil then return false end
        local route={};local current=goal
        while current do table.insert(route,1,current);current=parents[current] end
        local points={start}
        for _,k in ipairs(route)do local t=tiles[k];points[#points+1]=util.vector3(t[1]*512+256,t[2]*512+256,8)end
        points[#points+1]=finish
        local obstruction
        for i=1,#points-1 do
            if (points[i+1]-points[i]):length()>1 and nearby.castRay(points[i]+util.vector3(0,0,120),points[i+1]+util.vector3(0,0,120),{radius=100,collisionType=nearby.COLLISION_TYPE.World+nearby.COLLISION_TYPE.Door}).hit then obstruction=i;break end
        end
        if not obstruction then return true end
        if obstruction==1 or obstruction==#points-1 then return false end
        local a,b=route[obstruction-1],route[obstruction]
        blocked[a..'>'..b]=true;blocked[b..'>'..a]=true
    end
    return false
end
function M.reachable(start,finish,agents)
    local allMissing=true;local lastStatus
    for _,agent in ipairs(agents) do
        local status=nearby.findPath(start,finish,{agentBounds=agent.bounds,includeFlags=nearby.NAVIGATOR_FLAGS.Walk})
        lastStatus=tostring(status)
        if status==nearby.FIND_PATH_STATUS.Success then return true,'registered agent '..agent.id,lastStatus end
        if status~=nearby.FIND_PATH_STATUS.NavMeshNotFound then allMissing=false end
    end
    if allMissing then return graphRoute(start,finish),'authored route',lastStatus end
    return false,'navmesh path rejected',lastStatus
end
return M
