PLUGIN.Title = 'carbon_call'
PLUGIN.Description = 'guild call module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end

--PLUGIN:addcotw
function PLUGIN:addcotw( netuser, cmd , args )
    local guild = self:getGuild( netuser )
    table.insert( self.Guild[ guild ].activeperks, 'cotw')
    rust.SendChatToUser( netuser, 'cotw added' )
end

--PLUGIN:hasRallyCall
function PLUGIN:hasRallyCall( guild )
    local Rally = table.containsval( self.Guild[ guild ].activecalls, 'rally' )
    if ( Rally ) then Rally = ( self.Config.guild.calls.rally.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.rally.requirements.glvl )) return ( Rally + 1 ) else return false end
end

--PLUGIN:hasSYGCall
function PLUGIN:hasSYGCall( guild )
    local syg = table.containsval( self.Guild[ guild ].activecalls, 'syg' )
    if ( syg ) then syg = ( self.Config.guild.calls.rally.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.syg.requirements.glvl )) return ( 1 - syg ) else return false end
end

--PLUGIN:hasCOTWCall
function PLUGIN:hasCOTWCall ( guild )
    local cotw = table.containsval( self.Guild[ guild ].activecalls, 'cotw' )
    if ( cotw ) then cotw = ( self.Config.guild.calls.cotw.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.cotw.requirements.glvl + 1 )) return ( cotw + 1 ) else return false end
end

--PLUGIN:hasForGloryCall
function PLUGIN:hasForGloryCall ( guild )
    local forglory = table.containsval( self.Guild[ guild ].activecalls, 'forglory' )
    if ( forglory ) then forglory = ( self.Config.guild.calls.forglory.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.forglory.requirements.glvl + 1 )) return ( forglory + 1 ) else return false end
end