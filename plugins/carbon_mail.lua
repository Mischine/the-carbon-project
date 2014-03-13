PLUGIN.Title = 'carbon_mail'
PLUGIN.Description = 'mail module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

	self.Concept = {}

end

function PLUGIN:MailNew( cmdData )
	local concept = {
		['subject'] = '',
		['txt'] = '',
		['money'] = {
			['g'] = 0,
			['s'] = 0,
			['c'] = 0,
		},
		['item'] = {},
	}
	local subject
	if cmdData.args[2] then
		subject = tostring(cmdData.args[2])
		local i = 3
		while cmdData.args[i] do
			subject = subject .. ' ' .. cmdData.args[i]
			i = i + 1
		end
	end
	concept.subject = tostring(subject)
	self.Concept[ cmdData.netuser ] = concept
	rust.Notice( cmdData.netuser, 'New mail created. This concept will delete itself in 15 minutes.' )
	timer.Once( 900, function() if self.Concept[ cmdData.netuser ] then self:DelConcept( cmdData.netuser ) end  end)
	local content = {
		['header'] = 'New mail created!',
		['txt'] = 'You\'ve created a new concept. Here are some things you can do before sending it.',
		['list'] = {
			'/mail txt | Will add new text to the mail ( max 100 characters per mail )',
			'/mail items "ItemName" | Will add items to the mail. ( 20 copper per item )',
			'/mail money g s c | Will add money to the mail. ( 20 copper per transaction )',
			'/mail subject | Will add a subject to the mail',
			'/mail cancel | Will delete the concept. ( will return items/money )',
			'When your 15 minutes are up. And you haven\'t send it yet, the items will be transfered back.',
		}
	}
	func:TextBox( cmdData.netuser, content, cmdData.cmd, cmdData.args )
end

-- /mail subject
function PLUGIN:MailSubject( cmdData )
	if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail subject This is a subject' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	local msg = tostring(cmdData.args[2])
	local i = 3
	while cmdData.args[i] do
		msg = msg .. ' ' .. cmdData.args[i]
		i = i + 1
	end
	if concept.subject ~= '' then rust.SendChatToUser( cmdData.netuser, 'Subject changed from: ' .. concept.subject .. ' to: ' .. msg ) end
	concept.subject = tostring(msg)
	self.Concept[ cmdData.netuser ] = concept
	timer.Once( 2, function() rust.SendChatToUser( cmdData.netuser, 'Concept saved.' ) end )
end

-- /mail txt
function PLUGIN:MailTxt( cmdData )
	if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail txt I love kittens!' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	local msg
	if concept.txt ~= '' then msg = concept.txt .. '\n ' ..  tostring( cmdData.args[2] ) else msg = tostring( cmdData.args[2] ) end
	local i = 3
	while cmdData.args[i] do
		msg = msg .. ' ' .. cmdData.args[i]
		i = i + 1
	end
	concept.txt = tostring(msg)
	self.Concept[ cmdData.netuser ] = concept
	timer.Once( 2, function() rust.SendChatToUser( cmdData.netuser, 'Concept saved.' ) end )
end

function PLUGIN:MailMoney( cmdData )
	if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail money 0 13 37 | 0 Gold, 13 Silver, 37 copper.' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	local data = {
		['g'] = 0,
		['s'] = 0,
		['c'] = 0
	}
	if cmdData.args[2] then data.g = tonumber( cmdData.args[2] ) end
	if not data.g then rust.Notice( cmdData.netuser, 'Invalid gold amount! Must be number! ( Input: ' .. tostring(cmdData.args[2]).. ')' ) return end
	if cmdData.args[3] then data.s = tonumber( cmdData.args[3] ) end
	if not data.s then rust.Notice( cmdData.netuser, 'Invalid Silver amount! Must be number! ( Input: ' .. tostring(cmdData.args[3]).. ')' ) return end
	if cmdData.args[4] then data.c = tonumber( cmdData.args[4] ) + 20 end
	if not data.c then rust.Notice( cmdData.netuser, 'Invalid Copper amount! Must be number! ( Input: ' .. tostring(cmdData.args[4]).. ')' ) return end
	local canbuy = econ:canBuy( cmdData.netuser, data.g, data.s, data.c )
	if not canbuy then rust.Notice( cmdData.netuesr, tostring('Not enough money. Money required: G' .. data.g .. ' S' .. data.s .. ' C' .. data.c )) return end
	econ:RemoveBalance( cmdData.netuser, data.g, data.s, data.c )
	data.g = data.g + concept.money.g
	data.s = data.s + concept.money.s
	data.c = data.c + concept.money.c
	rust.SendChatToUser( cmdData.netuser, tostring('Concept now contains: Gold: ' .. data.g .. ' Silver: ' .. data.s .. ' Copper: ' .. data.c ))
	concept.money = data
	self.Concept[ cmdData.netuser ] = concept
	timer.Once( 2, function() rust.SendChatToUser( cmdData.netuser, 'Concept saved.' ) end )
end

function PLUGIN:MailItem( cmdData )
	if not cmdData.args[3] then rust.SendChatToUser( cmdData.netuser, '/mail item 50 "Cooked Chicken Breast"' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	local datablock = rust.GetDatablockByName( tostring(cmdData.args[3]) )
	if not datablock then rust.Notice( cmdData.netuser, tostring(cmdData.args[3]) .. ' does not exist!') return end
	local amount = tonumber( cmdData.args[2] )
	if not amount then rust.Notice( cmdData.netuser, 'Invalid amount! ( Input: ' .. tostring( cmdData.args[2]) .. ')') return end
	local inv = rust.GetInventory( cmdData.netuser )
	if not inv then rust.Notice( cmdData.netuser, 'Inventory not found, try again.' ) return end
	local isUnstackable = func:containsval(econ.unstackable, tostring(cmdDataargs[3]))
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
	if concept.item[ tostring(cmdDataargs[3]) ] then
		concept.item[ tostring(cmdData.args(3)) ] = concept.item[ tostring(cmdData.args(3)) ] + i
	else
		concept.item[ tostring(cmdData.args(3)) ] = i
	end
	rust.SendChatToUser( cmdData.netuser, tostring(i .. 'x ' .. cmdData.args[3] .. ' added to the concept.' ))
	self.Concept[ cmdData.netuser ] = concept
	timer.Once( 2, function() rust.SendChatToUser( cmdData.netuser, 'Concept saved.' ) end )
end

function PLUGIN:MailPv( cmdData )
	if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail pv' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end
	self:ShowMail( concept )
end

function PLUGIN:MailSend( cmdData )
	if not cmdData.args[2] then rust.SendChatToUser( cmdData.netuser, '/mail subject This is a subject' ) return end
	if not self.Concept[ cmdData.netuser ] then rust.Notice( cmdData.netuser, 'You\'ve no concept. Please create one with /mail new' ) return end
	local concept = self.Concept[ cmdData.netuser ]
	if not concept then rust.Notice( cmdData.netuser, 'Concept not found, please make a new concept with /mail new' ) return end

end

function PLUGIN:MailRead( cmdData )

end

function PLUGIN:ShowMail( mail )

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