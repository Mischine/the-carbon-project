PLUGIN.Title = 'carbon_core'
PLUGIN.Description = 'core module'
PLUGIN.Version = '0.0.3'
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
    self.RegFile = util.GetDatafile( 'carbon_reg' )
    local reg_txt = self.RegFile:GetText()
    if (reg_txt ~= '') then
        print( 'Carbon cfg file loaded!' )
        self.Reg = json.decode( reg_txt )
    else
        print( 'Creating carbon_reg' )
	    self.Reg = {}
    end

    self.sysname = self.Config.settings.sysname

    --self.rnd = 0
    --timer.Repeat(0.0066666667, function() math.randomseed(math.random(100)) self.rnd = math.random(100) end)

    self.tmpusers = {}
    self.UnregTimer = timer.Repeat( 60, function() self:UnregBC() end)
end

function PLUGIN:UnregBC()
	local content = {
		['header'] = 'Register to The Carbon Project',
		['msg'] = 'Please be sure to register. When you\'re registered your progress will be saved. Else it wont. \nTo register type /register',
		['suffix'] = 'Be sure to check out: www.tempusforge.com for more information about The Carbon Project.'
	}
	local cmd = 'register'
	local args = {}
	args[1] = 'Unregistered user'
	local netusers = rust.GetAllNetUsers()
	for _, netuser in pairs( netusers ) do
		local id = rust.GetUserID( netusers )
		local data = char[ id ]
		if not data then return end
		if not data.reg then func:TextBox(netuser,content,cmd,args)	end
	end
end

function PLUGIN:LoadLibrary()
    call = cs.findplugin("carbon_call")
    char = cs.findplugin("carbon_char")
    chat = cs.findplugin("carbon_chat")
    combat = cs.findplugin("carbon_combat")
    debug = cs.findplugin("carbon_debug")
    econ = cs.findplugin("carbon_econ")
    func = cs.findplugin("carbon_func")
    guild = cs.findplugin("carbon_guild")
    mail = cs.findplugin("carbon_mail")
    party = cs.findplugin("carbon_party")
    perk = cs.findplugin("carbon_perk")
    prof = cs.findplugin("carbon_prof")
    reload = cs.findplugin("carbon_reload")
    sandbox = cs.findplugin("carbon_sandbox")
    stats = cs.findplugin("carbon_stats")
    lang = cs.findplugin("carbon_lang")
    cmd = cs.findplugin("carbon_cmd")
    donate = cs.findplugin("carbon_donate")
    vote = cs.findplugin("carbon_vote")
    oxidecore = cs.findplugin("oxidecore")

    a = cs.findplugin("carbon_a")
    b = cs.findplugin("carbon_b")
    c = cs.findplugin("carbon_c")
    d = cs.findplugin("carbon_d")
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
            ['9mm Pistol']={['name']='9mm Pistol',['type']='c',['dmg']=1,['lvl']=1},
            ['M4']={['name']='M4',['type']='l',['dmg']=1,['lvl']=0},
            ['Bolt Action Rifle']={['name']='Bolt Action Rifle',['type']='l',['dmg']=1,['lvl']=10},
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
            ['ENABLE_LOCAL_CHAT'] = true,
            ['CHAT_DISTANCE'] = 20,
            ['filename']='carbon',
            ['sysname']=' ',
            ['dppercent']=5,
            ['dppercent']=5,
            ['sleeperxppercent']=5,
            ['sleerperdppecent']=5,
            ['sleeperradius']=2,
            ['lvlmodifier']=1, --0.5=Veteran | 1=hard | 1.5=normal | 2=easy
            ['maxplayerlvl']=70,
            ['glvlmodifier']=.1,
            ['clvlmodifier']=.5,
            ['maxguildlvl']=10,
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
            ['vault']={             -- room is inventory space / cost is in gold.
                ['1'] = {
                    ['cap']=50
                },
                ['2'] = {
                    ['cost']=3,
                    ['req']=2,
                    ['cap']=500
                },
                ['3'] = {
                    ['cost']=5,
                    ['req']=5,
                    ['cap']=750
                },
                ['4'] = {
                    ['cost']=10,
                    ['req']=7,
                    ['cap']=1000
                },
                ['5'] = {
                    ['cost']=20,
                    ['req']=10,
                    ['cap']=1500
                },
            },
            ['prices']={
                ['create']=25000
            },
            ['settings']={
                ['glvlmodifier']= .1,
                ['maxguildlvl']= 10,
                ['lvlreq']={
                    ['1']= 0,
                    ['2']= 3,
                    ['3']= 5,
                    ['4']= 10,
                    ['5']= 15,
                    ['6']= 20,
                    ['7']= 30,
                    ['8']= 40,
                    ['9']= 50,
                    ['10']= 100
                }
            },
            ['calls']={
                ['rally']={['name']='Rally!',['requirements']={['cost']={['g']=1,['s']=50,['c']=0},['glvl']=4},['mod']=.05},
                ['syg']={['name']='Stand Your Ground!',['requirements']={['cost']={['g']=1,['s']=50,['c']=0},['glvl']=5,['mod']=.05},['mod']=.04},
                ['cotw']={['name']='Call Of The Wild',['requirements']={['cost']={['g']=1,['s']=0,['c']=0},['glvl']=2},['mod']=.05},
                ['forglory']={['name']='For Glory!',['requirements']={['cost']={['g']=2,['s']=0,['c']=0},['glvl']=5},['mod']=.05 },
                ['kos']={['name']='Kill On Sight!',['requirements']={['cost']={['g']=5,['s']=0,['c']=0},['glvl']=6},['mod']=50}
            }
        }
    }
    self:ConfigSave()
