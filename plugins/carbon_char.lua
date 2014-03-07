PLUGIN.Title = 'carbon_char'
PLUGIN.Description = 'character module'
PLUGIN.Version = '0.0.2'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
    --LOAD/CREATE CHAR FILE
    self.UserFile = util.GetDatafile( 'carbon_char' )
    local dat_txt = self.UserFile:GetText()
    if (dat_txt ~= '') then
        print( 'Carbon dat file loaded!' )
        self.User = json.decode( dat_txt )
    else
        print( 'Creating carbon dat file...' )
        self.User = {}
        self:UserSave()
    end

    self:AddChatCommand( 'c', self.cmdCarbon )
end
function PLUGIN:Character(cmdData)
    local a = cmdData.netuserData.lvl+1 --level +1
    local ab = cmdData.netuserData.lvl --level
    local b = core.Config.settings.lvlmodifier
    local c = ((a*a)+a)/b*100-(a*100) --xp required for next level
    local d = math.floor(((cmdData.netuserData.xp/c)*100)+0.5) -- percent currently to next level.
    local e = c-cmdData.netuserData.xp -- left to go until level
    local f = ((ab*ab)+ab)/b*100-(ab*100) -- amount needed for current level
    local g = math.floor(((cmdData.netuserData.dp/(f*.5))*100)+0.5) -- percentage of dp
    local h = (f*.5) -- total possible dp
    if (a == 2) and (core.Config.settings.lvlmodifier >= 2) then f = 0 end
    local content = {
        ['list']={
	        cmdData.txt.level .. ':                          ' .. tostring(ab),
            ' ',
	        cmdData.txt.experience .. ':              (' .. tostring(cmdData.netuserData.xp) .. '/' .. tostring(c) .. ')   [' .. tostring(d) .. '%]   ' .. '(' .. tostring(e) .. ')',
            tostring(func:xpbar( d, 32 )),
            ' ',
	        cmdData.txt.deathpenalty .. ':         (' .. tostring(cmdData.netuserData.dp) .. '/' .. tostring(h) .. ')   [' .. tostring(g) .. '%]',
            tostring(func:xpbar( g, 32 )),
        },
	    ['cmds']=cmdData.txt['cmds_c'],
    }
    func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end
function PLUGIN:CharacterSkills(cmdData)

	local skillData = cmdData.netuserData.skills[ cmdData.args[2] ]
	if skillData then
		local a = skillData.lvl+1 --level +1
		local b = core.Config.settings.weaponlvlmodifier --level modifier
		local c = ((a*a)+a)/b*100-(a*100) --xp required for next level
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
    ['list']={
        cmdData.txt.strength .. ':     ' .. cmdData.netuserData.attributes.str,
            func:xpbar(cmdData.netuserData.attributes.str*10,10),
	    cmdData.txt.agility .. ':      ' .. cmdData.netuserData.attributes.agi,
            func:xpbar(cmdData.netuserData.attributes.agi*10,10),
	    cmdData.txt.stamina .. ':      ' .. cmdData.netuserData.attributes.sta,
            func:xpbar(cmdData.netuserData.attributes.sta*10,10),
	    cmdData.txt.intellect .. ':    ' .. cmdData.netuserData.attributes.int,
            func:xpbar(cmdData.netuserData.attributes.int*10,10),
        },
            ['cmds']=cmdData.txt['cmds_c_attr'],
        }
    func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end
