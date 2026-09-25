-- Rare, cycle-paced interventions for the outdoor encounter director.
-- "Good Daedra" is the Dunmer religious label for Azura, Boethiah, and
-- Mephala; it describes their place in the faith, not a moral alignment.
local M = {}

-- The roster is data-driven so future special-bucket entries can add more
-- encounter variants without changing the director's selection path.
M.roster = {
    {id='azura', name='Azura', tradition='Good Daedra', encounters={{family='daedra',friendly=true,
        line='The dusk has turned, and so may your fortune. Take this aid; remember whose star guides it.'}}},
    {id='boethiah', name='Boethiah', tradition='Good Daedra', encounters={{family='daedra',
        line='A borrowed victory teaches nothing. Face this trial with your own strength, or be remade by it.'}}},
    {id='clavicus_vile', name='Clavicus Vile', encounters={{family='daedra',
        line='A modest complication, with a most reasonable price. You need only survive it.'}}},
    {id='hermaeus_mora', name='Hermaeus Mora', encounters={{family='daedra',
        line='A fragment of hidden knowledge stirs nearby. Pry it from the silence, if you must.'}}},
    {id='hircine', name='Hircine', encounters={{family='beast',
        line='The chase is joined. Let the quarry turn hunter, and let the stronger claim the trail.'}}},
    {id='jyggalag', name='Jyggalag', encounters={{family='construct',
        line='The pattern is exact. An irregularity has been placed before you; resolve it.'}}},
    {id='malacath', name='Malacath', encounters={{family='daedra',
        line='The oath-breaker and the outcast are not forgotten. Stand against what the proud cast away.'}}},
    {id='mehrunes_dagon', name='Mehrunes Dagon', encounters={{family='daedra',
        line='Destruction opens the road that fear would close. Break what stands between you and change.'}}},
    {id='mephala', name='Mephala', tradition='Good Daedra', encounters={{family='beast',
        line='A thread has been drawn across your path. Follow it carefully; every web has another side.'}}},
    {id='meridia', name='Meridia', encounters={{family='undead',
        line='The dead defile the life that was granted. Drive this corruption from the world.'}}},
    {id='molag_bal', name='Molag Bal', encounters={{family='undead',
        line='Every will can be bent. Let this servant test how long yours resists.'}}},
    {id='namira', name='Namira', encounters={{family='undead',
        line='The discarded things of the world still hunger. Go on, meet what the bright ones refuse to see.'}}},
    {id='nocturnal', name='Nocturnal', encounters={{family='daedra',
        line='The shadow keeps what the careless lose. Something has stepped from it; chance is yours now.'}}},
    {id='peryite', name='Peryite', encounters={{family='beast',
        line='The smallest order must be maintained. Attend to this disorder, and do not shirk your part.'}}},
    {id='sanguine', name='Sanguine', encounters={{family='beast',
        line='A celebration without risk is a dreary thing. Let us give this evening a story.'}}},
    {id='sheogorath', name='Sheogorath', encounters={{family='all',
        line='The cheese has filed a complaint, and the consequence has teeth. This is probably related.'}}},
    {id='vaermina', name='Vaermina', encounters={{family='undead',
        line='The nightmare has found a shape beyond sleep. Do not expect waking to make it harmless.'}}},
    {id='ithelia', name='Ithelia', encounters={{family='all',
        line='A path that was not has opened. Its ending is not fixed, though something waits along it.'}}},
    {id='vivec', name='Vivec', encounters={{family='daedra',
        line='The warrior-poet leaves a verse unfinished: one hand offers the road, the other its trial. Choose by walking.'}}},
}

local byId = {}
for _, prince in ipairs(M.roster) do byId[prince.id] = prince end

-- Opportunities are spaced between the Dream's pressure warnings and tied to
-- the ongoing World Boss arc, not cells or individual spawns. A failed chance
-- still consumes its stage; successful interventions are capped at three.
local thresholds = {15, 30, 45, 60, 75, 90}
function M.tryOpportunity(outdoor, progress, chance, rng)
    local stage = math.max(0, math.floor(tonumber(outdoor.specialStage) or 0)) + 1
    if stage > #thresholds or (tonumber(progress) or 0) < thresholds[stage] then
        return nil, false
    end
    outdoor.specialStage = stage
    if (tonumber(outdoor.specialCount) or 0) >= 3 then return nil, true, false end
    chance = math.max(0, math.min(100, tonumber(chance) or 0))
    if rng(100) > chance then return nil, true, true end
    local prince = M.roster[rng(#M.roster)]
    local encounter = prince.encounters[rng(#prince.encounters)]
    outdoor.specialCount = (tonumber(outdoor.specialCount) or 0) + 1
    return {id=prince.id, name=prince.name, family=encounter.family,
        line=encounter.line, friendly=encounter.friendly, tradition=prince.tradition}, true, false
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
