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
	self:AddChatCommand('kill', self.Kill)
	self:AddChatCommand('hurt', self.Hurt)
	self:AddChatCommand('day', self.Day)
	self:AddChatCommand('cast', self.CastSphere)
	self:AddChatCommand('zx', self.Spawn)
	self:AddChatCommand('blink', self.Blink)
end
--local testC = util.GetFieldGetter( Rust.PlayerMovement_Mecanim._type, "PlayerMovement_Mecanim" )
--local testA, testB = typesystem.GetProperty( Rust.PlayerMovement_Mecanim, "flSprintSpeed", bf.public_instance )
local get_flSprintSpeed, set_flSprintSpeed = typesystem.GetField( Rust.PlayerMovement_Mecanim, "flSprintSpeed", bf.public_instance )
local weaponRecoil = typesystem.GetField( Rust.BulletWeaponDataBlock, "weaponRecoil", bf.private_instance )
local get_maxAudioDist, set_maxAudioDist = typesystem.GetField( Rust.CharacterFootstepTrait, "_maxAudioDist", bf.private_instance )
local get_traitMap = typesystem.GetField( Rust.Character, "_traitMap", bf.private_instance )
local get_CharacterFootstepTrait = typesystem.GetField( Rust.FootstepEmitter, "trait", bf.private_instance )
local get_defaultBlueprints = typesystem.GetField( Rust.Loadout, "_defaultBlueprints", bf.private_instance )
local get_waterLevelLitre = typesystem.GetField( Rust.Metabolism, "waterLevelLitre", bf.private_instance )
local _forwardsPlayerClientInput = typesystem.GetField( Rust.Controller, "_forwardsPlayerClientInput", bf.private_instance )
--get_maxWaterLevelLitre, set_maxWaterLevelLitre = typesystem.GetField( Rust.Metabolism, "maxWaterLevelLitre", bf.private_instance )
--AddWater = util.GetStaticMethod( Rust.Metabolism, "AddWater")
local Hurt = util.GetStaticMethod( Rust.TakeDamage, "Hurt")
--local get_maxAudioDist, set_maxAudioDist = typesystem.GetField( Rust.CharacterFootstepTrait, "_maxAudioDist", bf.private_static )
local getTrait = typesystem.GetField( Rust.FootstepEmitter, "trait", bf.private_instance )
--local CharacterFootstepTrait = util.GetPropertyGetter( Rust.PlayerMovement_Mecanim._type, "flSprintSpeed", true )

get_activeItem, set_activeItem = typesystem.GetField( Rust.Inventory, "_activeItem", bf.public_instance )

CCMotor = typesystem.GetField( Rust.Character, "_ccmotor", bf.private_instance )
HurtSelf = util.GetStaticMethod( Rust.TakeDamage, "HurtSelf")
function PLUGIN:Spawn(netuser, cmd, args)
	local createABC = util.FindOverloadedMethod( Rust.NetCull._type, 'InstantiateStatic', bf.public_static, { System.String, UnityEngine.Vector3, UnityEngine.Quaternion } )
	--local itemname = ';deploy_camp_bonfire'
	local itemname = tostring(args[1])
	local coords = netuser.playerClient.lastKnownPosition;
	local v = coords
	v.y = UnityEngine.Terrain.activeTerrain:SampleHeight(v)
	local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, 'LookRotation' )
	local q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( 'System.Object' ), { v } ))
	local arr = util.ArrayFromTable( cs.gettype( 'System.Object' ), { itemname, v, q  } )
	cs.convertandsetonarray( arr, 0, itemname, System.String._type )
	cs.convertandsetonarray( arr, 1, v, UnityEngine.Vector3._type )
	cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type )
	local xgameObject = createABC:Invoke( nil, arr )
