PLUGIN.Title = 'carbon_sandbox'
PLUGIN.Description = 'sandbox module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()

    core = cs.findplugin("carbon_core") core:LoadLibrary()

    self:AddChatCommand('x', self.x)
    self:AddChatCommand( 'alpha', self.AlphaTXT )
    self:AddChatCommand( 'help', self.cmdHelp )
    self:AddChatCommand( 'storm', self.cmdStorm )
    self:AddChatCommand( 'sandbox', self.Sandbox )

    self:AddChatCommand( 'v', self.ControllerProbe )

end
function PLUGIN:sandbox(netuser,cmd, args)

    local controllable = netuser.playerClient.controllable
    local character = controllable:GetComponent( "Character" )
    local inv = controllable:GetComponent( "Inventory" )
    local pinv = controllable:GetComponent( "PlayerInventory" )
    local nu = controllable:GetComponent( "NetUser" )
    local bp = controllable:GetComponent( "Blueprint" )
    local asr = controllable:GetComponent("AvatarSaveRestore")

    local avi = netuser:LoadAvatar()

    recycler = avi:avatar.Recycler()
    builder = avi:recycler.OpenBuilder()
    avi:character.GetLocal:PlayerInventory().SaveToAvatar(builder)
    avi:character.netUser.SaveAvatar(builder.Build())

    local avatar = asr:LoadAvatar()
    avatar:ClearAvatar()
    avatar:ShutdownAvatar(true)
    avatar:ClearInventory()
    avatar:ClearBlueprints()
    avatar:SaveAvatar()
    --[[
    local count = avatar.BlueprintsCount
    rust.SendChatToUser( netuser, ' ', tostring(count))
    local num = 0
    while num < avatar.BlueprintsCount do
        local blueprint = avatar:GetBlueprints(num)
        rust.BroadcastChat( tostring(blueprint))
        num = num + 1
    end
    local count = avatar.BlueprintsCount
    rust.SendChatToUser( netuser, ' ', tostring(count))

    --rust.BroadcastChat('Crouched : ' .. tostring(char.crouchable.crouched)) -- Shows 0

    --local avatar = netuser:LoadAvatar()
    --local builder = avatar:ToBuilder()

    local idMain = char.idMain
    --
    local avatar = netuser:LoadAvatar()
    local count = avatar.BlueprintsCount rust.BroadcastChat('local avatar = netuser:LoadAvatar(): ' .. tostring(count)) --shows 45


    local builder = avatar:ToBuilder()
    local count = builder.BlueprintsCount rust.BroadcastChat('local builder = avatar:ToBuilder(): ' .. tostring(count)) --shows 45

    builder:ClearBlueprints()
    builder:ClearInventory()
    local count = builder.BlueprintsCount rust.BroadcastChat('builder:ClearBlueprints(): ' .. tostring(count)) -- shows 0

    avatar = builder:Build()
    local count = avatar.BlueprintsCount rust.BroadcastChat('avatar = builder:Build(): ' .. tostring(count)) -- Shows 0

    netuser:SaveAvatar(avatar)
   local count = avatar.BlueprintsCount rust.BroadcastChat('netuser:SaveAvatar(avatar): ' .. tostring(count)) -- Shows 0

    local newavatar = netuser:LoadAvatar()
    local count = newavatar.BlueprintsCount rust.BroadcastChat('newavatar:ParseFrom(avatar): ' .. tostring(count)) -- Shows 0

    netuser:SaveAvatar(newavatar)
    avatar = netuser:LoadAvatar()

    local count = avatar.BlueprintsCount rust.BroadcastChat('avatar = netuser:LoadAvatar(): ' .. tostring(count)) -- Shows 0


    rust.SendChatToUser( netuser, ' ', tostring(char.blueprints_))

--]]
end




