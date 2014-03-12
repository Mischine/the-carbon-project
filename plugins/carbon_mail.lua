PLUGIN.Title = 'carbon_mail'
PLUGIN.Description = 'mail module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    --self:AddChatCommand( 'mail', self.cmdMail )
end

--[[
	TODO:
	 Redo the whole mail system. Make it so people can forward mails. And send/receive money/items.
	 Also make it so people can receive their donation per mail. XP,ITEM,MONEY,CLASSUNLOCK
 ]]

--PLUGIN:cmdMail
function PLUGIN:cmdMail( netuser, cmd ,args )
    if( not args[1] ) then                              -- /mail        to check your inbox
        local netuserID = rust.GetUserID( netuser )
        if( not char[ netuserID ].mail ) then
            local content = {['msg'] ='You have no new mail!',['header'] ='Inbox from: ' .. util.QuoteSafe(netuser.displayName),['cmds']={'read','send','del','clear','help'}}
            func:TextBox(netuser,content,cmd,args)
        return end

        local content = {
            ['msg'] ='',
            ['header'] ='Inbox from: ' .. util.QuoteSafe(netuser.displayName),
            ['list'] = {},
            ['cmds']={'read','send','del','clear','help'}
        }
        for k, v in pairs( char[ netuserID ].mail ) do
            if( not char[ netuserID ].mail[ k ].read ) then
                table.insert(content.list, '[ ' .. tostring( k ) .. ' ] | [ NEW ] Mail from: ' .. v.from )
            else
                table.insert(content.list, '[ ' .. tostring( k ) .. ' ] | Mail from: ' .. v.from )
            end
        end
        func:TextBox(netuser,content,cmd,args)
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
        local date = System.DateTime.Now:ToString("M/dd/yyyy")
        -- send mail
        self:sendMail( targid, netuser.displayName, date, msg )
        local content = {['msg'] = msg,['header'] ='Message send to ' .. tostring(args[2] ),['cmds']={}}
        local i = 3 while args[i] do args[i] = nil i = i + 1 end
        func:TextBox(netuser,content,cmd,args)
        rust.Notice( netuser, 'Mail send to ' .. tostring( args[2] ))
    elseif( action == 'read' ) then                             -- /mail read [id]          Read a mail
        if( not args[2] ) then rust.SendChatToUser( netuser, 'Mail', '/mail read [id]' ) return end
        local netuserID = rust.GetUserID( netuser )
        local ID = tostring( args[2] )
        if(( not char[ netuserID ].mail ) or ( not char[ netuserID ].mail[ ID ] )) then rust.Notice( netuser, 'Mail ID not found! ID: ' .. ID ) return end
        local mail = char[ netuserID ].mail[ ID ]

        local content = {
            ['msg'] = mail.msg,
            ['header'] ='From        : ' .. mail.from,
            ['subheader'] ='Date         : ' .. mail.date,
        }
        func:TextBox(netuser,content,cmd,args)
        char[ netuserID ].mail[ ID ].read = true
    elseif( action == 'del' ) then                              -- /mail del [id]           Delete specific message
        if( not args[2] ) then rust.SendChatToUser( netuser, 'Mail', '/mail del [id]' ) return end
        local ID = tostring( args[2] )
        local netuserID = rust.GetUserID( netuser )
        if(( not char[ netuserID ].mail ) or ( not char[ netuserID ].mail[ ID ] )) then rust.Notice( netuser, 'Mail ID not found! ID: ' .. ID ) return end
        char[ netuserID ].mail[ID] = nil
        local count = func:count( char[ netuserID ].mail )
        if ( count <= 0 ) then char[ netuserID ].mail = nil end
        rust.Notice( netuser, 'Mail ID ' .. ID .. ' succesfully deleted!' )
        char:Save( netuser)
    elseif( action == 'clear' ) then                            -- /mail clear              Clears whole inbox
        local netuserID = rust.GetUserID( netuser )
        if( char[ netuserID ].mail ) then
            char[ netuserID ].mail = nil
            rust.Notice( netuser, 'Mail cleared!' )
        else
            rust.Notice( netuser, 'No mail found!' )
        end
    elseif( action == 'help' ) then
        local content = {
            ['list'] = {
                'The mail system in carbon is easy to use.',
                'You\'re able to send mails to offline and online players.',
                '/mail to check your mail. It shows unread mails with a [NEW] infront of them',
                '/mail send "name" msg to send a mail to a person.',
                '/mail read ID to read the mail. This includes the sender, guild and the send date.',
                '/mail del ID to delete a single mail from your inbox.',
                '/mail clear to delete all your mails.',
                'The id ID shown infromt of the mail when you check your inbox with /mail.',
            },
        }
        func:TextBox(netuser,content,cmd,args)
    end
end

--PLUGIN:sendMail
function PLUGIN:sendMail( toplayerID, fromplayername, date, msg, guild )
    local mail = {}
    mail.from = util.QuoteSafe( fromplayername )
    mail.date = date
    mail.msg = msg
    mail.read = false
    self:Load( toplayerID )
    if ( guild ) then mail.guild = guild end
    -- get mail unique mail id
    if( not char[ toplayerID ].mail ) then char[ toplayerID ].mail = {} end
    local i = 0
    while ( char[ toplayerID ].mail[ tostring( i ) ]) do
        i = i + 1
    end
    char[ toplayerID ].mail[tostring( i )] = mail
    -- If online, send inventory notice.
    local name = char[ toplayerID ].name
    local b, netuser = rust.FindNetUsersByName( name )
    if ( b ) then rust.InventoryNotice( netuser, 'New mail from: ' .. util.QuoteSafe( fromplayername )) end
    -- Save
    char:Save( netuser )
	char[ toplayerID ] = nil
end
