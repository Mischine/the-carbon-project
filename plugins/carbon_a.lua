PLUGIN.Title = 'carbon_sandbox_a'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
    self:AddChatCommand( 'a', self.a )
end


function PLUGIN:a(netuser,cmd, args)
    local controllable = netuser.playerClient.controllable
    --local CLT = controllable:GetComponent( "CharacterLoadoutTrait" )
    local character = controllable:GetComponent( "Character" )
    local inv = controllable:GetComponent( "Inventory" )
    local pinv = controllable:GetComponent( "PlayerInventory" )
    local nu = controllable:GetComponent( "NetUser" )
    local bp = controllable:GetComponent( "Blueprint" )
    local avatar = netuser:LoadAvatar()

    rust.SendChatToUser(netuser, GetBlueprints)



--[[
--    rust.SendChatToUser(netuser, tostring(inv))
    builder = avatar:ToBuilder()
    rust.BroadcastChat('before: ')
    local count = builder.BlueprintsCount
    rust.BroadcastChat( tostring( count ))
    builder:ClearBlueprints()
    rust.BroadcastChat('after: ')
    local count = builder.BlueprintsCount
    rust.BroadcastChat(tostring( count ))
    avatar.Build()
--]]
    -- recycler = avi.avatar.Recycler()
    --avatar:ClearBlueprints()
end