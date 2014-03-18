PLUGIN.Title = 'carbon_char'
PLUGIN.Description = 'character module'
PLUGIN.Version = '0.0.4'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    self.char = {}

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
	local data = self:GetUserData( netuser )
	if data then
		rust.SendChatToUser( netuser, 'Reloaded data for ' ..  data.name )
	else
		rust.SendChatToUser( netuser, 'Failed to reload your data. Please report this to an admin.' )
	end
end
function PLUGIN:showchar( netuser, cmd, args)
	local netuserID = tostring(rust.GetUserID( netuser ))
	if self[ netuserID ] then
		rust.SendChatToUser( netuser, core.sysname, 'Checking data for:' ..  self[ netuserID ].name )
	else
		rust.SendChatToUser( netuser, core.sysname, 'Player data not loaded! Please report this to an admin.' )
	end
end

function PLUGIN:Character(cmdData)
	local currentXp
	if cmdData.netuserData.lvl > 1 then	currentXp = cmdData.netuserData.xp-core.Config.level.player[tostring(cmdData.netuserData.lvl)] else	currentXp = cmdData.netuserData.xp end
	local requiredXp
	if cmdData.netuserData.lvl < core.Config.settings.PLAYER_LEVEL_CAP and cmdData.netuserData.lvl > 1 then
		requiredXp = core.Config.level.player[tostring(cmdData.netuserData.lvl+1)]-core.Config.level.player[tostring(cmdData.netuserData.lvl)]
	elseif cmdData.netuserData.lvl == 1 then
		requiredXp = core.Config.level.player[tostring(cmdData.netuserData.lvl+1)]
	else
		requiredXp = core.Config.level.player[tostring(core.Config.settings.PLAYER_LEVEL_CAP)]
	end

	--CALCULATE SOME STUFF
	local xpPercentage, xpToGo = math.floor(((currentXp/requiredXp)*100)+.5), requiredXp-currentXp
	local totalAllowedDp = requiredXp*.5
	local dpPercentage = math.floor(((cmdData.netuserData.dp/totalAllowedDp)*100)+.5)
	local content=
			{
				['list']={cmdData.txt.level..':                          '..tostring(cmdData.netuserData.lvl),
				' ',
				cmdData.txt.experience..':              ('..currentXp..'/'..requiredXp..')   ['..xpPercentage..'%]   '..'('..xpToGo..')',
				tostring(func:xpbar(xpPercentage,32)),
				' ',
				cmdData.txt.deathpenalty..':         ('..cmdData.netuserData.dp..'/'..totalAllowedDp..')   ['..dpPercentage..'%]',
				func:xpbar(dpPercentage,32)},['cmds']=cmdData.txt['cmds_c']
			}
	func:TextBox(cmdData.netuser,content,cmdData.cmd,cmdData.args)
