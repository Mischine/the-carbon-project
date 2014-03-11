PLUGIN.Title = 'carbon_core'
PLUGIN.Description = 'combat module'
PLUGIN.Version = '0.0.2'
PLUGIN.Author = 'mischa / carex'

local LifeStatusType = cs.gettype( "LifeStatus, Assembly-CSharp" )
typesystem.LoadEnum(LifeStatusType, "LifeStatus" )

local _BodyParts = cs.gettype( "BodyParts, Facepunch.HitBox" )
local _GetNiceName = util.GetStaticMethod( _BodyParts, "GetNiceName" )

local damage_generic = 1
local damage_bullet = 2
local damage_melee = 4
local damage_explosion = 8
local damage_radiation = 16
local damage_cold = 32
local spamNet = {}

local IsAlive = tostring(LifeStatus.IsAlive)
local IsDead = tostring(LifeStatus.isDead)
local WasKilled = tostring(LifeStatus.WasKilled)
local Failed = tostring(LifeStatus.Failed)

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end


function PLUGIN:OnProcessDamageEvent( takedamage, damage )
	local combatData                                        -- Define combatData so that it wont turn global. I cant local it in the if statement, cus then I cannot use it outside of it.
	local dmg                                               -- Define dmg / We need to change this. Because I dont want to flood the server with people shooting dead NPC/Players.
	local status = tostring( damage.status )
	if ( status ~= IsDead ) then                            -- Prevent calculating even if they're dead. Less CPU usage. BETTAH PERFORMANCE!
        dmg, combatData = self:CombatDamage( takedamage, damage )
	end
	if ((combatData.bodyPart) and ( not combatData.npc )) then
	 	rust.BroadcastChat( combatData.bodyPart )
	end
	if dmg.amount <= 0 then                                 -- Checks if they're proficient with the weapon.
		dmg.status = LifeStatus.IsAlive
		rust.BroadcastChat( cancelagro )
	end
	if status == WasKilled then
		if dmg.amount < takedamage.health then              -- Revive when they are not actually dead. So they wont die with 25 hp. =) | I think even will counter headshots.
			dmg.status = LifeStatus.IsAlive
		end
	end
end


