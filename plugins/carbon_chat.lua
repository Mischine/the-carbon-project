PLUGIN.Title = 'carbon_chat'
PLUGIN.Description = 'chat module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    self:AddChatCommand( 'w', self.cmdWhisper )


end

--PLUGIN:cmdWhisper
function PLUGIN:cmdWhisper( netuser, cmd, args )
    -- Syntax check
    if(( not args[1] ) or ( not args[2] )) then rust.SendChatToUser( netuser, self.sysname, '/w \'name\' message ' ) return end
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
    local tag = self:getGuildTag( netuser )
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
    for k, v in ipairs( self.Config.settings.censor.chat ) do
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