end
function PLUGIN:CharacterSkills(cmdData)

	local skillData = cmdData.netuserData.skills[ cmdData.args[2] ]
	if skillData then
		local currentXp
		if skillData.lvl > 1 then currentXp = skillData.xp-core.Config.level.weapon[tostring(skillData.lvl)] else currentXp = skillData.xp end
		local requiredXp
		if skillData.lvl < core.Config.settings.WEAPON_LEVEL_CAP and skillData.lvl > 1 then
			requiredXp = core.Config.level.weapon[tostring(skillData.lvl+1)]-core.Config.level.weapon[tostring(skillData.lvl)]
		elseif skillData.lvl == 1 then
			requiredXp = core.Config.level.weapon[tostring(skillData.lvl+1)]
		else
			requiredXp = core.Config.level.weapon[tostring(core.Config.settings.WEAPON_LEVEL_CAP)]
		end
		local xpPercentage, xpToGo = math.floor(((currentXp/requiredXp)*100)+.5), requiredXp-currentXp
		local content = {
			['list'] = {cmdData.txt.skill .. ':  ' .. skillData.name,cmdData.txt.level .. ':  ' .. skillData.lvl,cmdData.txt.experience .. ':  (' .. currentXp .. '/' .. requiredXp .. ')  [' .. xpPercentage .. '%]  (' .. xpToGo .. ')', func:xpbar( xpPercentage, 32 ) },
			['cmds']=cmdData.txt['cmds_c_skills'],
		}
		func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
	else
		local content = {
			['list']={},
			['cmds']=cmdData.txt['cmds_c_skills']
		}
		for k,v in pairs(cmdData.netuserData.skills) do
			local currentXp
			if v.lvl > 1 then currentXp = v.xp-core.Config.level.weapon[tostring(v.lvl)] else currentXp = v.xp end
			local requiredXp
			if v.lvl < core.Config.settings.WEAPON_LEVEL_CAP and v.lvl > 1 then
				requiredXp = core.Config.level.weapon[tostring(v.lvl+1)]-core.Config.level.weapon[tostring(v.lvl)]
			elseif v.lvl == 1 then
				requiredXp = core.Config.level.weapon[tostring(v.lvl+1)]
			else
				requiredXp = core.Config.level.weapon[tostring(core.Config.settings.WEAPON_LEVEL_CAP)]
			end
			local xpPercentage, xpToGO = math.floor(((currentXp/requiredXp)*100)+.5), requiredXp-currentXp
			table.insert( content.list, tostring('   ' .. v.name .. '    •    Level: ' .. v.lvl .. '    •    ' .. xpPercentage .. '%' ))
			table.insert( content.list, tostring(func:xpbar( xpPercentage, 32 )))
		end
		func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
	end

end
function PLUGIN:CharacterAttributes(cmdData)
	local usedAp = 0
	for k,v in pairs(cmdData.netuserData.attributes) do
		usedAp = usedAp+v
	end
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
	    cmdData.txt.charisma .. ':    ' .. cmdData.netuserData.attributes.cha,
	    func:xpbar(cmdData.netuserData.attributes.cha*10,10),
	    cmdData.txt.wisdom .. ':    ' .. cmdData.netuserData.attributes.wis,
	    func:xpbar(cmdData.netuserData.attributes.wis*10,10),
	    cmdData.txt.perception .. ':    ' .. cmdData.netuserData.attributes.per,
	    func:xpbar(cmdData.netuserData.attributes.per*10,10),
	    cmdData.txt.luck .. ':    ' .. cmdData.netuserData.attributes.luc,
	    func:xpbar(cmdData.netuserData.attributes.luc*10,10),
	    ' ',
	    'Available Attribute Points: ' .. cmdData.netuserData.ap .. ' / ' .. cmdData.netuserData.ap+usedAp,
    },
	    ['cmds']=cmdData.txt['cmds_c_attr'],
    }
    func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end
