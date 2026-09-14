local I=require('openmw.interfaces')
local core=require('openmw.core')
local ui=require('openmw.ui')
local async=require('openmw.async')
local storage=require('openmw.storage')
local C=require('scripts.ashenloot.config')

I.Settings.registerRenderer('dreamforgedReset',function()
    local button={
        template=I.MWUI.templates.box,
        content=ui.content{{
            template=I.MWUI.templates.padding,
            content=ui.content{{template=I.MWUI.templates.textNormal,
                props={text=core.l10n('AshenLoot')('resetAllSettingsButton')}}},
        }},
    }
    button.events={mouseClick=async:callback(function()
        for key,value in pairs(C.defaults) do
            storage.globalSection(C.groupKey(key)):set(key,value)
        end
    end)}
    return button
end)

return {}
