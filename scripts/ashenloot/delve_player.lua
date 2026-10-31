local core,self,types=require('openmw.core'),require('openmw.self'),require('openmw.types')
local ui,util,async=require('openmw.ui'),require('openmw.util'),require('openmw.async')
local nearby,camera,I=require('openmw.nearby'),require('openmw.camera'),require('openmw.interfaces')
local input=require('openmw.input')
local R=require('scripts.ashenloot.rules')
local View=require('scripts.ashenloot.delve_view')
local Navigation=require('scripts.ashenloot.delve_navigation')
local window,groundRequest,anchorRequest,populationRequest
local function close()
    if window then window:destroy();window=nil end
    if I.UI.getMode()==I.UI.MODE.Interface then I.UI.removeMode(I.UI.MODE.Interface) end
end
local function text(s,color)
    return {type=ui.TYPE.Text,template=I.MWUI.templates.textNormal,
        props={text=s,textColor=color or util.color.rgb(0.9,0.86,0.77)}}
end
local function lines(out,s)
    local row=''
    for word in s:gmatch('%S+') do
        if #row+#word>68 then out[#out+1]=text(row);row='' end
        row=row=='' and word or row..' '..word
    end
    if row~='' then out[#out+1]=text(row) end
end
local function action(out,label,fn)
    local item=text(label,util.color.rgb(0.95,0.73,0.3))
    item.events={mouseClick=async:callback(fn)};out[#out+1]=item
end
local function send(action,extra)
    extra=extra or {};extra.player=self;extra.action=action
    core.sendGlobalEvent('Dreamforged_DelveAction',extra)
end
local function panel(e)
    if window then window:destroy() end
    I.UI.addMode(I.UI.MODE.Interface,{windows={}})
    local out={text(e.title,util.color.rgb(1,0.85,0.4))};lines(out,e.text)
    if e.kind=='intro' then
        action(out,'Take me to the refuge',function() send('enter');close() end)
    elseif e.kind=='shop' then
        out[#out+1]=text('Coins: '..table.concat(e.coins,' / ')..'  (Common through Relic)')
        for _,offer in ipairs(e.offers) do
            out[#out+1]=text(' ')
            lines(out,offer.name)
            -- Names plus mechanical details let the player inspect before buying.
            for i=1,math.min(2,#offer.details) do lines(out,offer.details[i]) end
            action(out,'Inspect',function()
                local detail={title=offer.name,kind='inspect',text=table.concat(offer.details,'\n'),back=e}
                panel(detail)
            end)
            if offer.sold then out[#out+1]=text('Sold')
            else
                local index,epoch=offer.index,e.epoch
                action(out,'Buy - '..offer.price..' '..R.rarities[offer.tier].name..' coins',function() send('buy',{index=index,epoch=epoch}) end)
            end
        end
        action(out,'Begin a new run...',function()
            panel({title='Let the old Dream fade?',kind='confirm',text='This clears the previous descent and starts again at depth 1. Your carried equipment and forging coins remain. The broker does not refresh.'})
        end)
    elseif e.kind=='confirm' then action(out,'Confirm new run',function() send('newRun',{confirm=true});close() end)
    elseif e.kind=='inspect' then action(out,'Back to broker',function() panel(e.back) end) end
    action(out,'Close',close)
    window=ui.create{layer='Windows',template=I.MWUI.templates.boxTransparent,
        props={relativePosition=util.vector2(0.5,0.5),anchor=util.vector2(0.5,0.5)},
        content=ui.content{{type=ui.TYPE.Flex,content=ui.content(out)}}}
end
local function validateAnchor(e)
    if e.cell and e.cell~=self.cell.name then
        core.sendGlobalEvent('Dreamforged_DelveAnchor',{player=self,token=e.token,depth=e.depth,clear=false,reason='player left floor'})
        return
    end
    local view=e.view
    if view and (core.getSimulationTime()-e.snapshotAt>.5 or (self.position-e.snapshotOrigin):length()>160) then view=nil end
    local positions,rejections={},{}
    local reason='no safe formation point';local groundFound,visible,occupied,navStatus=false,false,false,nil
    local navMethod;local agents=Navigation.agents()
    local count=math.min(2,math.max(1,e.count or 1))
    local offsets={{0,0},{320,0},{-320,0},{0,320},{0,-320}}
    for _,offset in ipairs(offsets) do
        local pos=e.position+util.vector3(offset[1],offset[2],0)
        local distance=(pos-self.position):length()
        local ground=nearby.castRay(pos+util.vector3(0,0,150),pos-util.vector3(0,0,150),{collisionType=nearby.COLLISION_TYPE.World})
        local why
        if not view then why='camera unavailable'
        elseif not ground.hit or ground.hitNormal.z<.8 or math.abs(ground.hitPos.z-pos.z)>64 then why='no level ground'
        elseif distance<1800 or distance>4000 then why='outside encounter range'
        else
            groundFound=true;pos=ground.hitPos+util.vector3(0,0,8)
            if View.visible(view,pos+util.vector3(0,0,150),250) then visible=true;why='visible to rendered camera'
            else
                for _,actor in ipairs(nearby.actors) do
                    if actor.enabled and not types.Actor.isDead(actor) and (actor.position-pos):length()<300 then occupied=true;why='occupied';break end
                end
                for _,chosen in ipairs(positions) do if (util.vector3(chosen[1],chosen[2],chosen[3])-pos):length()<300 then why='formation overlap' end end
                if not why and nearby.castRay(pos+util.vector3(0,0,110),pos+util.vector3(0,0,280),
                    {radius=100,collisionType=nearby.COLLISION_TYPE.World+nearby.COLLISION_TYPE.Door}).hit then why='blocked clearance' end
                if not why then
                    local reachable,method,status=Navigation.reachable(self.position,pos,agents)
                    navStatus,navMethod=status,method
                    if not reachable then why=method..' status '..tostring(status) end
                end
            end
        end
        if why then reason=why;rejections[why]=(rejections[why] or 0)+1
        else positions[#positions+1]={pos.x,pos.y,pos.z} end
        if #positions>=count then break end
    end
    core.sendGlobalEvent('Dreamforged_DelveAnchor',{player=self,token=e.token,depth=e.depth,
        clear=#positions>0,reason=#positions>0 and 'safe formation' or reason,positions=positions,
        cell=self.cell.name,origin=self.position,checkedAt=e.snapshotAt,
        ground=groundFound,visible=visible,occupied=occupied,navStatus=navStatus,navMethod=navMethod,rejections=rejections,
        camera=view and {fov=view.fov,baseFov=view.baseFov,mode=view.mode,margin=1.15} or nil})
end
local function validatePopulation(e)
    if not self.cell or self.cell.name~=e.cell then return end
    local started=core.getRealTime();local positions,rejections={},{}
    local agents=Navigation.agents();local methods={}
    for _,a in ipairs(e.points)do
        local pos=util.vector3(a[1],a[2],a[3]);local why
        local ground=nearby.castRay(pos+util.vector3(0,0,150),pos-util.vector3(0,0,150),{collisionType=nearby.COLLISION_TYPE.World})
        if (pos-self.position):length()<1800 then why='near player'
        elseif not ground.hit or ground.hitNormal.z<.8 then why='ground'
        elseif View.visible(e.view,pos+util.vector3(0,0,150),250)then why='visible'
        elseif nearby.castRay(pos+util.vector3(0,0,110),pos+util.vector3(0,0,280),
            {radius=100,collisionType=nearby.COLLISION_TYPE.World+nearby.COLLISION_TYPE.Door}).hit then why='clearance'
        else
            for _,actor in ipairs(nearby.actors)do
                if actor.enabled and not types.Actor.isDead(actor) and (actor.position-pos):length()<400 then why='occupied';break end
            end
            if not why then
                local reachable,method=Navigation.reachable(self.position,pos,agents);methods[method]=(methods[method]or 0)+1
                if not reachable then why='route' end
            end
        end
        if why then rejections[why]=(rejections[why]or 0)+1
        else positions[#positions+1]={ground.hitPos.x,ground.hitPos.y,ground.hitPos.z+8}end
    end
    core.sendGlobalEvent('Dreamforged_DelvePopulation',{player=self,token=e.token,depth=e.depth,cell=e.cell,
        origin=e.origin,checkedAt=e.at,positions=positions,
        metrics={ms=(core.getRealTime()-started)*1000,methods=methods,rejections=rejections}})
end
return {engineHandlers={
    onFrame=function()
        if populationRequest then local e=populationRequest;populationRequest=nil;validatePopulation(e)end
        if window and I.UI.getMode()~=I.UI.MODE.Interface then window:destroy();window=nil end
        if groundRequest then
            local e=groundRequest;groundRequest=nil
            if self.cell.isExterior then
                -- Select a flat, unobstructed patch close to the road, sampling
                -- the exact NPC location rather than offsetting it from a gate.
                for _,offset in ipairs({{0,0},{-250,-250},{250,-250},{-500,-500},{0,-650},{500,-500}}) do
                    local pos=e.position+util.vector3(offset[1],offset[2],0)
                    local hit=nearby.castRay(pos+util.vector3(0,0,4000),pos-util.vector3(0,0,4000),
                        {collisionType=nearby.COLLISION_TYPE.HeightMap})
                    if hit.hit and hit.hitNormal.z>0.93 and hit.hitPos.z>20 then
                        local clear=not nearby.castRay(hit.hitPos+util.vector3(0,0,65),hit.hitPos+util.vector3(0,0,200),
                            {radius=55,collisionType=nearby.COLLISION_TYPE.World+nearby.COLLISION_TYPE.Door}) .hit
                        if clear then core.sendGlobalEvent('Dreamforged_DelveEntrance',{player=self,position=hit.hitPos});break end
                    end
                end
            end
        end
        if anchorRequest then
            local e=anchorRequest;anchorRequest=nil
            validateAnchor(e)
        end
    end,
    onKeyPress=function(e) if window and e.code==input.KEY.Escape then close() end end,
},eventHandlers={Dreamforged_DelvePanel=panel,
    Dreamforged_DelveGroundEntrance=function(e) groundRequest=e end,
    Dreamforged_DelveCheckAnchor=function(e)
        e.view=View.capture();e.snapshotAt=core.getSimulationTime();e.snapshotOrigin=self.position;anchorRequest=e
    end,
    Dreamforged_DelvePopulation=function(e)
        e.view=View.capture();e.at=core.getSimulationTime();e.origin=self.position;populationRequest=e
    end}}
