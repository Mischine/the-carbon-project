PLUGIN.Title = 'carbon_timers'
PLUGIN.Description = 'timers database'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin('carbon_core') core:LoadLibrary()

	self.Pets = {}


	self:AddChatCommand( 'timerkill', self.KillPetTimer )

end

function PLUGIN:InitTimer( pet )
	if not pet then rust.Notice( netuser, 'Failed to initiate the timer. [ < Pet data not found. > ]' ) return end
	self.Pets[ netuser ] = timer.Repeat( 1, function()
		if not pet then rust.Notice( netuser , 'Pet data is lost. Pet AI is cancelled.' ) return end
		self:PetAI( pet.netuser, pet )
	end )
end

function PLUGIN:KillPetTimer( netuser, _, args )
	if not dev:isDev( netuser ) then return end
	local targuser = netuser
	if args[1] then
		local targname = args[1]
		local b, targuser = rust.FindNetUsersByName( targname )
		if not b then rust.SendChatToUser( netuser, core.sysname, 'player not found with name ' .. args[1] ) return end
	end
	if self.Pets and self.Pets[ targuser ] then
		self.Pets[ targuser ]:Destroy()
		rust.Notice( netuser, targuser.displayName .. '\'s pet timer destroyed.' )
	else
		rust.Notice( netuser, 'No pet timer found for: ' .. targuser.displayName )
	end
end