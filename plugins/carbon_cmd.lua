PLUGIN.Title = 'carbon_call'
PLUGIN.Description = 'guild call module'
PLUGIN.Version = '0.0.3'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end
function PLUGIN:PostInit()
    self:AddChatCommand( 'language', self.lang )

    -- Character
    self:AddChatCommand( 'c', self.cmdCharacter ) -- will show level, xp to go (w/bar), dp, available commands >
    self:AddChatCommand( 'skills', self.cmdSkills ) --only lists your skills and levels w/ bar also inspect by name individually will show bonus damage.
    self:AddChatCommand( 'attr', self.cmdAttributes ) --lists your attributes and point availability.
    self:AddChatCommand( 'perks', self.cmdPerks ) --shows current perks and levels w/ bar also inspect by name individually will show perk description.
    self:AddChatCommand( 'add', self.cmdAdd ) --used to add points to perks or attributes i.e. /add 1 str or /add 1 parry
    self:AddChatCommand( 'reset', self.cmdReset ) --used to reset perks, attr, class or prestige profession


    -- Guild
    self:AddChatCommand( 'guild', self.cmdGuild )       -- TESTED
    self:AddChatCommand( 'vault', self.cmdVault )       -- TESTED
    self:AddChatCommand( 'gl', self.cmdChat )
    self:AddChatCommand( 'members', self.cmdMembers )   -- TESTED
    self:AddChatCommand( 'ginvite', self.cmdInvite )    -- TESTED
    self:AddChatCommand( 'gkick', self.cmdKick )        -- TESTED
    self:AddChatCommand( 'rank', self.cmdRank )         -- TESTED
    self:AddChatCommand( 'war', self.cmdWar )
    self:AddChatCommand( 'call', self.cmdCall )         -- TESTED

    -- Prof
    self:AddChatCommand( 'prof', self.cmdProf )

    -- Statistics (stats)

end
function PLUGIN:GetCmdData(netuser, cmd ,args)
	local cmdData = {}
	cmdData = setmetatable({}, {__newindex = function(t, k, v) rawset(t, k, v) end })
	cmdData['netuserData'] = char[rust.GetUserID(netuser)]
	cmdData['netuser'] = netuser
	cmdData['cmd'] = cmd
	if #args then cmdData['args'] = args end
	if lang.Text[cmd][cmdData.netuserData.lang] then cmdData['txt'] = lang.Text[cmd][cmdData.netuserData.lang] end
	return cmdData
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
		if #args == 4 and args[2] == 'train' then
			char:CharacterPerksTrain( cmdData )
		elseif #args == 1 then
			char:CharacterPerks( cmdData )
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
function PLUGIN:cmdReset(netuser, cmd ,args)
    if not args[1] then
        local netuserData = char[netuserID]
        char:InfoSkills( netuserData )
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
