PLUGIN.Title = "Add Resource"
PLUGIN.Description = "Add Resource in map"
PLUGIN.Author = "Guewen and Thx Rexas & Luc"
PLUGIN.Version = 1.4

function PLUGIN:Init()

    oxmin_Plugin = plugins.Find("oxmin")
    if oxmin_Plugin or oxmin then
        self.FLAG_RESOURCE = oxmin.AddFlag( "resource" )
    end

    MapResource = util.GetDatafile( "resource" )

    local txt = MapResource:GetText()
    if (txt ~= "") then
        ResourcePlugin = json.decode( txt )
    else
        ResourcePlugin = {}
    end

    self:AddCommand("resource", "list", self.ViewResource)
    self:AddCommand("resource", "goto", self.Resourcefind)

    self:AddCommand("resource", "remove", self.ResourceRemove)
    self:AddChatCommand("resourceremove", self.ResourceRemove)
    self:AddChatCommand("removeresource", self.ResourceRemove)

    self:AddChatCommand("resourceadd", self.ResourceAdd)
    self:AddChatCommand("add", self.ResourceAdd)
    self:AddChatCommand("addresource", self.ResourceAdd)

    self:AddChatCommand("addrestemp", self.ResourceAddTemp)

    self:AddChatCommand("resourcegoto", self.Resourcefind)
    self:AddChatCommand("gotoresource", self.Resourcefind)

    -- self:AddChatCommand("res", self.loadfiles)

end

function OsTime()

    -- is not real OsTime calcule ^^
    local UniqueId1 = util.GetStaticPropertyGetter( System.DateTime, 'Now' )

    local YeartoSeconde = UniqueId1().Year * 31556926
    local MonthToSeconde = UniqueId1().Month * 2629743
    local DayToSeconde = UniqueId1().Day * 86400

    local HourToSeconde = UniqueId1().Hour * 3600
    local MinuteToSeconde = UniqueId1().Minute * 60
    local Seconde = UniqueId1().Second

    local tostimestart1 = 1970 * 31556926
    local tostimestart2 = 12 * 3600

    local tostimestart3 = tostimestart1 + tostimestart2
    local OsTimes = (YeartoSeconde + MonthToSeconde + DayToSeconde + HourToSeconde + MinuteToSeconde + Seconde) - tostimestart3 + UniqueId1().MilliSecond * 0.001

    return OsTimes
end

function PLUGIN:loadfiles( netuser, cmd, args )

    cmdReloadPlug("resource")

end

function PLUGIN:Save()
    MapResource:SetText( json.encode( ResourcePlugin ) )
    MapResource:Save()
end

function PLUGIN:Savelist(name)

    MapResourcelist = util.GetDatafile( "resourcelist" )

    local list = ""
    id = 1

    for k,v in pairs(ResourcePlugin) do

        local pos = "teleporte.topos \""..name.."\" \"".. v.x .."\"  \"".. v.y .."\"  \"".. v.z .."\" "


        if string.len( v.item) <8 then
            list = list .. id .. "		" .. v.item.. "				" .. v.UniqueId .. "		" ..  pos .. "\r\n"
        elseif string.len( v.item) >15 then
            list = list .. id .. "		" .. v.item.. "	" .. v.UniqueId .. "		" ..  pos .. "\r\n"
        elseif string.len( v.item) >11 then
            list = list .. id .. "		" .. v.item.. "			" .. v.UniqueId .. "		" ..  pos .. "\r\n"
        else
            list = list .. id .. "		" .. v.item.. "			" .. v.UniqueId .. "		" ..  pos .. "\r\n"
        end
        id = id + 1
    end

    MapResourcelist:SetText( list )
    MapResourcelist:Save()

end

function PLUGIN:GetAdmin(netuser)

    if oxmin_Plugin or oxmin then
        if  oxmin_Plugin:HasFlag( netuser, self.FLAG_RESOURCE, false ) then
            return true
        end
    end

    if netuser:CanAdmin() then
        return true
    end

    return false

end

-- Function Add -----------
local Raycast = util.FindOverloadedMethod( UnityEngine.Physics, "RaycastAll", bf.public_static, { UnityEngine.Ray } )
cs.registerstaticmethod( "tmp", Raycast )
local RaycastAll = tmp
tmp = nil

function TraceEyes( netuser )
    local controllable = netuser.playerClient.controllable
    local char = controllable:GetComponent( "Character" )
    local ray = char.eyesRay
    local hits = RaycastAll( ray )
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

