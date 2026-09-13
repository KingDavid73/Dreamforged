local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local I = require('openmw.interfaces')
local R = require('scripts.ashenloot.rules')
local Records = require('scripts.ashenloot.records')
local elapsed, stage, creature = 0, 0, nil
local loaded = false
local function check(condition, message) assert(condition, message) end
local function first()
    local p = world.players[1]
    check(not I.AshenLoot.eligible(p), 'Player must be excluded')
    local a, b = R.rng('reproducible'), R.rng('reproducible')
    for _ = 1, 100 do check(a(100) == b(100), 'RNG unstable') end
    local distribution = {0, 0, 0, 0, 0, 0}
    local random = R.rng('distribution')
    for _ = 1, 10000 do local t = R.rarity(random); distribution[t] = distribution[t] + 1 end
    for tier = 1, 6 do check(distribution[tier] > 0, 'Unreachable rarity') end
    check(R.rarity(function() return 99 end, 1, 0)==6, 'Relic rarity is unreachable')
    check(R.rarity(function() return 70 end, 1, 30)>=5, 'Rarity bonus does not improve rolls')
    check(R.rarity(function() return 59 end, 1, 40)==5, 'Rarity overflow must not collapse into Relic')
    check(R.rarity(function() return 89 end, 1, 40)==6, 'Promotion bonus does not widen Relic chance')
    for n = 1, 1000 do
        local elite = R.elite(tostring(n), 'Test')
        check(elite.modifiers[1] ~= elite.modifiers[2], 'Duplicate enemy modifiers')
        check(elite.name:find(R.elites[elite.modifiers[1]].epithet, 1, true), 'Name does not describe primary effect')
        local spec = R.item('tier-gates:' .. n, 1)
        check((R.prefixes[spec.prefix].minTier or 1) <= spec.tier, 'Prefix tier gate')
        check((R.suffixes[spec.suffix].minTier or 1) <= spec.tier, 'Suffix tier gate')
    end
    check(R.freshRarity({{lvl = 5}, {lvl = 2}}) == 5, 'Fresh Loot rarity mapping')
    -- Validate all affix combinations against actual record constructors, not mocks.
    for _, pair in ipairs({{types.Weapon, 'iron longsword'}, {types.Armor, 'iron_cuirass'},
        {types.Clothing, 'common_ring_01'}, {types.Weapon, 'chitin short bow'}, {types.Weapon, 'iron war axe'}}) do
        local base = pair[1].record(pair[2])
        check(base ~= nil, 'Missing fixture ' .. pair[2])
        for pre = 1, #R.prefixes do
            for suf = 1, #R.suffixes do
                local id, meta = Records.makeItem(base, pair[1], {tier = 4, power = 3, prefix = pre, suffix = suf, roll = 2})
                local record = pair[1].record(id)
                check(record.name == meta.name and record.enchant, 'Item record creation failed')
                local enchant = core.magic.enchantments.records[record.enchant]
                check(#enchant.effects >= (R.prefixes[pre].nativeWeapon==false and pair[1]==types.Weapon and 1 or 2), 'Enchantment effects missing')
                if pair[2] == 'iron war axe' then check(enchant.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike, 'Axe enchant type') end
                if pair[2] == 'chitin short bow' then check(enchant.type == core.magic.ENCHANTMENT_TYPE.CastOnUse, 'Bow enchant type') end
                if pair[2] == 'chitin short bow' then check(enchant.effects[1].range == core.magic.RANGE.Target, 'Bow spell is not ranged') end
                if pair[1] ~= types.Weapon then
                    check(enchant.effects[1].id == R.prefixes[pre].guard, 'Wearable prefix mismatch')
                    check(enchant.effects[2].id == R.suffixes[suf].guard, 'Wearable suffix mismatch')
                else
                    local offset=0
                    if R.prefixes[pre].nativeWeapon~=false then
                        check(enchant.effects[1].id == R.prefixes[pre].effect, 'Weapon prefix mismatch')
                        offset=1
                    end
                    check(enchant.effects[offset+1].id == R.suffixes[suf].effect, 'Weapon suffix mismatch')
                end
            end
        end
    end
    for tier = 1, 6 do
        local id = I.AshenLoot.test.giveLoot(p, 'test-tier:' .. tier, tier, 'iron longsword', tier)
        check(I.AshenLoot.getState().records[id].tier == tier, 'Forced rarity failed')
    end
    local forcedArmor=I.AshenLoot.test.giveLoot(p,'test-forced-armor',3,'iron_cuirass',3)
    check(forcedArmor and types.Armor.record(forcedArmor),'Forced armor base failed typed lookup')
    local state = I.AshenLoot.getState()
    local count = state.count
    I.AshenLoot.test.giveLoot(p, 'test-tier:1', 1, 'iron longsword', 1)
    check(state.count == count, 'Identical item roll must reuse record')
    if I.FreshLoot then I.FreshLoot.test.createItem('iron longsword', 1, 'damageMaxAdd', 3) end
    creature = world.createObject('rat', 1)
    creature:teleport(p.cell, p.position + require('openmw.util').vector3(150, 0, 0))
    print('[AshenLoot TEST] PASS: deterministic rules, ' .. (6 * #R.prefixes * #R.suffixes) .. ' item/enchantment combinations, six tiers, cache reuse')
end
local function second()
    check(I.AshenLoot.eligible(creature), 'Generic rat should be eligible')
    I.AshenLoot.test.encounter({actor = creature, force = true})
end
local function third()
    local state = I.AshenLoot.getState()
    local elite = state.elites[creature.id]
    check(elite and types.Actor.spells(creature)[elite.spellId], 'Elite ability was not applied')
    local effect = R.elites[elite.modifiers[1]]
    local active = types.Actor.activeEffects(creature):getEffect(effect.effect, effect.attribute)
    check(active.magnitude == effect.magnitude, 'Elite effect magnitude mismatch')
    I.AshenLoot.test.snapshot()
    world.players[1]:sendEvent('AshenLoot_TestUI')
    creature:addScript('scripts/ashenloot_test/actor.lua')
    creature:sendEvent('AshenLoot_TestKill')
    print('[AshenLoot TEST] PASS: original creature reference retained; actual elite ability active')
end
local function update(dt)
    elapsed = elapsed + dt
    local ok, err = pcall(function()
        if stage == 0 and elapsed > 1 then stage = 1; first()
        elseif stage == 1 and elapsed > 2 then stage = 2; second()
        elseif stage == 2 and elapsed > 4 then stage = 3; third()
        elseif stage == 3 and elapsed > 6 then
            stage = 4
            local before = #types.Actor.inventory(creature):getAll()
            check(I.AshenLoot.getState().rewards[creature.id], 'Death reward not processed')
            check(before > 0, 'Corpse loot missing')
            local elite = I.AshenLoot.getState().elites[creature.id]
            local trophy = R.trophies[elite.modifiers[1]]
            local trophyFound = false
            for _, item in ipairs(types.Actor.inventory(creature):getAll()) do
                local meta = I.AshenLoot.getState().records[item.recordId]
                if meta then
                    local weapon = types.Weapon.objectIsInstance(item)
                    local name = trophy.prefix and (weapon and R.prefixes[trophy.prefix].name or R.prefixes[trophy.prefix].defensiveName)
                        or ((not weapon and R.suffixes[trophy.suffix].defensiveName) or R.suffixes[trophy.suffix].name)
                    check(meta.name:find(name, 1, true), 'Trophy did not match elite primary modifier')
                    trophyFound = true
                end
            end
            check(trophyFound, 'No thematic elite trophy')
            I.AshenLoot.test.death(creature)
            check(#types.Actor.inventory(creature):getAll() == before, 'Duplicate death reward')
            print('[AshenLoot TEST] PASS: corpse reward and duplicate-event protection')
        elseif stage == 4 and elapsed > 8 then
            stage = 5
            types.Player.sendMenuEvent(world.players[1], 'AshenLoot_TestSave')
        elseif stage == 5 and loaded and elapsed > 10 then
            local state = I.AshenLoot.getState()
            check(state.rewards[creature.id], 'Reward tracking lost on reload')
            for id, meta in pairs(state.records) do
                local rec = types.Weapon.record(id) or types.Armor.record(id) or types.Clothing.record(id)
                check(rec and rec.name == meta.name, 'Dynamic item lost on reload')
                if meta.tier>1 then check(core.magic.enchantments.records[rec.enchant], 'Dynamic enchantment lost on reload') end
            end
            local before = #types.Actor.inventory(creature):getAll()
            I.AshenLoot.test.death(creature)
            check(#types.Actor.inventory(creature):getAll() == before, 'Reload duplicated reward')
            print('[AshenLoot TEST] PASS: save/reload preserved items, enchantments, elite identity and reward tracking')
            core.quit()
        elseif elapsed > 30 then error('Save/reload test timed out') end
    end)
    if not ok then print('[AshenLoot TEST] FAIL: ' .. tostring(err)); core.quit() end
end
return {engineHandlers = {onUpdate = update,
    onSave = function() return {elapsed = elapsed, stage = stage, creature = creature} end,
    onLoad = function(data) elapsed, stage, creature = data.elapsed, data.stage, data.creature; loaded = true end,
}, eventHandlers = {AshenLoot_TestUIResult = function(data)
    print('[AshenLoot TEST] ' .. (data.ok and 'PASS: player inventory UI created' or 'FAIL: ' .. data.error))
end}}
