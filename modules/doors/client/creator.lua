local isCreatingDoor = false

-- Command zum Starten des Creator-Modus (Nur für Admins)
RegisterCommand('createdoor', function()
    -- Prüfe Admin-Rechte serverseitig
    lib.callback('access_control:server:IsAdmin', false, function(isAdmin)
        if not isAdmin then
            return lib.notify({ type = 'error', description = 'Keine Berechtigung.' })
        end
        StartDoorCreator()
    end)
end, false)

function StartDoorCreator()
    if isCreatingDoor then return end
    isCreatingDoor = true

    lib.notify({ type = 'info', description = 'Door-Creator aktiv. Schaue auf eine Tür und drücke [E]. [G] zum Abbrechen.' })

    Citizen.CreateThread(function()
        while isCreatingDoor do
            Citizen.Wait(0)
            local hit, entity, coords = RaycastCamera(10.0)

            if hit and entity ~= 0 and IsEntityAnObject(entity) then
                -- Visualisierung: Zeichne Marker um das visierte Objekt
                DrawBoundingBox(entity)

                -- Drücke [E] um Tür auszuwählen
                if IsControlJustPressed(0, 38) then -- 38 = KEY_E
                    isCreatingDoor = false
                    OpenDoorCreationDialog(entity, GetEntityModel(entity), GetEntityCoords(entity), GetEntityHeading(entity))
                    break
                end
            end

            -- Drücke [G] zum Abbrechen
            if IsControlJustPressed(0, 47) then -- 47 = KEY_G
                isCreatingDoor = false
                lib.notify({ type = 'inform', description = 'Door-Creator abgebrochen.' })
                break
            end
        end
    end)
end

-- Öffnet das ox_lib Eingabe-Formular für die Türeigenschaften
function OpenDoorCreationDialog(entity, model, coords, heading)
    local input = lib.inputDialog('Neue Tür registrieren', {
        { type = 'input', label = 'Tür Name / Bezeichnung', placeholder = 'z.B. Evidence Room 101', required = true },
        { type = 'input', label = 'Owner Fraktion', placeholder = 'z.B. lapd (Leer lassen für Keine)', required = false },
        { type = 'select', label = 'Standard Status', options = { { value = 'LOCKED', label = 'Verschlossen (LOCKED)' }, { value = 'UNLOCKED', label = 'Offen (UNLOCKED)' } }, default = 'LOCKED' },
        { type = 'number', label = 'Auto-Lock Zeit (Sekunden)', description = '0 = Deaktiviert', default = 0, min = 0, max = 3600 },
        { type = 'slider', label = 'Security Level (Hacking-Schwierigkeit)', min = 1, max = 5, default = 1 }
    })

    if not input then return end

    local doorData = {
        id = 'door_' .. math.random(100000, 999999),
        name = input[1],
        owner_faction = input[2] ~= '' and input[2] or nil,
        default_state = input[3],
        auto_lock_time = input[4],
        security_level = input[5],
        model = model,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        heading = heading
    }

    -- An Server senden
    lib.callback('access_control:server:CreateDoor', false, function(success, doorId)
        if success then
            lib.notify({ type = 'success', description = ('Tür "%s" erfolgreich angelegt!'):format(doorData.name) })
        else
            lib.notify({ type = 'error', description = 'Fehler beim Speichern der Tür.' })
        end
    end, doorData)
end

-- Hilfsfunktion: Raycast aus der Kamerarichtung
function RaycastCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = vec3(
        cameraCoord.x + direction.x * distance,
        cameraCoord.y + direction.y * distance,
        cameraCoord.z + direction.z * distance
    )

    local rayHandle = StartShapeTestLosProbe(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0)
    local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)
    return hit, entityHit, endCoords
end

function RotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return vec3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

function DrawBoundingBox(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    local pad = 0.001
    DrawBox(
        GetOffsetFromEntityInWorldCoords(entity, min.x - pad, min.y - pad, min.z - pad),
        GetOffsetFromEntityInWorldCoords(entity, max.x + pad, max.y + pad, max.z + pad),
        0, 255, 150, 50
    )
end