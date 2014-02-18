PLUGIN.Title = "Carbon"
PLUGIN.Description = "experience. levels. skills. rewards."
PLUGIN.Version = "1.0.4a"
PLUGIN.Author = "Mischa"
--[[-----------< CHANGELOG >------------------
02.18.2014
    CREATED GITHUB
02.14.14
    ADD WEAPON XP SYSTEM AND BONUSES TO DMG PER WEAPON
02.13.14
	ADDED: SKILLS TO USERS TABLE (SKILLS HAVE NO SPACES)
02.12.14
	ADDED: DAMAGE MODIFIERS FOR NPC
	ADDED: LEVEL POP UP MESSAGE
	ADDED: LEVEL SYSTEM MATHEMATICALLY CALCULATED BASED ON XP
	ADDED: XP POPUP MESSAGE
	ADDED: XP +/- SYSTEM
	ADDED: DP +/- SYSTEM
--------------------------------------------
------------------TODO----------------------
[ ]ADD DEATH SKILL PENALTIES TO ATTACK AND DEFENSE
[ ]ADD LEVEL TO UNLOCK SKILLS
[ ]ADD DEFENSE BONUSES INCREASE FOR LEVEL
[ ]ADD ATTACK DMG INCREASE FOR LEVEL
[ ]ADD PERK +/- SYSTEM
[ ]ADD PERKS AND BONUSES
[ ]ADD PERK TRAINER SYSTEM
------------------------------------------]]
-- PLUGIN:Init | http://wiki.rustoxide.com/index.php?title=Hooks/Init
-----------------------------
function PLUGIN:Init()
	print( "Loading Carbon..." )

    -- Load the user datafile
    self.ConfigFile = util.GetDatafile( "carbon_cfg" )
    local cfg_txt = self.ConfigFile:GetText()
    if (cfg_txt ~= "") then
        self.Config = json.decode( cfg_txt )
        print( "Carbon config files loaded!" )
    else
        print( "Creating carbon config file..." )
        self.Config = {}
        self.Config.npc = {}
        self.Config.weapon = {}
        self.Config.sleepers = {}
        self.Config.settings = {}
        self:SetDefaultConfig()
    end

    -- Load the user datafile
    self.DataFile = util.GetDatafile( "carbon_dat" )
    local dat_txt = self.DataFile:GetText()
    if (dat_txt ~= "") then
        self.Data = json.decode( dat_txt )
        print( "Carbon data files loaded!" )
    else
        print( "Creating carbon data files..." )
        self.Data = {}
        self.Data.users = {}
        self:DataSave()
    end

	self:AddChatCommand("x", self.x) --< TEMPORARY INVISIBLE GEAR : REMOVE !!!!!!!!!!!!!
	self:AddChatCommand("reset", self.SetDefaultConfig)
	self:AddChatCommand("carbon", self.CarbonReload)
    self:AddChatCommand("c", self.cmdCarbon)
	print( "Carbon Loaded!" )
end
-----------------------------
-- Chat Commands 
-----------------------------
function PLUGIN:cmdCarbon(netuser, cmd, args)
    local netuserID = rust.GetUserID( netuser )
    if( not (args[1] ) ) then
        self:UserMsg( netuser,  "Carbon Character [Version " .. tostring(self.Version) .. "]" )
        self:UserMsg( netuser,  "Copyright (c) 2014 The Carbon Project. All rights reserved." )
        self:UserMsg( netuser, tostring( "-" ))
        self:UserMsg( netuser, tostring( "/c help" ))
        self:UserMsg( netuser, tostring( "For more information on a specific command, type help command-name" ))
        self:UserMsg( netuser, tostring( "xp                  Displays characters experience, level, and death penalty." ))
        self:UserMsg( netuser, tostring( "attr                Displays characters attributes." ))
        self:UserMsg( netuser, tostring( "skills              Displays or modifies character skills." ))
        self:UserMsg( netuser, tostring( "perks               Displays or changes character perks." ))
        self:UserMsg( netuser, tostring( "penalty             View your current penalties and effects." ))
        self:UserMsg( netuser, tostring( "profession          ... coming soon ... " ))
        return

    elseif ((args[1]) and (not(args[2]))) then
        local subject = tostring(args[1])
            if (subject == "xp") then
                self:UserMsg( netuser, "Name: " .. tostring( self.Data.users[netuserID].name ))
                self:UserMsg( netuser, "Level: " .. tostring( self.Data.users[netuserID].lvl ))
                self:UserMsg( netuser, "Experience: " .. tostring( self.Data.users[netuserID].xp ))
                local nextLVL = (self.Data.users[netuserID].lvl+1)
                local xptoLVL = math.ceil((((nextLVL*nextLVL)+nextLVL)/self.Config.settings.lvlmodifier*100-(nextLVL*100))-self.Data.users[netuserID].xp)
                self:UserMsg( netuser, "XP to level: " .. tostring( xptoLVL ))
                self:UserMsg( netuser, "-")
            self:UserMsg( netuser, "Death Penalty: " .. tostring( self.Data.users[netuserID].dp ))
        end
    elseif(( args[1] ) and ( args[2] )) then
        local subject = tostring(args[1])
        local value = (args[2])
    end
