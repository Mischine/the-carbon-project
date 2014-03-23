PLUGIN.Title = 'carbon_sandbox_b'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin('carbon_core') core:LoadLibrary()
	self:AddChatCommand( 'a', self.a )
	self:AddChatCommand( 'b', self.SpawnAI )
	self:AddChatCommand( 'c', self.CheckGameObject )
	self:AddChatCommand( 'd', self.DestroyTimer )

	self.timer = {}
end

function PLUGIN:a(netuser, _, _)

	-- >>>>>>>>>>>>>>>>>>>> EXPLOSIVES! <<<<<<<<<<<<<<<<<<<<
	local createABC = util.FindOverloadedMethod( Rust.NetCull._type, 'InstantiateStatic', bf.public_static, { System.String, UnityEngine.Vector3, UnityEngine.Quaternion } )
	local itemname = ';explosive_charge'
	local coords = netuser.playerClient.lastKnownPosition;
	coords.y = coords.y - 1.65
	local v = coords
	local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, 'LookRotation' )
	local q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( 'System.Object' ), { v } ))
	local arr = util.ArrayFromTable( cs.gettype( 'System.Object' ), { itemname, v, q  } )
	cs.convertandsetonarray( arr, 0, itemname, System.String._type )
	cs.convertandsetonarray( arr, 1, v, UnityEngine.Vector3._type )
	cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type )
	local xgameObject = createABC:Invoke( nil, arr )

	--[[
	-- >>>>>>>>>>>>>>>>>>>> LOOTBAG! <<<<<<<<<<<<<<<<<<<<
	local createABC = util.FindOverloadedMethod( Rust.NetCull._type, 'InstantiateStatic', bf.public_static, { System.String, UnityEngine.Vector3, UnityEngine.Quaternion } )
	--local itemname = ';deploy_camp_bonfire'
	local itemname = ';drop_lootsack_zombie'
	local coords = netuser.playerClient.lastKnownPosition;
	local v = coords
	v.y = v.y - 1.65
	local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, 'LookRotation' )
	local q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( 'System.Object' ), { v } ))
	local arr = util.ArrayFromTable( cs.gettype( 'System.Object' ), { itemname, v, q  } )
	cs.convertandsetonarray( arr, 0, itemname, System.String._type )
	cs.convertandsetonarray( arr, 1, v, UnityEngine.Vector3._type )
	cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type )
	local xgameObject = createABC:Invoke( nil, arr )
	local inv = xgameObject:GetComponent( 'Inventory' )
	rust.BroadcastChat( tostring( inv ))
	inv:Clear()
	local itemtogive = rust.GetDatablockByName( 'Wood' )
	local itemtogive1 = rust.GetDatablockByName( 'M4' )
	local itemtogive2 = rust.GetDatablockByName( 'MP5A4' )
	inv:AddItemAmount( itemtogive, 250 )
	inv:AddItemAmount( itemtogive1, 1 )
	inv:AddItemAmount( itemtogive2, 2 )
	]]
	--[[
	if itemname == ';deploy_camp_bonfire' then
		if not self.timer[ 'campfiretimer' ] then
			local campinv = inv
			local lewood = rust.GetDatablockByName( 'Wood' )
			rust.BroadcastChat( 'Creating campfiretimer...' )
			self.timer[ 'campfiretimer' ] = timer.Repeat( 600, function()
				rust.BroadcastChat( 'Refilling campfire(s)' )
				campinv:Clear()
				campinv:AddItemAmount( lewood, 250 )
			end)
		end
	end
	]]
	--func:DumpGameObject(xgameObject)
end

