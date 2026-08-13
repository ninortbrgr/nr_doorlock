-- Doppeltür in der Datenbank speichern
lib.callback.register('access_control:server:CreateDoubleDoor', function(source, payload)
    local player = PlayerManager.GetContext(source)
    if not player.isAdmin then return false end

    local query = [[
        INSERT INTO ac_doors (id, name, owner_faction, default_state, auto_lock_time, security_level, is_double, coords, heading, doors_data)
        VALUES (@id, @name, @owner, @default_state, @auto_lock, @security, 1, @coords, @heading, @doors_data)
    ]]

    MySQL.Async.execute(query, {
        ['@id'] = payload.id,
        ['@name'] = payload.name,
        ['@owner'] = payload.owner_faction,
        ['@default_state'] = payload.default_state,
        ['@auto_lock'] = payload.auto_lock_time,
        ['@security'] = payload.security_level,
        ['@coords'] = json.encode(payload.coords),
        ['@heading'] = payload.heading,
        ['@doors_data'] = json.encode(payload.doors_data)
    }, function(rows)
        if rows > 0 then
            DoorManager.Doors[payload.id] = payload
            DoorManager.States[payload.id] = payload.default_state

            -- An alle Clients zur Live-Registrierung senden
            TriggerClientEvent('access_control:client:RegisterNewDoor', -1, payload)
            EventBus.Publish("AUDIT_LOG", { action = "DOUBLE_DOOR_CREATED", doorId = payload.id, admin = player.identifier })
        end
    end)

    return true
end)

-- Tür permanent aus DB und Speicher löschen
lib.callback.register('access_control:server:DeleteDoor', function(source, doorId)
    local player = PlayerManager.GetContext(source)
    if not player.isAdmin then return false end

    MySQL.Async.execute('DELETE FROM ac_doors WHERE id = @id', { ['@id'] = doorId }, function(rows)
        if rows > 0 then
            DoorManager.Doors[doorId] = nil
            DoorManager.States[doorId] = nil

            -- Informiere alle Clients, die Zone/Target zu entfernen
            TriggerClientEvent('access_control:client:RemoveDoor', -1, doorId)
            EventBus.Publish("AUDIT_LOG", { action = "DOOR_DELETED", doorId = doorId, admin = player.identifier })
        end
    end)

    return true
end)