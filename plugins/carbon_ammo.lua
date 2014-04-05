PLUGIN.Title = 'carbon_ammo'
PLUGIN.Description = 'Unlimited_Ammo_Module'
PLUGIN.Version = '2014.03.27.1600'
PLUGIN.Author = 'Mischa'

function PLUGIN:Init()
	self:AddChatCommand( 'ca', self.AddRemove )
	self['CA_NETUSER_LIST'] = {}
	self['CA_TIMER_INTERVAL'] = 5
end
function PLUGIN:PostInit()
	timer.Repeat(self['CA_TIMER_INTERVAL'], function() self:OnProcessDamageEvent() end)
end

function PLUGIN:OnProcessDamageEvent(_,d)
	if d then
		if d.attacker.controllable and self['CA_NETUSER_LIST'][ d.attacker.client.netUser ] then
			if rust.GetInventory( d.attacker.client.netUser ).activeItem then
				local i = rust.GetInventory( d.attacker.client.netUser ).activeItem
				i.uses = i.maxUses i:SetCondition( 1 )
			end
		end
	else
		for k,v in pairs(self['CA_NETUSER_LIST']) do
			rust.BroadcastChat(tostring(k) .. '   ' .. tostring(v))
			if v then
				if rust.GetInventory( k ).activeItem then
					local i = rust.GetInventory( k ).activeItem
					i.uses = i.maxUses i:SetCondition( 1 )
				end
			end
		end
	end
end
function PLUGIN:AddRemove( netuser, _ , args )
	if not netuser:CanAdmin() then rust.SendChatToUser(netuser, 'Carbon','You have no power here.' ) return end
	if not args[1] then rust.SendChatToUser(netuser, 'Carbon','/ca "Name"' ) return end
	local b, targuser = rust.FindNetUsersByName( util.QuoteSafe( args[1] ))
	if not b then rust.SendChatToUser( netuser, 'Carbon', 'Player not found.' ) return false end
	if not self['CA_NETUSER_LIST'][ targuser ] then
		self['CA_NETUSER_LIST'][ targuser ] = true
		if netuser ~= targuser then
			rust.Notice( netuser, targuser.displayName .. ' now has Carbon Ammo.' )
		else
			rust.Notice( targuser, 'You now have Carbon Ammo.' )
		end
	else
		self['CA_NETUSER_LIST'][ targuser ] = nil
		if netuser ~= targuser then
			rust.Notice( netuser, targuser.displayName .. ' no longer has Carbon Ammo.' )
		else
			rust.Notice( targuser, 'You no longer have Carbon Ammo.' )
		end
	end
end