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
        for _,v in ipairs(content.prefix) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    else
        rust.SendChatToUser(netuser,core.sysname,' ')
        rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
    end
    rust.SendChatToUser(netuser,core.sysname,'║ ' .. cmd .. ' > ' .. table.concat(args, ' > '))
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    if content.header or content.subheader then
        if content.header then for _,v in ipairs(content.header) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end end
        if content.subheader then for _,v in ipairs(content.subheader) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end end
        rust.SendChatToUser(netuser,core.sysname,'╟­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­')
    end
    if content.msg then for _,v in ipairs(content.msg) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end end
    if content.list then for _,v in ipairs(content.list) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end end
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    if content.cmds then rust.SendChatToUser(netuser,core.sysname,'║ ► ' .. table.concat(content.cmds, '     ► ')) else
        rust.SendChatToUser(netuser,core.sysname,'║ ') end
    if content.suffix then
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
        for _,v in ipairs(content.suffix) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end
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
        for _,v in ipairs(content.prefix) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    else
        rust.SendChatToUser(netuser,core.sysname,' ')
        rust.SendChatToUser(netuser,core.sysname,'╔════════════════════════')
    end
    rust.SendChatToUser(netuser,core.sysname,'║ ' .. cmd .. ' > ' .. table.concat(args, ' > ') .. ' > ϟ error')
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    if content.header or content.subheader then
        if content.header then for _,v in ipairs(content.header) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end end
        if content.subheader then for _,v in ipairs(content.subheader) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end end
        rust.SendChatToUser(netuser,core.sysname,'╟­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­')
    end
    if content.msg then for _,v in ipairs(content.msg) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end
    elseif content.list then for _,v in ipairs(content.list) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end
    else rust.SendChatToUser(netuser,core.sysname,'║ Sacrebleu! Something went wrong.. .') end
    rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
    if content.cmds then rust.SendChatToUser(netuser,core.sysname,'║ ► ' .. table.concat(content.cmds, '     ► ')) else
        rust.SendChatToUser(netuser,core.sysname,'║ ') end
    if content.suffix then
        rust.SendChatToUser(netuser,core.sysname,'╟────────────────────────')
        for _,v in ipairs(content.suffix) do rust.SendChatToUser(netuser,core.sysname,'║ ' .. v) end
        rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,core.sysname,' ')
    else
        rust.SendChatToUser(netuser,core.sysname,'╚════════════════════════')
        rust.SendChatToUser(netuser,core.sysname,' ')
    end
    rust.InventoryNotice(netuser, 'Secrebleu!')
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
-- table.containsval - check if the value is in the table [ table.containtsval( table, value ) ]
function PLUGIN:containsval(t,cv) for _, v in ipairs(t) do  if v == cv then return true  end  end return nil end
-- self:count( counts a table )
function PLUGIN:count( table ) local i = 0 for k, v in pairs( table ) do i = i + 1 end return i end
-- self:sayTable( lists the values of that table , sep is the seperator, so like , or ; )
function PLUGIN:sayTable( table, sep ) local msg = '' local count = #table if( count <= 0 ) then return 'N/A' end local i = true

for k, v in ipairs( table ) do if( i ) then msg = msg .. v i = false else msg = msg .. (sep .. v) end end msg = msg .. '.' return msg end
function PLUGIN:returnvalues( table ) if( not table ) then return false end local msg = '' for k,v in pairs( table ) do msg = msg .. '[ ' .. v .. ' ]' end return msg end

function PLUGIN:Notice(netuser,prefix,text,duration)
    Rust.Rust.Notice.Popup( netuser.networkPlayer, prefix or " ", text .. '      ', duration or 4.0 )
end

--PLUGIN:findIDByName
function PLUGIN:findIDByName( name )
    for k,v in pairs( char.User ) do
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
function PLUGIN:Roll(amount)
    local seed = self:GetTimeMilliSeconds()
    math.randomseed(seed)
    local result = math.random(amount)
    return result
end