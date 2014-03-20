PLUGIN.Title = 'carbon_call'
PLUGIN.Description = 'guild call module'
PLUGIN.Version = '0.0.4'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end
function PLUGIN:PostInit()
	-- Language
    self:AddChatCommand( 'language', self.lang )

    -- Character
    self:AddChatCommand( 'c', self.cmdCharacter ) -- will show level, xp to go (w/bar), dp, available commands >
    self:AddChatCommand( 'class', self.cmdClass )
    -- Perks
    self:AddChatCommand( 'perks', self.cmdPerks )

    -- Guild
    self:AddChatCommand( 'guild', self.cmdGuild )       -- TESTED
    self:AddChatCommand( 'vault', self.cmdVault )       -- TESTED
    self:AddChatCommand( 'members', self.cmdMembers )   -- TESTED
    self:AddChatCommand( 'ginvite', self.cmdInvite )    -- TESTED
    self:AddChatCommand( 'gkick', self.cmdKick )        -- TESTED
    self:AddChatCommand( 'rank', self.cmdRank )         -- TESTED
    self:AddChatCommand( 'war', self.cmdWar )           -- TESTED
    self:AddChatCommand( 'call', self.cmdCall )         -- TESTED

    -- Prof
    self:AddChatCommand( 'prof', self.cmdProf )

	-- Party
    self:AddChatCommand( 'party', self.Party )

    -- Chat channels
    self:AddChatCommand( 'p', self.ChannelParty )
    self:AddChatCommand( 'g', self.ChannelGuild )
    self:AddChatCommand( 'l', self.ChannelLocal )
    -- self:AddChatCommand( 't', self.ChannelTrade )
    -- self:AddChatCommand( 'r', self.ChannelRecruit )
    -- self:AddChatCommand( 'z', self.ChannelZone )
    self:AddChatCommand( 'ch', self.Channel )

    -- Statistics (stats)

  -- Classes
    -- thief
    self:AddChatCommand( 'stealth', thief.cmdStealth )
    self:AddChatCommand( 'steal', thief.Steal )

    -- Mail
    self:AddChatCommand( 'mail', self.cmdMail )

	-- Other
    self:AddChatCommand( 'register', self.Register )
    self:AddChatCommand( 'w', self.Whisper )
end

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 MAIL COMMANDS
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function PLUGIN:cmdMail( netuser, cmd ,args )
	local cmdData = self:GetCmdData( netuser, cmd, args )
	if not args[1] then
		mail.MailInfo( cmdData )
	end
	local option = args[1]:lower()

	if option == 'new' then             -- /mail new [Optional subject]         To create a new mail, subject is optional
	elseif option == 'item' then        -- /mail item #amount "ItemName"        To add items
	elseif option == 'subject' then     -- /mail subject txt                    To add a subject
	elseif option == 'txt' then         -- /mail txt txt                        To add new text
	elseif option == 'money' then       -- /mail money g s c                    To add money to the mail
	elseif option == 'read' then        -- /mail read #ID                       To read an mail
	elseif option == 'pv' then          -- /mail pv                             To preview your mail that you\'re about to send
	elseif option == 'cancel' then      -- /mail cancel                         To cancel the concept. return items/money in concept
	elseif option == 'del' then         -- /mail del #ID                        To delete a mail
	elseif option == 'clear' then       -- /mail clear                          To clear your whole inbox. Even the one with items in it
	elseif option == 'fw' then          -- /mail fw                             To forward a mail
	elseif option == 'collect' then     -- /mail collect                        To collect the items/money/donation
	elseif option == 'send' then        -- /mail send "Name"                    To send mail to a player
	else
		mail.MailInfo( cmdData )
	end
end

function PLUGIN:GetCmdData(netuser, cmd ,args)
	local cmdData = {}
	cmdData['netuserData'] = char[rust.GetUserID(netuser)]
	cmdData['netuser'] = netuser
	cmdData['cmd'] = cmd
	if #args then cmdData['args'] = args end
	if lang.Text[cmd][cmdData.netuserData.lang] then cmdData['txt'] = lang.Text[cmd][cmdData.netuserData.lang] end
	return cmdData
