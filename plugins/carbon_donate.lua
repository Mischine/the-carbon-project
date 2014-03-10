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

end

--[[
	When people donate money, we put it in this JSon File, and they can pick it up whenever they're online.
	This is just temporary until we have it all synced up with the website.
 ]]

function PLUGIN:SaveDon()
	self.DonateFile:SetText( json.encode( self.Donate, { indent = true } ) )
	self.DonateFile:Save()
end