function PLUGIN:ControllerProbe(netuser, cmd, args)
    if (#args==0) then
        local validate, vicuser = rust.FindNetUsersByName( args[1] )
        if (not validate) then
            if (vicuser == 0) then
                print( "No player found with that name: " .. tostring( args[1] ))
            else
                print( "Multiple players found with name: " .. tostring( args[1] ))
            end
            return false
        end
    end
    
    --local controllable = vicuser.playerClient.controllable
    local controllable = netuser.playerClient.controllable
    local Character = controllable:GetComponent( "Character" )
    local IDLocalCharacter = char.idMain:GetComponent( "IDLocalCharacter" )
    local Inventory = controllable:GetComponent( "Inventory" )
    local PlayerInventory = controllable:GetComponent( "PlayerInventory" )
    local NetUser = controllable:GetComponent( "NetUser" )
    local Blueprint = controllable:GetComponent( "Blueprint" )
    local AvatarSaveRestore = controllable:GetComponent("AvatarSaveRestore")

    local HumanBodyTakeDamage = controllable:GetComponent("HumanBodyTakeDamage")
    local Metabolism = controllable:GetComponent("Metabolism")
    local EquipmentWearer = controllable:GetComponent("EquipmentWearer")
    local FallDamage = controllable:GetComponent("FallDamage")

    --rust.GetInventory( netuser )
    --local b, item = inv:GetItem( 30 )
    --print(tostring(item.datablock))
    --idchar:set_lockLook(true)
    --idchar:set_lockMovement(true)
    --rust.SendChatToUser(netuser, tostring(idchar.lockMovement))
    --rust.SendChatToUser(netuser, tostring(idchar.lockLook))

    
    
end
function PLUGIN:test( netuser, cmd, args)

    local avatar = netuser:LoadAvatar()
  local builder = avatar:ToBuilder()
    rust.BroadcastChat('before: ')
    local count = builder.BlueprintsCount
    rust.BroadcastChat( tostring( count ))
    builder:ClearBlueprints()
    rust.BroadcastChat('after: ')
    local count = builder.BlueprintsCount
    rust.BroadcastChat(tostring( count ))
    loadout._defaultBlueprints = nil
    local avatar = asr:LoadAvatar()
    avatar:ClearAvatar()
    avatar:ShutdownAvatar(true)
    avatar:ClearInventory()
    avatar:ClearBlueprints()
    avatar:SaveAvatar()

end


--PLUGIN:cmdStorm
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

--PLUGIN: cmdHelp
function PLUGIN:cmdHelp( netuser, cmd, args)
    if not args[1] then
        local content = {
            ['prefix']='The Carbon Project',
            ['msg'] ='Welcome to The Carbon Project! \n Carbon RPG is a plugin that allows Rust to be played as a MMORPG.' ..
                    '\n Carbon RPG has a lot of features. With the /help you\'re able to find some of the info about most of the features. \n' ..
                    '\nAt the top of each informational screen you will see a pseudo breadcrumb trail intended to ' ..
                    'help you with cmd navigation by displaying parent command, and the child cmds on the bottom.',
            ['cmds']={'features','gameplay','professions','guilds','perks','calls','economy','party','events','bosses','donation','authors'},
            ['suffix']='For more info: www.tempusforge.com'
        }
        func:TextBox(netuser,content,cmd,args) return
    elseif( args[1] == 'features' ) then
        local content = {
            ['msg'] ='There are a lot of features included in Carbon RPG, and a lot more to come! \nHere is a list of the current features.',
            ['list'] = {'- guilds','- perks','- calls','- attributes','- professions','- gun progression','- mail system','- whisper system','- lighting storms','- and loads more!'},
            ['suffix']='More information about these features are found on: www.tempusforge.com'
        }
        func:TextBox(netuser,content,cmd,args) return
    elseif( args[1] == 'gameplay' ) then
        local content = {
            ['msg'] ='Carbon RPG is all about progression! \n Character progression, profession progression, ' ..
                    'weapon unlocks, crafting unlocks, managing the most vicious, helpfull or economic guild, ' ..
                    'unlock perks, unlock calls or create a party to hunt bosses! To progress you\'ll need to craft, slay chickens ' ..
                    'earn money, learn new recipes, slay some more chickens or maybe the occasional rabbit, ' ..
                    'build a huge castle to protect you from the demons. Wait... what?',
            ['suffix']='/c to check your progression'
        }
        func:TextBox(netuser,content,cmd,args) return
    elseif( args[1] == 'professions' ) then
        local content = {
            ['msg'] ='Professions are used to unlock new crafting recipes! Different items have different profession level requirements.' ..
                    '\nWhen having a low Carpenter level you\'ll fail a lot trying to craft building components. The higher your Carpenter level ' ..
                    'the more chance to trigger a critical craft. This will grant you twice the result item and will be instant! ' ..
                    'Yea we\'re not that evil, are we? \n Here\'s a list of available professions:',
            ['list'] = {'- Munitions Engineer','- Medic ( Post-Alpha )','- Carpenter','- Armorsmith','- Weaponsmith'},
            ['suffix']='/c prof to check all your professions statistics'
        }
        func:TextBox(netuser,content,cmd,args) return
    elseif( args[1] == 'guilds' ) then
        local netuserID = rust.GetUserID( netuser )
        local req = 'CareX: "Yea dude, to bad you need a level 10 character to start a guild!"'
        if char.User[ netuserID ].lvl >= 10 then req = 'CareX: "Yea brah, go start your own guild now! Only 25 silver! And reign the solar system with your lightsaber..."' end
        local content = {
            ['msg'] ='Guilds? Hell yea! Mischa: "Sooooo... w-w-what can I do... n-n-now we have guilds?" CareX: "Well good sir, you can ' ..
                    'slay chickens together, make your own guild house, which everyone in the guild can access ofcourse. ' ..
                    'unlock guild calls and.. " Mischa: "Sir, what are guild calls?" CareX: "This my son, are buffs for your whole guild! ' ..
                    'Let me quickly explain; So you got your standerd buffs from your perks right?" Mischa: "y-y-eah... I guess so" ' ..
                    'CareX: "So when we activate our, lets say, Rally call, the whole guild gets a damage buff to rival guild members." ' ..
                    'Mischa: "n-n-noo way..." ' .. req,
            ['list'] = {},
            ['cmds']={},
            ['suffix']='/g to check all the guild info'
        }
        func:TextBox(netuser,content,cmd,args) return
    elseif( args[1] == 'perks' ) then
    elseif( args[1] == 'calls' ) then
    elseif( args[1] == 'economy' ) then
    elseif( args[1] == 'party' ) then
    elseif( args[1] == 'events' ) then
    elseif( args[1] == 'bosses' ) then
    elseif( args[1] == 'donation' ) then
    elseif( args[1] == 'authors' ) then

    else

    end
end

-- TEMPORARY PLUGIN FOR INVISIBILITY GEAR
function PLUGIN:x( netuser, cmd, args )
    local helmet = rust.GetDatablockByName( 'Invisible Helmet' )
    local vest = rust.GetDatablockByName( 'Invisible Vest' )
    local pants = rust.GetDatablockByName( 'Invisible Pants' )
    local boots = rust.GetDatablockByName( 'Invisible Boots' )
    local pref = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor )
    local inv = rust.GetInventory( netuser )
    local invitem1 = inv:AddItemAmount( helmet, 1, pref )
    local invitem2 = inv:AddItemAmount( vest, 1, pref )
    local invitem3 = inv:AddItemAmount( pants, 1, pref )
    local invitem4 = inv:AddItemAmount( boots, 1, pref )
