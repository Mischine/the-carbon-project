PLUGIN.Title = 'carbon_guild'
PLUGIN.Description = 'guild module'
PLUGIN.Version = '0.0.2'
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
        self:GuildSave()
    end

    self.Guild[ 'temp' ] = {}

    self:AddChatCommand( 'destroy', self.destroy )

    -- self.TimerCall = timer.Repeat( 5, function() self:CallTimer() end)
end

function PLUGIN:destroy(netuser, cmd ,args)
    if not netuser:CanAdmin() then return end
    self.TimerCall:Destroy()
end

--PLUGIN:Guilds commands
function PLUGIN:GuildIntro( netuser )
    local guild = self:getGuild( netuser )
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
end

function PLUGIN:GuildCreate( netuser, args )
    if self:getGuild( netuser ) then rust.Notice( netuser, 'You\'re already in a guild!' ) return end
    -- /g create 'Guild Name' 'Guild Tag'
    if(( args[2] ) and ( args[3] )) then
        local lvl = tonumber( char:getLvl( netuser ) )
        -- if( not ( lvl >= 10 )) then rust.Notice( netuser, 'level 10 required to create your own guild!' ) return end
        local name = tostring( args[2] )
        local tag = tostring( args[3] )
        tag = string.upper( tag )
        -- Tag/name language check.
        if( func:containsval( core.Config.settings.censor.tag, tag ) ) then rust.Notice( netuser, 'Can not compute. Error code number B' ) return end
        for _, v in ipairs( core.Config.settings.censor.chat ) do
            local found = string.find( name, v )
            if ( found ) then
                rust.Notice( netuser, 'Can not compute. Error code number B' )
                return false
            end
        end
        for _, v in ipairs( core.Config.settings.censor.tag ) do
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
        rust.SendChatToUser( netuser, core.sysname, '/guild create "Guild Name" "Guild Tag" ')
    end
end

function PLUGIN:GuildDelete( netuser, args )
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
end

function PLUGIN:GuildInfo( netuser )
    local guild = self:getGuild( netuser )
    if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild!' ) return end
    local data = self:getGuildData( guild )
    local a=data.glvl+1
    local b=data.glvl
    local c=core.Config.guild.settings.glvlmodifier
    local d=(a*a+a)/c*100-a*100             -- xp required for next lvl
    local e=math.floor(data.xp/d*100+0.5)   -- Percent currently to next lvl
    local f=d-data.xp                       -- xp left to go until next lvl
    local g=(b*b+b)/c*100-b*100             -- Amount needed for current lvl
    if a==2 and core.Config.guild.settings.glvlmodifier>=2 then g=0 end
    if (a == 2) and (core.Config.guild.settings.glvlmodifier >= 2) then f = 0 end
    rust.SendChatToUser(netuser,' ',' ')
    rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
    rust.SendChatToUser(netuser,core.sysname,'║ guild > ' .. guild .. ' > info')
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    rust.SendChatToUser(netuser,core.sysname,'║ Guild Name    : ' .. guild)
    rust.SendChatToUser(netuser,core.sysname,'║ Guild Tag        : ' .. data.tag)
    rust.SendChatToUser(netuser,core.sysname,'║ Guild Level     : ' .. b)
    if data.glvl ~= 10 then
        rust.SendChatToUser(netuser,core.sysname,'║ Required for guild level ' .. tostring(a) )
        rust.SendChatToUser(netuser,core.sysname,'║ members: ( ' .. func:count( data.members ) .. '/' .. core.Config.guild.settings.lvlreq[tostring(a)] .. ' )' )
        rust.SendChatToUser(netuser,core.sysname,'║ ' .. func:xpbar(math.floor( func:count( data.members ) / core.Config.guild.settings.lvlreq[tostring(a)] * 100), 32))
    end
    rust.SendChatToUser(netuser,core.sysname,'║ Guild XP          : (' .. data.xp .. '/' .. d .. ')   [' .. e .. '%]   (+' .. f .. ')')
    rust.SendChatToUser(netuser,core.sysname,'║ ' .. func:xpbar( e, 32))
    rust.SendChatToUser(netuser,core.sysname,'║ ')
    rust.SendChatToUser(netuser,core.sysname,'║ Vault lvl: ' .. tostring(data.vault.lvl))
    rust.SendChatToUser(netuser,core.sysname,'║ [ Gold: ' .. data.vault.money.g .. ' ] [ Silver: ' .. data.vault.money.s .. ' ] [ Copper: ' .. data.vault.money.c .. ' ]')
    rust.SendChatToUser(netuser,core.sysname,'║ Capacity          :  (' .. data.vault.cap .. '/' .. core.Config.guild.vault[tostring(data.vault.lvl)].cap .. ')   [ ' .. math.floor((data.vault.cap/core.Config.guild.vault[tostring(data.vault.lvl)].cap)*100) .. '% ]   (+' .. core.Config.guild.vault[tostring(data.vault.lvl)].cap-data.vault.cap .. ')' )
    rust.SendChatToUser(netuser,core.sysname,'║ ' .. func:xpbar(math.floor((data.vault.cap/core.Config.guild.vault[tostring(data.vault.lvl)].cap)*100) , 32))
    rust.SendChatToUser(netuser,core.sysname,'║ ')
    rust.SendChatToUser(netuser,core.sysname,'║ Guild Leader   : ' .. self:getGuildLeader( guild ))
    rust.SendChatToUser(netuser,core.sysname,'║ Members        : ' .. func:count( data.members ))
    rust.SendChatToUser(netuser,core.sysname,'║ Calls                  : ' .. table.concat( data.unlockedcalls, ', ' ))
    rust.SendChatToUser(netuser,core.sysname,'║ Active Calls    : ' .. table.concat( data.activecalls, ', ' ))
    rust.SendChatToUser(netuser,core.sysname,'║ War                   : ' .. table.concat( data.war, ', ' ))
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    rust.SendChatToUser(netuser,core.sysname,'║ ⌘')
    rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
    rust.SendChatToUser(netuser,' ',' ')
end

