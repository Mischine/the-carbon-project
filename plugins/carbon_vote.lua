PLUGIN.Title = 'carbon_vote'
PLUGIN.Description = 'voting module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'Mischa & CareX'

function PLUGIN:Init()
	core = cs.findplugin("carbon_core") core:LoadLibrary()

	self:AddChatCommand( 'votekick', self.cmdVoteKick )         -- /votekick "Name"
	self:AddChatCommand( 'voterestart', self.cmdVoteRestart )   -- /voterestart

	self.VoteLogFile = util.GetDatafile( 'carbon_votelog' )
	local log_txt = self.VoteLogFile:GetText()
	if (log_txt ~= '') then
		print( 'Carbon_votelog file loaded!' )
		self.Log = json.decode( log_txt )
	else
		print( 'Creating carbon_votelog file...' )
		self.Log = {
			['kick'] = {},
			['restart'] = ''
		}
		self:SaveLog()
	end

	self.votes = {
		['kick'] = {},
		['restart'] = ''
	}

end

--[[
	with the vote system the whole server can vote to kick someone. I though about giving them a temporary ban too.
	Or they can put a vote up to do a server restart. ( I tested the restart function, and it works =] )
 ]]

-- /votekick "name"
function PLUGIN:cmdVoteKick( netuser, cmd, args )
	local data = char:GetUserData( netuser )
	if not data then rust.Notice( netuser, 'Player data not found.' ) return end
	if not data.reg then rust.Notice( netuser, 'Only registered users can votekick.' ) return end
	if not args[1] then rust.Notice( netuser, '/votekick "Name" ' ) return end
	local targname = util.QuoteSafe( args[1] )
	local b, targuser = rust.FindNetUsersByName( targname )
	if ( not b ) then
		if( targuser == 0 ) then
			rust.Notice( netuser, 'No user found with the name: ' .. util.QuoteSafe( targname ) )
		else
			rust.Notice( netuser, 'Multiple users found with the name: ' .. util.QuoteSafe( targname ) )
		end
	return end
	if self.votes.kick[ targname ] then rust.Notice( netuser, targname .. ' is already in the votekick list.' ) return end
	self.votes.kick[ targname ] = tostring( rust.GetUserID( netuser ))
	rust.BroadcastChat( netuser.displayName .. ' has initialized to kick ' .. targname .. '. /vote yes/no to vote.' )
	if self.Log.kick[ data.name ] then
		table.insert( self.Log.kick[ data.name ], {['target'] = targname, ''})
	else
		self.Log.Kick[ data.name ]['target'] = targname
		self.Log.Kick[ data.name ]['succesful'] = false
	end

	-- Finish him....

end

-- /voterestart
-- rust.RunServerCommand("quit")
function PLUGIN:cmdVoteRestart( netuser, cmd, args )

end

function PLUGIN:SaveLog()
	self.VoteLogFile:SetText( json.encode( self.Log, { indent = true } ) )
	self.VoteLogFile:Save()
end