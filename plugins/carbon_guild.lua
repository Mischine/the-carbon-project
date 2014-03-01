PLUGIN.Title = 'carbon_guild'
PLUGIN.Description = 'guild module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    --LOAD/CREATE GUILD DATA FILE
    self.GuildFile = util.GetDatafile( 'carbon_gld' )
    local gld_txt = self.GuildFile:GetText()
    if (gld_txt ~= '') then
        print( 'Carbon gld file loaded!' )
        self.Guild = json.decode( gld_txt )
    else
        print( 'Creating carbon gld file...' )
        self.Guild = {}
        self.Guild[ 'temp' ] = {}
        self:GuildSave()
    end

    self:AddChatCommand( 'g', self.cmdGuilds )

end

--PLUGIN:Guilds commands
function PLUGIN:cmdGuilds( netuser, cmd, args )
    if( not args[1] ) then
        rust.SendChatToUser(netuser,' ',' ')
        rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
        rust.SendChatToUser(netuser,core.sysname,'║ guild > ')
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
        rust.SendChatToUser(netuser,core.sysname,'║ For more information on a specific command, type /help command-name')
        if not guild then
            rust.SendChatToUser(netuser,core.sysname,'║ To create a guild you need a level of 10 or higher.')
            rust.SendChatToUser(netuser,core.sysname,'║ The cost to create a guild is 25 Silver.')
        else
            rust.SendChatToUser(netuser,core.sysname,'║ delete               Deletes guild')
            rust.SendChatToUser(netuser,core.sysname,'║ info                   Displays guild\'s information that you\'re currently in.')
            rust.SendChatToUser(netuser,core.sysname,'║ stats                  Display global statistics of the guild.')
            rust.SendChatToUser(netuser,core.sysname,'║ invite                Invite a player to your guild.')
            rust.SendChatToUser(netuser,core.sysname,'║ kick                  Kicks a player from your guild.')
            rust.SendChatToUser(netuser,core.sysname,'║ leave                 To leave a guild.')
            rust.SendChatToUser(netuser,core.sysname,'║ war                    Engage in a war with another guild.')
            rust.SendChatToUser(netuser,core.sysname,'║ rank                  View/assign ranks to your guild members')
            rust.SendChatToUser(netuser,core.sysname,'║ members               To view all guild members')
        end
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
        if not guild then
            rust.SendChatToUser(netuser,core.sysname,'║ ⌘  • create  •  ')
        else
            rust.SendChatToUser(netuser,core.sysname,'║ ⌘  • delete • info • stats • invite • kick  ')
            rust.SendChatToUser(netuser,core.sysname,'║ ⌘  • leave • war • calls • rank • members  ')
        end
        rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,' ',' ')
        return end
    local action = tostring( args[1] ):lower()
    if ( action == 'create') then
        -- /g create 'Guild Name' 'Guild Tag'
        if(( args[2] ) and ( args[3] )) then
            local lvl = tonumber( char:getLvl( netuser ) )
            -- if( not ( lvl >= 10 )) then rust.Notice( netuser, 'level 10 required to create your own guild!' ) return end
            local userID = rust.GetUserID( netuser )
            if( char.User[ userID ].guild ) then rust.Notice( netuser, 'You\'re already in a guild!' ) return end
            local name = tostring( args[2] )
            local tag = tostring( args[3] )
            tag = string.upper( tag )
            -- Tag/name language check.
            if( func:containsval( core.Config.settings.censor.tag, tag ) ) then rust.Notice( netuser, 'Can not compute. Error code number B' ) return end
            for k, v in ipairs( core.Config.settings.censor.chat ) do
                local found = string.find( name, v )
                if ( found ) then
                    rust.Notice( netuser, 'Can not compute. Error code number B' )
                    return false
                end
            end
            for k, v in ipairs( core.Config.settings.censor.tag ) do
                local found = string.find( name, v )
                if ( found ) then
                    rust.Notice( netuser, 'Can not compute. Error code number B' )
                    return false
                end
            end
            -- Tag/name length check.
            if( string.len( tag ) > 3 ) then rust.Notice( netuser, 'Guild tag is too long! Maximum of 3 characters allowed' ) return end
            if( string.len( name ) > 15 ) then rust.Notice( netuser, 'Guild name is too long! Maximum of 15 characters allowed' ) return end
            self:CreateGuild( netuser, name, tag )
        else
            rust.SendChatToUser( netuser, core.sysname, '/g create "Guild Name" "Guild Tag" ')
        end

    elseif ( action == 'delete') then  --[ candelete ]
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ') return end
        -- /g delete GuildTag                       -- Deletes the guild
        if( args[2] and args[3] and not args[4] ) then
            -- Delete guild
            if( guild ) then
                local tag = '[' .. tostring( args[3]) .. ']'
                local rank = self:hasRank( netuser, guild, 'Leader' )
                if( guild ~= tostring( args[2] )) or ( self.Guild[ guild ].tag ~= tag ) then rust.Notice( netuser, 'Please type your guildname and tag to delete it' ) return end
                if( self:hasAbility( netuser, guild, 'candelete' ) ) then
                    -- DELETE GUILD
                    self:delGuild( guild )
                    rust.SendChatToUser( netuser, core.sysname, 'Guild disbanned!' )
                else
                    rust.Notice( netuser, 'You\'re not the guild leader!' )
                    return
                end
            end
        else
            rust.SendChatToUser( netuser, core.sysname, '/g delete "Guild Name" "Guild Tag" ' )
        end
    elseif ( action == 'info') then
        -- /g info                                  -- Displays general Guild information
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild!' ) return end
        local data = self:getGuildData( guild )
        rust.SendChatToUser(netuser,' ',' ')
        rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
        rust.SendChatToUser(netuser,core.sysname,'║ guild > ' .. guild .. ' > info')
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
        rust.SendChatToUser(netuser,core.sysname,'║ Guild Name    : ' .. guild)
        rust.SendChatToUser(netuser,core.sysname,'║ Guild Tag        : ' .. data.tag)
        rust.SendChatToUser(netuser,core.sysname,'║ Guild Level     : ' .. data.glvl)
        rust.SendChatToUser(netuser,core.sysname,'║ Guild XP          : (' .. data.xp .. '/' .. data.xpforLVL .. ')   [' .. math.floor(data.xp / data.xpforLVL * 100) .. '%]   (+' .. data.xpforLVL - data.xp .. ')')
        rust.SendChatToUser(netuser,core.sysname,'║ ')
        rust.SendChatToUser(netuser,core.sysname,'║ Guild Leader   : ' .. self:getGuildLeader( guild ))
        rust.SendChatToUser(netuser,core.sysname,'║ Members        : ' .. func:count( data.members ))
        if( data.interval >= 10 ) then
            rust.SendChatToUser(netuser,core.sysname,'║ Collect/' .. data.interval .. 'h     : ' .. data.collect)
        else
            rust.SendChatToUser(netuser,core.sysname,'║ Collect/' .. data.interval .. 'h      : ' .. data.collect)
        end
        rust.SendChatToUser(netuser,core.sysname,'║ Perks               : ' .. func:sayTable( data.unlockedperks, ', ' ))
        rust.SendChatToUser(netuser,core.sysname,'║ Active Perks : ' .. func:sayTable( data.activeperks, ', ' ))
        rust.SendChatToUser(netuser,core.sysname,'║ War                   : ' .. func:sayTable( data.war, ', ' ))
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
        rust.SendChatToUser(netuser,core.sysname,'║ ⌘')
        rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,' ',' ')
    elseif ( action == 'stats') then
        -- /g stats                                 -- Displays a lists of guild statistics
        local guild = self:getGuild( netuser )
        if( not guild ) then self.Notice( netuser, 'You\'re not in a guild!' ) return end
        local data = self:getGuildData( guild )
        rust.SendChatToUser(netuser,' ',' ')
        rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
        rust.SendChatToUser(netuser,core.sysname,'║ guild > ' .. guild .. ' > stats')
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
        rust.SendChatToUser(netuser,core.sysname,'║ COMING SOON!')
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
        rust.SendChatToUser(netuser,core.sysname,'║ ⌘')
        rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,' ',' ')
    elseif ( action == 'invite') then  --                                                  [ caninvite ]
        -- /g invite 'name'                                                 -- Invite a player to the guild
        if( not args[2] ) then rust.Notice( netuser, '/g invite "name" ' ) return end
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
        if( self:hasAbility( netuser, guild, 'caninvite' ) ) then
            local targname = tostring( args[ 2 ] )
            local b, targuser = rust.FindNetUsersByName( targname )
            if ( not b ) then
                if( targuser == 0 ) then
                    rust.Notice( netuser, 'No user found with the name: ' .. util.QuoteSafe( targname ) )
                else
                    rust.Notice( netuser, 'Multiple users found with the name: ' .. util.QuoteSafe( targname ) )
                end
                return end
            local targuserID = rust.GetUserID( targuser )
            local members = self:getGuildMembers( guild )
            print (tostring( members ))
            -- if( self.Guild[ guild].members[ targuserID ] ) then rust.Notice( netuser, tostring( targname ) .. ' is already in ' .. guild ) return end
            if( self.Guild.temp[ targuserID ] ) then rust.Notice( netuser, targname .. ' is alrady invited!' ) return end
            self.Guild.temp[ targuserID ] = guild
            timer.Once( 60, function()
                if( self.Guild.temp[ targuserID ]) then
                    rust.SendChatToUser(targuser, core.sysname, 'Invitation to ' .. guild .. ' expires in 60 seconds' )
                    timer.Once( 60, function()
                        if( self.Guild.temp[ targuserID ]) then
                            rust.SendChatToUser( targuser, core.sysname, 'Invitation to ' .. guild .. ' expired.' )
                            self.Guild.temp[ targuserID ] = nil
                        end
                    end)
                end
            end)
            rust.Notice( targuser, 'You\'ve been invited to ' .. guild .. '. /g accept to join the guild.', 15)
            rust.Notice( netuser, 'You\'ve invited ' .. targname .. ' to ' .. guild )
        else
            rust.Notice( netuser, 'You\'re not allowed to invite players to the guild!' )
        end
    elseif ( action == 'members') then -- /g members list all members + ranks | /g members "name" list all information about a member.
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild!' ) return end
        local data = self:getGuildData( guild )
        if not data then rust.Notice( netuser, 'Guild data not found! Report to a GM please.' ) return end
        if( not args[2] ) then -- get list of all guild members
            local i = 0
            local msg = ""
            local count = func:count( data.members )
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ ' .. guild .. ' > members' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ Total members: ' .. tostring( count )  )
            for k, v in pairs( data.members ) do
                if msg ~= "" then msg = msg .. ', ' end
                if i >= 2 then
                    msg = msg .. '[' .. v.rank .. ']' .. v.name .. ', '
                    rust.SendChatToUser(netuser,' ','║ '.. msg )
                    i = 0
                    msg = ""
                else
                    msg = msg .. '[' .. v.rank .. ']' .. v.name
                    i = i + 1
                end
            end
            if not ( i >= 3 ) then rust.SendChatToUser(netuser,' ','║ '.. msg ) end
            rust.SendChatToUser(netuser,' ','║ ' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        elseif ( args[2]) then -- get info about a specific guild member
            local name = tostring( args[2] )
            local found = false
            for k,v in pairs( data.members ) do
                if v.name == name then
                    found = true
                    rust.SendChatToUser(netuser,' ',' ')
                    rust.SendChatToUser(netuser,' ','╔════════════════════════')
                    rust.SendChatToUser(netuser,' ','║ ' .. guild .. ' > ' .. name )
                    rust.SendChatToUser(netuser,' ','╟────────────────────────')
                    rust.SendChatToUser(netuser,' ','║ Rank                             :' .. v.rank )
                    rust.SendChatToUser(netuser,' ','║ XP contributed         :' .. v.xpcon )
                    rust.SendChatToUser(netuser,' ','║ Money contributed  :' .. v.moncon )
                    rust.SendChatToUser(netuser,' ','║ ' )
                    rust.SendChatToUser(netuser,' ','║ Level: ' .. char.User[ k ].lvl )
                    rust.SendChatToUser(netuser,' ','║ Attributes: ' )
                    rust.SendChatToUser(netuser,' ','║     str   : ' .. char.User[ k ].attributes.str )
                    rust.SendChatToUser(netuser,' ','║     agi   : ' .. char.User[ k ].attributes.agi )
                    rust.SendChatToUser(netuser,' ','║     sta  : ' .. char.User[ k ].attributes.sta )
                    rust.SendChatToUser(netuser,' ','║     int   : ' .. char.User[ k ].attributes.int )
                    rust.SendChatToUser(netuser,' ','╟────────────────────────')
                    rust.SendChatToUser(netuser,' ','║ ⌘ ' )
                    rust.SendChatToUser(netuser,' ','╚════════════════════════')
                    rust.SendChatToUser(netuser,' ',' ')
                end
            end
            if not found then
                rust.SendChatToUser(netuser,' ',' ')
                rust.SendChatToUser(netuser,' ','╔════════════════════════')
                rust.SendChatToUser(netuser,' ','║ ' .. guild .. ' > ' .. name .. ' > ϟ error' )
                rust.SendChatToUser(netuser,' ','╟────────────────────────')
                rust.SendChatToUser(netuser,' ','║ ' .. name .. ' is not in your guild!' )
                rust.SendChatToUser(netuser,' ','╟────────────────────────')
                rust.SendChatToUser(netuser,' ','║ ⌘ ' )
                rust.SendChatToUser(netuser,' ','╚════════════════════════')
                rust.SendChatToUser(netuser,' ',' ')
            end

        else

        end
    elseif ( action == 'accept') then
        -- /g accept
        local netuserID = rust.GetUserID( netuser )
        if( self.Guild.temp[ netuserID ] ) then
            local guild = self.Guild.temp[ netuserID ]
            local entry = {}
            entry.name = netuser.displayName
            entry.rank = 'Member'
            entry.moncon = 0
            entry.xpcon = 0
            self.Guild[ guild ].members[ netuserID ] = entry
            char.User[ netuserID ][ 'guild' ] = guild
            self:sendGuildMsg( guild, char.User[ netuserID ].name , 'has joined the guild! =)' )
            self.Guild.temp[ netuserID ] = nil
            self:UserSave()
            self:GuildSave()
        end
    elseif ( action == 'leave') then
        -- /g leave guildtag
        if( not args[2] ) then rust.Notice( netuser, '/g leave [guildtag] ' ) return end
        local guild = self:getGuild( netuser )
        print( guild )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild!') return end
        local netuserID = rust.GetUserID( netuser )
        self.Guild[ guild ].members[ netuserID ] = nil
        char.User[ netuserID ].guild = nil
        self:sendGuildMsg( guild, netuser.displayName, 'has left the guild! =(' )
        local count = func:count( self.Guild[ guild ].members )
        if ( count == 0 ) then self.Guild[ guild ] = nil rust.Notice( netuser, guild .. ' has been disbanned!' ) end
        self:GuildSave()
        self:UserSave()
    elseif ( action == 'kick') then                 --                                                  [ cankick ]
        -- /g kick name                             -- Kick a player from the guild
        if( not args[2] ) then rust.Notice( netuser, '/g kick "name" ' )return end
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
        if( not self:hasAbility( netuser, guild, 'cankick' ) ) then rust.Notice(netuser, 'You\'re not permitted to kick a player from the guild.' ) return end
        local targname = util.QuoteSafe( args[2] )
        if( netuser.displayName == targname ) then rust.Notice( netuser, 'You cannot kick yourself...' ) return end
        local targuserID = false
        for k, v in pairs( self.Guild[ guild ].members ) do
            if( v.name:lower() == targname:lower() ) then targuserID = k return end
        end
        if( not targuserID ) then rust.Notice( netuser, 'player ' .. targname .. ' is not a member of ' .. guild .. '.') return end
        local date = System.DateTime.Now:ToString(core.Config.dateformat)
        mail:sendMail( targuserID, netuser.displayName, date, 'You\'ve been kicked from the guild ' .. guild, guild )
        self.Guild[ guild ].members[ targuserID ] = nil
        char.User[ targuserID ].guild = nil
        self:UserSave()
        self:GuildSave()
        --[[   elseif ( action == 'calls') then                --                                                  [ canwar ]
               local guild = self:getGuild( netuser )
               if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
               if not args[1] then
                   -- display calls, if they're active and what they do. and their modifiers.
                   rust.SendChatToUser(netuser,' ',' ')
                   rust.SendChatToUser(netuser,' ','╔════════════════════════')
                   rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  buy > ' .. data.name .. ' > bought ')
                   rust.SendChatToUser(netuser,' ','╟────────────────────────')
                   rust.SendChatToUser(netuser,' ','║ ' )
                   rust.SendChatToUser(netuser,' ','╟────────────────────────')
                   if( self:hasAbility( netuser, guild, 'canwar' ) ) then -- can add calls
                       rust.SendChatToUser(netuser,' ','║ add • remove ⌘ ' )
                   else
                       rust.SendChatToUser(netuser,' ','║ ⌘ ' )
                   end
                   rust.SendChatToUser(netuser,' ','╚════════════════════════')
                   rust.SendChatToUser(netuser,' ',' ')
               elseif args[1] =='add' then
                   if args[2] then
                   else
                   end
               end ]]

    elseif ( action == 'war') then                  --                                                  [ canwar ]
        -- /g war guildtag                          -- Engage a war with another guild / other guild will be notified.
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
        if( not self:hasAbility( netuser, guild, 'canwar' ) ) then rust.Notice(netuser, 'You\'re not permitted to initiate a war!' ) return end
        local targtag = '['..string.upper( tostring( args[2] ))..']'
        for k,v in pairs( self.Guild ) do
            if( v.tag == targtag )then
                self:engageWar( guild, k, netuser )
                return
            end
        end
        rust.Notice( netuser, 'Tag does not exist.' )
    elseif ( action == 'rank' ) then                            -- show rank. if [ canrank ] then show options too.
        if( not args[2] ) then
            local guild = self:getGuild( netuser )
            if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
            local rank = self:getRank( netuser, guild )
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
            rust.SendChatToUser(netuser,core.sysname,'║ guild > ' .. guild .. ' > rank')
            rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
            rust.SendChatToUser(netuser,core.sysname,'║ Your current rank status: ' .. tostring( rank ))
            rust.SendChatToUser(netuser,core.sysname,'║ /g rank list shows the power of each rank.')
            if( self:hasAbility( netuser, guild, 'canrank' ) ) then
                rust.SendChatToUser(netuser,core.sysname,'║ /g rank [list][give][add][edit].')
                rust.SendChatToUser(netuser,core.sysname,'║ list  | List all the available ranks and their abilites ')
                rust.SendChatToUser(netuser,core.sysname,'║ give  | Assign a rank to a guild member. ')
                rust.SendChatToUser(netuser,core.sysname,'║ Add    | Create a new rank for the guild.')
                rust.SendChatToUser(netuser,core.sysname,'║ edit  | Change rank settings.')
            end
            rust.SendChatToUser(netuser,core.sysname,'║ ')
            rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
            rust.SendChatToUser(netuser,core.sysname,'║ ⌘ list • give • add • edit ')
            rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
            return end
        if( args[2] ) then args[2] = tostring(args[2]):lower() end
        -------------------------------------
        if( args[2] == 'list' ) then                            -- /g rank list | shows list of ranks + abilities
            local guild = self:getGuild( netuser )
            if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
            local msg = {}
            for k, v in pairs( self.Guild[guild].ranks) do
                local count = func:count( self.Guild[guild].ranks[k]) +1
                while msg[ tostring(count) ] do count = count + 0.1 end
                msg[tostring( count )] = 'Rank: ' .. k .. ' Abilities: ' .. func:returnvalues( self.Guild[guild].ranks[k] )
            end
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
            rust.SendChatToUser(netuser,core.sysname,'║ guild > ' .. guild .. ' > rank > list')
            rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
            for i = 8, 1, -.1 do
                if msg[tostring(i)] then
                    rust.SendChatToUser(netuser,core.sysname,'║ '.. msg[tostring(i)])
                end
            end
            rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
            rust.SendChatToUser(netuser,core.sysname,'║ ⌘ list • give • add • edit ')
            rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        elseif( args[2] == 'give' ) then                        -- /g rank give 'rank' name | Add a rank to a member        [ canrank ]
            local guild = self:getGuild( netuser )
            if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
            if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to give ranks to a player.' ) return end
            if( args[3] and args[4] ) then
                local netuserID = rust.GetUserID( netuser )
                local targname = tostring( args[ 4 ] )
                local b, targuser = rust.FindNetUsersByName( targname )
                if ( not b ) then
                    if( targuser == 0 ) then
                        rust.Notice( netuser, 'No user found with the name: ' .. util.QuoteSafe( targname ) )
                    else
                        rust.Notice( netuser, 'Multiple users found with the name: ' .. util.QuoteSafe( targname ) )
                    end
                    return end
                local targuserID = rust.GetUserID( targuser )
                if( not self.Guild[ guild ].members[targuserID] ) then rust.Notice( netuser, targname .. ' is not in your guild!' ) return end
                if( not self.Guild[ guild ].ranks[ tostring( args[3]) ] ) then rust.Notice( netuser, tostring( args[3] .. ' is not an available rank! ')) return end
                if( not self.Guild[ guild ].members[targuserID].rank['Leader']) then rust.Notice( netuser, 'You\re not able to change the leaders rank! ') return end
                if(( tostringargs[3] == 'Leader' ) and( not self.Guild[ guild ].members[ netuserID ].rank == 'Leader' )) then rust.Notice( netuser, 'You cannot give anyone the Leader rank!') return end
                self.Guild[ guild ].members[targuserID].rank = tostring( args[3] )
                rust.Notice(netuser, targname .. ' is now a ' .. tostring( args[3] ))
                self:GuildSave()
            end
        elseif( args[2] == 'add' ) then                         -- /g rank add 'rank' | Create a new custom rank            [ canrank ]
            local guild = self:getGuild( netuser )
            if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
            if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to add ranks.' ) return end
            if( not args[3] ) then rust.SendChatToUser( netuser, '/g rank add "rankname" ') return end
            if( self.Guild[ guild ].ranks[ tostring(args[3]) ]) then rust.Notice( netuser, args[3] .. ' already exist!') return end
            self.Guild[ guild ].ranks[tostring(args[3])] = {}
            rust.SendChatToUser( netuser, 'Added new rank: ' .. args[3] )
            self:GuildSave()
        elseif( args[2] == 'del' ) then                        -- /g rank del 'rank' | delete a rank           [ canrank ]
            if(( args[3] ) and ( not args[4] )) then
                local guild = self:getGuild( netuser )
                if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
                if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to add ranks.' ) return end
                if ( args[3] == "Assasin" ) then rust.Notice( netuser, 'You cannot delete rank Assasin!' ) return end
                if ( args[3] == "Leader" ) then rust.Notice( netuser, 'You cannot delete rank Leader!' ) return end
                if( self.Guild[ guild ].ranks[tostring(args[3])]) then
                    self.Guild[ guild ].ranks[tostring(args[3])] = nil
                    rust.Notice( netuser, 'Rank ' .. args[3] .. ' has been deleted! ')
                    return
                else
                    rust.Notice( netuser, 'Rank ' .. args[3] .. ' does not exist!' )
                    return
                end
            else
                rust.SendChatToUser( netuser, '/g rank del "rank" ' )
            end
        elseif( args[2] == 'edit' ) then                        -- /g rank edit 'rank' | Create a new custom rank           [ canrank ]
            local guild = self:getGuild( netuser )
            if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
            if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to edit ranks.' ) return end
            if( not args[3] and not args[4] and not args[5] ) then
                self:sendTXT( netuser, guild, self.txt.guild.rankinfo )
            elseif( args[3] and args[4] and args[5] ) then
                if ( args[3] == "Assasin" ) then rust.Notice( netuser, 'You cannot edit rank Assasin!' ) return end
                if ( not self.Guild[guild].ranks[tostring(args[3])] ) then rust.Notice( netuser, 'Rank: ' .. tostring(args[3]).. ' doesn\'t exist!' ) return end
                if ( tonumber(args[4]) > 7 ) then rust.Notice( netuser, 'This rank abillity is not found. Chooose between 1 - 6' ) return end
                if(( args[5] == 'true' ) or ( args[5] == 'false' )) then
                    local tbl = {'candelete','caninvite','cankick','canvault','canwar','canrank' }
                    local ability = tbl[ tonumber( args[4] )]
                    if( args[5] == 'true' ) then
                        local contains = func:containsval( self.Guild[ guild ].ranks[tostring(args[3])])
                        if( contains ) then rust.Notice( netuser, tostring(args[3]) .. ' already has ' .. ability ) return end
                        table.insert( self.Guild[ guild ].ranks[tostring(args[3])], ability )
                        rust.Notice( netuser, ability .. ' has been added to ' .. tostring( args[3] ))
                    elseif( args[5] == 'false' ) then
                        local contains = func:containsval( self.Guild[ guild ].ranks[tostring(args[3])], ability )
                        if( not contains ) then rust.Notice( netuser, tostring(args[3]) .. ' doesn\'t have ' .. ability ) return end
                        for i,v in pairs( self.Guild[ guild ].ranks[tostring(args[3])] ) do
                            if( v == ability ) then
                                table.remove( self.Guild[ guild ].ranks[tostring(args[3])], i )
                                rust.Notice( netuser, ability .. ' has been taken from ' .. tostring( args[3] ))
                            end
                        end
                    end
                    self:GuildSave()
                else
                    self:sendTXT( netuser, guild, self.txt.guild.rankinfo )
                end
            else
                rust.SendChatToUser( netuser, '/g rank edit "rankname" [ID] true/false || /g rank ;For more information')
            end
        else
            if( self:hasAbility( netuser, guild, 'canrank' ) ) then rust.SendChatToUser( netuser, guild, '/g rank [list][give][take][add][edit]' )
            else rust.SendChatToUser( netuser, '/g rank [list]' ) end
        end

        -- elseif ( action == 'vault' ) then -- [ canvault ]
        -- /g vault buy                             -- Buy a vault

        -- /g vault add                             -- Add items/money to the guild vault

        -- /g vault withdraw                        -- withdraw items/money from the guild vault

        -- /g vault upgrade                         -- Upgrade your vault to the next lvl

    elseif ( action == 'help' ) then
        local guild = self:getGuild( netuser )
        if( not guild ) then guild = core.sysname end
        if not args[2] then
            self:sendTXT( netuser, guild, self.txt.guild.help )
            return
        end
        local action2 = tostring(args[2]:lower())
        if( action2 == 'create' ) then
            self:sendTXT( netuser, guild, self.txt.guild.create, 'create' )
        elseif( action2 == 'delete' ) then
            self:sendTXT( netuser, guild, self.txt.guild.delete, 'delete' )
        elseif( action2 == 'info' ) then
            self:sendTXT( netuser, guild, self.txt.guild.info, 'info' )
        elseif( action2 == 'stats' ) then
            self:sendTXT( netuser, guild, self.txt.guild.stats, 'stats' )
        elseif( action2 == 'invite' ) then
            self:sendTXT( netuser, guild, self.txt.guild.invite, 'invite' )
        elseif( action2 == 'kick' ) then
            self:sendTXT( netuser, guild, self.txt.guild.kick, 'kick' )
        elseif( action2 == 'war' ) then
            self:sendTXT( netuser, guild, self.txt.guild.war, 'war' )
        elseif( action2 == 'rank' ) then
            self:sendTXT( netuser, guild, self.txt.guild.rank, 'rank' )
        elseif( action2 == 'ability' ) then
            self:sendTXT( netuser, guild, self.txt.guild.ability, 'ability' )
        elseif( action2 == 'vault' ) then
            self:sendTXT( netuser, guild, self.txt.guild.vault, 'vault' )
        elseif( action2 == 'calls' ) then
            self:sendTXT( netuser, guild, self.txt.guild.calls, 'calls' )
        elseif( action2 == 'collection' ) then
            self:sendTXT( netuser, guild, self.txt.guild.collection, 'collection' )
        elseif( action2 == 'assassin' ) then
            self:sendTXT( netuser, guild, self.txt.guild.assassin, 'assassin' )
        elseif( action2 == '' ) then
        else
            rust.SendChatToUser( netuser, core.sysname, 'Please type /g create | delete | info | stats | invite | kick | war | rank | vault' )
        end
    else
        rust.SendChatToUser( netuser, core.sysname, 'Invalid command! Please type /g to view all available guild commands.' )
    end
end

--PLUGIN:engageWar
function PLUGIN:engageWar( guild, guild2, netuser )
    if( (guild) and (guild2) ) then
        table.insert( self.Guild[ guild ].war, guild2 )
        table.insert( self.Guild[ guild2 ].war, guild1 )
        self:sendGuildMsg( guild, 'WAR', guild .. ' is now at war with ' .. guild2 .. '!' )
        self:sendGuildMsg( guild2, 'WAR', guild2 .. ' is now at war with ' .. guild .. '!' )
    else
        rust.Notice( netuser, 'Invalid input.' )
    end
end

--PLUGIN:CreateGuild
function PLUGIN:CreateGuild( netuser, name, tag )
    if( self.Guild[ name ] ) then rust.Notice( netuser, 'This guild name is already used.' ) return end
    for k, v in pairs( self.Guild ) do
        if( v.tag == ('[' .. tag .. ']') ) then rust.Notice( netuser, 'This guild tag is already used!' ) return end
    end
    -- Check if player has enough money.
    local b, bal = api.Call( 'ce', 'canBuy', netuser, 0,25,0 )
    if ( bal ) then
        api.Call( 'ce', 'RemoveBalance', netuser, 0,25,0 )
    else
        rust.Notice( netuser, 'You do not have enough money! 25 Silver is required' )
        return
    end
    local netuserID = rust.GetUserID( netuser )
    local entry = {}
    entry.tag = '[' .. tag .. ']'                                                                                   -- Guild Tag
    entry.glvl = 1                                                                                                  -- Guild Level
    entry.xp = 0                                                                                                    -- Experience
    entry.xpforLVL = math.ceil((((2*2)+2)/core.Config.settings.glvlmodifier*100-(2*100)))                           -- xpforLVL
    entry.ranks = { ['Leader']={'candelete','caninvite','cankick','canvault','canwar','canrank'},                   -- Create default Ranks
        ['Co-Leader']={'caninvite','cankick','canvault','canwar'},
        ['War-Leader']={'canwar'},
        ['Quartermaster']={'canvault'},
        ['Assasin']={},
        ['Member']={}
    }
    entry.members = {}                                                                                              -- Members
    entry.members[ netuserID ] = {}
    entry.members[ netuserID ][ 'name' ] = netuser.displayName
    entry.members[ netuserID ][ 'rank' ] = 'Leader'
    entry.members[ netuserID ][ 'moncon' ] = 0
    entry.members[ netuserID ][ 'xpcon' ] = 0
    entry.war = {}                                                                                                  -- Guild is at war with:
    entry.collect = 0                                                                                               -- Collects money from members
    entry.gocollect = 0                                                                                             -- time left for next collection
    entry.interval = 0                                                                                              -- Amount of hours between each collection.
    entry.unlockedperks = {'rally','syg','forglory','cotw',}                                                        -- Perks are unlocked at certain Guild lvls ( Max: 10 )
    entry.activeperks = {}                                                                                          -- Perks are unlocked at certain Guild lvls ( Max: 10 )
    timer.Once( 1, function()
        rust.SendChatToUser( netuser, core.sysname, 'Creating Guild...' )
        timer.Once( 3, function()rust.SendChatToUser( netuser, core.sysname, 'Creating guild nameplates...' ) end )
        timer.Once( 6, function()rust.SendChatToUser( netuser, tostring( name ), 'Integrating tag...' ) end )
        timer.Once( 9, function()rust.SendChatToUser( netuser, tostring( '[' .. tag .. '] ' .. name ), 'Creating ' .. tostring( name ) .. ' user interface...' ) end )
        timer.Once( 16, function()rust.SendChatToUser( netuser, tostring( '[' .. tag .. '] ' .. name ), 'Feeding the chickens...' ) end )
        timer.Once( 18, function()rust.SendChatToUser( netuser, tostring( '[' .. tag .. '] ' .. name ), 'Your guild has been created!' ) end )
        timer.Once( 19, function()
            self.Guild[ name ] = entry                                                                                  -- Add complete table to Guilds file
            char.User[ netuserID ][ 'guild' ] = name                                                                    -- Add guild to userdata.
            self:UserSave()
            self:GuildSave() end)
    end )
end
--[[
    entry.vault = {}                                                                                                -- Vault
    entry.vault[ 'money' ][ 'gp' ] = 0                                                                              -- Gold in vault
    entry.vault[ 'money' ][ 'sp' ] = 0                                                                              -- Silver in vault
    entry.vault[ 'money' ][ 'cp' ] = 0                                                                              -- Copper in vault
    entry.vault[ 'weapons' ] = {}                                                                                   -- Weapons in vault
    entry.vault[ 'weapons' ] = {}                                                                                   -- Armor in vault
    entry.vault[ 'materials' ] = {}                                                                                 -- Metarials in vault
]]--

--PLUGIN:getGuildTag
function PLUGIN:getGuildTag( netuser )
    local guild = self:getGuild( netuser )
    if ( guild ) then
        local data = self:getGuildData( guild )
        local tag = data.tag
        return tag
    end
    return false
end

--PLUGIN:getGuildMembers
function PLUGIN:getGuildMembers( guild )
    local members = self.Guild[ guild ].members
    return members
end

--PLUGIN:sendGuildMsg
function PLUGIN:sendGuildMsg( guild, name, msg )
    local guilddata = self:getGuildData( guild )
    for k,v in pairs( self.Guild[ guild ].members ) do
        local b, targuser = rust.FindNetUsersByName( v.name )
        if( b ) then rust.SendChatToUser( targuser, guilddata.tag .. ' ' ..v.name, msg ) end
    end
end

--PLUGIN:delGuild
function PLUGIN:delGuild( guild )
    -- Delete guild from userdata.
    for k, v in pairs( self.Guild[ guild ].members ) do
        char.User[ k ].guild = nil
    end
    self:UserSave()
    -- Delete guild from self.Guild
    self.Guild[ guild ] = nil
    self:GuildSave()
end

--PLUGIN:getGuild
function PLUGIN:getGuild( netuser )
    local userID = rust.GetUserID( netuser )
    local guild = false
    if( char.User[ userID ].guild ) then guild = char.User[ userID ].guild end
    return guild
end

--PLUGIN:getGuildData
function PLUGIN:getGuildData( guild )
    local data = self.Guild[ guild ]
    if( not data ) then return false end
    return data
end

--PLUGIN:getGuildLeader
function PLUGIN:getGuildLeader( guild )
    local data = self:getGuildData( guild )
    for k ,v in pairs( data.members ) do
        if( v.rank == 'Leader' ) then
            return v.name
        end
    end
end

--PLUGIN:hasAbility
function PLUGIN:hasAbility( netuser, guild, ability )
    local rank = self:getRank( netuser, guild )
    local userID = rust.GetUserID( netuser )
    local val = func:containsval( self.Guild[ guild ].ranks[rank], ability )
    return val
end

--PLUGIN:hasRank
function PLUGIN:hasRank( netuser, guild, rank )
    local userID = rust.GetUserID( netuser )
    local grank = self.Guild[ guild ].members[ userID ].rank
    if ( grank == rank ) then return true else return false end
end

--PLUGIN:getRank
function PLUGIN:getRank( netuser, guild )
    local userID = rust.GetUserID( netuser )
    local rank = self.Guild[ guild ].members[ userID ].rank
    return rank
end

--PLUGIN:isRival
function PLUGIN:isRival( guild1, guild2 )
    local war = func:containsval( self.Guild[ guild1 ].war, guild2)
    return war
end

-- GUILD DOOR ACCESS!
local DeployableObjectOwnerID = util.GetFieldGetter( Rust.DeployableObject, "ownerID", true )
function PLUGIN:CanOpenDoor( netuser, door )

    -- Get and validate the deployable
    local deployable = door:GetComponent( "DeployableObject" )
    if (not deployable) then return end

    -- Get the owner ID and the user ID
    local ownerID = tostring( DeployableObjectOwnerID( deployable ) )
    local userID = rust.GetUserID( netuser )

    -- check if user is owner.
    if (ownerID == userID) then rust.Notice( netuser, 'Entered your own house! ') return true end

    -- if not get guilds
    local b, ownernetuser = rust.FindNetUsersByName( char.User[ ownerID ].name )
    if( not b ) then return end
    local ownerGuild = self:getGuild( ownernetuser )
    local userGuild = self:getGuild( netuser )
    if not ( ownerGuild and userGuild ) then return end

    -- Check if in same guild
    if ( userGuild == ownerGuild ) then rust.Notice( netuser, 'Entered ' .. char.User[ ownerID ].name .. '\'s house! ') return true end
end

-- GUILD UPDATE AND SAVE
function PLUGIN:GuildSave()
    self.GuildFile:SetText( json.encode( self.Guild, { indent = true } ) )
    self.GuildFile:Save()
end