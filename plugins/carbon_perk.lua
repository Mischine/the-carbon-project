PLUGIN.Title = 'carbon_perk'
PLUGIN.Description = 'perk module'
PLUGIN.Version = '0.0.1'
PLUGIN.Author = 'mischa / carex'

function PLUGIN:Init()
    core = cs.findplugin("carbon_core") core:LoadLibrary()
end

function PLUGIN:Stoneskin(combatData)
    if ((combatData.vicuser) and (combatData.vicuser ~= combatData.netuser) and (oodinvicuserData.perks.Stoneskin)) then
        if (vicuserData.perk.Stoneskin.lvl > 0) then
            if (vicuserData.perk.Stoneskin.lvl == 1) then
                damage = tonumber(damage - (damage*.05))
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 2) then
                damage = tonumber(damage - (damage*.10))
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 3) then
                damage = tonumber(damage - (damage*.15))
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 4) then
                damage = tonumber(damage - (damage*.20))
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            elseif (vicuserData.perk.Stoneskin.lvl == 5) then
                damage = tonumber(damage - (damage*.25))
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PLUGIN:perkStoneskin (vicuser): ' .. tostring(damage)) end
            end
        end
    end
    return damage
end


function PLUGIN:Parry(combatData)
    if ((vicuser) and (vicuserData.perks.Parry)) then
        if (vicuserData.perks.Parry.lvl > 0) then
            local roll = core.rnd
            if ((vicuserData.perks.Parry.lvl == 1) and (roll <= 3)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((vicuserData.perks.Parry.lvl == 2) and (roll <= 6)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((vicuserData.perks.Parry.lvl == 3) and (roll <= 9)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((vicuserData.perks.Parry.lvl == 4) and (roll <= 12)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            elseif ((vicuserData.perks.Parry.lvl == 5) and (roll <= 15)) then
                damage = 0
                self:GiveTimedBuff( vicuserData.id, 5 ,'ParryCrit' )
                if debug.list[ netuser.displayName ] then rust.SendChatToUser( debug.list[ netuser.displayName ].targnetuser,'PERK PARRY: ' .. tostring(damage)) end
            end
        end
    end
    return damage
end

function PLUGIN:Parry(combatData)
    --CRITICAL HIT CHECK
    if( char[ combatData.netuserData.id ].buffs[ 'ParryCrit' ]) then
        combatData.dmg.amount = combatData.dmg.amount * 2
        rust.InventoryNotice( combatData.netuser, 'Critical Hit!' )
        char[ combatData.netuserData.id ].buffs[ 'ParryCrit' ] = nil
    end
end

--PLUGIN:GiveTimedBuff
function PLUGIN:GiveTimedBuff( vicuserID, time, buff )
    if not char[ vicuserID ].buffs['ParryCrit'] then
        char[ vicuserID ].buffs['ParryCrit']=true
        timer.Once( time, function()
            if( char[ vicuserID ].buffs[ buff ] ) then char[ vicuserID ].buffs[ buff ] = nil end
        end )
    end
end