PLUGIN.Title = 'carbon_prof'
PLUGIN.Description = 'profession module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    --LOAD/CREATE TEXT FILE		PROF
    self.CraftFile = util.GetDatafile( 'carbon_craft' )
    local craft_txt = self.CraftFile:GetText()
    if (craft_txt ~= '') then
        print( 'carbon_craft file loaded!' )
        self.craft = json.decode( craft_txt )
    else
        print( 'carbon_txt file is missing!' )
    end

    self:AddChatCommand( 'inspect', self.cmdInspect ) 	-- prof
end

--PLUGIN:OnStartCrafting
local unstackable = {"M4", "9mm Pistol", "Shotgun", "P250", "MP5A4", "Pipe Shotgun", "Bolt Action Rifle", "Revolver", "HandCannon", "Research Kit 1",
    "Cloth Helmet","Cloth Vest","Cloth Pants","Cloth Boots","Leather Helmet","Leather Vest","Leather Pants","Leather Boots","Rad Suit Helmet",
    "Rad Suit Vest","Rad Suit Pants","Rad Suit Boots","Kevlar Helmet","Kevlar Vest","Kevlar Pants","Kevlar Boots", "Holo sight","Silencer","Flashlight Mod",
    "Laser Sight","Flashlight Mod", "Hunting Bow", "Rock","Stone Hatchet","Hatchet","Pick Axe", "Torch", "Furnace", "Bed","Handmade Lockpick", "Workbench",
    "Camp Fire", "Wood Storage Box","Small Stash","Large Wood Storage", "Sleeping Bag"}
