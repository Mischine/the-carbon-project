PLUGIN.Title = 'carbon_anim'
PLUGIN.Description = 'animation module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin('carbon_core') core:LoadLibrary()
end

