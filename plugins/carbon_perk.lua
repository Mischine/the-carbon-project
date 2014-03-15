PLUGIN.Title = 'carbon_perk'
PLUGIN.Description = 'perk module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
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
    if ((combatData.vicuser) and (combatData.vicuser ~= combatData.netuser) and (oodinvicuserData.perks.Stoneskin)) then
        if (vicuserData.perk.Stoneskin.lvl > 0) then
            if (vicuserData.perk.Stoneskin.lvl == 1) then
                damage = tonumber(damage - (damage*.05))
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 2) then
                damage = tonumber(damage - (damage*.10))
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 3) then
                damage = tonumber(damage - (damage*.15))
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 4) then
                damage = tonumber(damage - (damage*.20))
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 5) then
                damage = tonumber(damage - (damage*.25))
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
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
            if ((combatData.vicuserData.perks.parry == 1) and (roll <= 3)) then
                damage = 0
                rust.Notice('PARRIED')
                self:GiveTimedBuff( combatData.vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((combatData.vicuserData.perks.parry == 2) and (roll <= 6)) then
                damage = 0
                rust.Notice('PARRIED')
                self:GiveTimedBuff( combatData.vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((combatData.vicuserData.perks.parry == 3) and (roll <= 9)) then
                damage = 0
                rust.Notice('PARRIED')
                self:GiveTimedBuff( combatData.vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((combatData.vicuserData.perks.parry == 4) and (roll <= 12)) then
                damage = 0
                rust.Notice('PARRIED')
                self:GiveTimedBuff( combatData.vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ combatData.netuser.displayName ] then rust.SendChatToUser( debug.list[ combatData.netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((combatData.vicuserData.perks.parry == 5) and (roll <= 15)) then
                damage = 0
                rust.Notice('PARRIED')
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
	if buff == 'ParryCrit' then
	    if not char[ vicuserID ].buffs['ParryCrit'] then
	        char[ vicuserID ].buffs['ParryCrit']=true
	        timer.Once( time, function()
	            if( char[ vicuserID ].buffs[ buff ] ) then char[ vicuserID ].buffs[ buff ] = nil end
	        end )
	    end
	end
end