end
function PLUGIN:CarbonReload(  )
	plugins.Reload( "carbon" )
	rust.BroadcastChat( "Carbon Reloaded..." )
end

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

-----------------------------
-- PLUGIN:OnKilled | http://wiki.rustoxide.com/index.php?title=Hooks/OnKilled
-----------------------------
function PLUGIN:OnKilled (takedamage, dmg)
    debugr = true
    if(dmg.extraData) then
        weapon = string.gsub(tostring(dmg.extraData.dataBlock.name), "%s+", "")
    end
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
                    self:GiveXp( netuser, tonumber(math.floor(self.Data.users[vicuserID].xp*self.Config.settings.pkxppercent/100)))
                end
                if (vicuserdata) then
                    self:GiveDp( vicuser, tonumber(math.floor(self.Data.users[vicuserID].xp*self.Config.settings.dppercent/100)))
                end
                return
            end
            if(isSamePlayer) then
                if (netuserdata) then
                    self:GiveDp( netuser, tonumber(math.floor(self.Data.users[netuserID].xp*self.Config.settings.dppercent/100)))
                end
                return
            end
            return
        end
        if (vicuserdata) then
            self:GiveDp( vicuser, tonumber(math.floor(self.Data.users[vicuserID].xp*self.Config.settings.dppercent/100)))
            return
        end
        return
    end
	local targetXp = 0
	npcController = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI'}
	( function ()
        for i, npcController in ipairs(npcController) do
            if (takedamage:GetComponent( npcController )) then
                local originalName = tostring(dmg.victim.networkView.name)
                local targetName = string.gsub(originalName, "%(Clone%)", "")
                targetXp = tonumber(math.floor(self.Config.npc[targetName].xp*self.Config.settings.xpmodifier))
            return end --break out of all loops after finding controller type
		end
	end )()
	if (tonumber(targetXp) > 0) then
		local netuser = dmg.attacker.client.netUser
		local netuserID = rust.GetUserID( netuser )
		self:GiveXp( netuser, targetXp, weapon)
	elseif (string.find(takedamage.gameObject.Name, "MaleSleeper(",1 ,true) and (dmg.attacker.client) and (dmg.attacker.client.netUser) and self.Config.settings.sleeperdppercent > 0) then
		local actorUser = dmg.attacker.client.netUser
		local coord = actorUser.playerClient.lastKnownPosition
		local sleepreId = self:SleeperPos(coord)
	if(sleepreId ~= nil) then
		self.Config.sleepers.pos[sleepreId] = nil
		self:GiveXp( actorUser, tonumber(math.floor(self.Data.users[sleepreId].xp*self.Config.settings.sleeperxppercent/100)))
		self:setXpPercentById(sleepreId, tonumber(100-self.Config.settings.sleeperxppercent-self.Config.settings.dppercent))
	end
	end
    return
end

