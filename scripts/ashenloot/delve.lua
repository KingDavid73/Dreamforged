-- The Unending Dream. All persistent data lives in AshenLoot's saved state.
local core,world,types=require('openmw.core'),require('openmw.world'),require('openmw.types')
local util,I=require('openmw.util'),require('openmw.interfaces')
local C,R=require('scripts.ashenloot.config'),require('scripts.ashenloot.rules')
local Rules=require('scripts.ashenloot.delve_rules')
local layouts=require('scripts.ashenloot.delve_layouts')
local M={};local state,api,elapsed,lastCell,travelAt= nil,nil,0,nil,-100
local registered=false
local script='scripts/ashenloot/actor.lua'
local entrance={-7500,-68000,500}
local Selection=require('scripts.ashenloot.delve_selection')
local selectionVersion=2
local selectEnemy=Selection.choose
local function vec(p) return util.vector3(p[1],p[2],p[3]) end
local function live(o) return o and o:isValid() end
local function data()
    state.delve=state.delve or {version=1,serial=0,depth=0,bosses=0,slots={},actors={},offeredEpoch=-1}
    return state.delve
end
local function tell(p,message) p:sendEvent('AshenLoot_ForgeResult',{message=message}) end
local function journal(p,stage)
    local q=types.Player.quests(p)['df_unending_dream']
    if q.stage<stage then q:addJournalEntry(stage) end
end
local function hub(p) p:teleport(Rules.hub,util.vector3(0,0,8),{rotation=util.transform.rotateZ(0),onGround=true}) end
local function spell(p)
    local d=data()
    if not d.portalSpell then
        d.portalSpell=world.createRecord(core.magic.spells.createRecordDraft{
            name='Dream Portal',type=core.magic.SPELL_TYPE.Spell,cost=0,isAutocalc=false,alwaysSucceedFlag=true,
            effects={{id='detectkey',range=core.magic.RANGE.Self,magnitudeMin=1,magnitudeMax=1,duration=3,area=0}}}).id
    end
    if not types.Actor.spells(p)[d.portalSpell] then types.Actor.spells(p):add(d.portalSpell) end
end
local function tierCoins(p)
    state.forgePoints=state.forgePoints or {};state.forgePoints[p.id]=state.forgePoints[p.id] or {0,0,0,0,0,0}
    return state.forgePoints[p.id]