function PLUGIN:CharacterAttributesTrain(cmdData)
	cmdData.args[3] = tonumber(cmdData.args[3])
	if cmdData.args[3] >= 1 and (cmdData.args[4] == 'str' or cmdData.args[4] == 'agi' or cmdData.args[4] == 'sta' or cmdData.args[4] == 'int')then
		if cmdData.netuserData.ap >= cmdData.args[3] then
			if cmdData.netuserData.attributes[ cmdData.args[4] ]+tonumber(args[3])<=10 then
				cmdData.netuserData.ap=cmdData.netuserData.ap-cmdData.args[3]
				cmdData.netuserData.attributes[ cmdData.args[4] ]=cmdData.netuserData.attributes[ cmdData.args[4] ]+tonumber(cmdData.args[3])
				rust.InventoryNotice(netuser, '+' .. tostring(cmdData.args[3]) .. cmdData.args[4])
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
		['list']={
			cmdData.txt.strength .. ':     ' .. cmdData.netuserData.attributes.str,
			func:xpbar(cmdData.netuserData.attributes.str*10,10),
			cmdData.txt.agility .. ':      ' .. cmdData.netuserData.attributes.agi,
			func:xpbar(cmdData.netuserData.attributes.agi*10,10),
			cmdData.txt.stamina .. ':      ' .. cmdData.netuserData.attributes.sta,
			func:xpbar(cmdData.netuserData.attributes.sta*10,10),
			cmdData.txt.intellect .. ':    ' .. cmdData.netuserData.attributes.int,
			func:xpbar(cmdData.netuserData.attributes.int*10,10),
		},
		['cmds']={cmdData.txt.cmds}
	}
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end
function PLUGIN:CharacterPerksAdd(cmdData)
	local content = {
		['list']={
			cmdData.txt.strength .. ':     ' .. cmdData.netuserData.attributes.str,
			func:xpbar(cmdData.netuserData.attributes.str*10,10),
			cmdData.txt.agility .. ':      ' .. cmdData.netuserData.attributes.agi,
			func:xpbar(cmdData.netuserData.attributes.agi*10,10),
			cmdData.txt.stamina .. ':      ' .. cmdData.netuserData.attributes.sta,
			func:xpbar(cmdData.netuserData.attributes.sta*10,10),
			cmdData.txt.intellect .. ':    ' .. cmdData.netuserData.attributes.int,
			func:xpbar(cmdData.netuserData.attributes.int*10,10),
		},
		['cmds']={cmdData.txt.cmds}
	}
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end
function PLUGIN:CharacterClass(cmdData)
	local content = {
		['list']={
			cmdData.txt.strength .. ':     ' .. cmdData.netuserData.attributes.str,
			func:xpbar(cmdData.netuserData.attributes.str*10,10),
			cmdData.txt.agility .. ':      ' .. cmdData.netuserData.attributes.agi,
			func:xpbar(cmdData.netuserData.attributes.agi*10,10),
			cmdData.txt.stamina .. ':      ' .. cmdData.netuserData.attributes.sta,
			func:xpbar(cmdData.netuserData.attributes.sta*10,10),
			cmdData.txt.intellect .. ':    ' .. cmdData.netuserData.attributes.int,
			func:xpbar(cmdData.netuserData.attributes.int*10,10),
		},
		['cmds']={cmdData.txt.cmds}
	}
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end
function PLUGIN:CharacterClassSelect(cmdData)
	local content = {
		['list']={
			cmdData.txt.strength .. ':     ' .. cmdData.netuserData.attributes.str,
			func:xpbar(cmdData.netuserData.attributes.str*10,10),
			cmdData.txt.agility .. ':      ' .. cmdData.netuserData.attributes.agi,
			func:xpbar(cmdData.netuserData.attributes.agi*10,10),
			cmdData.txt.stamina .. ':      ' .. cmdData.netuserData.attributes.sta,
			func:xpbar(cmdData.netuserData.attributes.sta*10,10),
			cmdData.txt.intellect .. ':    ' .. cmdData.netuserData.attributes.int,
			func:xpbar(cmdData.netuserData.attributes.int*10,10),
		},
		['cmds']={cmdData.txt.cmds}
	}
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end
function PLUGIN:CharacterReset(cmdData)
	local content = {
		['list']={
			cmdData.txt.strength .. ':     ' .. cmdData.netuserData.attributes.str,
			func:xpbar(cmdData.netuserData.attributes.str*10,10),
			cmdData.txt.agility .. ':      ' .. cmdData.netuserData.attributes.agi,
			func:xpbar(cmdData.netuserData.attributes.agi*10,10),
			cmdData.txt.stamina .. ':      ' .. cmdData.netuserData.attributes.sta,
			func:xpbar(cmdData.netuserData.attributes.sta*10,10),
			cmdData.txt.intellect .. ':    ' .. cmdData.netuserData.attributes.int,
			func:xpbar(cmdData.netuserData.attributes.int*10,10),
		},
		['cmds']={cmdData.txt.cmds}
	}
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end
function PLUGIN:CharacterResetPerks(cmdData)
	local content = {
		['list']={
			cmdData.txt.strength .. ':     ' .. cmdData.netuserData.attributes.str,
			func:xpbar(cmdData.netuserData.attributes.str*10,10),
			cmdData.txt.agility .. ':      ' .. cmdData.netuserData.attributes.agi,
			func:xpbar(cmdData.netuserData.attributes.agi*10,10),
			cmdData.txt.stamina .. ':      ' .. cmdData.netuserData.attributes.sta,
			func:xpbar(cmdData.netuserData.attributes.sta*10,10),
			cmdData.txt.intellect .. ':    ' .. cmdData.netuserData.attributes.int,
			func:xpbar(cmdData.netuserData.attributes.int*10,10),
		},
		['cmds']={cmdData.txt.cmds}
	}
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end
function PLUGIN:CharacterResetAttributes(cmdData)
	local content = {
		['list']={
			cmdData.txt.strength .. ':     ' .. cmdData.netuserData.attributes.str,
			func:xpbar(cmdData.netuserData.attributes.str*10,10),
			cmdData.txt.agility .. ':      ' .. cmdData.netuserData.attributes.agi,
			func:xpbar(cmdData.netuserData.attributes.agi*10,10),
			cmdData.txt.stamina .. ':      ' .. cmdData.netuserData.attributes.sta,
			func:xpbar(cmdData.netuserData.attributes.sta*10,10),
			cmdData.txt.intellect .. ':    ' .. cmdData.netuserData.attributes.int,
			func:xpbar(cmdData.netuserData.attributes.int*10,10),
		},
		['cmds']={cmdData.txt.cmds}
	}
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end
function PLUGIN:CharacterResetClass(cmdData)
	local content = {
		['list']={
			cmdData.txt.strength .. ':     ' .. cmdData.netuserData.attributes.str,
			func:xpbar(cmdData.netuserData.attributes.str*10,10),
			cmdData.txt.agility .. ':      ' .. cmdData.netuserData.attributes.agi,
			func:xpbar(cmdData.netuserData.attributes.agi*10,10),
			cmdData.txt.stamina .. ':      ' .. cmdData.netuserData.attributes.sta,
			func:xpbar(cmdData.netuserData.attributes.sta*10,10),
			cmdData.txt.intellect .. ':    ' .. cmdData.netuserData.attributes.int,
			func:xpbar(cmdData.netuserData.attributes.int*10,10),
		},
		['cmds']={cmdData.txt.cmds}
	}
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end

