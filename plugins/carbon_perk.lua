PLUGIN.Title = 'carbon_perk'
PLUGIN.Description = 'perk module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end
function PLUGIN:knockback(combatData)
	-- Get a function that gives us the ground at a particular position.
	--
	-- public static bool GetGroundInfoNavMesh(Vector3 startPos, out Vector3 pos)
	--
	rust.BroadcastChat('startfindground')

	local pos = new(UnityEngine.Vector3)
	pos.x = 396.3525390625
	pos.y = 371.41613769531
	pos.z = -4756.615234375

	local RefParam2 = cs.gettype("UnityEngine.Vector3&, UnityEngine" )
	--rust.SendChatToUser( combatData.netuser, "REFERENCE TYPE: " .. tostring(RefTypeA))
	local _GetGroundInfoNavMesh = util.FindOverloadedMethod( Rust.TransformHelpers, "GetGroundInfoNavMesh", bf.public_static, { pos, RefTypeA } )

	-- Convert from "userdata" to LUA function
	cs.registerstaticmethod( "tmp", _GetGroundInfoNavMesh )
	local GetGroundInfoNavMesh = tmp
	tmp = nil

	local boolResult, refParam2Result = GetGroundInfoNavMesh( pos )
	rust.BroadcastChat(refParam2Result)
end

function PLUGIN:rage(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----perk:rage----' ) end
	if (combatData.vicuserData) and (combatData.vicuserData.perks.rage) and (combatData.dmg.attacker) then
		local rageNotice = function(a,b) rust.Notice(combatData.vicuser, 'Rage!',(a*b)) end
		rust.BroadcastChat(combatData.bodyPart)
		if( char[ combatData.vicuserData.id ].buffs[ 'Rage' ] ) then
			if combatData.bodyPart == 'head' then rageNotice:destroy() char[ combatData.vicuserData.id ].buffs[ 'Rage' ] = nil rust.BroadcastChat('rage: ended HEADSHOT!')  return combatData.dmg.amount end
			rust.BroadcastChat('rage: Has Rage, set damage to 0')
			combatData.dmg.amount = 0
			return combatData.dmg.amount
		end
		local function rage(a,b,combatData)
			if rust.GetInventory( combatData.vicuser ).activeItem then
				local activeItem = rust.GetInventory( combatData.vicuser ).activeItem
				local returnCondition = activeItem.condition
				local returnUses = activeItem.uses
				timer.Repeat(a, b, function() activeItem:SetCondition(returnCondition) activeItem.uses = returnUses end)
			end
			local time = a*b
			-- local rageNotice = func:Notice(combatData.vicuser,'☣','Rage!',(b*a))
			rageNotice(a,b)
		end
		if (combatData.vicuserData.perks.rage > 0) then
			if debug.list[ combatData.vicuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.vicuser.displayName ].targnetuser,'PERK RAGE: ' .. tostring(combatData.dmg.amount)) end
			local roll = func:Roll(true,0,100)
			rust.BroadcastChat(tostring(roll))
			if ((combatData.vicuserData.perks.rage == 1) and (roll <= 3)) then
				rage(0.25, 20, combatData)
			elseif ((combatData.vicuserData.perks.rage == 2) and (roll <= 6)) then
				rage(0.25, 40, combatData)
			elseif ((combatData.vicuserData.perks.rage == 3) and (roll <= 9)) then
				rage(0.25, 60, combatData)
			elseif ((combatData.vicuserData.perks.rage == 4) and (roll <= 12)) then
				rage(0.25, 80, combatData)
			elseif ((combatData.vicuserData.perks.rage == 5) and (roll <= 15)) then
				rage(0.25, 100, combatData)
			end
		end
	end
	return combatData.dmg.amount
end
function PLUGIN:disarm(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----perk:disarm----' ) end
	local damage = combatData.dmg.amount
	--[[
	rust.BroadcastChat('disarm')
	--TODO: SET UP DISARM PERK % CHANCE TO DISARM WHEN YOU HIT THE PLAYERS HANDS
	local vicuser = dmg.victim.client.netUser
	local controllable = vicuser.playerClient.controllable
	local Inventory = controllable:GetComponent( "Inventory" )
	local activeItem = Inventory.activeItem
	func:Notice(vicuser,'»','You have been disarmed!',5)
	Inventory:DeactivateItem()
--]]
	if ((combatData.vicuser) and (combatData.netuser) and (combatData.netuserData.perks.disarm)) then
		local Inventory = rust.GetInventory( combatData.vicuser ) -- This is more reliable.
		local disarmPart = {'hand', 'wrist','bicep'}
		if Inventory.activeItem and func:CheckBodyPart( combatData.bodyPart, disarmPart ) then
			if (combatData.netuserData.perks.disarm > 0) then
				local roll = func:Roll(true,0,100)
				if ((combatData.netuserData.perks.disarm == 1) and (roll <= 3)) then
					func:Notice(combatData.vicuser,'☓','You have been disarmed by '.. combatData.netuser.displayName,3)
					func:Notice(combatData.netuser,'✓','You have disarmed ' .. combatData.vicuser.displayName,3)
					Inventory:DeactivateItem()
					if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK DISARM: ' .. tostring(damage)) end
				elseif ((combatData.netuserData.perks.disarm == 2) and (roll <= 6)) then
					func:Notice(combatData.vicuser,'☓','You have been disarmed by '.. combatData.netuser.displayName,3)
					func:Notice(combatData.netuser,'✓','You have disarmed ' .. combatData.vicuser.displayName,3)
					Inventory:DeactivateItem()
					if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK DISARM: ' .. tostring(damage)) end
				elseif ((combatData.netuserData.perks.disarm == 3) and (roll <= 9)) then
					func:Notice(combatData.vicuser,'☓','You have been disarmed by '.. combatData.netuser.displayName,3)
					func:Notice(combatData.netuser,'✓','You have disarmed ' .. combatData.vicuser.displayName,3)
					Inventory:DeactivateItem()
					if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK DISARM: ' .. tostring(damage)) end
				elseif ((combatData.netuserData.perks.disarm == 4) and (roll <= 12)) then
					func:Notice(combatData.vicuser,'☓','You have been disarmed by '.. combatData.netuser.displayName,3)
					func:Notice(combatData.netuser,'✓','You have disarmed ' .. combatData.vicuser.displayName,3)
					Inventory:DeactivateItem()
					if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK DISARM: ' .. tostring(damage)) end
				elseif ((combatData.netuserData.perks.disarm == 5) and (roll <= 15)) then
					func:Notice(combatData.vicuser,'☓','You have been disarmed by '.. combatData.netuser.displayName,3)
					func:Notice(combatData.netuser,'✓','You have disarmed ' .. combatData.vicuser.displayName,3)
					Inventory:DeactivateItem()
					if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK DISARM: ' .. tostring(damage)) end
				end
			end
		end
	end
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( 'Disarmed the victim!' )) end
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( damage )) end
	return damage