function PLUGIN:CombatDamage (takedamage, dmg)
    --rust.BroadcastChat('INITIAL DAMAGE: ' .. tostring(dmg.amount))
    --SET UP COMBATDATA
    local combatData = {['dmg']={}}
    combatData = setmetatable({}, {__newindex = function(t, k, v) rawset(t, k, v) end })

	--local combatData = {}

    if dmg.amount then combatData['dmg'] = {['amount'] = dmg.amount,['damageTypes'] = dmg.damageTypes.value__} end
    if dmg.extraData then combatData['weapon'] = core.Config.weapon[tostring(dmg.extraData.dataBlock.name)] end
    if dmg.attacker.controllable then combatData['netuser'] =  dmg.attacker.client.netUser combatData['netuserData'] = char[rust.GetUserID(dmg.attacker.client.netUser)] end
    if dmg.victim.controllable then combatData['vicuser'] = dmg.victim.client.netUser combatData['vicuserData'] = char[rust.GetUserID(dmg.victim.client.netUser)] end
    if dmg.bodyPart ~= nil then if(dmg.bodyPart:GetType().Name == "BodyPart" and _GetNiceName(dmg.bodyPart) ~= nil) then combatData['bodyPart'] = _GetNiceName(dmg.bodyPart) end end
    if combatData.netuser then combatData['debug'] = combatData.netuser.displayName elseif (not (combatData.netuser) and (combatData.vicuser )) then combatData['debug'] = combatData.vicuser.displayName end

	local npc = core.Config.npc

    for k,v in pairs(npc) do
        if (k == string.gsub(dmg.attacker.networkView.name,'%(Clone%)', '')) then
            combatData['npc'] = core.Config.npc[string.gsub(dmg.attacker.networkView.name,'%(Clone%)', '')]
        end
        if (k == string.gsub(dmg.victim.networkView.name,'%(Clone%)', '')) then
            combatData['npc'] = core.Config.npc[string.gsub(dmg.victim.networkView.name,'%(Clone%)', '')]
        end
    end

    if combatData.netuser and combatData.vicuser and combatData.netuser ~= combatData.vicuser and combatData.weapon then
        combatData['scenario'] = 1 --client vs client
    elseif dmg.victim.controllable and not dmg.attacker.controllable then
        combatData['scenario'] = 2 --npc vs client
    elseif dmg.attacker.controllable and not dmg.victim.controllable then
        combatData['scenario'] = 3 --client vs npc
    end

    --BEGIN BATTLE SYSTEM
    if combatData.scenario == 1 then
	   if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------client vs client------------' ) end
       rust.BroadcastChat('------------client vs client------------')
        combatData.dmg.amount = self:WeaponSkill(combatData)
	    if combatData.dmg.amount == 0 then return 0 end
        combatData.dmg.amount = self:DmgModifier(combatData) --modifies based on configs for player, weapon, npc, etc..
        combatData.dmg.amount = self:DmgRandomizer(combatData) --randomizes the damage output to create realism!
        combatData.dmg.amount = self:Attack(combatData) --+attributes, +skills,  function:perks, +/- dp.,
        combatData.dmg.amount = self:CritCheck(combatData) --+attributes, +skills,  function:perks, +/- dp.,
        -- combatData.dmg.amount = self:GuildAttack(combatData) --all guild offensive calls and modifiers
	    -- combatData.dmg.amount = self:ActivatePerks(combatData)
        combatData.dmg.amount = self:GuildAttack(combatData) --all guild offensive calls and modifiers
        --dmg = self:Defend(combatData) --attributes, skills, perks, dp, dodge
        combatData.dmg.amount = self:GuildDefend(combatData)--all guild DEFENSIVE calls and modifiers
    elseif combatData.scenario == 2 then
	   if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------pve vs client------------' ) end
       rust.BroadcastChat('------------pve vs client------------')
        combatData.dmg.amount = self:DmgModifier(combatData) --modifies based on configs for player, weapon, npc, etc..
        combatData.dmg.amount = self:DmgRandomizer(combatData) --randomizes the damage output to create realism!
        combatData.dmg.amount = self:Attack(combatData) --+attributes, +skills, +/- perks, +/- dp.,
        combatData.dmg.amount = self:CritCheck(combatData) --+attributes, +skills,  function:perks, +/- dp.,
	    -- combatData.dmg.amount = self:ActivatePerks(combatData)
        --dmg = self:Defend(combatData) --attributes, skills, perks, dp, dodge
        combatData.dmg.amount = self:GuildDefend(combatData)--all guild DEFENSIVE calls and modifiers
    elseif combatData.scenario == 3 then
	   if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------client vs pve------------' ) end
       rust.BroadcastChat('------------client vs pve------------')
        combatData.dmg.amount = self:WeaponSkill(combatData)
	    if combatData.dmg.amount == 0 then return 0 end
        combatData.dmg.amount = self:DmgModifier(combatData) --modifies based on configs for player, weapon, npc, etc..
        combatData.dmg.amount = self:DmgRandomizer(combatData) --randomizes the damage output to create realism!
        combatData.dmg.amount = self:Attack(combatData) --+attributes, +skills, +/- perks, +/- dp.,
        combatData.dmg.amount = self:CritCheck(combatData) --+attributes, +skills,  function:perks, +/- dp.,
        -- combatData.dmg.amount = self:GuildAttack(combatData) --all guild offensive calls and modifiers
	    -- combatData.dmg.amount = self:ActivatePerks(combatData)
        combatData.dmg.amount = self:GuildAttack(combatData) --all guild offensive calls and modifiers
        -- combatData.dmg.amount = self:Defend(combatData) --attributes, skills, perks, dp, dodge
    end
    -- if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '' ) end
  rust.BroadcastChat('Final Damage: ' .. tostring(combatData.dmg.amount))
    dmg.amount = combatData.dmg.amount
    return dmg, combatData
end
function PLUGIN:ActivatePerks(combatData)
	--BEGIN BATTLE SYSTEM
	if combatData.scenario == 1 then

	elseif combatData.scenario == 2 then

	elseif combatData.scenario == 3 then

	end
end
function PLUGIN:GuildAttack(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----PLUGIN:GuildAttack----' ) end
    rust.BroadcastChat('----PLUGIN:GuildAttack----')
    combatData.dmg.amount = guild:GuildAttackMods( combatData )
    if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( combatData.dmg.amount )) end
    return combatData.dmg.amount
