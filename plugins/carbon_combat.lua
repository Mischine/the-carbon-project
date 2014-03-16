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
	-- Stealth check
	rust.BroadcastChat( 'Begin process' )
	if damage.victim.controllable then
		if thief:hasStealth( damage.victim.client.netUser ) then
			if damage.attacker.controllable then   -- PLAYER
				thief:Unstealth( damage.victim.client.netUser )
				damage.amount = damage.amount*1.5
			else
				local charid = rust.GetCharacter( damage.victim.client.netUser )
				if charid then
					local IDLocalCharacter = charid.idMain:GetComponent( "IDLocalCharacter" )
					IDLocalCharacter:set_lockMovement( false )
					timer.Once( 0.03, function () IDLocalCharacter:set_lockMovement( true ) end)
					rust.BroadcastChat( cancelagro )
				end
			end
		end
	end
	local combatData = {}                     -- Define combatData so that it wont turn global. I cant local it in the if statement, cus then I cannot use it outside of it.
	local dmg                                               -- Define dmg / We need to change this. Because I dont want to flood the server with people shooting dead NPC/Players.
	local status = tostring( damage.status )

	if ( status ~= IsDead ) then                            -- Prevent calculating even if they're dead. Less CPU usage. BETTAH PERFORMANCE!
        dmg, combatData = self:CombatDamage( takedamage, damage )
	end

	if ((combatData.bodyPart) and ( not combatData.npc )) then
	 	rust.BroadcastChat( combatData.bodyPart )
	end

	if dmg.amount >= takedamage.health then
		dmg.status = LifeStatus.WasKilled
	end

	if dmg.amount <= 0 then                                 -- Checks if they're proficient with the weapon.
		dmg.status = LifeStatus.IsAlive
		rust.BroadcastChat( cancelagro )
	end
	if dmg.amount >= 100 then
		dmg.status = LifeStatus.WasKilled
	end
	if status == WasKilled then
		if dmg.amount < takedamage.health then              -- Revive when they are not actually dead. So they wont die with 25 hp. =) | I think even will counter headshots.
			dmg.status = LifeStatus.IsAlive
		end
	end
end


