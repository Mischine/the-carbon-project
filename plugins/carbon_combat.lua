PLUGIN.Title = 'carbon_core'
PLUGIN.Description = 'combat module'
PLUGIN.Version = '0.0.3'
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
local IsDead = tostring(LifeStatus.IsDead)
local WasKilled = tostring(LifeStatus.WasKilled)
local Failed = tostring(LifeStatus.Failed)

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end

function PLUGIN:OnProcessDamageEvent( takedamage, damage )
	rust.BroadcastChat( 'damage: ' .. tostring(damage.amount) )
	damage.amount = thief:StealthCheck( takedamage, damage )  -- Stealth check
	local combatData, status, dmg = {}, tostring( damage.status )
	if ( status ~= IsDead ) then dmg, combatData = self:CombatDamage( takedamage, damage ) end
	if (( combatData and combatData.bodyPart) and ( not combatData.npc )) and not combatData.entity then rust.BroadcastChat( combatData.bodyPart ) end
	if dmg.amount >= takedamage.health then	if dmg.status then dmg.status = LifeStatus.WasKilled end end
	if dmg.amount <= 0 then	dmg.status = LifeStatus.IsAlive	rust.BroadcastChat( cancelagro ) end
	if status and dmg.status then if status == WasKilled then	if dmg.amount < takedamage.health then dmg.status = LifeStatus.IsAlive end end end
end

