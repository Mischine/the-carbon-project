PLUGIN.Title = 'carbon_util'
PLUGIN.Description = 'utilities module'
PLUGIN.Version = '0.0.2'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
    self:AddChatCommand( 'poison', self.Poison )
    self:AddChatCommand( 'injure', self.Injure )
    self:AddChatCommand( 'antirad', self.AntiRad )
    self:AddChatCommand( 'rad', self.Rad )
    self:AddChatCommand( 'bleed', self.Bleed )
    self:AddChatCommand( 'hot', self.HealOverTime )
    self:AddChatCommand( 'reflect', self.Reflect )
    self:AddChatCommand( 'calories', self.Calories )
    self:AddChatCommand( 'bandage', self.Bandage )
    self:AddChatCommand( 'hurt', self.Hurt )
    self:AddChatCommand( 'takeover', self.TakeOver )
    self:AddChatCommand( 'repair', self.cmdRepair )
    self:AddChatCommand( 'dev', self.isDev )

    self.spamNet = {} --used to prevent spammed messages to a user.
    self.SquareRoot = math.sqrt
end
--Util
--------------------------------------------------------------------------------------------------
function PLUGIN:TextBox(netuser, content, cmd, args)
    if content.prefix then content.prefix = self:WordWrap(content.prefix, 50) end
    --if content.breadcrumbs then content.breadcrumbs = self:WordWrap(content.breadcrumbs, 50) end
    if content.header then content.header = self:WordWrap(content.header, 50) end
    if content.subheader then content.subheader = self:WordWrap(content.subheader, 50) end
    if content.msg then content.msg = self:WordWrap(content.msg, 50) end
    --if content.cmds then content.cmds = self:WordWrap(content.cmds, 50) end
    if content.suffix then content.suffix = self:WordWrap(content.suffix, 50) end
    if content.prefix then
        rust.SendChatToUser(netuser,core.sysname,' ')
        rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
        for _,v in ipairs(content.prefix) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    else
        rust.SendChatToUser(netuser,core.sysname,' ')
        rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
    end
    rust.SendChatToUser(netuser,core.sysname,'║ ' .. cmd .. ' > ' .. table.concat(args, ' > '))
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    if content.header or content.subheader then
        if content.header then for _,v in ipairs(content.header) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end end
        if content.subheader then for _,v in ipairs(content.subheader) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end end
        rust.SendChatToUser(netuser,core.sysname,'╟­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­')
    end
    if content.msg then for _,v in ipairs(content.msg) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end end
    if content.list then for _,v in ipairs(content.list) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end end
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    if content.cmds then rust.SendChatToUser(netuser,core.sysname,'║ ► ' .. table.concat(content.cmds, '     ► ')) else
        rust.SendChatToUser(netuser,core.sysname,'║ ') end
    if content.suffix then
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
        for _,v in ipairs(content.suffix) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end
        rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,core.sysname,' ')
    else
        rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,core.sysname,' ')
    end
    content = {}
end
function PLUGIN:TextBoxError(netuser, content, cmd, args)
    if content.prefix then content.prefix = self:WordWrap(content.prefix, 50) end
    --if content.breadcrumbs then content.breadcrumbs = self:WordWrap(content.breadcrumbs, 50) end
    if content.header then content.header = self:WordWrap(content.header, 50) end
    if content.subheader then content.subheader = self:WordWrap(content.subheader, 50) end
    if content.msg then content.msg = self:WordWrap(content.msg, 50) end
    --if content.cmds then content.cmds = self:WordWrap(content.cmds, 50) end
    if content.suffix then content.suffix = self:WordWrap(content.suffix, 50) end
    if content.prefix then
        rust.SendChatToUser(netuser,core.sysname,' ')
        rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
        for _,v in ipairs(content.prefix) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    else
        rust.SendChatToUser(netuser,core.sysname,' ')
        rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
    end
    rust.SendChatToUser(netuser,core.sysname,'║ ' .. cmd .. ' > ' .. table.concat(args, ' > ') .. ' > ϟ error')
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    if content.header or content.subheader then
        if content.header then for _,v in ipairs(content.header) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end end
        if content.subheader then for _,v in ipairs(content.subheader) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end end
        rust.SendChatToUser(netuser,core.sysname,'╟­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­')
    end
    if content.msg then for _,v in ipairs(content.msg) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end
    elseif content.list then for _,v in ipairs(content.list) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end
    else rust.SendChatToUser(netuser,core.sysname,'║ Sacrebleu! Something went wrong.. .') end
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    if content.cmds then rust.SendChatToUser(netuser,core.sysname,'║ ► ' .. table.concat(content.cmds, '     ► ')) else
        rust.SendChatToUser(netuser,core.sysname,'║ ') end
    if content.suffix then
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
        for _,v in ipairs(content.suffix) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. tostring(v)) end
        rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,core.sysname,' ')
    else
        rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,core.sysname,' ')
    end
    rust.InventoryNotice(netuser, 'Sacrebleu!')
    content = {}
