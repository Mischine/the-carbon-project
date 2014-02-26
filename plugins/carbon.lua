PLUGIN.Title = 'Carbon'
PLUGIN.Description = 'experience. levels. skills. rewards.'
PLUGIN.Version = '0.0.8.1437a'
PLUGIN.Author = 'Mischa & CareX'
--[[ SPECIAL NOTES

--]]
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:Init | http://wiki.rustoxide.com/index.php?title=Hooks/Init
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:Init()
    if( not api.Exists( 'ce' ) ) then print( '[CARBON] Carbon needs carbon-econ to function.' ) return end

    print( 'Loading Carbon...' )
    --LOAD/CREATE CFG FILE
    self.ConfigFile = util.GetDatafile( 'carbon_cfg' )
    local cfg_txt = self.ConfigFile:GetText()
    if (cfg_txt ~= '') then
        print( 'Carbon cfg file loaded!' )
        self.Config = json.decode( cfg_txt )
    else
        print( 'Creating carbon cfg file...' )
        self:SetDefaultConfig()
    end
    --LOAD/CREATE RPG DATA FILE
    self.UserFile = util.GetDatafile( 'carbon_usr' )
    local dat_txt = self.UserFile:GetText()
    if (dat_txt ~= '') then
        print( 'Carbon dat file loaded!' )
        self.User = json.decode( dat_txt )
    else
        print( 'Creating carbon dat file...' )
        self.User = {}
        self:UserSave()
    end
    --LOAD/CREATE GUILD DATA FILE
    self.GuildFile = util.GetDatafile( 'carbon_gld' )
    local gld_txt = self.GuildFile:GetText()
    if (gld_txt ~= '') then
        print( 'Carbon gld file loaded!' )
        self.Guild = json.decode( gld_txt )
    else
        print( 'Creating carbon gld file...' )
        self.Guild = {}
        self.Guild[ 'temp' ] = {}
        self:GuildSave()
    end

    --LOAD/CREATE TEXT FILE
    self.txtFile = util.GetDatafile( 'carbon_txt' )
    local txt_txt = self.txtFile:GetText()
    if (txt ~= '') then
        print( 'carbon_txt file loaded!' )
        self.txt = json.decode( txt_txt )
    else
        print( 'carbon_txt file is missing!' )
    end

    self.sysname = self.Config.settings.sysname
    --TEMPORARY INVISIBLE GEAR COMMAND: REMOVE BEFORE RELEASE
    self:AddChatCommand('cotw', self.addcotw ) -- TESTING ONLY!
    self:AddChatCommand('x', self.x)
    --

    self:AddChatCommand( 'c', self.cmdCarbon )
    self:AddChatCommand( 'g', self.cmdGuilds )
    self:AddChatCommand( 'w', self.cmdWhisper )
    self:AddChatCommand( 'mail', self.cmdMail )
    self:AddChatCommand( 'alpha', self.AlphaTXT )     -- Alpha welcome text!
    -----------------------------------------------------------------------------------
    self:AddChatCommand( 'storm', self.cmdStorm )
    self:AddChatCommand('debug', self.cmdDebug)
    self:AddChatCommand('dump', self.dump)
    self:AddChatCommand('reset', self.SetDefaultConfig)
    spamNet = {}
    self.debugr = false
    self.rnd = 0
    timer.Repeat(0.0066666667, function() math.randomseed(math.random(100)) self.rnd = math.random(100) end)
    --timer.Repeat( 1, function() self.rnd = math.random( 0, 100 ) end )
    timer.Repeat( 60, function() self:GameUpdate() end ) -- This controls everything. guilds/random events etc. 1 minute timer.
    print( 'Carbon Loaded!' )
end

function PLUGIN:dump( netuser, cmd, args )
    local msg = s
    elf:xpbar(tonumber(args[1]))
    rust.BroadcastChat( msg )
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- Loads after all the other plugins are loaded!
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:PostInit()

end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- GameUpdate() -- Updates Guildcollectionsystem.
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GameUpdate()

end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- TURN DEBUG ON OR OFF! DEVELOPERTOOL! DISABLE ON ALPHA!
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:cmdDebug( netuser, cmd , args )
    if( self.debugr ) then
        self.debugr = false
        rust.SendChatToUser( netuser, self.sysname, 'debug: off' )
    else
        self.debugr = true
        rust.SendChatToUser( netuser, self.sysname, 'debug: on' )
    end
end

function PLUGIN:addcotw( netuser, cmd , args )
    local guild = self:getGuild( netuser )
    table.insert( self.Guild[ guild ].activeperks, 'cotw')
    rust.SendChatToUser( netuser, 'cotw added' )
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- table.containsval - check if the value is in the table [ table.containtsval( table, value ) ]
-- self:count( counts a table )
-- self:sayTable( lists the values of that table , sep is the seperator, so like , or ; )
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function table.containsval(t,cv) for _, v in ipairs(t) do  if v == cv then return true  end  end return nil end
function PLUGIN:count( table ) local i = 0 for k, v in pairs( table ) do i = i + 1 end return i end
function PLUGIN:sayTable( table, sep ) local msg = '' local count = #table if( count <= 0 ) then return 'N/A' end local i = true
for k, v in ipairs( table ) do if( i ) then msg = msg .. v i = false else msg = msg .. (sep .. v) end end msg = msg .. '.' return msg end
function table.returnvalues( table ) if( not table ) then return false end local msg = '' for k,v in pairs( table ) do msg = msg .. '[ ' .. v .. ' ]' end return msg end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--TEMPORARY PLUGIN FOR INVISIBILITY GEAR
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:x( netuser, cmd, args )
    local helmet = rust.GetDatablockByName( 'Invisible Helmet' )
    local vest = rust.GetDatablockByName( 'Invisible Vest' )
    local pants = rust.GetDatablockByName( 'Invisible Pants' )
    local boots = rust.GetDatablockByName( 'Invisible Boots' )
    local pref = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor )
    local inv = netuser.playerClient.rootControllable.idMain:GetComponent( 'Inventory' )
    local invitem1 = inv:AddItemAmount( helmet, 1, pref )
    local invitem2 = inv:AddItemAmount( vest, 1, pref )
    local invitem3 = inv:AddItemAmount( pants, 1, pref )
    local invitem4 = inv:AddItemAmount( boots, 1, pref )
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:OnKilled | http://wiki.rustoxide.com/index.php?title=Hooks/OnKilled
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:OnKilled (takedamage, dmg)
-----------------CLIENT VS CLIENT
    if (takedamage:GetComponent( 'HumanController' )) then
        local vicuser = dmg.victim.client.netUser
        local vicuserData = self.User[rust.GetUserID(vicuser)]
        if(dmg.victim.client and dmg.attacker.client) then
            local netuser = dmg.attacker.client.netUser
            local netuserData = self.User[rust.GetUserID(netuser)]
            if (netuser ~= vicuser) then
                netuserData.stats.kills.pvp = netuserData.stats.kills.pvp+1

                self:GiveDp( vicuser, vicuserData, math.floor(vicuserData.xp*self.Config.settings.dppercent/100))
            elseif(netuser == vicuser) then
                self:GiveDp( netuser, vicuserData, math.floor(netuserData.xp*self.Config.settings.dppercent/100))
            end
            return
-----------------PVE VS CLIENT
        elseif ((dmg.victim.client) and (not dmg.attacker.client)) then
            self:GiveDp( vicuser, vicuserData, math.floor(vicuserData.xp*self.Config.settings.dppercent/100))
        end
    end
-------------------CLIENT VS PVE
    local npcController = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI'}
    for i, npcController in ipairs(npcController) do
        if (takedamage:GetComponent( npcController )) then
            local npcData = self.Config.npc[string.gsub(tostring(dmg.victim.networkView.name), '%(Clone%)', '')]
            local netuser = dmg.attacker.client.netUser
            local netuserData = self.User[rust.GetUserID(netuser)]
            local xp = math.floor(npcData.xp*self.Config.settings.xpmodifier)
            if (not netuserData.stats.kills.pve[npcData.name]) then
                netuserData.stats.kills.pve[npcData.name] = 1
            else
                netuserData.stats.kills.pve[npcData.name] = netuserData.stats.kills.pve[npcData.name]+1
            end
            netuserData.stats.kills.pve.total = netuserData.stats.kills.pve.total+1
            self:GiveXp( weaponData, netuser, netuserData, xp)
            return end --break out of all loops after finding controller type
    end
-------------------CLIENT VS SLEEPER
    --[[
	if (string.find(takedamage.gameObject.Name, 'MaleSleeper(',1 ,true) and (dmg.attacker.client) and (dmg.attacker.client.netUser) and self.Config.settings.sleeperdppercent > 0) then
		local actorUser = dmg.attacker.client.netUser
		local coord = actorUser.playerClient.lastKnownPosition
		local sleepreId = self:SleeperPos(coord)
        if(sleepreId ~= nil) then
            self.Config.sleepers.pos[sleepreId] = nil
            self:GiveXp( actorUser, tonumber(math.floor(self.User[sleepreId].xp*self.Config.settings.sleeperxppercent/100)))
            self:setXpPercentById(sleepreId, tonumber(100-self.Config.settings.sleeperxppercent-self.Config.settings.dppercent))
        end
	end
    return
    --]]
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- OnProcessDamageEvent()
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--[[
local StatusIntGetter = util.GetFieldGetter( RustFirstPass.DamageEvent, "status", nil, System.Int32 )
function PLUGIN:OnProcessDamageEvent( takedamage, dmg )
    rust.BroadcastChat(tostring('damage amount: ' .. dmg.amount))
    rust.BroadcastChat(tostring('victim health: ' .. takedamage.health))
    dmg = self:ModifyDamage(takedamage, dmg)
    local status = StatusIntGetter( dmg )
    if (status == LifeStatus_WasKilled and takedamage.health <= 0 ) then
        --print( "setting health to 0!" )
        takedamage.health = 0
        self:OnKilled(takedamage, dmg)
    elseif (status == LifeStatus_IsAlive and takedamage.health > 0) then
        --print( "reducing health!" )
        --print( takedamage.health )
        takedamage.health = takedamage.health - dmg.amount
        --print( takedamage.health )
        self:OnHurt(takedamage, dmg)
    end
    rust.BroadcastChat(tostring('damage amount: ' .. dmg.amount))
    rust.BroadcastChat(tostring('victim health: ' .. takedamage.health))
    return dmg
end

local LifeStatusType = cs.gettype( "LifeStatus, Assembly-CSharp-firstpass" )
typesystem.LoadEnum(LifeStatusType, "LifeStatus" )
--Will print out alive or died in the server console when something takes damage.
function PLUGIN:OnProcessDamageEvent( takedamage, dmg )

    rust.BroadcastChat(tostring('damage amount: ' .. dmg.amount))
    rust.BroadcastChat(tostring('victim health: ' .. takedamage.health))

    dmg = self:ModifyDamage(takedamage, dmg) or dmg
    local status = dmg.status
    rust.BroadcastChat(tostring(status))

    if (status == LifeStatus.WasKilled or status == LifeStatus.IsDead) and takedamage.health > 0 then
        dmg.status = LifeStatus.IsAlive
        takedamage.health = takedamage.health - dmg.amount
        self:OnKilled(takedamage, dmg)
    end
    if (status == LifeStatus.IsAlive) then
        takedamage.health = takedamage.health - dmg.amount
        self:OnHurt(takedamage, dmg)
    end

    rust.BroadcastChat(tostring('damage amount: ' .. dmg.amount))
    rust.BroadcastChat(tostring('victim health: ' .. takedamage.health))

    return dmg
end

function PLUGIN:OnProcessDamageEvent( takedamage, dmg )
    rust.BroadcastChat(tostring('damage amount: ' .. dmg.amount))
    rust.BroadcastChat(tostring('victim health: ' .. takedamage.health))
    dmg = self:ModifyDamage(takedamage, dmg)
    self.BroadcastChat(tostring(takedamage.status))
    takedamage.health = takedamage.health - dmg.amount
    rust.BroadcastChat(tostring('damage amount: ' .. dmg.amount))
    rust.BroadcastChat(tostring('victim health: ' .. takedamage.health))
    return dmg
end
local StatusIntGetter = util.GetFieldGetter( RustFirstPass.DamageEvent, "status", nil, System.Int32 )
local LifeStatus_IsAlive = 0
local LifeStatus_IsDead = 2
local LifeStatus_WasKilled = 1
local LifeStatus_Failed = -1
--]]
function PLUGIN:OnProcessDamageEvent( takedamage, dmg )
    dmg = self:ModifyDamage(takedamage, dmg) or dmg
    if (GetTakeNoDamage( takedamage )) then return dmg end
    local status = StatusIntGetter( dmg )

    if dmg.extraData then
        weaponData = self.Config.weapon[tostring(dmg.extraData.dataBlock.name)]
    end
    if dmg.attacker.client then
        local isSamePlayer = (dmg.victim.client == dmg.attacker.client)
        if not isSamePlayer then
            if self:GetUserData(dmg.attacker.client.netUser) then
                local netuser = dmg.attacker.client.netUser
                local netuserData = self.User[rust.GetUserID(netuser)]
                if weaponData.lvl > netuserData.lvl then
                    local netuser = dmg.attacker.client.netUser
                    local netuserData = self.User[rust.GetUserID(netuser)]
                    dmg.status = LifeStatus.IsAlive
                    dmg.amount = 0
                    if not spamNet[weaponData.name .. netuser.displayName] then
                        self:Notice(netuser,'⊗','You are not proficient with this weapon!',5)
                        spamNet[weaponData.name .. netuser.displayName] = true
                        timer.Once(6, function() spamNet[weaponData.name .. netuser.displayName] = nil end)
                    end
                end
            end
        end
    end
    if (status == LifeStatus_WasKilled) then
        --print( "setting health to 0!" )
        takedamage.health = 0
        self:OnKilled(takedamage, dmg)
    elseif (status == LifeStatus_IsAlive) then
        --print( "reducing health!" )
        --print( takedamage.health )
        takedamage.health = takedamage.health - dmg.amount
        --print( takedamage.health )
        self:OnHurt(takedamage, dmg)
    end
    return dmg
