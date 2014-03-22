PLUGIN.Title = 'carbon_core'
PLUGIN.Description = 'combat module'
PLUGIN.Version = '140319' --ADDED NEW VERSION CONTROL USING DATE 2DIGIT([YR][MO][DA].[24HRTIME])
PLUGIN.Author = 'mischa / carex'

local structureMaster_ownerID = util.GetFieldGetter(Rust.StructureMaster, "ownerID", true)
local deployableObject_ownerID = util.GetFieldGetter(Rust.DeployableObject, "ownerID", true)

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

local structure_ceiling = 3
local structure_doorway = 2
local structure_foundation = 5
local structure_last = 8
local structure_pillar = 0
local structure_ramp = 7
local structure_stairs = 4
local structure_wall = 1
local structure_windowwall = 6

local IsAlive = tostring(LifeStatus.IsAlive)
local IsDead = tostring(LifeStatus.IsDead)
local WasKilled = tostring(LifeStatus.WasKilled)
local Failed = tostring(LifeStatus.Failed)

local spamNet = {}

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end
function PLUGIN:OnProcessDamageEvent( takedamage, damage )
	--rust.BroadcastChat(tostring(UnityEngineGameObject:GetComponents()))
	--print(tostring(takedamage.bleedAttcker))
	--rust.BroadcastChat( tostring( takedamage ))
	--rust.BroadcastChat( 'damage: ' .. tostring(damage.amount) )
	damage.amount = thief:StealthCheck( takedamage, damage )  -- Stealth check
	local combatData, status, dmg = {}, tostring( damage.status )
	if ( status ~= IsDead ) then dmg, combatData = self:CombatDamage( takedamage, damage ) end
	if (( combatData and combatData.bodyPart) and ( not combatData.npc )) and not combatData.entity then --[[rust.BroadcastChat( combatData.bodyPart )]] end
	if dmg.amount >= takedamage.health then	if dmg.status then dmg.status = LifeStatus.WasKilled end end
	if dmg.amount <= 0 then	dmg.status = LifeStatus.IsAlive	return end
	if status and dmg.status then if status == WasKilled then	if dmg.amount < takedamage.health then dmg.status = LifeStatus.IsAlive end end end
end



