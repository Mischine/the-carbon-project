PLUGIN.Title = "carbon_debug"
PLUGIN.Description = "debug module"
PLUGIN.Version = "0.0.1 alpha"
PLUGIN.Author = "Mischa & CareX"


function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
    self.list = {}

    self:AddChatCommand( 'debug', self.cmdDebug )
end

function PLUGIN:cmdDebug( netuser, cmd, args )
	if not args[1] then
		local msg = 'Debugging: '
		for k,_ in pairs( self.list ) do
			msg = msg .. k .. ', '
		end
		rust.SendChatToUser( netuser, msg )
		return
	end
	local targname = util.QuoteSafe( args[1] )
	if self.list[ targname ] then rust.Notice( netuser, targname .. '\'s debug is terminated') self.list[ targname ] = nil return end
	local validate, targuser = rust.FindNetUsersByName( targname )
	if (not validate) then
		if (targuser == 0) then
			rust.Notice( netuser, 'No players found with name: ' .. util.QuoteSafe( targname ))
		else
			rust.Notice( netuser,'Multiple players found with name: ' .. util.QuoteSafe( targname ))
		end
	return end
	self.list[ targname ] = true
	rust.Notice( netuser, 'Debugging ' .. targname )
end

function PLUGIN:SendDebug( name, msg )
	timer.Once( 0.01, function() rust.RunServerCommand( 'echo [ DEBUG ' .. name .. ' ] ' .. msg ) end )
end