end

--PLUGIN:OnUserConnect | http://wiki.rustoxide.com/index.php?title=Hooks/OnUserConnect
function PLUGIN:OnUserConnect( netuser )
    print(util.QuoteSafe(netuser.displayName .. ' has connected.'))
    -- self:AlphaTXT( netuser ) --  [Oxide] carbon_sandbox: [string "util.stl"]:171: attempt to index local 'str' (a nil value)
    --[[
    if netuser.displayName:find'%W' then
        rust.SendChatToUser( netuser, ' ', ' ' )
        rust.SendChatToUser( netuser, '**ALERT**', 'Your name must be alphanumeric( numbers and letters )! Please change your name. You\'ll be kicked' )
        timer.Once(25, function() netuser:Kick( NetError.Facepunch_Kick_RCON, true ) end)
        return
    end
    --]]
    local data = char:GetUserData( netuser ) -- asks for dat.
    if( data ) then
	    if ( data.mail ) then
	        local i = 0
	        for _, v in pairs( data.mail ) do
	            if( not v.read ) then i = i + 1 end
	        end
	        if( i > 0 ) then rust.SendChatToUser( netuser,'/Mail', 'You\'ve got ' .. tostring( i ) .. ' unread mails!' ) end
	    end
	    if not data.reg then
		    for k, _ in pairs( self.Reg ) do
			    if netuser.displayName == k then
				    rust.SendChatToUser( netuser, 'Your name is already used. Please change your name. You will be kicked.' )
				    timer.Once(25, function() netuser:Kick( NetError.Facepunch_Kick_RCON, true ) end)
				    return
			    end
		    end
		    for k, _ in pairs( self.tmpusers ) do
			    if netuser.displayName == k then
				    rust.SendChatToUser( netuser, 'Your name is already used. Please change your name. You will be kicked.' )
				    timer.Once(25, function() netuser:Kick( NetError.Facepunch_Kick_RCON, true ) end)
				    return
			    end
		    end
		    self.tmpusers[ netuser.displayName ] = netuser
		    rust.Notice( netuser, 'Please register with /register' )
	    end
	    if data.reg then
		    if data.name ~= netuser.displayName then
			    rust.SendChatToUser( netuser, 'Please revert your name back to: ' .. data.name .. '. You will be kicked.' )
			    timer.Once(25, function() netuser:Kick( NetError.Facepunch_Kick_RCON, true ) end)
			    print( data.name .. '( ' .. data.id .. ' ) has logged in with a different name: ' .. netuser.displayName )
		    end
	    end
	    data.crafting = false
	end
    rust.BroadcastChat( netuser.displayName .. ' has connected to the server!')
end

function PLUGIN:OnUserDisconnect( netplayer )
	local netuser = rust.NetUserFromNetPlayer(netplayer)
	local netuserID = tostring(rust.GetUserID( netuser ) )
	rust.BroadcastChat( netuser.displayName .. ' has left the server!' )
	if not char[netuserID].reg then
		if self.tmpusers[netuser.displayName] then
			self.tmpusers[ netuser.displayName] = nil
			char[ netuserID ] = nil
		return end
	end
	char:Save( netuserID, netuser )
	char[netuserID] = nil
end

-- ------------------------------------------
-- /register To register to be able to save
-- ------------------------------------------
function PLUGIN:cmdRegister( netuser, cmd ,args )
	local netuserID = rust.GetUserID( netuser )
	local data = char[ netuserID ]
	if not data then rust.Notice( netuser, 'Could not find userdata. Try relogging.' ) return end
	if data.reg then rust.Notice( netuser, 'You\'re already registered.' ) return end
	local name = netuser.displayName:lower()
	local found = false
	for _,v in pairs( self.reg ) do
		string.find( name, v )
		local found = true
	end
	if found then
		local content = {
			['header'] = 'Unsuccesfull',
			['msg'] = 'Registration failed, your name is already used. Please choose a different name. \nInfo:',
			['list'] = {'Name: ' .. netuser.displayName .. '( Already Used )' ,'ID: ' .. tostring(netuserID),},
			['suffix'] = 'Be sure to check out: www.tempusforge.com'
		}
		func:TextBox(netuser,content,cmd,args)
	return end
	self.Reg[ netuserID ] = netuser.displayName
	local content = {
		['header'] = 'Succesfull!',
		['msg'] = 'You have registered succesfully to The Carbon Project. Your progress will now be safed. \nRegistration info:',
		['list'] = {'Name: ' .. netuser.displayName ,'ID: ' .. tostring(netuserID),},
		['suffix'] = 'Be sure to check out: www.tempusforge.com'
	}
	func:TextBox(netuser,content,cmd,args)
	data.reg = true
	char:Save( netuserID, netuser )
	core:SaveReg()
	print( netuser.displayName .. ' has registered with ID: ' .. tostring( netuserID ) )
end

function PLUGIN:SaveReg()
	self.RegFile:SetText( json.encode( self.Reg, { indent = true } ) )
	self.RegFile:Save()
end

--[[
-- CONFIG UPDATE AND SAVE
function PLUGIN:ConfigSave()
    self.ConfigFile:SetText( json.encode( self.Config, { indent = true } ) )
    self.ConfigFile:Save()
    self:ConfigUpdate()
end
function PLUGIN:ConfigUpdate()
    self.ConfigFile = util.GetDatafile( 'carbon_cfg' )
    local txt = self.ConfigFile:GetText()
    self.Config = json.decode ( txt )
end
]]