function PLUGIN:GuildStats( netuser )
    -- /g stats                                 -- Displays a lists of guild statistics
    local guild = self:getGuild( netuser )
    if( not guild ) then self.Notice( netuser, 'You\'re not in a guild!' ) return end
    rust.SendChatToUser(netuser,' ',' ')
    rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
    rust.SendChatToUser(netuser,core.sysname,'║ guild > ' .. guild .. ' > stats')
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    rust.SendChatToUser(netuser,core.sysname,'║ COMING SOON!')
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    rust.SendChatToUser(netuser,core.sysname,'║ ⌘')
    rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
    rust.SendChatToUser(netuser,' ',' ')
end

function PLUGIN:GuildInvite( netuser, args )
    local guild = self:getGuild( netuser )
    if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
    if( self:hasAbility( netuser, guild, 'caninvite' ) ) then
        local targname = tostring( args[ 1 ] )
        local b, targuser = rust.FindNetUsersByName( targname )
        if ( not b ) then
            if( targuser == 0 ) then
                rust.Notice( netuser, 'No user found with the name: ' .. util.QuoteSafe( targname ) )
            else
                rust.Notice( netuser, 'Multiple users found with the name: ' .. util.QuoteSafe( targname ) )
            end
            return end
        local hisguild = self:getGuild( targuser )
        if hisguild then rust.Notice( targname .. ' is already in a guild!' ) return end
        local targuserID = rust.GetUserID( targuser )
        local members = self:getGuildMembers( guild )
        print (tostring( members ))
        if( self.Guild[ guild].members[ targuserID ] ) then rust.Notice( netuser, tostring( targname ) .. ' is already in ' .. guild ) return end
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
        rust.Notice( targuser, 'You\'ve been invited to ' .. guild .. '. /guild accept to join the guild.', 15)
        rust.Notice( netuser, 'You\'ve invited ' .. targname .. ' to ' .. guild )
    else
        rust.Notice( netuser, 'You\'re not allowed to invite players to the guild!' )
    end
end

function PLUGIN:GuildMembers( netuser, args )
    local guild = self:getGuild( netuser )
    if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild!' ) return end
    local data = self:getGuildData( guild )
    if not data then rust.Notice( netuser, 'Guild data not found! Report to a GM please.' ) return end
    if( not args[1] ) then -- get list of all guild members
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
    elseif ( args[1]) then -- get info about a specific guild member
        local name = tostring( args[1] )
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
    end
end

function PLUGIN:GuildAccept( netuser )
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
        char:UserSave()
        self:GuildSave()
    end
end

function PLUGIN:GuildLeave( netuser,args )
    local guild = self:getGuild( netuser )
    if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild!') return end
    if( not args[2] ) then rust.Notice( netuser, '/g leave [guildtag] ' ) return end
    local netuserID = rust.GetUserID( netuser )
    self.Guild[ guild ].members[ netuserID ] = nil
    char.User[ netuserID ].guild = nil
    self:sendGuildMsg( guild, netuser.displayName, 'has left the guild! =(' )
    local count = func:count( self.Guild[ guild ].members )
    if ( count == 0 ) then self.Guild[ guild ] = nil rust.Notice( netuser, guild .. ' has been disbanned!' ) end
    self:GuildSave()
    char:UserSave()
end

function PLUGIN:GuildKick( netuser,args )
    if( not args[1] ) then rust.Notice( netuser, '/gkick "name" ' )return end
    local guild = self:getGuild( netuser )
    if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
    if( not self:hasAbility( netuser, guild, 'cankick' ) ) then rust.Notice(netuser, 'You\'re not permitted to kick a player from the guild.' ) return end
    local targname = util.QuoteSafe( args[1] )
    if( netuser.displayName == targname ) then rust.Notice( netuser, 'You cannot kick yourself...' ) return end
    local targuserID = false
    for k, v in pairs( self.Guild[ guild ].members ) do if( v.name:lower() == targname:lower() ) then targuserID = k break end end
    if( not targuserID ) then rust.Notice( netuser, 'player ' .. targname .. ' is not a member of ' .. guild .. '.') return end
    local date = System.DateTime.Now:ToString(core.Config.dateformat)
    rust.Notice(netuser,  'Kicked ' .. targname .. ' from ' .. guild )
    mail:sendMail( targuserID, netuser.displayName, date, 'You\'ve been kicked from the guild ' .. guild, guild )
    self.Guild[ guild ].members[ targuserID ] = nil
    char.User[ targuserID ].guild = nil
    char:UserSave()
    self:GuildSave()
end

function PLUGIN:GuildCall( netuser, cmd, args )
    local guild = self:getGuild( netuser )
    local data = self:getGuildData( guild )
    if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
    if args[1] then
        if args[1]:lower() == 'activate' then
            local call = tostring(args[2])
            if( not self:hasAbility( netuser, guild, 'cancall' ) ) then rust.Notice( netuser, 'You are not allowed to activate calls!' ) return end
            if not core.Config.guild.calls[call] then
                local content = {
                    ['header'] = call .. ' does not exist',
                    ['msg']= 'Available calls: cotw, glory, syd and rally'
                }
                func:TextBox(netuser,content,cmd,args)
                return end
            if not func:containsval(data.unlockedcalls, call) then rust.Notice( netuser, call .. ' is not unlocked!' ) return end
            if data.activecalls[ call ] then rust.Notice( netuser, call .. ' is already active!' ) return end
            data.activecalls[ call ] = {}
            data.activecalls[ call ][ 'time' ] = 240
            self:sendGuildMsg( guild, 'INCOMING CALL', '::::::::: ' .. call .. ' is activated! :::::::::' )
            self:GuildSave()
            return
        end
    end
    -- display calls, if they're active and what they do. and their modifiers.
    if args[1] then
        local i = 1
        while args[i] do
            args[i] = nil
            i = i + 1
        end
    end
    local content = {
        ['header'] = 'Available Calls',
        ['msg'] = 'Choose wisely when activating a call. They\'re only for 4 hours! \nHere is a list of available calls:',
        ['list'] = {},
        ['cmds'] = {},
        ['suffix'] = 'Adding a call is only for 4 hours!'
    }
    local count = func:count( data.unlockedcalls )
    if count > 0 then
        for _,v in pairs( data.unlockedcalls ) do
            local call = core.Config.guild.calls[v].name
            local g,s = core.Config.guild.calls[v].requirements.cost.g, core.Config.guild.calls[v].requirements.cost.s
            local cost = '[ Gold: ' .. g .. ' ]  [ Silver: ' .. s .. ' ] '
            table.insert(content.list, cost .. call .. ' (' .. v .. ')' )
        end
    else
        table.insert(content.list, 'There are no calls unlocked!' )
    end
    local count2 = func:count(data.activecalls)
    if count2 > 0 then
        table.insert(content.list, ' ' )
        table.insert(content.list, 'Active Calls' )
        for k, v in pairs( data.activecalls) do
            local call = core.Config.guild.calls[k].name .. ' | Time Left: ' .. tostring(v.time) .. ' minutes'
            table.insert(content.list, call )
        end
    end

    if( self:hasAbility( netuser, guild, 'cancall' ) ) then -- can add calls
        table.insert(content.cmds, 'activate' )
    end
    func:TextBox(netuser,content,cmd,args)
