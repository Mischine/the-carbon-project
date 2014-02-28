PLUGIN.Title = 'carbon_core'
PLUGIN.Description = 'carbon core file'
PLUGIN.Version = '0.0.1a'
PLUGIN.Author = 'mischa/carex'


function PLUGIN:Init()
    package.path = "/carbon/?.lua;" .. package.path
    self:AddChatCommand( 'test', self.cmdTest )
end