end

function PLUGIN:stoneskin(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----perk:stoneskin----' ) end
	local damage = combatData.dmg.amount
    if ((combatData.vicuser) and (combatData.vicuser ~= combatData.netuser) and (combatData.vicuserData.perks.stoneskin)) then
        if (combatData.vicuserData.perks.stoneskin > 0) then
            if (combatData.vicuserData.perks.stoneskin == 1) then
                damage = tonumber(damage - (damage*.05))
            elseif (combatData.vicuserData.perks.stoneskin == 2) then
                damage = tonumber(damage - (damage*.10))
            elseif (combatData.vicuserData.perks.stoneskin == 3) then
                damage = tonumber(damage - (damage*.15))
            elseif (combatData.vicuserData.perks.stoneskin == 4) then
                damage = tonumber(damage - (damage*.20))
           elseif (combatData.vicuserData.perks.stoneskin == 5) then
                damage = tonumber(damage - (damage*.25))
            end
        end
    end
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( damage )) end
    return damage
end

function PLUGIN:parry(combatData)
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, '----perk:parry----' ) end
	--CRITICAL HIT CHECK
	local damage = combatData.dmg.amount
	if( char[ combatData.netuserData.id ].buffs[ 'ParryCrit' ]) then
		damage = combatData.dmg.amount * 2
		rust.InventoryNotice( combatData.netuser, 'Critical Hit!' )
		char[ combatData.netuserData.id ].buffs[ 'ParryCrit' ] = nil
		return damage
	end
    if ((combatData.vicuser) and (combatData.vicuserData.perks.parry)) then
        if (combatData.vicuserData.perks.parry > 0) then
            local roll = func:Roll(true,0,100)
            rust.BroadcastChat(tostring(roll))
            if ((combatData.vicuserData.perks.parry == 1) and (roll <= 3)) then
                damage = 0
                func:Notice(combatData.netuser,'☓','Your attack was parried by '.. combatData.vicuser.displayName,3)
                func:Notice(combatData.vicuser,'✓','You parried ' .. combatData.netuser.displayName,3)
                self:GiveTimedBuff( combatData.vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((combatData.vicuserData.perks.parry == 2) and (roll <= 6)) then
                damage = 0
                func:Notice(combatData.netuser,'☓','Your attack was parried by '.. combatData.vicuser.displayName,3)
                func:Notice(combatData.vicuser,'✓','You parried ' .. combatData.netuser.displayName,3)
                self:GiveTimedBuff( combatData.vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((combatData.vicuserData.perks.parry == 3) and (roll <= 9)) then
                damage = 0
                func:Notice(combatData.netuser,'☓','Your attack was parried by '.. combatData.vicuser.displayName,3)
                func:Notice(combatData.vicuser,'✓','You parried ' .. combatData.netuser.displayName,3)
                self:GiveTimedBuff( combatData.vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((combatData.vicuserData.perks.parry == 4) and (roll <= 12)) then
                damage = 0
                func:Notice(combatData.netuser,'☓','Your attack was parried by '.. combatData.vicuser.displayName,3)
                func:Notice(combatData.vicuser,'✓','You parried ' .. combatData.netuser.displayName,3)
                self:GiveTimedBuff( combatData.vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((combatData.vicuserData.perks.parry == 5) and (roll <= 15)) then
                damage = 0
                func:Notice(combatData.netuser,'☓','Your attack was parried by '.. combatData.vicuser.displayName,3)
                func:Notice(combatData.vicuser,'✓','You parried ' .. combatData.netuser.displayName,3)
                self:GiveTimedBuff( combatData.vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            end
        end
    end
	if debug.list[ combatData.debug] then debug:SendDebug( combatData.debug, tostring( damage )) end
    return damage
end

--PLUGIN:GiveTimedBuff
function PLUGIN:GiveTimedBuff( vicuserID, time, buff )
	if not char[ vicuserID ].buffs[buff] then
		char[ vicuserID ].buffs[buff]=true
		timer.Once( time, function()
			if( char[ vicuserID ].buffs[ buff ] ) then char[ vicuserID ].buffs[ buff ] = nil end
		end )
	end
end