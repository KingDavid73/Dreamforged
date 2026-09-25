-- Original, short captions for the director. "The Dream" is Dreamforged's
-- interpretation of Morrowind's dream imagery, not a canonical speaking NPC.
local R = require('scripts.ashenloot.rules')
local M = {}

local lines = {
    roam = {
        {'The Dream', 'The road is quiet. I would not call it empty.'},
        {'The Dream', 'Every footstep gives the next moment somewhere to stand.'},
        {'The Dream', 'The ash has settled. For now.'},
        {'The Dream', 'A little silence is part of the music, traveler.'},
        {'The Dream', 'You have walked far enough for the world to notice.'},
        {'Dagoth Ur', 'You travel boldly, old friend. I wonder who taught you such confidence.'},
        {'Dagoth Ur', 'Even the smallest road may lead to Red Mountain.'},
        {'Dagoth Ur', 'Take your ease. I have not asked the land to rise against you. Yet.'},
    },
    rising = {
        {'The Dream', 'The paths ahead are beginning to gather.'},
        {'The Dream', 'Your victories have disturbed the pattern. Watch the road.'},
        {'The Dream', 'The small things have fallen. Something larger remembers.'},
        {'The Dream', 'The air grows crowded with unfinished choices.'},
        {'The Dream', 'A storm need not begin with thunder.'},
        {'The Dream', 'The one beneath Red Mountain asks for harsher trials. I have not refused him.'},
        {'Dagoth Ur', 'You have had your measure of lesser foes. Shall we try another?'},
        {'Dagoth Ur', 'The sleepers stir when you pass. Do you hear them?'},
        {'Dagoth Ur', 'I see your courage. I have other tests for it.'},
        {'Dagoth Ur', 'The Dream lends me its roads, old friend. Let us see where they lead.'},
    },
    imminent = {
        {'The Dream', 'There is a weight ahead of you. It has begun to move.'},
        {'The Dream', 'The next name has not yet been spoken, but it is near.'},
        {'The Dream', 'Keep what strength you can. A greater shape approaches.'},
        {'The Dream', 'The road narrows, though no stone has moved.'},
        {'Dagoth Ur', 'A worthy adversary is coming. Let us see what you make of one another.'},
        {'Dagoth Ur', 'You wanted a trial, old friend. I have heard you.'},
        {'Dagoth Ur', 'There is an hour for boasting and an hour for battle. Which is this?'},
    },
    dungeon = {
        {'The Dream', 'Stone keeps its own account of those who enter.'},
        {'The Dream', 'Here, even a whisper must find its way out.'},
        {'The Dream', 'The dead do not own this place merely because they stayed.'},
        {'Dagoth Ur', 'You have come beneath the earth again. We have that much in common.'},
        {'Dagoth Ur', 'A ruin is a patient thing. Are you?'},
    },
    group = {
        {'Dagoth Ur', 'The road has sent you company, old friend. Let us see what you make of it.'},
        {'Dagoth Ur', 'I have set another trial in your path. Do not mistake it for a gift.'},
        {'Dagoth Ur', 'Your passage has awakened a few old hungers. Attend to them.'},
        {'Dagoth Ur', 'More challengers approach. I would hate for you to grow complacent.'},
        {'Dagoth Ur', 'The land has answered your footsteps. Answer it in turn.'},
        {'Dagoth Ur', 'You have drawn an audience, old friend. Try not to disappoint it.'},
    },
    promotion = {
        {'Dagoth Ur', 'A sharper piece has entered the game: {enemy}, {tier}. Show me whether your edge is true.'},
        {'Dagoth Ur', 'I have raised the stakes with {enemy}. A {tier} is more than a name, old friend.'},
        {'Dagoth Ur', 'The lesser trial has changed its face. {enemy} now bears the mark of a {tier}.'},
        {'Dagoth Ur', 'Do not hurry past {enemy}. The {tier} has been given a little more of my attention.'},
    },
    promotedKill = {
        {'Dagoth Ur', 'You have unmade {enemy}, a {tier}. I had hoped it would make you work harder.'},
        {'Dagoth Ur', 'Well met, old friend. The {tier} called {enemy} will trouble you no more.'},
        {'Dagoth Ur', 'That {tier} has fallen. Take the breath you have earned; I will find another test.'},
        {'Dagoth Ur', 'You have answered {enemy} with steel and will. I am listening.'},
    },
    den = {
        {'Dagoth Ur', 'Something rooted has begun to breed trouble. Find its source, old friend.'},
        {'Dagoth Ur', 'The nest will keep its own counsel until you silence it.'},
        {'Dagoth Ur', 'The earth has given this place a mouth. You may wish to close it.'},
    },
    boss = {
        {'Dagoth Ur', 'Come, old friend. {enemy} is eager to meet you.'},
        {'Dagoth Ur', 'I have named your adversary {enemy}. Let battle decide what the name is worth.'},
        {'Dagoth Ur', 'The lesser trials are done. {enemy} waits ahead.'},
        {'Dagoth Ur', 'Behold {enemy}. I trust you have not mistaken patience for mercy.'},
        {'Dagoth Ur', 'A greater shape has entered the dream: {enemy}. Meet it without fear.'},
        {'Dagoth Ur', 'You asked the world to answer. It answers now as {enemy}.'},
    },
    bossVictory = {
        {'Dagoth Ur', 'Well struck, old friend. {enemy} was not enough. I shall remember that.'},
        {'Dagoth Ur', 'A worthy contest. Take what was won and enjoy the silence you earned.'},
        {'Dagoth Ur', 'You have unmade {enemy}. Even the mountain must take note.'},
        {'Dagoth Ur', 'The great shape has fallen. I will not begrudge you this breath.'},
        {'Dagoth Ur', 'You have surprised me again. Such persistence deserves a finer trial.'},
        {'Dagoth Ur', 'I thought {enemy} would keep you longer. The dream is full of surprises.'},
    },
    victory = {
        {'Dagoth Ur', '{enemy} gave you a proper fight, I hope.'},
        {'Dagoth Ur', 'A worthy stroke against {enemy}. There will be others.'},
        {'Dagoth Ur', 'You have taken the measure of {enemy}. Do not grow proud of it.'},
        {'Dagoth Ur', 'The path opens a little wider. I am sure you will find another way to trouble it.'},
        {'Dagoth Ur', 'One name less upon the road: {enemy}. The road is not yet empty.'},
    },
    barren = {
        {'Dagoth Ur', '{enemy} left little behind. Not every trial pays in silver or steel.'},
        {'Dagoth Ur', 'A hard-won silence, and little else. Such is the road, old friend.'},
        {'Dagoth Ur', 'No prize this time. The next wager may be kinder, or more costly.'},
    },
    prize = {
        {'Dagoth Ur', '{item} is a dangerous prize, old friend. I look forward to seeing it tested.'},
        {'Dagoth Ur', 'A fine relic: {item}. Such things have a way of summoning their own trials.'},
        {'Dagoth Ur', 'Keep {item} close. Worthy things invite worthy adversaries.'},
        {'Dagoth Ur', 'The dream has yielded {item}. Let us see whether you are worthy of it.'},
        {'Dagoth Ur', 'That {item} may change the course of your next battle. I should not like to disappoint it.'},
    },
    relicPrize = {
        {'Dagoth Ur', 'A relic: {item}. Such power is never quiet for long, old friend.'},
        {'Dagoth Ur', 'You found {item}. Keep it close; I would see what it makes of you.'},
        {'Dagoth Ur', 'The dream has yielded {item}. A rare answer, and a more dangerous question.'},
    },
    mythicPrize = {
        {'Dagoth Ur', 'A mythic thing: {item}. Now the dream has given us something worth fearing.'},
        {'Dagoth Ur', 'You hold {item}, old friend. I will not pretend I am unmoved.'},
        {'Dagoth Ur', '{item} has found its way into your hands. Let us see what power recognizes power.'},
    },
    bossMythic = {
        {'Dagoth Ur', 'You have felled {enemy} and claimed {item}. This dream has become interesting again.'},
        {'Dagoth Ur', 'A World Boss falls, and {item} is yours. I shall have to answer in kind.'},
        {'Dagoth Ur', '{enemy} is gone; {item} remains. Enjoy this victory, old friend. It will not be the last.'},
    },
    commonKill = {
        {'The Dream', 'Another {kind} falls. The road remains hungry.'},
        {'The Dream', 'A small victory is still a victory.'},
        {'Dagoth Ur', 'A {kind}, was it? You have not exhausted my imagination.'},
        {'Dagoth Ur', 'Even such small foes have their place in a trial.'},
    },
    sleep = {
        {'The Dream', 'You slept behind safe walls. The road will wait for you.'},
        {'The Dream', 'Rest was wise. Begin again when you are ready.'},
        {'Dagoth Ur', 'Sleep well, old friend. Dreams are not always an escape.'},
    },
}