end
function PLUGIN:Kill(netuser, cmd, args)
	if(#args==0)then
		rust.SendChatToUser(netuser,'/hurt "name" #[amount]' )
	else
		local validate, vicuser = rust.FindNetUsersByName( args[1] )
		if (not validate) then
			if (vicuser == 0) then
				print( "No player found with that name: " .. tostring( args[1] ))
			else
				print( "Multiple players found with name: " .. tostring( args[1] ))
			end
			return false
		end
		local Character = rust.GetCharacter( vicuser )
		local vicuserID = rust.GetUserID( vicuser )
		local netuserID = rust.GetUserID( netuser )
		local TakeDamage = Character:GetComponent( "TakeDamage" )
		local ClientVitalsSync = Character:GetComponent( "ClientVitalsSync" )
		local HumanBodyTakeDamage = Character:GetComponent("HumanBodyTakeDamage")
		HumanBodyTakeDamage:SetBleedingLevel(999)
		TakeDamage.health = 0.01
		HumanBodyTakeDamage:DoBleed(netuser.idMain)
		ClientVitalsSync:SendClientItsHealth()
	end
end

function PLUGIN:sc(netuser, cmd, args)
	--local validate,vicuser = rust.FindNetUsersByName( args[1] )

	--local vicusercontrollable = vicuser.playerClient.controllable
	--local vicuserCharacter = rust.GetCharacter( vicuser )
	--local vicuserInventory = vicusercontrollable:GetComponent( "Inventory" )
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
	local CharacterLoadoutTrait = Character:GetComponent("CharacterLoadoutTrait")
	local ClientVitalsSync = Character:GetComponent('ClientVitalsSync')
	local CharacterInfo = Character:GetComponent('CharacterInfo')
	local CharacterWalkSpeedTrait = Character:GetComponent("CharacterWalkSpeedTrait")
	local CharacterGameObject = Character:get_gameObject()
	local MetabolismGameObject = Metabolism:get_gameObject()
	local HumanController = CharacterGameObject:GetComponent( "HumanController" )
	local Collider = CharacterGameObject:GetComponent( "Collider" )
	local Physics = Collider:GetComponent( "Physics" )
	local ClientConnection = controllable:GetComponent( "ClientConnection")
	local Component = cs.gettype('Component, UnityEngine')
	local MyComponent = Character:GetComponent("Component")


	rust.BroadcastChat(tostring(Rust.ServerManagement:RemovePlayerSpawn()))
--[[
	Protected Sub NetworkSound(ByVal toPlay As BasicWildLifeAI.AISound)
	MyBase.networkView.RPC(Of Byte)("Snd", RPCMode.Others, toPlay)
	End Sub
--]]
	--local BasicWildLifeAI = hunter.Pets[ netuser ][ 'BaseWildAI' ]
	--local args = cs.newarray(System.Object._type, 0)
	--BasicWildLifeAI.networkView:RPC("CL_Attack", uLink.RPCMode.OthersExceptOwner, args);

	--BasicWildLifeAI.networkView:RPC("Attack", uLink.RPCMode.OthersExceptOwner, args);

	--MyBase.networkView.RPC("Vomit", MyBase.networkView.owner, New Object(0) {})
	--Metabolism.networkView:RPC("CL_Attack", BasicWildLifeAI.networkView.owner, args);
--[[
	local controllable = netuser.playerClient.controllable
	local Character = controllable:GetComponent( "Character" )
	local CharacterGameObject = Character:get_gameObject()

	local attacker = cs.gettype('IDBase, Facepunch.ID')
	local victim = cs.gettype('IDBase, Facepunch.ID')
	local damageQuantity = cs.gettype('TakeDamage+Quantity, Assembly-CSharp')
	local extraData = System.Object
	local Hurt = util.FindOverloadedMethod(Rust.TakeDamage, "Hurt", bf.public_static, {attacker,victim, damageQuantity, extraData})
	--cs.registerstaticmethod( "tmp", Hurt ) local Hurt = tmp tmp = nil
	local a = Character.idMain
	local b = Character.idMain
	local c = 5
	local d = CharacterGameObject
	local arr = util.ArrayFromTable( cs.gettype( 'System.Object' ), { a, b, c, d  } )
	cs.convertandsetonarray( arr, 0, a, attacker )
	cs.convertandsetonarray( arr, 1, b, victim )
	cs.convertandsetonarray( arr, 2, c, damageQuantity )
	cs.convertandsetonarray( arr, 3, d, extraData )

	local takedamage = Hurt:Invoke( nil, arr )
]]
--[[
	local IDBase = cs.gettype("IDBase, Facepunch.ID")
	local SystemObject = cs.gettype( 'System.Object' )
	local SystemSingle = cs.gettype( 'System.Single' )


	local Heal = util.FindOverloadedMethod( Rust.TakeDamage, "Heal", bf.public_static, {  IDBase, System.Single.float } )
	cs.registerstaticmethod( "tmp", Heal ) local Heal = tmp tmp = nil
	rust.BroadcastChat(tostring(Heal))
]]
--[[
	local IDBase = cs.gettype("IDBase, Facepunch.ID")
	local Quantity = cs.gettype( "TakeDamage+Quantity, Rust" )
	local SystemObject = cs.gettype( 'System.Object' )
	local SystemFloat = cs.gettype( 'System.float' )

	local Kill = util.FindOverloadedMethod( Rust.TakeDamage, "Kill", bf.public_static, {  IDBase, IDBase, SystemObject } )
	cs.registerstaticmethod( "tmp", Kill ) local Kill = tmp tmp = nil
	Kill(Character.idMain, vicuserCharacter.idMain, CharacterGameObject)
]]
	--[[
			local KillSelf = util.FindOverloadedMethod( Rust.TakeDamage, "KillSelf", bf.public_static, { cs.gettype('IDBase, Facepunch.ID'), cs.gettype( 'System.Object' ) } )
			cs.registerstaticmethod( "tmp2", KillSelf )
			local KillSelf = tmp2
			tmp2 = nil
			KillSelf(Character.idMain, CharacterGameObject)
			rust.BroadcastChat(tostring(KillSelf))
	]]
	--[[
			local HostileWildlifeAI = util.FindOverloadedMethod( Rust.HostileWildlifeAI, " EnterState_Attack", bf.protected_instance, {} )
			local get_state, set_state = typesystem.GetField( Rust.BasicWildLifeAI, "_state", bf.private_instance )

			cs.registerstaticmethod( "tmp2", HostileWildlifeAI )
			local HostileWildlifeAI = tmp2
			tmp2 = nil


			set_state()
			rust.BroadcastChat(tostring(get_state))
			rust.BroadcastChat(tostring(set_state))
	]]

	--[[
	rust.BroadcastChat(tostring(get_boundBPs))
	local this = get_boundBPs(PlayerInventory)
	rust.BroadcastChat(tostring(this))
	rust.BroadcastChat(tostring(set_boundBPs))
	set_boundBPs(PlayerInventory, nil)
	]]
	--[[

	for k,v in pairs(Rust.DatablockDictionary.All) do
		print(tostring(k)..'   '..tostring(v))
	end
	]]


	--Rust.DropHelper.DropInventoryContents(Inventory)
	--Rust.DropHelper.DropItem( Inventory, 30 )
	--[[
	rust.BroadcastChat(tostring(avatar.BlueprintsCount))
	local GetAvatar, SetAvatar = typesystem.GetField( Rust.NetUser, "avatar", bf.private_instance )

	local svrMgr = Rust.ServerManagement.Get()
	print( tostring(svrMgr))

	--Rust.ServerManagement.Get().CreatePlayerClientForUser(netuser);
	local CPCFU = util.FindOverloadedMethod( Rust.ServerManagement, "CreatePlayerClientForUser", bf.private_instance, {Rust.NetUser  } )
	print( tostring(CPCFU) )
	local arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { netuser } )
	cs.convertandsetonarray( arr, 0, netuser, Rust.NetUser._type )
	local _PlayerClient = CPCFU:Invoke( svrMgr, arr )
	print( "Result:" .. tostring(_PlayerClient))


	local builder = avatar:ToBuilder()
	builder:ClearBlueprints()
	local new_avatar = builder:Build()
	SetAvatar(_PlayerClient, new_avatar)

	rust.BroadcastChat(avatar)
]]


	--[[
	Rust.Character.DestroyCharacter( HumanController.idMain )
	local svrMgr = Rust.ServerManagement.Get()
	local CPCFU = util.FindOverloadedMethod( Rust.ServerManagement, "CreatePlayerClientForUser", bf.private_instance, {Rust.NetUser  } )
	print( tostring(CPCFU) )
	local arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { netuser } )
	cs.convertandsetonarray( arr, 0, netuser, Rust.NetUser._type )
	local _PlayerClient = CPCFU:Invoke( svrMgr, arr )
	netuser.playerClient = _PlayerClient
	local GetAvatar, SetAvatar = typesystem.GetField( Rust.NetUser, "avatar", bf.private_instance )
	local avatar = GetAvatar( netuser )
	local builder = avatar:ToBuilder()
	builder:ClearBlueprints()
	local new_avatar = builder:Build()
	SetAvatar(HumanController.idMain, new_avatar)
]]

	-- BLANK NOW
	--local rootGO = netuser.playerClient.rootControllable.idMain:GetComponent( "Transform" )
	--self:DumpGameObject( rootGO.gameObject )






	-- BLANK NOW
	--local rootGO = netuser.playerClient.rootControllable.idMain:GetComponent( "Transform" )
	--self:DumpGameObject( rootGO.gameObject )



