PLUGIN.Title = 'carbon_thief'
PLUGIN.Description = 'class thief module'
PLUGIN.Version = '0.0.2'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
	core = cs.findplugin("carbon_core") core:LoadLibrary()

	self.stealth = {}

	self.cd = {}


end

-- TODO: Add thieving xp to abilities.

function PLUGIN:ThiefInfo( netuser, cmd, args )
	local content = {
		['header'] = 'You\'re now a Thief!',
		['msg'] = 'A thief is a versatile class, capable of sneaky combat and nimble tricks. The thief is stealthy and agile, and currently the only class capable of finding and disarming many traps and picking locks. The rogue also has the ability to "sneak attack" or "backstab" enemies who are caught off-guard or taken by surprise, inflicting extra damage. The thief class is the only class able to walk in stealth mode undetectable by enemy hordes and other players.',
	}
	func:TextBox(netuser, content, cmd, args)
end

function PLUGIN:SpecThief( cmdData )
	cmdData.netuserData.stealth = false
	cmdData.netuserData.class = 'thief'
	if not cmdData.netuserData.classdata then cmdData.netuserData.classdata = {} end
	if not cmdData.netuserData.classdata.thief then
		cmdData.netuserData.classdata = {
			['thief']={
				['lvl'] = 1,
				['xp'] = 0,
				['steal'] = 5,                  -- 5% success chance
				['stealcd'] = 30,               -- 30 secs cooldown before you can steal again.
				['stealth'] = 30,               -- 30 secs stealth max.
				['stealthcd'] = 20,             -- 20 secs stealth cooldown before using it again AFTER you've unstealthed..
				['picklock'] = 10,              -- 10% succes chance to picklock a door
				['picklockfail'] = 90,          -- 90% chance to break picklock.
				['picklockcd'] = 20,            -- 20 secs cooldown before you can picklock again
				['backstab'] = 0.1,             -- 10% dmg increase when backstab.
			}
		}
	end
	char:Save( cmdData.netuser )
	local content = {
		['header'] = 'You\'re now a Thief!',
		['msg'] = 'A thief is a versatile class, capable of sneaky combat and nimble tricks. The thief is stealthy and agile, and currently the only class capable of finding and disarming many traps and picking locks. The rogue also has the ability to "sneak attack" or "backstab" enemies who are caught off-guard or taken by surprise, inflicting extra damage. The thief class is the only class able to walk in stealth mode undetectable by enemy hordes and other players.',
	}
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end

function PLUGIN:Steal( netuser, _, args )
	if self.cd[ netuser ] and self.cd[ netuser ].steal then rust.Notice( netuser, 'Stealing is still on cooldown!' ) return end
	if not self:isThief( netuser ) then rust.Notice( netuser, 'You\'re not a thief!' ) return end
	if not args[1] then rust.SendChatToUser( netuser, '/steal "name" ' ) return end
	local targname = tostring( args[1] )
	local b, vicuser = rust.FindNetUsersByName( args[1] )
	if (not b) then return rust.Notice( netuser, 'No player found with the name ' .. targname ) end
	-- Get new posistion
	local charid = rust.GetCharacter( netuser )
	if not charid then rust.Notice( netuser ,'No char.' ) return end
	local IDLocalCharacter = charid.idMain:GetComponent( "IDLocalCharacter" )
	IDLocalCharacter:set_lockMovement( false )

	local coords1 = netuser.playerClient.lastKnownPosition
	if ( coords1 ) and ( coords1.x ) and ( coords1.y ) and ( coords1.z ) then
		local coords2 = vicuser.playerClient.lastKnownPosition
		if ( coords2 ) and ( coords2.x ) and ( coords2.y ) and ( coords2.z ) then
			if ( func:Distance3D ( coords1.x, coords1.y, coords1.z, coords2.x, coords2.y, coords2.z ) <= 2 ) then
				self:StealFrom( netuser, vicuser )
				IDLocalCharacter:set_lockMovement( true )
				return
			else
				IDLocalCharacter:set_lockMovement( true )
				return
			end
		end
		rust.Notice( netuser, 'Failed to get victims coords, try again.' )
	end
	rust.Notice( netuser, 'Failed to get your coords, try again.' )
	IDLocalCharacter:set_lockMovement( true )
