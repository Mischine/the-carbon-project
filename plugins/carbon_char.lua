PLUGIN.Title = 'carbon_char'
PLUGIN.Description = 'character module'
PLUGIN.Version = '0.0.3'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    self:AddChatCommand( 'c', self.cmdCarbon )
    self:AddChatCommand( 'load', self.loadchar )
    self:AddChatCommand( 'check', self.showchar )

end
function PLUGIN:PostInit()
	local users = rust.GetAllNetUsers()

	for _, v in pairs( users ) do
		local netuserID = tostring(rust.GetUserID( v ) )
		self:GetUserData( v )

	end
end
function PLUGIN:loadchar( netuser, cmd, args)
	local netuserID = rust.GetUserID( netuser )
	self:Load( netuserID )
	rust.SendChatToUser( netuser, 'Reloaded data from ' ..  self[ netuserID ].name )
end
function PLUGIN:showchar( netuser, cmd, args)
	local netuserID = rust.GetUserID( netuser )
	rust.SendChatToUser( netuser, 'Checking data ' ..  self[ netuserID ].name )
end

function PLUGIN:Character(cmdData)
	--TODO:REFINE XP CALCULATIONS ? MAKE A FUNCTION ?

	local a=cmdData.netuserData.lvl -- current level
	local b=core.Config.settings.lvlmodifier --level modifier
	local bb=(1*1+1)/b*100-(1)*100
	rust.BroadcastChat(tostring(bb))
	local c=((a+1)*a+1+a+1)/b*100-(a+1)*100-(((a-1)*a-1+a-1)/b*100-(a-1)*100)-100 -- total needed to level
	local d=cmdData.netuserData.xp-((a-1)*a-1+a-1)/b*100-(a-1)*100-100
	local e=math.floor(d/c*100+0.5)
	local f=c-d
	local g=(a*a+a)/b*100-a*100
	local h=math.floor((((cmdData.netuserData.dp/c)*.5)*100)+0.5)
	local i=c*.5;
	if a==2 and core.Config.settings.lvlmodifier>=2 then g=0 end
	local j=
			{
				['list']={cmdData.txt.level..':                          '..tostring(a),
				' ',
				cmdData.txt.experience..':              ('..tostring(d)..'/'..tostring(c)..')   ['..tostring(e)..'%]   '..'('..tostring(f)..')',
				tostring(func:xpbar(e,32)),
				' ',
				cmdData.txt.deathpenalty..':         ('..tostring(cmdData.netuserData.dp)..'/'..tostring(i)..')   ['..tostring(h)..'%]',
				tostring(func:xpbar(h,32))},['cmds']=cmdData.txt['cmds_c']
			}

	func:TextBox(cmdData.netuser,j,cmdData.cmd,cmdData.args)
end
function PLUGIN:CharacterSkills(cmdData)

	local skillData = cmdData.netuserData.skills[ cmdData.args[2] ]
	if skillData then
		local a = skillData.lvl --level +1
		local b = core.Config.settings.weaponlvlmodifier --level modifier
		local c = (((a+1)*(a+1))+(a+1))/b*100-((a+1)*100)-((a*a)+a)/b*100-(a*100) --xp required for next level
		local d = math.floor(((skillData.xp/c)*100)+0.5) -- percent currently to next level.
		local e = c-skillData.xp -- left to go until level
		local content = {
			['list'] = {cmdData.txt.skill .. ':  ' .. skillData.name,cmdData.txt.level':  ' .. skillData.lvl,cmdData.txt.experience':  (' .. skillData.xp .. '/' .. c .. ')  [' .. d .. '%]  (' .. e .. ')', func:xpbar( d, 32 ) },
			['cmds']=cmdData.txt['cmds_c_skills'],
		}
		func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
	else
		local content = {
			--['prefix']='This is any prefix you would like to enter.',
			--['breadcrumbs']=args,
			--['header']='Header',
			--['subheader']='Subheader',
			--['msg']={},
			['list']={},
			['cmds']=cmdData.txt['cmds_c_skills'],
			--['suffix']='this is the suffix',
		}
		for k,v in pairs(cmdData.netuserData.skills) do
			local a = v.lvl+1 --level +1
			local b = core.Config.settings.weaponlvlmodifier --level modifier
			local c = ((a*a)+a)/b*100-(a*100) --xp required for next level
			local d = math.floor(((v.xp/c)*100)+0.5) -- percent currently to next level.
			table.insert( content.list, tostring('   ' .. v.name .. '    •    Level: ' .. v.lvl .. '    •    ' .. 'Exp: ' .. v.xp ))
			table.insert( content.list, tostring(func:xpbar( d, 32 )))
		end
		func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
	end

