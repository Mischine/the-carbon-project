PLUGIN.Title = 'carbon_call'
PLUGIN.Description = 'guild call module'
PLUGIN.Version = '0.0.2'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end


function PLUGIN:PostInit()
    self:AddChatCommand( 'language', self.lang )

    -- Character
    self:AddChatCommand( 'xp', self.xp )

    -- Guild
    self:AddChatCommand( 'ghelp', self.cmdGuildHelp )
    self:AddChatCommand( 'guild', self.cmdGuild )
    self:AddChatCommand( 'vault', self.cmdVault )
    self:AddChatCommand( 'g', self.cmdGuildChat )
    self:AddChatCommand( 'members', self.cmdMembers )
    self:AddChatCommand( 'ginvite', self.cmdInvite )
    self:AddChatCommand( 'gkick', self.cmdKick )
    self:AddChatCommand( 'rank', self.cmdRank )
    self:AddChatCommand( 'war', self.cmdWar )
    self:AddChatCommand( 'call', self.cmdCall )

    -- Prof

    -- Statistics (stats)

    -- Random Mischa Crap.
    self:AddChatCommand( 'avatar', self.avatar )
    self:AddChatCommand( 'testme', self.test )
end

function PLUGIN:cmdGuild(netuser, cmd ,args)
    -- Get Language & Data
    local netuserData = char.User[rust.GetUserID( netuser )]
    local lang = netuserData.lang                               -- Will implement later. This is gonna fuck up the outlining tho
    if not args[1] then
        guild:GuildIntro( netuser )
    elseif args[1]:lower() == 'create' then
        guild:GuildCreate( netuser, args )
    elseif args[1]:lower() == 'delete' then
        guild:GuildDelete( netuser, args )
    elseif args[1]:lower() == 'info' then
        guild:GuildInfo( netuser )
    elseif args[1]:lower() == 'accept' then
        guild:GuildAccept( netuser )
    elseif args[1]:lower() == 'help' then
        guild:GuildHelp( netuser, args )
    elseif args[1]:lower() == 'leave' then
        guild:GuildLeave( netuser,args )
    elseif args[1]:lower() == 'stats' then
        guild:GuildStats( netuser )
    else
        guild:GuildCommands( netuser, cmd ,args )               -- TODO
    end
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
    guild:GuildCall( netuser, args )
end
function PLUGIN:cmdWar( netuser, cmd, args )
    if not args[1] then rust.Notice( netuser, '/war "GuildTag" ' ) return end
    guild:GuildWar( netuser )
end
function PLUGIN:cmdRank( netuser, cmd ,args )
    guild:GuildRank( netuser, cmd, args )
end
function PLUGIN:cmdVault( netuser, cmd, args ) 
    guild:GuildVault( netuser, cmd, args )
end

function foo(...)
    rust.SendChatToUser( netuser, ' ', tostring(arg))
end

function PLUGIN:lang(netuser, cmd, args)
    local netuserID = rust.GetUserID( netuser )
    local netuserData = char.User[netuserID]
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

function PLUGIN:xp(netuser, cmd, args)
    local netuserID = rust.GetUserID( netuser )
    local netuserData = char.User[netuserID]
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
            lang.Text.xp[netuserData.lang].level .. ':                          ' .. tostring(a-1),
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
