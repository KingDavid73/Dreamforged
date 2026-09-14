local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local util = require('openmw.util')
local C = require('scripts.ashenloot.config')
local R = require('scripts.ashenloot.rules')
local A = require('scripts.ashenloot.advancement')
local Records = require('scripts.ashenloot.records')
local Progress = require('scripts.ashenloot.progression')
local script = 'scripts/ashenloot/actor.lua'
local state = {version = 26, records = {}, cache = {}, elites = {}, rewards = {}, abilities = {}, procs = {}, cooldowns = {},
    itemSpells={},itemCooldowns={},itemProcRoll=0,count = 0}
local pool
local mythicDefinitions={
 {id='wabbajack',name='Wabbajack',base='wooden staff',description='Safe creatures become a different level-scaled creature.'},
 {id='corruption',name='Skull of Corruption',base='staff_magnus_unique',description='Creates an evil duplicate that fights its original.'},
 {id='worms',name='Staff of Worms',base='wooden staff',description='Recreates a safe fallen actor as a temporary ally.'},
 {id='wild_friend',name='Staff of the Helpful Accident',base='wooden staff',description='Calls a random level-scaled creature ally.'},
 {id='wild_hostile',name='Staff of Immediate Regret',base='wooden staff',description='Calls a random level-scaled creature that attacks the wielder.'},
 {id='kingmaker',name='Kingmaker',base='staff_hasedoki_unique',description='Rerolls a safe NPC and raises them to Champion rank.'},
 {id='godmaker',name='Godmaker',base='staff_magnus_unique',description='Raises a hostile target one rank, up to World Boss.'},
 {id='sanguine_rose',name='Sanguine Rose',base='wooden staff',description='Calls a random Daedra ally.'},
 {id='apotheosis',name='Apotheosis',base='staff_magnus_unique',kind='weapon',description='A brutally excessive tri-elemental staff.',effects={{'firedamage',20,3,core.magic.RANGE.Target},{'frostdamage',20,3,core.magic.RANGE.Target},{'shockdamage',25,2,core.magic.RANGE.Target}}},
 {id='hasedokis_rebuke',name="Hasedoki's Rebuke",base='staff_hasedoki_unique',kind='weapon',description='Crushes a target under invisible force.',effects={{'burden',100,8,core.magic.RANGE.Target},{'damagefatigue',25,4,core.magic.RANGE.Target}}},
 {id='levitating_pants',name='Pants of the Unending Sky',base='common_pants_01',kind='clothing',description='You always levitate. This may be deeply inconvenient.',effects={{'levitate',1,0}}},
 {id='reckless_boots',name='Boots of Catastrophic Momentum',base='common_shoes_01',kind='clothing',description='Five hundred Speed and Acrobatics. Steering is your problem.',effects={{'fortifyattribute',500,0,nil,'speed'},{'fortifyskill',500,0,nil,nil,'acrobatics'}}},
 {id='too_many_thoughts',name='Helm of Too Many Thoughts',base='iron_helmet',kind='armor',description='Great intellect, terrible silence.',effects={{'fortifyattribute',50,0,nil,'intelligence'},{'silence',1,0}}},
 {id='elsewhere_ring',name='Ring of Being Elsewhere',base='common_ring_01',kind='clothing',description='Hard to see and mysteriously heavy.',effects={{'chameleon',35,0},{'burden',50,0}}},
}
for _,def in ipairs(mythicDefinitions) do
    if not def.kind then def.kind='weapon';def.effects={{'restorehealth',1,1,core.magic.RANGE.Target}} end
end
local enrollmentTimer, lastCoverage = 0, ''
local beastHandlerRegistered = false
local projectileHandlerRegistered = false
local tomeHandlerRegistered = false
local function advancementEffect(data,targeted)
    local effect={id=data[1],magnitudeMin=data[2],magnitudeMax=data[2],duration=data[3] or 0,area=0,
        range=targeted and core.magic.RANGE.Touch or core.magic.RANGE.Self}
    if data[4] then effect.affectedAttribute=data[4] end
    if data[5] then effect.affectedSkill=data[5] end
    return effect
