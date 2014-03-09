PLUGIN.Title = 'carbon_party'
PLUGIN.Description = 'party module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    --LOAD/CREATE GUILD DATA FILE
    self.PartyFile = util.GetDatafile( 'carbon_party' )
    local party_txt = self.PartyFile:GetText()
    if (party_txt ~= '') then
	    print( 'Carbon_party file loaded!' )
	    self.Party = json.decode( party_txt )
    else
	    print( 'Creating carbon gld file...' )
	    self.Party = {}
	    self:PartySave()
    end

    self.tmp = {}

end

--[[
    /party list         -- List of partys available ( which are set to public and not private
    /party invite       -- Invite a player
    /party kick         -- kicks a player
    /party leave        -- Leaves your current party
    /party members      -- Check the players in party
    /party set          -- Set your party to private or public | Default is public

    Party can be maxed 5 players. will increase with the intellect of the creator.

 ]]

function PLUGIN:PartyList( netuser, cmd, args )
	local content = {
		['msg'] = 'Here is a list of public parties. To join a party type /join ID.',
		['list'] = {}
	}
	for k,v in pairs( self.Party ) do
		if v.public then
			local msg = '[ID: ' .. k .. '] NAME: ' .. v.name .. ' || Slots: (' .. v.totalmem .. '/' .. v.slots .. ')'
			table.insert( content.msg, msg )
		end
	end
	func:TextBox(netuser,content,cmd,args)
end

-- /party create
function PLUGIN:PartyCreate( netuser, cmd, args )
	if self:getParty( netuser ) then rust.Notice( netuser, 'You\'re already in a party!' ) return end
	local data = char[ rust.GetUserID( netuser ) ]
	if data.lvl < 5 then rust.Notice( netuser, 'You need to be atleast level 5 to create a party!' ) return end
	local pdata = {}
	pdata.name = netuser.displayName
	if args[2] then pdata.name = tostring(args[2]) end                  -- Choice to give the party a name.
	pdata.slots = 5 + math.floor( 0.5 * data.attributes.int )           -- Max of 10 slots with 10 intelligence.
	pdata.public = false                                                -- When true everyone can joiun with /party join
	pdata.xp = 0                                                        -- Total xp this party earned
	pdata.totalmem = 1
	pdata.members = {}
	pdata.members[ rust.GetUserID( netuser )] = {
		['name'] = netuser.displayName,
		['rank'] = 'leader',
		['int'] = data.attributes.int,
		['xpcon'] = 0
	}

	local i = 0
	while self.Party[tostring(i)] do
		i = i + 1
	end

	pdata.id = tostring(i)
	self.Party[tostring(i)] = pdata
	char[ rust.GetUserID( netuser )]['party'] = tostring(i)
	rust.SendChatToUser( netuser, core.sysname,  'Party created! /party invite "Name" to invite more people!' )
	self:PartySave()
end

function PLUGIN:PartyInvite( netuser, cmd, args )
	if not args[2] then rust.SendChatToUser( netuser, core.sysname, '/party invite "Name" ' ) return end
	local pdata = self:getParty( netuser )
	if not pdata then rust.Notice( netuser, 'You\'re not in a party!' ) return end
	if pdata.members[ rust.GetUserID(netuser)].rank ~= 'leader' then rust.Notice( netuser, 'You cannot invite anyone!' ) return end
	local slots = 5
	for _,v in pairs( pdata.members ) do
		slots = slots + (v.int * 0.5)
	end
	if pdata.totalmem >= slots then rust.Notice( netuser, 'Cannot invite any more players!' ) return end
	local targname = util.QuoteSafe( args[2] )
	local b, targuser = rust.FindNetUsersByName( targname )
	if ( not b ) then
		if( targuser == 0 ) then
			rust.Notice( netuser, 'No user found with the name: ' .. util.QuoteSafe( targname ) )
		else
			rust.Notice( netuser, 'Multiple users found with the name: ' .. util.QuoteSafe( targname ) )
		end
	return end
	if pdata.members[ rust.GetUserID( targuser )] then rust.Notice( netuser, targname .. ' is already in your party!' ) return end
	if self:getParty( targuser ) then rust.Notice( netuser, targname .. ' is already in a party!' ) return end
	if self.tmp[ targuser ] then rust.Notice( netuser, targname .. ' has already a party invitation!' ) return end

	rust.Notice( targuser, 'You\'ve been invited to party: ' .. pdata.name )
	local msg = ':::::::::::: ' .. targname .. 'has been invited to the party. ::::::::::::'
	self:sendPartyMsg( 'INVITE', pdata.members ,msg )
	rust.SendChatToUser( targuser, core.sysname, 'To accept the party invite type: /party accept' )
	self.tmp[ targuser ] = pdata.id
	timer.Once( 30, function()
		if self.tmp[ targuser ] then
			rust.Notice( targuser, 'The invitation to party: ' .. pdata.name .. ' will expire in 30 seconds.' )
			timer.Once( 30, function()
				if self.tmp[ targuser ] then
					rust.Notice( targuser, 'The invitation to party: ' .. pdata.name .. ' has expired! ')
					self.tmp[ targuer ] = nil
				end
			end)
		end
	end)
end

function PLUGIN:PartyAccept( netuser, cmd, args )
	if not self.tmp[ netuser ] then rust.Notice( netuser, 'You have no party invites!' ) return end
	local pdata = self.Party[ self.tmp[ netuser ] ]
	if not pdata then rust.Notice( netuser, 'Party data not found!' ) return end
	local netuserID = rust.GetUserID( netuser )
	local data = char[ netuserID ]
	if not data then rust.Notice( netuser, 'Player data not found!' ) return end

	pdata.members[ netuserID ] = {
		['name'] = netuser.displayName,
		['rank'] = 'members',
		['int'] = data.attributes.int,
		['xpcon'] = 0
	}
	pdata.totalmem = pdata.totalmem + 1
	local msg = util.QuoteSafe(netuser.displayName) .. ' has joined the party!'
	self:sendPartyMsg( netuser.displayName, pdata.members ,msg )
	self.tmp[ netuser ] = nil
	self:PartySave()
end

function PLUGIN:PartyKick( netuser, cmd, args )
	if not args[2] then rust.SendChatToUser( netuser, core.sysname, '/party kick "Name" ' ) return end
	local targname = util.QuoteSafe( args[2] )
	local pdata = self:getParty( netuser )
	if not pdata then rust.Notice( netuser, 'you\'re not in a party!' ) return end
	if pdata.members[ rust.GetUserID( netuser )].rank ~= 'leader' then rust.Notice( netuser, 'You\'re not allowed to kick players from the party.' ) return end
	local targid = false
	for k, v in pairs( pdata.members ) do
		if v.name == targname then targid = k break end
	end
	if not targid then rust.Notice( netuser, targname .. ' is not in your party!' ) return end
	local b, targuser = rust.FindNetUsersByName( targname )
	if b then rust.SendChatToUser( targuser, 'PARTY', 'You\'ve been kicked out of the party!' ) end
	pdata.totalmem = pdata.totalmem - 1
	pdata.members[ targid ] = nil
end

function PLUGIN:PartyMembers( netuser, cmd, args )

end

function PLUGIN:PartySet( netuser, cmd, args )

end

function PLUGIN:PartyLeave( netuser, cmd, args )
	local count = func:count( self.Guild[ guild ].members )
	if ( count == 0 ) then self.Guild[ guild ] = nil rust.Notice( netuser, guild .. ' has been disbanned!' ) end
end
function PLUGIN:PartySet( netuser, cmd, args )

end

function PLUGIN:PartyOverView( netuser, cmd, args )

end

function PLUGIN:PartyInfo( netuser, cmd, args )

end

function PLUGIN:getParty( netuser )
	for k, v in pairs( self.Party ) do
		if v.members[rust.GetUserID( netuser )] then return self.Party[k] end
	end
	return false
end

function PLUGIN:getPartyByID( id )
	if self.Party[ id ] then return self.Party[ id ] else return false end
end

function PLUGIN:cmdPartyChat( netuser, cmd, args )

end

function PLUGINsendPartyMsg( name, members, msg )
	for _,v in pairs( members ) do
		local b, targuser = rust.FindNetUsersByName( v.name )
		if b then rust.SendChatToUser( targuser, name .. '[P]',msg ) end
	end
end

-- PARTY SAVE
function PLUGIN:PartySave()
	self.PartyFile:SetText( json.encode( self.Party, { indent = true } ) )
	self.PartyFile:Save()
end