end

--PLUGIN:OnUserChat
function PLUGIN:AlphaTXT( netuser )
    rust.SendChatToUser(netuser,' ',' ')
    rust.SendChatToUser(netuser,self.Chat,'╔════════════════════════')
    rust.SendChatToUser(netuser,self.Chat,'║ login > Alpha Message')
    rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
    rust.SendChatToUser(netuser,self.Chat,'║ The Carbon Project [ Version ' .. tostring(self.Version) .. ' ]' )
    rust.SendChatToUser(netuser,self.Chat,'║ Copyright (c) 2014 Tempus Forge. All rights reserved.')
    rust.SendChatToUser(netuser,self.Chat,'║ -- to view this message again, type /alpha -- ')
    rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
    rust.SendChatToUser(netuser,self.Chat,'║ Welcome to "The Carbon Project" Alpha test!')
    rust.SendChatToUser(netuser,self.Chat,'║ Carbon RPG is a game with a dynamic leveling system, ')
    rust.SendChatToUser(netuser,self.Chat,'║ Professions, Skills, Perks, Calls, Guilds, Party( coming soon ), ')
    rust.SendChatToUser(netuser,self.Chat,'║ Random events( coming soon )and boss mobs( coming soon ).')
    rust.SendChatToUser(netuser,self.Chat,'║ Use /c for global information. Use /g for guild commands.')
    rust.SendChatToUser(netuser,self.Chat,'║ ')
    rust.SendChatToUser(netuser,self.Chat,'║ Take a look around, for more information visit: www.tempusforge.com')
    rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
    rust.SendChatToUser(netuser,self.Chat,'║ Disclaimer: This is an ALPHA test, there will be bugs, there will be crashes,')
    rust.SendChatToUser(netuser,self.Chat,'║ there will be restarts and there will be wipes.')
    rust.SendChatToUser(netuser,self.Chat,'╟────────────────────────')
    rust.SendChatToUser(netuser,self.Chat,'║ ⌘ Created by: Mischa & CareX ')
    rust.SendChatToUser(netuser,self.Chat,'╚════════════════════════')
    rust.SendChatToUser(netuser,' ',' ')
end