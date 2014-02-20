PLUGIN.Title = "Carbon"
PLUGIN.Description = "experience. levels. skills. rewards."
PLUGIN.Version = "1.0.6a"
PLUGIN.Author = "Mischa & CareX"
--[[ SPECIAL NOTES
  02.20.2014
  Mischa:

            -redone: GuildsFile is now GuildFile : self.Guilds is now self.Guild etc..
            -redone: settings, cleaner, faster.
            -merged: guild config file with carbon_cfg
            -added: function modifyDP
            -added: function checkCrit
            -added: function staModify
            -added: function attrModify
            -added: perk system: givePerk, takePerk, perkPerk. ModifyDamage now called self:perkPerk


    CHANGELOG: 02.19.2014
 CareX:
            - Added sysname to most of the chats
            - Added delGuild
            - Redone some of the guild creations. ( check it out, you might know some funny lines to say too )
            - Added guilds to the userdata. So it's easier to search for guild, dont have to go trough everyguilds members list
            - Added self.debugr to the guild perks in ModifyDamage()
            - Redone getGuild()
            - Added me to the authors! You selfisch mofo! ( I want credits, I like fame. Give money, swag. )
            - Integrated Market.
            - self.CS = CurrencySymbol. This CurrencySymbol comes from Market. ( PostInit() )
            - Tested Guild Creations
                - Checks to see if you're already in a guild.
                - Created
                - "Cannot compute, error number b" works. ( Immature Guild Tags )
                - Nice creating sequence added. Cus why not?
            - Tested Guild Deletion
                - Leader rank required works
                - Need to type the EXACT guild name AND EXACT guild tag to delete it
                - checks if you're even in a guild
            - Tested some RPG features, eliminated a bug with the update(). self.User would get corrupted after a dataupdate.
            - Added Guild Info
            - Alot of things... xD dunno what anymore
            - Made the /g help structure.
            - started on /g invite
            -

            What you think. /gld instead of /g and make /g guildchat?
            Also do we want; /p party chat, /d direct chat. etc? or is that post-alpha?


--]]

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:Init | http://wiki.rustoxide.com/index.php?title=Hooks/Init
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:Init()

    if( not api.Exists( "economy" ) ) then print( "[CARBON] Carbon needs an economy plugin to work" ) return end
    econ_mod = ((plugins.Find( "econ" )) or (plugins.Find( "market" )))

	print( "Loading Carbon..." )
    --LOAD/CREATE CFG FILE
    self.ConfigFile = util.GetDatafile( "carbon_cfg" )
    local cfg_txt = self.ConfigFile:GetText()
    if (cfg_txt ~= "") then
        print( "Carbon cfg file loaded!" )
        self.Config = json.decode( cfg_txt )
    else
        print( "Creating carbon cfg file..." )
        self:SetDefaultConfig()
    end
    --LOAD/CREATE RPG DATA FILE
    self.UserFile = util.GetDatafile( "carbon_usr" )
    local dat_txt = self.UserFile:GetText()
    if (dat_txt ~= "") then
        print( "Carbon dat file loaded!" )
        self.User = json.decode( dat_txt )
    else
        print( "Creating carbon dat file..." )
        self.User = {}
        self.User[ "hai" ] = "hai"
        self:UserSave()
    end
    --LOAD/CREATE GUILD DATA FILE
    self.GuildFile = util.GetDatafile( "carbon_gld" )
    local gld_txt = self.GuildFile:GetText()
    if (gld_txt ~= "") then
        print( "Carbon gld file loaded!" )
        self.Guild = json.decode( gld_txt )
    else
        print( "Creating carbon gld file..." )
        self.Guild = {}
        self.Guild[ "temp" ] = {}
        self:GuildSave()
    end
    self.sysname = self.Config.settings.sysname
    --TEMPORARY INVISIBLE GEAR COMMAND: REMOVE BEFORE RELEASE
    self:AddChatCommand("cotw", self.addcotw ) -- TESTING ONLY!
	self:AddChatCommand("x", self.x)
    --
	self:AddChatCommand("reset", self.SetDefaultConfig)
    self:AddChatCommand("reload", self.cmdReload)
    self:AddChatCommand("c", self.cmdCarbon)
    self:AddChatCommand("g", self.cmdGuilds)
    self:AddChatCommand("debug", self.cmdDebug)

    self.debugr = false
    self.rnd = 0
    timer.Repeat( 1, function() self.rnd = math.random( 0, 100 ) end )
    timer.Repeat( 60, function() self:GameUpdate() end ) -- This controls everything. guilds/random events etc. 1 minute timer.
    print( "Carbon Loaded!" )
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- Loads after all the other plugins are loaded!
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:PostInit()
    self.CS = econ_mod.CurrencySymbol
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- Testing plugin reload!
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function reloadCarbon(carbon)
    reloadtoken = timer.Once(3,function() reloadtoken = nil  end)
    print("Carbon reloader initiated.. .")
    cs.reloadplugin(carbon)
    local cplugin = plugins.Find(carbon)
    if cplugin then
        cplugin:Init()
        if cplugin.PostInit then cplugin:PostInit() end
    else
        return false, "Failed to reload carbon"
    end
    print("Carbon reloader complete.")
    return true, "Carbon reloaded"
end

function PLUGIN:cmdReload( netuser, cmd, args )
    if not reloadtoken then
        local b, str = reloadCarbon("carbon")
        rust.Notice(netuser,str)     end
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
    if( tostring( args[1] )) == "true" then
        self.debugr = true
        rust.BroadcastChat( "debugr is now on" )
    elseif( tostring(args[1]) == "false" ) then
        self.debugr = false
        rust.BroadcastChat( "debugr is now off" )
    else
        rust.SendChatToUser( netuser, "/debug false or /debug true" )
    end
end