local _BodyParts = cs.gettype( "BodyParts, Facepunch.HitBox" )
local _GetNiceName = util.GetStaticMethod( _BodyParts, "GetNiceName" )
function PLUGIN:CombatDamage (takedamage, dmg)
	-- Object check
	if takedamage.gameObject then
		rust.BroadcastChat( 'Name: ' .. tostring( takedamage.gameObject.Name ))
		rust.BroadcastChat( 'Health: ' .. tostring( takedamage.health) )
		rust.BroadcastChat( 'Damage: ' .. tostring( dmg.amount) )
		if dmg.attacker then rust.BroadcastChat( 'Attacker: ' .. tostring( dmg.attacker) ) else rust.BroadcastChat( 'No attacker' ) end
	end
	local randMultiplier = func:Roll(false,0.50123456789,0.59876543210) dmg.amount = func:Roll(false,dmg.amount*randMultiplier,dmg.amount)

    local combatData = {}
    if dmg.amount then combatData['dmg'] = {['amount'] = dmg.amount,['damageTypes'] = dmg.damageTypes.value__} end
    if dmg.extraData then combatData['weapon'] = core.Config.weapon[tostring(dmg.extraData.dataBlock.name)] end
    if dmg.attacker.controllable then combatData['netuser'] =  dmg.attacker.client.netUser combatData['netuserData'] = char[rust.GetUserID(dmg.attacker.client.netUser)] end
    if dmg.victim.controllable then combatData['vicuser'] = dmg.victim.client.netUser combatData['vicuserData'] = char[rust.GetUserID(dmg.victim.client.netUser)] end

    if dmg.bodyPart ~= nil then if(dmg.bodyPart:GetType().Name == "BodyPart" and _GetNiceName(dmg.bodyPart) ~= nil) then combatData['bodyPart'] = _GetNiceName(dmg.bodyPart) end end
    if combatData.netuser then combatData['debug'] = combatData.netuser.displayName elseif (not (combatData.netuser) and (combatData.vicuser )) then combatData['debug'] = combatData.vicuser.displayName end

	-- Berserker plugin stuff ( Auto repair \ Auto ammo fill )
	func:Repair( combatData.netuser, 1 )

    for k,v in pairs(core.Config.npc) do
	    if dmg.attacker and dmg.attacker.networkView then
	        if (k == string.gsub(dmg.attacker.networkView.name,'%(Clone%)', '')) then
	            combatData['npc'] = core.Config.npc[string.gsub(dmg.attacker.networkView.name,'%(Clone%)', '')]
		        break
	        end
	    end
	    if dmg.victim and dmg.victim.networkView then
	        if (k == string.gsub(dmg.victim.networkView.name,'%(Clone%)', '')) then
	            combatData['npc'] = core.Config.npc[string.gsub(dmg.victim.networkView.name,'%(Clone%)', '')]
		        break
	        end
	    end
    end
	if takedamage.gameObject then
		for k, v in pairs( core.Config.entities ) do
			if dmg.attacker and dmg.attacker.networkView then
				if dmg.victim then
					if k == takedamage.gameObject.Name then	combatData['entity'] = v break end
				end
			end
		end
	end
    if combatData.netuser and combatData.vicuser and combatData.netuser ~= combatData.vicuser and combatData.weapon then
        combatData['scenario'] = 1 --client vs client
        rust.BroadcastChat( 'Scenario: 1' )
    elseif dmg.victim.controllable and not dmg.attacker.controllable then
        combatData['scenario'] = 2 --npc vs client
        rust.BroadcastChat( 'Scenario: 2' )
    elseif dmg.attacker.controllable and not dmg.victim.controllable and not combatData.entity then
        combatData['scenario'] = 3 --client vs npc
        rust.BroadcastChat( 'Scenario: 3' )
    elseif dmg.attacker.contrallable and combatData.entity and combatData.weapon.type == 'm' then
	    combatData['scenario'] = 4 --client vs entity
	    combatData.dmg.amount = combatData.entity.dmg           -- setting base damage for each object.
	    rust.BroadcastChat( 'Scenario: 4' )
    elseif dmg.attacker.contrallable and combatData.entity then
	    combatData['scenario'] = 5 --client vs entity
	    rust.BroadcastChat( 'Scenario: 5' )
	    return combatData.dmg, combatData
    else
	    rust.BroadcastChat( 'Scenario: Invalid' )
	    self:PrintInvalidScenario( combatData,dmg, takedamage )
	    return combatData.dmg, combatData
    end

    --BEGIN BATTLE SYSTEM
    if combatData.scenario == 1 then                                                                                        -- client vs client
	    --[[ TODO: FIX ARMOR REQUIREMENTS
	    local controllable = combatData.netuser.playerClient.controllable
	    local ProtectionTakeDamage = controllable:GetComponent( "ProtectionTakeDamage" )
	    local acValue = ProtectionTakeDamage.GetArmorValues
	    rust.BroadcastChat(tostring(acValue))
	    --]]
		if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------client vs client------------' ) end
		--rust.BroadcastChat('------------client vs client------------')
		combatData.dmg.amount = self:WeaponSkill(combatData)
		if combatData.dmg.amount == 0 then return combatData.dmg end
		combatData.dmg.amount = self:PartyCheck( combatData )
		if combatData.dmg.amount == 0 then return combatData.dmg end
		combatData.dmg.amount = self:GuildCheck( combatData )
		if combatData.dmg.amount == 0 then return combatData.dmg end
		combatData.dmg.amount = self:DmgModifier(combatData) --modifies based on configs for player, weapon, npc, etc..
		combatData.dmg.amount = self:DmgRandomizer(combatData) --randomizes the damage output to create realism!
		combatData.dmg.amount = self:Attack(combatData) --+attributes, +skills,  function:perks, +/- dp.,
		combatData.dmg.amount = self:CritCheck(combatData) --+attributes, +skills,  function:perks, +/- dp.,
		combatData.dmg.amount = self:GuildAttack(combatData) --all guild offensive calls and modifiers
		for k,v in pairs(combatData.netuserData.perks) do combatData.dmg.amount = perk[k](perk, combatData) end
		--combatData.dmg.amount = self:Defend(combatData) --attributes, skills, perks, dp, dodge
		combatData.dmg.amount = self:ThiefMod( combatData )
		combatData.dmg.amount = self:GuildDefend(combatData)--all guild DEFENSIVE calls and modifiers
    elseif combatData.scenario == 2 then                                                                                        -- pve vs client
		if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------pve vs client------------' ) end
		--rust.BroadcastChat('------------pve vs client------------')
		combatData.dmg.amount = self:DmgModifier(combatData) --modifies based on configs for player, weapon, npc, etc..
		combatData.dmg.amount = self:DmgRandomizer(combatData) --randomizes the damage output to create realism!
		combatData.dmg.amount = self:Attack(combatData) --+attributes, +skills, +/- perks, +/- dp.,
		combatData.dmg.amount = self:CritCheck(combatData) --+attributes, +skills,  function:perks, +/- dp.,
		for k,v in pairs(combatData.vicuserData.perks) do combatData.dmg.amount = perk[k](perk, combatData) end
		combatData.dmg.amount = self:GuildDefend(combatData)--all guild DEFENSIVE calls and modifiers
		combatData.dmg.amount = self:Defend(combatData) --attributes, skills, perks, dp, dodge
    elseif combatData.scenario == 3 then                                                                                        -- client vs pve
		if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------client vs pve------------' ) end
		--rust.BroadcastChat('------------client vs pve------------')
		combatData.dmg.amount = self:WeaponSkill(combatData)
		if combatData.dmg.amount == 0 then return combatData.dmg end
		combatData.dmg.amount = self:DmgModifier(combatData) --modifies based on config s for player, weapon, npc, etc...
		combatData.dmg.amount = self:DmgRandomizer(combatData) --randomizes the damage output to create realism!
		combatData.dmg.amount = self:Attack(combatData) --+attributes, +skills, +/- perks, +/- dp.
		combatData.dmg.amount = self:CritCheck(combatData) --+attributes, +skills,  function:perks, +/- dp.
		for k,v in pairs(combatData.netuserData.perks) do combatData.dmg.amount = perk[k](perk, combatData) end
		combatData.dmg.amount = self:GuildAttack(combatData) --all guild offensive calls and modifiers
	elseif combatData.scenario == 4 then                                                                                        -- client vs entity
	    if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------client vs entity------------' ) end
	    --rust.BroadcastChat('------------client vs entity------------')

    end
    if debug.list[ combatData.debug] then debug:SendDebug(combatData.debug, 'Final Damage: ' .. tostring(combatData.dmg.amount)) end
    rust.BroadcastChat('Final Damage: ' .. tostring(combatData.dmg.amount))
    dmg.amount = combatData.dmg.amount
    return dmg, combatData
