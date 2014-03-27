PLUGIN.Title = 'carbon_sandbox_a'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin("carbon_core") core:LoadLibrary()
	self:AddChatCommand( 'spawnpet', self.SpawnPet )

	self.idlepets = {}

end

function PLUGIN:SpawnPet( netuser, cmd, args )
	if not dev:isDev( netuser ) then return end

end