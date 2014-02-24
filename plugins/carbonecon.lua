PLUGIN.Title = "Carbon Ecnomy"
PLUGIN.Description = ""
PLUGIN.Version = "0.1 alpha"
PLUGIN.Author = "Mischa & CareX"


function PLUGIN:Init()
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
        self.Config = json.decode( cfg_txt )
        print( "carbon_cfg file loaded" )
    else
        self:LoadDefaultConfig()
        print( "carbon_cfg file created" )
        self.CfgFile:SetText( json.encode( self.Config, { indent = true } ) )
        self.CfgFile:Save()
    end

    local count = 0
    for _,v in pairs(self.Data) do count = count + 1 end
    print("Carbon: A total of " .. tostring(count) .. " users has been found.")

    -- Sets CurrencySymbol, Chat name
    self.Chat = self.Config.Chat


    -- Initializing chat commands
    self:AddChatCommand( "ehelp", self.cmdHelp )
    self:AddChatCommand( "bal", self.cmdBal )

    self:AddChatCommand('ereload', self.cmdReload)

    print( "carbon_econ version " .. self.Version .. " Loading complete." )
end

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
                        print( tostring( 'gg: ' .. data.gg .. ' | gs: ' .. data.gs .. ' | gc: ' .. data.gc ))
                        print( tostring( 'tg: ' .. data.tg .. ' | ts: ' .. data.ts .. ' | tc: ' .. data.tc ))
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
            local npcData = self.Config.Rewards[string.gsub(tostring(dmg.victim.networkView.name), '%(Clone%)', '')]
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
    local data = self:getUserData( netuser )
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
    local getbal = math.floor(( bal * ( math.floor( math.random( self.Config.Rewards.PlayerKill.min, self.Config.Rewards.PlayerKill.max )) / 100 )))
    bal = math.floor((( bal - getbal ) - ( bal * ( math.floor( math.random( self.Config.Rewards.OnKilled.min, self.Config.Rewards.OnKilled.max )) / 100 ))))
    while getbal >= 10000 do
        gg = gg + 1
        getbal = getbal - 10000
    end
    while (getbal >= 100 ) do
        gs = gs + 1
        getbal = getbal - 100
    end
    local gc = getbal

    while bal >= 10000 do
        tg = tg + 1
        bal = bal - 10000
    end
    while (bal >= 100 ) do
        ts = ts + 1
        bal = bal - 100
    end
    local tc = bal
    print( tostring( 'gg: ' .. gg .. ' | gs: ' .. gs .. ' | gc: ' .. gc ))
    print( tostring( 'tg: ' .. tg .. ' | ts: ' .. ts .. ' | tc: ' .. tc ))
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
    rust.SendChatToUser( netuser, self.Chat, "HAI 4!" )
end

-- function PLUGIN:cmdHelp( netuser, cmd, args)

-- end

function PLUGIN:LoadDefaultConfig()
    self.Config = {}
    self.Config[ "TransferFee" ] = 5                                            -- Fee that will be deducted when transfering money to friends ( In percent ( $ ))
    self.Config[ "Chat" ] = "CarbonEcon"                                        -- Chat name
    self.Config[ "Rewards" ] = {}
    self.Config.Rewards[ "PlayerKill" ] = {['max']=15,['min']=8}                -- Reward for killing a Player ( In percent ( % ))
    self.Config.Rewards[ "OnKilled" ] = {['max']=10,['min']=6}                  -- Penalty for being killed ( In percent ( % ))
    self.Config.Rewards[ "ZombieNPC_SLOW" ] = {['max']=25,['min']=18}           -- Reward for killing a ZombieNPC_SLOW
    self.Config.Rewards[ "ZombieNPC_FAST" ] = {['max']=30,['min']=20}           -- Reward for killing a ZombieNPC_FAST
    self.Config.Rewards[ "ZombieNPC" ] = {['max']=25,['min']=10}                -- Reward for killing a ZombieNPC
    self.Config.Rewards[ "MutantBear" ] = {['max']=30,['min']=15}               -- Reward for killing a MutantBear
    self.Config.Rewards[ "MutantWolf" ] = {['max']=20,['min']=10}               -- Reward for killing a MutantWolf
    self.Config.Rewards[ "Bear" ] = {['max']=25,['min']=10}                     -- Reward for killing a Bear
    self.Config.Rewards[ "Wolf" ] = {['max']=20,['min']=8}                      -- Reward for killing a Wolf
    self.Config.Rewards[ "Stag_A" ] = {['max']=15,['min']=8}                    -- Reward for killing a Stag
    self.Config.Rewards[ "Boar_A" ] = {['max']=15,['min']=8}                    -- Reward for killing a Boar
    self.Config.Rewards[ "Chicken" ] = {['max']=15,['min']=8}                   -- Reward for killing a Chicken
    self.Config.Rewards[ "Rabbit" ] = {['max']=15,['min']=8}                    -- Reward for killing a Rabbit
end

function PLUGIN:Save()
    self.DataFile:SetText( json.encode( self.Data, { indent = true } ) )
    self.DataFile:Save()
end

-- API bind
api.Bind( PLUGIN, "ce" )