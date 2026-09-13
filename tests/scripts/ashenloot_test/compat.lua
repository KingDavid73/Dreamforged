local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local storage = require('openmw.storage')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local C = require('scripts.ashenloot.config')
local cfg = storage.globalSection('SettingsAshenLoot')
local elapsed, mark, stage = 0, 0, 0
local original, replacement, mainland, fast, originalPosition, beforeLoot, reloaded
local function pass(s) print('[AshenLoot COMPAT] PASS: ' .. s) end
local function transition(nextStage) stage, mark = nextStage, elapsed end
local function creatureFixture(recordId, offset)
    local p = world.players[1]
    local actor = world.createObject(recordId)
    actor:teleport(p.cell, p.position + util.vector3(offset, 0, 0))
    actor:addScript('scripts/ashenloot_test/actor.lua')
    return actor
end
local function eliteEffect(actor)
    local elite = I.AshenLoot.getState().elites[actor.id]
    assert(elite, 'Expected elite metadata')
    assert(types.Actor.spells(actor)[elite.spellId], 'Missing elite ability')
    assert(types.Actor.stats.dynamic.health(actor).modifier == elite.healthBonus, 'Health modifier mismatch')
    return elite
end
local function onUpdate(dt)
    if dt <= 0 then return end
    elapsed = elapsed + dt
    local ok, err = pcall(function()
        if stage == 0 then
            if not storage.globalSection('MWR_By_Diject'):get('version') then
                assert(elapsed < 120, 'World Randomizer initialization timeout'); return
            end
            assert(C.eliteChance == 0.16 and C.normalDropChance == 0.12, 'Balanced defaults missing')
            cfg:set('preset', 'Testing')
            assert(C.eliteChance == 0.5 and C.normalDropChance == 1, 'Testing preset missing')
            world.players[1]:sendEvent('AshenLoot_TestFreezeAI')
            cfg:set('preset', 'Balanced')
            assert(C.eliteChance == 0.16 and C.normalDropChance == 0.12, 'Balanced preset failed')
            cfg:set('preset', 'Custom'); cfg:set('elitePercent', 100); cfg:set('dropPercent', 100)
            assert(C.eliteChance == 1 and C.normalDropChance == 1, 'Custom settings failed')
            pass('Balanced defaults and live Testing/Balanced/Custom settings; Fresh Loot and World Randomizer loaded with TR')
            -- Enable the installed randomizer through its public settings event. Avoid scenery changes in the test room.
            core.sendGlobalEvent('mwrbd_updateSettings', {enabled = true, randomizeOnce = true,
                world = {item = {randomize = false}, light = {randomize = false}, herb = {randomize = false},
                    static = {tree = {randomize = false}, rock = {randomize = false}, flora = {randomize = false}}},
                creature = {randomize = true, onlyLeveled = false, byType = true, rregion = {min = 100, max = 100},
                    item = {randomize = false}, stat = {dynamic = {randomize = false}},
                    spell = {randomize = false, add = {count = 0}, remove = {count = 0}}}})
            transition(1)
        elseif stage == 1 and elapsed - mark > 1 then
            original = creatureFixture('rat', 180)
            originalPosition = world.players[1].position + util.vector3(180, 0, 0)
            transition(2)
        elseif stage == 2 and elapsed - mark > 1 then
            assert(not original.enabled, 'World Randomizer did not replace original creature')
            assert(not I.AshenLoot.getState().elites[original.id], 'Disabled original was promoted')
            for _, actor in ipairs(world.activeActors) do
                if types.Creature.objectIsInstance(actor) and actor.enabled and actor.id ~= original.id
                    and (actor.position - originalPosition):length() < 150 then replacement = actor; break end
            end
            assert(replacement, 'Replacement creature was not found')
            assert(I.AshenLoot.eligible(replacement), 'Randomized replacement is not eligible')
            replacement:addScript('scripts/ashenloot_test/actor.lua')
            replacement:sendEvent('AshenLoot_TestHostile')
            pass('actual World Randomizer replacement retained; original excluded: ' .. replacement.recordId)
            -- Use a real Tamriel Data creature with a mainland-style record ID.
            local trId
            for _, rec in pairs(types.Creature.records) do
                if rec.id:match('^t_') and rec.type == types.Creature.TYPE.Creatures and not rec.mwscript and not rec.isEssential then
                    local offers = false
                    for _, offered in pairs(rec.servicesOffered or {}) do offers = offers or offered end
                    if not offers then trId = rec.id; break end
                end
            end
            assert(trId, 'No Tamriel Data creature fixture found')
            -- Switch off further replacements so we can inspect the exact mainland reference, retaining the mod's event handlers.
            core.sendGlobalEvent('mwrbd_updateSettings', {creature = {randomize = false}})
            transition(3)
        elseif stage == 3 and elapsed - mark > 1 then
            local trId
            for _, rec in pairs(types.Creature.records) do
                if rec.id:match('^t_') and rec.type == types.Creature.TYPE.Creatures and not rec.mwscript and not rec.isEssential then
                    local offers = false
                    for _, v in pairs(rec.servicesOffered or {}) do offers = offers or v end
                    if not offers then trId = rec.id; break end
                end
            end
            mainland = creatureFixture(trId, 350)
            mainland:sendEvent('AshenLoot_TestHostile')
            transition(4)
        elseif stage == 4 and elapsed - mark > 0.7 then
            mainland:sendEvent('AshenLoot_TestStatus')
            assert(not I.AshenLoot.getState().elites[mainland.id], 'Promoted before settling delay')
            mainland:sendEvent('mwr_actor_setDynamicBaseStats', {health = 80})
            mainland:sendEvent('AshenLoot_TestHostile')
            transition(5)
        elseif stage == 5 and elapsed - mark > 3.5 then
            local elite = eliteEffect(mainland)
            print('[AshenLoot HEALTH] base=' .. types.Actor.stats.dynamic.health(mainland).base .. ' modifier=' .. types.Actor.stats.dynamic.health(mainland).modifier .. ' current=' .. types.Actor.stats.dynamic.health(mainland).current .. ' reference=' .. elite.healthReference .. ' bonus=' .. elite.healthBonus)
            assert(types.Actor.stats.dynamic.health(mainland).base == 80, 'Promotion changed randomized base health')
            assert(elite.healthReference == 80, 'Promotion used stale health')
            assert(elite.name:find(mainland.type.record(mainland).name, 1, true), 'Creature name not preserved')
            eliteEffect(replacement)
            pass('real Tamriel Data creature promoted after delayed stat randomization: ' .. mainland.recordId)
            mainland:sendEvent('mwr_actor_setDynamicBaseStats', {health = 160})
            transition(6)
        elseif stage == 6 and elapsed - mark > 3.5 then
            local elite = eliteEffect(mainland)
            assert(elite.healthReference == 160, 'Health bonus did not track later reroll')
            assert(types.Actor.stats.dynamic.health(mainland).base == 160, 'Base stat overwritten by promotion')
            pass('later World Randomizer health reroll preserved and recalibrated elite health modifier')
            cfg:set('elitePercent', 0)
            fast = creatureFixture('rat', 500)
            transition(65)
        elseif stage == 65 and elapsed - mark > 0.35 then
            fast:sendEvent('AshenLoot_TestFastKill')
            transition(7)
        elseif stage == 7 and elapsed - mark > 3.5 then
            assert(types.Actor.isDead(fast), 'Fast-kill fixture survived')
            assert(I.AshenLoot.getState().rewards[fast.id], 'Fast ordinary kill received no loot roll')
            local found = false
            for _, item in ipairs(types.Actor.inventory(fast):getAll()) do
                found = found or I.AshenLoot.getState().records[item.recordId] ~= nil
            end
            assert(found, '100% drop preset did not produce ordinary loot')
            assert(not I.AshenLoot.getState().elites[fast.id], 'Fast corpse incorrectly promoted')
            pass('100% ordinary drop chance works on kills before promotion delay')
            mainland:sendEvent('AshenLoot_TestKill')
            transition(8)
        elseif stage == 8 and elapsed - mark > 3 then
            beforeLoot = #types.Actor.inventory(mainland):getAll()
            assert(I.AshenLoot.getState().rewards[mainland.id], 'Elite reward missing')
            local itemsData = storage.globalSection('MWR_By_Diject'):getCopy('itemsData')
            local ownCount = 0
            for _, item in ipairs(types.Actor.inventory(mainland):getAll()) do
                if I.AshenLoot.getState().records[item.recordId] then
                    ownCount = ownCount + 1
                    assert(not itemsData.items[item.recordId], 'Generated item entered randomizer pool')
                end
            end
            assert(ownCount > 0, 'Elite generated item missing')
            mainland:sendEvent('mwr_actor_randomizeInventory', {itemsData = itemsData, config = {item = {randomize = true}}})
            transition(9)
        elseif stage == 9 and elapsed - mark > 2 then
            local ownCount = 0
            for _, item in ipairs(types.Actor.inventory(mainland):getAll()) do
                if I.AshenLoot.getState().records[item.recordId] then ownCount = ownCount + 1 end
            end
            assert(ownCount > 0, 'World Randomizer removed generated loot')
            pass('generated corpse loot survives actual World Randomizer inventory pass')
            cfg:set('preset', 'Testing')
            transition(10)
            types.Player.sendMenuEvent(world.players[1], 'AshenLoot_TestSave')
        elseif stage == 10 and reloaded and elapsed - mark > 3.5 then
            eliteEffect(replacement)
            assert(C.eliteChance == 0.5 and C.normalDropChance == 1, 'Settings did not persist')
            assert(I.AshenLoot.getState().rewards[mainland.id], 'Reward state did not persist')
            local before = #types.Actor.inventory(mainland):getAll()
            I.AshenLoot.test.death(mainland)
            assert(#types.Actor.inventory(mainland):getAll() == before, 'Duplicate loot after reload')
            pass('combined-mod save/reload preserved living elite, settings, loot, and reward deduplication')
            core.quit()
        elseif stage > 0 and elapsed - mark > 20 then error('Stage timeout: ' .. stage) end
    end)
    if not ok then print('[AshenLoot COMPAT] FAIL stage ' .. stage .. ': ' .. tostring(err)); core.quit() end
end
return {engineHandlers = {onUpdate = onUpdate,
    onSave = function() return {elapsed = elapsed, mark = mark, stage = stage, original = original,
        replacement = replacement, mainland = mainland, fast = fast, originalPosition = originalPosition, beforeLoot = beforeLoot} end,
    onLoad = function(s)
        elapsed, mark, stage = s.elapsed, s.mark, s.stage
        original, replacement, mainland, fast = s.original, s.replacement, s.mainland, s.fast
        originalPosition, beforeLoot, reloaded = s.originalPosition, s.beforeLoot, true
    end,
}}
