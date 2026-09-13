local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local core = require('openmw.core')
local menu = require('openmw.menu')
local calls, controls = {}, nil
local elapsed, stage = 0, 0
-- Wrap the installed native renderers; retain their real menu setter callbacks.
require('scripts.omw.settings.renderers')(function(name, render)
    I.Settings.registerRenderer(name, function(value, set, argument)
        calls[#calls + 1] = {name = name, value = value, set = set, argument = argument}
        if name == 'select' and argument and argument.l10n == 'AshenLoot'
                and argument.items[1] == 'F6' then
            controls = {}
            for n = 1, 9 do controls[n] = calls[#calls - 9 + n] end
        end
        return render(value, set, argument)
    end)
end)
local keys = {'enabled', 'preset', 'elitePercent', 'dropPercent', 'settleSeconds',
    'protectQuestActors', 'allowRespawningNPCs', 'showTargetCard', 'inventoryKey'}
local original = {true, 'Balanced', 30, 50, 2, true, false, true, 'F8'}
local changed = {false, 'Custom', 73, 81, 3, false, true, false, 'F9'}
return {engineHandlers = {onFrame = function(dt)
    if menu.getState() ~= menu.STATE.Running or stage == 3 then return end
    elapsed = elapsed + dt
    local ok, err = pcall(function()
        if stage == 0 and elapsed > 1 then
            assert(controls, 'Ashen Loot key selector was not rendered')
            for n, control in ipairs(controls) do
                assert(control.value == original[n], 'Wrong initial UI value for ' .. keys[n])
            end
            for _, call in ipairs(calls) do
                assert(call.value ~= nil, 'Menu rendered a nil setting')
            end
            for n, control in ipairs(controls) do control.set(changed[n]) end
            stage = 1
        elseif stage == 1 and elapsed > 2 then
            for n, key in ipairs(keys) do
                assert(storage.globalSection('SettingsAshenLoot'):get(key) == changed[n],
                    'Menu setter did not update global ' .. key)
            end
            for n, control in ipairs(controls) do control.set(original[n]) end
            stage = 2
        elseif stage == 2 and elapsed > 3 then
            for n, key in ipairs(keys) do
                assert(storage.globalSection('SettingsAshenLoot'):get(key) == original[n],
                    'Menu setter did not restore ' .. key)
            end
            print('[AshenLoot SETTINGS] PASS: native menu defaults, all toggles, numbers, preset and F8/F9 selector setters')
            stage = 3
        end
    end)
    if not ok then print('[AshenLoot SETTINGS] FAIL: ' .. tostring(err)); stage = 3; core.quit() end
end}}
