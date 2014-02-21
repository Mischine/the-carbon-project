PLUGIN.Title = "Carbon"
PLUGIN.Description = "experience. levels. skills. rewards."
PLUGIN.Version = "0.0.6a"
PLUGIN.Author = "Mischa & CareX"
--[[ SPECIAL NOTES
  02.20.2014
  Mischa:

            TODO: NOTE!:: WE REALLY NEED TO HAVE ALL THIS ON TRELLO/FORUMS.


            TODO: ONE SHOT KILL PREVENTION
            TODO: ADD CHARACTER ATTR POINTS AND PERK POINTS GAINS PER LEVEL
            TODO: PERK PARRY: ADD TIMED BUFF TO CRIT 100%
            TODO: CHAT COMMANDS

            
            -Fixed: Bug in player creation. pve should have been a table{} containing total= and individual pve controllers.
            -Fixed: OnKilled, Modify Damage (modifiers should work for pvp and pve appropriately.) Needs testing.
            -Created calculations for attribute and perk points.
            -Fixed: corresponding functions for onkilled/modifydamage

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

            - this is my, CareX, edit test!

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
    self:AddChatCommand("dump", self.dump)

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
        rust.SendChatToUser( netuser, self.sysname, " ")
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
        weaponData = self.Config.weapon[tostring(dmg.extraData.dataBlock.name)]
    end
    --PLAYER vs PLAYER
    if (takedamage:GetComponent( "HumanController" )) then
        local vicuser = dmg.victim.client.netUser
        local vicuserData = self.User[rust.GetUserID(vicuser)]
        if(dmg.victim.client and dmg.attacker.client) then
            local netuser = dmg.attacker.client.netUser
            local netuserData = self.User[rust.GetUserID(netuser)]
            if (netuser ~= vicuser) then
                netuserData.stats.kills.pvp = netuserData.stats.kills.pvp+1
                --TAKEMONEY !!!!!! CareX
                self:GiveDp( vicuser, vicuserData, math.floor(vicuserData.xp*self.Config.settings.dppercent/100))
            elseif(netuser == vicuser) then
                self:GiveDp( netuser, math.floor(netuserData.xp*self.Config.settings.dppercent/100))
            end
            return
    -- NPC vs PLAYER
        elseif ((dmg.victim.client) and (not dmg.attacker.client)) then
            self:GiveDp( vicuser, math.floor(vicuserData.xp*self.Config.settings.dppercent/100))
        end
    end
    -- PLAYER vs NPC
	local npcController = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI'}
    for i, npcController in ipairs(npcController) do
        if (takedamage:GetComponent( npcController )) then
            local npcData = self.Config.npc[string.gsub(tostring(dmg.victim.networkView.name), "%(Clone%)", "")]
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
    --PLAYER vs SLEEPER
    --[[
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
    --]]
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- OnProcessDamageEvent()
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--[[
local LifeStatusType = cs.gettype( "LifeStatus, Assembly-CSharp-firstpass" )
typesystem.LoadEnum(LifeStatusType, "LifeStatus" )
function PLUGIN:OnProcessDamageEvent( takedamage, damage )
    local status = damage.status
    if(damage.extraData) then
        weapon = tostring(damage.extraData.dataBlock.name)
    end
    if (weapon == "Uber Hatchet") then
        if (status == LifeStatus.WasKilled) then
            damage.status = LifeStatus.IsAlive
            if( damage.victim.client.NetUser ) then
                if( takedamage.health < 100 ) then
                    damage.amount = 0-1
                else
                    damage.amount = 0
                end
            end
        end
    end
end
--]]
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- PLUGIN:ModifyDamage | http://wiki.rustoxide.com/index.php?title=Hooks/ModifyDamage
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:ModifyDamage (takedamage, dmg)
    if(dmg.extraData) then
        weaponData = self.Config.weapon[tostring(dmg.extraData.dataBlock.name)]
    end
    if (takedamage:GetComponent( "HumanController" )) then
        if(dmg.victim.client and dmg.attacker.client) then
            local isSamePlayer = (dmg.victim.client == dmg.attacker.client)
            if (dmg.victim.client.netUser.displayName and not isSamePlayer) then
                if (self:GetUserData(dmg.attacker.client.netUser)) then
                    local netuser = dmg.attacker.client.netUser
                    local netuserData = self.User[rust.GetUserID(netuser)]
                    local vicuser = dmg.victim.client.netUser
                    local vicuserData = self.User[rust.GetUserID(vicuser)]
                    if (not netuserData.skills[weaponData.id]) then
                        netuserData.skills[weaponData.id] = {["xp"]=0,["lvl"]=0}
                        self:UserSave()
                    end
                    --START: ADJUST ATTACKER DAMAGE
                    --PERK PARRY
                    dmg.amount = self:perkParry(dmg, vicuser, vicuserData)
                    if (self.debugr == true) then  rust.BroadcastChat("PERK PARRY: " .. tostring(dmg.amount)) end
                    --DEATH PENALTY MODIFIER
                    dmg.amount = self:modifyDP(netuserData)
                    if (self.debugr == true) then rust.BroadcastChat("DP MODIFIER: " .. tostring(dmg.amount)) end
                    --RANDOMIZE DMG
                    dmg.amount = math.random(dmg.amount*0.5,tonumber(dmg.amount))
                    if (self.debugr == true) then  rust.BroadcastChat("RANDOM DAMAGE: " .. tostring(dmg.amount)) end
                    --PLAYER DMG MODIFIER
                    dmg.amount = dmg.amount*netuserData.dmg
                    if (self.debugr == true) then  rust.BroadcastChat("PLAYER DMG MODIFIER: " .. tostring(dmg.amount)) end
                    --WEAPON DMG BONUS
                    dmg.amount = dmg.amount+netuserData.skills[weapon].lvl*.3
                    if (self.debugr == true) then  rust.BroadcastChat("WEAPON SKILL BONUS: " .. tostring(netuserData.skills[weapon].lvl*.3)) end
                    --ATTRIBUTE DMG MODIFIER
                    dmg.amount = self:attrModify(weaponData, netuserData, vicuserData, dmg.amount)
                    if (self.debugr == true) then  rust.BroadcastChat("ATTRIBUTE DMG MODIFIER: " .. tostring(dmg.amount)) end
                    --CRIT CHANCE
                    dmg.amount = self:critCheck(weaponData, netuser, netuserData, dmg.amount)
                    if (self.debugr == true) then rust.BroadcastChat("CRIT CHANCE: " .. tostring(dmg.amount)) end

                    --GUILD: MODIFIERS
                    local guild = self:getGuild( netuserData )
                    local vicguild = self:getGuild( vicuserData )
                    if (self.debugr == true) then rust.BroadcastChat( "GUILDS: " .. netuser.displayName .. " : " .. tostring( guild ) .. " || " .. vicuser.displayName .. " : " .. tostring( vicguild )  ) end
                    if ( guild ) and (vicguild ) then
                        local isRival = self:isRival( guild, vicguild )
                        if( isRival ) then
                            if (self.debugr == true) then rust.BroadcastChat( tostring( guild ) .. " and " .. tostring( vicguild ) .. " are rivals!" ) end
                           --Att Rally! bonus damage
                           local dmgmod = self:hasRallyCall( guild )
                           if( dmgmod ) then
                               if (self.debugr == true) then rust.BroadcastChat("Before Rally Bonus Damage : " .. tostring(damage) .. " || After: " .. tostring( damage * dmgmod )) end
                                damage = damage * dmgmod
                            end
                            --Vic Stand Your Ground defense bonus
                            local ddmgmod = self:hasSYGCall( vicguild )
                            if( ddmgmod ) then
                                if (self.debugr == true) then rust.BroadcastChat("Before SYG Damage : " .. tostring(damage) .. " || After: " .. tostring( damage * ddmgmod )) end
                                damage = damage * ddmgmod
                            end
                        end
                    end

                    --VICTIM: STAMINA MODIFIER
                    dmg.amount = self:staModify(netuserData, vicuserData, nil, dmg.amount)
                    if (self.debugr == true) then rust.BroadcastChat("Damage :" .. tostring(dmg.amount)) end
                    --VICTIM: STONESKIN MODIFIER
                    self:perkStoneskin(netuser, netuserData, vicuser, vicuserData, damage)
                    if (self.debugr == true) then rust.BroadcastChat("Adjusted to target damage after Stoneskin: " .. tostring(dmg.amount)) end
                    dmg.amount = damage
                    dmg.amount = 20
                    return dmg
                end
            end
            if(isSamePlayer and self.Config.suicide) then
                --SUICIDE ACTION HERE
                return dmg
            end
        elseif ((dmg.victim.client) and (not dmg.attacker.client)) then
            if (self:GetUserData(dmg.victim.client.netUser)) then
                local vicuser = dmg.victim.client.netUser
                local vicuserData = self.User[rust.GetUserID(vicuser)]
                local npcData = self.Config.npc[string.gsub(tostring(dmg.attacker.networkView.name), "%(Clone%)", "")]
                --START: ADJUST ATTACKER DAMAGE
                --PERK PARRY
                dmg.amount = self:perkParry(vicuser, vicuserData, dmg.amount)
                if (self.debugr == true) then  rust.BroadcastChat("PERK PARRY: " .. tostring(dmg.amount)) end
                --RANDOMIZE DMG
                dmg.amount = math.random(dmg.amount*0.5,tonumber(dmg.amount))
                if (self.debugr == true) then  rust.BroadcastChat("RANDOM DAMAGE: " .. tostring(dmg.amount)) end
                --PLAYER DMG MODIFIER
                dmg.amount = dmg.amount*vicuserData.dmg
                if (self.debugr == true) then  rust.BroadcastChat("PLAYER DMG MODIFIER: " .. tostring(dmg.amount)) end
                --ATTRIBUTE DMG MODIFIER
                dmg.amount = self:attrModify(weaponData, npcData, vicuserData, dmg.amount)
                if (self.debugr == true) then  rust.BroadcastChat("ATTRIBUTE DMG MODIFIER: " .. tostring(dmg.amount)) end
                --CRIT CHANCE
                dmg.amount = self:critCheck(weaponData, npcData, vicuserData, dmg.amount)
                if (self.debugr == true) then  rust.BroadcastChat("CRIT CHANCE: " .. tostring(dmg.amount)) end

                --GUILD: MODIFIERS
                local guild = self:getGuild( vicuser )
                if (self.debugr == true) then rust.BroadcastChat("Guild found: " .. tostring( guild )  ) end
                if ( guild ) then
                    local cotw = self:hasCOTWCall( guild )
                    if( cotw ) then
                        if (self.debugr == true) then rust.BroadcastChat("COTW Perk dmg from: " .. damage .. " to: " .. damage * cotw .. " || cotwmod: " .. cotw ) end
                        damage = damage * cotw
                    end
                end

                --VICTIM: STAMINA MODIFIER
                dmg.amount = self:staModify(nil, vicuserData, nil, dmg.amount)
                if (self.debugr == true) then rust.BroadcastChat("STAMINA MODIFIER:" .. tostring(dmg.amount)) end
                --VICTIM: STONESKIN MODIFIER
                dmg.amount = self:perkStoneskin(netuser, netuserData, vicuser, vicuserData, dmg.amount)
                if (self.debugr == true) then rust.BroadcastChat("STONESKIN PERK: " .. tostring(dmg.amount)) end
                return dmg
            end
        end
    end
	local npcController = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI' }
    for i, npcController in ipairs(npcController) do
        if (takedamage:GetComponent( npcController )) then
            local netuser = dmg.attacker.client.netUser
            local netuserData = self.User[rust.GetUserID(netuser)]
            local npcData = self.Config.npc[string.gsub(tostring(dmg.victim.networkView.name), "%(Clone%)", "")]
            if (not netuserData.skills[weaponData.id]) then
                netuserData.skills[weaponData.id] = {["xp"]=0,["lvl"]=0}
                self:UserSave()
            end

            --DEATH PENALTY MODIFIER
            dmg.amount = self:modifyDP(netuserData, dmg.amount)
            if (self.debugr == true) then rust.BroadcastChat("DP MODIFIER: " .. tostring(dmg.amount)) end
            --RANDOMIZE DMG
            dmg.amount = math.random(dmg.amount*0.5,tonumber(dmg.amount))
            if (self.debugr == true) then  rust.BroadcastChat("RANDOMIZE DAMAGE: " .. tostring(dmg.amount)) end
            --NPC DMG MODIFIER
            dmg.amount = dmg.amount*npcData.dmg
            if (self.debugr == true) then  rust.BroadcastChat("NPC DMG MODIFIER: " .. tostring(dmg.amount)) end
            --WEAPON DMG BONUS
            dmg.amount = dmg.amount+netuserData.skills[weapon].lvl*0.3
            if (self.debugr == true) then  rust.BroadcastChat("WEAPON SKILL BONUS: " .. tostring(netuserData.skills[weapon].lvl*0.3)) end
            --ATTRIBUTE DMG MODIFIER
            dmg.amount = self:attrModify(weaponData, netuserData, vicuserData, dmg.amount)
            if (self.debugr == true) then rust.BroadcastChat("ATTRIBUTE MODIFIER: " .. tostring(dmg.amount)) end
            --CRIT CHANCE
            dmg.amount = self:critCheck(weaponData, netuser, netuserData, dmg.amount)
            if (self.debugr == true) then rust.BroadcastChat("CRIT CHANCE: " .. tostring(dmg.amount)) end

            --GUILD STUFF
            local guild = self:getGuild( netuser )
            if (self.debugr == true) then rust.BroadcastChat("Guild found: " .. tostring( guild )  ) end
            if ( guild ) then
                local cotw = self:hasCOTWCall( guild )
                if( cotw ) then
                    if (self.debugr == true) then rust.BroadcastChat("COTW Perk dmg from: " .. damage .. " to: " .. damage * cotw .. " || cotwmod: " .. cotw ) end
                    damage = damage * cotw
                end
            end
            dmg.amount = self:staModify(netuserData, nil, npcData, dmg.amount)
            if (self.debugr == true) then rust.BroadcastChat("STAMINA MODIFIER:" .. tostring(dmg.amount)) end
            return dmg
        end
    end
	if (string.find(tostring(takedamage.gameObject.Name), "MaleSleeper(",1 ,true) and (dmg.attacker.client) and (dmg.attacker.client.netUser) and self.Config.settings.sleeperdppercent > 0) then
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
        end
    end
    if (npcData) then
        if (npcData.sta>0) then
            damage = damage-((npcData.sta+math.random(netuserData.lvl-1,netuserData.lvl+1))*0.1)
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
    end
    return damage
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:attrModify
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:attrModify(weaponData, netuserData, vicuserData, damage)
    if weaponData then
        if (weaponData.type == "melee") and (netuserData.attributes.str>0) then
            damage = damage + ((netuserData.attributes.str+netuserData.lvl)*.3)
        elseif (weaponData.type == "ranged" ) and (netuserData.attributes.agi>0) then
            damage = damage + ((netuserData.attributes.agi+netuserData.lvl)*.3)
        end
    end
    if not weaponData then
        if (netuserData.str>0) then
            damage = damage + ((netuserData.str+(math.random(vicuserData.lvl-1,vicuserData.lvl+1)))*.3)
        end
    end
    return damage
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:critCheck
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:critCheck(weaponData, netuser, netuserData, damage)
    if (netuserData.attributes.agi>0) then
        local roll = self.rnd
        if (weaponData.type == "melee") then
            if ((netuserData.attributes.agi+netuserData.lvl)*.002 >= roll) then
                damage = damage * 2
                rust.InventoryNotice( netuser, "Critical Hit!" )
            end
        elseif (weaponData.type == "ranged") then
            if ((netuserData.attributes.agi+netuserData.lvl)*.001 >= roll) then
                damage = damage * 2
                rust.InventoryNotice( netuser, "Critical Hit!" )
            end
        end
    end
    return damage
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:perkStoneskin
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:perkStoneskin(netuser, vicuser, vicuserData, damage)
    if ((vicuser) and (vicuser ~= netuser) and (vicuserData.perks.Stoneskin)) then
        if (vicuserData.perk.Stoneskin.lvl > 0) then
            if (vicuserStoneskin == 1) then
                damage = tonumber(damage - (damage*.05))
            elseif (vicuserStoneskin == 2) then
                damage = tonumber(damage - (damage*.10))
            elseif (vicuserStoneskin == 3) then
                damage = tonumber(damage - (damage*.15))
            elseif (vicuserStoneskin == 4) then
                damage = tonumber(damage - (damage*.20))
            elseif (vicuserStoneskin == 5) then
                damage = tonumber(damage - (damage*.25))
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
                self:GiveTimedBuff( vicuserData.id, 5 ,"ParryCrit" )
            elseif ((vicuserData.perks.Parry.lvl == 2) and (roll <= 6)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,"ParryCrit" )
            elseif ((vicuserData.perks.Parry.lvl == 3) and (roll <= 9)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,"ParryCrit" )
            elseif ((vicuserData.perks.Parry.lvl == 4) and (roll <= 12)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,"ParryCrit" )
            elseif ((vicuserData.perks.Parry.lvl == 5) and (roll <= 15)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,"ParryCrit" )
            end
        end
    end
    return damage
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:GiveTimedBuff
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GiveTimedBuff( vicuserID, time, buff )
    if not self.Users[vicuserID].buffs["ParryCrit"] then self.Users[vicuserID].buffs["ParryCrit"]=true end
    timer.Once( time, function() self.Users[ vicuserID ].buffs[ buff ] = nil end )
end
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:GiveXp
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:GiveXp(weaponData, netuser, netuserData, xp)

    -- MISCHA: Check if this is right! // Takes 10% from your exp, adds it to the guild exp (gxp)
    -- I did it BEFORE the DP check, because you didn't want the guild to suffer from someone's DP.
    local guild = self:getGuild( netuser )
    if( guild ) then
        local gxp = math.floor( xp * .1 )
        --xp = xp - gxp --if we want to take from the players xp.
        self.Guild[ guild ].xp = self.Guild[ guild ].xp + gxp
        self:GuildSave()
        rust.InventoryNotice( netuser, "+" .. gxp .. "gxp" )
    end

	if (netuserData.dp>xp) then
		netuserData.dp = netuserData.dp - xp
		rust.InventoryNotice( netuser, "-" .. (netuserData.dp - xp) .. "dp" )
	elseif (netuserData.dp<=0) then
        netuserData.xp = netuserData.xp+xp
		netuserData.skills[ weaponData.id ].xp = netuserData.skills[ weaponData.id ].xp + xp
		rust.InventoryNotice( netuser, "+" .. xp .. "xp" )
		self:PlayerLvl(netuser, netuserData, xp)
		self:WeaponLvl(weaponData, netuser, netuserData, xp)
    elseif((xp>netuserData.dp) and (not (netuserData.dp<= 0))) then
		local xp = xp-netuserData.dp
		netuserData.xp = netuserData.xp+xp
        netuserData.skills[ weaponData.id ].xp = netuserData.skills[ weaponData.id ].xp + xp
		rust.InventoryNotice( netuser, "-" .. netuserData.dp .. "dp" )
		rust.InventoryNotice( netuser, "+" .. xp .. "xp" )
		netuserData.dp = 0
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
        rust.InventoryNotice( vicuser, "+" .. (dp - vicuserData.xp*.5) .. "dp" )
    else
        vicuserData.dp = vicuserData.dp + dp
        rust.InventoryNotice( vicuser, "+" .. (dp) .. "dp" )
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
		rust.Notice( netuser, "You are now level " .. calcLvl .. "!", 5 )
    end
    --[[
    local calcAp = math.floor((math.sqrt(100*((self.Config.settings.lvlmodifier*(netuserData.xp+xp))+25))+50)/100/3)
    if (calcAp ~= netuserData.ap) then
        netuserData.ap = calcAp
        rust.Notice( netuser, "You earned an att" .. calcAp .. " !", 5 )
    end
    local calcAp = math.floor((math.sqrt(100*((self.Config.settings.lvlmodifier*(netuserData.xp+xp))+25))+50)/100/3)
    if (calcAp ~= netuserData.ap) then
        netuserData.ap = calcAp
        rust.Notice( netuser, "You earned an att" .. calcAp .. " !", 5 )
    end
    --]]
end

--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:WeaponLvl
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

function PLUGIN:WeaponLvl(weaponData, netuser, netuserData, xp)
	local calcLvl = math.floor((math.sqrt(100*((self.Config.settings.weaponlvlmodifier*(netuserData.skills[ weaponData.id ].xp+xp))+25))+50)/100)
	if (calcLvl ~= netuserData.skills[ weaponData.id ].lvl) then
		netuserData.skills[ weapon ].lvl = calcLvl
        timer.Once( 5, function()  rust.Notice( netuser, "Your skill with the " .. tostring(weaponData.name) .. " is now level " .. tostring(calcLvl) .. "!", 5 ) end )
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
        rust.SendChatToUser( netuser, " ", " ")
        rust.SendChatToUser( netuser, self.sysname, tostring( "/g help" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "For more information on a specific command, type help command-name" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "create              Creates guild" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "delete               Deletes guild" ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "info                   Displays guild's information that you're currently in." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "stats                  Display global statistics of the guild." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "invite                Invite a player to your guild." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "kick                  Kicks a player from your guild." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "war                    Engage in a war with another guild." ))
        rust.SendChatToUser( netuser, self.sysname, tostring( "rank                  View/assign ranks to your guild members" ))
        return
    elseif ( tostring( args[1] ) == "create") then
        -- /g create "Guild Name" "Guild Tag"
        if(( args[2] ) and ( args[3] )) then
            local lvl = tonumber( self:getLvl( netuser ) )
            -- if( not ( lvl >= 10 )) then rust.Notice( netuser, "level 10 required to create your own guild!" ) return end
            local userID = rust.GetUserID( netuser )
            if( self.User[ userID ].guild ) then rust.Notice( netuser, "You're already in a guild!" ) return end
            local name = tostring( args[2] )
            local tag = tostring( args[3] )
            tag = string.upper( tag )
            if( table.containsval( self.Config.settings.censor.tag, tag ) ) then rust.Notice( netuser, "Can not compute. Error code number B" ) return end
            if( string.len( tag ) > 3 ) then rust.Notice( netuser, "Guild tag is too long! Maximum of 3 characters allowed" ) return end
            if( string.len( name ) > 15 ) then rust.Notice( netuser, "Guild name is too long! Maximum of 15 characters allowed" ) return end
            self:CreateGuild( netuser, name, tag )
        else
            rust.SendChatToUser( netuser, self.sysname, "/g create \"Guild Name\" \"Guild Tag\" ")
        end

    elseif ( tostring( args[1] ) == "delete") then  --                                                  [ candelete ]
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
        if( not guild ) then rust.Notice( netuser, "You're not in a guild!" ) return end
        local data = self:getGuildData( guild )
        local chat = ( data.tag .. " " .. guild )
        rust.SendChatToUser( netuser, chat, chat .. "'s Guild Info:" )
        rust.SendChatToUser( netuser, chat, "----------------------------------" )
        rust.SendChatToUser( netuser, chat, "Guild Name    : " .. guild )
        rust.SendChatToUser( netuser, chat, "Guild Tag        : " .. data.tag )
        rust.SendChatToUser( netuser, chat, "Guild Level     : " .. data.glvl )
        rust.SendChatToUser( netuser, chat, "Guild XP          : (" .. data.xp .. "/" .. data.xpforLVL .. ") (+" .. data.xpforLVL - data.xp .. ")" )
        rust.SendChatToUser( netuser, " ", " " )
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

    elseif ( tostring( args[1] ) == "invite") then  --                                                  [ caninvite ]
        -- /g invite "name"                         -- Invite a player to the guild
        local guild = self:getGuild( netuser )
        local cando = self:hasAbility( netuser, guild, "caninvite" )
        if( cando ) then
            local targname = tostring( args[ 2 ] )
            local b, targuser = rust.FindNetUsersByName( targname )
            if ( not b ) then
                if( targuser == 0 ) then
                    rust.Notice( netuser, "No user found with the name: " .. util.QuoteSafe( targname ) )
                else
                    rust.Notice( netuser, "Multiple users found with the name: " .. util.QuoteSafe( targname ) )
                end
            return end
            local targuserID = rust.GetUserID( targuser )
            local members = self:getGuildMembers( guild )
            table.containsval( members, targuserID )
            self.Guild.temp[ targuserID ] = guild
            timer.Once( 60, function()
                if( self.Guild.temp[ targuserID ]) then
                    rust.SendChatToUser(targuser, self.sysname, "Invitation to " .. guild .. " expires in 60 seconds" )
                    timer.Once( 60, function()
                        if( self.Guild.temp[ targuserID ]) then
                            rust.SendChatToUser( targuser, self.sysname, "Invatation to " .. guild .. " expired." )
                            self.Guild.temp[ targuserID ] = nil
                        end
                    end)
                end
            end)
            rust.Notice( targuser, "You've been invited to " .. guild .. ". /g accept to join the guild.", 15)
        else
            rust.Notice( netuser, "You're not allowed to invite players to the guild!" )
        end
    elseif ( tostring( args[1] ) == "accept") then
        -- /g accept
        local netuserID = rust.GetUserID( netuser )
        if( self.Guild.temp[ netuserID ] ) then
            local guild = self.Guild.temp[ netuserID ]
            local entry = {}
            entry.name = netuser.displayName
            entry.rank = "Member"
            entry.moncon = 0
            entry.xpcon = 0
            self.Guild[ guild ].members[ netuserID ] = entry
            self.User[ netuserID ][ "guild" ] = guild
            self:sendGuildMsg( guild, netuser.displayName, "has joined the guild!" )
            self.Guild.temp[ netuserID ] = nil
            self:UserSave()
            self:GuildUser()
        end
    elseif ( tostring( args[1] ) == "leave") then
        -- /g leave guildtag


    elseif ( tostring( args[1] ) == "kick") then    --                                                  [ cankick ]
        -- /g kick name                             -- Kick a player from the guild


    elseif ( tostring( args[1] ) == "war") then     --                                                  [ canwar ]
        -- /g war guildtag                          -- Engage a war with another guild / other guild will be notified.


    elseif ( tostring( args[1] ) == "rank") then
        -- /g rank list                             -- Shows available ranks

        -- /g rank list info                        -- Shows the rank capabilities

        -- /g rank give 'rank' name                 -- Add a rank to a member                           [ canrank ]

        -- /g rank delete 'rank' name               -- Deletes a rank from a member                     [ canrank ]

        -- /g rank add 'rank'                       -- Create a new custom rank                         [ canrank ]

        -- /g rank edit 'rank'                      -- Create a new custom rank                         [ canrank ]

    elseif ( tostring( args[1] ) == "vault" ) then  --                                                  [ canvault ]
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
            rust.SendChatToUser( netuser, self.sysname, "Invalid command! Please type /g [ create/delete/info/stats/invite/kick/war/rank/vault ]" )
        end
    else
        rust.SendChatToUser( netuser, self.sysname, "Invalid command! Please type /g to view all available guild commands." )
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
    entry.xpforLVL = math.ceil((((2*2)+2)/self.Config.settings.glvlmodifier*100-(2*100)))                           -- xpforLVL
    entry.ranks = { ["Leader"]={"candelete","caninvite","cankick","canvault","canwar","canrank"},                   -- Create default Ranks
                    ["Co-Leader"]={"caninvite","cankick","canvault","canwar"},
                    ["War-Leader"]={"canwar"},
                    ["Quartermaster"]={"canvault"},
                    ["Assasin"]={},
                    ["Member"]={}
                  }
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
        self.Guild[ name ] = entry                                                                                  -- Add complete table to Guilds file
        self.User[ netuserID ][ "guild" ] = name                                                                    -- Add guild to userdata.
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
--PLUGIN:getGuildMembers
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:getGuildMembers( guild )
    local guilddata = self:getGuildData( guild )
    local members = guilddata.members
    return members
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:sendGuildMsg
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:sendGuildMsg( guild, name, msg )
    local guilddata = self:getGuildData( guild )
    local members = guilddata.members
    for k,v in pairs( members ) do
        local targuser = rust.NetUserFromNetPlayer( k )
        rust.SendChatToUser( targuser, guilddata.tag .. " " ..v.name, msg )
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
        if( v.rank == "Leader" ) then
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
    local Rally = table.containsval( self.Guild[ guild ].activeperks, "rally" )
    if ( Rally ) then Rally = ( self.Config.guild.calls.rally.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.rally.requirements.glvl )) return ( Rally + 1 ) else return false end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:hasSYGCall
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:hasSYGCall( guild )
    local syg = table.containsval( self.Guild[ guild ].activeperks, "syg" )
    if ( syg ) then syg = ( self.Config.guild.calls.rally.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.syg.requirements.glvl )) return ( 1 - syg ) else return false end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:hasCOTWCall
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:hasCOTWCall ( guild )
    local cotw = table.containsval( self.Guild[ guild ].activeperks, "cotw" )
    if ( cotw ) then cotw = ( self.Config.guild.calls.cotw.mod * ( self.Guild[ guild ].glvl - self.Config.guild.calls.cotw.requirements.glvl + 1 )) return ( cotw + 1 ) else return false end