--[[
	local GetAvatar, SetAvatar = typesystem.GetField( Rust.NetUser, "avatar", bf.private_instance )
	local avatar = GetAvatar( netuser )
	local builder = avatar:ToBuilder()
	builder:ClearBlueprints()
	local new_avatar = builder:PrepareBuilder()
	SetAvatar(netuser, new_avatar)

]]

	--local get_jog, set_jog = typesystem.GetField( Rust.CharacterWalkSpeedTrait, "_jog", bf.private_instance )
	--rust.BroadcastChat('get_jog: '.. tostring(get_jog) .. '   set_jog: '.. tostring(set_jog))

	-- Get a function that gives us the ground at a particular position.
	--
	-- public static bool GetGroundInfoNavMesh(Vector3 startPos, out Vector3 pos)
	--rust.BroadcastChat(tostring(Character.transform:TransformDirection(Character.transform:set_position(coords))))


	-- Get a function that gives us the ground at a particular position.
	--
	-- public static bool GetGroundInfoNavMesh(Vector3 startPos, out Vector3 pos)
	--

	--CharacterController.rigidbody.constraints = UnityEngine.RigidbodyConstraints.FreezeAll
	--print(tostring(UnityEngine:GetComponents(CharacterGameObject)))

	--[[
	local DamageTypeFlags = cs.gettype( "DamageTypeFlags, Assembly-CSharp" )
	typesystem.LoadEnum(DamageTypeFlags, "DamageTypeFlags" )

	local get_armorValues = typesystem.GetField( Rust.ProtectionTakeDamage, "_armorValues", bf.private_instance )
	local this = get_armorValues(ProtectionTakeDamage)

	rust.SendChatToUser(netuser, tostring(DamageTypeFlags.damage_bullet))
	rust.SendChatToUser(netuser, tostring(this[DamageTypeFlags.damage_generic]))
	rust.SendChatToUser(netuser, tostring(this[DamageTypeFlags.damage_bullet]))
	rust.SendChatToUser(netuser, tostring(this.melee))
	rust.SendChatToUser(netuser, tostring(this.explosion))
	rust.SendChatToUser(netuser, tostring(this.radiation))
	rust.SendChatToUser(netuser, tostring(this.cold))

	]]
	--rust.SendChatToUser(netuser, tostring(ProtectionTakeDamage:GetArmorValue(1))) --Bullet

	--rust.SendChatToUser(netuser, tostring(inactiveItem))




