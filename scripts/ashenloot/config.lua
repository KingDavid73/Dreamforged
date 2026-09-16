local storage = require('openmw.storage')
local groupKeys={
    reset='SettingsDreamforgedReset',scaling='SettingsDreamforgedScaling',encounters='SettingsDreamforgedEncounters',
    dungeons='SettingsDreamforgedDungeons',bosses='SettingsDreamforgedBosses',
    loot='SettingsDreamforgedLoot',npcs='SettingsDreamforgedNPCs',interface='SettingsDreamforgedInterface'}
local keyGroups={}
for _,key in ipairs({'resetAllSettings'}) do keyGroups[key]=groupKeys.reset end
for _,key in ipairs({'progression','levelScaling','gearLevelInfluence','enemyHealth','enemyDamage','encounterLevelBelow','encounterLevelAbove'}) do keyGroups[key]=groupKeys.scaling end
for _,key in ipairs({'creatureVariety','creaturePoolMode','extraEncounters','directorIntensity','encounterDensity','excludeExtraCliffRacers','exteriorBudget','outdoorDirectorInterval','outdoorDirectorChance','outdoorPressureGain','creatureDenChance','creatureDenWaveInterval','creatureDenMinCycles','creatureDenMaxCycles','exteriorTriggerMin','exteriorTriggerRange','exteriorAnchorChance','exteriorGroupMin','exteriorGroupMax','exteriorSpawnMin','exteriorSpread','settlementSuppression','rerunnableWilderness','wildernessResetHours'}) do keyGroups[key]=groupKeys.encounters end
for _,key in ipairs({'interiorBudget','rerunnableDungeons','dungeonResetHours','dungeonBosses'}) do keyGroups[key]=groupKeys.dungeons end
for _,key in ipairs({'worldBosses','worldBossCadenceMinutes','worldBossChance','worldBossCellCap','uniquePercent','eliteTierPercent','worldBossAddInitialDelay','worldBossAddInterval','worldBossAddMin','worldBossAddMax','worldBossAddCap','worldBossMinLevel','worldBossRange','worldBossSpawnMinDistance','worldBossDistanceHide'}) do keyGroups[key]=groupKeys.bosses end
for _,key in ipairs({'healingPercent','supplyPercent','ammunitionPercent','spellTomePercent','adaptiveLootDirector','lootDirectorStrength','lootDirectorReserve','lootDirectorSpreeChance','supplyContainers','randomizeContainers','containerLootPercent','randomizeLooseDungeonItems','looseDungeonItemPercent','groundDrops','groundGlow','autoSalvageCommon','autoSalvageUncommon','autoSalvageRare','autoSalvageEpic','autoSalvageLegendary','autoSalvageRelic'}) do keyGroups[key]=groupKeys.loot end
for _,key in ipairs({'npcProgression','randomizeNpcInventories','npcInventoryPercent','npcAshenGearPercent','guardProgression','guardPower','scavenge','civilianDefense'}) do keyGroups[key]=groupKeys.npcs end
for _,key in ipairs({'showTargetCard','inventoryKey','forgeKey','abilityControllerModifier','abilityControllerCycle','abilityControllerUse'}) do keyGroups[key]=groupKeys.interface end
local function groupKey(key) return keyGroups[key] or 'SettingsAshenLoot' end
local defaults = {
    enabled = true, preset = 'Crawler', elitePercent = 25, dropPercent = 35, resetAllSettings = false,
    settleSeconds = 2, protectQuestActors = true, allowRespawningNPCs = false, unsafeContent = false,
    showTargetCard = true, inventoryKey = 'F8', forgeKey = 'F7', pageSize = 4, maxGeneratedItems = 2000,
    abilityControllerModifier = 'RightShoulder', abilityControllerCycle = 'DPadLeft',
    abilityControllerUse = 'DPadRight',
    progression = true, levelScaling = 0.6, gearLevelInfluence = 0.5, enemyHealth = 1, enemyDamage = 1,
    npcProgression = true, creatureVariety = 50, extraEncounters = true,
    directorIntensity = 1, exteriorBudget = 6, outdoorDirectorInterval = 5, outdoorDirectorChance = 35,
    outdoorPressureGain = 15,
    creatureDenChance = 12, creatureDenWaveInterval = 18, creatureDenMinCycles = 1, creatureDenMaxCycles = 3,
    exteriorTriggerMin = 300, exteriorTriggerRange = 2200, exteriorAnchorChance = 65,
    exteriorGroupMin = 2, exteriorGroupMax = 4, exteriorSpawnMin = 1200,
    interiorBudget = 3, uniquePercent = 5, eliteTierPercent = 25, dungeonBosses = true,
    settlementSuppression = true, guardProgression = true, guardPower = 1.35,
    healingPercent = 65, supplyPercent = 25, ammunitionPercent = 15, spellTomePercent = 25, groundDrops = true,
    adaptiveLootDirector = true, lootDirectorStrength = 1, lootDirectorReserve = 150, lootDirectorSpreeChance = 15,
    scavenge = true, civilianDefense = true,
    supplyContainers = true,
    exteriorSpread = 2200,
    encounterDensity = 1.5,
    groundGlow = true, excludeExtraCliffRacers = true, creaturePoolMode = 'Similar',
    randomizeContainers = true, containerLootPercent = 30,
    randomizeLooseDungeonItems = true, looseDungeonItemPercent = 15,
    autoSalvageCommon = false, autoSalvageUncommon = false, autoSalvageRare = false, autoSalvageEpic = false,
    autoSalvageLegendary = false, autoSalvageRelic = false,
    randomizeNpcInventories = true, npcInventoryPercent = 45, npcAshenGearPercent = 5,
    worldBosses = true, worldBossCadenceMinutes = 10, worldBossChance = 3, worldBossCellCap = 1, worldBossMinLevel = 5, worldBossRange = 5000,
    worldBossSpawnMinDistance = 1200, worldBossDistanceHide = 900,
    worldBossAddInitialDelay = 20, worldBossAddInterval = 30,
    worldBossAddMin = 1, worldBossAddMax = 3, worldBossAddCap = 6,
    encounterLevelBelow = 4, encounterLevelAbove = 10,
    rerunnableDungeons = true, dungeonResetHours = 72,
    rerunnableWilderness = true, wildernessResetHours = 72,
}
local function get(key)
    local value = storage.globalSection(groupKey(key)):get(key)
    if value == nil then return defaults[key] end
    return value
