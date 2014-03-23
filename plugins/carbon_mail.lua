PLUGIN.Title = 'carbon_mail'
PLUGIN.Description = 'mail module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
	self.Concept = {}

    self.unstackable = {"M4", "9mm Pistol", "Shotgun", "P250", "MP5A4", "Pipe Shotgun", "Bolt Action Rifle", "Revolver", "HandCannon", "Research Kit 1",
	    "Cloth Helmet","Cloth Vest","Cloth Pants","Cloth Boots","Leather Helmet","Leather Vest","Leather Pants","Leather Boots","Rad Suit Helmet",
	    "Rad Suit Vest","Rad Suit Pants","Rad Suit Boots","Kevlar Helmet","Kevlar Vest","Kevlar Pants","Kevlar Boots", "Holo sight","Silencer","Flashlight Mod",
	    "Laser Sight","Flashlight Mod", "Hunting Bow", "Rock","Stone Hatchet","Hatchet","Pick Axe", "Torch", "Furnace", "Bed","Handmade Lockpick", "Workbench",
	    "Camp Fire", "Wood Storage Box","Small Stash","Large Wood Storage", "Sleeping Bag", Rock }
end

function PLUGIN:MailCheck( cmdData )
	local data = char[ cmdData.netuserID ]
	if not data then rust.Notice( cmdData.netuser, 'PlayerData not found!' )return end
	if not data.mail then
		local content = {
			['header'] = 'Mailbox',
			['msg'] = 'Your mailbox is empty.',
		}
		func:TextBox( cmdData.netuser, content, cmdData.cmd, cmdData.args )
	else
		local content = {
			['header'] = 'Mailbox',
			['list'] = {}
		}
		-- Mail
		for k,v in pairs( data.mail ) do
			local msg = '[ ' .. k .. ' ] From: ' .. v.sender .. ' | Subject: ' .. table.concat(v.subject, ' ' )
			if not v.read then msg = '[ NEW ] ' .. msg end
			table.insert( content.list, tostring(msg))
		end
		func:TextBox( cmdData.netuser, content, cmdData.cmd, cmdData.args )
	end
end

function PLUGIN:MailNew( cmdData )
	if self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You already have a concept! Please use /mail cancel ; to delete the concept.' ) return end
	local concept = {
		['subject'] = {},
		['txt'] = {},
		['sender'] = cmdData.netuser.displayName,
		['target'] = '',
		['date'] = System.DateTime.Now:ToString('M/dd/yyyy'),
		['money'] = {
			['g'] = 0,
			['s'] = 0,
			['c'] = 0,
		},
		['read'] = false
	}
	if cmdData.args[2] then
		local i = 2
		while cmdData.args[i] do
			table.insert(concept.subject, cmdData.args[i] )
			cmdData.args[i] = nil
			i = i + 1
		end
	end
	self.Concept[ cmdData.netuser ] = concept
	rust.Notice( cmdData.netuser, 'New mail created. This concept will delete itself in 30 minutes.' )
	timer.Once( 1800, function() if self.Concept[ cmdData.netuser ] then self:DelConcept( cmdData.netuser ) end  end)
	local content = {
		['header'] = 'New mail created!',
		['msg'] = 'You\'ve created a new concept. Here are some things you can do before sending it.',
		['list'] = {
			'/mail txt | Will add new text to the mail ( max 100 characters per mail )',
			'/mail items "ItemName" | Will add items to the mail. ( 20 copper per item )',
			'/mail money g s c | Will add money to the mail. ( 20 copper per transaction )',
			'/mail subject | Will add a subject to the mail',
			'/mail cancel | Will delete the concept. ( will return items/money )',
			'When your 30 minutes are up. And you haven\'t send it yet, the items will be transfered back.',
		}
	}
	func:TextBox( cmdData.netuser, content, cmdData.cmd, cmdData.args )
	timer.Once( 2, function() rust.InventoryNotice( cmdData.netuser, 'Concept created.' ) end )
end

-- /mail subject
function PLUGIN:MailSubject( cmdData )
	if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail subject This is a subject' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	local i = 2
	concept.subject = {}
	while cmdData.args[i] do
		table.insert( concept.subject, cmdData.args[i])
		i = i + 1
	end
	rust.SendChatToUser(cmdData.netuser, 'Mail', 'Mail subject changed!' )
	self.Concept[ cmdData.netuser ] = concept
	timer.Once( 2, function() rust.InventoryNotice( cmdData.netuser, 'Concept saved.' ) end )
	self:ShowMail( cmdData, concept )
