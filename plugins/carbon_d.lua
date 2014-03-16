PLUGIN.Title = 'carbon_sandbox_d'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    self:AddChatCommand( 'gdump', self.cmdTest )
end
function PLUGIN:cmdTest()
	for k,v in pairs(_G) do
		for key,value in pairs(v) do
			print(key .. ' ' .. value)
		end
	end
end