end

function PLUGIN:StealFrom( netuser, vicuser )
	if netuser and vicuser then
		local netdata = char:GetUserDataFromTable( netuser )
		if not netdata then Notice( netuser, 'Failed to load data, try again' ) return end
		if func:Roll( false, 100 ) > data.classdata.steal then
			self:GiveThiefXp( netuser, 100 )
			rust.Notice( netuser, 'Failed to steal!' )
			if not self.cd[ netuser ] then self.cd[ netuser ] = {} end
			self.cd[ netuser ]['steal'] = netdata.classdata.thief.stealcd
			timer.Once( netdata.classdata.thief.stealcd, function() if self.cd[ netuser ]['steal'] then self.cd[ netuser ]['steal'] = nil rust.InventoryNotice( netuser, 'Steal ready!' ) end end )
			return
		end
		local vicdata = char:GetUserDataFromTable( vicuser )
		if not vicdata then rust.Notice( netuser, 'Failed to load victems data, try again.' ) return end
		local data = econ:getBalance( vicuser )
		local bal = econ:DeConvert( data.g, data.s, data.c )
		if bal > 0 then
			local max = 1750 + (250 * netdata.classdata.thief.lvl )
			local take = func:Roll(true,  0, max )
			if take > bal/2 then take = bal/2 end               -- Take 50% when the take is higher then 50% of the vics balance.
			local data = econ:Convert( math.floor(take) )
			econ:AddBalance( netuser, data.g, data.s, data.c  )
			econ:RemoveBalance( vicuser, data.g, data.s, data.c  )
			local msg = tostring('Gold: ' .. data.g .. ' Silver: ' .. data.s .. ' Copper: ' .. data.c)
			rust.Notice( vicuser, netuser.displayName .. ' stole ' .. tostring( msg ) .. ' from you!')
			rust.Notice( netuser, 'You stole ' .. tostring( msg ) .. ' from ' .. vicuser.displayName)
		else
			rust.Notice( netuser, vicuser.displayName .. ' has no money!' )
		end

		-- Item steal
		if netdata.classdata.thief.lvl >= 10 then
			local netinv = rust.GetInventory( netuser )
			if not netinv then rust.Notice( netuser, 'Failed to load inventory, try again.' ) return end
			local vicinv = rust.GetInventory( vicuser )
			if not vicinv then rust.Notice( netuser, 'Failed to load victims inventory, try again.' ) return end

			local roll = func:Roll( false, 100 )
			roll = 1
			if roll < netdata.classdata.thief.steal then
				local max
				local min
				if netdata.classdata.thief.lvl < 20 then
					min = 1
					max = 2
				elseif netdata.classdata.thief.lvl < 30 then
					min = 1
					max = 2
				elseif netdata.classdata.thief.lvl < 40 then
					min = 2
					max = 4
				elseif netdata.classdata.thief.lvl >= 40 then
					min = 3
					max = 5
				else
					min = 1
					max = 1
				end
				local total = func:Roll( true, min, max )
				local i = 0
				local y = 0
				while i < total do
					local rnd = func:Roll( true, 0, 29 )
					if y >= 35 then break end
					local b, item = vicinv:GetItem(rnd)
					if b then
						vicinv:RemoveItem( rnd )
						local uses = item.uses
						local con = false
						if item.condition then con = item.condition end
						local db = item.datablock
						local split = db._splittable
						for i = 0, 35 do
							local c, _ = netinv:GetItem( i )
							if not c then
								netinv:AddItemAmount( db, 1 )
								b, item = netinv:GetItem( i )
								if b then
									if con then
										item.condition = con
									end
									if uses then
										item.uses = uses
									end
								end
								if split then
									rust.InventoryNotice( netuser, tostring('+' .. uses .. ' ' .. db.name ))
									rust.InventoryNotice( vicuser, tostring('-' .. uses .. ' ' .. db.name ))
								else
									rust.InventoryNotice( netuser, tostring('+ 1 ' .. db.name ))
									rust.InventoryNotice( vicuser, tostring('- 1 ' .. db.name ))

								end
								break
							end
						end
						i = i + 1
					end
					y = y + 1
				end
			end
		end
		self:GiveThiefXp( netuser, 40 )
		if self:hasStealth( netuser ) then self:Unstealth( netuser ) end
		if not self.cd[ netuser ] then self.cd[ netuser ] = {} end
		self.cd[ netuser ]['steal'] = netdata.classdata.thief.stealcd
		timer.Once( netdata.classdata.thief.stealcd, function() if self.cd[ netuser ]['steal'] then self.cd[ netuser ]['steal'] = nil rust.InventoryNotice( netuser, 'Steal ready!' ) end end )
	end