end

function PLUGIN:GuildDefend(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----PLUGIN:GuildDefend----' ) end
    rust.BroadcastChat('----PLUGIN:GuildDefend----')
    combatData.dmg.amount = guild:GuildDefendMods( combatData )
    if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( combatData.dmg.amount )) end
    return combatData.dmg.amount
end
-----------------------------------------------------------------
--http://wiki.rustoxide.com/index.php?title=Hooks/OnKilled
function PLUGIN:OnKilled (takedamage, dmg)
    --SET UP COMBATDATA
    local combatData = {['dmg']={}}
    combatData = setmetatable({}, {__newindex = function(t, k, v) rawset(t, k, v) end })

	--local combatData = {}

    if dmg.amount then combatData['dmg'] = {['amount'] = dmg.amount,['damageTypes'] = dmg.damageTypes.value__} end
    if dmg.extraData then combatData['weapon'] = core.Config.weapon[tostring(dmg.extraData.dataBlock.name)] end
    if dmg.attacker.controllable then combatData['netuser'] =  dmg.attacker.client.netUser  combatData['netuserData'] = char[rust.GetUserID(dmg.attacker.client.netUser)] end
    if dmg.victim.controllable then combatData['vicuser'] = dmg.victim.client.netUser combatData['vicuserData'] = char[rust.GetUserID(dmg.victim.client.netUser)] end
    local npc = core.Config.npc
    for k,v in pairs(npc) do
        if (k == string.gsub(dmg.attacker.networkView.name,'%(Clone%)', '')) then
            combatData['npc'] = core.Config.npc[string.gsub(dmg.attacker.networkView.name,'%(Clone%)', '')]
        end
        if (k == string.gsub(dmg.victim.networkView.name,'%(Clone%)', '')) then
            combatData['npc'] = core.Config.npc[string.gsub(dmg.victim.networkView.name,'%(Clone%)', '')]
        end
    end

    if combatData.netuser and combatData.vicuser and combatData.netuser ~= combatData.vicuser and combatData.weapon then
        combatData['scenario'] = 1 --client vs client
    elseif dmg.victim.controllable and not dmg.attacker.controllable then
        combatData['scenario'] = 2 --npc vs client
    elseif dmg.attacker.controllable and not dmg.victim.controllable then
        combatData['scenario'] = 3 --client vs npc
    end

    --BEGIN BATTLE SYSTEM
    if combatData.scenario == 1 then
        combatData.netuserData.stats.kills.pvp = combatData.netuserData.stats.kills.pvp+1
        char:GiveDp( combatData, math.floor(combatData.vicuserData.xp*core.Config.settings.dppercent/100))
    elseif combatData.scenario == 2 then
        char:GiveDp( combatData, math.floor(combatData.vicuserData.xp*core.Config.settings.dppercent/100))
    elseif combatData.scenario == 3 then
        local xp = math.floor(combatData.npc.xp*core.Config.settings.xpmodifier)
        if (not combatData.netuserData.stats.kills.pve[combatData.npc.name]) then
            combatData.netuserData.stats.kills.pve[combatData.npc.name] = 1
        else
            combatData.netuserData.stats.kills.pve[combatData.npc.name] = combatData.netuserData.stats.kills.pve[combatData.npc.name]+1
        end
        combatData.netuserData.stats.kills.pve.total = combatData.netuserData.stats.kills.pve.total+1
	    local pdata = party:getParty( combatData.netuser )
        if pdata then
	        party:DistributeXP( combatData, pdata, xp )
        else
            char:GiveXp( combatData, xp, true)
        end
    end
end
-----------------------------------------------------------------
function PLUGIN:WeaponSkill (combatData)
    if (not combatData.netuserData.skills[combatData.weapon.name]) then
        char[combatData.netuserData.id].skills[combatData.weapon.name] = {['name']=combatData.weapon.name,['xp']=0,['lvl']=1 }
        char:Save( combatData.netuser )
    end
    if combatData.weapon.lvl > combatData.netuserData.skills[combatData.weapon.name].lvl then
        combatData.dmg.amount = 0
        if not spamNet[tostring(combatData.weapon.name .. combatData.netuser.displayName)] then
            func:Notice(combatData.netuser,'⊗','You are not proficient with this weapon!',5)
            spamNet[tostring(combatData.weapon.name .. combatData.netuser.displayName)] = true
            timer.Once(6, function() spamNet[tostring(combatData.weapon.name .. combatData.netuser.displayName)] = nil end)
        end
    end
    return combatData.dmg.amount
