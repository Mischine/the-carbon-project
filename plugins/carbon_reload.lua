PLUGIN.Title = 'Carbon Reload'
PLUGIN.Description = 'carbon reload module'
PLUGIN.Version = '0.0.1a'
PLUGIN.Author = 'Mischa & CareX'

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:Init | http://wiki.rustoxide.com/index.php?title=Hooks/Init
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:Init()
    self:AddChatCommand('reload', self.cmdReload)
    self:AddChatCommand('reloadall', self.cmdReloadAll)
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- Testing plugin reload!
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function reloadCarbon(plugin)
    reloadtoken = timer.Once(3,function() reloadtoken = nil  end)
    print('Carbon reloader initiated.. .')
    cs.reloadplugin(plugin)
    local cplugin = plugins.Find(plugin)
    if cplugin then
        cplugin:Init()
        if cplugin.PostInit then cplugin:PostInit() end
    else
        return false, 'Failed to reload ' .. plugin
    end
    print('Carbon reloader complete.')
    return true, (plugin .. ' reloaded!')
end

function PLUGIN:cmdReload( netuser, cmd, args )
    if not reloadtoken then
        local b, str = reloadCarbon('carbon_' .. args[1])
        Rust.Rust.Notice.Popup( netuser.networkPlayer, prefix or " ϟ", str .. '      ', duration or 4.0 )
        rust.RunServerCommand( 'wildlife.forceupdate' )
    end
end
function PLUGIN:cmdReloadAll( netuser, cmd, args )
    local plugins = {
        'carbon_call','carbon_char','carbon_chat','carbon_combat','carbon_core','carbon_debug','carbon_econ',
        'carbon_func','carbon_guild','carbon_mail','carbon_party','carbon_perk','carbon_prof','carbon_sandbox','carbon_stats',
        'carbon_reload'
    }
    for _,v in ipairs(plugins) do
        if not reloadtoken then
            local b, str = reloadCarbon(v)
            Rust.Rust.Notice.Popup( netuser.networkPlayer, prefix or " ϟ", str .. '      ', duration or 4.0 )
            rust.RunServerCommand( 'wildlife.forceupdate' )
        end
    end

end