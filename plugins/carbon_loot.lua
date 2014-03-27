-- Define plugin variables
PLUGIN.Title = 'carbon_loot'
PLUGIN.Description = 'Carbon Loot System Module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex :(forked from) thomasfn'

local ScriptableObjectCreateMethod = util.FindOverloadedMethod( UnityEngine.ScriptableObject, "CreateInstance", bf.public_static, { System.Type } )

local function ScriptableObjectCreate( typ )
	typ = typesystem.TypeFromMetatype( typ )
	return ScriptableObjectCreateMethod:Invoke( nil, util.ArrayFromTable( System.Object, { typ } ) )
end

function PLUGIN:Init()
	core = cs.findplugin("carbon_core") core:LoadLibrary()
end
function PLUGIN:SetLoot( combatData )
	local createABC = util.FindOverloadedMethod( Rust.NetCull._type, 'InstantiateStatic', bf.public_static, { System.String, UnityEngine.Vector3, UnityEngine.Quaternion } )
	--local itemname = ';deploy_camp_bonfire'
	local itemname = ';drop_lootsack_zombie'
	local coords = combatData.victimPos;
	local v = coords
	local r = tonumber(UnityEngine.Random.value) * 3.14159274 * 2
	v.x = v.x + tonumber(UnityEngine.Mathf.Cos(r) * 1.5)
	v.z = v.z + tonumber(UnityEngine.Mathf.Cos(r) * 1.5)
	v.y = UnityEngine.Terrain.activeTerrain:SampleHeight(v)

	local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, 'LookRotation' )
	local q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( 'System.Object' ), { v } ))
	local arr = util.ArrayFromTable( cs.gettype( 'System.Object' ), { itemname, v, q  })
	cs.convertandsetonarray( arr, 0, itemname, System.String._type )
	cs.convertandsetonarray( arr, 1, v, UnityEngine.Vector3._type )
	cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type )
	local xgameObject = createABC:Invoke( nil, arr )
	local inv = xgameObject:GetComponent( 'Inventory' )
	inv:Clear()

	for k,_ in pairs(combatData.npc.loot) do
		if combatData.netuserData.lvl < tonumber(k+5) and combatData.netuserData.lvl > tonumber(k-5) then
			local roll = func:Roll(0,100)
			for key,_ in pairs(combatData.npc.loot[ tostring(k) ]) do
				if combatData.npc.loot[ tostring(k) ][tostring(key)].chance >= roll then
					local itemtogive = rust.GetDatablockByName( tostring(key) )
					local amount = self:CalculateDropAmount( combatData, k, key )
					inv:AddItemAmount( itemtogive, amount )
				end
			end
			if combatData.netuserData.attributes.luc > 1 then
				roll = roll+(combatData.netuserData.attributes.luc*0.01)+(combatData.netuserData.lvl*0.0005)
				if combatData.netuserData.attributes.luc >=10 then
					local epicRoll = func:Roll(0,100,1)
					if epicRoll <= combatData.netuserData.lvl*.0005 then
						rust.InventoryNotice(combatData.netuser, 'Rare Drop')
						--local randomItem = func:Roll(true,1, 11)
						--local item =
						--self:EpicDrop(combatData, item)
						-- SUPPLY SIGNAL, MILITARY WEAPONS, KEVLAR, ANY BLUEPRINT, TEMPORARY PET
					end
				end
			end
			break
		end
	end
end
function PLUGIN:CalculateDropAmount( combatData, lvl, item )

	local min = combatData.npc.loot[tostring(lvl)][tostring(item)].min
	local max = combatData.npc.loot[tostring(lvl)][tostring(item)].max
	local luck = combatData.netuserData.attributes.luc
	local level = combatData.netuserData.lvl
	min = min+min*(luck*0.01+level*0.0005)
	max = max+max*(luck*0.01+level*0.0005)

	return func:Roll(min,max)
end
--[[

		local itemtogive = rust.GetDatablockByName( 'Wood' )
		local itemtogive1 = rust.GetDatablockByName( 'M4' )
		local itemtogive2 = rust.GetDatablockByName( 'MP5A4' )
		inv:AddItemAmount( itemtogive, 250 )
		inv:AddItemAmount( itemtogive1, 1 )
		inv:AddItemAmount( itemtogive2, 2 )
]]

