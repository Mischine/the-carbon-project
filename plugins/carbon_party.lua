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
	    print( 'Creating carbon_party file...' )
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
			local msg = tostring('[ID: ' .. k .. '] NAME: ' .. v.name .. ' || Slots: (' .. func:count( v.members ) .. '/' .. v.slots .. ')')
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
	pdata.slots = 5 +  (0.5 * data.attributes.int)                      -- Max of 10 slots with 10 intelligence.
	pdata.public = false                                                -- When true, everyone can join with /party join
	pdata.xp = 0                                                        -- Total xp this party earned
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
	if not pdata.public then
		if pdata.members[ rust.GetUserID(netuser)].rank ~= 'leader' then rust.Notice( netuser, 'You cannot invite anyone!' ) return end
	end
	local slots = 5
	for _,v in pairs( pdata.members ) do
		slots = slots + (v.int * 0.5)
	end
	if func:count( pdata.members ) >= slots then rust.Notice( netuser, 'Cannot invite any more players!' ) return end
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
		['rank'] = 'member',
		['int'] = data.attributes.int,
		['xpcon'] = 0
	}
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
	pdata.members[ targid ] = nil
end

function PLUGIN:PartyMembers( netuser, cmd, args )
	local pdata = self:getParty( netuser )
	if not pdata then rust.Notice( netuser, 'you\'re not in a party!' ) return end
	local content = {
		['header'] = 'Party Members:',
		['list'] = {}
	}
	for _,v in pairs( pdata.members ) do
		local b, _ = rust.FindNetUsersByName( v.name )
		local status = 'Online'
		if not b then status = 'Offline' end
		table.insert( content.list, v.name .. ' Status: ' .. status .. ' || Xp contributed: ' .. tostirng( v.xpcon ))
	end
	func:TextBox(netuser,content,cmd,args)
end

-- /party set true/false
function PLUGIN:PartySet( netuser, cmd, args )
	local pdata = self:getParty( netuser )
	if not pdata then rust.Notice( netuser, 'you\'re not in a party!' ) return end
	if pdata.members[ rust.GetUserID(netuser)].rank ~= 'leader' then rust.Notice( netuser, 'You cannot change party status.' ) return end
	if not args[2] then rust.SendChatToUser( netuser, '/party set true/false' ) return end
	if args[2]:lower() == 'true' then
		pdata.public = true
		local msg = '::::::::::: ' .. netuser.displayName .. ' has set public to true! :::::::::::'
		self:sendPartyMsg( 'STATUS', pdata.members, msg )
	elseif args[2]:lower() == 'false' then
		pdata.public = false
		local msg = '::::::::::: ' .. netuser.displayName .. ' has set public to false! :::::::::::'
		self:sendPartyMsg( 'STATUS', pdata.members, msg )
	else
		rust.SendChatToUser( netuser, '/party set true/false' )
	end
	self:PartySave()
end

function PLUGIN:PartyLeave( netuser, cmd, args )
	local pdata = self:getParty( netuser )
	if not pdata then rust.Notice( netuser, 'you\'re not in a party!' ) return end
	if pdata.members[ rust.GetUserID( netuser )].rank == 'leader' then
		for _,v in pairs ( pdata.members ) do
			local b, _ = rust.FindNetUsersByName( v.name )
			if b then
				v.rank = 'leader'
				self:sendPartyMsg( 'PARTY', pdata.members, '::::::::::: '..  v.name .. ' is now the party leader! :::::::::::')
			break end
		end
	end
	pdata.members[ rust.GetUserID( netuser )] = nil
	self:sendPartyMsg( netuser.displayName,  pdata.name, '::::::::::: ' .. netuser.displayName .. ' has left the party :::::::::::' )
	local count = func:count( pdata.members )
	if ( count == 0 ) then self.Party[ pdata.id ] = nil rust.Notice( netuser, 'Party has been disbanned!' ) end
	self:PartySave()
end