function PLUGIN:SpawnAI(netuser, cmd, arg)
	local createABC = util.FindOverloadedMethod( Rust.NetCull._type, "InstantiateClassic", bf.public_static, { System.String, UnityEngine.Vector3, UnityEngine.Quaternion, System.Int32 } )
	local itemname = "Bear"
	--local itemname = "Wolf"
	--local itemname = "MutantBear"

	for i=0, 20 do
		local coords = netuser.playerClient.lastKnownPosition
		coords.x = func:Roll( false, coords.x-20, coords.x+20)
		coords.z = func:Roll( false, coords.z-20, coords.z+20)
		--coords.z = coords.z + 25
		coords.y = coords.y + 5
		--local char = rust.GetCharacter( netuser )
		--local gObject = char:get_gameObject()
		local v = coords
		local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, "LookRotation" )
		local q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( "System.Object" ), { v } ))
		local arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { itemname, v, q , 0 } )  ;
		cs.convertandsetonarray( arr, 0, itemname, System.String._type ) cs.convertandsetonarray( arr, 1, v, UnityEngine.Vector3._type )
		cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type ) cs.convertandsetonarray( arr, 3, 0, System.Int32._type )
		local xgameObject = createABC:Invoke( nil, arr )
		--func:DumpGameObject(xgameObject)
		--local HostileWildlifeAI = xgameObject:GetComponent( 'HostileWildlifeAI' )
		--HostileWildlifeAI:GoScentblind( 5 )
		local navmesh = xgameObject:GetComponent( 'NavMeshMovement' )
		--timer.Repeat( 2, 20, function() navmesh:SetMoveTarget( gObject, 7 )  end)
		--timer.Once( 10, function() HostileWildlifeAI.nextScentListenTime = 0 rust.BroadcastChat( 'Scent reset' )  end)
		timer.Once( 6, function()
			navmesh:SetMoveTarget( gObject, 15 )
		end)
		--rust.BroadcastChat( 'targetLookRotation: ' .. navmesh.targetLookRotation)
		--rust.BroadcastChat( 'NavMeshAgent: ' .. tostring(navmesh._agent))
	end
	timer.Once(5, function() rust.BroadcastChat( 'Yeh... you\'re fucked.' ) end)
end

function PLUGIN:CheckGameObject( netuser, cmd, args )
	local char = rust.GetCharacter( netuser )
	local gObject = char:get_gameObject()
	rust.BroadcastChat( tostring( gObject ))
end

function PLUGIN:DestroyTimer( netuser, cmd, args )
	if self.timer[ 'campfiretimer' ] then
		rust.BroadcastChat( 'Destroying campfiretimer...' )
		self.timer[ 'campfiretimer' ]:Destroy()
		rust.BroadcastChat( 'Destroyed campfiretimer!' )
	end
end

--[[
		-- --- Structure Wood ---
		';struct_wood_wall',
		';struct_wood_doorway',
		';struct_wood_ceiling',
		';struct_wood_windowframe',
		';struct_wood_stairs',
		';struct_wood_ramp',
		';struct_wood_foundation',

		-- --- Structure Metal ---
		';struct_metal_foundation',
		';struct_metal_wall',
		';struct_metal_doorframe',
		';struct_metal_ceiling',
		';struct_metal_stairs',
		';struct_metal_windowframe',
		';struct_metal_ramp',
		';struct_metal_pillar',
		';deploy_metalwindowbars',

		-- ------Door--------
		';deploy_wood_door',
		';deploy_metal_door',

		-- ------ Storage -------
		';deploy_wood_box',
		';deploy_wood_storage_large',
		';deploy_small_stash',

		-- ----- Attack and protect -----
		';deploy_largewoodspikewall',
		';deploy_woodspikewall',
		';deploy_wood_barricade',
		';deploy_woodgateway',
		';deploy_woodgate',

		-- -- Base --
		';deploy_camp_bonfire',
		';deploy_wood_shelter',
		';deploy_furnace',
		';deploy_workbench',
		';deploy_camp_sleepingbag',
		';deploy_singlebed',

		-- -- Ressource --
		';res_woodpile',
		';res_ore_1',
		';res_ore_2',

		-- -- Other --
		';drop_lootsack_zombie',
		';drop_lootsack',
		';sleeper_male',
		';explosive_charge'
--]]