end
--]]


--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:ModifyDamage | http://wiki.rustoxide.com/index.php?title=Hooks/ModifyDamage
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:ModifyDamage (takedamage, dmg)
--------------------CLIENT VS CLIENT
    if (takedamage:GetComponent( 'HumanController' )) then
        if(dmg.victim.client and dmg.attacker.client) then
            local isSamePlayer = (dmg.victim.client == dmg.attacker.client)
            if (dmg.victim.client.netUser.displayName and not isSamePlayer) then
                if (self:GetUserData(dmg.attacker.client.netUser) and self:GetUserData(dmg.victim.client.netUser)) then
                    if not dmg.damageTypes then return dmg end -- security measure to ensure bleeding or radiation does not fail.
                    local netuser = dmg.attacker.client.netUser
                    local netuserData = self.User[rust.GetUserID(netuser)]
                    local vicuser = dmg.victim.client.netUser
                    local vicuserData = self.User[rust.GetUserID(vicuser)]

                    if (not netuserData.skills[tostring(dmg.extraData.dataBlock.name)]) then
                        netuserData.skills[tostring(dmg.extraData.dataBlock.name)] = {['name']=tostring(weaponData.name),['xp']=0,['lvl']=0}
                        self:UserSave()
                    end

                    if (self.debugr == true) then print('---------------BEGIN ME VS PVP---------------') end
                    -- STEP 1 DAMAGE ROLL
                    dmg.amount = math.random(dmg.amount*0.5,tonumber(dmg.amount))   if (self.debugr == true) then print('RANDOM DAMAGE: ' .. tostring(dmg.amount)) end
                    -- STEP 2 DP MODIFIER
                    dmg.amount = self:modifyDP(netuserData, dmg.amount)
                    --STEP 3 ATR MODIFIER
                    dmg.amount = self:attrModify(weaponData, netuserData, vicuserData, dmg.amount)  if (self.debugr == true) then print('ATTRIBUTE DMG MODIFIER: ' .. tostring(dmg.amount)) end
                    -- STEP 4 WPN MODIFIER
                    dmg.amount = dmg.amount+netuserData.skills[weaponData.name].lvl*.3   if (self.debugr == true) then print('WEAPON SKILL BONUS: ' .. tostring(netuserData.skills[weaponData.name].lvl*.3)) end
                    --STEP 5 CRIT CHECK
                    dmg.amount = self:critCheck(weaponData, netuser, netuserData, dmg.amount)    if (self.debugr == true) then print('CRIT CHANCE: ' .. tostring(dmg.amount)) end
                    -- STEP 6 VIC MODIFIER
                    if vicuserData.dmg ~= 1 then dmg.amount = dmg.amount*vicuserData.dmg if (self.debugr == true) then print('vicuser dmg modifier: ' .. tostring(dmg.amount)) end end
                    --STEP 7 VIC STA MOD
                    dmg.amount = self:staModify(netuserData, vicuserData, nil, dmg.amount)
                    --STEP 8 PERK STONE
                    dmg.amount = self:perkStoneskin(netuser, netuserData, vicuser, vicuserData, dmg.amount)
                    -- STEP 9 PERK PARRY
                    dmg.amount = self:perkParry(vicuser, vicuserData, dmg.amount)

                    --GUILD: MODIFIERS
                    local guild = self:getGuild( netuser )
                    local vicguild = self:getGuild( vicuser )
                    if (self.debugr == true) then print( 'GUILDS: ' .. netuser.displayName .. ' : ' .. tostring( guild ) .. ' || ' .. vicuser.displayName .. ' : ' .. tostring( vicguild )  ) end
                    if ( guild ) and (vicguild ) then
                        local isRival = self:isRival( guild, vicguild )
                        if( isRival ) then
                            if (self.debugr == true) then print( tostring( guild ) .. ' and ' .. tostring( vicguild ) .. ' are rivals!' ) end
                            --Att Rally! bonus damage
                            local dmgmod = self:hasRallyCall( guild )
                            if( dmgmod ) then
                                if (self.debugr == true) then print('Before Rally Bonus Damage : ' .. tostring(dmg.amount) .. ' || After: ' .. tostring( dmg.amount * dmgmod )) end
                                dmg.amount = dmg.amount * dmgmod
                            end
                            --Vic Stand Your Ground defense bonus
                            local ddmgmod = self:hasSYGCall( vicguild )
                            if( ddmgmod ) then
                                if (self.debugr == true) then print('Before SYG Damage : ' .. tostring(dmg.amount) .. ' || After: ' .. tostring( dmg.amount * ddmgmod )) end
                                dmg.amount = dmg.amount * ddmgmod
                            end
                        end
                    end

                    return dmg

                end
            end
            if(isSamePlayer and self.Config.suicide) then
                --SUICIDE ACTION HERE
                return dmg
            end
----------------------PVE VS CLIENT
        elseif ((dmg.victim.client) and (not dmg.attacker.client)) then
            if not dmg.damageTypes then return dmg end
            if (self:GetUserData(dmg.victim.client.netUser)) then
                local vicuser = dmg.victim.client.netUser
                local vicuserData = self.User[rust.GetUserID(vicuser)]
                local npcData = self.Config.npc[string.gsub(tostring(dmg.attacker.networkView.name), '%(Clone%)', '')]
                if (self.debugr == true) then print('---------------BEGIN PVE VS ME---------------') end
                --STEP 1 DAMAGE ROLL
                dmg.amount = math.random(dmg.amount*0.5,tonumber(dmg.amount))   if (self.debugr == true) then print('RANDOM DAMAGE: ' .. tostring(dmg.amount)) end
                --STEP 2 DP MODIFIER
                --dmg.amount = self:modifyDP(netuserData, dmg.amount) NEEDS WORK FOR DEFENSE CHANGES
                -- STEP 3 ATR MODIFIER
                dmg.amount = self:attrModify(weaponData, npcData, vicuserData, dmg.amount)  if (self.debugr == true) then print('ATTRIBUTE DMG MODIFIER: ' .. tostring(dmg.amount)) end
                -- STEP 4 WPN MODIFIER
                dmg.amount = dmg.amount+netuserData.skills[weaponData.name].lvl*.3   if (self.debugr == true) then print('WEAPON SKILL BONUS: ' .. tostring(netuserData.skills[weaponData.name].lvl*.3)) end
                -- STEP 5 CRIT CHECK
                dmg.amount = self:critCheck(weaponData, npcData, vicuserData, dmg.amount)    if (self.debugr == true) then print('CRIT CHANCE: ' .. tostring(dmg.amount)) end
                --STEP 6 VIC MODIFIER
                if vicuserData.dmg ~= 1 then dmg.amount = dmg.amount*vicuserData.dmg if (self.debugr == true) then print('vicuser dmg modifier: ' .. tostring(dmg.amount)) end end
                -- STEP 7 VIC STA MOD
                dmg.amount = self:staModify(nil, vicuserData, nil, dmg.amount)if (self.debugr == true) then print('STAMINA MODIFIER:' .. tostring(dmg.amount)) end
                --STEP 8 PERK STONE
                dmg.amount = self:perkStoneskin(netuser, netuserData, vicuser, vicuserData, dmg.amount) if (self.debugr == true) then print('STONESKIN PERK: ' .. tostring(dmg.amount)) end
                --STEP 9 PERK PARRY
                dmg.amount = self:perkParry(vicuser, vicuserData, dmg.amount)--PERK PARRY

               --GUILD: MODIFIERS
                local guild = self:getGuild( vicuser )
                if (self.debugr == true) then print('Guild found: ' .. tostring( guild )  ) end
                if ( guild ) then
                    local cotw = self:hasCOTWCall( guild )
                    if( cotw ) then
                        if (self.debugr == true) then print('COTW Perk dmg from: ' .. dmg.amount .. ' to: ' .. dmg.amount * cotw .. ' || cotwmod: ' .. cotw ) end
                        dmg.amount = dmg.amount * cotw
                    end
                end


                return dmg
            end
        end
    end
----------------------------CLIENT VS PVE
    local npcController = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI' }
    for i, npcController in ipairs(npcController) do
        if (takedamage:GetComponent( npcController )) then
            local netuser = dmg.attacker.client.netUser
            local netuserData = self.User[rust.GetUserID(netuser)]
            local npcData = self.Config.npc[string.gsub(tostring(dmg.victim.networkView.name), '%(Clone%)', '')]

            if (not netuserData.skills[tostring(dmg.extraData.dataBlock.name)]) then
                netuserData.skills[weaponData.name] = {['name']=tostring(weaponData.name),['xp']=0,['lvl']=0}
                self:UserSave()
            end
            if (self.debugr == true) then print('---------------BEGIN ME VS PVE---------------') end
            --STEP 1 DAMAGE ROLL
            dmg.amount = math.random(dmg.amount*0.5,tonumber(dmg.amount))   if (self.debugr == true) then print('RANDOM DAMAGE: ' .. tostring(dmg.amount)) end
            --STEP 2 DP MODIFIER
            dmg.amount = self:modifyDP(netuserData, dmg.amount)
            -- STEP 3 ATR MODIFIER
            dmg.amount = self:attrModify(weaponData, netuserData, npcData, dmg.amount)      if (self.debugr == true) then print('ATTRIBUTE DMG MODIFIER: ' .. tostring(dmg.amount)) end
            --STEP 4 WPN MODIFIER
            dmg.amount = dmg.amount+netuserData.skills[ weaponData.name ].lvl*0.3      if (self.debugr == true) then print('WEAPON SKILL BONUS: ' .. tostring(netuserData.skills[weaponData.name].lvl*.3)) end
            -- STEP 5 CRIT CHECK
            dmg.amount = self:critCheck(weaponData, netuser, netuserData, dmg.amount)       if (self.debugr == true) then print('CRIT CHANCE: ' .. tostring(dmg.amount)) end
            -- STEP 6 VIC MODIFIER
            dmg.amount = dmg.amount*npcData.dmg     if (self.debugr == true) then print('vicuser dmg modifier: ' .. tostring(dmg.amount)) end
            --STEP 7 VIC STA MOD
            dmg.amount = self:staModify(netuserData, nil, npcData, dmg.amount)    if (self.debugr == true) then print('STAMINA MODIFIER:' .. tostring(dmg.amount)) end

            --GUILD STUFF
            local guild = self:getGuild( netuser )
            if (self.debugr == true) then print('Guild found: ' .. tostring( guild )  ) end
            if ( guild ) then
                local cotw = self:hasCOTWCall( guild )
                if( cotw ) then
                    if (self.debugr == true) then print('COTW Perk dmg from: ' .. dmg.amount .. ' to: ' .. dmg.amount * cotw .. ' || cotwmod: ' .. cotw ) end
                    dmg.amount = dmg.amount * cotw
                end
            end

            return dmg
        end
    end
-----------------------CLIENT VS SLEEPER
    if (string.find(tostring(takedamage.gameObject.Name), 'MaleSleeper(',1 ,true) and (dmg.attacker.client) and (dmg.attacker.client.netUser) and self.Config.settings.sleeperdppercent > 0) then
        if(sleepreId ~= nil) then
            --SLEEPER ACTION HERE
            return dmg
        end
    end