end

function PLUGIN:GuildWar( netuser )
    local guild = self:getGuild( netuser )
    if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
    if( not self:hasAbility( netuser, guild, 'canwar' ) ) then rust.Notice(netuser, 'You\'re not permitted to initiate a war!' ) return end
    local targtag = '['..string.upper( tostring( args[1] ))..']'
    for k,v in pairs( self.Guild ) do
        if( v.tag == targtag )then
            self:engageWar( guild, k, netuser )
            return
        end
    end
    rust.Notice( netuser, 'Tag does not exist.' )
end

function PLUGIN:GuildRank( netuser, cmd, args )
    if( not args[1] ) then
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
        local rank = self:getRank( netuser, guild )
        rust.SendChatToUser(netuser,' ',' ')
        rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
        rust.SendChatToUser(netuser,core.sysname,'║ guild > ' .. guild .. ' > rank')
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
        rust.SendChatToUser(netuser,core.sysname,'║ Your current rank status: ' .. tostring( rank ))
        rust.SendChatToUser(netuser,core.sysname,'║ /rank list shows the power of each rank.')
        if( self:hasAbility( netuser, guild, 'canrank' ) ) then
            rust.SendChatToUser(netuser,core.sysname,'║ /rank [list][give][add][edit].')
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
    if( args[1] ) then args[1] = tostring(args[1]):lower() end
    -------------------------------------
    if( args[1] == 'list' ) then                            -- /rank list | shows list of ranks + abilities
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
    elseif( args[1] == 'give' ) then
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
        if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to give ranks to a player.' ) return end

        if( args[2] and args[3] ) then
            local netuserID = rust.GetUserID( netuser )
            local targname = tostring( args[ 3 ] )
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
            if( not self.Guild[ guild ].ranks[ tostring( args[2]) ] ) then rust.Notice( netuser, tostring( args[2] .. ' is not an available rank! ')) return end
            if( self.Guild[ guild ].members[targuserID].rank['Leader']) then rust.Notice( netuser, 'You\'re not able to change the leaders rank! ') return end
            if( tostring(args[2]) == 'Leader' ) then rust.Notice( netuser, 'You cannot give anyone the Leader rank!') return end
            self.Guild[ guild ].members[targuserID].rank = tostring( args[2] )
            rust.Notice(netuser, targname .. ' is now a ' .. tostring( args[2] ))
            self:GuildSave()
        else
            local content = {
                ['header']='Incomplete command!',
                ['msg']='/rank give "rank" "name" '
            }
            func:TextBoxError(netuser,content,cmd,args)
            return
        end

    elseif( args[1] == 'add' ) then                         -- /rank add 'rank' | Create a new custom rank            [ canrank ]
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
        if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to add ranks.' ) return end
        if( not args[2] ) then rust.SendChatToUser( netuser, '/rank add "rankname" ') return end
        if( self.Guild[ guild ].ranks[ tostring(args[2]) ]) then rust.Notice( netuser, args[2] .. ' already exist!') return end
        self.Guild[ guild ].ranks[tostring(args[2])] = {}
        rust.SendChatToUser( netuser, 'Added new rank: ' .. args[2] )
        self:GuildSave()
    elseif( args[1] == 'del' ) then                        -- /rank del 'rank' | delete a rank           [ canrank ]
        if(( args[2] ) and ( not args[3] )) then
            local guild = self:getGuild( netuser )
            if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
            if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to add ranks.' ) return end
            if ( args[2] == "Assasin" ) then rust.Notice( netuser, 'You cannot delete rank Assasin!' ) return end
            if ( args[2] == "Leader" ) then rust.Notice( netuser, 'You cannot delete rank Leader!' ) return end
            if( self.Guild[ guild ].ranks[tostring(args[2])]) then
                self.Guild[ guild ].ranks[tostring(args[2])] = nil
                rust.Notice( netuser, 'Rank ' .. args[2] .. ' has been deleted! ')
                return
            else
                rust.Notice( netuser, 'Rank ' .. args[2] .. ' does not exist!' )
                return
            end
        else
            rust.SendChatToUser( netuser, '/rank del "rank" ' )
        end
    elseif( args[1] == 'edit' ) then                        -- /rank edit 'rank' | Create a new custom rank           [ canrank ]
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
        if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to edit ranks.' ) return end
        if( not args[2] and not args[3] ) then

            local content = {
                ['msg'] ='Ranks can be configured however you want! \n To configure a rank: /rank edit "rankname" [ID] true/false',
                ['list'] ={'[1] candelete : Is able to delete the guild.','[2] caninvite : Is able to invite new players to the guild.','[3] cankick   : Is able to kick guildmembers.','[4] canvault  : Coming soon!','[5] canwar    : Is able to start wars with other guilds.','[6] canrank   : Is able to give/add/edit ranks.','[7] cancall   : Is able to activate calls.'}
            }
            func:TextBox(netuser,content,cmd,args)
        elseif( args[2] and args[3] and args[4] ) then
            if ( args[2] == "Assasin" ) then rust.Notice( netuser, 'You cannot edit rank Assasin!' ) return end
            if ( not self.Guild[guild].ranks[tostring(args[2])] ) then rust.Notice( netuser, 'Rank: ' .. tostring(args[2]).. ' doesn\'t exist!' ) return end
            if ( tonumber(args[3]) > 7 ) then rust.Notice( netuser, 'This rank abillity is not found. Chooose between 1 - 7' ) return end
            if(( args[4] == 'true' ) or ( args[4] == 'false' )) then
                local tbl = {'candelete','caninvite','cankick','canvault','canwar','canrank', 'cancall' }
                local ability = tbl[ tonumber( args[3] )]
                if( args[4] == 'true' ) then
                    local contains = func:containsval( self.Guild[ guild ].ranks[tostring(args[2])])
                    if( contains ) then rust.Notice( netuser, tostring(args[2]) .. ' already has ' .. ability ) return end
                    table.insert( self.Guild[ guild ].ranks[tostring(args[2])], ability )
                    rust.Notice( netuser, ability .. ' has been added to ' .. tostring( args[2] ))
                elseif( args[4] == 'false' ) then
                    local contains = func:containsval( self.Guild[ guild ].ranks[tostring(args[2])], ability )
                    if( not contains ) then rust.Notice( netuser, tostring(args[2]) .. ' doesn\'t have ' .. ability ) return end
                    for i,v in pairs( self.Guild[ guild ].ranks[tostring(args[2])] ) do
                        if( v == ability ) then
                            table.remove( self.Guild[ guild ].ranks[tostring(args[2])], i )
                            rust.Notice( netuser, ability .. ' has been taken from ' .. tostring( args[2] ))
                        end
                    end
                end
                self:GuildSave()
            else
                local content = {
                    ['msg'] ='Ranks can be configured however you want! \n To configure a rank: /rank edit "rankname" [ID] true/false',
                    ['list'] ={'[1] candelete : Is able to delete the guild.','[2] caninvite : Is able to invite new players to the guild.','[3] cankick   : Is able to kick guildmembers.','[4] canvault  : Coming soon!','[5] canwar    : Is able to start wars with other guilds.','[6] canrank   : Is able to give/add/edit ranks.',}
                }
                func:TextBox(netuser,content,cmd,args)
            end
        else
            rust.SendChatToUser( netuser, '/rank edit "rankname" [ID] true/false || /rank ;For more information')
        end
    else
        if( self:hasAbility( netuser, guild, 'canrank' ) ) then rust.SendChatToUser( netuser, guild, '/rank [list][give][take][add][edit]' )
        else rust.SendChatToUser( netuser, '/rank [list]' ) end
    end
