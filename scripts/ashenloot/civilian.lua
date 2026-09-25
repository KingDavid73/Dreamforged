local core, types, self = require('openmw.core'), require('openmw.types'), require('openmw.self')
local nearby, util = require('openmw.nearby'), require('openmw.util')
local I, C = require('openmw.interfaces'), require('scripts.ashenloot.config')
local elapsed, target, timeout, travelPos = -require('scripts.ashenloot.rules').rng(self.id)()*8,nil,0,nil
local scanCursor=1
local scavenged=0
local firstSeen={}
local lastPrune=0
local S=types.Actor.EQUIPMENT_SLOT
local armorSlots={}
for name,equip in pairs({Helmet='Helmet',Cuirass='Cuirass',Greaves='Greaves',LPauldron='LeftPauldron',
    RPauldron='RightPauldron',LGauntlet='LeftGauntlet',RGauntlet='RightGauntlet',Boots='Boots',LBracer='LeftGauntlet',RBracer='RightGauntlet'}) do
    armorSlots[types.Armor.TYPE[name]]=S[equip]
end
armorSlots[types.Armor.TYPE.Shield]=S.CarriedLeft
local weaponSkills = {[0]='shortblade',[1]='longblade',[2]='longblade',[3]='bluntweapon',
    [4]='bluntweapon',[5]='bluntweapon',[6]='spear',[7]='axe',[8]='axe',[9]='marksman',[10]='marksman'}
local function reservedForPlayer(item)
    local api=I.AshenLoot
    if not api or not api.getState then return false end
    local ok,state=pcall(api.getState)
    local loose=ok and state and state.director and state.director.loose
        and state.director.loose[item.id]
    return type(loose)=='table' and loose.protected==true
end
local function likelyPlayerDrop(item)
    local owner=item.owner
    if owner and owner.recordId and tostring(owner.recordId):lower()=='player' then return true end
    if owner and (owner.recordId or owner.factionId) then return false end
    -- OpenMW 0.51 has no global onDropped/onPlaced callback. A loose object
    -- without an original cell is the best available signal for an item that
    -- came out of an inventory; generated Dreamforged rewards are separately
    -- protected by reservedForPlayer until the player collects them.
    return item.startingCell==nil
end
local function slot(item)
    if types.Weapon.objectIsInstance(item) then
        local r=item.type.record(item)
        if r.type>types.Weapon.TYPE.MarksmanCrossbow then return end
        return S.CarriedRight
    elseif types.Armor.objectIsInstance(item) then return armorSlots[item.type.record(item).type] end
end
local function score(item)
    if not item then return 0 end
    local r=item.type.record(item)
    if types.Weapon.objectIsInstance(item) then
        local skill=weaponSkills[r.type]
        local ability=skill and types.NPC.stats.skills[skill](self).modified or 20
        return math.max(r.chopMaxDamage,r.slashMaxDamage,r.thrustMaxDamage)*r.speed*(0.25+ability/100)+(r.enchant and 5 or 0)
    end
    return r.baseArmor or 0
end
local function protected()
    local r=self.type.record(self)
    if r.mwscript or r.isEssential or types.Actor.isDead(self) then return true end
    local follower=false
    I.AI.forEachPackage(function(p) if p.type=='Follow' or p.type=='Escort' then follower=true end end)
    return follower
end
local function stopTravel()
    if travelPos then
        I.AI.filterPackages(function(p)
            return not (p.type=='Travel' and p.destPosition and (p.destPosition-travelPos):length()<1)
        end)
    end
    target,travelPos=nil,nil
