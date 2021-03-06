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
	self:AddChatCommand( 'petdebug', self.PetDebug )
	--self:AddChatCommand( 'tppet', self.PetTP )

	self.Pets = {}      -- Database of pets
	self.BL = {}        -- Blacklist for NPC that aren't pets [ To increase performance ]
end

function PLUGIN:PetDebug( netuser, cmd, args )
	if not dev:isDev( netuser ) then return end
	if not args[2] then rust.Notice( netuser, 'Missing argument 2, "true/false"' )return end
	local targuser = netuser
	if args[1] then
		local b, targuser = rust.FindNetUsersByName( args[1] )
		if not b then rust.SendChatToUser( netuser, core.sysname, 'player not found with name ' .. args[1] ) return end
	end
	local pet = self:getPetData( netuser )
	if not pet then rust.Notice( netuser , 'No pet found.' )return end
	local set = args[2]:lower()
	if set == 'true' then
		pet.debug = true
		rust.Notice( netuser ,'Pet debug set to true' )
	elseif set == 'false' then
		pet.debug = false
		rust.Notice( netuser ,'Pet debug set to false' )
	else
		rust.Notice( netuser ,'Invalid argument.' )
	end

end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 Pet OnInitiate Functions
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function PLUGIN:PetCall( netuser, _, _ )
	if not dev:isDev( netuser ) then return end
	if self:hasPet( netuser ) then rust.Notice( netuser,  'Your pet is already summoned!' ) return end
	self.Pets[ netuser ] = {}
	----------------
	local createABC = util.FindOverloadedMethod( Rust.NetCull._type, 'InstantiateStatic', bf.public_static, { System.String, UnityEngine.Vector3, UnityEngine.Quaternion } )
	local itemname = ':bear_prefab'
	local coords = netuser.playerClient.lastKnownPosition
	coords.x = math.random( coords.x - 50, coords.x + 50 )
	coords.z = math.random( coords.z - 50, coords.z + 50 )
	coords.y = UnityEngine.Terrain.activeTerrain:SampleHeight(coords) + 1
	local char = rust.GetCharacter( netuser )
	local gObject = char:get_gameObject()
	local v = coords
	local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, 'LookRotation' )
	local q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( 'System.Object' ), { v } ))
	local arr = util.ArrayFromTable( cs.gettype( 'System.Object' ), { itemname, v, q  } )
	cs.convertandsetonarray( arr, 0, itemname, System.String._type )
	cs.convertandsetonarray( arr, 1, v, UnityEngine.Vector3._type )
	cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type )
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
	self.Pets[ netuser ][ 'idMain' ] = netuser.playerClient.rootControllable.idMain
	self.Pets[ netuser ][ 'char' ] = char
	self.Pets[ netuser ][ 'npcChar' ] = xgameObject:GetComponent( 'Character' )
	self.Pets[ netuser ][ 'netuser' ] = netuser
	self.Pets[ netuser ][ 'TakeDamage' ] = xgameObject:GetComponent( 'TakeDamage' )
	self.Pets[ netuser ][ 'type' ] = 1                                                      -- 1 == wolf, 2 == bear
	self.Pets[ netuser ][ 'dmg' ] = 5                                                       -- Configure this.
	self.Pets[ netuser ][ 'RunSpeed' ] = 9                                                  -- Configure this.
	self.Pets[ netuser ][ 'WalkSpeed' ] = 4                                                 -- Configure this.
	self.Pets[ netuser ][ 'RegenRate' ] = 0.3                                               -- Configure this.
	self.Pets[ netuser ][ 'state' ] = 0
	self.Pets[ netuser ][ 'attackspeed' ] = 3
	self.Pets[ netuser ][ 'NextAttack' ] = self.Pets[ netuser ].attackspeed
	self.Pets[ netuser ][ 'debug' ] = true
	self.Pets[ netuser ].TakeDamage.maxHealth = 200
	self.Pets[ netuser ].TakeDamage.health = self.Pets[ netuser ].TakeDamage.maxHealth
	self.Pets[ netuser ].HosAI:GoScentBlind( 3 )
	self.Pets[ netuser ] = self:SyncPetPropertiesWithPlayerStats( self.Pets[ netuser ] )
	if self.Pets[ netuser ] then timers:InitTimer( netuser, self.Pets[ netuser ] ) rust.SendChatToUser( netuser, 'Your pet has been called!' )
	else rust.Notice( netuser, 'Pet data not found, try again.' ) return end
end

--[[ PetStates

	idle                  = 0
	roaming               = 1

	returning             = 2

	following ( walk )    = 3
	following ( run )     = 4
	stay                  = 7

	npcattack             = 5
	playerattack          = 6

	// npcalonetime          = 8

 ]]