-----------------------------
-- PLUGIN:ModifyDamage | http://wiki.rustoxide.com/index.php?title=Hooks/ModifyDamage
-----------------------------
function PLUGIN:ModifyDamage (takedamage, dmg)
    debugr = true
    if(dmg.extraData) then
        weapon = string.gsub(tostring(dmg.extraData.dataBlock.name), "%s+", "")
    end
    --if i have death penalty then lower my damage based on what my death penalty's percentage is.
    if ((dmg.attacker.client) and (dmg.victim.networkView.name)) then
        local netuser = dmg.attacker.client.netUser
        local netuserID = rust.GetUserID( netuser )
        local netuserDP = self.Data.users[ netuserID ].dp
        if (netuserDP > 0) then
            local dppercentage = netuserDP / self.Data.users[ netuserID ].xp
            local dmgdp = tonumber(dmg.amount * dppercentage)
            dmg.amount = math.ceil(tonumber(dmg.amount - dmgdp))
            if (debugr == true) then  rust.BroadcastChat("Damage reduced by: " .. tostring(math.ceil(dmgdp)) .. " due to " .. netuserDP .. "dp.") end
        end

    end
    --PERK - PARRY
    self:PerkParry(takedamage, dmg)
    if (takedamage:GetComponent( "HumanController" )) then
        if(dmg.victim.client and dmg.attacker.client) then
            local isSamePlayer = (dmg.victim.client == dmg.attacker.client)
            if (dmg.victim.client.netUser.displayName and not isSamePlayer) then
                local vicuser = dmg.victim.client.netUser
                local vicuserID = rust.GetUserID( vicuser )
                local netuser = dmg.attacker.client.netUser
                local netuserID = rust.GetUserID( netuser )
                if not self.Data.users[ netuserID ].skills[ weapon ] then
                    self.Data.users[ netuserID ].skills[ weapon ] = {}
                    self.Data.users[ netuserID ].skills[ weapon ].xp = 0
                    self.Data.users[ netuserID ].skills[ weapon ].lvl = 0
                end
                local attackdata = self:GetUserData( netuser )
                if (attackdata) then
                    --START: ADJUST ATTACKER DAMAGE
                    local weaponDmg = self.Data.users[netuserID].skills[weapon].lvl*.3
                    local weaponType = self.Config.weapon[ weapon ].type
                    local netuserAGI = tonumber(self.Data.users[ netuserID ].attributes.agi)
                    local netuserSTR = tonumber(self.Data.users[ netuserID ].attributes.str)
                    local netuserLVL = tonumber(self.Data.users[ netuserID ].lvl)
                    --Adjust damage per death penalty
                    if (netuserDP > 0) then
                        local dppercentage = netuserDP / self.Data.users[ netuserID ].xp
                        local dmgdp = tonumber(dmg.amount * dppercentage)
                        dmg.amount = math.ceil(tonumber(dmg.amount - dmgdp))
                        if (debugr == true) then  rust.BroadcastChat("Damage reduced by: " .. tostring(math.ceil(dmgdp)) .. " due to " .. netuserDP .. "dp.") end
                    end
                    --Randomize damage.
                    local damage = math.random(tonumber(dmg.amount*.5),tonumber(dmg.amount))
                    --Multiply damage by players damage modifier
                    local damage = tonumber(damage * self.Data.users[ netuserID ].dmg)
                    --Weapon skill bonus applied
                    local damage = tonumber(damage + weaponDmg)
                    if (debugr == true) then  rust.BroadcastChat("Weapon skill bonus added: " .. tostring(damage)) end
                    --Attribute modifiers
                    if (weaponType == "melee") and (netuserSTR>0) then
                        damage = damage + ((netuserSTR+netuserLVL)*.3)
                    if (debugr == true) then  rust.BroadcastChat("Strength bonus added: " .. tostring(damage)) end
                    elseif (weaponType == "ranged" ) and (netuserAGI>0) then
                        damage = damage + ((netuserAGI+netuserLVL)*.3)
                    if (debugr == true) then  rust.BroadcastChat("Agility bonus added: " .. tostring(damage)) end
                    end

                    --Crit check
                    local diceRoll = math.random(0,100)
                    local diceRoll = math.random(0,100)
                    if (netuserAGI>0) then
                        if (weaponType == "melee") then
                            if (debugr == true) then rust.BroadcastChat("Dice Rolled!: " .. (tostring(netuserAGI+netuserLVL)*.002) .. " | " .. tostring(diceRoll)) end
                            if ((netuserAGI+netuserLVL)*.002 >= diceRoll) then
                                damage = damage * 2
                                rust.InventoryNotice( netuser, "Critical Hit!" )
                            end
                        elseif (weaponType == "ranged") then
                            if (debugr == true) then rust.BroadcastChat("Dice Rolled!: " .. (tostring(netuserAGI+netuserLVL)*.001) .. " | " .. tostring(diceRoll)) end
                            if ((netuserAGI+netuserLVL)*.001 >= diceRoll) then
                                damage = damage * 2
                                rust.InventoryNotice( netuser, "Critical Hit!" )
                            end
                        end
                    end
                    --Vic stamina modifier
                    dmg.amount = damage - ((self.Data.users[ vicuserID ].attributes.sta+self.Data.users[ vicuserID ].lvl)*.1)
                    if (debugr == true) then rust.BroadcastChat("Damage :" .. tostring(dmg.amount)) end
                    --PERK - STONESKIN
                    self:PerkStoneskin(dmg)
                    if (debugr == true) then rust.BroadcastChat("Adjusted to target damage after Stoneskin: " .. tostring(dmg.amount)) end
                    --END ADJUST ATTACKER DAMAGE
                end
            end
            if(isSamePlayer and self.Config.suicide) then
                --SUICIDE ACTION HERE
                return
            end
        end
        return dmg
    end
	local myString = takedamage.gameObject.Name
	npcController = {'ZombieController', 'BearAI', 'WolfAI', 'StagAI', 'BoarAI', 'ChickenAI', 'RabbitAI'}
	( function ()
        for i, npcController in ipairs(npcController) do
            if (takedamage:GetComponent( npcController )) then

        local netuser = dmg.attacker.client.netUser
        local netuserID = rust.GetUserID( netuser )
        if not self.Data.users[ netuserID ].skills[ weapon ] then
            self.Data.users[ netuserID ].skills[ weapon ] = {}
            self.Data.users[ netuserID ].skills[ weapon ].xp = 0
            self.Data.users[ netuserID ].skills[ weapon ].lvl = 0
        end
		local originalName = tostring(dmg.victim.networkView.name)
		local targetName = string.gsub(originalName, "%(Clone%)", "")
		local targetDmg = self.Config.npc[targetName].dmg
        local weaponDmg = self.Data.users[netuserID].skills[weapon].lvl*.3
        local weaponType = self.Config.weapon[ weapon ].type
        local netuserAGI = tonumber(self.Data.users[ netuserID ].attributes.agi)
        local netuserSTR = tonumber(self.Data.users[ netuserID ].attributes.str)
        local netuserLVL = tonumber(self.Data.users[ netuserID ].lvl)
        --Randomize damage
        local damage = math.random(tonumber(dmg.amount*.5),tonumber(dmg.amount))
        --Apply global victim damage modifier
        local damage = tonumber(damage * targetDmg)
        --Apply weapon skill bonus
        local damage = tonumber(damage + weaponDmg)
        if (debugr == true) then rust.BroadcastChat("Weapon skill bonus added: " .. tostring(damage)) end
        --Apply attribute modifiers
        if (weaponType == "melee") and (netuserSTR>0) then
            damage = damage + ((netuserSTR+netuserLVL)*.3)
            if (debugr == true) then rust.BroadcastChat("Strength bonus added: " .. tostring(damage)) end
        elseif (weaponType == "ranged" ) and (netuserAGI>0) then
            damage = damage + ((netuserAGI+netuserLVL)*.3)
            if (debugr == true) then rust.BroadcastChat("Agility bonus added: " .. tostring(damage)) end
        end
        --Crit check
        local diceRoll = math.random(0,100)
        local diceRoll = math.random(0,100)
        if (netuserAGI>0) then
            if (weaponType == "melee") then
                if (debugr == true) then rust.BroadcastChat("Dice Rolled!: " .. (tostring(netuserAGI+netuserLVL)*.002) .. " | " .. tostring(diceRoll)) end
                if ((netuserAGI+netuserLVL)*.002 >= diceRoll) then
                    damage = damage * 2
                    rust.InventoryNotice( netuser, "Critical Hit!" )
                end
            elseif (weaponType == "ranged") then
                if (debugr == true) then rust.BroadcastChat("Dice Rolled!: " .. (tostring(netuserAGI+netuserLVL)*.001) .. " | " .. tostring(diceRoll)) end
                if ((netuserAGI+netuserLVL)*.001 >= diceRoll) then
                    damage = damage * 2
                    rust.InventoryNotice( netuser, "Critical Hit!" )
                end
            end
        end

		dmg.amount = damage
        if (debugr == true) then rust.BroadcastChat("Adjusted to target damage: " .. tostring(dmg.amount)) end
        return end
        end
    end )()
	if (string.find(myString, "MaleSleeper(",1 ,true) and (dmg.attacker.client) and (dmg.attacker.client.netUser) and self.Config.settings.sleeperdppercent > 0) then
		if(sleepreId ~= nil) then
			--SLEEPER ACTION HERE
        end
    end
    --rust.BroadcastChat("THIS IS WHAT IM RETURNING: " .. tostring(math.ceil(tonumber(dmg.amount))))
    --return math.ceil(tonumber(dmg.amount))

