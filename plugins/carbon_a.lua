PLUGIN.Title = 'carbon_sandbox_a'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
    --self:AddChatCommand( 'a', self.a )
    --self:AddChatCommand( 'name', self.name )
    --self:AddChatCommand( 'move', self.move )
    --self:AddChatCommand( 'lamp', self.lamp )
    --self:AddChatCommand( 'attack', self.attack )
    self:AddChatCommand( 'givegxp', self.givegxp )
    self:AddChatCommand( 'givexp', self.givexp )
end

function PLUGIN:givexp( netuser, cmd, args )
	local xp = tonumber( args[1] )
	if not xp then rust.Notice( netuser, 'Wrong number, dumbfuck' ) return end
	local data = {
		['netuser'] = netuser,
		['netuserData'] = char[ rust.GetUserID( netuser )  ]
	}
	local wepxp = false
	if args[2] and args[2]:lower() == 'true' then
		local inv = rust.GetInventory( netuser )
		if inv.activeItem then
			local activeItem = inv.activeItem
			if core.Config.weapon[tostring(activeItem.datablock.name)] then
				data['weapon'] = core.Config.weapon[tostring(activeItem.datablock.name)]
				wepxp = true
			else
				rust.Notice( netuser, 'This is no weapon...' )
				return
			end
		else
			rust.Notice( netuser, 'no active weapon...' )
			return
		end
	end
	char:GiveXp(data, xp, wepxp, false )
end

function PLUGIN:givegxp( netuser, cmd, args )
	local guildname = guild:getGuild( netuser )
	if guildname then
		local gxp = tonumber( args[1])
		if not gxp then rust.Notice( netuser, 'Wrong number, dumbfuck' ) return end
		local gxp = guild:GiveGXP( guildname, gxp )
		if gxp > 0 then
			timer.Once( 3 , function() rust.InventoryNotice( netuser, '+' .. tostring(gxp) .. 'gxp' )  end)
		end
	end
end

-- Detects if someone is moving.
function PLUGIN:move( netuser, cmd ,args )
	local char = rust.GetCharacter( netuser )
	if not char then rust.BroadcastChat( 'char not found')return end

	timer.Repeat( 1, 10, function () rust.BroadcastChat( 'moving check.' )rust.BroadcastChat( 'Moving: ' .. tostring(char.stateFlags.movement)) end)
end
-- Dunno yet.. It's not when you have a torch on or something.
function PLUGIN:lamp( netuser, cmd ,args )
	local char = rust.GetCharacter( netuser )
	if not char then rust.BroadcastChat( 'char not found')return end

	timer.Repeat( 1, 10, function () rust.BroadcastChat( 'lamp check.' )rust.BroadcastChat( 'Lamp: ' .. tostring(char.stateFlags.lamp)) end)
end
-- Check if someone is attacking
function PLUGIN:attack( netuser, cmd ,args )
	local char = rust.GetCharacter( netuser )
	if not char then rust.BroadcastChat( 'char not found')return end

	timer.Repeat( 1, 10, function () rust.BroadcastChat( 'attack check.' )
	rust.BroadcastChat( 'attack: ' .. tostring(char.stateFlags.attack))
	rust.BroadcastChat( 'attack2: ' .. tostring(char.stateFlags.attack2)) end)
end


function PLUGIN:a(netuser,cmd, args)
    local controllable = netuser.playerClient.controllable
    --local CLT = controllable:GetComponent( "CharacterLoadoutTrait" )
    local character = controllable:GetComponent( "Character" )
    local inv = controllable:GetComponent( "Inventory" )
    local pinv = controllable:GetComponent( "PlayerInventory" )
    local nu = controllable:GetComponent( "NetUser" )
    local bp = controllable:GetComponent( "Blueprint" )
    local avatar = netuser:LoadAvatar()

	rust.SendChatToUser(netuser, tostring(inv.activeItem))
    --pinv:DoDeactivateItem()



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
    --avatar:ClearBlueprints()
end

function PLUGIN:name( netuser, cmd, args )
	local char = rust.GetCharacter( netuser )
	if not char then rust.Notice( netuser , 'char not found' ) return end

	local trait = char:LoadTraitMapNonNetworked()
	if not trait then rust.Notice( netuser, 'Trait not found! :(' )return end
	print( trait )


	-- local rs = char.recoilSimulation
	-- rs:AddRecoil( 100, 50, 50)
end