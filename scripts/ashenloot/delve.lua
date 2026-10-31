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
local Context=require('scripts.ashenloot.encounter_context')
local Pacing=require('scripts.ashenloot.delve_pacing')
local Population=require('scripts.ashenloot.delve_population')
local Narration=require('scripts.ashenloot.narration')
local selectionVersion=2
local bindingGeneration=0
local selectEnemy=Selection.choose
local function vec(p) return util.vector3(p[1],p[2],p[3]) end
local function live(o) return o and o:isValid() end
local function remove(o) if live(o) and o.count>0 then o:remove() end end
local function diagnostic(slot,status,detail)
    slot.diagnostics=slot.diagnostics or {counts={},history={}}
    local d=slot.diagnostics
    d.counts[status]=(d.counts[status] or 0)+1
    if d.status~=status then
        d.history[#d.history+1]={time=core.getSimulationTime(),status=status,detail=detail}
        if #d.history>32 then table.remove(d.history,1) end
    end
    d.status,d.detail=status,detail
    if status=='wave spawned' or status=='batch deferred' or status=='placement cancelled' or status=='initial population' then
        d.lastAction=status..': '..tostring(detail)
    end
end
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
        remove(d.escrow)
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
    if Context.kind(p and p.cell)~='delve' then return end
    local d=data()
    for index,l in ipairs(layouts) do
        local slot=d.slots[index]
        if slot and p.cell and p.cell.name==l.name then return slot,index end
    end
end
local function spawn(slot,index,anchor,boss,healthFraction,reinforcement)
    local d=data();local l=layouts[index];slot.serial=(slot.serial or 0)+1
    local rng=R.stream(d.serial..':'..slot.depth..':'..slot.serial,'delve-species-v1')
    local _,archetype=selectEnemy(l.theme,boss,rng,slot.depth)
    local id=Selection.recordId(archetype)
    local actor=world.createObject(id,1)
    local target=math.max(1,math.floor(d.baseline+(slot.depth-1)*1.25))
    local info={depth=slot.depth,index=index,level=target,boss=boss or false,selectionVersion=selectionVersion,
        archetypeLevel=archetype.level,optionalArchetype=archetype.optional,archetypeSource=archetype.id,reinforcement=reinforcement or false,density=true}
    d.actors[actor.id]=info
    slot.objects[#slot.objects+1]=actor
    slot.ids=slot.ids or {};slot.ids[#slot.ids+1]=actor.id
    if boss then slot.boss=actor end
    state.director.generated[actor.id]='delve'
    state.director.spawnLevels[actor.id]=target
    -- Attach before teleport so activation cannot race progression preparation.
    if not actor:hasScript(script) then actor:addScript(script) end
    actor:teleport(l.name,vec(anchor),{onGround=true})
    -- Ambient enemies stay local; reinforcement groups actively join the encounter.
    actor:sendEvent('Dreamforged_DelveSpawned',{healthFraction=healthFraction,reinforcement=reinforcement or false})
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
        if info and old.enabled and old.count>0 and info.selectionVersion~=selectionVersion and not types.Actor.isDead(old) then
            local hp=types.Actor.stats.dynamic.health(old)
            local maximum=hp.base+hp.modifier
            local fraction=maximum>0 and math.max(0.01,math.min(1,hp.current/maximum)) or 1
            local pos=old.position
            local actor=spawn(slot,index,{pos.x,pos.y,pos.z},info.boss and not slot.bossDefeated,fraction)
            -- spawn appends; replace the original entry without changing population.
            slot.objects[#slot.objects]=nil;slot.ids[#slot.ids]=nil
            slot.objects[i]=actor;slot.ids[i]=actor.id
            local oldId=old.id;remove(old);forgetActor(oldId);replaced=replaced+1
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
            remove(item);remove(loose.light)
            state.director.loose[id]=nil
        end
    end
    for i,o in ipairs(slot.objects or {}) do
        local id=slot.ids and slot.ids[i] or (live(o) and o.id)
        remove(o)
        if id then
            forgetActor(id)
        end
    end
end
local function livingHere(actor,slot)
    return live(actor) and actor.enabled and actor.count>0 and actor.cell and actor.cell.name==slot.cell and not types.Actor.isDead(actor)
end
local function aliveCount(slot)
    local count=0;for _,actor in ipairs(slot.objects) do if livingHere(actor,slot) then count=count+1 end end
    return count
end
local function observation(slot,p,sample)
    local nearby,incoming,reinforcements,kills,combat=0,0,0,0,0
    slot.deadSeen=slot.deadSeen or {}
    for _,actor in ipairs(slot.objects)do
        if livingHere(actor,slot)then
            local distance=(actor.position-p.position):length()
            local info=context(actor)
            if info and distance<2400 and (info.combatUntil or 0)>core.getSimulationTime()then combat=combat+1 end
            if distance<Pacing.nearRadius then nearby=nearby+1 end
            if info and info.reinforcement then
                reinforcements=reinforcements+1
                if distance>=Pacing.nearRadius then incoming=incoming+1 end
            end
        elseif sample and live(actor) and actor.count>0 and types.Actor.isDead(actor) and not slot.deadSeen[actor.id]then
            slot.deadSeen[actor.id]=true
            if actor.cell==p.cell and (actor.position-p.position):length()<2400 then kills=kills+1 end
        end
    end
    -- Count other hostile actors too, without mistaking allies for floor-owned enemies.
    for _,actor in ipairs(world.activeActors)do
        if actor~=p and not context(actor) and actor.cell==p.cell and actor.enabled and actor.count>0
            and not types.Actor.isDead(actor) and types.Actor.stats.ai.fight(actor).base>=80
            and (actor.position-p.position):length()<Pacing.nearRadius then nearby=nearby+1 end
    end
    local hp=types.Actor.stats.dynamic.health(p);local maximum=math.max(1,hp.base+hp.modifier)
    local health=math.max(0,math.min(1,hp.current/maximum))
    local loss=sample and slot.lastHealth and math.max(0,slot.lastHealth-health)or 0
    if sample then slot.lastHealth=health end
    return {nearby=nearby,incoming=incoming,reinforcements=reinforcements,kills=kills,health=health,loss=loss,combat=combat}
end
local function nearBoss(slot,p)
    return not not (livingHere(slot.boss,slot) and (slot.boss.position-p.position):length()<1800)
end
local function cancelPlacement(slot,reason,includePopulation)
    if slot.pending or slot.placement then diagnostic(slot,'placement cancelled',reason) end
    slot.pending=nil;slot.placement=nil
    if includePopulation then slot.populationPending=nil;if slot.voice then slot.voice.pending=nil end end
end
local function finishFailure(slot,reason)
    local batch=slot.placement
    slot.pending=nil;slot.placement=nil;slot.lastPlacementFailure=reason
    diagnostic(slot,'batch deferred',reason)
    if batch and batch.bossAdd then slot.nextAdds=core.getSimulationTime()+5
    else slot.nextWave=core.getSimulationTime()+5 end
end
local function nextCandidate(slot,p)
    local batch=slot.placement;local now=core.getSimulationTime()
    if not batch then return end
    if now>batch.expires or batch.attempts>=12 or batch.attempts>=#batch.options then finishFailure(slot,'candidate batch exhausted');return end
    batch.attempts=batch.attempts+1
    local index=(batch.start+batch.attempts-1)%#batch.options+1
    slot.anchorCursor=index
    local anchor=batch.options[index]
    local d=data();d.placementSerial=(d.placementSerial or 0)+1
    local token=bindingGeneration..':'..d.placementSerial
    slot.request=(slot.request or 0)+1
    slot.pending={token=token,expires=math.min(batch.expires,now+2),anchor=anchor,count=batch.count,bossAdd=batch.bossAdd,bossId=batch.bossId}
    diagnostic(slot,batch.bossAdd and 'boss add requested' or 'wave requested',
        'Token '..token..'; attempt '..batch.attempts..'/'..math.min(12,#batch.options)..'; '..batch.count..' actors')
    p:sendEvent('Dreamforged_DelveCheckAnchor',{token=token,depth=slot.depth,cell=slot.cell,position=vec(anchor),count=batch.count})
end
local function beginPlacement(slot,index,p,bossAdd)
    if not C.enabled or not C.extraEncounters or (bossAdd or false)~=nearBoss(slot,p) then return false end
    if slot.pending or slot.placement then return false end
    local alive=aliveCount(slot);local o=observation(slot,p)
    if o.health<.35 or (slot.pacing and slot.pacing.damage>=.18)then return false end
    local available=Pacing.capacity(slot.pacing or {},alive,o.nearby,o.incoming,o.reinforcements)
    if (slot.serial or 0)>=96 then diagnostic(slot,'floor budget','Floor encounter budget exhausted; descend to continue');return false end
    if not bossAdd and slot.pacing and slot.pacing.blocked then return false end
    diagnostic(slot,'placement search',alive..'/'..Pacing.floorCap..' living; '..o.nearby..' nearby; '..o.incoming..' incoming')
    slot.diagnostics.alive,slot.diagnostics.cap=alive,Pacing.floorCap
    if available<=0 then diagnostic(slot,'threat cap',o.nearby..' nearby, '..o.incoming..' incoming; floor '..alive..'/'..Pacing.floorCap);return false end
    if bossAdd and (slot.addsMade or 0)>=4 then return false end
    local options,candidates={},{}
    for anchorIndex,a in ipairs(layouts[index].anchors) do
        for offsetIndex,offset in ipairs({{0,0},{384,0},{-384,0},{0,384},{0,-384},{384,384},{-384,384},{384,-384},{-384,-384}}) do
            local pos=vec(a)+util.vector3(offset[1],offset[2],0);local distance=(pos-p.position):length()
            local occupied=false
            for _,actor in ipairs(slot.objects) do if livingHere(actor,slot) and (actor.position-pos):length()<300 then occupied=true;break end end
            if not occupied and distance>=1800 and distance<=4000 then options[#options+1]={pos.x,pos.y,pos.z} end
            candidates[#candidates+1]={index=anchorIndex,offset=offsetIndex,distance=math.floor(distance),occupied=occupied,inRange=distance>=1800 and distance<=4000}
        end
    end
    slot.diagnostics.candidates=candidates
    if #options==0 then diagnostic(slot,'no eligible anchor','No free candidate within 1800-4000');return false end
    local rng=R.stream(data().serial..':'..slot.depth,'delve-placement-v1')
    local start=slot.anchorCursor or (rng(#options)-1)
    slot.placement={options=options,start=start,attempts=0,expires=core.getSimulationTime()+8,
        count=math.min(bossAdd and 1 or 2,available),bossAdd=bossAdd or false,bossId=bossAdd and slot.boss.id or nil}
    nextCandidate(slot,p);return true
end
local function descend(p)
    if core.getSimulationTime()-travelAt<2 then return end
    travelAt=core.getSimulationTime()
    local previous=currentSlot(p)
    if previous then
        cancelPlacement(previous,'descending',true);previous.nextWave=travelAt+15;previous.nextAdds=travelAt+15
    end
    local d=data();local depth=d.depth+1;local index=Rules.layout(depth)
    local old=d.slots[index]
    if old then cancelPlacement(old,'layout recycled',true);cleanup(old) end
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
    cancelPlacement(slot,'portal retreat',true)
    slot.nextWave=core.getSimulationTime()+15;slot.nextAdds=core.getSimulationTime()+15
    local d=data();d.returnPoint={cell=p.cell.name,position=p.position,rotation=p.rotation,depth=slot.depth}
    hub(p)
end
local function resume(p)
    local d=data();local r=d.returnPoint
    local returnSlot=r and d.slots[Rules.layout(r.depth)]
    if r and returnSlot and returnSlot.depth==r.depth then
        p:teleport(r.cell,r.position,{rotation=r.rotation,onGround=true})
        returnSlot.nextWave=core.getSimulationTime()+15
        returnSlot.nextAdds=math.max(returnSlot.nextAdds or 0,core.getSimulationTime()+15)
    elseif d.depth>0 then
        local index=Rules.layout(d.depth)
        p:teleport(layouts[index].name,vec(layouts[index].entry),{onGround=true})
        d.slots[index].nextWave=core.getSimulationTime()+15
        d.slots[index].nextAdds=math.max(d.slots[index].nextAdds or 0,core.getSimulationTime()+15)
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
        for _,slot in pairs(d.slots) do cancelPlacement(slot,'run reset',true);cleanup(slot) end
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
function M.bind(s,a)
    state,api=s,a;Selection.bind(data);bindingGeneration=bindingGeneration+1;lastCell=nil;elapsed=0
    for _,slot in pairs((s.delve or {}).slots or {}) do slot.pending=nil;slot.placement=nil;slot.populationPending=nil;slot.lastHealth=nil;if slot.voice then slot.voice.pending=nil end end
end
function M.init()
    if registered or not core.contentFiles.has('Dreamforged-Delve.esp') then return end
    registered=true
    I.Activation.addHandlerForType(types.Activator,activate)
    I.Activation.addHandlerForType(types.NPC,activate)
end
local function populate(slot,index,p,now)
    local pop=slot.population
    if not pop or pop.done then return end
    if slot.populationPending and now<slot.populationPending.expires then return end
    if pop.made>=pop.target then pop.done=true;slot.populationPending=nil;return end
    if pop.cursor>#pop.points then
        pop.round=(pop.round or 1)+1
        if pop.round>3 then pop.done=true;slot.populationPending=nil;return end
        pop.cursor=1
    end
    local points={}
    for i=pop.cursor,math.min(#pop.points,pop.cursor+3)do points[#points+1]=pop.points[i]end
    pop.cursor=pop.cursor+#points
    local d=data();d.placementSerial=(d.placementSerial or 0)+1
    local token=bindingGeneration..':population:'..d.placementSerial
    slot.populationPending={token=token,expires=now+2,points=points}
    p:sendEvent('Dreamforged_DelvePopulation',{token=token,depth=slot.depth,cell=slot.cell,points=points})
end
function M.population(e)
    local p=e and e.player;if not live(p)then return end
    local slot,index=currentSlot(p);local pending=slot and slot.populationPending
    if not pending or e.token~=pending.token or e.depth~=slot.depth then return end
    slot.populationPending=nil
    if not C.enabled or core.getSimulationTime()>pending.expires or types.Actor.isDead(p) or e.cell~=slot.cell or not e.origin or (p.position-e.origin):length()>160
        or not e.checkedAt or core.getSimulationTime()-e.checkedAt>.75 then return end
    local pop=slot.population
    for _,pos in ipairs(e.positions or {})do
        if pop.made>=pop.target or aliveCount(slot)>=Pacing.floorCap then break end
        local authored=false
        for _,point in ipairs(pending.points)do if (vec(point)-vec(pos)):length()<64 then authored=true;break end end
        local occupied=false
        for _,actor in ipairs(slot.objects)do if livingHere(actor,slot)and(actor.position-vec(pos)):length()<400 then occupied=true end end
        if authored and not occupied then spawn(slot,index,pos,false);pop.made=pop.made+1 end
    end
    pop.lastValidation=e.metrics
    pop.validations=(pop.validations or 0)+1
    pop.validationMs=(pop.validationMs or 0)+(e.metrics and e.metrics.ms or 0)
    pop.maxValidationMs=math.max(pop.maxValidationMs or 0,e.metrics and e.metrics.ms or 0)
end
function M.combat(e)
    local info=e and live(e.actor) and context(e.actor)
    if info then info.combatUntil=e.fighting and core.getSimulationTime()+4 or 0 end
end
function M.allowPromotion(actor)
    local info=context(actor);if not info or not info.density or info.boss then return true end
    local slot=data().slots[info.index];return slot and (slot.promotions or 0)<Pacing.promotionCap
end
function M.promoted(actor)
    local info=context(actor)
    if info and info.density and not info.boss and not info.promoted then
        info.promoted=true;local slot=data().slots[info.index];slot.promotions=(slot.promotions or 0)+1
    end
end
function M.rewardEligible(actor)
    local info=context(actor)
    if not info or not info.density or info.boss or state.elites[actor.id]then return true end
    return R.stream(actor.id,'density-reward-v1')()<4/Pacing.ambientTarget(info.depth)
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
        for _,o in ipairs(d.entrance) do remove(o) end
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
            retreat(p);return
        end
    end
    local slot,index=currentSlot(p)
    for _,other in pairs(d.slots) do if other.cell~=p.cell.name then cancelPlacement(other,'player left floor',true) end end
    if not slot then lastCell=nil;return end
    if not C.enabled then cancelPlacement(slot,'Dreamforged disabled',true);diagnostic(slot,'disabled','Dreamforged is disabled');return end
    if lastCell~=p.cell.name then
        lastCell=p.cell.name;slot.nextWave=now+15;slot.nextAdds=math.max(slot.nextAdds or 0,now+15);slot.lastHealth=nil
        slot.pacing=slot.pacing or Pacing.new(now);slot.pacing.lastAt=now
    end
    if slot.pendingInitial then
        slot.pendingInitial=nil
        slot.population={points=Population.points(layouts[index]),cursor=1,made=0,target=Pacing.ambientTarget(slot.depth)}
        slot.pacing=Pacing.new(now)
        Narration.offerDungeon(slot,'entry','descent',{depth=slot.depth},now,3)
        if Rules.boss(slot.depth) then spawn(slot,index,layouts[index].exit,true) end
        print('[Dreamforged Delve] initial population depth '..slot.depth)
        diagnostic(slot,'initial population',#slot.objects..' actors placed')
    end
    populate(slot,index,p,now)
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
        slot.pacing=slot.pacing or Pacing.new(now);slot.pacing.phase='relax';slot.pacing.phaseAt=now;slot.pacing.untilTime=now+35
        if slot.depth>=3 then journal(p,100) end
        Narration.offerDungeon(slot,'victory','guardianVictory',{},now,4)
        tell(p,'Velyna has new stock. Reinforcements pause while you recover.')
    end
    if nearBoss(slot,p)then Narration.offerDungeon(slot,'guardian','guardian',{},now,4)end
    if not C.extraEncounters then Narration.tickDungeon(state,C,p,now,slot);cancelPlacement(slot,'extra encounters disabled');diagnostic(slot,'encounters disabled','Extra encounters are disabled');return end
    local o=observation(slot,p,true);slot.pacing=slot.pacing or Pacing.new(now)
    local previousPhase=slot.voice and slot.voice.phase
    Pacing.step(slot.pacing,now,o)
    slot.voice=slot.voice or {seen={}};slot.voice.phase=slot.pacing.phase
    if previousPhase~=slot.pacing.phase and slot.voice.pending and slot.voice.pending.priority==1 then slot.voice.pending=nil end
    if previousPhase and previousPhase~=slot.pacing.phase and slot.pacing.phase~='fade' then
        Narration.offerDungeon(slot,nil,slot.pacing.phase,{},now,1)
    end
    slot.pacing.reinforcements=o.reinforcements
    local bossEncounter=nearBoss(slot,p)
    Narration.tickDungeon(state,C,p,now,slot)
    if bossEncounter and (o.health<.35 or slot.pacing.damage>=.18)then
        cancelPlacement(slot,'player recovery');diagnostic(slot,'recovery','Guardian adds withheld while depleted');return
    end
    if not bossEncounter and slot.pacing.blocked then
        cancelPlacement(slot,'pacing recovery');diagnostic(slot,slot.pacing.phase,slot.pacing.reason or 'Recovery');return
    end
    if slot.population and not slot.population.done then diagnostic(slot,'populating','Ambient '..slot.population.made..'/'..slot.population.target);return end
    if slot.placement and slot.placement.bossAdd~=bossEncounter then cancelPlacement(slot,'encounter changed') end
    if slot.pending then
        if now>slot.pending.expires then
            diagnostic(slot,'response expired','Token '..slot.pending.token);slot.pending=nil;nextCandidate(slot,p)
        else diagnostic(slot,'awaiting placement','Token '..slot.pending.token) end
        return
    end
    if bossEncounter then
        if now>=(slot.nextAdds or 0) and (slot.addsMade or 0)<4 then
            if not beginPlacement(slot,index,p,true) then slot.nextAdds=now+5 end
        else diagnostic(slot,'boss encounter','Ordinary waves paused; adds made '..(slot.addsMade or 0)) end
        return
    end
    if now<slot.nextWave then diagnostic(slot,'waiting',math.ceil(slot.nextWave-now)..' seconds to next wave check');return end
    if not beginPlacement(slot,index,p,false) then slot.nextWave=now+5 end
end
function M.anchor(e)
    local p=e and e.player;if not live(p) or not types.Player.objectIsInstance(p) then return end
    local slot,index=currentSlot(p);if not slot then return end
    local request=slot.pending;local batch=slot.placement;local now=core.getSimulationTime()
    if not request or not batch or e.depth~=slot.depth or e.token~=request.token then return end
    slot.pending=nil
    if not C.enabled or not C.extraEncounters or types.Actor.isDead(p) or request.bossAdd~=nearBoss(slot,p)
        or (request.bossAdd and request.bossId~=slot.boss.id) then cancelPlacement(slot,'encounter changed');return end
    slot.diagnostics.lastResponse={token=e.token,clear=e.clear,reason=e.reason,camera=e.camera,
        ground=e.ground,visible=e.visible,navStatus=e.navStatus,navMethod=e.navMethod,occupied=e.occupied,rejections=e.rejections}
    local failure=not e.clear and (e.reason or 'placement rejected')
        or now>request.expires and 'expired response'
        or e.cell~=slot.cell and 'changed cell'
        or not e.checkedAt and 'missing validation time'
        or e.checkedAt and now-e.checkedAt>0.75 and 'stale camera validation'
        or not e.origin and 'missing validation origin'
        or e.origin and (p.position-e.origin):length()>160 and 'player moved during validation'
    local positions={}
    if not failure then
        for i,a in ipairs(e.positions or {}) do
            if i>request.count then break end
            local pos=vec(a);local distance=(pos-p.position):length()
            if (pos-vec(request.anchor)):length()>500 or distance<1800 or distance>4000 then failure='invalid validated position';break end
            for _,actor in ipairs(slot.objects) do if livingHere(actor,slot) and (actor.position-pos):length()<300 then failure='position became occupied';break end end
            for _,other in ipairs(positions) do if (vec(other)-pos):length()<300 then failure='formation overlap';break end end
            if failure then break end
            positions[#positions+1]=a
        end
        if #positions==0 then failure=failure or 'empty formation' end
    end
    if failure then
        slot.lastPlacementFailure=failure;diagnostic(slot,'placement rejected',failure)
        nextCandidate(slot,p);return
    end
    local o=observation(slot,p)
    if o.health<.35 or (slot.pacing and slot.pacing.damage>=.18)then cancelPlacement(slot,'player recovery');return end
    local capacity=Pacing.capacity(slot.pacing or {},aliveCount(slot),o.nearby,o.incoming,o.reinforcements)
    if not request.bossAdd and slot.pacing and slot.pacing.blocked then cancelPlacement(slot,'pacing recovery');return end
    local count=math.min(#positions,capacity,96-(slot.serial or 0),request.bossAdd and (4-(slot.addsMade or 0)) or 2)
    if count<=0 then finishFailure(slot,'population capacity changed');return end
    slot.placement=nil;slot.lastPlacementFailure=nil
    for i=1,count do spawn(slot,index,positions[i],false,nil,true) end
    if request.bossAdd then
        slot.addsMade=(slot.addsMade or 0)+count;slot.addWaves=(slot.addWaves or 0)+1;slot.nextAdds=now+25
    else
        slot.ordinaryWaves=(slot.ordinaryWaves or slot.waves or 0)+1
        slot.nextWave=now+((slot.pacing and slot.pacing.phase=='peak') and 7 or 11)
    end
    slot.waves=(slot.waves or 0)+1
    if not request.bossAdd then Narration.offerDungeon(slot,nil,'group',{},now,1)end
    diagnostic(slot,'wave spawned',count..' actors; '..(request.bossAdd and 'boss add' or 'ordinary wave'))
    print('[Dreamforged Delve] reinforcement wave '..slot.waves..' at depth '..slot.depth..' ('..count..' actors)')
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
function M.debugState(p)
    local slot=currentSlot(p)
    if not slot then return {status='Uninitialized',detail='Start or resume a descent through the refuge.'} end
    local now=core.getSimulationTime();local diag=slot.diagnostics or {};local bossEncounter=nearBoss(slot,p)
    local guardian=not Rules.boss(slot.depth) and 'not scheduled' or slot.bossDefeated and 'defeated'
        or livingHere(slot.boss,slot) and (bossEncounter and 'engaged' or 'alive') or 'pending'
    local pace=slot.pacing or {}
    return {depth=slot.depth,alive=aliveCount(slot),cap=Pacing.floorCap,
        dungeonPhase=pace.phase or 'build',intensity=math.floor(pace.intensity or 0),nearby=pace.nearby or 0,
        nearbyCap=pace.nearbyCap or 8,incoming=pace.incoming or 0,recovery=pace.phase=='relax' and math.max(0,math.ceil((pace.untilTime or now)-now))or nil,
        ambient=slot.population and slot.population.made,ambientTarget=slot.population and slot.population.target,
        waves=slot.ordinaryWaves or math.max(0,(slot.waves or 0)-(slot.addWaves or 0)),
        guardian=guardian,adds=slot.addsMade or 0,addCap=4,
        countdown=not slot.pending and (not slot.population or slot.population.done)
            and (bossEncounter and (pace.health or 1)>=.35 and (pace.damage or 0)<.18 or not bossEncounter and not pace.blocked)
            and (not bossEncounter or (slot.addsMade or 0)<4)
            and math.max(0,math.ceil((bossEncounter and (slot.nextAdds or now) or (slot.nextWave or now))-now)) or nil,
        countdownKind=bossEncounter and 'guardian add' or 'wave',
        status=diag.status or 'Initializing',detail=diag.detail or 'Preparing the floor.',
        lastAction=diag.lastAction or '',attempt=slot.placement and slot.placement.attempts or nil,
        lastFailure=slot.lastPlacementFailure}
end
M.test={descend=descend,resume=resume,retreat=retreat,shop=shop,spawn=spawn,data=data,activate=activate,
    selectEnemy=selectEnemy,migrateSelection=migrateSelection,selection=Selection,
    beginPlacement=beginPlacement,aliveCount=aliveCount,cancelPlacement=cancelPlacement,observation=observation,pacing=Pacing,population=Population}
return M
