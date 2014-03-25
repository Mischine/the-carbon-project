PLUGIN.Title = 'carbon_hunter'
PLUGIN.Description = 'hunter class module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin('carbon_core') core:LoadLibrary()

	self:AddChatCommand( 'pet', self.Pet)
	self:AddChatCommand( 'killpet', self.KillPet )
	self:AddChatCommand( 'petatt', self.PetAttack )
	self:AddChatCommand( 'petcall', self.PetCallBack )
	self:AddChatCommand( 'petstay', self.PetStay )
	--self:AddChatCommand( 'petfollow', self.PetCallBack )
	--self:AddChatCommand( 'tppet', self.PetTP )

	self.Pets={}
end

function PLUGIN:Pet( netuser, _, _ )
	if not dev:isDev( netuser ) then return end
	if self.Pets and self.Pets[ netuser ] then rust.BroadcastChat( 'You already have a pet!' ) return end
	self.Pets[ netuser ] = {}
	local createABC = util.FindOverloadedMethod( Rust.NetCull._type, "InstantiateClassic", bf.public_static, { System.String, UnityEngine.Vector3, UnityEngine.Quaternion, System.Int32 } )
	local itemname = "Bear"
	--local itemname = "Wolf"
	local coords = netuser.playerClient.lastKnownPosition
	coords.y = coords.y + 5
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
	self.Pets[ netuser ][ 'PetGObj' ] = xgameObject
	self.Pets[ netuser ][ 'NavMesh' ] = xgameObject:GetComponent( 'NavMeshMovement' )
	self.Pets[ netuser ][ 'gObject' ] = gObject
	self.Pets[ netuser ][ 'pClient' ] = netuser.playerClient
	self.Pets[ netuser ][ 'char' ] = char
	self.Pets[ netuser ][ 'npcChar' ] = xgameObject:GetComponent( 'Character' )
	self.Pets[ netuser ][ 'attack' ] = false
	self.Pets[ netuser ][ 'stay' ] = false
	self.Pets[ netuser ].HosAI:GoScentblind( 3 )
	self.Pets[ netuser ][ 'timer' ] = timer.Repeat( 1,
	function()
		local coords = self.Pets[ netuser ].BaseWildAI.transform:get_position()
		local mycoords = self.Pets[ netuser ].pClient.lastKnownPosition
		local dis = func:Distance3D( coords.x, coords.y, coords.z, mycoords.x, mycoords.y, mycoords.z )
		rust.BroadcastChat( 'Attack: ' .. tostring( self.Pets[ netuser ].attack ))
		rust.BroadcastChat( 'TargID: ' .. tostring( self.Pets[ netuser ][ 'HosAI' ]._targetTD))
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
end

-- TODO: attacking works fine, but when I callback, it keeps attacking me instead... :(
function PLUGIN:PetAttack( netuser, _ ,args )
	if not dev:isDev( netuser ) then return end
	if self.Pets and not self.Pets[ netuser ] then rust.BroadcastChat( 'You dont have a pet.!' ) return end
	local pet = self.Pets[ netuser ]
	local b, targuser = rust.FindNetUsersByName( tostring(args [1] ))
	if not b then rust.SendChatToUser( netuser, core.sysname, 'Invalid target!' ) return end
	local char = rust.GetCharacter( targuser )
	local gObject = char:get_gameObject()
	pet.attack = true
	pet.HosAI:GoScentblind( 0 )
	pet.NavMesh:SetMoveTarget( gObject, 7 )
end

function PLUGIN:PetCallBack( netuser )
	if not dev:isDev( netuser ) then return end
	if self.Pets and not self.Pets[ netuser ] then rust.BroadcastChat( 'You dont have a pet.!' ) return end
	local pet = self.Pets[ netuser ]
	local mycoords = self.Pets[ netuser ].pClient.lastKnownPosition
	pet.HosAI:LoseTarget()
	pet.HosAI:GoScentblind( 5 )
	pet.attack = false
	pet.stay = false
	pet.NavMesh:SetMovePosition( mycoords, 9 )
end

function PLUGIN:PetStay( netuser )
	if not dev:isDev( netuser ) then return end
	if self.Pets and not self.Pets[ netuser ] then rust.BroadcastChat( 'You dont have a pet.!' ) return end
	local pet = self.Pets[ netuser ]
	pet.stay = true
	pet.attack = false
	pet.HosAI:GoScentblind( 3 )
	pet.NavMesh:Stop()
end

function PLUGIN:PetTP( netuser )
	local coords = self.Pets[ netuser ].BaseWildAI.transform:get_position()
	coords.x = coords.x + 50
	coords.y = coords.y + 10
	self.Pets[ netuser ].BaseWildAI.transform:set_position(coords)
	rust.BroadcastChat( '' )
end

function PLUGIN:KillPet( netuser, _, _ )
	if self.Pets[ netuser ] and self.Pets[ netuser ].timer then
		--self:ObjectRemove( self.Pets[ netuser ].PetGObj )
		local mycoords = self.Pets[ netuser ].pClient.lastKnownPosition
		mycoords.x = mycoords.x + math.random( 500 )
		mycoords.z = mycoords.z + math.random( 500 )
		self.Pets[ netuser ].HosAI:GoScentblind( 20 )
		self.Pets[ netuser ].NavMesh:SetMovePosition( mycoords, 6 )
		self.Pets[ netuser ].timer:Destroy()
		self.Pets[ netuser ] = nil
		rust.BroadcastChat( 'Pet has been released!' )
	else
		rust.BroadcastChat( 'No Pet timer found!' )
	end
end

function PLUGIN:ObjectRemove( gObject )



	--[[
	local NetCullRemove = util.FindOverloadedMethod( Rust.NetCull._type, "Destroy", bf.public_static, { UnityEngine.GameObject} )
	local arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { gObject } )  ;
	cs.convertandsetonarray( arr, 0, gObject , UnityEngine.GameObject._type )
	NetCullRemove:Invoke( nil, arr )
	rust.BroadcastChat( 'Removed GameObject' )
	]]
end