function PLUGIN:CharacterAttributesTrain(cmdData)
	cmdData.args[3] = tonumber(cmdData.args[3])
	cmdData.args[4] = tostring(cmdData.args[4])
	if cmdData.args[3] >= 1 and ( self[ cmdData.netuserData.id ].attributes[ cmdData.args[4] ] ) then
		if cmdData.netuserData.ap >= cmdData.args[3] then
			if cmdData.netuserData.attributes[ cmdData.args[4] ] + cmdData.args[3]<=10 then
				cmdData.netuserData.ap=cmdData.netuserData.ap - cmdData.args[3]
				cmdData.netuserData.attributes[ cmdData.args[4] ] = cmdData.netuserData.attributes[ cmdData.args[4] ] + cmdData.args[3]
				rust.InventoryNotice(cmdData.netuser, '+' .. tostring(cmdData.args[3]) .. cmdData.args[4])
				self:Save(cmdData.netuser )
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
	local content = {
		['list']={},
		['cmds']=cmdData.txt['cmds_c_perks'],
	}
	local usedpp = 0
	for k,v in pairs(cmdData.netuserData.perks) do
		table.insert( content.list, tostring('   ' .. core.Config.perks[k].name))
		table.insert( content.list, tostring(func:xpbar( v*20, 5 )))
		usedpp = usedpp+v
	end
	table.insert( content.list, 'Available Perk Points: ' .. cmdData.netuserData.pp .. ' / ' .. usedpp+cmdData.netuserData.pp )
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
end
function PLUGIN:CharacterPerksTrain(cmdData)
	cmdData.args[3] = tonumber(cmdData.args[3])
	cmdData.args[4] = tostring(cmdData.args[4])
	if cmdData.args[3] >= 1 then
		if debug.list[ cmdData.netuser.displayName ] then debug:SendDebug( combatData.debug, '' ) end
		if (core.Config.perks[cmdData.args[4]]) then
			local currentPerkLvl = 0
			if cmdData.netuserData.perks[cmdData.args[4]] then currentPerkLvl = cmdData.netuserData.perks[cmdData.args[4]] end
			local desiredPerkLvl = currentPerkLvl+cmdData.args[3]
			if desiredPerkLvl <= 5 then
				if cmdData.netuserData.pp >= cmdData.args[3] then
					local res, atr, curlvl, reqlvl = self:RequirementCheck(cmdData, desiredPerkLvl)
					if res then
						cmdData.netuserData.pp=cmdData.netuserData.pp - cmdData.args[3]

						cmdData.netuserData.perks[ cmdData.args[4] ] = currentPerkLvl + cmdData.args[3]
						rust.InventoryNotice(cmdData.netuser, '+' .. tostring(cmdData.args[3]) .. ' '.. core.Config.perks[ cmdData.args[4] ].name)
						self:Save(cmdData.netuser )
						self:CharacterPerks(cmdData)
					else
						if atr then
							if atr=='str'then atr='Strength'
							elseif atr=='sta'then atr='Stamina'
							elseif atr=='agi'then atr='Agility'
							elseif atr=='int'then atr='Intellect'
							elseif atr=='cha'then atr='Charisma'
							elseif atr=='wis'then atr='Wisdom'
							elseif atr=='wil'then atr='Willpower'
							elseif atr=='per'then atr='Perception'
							elseif atr=='luc'then atr='Luck' end
						end
						local content = {
							['header']= 'Requirements not met',
							--obtain attribute nice name.. >;)
							['msg'] =tostring('Your '.. atr ..' must be at least '.. reqlvl),
							['list'] = {'Your current ' .. atr .. ' level is ' .. curlvl },
							['cmds'] = cmdData.txt['cmds_c_perks'],
						}
						func:TextBoxError(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
					end
				else
					local content = {
						['msg'] = cmdData.txt['insufficientpp'],
						['cmds']=cmdData.txt['cmds_c_attr_train'],
					}
					func:TextBoxError(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
				end
			else
				local content = {
				['msg'] = cmdData.txt['perklvloverlimit'],
				['cmds']=cmdData.txt['cmds_c_attr_train'],
				}
				func:TextBoxError(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
			end
		else
			local content = {
				['msg'] = cmdData.txt['perkdoesntexist'],
				['cmds']=cmdData.txt['cmds_c_attr_train'],
			}
			func:TextBoxError(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
		end
	else
		local content = {
			['msg'] = cmdData.txt['trainperknegative'],
			['cmds']=cmdData.txt['cmds_c_attr_train'],
		}
		func:TextBoxError(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
	end
end
function PLUGIN:RequirementCheck(cmdData, desiredPerkLvl)
	for k,v in pairs( core.Config.perks[cmdData.args[4]].req.attr ) do
		if (v) then
			if cmdData.netuserData.attributes[k] < v[tostring(desiredPerkLvl)] then return false, k, cmdData.netuserData.attributes[k],v[tostring(desiredPerkLvl)] end
		end
	end
	-- check character lvl
	if core.Config.perks[ cmdData.args[4] ].req.lvl then
		if cmdData.netuserData.lvl < core.Config.perks[cmdData.args[4]].req.lvl then return false, 'Level', cmdData.netuserData.lvl, core.Config.perks[cmdData.args[4]].req.lvl end
	end
	-- check class
	if core.Config.perks[ cmdData.args[4] ].req.class then
		if not cmdData.netuserData.class == core.Config.perks[cmdData.args[4]].req.class then return false, 'Class', cmdData.netuserData.class, core.Config.perks[cmdData.args[4]].req.class end
	end
	-- check achievements
	if core.Config.perks[ cmdData.args[4] ].req.achievement then
		for k, v in pairs( core.Config.perks[ cmdData.args[4] ].req.achievement) do
			local b = func:containsval( cmdData.netuserData.achievements, v )
			if not b then return false, 'Achievements', 'Not complete', core.Achieve[ tostring(v) ].name end
		end
	end
	-- check quests
	if core.Config.perks[ cmdData.args[4] ].req.quest then
		for k, v in pairs( core.Config.perks[ cmdData.args[4] ].req.quest) do
			local b = func:containsval( cmdData.netuserData.quests, v )
			if not b then return false, 'Quests', 'Not complete', core.Quest[tostring(v)].name end
		end
	end
	return true
end
function PLUGIN:CharacterReset(cmdData)
	local content = {
		['msg']=cmdData.txt['MSG_C_RESET'],
		['cmds']=cmdData.txt['CMDS_C_RESET'],
	}
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args) return
end
function PLUGIN:CharacterResetPerks(cmdData)
	--TODO: ADD COST THAT GROWS EACH TIME        ['untrainperkcost']=500, --this is the cost in copper | ['untraincostgrowth']=.10, --the rate at which untrain cost grows floored.
	local availablePp = cmdData.netuserData.pp
	local usedPp = 0
	for k,v in pairs(cmdData.netuserData.perks) do
		usedPp = usedPp+v
		cmdData.netuserData.perks[k] = nil
	end
	cmdData.netuserData.pp = cmdData.netuserData.pp+usedPp
	self:CharacterPerks(cmdData)
	self:Save(cmdData.netuser)
end
function PLUGIN:CharacterResetAttributes(cmdData)
	--TODO: ADD COST THAT GROWS              	['untrainattrcost']=500, --this is the cost in copper | ['untraincostgrowth']=.10, --the rate at which untrain cost grows floored.
	local availableAp = cmdData.netuserData.ap
	local usedAp = 0
	for k,v in pairs(cmdData.netuserData.attributes) do
		usedAp = usedAp+v
		cmdData.netuserData.attributes[k] = 0
	end
	cmdData.netuserData.ap = cmdData.netuserData.ap+usedAp
	self:CharacterAttributes(cmdData)
	self:Save(cmdData.netuser)
end
function PLUGIN:GiveXp(combatData, xp, weplvl )

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
        if weplvl then combatData.netuserData.skills[ combatData.weapon.name ].xp = combatData.netuserData.skills[ combatData.weapon.name ].xp + xp end
        rust.InventoryNotice( combatData.netuser, '+' .. xp .. 'xp' )
        self:PlayerLvl(combatData, xp)
        if weplvl then self:WeaponLvl(combatData, xp) end
    else
        local xp = xp-combatData.netuserData.dp
        combatData.netuserData.xp = combatData.netuserData.xp+xp
        if weplvl then combatData.netuserData.skills[ combatData.weapon.name ].xp = combatData.netuserData.skills[ combatData.weapon.name ].xp + xp end
        combatData.netuserData.dp = 0
        rust.InventoryNotice( combatData.netuser, '-' .. combatData.netuserData.dp .. 'dp' )
        rust.InventoryNotice( combatData.netuser, '+' .. xp .. 'xp' )
        self:PlayerLvl(combatData)
        if weplvl then self:WeaponLvl(combatData, xp) end
    end
    if combatData.netuser then self:Save( combatData.netuser ) end if combatData.vicuser then self:Save( combatData.vicuser ) end
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

    if combatData.netuser then self:Save( combatData.netuser ) end if combatData.vicuser then self:Save( combatData.vicuser ) end
end

--PLUGIN:PlayerLvl
function PLUGIN:PlayerLvl(combatData)   -- We dont use then xp variable
	-- for level = combatData.netuserData.lvl+5, 1, -1 do       -- handled further in the code, Less cpu usage?
		local level = combatData.netuserData.lvl + 1
		if combatData.netuserData.lvl >= core.Config.settings.PLAYER_LEVEL_CAP then combatData.netuserData.xp = core.Config.level.player[tostring(core.Config.settings.PLAYER_LEVEL_CAP)] return end -- Handles Max player lvl cap.
		if combatData.netuserData.xp >= core.Config.level.player[tostring(level)] then
			if combatData.netuserData.xp >= core.Config.level.player[tostring(level+1)] then    -- checks if it double level; If so, we loop trough all the levels just in case. ( double level is allmost impossible with Quests etc. )
				for i = core.Config.settings.PLAYER_LEVEL_CAP, level, - 1 do
					if combatData.netuserData.xp >= core.Config.level.player[tostring(i)] then
						level = i
						break
						--[[
							So what this does, When you double level, it's gonna check the whole table. so the first xp it gets is the level he has achieved.
							This for loop will only fire if they're already double leveled. And if they're only just double leveled it will stop at that level anyway.
							And it's dynamic, because we have a player level cap config. So we change that, it changes the for loop. ( just be sure to have the core.Config xp
							tables updated. :P ( could also add a security for that... but meh. )
						 ]]
					end
				end
			end

			-- Level up
			-- if level ~= currentLvl then  -- Already handled by previous if statements. Also, you didn't have a currentLvl variable.

				--ADJUST LEVEL
				combatData.netuserData.lvl = level --set character level
				func:Notice(combatData.netuser,'✛','You are now level ' .. tostring(level),5)

				--ADJUST ATTRIBUTE POINTS
				local usedAp = 0 --base attribute points
				for k,v in pairs(combatData.netuserData.attributes) do usedAp = usedAp+v end --tally up used ap
				if combatData.netuserData.ap ~= math.floor(level/core.Config.settings.AP_PER_LEVEL)-usedAp then
					combatData.netuserData.ap=combatData.netuserData.ap+(math.floor(level/core.Config.settings.AP_PER_LEVEL)-usedAp) --set ap
-- Added timers to these, they were overlapping.
					timer.Once( 5, function ()func:Notice(combatData.netuser,'✛','You have earned an attribute point!',5) end)
				end

				--ADJUST PERK POINTS
				local usedPp = 0 --base perk points
				for k,v in pairs(combatData.netuserData.perks) do usedPp = usedPp+v end -- tally up used pp
				if combatData.netuserData.pp ~= math.floor(level/core.Config.settings.PP_PER_LEVEL)-usedPp then
					combatData.netuserData.pp=combatData.netuserData.pp+(math.floor(level/core.Config.settings.PP_PER_LEVEL)-usedPp) --set pp
-- Added timers to these, they were overlapping.
					timer.Once( 10, function ()func:Notice(combatData.netuser,'✛','You have earned a perk point!',5) end)
				end

				--UNLOCK CLASS CHECK
				if level == 25 then
					local content = {
						['header'] = 'Classes unlock!',
						['msg'] = 'You\'re now able to choose an class! Choosing a class will cost you 5 Gold. Classes give you extra abilities to play with. ',
						['list'] = { 'To choose a class, type /class' },
						['suffix'] = 'For more information about classes visit: www.tempusforge.com'
					}
					local cmd = 'Classes unlock!'
					local args = {}
					args[1] = 'Unlock message.'
					func:TextBox( combatData.netuser, content, cmd, args )
				end
			-- end
		end

	-- end
	--[[ OLD CALC LEVEL STUFF.. REWRITTEN

    local calcLvl = math.floor((math.sqrt(100*((core.Config.settings.lvlmodifier*(combatData.netuserData.xp+xp))+25))+50)/100)
    if calcLvl <= core.Config.settings.maxplayerlvl then
        if (calcLvl ~= combatData.netuserData.lvl) then
            combatData.netuserData.lvl = calcLvl
            rust.Notice( combatData.netuser, 'You are now level ' .. calcLvl .. '!', 5 )
	        if calcLvl == 25 then       -- Unlock classes selection.
		        local content = {
			        ['header'] = 'Classes unlock!',
			        ['msg'] = 'You\'re now able to choose an class! Choosing a class will cost you 5 Gold. Classes give you extra abilities to play with. ',
			        ['list'] = { 'To choose a class, type /class' },
			        ['suffix'] = 'For more information about classes visit: www.tempusforge.com'
		        }
		        local cmd = 'Classes unlock!'
		        local args = {}
		        args[1] = 'Unlock message.'
		        func:TextBox( combatData.netuser, content, cmd, args )
	        end
        end
        local calcAp = math.floor(((math.sqrt(100*((core.Config.settings.lvlmodifier*(combatData.netuserData.xp+xp))+25))+50)/100)/3)
        local usedAp = 0
        local usedPp = 0
        for k,v in pairs(combatData.netuserData.attributes) do
	        usedAp = usedAp+v
        end
        if (calcAp > (combatData.netuserData.ap+usedAp)) then
            combatData.netuserData.ap = calcAp
            timer.Once(2, function() rust.SendChatToUser( combatData.netuser, core.sysname, 'You have earned an attribute point!') end)
        end
        local calcPp = math.floor(((math.sqrt(100*((core.Config.settings.lvlmodifier*(combatData.netuserData.xp+xp))+25))+50)/100)/6)
        for k,v in pairs(combatData.netuserData.perks) do
	        usedPp = usedPp+v
        end
        if (calcPp > (combatData.netuserData.pp+usedPp)) then
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
    ]]
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
    self:SetDpPercentById(netuser, rust.GetUserID( netuser ) ,percent )
    if (percent >= 0 and percent <= 100) then
        --[[rust.SendChatToUser( netuser, self:printmoney(netuser) )--]]
    end
end

--PLUGIN:SetDpPercentById
function PLUGIN:SetDpPercentById(netuser, netuserID, percent)
    if (percent >= 0 and percent <= 100) then
        if (percent == 0) then
            self[netuserID].dp = math.floor(self[netuserID].dp + self[netuserID].xp)
        else
            self[netuserID].dp = math.floor(self[netuserID].dp + (self[netuserID].xp * percent / 100))
        end
        self:Save( netuser )
    end
end


-- TODO: Add more classes. Medic before alpha maybe?
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--              CLASS COMMANDS
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:ClassReject( cmdData )
	local content = {
		['header'] = 'Class Reject',
		['msg'] = 'You\'re not high enough level to choose a class. Please return when you\'re level 25 or higher.',
		['suffix'] = 'More information about classes can be found at: www.tempusforge.com'
	}
	func:TextBox( cmdData.netuser, content, cmdData.cmd, cmdData.args )
end

function PLUGIN:ClassInfo( cmdData )
	local content = {
		['header'] = 'Class Info',
		['msg'] = 'Classes add a wide variaty of options in Carbon. \nHere is a list of all the available classes: ',
		['list'] = {'Thief'},
		['suffix'] = 'More information about classes can be found at: www.tempusforge.com'
	}
	func:TextBox( cmdData.netuser, content, cmdData.cmd, cmdData.args )
end

function PLUGIN:SpecThief( cmdData )
	if not cmdData.args[2] then
		self:ThiefInfo( cmdData )
	elseif cmdData.args[2]:lower() == 'spec' then
		local canbuy = econ:canBuy( cmdData.netuser, 5, 0, 0)
		if not canbuy then rust.Notice( cmdData.netuser, 'Not enough balance, to spec a class it will cost 5 Gold.' ) return end
		econ:RemoveBalance( cmdData.netuser, 5, 0 ,0 )
		thief:SpecThief( cmdData )
	else
		self:ThiefInfo( cmdData )
	end
end

function PLUGIN:ThiefInfo( cmdData )
	local content = {
		['header'] = 'Thief Info',
		['msg'] = 'A thief is a master of perception. Be stealthy. Backstab enemies or try to unlock their doors even? \nThief Features:',
		['list'] = {'steal', 'stealth', 'backstab', 'picklock' },
		['suffix'] = 'To spec thief, /class thief spec'
	}
	func:TextBox( cmdData.netuser, content, cmdData.cmd, cmdData.args )
end

function PLUGIN:ThiefCmds( cmdData )
	local content = {
		['header'] = 'Thief Commands',
		['msg'] = 'When trying to picklock a door, you need to have Handmade Lockpicks in slot 6 on your hotbar. To backstab a player you need to have a melee weapon, and standing behind a enemy in stealth mode when you hit them. Here is a list of thief commands:',
		['list'] = {'/steal "name" - To steal from someone nearby.','/stealth - To go into stealth','/unstealth - To go visible again', },
		['suffix'] = 'More information about the thief at: www.tempusforge.com'
	}
	func:TextBox( cmdData.netuser, content, cmdData.cmd, cmdData.args )
end

function PLUGIN:GetUserDataFromTable( netuser )
	local netuserID = rust.GetUserID( netuser )
	if self[ netuserID ] then
		local data = self[ netuserID ]
		if data then return data end
	end
	local data = self:Load( netuser )
	if data then return data end
	return false
end

function PLUGIN:GetUserData( netuser )

	local netuserID = tostring(rust.GetUserID( netuser ) )
	local data = self:Load( netuserID )

	if (not data ) then -- if not, creates one
		data = {}
		data.id = netuserID
		data.name = netuser.displayName
		data.prevnames = {}
		data.reg = false
		data.swear = 0
		data.sweartbl = {}
		data.channel = 'local'
		data.lang = 'english'
		data.lvl = 1
		data.xp = 0
		data.pp = 0
		data.dp = 0
		data.ap = 0
		data.dmg = 1
		data.ut = 0 --the amount of times this user has untrained his/her attributes.
		data.attributes = {['str']=0,['sta']=0,['agi']=0,['int']=0,['cha']=0,['wis']=0,['wil']=0,['per']=0,['luc']=0 }
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
			['Toolsmith']={['lvl']=1,['xp']=0,['maxlvl']=70}
		}
		self[netuserID] = data
		self:Save( netuser )
		return data
	end
	self[netuserID] = data
	return data
end

-- DATA UPDATE AND SAVE
function PLUGIN:Save( netuser )
	local netuserID = rust.GetUserID( netuser )
	if self[ netuserID ].reg then
		self.SaveCharFile = util.GetDatafile( tostring( netuserID ) )
		self.SaveCharFile:SetText( json.encode( self[ tostring(netuserID) ], { indent = true } ) )
		self.SaveCharFile:Save()
		if netuser then
			timer.Once( 5, function() rust.InventoryNotice( netuser, 'Saving complete...' ) end)
		end
	else
		if netuser then
			timer.Once( 5, function() rust.InventoryNotice( netuser, 'Saving failed...' ) end)
		end
	end
end

-- DATA UPDATE AND SAVE
function PLUGIN:Load( netuserID )
	rust.BroadcastChat( 'Loading datafile' )
	self.CharFile = util.GetDatafile( tostring( netuserID ) )
	local txt = self.CharFile:GetText()
	if txt ~= "" then
		local data = json.decode( txt )
		return data
	end
	return false
end