function PLUGIN:PetUpdate( netuser, pet )
	if pet.TakeDamage.health <= 0 then self:OnPetKilled( pet ) return end
	------------------------
	-- DistanceCalculator --
	local coords = pet.BaseWildAI.transform:get_position()
	local mycoords = pet.pClient.lastKnownPosition
	local dis = func:round(UnityEngine.Vector3.Distance( coords, mycoords ),2 )

	--[ [ Debug
	if pet.debug then
		if not pet[ 'update' ] then pet[ 'update' ] = 0 end
		if pet.update > 2 then
			rust.BroadcastChat( tostring('Distance: '..dis..'  |State: '..pet.state..' | ScentBlind: '..tostring(pet.HosAI:IsScentBlind() )..'  | NextScent: '..tostring(pet.HosAI.nextScentListenTime)))
			pet.update = 0
		else
			pet.update = pet.update + 1
		end
	end
	-- ]]

	------------------------
	-- CombatIntelligence --
	if pet.target and pet.targetObject then rust.BroadcastChat( 'Pet changed to state 5 ' ) pet.state = 5 end
	if pet.state == 5 or pet.state == 6 then
		local attdis = func:round(UnityEngine.Vector3.Distance( pet.targetObject.transform.position, coords ),2 )
		rust.BroadcastChat( 'attdis: ' .. tostring(attdis))
		if pet.target and pet.target.health <= 0 then
			pet.NavMesh:Stop()
			pet.HosAI:GoScentBlind( 2 )
			pet.state = 0
			-- self:GivePetXP( pet, xp ) // Maybe?
			if pet.target then pet.target = nil end if pet.targetObject then pet.targetObject = nil end
		end

		-- Player
		if pet.state == 6 then
			if attdis > 5 then
				pet.NavMesh:SetMoveTarget( pet.targetObject, pet.RunSpeed )
			elseif attdis < 15 then
				pet.HosAI.nextScentListenTime = 0
			end
		-- NPC
		elseif pet.state == 5 then
			pet.HosAI:GoScentBlind( 2 )
			if attdis > 3 then
				pet.NavMesh:SetMoveTarget( pet.targetObject, pet.RunSpeed )
			else
				if pet.NextAttack <= 0 then
					anim:PetAttackAnim( pet )
					rust.BroadcastChat( 'Pet Hit for: ' .. tostring(pet.dmg) )
					pet.target.health = pet.target.health - pet.dmg
					rust.BroadcastChat( 'New health: ' .. tostring(pet.target.health) )
					pet.NextAttack = pet.attackspeed
				else
					pet.NextAttack = pet.NextAttack - 1
				end
				if pet.target.health <= 0 then
					self:PetStopAttack( pet )
				end
			end
		end
	end

	--------------------------
	-- MovementIntelligence --
	if pet.state == 0 or pet.state == 1 or pet.state == 2 or pet.state == 3 or pet.state == 4 then
		rust.BroadcastChat('Movement.')
		pet.HosAI:GoScentBlind( 2 )
		if pet.target then pet.target = nil end if pet.targetObject then pet.targetObject = nil end
		if dis > 8 and dis < 10 then
			mycoords.x = mycoords.x + math.random( 3 )
			mycoords.z = mycoords.z + math.random( 3 )
			pet.NavMesh:SetMovePosition( mycoords, 1.5 )
			pet.state = 2
		elseif dis >= 12 then
			if self.Pets[ netuser ].char.stateFlags.sprint then
				pet.NavMesh:SetMovePosition( mycoords, pet.RunSpeed )
				pet.state = 4
			elseif not self.Pets[ netuser ].char.stateFlags.sprint then
				pet.NavMesh:SetMovePosition( mycoords, pet.WalkSpeed )
				pet.state = 3
			end
		else
			pet.state = 1
		end
	end

	-----------------------------
	-- Pet Regen % Unagressive --
	if pet.state ~= 6 then
		pet.HosAI:GoScentBlind( 2 )
		if pet.TakeDamage.health < pet.TakeDamage.MaxHealth then
			if pet.state == 0 or pet.state == 1 then
				pet.TakeDamage.health = pet.TakeDamage.health + pet.RegenRate
			elseif pet.state == 2 then
				pet.TakeDamage.health = pet.TakeDamage.health + (pet.RegenRate * 0.75)
			elseif pet.state == 3 then
				pet.TakeDamage.health = pet.TakeDamage.health + (pet.RegenRate * 0.50)
			elseif pet.state == 4 then
				pet.TakeDamage.health = pet.TakeDamage.health + (pet.RegenRate * 0.35)
			end
		end
	end
	-----------------
	-- AbuseChecks --
	if pet.state ~= 8 and dis > 60 then
		self:PetReturnToOwnerTeleport( pet ) pet.state = 0
		if pet.target then pet.target = nil end
		if pet.targetObject  then pet.targetObject = nil end
	end
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 Pet Combat Functions
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function PLUGIN:PetAttackPlayer( combatData, takedamage, pet )
rust.BroadcastChat( 'PLAYER ATTACK START' )
	if not combatData.vicuser or not takedamage then return end
	if pet.target == takedamage then return end
