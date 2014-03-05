PLUGIN.Title = 'carbon_sandbox_a'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end
--[[

i = 1
local bool = inv:IsSlotFree(i)
i = i + 1
if bool then inv:DropItem(inv,i)



i = 1
local bool = inv:IsSlotFree(i)
i = i + 1
if bool then
moveitem
else
dropitem
end

--]]