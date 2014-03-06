PLUGIN.Title = 'carbon_sandbox_b'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    self:AddChatCommand( 'b', self.b )
end
function PLUGIN:b(netuser, cmd, args )
    rust.BroadcastChat(string.format("%-\ts   hai", '1231123231'))
    rust.BroadcastChat(string.format("%-\ts   hai", '1231'))
    rust.BroadcastChat(string.format("%-\ts   hai", '12311sdf23231'))
    --rust.BroadcastChat(b:gsub("%s+", "   "))
    --rust.BroadcastChat(c:gsub("%s+", "   "))
    --rust.BroadcastChat(d:gsub("%s+", "   "))
end