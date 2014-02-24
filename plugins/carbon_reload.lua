PLUGIN.Title = 'Carbon Reload'
PLUGIN.Description = 'carbon reload module'
PLUGIN.Version = '0.0.1a'
PLUGIN.Author = 'Mischa & CareX'

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:Init | http://wiki.rustoxide.com/index.php?title=Hooks/Init
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:Init()
    self:AddChatCommand('reload', self.cmdReload)
    self:AddChatCommand('reloader', self.cmdReloader)
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
    return true, 'Carbon reloaded asdfasdf'
end

function PLUGIN:cmdReload( netuser )
    if not reloadtoken then
        local b, str = reloadCarbon('carbon')
        rust.Notice(netuser, str)
        rust.RunServerCommand( 'wildlife.forceupdate' )
    end
end
function reloaderCarbon(carbon)
    reloadtoken = timer.Once(3,function() reloadtoken = nil  end)
    print('Carbon reloader initiated.. .')
    cs.reloadplugin(carbon)
    local cplugin = plugins.Find(carbon)
    if cplugin then
        cplugin:Init()
        if cplugin.PostInit then cplugin:PostInit() end
    else
        return false, 'Failed to reload carbon reloader'
    end
    print('Carbon reloader complete.')
    return true, 'Carbon reloaded'
end
local RustNoticeTemplate = { RustFirstPass.NetUser, "string", "number" }
function PLUGIN:cmdReloader( netuser )
    if not reloadtoken then
        local b, str = reloaderCarbon('carbon_reload')
        local text = 'this is a test'
        local duration = 2
        Rust.Rust.Notice.Popup( netuser.networkPlayer, " ", text, duration or 4.0 )
        --rust.Notice( netuser, "   ", text, duration or 4.0 )
        rust.RunServerCommand( 'wildlife.forceupdate' )
    end
end