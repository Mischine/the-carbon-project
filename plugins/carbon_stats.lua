PLUGIN.Title = 'carbon_stats'
PLUGIN.Description = 'statistics module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()

    --LOAD/CREATE TEXT FILE
    self.StatsFile = util.GetDatafile( 'carbon_stats' )
    local stats_txt = self.StatsFile:GetText()
    if (stats_txt ~= '') then
        print( 'carbon_stats file loaded!' )
        self.Stats = json.decode( stats_txt )
    else
        self:CreateNewStatsFile()
        print( 'carbon_stats file is created!' )
    end
end

--PLUGIN:CreateNewStatsFile
function PLUGIN:CreateNewStatsFile()
    self.Stats = {
        ['econ'] = {
            ['itemssold']= 0 ,
            ['itemsbought'] = 0,
            ['totalmoney'] = 0
        },
        ['leaderboard']={
            ['lvl'] = "",
            ['prof']= {
                ['Engineer']= "",
                ['Medic']= "",
                ['Carpenter']="" ,
                ['Armorsmith']="",
                ['Weaponsmith']=""
            },
            ['richest']= "",
            ['pvpkills']= "",
            ['pvekills']= "",
            ['pvpkd']= ""
        }
    }
end