end

-----------------------------------------------------------------
--http://wiki.rustoxide.com/index.php?title=Hooks/OnKilled
function PLUGIN:OnKilled (takedamage, dmg)
	--SET UP COMBATDATA
	--local combatData = {['dmg']={}}
	--combatData = setmetatable({}, {__newindex = function(t, k, v) rawset(t, k, v) end })
	local combatData = {}

	if dmg.amount then combatData['dmg'] = {['amount'] = dmg.amount,['damageTypes'] = dmg.damageTypes.value__} end
	if dmg.extraData then combatData['weapon'] = core.Config.weapon[tostring(dmg.extraData.dataBlock.name)] end
	if dmg.attacker.controllable then combatData['netuser'] =  dmg.attacker.client.netUser  combatData['netuserData'] = char[rust.GetUserID(dmg.attacker.client.netUser)] end
	if dmg.victim.controllable then combatData['vicuser'] = dmg.victim.client.netUser combatData['vicuserData'] = char[rust.GetUserID(dmg.victim.client.netUser)] end
	if dmg.bodyPart ~= nil then if(dmg.bodyPart:GetType().Name == "BodyPart" and _GetNiceName(dmg.bodyPart) ~= nil) then combatData['bodyPart'] = _GetNiceName(dmg.bodyPart) end end
	if combatData.netuser then combatData['debug'] = combatData.netuser.displayName elseif (not (combatData.netuser) and (combatData.vicuser )) then combatData['debug'] = combatData.vicuser.displayName end

	for k,v in pairs(core.Config.npc) do
		if dmg.attacker and dmg.attacker.networkView then
			if (k == string.gsub(dmg.attacker.networkView.name,'%(Clone%)', '')) then
				combatData['npc'] = core.Config.npc[string.gsub(dmg.attacker.networkView.name,'%(Clone%)', '')]
				break
			end
		end
		if dmg.victim and dmg.victim.networkView then
			if (k == string.gsub(dmg.victim.networkView.name,'%(Clone%)', '')) then
				combatData['npc'] = core.Config.npc[string.gsub(dmg.victim.networkView.name,'%(Clone%)', '')]
				break
			end
		end
	end
	if takedamage.gameObject then
		for k, v in pairs( core.Config.entities ) do
			if dmg.attacker and dmg.attacker.networkView then
				if dmg.victim then
					if k == takedamage.gameObject.Name then	combatData['entity'] = v break end
				end
			end
		end
	end

	if combatData.netuser and combatData.vicuser and combatData.netuser ~= combatData.vicuser and combatData.weapon then
		combatData['scenario'] = 1 --client vs client
		rust.BroadcastChat( 'Scenario: 1' )
	elseif dmg.victim.controllable and not dmg.attacker.controllable then
		combatData['scenario'] = 2 --npc vs client
		rust.BroadcastChat( 'Scenario: 2' )
	elseif dmg.attacker.controllable and not dmg.victim.controllable and not combatData.entity then
		combatData['scenario'] = 3 --client vs npc
		rust.BroadcastChat( 'Scenario: 3' )
	elseif dmg.attacker.contrallable and combatData.entity and combatData.weapon.type == 'm' then
		combatData['scenario'] = 4 --client vs entity
		combatData.dmg.amount = combatData.entity.dmg           -- setting base damage for each object.
		rust.BroadcastChat( 'Scenario: 4' )
	elseif dmg.attacker.contrallable and combatData.entity then
		combatData['scenario'] = 5 --client vs entity
		rust.BroadcastChat( 'Scenario: 5' )
	else
		rust.BroadcastChat( 'Scenario: Invalid' )
		self:PrintInvalidScenario( combatData, dmg, takedamage )
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
		if pdata then party:DistributeXP( combatData, pdata, xp ) else char:GiveXp( combatData, xp, true) end
	elseif combatData.scenario == 4 then
		-- Client vs Entity ( valid weapon )
		-- If we decide to do nothing with this scenario, we can just delete it.
	elseif combatData.scenario == 5 then
		-- Client vs Entity ( invalid weapon )
		-- If we decide to do nothing with this scenario, we can just delete it.
	end