--[[
-- CARBON CHAT COMMANDS
function PLUGIN:cmdCarbon(netuser,cmd,args)
    local netuserID = rust.GetUserID( netuser )
    local netuserData = self.User[netuserID]
    for k,v in ipairs(args)do args[k]=tostring(args[k]) end

    if(#args==0)then
        local content = {
            ['msg'] = 'Character chat commands are activated with' ..
                    ' /c. At the top of each informational screen you' ..
                    ' will see a pseudo breadcrumb trail intended to ' ..
                    'help you with cmd navigation by displaying parent' ..
                    'commands.\n \ni.e.  c > ...\n \nThe bar below ' ..
                    'contains child commands for further navigation.\n \ne.g.  /c xp',
            ['cmds']={'xp','atr','skills','perks','help'}
        }

        func:TextBox(netuser, content, cmd, args) return
    end

        elseif args[1]=='atr' then
            local content = {
                ['list']={
                    'Strength:     ' .. netuserData.attributes.str,
                    func:xpbar(netuserData.attributes.str*10,10),
                    'Agility:      ' .. netuserData.attributes.agi,
                    func:xpbar(netuserData.attributes.agi*10,10),
                    'Stamina:      ' .. netuserData.attributes.sta,
                    func:xpbar(netuserData.attributes.sta*10,10),
                    'Intellect:    ' .. netuserData.attributes.int,
                    func:xpbar(netuserData.attributes.int*10,10),
                },
                ['cmds']={'train','untrain'}
            }
            func:TextBox(netuser, content, cmd, args) return
        elseif args[1] == 'skills' then
            local content = {
                --['prefix']='This is any prefix you would like to enter.',
                --['breadcrumbs']=args,
                --['header']='Header',
                --['subheader']='Subheader',
                --['msg']={},
                ['list']={},
                ['cmds']={'"skill name"'},
                --['suffix']='this is the suffix',
            }
            for k,v in pairs(netuserData.skills) do
                local a = v.lvl+1 --level +1
                local b = core.Config.settings.weaponlvlmodifier --level modifier
                local c = ((a*a)+a)/b*100-(a*100) --xp required for next level
                local d = math.floor(((v.xp/c)*100)+0.5) -- percent currently to next level.
                table.insert( content.list, tostring('   ' .. v.name .. '    •    Level: ' .. v.lvl .. '    •    ' .. 'Exp: ' .. v.xp ))
                table.insert( content.list, tostring(func:xpbar( d, 32 )))
            end
            func:TextBox(netuser, content, cmd, args) return
        elseif (args[1] == 'perks') then
            local msg = {'perks info here'}
            func:TextBox(netuser, 'perks', msg, '•  list  •  active  •') return
        else
            local content={['cmds']={'xp','atr','skills','perks'}}
            func:TextBoxError(netuser, content, cmd, args) return
            --self:cmdError(netuser, ' ', '•  xp  •  atr  •  skills  •  perks  •  help  •') return
        end
    end
    if #args==2 then
        if args[1] == 'atr'then
            if args[2] == 'train' then
                local content = {
                    ['msg']='To level up your attributes you must train using available attribute points (ap). WARNING: to untrain you will be required to pay a trainer. The cost will increase the more you times you untrain.\n \nAvailable AP:  ' .. netuserData.ap,

                    ['cmds']={'str #','agi #','sta #','int #'},
                }
                func:TextBox(netuser, content, cmd, args) return
            elseif args[2] == 'untrain' then
                local content = {
                    ['msg']='To untrain your attribute points you will have to pay a trainer. WARNING: each time you untrain the cost will increase.\n \nIf you are sure you want to untrain use the pay command.\n \ni.e. /c atr untrain pay\n \nCost: ' .. tonumber(core.Config.settings.untraincost*(1+core.Config.settings.untraincostgrowth)^netuserData.ut),
                    ['cmds']={'pay'},
                }
            else
                local content = {['cmds']={'train','untrain'}}
                func:TextBoxError(netuser, content, cmd, args) return
            end
        elseif args[1] == 'skills'then
            local skillData = netuserData.skills[ args[2] ]
            if skillData then
                local a = skillData.lvl+1 --level +1
                local b = core.Config.settings.weaponlvlmodifier --level modifier
                local c = ((a*a)+a)/b*100-(a*100) --xp required for next level
                local d = math.floor(((skillData.xp/c)*100)+0.5) -- percent currently to next level.
                local e = c-skillData.xp -- left to go until level
                local content = {
                    ['list'] = {'Skill:  ' .. skillData.name,'Level:  ' .. skillData.lvl,'Experience:  (' .. skillData.xp .. '/' .. c .. ')  [' .. d .. '%]  (' .. e .. ')', func:xpbar( d, 32 ) }
                }

                func:TextBox(netuser, content, cmd, args) return
            else
                local content = {['cmds']={'"skill name"'}}
                func:TextBoxError(netuser, content, cmd, args) return
            end
        else
            local content={
                ['cmds']={'xp', 'atr','skills','perks'}
            }
            func:TextBoxError(netuser, content, cmd, args) return
        end
    end
    if #args>=3 then
        if args[1] == 'atr' and args[2] == 'train' and tonumber(args[4]) >= 1 and (args[3] == 'str' or args[3] == 'agi' or args[3] == 'sta' or args[3] == 'int')then
            if netuserData.ap >= tonumber(args[4]) then
                if netuserData.attributes[ args[3] ]+tonumber(args[4])<=10 then
                    netuserData.ap=netuserData.ap-tonumber(args[4])
                    netuserData.attributes[ args[3] ]=netuserData.attributes[ args[3] ]+tonumber(args[4])
                    rust.InventoryNotice(netuser, '+' .. tostring(args[4]) .. args[3])
                else
                    local content = {
                        ['msg']='You can\'t train above 10!',
                        ['cmds']={'str #','agi #','sta #','int #'},
                    }
                    func:TextBoxError(netuser, content, cmd, args) return
                end
            else
                local content = {
                    ['msg'] = 'Insufficient attribute points!',
                    ['cmds']={'str #','agi #','sta #','int #'},
                }
            end

        elseif args[1] == 'atr' and args[2] == 'untrain' and args[3] == 'pay' then
            func:Notice(netuser, ' ', 'You have untrained all attributes!', 4)
            netuserData.attributes.str=0
            netuserData.attributes.agi=0
            netuserData.attributes.sta=0
            netuserData.attributes.int=0
            self:UserSave()
        else
            local content = {
                ['cmds']={'str #','agi #','sta #','int #'},
            }
            func:TextBoxError(netuser, content, cmd, args) return
        end
    end
end
--]]
function PLUGIN:GiveXp(combatData, xp)

    local guildname = guild:getGuild( combatData.netuser )
    rust.BroadcastChat( guildname )
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
    self:UserSave()
end


--PLUGIN:getLvl
function PLUGIN:getLvl( netuser )
    local netuserID = rust.GetUserID( netuser )
    local lvl = self.User[ netuserID ].lvl
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
    self:UserSave()
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
            self.User[netuserID].dp = math.floor(self.User[netuserID].dp + self.User[netuserID].xp)
        else
            self.User[netuserID].dp = math.floor(self.User[netuserID].dp + (self.User[netuserID].xp * percent / 100))
        end
        self:UserSave()
    end
end

-- PLUGIN:GetUserData
function PLUGIN:GetUserData( netuser )
    local netuserID = rust.GetUserID( netuser )
    local data = self.User[ netuserID ] -- checks if data exist
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
        self.User[ netuserID ] = data
        self:UserSave()
    end
    return data
end


-- DATA UPDATE AND SAVE
function PLUGIN:UserSave()
    print('Saving user data.')
    self.UserFile:SetText( json.encode( self.User, { indent = true } ) )
    self.UserFile:Save()
    self:UserUpdate()
    func.spamNet = {}
end
function PLUGIN:UserUpdate()
    self.UserFile = util.GetDatafile( 'carbon_char' )
    local txt = self.UserFile:GetText()
    self.User = json.decode ( txt )
end