end
function PLUGIN:PerkStoneskin(dmg)
    if ((dmg.victim.client) and (dmg.victim.client ~= dmg.attacker.client)) then
        local vicuser = dmg.victim.client.netUser
        local vicuserID = rust.GetUserID( vicuser )
        local vicuserStoneskin = self.Data.users[ vicuserID ].perks.Stoneskin.lvl
        if (vicuserStoneskin > 0) then
            if (vicuserStoneskin == 1) then
                dmg.amount = tonumber(dmg.amount - (dmg.amount*.05))
                if (debugr == true) then  rust.BroadcastChat("[PERK]: Stoneskin absorbed " .. tostring(dmg.amount*.05) .. " dmg!") end

                do return dmg end
            elseif (vicuserStoneskin == 2) then
                dmg.amount = tonumber(dmg.amount - (dmg.amount*.10))
                if (debugr == true) then  rust.BroadcastChat("[PERK]: Stoneskin absorbed " .. tostring(dmg.amount*.10) .. " dmg!") end
                do return dmg end
            elseif (vicuserStoneskin == 3) then
                dmg.amount = tonumber(dmg.amount - (dmg.amount*.15))
                if (debugr == true) then  rust.BroadcastChat("[PERK]: Stoneskin absorbed " .. tostring(dmg.amount*.15) .. " dmg!") end
                do return dmg end
            elseif (vicuserStoneskin == 4) then
                dmg.amount = tonumber(dmg.amount - (dmg.amount*.20))
                if (debugr == true) then  rust.BroadcastChat("[PERK]: Stoneskin absorbed " .. tostring(dmg.amount*.20) .. " dmg!") end
                do return dmg end
            elseif (vicuserStoneskin == 5) then
                dmg.amount = tonumber(dmg.amount - (dmg.amount*.25))
                if (debugr == true) then  rust.BroadcastChat("[PERK]: Stoneskin absorbed " .. tostring(dmg.amount*.25) .. " dmg!") end
                do return dmg end
            end
        end
    end
