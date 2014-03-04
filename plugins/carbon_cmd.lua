PLUGIN.Title = 'carbon_call'
PLUGIN.Description = 'guild call module'
PLUGIN.Version = '0.0.2'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end


function PLUGIN:PostInit()
    self:AddChatCommand( 'language', self.lang )
    self:AddChatCommand( 'xp', self.xp )
    self:AddChatCommand( 'avatar', self.avatar )
    self:AddChatCommand( 'testme', self.test )
end
function foo(...)
    rust.SendChatToUser( netuser, ' ', tostring(arg))
end
function PLUGIN:lang(netuser, cmd, args)
    local netuserID = rust.GetUserID( netuser )
    local netuserData = char.User[netuserID]
    if args[1] == 'english' or args[1] == 'russian' then
        netuserData.lang = tostring(args[1])
        rust.SendChatToUser(netuser, 'Language set to ' .. tostring(args[1]) .. '.')
    else
    end
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
