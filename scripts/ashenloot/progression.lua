-- Standalone 0.4 director. No third-party mod code or assets.
local core, types, world = require('openmw.core'), require('openmw.types'), require('openmw.world')
local util = require('openmw.util')
local C, R = require('scripts.ashenloot.config'), require('scripts.ashenloot.rules')
local Records = require('scripts.ashenloot.records')
local M = {}
local state, loot, promote, eligible
local pools, gear, itemPools, kindPools, pending = nil, nil, nil, nil, {}
local genericCreatureIds
local timer, considered, lastPlayerCell = 0, {}, nil
local function valid(a) return a and a:isValid() and a.enabled and not types.Actor.isDead(a) end
local function additionalCount(cellState)
    return math.max(0,math.floor(tonumber(cellState and cellState.additionalCount) or 0))
end
local function setAdditionalCount(cellState,value)
    cellState.additionalCount=math.max(0,math.floor(tonumber(value) or 0))
end
local function isGuard(actor)
    if not actor or not types.NPC.objectIsInstance(actor) then return false end
    local rec=actor.type.record(actor)
    local text=((rec.id or '')..' '..(rec.name or '')):lower()
    for _,word in ipairs({'guard','ordinator','her hand','hands of almalexia'}) do
        if text:find(word,1,true) then return true end
    end
    return false
end
local function isAggressive(actor)
    return actor and actor:isValid() and not types.Actor.isDead(actor)
        and types.Actor.stats.ai.fight(actor).base>=80
end
local function worldBossScale(actor)
    local rec=actor.type.record(actor)
    local name=((rec.id or '')..' '..(rec.name or '')..' '..(rec.model or '')):lower()
    local small=false
    for _,word in ipairs({'scrib','rat','crab','forager','fish','spider','scamp','grub','beetle'}) do
        if name:find(word,1,true) then small=true;break end
    end
    local large=false
    for _,word in ipairs({'ogrim','daedroth','centurion','titan','giant','bear','mammoth','golem'}) do
        if name:find(word,1,true) then large=true;break end
    end
    local exterior=actor.cell and actor.cell.isExterior or false
    local factor
    if exterior then factor=large and 2 or (small and 5 or 3)
    else factor=large and 1.15 or (small and 3 or 1.7) end
    return math.min(exterior and 6 or 3.25,actor.scale*factor),factor
end
local function activeWorldBosses(cell)
    local count=0
    for _,other in ipairs(world.activeActors) do
        local elite=state.elites[other.id]
        if other.cell==cell and elite and elite.worldBoss and not types.Actor.isDead(other) then count=count+1 end
    end
    return count
end
local function level() return math.max(1,types.Actor.stats.level(world.players[1]).current) end
local function gearSlots(item)
    local S=types.Actor.EQUIPMENT_SLOT
    if types.Weapon.objectIsInstance(item) then
        local rec=types.Weapon.record(item)
        return rec and rec.type<=types.Weapon.TYPE.MarksmanCrossbow and {S.CarriedRight}
    elseif types.Armor.objectIsInstance(item) then
        local rec=types.Armor.record(item)
        local armorSlots={
            [types.Armor.TYPE.Helmet]=S.Helmet,[types.Armor.TYPE.Cuirass]=S.Cuirass,
            [types.Armor.TYPE.Greaves]=S.Greaves,[types.Armor.TYPE.LPauldron]=S.LeftPauldron,
            [types.Armor.TYPE.RPauldron]=S.RightPauldron,[types.Armor.TYPE.LGauntlet]=S.LeftGauntlet,
            [types.Armor.TYPE.RGauntlet]=S.RightGauntlet,[types.Armor.TYPE.LBracer]=S.LeftGauntlet,
            [types.Armor.TYPE.RBracer]=S.RightGauntlet,[types.Armor.TYPE.Shield]=S.CarriedLeft}
        local slot=rec and armorSlots[rec.type]
        return slot and {slot}
    elseif types.Clothing.objectIsInstance(item) then
        local rec=types.Clothing.record(item)
        local slots={
            [types.Clothing.TYPE.Amulet]={S.Amulet}, [types.Clothing.TYPE.Belt]={S.Belt},
            [types.Clothing.TYPE.LGlove]={S.LeftGauntlet}, [types.Clothing.TYPE.Pants]={S.Pants},
            [types.Clothing.TYPE.RGlove]={S.RightGauntlet}, [types.Clothing.TYPE.Ring]={'ring'},
            [types.Clothing.TYPE.Robe]={S.Robe}, [types.Clothing.TYPE.Shirt]={S.Shirt},
            [types.Clothing.TYPE.Shoes]={S.Boots}, [types.Clothing.TYPE.Skirt]={S.Skirt},
        }
        return rec and slots[rec.type]
    end
