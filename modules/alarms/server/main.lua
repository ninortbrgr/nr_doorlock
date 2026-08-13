AlarmManager = {
    ActiveAlarms = {},
    Cooldowns = {}
}

local ALARM_COOLDOWN_SECONDS = 30

-- Signalisiert einen Sicherheitsalarm an einer Tür
function AlarmManager.Trigger(doorId, reason, sourcePlayer)
    local door = DoorManager.Doors[doorId]
    if not door then return end

    local currentTime = os.time()
    if AlarmManager.Cooldowns[doorId] and (currentTime - AlarmManager.Cooldowns[doorId]) < ALARM_COOLDOWN_SECONDS then
        return -- Alarm-Cooldown aktiv, Spam verhindern
    end

    AlarmManager.Cooldowns[doorId] = currentTime
    AlarmManager.ActiveAlarms[doorId] = {
        doorId = doorId,
        doorName = door.name,
        faction = door.owner_faction,
        reason = reason,
        triggeredAt = currentTime
    }

    local playerContext = sourcePlayer and PlayerManager.GetContext(sourcePlayer) or nil
    local playerIdentifier = playerContext and playerContext.identifier or "UNKNOWN"

    -- 1. Event Bus benachrichtigen (für Audit-Logs, Discord-Webhooks, etc.)
    EventBus.Publish("SECURITY_ALERT", {
        type = "ALARM_TRIGGERED",
        doorId = doorId,
        doorName = door.name,
        faction = door.owner_faction,
        reason = reason,
        player = playerIdentifier,
        coords = door.coords
    })

    -- 2. Alle Online-Mitglieder der Besitzer-Fraktion benachrichtigen
    if door.owner_faction then
        AlarmManager.NotifyFactionMembers(door.owner_faction, door.name, reason, door.coords)
    end

    -- 3. Akustischen/Visuellen Alarm an nahe Clients senden
    TriggerClientEvent('access_control:client:PlayAlarmEffects', -1, door.coords, 50.0)
end

-- Hilfsfunktion: Sendet Notfallsignale an alle Mitglieder einer Fraktion
function AlarmManager.NotifyFactionMembers(faction, doorName, reason, coords)
    local players = GetPlayers()
    for _, src in ipairs(players) do
        local targetContext = PlayerManager.GetContext(tonumber(src))
        if targetContext and targetContext.faction == faction then
            TriggerClientEvent('access_control:client:ReceiveFactionAlert', src, {
                title = "SECURITY ALERT",
                description = ("Aktivität bei '%s': %s"):format(doorName, reason),
                coords = coords
            })
        end
    end
end

exports('TriggerAlarm', AlarmManager.Trigger)