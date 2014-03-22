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
        print( 'Carbon_cfg file loaded!' )
        self.Config = json.decode( cfg_txt )
    else
        print( 'Creating carbon cfg file...' )
        self:SetDefaultConfig()
    end
    self.RegFile = util.GetDatafile( 'carbon_reg' )
    local reg_txt = self.RegFile:GetText()
    if (reg_txt ~= '') then
        print( 'Carbon_reg file loaded!' )
        self.Reg = json.decode( reg_txt )
    else
        print( 'Creating carbon_reg' )
	    self.Reg = {}
	    self:SaveReg()
    end

    self.sysname = self.Config.settings.sysname

    --self.rnd = 0
    --timer.Repeat(0.0066666667, function() math.randomseed(math.random(100)) self.rnd = math.random(100) end)

    self.tmpusers = {}
    -- self.UnregTimer = timer.Repeat( 60, function() self:UnregBC() end)
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
    thief = cs.findplugin("carbon_thief")

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
        ['entities'] = {
	        -- Wood structures
		    ['WoodGateway(Clone)'] = {['name']='Wood Gateway',['maxhealth']=2000,['dmg']=5,},
		    ['WoodGate(Clone)'] = {['name']='Wood Gate',['maxhealth']=1800,['dmg']=6,},
		    ['Barricade_Fence_Deplayable(Clone)'] = {['name']='Barricade',['maxhealth']=1000,['dmg']=25,},
		    ['Wood_Shelter(Clone)'] = {['name']='Wood Shelter',['maxhealth']=1000,['dmg']=3,},
		    ['WoodFoundation(Clone)'] = {['name']='Wood Foundation',['maxhealth']=2500,['dmg']=5,},
		    ['WoodWindowFrame(Clone)'] = {['name']='Wood Window',['maxhealth']=1000,['dmg']=5,},
		    ['WoodStairs(Clone)'] = {['name']='Wood Stairs',['maxhealth']=1000,['dmg']=19,},
		    ['WoodWall(Clone)'] = {['name']='Wood Wall',['maxhealth']=1000,['dmg']=5,},
		    ['WoodenDoor(Clone)'] = {['name']='Wooden Door',['maxhealth']=500,['dmg']=3,},
		    ['WoodDoorFrame(Clone)'] = {['name']='Wood Door Frame',['maxhealth']=1000,['dmg']=5,},
		    ['WoodCeiling(Clone)'] = {['name']='Wood Ceiling',['maxhealth']=1000,['dmg']=5,},
		    ['WoodRamp(Clone)'] = {['name']='Wood Ramp',['maxhealth']=1000,['dmg']=5,},
		    ['WoodPillar(Clone)'] = {['name']='Wood Pillar',['maxhealth']=5000,['dmg']=5,},
		    ['LargeWoodSpikeWall(Clone)'] = {['name']='Large Wood Spike Wall',['maxhealth']=1500,['dmg']=5,},
		    ['WoodSpikeWall(Clone)']={['name']='Wood Spike Wall',['maxhealth']=750,['dmg']=15,},
	        -- Utilities
		    ['Furnace(Clone)']={['name']='Furnace',['maxhealth']=500,['dmg']=25,},
		    ['WorkBench(Clone)']={['name']='Workbench',['maxhealth']=1000,['dmg']=25,},
		    ['SleepingBagA(Clone)']={['name']='Sleeping Bag',['maxhealth']=500,['dmg']=25,},
		    ['SmallStash(Clone)']={['name']='Small Stash',['maxhealth']=100,['dmg']=25,},
		    ['SingleBed(Clone)']={['name']='Bed',['maxhealth']=500,['dmg']=5,},
		    ['Campfire(Clone)']={['name']='Campfire',['maxhealth']=500,['dmg']=25,},
		    ['WoodBoxLarge(Clone)']={['name']='Large Storage Box',['maxhealth']=1000,['dmg']=5,},
		    ['WoodBox(Clone)']={['name']='Storage Box',['maxhealth']=500,['dmg']=5,},
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
	        ['PP_PER_LEVEL'] = 4,
	        ['AP_PER_LEVEL'] = 2,
	        ['LEVELCAP'] = 70,
            ['ENABLE_LOCAL_CHAT'] = true,
            ['CHAT_DISTANCE'] = 20,
            ['filename']='carbon',
            ['sysname']=' ',
            ['dppercent']=5,
            ['dppercent']=5,
            ['sleeperxppercent']=5,
            ['sleerperdppecent']=5,
            ['sleeperradius']=2,
            ['PLAYER_LEVEL_MODIFIER']=1, --Increasing is a multiplier: i.e. level*level*100*MODIFIER (NOTE: Level 1 is always 0)
            ['PLAYER_LEVEL_CAP']=70,
            ['GUILD_LEVEL_MODIFIER']=50,
	        ['GUILD_LEVEL_CAP']=10,
            ['CLASS_LEVEL_MODIFIER']=12,
	        ['CLASS_LEVEL_CAP']=20,
	        ['WEAPON_LEVEL_MODIFIER']=12,
	        ['WEAPON_LEVEL_CAP']=10,
            ['untrainperkcost']=500, --this is the cost in copper
	        ['untrainattrcost']=500, --this is the cost in copper
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
                ['GUILD_LEVEL_MODIFIER']= 10,
                ['GUILD_LEVEL_CAP']= 10,
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
            },
        },
	    ['perks']={
		    ['parry']={['name']='Parry',['req']={['attr']={['str']=nil,['sta']=nil,['agi']={['1']=1,['2']=2,['3']=3,['4']=4,['5']=5,},['int']=nil,['cha']=nil,['wis']=nil,['wil']=nil,['per']=nil,['chance']=nil},['lvl']=nil,['class']=nil,['achievement']=nil,['quest']=nil}},
		    ['disarm']={['name']='Disarm',['req']={['attr']={['str']=nil,['sta']=nil,['agi']={['1']=1,['2']=2,['3']=3,['4']=4,['5']=5,},['int']=nil,['cha']=nil,['wis']=nil,['wil']=nil,['per']=nil,['chance']=nil},['lvl']=nil,['class']=nil,['achievement']=nil,['quest']=nil,}},
		    ['stoneskin']={['name']='Stoneskin',['req']={['attr']={['str']={['1']=1,['2']=2,['3']=3,['4']=4,['5']=5,},['sta']=nil,['agi']=nil,['int']=nil,['cha']=nil,['wis']=nil,['wil']=nil,['per']=nil,['chance']=nil},['lvl']=nil,['class']=nil,['achievement']=nil,['quest']=nil,}},
		    ['knockdown']={['name']='Knockdown',['req']={['attr']={['str']={['1']=1,['2']=2,['3']=3,['4']=4,['5']=5,},['sta']=nil,['agi']=nil,['int']=nil,['cha']=nil,['wis']=nil,['wil']=nil,['per']=nil,['chance']=nil},['lvl']=nil,['class']=nil,['achievement']=nil,['quest']=nil,}},
		    ['rage']={['name']='Rage',['req']={['attr']={['str']={['1']=2,['2']=4,['3']=6,['4']=8,['5']=10,},['sta']=nil,['agi']=nil,['int']=nil,['cha']=nil,['wis']=nil,['wil']=nil,['per']=nil,['chance']=nil},['lvl']={['1']=10,['2']=20,['3']=30,['4']=40,['5']=50,},['class']=nil,['achievement']=nil,['quest']=nil,}},
	    },
	    ['level']={
		    ['player']={},
		    ['guild']={},
		    ['weapon']={},
		    ['class']={},
	    },
    }
    for level = self.Config.settings.PLAYER_LEVEL_CAP, 1, -1 do
	    if level == 1 then
	        self.Config.level.player[tostring(level)] = 0
	    else
	        self.Config.level.player[tostring(level)] = math.floor((level*level*100)*self.Config.settings.PLAYER_LEVEL_MODIFIER)
		end
    end
    for level = self.Config.settings.GUILD_LEVEL_CAP, 1, -1 do
	    if level == 1 then
		    self.Config.level.guild[tostring(level)] = 0
	    else
		    self.Config.level.guild[tostring(level)] = math.floor((level*level*100)*self.Config.settings.GUILD_LEVEL_MODIFIER)
	    end
    end
    for level = self.Config.settings.CLASS_LEVEL_CAP, 1, -1 do
	    if level == 1 then
		    self.Config.level.class[tostring(level)] = 0
	    else
		    self.Config.level.class[tostring(level)] = math.floor((level*level*100)*self.Config.settings.CLASS_LEVEL_MODIFIER)
	    end
    end
    for level = self.Config.settings.WEAPON_LEVEL_CAP, 1, -1 do
	    if level == 1 then
		    self.Config.level.weapon[tostring(level)] = 0
	    else
		    self.Config.level.weapon[tostring(level)] = math.floor((level*level*100)*self.Config.settings.WEAPON_LEVEL_MODIFIER)
	    end
    end
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
	    cmd:ChannelLocal( netuser )
	end
    rust.BroadcastChat( netuser.displayName .. ' has joined the server!')
