PLUGIN.Title = 'carbon_sound'
PLUGIN.Description = 'sound module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin('carbon_core') core:LoadLibrary()
end