end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:staModify
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:staModify(netuserData, vicuserData, npcData, damage)
    if (vicuserData) then
        if (vicuserData.attributes.sta>0) then
            damage = damage-((vicuserData.attributes.sta+vicuserData.lvl)*0.1)
            if (self.debugr == true) then print('PLUGIN:staModify (vicuser) :' .. tostring(dmg.amount)) end
        end
    end
    if (npcData) then
        if (npcData.sta>0) then
            damage = damage-((npcData.sta+math.random(netuserData.lvl-1,netuserData.lvl+1))*0.1)
            if (self.debugr == true) then print('PLUGINS:staModify (npc):' .. tostring(damage)) end
        end
    end
    return damage
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:modifyDP
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--Adjust damage per death penalty
function PLUGIN:modifyDP(netuserData, damage)
    if (netuserData.dp > 0) then
        local dppercentage = netuserData.dp/netuserData.xp
        local dmgdp = damage*dppercentage
        damage = math.ceil(tonumber(damage-dmgdp))
        if (self.debugr == true) then print('PLUGIN:modifyDP: ' .. tostring(damage)) end
    end
    return damage
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:attrModify
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:attrModify(weaponData, netuserData, vicuserData, damage)
    if weaponData then
        if (weaponData.type == 'm') and (netuserData.attributes.str>0) then
            damage = damage + ((netuserData.attributes.str+netuserData.lvl)*.3)
            if (self.debugr == true) then print('PLUGIN:attrModify (str) :' .. tostring(damage)) end
        elseif (weaponData.type == 'l' or weaponData.type == 'c') and (netuserData.attributes.agi>0) then
            damage = damage + ((netuserData.attributes.agi+netuserData.lvl)*.3)
            if (self.debugr == true) then print('PLUGIN:attrModify (agi) :' .. tostring(damage)) end
        end
    end
    if not weaponData then
        if (netuserData.str>0) then
            damage = damage + ((netuserData.str+(math.random(vicuserData.lvl-1,vicuserData.lvl+1)))*.3)
            if (self.debugr == true) then print('PLUGIN:attrModify (no weaponData) :' .. tostring(damage)) end
        end
    end
    return damage
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:critCheck
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:critCheck(weaponData, netuser, netuserData, damage)
    if( self.User[ netuserData.id ].buffs[ 'ParryCrit' ]) then
        damage = damage * 2
        self.User[ netuserData.id ].buffs[ 'ParryCrit' ] = nil
        return damage
    end
    if (netuserData.attributes.agi>0) then
        local roll = self.rnd
        if (weaponData.type == 'm') then
            if ((netuserData.attributes.agi+netuserData.lvl)*.002 >= roll) then
                damage = damage * 2
                rust.InventoryNotice( netuser, 'Critical Hit!' )
                if (self.debugr == true) then print('PLUGIN:critCheck (m): ' .. tostring(damage)) end
            end
        elseif (weaponData.type == 'l' or weaponData.type == 'c') then
            if ((netuserData.attributes.agi+netuserData.lvl)*.001 >= roll) then
                damage = damage * 2
                rust.InventoryNotice( netuser, 'Critical Hit!' )
                if (self.debugr == true) then print('PLUGIN:critCheck (l/c)' .. tostring(damage)) end
            end
        end
    end
    return damage
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:perkStoneskin
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:perkStoneskin(netuser, netuserData, vicuser, vicuserData, damage)
    if ((vicuser) and (vicuser ~= netuser) and (vicuserData.perks.Stoneskin)) then
        if (vicuserData.perk.Stoneskin.lvl > 0) then
            if (vicuserData.perk.Stoneskin.lvl == 1) then
                damage = tonumber(damage - (damage*.05))
                if (self.debugr == true) then print('PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 2) then
                damage = tonumber(damage - (damage*.10))
                if (self.debugr == true) then print('PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 3) then
                damage = tonumber(damage - (damage*.15))
                if (self.debugr == true) then print('PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 4) then
                damage = tonumber(damage - (damage*.20))
                if (self.debugr == true) then print('PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 5) then
                damage = tonumber(damage - (damage*.25))
                if (self.debugr == true) then print('PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            end
        end
    end
    return damage
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:perkParry
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:perkParry(vicuser, vicuserData, damage)
    if ((vicuser) and (vicuserData.perks.Parry)) then
        if (vicuserData.perks.Parry.lvl > 0) then
            local roll = self.rnd
            if ((vicuserData.perks.Parry.lvl == 1) and (roll <= 3)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,'ParryCrit' )
                if (self.debugr == true) then print('PERK PARRY: ' .. tostring(damage)) end
            elseif ((vicuserData.perks.Parry.lvl == 2) and (roll <= 6)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,'ParryCrit' )
                if (self.debugr == true) then print('PERK PARRY: ' .. tostring(damage)) end
            elseif ((vicuserData.perks.Parry.lvl == 3) and (roll <= 9)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,'ParryCrit' )
                if (self.debugr == true) then print('PERK PARRY: ' .. tostring(damage)) end
            elseif ((vicuserData.perks.Parry.lvl == 4) and (roll <= 12)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,'ParryCrit' )
                if (self.debugr == true) then print('PERK PARRY: ' .. tostring(damage)) end
            elseif ((vicuserData.perks.Parry.lvl == 5) and (roll <= 15)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,'ParryCrit' )
                if (self.debugr == true) then print('PERK PARRY: ' .. tostring(damage)) end
            end
        end
    end
    return damage
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:GiveTimedBuff
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GiveTimedBuff( vicuserID, time, buff )
    if not self.User[ vicuserID ].buffs['ParryCrit'] then
        self.User[ vicuserID ].buffs['ParryCrit']=true
        timer.Once( time, function()
            if( self.User[ vicuserID ].buffs[ buff ] ) then self.User[ vicuserID ].buffs[ buff ] = nil end
        end )
    end
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:GiveXp
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GiveXp(weaponData, netuser, netuserData, xp)

    local guild = self:getGuild( netuser )
    if( guild ) then
        local gxp = math.floor( xp * .1 )
        local glory = self:hasForGlory( guild )
        if( glory ) then gxp = gxp * glory end
        --xp = xp - gxp --if we want to take from the players xp.
        self.Guild[ guild ].xp = self.Guild[ guild ].xp + gxp
        self:GuildSave()
        rust.InventoryNotice( netuser, '+' .. gxp .. 'gxp' )
    end

    if (netuserData.dp>xp) then
        netuserData.dp = netuserData.dp - xp
        rust.InventoryNotice( netuser, '-' .. (netuserData.dp - xp) .. 'dp' )
    elseif (netuserData.dp<=0) then
        netuserData.xp = netuserData.xp+xp
        netuserData.skills[ weaponData.name ].xp = netuserData.skills[ weaponData.name ].xp + xp
        rust.InventoryNotice( netuser, '+' .. xp .. 'xp' )
        self:PlayerLvl(netuser, netuserData, xp)
        self:WeaponLvl(weaponData, netuser, netuserData, xp)
    else
        local xp = xp-netuserData.dp
        netuserData.xp = netuserData.xp+xp
        netuserData.skills[ weaponData.name ].xp = netuserData.skills[ weaponData.name ].xp + xp
        netuserData.dp = 0
        rust.InventoryNotice( netuser, '-' .. netuserData.dp .. 'dp' )
        rust.InventoryNotice( netuser, '+' .. xp .. 'xp' )
        self:PlayerLvl(netuser, netuserData, xp)
        self:WeaponLvl(weaponData, netuser, netuserData, xp)
    end
    self:UserSave()
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:getLvl
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:getLvl( netuser )
    local netuserID = rust.GetUserID( netuser )
    local lvl = self.User[ netuserID ].lvl
    return lvl
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:GiveDp
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GiveDp(vicuser, vicuserData, dp)
    if ((vicuserData.dp+dp/vicuserData.xp) >= .5) then
        vicuserData.dp = vicuserData.xp*.5
        rust.InventoryNotice( vicuser, '+' .. (dp - vicuserData.xp*.5) .. 'dp' )
    else
        vicuserData.dp = vicuserData.dp + dp
        rust.InventoryNotice( vicuser, '+' .. (dp) .. 'dp' )
    end
    self:UserSave()
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:PlayerLvl
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:PlayerLvl(netuser, netuserData, xp)


    local calcLvl = math.floor((math.sqrt(100*((self.Config.settings.lvlmodifier*(netuserData.xp+xp))+25))+50)/100)
    if (calcLvl ~= netuserData.lvl) then
        netuserData.lvl = calcLvl
        rust.Notice( netuser, 'You are now level ' .. calcLvl .. '!', 5 )
    end
    local calcAp = math.floor(((math.sqrt(100*((self.Config.settings.lvlmodifier*(netuserData.xp+xp))+25))+50)/100)/3)
    if (calcAp > netuserData.ap) then
        netuserData.ap = calcAp
        timer.Once(2, function() rust.SendChatToUser( netuser, self.sysname, 'You have earned an attribute point!') end)
    end
    local calcPp = math.floor(((math.sqrt(100*((self.Config.settings.lvlmodifier*(netuserData.xp+xp))+25))+50)/100)/6)
    if (calcPp > netuserData.pp) then
        netuserData.pp = calcPp
        timer.Once(3, function() rust.SendChatToUser( netuser, self.sysname, 'You have earned a perk point!') end)
    end
    rust.SendChatToUser( netuser, self.sysname, tostring(netuserData.ap) .. ' ' .. tostring(netuserData.pp) .. ' ' .. tostring(calcAp) .. ' ' .. tostring(calcPp))
end

--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:WeaponLvl
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

function PLUGIN:WeaponLvl(weaponData, netuser, netuserData, xp)
    local calcLvl = math.floor((math.sqrt(100*((self.Config.settings.weaponlvlmodifier*(netuserData.skills[ weaponData.name ].xp+xp))+25))+50)/100)
    if (calcLvl ~= netuserData.skills[ weaponData.name ].lvl) then
        netuserData.skills[ weaponData.name ].lvl = calcLvl
        timer.Once( 5, function()  rust.Notice( netuser, 'Your skill with the ' .. tostring(weaponData.name) .. ' is now level ' .. tostring(calcLvl) .. '!', 5 ) end )
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:SetDpPercent
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:SetDpPercent(netuser, percent)
    self:SetDpPercentById(rust.GetUserID( netuser ) ,percent )
    if (percent >= 0 and percent <= 100) then
        --[[rust.SendChatToUser( netuser, self:printmoney(netuser) )--]]
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:SetDpPercentById
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:SetDpPercentById(netuserID, percent)
    if (percent >= 0 and percent <= 100) then
        if (percent == 0) then
            self.User[netuserID].dp = math.floor(self.User[netuserID].dp + self.User[netuserID].xp)
        else
            self.User[netuserID].dp = math.floor(self.User[netuserID].dp + (self.User[netuserID].xp * percent / 100))
        end
        self:UserSave()
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:SleeperPos
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:SleeperPos(point)
    for key,value in pairs(self.Config.sleepers.pos) do
        if (self:SleeperRadius(value,point,tonumber(self.Config.settings.sleeperradius))) then
            return key
        end
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:SleeperRadius
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:SleeperRadius(pos, point, rad)
    return (pos.x < point.x + rad and pos.x > point.x - rad)
            and (pos.y < point.y + rad and pos.y > point.y - rad)
            and (pos.z < point.z + rad and pos.z > point.z - rad)
end


--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:cmdStorm
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:cmdStorm(netuser,cmd, args)
    --rust.RunServerCommand( 'env.daylength 45')
    --rust.RunServerCommand( 'env.nightlength 15' )
    local Time = Rust.EnvironmentControlCenter.Singleton:GetTime()
    if Time < 2 or Time > 22 then
        timer.Repeat(1, 100, function() Time = Time+0.0066666667 end)
        timer.Repeat( 5, 20, function()
            local randomTime = math.random(0,10)
            timer.Once( randomTime, function()
                --rust.RunServerCommand( 'env.daylength 0.0005')
                --rust.RunServerCommand( 'env.nightlength 0.005' )
                local randomFlashCount = math.floor(math.random(0,5.9))
                local randomInterval = math.random(0.05, 0.05)
                timer.Repeat(randomInterval, randomFlashCount,
                    function() Rust.EnvironmentControlCenter.Singleton:SetTime(12) timer.Once(0.005, function() Rust.EnvironmentControlCenter.Singleton:SetTime(Time) end)
                end)

                local randomLength = math.random(0.10,0.25)
                timer.Once( randomLength, function()
                    --rust.RunServerCommand( 'env.daylength 45')
                    --rust.RunServerCommand( 'env.nightlength 15' )
                    Rust.EnvironmentControlCenter.Singleton:SetTime(Time)
                end)
            end)
        end )
    end
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- CARBON POPUP
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:Notice(netuser,prefix,text,duration)
    Rust.Rust.Notice.Popup( netuser.networkPlayer, prefix or " ", text .. '      ', duration or 4.0 )
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- CARBON CHAT COMMANDS
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:cmdCarbon(netuser,cmd,args)
    local netuserID = rust.GetUserID( netuser )
    local netuserData = self.User[netuserID]

    for k,v in ipairs(args)do args[k]=tostring(args[k]) end

    if(#args==0)then
        local msg = {
            'Character chat commands are activated with /c.',
            'At the top of each informational screen you will',
            'see a pseudo breadcrumb trail intended to help you',
            'with cmd navigation by displaying parent commands.',
            ' ',
            'i.e.  c > ... ',
            ' ',
            'The bar below contains child commands for further',
            'navigation.',
            ' ',
            'e.g.  /c xp',
        }
        self:cmdText(netuser, ' ', msg, '•  xp  •  atr  •  skills  •  perks  •  help  •') return
    end

    if #args==1 then
        if (args[1] == 'xp') then
            local a = netuserData.lvl+1 --level +1
            local ab = netuserData.lvl --level
            local b = self.Config.settings.lvlmodifier --level modifier
            local c = ((a*a)+a)/b*100-(a*100) --xp required for next level
            local d = math.floor(((netuserData.xp/c)*100)+0.5) -- percent currently to next level.
            local e = c-netuserData.xp -- left to go until level
            local f = ((ab*ab)+ab)/b*100-(ab*100) -- amount needed for current level
            local g = math.floor(((netuserData.dp/(f*.5))*100)+0.5) -- percentage of dp
            local h = (f*.5) -- total possible dp
            if (a == 2) and (self.Config.settings.lvlmodifier >= 2) then f = 0 end
            local msg = {
                'Level:                          ' .. tostring(a-1),
                'Experience:              (' .. tostring(netuserData.xp) .. '/' .. tostring(c) .. ')   [' .. tostring(d) .. '%]   ' .. '(' .. tostring(e) .. ')',
                self:medxpbar( d ),
                'Death Penalty:         (' .. tostring(netuserData.dp) .. '/' .. tostring(h) .. ')   [' .. tostring(g) .. '%]',
                self:medxpbar( g ),
            }
            self:cmdText(netuser, 'xp', msg, ' ') return
        elseif args[1]=='atr' then
            local msg = {
                'Strength:     ' .. netuserData.attributes.str,
                self:xpbar(netuserData.attributes.str,10),
                'Agility:      ' .. netuserData.attributes.agi,
                self:xpbar(netuserData.attributes.agi,10),
                'Stamina:      ' .. netuserData.attributes.sta,
                self:xpbar(netuserData.attributes.sta,10),
                'Intellect:    ' .. netuserData.attributes.int,
                self:xpbar(netuserData.attributes.int,10),
            }
            self:cmdText(netuser, 'atr', msg, '•  train  •  untrain  •') return
        elseif args[1] == 'skills' then
            local msg = {}
            for k,v in pairs(netuserData.skills) do
                local a = v.lvl+1 --level +1
                local b = self.Config.settings.weaponlvlmodifier --level modifier
                local c = ((a*a)+a)/b*100-(a*100) --xp required for next level
                local d = math.floor(((v.xp/c)*100)+0.5) -- percent currently to next level.
                table.insert( msg, tostring('   ' .. v.name .. '    •    Level: ' .. v.lvl .. '    •    ' .. 'Exp: ' .. v.xp ))
                table.insert( msg, tostring(self:xpbar( d, 32 )))
            end
            self:cmdText(netuser, 'skills', msg or ' ', '•  "skill name"  •') return
        elseif (args[1] == 'perks') then
            local msg = {'perks info here'}
            self:cmdText(netuser, 'perks', msg, '•  list  •  active  •') return
        else
            self:cmdError(netuser, ' ', '•  xp  •  atr  •  skills  •  perks  •  help  •') return
        end
    end
    if #args==2 then
        if args[1] == 'atr'then
            if args[2] == 'train' then
                local msg = {
                    'To level up your attributes you',
                    'must train using available attribute',
                    'points (ap). WARNING: to untrain you',
                    'will be required to pay a trainer.',
                    'The cost will increase the more you',
                    'times you untrain.',
                    ' ',
                    'Available AP:  ' .. netuserData.ap,
                }
                self:cmdText(netuser, 'atr > train', msg, '•  str #  •  agi #  •  sta #  •  int #  •') return
            elseif args[2] == 'untrain' then
                local msg = {
                    'To untrain your attribute points',
                    'you will have to pay a trainer.',
                    'WARNING: each time you untrain',
                    'the cost will increase.',
                    ' ',
                    'If you are sure you want to untrain',
                    'use the pay command.',
                    ' ',
                    'i.e. /c atr untrain pay',
                    ' ',
                    'Cost: ' .. tonumber(self.Config.settings.untraincost*(1+self.Config.settings.untraincostgrowth)^netuserData.ut),
                }
                self:cmdText(netuser, 'atr > untrain', msg, '•  pay  •') return
            else
                self:cmdError(netuser, 'atr', '•  train  •  untrain  •') return
            end
        elseif args[1] == 'skills'then
            local skillData = netuserData.skills[args[2]]
            if skillData then
                local a = skillData.lvl+1 --level +1
                local b = self.Config.settings.weaponlvlmodifier --level modifier
                local c = ((a*a)+a)/b*100-(a*100) --xp required for next level
                local d = math.floor(((skillData.xp/c)*100)+0.5) -- percent currently to next level.
                local e = c-skillData.xp -- left to go until level

                local msg = {'Skill:  ' .. skillData.name,'Level:  ' .. skillData.lvl,'Experience:  (' .. skillData.xp .. '/' .. c .. ')  [' .. d .. '%]  (' .. e .. ')', self:xpbar( d, 32 ) }

                self:cmdText(netuser, 'skills > ' .. tostring(skillData.name), msg, ' ') return
            else
                self:cmdError(netuser, 'skills', '•  "skill name"  •') return
            end
        else
            self:cmdError(netuser, ' ', '•  xp  •  atr  •  skills  •  perks  •  help  •') return
        end
    end
    if #args>=3 then
        if args[1] == 'atr' and args[2] == 'train' and tonumber(args[4]) >= 1 and (args[3] == 'str' or args[3] == 'agi' or args[3] == 'sta' or args[3] == 'int')then
            if netuserData.ap >= tonumber(args[4]) then
                if args[3] == 'str' then
                    if netuserData.attributes.str+tonumber(args[4])>10 or tonumber(args[4])>netuserData.ap then return end
                    netuserData.ap=netuserData.ap-tonumber(args[4])
                    netuserData.attributes.str=netuserData.attributes.str+tonumber(args[4])
                    rust.InventoryNotice(netuser, '+' .. tostring(args[4]) .. ' strength!')
                    self:UserSave()
                elseif args[3] == 'agi' then
                    if netuserData.attributes.agi+tonumber(args[4])>10 or tonumber(args[4])>netuserData.ap then return end
                    netuserData.ap=netuserData.ap-tonumber(args[4])
                    netuserData.attributes.agi=netuserData.attributes.agi+tonumber(args[4])
                    rust.InventoryNotice(netuser, '+' .. tostring(args[4]) .. ' agility!')
                    self:UserSave()
                elseif args[3] == 'sta' then
                    if netuserData.attributes.sta+tonumber(args[4])>10 or tonumber(args[4])>netuserData.ap then return end
                    netuserData.ap=netuserData.ap-tonumber(args[4])
                    netuserData.attributes.sta=netuserData.attributes.sta+tonumber(args[4])
                    rust.InventoryNotice(netuser, '+' .. tostring(args[4]) .. ' stamina!')
                    self:UserSave()
                elseif args[3] == 'int' then
                    if netuserData.attributes.int+tonumber(args[4])>10 or tonumber(args[4])>netuserData.ap then return end
                    netuserData.ap=netuserData.ap-tonumber(args[4])
                    netuserData.attributes.int=netuserData.attributes.int+tonumber(args[4])
                    rust.InventoryNotice(netuser, '+' .. tostring(args[4]) .. ' intellect!')
                    self:UserSave()
                else

                end
            else
                local msg = {
                    'Insufficient attribute points!'
                }
                self:cmdError(netuser, 'atr > train', '•  str #  •  agi #  •  sta #  •  int #  •', msg) return
            end

        elseif args[1] == 'atr' and args[2] == 'untrain' and args[3] == 'pay' then
            self:Notice(netuser, ' ', 'You have untrained all attributes!', 4)
            netuserData.attributes.str=0
            netuserData.attributes.agi=0
            netuserData.attributes.sta=0
            netuserData.attributes.int=0
            self:UserSave()
        else
            self:cmdError(netuser, 'atr', '•  add  •  remove  •') return
        end
    end

end
function PLUGIN:cmdText(netuser, breadcrumbs, msg, cmds)
    rust.SendChatToUser(netuser,self.sysname,' ')
    rust.SendChatToUser(netuser,self.sysname,'╔════════════════════════')
    rust.SendChatToUser(netuser,self.sysname,'║ c > ' .. breadcrumbs)
    rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
    for _,v in ipairs(msg) do
        rust.SendChatToUser(netuser,self.sysname,'║ ' .. v)
    end
    rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
    rust.SendChatToUser(netuser,self.sysname,'║ ⌘  ' .. cmds)
    rust.SendChatToUser(netuser,self.sysname,'╚════════════════════════')
    rust.SendChatToUser(netuser,self.sysname,' ')
end
function PLUGIN:cmdError(netuser, breadcrumbs, cmds, msg)
    rust.SendChatToUser(netuser,self.sysname,' ')
    rust.SendChatToUser(netuser,self.sysname,'╔════════════════════════')
    rust.SendChatToUser(netuser,self.sysname,'║ c > ' .. breadcrumbs .. ' > ϟ error')
    rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
    if msg then
        for _,v in ipairs(msg) do
            rust.SendChatToUser(netuser,self.sysname,'║ ' .. v)
        end
    else
        rust.SendChatToUser(netuser,self.sysname,'║ Invalid command! See the following')
        rust.SendChatToUser(netuser,self.sysname,'║ commands below for available commands.')
    end
    rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
    rust.SendChatToUser(netuser,self.sysname,'║ ⌘  ' .. cmds)
    rust.SendChatToUser(netuser,self.sysname,'╚════════════════════════')
    rust.SendChatToUser(netuser,self.sysname,' ')
    self:Notice(netuser, 'ϟ', 'invalid command', 2)
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:cmdWhisper
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:cmdWhisper( netuser, cmd, args )
    -- Syntax check
    if(( not args[1] ) or ( not args[2] )) then rust.SendChatToUser( netuser, self.sysname, '/w \'name\' message ' ) return end
    -- Player check
    local targname = tostring( args[1] )
    if( netuser.displayName == targname ) then rust.Notice( netuser, 'You cannot whisper to yourself!' ) return end
    local b, targuser = rust.FindNetUsersByName( targname )
    if ( not b ) then
        if( targuser == 0 ) then
            rust.Notice( netuser, 'No user found with the name: ' .. util.QuoteSafe( targname ) )
        else
            rust.Notice( netuser, 'Multiple users found with the name: ' .. util.QuoteSafe( targname ) )
        end
        return end
    -- Get guildtag
    local tag = self:getGuildTag( netuser )
    local displayname = netuser.displayName .. ' [whispers]'
    if ( tag ) then displayname = tag .. displayname end
    -- Generating msg
    local i = 2
    local msg = ''
    while ( i <= #args ) do
        msg = msg .. ' ' .. args[i]
        i = i + 1
    end
    -- Checking msg for language
    local tempstring = string.lower( msg )
    for k, v in ipairs( self.Config.settings.censor.chat ) do
        local found = string.find( tempstring, v )
        if ( found ) then
            rust.Notice( netuser, 'Dont swear!' )
            return
        end
    end
    -- Send message
    rust.SendChatToUser( targuser, displayname, tostring( msg ))
    rust.Notice( netuser, 'Message send!' )
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:findIDByName
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:findIDByName( name )
    for k,v in pairs( self.User ) do
        if ( v.name == name ) then return k end
    end
    return false
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:cmdMail
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:cmdMail( netuser, cmd ,args )
    if( not args[1] ) then                              -- /mail        to check your inbox
        local netuserID = rust.GetUserID( netuser )
        if( not self.User[ netuserID ].mail ) then rust.SendChatToUser( netuser, 'Mail', 'You\'ve no new mail' ) return end
        rust.SendChatToUser( netuser, ' ', ' ')
        rust.SendChatToUser( netuser, 'Mail', 'Inbox from: ' .. util.QuoteSafe(netuser.displayName ))
        for k, v in pairs( self.User[ netuserID ].mail ) do
            if( not self.User[ netuserID ].mail[ k ].read ) then
                rust.SendChatToUser( netuser, 'Mail', '[ ' .. tostring( k ) .. ' ] | [ NEW ] Mail from: ' .. v.from)
            else
                rust.SendChatToUser( netuser, 'Mail', '[ ' .. tostring( k ) .. ' ] | Mail from: ' .. v.from)
            end
        end
        return end
    local action = string.lower( tostring( args[1] ))
    if( action == 'send' ) then                         -- /mail send 'name' msg
        if(( not args[2] ) or ( not args[3] )) then
            rust.SendChatToUser( netuser, 'Mail', '/mail send \'name\' message ' )
            return end
        -- Player check
        -- if( netuser.displayName == tostring( args[2] ) ) then rust.Notice( netuser, 'You cannot send mail to yourself!' ) return end
        local targid = self:findIDByName( tostring( args[2] ))
        if( not targid ) then rust.Notice( netuser, 'No player with the name: ' .. tostring( args[2]) .. ' found in the database.' ) return end
        -- Get guild

        local b, canbuy = api.Call('ce', 'canBuy', netuser, 0,0,5 )
        if( not canbuy ) then rust.Notice( netuser, ' Not enough copper! 5 copper required! ') return end
        api.Call( 'ce', 'RemoveBalance', netuser, 0,0,5 )

        local guild = self:getGuild( netuser )
        -- Generating msg
        local i = 3
        local msg = ''
        while ( i <= #args ) do
            msg = msg .. ' ' .. args[i]
            i = i + 1
        end
        -- Checking msg for language
        local tempstring = string.lower( msg )
        for k, v in ipairs( self.Config.settings.censor.chat ) do
            local found = string.find( tempstring, v )
            if ( found ) then
                rust.Notice( netuser, 'Dont swear!' )
                return
            end
        end
        -- get date and time / convert to datetime
        local date = System.DateTime.Now:ToString(self.Config.dateformat)
        -- send mail
        if( guild ) then self:sendMail( targid, netuser.displayName, date, msg, guild ) else self:sendMail( targid, netuser.displayName, datetime, msg ) end
        rust.Notice( netuser, 'Mail send to ' .. tostring( args[2] ))
    elseif( action == 'read' ) then                             -- /mail read [id]          Read a mail
        if( not args[2] ) then rust.SendChatToUser( netuser, 'Mail', '/mail read [id]' ) return end
        local netuserID = rust.GetUserID( netuser )
        local ID = tostring( args[2] )
        if(( not self.User[ netuserID ].mail ) or ( not self.User[ netuserID ].mail[ ID ] )) then rust.Notice( netuser, 'Mail ID not found! ID: ' .. ID ) return end
        local mail = self.User[ netuserID ].mail[ ID ]
        rust.SendChatToUser( netuser, ' ', ' ')
        rust.SendChatToUser( netuser, 'Mail', 'From        : ' .. mail.from  )
        if( mail.guild ) then rust.SendChatToUser( netuser, 'Mail', 'Guild         : ' .. mail.guild  ) end
        rust.SendChatToUser( netuser, 'Mail', 'Date         : ' .. mail.date  )
        rust.SendChatToUser( netuser, 'Mail', 'Message :' .. mail.msg)
        self.User[ netuserID ].mail[ ID ].read = true
    elseif( action == 'del' ) then                              -- /mail del [id]           Delete specific message
        if( not args[2] ) then rust.SendChatToUser( netuser, 'Mail', '/mail del [id]' ) return end
        local ID = tostring( args[2] )
        local netuserID = rust.GetUserID( netuser )
        if(( not self.User[ netuserID ].mail ) or ( not self.User[ netuserID ].mail[ ID ] )) then rust.Notice( netuser, 'Mail ID not found! ID: ' .. ID ) return end
        self.User[ netuserID ].mail[ID] = nil
        local count = self:count( self.User[ netuserID ].mail )
        if ( count <= 0 ) then self.User[ netuserID ].mail = nil end
        rust.Notice( netuser, 'Mail ID ' .. ID .. ' succesfully deleted!' )
        self:UserSave()
    elseif( action == 'clear' ) then                            -- /mail clear              Clears whole inbox
        local netuserID = rust.GetUserID( netuser )
        if( self.User[ netuserID ].mail ) then
            self.User[ netuserID ].mail = nil
            rust.Notice( netuser, 'Mail cleared!' )
        else
            rust.Notice( netuser, 'No mail found!' )
        end
    elseif( action == 'help' ) then
        rust.SendChatToUser(netuser,' ','\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
        rust.SendChatToUser(netuser,' ','█\n█')
        rust.SendChatToUser( netuser, self.sysname,'█ The mail system in carbon is easy to use.' .. '\n█' )
        rust.SendChatToUser( netuser, self.sysname,'█ You\'re able to send mails to offline and online players.' .. '\n█' )
        rust.SendChatToUser( netuser, self.sysname,'█ /mail to check your mail. It shows unread mails with a [NEW] infront of them' .. '\n█' )
        rust.SendChatToUser( netuser, self.sysname,'█ /mail read ID to read the mail. This includes the sender, guild and the send date.' .. '\n█' )
        rust.SendChatToUser( netuser, self.sysname,'█ /mail del ID to delete a single mail from your inbox.' .. '\n█' )
        rust.SendChatToUser( netuser, self.sysname,'█ /mail clear to delete all your mails.' .. '\n█' )
        rust.SendChatToUser( netuser, self.sysname,'█ The id ID shown infromt of the mail when you check your inbox with /mail.' .. '\n█' )
        rust.SendChatToUser(netuser,' ','█\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
        rust.SendChatToUser( netuser, ' ', ' ' )
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:sendMail
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:sendMail( toplayerID, fromplayername, date, msg, guild )
    local mail = {}
    mail.from = util.QuoteSafe( fromplayername )
    mail.date = date
    mail.msg = msg
    mail.read = false
    if ( guild ) then mail.guild = guild end
    -- get mail unique mail id
    if( not self.User[ toplayerID ].mail ) then self.User[ toplayerID ].mail = {} end
    local i = 0
    while ( self.User[ toplayerID ].mail[ tostring( i ) ]) do
        i = i + 1
    end
    self.User[ toplayerID ].mail[tostring( i )] = mail
    -- If online, send inventory notice.
    local name = self.User[ toplayerID ].name
    local b, netuser = rust.FindNetUsersByName( name )
    if ( b ) then rust.InventoryNotice( netuser, 'New mail from: ' .. util.QuoteSafe( fromplayername )) end
    -- Save
    self:UserSave()
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:getGuildTag
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:getGuildTag( netuser )
    local guild = self:getGuild( netuser )
    if ( guild ) then
        local data = self:getGuildData( guild )
        local tag = data.tag
        return tag
    end
    return false
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:Guilds commands
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:cmdGuilds( netuser, cmd, args )
    if( not args[1] ) then
        rust.SendChatToUser(netuser,self.sysname,'\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
        rust.SendChatToUser(netuser,self.sysname,'█\n█')
        rust.SendChatToUser( netuser, self.sysname, tostring('█ The Carbon Project [ Version ' .. tostring(self.Version) .. ' ]' .. '\n█' ))
        rust.SendChatToUser( netuser, self.sysname, tostring('█ Copyright (c) 2014 Tempus Forge. All rights reserved.' .. '\n█' ))
        rust.SendChatToUser( netuser, ' ', '█ ' .. '\n█')
        rust.SendChatToUser( netuser, self.sysname, tostring( '█ /g help' .. '\n█' ))
        rust.SendChatToUser( netuser, self.sysname, tostring( '█ For more information on a specific command, type help command-name' .. '\n█' ))
        rust.SendChatToUser( netuser, self.sysname, tostring( '█ create              Creates guild' .. '\n█' ))
        local guild = self:getGuild( netuser )
        if not guild then
            rust.SendChatToUser( netuser, ' ', '█  ' .. '\n█')
            rust.SendChatToUser( netuser, self.sysname, tostring( '█ To create a guild you need a level of 10 or higher.' .. '\n█' ))
            rust.SendChatToUser( netuser, self.sysname, tostring( '█ The cost to create a guild is 25 Silver.' .. '\n█' ))
            rust.SendChatToUser(netuser,self.sysname,'█\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
            rust.SendChatToUser( netuser, self.sysname, tostring('                      Copyright (c) 2014 Tempus Forge. All rights reserved.' ))
            return end
        rust.SendChatToUser( netuser, self.sysname, tostring( '█ delete               Deletes guild' .. '\n█' ))
        rust.SendChatToUser( netuser, self.sysname, tostring( '█ info                   Displays guild\'s information that you\'re currently in.' .. '\n█' ))
        rust.SendChatToUser( netuser, self.sysname, tostring( '█ stats                  Display global statistics of the guild.' .. '\n█' ))
        rust.SendChatToUser( netuser, self.sysname, tostring( '█ invite                Invite a player to your guild.' .. '\n█' ))
        rust.SendChatToUser( netuser, self.sysname, tostring( '█ kick                  Kicks a player from your guild.' .. '\n█' ))
        rust.SendChatToUser( netuser, self.sysname, tostring( '█ war                    Engage in a war with another guild.' .. '\n█' ))
        rust.SendChatToUser( netuser, self.sysname, tostring( '█ rank                  View/assign ranks to your guild members' .. '\n█' ))
        rust.SendChatToUser(netuser,self.sysname,'█\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
        rust.SendChatToUser( netuser, self.sysname, tostring('                          The Carbon Project™ 2014 Tempus Forge ©' ))
        return end
    local action = tostring( args[1] ):lower()
    if ( action == 'create') then
        -- /g create 'Guild Name' 'Guild Tag'
        if(( args[2] ) and ( args[3] )) then
            local lvl = tonumber( self:getLvl( netuser ) )
            -- if( not ( lvl >= 10 )) then rust.Notice( netuser, 'level 10 required to create your own guild!' ) return end
            local userID = rust.GetUserID( netuser )
            if( self.User[ userID ].guild ) then rust.Notice( netuser, 'You\'re already in a guild!' ) return end
            local name = tostring( args[2] )
            local tag = tostring( args[3] )
            tag = string.upper( tag )
            -- Tag/name language check.
            if( table.containsval( self.Config.settings.censor.tag, tag ) ) then rust.Notice( netuser, 'Can not compute. Error code number B' ) return end
            for k, v in ipairs( self.Config.settings.censor.chat ) do
                local found = string.find( name, v )
                if ( found ) then
                    rust.Notice( netuser, 'Can not compute. Error code number B' )
                    return false
                end
            end
            for k, v in ipairs( self.Config.settings.censor.tag ) do
                local found = string.find( name, v )
                if ( found ) then
                    rust.Notice( netuser, 'Can not compute. Error code number B' )
                    return false
                end
            end
            -- Tag/name length check.
            if( string.len( tag ) > 3 ) then rust.Notice( netuser, 'Guild tag is too long! Maximum of 3 characters allowed' ) return end
            if( string.len( name ) > 15 ) then rust.Notice( netuser, 'Guild name is too long! Maximum of 15 characters allowed' ) return end
            self:CreateGuild( netuser, name, tag )
        else
            rust.SendChatToUser( netuser, self.sysname, '/g create "Guild Name" "Guild Tag" ')
        end

    elseif ( action == 'delete') then  --[ candelete ]
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ') return end
        -- /g delete GuildTag                       -- Deletes the guild
        if( args[2] and args[3] and not args[4] ) then
            -- Delete guild
            if( guild ) then
                local tag = '[' .. tostring( args[3]) .. ']'
                local rank = self:hasRank( netuser, guild, 'Leader' )
                if( guild ~= tostring( args[2] )) or ( self.Guild[ guild ].tag ~= tag ) then rust.Notice( netuser, 'Please type your guildname and tag to delete it' ) return end
                if( self:hasAbility( netuser, guild, 'candelete' ) ) then
                    -- DELETE GUILD
                    self:delGuild( guild )
                    rust.SendChatToUser( netuser, self.sysname, 'Guild disbanned!' )
                else
                    rust.Notice( netuser, 'You\'re not the guild leader!' )
                    return
                end
            end
        else
            rust.SendChatToUser( netuser, self.sysname, '/g delete "Guild Name" "Guild Tag" ' )
        end
    elseif ( action == 'info') then
        -- /g info                                  -- Displays general Guild information
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild!' ) return end
        local data = self:getGuildData( guild )
        local chat = ( data.tag )
        rust.SendChatToUser( netuser, ' ', ' ' )
        rust.SendChatToUser(netuser,self.sysname,'\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
        rust.SendChatToUser(netuser,self.sysname,'█\n█')
        rust.SendChatToUser( netuser, chat, '█ '.. chat .. '\'s Guild Info: ' .. '\n█' )
        rust.SendChatToUser( netuser, ' ', '█  ' .. '\n█'  )
        rust.SendChatToUser( netuser, chat, '█ Guild Name    : ' .. guild .. '\n█'  )
        rust.SendChatToUser( netuser, chat, '█ Guild Tag        : ' .. data.tag .. '\n█'  )
        rust.SendChatToUser( netuser, chat, '█ Guild Level     : ' .. data.glvl .. '\n█'  )
        rust.SendChatToUser( netuser, chat, '█ Guild XP          : (' .. data.xp .. '/' .. data.xpforLVL .. ')   [' .. math.floor(data.xp / data.xpforLVL * 100) .. '%]   (+' .. data.xpforLVL - data.xp .. ')' .. '\n█' )
        rust.SendChatToUser( netuser, ' ', '█  ' .. '\n█'  )
        rust.SendChatToUser( netuser, chat, '█ Guild Leader   : ' .. self:getGuildLeader( guild ) .. '\n█' )
        rust.SendChatToUser( netuser, chat, '█ Members        : ' .. self:count( data.members ) .. '\n█' )
        if( data.interval >= 10 ) then
            rust.SendChatToUser( netuser, chat, '█ Collect/' .. data.interval .. 'h     : ' .. data.collect .. '\n█'  ) -- To make it semetrical. xD I'm anal like that.
        else
            rust.SendChatToUser( netuser, chat, '█ Collect/' .. data.interval .. 'h      : ' .. data.collect .. '\n█'  ) -- To make it semetrical. xD I'm anal like that.
        end
        rust.SendChatToUser( netuser, chat, '█ Perks               : ' .. self:sayTable( data.unlockedperks, ', ' ) .. '\n█'  )
        rust.SendChatToUser( netuser, chat, '█ Active Perks : ' .. self:sayTable( data.activeperks, ', ' ) .. '\n█'  )
        rust.SendChatToUser( netuser, chat, '█ War                   : ' .. self:sayTable( data.war, ', ' ) .. '\n█' )
        rust.SendChatToUser(netuser,self.sysname,'█\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
        rust.SendChatToUser( netuser, ' ', ' ' )
    elseif ( action == 'stats') then
        -- /g stats                                 -- Displays a lists of guild statistics
        local guild = self:getGuild( netuser )
        if( not guild ) then self.Notice( netuser, 'You\'re not in a guild!' ) return end
        local data = self:getGuildData( guild )
        local chat = ( data.tag .. ' ' .. guild )
        rust.SendChatToUser( netuser, ' ', ' ' )
        rust.SendChatToUser(netuser,self.sysname,'\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
        rust.SendChatToUser(netuser,self.sysname,'█\n█')
        rust.SendChatToUser( netuser, self.sysname,'█ COMING SOON!' .. '\n█' )
        rust.SendChatToUser(netuser,self.sysname,'█\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
        rust.SendChatToUser( netuser, ' ', ' ' )
        -- rust.SendChatToUser( netuser, chat, chat .. ''s Guild statistics:' )
        -- rust.SendChatToUser( netuser, chat, '' )
        -- rust.SendChatToUser( netuser, chat, '' )

    elseif ( action == 'invite') then  --                                                  [ caninvite ]
        -- /g invite 'name'                                                 -- Invite a player to the guild
        if( not args[2] ) then rust.Notice( netuser, '/g invite "name" ' ) return end
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
        if( self:hasAbility( netuser, guild, 'caninvite' ) ) then
            local targname = tostring( args[ 2 ] )
            local b, targuser = rust.FindNetUsersByName( targname )
            if ( not b ) then
                if( targuser == 0 ) then
                    rust.Notice( netuser, 'No user found with the name: ' .. util.QuoteSafe( targname ) )
                else
                    rust.Notice( netuser, 'Multiple users found with the name: ' .. util.QuoteSafe( targname ) )
                end
                return end
            local targuserID = rust.GetUserID( targuser )
            local members = self:getGuildMembers( guild )
            print (tostring( members ))
            -- if( self.Guild[ guild].members[ targuserID ] ) then rust.Notice( netuser, tostring( targname ) .. ' is already in ' .. guild ) return end
            if( self.Guild.temp[ targuserID ] ) then rust.Notice( netuser, targname .. ' is alrady invited!' ) return end
            self.Guild.temp[ targuserID ] = guild
            timer.Once( 60, function()
                if( self.Guild.temp[ targuserID ]) then
                    rust.SendChatToUser(targuser, self.sysname, 'Invitation to ' .. guild .. ' expires in 60 seconds' )
                    timer.Once( 60, function()
                        if( self.Guild.temp[ targuserID ]) then
                            rust.SendChatToUser( targuser, self.sysname, 'Invitation to ' .. guild .. ' expired.' )
                            self.Guild.temp[ targuserID ] = nil
                        end
                    end)
                end
            end)
            rust.Notice( targuser, 'You\'ve been invited to ' .. guild .. '. /g accept to join the guild.', 15)
            rust.Notice( netuser, 'You\'ve invited ' .. targname .. ' to ' .. guild )
        else
            rust.Notice( netuser, 'You\'re not allowed to invite players to the guild!' )
        end
    elseif ( action == 'accept') then
        -- /g accept
        local netuserID = rust.GetUserID( netuser )
        if( self.Guild.temp[ netuserID ] ) then
            local guild = self.Guild.temp[ netuserID ]
            local entry = {}
            entry.name = netuser.displayName
            entry.rank = 'Member'
            entry.moncon = 0
            entry.xpcon = 0
            self.Guild[ guild ].members[ netuserID ] = entry
            self.User[ netuserID ][ 'guild' ] = guild
            self:sendGuildMsg( guild, netuser.displayName, 'has joined the guild! =)' )
            self.Guild.temp[ netuserID ] = nil
            self:UserSave()
            self:GuildSave()
        end
    elseif ( action == 'leave') then
        -- /g leave guildtag
        if( not args[2] ) then rust.Notice( netuser, '/g leave [guildtag] ' ) return end
        local guild = self:getGuild( netuser )
        print( guild )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild!') return end
        local netuserID = rust.GetUserID( netuser )
        self.Guild[ guild ].members[ netuserID ] = nil
        self.User[ netuserID ].guild = nil
        self:sendGuildMsg( guild, netuser.displayName, 'has left the guild! =(' )
        local count = self:count( self.Guild[ guild ].members )
        if ( count == 0 ) then self.Guild[ guild ] = nil rust.Notice( netuser, guild .. ' has been disbanned!' ) end
        self:GuildSave()
        self:UserSave()
    elseif ( action == 'kick') then                 --                                                  [ cankick ]
        -- /g kick name                             -- Kick a player from the guild
        if( not args[2] ) then rust.Notice( netuser, '/g kick "name" ' )return end
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
        if( not self:hasAbility( netuser, guild, 'cankick' ) ) then rust.Notice(netuser, 'You\'re not permitted to kick a player from the guild.' ) return end
        local targname = util.QuoteSafe( args[2] )
        if( netuser.displayName == targname ) then rust.Notice( netuser, 'You cannot kick yourself...' ) return end
        local targuserID = false
        for k, v in pairs( self.Guild[ guild ].members ) do
            if( v.name:lower() == targname:lower() ) then targuserID = k return end
        end
        if( not targuserID ) then rust.Notice( netuser, 'player ' .. targname .. ' is not a member of ' .. guild .. '.') return end
        local date = System.DateTime.Now:ToString(self.Config.dateformat)
        self:sendMail( targuserID, netuser.displayName, date, 'You\'ve been kicked from the guild ' .. guild, guild )
        self.Guild[ guild ].members[ targuserID ] = nil
        self.User[ targuserID ].guild = nil
        self:UserSave()
        self:GuildSave()
    elseif ( action == 'war') then                  --                                                  [ canwar ]
        -- /g war guildtag                          -- Engage a war with another guild / other guild will be notified.
        local guild = self:getGuild( netuser )
        if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
        if( not self:hasAbility( netuser, guild, 'canwar' ) ) then rust.Notice(netuser, 'You\'re not permitted to kick a player from the guild.' ) return end
        local targtag = '['..string.upper( tostring( args[2] ))..']'
        for k,v in pairs( self.Guild ) do
            if( v.tag == targtag )then
                self:engageWar( guild, k, netuser )
                return
            end
        end
        rust.Notice( netuser, 'Tag does not exist.' )
    elseif ( action == 'rank' ) then                            -- show rank. if [ canrank ] then show options too.
        if( not args[2] ) then
            local guild = self:getGuild( netuser )
            if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
            local rank = self:getRank( netuser, guild )
            rust.SendChatToUser(netuser,self.sysname,'\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
            rust.SendChatToUser(netuser,self.sysname,'█\n█')
            rust.SendChatToUser( netuser, guild, '█ Your current rank status: ' .. tostring( rank ) .. '\n█')
            rust.SendChatToUser( netuser, guild, '█ /g rank list shows the power of each rank.' .. '\n█')
            if( self:hasAbility( netuser, guild, 'canrank' ) ) then
                rust.SendChatToUser( netuser, guild, '█ /g rank [list][give][add][edit].' .. '\n█' )
                rust.SendChatToUser( netuser, guild, '█ [list]  | List all the available ranks and their abilites ' .. '\n█' )
                rust.SendChatToUser( netuser, guild, '█ [give]  | Assign a rank to a guild member. ' .. '\n█' )
                rust.SendChatToUser( netuser, guild, '█ [Add]    | Create a new rank for the guild.' .. '\n█' )
                rust.SendChatToUser( netuser, guild, '█ [edit]  | Change rank settings.' .. '\n█' )
                rust.SendChatToUser( netuser, guild, '█  ' .. '\n█' )
            end
            rust.SendChatToUser(netuser,self.sysname,'█\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
            rust.SendChatToUser( netuser, ' ', ' ' )
            return
        end
        if( args[2] ) then args[2] = tostring(args[2]):lower() end
        -------------------------------------
        if( args[2] == 'list' ) then                            -- /g rank list | shows list of ranks + abilities
            local guild = self:getGuild( netuser )
            if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
            local msg = {}
            for k, v in pairs( self.Guild[guild].ranks) do
                local count = self:count( self.Guild[guild].ranks[k]) +1
                while msg[ tostring(count) ] do count = count + 0.1 end
                msg[tostring( count )] = 'Rank: ' .. k .. ' Abilities: ' .. table.returnvalues( self.Guild[guild].ranks[k] )
            end
            rust.SendChatToUser(netuser,self.sysname,'\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
            rust.SendChatToUser(netuser,self.sysname,'█\n█')
            for i = 8, 1, -.1 do
                if msg[tostring(i)] then
                    rust.SendChatToUser( netuser, guild,'█ ' .. msg[tostring(i)] .. '\n█' )
                end
            end
            rust.SendChatToUser(netuser,self.sysname,'█\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
            rust.SendChatToUser( netuser, ' ', ' ' )
        elseif( args[2] == 'give' ) then                        -- /g rank give 'rank' name | Add a rank to a member        [ canrank ]
            local guild = self:getGuild( netuser )
            if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
            if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to give ranks to a player.' ) return end
            if( args[3] and args[4] ) then
                local netuserID = rust.GetUserID( netuser )
                local targname = tostring( args[ 4 ] )
                local b, targuser = rust.FindNetUsersByName( targname )
                if ( not b ) then
                    if( targuser == 0 ) then
                        rust.Notice( netuser, 'No user found with the name: ' .. util.QuoteSafe( targname ) )
                    else
                        rust.Notice( netuser, 'Multiple users found with the name: ' .. util.QuoteSafe( targname ) )
                    end
                    return end
                local targuserID = rust.GetUserID( targuser )
                if( not self.Guild[ guild ].members[targuserID] ) then rust.Notice( netuser, targname .. ' is not in your guild!' ) return end
                if( not self.Guild[ guild ].ranks[ tostring( args[3]) ] ) then rust.Notice( netuser, tostring( args[3] .. ' is not an available rank! ')) return end
                if( not self.Guild[ guild ].members[targuserID].rank['Leader']) then rust.Notice( netuser, 'You\re not able to change the leaders rank! ') return end
                if(( tostringargs[3] == 'Leader' ) and( not self.Guild[ guild ].members[ netuserID ].rank == 'Leader' )) then rust.Notice( netuser, 'You cannot give anyone the Leader rank!') return end
                self.Guild[ guild ].members[targuserID].rank = tostring( args[3] )
                rust.Notice(netuser, targname .. ' is now a ' .. tostring( args[3] ))
                self:GuildSave()
            end
        elseif( args[2] == 'add' ) then                         -- /g rank add 'rank' | Create a new custom rank            [ canrank ]
            local guild = self:getGuild( netuser )
            if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
            if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to add ranks.' ) return end
            if( not args[3] ) then rust.SendChatToUser( netuser, '/g rank add "rankname" ') return end
            if( self.Guild[ guild ].ranks[ tostring(args[3]) ]) then rust.Notice( netuser, args[3] .. ' already exist!') return end
            self.Guild[ guild ].ranks[tostring(args[3])] = {}
            rust.SendChatToUser( netuser, 'Added new rank: ' .. args[3] )
            self:GuildSave()
        elseif( args[2] == 'del' ) then                        -- /g rank del 'rank' | delete a rank           [ canrank ]
            if(( args[3] ) and ( not args[4] )) then
                local guild = self:getGuild( netuser )
                if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
                if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to add ranks.' ) return end
                if ( args[3] == "Assasin" ) then rust.Notice( netuser, 'You cannot delete rank Assasin!' ) return end
                if ( args[3] == "Leader" ) then rust.Notice( netuser, 'You cannot delete rank Leader!' ) return end
                if( self.Guild[ guild ].ranks[tostring(args[3])]) then
                    self.Guild[ guild ].ranks[tostring(args[3])] = nil
                    rust.Notice( netuser, 'Rank ' .. args[3] .. ' has been deleted! ')
                    return
                else
                    rust.Notice( netuser, 'Rank ' .. args[3] .. ' does not exist!' )
                    return
                end
            else
                rust.SendChatToUser( netuser, '/g rank del "rank" ' )
            end
        elseif( args[2] == 'edit' ) then                        -- /g rank edit 'rank' | Create a new custom rank           [ canrank ]
            local guild = self:getGuild( netuser )
            if( not guild ) then rust.Notice( netuser, 'You\'re not in a guild! ' ) return end
            if( not self:hasAbility( netuser, guild, 'canrank' ) ) then rust.Notice(netuser, 'You\'re not permitted to edit ranks.' ) return end
            if( not args[3] and not args[4] and not args[5] ) then
                self:sendTXT( netuser, guild, self.txt.guild.rankinfo )
            elseif( args[3] and args[4] and args[5] ) then
                if ( args[3] == "Assasin" ) then rust.Notice( netuser, 'You cannot edit rank Assasin!' ) return end
                if ( not self.Guild[guild].ranks[tostring(args[3])] ) then rust.Notice( netuser, 'Rank: ' .. tostring(args[3]).. ' doesn\'t exist!' ) return end
                if ( tonumber(args[4]) > 7 ) then rust.Notice( netuser, 'This rank abillity is not found. Chooose between 1 - 6' ) return end
                if(( args[5] == 'true' ) or ( args[5] == 'false' )) then
                    local tbl = {'candelete','caninvite','cankick','canvault','canwar','canrank' }
                    local ability = tbl[ tonumber( args[4] )]
                    if( args[5] == 'true' ) then
                        local contains = table.containsval( self.Guild[ guild ].ranks[tostring(args[3])])
                        if( contains ) then rust.Notice( netuser, tostring(args[3]) .. ' already has ' .. ability ) return end
                        table.insert( self.Guild[ guild ].ranks[tostring(args[3])], ability )
                        rust.Notice( netuser, ability .. ' has been added to ' .. tostring( args[3] ))
                    elseif( args[5] == 'false' ) then
                        local contains = table.containsval( self.Guild[ guild ].ranks[tostring(args[3])], ability )
                        if( not contains ) then rust.Notice( netuser, tostring(args[3]) .. ' doesn\'t have ' .. ability ) return end
                        for i,v in pairs( self.Guild[ guild ].ranks[tostring(args[3])] ) do
                            if( v == ability ) then
                                table.remove( self.Guild[ guild ].ranks[tostring(args[3])], i )
                                rust.Notice( netuser, ability .. ' has been taken from ' .. tostring( args[3] ))
                            end
                        end
                    end
                    self:GuildSave()
                else
                    self:sendTXT( netuser, guild, self.txt.guild.rankinfo )
                end
            else
                rust.SendChatToUser( netuser, '/g rank edit "rankname" [ID] true/false || /g rank ;For more information')
            end
        else
            if( self:hasAbility( netuser, guild, 'canrank' ) ) then rust.SendChatToUser( netuser, guild, '/g rank [list][give][take][add][edit]' )
            else rust.SendChatToUser( netuser, '/g rank [list]' ) end
        end
        -- elseif ( action == 'perks' ) then -- [ canvault ]


        -- elseif ( action == 'vault' ) then -- [ canvault ]
        -- /g vault buy                             -- Buy a vault

        -- /g vault add                             -- Add items/money to the guild vault

        -- /g vault withdraw                        -- withdraw items/money from the guild vault

        -- /g vault upgrade                         -- Upgrade your vault to the next lvl

    elseif ( action == 'help' ) then
        local guild = self:getGuild( netuser )
        if( not guild ) then guild = self.sysname end
        if not args[2] then
            self:sendTXT( netuser, guild, self.txt.guild.help )
            return
        end
        local action2 = tostring(args[2]:lower())
        if( action2 == 'create' ) then
            self:sendTXT( netuser, guild, self.txt.guild.create )
        elseif( action2 == 'delete' ) then
            self:sendTXT( netuser, guild, self.txt.guild.delete )
        elseif( action2 == 'info' ) then
            self:sendTXT( netuser, guild, self.txt.guild.info )
        elseif( action2 == 'stats' ) then
            self:sendTXT( netuser, guild, self.txt.guild.stats )
        elseif( action2 == 'invite' ) then
            self:sendTXT( netuser, guild, self.txt.guild.invite )
        elseif( action2 == 'kick' ) then
            self:sendTXT( netuser, guild, self.txt.guild.kick )
        elseif( action2 == 'war' ) then
            self:sendTXT( netuser, guild, self.txt.guild.war )
        elseif( action2 == 'rank' ) then
            self:sendTXT( netuser, guild, self.txt.guild.rank )
        elseif( action2 == 'ability' ) then
            self:sendTXT( netuser, guild, self.txt.guild.ability )
        elseif( action2 == 'vault' ) then
            self:sendTXT( netuser, guild, self.txt.guild.vault )
        elseif( action2 == 'calls' ) then
            self:sendTXT( netuser, guild, self.txt.guild.calls )
        elseif( action2 == 'collection' ) then
            self:sendTXT( netuser, guild, self.txt.guild.collection )
        elseif( action2 == 'assassin' ) then
            self:sendTXT( netuser, guild, self.txt.guild.assassin )
        elseif( action2 == '' ) then
        else
            rust.SendChatToUser( netuser, self.sysname, 'Please type /g create | delete | info | stats | invite | kick | war | rank | vault' )
        end
    else
        rust.SendChatToUser( netuser, self.sysname, 'Invalid command! Please type /g to view all available guild commands.' )
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:engageWar
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:engageWar( guild, guild2, netuser )
    if( (guild) and (guild2) ) then
        table.insert( self.Guild[ guild ].war, guild2 )
        table.insert( self.Guild[ guild2 ].war, guild1 )
        self:sendGuildMsg( guild, 'WAR', guild .. ' is now at war with ' .. guild2 .. '!' )
        self:sendGuildMsg( guild2, 'WAR', guild2 .. ' is now at war with ' .. guild .. '!' )
    else
        rust.Notice( netuser, 'Invalid input.' )
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:CreateGuild
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:CreateGuild( netuser, name, tag )
    if( self.Guild[ name ] ) then rust.Notice( netuser, 'This guild name is already used.' ) return end
    for k, v in pairs( self.Guild ) do
        if( v.tag == ('[' .. tag .. ']') ) then rust.Notice( netuser, 'This guild tag is already used!' ) return end
    end
    -- Check if player has enough money.
    local b, bal = api.Call( 'ce', 'canBuy', netuser, 0,25,0 )
    if ( bal ) then
        api.Call( 'ce', 'RemoveBalance', netuser, 0,25,0 )
    else
        rust.Notice( netuser, 'You do not have enough money! 25 Silver is required' )
        return
    end
    local netuserID = rust.GetUserID( netuser )
    local entry = {}
    entry.tag = '[' .. tag .. ']'                                                                                   -- Guild Tag
    entry.glvl = 1                                                                                                  -- Guild Level
    entry.xp = 0                                                                                                    -- Experience
    entry.xpforLVL = math.ceil((((2*2)+2)/self.Config.settings.glvlmodifier*100-(2*100)))                           -- xpforLVL
    entry.ranks = { ['Leader']={'candelete','caninvite','cankick','canvault','canwar','canrank'},                   -- Create default Ranks
        ['Co-Leader']={'caninvite','cankick','canvault','canwar'},
        ['War-Leader']={'canwar'},
        ['Quartermaster']={'canvault'},
        ['Assasin']={},
        ['Member']={}
    }
    entry.members = {}                                                                                              -- Members
    entry.members[ netuserID ] = {}
    entry.members[ netuserID ][ 'name' ] = netuser.displayName
    entry.members[ netuserID ][ 'rank' ] = 'Leader'
    entry.members[ netuserID ][ 'moncon' ] = 0
    entry.members[ netuserID ][ 'xpcon' ] = 0
    entry.war = {}                                                                                                  -- Guild is at war with:
    entry.collect = 0                                                                                               -- Collects money from members
    entry.gocollect = 0                                                                                             -- time left for next collection
    entry.interval = 0                                                                                              -- Amount of hours between each collection.
    entry.unlockedperks = {}                                                                                        -- Perks are unlocked at certain Guild lvls ( Max: 10 )
    entry.activeperks = {}                                                                                          -- Perks are unlocked at certain Guild lvls ( Max: 10 )
    timer.Once( 1, function()
        rust.SendChatToUser( netuser, self.sysname, 'Creating Guild...' )
        timer.Once( 3, function()rust.SendChatToUser( netuser, self.sysname, 'Creating guild nameplates...' ) end )
        timer.Once( 6, function()rust.SendChatToUser( netuser, tostring( name ), 'Integrating tag...' ) end )
        timer.Once( 9, function()rust.SendChatToUser( netuser, tostring( '[' .. tag .. '] ' .. name ), 'Creating ' .. tostring( name ) .. ' user interface...' ) end )
        timer.Once( 16, function()rust.SendChatToUser( netuser, tostring( '[' .. tag .. '] ' .. name ), 'Feeding the chickens...' ) end )
        timer.Once( 18, function()rust.SendChatToUser( netuser, tostring( '[' .. tag .. '] ' .. name ), 'Your guild has been created!' ) end )
        timer.Once( 19, function()
            self.Guild[ name ] = entry                                                                                  -- Add complete table to Guilds file
            self.User[ netuserID ][ 'guild' ] = name                                                                    -- Add guild to userdata.
            self:UserSave()
            self:GuildSave() end)
    end )
end

--[[
    entry.vault = {}                                                                                                -- Vault
    entry.vault[ 'money' ][ 'gp' ] = 0                                                                              -- Gold in vault
    entry.vault[ 'money' ][ 'sp' ] = 0                                                                              -- Silver in vault
    entry.vault[ 'money' ][ 'cp' ] = 0                                                                              -- Copper in vault
    entry.vault[ 'weapons' ] = {}                                                                                   -- Weapons in vault
    entry.vault[ 'weapons' ] = {}                                                                                   -- Armor in vault
    entry.vault[ 'materials' ] = {}                                                                                 -- Metarials in vault
]]--

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:sendTXT
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:sendTXT( netuser, chatname, data )
    if( not data ) then print( 'Data was not found!' ) rust.Notice( netuser, 'txt file not found! please report this to a GM!' ) return end
    rust.SendChatToUser(netuser,' ','\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
    rust.SendChatToUser(netuser,' ','█\n█')
    local v = false
    if ( data.header ) then rust.SendChatToUser( netuser, tostring( chatname ), '█  ' .. tostring( data.header ) .. '\n█' ) v = true end
    if ( data.subheader ) then rust.SendChatToUser( netuser, tostring( chatname ), '█  ' .. tostring( data.subheader ) .. '\n█' ) v = true end
    if ( v ) then rust.SendChatToUser( netuser, ' ', '█\n█' ) end
    local i = 1
    while ( data.txt[tostring(i)] ) do
        rust.SendChatToUser( netuser, chatname,'█  ' .. data.txt[tostring(i)] .. '\n█')
        i = i + 1
    end
    rust.SendChatToUser(netuser,' ','█\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:getGuildMembers
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:getGuildMembers( guild )
    local members = self.Guild[ guild ].members
    return members
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:sendGuildMsg
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:sendGuildMsg( guild, name, msg )
    local guilddata = self:getGuildData( guild )
    for k,v in pairs( self.Guild[ guild ].members ) do
        local b, targuser = rust.FindNetUsersByName( v.name )
        if( b ) then rust.SendChatToUser( targuser, guilddata.tag .. ' ' ..v.name, msg ) end
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:delGuild
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:delGuild( guild )
    -- Delete guild from userdata.
    for k, v in pairs( self.Guild[ guild ].members ) do
        self.User[ k ].guild = nil
    end
    self:UserSave()
    -- Delete guild from self.Guild
    self.Guild[ guild ] = nil
    self:GuildSave()
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:getGuild
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:getGuild( netuser )
    local userID = rust.GetUserID( netuser )
    local guild = false
    if( self.User[ userID ].guild ) then guild = self.User[ userID ].guild end
    return guild
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:getGuildData
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:getGuildData( guild )
    local data = self.Guild[ guild ]
    if( not data ) then return false end
    return data
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:getGuildLeader
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:getGuildLeader( guild )
    local data = self:getGuildData( guild )
    for k ,v in pairs( data.members ) do
        if( v.rank == 'Leader' ) then
            return v.name
        end
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:hasAbility
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:hasAbility( netuser, guild, ability )
    local rank = self:getRank( netuser, guild )
    local userID = rust.GetUserID( netuser )
    local val = table.containsval( self.Guild[ guild ].ranks[rank], ability )
    return val
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:hasRank
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:hasRank( netuser, guild, rank )
    local userID = rust.GetUserID( netuser )
    local grank = self.Guild[ guild ].members[ userID ].rank
    if ( grank == rank ) then return true else return false end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:getRank
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:getRank( netuser, guild )
    local userID = rust.GetUserID( netuser )
    local rank = self.Guild[ guild ].members[ userID ].rank
    return rank
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:isRival
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:isRival( guild1, guild2 )
    local war = table.containsval( self.Guild[ guild1 ].war, guild2)
    return war
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:hasRallyCall
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:hasRallyCall( guild )
    local Rally = table.containsval( self.Guild[ guild ].activecalls, 'rally' )
    if ( Rally ) then Rally = ( self.Config.guild.calls.rally.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.rally.requirements.glvl )) return ( Rally + 1 ) else return false end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:hasSYGCall
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:hasSYGCall( guild )
    local syg = table.containsval( self.Guild[ guild ].activecalls, 'syg' )
    if ( syg ) then syg = ( self.Config.guild.calls.rally.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.syg.requirements.glvl )) return ( 1 - syg ) else return false end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:hasCOTWCall
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:hasCOTWCall ( guild )
    local cotw = table.containsval( self.Guild[ guild ].activecalls, 'cotw' )
    if ( cotw ) then cotw = ( self.Config.guild.calls.cotw.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.cotw.requirements.glvl + 1 )) return ( cotw + 1 ) else return false end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:hasForGloryCall
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:hasForGloryCall ( guild )
    local forglory = table.containsval( self.Guild[ guild ].activecalls, 'forglory' )
    if ( forglory ) then forglory = ( self.Config.guild.calls.forglory.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.forglory.requirements.glvl + 1 )) return ( forglory + 1 ) else return false end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:SetDefaultConfig
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:SetDefaultConfig()
    self.Config = {
        ['npc']={
            ['ZombieNPC_SLOW']={['id']='ZombieNPC_SLOW',['ai']='ZombieController',['name']='Slow Zombie',['xp']=45,['dmg']=.25,['sta']=10,['str']=10},
            ['ZombieNPC_FAST']={['id']='ZombieNPC_FAST',['ai']='ZombieControlller',['name']='Fast Zombie',['xp']=40,['dmg']=.25,['sta']=9,['str']=9},
            ['ZombieNPC']={['id']='ZombieNPC',['ai']='ZombieController',['name']='Zombie',['xp']=35,['dmg']=.25,['sta']=8,['str']=8},
            ['MutantBear']={['id']='MutantBear',['ai']='BearAI',['name']='Mutant Bear',['xp']=30,['dmg']=.25,['sta']=7,['str']=7},
            ['MutantWolf']={['id']='MutantWolf',['ai']='WolfAI',['name']='Mutant Wolf',['xp']=25,['dmg']=.15,['sta']=6,['str']=6},
            ['Bear']={['id']='Bear',['ai']='BearAI',['name']='Bear',['xp']=20,['dmg']=.35,['sta']=5,['str']=5},
            ['Wolf']={['id']='Wolf',['ai']='WolfAI',['name']='Wolf',['xp']=15,['dmg']=.25,['sta']=4,['str']=4},
            ['Stag_A']={['id']='Stag_A',['ai']='StagAI',['name']='Stag',['xp']=10,['dmg']=.50,['sta']=3,['str']=3},
            ['Boar_A']={['id']='Boar_A',['ai']='BoarAI',['name']='Boar',['xp']=10,['dmg']=.50,['sta']=2,['str']=2},
            ['Chicken']={['id']='Chicken',['ai']='ChickenAI',['name']='Chicken',['xp']=5,['dmg']=1,['sta']=1,['str']=1},
            ['Rabbit']={['id']='Rabbit',['ai']='RabbitAI',['name']='Rabbit',['xp']=5,['dmg']=1,['sta']=1,['str']=1},
        },
        ['weapon']={
            ['Unarmed']={['name']='Unarmed',['type']='m',['dmg']=1,['lvl']=1},
            ['Uber Hunting Bow']={['name']='Uber Hunting Bow',['type']='l',['dmg']=1,['lvl']=1},
            ['Stone Hatchet']={['name']='Stone Hatchet',['type']='m',['dmg']=1,['lvl']=1},
            ['Hatchet']={['name']='Hatchet',['type']='m',['dmg']=1,['lvl']=1},
            ['Pick Axe']={['name']='Pick Axe',['type']='m',['dmg']=1,['lvl']=1},


            ['Hand Cannon']={['name']='Hand Cannon',['type']='c',['dmg']=1,['lvl']=1},
            ['Pipe Shotgun'] ={['name']='Pipe Shotgun',['type']='c',['dmg']=1,['lvl']=1},
            ['Revolver']={['name']='Revolver',['type']='c',['dmg']=1,['lvl']=1},
            ['9mm Pistol']={['name']='9mm Pistol',['type']='c',['dmg']=1,['lvl']=3},
            ['M4']={['name']='M4',['type']='l',['dmg']=1,['lvl']=5},
            ['Bolt Action Rifle']={['name']='Bolt Action Rifle',['type']='l',['dmg']=1,['lvl']=1},
            ['Explosive Charge']={['name']='Explosive Charge',['type']='e',['dmg']=1,['lvl']=1},
            ['F1 Grenade']={['name']='F1 Grenade',['type']='e',['dmg']=1,['lvl']=1},


            ['Hunting Bow']={['name']='Hunting Bow',['type']='l',['dmg']=1,['lvl']=1},
            ['MP5A4']={['name']='MP5A4',['type']='l',['dmg']=1,['lvl']=1},
            ['P250']={['name']='P250',['type']='c',['dmg']=1,['lvl']=1},



            ['Rock']={['name']='Rock',['type']='m',['dmg']=1,['lvl']=1},
            ['Shotgun']={['name']='Shotgun',['type']='c',['dmg']=1,['lvl']=1},

            ['Uber Hatchet']={['name']='Uber Hatchet',['type']='c',['dmg']=1,['lvl']=1},
        },
        ['settings']={
            ['filename']='carbon',
            ['sysname']=' ',
            ['dppercent']=5,
            ['dppercent']=5,
            ['sleeperxppercent']=5,
            ['sleerperdppecent']=5,
            ['sleeperradius']=2,
            ['lvlmodifier']=1, --0.5=Veteran | 1=hard | 1.5=normal | 2=easy
            ['glvlmodifier']=.1,
            ['untraincost']=500, --this is the cost in copper
            ['untraincostgrowth']=.10, --the rate at which untrain cost grows floored.
            ['weaponlvlmodifier']=0.5,--0.5=Veteran | 1=hard | 1.5=normal | 2=easy
            ['xpmodifier']=1, -- multiplies values of npc xp given. (ie; 2 = 2x npc reward)
            ['censor'] = {
                ['chat']={'fuck','shit','bitch','ass'},
                ['tag']={'TIT','SEX','FU','FUK','FUC','DIK'}
            }
        },
        ['guild'] = {
            ['prices']={
                ['create']=25000
            },
            ['settings']={
                ['vault']={['req']=2,['cost']=50000 ,['slots']=30},
                ['glvlmodifier']=.1,
            },
            ['calls']={
                ['rally']={['requirements']={['cost']=30000,['glvl']=3},['mod']=.05},
                ['syg']={['requirements']={['cost']=30000,['glvl']=3,['mod']=.05},['mod']=.04},
                ['cotw']={['requirements']={['cost']=25000,['glvl']=2},['mod']=.05},
                ['forglory']={['requirements']={['cost']=25000,['glvl']=2},['mod']=.05 },
                ['kos']={['requirements']={['cost']=25000,['glvl']=2},['mod']=50}
            }
        },
        ['prof'] = {
            ['engineer']={},
            ['medic']={},
            ['carpenter']={},
            ['armorsmith']={},
            ['weaponsmith']={}
        }
    }
    self:ConfigSave()
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:OnUserChat | http://wiki.rustoxide.com/index.php?title=Hooks/OnUserConnect
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:OnUserChat(netuser, name, msg)
    if ( msg:sub( 1, 1 ) ~= '/' ) then
        local tempstring = string.lower( msg )
        for k, v in ipairs( self.Config.settings.censor.chat ) do
            local found = string.find( tempstring, v )
            if ( found ) then
                rust.Notice( netuser, 'Dont swear!' )
                return false
            end
        end
        local userID = rust.GetUserID( netuser )
        local guild = self:getGuild( netuser )
        if( guild ) then
            local data = self:getGuildData( guild )
            name = data.tag .. ' ' .. name
            rust.BroadcastChat( name, msg )
            return false
        end
    end
end

function PLUGIN:AlphaTXT( netuser )
    rust.SendChatToUser( netuser, self.sysname, tostring('The Carbon Project [ Version ' .. tostring(self.Version) .. ' ]' ))
    rust.SendChatToUser( netuser, self.sysname, tostring('  Copyright (c) 2014 Tempus Forge. All rights reserved.' ))
    rust.SendChatToUser( netuser, self.sysname, tostring('    -- to view this message again, type /alpha -- ' ))
    rust.SendChatToUser( netuser, ' ', ' ' )
    rust.SendChatToUser( netuser, self.sysname, 'Welcome to "The Carbon Project" Alpha test!' )
    rust.SendChatToUser( netuser, self.sysname, 'Carbon RPG is a game with a dynamic leveling system, Professions, Skills, Perks, Calls,' )
    rust.SendChatToUser( netuser, self.sysname, 'Guilds, Party( coming soon ), Random events( coming soon )and boss mobs( coming soon )!' )
    rust.SendChatToUser( netuser, self.sysname, 'Use /c for global information. Use /g for guild commands.' )
    rust.SendChatToUser( netuser, self.sysname, 'Take a look around, for more information visit: www.tempusforge.com' )
    rust.SendChatToUser( netuser, ' ', ' ' )
    rust.SendChatToUser( netuser, self.sysname, 'Disclaimer: This is an ALPHA test, there will be bugs, there will be crashes, ' )
    rust.SendChatToUser( netuser, self.sysname, 'there will be restarts and there will be wipes.' )
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:OnUserConnect | http://wiki.rustoxide.com/index.php?title=Hooks/OnUserConnect
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:OnUserConnect( netuser )
    self:AlphaTXT( netuser )
    if netuser.displayName:find'%W' then
        rust.SendChatToUser( netuser, ' ', ' ' )
        rust.SendChatToUser( netuser, '**ALERT**', 'Your name must be alphanumeric( numbers and letters )! Please change your name. You\'ll be kicked' )
        timer.Once(25, function() netuser:Kick( NetError.Facepunch_Kick_RCON, true ) end)
        return
    end
    local data = self:GetUserData( netuser ) -- asks for dat.
    data.name = netuser.displayName

    -- Check mail
    local netuserID = rust.GetUserID( netuser )
    if( not self.User[ netuserID ] ) then return end
    if ( self.User[ netuserID ].mail ) then
        local i = 0
        for k, v in pairs( self.User[ netuserID ].mail ) do
            if( not v.read ) then i = i + 1 end
        end
        if( i > 0 ) then rust.SendChatToUser( netuser,'/Mail', 'You\'ve got ' .. tostring( i ) .. ' unread mails!' ) end
    end
    rust.BroadcastChat( netuser.displayName .. ' has connected to the server!')
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:GetUserData
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GetUserData( netuser )
    local netuserID = rust.GetUserID( netuser )
    local data = self.User[ netuserID ] -- checks if data exist
    if (not data ) then -- if not, creates one
        data = {}
        data.id = netuserID
        data.name = netuser.displayName
        data.lvl = 1
        data.xp = 0
        data.pp = 0
        data.dp = 0
        data.ap = 0
        data.dmg = 1
        data.ut = 0 --the amount of times this user has untrained his/her attributes.
        data.attributes = {['str']=0,['agi']=0,['sta']=0,['int']=0 }
        data.buffs = {}
        data.skills = {}
        data.perks = {}
        data.stats = {['deaths']={['pvp']=0,['pve']=0},['kills']={['pvp']=0,['pve']={['total']=0}}}
        self.User[ netuserID ] = data
        self:UserSave()
    end
    return data
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- CONFIG UPDATE AND SAVE
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:ConfigSave()
    self.ConfigFile:SetText( json.encode( self.Config, { indent = true } ) )
    self.ConfigFile:Save()
    self:ConfigUpdate()
end
function PLUGIN:ConfigUpdate()
    self.ConfigFile = util.GetDatafile( 'carbon_cfg' )
    local txt = self.ConfigFile:GetText()
    self.Config = json.decode ( txt )
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- DATA UPDATE AND SAVE
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:UserSave()
    self.UserFile:SetText( json.encode( self.User, { indent = true } ) )
    self.UserFile:Save()
    self:UserUpdate()
    spamNet = {}
end
function PLUGIN:UserUpdate()
    self.UserFile = util.GetDatafile( 'carbon_usr' )
    local txt = self.UserFile:GetText()
    self.User = json.decode ( txt )
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- GUILD UPDATE AND SAVE
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GuildSave()
    self.GuildFile:SetText( json.encode( self.Guild, { indent = true } ) )
    self.GuildFile:Save()
    -- self:GuildUpdate()
end
function PLUGIN:GuildUpdate()
    self.GuildFile = util.GetDatafile( 'carbon_gld' )
    local txt = self.GuildFile:GetText()
    self.Guild = json.decode ( txt )
end

function PLUGIN:xpbar( value )
    local msg = '▐'
    for i=1, 25 do
        if( (value / 4) >= i ) then
            msg = msg .. '█'
        else
            msg = msg .. '▒'
        end
    end
    msg = msg .. '▌'
    return msg
end
function PLUGIN:medxpbar( value )
    local msg = ''
    for i=1, 20 do
        if( (value / 5) >= i ) then
            msg = msg .. '■'
        else
            msg = msg .. '□'
        end
    end
    msg = msg
    return msg
end
function PLUGIN:xpbar( value, size )
    local msg = ''
    for i=1, size do
        if( (value / (100/size)) >= i ) then
            msg = msg .. '■'
        else
            msg = msg .. '□'
        end
    end
    return msg
end
function PLUGIN:minixpbar( value )
    local msg = '▪'
    for i=1, 100 do
        if( (value / 1) >= i ) then
            msg = msg .. '▪'
        else
            msg = msg .. '▫'
        end
    end
    msg = msg .. '▪'
    return msg
end

function PLUGIN:sidexpbar( value )
    local msg = '■'
    for i=1, 10 do
        if( (value / 10) >= i ) then
            msg = msg .. '■'
        else
            msg = msg .. '□'
        end
    end
    msg = msg .. '■'
    return msg
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- GUILD DOOR ACCESS!
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- TESTING IF THIS IS A GOOD ADDITION! ( if not, wait till they fixed it )
local DeployableObjectOwnerID = util.GetFieldGetter( Rust.DeployableObject, "ownerID", true )
function PLUGIN:CanOpenDoor( netuser, door )
    -- Get and validate the deployable
    local deployable = door:GetComponent( "DeployableObject" )
    if (not deployable) then return end

    -- Get the owner ID and the user ID
    local ownerID = tostring( DeployableObjectOwnerID( deployable ) )
    local userID = rust.GetUserID( netuser )

    -- check if user is owner.
    if (ownerID == userID) then rust.Notice( netuser, 'Entered your own house! ') return true end

    -- if not get guilds
    local ownernetuser = rust.FindNetUsersByName( self.User[ ownerID ].name )
    local ownerGuild = self:getGuild( ownernetuser )
    local userGuild = self:getGuild( netuser )
    if not ( ownerGuild and userGuild ) then return end

    -- Check if in same guild
    if ( userGuild == ownerGuild ) then rust.Notice( netuser, 'Entered ' .. self.User[ ownerID ].name .. '\'s house! ') return true end
end
