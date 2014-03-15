PLUGIN.Title = 'carbon_sandbox_c'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin("carbon_core") core:LoadLibrary()
	self:AddChatCommand( 'sc', self.sc )
	self:AddChatCommand( 'mdisarm', self.MagicDisarm )
end

function PLUGIN:sc(netuser, cmd, args)
	local i = 1
	while i <= 1 do
		if not args[1] then break end
		local validate,netuser = rust.FindNetUsersByName( args[1] )
		i = i+1
	end
	local controllable = netuser.playerClient.controllable
	local netuserID = rust.GetCharacter( netuser )
	local Character = controllable:GetComponent( "Character" )
	local Inventory = controllable:GetComponent( "Inventory" )
	local InventoryHolder = controllable:GetComponent( "InventoryHolder" )
	local EquipmentWearer = controllable:GetComponent( "EquipmentWearer" )
	local IDLocalCharacter = netuserID.idMain:GetComponent( "IDLocalCharacter" )
	local ProtectionTakeDamage = controllable:GetComponent( "ProtectionTakeDamage" )
	local PlayerInventory = controllable:GetComponent( "PlayerInventory" )


	Character:DestroyCharacter(Character)

	rust.BroadcastChat(tostring(line))
	Character:ControlOverriddenBy(controllable)
	Character:ControlOverriddenBy(netuserID.idMain)
	Character:ControlOverriddenBy(controllable)
	rust.SendChatToUser(netuser, tostring(controllable))
	if Inventory.activeItem then
		rust.SendChatToUser(netuser, tostring(Inventory.activeItem.slot))
		local b, item = Inventory:GetItem( 30 )
		rust.SendChatToUser(netuser, tostring(b))
		rust.SendChatToUser(netuser, tostring(item))

		Inventory:DeactivateItem()
	end





	--[[
	--    rust.SendChatToUser(netuser, tostring(inv))
		builder = avatar:ToBuilder()
		rust.BroadcastChat('before: ')
		local count = builder.BlueprintsCount
		rust.BroadcastChat( tostring( count ))
		builder:ClearBlueprints()
		rust.BroadcastChat('after: ')
		local count = builder.BlueprintsCount
		rust.BroadcastChat(tostring( count ))
		avatar.Build()
	--]]
	-- recycler = avi.avatar.Recycler()
	--avatar:ClearBlueprints()
end
function PLUGIN:Disarm(takedamage, dmg)
	local vicuser = dmg.victim.client.netUser
	local controllable = vicuser.playerClient.controllable
	local Inventory = controllable:GetComponent( "Inventory" )
	local activeItem = Inventory.activeItem
	func:Notice(vicuser,'»','You have been disarmed!',5)
	Inventory:DeactivateItem()
end

function PLUGIN:MagicDisarm(netuser, cmd, args)
	local validate, vicuser = rust.FindNetUsersByName( args[1] )
	if (not validate) then
		if (vicuser == 0) then
			print( "No player found with that name: " .. tostring( args[1] ))
		else
			print( "Multiple players found with name: " .. tostring( args[1] ))
		end
		return false
	end
	local controllable = vicuser.playerClient.controllable
	local Inventory = controllable:GetComponent( "Inventory" )
	local activeItem = Inventory.activeItem
	func:Notice(vicuser,'»','You have been disarmed!',5)
	Inventory:DeactivateItem()
end