end
local function update(dt)
    elapsed=elapsed+dt
    local interval=target and 1 or 10
    if elapsed<interval then return end
    elapsed=0
    if not C.enabled or not C.scavenge or protected() then stopTravel();return end
    local active=I.AI.getActivePackage()
    if active and active.type=='Combat' then stopTravel();return end
    if target then
        timeout=timeout+1
        if not target:isValid() or target.parentContainer or target.cell~=self.cell or timeout>20 then stopTravel();return end
        if (target.position-self.position):length()<220 then
            core.sendGlobalEvent('AshenLoot_Scavenge',{actor=self,item=target,
                playerDrop=likelyPlayerDrop(target)})
            stopTravel()
        end
        return
    end
    if C.civilianDefense and scavenged>0 then
        local hp=types.Actor.stats.dynamic.health(self)
        if hp.current>=math.max(5,hp.base*0.35) then
            local defenseRange=250+math.min(3,scavenged)*125
            for _,other in ipairs(nearby.actors) do
                if other~=self and other:isValid() and types.Creature.objectIsInstance(other)
                    and not types.Actor.isDead(other) and types.Actor.stats.ai.fight(other).base>=80
                    and (other.position-self.position):length()<=defenseRange then
                    stopTravel()
                    I.AI.startPackage {type='Combat',target=other,cancelOther=false}
                    return
                end
            end
        end
    end
    -- Do not interrupt travel/follow/escort/combat jobs. Native idle packages are not
    -- reported consistently across NPC schedules, so only block known busy work.
    if active and (active.type=='Travel' or active.type=='Follow' or active.type=='Escort'
        or active.type=='Combat' or active.type=='Activate') then return end
    local eq=types.Actor.getEquipment(self)
    local items=nearby.items
    local now=core.getSimulationTime()
    if now-lastPrune>=60 then
        lastPrune=now
        for id,untilTime in pairs(firstSeen) do
            if untilTime+30<now then firstSeen[id]=nil end
        end
    end
    for _=1,#items do
        if scanCursor>#items then scanCursor=1 end
        local item=items[scanCursor]
        scanCursor=scanCursor+1
        if item.enabled and item.cell==self.cell and (item.position-self.position):length()<2000 then
            local s=slot(item)
            local ok,r=pcall(function() return item.type.record(item) end)
            local owner=item.owner
            local playerDrop=likelyPlayerDrop(item)
            local ownedByOther=owner and (owner.recordId or owner.factionId)
            local betterEquipment=s and score(item)>score(eq[s])*1.02
            if ok and r and not reservedForPlayer(item) and not r.mwscript
                and (playerDrop or (not ownedByOther and betterEquipment)) then
                local grace=firstSeen[item.id]
                if playerDrop and not grace then
                    -- A brief first-noticed grace period gives the player time
                    -- to correct an accidental drop without polling constantly.
                    firstSeen[item.id]=now+5
                elseif not grace or now>=grace then
                    target,timeout,travelPos=item,0,item.position
                    I.AI.startPackage {type='Travel',destPosition=travelPos,cancelOther=false}
                    return
                end
            end
        end
    end
end
I.Combat.addOnHitHandler(function(hit)
    if not C.enabled or not C.civilianDefense or protected() or not hit.successful then return end
    local attacker=hit.attacker
    if not attacker or not attacker:isValid() or not types.Creature.objectIsInstance(attacker) then return end
    if (attacker.position-self.position):length()>220 then return end
    local hp=types.Actor.stats.dynamic.health(self)
    if hp.current<math.max(5,hp.base*0.2) then return end
    stopTravel()
    I.AI.startPackage {type='Combat',target=attacker,cancelOther=false}
end)
return {engineHandlers={
    onUpdate=update,onInactive=stopTravel,
    onSave=function() return {scavenged=scavenged} end,
    onLoad=function(data) scavenged=data and data.scavenged or 0;stopTravel() end,
},eventHandlers={
    AshenLoot_Pickup=function(item)
        if not item or not item:isValid() or item.parentContainer~=self.object then return end
        scavenged=scavenged+1
        local s=slot(item)
        if not s then return end
        local eq=types.Actor.getEquipment(self)
        if score(item)<=score(eq[s]) then return end
        eq[s]=item
        types.Actor.setEquipment(self,eq)
    end,
}}