-- /party join ID
function PLUGIN:PartyJoin( netuser, cmd, args )
	local party = self:getParty( netuser )
	if party then rust.Notice( netuser, 'You\'re already in a party!' ) return end
	if not args[2] then rust.SendChatToUser( netuser, core.sysname, '/party join ID' ) return end
	local pid = tonumber(args[2])
	if not pid then rust.Notice( netuser, 'Invalid ID. ( ' .. tostring(pid) .. ' )' ) return end
	local pdata = self:getPartyByID( pid )
	if not pdata then rust.Notice( netuser, 'Party ID does not exist!' ) return end
	if not pdata.public then rust.Notice( netuser, 'Party is not public!' ) return end
	if func:count(pdata.members) >= pdata.slots then rust.Notice( netuser, 'Party is full' ) return end
	local data = char[ rust.GetUserID( netuser )]
	if not data then rust.Notice(netuser, 'Player data not found! try relogging.' ) return end
	-- Joining party
	pdata.members[ rust.GetUserID( netuser )] = {
		['name'] = netuser.displayName,
		['rank'] = 'member',
		['int'] = data.attributes.int,
		['xpcon'] = 0
	}
	local msg = '::::::::::: ' .. netuser.displayName .. ' has joined the party :::::::::::'
	self:sendPartyMsg( netuser.displayName, pdata.members, msg )
	self:PartySave()
end

function PLUGIN:PartyOverView( netuser, cmd, args )
	local pdata = self:getParty( netuser )
	if not pdata then rust.Notice( netuser, 'You\'re not in a party!' ) return end
	local leader
	for k,v in pairs( pdata.members) do
		if v.rank == 'leader' then leader = v.name break end
	end
	local content = {
		['header'] = pdata.name .. '\'s overview',
		['msg'] = 'This is the party overview, this will provide some basic information about the party. To check the party members individually, type: /party members',
		['list'] = {
			' ',
			'Public                   : '.. tostring(pdata.public),
			'Total members         : ' .. tostring(func:count( pdata.members)),
			'Leader                   : ' .. leader,
			'Total xp gained     : ' .. tostring(pdata.xp),
			'Available slots       : ' .. tostring(pdata.slots),
		}
	}
	func:TextBox(netuser,content,cmd,args)
end

function PLUGIN:PartyInfo( netuser, cmd, args )
	local content = {
		['header'] = 'Party information',
		['msg'] = 'The party system in Carbon is easy to use. There are 2 kind of parties. Public and private. For private parties you have to be invited to join. Public parties can be joined by anyone as long as there are enough slots. To find public parties type /party list. ' ,
		['suffix'] = 'Learn more about parties at; www.tempusforge.com'
	}
	func:TextBox(netuser,content,cmd,args)
end

-- -------------------------------------
-- Party function
-- -------------------------------------
function PLUGIN:DistributeXP( combatData, pdata, xp )
	local c = combatData.netuser.playerClient.lastKnownPosition
	if not (( c ) and ( c.x ) and ( c.y ) and ( c.z )) then char:GiveXP( combatData, xp, true ) return end
rust.BroadcastChat( 'coords found' )
	local int
	local i = 1
	local allcombatData = {}
	for k,v in pairs( pdata.members ) do
		local b, netuser = rust.FindNetUsersByName( v.name )
		if b then
			local tc = netuser.playerClient.lastKnownPosition
			if ( tc ) and ( tc.x ) and ( tc.y ) and ( tc.z ) then
				if ( func:Distance3D ( c.x, c.y, c.z, tc.x, tc.y, tc.z ) <= 100 ) then
rust.BroadcastChat( 'In range' )
					local netuserData = char[ rust.GetUserID( netuser )]
					if netuserData then
						allcombatData[i] = {
							['netuser'] = netuser,
							['netuserData'] = netuserData
						}
						i = i + 1
						int = int + netuserData.attributes.int
					end
				end
			end
		end
	end
	local mod = 1 + ( 0.05 * int )
	pdata.xp = pdata.xp + ( xp * mod )
	pdata.members[combatData.netuserData.id].xpcon = pdata.members[combatData.netuserData.id].xpcon + ( xp * mod )
	xp = ( xp *  mod ) / i
	local y = 1
	while allcombatData[y] do
		char:GiveXP( allcombatData[i], xp, false )
		y = y + 1
	end
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
	local pdata = self:getParty( netuser)
	if not pdata then rust.Notice( netuser, 'You\'re not in a party!' ) return end
	local i = 1
	local msg = ''
	while ( args[i] ) do
		msg = msg .. ' ' .. args[i]
		i = i + 1
	end
	local tempstring = string.lower( msg )
	for k, v in ipairs( core.Config.settings.censor.chat ) do
		local found = string.find( tempstring, v )
		if ( found ) then rust.Notice( netuser, 'Dont swear!' ) return end
	end
	self:sendPartyMsg(netuser.displayName, pdata.members, msg )
end

function PLUGIN:sendPartyMsg( name, members, msg )
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