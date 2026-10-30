-- Dungeon archetypes: depth chooses a species; progression.lua owns stat scaling.
local types=require('openmw.types')
local world=require('openmw.world')
local themes=require('scripts.ashenloot.delve_enemies')
local M={}
local pools,byId,savedData
function M.bind(getData) savedData=getData;pools=nil;byId=nil end
local function contains(text,words)
    for _,word in ipairs(words) do if text:find(word,1,true) then return true end end
    return false
end
local function safe(rec)
    if not rec then return false,'missing record' end
    if rec.mwscript or rec.isEssential or not rec.canWalk then return false,'scripted/protected/nonwalking' end
    for _,v in pairs(rec.servicesOffered or {}) do if v then return false,'services' end end
    return true
end
function M.classify(rec,listed)
    local ok,reason=safe(rec);if not ok then return nil,reason end
    local id=rec.id:lower()
    if themes.nativeIds[id] or id:find('df_',1,true)==1 or id:find('generated:',1,true)==1 or id:find('$',1,true) then return nil,'native/private/generated' end
    local raw=(id..' '..(rec.model or '')..' '..(rec.name or '')):lower()
    local text=raw:gsub('[ _%-]','')
    local words=' '..raw:gsub('[^%w]',' ')..' '
    if words:find(' dead ',1,true) or words:find(' pet ',1,true)
        or contains(text,{'unique','quest','summon','corpse','packguar','tame','domestic','friendly','peaceful','companion','caravan','merchant','siltstrider'}) then return nil,'noncombat or special actor' end
    if id:find('_q_',1,true) or id:find('_uni',1,true) then return nil,'quest/unique record tag' end
    -- Respawn flags are often inherited by named pets and hand-placed quest
    -- variants. Require an actual population-list reference for optional content.
    if not listed then return nil,'not in a creature population list' end
    local theme
    if rec.type==types.Creature.TYPE.Undead then theme=2
    elseif rec.type==types.Creature.TYPE.Daedra then theme=4
    elseif contains(text,{'centurion','dwemer','dwarven','animuncul'}) then theme=3
    elseif rec.type==types.Creature.TYPE.Creatures and contains(text,{'rat','kwama','nix','alit','kagouti','shalk','scrib','hound','wolf','bear','boar','spider','beetle','centipede','scorpion','worm','dreugh','crab','lizard','reptile','durzog','grahl'}) then theme=1
    end
    if not theme then return nil,'unknown theme' end
    local attack=0
    for i,v in ipairs(rec.attack or {}) do if i%2==0 then attack=math.max(attack,v) end end
    local skill=math.max(rec.combatSkill or 0,rec.magicSkill or 0,rec.stealthSkill or 0)
    local level=math.max(1,math.min(100,math.floor(0.5+math.max((skill-15)/3.2,attack/1.4,math.sqrt(rec.soulValue or 0)*1.4))))
    return theme,level
end
local function build()
    if pools then return end
    pools={};byId={}
    for theme,definition in ipairs(themes) do
        pools[theme]={ordinary={},boss={},optional={}}
        for _,role in ipairs({'ordinary','boss'}) do
            for _,id in ipairs(definition[role]) do
                local ok,reason=safe(types.Creature.records[id])
                if ok then
                    local e={id=id,level=assert(definition.levels[id]),theme=theme,optional=false}
                    pools[theme][role][#pools[theme][role]+1]=e;byId[id]=e
                else print('[Dreamforged Delve] rejected '..id..': '..reason) end
            end
            assert(#pools[theme][role]>0,'Missing dungeon '..role..' pool for '..definition.name..'; reinstall matching Dreamforged-Delve.esp')
        end
    end
    local listed={}
    -- Inspect all lists, including nested-list definitions, without expanding cycles.
    for _,list in pairs(types.LevelledCreature.records) do
        for _,e in ipairs(list.creatures or {}) do listed[e.id:lower()]=true end
    end
    for _,rec in pairs(types.Creature.records) do
        local theme,level=M.classify(rec,listed[rec.id:lower()])
        if theme then
            local e={id=rec.id,theme=theme,level=level,optional=true}
            pools[theme].optional[#pools[theme].optional+1]=e;byId[e.id]=e
        end
    end
    for theme,pool in ipairs(pools) do
        table.sort(pool.optional,function(a,b)return a.id<b.id end)
        print('[Dreamforged Delve] '..themes[theme].name..' optional archetypes: '..#pool.optional)
    end
    for source,id in pairs(savedData and savedData().optionalRecords or {}) do
        if byId[source] and types.Creature.records[id] then byId[id]=byId[source] end
    end
end
function M.target(depth,boss)
    -- Absolute depth keeps progressing when palettes cycle. Player/gear level
    -- still controls prepared stats; it does not skip the opening archetypes.
    return 1+0.75*(math.max(1,depth or 1)-1)+(boss and 4 or 0)
end
local function band(pool,target,nearest)
    local result={};local distance,best=math.huge,nil
    for _,e in ipairs(pool) do
        if e.level>=target*0.55 and e.level<=target+math.max(2,target*0.25) then result[#result+1]=e end
        local d=math.abs(e.level-target)
        if d<distance or (d==distance and best and e.level>best.level) then distance,best=d,e end
    end
    -- Exhausted native themes retain their closest strong archetype, rather than
    -- resetting to rats or borrowing an unrelated creature at extreme depth.
    if #result==0 and nearest and best then result[1]=best end
    return result
end
local function weighted(pool,target,rng)
    local total=0
    for _,e in ipairs(pool) do total=total+1/(1+math.abs(e.level-target)) end
    local pick=rng()*total
    for _,e in ipairs(pool) do
        pick=pick-1/(1+math.abs(e.level-target));if pick<=0 then return e end
    end
    return pool[#pool]
end
function M.choose(theme,boss,rng,depth,allowOptional)
    build();local pool=assert(pools[theme],'Unknown dungeon theme '..tostring(theme))
    local target=M.target(depth,boss)
    local candidates=band(pool[boss and 'boss' or 'ordinary'],target,true)
    -- Native boss identity stays curated. Mod creatures supplement ordinary
    -- encounters at a bounded rate, regardless of how many mods are installed.
    local optional=not boss and allowOptional~=false and band(pool.optional,target,false) or {}
    if #optional>0 and rng(100)<=25 then candidates=optional end
    local entry=weighted(candidates,target,rng)
    return entry.id,entry
end
function M.describe(id) build();return byId[id] end
function M.catalog() build();return pools end
function M.recordId(entry)
    if not entry.optional then return entry.id end
    build()
    local d=assert(savedData,'Dungeon selection not bound')()
    d.optionalRecords=d.optionalRecords or {}
    local id=d.optionalRecords[entry.id]
    if not id or not types.Creature.records[id] then
        -- Preserve mod visuals, stats, spells and inventory, but give the dungeon
        -- its own nonrespawning identity and save-controlled lifetime.
        id=world.createRecord(types.Creature.createRecordDraft{
            template=types.Creature.records[entry.id],isRespawning=false,isEssential=false,
        }).id
        d.optionalRecords[entry.id]=id
    end
    byId[id]=entry
    return id
end
return M