local pressureThresholds={25,50,75}
local pressureLines={
    [1]={
        'The dream stirs at the edge of your path. Something has begun to take notice.',
        'The pattern shifts by a little. You are not yet near its center.',
        'A faint pressure gathers beneath the quiet. Keep walking, and it will gather shape.',
    },
    [2]={
        'The dream advances. Lesser trials have left their mark; a sterner answer is forming.',
        'The road remembers each small victory. Something greater is learning your name.',
        'Half the silence is spent. The next shape in the dream will not be so easily dismissed.',
    },
    [3]={
        'The dream draws near to its reckoning. Gather your strength; a great trial is taking form.',
        'The pattern is almost complete. Even the ash seems to wait for what comes next.',
        'You have brought the dream to its threshold. Soon it will answer you without disguise.',
    },
}

function M.pressureStage(value)
    local pressure=math.max(0,tonumber(value) or 0)
    local stage=0
    for index,threshold in ipairs(pressureThresholds) do
        if pressure>=threshold then stage=index else break end
    end
    return stage
end

-- Status messages are milestone-driven, not random chatter. A nonzero voice
-- setting guarantees each crossed threshold is eventually reported; zero
-- remains a complete mute switch.
function M.emitPressure(state,config,player,now,pressure,stage)
    local frequency=math.max(0,math.min(100,tonumber(config.directorVoiceFrequency) or 0))
    if not config.enabled or frequency<=0 or not player or not player:isValid() then return false end
    stage=math.max(0,math.min(#pressureThresholds,math.floor(tonumber(stage) or M.pressureStage(pressure))))
    if stage<=0 then return false end
    local voice=state.voice or {lastAt=-1000,lastByKind={},lastIndex={},serial=0}
    state.voice=voice
    voice.lastByKind=voice.lastByKind or {};voice.lastIndex=voice.lastIndex or {}
    if now-(voice.lastAt or -1000)<8 then return false end
    local pool=pressureLines[stage]
    local rng=R.rng(tostring(math.floor(now))..':'..stage..':dream-pressure')
    local index=rng(#pool)
    if #pool>1 and index==voice.lastPressureIndex then index=index%#pool+1 end
    voice.lastPressureIndex=index
    voice.lastAt=now;voice.lastByKind.pressure=now
    player:sendEvent('AshenLoot_DirectorVoice',{
        speaker='The Dream',text=pool[index],duration=8})
    return true
end

local function clean(value, fallback)
    local s=tostring(value or fallback or ''):gsub('[\r\n\t]', ' '):gsub('%s+', ' ')
    if #s>72 then s=s:sub(1,69)..'...' end
    return s
end

function M.render(kind, seed, values, previous)
    local pool=lines[kind]
    if not pool then return nil end
    local rng=R.rng(tostring(seed or '')..':voice:'..kind)
    local index=rng(#pool)
    if #pool>1 and index==previous then index=index%#pool+1 end
    local choice=pool[index]
    local content=choice[2]:gsub('{(%w+)}',function(key)
        return clean(values and values[key], key=='item' and 'the prize' or 'the foe')
    end)
    return {speaker=choice[1],text=content,index=index,kind=kind}
end

function M.emit(state, config, player, now, kind, values, important)
    local frequency=math.max(0,math.min(100,tonumber(config.directorVoiceFrequency) or 0))
    if not config.enabled or frequency<=0 or not player or not player:isValid() then return false end
    local voice=state.voice or {lastAt=-1000,lastByKind={},lastIndex={},serial=0}
    state.voice=voice
    voice.lastByKind=voice.lastByKind or {};voice.lastIndex=voice.lastIndex or {}
    local gap=important and 8 or math.max(20,95-frequency*0.75)
    if now-(voice.lastAt or -1000)<gap or now-(voice.lastByKind[kind] or -1000)<(important and 12 or 70) then return false end
    voice.serial=(voice.serial or 0)+1
    local seed=tostring(math.floor(now))..':'..voice.serial..':'..clean(values and values.enemy,'')
    local rng=R.rng(seed..':chance')
    local chance=important and 100 or (kind=='roam' or kind=='dungeon') and frequency*0.38
        or (kind=='commonKill' and frequency*0.25 or frequency*0.7)
    if rng(100)>chance then return false end
    local line=M.render(kind,seed,values,voice.lastIndex[kind])
    if not line then return false end
    voice.lastAt=now;voice.lastByKind[kind]=now;voice.lastIndex[kind]=line.index
    player:sendEvent('AshenLoot_DirectorVoice',{speaker=line.speaker,text=line.text,duration=7})
    return true
end

-- Event-specific odds are easier for players to reason about than one global
-- chatter roll. At the default voice setting (60), baseChance is the actual
-- chance; the setting scales it up/down and zero remains a mute switch.
function M.emitChance(state,config,player,now,kind,values,baseChance)
    local frequency=math.max(0,math.min(100,tonumber(config.directorVoiceFrequency) or 0))
    if not config.enabled or frequency<=0 or not player or not player:isValid() then return false end
    local chance=math.max(0,math.min(100,
        (tonumber(baseChance) or 0)*(frequency/60)))
    local voice=state.voice or {lastAt=-1000,lastByKind={},lastIndex={},serial=0}
    state.voice=voice
    voice.lastByKind=voice.lastByKind or {};voice.lastIndex=voice.lastIndex or {}
    voice.serial=(voice.serial or 0)+1
    local seed=tostring(math.floor(now))..':'..voice.serial..':'..clean(values and values.enemy,'')
    if R.rng(seed..':event-chance')(100)>chance then return false end
    local line=M.render(kind,seed,values,voice.lastIndex[kind])
    if not line then return false end
    voice.lastAt=now;voice.lastByKind[kind]=now;voice.lastIndex[kind]=line.index
    player:sendEvent('AshenLoot_DirectorVoice',{
        speaker=line.speaker,text=line.text,duration=7})
    return true
end

-- A special encounter already passed its own director roll, so do not put a
-- second random gate or ordinary chatter cooldown between that event and its
-- line. The existing frequency switch still cleanly silences all captions.
function M.emitSpecial(state, config, player, now, encounter)
    local frequency=math.max(0,math.min(100,tonumber(config.directorVoiceFrequency) or 0))
    if not config.enabled or frequency<=0 or not player or not player:isValid()
        or not encounter or not encounter.name or not encounter.line then return false end
    local voice=state.voice or {lastAt=-1000,lastByKind={},lastIndex={},serial=0}
    state.voice=voice
    voice.lastAt=now
    voice.lastByKind.special=now
    player:sendEvent('AshenLoot_DirectorVoice',{
        speaker=encounter.name,text=encounter.line,duration=8})
    return true
end

M.lines=lines
M.pressureLines=pressureLines
return M
