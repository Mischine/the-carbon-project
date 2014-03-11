PLUGIN.Title = 'carbon_sandbox_c'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()




    self:AddChatCommand( 'getostime', self.cmdOSTime )
end

--PLUGIN:hasSYGCall
function PLUGIN:OSTime( netuser, cmd, args )
	rust.BroadcastChat(tostring(core.OSdateTime))
end

