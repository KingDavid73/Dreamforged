local core,self,types=require('openmw.core'),require('openmw.self'),require('openmw.types')
local ui,util,async=require('openmw.ui'),require('openmw.util'),require('openmw.async')
local nearby,camera,I=require('openmw.nearby'),require('openmw.camera'),require('openmw.interfaces')
local input=require('openmw.input')
local R=require('scripts.ashenloot.rules')
local window,groundRequest,anchorRequest
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
local function inView(pos)
    local offset=pos-camera.getPosition()
    local points={util.vector2(0,0),util.vector2(1,0),util.vector2(1,1),util.vector2(0,1)}
    local centre=camera.viewportToWorldVector(util.vector2(0.5,0.5))
    if offset:dot(centre)<=0 then return false end
    for i=1,4 do
        local normal=camera.viewportToWorldVector(points[i]):cross(camera.viewportToWorldVector(points[i%4+1]))
        if offset:dot(normal)*centre:dot(normal)<0 then return false end
    end
    return true
end
return {engineHandlers={
    onFrame=function()
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
            local pos=e.position
            local ground=nearby.castRay(pos+util.vector3(0,0,150),pos-util.vector3(0,0,150),{collisionType=nearby.COLLISION_TYPE.World})
            local clear,reason=false,'no ground'
            if ground.hit then reason='visible to camera' end
            if ground.hit and not inView(pos+util.vector3(0,0,80)) then
                local status=nearby.findPath(self.position,pos,{agentBounds=types.Actor.getPathfindingAgentBounds(self),includeFlags=nearby.NAVIGATOR_FLAGS.Walk})
                clear=status==nearby.FIND_PATH_STATUS.Success
                reason='nav status '..tostring(status)
                for _,actor in ipairs(nearby.actors) do if not types.Actor.isDead(actor) and (actor.position-pos):length()<220 then clear=false;reason='occupied' end end
            end
            core.sendGlobalEvent('Dreamforged_DelveAnchor',{player=self,token=e.token,depth=e.depth,clear=clear,reason=reason})
        end
    end,
    onKeyPress=function(e) if window and e.code==input.KEY.Escape then close() end end,
},eventHandlers={Dreamforged_DelvePanel=panel,
    Dreamforged_DelveGroundEntrance=function(e) groundRequest=e end,
    Dreamforged_DelveCheckAnchor=function(e) anchorRequest=e end}}
