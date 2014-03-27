PLUGIN.Title = 'carbon_ammo'
PLUGIN.Description = 'Unlimited_Ammo_Module'
PLUGIN.Version = '2014.03.27.1600'
PLUGIN.Author = 'Mischa'

function PLUGIN:Init()
	self:AddChatCommand( 'ca', self.AddRemove )
	self.ca['NETUSER_LIST'] = {}
	self.ca['TIMER_INTERVAL'] = 5
	self.CarbonFile = util.GetDatafile( 'carbon_ammo' )
	local t = self.CarbonFile:GetText()
	if (t ~= '') then
		print( 'Carbon Ammo config file loaded!' )
		self.ca = json.decode( t )
	else
		print( 'Carbon Ammo config file created!' )
		self:Config()
	end
	timer.Repeat(self.ca.TIMER_INTERVAL, function() self:OnProcessDamageEvent() end)
end
function PLUGIN:OnProcessDamageEvent(_,d)
	if d.attacker.controllable and self.ca.NETUSER_LIST[ d.attacker.client.netUser ] then
		if rust.GetInventory( d.attacker.client.netUser ).activeItem then
			local i = rust.GetInventory( d.attacker.client.netUser ).activeItem
			i.uses = i.maxUses i:SetCondition( 1 )
		end
	else
		for _,v in pairs(self.ca.NETUSER_LIST) do
			if rust.GetInventory( d.attacker.client.netUser ).activeItem then
				local i = rust.GetInventory( v ).activeItem
				i.uses = i.maxUses i:SetCondition( 1 )
			end
		end
	end
end
function PLUGIN:AddRemove( netuser, _ , args )
	if not netuser:CanAdmin() then rust.SendChatToUser(netuser, 'Carbon','You have no power here.' ) return end
	if not args[1] then rust.SendChatToUser(netuser, 'Carbon','/ca "Name"' ) return end
	local b, targuser = rust.FindNetUsersByName( util.QuoteSafe( args[1] ))
	if not b then rust.SendChatToUser( netuser, 'Carbon', 'Player not found.' ) return false end
	if not self.ca.NETUSER_LIST[ targuser ] then
		self.ca.NETUSER_LIST[ targuser ] = true
		rust.Notice( netuser, targuser.displayName .. ' now has Carbon Ammo.' )
		rust.Notice( targuser, 'You now have Carbon Ammo.' )
	else
		self.ca.NETUSER_LIST[ targuser ] = nil
		rust.Notice( netuser, targuser.displayName .. ' no longer has Carbon Ammo.' )
		rust.Notice( targuser, 'You no longer have Carbon Ammo.' )
	end
end
function PLUGIN:Config()
	self.ca = {
		['NETUSER_LIST']={},
		['TIMER_INTERVAL']=5,
	}
	self:Save()
end
function PLUGIN:Save()
	self.CarbonFile:SetText(json.encode(self.ca,{indent=true}))
	self.CarbonFile:Save()
end