rust.BroadcastChat( 'PLAYER ATTACK PAST CHECK' )
	local TargObject = rust.GetCharacter( combatData.vicuser ):get_gameObject()
	pet.target = takedamage
	pet.targetObject = TargObject
	pet.state = 6
	pet.NavMesh:SetMoveTarget( pet.targetObject, pet.RunSpeed )
end

function PLUGIN:PetAttackNPC( combatData, takedamage, pet )
rust.BroadcastChat( 'NPC ATTACK START' )
	if not combatData.npc or not combatData.npc.gObject or not takedamage then return end
	if pet.target == takedamage then return end
rust.BroadcastChat( 'NPC ATTACK PAST CHECK' )
	local TargObject = combatData.npc.gObject
	pet.target = takedamage
	pet.state = 5
	pet.targetObject = TargObject
	pet.NavMesh:SetMoveTarget( pet.targetObject, pet.RunSpeed )
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 Pet Dynamic Functions
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

--[[
	Pets get hungry, needs food.
	 Pet runs away because he needs some alone time.
 ]]

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
	if not self:hasPet( netuser ) then rust.Notice( netuser,  'You dont have a pet!' ) return end
	local pet = self:getPetData( netuser )
	if pet then self:PetFreeze( pet ) end
end

--[[ TODO: Redo this.
function PLUGIN:cmdPetAttack( netuser, _, args )
	if not dev:isDev( netuser ) then return end
	if not self:hasPet( netuser ) then rust.Notice( netuser,  'You dont have a pet!' ) return end
	local pet = self.Pets[ netuser ]
	local b, targuser = rust.FindNetUsersByName( args[1] )
	if not b then rust.SendChatToUser( netuser, core.sysname, 'Invalid target' ) return false end
	local char = rust.GetCharacter( targuser )
	if not char then return end
	local gObject = char:get_gameObject()
	if not gObject then return end
	self:PetAttack( pet, gObject )
end
]]

-- TODO: Refine.
function PLUGIN:cmdReleasePet( netuser, _, _ )
	if self.Pets[ netuser ] and timers.Pets[ netuser ] then
		local coords = netuser.playerClient.lastKnownPosition
		coords.x = math.random( coords.x - 500, coords.x + 500 )
		coords.z = math.random( coords.z - 500, coords.z + 500 )
		coords.y = UnityEngine.Terrain.activeTerrain:SampleHeight(coords) + 1
		self.Pets[ netuser ].HosAI:GoScentBlind( 20 )
		self.Pets[ netuser ].NavMesh:SetMovePosition( coords, 6 )
		timers.Pets[ netuser ]:Destroy()
		timer.Once( 15, function()
			self.Pets[ netuser ] = nil
		end)
		rust.SendChatToUser(netuser, core.sysname, 'Pet has been released!' )
	elseif self.Pets[ netuser ] and not timers.Pets[ netuser ] then
		self.Pets[ netuser ] = nil
	elseif timers.Pets[ netuser ] and not self.Pets[ netuser ] then
		timers.Pets[ netuser ]:Destroy()
	else
		rust.SendChatToUser(netuser, core.sysname, 'No Pet timer found!' )
	end
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--                 Pet Utility Functions
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function PLUGIN:PetFreeze( pet )
	pet.stay = 7
	pet.HosAI:GoScentBlind( 3 )
	pet.NavMesh:Stop()
end

function PLUGIN:PetReturnToOwner( pet )
	local mycoords = pet.pClient.lastKnownPosition
	pet.HosAI:LoseTarget()
	pet.HosAI:GoScentBlind( 5 )
	pet.state = 0
	if pet.target then pet.target = nil end if pet.targetObject  then pet.targetObject = nil end
	pet.NavMesh:SetMovePosition( mycoords, pet.RunSpeed )
end

function PLUGIN:PetReturnToOwnerTeleport( pet )
	local coords = pet.pClient.lastKnownPosition
	coords.x = math.random( coords.x - 10, coords.x + 10 )
	coords.z = math.random( coords.z - 10, coords.z + 10 )
	coords.y = UnityEngine.Terrain.activeTerrain:SampleHeight(coords) + 1
	rust.SendChatToUser( pet.netuser, core.sysname, 'Pet has been teleported back to you.' )
	pet.state = 0
	if pet.target then pet.target = nil end if pet.targetObject  then pet.targetObject = nil end
	pet.NavAgent:Warp( coords )
end

function PLUGIN:SyncPetPropertiesWithPlayerStats( pet )
	-- TODO: Make once Hunter XP system is complete. ( so when we know all the attributes thats gonna effect Pets )
end

function PLUGIN:OnPetKilled( pet )

end

function PLUGIN:PetStopAttack( pet )
	if pet.target then pet.target = nil end if pet.targetObject then pet.targetObject = nil end
	pet.state = 0
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