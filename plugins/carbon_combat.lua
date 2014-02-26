PLUGIN.Title = 'carbon_combat'
PLUGIN.Description = 'carbon core file'
PLUGIN.Version = '0.0.1a'
PLUGIN.Author = 'mischa/carex'
function PLUGIN:Init()
    --nothing here
end

function PLUGIN:CombatModifyDamage( takedamage,dmg )
    rust.BroadcastChat( tostring(dmg.amount) )
end