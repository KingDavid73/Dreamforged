-- Pure Lua rules, shared by the engine scripts and deterministic tests.
local M = {}
M.rarities = {
    -- Keep the two chase tiers equally likely.  The previous table had a
    -- zero-weight Relic entry, which made natural Relic rolls unreachable
    -- (only forced World Boss rewards could create one).
    { name = 'Common', color = {0.82, 0.82, 0.82}, weight = 43 },
    { name = 'Uncommon', color = {0.35, 0.90, 0.42}, weight = 32 },
    { name = 'Rare', color = {0.40, 0.64, 1.00}, weight = 15 },
    { name = 'Epic', color = {0.78, 0.43, 1.00}, weight = 6 },
    { name = 'Legendary', color = {1.00, 0.49, 0.15}, weight = 2 },
    { name = 'Relic', color = {1.00, 0.92, 0.55}, weight = 2 },
}
-- World Bosses use a deliberately generous, self-contained reward table.
-- Mythic is tier 7 here because it is a curated artifact rather than part of
-- the ordinary Common-to-Relic procedural ladder.
M.worldBossRarities = {1, 2, 7, 20, 30, 20, 20}
M.worldBossNames = {
    beast={'the Ashen Colossus','the Elder Fang','the Unclean','Blight-Touched','Red Mountain Hunger',
        'Scourge of the Grazelands','the Egg-Mine Terror','the Silt-Strider Bane','the Wild Hunt',
        'the Bitter Coast Horror','the Velothi Devourer','Spawn of the Ash Storm'},
    undead={'the Deathless','Grave-Sovereign','the Hollow King','Keeper of the Sixth Tomb',
        'the Unshriven','Bone-Warden','the Ancestor Forsaken','the Ashen Revenant','Crypt-Speaker',
        'the Sleepless Hunger','Bearer of the Black Heart','the Nameless House'},
    daedra={'the Doom Herald','the Red Exile','Oath-Breaker','Dagon\'s Castoff','the Ashpit Tyrant',
        'the House of Troubles','the Oblivion-Bound','the Kinslayer of Coldharbour','the Bad Man\'s Hand',
        'the Unbidden','the Sigil-Breaker','the Prince\'s Regret'},
    construct={'the Brass Tyrant','the Unmaking Engine','the Last Centurion','the Tonal Ruin',
        'Kagrenac\'s Error','the Deep-Forged','the Anumidium Shard','the Silent Gear',
        'the Architect\'s Wrath','the Broken Tonality','the Ghost in Brass','the Lost Animunculus'},
}
M.worldBossGivenNames = {
    rat={'Rothis','Gnaw-in-Ash','Skar-Tail'}, scrib={'Vaba-Scrib','Chitin-Song','Shalk-Tongue'},
    mudcrab={'Shell-of-Rethan','Dreughkin','Redoran\'s Bane'}, guar={'Ash-Back','Herd-Breaker','Veloth\'s Stray'},
    alit={'Red Maw','Ashfang','Molag\'s Hound'}, kagouti={'Kagren\'s Tusk','Gorehide','Red Mountain Horn'},
    nix={'Nix-Blood','Dust-Hound','Silt-Strider\'s Bane'}, cliff={'Jiub\'s Regret','Sky-Screech','Vivec\'s Nuisance'},
    fish={'Dreugh-Bait','Abecean Maw','Old Blue-Fin'}, ogrim={'Ashpit-Born','Malacath\'s Gut','Ghor-Grahn'},
    skeleton={'Relas Bone-Hand','Saren the Unburied','Othrelas'}, ghost={'Aralor Unmourned','Vevrana','Drinar Ancestor-Lost'},
    daedroth={'Krazzt','Uroth-Bal','Zanrakh'}, dremora={'Valkyn Rethar','Kynval Zanar','Caitiff Vhor'},
    scamp={'Razzik','Murrit','Skritch'}, centurion={'Bthuand Mzahn','Kagren-Bal','Mzuleft Remnant'},
}
local familySyllables={
    beast={{'Ash','Red','Vel','Silt','Chit','Graz'},{'fang','maw','hide','tusk','claw','back'}},
    undead={{'Aral','Dral','Oth','Seran','Vev','Rela'},{'or','as','yn','is','oth','ar'}},
    daedra={{'Kraz','Valk','Zan','Uroth','Mehr','Vhor'},{'akh','yn','oth','ara','az','eth'}},
    construct={{'Bthu','Mzun','Kagren','Nchur','Arkng','Dum'},{'damz','zahn','thumz','left','dahrk','ac'}},
}
local function bossGivenPool(baseName,family)
    local lower=baseName:lower()
    for _,key in ipairs({'mudcrab','slaughterfish','fish','scrib','guar','alit','kagouti','nix','cliff','ogrim',
        'skeleton','ghost','daedroth','dremora','scamp','centurion','rat'}) do
        local pool=M.worldBossGivenNames[key]
        if pool and lower:find(key,1,true) then return pool end
    end
    local parts=familySyllables[family] or familySyllables.beast
    local pool={}
    for i=1,3 do
        local roll=M.rng(lower..':'..family..':given:'..i)
        pool[i]=parts[1][roll(#parts[1])]..parts[2][roll(#parts[2])]
    end
    return pool
end
function M.worldBossName(seed,baseName,family)
    local titles=M.worldBossNames[family] or M.worldBossNames.beast
    local given=bossGivenPool(baseName,family)
    local nameRoll=M.rng(seed..':worldboss-given-v2');nameRoll(997)
    local titleRoll=M.rng(seed..':worldboss-title-v2');titleRoll(7919);titleRoll(1543)
    return given[nameRoll(#given)]..' '..titles[titleRoll(#titles)]
end
M.npcBossTitles = {
    generic={'the Dread','the Unbroken','the Ash-Crowned','the Blood-Anointed','the Doom-Wreathed'},
    combat={'the War-Blessed','the Iron Reaver','the Oath-Hammer','the Unyielding','the Red-Handed'},
    magic={'the Spell-Tyrant','the Aether-Crowned','the Hex-Sovereign','the Rune-Bound','the Void-Speaker'},
    stealth={'the Unseen Hand','the Night-Knife','the Silent Doom','the Shadow-Crowned','the Whispering Death'},
    dunmer={'the Ash-Blooded','the Ancestor-Forsaken','Red Mountain\'s Wrath'},
    nord={'the Frost-Bitten','the Whale-Bone Reaver','Storm of Solstheim'},
    orc={'Malacath\'s Chosen','the Ashpit Hammer','the Oath-Breaker'},
    argonian={'Hunts-in-Ash','the Hist-Forsaken','the Marsh-Born Terror'},
    khajiit={'Moon-Claw','Masser\'s Fang','the Sugar-Mad'},
    bosmer={'the Green-Pact Breaker','Wild-Hunt-Touched','the Walking Thorn'},
    altmer={'the Star-Crowned','the Tower\'s Scorn','the Aetherial Tyrant'},
    breton={'the Witch-Blooded','the Spell-Reaver','the Direnni Scourge'},
    imperial={'the Iron Tribune','the Black Legion','the Ruby Throne\'s Bane'},
    redguard={'the Ansei-Forsaken','the Yokudan Blade','the Walking Sandstorm'},
}
function M.worldBossNpcName(seed,baseName,race,specialization)
    baseName=(baseName and baseName~='') and baseName or 'Nameless Wanderer'
    local raceKey=tostring(race or ''):lower():gsub('^.*:', '')
    local specKey=tostring(specialization or ''):lower()
    local pools={M.npcBossTitles.generic}
    if M.npcBossTitles[specKey] then pools[#pools+1]=M.npcBossTitles[specKey] end
    for key,pool in pairs(M.npcBossTitles) do
        if key~='generic' and key~='combat' and key~='magic' and key~='stealth'
            and raceKey:find(key,1,true) then pools[#pools+1]=pool;break end
    end
    local rng=M.rng(seed..':npc-worldboss-v1')
    local pool=pools[rng(#pools)]
    local title=pool[rng(#pool)]
    -- Preserve the authored NPC identity; only decorate it with a compact title.
    if rng(3)==1 then return title:gsub('^the ','')..' '..baseName end
    return baseName..', '..title
end
local uniqueOrigins={
    beast={'Hunters once dismissed this creature as ordinary prey.','Ashlanders marked its spoor but refused to follow it.','It survived where blight, steel, and hunger killed the rest.'},
    undead={'The name carved above its tomb has long since weathered away.','Improper rites left this spirit with neither rest nor ancestor shrine.','It remembers its burial more clearly than it remembers life.'},
    daedra={'A forgotten summoning bound it to Mundus after its master died.','It crossed from Oblivion beneath an inauspicious red moon.','Even the cult that called it forth eventually fled its presence.'},
    construct={'Its makers struck its designation from every surviving tablet.','A tonal command still drives this machine through the deep places.','It woke alone after centuries beneath ash and fallen stone.'},
}
local uniqueTurns={
    beast={'Repeated battles taught it to hunt armed prey.','Something in the ash changed its blood and sharpened its instincts.','Each narrow escape made it stranger, larger, and less afraid.'},
    undead={'Centuries of resentment hardened memory into sorcery.','Every trespasser added another grievance to its deathless vigil.','The silence of the tomb gathered around it like armor.'},
    daedra={'Its long exile taught it cruelties unknown in its native realm.','Broken pacts became the source of its unnatural strength.','It learned to feed upon the laws that should have constrained it.'},
    construct={'Damaged directives have become something resembling malice.','Corroded mechanisms now turn with impossible purpose.','A fractured tonal core continually rewrites its ancient design.'},
}
local powerLore={
    Ashbrand='Fire gathers wherever its blows fall.',Rimebound='The air freezes around its passing.',
    ['Storm-Crowned']='Thunder answers its fury.', ['Venom-Weaver']='Its wounds carry an alchemist’s nightmare.',
    ['Bone-Warded']='An unseen weight turns aside ordinary blows.',Huntsman='Distance offers little protection from its pursuit.',
    ['Oath-Wrath']='An old oath lends violence to every strike.', ['Red Hunger']='Blood lost nearby seems to strengthen it.',
    ['Hush-Woven']='Sound and certainty fade around its outline.', ['Aether-Hungry']='Spells unravel and feed the thing they were meant to harm.',
    Spellbreaker='Sorcery recoils from its warded flesh.',Juggernaut='Pain only deepens its momentum.',
    ['Mist-Stalker']='It moves behind a veil that confuses eye and instinct.', ['War-Blessed']='Battle itself appears to favor it.',
    ['Void-Warded']='The space around it rejects hostile magic.', ['Life-Drinker']='Every wound it opens purchases another moment of life.',
}
local bossTitleLore={
    ['the Ashen Colossus']='Ashlander tales claim the earth itself enlarged this foe to carry Red Mountain’s anger.',
    ['the Elder Fang']='Its spoor appears in hunting records older than several Great Houses.',
    ['the Unclean']='Temple cautions name it as a walking profanation that no cleansing rite could quiet.',
    ['Blight-Touched']='It endured the red storms until blight became inheritance rather than disease.',
    ['Red Mountain Hunger']='Pilgrims say its appetite is a small echo of the hunger beneath Red Mountain.',
    ['Scourge of the Grazelands']='Entire grazing paths were abandoned after its shadow crossed the northern grasslands.',
    ['the Egg-Mine Terror']='Kwama workers ceased answering their keepers wherever this terror nested.',
    ['the Silt-Strider Bane']='Caravan masters still leave offerings where a strider once fell beneath it.',
    ['the Wild Hunt']='Bosmer whisper that some fragment of the formless Hunt was stranded in this body.',
    ['the Bitter Coast Horror']='Smugglers used its cries to frighten rivals until the cries began answering them.',
    ['the Velothi Devourer']='Velothi stones mark settlements whose names survived only in its legends.',
    ['Spawn of the Ash Storm']='Witnesses insist the storm deposited it fully grown and already enraged.',
    ['the Deathless']='Neither consecration nor dismemberment persuaded this dead thing to remain dead.',
    ['Grave-Sovereign']='Restless dead gather around it as though remembering an ancient court.',
    ['the Hollow King']='It rules no living subject, yet empty tombs still answer its summons.',
    ['Keeper of the Sixth Tomb']='The Sixth House entrusted it with a secret even its dreamers were forbidden to speak.',
    ['the Unshriven']='No recognized rite can account for the stubborn knot binding spirit to remains.',
    ['Bone-Warden']='It has guarded forgotten bones so long that none remember whose they were.',
    ['the Ancestor Forsaken']='Its descendants erased every shrine, but could not erase the ancestor.',
    ['the Ashen Revenant']='Each red storm renews the purpose that dragged it from burial.',
    ['Crypt-Speaker']='Those who sleep near its tomb dream in the voices of strangers.',
    ['the Sleepless Hunger']='Death removed every mortal need except appetite.',
    ['Bearer of the Black Heart']='A dark relic beats where no living heart remains.',
    ['the Nameless House']='Records of its bloodline were destroyed, leaving the corpse to embody the House alone.',
    ['the Doom Herald']='Its arrival has preceded calamity often enough to make coincidence an indulgence.',
    ['the Red Exile']='Some unnamed Prince cast it out, but neglected to strip away its power.',
    ['Oath-Breaker']='The terms of its broken pact still scar the air around it.',
    ["Dagon's Castoff"]='Even Mehrunes Dagon found no further use for this ruinous servant.',
    ['the Ashpit Tyrant']='Orc wise women name it among the cruelest shapes rejected by Malacath.',
    ['the House of Troubles']='Four old miseries seem to speak through one Daedric will.',
    ['the Oblivion-Bound']='Its body stands in Vvardenfell, but its shadow falls elsewhere.',
    ['the Kinslayer of Coldharbour']='Coldharbour remembers the kin it betrayed even when mortals do not.',
    ["the Bad Man's Hand"]='Ashlander stories treat it as one grasping finger of an older enemy.',
    ['the Unbidden']='No summoner claims responsibility for opening its path into the world.',
    ['the Sigil-Breaker']='Conjurers learned too late that no binding circle remained whole around it.',
    ["the Prince's Regret"]='Its continued existence is said to embarrass the very Prince who fashioned it.',
    ['the Brass Tyrant']='Dwemer mechanisms still alter their patrols rather than cross its path.',
    ['the Unmaking Engine']='Every motion appears calculated to reduce ordered things into components.',
    ['the Last Centurion']='No surviving machine acknowledges its command, yet it continues to issue orders.',
    ['the Tonal Ruin']='A broken Dwemer harmony resonates from its frame like a mortal curse.',
    ["Kagrenac's Error"]='Forbidden diagrams describe it only as a result that must never be repeated.',
    ['the Deep-Forged']='It bears alloys and workmanship found nowhere above the lowest ruins.',
    ['the Anumidium Shard']='Its builders mistook imitation of a god for an ordinary engineering problem.',
    ['the Silent Gear']='Nearby machinery falls quiet as though listening for its next rotation.',
    ["the Architect's Wrath"]='Its violence follows plans whose architect and purpose have both been lost.',
    ['the Broken Tonality']='One impossible note sustains its damaged frame.',
    ['the Ghost in Brass']='Something more willful than machinery watches through its metal face.',
    ['the Lost Animunculus']='No ruin claims its manufacture, and no known control signal reaches it.',
}
function M.biography(seed,data)
    local rng=M.rng(seed..':biography-v1')
    local family=data.family or 'beast'
    local mods={}
    for _,index in ipairs(data.modifiers or {}) do
        local mod=M.elites[index]
        if mod and powerLore[mod.name] then mods[#mods+1]=powerLore[mod.name] end
    end
    local power=#mods>0 and mods[rng(#mods)] or 'Its surviving strength defies any simple explanation.'
    if data.worldBoss then
        local dedicated
        for title,lore in pairs(bossTitleLore) do
            if tostring(data.name or ''):find(title,1,true) then dedicated=lore;break end
        end
        dedicated=dedicated or 'Its name survives in warnings exchanged between those fortunate enough to escape it.'
        return dedicated..' '..power
    end
    local origins=uniqueOrigins[family] or uniqueOrigins.beast
    local turns=uniqueTurns[family] or uniqueTurns.beast
    return origins[rng(#origins)]..' '..turns[rng(#turns)]..' '..power
end
function M.rng(seed)
    local n = 1
    for i = 1, #tostring(seed) do n = (n * 31 + tostring(seed):byte(i)) % 2147483647 end
    return function(max)
        n = (n * 48271) % 2147483647
        local v = n / 2147483647
        return max and math.floor(v * max) + 1 or v
    end
end
function M.rarity(random, minimum, bonus)
    -- Rarity bonuses improve a roll, but never collapse the overflow into the
    -- final percentile.  Capping `random(100) + bonus` at 100 made every roll
    -- above the cap a Relic, which was especially visible on promoted packs.
    -- Keep a small natural Relic slice, then let promotion/gear bonus widen it
    -- gradually (0.25 percentage points per bonus point, capped at 20%). The
    -- bonus is decided as an expanded top slice rather than by clamping an
    -- overflowing roll to 100, so high-tier packs become more likely to see a
    -- Relic without turning every overflowed result into one.
    local raw=math.floor(tonumber(random(100)) or 1)
    raw=math.max(1,math.min(100,raw))
    local amount=math.max(0,math.floor(tonumber(bonus) or 0))
    local relicWeight=M.rarities[#M.rarities] and M.rarities[#M.rarities].weight or 1
    local relicChance=math.min(20,relicWeight+amount*0.25)
    local relicStart=101-relicChance
    local roll
    if raw>=relicStart then
        return math.max(#M.rarities, minimum or 1)
    else
        -- Keep the ordinary CDF's final percentile reserved for Relic. The
        -- expanded Relic chance above is handled explicitly, so promoted
        -- overflow can still reach Legendary without becoming Relic by
        -- accident.
        roll=math.min(98,raw+amount)
    end
    local sum = 0
    for i, r in ipairs(M.rarities) do
        sum = sum + r.weight
        if roll <= sum then return math.max(i, minimum or 1) end
    end
    return #M.rarities
end
function M.levelRarityBonus(level)
    return math.min(15,math.max(0,math.floor(math.log(math.max(1,level or 1)+1)/math.log(2)*2)-1))
end
function M.worldBossRarity(random, upwardBonus)
    local roll=math.max(1,math.min(100,math.floor(tonumber(random(100)) or 1)))
    local total,tier=0,#M.worldBossRarities
    for index,weight in ipairs(M.worldBossRarities) do
        total=total+weight
        if roll<=total then tier=index;break end
    end
    -- Level, overgear and configured difficulty can promote the base result by
    -- one step. Keeping this as a separate roll preserves the exact 1/2/7/20/
    -- 30/20/20 base table instead of piling clamped overflow into Mythic.
    local chance=math.max(0,math.min(100,math.floor(tonumber(upwardBonus) or 0)))
    if tier<#M.worldBossRarities and chance>0 and random(100)<=chance then tier=tier+1 end
    return tier
end
M.lootCosts={1,2,5,12,25,45}
M.lootBudgetProfiles={
    [0]={min=1,max=2,floor=1,lowCap=2},
    [1]={min=1,max=3,floor=2,lowCap=1},
    [2]={min=1,max=4,floor=3,lowCap=1},
    [3]={min=2,max=5,floor=4,lowCap=1},
    [4]={min=3,max=6,floor=5,lowCap=0},
}
-- Convert one defeated actor's power budget into a bounded package. Promotion
-- floors, low-tier caps and a hard six-slot ceiling prevent both fifty Commons
-- and mechanically identical boss piles. Unspent value upgrades existing rolls.
function M.lootBudgetPlan(random,rank,budget,mythicPercent)
    rank=math.max(0,math.min(4,math.floor(tonumber(rank) or 0)))
    budget=math.max(0,tonumber(budget) or 0)
    local profile=M.lootBudgetProfiles[rank]
    local goal=profile.min+random(profile.max-profile.min+1)-1
    local tiers={}
    if rank==4 and random(100)<=math.max(0,math.min(100,mythicPercent or 0)) then tiers[#tiers+1]=7 end
    local proceduralGoal=math.max(rank>0 and 1 or 0,goal-#tiers)
    local remaining=budget
    if proceduralGoal>0 then
        tiers[#tiers+1]=profile.floor
        remaining=math.max(0,remaining-M.lootCosts[profile.floor])
    end
    local low=0
    while #tiers<goal do
        local slotsLeft=goal-#tiers
        local ideal=remaining/math.max(1,slotsLeft)
        local choices,weights,total={},{},0
        local requiredAfter=math.max(0,profile.min-(#tiers+1))
        local spendable=remaining-requiredAfter*M.lootCosts[profile.floor]
        for tier=1,6 do
            local isLow=tier<profile.floor
            if M.lootCosts[tier]<=spendable and (not isLow or low<profile.lowCap) then
                local distance=math.abs(math.log(math.max(1,ideal))/math.log(2)-math.log(M.lootCosts[tier])/math.log(2))
                local weight=math.max(1,math.floor(24/(1+distance)+0.5))
                choices[#choices+1]=tier;weights[#weights+1]=weight;total=total+weight
            end
        end
        if #choices==0 then break end
        local roll=random(total);local chosen=choices[#choices]
        for index,weight in ipairs(weights) do roll=roll-weight;if roll<=0 then chosen=choices[index];break end end
        tiers[#tiers+1]=chosen;remaining=remaining-M.lootCosts[chosen]
        if chosen<profile.floor then low=low+1 end
    end
    -- Remaining budget raises quality instead of buying a tail of cheap items.
    local upgraded=true
    while upgraded do
        upgraded=false
        for index=#tiers,1,-1 do
            local tier=tiers[index]
            if tier<6 then
                local delta=M.lootCosts[tier+1]-M.lootCosts[tier]
                if remaining>=delta then tiers[index]=tier+1;remaining=remaining-delta;upgraded=true end
            end
        end
    end
    return tiers,remaining
end
-- Decide how much saved reward credit joins this promoted enemy's personal
-- budget. Hunger makes long dry stretches less likely, but never guarantees a
-- named item. A spree releases much of the reserve; a frugal result saves it.
function M.lootDirectorSpend(random,bank,hunger,rank,strength,spreePercent)
    bank=math.max(0,tonumber(bank) or 0);hunger=math.max(0,math.min(100,tonumber(hunger) or 0))
    rank=math.max(0,math.min(4,math.floor(tonumber(rank) or 0)))
    strength=math.max(0.1,math.min(3,tonumber(strength) or 1))
    if rank<=0 or bank<1 then return 0,'saving' end
    local releaseChance=math.min(92,18+rank*11+hunger*0.45)
    if random(100)>releaseChance then return 0,'saving' end
    local spreeChance=math.min(90,(tonumber(spreePercent) or 15)+hunger*0.35)
    if random(100)<=spreeChance then
        local fraction=0.45+random(41)/100
        return math.min(bank,math.max(1,bank*fraction*strength)),'spree'
    end
    local allowance=(2+rank*3+random(5+rank*3))*strength
    return math.min(bank,allowance),'steady'
end
M.prefixes = {
    { name = 'Dagonfire', defensiveName = 'Fireshrouded', effect = 'firedamage', guard = 'fireshield', duration = 2 },
    { name = 'Rimefang', defensiveName = 'Frostshrouded', effect = 'frostdamage', guard = 'frostshield', duration = 2 },
    { name = 'Stormkissed', defensiveName = 'Stormshrouded', effect = 'shockdamage', guard = 'lightningshield', duration = 1, factor = 1.5 },
    { name = 'Webvenom', defensiveName = 'Webwoven', effect = 'poison', guard = 'chameleon', duration = 3, factor = 0.65 },
    { name = 'Spell-Drinking', defensiveName = 'Aetherwoven', effect = 'absorbmagicka', guard = 'fortifymagicka', duration = 2, minTier = 2 },
    { name = 'Spirit-Rending', defensiveName = 'Ancestor-Warded', effect = 'damagehealth', guard = 'sanctuary', duration = 1, minTier = 2 },
    { name = 'Magebane', defensiveName = 'Spell-Warded', effect = 'silence', guard = 'spellabsorption', duration = 3, minTier = 2 },
    { name = 'Soul-Thirsting', defensiveName = 'Vital', effect = 'absorbhealth', guard = 'fortifyhealth', duration = 2, minTier = 2 },
    { name = 'Hexing', defensiveName = 'Mirror-Warded', effect = 'weaknesstomagicka', guard = 'reflect', duration = 4, minTier = 3 },
    { name = 'Blinding', defensiveName = 'Mist-Woven', effect = 'blind', guard = 'chameleon', duration = 3, minTier = 2 },
    { name = 'Burdening', defensiveName = 'Featherlight', effect = 'burden', guard = 'feather', duration = 4 },
    { name = 'Will-Breaking', defensiveName = 'Resolute', effect = 'demoralizehumanoid', guard = 'resistmagicka', duration = 3, minTier = 3 },
    { name = 'Bloodletter', defensiveName = 'Blood-Warded', effect = 'damagehealth', guard = 'restorehealth', duration = 5, factor = 0.45, minTier = 2 },
    { name = 'Dreambinding', defensiveName = 'Wakeful', effect = 'paralyze', guard = 'resistparalysis', duration = 1, fixed = 1, minTier = 3 },
    { name = 'Beast-Binding', defensiveName = 'Beast-Warded', effect = 'commandcreature', guard = 'resistmagicka', nativeWeapon = false, weaponProc = 'command', minTier = 3 },
    { name = 'Will-Binding', defensiveName = 'Will-Warded', effect = 'commandhumanoid', guard = 'resistmagicka', nativeWeapon = false, weaponProc = 'command', minTier = 3 },
    { name = 'Storm-Branching', defensiveName = 'Stormheart', effect = 'shockdamage', guard = 'lightningshield', duration = 1, factor = 0.7, weaponProc = 'chain', minTier = 2 },
}
M.suffixes = {
    { name = 'of Sundering', defensiveName = 'of the Earth Bones', property = 'damage', effect = 'damagehealth', guard = 'shield' },
    { name = "of Veloth's Road", property = 'weight', effect = 'restorefatigue', self = true, guard = 'feather', duration = 3 },
    { name = "of Malacath's Oath", property = 'condition', effect = 'fortifyattribute', self = true, guard = 'fortifyattribute', attribute = 'strength', duration = 6 },
    { name = 'of Red Hunger', defensiveName = 'of the Unbroken Heart', effect = 'absorbhealth', guard = 'fortifyhealth', duration = 2 },
    { name = 'of the Tireless', effect = 'restorefatigue', self = true, guard = 'restorefatigue', duration = 2 },
    { name = 'of the Inward Tower', effect = 'spellabsorption', self = true, guard = 'spellabsorption', duration = 6, minTier = 3 },
    { name = 'of Aetherial Reserve', effect = 'restoremagicka', self = true, guard = 'fortifymagicka', duration = 2, minTier = 3 },
    { name = 'of the Hidden Hand', effect = 'fortifyattribute', self = true, guard = 'fortifyattribute', attribute = 'agility', duration = 5 },
    { name = 'of the Wind', effect = 'fortifyattribute', self = true, guard = 'fortifyattribute', attribute = 'speed', duration = 6 },
    { name = 'of the Duelist', effect = 'fortifyattack', self = true, guard = 'sanctuary', duration = 6 },
    { name = 'of Spell Turning', effect = 'reflect', self = true, guard = 'reflect', duration = 5, minTier = 3 },
    { name = 'of the Leech', effect = 'absorbhealth', guard = 'restorehealth', duration = 2, minTier = 2 },
    { name = 'of Crushing Weight', effect = 'burden', guard = 'feather', duration = 4, weaponProc = 'crushing' },
    { name = 'of the Battlemage', effect = 'fortifymagicka', self = true, guard = 'fortifymagicka', duration = 6, minTier = 2 },
    { name = 'of the Briarheart', defensiveName = 'of the Briar Ward', effect = 'damagehealth', guard = 'shield', duration = 2, armorProc = 'thorns', minTier = 2 },
    { name = 'of Arcane Echoes', defensiveName = 'of the Warding Echo', effect = 'shockdamage', guard = 'spellabsorption', duration = 1,
        weaponProc = 'castOnHit', armorProc = 'castWhenStruck', minTier = 2 },
}
M.itemProcs = {
    thorns={trigger='struck',chance=1,cooldown=1,description='Melee attackers take level-scaled retaliatory damage'},
    castOnHit={trigger='hit',chance=0.25,cooldown=4,description='25% chance on hit to cast a fire, frost, or shock burst'},
    castWhenStruck={trigger='struck',chance=0.20,cooldown=6,description='20% chance when struck to release an elemental nova'},
    command={trigger='hit',chance=0.18,cooldown=12,description='18% chance to command a safe non-player target for 6s'},
    crushing={trigger='hit',chance=0.18,cooldown=6,description='18% chance to deal capped damage based on current health'},
    chain={trigger='hit',chance=0.25,cooldown=4,description='25% chance to arc shock damage to a nearby hostile'},
}
-- Legacy display data stays separate from the new effect definitions;
-- new encounters explicitly carry rulesVersion=3.
M.legacyElites = {
    {name='Molten', description='40% fire resistance'}, {name='Rimeblood', description='40% frost resistance'},
    {name='Stormbound', description='40% shock resistance'}, {name='Venomward', description='60% poison resistance'},
    {name='Ironhide', description='20 points of shield'}, {name='Swift', description='+25 speed'},
    {name='Savage', description='+20 strength'}, {name='Regenerating', description='Regenerates 1 health per second'},
}
M.elites = {
    { name = 'Ashbrand', epithet = 'the Ashbrand', effect = 'fireshield', magnitude = 8,
        proc = {effect='firedamage', magnitude=2, duration=3, cooldown=4}, description = 'Fire shield 8; hits burn for 2/s for 3s (4s cooldown)' },
    { name = 'Rimebound', epithet = 'the Rimebound', effect = 'frostshield', magnitude = 8,
        proc = {effect='frostdamage', magnitude=3, duration=2, cooldown=4}, description = 'Frost shield 8; hits deal frost 3/s for 2s (4s cooldown)' },
    { name = 'Storm-Crowned', epithet = 'the Storm-Crowned', effect = 'lightningshield', magnitude = 8,
        proc = {effect='shockdamage', magnitude=7, duration=1, cooldown=4}, description = 'Lightning shield 8; hits shock for 7 (4s cooldown)' },
    { name = 'Venom-Weaver', epithet = 'the Venom-Weaver', effect = 'fortifyattack', magnitude = 5,
        proc = {effect='poison', magnitude=3, duration=3, cooldown=5}, description = '+5 attack; hits poison for 3/s for 3s (5s cooldown)' },
    { name = 'Bone-Warded', epithet = 'the Bone-Warded', effect = 'shield', magnitude = 20,
        proc = {effect='damagefatigue', magnitude=12, duration=2, cooldown=4, retaliate=true}, description = 'Shield 20; melee attackers lose 12 fatigue/s for 2s (4s cooldown)' },
    { name = 'Huntsman', epithet = 'the Huntsman', effect = 'fortifyattribute', attribute = 'speed', magnitude = 25,
        extra = {effect='fortifyattribute', attribute='agility', magnitude=15}, description = '+25 speed and +15 agility; closes distance quickly' },
    { name = 'Oath-Wrath', epithet = 'the Oath-Wrath', effect = 'fortifyattribute', attribute = 'strength', magnitude = 20,
        proc = {effect='damagefatigue', magnitude=8, duration=2, cooldown=4}, description = '+20 strength; hits drain 8 fatigue/s for 2s (4s cooldown)' },
    { name = 'Red Hunger', epithet = 'of the Red Hunger', effect = 'fortifyattack', magnitude = 8,
        proc = {effect='absorbhealth', magnitude=3, duration=2, cooldown=5}, description = '+8 attack; hits steal 3 health/s for 2s (5s cooldown)' },
    { name = 'Hush-Woven', epithet = 'the Hush-Woven', effect = 'chameleon', magnitude = 15,
        proc = {effect='silence', magnitude=1, duration=2, cooldown=8}, description = 'Chameleon 15%; hits silence for 2s (8s cooldown)' },
    { name = 'Aether-Hungry', epithet = 'the Aether-Hungry', effect = 'spellabsorption', magnitude = 15,
        proc = {effect='absorbmagicka', magnitude=5, duration=2, cooldown=5}, description = '15% spell absorption; hits steal 5 magicka/s for 2s (5s cooldown)' },
    { name = 'Spellbreaker', epithet = 'the Spellbreaker', effect = 'reflect', magnitude = 12,
        proc = {effect='silence', magnitude=1, duration=3, cooldown=8}, description = 'Reflects 12% of spells; hits can silence for 3s (8s cooldown)' },
    { name = 'Juggernaut', epithet = 'the Juggernaut', effect = 'fortifyhealth', magnitude = 30,
        proc = {effect='burden', magnitude=20, duration=4, cooldown=6}, description = '+30 health; hits burden foes by 20 for 4s (6s cooldown)' },
    { name = 'Mist-Stalker', epithet = 'the Mist-Stalker', effect = 'chameleon', magnitude = 22,
        proc = {effect='blind', magnitude=20, duration=3, cooldown=7}, description = 'Chameleon 22%; hits blind for 3s (7s cooldown)' },
    { name = 'War-Blessed', epithet = 'the War-Blessed', effect = 'fortifyattack', magnitude = 12,
        extra = {effect='fortifyattribute', attribute='strength', magnitude=15}, description = '+12 attack and +15 strength' },
    { name = 'Void-Warded', epithet = 'the Void-Warded', effect = 'resistmagicka', magnitude = 25,
        proc = {effect='weaknesstomagicka', magnitude=20, duration=4, cooldown=7}, description = '25% magic resistance; hits expose foes to magic for 4s (7s cooldown)' },
    { name = 'Life-Drinker', epithet = 'the Life-Drinker', effect = 'fortifyhealth', magnitude = 20,
        proc = {effect='absorbhealth', magnitude=5, duration=2, cooldown=5}, description = '+20 health; hits steal 5 health/s for 2s (5s cooldown)' },
}
function M.allowedEliteIndexes()
    local indexes={}
    for index,mod in ipairs(M.elites) do
        -- Fatigue damage is deliberately omitted from new rolls; it proved
        -- difficult to notice and duplicated ordinary stamina pressure.
        if not mod.proc or mod.proc.effect~='damagefatigue' then indexes[#indexes+1]=index end
    end
    return indexes
end
-- Trophy affixes reflect the primary modifier; the other affix stays random.
M.trophies = {{prefix=1}, {prefix=2}, {prefix=3}, {prefix=4}, {suffix=1},
    {suffix=2}, {suffix=3}, {suffix=4}, {prefix=4}, {prefix=5}}
function M.elite(seed, baseName, family)
    local r = M.rng(seed)
    local tier = r() < 0.18 and 2 or 1
    local a, b = r(#M.elites), r(#M.elites - 1)
    if b >= a then b = b + 1 end
    local mods = {a}
    if tier == 2 then mods[2] = b end
    return {
        name = baseName .. ' ' .. M.elites[a].epithet, baseName = baseName,
        tier = tier, modifiers = mods, healthScale = tier == 2 and 1.8 or 1.35,
        rulesVersion = 3,
    }
end
local function affix(random, list, tier)
    local candidates = {}
    for index, value in ipairs(list) do
        if tier >= (value.minTier or 1) then candidates[#candidates + 1] = index end
    end
    return candidates[random(#candidates)]
end
function M.item(seed, level, minimum, rarityBonus, forcedTier)
    local r = M.rng(seed)
    local levelBonus=M.levelRarityBonus(level)
    local tier = forcedTier or M.rarity(r, minimum,levelBonus+(rarityBonus or 0))
    return { tier = tier, prefix = affix(r, M.prefixes, tier), suffix = affix(r, M.suffixes, tier),
        level = math.max(1,math.floor(level or 1)),
        power = math.max(2, math.min(36, 2 + math.floor(((level or 1) - 1) / 3))),
        roll = r(tier + 2), style = r(3) }
end
function M.freshRarity(mods)
    local count, peak = 0, 0
    for _, m in ipairs(mods or {}) do
        count, peak = count + 1, math.max(peak, tonumber(m.lvl) or 0)
    end
    if count >= 2 and peak >= 5 then return 5 end
    if count >= 2 and peak >= 3 then return 4 end
    return count >= 2 and 3 or 2
end
return M
