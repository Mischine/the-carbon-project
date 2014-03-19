PLUGIN.Title = 'carbon_sandbox_c'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin("carbon_core") core:LoadLibrary()
	self:AddChatCommand( 'sc', self.sc )
	self:AddChatCommand( 'mdisarm', self.MagicDisarm )
	self:AddChatCommand( 'testxp', self.TestXP )
	self:AddChatCommand('location', self.loc)
	self:AddChatCommand('tp', self.tel)
end
--local testC = util.GetFieldGetter( Rust.PlayerMovement_Mecanim._type, "PlayerMovement_Mecanim" )
--local testA, testB = typesystem.GetProperty( Rust.PlayerMovement_Mecanim, "flSprintSpeed", bf.public_instance )
local get_flSprintSpeed, set_flSprintSpeed = typesystem.GetField( Rust.PlayerMovement_Mecanim, "flSprintSpeed", bf.public_instance )
local weaponRecoil = typesystem.GetField( Rust.BulletWeaponDataBlock, "weaponRecoil", bf.private_instance )
--local testD = util.GetPropertyGetter( Rust.PlayerMovement_Mecanim._type, "flSprintSpeed", true )
function PLUGIN:sc(netuser, cmd, args)
	local i = 1
	while i <= 1 do
		if not args[1] then break end
		local validate,netuser = rust.FindNetUsersByName( args[1] )
		i = i+1
	end
	local controllable = netuser.playerClient.controllable
	local avatar = netuser:LoadAvatar()
	local netuserID = rust.GetCharacter( netuser )
	local Character = controllable:GetComponent( "Character" )
	local Inventory = controllable:GetComponent( "Inventory" )
	local InventoryHolder = controllable:GetComponent( "InventoryHolder" )
	local EquipmentWearer = controllable:GetComponent( "EquipmentWearer" )
	local IDLocalCharacter = netuserID.idMain:GetComponent( "IDLocalCharacter" )
	local ProtectionTakeDamage = controllable:GetComponent( "ProtectionTakeDamage" )
	local PlayerInventory = controllable:GetComponent( "PlayerInventory" )
	local EquipmentWearer = controllable:GetComponent( "EquipmentWearer" )
	local HeldItemDataBlock = controllable:GetComponent( "HeldItemDataBlock" )
	local Metabolism = controllable:GetComponent("Metabolism")


	--local testthis = set_flSprintSpeed()
	--rust.SendChatToUser(netuser, tostring(testthis))
	-- Inventory.activeItem.datablock.caloriesPerSwing = 2 -- change calories per swing =)
	--Inventory.activeItem.datablock.midSwingDelay = 1.25 -- change swing delay
	-- Inventory.activeItem.datablock.worldSwingAnimationSpeed = 0.75 -- doesnt do anything.. . ?
	--Inventory.activeItem.datablock.midSwingDelay = 1.25
	--Inventory.activeItem.datablock.gathersResources = true
	--THIS IS FOR BULLETWEAPONDATABLOCKS
	--Inventory.activeItem.datablock.aimingRecoilSubtract = 0.5 --0.5
	--Inventory.activeItem.datablock.recoilDuration = 0.20000000298023
	--Inventory.activeItem.datablock.maxEligableSlots = 5 -- This works for new weapons only..
	--Inventory.activeItem.datablock.recoilPitchMax = 5
	--Inventory.activeItem.datablock.recoilPitchMin = 2
	--Inventory.activeItem.datablock.recoilYawMax = 3
	--Inventory.activeItem.datablock.recoilYawMin = -3
	--Inventory.activeItem.datablock.fireRate = 0.125 -- prevents damage output to happen at this time
	--Inventory.activeItem.datablock.fireRateSecondary = 1
	--Metabolism:AddWater(tonumber(-5))
	--rust.SendChatToUser(netuser, tostring(avatar.vitals.hydration))


	rust.BroadcastChat(tostring(Inventory.activeItem.datablock.creatorID))
--[[
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(0))) --Generic
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(1))) --Bullet
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(2))) --Melee
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(3))) --Explosion
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(4))) --Radiation
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(5))) --Cold

	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(0))) --Generic
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(1))) --Bullet
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(2))) --Melee
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(3))) --Explosion
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(4))) --Radiation
	rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(5))) --Cold
]]


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
function PLUGIN:loc(netuser, cmd)
	if (netuser.playerClient.hasLastKnownPosition) then
		local coords = netuser.playerClient.lastKnownPosition;
		rust.SendChatToUser( netuser, "Location", "X: " .. math.floor(coords.x) .. "   Y: " .. math.floor(coords.y) .. "   Z: " .. math.floor(coords.z) )

		print( netuser, "Location", "X: " .. coords.x .. "   Y: " .. coords.y .. "   Z: " .. coords.z )
	end
end
-- -316304384 Location X: 6396.3525390625   Y: 371.41613769531   Z: -4756.615234375
function PLUGIN:tel(netuser, cmd, args)
	local locations = {
		['devrock']='"6396.3525390625" "371.41613769531" "-4756.615234375"',

	}
	if #args==0 then
		rust.SendChatToUser(netuser,'/tp [LOCATION] | /tp [NAME] [LOCATION] | /tp list' )
	elseif #args == 1 and locations[ args[1] ] then
		local isAdmin = netuser.admin
		if not isAdmin then netuser.admin = true end
		rust.RunServerCommand( 'teleport.topos "'..netuser.displayName..'" '.. locations[tostring(args[1])])
		if not isAdmin then netuser.admin = false end
	elseif #args == 1 and args[1] == 'list' then
		for k,v in pairs (locations) do
			rust.SendChatToUser( netuser, core.Config.settings.sysname,tostring(k))
		end
	elseif #args == 2 and locations[ args[2] ] then
		local validate, targetuser = rust.FindNetUsersByName( args[1] )
		if (not validate) then
			if (targetuser == 0) then
				print( "No player found with that name: " .. tostring( args[1] ))
			else
				print( "Multiple players found with name: " .. tostring( args[1] ))
			end
			return false
		end
		local isAdmin = netuser.admin
		if not isAdmin then netuser.admin = true end
		rust.RunServerCommand( 'teleport.topos "'..targetuser.displayName..'" '.. locations[tostring(args[2])])
		if not isAdmin then netuser.admin = false end
	end
end