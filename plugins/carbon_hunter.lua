PLUGIN.Title = 'carbon_hunter'
PLUGIN.Description = 'hunter class module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin('carbon_core') core:LoadLibrary()

	self:AddChatCommand( 'pet', self.Pet)
	self:AddChatCommand( 'killpet', self.KillPet)

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
	local HostileWildlifeAI = xgameObject:GetComponent( 'HostileWildlifeAI' )
	local navmesh = xgameObject:GetComponent( 'NavMeshMovement' )
	self.Pets[ netuser ][ 'HosAI' ] = HostileWildlifeAI
	self.Pets[ netuser ][ 'PetGObj' ] = xgameObject
	self.Pets[ netuser ][ 'NavMesh' ] = navmesh
	HostileWildlifeAI:GoScentblind( 3 )
	self.Pets[ netuser ][ 'timer' ] = timer.Repeat( 2,
		function()
			self.Pets[ netuser ].HosAI:GoScentblind( 5 )
			self.Pets[ netuser ].NavMesh:SetMoveTarget( gObject, 7 )
		end)
end

function PLUGIN:KillPet( netuser, _, _ )
	if self.Pets[ netuser ] and self.Pets[ netuser ].timer then
		self.Pets[ netuser ].timer:Destroy()
		rust.BroadcastChat( 'Pet timer Destroyed!' )
	else
		rust.BroadcastChat( 'No Pet timer found!' )
	end
end
