PLUGIN.Title = 'carbon_mail'
PLUGIN.Description = 'mail module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    self:AddChatCommand( 'mail', self.cmdMail )
end

--PLUGIN:cmdMail
function PLUGIN:cmdMail( netuser, cmd ,args )
    if( not args[1] ) then                              -- /mail        to check your inbox
        local netuserID = rust.GetUserID( netuser )
        if( not char.User[ netuserID ].mail ) then rust.SendChatToUser( netuser, 'Mail', 'You\'ve no new mail' ) return end
        rust.SendChatToUser( netuser, ' ', ' ')
        rust.SendChatToUser( netuser, 'Mail', 'Inbox from: ' .. util.QuoteSafe(netuser.displayName ))
        for k, v in pairs( char.User[ netuserID ].mail ) do
            if( not char.User[ netuserID ].mail[ k ].read ) then
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
        local targid = func:findIDByName( tostring( args[2] ))
        if( not targid ) then rust.Notice( netuser, 'No player with the name: ' .. tostring( args[2]) .. ' found in the database.' ) return end
        -- Get guild

        local b, canbuy = api.Call('ce', 'canBuy', netuser, 0,0,5 )
        if( not canbuy ) then rust.Notice( netuser, ' Not enough copper! 5 copper required! ') return end
        api.Call( 'ce', 'RemoveBalance', netuser, 0,0,5 )

        local guild = guild:getGuild( netuser )
        -- Generating msg
        local i = 3
        local msg = ''
        while ( i <= #args ) do
            msg = msg .. ' ' .. args[i]
            i = i + 1
        end
        -- Checking msg for language
        local tempstring = string.lower( msg )
        for k, v in ipairs( core.Config.settings.censor.chat ) do
            local found = string.find( tempstring, v )
            if ( found ) then
                rust.Notice( netuser, 'Dont swear!' )
                return
            end
        end
        -- get date and time / convert to datetime
        local date = System.DateTime.Now:ToString(core.Config.dateformat)
        -- send mail
        if( guild ) then guild:sendMail( targid, netuser.displayName, date, msg, guild ) else guild:sendMail( targid, netuser.displayName, datetime, msg ) end
        rust.Notice( netuser, 'Mail send to ' .. tostring( args[2] ))
    elseif( action == 'read' ) then                             -- /mail read [id]          Read a mail
        if( not args[2] ) then rust.SendChatToUser( netuser, 'Mail', '/mail read [id]' ) return end
        local netuserID = rust.GetUserID( netuser )
        local ID = tostring( args[2] )
        if(( not char.User[ netuserID ].mail ) or ( not char.User[ netuserID ].mail[ ID ] )) then rust.Notice( netuser, 'Mail ID not found! ID: ' .. ID ) return end
        local mail = char.User[ netuserID ].mail[ ID ]
        rust.SendChatToUser( netuser, ' ', ' ')
        rust.SendChatToUser( netuser, 'Mail', 'From        : ' .. mail.from  )
        if( mail.guild ) then rust.SendChatToUser( netuser, 'Mail', 'Guild         : ' .. mail.guild  ) end
        rust.SendChatToUser( netuser, 'Mail', 'Date         : ' .. mail.date  )
        rust.SendChatToUser( netuser, 'Mail', 'Message :' .. mail.msg)
        char.User[ netuserID ].mail[ ID ].read = true
    elseif( action == 'del' ) then                              -- /mail del [id]           Delete specific message
        if( not args[2] ) then rust.SendChatToUser( netuser, 'Mail', '/mail del [id]' ) return end
        local ID = tostring( args[2] )
        local netuserID = rust.GetUserID( netuser )
        if(( not char.User[ netuserID ].mail ) or ( not char.User[ netuserID ].mail[ ID ] )) then rust.Notice( netuser, 'Mail ID not found! ID: ' .. ID ) return end
        char.User[ netuserID ].mail[ID] = nil
        local count = func:count( char.User[ netuserID ].mail )
        if ( count <= 0 ) then char.User[ netuserID ].mail = nil end
        rust.Notice( netuser, 'Mail ID ' .. ID .. ' succesfully deleted!' )
        self:UserSave()
    elseif( action == 'clear' ) then                            -- /mail clear              Clears whole inbox
        local netuserID = rust.GetUserID( netuser )
        if( char.User[ netuserID ].mail ) then
            char.User[ netuserID ].mail = nil
            rust.Notice( netuser, 'Mail cleared!' )
        else
            rust.Notice( netuser, 'No mail found!' )
        end
    elseif( action == 'help' ) then
        rust.SendChatToUser(netuser,' ','\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
        rust.SendChatToUser(netuser,' ','█\n█')
        rust.SendChatToUser( netuser, core.sysname,'█ The mail system in carbon is easy to use.' .. '\n█' )
        rust.SendChatToUser( netuser, core.sysname,'█ You\'re able to send mails to offline and online players.' .. '\n█' )
        rust.SendChatToUser( netuser, core.sysname,'█ /mail to check your mail. It shows unread mails with a [NEW] infront of them' .. '\n█' )
        rust.SendChatToUser( netuser, core.sysname,'█ /mail read ID to read the mail. This includes the sender, guild and the send date.' .. '\n█' )
        rust.SendChatToUser( netuser, core.sysname,'█ /mail del ID to delete a single mail from your inbox.' .. '\n█' )
        rust.SendChatToUser( netuser, core.sysname,'█ /mail clear to delete all your mails.' .. '\n█' )
        rust.SendChatToUser( netuser, core.sysname,'█ The id ID shown infromt of the mail when you check your inbox with /mail.' .. '\n█' )
        rust.SendChatToUser(netuser,' ','█\n▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀')
        rust.SendChatToUser( netuser, ' ', ' ' )
    end
end

--PLUGIN:sendMail
function PLUGIN:sendMail( toplayerID, fromplayername, date, msg, guild )
    local mail = {}
    mail.from = util.QuoteSafe( fromplayername )
    mail.date = date
    mail.msg = msg
    mail.read = false
    if ( guild ) then mail.guild = guild end
    -- get mail unique mail id
    if( not char.User[ toplayerID ].mail ) then char.User[ toplayerID ].mail = {} end
    local i = 0
    while ( char.User[ toplayerID ].mail[ tostring( i ) ]) do
        i = i + 1
    end
    char.User[ toplayerID ].mail[tostring( i )] = mail
    -- If online, send inventory notice.
    local name = char.User[ toplayerID ].name
    local b, netuser = rust.FindNetUsersByName( name )
    if ( b ) then rust.InventoryNotice( netuser, 'New mail from: ' .. util.QuoteSafe( fromplayername )) end
    -- Save
    self:UserSave()
end
