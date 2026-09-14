local I,storage,core,menu=require('openmw.interfaces'),require('openmw.storage'),require('openmw.core'),require('openmw.menu')
local C=require('scripts.ashenloot.config')
local keys={'enabled','preset','elitePercent','dropPercent','settleSeconds','protectQuestActors','allowRespawningNPCs','unsafeContent',
    'progression','levelScaling','gearLevelInfluence','enemyHealth','enemyDamage','encounterLevelBelow','encounterLevelAbove',
    'creatureVariety','creaturePoolMode','extraEncounters','encounterDensity','excludeExtraCliffRacers','exteriorBudget','outdoorDirectorInterval','outdoorDirectorChance','outdoorPressureGain','exteriorGroupMin','exteriorGroupMax','exteriorSpawnMin','exteriorSpread','settlementSuppression','rerunnableWilderness','wildernessResetHours',
    'interiorBudget','rerunnableDungeons','dungeonResetHours','dungeonBosses',
    'worldBosses','worldBossChance','worldBossCellCap','uniquePercent','eliteTierPercent',
    'worldBossAddInitialDelay','worldBossAddInterval','worldBossAddMin','worldBossAddMax','worldBossAddCap',
    'worldBossMinLevel','worldBossRange',
    'healingPercent','supplyPercent','ammunitionPercent','spellTomePercent','supplyContainers','randomizeContainers','containerLootPercent','randomizeLooseDungeonItems','looseDungeonItemPercent','groundDrops','groundGlow','autoSalvageCommon','autoSalvageUncommon','autoSalvageRare','autoSalvageEpic','autoSalvageLegendary','autoSalvageRelic',
    'npcProgression','randomizeNpcInventories','npcInventoryPercent','npcAshenGearPercent','guardProgression','guardPower','scavenge','civilianDefense',
    'showTargetCard','inventoryKey','forgeKey','abilityControllerModifier','abilityControllerCycle','abilityControllerUse'}
local calls,controls={},nil
local done=false
require('scripts.omw.settings.renderers')(function(name,render)
    I.Settings.registerRenderer(name,function(value,set,argument)
        calls[#calls+1]={value=value,set=set}
        if name=='select' and argument and argument.l10n=='AshenLoot' and argument.items[1]=='DPadRight' then
            controls={}
            for n=1,#keys do controls[n]=calls[#calls-#keys+n] end
        end
        return render(value,set,argument)
    end)
end)
return {engineHandlers={onFrame=function()
    if done or not controls or menu.getState()~=menu.STATE.Running then return end
    done=true
    local ok,err=pcall(function()
        for n,key in ipairs(keys) do
            local default=C.defaults[key]
            assert(controls[n].value==default,'Initial setting '..key)
            controls[n].set(default)
            assert(storage.globalSection(C.groupKey(key)):get(key)==default,'Setting callback '..key)
        end
    end)
    print('[AshenLoot SETTINGS5] '..(ok and 'PASS: all 78 native controls have non-nil defaults and working global setters' or 'FAIL: '..tostring(err)))
    if not ok then core.quit() end
end}}
