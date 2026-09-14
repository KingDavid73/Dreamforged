local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local C = require('scripts.ashenloot.config')
local storage = require('openmw.storage')
local nearby = require('openmw.nearby')
local hasRandomizer = core.contentFiles.has('morrowind_world_randomizer.omwscripts')
local randomizer = hasRandomizer and storage.globalSection('MWR_By_Diject')
local data = {checked = false, applied = false, deathSent = false, witnessed = false}
local timer, quiet, pendingAge = 0, 0, 0
local pending, deferred, lastBase = false, nil, nil
local function isFollower()
    local follower = false
    I.AI.forEachPackage(function(package)
        if package.type == 'Follow' or package.type == 'Escort' then follower = true end
    end)
    return follower
end
local function available()
    local rec = self.type.record(self)
    if not C.unsafeContent then
        for _, offered in pairs(rec.servicesOffered or {}) do if offered then return false end end
    end
    if types.NPC.objectIsInstance(self) and not (C.npcProgression or (C.allowRespawningNPCs and rec.isRespawning)) then return false end
    return C.enabled and self.enabled and self.scale >= 0.001 and (C.unsafeContent or not isFollower())
        and (C.unsafeContent or not (C.protectQuestActors and
            (rec.isEssential or (rec.mwscript and (not types.Creature.objectIsInstance(self) or not rec.isRespawning)))))
end
local function request(refresh)
    if not available() or (data.checked and not refresh) or pending then return end
    if quiet < C.settleSeconds then return end
    if randomizer and not randomizer:get('version') then return end
    pending = true
    pendingAge = 0
    core.sendGlobalEvent('AshenLoot_PrepareFighting', self)
    core.sendGlobalEvent('AshenLoot_Encounter', {actor = self})
end
I.Combat.addOnHitHandler(function(attack)
    if available() and attack.successful and attack.attacker and types.Player.objectIsInstance(attack.attacker) then
        data.witnessed = true
    end
end)
local function apply(event)
    data.checked = true
    if not event.elite then
        local spells=types.Actor.spells(self)
        if data.elite and data.elite.spellId and spells[data.elite.spellId] then spells:remove(data.elite.spellId) end
        if (data.modifierBonus or 0)>0 and not types.Actor.isDead(self) then
            local hp=types.Actor.stats.dynamic.health(self)
            hp.modifier=hp.modifier-data.modifierBonus
            hp.current=math.max(1,hp.current-data.modifierBonus)
        end
        data.elite=nil;data.modifierBonus=0;data.applied=false
        return
    end
    if types.Actor.isDead(self) then return end
    local oldSpell = data.elite and data.elite.spellId
    local spells = types.Actor.spells(self)
    -- Modifier abilities are separate from the tracked dynamic-health bonus.
    if not spells[event.elite.spellId] then spells:add(event.elite.spellId) end
    if oldSpell and oldSpell ~= event.elite.spellId and spells[oldSpell] then spells:remove(oldSpell) end
    if event.elite.healthModel == 2 then
        local hp = types.Actor.stats.dynamic.health(self)
        local delta = event.elite.healthBonus - (data.modifierBonus or 0)
        hp.modifier = hp.modifier + delta
        hp.current = math.max(1, hp.current + delta)
        data.modifierBonus = event.elite.healthBonus
    end
    data.elite = event.elite
    data.applied = true
    core.sendGlobalEvent('AshenLoot_Promoted', self)
end
local function result(event)
    pending = false
    deferred = event
end
local function disturbed()
    quiet = 0
end
local function update(dt)
    if dt <= 0 then return end
    timer = timer + dt
    quiet = quiet + dt
    if pending then
        pendingAge = pendingAge + dt
        if pendingAge > C.settleSeconds + 3 then pending = false end
    end
    if timer < 0.25 then return end
    timer = 0
    if not available() then return end
    if data.den then
        I.AI.removePackages()
        types.Actor.stats.ai.fight(self).base=0
    end
    local hp = types.Actor.stats.dynamic.health(self)
    if lastBase and hp.base ~= lastBase then quiet = 0 end
    lastBase = hp.base
    if types.Actor.isDead(self) then
        -- A fast kill still earns ordinary loot; never promote a corpse or a disabled parent.
        if (data.checked or data.witnessed) and not data.deathSent then
            data.deathSent = true
            core.sendGlobalEvent('AshenLoot_Death', self)
        end
        return
    end
    local fightingPlayer=false
    I.AI.forEachPackage(function(package)
        if package.type == 'Combat' and package.target and types.Player.objectIsInstance(package.target) then
            data.witnessed = true
            fightingPlayer=true
        end
    end)
    if quiet < C.settleSeconds then return end
    if deferred then
        local event = deferred
        deferred = nil
        if event.elite and event.elite.healthModel == 2 and event.elite.healthReference ~= hp.base then request(true)
        else apply(event) end
    end
    if data.applied then
        if data.elite.worldBoss and fightingPlayer and C.worldBossAddCap>0 then
            local now=core.getSimulationTime()
            data.bossWaveAt=data.bossWaveAt or (now+C.worldBossAddInitialDelay)
            if now>=data.bossWaveAt then
                data.bossWaveAt=now+C.worldBossAddInterval
                core.sendGlobalEvent('AshenLoot_BossWave',self)
            end
        end
        if data.elite.healthModel == 2 and data.elite.healthReference ~= hp.base then request(true) end
        return
    end
    if data.checked or pending then return end
    if data.witnessed then request() end
