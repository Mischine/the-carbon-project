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
function PLUGIN:test(netuser,cmd, args)

    local controllable = netuser.playerClient.controllable
    local char = controllable:GetComponent( "Character" )

    local inv = controllable:GetComponent( "Inventory" )
    local pinv = controllable:GetComponent( "PlayerInventory" )
    local nu = controllable:GetComponent( "NetUser" )
    local bp = controllable:GetComponent( "Blueprint" )
    local asr = controllable:GetComponent("AvatarSaveRestore")
    local avatar = netuser:LoadAvatar()

    --[[
    local count = avatar.BlueprintsCount
    rust.SendChatToUser( netuser, ' ', tostring(count))
    local num = 0
    while num < avatar.BlueprintsCount do
        local blueprint = avatar:GetBlueprints(num)
        rust.BroadcastChat( tostring(blueprint))
        num = num + 1
    end
    local count = avatar.BlueprintsCount
    rust.SendChatToUser( netuser, ' ', tostring(count))
--]]
    --rust.BroadcastChat('Crouched : ' .. tostring(char.crouchable.crouched)) -- Shows 0

    --local avatar = netuser:LoadAvatar()
    --local builder = avatar:ToBuilder()
    --[[
    local idMain = char.idMain
    --
    local avatar = netuser:LoadAvatar()
    local count = avatar.BlueprintsCount rust.BroadcastChat('local avatar = netuser:LoadAvatar(): ' .. tostring(count)) --shows 45


    local builder = avatar:ToBuilder()
    local count = builder.BlueprintsCount rust.BroadcastChat('local builder = avatar:ToBuilder(): ' .. tostring(count)) --shows 45

    builder:ClearBlueprints()
    builder:ClearInventory()
    local count = builder.BlueprintsCount rust.BroadcastChat('builder:ClearBlueprints(): ' .. tostring(count)) -- shows 0

    avatar = builder:Build()
    local count = avatar.BlueprintsCount rust.BroadcastChat('avatar = builder:Build(): ' .. tostring(count)) -- Shows 0

    netuser:SaveAvatar(avatar)
   local count = avatar.BlueprintsCount rust.BroadcastChat('netuser:SaveAvatar(avatar): ' .. tostring(count)) -- Shows 0

    local newavatar = netuser:LoadAvatar()
    local count = newavatar.BlueprintsCount rust.BroadcastChat('newavatar:ParseFrom(avatar): ' .. tostring(count)) -- Shows 0

    netuser:SaveAvatar(newavatar)
    avatar = netuser:LoadAvatar()

    local count = avatar.BlueprintsCount rust.BroadcastChat('avatar = netuser:LoadAvatar(): ' .. tostring(count)) -- Shows 0


    rust.SendChatToUser( netuser, ' ', tostring(char.blueprints_))

--]]
    --[[
        --local DamageTypeList={10, 0, 0, 0, 0, 0}
        --Rust.TakeDamage.Hurt(bulletWeaponItem.inventory, char.idMain, DamageTypeList)
        rust.SendChatToUser( netuser, ' ', tostring(char.idMain))
        --
        rust.SendChatToUser( netuser, ' ', tostring(netuser:SecondsConnected()))
        rust.SendChatToUser( netuser, ' ', tostring(netuser.user))
        rust.SendChatToUser( netuser, ' ', tostring(netuser.user.usergroup))
        rust.SendChatToUser( netuser, ' ', tostring(netuser.admin))
        netuser.admin = false
        rust.SendChatToUser( netuser, ' ', tostring(netuser.admin))

        print(tostring(netuser.user.usergroup))    --netuser.user.usergroup = 1 ; this kicks you
        local DefaultInstance = avatar.DefaultInstance
        local BeltCount = avatar.BeltCount -- how many items avatar has in belt.
        local Vitals = avatar.Vitals

    --]]
    --rust.SendChatToUser( netuser, ' ', tostring(builder))
    --rust.SendChatToUser( netuser, ' ', tostring(blueprint))
    --rust.SendChatToUser( netuser, ' ', tostring(DefaultInstance))
    --rust.SendChatToUser( netuser, ' ', tostring(BeltCount))
    -- inv.activeItem:Clear()

--[[
    local count = avatar.BlueprintsCount
    rust.SendChatToUser( netuser, ' ', tostring(count))
    local num = 0
    while num < avatar.BlueprintsCount do
        local blueprint = avatar:GetBlueprints(num)
        print(blueprint)
        local bpbuilder = blueprint:ToBuilder()
        bpbuilder:ClearId()
        rust.SendChatToUser( netuser, ' ', 'bpbuilder:       ' .. tostring(bpbuilder))
        rust.SendChatToUser( netuser, ' ', tostring(blueprint))
        num = num + 1
    end
    local count = avatar.BlueprintsCount
    rust.SendChatToUser( netuser, ' ', tostring(count))

    local count = avatar.BlueprintsCount
    rust.SendChatToUser( netuser, ' ', tostring(count))
    local num = 0
    while num < avatar.BlueprintsCount do
        local blueprint = avatar:GetBlueprints(num)
        print(blueprint)
        rust.SendChatToUser( netuser, ' ', tostring(blueprint))
        num = num + 1
    end
    local count = avatar.BlueprintsCount
    rust.SendChatToUser( netuser, ' ', tostring(count))
--]]






    --[[
    builder:ClearBlueprints()
    rust.BroadcastChat('after: ')
    local count = builder.BlueprintsCount
    rust.BroadcastChat('Pre-Builder: ' .. tostring(count))
    local result = builder:PrepareBuilder()
    print( result )
    --rust.SendChatToUser( netuser, ' ', tostring(inv.activeItem.datablock.name) ) -- gets and sets name
    --inv:Clear()
    rust.SendChatToUser( netuser, ' ', tostring(pinv) )
    pinv:SaveToAvatar()
    rust.SendChatToUser( netuser, ' ', tostring(pinv) )
    --Rust.EnvironmentControlCenter.Singleton:GetTime()
    --]]

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
