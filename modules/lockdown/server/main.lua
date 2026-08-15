LockdownManager = {
    ActiveLockdowns = {} -- Speichert den Status z.B. { ['lapd'] = true }
}

-- Befehl: /lockdown [fraktion]
RegisterCommand('lockdown', function(source, args)
    local player = PlayerManager.GetContext(source)
    if not player then return end

    -- Wenn kein Argument übergeben wird, nimm die eigene Fraktion
    local targetFaction = args[1] or player.faction

    if not targetFaction then
        return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Du bist in keiner Fraktion.' })
    end

    -- Berechtigungsprüfung: Admin oder Fraktionsleitung (Rank >= 4)
    if not player.isAdmin and (player.faction ~= targetFaction or player.rank < 4) then
        return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Keine Berechtigung für einen Gebäude-Lockdown.' })
    end

    -- Toggle den Status
    local isLocked = not LockdownManager.ActiveLockdowns[targetFaction]
    LockdownManager.ActiveLockdowns[targetFaction] = isLocked

    -- Sende den Status an alle Clients (für UI/Sounds)
    TriggerClientEvent('access_control:client:SyncLockdown', -1, targetFaction, isLocked)

    -- Alle betroffenen Türen sofort erzwingend verschließen
    if isLocked then
        for doorId, door in pairs(DoorManager.Doors) do
            if door.owner_faction == targetFaction and not door.locked then
                door.locked = true
                TriggerClientEvent('access_control:client:UpdateDoorState', -1, doorId, true)
            end
        end
    end

    -- Ins Audit/Discord Log schreiben
    EventBus.Publish("SECURITY_ALERT", {
        type = "ALARM_TRIGGERED",
        doorName = "GESAMTES GEBÄUDE",
        doorId = "LOCKDOWN",
        faction = targetFaction,
        reason = isLocked and ("Lockdown aktiviert durch " .. player.identifier) or ("Lockdown aufgehoben durch " .. player.identifier)
    })

    TriggerClientEvent('ox_lib:notify', source, { 
        type = isLocked and 'error' or 'success', 
        description = isLocked and 'GEBÄUDE-LOCKDOWN AKTIVIERT!' or 'Lockdown aufgehoben.'
    })
end, false)

-- Export für andere Ressourcen oder das Door-Modul
exports('IsFactionInLockdown', function(faction)
    return LockdownManager.ActiveLockdowns[faction] or false
end)