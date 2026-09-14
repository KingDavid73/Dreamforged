local I,storage,core,menu=require('openmw.interfaces'),require('openmw.storage'),require('openmw.core'),require('openmw.menu')
local C=require('scripts.ashenloot.config')
local keys={'enabled','preset','elitePercent','dropPercent','settleSeconds','protectQuestActors','allowRespawningNPCs','unsafeContent',
    'progression','levelScaling','gearLevelInfluence','enemyHealth','enemyDamage','encounterLevelBelow','encounterLevelAbove',
    'extraEncounters','directorIntensity','creaturePoolMode','creatureVariety','excludeExtraCliffRacers','settlementSuppression','rerunnableWilderness','wildernessResetHours',
    'interiorBudget','rerunnableDungeons','dungeonResetHours','dungeonBosses',
    'worldBosses','worldBossCadenceMinutes','worldBossCellCap','uniquePercent','eliteTierPercent','worldBossMinLevel','worldBossRange','worldBossSpawnMinDistance','worldBossDistanceHide',
    'healingPercent','supplyPercent','ammunitionPercent','spellTomePercent','adaptiveLootDirector','lootDirectorStrength','lootDirectorReserve','lootDirectorSpreeChance','supplyContainers','randomizeContainers','containerLootPercent','randomizeLooseDungeonItems','looseDungeonItemPercent','groundDrops','groundGlow','autoSalvageCommon','autoSalvageUncommon','autoSalvageRare','autoSalvageEpic','autoSalvageLegendary','autoSalvageRelic',
    'npcProgression','randomizeNpcInventories','npcInventoryPercent','npcAshenGearPercent','guardProgression','guardPower','scavenge','civilianDefense',
    'showTargetCard','inventoryKey','forgeKey','abilityControllerModifier','abilityControllerCycle','abilityControllerUse'}
local calls,controls={},nil
local done=false
local resetRequested=false
local finished=false
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
    local ok,err=pcall(function()
        if not resetRequested then
            for n,key in ipairs(keys) do
                local default=C.defaults[key]
                assert(controls[n].value==default,'Initial setting '..key)
                controls[n].set(default)
                assert(storage.globalSection(C.groupKey(key)):get(key)==default,'Setting callback '..key)
            end
            -- Exercise the same deferred event used by the menu button. The
            -- next frame must restore a deliberately changed value.
            controls[4].set(0)
            controls[17].set(3)
            controls[29].set(60)
            core.sendGlobalEvent('Dreamforged_ResetSettings')
            resetRequested=true
            return
        end
        assert(storage.globalSection(C.groupKey('dropPercent')):get('dropPercent')==C.defaults.dropPercent,
            'Deferred all-settings reset did not restore dropPercent')
        assert(storage.globalSection(C.groupKey('directorIntensity')):get('directorIntensity')==C.defaults.directorIntensity,
            'Deferred all-settings reset did not restore directorIntensity')
        assert(storage.globalSection(C.groupKey('worldBossCadenceMinutes')):get('worldBossCadenceMinutes')==C.defaults.worldBossCadenceMinutes,
            'Deferred all-settings reset did not restore worldBossCadenceMinutes')
        local registered=storage.globalSection('OmwSettingGroups'):asTable()
        local encounterGroup=registered[C.groups.encounters]
        assert(encounterGroup and not encounterGroup.settings.outdoorDirectorInterval,
            'Retired low-level director control was reintroduced')
        done=true
        finished=true
    end)
    if finished or not ok then
        print('[AshenLoot SETTINGS5] '..(ok and 'PASS: all '..#keys..' native controls have non-nil defaults and working global setters; deferred all-settings reset restored a changed value' or 'FAIL: '..tostring(err)))
    end
    if not ok then core.quit() end
end}}