end

function PLUGIN:cmdStealth( netuser )
	if not self:isThief( netuser ) then rust.Notice( netuser, 'You\'re not a thief!' ) return end
	if self.cd[netuser] and self.cd[ netuser ]['stealth'] then rust.Notice( netuser, 'Stealth is still on cooldown! ' ) return end
	if self:hasStealth( netuser ) then self:Unstealth( netuser ) else self:Stealth( netuser ) end
end

function PLUGIN:Stealth( netuser )
	local data = char:GetUserDataFromTable( netuser )
	if not data then return end
	local netuserID = rust.GetUserID( netuser )
	local charid = rust.GetCharacter( netuser )
	if not charid then rust.Notice( netuser ,'No char.' ) return end
	local IDLocalCharacter = charid.idMain:GetComponent( "IDLocalCharacter" )
	IDLocalCharacter:set_lockMovement( true )
	data.stealth = true

	local inv = rust.GetInventory( netuser )
	if not inv then rust.Notice( netuser, 'Inventory not found, try again!' ) return end
	local tbl = {}
	local con = 0
	local b, helmet = inv:GetItem( 36 )
	if b then
		con = helmet.condition
		helmet = helmet.datablock
		tbl[ 'helmet' ] = {
			['item'] = helmet,
			['con'] = con,
			['slot'] = 36
		}
		inv:RemoveItem( 36 )
	end
	local b, vest = inv:GetItem( 37 )
	if b then
		con = vest.condition
		vest = vest.datablock
		tbl[ 'vest' ] = {
			['item'] = vest,
			['con'] = con,
			['slot'] = 37
		}
		inv:RemoveItem( 37 )
	end
	local b, pants = inv:GetItem( 38 )
	if b then
		con = pants.condition
		pants = pants.datablock
		tbl[ 'pants' ] = {
			['item'] = pants,
			['con'] = con,
			['slot'] = 38
		}
		inv:RemoveItem( 38 )
	end
	local b, boots = inv:GetItem( 39 )
	if b then
		con = boots.condition
		boots = boots.datablock
		tbl[ 'boots' ] = {
			['item'] = boots,
			['con'] = con,
			['slot'] = 39
		}
		inv:RemoveItem( 39 )
	end
	self.stealth[ netuserID ] = tbl
	local helmet = rust.GetDatablockByName( 'Invisible Helmet' )
	local vest = rust.GetDatablockByName( 'Invisible Vest' )
	local pants = rust.GetDatablockByName( 'Invisible Pants' )
	local boots = rust.GetDatablockByName( 'Invisible Boots' )
	local pref = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor )
	local inv = rust.GetInventory( netuser )
	inv:AddItemAmount( helmet, 1, pref )
	inv:AddItemAmount( vest, 1, pref )
	inv:AddItemAmount( pants, 1, pref )
	inv:AddItemAmount( boots, 1, pref )
	rust.InventoryNotice( netuser, '+ Stealth' )
	timer.Once( data.classdata.thief.stealth, function() if self:hasStealth( netuser ) then self:Unstealth( netuser ) end end)
