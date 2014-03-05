PLUGIN.Title = 'carbon_sandbox_a'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
    
    self:AddChatCommand( 'test', self.test )
end

function PLUGIN:test(netuser, cmd, args )

end

