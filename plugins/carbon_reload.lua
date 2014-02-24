PLUGIN.Title = 'Carbon Reload'
PLUGIN.Description = 'carbon reload module'
PLUGIN.Version = '0.0.1a'
PLUGIN.Author = 'Mischa & CareX'

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:Init | http://wiki.rustoxide.com/index.php?title=Hooks/Init
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:Init()
    self:AddChatCommand('reload', self.cmdReload)
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- Testing plugin reload!
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function reloadCarbon(carbon)
    reloadtoken = timer.Once(3,function() reloadtoken = nil  end)
    print('Carbon reloader initiated.. .')
    cs.reloadplugin(carbon)
    local cplugin = plugins.Find(carbon)
    if cplugin then
        cplugin:Init()
        if cplugin.PostInit then cplugin:PostInit() end
    else
        return false, 'Failed to reload carbon'
    end
    print('Carbon reloader complete.')
    return true, 'Carbon reloaded'
end

function PLUGIN:cmdReload( netuser )
    if not reloadtoken then
        local b, str = reloadCarbon('carbon')
        --rust.Notice(netuser, "X", str, 1)
        rust.Notice(netuser, "", "You must be at a workbench to do this.", 4)
        rust.RunServerCommand( 'wildlife.forceupdate' )
    end
end