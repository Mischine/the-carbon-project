PLUGIN.Title = 'carbon_chat'
PLUGIN.Description = 'chat module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

end

function PLUGIN:PostInit()
    -- Notify console
    print( "Loading the local chat resource..." )

    -- Lua math.sqrt
    self.SquareRoot = math.sqrt

    -- Default distance
    self.Distance = 20

    -- Check if the settings table is working correctly
    if ( core.Config.settings ) and ( core.Config.settings['CHAT_DISTANCE'] ) then
        self.Distance = core.Config.settings['CHAT_DISTANCE']
    end

    -- Define the chat commands if the "ENABLE_LOCAL_ONLY" setting is turned off
    if not ( core.Config.settings ) or not ( core.Config.settings['ENABLE_LOCAL_CHAT'] ) then
        self:AddChatCommand( "l", self.OnLocalChat )
        self:AddChatCommand( "local", self.OnLocalChat )
    end
end

--PLUGIN:cmdWhisper
function PLUGIN:cmdWhisper( netuser, cmd, args )
    -- Syntax check
    if(( not args[1] ) or ( not args[2] )) then rust.SendChatToUser( netuser, core.sysname, '/w \'name\' message ' ) return end
    -- Player check
    local targname = tostring( args[1] )
    if( netuser.displayName == targname ) then rust.Notice( netuser, 'You cannot whisper to yourself!' ) return end
    local b, targuser = rust.FindNetUsersByName( targname )
    if ( not b ) then
        if( targuser == 0 ) then
            rust.Notice( netuser, 'No user found with the name: ' .. util.QuoteSafe( targname ) )
        else
            rust.Notice( netuser, 'Multiple users found with the name: ' .. util.QuoteSafe( targname ) )
        end
    return end
    -- Get guildtag
    local tag = guild:getGuildTag( netuser )
    local displayname = netuser.displayName .. ' [whispers]'
    if ( tag ) then displayname = tag .. displayname end
    -- Generating msg
    local i = 2
    local msg = ''
    while ( i <= #args ) do
        msg = msg .. ' ' .. args[i]
        i = i + 1
    end
    -- Checking msg for language
    local tempstring = string.lower( msg )
    for _, v in ipairs( core.Config.settings.censor.chat ) do
        local found = string.find( tempstring, v )
        if ( found ) then
	        local data = char[ tostring(rust.GetUserID( netuser ))]
            rust.BroadcastChat( netuser.displayName, 'I\'m a naughty person.' )
            data.swear = data.swear + 1
	        tabe.insert(data.sweartbl, v )
	        local netuserID = rust.GetUserID( netuser )
            if data.swear >= 10 then rust.Notice( netuser, 'You have sweared ' .. tostring(data.swear) .. ' times now. Be careful, consequences may soon happen.' ) end
	        char:Save( netuser )
            return
        end
    end
    -- Send message
    rust.SendChatToUser( targuser, displayname, tostring( msg ))
    rust.Notice( netuser, 'Message send!' )
end

--[[
--PLUGIN:OnUserChat
function PLUGIN:OnUserChat(netuser, name, msg)
	if ( msg:sub( 1, 1 ) ~= '/' ) then
		local tempstring = string.lower( msg )
		for _, v in ipairs( self.Config.settings.censor.chat ) do
			local found = string.find( tempstring, v )
			if ( found ) then
				local data = char[ tostring(rust.GetUserID( netuser ))]
				rust.BroadcastChat( name, 'I\'m a naughty person.' )
				data.swear = data.swear + 1
				if data.swear >= 10 then rust.Notice( netuser, 'You have sweared ' .. tostring(data.swear) .. ' times now. Be careful, consequences may soon happen.' ) char:Save( tostring(rust.GetUserID( netuser )), 10) end
				return false
			end
		end
		local tag = guild:getGuildTag( netuser )
		if tag then
			name = tag .. ' ' .. name
			rust.BroadcastChat( name, msg )
			return false
		end
	end
end
]]

function PLUGIN:OnUserChat(netuser, name, msg)
	if ( msg:sub( 1, 1 ) == "/" ) then return end
	local data = char:GetUserData( netuser )
	if not data then rust.Notice( netuser, 'Userdata not found, try relogging' ) return false end
	local guild = guild:getGuild( netuser )
	if guild then name = tostring( guild.tag .. ' ' .. name ) end

	-- Swear check.
	for _, v in ipairs( core.Config.settings.censor.chat ) do
		local tmpstring = msg:lower()
		local found = string.find( tmpstring, v )
		if ( found ) then
			rust.BroadcastChat( netuser.displayName, 'Dont swear.' )
			data.swear = data.swear + 1
			tabe.insert(data.sweartbl, v )
			if data.swear >= 10 then rust.Notice( netuser, 'You have sweared ' .. tostring(data.swear) .. ' times now. Be careful, consequences may soon happen.' ) end
			char:Save( netuser )
			return false
		end
	end

	-- Language converter
	-- COMING SOON

	-- Get chat channel
	if data.channel == 'local' then            -- Local channel | 30 coords.
		self:OnLocalChat( netuser, name, msg )
	elseif data.channel == 'guild' then        -- Guild channel | Only visible to guild
		if not guild then rust.Notice( netuser, 'Your\'re not in a guild!' ) return false end
		self:sendGuildMsg(guild, name, msg )
	elseif data.channel == 'party' then        -- Party channel | Only visible to Party
		self:cmdPartyChat( netuser, name, msg )
	elseif data.channel == 'trade' then        -- Trade channel | Only visible to people in the same channel || COMING SOON
		data.channel = 'local'
		char:Save( netuser )
		self:OnLocalChat( netuser, name, msg )
	elseif data.channel == 'recruit' then      -- Recruit channel | Only visible to people in the same channel || COMING SOON
		data.channel = 'local'
		char:Save( netuser )
		self:OnLocalChat( netuser, name, msg )
	elseif data.channel == 'zone' then         -- Zone channel | Only visible to people in the same zone || COMING SOON
		data.channel = 'local'
		char:Save( netuser )
		self:OnLocalChat( netuser, name, msg )
	else
		data.channel = 'local'
		char:Save( netuser )
		self:OnLocalChat( netuser, name, msg )
	end
	return false
end

-- Local chat function bound the to commands
function PLUGIN:OnLocalChat( netuser, name, msg )
    -- Get the coordinates from the sender
    local coords1 = netuser.playerClient.lastKnownPosition
    -- Get all the online players
    local users = rust.GetAllNetUsers()
    -- Safety check, do we have the coordinates?
    if ( coords1 ) and ( coords1.x ) and ( coords1.y ) and ( coords1.z ) then
        -- Loop thru the online players
        for i = 1, #users do
            -- Get the coordinates from the player in the loop
            local coords2 = users[ i ].playerClient.lastKnownPosition
            -- Safety check, do we have the coordinates?
            if ( coords2 ) and ( coords2.x ) and ( coords2.y ) and ( coords2.z ) then
                -- Check if the player in the loop is near the message sender
                if ( func:Distance3D ( coords1.x, coords1.y, coords1.z, coords2.x, coords2.y, coords2.z ) <= 30 ) then
                    -- Send the message the message to the player
                    rust.SendChatToUser( users[ i ], name .. ' [L]',  msg )
                end
            end
        end
        -- Log the message
        print ( "(LOCAL) " .. name .. ": " .. msg )
    end
end

function PLUGIN:sendGuildMsg( guild, name, msg )
	local guilddata = self:getGuildData( guild )
	if guilddata then
		for _,v in pairs( guilddata.members ) do
			local b, targuser = rust.FindNetUsersByName( v.name )
			if( b ) then rust.SendChatToUser( targuser, name .. '  [G]' , msg ) end
		end
	end
end

function PLUGIN:cmdPartyChat( netuser, name, msg )
	local pdata = self:getParty( netuser)
	if not pdata then rust.Notice( netuser, 'You\'re not in a party!' ) return end
	for _,v in pairs( pdata.members ) do
		local b, targuser = rust.FindNetUsersByName( v.name )
		if b then rust.SendChatToUser( targuser, name .. '  [P]',msg ) end
	end
end


--[[
-- About the same code as for the local chat commands
function PLUGIN:OnUserChat( netuser, name, message )
    if ( core.Config.settings ) and ( core.Config.settings['ENABLE_LOCAL_CHAT'] ) then
        -- Check if the message is a command
        if ( message:sub( 1, 1 ) == "/" ) then return end

        -- Get the coordinates from the sender
        local coords1 = netuser.playerClient.lastKnownPosition

        -- Get all the online players
        local users = rust.GetAllNetUsers()

        -- Safety check, do we have the coordinates?
        if ( coords1 ) and ( coords1.x ) and ( coords1.y ) and ( coords1.z ) then

            -- Loop thru the online players
            for i = 1, #users do

                -- Get the coordinates from the player in the loop
                local coords2 = users[ i ].playerClient.lastKnownPosition

                -- Safety check, do we have the coordinates?
                if ( coords2 ) and ( coords2.x ) and ( coords2.y ) and ( coords2.z ) then

                    -- Check if the player in the loop is near the message sender
                    if ( self:Distance3D ( coords1.x, coords1.y, coords1.z, coords2.x, coords2.y, coords2.z ) <= self.Distance ) then

                        -- Send the message the message to the player
                        rust.SendChatToUser( users[ i ], "(LOCAL) " .. netuser.displayName, message )
                    end
                end
            end

            -- Log the message
            print ( "(LOCAL) " .. netuser.displayName .. ": " .. message )

            -- Return so the message doesn't get ouputted to all the players
            return false
        end
    end
end
]]
