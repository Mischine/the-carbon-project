PLUGIN.Title = 'carbon_core'
PLUGIN.Description = 'core module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

local OSdateTime = util.GetStaticPropertyGetter( System.DateTime, 'Now' )

function PLUGIN:Init()
    self:LoadLibrary()

    self.ConfigFile = util.GetDatafile( 'carbon_cfg' )
    local cfg_txt = self.ConfigFile:GetText()
    if (cfg_txt ~= '') then
        print( 'Carbon cfg file loaded!' )
        self.Config = json.decode( cfg_txt )
    else
        print( 'Creating carbon cfg file...' )
        self:SetDefaultConfig()
    end

    self.sysname = self.Config.settings.sysname

    self.rnd = 0
    self.Timer = {}
    self.Timer.randomseed = timer.Repeat(0.0066666667, function() math.randomseed(math.random(100)) self.rnd = math.random(100) end)


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
    func = cs.findplugin("carbon_func")
    mail = cs.findplugin("carbon_mail")
    debug = cs.findplugin("carbon_debug")
    sandbox = cs.findplugin("carbon_sandbox")
end

--PLUGIN:SetDefaultConfig
function PLUGIN:SetDefaultConfig()
    self.Config = {
        ['npc']={
            ['ZombieNPC_SLOW']={['id']='ZombieNPC_SLOW',['ai']='ZombieController',['name']='Slow Zombie',['xp']=45,['dmg']=.25,['attributes']={['sta']=10,['agi']=10,['str']=10}},
            ['ZombieNPC_FAST']={['id']='ZombieNPC_FAST',['ai']='ZombieControlller',['name']='Fast Zombie',['xp']=40,['dmg']=.25,['attributes']={['sta']=9,['agi']=9,['str']=9}},
            ['ZombieNPC']={['id']='ZombieNPC',['ai']='ZombieController',['name']='Zombie',['xp']=35,['dmg']=.25,['attributes']={['sta']=8,['agi']=8,['str']=8}},
            ['MutantBear']={['id']='MutantBear',['ai']='BearAI',['name']='Mutant Bear',['xp']=30,['dmg']=.25,['attributes']={['sta']=7,['agi']=7,['str']=7}},
            ['MutantWolf']={['id']='MutantWolf',['ai']='WolfAI',['name']='Mutant Wolf',['xp']=25,['dmg']=.15,['attributes']={['sta']=6,['agi']=6,['str']=6}},
            ['Bear']={['id']='Bear',['ai']='BearAI',['name']='Bear',['xp']=20,['dmg']=.35,['attributes']={['sta']=5,['agi']=5,['str']=5}},
            ['Wolf']={['id']='Wolf',['ai']='WolfAI',['name']='Wolf',['xp']=15,['dmg']=.25,['attributes']={['sta']=4,['agi']=4,['str']=4}},
            ['Stag_A']={['id']='Stag_A',['ai']='StagAI',['name']='Stag',['xp']=10,['dmg']=.50,['attributes']={['sta']=3,['agi']=3,['str']=3}},
            ['Boar_A']={['id']='Boar_A',['ai']='BoarAI',['name']='Boar',['xp']=10,['dmg']=.50,['attributes']={['sta']=2,['agi']=2,['str']=2}},
            ['Chicken']={['id']='Chicken',['ai']='ChickenAI',['name']='Chicken',['xp']=5,['dmg']=1,['attributes']={['sta']=1,['agi']=1,['str']=1}},
            ['Rabbit']={['id']='Rabbit',['ai']='RabbitAI',['name']='Rabbit',['xp']=5,['dmg']=1,['attributes']={['sta']=1,['agi']=1,['str']=1}},
        },
        ['weapon']={
            ['Unarmed']={['name']='Unarmed',['type']='m',['dmg']=1,['lvl']=1},
            ['Uber Hunting Bow']={['name']='Uber Hunting Bow',['type']='l',['dmg']=1,['lvl']=1},
            ['Stone Hatchet']={['name']='Stone Hatchet',['type']='m',['dmg']=1,['lvl']=1},
            ['Hatchet']={['name']='Hatchet',['type']='m',['dmg']=1,['lvl']=1},
            ['Pick Axe']={['name']='Pick Axe',['type']='m',['dmg']=1,['lvl']=1},


            ['Hand Cannon']={['name']='Hand Cannon',['type']='c',['dmg']=1,['lvl']=1},
            ['Pipe Shotgun'] ={['name']='Pipe Shotgun',['type']='c',['dmg']=1,['lvl']=1},
            ['Revolver']={['name']='Revolver',['type']='c',['dmg']=1,['lvl']=1},
            ['9mm Pistol']={['name']='9mm Pistol',['type']='c',['dmg']=1,['lvl']=3},
            ['M4']={['name']='M4',['type']='l',['dmg']=1,['lvl']=5},
            ['Bolt Action Rifle']={['name']='Bolt Action Rifle',['type']='l',['dmg']=5,['lvl']=1},
            ['Explosive Charge']={['name']='Explosive Charge',['type']='e',['dmg']=1,['lvl']=1},
            ['F1 Grenade']={['name']='F1 Grenade',['type']='e',['dmg']=1,['lvl']=1},


            ['Hunting Bow']={['name']='Hunting Bow',['type']='l',['dmg']=1,['lvl']=1},
            ['MP5A4']={['name']='MP5A4',['type']='l',['dmg']=1,['lvl']=1},
            ['P250']={['name']='P250',['type']='c',['dmg']=1,['lvl']=1},



            ['Rock']={['name']='Rock',['type']='m',['dmg']=1,['lvl']=1},
            ['Shotgun']={['name']='Shotgun',['type']='c',['dmg']=1,['lvl']=1},

            ['Uber Hatchet']={['name']='Uber Hatchet',['type']='c',['dmg']=1,['lvl']=1},
        },
        ['settings']={
            ['filename']='carbon',
            ['sysname']=' ',
            ['dppercent']=5,
            ['dppercent']=5,
            ['sleeperxppercent']=5,
            ['sleerperdppecent']=5,
            ['sleeperradius']=2,
            ['lvlmodifier']=1, --0.5=Veteran | 1=hard | 1.5=normal | 2=easy
            ['glvlmodifier']=.1,
            ['untraincost']=500, --this is the cost in copper
            ['untraincostgrowth']=.10, --the rate at which untrain cost grows floored.
            ['weaponlvlmodifier']=0.5,--0.5=Veteran | 1=hard | 1.5=normal | 2=easy
            ['xpmodifier']=1, -- multiplies values of npc xp given. (ie; 2 = 2x npc reward)
            ['censor'] = {
                ['chat']={'fuck','shit','bitch','ass'},
                ['tag']={'TIT','SEX','FU','FUK','FUC','DIK'}
            }
        },
        ['guild'] = {
            ['prices']={
                ['create']=25000
            },
            ['settings']={
                ['vault']={['req']=2,['cost']=50000 ,['slots']=30},
                ['glvlmodifier']=.1,
            },
            ['calls']={
                ['rally']={['requirements']={['cost']=30000,['glvl']=3},['mod']=.05},
                ['syg']={['requirements']={['cost']=30000,['glvl']=3,['mod']=.05},['mod']=.04},
                ['cotw']={['requirements']={['cost']=25000,['glvl']=2},['mod']=.05},
                ['forglory']={['requirements']={['cost']=25000,['glvl']=2},['mod']=.05 },
                ['kos']={['requirements']={['cost']=25000,['glvl']=2},['mod']=50}
            }
        }
    }
    self:ConfigSave()