end

function PLUGIN:OnUserDisconnect( netplayer )
	if not netplayer then return end
	local netuser = rust.NetUserFromNetPlayer(netplayer) if not netuser then return end
	rust.BroadcastChat( netuser.displayName .. ' has left the server!' )
	local netuserID = tostring(rust.GetUserID( netuser ) ) if not char[netuserID] then return end
	if thief:hasStealth( netuser ) then thief:Unstealth( netuser ) end
	if not char[netuserID].reg then
		if self.tmpusers[netuser.displayName] then
			self.tmpusers[ netuser.displayName] = nil
		end
	else
		char:Save( netuser, true )
	end
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
	local name = string.lower(netuser.displayName)
	local found = false
	for _,v in pairs( self.Reg ) do
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
	char:Save( netuser )
	core:SaveReg()
	print( netuser.displayName .. ' has registered with ID: ' .. tostring( netuserID ) )
end

-- GUILD DOOR ACCESS!
local DeployableObjectOwnerID = util.GetFieldGetter( Rust.DeployableObject, "ownerID", true )
function PLUGIN:CanOpenDoor( netuser, door )

	-- Get and validate the deployable
	local deployable = door:GetComponent( "DeployableObject" )
	if (not deployable) then return end

	-- Get the owner ID and the user ID
	local ownerID = tostring( DeployableObjectOwnerID( deployable ) )
	local userID = rust.GetUserID( netuser )

	-- check if user is owner.
	if (ownerID == userID) then return true end

	-- if not, get guilds           TODO: Test this.
	local guildname = guild:getGuild( netuser )
	if guildname then
		local guilddata = guild:getGuildData( guildname )
		if guilddata then
			for k, v in pairs( guild.members ) do
				if (k == ownerID) then rust.Notice( netuser, 'Entered/left ' .. v.name .. '\'s house.' ) return true end
			end
		end
	end
	-- TODO : Finish the thieving. I need a cfg file and how they lvl up.
	-- Need handmade Lockpick and luck to open doors. -- Maybe have a cooldown on it when fail?
	if thief:isThief( netuser ) then
		local inv = rust.GetInventory( netuser )
		if not inv then return false end


	end
end

function PLUGIN:SaveReg()
	self.RegFile:SetText( json.encode( self.Reg, { indent = true } ) )
	self.RegFile:Save()
end

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