-- Resource table
local resource ={
    "car_startup", ":boar_prefab", ":stag_prefab", ":rabbit_prefab_a", ":chicken_prefab", ":bear_prefab", ":wolf_prefab", ":mutant_bear", ":mutant_wolf",
    "AmmoLootBox", "MedicalLootBox", "BoxLoot", "WeaponLootBox", "FireBarrel", ":player_soldier", "ZombieNPC"
}

local resource2 = {
    ";res_woodpile", ";res_ore_1", ";res_ore_2", ";res_ore_3", ";struct_metal_foundation"
}

local LimitAI = {
    ":bear_prefab", ":wolf_prefab", ":mutant_bear", ":mutant_wolf"
}

-- Function Add End
function PLUGIN:ResourceAddTemp( netuser, cmd, args )

    if not self:GetAdmin(netuser) then
        rust.SendChatToUser( netuser, "Error add resource" , "You are not admin!" )
        return
    end

    local trace = TraceEyes(netuser)
    local pos = trace.point

    if not args[1] then rust.SendChatToUser( netuser, "Error add resource" , "Use /addresource \"Name Entity\" \"Number Entity\" " ) return end
    if not args[2] then rust.SendChatToUser( netuser, "Error add resource" , "Use /addresource \"Name Entity\" \"Number Entity\" " ) return end

    local item = util.QuoteSafe(args[1])
    local nbr = tonumber(util.QuoteSafe(args[2]))
    local find = false

    for k,v in pairs(resource) do
        if v == item then
            find = true
            typefunc = 1
        end
    end

    for k,v in pairs(resource2) do
        if v == item then
            find = true
            typefunc = 2
        end
    end

    for k,v in pairs(LimitAI) do
        if v == item then

            if pos.x < 3590 then
                rust.SendChatToUser( netuser, "Error add resource" , "NavMesh no find (outside map)" )
                return
            end

            if pos.z > 1080 then
                rust.SendChatToUser( netuser, "Error add resource" , "NavMesh no find (outside map)" )
                return
            end

        end
    end

    if not find then
        rust.SendChatToUser( netuser, "Error add resource" , "Items not found" )
        return
    end

    for i = 0, nbr do

        local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, "LookRotation" )
        q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( "System.Object" ), { pos } ))

        local arr = nil

        if typefunc == 2 then
            arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { item, pos, q  } )  ;
        else
            arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { item, pos, q, 0  } )  ;
        end

        cs.convertandsetonarray( arr, 0, item, System.String._type )
        cs.convertandsetonarray( arr, 1, pos, UnityEngine.Vector3._type )
        cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type )
        if typefunc == 2 then
            -- nothing to do
        elseif typefunc == 3 then
            cs.convertandsetonarray( arr, 3, 0, System.Int32._type )
        else
            cs.convertandsetonarray( arr, 3, 0, System.Int32._type )
        end

        local xgameObject = FuncCreate[typefunc]:Invoke( nil, arr )

    end
end

function PLUGIN:ResourceAdd( netuser, cmd, args )

    if not self:GetAdmin(netuser) then
        rust.SendChatToUser( netuser, "Error add resource" , "You are not admin!" )
        return
    end

    local trace = TraceEyes(netuser)
    local pos = trace.point

    if not args[1] then rust.SendChatToUser( netuser, "Error add resource" , "Use /addresource \"Name Entity\" " ) return end

    local item = util.QuoteSafe(args[1])

    local find = false

    for k,v in pairs(resource) do
        if v == item then
            find = true
            typefunc = 1
        end
    end

    for k,v in pairs(resource2) do
        if v == item then
            find = true
            typefunc = 2
        end
    end

    for k,v in pairs(LimitAI) do
        if v == item then

            if pos.x < 3590 then
                rust.SendChatToUser( netuser, "Error add resource" , "NavMesh no find (outside map)" )
                return
            end

            if pos.z > 1080 then
                rust.SendChatToUser( netuser, "Error add resource" , "NavMesh no find (outside map)" )
                return
            end

        end
    end

    if not find then
        rust.SendChatToUser( netuser, "Error add resource" , "Items not found" )
        return
    end
    local UniqueId = OsTime()

    local UniqueIdString = util.GetStaticPropertyGetter( System.DateTime, 'Now' )

    UniqueIdString = tostring(UniqueIdString())

    table.insert(ResourcePlugin, {id = UniqueId, UniqueId = UniqueIdString, x = pos.x, y = pos.y, z = pos.z , item = item, typefunc = typefunc })

    self:Save()

    self:CreateResource( UniqueId, pos )
    self:Savelist(netuser.displayName)

