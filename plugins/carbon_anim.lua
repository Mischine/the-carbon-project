PLUGIN.Title = 'carbon_anim'
PLUGIN.Description = 'animation module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin('carbon_core') core:LoadLibrary()
end

function PLUGIN:PetAttackAnim( pet )
	if not pet then return end
	local args = cs.newarray(System.Object._type, 0)
	pet.BaseWildAI.networkView:RPC("CL_Attack", uLink.RPCMode.OthersExceptOwner, args);
end



--[[
base.get_networkView().RPC<byte>("Snd", 1, toPlay);
base.get_networkView().RPC("CL_Attack", 9, new object[0]);
]]