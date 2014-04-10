PLUGIN.Title = 'carbon_timers'
PLUGIN.Description = 'timers database'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin('carbon_core') core:LoadLibrary()

	self.Pets = {}

end