end

function PLUGIN:Unstealth( netuser )
	local data = char:GetUserDataFromTable( netuser )
	if not data then return end
	if not data.stealth then rust.Notice( netuser, 'You\'re not stealth!' ) return end
	local netuserID = rust.GetUserID( netuser )
	local charid = rust.GetCharacter( netuser )
	if not charid then rust.Notice( netuser ,'No char.' ) return end
	local IDLocalCharacter = charid.idMain:GetComponent( "IDLocalCharacter" )
	IDLocalCharacter:set_lockMovement( false )
	data.stealth = false

	local inv = rust.GetInventory( netuser )
	if not inv then rust.Notice( netuser, 'Inventory not found, try again!' ) return end
	local pref = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor )

	-- Deleting Invisible items
	local a,b,c,d=rust.GetDatablockByName('Invisible Helmet'),rust.GetDatablockByName('Invisible Vest'),rust.GetDatablockByName('Invisible Pants'),rust.GetDatablockByName('Invisible Boots')
	while true do local f=inv:FindItem(a)if f then inv:RemoveItem(f)else break end end
	while true do local f=inv:FindItem(b)if f then inv:RemoveItem(f)else break end end
	while true do local f=inv:FindItem(c)if f then inv:RemoveItem(f)else break end end
	while true do local f=inv:FindItem(d)if f then inv:RemoveItem(f)else break end end
	-- inv:RemoveItem( 36 )inv:RemoveItem( 37 )inv:RemoveItem( 38 )inv:RemoveItem( 39 )
	if self.stealth[ netuserID ] then
		for _, v in pairs ( self.stealth[netuserID] ) do
			local datablock = v.item
			inv:AddItemAmount( datablock, 1, pref )
			local b, item = inv:GetItem( v.slot )
			if b then
				item:SetCondition( v.con )
			end
		end
	end
	self.stealth[ netuserID ] = nil
	rust.InventoryNotice( netuser, '- Stealth' )
	if not self.cd[netuser] then self.cd[netuser]={} end
	self.cd[netuser]['stealth'] = true
	timer.Once( data.classdata.thief.stealthcd, function() if self.cd[ netuser ]['stealth'] then rust.InventoryNotice( netuser, 'Stealth ready!' )self.cd[ netuser ]['stealth'] = nil  end end )
end

