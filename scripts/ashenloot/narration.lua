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
        {'The Dream', 'The road has acquired company.'},
        {'The Dream', 'The next encounter is already finding its feet.'},
        {'The Dream', 'The quiet ahead has begun to move.'},
        {'Dagoth Ur', 'I would not travel alone just now, old friend.'},
        {'Dagoth Ur', 'Some new faces are making their way to you.'},
        {'Dagoth Ur', 'You have drawn an audience. Try not to disappoint it.'},
    },
    den = {
        {'The Dream', 'Something rooted has begun to breed trouble ahead.'},
        {'The Dream', 'The road has grown a nest. It will not empty itself.'},
        {'The Dream', 'Find the source, or the company will keep coming.'},
        {'Dagoth Ur', 'A nest is a patient adversary. You may wish to be less patient.'},
        {'Dagoth Ur', 'The earth is lending me soldiers now.'},
    },
    boss = {
        {'The Dream', '{enemy} has taken shape ahead. The road is no longer quiet.'},
        {'The Dream', 'A name gathers around the danger: {enemy}.'},
        {'The Dream', 'The lesser voices fall silent. {enemy} is near.'},
        {'The Dream', 'He asked for a champion. I gave him {enemy}.'},
        {'Dagoth Ur', 'Come, old friend. {enemy} is eager to meet you.'},
        {'Dagoth Ur', 'I have set no crown upon {enemy}. Let battle decide the title.'},
        {'Dagoth Ur', 'Behold {enemy}. I trust you came prepared.'},
    },
    bossVictory = {
        {'The Dream', '{enemy} is ended. The road may breathe again.'},
        {'The Dream', 'You have unmade {enemy}. Even the ash remembers.'},
        {'The Dream', 'The great shape has fallen. Take the quiet it leaves.'},
        {'Dagoth Ur', 'Well struck. {enemy} was not enough. I shall remember that.'},
        {'Dagoth Ur', 'A fine contest, old friend. Enjoy what you have won.'},
        {'Dagoth Ur', 'You have earned a little peace. I will not begrudge it.'},
        {'Dagoth Ur', 'The Dream and I misjudged you. That is interesting.'},
    },
    victory = {
        {'The Dream', '{enemy} falls, and the path opens a little wider.'},
        {'The Dream', 'One name less upon the road: {enemy}.'},
        {'The Dream', 'That was no ordinary {kind}. You knew it by the end.'},
        {'Dagoth Ur', '{enemy} gave you a proper fight, I hope.'},
        {'Dagoth Ur', 'A worthy stroke against {enemy}. There will be others.'},
    },
    barren = {
        {'The Dream', '{enemy} left no treasure worth the telling. The story continues.'},
        {'The Dream', 'A hard-won silence, and little else. Such is the road.'},
        {'The Dream', 'Not every fallen foe leaves a gift.'},
        {'Dagoth Ur', 'You bested {enemy} for so little? A cruel bargain.'},
        {'Dagoth Ur', 'No prize from {enemy}. Perhaps your next wager will fare better.'},
    },
    prize = {
        {'The Dream', '{item} has found its way to you. The world must answer.'},
        {'The Dream', 'A fine prize: {item}. Its tale has only begun.'},
        {'The Dream', 'You carry {item} now. Other hands will remember it.'},
        {'Dagoth Ur', '{item}? A dangerous gift. I look forward to its use.'},
        {'Dagoth Ur', 'That {item} suits you. I shall send a reason to draw it.'},
        {'Dagoth Ur', 'Keep {item} close, old friend. Worthy things invite worthy trials.'},
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

M.lines=lines
return M
