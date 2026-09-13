local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local function hostile()
    I.AI.startPackage {type = 'Combat', target = nearby.players[1]}
    I.Combat.onHit {attacker = nearby.players[1], successful = true, damage = {health = 0},
        strength = 0, sourceType = I.Combat.ATTACK_SOURCE_TYPES.Melee}
end
return {eventHandlers = {
    AshenLoot_TestEquip = function(event)
        types.Actor.setEquipment(self,{[types.Actor.EQUIPMENT_SLOT.CarriedRight]=event.weapon,
            [types.Actor.EQUIPMENT_SLOT.Cuirass]=event.armor})
        types.Actor.stats.dynamic.magicka(self).base=100
        types.Actor.stats.dynamic.magicka(self).current=100
        types.NPC.stats.skills.destruction(self).base=60
        types.NPC.stats.skills.longblade(self).base=60
    end,
    AshenLoot_TestReceiveHit = function(event)
        I.Combat.onHit {attacker = event.attacker, successful = event.successful ~= false,
            damage = {health = 0}, strength = 0, sourceType = event.source or I.Combat.ATTACK_SOURCE_TYPES.Melee}
    end,
    AshenLoot_TestVitals = function()
        types.Actor.stats.dynamic.health(self).base = 500
        types.Actor.stats.dynamic.health(self).current = 300
        types.Actor.stats.dynamic.magicka(self).base = 100
        types.Actor.stats.dynamic.magicka(self).current = 100
        types.Actor.stats.dynamic.fatigue(self).base = 300
        types.Actor.stats.dynamic.fatigue(self).current = 300
    end,
    AshenLoot_TestKill = function() types.Actor.stats.dynamic.health(self).current = 0 end,
    AshenLoot_TestHostile = hostile,
    AshenLoot_TestStatus = function()
        print('[AshenLoot STATUS] ' .. self.recordId .. ' ' .. require('openmw_aux.util').deepToString(I.AshenLootActor and I.AshenLootActor.getStatus()))
    end,
    AshenLoot_TestFastKill = function()
        I.Combat.onHit {attacker = nearby.players[1], successful = true, damage = {health = 10000},
            strength = 1, sourceType = I.Combat.ATTACK_SOURCE_TYPES.Melee}
    end,
}}