end
function PLUGIN:DmgModifier (combatData)
	-- if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '' ) end
    rust.BroadcastChat('----PLUGIN:DmgModifier----')
    if combatData.scenario == 1 then
        if combatData.weapon then
            combatData.dmg.amount = combatData.dmg.amount * combatData.weapon.dmg
        end
        if combatData.vicuser then
            combatData.dmg.amount = combatData.dmg.amount * combatData.vicuserData.dmg
        end
    elseif combatData.scenario == 2 then
        if combatData.vicuser then
            combatData.dmg.amount = combatData.dmg.amount * combatData.vicuserData.dmg
        end
    elseif combatData.scenario == 3 then
        if combatData.weapon then
            combatData.dmg.amount = combatData.dmg.amount * combatData.weapon.dmg
        end
        if combatData.vicuser then
            combatData.dmg.amount = combatData.dmg.amount * combatData.vicuserData.dmg
        end
        if combatData.npc then
            combatData.dmg.amount = combatData.dmg.amount * combatData.npc.dmg
        end
    end
    -- if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '' ) end
    rust.BroadcastChat(tostring(combatData.dmg.amount))
    return combatData.dmg.amount
end
function PLUGIN:DmgRandomizer(combatData)
	-- if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '' ) end
    rust.BroadcastChat('----PLUGIN:DmgRandomizer----')
    local seed = func:GetTimeMilliSeconds()
    math.randomseed(seed)
    combatData.dmg.amount = math.random(combatData.dmg.amount*.5,combatData.dmg.amount)
    -- if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '' ) end
    rust.BroadcastChat(tostring(combatData.dmg.amount))
    return combatData.dmg.amount
end
function PLUGIN:Attack(combatData)
	-- if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '' ) end
    rust.BroadcastChat('----PLUGIN:Attack----')
    if combatData.scenario == 1 then
        --ATTACKER DP DMG MODIFIERS
        if combatData.netuserData.dp then
            if combatData.netuserData.dp > 0 then
                local dppercentage = combatData.netuserData.dp/combatData.netuserData.xp
                local dmgdp = combatData.dmg.amount*dppercentage
                combatData.dmg.amount = combatData.dmg.amount-dmgdp
            end
        end
        --ATTACKER ATTRIBUTE DMG MODIFIERS
        if combatData.dmg.damageTypes then
            if (combatData.dmg.damageTypes == damage_melee) and (combatData.netuserData.attributes.str>0) then
                combatData.dmg.amount = combatData.dmg.amount * (((combatData.netuserData.attributes.str+combatData.netuserData.lvl)*.003)+1)
            elseif (combatData.dmg.damageTypes == damage_bullet) and (combatData.netuserData.attributes.agi>0) then
                combatData.dmg.amount = combatData.dmg.amount * (((combatData.netuserData.attributes.agi+combatData.netuserData.lvl)*.003)+1)
            end
        end


    elseif combatData.scenario == 2 then
        --ATTACKER DP DMG MODIFIERS
        if combatData.vicuserData.dp then
            if combatData.vicuserData.dp > 0 then
                local dppercentage = combatData.vicuserData.dp/combatData.vicuserData.xp
                local dmgdp = combatData.dmg.amount*dppercentage
                combatData.dmg.amount = combatData.dmg.amount+dmgdp
            end
        end
        if combatData.npc.attributes.str > 0 then
            combatData.dmg.amount = combatData.dmg.amount * (((combatData.npc.attributes.str+(math.floor((math.random(combatData.vicuserData.lvl-1,combatData.vicuserData.lvl+1))+.05)))*.003)+1)
        end
    elseif combatData.scenario == 3 then
        --ATTACKER DP DMG MODIFIERS
        if combatData.netuserData.dp then
            if combatData.netuserData.dp > 0 then
                local dppercentage = combatData.netuserData.dp/combatData.netuserData.xp
                local dmgdp = combatData.dmg.amount*dppercentage
                combatData.dmg.amount = combatData.dmg.amount-dmgdp
            end
        end
        --ATTACKER ATTRIBUTE DMG MODIFIERS
        if combatData.dmg.damageTypes then
            if (combatData.dmg.damageTypes == damage_melee) and (combatData.netuserData.attributes.str>0) then
                combatData.dmg.amount = combatData.dmg.amount * (((combatData.netuserData.attributes.str+combatData.netuserData.lvl)*.003)+1)
            elseif (combatData.dmg.damageTypes == damage_bullet) and (combatData.netuserData.attributes.agi>0) then
                combatData.dmg.amount = combatData.dmg.amount * (((combatData.netuserData.attributes.agi+combatData.netuserData.lvl)*.003)+1)
            end
        end
    end
    -- if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '' ) end
    rust.BroadcastChat(tostring(combatData.dmg.amount))
    return combatData.dmg.amount