end
return setmetatable({defaults = defaults,groupKey=groupKey,groups=groupKeys,keyGroups=keyGroups}, {__index = function(_, key)
    if key == 'eliteChance' or key == 'normalDropChance' then
        local preset = get('preset')
        if preset == 'Testing' then return key == 'eliteChance' and 0.5 or 1 end
        if preset == 'Balanced' then return key == 'eliteChance' and 0.16 or 0.12 end
        if preset == 'Crawler' then return key == 'eliteChance' and 0.25 or 0.35 end
        local percent = tonumber(get(key == 'eliteChance' and 'elitePercent' or 'dropPercent')) or 0
        return math.max(0, math.min(100, percent)) / 100
    end
    if key == 'settleSeconds' then return math.max(0.5, math.min(10, tonumber(get(key)) or 2)) end
    local bounds = {levelScaling={0,2}, gearLevelInfluence={0,1}, enemyHealth={0.25,3}, enemyDamage={0.25,3}, encounterDensity={0.5,3},guardPower={1,2.5},
        directorIntensity={0.25,3}, exteriorBudget={0,30}, outdoorDirectorInterval={5,60}, outdoorDirectorChance={0,100},
        outdoorPressureGain={0,50}, creatureDenChance={0,100}, creatureDenWaveInterval={5,120},
        creatureDenMinCycles={1,6}, creatureDenMaxCycles={1,6}, exteriorTriggerMin={100,2000}, exteriorTriggerRange={600,8000}, exteriorAnchorChance={0,100},
        exteriorGroupMin={1,10}, exteriorGroupMax={1,10}, exteriorSpawnMin={100,3000},
        interiorBudget={0,8}, creatureVariety={0,100},
        uniquePercent={0,100}, eliteTierPercent={0,100}, healingPercent={0,100}, supplyPercent={0,100}, ammunitionPercent={0,100}, spellTomePercent={0,100}, exteriorSpread={300,8000},
        lootDirectorStrength={0.1,3},lootDirectorReserve={0,500},lootDirectorSpreeChance={0,100},
        containerLootPercent={0,100}, looseDungeonItemPercent={0,100},
        npcInventoryPercent={0,100}, npcAshenGearPercent={0,50}, worldBossCadenceMinutes={2,60}, worldBossChance={0,100}, worldBossCellCap={1,10},
        worldBossAddInitialDelay={0,300}, worldBossAddInterval={5,300}, worldBossAddMin={1,10},
        worldBossAddMax={1,10}, worldBossAddCap={0,30},
        worldBossMinLevel={1,50}, worldBossRange={1000,10000}, worldBossSpawnMinDistance={1000,3000},
        worldBossDistanceHide={100,3000}}
    bounds.encounterLevelBelow={0,20};bounds.encounterLevelAbove={0,30};bounds.dungeonResetHours={6,720};bounds.wildernessResetHours={6,720}
    if bounds[key] then return math.max(bounds[key][1], math.min(bounds[key][2], tonumber(get(key)) or defaults[key])) end
    return get(key)
end})
