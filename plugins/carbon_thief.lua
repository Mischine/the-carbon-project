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
	func:TextBox(cmdData.netuser, content, cmdData.cmd, cmdData.args)
end

function PLUGIN:Steal( netuser, cmd, args )
	if not args[1] then rust.SendChatToUser( netuser, '/steal "name" ' ) return end
	local targname = util.QuoteSave( args[1] )

end

function PLUGIN:Stealth( netuser, cmd, args)
	local data = char:GetUserData( netuser )
	if not data then return end
	if data.stealth then rust.Notice( netuser, 'You\'re already stealth!' ) return end
	local netuserID = rust.GetUserID( netuser )
	local char = rust.GetCharacter( netuser )
	if not char then rust.Notice( netuser ,'No char.' ) return end
	local IDLocalCharacter = char.idMain:GetComponent( "IDLocalCharacter" )
	IDLocalCharacter:set_lockMovement( true )
	data.stealth = true

	local inv = rust.GetInventory( netuser )
	if not inv then rust.Notice( netuser, 'Inventory not found, try again!' ) return end
	local tbl = {}
	local con = 0
	local helmet = inv:GetItem( 36 )
	if helmet then
		con = helmet.condition
		tbl[ 'helmet' ] = {
			['item'] = helmet,
			['con'] = con
		}
		inv:RemoveItem( 36 )
	end
	local vest = inv:GetItem( 37 )
	if vest then
		con = vest.condition
		tbl[ 'vest' ] = {
			['item'] = vest,
			['con'] = con
		}
		inv:RemoveItem( 37 )
	end
	local pants = inv:GetItem( 38 )
	if pants then
		con = pants.condition
		tbl[ 'pants' ] = {
			['item'] = pants,
			['con'] = con
		}
		inv:RemoveItem( 38 )
	end
	local boots = inv:GetItem( 39 )
	if boots then
		con = boots.condition
		tbl[ 'boots' ] = {
			['item'] = boots,
			['con'] = con
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
	char:Save( netuser )
end

function PLUGIN:Unstealth( netuser )
	local data = char:GetUserData( netuser )
	if not data then return end
	if not data.stealth then rust.Notice( netuser, 'You\'re not stealth!' ) return end
	local netuserID = rust.GetUserID( netuser )
	local char = rust.GetCharacter( netuser )
	if not char then rust.Notice( netuser ,'No char.' ) return end
	local IDLocalCharacter = char.idMain:GetComponent( "IDLocalCharacter" )
	IDLocalCharacter:set_lockMovement( false )
	data.stealth = false

	local inv = rust.GetInventory( netuser )
	if not inv then rust.Notice( netuser, 'Inventory not found, try again!' ) return end
	local pref = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor )

	-- char:set_lockMovement(false)
	rust.SendChatToUser(netuser, 'Movement: ' .. tostring(idchar.lockMovement))

	inv:RemoveItem( 36 )inv:RemoveItem( 37 )inv:RemoveItem( 38 )inv:RemoveItem( 39 )
	if self.stealth[ netuserID ] then
		for _, v in pairs ( self.stealth[netuserID] ) do
			local datablock = v.item
			datablock:SetCondition(v.con)
			inv:AddItemAmount( datablock, 1, pref )
		end
	end
	rust.InventoryNotice( netuser, '- Stealth' )
	char:Save( netuser )
end



function PLUGIN:hasStealth( netuser )
	local data = char:GetUserData( netuser )
	if not data then return false end
	if data.stealth then return true else return false end
end

function PLUGIN:isThief( netuser, cmd, args )
	local data = char:GetUserData( netuser )
	if not data then return false end
	if data.class == 'thief' then return true else return false end
end