local _BodyParts = cs.gettype( "BodyParts, Facepunch.HitBox" )
local _GetNiceName = util.GetStaticMethod( _BodyParts, "GetNiceName" )
function PLUGIN:CombatDamage (takedamage, dmg)
	local randMultiplier = func:Roll(false,0.50123456789,0.59876543210) dmg.amount = func:Roll(false,dmg.amount*randMultiplier,dmg.amount)

    local combatData = {}
    if dmg.amount then combatData['dmg'] = {['amount'] = dmg.amount,['damageTypes'] = dmg.damageTypes.value__} end
    if dmg.extraData then combatData['weapon'] = core.Config.weapon[tostring(dmg.extraData.dataBlock.name)] end
    if dmg.attacker.controllable then combatData['netuser'] =  dmg.attacker.client.netUser combatData['netuserData'] = char[rust.GetUserID(dmg.attacker.client.netUser)] end
    if dmg.victim.controllable then combatData['vicuser'] = dmg.victim.client.netUser combatData['vicuserData'] = char[rust.GetUserID(dmg.victim.client.netUser)] end
    if dmg.bodyPart ~= nil then if(dmg.bodyPart:GetType().Name == "BodyPart" and _GetNiceName(dmg.bodyPart) ~= nil) then combatData['bodyPart'] = _GetNiceName(dmg.bodyPart) end end
    if combatData.netuser then combatData['debug'] = combatData.netuser.displayName elseif (not (combatData.netuser) and (combatData.vicuser )) then combatData['debug'] = combatData.vicuser.displayName end

	local npc = core.Config.npc

	func:Repair( combatData.netuser, 1 )
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
        rust.BroadcastChat( 'Scenario 1 chooser....' )
    elseif dmg.victim.controllable and not dmg.attacker.controllable then
        combatData['scenario'] = 2 --npc vs client
    elseif dmg.attacker.controllable and not dmg.victim.controllable then
        combatData['scenario'] = 3 --client vs npc
    end

    --BEGIN BATTLE SYSTEM
    if combatData.scenario == 1 then
	    --[[ TODO: FIX ARMOR REQUIREMENTS
	    local controllable = combatData.netuser.playerClient.controllable
	    local ProtectionTakeDamage = controllable:GetComponent( "ProtectionTakeDamage" )
	    local acValue = ProtectionTakeDamage.GetArmorValues
	    rust.BroadcastChat(tostring(acValue))
	    --]]
		if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------client vs client------------' ) end
		--rust.BroadcastChat('------------client vs client------------')
		rust.BroadcastChat( 'Scenario 1 start.' )
		combatData.dmg.amount = self:WeaponSkill(combatData)
		if combatData.dmg.amount == 0 then return 0 end
		combatData.dmg.amount = self:PartyCheck( combatData )
		if combatData.dmg.amount == 0 then return 0 end
		combatData.dmg.amount = self:GuildCheck( combatData )
		if combatData.dmg.amount == 0 then return 0 end
		combatData.dmg.amount = self:DmgModifier(combatData) --modifies based on configs for player, weapon, npc, etc..
		combatData.dmg.amount = self:DmgRandomizer(combatData) --randomizes the damage output to create realism!
		combatData.dmg.amount = self:Attack(combatData) --+attributes, +skills,  function:perks, +/- dp.,
		combatData.dmg.amount = self:CritCheck(combatData) --+attributes, +skills,  function:perks, +/- dp.,
		combatData.dmg.amount = self:GuildAttack(combatData) --all guild offensive calls and modifiers
		rust.BroadcastChat( 'Before Perks' )
		for k,v in pairs(combatData.netuserData.perks) do combatData.dmg.amount = perk[k](perk, combatData) end
		rust.BroadcastChat( 'After ThiefMod' )
		--combatData.dmg.amount = self:Defend(combatData) --attributes, skills, perks, dp, dodge
		rust.BroadcastChat( 'Before ThiefMod' )
		combatData.dmg.amount = self:ThiefMod( combatData )
		combatData.dmg.amount = self:GuildDefend(combatData)--all guild DEFENSIVE calls and modifiers
    elseif combatData.scenario == 2 then
		if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------pve vs client------------' ) end
		--rust.BroadcastChat('------------pve vs client------------')
		combatData.dmg.amount = self:DmgModifier(combatData) --modifies based on configs for player, weapon, npc, etc..
		combatData.dmg.amount = self:DmgRandomizer(combatData) --randomizes the damage output to create realism!
		combatData.dmg.amount = self:Attack(combatData) --+attributes, +skills, +/- perks, +/- dp.,
		combatData.dmg.amount = self:CritCheck(combatData) --+attributes, +skills,  function:perks, +/- dp.,
		for k,v in pairs(combatData.vicuserData.perks) do combatData.dmg.amount = perk[k](perk, combatData) end
		combatData.dmg.amount = self:GuildDefend(combatData)--all guild DEFENSIVE calls and modifiers
		combatData.dmg.amount = self:Defend(combatData) --attributes, skills, perks, dp, dodge
    elseif combatData.scenario == 3 then
		if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '------------client vs pve------------' ) end
		--rust.BroadcastChat('------------client vs pve------------')
		combatData.dmg.amount = self:WeaponSkill(combatData)
		if combatData.dmg.amount == 0 then return 0 end
		combatData.dmg.amount = self:DmgModifier(combatData) --modifies based on config s for player, weapon, npc, etc...
		combatData.dmg.amount = self:DmgRandomizer(combatData) --randomizes the damage output to create realism!
		combatData.dmg.amount = self:Attack(combatData) --+attributes, +skills, +/- perks, +/- dp.
		combatData.dmg.amount = self:CritCheck(combatData) --+attributes, +skills,  function:perks, +/- dp.
		for k,v in pairs(combatData.netuserData.perks) do combatData.dmg.amount = perk[k](perk, combatData) end
		combatData.dmg.amount = self:GuildAttack(combatData) --all guild offensive calls and modifiers
    end
    if debug.list[ combatData.debug] then debug:SendDebug(combatData.debug, 'Final Damage: ' .. tostring(combatData.dmg.amount)) end
    --rust.BroadcastChat('Final Damage: ' .. tostring(combatData.dmg.amount))
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