end

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 CHANNEL COMMANDS
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:Channel( netuser, cmd ,args )
	local data = char:GetUserDataFromTable( netuser )
	if not data then rust.Notice( netuser, 'Userdata not found, try relogging.' ) return end
	rust.SendChatToUser( netuser, 'Your current channel is ' .. data.channel )
end

function PLUGIN:ChannelParty( netuser, _, _ )
	local data = char:GetUserDataFromTable( netuser )
	if not data then rust.Notice( netuser, 'Userdata not found, try relogging.' ) return end
	local pdata = party:getParty( netuser )
	if not pdata then rust.Notice( netuser, 'You\'re not in a party!' ) return end
	data.channel = 'party'
	rust.SendChatToUser( netuser, core.sysname ,':::::::::: Now talking in party chat. ::::::::::' )
	char:Save( netuser )
end

function PLUGIN:ChannelGuild( netuser, _, _ )
	local data = char:GetUserDataFromTable( netuser )
	if not data then rust.Notice( netuser, 'Userdata not found, try relogging.' ) return end
	local guild = guild:getGuild( netuser )
	if not guild then rust.Notice( netuser, 'You\'re not in a guild!' ) return end
	data.channel = 'guild'
	rust.SendChatToUser( netuser, core.sysname ,':::::::::: Now talking in guild chat. ::::::::::' )
	char:Save( netuser )
end

function PLUGIN:ChannelLocal( netuser, _, _ )
	local data = char:GetUserDataFromTable( netuser )
	if not data then rust.Notice( netuser, 'Userdata not found, try relogging.' ) return end
	data.channel = 'local'
	rust.SendChatToUser( netuser, core.sysname ,':::::::::: Now talking in local chat. ::::::::::' )
	char:Save( netuser )
end

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 WHISPER COMMANDS
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:Whisper( netuser, cmd, args)
	chat:cmdWhisper( netuser, cmd, args )
end
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 REGISTER COMMANDS
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:Register( netuser, cmd, args )
	core:cmdRegister( netuser, cmd ,args )
end
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 PARTY COMMANDS
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:Party( netuser, cmd, args )
	if not args[1] then
		local pdata = party:getParty( netuser )
		if pdata then
			party:PartyOverView( netuser, cmd, args )   -- TESTED
		else
			party:PartyInfo(netuser, cmd, args )        -- TESTED
		end
		return
	end
	local cmd = args[1]:lower()
	if cmd == 'create' then                             -- TESTED
		party:PartyCreate( netuser, cmd, args )
	elseif cmd == 'list' then                           -- TESTED
		party:PartyList(netuser, cmd, args )
	elseif cmd == 'invite' then
		party:PartyInvite(netuser, cmd, args )
	elseif cmd == 'accept' then
		party:PartyAccept( netuser, cmd ,args )
	elseif cmd == 'kick' then
		party:PartyKick(netuser, cmd, args )
	elseif cmd == 'leave' then                          -- TESTED
		party:PartyLeave( netuser, cmd, args )
	elseif cmd == 'members' then                        -- TESTED
		party:PartyMembers(netuser, cmd, args )
	elseif cmd == 'join' then
		party:PartyJoin( netuser, cmd, args )
	elseif cmd == 'set' then                            -- TESTED
		party:PartySet(netuser, cmd, args )
	else                                                -- TESTED
		party:PartyInfo(netuser, cmd, args )
	end
end

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 PROFFESIONS COMMANDS
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:cmdProf( netuser, cmd, args )
    if not args [1] then
        prof:InfoProf( netuser, cmd, args )
    return end