end
function PLUGIN:PerkParry(takedamage, dmg)
    if ((dmg.victim.client) and (dmg.victim.client ~= dmg.attacker.client)) then
        local vicuser = dmg.victim.client.netUser
        local vicuserID = rust.GetUserID( vicuser )
        local vicuserParry = self.Data.users[ vicuserID ].perks.Parry.lvl
        --PARRY
        if (vicuserParry > 0) then
            local parryRoll = math.random(0,100)
            local parryRoll = math.random(0,100)
            if ((vicuserParry == 1) and (parryRoll <= 3)) then
                dmg.amount = 0
                if (debugr == true) then  rust.BroadcastChat("[PERK]: You dodged the incoming attack! | 3 > " .. tostring(parryRoll)) end
                do return end
            elseif ((vicuserParry == 2) and (parryRoll <= 6)) then
                dmg.amount = 0
                if (debugr == true) then  rust.BroadcastChat("[PERK]: You dodged the incoming attack! | 6 > " .. tostring(parryRoll)) end
                do return end
            elseif ((vicuserParry == 3) and (parryRoll <= 9)) then
                dmg.amount = 0
                if (debugr == true) then  rust.BroadcastChat("[PERK]: You dodged the incoming attack! | 9 > " .. tostring(parryRoll)) end
                do return end
            elseif ((vicuserParry == 4) and (parryRoll <= 12)) then
                dmg.amount = 0
                if (debugr == true) then  rust.BroadcastChat("[PERK]: You dodged the incoming attack! | 12 > " .. tostring(parryRoll)) end
                do return end
            elseif ((vicuserParry == 5) and (parryRoll <= 15)) then
                dmg.amount = 0
                if (debugr == true) then  rust.BroadcastChat("[PERK]: You dodged the incoming attack! | 15 > " .. tostring(parryRoll)) end
                do return end
            end
        end
    end
end
-----------------------------
--PLUGIN:SysMsg | http://wiki.rustoxide.com/index.php?title=Rust/SendChatToUser
-----------------------------
function PLUGIN:UserMsg( netuser, msg )
    rust.RunClientCommand(netuser, "chat.add \"" .. self.Config.settings.sysname .. "\" \"" .. util.QuoteSafe(string.format(msg)) .. "\"" )
end
function PLUGIN:UserInvMsg( netuser, msg )
	rust.InventoryNotice( netuser, msg )
end
function PLUGIN:UserPopup( netuser, msg, seconds )
	if not seconds then local seconds = 3 end
	rust.Notice( netuser, msg, seconds )
end
function PLUGIN:SysMsg( netuser, msg )
	rust.BroadcastChat( self.Config.settings.sysname, msg )
