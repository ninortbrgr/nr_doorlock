-- Admin-Check Callback
lib.callback.register('access_control:server:IsAdmin', function(source)
    local player = PlayerManager.GetContext(source)
    return player.isAdmin
end)

-- Tür in der Datenbank speichern und live laden
lib.callback.register('access_control:server:CreateDoor', function(source, doorData)
    local player = PlayerManager.GetContext(source)
    if not player.isAdmin then return false, "UNAUTHORIZED" end

    local query = [[
        INSERT INTO ac_doors (id, name, owner_faction, default_state, auto_lock_time, security_level, model, coords, heading)
        VALUES (@id, @name, @owner, @default_state, @auto_lock, @security, @model, @coords, @heading)
    ]]

    MySQL.Async.execute(query, {
        ['@id'] = doorData.id,
        ['@name'] = doorData.name,
        ['@owner'] = doorData.owner_faction,
        ['@default_state'] = doorData.default_state,
        ['@auto_lock'] = doorData.auto_lock_time,
        ['@security'] = doorData.security_level,
        ['@model'] = doorData.model,
        ['@coords'] = json.encode(doorData.coords),
        ['@heading'] = doorData.heading
    }, function(rows)
        if rows > 0 then
            -- Speichere im Live-Manager
            DoorManager.Doors[doorData.id] = doorData
            DoorManager.States[doorData.id] = doorData.default_state

            -- Registriere ox_target Live für alle Spieler
            TriggerClientEvent('access_control:client:RegisterNewDoor', -1, doorData)

            -- Event-Bus Benachrichtigung
            EventBus.Publish("AUDIT_LOG", { action = "DOOR_CREATED", doorId = doorData.id, admin = player.identifier })
            EventBus.Publish("DOOR_CREATED", doorData)
        end
    end)

    return true, doorData.id
end)