PLUGIN.Title = 'carbon_sandbox_d'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    self:AddChatCommand( 'test', self.cmdTest )
end


