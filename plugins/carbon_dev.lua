PLUGIN.Title = 'carbon_dev'
PLUGIN.Description = 'dev module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin("carbon_core") core:LoadLibrary()

	self.opendoor = {}      -- dev.opendoor[ netuser ] = true


	self:AddChatCommand( 'opendoor', self.OpenDoor )
end

function PLUGIN:isDev( netuser )
	local SteamID = rust.CommunityIDToSteamID( tonumber( rust.GetUserID( netuser ) ) )
	if SteamID == 'STEAM_0:1:36236335' or SteamID == 'STEAM_0:0:25828468' then return true else return false end
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--              Dev tool to open all doors
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:OpenDoor( netuser, cmd, args )
	if not self:isDev( netuser ) then return end
	if self.opendoor[ netuser ] then self.opendoor[ netuser ] = nil rust.Notice( netuser, 'OpenDoor is now deactivated.' ) return end
	if not self.opendoor[ netuser ] then self.opendoor[ netuser ] = true rust.Notice( netuser, 'OpenDoor is now activated.' ) return end
	rust.Notice( netuser, 'Something went terribly wrong. ' )
end
function PLUGIN:hasOpenDoor( netuser )
	if self.opendoor[ netuser ] then return true else return false end
end
-- ----------------------------------------------------------

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                     Description here.
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ----------------------------------------------------------