end
-----------------------------
--PLUGIN:GiveXp
-----------------------------
function PLUGIN:GiveXp(netuser, xp, weapon)

    local netuserID = rust.GetUserID( netuser )
	local netuserDP = self.Data.users[ netuserID ].dp
	local netuserLVL = self.Data.users[ netuserID ].lvl
	local netuserXP = self.Data.users[ netuserID ].xp

	local weaponLVL = self.Data.users[ netuserID ].skills[ weapon ].lvl
	local weaponXP = self.Data.users[ netuserID ].skills[ weapon ].xp

	if (netuserDP>xp) then
		self.Data.users[ netuserID ].dp = netuserDP - xp
		self:UserInvMsg( netuser, "-" .. (netuserDP - xp) .. "dp" )
	elseif (netuserDP<=0) then
        self.Data.users[ netuserID ].xp = tonumber(netuserXP+xp)
		self.Data.users[ netuserID ].skills[ weapon ].xp = weaponXP + xp
		self:UserInvMsg( netuser, "+" .. xp .. "xp" )
		self:PlayerLvl(netuser, netuserID, netuserLVL, netuserXP, xp)
		self:WeaponLvl(netuser, netuserID, weaponLVL, weaponXP, weapon, xp)
    elseif( ( xp > netuserDP ) and (not (netuserDP <= 0 ))) then
		local xp = tonumber(xp-netuserDP)
		self.Data.users[ netuserID ].xp = tonumber(netuserXP+xp)
		self.Data.users[ netuserID ].skills[ weapon ].xp = weaponXP + xp
		self:UserInvMsg( netuser, "-" .. netuserDP .. "dp" )
		self:UserInvMsg( netuser, "+" .. xp .. "xp" )
		self.Data.users[ netuserID ].dp = 0
		self:PlayerLvl(netuser, netuserID, netuserLVL, netuserXP, xp)
		self:WeaponLvl(netuser, netuserID, weaponLVL, weaponXP, weapon, xp)
    end
    self:DataSave()
end
-----------------------------
--PLUGIN:GiveDp
-----------------------------
function PLUGIN:GiveDp(vicuser, dp)

    local vicuserID = rust.GetUserID( vicuser )
    local vicuserDP = self.Data.users[ vicuserID ].dp
    local vicuserXP = self.Data.users[ vicuserID ].xp

    if ((vicuserDP+dp/vicuserXP) >= .5) then
        
        self.Data.users[ vicuserID ].dp = vicuserXP*.5
        self:UserInvMsg( vicuser, "+" .. (dp - vicuserXP*.5) .. "dp" )
    else
        self.Data.users[ vicuserID ].dp = vicuserDP + dp
        self:UserInvMsg( vicuser, "+" .. (dp) .. "dp" )
    end
    self:DataSave()
end
-----------------------------
--PLUGIN:PlayerLvl
-----------------------------
function PLUGIN:PlayerLvl(netuser, netuserID, netuserLVL, netuserXP, xp)
	local netuserLVLx = math.floor((math.sqrt(100*((self.Config.settings.lvlmodifier*(netuserXP+xp))+25))+50)/100)
	if (netuserLVLx ~= netuserLVL) then
		self.Data.users[ netuserID ].lvl = netuserLVLx
		self:UserPopup( netuser, "You are now level " .. netuserLVLx .. "!", 5 )
	end
end
-----------------------------
--PLUGIN:WeaponLvl
-----------------------------
function PLUGIN:WeaponLvl(netuser, netuserID, weaponLVL, weaponXP, weapon, xp)
	local weaponLVLx = math.floor((math.sqrt(100*((self.Config.settings.weaponlvlmodifier*(weaponXP+xp))+25))+50)/100)
	if (weaponLVLx ~= weaponLVL) then
		self.Data.users[ netuserID ].skills[ weapon ].lvl = weaponLVLx
        timer.Once( 5, function()  self:UserPopup( netuser, "Your skill level has increased!", 5 ) end )
	end
end
-----------------------------
--PLUGIN:SetDpPercent
-----------------------------
function PLUGIN:SetDpPercent(netuser, percent)
    self:SetDpPercentById(rust.GetUserID( netuser ) ,percent )
    if (percent >= 0 and percent <= 100) then
        --[[rust.SendChatToUser( netuser, self:printmoney(netuser) )--]] 
	end
end

-----------------------------
--PLUGIN:SetDpPercentById
-----------------------------
function PLUGIN:SetDpPercentById(netuserID, percent)
    if (percent >= 0 and percent <= 100) then
        if (percent == 0) then
            self.Data.users[netuserID].dp = math.floor(self.Data.users[netuserID].dp + self.Data.users[netuserID].xp)
        else
            self.Data.users[netuserID].dp = math.floor(self.Data.users[netuserID].dp + (self.Data.users[netuserID].xp * percent / 100))
        end
        self:DataSave()
    end
