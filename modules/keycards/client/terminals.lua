local Terminals = {}

-- Event zum Öffnen des Keycard-Terminals per NUI
RegisterNetEvent('access_control:client:OpenKeycardTerminal')
AddEventHandler('access_control:client:OpenKeycardTerminal', function(terminalData)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openTerminal',
        data = terminalData
    })
end)

-- Registriert ein Terminal im Target-System
function RegisterTerminalTarget(terminalId, coords)
    exports.ox_target:addBoxZone({
        name = 'ac_terminal_' .. terminalId,
        coords = vec3(coords.x, coords.y, coords.z),
        size = vec3(0.8, 0.8, 1.0),
        rotation = coords.w or 0.0,
        debug = false,
        options = {
            {
                name = 'ac_open_terminal_' .. terminalId,
                icon = 'fa-solid fa-credit-card',
                label = 'Keycard-Terminal bedienen',
                onSelect = function()
                    TriggerServerEvent('access_control:server:InteractWithTerminal', terminalId)
                end
            }
        }
    })
end

-- Command für Admins, um ein Terminal am aktuellen Standort zu platzieren
RegisterCommand('createterminal', function()
    lib.callback('access_control:server:IsAdmin', false, function(isAdmin)
        if not isAdmin then return lib.notify({ type = 'error', description = 'Keine Berechtigung.' }) end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        local input = lib.inputDialog('Neues Keycard-Terminal erstellen', {
            { type = 'input', label = 'Terminal Name', placeholder = 'z.B. LSPD Rezeption', required = true },
            { type = 'input', label = 'Fraktion (optional)', placeholder = 'z.B. lapd', required = false },
            { type = 'slider', label = 'Maximales Access-Level', min = 1, max = 5, default = 3 }
        })

        if not input then return end

        local payload = {
            id = 'term_' .. math.random(100000, 999999),
            name = input[1],
            faction = input[2] ~= '' and input[2] or nil,
            max_access_level = input[3],
            coords = { x = coords.x, y = coords.y, z = coords.z, w = heading }
        }

        TriggerServerEvent('access_control:server:SaveTerminal', payload)
    end)
end, false)

-- Empfange registrierte Terminals vom Server
RegisterNetEvent('access_control:client:SyncTerminals')
AddEventHandler('access_control:client:SyncTerminals', function(serverTerminals)
    Terminals = serverTerminals
    for id, term in pairs(Terminals) do
        RegisterTerminalTarget(id, term.coords)
    end
end)