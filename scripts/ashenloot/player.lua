local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local async = require('openmw.async')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local I = require('openmw.interfaces')
local C = require('scripts.ashenloot.config')
local R = require('scripts.ashenloot.rules')
local A = require('scripts.ashenloot.advancement')
local whiteTexture=ui.texture {path='white'}
I.Settings.registerPage {key = 'AshenLoot', l10n = 'AshenLoot', name = 'page', description = 'pageDescription'}
local records, elites, fresh, forgePoints = {}, {}, {}, {0,0,0,0,0,0}
local classBoosted = false
local classKitGranted = false
local classElapsed = 0
local classAttributes
local advancementElapsed,activeAbilities,activeIndex,lastAdvancementSignature=0,{},0,''
local restSession
local attributeIds = {'strength', 'intelligence', 'willpower', 'agility', 'speed', 'endurance', 'personality', 'luck'}
local classSkills = {
    al_warrior = {major = {'longblade', 'block', 'heavyarmor', 'armorer', 'athletics'},
        minor = {'axe', 'bluntweapon', 'spear', 'mediumarmor', 'marksman'}},
    al_warmage = {major = {'destruction', 'restoration', 'heavyarmor', 'bluntweapon', 'enchant'},
        minor = {'alteration', 'mysticism', 'conjuration', 'block', 'alchemy'}},
    al_archer = {major = {'marksman', 'lightarmor', 'athletics', 'sneak', 'spear'},
        minor = {'acrobatics', 'shortblade', 'alchemy', 'security', 'restoration'}},
    al_rogue = {major = {'shortblade', 'sneak', 'lightarmor', 'security', 'illusion'},
        minor = {'marksman', 'acrobatics', 'speechcraft', 'mercantile', 'alchemy'}},
    al_conjurer = {major = {'conjuration', 'illusion', 'mysticism', 'alteration', 'enchant'},
        minor = {'restoration', 'destruction', 'alchemy', 'unarmored', 'shortblade'}},
}
local function isRestMode(mode)
    local modes=I.UI and I.UI.MODE
    local known=modes and (modes.Rest or modes.RestMenu)
    if known and mode==known then return true end
    return type(mode)=='string' and mode:lower():find('rest',1,true)~=nil
end
local function safeSleepCell(cell)
    if not cell or cell.isExterior then return false end
    if cell.hasTag then
        local ok,noSleep=pcall(cell.hasTag,cell,'NoSleep')
        if ok and noSleep then return false end
    end
    return true