end

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 CHARACTER COMMANDS
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function PLUGIN:cmdCharacter(netuser, cmd ,args)

	--for _,v in pairs(args) do args[v] = args[v]:lower() end
	local cmdData = self:GetCmdData(netuser, cmd ,args)

	if not args[1] then
		char:Character( cmdData )
	elseif args[1] == 'skills' then
		char:CharacterSkills( cmdData )
	elseif args[1] == 'attr' then
		if #args == 4 and args[2] == 'train' then
			char:CharacterAttributesTrain( cmdData )
		elseif #args == 1 then
			char:CharacterAttributes( cmdData )
		end
	elseif args[1] == 'perks' then
		if #args == 2 and args[2] == 'list' then
			char:CharacterPerksList(cmdData)
		elseif #args == 4 and args[2] == 'train' then
			char:CharacterPerksTrain(cmdData)
		elseif #args == 1 then
			char:CharacterPerks(cmdData)
		end
	elseif args[1] == 'class' then
		if #args == 3 and args[2] == 'select' then
			char:CharacterClassSelect( cmdData )
		elseif #args == 1 then
			char:CharacterClass( cmdData )
		end
	elseif args[1] == 'reset' then
		if #args == 1 then
			char:CharacterReset( cmdData )
		elseif #args == 2 and args[2] == 'perks' then
			char:CharacterResetPerks( cmdData )
		elseif #args == 2 and args[2] == 'attr' then
			char:CharacterResetAttributes( cmdData )
		elseif #args == 2 and args[2] == 'class' then
			char:CharacterResetClass( cmdData )
		end
	else
		--TODO: ADD ERROR
	end
end
function PLUGIN:cmdSkills(netuser, cmd ,args)
    if not args[1] then
        local netuserData = char[netuserID]

    end
end
function PLUGIN:cmdAttributes(netuser, cmd ,args)
    if not args[1] then
        local netuserData = char[netuserID]
        char:InfoSkills( netuserData )
    end
end
function PLUGIN:cmdPerks(netuser, cmd ,args)
    if not args[1] then
        local netuserData = char[netuserID]
        char:InfoSkills( netuserData )
    end
end
function PLUGIN:cmdAdd(netuser, cmd ,args)
    if not args[1] then
        local netuserData = char[netuserID]
        char:InfoSkills( netuserData )
    end
end
function PLUGIN:cmdReset(netuser, _ ,args)
	local netuserID = rust.GetUserID( netuser )
    if not args[1] then
        local netuserData = char[netuserID]
        char:InfoSkills( netuserData )
    end
end

function PLUGIN:cmdClass( netuser, cmd, args )
	local cmdData = self:GetCmdData(netuser, cmd ,args)
	if cmdData.netuserData.lvl < 25 then
		char:ClassReject( cmdData )
		return
	end
	if not args[1] then
		if cmdData.netuserData.class then
			if cmdData.netuserData.class == 'thief' then
				char:ThiefCmds( cmdData )
				return
			end
		end
	char:ClassInfo( cmdData )
	return end
	if args[1]:lower() == 'thief' then
		char:SpecThief( cmdData )
	else
		char:ClassInfo( cmdData )
	end
end
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                    GUILD COMMANDS
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:cmdGuild(netuser, cmd ,args)
    -- Get Language & Data
    local netuserData = char[rust.GetUserID( netuser )]
    local lang = netuserData.lang   --the language is included in the netuserData B)~   -- Will implement later. This is gonna fuck up the outlining tho
    if not args[1] then
        guild:GuildIntro( netuser )
    elseif args[1]:lower() == 'create' then     -- TESTED
        guild:GuildCreate( netuser, args )
    elseif args[1]:lower() == 'delete' then     -- TESTED
        guild:GuildDelete( netuser, args )
    elseif args[1]:lower() == 'info' then       -- TESTED
        guild:GuildInfo( netuser )
    elseif args[1]:lower() == 'accept' then     -- TESTED
        guild:GuildAccept( netuser )
    elseif args[1]:lower() == 'help' then       -- TESTED
        guild:GuildHelp( netuser, cmd, args )
    elseif args[1]:lower() == 'leave' then      -- TESTED
        guild:GuildLeave( netuser,args )
    elseif args[1]:lower() == 'stats' then      -- TESTED
        guild:GuildStats( netuser )
    else
	    guild:GuildHelp( netuser, cmd, args )   -- TESTED
    end
