local I=require('openmw.interfaces')
local core=require('openmw.core')
local ui=require('openmw.ui')
local async=require('openmw.async')

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
        -- Defer the bulk write to the GLOBAL script's next update tick. A
        -- menu click that writes dozens of settings while the native page is
        -- rebuilding can invalidate the section layout and hide its buttons.
        core.sendGlobalEvent('Dreamforged_ResetSettings')
    end)}
    return button
end)

return {}