end


-- for reload
if ResourceTimer then
    ResourceTimer:Destroy()
end

-- InstantiateDyna = util.GetStaticMethod( RustFirstPass.NetCull._type, "InstantiateDynamic" )
FuncCreate = {}
FuncCreate[1] = util.FindOverloadedMethod( RustFirstPass.NetCull._type, "InstantiateClassic", bf.public_static, { System.String, UnityEngine.Vector3, UnityEngine.Quaternion, System.Int32 } )
FuncCreate[2] = util.FindOverloadedMethod( RustFirstPass.NetCull._type, "InstantiateStatic", bf.public_static, { System.String, UnityEngine.Vector3,UnityEngine.Quaternion } )
NetCullRemove = util.FindOverloadedMethod( RustFirstPass.NetCull._type, "Destroy", bf.public_static, { UnityEngine.GameObject} )
WildlifeRemove = util.GetStaticMethod( Rust.WildlifeManager._type, "RemoveWildlifeInstance")

GO = {}
GO.FindObjectsOfType = util.GetStaticMethod( UnityEngine.Object, "FindObjectsOfType")
AiSpawners = GO.FindObjectsOfType(Rust.GenericSpawner._type)

if not tabents then
    tabents = {}
end

function PLUGIN:CreateResource( UniqueId, pos )

    local vvalue = nil
    local kvalue = nil

    for k,v in pairs(ResourcePlugin) do

        if v.id == UniqueId then
            vvalue = v
            kvalue = k
        end

    end

    local v = vvalue
    local pos = new(UnityEngine.Vector3)

    if pos.x == "x" then

        local PlayerClientAll = rust.GetAllNetUsers()

        for key,netuser in pairs(PlayerClientAll) do
            pos = netuser.playerClient.lastKnownPosition
            break
        end

        if pos.x == "x" then
            return
        end
    end

    pos.x = v.x
    pos.y = v.y
    pos.z = v.z

    local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, "LookRotation" )
    q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( "System.Object" ), { pos } ))

    local arr = nil

    if v.typefunc == 2 then
        arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { v.item, pos, q  } )  ;
    else
        arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { v.item, pos, q, 0  } )  ;
    end

    cs.convertandsetonarray( arr, 0, v.item, System.String._type )
    cs.convertandsetonarray( arr, 1, pos, UnityEngine.Vector3._type )
    cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type )
    if v.typefunc == 2 then
    else
        cs.convertandsetonarray( arr, 3, 0, System.Int32._type )
    end

    local xgameObject = FuncCreate[v.typefunc]:Invoke( nil, arr )
    tabents[UniqueId] = {object = xgameObject, pos = pos}

end




ResourceTimer = timer.Repeat( 1, 1, function()

    for k,v in pairs(ResourcePlugin) do

        local finder = false
        if tabents[v.id] then
            finder = true
            if tabents[v.id].object.GameObject.Name == "Name" then
                tabents[v.id] = nil
                finder = false
            end

        end

        local pos = new(UnityEngine.Vector3)

        if pos.x == "x" then

            local PlayerClientAll = rust.GetAllNetUsers()

            for key,netuser in pairs(PlayerClientAll) do
                pos = netuser.playerClient.lastKnownPosition
                break
            end

            if pos.x == "x" then
                return
            end
        end


        pos.x = v.x
        pos.y = v.y
        pos.z = v.z

        if not finder then

            local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, "LookRotation" )
            q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( "System.Object" ), { pos } ))

            local arr = nil

            if v.typefunc == 2 then
                arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { v.item, pos, q  } )  ;
            else
                arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { v.item, pos, q, 0  } )  ;
            end

            cs.convertandsetonarray( arr, 0, v.item, System.String._type )
            cs.convertandsetonarray( arr, 1, pos, UnityEngine.Vector3._type )
            cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type )
            if v.typefunc == 2 then
            else
                cs.convertandsetonarray( arr, 3, 0, System.Int32._type )
            end

            local xgameObject = FuncCreate[v.typefunc]:Invoke( nil, arr )
            tabents[v.id] = {object = xgameObject, pos = pos}

        end
    end

end)

