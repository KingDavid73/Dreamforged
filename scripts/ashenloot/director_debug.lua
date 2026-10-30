-- Shared HUD text makes context-specific metrics independently testable.
local M={}
function M.lines(data)
    local lines={'DREAMFORGED DIRECTOR DEBUG','Context: '..tostring(data.contextLabel or 'Waiting')}
    if data.cellName then lines[#lines+1]=data.cellName end
    if data.context=='wilderness' then
        lines[#lines+1]=string.format('Pressure %d%% | Boss cycle %d%% | %s',
            math.floor(math.max(0,math.min(100,tonumber(data.pressure) or 0))),math.floor(math.max(0,math.min(100,tonumber(data.cycle) or 0))),tostring(data.phase or 'build'))
    elseif data.context=='delve' then
        if data.depth then
            lines[#lines+1]=string.format('Depth %d | Enemies %d/%d | Waves %d',data.depth,data.alive or 0,data.cap or 8,data.waves or 0)
            lines[#lines+1]=string.format('Guardian: %s | Adds %d/%d',data.guardian or 'not scheduled',data.adds or 0,data.addCap or 4)
            if data.countdown then lines[#lines+1]=string.format('Next %s check: %ds',data.countdownKind or 'wave',data.countdown) end
        end
    elseif data.context=='interior_hostile' then
        lines[#lines+1]='Interior additions tracked: '..tostring(data.additions or 0)
    end
    lines[#lines+1]='State: '..tostring(data.status or 'Waiting')
    if data.detail and data.detail~='' then lines[#lines+1]=data.detail end
    if data.lastAction and data.lastAction~='' then lines[#lines+1]='Last: '..data.lastAction end
    return lines
end
return M