--[[
function range(init, limit, step)
	step = step or 1
	return function()
		local value = init
		init = init + step
		if limit * step >= value * step then
			return value
		end
	end
end
]]
-- *******************************************
-- PLUGIN:OnDatablocksLoaded()
-- Called when the datablocks are ready to be modified
-- *******************************************
function PLUGIN:OnDatablocksLoaded()
	-- Get default spawn lists
	self.DefaultSpawnlists = self:LoadDefaultSpawnlists()

	-- Read custom loot tables in
	local data = util.GetDatafile( "carbon_loot" )
	if (data:GetText() == "") then
		data:SetText( json.encode( self.DefaultSpawnlists, { indent = true } ) )
		data:Save()
		self.Spawnlists = self.DefaultSpawnlists
	else
		self.Spawnlists = json.decode( data:GetText() )
		self:PatchNewSpawnlists()
	end
end

-- *******************************************
-- PLUGIN:LoadDefaultSpawnlists()
-- Loads the default spawn lists
-- *******************************************
function PLUGIN:LoadDefaultSpawnlists()
	local spawnlists = Rust.DatablockDictionary._lootSpawnLists
	local tblspawnlists = {}
	local keyenum = spawnlists.Keys:GetEnumerator()
	while (keyenum:MoveNext()) do
		local key = keyenum.Current
		local lootspawnlist = spawnlists[ key ]
		local spawnlist = {}
		spawnlist.min = lootspawnlist.minPackagesToSpawn
		spawnlist.max = lootspawnlist.maxPackagesToSpawn
		spawnlist.nodupes = lootspawnlist.noDuplicates
		spawnlist.oneofeach = lootspawnlist.spawnOneOfEach
		spawnlist.packages = {}
		for i=0, lootspawnlist.LootPackages.Length - 1 do
			local entry = lootspawnlist.LootPackages[i]
			local tblentry = {}
			--local t = entry.obj:GetType()
			--if (t:IsAssignableFrom( Rust.Datablock )) then
			--tblentry.object = entry.obj.name
			--end
			--print( entry.obj:GetType().FullName .. " - " .. tostring( entry.obj ) )
			if (entry.obj) then
				tblentry.object = entry.obj.name
			else
				tblentry.object = tostring( entry.obj )
			end
			tblentry.weight = entry.weight
			tblentry.min = entry.amountMin
			tblentry.max = entry.amountMax
			spawnlist.packages[i] = tblentry
		end
		tblspawnlists[ key ] = spawnlist
	end
	return tblspawnlists
end

-- *******************************************
-- PLUGIN:PatchNewSpawnlists()
-- Patches new spawn lists into the server
-- *******************************************
local LootWeightedEntry = cs.gettype( "LootSpawnList+LootWeightedEntry, Assembly-CSharp" )
function PLUGIN:PatchNewSpawnlists()
	local spawnlistobjects = {}
	local cnt = 0
	for k, v in pairs( self.Spawnlists ) do
		local obj = ScriptableObjectCreate( Rust.LootSpawnList )
		obj.minPackagesToSpawn = v.min
		obj.maxPackagesToSpawn = v.max
		obj.noDuplicates = v.nodupes
		obj.spawnOneOfEach = v.oneofeach
		obj.name = k
		spawnlistobjects[ k ] = obj
		cnt = cnt + 1
	end
	for k, v in pairs( self.Spawnlists ) do
		local entrylist = {}
		local i = 0
		local is = "0"
		while (v.packages[ is ]) do
			local entry = v.packages[ is ]
			local entryobj = new( LootWeightedEntry )
			entryobj.amountMin = entry.min
			entryobj.amountMax = entry.max
			entryobj.weight = entry.weight
			if (spawnlistobjects[ entry.object ]) then
				entryobj.obj = spawnlistobjects[ entry.object ]
				if (not entryobj.obj) then
					error( "Couldn't find spawn list by name '" .. entry.object .. "'!" )
				end
			else
				entryobj.obj = rust.GetDatablockByName( entry.object )
				if (not entryobj.obj) then
					error( "Couldn't find datablock by name '" .. entry.object .. "'!" )
				end
			end
			entrylist[ i + 1 ] = entryobj
			i = i + 1
			is = tostring( i )
		end
		spawnlistobjects[ k ].LootPackages = util.ArrayFromTable( LootWeightedEntry, entrylist )
	end
	local spawnlists = Rust.DatablockDictionary._lootSpawnLists
	spawnlists:Clear()
	for k, v in pairs( self.Spawnlists ) do
		spawnlists:Add( k, spawnlistobjects[ k ] )
	end
	print( tostring( cnt ) .. " custom loot tables were loaded!" )
end