end
local function gearLevel()
    local player=world.players[1]
    local playerLevel=level()
    if not player or not state or not state.records then return playerLevel end
    local best, rings, seen = {}, {}, {}
    local inventory=types.Actor.inventory(player)
    local function consider(item)
        if not item or not item.recordId or seen[item.id] then return end
        seen[item.id]=true
        local meta=state.records[item.recordId]
        if not meta or not (meta.level or meta.dropLevel) then return end
        local itemLevel=tonumber(meta.level or meta.dropLevel) or playerLevel
        -- Rarity represents multiplicative affix power that raw drop level does
        -- not capture. Relics in particular can dominate a build many levels
        -- before their nominal drop level would look threatening.
        local rarityPremium=({[1]=0,[2]=4,[3]=10,[4]=18,[5]=28})[tonumber(meta.tier) or 1] or 0
        local qualityPremium=math.max(0,(tonumber(meta.baseQualityTier) or 1)-1)*2
        local score=itemLevel+rarityPremium+qualityPremium
        for _,slot in ipairs(gearSlots(item) or {}) do
            if slot=='ring' then rings[#rings+1]={id=item.id,score=score,count=math.max(1,item.count or 1)}
            elseif not best[slot] or score>best[slot].score then best[slot]={id=item.id,score=score} end
        end
    end
    for _,item in ipairs(inventory:getAll()) do consider(item) end
    -- Equipped objects are normally part of Actor.inventory, but considering
    -- them explicitly also covers engine versions that expose them separately.
    for _,item in pairs(types.Actor.getEquipment(player)) do
        consider(item)
    end
    table.sort(rings,function(a,b) return a.score>b.score end)
    local ringSlots={}
    for _,candidate in ipairs(rings) do
        if candidate.count>0 and not ringSlots[1] then ringSlots[1]=candidate;break end
    end
    if ringSlots[1] then
        for index=2,#rings do
            if rings[index].id~=ringSlots[1].id or rings[index].count>1 then ringSlots[2]=rings[index];break end
        end
    end
    if ringSlots[1] then best[types.Actor.EQUIPMENT_SLOT.LeftRing]=ringSlots[1] end
    if ringSlots[2] then best[types.Actor.EQUIPMENT_SLOT.RightRing]=ringSlots[2] end
    local total,count=0,0
    for _,entry in pairs(best) do total=total+entry.score;count=count+1 end
    if count==0 then return playerLevel end
    local average=total/count
    local influence=math.max(0,math.min(1,tonumber(C.gearLevelInfluence) or 0.5))
    return math.max(playerLevel,math.floor(playerLevel+(average-playerLevel)*influence+0.5))
end
local function prestigeScale(effectiveLevel)
    -- Preserve the established curve through level 100, then keep uncapped
    -- leveling meaningful as a direct multiplier. Level 500 therefore means
    -- 5x baseline health/strength before promotion.
    return math.max(1,effectiveLevel/100)
end
local directDamageEffects={damagehealth=true,firedamage=true,frostdamage=true,shockdamage=true,
    poison=true}
local function effectDamage(effect)
    if not effect or not directDamageEffects[effect.id] then return 0 end
    local low=tonumber(effect.magnitudeMin) or 0
    local high=tonumber(effect.magnitudeMax) or low
    -- Use the charged/high end of a single effect, but never sum every proc on
    -- an item. Morrowind's damage swing is discrete; treating a whole list of
    -- on-hit effects as simultaneous sustained DPS made promoted health grow
    -- far beyond what first-person combat can reasonably absorb.
    local amount=math.max(0,high)
    -- Damage-over-time effects contribute a small first-tick allowance only;
    -- later ticks depend on the target staying in range and are not used to
    -- inflate an encounter's durability target.
    if (tonumber(effect.duration) or 0)>1 then amount=amount*1.15 end
    return amount
end
local function enchantmentDamage(enchantId)
    if not enchantId or not core.magic.enchantments.records then return 0 end
    local enchant=core.magic.enchantments.records[enchantId]
    if not enchant then return 0 end
    local best=0
    for _,effect in pairs(enchant.effects or {}) do best=math.max(best,effectDamage(effect)) end
    return best
end
local function playerDamageProfile()
    local player=world.players[1]
    local director=state and state.director
    local now=core.getSimulationTime()
    if director and director.playerDamageProfileAt and now-director.playerDamageProfileAt<10
        and director.playerDamageProfile then
        return director.playerDamageProfile
    end
    if not player or not player:isValid() then
        return {hit=1,rawHit=1,bestWeapon=1,bestSpell=0,cadence=2,dps=0.5,score=1,band=1}
    end
    local bestWeapon,bestSpell=0,0
    local seen={}
    local function considerWeapon(item)
        if not item or seen[item.id] or not types.Weapon.objectIsInstance(item) then return end
        seen[item.id]=true
        local record=types.Weapon.record(item)
        if not record or record.type>types.Weapon.TYPE.MarksmanCrossbow then return end
        local damage=math.max(record.chopMaxDamage or 0,record.slashMaxDamage or 0,record.thrustMaxDamage or 0)
        -- Physical damage plus the strongest single on-hit effect is one
        -- charged attack. A second proc is not assumed to stack reliably.
        bestWeapon=math.max(bestWeapon,damage+enchantmentDamage(record.enchant))
    end
    local inventory=types.Actor.inventory(player)
    if inventory then for _,item in ipairs(inventory:getAll()) do considerWeapon(item) end end
    for _,item in pairs(types.Actor.getEquipment(player)) do considerWeapon(item) end
    local known=types.Actor.spells(player)
    for _,spell in pairs(core.magic.spells.records or {}) do
        if spell and spell.id and known[spell.id] then
            local damage=0
            for _,effect in pairs(spell.effects or {}) do damage=damage+effectDamage(effect) end
            if damage>0 then bestSpell=math.max(bestSpell,damage) end
        end
    end
    local rawHit=math.max(1,bestWeapon,bestSpell)
    -- One charged attack/cast is modeled as roughly two seconds. A modest
    -- reliability factor accounts for misses, fatigue, movement, and healing
    -- without pretending the player stands still and lands every maximum hit.
    local feedback=director and director.combat and tonumber(director.combat.killFactor) or 1
    feedback=math.max(0.75,math.min(1.25,feedback))
    local reliableHit=math.max(1,rawHit*0.75/math.max(0.75,feedback))
    local effectiveLevel=gearLevel()
    -- Ten broad bands keep the director stable. Level/gear remains the main
    -- signal, while an exceptional weapon can lift a low-level character a
    -- few bands without making every recalculation snowball.
    local score=math.max(effectiveLevel,math.ceil(rawHit/12))
    local band=math.max(1,math.min(10,math.ceil(score/5)))
    local profile={hit=reliableHit,rawHit=rawHit,bestWeapon=bestWeapon,bestSpell=bestSpell,
        cadence=2,dps=reliableHit/2,score=score,band=band,feedback=feedback}
    if director then
        director.playerDamageProfile=profile
        director.playerDamageProfileAt=now
        director.playerDps=profile.dps
        director.playerDpsAt=now
    end
    return profile
end
local function playerCombatDps()
    return playerDamageProfile().dps
end
local function gearHealthScale(effectiveLevel,playerLevel,dps)
    -- Legacy score helper retained for saved/test API compatibility. Promoted
    -- HP no longer consumes this value; the bounded charged-hit profile in
    -- global.lua is the sole durability response to player damage.
    local levelScale=math.min(3,1+math.max(0,effectiveLevel-playerLevel)*0.10)
    if not dps then return levelScale end
    local expected=math.max(3,1.7+playerLevel*1.15)
    local ratio=math.max(0.5,math.min(5,dps/expected))
    local combatScale=math.max(0.9,math.min(1.25,0.95+(ratio-1)*0.08))
    return math.min(3,levelScale*combatScale)
end
local function cellKey(cell) return cell.id end
local function dungeon(cell)
    if cell.isExterior then return false end
    local n = cell.name:lower()
    for _, word in ipairs({'tomb','shrine','ruin','cavern','cave','grotto','daedric','crypt','stronghold','mine'}) do
        if n:find(word,1,true) then return true end
    end
    -- Most vanilla caves have proper names rather than the word "cave".
    for _,word in ipairs({'guild','temple','house','manor','shop','tavern','tradehouse','inn','canton','palace'}) do
        if n:find(word,1,true) then return false end
    end
    for _,actor in ipairs(world.activeActors) do
        if actor.cell==cell then
            for _,offered in pairs(actor.type.record(actor).servicesOffered or {}) do if offered then return false end end
        end
    end
    return true -- Called only after a protected/hostile eligibility check.
end
local function buildGenericCreatureIds()
    if genericCreatureIds then return end
    genericCreatureIds={}
    local visiting={}
    local function addList(list)
        if not list or visiting[list.id] then return end
        visiting[list.id]=true
        for _,entry in ipairs(list.creatures or {}) do
            if types.Creature.records[entry.id] then genericCreatureIds[entry.id:lower()]=true
            else addList(types.LevelledCreature.records[entry.id]) end
        end
    end
    for _,list in pairs(types.LevelledCreature.records) do addList(list) end
end
local function ordinaryCreatureRecord(rec)
    if not rec or rec.isEssential then return false end
    buildGenericCreatureIds()
    local id=rec.id:lower()
    if id:find('^generated:') then return false end
    for _,word in ipairs({'unique','summon','_pet','_quest'}) do if id:find(word,1,true) then return false end end
    -- Many expansion and creature-pack records are not placed in a leveled list
    -- and do not mark the base record as respawning. Admit unscripted records as
    -- ordinary archetypes; retain the stronger respawn/list requirement only
    -- for scripted creatures so quest specimens stay behind Unsafe Chaos.
    if rec.mwscript and not rec.isRespawning and not genericCreatureIds[id] then return false end
    for _, v in pairs(rec.servicesOffered or {}) do if v then return false end end
    return true
end
local function safeRecord(rec)
    if not rec then return false end
    if C.unsafeContent then return not rec.id:find('^generated:') end
    return ordinaryCreatureRecord(rec)
end
local function populationAnchor(actor)
    local rec=actor and actor.type.record(actor)
    if not rec then return false end
    if types.Creature.objectIsInstance(actor) then return ordinaryCreatureRecord(rec) end
    if rec.mwscript or rec.isEssential then return false end
    for _,v in pairs(rec.servicesOffered or {}) do if v then return false end end
    return true
end
local function family(rec)
    if rec.type == types.Creature.TYPE.Undead then return 'undead' end
    if rec.type == types.Creature.TYPE.Daedra then return 'daedra' end
    local s = (rec.id .. ' ' .. (rec.model or '')):lower()
    if s:find('centurion') or s:find('sphere') or s:find('steam') then return 'construct' end
    return 'beast'
end
local function estimatedLevel(rec)
    local attack=0
    for index,value in ipairs(rec.attack or {}) do if index%2==0 then attack=math.max(attack,value) end end
    local skill=math.max(rec.combatSkill or 0,rec.magicSkill or 0,rec.stealthSkill or 0)
    return math.max(1,math.min(100,math.floor(0.5+math.max((skill-15)/3.2,attack/1.4,math.sqrt(rec.soulValue or 0)*1.4))))
end
local function buildPools()
    if pools then return end
    pools = {beast={},undead={},daedra={},construct={},all={}}
    -- Authored estimates improve Similar mode. Every otherwise-safe walking or
    -- flying record still enters Random mode, including expansion/mod content.
    local tiers = {rat=1, kwama=3, scrib=1, nix=5, alit=4, kagouti=8, guar=4,
        cliff=5, wolf=6, bear=12, horker=6, skeleton=5, ghost=5, bonelord=15,
        bonewalker=10, scamp=5, clannfear=12, daedroth=18, dremora=20,
        golden=30, ogrim=22, atronach=18, spider=8, sphere=14, steam=24}
    local vanilla={rat=1,scrib=1,kwamaforager=2,kwamaworker=3,kwamawarrior=6,nixhound=5,alit=4,kagouti=8,guar=4,
        skeleton=5,skeletonarcher=7,ancestorghost=5,bonewalker=10,greaterbonewalker=16,bonelord=15,
        scamp=5,clannfear=12,daedroth=18,dremora=20,goldensaint=30,ogrim=22,ogrimtitan=26,
        flameatronach=18,frostatronach=20,stormatronach=25,centurionspider=8,centurionsphere=14,steamcenturion=24}
    for _, rec in pairs(types.Creature.records) do
        if safeRecord(rec) and (rec.canWalk or rec.canFly) and not (rec.canSwim and not rec.canWalk and not rec.canFly)
            and not rec.id:find('$',1,true) then
            local s = (rec.id .. ' ' .. (rec.model or '')):lower()
            local estimate=vanilla[(rec.id:lower():gsub('[ _%-]',''))]
            if rec.id:match('^t_') or rec.id:match('^bm_') then
                for word, value in pairs(tiers) do if s:find(word,1,true) then estimate = math.max(estimate or 1,value) end end
            end
            estimate=estimate or estimatedLevel(rec)
            local f = family(rec)
            local entry={id=rec.id,level=estimate,family=f,flies=rec.canFly and not rec.canWalk}
            pools[f][#pools[f]+1] = entry
            pools.all[#pools.all+1]=entry
        end
    end
    for _, pool in pairs(pools) do table.sort(pool,function(a,b) return a.id < b.id end) end
end
local function isCliff(id)
    id=(id or ''):lower()
    return id:find('cliff',1,true) and id:find('racer',1,true)
end
local function pickCreature(actor, target, rng, extra)
    buildPools()
    local rec = actor.type.record(actor)
    if not types.Creature.objectIsInstance(actor) then return actor.recordId end
    local candidates = {}
    if extra and C.creaturePoolMode=='Random' then
        for _,entry in ipairs(pools.all) do
            if not (C.excludeExtraCliffRacers and isCliff(entry.id)) then candidates[#candidates+1]=entry.id end
        end
        table.sort(candidates)
        return #candidates>0 and candidates[rng(#candidates)] or actor.recordId
    end
    if extra and (rec.canFly or rec.canSwim or not rec.canWalk) then
        -- Flying/swimming actors may anchor a pack, but its members must be
        -- selected from the land-capable pool used by navmesh placement.
        for _,entry in ipairs(pools.beast) do
            if not entry.flies and not (C.excludeExtraCliffRacers and isCliff(entry.id)) then candidates[#candidates+1]=entry.id end
        end
        return #candidates>0 and candidates[rng(#candidates)] or 'rat'
    end
    if rec.canFly or rec.canSwim then
        if not (extra and C.excludeExtraCliffRacers and isCliff(actor.recordId)) then return actor.recordId end
        for _,entry in ipairs(pools.beast) do candidates[#candidates+1]=entry.id end
        return #candidates>0 and candidates[rng(#candidates)] or actor.recordId
    end
    local northern=(actor.recordId:find('^bm_') or actor.recordId:find('^t_sky_'))~=nil
    for _, entry in ipairs(pools[family(rec)]) do
        local regional=not entry.id:find('^bm_') and not entry.id:find('^t_sky_') or northern
        if regional and entry.level >= math.max(1,target-C.encounterLevelBelow)
            and entry.level <= target+C.encounterLevelAbove
            and not (extra and C.excludeExtraCliffRacers and isCliff(entry.id)) then candidates[#candidates+1]=entry.id end
    end
    return #candidates > 0 and candidates[rng(#candidates)] or actor.recordId
end
local function pickNpcReinforcement(actor,target,rng)
    buildPools()
    local text=(actor.cell.name..' '..actor.recordId..' '..(actor.type.record(actor).name or '')):lower()
    local wanted='beast'
    if not actor.cell.isExterior then
        if text:find('vampir',1,true) or text:find('necrom',1,true) or text:find('tomb',1,true)
            or text:find('crypt',1,true) or text:find('ancestral',1,true) then wanted='undead'
        elseif text:find('daedr',1,true) or text:find('shrine',1,true) or text:find('cult',1,true) then wanted='daedra'
        elseif text:find('dwemer',1,true) or text:find('dwarven',1,true) then wanted='construct' end
    end
    local families=C.creaturePoolMode=='Random' and {'all'} or {wanted}
    local candidates={}
    for _,familyName in ipairs(families) do
        for _,entry in ipairs(pools[familyName]) do
            if (C.creaturePoolMode=='Random' or (entry.level>=math.max(1,target-C.encounterLevelBelow)
                and entry.level<=target+C.encounterLevelAbove))
                and not (C.excludeExtraCliffRacers and isCliff(entry.id)) then
                candidates[#candidates+1]=entry.id
            end
        end
    end
    if #candidates==0 then
        for _,entry in ipairs(pools[wanted]) do
            if not (C.excludeExtraCliffRacers and isCliff(entry.id)) then candidates[#candidates+1]=entry.id end
        end
    end
    table.sort(candidates)
    return #candidates>0 and candidates[rng(#candidates)] or (actor.cell.isExterior and 'nix-hound' or 'skeleton')
end
local function pickDungeonCreature(cell,target,rng)
    buildPools()
    local source=pools.all
    if C.creaturePoolMode~='Random' then
        local text=(cell.name or ''):lower()
        local wanted='beast'
        if text:find('tomb',1,true) or text:find('crypt',1,true) or text:find('ancestral',1,true)
            or text:find('vampir',1,true) or text:find('necrom',1,true) then wanted='undead'
        elseif text:find('daedr',1,true) or text:find('shrine',1,true) then wanted='daedra'
        elseif text:find('dwemer',1,true) or text:find('dwarven',1,true) then wanted='construct' end
        source=pools[wanted]
    end
    local candidates={}
    for _,entry in ipairs(source) do
        if (C.creaturePoolMode=='Random' or (entry.level>=math.max(1,target-C.encounterLevelBelow)
            and entry.level<=target+C.encounterLevelAbove))
            and not (C.excludeExtraCliffRacers and isCliff(entry.id)) then candidates[#candidates+1]=entry.id end
    end
    if #candidates==0 then
        for _,entry in ipairs(pools.beast) do if not (C.excludeExtraCliffRacers and isCliff(entry.id)) then candidates[#candidates+1]=entry.id end end
    end
    table.sort(candidates)
    return #candidates>0 and candidates[rng(#candidates)] or 'rat'
end
local function pickFamilyCreature(familyName,target,rng)
    buildPools()
    local source=pools[familyName] or pools.all
    local candidates={}
    for _,entry in ipairs(source) do
        if entry.level>=math.max(1,target-C.encounterLevelBelow)
            and entry.level<=target+C.encounterLevelAbove
            and not (C.excludeExtraCliffRacers and isCliff(entry.id)) then candidates[#candidates+1]=entry.id end
    end
    if #candidates==0 then for _,entry in ipairs(source) do candidates[#candidates+1]=entry.id end end
    table.sort(candidates)
    return #candidates>0 and candidates[rng(#candidates)] or 'rat'
end
local function encounterTarget(native,playerLevel,jitter,isCreature,isGenerated)
    if not C.progression then return native end
    if not isCreature then return math.max(native,math.floor(1+(playerLevel-1)*C.levelScaling+jitter)) end
    local influence=math.min(1,C.levelScaling)
    local target=math.floor(native+(playerLevel-native)*influence+jitter+0.5)
    target=math.max(playerLevel-C.encounterLevelBelow,math.min(playerLevel+C.encounterLevelAbove,target))
    if isGenerated and C.creaturePoolMode=='Random' then target=playerLevel+jitter end
    return math.max(1,target)
end
local function buildGear()
    if gear then return end
    gear = {}
    for _, kind in ipairs({types.Weapon,types.Armor,types.Clothing}) do
        for _, rec in pairs(kind.records) do
            if (C.unsafeContent or (not rec.mwscript and not rec.enchant)) and rec.value > 0 and not rec.id:find('$',1,true) then
                local key = tostring(kind) .. ':' .. tostring(rec.type)
                gear[key] = gear[key] or {}
                gear[key][#gear[key]+1] = rec
            end
        end
    end
    for _, p in pairs(gear) do table.sort(p,function(a,b) return a.id < b.id end) end
end
function M.bind(s, giveLoot, encounter, isEligible)
    state, loot, promote, eligible = s, giveLoot, encounter, isEligible
    state.director = state.director or {actors={},cells={},generated={},cache={},supplies={},loose={},containers={},randomizedContainers={},npcLoot={},looseCells={},bossAdds={}}
    for _, key in ipairs({'actors','cells','generated','cache','supplies','loose','containers','randomizedContainers','npcLoot','looseCells','bossAdds'}) do
        state.director[key] = state.director[key] or {}
    end
    state.director.outdoor=state.director.outdoor or {pressure=0,bossProgress=0,nextRoll=0}
    state.director.outdoor.pressure=state.director.outdoor.pressure or 0
    state.director.outdoor.bossProgress=state.director.outdoor.bossProgress or 0
    state.director.outdoor.phase=state.director.outdoor.phase or 'build'
    state.director.outdoor.peakUntil=state.director.outdoor.peakUntil or 0
    state.director.outdoor.relaxUntil=state.director.outdoor.relaxUntil or 0
    state.director.outdoor.nextRoll=state.director.outdoor.nextRoll or 0
    state.director.outdoor.distance=state.director.outdoor.distance or 0
    state.director.outdoor.terrainRetries=state.director.outdoor.terrainRetries or 0
    -- A living outdoor World Boss owns the current climax. Its actor script
    -- continues to request reinforcement waves while the director remains
    -- paused until the boss's death event clears this id.
    state.director.outdoor.activeBossId=state.director.outdoor.activeBossId or false
    state.director.dens=state.director.dens or {}
    state.director.directorCosts=state.director.directorCosts or {}
    state.director.spawnLevels=state.director.spawnLevels or {}
    -- Lightweight, persisted combat telemetry. It is deliberately slow-moving
    -- so one unusually long fight cannot make the next encounter trivial.
    state.director.combat=state.director.combat or {kills=0,avgSeconds=0,killFactor=1}
    state.director.combat.kills=tonumber(state.director.combat.kills) or 0
    state.director.combat.avgSeconds=tonumber(state.director.combat.avgSeconds) or 0
    state.director.combat.killFactor=math.max(0.75,math.min(1.25,tonumber(state.director.combat.killFactor) or 1))
    for _,cellState in pairs(state.director.cells) do
        if cellState.additionalCount==nil then setAdditionalCount(cellState,cellState.count or 0) end
        cellState.count=nil
    end
    pending, pools, gear, itemPools, kindPools, lastPlayerCell, considered = {}, nil, nil, nil, nil, nil, {}
    for id,a in pairs(state.director.actors) do if a.pendingReplacement then state.director.actors[id]=nil end end
end

-- Record the observed time from a fighting preparation request to death. This
-- is intentionally a gentle correction signal, not a per-frame difficulty
-- controller: ordinary movement and one-off outliers should not thrash HP.
function M.recordKillTime(actor,elite)
    if not actor or not elite or not state or not state.director then return end
    local actorState=state.director.actors and state.director.actors[actor.id]
    local started=actorState and actorState.combatAt
    if not started then return end
    local elapsed=math.max(0,core.getSimulationTime()-started)
    local expected=elite.worldBoss and 45 or ({8,12,18})[elite.rank or 1] or 8
    local ratio=math.max(0.6,math.min(1.8,elapsed/math.max(4,expected)))
    local combat=state.director.combat
    combat.kills=(tonumber(combat.kills) or 0)+1
    combat.avgSeconds=(tonumber(combat.avgSeconds) or 0)==0 and elapsed
        or combat.avgSeconds*0.9+elapsed*0.1
    combat.killFactor=math.max(0.75,math.min(1.25,(tonumber(combat.killFactor) or 1)*0.9+ratio*0.1))
    actorState.combatAt=nil
    -- Re-evaluate the profile at the next promotion, not every frame.
    state.director.playerDamageProfileAt=0
end
local function exteriorTown(cell)
    if not C.settlementSuppression then return false end
    local civilians=0
    for _,other in ipairs(world.activeActors) do
        if other.cell==cell and types.NPC.objectIsInstance(other)
            and types.Actor.stats.ai.fight(other).base<80 then civilians=civilians+1 end
    end
    return civilians>=2
end
local function directorDensity()
    return 1.5*C.directorIntensity
end

local function enterOutdoorRelax(outdoor,now,intensity,seconds)
    outdoor.phase='relax'
    outdoor.relaxUntil=math.max(outdoor.relaxUntil or 0,now+(seconds or math.max(30,45/intensity)))
    outdoor.peakUntil=0
end
local function enterOutdoorPeak(outdoor,now,intensity)
    outdoor.phase='peak'
    outdoor.peakUntil=math.max(outdoor.peakUntil or 0,now+math.max(5,8/intensity))
    outdoor.relaxUntil=0
end
local function liveOutdoorDirectorGroup(cell,except)
    for _,other in ipairs(world.activeActors) do
        if other~=except and other.cell==cell and valid(other)
            and state.director.generated[other.id]=='director' then return true end
    end
    return false
end

-- Wilderness combat is feedback for the director. Ordinary kills and lower
-- promotions mean the player is engaging, so they build pressure instead of
-- granting a lull. Only major victories create meaningful breathing room.
local function applyOutdoorVictory(outdoor,elite,now,intensity)
    if not elite then
        outdoor.pressure=math.min(100,(outdoor.pressure or 0)+4*intensity)
        outdoor.bossProgress=math.min(100,(outdoor.bossProgress or 0)+1.5*intensity)
        return
    end
    if not elite.worldBoss then
        local rank=math.max(1,math.min(3,elite.rank or 1))
        outdoor.pressure=math.min(100,(outdoor.pressure or 0)+({5,7,9})[rank]*intensity)
        outdoor.bossProgress=math.min(100,(outdoor.bossProgress or 0)+({4,8,12})[rank]*intensity)
        local seconds=({3,8,15})[rank]
        outdoor.safeUntil=math.max(outdoor.safeUntil or 0,now+seconds)
        return
    end
    local seconds=elite.worldBoss and 180 or 25
    outdoor.safeUntil=math.max(outdoor.safeUntil or 0,now+seconds)
    outdoor.pressure=0
    if elite.worldBoss then
        outdoor.bossProgress=0
        outdoor.lastBossAt=now
        outdoor.phase='build';outdoor.peakUntil=0;outdoor.relaxUntil=0
    else
        outdoor.bossProgress=math.min(100,(outdoor.bossProgress or 0)+15*intensity)
    end
end
function M.victoryRespite(actor,elite)
    if not actor or not actor.cell or not actor.cell.isExterior then return end
    local outdoor=state.director.outdoor
    local now=core.getSimulationTime()
    outdoor.safeCell=actor.cell.id -- retained for old-save diagnostics
    if elite and elite.worldBoss and outdoor.activeBossId==actor.id then
        outdoor.activeBossId=false
    end
    applyOutdoorVictory(outdoor,elite,now,C.directorIntensity)
    -- Native kills continue to build pressure. A generated outdoor group gets
    -- one L4D-style relax window only after its last member dies; this avoids
    -- pausing the director after every rat while still giving a hard-fought
    -- encounter room to breathe.
    if state.director.generated[actor.id]=='director' and not liveOutdoorDirectorGroup(actor.cell,actor) then
        enterOutdoorRelax(outdoor,now,C.directorIntensity)
    end
end
-- A safe sleep is the deliberate recovery point for the outdoor director.
-- Ordinary waiting/resting, walking through a settlement, and short victory
-- lulls leave the pressure arc intact so the next wilderness leg still has a
-- destination. The player script sends this event after the native Rest UI
-- closes following a game-time advance in a cell that permits sleep.
function M.safeSleep(player)
    if player and not player:isValid() then return end
    local outdoor=state.director.outdoor
    local now=core.getSimulationTime()
    outdoor.pressure=0
    outdoor.bossProgress=0
    outdoor.phase='build'
    outdoor.peakUntil=0
    outdoor.relaxUntil=0
    outdoor.safeUntil=math.max(outdoor.safeUntil or 0,now+10)
    outdoor.nextRoll=now+10
    outdoor.distance=0
    outdoor.terrainRetries=0
    outdoor.lastSafeSleep=core.getGameTime()
    outdoor.safeCell=player and player.cell and player.cell.id or outdoor.safeCell
    print('[AshenLoot] safe sleep reset outdoor pressure')
end
function M.bossWave(actor)
    if not C.enabled or not C.extraEncounters or not valid(actor) then return end
    local elite=state.elites[actor.id]
    local player=world.players[1]
    if not elite or not elite.worldBoss or not player or player.cell~=actor.cell then return end
    local d=state.director
    local tracked=d.bossAdds[actor.id] or {}
    local live={}
    for _,id in ipairs(tracked) do
        for _,candidate in ipairs(world.activeActors) do
            if candidate.id==id and valid(candidate) then live[#live+1]=id;break end
        end
    end
    d.bossAdds[actor.id]=live
    local intensity=C.directorIntensity
    local cap=math.max(1,math.floor(6*intensity+0.5))
    if cap<=0 or #live>=cap then return end
    local rng=R.rng(actor.id..':boss-wave:'..math.floor(core.getSimulationTime()/math.max(5,30/intensity)))
    local low=math.max(1,math.floor(math.sqrt(intensity)+0.5))
    local high=math.max(low,math.floor(3*math.sqrt(intensity)+0.5))
    local count=math.min(cap-#live,low+rng(high-low+1)-1)
    local token=actor.id..':boss-wave:'..tostring(core.getSimulationTime())
    pending[token]={actor=actor,level=M.actorLevel(actor),count=count,cell=actor.cell.id,
        created=core.getSimulationTime(),bossWave=true}
    player:sendEvent('AshenLoot_FindSpawn',{token=token,actor=actor,count=count})
end
local inventoryKinds={types.Weapon,types.Armor,types.Clothing,types.Potion,types.Ingredient,
    types.Book,types.Lockpick,types.Probe,types.Apparatus}
if types.Miscellaneous then inventoryKinds[#inventoryKinds+1]=types.Miscellaneous end
local function poolKey(kind,rec)
    local subtype=(kind==types.Weapon or kind==types.Armor or kind==types.Clothing or kind==types.Apparatus) and rec.type or 0
    return tostring(kind)..':'..tostring(subtype)
end
local function safeInventoryRecord(kind,rec)
    if not rec or not rec.value or rec.value<=0 or not rec.id
        or rec.id:find('$',1,true) then return false end
    if C.unsafeContent then return true end
    if rec.mwscript then return false end
    local text=(rec.id..' '..(rec.name or '')):lower()
    for _,word in ipairs({'artifact','quest','unique'}) do
        if text:find(word,1,true) then return false end
    end
    if kind==types.Miscellaneous then
        if rec.isKey or text:find('azura',1,true) or text:find('propylon',1,true) then return false end
        -- Miscellaneous records contain keys, quest props and documents as well
        -- as treasure. Admit only recognizable, fungible valuables.
        for _,word in ipairs({'gem','diamond','emerald','ruby','sapphire','pearl','soulgem','coin','gold'}) do
            if text:find(word,1,true) then return true end
        end
        return false
    end
    return true
end
local function buildItemPools()
    if itemPools then return end
    itemPools,kindPools={},{}
    for _,kind in ipairs(inventoryKinds) do
        for _,rec in pairs(kind.records) do
            if safeInventoryRecord(kind,rec) then
                local key=poolKey(kind,rec)
                itemPools[key]=itemPools[key] or {}
                local equipment=kind==types.Weapon or kind==types.Armor or kind==types.Clothing
                local entry={id=rec.id,value=rec.value,kind=kind,
                    ordinary=not equipment or not rec.enchant,enchanted=equipment and not not rec.enchant}
                itemPools[key][#itemPools[key]+1]=entry
                local kindKey=tostring(kind)
                kindPools[kindKey]=kindPools[kindKey] or {}
                kindPools[kindKey][#kindPools[kindKey]+1]=entry
            end
        end
    end
    for _,pool in pairs(itemPools) do table.sort(pool,function(a,b) return a.id<b.id end) end
    for _,pool in pairs(kindPools) do table.sort(pool,function(a,b) return a.id<b.id end) end
end
local function randomBase(kind,rec,target,rng,ordinaryOnly)
    buildItemPools()
    local pool=itemPools[poolKey(kind,rec)] or {}
    local ceiling=math.max(rec.value*3,100+target*target*7)
    local floor=math.max(1,math.min(rec.value*0.25,target*target*0.08))
    local choices={}
    for _,entry in ipairs(pool) do
        if (not ordinaryOnly or entry.ordinary) and entry.value>=floor and entry.value<=ceiling then
            choices[#choices+1]=entry
        end
    end
    return #choices>0 and choices[rng(#choices)] or nil
end
local function randomBroadBase(target,rng)
    buildItemPools()
    local floor=math.max(5,target*target*0.12)
    local ceiling=math.max(250,250+target*target*10)
    local categories={}
    for _,kind in ipairs(inventoryKinds) do
        local choices={}
        for _,entry in ipairs(kindPools[tostring(kind)] or {}) do
            if entry.ordinary and entry.value>=floor and entry.value<=ceiling then choices[#choices+1]=entry end
        end
        if #choices>0 then categories[#categories+1]=choices end
    end
    if #categories==0 then return nil end
    local choices=categories[rng(#categories)]
    return choices[rng(#choices)]
end
local function randomNativeEnchanted(target,rng)
    buildItemPools()
    local floor=math.max(15,target*target*0.08)
    local ceiling=math.max(500,500+target*target*18)
    local categories={}
    for _,kind in ipairs({types.Weapon,types.Armor,types.Clothing}) do
        local choices={}
        for _,entry in ipairs(kindPools[tostring(kind)] or {}) do
            if entry.enchanted and entry.value>=floor and entry.value<=ceiling then choices[#choices+1]=entry end
        end
        if #choices>0 then categories[#categories+1]=choices end
    end
    if #categories==0 then return nil end
    local choices=categories[rng(#categories)]
    return choices[rng(#choices)]
end
local function randomSimilarEnchanted(kind,rec,target,rng)
    buildItemPools()
    local floor=math.max(15,target*target*0.08)
    local ceiling=math.max(500,500+target*target*18)
    local choices={}
    for _,entry in ipairs(itemPools[poolKey(kind,rec)] or {}) do
        if entry.enchanted and entry.value>=floor and entry.value<=ceiling then choices[#choices+1]=entry end
    end
    return #choices>0 and choices[rng(#choices)] or nil
end
local function randomContainerBase(kind,rec,target,rng,chest,lockLevel)
    -- Regular caches remain mostly believable. Chests and difficult locks move
    -- replacement rolls upward through valuable native and enchanted-native tiers.
    local enchantedChance=math.min(30,5+(chest and 5 or 0)+lockLevel*0.20)
    local valuableChance=math.min(45,25+(chest and 5 or 0)+lockLevel*0.125)
    local roll=rng(100)
    if roll<=enchantedChance then
        local found=randomNativeEnchanted(target,rng)
        if found then return found,'enchanted' end
    end
    if roll<=enchantedChance+valuableChance then
        local found=randomBroadBase(target,rng)
        if found then return found,'valuable' end
    end
    return randomBase(kind,rec,target,rng,true),'ordinary'
end
local function randomizeInventory(anchor,inventory,target,seed,skipEquipped,remixContext)
    local rng=R.rng(seed)
    local equipped={}
    if skipEquipped then for _,item in pairs(types.Actor.getEquipment(anchor)) do equipped[item.id]=true end end
    local originals={}
    for _,kind in ipairs(inventoryKinds) do
        for _,item in ipairs(inventory:getAll(kind)) do originals[#originals+1]={item=item,kind=kind,count=item.count} end
    end
    local changed=0
    for _,entry in ipairs(originals) do
        local item,kind=entry.item,entry.kind
        if item:isValid() and not equipped[item.id] then
            local rec=kind.record(item)
            if rec and (C.unsafeContent or not rec.mwscript) and rec.value and rec.value>0 then
                local replacement
                if remixContext and remixContext.container then
                    replacement=randomContainerBase(kind,rec,target,rng,
                        remixContext.chest,remixContext.lockLevel or 0)
                elseif remixContext and remixContext.npc and
                    (kind==types.Weapon or kind==types.Armor or kind==types.Clothing) then
                    local roll=rng(100)
                    if roll<=remixContext.ashenChance then
                        replacement=randomBase(kind,rec,target,rng,true)
                        if replacement then
                            local id=loot(anchor,seed..':'..item.id,remixContext.minimum or 1,
                                replacement.id,nil,nil,inventory)
                            if id then
                                if item:isValid() then item:remove();changed=changed+1 end
                            end
                            replacement=nil
                        end
                    elseif roll<=remixContext.ashenChance+remixContext.enchantedChance then
                        replacement=randomSimilarEnchanted(kind,rec,target,rng)
                            or randomBase(kind,rec,target,rng,true)
                    else replacement=randomBase(kind,rec,target,rng,true) end
                else replacement=randomBase(kind,rec,target,rng) end
                if replacement then
                    local made
                    if remixContext then
                        local equipment=replacement.kind==types.Weapon or replacement.kind==types.Armor
                            or replacement.kind==types.Clothing
                        world.createObject(replacement.id,equipment and 1 or entry.count):moveInto(inventory)
                        made=true
                    elseif kind==types.Weapon or kind==types.Armor or kind==types.Clothing then
                        made=loot(anchor,seed..':'..item.id,1,replacement.id,nil,nil,inventory)
                        if made and entry.count>1 then world.createObject(made,entry.count-1):moveInto(inventory) end
                    else
                        world.createObject(replacement.id,entry.count):moveInto(inventory); made=true
                    end
                    if made and item:isValid() then item:remove();changed=changed+1 end
                end
            end
        end
    end
    return changed
end
function M.actorLevel(actor)
    local a = state.director.actors[actor.id]
    return a and a.level or level()
end
function M.gearLevel()
    return gearLevel()
end
local function npcGearChances(profile)
    profile=profile or {}
    local rank=profile.rank or 0
    local base=C.npcAshenGearPercent
    local rankBonus=({[0]=0,5,12,20})[rank] or 20
    local ashen=base<=0 and 0 or math.min(50,base+
        (profile.worldBoss and 30 or (profile.guard and 10 or rankBonus)))
    local enchanted=profile.worldBoss and 30 or (profile.guard and 25 or 12+rank*5)
    return ashen,enchanted
end
function M.loadout(actor, target, minimum, profile)
    if not types.NPC.objectIsInstance(actor) or not C.npcProgression then return end
    buildGear()
    local rng = R.rng(actor.id .. ':loadout4')
    profile=profile or {}
    local ashenChance,enchantedChance=npcGearChances(profile)
    -- Each eligible piece rolls independently. Full generated suits remain
    -- possible anomalies rather than being prohibited, but are very unlikely.
    local remixContext={npc=true,ashenChance=ashenChance,enchantedChance=enchantedChance,
        minimum=minimum or 1}
    local equipment = types.Actor.getEquipment(actor)
    local inventory=types.Actor.inventory(actor)
    local replacements = {}
    -- Remix carried items before creating replacement equipment, so the new
    -- loadout cannot be processed a second time while its equip event is queued.
    if C.randomizeNpcInventories and not state.director.npcLoot[actor.id] then
        state.director.npcLoot[actor.id]=true
        if R.rng(actor.id..':inventory7')(100)<=C.npcInventoryPercent then
            randomizeInventory(actor,inventory,target,actor.id..':inventory7',true,remixContext)
        end
    end
    for slot, item in pairs(equipment) do
        if #replacements >= 3 then break end
        local rec, kind = item.type.record(item), item.type
        if (kind == types.Weapon or kind == types.Armor or kind == types.Clothing) and not rec.mwscript and not rec.enchant then
            local candidates = {}
            local ceiling = 100 + target * target * 7
            for _, candidate in ipairs(gear[tostring(kind)..':'..tostring(rec.type)] or {}) do
                if candidate.id~=rec.id and candidate.value <= ceiling
                    and candidate.value >= math.max(math.min(rec.value,ceiling)*0.6,math.min(1500,target*target*0.15)) then
                    candidates[#candidates+1]=candidate
                end
            end
            if #candidates > 0 then
                local base = candidates[rng(#candidates)]
                local roll=rng(100)
                local id
                if roll<=ashenChance then
                    id=loot(actor,actor.id..':slot7:'..slot,minimum or 1,base.id)
                elseif roll<=ashenChance+enchantedChance then
                    local enchanted=randomSimilarEnchanted(kind,rec,target,rng)
                    if enchanted then base=enchanted end
                end
                if not id and base.id~=rec.id then
                    world.createObject(base.id,1):moveInto(inventory);id=base.id
                end
                if id then
                    replacements[#replacements+1]={slot=slot,old=item,id=id}
                end
            end
        end
    end
    actor:sendEvent('AshenLoot_Equip',replacements)
    for _,entry in ipairs(replacements) do
        if entry.old and entry.old:isValid() then entry.old:remove() end
    end
    local magic = types.Actor.stats.dynamic.magicka(actor).base
    if magic >= 30 then
        local school = types.NPC.stats.skills.destruction(actor).base
        if school >= 20 then
            local p = math.max(1,math.min(10,math.ceil(target/5)))
            local element = ({'firedamage','frostdamage','shockdamage'})[rng(3)]
            local key = 'caster:'..element..':'..p
            local id = state.director.cache[key]
            if not id then
                id = world.createRecord(core.magic.spells.createRecordDraft {
                    name='Dreamforged '..element..' '..p,type=core.magic.SPELL_TYPE.Spell,
                    cost=math.min(20,3+p),isAutocalc=false,
                    effects={Records.effect(element,3+p,core.magic.RANGE.Target,2)},
                }).id
                state.director.cache[key]=id
            end
            types.Actor.spells(actor):add(id)
        end
    end
end
function M.prepare(actor, inCombat)
    if not C.enabled or not eligible(actor) or not valid(actor) then return end
    local d = state.director
    -- 0.7.4 stored generated actors as boolean true. Reconsider active exterior
    -- members once so an existing save can finish an unspent cell budget.
    local legacyExterior=d.generated[actor.id]==true and actor.cell.isExterior
    if d.actors[actor.id] and not legacyExterior then
        if inCombat and not d.actors[actor.id].combatAt then
            d.actors[actor.id].combatAt=core.getSimulationTime()
        end
        return
    end
    if legacyExterior then d.generated[actor.id]=1;d.actors[actor.id]=nil end
    local rng = R.rng(actor.id..':progression4')
    local native = math.max(1,types.Actor.stats.level(actor).current)
    local guard=C.guardProgression and isGuard(actor)
    local playerLevel=level()
    local effectiveLevel=gearLevel()
    local combatProfile=playerDamageProfile()
    -- Native artifacts and exceptional weapons may not be present in the
    -- generated-item score table. Let the broad damage score lift the target
    -- band in that case, without bypassing the normal level window.
    effectiveLevel=math.max(effectiveLevel,combatProfile.score or effectiveLevel)
    local generated = d.generated[actor.id]
    local target=encounterTarget(native,effectiveLevel,rng(5)-3,types.Creature.objectIsInstance(actor),generated~=nil)
    if d.spawnLevels[actor.id] then target=math.max(1,math.floor(d.spawnLevels[actor.id]+0.5)) end
    if guard then target=math.max(target,math.floor(effectiveLevel*0.8)+4) end
    target = math.max(1,target)
    local cell = actor.cell
    d.actors[actor.id]={level=target,cell=actor.cell.id,
        combatAt=inCombat and core.getSimulationTime() or nil,
        -- Outdoor director actors retain the pressure at the moment they are
        -- prepared.  The promotion ladder can then favor ordinary members at
        -- low pressure and reserve higher tiers for a rising encounter arc.
        directorPressure=(cell and cell.isExterior and generated=='director')
            and math.max(0,math.min(100,tonumber(d.outdoor.pressure) or 0)) or nil}
    local ck = cellKey(cell)
    d.cells[ck]=d.cells[ck] or {additionalCount=0,boss=false}
    local cellState=d.cells[ck]
    if cell.isExterior then cellState.isExterior=true end
    local boss = C.dungeonBosses and dungeon(cell) and isAggressive(actor) and not cellState.boss
    if boss then cellState.boss=actor.id end
    local town=cell.isExterior and exteriorTown(cell) or false
    -- World Boss is the highest promotion result, not a separate per-cell roll.
    -- Only actors that actually promote receive this conditional chance.
    local allowWorldBoss=C.worldBosses and not guard and not town and isAggressive(actor)
        and playerLevel>=C.worldBossMinLevel and activeWorldBosses(cell)<C.worldBossCellCap
    local outdoorBossChance=3
    local forceOutdoorBoss=false
    if allowWorldBoss and cell.isExterior and generated=='director' then
        local progress=math.max(0,math.min(100,d.outdoor.bossProgress or 0))
        outdoorBossChance=math.min(40,3+math.max(0,progress-60)*0.5)
        forceOutdoorBoss=progress>=100
    end
    -- Replace only before combat, never change a fighting actor underneath the player.
    if not generated and not inCombat and not town and C.progression and types.Creature.objectIsInstance(actor)
        and rng(100) <= C.creatureVariety and (actor.position-world.players[1].position):length() > 900 then
        local id=pickCreature(actor,target,rng)
        if id ~= actor.recordId then
            local token=actor.id..':replacement'
            pending[token]={actor=actor,replacement=id,created=core.getSimulationTime()}
            d.actors[actor.id].pendingReplacement=true
            world.players[1]:sendEvent('AshenLoot_CheckReplacement',{actor=actor,token=token})
            return
        end
    end
    local combatDps=combatProfile.dps
    local combatBand=combatProfile.band
    local prestige=prestigeScale(effectiveLevel)
    actor:sendEvent('AshenLoot_Scale',{level=target,nativeLevel=native,health=C.enemyHealth*prestige*(guard and C.guardPower or 1),
        damage=C.enemyDamage*prestige*(guard and C.guardPower or 1),progression=C.progression,
        allowDownscale=types.Creature.objectIsInstance(actor)})
    if guard then M.loadout(actor,target+6,2,{guard=true});return end
    if boss or cellState.boss==actor.id then
        promote({actor=actor,force=true,rank=2,allowWorldBoss=allowWorldBoss,
            worldBossChance=outdoorBossChance,combatDps=combatDps,combatBand=combatBand})
    else promote({actor=actor,force=forceOutdoorBoss,worldBoss=forceOutdoorBoss,
        allowWorldBoss=allowWorldBoss,worldBossChance=outdoorBossChance,combatDps=combatDps,
        combatBand=combatBand}) end
    local elite=state.elites[actor.id]
    if elite and elite.worldBoss and cell.isExterior then
        -- Promotion is the moment the World Boss becomes real. Empty the
        -- outdoor pressure arc immediately and let the boss's own add waves
        -- carry the encounter until its death event releases the lock.
        d.outdoor.bossProgress=0
        d.outdoor.pressure=0
        d.outdoor.activeBossId=actor.id
        d.outdoor.phase='build';d.outdoor.peakUntil=0;d.outdoor.relaxUntil=0
        d.outdoor.safeUntil=0
        d.outdoor.lastBossAt=core.getSimulationTime()
    end
    if elite and elite.worldBoss and not d.actors[actor.id].bossScaleFactor then
        d.actors[actor.id].bossOriginalScale=actor.scale
        local scale,factor=worldBossScale(actor)
        actor:setScale(scale)
        d.actors[actor.id].bossScaleFactor=factor
    end
    M.loadout(actor,target,elite and math.min(3,elite.rank or 1) or 1,
        {rank=elite and elite.rank or 0,worldBoss=elite and elite.worldBoss})
    if cellState.boss==actor.id then M.supplement(cell,target) end
    M.containerLoot(cell,actor,target)
    local baseBudget=cell.isExterior and 6 or (dungeon(cell) and C.interiorBudget or 0)
    local maxCount=math.floor(baseBudget*directorDensity()+0.5)
    if town then maxCount=0 end
    -- A replacement may stand in for its native anchor, but an additional
    -- generated actor never chains into another group.
    local canAnchorPack=not generated or generated=='replacement'
    -- Unsafe identity eligibility must never create extra population anchors.
    -- It permits promotions/transforms; ordinary encounter records still own
    -- the cell's strictly budgeted reinforcement generation.
    if not cell.isExterior and C.extraEncounters and populationAnchor(actor) and canAnchorPack
        and additionalCount(cellState) < maxCount then
        local group=math.max(1,math.floor(directorDensity()+0.5))
        if elite and elite.rank==3 then group=group+(elite.worldBoss and 2 or 1) end
        local count=math.min(maxCount-additionalCount(cellState),group)
        setAdditionalCount(cellState,additionalCount(cellState)+count)
        local token=actor.id..':pack'
        pending[token]={actor=actor,level=target,count=count,cell=ck,created=core.getSimulationTime()}
        world.players[1]:sendEvent('AshenLoot_FindSpawn',{token=token,actor=actor,count=count})
    end
end
function M.replaceResult(event)
    local request=pending[event.token]
    if not request or not request.replacement then return end
    pending[event.token]=nil
    local actor=request.actor
    if not valid(actor) then return end
    local d=state.director
    if C.enabled and event.clear and (actor.position-world.players[1].position):length()>900 then
        local replacement=world.createObject(request.replacement,1)
        d.generated[replacement.id]='replacement'
        replacement:teleport(actor.cell,actor.position,{rotation=actor.rotation})
        replacement:sendEvent('AshenLoot_Spawned')
        actor.enabled=false
        local cellState=d.cells[actor.cell.id]
        if cellState.boss==actor.id then cellState.boss=replacement.id end
        d.actors[actor.id].pendingReplacement=nil
        d.actors[actor.id].replacement=replacement
    else
        d.actors[actor.id]=nil
        M.prepare(actor,true)
    end
end
local denThemes={
    beast={name='Brood Nest',effect='burden'},
    undead={name='Grave Brood',effect='drainhealth'},
    daedra={name='Profane Hatchery',effect='weaknesstomagicka'},
    construct={name='Dwemer Incubator',effect='shockdamage'},
}
local function denRecord(familyName,tier)
    local key='den-record:'..familyName..':'..tier
    local cached=state.director.cache[key]
    if cached and types.Creature.records[cached] then return cached end
    local queen=types.Creature.records['kwama queen']
    if not queen then
        for _,rec in pairs(types.Creature.records) do
            if (rec.model or ''):lower():find('kwama queen',1,true) then queen=rec;break end
        end
    end
    if not queen then return nil end
    local adjective=({'Lesser ',' ','Greater '})[tier] or ''
    local record=world.createRecord(types.Creature.createRecordDraft{
        template=queen,name=adjective..(denThemes[familyName] or denThemes.beast).name,
        isEssential=false,isRespawning=false,canWalk=false,canSwim=false,canFly=false,
        attack={0,1,0,1,0,1},combatSkill=5,magicSkill=5,stealthSkill=5,soulValue=0,baseGold=0,
    })
    state.director.cache[key]=record.id
    return record.id
end
local function createDen(request,pos)
    local id=denRecord(request.family,request.tier)
    if not id then return nil end
    local den=world.createObject(id,1)
    den:teleport(request.actor.cell,pos)
    local native=math.max(1,types.Actor.stats.level(den).current)
    local health=({1.1,1.8,2.7})[request.tier] or 1.1
    state.director.generated[den.id]='den'
    state.director.directorCosts[den.id]=request.cost or 2
    state.director.actors[den.id]={level=request.level,cell=request.cell,den=true}
    local now=core.getSimulationTime()
    state.director.dens[den.id]={family=request.family,tier=request.tier,cycles=math.max(1,tonumber(request.cycles) or 1),
        -- The first wave is deliberately prompt.  Later cycles use the
        -- configured interval, but a newly discovered den should visibly do
        -- its job before the player has forgotten it exists.
        nextWave=now+math.max(1,math.min(5,tonumber(C.creatureDenWaveInterval) or 5)),
        cell=request.cell,level=request.level,dead=false,
        vfxId='dreamforged_den:'..den.id}
    den:sendEvent('AshenLoot_Scale',{level=request.level,nativeLevel=native,health=health,
        damage=0.25,progression=true,allowDownscale=true})
    local effect=core.magic.effects.records[(denThemes[request.family] or denThemes.beast).effect]
    local static=effect and effect.castStatic and types.Static.record(effect.castStatic)
    den:sendEvent('AshenLoot_DenSpawned',{model=static and static.model,particle=effect and effect.particle,
        vfxId='dreamforged_den:'..den.id})
    return den
end
function M.spawnResult(event)
    local request=pending[event.token]
    if not request then return end
    pending[event.token]=nil
    local actor=request.actor
    local cellState=state.director.cells[request.cell]
    local function refund(amount)
        if request.bossWave or request.director then return end
        if cellState then setAdditionalCount(cellState,additionalCount(cellState)-(amount or request.count)) end
    end
    if not C.enabled or not C.extraEncounters or not valid(actor) or actor.cell.id~=request.cell then refund();return end
    local rng=R.rng(event.token)
    local made=0
    for _,pos in ipairs(event.positions or {}) do
        if made>=request.count then break end
        local offset=pos-actor.position
        if actor.cell.isExterior or offset:length()<900 then
            if request.den then
                if createDen(request,pos) then made=made+1 end
                break
            end
            local id=request.denWave and pickFamilyCreature(request.family,request.level,rng)
                or (request.director and pickDungeonCreature(actor.cell,request.level,rng))
                or (types.Creature.objectIsInstance(actor) and pickCreature(actor,request.level,rng,true) or actor.recordId)
            -- NPC copies are forbidden: use varied level-aware creature allies instead.
            if types.NPC.objectIsInstance(actor) then id=pickNpcReinforcement(actor,request.level,rng) end
            local spawn=world.createObject(id,1)
            local parentGeneration=type(state.director.generated[actor.id])=='number'
                and state.director.generated[actor.id] or 0
            state.director.generated[spawn.id]=request.bossWave and 'bossAdd'
                or (request.director and 'director' or (parentGeneration+1))
            if request.director then
                state.director.directorCosts[spawn.id]=request.cost or 1
                state.director.spawnLevels[spawn.id]=request.level
            end
            if request.bossWave then
                local adds=state.director.bossAdds[actor.id] or {}
                adds[#adds+1]=spawn.id;state.director.bossAdds[actor.id]=adds
            end
            spawn:teleport(actor.cell,pos)
            spawn:sendEvent('AshenLoot_Spawned')
            made=made+1
        end
    end
    local missing=math.max(0,request.count-made)
    if request.director and missing>0 then
        local now=core.getSimulationTime()
        local player=world.players[1]
        -- A bad terrain/navmesh sample is not a reason to spend pressure. Give
        -- the placement sampler one bounded retry after a short delay. This
        -- keeps a single awkward hillside from silently deleting a director
        -- group, without creating a tight retry loop every frame.
        -- Retry a bad navmesh/terrain sample twice (three placement passes in
        -- total).  The retry is bounded and delayed, so a cliff or bad cell
        -- cannot turn into a tight per-frame spawn loop.
        if (request.terrainRetries or 0)<2 and player and player:isValid()
            and actor and actor:isValid() and actor.cell and actor.cell.id==request.cell then
            local retry={}
            for key,value in pairs(request) do retry[key]=value end
            retry.count=missing
            retry.created=now
            retry.terrainRetries=(request.terrainRetries or 0)+1
            local token=(actor and actor.id or request.cell)..':director-retry:'..tostring(now)..':'..tostring(retry.terrainRetries)
            pending[token]=retry
            local eventData={token=token,actor=actor,count=missing,director=true,
                den=retry.den,denWave=retry.denWave,dirX=retry.dirX,dirY=retry.dirY}
            player:sendEvent('AshenLoot_FindSpawn',eventData)
            local interval=math.max(5,tonumber(C.outdoorDirectorInterval) or 5)
            state.director.outdoor.nextRoll=now+math.min(5,interval)
            state.director.outdoor.distance=150
            print('[AshenLoot] director placement retry '..missing..' in '..request.cell)
        else
            -- Persistent placement failure contributes a small amount of
            -- appetite so the next five-second batch is not suppressed forever.
            local outdoor=state.director.outdoor
            outdoor.pressure=math.min(100,(outdoor.pressure or 0)+5*C.directorIntensity)
            outdoor.nextRoll=now+math.max(5,tonumber(C.outdoorDirectorInterval) or 5)
            outdoor.distance=0
            print('[AshenLoot] director placement failed '..missing..' in '..request.cell)
        end
    end
    if missing==0 or not request.director or (request.terrainRetries or 0)>=1 then
        if request.director and made>0 then
            enterOutdoorPeak(state.director.outdoor,core.getSimulationTime(),C.directorIntensity)
        end
    end
    refund(missing)
    print('[AshenLoot] encounter placement '..made..'/'..request.count..' in '..request.cell)
end
local scrollRecipes={
    {name='Embers',effect='firedamage',secondary='weaknesstofire'},
    {name='Rime',effect='frostdamage',secondary='weaknesstofrost'},
    {name='Storms',effect='shockdamage',secondary='weaknesstoshock'},
    {name='Sundering',effect='damagehealth',secondary='burden'},
    {name='Binding',effect='burden',secondary='demoralizehumanoid'},
    {name='Warding',effect='shield',secondary='resistmagicka',self=true},
}
local ammunitionPools
local function buildAmmunitionPools()
    if ammunitionPools then return end
    ammunitionPools={arrow={},bolt={}}
    for _,rec in pairs(types.Weapon.records) do
        local pool=rec.type==types.Weapon.TYPE.Arrow and ammunitionPools.arrow
            or (rec.type==types.Weapon.TYPE.Bolt and ammunitionPools.bolt or nil)
        if pool and safeInventoryRecord(types.Weapon,rec) and not rec.enchant then
            pool[#pool+1]={id=rec.id,power=math.max(rec.chopMaxDamage or 0,rec.slashMaxDamage or 0,
                rec.thrustMaxDamage or 0)+(rec.value or 0)*0.02}
        end
    end
    for _,pool in pairs(ammunitionPools) do
        table.sort(pool,function(a,b) return a.power==b.power and a.id<b.id or a.power<b.power end)
    end
end
local function rangedPreference(player)
    if not player or not types.NPC.objectIsInstance(player) then return nil,0,false end
    local marksman=types.NPC.stats.skills.marksman(player).base
    local function weaponMode(item)
        if not item or not types.Weapon.objectIsInstance(item) then return end
        local rec=item and types.Weapon.record(item)
        if not rec then return end
        if rec.type==types.Weapon.TYPE.MarksmanBow then return 'arrow' end
        if rec.type==types.Weapon.TYPE.MarksmanCrossbow then return 'bolt' end
    end
    for _,item in pairs(types.Actor.getEquipment(player)) do
        local mode=weaponMode(item);if mode then return mode,marksman,true end
    end
    for _,item in ipairs(types.Actor.inventory(player):getAll(types.Weapon)) do
        local mode=weaponMode(item);if mode then return mode,marksman,true end
    end
    return nil,marksman,false
end
local function ammunitionDrop(player,target,rng)
    buildAmmunitionPools()
    local mode,marksman,hasLauncher=rangedPreference(player)
    if not mode then mode=rng(2)==1 and 'arrow' or 'bolt' end
    local pool=ammunitionPools[mode]
    if #pool==0 then return end
    -- Mostly follows character power, but the random spread preserves an
    -- occasional exciting high-material bundle at low levels.
    local effective=math.max(1,target+rng(21)-11)
    local percentile=math.max(0,math.min(1,effective/80))
    local index=math.max(1,math.min(#pool,1+math.floor((#pool-1)*percentile)))
    local count=8+rng(8)+math.floor(math.min(100,marksman)/10)
    return pool[index].id,count,marksman,hasLauncher
end
local function supplyRecord(target, kind, rare, variant)
    local band=math.max(1,math.min(20,math.ceil(target/5)))
    variant=kind=='scroll' and math.max(1,math.min(#scrollRecipes,tonumber(variant) or 1)) or 0
    local key='v9:'..kind..':'..band..':'..tostring(rare)..':'..variant
    if state.director.supplies[key] then return state.director.supplies[key] end
    local effects, name = {}, ''
    if kind=='scroll' then
        local base
        for _,r in pairs(types.Book.records) do if r.isScroll and not r.mwscript then base=r;break end end
        if not base then return end
        local recipe=scrollRecipes[variant]
        local range=recipe.self and core.magic.RANGE.Self or core.magic.RANGE.Target
        effects={Records.effect(recipe.effect,5+band*2,range,recipe.self and 8 or 3)}
        if rare then effects[#effects+1]=Records.effect(recipe.secondary,4+band,range,recipe.self and 8 or 3) end
        local enchant=world.createRecord(core.magic.enchantments.createRecordDraft {
            type=core.magic.ENCHANTMENT_TYPE.CastOnce,cost=0,charge=0,isAutocalc=false,effects=effects})
        name='Dreamforged Scroll of '..(rare and 'Greater ' or '')..recipe.name..' '..band
        local id=world.createRecord(types.Book.createRecordDraft {template=base,name=name,enchant=enchant.id,
            text=name,skill='',value=15+band*5}).id
        state.director.supplies[key]=id
        return id
    end
    local displayTier=math.max(1,math.min(5,math.ceil(band/4)))
    local names={
        health={'Minor Healing Potion','Healing Potion','Major Healing Potion','Greater Healing Potion','Super Healing Potion'},
        magicka={'Minor Mana Potion','Mana Potion','Major Mana Potion','Greater Mana Potion','Super Mana Potion'},
        fatigue={'Minor Stamina Potion','Stamina Potion','Major Stamina Potion','Greater Stamina Potion','Super Stamina Potion'},
    }
    -- Native potion art is quality-coded rather than effect-coded. These three
    -- give recovery supplies a stable red/blue/green visual language.
    local visual={health='p_restore_health_e',magicka='p_restore_health_q',fatigue='p_restore_health_b'}
    local base=types.Potion.record(visual[kind]) or types.Potion.record('p_restore_health_b')
    local effect=kind=='health' and 'restorehealth' or (kind=='magicka' and 'restoremagicka' or 'restorefatigue')
    effects={Records.effect(effect,4+band*2,core.magic.RANGE.Self,5)}
    if rare then effects[#effects+1]=Records.effect(kind=='fatigue' and 'restorehealth' or 'restorefatigue',2+band,core.magic.RANGE.Self,5) end
    name=(rare and 'Replenishing ' or '')..names[kind][displayTier]
    local id=world.createRecord(types.Potion.createRecordDraft {template=base,name=name,effects=effects,
        isAutocalc=false,value=8+band*3,weight=0.25}).id
    state.director.supplies[key]=id
    return id
end
local looseKinds={types.Weapon,types.Armor,types.Clothing,types.Potion,types.Ingredient,
    types.Lockpick,types.Probe,types.Apparatus}
if types.Miscellaneous then looseKinds[#looseKinds+1]=types.Miscellaneous end
local function looseDungeon(cell)
    if not cell or cell.isExterior then return false end
    local name=(cell.name or ''):lower()
    for _,word in ipairs({'tomb','crypt','ancestral','shrine','daedric','dwemer'}) do
        if name:find(word,1,true) then return true end
    end
    -- Dwemer and Daedric interiors often have proper names. Their architecture
    -- is a safer signal than treating every generic hostile interior as eligible.
    if types.Static then
        local checked=0
        for _,object in ipairs(cell:getAll(types.Static)) do
            local rec=types.Static.record(object)
            local text=rec and ((rec.id or '')..' '..(rec.model or '')):lower() or ''
            if text:find('dwrv',1,true) or text:find('dwemer',1,true)
                or text:find('in_dae',1,true) or text:find('daedric',1,true) then return true end
            checked=checked+1;if checked>=200 then break end
        end
    end
    return false
end
local function randomLooseBase(kind,rec,target,rng)
    local equipment=kind==types.Weapon or kind==types.Armor or kind==types.Clothing
    local roll=rng(100)
    if equipment and roll<=5 then
        return randomBase(kind,rec,target,rng,true),'ashen'
    elseif roll<=15 then
        local found=equipment and randomSimilarEnchanted(kind,rec,target,rng) or randomNativeEnchanted(target,rng)
        if found then return found,'enchanted' end
    end
    if roll<=45 then
        local found=randomBroadBase(target,rng)
        if found then return found,'valuable' end
    end
    return randomBase(kind,rec,target,rng,true),'ordinary'
end
function M.looseLoot(cell,anchor,target)
    if not C.randomizeLooseDungeonItems or not looseDungeon(cell)
        or state.director.looseCells[cell.id] then return end
    state.director.looseCells[cell.id]=true
    local eligibleCount,selected,replaced,ashen=0,0,0,0
    for _,kind in ipairs(looseKinds) do
        for _,item in ipairs(cell:getAll(kind)) do
            local rec=kind.record(item)
            local equipment=kind==types.Weapon or kind==types.Armor or kind==types.Clothing
            if item:isValid() and item.enabled and not item.parentContainer and item.contentFile
                and not item.owner.recordId and not item.owner.factionId and safeInventoryRecord(kind,rec)
                and (C.unsafeContent or not (equipment and rec.enchant))
                and (C.unsafeContent or rec.value<=math.max(500,500+target*target*10)) then
                eligibleCount=eligibleCount+1
                local rng=R.rng(item.id..':loose8')
                if rng(100)<=C.looseDungeonItemPercent then
                    selected=selected+1
                    local replacement,tier=randomLooseBase(kind,rec,target,rng)
                    if replacement then
                        local position,rotation,scale,count=item.position,item.rotation,item.scale,item.count
                        local made
                        if tier=='ashen' then
                            made=loot(anchor,item.id..':loose-gear8',1,replacement.id,nil,nil,
                                {worldCell=cell,position=position,rotation=rotation,scale=scale})
                            if made then ashen=ashen+1 end
                        else
                            local object=world.createObject(replacement.id,count)
                            object:teleport(cell,position,rotation)
                            if scale~=1 then object:setScale(scale) end
                            made=true
                        end
                        if made and item:isValid() then item:remove();replaced=replaced+1 end
                    end
                end
            end
        end
    end
    print('[AshenLoot] loose cache '..cell.id..': '..selected..'/'..eligibleCount
        ..' selected, '..replaced..' replaced, '..ashen..' Ashen')
end
function M.supplies(actor)
    local rng=R.rng(actor.id..':supplies4')
    local target=M.actorLevel(actor)
    local function give(kind)
        local id=supplyRecord(target,kind,rng(100)<20,kind=='scroll' and rng(#scrollRecipes) or nil)
        if id then world.createObject(id,1):moveInto(types.Actor.inventory(actor)) end
    end
    -- Denser cells should yield more total supplies, but not in direct proportion
    -- to every extra body. Square-root normalization keeps exploration sustainable.
    local density=math.sqrt(math.max(1,directorDensity()))
    if rng(100)<=C.healingPercent/density then give('health') end
    if rng(100)<=C.supplyPercent/density then
        local player=world.players[1]
        local magicFocused=false
        if player and types.NPC.objectIsInstance(player) then
            local rec=types.NPC.record(player)
            local class=((rec and rec.class) or ''):lower()
            local classRecord=types.NPC.classes and types.NPC.classes.records and types.NPC.classes.records[rec.class]
            magicFocused=class:find('warmage',1,true) or class:find('conjurer',1,true)
                or (classRecord and tostring(classRecord.specialization):lower()=='magic')
        end
        if magicFocused then
            local roll=rng(100);give(roll<=45 and 'scroll' or (roll<=85 and 'magicka' or 'fatigue'))
        else give(({'fatigue','magicka','scroll'})[rng(3)]) end
    end
    local player=world.players[1]
    local _,marksman,hasLauncher=rangedPreference(player)
    local ammunitionChance=math.min(95,C.ammunitionPercent+math.min(50,marksman*0.5)+(hasLauncher and 25 or 0))
    if rng(100)<=ammunitionChance/density then
        local id,count=ammunitionDrop(player,target,rng)
        if id then world.createObject(id,count):moveInto(types.Actor.inventory(actor)) end
    end
end
function M.supplement(cell,target)
    if not C.supplyContainers then return end
    local added=0
    for _,container in ipairs(cell:getAll(types.Container)) do
        if added>=2 then break end
        local rec=container.type.record(container)
        if not state.director.containers[container.id] and not rec.mwscript
            and not container.owner.recordId and not container.owner.factionId then
            local id=supplyRecord(target,'health',false)
            world.createObject(id,1):moveInto(types.Container.content(container))
            state.director.containers[container.id]=true
            added=added+1
        end
    end
end
function M.containerLoot(cell,anchor,target)
    if not C.randomizeContainers or not dungeon(cell) then return end
    local eligible,selected,replaced,prizes=0,0,0,0
    for _,container in ipairs(cell:getAll(types.Container)) do
        local rec=container.type.record(container)
        if state.director.randomizedContainers[container.id]==nil and not rec.mwscript
            and not container.owner.recordId and not container.owner.factionId then
            eligible=eligible+1
            local text=((rec.id or '')..' '..(rec.name or '')..' '..(rec.model or '')):lower()
            local chest=text:find('chest',1,true) or text:find('coffer',1,true)
                or text:find('strongbox',1,true) or text:find('trunk',1,true)
            local lockLevel=math.max(0,types.Lockable.getLockLevel(container) or 0)
            local chance=math.min(100,C.containerLootPercent+(chest and 20 or 0)+math.min(40,lockLevel*0.5))
            local rng=R.rng(container.id..':container5')
            state.director.randomizedContainers[container.id]=rng(100)<=chance
            if state.director.randomizedContainers[container.id] then
                selected=selected+1
                local inventory=types.Container.content(container)
                replaced=replaced+randomizeInventory(anchor,inventory,target,container.id..':container7',false,
                    {container=true,chest=not not chest,lockLevel=lockLevel})
                -- Every selected container rolls independently, so a lucky
                -- dungeon can exceed the average rather than hitting a hard cap.
                local prizeChance=math.min(90,25+(chest and 25 or 0)+math.min(40,lockLevel*0.5))
                local prizeRng=R.rng(container.id..':cache-prize7')
                if prizeRng(100)<=prizeChance then
                    local minimum=1
                    local rareChance=math.min(90,(chest and 15 or 0)+lockLevel)
                    if prizeRng(100)<=rareChance then minimum=2 end
                    if lockLevel>=50 and prizeRng(100)<=math.min(35,(lockLevel-40)*0.75) then minimum=3 end
                    if loot(anchor,container.id..':cache-gear7',minimum,nil,nil,nil,inventory) then prizes=prizes+1 end
                end
            end
        end
    end
    if eligible>0 then
        print('[AshenLoot] container cache '..cell.id..': '..selected..'/'..eligible
            ..' selected, '..replaced..' contents remixed, '..prizes..' prizes added')
    end
end
local function glowRecord(tier)
    local key='glow3:'..tier
    if state.director.cache[key] then return state.director.cache[key] end
    -- Use the same canonical palette rendered by the salvage and target-card
    -- UIs. Keeping a second hand-tuned table here caused ground lights to
    -- drift visibly from their rarity text (especially Rare/Epic/Legendary).
    tier=math.max(1,math.min(#R.rarities,math.floor(tonumber(tier) or 1)))
    local c=R.rarities[tier].color
    -- A model-less native light keeps the rarity glow without inheriting visible
    -- torch geometry. Empty model paths are rejected by OpenMW record creation.
    local template=types.Light.record('yellow light')
    if not template then return end
    local id=world.createRecord(types.Light.createRecordDraft {template=template,name='Dreamforged loot glow',
        weight=0,value=0,duration=0,radius=180,color=util.color.rgb(c[1],c[2],c[3]),isCarriable=false,
        isDynamic=true,isFire=false,isFlicker=false,isFlickerSlow=false,isNegative=false,isOffByDefault=false,
        isPulse=true,isPulseSlow=false}).id
    state.director.cache[key]=id
    return id
end
function M.ground(item, actor, dropIndex)
    if not C.groundDrops or not types.Actor.isDead(actor) then return end
    local player=world.players[1]
    local direction=player and (player.position-actor.position) or util.vector3(1,0,0)
    direction=util.vector3(direction.x,direction.y,0)
    local length=direction:length()
    if length<1 then direction=util.vector3(1,0,0) else direction=direction/length end
    dropIndex=math.max(1,math.floor(dropIndex or 1))
    local step=math.ceil((dropIndex-1)/2)
    local sign=dropIndex%2==0 and 1 or -1
    local angle=dropIndex==1 and 0 or sign*math.min(math.rad(54),step*math.rad(18))
    local spreadDirection=util.vector3(direction.x*math.cos(angle)-direction.y*math.sin(angle),
        direction.x*math.sin(angle)+direction.y*math.cos(angle),0)
    local distance=math.max(120,math.min(420,100+actor.scale*55+((dropIndex-1)%3)*55))
    -- Global scripts cannot raycast in OpenMW 0.51. Keep the corpse's known
    -- walkable elevation and move laterally toward the player; the small lift
    -- prevents terrain intersection without placing the reward inside the body.
    local dropPosition=actor.position+spreadDirection*distance+util.vector3(0,0,32)
    -- Keep the horizontal fan and let the short-lived local drop helper probe
    -- the active cell's height map/world collision for uneven terrain.
    item:teleport(actor.cell,dropPosition)
    -- Generated rewards remain reserved for the player while they are loose.
    -- The director removes this entry as soon as the player picks the item up;
    -- if the player later drops it, it is no longer protected and civilians
    -- may scavenge it like any ordinary player-dropped object.
    local loose={grace=0,protected=true,item=item}
    state.director.loose[item.id]=loose
    if C.groundGlow then
        local meta=state.records[item.recordId]
        local glowId=glowRecord(meta and meta.tier or 1)
        if glowId then
            local light=world.createObject(glowId,1)
            light:teleport(actor.cell,dropPosition+util.vector3(0,0,6))
            loose.light=light
        end
    end
    -- Global scripts cannot raycast on OpenMW 0.51, so attach a one-shot
    -- custom script to the dropped object. It returns only an id and a
    -- position (serializable across script contexts); the global handler below
    -- performs the actual teleports and removes the helper.
    item:addScript('scripts/ashenloot/drop.lua')
    return true
end
function M.scavenge(event)
    local actor,item=event.actor,event.item
    if not C.enabled or not C.scavenge or not valid(actor) or not item or not item:isValid() then return end
    if item.parentContainer or actor.cell~=item.cell or (actor.position-item.position):length()>240 then return end
    if not types.Weapon.objectIsInstance(item) and not types.Armor.objectIsInstance(item) then return end
    local ok,rec=pcall(function() return item.type.record(item) end)
    if not ok or not rec then return end
    local owner= item.owner
    if rec.mwscript or (owner and (owner.recordId or owner.factionId)) then return end
    local loose=state.director.loose[item.id]
    if type(loose)=='table' and loose.protected then return end
    local grace=type(loose)=='table' and loose.grace or loose
    if (grace or 0)>core.getSimulationTime() then return end
    -- OpenMW may update parentContainer one frame after moveInto succeeds;
    -- do not reject a successful transfer on that transient representation.
    local okMove=pcall(function() item:moveInto(types.Actor.inventory(actor)) end)
    if not okMove or not item:isValid() then return end
    actor:sendEvent('AshenLoot_Pickup',item)
end
local function rerunDungeon(cell,cellState,force)
    if not force and (not C.rerunnableDungeons or not cellState.clearedAt or not cellState.leftAfterClear
        or core.getGameTime()-cellState.clearedAt<C.dungeonResetHours*3600) then return 0 end
    local points={}
    for _,point in pairs(cellState.spawnPoints or {}) do points[#points+1]=point end
    if #points==0 then return 0 end
    table.sort(points,function(a,b) return (a.key or '')<(b.key or '') end)
    local wanted=math.max(1,math.floor(C.interiorBudget*directorDensity()+0.5))
    local target=gearLevel()
    local generation=(cellState.rerunGeneration or 0)+1
    local rng=R.rng(cell.id..':rerun:'..generation)
    local made=0
    for index=1,wanted do
        local point=points[((index-1)%#points)+1]
        local ring=math.floor((index-1)/#points)
        local angle=(index*2.399963)+ring
        local radius=ring*90
        local pos=util.vector3(point.x+math.cos(angle)*radius,point.y+math.sin(angle)*radius,point.z)
        local id=pickDungeonCreature(cell,target,rng)
        local spawn=world.createObject(id,1)
        state.director.generated[spawn.id]='rerun'
        spawn:teleport(cell,pos)
        spawn:sendEvent('AshenLoot_Spawned')
        made=made+1
    end
    setAdditionalCount(cellState,made);cellState.boss=false
    cellState.clearedAt=nil;cellState.leftAfterClear=false;cellState.emptySince=nil
    cellState.hadHostiles=true;cellState.rerunGeneration=generation
    cellState.resetGrace=core.getSimulationTime()+10
    print('[AshenLoot] repopulated dungeon '..cell.id..' with '..made..' enemies (wave '..generation..')')
    return made
end
local function updateCellState(player)
    local current=player.cell and player.cell.id
    if lastPlayerCell and lastPlayerCell~=current then
        local previous=state.director.cells[lastPlayerCell]
        if previous and previous.clearedAt then previous.leftAfterClear=true end
        if previous and previous.isExterior then previous.wildernessLeftAt=core.getGameTime() end
    end
    local entering=current~=lastPlayerCell
    lastPlayerCell=current
    local cell=player.cell
    if not cell then return end
    if cell.isExterior then
        local cellState=state.director.cells[current] or {additionalCount=0,boss=false,isExterior=true}
        state.director.cells[current]=cellState;cellState.isExterior=true
        if entering and C.rerunnableWilderness and cellState.wildernessLeftAt
            and core.getGameTime()-cellState.wildernessLeftAt>=C.wildernessResetHours*3600 then
            local live=0
            for _,actor in ipairs(world.activeActors) do
                local marker=state.director.generated[actor.id]
                if actor.cell==cell and marker and marker~='replacement' and marker~='bossAdd'
                    and valid(actor) then live=live+1 end
            end
            setAdditionalCount(cellState,live)
            for id,data in pairs(state.director.actors) do
                if data.cell==current and not state.director.generated[id] then state.director.actors[id]=nil end
            end
            cellState.wildernessLeftAt=nil
            print('[AshenLoot] wilderness reset: '..current..' ('..live..' surviving additions retained)')
        end
        return
    end
    if not dungeon(cell) then return end
    local cellState=state.director.cells[current] or {additionalCount=0,boss=false}
    state.director.cells[current]=cellState
    if entering then
        M.looseLoot(cell,player,level())
        rerunDungeon(cell,cellState,false)
    end
    if (cellState.resetGrace or 0)>core.getSimulationTime() then return end
    cellState.spawnPoints=cellState.spawnPoints or {}
    local alive,sawHostile=0,false
    for _,actor in ipairs(world.activeActors) do
        if actor.cell==cell and not types.Player.objectIsInstance(actor)
            and types.Actor.stats.ai.fight(actor).base>=80 then
            sawHostile=true
            if not types.Actor.isDead(actor) then alive=alive+1 end
            if not cellState.spawnPoints[actor.id] then
                cellState.spawnPoints[actor.id]={key=actor.id,x=actor.position.x,y=actor.position.y,z=actor.position.z}
            end
        end
    end
    if sawHostile then cellState.hadHostiles=true end
    if alive>0 then
        cellState.emptySince=nil
    elseif cellState.hadHostiles and not cellState.clearedAt then
        cellState.emptySince=cellState.emptySince or core.getSimulationTime()
        if core.getSimulationTime()-cellState.emptySince>=5 then
            cellState.clearedAt=core.getGameTime();cellState.leftAfterClear=false
            print('[AshenLoot] dungeon cleared: '..cell.id)
        end
    end
end
local function liveDirectorThreat(player)
    local threat,hostiles=0,0
    for _,actor in ipairs(world.activeActors) do
        if actor.cell==player.cell and valid(actor) and not types.Player.objectIsInstance(actor) then
            local distance=(actor.position-player.position):length()
            -- Peaceful native wildlife (netch farms, egg mines, etc.) is not
            -- crowding. Only actors that would actually attack the player
            -- suppress the director's hostile-population check.
            if distance<3000 and isAggressive(actor) then hostiles=hostiles+1 end
            if state.director.generated[actor.id]=='director' or state.director.generated[actor.id]=='den' then
                if distance<5000 then threat=threat+(state.director.directorCosts[actor.id] or 1) end
            end
        end
    end
    return threat,hostiles
end
local function updateDens(player)
    local now=core.getSimulationTime()
    for id,denState in pairs(state.director.dens) do
        denState.tier=math.max(1,math.min(3,tonumber(denState.tier) or 1))
        denState.cycles=math.max(0,tonumber(denState.cycles) or 0)
        denState.level=math.max(1,tonumber(denState.level) or gearLevel())
        local den
        for _,actor in ipairs(world.activeActors) do if actor.id==id then den=actor;break end end
        if den and den:isValid() and types.Actor.isDead(den) and not denState.dead then
            denState.dead=true
            local vfxId=denState.vfxId or ('dreamforged_den:'..id)
            -- Global removal is a backstop for cases where the actor script
            -- was detached/disabled on the same frame as death.
            core.sendGlobalEvent('RemoveVfx',vfxId)
            if not denState.vfxId then core.sendGlobalEvent('RemoveVfx','dreamforged_den') end
            local outdoor=state.director.outdoor
            outdoor.safeCell=den.cell.id;outdoor.safeUntil=math.max(outdoor.safeUntil or 0,now+30)
            enterOutdoorRelax(outdoor,now,C.directorIntensity,30)
            -- Destroying a den grants a short tactical lull, but it does not
            -- erase the wilderness appetite. Only a World Boss victory or a
            -- deliberate settlement reset clears the outdoor pressure arc.
        elseif den and valid(den) and den.cell==player.cell and (den.position-player.position):length()<3500
            and denState.cycles>0 and now>=(denState.nextWave or 0) then
            local threat=liveDirectorThreat(player)
            local cap=math.max(1,math.floor(9*C.directorIntensity+0.5))
            local cost=math.max(0.35,math.min(1.5,denState.level/math.max(1,gearLevel())))
            local rng=R.rng(id..':den-wave:'..denState.cycles)
            local wanted=denState.tier+rng(2)-1
            local count=math.min(wanted,math.max(0,math.floor((cap-threat)/cost)))
            if count>0 then
                denState.cycles=denState.cycles-1
                denState.nextWave=now+math.max(5,tonumber(C.creatureDenWaveInterval) or 5)
                local token=id..':den-wave:'..tostring(denState.cycles)
                pending[token]={actor=den,level=denState.level,count=count,cell=den.cell.id,
                    created=now,director=true,denWave=true,family=denState.family,cost=cost,
                    dirX=0,dirY=0}
                player:sendEvent('AshenLoot_FindSpawn',{token=token,actor=den,count=count,denWave=true})
            else
                -- No capacity is not a spent cycle.  Keep the den alive and
                -- try again on the next director tick once nearby enemies
                -- have been cleared.
                denState.nextWave=now+5
            end
        end
    end
end
local function updateOutdoorDirector(player)
    local cell=player.cell
    if not cell or not cell.isExterior or not C.extraEncounters then return end
    local d=state.director
    local outdoor=d.outdoor
    local now=core.getSimulationTime()
    local intensity=C.directorIntensity
    -- Director decisions are intentionally batched.  Five seconds is the
    -- responsive default: frequent enough to keep wilderness pressure alive,
    -- still bounded so terrain sampling never runs every frame.
    local interval=math.max(5,tonumber(C.outdoorDirectorInterval) or 5)
    local current={x=player.position.x,y=player.position.y,z=player.position.z}
    if outdoor.cell~=cell.id then
        outdoor.cell=cell.id;outdoor.last=current;outdoor.distance=0
        -- Pressure belongs to the journey, not the arbitrary exterior-cell
        -- boundary. Preserve it while re-aiming the next encounter.
        outdoor.nextRoll=math.min(outdoor.nextRoll or now+interval,now+interval)
    else
        local last=outdoor.last or current
        local dx,dy=current.x-last.x,current.y-last.y
        local step=math.sqrt(dx*dx+dy*dy)
        if step>1 then
            outdoor.dirX, outdoor.dirY=dx/step,dy/step
            outdoor.distance=(outdoor.distance or 0)+step
        end
        outdoor.last=current
    end
    if exteriorTown(cell) then
        -- Settlements are a pause, not a reset. Preserve the pressure and
        -- World Boss arc so simply brushing a town boundary cannot erase the
        -- journey's accumulated appetite. A deliberate safe sleep sends the
        -- reset event above.
        outdoor.nextRoll=now+interval
        outdoor.distance=0
        return
    end
    if outdoor.activeBossId then
        -- A living World Boss is the outdoor climax. Do not spend pressure or
        -- roll another player-centered group while its add waves are active.
        outdoor.pressure=0
        outdoor.bossProgress=0
        outdoor.nextRoll=now+interval
        outdoor.distance=0
        return
    end
    -- Recovery follows the player across arbitrary exterior-cell borders.
    if now<(outdoor.safeUntil or 0) then return end
    if outdoor.phase=='peak' then
        if now<(outdoor.peakUntil or 0) then return end
        outdoor.phase='build';outdoor.peakUntil=0
    elseif outdoor.phase=='relax' then
        if now<(outdoor.relaxUntil or 0) then return end
        outdoor.phase='build';outdoor.relaxUntil=0
    end
    local directorPending=false
    for _,request in pairs(pending) do
        if request.director and request.cell==cell.id then directorPending=true;break end
    end
    if directorPending or now<(outdoor.nextRoll or 0) or (outdoor.distance or 0)<150 then return end
    outdoor.nextRoll=now+interval
    outdoor.distance=0
    local live,hostiles=liveDirectorThreat(player)
    local cap=math.max(1,math.floor(9*intensity+0.5))
    local hp=types.Actor.stats.dynamic.health(player)
    local healthRatio=hp.base>0 and hp.current/hp.base or 1
    -- Active, healthy travel advances the overall dramatic arc even while a
    -- few native creatures are nearby. Only genuine crowding or danger pauses
    -- new spending; one-off rats and scribs no longer starve the director.
    if healthRatio>0.35 then
        local cadence=math.max(120,C.worldBossCadenceMinutes*60)
        outdoor.bossProgress=math.min(100,(outdoor.bossProgress or 0)+100*interval/cadence)
    end
    if live>=cap or hostiles>=math.max(8,cap) or healthRatio<=0.35 then return end
    local rng=R.rng(cell.id..':outdoor-director:'..math.floor(now/interval))
    local configuredChance=tonumber(C.outdoorDirectorChance)
    local baseChance=configuredChance and math.max(0,math.min(95,configuredChance))
        or math.max(15,math.min(80,35+(intensity-1)*25))
    local chance=math.min(95,baseChance+(outdoor.pressure or 0))
    if rng(100)>chance then
        outdoor.pressure=math.min(100,(outdoor.pressure or 0)+(tonumber(C.outdoorPressureGain) or 15)*intensity)
        return
    end
    -- At low pressure, spend the roll on a visible group of weaker enemies;
    -- rising pressure keeps the group size but lets the promotion ladder move
    -- one or two members into higher tiers.  Respect the exposed group bounds
    -- while making the shipped default (2--4) feel consistently inhabited.
    local pressure01=math.max(0,math.min(1,(outdoor.pressure or 0)/100))
    local groupMin=math.max(1,math.floor(tonumber(C.exteriorGroupMin) or 1))
    local groupMax=math.max(groupMin,math.floor(tonumber(C.exteriorGroupMax) or 3))
    local low=math.min(groupMax,groupMin+math.floor((1-pressure01)*math.min(2,groupMax-groupMin)+0.5))
    local high=groupMax
    local power=gearLevel()
    local target=math.max(1,math.floor(power*(0.54+rng(61)/100)+0.5))
    local cost=math.max(0.35,math.min(1.5,target/power))
    local count=math.min(math.max(0,math.floor((cap-live)/cost)),low+rng(high-low+1)-1)
    if count<=0 then return end
    -- Spending a director group does not erase appetite. The player is still
    -- out in the wilderness and the arc should keep trending upward until a
    -- World Boss victory or a deliberate safe sleep.
    outdoor.lastEncounterAt=now
    local token=cell.id..':director:'..tostring(now)
    local denActive=false
    for _,denState in pairs(d.dens) do if denState.cell==cell.id and not denState.dead then denActive=true;break end end
    local denChance=math.min(50,math.max(0,tonumber(C.creatureDenChance) or 12))
    if not denActive and rng(100)<=denChance and live+2<=cap then
        local families={'beast','undead','daedra','construct'}
        local family=families[rng(#families)]
        local maxTier=power>=25 and 3 or (power>=10 and 2 or 1)
        local tier=rng(maxTier)
        local cycleLow=1
        local cycleHigh=math.max(1,math.ceil(3*math.sqrt(intensity)))
        pending[token]={actor=player,level=target,count=1,cell=cell.id,created=now,
            director=true,den=true,family=family,tier=tier,cycles=cycleLow+rng(cycleHigh-cycleLow+1)-1,cost=2,
            dirX=outdoor.dirX or 1,dirY=outdoor.dirY or 0}
        player:sendEvent('AshenLoot_FindSpawn',{token=token,actor=player,count=1,
            director=true,dirX=outdoor.dirX or 1,dirY=outdoor.dirY or 0})
    else
        pending[token]={actor=player,level=target,count=count,cell=cell.id,
            created=now,director=true,cost=cost,
            dirX=outdoor.dirX or 1,dirY=outdoor.dirY or 0}
        player:sendEvent('AshenLoot_FindSpawn',{token=token,actor=player,count=count,
            director=true,dirX=outdoor.dirX or 1,dirY=outdoor.dirY or 0})
    end
end
function M.update(dt)
    timer=timer+dt
    if timer<1 or not C.enabled or not world.players[1] then return end
    timer=0
    updateCellState(world.players[1])
    for itemId,loose in pairs(state.director.loose) do
        if type(loose)=='table' and (not loose.item or not loose.item:isValid() or loose.item.parentContainer) then
            if loose.light and loose.light:isValid() then loose.light:remove() end
            state.director.loose[itemId]=nil
        elseif type(loose)=='number' and loose<core.getSimulationTime()-300 then
            state.director.loose[itemId]=nil
        end
    end
    local count=0
    local player=world.players[1]
    updateDens(player)
    updateOutdoorDirector(player)
    for _,actor in ipairs(world.activeActors) do
        if count>=3 then break end
        local legacyExterior=state.director.generated[actor.id]==true and actor.cell.isExterior
        local distance=(actor.position-player.position):length()
        local closeEnough=not actor.cell.isExterior or distance<=3000
        if valid(actor) and eligible(actor) and (not state.director.actors[actor.id] or legacyExterior)
            and closeEnough
            and (considered[actor.id] or 0)<core.getSimulationTime()
            and (types.Creature.objectIsInstance(actor)
                or types.Actor.stats.ai.fight(actor).base>=80
                or (C.guardProgression and isGuard(actor))) then
            considered[actor.id]=core.getSimulationTime()+10
            actor:sendEvent('AshenLoot_Consider');count=count+1
        end
    end
    for token,request in pairs(pending) do
        if core.getSimulationTime()-request.created>15 then
            if request.replacement then state.director.actors[request.actor.id]=nil end
            if request.count and not request.director and state.director.cells[request.cell] then
                local cellState=state.director.cells[request.cell]
                setAdditionalCount(cellState,additionalCount(cellState)-request.count)
            end
            pending[token]=nil
        end
    end
end
function M.refreshPools()
    pools, gear, itemPools, kindPools, genericCreatureIds = nil, nil, nil, nil, nil
end
M.test={supplyRecord=supplyRecord,pickCreature=pickCreature,dungeon=dungeon,rerunDungeon=rerunDungeon,
    pickNpcReinforcement=pickNpcReinforcement,randomizeInventory=randomizeInventory,
    randomBase=randomBase,isGuard=isGuard,isAggressive=isAggressive,worldBossScale=worldBossScale,
    activeWorldBosses=activeWorldBosses,
    estimatedLevel=estimatedLevel,encounterTarget=encounterTarget,pickDungeonCreature=pickDungeonCreature,
    randomBroadBase=randomBroadBase,randomNativeEnchanted=randomNativeEnchanted,
    randomSimilarEnchanted=randomSimilarEnchanted,
    randomContainerBase=randomContainerBase,npcGearChances=npcGearChances,
    randomLooseBase=randomLooseBase,looseDungeon=looseDungeon,safeRecord=safeRecord,
    ordinaryCreatureRecord=ordinaryCreatureRecord,populationAnchor=populationAnchor,
    safeInventoryRecord=safeInventoryRecord,
    gearLevel=gearLevel,combatDps=playerCombatDps,damageProfile=playerDamageProfile,
    gearHealthScale=gearHealthScale,prestigeScale=prestigeScale,recordKillTime=M.recordKillTime,
    additionalCount=additionalCount,applyOutdoorVictory=applyOutdoorVictory,
     enterOutdoorPeak=enterOutdoorPeak,enterOutdoorRelax=enterOutdoorRelax,safeSleep=M.safeSleep}
return M
