PLUGIN.Title = 'carbon_hunter'
PLUGIN.Description = 'hunter class module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin('carbon_core') core:LoadLibrary()

	self:AddChatCommand( 'pet', self.PetCall)
	self:AddChatCommand( 'petrelease', self.cmdReleasePet )
	self:AddChatCommand( 'petatt', self.cmdPetAttack )
	self:AddChatCommand( 'petcall', self.cmdPetCallBack )
	self:AddChatCommand( 'petstay', self.cmdPetStay )
	self:AddChatCommand( 'state', self.SetState )
	--self:AddChatCommand( 'tppet', self.PetTP )

	self.Pets = {}      -- Database of pets
	self.BL = {}        -- Blacklist for NPC that aren't pets [ To increase performance ]
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 Pet OnInitiate Functions
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function PLUGIN:PetCall( netuser, _, _ )
	if not dev:isDev( netuser ) then return end
	if self:hasPet( netuser ) then rust.Notice( netuser,  'You dont have a pet.!' ) return end
	self.Pets[ netuser ] = {}
	local createABC = util.FindOverloadedMethod( Rust.NetCull._type, "InstantiateClassic", bf.public_static, { System.String, UnityEngine.Vector3, UnityEngine.Quaternion, System.Int32 } )
	local itemname = "Bear"
	--local itemname = "Wolf"
	local coords = netuser.playerClient.lastKnownPosition
	coords.x = math.random( coords.x - 50, coords.x + 50 )
	coords.z = math.random( coords.z - 50, coords.z + 50 )
	coords.y = UnityEngine.Terrain.activeTerrain:SampleHeight(coords) + 1
	local char = rust.GetCharacter( netuser )
	local gObject = char:get_gameObject()
	local v = coords
	local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, "LookRotation" )
	local q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( "System.Object" ), { v } ))
	local arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { itemname, v, q , 0 } )  ;
	cs.convertandsetonarray( arr, 0, itemname, System.String._type ) cs.convertandsetonarray( arr, 1, v, UnityEngine.Vector3._type )
	cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type ) cs.convertandsetonarray( arr, 3, 0, System.Int32._type )
	local xgameObject = createABC:Invoke( nil, arr )
	--func:DumpGameObject( xgameObject )
	self.Pets[ netuser ][ 'HosAI' ] = xgameObject:GetComponent( 'HostileWildlifeAI' )
	self.Pets[ netuser ][ 'BaseAI' ] = xgameObject:GetComponent( 'BaseAIMovement' )
	self.Pets[ netuser ][ 'BaseWildAI' ] = xgameObject:GetComponent( 'BasicWildLifeAI' )
	self.Pets[ netuser ][ 'PetGObject' ] = xgameObject
	self.Pets[ netuser ][ 'NavMesh' ] = xgameObject:GetComponent( 'NavMeshMovement' )
	self.Pets[ netuser ][ 'NavAgent' ] = self.Pets[ netuser ].NavMesh._agent
	self.Pets[ netuser ][ 'gObject' ] = gObject
	self.Pets[ netuser ][ 'pClient' ] = netuser.playerClient
	self.Pets[ netuser ][ 'char' ] = char
	self.Pets[ netuser ][ 'npcChar' ] = xgameObject:GetComponent( 'Character' )
	self.Pets[ netuser ][ 'netuser' ] = netuser
	self.Pets[ netuser ][ 'attack' ] = false
	self.Pets[ netuser ][ 'stay' ] = false
	self.Pets[ netuser ][ 'type' ] = 'bear'
	self.Pets[ netuser ][ 'RunSpeed' ] = 9
	self.Pets[ netuser ][ 'WalkSpeed' ] = 4
	self.Pets[ netuser ].HosAI:GoScentBlind( 3 )
	local pet = self.Pets[ netuser ]
	--pet = self:SyncPetPropertiesWithPlayerStats( pet )
	self:PetAI( netuser, pet )
	rust.SendChatToUser( netuser, 'Your pet has been called!' )
	--[[
	self.Pets[ netuser ][ 'timer' ] = timer.Repeat( 1,
	function()
		local coords = self.Pets[ netuser ].BaseWildAI.transform:get_position()
		local mycoords = self.Pets[ netuser ].pClient.lastKnownPosition
		local dis = func:Distance3D( coords.x, coords.y, coords.z, mycoords.x, mycoords.y, mycoords.z )
		if not self.Pets[ netuser ].attack and not self.Pets[ netuser ].stay then
			if dis > 8 and dis < 10 then
				mycoords.x = mycoords.x + math.random( 3 )
				mycoords.z = mycoords.z + math.random( 3 )
				self.Pets[ netuser ].NavMesh:SetMovePosition( mycoords, 1.5 )
			elseif dis >= 12 then
				if self.Pets[ netuser ].char.stateFlags.sprint then
					self.Pets[ netuser ].NavMesh:SetMovePosition( mycoords, 9 )
				elseif not self.Pets[ netuser ].char.stateFlags.sprint then
					self.Pets[ netuser ].NavMesh:SetMovePosition( mycoords, 4 )
				elseif dis > 50 then
					self.Pets[ netuser ].NavMesh:SetMovePosition( mycoords, 20 )
				end
			end
		end
		if not self.Pets[ netuser ].attack then
			self.Pets[ netuser ].HosAI:GoScentblind( 5 )
		end
	end)
	]]