end
--WordWrap(str, int)
function PLUGIN:WordWrap(strText, intMaxLength)
    local tblOutput = {}
    local intIndex
    local strBuffer = ""
    local tblLines = self:Explode(strText, "\n")
    for k, strLine in pairs(tblLines) do
        local tblWords = self:Explode(strLine, " ")
        if (#tblWords > 0) then
            intIndex = 1
            while tblWords[intIndex] do
                local strWord = " " .. tblWords[intIndex]
                if (strBuffer:len() >= intMaxLength) then
                    table.insert(tblOutput, strBuffer:sub(1, intMaxLength))
                    strBuffer = strBuffer:sub(intMaxLength + 1)
                else
                    if (strWord:len() > intMaxLength) then
                        strBuffer = strBuffer .. strWord
                    elseif (strBuffer:len() + strWord:len() >= intMaxLength) then
                        table.insert(tblOutput, strBuffer)
                        strBuffer = ""
                    else
                        if (strBuffer == "") then
                            strBuffer = strWord:sub(2)
                        else
                            strBuffer = strBuffer .. strWord
                        end
                        intIndex = intIndex + 1
                    end
                end
            end
            if (strBuffer ~= "") then
                table.insert(tblOutput, strBuffer)
                strBuffer = ""
            end
        end
    end
    return tblOutput
end
function PLUGIN:Explode(strText, strDelimiter)
    local strTemp = ""
    local tblOutput = {}
    for intIndex = 1, strText:len(), 1 do
        if (strText:sub(intIndex, intIndex + strDelimiter:len() - 1) == strDelimiter) then
            table.insert(tblOutput, strTemp)
            strTemp = ""
        else
            strTemp = strTemp .. strText:sub(intIndex, intIndex)
        end
    end
    if (strTemp ~= "") then
        table.insert(tblOutput, strTemp)
    end
    return tblOutput
end
function PLUGIN:containsval(t,cv) for _, v in ipairs(t) do if v == cv then return true end end return nil end
function PLUGIN:containskey(t,cv) for k, _ in ipairs(t) do if k == cv then return true end end return nil end
function PLUGIN:count( table ) local i = 0 for k, v in pairs( table ) do i = i + 1 end return i end
function PLUGIN:sayTable( table, sep ) local msg = '' local count = #table if( count <= 0 ) then return 'N/A' end local i = true
for k, v in ipairs( table ) do if( i ) then msg = msg .. v i = false else msg = msg .. (sep .. v) end end msg = msg .. '.' return msg end
function PLUGIN:returnvalues( table ) if( not table ) then return false end local msg = '' for k,v in pairs( table ) do msg = msg .. '[ ' .. v .. ' ]' end return msg end
function PLUGIN:CheckBodyPart(a,b)for c,d in pairs(b)do if string.find(a,d)then return true end end end
function PLUGIN:Notice(netuser,prefix,text,duration)
    Rust.Rust.Notice.Popup( netuser.networkPlayer, prefix or " ", text .. '      ', duration or 4.0 )
end

function PLUGIN:isDev( netuser )
	local SteamID = rust.CommunityIDToSteamID( tonumber( rust.GetUserID( netuser ) ) )
	if SteamID == 'STEAM_0:1:36236335' or SteamID == 'STEAM_0:0:25828468' then return true else return false end
end

--PLUGIN:findIDByName
function PLUGIN:findIDByName( name )
    for k,v in pairs( char ) do
        if ( v.name == name ) then return k end
    end
    return false
end

function PLUGIN:xpbar( value, size )
    local msg = ''
    for i=1, size do
        if(value / (100/size) >= i ) then
            msg = msg .. '■'
        else
            msg = msg .. '□'
        end
    end
    return msg
end

function PLUGIN:GetTimeMilliSeconds()
    local epoch = System.DateTime.Parse[1]( "1970-01-01 00:00:00" ):ToLocalTime()
    local now = System.DateTime.Now
    local unix = now:Subtract( epoch )
    return unix.TotalMilliSeconds
end

function PLUGIN:Roll(a,b,c)
    local d=self:GetTimeMilliSeconds()
    math.randomseed(d)
    local result = 0
    if not c then
        result=math.random(b)
    else
        result=math.random(b,c)
    end
    if a then
        return math.floor((result)+0.5)
    else
        return result
    end
end
function PLUGIN:FindNetUserById(netuserID)
	local findUserName
	rust.BroadcastChat('searching..')
	if char[tostring(netuserID)].name then
		findUserName = char[tostring(netuserID)].name
	elseif not findUserName then
		if core.Reg[tostring(netuserID)] then
			findUserName = core.Reg[tostring(netuserID)]
		end
	end
	local validate, findUser = rust.FindNetUsersByName( findUserName )
	if (not validate) then
		if (findUser == 0) then
			print( "No player found with that name: " .. tostring( findUser ))
		else
			print( "Multiple players found with name: " .. tostring( findUser ))
		end
		return false
	end
	return findUser
end
-- DATA UPDATE AND SAVE
function PLUGIN:Save(name, dir)
	print('Saving: ' .. name)
	self[name ..'File']:SetText( json.encode( self[name], { indent = true } ) )
	self[name ..'File']:Save()
end
function PLUGIN:Load(filename)
		self.ConfigFile = util.GetDatafile( 'carbon_cfg' )
	local cfg_txt = self.ConfigFile:GetText()
	if (cfg_txt ~= '') then
		print( 'Carbon cfg file loaded!' )
		self.Config = json.decode( cfg_txt )
	else
		print( 'Creating carbon cfg file...' )
		self:SetDefaultConfig()
	end
end

-- Returns the distance between two 3 dimensional points
function PLUGIN:Distance3D ( x1, y1, z1, x2, y2, z2 )
	local xd = x2 - x1
	local yd = y2 - y1
	local zd = z2 - z1
	return self.SquareRoot( xd * xd + yd * yd + zd * zd )
end
-------------------------------------------------------------------------------
-- NEW FUNCTIONS
function PLUGIN:Poison(netuser, cmd, args)
    local validate, vicuser = rust.FindNetUsersByName( args[1] )
    if (not validate) then
        if (vicuser == 0) then
            print( "No player found with that name: " .. tostring( args[1] ))
        else
            print( "Multiple players found with name: " .. tostring( args[1] ))
        end
        return false
    end
    local controllable = vicuser.playerClient.controllable
    local this = controllable:GetComponent("Metabolism")

    if args[3] and args[2] == 'remove' and this:IsPoisoned() then
        this:SubtractPosion(tonumber(args[3]))
    elseif args[3] and args[2] == 'add' and not this:IsPoisoned() then
        this:AddPoison(tonumber(args[3]))
	    this:Vomit()
    elseif not args[3] and args[2] == 'check'  then
        rust.SendChatToUser(netuser,tostring( this:IsPoisoned() ))
    end
end
function PLUGIN:AntiRad(netuser, cmd, args)
    local validate, vicuser = rust.FindNetUsersByName( args[1] )
    if (not validate) then
        if (vicuser == 0) then
            print( "No player found with that name: " .. tostring( args[1] ))
        else
            print( "Multiple players found with name: " .. tostring( args[1] ))
        end
        return false
    end
    local controllable = vicuser.playerClient.controllable
    local this = controllable:GetComponent("Metabolism")

    if args[3] and args[2] == 'add' then
        this:AddAntiRad(tonumber(args[3]))
    end

end
function PLUGIN:Rad(netuser, cmd, args)
    local validate, vicuser = rust.FindNetUsersByName( args[1] )
    if (not validate) then
        if (vicuser == 0) then
            print( "No player found with that name: " .. tostring( args[1] ))
        else
            print( "Multiple players found with name: " .. tostring( args[1] ))
        end
        return false
    end
    local controllable = vicuser.playerClient.controllable
    local this = controllable:GetComponent("Metabolism")
    if(#args==0)then
        rust.SendChatToUser(netuser,'/rad "name" add|remove|check #[amount]' )
    end
    if args[3] and args[2] == 'add' then
        this:AddRads(tonumber(args[3]))
    elseif not args[3] and args[2] == 'check'  then
        local radLevel = this:GetRadLevel()
        rust.SendChatToUser(netuser,tostring( radLevel ))
    end
end
function PLUGIN:Calories(netuser, cmd, args)
    local validate, vicuser = rust.FindNetUsersByName( args[1] )
    if (not validate) then
        if (vicuser == 0) then
            print( "No player found with that name: " .. tostring( args[1] ))
        else
            print( "Multiple players found with name: " .. tostring( args[1] ))
        end
        return false
    end
    local controllable = vicuser.playerClient.controllable
    local this = controllable:GetComponent("Metabolism")
    if(#args==0)then
        rust.SendChatToUser(netuser,'/calories "name" add|remove|check #[amount]' )
    end
    if args[3] and args[2] == 'remove' then
        this:SubtractCalories(tonumber(args[3]))
    elseif args[3] and args[2] == 'add' then
        this:AddCalories(tonumber(args[3]))
    elseif not args[3] and args[2] == 'check'  then
        rust.SendChatToUser(netuser,tostring( this:GetCalorieLevel() ))
    end
end
function PLUGIN:Injure(netuser, cmd, args)
    if(#args==0)then
        rust.SendChatToUser(netuser,'/injure "name" add|check|clear #[length]' )
    else
        local validate, vicuser = rust.FindNetUsersByName( args[1] )
        if (not validate) then
            if (netuser == 0) then
                print( "No player found with that name: " .. tostring( args[1] ))
            else
                print( "Multiple players found with name: " .. tostring( args[1] ))
            end
            return false
        end
        local controllable = vicuser.playerClient.controllable
        local this = controllable:GetComponent("FallDamage")
        if args[3] and args[2] == 'add' then
            this:SetLegInjury(tonumber(args[3]))
        elseif not args[3] and args[2] == 'check'  then
            local injuryLevel = this:GetLegInjury()
            rust.SendChatToUser(netuser,tostring( injuryLevel ))
        elseif not args[3] and args[2] == 'clear'  then
            this:ClearInjury()
        end

        --this:AddLegInjury(float)
        --this:ResetInjuryTime(float) -- float time = this.injury_length * Random.Range(0.9f, 1.1f);
        --this:FallImpact(float fallspeed) --
    end
end
function PLUGIN:Bleed(netuser, cmd, args)
    local validate, vicuser = rust.FindNetUsersByName( args[1] )
    if (not validate) then
        if (netuser == 0) then
            print( "No player found with that name: " .. tostring( args[1] ))
        else
            print( "Multiple players found with name: " .. tostring( args[1] ))
        end
        return false
    end
    local controllable = vicuser.playerClient.controllable
    local this = controllable:GetComponent("HumanBodyTakeDamage")
    if(#args==0)then
        rust.SendChatToUser(netuser,'/bleed "name" add|check|clear #[length]' )
    end
    if args[3] and args[2] == 'add' then
        this:SetBleedingLevel(tonumber(args[3]))
    elseif not args[3] and args[2] == 'check'  then
        rust.SendChatToUser(netuser,tostring( this:IsBleeding() ))
    elseif not args[3] and args[2] == 'clear'  then
        this:SetBleedingLevel(0)
    end
end
function PLUGIN:HealOverTime(netuser, cmd, args)
    local validate, vicuser = rust.FindNetUsersByName( args[1] )
    if (not validate) then
        if (netuser == 0) then
            print( "No player found with that name: " .. tostring( args[1] ))
        else
            print( "Multiple players found with name: " .. tostring( args[1] ))
        end
        return false
    end
    local controllable = vicuser.playerClient.controllable
    local this = controllable:GetComponent("HumanBodyTakeDamage")
    if(#args==0)then
        rust.SendChatToUser(netuser,'/hot "name" add|check|clear #[amount]' )
    end
    if args[3] and args[2] == 'add' then
        this:HealOverTime(tonumber(args[3]))
    elseif not args[3] and args[2] == 'check'  then
        rust.SendChatToUser(netuser,tostring( this:CheckLevels() ))
    elseif not args[3] and args[2] == 'clear'  then
        this._healOverTime = 0
    end
end
function PLUGIN:Bandage(netuser, cmd, args)
    if(#args==0)then
        rust.SendChatToUser(netuser,'/bandage "name" #[amount]' )
    else
        local validate, vicuser = rust.FindNetUsersByName( args[1] )
        if (not validate) then
            if (netuser == 0) then
                print( "No player found with that name: " .. tostring( args[1] ))
            else
                print( "Multiple players found with name: " .. tostring( args[1] ))
            end
            return false
        end
        local controllable = vicuser.playerClient.controllable
        local this = controllable:GetComponent("HumanBodyTakeDamage")


        if args[2] then
            this:Bandage(tonumber(args[2]))
        end
    end
end
function PLUGIN:Reflect(netuser, cmd, args)
    if(#args==0)then
        rust.SendChatToUser(netuser,'/reflect "from name" "to name"' )
    else
        local validatea, vicusera = rust.FindNetUsersByName( args[1] )
        if (not validatea) then
            if (vicusera == 0) then
                print( "No player found with that name: " .. tostring( args[1] ))
            else
                print( "Multiple players found with name: " .. tostring( args[1] ))
            end
            return false
        end
        local validateb, vicuserb = rust.FindNetUsersByName( args[2] )
        if (not validateb) then
            if (vicuserb == 0) then
                print( "No player found with that name: " .. tostring( args[2] ))
            else
                print( "Multiple players found with name: " .. tostring( args[2] ))
            end
            return false
        end
        local controllablea = vicusera.playerClient.controllable
        local this = controllablea:GetComponent("HumanBodyTakeDamage")
        local controllableb = vicuserb.playerClient.controllable
        local other = controllableb:GetComponent("HumanBodyTakeDamage")

        if args[2] then
            this:CopyMembersTo(other)
        end
    end
end

function PLUGIN:Hurt(netuser, cmd, args)
    if(#args==0)then
        rust.SendChatToUser(netuser,'/hurt "name" #[amount]' )
    else
        local validate, vicuser = rust.FindNetUsersByName( args[1] )
        if (not validate) then
            if (netuser == 0) then
                print( "No player found with that name: " .. tostring( args[1] ))
            else
                print( "Multiple players found with name: " .. tostring( args[1] ))
            end
            return false
        end
        local controllable = netuser.playerClient.controllable
        local this = controllable:GetComponent("TakeDamage")
        local that = controllable:GetComponent("HumanBodyTakeDamage")
        rust.SendChatToUser(netuser,tostring(this) )
        rust.SendChatToUser(netuser,tostring(that) )
        if args[2] then
            this:Hurt(netuser.idMain, vicuser.idMain, tonumber(args[3]))
        end
    end
end
function PLUGIN:TakeOver(netuser, cmd, args)
    if(#args==0)then
        rust.SendChatToUser(netuser,'/hurt "name" #[amount]' )
    else
        local validate, vicuser = rust.FindNetUsersByName( args[1] )
        if (not validate) then
            if (vicuser == 0) then
                print( "No player found with that name: " .. tostring( args[1] ))
            else
                print( "Multiple players found with name: " .. tostring( args[1] ))
            end
            return false
        end
        local controllable = netuser.playerClient.controllable
        local controller = controllable:GetComponent("HumanController")
        --local self = controllable:GetComponent("TakeDamage")
        --local self = controllable:GetComponent("HumanBodyTakeDamage")

        local controllable = vicuser.playerClient.controllable
        local this = controllable:GetComponent("Character")

        if args[2] then
            this:ControlOverriddenBy(controller)

        end
    end
end
function PLUGIN:deepcopy(t)
	if type(t) ~= 'table' then return t end
	local mt = getmetatable(t)
	local res = {}
	for k,v in pairs(t) do
		if type(v) == 'table' then
			v = deepcopy(v)
		end
		res[k] = v
	end
	setmetatable(res,mt)
	return res
end

function PLUGIN:cmdRepair( netuser, cmd ,args )
	if not args[1] then rust.SendChatToUser( netuser, '/repair "#HotkeySlotNumber"' ) return end
	local spot = tonumber( args[1] )
	if not spot then rust.Notice( netuser, 'invalid numer' ) return end
	self:Repair( netuser, spot )
end

function PLUGIN:Repair( netuser, spot )
	local inv = rust.GetInventory( netuser )
	if not inv then rust.Notice( netuser, 'Inventory not found, bitch.' ) return end
	if spot == 1 then spot = 30 elseif spot == 2 then spot = 31 elseif spot == 3 then spot = 32 elseif spot == 4 then spot = 33 elseif spot == 5 then spot = 34 elseif spot == 6 then spot = 35 else rust.Notice( netuser, 'Wrong hotkey slot noob.' ) return end
	local b, item = inv:GetItem( spot )
	if not b then rust.Notice( netuser, 'No item in that Slot.' ) return end
	item:SetCondition(1)
	item.uses = 300
	-- rust.Notice( netuser, 'Changed condition to 100.' )
end