end

function PLUGIN:GuildVault( netuser, cmd, args )
    local guild = self:getGuild( netuser )
    if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
    if not args[1] then
        local data = self:getGuildData( guild )
        -- List capacity, money and items in the vault.
        local content = {
            ['subheader'] ='[ Gold: ' .. data.vault.money.g .. ' ] [ Silver: ' .. data.vault.money.s .. ' ] [ Copper: ' .. data.vault.money.c .. ' ]',
            ['header'] ='Vault level: ' .. tostring( data.vault.lvl) ,
            'Capacity: (' .. data.vault.cap .. '/' .. core.Config.guild.vault[tostring(data.vault.lvl)].cap .. ')   [ ' .. math.floor((data.vault.cap/core.Config.guild.vault[tostring(data.vault.lvl)].cap)*100) .. '% ]   (+' .. core.Config.guild.vault[tostring(data.vault.lvl)].cap-data.vault.cap .. ')',
            ['list'] = {'Capacity: (' .. data.vault.cap .. '/' .. core.Config.guild.vault[tostring(data.vault.lvl)].cap .. ')   [ ' .. math.floor((data.vault.cap/core.Config.guild.vault[tostring(data.vault.lvl)].cap)*100) .. '% ]   (+' .. core.Config.guild.vault[tostring(data.vault.lvl)].cap-data.vault.cap .. ')',
                func:xpbar(math.floor((data.vault.cap/core.Config.guild.vault[tostring(data.vault.lvl)].cap)*100) , 32)},
            ['cmds'] = {'store','withdraw','upgrade','donate'}
        }
        for k,v in pairs( data.vault.items ) do
            table.insert( content.list, tostring(v) .. 'x ' .. k  )
        end
        func:TextBox(netuser,content,cmd,args)

    elseif args[1]:lower() == 'help' then
        local content = {
            ['msg'] ='',
            ['list'] = {'Level 1: Cost: free | 50 vault capacity.','Level 2: Cost: 3 Gold | 500 vault capacity.','Level 3: Cost: 5 Gold | 750 vault capacity.','Level 4: Cost: 10 Gold | 1000 vault capacity.','Level 5: Cost: 20 Gold | 1500 vault capacity.'},
            ['suffix'] = 'To upgrade your vault use /vault upgrade',
            ['cmds'] = {'store','withdraw','upgrade','donate'}
        }
        func:TextBox(netuser,content,cmd,args)
    elseif args[1]:lower() == 'store' then
        -- /g vault add                             -- Add items/money to the guild vault
        if( not self:hasAbility( netuser, guild, 'canvault' ) ) then rust.Notice(netuser, 'You\'re not permitted to interact with the guild vault.' ) return end
        if not args[2] and not args[3] then
            local content = {
                ['msg'] ='Storing items in the vaul will take up capacity. Every item is 1 capacity. A M4 is 1 capacity, 1 stone is 1 capacity. \n to store an item in the vault type /vault store "itemname" [amount]',
            }
            func:TextBox(netuser,content,cmd,args)
        elseif args[2] and args[3] then
            -- /g vault store "item" amount
            local guilddata = self:getGuildData( guild )
            local item = args[2]
            local amount = tonumber( args[3] )
            if not amount then rust.Notice( netuser, 'Invalid amount!' ) return end
            if guilddata.vault.cap == core.Config.guild.vault[tostring(guilddata.vault.lvl)].cap then rust.Notice( netuser, 'Guild vault capacity is maxed!' ) return end
            if (( guilddata.vault.cap + amount ) > core.Config.guild.vault[tostring(guilddata.vault.lvl)].cap ) then
                amount = core.Config.guild.vault[tostring(guilddata.vault.lvl)].cap - guilddata.vault.cap
                rust.SendChatToUser(netuser,core.sysname , 'Amount adjusted to ' ..  tostring(amount) .. ' to prevent overflow.' )
            end
            self:StoreItems( netuser, item, amount, guilddata )
        end
    elseif args[1]:lower() == 'donate' then
        if not args[2] then
            local content = {
                ['msg'] ='To donate money type /vault donate gold silver copper \n For example /g vault donate 2 5 10 donates 2 gold 5 Silver and 10 Copper.',
            }
            func:TextBox(netuser,content,cmd,args)
        else
            local g,s,c = 0,0,0
            g = tonumber(args[2])
            if not g then rust.Notice(netuser, 'Invalid Gold amount!' ) return end
            if args[3] then s = tonumber(args[3]) end
            if not g then rust.Notice(netuser, 'Invalid Silver amount!' ) return end
            if args[4] then c = tonumber(args[4]) end
            if not c then rust.Notice( netuser, 'Invalid Copper amount!' ) return end
            local canbuy = econ:canBuy( netuser, g, s, c )
            if not canbuy then rust.Notice( netuser, 'Not enough balance!' ) return end
            self:GuildDeposit( netuser.displayName, guild, g,s,c )
            econ:RemoveBalance( netuser, g, s, c )
            econ:Save()
        end
    elseif args[1]:lower() == 'withdraw' then
        -- /g vault withdraw                        -- withdraw items/money from the guild vault
        if( not self:hasAbility( netuser, guild, 'canvault' ) ) then rust.Notice(netuser, 'You\'re not permitted to interact with the guild vault.' ) return end
        if not args[2] then
            local content = {
                ['msg'] ='To withdraw /vault withdraw "ItemName" [amount] OR /vault withdraw money Gold Silver Copper',
            }
            func:TextBox(netuser,content,cmd,args)
            return end
        if args[2] == 'money' then
            if not args[3] then
                local content = {
                    ['msg'] = 'Syntax: /vault withdraw money GOLD SILVER COPPER. For example: /g vault withdraw 0 8 4 || This will withdraw 8 silver and 4 copper.'
                }
            else
                local g,s,c = 0,0,0
                g = tonumber(args[3])
                if not g then rust.Notice(netuser, 'Invalid Gold amount!' ) return end
                if args[4] then s = tonumber(args[4]) end
                if not s then rust.Notice(netuser, 'Invalid Silver amount!' ) return end
                if args[5] then c = tonumber(args[5]) end
                if not c then rust.Notice( netuser, 'Invalid Copper amount!' ) return end
                local canbuy = self:canBuyGuild( guild, g, s, c )
                if not canbuy then rust.Notice( netuser, 'Not enough balance in the guild vault!' ) return end
                self:GuildWithdraw( netuser.displayName, guild, g,s,c )
                econ:AddBalance( netuser, g, s, c )
                econ:Save()
            end
        elseif args[2] and args[3] then
            local guilddata = self:getGuildData( guild )
            local itemname = tostring(args[2])
            local datablock = rust.GetDatablockByName( itemname )
            if not datablock then rust.Notice( netuser, itemname .. ' does not exist!') return end
            if not guilddata.vault.items[ itemname ] then rust.Notice( netuser, 'Guild vault does not have ' .. itemname .. ' stored!' ) return end
            local amount = tonumber(args[3])
            if not amount then rust.Notice(netuser, 'Invalid amount!' ) return end
            local vaultamount = guilddata.vault.items[ itemname ]
            if amount > vaultamount then amount = vaultamount rust.SendChatToUser( netuser,core.sysname, 'amount set to ' .. tostring( vaultamount )) end
            local inv = rust.GetInventory(netuser)
            if not inv then rust.Notice( netuser, 'Inventory not found, please relog!' ) return end
            guilddata.vault.items[ itemname ] = guilddata.vault.items[ itemname ] - amount
            if guilddata.vault.items[ itemname ] == 0 then guilddata.vault.items[ itemname ] = nil end
            inv:AddItemAmount( datablock, amount )
            self:sendGuildMsg( guild, netuser.displayName, ':::::::::::::: has withdrawed: ' .. tostring( amount ) .. 'x ' .. itemname .. ' ::::::::::::::' )
            guilddata.vault.cap = guilddata.vault.cap - amount
            self:GuildSave()
            char:UserSave()
        else
            local content = {
                ['msg'] ='To withdraw /vault withdraw "ItemName" [amount] OR /g vault withdraw money Gold Silver Copper',
            }
            func:TextBox(netuser,content,cmd,args)
        end
    elseif args[1]:lower() == 'upgrade' then
        -- /g vault upgrade                         -- Upgrade your vault to the next lvl
        if( not self:hasAbility( netuser, guild, 'canvault' ) ) then rust.Notice(netuser, 'You\'re not permitted to interact with the guild vault.' ) return end
        local data = self:getGuildData( guild )
        if not data then rust.Notice(netuser, 'Guild data not found.' ) return end
        if not args[2] then
            if data.glvl >= core.Config.guild.vault[tostring(data.vault.lvl + 1)].req then
                local content = {
                    ['header']='Upgrading vault to level: ' .. data.vault.lvl + 1,
                    ['msg']='Upgrading to vault level will cost: Gold: ' .. core.Config.guild.vault[ tostring(data.vault.lvl + 1)].cost,
                    ['suffix']='Type "/vault upgrade yes" to upgrade your vault!'
                }
                func:TextBox(netuser,content,cmd,args)
            else
                local content = {
                    ['header']='Upgrading vault to level: ' .. data.vault.lvl + 1,
                    ['msg']='You cannot level your guild vault! Guild level required: ' .. core.Config.guild.vault[tostring(data.vault.lvl + 1)].req
                }
                func:TextBox(netuser,content,cmd,args)
            end
            return end
        if args[2]:lower() == 'yes' then
            -- Uprade vault
            local g = core.Config.guild.vault[tostring(data.vault.lvl +1)].cost
            local canbuy = self:canBuyGuild( guild, g, 0, 0)
            if not canbuy then rust.Notice(netuser, 'Insufficient guild funds!' ) return end
            data.vault.lvl = data.vault.lvl + 1
            data.vault.cap = core.Config.guild.vault[ tostring(data.vault.lvl + 1)].cap
            self:GuildWithdraw( netuser.displayName, guild, g, 0, 0 )
            local msg = '::::::::::: has upgraded the vault to level ' .. data.vault.lvl .. ' :::::::::::'
            self:sendGuildMsg( guild, netuser.displayName, msg )
            self:GuildSave()
        end
    else
        local content = {
            ['msg'] ='',
            ['list'] = {'Level 1: Cost: free | 50 vault capacity.','Level 2: Cost: 3 Gold | 500 vault capacity.','Level 3: Cost: 5 Gold | 750 vault capacity.','Level 4: Cost: 10 Gold | 1000 vault capacity.','Level 5: Cost: 20 Gold | 1500 vault capacity.'},
            ['suffix'] = 'To upgrade your vault use /vault upgrade',
            ['cmds'] = {'store','withdraw','upgrade','donate'}
        }
        func:TextBox(netuser,content,cmd,args)
    end