function PLUGIN:addcotw( netuser, cmd , args )
    local guild = self:getGuild( netuser )
    table.insert( self.Guild[ guild ].activeperks, "cotw")
    rust.SendChatToUser( netuser, "cotw added" )
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- table.containsval - check if the value is in the table [ table.containtsval( table, value ) ]
-- self:count( counts a table )
-- self:sayTable( lists the values of that table , sep is the seperator, so like , or ; )
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function table.containsval(t,cv) for _, v in ipairs(t) do  if v == cv then return true  end  end return nil end
function PLUGIN:count( table ) local i = 0 for k, v in pairs( table ) do i = i + 1 end return i end
function PLUGIN:sayTable( table, sep ) local msg = "" local count = #table if( count <= 0 ) then return "N/A" end local i = true
    for k, v in ipairs( table ) do if( i ) then msg = msg .. v i = false else msg = msg .. (sep .. v) end end msg = msg .. "." return msg end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- CARBON CHAT COMMANDS
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:cmdCarbon(netuser, cmd, args)
    local netuserID = rust.GetUserID( netuser )
    if( not (args[1] ) ) then
        rust.SendChatToUser( netuser, self.sysname,  "The Carbon Project [Version " .. tostring(self.Version) .. "]" )
        rust.SendChatToUser( netuser, self.sysname,  "Copyright (c) 2014 Tempus Forge. All rights reserved." )
        rust.SendChatToUser( netuser, self.sysname, tostring( "-" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "/c help" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "For more information on a specific command, type help command-name" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "xp                  Displays characters experience, level, and death penalty." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "attr                Displays characters attributes." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "skills              Displays or modifies character skills." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "perks               Displays or changes character perks." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "penalty             View your current penalties and effects." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "profession          ... coming soon ... " ))
        return

    elseif ((args[1]) and (not(args[2]))) then
        local subject = tostring(args[1])
            if (subject == "xp") then
                local nextLVL = (self.User[netuserID].lvl+1)
                local xpforLVL = math.ceil((((nextLVL*nextLVL)+nextLVL)/self.Config.settings.lvlmodifier*100-(nextLVL*100)))
                local xptoLVL = math.ceil((((nextLVL*nextLVL)+nextLVL)/self.Config.settings.lvlmodifier*100-(nextLVL*100))-self.User[netuserID].xp)
                rust.SendChatToUser( netuser, self.sysname, "Name: " .. tostring( self.User[netuserID].name ))
                rust.SendChatToUser( netuser, self.sysname, "Level: " .. tostring( self.User[netuserID].lvl ))
                rust.SendChatToUser( netuser, self.sysname, "Experience: " .. tostring( self.User[netuserID].xp .. " / " .. tostring(xpforLVL) .. " (" .. tostring(xptoLVL) .. ")"))
                rust.SendChatToUser( netuser, self.sysname, "-")
                rust.SendChatToUser( netuser, self.sysname, "Death Penalty: " .. tostring( self.User[netuserID].dp ))
            end
    elseif(( args[1] ) and ( args[2] )) then
        local subject = tostring(args[1])
        local value = (args[2])
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--TEMPORARY PLUGIN FOR INVISIBILITY GEAR
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:x( netuser, cmd, args )
	local helmet = rust.GetDatablockByName( "Invisible Helmet" )
	local vest = rust.GetDatablockByName( "Invisible Vest" )
	local pants = rust.GetDatablockByName( "Invisible Pants" )
	local boots = rust.GetDatablockByName( "Invisible Boots" )
	local pref = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor )
	local inv = netuser.playerClient.rootControllable.idMain:GetComponent( "Inventory" )
	local invitem1 = inv:AddItemAmount( helmet, 1, pref )
	local invitem2 = inv:AddItemAmount( vest, 1, pref )
	local invitem3 = inv:AddItemAmount( pants, 1, pref )
	local invitem4 = inv:AddItemAmount( boots, 1, pref )
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:OnKilled | http://wiki.rustoxide.com/index.php?title=Hooks/OnKilled
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:OnKilled (takedamage, dmg)
    if(dmg.extraData) then
        weapon = tostring(dmg.extraData.dataBlock.name)
    end
    --IF PLAYER
    if (takedamage:GetComponent( "HumanController" )) then
        local vicuser = dmg.victim.client.netUser
        local vicuserID = rust.GetUserID( vicuser )
        local vicuserdata = self:GetUserData( vicuser )
        if(dmg.victim.client and dmg.attacker.client) then
            local netuser = dmg.attacker.client.netUser
            local netuserID = rust.GetUserID( netuser )
            local netuserdata = self:GetUserData( netuser )
            local isSamePlayer = (dmg.victim.client == dmg.attacker.client)
            if (dmg.victim.client.netUser.displayName and not isSamePlayer) then
                if (netuserdata) then
                    self.User[netuserID].stats.kills.pvp = tonumber(self.User[netuserID].stats.kills.pvp+1)
                    self:GiveXp( netuser, tonumber(math.floor(self.User[vicuserID].xp*self.Config.settings.pkxppercent/100)))
                end
                if (vicuserdata) then
                    self:GiveDp( vicuser, tonumber(math.floor(self.User[vicuserID].xp*self.Config.settings.dppercent/100)))
                end
                return
            end
            if(isSamePlayer) then
                if (netuserdata) then
                    self:GiveDp( netuser, tonumber(math.floor(self.User[netuserID].xp*self.Config.settings.dppercent/100)))
                end
                return
            end
            return
        end
        if (vicuserdata) then
            self:GiveDp( vicuser, tonumber(math.floor(self.User[vicuserID].xp*self.Config.settings.dppercent/100)))
            return
        end
        return
    end
    -- IF NPC
	local npcController = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI'}
	( function ()
        for i, npcController in ipairs(npcController) do
            if (takedamage:GetComponent( npcController )) then
                local originalName = tostring(dmg.victim.networkView.name)
                local targetNAME = string.gsub(originalName, "%(Clone%)", "")
                local netuser = dmg.attacker.client.netUser
                local netuserID = rust.GetUserID( netuser )
                local targetXP = tonumber(math.floor(self.Config.npc[targetNAME].xp*self.Config.settings.xpmodifier))
                if (not self.User[netuserID].stats.kills.pve[targetNAME]) then
                    self.User[netuserID].stats.kills.pve[targetNAME] = 1
                else
                    self.User[netuserID].stats.kills.pve[targetNAME] = self.User[netuserID].stats.kills.pve[targetNAME]+1
                end
                self.User[netuserID].stats.kills.pve.total = tonumber(self.User[netuserID].stats.kills.pve.total+1)
                self:GiveXp( netuser, targetXP, weapon)
            return end --break out of all loops after finding controller type
		end
	end )()
    --IF SLEEPER
	if (string.find(takedamage.gameObject.Name, "MaleSleeper(",1 ,true) and (dmg.attacker.client) and (dmg.attacker.client.netUser) and self.Config.settings.sleeperdppercent > 0) then
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
end

