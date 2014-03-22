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
	self:AddChatCommand('rage', self.Rage)
	self:AddChatCommand('kb', self.knockback)
end
--local testC = util.GetFieldGetter( Rust.PlayerMovement_Mecanim._type, "PlayerMovement_Mecanim" )
--local testA, testB = typesystem.GetProperty( Rust.PlayerMovement_Mecanim, "flSprintSpeed", bf.public_instance )
local get_flSprintSpeed, set_flSprintSpeed = typesystem.GetField( Rust.PlayerMovement_Mecanim, "flSprintSpeed", bf.public_instance )
local weaponRecoil = typesystem.GetField( Rust.BulletWeaponDataBlock, "weaponRecoil", bf.private_instance )
local get_maxAudioDist, set_maxAudioDist = typesystem.GetField( Rust.CharacterFootstepTrait, "_maxAudioDist", bf.private_instance )
local get_traitMap = typesystem.GetField( Rust.Character, "_traitMap", bf.private_instance )
local get_CharacterFootstepTrait = typesystem.GetField( Rust.FootstepEmitter, "trait", bf.private_instance )
local get_waterLevelLitre = typesystem.GetField( Rust.Metabolism, "waterLevelLitre", bf.private_instance )
local _forwardsPlayerClientInput = typesystem.GetField( Rust.Controller, "_forwardsPlayerClientInput", bf.private_instance )
local get_maxWaterLevelLitre, set_maxWaterLevelLitre, test = typesystem.GetField( Rust.Metabolism, "maxWaterLevelLitre", bf.private_instance )
local AddWater = util.GetStaticMethod( Rust.Metabolism, "AddWater")
--local get_maxAudioDist, set_maxAudioDist = typesystem.GetField( Rust.CharacterFootstepTrait, "_maxAudioDist", bf.private_static )
local getTrait = typesystem.GetField( Rust.FootstepEmitter, "trait", bf.private_instance )
--local CharacterFootstepTrait = util.GetPropertyGetter( Rust.PlayerMovement_Mecanim._type, "flSprintSpeed", true )

function dump (prefix, a)
	for i,v in pairs (a) do
		if type(v) == "table" then
			dump(prefix .. '.' .. i,v)
		elseif type(v) == "function" then
			print (prefix .. '.' .. i .. '()')
		end
	end
end


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
	local RecoilSimulation = Character:GetComponent("RecoilSimulation")
	local AvatarSaveRestore = Character:GetComponent("AvatarSaveRestore")
	local TakeDamage = Character:GetComponent("TakeDamage")
	local FootstepEmitter = Character:GetComponent("FootstepEmitter")
	local CharacterTraitMap = get_traitMap(rust.GetCharacter(netuser))
	local CharacterFootstepTrait = get_CharacterFootstepTrait(FootstepEmitter)
	local ClientVitalsSync = Character:GetComponent('ClientVitalsSync')
	local CharacterMotor = Character:GetComponent('CharacterMotor')
	local CharacterInfo = Character:GetComponent('CharacterInfo')
	--Metabolism.maxWaterLevelLitre = 40
	--Metabolism:AddWater(10)

	local args = cs.newarray(System.Object._type, 0)
	Metabolism.networkView:RPC("Vomit", Metabolism.networkView.owner, args);

	--TakeDamage.maxHealth = 999
	--TakeDamage.health = 999
	--local distanceCheck = FootstepEmitter:get_maxAudioDist()

	--AvatarSaveRestore:SaveAvatar()
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
function PLUGIN:Rage(netuser, cmd, args)
	local controllable = vicuser.playerClient.controllable
	local Metabolism = controllable:GetComponent("Metabolism")

	local activeItem = rust.GetInventory( netuser ).activeItem
	local returnCondition = activeItem.condition
	local returnUses = activeItem.uses
	timer.Repeat(0.25, 20, function()
		activeItem:SetCondition(returnCondition)
		activeItem.uses = returnUses
	end)
	func:Notice(netuser,'☣','Rage!',5)
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
	rust.BroadcastChat(tostring(activeItem.condition))
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


local Raycastp = util.FindOverloadedMethod( UnityEngine.Physics, "RaycastAll", bf.public_static, { UnityEngine.Ray } )
cs.registerstaticmethod( "tmp", Raycastp )
local RaycastAll = tmp
tmp = nil
function TraceEyesp( netuser )
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
	return closest
end
function PLUGIN:knockback(netuser, cmd, args)
	self.agodMap = {}
	self.jumpheight = 3
	local offset = self.jumpheight if args[1] and tonumber(args[1]) then offset = tonumber(args[1]) end
	local uid = rust.GetUserID( netuser )
	self.agodMap[uid] =  timer.Once(6, function()  self.agodMap[uid] = nil end )

	local  trace = TraceEyesp(netuser)
	if not trace then return end
	local p = trace.point

	local coords = netuser.playerClient.lastKnownPosition
	coords.x ,coords.y ,coords.z = p.x,p.y+offset,p.z
	rust.ServerManagement():TeleportPlayer(netuser.playerClient.netPlayer, coords)
end
function PLUGIN:DumpGameObject( _gameObj )
	local types = UnityEngine.Component._type --cs.gettype( "UnityEngine.Component" ) -- cs.gettype("Facepunch+MonoBehaviour, Facepunch.ID")
	local _components = _gameObj:GetComponents( types )
	print( "Found Component List?: "..tostring( _components ) )

	local tbl = cs.createtablefromarray( _components )
	print( "Found Entries #: "..tostring( #tbl ) )

	if (#tbl == 0) then
		print( "Empty table" )
	else
		for i=1,#tbl do
			print( "Found Component: "..tostring( tbl[i] ) )
		end
	end

	print(" - - - - - - - - - - - - ")

	local types = UnityEngine.Component._type --cs.gettype( "UnityEngine.Component" ) -- cs.gettype("Facepunch+MonoBehaviour, Facepunch.ID")
	local _components = _gameObj:GetComponentsInChildren( types )
	print( "Found Children Component List?: "..tostring( _components ) )

	local tbl = cs.createtablefromarray( _components )
	print( "Found Entries #: "..tostring( #tbl ) )

	if (#tbl == 0) then
		print( "Empty table" )
	else
		for i=1,#tbl do
			print( "Found Component: "..tostring( tbl[i] ) )
		end
	end

	print( "" )
	print( "" )
	print( "" )
end