end

function PLUGIN:cmdChat( netuser, cmd, args )
    guild:gChat( netuser, cmd, args )
end
function PLUGIN:cmdInvite( netuser, cmd ,args )
    if not args[1] then
        local content = {['msg'] = 'To invite players to the guild type: /ginvite "Name" '}
        func:TextBoxError(netuser, content, cmd, args) return
    elseif args[1] then
        guild:GuildInvite( netuser, args )
    end
end
function PLUGIN:cmdMembers( netuser, cmd, args )
    guild:GuildMembers( netuser, args )
end
function PLUGIN:cmdKick( netuser, cmd, args )
    guild:GuildKick( netuser, args )
end
function PLUGIN:cmdCall( netuser, cmd, args )
    guild:GuildCall( netuser, cmd, args )
end
function PLUGIN:cmdWar( netuser, cmd, args )
    if not args[1] then rust.Notice( netuser, '/war "GuildTag" ' ) return end
    guild:GuildWar( netuser, args )
end
function PLUGIN:cmdRank( netuser, cmd ,args )
    guild:GuildRank( netuser, cmd, args )
end
function PLUGIN:cmdVault( netuser, cmd, args )
    guild:GuildVault( netuser, cmd, args )
end
function PLUGIN:lang(netuser, cmd, args)
    local netuserID = rust.GetUserID( netuser )
    local netuserData = char[netuserID]
    if args[1] then
        if args[1] == 'english' or args[1] == 'russian' then
            netuserData.lang = tostring(args[1])
            rust.SendChatToUser(netuser, 'Language set to ' .. tostring(args[1]) .. '.')
        return end
    end
    local content = {
        ['msg'] = 'Available languages:',
        ['list'] = {}
    }
    for _, v in pairs( lang.Text.available ) do
        table.insert( content.list, ' - ' .. v )
    end
    func:TextBox(netuser, content, cmd, args) return
end

--[[
function PLUGIN:xp(netuser, cmd, args)
    local netuserID = rust.GetUserID( netuser )
    local netuserData = char[netuserID]
    local a = netuserData.lvl+1 --level +1
    local ab = netuserData.lvl --level
    local b = core.Config.settings.lvlmodifier
    local c = ((a*a)+a)/b*100-(a*100) --xp required for next level
    local d = math.floor(((netuserData.xp/c)*100)+0.5) -- percent currently to next level.
    local e = c-netuserData.xp -- left to go until level
    local f = ((ab*ab)+ab)/b*100-(ab*100) -- amount needed for current level
    local g = math.floor(((netuserData.dp/(f*.5))*100)+0.5) -- percentage of dp
    local h = (f*.5) -- total possible dp
    if (a == 2) and (core.Config.settings.lvlmodifier >= 2) then f = 0 end
    local content = {
        ['list']={
            lang.Text.xp[netuserData.lang].level .. ':                          ' .. tostring(ab),
            ' ',
            lang.Text.xp[netuserData.lang].experience .. ':              (' .. tostring(netuserData.xp) .. '/' .. tostring(c) .. ')   [' .. tostring(d) .. '%]   ' .. '(' .. tostring(e) .. ')',
            tostring(func:xpbar( d, 32 )),
            ' ',
            lang.Text.xp[netuserData.lang].deathpenalty .. ':         (' .. tostring(netuserData.dp) .. '/' .. tostring(h) .. ')   [' .. tostring(g) .. '%]',
            tostring(func:xpbar( g, 32 )),
        }
    }
    func:TextBox(netuser, content, cmd, args) return
end
--]]
