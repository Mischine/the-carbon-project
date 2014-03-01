PLUGIN.Title = 'carbon_call'
PLUGIN.Description = 'guild call module'
PLUGIN.Version = '0.0.2'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end

--PLUGIN:addcotw
function PLUGIN:addcotw( netuser, cmd , args )
    local guild = guild:getGuild( netuser )
    table.insert( guild.Guild[ guild ].activeperks, 'cotw')
    rust.SendChatToUser( netuser, 'cotw added' )
end

--PLUGIN:hasRallyCall
function PLUGIN:hasRallyCall( guild )
    local Rally = func:containsval( guild.Guild[ guild ].activecalls, 'rally' )
    if ( Rally ) then Rally = ( core.Config.guild.calls.rally.mod * ( guild.Guild[ guild ].glvl - core.Config.guild.calls.rally.requirements.glvl )) return ( Rally + 1 ) else return false end
end

--PLUGIN:hasSYGCall
function PLUGIN:hasSYGCall( guild )
    local syg = func:containsval( guild.Guild[ guild ].activecalls, 'syg' )
    if ( syg ) then syg = ( core.Config.guild.calls.rally.mod * ( guild.Guild[ guild ].glvl - core.Config.guild.calls.syg.requirements.glvl )) return ( 1 - syg ) else return false end
end

--PLUGIN:hasCOTWCall
function PLUGIN:hasCOTWCall ( guild )
    local cotw = func:containsval( guild.Guild[ guild ].activecalls, 'cotw' )
    if ( cotw ) then cotw = ( core.Config.guild.calls.cotw.mod * ( guild.Guild[ guild ].glvl - core.Config.guild.calls.cotw.requirements.glvl + 1 )) return ( cotw + 1 ) else return false end
end

--PLUGIN:hasForGloryCall
function PLUGIN:hasForGloryCall ( guild )
    local forglory = func:containsval( guild.Guild[ guild ].activecalls, 'forglory' )
    if ( forglory ) then forglory = ( core.Config.guild.calls.forglory.mod * ( guild.Guild[ guild ].glvl - core.Config.guild.calls.forglory.requirements.glvl + 1 )) return ( forglory + 1 ) else return false end
end