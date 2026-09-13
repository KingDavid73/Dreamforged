local core, types, world = require('openmw.core'), require('openmw.types'), require('openmw.world')
local I, util = require('openmw.interfaces'), require('openmw.util')
local R, Records = require('scripts.ashenloot.rules'), require('scripts.ashenloot.records')
local cfg = require('openmw.storage').globalSection('SettingsAshenLoot')
local elapsed, mark, stage, fixtures, savedCooldown, loaded = 0, 0, 0, {}, nil, false
local custom={}
local function pass(s) print('[AshenLoot EFFECTS] PASS: ' .. s) end
local function nextStage(s) stage, mark = s, elapsed end
local function create(offset)
    local p = world.players[1]
    local a = world.createObject('rat')
    a:teleport(p.cell, p.position + util.vector3(offset, 250, 0))
    a:addScript('scripts/ashenloot_test/actor.lua')
    a:sendEvent('AshenLoot_TestVitals')
    return a
end
local function hit(index, successful, source)
    local f = fixtures[index]
    local p = R.elites[index].proc
    local receiver, attacker = f.target, f.actor
    if p and p.retaliate then receiver, attacker = f.actor, f.target end
    receiver:sendEvent('AshenLoot_TestReceiveHit', {attacker=attacker, successful=successful, source=source})
