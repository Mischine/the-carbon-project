PLUGIN.Title = 'carbon_lang'
PLUGIN.Description = 'language localization database'
PLUGIN.Version = '0.0.2'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    --LOAD/CREATE LANGUAGE FILE
    self.TextFile = util.GetDatafile( 'carbon_lang' )
    local lang_txt = self.TextFile:GetText()
    if (lang_txt ~= '') then
        print( 'Carbon lang file loaded!' )
        self.Text = json.decode( lang_txt )
    else
        print( 'Creating carbon lang file...' )
        self:SetLocalization()
    end
    self:AddChatCommand( 'updatelang', self.SetLocalization )

end

function PLUGIN:SetLocalization()
    self.Text = {
        ['available']={'english','russian'},
        ['c'] = {
            ['english'] = {
                ['level'] = 'Level',
                ['experience'] = 'Experience',
                ['deathpenalty'] = 'Death Penalty',
                ['cmds'] = {'attr','skills','perks'}
            },
            ['russian'] = {
                ['level'] = 'уровень',
                ['experience'] = 'опыт',
                ['deathpenalty'] = 'смертная казнь',
            }
        },
        ['attr'] = {
            ['strength'] = 'Strength',
            ['agility'] = 'Agility',
            ['stamina'] = 'Stamina',
            ['intellect'] = 'Intellect',
            ['cmds'] = {'add [#] [str|agi|sta|int]', 'reset'}

        }
    }
    self:TextSave()
end
-- DATA UPDATE AND SAVE
function PLUGIN:TextSave()
    print('Saving language data.')
    self.TextFile:SetText( json.encode( self.Text, { indent = true } ) )
    self.TextFile:Save()
    self:LangUpdate()
end
function PLUGIN:LangUpdate()
    self.TextFile = util.GetDatafile( 'carbon_lang' )
    local lang_txt = self.TextFile:GetText()
    self.Text = json.decode ( lang_txt )
end