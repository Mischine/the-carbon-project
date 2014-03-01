PLUGIN.Title = "carbon_econ"
PLUGIN.Description = "econ module"
PLUGIN.Version = "0.0.1 alpha"
PLUGIN.Author = "Mischa & CareX"


function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
    print( "Carbon Econ version " .. self.Version .. " Loading..." )

    -- Gets/Creates Data File
    self.DataFile = util.GetDatafile( "carbon_econ_dat" )
    local data = self.DataFile:GetText()
    if ( data ~= "" ) then
        self.Data = json.decode( data )
        print( "carbon_dat file loaded" )
    else
        print( "carbon_dat Data File created" )
        self.Data = {}
        self:Save()
    end

    -- Gets/Creates cfg File
    self.CfgFile = util.GetDatafile( "carbon_econ_cfg" )
    local cfg_txt = self.CfgFile:GetText()
    if ( cfg_txt ~= "" ) then
        core.Config = json.decode( cfg_txt )
        print( "carbon_cfg file loaded" )
    else
        self:LoadDefaultConfig()
        print( "carbon_cfg file created" )
        self.CfgFile:SetText( json.encode( core.Config, { indent = true } ) )
        self.CfgFile:Save()
    end
    -- Gets item File
    self.ItemFile = util.GetDatafile( "carbon_itm" )
    local itm_txt = self.ItemFile:GetText()
    if ( itm_txt ~= "" ) then
        self.Item = json.decode( itm_txt )
        print( "carbon_itm file loaded" )
    else
        print( 'carbon_itm not found!' )
    end

    self.cat = { 'misc','armor','food','weapons','building','adv building','tools', 'mats', 'ammo','mods' }

    local count = 0
    for _,v in pairs(self.Data) do count = count + 1 end
    print("Carbon: A total of " .. tostring(count) .. " users has been found.")

    -- Sets CurrencySymbol, Chat name
    self.Chat = core.Config.Chat


    -- Initializing chat commands
    self:AddChatCommand( "ehelp", self.cmdHelp )
    self:AddChatCommand( "bal", self.cmdBal )
    -- self:AddChatCommand( "ereload", self.cmdReload )


    self:AddChatCommand( "store", self.cmdStore )
    self:AddChatCommand( "buy", self.cmdBuy )
    self:AddChatCommand( "sell", self.cmdSell )

    print( "carbon_econ version " .. self.Version .. " Loading complete." )

end

function func:containsval(t,cv) for _, v in pairs(t) do  if v == cv then return true  end  end return nil end
local unstackable = {"M4", "9mm Pistol", "Shotgun", "P250", "MP5A4", "Pipe Shotgun", "Bolt Action Rifle", "Revolver", "HandCannon", "Research Kit 1",
    "Cloth Helmet","Cloth Vest","Cloth Pants","Cloth Boots","Leather Helmet","Leather Vest","Leather Pants","Leather Boots","Rad Suit Helmet",
    "Rad Suit Vest","Rad Suit Pants","Rad Suit Boots","Kevlar Helmet","Kevlar Vest","Kevlar Pants","Kevlar Boots", "Holo sight","Silencer","Flashlight Mod",
    "Laser Sight","Flashlight Mod", "Hunting Bow", "Rock","Stone Hatchet","Hatchet","Pick Axe", "Torch", "Furnace", "Bed","Handmade Lockpick", "Workbench",
    "Camp Fire", "Wood Storage Box","Small Stash","Large Wood Storage", "Sleeping Bag" }

function PLUGIN:cmdReload( netuser, cmd, args )
    if not reloadtoken then
        local b, str = reloadCarbon('carbonecon')
        rust.Notice(netuser,str)     end
end

function reloadCarbon(carbonecon)
    reloadtoken = timer.Once(3,function() reloadtoken = nil  end)
    print('Carbon Econ reloader initiated.. .')
    cs.reloadplugin(carbonecon)
    local ceplugin = plugins.Find(carbonecon)
    if ceplugin then
        ceplugin:Init()
        if ceplugin.PostInit then cplugin:PostInit() end
    else
        return false, 'Failed to reload carbon'
    end
    print('Carbon Econ reloader complete.')
    return true, 'Carbon Econ reloaded'
end

