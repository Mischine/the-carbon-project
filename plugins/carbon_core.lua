PLUGIN.Title = 'carbon_core'
PLUGIN.Description = 'core module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    self:LoadLibrary()
end
function PLUGIN:LoadLibrary()
    call = cs.findplugin("carbon_call")
    combat = cs.findplugin("carbon_combat")
    econ = cs.findplugin("carbon_econ")
    guild = cs.findplugin("carbon_guild")
    party = cs.findplugin("carbon_party")
    perk = cs.findplugin("carbon_perk")
    char = cs.findplugin("carbon_char")
    prof = cs.findplugin("carbon_prof")
    util = cs.findplugin("carbon_util")
end