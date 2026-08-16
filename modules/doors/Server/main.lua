DoorManager = {
    Doors = {}, -- Hier liegen die Config-Daten der Türen (Coords, Name etc.)
    States = {} -- Hier liegt der aktuelle Live-Status (LOCKED, UNLOCKED)
}

-- 1. Türen aus der Datenbank laden
function DoorManager.LoadDoors()
    MySQL.Async.fetchAll("SELECT * FROM ac_doors", {}, function(results)
        for _, row in ipairs(results) do
            DoorManager.Doors[row.id] = {
                id = row.id,
                name = row.name,
                owner_faction = row.owner_faction,
                default_state = row.default_state,
                auto_lock_time = row.auto_lock_time,
                security_level = row.security_level,
                coords = json.decode(row.coords),
                heading = row.heading
            }
            -- Setze den aktuellen Status auf den Default-Status der Datenbank
            DoorManager.States[row.id] = row.default_state
        end
        print(("[Doors] Loaded %s doors."):format(#results))
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    DoorManager.LoadDoors()
end)

-- 2. Client fordert aktuelle Tür-Zustände an (beim Joinen)
lib.callback.register('access_control:server:GetDoorStates', function(source)
    return DoorManager.Doors, DoorManager.States
end)

-- 3. INTERAKTION: Der Spieler versucht eine Tür umzuschalten
lib.callback.register('access_control:server:InteractDoor', function(source, doorId, requestedAction)
    local door = DoorManager.Doors[doorId]
    if not door then return false, "DOOR_NOT_FOUND" end

    -- ==========================================
    -- NEU: LOCKDOWN CHECK
    -- ==========================================
    if door.owner_faction and exports['nr_doorlock']:IsFactionInLockdown(door.owner_faction) then
        local player = PlayerManager.GetContext(source)
        
        if not player.isAdmin then
            TriggerClientEvent('ox_lib:notify', source, { 
                type = 'error', 
                description = 'Zugriff verweigert! Das Gebäude befindet sich im Lockdown.' 
            })
            EventBus.Publish("AUDIT_LOG", { action = "ACCESS_DENIED", doorId = doorId, reason = "LOCKDOWN_ACTIVE" })
            return false, "LOCKDOWN_ACTIVE"
        else
            TriggerClientEvent('ox_lib:notify', source, { 
                type = 'warning', 
                description = 'Lockdown aktiv - Admin-Override genutzt.' 
            })
        end
    end
    -- ==========================================

    -- Hier rufen wir unser Gehirn auf!
    local isAllowed, reason = PolicyEngine.Evaluate(source, doorId, 'ACCESS')

    if isAllowed then
        -- Zustand umkehren
        local newState = (DoorManager.States[doorId] == 'LOCKED') and 'UNLOCKED' or 'LOCKED'
        DoorManager.States[doorId] = newState
        
        -- Alle Clients über den neuen Zustand informieren
        TriggerClientEvent('access_control:client:UpdateDoorState', -1, doorId, newState)

        -- Auto-Lock Timer starten, falls konfiguriert und Tür nun offen ist
        if newState == 'UNLOCKED' and door.auto_lock_time > 0 then
            DoorManager.HandleAutoLock(doorId, door.auto_lock_time)
        end

        -- Audit Log schreiben
        EventBus.Publish("AUDIT_LOG", { action = "DOOR_TOGGLED", doorId = doorId, state = newState, reason = reason })
        return true, "SUCCESS"
    else
        EventBus.Publish("AUDIT_LOG", { action = "ACCESS_DENIED", doorId = doorId, reason = reason })
        return false, reason
    end
end)
-- 4. Auto-Lock Logik
function DoorManager.HandleAutoLock(doorId, timeInSeconds)
    Citizen.CreateThread(function()
        Citizen.Wait(timeInSeconds * 1000)
        if DoorManager.States[doorId] == 'UNLOCKED' then
            DoorManager.States[doorId] = 'LOCKED'
            TriggerClientEvent('access_control:client:UpdateDoorState', -1, doorId, 'LOCKED')
            EventBus.Publish("AUDIT_LOG", { action = "DOOR_AUTO_LOCKED", doorId = doorId })
        end
    end)
end

-- Aktualisierte Berechtigungsprüfung im DoorManager
function DoorManager.CanPlayerAccess(source, doorId)
    local door = DoorManager.Doors[doorId]
    if not door then return false end

    local player = PlayerManager.GetContext(source)

    -- 1. Admins haben immer Zugriff
    if player.isAdmin then return true end

    -- 2. Prüfe Keycards & Badges im Inventar
    local hasCard, reason = KeycardManager.HasValidKeycard(source, door)
    if hasCard then return true end

    -- 3. Standard-Fraktionscheck (falls kein Badge benötigt wird)
    if door.owner_faction and player.faction == door.owner_faction then
        return true
    end

    return false
end

function DoorManager.GetDoor(doorId)
    return DoorManager.Doors[doorId]
end