end

-----------------------------
--PLUGIN:SleeperPos
-----------------------------
function PLUGIN:SleeperPos(point)
    for key,value in pairs(self.Config.sleepers.pos) do
        if (self:SleeperRadius(value,point,tonumber(self.Config.settings.sleeperradius))) then
            return key   
		end 
	end
end

-----------------------------
--PLUGIN:SleeperRadius
-----------------------------
function PLUGIN:SleeperRadius(pos, point, rad)
	return (pos.x < point.x + rad and pos.x > point.x - rad)
	and (pos.y < point.y + rad and pos.y > point.y - rad)
	and (pos.z < point.z + rad and pos.z > point.z - rad)
end

-----------------------------
--PLUGIN:SetDefaultConfig
-----------------------------
function PLUGIN:SetDefaultConfig()


		self.Config.npc.ZombieNPC_SLOW = {}
			self.Config.npc.ZombieNPC_SLOW.id =  "ZombieNPC_SLOW"
			self.Config.npc.ZombieNPC_SLOW.ctrl =  "ZombieController"
			self.Config.npc.ZombieNPC_SLOW.name=  "Slow Zombie"
			self.Config.npc.ZombieNPC_SLOW.xp = 45
			self.Config.npc.ZombieNPC_SLOW.dmg =.25

		self.Config.npc.ZombieNPC_FAST = {}
			self.Config.npc.ZombieNPC_FAST.id = "ZombieNPC_FAST"
			self.Config.npc.ZombieNPC_FAST.ctrl = "ZombieControlller"
			self.Config.npc.ZombieNPC_FAST.name=  "Fast Zombie"
			self.Config.npc.ZombieNPC_FAST.xp = 40
			self.Config.npc.ZombieNPC_FAST.dmg = .25

		self.Config.npc.ZombieNPC = {}
			self.Config.npc.ZombieNPC.id = "ZombieNPC"
			self.Config.npc.ZombieNPC.ctrl = "ZombieController"
			self.Config.npc.ZombieNPC.name = "Zombie"
			self.Config.npc.ZombieNPC.xp = 35
			self.Config.npc.ZombieNPC.dmg = .25

		self.Config.npc.MutantBear = {}
			self.Config.npc.MutantBear.id = "MutantBear"
			self.Config.npc.MutantBear.ctrl = "BearAI"
			self.Config.npc.MutantBear.name = "Mutant Bear"
			self.Config.npc.MutantBear.xp = 30
			self.Config.npc.MutantBear.dmg =.25

		self.Config.npc.MutantWolf = {}
			self.Config.npc.MutantWolf.id = "MutantWolf"
			self.Config.npc.MutantWolf.ctrl = "WolfAI"
			self.Config.npc.MutantWolf.name = "Mutant Wolf"
			self.Config.npc.MutantWolf.xp = 25
			self.Config.npc.MutantWolf.dmg =.15

		self.Config.npc.Bear = {}
			self.Config.npc.Bear.id = "Bear"
			self.Config.npc.Bear.ctrl = "BearAI"
			self.Config.npc.Bear.name = "Bear"
			self.Config.npc.Bear.xp = 20
			self.Config.npc.Bear.dmg =.35

		self.Config.npc.Wolf = {}
			self.Config.npc.Wolf.id = "Wolf"
			self.Config.npc.Wolf.ctrl = "WolfAI"
			self.Config.npc.Wolf.name = "Wolf"
			self.Config.npc.Wolf.xp = 15
			self.Config.npc.Wolf.dmg =.25

		self.Config.npc.Stag_A = {}
			self.Config.npc.Stag_A.id = "Stag_A"
			self.Config.npc.Stag_A.ctrl = "StagAI"
			self.Config.npc.Stag_A.name = "Stag"
			self.Config.npc.Stag_A.xp = 10
			self.Config.npc.Stag_A.dmg =.50

		self.Config.npc.Boar_A = {}
			self.Config.npc.Boar_A.id = "Boar_A"
			self.Config.npc.Boar_A.ctrl = "BoarAI"
			self.Config.npc.Boar_A.name = "Boar"
			self.Config.npc.Boar_A.xp = 10
			self.Config.npc.Boar_A.dmg =.50

		self.Config.npc.Chicken = {}
			self.Config.npc.Chicken.id = "Chicken"
			self.Config.npc.Chicken.ctrl = "ChickenAI"
			self.Config.npc.Chicken.name = "Chicken"
			self.Config.npc.Chicken.xp = 5
			self.Config.npc.Chicken.dmg = 1

		self.Config.npc.Rabbit = {}
			self.Config.npc.Rabbit.id = "Rabbit"
			self.Config.npc.Rabbit.ctrl = "RabbitAI"
			self.Config.npc.Rabbit.name = "Rabbit"
			self.Config.npc.Rabbit.xp = 5
			self.Config.npc.Rabbit.dmg = 1

        self.Config.weapon[ "9mmPistol" ] =  {}
            self.Config.weapon[ "9mmPistol" ].type = "ranged"

        self.Config.weapon[ "M4" ] =  {}
            self.Config.weapon[ "M4" ].type = "ranged"

        self.Config.weapon[ "ExplosiveCharge" ] =  {}
            self.Config.weapon[ "ExplosiveCharge" ].type = "explosive"

		self.Config.settings.dppercent = 5
		self.Config.settings.pkxppercent = 5
		self.Config.settings.sleeperxppercent = 5 --try to keep this >= the dp percent to prevent exploiting to power level
		self.Config.settings.sleerperdppecent = 5
		self.Config.settings.sleeperradius = 2
		self.Config.settings.lvlmodifier = 2 -- 1 is high, 2 is normal (wouldn't recommend changing this too much. perhaps change the xp the npc's give would be better)
		self.Config.settings.weaponlvlmodifier = 1.5
		self.Config.settings.xpmodifier = 1 -- multiplies values of npc xp given. (ie; 2 = 2x npc reward)
		self.Config.settings.sysname = "-"

    self:ConfigSave()
