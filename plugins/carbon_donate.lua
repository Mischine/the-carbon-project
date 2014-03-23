PLUGIN.Title = 'carbon_donate'
PLUGIN.Description = 'donations module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin("carbon_core") core:LoadLibrary()

	self.DonateFile = util.GetDatafile( 'carbon_donate' )
	local don_txt = self.DonateFile:GetText()
	if (don_txt ~= '') then
		print( 'Carbon_donate file loaded!' )
		self.Donate = json.decode( don_txt )
	else
		print( 'Creating carbon_donate file...' )
		self.Donate = {}
		self:SaveDon()
	end
	self:AddChatCommand( 'donatexp', self.DonateXP )
	self:AddChatCommand( 'donatebal', self.DonateBal )
	self:AddChatCommand( 'donateitem', self.DonateItem )
end

function PLUGIN:DonateXP( netuser, _, args )
	if not dev:isDev( netuser ) then rust.Notice( netuser, 'Unknown chat command!' )return end
	if not args[1] and args[2] then rust.SendChatToUser( netuser, 'DONATE', '/donatexp "Name" "Amount ') return end
	local targname = tostring(args[1])
	local amount = tonumber(args[2])
	if not amount then rust.Notice( netuser, 'Invalid amount, noob.' ) return end
	local targID = 0
	for k,v in pairs(core.Reg ) do
		if v == targname then targID = k end
	end
	if targID == 0 then rust.Notice( netuser, targname .. ' was not found in our database!' ) return end
	local data = char[ targID ]	if not data then data = char:Load( targID )	end
	if not data then rust.Notice( netuser, targname .. ' was not found in our database!' ) return end -- Failsafe.
	if not data['mail'] then data['mail'] = {} end
	local concept = {
		['subject'] = {'Your donation!'},
		["txt"] = {'Thanks for donating to The Carbon Project! We really appreciate it! Here are your vials of xp, dont drink them all at once!'},
		['sender'] = 'The Carbon Project',
		['target'] = targname,
		['date'] = System.DateTime.Now:ToString('M/dd/yyyy'),
		['money'] = {
			['g'] = 0,
			['s'] = 0,
			['c'] = 0,
		},
		['xp'] = amount,
		['read'] = false
	}
	local uid = 0
	while data.mail[tostring(uid)] do
		uid = uid + 1
	end
	data.mail[ tostring(uid) ] = concept
	char:SaveDataByID( targID, data )
	self:AddDonation( targID, targname, 'Donated for: ' .. tostring(amount) .. ' xp!' )
	local b, targuser = rust.FindNetUsersByName( targname )
	if( b ) then rust.Notice( targuser, 'You\'ve got new mail from: The Carbon Project' ) rust.InventoryNotice( targuser, '+1 mail' ) end
	rust.SendChatToUser( netuser, core.sysname, 'Succesfully send mail to ' .. targname )
end

function PLUGIN:DonateBal( netuser, _, args )
	if not dev:isDev( netuser ) then rust.Notice( netuser, 'Unknown chat command!' )return end
	if not args[4] then rust.SendChatToUser( netuser, 'DONATE', '/donatexp "Name" g s c ') return end
	local targname = tostring(args[1])
	local g,s,c = tonumber(args[2]),tonumber(args[3]),tonumber(args[4])
	if not g or not s or not c then rust.Notice( netuser, 'Invalid amount, noob.' ) return end
	local targID = 0
	for k,v in pairs(core.Reg ) do
		if v == targname then targID = k end
	end
	if targID == 0 then rust.Notice( netuser, targname .. ' was not found in our database!' ) return end
	local data = char[ targID ]	if not data then data = char:Load( targID )	end
	if not data then rust.Notice( netuser, targname .. ' was not found in our database!' ) return end -- Failsafe.
	if not data['mail'] then data['mail'] = {} end
	local concept = {
		['subject'] = {'Your donation!'},
		["txt"] = {'Thanks for donating to The Carbon Project! We really appreciate it! Here are your bags of money! Spend it wisely...'},
		['sender'] = 'The Carbon Project',
		['target'] = targname,
		['date'] = System.DateTime.Now:ToString('M/dd/yyyy'),
		['money'] = {
			['g'] = g,
			['s'] = s,
			['c'] = c,
		},
		['read'] = false
	}
	local uid = 0
	while data.mail[tostring(uid)] do
		uid = uid + 1
	end
	data.mail[ tostring(uid) ] = concept
	char:SaveDataByID( targID, data )
	self:AddDonation( targID, targname, 'Donated for: Gold: ' .. tostring(g) .. '  |  Silver: ' .. tostring(s) .. '  |  Copper: ' .. tostring(c) )
	local b, targuser = rust.FindNetUsersByName( targname )
	if( b ) then rust.Notice( targuser, 'You\'ve got new mail from: The Carbon Project' ) rust.InventoryNotice( targuser, '+1 mail' ) end
	rust.SendChatToUser( netuser, core.sysname, 'Succesfully send mail to ' .. targname )