function PLUGIN:GetDistance(netuser)
	local Raycastp = util.FindOverloadedMethod( UnityEngine.Physics, "RaycastAll", bf.public_static, { UnityEngine.Ray } )
	cs.registerstaticmethod( "tmp", Raycastp )
	local RaycastAll = tmp
	tmp = nil

	local hits = RaycastAll( rust.GetCharacter( netuser ).eyesRay )
	local tbl = cs.createtablefromarray( hits )
	if (#tbl == 0) then return end
	local closest = tbl[1]
	local closestdist = closest.distance
	for i=2, #tbl do
		if (tbl[i].distance < closestdist) then
			closest = tbl[i]
			closestdist = closest.distance
		end
	end
	targetLoc = closest.point
	netuserLoc = netuser.playerClient.lastKnownPosition
	return math.floor(math.sqrt(math.pow(netuserLoc.x - targetLoc.x,2) + math.pow(netuserLoc.y - targetLoc.y,2) + math.pow(netuserLoc.z - targetLoc.z,2))+.5)
end

function PLUGIN:CombatDamage (takedamage, dmg)
		local combatData = self:GetCombatData(takedamage,dmg)
		--perk:knockback(combatData)

		--[[
		local StructureComponent = takedamage:GetComponent("StructureComponent")
		local DeployableObject = takedamage:GetComponent("DeployableObject")
		if DeployableObject then

		elseif StructureComponent then
			local StructureMaster = StructureComponent._master
			rust.BroadcastChat( 'Name: ' .. tostring( takedamage.gameObject.Name ))
			rust.BroadcastChat( 'Health: ' .. tostring( takedamage.health) )
			rust.BroadcastChat( 'Damage: ' .. tostring( dmg.amount) )
			rust.BroadcastChat( 'StructureComponent: ' .. tostring( StructureComponent ))
			rust.BroadcastChat( 'OwnerID: ' .. tostring( tonumber(structureMaster_ownerID(StructureMaster)) ))

			local foundNetUser = func:FindNetUserById(tonumber(structureMaster_ownerID(StructureMaster)))
			rust.BroadcastChat( tostring(foundNetUser))
			rust.BroadcastChat( 'Structure Type: ' .. tostring( StructureComponent.type.value__ ))
			rust.BroadcastChat( 'Material Type: ' .. tostring( StructureComponent._materialType ))
			--rust.BroadcastChat( tostring( tostring(StructureMaster.gridSpacingXZ)))
			--rust.BroadcastChat( tostring( tostring(StructureMaster.gridSpacingY) ))
			--rust.BroadcastChat( tostring( tostring(StructureMaster.foundationSize) ))
			--rust.BroadcastChat( tostring( StructureComponent.deathEffect ))
		end
--]]
		--if dmg.attacker then rust.BroadcastChat( 'Attacker: ' .. tostring( dmg.attacker) ) else rust.BroadcastChat( 'No attacker' ) end



	-- Berserker plugin stuff ( Auto repair \ Auto ammo fill )
	--func:Repair( combatData.netuser, 1 )
    --BEGIN BATTLE SYSTEM
    if combatData.scenario == 1 then
		if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------PVP------------' ) end
		combatData.dmg.amount = self:WeaponSkill(combatData); if combatData.dmg.amount == 0 then return combatData.dmg, combatData end
		combatData.dmg.amount = self:PartyCheck(combatData); if combatData.dmg.amount == 0 then return combatData.dmg, combatData end
		combatData.dmg.amount = self:GuildCheck(combatData); if combatData.dmg.amount == 0 then return combatData.dmg, combatData end
		combatData.dmg.amount = self:DmgModifier(combatData)
		combatData.dmg.amount = self:DmgRandomizer(combatData)
		combatData.dmg.amount = self:Attack(combatData)
		combatData.dmg.amount = self:CritCheck(combatData) --TODO: MOVE INTO ATTACK
		combatData.dmg.amount = self:GuildAttack(combatData)
		combatData.dmg.amount = self:ActivatePerks(combatData); if combatData.dmg.amount == 0 then return combatData.dmg, combatData end
		combatData.dmg.amount = self:ThiefMod(combatData)
		combatData.dmg.amount = self:GuildDefend(combatData)
		combatData.dmg.amount = self:Defend(combatData); if combatData.dmg.amount == 0 then return combatData.dmg, combatData end --TODO: ADD ARMOR MODIFICATIONS IN HERE
    elseif combatData.scenario == 2 then
		if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------EVP------------' ) end
		combatData.dmg.amount = self:DmgModifier(combatData)
		combatData.dmg.amount = self:DmgRandomizer(combatData)
		combatData.dmg.amount = self:Attack(combatData)
		combatData.dmg.amount = self:CritCheck(combatData) --TODO: MOVE INTO ATTACK
		combatData.dmg.amount = self:ActivatePerks(combatData);if combatData.dmg.amount == 0 then return combatData.dmg, combatData end
		combatData.dmg.amount = self:GuildDefend(combatData)
		combatData.dmg.amount = self:Defend(combatData); if combatData.dmg.amount == 0 then return combatData.dmg, combatData end --TODO: ADD ARMOR MODIFICATIONS IN HERE
    elseif combatData.scenario == 3 then
		if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------PVE------------' ) end
		combatData.dmg.amount = self:WeaponSkill(combatData);if combatData.dmg.amount == 0 then return combatData.dmg, combatData end
		combatData.dmg.amount = self:DmgModifier(combatData)
		combatData.dmg.amount = self:DmgRandomizer(combatData)
		combatData.dmg.amount = self:RangeModifier(combatData)
		combatData.dmg.amount = self:Attack(combatData)
		combatData.dmg.amount = self:CritCheck(combatData)--TODO: MOVE INTO ATTACK
		combatData.dmg.amount = self:ActivatePerks(combatData); if combatData.dmg.amount == 0 then return combatData.dmg, combatData end
		combatData.dmg.amount = self:GuildAttack(combatData)
		combatData.dmg.amount = self:Defend(combatData); if combatData.dmg.amount == 0 then return combatData.dmg, combatData end --TODO: ADD ARMOR MODIFICATIONS IN HERE
	elseif combatData.scenario == 4 then                                                                                        -- client vs entity
	    if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------client vs entity------------' ) end
    end
    if debug.list[ combatData.debug] then debug:SendDebug(combatData.debug, 'Final Damage: ' .. tostring(combatData.dmg.amount)) end

    dmg.amount = combatData.dmg.amount
 	--rust.BroadcastChat('Final Damage: ' .. tostring(func:round(dmg.amount,2)))
    return dmg, combatData
end
function PLUGIN:RangeModifier(combatData)
	local distance = tonumber(self:GetDistance(combatData.dmg.attacker.client.netUser)) --rust.BroadcastChat('Distance: '..tostring(distance).. 'm')
	local weaponRange = tonumber(rust.GetInventory(combatData.netuser).activeItem.datablock.bulletRange)
	local percRange = math.floor((100-(100*(distance/weaponRange)))+.5) --rust.BroadcastChat(tostring(percRange))
	local rangeModifier = combatData.dmg.amount*(percRange*.01)
	local crouchBonus = 0
	local perBonus = 0
 	--rust.BroadcastChat(tostring(rust.GetCharacter(combatData.netuser).stateFlags.aim))
	if rust.GetCharacter(combatData.netuser).stateFlags.movement then
		crouchBonus = (combatData.dmg.amount - rangeModifier)*.5
		perBonus = ((combatData.dmg.amount - rangeModifier)*.5)*(combatData.netuserData.attributes.per*.1)
		--[[
		rust.BroadcastChat(tostring('Crouch Bonus: ' .. crouchBonus))
		rust.BroadcastChat(tostring('Perception Bonus: ' .. perBonus))
		rust.BroadcastChat(tostring('Original Damage: ' .. combatData.dmg.amount .. '  |  Calculated Damage: ' .. combatData.dmg.amount*(percRange*.01)+crouchBonus+perBonus.. '  |  Lost Damage: ' .. (combatData.dmg.amount)-(combatData.dmg.amount*(percRange*.01)+crouchBonus+perBonus)))
		]]
	else
		perBonus = ((combatData.dmg.amount - rangeModifier)*.5)*(combatData.netuserData.attributes.per*.05)
		--rust.BroadcastChat(tostring('Original Damage: ' .. combatData.dmg.amount .. '  |  Calculated Damage: ' .. rangeModifier .. '  |  Lost Damage: ' .. combatData.dmg.amount-rangeModifier))
		--print(tostring('Original Damage: ' .. combatData.dmg.amount .. '  |  Calculated Damage: ' .. rangeModifier .. '  |  Lost Damage: ' .. combatData.dmg.amount-rangeModifier))
	end
	--[[
	print(tostring('Distance: ' .. distance .. 'm'))
	print(tostring('Original Damage: ' .. combatData.dmg.amount))
	print(tostring('Crouch Bonus: ' .. crouchBonus))
	print(tostring('Perception Bonus: ' .. perBonus ..'  @  ' ..combatData.netuserData.attributes.per.. ' perception'))
	print(tostring('Calculated Damage: ' .. combatData.dmg.amount*(percRange*.01)+crouchBonus+perBonus))
	print(tostring('Damage Loss: ' .. (combatData.dmg.amount)-(combatData.dmg.amount*(percRange*.01)+crouchBonus+perBonus)))
	]]
	combatData.dmg.amount = combatData.dmg.amount*(percRange*.01)+crouchBonus+perBonus
	return combatData.dmg.amount
end
function PLUGIN:GetCombatData(takedamage, dmg)
	local combatData = {}
	if takedamage:GetComponent("DeployableObject") then combatData['objectData'] = takedamage:GetComponent("DeployableObject") end
	if takedamage:GetComponent("StructureComponent") then combatData['structureData'] = takedamage:GetComponent("StructureComponent") end

	if dmg.amount then combatData['dmg'] = dmg --[[{['amount'] = dmg.amount,['damageTypes'] = dmg.damageTypes.value__}]] end
	if dmg.extraData then combatData['weapon'] = core.Config.weapon[tostring(dmg.extraData.dataBlock.name)] end
	if dmg.attacker.controllable then combatData['netuser'] =  dmg.attacker.client.netUser combatData['netuserData'] = char[rust.GetUserID(dmg.attacker.client.netUser)] end
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
		combatData['scenario'] = 1 --PVP
	 	--rust.BroadcastChat( 'Scenario: ' .. tostring(combatData['scenario']) )
	elseif dmg.victim.controllable and not dmg.attacker.controllable then
		combatData['scenario'] = 2 --EVP
	 	--rust.BroadcastChat( 'Scenario: ' .. tostring(combatData['scenario']) )
	elseif dmg.attacker.controllable and not dmg.victim.controllable and not combatData.entity then
		combatData['scenario'] = 3 --PVE
	 	--rust.BroadcastChat( 'Scenario: ' .. tostring(combatData['scenario']) )
	elseif dmg.attacker.controllable and (combatData.objectData or combatData.structureData) and combatData.weapon.type == 'm' then
		combatData['scenario'] = 4 --PVO & --PVS
		combatData.dmg.amount = combatData.entity.dmg           -- setting base damage for each object.
	 	--rust.BroadcastChat( 'Scenario: ' .. tostring(combatData['scenario']) )
	elseif dmg.attacker.controllable and combatData.entity then
		combatData['scenario'] = 5
	 	--rust.BroadcastChat( 'Scenario: ' .. tostring(combatData['scenario']) )
		return combatData.dmg.amount, combatData
	elseif string.find((tostring(combatData.dmg.attacker.id)), "(Metabolism)", 1, true) then
		combatData['scenario'] = 6
	 	--rust.BroadcastChat( 'Scenario: ' .. tostring(combatData['scenario']) )
		--return combatData.dmg.amount, combatData
	else
	 	--rust.BroadcastChat( 'Scenario: Invalid' )
		-- self:PrintInvalidScenario( combatData,dmg, takedamage )
		return combatData.dmg.amount, combatData
	end
	return combatData
end
function PLUGIN:OnKilled (takedamage, dmg)
	local combatData = self:GetCombatData(takedamage,dmg)
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
 	--rust.BroadcastChat( 'Thief start' )
	if thief:isThief( combatData.netuser ) and thief:hasStealth( combatData.netuser ) then
	 	--rust.BroadcastChat( 'Thief start' )
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
function PLUGIN:ActivatePerks(combatData)
	if combatData.scenario == 1 then
		for k,v in pairs(combatData.netuserData.perks) do combatData.dmg.amount = perk[k](perk, combatData) end
		for k,v in pairs(combatData.vicuserData.perks) do combatData.dmg.amount = perk[k](perk, combatData) end
	elseif combatData.scenario == 2 then
		for k,v in pairs(combatData.vicuserData.perks) do combatData.dmg.amount = perk[k](perk, combatData) end
	elseif combatData.scenario == 3 then
		for k,v in pairs(combatData.netuserData.perks) do combatData.dmg.amount = perk[k](perk, combatData) end
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
	local min,max = combatData.dmg.amount*(func:Roll(false,0.5,0.6)),combatData.dmg.amount*(func:Roll(false,0.9,1))
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
function PLUGIN:Defend(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----PLUGIN:Defend----' ) end

	if (combatData.vicuserData) then
		if (combatData.vicuserData.attributes.sta>0) then
			combatData.dmg.amount = combatData.dmg.amount-((combatData.vicuserData.attributes.sta+combatData.vicuserData.lvl)*0.1)
			if combatData.dmg.amount < 0 then combatData.dmg.amount = 0 end
		end
	end
	if (combatData.npc) and (not combatData.vicuserData) then
		if (combatData.npc.attributes.sta>0) then
			combatData.dmg.amount = combatData.dmg.amount-((combatData.npc.attributes.sta)*0.1)
			if combatData.dmg.amount < 0 then combatData.dmg.amount = 0 end
		end
	end
	return combatData.dmg.amount
end
function PLUGIN:CritCheck(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----PLUGIN:CritCheck----' ) end
    --rust.BroadcastChat('----PLUGIN:CritCheck----')
    if combatData.scenario == 1 then
        if (combatData.netuserData.attributes.agi>0) then
            local roll = func:Roll(false,0,100)
            if combatData.dmg.damageTypes.value__ == damage_melee then
                if ((math.floor(100*(combatData.netuserData.attributes.agi+combatData.netuserData.lvl)*.002)+.5) >= roll) then
                    combatData.dmg.amount = combatData.dmg.amount * 2
                    rust.InventoryNotice( combatData.vicuser, 'Critically Wounded!' )
                    rust.InventoryNotice( combatData.netuser, 'Critical Hit!' )
	                func:PlaySound(combatData.vicuser, 'vomit')
                end
            elseif combatData.dmg.damageTypes.value__ == damage_bullet then
                if ((math.floor(100*(combatData.netuserData.attributes.agi+combatData.netuserData.lvl)*.001)+.5) >= roll) then
                    combatData.dmg.amount = combatData.dmg.amount * 2
                    rust.InventoryNotice( combatData.vicuser, 'Critically Wounded!' )
                    rust.InventoryNotice( combatData.netuser, 'Critical Hit!' )
                    func:PlaySound(combatData.vicuser, 'vomit')
                end
            end
        end
    elseif combatData.scenario == 2 then
        if (combatData.npc.attributes.agi>0) then
            local roll = func:Roll(false,0,100)
            if (math.floor(100*(combatData.vicuserData.attributes.agi+combatData.vicuserData.lvl)*.002)+.5) >= roll then
                combatData.dmg.amount = combatData.dmg.amount * 2
                rust.InventoryNotice( combatData.vicuser, 'Critically Wounded!' )
                func:PlaySound(combatData.vicuser, 'vomit')
            end
        end
    elseif combatData.scenario == 3 then
        if (combatData.netuserData.attributes.agi>0) then
            local roll = func:Roll(false,0,100)
            if combatData.dmg.damageTypes.value__ == damage_melee then
                if ((math.floor(100*(combatData.netuserData.attributes.agi+combatData.netuserData.lvl)*.002)+.5) >= roll) then
                    combatData.dmg.amount = combatData.dmg.amount * 2
                    rust.InventoryNotice( combatData.netuser, 'Critical Hit!' )
                end
            elseif combatData.dmg.damageTypes.value__ == damage_bullet then
                if ((math.floor(100*(combatData.netuserData.attributes.agi+combatData.netuserData.lvl)*.001)+.5) >= roll) then
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