--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:ModifyDamage | http://wiki.rustoxide.com/index.php?title=Hooks/ModifyDamage
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:ModifyDamage (takedamage, dmg)
    if(dmg.extraData) then
        weapon = tostring(dmg.extraData.dataBlock.name)
    end
    if (takedamage:GetComponent( "HumanController" )) then
        if(dmg.victim.client and dmg.attacker.client) then
            local isSamePlayer = (dmg.victim.client == dmg.attacker.client)
            if (dmg.victim.client.netUser.displayName and not isSamePlayer) then
                local vicuser = dmg.victim.client.netUser
                local vicuserID = rust.GetUserID( vicuser )
                local netuser = dmg.attacker.client.netUser
                local netuserID = rust.GetUserID( netuser )
                if (self:GetUserData(netuser)) then
                    --START: ADJUST ATTACKER DAMAGE
                    local weaponDMG = self.User[netuserID].skills[weapon].lvl*.3
                    local weaponTYPE = self.Config.weapon[ weapon ].type
                    local netuserAGI = self.User[ netuserID ].attributes.agi
                    local netuserSTR = self.User[ netuserID ].attributes.str
                    local netuserLVL = self.User[ netuserID ].lvl
                    local netuserDP = self.User[ netuserID ].dp
                    local netuserDMG = self.User[ netuserID ].dmg
                    --DOES USER HAVE THIS WEAPON SKILL? NO!? OK I'LL ADD IT
                    if (not self.User[netuserID].skills[weapon]) then
                        self.User[netuserID].skills[weapon] = {["xp"]=0,["lvl"]=0}
                        self:UserSave()
                    end
                    local weaponDMG = self.User[netuserID].skills[weapon].lvl*.3
                    --PERK PARRY
                    self:perkParry(takedamage, dmg)
                    --MODIFY DMG W/DEATH PENALTY
                    self:modifyDP(netuserDP, netuserID)
                    --RANDOMIZE
                    local damage = math.random(tonumber(dmg.amount*.5),tonumber(dmg.amount))
                    if (self.debugr == true) then  rust.BroadcastChat("RANDOM DAMAGE: " .. tostring(damage)) end
                    --PLAYER DMG MODIFIER
                    local damage = tonumber(damage * self.User[ netuserID ].dmg)
                    if (self.debugr == true) then  rust.BroadcastChat("PLAYER DMG MODIFIER: " .. tostring(damage)) end
                    --WEAPON SKILL BONUS
                    local damage = tonumber(damage + weaponDMG)
                    if (self.debugr == true) then  rust.BroadcastChat("WEAPON SKILL BONUS: " .. tostring(weaponDMG)) end
                    --ATTRIBUTE MODIFIERS
                    self:attrModify(weaponTYPE, netuserSTR, damage, netuserLVL, netuserAGI)
                    --CRIT CHECK
                    self:critCheck(netuserAGI, weaponTYPE, netuserLVL, damage, netuser)
                    --Guild perk modifiers
                    local guild = self:getGuild( netuser )
                    local vicguild = self:getGuild( vicuser )
                    if (self.debugr == true) then rust.BroadcastChat( "GUILDS: " .. netuser.displayName .. " : " .. tostring( guild ) .. " || " .. vicuser.displayName .. " : " .. tostring( vicguild )  ) end
                    if ( guild ) and (vicguild ) then
                        local isRival = self:isRival( guild, vicguild )
                        if( isRival ) then
                            if (self.debugr == true) then rust.BroadcastChat( tostring( guild ) .. " and " .. tostring( vicguild ) .. " are rivals!" ) end
                           --Att Rally! bonus damage
                           local dmgmod = self:hasRallyPerk( guild )
                           if( dmgmod ) then
                               if (self.debugr == true) then rust.BroadcastChat("Before Rally Bonus Damage : " .. tostring(damage) .. " || After: " .. tostring( damage * dmgmod )) end
                                damage = damage * dmgmod
                            end
                            --Vic Stand Your Ground defense bonus
                            local ddmgmod = self:hasSYGPerk( vicguild )
                            if( ddmgmod ) then
                                if (self.debugr == true) then rust.BroadcastChat("Before SYG Damage : " .. tostring(damage) .. " || After: " .. tostring( damage * ddmgmod )) end
                                damage = damage * ddmgmod
                            end
                        end
                    end
                    --Vic stamina modifier
                    dmg.amount = damage - ((self.User[ vicuserID ].attributes.sta+self.User[ vicuserID ].lvl)*.1)
                    if (self.debugr == true) then rust.BroadcastChat("Damage :" .. tostring(dmg.amount)) end
                    --PERK - STONESKIN
                    self:perkStoneskin(dmg)
                    if (self.debugr == true) then rust.BroadcastChat("Adjusted to target damage after Stoneskin: " .. tostring(dmg.amount)) end
                    --END ADJUST ATTACKER DAMAGE
                end
            end
            if(isSamePlayer and self.Config.suicide) then
                --SUICIDE ACTION HERE
--------------------------------------------- Extra DP? -- CareX
                return
            end
        end
        return dmg
    end
	local myString = takedamage.gameObject.Name
	local npcController = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI'}
	( function ()
        for i, npcController in ipairs(npcController) do
            if (takedamage:GetComponent( npcController )) then
                local netuser = dmg.attacker.client.netUser
                local netuserID = rust.GetUserID( netuser )
                if not self.User[ netuserID ].skills[ weapon ] then
                    self.User[ netuserID ].skills[ weapon ] = {}
                    self.User[ netuserID ].skills[ weapon ].xp = 0
                    self.User[ netuserID ].skills[ weapon ].lvl = 0
                end
                --local originalName = tostring(dmg.victim.networkView.name)
                --local targetNAME = string.gsub(originalName, "%(Clone%)", "")
                local targetNAME = string.gsub(tostring(dmg.victim.networkView.name), "%(Clone%)", "")
                local targetDMG = self.Config.npc[targetNAME].dmg
                local weaponDMG = self.User[netuserID].skills[weapon].lvl*.3
                local weaponTYPE = self.Config.weapon[ weapon ].type
                local netuserAGI = self.User[ netuserID ].attributes.agi
                local netuserSTR = self.User[ netuserID ].attributes.str
                local netuserLVL = self.User[ netuserID ].lvl
                local netuserDP = self.User[ netuserID ].dp
                --MODIFY DMG W/DEATH PENALTY
                self:modifyDP(netuserDP, netuserID)
                --Randomize damage
                local damage = math.random(tonumber(dmg.amount*.5),tonumber(dmg.amount))
                --Apply global victim damage modifier
                local damage = tonumber(damage * targetDMG)
                --Apply weapon skill bonus
                local damage = tonumber(damage + weaponDMG)
                if (self.debugr == true) then rust.BroadcastChat("Weapon skill bonus added: " .. tostring(damage)) end
                --ATTRIBUTE MODIFIERS
                self:attrModify(weaponTYPE, netuserSTR, damage, netuserLVL, netuserAGI)
                --CRIT CHECK
                self:critCheck(netuserAGI, weaponTYPE, netuserLVL, damage, netuser)

                local guild = self:getGuild( netuser )
                if (self.debugr == true) then rust.BroadcastChat("Guild found: " .. tostring( guild )  ) end
                if ( guild ) then
                    local cotw = self:hasCOTWPerk( guild )
                    if( cotw ) then
                        if (self.debugr == true) then rust.BroadcastChat("COTW Perk dmg from: " .. damage .. " to: " .. damage * cotw .. " || cotwmod: " .. cotw ) end
                        damage = damage * cotw
                    end
                end
                dmg.amount = damage
                if (self.debugr == true) then rust.BroadcastChat("Adjusted to target damage: " .. tostring(dmg.amount)) end
            return end
        end
    end )()
	if (string.find(myString, "MaleSleeper(",1 ,true) and (dmg.attacker.client) and (dmg.attacker.client.netUser) and self.Config.settings.sleeperdppercent > 0) then
		if(sleepreId ~= nil) then
			--SLEEPER ACTION HERE
        end
    end