end
-----------------------------------------------------------------

-- When there is an invalid Scenario, it will print some info to help use create a new scenario or smash a bug.
-- TODO: Add more debugs to it. I dont know them all.
function PLUGIN:PrintInvalidScenario( combatData, dmg, takedamage )
	print( '----- Begin: Invalid Scenario Print -----' )
	if combatData then
		if takedamage.gameObject then print('gameObject: ' .. tostring(takedamage.gameObject.Name)) end
		if takedamage.health then print('health: ' .. tostring(combatData)) end
		if dmg and dmg.amount then print('Damage: ' .. tostring(dmg.amount)) end

		if combatData.netuser then print( 'netuser: ' .. tostring(combatData.netuser) ) end
		if combatData.vicuser then print( 'vicuser: ' .. tostring(combatData.vicuser)) end
		if combatData.weapon then print( 'weapon: ' .. tostring(combatData.weapon.name)) end
		if combatData.dmg then print('damage: ' .. tostring(combatData.dmg.amount)) end
		if combatData.npc then print('npc: ' .. tostring(combatData.npc.name)) end
		if combatData.entity then print('entity: ' .. tostring(combatData.entity.name)) end
		if combatData.bodyPart then print('BodyPart: ' .. tostring(combatData.bodyPart)) end
		-- if combatData then print('' .. tostring(combatData)) end
	end
	print( '----- End: Invalid Scenario Print -----' )
end

function PLUGIN:ActivatePerks(combatData)
	--BEGIN BATTLE SYSTEM
	if combatData.scenario == 1 then

	elseif combatData.scenario == 2 then

	elseif combatData.scenario == 3 then

	end
end
function PLUGIN:GuildAttack(combatData, takedamage )
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----PLUGIN:GuildAttack----' ) end
    --rust.BroadcastChat('----PLUGIN:GuildAttack----')
    combatData.dmg.amount = guild:GuildAttackMods( combatData, takedamage )
    if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( combatData.dmg.amount )) end
    return combatData.dmg.amount
end

function PLUGIN:GuildDefend(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----PLUGIN:GuildDefend----' ) end
    --rust.BroadcastChat('----PLUGIN:GuildDefend----')
    combatData.dmg.amount = guild:GuildDefendMods( combatData )
    if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( combatData.dmg.amount )) end
    return combatData.dmg.amount
end

