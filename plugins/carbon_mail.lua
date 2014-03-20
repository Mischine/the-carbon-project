PLUGIN.Title = 'carbon_mail'
PLUGIN.Description = 'mail module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
	self.Concept = {}
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
		['item'] = {},
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
		['txt'] = 'You\'ve created a new concept. Here are some things you can do before sending it.',
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
	timer.Once( 2, function() rust.InventoryNotice( cmdData.netuser, 'Concept saved.' ) end )
end

-- /mail subject
function PLUGIN:MailSubject( cmdData )
	if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail subject This is a subject' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	local i = 2
	while cmdData.args[i] do
		table.insert( concept.subject, cmdData.args[i])
		i = i + 1
	end
	rust.SendChatToUser(cmdData.netuser, 'Mail', 'Mail subject changed!' )
	self.Concept[ cmdData.netuser ] = concept
	timer.Once( 2, function() rust.InventoryNotice( cmdData.netuser, 'Concept saved.' ) end )
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
	if cmdData.args[4] then data.c = tonumber( cmdData.args[4] + 20) end
	if not data.c then rust.Notice( cmdData.netuser, 'Invalid Copper amount! Must be number! ( Input: ' .. tostring(cmdData.args[4]).. ')' ) return end
	local canbuy = econ:canBuy( cmdData.netuser, data.g, data.s, data.c )
	if not canbuy then rust.Notice( cmdData.netuser, tostring('Not enough money. Money required: G' .. data.g .. ' S' .. data.s .. ' C' .. data.c )) return end
	econ:RemoveBalance( cmdData.netuser, data.g, data.s, data.c )
	data.g = data.g + concept.money.g
	data.s = data.s + concept.money.s
	data.c = data.c + concept.money.c
	rust.SendChatToUser( cmdData.netuser, tostring('Concept now contains: Gold: ' .. data.g .. ' Silver: ' .. data.s .. ' Copper: ' .. data.c ))
	concept.money = data
	self.Concept[ cmdData.netuser ] = concept
	timer.Once( 2, function() rust.InventoryNotice( cmdData.netuser, 'Concept saved.' ) end )
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
	if concept.item[ itemname ] then
		concept.item[ itemname ] = concept.item[ itemname ] + i
	else
		concept.item[ itemname ] = i
	end
	rust.SendChatToUser( cmdData.netuser, tostring(i .. 'x ' .. itemname .. ' added to the concept.' ))
	self.Concept[ cmdData.netuser ] = concept
	timer.Once( 2, function() rust.InventoryNotice( cmdData.netuser, 'Concept saved.' ) end )
end

function PLUGIN:MailPv( cmdData )
	-- if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail pv' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	self:ShowMail( cmdData, concept )
end

function PLUGIN:MailSend( cmdData )
	if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail send "Name"' ) return end
	local targname = util.QuoteSafe( cmdData.args[2] )
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end

end

function PLUGIN:MailRead( cmdData )

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

end

function PLUGIN:DelConcept( netuser )

end

function PLUGIN:MailCancel( netuser )

end

function PLUGIN:MailClear( cmdData )

end

function PLUGIN:MailCollect( cmdData )

end

function PLUGIN:MailInfo( cmdData )

end