end
function PLUGIN:staModify(dmg)
    if ((dmg.attacker.client) and (dmg.victim.networkView.name)) then
        local netuser = dmg.attacker.client.netUser
        local netuserID = rust.GetUserID( netuser )
        local netuserDP = self.User[ netuserID ].dp
        if (netuserDP > 0) then
            local dppercentage = netuserDP / self.User[ netuserID ].xp
            local dmgdp = tonumber(dmg.amount * dppercentage)
            dmg.amount = math.ceil(tonumber(dmg.amount - dmgdp))
            if (self.debugr == true) then  rust.BroadcastChat("Damage reduced by: " .. tostring(math.ceil(dmgdp)) .. " due to " .. netuserDP .. "dp.") end
        end
    end
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:modifyDP
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--Adjust damage per death penalty
function PLUGIN:modifyDP(netuserDP, netuserID)
    if (netuserDP > 0) then
        local dppercentage = netuserDP / self.User[ netuserID ].xp
        local dmgdp = tonumber(dmg.amount * dppercentage)
        dmg.amount = math.ceil(tonumber(dmg.amount - dmgdp))
        if (self.debugr == true) then  rust.BroadcastChat("Damage reduced by: " .. tostring(math.ceil(dmgdp)) .. " due to " .. netuserDP .. "dp.") end
    end
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:attrModify
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:attrModify(weaponTYPE, netuserSTR, damage, netuserLVL, netuserAGI)
    if (weaponTYPE == "melee") and (netuserSTR>0) then
        damage = damage + ((netuserSTR+netuserLVL)*.3)
        if (self.debugr == true) then rust.BroadcastChat("Strength bonus added: " .. tostring(damage)) end
    elseif (weaponTYPE == "ranged" ) and (netuserAGI>0) then
        damage = damage + ((netuserAGI+netuserLVL)*.3)
        if (self.debugr == true) then rust.BroadcastChat("Agility bonus added: " .. tostring(damage)) end
    end
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:critCheck
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:critCheck(netuserAGI, weaponTYPE, netuserLVL, damage, netuser)
    if (netuserAGI>0) then
        local roll = self.rnd
        if (weaponTYPE == "melee") then
            if (self.debugr == true) then rust.BroadcastChat("Dice Rolled!: " .. (tostring(netuserAGI+netuserLVL)*.002) .. " | " .. tostring(roll)) end
            if ((netuserAGI+netuserLVL)*.002 >= roll) then
                damage = damage * 2
                rust.InventoryNotice( netuser, "Critical Hit!" )
            end
        elseif (weaponTYPE == "ranged") then
            if (self.debugr == true) then rust.BroadcastChat("Dice Rolled!: " .. (tostring(netuserAGI+netuserLVL)*.001) .. " | " .. tostring(roll)) end
            if ((netuserAGI+netuserLVL)*.001 >= roll) then
                damage = damage * 2
                rust.InventoryNotice( netuser, "Critical Hit!" )
            end
        end
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:PerkStoneskin
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:perkStoneskin(dmg)
    if ((dmg.victim.client) and (dmg.victim.client ~= dmg.attacker.client)) then
        local vicuser = dmg.victim.client.netUser
        local vicuserID = rust.GetUserID( vicuser )
        local vicuserStoneskin = self.User[ vicuserID ].perks.Stoneskin.lvl
        if (vicuserStoneskin > 0) then
            if (vicuserStoneskin == 1) then
                dmg.amount = tonumber(dmg.amount - (dmg.amount*.05))
                if (self.debugr == true) then  rust.BroadcastChat("[PERK]: Stoneskin absorbed " .. tostring(dmg.amount*.05) .. " dmg!") end
                do return dmg end
            elseif (vicuserStoneskin == 2) then
                dmg.amount = tonumber(dmg.amount - (dmg.amount*.10))
                if (self.debugr == true) then  rust.BroadcastChat("[PERK]: Stoneskin absorbed " .. tostring(dmg.amount*.10) .. " dmg!") end
                do return dmg end
            elseif (vicuserStoneskin == 3) then
                dmg.amount = tonumber(dmg.amount - (dmg.amount*.15))
                if (self.debugr == true) then  rust.BroadcastChat("[PERK]: Stoneskin absorbed " .. tostring(dmg.amount*.15) .. " dmg!") end
                do return dmg end
            elseif (vicuserStoneskin == 4) then
                dmg.amount = tonumber(dmg.amount - (dmg.amount*.20))
                if (self.debugr == true) then  rust.BroadcastChat("[PERK]: Stoneskin absorbed " .. tostring(dmg.amount*.20) .. " dmg!") end
                do return dmg end
            elseif (vicuserStoneskin == 5) then
                dmg.amount = tonumber(dmg.amount - (dmg.amount*.25))
                if (self.debugr == true) then  rust.BroadcastChat("[PERK]: Stoneskin absorbed " .. tostring(dmg.amount*.25) .. " dmg!") end
                do return dmg end
            end
        end
    end
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:PerkParry
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:perkParry(takedamage, dmg)
    if ((dmg.victim.client) and (dmg.victim.client ~= dmg.attacker.client)) then
        local vicuser = dmg.victim.client.netUser
        local vicuserID = rust.GetUserID( vicuser )
        local vicuserParry = self.User[ vicuserID ].perk.Parry.lvl
        --PARRY
        if (vicuserParry > 0) then
            local roll = self.rnd
            if ((vicuserParry == 1) and (roll <= 3)) then
                dmg.amount = 0
                if (self.debugr == true) then  rust.BroadcastChat("[PERK]: You dodged the incoming attack! | 3 > " .. tostring(roll)) end
                do return end
            elseif ((vicuserParry == 2) and (roll <= 6)) then
                dmg.amount = 0
                if (self.debugr == true) then  rust.BroadcastChat("[PERK]: You dodged the incoming attack! | 6 > " .. tostring(roll)) end
                do return end
            elseif ((vicuserParry == 3) and (roll <= 9)) then
                dmg.amount = 0
                if (self.debugr == true) then  rust.BroadcastChat("[PERK]: You dodged the incoming attack! | 9 > " .. tostring(roll)) end
                do return end
            elseif ((vicuserParry == 4) and (roll <= 12)) then
                dmg.amount = 0
                if (self.debugr == true) then  rust.BroadcastChat("[PERK]: You dodged the incoming attack! | 12 > " .. tostring(roll)) end
                do return end
            elseif ((vicuserParry == 5) and (roll <= 15)) then
                dmg.amount = 0
                if (self.debugr == true) then  rust.BroadcastChat("[PERK]: You dodged the incoming attack! | 15 > " .. tostring(roll)) end
                do return end
            end
        end
    end
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:GiveXp
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GiveXp(netuser, xp, weapon)

    local netuserID = rust.GetUserID( netuser )
	local netuserDP = self.User[ netuserID ].dp
	local netuserLVL = self.User[ netuserID ].lvl
	local netuserXP = self.User[ netuserID ].xp

	local weaponLVL = self.User[ netuserID ].skills[ weapon ].lvl
	local weaponXP = self.User[ netuserID ].skills[ weapon ].xp

    -- MISCHA: Check if this is right! // Takes 10% from your exp, adds it to the guild exp (gxp)
    -- I did it BEFORE the DP check, because you didn't want the guild to suffer from someone's DP.
    local guild = self:getGuild( netuser )
    if( guild ) then
        local gxp = math.floor( xp * .1 )
        xp = xp - gxp
        self.Guild[ guild ].xp = self.Guild[ guild ].xp + gxp
        self:GuildSave()
        rust.InventoryNotice( netuser, "+" .. gxp .. "gxp" )
    end

	if (netuserDP>xp) then
		self.User[ netuserID ].dp = netuserDP - xp
		rust.InventoryNotice( netuser, "-" .. (netuserDP - xp) .. "dp" )
	elseif (netuserDP<=0) then
        self.User[ netuserID ].xp = tonumber(netuserXP+xp)
		self.User[ netuserID ].skills[ weapon ].xp = weaponXP + xp
		rust.InventoryNotice( netuser, "+" .. xp .. "xp" )
		self:PlayerLvl(netuser, netuserID, netuserLVL, netuserXP, xp)
		self:WeaponLvl(netuser, netuserID, weaponLVL, weaponXP, weapon, xp)
    elseif( ( xp > netuserDP ) and (not (netuserDP <= 0 ))) then
		local xp = tonumber(xp-netuserDP)
		self.User[ netuserID ].xp = tonumber(netuserXP+xp)
		self.User[ netuserID ].skills[ weapon ].xp = weaponXP + xp
		rust.InventoryNotice( netuser, "-" .. netuserDP .. "dp" )
		rust.InventoryNotice( netuser, "+" .. xp .. "xp" )
		self.User[ netuserID ].dp = 0
		self:PlayerLvl(netuser, netuserID, netuserLVL, netuserXP, xp)
		self:WeaponLvl(netuser, netuserID, weaponLVL, weaponXP, weapon, xp)
    end
    self:UserSave()
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:GiveDp
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GiveDp(vicuser, dp)
    local vicuserID = rust.GetUserID( vicuser )
    local vicuserDP = self.User[ vicuserID ].dp
    local vicuserXP = self.User[ vicuserID ].xp

    if ((vicuserDP+dp/vicuserXP) >= .5) then
        self.User[ vicuserID ].dp = vicuserXP*.5
        rust.InventoryNotice( vicuser, "+" .. (dp - vicuserXP*.5) .. "dp" )
    else
        self.User[ vicuserID ].dp = vicuserDP + dp
        rust.InventoryNotice( vicuser, "+" .. (dp) .. "dp" )
    end
    self:UserSave()
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:PlayerLvl
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:PlayerLvl(netuser, netuserID, netuserLVL, netuserXP, xp)
	local netuserLVLx = math.floor((math.sqrt(100*((self.Config.settings.lvlmodifier*(netuserXP+xp))+25))+50)/100)
	if (netuserLVLx ~= netuserLVL) then
		self.User[ netuserID ].lvl = netuserLVLx
		rust.Notice( netuser, "You are now level " .. netuserLVLx .. "!", 5 )
	end
