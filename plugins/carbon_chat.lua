PLUGIN.Title = 'carbon_chat'
PLUGIN.Description = 'chat module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()



    self:AddChatCommand( 'w', self.cmdWhisper )

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
    for k, v in ipairs( core.Config.settings.censor.chat ) do
        local found = string.find( tempstring, v )
        if ( found ) then
            rust.Notice( netuser, 'Dont swear!' )
            return
        end
    end
    -- Send message
    rust.SendChatToUser( targuser, displayname, tostring( msg ))
    rust.Notice( netuser, 'Message send!' )
end

-- Returns the distance between two 3 dimensional points
function PLUGIN:Distance3D ( x1, y1, z1, x2, y2, z2 )
    local xd = x2 - x1
    local yd = y2 - y1
    local zd = z2 - z1
    return self.SquareRoot( xd * xd + yd * yd + zd * zd )
end

-- Returns the distance between two 2 dimensional points (we don't need this one, just included it for the lulz)
-- function PLUGIN:Distance2D ( x1, y1, x2, y2 )
-- local xd = x2 - x1
-- local yd = y2 - y1
-- return self.SquareRoot( xd * xd + yd * yd )
-- end

-- Local chat function bound the to commands
function PLUGIN:OnLocalChat( netuser, _, args )
    -- Compose the message
    local message = util.QuoteSafe( table.concat( args, " " ) )

    -- Check if the message string is empty
    if not ( args ) or not ( message ) or ( message:find("^%s*$") ) then
        rust.Notice( netuser, "You didn't enter a message!" )
        return
    end

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
                    rust.SendChatToUser( users[ i ], netuser.displayName, "(LOCAL): " .. message )
                end
            end
        end

        -- Log the message
        print ( "(LOCAL) " .. netuser.displayName .. ": " .. message )
    end
end

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
