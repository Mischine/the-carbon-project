PLUGIN.Title = 'carbon_core'
PLUGIN.Description = 'combat module'
PLUGIN.Version = '0.0.11'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end

function PLUGIN:OnProcessDamageEvent( takedamage, dmg )
    --[[
    if dmg.attacker.client.netUser then
        if weaponData then
            local weaponData = core.Config.weapon[tostring(dmg.extraData.dataBlock.name)] or nil
            local netuser = dmg.attacker.client.netUser
            local netuserData = char.User[rust.GetUserID(netuser)]
            if weaponData.lvl > netuserData.lvl then
                dmg.amount = 0
                if not spam[weaponData.name .. netuserData.id] then
                    func:Notice(netuser,'⊗','You are not proficient with this weapon!',5)
                    spam[weaponData.name .. netuserData.id] = weaponData.name .. netuserData.id
                end
                timer.Once(6, function() spam[weaponData.name .. netuserData.id] = nil end)
                return dmg
            end
        end
    end
    --]]
end
--[[
function PLUGIN:OnProcessDamageEvent( takedamage, dmg )
    rust.BroadcastChat('OnProcessDamageEvent')

    if dmg.extraData then
        weaponData = core.Config.weapon[tostring(dmg.extraData.dataBlock.name)]
        rust.BroadcastChat(weaponData.name)
    end
    return dmg

    if dmg.attacker.client then
        local isSamePlayer = (dmg.victim.client == dmg.attacker.client)
        if not isSamePlayer then
            if char:GetUserData(dmg.attacker.client.netUser) then
                local netuser = dmg.attacker.client.netUser
                local netuserData = char.User[rust.GetUserID(netuser)]
                if weaponData.lvl > netuserData.lvl then
                    local netuser = dmg.attacker.client.netUser
                    local netuserData = char.User[rust.GetUserID(netuser)]
                    dmg.status = LifeStatus.IsAlive
                    dmg.amount = 0
                    if not spamNet[weaponData.name .. netuser.displayName] then
                        func:Notice(netuser,'⊗','You are not proficient with this weapon!',5)
                        spamNet[weaponData.name .. netuser.displayName] = true
                        timer.Once(6, function() spamNet[weaponData.name .. netuser.displayName] = nil end)
                    end
                end
            end
        end
    end

end
--]]

function PLUGIN:ModifyDamage (takedamage, dmg)
    --CLIENT VS CLIENT

    if dmg.victim.controllable then
        if dmg.attacker.controllable and dmg.victim.controllable then
            if dmg.attacker.controllable ~= dmg.victim.controllable then
                if dmg.extraData then
                    rust.BroadcastChat('attacking player.. .')
                    local weaponData = core.Config.weapon[tostring(dmg.extraData.dataBlock.name)]
                    local netuser = dmg.attacker.client.netUser
                    local netuserData = char.User[rust.GetUserID(netuser)]
                    local vicuser = dmg.victim.client.netUser
                    local vicuserData = char.User[rust.GetUserID(vicuser)]
                    if weaponData and not netuserData.skills[weaponData.name] then
                        netuserData.skills[weaponData.name] = {['name']=weaponData.name,['xp']=0,['lvl']=0}
                        char:UserSave()
                    end
                end
            else
                rust.BroadcastChat('suicide.. .')
                --SUICIDE
            end

        elseif dmg.victim.controllable and not dmg.attacker.controllable then
            rust.BroadcastChat('npc attacking.. .')
        end
    elseif dmg.attacker.controllable and not dmg.victim.controllable then
        if dmg.extraData then
            local weaponData = core.Config.weapon[tostring(dmg.extraData.dataBlock.name)]
            local v = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI' }
            for _,v in pairs(v) do
                if (takedamage:GetComponent(v)) then
                    rust.BroadcastChat('attacking ' .. v .. '.. .')
                end
            end
        end
    end
    return dmg