end

-- /mail txt
function PLUGIN:MailTxt( cmdData )
	if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail txt I love kittens!' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	local i = 2
	while cmdData.args[i] do
		table.insert( concept.txt, cmdData.args[i])
		i = i + 1
	end
	rust.SendChatToUser(cmdData.netuser, 'Mail', 'Mail text updated!' )
	self.Concept[ cmdData.netuser ] = concept
	timer.Once( 2, function() rust.InventoryNotice( cmdData.netuser, 'Concept saved.' ) end )
	self:ShowMail( cmdData, concept )
end

function PLUGIN:MailMoney( cmdData )
	if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail money 0 13 37 | 0 Gold, 13 Silver, 37 copper.' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	local data = {
		['g'] = 0,
		['s'] = 0,
		['c'] = 0,
		['txt'] = ''
	}
	if cmdData.args[2] then data.g = tonumber( cmdData.args[2] ) end
	if not data.g then rust.Notice( cmdData.netuser, 'Invalid gold amount! Must be number! ( Input: ' .. tostring(cmdData.args[2]).. ')' ) return end
	if cmdData.args[3] then data.s = tonumber( cmdData.args[3] ) end
	if not data.s then rust.Notice( cmdData.netuser, 'Invalid Silver amount! Must be number! ( Input: ' .. tostring(cmdData.args[3]).. ')' ) return end
	if cmdData.args[4] then data.c = tonumber( cmdData.args[4] ) end
	if not data.c then rust.Notice( cmdData.netuser, 'Invalid Copper amount! Must be number! ( Input: ' .. tostring(cmdData.args[4]).. ')' ) return end
	local canbuy = econ:canBuy( cmdData.netuser, data.g, data.s, data.c+20 )
	if not canbuy then rust.Notice( cmdData.netuser, tostring('Not enough money. Money required: G' .. data.g .. ' S' .. data.s .. ' C' .. data.c+20 )) return end
	econ:RemoveBalance( cmdData.netuser, data.g, data.s, data.c+20 )
	data.g = data.g + concept.money.g
	data.s = data.s + concept.money.s
	data.c = data.c + concept.money.c
	concept.money = data
	self.Concept[ cmdData.netuser ] = concept
	timer.Once( 2, function() rust.InventoryNotice( cmdData.netuser, 'Concept saved.' ) end )
	self:ShowMail( cmdData, concept )
end

function PLUGIN:MailItem( cmdData )
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	if not cmdData.args[3] then rust.SendChatToUser( cmdData.netuser, '/mail item 50 "Cooked Chicken Breast"' ) return end
	local amount = tonumber( cmdData.args[2])
	if not amount then rust.Notice( cmdData.netuser, 'Invalid amount! ( Input: ' .. tostring( cmdData.args[2]) .. ')') return end
	local concept = self.Concept[ cmdData.netuser ]
	local itemname = ''
	local x = 3
	while cmdData.args[x] do
		if itemname ~= '' then
			itemname = itemname .. ' ' .. cmdData.args[x]
		else
			itemname = cmdData.args[x]
		end
		x = x + 1
	end
	itemname = tostring(itemname)
	local datablock = rust.GetDatablockByName( itemname )
	if not datablock then rust.Notice( cmdData.netuser, itemname .. ' does not exist!') return end
	local inv = rust.GetInventory( cmdData.netuser )
	if not inv then rust.Notice( cmdData.netuser, 'Inventory not found, try again.' ) return end
	local isUnstackable = func:containsval(econ.unstackable, itemname)
	local i = 0
	local item = inv:FindItem(datablock)
	if (item) then
		if (not isUnstackable) then
			while (i < amount) do
				if (item.uses > 0) then
					item:SetUses(item.uses - 1)
					i = i + 1
				else
					inv:RemoveItem(item)
					item = inv:FindItem(datablock)
					if (not item) then
						break
					end
				end
			end
		else
			while (i < amount) do
				inv:RemoveItem(item)
				i = i + 1
				item = inv:FindItem(datablock)
				if (not item) then
					break
				end
			end
		end
	else rust.Notice(netuser, "Item not found in inventory!") return end
	if ((not isUnstackable) and (item) and (item.uses <= 0)) then inv:RemoveItem(item) end
	if not concept.item then concept.item = {} end
	if concept.item[ itemname ] then
		concept.item[ itemname ] = concept.item[ itemname ] + i
	else
		concept.item[ itemname ] = i
	end
	rust.SendChatToUser( cmdData.netuser, tostring(i .. 'x ' .. itemname .. ' added to the concept.' ))
	self.Concept[ cmdData.netuser ] = concept
	timer.Once( 2, function() rust.InventoryNotice( cmdData.netuser, 'Concept saved.' ) end )
	self:ShowMail( cmdData, concept )
