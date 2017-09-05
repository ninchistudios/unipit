
groupCounter = 100
unitCounter = 100

function DropoffGroupDirect(count, radius, xCenter, yCenter, xDest, yDest)
    local group = {
        ["visible"] = false,
        ["taskSelected"] = true,
        ["groupId"] = groupCounter,
        ["hidden"] = false,
        ["units"] = {},
        ["y"] = yCenter,
        ["x"] = xCenter,
        ["name"] = "GroupName" .. groupCounter,
        ["start_time"] = 0,
        ["task"] = "Ground Nothing",
        ["route"] = {
            ["points"] = 
            {
                [1] = 
                {
                    ["alt"] = 41,
                    ["type"] = "Turning Point",
                    ["ETA"] = 0,
                    ["alt_type"] = "BARO",
                    ["formation_template"] = "",
                    ["y"] = yCenter,
                    ["x"] = xCenter,
                    ["ETA_locked"] = true,
                    ["speed"] = 5.5555555555556,
                    ["action"] = "Diamond",
                    ["task"] = 
                    {
                        ["id"] = "ComboTask",
                        ["params"] = 
                        {
                            ["tasks"] = 
                            {
                            }, -- end of ["tasks"]
                        }, -- end of ["params"]
                    }, -- end of ["task"]
                    ["speed_locked"] = false,
                }, -- end of [1]
                [2] = 
                {
                    ["alt"] = 54,
                    ["type"] = "Turning Point",
                    ["ETA"] = 52.09716824195,
                    ["alt_type"] = "BARO",
                    ["formation_template"] = "",
                    ["y"] = yDest,
                    ["x"] = xDest,
                    ["ETA_locked"] = false,
                    ["speed"] = 5.5555555555556,
                    ["action"] = "Diamond",
                    ["task"] = 
                    {
                        ["id"] = "ComboTask",
                        ["params"] = 
                        {
                            ["tasks"] = 
                            {
                            }, -- end of ["tasks"]
                        }, -- end of ["params"]
                    }, -- end of ["task"]
                    ["speed_locked"] = false,
                }, -- end of [2]
            }, -- end of ["points"]
        }, -- end of ["route"]
    }

    groupCounter = groupCounter + 1
    
    for i = 1,count do  
        local angle = math.pi * 2 * (i-1) / count
        local xofs = math.cos(angle) * radius
        local yofs = math.sin(angle) * radius
        local unitType = "Soldier M4"
        if i < 4 then
            unitType = "Soldier M249"
        end
        group.units[i] = NewSoldierUnit(xCenter + xofs, yCenter + yofs, angle, unitType)
        
    end
    
    return group
end

function NewSoldierUnit(x, y, heading, unitType)
    local unit = {
        ["y"] = y,
        ["type"] = unitType,
        ["name"] = "Unitname" .. unitCounter,
        ["unitId"] = unitCounter,
        ["heading"] = heading,
        ["playerCanDrive"] = true,
        ["skill"] = "Excellent",
        ["x"] = x,
    }
    
    unitCounter = unitCounter + 1
    
    return unit    
end


PickupZones = {
    [1] = {
        ZoneName = "PickupZone",
        SmokeColor = trigger.smokeColor.Blue,
    },
}

DropoffZones = {
    [1] = {
        Name = "Nuclear Plant (Red)",
        ZoneName = "DropoffZone1",
        SmokeColor = trigger.smokeColor.Red,
        DropFunction = DropoffGroupDirect
    },
    [2] = {
        Name = "Rail Station (Orange)",
        ZoneName = "DropoffZone2",
        SmokeColor = trigger.smokeColor.Orange,
        DropFunction = DropoffGroupDirect
    },
    [3] = {
        Name = "City Center (Green)",
        ZoneName = "DropoffZone3",
        SmokeColor = trigger.smokeColor.Green,
        DropFunction = DropoffGroupDirect
    },
    [4] = {
        Name = "Hospitals (Blue)",
        ZoneName = "DropoffZone4",
        SmokeColor = trigger.smokeColor.Blue,
        DropFunction = DropoffGroupDirect
    },
}

function SpawnSmoke(smokeX, smokeY, smokeColor)
    local pos2 = { x = smokeX, y = smokeY }
    local alt = land.getHeight(pos2)
    local pos3 = {x=pos2.x, y=alt, z=pos2.y}
    trigger.action.smoke(pos3, smokeColor)
end

function SmokeTimer(arg, time)    
    for i=1,#PickupZones do
       local zone = trigger.misc.getZone(PickupZones[i].ZoneName)
       SpawnSmoke(zone.point.x, zone.point.z, PickupZones[i].SmokeColor)
    end
    
    for i=1,#DropoffZones do
       local zone = trigger.misc.getZone(DropoffZones[i].ZoneName)
       SpawnSmoke(zone.point.x, zone.point.z, DropoffZones[i].SmokeColor)
    end
    
    return time + 270
end

UnitStateTable = {}