end

function PLUGIN:PetAI( netuser, pet )
	pet[ 'timer' ] = timer.Repeat( 1,
	function()
		----------------------
		-- PetInCombatcheck --
		--TODO: Make this. =-)
		------------------------
		-- DistanceCalculator --
		local coords = pet.BaseWildAI.transform:get_position()
		local mycoords = pet.pClient.lastKnownPosition
		local dis = UnityEngine.Vector3.Distance( coords, mycoords )
		rust.BroadcastChat( tostring('Distance: ' .. func:round( dis, 2 ) .. '  |  Attack: ' .. tostring(pet.attack) .. ' | Stay: ' .. tostring(pet.stay ) .. ' | hasTarg: ' .. tostring( pet.HosAI:HasTarget()) .. ' | ScentBlind: ' .. tostring(pet.HosAI:IsScentBlind())))
		--------------------------
		-- MovementIntellegence --
		if not pet.attack and not pet.stay then
			if dis > 8 and dis < 10 then
				mycoords.x = mycoords.x + math.random( 3 )
				mycoords.z = mycoords.z + math.random( 3 )
				pet.NavMesh:SetMovePosition( mycoords, 1.5 )
			elseif dis >= 12 then
				if self.Pets[ netuser ].char.stateFlags.sprint then
					pet.NavMesh:SetMovePosition( mycoords, pet.RunSpeed )
				elseif not self.Pets[ netuser ].char.stateFlags.sprint then
					pet.NavMesh:SetMovePosition( mycoords, pet.WalkSpeed )
				end
			end
		end
		-----------------
		-- AbuseChecks --
		if dis > 60 then self:PetReturnToOwnerTeleport( pet ) end

		-------------------------
		-- KeepsPetUnagressive --
		if not pet.attack then
			self.Pets[ netuser ].HosAI:GoScentBlind( 5 )
		end

	end)
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 Pet Dynamic Functions
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:PetAttackPrep( netuser, combatData, takedamage )
	rust.BroadcastChat( 'Start: PetAttackPrep' )
	local pet = self:getPetData( netuser )
	if not pet then return end
	if pet.attack then return end
	local TargObject
	if combatData.vicuser then
		local char = rust.GetCharacter( combatData.vicuser )
		TargObject = char:get_gameObject()
		self:PetAttack( pet, TargObject )
	elseif combatData.npc then
		TargObject = combatData.npc.gObject
		self:PetAttack( pet, TargObject, takedamage )
	else
		return
	end
end

--TODO: Redo this.
function PLUGIN:StopPetAttack( netuser, combatData )
	local pet = self:getPetData( netuser )
	if not pet then return end
	local TargObject
	if combatData.vicuser then
		local char = rust.GetCharacter( combatData.vicuser )
		TargObject = char:get_gameObject()
	elseif combatData.npc then
		TargObject = combatData.npc.gObject
	else
		return
	end
	pet.attack = true
	pet.HosAI.nextScentListenTime = 0
	pet.NavMesh:SetMoveTarget( TargObject, 8 )
end


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                  Pet Chat Commands 
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:cmdPetCallBack( netuser )
	if not dev:isDev( netuser ) then return end
	local pet = self:getPetData( netuser )
	if pet then self:PetReturnToOwner( pet ) end
end

function PLUGIN:cmdPetStay( netuser )
	if not dev:isDev( netuser ) then return end
	if not self:hasPet( netuser ) then rust.Notice( netuser,  'You dont have a pet.!' ) return end
	local pet = self:getPetData( netuser )
	if pet then self:PetFreeze( pet ) end
end

function PLUGIN:cmdPetAttack( netuser, _, args )
	if not dev:isDev( netuser ) then return end
	if not self:hasPet( netuser ) then rust.Notice( netuser,  'You dont have a pet.!' ) return end
	local pet = self.Pets[ netuser ]
	local b, targuser = rust.FindNetUsersByName( args[1] )
	if not b then rust.SendChatToUser( netuser, core.sysname, 'Invalid target' ) return false end
	local char = rust.GetCharacter( targuser )
	if not char then return end
	local gObject = char:get_gameObject()
	if not gObject then return end
	self:PetAttack( pet, gObject )