end




-----------------------------
--PLUGIN:OnUserConnect | http://wiki.rustoxide.com/index.php?title=Hooks/OnUserConnect
-----------------------------
function PLUGIN:OnUserConnect( netuser )
    local data = self:GetUserData( netuser ) -- asks for dat.
end

-----------------------------
--PLUGIN:GetUserData
-----------------------------
function PLUGIN:GetUserData( netuser )
    local netuserID = rust.GetUserID( netuser )
    local data = self.Data.users[ netuserID ] -- checks if data exist
    if (not data) then -- if not, creates one
        data = {}
        data.id = netuserID
        data.name = name
        data.lvl = 1
        data.xp = 0
        data.pp = 0
        data.dp = 0
        data.dmg = 1 --global damage modifier per player 1 = 100% of dmg.amount
        data.attributes = {}
        data.attributes.str = 0 --Damage Bonus Melee = (strength+level)*.3
        data.attributes.agi = 0 --Damage Bonus Ranged = (agility+level)*.3 | Chance to crit ranged = ((agi+lvl)*.001) | Chance to crit melee = ((agi+lvl)*.002)
        data.attributes.sta = 0 --Negates Any Damage Taken = (sta+level)*.1
        data.attributes.int = 0 --Chance to craft/research = (int*5)+(level*.3)
        data.skills = {}
        local skill = {"9mmPistol", "ExplosiveCharge", "F1Grenade", "HandCannon", "Hatchet", "HuntingBow", "M4", "MP5A4", "P250", "PickAxe", "PipeShotgun", "Revolver", "Rock", "Shotgun", "StoneHatchet"}
        for i, skill in ipairs(skill) do
            data.skills[ skill ] = {}
            data.skills[ skill ].xp = 0
            data.skills[ skill ].lvl = 0
        end

        data.perks = {}
        local perk = {"Parry", "Stoneskin"}
        for i, perk in ipairs(perk) do
            data.perks[ perk ] = {}
            data.perks[ perk ].lvl = 0
        end
        self.Data.users[ netuserID ] = data
        self:DataSave()
    end
    return data
end
function PLUGIN:ConfigSave()
    self.ConfigFile:SetText( json.encode( self.Config, { indent = true } ) )
    self.ConfigFile:Save()
    self:ConfigUpdate()
end

function PLUGIN:DataSave()
    self.DataFile:SetText( json.encode( self.Data, { indent = true } ) )
    self.DataFile:Save()
    self:DataUpdate()
end

function PLUGIN:ConfigUpdate()
    self.ConfigFile = util.GetDatafile( "carbon_cfg" )
    local txt = self.ConfigFile:GetText()
    self.Config = json.decode ( txt )
end

function PLUGIN:DataUpdate()
    self.DataFile = util.GetDatafile( "carbon_dat" )
    local txt = self.DataFile:GetText()
    self.Data = json.decode ( txt )
end

--api.Call( "economy", "takeMoneyFrom", netuser, value )