end

--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:WeaponLvl
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:WeaponLvl(netuser, netuserID, weaponLVL, weaponXP, weapon, xp)
	local weaponLVLx = math.floor((math.sqrt(100*((self.Config.settings.weaponlvlmodifier*(weaponXP+xp))+25))+50)/100)
	if (weaponLVLx ~= weaponLVL) then
		self.User[ netuserID ].skills[ weapon ].lvl = weaponLVLx
        timer.Once( 5, function()  rust.Notice( netuser, "Your skill level has increased!", 5 ) end )
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
--PLUGIN:Guilds commands
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:cmdGuilds( netuser, cmd, args )
    if( not (args[1] ) ) then
        rust.SendChatToUser( netuser, self.sysname, tostring("The Carbon Project [ Version " .. tostring(self.Version) .. " ]" ))
        rust.SendChatToUser( netuser, self.sysname, tostring("Copyright (c) 2014 Tempus Forge. All rights reserved." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "-" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "/g help" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "For more information on a specific command, type help command-name" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "create              Creates guild" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "delete               Deletes guild" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "info                   Displays guild's information that you're currently in." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "invite                Invite a player to your guild." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "kick                  Kicks a player from your guild." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "war                    Engage in a war with another guild." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "rank                  View/assign ranks to your guild members" ))
        return
    elseif ( tostring( args[1] ) == "create") then
        -- /g create "Guild Name" "Guild Tag"
        if(( args[2] ) and ( args[3] )) then
            local userID = rust.GetUserID( netuser )
            if( self.User[ userID ].guild ) then rust.Notice( netuser, "You're already in a guild!" ) return end
            local name = tostring( args[2] )
            local tag = tostring( args[3] )
            tag = string.upper( tag )
            local blocked = table.containsval( self.Config.settings.censor.tag, tag )
            if( blocked ) then rust.Notice( netuser, "Can not compute. Error code number B" ) return end
            if( string.len( tag ) > 3 ) then rust.Notice( netuser, "Guild tag is too long! Maximum of 3 characters allowed" ) return end
            if( string.len( name ) > 15 ) then rust.Notice( netuser, "Guild name is too long! Maximum of 15 characters allowed" ) return end
            self:CreateGuild( netuser, name, tag )
        else
            rust.SendChatToUser( netuser, self.sysname, "/g create \"Guild Name\" \"Guild Tag\" ")
        end

    elseif ( tostring( args[1] ) == "delete") then
        -- /g delete GuildTag                       -- Deletes the guild
        if( args[2] and args[3] ) then
            -- Delete guild
            local guild = self:getGuild( netuser )
            if( guild ) then
                local tag = "[" .. tostring( args[3]) .. "]"
                local rank = self:hasRank( netuser, guild, "Leader" )
                if( guild ~= tostring( args[2] )) or ( self.Guild[ guild ].tag ~= tag ) then rust.Notice( netuser, "Please type your guildname and tag to delete it" ) return end
                if( rank ) then
                    -- DELETE GUILD
                    self:delGuild( guild )
                    rust.SendChatToUser( netuser, self.sysname, "Guild disbanned!" )
                else
                    rust.Notice( netuser, "You're not the guild leader!" )
                    return
                end
            else
                rust.Notice( netuser, "You're not in a guild!" )
                return
            end
        else
            rust.SendChatToUser( netuser, self.sysname, "/g delete \"Guild Name\" \"Guild Tag\" " )
        end
    elseif ( tostring( args[1] ) == "info") then
        -- /g info                                  -- Displays general Guild information
        local guild = self:getGuild( netuser )
        if( not guild ) then self.Notice( netuser, "You're not in a guild!" ) return end
        local data = self:getGuildData( guild )
        local chat = ( data.tag .. " " .. guild )
        rust.SendChatToUser( netuser, chat, chat .. "'s Guild Info:" )
        rust.SendChatToUser( netuser, chat, "----------------------------------" )
        rust.SendChatToUser( netuser, chat, "Guild Name    : " .. guild )
        rust.SendChatToUser( netuser, chat, "Guild Tag        : " .. data.tag )
        rust.SendChatToUser( netuser, chat, "Guild Level     : " .. data.glvl )
        rust.SendChatToUser( netuser, chat, "Guild XP          : (" .. data.xp .. "/" .. data.xpforLVL .. ") (+" .. data.xpforLVL - data.xp .. ")" )
        rust.SendChatToUser( netuser, chat, "-" )
        rust.SendChatToUser( netuser, chat, "Guild Leader   : " .. self:getGuildLeader( guild ))
        rust.SendChatToUser( netuser, chat, "Members        : " .. self:count( data.members ))
        if( data.interval >= 10 ) then
            rust.SendChatToUser( netuser, chat, "Collect/" .. data.interval .. "h     : " .. data.collect ) -- To make it semetrical. xD I'm anal like that.
        else
            rust.SendChatToUser( netuser, chat, "Collect/" .. data.interval .. "h      : " .. data.collect ) -- To make it semetrical. xD I'm anal like that.
        end
        rust.SendChatToUser( netuser, chat, "Perks               : " .. self:sayTable( data.unlockedperks, ", " ) )
        rust.SendChatToUser( netuser, chat, "Active Perks : " .. self:sayTable( data.activeperks, ", " ) )
        rust.SendChatToUser( netuser, chat, "War                   : " .. self:sayTable( data.war, ", " ))
    elseif ( tostring( args[1] ) == "stats") then
        -- /g stats                                 -- Displays a lists of statistics
        local guild = self:getGuild( netuser )
        if( not guild ) then self.Notice( netuser, "You're not in a guild!" ) return end
        local data = self:getGuildData( guild )
        local chat = ( data.tag .. " " .. guild )
        rust.SendChatToUser( netuser, chat, chat .. "'s Guild statistics:" )
        rust.SendChatToUser( netuser, chat, "" )
        rust.SendChatToUser( netuser, chat, "" )

    elseif ( tostring( args[1] ) == "invite") then
        -- /g invite name                           -- Invite a player to the guild
        local guild = self:getGuild( netuser )
        local rank1, rank2 = self:hasRank( netuser, guild, "Leader" ), self:hasRank( netuser, guild, "Co-Leader" )          -- When ranks are customizeable, we need to chance this.
        if( rank1 ) or (rank2) then
            --
        else
            rust.Notice( netuser, "You're not allowed to invite players to the guild!" )
        end
    elseif ( tostring( args[1] ) == "kick") then
        -- /g kick name                             -- Kick a player from the guild

    elseif ( tostring( args[1] ) == "war") then
        -- /g war guildtag                          -- Engage a war with another guild / other guild will be notified.

    elseif ( tostring( args[1] ) == "rank") then
        -- /g rank list                             -- Shows available ranks

        -- /g rank add 'rank' name                  -- Add a rank to a member

        -- /g rank delete 'rank' name               -- Deletes a rank from a member

        -- /g rank create 'rank'                    -- Create a new custom rank

    elseif ( tostring( args[1] ) == "vault" ) then
        -- /g vault buy                             -- Buy a vault

        -- /g vault add                             -- Add items/money to the guild vault

        -- /g vault withdraw                        -- withdraw items/money from the guild vault

        -- /g vault upgrade                         -- Upgrade your vault to the next lvl

    elseif ( tostring( args[1] ) == "help" ) then
        if( tostring( args[2]) == "create" )then
        elseif( tostring( args[2] ) == "delete" ) then
        elseif( tostring( args[2] ) == "info" ) then
        elseif( tostring( args[2] ) == "stats" ) then
        elseif( tostring( args[2] ) == "invite" ) then
        elseif( tostring( args[2] ) == "kick" ) then
        elseif( tostring( args[2] ) == "war" ) then
        elseif( tostring( args[2] ) == "rank" ) then
        elseif( tostring( args[2] ) == "vault" ) then
        else
            rust.SendChatToUser( netuser, self.sysname,"Invalid command! Please type /g [ create/delete/info/stats/invite/kick/war/rank/vault ]" )
        end
    else
        rust.SendChatToUser( netuser, self.sysname,"Invalid command! Please type /g to view all available guild commands." )
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:CreateGuild
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:CreateGuild( netuser, name, tag )
    if( self.Guild[ name ] ) then rust.Notice( netuser, "This guild name is already used." ) return end
    for k, v in pairs( self.Guild ) do
            if( v.tag == ("[" .. tag .. "]") ) then rust.Notice( netuser, "This guild tag is already used!" ) return end
    end
    -- Check if player has enough money.
    local b, bal = api.Call( "economy", "getMoney", netuser )
    if ( b ) then
        -- if ( bal < self.Config.guild.prices.create) then
        --    rust.Notice( netuser, "Not enough money! Requires: ".. self.CS .. self.Config.guild.prices.create )
        --    return
        --else
           api.Call( "economy", "takeMoneyFrom", netuser, self.Config.guild.prices.create )
        --end
    else
        rust.Notice( netuser, "Couldn't find your balance!" )
        return
    end

    local netuserID = rust.GetUserID( netuser )
    local entry = {}
    entry.tag = "[" .. tag .. "]"                                                                                   -- Guild Tag
    entry.glvl = 1                                                                                                  -- Guild Level
    entry.xp = 0                                                                                                    -- Experience
    entry.xpforLVL = math.ceil((((2*2)+2)/self.Config.settings.glvlmodifier*100-(2*100)))                          -- xpforLVL
    entry.ranks = { "Leader", "Co-Leader", "War-Leader", "Quartermaster", "Assasin", "Member" }                     -- Create default Ranks
    entry.members = {}                                                                                              -- Members
    entry.members[ netuserID ] = {}
    entry.members[ netuserID ][ "name" ] = netuser.displayName
    entry.members[ netuserID ][ "rank" ] = "Leader"
    entry.members[ netuserID ][ "moncon" ] = 0
    entry.members[ netuserID ][ "xpcon" ] = 0
    entry.war = {}                                                                                                  -- Guild is at war with:
    entry.collect = 0                                                                                               -- Collects money from members
    entry.gocollect = 0                                                                                             -- time left for next collection
    entry.interval = 0                                                                                              -- Amount of hours between each collection.
    entry.unlockedperks = {}                                                                                        -- Perks are unlocked at certain Guild lvls ( Max: 10 )
    entry.activeperks = {}                                                                                          -- Perks are unlocked at certain Guild lvls ( Max: 10 )
    timer.Once( 1, function()
        rust.SendChatToUser( netuser, self.sysname, "Creating Guild..." )
        timer.Once( 3, function()rust.SendChatToUser( netuser, self.sysname, "Creating guild nameplates..." ) end )
        timer.Once( 6, function()rust.SendChatToUser( netuser, tostring( name ), "Integrating tag..." ) end )
        timer.Once( 9, function()rust.SendChatToUser( netuser, tostring( "[" .. tag .. "] " .. name ), "Creating " .. tostring( name ) .. " user interface..." ) end )
        timer.Once( 16, function()rust.SendChatToUser( netuser, tostring( "[" .. tag .. "] " .. name ), "Feeding the chickens..." ) end )
        timer.Once( 18, function()rust.SendChatToUser( netuser, tostring( "[" .. tag .. "] " .. name ), "Your guild has been created!" ) end )
        timer.Once( 19, function()
        self.Guild[ name ] = entry                                                                                 -- Add complete table to Guilds file
        self.User[ netuserID ][ "guild" ] = name                                                              -- Add guild to userdata.
        self:UserSave()
        self:GuildSave() end)
        end )