end

function PLUGIN:MailPv( cmdData )
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	self:ShowMail( cmdData, concept )
end

function PLUGIN:MailSend( cmdData )
	if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail send "Name"' ) return end
	local targname = util.QuoteSafe( cmdData.args[2] )
	-- if targname == cmdData.netuser.displayName then rust.Notice( cmdData.netuser, 'You cannot send mail to yourself!' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	local canbuy = econ:canBuy( cmdData.netuser, 0, 0, 5 )
	if not canbuy then rust.Notice( cmdData.netuser, 'Insuficient funds! Need 5 copper to send a mail!' ) return end
	local targname = cmdData.args[2]
	local targID = 0
	for k,v in pairs(core.Reg ) do
		if v == targname then targID = k end
	end
	if targID == 0 then rust.Notice( cmdData.netuser, targname .. ' was not found in our database!' ) return end
	local data = char[ targID ]
	if not data then
		data = char:Load( targID )
	end
	if not data then rust.Notice( cmdData.netuser, targname .. ' was not found in our database!' ) return end -- Failsafe.
	if not data['mail'] then rust.BroadcastChat( 'data.mail created' ) data['mail'] = {} end
	local uid = 0
	while data.mail[tostring(uid)] do
		uid = uid + 1
	end
	econ:RemoveBalance( cmdData.netuser, 0,0,5 )
	concept.target = targname
	data.mail[ tostring(uid) ] = concept
	char:SaveDataByID( targID, data )
	local b, targuser = rust.FindNetUsersByName( targname )
	if( b ) then rust.Notice( targuser, 'You\'ve got new mail from: ' .. cmdData.netuser.displayName ) rust.InventoryNotice( targuser, '+1 mail' ) end
	rust.SendChatToUser( cmdData.netuser, core.sysname, 'Succesfully send mail to ' .. targname )
	self.Concept[ cmdData.netuser ] = nil
	rust.InventoryNotice( cmdData.netuser, 'Concept deleted' )
end

function PLUGIN:MailRead( cmdData )
	if not cmdData.args[2] then rust.Notice( cmdData.netuser, '/mail read #ID' ) return end
	local ID = tonumber( cmdData.args[2] )
	if not ID then rust.Notice( cmdData.netuser, 'Invalid ID!' ) return end
	local data = char[ cmdData.netuserID ]
	if not data then rust.Notice( cmdData.netuser, 'PlayerData not found!' ) return end
	if not data.mail then rust.Notice( cmdData.netuser, 'You have no new mail!' ) return end
	if not data.mail[ tostring(ID) ] then rust.Notice( cmdData.netuser, 'Mail ID [' .. tostring(ID) .. '] not found!' ) return end
	local mail = data.mail[ tostring(ID)]
	if not mail then rust.Notice( cmdData.netuser, 'Mail ID [' .. tostring(ID) .. '] not found!' ) return end
	mail.read = true
	self:ShowMail( cmdData, mail )
	char:Save( cmdData.netuser )
end

function PLUGIN:ShowMail( cmdData, mail )
	local txt = table.concat(mail.txt, ' ' )
	local subject = table.concat(mail.subject, ' ' )
	if subject ~= '' then mail.subject = func:WordWrap(subject, 90) end
	if txt ~= '' then mail.txt = func:WordWrap(txt, 90) end
	rust.SendChatToUser(cmdData.netuser,core.sysname,' ')
	rust.SendChatToUser(cmdData.netuser,core.sysname,'╔════════════════════════════════════════════════')
	if mail.subject or mail.from or mail.date then
		if subject ~= '' then for _, v in ipairs(mail.subject) do rust.SendChatToUser(cmdData.netuser,core.sysname,'║ ' .. tostring(v)) end
		else rust.SendChatToUser(cmdData.netuser,core.sysname,'║ No subject.') end
		rust.SendChatToUser(cmdData.netuser,core.sysname,'╟────────────────────────────────────────────────')
		if mail.sender then rust.SendChatToUser(cmdData.netuser,core.sysname,'║ From: ' .. mail.sender) end
		if mail.target then rust.SendChatToUser(cmdData.netuser,core.sysname,'║ To: ' .. mail.target) end
		if mail.date then rust.SendChatToUser(cmdData.netuser,core.sysname,'║ Date: ' .. mail.date) end
		rust.SendChatToUser(cmdData.netuser,core.sysname,'╟────────────────────────────────────────────────')
	end
	if txt ~= '' then for _, v in ipairs(mail.txt) do rust.SendChatToUser(cmdData.netuser,core.sysname,'║ ' .. tostring(v)) end
	else rust.SendChatToUser(cmdData.netuser,core.sysname,'║ No text attached.') end
	if mail.money.g > 0 or mail.money.s > 0 or mail.money.c > 0 then
		rust.SendChatToUser(cmdData.netuser,core.sysname,'╟────────────────────────────────────────────────')
		rust.SendChatToUser(cmdData.netuser,core.sysname,'║ Money attached: ' .. tostring('Gold:' .. mail.money.g .. ' Silver: ' .. mail.money.s .. ' Copper: ' .. mail.money.c))
		rust.SendChatToUser(cmdData.netuser,core.sysname,'╟────────────────────────────────────────────────')
	end
	if mail.item then
		rust.SendChatToUser(cmdData.netuser,core.sysname,'╟────────────────────────────────────────────────')
		rust.SendChatToUser(cmdData.netuser,core.sysname,'║ items attached: ')
		for k,v in pairs( mail.item ) do
			rust.SendChatToUser(cmdData.netuser,core.sysname,'║ - ' .. tostring(v) .. 'x ' .. tostring(k))
		end
		rust.SendChatToUser(cmdData.netuser,core.sysname,'║ To claim the items attached to this mail; /mail claim [#ID]')
		rust.SendChatToUser(cmdData.netuser,core.sysname,'╟────────────────────────────────────────────────')
	end
	if mail.xp and mail.xp > 0 then
		rust.SendChatToUser(cmdData.netuser,core.sysname,'╟────────────────────────────────────────────────')
		rust.SendChatToUser(cmdData.netuser,core.sysname,'║ XP Attached: ' .. tostring( mail.xp ))
		rust.SendChatToUser(cmdData.netuser,core.sysname,'╟────────────────────────────────────────────────')
	end
	if mail.date then
		rust.SendChatToUser(cmdData.netuser,core.sysname,'╟════════════════════════════════════════════════')
		rust.SendChatToUser(cmdData.netuser,core.sysname,'║ Send date: ' .. tostring( mail.date ))
		rust.SendChatToUser(cmdData.netuser,core.sysname,'╚════════════════════════════════════════════════')
		rust.SendChatToUser(cmdData.netuser,core.sysname,' ')
	else
		rust.SendChatToUser(cmdData.netuser,core.sysname,'╚════════════════════════════════════════════════')
		rust.SendChatToUser(cmdData.netuser,core.sysname,' ')
	end
end

function PLUGIN:MailDel( cmdData )
	if not cmdData.args[2] then rust.Notice( cmdData.netuser, '/mail del #ID' ) return end
	local ID = tonumber( cmdData.args[2] )
	if not ID then rust.Notice( cmdData.netuser, 'Invalid ID!' ) return end
	local data = char[ cmdData.netuserID ]
	if not data then rust.Notice( cmdData.netuser, 'PlayerData not found!' ) return end
	if not data.mail then rust.Notice( cmdData.netuser, 'You have no new mail!' ) return end
	if not data.mail[ tostring(ID) ] then rust.Notice( cmdData.netuser, 'Mail ID [' .. tostring(ID) .. '] not found!' ) return end
	local mail = data.mail[ tostring(ID)]
	if not mail then rust.Notice( cmdData.netuser, 'Mail ID [' .. tostring(ID) .. '] not found!' ) return end
	local isgone = self:CheckAttachments( cmdData, mail )
	if not isgone then return end
	data.mail[ tostring(ID) ] = nil
	local i = 0
	for _, _ in pairs( data.mail ) do i = i + 1 end
	if i == 0 then data.mail = nil end
	rust.SendChatToUser( cmdData.netuser, core.sysname, 'Mail [' .. tostring(ID) .. '] succesfully deleted.' )
	char:Save( cmdData.netuser )
end

function PLUGIN:MailCancel( cmdData )
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	local isgone = self:CheckAttachments( cmdData, mail )
	if not isgone then return end
	self.Concept[ cmdData.netuser ] = nil
	rust.SendChatToUser( cmdData.netuser, core.sysname, 'Succesfully deleted the concept' )
	rust.InventoryNotice( cmdData.netuser, core.sysname, 'Concept deleted' )
end

function PLUGIN:MailClear( cmdData )
	local data = char[ cmdData.netuserID ]
	if not data then rust.Notice( cmdData.netuser, 'Playerdata not found!' ) return end
	if not data.mail then rust.Notice( cmdData.netuser, 'No mail found.' ) return end
	local i = 0
	for _, v in pairs( data.mail ) do
		local isgone = self:CheckAttachments( cmdData, v )
		if not isgone then return end
		i = i + 1
	end
	data.mail = nil
	rust.SendChatToUser( cmdData.netuser, 'Succesfully cleared ' .. tostring(i) .. ' mail from your inbox.' )
	char:Save( cmdData.netuser )
end

function PLUGIN:MailCollect( cmdData ) -- /mail collect ID
	if not cmdData.args[2] then rust.Notice( cmdData.netuser, '/mail del #ID' ) return end
	local ID = tonumber( cmdData.args[2] )
	if not ID then rust.Notice( cmdData.netuser, 'Invalid ID!' ) return end
	local data = char[ cmdData.netuserID ]
	if not data then rust.Notice( cmdData.netuser, 'PlayerData not found!' ) return end
	if not data.mail then rust.Notice( cmdData.netuser, 'You have no new mail!' ) return end
	if not data.mail[ tostring(ID) ] then rust.Notice( cmdData.netuser, 'Mail ID [' .. tostring(ID) .. '] not found!' ) return end
	local mail = data.mail[ tostring(ID)]
	if not mail then rust.Notice( cmdData.netuser, 'Mail ID [' .. tostring(ID) .. '] not found!' ) return end
	if mail.item or mail.money.g > 0 or mail.money.s > 0 or mail.money.c > 0 or mail.xp then
		local isgone = self:CheckAttachments( cmdData, mail )
		if not isgone then return end
		rust.SendChatToUser( cmdData.netuser, core.sysname, 'Succesfully collected items/money from mail [ ' .. tostring( ID ) ..' ]' )
		return
	end
	rust.SendChatToUser( cmdData.netuser, core.sysname, 'Nothing to collect from this mail [ ' .. tostring( ID ) ..' ]' )
end

function PLUGIN:MailInfo( cmdData )
	-- TODO: Finish MailInfo
end

function PLUGIN:CheckAttachments( cmdData, mail ) -- This checks if there are any items/money to return.
	if mail.money.g > 0 or mail.money.s > 0 or mail.money.c > 0 then
		econ:AddBalance( cmdData.netuser, mail.money.g, mail.money.s, mail.money.c )
		mail.money.g = 0
		mail.money.s = 0
		mail.money.c = 0
	end
	if mail.xp and mail.xp > 0 then
		char:GiveXp(cmdData, mail.xp, false, true )
		mail.xp = nil
	end
	local inv = rust.GetInventory( cmdData.netuser )
	if not inv then rust.Notice( cmdData.netuser, 'Inventory not found! Try relogging.' )return false end
	if mail.item then
		for k, v in pairs( mail.item ) do
			local datablock = rust.GetDatablockByName( k )
			if not datablock then rust.Notice( cmdData.netuser, ' Datablock not found, report this to a GM please. ') return end
			local isUnstackable = func:containsval( self.unstackable, k )
			local invamount = v if( isUnstackable ) then invamount = v * 250 end
			local amountleft = self:hasEnoughSlots( inv, invamount, k, isUnstackable )
			inv:AddItemAmount( datablock, v - amountleft )
			if amountleft > 0 then
				mail.item[ k ] = amountleft
				char:Save( cmdData.netuser )
				rust.Notice( cmdData.netuser, 'Not enough inventory space for ' ..  tostring(amountleft) .. 'x ' .. k ..  '' )
				return false
			end
			v = nil
		end
	end
	char:Save( cmdData.netuser )
	return true
end

function PLUGIN:hasEnoughSlots( inv, uses, itemname, isUnstackable )
	for i = 0, 35 do
		local b, item = inv:GetItem( i )
		if b then
			if item.datablock.name == itemname and not isUnstackable then
				uses = uses - (250 - item.uses)
			end
		else
			uses = uses - 250
		end
		if uses <= 0 then return 0 end
		i = i + 1
	end
	if isUnstackable then uses = uses / 250 end
	rust.BroadcastChat( 'uses: ' .. tostring( uses ))
	if uses <= 0 then return 0 end
	return uses
end