end
function PLUGIN:CharacterAttributes(cmdData)
    local content = {
    ['list']=
    {
        cmdData.txt.strength .. ':     ' .. cmdData.netuserData.attributes.str,
        func:xpbar(cmdData.netuserData.attributes.str*10,10),
	    cmdData.txt.agility .. ':      ' .. cmdData.netuserData.attributes.agi,
        func:xpbar(cmdData.netuserData.attributes.agi*10,10),
	    cmdData.txt.stamina .. ':      ' .. cmdData.netuserData.attributes.sta,
        func:xpbar(cmdData.netuserData.attributes.sta*10,10),
	    cmdData.txt.intellect .. ':    ' .. cmdData.netuserData.attributes.int,
        func:xpbar(cmdData.netuserData.attributes.int*10,10),
	    ' ',
	    'Available Attribute Points: ' .. cmdData.netuserData.ap .. ' / ' .. cmdData.netuserData.attributes.str+cmdData.netuserData.attributes.agi+cmdData.netuserData.attributes.sta+cmdData.netuserData.attributes.int+cmdData.netuserData.ap,
    },
	    ['cmds']=cmdData.txt['cmds_c_attr'],
    }
    func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end
function PLUGIN:CharacterAttributesTrain(cmdData)
	cmdData.args[3] = tonumber(cmdData.args[3])
	cmdData.args[4] = tostring(cmdData.args[4])
	if cmdData.args[3] >= 1 and (cmdData.args[4] == 'str' or cmdData.args[4] == 'agi' or cmdData.args[4] == 'sta' or cmdData.args[4] == 'int')then
		if cmdData.netuserData.ap >= cmdData.args[3] then
			if cmdData.netuserData.attributes[ cmdData.args[4] ] + cmdData.args[3]<=10 then
				cmdData.netuserData.ap=cmdData.netuserData.ap - cmdData.args[3]
				cmdData.netuserData.attributes[ cmdData.args[4] ] = cmdData.netuserData.attributes[ cmdData.args[4] ] + cmdData.args[3]
				rust.InventoryNotice(cmdData.netuser, '+' .. tostring(cmdData.args[3]) .. cmdData.args[4])
				self:Save(cmdData.netuserData.id)
				self:CharacterAttributes(cmdData)
			else
				local content = {
					['msg']=cmdData.txt['toomuchap'],
					['cmds']=cmdData.txt['cmds_c_attr_train'],
				}
				func:TextBoxError(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
			end
		elseif cmdData.netuserData.ap < cmdData.args[3] then
			local content = {
				['msg'] = cmdData.txt['insufficientap'],
				['cmds']=cmdData.txt['cmds_c_attr_train'],
			}
			func:TextBoxError(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
		end
	else
		func:TextBoxError(cmdData.netuser, content, cmdData.cmd, cmdData.args)
	end
end
function PLUGIN:CharacterPerks(cmdData)
	--TODO: ADD PERK CHAR COMMAND
end
function PLUGIN:CharacterPerksAdd(cmdData)
	--TODO: ADD PERK CHAR COMMAND
end
function PLUGIN:CharacterClass(cmdData)
	--TODO: ADD CHAR CLASS COMMAND
end
function PLUGIN:CharacterClassSelect(cmdData)
	--TODO: ADD CHAR CLASS SELECT COMMAND
end
function PLUGIN:CharacterReset(cmdData)
	--TODO: ADD CHAR RESET COMMAND
end
function PLUGIN:CharacterResetPerks(cmdData)
	--TODO: ADD  CHAR RESET PERKS COMMAND
end
function PLUGIN:CharacterResetAttributes(cmdData)
	--TODO: ADD CHAR RESET ATTRIBUTES COMMAND
end
function PLUGIN:CharacterResetClass(cmdData)
	--TODO: ADD CHAR RESET CLASS COMMAND
end

function PLUGIN:GiveXp(combatData, xp)

    local guildname = guild:getGuild( combatData.netuser )
    if( guildname ) then
        local gxp = math.floor( xp * 0.1 )
        local gxp = guild:GiveGXP( guildname, gxp )
        if gxp > 0 then
            timer.Once( 3 , function() rust.InventoryNotice( combatData.netuser, '+' .. gxp .. 'gxp' )  end)
        end
    end

    if (combatData.netuserData.dp>xp) then
        combatData.netuserData.dp = combatData.netuserData.dp - xp
        rust.InventoryNotice( combatData.netuser, '-' .. (combatData.netuserData.dp - xp) .. 'dp' )
    elseif (combatData.netuserData.dp<=0) then
        combatData.netuserData.xp = combatData.netuserData.xp+xp
        combatData.netuserData.skills[ combatData.weapon.name ].xp = combatData.netuserData.skills[ combatData.weapon.name ].xp + xp
        rust.InventoryNotice( combatData.netuser, '+' .. xp .. 'xp' )
        self:PlayerLvl(combatData, xp)
        self:WeaponLvl(combatData, xp)
    else
        local xp = xp-combatData.netuserData.dp
        combatData.netuserData.xp = combatData.netuserData.xp+xp
        combatData.netuserData.skills[ combatData.weapon.name ].xp = combatData.netuserData.skills[ combatData.weapon.name ].xp + xp
        combatData.netuserData.dp = 0
        rust.InventoryNotice( combatData.netuser, '-' .. combatData.netuserData.dp .. 'dp' )
        rust.InventoryNotice( combatData.netuser, '+' .. xp .. 'xp' )
        self:PlayerLvl(combatData, xp)
        self:WeaponLvl(combatData, xp)
    end
    if combatData.netuser then self:Save( combatData.netuserData.id ) end if combatData.vicuser then self:Save( combatData.vicuserData.id ) end
end

--PLUGIN:getLvl
function PLUGIN:getLvl( netuser )
    local netuserID = rust.GetUserID( netuser )
    local lvl = self[ netuserID ].lvl
    return lvl
end

--PLUGIN:GiveDp
function PLUGIN:GiveDp(combatData, dp)
    if ((combatData.vicuserData.dp+dp/combatData.vicuserData.xp) >= .5) then
        combatData.vicuserData.dp = combatData.vicuserData.xp*.5
        rust.InventoryNotice( combatData.vicuser, '+' .. (dp - combatData.vicuserData.xp*.5) .. 'dp' )
    else
        combatData.vicuserData.dp = combatData.vicuserData.dp + dp
        rust.InventoryNotice( combatData.vicuser, '+' .. (dp) .. 'dp' )
    end

    if combatData.netuser then self:Save( combatData.netuserData.id ) end if combatData.vicuser then self:Save( combatData.vicuserData.id ) end
end

--PLUGIN:PlayerLvl
function PLUGIN:PlayerLvl(combatData, xp)
    local calcLvl = math.floor((math.sqrt(100*((core.Config.settings.lvlmodifier*(combatData.netuserData.xp+xp))+25))+50)/100)
    if calcLvl <= core.Config.settings.maxplayerlvl then
        if (calcLvl ~= combatData.netuserData.lvl) then
            combatData.netuserData.lvl = calcLvl
            rust.Notice( combatData.netuser, 'You are now level ' .. calcLvl .. '!', 5 )
        end
        local calcAp = math.floor(((math.sqrt(100*((core.Config.settings.lvlmodifier*(combatData.netuserData.xp+xp))+25))+50)/100)/3)
        if (calcAp > combatData.netuserData.ap) then
            combatData.netuserData.ap = calcAp
            timer.Once(2, function() rust.SendChatToUser( combatData.netuser, core.sysname, 'You have earned an attribute point!') end)
        end
        local calcPp = math.floor(((math.sqrt(100*((core.Config.settings.lvlmodifier*(combatData.netuserData.xp+xp))+25))+50)/100)/6)
        if (calcPp > combatData.netuserData.pp) then
            combatData.netuserData.pp = calcPp
            timer.Once(3, function() rust.SendChatToUser( combatData.netuser, core.sysname, 'You have earned a perk point!') end)
        end
        -- rust.SendChatToUser( combatData.netuser, core.sysname, tostring(combatData.netuserData.ap) .. ' ' .. tostring(combatData.netuserData.pp) .. ' ' .. tostring(calcAp) .. ' ' .. tostring(calcPp))
    else
        local ab = core.Config.settings.maxplayerlvl
        local b = core.Config.settings.lvlmodifier
        local f = ((ab*ab)+ab)/b*100-(ab*100)
        combatData.netuserData.xp = f
    end
end

--PLUGIN:WeaponLvl
function PLUGIN:WeaponLvl(combatData, xp)
    local calcLvl = math.floor((math.sqrt(100*((core.Config.settings.weaponlvlmodifier*(combatData.netuserData.skills[ combatData.weapon.name ].xp+xp))+25))+50)/100)
    if (calcLvl ~= combatData.netuserData.skills[ combatData.weapon.name ].lvl) then
        combatData.netuserData.skills[ combatData.weapon.name ].lvl = calcLvl
        timer.Once( 5, function()  rust.Notice( combatData.netuser, 'Your skill with the ' .. tostring(combatData.weapon.name) .. ' is now level ' .. tostring(calcLvl) .. '!', 5 ) end )
    end
end

--PLUGIN:SetDpPercent
function PLUGIN:SetDpPercent(netuser, percent)
    self:SetDpPercentById(rust.GetUserID( netuser ) ,percent )
    if (percent >= 0 and percent <= 100) then
        --[[rust.SendChatToUser( netuser, self:printmoney(netuser) )--]]
    end
end

--PLUGIN:SetDpPercentById
function PLUGIN:SetDpPercentById(netuserID, percent)
    if (percent >= 0 and percent <= 100) then
        if (percent == 0) then
            self[netuserID].dp = math.floor(self[netuserID].dp + self[netuserID].xp)
        else
            self[netuserID].dp = math.floor(self[netuserID].dp + (self[netuserID].xp * percent / 100))
        end
        self:Save( netuserID )
    end
end

function PLUGIN:GetUserData( netuser )

	local netuserID = tostring(rust.GetUserID( netuser ) )
	local data = self:Load( netuserID )

	if (not data ) then -- if not, creates one
		-- Check name
		data = {}
		data.id = netuserID
		data.name = netuser.displayName
		data.prevnames = {}
		data.reg = false
		data.lang = 'english'
		data.lvl = 1
		data.xp = 0
		data.pp = 0
		data.dp = 0
		data.ap = 0
		data.dmg = 1
		data.ut = 0 --the amount of times this user has untrained his/her attributes.
		data.attributes = {['str']=0,['agi']=0,['sta']=0,['int']=0 }
		data.buffs = {}
		data.skills = {}
		data.perks = {}
		data.crafting = false
		data.stats = {['deaths']={['pvp']=0,['pve']=0},['kills']={['pvp']=0,['pve']={['total']=0}}}
		data.prof = {
			['Engineer']={['lvl']=0,['xp']=0,['maxlvl']=70},        -- Disabled on default : When unlocked you get lvl 1
			['Medic']={['lvl']=0,['xp']=0,['maxlvl']=70},           -- Disabled on default : When unlocked you get lvl 1
			['Carpenter']={['lvl']=1,['xp']=0,['maxlvl']=70},
			['Armorsmith']={['lvl']=1,['xp']=0,['maxlvl']=70},
			['Weaponsmith']={['lvl']=1,['xp']=0,['maxlvl']=70},
			['Toolsmith']={['lvl']=1,['xp']=0,['maxlvl']=70},
			['Thief']={['lvl']=1,['xp']=0,['maxlvl']=70}            -- Disabled on default : When unlocked you get lvl 1
		}
		self:Save(netuserID)
	end
	if netuser.displayName ~= data.name then
		-- check new name
		table.insert( data.prevnames, data.name )
		data.name = netuser.displayName
		self:Save( netuserID )
	end
	self[netuserID] = data
	return data
end

-- DATA UPDATE AND SAVE
function PLUGIN:Save(netuserID)
	if self[ netuserID ].reg then
		print('Saving: ' .. netuserID)
		self.CharFile:SetText( json.encode( self[ netuserID ], { indent = true } ) )
		self.CharFile:Save()
	else

	end
end
-- DATA UPDATE AND SAVE
function PLUGIN:Load( netuserID )
	self.CharFile = util.GetDatafile( netuserID )
	local txt = self.CharFile:GetText()
	if txt ~= "" then
		local data = json.decode( txt )
		return data
	end
	return false
end

--[[
-- PLUGIN:GetUserData
function PLUGIN:GetUserData( netuser )
    local netuserID = rust.GetUserID( netuser )
    local data = self[ netuserID ] -- checks if data exist
    if (not data ) then -- if not, creates one
        data = {}
        data.id = netuserID
        data.name = netuser.displayName
        data.lang = 'english'
        data.lvl = 1
        data.xp = 0
        data.pp = 0
        data.dp = 0
        data.ap = 0
        data.dmg = 1
        data.ut = 0 --the amount of times this user has untrained his/her attributes.
        data.attributes = {['str']=0,['agi']=0,['sta']=0,['int']=0 }
        data.buffs = {}
        data.skills = {}
        data.perks = {}
        data.crafting = false
        data.stats = {['deaths']={['pvp']=0,['pve']=0},['kills']={['pvp']=0,['pve']={['total']=0}}}
        data.prof = {
            ['Engineer']={['lvl']=0,['xp']=0,['maxlvl']=70},        -- Disabled on default : When unlocked you get lvl 1
            ['Medic']={['lvl']=0,['xp']=0,['maxlvl']=70},           -- Disabled on default : When unlocked you get lvl 1
            ['Carpenter']={['lvl']=1,['xp']=0,['maxlvl']=70},
            ['Armorsmith']={['lvl']=1,['xp']=0,['maxlvl']=70},
            ['Weaponsmith']={['lvl']=1,['xp']=0,['maxlvl']=70},
            ['Toolsmith']={['lvl']=1,['xp']=0,['maxlvl']=70},
            ['Thief']={['lvl']=1,['xp']=0,['maxlvl']=70}            -- Disabled on default : When unlocked you get lvl 1
            }
        self[ netuserID ] = data
        self:UserSave()
    end
    return data
end


-- DATA UPDATE AND SAVE
function PLUGIN:UserSave()
    print('Saving user data.')
    selfFile:SetText( json.encode( self, { indent = true } ) )
    selfFile:Save()
    self:UserUpdate()
    func.spamNet = {}
end
function PLUGIN:UserUpdate()
    selfFile = util.GetDatafile( 'carbon_char' )
    local txt = selfFile:GetText()
    self = json.decode ( txt )
end
--]]