end

function PLUGIN:DonateItem( netuser, _, args )
	if not dev:isDev( netuser ) then rust.Notice( netuser, 'Unknown chat command!' )return end
	if not args[4] then rust.SendChatToUser( netuser, 'DONATE', '/donateitem amount "Name" ') return end
	local targname = tostring(args[1])
	local targID = 0
	for k,v in pairs(core.Reg ) do
		if v == targname then targID = k end
	end
	if targID == 0 then rust.Notice( netuser, targname .. ' was not found in our database!' ) return end
	local data = char[ targID ]	if not data then data = char:Load( targID )	end
	if not data then rust.Notice( netuser, targname .. ' was not found in our database!' ) return end -- Failsafe.
	if not data['mail'] then data['mail'] = {} end
	local concept = {
		['subject'] = {'Your donation!'},
		["txt"] = {'Thanks for donating to The Carbon Project! We really appreciate it! Here are the items you\'ve requested!'},
		['sender'] = 'The Carbon Project',
		['target'] = targname,
		['date'] = System.DateTime.Now:ToString('M/dd/yyyy'),
		['item'] = {},
		['money'] = {
			['g'] = 0,
			['s'] = 0,
			['c'] = 0,
		},
		['read'] = false
	}
	local y = 2
	while args[y] do
		local amount = tonumber( args[y] )
		if not amount then rust.Notice( netuser, 'Invalid amount on argument ' .. tostring(y) .. ' [' .. tostring(args[y]) .. ' ]' ) return end
		y = y + 1
		local datablock = rust.GetDatablockByName( args[y] )
		if not datablock then rust.Notice( cmdData.netuser, itemname .. ' does not exist! [ ' .. tostring(args[y]) .. ' ] ') return end
		if concept.item[ args[y] ] then concept.item[ args[y] ] = concept.item[ args[y] ] + amount
		else concept.item[ args[y] ] = amount end
		y = y + 1
	end
	local uid = 0
	while data.mail[tostring(uid)] do
		uid = uid + 1
	end
	data.mail[ tostring(uid) ] = concept
	char:SaveDataByID( targID, data )
	local msg = 'Donated for: '
	for k,v in pairs( concept.item ) do
		msg = msg .. tostring(v) .. 'x ' .. k .. ', '
	end
	self:AddDonation( targID, targname, msg )
	local b, targuser = rust.FindNetUsersByName( targname )
	if( b ) then rust.Notice( targuser, 'You\'ve got new mail from: The Carbon Project' ) rust.InventoryNotice( targuser, '+1 mail' ) end
	rust.SendChatToUser( netuser, core.sysname, 'Succesfully send mail to ' .. targname )
end

function PLUGIN:AddDonation(ID, name, msg )
	if not self.Donate[ ID ] then self.Donate[ ID ]={} self.Donate[ ID ]['name']=name end
	local i = 0
	while self.Donate[ ID ][ tostring(i) ] do
		i = i + 1
	end
	self.Donate[ ID ][tostring(i) ] = msg
	self:SaveDon()
end

function PLUGIN:SaveDon()
	self.DonateFile:SetText( json.encode( self.Donate, { indent = true } ) )
	self.DonateFile:Save()
end