end
return {
    interfaceName = 'AshenLootActor',
    interface = {version = 2, getStatus = function()
        return {quiet = quiet, pending = pending, checked = data.checked, applied = data.applied,
            witnessed = data.witnessed, available = available(), health = types.Actor.stats.dynamic.health(self).base,
            current = types.Actor.stats.dynamic.health(self).current, dead = types.Actor.isDead(self)}
    end},
    engineHandlers = {
        onActive = function() quiet, lastBase, pending, deferred = 0, nil, false, nil end,
        onUpdate = update,
        onSave = function() return data end,
        onLoad = function(saved) data = saved or data; pending = false; quiet = 0; lastBase = nil end,
    },
    eventHandlers = {
        AshenLoot_Consider = function()
            if available() and not types.Actor.isDead(self) then
                local active=I.AI.getActivePackage()
                core.sendGlobalEvent(active and active.type=='Combat' and 'AshenLoot_PrepareFighting' or 'AshenLoot_Prepare',self)
            end
        end,
        AshenLoot_Scale = function(event)
            if data.scaled or not available() then return end
            data.scaled = true
            local hp = types.Actor.stats.dynamic.health(self)
            local fraction = hp.base > 0 and math.min(1,hp.current/hp.base) or 1
            local native = math.max(1,event.nativeLevel or types.Actor.stats.level(self).current)
            local delta = event.progression and event.level-native or 0
            -- Level growth scales with the creature's native durability, while the
            -- ratio path also makes high-tier loaded creatures usable at low level.
            local scaledHealth=hp.base
            if event.allowDownscale and delta<0 then
                local ratio=math.max(0.20,((event.level+4)/(native+4))^0.85)
                scaledHealth=hp.base*ratio
                local magicka=types.Actor.stats.dynamic.magicka(self)
                local magickaFraction=magicka.base>0 and math.min(1,magicka.current/magicka.base) or 1
                magicka.base=math.max(0,magicka.base*math.max(0.2,(event.level+4)/(native+4)))
                magicka.current=magicka.base*magickaFraction
            elseif delta>0 then
                scaledHealth=hp.base+delta*(3+math.min(8,hp.base*0.08))
            end
            hp.base = math.max(5,scaledHealth*event.health)
            hp.current = hp.base*fraction
            local strength=types.Actor.stats.attributes.strength(self)
            local strengthScale=1
            if event.allowDownscale and delta<0 then
                strengthScale=math.max(0.30,((event.level+4)/(native+4))^0.65)
            end
            strength.base = math.max(1,math.min(10000,(strength.base*strengthScale+math.max(0,delta)*1.1)*event.damage))
            if event.progression then types.Actor.stats.level(self).current=event.level end
        end,
        AshenLoot_Equip = function(items)
            if not available() then return end
            local eq = types.Actor.getEquipment(self)
            for _,entry in ipairs(items) do eq[entry.slot]=entry.id end
            types.Actor.setEquipment(self,eq)
        end,
        AshenLoot_Spawned = function()
            types.Actor.stats.ai.fight(self).base=90
            local player=nearby.players[1]
            if player then I.AI.startPackage{type='Combat',target=player,cancelOther=true} end
        end,
        AshenLoot_DenSpawned = function(event)
            data.den=true
            I.AI.removePackages()
            types.Actor.stats.ai.fight(self).base=0
            if event and event.model then
                self:sendEvent('AddVfx',{model=event.model,
                    options={particleTextureOverride=event.particle,loop=true,useAmbientLight=false}})
            end
        end,
        AshenLoot_MythicAttack=function(target)
            if target and target:isValid() then
                types.Actor.stats.ai.fight(self).base=100
                I.AI.startPackage{type='Combat',target=target,cancelOther=true}
            end
        end,
        AshenLoot_MythicFollow=function(target)
            if target and target:isValid() then
                types.Actor.stats.ai.fight(self).base=20
                I.AI.startPackage{type='Follow',target=target,cancelOther=true}
            end
        end,
        AshenLoot_EncounterResult = result,
        mwr_actor_setDynamicBaseStats = disturbed, mwr_actor_setDynamicStats = disturbed,
        mwr_actor_randomizeSpells = disturbed, mwr_actor_randomizeInventory = disturbed,
        mwr_actor_setEquipment = disturbed,
    },
}