ResourceTimer = timer.Repeat( 600, 0, function()

    for k,v in pairs(ResourcePlugin) do

        local finder = false
        if tabents[v.id] then
            finder = true
            if tabents[v.id].object.GameObject.Name == "Name" then
                tabents[v.id] = nil
                finder = false
            end

        end

        local pos = new(UnityEngine.Vector3)

        if pos.x == "x" then

            local PlayerClientAll = rust.GetAllNetUsers()

            for key,netuser in pairs(PlayerClientAll) do
                pos = netuser.playerClient.lastKnownPosition
                break
            end

            if pos.x == "x" then
                return
            end
        end


        pos.x = v.x
        pos.y = v.y
        pos.z = v.z

        if not finder then

            local _LookRotation = util.GetStaticMethod( UnityEngine.Quaternion._type, "LookRotation" )
            q = _LookRotation[1]:Invoke( nil, util.ArrayFromTable( cs.gettype( "System.Object" ), { pos } ))

            local arr = nil

            if v.typefunc == 2 then
                arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { v.item, pos, q  } )  ;
            else
                arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { v.item, pos, q, 0  } )  ;
            end

            cs.convertandsetonarray( arr, 0, v.item, System.String._type )
            cs.convertandsetonarray( arr, 1, pos, UnityEngine.Vector3._type )
            cs.convertandsetonarray( arr, 2, q, UnityEngine.Quaternion._type )
            if v.typefunc == 2 then
            else
                cs.convertandsetonarray( arr, 3, 0, System.Int32._type )
            end

            local xgameObject = FuncCreate[v.typefunc]:Invoke( nil, arr )
            tabents[v.id] = {object = xgameObject, pos = pos}

        end
    end

end)

console = {}
function console.add(ply,text)

    rust.RunClientCommand( ply, "echo " .. text  )

end

function PLUGIN:ViewResource( arg )

    if not self:GetAdmin(arg.argUser) then
        console.add(arg.argUser, "Error add resource: You are not admin!")
        return
    end

    console.add(arg.argUser, "ID		Item		date")
    local id = 1

    for k,v in pairs(ResourcePlugin) do

        console.add(arg.argUser, id .. "		" .. v.item.. "		".. v.UniqueId )
        id = id + 1
    end
    self:Savelist(arg.argUser.displayName)
end

function PLUGIN:Resourcefind( arg, cmd, args )

    if arg.argUser == "argUser" then
        id = args[1]
        netuser = arg

        if not self:GetAdmin(netuser) then
            rust.SendChatToUser( netuser, "Error add resource" , "You are not admin!" )
            return
        end
        if not id then
            rust.SendChatToUser( netuser, "Error add resource" , "Use /resourceremove ID" )
            return
        end

    else
        netuser = arg.argUser
        id = arg:GetString( 0 )

        if not self:GetAdmin(netuser) then
            console.add(netuser, "Error add resource: You are not admin!")
            return
        end
        if id == "" then
            console.add(netuser, "Error add resource: Use /resourceremove ID")
            return
        end
    end

    if not self:GetAdmin(netuser) then
        rust.SendChatToUser( netuser, "Error add resource" , "You are not admin!" )
        return
    end
    local ids = 1
    for k,v in pairs(ResourcePlugin) do

        if tonumber(id) == ids then

            local pos = new(UnityEngine.Vector3)
            pos.x = v.x
            pos.y = v.y
            pos.z = v.z

            rust.ServerManagement():TeleportPlayerToWorld(netuser.networkPlayer, pos)
        end
        ids = ids + 1
    end

end

function PLUGIN:ResourceRemove( arg, cmd, args )

    if arg.argUser == "argUser" then
        id = args[1]
        netuser = arg

        if not self:GetAdmin(netuser) then
            rust.SendChatToUser( netuser, "Error add resource" , "You are not admin!" )
            return
        end
        if not id then
            rust.SendChatToUser( netuser, "Error add resource" , "Use /resourceremove ID" )
            return
        end

    else
        netuser = arg.argUser
        id = arg:GetString( 0 )

        if not self:GetAdmin(netuser) then
            console.add(netuser, "Error add resource: You are not admin!")
            return
        end
        if id == "" then
            console.add(netuser, "Error add resource: Use /resourceremove ID")
            return
        end
    end
    local ids = 1

    for k,v in pairs(ResourcePlugin) do

        if tonumber(id) == ids then

            ResourcePlugin[k] = nil
            self:Save()
            if tabents[k] then


                local finder = false

                if not finder then
                    arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { tabents[k].object } )  ;
                    cs.convertandsetonarray( arr, 0, tabents[k].object , UnityEngine.GameObject._type )
                    NetCullRemove:Invoke( nil, arr )
                end

                tabents[k] = nil

            end
        end
        ids = ids + 1
    end

end