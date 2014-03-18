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
    local netuser = rust.NetUserFromNetPlayer( inv.networkViewOwner )
    local inv = rust.GetInventory( netuser )
    if not inv then rust.Notice( netuser, 'Inventory not found, report to a GM. Unable to craft.') return false end
    if( self.craft[ blueprint.resultItem.name ] ) then
        local netuserID = rust.GetUserID( netuser )
        -- if char[ netuserID ].crafting then rust.Notice(netuser, 'You\'re already crafting!' ) return false end
        char[ netuserID ].crafting = true
        local data = self.craft[ blueprint.resultItem.name ]
        if not data then rust.Notice( netuser, 'No data found...' ) char[ netuserID ].crafting = false return false end
        local craftdata = char[ netuserID ].prof[ data.prof ]
        if( craftdata.lvl < data.req ) then rust.Notice( netuser, 'You cannot craft this yet. ' .. data.prof .. ' level ' .. data.req .. ' required!') char[ netuserID ].crafting = false return false end
        local a,b,c=craftdata.lvl, char[ netuserID ].attributes.int, data.dif ;local d,e=100-a*0.321429/2-b*2.25/2+c*0.22501,50-a*0.321429-b*2.25+c*0.4501
        local crit, failed = false,false

        local roll = func:Roll(true, 100)
        if(roll < e) then
	        rust.BroadcastChat( 'Before setting failed to true' )

            failed = true
            rust.BroadcastChat('FAILED' )
        elseif (roll > d) then
            crit = true
            rust.BroadcastChat( 'CRIT' )
        end
        local Time = data.ct * amount
        if crit then rust.Notice( netuser, 'Critical craft!' ) Time = 0 end
        local i = Time
        if Time == 0 then Time = 1 end
        timer.Repeat(1, Time , function()
            if Time > 0 then rust.InventoryNotice( netuser, tostring(i) ) end
            local controllable = netuser.playerClient.controllable
            local this = controllable:GetComponent("FallDamage")
	        this:SetLegInjury(1000)
            i = i - 1
            if( i <= 0 ) then
                for k,v in pairs( data.mats ) do
                    v = v * amount
                    if failed then v = math.floor(v / 2) end
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
                    else rust.Notice(netuser, "Dont cheat bro. You just lost your mats.") char[ netuserID ].crafting = false return false end
                    if ((not isUnstackable) and (item) and (item.uses <= 0)) then inv:RemoveItem(item) end
                end

                local item2 = rust.GetDatablockByName( blueprint.resultItem.name )
                if crit then amount = amount * 2 end

                if not failed then
                    timer.Once( 1, function()
                        inv:AddItemAmount( item2, amount )
                        rust.InventoryNotice( netuser, amount .. 'x ' .. blueprint.resultItem.name )
                    end)
                end
                local xp = func:Roll( true, data.xp.min, data.xp.max )*amount
                if failed then xp = math.floor(xp / 2) rust.Notice( netuser, 'Crafting failure!' ) end
                timer.Once(2, function()
                    xp = self:AddCraftXP( netuser, data.prof, xp )
                    if xp == 0 then char[ netuserID ].crafting = false return end
                    rust.InventoryNotice( netuser , '+' .. xp .. ' ' .. data.prof .. ' xp')
                end)
                timer.Once(1, function() this:ClearInjury() end)
                char:Save( netuser )
                char[ netuserID ].crafting = false
            end
        end )
        return false
    else
        print( '[ CRAFTING ] ' .. blueprint.resultItem.name .. ' is not in carbon_craft' )
        rust.Notice( netuser, blueprint.resultItem.name .. ' is not in the carbon_craft file, please report to a GM.' )
        return false
    end
end

function PLUGIN:AddCraftXP(netuser, prof, xp)
	local netuserID = rust.GetUserID( netuser )
    local data = char:GetUserDataFromTable(netuser)
    if not data then return end
    local craftdata = data.prof[ prof ]
    if not craftdata then return end
    if craftdata.lvl == craftdata.maxlvl then return 0 end
    local calcLvl = math.floor((math.sqrt(100*((core.Config.settings.CLASS_LEVEL_MODIFIER*(craftdata.xp+xp))+25))+50)/100)
    if calcLvl ~= craftdata.lvl then
        craftdata.lvl = calcLvl
        -- LEVEL UP
        local content = {
            ['header'] = 'You\'re now level ' .. tostring(calcLvl) .. ' ' .. prof .. '!',
            ['msg'] = 'Unlocked: '
        }
        local found = false
        for k, v in pairs(self.craft) do
            if v.prof == prof then
                if v.req == calcLvl then
                    content.msg = content.msg .. ', ' .. k
                    found = true
                end
            end
        end
        craftdata.xp = craftdata.xp + xp
        local cmd = prof .. ' Level Up!'
        local args = {}
        if not found then content.msg = 'There are no new researches available.' end
        func:TextBox(netuser,content,cmd,args) return
    end
    craftdata.xp = craftdata.xp + xp
    return xp
end