end
function PLUGIN:CritCheck(combatData)
	-- if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '' ) end
    rust.BroadcastChat('----PLUGIN:CritCheck----')
    if combatData.scenario == 1 then
        if (combatData.netuserData.attributes.agi>0) then
            local roll = func:Roll(false, 100)
            if combatData.dmg.damageTypes == 4 then
                if ((combatData.netuserData.attributes.agi+combatData.netuserData.lvl)*.002 >= roll) then
                    combatData.dmg.amount = combatData.dmg.amount * 2
                    rust.InventoryNotice( combatData.netuser, 'Critical Hit!' )
                end
            elseif combatData.dmg.damageTypes == 2 then
                if ((combatData.netuserData.attributes.agi+combatData.netuserData.lvl)*.001 >= roll) then
                    combatData.dmg.amount = combatData.dmg.amount * 2
                    rust.InventoryNotice( combatData.netuser, 'Critical Hit!' )
                end
            end
        end
    elseif combatData.scenario == 2 then
        if (combatData.npc.attributes.agi>0) then
            local roll = func:Roll(false, 100)
            if (combatData.npc.attributes.agi+math.random(combatData.vicuserData.lvl-1,combatData.vicuserData.lvl+1))*.002 >= roll then
                combatData.dmg.amount = combatData.dmg.amount * 2
                rust.InventoryNotice( vicuser, 'Critically Wounded!' )
            end
        end
    elseif combatData.scenario == 3 then
        if (combatData.netuserData.attributes.agi>0) then
            local roll = func:Roll(false, 100)
            if combatData.dmg.damageTypes == 4 then
                if ((combatData.netuserData.attributes.agi+combatData.netuserData.lvl)*.002 >= roll) then
                    combatData.dmg.amount = combatData.dmg.amount * 2
                    rust.InventoryNotice( combatData.netuser, 'Critical Hit!' )
                end
            elseif combatData.dmg.damageTypes == 2 then
                if ((combatData.netuserData.attributes.agi+combatData.netuserData.lvl)*.001 >= roll) then
                    combatData.dmg.amount = combatData.dmg.amount * 2
                    rust.InventoryNotice( combatData.netuser, 'Critical Hit!' )
                end
            end
        end
    end
    -- if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '' ) end
    rust.BroadcastChat(tostring(combatData.dmg.amount))
    return combatData.dmg.amount
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
                local vicuserData = char[rust.GetUserID(vicuser)]
                local npc = core.Config.npc[string.gsub(tostring(dmg.attacker.networkView.name), '%(Clone%)', '')]

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
                --dmg.amount = self:attrModify(weaponData, npc, vicuserData, dmg.amount)  if debugr == true then rust.BroadcastChat('ATTRIBUTE DMG MODIFIER: ' .. tostring(dmg.amount)) end
                -- STEP 7 CRIT CHECK
                dmg.amount = self:critCheck(weaponData, npc, vicuserData, dmg.amount)    if debugr == true then rust.BroadcastChat('CRIT CHANCE: ' .. tostring(dmg.amount)) end
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
            local netuserData = char[rust.GetUserID(netuser)]
            local npc = core.Config.npc[string.gsub(tostring(dmg.victim.networkView.name), '%(Clone%)', '')]

            if (not netuserData.skills[tostring(dmg.extraData.dataBlock.name)]) then
                netuserData.skills[weaponData.name] = {['name']=tostring(weaponData.name),['xp']=0,['lvl']=0 }
                char:UserSave()
            end

            if debugr == true then rust.BroadcastChat('---------------BEGIN ME VS PVE---------------') end
            -- STEP 1 VIC MODIFIER
            dmg.amount = dmg.amount*npc.dmg     if debugr == true then rust.BroadcastChat('VICUSER DMG MODIFIER: ' .. tostring(dmg.amount)) end
            -- STEP 2 WPN DMG MODIFIER
            if weaponData then dmg.amount = dmg.amount*weaponData.dmg     if debugr == true then rust.BroadcastChat('WEAPON DMG MODIFIER: ' .. tostring(dmg.amount)) end end
            --STEP 3 DAMAGE ROLL
            dmg.amount = math.random(dmg.amount*0.5,tonumber(dmg.amount))   if debugr == true then rust.BroadcastChat('RANDOM DAMAGE: ' .. tostring(dmg.amount)) end
            --STEP 4 DP MODIFIER
            dmg.amount = self:modifyDP(netuserData, dmg.amount)
            --STEP 5 WPN SKILL MODIFIER
            dmg.amount = dmg.amount+netuserData.skills[ weaponData.name ].lvl*0.3      if debugr == true then rust.BroadcastChat('WEAPON SKILL BONUS: ' .. tostring(netuserData.skills[weaponData.name].lvl*.3)) end
            -- STEP 6 ATR MODIFIER
            dmg.amount = self:attrModify(weaponData, netuserData, npc, dmg.amount)      if debugr == true then rust.BroadcastChat('ATTRIBUTE DMG MODIFIER: ' .. tostring(dmg.amount)) end
            -- STEP 7 CRIT CHECK
            dmg.amount = self:critCheck(weaponData, netuser, netuserData, dmg.amount)       if debugr == true then rust.BroadcastChat('CRIT CHANCE: ' .. tostring(dmg.amount)) end
            --STEP 8 VIC STA MOD
            dmg.amount = self:staModify(netuserData, nil, npc, dmg.amount)    if debugr == true then rust.BroadcastChat('STAMINA MODIFIER:' .. tostring(dmg.amount)) end

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
        local vicuserData = char[rust.GetUserID(vicuser)]
        if(dmg.victim.client and dmg.attacker.client) then
            local netuser = dmg.attacker.client.netUser
            local netuserData = char[rust.GetUserID(netuser)]
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
            local npc = core.Config.npc[string.gsub(tostring(dmg.victim.networkView.name), '%(Clone%)', '')]
            local netuser = dmg.attacker.client.netUser
            local netuserData = char[rust.GetUserID(netuser)]
            local xp = math.floor(npc.xp*core.Config.settings.xpmodifier)
            if (not netuserData.stats.kills.pve[npc.name]) then
                netuserData.stats.kills.pve[npc.name] = 1
            else
                netuserData.stats.kills.pve[npc.name] = netuserData.stats.kills.pve[npc.name]+1
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
            char.GiveXp( actorUser, tonumber(math.floor(char[sleepreId].xp*core.Config.settings.sleeperxppercent/100)))
            self:setXpPercentById(sleepreId, tonumber(100-core.Config.settings.sleeperxppercent-core.Config.settings.dppercent))
        end
	end
    return
end

--PLUGIN:staModify
function PLUGIN:staModify(netuserData, vicuserData, npc, damage)
    if (vicuserData) then
        if (vicuserData.attributes.sta>0) then
            damage = damage-((vicuserData.attributes.sta+vicuserData.lvl)*0.1)
            if debugr == true then rust.BroadcastChat('PLUGIN:staModify (vicuser) :' .. tostring(dmg.amount)) end
        end
    end
    if (npc) then
        if (npc.attributes.sta>0) then
            damage = damage-((npc.attributes.sta+math.random(netuserData.lvl-1,netuserData.lvl+1))*0.1)
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

    if( char[ netuserData.id ].buffs[ 'ParryCrit' ]) then
        damage = damage * 2
        char[ netuserData.id ].buffs[ 'ParryCrit' ] = nil
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