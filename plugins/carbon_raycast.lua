PLUGIN.Title = 'carbon_raycast'
PLUGIN.Description = 'raycast module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()

    core = cs.findplugin("carbon_core") core:LoadLibrary()

    self:AddChatCommand('trace', self.cmdRView)

end

local Raycast = util.FindOverloadedMethod( UnityEngine.Physics, "RaycastAll", bf.public_static, { UnityEngine.Ray } )
cs.registerstaticmethod( "tmp2", Raycast )
local RaycastAll = tmp2
tmp2 = nil

function PLUGIN:cmdRView(netuser, cmd, args)
    local repeats = 0
    local totalRepeats = 3
    timer.Repeat(1, totalRepeats, function()
        repeats = repeats + 1
        local trace = TraceEyesw(netuser)
        if not trace then return end
        local p = trace.point
        local dist = self:radFromCoordinates(netuser.playerClient.lastKnownPosition, p)
        if dist > 150 or dist <= 10 then return end
        local rad = 1
        if dist > 10 then rad = 0.0012 * dist + 1.97 end
        local allnetusers = rust.GetAllNetUsers()
        if (allnetusers) then
            for i = 1, #allnetusers do
                rust.BroadcastChat( tostring( p ))
                local netusertmp = allnetusers[i]

                local pos = netusertmp.playerClient.lastKnownPosition
                local pname = netusertmp.displayName
                local actorname = netuser.displayName
                if pname ~= actorname and self:isPointInRadius(pos, p, rad) then
                    rust.Notice(netuser, " [ " .. netusertmp.displayName .. " ], distance: " .. self:round(dist, 1) .. " m")
                    break
                end
            end
            rust.Notice(netuser, 'Nothing found' )
        end
    end)
end

function S_TraceEyes( netuser)
	local Raycast = util.FindOverloadedMethod( UnityEngine.Physics, "RaycastAll", bf.public_static, { UnityEngine.Ray } )
	cs.registerstaticmethod( "tmp", Raycast )
	local RaycastAll = tmp
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



function PLUGIN:radFromCoordinates(p1, p2)
    return math.sqrt(math.pow(p1.x - p2.x,2) + math.pow(p1.y - p2.y,2) + math.pow(p1.z - p2.z,2)) end
function PLUGIN:round(val, decimal)
    if (decimal) then return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
    else  return math.floor(val+0.5) end end
function PLUGIN:isPointInRadius(pos, point, rad)
    rust.BroadcastChat('pos' .. tostring(pos))
    rust.BroadcastChat('point' .. tostring(point))
    rust.BroadcastChat('rad' .. tostring(rad))
    return (pos.x < point.x + rad and pos.x > point.x - rad)
            and (pos.y < point.y + rad and pos.y > point.y - rad)
            and (pos.z < point.z + rad and pos.z > point.z - rad)
end