end

function PLUGIN:GuildHelp( netuser, cmd, args )
    local guild = self:getGuild( netuser )
    if( not guild ) then guild = core.sysname end
    if not args[2] then
        local content = {
            ['msg'] ='Learn more about guilds in Carbon!',
            ['cmds'] ={'create','delete','info','stats','invite','kick','war','rank','rank','ability','vault','calls','assassin'}
        }
        func:TextBox(netuser,content,cmd,args)
        return
    end
    local action2 = tostring(args[2]:lower())
    if( action2 == 'create' ) then
        local content = {
            ['header'] ='Syntax: /g create "guildname" "TAG"',
            ['msg'] ='Create a guild by typing /g create "GuildName" "TAG". \n There are disabled tags. There is a fee to creating a guild. To create a guild it will cost you 25 silver and you must be atleast level 10.',
        }
        func:TextBox(netuser,content,cmd,args)
    elseif( action2 == 'delete' ) then
        local content = {
            ['header'] ='It is required to have the ability: "candelete"',
            ['msg'] ='The leader is the only person who can dissemble a guild. \n This is adjustable by editing rank permissions. We do not recommend changing this setting!',
        }
        func:TextBox(netuser,content,cmd,args)
    elseif( action2 == 'info' ) then
        local content = {
            ['msg'] ='/g info displays information about a guild. \n Information regarding guildname, guild tag, guild level, current guild xp, number of members, available calls, active calls, and the tags of enemey guilds.',
        }
        func:TextBox(netuser,content,cmd,args)
    elseif( action2 == 'stats' ) then
        local content = {
            ['msg'] ='/g stats displays statistical information about a guild. \n Information regarding player with the most contributed xp and money, ...',
        }
        func:TextBox(netuser,content,cmd,args)
    elseif( action2 == 'invite' ) then
        local content = {
            ['header'] ='It is required to have the ability: caninvite',
            ['msg'] ='/g invite "PlayerName" to initiate someone into your guild. /n The person to be initiated must be online and name correctly spelled and the initiated person will recieve a join message and they can choose to accept. However, the initiated person can deny the invitation to the guild. The initiated member will need to type /g accept. The entire guild will be notified! The guild should welcome the new member and guide him throughout.',
        }
        func:TextBox(netuser,content,cmd,args)
    elseif( action2 == 'kick' ) then
        local content = {
            ['header'] ='It is required to have the ability: cankick',
            ['msg'] ='/g kick "PlayerName" to remove a player from your guild entirely. \n If someone is about to be kicked, the target user does not have to be online and will recieve mail regarding their status being removed from the guild. Due to limitations, reasons for status being remove is not available You can always send them a message using the mail system or /w when they are online.',
        }
        func:TextBox(netuser,content,cmd,args)
    elseif( action2 == 'war' ) then
        local content = {
            ['header'] ='It is required to have the ability: canwar',
            ['msg'] ='/g war "GuildTag" signals a war with another guild of your choice. \n When a guild is in war then all the guild calls will be activated. Guild calls will only work on the enemy guilds.',
        }
        func:TextBox(netuser,content,cmd,args)
    elseif( action2 == 'rank' ) then
        local content = {
            ['header'] ='It is required to have the ability: canrank',
            ['msg'] ='Ranks in guilds are mainly to assign permissions and figurative status. There are 6 default ranks: Leader, Co-Leader, Quartermaster, War-Leader, Assassin ( coming soon! ) and member. Quartermasters are able to add/take from the guild vault.'
        }
        func:TextBox(netuser,content,cmd,args)
    elseif( action2 == 'ability' ) then
        local content = {
            ['msg'] ='Abilities are required for certain actions. These abilities are given per rank. For example, a member of a guild must have the \"caninvite\" to invite other players to the guild. Guild members with the ability \"canrank\" can edit these ranks and add new ranks as well.'
        }
        func:TextBox(netuser,content,cmd,args)
    elseif( action2 == 'vault' ) then
        local content = {
            ['msg'] ='With vault you\'re able to have your own guild vault. Check for more information: /vault'
        }
        func:TextBox(netuser,content,cmd,args)
    elseif( action2 == 'calls' ) then
        local content = {
            ['msg'] ='For more information check: /call'
        }
        func:TextBox(netuser,content,cmd,args)
    elseif( action2 == 'assassin' ) then
        local content = {
            ['msg'] ='COMING SOON!'
        }
        func:TextBox(netuser,content,cmd,args)
    else
        rust.SendChatToUser( netuser, core.sysname, 'Please type /guild create | delete | info | stats' )
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

