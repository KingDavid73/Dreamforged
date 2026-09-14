local I = require('openmw.interfaces')
local C = require('scripts.ashenloot.config')
local storage = require('openmw.storage')
local function option(key, renderer, argument)
    return {key = key, name = key, description = key .. 'Description', renderer = renderer,
        default = C.defaults[key], argument = argument}
end
local groups={
    {key=C.groups.reset,name='resetSettings',description='resetSettingsDescription',order=0,settings={
        option('resetAllSettings', 'dreamforgedReset'),
    }},
    {key='SettingsAshenLoot',name='generalSettings',description='generalSettingsDescription',order=10,settings={
        option('enabled', 'checkbox'),
        option('preset', 'select', {l10n = 'AshenLoot', items = {'Crawler', 'Testing', 'Balanced', 'Custom'}}),
        option('elitePercent', 'number', {min = 0, max = 100, integer = true}),
        option('dropPercent', 'number', {min = 0, max = 100, integer = true}),
        option('settleSeconds', 'number', {min = 0.5, max = 10}),
        option('protectQuestActors', 'checkbox'),
        option('allowRespawningNPCs', 'checkbox'),
        option('unsafeContent', 'checkbox'),
    }},
    {key=C.groups.scaling,name='scalingSettings',description='scalingSettingsDescription',order=20,settings={
        option('progression', 'checkbox'),
        option('levelScaling', 'number', {min=0,max=2}),
        option('gearLevelInfluence', 'number', {min=0,max=1}),
        option('enemyHealth', 'number', {min=0.25,max=3}),
        option('enemyDamage', 'number', {min=0.25,max=3}),
        option('encounterLevelBelow', 'number', {min=0,max=20,integer=true}),
        option('encounterLevelAbove', 'number', {min=0,max=30,integer=true}),
    }},
    {key=C.groups.encounters,name='encounterSettings',description='encounterSettingsDescription',order=30,settings={
        option('creatureVariety', 'number', {min=0,max=100,integer=true}),
        option('creaturePoolMode', 'select', {l10n='AshenLoot', items={'Similar','Random'}}),
        option('extraEncounters', 'checkbox'),
        option('encounterDensity', 'number', {min=0.5,max=3}),
        option('excludeExtraCliffRacers', 'checkbox'),
        option('exteriorBudget', 'number', {min=0,max=30,integer=true}),
        option('outdoorDirectorInterval', 'number', {min=3,max=60,integer=true}),
        option('outdoorDirectorChance', 'number', {min=0,max=100,integer=true}),
        option('outdoorPressureGain', 'number', {min=0,max=50,integer=true}),
        option('creatureDenChance', 'number', {min=0,max=100,integer=true}),
        option('creatureDenWaveInterval', 'number', {min=5,max=120,integer=true}),
        option('creatureDenMinCycles', 'number', {min=1,max=6,integer=true}),
        option('creatureDenMaxCycles', 'number', {min=1,max=6,integer=true}),
        option('exteriorGroupMin', 'number', {min=1,max=10,integer=true}),
        option('exteriorGroupMax', 'number', {min=1,max=10,integer=true}),
        option('exteriorSpawnMin', 'number', {min=300,max=3000,integer=true}),
        option('exteriorSpread', 'number', {min=300,max=8000,integer=true}),
        option('settlementSuppression', 'checkbox'),
        option('rerunnableWilderness', 'checkbox'),
        option('wildernessResetHours', 'number', {min=6,max=720,integer=true}),
    }},
    {key=C.groups.dungeons,name='dungeonSettings',description='dungeonSettingsDescription',order=40,settings={
        option('interiorBudget', 'number', {min=0,max=8,integer=true}),
        option('rerunnableDungeons', 'checkbox'),
        option('dungeonResetHours', 'number', {min=6,max=720,integer=true}),
        option('dungeonBosses', 'checkbox'),
    }},
    {key=C.groups.bosses,name='bossSettings',description='bossSettingsDescription',order=50,settings={
        option('worldBosses', 'checkbox'),
        option('worldBossChance', 'number', {min=0,max=100,integer=true}),
        option('worldBossCellCap', 'number', {min=1,max=10,integer=true}),
        option('uniquePercent', 'number', {min=0,max=100,integer=true}),
        option('eliteTierPercent', 'number', {min=0,max=100,integer=true}),
        option('worldBossAddInitialDelay', 'number', {min=0,max=300,integer=true}),
        option('worldBossAddInterval', 'number', {min=5,max=300,integer=true}),
        option('worldBossAddMin', 'number', {min=1,max=10,integer=true}),
        option('worldBossAddMax', 'number', {min=1,max=10,integer=true}),
        option('worldBossAddCap', 'number', {min=0,max=30,integer=true}),
        option('worldBossMinLevel', 'number', {min=1,max=50,integer=true}),
        option('worldBossRange', 'number', {min=1000,max=10000,integer=true}),
    }},
    {key=C.groups.loot,name='lootSettings',description='lootSettingsDescription',order=60,settings={
        option('healingPercent', 'number', {min=0,max=100,integer=true}),
        option('supplyPercent', 'number', {min=0,max=100,integer=true}),
        option('ammunitionPercent', 'number', {min=0,max=100,integer=true}),
        option('spellTomePercent', 'number', {min=0,max=100,integer=true}),
        option('adaptiveLootDirector', 'checkbox'),
        option('lootDirectorStrength', 'number', {min=0.1,max=3}),
        option('lootDirectorReserve', 'number', {min=0,max=500,integer=true}),
        option('lootDirectorSpreeChance', 'number', {min=0,max=100,integer=true}),
        option('supplyContainers', 'checkbox'),
        option('randomizeContainers', 'checkbox'),
        option('containerLootPercent', 'number', {min=0,max=100,integer=true}),
        option('randomizeLooseDungeonItems', 'checkbox'),
        option('looseDungeonItemPercent', 'number', {min=0,max=100,integer=true}),
        option('groundDrops', 'checkbox'),
        option('groundGlow', 'checkbox'),
        option('autoSalvageCommon', 'checkbox'),
        option('autoSalvageUncommon', 'checkbox'),
        option('autoSalvageRare', 'checkbox'),
        option('autoSalvageEpic', 'checkbox'),
        option('autoSalvageLegendary', 'checkbox'),
        option('autoSalvageRelic', 'checkbox'),
    }},
    {key=C.groups.npcs,name='npcSettings',description='npcSettingsDescription',order=70,settings={
        option('npcProgression', 'checkbox'),
        option('randomizeNpcInventories', 'checkbox'),
        option('npcInventoryPercent', 'number', {min=0,max=100,integer=true}),
        option('npcAshenGearPercent', 'number', {min=0,max=50,integer=true}),
        option('guardProgression', 'checkbox'),
        option('guardPower', 'number', {min=1,max=2.5}),
        option('scavenge', 'checkbox'),
        option('civilianDefense', 'checkbox'),
    }},
    {key=C.groups.interface,name='interfaceSettings',description='interfaceSettingsDescription',order=80,settings={
        option('showTargetCard', 'checkbox'),
        option('inventoryKey', 'select', {l10n = 'AshenLoot', items = {'F6', 'F7', 'F8', 'F9', 'F10', 'F11'}}),
        option('forgeKey', 'select', {l10n = 'AshenLoot', items = {'F6', 'F7', 'F8', 'F9', 'F10', 'F11'}}),
        option('abilityControllerModifier', 'select', {l10n='AshenLoot', items={'LeftShoulder','RightShoulder','LeftStick','RightStick','Back','Start','Paddle1','Paddle2','Paddle3','Paddle4'}}),
        option('abilityControllerCycle', 'select', {l10n='AshenLoot', items={'DPadLeft','DPadRight','DPadUp','DPadDown','A','B','X','Y','LeftStick','RightStick','LeftShoulder','RightShoulder','Paddle1','Paddle2','Paddle3','Paddle4'}}),
        option('abilityControllerUse', 'select', {l10n='AshenLoot', items={'DPadRight','DPadLeft','DPadUp','DPadDown','A','B','X','Y','LeftStick','RightStick','LeftShoulder','RightShoulder','Paddle1','Paddle2','Paddle3','Paddle4'}}),
    }},
}
for _,group in ipairs(groups) do
    local section=storage.globalSection(group.key);section:setLifeTime(storage.LIFE_TIME.Temporary)
    I.Settings.registerGroup {key=group.key,page='AshenLoot',l10n='AshenLoot',name=group.name,
        description=group.description,order=group.order,permanentStorage=false,settings=group.settings}
end
-- OpenMW 0.51's menu rebuild loses the global-storage flag on whole-section
-- reset notifications. Set keys individually so controls keep reading/writing
-- global settings and retain their renderer arguments (including selectors).
-- onInit resets a new character; saved characters are restored by Settings.
return {engineHandlers = {onInit = function()
    for key, value in pairs(C.defaults) do storage.globalSection(C.groupKey(key)):set(key,value) end
end}}
