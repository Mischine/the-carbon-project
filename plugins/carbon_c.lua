PLUGIN.Title = 'carbon_sandbox_c'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin("carbon_core") core:LoadLibrary()
	self:AddChatCommand( 'sc', self.sc )
	self:AddChatCommand( 'mdisarm', self.MagicDisarm )
	self:AddChatCommand( 'testxp', self.TestXP )
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
	local EquipmentWearer = controllable:GetComponent( "EquipmentWearer" )
	local PlayerController = controllable:GetComponent( "PlayerController" )

	--local CharacterLoadoutTrait = controllable:GetComponent( "CharacterLoadoutTrait" )


	local str = Rust
	for k, v in ipairs( str ) do
		print(tostring(k .. ' | ' .. v))
	end
	rust.SendChatToUser(netuser, tostring(str))
	Character:set_blind(false)
	Character:set_deaf(false)
	Character:set_mute(false)
	print(tostring(Character:get_blind()))
	print(tostring(Character:get_deaf()))
	print(tostring(Character:get_mute()))
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(0))) --Generic
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(1))) --Bullet
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(2))) --Melee
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(3))) --Explosion
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(4))) --Radiation
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(5))) --Cold



--[[
	if Inventory.activeItem then
		--rust.SendChatToUser(netuser, tostring(Inventory.activeItem.slot))
		--local b, item = Inventory:GetItem( 30 )
		--rust.SendChatToUser(netuser, tostring(b))
		--rust.SendChatToUser(netuser, tostring(item))
		local activeItem = Inventory.activeItem
		activeItem.extraData.name = 'Rock'
		rust.SendChatToUser(netuser, tostring(activeItem))
		Inventory:DeactivateItem()
	end

]]



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
--[[
local a=cmdData.netuserData.lvl -- current level
local b=core.Config.settings.lvlmodifier --level modifier
local bb=(1*1+1)/b*100-(1)*100
rust.BroadcastChat(tostring(bb))
local c=((a+1)*a+1+a+1)/b*100-(a+1)*100-(((a-1)*a-1+a-1)/b*100-(a-1)*100)-100 -- total needed to level
local d=cmdData.netuserData.xp-((a-1)*a-1+a-1)/b*100-(a-1)*100-100
local e=math.floor(d/c*100+0.5)
local f=c-d
local g=(a*a+a)/b*100-a*100
local h=math.floor((((cmdData.netuserData.dp/c)*.5)*100)+0.5)
local i=c*.5;
if a==2 and core.Config.settings.lvlmodifier>=2 then g=0 end


math.floor((math.sqrt(100*((core.Config.settings.lvlmodifier*(combatData.netuserData.xp+xp))+25))+50)/100)
]]
function PLUGIN:TestXP(netuser, cmd, args)
	local xp = char[rust.GetUserID( netuser )].xp+xp
	for level = core.Config.settings.LEVELCAP, 1, -1 do
		if xp >= core.Config.level[tostring(level)] then
			rust.BroadcastChat(tostring(level))
			return
		end
	end
end