end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--PLUGIN:SetDefaultConfig
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function PLUGIN:SetDefaultConfig()
        self.Config = {
            ["npc"]={
                ["ZombieNPC_SLOW"]={["id"]="ZombieNPC_SLOW",["ai"]="ZombieController",["name"]="Slow Zombie",["xp"]=45,["dmg"]=.25,["sta"]=10,["str"]=10},
                ["ZombieNPC_FAST"]={["id"]="ZombieNPC_FAST",["ai"]="ZombieControlller",["name"]="Fast Zombie",["xp"]=40,["dmg"]=.25,["sta"]=9,["str"]=9},
                ["ZombieNPC"]={["id"]="ZombieNPC",["ai"]="ZombieController",["name"]="Zombie",["xp"]=35,["dmg"]=.25,["sta"]=8,["str"]=8},
                ["MutantBear"]={["id"]="MutantBear",["ai"]="BearAI",["name"]="Mutant Bear",["xp"]=30,["dmg"]=.25,["sta"]=7,["str"]=7},
                ["MutantWolf"]={["id"]="MutantWolf",["ai"]="WolfAI",["name"]="Mutant Wolf",["xp"]=25,["dmg"]=.15,["sta"]=6,["str"]=6},
                ["Bear"]={["id"]="Bear",["ai"]="BearAI",["name"]="Bear",["xp"]=20,["dmg"]=.35,["sta"]=5,["str"]=5},
                ["Wolf"]={["id"]="Wolf",["ai"]="WolfAI",["name"]="Wolf",["xp"]=15,["dmg"]=.25,["sta"]=4,["str"]=4},
                ["Stag_A"]={["id"]="Stag_A",["ai"]="StagAI",["name"]="Stag",["xp"]=10,["dmg"]=.50,["sta"]=3,["str"]=3},
                ["Boar_A"]={["id"]="Boar_A",["ai"]="BoarAI",["name"]="Boar",["xp"]=10,["dmg"]=.50,["sta"]=2,["str"]=2},
                ["Chicken"]={["id"]="Chicken",["ai"]="ChickenAI",["name"]="Chicken",["xp"]=5,["dmg"]=1,["sta"]=1,["str"]=1},
                ["Rabbit"]={["id"]="Rabbit",["ai"]="RabbitAI",["name"]="Rabbit",["xp"]=5,["dmg"]=1,["sta"]=1,["str"]=1},
            },
            ["weapon"]={
                ["9mm Pistol"]={["id"]="9mm Pistol",["type"]="c",["dmg"]=1,["lvl"]=1},
                ["M4"]={["id"]="M4",["type"]="l",["dmg"]=1,["lvl"]=1},
                ["Bolt Action Rifle"]={["id"]="Bolt Action Rifle",["type"]="l",["dmg"]=1,["lvl"]=1},
                ["Explosive Charge"]={["id"]="Explosive Charge",["type"]="e",["dmg"]=1,["lvl"]=1},
                ["F1 Grenade"]={["id"]="F1 Grenade",["type"]="e",["dmg"]=1,["lvl"]=1},
                ["Hand Cannon"]={["id"]="Hand Cannon",["type"]="c",["dmg"]=1,["lvl"]=1},
                ["Hatchet"]={["id"]="Hatchet",["type"]="m",["dmg"]=1,["lvl"]=1},
                ["Hunting Bow"]={["id"]="Hunting Bow",["type"]="l",["dmg"]=1,["lvl"]=1},
                ["MP5A4"]={["id"]="MP5A4",["type"]="l",["dmg"]=1,["lvl"]=1},
                ["P250"]={["id"]="P250",["type"]="c",["dmg"]=1,["lvl"]=1},
                ["Pick Axe"]={["id"]="Pick Axe",["type"]="m",["dmg"]=1,["lvl"]=1},
                ["Pipe Shotgun"] ={["id"]="Pipe Shotgun",["type"]="c",["dmg"]=1,["lvl"]=1},
                ["Revolver"]={["id"]="Revolver",["type"]="c",["dmg"]=1,["lvl"]=1},
                ["Rock"]={["id"]="Rock",["type"]="m",["dmg"]=1,["lvl"]=1},
                ["Shotgun"]={["id"]="Shotgun",["type"]="c",["dmg"]=1,["lvl"]=1},
                ["Stone Hatchet"]={["id"]="Stone Hatchet",["type"]="m",["dmg"]=1,["lvl"]=1},
            },
            ["settings"]={
                ["filename"]="carbon",
                ["sysname"]=" ",
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
    local data = self:GetUserData( netuser ) -- asks for dat.
    data.name = netuser.displayName
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
        data.attributes = {["str"]=0,["agi"]=0,["sta"]=0,["int"]=0 }
        data.buffs = {}
        data.skills = {}
        data.perks = {}
        data.stats = {["deaths"]={["pvp"]=0,["pve"]=0},["kills"]={["pvp"]=0,["pve"]={["total"]=0}}}
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