end

-- TODO: Refine.
function PLUGIN:cmdReleasePet( netuser, _, _ )
	if self.Pets[ netuser ] and self.Pets[ netuser ].timer then
		local coords = netuser.playerClient.lastKnownPosition
		coords.x = math.random( coords.x - 50, coords.x + 50 )
		coords.z = math.random( coords.z - 50, coords.z + 50 )
		coords.y = UnityEngine.Terrain.activeTerrain:SampleHeight(coords) + 1
		self.Pets[ netuser ].HosAI:GoScentBlind( 20 )
		self.Pets[ netuser ].NavMesh:SetMovePosition( mycoords, 6 )
		self.Pets[ netuser ].timer:Destroy()
		self.Pets[ netuser ] = nil
		rust.BroadcastChat( 'Pet has been released!' )
	else
		rust.BroadcastChat( 'No Pet timer found!' )
	end
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 Pet Utility Functions
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function PLUGIN:PetFreeze( pet )
	pet.stay = true
	pet.attack = false
	pet.HosAI:GoScentBlind( 3 )
	pet.NavMesh:Stop()
end

function PLUGIN:PetAttack( pet, targ, takedamage )
	rust.BroadcastChat( 'Initiate Pet Attack!' )
	pet.attack = true
	pet.HosAI.nextScentListenTime = 0
	rust.BroadcastChat( 'Targ: ' .. tostring( targ ))
	if takedamage then
		pet.NavMesh:SetMoveTarget( targ, pet.RunSpeed )
		pet.HosAI:SetAttackTarget( takedamage )
		--pet.HosAI:EnterState_Chase()
	else
		pet.NavMesh:SetMoveTarget( targ, pet.RunSpeed )
	end
	rust.BroadcastChat( 'Pet Attack!' )
end

function PLUGIN:PetReturnToOwner( pet )
	local mycoords = pet.pClient.lastKnownPosition
	pet.HosAI:LoseTarget()
	pet.HosAI:GoScentBlind( 5 )
	pet.attack = false
	pet.stay = false
	pet.NavMesh:SetMovePosition( mycoords, pet.RunSpeed )
end

function PLUGIN:PetReturnToOwnerTeleport( pet )
	local coords = pet.pClient.lastKnownPosition
	rust.BroadcastChat( tostring( coords ))
	coords.x = math.random( coords.x - 10, coords.x + 10 )
	coords.z = math.random( coords.z - 10, coords.z + 10 )
	coords.y = UnityEngine.Terrain.activeTerrain:SampleHeight(coords) + 1
	rust.SendChatToUser( pet.netuser, core.sysname, 'Pet has been teleported back to you.')
	pet.NavAgent:Warp( coords )
end

function PLUGIN:SyncPetPropertiesWithPlayerStats( pet )
	-- TODO: Make once Hunter XP system is complete. ( so when we know all the attributes thats gonna effect Pets )
end

function PLUGIN:OnPetKilled( pet )
	
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 Pet Global Functions
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:hasPet( netuser )
	if not self.Pets then return false end
	if self.Pets[ netuser ] then return true else return false end
end

function PLUGIN:getPetData( netuser )
	if self.Pets[ netuser ] then return self.Pets[ netuser ] else return false end
end

function PLUGIN:isPetOwner( NPCObject )
	if self.BL and self.BL[ NPCObject ] then return false end
	for _, v in pairs( self.Pet ) do
		if v.PetGObject == NPCObject then return v.netuser end
	end
	if self.BL and not self.BL[ NPCObject ] then self.BL[ NPCObject ] = true end
	return false
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 Hunter Leveling Functions
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:GiveHunterXP( netuser, xp )

end

function PLUGIN:CheckHunterLevelUp( netuser, xp )

end

function PLUGIN:getHunterLevel( netuser )

end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 Hunter Global Functions
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function PLUGIN:isHunter( netuser )

end

--[[
-- get_state, set_state = typesystem.GetField( Rust.BasicWildlifeAI, "_state", bf.private_instance )



function PLUGIN:SetState( netuser, _, args )
	if not dev:isDev( netuser ) then return end
	local pet = self:getPetData( netuser )
	self:GetSetState( pet.NPCObject, tonumber(args[1]))
end

function PLUGIN:GetSetState( Object, _ )
	rust.BroadcastChat(tostring(get_state) .. '   ' .. tostring(set_state))
	--rust.BroadcastChat(tostring(EnterState_Attack))
	--Object:EnterState_Attack()
	--rust.BroadcastChat( ' EnterState_Attack set ')
end
]]