PLUGIN.Title = 'carbon_combat'
PLUGIN.Description = 'carbon core file'
PLUGIN.Version = '0.0.1a'
PLUGIN.Author = 'mischa/carex'

function PLUGIN:cmdTest( )
    rust.BroadcastChat( 'it works!' )
end