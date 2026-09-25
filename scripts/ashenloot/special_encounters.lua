-- Rare, cycle-paced interventions for the outdoor encounter director.
-- "Good Daedra" is the Dunmer religious label for Azura, Boethiah, and
-- Mephala; it describes their place in the faith, not a moral alignment.
local M = {}

-- The roster is data-driven so future special-bucket entries can add more
-- encounter variants without changing the director's selection path.
M.roster = {
    {id='azura', name='Azura', tradition='Good Daedra', encounters={{family='daedra',friendly=true,
        line='I lend you a shadow for this trial. Do not mistake aid for affection.'}}},
    {id='boethiah', name='Boethiah', tradition='Good Daedra', encounters={{family='daedra',
        line='Strength without trial is only a claim. Prove yours in the dust.'}}},
    {id='clavicus_vile', name='Clavicus Vile', encounters={{family='daedra',
        line='A bargain, perhaps: survive my little complication, and we shall speak.'}}},
    {id='hermaeus_mora', name='Hermaeus Mora', encounters={{family='daedra',
        line='A secret has taken shape. Learn what it knows, if you can.'}}},
    {id='hircine', name='Hircine', encounters={{family='beast',
        line='The hunt has found its quarry. Turn, hunter, and earn the name.'}}},
    {id='jyggalag', name='Jyggalag', encounters={{family='construct',
        line='The pattern admits no exception. Be measured, then be overcome.'}}},
    {id='malacath', name='Malacath', encounters={{family='daedra',
        line='The discarded are not forgotten. Face what the strong cast aside.'}}},
    {id='mehrunes_dagon', name='Mehrunes Dagon', encounters={{family='daedra',
        line='All walls fall in time. Let this one be the first to break.'}}},
    {id='mephala', name='Mephala', tradition='Good Daedra', encounters={{family='beast',
        line='A thread was cut. Follow it, and see what waits at the other end.'}}},
    {id='meridia', name='Meridia', encounters={{family='undead',
        line='The unquiet dead trespass upon the living. Return this one to silence.'}}},
    {id='molag_bal', name='Molag Bal', encounters={{family='undead',
        line='Kneel, little soul. First you must survive the hand that closes around you.'}}},
    {id='namira', name='Namira', encounters={{family='undead',
        line='Come closer to what the bright folk fear. There is room in the dark.'}}},
    {id='nocturnal', name='Nocturnal', encounters={{family='daedra',
        line='A shadow has left its hiding place. It is yours to outlast.'}}},
    {id='peryite', name='Peryite', encounters={{family='beast',
        line='Every burden has its proper bearer. Take up the task before you.'}}},
    {id='sanguine', name='Sanguine', encounters={{family='beast',
        line='The revel has grown dull. Give the night something worth remembering.'}}},
    {id='sheogorath', name='Sheogorath', encounters={{family='all',
        line='I misplaced a perfectly good monster. Do be a dear and find it.'}}},
    {id='vaermina', name='Vaermina', encounters={{family='undead',
        line='You woke before the ending. Let us see if you can do so again.'}}},
    {id='ithelia', name='Ithelia', encounters={{family='all',
        line='Another path briefly opens. This one has teeth; choose what comes next.'}}},
    {id='vivec', name='Vivec', encounters={{family='daedra',
        line='A verse is unfinished. Answer its violence with your own.'}}},
}

local byId = {}
for _, prince in ipairs(M.roster) do byId[prince.id] = prince end

-- The three opportunities are tied to the ongoing World Boss arc, not cells
-- or individual spawns. A failed chance still consumes that stage; at most
-- three special events can occur before the cycle closes.
local thresholds = {15, 45, 75}
function M.tryOpportunity(outdoor, progress, chance, rng)
    local stage = math.max(0, math.floor(tonumber(outdoor.specialStage) or 0)) + 1
    if stage > #thresholds or (tonumber(progress) or 0) < thresholds[stage] then
        return nil, false
    end
    outdoor.specialStage = stage
    chance = math.max(0, math.min(100, tonumber(chance) or 0))
    if rng(100) > chance then return nil, true end
    local prince = M.roster[rng(#M.roster)]
    local encounter = prince.encounters[rng(#prince.encounters)]
    return {id=prince.id, name=prince.name, family=encounter.family,
        line=encounter.line, friendly=encounter.friendly, tradition=prince.tradition}, true
end

function M.get(id)
    local prince = byId[id]
    if not prince then return nil end
    local encounter = prince.encounters[1]
    if not encounter then return nil end
    return {id=prince.id,name=prince.name,family=encounter.family,
        line=encounter.line,friendly=encounter.friendly,tradition=prince.tradition}
end

return M
