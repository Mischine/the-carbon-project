PLUGIN.Title = "carbon_debug"
PLUGIN.Description = "debug module"
PLUGIN.Version = "0.0.1 alpha"
PLUGIN.Author = "Mischa & CareX"


function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
    self.debug = {}

    self:AddChatCommand( 'debug', self.cmdDebug )
end

function PLUGIN:cmdDebug( netuser, cmd , args )
    if( not netuser:CanAdmin()) then rust.Notice( netuser, 'You cannot debug!' ) return end
    if( args[1] == 'termall' ) then self.debug = {} rust.Notice( netuser, 'All debugs have been terminated!') return end
    if not args[1] then rust.Notice( netuser, '/debug "name" ' ) return end
    if self.debug[ targname ] then rust.Notice( netuser, util.QuoteSafe(targname) '\'s debug is terminated') self.debug[ targname ] = nil return end
    local targname = util.QuoteSafe(args[1])
    local validate, netuser = rust.FindNetUsersByName( targname )
    if (not validate) then
        if (netuser == 0) then
            rust.Notice( netuser, 'No players found with name: ' .. util.QuoteSafe( targname ))
        else
            rust.Notice( netuser,'Multiple players found with name: ' .. util.QuoteSafe( targname ))
        end
        return end

    local data = {}
    data.targnetuser = netuser
    self.debug[ targname ] = data
    rust.Notice( netuser, util.QuoteSafe(targname) '\'s debug is activated')
end

-- if self.debug[ netuser.displayName ] then rust.SendChatToUser(, self.debug[ netuser.displayName ].targnetuser, 'actual debug.' ) end