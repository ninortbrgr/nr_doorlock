-- Admin Command für das Hauptmenü
RegisterCommand('dooradmin', function()
    lib.callback('access_control:server:IsAdmin', false, function(isAdmin)
        if not isAdmin then
            return lib.notify({ type = 'error', description = 'Keine Berechtigung.' })
        end
        OpenAdminMenu()
    end)
end, false)

function OpenAdminMenu()
    lib.registerContext({
        id = 'ac_admin_main_menu',
        title = '🛡️ Access Control - Admin Panel',
        options = {
            {
                title = 'Einzeltür erstellen',
                description = 'Ziele auf ein einzelnes Tür-Objekt und erstelle eine neue Tür.',
                icon = 'door-closed',
                onSelect = function()
                    StartDoorCreator() -- Aus dem vorherigen Schritt
                end
            },
            {
                title = 'Doppeltür erstellen',
                description = 'Verknüpfe zwei Türflügel zu einer gemeinsam gesteuerten Doppeltür.',
                icon = 'door-open',
                onSelect = function()
                    StartDoubleDoorCreator()
                end
            },
            {
                title = 'Türen in der Nähe verwalten',
                description = 'Sucht registrierte Türen im Umkreis von 15 Metern.',
                icon = 'location-dot',
                onSelect = function()
                    OpenNearbyDoorsMenu()
                end
            }
        }
    })
    lib.showContext('ac_admin_main_menu')
end

-- Erstellungsprozess für Doppeltüren
function StartDoubleDoorCreator()
    local door1Data, door2Data = nil, nil

    -- SCHRITT 1: Erste Tür auswählen
    lib.notify({ type = 'info', description = 'SCHRITT 1: Schaue auf die ERSTE Tür und drücke [E]. [G] zum Abbrechen.' })
    local success1 = SelectDoorObject(function(entity, model, coords, heading)
        door1Data = { model = model, coords = { x = coords.x, y = coords.y, z = coords.z }, heading = heading }
    end)

    if not success1 or not door1Data then return end

    Citizen.Wait(500)

    -- SCHRITT 2: Zweite Tür auswählen
    lib.notify({ type = 'info', description = 'SCHRITT 2: Schaue auf die ZWEITE Tür und drücke [E]. [G] zum Abbrechen.' })
    local success2 = SelectDoorObject(function(entity, model, coords, heading)
        door2Data = { model = model, coords = { x = coords.x, y = coords.y, z = coords.z }, heading = heading }
    end)

    if not success2 or not door2Data then return end

    -- SCHRITT 3: Eigenschaften festlegen
    local input = lib.inputDialog('Neue Doppeltür registrieren', {
        { type = 'input', label = 'Bezeichnung der Doppeltür', placeholder = 'z.B. LSPD Haupteingang', required = true },
        { type = 'input', label = 'Owner Fraktion', placeholder = 'z.B. lapd', required = false },
        { type = 'select', label = 'Standard Status', options = { { value = 'LOCKED', label = 'Verschlossen' }, { value = 'UNLOCKED', label = 'Offen' } }, default = 'LOCKED' },
        { type = 'number', label = 'Auto-Lock Zeit (Sekunden)', default = 0, min = 0 },
        { type = 'slider', label = 'Security Level', min = 1, max = 5, default = 1 }
    })

    if not input then return end

    -- Berechne Mittelpunkt zwischen beiden Türen für den ox_target Interaktionspunkt
    local centerCoords = vec3(
        (door1Data.coords.x + door2Data.coords.x) / 2,
        (door1Data.coords.y + door2Data.coords.y) / 2,
        (door1Data.coords.z + door2Data.coords.z) / 2
    )

    local payload = {
        id = 'double_door_' .. math.random(100000, 999999),
        name = input[1],
        owner_faction = input[2] ~= '' and input[2] or nil,
        default_state = input[3],
        auto_lock_time = input[4],
        security_level = input[5],
        is_double = true,
        coords = centerCoords,
        heading = door1Data.heading,
        doors_data = { door1Data, door2Data }
    }

    lib.callback('access_control:server:CreateDoubleDoor', false, function(success)
        if success then
            lib.notify({ type = 'success', description = 'Doppeltür erfolgreich registriert!' })
        else
            lib.notify({ type = 'error', description = 'Fehler beim Speichern der Doppeltür.' })
        end
    end, payload)
end

-- Hilfsfunktion: Visuelle Objektauswahl im Raycast
function SelectDoorObject(cb)
    local selecting = true
    local selected = false

    while selecting do
        Citizen.Wait(0)
        local hit, entity, coords = RaycastCamera(10.0)

        if hit and entity ~= 0 and IsEntityAnObject(entity) then
            DrawBoundingBox(entity)

            if IsControlJustPressed(0, 38) then -- KEY_E
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                cb(entity, GetEntityModel(entity), GetEntityCoords(entity), GetEntityHeading(entity))
                selected = true
                selecting = false
            end
        end

        if IsControlJustPressed(0, 47) then -- KEY_G (Abbrechen)
            lib.notify({ type = 'inform', description = 'Auswahl abgebrochen.' })
            selecting = false
        end
    end

    return selected
end

-- Menü für Türen in der Nähe (Teleport / Edit / Delete)
function OpenNearbyDoorsMenu()
    local pCoords = GetEntityCoords(PlayerPedId())
    local options = {}

    for id, door in pairs(ConfiguredDoors) do
        local doorCoords = vec3(door.coords.x, door.coords.y, door.coords.z)
        local dist = #(pCoords - doorCoords)

        if dist <= 15.0 then
            table.insert(options, {
                title = door.name,
                description = ("ID: %s | Typ: %s | Distanz: %.1fm"):format(id, door.is_double and "Doppeltür" or "Einzeltür", dist),
                icon = door.is_double and 'door-open' or 'door-closed',
                onSelect = function()
                    OpenSingleDoorAdminAction(door)
                end
            })
        end
    end

    if #options == 0 then
        return lib.notify({ type = 'inform', description = 'Keine registrierten Türen im Umkreis von 15m gefunden.' })
    end

    lib.registerContext({
        id = 'ac_admin_nearby_doors',
        title = 'Türen in der Nähe',
        menu = 'ac_admin_main_menu',
        options = options
    })
    lib.showContext('ac_admin_nearby_doors')
end

-- Aktionen für eine spezifische Tür (Löschen / Teleport)
function OpenSingleDoorAdminAction(door)
    lib.registerContext({
        id = 'ac_admin_door_detail',
        title = door.name,
        menu = 'ac_admin_nearby_doors',
        options = {
            {
                title = 'Teleportieren zur Tür',
                icon = 'location-arrow',
                onSelect = function()
                    SetEntityCoords(PlayerPedId(), door.coords.x, door.coords.y, door.coords.z, false, false, false, false)
                end
            },
            {
                title = 'Tür löschen',
                description = 'Entfernt die Tür permanent aus der Datenbank.',
                icon = 'trash-can',
                colorScheme = 'red',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Tür löschen?',
                        content = ('Möchtest du die Tür "%s" wirklich unwiderruflich löschen?'):format(door.name),
                        centered = true,
                        cancel = true
                    })

                    if confirm == 'confirm' then
                        lib.callback('access_control:server:DeleteDoor', false, function(success)
                            if success then
                                lib.notify({ type = 'success', description = 'Tür gelöscht.' })
                            end
                        end, door.id)
                    end
                end
            }
        }
    })
    lib.showContext('ac_admin_door_detail')
end