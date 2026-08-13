HackingManager = {
    DoorCooldowns = {},
    ActiveSessions = {}
}

local HACK_COOLDOWN_SECONDS = 180 -- 3 Minuten Cooldown nach einem Versuch

-- 1. Client fragt Hack-Start an
lib.callback.register('access_control:server:StartHackAttempt', function(source, doorId)
    local door = DoorManager.Doors[doorId]
    if not door then return false, "DOOR_NOT_FOUND" end

    -- Check: Ist die Tür überhaupt gesperrt?
    if DoorManager.States[doorId] ~= 'LOCKED' then
        return false, "DOOR_NOT_LOCKED"
    end

    -- Check: Cooldown aktiv?
    local currentTime = os.time()
    if HackingManager.DoorCooldowns[doorId] and (currentTime - HackingManager.DoorCooldowns[doorId]) < HACK_COOLDOWN_SECONDS then
        return false, "COOLDOWN_ACTIVE"
    end

    -- Erstelle eine valide Hack-Session für den Spieler mit Timestamp
    HackingManager.ActiveSessions[source] = {
        doorId = doorId,
        startedAt = currentTime,
        securityLevel = door.security_level or 1
    }

    return true, {
        securityLevel = door.security_level or 1
    }
end)

-- 2. Client übermittelt das Ergebnis des Minispiels
lib.callback.register('access_control:server:CompleteHack', function(source, doorId, success)
    local session = HackingManager.ActiveSessions[source]
    
    -- Validierung der Session
    if not session or session.doorId ~= doorId then
        return false, "INVALID_SESSION"
    end

    HackingManager.ActiveSessions[source] = nil -- Session auflösen
    HackingManager.DoorCooldowns[doorId] = os.time() -- Cooldown setzen

    if success then
        -- ERFOLG: Tür für begrenzte Zeit auf BREACHED setzen
        DoorManager.States[doorId] = 'BREACHED'
        TriggerClientEvent('access_control:client:UpdateDoorState', -1, doorId, 'BREACHED')

        -- Event & Log
        EventBus.Publish("AUDIT_LOG", { action = "DOOR_HACKED_SUCCESS", doorId = doorId, player = GetPlayerIdentifier(source, 0) })
        EventBus.Publish("SECURITY_ALERT", { type = "HACK_SUCCESS", doorId = doorId, player = GetPlayerIdentifier(source, 0) })

        -- Tür nach 60 Sekunden automatisch wieder sperren
        Citizen.CreateThread(function()
            Citizen.Wait(60000)
            if DoorManager.States[doorId] == 'BREACHED' then
                DoorManager.States[doorId] = 'LOCKED'
                TriggerClientEvent('access_control:client:UpdateDoorState', -1, doorId, 'LOCKED')
                EventBus.Publish("AUDIT_LOG", { action = "DOOR_AUTO_RELOCKED_AFTER_BREACH", doorId = doorId })
            end
        end)

        return true, "BREACHED"
    else
        -- FEHLER: Alarm auslösen & Log schreiben
        AlarmManager.Trigger(doorId, "Fehlgeschlagener Hackversuch", source)
        EventBus.Publish("AUDIT_LOG", { action = "DOOR_HACKED_FAILED", doorId = doorId, player = GetPlayerIdentifier(source, 0) })
        
        return false, "HACK_FAILED"
    end
end)