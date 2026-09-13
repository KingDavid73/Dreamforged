-- Receivers include NPCs so elite attacks also affect guards and companions.
-- No actor replacement or changes to the native attack's physical damage.
local I = require('openmw.interfaces')
local core = require('openmw.core')
local self = require('openmw.self')
local C = require('scripts.ashenloot.config')
I.Combat.addOnHitHandler(function(attack)
    local source = attack.sourceType
    if C.enabled and attack.successful and attack.attacker
            and (source == I.Combat.ATTACK_SOURCE_TYPES.Melee or source == I.Combat.ATTACK_SOURCE_TYPES.Ranged) then
        core.sendGlobalEvent('AshenLoot_PhysicalHit', {attacker = attack.attacker, target = self,
            melee = source == I.Combat.ATTACK_SOURCE_TYPES.Melee})
    end
end)
return {}
