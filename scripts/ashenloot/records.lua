local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local R = require('scripts.ashenloot.rules')
local M = {}
local function effect(id, magnitude, range, duration, attribute)
    local e = { id = id, magnitudeMin = magnitude, magnitudeMax = magnitude,
        range = range or core.magic.RANGE.Self, duration = duration or 0, area = 0 }
    if attribute then e.affectedAttribute = attribute end
    return e
end
M.effect = effect
function M.ability(data)
    local effects = {}
    for _, index in ipairs(data.modifiers) do
        local m = R.elites[index]
        effects[#effects + 1] = effect(m.effect, math.floor(m.magnitude * (data.effectScale or 1)), nil, nil, m.attribute)
        if m.extra then
            effects[#effects + 1] = effect(m.extra.effect, m.extra.magnitude, nil, nil, m.extra.attribute)
        end
    end
    return world.createRecord(core.magic.spells.createRecordDraft {
        name = 'Dreamforged: ' .. data.name, type = core.magic.SPELL_TYPE.Ability,
        cost = 0, isAutocalc = false, effects = effects,
    }).id
end
function M.proc(index, scale)
    local mod = R.elites[index]
    local p = assert(mod.proc)
    return world.createRecord(core.magic.spells.createRecordDraft {
        name = mod.name, type = core.magic.SPELL_TYPE.Spell, cost = 0, isAutocalc = false,
        effects = {effect(p.effect, p.effect=='silence' and p.magnitude or math.floor(p.magnitude*(scale or 1)), core.magic.RANGE.Touch, p.duration)},
    }).id
end
function M.makeItem(base, kind, spec)
    local pre, suf = R.prefixes[spec.prefix], R.suffixes[spec.suffix]
    local itemLevel = spec.dropLevel or spec.level or (spec.power * 4)
    -- Native on-strike bow enchants do not work; their on-use spells are ranged.
    local melee = kind == types.Weapon and base.type <= types.Weapon.TYPE.AxeTwoHand
        and base.type ~= types.Weapon.TYPE.BluntTwoWide
    local weapon = kind == types.Weapon
    if spec.tier==1 then
        local name='[Common] '..base.name
        local record=world.createRecord(kind.createRecordDraft{template=base,name=name})
        return record.id,{name=name,tier=1,rarity='Common',level=itemLevel,dropLevel=itemLevel,
            baseQualityTier=spec.baseQualityTier or 1,
            details={'Base quality tier '..tostring(spec.baseQualityTier or 1)..'/8','No affixes','Drop level '..itemLevel},
            source='Dreamforged',baseId=base.id,itemType=weapon and 'weapon' or 'wearable',procs={}}
    end
    local usePrefix=spec.tier>=3 or (spec.roll%2==1)
    local useSuffix=spec.tier>=3 or not usePrefix
    local magnitude = math.floor((spec.power + spec.tier + spec.roll) * 1.2 + 0.5)
    local range = weapon and (melee and core.magic.RANGE.Touch or core.magic.RANGE.Target) or core.magic.RANGE.Self
    local duration = weapon and pre.duration or 0
    local effects = {}
    if usePrefix and not (weapon and pre.nativeWeapon == false) then
        local amount=weapon and (pre.fixed or math.max(1, math.floor(magnitude * (pre.factor or 1))))
            or (pre.guard == 'fortifymagicka' and magnitude * 2 or math.min(12, magnitude))
        effects[#effects+1]=effect(weapon and pre.effect or pre.guard,amount,range,duration)
    end
    if useSuffix and suf.effect then
        local amount = math.max(2, math.floor(magnitude / 2))
        if suf.attribute then amount=math.floor(6+(itemLevel-1)*0.65+(spec.tier-1)*2) end
        if not weapon then
            if suf.guard == 'restorefatigue' then amount = 1
            elseif suf.guard == 'feather' then amount = magnitude * 3
            elseif suf.guard == 'fortifyhealth' or suf.guard == 'fortifymagicka' then amount = magnitude * 2 end
        end
        effects[#effects + 1] = effect(weapon and suf.effect or suf.guard,
            amount, (weapon and suf.self) and core.magic.RANGE.Self or range,
            weapon and (suf.duration or 1) or 0, suf.attribute)
    end
    if spec.tier >= 4 then
        -- A useful action/resource bonus, rather than another situational ward.
        effects[#effects + 1] = effect(weapon and 'restorefatigue' or 'fortifyattribute',
            spec.tier, core.magic.RANGE.Self, weapon and 2 or 0, not weapon and 'agility' or nil)
    end
    if spec.tier >= 5 then
        effects[#effects + 1] = effect(weapon and 'restorehealth' or 'fortifyattribute',
            weapon and math.max(1, math.floor(magnitude / 3)) or math.floor(magnitude / 2),
            core.magic.RANGE.Self, weapon and 2 or 0, not weapon and 'strength' or nil)
    end
    if spec.tier >= 6 then
        effects[#effects + 1] = effect(weapon and 'fortifyattack' or 'sanctuary',
            weapon and 10 or 12, core.magic.RANGE.Self, weapon and 3 or 0)
        effects[#effects + 1] = effect(weapon and 'weaknesstomagicka' or 'resistmagicka',
            weapon and 18 or 15, weapon and core.magic.RANGE.Touch or core.magic.RANGE.Self,
            weapon and 4 or 0)
        -- Relics retain the iconic template's native enchantment in addition to
        -- their six Ashen effects; the original record itself is never changed.
        local native=base.enchant and core.magic.enchantments.records[base.enchant]
        if native then
            for _,e in ipairs(native.effects) do
                local copied={id=e.id,magnitudeMin=e.magnitudeMin,magnitudeMax=e.magnitudeMax,
                    range=e.range,duration=e.duration,area=e.area}
                if e.affectedAttribute then copied.affectedAttribute=e.affectedAttribute end
                if e.affectedSkill then copied.affectedSkill=e.affectedSkill end
                effects[#effects+1]=copied
            end
        end
    end
    local enchantment = world.createRecord(core.magic.enchantments.createRecordDraft {
        type = weapon and (melee and core.magic.ENCHANTMENT_TYPE.CastOnStrike
            or core.magic.ENCHANTMENT_TYPE.CastOnUse) or core.magic.ENCHANTMENT_TYPE.ConstantEffect,
        cost = weapon and 1 or 0, charge = weapon and 10000 or 0,
        isAutocalc = false, effects = effects,
    })
    local rarity = R.rarities[spec.tier]
    local affixName=(usePrefix and ((weapon and pre.name or pre.defensiveName)..' ') or '')..base.name
        ..(useSuffix and (' '..((not weapon and suf.defensiveName) or suf.name)) or '')
    local draft = {template = base, name = '[' .. R.rarities[spec.tier].name .. '] ' .. affixName,
        enchant = enchantment.id, value = math.floor(base.value * (1 + spec.tier * 0.2) + magnitude * 8)}
    local details = {}
    details[#details + 1] = 'Base quality tier ' .. tostring(spec.baseQualityTier or 1) .. '/8'
    local bonus = 0.05 * (spec.tier + spec.roll) + math.min(0.45, math.max(0, itemLevel-1)*0.0075)
    if weapon then
        draft.isMagical = true
        local style = spec.style or 2
        local styleName = ({'Quick','Balanced','Heavy'})[style]
        local styleFactor=({0.9,1,1.15})[style]
        draft.speed = base.speed * ({1.15,1,0.9})[style]
        local mult = (1 + bonus + (useSuffix and suf.property == 'damage' and bonus or 0)
            + math.min(1.5, (spec.power - 1) * 0.035)) * styleFactor
        local nativeMax=math.max(base.chopMaxDamage or 1,base.slashMaxDamage or 1,base.thrustMaxDamage or 1)
        -- Morrowind's displayed range is charge time, not random damage: a held
        -- attack reliably reaches the maximum. Preserve strong native artifacts,
        -- but stop stacked affixes from turning low-level drops into 200+ damage
        -- weapons. High-level Heavy rolls still grow toward a hard 120 ceiling.
        local damageCap=math.min(120,math.max(nativeMax,
            math.floor((24+itemLevel*0.75+spec.tier*5)*styleFactor+0.5)))
        details[#details + 1] = styleName .. ' | Attack speed: ' .. string.format('%.2f', draft.speed)
        for _, key in ipairs({'chopMinDamage', 'chopMaxDamage', 'slashMinDamage',
            'slashMaxDamage', 'thrustMinDamage', 'thrustMaxDamage'}) do
            draft[key] = math.min(damageCap,math.floor(base[key] * mult))
        end
        details[#details + 1] = '+' .. math.floor((mult - 1) * 100 + 0.5)
            .. '% base damage (level cap ' .. damageCap .. ')'
    elseif kind == types.Armor then
        draft.baseArmor = math.floor(base.baseArmor * (1 + bonus * (useSuffix and suf.property == 'damage' and 2 or 1)))
        details[#details + 1] = 'Armor rating: ' .. draft.baseArmor
    elseif useSuffix and suf.property == 'damage' then
        draft.enchantCapacity = base.enchantCapacity * (1 + bonus)
        details[#details + 1] = 'Enchantment capacity +' .. math.floor(bonus * 100 + 0.5) .. '%'
    end
    if useSuffix and suf.property == 'weight' then
        draft.weight = base.weight * (1 - math.min(0.45, bonus * 1.5))
        details[#details + 1] = 'Weight reduced to ' .. string.format('%.1f', draft.weight)
    elseif useSuffix and suf.property == 'condition' then
        if base.health then
            draft.health = math.floor(base.health * (1 + bonus * 2))
            details[#details + 1] = 'Durability: ' .. draft.health
        else
            draft.enchantCapacity = base.enchantCapacity * (1 + bonus * 2)
            details[#details + 1] = 'Increased enchantment capacity'
        end
    end
    details[#details + 1] = 'Drop level ' .. itemLevel
    local itemProcs={}
    local function addProc(id)
        if id then
            itemProcs[#itemProcs+1]={id=id,tier=spec.tier,level=itemLevel,power=spec.power}
            details[#details+1]=R.itemProcs[id].description
        end
    end
    if weapon then if usePrefix then addProc(pre.weaponProc) end;if useSuffix then addProc(suf.weaponProc) end
    else if usePrefix then addProc(pre.armorProc) end;if useSuffix then addProc(suf.armorProc) end end
    details[#details + 1] = melee and 'Cast on strike | 10,000 charge, 1 cost' or (weapon and 'Cast on use (ranged) | 10,000 charge, 1 cost' or 'Constant effect')
    for _, e in ipairs(effects) do
        local rec = core.magic.effects.records[e.id]
        details[#details + 1] = (rec and rec.name or e.id) .. (e.affectedAttribute and ' (' .. e.affectedAttribute .. ')' or '')
            .. ': ' .. e.magnitudeMin .. (e.duration > 0 and ' for ' .. e.duration .. 's' or '')
            .. (e.range == core.magic.RANGE.Self and ' on self' or '')
    end
    local record = world.createRecord(kind.createRecordDraft(draft))
    return record.id, {name = draft.name, tier = spec.tier, rarity = rarity.name,
        level = itemLevel, dropLevel = itemLevel,
        baseQualityTier = spec.baseQualityTier or 1,
        details = details, source = 'Dreamforged', baseId = base.id, enchantmentId = enchantment.id,
        itemType=weapon and 'weapon' or 'wearable', procs=itemProcs}
end
function M.makeMythic(base,kind,definition)
    local effects={}
    for _,data in ipairs(definition.effects or {}) do
        local made=effect(data[1],data[2],data[4] or core.magic.RANGE.Self,data[3] or 0,data[5])
        if data[6] then made.affectedSkill=data[6] end
        effects[#effects+1]=made
    end
    local enchant=world.createRecord(core.magic.enchantments.createRecordDraft{
        type=kind==types.Weapon and core.magic.ENCHANTMENT_TYPE.CastOnUse or core.magic.ENCHANTMENT_TYPE.ConstantEffect,
        cost=kind==types.Weapon and 1 or 0,charge=kind==types.Weapon and 10000 or 0,isAutocalc=false,effects=effects})
    local record=world.createRecord(kind.createRecordDraft{template=base,name='[Mythic] '..definition.name,
        enchant=enchant.id,value=math.max(base.value or 1,50000)})
    return record.id,{name='[Mythic] '..definition.name,tier=6,rarity='Mythic',level=1,dropLevel=1,
        details={definition.description,kind==types.Weapon and 'Cast on use | Mythic projectile effect' or 'Constant effect'},
        source='Dreamforged Mythic',baseId=base.id,enchantmentId=enchant.id,itemType=kind==types.Weapon and 'weapon' or 'wearable',
        procs={},mythic=definition.id}
end
return M
