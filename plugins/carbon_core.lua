PLUGIN.Title = 'carbon_core'
PLUGIN.Description = 'carbon core file'
PLUGIN.Version = '0.0.1a'
PLUGIN.Author = 'mischa/carex'
combat = cs.findplugin('carbon_combat')
local carbon_ = {['combat']='carbon_combat'}

local alib = nil
function loadLibrary( )
    if not alib then
        alib = cs.findplugin("ALibrary")
        if not alib then
            return false
        end
    end
    return true
end
function PLUGIN:Init()
    loadLibrary(carbon_)
end
function PLUGIN:ModifyDamage( takedamage,dmg )
    combat:CombatModifyDamage( takedamage,dmg )
end