end
local townInteriorPrefixes={
    "ald'ruhn",'akamora','andothren','balmora','bal oyra','blacklight','caldera',
    'dagon fel','ebonheart','firewatch','gnaar mok','gnisis','hla oad','helnim',
    'kragenmoor','khuul','maar gan','molag mar','mournhold','narsis','necrom',
    'old ebonheart','pelagiad','port telvannis','raven rock','sadrith mora',
    'seyda neen','silgrad tower','suran','tel aruhn','tel branora','tel mora',
    'vivec','vos','wolverine hall','baan malur','glenpoint',
}
local function townSleepCell(cell)
    if not safeSleepCell(cell) then return false end
    local name=(tostring(cell.name or '')..' '..tostring(cell.id or '')):lower():gsub('^%s+','')
    for _,prefix in ipairs(townInteriorPrefixes) do
        if name==prefix or name:sub(1,#prefix+1)==prefix..','
            or name:sub(1,#prefix+1)==prefix..' ' then return true end
    end
    return false
end
local book, forgeWindow, targetCard, bossCard, voiceCard
local voiceMessage,voiceUntil
local page, lastTarget, elapsed = 0, nil, 0
local forgePage=1
local function color(tier)
    local c = R.rarities[tier].color
    return util.color.rgb(c[1], c[2], c[3])
end
local function text(value, tier)
    return {type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
        props = {text = value, textColor = tier and color(tier) or util.color.rgb(0.86, 0.84, 0.78)}}
end
local function wrapped(lines, value)
    local line = ''
    for word in value:gmatch('%S+') do
        if #line + #word > 90 then lines[#lines + 1] = text(line); line = '' end
        line = line == '' and word or line .. ' ' .. word
    end
    if line ~= '' then lines[#lines + 1] = text(line) end
end
local function panel(lines, x, y)
    return {layer = 'HUD', template = I.MWUI.templates.boxTransparent,
        props = {relativePosition = util.vector2(x, y), anchor = util.vector2(0.5, 0)},
        content = ui.content {{type = ui.TYPE.Flex, content = ui.content(lines)}}}
end
local function actorPanel(name, subtitle, current, maximum, tier)
    local width,height=460,subtitle and 56 or 38
    local fraction=math.max(0,math.min(1,current/math.max(1,maximum)))
    local nameColor=tier and color(tier) or util.color.rgb(0.92,0.88,0.78)
    local content={
        {type=ui.TYPE.Flex,props={horizontal=true,arrange=ui.ALIGNMENT.Center,size=util.vector2(width,20)},
            content=ui.content{{type=ui.TYPE.Text,template=I.MWUI.templates.textNormal,
                props={text=name,textColor=nameColor}}}},
        {type=ui.TYPE.Image,props={resource=whiteTexture,color=util.color.rgb(0.05,0.025,0.02),
            position=util.vector2(0,22),size=util.vector2(width,14)}},
        {type=ui.TYPE.Image,props={resource=whiteTexture,color=util.color.rgb(0.18,0.015,0.01),
            position=util.vector2(2,24),size=util.vector2(width-4,10)}},
        {type=ui.TYPE.Image,props={resource=whiteTexture,color=util.color.rgb(0.68,0.025,0.015),
            position=util.vector2(2,24),size=util.vector2(math.max(1,(width-4)*fraction),10)}},
    }
    if subtitle then
        content[#content+1]={type=ui.TYPE.Flex,props={horizontal=true,arrange=ui.ALIGNMENT.Center,
            position=util.vector2(0,39),size=util.vector2(width,17)},content=ui.content{{type=ui.TYPE.Text,
                template=I.MWUI.templates.textNormal,props={text=subtitle,textColor=nameColor}}}}
    end
    return {layer='HUD',type=ui.TYPE.Container,
        props={relativePosition=util.vector2(0.5,0.075),anchor=util.vector2(0.5,0),size=util.vector2(width,height)},
        content=ui.content(content)}
end
local function metadata(item)
    if records[item.recordId] then return records[item.recordId] end
    if fresh[item.recordId] then
        local rec = item.type.record(item)
        return {name = rec.name, tier = R.freshRarity(fresh[item.recordId]), source = 'Fresh Loot',
            details = {'Rarity estimated from Fresh Loot affix count and levels.'}}
    end
end
local function closeBook()
    if book then book:destroy(); book = nil end
    page = 0
end
local function closeForge()
    if forgeWindow and forgeWindow~=true then forgeWindow:destroy() end
    forgeWindow=nil
    if I.UI.getMode()==I.UI.MODE.Interface then I.UI.removeMode(I.UI.MODE.Interface) end
end
local function actionText(label,tier,callback)
    return {type=ui.TYPE.Text,template=I.MWUI.templates.textNormal,
        props={text=label,textColor=tier and color(tier) or util.color.rgb(0.95,0.82,0.45)},
        events={mouseClick=async:callback(callback)}}
end
local function renderForge()
    if not forgeWindow then return end
    if forgeWindow~=true then forgeWindow:destroy() end
    forgeWindow=nil
    local equipped={}
    for _,item in pairs(types.Actor.getEquipment(self)) do equipped[item.id]=true end
    local items={}
    for _,item in ipairs(types.Actor.inventory(self):getAll()) do
        local meta=records[item.recordId]
        if meta and not equipped[item.id] then items[#items+1]={item=item,meta=meta} end
    end
    table.sort(items,function(a,b)
        if a.meta.tier~=b.meta.tier then return a.meta.tier<b.meta.tier end
        return a.meta.name<b.meta.name
    end)
    local perPage=8;local pages=math.max(1,math.ceil(#items/perPage));forgePage=math.min(forgePage,pages)
    local divider='------------------------------------------------------------'
    local lines={text('DREAMFORGED REFORGING EXCHANGE'),
        text('Salvage page '..forgePage..'/'..pages),
        text('Equipped items are protected and never appear below.'),
        text(divider),
        text('FORGE AND COMBINE'),
        text('Five matching coins forge one item. Three coins combine upward.')}
    for tier=1,6 do
        local purchaseTier=tier
        local points=forgePoints[tier] or 0
        lines[#lines+1]=actionText('Forge '..R.rarities[tier].name..': '..points..'/5 coins',tier,function()
            core.sendGlobalEvent('AshenLoot_Reforge',{player=self,tier=purchaseTier})
        end)
        if tier<6 then
            lines[#lines+1]=actionText('Combine 3 '..R.rarities[tier].name..' coins -> 1 '..R.rarities[tier+1].name..' coin',tier+1,function()
                core.sendGlobalEvent('AshenLoot_CombineForgeCoins',{player=self,tier=purchaseTier})
            end)
        end
    end
    lines[#lines+1]=text(divider)
    lines[#lines+1]=text('SALVAGE - COMMON TO RELIC')
    lines[#lines+1]=text('Select an unequipped item to convert it into one matching coin.')
    if #items==0 then lines[#lines+1]=text('Nothing available to salvage. Equipped items are protected.') end
    for index=(forgePage-1)*perPage+1,math.min(forgePage*perPage,#items) do
        local entry=items[index];local salvageItem=entry.item;local salvageMeta=entry.meta
        lines[#lines+1]=actionText('Salvage: '..salvageMeta.name,salvageMeta.tier,function()
            core.sendGlobalEvent('AshenLoot_Salvage',{player=self,item=salvageItem})
        end)
    end
    if pages>1 then lines[#lines+1]=actionText('Next salvage page',nil,function() forgePage=forgePage%pages+1;renderForge() end) end
    lines[#lines+1]=actionText('Close exchange',nil,closeForge)
    forgeWindow=ui.create({layer='Windows',template=I.MWUI.templates.boxTransparent,
        props={relativePosition=util.vector2(0.5,0.5),anchor=util.vector2(0.5,0.5)},
        content=ui.content{{type=ui.TYPE.Flex,content=ui.content(lines)}}})
end
local function openForge()
    closeBook();forgePage=1
    I.UI.addMode(I.UI.MODE.Interface,{windows={}})
    forgeWindow=true;renderForge()
    core.sendGlobalEvent('AshenLoot_Request')
end
local function renderBook()
    if page == 0 then return end
    if book then book:destroy(); book = nil end
    local items = {}
    for _, item in ipairs(types.Actor.inventory(self):getAll()) do
        local meta = metadata(item)
        if meta then items[#items + 1] = {item = item, meta = meta} end
    end
    table.sort(items, function(a, b)
        if a.meta.tier ~= b.meta.tier then return a.meta.tier > b.meta.tier end
        return a.meta.name < b.meta.name
    end)
    local pages = math.max(1, math.ceil(#items / C.pageSize))
    if page > pages then closeBook(); return end
    local lines = {text('MORROWIND: DREAMFORGED  |  ' .. page .. '/' .. pages),
        text(C.inventoryKey .. ': next page / close after last page.  Shift+' .. C.inventoryKey .. ': close.')}
    if #items == 0 then lines[#lines + 1] = text('No affixed loot in your inventory yet.') end
    for index = (page - 1) * C.pageSize + 1, math.min(page * C.pageSize, #items) do
        local entry, meta = items[index], items[index].meta
        lines[#lines + 1] = text(meta.name
            .. (entry.item.count > 1 and ' x' .. entry.item.count or ''), meta.tier)
        if meta.source == 'Fresh Loot' then
            lines[#lines + 1] = text('Fresh Loot | rarity estimated from affixes')
        else
            wrapped(lines, table.concat(meta.details, ' | '))
        end
    end
    book = ui.create(panel(lines, 0.5, 0.15))
end
local function clearTarget()
    if targetCard then targetCard:destroy(); targetCard = nil end
    lastTarget = nil
end
local function clearBossCard()
    if bossCard then bossCard:destroy();bossCard=nil end
end
local function clearVoiceCard()
    if voiceCard then voiceCard:destroy();voiceCard=nil end
end
local function updateVoiceCard()
    if not C.enabled or C.directorVoiceFrequency<=0 or I.UI.getMode()
        or not voiceMessage or core.getSimulationTime()>=(voiceUntil or 0) then
        clearVoiceCard()
        return
    end
    if voiceCard then return end
    local speakerColor=voiceMessage.speaker=='Dagoth Ur'
        and util.color.rgb(0.82,0.58,0.38) or util.color.rgb(0.67,0.79,0.92)
    local lines={{type=ui.TYPE.Text,template=I.MWUI.templates.textNormal,
        props={text=voiceMessage.speaker,textColor=speakerColor}}}
    wrapped(lines,voiceMessage.text)
    local layout=panel(lines,0.5,0.78)
    layout.props.anchor=util.vector2(0.5,1)
    voiceCard=ui.create(layout)
end
local function updateBossCard()
    clearBossCard()
    if not C.worldBosses or I.UI.getMode() then return end
    local nearest,meta,distance
    for _,actor in ipairs(nearby.actors) do
        local boss=elites[actor.id]
        if boss and boss.worldBoss and actor:isValid() and not types.Actor.isDead(actor) then
            local d=(actor.position-self.position):length()
            if d<=C.worldBossRange and (not distance or d<distance) then nearest,meta,distance=actor,boss,d end
        end
    end
    if not nearest then return end
    local displayName=meta.name
    local hideDistance=math.max(0,tonumber(C.worldBossDistanceHide) or 900)
    if distance>hideDistance then
        displayName=displayName..'  ['..math.floor(distance+0.5)..' units]'
    end
    local hp=types.Actor.stats.dynamic.health(nearest)
    local maximum=math.max(1,math.ceil(hp.base+hp.modifier))
    local current=math.max(0,math.ceil(hp.current))
    local fraction=math.max(0,math.min(1,current/maximum))
    local width,height=760,52
    bossCard=ui.create({layer='HUD',type=ui.TYPE.Container,
        props={relativePosition=util.vector2(0.5,0.90),anchor=util.vector2(0.5,1),size=util.vector2(width,height)},
        content=ui.content {
            {type=ui.TYPE.Flex,props={horizontal=true,arrange=ui.ALIGNMENT.Center,size=util.vector2(width,26)},
                content=ui.content {{type=ui.TYPE.Text,template=I.MWUI.templates.textNormal,
                    props={text=displayName,textColor=util.color.rgb(0.92,0.88,0.78)}}}},
            {type=ui.TYPE.Image,props={resource=whiteTexture,color=util.color.rgb(0.05,0.025,0.02),
                position=util.vector2(0,30),size=util.vector2(width,20)}},
            {type=ui.TYPE.Image,props={resource=whiteTexture,color=util.color.rgb(0.18,0.015,0.01),
                position=util.vector2(3,33),size=util.vector2(width-6,14)}},
            {type=ui.TYPE.Image,props={resource=whiteTexture,color=util.color.rgb(0.68,0.025,0.015),
                position=util.vector2(3,33),size=util.vector2(math.max(1,(width-6)*fraction),14)}},
        }})
end
local function frame(dt)
    local class = string.lower(types.NPC.record(self).class or '')
    local skills = classSkills[class]
    -- NCGDMW derives a new attribute total when chargen closes.  Remember the
    -- values the player actually confirmed so our deliberately stronger class
    -- templates survive that initialization pass.
    if skills and I.UI.getMode() == 'ChargenClassReview' then
        classAttributes = {}
        for _, id in ipairs(attributeIds) do
            classAttributes[id] = types.Actor.stats.attributes[id](self).base
        end
    end
    if not classBoosted then
        local ncgdReady = not I.NCGDMW or not I.NCGDMW.GetState or I.NCGDMW.GetState().isInitialized
        if types.Player.isCharGenFinished(self) and ncgdReady then classElapsed = classElapsed + dt end
        if classElapsed >= 3 then
            classElapsed = 0
            if skills then
                if classAttributes then
                    for _, id in ipairs(attributeIds) do
                        local value = classAttributes[id]
                        if value then
                            if I.NCGDMW and I.NCGDMW.Attribute then I.NCGDMW.Attribute(id, value)
                            else types.Actor.stats.attributes[id](self).base = value end
                        end
                    end
                end
                for _, id in ipairs(skills.major) do
                    local stat = types.NPC.stats.skills[id](self)
                    local value = math.min(100, stat.base + 10)
                    if I.NCGDMW and I.NCGDMW.Skill then I.NCGDMW.Skill(id, value) else stat.base = value end
                end
                for _, id in ipairs(skills.minor) do
                    local stat = types.NPC.stats.skills[id](self)
                    local value = math.min(100, stat.base + 5)
                    if I.NCGDMW and I.NCGDMW.Skill then I.NCGDMW.Skill(id, value) else stat.base = value end
                end
                classBoosted = true
            end
            if skills and not classKitGranted then
                core.sendGlobalEvent('AshenLoot_StartingKit', {player = self, class = class})
                classKitGranted = true
            end
        end
    end
    if not C.enabled then closeBook();closeForge(); clearTarget();clearBossCard();clearVoiceCard(); return end
    advancementElapsed=advancementElapsed+dt
    if advancementElapsed>=1 and types.Player.isCharGenFinished(self) then
        advancementElapsed=0
        local rec=types.NPC.record(self)
        local classRecord=types.NPC.classes and types.NPC.classes.records and types.NPC.classes.records[rec.class]
        local specialty=A.specialty(rec.class,classRecord and classRecord.specialization)
        local values={};for skill in pairs(A.skills) do values[skill]=types.NPC.stats.skills[skill](self).base end
        local playerLevel=types.Actor.stats.level(self).current
        local signature=specialty..':'..playerLevel
        for skill in pairs(A.skills) do signature=signature..':'..skill..'='..values[skill] end
        if signature~=lastAdvancementSignature then
            lastAdvancementSignature=signature
            core.sendGlobalEvent('AshenLoot_AdvancementReconcile',{player=self,
                level=playerLevel,specialty=specialty,skills=values})
        end
    end
    if not C.enabled or I.UI.getMode() then clearTarget();clearBossCard();clearVoiceCard(); return end
    elapsed = elapsed + dt
    if elapsed < 0.15 then return end
    elapsed = 0
    updateVoiceCard()
    updateBossCard()
    if not C.showTargetCard then clearTarget();return end
    local origin = camera.getPosition()
    local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    local hit = nearby.castRenderingRay(origin, origin + direction * 4000, {ignore = self})
    local item = hit.hitObject
    if not item or not item:isValid() then clearTarget(); return end
    local elite = elites[item.id]
    local meta = metadata(item)
    -- Living World Bosses use the dedicated bottom HUD bar.  Once dead, let
    -- the ordinary target path render the saved full corpse biography and
    -- modifier list instead of reverting to a generic defeated card.
    if elite and elite.worldBoss
        and not (types.Actor.objectIsInstance(item) and types.Actor.isDead(item)) then
        clearTarget();return
    end
    local lines, key
    if types.Actor.objectIsInstance(item) and (elite or types.Actor.stats.ai.fight(item).base>=80) then
        local hp=types.Actor.stats.dynamic.health(item)
        local current=math.max(0,math.ceil(hp.current))
        local maximum=math.max(1,math.ceil(hp.base+hp.modifier))
        local dead=types.Actor.isDead(item)
        local rec=item.type.record(item)
        local name=elite and elite.name or rec.name
        local tier=elite and (elite.rank and math.min(4,elite.rank+1) or 2) or nil
        key=item.id..':'..current..':'..tostring(dead)
        if not dead then
            local subtitle
            if elite then
                local names={}
                for _,index in ipairs(elite.modifiers) do
                    local mod=(elite.rulesVersion==3 and R.elites or R.legacyElites)[index]
                    if mod then names[#names+1]=mod.name end
                end
                local rank=elite.rank and ({'Champion','Elite','Unique'})[elite.rank] or 'Promoted'
                subtitle=rank..(#names>0 and '  |  '..table.concat(names,' | ') or '')
            end
            clearTarget();lastTarget=key
            targetCard=ui.create(actorPanel(name,subtitle,current,maximum,tier))
            return
        elseif elite then
        local tier = elite.rank and math.min(4, elite.rank + 1) or (elite.tier == 2 and 4 or 2)
        local descriptions = {}
        for _, index in ipairs(elite.modifiers) do
            local mod = (elite.rulesVersion == 3 and R.elites or R.legacyElites)[index]
            descriptions[#descriptions + 1] = mod.name .. ': ' .. mod.description
        end
        local rankLabel
        if elite.worldBoss then
            rankLabel = 'WORLD BOSS  '
        else
            rankLabel = elite.rank and ({'CHAMPION  ','ELITE  ','UNIQUE  '})[elite.rank]
                or (elite.tier == 2 and 'CHAMPION  ' or 'ELITE  ')
        end
        lines = {text(rankLabel .. elite.name, tier),
            text(elite.baseName .. ' | ' .. current .. ' health | x' .. elite.healthScale .. ' base health'),
            }
        if elite.biography then wrapped(lines,elite.biography) end
        for _, description in ipairs(descriptions) do lines[#lines+1] = text(description, tier) end
        if elite.effectScale and elite.effectScale>1 then lines[#lines+1]=text('Level '..elite.itemLevel..' | Primary powers x'..elite.effectScale..' (silence duration unchanged)') end
        clearTarget();lastTarget=key
        targetCard=ui.create(panel(lines,0.5,0.075))
        return
        else
            local actorLevel=math.max(1,types.Actor.stats.level(item).current)
            local corpseLines={text('DEFEATED  '..name),text('Level '..actorLevel..' | '..maximum..' base health')}
            clearTarget();lastTarget=key
            targetCard=ui.create(panel(corpseLines,0.5,0.075))
            return
        end
    end
    if not lines then clearTarget(); return end
    key = key .. ':' .. C.targetPosition
    if key == lastTarget then return end
    clearTarget()
    lastTarget = key
    local layout = panel(lines, C.targetPosition == 'Left' and 0.02 or 0.5,
        C.targetPosition == 'Top' and 0.18 or (C.targetPosition == 'Left' and 0.35 or 0.94))
    layout.props.anchor = util.vector2(C.targetPosition == 'Left' and 0 or 0.5, C.targetPosition == 'Bottom' and 1 or 0)
    targetCard = ui.create(layout)
end
local function tooltip(item, layout)
    local meta = metadata(item)
    if not meta then return end
    local ok, content = pcall(function() return layout.content[1].content[1].content end)
    if ok and content then content:insert(2, text('[' .. (meta.rarity or R.rarities[meta.tier].name) .. '] ' .. meta.source, meta.tier)) end
end
local function selectedAbilityMessage()
    if #activeAbilities==0 then ui.showMessage('No Dreamforged active abilities unlocked.');return false end
    activeIndex=activeIndex%#activeAbilities+1
    ui.showMessage('Dreamforged ability: '..activeAbilities[activeIndex].name..' (Ctrl+'..C.inventoryKey..' or controller combo to use)')
    return true
end
local function useSelectedAbility()
    local ability=activeAbilities[activeIndex]
    if not ability then ui.showMessage('No Dreamforged active ability selected. Cycle one first.');return end
    local target
    if ability.target then
        local origin=camera.getPosition();local direction=camera.viewportToWorldVector(util.vector2(0.5,0.5))
        local hit=nearby.castRenderingRay(origin,origin+direction*4000,{ignore=self})
        target=hit.hitObject
    end
    core.sendGlobalEvent('AshenLoot_UseAdvancement',{player=self,id=ability.id,target=target})
end
if I.InventoryExtender then I.InventoryExtender.registerTooltipModifier('AshenLoot', tooltip) end
return {
    interfaceName = 'AshenLootUI',
    interface = {version = 1, getMetadata = metadata, openInventory = function() page = 1; renderBook() end},
    engineHandlers = {
        onFrame = frame,
        onKeyPress = function(key)
            if not C.enabled then return end
            if I.UI.getMode() == 'Console' then return end
            if key.code==input.KEY[C.forgeKey] then
                if I.UI.getMode() and not forgeWindow then return end
                if forgeWindow then closeForge() else openForge() end
                return
            end
            if key.code ~= input.KEY[C.inventoryKey] then return end
            if key.withCtrl then
                useSelectedAbility()
                return
            end
            if key.withShift then
                closeBook()
                selectedAbilityMessage()
                return
            end
            page = page + 1
            core.sendGlobalEvent('AshenLoot_Request')
        end,
        onControllerButtonPress = function(id)
            if not C.enabled or I.UI.getMode() then return end
            local buttons=input.CONTROLLER_BUTTON
            local modifier=buttons[C.abilityControllerModifier]
            if not modifier or id==modifier or not input.isControllerButtonPressed(modifier) then return end
            if id==buttons[C.abilityControllerCycle] then closeBook();selectedAbilityMessage();return end
            if id==buttons[C.abilityControllerUse] then useSelectedAbility() end
        end,
        onActive = function() core.sendGlobalEvent('AshenLoot_Request') end,
        onSave = function()
            return {fresh = fresh, classBoosted = classBoosted, classKitGranted = classKitGranted,
                classAttributes = classAttributes}
        end,
        onLoad = function(data)
            fresh = data and data.fresh or {}
            classBoosted = data and data.classBoosted or false
            classKitGranted = data and data.classKitGranted or false
            classAttributes = data and data.classAttributes or nil
            lastAdvancementSignature='';advancementElapsed=0
            closeBook();closeForge(); clearTarget();clearBossCard();clearVoiceCard();voiceMessage=nil;voiceUntil=nil
        end,
    },
    eventHandlers = {
        AshenLoot_DirectorVoice = function(event)
            if not event or not event.speaker or not event.text then return end
            voiceMessage={speaker=tostring(event.speaker),text=tostring(event.text)}
            voiceUntil=core.getSimulationTime()+math.max(3,math.min(12,tonumber(event.duration) or 7))
            clearVoiceCard()
            updateVoiceCard()
        end,
        UiModeChanged = function(data)
            if not data then return end
            local entering=isRestMode(data.newMode)
            local leaving=isRestMode(data.oldMode) and not entering
            if entering then
                restSession={cell=self.cell,gameTime=core.getGameTime()}
            elseif leaving and restSession then
                local elapsed=core.getGameTime()-(restSession.gameTime or 0)
                local cell=self.cell
                -- OpenMW currently exposes no sleep-completed Lua event. The
                -- native Rest UI does expose its mode transition; combining
                -- that with a meaningful game-time advance and a cell that
                -- permits sleep gives us a conservative signal. Then require a
                -- known settlement interior; wilderness camps and remote
                -- dungeons may restore health, but do not ease world pressure.
                if elapsed>=60 and cell==restSession.cell and townSleepCell(cell) then
                    core.sendGlobalEvent('AshenLoot_SafeSleep',{player=self,duration=elapsed,town=true})
                end
                restSession=nil
            end
        end,
        AshenLoot_CheckReplacement=function(event)
            local actor=event.actor
            local clear=false
            if actor and actor:isValid() and actor.cell==self.cell then
                local pos=actor.position
                clear=not nearby.castRay(pos+util.vector3(0,0,80),pos+util.vector3(0,0,220),
                    {radius=60,collisionType=nearby.COLLISION_TYPE.World+nearby.COLLISION_TYPE.Door+nearby.COLLISION_TYPE.HeightMap}).hit
            end
            core.sendGlobalEvent('AshenLoot_ReplacementResult',{token=event.token,clear=clear})
        end,
        AshenLoot_FindSpawn = function(event)
            local positions={}
            local actor=event.actor
            if C.enabled and actor and actor:isValid() and (actor.cell.isExterior or actor.cell==self.cell) then
                if actor.cell.isExterior then
                    local options={agentBounds=types.Actor.getPathfindingAgentBounds(actor),
                        includeFlags=nearby.NAVIGATOR_FLAGS.Walk}
                    local directorMin=math.max(1000,math.min(3000,tonumber(C.worldBossSpawnMinDistance) or 1200))
                    local spawnMin=event.director and directorMin or 1200
                    local spawnMax=event.director and math.max(directorMin+200,2200) or 2200
                    local attempts=math.max(18,event.count*20)
                    local strictAttempts=math.floor(attempts*0.55)
                    local dir=util.vector3(event.dirX or 1,event.dirY or 0,0)
                    local forwardDirector=event.director and not event.denWave
                    local center=forwardDirector and actor.position+dir*((spawnMin+spawnMax)*0.5) or actor.position
                    local radius=forwardDirector and math.max(250,(spawnMax-spawnMin)*0.5)
                        or (event.denWave and math.min(650,spawnMax) or spawnMax)
                    for attempt=1,attempts do
                        if #positions>=event.count then break end
                        -- Director groups get a bounded relaxed pass after the
                        -- strict navmesh samples at every intensity. Hills and
                        -- modded terrain are common; waiting for maximum
                        -- intensity here made ordinary defaults silently lose
                        -- most of their requested group.
                        local relaxed=event.director and attempt>strictAttempts
                        local pos=nearby.findRandomPointAroundCircle(center,radius,options)
                        -- At maximum density, fall back to a deterministic
                        -- landscape probe if the local navmesh sampler cannot
                        -- supply enough points. This favors visible hordes over
                        -- silently refunding most of the configured budget.
                        if not pos and relaxed then
                            local angle=attempt*2.3999632297
                            local radius=spawnMin+(spawnMax-spawnMin)*((attempt%17)/17)
                            pos=center+util.vector3(math.cos(angle)*radius,math.sin(angle)*radius,0)
                        end
                        local ground=pos and nearby.castRay(pos+util.vector3(0,0,2048),pos-util.vector3(0,0,2048),
                            {collisionType=nearby.COLLISION_TYPE.World+nearby.COLLISION_TYPE.HeightMap})
                        if ground and ground.hit and ground.hitNormal and ground.hitNormal.z>=(relaxed and 0.35 or 0.65)
                            and (not actor.cell.hasWater or ground.hitPos.z>(actor.cell.waterLevel or -100000)+12) then
                            local candidate=ground.hitPos+util.vector3(0,0,8)
                            local clear=not nearby.castRay(candidate+util.vector3(0,0,60),candidate+util.vector3(0,0,220),
                                {radius=relaxed and 25 or 45,collisionType=nearby.COLLISION_TYPE.World+nearby.COLLISION_TYPE.Door+nearby.COLLISION_TYPE.HeightMap}).hit
                            local fromPlayer=candidate-self.position
                            local forward=fromPlayer.x*dir.x+fromPlayer.y*dir.y
                            local separated=clear and fromPlayer:length()>=spawnMin and fromPlayer:length()<=spawnMax+300
                                and (not forwardDirector or forward>spawnMin*0.35)
                            local spacing=relaxed and 80 or 140
                            for _,other in ipairs(nearby.actors) do if (other.position-candidate):length()<spacing then separated=false end end
                            for _,other in ipairs(positions) do if (other-candidate):length()<spacing then separated=false end end
                            if separated then positions[#positions+1]=candidate end
                        end
                    end
                    core.sendGlobalEvent('AshenLoot_SpawnResult',{token=event.token,positions=positions})
                    return
                end
                local options={agentBounds=types.Actor.getPathfindingAgentBounds(actor),includeFlags=nearby.NAVIGATOR_FLAGS.Walk}
                for attempt=1,8 do
                    if #positions>=event.count then break end
                    local pos=nearby.findRandomPointAroundCircle(actor.position,500,options)
                    if pos and (pos-self.position):length()>650 and (pos-actor.position):length()>100 then
                        local hit=nearby.castRay(pos+util.vector3(0,0,80),pos-util.vector3(0,0,120))
                        local clear=not nearby.castRay(pos+util.vector3(0,0,80),pos+util.vector3(0,0,220),{radius=60}).hit
                        if hit.hit and clear then
                            local separated=true
                            for _,other in ipairs(nearby.actors) do if (other.position-pos):length()<150 then separated=false end end
                            for _,other in ipairs(positions) do if (other-pos):length()<150 then separated=false end end
                            if separated then positions[#positions+1]=hit.hitPos+util.vector3(0,0,8) end
                        end
                    end
                end
            end
            core.sendGlobalEvent('AshenLoot_SpawnResult',{token=event.token,positions=positions})
        end,
        AshenLoot_Snapshot = function(data)
            records,elites,forgePoints=data.records,data.elites,data.forgePoints or forgePoints
            renderBook();if forgeWindow then renderForge() end
        end,
        AshenLoot_ForgeResult=function(data) if data and data.message then ui.showMessage(data.message) end end,
        AshenLoot_Record = function(data) records[data.id] = data.metadata end,
        AshenLoot_Elite = function(data) elites[data.id] = data.metadata end,
        AshenLoot_AdvancementList=function(data)
            activeAbilities=data or {};if activeIndex>#activeAbilities then activeIndex=0 end
        end,
        AshenLoot_AdvancementResult=function(data) ui.showMessage(data.message or (data.ok and 'Ability activated.' or 'Ability unavailable.')) end,
        AshenLoot_ApplyAdvancement=function(data)
            local hp=types.Actor.stats.dynamic.health(self);local mp=types.Actor.stats.dynamic.magicka(self)
            local fp=types.Actor.stats.dynamic.fatigue(self)
            hp.current=math.max(1,hp.current-(data.health or 0));mp.current=mp.current-(data.magicka or 0)
            fp.current=fp.current-(data.fatigue or 0)
            if data.target==self then
                types.Actor.activeSpells(self):add{id=data.record,effects=data.indexes,caster=self,stackable=false}
            else
                core.sendGlobalEvent('AshenLoot_ApplyTargetedAdvancement',{record=data.record,indexes=data.indexes,
                    target=data.target,player=self})
            end
            ui.showMessage((data.name or 'Dreamforged ability')..' activated.')
        end,
        FreshLoot_save_modded_records = function(data)
            for _, entry in ipairs(data) do fresh[entry.recordId] = entry.lvlModIds end
            renderBook()
        end,
        FreshLoot_remove_modded_records = function(data) for _, id in ipairs(data) do fresh[id] = nil end end,
    },
}
