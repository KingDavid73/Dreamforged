local core,types,world=require('openmw.core'),require('openmw.types'),require('openmw.world')
local I,R,Records=require('openmw.interfaces'),require('scripts.ashenloot.rules'),require('scripts.ashenloot.records')
local Advancement=require('scripts.ashenloot.advancement')
local Narration=require('scripts.ashenloot.narration')
local Config=require('scripts.ashenloot.config')
local util=require('openmw.util')
local settings={}
function settings:set(key,value) require('openmw.storage').globalSection(Config.groupKey(key)):set(key,value) end
local elapsed,stage,loaded=0,0,false
local rat,npc,ids,levelBefore,remixReady,mythicItems={},nil,{},nil,false,{}
local function pass(s) print('[AshenLoot V4] PASS: '..s) end
local function check(c,s) assert(c,s) end
local function update(dt)
    elapsed=elapsed+dt
    local ok,err=pcall(function()
        local p=world.players[1]
        if not p then return end
        if stage==0 and elapsed>2 then
            stage=1
            local lineCount=0
            for _,pool in pairs(Narration.lines) do lineCount=lineCount+#pool end
            check(lineCount==78,'Director voice template count changed unexpectedly')
            local rendered=Narration.render('boss','test',{enemy='Ash Vampire'},nil)
            check(rendered and rendered.text:find('Ash Vampire',1,true),'Director voice failed ad-lib substitution')
            local heard={}
            local listener={isValid=function() return true end,
                sendEvent=function(_,name,payload) heard[#heard+1]={name=name,payload=payload} end}
            local voiceState={}
            check(not Narration.emit(voiceState,{enabled=true,directorVoiceFrequency=0},listener,100,'boss',
                {enemy='Ash Vampire'},true),'Voice frequency 0 did not disable captions')
            check(Narration.emit(voiceState,{enabled=true,directorVoiceFrequency=60},listener,100,'boss',
                {enemy='Ash Vampire'},true),'Priority boss caption did not dispatch')
            check(#heard==1 and heard[1].name=='AshenLoot_DirectorVoice','Director voice event missing')
            check(not Narration.emit(voiceState,{enabled=true,directorVoiceFrequency=60},listener,101,'boss',
                {enemy='Ash Vampire'},true),'Director voice cooldown did not apply')
            p:sendEvent('AshenLoot_DirectorVoice',{speaker='The Dream',
                text='A test voice rises from the ash.',duration=3})
            pass('director voice templates, ad-libs, off setting and cooldown')
            p:sendEvent('AshenLoot_TestFreezeAI')
            settings:set('extraEncounters',false)
            settings:set('creatureVariety',0)
            for _,level in ipairs({1,10,30,60}) do
                for tier=1,6 do
                    for _,entry in ipairs({{types.Weapon,'iron longsword'},{types.Weapon,'wooden staff'},
                        {types.Weapon,'chitin short bow'},{types.Armor,'iron_cuirass'},{types.Clothing,'common_ring_01'}}) do
                        local base=entry[1].record(entry[2])
                        check(base,'Missing fixture '..entry[2])
                        local spec=R.item('v4:'..level..':'..tier,level,tier)
                        spec.tier=tier
                        local id,meta=Records.makeItem(base,entry[1],spec)
                        ids[#ids+1]=id
                        local rec=entry[1].record(id)
                        if tier==1 then check(not rec.enchant,'Common item received an enchantment')
                        else
                            local enchant=core.magic.enchantments.records[rec.enchant]
                            local usePrefix=tier>=3 or spec.roll%2==1;local useSuffix=tier>=3 or not usePrefix
                            local expected=(usePrefix and not (entry[1]==types.Weapon and R.prefixes[spec.prefix].nativeWeapon==false)) and 1 or 0
                            if useSuffix and R.suffixes[spec.suffix].effect then expected=expected+1 end
                            if tier>=4 then expected=expected+1 end;if tier>=5 then expected=expected+1 end;if tier>=6 then expected=expected+2 end
                            check(#enchant.effects==expected,'Native affix count')
                            if entry[1]==types.Weapon then check(enchant.charge==10000 and enchant.cost==1,'Charge model') end
                            if entry[2]=='wooden staff' then check(enchant.type==core.magic.ENCHANTMENT_TYPE.CastOnUse,'Staff casting') end
                        end
                    end
                end
            end
            check(R.item('same',30,1).power>R.item('same',1,1).power,'Level progression')
            check(I.AshenLoot.progression.test.gearHealthScale(3,3)==1,'On-level gear changed health')
            check(I.AshenLoot.progression.test.gearHealthScale(13,3)==2,'Overgear durability response')
            check(I.AshenLoot.progression.test.gearHealthScale(50,3)==3,'Overgear durability cap')
            check(I.AshenLoot.progression.test.prestigeScale(100)==1,'Prestige changed level-100 baseline')
            check(I.AshenLoot.progression.test.prestigeScale(500)==5,'Level-500 prestige multiplier')
            check(I.AshenLoot.progression.test.encounterTarget(50,500,0,true,true)>=496,'Uncapped generated encounter level')
            local budgetExamples={[0]=1.1,[1]=8.5,[2]=22,[3]=45,[4]=90}
            local budgetCounts={}
            for rank=0,4 do
                local profile=R.lootBudgetProfiles[rank];budgetCounts[rank]={0,0,0,0,0,0,0}
                for sample=1,1000 do
                    local tiers=R.lootBudgetPlan(R.rng('budget-plan:'..rank..':'..sample),rank,budgetExamples[rank],20)
                    check(#tiers>=profile.min and #tiers<=profile.max,'Loot package size escaped rank bounds: rank='..rank..' sample='..sample..' size='..#tiers)
                    local low=0
                    for _,tier in ipairs(tiers) do
                        check(tier>=1 and tier<=7,'Invalid planned loot tier')
                        budgetCounts[rank][tier]=budgetCounts[rank][tier]+1
                        if tier<profile.floor then low=low+1 end
                    end
                    check(low<=profile.lowCap,'Loot package escaped low-tier cap')
                end
            end
            check(budgetCounts[0][1]>900,'Ordinary budget stopped favoring single Common equipment')
            check(budgetCounts[4][1]==0 and budgetCounts[4][2]==0 and budgetCounts[4][3]==0 and budgetCounts[4][4]==0,
                'World Boss budget bought low-tier filler')
            check(budgetCounts[4][7]>=150 and budgetCounts[4][7]<=250,'World Boss Mythic roll escaped expected range')
            local moods={saving=0,steady=0,spree=0};local spent=0;local directorRng=R.rng('reward-director-sequence')
            for sample=1,1000 do
                local amount,mood=R.lootDirectorSpend(directorRng,100,60,3,1,15)
                check(amount>=0 and amount<=100,'Reward director overspent its reserve')
                moods[mood]=moods[mood]+1;spent=spent+amount
            end
            check(moods.saving>100 and moods.steady>100 and moods.spree>50 and spent>5000,
                string.format('Reward director variation saving=%d steady=%d spree=%d spent=%.1f',moods.saving,moods.steady,moods.spree,spent))
            print(string.format('[AshenLoot V4] budget samples: normal C=%d; champion U+=%d; elite R+=%d; unique E+=%d; boss L=%d Rl=%d M=%d',
                budgetCounts[0][1],budgetCounts[1][2]+budgetCounts[1][3]+budgetCounts[1][4]+budgetCounts[1][5]+budgetCounts[1][6],
                budgetCounts[2][3]+budgetCounts[2][4]+budgetCounts[2][5]+budgetCounts[2][6],
                budgetCounts[3][4]+budgetCounts[3][5]+budgetCounts[3][6],budgetCounts[4][5],budgetCounts[4][6],budgetCounts[4][7]))
            pass('bounded loot packages plus frugal, steady and spree director spending preserve paced reward variation')
            local capSpec=R.item('damage-cap',3,6);capSpec.tier=6;capSpec.style=3
            local capId=Records.makeItem(types.Weapon.record('daedric battle axe'),types.Weapon,capSpec)
            ids[#ids+1]=capId
            local capped=types.Weapon.record(capId)
            check(math.max(capped.chopMaxDamage,capped.slashMaxDamage,capped.thrustMaxDamage)<=80,
                'Low-level Relic weapon escaped charged-damage cap')
            pass('120 item/level/rarity combinations, Common through Relic effects, staff and bow casting, charge')
            local forcedArmor=I.AshenLoot.test.giveLoot(p,'v4-forced-armor',3,'iron_cuirass',3,nil,types.Actor.inventory(p))
            check(forcedArmor and types.Armor.record(forcedArmor),'Forced armor reward failed typed record lookup')
            pass('forced weapon/armor reward bases survive typed record probing')
            local artifact=types.Weapon.record('daedric_crescent_unique') or types.Weapon.record('umbra sword')
            check(artifact,'Missing curated artifact fixture')
            local relicSpec=R.item('relic',30,6);relicSpec.tier=6
            local relicId,relicMeta=Records.makeItem(artifact,types.Weapon,relicSpec)
            ids[#ids+1]=relicId
            check(relicMeta.tier==6 and #core.magic.enchantments.records[types.Weapon.record(relicId).enchant].effects>=6,
                'Relic tier and expanded enchantment')
            pass('boss-only Relic preserves an iconic artifact template with expanded effects')
            I.AshenLoot.test.ensureSpellTomes()
            local tomeCount=0
            for _,tome in pairs(I.AshenLoot.getState().spellTomes) do
                check(core.magic.spells.records[tome.spell] and types.Book.record(tome.book),'Invalid spell tome records')
                tomeCount=tomeCount+1
            end
            check(tomeCount==24,'Curated spell tome count: '..tomeCount)
            pass('24 tiered permanent spell tomes create valid spell and book records')
            local learnedTome=I.AshenLoot.getState().spellTomes.ember_dart
            world.createObject(learnedTome.book,1):moveInto(types.Actor.inventory(p))
            local tomeObject=types.Actor.inventory(p):findAll(learnedTome.book)[1]
            I.AshenLoot.test.learnSpellTome(tomeObject,p)
            local remaining=types.Actor.inventory(p):countOf(learnedTome.book)
            check(remaining==0,'Spell tome was not consumed: remaining='..remaining)
            check(core.magic.spells.records[learnedTome.spell],'Learned spell record disappeared')
            pass('spell tome pickup/use backend queues the permanent spell and consumes the book')
            local bossNames={}
            for n=1,18 do bossNames[R.worldBossName('boss-name-'..n,'Rat','beast')]=true end
            local bossNameCount=0;for _ in pairs(bossNames) do bossNameCount=bossNameCount+1 end
            check(bossNameCount>=8,'World boss name diversity')
            check(R.worldBossName('mudcrab-name','Mudcrab','beast'):find(' ',1,true),'Lore-styled boss name')
            pass('per-creature given names and expanded lore-styled boss epithets')
            local npcBossNames={}
            for n=1,20 do
                local name=R.worldBossNpcName('npc-name-'..n,'Fargoth','bosmer','stealth')
                check(name:find('Fargoth',1,true),'NPC world boss lost authored name')
                npcBossNames[name]=true
            end
            local npcNameCount=0;for _ in pairs(npcBossNames) do npcNameCount=npcNameCount+1 end
            check(npcNameCount>=8,'NPC world boss title diversity')
            pass('NPC world bosses preserve authored names with race/specialization titles')
            local uniqueBio=R.biography('unique-lore',{family='undead',modifiers={2,10},worldBoss=false})
            local bossFullName=R.worldBossName('boss-lore','Rat','beast')
            local bossBio=R.biography('boss-lore',{name=bossFullName,family='beast',modifiers={1,6},worldBoss=true})
            check(#uniqueBio>120 and #bossBio>100,'Generated promoted biography too short')
            check(uniqueBio==R.biography('unique-lore',{family='undead',modifiers={2,10},worldBoss=false}),
                'Unique biography is not deterministic')
            pass('Unique templates and title-aware World Boss histories produce stable corpse lore')
            local milestoneSkills={};for skill in pairs(Advancement.skills) do milestoneSkills[skill]=100 end
            I.AshenLoot.test.reconcileAdvancement({player=p,level=50,specialty='magic',skills=milestoneSkills})
            local advancementCount=0;for _ in pairs(I.AshenLoot.getState().advancementRecords) do advancementCount=advancementCount+1 end
            check(advancementCount>=115,'Skill/specialty milestone catalog incomplete: '..advancementCount)
            check(#Advancement.activeLevels==4,'Specialty active milestones')
            local skillActiveCount=0;for _ in pairs(Advancement.skillActives) do skillActiveCount=skillActiveCount+1 end
            check(skillActiveCount==27,'Every skill must expose a signature active')
            I.AshenLoot.test.useAdvancement({player=p,id='aetherial_mastery'})
            check(I.AshenLoot.getState().advancementUses.aetherial_mastery
                and #I.AshenLoot.getState().advancementUses.aetherial_mastery==1,'Realtime cooldown activation')
            I.AshenLoot.test.useAdvancement({player=p,id='aetherial_mastery'})
            check(#I.AshenLoot.getState().advancementUses.aetherial_mastery==1,'Realtime cooldown rejection')
            for n=1,4 do I.AshenLoot.test.useAdvancement({player=p,id='arcane_surge'}) end
            check(#I.AshenLoot.getState().advancementUses.arcane_surge==3,'Three recovering game-time charges')
            pass('all skills award 50/75/100 passives and a signature active; ten specialty milestones are defined')
            for _,def in ipairs(I.AshenLoot.test.mythicDefinitions) do
                local kind=def.kind=='armor' and types.Armor or (def.kind=='clothing' and types.Clothing or types.Weapon)
                local base=kind.record(def.base) or (kind==types.Weapon and kind.record('wooden staff'))
                check(base,'Missing mythic base '..def.id)
                local id,meta=Records.makeMythic(base,kind,def);ids[#ids+1]=id
                I.AshenLoot.getState().records[id]=meta;mythicItems[def.id]=world.createObject(id,1)
                mythicItems[def.id]:moveInto(types.Actor.inventory(p))
                check(meta.mythic==def.id and meta.tier==6,'Mythic metadata '..def.id)
            end
            pass('ten mythic staves and four absurd mythic wearables create valid records')
            for index=7,#R.prefixes do
                local spec=R.item('new-prefix:'..index,30,2);spec.prefix=index;spec.suffix=1
                local id=Records.makeItem(types.Weapon.record('iron longsword'),types.Weapon,spec)
                ids[#ids+1]=id
            end
            for index=9,#R.suffixes do
                local spec=R.item('new-suffix:'..index,30,2);spec.prefix=1;spec.suffix=index
                local id=Records.makeItem(types.Armor.record('iron_cuirass'),types.Armor,spec)
                ids[#ids+1]=id
            end
            local procSeen={}
            for pre,def in ipairs(R.prefixes) do
                if def.weaponProc then
                    local spec=R.item('proc-prefix:'..pre,30,4);spec.prefix=pre;spec.suffix=1
                    local _,meta=Records.makeItem(types.Weapon.record('iron longsword'),types.Weapon,spec)
                    for _,proc in ipairs(meta.procs) do procSeen[proc.id]=true end
                end
            end
            for suffix,def in ipairs(R.suffixes) do
                local spec=R.item('proc-suffix:'..suffix,30,4);spec.prefix=1;spec.suffix=suffix
                for _,kind in ipairs({types.Weapon,types.Armor}) do
                    local base=kind==types.Weapon and kind.record('iron longsword') or kind.record('iron_cuirass')
                    local _,meta=Records.makeItem(base,kind,spec)
                    for _,proc in ipairs(meta.procs) do procSeen[proc.id]=true end
                end
            end
            for id in pairs(R.itemProcs) do check(procSeen[id],'Defined item proc not reachable: '..id) end
            pass('open wounds, paralysis, Command, thorns, spell echoes, crushing blows and chain lightning are reachable')
            for index=11,#R.elites do
                check(Records.ability({name='Effect test',modifiers={index},effectScale=1}),'Elite ability record')
                if R.elites[index].proc then check(Records.proc(index,1),'Elite proc record') end
            end
            local allowed={};for _,index in ipairs(R.allowedEliteIndexes()) do allowed[index]=true end
            check(not allowed[5] and not allowed[7],'Fatigue modifiers entered new rolls')
            for _,index in ipairs({1,2,3,4,6,8,9,10,11,12,13,14,15,16}) do
                check(allowed[index],'Defined enemy modifier not selectable: '..index)
            end
            pass('all 14 non-fatigue enemy modifiers are selectable and have working records')
            local cliff=world.createObject('cliff racer',1)
            local chosen=I.AshenLoot.progression.test.pickCreature(cliff,5,R.rng('cliff-filter'),true)
            check(not chosen:lower():find('cliff racer',1,true),'Additional cliff racer filter')
            settings:set('creaturePoolMode','Random')
            chosen=I.AshenLoot.progression.test.pickCreature(cliff,5,R.rng('random-pool'),true)
            check(chosen and not chosen:lower():find('cliff racer',1,true),'Random full loaded pool')
            local randomCreatures={}
            local loadedRng=R.rng('random-loaded-catalog');for n=1,250 do
                randomCreatures[I.AshenLoot.progression.test.pickCreature(cliff,1,loadedRng,true)]=true end
            local randomCount=0;for id in pairs(randomCreatures) do
                randomCount=randomCount+1
                local rec=types.Creature.record(id)
                check(rec and (rec.canWalk or rec.canFly) and not (rec.canSwim and not rec.canWalk and not rec.canFly),'Unsafe random creature')
                check(I.AshenLoot.progression.test.safeRecord(rec),'One-off or quest creature entered random pool: '..id)
            end
            check(randomCount>=20,'Random mode is still using a narrow catalog: '..randomCount)
            check(I.AshenLoot.progression.test.encounterTarget(50,1,0,true,false)<=11,'Natural high-level creature escaped level band')
            check(I.AshenLoot.progression.test.encounterTarget(50,1,0,true,true)==1,'Random addition did not normalize to player')
            local categories={};local containerRng=R.rng('broad-container-categories')
            for n=1,300 do
                local entry=I.AshenLoot.progression.test.randomBroadBase(12,containerRng)
                if entry then categories[tostring(entry.kind)]=true end
            end
            local categoryCount=0;for _ in pairs(categories) do categoryCount=categoryCount+1 end
            check(categoryCount>=5,'Container remix is still restricted to narrow item categories')
            if types.Miscellaneous then
                check(categories[tostring(types.Miscellaneous)],'Curated gems/valuables category is absent')
            end
            local tiers={};local tierRng=R.rng('container-gradient-tiers')
            local bonemeal=types.Ingredient.record('ingred_bonemeal_01')
            for n=1,1000 do
                local _,tier=I.AshenLoot.progression.test.randomContainerBase(
                    types.Ingredient,bonemeal,30,tierRng,true,80)
                tiers[tier]=true
            end
            check(tiers.ordinary and tiers.valuable and tiers.enchanted,
                'Locked chest did not expose all three native loot-gradient tiers')
            local looseTiers={};local looseRng=R.rng('loose-item-gradient')
            local ironSword=types.Weapon.record('iron longsword')
            for n=1,1000 do
                local replacement,tier=I.AshenLoot.progression.test.randomLooseBase(
                    types.Weapon,ironSword,30,looseRng)
                if replacement then looseTiers[tier]=true end
            end
            check(looseTiers.ordinary and looseTiers.valuable and looseTiers.enchanted and looseTiers.ashen,
                'Loose dungeon item gradient did not expose all four tiers')
            local normalAshen,normalEnchanted=I.AshenLoot.progression.test.npcGearChances({})
            local eliteAshen,eliteEnchanted=I.AshenLoot.progression.test.npcGearChances({rank=2})
            local worldAshen=I.AshenLoot.progression.test.npcGearChances({rank=3,worldBoss=true})
            check(normalAshen==5 and normalEnchanted==12,'Default ordinary NPC gear gradient')
            check(eliteAshen==17 and eliteEnchanted==22,'Elite NPC gear gradient')
            check(worldAshen==35,'World-boss NPC gear gradient')
            settings:set('creaturePoolMode','Similar')
            local fish=world.createObject('slaughterfish',1)
            chosen=I.AshenLoot.progression.test.pickCreature(fish,5,R.rng('fish-land-pack'),true)
            local land=types.Creature.record(chosen)
            check(land and land.canWalk and not land.canSwim and not land.canFly,'Swimming anchor produced non-land reinforcement')
            fish:remove()
            cliff:remove()
            pass('container value gradient/categories, creature modes, level band, cliff filter, and land-only swimming-anchor packs')
            local unsafeNpc,unsafeNpcRecord
            for _,candidate in ipairs(world.activeActors) do
                local rec=types.NPC.objectIsInstance(candidate) and types.NPC.record(candidate)
                local service=false;for _,v in pairs(rec and rec.servicesOffered or {}) do if v then service=true end end
                if rec and not types.Player.objectIsInstance(candidate) and (rec.mwscript or rec.isEssential or service) then
                    unsafeNpc,unsafeNpcRecord=candidate,rec;break
                end
            end
            check(unsafeNpcRecord,'Unsafe NPC fixture')
            settings:set('unsafeContent',false)
            check(not I.AshenLoot.eligible(unsafeNpc),'Protected NPC admitted in safe mode')
            local artifactRecord=types.Weapon.record('keening') or types.Weapon.record('umbra sword')
            check(artifactRecord,'Unsafe artifact fixture')
            check(not I.AshenLoot.progression.test.safeInventoryRecord(types.Weapon,artifactRecord),'Artifact admitted in safe mode')
            settings:set('unsafeContent',true);I.AshenLoot.test.refreshContentPools()
            check(I.AshenLoot.eligible(unsafeNpc),'Protected NPC excluded in unsafe mode; unsafe='..tostring(Config.unsafeContent)
                ..', npcProgression='..tostring(Config.npcProgression)..', enabled='..tostring(unsafeNpc.enabled)
                ..', scale='..tostring(unsafeNpc.scale)..', npc='..tostring(types.NPC.objectIsInstance(unsafeNpc)))
            check(not I.AshenLoot.progression.test.populationAnchor(unsafeNpc),
                'Unsafe-only NPC became a reinforcement anchor')
            check(I.AshenLoot.progression.test.safeInventoryRecord(types.Weapon,artifactRecord),'Artifact excluded in unsafe mode')
            local foundArtifact=false
            for _,entry in ipairs(I.AshenLoot.test.getPool()) do if entry.id==artifactRecord.id then foundArtifact=true;break end end
            check(foundArtifact,'Unsafe artifact missing from procedural base pool')
            settings:set('unsafeContent',false);I.AshenLoot.test.refreshContentPools()
            pass('unsafe chaos appends protected NPC and artifact records only while enabled')
            for _,kind in ipairs({'health','fatigue','magicka','scroll'}) do
                for _,level in ipairs({1,30,60}) do
                    local id=I.AshenLoot.progression.test.supplyRecord(level,kind,true)
                    check(id,'Supply record '..kind)
                    world.createObject(id,1):moveInto(types.Actor.inventory(p))
                    ids[#ids+1]=id
                end
            end
            local scrollNames={}
            for variant=1,6 do
                local id=I.AshenLoot.progression.test.supplyRecord(20,'scroll',variant%2==0,variant)
                local rec=types.Book.record(id);check(rec and rec.isScroll,'Mage scroll variant '..variant)
                scrollNames[rec.name]=true;ids[#ids+1]=id
            end
            local scrollCount=0;for _ in pairs(scrollNames) do scrollCount=scrollCount+1 end
            check(scrollCount==6,'Curated scroll recipes collapsed to duplicate records')
            local minorHealth=types.Potion.record(I.AshenLoot.progression.test.supplyRecord(1,'health',false))
            local superHealth=types.Potion.record(I.AshenLoot.progression.test.supplyRecord(100,'health',false))
            local mana=types.Potion.record(I.AshenLoot.progression.test.supplyRecord(30,'magicka',false))
            check(minorHealth.name=='Minor Healing Potion' and superHealth.name=='Super Healing Potion',
                'Diablo-style healing potion names')
            check(mana.name=='Mana Potion','Diablo-style mana potion name')
            check(minorHealth.icon=='icons/m/tx_potion_exclusive_01.dds'
                and mana.icon=='icons/m/tx_potion_quality_01.dds','Recovery potion color language')
            pass('12 level-scaled multi-effect potion/scroll records')
            for _,class in ipairs({'al_warrior','al_warmage','al_archer','al_rogue','al_conjurer'}) do
                I.AshenLoot.test.startingKit({player=p,class=class})
            end
            for n=1,4 do
                rat[n]=world.createObject('rat',1)
                rat[n]:teleport(p.cell,p.position+util.vector3(300+n*100,0,0))
                rat[n]:addScript('scripts/ashenloot_test/actor.lua')
            end
            local peaceful=world.createObject('scrib',1)
            peaceful:teleport(p.cell,p.position+util.vector3(850,0,0))
            check(not I.AshenLoot.progression.test.isAggressive(peaceful),'Peaceful actor boss eligibility')
            check(I.AshenLoot.progression.test.isAggressive(rat[1]),'Hostile actor boss eligibility')
            local ogrim=world.createObject('ogrim',1)
            ogrim:teleport(p.cell,p.position+util.vector3(900,0,0))
            local smallScale=I.AshenLoot.progression.test.worldBossScale(rat[1])
            local largeScale=I.AshenLoot.progression.test.worldBossScale(ogrim)
            check(smallScale>largeScale and largeScale<=1.15,'Interior size-aware boss scaling')
            pass('aggressive-only boss eligibility and interior size-aware scaling')
            for _,rec in pairs(types.NPC.records) do
                local service=false
                for _,v in pairs(rec.servicesOffered or {}) do if v then service=true end end
                if rec.id~='player' and not rec.mwscript and not rec.isEssential and not service then
                    npc=world.createObject(rec.id,1)
                    if not types.Actor.isDead(npc) then
                        npc:teleport(p.cell,p.position+util.vector3(600,200,0))
                        break
                    else npc:remove();npc=nil end
                end
            end
            check(npc,'NPC fixture')
            npc:addScript('scripts/ashenloot_test/actor.lua')
            local sword=world.createObject('iron longsword',1)
            local armor=world.createObject('iron_cuirass',1)
            sword:moveInto(types.Actor.inventory(npc));armor:moveInto(types.Actor.inventory(npc))
            npc:sendEvent('AshenLoot_TestEquip',{weapon=sword,armor=armor})
            local carried=world.createObject('steel dagger',2)
            carried:moveInto(types.Actor.inventory(p))
            remixReady=true
        elseif stage==1 and elapsed>4 then
            stage=2
            local kitItems={}
            for _,item in ipairs(types.Actor.inventory(p):getAll()) do kitItems[item.recordId]=true end
            for _,id in ipairs({'iron_shield','steel mace','chitin short bow','pick_apprentice_01','steel staff'}) do
                check(kitItems[id],'Starting kit item '..id)
            end
            for _,spell in ipairs({'fire bite','hearth heal','Shield','bound mace','summon ancestral ghost',
                'bound dagger','Chameleon','detect_creature','water walking'}) do
                check(types.Actor.spells(p)[spell],'Starting spell '..spell)
            end
            pass('five starter kits and two caster spellbooks')
            local remixCount=I.AshenLoot.getState().count
            I.AshenLoot.progression.test.randomizeInventory(p,types.Actor.inventory(p),20,'inventory-remix-test',false)
            check(I.AshenLoot.getState().count>remixCount,'Broad inventory remix created affixed replacement gear')
            pass('broad inventory remix plus Ashen affix layer')
            for n=1,3 do I.AshenLoot.test.encounter({actor=rat[n],force=true,rank=n,gearPressure=3}) end
            I.AshenLoot.test.encounter({actor=rat[4],force=true,rank=3,worldBoss=true,gearPressure=3})
            I.AshenLoot.progression.prepare(npc)
            I.AshenLoot.test.snapshot()
            p:sendEvent('AshenLoot_TestUI')
        elseif stage==2 and elapsed>12 then
            stage=3
            local state=I.AshenLoot.getState()
            for n=1,3 do
                local e=state.elites[rat[n].id]
                check(e.rank==n and #e.modifiers==n,'Promotion ranks')
                check(types.Actor.spells(rat[n])[e.spellId],'Promotion ability')
            end
            local wb=state.elites[rat[4].id]
            check(wb.worldBoss and #wb.modifiers==6 and wb.healthScale==4.5,'World boss bounded base durability profile')
            if not types.Actor.spells(rat[4])[wb.spellId] then
                print('[AshenLoot V4] DIAG boss spell missing id='..tostring(wb.spellId)
                    ..' dead='..tostring(types.Actor.isDead(rat[4]))
                    ..' valid='..tostring(rat[4]:isValid())
                    ..' record='..tostring(rat[4].recordId))
            end
            check(types.Actor.spells(rat[4])[wb.spellId],'World boss ability')
            I.AshenLoot.test.mythicImpact(mythicItems.wild_friend,p,rat[1])
            check(next(state.mythicSummons),'Friendly random-creature mythic staff')
            check(state.director.actors[npc.id],'NPC progression')
            local eq=types.Actor.getEquipment(npc)
            local weapon=eq[types.Actor.EQUIPMENT_SLOT.CarriedRight]
            local cuirass=eq[types.Actor.EQUIPMENT_SLOT.Cuirass]
            check(weapon and weapon.recordId~='iron longsword','NPC weapon was not remixed')
            check(cuirass and cuirass.recordId~='iron_cuirass','NPC armor was not remixed')
            local old=false
            for _,found in ipairs(types.Actor.inventory(npc):getAll()) do
                if found.recordId=='iron longsword' or found.recordId=='iron_cuirass' then old=true end
            end
            check(not old,'Replaced native loadout was duplicated on the NPC corpse')
            local count=state.count
            I.AshenLoot.progression.prepare(npc)
            check(count==state.count,'NPC repeated loadout')
            settings:set('healingPercent',100)
            settings:set('groundDrops',true)
            rat[1]:sendEvent('AshenLoot_TestKill')
            pass('three ranks, NPC progression/loadout, repeated processing stable')
        elseif stage==3 and elapsed>15 then
            stage=4
            local state=I.AshenLoot.getState()
            check(state.rewards[rat[1].id],'Death reward')
            local healed=false
            for _,item in ipairs(types.Actor.inventory(rat[1]):getAll()) do if types.Potion.objectIsInstance(item) then healed=true end end
            check(healed,'Creature healing drop')
            local _,loose=next(state.director.loose)
            check(loose and loose.item,'Ground reward')
            check((loose.item.position-rat[1].position):length()>80,'Ground reward remained inside corpse')
            local before=#types.Actor.inventory(rat[1]):getAll()
            I.AshenLoot.test.death(rat[1])
            check(before==#types.Actor.inventory(rat[1]):getAll(),'Duplicate drops')
            pass('creature potion loot, ground equipment reward, death deduplication')
            types.Player.sendMenuEvent(p,'AshenLoot_TestSave')
        elseif stage==4 and loaded and elapsed>14 then
            stage=5
            local state=I.AshenLoot.getState()
            check(state.rewards[rat[1].id] and state.director.actors[npc.id],'Saved progression')
            for _,id in ipairs(ids) do
                check(types.Weapon.record(id) or types.Armor.record(id) or types.Clothing.record(id)
                    or types.Potion.record(id) or types.Book.record(id),'Saved dynamic record')
            end
            check(state.elites[rat[3].id].rank==3,'Unique saved')
            check(state.elites[rat[4].id].worldBoss,'World boss saved')
            pass('save/reload preserved gear, supplies, three ranks, world boss and director state')
            core.quit()
        elseif elapsed>40 then error('Timed out') end
    end)
    if not ok then print('[AshenLoot V4] FAIL: '..tostring(err));core.quit() end
end
return {engineHandlers={onUpdate=update,onSave=function() return {elapsed=elapsed,stage=stage,rat=rat,npc=npc,ids=ids} end,
    onLoad=function(d) elapsed,stage,rat,npc,ids=d.elapsed,d.stage,d.rat,d.npc,d.ids;loaded=true end},
    eventHandlers={AshenLoot_TestUIResult=function(d) check(d.ok,d.error);pass('loot browser UI') end}}