function PLUGIN:OnKilled ( takedamage, dmg )
    if ( takedamage:GetComponent( "HumanController" )) then
        local victim = takedamage:GetComponent( "HumanController" )
        if ( victim ) then
            local netplayer = victim.networkViewOwner
            if ( netplayer ) then
                local VicNetuser = rust.NetUserFromNetPlayer( netplayer )
                if ( VicNetuser ) then
                    if (( dmg.attacker.client ) and ( dmg.attacker.client.netUser )) then
                        local AttNetuser = dmg.attacker.client.netUser
                        if ( AttNetuser.displayName == VicNetuser.displayName ) then
                            -- Suicide
                            return
                        end
                        rust.SendChatToUser( AttNetuser, self.Chat, "You've killed " .. VicNetuser.displayName .. "!")
                        rust.SendChatToUser( VicNetuser, self.Chat, "You've been killed by " .. AttNetuser.displayName .. "!")
                        local vBal = self:getBalance( VicNetuser )
                        local data = self:Percentage( vBal.g, vBal.s, vBal.c )
                        self:AddBalance( AttNetuser, data.gg, data.gs, data.gc )
                        self:RemoveBalance( VicNetuser,data.tg, data.ts, data.tc )
                    end
                end
            end
        end
    end
    local npcController = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI'}
    for _, npcController in ipairs(npcController) do
        if (takedamage:GetComponent( npcController )) then
            local npcData = core.Config.Rewards[string.gsub(tostring(dmg.victim.networkView.name), '%(Clone%)', '')]
            local netuser = dmg.attacker.client.netUser
            local data = self:Convert( math.floor( math.random( npcData.min, npcData.max )))
            self:AddBalance( netuser, data.g, data.s, data.c )
            return end --break out of all loops after finding controller type
    end
end

function PLUGIN:Convert( value )
    local g,s,c = 0,0,0
    while value >= 10000 do
        g = g + 1
        value = value - 10000
    end
    while value >= 100 do
        s = s + 1
        value = value - 100
    end
    c = value
    local tbl = {['g']=g,['s']=s,['c']=c}
    return tbl
end

function PLUGIN:OnUserConnect( netuser )
    local data = char:GetUserData( netuser )
    rust.SendChatToUser( netuser, self.Chat, self:printBalance( netuser,0,0,0 ) )
end

function PLUGIN:getUserData( netuser )
    local UserID = rust.GetUserID( netuser )
    local data = self.Data[ UserID ]
    if (not data) then
        data = {}
        data.Balance = {
            ['g']= 0,
            ['s']= 0,
            ['c']= 0
        }
        self.Data[ UserID ] = data
        self:Save()
    end
    return data
end

function PLUGIN:getBalance( netuser )
    local UserID = rust.GetUserID( netuser )
    local data = self.Data[ UserID ].Balance
    return data
end

function PLUGIN:canBuy( netuser, g, s, c )
    local UserID = rust.GetUserID( netuser )
    local data = self.Data[ UserID ].Balance
    local cost = (( g * 10000 ) + ( s * 100 ) + ( c * 1 ))
    local bal = (( data.g * 10000 ) + ( data.s * 100 ) + ( data.c * 1 ))
    if( bal >= cost ) then return true else return false end
end

function PLUGIN:Percentage( g, s, c )
    local gg, gs, tg, ts = 0,0,0,0
    local bal = (( g * 10000 ) + ( s * 100 ) + ( c * 1 ))

    local getbal = math.floor(( bal * ( math.floor( math.random( core.Config.Rewards.PlayerKill.min, core.Config.Rewards.PlayerKill.max )) / 100 )))
    local take = math.floor((getbal ) + ( bal * ( math.floor( math.random( core.Config.Rewards.OnKilled.min, core.Config.Rewards.OnKilled.max )) / 100 )))
    while getbal >= 10000 do
        gg = gg + 1
        getbal = getbal - 10000
    end
    while (getbal >= 100 ) do
        gs = gs + 1
        getbal = getbal - 100
    end
    local gc = getbal

    while take >= 10000 do
        tg = tg + 1
        take = bal - 10000
    end
    while (take >= 100 ) do
        ts = ts + 1
        take = take - 100
    end
    local tc = take
    local tbl = {['tg']= tg,['ts']= ts,['tc']=tc,['gg']= gg,['gs']= gs,['gc']=gc}
    return tbl
end