-- inspect items. Crafting and maybe Economy.
function PLUGIN:cmdInspect( netuser, cmd, args )
    if not args[1] then
        if not args[1]then local content={['msg']=' With the inspect feature you\'re able inspect any item ingame. This will show the crafting information. \n \n Simply type /inspect Item Name' }
        func:TextBox(netuser,content,cmd,args)return end
    elseif args[1] then
	    local itemname = ''
	    local i = 1
	    while args[i] do
		    args[i] = args[i]:sub(1,1):upper()..args[i]:sub(2):lower()
		    if itemname == '' then
		        itemname = itemname .. args[i]
		    else
		        itemname = itemname .. ' ' .. args[i]
		    end
		    if i > 1 then args[i] = nil end
		    i = i + 1
	    end
	    args[1] = itemname

        if( not self.craft[ itemname ] ) then -- item not found
            local content={['msg']=''.. itemname .. ' is not craftable!' }
            func:TextBoxError(netuser,content,cmd,args) return
        else
            local netuserID = rust.GetUserID( netuser )
            local data = self.craft[ itemname ]
            local craftdata = char[ netuserID ].prof[ data.prof ]
            local a,b,c=craftdata.lvl, char[ netuserID ].attributes.int, data.dif ;local d,e=100-a*0.321429/2-b*2.25/2+c*0.22501,50-a*0.321429-b*2.25+c*0.4501
            local content = {
                ['list']=
                {
                    'Item                        : ' .. itemname,
                    'Profession           : ' .. data.prof,
                    'Required level      : ' .. data.req,
                    'Difficulty               : ' .. data.dif,
                    'Crafting Time       : ' .. data.ct,
                    'XP                           : ' .. data.xp.min .. ' - ' .. data.xp.max,
                }
            }
            local craftdata = char[ netuserID ].prof[ data.prof ]
            if data.req <= craftdata.lvl then
                table.insert( content.list, 'Fail chance           : ' .. tostring(math.floor(e+0.5)) .. '%' )
                if math.floor((100 - d)+0.5) > 0 then
                    table.insert( content.list, 'Critical chance     : ' .. tostring(math.floor((100 - d)+0.5)) .. '%' )
                else
	                table.insert( content.list, 'Critical chance     : ' .. '0%' )
                end
            end
            local msg
            local diff = data.req - craftdata.lvl
            if (diff < 0) then
	            msg = 'You can craft this item'
            else
                msg = tostring( 'You need ' .. diff  .. ' ' .. data.prof .. ' levels to craft this.' )
            end
            content.cmds = {msg}
            table.insert( content.list, ' ')
            table.insert( content.list, 'Materials: ')
            for k, v in pairs( data.mats ) do table.insert( content.list, '- ' .. v .. 'x ' .. k ) end
            func:TextBox(netuser,content,cmd,args) return
        end
    end
end

function PLUGIN:OnBlueprintUse( blueprint, item )
    local inv = item.inventory
    local s = tostring( inv )
    local f = "Player"
    local deb = string.find(s, f ) +7
    local fin = string.find( s, "(" , deb, true) - 2
    local s2 = string.sub(s, deb, fin)
    local validate, netuser = rust.FindNetUsersByName( tostring(s2) )
    if (not validate) then
        if (netuser == 0) then
            print( "[ OnBluePrintUse ] No players found with name: " .. tostring( s2 ))
        else
            print( "[ OnBluePrintUse ] Multiple players found with name: " .. tostring( s2 ))
        end
        return false
    end
    if( self.craft[ blueprint.resultItem.name ] ) then
        local netuserID = rust.GetUserID( netuser )
        local data = self.craft[ blueprint.resultItem.name ]
        if not data then rust.Notice( netuser, 'No data found...' ) return false end
        local craftdata = char[ netuserID ].prof[ data.prof ]
        if( craftdata.lvl < data.req ) then
            rust.Notice( netuser, 'You cannot research this yet. ' .. data.prof .. ' level ' .. data.req .. ' required!')
        return false end
    else
        rust.Notice( netuser, blueprint.resultItem.name .. ' was not found in the database! Report this to a GM!' )
        return false
    end
end

-- Blocking researching kit
function PLUGIN:OnResearchItem( researchtoolitem, item )
    return MergeResult.Failed
end

function PLUGIN:InfoProf( netuser, cmd ,args )
    local content = {
        ['list']={}
    }
    for k, v in pairs( char[rust.GetUserID( netuser )].prof) do
        if v.lvl >= 1 then
            local a = v.lvl+1 --level +1
            local ab = v.lvl --level
            local b = core.Config.settings.CLASS_LEVEL_MODIFIER
            local c = ((a*a)+a)/b*100-(a*100) --xp required for next level
            local d = math.floor(((v.xp/c)*100)+0.5) -- percent currently to next level.
            local e = c-v.xp -- left to go until level
            local f = ((ab*ab)+ab)/b*100-(ab*100) -- amount needed for current level
            if (a == 2) and (core.Config.settings.CLASS_LEVEL_MODIFIER >= 2) then f = 0 end
            table.insert(content.list, k .. ' level: ' .. tostring(ab) )
            table.insert(content.list, 'Experience: (' .. v.xp .. '/' .. tostring(c) .. ')  [' .. tostring(d) .. '%]   (+' .. tostring(e) .. ')' )
            table.insert(content.list, tostring(func:xpbar( d, 32 )))
        end
    end
    func:TextBox(netuser,content,cmd,args) return
end

--[[
txt.level .. ':                          ' .. tostring(ab),
            ' ',
            txt.experience .. ':              (' .. tostring(netuserData.xp) .. '/' .. tostring(c) .. ')   [' .. tostring(d) .. '%]   ' .. '(' .. tostring(e) .. ')',
            tostring(func:xpbar( d, 32 )),
            ' ',
            txt.deathpenalty .. ':         (' .. tostring(netuserData.dp) .. '/' .. tostring(h) .. ')   [' .. tostring(g) .. '%]',
            tostring(func:xpbar( g, 32 )),
 ]]