end
local function shop(p)
    local d=data();local epoch=d.bosses or 0
    if d.offeredEpoch~=epoch then
        if live(d.escrow) then d.escrow:remove() end
        d.escrow=world.createObject('df_delve_escrow',1);d.offers={}
        local inv=types.Container.content(d.escrow)
        local tiers={3,4,5}
        for i,tier in ipairs(tiers) do
            local id=api.giveLoot(p,'delve-shop:'..p.id..':'..epoch..':'..i,tier,nil,tier,nil,inv)
            if id then
                local item=inv:find(id)
                d.offers[#d.offers+1]={id=id,item=item,tier=tier,price=8,sold=false}
            end
        end
        d.offeredEpoch=epoch
    end
    local offers={}
    for i,o in ipairs(d.offers or {}) do
        local meta=state.records[o.id]
        offers[#offers+1]={index=i,name=meta and meta.name or o.id,tier=o.tier,price=o.price,
            details=meta and meta.details or {},sold=o.sold}
    end
    p:sendEvent('Dreamforged_DelvePanel',{title='Velyna, Broker of Dreams',kind='shop',epoch=epoch,
        text='Gold has no purchase here. Salvage generated gear in your Forge to earn coins. Stock changes only after a dungeon World Boss victory.',
        offers=offers,coins=tierCoins(p)})
end
local function context(actor)
    local d=state.delve
    return d and d.actors and d.actors[actor.id]
end
function M.context(actor) return context(actor) end
local function currentSlot(p)
    local d=data()
    for index,l in ipairs(layouts) do
        local slot=d.slots[index]
        if slot and p.cell and p.cell.name==l.name then return slot,index end
    end
end
local function spawn(slot,index,anchor,boss,healthFraction)
    local d=data();local l=layouts[index];slot.serial=(slot.serial or 0)+1
    local rng=R.rng(d.serial..':'..slot.depth..':'..slot.serial)
    -- Adjacent short seeds have correlated first draws; mix before choosing a species.
    rng(997);rng(7919)
    local _,archetype=selectEnemy(l.theme,boss,rng,slot.depth)
    local id=Selection.recordId(archetype)
    local actor=world.createObject(id,1)
    local target=math.max(1,math.floor(d.baseline+(slot.depth-1)*1.25))
    local info={depth=slot.depth,index=index,level=target,boss=boss or false,selectionVersion=selectionVersion,
        archetypeLevel=archetype.level,optionalArchetype=archetype.optional,archetypeSource=archetype.id}
    d.actors[actor.id]=info
    slot.objects[#slot.objects+1]=actor
    slot.ids=slot.ids or {};slot.ids[#slot.ids+1]=actor.id
    if boss then slot.boss=actor end
    state.director.generated[actor.id]='delve'
    state.director.spawnLevels[actor.id]=target
    -- Attach before teleport so activation cannot race progression preparation.
    if not actor:hasScript(script) then actor:addScript(script) end
    actor:teleport(l.name,vec(anchor),{onGround=true})
    -- Start passive until the player approaches, rather than aggroing the entire floor.
    actor:sendEvent('Dreamforged_DelveSpawned',{healthFraction=healthFraction})
    print('[Dreamforged Delve] selected '..id..' ('..archetype.id..') depth '..slot.depth..(boss and ' guardian' or ' ordinary'))
    return actor
end
local function forgetActor(id)
    data().actors[id]=nil
    for _,key in ipairs({'generated','spawnLevels','actors','directorCosts','promotionBonuses','bossAdds','supplies','npcLoot','specialActors'}) do state.director[key][id]=nil end
    state.elites[id]=nil;state.rewards[id]=nil
end
local function migrateSelection(slot,index)
    if slot.selectionVersion==selectionVersion then return end
    local replaced=0
    for i=1,#slot.objects do
        local old=slot.objects[i]
        local info=live(old) and context(old)
        if info and info.selectionVersion~=selectionVersion and not types.Actor.isDead(old) then
            local hp=types.Actor.stats.dynamic.health(old)
            local maximum=hp.base+hp.modifier
            local fraction=maximum>0 and math.max(0.01,math.min(1,hp.current/maximum)) or 1
            local pos=old.position
            local actor=spawn(slot,index,{pos.x,pos.y,pos.z},info.boss and not slot.bossDefeated,fraction)
            -- spawn appends; replace the original entry without changing population.
            slot.objects[#slot.objects]=nil;slot.ids[#slot.ids]=nil
            slot.objects[i]=actor;slot.ids[i]=actor.id
            local oldId=old.id;old:remove();forgetActor(oldId);replaced=replaced+1
        end
    end
    slot.selectionVersion=selectionVersion
    if replaced>0 then print('[Dreamforged Delve] repaired '..replaced..' saved enemies at depth '..slot.depth) end
end
local function cleanup(slot)
    local d=data()
    -- Remove only unclaimed ground rewards from the slot being recycled.
    -- Carried/stashed items have a parent container and must survive every reset.
    local cellName=slot.cell
    for id,loose in pairs(state.director.loose or {}) do
        local item=type(loose)=='table' and loose.item
        if live(item) and not item.parentContainer and item.cell and item.cell.name==cellName then
            item:remove()
            if live(loose.light) then loose.light:remove() end
            state.director.loose[id]=nil
        end
    end
    for i,o in ipairs(slot.objects or {}) do
        local id=slot.ids and slot.ids[i] or (live(o) and o.id)
        if live(o) then o:remove() end
        if id then
            forgetActor(id)
        end
    end
end
local function descend(p)
    if core.getSimulationTime()-travelAt<2 then return end
    travelAt=core.getSimulationTime()
    local d=data();local depth=d.depth+1;local index=Rules.layout(depth)
    local old=d.slots[index]
    if old then cleanup(old) end
    d.depth=depth;d.returnPoint=nil
    if not d.baseline then d.baseline=math.max(1,api.progress.gearLevel());d.serial=d.serial+1 end
    local slot={depth=depth,cell=layouts[index].name,serial=0,objects={},phase='build',nextWave=core.getSimulationTime()+25,
        entered=core.getSimulationTime(),bossDefeated=false}
    d.slots[index]=slot
    p:teleport(layouts[index].name,vec(layouts[index].entry),{onGround=true})
    -- Spawn on the following update, after teleport and collision have committed.
    slot.pendingInitial=true
    journal(p,20);spell(p)
    tell(p,'Depth '..depth..' - '..({'Cave','Ancestral Tomb','Dwemer','Daedric'})[Rules.theme(depth)]
        ..(Rules.boss(depth) and ' | A World Boss guards this depth.' or ''))
end
local function retreat(p)
    local slot=currentSlot(p)
    if not slot then tell(p,'Dream Portal answers only within the Unending Dream.');return end
    local d=data();d.returnPoint={cell=p.cell.name,position=p.position,rotation=p.rotation,depth=slot.depth}
    hub(p)
end
local function resume(p)
    local d=data();local r=d.returnPoint
    local returnSlot=r and d.slots[Rules.layout(r.depth)]
    if r and returnSlot and returnSlot.depth==r.depth then
        p:teleport(r.cell,r.position,{rotation=r.rotation,onGround=true})
        returnSlot.nextWave=core.getSimulationTime()+15
    elseif d.depth>0 then
        local index=Rules.layout(d.depth)
        p:teleport(layouts[index].name,vec(layouts[index].entry),{onGround=true})
        d.slots[index].nextWave=core.getSimulationTime()+15
    else descend(p) end
end
local function nearBroker(p)
    if not p.cell or p.cell.name~=Rules.hub then return false end
    return (p.position-util.vector3(850,200,8)):length()<650
end
function M.action(e)
    local p=e and e.player
    if not live(p) or not types.Player.objectIsInstance(p) then return end
    local d=data()
    if e.action=='enter' and p.cell and p.cell.isExterior and d.entrancePosition
        and (p.position-d.entrancePosition):length()<650 then
        journal(p,10);hub(p);spell(p);journal(p,20)
    elseif e.action=='portal' then retreat(p)
    elseif e.action=='buy' and nearBroker(p) then
        local offer=d.offers and d.offers[tonumber(e.index)]
        if e.epoch~=d.offeredEpoch or not offer or offer.sold or not live(offer.item) then shop(p);return end
        local coins=tierCoins(p)
        if coins[offer.tier]<offer.price then tell(p,'You need '..offer.price..' '..R.rarities[offer.tier].name..' forging coins.');shop(p);return end
        -- Move first: failed transfers never consume currency or mark an offer sold.
        offer.item:moveInto(types.Actor.inventory(p));coins[offer.tier]=coins[offer.tier]-offer.price;offer.sold=true
        d.pendingBaseline=p;api.snapshot(p);shop(p)
    elseif e.action=='newRun' and p.cell and p.cell.name==Rules.hub and e.confirm then
        for _,slot in pairs(d.slots) do cleanup(slot) end
        d.depth=0;d.baseline=nil;d.returnPoint=nil;d.slots={};d.serial=d.serial+1
        tell(p,'The old descent fades. Your equipment and forging coins remain.');hub(p)
    elseif e.action=='shop' and nearBroker(p) then shop(p) end
end
local function activate(o,p)
    if not types.Player.objectIsInstance(p) then return end
    local id=o.recordId
    if id=='df_delve_enter' then journal(p,10);hub(p);spell(p);journal(p,20)
    elseif id=='df_delve_exit' then p:teleport('',vec(entrance)+util.vector3(0,-300,0),{onGround=true})
    elseif id=='df_delve_attendant' then
        journal(p,10)
        p:sendEvent('Dreamforged_DelvePanel',{title='Nerethi, Maelstrom Herald',kind='intro',
            text='I wear this shape for your comfort. I serve Fa-Nuit-Hen, the Multiplier of Motions Known. My patron keeps trials beyond Mundus, where skill is worth more than pedigree. The Unending Dream is one such proving ground. Its caverns and ruins are borrowed shapes, not places beneath Seyda Neen. Every third depth holds a guardian. Keep what you earn; our broker accepts forging coins, not gold. Shall I take you to the refuge? You may return whenever you wish.'})
    elseif id=='df_delve_broker' then shop(p)
    elseif id=='df_delve_resume' then resume(p)
    elseif id=='df_delve_retreat' then retreat(p)
    elseif id=='df_delve_descend' then
        if p.cell.name==Rules.hub then resume(p)
        elseif currentSlot(p) then descend(p) end
    else return end
    return false
end
function M.bind(s,a) state,api=s,a;Selection.bind(data) end
function M.init()
    if registered or not core.contentFiles.has('Dreamforged-Delve.esp') then return end
    registered=true
    I.Activation.addHandlerForType(types.Activator,activate)
    I.Activation.addHandlerForType(types.NPC,activate)
end
function M.update(dt)
    if not core.contentFiles.has('Dreamforged-Delve.esp') then return end
    M.init()
    local saved=data()
    if live(saved.pendingBaseline) then api.refreshBaseline(saved.pendingBaseline);saved.pendingBaseline=nil end
    elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
    local p=world.players[1];if not live(p) or types.Actor.isDead(p) then return end
    local d=data();local now=core.getSimulationTime()
    if d.entrance and d.entranceVersion~=2 then
        for _,o in ipairs(d.entrance) do if live(o) then o:remove() end end
        d.entrance=nil;d.entrancePosition=nil
    end
    if live(d.escrow) then
        for _,o in ipairs(d.offers or {}) do
            if not o.sold and not o.item then o.item=types.Container.content(d.escrow):find(o.id) end
        end
    end
    -- Exterior placement is resolved against the running mod suite's terrain by the player script.
    if not d.entrance and p.cell.isExterior and (p.position-vec(entrance)):length()<12000 then
        p:sendEvent('Dreamforged_DelveGroundEntrance',{position=vec(entrance)})
    end
    if p.cell.name==Rules.hub then spell(p);journal(p,20) end
    if d.portalSpell then
        local active=types.Actor.activeSpells(p)
        if active:isSpellActive(d.portalSpell) then
            for _,s in pairs(active) do if s.id==d.portalSpell then active:remove(s.activeSpellId) end end
            retreat(p)
        end
    end
    local slot,index=currentSlot(p)
    if not slot or not C.enabled then return end
    if lastCell~=p.cell.name then lastCell=p.cell.name;slot.nextWave=now+15 end
    if slot.pendingInitial then
        slot.pendingInitial=nil
        for i=2,math.min(5,#layouts[index].anchors) do spawn(slot,index,layouts[index].anchors[i],false) end
        if Rules.boss(slot.depth) then spawn(slot,index,layouts[index].exit,true) end
        print('[Dreamforged Delve] initial population depth '..slot.depth)
    end
    migrateSelection(slot,index)
    -- Prepare remote actors globally too; custom actor-processing ranges must
    -- not delay a guaranteed guardian's promotion until the player is beside it.
    for _,actor in ipairs(slot.objects) do
        if live(actor) and actor.enabled and not types.Actor.isDead(actor) and not state.director.actors[actor.id] then
            api.progress.prepare(actor,false)
        end
    end
    if live(slot.boss) and types.Actor.isDead(slot.boss) and not slot.bossDefeated then
        slot.bossDefeated=true;d.bosses=d.bosses+1;slot.nextWave=now+35
        if slot.depth>=3 then journal(p,100) end
        tell(p,'The guardian falls. Velyna has new stock. The Dream grants a moment of quiet.')
    end
    -- Boss fights use a bounded add budget; ordinary waves pause during the climax.
    if live(slot.boss) and not types.Actor.isDead(slot.boss) and (slot.boss.position-p.position):length()<1800 then
        if now>=(slot.nextAdds or 0) and (slot.addsMade or 0)<4 then
            slot.nextAdds=now+25
            local anchor=layouts[index].anchors[2]
            -- Same out-of-view and nav validation as ordinary waves.
            slot.request=(slot.request or 0)+1
            slot.pending={token=slot.request,expires=now+5,anchor=anchor,count=1,bossAdd=true}
            p:sendEvent('Dreamforged_DelveCheckAnchor',{token=slot.request,depth=slot.depth,position=vec(anchor)})
        end
        return
    end
    if now<slot.nextWave or not C.extraEncounters then return end
    local alive=0
    for _,o in ipairs(slot.objects) do if live(o) and not types.Actor.isDead(o) then alive=alive+1 end end
    local cap=8
    if alive>=cap then slot.nextWave=now+5;return end
    local options={}
    for _,a in ipairs(layouts[index].anchors) do
        local distance=(vec(a)-p.position):length()
        local occupied=false
        for _,actor in ipairs(slot.objects) do
            if live(actor) and not types.Actor.isDead(actor) and (actor.position-vec(a)):length()<350 then occupied=true;break end
        end
        if not occupied and distance>=1800 and distance<=7000 then options[#options+1]=a end
    end
    if #options==0 then slot.nextWave=now+5;return end
    local rng=R.rng(d.serial..':'..slot.depth..':wave:'..slot.serial..':'..(slot.request or 0))
    local a=options[rng(#options)]
    -- Local ray/nav validation happens before any reinforcement is committed.
    slot.request=(slot.request or 0)+1
    slot.pending={token=slot.request,expires=now+5,anchor=a,count=math.min(2,cap-alive)}
    p:sendEvent('Dreamforged_DelveCheckAnchor',{token=slot.request,depth=slot.depth,position=vec(a)})
    slot.nextWave=now+30
end
function M.anchor(e)
    local p=e and e.player;if not live(p) then return end
    local slot,index=currentSlot(p);if not slot then return end
    local request=slot.pending
    if not request or e.depth~=slot.depth or e.token~=request.token then return end
    slot.pending=nil
    if not e.clear or core.getSimulationTime()>request.expires then
        slot.lastPlacementFailure=e.reason or 'expired';slot.nextWave=core.getSimulationTime()+5;return
    end
    for i=1,request.count do
        local a=request.anchor
        spawn(slot,index,{a[1]+(i-1)*100,a[2],a[3]},false)
    end
    if request.bossAdd then slot.addsMade=(slot.addsMade or 0)+request.count end
    slot.waves=(slot.waves or 0)+1
    print('[Dreamforged Delve] reinforcement wave '..slot.waves..' at depth '..slot.depth)
    if slot.waves%3==0 then slot.nextWave=core.getSimulationTime()+45 end
end
function M.groundEntrance(e)
    local p=e and e.player;if not live(p) or not p.cell.isExterior or not e.position then return end
    local d=data();if d.entrance then return end
    if (e.position-vec(entrance)):length()>4000 then return end
    entrance={e.position.x,e.position.y,e.position.z};d.entrancePosition=e.position
    d.entrance={}
    local npc=world.createObject('df_delve_attendant',1);d.entrance[1]=npc;d.entranceVersion=2
    if not d.heraldAura then
        d.heraldAura=world.createRecord(core.magic.spells.createRecordDraft{
            name='Glimmer of Maelstrom',type=core.magic.SPELL_TYPE.Ability,cost=0,isAutocalc=false,
            effects={{id='light',range=core.magic.RANGE.Self,magnitudeMin=20,magnitudeMax=20,duration=0,area=0}}}).id
    end
    types.Actor.spells(npc):add(d.heraldAura)
    -- Explicit terrain height; onGround snapping was burying the herald on slopes.
    npc:teleport('',e.position+util.vector3(0,0,12))
    print('[Dreamforged Delve] herald placed at '..tostring(e.position))
end
M.test={descend=descend,resume=resume,retreat=retreat,shop=shop,spawn=spawn,data=data,activate=activate,
    selectEnemy=selectEnemy,migrateSelection=migrateSelection,selection=Selection}
return M