function PLUGIN:AddBalance( netuser, g, s, c )
    local UserID = rust.GetUserID( netuser )
    while ( c >= 100 ) do
        c = c - 100
        s = s + 1
    end
    while ( s >= 100 ) do
        s = s - 100
        g = g + 1
    end
    if( g ) then self.Data[ UserID ].Balance.g = self.Data[ UserID ].Balance.g + g end
    if( s ) then self.Data[ UserID ].Balance.s = self.Data[ UserID ].Balance.s + s end
    if( c ) then self.Data[ UserID ].Balance.c = self.Data[ UserID ].Balance.c + c end
    while( self.Data[ UserID ].Balance.c >= 100 ) do
        self.Data[ UserID ].Balance.s = self.Data[ UserID ].Balance.s + 1
        self.Data[ UserID ].Balance.c = self.Data[ UserID ].Balance.c - 100
    end
    while( self.Data[ UserID ].Balance.s >= 100 ) do
        self.Data[ UserID ].Balance.g = self.Data[ UserID ].Balance.g + 1
        self.Data[ UserID ].Balance.s = self.Data[ UserID ].Balance.s - 100
    end
    rust.SendChatToUser( netuser, self.Chat, self:printBalance( netuser, g, s, c, true ) )
    self:Save()
end

function PLUGIN:RemoveBalance( netuser, g, s, c )
    local UserID = rust.GetUserID( netuser )
    while ( c >= 100 ) do
        c = c - 100
        s = s + 1
    end
    while ( s >= 100 ) do
        s = s - 100
        g = g + 1
    end
    if( g ) then self.Data[ UserID ].Balance.g = self.Data[ UserID ].Balance.g - g end
    if( s ) then self.Data[ UserID ].Balance.s = self.Data[ UserID ].Balance.s - s end
    if( c ) then self.Data[ UserID ].Balance.c = self.Data[ UserID ].Balance.c - c end
    while( self.Data[ UserID ].Balance.c < 0 ) do
        self.Data[ UserID ].Balance.c = self.Data[ UserID ].Balance.c + 100
        self.Data[ UserID ].Balance.s = self.Data[ UserID ].Balance.s - 1
    end
    while( self.Data[ UserID ].Balance.s < 0 ) do
        self.Data[ UserID ].Balance.s = self.Data[ UserID ].Balance.s + 100
        self.Data[ UserID ].Balance.g = self.Data[ UserID ].Balance.g - 1
    end
    rust.SendChatToUser( netuser, self.Chat, self:printBalance( netuser, g, s, c, false ) )
    self:Save()
end

function PLUGIN:printBalance( netuser, g, s, c, alter )
    local UserID = rust.GetUserID( netuser )
    local data = self.Data[ UserID ].Balance
    local msg = ''
    if(( g > 0 ) and ( alter )) then
        msg = '[ Gold: ' .. data.g .. ' ( +' .. g ..' ) ]  '
    elseif(( g > 0 ) and ( not alter )) then
        msg = '[ Gold: ' .. data.g .. ' ( -' .. g ..' ) ]  '
    else
        msg = '[ Gold: ' .. data.g .. ' ]  '
    end
    if(( s > 0 ) and ( alter )) then
        msg = msg ..'[ Silver: ' .. data.s .. ' ( +' .. s ..' ) ]  '
    elseif(( s > 0 ) and ( not alter )) then
        msg = msg .. '[ Silver: ' .. data.s .. ' ( -' .. s ..' ) ]  '
    else
        msg = msg .. '[ Silver: ' .. data.s .. ' ]  '
    end
    if(( c > 0 ) and ( alter )) then
        msg = msg .. '[ Copper: ' .. data.c .. ' ( +' .. c ..' ) ]  '
    elseif(( c > 0 ) and ( not alter )) then
        msg = msg .. '[ Copper: ' .. data.c .. ' ( -' .. c ..' ) ]  '
    else
        msg = msg .. '[ Copper: ' .. data.c .. ' ]  '
    end
    return msg
end

function PLUGIN:cmdBal( netuser )
    rust.SendChatToUser( netuser, self.Chat, self:printBalance( netuser,0,0,0 ))
    self:AddBalance( netuser, 5,0,0 )
end

-- function PLUGIN:cmdHelp( netuser, cmd, args)

-- end