function PLUGIN:ThiefMod( combatData )
	rust.BroadcastChat( 'Thief start' )
	if thief:isThief( combatData.netuser ) and thief:hasStealth( combatData.netuser ) then
		rust.BroadcastChat( 'Thief start' )
		local netchar = rust.GetCharacter(combatData.netuser)
		local vicchar = rust.GetCharacter(combatData.vicuser)
		if (type(netchar.eyesYaw == "number")) and (type(vicchar.eyesYaw == "number")) then
			local netangle = (netchar.eyesYaw+90)%360
			local vicangle = (vicchar.eyesYaw+90)%360
			if (((netangle - vicangle) >= -40) and ((netangle - vicangle) <= 40)) then
				combatData.dmg.amount = combatData.dmg.amount * (1 + combatData.netuserData.classdata.thief.backstab)
				rust.InventoryNotice( combatData.netuser, 'Backstab!' )
				thief:Unstealth( combatData.netuser )
				return combatData.dmg.amount
			end
		end
	end
	return combatData.dmg.amount
end

function PLUGIN:PartyCheck( combatData )
	local NetParty = party:getParty( combatData.netuser )
	if not NetParty then return combatData.dmg.amount end
	local VicParty = party:getParty( combatData.vicuser )
	if not VicParty then return combatData.dmg.amount end
	if VicParty.id == NetParty.id then
		rust.Notice( combatData.netuser, combatData.vicuserData.name .. ' is in your party!'  )
		return 0
	end
	return combatData.dmg.amount
end

function PLUGIN:GuildCheck( combatData )
	local NetGuild = guild:getGuild( combatData.netuser )
	if not NetGuild then return combatData.dmg.amount end
	local VicGuild = guild:getGuild( combatData.vicuser )
	if not VicGuild then return combatData.dmg.amount end
	if NetGuild == VicGuild then
		rust.Notice( combatData.netuser , combatData.vicuserData.name .. ' is in your guild!' )
		return 0
	end
	return combatData.dmg.amount
end

function PLUGIN:WeaponSkill(combatData)
	if not combatData.weapon then return combatData.dmg.amount end  -- First step to C4 bug fixing victory! >:)
    if (not combatData.netuserData.skills[combatData.weapon.name]) then
        char[combatData.netuserData.id].skills[combatData.weapon.name] = {['name']=combatData.weapon.name,['xp']=0,['lvl']=1 }
        char:Save( combatData.netuser )
    end
    if combatData.weapon.lvl > combatData.netuserData.skills[combatData.weapon.name].lvl then
        combatData.dmg.amount = 0
        if not spamNet[tostring(combatData.weapon.name .. combatData.netuser.displayName)] then
            func:Notice(combatData.netuser,'⊗','You are not proficient with this weapon!',5)
            local inv = rust.GetInventory( combatData.netuser )
            if inv then inv:DeactivateItem() end
            spamNet[tostring(combatData.weapon.name .. combatData.netuser.displayName)] = true
            timer.Once(6, function() spamNet[tostring(combatData.weapon.name .. combatData.netuser.displayName)] = nil end)
        end
    end

    -- TODO: Add dmg increase on higher weaponlvl.
    return combatData.dmg.amount
end
function PLUGIN:DmgModifier (combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----PLUGIN:DmgModifier----' ) end
    --rust.BroadcastChat('----PLUGIN:DmgModifier----')
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
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( combatData.dmg.amount )) end
    --rust.BroadcastChat(tostring(combatData.dmg.amount))
    return combatData.dmg.amount
end
function PLUGIN:DmgRandomizer(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----PLUGIN:DmgRandomizer----' ) end
    --rust.BroadcastChat('----PLUGIN:DmgRandomizer----')
    local min, max = combatData.dmg.amount*.5,combatData.dmg.amount
    combatData.dmg.amount = func:Roll(false,min,max)
    if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( combatData.dmg.amount )) end
    --rust.BroadcastChat(tostring(combatData.dmg.amount))
    return combatData.dmg.amount
end
function PLUGIN:Attack(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----PLUGIN:Attack----' ) end
    --rust.BroadcastChat('----PLUGIN:Attack----')
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
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( combatData.dmg.amount )) end
    --rust.BroadcastChat(tostring(combatData.dmg.amount))
    return combatData.dmg.amount
end
function PLUGIN:CritCheck(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----PLUGIN:CritCheck----' ) end
    --rust.BroadcastChat('----PLUGIN:CritCheck----')
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
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( combatData.dmg.amount )) end
    --rust.BroadcastChat(tostring(combatData.dmg.amount))
    return combatData.dmg.amount
end