function PLUGIN:GiveGXP( guild, xp )
    local data = self:getGuildData( guild )
    if not data then return end
    if data.glvl == core.Config.guild.settings.maxguildlvl then return end
    local members = func:count( data.members )
    local calcLvl = math.floor((math.sqrt(100*((core.Config.guild.settings.glvlmodifier*(data.xp+xp))+25))+50)/100)
    rust.BroadcastChat( tostring( calcLvl ))
    if( calcLvl ~= data.glvl ) then
        -- level up | check if allowed.
        if( members >= core.Config.guild.settings.lvlreq[tostring(calcLvl)] ) then
            data.xp = data.xp + xp
            data.glvl = calcLvl
            self:sendGuildMsg( guild, 'LEVELUP!', ':::::::::::::::: Guild level ' .. tostring(calcLvl) .. ' reached! ::::::::::::::::' )
            self:GuildSave()
            self:CallUnlock(guild)
            return xp
        else
            data.xp = (((data.glvl*data.glvl)+data.glvl)/core.Config.guild.settings.glvlmodifier*100-(data.glvl*100))-1
            xp = 0
            return xp
        end
    end
    data.xp = data.xp + xp
    self:GuildSave()
    return xp
end

function PLUGIN:CallUnlock( guild )
    local data = self:getGuildData( guild )
    if not data then return end
    for k, v in pairs( core.Config.guild.calls) do
        if data.glvl == v.requirements.glvl then
            -- unlocked!
            table.insert( data.unlockedcalls, k )
            self:sendGuildMsg( guild, 'CALL UNLOCK!', v.name .. ' is now unlocked!' )
            self:GuildSave()
        end
    end