end

--[[
    entry.vault = {}                                                                                                -- Vault
    entry.vault[ "money" ][ "gp" ] = 0                                                                              -- Gold in vault
    entry.vault[ "money" ][ "sp" ] = 0                                                                              -- Silver in vault
    entry.vault[ "money" ][ "cp" ] = 0                                                                              -- Copper in vault
    entry.vault[ "weapons" ] = {}                                                                                   -- Weapons in vault
    entry.vault[ "weapons" ] = {}                                                                                   -- Armor in vault
    entry.vault[ "materials" ] = {}                                                                                 -- Metarials in vault
]]--

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

function PLUGIN:getGuildLeader( guild )
    local data = self:getGuildData( guild )
    for k ,v in pairs( data.members ) do
        if( v.rank == "Leader" ) then
            return v.name
        end
    end
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
    local rank = self.Guild[ guild ][ userID ].rank
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
--PLUGIN:HasRallyPerk
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:hasRallyPerk( guild )
    local Rally = table.containsval( self.Guild[ guild ].activeperks, "rally" )
    if ( Rally ) then Rally = ( self.Config.guild.calls.rally.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.rally.requirements.glvl )) return ( Rally + 1 ) else return false end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:HasSYGPerk
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:hasSYGPerk( guild )
    local syg = table.containsval( self.Guild[ guild ].activeperks, "syg" )
    if ( syg ) then syg = ( self.Config.guild.calls.rally.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.syg.requirements.glvl )) return ( 1 - syg ) else return false end
