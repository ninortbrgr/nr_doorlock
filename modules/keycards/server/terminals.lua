local ServerTerminals = {}

-- Beim Serverstart alle Terminals laden
MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM ac_terminals', {}, function(results)
        if results then
            for _, row in ipairs(results) do
                ServerTerminals[row.id] = {
                    id = row.id,
                    name = row.name,
                    faction = row.faction,
                    max_access_level = row.max_access_level,
                    coords = json.decode(row.coords)
                }
            end
            TriggerClientEvent('access_control:client:SyncTerminals', -1, ServerTerminals)
        end
    end)
end)

-- Interaktions-Check für Spieler
RegisterNetEvent('access_control:server:InteractWithTerminal')
AddEventHandler('access_control:server:InteractWithTerminal', function(terminalId)
    local src = source
    local terminal = ServerTerminals[terminalId]
    if not terminal then return end

    local player = PlayerManager.GetContext(src)

    -- Check: Ist das Terminal an eine Fraktion gebunden?
    if terminal.faction and player.faction ~= terminal.faction and not player.isAdmin then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Kein Zugriff auf dieses Terminal.' })
    end

    -- Öffne NUI für den Spieler
    TriggerClientEvent('access_control:client:OpenKeycardTerminal', src, terminal)
end)

-- Speichern eines neuen Terminals (Admin)
RegisterNetEvent('access_control:server:SaveTerminal')
AddEventHandler('access_control:server:SaveTerminal', function(payload)
    local src = source
    local player = PlayerManager.GetContext(src)
    if not player.isAdmin then return end

    local query = [[
        INSERT INTO ac_terminals (id, name, faction, max_access_level, coords)
        VALUES (@id, @name, @faction, @max, @coords)
    ]]

    MySQL.Async.execute(query, {
        ['@id'] = payload.id,
        ['@name'] = payload.name,
        ['@faction'] = payload.faction,
        ['@max'] = payload.max_access_level,
        ['@coords'] = json.encode(payload.coords)
    }, function(rows)
        if rows > 0 then
            ServerTerminals[payload.id] = payload
            TriggerClientEvent('access_control:client:SyncTerminals', -1, ServerTerminals)
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Terminal erfolgreich platziert.' })
        end
    end)
end)