-- TODO: Test this!
function PLUGIN:PickLock( netuser, ownerID, door )
	if self.cd[netuser] and self.cd[ netuser ]['picklock'] then rust.SendChatToUser( netuser, core.sysname, 'Picklock is still on cooldown! ' ) return false end
	local inv = rust.GetInventory( netuser )
	if not inv then return false end
	local netuserData = char[ rust.GetUserID( netuser )]
	if not netuserData then rust.SendChatToUser( netuser , core.sysname, '404: netuserData not found!' )return false end
	local b, item = inv:GetItem( 35 )
	if not b then rust.SendChatToUser( netuser, 'Thief Master', 'You need to have a Handmade Picklock in slot 6 to able to picklock!' ) return false end
	if item.datablock.name ~= 'Handmade Lockpick' then return false end
	if not char[ownerID] then rust.SendChatToUser( netuser, core.sysname, 'Player is offline, you cannot picklock doors from offline players.' ) return false end
	local vicdata = char[ownerID]
	local b, targuser = rust.FindNetUsersByName( vicdata.name )
	if not b then rust.SendChatToUser( netuser, core.sysname, 'Player is offline, you cannot picklock doors from offline players.' ) return false end
	rust.Notice( targuser, netuser.displayName .. ' tried to picklock your door! Did he succeed?' )
	local s = tostring(door) local f  = string.find(s, "(Clone)" ) - 2	local s2 = string.sub(s, 0, f )	local roll = func:Roll( false, 100 )
	local doormod = 0 if s2 == 'MetalDoor' then doormod = 0.25 end
	if roll <= (netuserData.classdata.thief.picklock * (1+(0.02 * netuserData.attributes.luc )) * (1+doormod)) then
		rust.InventoryNotice( netuser, 'You have succesfully picklocked this door! Be aware, the owner is warned.' )
		self:GiveThiefXp( netuser, 50 )
		if not self.cd[netuser] then self.cd[netuser]={} end
		self.cd[netuser]['picklock'] = true
		timer.Once( netuserData.classdata.thief.picklockcd, function() if self.cd[ netuser ]['picklock'] then rust.InventoryNotice( netuser, 'Picklock ready!' )self.cd[ netuser ]['picklock'] = nil  end end )
		return true
	else
		rust.InventoryNotice( netuser, 'Picklock Failed.' )
	end
	self:GiveThiefXp( netuser, 20 )
	roll = func:Roll( false, 100 )
	if roll <= (netuserData.classdata.thief.picklockfail * (1+(0.02 * netuserData.attributes.luc )) * (1-doormod)) then rust.SendChatToUser( netuser, 'Handmade Lockpick broke!' ) inv:RemoveItem( 35 ) end
	if not self.cd[netuser] then self.cd[netuser]={} end
	self.cd[netuser]['picklock'] = true
	timer.Once( netuserData.classdata.thief.picklockcd, function() if self.cd[ netuser ]['picklock'] then rust.InventoryNotice( netuser, 'Picklock ready!' )self.cd[ netuser ]['picklock'] = nil  end end )
	return false
end

function PLUGIN:StealthCheck( takedamage, damage )
	if damage.victim.controllable then
		if thief:hasStealth( damage.victim.client.netUser ) then
			if damage.attacker.controllable then
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
	return damage.amount
end

function PLUGIN:GiveThiefXp( netuser, xp )
	local data = char:GetUserDataFromTable( netuser )
	if not data then rust.Notice( netuser, 'Player data not found, try relogging!' ) return end
	if data.classdata.thief.lvl < 20 then
		if ((data.classdata.thief.xp + xp ) >= core.Config.level.class[ tostring( data.classdata.thief.lvl+1 )]) then
			func:Notice(combatData.netuser,'✛','You are now a level ' .. tostring(level) .. ' thief!',5)
			data.classdata.thief.lvl = data.classdata.thief.lvl+1                           -- Max lvl 20
			data.classdata.thief.steal = data.classdata.thief.steal + 3                     -- Max 65% success
			data.classdata.thief.stealcd = data.classdata.thief.stealcd - 1                 -- Max 20 sec cd
			data.classdata.thief.stealth = data.classdata.thief.stealth + 1                 -- Max 50 sec Stealth
			data.classdata.thief.stealthcd = data.classdata.thief.stealthcd - 0.5           -- Max 10 sec Stealth cooldown
			data.classdata.thief.picklock = data.classdata.thief.picklock + 1               -- Max 30% change to picklock a door
			data.classdata.thief.picklockfail = data.classdata.thief.picklockfail - 3       -- Max 30% chance to break lockpick
			data.classdata.thief.picklockcd = data.classdata.thief.picklockcd - 0.5         -- Max 10 sec Picklock Cooldown
			data.classdata.thief.backstab = data.classdata.thief.backstab + 0.07            -- Max 140% Damage increase.
		end
		data.classdata.thief.xp = data.classdata.thief.xp + xp
		rust.InventoryNotice( netuser, '+' .. tostring(xp) .. ' thieving xp' )
		char:Save( netuser )
	end
end

function PLUGIN:hasStealth( netuser )
	if not self:isThief( netuser ) then return false end
	local data = char:GetUserDataFromTable( netuser )
	if not data then return false end
	if data.stealth then return true else return false end
end

function PLUGIN:isThief( netuser )
	local data = char:GetUserDataFromTable( netuser )
	if not data then return false end
	if data.class == 'thief' then return true else return false end
end