--[[
	local builder = avatar:ToBuilder()
	builder:ClearBlueprints()
	PrepareBuilder = util.GetStaticMethod( RustProto.Avatar.Builder, "PrepareBuilder")
	local new_avatar = builder:PrepareBuilder()
	netuser:SaveAvatar(netuser.userID, new_avatar)
]]


	--netuser:SaveAvatar(avatar2)
	--netuser:SaveAvatar(netuserIDULONG, avatar2)


	--local maxplayers = server.maxplayers
	--maxplayers = 1
	--c:DumpGameObject( this )
	--rust.SendChatToUser(netuser, tostring(loadout))

	--[[
		local env = Rust.env
		local daylength = env.daylength
		local nightlength = env.nightlength
		local save = Rust.save
		save.friendly = false
		save.profile = false



	builder = avatar:ToBuilder()
	builder:ClearBlueprints()
	AvatarSaveRestore:ClearAvatar()
	netuser:SaveAvatar(builder:Build())
	]]
	--rust.SendChatToUser(netuser, tostring(Metabolism:get_maxWaterLevelLitre()))

	--TakeDamage.maxHealth = 999
	--TakeDamage.health = 999
	--local distanceCheck = FootstepEmitter:get_maxAudioDist()

	--Inventory.activeItem.datablock.caloriesPerSwing = 2 -- change calories per swing =)
	--Inventory.activeItem.datablock.midSwingDelay = 1.25 -- change swing delay
	--Inventory.activeItem.datablock.worldSwingAnimationSpeed = 0.75 -- doesnt do anything.. . ?
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
function PLUGIN:KillSelf(netuser, cmd, args)
	local KillSelf = util.FindOverloadedMethod( Rust.TakeDamage, "KillSelf", bf.public_static, { cs.gettype('IDBase, System.SingleFacepunch.ID'), cs.gettype( 'System.Object' ) } )
	cs.registerstaticmethod( "tmp2", KillSelf )
	local KillSelf = tmp2
	tmp2 = nil
	KillSelf(Character.idMain, CharacterGameObject)

	rust.BroadcastChat(tostring(KillSelf))