function UnitRadioCommand(unitName)
    local unit = Unit.getByName(unitName)
    
    if unit == nil then
        UnitStateTable[unitName] = false
        return
    end
    
    local unitId = unit:getID()
    local group = unit:getGroup()
    local groupName = group:getName()
    local playerName = unit:getPlayerName()
    
    if UnitStateTable[unitName] == nil then
        UnitStateTable[unitName] = false
    end
    
    local pickupZone = UnitInAnyPickupZone(unit)
    local dropoffZone = UnitInAnyDropoffZone(unit)
    
    if pickupZone ~= nil then
        UnitStateTable[unitName] = true
        trigger.action.outText(playerName .. " (" .. groupName .. ") has 11 troops on board.", 10)
    else
        if dropoffZone ~= nil then
            if UnitStateTable[unitName] == true then
                local unitpos = unit:getPoint()
                local triggerZone = trigger.misc.getZone(dropoffZone.ZoneName)
                local newGroup = dropoffZone.DropFunction(11, 15, unitpos.x, unitpos.z, triggerZone.point.x, triggerZone.point.z)
                coalition.addGroup(country.id.USA, Group.Category.GROUND, newGroup)
                
                UnitStateTable[unitName] = false
                
                trigger.action.outText(playerName .. " (" .. groupName .. ") just dropped 11 troops.", 10)
            else
                trigger.action.outText(playerName .. " (" .. groupName .. ") didn't have any troops to drop.", 10)
            end
        else
            -- landed in nomands
            trigger.action.outText(playerName .. " (" .. groupName .. ") isn't in a pickup or dropoff zone.", 10)
        end
    end       
end

RadioCommandTable = {}

function AddRadioCommand(unitName)
    if RadioCommandTable[unitName] == nil then
        local unit = Unit.getByName(unitName)
        if unit == nil then
            return
        end
        
        local group = unit:getGroup()
        if group == nil then
            return
        end
        
        local gid = group:getID()
        
        missionCommands.addCommandForGroup(gid, "Load/unload Troops", nil, UnitRadioCommand, unitName)
        RadioCommandTable[unitName] = true
    end
end


function AddRadioCommands(arg, time)
    AddRadioCommand("HueyPilot1")
    AddRadioCommand("HueyPilot2")
    AddRadioCommand("HueyPilot3")
    AddRadioCommand("HueyPilot4")
    AddRadioCommand("HueyPilot5")
    AddRadioCommand("HueyPilot6")
    AddRadioCommand("HueyPilot7")
    AddRadioCommand("HueyPilot8") 
    AddRadioCommand("HueyPilot9")       
    return time + 5
end

function GetDistance(xUnit, yUnit, xZone, yZone)
    local xDiff = xUnit - xZone
    local yDiff = yUnit - yZone
    return math.sqrt(xDiff * xDiff + yDiff * yDiff)    
end


function FindNearestDropoffZone(unit)
    local minDist = 5000
    local minZone = nil
    local unitpos = unit:getPoint()
    
    for i=1,#DropoffZones do
        local zone = DropoffZones[i]
        local triggerZone = trigger.misc.getZone(zone.ZoneName)
        local dist = GetDistance(unitpos.x, unitpos.z, triggerZone.point.x, triggerZone.point.z)
        if dist < minDist then
            minDist = dist
            minZone = zone
        end
    end
    
    return minZone    
end


function StatusReport(arg, time)
    -- array of Group function coalition.getGroups(enum coalition.side coalition, enum Group.Category groupCategory or nil)
    -- array of Unit function Group.getUnits(Group self)
    -- enum country.id CoalitionObject.getCountry(CoalitionObject self)

    local zoneTable = {}

    for i=1,#DropoffZones do
        zoneTable[DropoffZones[i].Name] = 0
    end

    local groups = coalition.getGroups(coalition.side.RED, Group.Category.GROUND)
    env.info("Got groups: " .. #groups, false)
    for i=1,#groups do
        local group = groups[i]
        if group ~= nil then
            local units = group:getUnits()
            for j=1,#units do
                local unit = units[j]
                if unit ~= nil then
                    local country = unit:getCountry()
                    if country == 17 then       -- if INSURGENT
                        local zone = FindNearestDropoffZone(unit)
                        if zone ~= nil then
                            zoneTable[zone.Name] = zoneTable[zone.Name] + 1
                        end
                    end
                end
            end
        end
    end

    local text = "MISSION STATUS  -  See mission briefing for details\n\n"

    for k,v in pairs(zoneTable) do
        env.info("Append status [" .. tostring(k) .. "] [" .. tostring(v) .. "]", false)
        text = text .. tostring(k) .. ": " .. tostring(v) .. " insurgent units remain.\n"
    end
    
    
    trigger.action.outText(text, 20)
    
    return time + 45
end
   

do
    timer.scheduleFunction(SmokeTimer, nil, timer.getTime() + 5)
    timer.scheduleFunction(AddRadioCommands, nil, timer.getTime() + 5)
    timer.scheduleFunction(StatusReport, nil, timer.getTime() + 45)
end


function UnitInAnyPickupZone(unit)
    for i=1,#PickupZones do
        if UnitInZone(unit, PickupZones[i]) then
            return PickupZones[i]
        end
    end
    
    return nil
end

function UnitInAnyDropoffZone(unit)
    for i=1,#DropoffZones do
        if UnitInZone(unit, DropoffZones[i]) then
            return DropoffZones[i]
        end
    end
    
    return nil
end


function UnitInZone(unit, zone)
    if unit:inAir() then
        return false
    end
    
    local triggerZone = trigger.misc.getZone(zone.ZoneName)
    local group = unit:getGroup()
    local groupid = group:getID()
    local unitpos = unit:getPoint()
    local xDiff = unitpos.x - triggerZone.point.x
    local yDiff = unitpos.z - triggerZone.point.z
    local dist = math.sqrt(xDiff * xDiff + yDiff * yDiff)
    
    if dist > triggerZone.radius then
        return false
    end
    
    return true
end


