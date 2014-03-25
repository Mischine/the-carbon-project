PLUGIN.Title = 'carbon_sandbox_b'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin('carbon_core') core:LoadLibrary()
	self:AddChatCommand( 'a', self.a )
	self:AddChatCommand( 'as', self.AirStrike )
	self:AddChatCommand( 'b', self.SpawnAI )
	-- self:AddChatCommand( 'c', self.CheckGameObject )
	self:AddChatCommand( 'd', self.DestroyTimer )
	self:AddChatCommand( 'gui', self.gui )
	self:AddChatCommand( 'cc', self.cc )

	self.timer = {}
end

function PLUGIN:gui( netuser, cmd, args )
	local rec = unityEngine.Rect
	rust.BroadcastChat( tostring (rec) )
	UnityEngine.GUI:Box(rec, "Loader Menu")

end

function PLUGIN:cc( netuser )
	local char = rust.GetCharacter( netuser )
	local gObject = char:get_gameObject()
	local cc = netuser:GetComponent( 'CharacterController' )
	rust.BroadcastChat( tostring(cc ))
end

function PLUGIN:AirStrike( netuser, _, args )
	if not dev:isDev(netuser ) then return end
	if not args[1] then rust.BroadcastChat('/as "Name"') return end
	local b, targuser = rust.FindNetUsersByName( tostring(args [1] ))
	if not b then rust.SendChatToUser( netuser, core.sysname, 'Invalid target!' ) return end
	local coords = targuser.playerClient.lastKnownPosition
	coords.y = coords.y - 1.8
	timer.Repeat( 0.34, 20, function() self:UnloadAirstrike( coords ) end)
--[[timer.Once( 1,function() rust.BroadcastChat('CareX','B-2 Spirit, Can you read me? over.')
		timer.Once( 2, function() rust.BroadcastChat('B-2 Spirit','Loud and clear, sir! over.')
			timer.Once( 3, function() rust.BroadcastChat('CareX','I\'ve got a new target for you guys! over.')
				timer.Once( 3, function() rust.BroadcastChat('B-2 Spirit','Send in the coordinations! We\'re ready, sir. over.')
					timer.Once( 3, function() rust.BroadcastChat('CareX','New coordinates are send. Did you receive? over.')
						timer.Once( 2, function() rust.BroadcastChat('B-2 Spirit','Coordinates received! 5 seconds to destination. over.')
							timer.Once( 2, function() rust.BroadcastChat('CareX','Keep me updated! over and out!')
								timer.Once(1, function() timer.Repeat( 0.34, 20, function() self:UnloadAirstrike( coords ) end)
									timer.Once( 7, function() rust.BroadcastChat('B-2 Spirit','Hit confirmed! I repeat, hit confirmed! over.')
										timer.Once( 2, function() rust.BroadcastChat('CareX','Excellent job! return back to base! over and out.')
										end)
									end)
								end)
							end)
						end)
					end)
				end)
			end)
		end)
	end)
]]
end

function PLUGIN:UnloadAirstrike( co2 )
	local createABC = util.FindOverloadedMethod( Rust.NetCull._type, 'InstantiateStatic', bf.public_static, { System.String, UnityEngine.Vector3, UnityEngine.Quaternion } )
	local itemname = ';explosive_charge'
	local coords = co2
	coords.x = math.random(coords.x-10, coords.x+10)
	coords.z = math.random(coords.z-10, coords.z+10)
	local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, 'LookRotation' )
	local q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( 'System.Object' ), { coords } ))
	local arr = util.ArrayFromTable( cs.gettype( 'System.Object' ), { itemname, coords, q  } )
	cs.convertandsetonarray( arr, 0, itemname, System.String._type )
	cs.convertandsetonarray( arr, 1, coords, UnityEngine.Vector3._type )
	cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type )
	local xgameObject = createABC:Invoke( nil, arr )
	local te = xgameObject:GetComponent('TimedExplosive')
	te.explosionRadius = 30
	te.damage = 70
	timer.NextFrame(function() te:Explode() end)
end

function PLUGIN:a(netuser, _, _)
	-- >>>>>>>>>>>>>>>>>>>> EXPLOSIVES! <<<<<<<<<<<<<<<<<<<<
	local createABC = util.FindOverloadedMethod( Rust.NetCull._type, 'InstantiateStatic', bf.public_static, { System.String, UnityEngine.Vector3, UnityEngine.Quaternion } )
	local itemname = ';explosive_charge'
	local coords = netuser.playerClient.lastKnownPosition
	coords.x = func:Roll( false, coords.x-10, coords.x+10)
	coords.z = func:Roll( false, coords.z-10, coords.z+10)
	coords.y = coords.y - 1.8
	local v = coords
	local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, 'LookRotation' )
	local q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( 'System.Object' ), { v } ))
	local arr = util.ArrayFromTable( cs.gettype( 'System.Object' ), { itemname, v, q  } )
	cs.convertandsetonarray( arr, 0, itemname, System.String._type )
	cs.convertandsetonarray( arr, 1, v, UnityEngine.Vector3._type )
	cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type )
	local xgameObject = createABC:Invoke( nil, arr )
	local te = xgameObject:GetComponent('TimedExplosive')
	te.explosionRadius = 20
	rust.BroadcastChat( tostring(te.explosionRadius))
	te.damage = 100
	rust.BroadcastChat( tostring(te.damage))
	timer.NextFrame(function() te:Explode() rust.BroadcastChat( 'Explode!' )end)

	-- coords.y = UnityEngine.Terrain.activeTerrain:SampleHeight(coords)

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

function PLUGIN:ModifyDamage( _, damage)
    if (damage.attacker.client) then
        local netuser = damage.attacker.client.netUser
        if ( netuser:CanAdmin() ) then
            if ( damage.extraData ~= nil ) then
                if (damage.extraData.dataBlock ~= nil) then
                   if (damage.extraData.dataBlock.name ~= nil) then
                   local view_coor = S_TraceEyes( netuser )
                    if not view_coor then
                       return
                    end
                   view_coor = view_coor.point
                   self:S_ResetVariables()
                   self.ObjectTableID = 5
                   self.ObjectPosition = { view_coor.x, view_coor.y, view_coor.z }
                   self.hObject = self:S_CreateObject( netuser, self.ObjectTableID, self.ObjectPosition, self.ObjectRotation)
                    print(">> SHOOT :: ".. netuser.displayName)
                    end
                end
           end
       end
   end
end