end

--PLUGIN:OnUserConnect | http://wiki.rustoxide.com/index.php?title=Hooks/OnUserConnect
function PLUGIN:OnUserConnect( netuser )
    print(tostring(netuser.displayName .. ' has connected.'))
    --[[
    self:AlphaTXT( netuser )
    if netuser.displayName:find'%W' then
        rust.SendChatToUser( netuser, ' ', ' ' )
        rust.SendChatToUser( netuser, '**ALERT**', 'Your name must be alphanumeric( numbers and letters )! Please change your name. You\'ll be kicked' )
        timer.Once(25, function() netuser:Kick( NetError.Facepunch_Kick_RCON, true ) end)
        return
    end
    --]]
    local data = self:GetUserData( netuser ) -- asks for dat.
    data.name = netuser.displayName

    -- Check mail
    local netuserID = rust.GetUserID( netuser )
    if( not self.User[ netuserID ] ) then return end
    if ( self.User[ netuserID ].mail ) then
        local i = 0
        for k, v in pairs( self.User[ netuserID ].mail ) do
            if( not v.read ) then i = i + 1 end
        end
        if( i > 0 ) then rust.SendChatToUser( netuser,'/Mail', 'You\'ve got ' .. tostring( i ) .. ' unread mails!' ) end
    end
    rust.BroadcastChat( netuser.displayName .. ' has connected to the server!')

    -- Reset crafting:
    self.User[ netuserID ].crafting = false
end

--PLUGIN:OnUserChat
function PLUGIN:OnUserChat(netuser, name, msg)
    if ( msg:sub( 1, 1 ) ~= '/' ) then
        local tempstring = string.lower( msg )
        for k, v in ipairs( self.Config.settings.censor.chat ) do
            local found = string.find( tempstring, v )
            if ( found ) then
                rust.Notice( netuser, 'Dont swear!' )
                return false
            end
        end
        local userID = rust.GetUserID( netuser )
        local guild = self:getGuild( netuser )
        if( guild ) then
            local data = self:getGuildData( guild )
            name = data.tag .. ' ' .. name
            rust.BroadcastChat( name, msg )
            return false
        end
    end
end




-- CONFIG UPDATE AND SAVE
function PLUGIN:ConfigSave()
    self.ConfigFile:SetText( json.encode( self.Config, { indent = true } ) )
    self.ConfigFile:Save()
    self:ConfigUpdate()
end