end

function PLUGIN:hasCOTWPerk ( guild )
    local cotw = table.containsval( self.Guild[ guild ].activeperks, "cotw" )
    if ( cotw ) then cotw = ( self.Config.guild.calls.cotw.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.cotw.requirements.glvl + 1 )) return ( cotw + 1 ) else return false end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:SetDefaultGuildConfig
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--[[
function PLUGIN:SetDefaultGuildConfig()

    self.Gconfig={
        ["prices"]={
            ["create"]=25000
        },
        ["settings"]={
            ["vault"]={["req"]=2,["cost"]=50000 ,["slots"]=30},
            ["glvlmodifier"]=.1,
            ["blockedtags"]={"TIT","SEX","FU","FUK","FUC","DIK"}
        },
        ["calls"]={
            ["rally"]={["requirements"]={["cost"]=30000,["glvl"]=3},["mod"]=.05},
            ["syg"]={["requirements"]={["cost"]=30000,["glvl"]=3,["mod"]=.05},["mod"]=.04},
            ["cotw"]={["requirements"]={["cost"]=25000,["glvl"]=2},["mod"]=.05},
            ["forglory"]={["requirements"]={["cost"]=25000,["glvl"]=2},["mod"]=.05 },
            ["kos"]={["requirements"]={["cost"]=25000,["glvl"]=2},["mod"]=50}
        }                                                                                                             -- Cost to create a guild
    self.Gconfig[ "settings" ] = {}
    self.Gconfig[ "settings" ][ "vault" ] = {}
    self.Gconfig[ "settings" ][ "vault" ][ "req" ] = 2                                                              -- Required guild lvl to create a vault
    self.Gconfig[ "settings" ][ "vault" ][ "cost" ] = 50000                                                         -- The cost to enable your guild vault                      -    - MISCHA FIX THIS! -    -
    self.Gconfig[ "settings" ][ "vault" ][ "slots" ] = 30                                                           -- Slots to begin with/ Increase by 10 slots every level
    self.Gconfig[ "settings" ][ "glvlmodifier" ] = .1                                                               -- Modifies the xp need for next lvl. The highger you go, the easier it gets. .2 is 200% easier
    self.Gconfig[ "settings" ][ "blockedtags" ] = { "TIT", "SEX", "FU", "FUK", "FUC", "DIK" }                       -- Blocked Guild Tags.
    self.Gconfig[ "calls" ] = {}
    self.Gconfig[ "calls" ][ "rally" ] = {}                                                                         -- Raddy ; Increase damage to rival guild members
    self.Gconfig[ "calls" ][ "rally" ][ "requirements" ] = {}
    self.Gconfig[ "calls" ][ "rally" ][ "requirements" ][ "cost" ] = 30000
    self.Gconfig[ "calls" ][ "rally" ][ "requirements" ][ "glvl" ] = 3
    self.Gconfig[ "calls" ][ "rally" ][ "mod" ] = .05
    self.Gconfig[ "calls" ][ "syg" ] = {}                                                                           -- Stand your Ground ; Decrease damage from rival guild members
    self.Gconfig[ "calls" ][ "syg" ][ "requirements" ] = {}
    self.Gconfig[ "calls" ][ "syg" ][ "requirements" ][ "cost" ] = 30000
    self.Gconfig[ "calls" ][ "syg" ][ "requirements" ][ "glvl" ] = 3
    self.Gconfig[ "calls" ][ "syg" ][ "requirements" ][ "mod" ] = .05
    self.Gconfig[ "calls" ][ "scavenger" ] = {}                                                                     -- Scavenger ; Have a chance to get a random drop from a kill ( MPC only )
    self.Gconfig[ "calls" ][ "scavenger" ][ "requirements" ] = {}
    self.Gconfig[ "calls" ][ "scavenger" ][ "requirements" ][ "cost" ] = 20000
    self.Gconfig[ "calls" ][ "scavenger" ][ "requirements" ][ "glvl" ] = 4
    self.Gconfig[ "calls" ][ "scavenger" ][ "mod" ] = .04
    self.Gconfig[ "calls" ][ "cotw" ] = {}                                                                          -- Call of the Wild ; Increase damage to wildlife
    self.Gconfig[ "calls" ][ "cotw" ][ "requirements" ] = {}
    self.Gconfig[ "calls" ][ "cotw" ][ "requirements" ][ "cost" ] = 25000
    self.Gconfig[ "calls" ][ "cotw" ][ "requirements" ][ "glvl" ] = 2
    self.Gconfig[ "calls" ][ "cotw" ][ "mod" ] = .05
    self.Gconfig[ "calls" ][ "forglory" ] = {}                                                                      -- For Glory ; Increase guild xp gains
    self.Gconfig[ "calls" ][ "forglory" ][ "requirements" ] = {}
    self.Gconfig[ "calls" ][ "forglory" ][ "requirements" ][ "cost" ] = 25000
    self.Gconfig[ "calls" ][ "forglory" ][ "requirements" ][ "glvl" ] = 2
    self.Gconfig[ "calls" ][ "forglory" ][ "mod" ] = .05
    -- self.Gconfig[ "calls" ][ "kos" ] = {}                                                                        -- Kill On Sight ; Mark a player and when he gets close to one of your members, they'll be notified.
    -- self.Gconfig[ "calls" ][ "kos" ][ "requirements" ] = {}                                                      -- Marked player do not know they're marked, unless they have a high int attribute. They have a change to
    -- self.Gconfig[ "calls" ][ "kos" ][ "requirements" ][ "cost" ] = 25000                                         -- receive a message saying that they're marked.
    -- self.Gconfig[ "calls" ][ "kos" ][ "requirements" ][ "glvl" ] = 2                                             -- FUTURE FEATURE!
    -- self.Gconfig[ "calls" ][ "kos" ][ "mod" ] = 50

    }
    config.Save( "carbon_gld_cfg" )
end
--]]
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:SetDefaultConfig
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:SetDefaultConfig()
        self.Config = {
            ["npc"]={
                ["ZombieNPC_SLOW"]={["ai"]="ZombieController",["name"]="Slow Zombie",["xp"]=45,["dmg"]=.25},
                ["ZombieNPC_FAST"]={["ai"]="ZombieControlller",["name"]="Fast Zombie",["xp"]=40,["dmg"]=.25},
                ["ZombieNPC"]={["ai"]="ZombieController",["name"]="Zombie",["xp"]=35,["dmg"]=.25},
                ["MutantBear"]={["ai"]="BearAI",["name"]="Mutant Bear",["xp"]=30,["dmg"]=.25},
                ["MutantWolf"]={["ai"]="WolfAI",["name"]="Mutant Wolf",["xp"]=25,["dmg"]=.15},
                ["Bear"]={["ai"]="BearAI",["name"]="Bear",["xp"]=20,["dmg"]=.35},
                ["Wolf"]={["ai"]="WolfAI",["name"]="Wolf",["xp"]=15,["dmg"]=.25},
                ["Stag_A"]={["ai"]="StagAI",["name"]="Stag",["xp"]=10,["dmg"]=.50},
                ["Boar_A"]={["ai"]="BoarAI",["name"]="Boar",["xp"]=10,["dmg"]=.50},
                ["Chicken"]={["ai"]="ChickenAI",["name"]="Chicken",["xp"]=5,["dmg"]=1},
                ["Rabbit"]={["ai"]="RabbitAI",["name"]="Rabbit",["xp"]=5,["dmg"]=1},
            },
            ["weapon"]={
                ["9mm Pistol"]={["type"]="c",["dmg"]=1,["lvl"]=1},
                ["M4"]={["type"]="l",["dmg"]=1,["lvl"]=1},
                ["Bolt Action Rifle"]={["type"]="l",["dmg"]=1,["lvl"]=1},
                ["Explosive Charge"]={["type"]="e",["dmg"]=1,["lvl"]=1},
                ["F1 Grenade"]={["type"]="e",["dmg"]=1,["lvl"]=1},
                ["Hand Cannon"]={["type"]="c",["dmg"]=1,["lvl"]=1},
                ["Hatchet"]={["type"]="m",["dmg"]=1,["lvl"]=1},
                ["Hunting Bow"]={["type"]="l",["dmg"]=1,["lvl"]=1},
                ["MP5A4"]={["type"]="l",["dmg"]=1,["lvl"]=1},
                ["P250"]={["type"]="c",["dmg"]=1,["lvl"]=1},
                ["Pick Axe"]={["type"]="m",["dmg"]=1,["lvl"]=1},
                ["Pipe Shotgun"] ={["type"]="c",["dmg"]=1,["lvl"]=1},
                ["Revolver"]={["type"]="c",["dmg"]=1,["lvl"]=1},
                ["Rock"]={["type"]="m",["dmg"]=1,["lvl"]=1},
                ["Shotgun"]={["type"]="c",["dmg"]=1,["lvl"]=1},
                ["Stone Hatchet"]={["type"]="m",["dmg"]=1,["lvl"]=1},
            },
            ["settings"]={
                ["filename"]="carbon",
                ["sysname"]="-",
                ["dppercent"]=5,
                ["dppercent"]=5,
                ["sleeperxppercent"]=5,
                ["sleerperdppecent"]=5,
                ["sleeperradius"]=2,
                ["lvlmodifier"]=2, --0.5=Veteran | 1=hard | 1.5=normal | 2=easy
                ["glvlmodifier"]=.1,
                ["weaponlvlmodifier"]=1.5,
                ["xpmodifier"]=1, -- multiplies values of npc xp given. (ie; 2 = 2x npc reward)
                ["censor"] = {
                    ["chat"]={"fuck","shit","bitch","ass"},
                    ["tag"]={"TIT","SEX","FU","FUK","FUC","DIK"}
                }
            },
            ["guild"] = {
                ["prices"]={
                    ["create"]=25000
                },
                ["settings"]={
                    ["vault"]={["req"]=2,["cost"]=50000 ,["slots"]=30},
                    ["glvlmodifier"]=.1,
                    --["blockedtags"]={"TIT","SEX","FU","FUK","FUC","DIK"}
                },
                ["calls"]={
                    ["rally"]={["requirements"]={["cost"]=30000,["glvl"]=3},["mod"]=.05},
                    ["syg"]={["requirements"]={["cost"]=30000,["glvl"]=3,["mod"]=.05},["mod"]=.04},
                    ["cotw"]={["requirements"]={["cost"]=25000,["glvl"]=2},["mod"]=.05},
                    ["forglory"]={["requirements"]={["cost"]=25000,["glvl"]=2},["mod"]=.05 },
                    ["kos"]={["requirements"]={["cost"]=25000,["glvl"]=2},["mod"]=50}
                }
            }

        }
    self:ConfigSave()
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:OnUserChat | http://wiki.rustoxide.com/index.php?title=Hooks/OnUserConnect
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:OnUserChat(netuser, name, msg)
    if ( msg:sub( 1, 1 ) ~= "/" ) then
        local tempstring = string.lower( msg )
        for k, v in ipairs( self.Config.settings.censor.chat ) do
            local found = string.find( tempstring, v )
            if ( found ) then
                rust.Notice( netuser, "Dont swear!" )
                return false
            end
        end
        local userID = rust.GetUserID( netuser )
        local guild = self:getGuild( netuser )
        if( guild ) then
            local data = self:getGuildData( guild )
            name = data.tag .. " " .. name
            rust.BroadcastChat( name, msg )
            return false
        end
    end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:OnUserConnect | http://wiki.rustoxide.com/index.php?title=Hooks/OnUserConnect
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:OnUserConnect( netuser )
    self:GetUserData( netuser ) -- asks for dat.
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:GetUserData
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GetUserData( netuser )
    local netuserID = rust.GetUserID( netuser )
    --local data = self.User[ netuserID ] -- checks if data exist
    if (not self.User[ netuserID ]) then -- if not, creates one
        self["User"]={
            [netuserID]={
                ["id"]=netuserID,
                ["name"]=name,
                ["lvl"]=1,
                ["xp"]=0,
                ["pp"]=0,
                ["dp"]=0,
                ["ap"]=0,
                ["dmg"]=1,
                ["attributes"] = {
                    ["str"]=0,--Damage Bonus Melee = (strength+level)*.3
                    ["agi"]=0,--Damage Bonus Ranged = (agility+level)*.3 | Chance to crit ranged = ((agi+lvl)*.001) | Chance to crit melee = ((agi+lvl)*.002)
                    ["sta"]=0,--Negates Any Damage Taken = (sta+level)*.1
                    ["int"]=0,--Chance to craft/research = (int*5)+(level*.3)
                },
                ["skills"]={},
                ["perk"]={},
                ["stats"]={
                    ["deaths"]={["pvp"]=0,["pve"]=0},
                    ["kills"]={["pvp"]=0,["pve"]={["total"]=0}},

                },
            }
        }
        self:UserSave()
    end
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
    self.ConfigFile = util.GetDatafile( "carbon_cfg" )
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
end
function PLUGIN:UserUpdate()
    self.UserFile = util.GetDatafile( "carbon_usr" )
    local txt = self.UserFile:GetText()
    self.User = json.decode ( txt )
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- GUILD UPDATE AND SAVE
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GuildSave()
    self.GuildFile:SetText( json.encode( self.Guild, { indent = true } ) )
    self.GuildFile:Save()
    -- self.GuildUpdate()
end
function PLUGIN:GuildUpdate()
    self.GuildFile = util.GetDatafile( "carbon_gld" )
    local txt = self.GuildFile:GetText()
    self.Guild = json.decode ( txt )
end

--api.Call( "economy", "takeMoneyFrom", netuser, value )