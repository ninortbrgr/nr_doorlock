local ConfiguredDoors = {}
local DoorStates = {}
local TargetZones = {}

-- 1. Initialer Sync beim Laden des Spielers
Citizen.CreateThread(function()
    -- Warten bis der Spieler vollständig geladen ist
    while not next(ConfiguredDoors) do
        ConfiguredDoors, DoorStates = lib.callback.await('access_control:server:GetDoorStates', false)
        Citizen.Wait(1000)
    end
    
    SetupTargets()
end)

-- 2. ox_target Setup
function SetupTargets()
    for doorId, door in pairs(ConfiguredDoors) do
        
        local options = {
            {
                name = 'ac_toggle_' .. doorId,
                icon = 'fa-solid fa-power-off',
                -- Das Label ändert sich dynamisch je nach Zustand!
                label = 'Tür umschalten', 
                canInteract = function()
                    -- Target-Option nur anzeigen, wenn der Spieler nah genug ist
                    return true 
                end,
                onSelect = function()
                    AttemptDoorToggle(doorId)
                end
            }
        }

        -- ox_target BoxZone für die Tür erstellen
        local zoneId = exports.ox_target:addBoxZone({
            coords = vec3(door.coords.x, door.coords.y, door.coords.z),
            size = vec3(2.0, 2.0, 2.5), -- Kann in der DB verfeinert werden
            rotation = door.heading,
            debug = false,
            options = options
        })
        
        TargetZones[doorId] = zoneId
        
        -- Tür im GTA Engine sperren/entsperren (Native)
        UpdateNativeDoorState(doorId, door.coords, DoorStates[doorId])
    end
end

-- 3. Interaktion an den Server senden
function AttemptDoorToggle(doorId)
    -- Lade-Animation für UI Feedback
    lib.notify({ type = 'info', description = 'Prüfe Berechtigungen...', duration = 1500 })

    -- Server Callback feuern
    lib.callback('access_control:server:InteractDoor', false, function(success, reason)
        if success then
            lib.notify({ type = 'success', description = 'Zugriff gewährt.' })
        else
            -- Bei Fehler (z.B. "EXPLICITLY_DENIED" oder "UNAUTHORIZED")
            lib.notify({ type = 'error', description = 'Zugriff verweigert (' .. reason .. ')' })
            
            -- Ggf. Sound abspielen
            PlaySoundFrontend(-1, "Hack_Failed", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", true)
        end
    end, doorId, 'TOGGLE')
end

-- 4. Echtzeit-Updates vom Server empfangen
RegisterNetEvent('access_control:client:UpdateDoorState')
AddEventHandler('access_control:client:UpdateDoorState', function(doorId, newState)
    DoorStates[doorId] = newState
    
    -- GTA Engine Door State updaten
    if ConfiguredDoors[doorId] then
        UpdateNativeDoorState(doorId, ConfiguredDoors[doorId].coords, newState)
    end
end)

-- 5. GTA Native Logik (Türen physikalisch sperren)
function UpdateNativeDoorState(doorId, coords, state)
    local doorEntity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 2.0, ConfiguredDoors[doorId].model, false, false, false)
    
    if doorEntity ~= 0 then
        local isLocked = (state == 'LOCKED')
        
        -- GTA Natives für Tür-Status
        FreezeEntityPosition(doorEntity, isLocked)
        
        -- Setzt die Tür sanft zu, wenn sie gesperrt wird
        if isLocked then
            SetEntityRotation(doorEntity, 0.0, 0.0, ConfiguredDoors[doorId].heading, 2, true)
        end
    end
end 

-- Empfange neu erstellte Tür vom Server während des Spielens
RegisterNetEvent('access_control:client:RegisterNewDoor')
AddEventHandler('access_control:client:RegisterNewDoor', function(door)
    ConfiguredDoors[door.id] = door
    DoorStates[door.id] = door.default_state

    -- Registriere ox_target Zone direkt
    local options = {
        {
            name = 'ac_toggle_' .. door.id,
            icon = 'fa-solid fa-power-off',
            label = 'Tür umschalten',
            onSelect = function()
                AttemptDoorToggle(door.id)
            end
        }
    }

    exports.ox_target:addBoxZone({
        coords = vec3(door.coords.x, door.coords.y, door.coords.z),
        size = vec3(2.0, 2.0, 2.5),
        rotation = door.heading,
        debug = false,
        options = options
    })

    UpdateNativeDoorState(door.id, door.coords, door.default_state)
end)

-- Innerhalb der Target-Erstellung für jede Tür:
local options = {
    {
        name = 'ac_toggle_' .. door.id,
        icon = 'fa-solid fa-power-off',
        label = 'Tür umschalten',
        onSelect = function() AttemptDoorToggle(door.id) end
    },
    {
        name = 'ac_hack_' .. door.id,
        icon = 'fa-solid fa-laptop-code',
        label = 'Sicherheitssystem überbrücken',
        canInteract = function()
            -- Nur anzeigen wenn Tür gesperrt ist und Security Level > 0 besitzt
            return DoorStates[door.id] == 'LOCKED' and (door.security_level or 0) > 0
        end,
        onSelect = function()
            TriggerEvent('access_control:client:StartHack', door.id)
        end
    }
}
-- Tür-Löschung auf dem Client verarbeiten
RegisterNetEvent('access_control:client:RemoveDoor')
AddEventHandler('access_control:client:RemoveDoor', function(doorId)
    ConfiguredDoors[doorId] = nil
    DoorStates[doorId] = nil
    exports.ox_target:removeZone('ac_zone_' .. doorId)
end)

-- Verbesserte Native-Türausrichtung (Unterstützt Einzel- und Doppeltüren)
function UpdateNativeDoorState(doorId, coords, state)
    local door = ConfiguredDoors[doorId]
    if not door then return end

    local isLocked = (state == 'LOCKED')

    if door.is_double and door.doors_data then
        -- Wenn es eine Doppeltür ist, verarbeite beide Flügel
        for _, subDoor in ipairs(door.doors_data) do
            local doorHash = type(subDoor.model) == 'number' and subDoor.model or GetHashKey(subDoor.model)
            AddDoorToSystem(doorHash, doorHash, subDoor.coords.x, subDoor.coords.y, subDoor.coords.z, false, false, false)
            DoorSystemSetDoorState(doorHash, isLocked and 1 or 0, false, true)
        end
    else
        -- Einzeltür
        local doorHash = type(door.model) == 'number' and door.model or GetHashKey(door.model)
        AddDoorToSystem(doorHash, doorHash, door.coords.x, door.coords.y, door.coords.z, false, false, false)
        DoorSystemSetDoorState(doorHash, isLocked and 1 or 0, false, true)
    end
end