function PLUGIN:OnStartCrafting( inv, blueprint, amount )
    local s = tostring( inv )
    local f = "Player"
    local deb = string.find(s, f ) +7
    local fin = string.find( s, "(" , deb, true) - 2
    local s2 = string.sub(s, deb, fin)
    local validate, netuser = rust.FindNetUsersByName( tostring(s2) )
    if (not validate) then
        if (netuser == 0) then
            print( "[ OnStartCrafting ] No players found with name: " .. tostring( s2 ))
        else
            print( "[ OnStartCrafting ] Multiple players found with name: " .. tostring( s2 ))
        end
        return false
    end
    local inv = rust.GetInventory( netuser )
    if not inv then rust.Notice('Inventory not found, report to a GM. Unable to craft.') return false end
    if( self.craft[ blueprint.resultItem.name ] ) then
        local netuserID = rust.GetUserID( netuser )
        if char.User[ netuserID ].crafting then rust.Notice(netuser, 'You\'re already crafting!' ) return false end
        char.User[ netuserID ].crafting = true
        local data = self.craft[ blueprint.resultItem.name ]
        if not data then rust.Notice( netuser, 'No data found...' ) char.User[ netuserID ].crafting = false return false end
        local craftdata = char.User[ netuserID ].prof[ data.prof ]
        if( data.prof ~= 'Intelligence' ) then
            if( craftdata.lvl < data.req ) then rust.Notice( netuser, 'You cannot craft this yet. ' .. data.prof .. ' level ' .. data.req .. ' required!') char.User[ netuserID ].crafting = false return false end
        else
            if( char.User[ netuserID ].attributes.int < data.req ) then rust.Notice( netuser, 'You cannot craft this yet. ' ..  data.prof .. ' level ' .. data.req .. ' required!' ) char.User[ netuserID ].crafting = false return false end
        end

        -- Crafting:
        -- check for crit
        -- check for failed
        local Time = data.ct * amount
        -- If crit, then Time becomes = 0. This means instant craft.
        if crit then rust.Notice( netuser, 'Critical craft!' ) Time = 0 end
        local i = Time
        if Time == 0 then Time = 1 end
        timer.Repeat(1, Time , function()
            if Time > 0 then rust.InventoryNotice( netuser, tostring(i) ) end
            i = i - 1
            if( i <= 0 ) then
                -- del mats
                for k,v in pairs( data.mats ) do
                    if failed then v = (v*amouunt) / 2 end
                    v = v * amount
                    local datablock = rust.GetDatablockByName( k )
                    local isUnstackable = func:containsval(unstackable, k )
                    local y = 0
                    local item = inv:FindItem(datablock)
                    if (item) then
                        if (not isUnstackable) then
                            while (y < v) do
                                if (item.uses > 0) then
                                    item:SetUses(item.uses - 1)
                                    y = y + 1
                                else
                                    inv:RemoveItem(item)
                                    item = inv:FindItem(datablock)
                                    if (not item) then
                                        break
                                    end
                                end
                            end
                        else
                            while (y < v) do
                                inv:RemoveItem(item)
                                y = y + 1
                                item = inv:FindItem(datablock)
                                if (not item) then
                                    break
                                end
                            end
                        end
                    else rust.Notice(netuser, "Dont cheat bro. You just lost your mats.") char.User[ netuserID ].crafting = false return false end
                    if ((not isUnstackable) and (item) and (item.uses <= 0)) then inv:RemoveItem(item) end
                end

                local item2 = rust.GetDatablockByName( blueprint.resultItem.name )
                -- craft crit the double the amount is given.
                if crit then amount = amount * 2 end

                -- if craft failed, then no items are given.
                if not failed then
                    timer.Once( 1, function()
                        inv:AddItemAmount( item2, amount )
                        rust.InventoryNotice( netuser, amount .. 'x ' .. blueprint.resultItem.name )
                        char.User[ netuserID ].crafting = false
                    end)
                end
                -- add xp || Random xp is not random... o.O     <-- best smiley evah?
                --                                      ___     <-- best smiley evah?
                local xp = math.floor(( math.random( data.xp.min, data.xp.max ))*amount)
                if failed then xp = xp / 2 rust.Notice( netuser, 'Crafting failure!' ) end
                -- self:AddCraftXP( netuser, prof, xp )
                if( not data.prof == 'Intelligence' ) then
                    timer.Once(3, function()
                        craftdata.xp = craftdata.xp + xp -- TEMPORARY!
                        rust.InventoryNotice( netuser , '+' .. xp .. ' ' .. data.prof .. ' xp')
                    end)
                else
                    timer.Once(3, function()
                        char.User[ netuserID ].xp = char.User[ netuserID ].xp + xp
                        rust.InventoryNotice( netuser, '+' .. xp .. 'xp' )
                    end)
                end
                char:UserSave()
            end
        end )
        return false
    else
        print( '[ CRAFTING ] ' .. blueprint.resultItem.name .. ' is not in carbon_craft' )
        rust.Notice( netuser, blueprint.resultItem.name .. ' is not in the carbon_craft file, please report to a GM.' )
        return false
    end
end

-- inspect items. Crafting and maybe Economy.
function PLUGIN:cmdInspect( netuser, cmd, args )
    if not args[1] then
        if not args[1]then local content={['msg']=' With the inspect feature you\'re able inspect any item ingame. This will show the crafting information. \n \n Simply type /inspect "Item Name"' }
        func:TextBox(netuser,content,cmd,args)return end
    elseif args[1] then
        local itemname = tostring( args[1] )
        if( not self.craft[ itemname ] ) then -- item not found
            local content={['msg']=''.. itemname .. ' is not craftable!' }
            func:TextBoxError(netuser,content,cmd,args) return
        else
            local data = self.craft[ itemname ]

            local content = {
                ['list']=
                {
                    'Item                        : ' .. itemname,
                    'Profession           : ' .. data.prof,
                    'Required level      : ' .. data.req,
                    'Difficulty               : ' .. data.dif,
                    'Crafting Time       : ' .. data.ct,
                    'XP                           : ' .. data.xp.min .. ' - ' .. data.xp.max,
                    ' ',
                    'Materials: '
                }
            }
            for k, v in pairs( data.mats ) do table.insert( content.list, '- ' .. v .. 'x ' .. k ) end
            func:TextBox(netuser,content,cmd,args) return
        end
    end
end