end

function PLUGIN:CallTimer()
    for k, v in pairs(self.Guild) do
        for y,z in pairs(self.Guild[k].activecalls) do
            z.time = z.time - 1
            if z.time <= 0 then
                self:sendGuildMsg(k, 'CALL ENDED', '::::::::::::' .. y .. ' has ended! ::::::::::::' )
                self.Guild[k].activecalls[y] = nil
                self:GuildSave()
            end
        end
        self:GuildSave()
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
    entry.ranks = { ['Leader']={'candelete','caninvite','cankick','canvault','canwar','canrank','cancall'},         -- Create default Ranks
        ['Co-Leader']={'caninvite','cankick','canvault','canwar','cancall'},
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
    entry.war = {}
    entry.vault = {}                                                                                                -- Vault
    entry.vault[ 'money' ] = {}
    entry.vault[ 'money' ][ 'g' ] = 0                                                                               -- Gold in vault
    entry.vault[ 'money' ][ 's' ] = 0                                                                               -- Silver in vault
    entry.vault[ 'money' ][ 'c' ] = 0                                                                               -- Copper in vault
    entry.vault[ 'items' ] = {}                                                                                     -- items in vault                                                                                               -- Guild is at war with:
    entry.vault[ 'lvl' ] = 1                                                                                        -- Current level of the vault                                                                                           -- Guild is at war with:
    entry.vault[ 'cap' ] = 0                                                                                        -- Current capacity of the vault
    entry.unlockedcalls = {}                                                                                        -- calls are unlocked at certain Guild lvls ( Max: 10 )
    entry.activecalls = {}                                                                                          -- Add complete table to Guilds file
    char.User[ netuserID ][ 'guild' ] = name                                                                        -- calls are activated by the perks command
    timer.Once( 1, function()
        rust.SendChatToUser( netuser, core.sysname, 'Creating Guild...' )
        timer.Once( 3, function()rust.SendChatToUser( netuser, core.sysname, 'Creating guild nameplates...' ) end )
        timer.Once( 6, function()rust.SendChatToUser( netuser, tostring( name ), 'Integrating tag...' ) end )
        timer.Once( 9, function()rust.SendChatToUser( netuser, tostring( '[' .. tag .. '] ' .. name ), 'Creating ' .. tostring( name ) .. ' user interface...' ) end )
        timer.Once( 16, function()rust.SendChatToUser( netuser, tostring( '[' .. tag .. '] ' .. name ), 'Feeding the chickens...' ) end )
        timer.Once( 18, function()rust.SendChatToUser( netuser, tostring( '[' .. tag .. '] ' .. name ), 'Your guild has been created!' ) end )
        timer.Once( 19, function()
            self.Guild[ name ] = entry                                                                                  -- Add guild to userdata.
            char:UserSave()
            self:GuildSave() end)
    end )
end

local unstackable = {"M4", "9mm Pistol", "Shotgun", "P250", "MP5A4", "Pipe Shotgun", "Bolt Action Rifle", "Revolver", "HandCannon", "Research Kit 1",
    "Cloth Helmet","Cloth Vest","Cloth Pants","Cloth Boots","Leather Helmet","Leather Vest","Leather Pants","Leather Boots","Rad Suit Helmet",
    "Rad Suit Vest","Rad Suit Pants","Rad Suit Boots","Kevlar Helmet","Kevlar Vest","Kevlar Pants","Kevlar Boots", "Holo sight","Silencer","Flashlight Mod",
    "Laser Sight","Flashlight Mod", "Hunting Bow", "Rock","Stone Hatchet","Hatchet","Pick Axe", "Torch", "Furnace", "Bed","Handmade Lockpick", "Workbench",
    "Camp Fire", "Wood Storage Box","Small Stash","Large Wood Storage", "Sleeping Bag" }

--PLUGIN:StoreItems
function PLUGIN:StoreItems( netuser, itemname, amount, guilddata )
    local datablock = rust.GetDatablockByName( itemname )
    if not datablock then rust.Notice( netuser, ' Item does not exist ') return end
    local inv = rust.GetInventory( netuser )
    if not inv then rust.Notice( netuser, 'Inventory not found, please report this to a GM.' ) return end
    local isUnstackable = func:containsval(unstackable,itemname)
    local i = 0
    local item = inv:FindItem(datablock)
    if (item) then
        if (not isUnstackable) then
            while (i < amount) do
                if (item.uses > 0) then
                    item:SetUses(item.uses - 1)
                    i = i + 1
                else
                    inv:RemoveItem(item)
                    item = inv:FindItem(datablock)
                    if (not item) then
                        break
                    end
                end
            end
        else
            while (i < amount) do
                inv:RemoveItem(item)
                i = i + 1
                item = inv:FindItem(datablock)
                if (not item) then
                    break
                end
            end
        end
    else rust.Notice(netuser, "Item not found in inventory!") return end
    if ((not isUnstackable) and (item) and (item.uses <= 0)) then inv:RemoveItem(item) end

    if guilddata.vault.items[ itemname ] then
        guilddata.vault.items[ itemname ] = guilddata.vault.items[ itemname ] + i
    else
        guilddata.vault.items[ itemname ] = i
    end
    guilddata.vault.cap = guilddata.vault.cap + i
    self:GuildSave()
    local guild = self:getGuild( netuser )
    if i > 0 then
        self:sendGuildMsg( guild, netuser.displayName, ':::::::::::::: has deposit: ' .. tostring( i ) .. 'x ' .. itemname .. ' ::::::::::::::' )
    end
end

--[[
    entry.vault = {}                                                                                                -- Vault
    entry.vault[ 'money' ][ 'gp' ] = 0                                                                              -- Gold in vault
    entry.vault[ 'money' ][ 'sp' ] = 0                                                                              -- Silver in vault
    entry.vault[ 'money' ][ 'cp' ] = 0                                                                              -- Copper in vault
    entry.vault[ 'items' ] = {}                                                                                     -- items in vault                                                                                               -- Guild is at war with:
    entry.vault[ 'lvl' ] = 1                                                                                        -- Current level of the vault                                                                                           -- Guild is at war with:
    entry.vault[ 'cap' ] = 0                                                                                        -- Current capacity of the vault
 ]]

function PLUGIN:GuildDeposit( name, guild, g, s, c )
    local guilddata = self:getGuildData( guild )
    while ( c >= 100 ) do
        c = c - 100
        s = s + 1
    end
    while ( s >= 100 ) do
        s = s - 100
        g = g + 1
    end
    if( g ) then guilddata.vault.money.g = guilddata.vault.money.g + g end
    if( s ) then guilddata.vault.money.s = guilddata.vault.money.s + s end
    if( c ) then guilddata.vault.money.c = guilddata.vault.money.c + c end
    while( guilddata.vault.money.c >= 100 ) do
        guilddata.vault.money.s = guilddata.vault.money.s + 1
        guilddata.vault.money.c = guilddata.vault.money.c - 100
    end
    while( guilddata.vault.money.s >= 100 ) do
        guilddata.vault.money.g = guilddata.vault.money.g + 1
        guilddata.vault.money.s = guilddata.vault.money.s - 100
    end
    local msg = ':::::::::::::: has donated [ Gold: ' .. g .. ' ] [ Silver: ' .. s .. ' ] [ Copper: ' .. c .. ' ] ::::::::::::::'
    self:sendGuildMsg( guild, name, msg )
    self:GuildSave()
end

function PLUGIN:GuildWithdraw( name, guild, g, s, c )
    local guilddata = self:getGuildData( guild )
    while ( c >= 100 ) do
        c = c - 100
        s = s + 1
    end
    while ( s >= 100 ) do
        s = s - 100
        g = g + 1
    end
    if( g ) then guilddata.vault.money.g = guilddata.vault.money.g - g end
    if( s ) then guilddata.vault.money.s = guilddata.vault.money.s - s end
    if( c ) then guilddata.vault.money.c = guilddata.vault.money.c - c end
    while( guilddata.vault.money.c < 0 ) do
        guilddata.vault.money.c = guilddata.vault.money.c + 100
        guilddata.vault.money.s =guilddata.vault.money.s - 1
    end
    while( guilddata.vault.money.s < 0 ) do
        guilddata.vault.money.s = guilddata.vault.money.s + 100
        guilddata.vault.money.g = guilddata.vault.money.g - 1
    end
    local msg = ':::::::::::::: has withdrawed [ Gold: ' .. g .. ' ] [ Silver: ' .. s .. ' ] [ Copper: ' .. c .. ' ] ::::::::::::::'
    self:sendGuildMsg( guild, name, msg )
    self:GuildSave()
end

function PLUGIN:canBuyGuild( guild, g, s, c )
    local data = self:getGuildData( guild )
    local cost = (( g * 10000 ) + ( s * 100 ) + ( c * 1 ))
    local bal = (( data.vault.money.g * 10000 ) + ( data.vault.money.s * 100 ) + ( data.vault.money.c * 1 ))
    if( bal >= cost ) then return true else return false end
end

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

function PLUGIN:cmdGuildChat( netuser, cmd, args )
    rust.BroadcastChat( tostring(netuser))
    local guild = self:getGuild( netuser )
    if not guild then rust.Notice( netuser, 'You\'re not in a guild!' ) return end
    local i = 1
    local msg = ''
    while ( i <= #args ) do
        msg = msg .. ' ' .. args[i]
        i = i + 1
    end
    local tempstring = string.lower( msg )
    for k, v in ipairs( core.Config.settings.censor.chat ) do
        local found = string.find( tempstring, v )
        if ( found ) then
            rust.Notice( netuser, 'Dont swear!' )
            return
        end
    end
    self:sendGuildMsg(guild, netuser.displayName, msg )
end

--PLUGIN:sendGuildMsg
function PLUGIN:sendGuildMsg( guild, name, msg )
    local guilddata = self:getGuildData( guild )
    for k,v in pairs( self.Guild[ guild ].members ) do
        local b, targuser = rust.FindNetUsersByName( v.name )
        if( b ) then rust.SendChatToUser( targuser, name .. '  [G]' , msg ) end
    end
end

--PLUGIN:delGuild
function PLUGIN:delGuild( guild )
    -- Delete guild from userdata.
    for k, v in pairs( self.Guild[ guild ].members ) do
        char.User[ k ].guild = nil
    end
    char:UserSave()
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

--[[
--      local ab = core.Config.settings.maxplayerlvl
        local b = core.Config.settings.lvlmodifier
        local f = ((ab*ab)+ab)/b*100-(ab*100)]
 ]]