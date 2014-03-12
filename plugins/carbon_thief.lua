PLUGIN.Title = 'carbon_thief'
PLUGIN.Description = 'class thief module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
	core = cs.findplugin("carbon_core") core:LoadLibrary()

	self.stealth = {}

	self:AddChatCommand( 'stealth', self.Stealth )
	self:AddChatCommand( 'unstealth', self.Unstealth )
end

function PLUGIN:ThiefInfo( netuser, cmd, args )
	local content = {
		['header'] = 'You\'re now a Thief!',
		['msg'] = 'A thief is a versatile class, capable of sneaky combat and nimble tricks. The thief is stealthy and agile, and currently the only class capable of finding and disarming many traps and picking locks. The rogue also has the ability to "sneak attack" or "backstab" enemies who are caught off-guard or taken by surprise, inflicting extra damage. The thief class is the only class able to walk in stealth mode undetectable by enemy hordes and other players.',
	}
	func:TextBox(netuser, content, cmd, args)
end

function PLUGIN:SpecThief( netuser, cmd, args )
	local data = char:GetUserData( netuser )
	if not data then return end
	data.stealth = false
	data.class = 'thief'
	local content = {
		['header'] = 'You\'re now a Thief!',
		['msg'] = 'A thief is a versatile class, capable of sneaky combat and nimble tricks. The thief is stealthy and agile, and currently the only class capable of finding and disarming many traps and picking locks. The rogue also has the ability to "sneak attack" or "backstab" enemies who are caught off-guard or taken by surprise, inflicting extra damage. The thief class is the only class able to walk in stealth mode undetectable by enemy hordes and other players.',
	}
	func:TextBox(netuser, content, cmd, args)
end

function PLUGIN:Steal( netuser, cmd, args )
	if not args[1] then rust.SendChatToUser( netuser, '/steal "name" ' ) return end
	local targname = util.QuoteSave( args[1] )
	local b, vicuser = rust.FindNetUsersByName( args[1] )
	if (not b) then return rust.Notice( netuser, 'No player found with the name ' .. targname ) end
	local coords1 = netuser.playerClient.lastKnownPosition
	if ( coords1 ) and ( coords1.x ) and ( coords1.y ) and ( coords1.z ) then
		local coords2 = vicuser.playerClient.lastKnownPosition
		if ( coords2 ) and ( coords2.x ) and ( coords2.y ) and ( coords2.z ) then
			if ( func:Distance3D ( coords1.x, coords1.y, coords1.z, coords2.x, coords2.y, coords2.z ) <= 1.5 ) then
				self:StealFrom( netuser, vicuser )
			end
		end
		rust.Notice( netuser, 'Failed to get victims coords, try again.' )
	end
	rust.Notice( netuser, 'Failed to get your coords, try again.' )
end

function PLUGIN:StealFrom( netuser, vicuser )
	-- TODO : Finish stealing from. Make a CFG. Ask mischa what we want for Thief CFG.
end

function PLUGIN:Stealth( netuser )
	local data = char:GetUserData( netuser )
	if not data then return end
	if data.stealth then rust.Notice( netuser, 'You\'re already stealth!' ) return end
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
	local invitem1 = inv:AddItemAmount( helmet, 1, pref )
	local invitem2 = inv:AddItemAmount( vest, 1, pref )
	local invitem3 = inv:AddItemAmount( pants, 1, pref )
	local invitem4 = inv:AddItemAmount( boots, 1, pref )
	rust.InventoryNotice( netuser, '+ Stealth' )
	-- TODO: With the CFG file we can set a certain amount of time they can invisible
	char:Save( netuser )
end

function PLUGIN:Unstealth( netuser )
	local data = char:GetUserData( netuser )
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

	inv:RemoveItem( 36 )inv:RemoveItem( 37 )inv:RemoveItem( 38 )inv:RemoveItem( 39 )
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
	char:Save( netuser )
end

function PLUGIN:hasStealth( netuser )
	local data = char:GetUserData( netuser )
	if not data then return false end
	if data.stealth then return true else return false end
end

function PLUGIN:isThief( netuser )
	local data = char:GetUserData( netuser )
	if not data then return false end
	if data.class == 'thief' then return true else return false end
end