-- |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--  STORE FUNCTIONS!!
-- |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:cmdStore( netuser, cmd, args )
    if( not args[1] ) then
        rust.SendChatToUser(netuser,' ',' ')
        rust.SendChatToUser(netuser,self.Chat,'╔════════════════════════')
        rust.SendChatToUser(netuser,self.Chat,'║ store >')
        rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
        rust.SendChatToUser(netuser,self.Chat,'║ Carbon Economy is a complex but easy to use')
        rust.SendChatToUser(netuser,self.Chat,'║ economy system. To navigate trough the shop')
        rust.SendChatToUser(netuser,self.Chat,'║ you\'ll be using categories and ID\'s')
        rust.SendChatToUser(netuser,self.Chat,'║ Available categories: ')
        rust.SendChatToUser(netuser,self.Chat,'║ food, tools, mats, armor, weapons, ammo,')
        rust.SendChatToUser(netuser,self.Chat,'║ mods, building, adv building and misc')
        rust.SendChatToUser(netuser,self.Chat,'║ If you\'ve found your item, check the ID.')
        rust.SendChatToUser(netuser,self.Chat,'║ With the ID you can buy items from the shop or')
        rust.SendChatToUser(netuser,self.Chat,'║ even sell items with the ID. It is however possible')
        rust.SendChatToUser(netuser,self.Chat,'║ to buy and sell with full item names. ')
        rust.SendChatToUser(netuser,self.Chat,'║ But be aware, it must be exactly the item name.')
        rust.SendChatToUser(netuser,self.Chat,'║ ie: "Cooked Chicken Breast" ')
        rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
        rust.SendChatToUser(netuser,self.Chat,'║ ⌘ /store •  "category"  • ')
        rust.SendChatToUser(netuser,self.Chat,'╚════════════════════════')
        rust.SendChatToUser(netuser,' ',' ')
    elseif( args[1] ) and ( not args[2] ) then
        local cat = args[1]:lower()
        local b = func:containsval(self.cat, cat )
        if( b) then
            rust.SendChatToUser(netuser,self.Chat,'╔════════════════════════')
            rust.SendChatToUser(netuser,self.Chat,'║ store > ' .. cat )
            rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
            local found = false
            for k, v in pairs( self.Item ) do
                if ( v.cat == cat ) then
                    if( not( v.price.g == 0 and v.price.s == 0 and v.price.c == 0)) then
                        found = true
                        rust.SendChatToUser(netuser,self.Chat,'║  [ID: ' .. tostring(k) .. ' }  Item: ' .. v.name )
                    end
                end
            end
            if( not found ) then rust.SendChatToUser(netuser,self.Chat,'║ We\'re deeply sorry, currently there are') end
            if( not found ) then rust.SendChatToUser(netuser,self.Chat,'║ no items for sale in this category.') end
            rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
            rust.SendChatToUser(netuser,self.Chat,'║ ⌘ /buy ID | /sell ID ')
            rust.SendChatToUser(netuser,self.Chat,'╚════════════════════════')
        else
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,self.Chat,'╔════════════════════════')
            rust.SendChatToUser(netuser,self.Chat,'║ store > ' .. cat .. ' > ϟ error')
            rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
            rust.SendChatToUser(netuser,self.Chat,'║ Invalid category.')
            rust.SendChatToUser(netuser,self.Chat,'║ Available categories:')
            rust.SendChatToUser(netuser,self.Chat,'║ food, tools, mats, armor, weapons, ammo,')
            rust.SendChatToUser(netuser,self.Chat,'║ mods, building, adv building and misc')
            rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
            rust.SendChatToUser(netuser,self.Chat,'║ ⌘  •  /store  •  ')
            rust.SendChatToUser(netuser,self.Chat,'╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        end
    else
        rust.SendChatToUser(netuser,' ',' ')
        rust.SendChatToUser(netuser,self.Chat,'╔════════════════════════')
        rust.SendChatToUser(netuser,self.Chat,'║ store > ϟ error')
        rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
        rust.SendChatToUser(netuser,self.Chat,'║ Invalid arguments.')
        rust.SendChatToUser(netuser,self.Chat,'║ Available arguments are:')
        rust.SendChatToUser(netuser,self.Chat,'║ /store')
        rust.SendChatToUser(netuser,self.Chat,'║ /store CATEGORY')
        rust.SendChatToUser(netuser,self.Chat,'║ Available categories:')
        rust.SendChatToUser(netuser,self.Chat,'║ food, tools, mats, armor, weapons, ammo,')
        rust.SendChatToUser(netuser,self.Chat,'║ mods, building, adv building and misc')
        rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
        rust.SendChatToUser(netuser,self.Chat,'║ ⌘ store  ')
        rust.SendChatToUser(netuser,self.Chat,'╚════════════════════════')
        rust.SendChatToUser(netuser,' ',' ')
    end
end
-- self.cat = { 'misc','armor','food','weapons','building','adv building','tools', 'mats', 'ammo','mods' }
function PLUGIN:cmdBuy( netuser, cmd, args )
    -- GIVING DA INFO!
    if( not args[1] ) then
        rust.Notice( netuser, 'help info ' )
        -- Your job, Mischa. xD
        return end
    -- Getting da item!
    if ( args[1] and not args[2] ) then
        -- local data = self.Item[ tostring(args[1]) ]
        local data = false
        local key = false
        if ( not tonumber( args[1] )) then
            for k,v in pairs( self.Item ) do
                if( v.name == args[1] ) then data = v key = k break end
            end
        else
            key = tostring(args[1])
            data = self.Item[ key ]
        end
        if( data and key ) and ( data.price.g > 0 or data.price.s > 0 or data.price.c > 0) then
            local price = ""
            if( data.price.g > 0 ) then
                price = tostring( '[ Gold: ' .. data.price.g .. ' ] ' )
            elseif( data.price.s > 0 ) then
                price = price .. tostring(  '[ Silver: ' .. data.price.s .. ' ] ' )
            elseif( data.price.c > 0 ) then
                price = price .. tostring( '[ Copper: ' .. data.price.c .. ' ] ' )
            end
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ ' .. self.Chat .. '  buy > [' .. key .. ']  ' .. data.name )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ Name:      ' .. data.name )
            rust.SendChatToUser(netuser,' ','║ Price:       ' .. tostring( price ) )
            rust.SendChatToUser(netuser,' ','║ Stock:      ( ' .. data.amount .. ' / ' .. data.max .. ' )'  )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ Category: ' .. data.cat )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        elseif( data and key ) and ( data.price.g == 0 and data.price.s == 0 and data.price.c == 0 ) then
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  buy > ' .. data.name .. ' > ϟ error ')
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ' .. data.name .. ' is not tradable. ' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        else
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  buy > ' .. tostring( args[1] ) .. ' > ϟ error ')
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ' .. args[1] .. ' not found!' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        end
    elseif( args[1] and args[2] and not args[3] ) then
        -- buy stuff.
        local data = false
        local key = false
        local amount = math.floor(( tonumber( args[2] )))
        if not amount then rust.Notice( netuser, 'Invalid amount! Please put a numeric amount! (ie. 8 )' ) return end
        -- Check if item exists.
        if ( not tonumber( args[1] )) then -- if args[2] is string. ( Item Name )
            for k,v in pairs( self.Item ) do
                if( v.name == args[1] ) then data = v key = k break end
            end
        else -- if args[2] is number ( ID )
            key = tostring(args[1])
            data = self.Item[ key ]
        end
        if( data and key and ( not ( amount <= data.amount ))) and ( data.price.g > 0 or data.price.s > 0 or data.price.c > 0) then -- not enough items in the market!
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  buy > ' .. data.name .. ' > ϟ error ')
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ Insufficient amount in store: ' )
            rust.SendChatToUser(netuser,' ','║ Amount available: ' )
            rust.SendChatToUser(netuser,' ','║ ( ' .. data.amount .. ' / ' .. data.max .. ' )' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        elseif( data and key and amount and ( amount <= data.amount )) and ( data.price.g > 0 or data.price.s > 0 or data.price.c > 0) then -- Item exist and is tradable
            local g,s,c = data.price.g * amount, data.price.s * amount, data.price.c * amount
            local canbuy = self:canBuy( netuser, g, s ,c )
            local datablock = rust.GetDatablockByName( data.name )
            if not datablock then rust.Notice( netuser, ' Datablock not found, report this to a GM please. ') return end
            if( canbuy ) then -- Has enough money datablock found.
                local inv = rust.GetInventory( netuser )
                if not inv then rust.Notice( netuser, 'Inventory not found! Please report this to a GM' ) return end
                local isUnstackable = func:containsval( unstackable, data.name )
                local invamount = amount
                if( isUnstackable ) then invamount = amount * 250 end
                local i = 0
                while( i <= 36 )do
                    local b, item = inv:GetItem( i )
                    if (b) then
                        local s = tostring( item )
                        local x = string.find(s, "%(on", 2) -2
                        local itemname = string.sub(s, 2, x)
                        if( itemname == data.name ) then
                            if( not isUnstackable ) then
                                local tmp = item.uses
                                local space = 250 - item.uses
                                invamount = invamount - space
                            end
                        end
                    else
                        invamount = invamount - 250
                    end
                    i = i + 1
                end
                if( invamount <= 0 ) then -- Enough inventory, space everything checks out.
                    self:RemoveBalance( netuser, g,s,c )
                    inv:AddItemAmount( datablock, amount )
                    self.Item[ key ].amount = self.Item[ key ].amount - amount
                    while ( c >= 100 ) do
                        c = c - 100
                        s = s + 1
                    end
                    while ( s >= 100 ) do
                        s = s - 100
                        g = g + 1
                    end
                    rust.SendChatToUser(netuser,' ',' ')
                    rust.SendChatToUser(netuser,' ','╔════════════════════════')
                    rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  buy > ' .. data.name .. ' > bought ')
                    rust.SendChatToUser(netuser,' ','╟────────────────────────')
                    rust.SendChatToUser(netuser,' ','║ Succesfully bought: ' )
                    rust.SendChatToUser(netuser,' ','║ ' .. amount .. 'x ' .. data.name  )
                    rust.SendChatToUser(netuser,' ','║ Costs:'  )
                    rust.SendChatToUser(netuser,' ','║ [ Gold: ' .. g .. ' ] [ Silver: ' .. s .. ' ]  [ Copper: ' .. c ..' ]' )
                    rust.SendChatToUser(netuser,' ','╟────────────────────────')
                    rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
                    rust.SendChatToUser(netuser,' ','╚════════════════════════')
                    rust.SendChatToUser(netuser,' ',' ')
                    self:ItemSave()
                else -- Not enough inventory space
                    rust.Notice( netuser, 'Not enough inventory space!' )
                    return
                end
            else -- does not have enough money
                while ( c >= 100 ) do
                    c = c - 100
                    s = s + 1
                end
                while ( s >= 100 ) do
                    s = s - 100
                    g = g + 1
                end
                rust.SendChatToUser(netuser,' ',' ')
                rust.SendChatToUser(netuser,' ','╔════════════════════════')
                rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  buy > ' .. data.name .. ' > ϟ error ')
                rust.SendChatToUser(netuser,' ','╟────────────────────────')
                rust.SendChatToUser(netuser,' ','║ Insufficient funds! ' )
                rust.SendChatToUser(netuser,' ','║ Total cost: ' )
                rust.SendChatToUser(netuser,' ','║ [ Gold: ' .. g .. ' ] [ Silver: ' .. s .. ' ]  [ Copper: ' .. c ..' ]' )
                rust.SendChatToUser(netuser,' ','║ Your balance:' )
                rust.SendChatToUser(netuser,' ','║ ' .. self:printBalance( netuser,0,0,0 ) )
                rust.SendChatToUser(netuser,' ','╟────────────────────────')
                rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
                rust.SendChatToUser(netuser,' ','╚════════════════════════')
                rust.SendChatToUser(netuser,' ',' ')

            end
        elseif( data and key and amount ) and ( data.price.g == 0 and data.price.s == 0 and data.price.c == 0 ) then -- Item exist but is not tradable
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  buy > ' .. data.name .. ' > ϟ error ')
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ Item untradeable! ' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        else -- Item does not not exist.
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  buy > ' .. tostring( args[1] ) .. ' > ϟ error ')
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ' .. args[1] .. ' not found!' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        end
    else
        rust.Notice( netuser, 'Help' )
    end
end

function PLUGIN:cmdSell( netuser, cmd, args)
    if( not args[1] ) then
        rust.Notice( netuser, 'help info ' )
        -- Your job, Mischa. xD
        return end
    -- Getting da item!
    if ( args[1] and not args[2] ) then
        -- local data = self.Item[ tostring(args[1]) ]
        local data = false
        local key = false
        if ( not tonumber( args[1] )) then
            for k,v in pairs( self.Item ) do
                if( v.name == args[1] ) then data = v key = k break end
            end
        else
            key = tostring(args[1])
            data = self.Item[ key ]
        end
        if( data and key ) and ( data.price.g > 0 or data.price.s > 0 or data.price.c > 0) then
            local price = ""
            if( data.price.g > 0 ) then
                price = tostring( '[ Gold: ' .. math.floor( data.price.g * .6 ) .. ' ] ' )
            elseif( data.price.s > 0 ) then
                price = price .. tostring(  '[ Silver: ' .. math.floor( data.price.s * .6 ) .. ' ] ' )
            elseif( data.price.c > 0 ) then
                price = price .. tostring( '[ Copper: ' .. math.floor( data.price.c * .6 ) .. ' ] ' )
            end
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ ' .. self.Chat .. '  sell > [' .. key .. ']  ' .. data.name )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ Name:      ' .. data.name )
            rust.SendChatToUser(netuser,' ','║ sell:       ' .. tostring( price ) )
            rust.SendChatToUser(netuser,' ','║ Stock:      ( ' .. data.amount .. ' / ' .. data.max .. ' )'  )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ Category: ' .. data.cat )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        elseif( data and key ) and ( data.price.g == 0 and data.price.s == 0 and data.price.c == 0 ) then
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  sell > ' .. data.name .. ' > ϟ error ')
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ' .. data.name .. ' is not tradable. ' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        else
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  sell > ' .. tostring( args[1] ) .. ' > ϟ error ')
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ' .. args[1] .. ' not found!' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        end
    elseif( args[1] and args[2] and not args[3] ) then
        -- buy stuff.
        local data = false
        local key = false
        local amount = math.floor(( tonumber( args[2] )))
        if not amount then rust.Notice( netuser, 'Invalid amount! Please put a numeric amount! (ie. 8 )' ) return end
        if not amount > 0 then rust.Notice( netuser, 'Invalid amount!' ) return end
        -- Check if item exists.
        if ( not tonumber( args[1] )) then -- if args[2] is string. ( Item Name )
            for k,v in pairs( self.Item ) do
                if( v.name == args[1] ) then data = v key = k break end
            end
        else -- if args[2] is number ( ID )
            key = tostring(args[1])
            data = self.Item[ key ]
        end
        if( data and key and (( amount + data.amount ) > data.max )) and ( data.price.g > 0 or data.price.s > 0 or data.price.c > 0) then -- not enough items in the market!
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  buy > ' .. data.name .. ' > ϟ error ')
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ The store cannot store this much items! ' )
            rust.SendChatToUser(netuser,' ','║ Current amount: ' )
            rust.SendChatToUser(netuser,' ','║ ( ' .. data.amount .. ' / ' .. data.max .. ' )' )
            rust.SendChatToUser(netuser,' ','║ Amount that can be sold: ' .. data.max - data.amount )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        elseif( data and key and amount and ( amount + data.amount ) <= data.max ) and ( data.price.g > 0 or data.price.s > 0 or data.price.c > 0) then -- Item exist and is tradable
            local datablock = rust.GetDatablockByName( data.name )
            if not datablock then rust.Notice( netuser, ' Datablock not found, report this to a GM please. ') return end
            local inv = rust.GetInventory( netuser )
            if not inv then rust.Notice( netuser, 'Inventory not found, please report this to a GM.' ) return end
            local isUnstackable = func:containsval(unstackable,data.name)
            local i = 0
            local item = inv:FindItem(datablock)
            if (item) then
                if (not isUnstackable) then
                    while (i < amount) do
                        if (item.uses > 0) then
                            item:SetUses(item.uses - 1)
                            i = i + 1
                        else
                            inv:RemoveItem(item)
                            item = inv:FindItem(datablock)
                            if (not item) then
                                break
                            end
                        end
                    end
                else
                    while (i < amount) do
                        inv:RemoveItem(item)
                        i = i + 1
                        item = inv:FindItem(datablock)
                        if (not item) then
                            break
                        end
                    end
                end
            else rust.Notice(netuser, "Item not found in inventory!") return end
            if ((not isUnstackable) and (item) and (item.uses <= 0)) then inv:RemoveItem(item) end
            local g,s,c = math.floor(( data.price.g * i ) * 0.6),math.floor((data.price.s * i) * 0.6),math.floor(( data.price.c * i ) * 0.6)
            self.Item[ key ].amount = self.Item[ key ].amount + i
            while ( c >= 100 ) do
                c = c - 100
                s = s + 1
            end
            while ( s >= 100 ) do
                s = s - 100
                g = g + 1
            end
            self:AddBalance( netuser, g,s,c )
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  buy > ' .. data.name .. ' > Sold ')
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ Succesfully Sold: ' )
            rust.SendChatToUser(netuser,' ','║ ' .. i .. 'x ' .. data.name  )
            rust.SendChatToUser(netuser,' ','║ Profit:'  )
            rust.SendChatToUser(netuser,' ','║ [ Gold: ' .. g .. ' ] [ Silver: ' .. s .. ' ]  [ Copper: ' .. c ..' ]' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
            self:ItemSave()
        elseif( data and key and amount ) and ( data.price.g == 0 and data.price.s == 0 and data.price.c == 0 ) then -- Item exist but is not tradable
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  sell > ' .. data.name .. ' > ϟ error ')
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ Item untradeable! ' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        else -- Item does not not exist.
            rust.SendChatToUser(netuser,' ',' ')
            rust.SendChatToUser(netuser,' ','╔════════════════════════')
            rust.SendChatToUser(netuser,' ','║ '.. self.Chat .. '  sell > ' .. tostring( args[1] ) .. ' > ϟ error ')
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ' .. args[1] .. ' not found!' )
            rust.SendChatToUser(netuser,' ','╟────────────────────────')
            rust.SendChatToUser(netuser,' ','║ ⌘ /store to check for ID\'s ' )
            rust.SendChatToUser(netuser,' ','╚════════════════════════')
            rust.SendChatToUser(netuser,' ',' ')
        end
    else
        rust.Notice( netuser, 'Help' )
    end
end

function PLUGIN:LoadDefaultConfig()
    core.Config = {}
    core.Config[ "TransferFee" ] = 5                                            -- Fee that will be deducted when transfering money to friends ( In percent ( $ ))
    core.Config[ "Chat" ] = "₠"                                                 -- Chat name
    core.Config[ "Rewards" ] = {}
    core.Config.Rewards[ "PlayerKill" ] = {['max']=15,['min']=8}                -- Reward for killing a Player ( In percent ( % ))
    core.Config.Rewards[ "OnKilled" ] = {['max']=10,['min']=6}                  -- Penalty for being killed ( In percent ( % ))
    core.Config.Rewards[ "ZombieNPC_SLOW" ] = {['max']=25,['min']=18}           -- Reward for killing a ZombieNPC_SLOW
    core.Config.Rewards[ "ZombieNPC_FAST" ] = {['max']=30,['min']=20}           -- Reward for killing a ZombieNPC_FAST
    core.Config.Rewards[ "ZombieNPC" ] = {['max']=25,['min']=10}                -- Reward for killing a ZombieNPC
    core.Config.Rewards[ "MutantBear" ] = {['max']=30,['min']=15}               -- Reward for killing a MutantBear
    core.Config.Rewards[ "MutantWolf" ] = {['max']=20,['min']=10}               -- Reward for killing a MutantWolf
    core.Config.Rewards[ "Bear" ] = {['max']=25,['min']=10}                     -- Reward for killing a Bear
    core.Config.Rewards[ "Wolf" ] = {['max']=20,['min']=8}                      -- Reward for killing a Wolf
    core.Config.Rewards[ "Stag_A" ] = {['max']=15,['min']=8}                    -- Reward for killing a Stag
    core.Config.Rewards[ "Boar_A" ] = {['max']=15,['min']=8}                    -- Reward for killing a Boar
    core.Config.Rewards[ "Chicken" ] = {['max']=15,['min']=8}                   -- Reward for killing a Chicken
    core.Config.Rewards[ "Rabbit" ] = {['max']=15,['min']=8}                    -- Reward for killing a Rabbit
end

function PLUGIN:Save()
    self.DataFile:SetText( json.encode( self.Data, { indent = true } ) )
    self.DataFile:Save()
end

function PLUGIN:ItemSave()
    self.ItemFile:SetText( json.encode( self.Item, { indent = true } ) )
    self.ItemFile:Save()
end

-- API bind
api.Bind( PLUGIN, "ce" )