end
local function update(dt)
    if dt <= 0 then return end
    elapsed = elapsed + dt
    local ok, err = pcall(function()
        if stage == 0 and elapsed > 1 then
            cfg:set('preset', 'Custom'); cfg:set('elitePercent', 0); cfg:set('dropPercent', 0)
            cfg:set('creatureVariety',0);cfg:set('extraEncounters',false);cfg:set('progression',false)
            world.players[1]:sendEvent('AshenLoot_TestFreezeAI')
            for index, mod in ipairs(R.elites) do
                local actor, target = create(index * 30), create(index * 30 + 10)
                local elite = R.elite('effects:' .. index, 'Rat')
                elite.modifiers, elite.tier, elite.healthScale = {index}, 1, 1.35
                I.AshenLoot.getState().elites[actor.id] = elite
                fixtures[index] = {actor=actor, target=target}
            end
            nextStage(1)
        elseif stage == 1 and elapsed - mark > 1 then
            for _, f in ipairs(fixtures) do I.AshenLoot.test.encounter({actor=f.actor, force=true}) end
            nextStage(2)
        elseif stage == 2 and elapsed - mark > 3 then
            for index, f in ipairs(fixtures) do
                local mod = R.elites[index]
                assert(types.Actor.activeEffects(f.actor):getEffect(mod.effect, mod.attribute).magnitude == mod.magnitude,
                    'Missing native ability: ' .. mod.name)
                f.hp = types.Actor.stats.dynamic.health(f.target).current
                f.casterHp = types.Actor.stats.dynamic.health(f.actor).current
                hit(index, false, 'melee')
                hit(index, true, 'magic')
            end
            pass('all 16 defined enemy abilities applied through native effects')
            nextStage(3)
        elseif stage == 3 and elapsed - mark > 0.5 then
            assert(next(I.AshenLoot.getState().procs) == nil, 'Miss or magic hit triggered a proc')
            for index in ipairs(fixtures) do hit(index, true, 'melee'); hit(index, true, 'melee') end
            nextStage(4)
        elseif stage == 4 and elapsed - mark > 0.5 then
            for index, f in ipairs(fixtures) do
                local mod = R.elites[index]
                if mod.proc then
                    local id = I.AshenLoot.getState().procs[index]
                    if not (id and types.Actor.activeSpells(f.target):isSpellActive(id)) then
                        print('[AshenLoot EFFECTS] diagnostic '..index..' id='..tostring(id)..' dt='..(elapsed-mark)..' hp='..types.Actor.stats.dynamic.health(f.target).current)
                        print(require('openmw_aux.util').deepToString(I.AshenLoot.getState().elites[f.actor.id]))
                        for k,v in pairs(I.AshenLoot.getState().procs) do print('proc key '..tostring(k)..' = '..v) end
                        for _,m in ipairs(I.AshenLoot.getState().elites[f.actor.id].modifiers) do print('modifier '..m) end
                        print('eligible '..tostring(I.AshenLoot.eligible(f.actor))..' actor '..f.actor.id..' target '..f.target.id..' enabled '..tostring(f.actor.enabled)..' '..tostring(f.target.enabled))
                    end
                    assert(id and types.Actor.activeSpells(f.target):isSpellActive(id), 'Missing active proc: ' .. mod.name)
                    local count = 0
                    for _, active in pairs(types.Actor.activeSpells(f.target)) do
                        if active.id == id then count = count + 1; assert(active.caster == f.actor, 'Lost caster attribution') end
                    end
                    assert(count == 1, 'Repeated hit stacked the same proc')
                end
            end
            savedCooldown = I.AshenLoot.getState().cooldowns[fixtures[4].actor.id][4]
            pass('real Combat hit handlers apply all 14 attack/retaliation spells; misses/magic excluded; no rapid stacking')
            nextStage(5)
        elseif stage == 5 and elapsed - mark > 2.8 then
            for _, index in ipairs({1, 2, 3, 4, 8}) do
                local f = fixtures[index]
                assert(types.Actor.stats.dynamic.health(f.target).current < f.hp - 2, 'Damage had no gameplay effect: ' .. index)
            end
            assert(types.Actor.stats.dynamic.health(fixtures[8].actor).current > fixtures[8].casterHp + 2, 'Absorb Health did not heal its caster')
            assert(types.Actor.stats.dynamic.magicka(fixtures[10].target).current < 95, 'Absorb Magicka did not drain')
            assert(types.Actor.stats.dynamic.fatigue(fixtures[5].target).current < 295, 'Retaliation did not drain fatigue')
            pass('actual fire/frost/shock/poison damage, lifesteal healing, magicka drain and fatigue retaliation')
            local resist = world.createRecord(core.magic.spells.createRecordDraft {name='Test poison immunity',
                type=core.magic.SPELL_TYPE.Ability, cost=0, isAutocalc=false, effects={Records.effect('resistpoison',100)}})
            types.Actor.spells(fixtures[4].target):add(resist.id)
            nextStage(6)
        elseif stage == 6 and elapsed - mark > 2 then
            fixtures[4].hp = types.Actor.stats.dynamic.health(fixtures[4].target).current
            hit(4, true, 'melee')
            nextStage(7)
        elseif stage == 7 and elapsed - mark > 3.5 then
            assert(types.Actor.stats.dynamic.health(fixtures[4].target).current >= fixtures[4].hp - 0.01, 'Poison bypassed immunity')
            pass('native poison resistance prevents damage')
            cfg:set('enabled', false)
            savedCooldown = I.AshenLoot.getState().cooldowns[fixtures[1].actor.id][1]
            hit(1, true, 'melee')
            nextStage(8)
        elseif stage == 8 and elapsed - mark > 0.5 then
            assert(I.AshenLoot.getState().cooldowns[fixtures[1].actor.id][1] == savedCooldown, 'Disabled mod triggered a proc')
            cfg:set('enabled', true)
            savedCooldown = I.AshenLoot.getState().cooldowns[fixtures[4].actor.id][4]
            pass('disable toggle suppresses new procs')
            local player=world.players[1]
            custom.target,custom.chain,custom.striker=create(600),create(650),create(700)
            local function item(kind,base,spec)
                local id,meta=Records.makeItem(kind.record(base),kind,spec)
                I.AshenLoot.getState().records[id]=meta
                local object=world.createObject(id,1);object:moveInto(types.Actor.inventory(player));return object
            end
            custom.echoWeapon=item(types.Weapon,'iron longsword',{tier=4,power=12,level=30,roll=3,style=2,prefix=17,suffix=16})
            custom.echoBow=item(types.Weapon,'chitin short bow',{tier=4,power=12,level=30,roll=3,style=2,prefix=17,suffix=16})
            custom.echoArmor=item(types.Armor,'iron_cuirass',{tier=4,power=12,level=30,roll=3,style=2,prefix=1,suffix=16})
            custom.commandWeapon=item(types.Weapon,'iron longsword',{tier=4,power=12,level=30,roll=3,style=2,prefix=15,suffix=13})
            custom.thornArmor=item(types.Armor,'iron_cuirass',{tier=4,power=12,level=30,roll=3,style=2,prefix=1,suffix=15})
            player:sendEvent('AshenLoot_TestEquip',{weapon=custom.echoWeapon,armor=custom.echoArmor})
            nextStage(9)
        elseif stage == 9 and elapsed-mark>0.7 then
            local player=world.players[1]
            custom.targetHp=types.Actor.stats.dynamic.health(custom.target).current
            custom.chainHp=types.Actor.stats.dynamic.health(custom.chain).current
            custom.strikerHp=types.Actor.stats.dynamic.health(custom.striker).current
            I.AshenLoot.test.physicalHit({attacker=player,target=custom.target,melee=true,forceItemProcs=true})
            I.AshenLoot.test.physicalHit({attacker=custom.striker,target=player,melee=true,forceItemProcs=true})
            nextStage(10)
        elseif stage == 10 and elapsed-mark>2 then
            assert(types.Actor.stats.dynamic.health(custom.target).current<custom.targetHp,'Chance-on-hit elemental spell did not damage target')
            assert(types.Actor.stats.dynamic.health(custom.chain).current<custom.chainHp,'Chain lightning did not reach nearby hostile')
            assert(types.Actor.stats.dynamic.health(custom.striker).current<custom.strikerHp,'When-struck nova did not damage attacker')
            world.players[1]:sendEvent('AshenLoot_TestEquip',{weapon=custom.commandWeapon,armor=custom.thornArmor})
            nextStage(11)
        elseif stage == 11 and elapsed-mark>0.7 then
            local player=world.players[1]
            custom.targetHp=types.Actor.stats.dynamic.health(custom.target).current
            custom.strikerHp=types.Actor.stats.dynamic.health(custom.striker).current
            I.AshenLoot.test.physicalHit({attacker=player,target=custom.target,melee=true,forceItemProcs=true})
            I.AshenLoot.test.physicalHit({attacker=custom.striker,target=player,melee=true,forceItemProcs=true})
            nextStage(12)
        elseif stage == 12 and elapsed-mark>2 then
            assert(types.Actor.stats.dynamic.health(custom.target).current<custom.targetHp,'Crushing blow did not damage target')
            assert(types.Actor.activeEffects(custom.target):getEffect('commandcreature').magnitude>=100,'Command proc did not affect creature')
            assert(types.Actor.stats.dynamic.health(custom.striker).current<custom.strikerHp,'Thorns did not damage melee attacker')
            pass('thorns, chance casts, safe Command, crushing blow and chain lightning work through equipped generated gear')
            world.players[1]:sendEvent('AshenLoot_TestEquip',{weapon=custom.echoBow,armor=custom.echoArmor})
            nextStage(13)
        elseif stage == 13 and elapsed-mark>0.7 and not loaded then
            custom.targetHp=types.Actor.stats.dynamic.health(custom.target).current
            I.AshenLoot.test.physicalHit({attacker=world.players[1],target=custom.target,melee=false,forceItemProcs=true})
            nextStage(14)
        elseif stage == 14 and elapsed-mark>2 and not loaded then
            assert(types.Actor.stats.dynamic.health(custom.target).current<custom.targetHp,'Equipped bow did not trigger ranged on-hit proc')
            pass('generated bow procs forward through successful ranged hits')
            types.Player.sendMenuEvent(world.players[1], 'AshenLoot_TestSave')
            nextStage(15)
        elseif stage == 15 and loaded and elapsed - mark > 2 then
            assert(I.AshenLoot.getState().cooldowns[fixtures[4].actor.id][4] == savedCooldown, 'Cooldown state lost on reload')
            for index, f in ipairs(fixtures) do
                assert(I.AshenLoot.getState().elites[f.actor.id].rulesVersion == 3, 'Rules identity lost')
                if R.elites[index].proc then assert(core.magic.spells.records[I.AshenLoot.getState().procs[index]], 'Proc spell lost') end
            end
            pass('save/reload preserves proc records, cooldowns and new elite identities')
            core.quit()
        elseif elapsed - mark > 25 then error('Timed out stage ' .. stage) end
    end)
    if not ok then print('[AshenLoot EFFECTS] FAIL stage ' .. stage .. ': ' .. tostring(err)); core.quit() end
end
return {engineHandlers={onUpdate=update,
    onSave=function() return {elapsed=elapsed, mark=mark, stage=stage, fixtures=fixtures, savedCooldown=savedCooldown} end,
    onLoad=function(s) elapsed, mark, stage, fixtures, savedCooldown, loaded = s.elapsed, s.mark, s.stage, s.fixtures, s.savedCooldown, true end,
}}