end
            --[[
                    if debugr == true then rust.BroadcastChat('---------------BEGIN ME VS PVP---------------') end
                    -- STEP 1 VIC MODIFIER
                    if vicuserData.dmg ~= 1 then dmg.amount = dmg.amount*vicuserData.dmg if debugr == true then rust.BroadcastChat('vicuser dmg modifier: ' .. tostring(dmg.amount)) end end
                    -- STEP 2 WPN DMG MODIFIER
                    if weaponData then dmg.amount = dmg.amount*weaponData.dmg     if debugr == true then rust.BroadcastChat('WEAPON DMG MODIFIER: ' .. tostring(dmg.amount)) end end


                    -- STEP 3 DAMAGE ROLL
                    dmg.amount = math.random(dmg.amount*0.5,tonumber(dmg.amount))   if debugr == true then rust.BroadcastChat('RANDOM DAMAGE: ' .. tostring(dmg.amount)) end
                    -- STEP 4 DP MODIFIER
                    dmg.amount = self:modifyDP(netuserData, dmg.amount)
                    -- STEP 5 WPN MODIFIER
                    dmg.amount = dmg.amount+netuserData.skills[weaponData.name].lvl*.3   if debugr == true then rust.BroadcastChat('WEAPON SKILL BONUS: ' .. tostring(netuserData.skills[weaponData.name].lvl*.3)) end

                    --STEP 6 ATR MODIFIER
                    dmg.amount = self:attrModify(weaponData, netuserData, vicuserData, dmg.amount)  if debugr == true then rust.BroadcastChat('ATTRIBUTE DMG MODIFIER: ' .. tostring(dmg.amount)) end
                    --STEP 7 CRIT CHECK
                    dmg.amount = self:critCheck(weaponData, netuser, netuserData, dmg.amount)    if debugr == true then rust.BroadcastChat('CRIT CHANCE: ' .. tostring(dmg.amount)) end
                    --STEP 8 VIC STA MOD
                    dmg.amount = self:staModify(netuserData, vicuserData, nil, dmg.amount)
                    --STEP 9 PERK STONE
                    dmg.amount = perk:Stoneskin(netuser, netuserData, vicuser, vicuserData, dmg.amount)
                    -- STEP 10 PERK PARRY
                    dmg.amount = perk:Parry(vicuser, vicuserData, dmg.amount)

                    --GUILD: MODIFIERS
                    local guild = guild:getGuild( netuser )
                    local vicguild = guild:getGuild( vicuser )
                    if debugr == true then rust.BroadcastChat( 'GUILDS: ' .. netuser.displayName .. ' : ' .. tostring( guild ) .. ' || ' .. vicuser.displayName .. ' : ' .. tostring( vicguild )  ) end
                    if ( guild ) and (vicguild ) then
                        if( guild == vicguild ) then
                            rust.Notice( netuser, vicuser.displayName .. ' is in your guild!'  )
                        else
                            local isRival = guild:isRival( guild, vicguild )
                            if( isRival ) then
                                if debugr == true then rust.BroadcastChat( tostring( guild ) .. ' and ' .. tostring( vicguild ) .. ' are rivals!' ) end
                                --Att Rally! bonus damage
                                local dmgmod = call:HasRallyCall( guild )
                                if( dmgmod ) then
                                    if debugr == true then rust.BroadcastChat('Before Rally Bonus Damage : ' .. tostring(dmg.amount) .. ' || After: ' .. tostring( dmg.amount * dmgmod )) end
                                    dmg.amount = dmg.amount * dmgmod
                                end
                                --Vic Stand Your Ground defense bonus
                                local ddmgmod = call:hasSYGCall( vicguild )
                                if( ddmgmod ) then
                                    if debugr == true then rust.BroadcastChat('Before SYG Damage : ' .. tostring(dmg.amount) .. ' || After: ' .. tostring( dmg.amount * ddmgmod )) end
                                    dmg.amount = dmg.amount * ddmgmod
                                end
                            end
                            --Vic Stand Your Ground defense bonus
                            local ddmgmod = call:hasSYGCall( vicguild )
                            if( ddmgmod ) then
                                if debugr == true then rust.BroadcastChat('Before SYG Damage : ' .. tostring(dmg.amount) .. ' || After: ' .. tostring( dmg.amount * ddmgmod )) end
                                dmg.amount = dmg.amount * ddmgmod
                            end
                        end
                    end


            end
            if(isSamePlayer and core.Config.suicide) then
                --SUICIDE ACTION HERE
                return dmg
            end
            ----------------------PVE VS CLIENT
        elseif ((dmg.victim.client) and (not dmg.attacker.client)) then
            if not dmg.damageTypes then return dmg end
            if (char:GetUserData(dmg.victim.client.netUser)) then
                local vicuser = dmg.victim.client.netUser
                local vicuserData = char.User[rust.GetUserID(vicuser)]
                local npcData = core.Config.npc[string.gsub(tostring(dmg.attacker.networkView.name), '%(Clone%)', '')]

                if debugr == true then rust.BroadcastChat('---------------BEGIN PVE VS ME---------------') end
                --STEP 1 VIC MODIFIER
                if vicuserData.dmg ~= 1 then dmg.amount = dmg.amount*vicuserData.dmg if debugr == true then rust.BroadcastChat('vicuser dmg modifier: ' .. tostring(dmg.amount)) end end
                -- STEP 2 WPN DMG MODIFIER
                if weaponData then dmg.amount = dmg.amount*weaponData.dmg     if debugr == true then rust.BroadcastChat('WEAPON DMG MODIFIER: ' .. tostring(dmg.amount)) end end
                --STEP 3 DAMAGE ROLL
                dmg.amount = math.random(dmg.amount*0.5,tonumber(dmg.amount))   if debugr == true then rust.BroadcastChat('RANDOM DAMAGE: ' .. tostring(dmg.amount)) end
                --STEP 4 DP MODIFIER
                --dmg.amount = self:modifyDP(netuserData, dmg.amount) NEEDS WORK FOR DEFENSE CHANGES
                -- STEP 5 WPN SKILL MODIFIER
                --dmg.amount = dmg.amount+netuserData.skills[weaponData.name].lvl*.3   if debugr == true then rust.BroadcastChat('WEAPON SKILL BONUS: ' .. tostring(netuserData.skills[weaponData.name].lvl*.3)) end
                -- STEP 6 ATR MODIFIER
                --dmg.amount = self:attrModify(weaponData, npcData, vicuserData, dmg.amount)  if debugr == true then rust.BroadcastChat('ATTRIBUTE DMG MODIFIER: ' .. tostring(dmg.amount)) end
                -- STEP 7 CRIT CHECK
                dmg.amount = self:critCheck(weaponData, npcData, vicuserData, dmg.amount)    if debugr == true then rust.BroadcastChat('CRIT CHANCE: ' .. tostring(dmg.amount)) end
                -- STEP 8 VIC STA MOD
                --dmg.amount = self:staModify(nil, vicuserData, nil, dmg.amount)if debugr == true then rust.BroadcastChat('STAMINA MODIFIER:' .. tostring(dmg.amount)) end
                --STEP 9 PERK STONE
                dmg.amount = perk:Stoneskin(netuser, netuserData, vicuser, vicuserData, dmg.amount) if debugr == true then rust.BroadcastChat('STONESKIN PERK: ' .. tostring(dmg.amount)) end
                --STEP 10 PERK PARRY
                dmg.amount = perk:Parry(vicuser, vicuserData, dmg.amount) if debugr == true then rust.BroadcastChat('PARRY PERK: ' .. tostring(dmg.amount)) end

                --GUILD: MODIFIERS
                local guild = guild:getGuild( vicuser )
                if debugr == true then rust.BroadcastChat('Guild found: ' .. tostring( guild )  ) end
                if ( guild ) then
                    local cotw = calls:hasCOTWCall( guild )
                    if( cotw ) then
                        if debugr == true then rust.BroadcastChat('COTW Perk dmg from: ' .. dmg.amount .. ' to: ' .. dmg.amount * cotw .. ' || cotwmod: ' .. cotw ) end
                        dmg.amount = dmg.amount * cotw
                    end
                end


                return dmg
            end
        end
    end
    ----------------------------CLIENT VS PVE
    local npcController = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI' }
    for i, npcController in ipairs(npcController) do
        if (takedamage:GetComponent( npcController )) then
            local netuser = dmg.attacker.client.netUser
            local netuserData = char.User[rust.GetUserID(netuser)]
            local npcData = core.Config.npc[string.gsub(tostring(dmg.victim.networkView.name), '%(Clone%)', '')]

            if (not netuserData.skills[tostring(dmg.extraData.dataBlock.name)]) then
                netuserData.skills[weaponData.name] = {['name']=tostring(weaponData.name),['xp']=0,['lvl']=0 }
                char:UserSave()
            end

            if debugr == true then rust.BroadcastChat('---------------BEGIN ME VS PVE---------------') end
            -- STEP 1 VIC MODIFIER
            dmg.amount = dmg.amount*npcData.dmg     if debugr == true then rust.BroadcastChat('VICUSER DMG MODIFIER: ' .. tostring(dmg.amount)) end
            -- STEP 2 WPN DMG MODIFIER
            if weaponData then dmg.amount = dmg.amount*weaponData.dmg     if debugr == true then rust.BroadcastChat('WEAPON DMG MODIFIER: ' .. tostring(dmg.amount)) end end
            --STEP 3 DAMAGE ROLL
            dmg.amount = math.random(dmg.amount*0.5,tonumber(dmg.amount))   if debugr == true then rust.BroadcastChat('RANDOM DAMAGE: ' .. tostring(dmg.amount)) end
            --STEP 4 DP MODIFIER
            dmg.amount = self:modifyDP(netuserData, dmg.amount)
            --STEP 5 WPN SKILL MODIFIER
            dmg.amount = dmg.amount+netuserData.skills[ weaponData.name ].lvl*0.3      if debugr == true then rust.BroadcastChat('WEAPON SKILL BONUS: ' .. tostring(netuserData.skills[weaponData.name].lvl*.3)) end
            -- STEP 6 ATR MODIFIER
            dmg.amount = self:attrModify(weaponData, netuserData, npcData, dmg.amount)      if debugr == true then rust.BroadcastChat('ATTRIBUTE DMG MODIFIER: ' .. tostring(dmg.amount)) end
            -- STEP 7 CRIT CHECK
            dmg.amount = self:critCheck(weaponData, netuser, netuserData, dmg.amount)       if debugr == true then rust.BroadcastChat('CRIT CHANCE: ' .. tostring(dmg.amount)) end
            --STEP 8 VIC STA MOD
            dmg.amount = self:staModify(netuserData, nil, npcData, dmg.amount)    if debugr == true then rust.BroadcastChat('STAMINA MODIFIER:' .. tostring(dmg.amount)) end

            --GUILD STUFF
            local guild = guild:getGuild( netuser )
            if debugr == true then rust.BroadcastChat('Guild found: ' .. tostring( guild )  ) end
            if ( guild ) then
                local cotw = calls:hasCOTWCall( guild )
                if( cotw ) then
                    if debugr == true then rust.BroadcastChat('COTW Perk dmg from: ' .. dmg.amount .. ' to: ' .. dmg.amount * cotw .. ' || cotwmod: ' .. cotw ) end
                    dmg.amount = dmg.amount * cotw
                end
            end

            return dmg
        end
    end
    -----------------------CLIENT VS SLEEPER
    if (string.find(tostring(takedamage.gameObject.Name), 'MaleSleeper(',1 ,true) and (dmg.attacker.client) and (dmg.attacker.client.netUser) and core.Config.settings.sleeperdppercent > 0) then
        if(sleepreId ~= nil) then
            --SLEEPER ACTION HERE
            return dmg
        end
    end
end

-- PLUGIN:OnKilled | http://wiki.rustoxide.com/index.php?title=Hooks/OnKilled
function PLUGIN:OnKilled (takedamage, dmg)
    -----------------CLIENT VS CLIENT
    if (takedamage:GetComponent( 'HumanController' )) then
        local vicuser = dmg.victim.client.netUser
        local vicuserData = char.User[rust.GetUserID(vicuser)]
        if(dmg.victim.client and dmg.attacker.client) then
            local netuser = dmg.attacker.client.netUser
            local netuserData = char.User[rust.GetUserID(netuser)]
            if (netuser ~= vicuser) then
                netuserData.stats.kills.pvp = netuserData.stats.kills.pvp+1
                char:GiveDp( vicuser, vicuserData, math.floor(vicuserData.xp*core.Config.settings.dppercent/100))
            elseif(netuser == vicuser) then
                char:GiveDp( netuser, vicuserData, math.floor(netuserData.xp*core.Config.settings.dppercent/100))
            end
            return
            -----------------PVE VS CLIENT
        elseif ((dmg.victim.client) and (not dmg.attacker.client)) then
            char:GiveDp( vicuser, vicuserData, math.floor(vicuserData.xp*core.Config.settings.dppercent/100))
        end
    end
    -------------------CLIENT VS PVE
    local npcController = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI'}
    for i, npcController in ipairs(npcController) do
        if (takedamage:GetComponent( npcController )) then
            local npcData = core.Config.npc[string.gsub(tostring(dmg.victim.networkView.name), '%(Clone%)', '')]
            local netuser = dmg.attacker.client.netUser
            local netuserData = char.User[rust.GetUserID(netuser)]
            local xp = math.floor(npcData.xp*core.Config.settings.xpmodifier)
            if (not netuserData.stats.kills.pve[npcData.name]) then
                netuserData.stats.kills.pve[npcData.name] = 1
            else
                netuserData.stats.kills.pve[npcData.name] = netuserData.stats.kills.pve[npcData.name]+1
            end
            netuserData.stats.kills.pve.total = netuserData.stats.kills.pve.total+1
            char.GiveXp( weaponData, netuser, netuserData, xp)
            return end --break out of all loops after finding controller type
    end
    -------------------CLIENT VS SLEEPER

	if (string.find(takedamage.gameObject.Name, 'MaleSleeper(',1 ,true) and (dmg.attacker.client) and (dmg.attacker.client.netUser) and core.Config.settings.sleeperdppercent > 0) then
		local actorUser = dmg.attacker.client.netUser
		local coord = actorUser.playerClient.lastKnownPosition
		local sleepreId = self:SleeperPos(coord)
        if(sleepreId ~= nil) then
            core.Config.sleepers.pos[sleepreId] = nil
            char.GiveXp( actorUser, tonumber(math.floor(char.User[sleepreId].xp*core.Config.settings.sleeperxppercent/100)))
            self:setXpPercentById(sleepreId, tonumber(100-core.Config.settings.sleeperxppercent-core.Config.settings.dppercent))
        end
	end
    return
end

--PLUGIN:staModify
function PLUGIN:staModify(netuserData, vicuserData, npcData, damage)
    if (vicuserData) then
        if (vicuserData.attributes.sta>0) then
            damage = damage-((vicuserData.attributes.sta+vicuserData.lvl)*0.1)
            if debugr == true then rust.BroadcastChat('PLUGIN:staModify (vicuser) :' .. tostring(dmg.amount)) end
        end
    end
    if (npcData) then
        if (npcData.attributes.sta>0) then
            damage = damage-((npcData.attributes.sta+math.random(netuserData.lvl-1,netuserData.lvl+1))*0.1)
            if debugr == true then rust.BroadcastChat('PLUGINS:staModify (npc):' .. tostring(damage)) end
        end
    end
    return damage
end

--PLUGIN:modifyDP
function PLUGIN:modifyDP(netuserData, damage)
    if (netuserData.dp > 0) then
        local dppercentage = netuserData.dp/netuserData.xp
        local dmgdp = damage*dppercentage
        damage = math.ceil(tonumber(damage-dmgdp))
        if debugr == true then rust.BroadcastChat('PLUGIN:modifyDP: ' .. tostring(damage)) end
    end
    return damage
end

--PLUGIN:attrModify
function PLUGIN:attrModify(weaponData, netuserData, vicuserData, damage)
    if weaponData then
        if (weaponData.type == 'm') and (netuserData.attributes.str>0) then
            damage = damage + ((netuserData.attributes.str+netuserData.lvl)*.3)
            if debugr == true then rust.BroadcastChat('PLUGIN:attrModify (str) :' .. tostring(damage)) end
        elseif (weaponData.type == 'l' or weaponData.type == 'c') and (netuserData.attributes.agi>0) then
            damage = damage + ((netuserData.attributes.agi+netuserData.lvl)*.3)
            if debugr == true then rust.BroadcastChat('PLUGIN:attrModify (agi) :' .. tostring(damage)) end
        end
    end
    if not weaponData then
        if (netuserData.str>0) then
            damage = damage + ((netuserData.str+(math.random(vicuserData.lvl-1,vicuserData.lvl+1)))*.3)
            if debugr == true then rust.BroadcastChat('PLUGIN:attrModify (no weaponData) :' .. tostring(damage)) end
        end
    end
    return damage
end


--PLUGIN:critCheck
function PLUGIN:critCheck(weaponData, netuser, netuserData, damage)

    if( char.User[ netuserData.id ].buffs[ 'ParryCrit' ]) then
        damage = damage * 2
        char.User[ netuserData.id ].buffs[ 'ParryCrit' ] = nil
        return damage
    end
    if (netuserData.attributes.agi>0) then
        local roll = core.rnd
        if (weaponData.type == 'm') then
            if ((netuserData.attributes.agi+netuserData.lvl)*.002 >= roll) then
                damage = damage * 2
                rust.InventoryNotice( netuser, 'Critical Hit!' )
                if debugr == true then rust.BroadcastChat('PLUGIN:critCheck (m): ' .. tostring(damage)) end
            end
        elseif (weaponData.type == 'l' or weaponData.type == 'c') then
            if ((netuserData.attributes.agi+netuserData.lvl)*.001 >= roll) then
                damage = damage * 2
                rust.InventoryNotice( netuser, 'Critical Hit!' )
                if debugr == true then rust.BroadcastChat('PLUGIN:critCheck (l/c)' .. tostring(damage)) end
            end
        end
    end
    return damage
end
            --]]