end
local function advancementRecord(key,name,spellType,effects,targeted)
    state.advancementRecords=state.advancementRecords or {}
    local id=state.advancementRecords[key]
    if id and core.magic.spells.records[id] then return id end
    local made={};for _,effect in ipairs(effects) do made[#made+1]=advancementEffect(effect,targeted) end
    id=world.createRecord(core.magic.spells.createRecordDraft{name='Dreamforged: '..name,type=spellType,cost=0,
        isAutocalc=false,alwaysSucceedFlag=true,effects=made}).id
    state.advancementRecords[key]=id;return id
end
local function activeDefinitions(snapshot)
    local list={}
    for _,level in ipairs(A.activeLevels) do
        local def=A.actives[snapshot.specialty] and A.actives[snapshot.specialty][level]
        if def and snapshot.level>=level then list[#list+1]=def end
    end
    for skill,def in pairs(A.skillActives) do
        if (snapshot.skills[skill] or 0)>=def.level then list[#list+1]=def end
    end
    table.sort(list,function(a,b)return a.name<b.name end);return list
end
local function reconcileAdvancement(event)
    local player=event.player;if not player or not player:isValid() then return end
    state.advancementEarned=state.advancementEarned or {};local earned=state.advancementEarned
    local newly=0
    local function grant(key,name,effects)
        local id=advancementRecord(key,name,core.magic.SPELL_TYPE.Ability,effects,false)
        if not types.Actor.spells(player)[id] then types.Actor.spells(player):add(id) end
        if not earned[key] then newly=newly+1 end;earned[key]=true
    end
    for skill,spec in pairs(A.skills) do
        local value=event.skills[skill] or 0
        if value>=50 then grant('skill:'..skill..':50',skill..' Adept',{{'fortifyattribute',2,0,A.attributes[spec]}}) end
        if value>=75 then grant('skill:'..skill..':75',skill..' Expert',{{'fortifyskill',5,0,nil,skill}}) end
        if value>=100 then
            local m=A.masteries[skill];grant('skill:'..skill..':100',skill..' Mastery',{{m[1],m[3],0,m[2]}})
        end
    end
    for _,level in ipairs(A.passiveLevels) do if event.level>=level then
        local effects=event.specialty=='combat' and {{'fortifyhealth',3+math.floor(level/10),0}}
            or event.specialty=='magic' and {{'fortifymagicka',6+math.floor(level/5),0}}
            or {{'fortifyfatigue',5+math.floor(level/5),0}}
        grant('level:'..event.specialty..':'..level,event.specialty..' Path '..level,effects)
    end end
    local active={};for _,def in ipairs(activeDefinitions(event)) do
        advancementRecord('active:'..def.id,def.name,core.magic.SPELL_TYPE.Spell,def.effects,def.target)
        active[#active+1]={id=def.id,name=def.name,cost=def.cost,cooldown=def.cooldown,charges=def.charges,
            recharge=def.recharge,gameTime=def.gameTime,target=def.target}
        earned['active:'..def.id]=true
    end
    state.advancementSnapshot=event
    player:sendEvent('AshenLoot_AdvancementList',active)
    if newly>0 then player:sendEvent('AshenLoot_AdvancementResult',{ok=true,
        message=newly==1 and 'A new Dreamforged milestone was unlocked.' or (newly..' Dreamforged milestones were unlocked.')}) end
end
local function useAdvancement(event)
    local player=event.player;local snapshot=state.advancementSnapshot
    if not player or not player:isValid() or not snapshot then return end
    local found;for _,def in ipairs(activeDefinitions(snapshot)) do if def.id==event.id then found=def;break end end
    if not found then return end
    local target=found.target and event.target or player
    if not target or not target:isValid() or not types.Actor.objectIsInstance(target) or types.Actor.isDead(target) then
        player:sendEvent('AshenLoot_AdvancementResult',{ok=false,message='No valid target.'});return
    end
    state.advancementUses=state.advancementUses or {};local uses=state.advancementUses[found.id] or {}
    local now=found.gameTime and core.getGameTime() or core.getSimulationTime()
    local recovery=found.recharge or found.cooldown or 0;local live={}
    for _,used in ipairs(uses) do if now-used<recovery then live[#live+1]=used end end
    if found.charges and #live>=found.charges then
        player:sendEvent('AshenLoot_AdvancementResult',{ok=false,message=found.name..' has no charges ready.'});return
    elseif not found.charges and live[1] then
        player:sendEvent('AshenLoot_AdvancementResult',{ok=false,message=found.name..' is cooling down.'});return
    end
    local cost=found.cost or {};local hp=types.Actor.stats.dynamic.health(player)
    local mp=types.Actor.stats.dynamic.magicka(player);local fp=types.Actor.stats.dynamic.fatigue(player)
    local hc=(cost.health or 0)+(cost.healthPercent or 0)*math.max(1,hp.base+hp.modifier)
    local mc=(cost.magicka or 0)+(cost.magickaPercent or 0)*math.max(1,mp.base+mp.modifier)
    local fc=(cost.fatigue or 0)+(cost.fatiguePercent or 0)*math.max(1,fp.base+fp.modifier)
    if hp.current-hc<1 or mp.current<mc or fp.current<fc then
        player:sendEvent('AshenLoot_AdvancementResult',{ok=false,message='Not enough Health, Magicka, or Fatigue.'});return
    end
    local record=advancementRecord('active:'..found.id,found.name,core.magic.SPELL_TYPE.Spell,found.effects,found.target)
    local indexes={};for n=0,#core.magic.spells.records[record].effects-1 do indexes[#indexes+1]=n end
    live[#live+1]=now;state.advancementUses[found.id]=live
    player:sendEvent('AshenLoot_ApplyAdvancement',{record=record,target=target,indexes=indexes,
        health=hc,magicka=mc,fatigue=fc,name=found.name})
end
local function applyTargetedAdvancement(event)
    if not event or not event.target or not event.target:isValid() then return end
    types.Actor.activeSpells(event.target):add{id=event.record,effects=event.indexes,
        caster=event.player,stackable=false}
end
local startingKits = {
    al_warrior = {{'iron longsword', 1}, {'iron_shield', 1}, {'iron_cuirass', 1},
        {'iron_greaves', 1}, {'iron boots', 1}, {'p_restore_health_b', 3}, {'p_restore_fatigue_b', 2}},
    al_warmage = {{'steel mace', 1}, {'chitin cuirass', 1}, {'chitin_shield', 1},
        {'p_restore_health_b', 2}, {'p_restore_magicka_b', 4}},
    al_archer = {{'chitin short bow', 1}, {'iron arrow', 60}, {'chitin cuirass', 1},
        {'chitin boots', 1}, {'steel shortsword', 1}, {'p_restore_health_b', 2}, {'p_restore_fatigue_b', 2}},
    al_rogue = {{'steel dagger', 1}, {'chitin cuirass', 1}, {'chitin boots', 1},
        {'pick_apprentice_01', 3}, {'probe_apprentice_01', 3}, {'p_restore_health_b', 2}, {'p_restore_fatigue_b', 2}},
    al_conjurer = {{'steel staff', 1}, {'common_robe_01', 1}, {'steel dagger', 1},
        {'p_restore_magicka_b', 5}, {'p_restore_health_b', 2}},
}
local startingSpells = {
    al_warmage = {'fire bite', 'hearth heal', 'Shield', 'bound mace'},
    al_conjurer = {'summon ancestral ghost', 'bound dagger', 'Chameleon', 'detect_creature', 'water walking'},
}
local tomeDefinitions={
 {id='ember_dart',name='Ember Dart',tier=1,cost=6,e={{'firedamage',6,2,'target'}}},
 {id='frost_shard',name='Frost Shard',tier=1,cost=6,e={{'frostdamage',6,2,'target'}}},
 {id='spark_lance',name='Spark Lance',tier=1,cost=7,e={{'shockdamage',7,2,'target'}}},
 {id='hearth_mend',name='Hearth Mend',tier=1,cost=8,e={{'restorehealth',5,3,'self'}}},
 {id='ash_shell',name='Ash Shell',tier=1,cost=9,e={{'shield',10,20,'self'}}},
 {id='pilgrims_step',name="Pilgrim's Step",tier=1,cost=8,e={{'fortifyattribute',15,20,'self','speed'}}},
 {id='triune_bolt',name='Triune Bolt',tier=2,cost=18,e={{'firedamage',6,3,'target'},{'frostdamage',6,3,'target'},{'shockdamage',6,3,'target'}}},
 {id='grave_grasp',name='Grave Grasp',tier=2,cost=16,e={{'damagehealth',8,3,'target'},{'burden',25,8,'target'}}},
 {id='ghostguard',name='Ghostguard',tier=2,cost=17,e={{'shield',18,25,'self'},{'resistnormalweapons',20,25,'self'}}},
 {id='velothi_mending',name='Velothi Mending',tier=2,cost=15,e={{'restorehealth',8,4,'self'},{'restorefatigue',10,4,'self'}}},
 {id='netch_leap',name='Netch Leap',tier=2,cost=13,e={{'jump',35,15,'self'},{'feather',35,15,'self'}}},
 {id='ancestors_call',name="Ancestor's Call",tier=2,cost=20,e={{'summonancestralghost',1,35,'self'}}},
 -- Curated tomes are vendor-like spellbook fillers, not the endgame loot
 -- chase. Keep their encounter availability in the early/mid band (tiers 1
 -- and 2); powerful effects still have higher magicka costs and remain rare
 -- because a tome only replaces a successful mage weapon roll.
 {id='red_mountain_breath',name="Red Mountain's Breath",tier=2,cost=32,e={{'firedamage',16,4,'target'},{'weaknesstofire',20,6,'target'}}},
 {id='winter_of_skyrim',name='Winter of Skyrim',tier=2,cost=32,e={{'frostdamage',16,4,'target'},{'weaknesstofrost',20,6,'target'}}},
 {id='storm_of_azura',name='Storm of Azura',tier=2,cost=34,e={{'shockdamage',18,4,'target'},{'weaknesstoshock',20,6,'target'}}},
 {id='sanctuary_of_mercy',name='Sanctuary of Mercy',tier=2,cost=28,e={{'sanctuary',30,30,'self'}}},
 {id='aether_well',name='Aether Well',tier=2,cost=26,e={{'restoremagicka',10,8,'self'},{'spellabsorption',15,25,'self'}}},
 {id='daedric_envoy',name='Daedric Envoy',tier=2,cost=38,e={{'summondremora',1,45,'self'}}},
 {id='elemental_ruin',name='Elemental Ruin',tier=2,cost=60,e={{'firedamage',18,5,'target'},{'frostdamage',18,5,'target'},{'shockdamage',18,5,'target'}}},
 {id='heart_of_lorkhan',name='Heart of Lorkhan',tier=2,cost=52,e={{'fortifyhealth',60,45,'self'},{'fortifymagicka',60,45,'self'}}},
 {id='ghostwalk',name='Ghostwalk',tier=2,cost=45,e={{'chameleon',60,25,'self'},{'fortifyattribute',35,25,'self','speed'}}},
 {id='tribunal_ward',name='Tribunal Ward',tier=2,cost=55,e={{'reflect',25,35,'self'},{'spellabsorption',25,35,'self'},{'resistmagicka',25,35,'self'}}},
 {id='sixth_house_dream',name='Sixth House Dream',tier=2,cost=58,e={{'paralyze',1,5,'target'},{'damagehealth',16,5,'target'}}},
 {id='gate_of_oblivion',name='Gate of Oblivion',tier=2,cost=65,e={{'summongoldensaint',1,60,'self'}}},
}
local function ensureSpellTomes()
    state.spellTomes=state.spellTomes or {};state.spellTomesByRecord=state.spellTomesByRecord or {}
    local base
    for _,rec in pairs(types.Book.records) do
        if not rec.isScroll and not rec.mwscript and rec.value>0 then base=rec;break end
    end
    if not base then return end
    local ranges={self=core.magic.RANGE.Self,touch=core.magic.RANGE.Touch,target=core.magic.RANGE.Target}
    for _,def in ipairs(tomeDefinitions) do
        local saved=state.spellTomes[def.id]
        if not saved or not core.magic.spells.records[saved.spell] or not types.Book.record(saved.book) then
            local effects={}
            for _,e in ipairs(def.e) do effects[#effects+1]=Records.effect(e[1],e[2],ranges[e[4]],e[3],e[5]) end
            local spell=world.createRecord(core.magic.spells.createRecordDraft{name='Dreamforged: '..def.name,
                type=core.magic.SPELL_TYPE.Spell,cost=def.cost,isAutocalc=false,effects=effects})
            local book=world.createRecord(types.Book.createRecordDraft{template=base,name='Spell Tome: '..def.name,
                text='The sigils settle into memory. Use this tome to permanently learn '..def.name..'.',skill='',value=75*def.tier})
            saved={spell=spell.id,book=book.id,tier=def.tier,name=def.name};state.spellTomes[def.id]=saved
        end
        -- Refresh the availability band for existing saves when the tome
        -- table changes; the generated spell/book records themselves remain
        -- stable and duplicate protection still works as before.
        saved.tier=def.tier
        state.spellTomesByRecord[saved.book]=saved
    end
end
local function supported()
    return core.magic.enchantments.createRecordDraft and core.magic.spells.createRecordDraft
end
local function beastArmorEquip(armor, actor)
    if not I.protectedbeasts or not armor or not actor then return end
    local meta = state.records[armor.recordId]
    if not meta or not meta.baseId then return end
    local original = types.Armor.record(armor.recordId)
    if not original then return end
    return I.protectedbeasts.onArmorEquip(armor, actor, meta.baseId, function(beastBaseId)
        local key = 'beast:' .. armor.recordId .. ':' .. beastBaseId
        if state.cache[key] then return state.cache[key] end
        local beastBase = types.Armor.record(beastBaseId)
        if not beastBase then return end
        local id = world.createRecord(types.Armor.createRecordDraft {
            template = beastBase, name = original.name, enchant = original.enchant,
            value = original.value, weight = original.weight, health = original.health,
            baseArmor = original.baseArmor,
        }).id
        state.cache[key] = id
        state.records[id] = meta
        return id
    end)
end
local function eligible(actor)
    if not C.enabled or not supported() or types.Player.objectIsInstance(actor) then return false end
    if not actor.enabled or actor.scale < 0.001 then return false end
    if not (types.Creature.objectIsInstance(actor) or types.NPC.objectIsInstance(actor)) then return false end
    local rec = actor.type.record(actor)
    if not rec or (not C.unsafeContent and C.protectQuestActors and
        (rec.isEssential or (rec.mwscript and (not types.Creature.objectIsInstance(actor) or not rec.isRespawning)))) then return false end
    if not C.unsafeContent then for _, offered in pairs(rec.servicesOffered or {}) do if offered then return false end end end
    if types.NPC.objectIsInstance(actor) then return C.npcProgression or (C.allowRespawningNPCs and rec.isRespawning) end
    return true
end
local family
local function bossName(actor,rec)
    if types.NPC.objectIsInstance(actor) then
        local classRecord=types.NPC.classes and types.NPC.classes.records and types.NPC.classes.records[rec.class]
        return R.worldBossNpcName(actor.id,rec.name,rec.race,classRecord and classRecord.specialization)
    end
    return R.worldBossName(actor.id,rec.name,family(rec))
end
local function biography(actor,elite,rec)
    local specialization
    if types.NPC.objectIsInstance(actor) then
        local classRecord=types.NPC.classes and types.NPC.classes.records and types.NPC.classes.records[rec.class]
        specialization=classRecord and classRecord.specialization
    end
    return R.biography(actor.id,{name=elite.name,baseName=rec.name,family=elite.family or family(rec),
        modifiers=elite.modifiers,worldBoss=elite.worldBoss,npc=types.NPC.objectIsInstance(actor),
        race=rec.race,specialization=specialization})
end
local function demoteInvalidWorldBoss(actor)
    local elite=state.elites[actor.id]
    if not elite or not elite.worldBoss or C.unsafeContent or types.Actor.stats.ai.fight(actor).base>=80 then return end
    local director=state.director
    local actorState=director and director.actors and director.actors[actor.id]
    if actorState and actorState.bossOriginalScale then actor:setScale(actorState.bossOriginalScale)
    else actor:setScale(math.max(0.01,actor.scale/1.45)) end
    state.elites[actor.id]=false
    if director and director.cells then
        for _,cellState in pairs(director.cells) do
            if cellState.boss==actor.id then cellState.boss=false end
        end
    end
    actor:sendEvent('AshenLoot_EncounterResult',{elite=false})
    local player=world.players[1]
    if player then player:sendEvent('AshenLoot_Elite',{id=actor.id,metadata=false}) end
end
local function attach(actor)
    if actor and actor:isValid() then demoteInvalidWorldBoss(actor) end
    local elite=actor and state.elites[actor.id]
    local requiredNameVersion=types.NPC.objectIsInstance(actor) and 3 or 2
    if elite and elite.worldBoss and elite.nameVersion~=requiredNameVersion then
        local rec=actor.type.record(actor)
        elite.family=family(rec)
        elite.name=bossName(actor,rec)
        elite.nameVersion=requiredNameVersion
        local player=world.players[1]
        if player then player:sendEvent('AshenLoot_Elite',{id=actor.id,metadata=elite}) end
    end
    if elite and (elite.worldBoss or elite.rank==3) and not elite.biography then
        local rec=actor.type.record(actor)
        elite.family=elite.family or family(rec)
        elite.biography=biography(actor,elite,rec)
        local player=world.players[1]
        if player then player:sendEvent('AshenLoot_Elite',{id=actor.id,metadata=elite}) end
    end
    if eligible(actor) and not actor:hasScript(script) then actor:addScript(script) end
end
family=function(rec)
    local id = (rec.id .. ' ' .. rec.name .. ' ' .. (rec.model or '')):lower()
    if id:find('centurion') or id:find('automaton') or id:find('construct') then return 'construct' end
    if rec.type == types.Creature.TYPE.Undead then return 'undead' end
    if rec.type == types.Creature.TYPE.Daedra then return 'daedra' end
    return 'beast'
end
local function prepareAbility(elite, actor)
    if elite.healthModel == 1 then return end -- Preserve existing 0.1 elites without doubling their base-health bonus.
    elite.healthModel = 2
    elite.healthReference = types.Actor.stats.dynamic.health(actor).base
    elite.healthBonus = math.max(1, math.min(30000, math.floor(elite.healthReference * (elite.healthScale - 1) + 0.5)))
    local spellKey = (elite.rulesVersion == 3 and 'v3:' or 'v2:') .. table.concat(elite.modifiers, ':') .. ':' .. (elite.effectScale or 1)
    -- Saved pre-0.3 elites keep their recorded ability and original behavior.
    if elite.rulesVersion ~= 3 and elite.spellId then return end
    if not state.abilities[spellKey] then state.abilities[spellKey] = Records.ability(elite) end
    elite.spellId = state.abilities[spellKey]
end
local function getPool()
    if pool then return pool end
    pool = {}
    local qualityGroups={}
    local function qualityMetric(kind,rec)
        local value=math.max(1,tonumber(rec.value) or 1)
        if kind==types.Weapon then
            local damage=math.max(rec.chopMaxDamage or 0,rec.slashMaxDamage or 0,rec.thrustMaxDamage or 0)
            return damage*30+(rec.health or 0)*0.025+(rec.enchantCapacity or 0)*0.5+math.log(value+1)*4
        elseif kind==types.Armor then
            return (rec.baseArmor or 0)*22+(rec.health or 0)*0.02+(rec.enchantCapacity or 0)*0.5+math.log(value+1)*4
        end
        return (rec.enchantCapacity or 0)*2+math.log(value+1)*12
    end
    for _, kind in ipairs({types.Weapon, types.Armor, types.Clothing}) do
        for _, rec in pairs(kind.records) do
            local id = rec.id
            local text = ((rec.id or '') .. ' ' .. (rec.name or '')):lower()
            local blocked=text:find('unique',1,true) or text:find('artifact',1,true) or text:find('quest',1,true)
                or text:find('testing',1,true) or text:find('placeholder',1,true)
            if (C.unsafeContent or (not blocked and not rec.mwscript and not rec.enchant)) and rec.value > 0
                and (kind ~= types.Weapon or rec.type <= types.Weapon.TYPE.MarksmanCrossbow) then
                -- Clothing records cover both wearable garments and the
                -- accessory slots (rings, amulets, charms, etc.). Keep those
                -- as separate loot families so the family roll can give
                -- garments and jewelry their own, small shares.
                local category = kind == types.Armor and 'armor'
                    or (kind == types.Clothing and
                        ((text:find('ring', 1, true) or text:find('amulet', 1, true)
                            or text:find('charm', 1, true) or text:find('necklace', 1, true)
                            or text:find('pendant', 1, true)) and 'accessory' or 'clothing'))
                    or ((text:find('staff', 1, true) or text:find('wand', 1, true)) and 'staff')
                    or ((text:find('bow', 1, true) or text:find('crossbow', 1, true)) and 'ranged')
                    or 'melee'
                local entry={id=id,kind=kind,value=rec.value,category=category,
                    qualityMetric=qualityMetric(kind,rec),qualityGroup=tostring(kind)..':'..tostring(rec.type)}
                pool[#pool+1]=entry
                qualityGroups[entry.qualityGroup]=qualityGroups[entry.qualityGroup] or {}
                qualityGroups[entry.qualityGroup][#qualityGroups[entry.qualityGroup]+1]=entry
            end
        end
    end
    -- Rank every loaded subtype against its peers. Mod-added equipment is thus
    -- placed beside statistically comparable vanilla gear without requiring a
    -- brittle list of material names.
    for _,entries in pairs(qualityGroups) do
        table.sort(entries,function(a,b)
            return a.qualityMetric==b.qualityMetric and a.id<b.id or a.qualityMetric<b.qualityMetric
        end)
        for index,entry in ipairs(entries) do
            entry.qualityTier=math.min(8,1+math.floor((index-1)*8/#entries))
        end
    end
    table.sort(pool, function(a, b) return a.id < b.id end)
    assert(#pool > 0, 'Ashen Loot: no suitable base items in loaded content')
    return pool
end
local function rollBaseQuality(random,dropLevel)
    -- A level-1 perfect roll can reach tier 8. Levels improve the odds gently
    -- rather than locking low or high material bands out of the pool.
    local bonus=math.min(35,math.max(0,math.floor(math.log(math.max(1,dropLevel)+1)/math.log(2)*2)-1))
    local score=random(100)+bonus
    for tier,threshold in ipairs({35,55,70,82,90,96,100}) do if score<=threshold then return tier end end
    return 8
end
local function sumPlayerSkills(player, names)
    local total = 0
    for _, name in ipairs(names) do
        local stat = types.NPC.stats.skills[name](player)
        total = total + (stat and stat.base or 0)
    end
    return total
end
local function lootProfile()
    local player = world.players[1]
    if not player or not types.NPC.objectIsInstance(player) then return end
    local rec = types.NPC.record(player)
    local class = ((rec and rec.class) or ''):lower()
    -- Ashen classes are explicit. The order matters because War Mage contains
    -- both "war" and "mage" in its display name.
    if class:find('warmage', 1, true) or class:find('war mage', 1, true) then
        return {key = 'warmage', staff = 55, melee = 22.5, ranged = 22.5}
    elseif class:find('conjurer', 1, true) then
        return {key = 'conjurer', staff = 55, melee = 22.5, ranged = 22.5}
    elseif class:find('archer', 1, true) then
        return {key = 'archer', ranged = 55, melee = 22.5, staff = 22.5}
    elseif class:find('rogue', 1, true) or class:find('thief', 1, true) then
        return {key = 'rogue', ranged = 45, melee = 40, staff = 15}
    elseif class:find('warrior', 1, true) or class:find('fighter', 1, true) then
        return {key = 'warrior', melee = 55, ranged = 22.5, staff = 22.5}
    end
    local classRecord=types.NPC.classes and types.NPC.classes.records and types.NPC.classes.records[rec.class]
    local specialization=classRecord and (classRecord.specialization or ''):lower()
    if specialization=='combat' then
        return {key = 'combat', melee = 55, ranged = 22.5, staff = 22.5}
    elseif specialization=='magic' then
        return {key = 'magic', staff = 55, melee = 22.5, ranged = 22.5}
    elseif specialization=='stealth' then
        return {key = 'stealth', ranged = 55, melee = 30, staff = 15}
    end
    -- Vanilla classes do not share stable names across overhaul mods. Infer a
    -- broad specialization from current skill totals instead of restricting
    -- their drops to a brittle class-name list.
    local combat = sumPlayerSkills(player, {'armorer','athletics','axe','block','bluntweapon','heavyarmor','longblade','mediumarmor','spear'})
    local magic = sumPlayerSkills(player, {'alchemy','alteration','conjuration','destruction','enchant','illusion','mysticism','restoration'})
    local stealth = sumPlayerSkills(player, {'acrobatics','lightarmor','marksman','mercantile','security','shortblade','sneak','speechcraft'})
    if combat >= magic and combat >= stealth then
        return {key = 'combat', melee = 55, ranged = 22.5, staff = 22.5}
    elseif magic >= stealth then
        return {key = 'magic', staff = 55, melee = 22.5, ranged = 22.5}
    end
    return {key = 'stealth', ranged = 55, melee = 30, staff = 15}
end
local function chooseLootEntry(candidates, random, profile, forcedFamily, equalFamilies)
    if #candidates == 0 then return end
    if #candidates==1 then return candidates[1] end
    if not candidates[1].category then return candidates[random(#candidates)] end
    local families={weapon={},armor={},clothing={},accessory={}}
    for _,entry in ipairs(candidates) do
        local family=(entry.category=='armor' and 'armor')
            or (entry.category=='clothing' and 'clothing')
            or (entry.category=='accessory' and 'accessory')
            or 'weapon'
        families[family][#families[family]+1]=entry
    end
    local family=forcedFamily
    if not family or #families[family]==0 then
        local familyOrder=equalFamilies
            and {{'weapon',25},{'armor',25},{'clothing',25},{'accessory',25}}
            or {{'weapon',50},{'armor',40},{'clothing',5},{'accessory',5}}
        local total=0
        for _,e in ipairs(familyOrder) do if #families[e[1]]>0 then total=total+e[2] end end
        local roll=random()*total
        for _,e in ipairs(familyOrder) do if #families[e[1]]>0 then roll=roll-e[2];if roll<=0 then family=e[1];break end end end
    end
    local selected=families[family]
    if family=='weapon' then
        local categories={melee={},ranged={},staff={}}
        for _,entry in ipairs(selected) do categories[entry.category][#categories[entry.category]+1]=entry end
        local order={'melee','ranged','staff'};local total=0
        for _,category in ipairs(order) do if #categories[category]>0 then total=total+(profile and profile[category] or 33.333) end end
        local roll=random()*total
        for _,category in ipairs(order) do
            if #categories[category]>0 then roll=roll-(profile and profile[category] or 33.333);if roll<=0 then selected=categories[category];break end end
        end
    end
    -- Pick a slot/subtype before its individual base record so heavily modded
    -- slots do not crowd every other equipment slot out of the table.
    local subtypeGroups={};local keys={}
    for _,entry in ipairs(selected) do
        local key=entry.qualityGroup or entry.category
        if not subtypeGroups[key] then subtypeGroups[key]={};keys[#keys+1]=key end
        subtypeGroups[key][#subtypeGroups[key]+1]=entry
    end
    table.sort(keys);local group=subtypeGroups[keys[random(#keys)]]
    return group[random(#group)]
end
local function giveLoot(actor, seed, minimum, forcedBase, forcedTier, trophy, destination, forcedFamily, rarityBonus,dropIndex)
    local player = world.players[1]
    -- Drops use the encounter's persisted scaled level, not the player's raw
    -- level. This keeps a boss's reward on the same level band as its stats.
    local dropLevel = player and Progress.actorLevel(actor) or 1
    local spec = R.item(seed, dropLevel, minimum,rarityBonus,forcedTier)
    spec.dropLevel = dropLevel
    if trophy then
        spec.prefix = trophy.prefix or spec.prefix
        spec.suffix = trophy.suffix or spec.suffix
    end
    local candidates = {}
    local baseRandom=R.rng(seed .. ':base')
    local desiredQuality=rollBaseQuality(baseRandom,dropLevel)
    if forcedBase then
        for _,kind in ipairs({types.Weapon,types.Armor,types.Clothing}) do
            -- Querying a valid Armor ID through Weapon.record throws instead
            -- of returning nil, so probe forced iconic bases defensively.
            local ok,rec=pcall(function() return kind.record(forcedBase) end)
            if ok and rec and (C.unsafeContent or not rec.mwscript) then
                candidates[1]={id=rec.id,kind=kind,value=rec.value,qualityTier=8};break
            end
        end
    end
    if not forcedBase then
        local nearest=9
        for _,entry in ipairs(getPool()) do nearest=math.min(nearest,math.abs(entry.qualityTier-desiredQuality)) end
        for _,entry in ipairs(getPool()) do
            if math.abs(entry.qualityTier-desiredQuality)==nearest then candidates[#candidates+1]=entry end
        end
    end
    assert(#candidates > 0, 'Ashen Loot: base item is not in the supported loot pool')
    local profile = player and lootProfile()
    -- Legendary and Relic rewards should not be quietly skewed by the broad
    -- everyday weapon/armor family gradient.  Their family roll is equal;
    -- class archetype weighting still applies inside the weapon branch.
    local entry = chooseLootEntry(candidates, baseRandom, profile,
        spec.tier>=5 and nil or forcedFamily, spec.tier>=5)
    spec.baseQualityTier=entry.qualityTier or desiredQuality
    local key = table.concat({'v8', profile and profile.key or 'none', entry.id, spec.baseQualityTier, spec.tier, spec.prefix, spec.suffix, spec.power, spec.roll, spec.style, spec.dropLevel}, ':')
    local id = state.cache[key]
    if not id then
        if state.count >= C.maxGeneratedItems then
            -- Reuse a known item when the save's generation budget is exhausted.
            local matching, bestDistance = {}, nil
            for rid, meta in pairs(state.records) do
                if meta.tier >= (minimum or 1) and (not forcedBase or meta.baseId==forcedBase) then
                    local distance=math.abs((tonumber(meta.level or meta.dropLevel) or dropLevel)-dropLevel)
                    if not bestDistance or distance<bestDistance then
                        matching={rid};bestDistance=distance
                    elseif distance==bestDistance then matching[#matching+1]=rid end
                end
            end
            table.sort(matching)
            if #matching == 0 then return false end
            id = matching[R.rng(seed .. ':reuse')(#matching)]
        else
            local metadata
            id, metadata = Records.makeItem(entry.kind.record(entry.id), entry.kind, spec)
            state.records[id], state.cache[key] = metadata, id
            state.count = state.count + 1
        end
    end
    local item = world.createObject(id, 1)
    if type(destination)=='table' and destination.worldCell then
        item:teleport(destination.worldCell,destination.position,destination.rotation)
        if destination.scale and destination.scale~=1 then item:setScale(destination.scale) end
    elseif destination then item:moveInto(destination)
    elseif not Progress.ground(item,actor,dropIndex) then item:moveInto(types.Actor.inventory(actor)) end
    if player then player:sendEvent('AshenLoot_Record', {id = id, metadata = state.records[id]}) end
    return id
end
local function gearOverage()
    local player=world.players[1]
    if not player then return 0 end
    return math.max(0,Progress.gearLevel()-types.Actor.stats.level(player).current)
end
local function mythicChance()
    return R.worldBossRarities[7]
end
local function worldBossRewardBonus(actor)
    local levelBonus=R.levelRarityBonus(Progress.actorLevel(actor))
    local overgear=math.min(30,gearOverage())
    local difficulty=math.floor(math.max(0,C.enemyHealth-1)*10
        +math.max(0,C.enemyDamage-1)*10+0.5)
    return math.min(75,levelBonus+overgear+difficulty)
end
local function giveMythic(actor,seed,dropIndex)
    local rng=R.rng((seed or actor.id..':mythic')..':definition')
    local def=mythicDefinitions[rng(#mythicDefinitions)]
    local kind=def.kind=='armor' and types.Armor or (def.kind=='clothing' and types.Clothing or types.Weapon)
    local base=kind.record(def.base) or (kind==types.Weapon and kind.record('wooden staff'))
    if base then
        local id,meta=Records.makeMythic(base,kind,def);meta.dropLevel=Progress.actorLevel(actor);meta.level=meta.dropLevel
        state.records[id]=meta;local item=world.createObject(id,1)
        if not Progress.ground(item,actor,dropIndex) then item:moveInto(types.Actor.inventory(actor)) end
        local player=world.players[1];if player then player:sendEvent('AshenLoot_Record',{id=id,metadata=meta}) end
        return id
    end
end
local function safeMythicActor(actor,allowDead)
    if not actor or not actor:isValid() or types.Player.objectIsInstance(actor) then return false end
    if not allowDead and types.Actor.isDead(actor) then return false end
    local rec=actor.type.record(actor)
    if not rec or (not C.unsafeContent and (rec.mwscript or rec.isEssential)) then return false end
    if not C.unsafeContent then for _,service in pairs(rec.servicesOffered or {}) do if service then return false end end end
    return true
end
local function randomCreatureId(seed,daedraOnly)
    local choices={}
    for _,rec in pairs(types.Creature.records) do
        if Progress.test.safeRecord(rec) and (rec.canWalk or rec.canFly)
            and not (rec.canSwim and not rec.canWalk and not rec.canFly)
            and (not daedraOnly or rec.type==types.Creature.TYPE.Daedra) then choices[#choices+1]=rec.id end
    end
    table.sort(choices);return #choices>0 and choices[R.rng(seed)(#choices)]
end
local function spawnMythicCreature(id,target,caster,friendly)
    if not id or not target.cell then return end
    local spawn=world.createObject(id,1);spawn:teleport(target.cell,target.position+util.vector3(80,0,8))
    if not spawn:hasScript(script) then spawn:addScript(script) end
    state.mythicSummons=state.mythicSummons or {};state.mythicSummons[spawn.id]=core.getSimulationTime()+120
    spawn:sendEvent(friendly and 'AshenLoot_MythicFollow' or 'AshenLoot_MythicAttack',friendly and caster or caster)
    return spawn
end
local function mythicImpact(item,caster,target)
    local meta=item and state.records[item.recordId]
    if not meta or not meta.mythic or not caster or not target or not types.Actor.objectIsInstance(target) then return end
    local power=meta.mythic
    if power=='wabbajack' and types.Creature.objectIsInstance(target) and safeMythicActor(target) then
        local id=randomCreatureId(target.id..':wabbajack')
        if id and id~=target.recordId then
            local cell,pos,rotation,scale=target.cell,target.position,target.rotation,target.scale
            target:remove();local replacement=world.createObject(id,1);replacement:teleport(cell,pos,rotation);replacement:setScale(scale)
            if not replacement:hasScript(script) then replacement:addScript(script) end
            replacement:sendEvent('AshenLoot_Spawned')
        end
    elseif power=='corruption' and safeMythicActor(target)
        and (not types.NPC.objectIsInstance(target) or target.type.record(target).isRespawning) then
        local copy=spawnMythicCreature(target.recordId,target,caster,false)
        if copy then target:sendEvent('AshenLoot_MythicAttack',copy);copy:sendEvent('AshenLoot_MythicAttack',target) end
    elseif power=='worms' and safeMythicActor(target,true) and types.Actor.isDead(target)
        and (not types.NPC.objectIsInstance(target) or target.type.record(target).isRespawning) then
        spawnMythicCreature(target.recordId,target,caster,true)
    elseif power=='wild_friend' or power=='wild_hostile' or power=='sanguine_rose' then
        local id=randomCreatureId(item.id..':'..core.getSimulationTime(),power=='sanguine_rose')
        spawnMythicCreature(id,target,caster,power~='wild_hostile')
    elseif power=='kingmaker' and types.NPC.objectIsInstance(target) and safeMythicActor(target) then
        Progress.test.randomizeInventory(target,types.Actor.inventory(target),Progress.actorLevel(target),target.id..':kingmaker:'..core.getSimulationTime(),false,{rank=1})
        encounter{actor=target,force=true,rank=1}
    elseif power=='godmaker' and safeMythicActor(target) and (C.unsafeContent or types.Actor.stats.ai.fight(target).base>=80) then
        local old=state.elites[target.id];local rank=old and old.rank or 0
        if old and old.worldBoss then return end
        if old and old.spellId and types.Actor.spells(target)[old.spellId] then types.Actor.spells(target):remove(old.spellId) end
        if rank>=3 then encounter{actor=target,force=true,rank=3,worldBoss=true}
        else encounter{actor=target,force=true,rank=rank+1} end
    end
end
local function trigger(actor, target, retaliate)
    local elite = state.elites[actor.id]
    if not elite or elite.rulesVersion ~= 3 or not eligible(actor) then return end
    if not actor:isValid() or not target:isValid() or not target.enabled or actor.id == target.id
        or types.Actor.isDead(actor) or types.Actor.isDead(target) then return end
    local now = core.getSimulationTime()
    local cooldowns = state.cooldowns[actor.id] or {}
    state.cooldowns[actor.id] = cooldowns
    for _, index in ipairs(elite.modifiers) do
        local proc = R.elites[index].proc
        if proc and (proc.retaliate == true) == retaliate and now >= (cooldowns[index] or 0) then
            local procKey=elite.effectScale and (index..':'..elite.effectScale) or index
            if not state.procs[procKey] then state.procs[procKey] = Records.proc(index,elite.effectScale) end
            cooldowns[index] = now + proc.cooldown
            types.Actor.activeSpells(target):add {id = state.procs[procKey], effects = {0},
                caster = actor, stackable = false}
            local effect = core.magic.effects.records[proc.effect]
            local static = effect.hitStatic and types.Static.record(effect.hitStatic)
            if static then target:sendEvent('AddVfx', {model = static.model,
                options = {particleTextureOverride = effect.particle, loop = false}}) end
            if effect.hitSound and effect.hitSound ~= '' then core.sound.playSound3d(effect.hitSound, target) end
        end
    end
end
local function itemSpell(effect,magnitude,duration)
    local key=table.concat({effect,magnitude,duration or 1},':')
    if not state.itemSpells[key] then
        state.itemSpells[key]=world.createRecord(core.magic.spells.createRecordDraft {
            name='Dreamforged proc',type=core.magic.SPELL_TYPE.Spell,cost=0,isAutocalc=false,
            effects={Records.effect(effect,magnitude,core.magic.RANGE.Touch,duration or 1)},
        }).id
    end
    return state.itemSpells[key]
end
local function applyItemSpell(caster,target,effect,magnitude,duration)
    if not target or not target:isValid() or types.Actor.isDead(target) then return end
    types.Actor.activeSpells(target):add {id=itemSpell(effect,math.max(1,math.floor(magnitude+0.5)),duration),
        effects={0},caster=caster,stackable=false}
end
local function safeCommandTarget(target)
    if types.Player.objectIsInstance(target) then return false end
    local rec=target.type.record(target)
    if not rec or (not C.unsafeContent and (rec.isEssential or rec.mwscript)) then return false end
    for _,offered in pairs(rec.servicesOffered or {}) do if offered then return false end end
    return true
end
local function itemProcs(actor,triggerName)
    local strongest={}
    for slot,item in pairs(types.Actor.getEquipment(actor)) do
        local meta=state.records[item.recordId]
        if meta and meta.procs and (meta.itemType~='weapon' or slot==types.Actor.EQUIPMENT_SLOT.CarriedRight) then
            for _,proc in ipairs(meta.procs) do
                local rule=R.itemProcs[proc.id]
                if rule and rule.trigger==triggerName and (not strongest[proc.id] or proc.level>strongest[proc.id].level) then
                    strongest[proc.id]={proc=proc,recordId=item.recordId}
                end
            end
        end
    end
    return strongest
end
local function hostileCandidate(actor,source)
    if actor==source or not actor:isValid() or types.Actor.isDead(actor) then return false end
    if types.Player.objectIsInstance(source) then return types.Actor.stats.ai.fight(actor).base>=80 end
    return types.Player.objectIsInstance(actor)
end
local function triggerItemProcs(owner,target,triggerName,melee,force)
    local now=core.getSimulationTime()
    for id,entry in pairs(itemProcs(owner,triggerName)) do
        local rule,proc=R.itemProcs[id],entry.proc
        local cooldownKey=owner.id..':'..entry.recordId..':'..id
        state.itemProcRoll=(state.itemProcRoll or 0)+1
        local rolled=R.rng(cooldownKey..':'..state.itemProcRoll)()
        if (force or rolled<rule.chance) and now>=(state.itemCooldowns[cooldownKey] or 0) then
            state.itemCooldowns[cooldownKey]=now+rule.cooldown
            local amount=3+proc.tier*2+math.floor(proc.level*0.25)
            if id=='thorns' and melee then
                applyItemSpell(owner,target,'damagehealth',amount,1)
            elseif id=='castOnHit' then
                local elements={'firedamage','frostdamage','shockdamage'}
                applyItemSpell(owner,target,elements[(state.itemProcRoll%3)+1],amount+2,1)
            elseif id=='castWhenStruck' then
                local seen={[owner.id]=true}
                applyItemSpell(owner,target,'shockdamage',amount+3,1);seen[target.id]=true
                for _,other in ipairs(world.activeActors) do
                    if not seen[other.id] and other.cell==owner.cell and (other.position-owner.position):length()<=350
                        and hostileCandidate(other,owner) then
                        applyItemSpell(owner,other,'shockdamage',amount+3,1);seen[other.id]=true
                    end
                end
            elseif id=='command' and safeCommandTarget(target) then
                local effect=types.NPC.objectIsInstance(target) and 'commandhumanoid' or 'commandcreature'
                applyItemSpell(owner,target,effect,100,6)
            elseif id=='crushing' then
                local hp=types.Actor.stats.dynamic.health(target)
                local cap=8+proc.tier*3+proc.level*0.35
                local damage=math.min(hp.current*0.06,cap)
                local elite=state.elites[target.id]
                if elite and elite.worldBoss then damage=damage*0.35 end
                applyItemSpell(owner,target,'damagehealth',damage,1)
            elseif id=='chain' then
                local nearest,distance
                for _,other in ipairs(world.activeActors) do
                    if other~=target and other.cell==target.cell and hostileCandidate(other,owner) then
                        local d=(other.position-target.position):length()
                        if d<=500 and (not distance or d<distance) then nearest,distance=other,d end
                    end
                end
                if nearest then applyItemSpell(owner,nearest,'shockdamage',amount+1,1) end
            end
        end
    end
end
local function physicalHit(event)
    local a, b = event.attacker, event.target
    if not C.enabled or not a or not b or not a:isValid() or not b:isValid()
        or not types.Actor.objectIsInstance(a) or not types.Actor.objectIsInstance(b) then return end
    trigger(a, b, false)
    if event.melee then trigger(b, a, true) end
    triggerItemProcs(a,b,'hit',event.melee,event.forceItemProcs)
    triggerItemProcs(b,a,'struck',event.melee,event.forceItemProcs)
end
local function encounter(data)
    local actor = data.actor
    if not actor or not actor:isValid() or not eligible(actor) then return end
    local key = actor.id
    if types.Actor.isDead(actor) then
        if state.elites[key] == nil then state.elites[key] = false end
        actor:sendEvent('AshenLoot_EncounterResult', {elite = false})
        return
    end
    if state.elites[key] == nil or (data.force and (not state.elites[key] or data.rank)) then
        if data.force or R.rng(key .. ':elite')() < C.eliteChance then
            local rec = actor.type.record(actor)
            local elite = R.elite(key, rec.name, family(rec))
            local random = R.rng(key .. ':rank4')
            -- World Boss is the top rung of the promotion ladder. This roll is
            -- conditional on the actor first passing the promotion roll (or
            -- being force-promoted as a dungeon leader).
            local worldBoss=data.worldBoss or (data.allowWorldBoss and random(100)<=C.worldBossChance)
            elite.rank = worldBoss and 3 or (data.rank or (random(100)<=C.uniquePercent and 3
                or (random(100)<=C.eliteTierPercent and 2 or 1)))
            elite.tier = elite.rank >= 2 and 2 or 1
            elite.modifiers = {elite.modifiers[1]}
            -- Exclude fatigue-drain modifiers from new procedural encounters.
            local allowed = R.allowedEliteIndexes()
            if elite.modifiers[1]==5 or elite.modifiers[1]==7 then elite.modifiers[1]=allowed[random(#allowed)] end
            while #elite.modifiers < elite.rank do
                local m=allowed[random(#allowed)];local found=false
                for _,v in ipairs(elite.modifiers) do if v==m then found=true end end
                if not found then elite.modifiers[#elite.modifiers+1]=m end
            end
            if worldBoss then
                while #elite.modifiers<6 do
                    local m=allowed[random(#allowed)];local found=false
                    for _,v in ipairs(elite.modifiers) do if v==m then found=true end end
                    if not found then elite.modifiers[#elite.modifiers+1]=m end
                end
                elite.worldBoss=true
                elite.family=family(rec)
                elite.name=bossName(actor,rec)
                elite.nameVersion=types.NPC.objectIsInstance(actor) and 3 or 2
                elite.healthScale=4.5
            end
            if not elite.worldBoss then
                elite.name=rec.name .. ' ' .. R.elites[elite.modifiers[1]].epithet
                elite.healthScale=({1.2,1.5,1.9})[elite.rank]
            end
            if elite.worldBoss or elite.rank==3 then
                elite.family=elite.family or family(rec)
                elite.biography=biography(actor,elite,rec)
            end
            -- Put almost all anti-overgear durability on promoted enemies.
            -- Champions absorb 25% of the extra pressure, Elites 50%, Uniques
            -- 75%, and world bosses the full amount.
            local pressure=math.max(1,tonumber(data.gearPressure) or 1)
            local weight=elite.worldBoss and 1 or ({0.25,0.5,0.75})[elite.rank]
            elite.healthScale=elite.healthScale*(1+(pressure-1)*weight)
            elite.itemLevel=Progress.actorLevel(actor)
            elite.effectScale=math.min(elite.worldBoss and 2.5 or 2,1+math.floor(elite.itemLevel/10)*0.15)
            state.elites[key] = elite
        else state.elites[key] = false end
    end
    if state.elites[key] then prepareAbility(state.elites[key], actor) end
    actor:sendEvent('AshenLoot_EncounterResult', {elite = state.elites[key]})
end
local function giveSpellTome(actor,force,dropIndex)
    local player=world.players[1]
    if not player or C.spellTomePercent<=0 then return end
    local profile=lootProfile();local magicProfile=profile and
        (profile.key=='magic' or profile.key=='warmage' or profile.key=='conjurer')
    local multiplier=magicProfile and 3 or 0.5
    local elite=state.elites[actor.id]
    if elite and elite.worldBoss then multiplier=math.max(multiplier,6) elseif elite then multiplier=multiplier*1.5 end
    local rng=R.rng(actor.id..':spell-tome-v1')
    if not force and rng(100)>math.min(80,C.spellTomePercent*multiplier) then return end
    ensureSpellTomes()
    local level=Progress.actorLevel(actor)
    local cap=math.max(1,math.min(4,1+math.floor((level-1)/12)))
    if cap<4 and rng(100)<=10 then cap=cap+1 end
    local carried={}
    for _,book in ipairs(types.Actor.inventory(player):getAll(types.Book)) do carried[book.recordId]=true end
    local spells=types.Actor.spells(player);local candidates={}
    for _,saved in pairs(state.spellTomes) do
        if saved.tier<=cap and not spells[saved.spell] and not carried[saved.book] then candidates[#candidates+1]=saved end
    end
    table.sort(candidates,function(a,b) return a.book<b.book end)
    if #candidates==0 then return end
    local selected=candidates[rng(#candidates)]
    local book=world.createObject(selected.book,1)
    if not Progress.ground(book,actor,dropIndex) then book:moveInto(types.Actor.inventory(actor)) end
    return true
end
local function learnSpellTome(book,actor)
    if not book or not actor or not types.Player.objectIsInstance(actor) then return end
    local saved=state.spellTomesByRecord and state.spellTomesByRecord[book.recordId]
    if not saved then return end
    local spells=types.Actor.spells(actor)
    if spells[saved.spell] then return false end
    spells:add(saved.spell);book:remove(1)
    actor:sendEvent('AshenLoot_ForgeResult',{message='Learned Dreamforged spell: '..saved.name..'.'})
    return false
end
local function spellTomeUse(book,actor) return learnSpellTome(book,actor) end
local function spellTomeActivate(book,actor) return learnSpellTome(book,actor) end
local tomePickupElapsed=0
local function updateSpellTomePickup(dt)
    tomePickupElapsed=tomePickupElapsed+dt
    if tomePickupElapsed<0.2 then return end
    tomePickupElapsed=0
    local player=world.players[1]
    if not player then return end
    for _,book in ipairs(types.Actor.inventory(player):getAll(types.Book)) do
        if state.spellTomesByRecord and state.spellTomesByRecord[book.recordId] then
            learnSpellTome(book,player)
            return
        end
    end
end
local function death(actor)
    if not actor or not actor:isValid() or not eligible(actor) or not types.Actor.isDead(actor) then return end
    if state.rewards[actor.id] then return end
    state.rewards[actor.id] = true
    Progress.supplies(actor)
    local elite = state.elites[actor.id]
    Progress.victoryRespite(actor,elite)
    local worldBoss=elite and elite.worldBoss
    local rank=elite and (worldBoss and 4 or (elite.rank or 1)) or 0
    local attempts=({[0]=1,[1]=2,[2]=3,[3]=4,[4]=6})[rank]
    local chance=math.min(100,C.normalDropChance*100+({[0]=0,[1]=20,[2]=35,[3]=50,[4]=100})[rank])
    -- Ordinary promotions should almost always make a visible loot burst while
    -- preserving a tiny dry-kill possibility. World Bosses reach 100% here and
    -- route all six successes through their dedicated seven-tier table below.
    if rank>0 and rank<4 then chance=math.max(97,chance) end
    local rarityBonus=({[0]=0,[1]=8,[2]=18,[3]=30,[4]=40})[rank]+math.min(20,gearOverage())
    local profile=lootProfile();local magicProfile=profile and
        (profile.key=='magic' or profile.key=='warmage' or profile.key=='conjurer')
    for attempt=1,attempts do
        local rng=R.rng(actor.id..':reward-attempt:'..attempt)
        if rng(100)<=chance then
            local familyRoll=rng(100)
            -- Keep the same family gradient used by the base-item selector:
            -- weapons 50%, armor 40%, garments 5%, jewelry/accessories 5%.
            local family=familyRoll<=50 and 'weapon'
                or (familyRoll<=90 and 'armor'
                or (familyRoll<=95 and 'clothing' or 'accessory'))
            -- The tome branch moved from a 10%-share accessory family to the
            -- 50%-share weapon family. Normalize the in-branch chance so the
            -- overall drop rate stays close to the previous behavior while
            -- still preserving the Magic profile's 3x preference.
            local tomeChance=math.min(90,C.spellTomePercent*(magicProfile and 3 or 0.5)*0.2)
            -- Spell tomes are mage weapons in the loot taxonomy: they fill
            -- the same reward slot as staves/wands instead of consuming the
            -- small universal accessory share. Non-mages never replace their
            -- accessory drops with a tome.
            local madeTome=not worldBoss and magicProfile and family=='weapon'
                and rng(100)<=tomeChance and giveSpellTome(actor,true,attempt)
            if not madeTome then
                if worldBoss then
                    local bossSeed=actor.id..':world-boss-loot:'..attempt
                    local bossTier=R.worldBossRarity(R.rng(bossSeed..':tier'),worldBossRewardBonus(actor))
                    if bossTier==7 then giveMythic(actor,bossSeed,attempt)
                    else giveLoot(actor,bossSeed,1,nil,bossTier,nil,nil,family,0,attempt) end
                else
                    giveLoot(actor,actor.id..':loot:'..attempt,1,nil,nil,nil,
                        nil,family,rarityBonus,attempt)
                end
            end
        end
    end
end
Progress.bind(state,giveLoot,encounter,eligible)
local function snapshot(player)
    player = player or world.players[1]
    if not player then return end
    local forge=state.forgePoints and state.forgePoints[player.id] or {0,0,0,0,0,0}
    player:sendEvent('AshenLoot_Snapshot', {records = state.records, elites = state.elites, forgePoints=forge})
    -- Fresh Loot owns its state. Read only the current inventory's tracked items.
    if I.FreshLoot and I.FreshLoot.getState then
        local fresh = I.FreshLoot.getState()
        local items = {}
        for _, item in ipairs(types.Actor.inventory(player):getAll()) do
            local old = fresh.items and fresh.items[item.id]
            if old then items[#items + 1] = {recordId = item.recordId, lvlModIds = old.lvlModIds} end
        end
        player:sendEvent('FreshLoot_save_modded_records', items)
    end
end
local autoSalvageCounts,autoSalvageElapsed={},0
local autoSalvageSettings={'autoSalvageCommon','autoSalvageUncommon','autoSalvageRare','autoSalvageEpic','autoSalvageLegendary','autoSalvageRelic'}
local function generatedInventoryCounts(player)
    local counts={}
    for _,item in ipairs(types.Actor.inventory(player):getAll()) do
        if state.records[item.recordId] then counts[item.recordId]=(counts[item.recordId] or 0)+item.count end
    end
    return counts
end
local function refreshAutoSalvageBaseline(player)
    if player and player:isValid() then autoSalvageCounts=generatedInventoryCounts(player) end
end
local function updateAutoSalvage(dt)
    autoSalvageElapsed=autoSalvageElapsed+dt
    if autoSalvageElapsed<0.25 then return end
    autoSalvageElapsed=0
    local player=world.players[1]
    if not player then return end
    local current=generatedInventoryCounts(player)
    if not C.enabled then autoSalvageCounts=current;return end
    local equipped={}
    for _,item in pairs(types.Actor.getEquipment(player)) do equipped[item.recordId]=true end
    local points=state.forgePoints and state.forgePoints[player.id] or {0,0,0,0,0,0}
    local salvaged={0,0,0,0,0,0};local total=0
    local inventory=types.Actor.inventory(player)
    for recordId,count in pairs(current) do
        local meta=state.records[recordId]
        local tier=meta and math.max(1,math.min(6,math.floor(meta.tier or 1))) or 1
        local added=count-(autoSalvageCounts[recordId] or 0)
        if added>0 and not meta.mythic and C[autoSalvageSettings[tier]] and not equipped[recordId] then
            local remaining=added
            for _,stack in ipairs(inventory:findAll(recordId)) do
                if not types.Actor.hasEquipped(player,stack) then
                    local take=math.min(remaining,stack.count)
                    stack:remove(take);remaining=remaining-take
                    if remaining<=0 then break end
                end
            end
            local removed=added-remaining
            if removed>0 then
                points[tier]=(points[tier] or 0)+removed;salvaged[tier]=salvaged[tier]+removed;total=total+removed
            end
        end
    end
    state.forgePoints=state.forgePoints or {};state.forgePoints[player.id]=points
    refreshAutoSalvageBaseline(player)
    if total>0 then
        local parts={}
        for tier=1,6 do if salvaged[tier]>0 then parts[#parts+1]=salvaged[tier]..' '..R.rarities[tier].name end end
        snapshot(player);player:sendEvent('AshenLoot_ForgeResult',{message='Auto-salvaged '..table.concat(parts,', ')..' item(s) into forging coins.'})
    end
end
local function forgeResult(player,message)
    snapshot(player);player:sendEvent('AshenLoot_ForgeResult',{message=message})
end
local function salvage(data)
    local player,item=data and data.player,data and data.item
    if not player or not player:isValid() or not item or not item:isValid()
        or item.parentContainer~=player then return end
    if types.Actor.hasEquipped(player,item) then forgeResult(player,'Equipped items are protected.');return end
    local meta=state.records[item.recordId]
    if not meta or not meta.tier then forgeResult(player,'Only Dreamforged generated items can be salvaged.');return end
    if meta.mythic then forgeResult(player,'Mythic artifacts cannot be reduced to ordinary forging coins.');return end
    local tier=math.max(1,math.min(6,math.floor(meta.tier)))
    state.forgePoints=state.forgePoints or {}
    local points=state.forgePoints[player.id] or {0,0,0,0,0,0}
    points[tier]=(points[tier] or 0)+1;state.forgePoints[player.id]=points
    item:remove(1)
    forgeResult(player,'Salvaged '..meta.name..' for 1 forging coin.')
end
local function reforge(data)
    local player=data and data.player
    local tier=math.max(1,math.min(6,math.floor(tonumber(data and data.tier) or 1)))
    if not player or not player:isValid() then return end
    state.forgePoints=state.forgePoints or {}
    local points=state.forgePoints[player.id] or {0,0,0,0,0,0}
    if (points[tier] or 0)<5 then forgeResult(player,'You need 5 '..R.rarities[tier].name..' forging coins.');return end
    local inventory=types.Actor.inventory(player)
    points[tier]=points[tier]-5;state.forgePoints[player.id]=points
    state.forgeSerial=(state.forgeSerial or 0)+1
    local made=giveLoot(player,player.id..':reforge:'..state.forgeSerial,tier,nil,tier,nil,inventory)
    if not made then
        points[tier]=points[tier]+5
        forgeResult(player,'The reforge failed; your coins were returned.');return
    end
    -- A purchased reforge is an intentional keep, not ordinary newly acquired
    -- loot. Refreshing immediately prevents an enabled rarity filter from
    -- consuming the item on the next inventory scan.
    refreshAutoSalvageBaseline(player)
    forgeResult(player,'Reforged a random '..R.rarities[tier].name..' item for 5 coins.')
end
local function combineForgeCoins(data)
    local player=data and data.player
    local tier=math.max(1,math.min(5,math.floor(tonumber(data and data.tier) or 1)))
    if not player or not player:isValid() then return end
    state.forgePoints=state.forgePoints or {}
    local points=state.forgePoints[player.id] or {0,0,0,0,0,0}
    if (points[tier] or 0)<3 then
        forgeResult(player,'You need 3 '..R.rarities[tier].name..' forging coins to combine them.');return
    end
    points[tier]=points[tier]-3
    points[tier+1]=(points[tier+1] or 0)+1
    state.forgePoints[player.id]=points
    forgeResult(player,'Combined 3 '..R.rarities[tier].name..' coins into 1 '..R.rarities[tier+1].name..' forging coin.')
end
local function guard(fn)
    return function(data)
        local ok, err = pcall(fn, data)
        if not ok then print('[AshenLoot] ERROR: ' .. tostring(err)) end
    end
end
local function startingKit(data)
    if not data or not data.player or not data.player:isValid() then return end
    local kit = startingKits[data.class]
    if not kit then return end
    local inventory = types.Actor.inventory(data.player)
    for _, entry in ipairs(kit) do
        world.createObject(entry[1], entry[2]):moveInto(inventory)
    end
    local spells = types.Actor.spells(data.player)
    for _, id in ipairs(startingSpells[data.class] or {}) do
        if not spells[id] then spells:add(id) end
    end
end
return {
    interfaceName = 'AshenLoot',
    interface = {version = 4, eligible = eligible, getState = function() return state end, progression=Progress,
        test = {giveLoot = giveLoot, encounter = encounter, death = death, snapshot = snapshot, physicalHit=physicalHit,
            startingKit = startingKit,reconcileAdvancement=reconcileAdvancement,useAdvancement=useAdvancement,
            mythicImpact=mythicImpact,mythicDefinitions=mythicDefinitions,getPool=getPool,mythicChance=mythicChance,
            worldBossRewardBonus=worldBossRewardBonus,
            ensureSpellTomes=ensureSpellTomes,tomeDefinitions=tomeDefinitions,learnSpellTome=learnSpellTome,
            refreshContentPools=function() pool=nil;Progress.refreshPools() end}},
    engineHandlers = {
        onInit = function()
            assert(supported(), 'Ashen Loot requires OpenMW 0.51 or newer')
            if I.ItemUsage and not tomeHandlerRegistered then
                I.ItemUsage.addHandlerForType(types.Book,spellTomeUse);tomeHandlerRegistered=true
            end
            if I.Activation then I.Activation.addHandlerForType(types.Book,spellTomeActivate) end
            if I.protectedbeasts and not beastHandlerRegistered then
                I.ItemUsage.addHandlerForType(types.Armor, beastArmorEquip)
                beastHandlerRegistered = true
            end
            if I.Projectiles and not projectileHandlerRegistered then
                I.Projectiles.addOnProjectileHitHandler(I.Projectiles.TYPES.Magic,function(projectile,hit)
                    local data=projectile.userData or {}
                    local target=hit and hit.hitObject
                    local item=data.item or data.sourceItem
                    local caster=data.caster or data.actor
                    local ok,err=pcall(mythicImpact,item,caster,target)
                    if not ok then print('[AshenLoot] ERROR mythic projectile: '..tostring(err)) end
                end)
                projectileHandlerRegistered=true
            end
        end,
        onActorActive = guard(attach), onPlayerAdded = guard(function(player) snapshot(player);refreshAutoSalvageBaseline(player) end),
        onUpdate = function(dt)
            local ok,err=pcall(Progress.update,dt)
            if not ok then print('[AshenLoot] ERROR director: '..tostring(err)) end
            local salvageOk,salvageErr=pcall(updateAutoSalvage,dt)
            if not salvageOk then print('[AshenLoot] ERROR auto-salvage: '..tostring(salvageErr)) end
            local tomeOk,tomeErr=pcall(updateSpellTomePickup,dt)
            if not tomeOk then print('[AshenLoot] ERROR spell tome pickup: '..tostring(tomeErr)) end
            if state.mythicSummons then
                local now=core.getSimulationTime()
                for id,expires in pairs(state.mythicSummons) do
                    local found
                    for _,actor in ipairs(world.activeActors) do if actor.id==id then found=actor;break end end
                    if now>=expires then if found and found:isValid() then found:remove() end;state.mythicSummons[id]=nil end
                end
            end
            enrollmentTimer = enrollmentTimer + dt
            if enrollmentTimer < 1 then return end
            enrollmentTimer = 0
            local coverage = tostring(C.enabled) .. tostring(C.protectQuestActors) .. tostring(C.allowRespawningNPCs)
                .. tostring(C.unsafeContent)
            if coverage == lastCoverage then return end
            lastCoverage = coverage
            pool=nil;Progress.refreshPools()
            for _, actor in ipairs(world.activeActors) do attach(actor) end
        end,
        onSave = function() return state end,
        onLoad = function(data)
            state = data or state; pool = nil; lastCoverage = '';autoSalvageCounts={};autoSalvageElapsed=0
            local oldVersion=state.version or 1
            state.procs, state.cooldowns = state.procs or {}, state.cooldowns or {}
            state.itemSpells,state.itemCooldowns,state.itemProcRoll=state.itemSpells or {},state.itemCooldowns or {},state.itemProcRoll or 0
            state.advancementRecords,state.advancementEarned,state.advancementUses=
                state.advancementRecords or {},state.advancementEarned or {},state.advancementUses or {}
            state.mythicSummons=state.mythicSummons or {}
            state.forgePoints,state.forgeSerial=state.forgePoints or {},state.forgeSerial or 0
            state.spellTomes,state.spellTomesByRecord=state.spellTomes or {},state.spellTomesByRecord or {}
            if state.version == 1 then
                for _, elite in pairs(state.elites) do if elite then elite.healthModel = 1 end end
                state.version = 2
            end
            if oldVersion<6 then
                local settings=storage.globalSection(C.groupKey('exteriorSpread'))
                if settings:get('exteriorSpread')==3000 then settings:set('exteriorSpread',1000) end
            end
            if oldVersion<8 and state.director and state.director.loose then
                for _,loose in pairs(state.director.loose) do
                    if type(loose)=='table' and loose.light and loose.light:isValid() then loose.light:remove();loose.light=nil end
                end
            end
            if oldVersion<14 and state.director then
                -- Reconsider native anchors as their cells reactivate. Existing
                -- generated counts persist, so only unfilled budget is added.
                state.director.actors={}
            end
            if oldVersion<15 then
                -- Preserve the user's existing values while splitting the old
                -- monolithic settings list into player-facing category groups.
                local legacy=storage.globalSection('SettingsAshenLoot')
                for key in pairs(C.defaults) do
                    local destination=C.groupKey(key)
                    if destination~='SettingsAshenLoot' then
                        local value=legacy:get(key)
                        if value~=nil then storage.globalSection(destination):set(key,value) end
                    end
                end
            end
            if oldVersion<16 and state.director then
                -- Reconsider native exterior anchors under the adjacent-cell
                -- activation band while preserving already-generated counts.
                state.director.actors={}
            end
            if oldVersion<20 then
                -- Insert Common below the legacy five-tier ladder without
                -- downgrading saved equipment or coin balances.
                for _,meta in pairs(state.records or {}) do
                    if meta and meta.tier then
                        meta.tier=math.min(6,meta.tier+1)
                        meta.rarity=meta.mythic and 'Mythic' or R.rarities[meta.tier].name
                    end
                end
                for playerId,old in pairs(state.forgePoints or {}) do
                    state.forgePoints[playerId]={0,old[1] or 0,old[2] or 0,old[3] or 0,old[4] or 0,old[5] or 0}
                end
                local lootSettings=storage.globalSection(C.groups.loot)
                if lootSettings:get('autoSalvageMagic') then lootSettings:set('autoSalvageUncommon',true) end
            end
            if oldVersion<21 then
                local interfaceSettings=storage.globalSection(C.groups.interface)
                if interfaceSettings:get('forgeKey')=='F9' then interfaceSettings:set('forgeKey','F10') end
            end
            if oldVersion<22 then
                local interfaceSettings=storage.globalSection(C.groups.interface)
                local forgeKey=interfaceSettings:get('forgeKey')
                if forgeKey=='F9' or forgeKey=='F10' then interfaceSettings:set('forgeKey','F2') end
            end
            if oldVersion<23 then
                local interfaceSettings=storage.globalSection(C.groups.interface)
                if interfaceSettings:get('forgeKey')=='F2' then interfaceSettings:set('forgeKey','F7') end
            end
            if oldVersion<24 and state.director and state.director.cells then
                -- Make the population budget's meaning explicit for old saves:
                -- it tracks Dreamforged additions only, never native actors.
                for _,cellState in pairs(state.director.cells) do
                    cellState.additionalCount=math.max(0,tonumber(cellState.additionalCount)
                        or tonumber(cellState.count) or 0)
                    cellState.count=nil
                end
            end
            if oldVersion<25 then
                local encounterSettings=storage.globalSection(C.groups.encounters)
                if encounterSettings:get('exteriorSpawnMin')==450 then encounterSettings:set('exteriorSpawnMin',1200) end
                if encounterSettings:get('exteriorSpread')==1000 then encounterSettings:set('exteriorSpread',2200) end
            end
            state.version = 26
            Progress.bind(state,giveLoot,encounter,eligible)
        end,
    },
    eventHandlers = {
        AshenLoot_Prepare = guard(Progress.prepare),
        AshenLoot_Salvage = guard(salvage),
        AshenLoot_Reforge = guard(reforge),
        AshenLoot_CombineForgeCoins = guard(combineForgeCoins),
        AshenLoot_PrepareFighting = guard(function(actor) Progress.prepare(actor,true) end),
        AshenLoot_SpawnResult = guard(Progress.spawnResult),
        AshenLoot_BossWave = guard(Progress.bossWave),
        AshenLoot_ReplacementResult = guard(Progress.replaceResult),
        AshenLoot_Scavenge = guard(Progress.scavenge),
        AshenLoot_AlignGroundDropResult = guard(function(event)
            local loose=event and state.director and state.director.loose and state.director.loose[event.id]
            local item=loose and loose.item
            if not item or not item:isValid() then return end
            if event.position and not item.parentContainer and item.cell then
                item:teleport(item.cell,event.position,item.rotation)
                local light=loose.light
                if light and light:isValid() and light.cell==item.cell then
                    light:teleport(item.cell,event.position+util.vector3(0,0,6),light.rotation)
                end
            end
            if item:hasScript('scripts/ashenloot/drop.lua') then
                item:removeScript('scripts/ashenloot/drop.lua')
            end
        end),
        AshenLoot_PhysicalHit = guard(physicalHit),
        AshenLoot_Encounter = guard(encounter), AshenLoot_Death = guard(death),
        AshenLoot_Promoted = guard(function(actor)
            if not actor or not actor:isValid() or not eligible(actor) then return end
            local elite, player = state.elites[actor.id], world.players[1]
            if player and elite then player:sendEvent('AshenLoot_Elite', {id = actor.id, metadata = elite}) end
        end),
        AshenLoot_Request = guard(function() snapshot() end),
        AshenLoot_StartingKit = guard(startingKit),
        AshenLoot_AdvancementReconcile = guard(reconcileAdvancement),
        AshenLoot_UseAdvancement = guard(useAdvancement),
        AshenLoot_ApplyTargetedAdvancement = guard(applyTargetedAdvancement),
        AshenLoot_Demo = guard(function()
            for tier = 1, 4 do giveLoot(world.players[1], 'demo:' .. tier, tier, 'iron longsword', tier) end
            snapshot()
        end),
    },
}
