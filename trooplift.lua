
groupCounter = 100
unitCounter = 100
unitsLiftableLimit = 3
unitsLiftedCounter = 0
unitsInsertedCounter = 0
debugit = true

UnitStateTable = {}
RadioCommandTable = {}

PickupZones = {
    [1] = {
        Name = "PZ ORANGE",
		ZoneName = "PZORANGE",
		SmokeColor = trigger.smokeColor.Orange
    }
}

DropoffZones = {
    [1] = {
        Name = "DZ RED",
        ZoneName = "DZRED",
        SmokeColor = trigger.smokeColor.White,
        DropFunction = DropoffGroupDirect
    }
}

-- builds & returns a [count] man dropoff group with 2 waypoints
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

-- returns a new soldier unit
-- TODO change skill to random?
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

function SpawnSmoke(smokeX, smokeY, smokeColor)
    local pos2 = { x = smokeX, y = smokeY }
    local alt = land.getHeight(pos2)
    local pos3 = {x=pos2.x, y=alt, z=pos2.y}
    trigger.action.smoke(pos3, smokeColor)
end

-- called every 270 sec to refresh smoke
function SmokeTimer(arg, time)    
    
	if unitsLiftedCounter < unitsLiftableLimit then
		for i=1,#PickupZones do
			local zone = trigger.misc.getZone(PickupZones[i].ZoneName)
			SpawnSmoke(zone.point.x, zone.point.z, PickupZones[i].SmokeColor)
		end
	end
    
    if unitsInsertedCounter < unitsLiftableLimit then
		for i=1,#DropoffZones do
			local zone = trigger.misc.getZone(DropoffZones[i].ZoneName)
			SpawnSmoke(zone.point.x, zone.point.z, DropoffZones[i].SmokeColor)
		end
	end
    
    return time + 270
end

function UnitRadioCommand(unitName)
    local unit = Unit.getByName(unitName)
    DebugIt("Radio Command from unit " .. unitName)	
	
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
		if unitsLiftedCounter >= unitsLiftableLimit then
			MistMessage(playerName .. " (" .. groupName .. ") wave off, all available units lifted.")
		elseif UnitStateTable[unitName] == true then
			MistMessage("Unable to load more troops: " .. playerName .. " (" .. groupName .. ") is at MTOW.")
		else
			UnitStateTable[unitName] = true
			MistMessage(playerName .. " (" .. groupName .. ") loaded 10 troops (2,200 lb).")
			SetHumping(unitName,true)
			unitsLiftedCounter = unitsLiftedCounter + 1
		end
    elseif dropoffZone ~= nil then
            if UnitStateTable[unitName] == true then
                local unitpos = unit:getPoint()
                local triggerZone = trigger.misc.getZone(dropoffZone.ZoneName)
                local newGroup = DropoffGroupDirect(10, 15, unitpos.x, unitpos.z, triggerZone.point.x, triggerZone.point.z)
                coalition.addGroup(country.id.USA, Group.Category.GROUND, newGroup)
                
                UnitStateTable[unitName] = false
                
                MistMessage(playerName .. " (" .. groupName .. ") inserted 10 troops (2,200 lb).")
				unitsInsertedCounter = unitsInsertedCounter + 1
				SetHumping(unitName,false)
            else
                MistMessage("Unable to insert troops: " .. playerName .. " (" .. groupName .. ") doesn't have any troops on board.")
            end
    else
        -- landed in nomans
        MistMessage(playerName .. " (" .. groupName .. ") unable to load or unload troops here.")
    end       
end

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
        
        missionCommands.addCommandForGroup(gid, "Load/Unload Troops", nil, UnitRadioCommand, unitName)
        RadioCommandTable[unitName] = true
		MistMessage("New Radio menu added for " .. unitName)
    end
end

-- repeated every 5 sec in case of new joiners
function AddRadioCommands(arg, time)
    AddRadioCommand("C03")
    AddRadioCommand("C04")
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
    DebugIt("Got groups: " .. #groups)
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

    local text = "MISSION STATUS\n\n"

    for k,v in pairs(zoneTable) do
        DebugIt("Append status [" .. tostring(k) .. "] [" .. tostring(v) .. "]")
        text = text .. tostring(v) .. " insurgent units remain vicinty " .. tostring(k) .. "\n"
    end
       
    MistMessage(text)
    
    return time + 120
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

-- sends messages to all users via MIST messaging for 10 secs
function MistMessage(theMsg)
	local msg = {}
	msg.text = theMsg
	msg.displayTime = 10
	msg.msgFor = {coa = {'all'}}
	DebugIt("Message to all: " .. msg.text)
	mist.message.add(msg)
end

-- simple debug to console function
function DebugIt(theMsg)
	if debugit then
		env.info("DEBUGIT:>" .. theMsg .. "<", false)
	end
end

-- change weight flags for triggers in the ME
function SetHumping(unitName,isHumping)
	if unitName == "C03" then
		trigger.action.setUserFlag("198", isHumping)
	elseif unitName == "C04" then
		trigger.action.setUserFlag("199", isHumping)
	else
		DebugIt("error in SetHumping: unitName not recognised")
	end
end

do
    timer.scheduleFunction(SmokeTimer, nil, timer.getTime() + 5)
	DebugIt("smoke timer scheduled")
    timer.scheduleFunction(AddRadioCommands, nil, timer.getTime() + 5)
	DebugIt("radio commands scheduled")
    timer.scheduleFunction(StatusReport, nil, timer.getTime() + 120)
	DebugIt("status report scheduled")
	DebugIt("Flag 198 (C03 Humping) status: " .. trigger.misc.getUserFlag("198"))
	DebugIt("Flag 199 (C04 Humping) status: " .. trigger.misc.getUserFlag("199"))
end
