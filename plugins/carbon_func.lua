PLUGIN.Title = 'carbon_util'
PLUGIN.Description = 'utilities module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    self.spamNet = {} --used to prevent spammed messages to a user.
end
--Util
--------------------------------------------------------------------------------------------------
function PLUGIN:TextBox(netuser, content, cmd, args)
    if content.prefix then content.prefix = WordWrap(content.prefix, 50) end
    --if content.breadcrumbs then content.breadcrumbs = WordWrap(content.breadcrumbs, 50) end
    if content.header then content.header = WordWrap(content.header, 50) end
    if content.subheader then content.subheader = WordWrap(content.subheader, 50) end
    if content.msg then content.msg = WordWrap(content.msg, 50) end
    --if content.cmds then content.cmds = WordWrap(content.cmds, 50) end
    if content.suffix then content.suffix = WordWrap(content.suffix, 50) end
    if content.prefix then
        rust.SendChatToUser(netuser,self.sysname,' ')
        rust.SendChatToUser(netuser,self.sysname,'╔════════════════════════')
        for _,v in ipairs(content.prefix) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end
        rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
    else
        rust.SendChatToUser(netuser,self.sysname,' ')
        rust.SendChatToUser(netuser,self.sysname,'╔════════════════════════')
    end
    rust.SendChatToUser(netuser,self.sysname,'║ ' .. cmd .. ' > ' .. table.concat(args, ' > '))
    rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
    if content.header or content.subheader then
        if content.header then for _,v in ipairs(content.header) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end end
        if content.subheader then for _,v in ipairs(content.subheader) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end end
        rust.SendChatToUser(netuser,self.sysname,'╟­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­')
    end
    if content.msg then for _,v in ipairs(content.msg) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end end
    if content.list then for _,v in ipairs(content.list) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end end
    rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
    if content.cmds then rust.SendChatToUser(netuser,self.sysname,'║ ► ' .. table.concat(content.cmds, '     ► ')) else
        rust.SendChatToUser(netuser,self.sysname,'║ ') end
    if content.suffix then
        rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
        for _,v in ipairs(content.suffix) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end
        rust.SendChatToUser(netuser,self.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,self.sysname,' ')
    else
        rust.SendChatToUser(netuser,self.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,self.sysname,' ')
    end
    content = {}
end
function PLUGIN:TextBoxError(netuser, content, cmd, args)
    if content.prefix then content.prefix = WordWrap(content.prefix, 50) end
    --if content.breadcrumbs then content.breadcrumbs = WordWrap(content.breadcrumbs, 50) end
    if content.header then content.header = WordWrap(content.header, 50) end
    if content.subheader then content.subheader = WordWrap(content.subheader, 50) end
    if content.msg then content.msg = WordWrap(content.msg, 50) end
    --if content.cmds then content.cmds = WordWrap(content.cmds, 50) end
    if content.suffix then content.suffix = WordWrap(content.suffix, 50) end
    if content.prefix then
        rust.SendChatToUser(netuser,self.sysname,' ')
        rust.SendChatToUser(netuser,self.sysname,'╔════════════════════════')
        for _,v in ipairs(content.prefix) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end
        rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
    else
        rust.SendChatToUser(netuser,self.sysname,' ')
        rust.SendChatToUser(netuser,self.sysname,'╔════════════════════════')
    end
    rust.SendChatToUser(netuser,self.sysname,'║ ' .. cmd .. ' > ' .. table.concat(args, ' > ') .. ' > ϟ error')
    rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
    if content.header or content.subheader then
        if content.header then for _,v in ipairs(content.header) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end end
        if content.subheader then for _,v in ipairs(content.subheader) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end end
        rust.SendChatToUser(netuser,self.sysname,'╟­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­')
    end
    if content.msg then for _,v in ipairs(content.msg) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end
    elseif content.list then for _,v in ipairs(content.list) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end
    else rust.SendChatToUser(netuser,self.sysname,'║ Sacrebleu! Something went wrong.. .') end
    rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
    if content.cmds then rust.SendChatToUser(netuser,self.sysname,'║ ► ' .. table.concat(content.cmds, '     ► ')) else
        rust.SendChatToUser(netuser,self.sysname,'║ ') end
    if content.suffix then
        rust.SendChatToUser(netuser,self.sysname,'╟────────────────────────')
        for _,v in ipairs(content.suffix) do rust.SendChatToUser(netuser,self.sysname,'║ ' .. v) end
        rust.SendChatToUser(netuser,self.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,self.sysname,' ')
    else
        rust.SendChatToUser(netuser,self.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,self.sysname,' ')
    end
    rust.InventoryNotice(netuser, 'Secrebleu!')
    content = {}
end
--WordWrap(str, int)
function WordWrap(strText, intMaxLength)
    local tblOutput = {}
    local intIndex
    local strBuffer = ""
    local tblLines = Explode(strText, "\n")
    for k, strLine in pairs(tblLines) do
        local tblWords = Explode(strLine, " ")
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
function Explode(strText, strDelimiter)
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
-- table.containsval - check if the value is in the table [ table.containtsval( table, value ) ]
function table.containsval(t,cv) for _, v in ipairs(t) do  if v == cv then return true  end  end return nil end
-- self:count( counts a table )
function PLUGIN:count( table ) local i = 0 for k, v in pairs( table ) do i = i + 1 end return i end
-- self:sayTable( lists the values of that table , sep is the seperator, so like , or ; )
function PLUGIN:sayTable( table, sep ) local msg = '' local count = #table if( count <= 0 ) then return 'N/A' end local i = true

for k, v in ipairs( table ) do if( i ) then msg = msg .. v i = false else msg = msg .. (sep .. v) end end msg = msg .. '.' return msg end
function table.returnvalues( table ) if( not table ) then return false end local msg = '' for k,v in pairs( table ) do msg = msg .. '[ ' .. v .. ' ]' end return msg end

function PLUGIN:Notice(netuser,prefix,text,duration)
    Rust.Rust.Notice.Popup( netuser.networkPlayer, prefix or " ", text .. '      ', duration or 4.0 )
end

--PLUGIN:findIDByName
function PLUGIN:findIDByName( name )
    for k,v in pairs( self.User ) do
        if ( v.name == name ) then return k end
    end
    return false
end

-- PLUGIN:GetUserData
function PLUGIN:GetUserData( netuser )
    print(tostring('GetUserData: ' .. tostring(netuser)))
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
        data.crafting = false
        data.stats = {['deaths']={['pvp']=0,['pve']=0},['kills']={['pvp']=0,['pve']={['total']=0}}}
        data.prof = {['Engineer']={['lvl']=1,['xp']=0},
            ['Medic']={['lvl']=0,['xp']=0},
            ['Carpenter']={['lvl']=1,['xp']=0},
            ['Armorsmith']={['lvl']=1,['xp']=0},
            ['Weaponsmith']={['lvl']=1,['xp']=0}}
        self.User[ netuserID ] = data
        self:UserSave()
    end
    return data
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