PLUGIN.Title="Title"
PLUGIN.Version="1.0"
PLUGIN.Description="Description."
PLUGIN.Author="Author"
function PLUGIN:Init()
    self:AddChatCommand("pvp",self.pvp)
end
function PLUGIN:pvp(a,b)
    if b[1]=="on"then
    rust.RunServerCommand("server.pvp true")
    rust.BroadcastChat(NetUser,"PvP ON!")
    end
    if b[1]=="off"then
        rust.RunServerCommand("server.pvp false")
        rust.BroadcastChat(a,"PvP OFF!")
    end
end