end
function PLUGIN:Blink(netuser, cmd, args)
	local coords = netuser.playerClient.lastKnownPosition
	local RaycastBlink = util.FindOverloadedMethod( UnityEngine.Physics, "RaycastAll", bf.public_static, { UnityEngine.Vector3 ,UnityEngine.Vector3,System.Single } )
	cs.registerstaticmethod( "tmp2", RaycastBlink )
	local RaycastBlink = tmp2
	tmp2 = nil

	local ray = rust.GetCharacter( netuser ).eyesOrigin
	local radius = 100
	local direction = rust.GetCharacter( netuser ).forward
	local distance = 100

	local hits = RaycastBlink( ray,direction,distance  )
	local tbl = cs.createtablefromarray( hits )
	rust.BroadcastChat(tostring(tbl[1]))
end
function PLUGIN:CastSphere(netuser, cmd, args)
	local NetCullRemove = util.FindOverloadedMethod( Rust.NetCull._type, "Destroy", bf.public_static, { UnityEngine.GameObject} )
	local WildlifeRemove = util.GetStaticMethod( Rust.WildlifeManager._type, "RemoveWildlifeInstance")

	local coords = netuser.playerClient.lastKnownPosition
	local Raycast = util.FindOverloadedMethod( UnityEngine.Physics, "SphereCastAll", bf.public_static, { UnityEngine.Ray,System.Single,System.Single } )
	cs.registerstaticmethod( "tmp2", Raycast )
	local Raycast = tmp2
	tmp2 = nil

	local ray = rust.GetCharacter( netuser ).eyesRay
	local radius = 0.1
	local direction = rust.GetCharacter( netuser ).forward
	local distance = 30

	local hits = Raycast( ray,radius,distance  )
	local tbl = cs.createtablefromarray( hits )
	for k,v in pairs(tbl) do

		if string.find(tostring(v.collider), 'Terrain',1 ,true) then
			rust.BroadcastChat(tostring(v.point))
			local coord = v
			coord.y = UnityEngine.Terrain.activeTerrain:SampleHeight(coord)
			local tpTo = '"'..tostring(coord.x)..'" "'..tostring(coord.y)..'" "'..tostring(coord.z)..'"'
			rust.RunServerCommand( 'teleport.topos "'..netuser.displayName..'" '.. tpTo)

		end
	end
		--rust.BroadcastChat(tostring(k)..'   '..tostring(v.collider.gameObject.transform.position))



		--[[
		if string.find(tostring(k), 'Stag(',1 ,true) or string.find(tostring(k), 'Wolf(',1 ,true) then
			local object = v.collider.gameObject

			local arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { object } )  ;
			cs.convertandsetonarray( arr, 0, object , UnityEngine.GameObject._type )
			NetCullRemove:Invoke( nil, arr )
			--WildlifeRemove(object:GetComponent('BasicWilfLifeAI'))

		end
]]
end
function PLUGIN:Day(netuser, cmd, args)
	rust.RunServerCommand('env.time 10')
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
