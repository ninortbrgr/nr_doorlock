-- Empfang von Fraktions-Sicherheitswarnungen
RegisterNetEvent('access_control:client:ReceiveFactionAlert')
AddEventHandler('access_control:client:ReceiveFactionAlert', function(alertData)
    -- Ingame-Benachrichtigung
    lib.notify({
        title = alertData.title,
        description = alertData.description,
        type = 'error',
        duration = 8000
    })

    -- Akustisches Signal für Fraktionsmitglieder
    PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", true)

    -- Erzeuge temporären Blip auf der Karte für Einsatzkräfte
    if alertData.coords then
        local blip = AddBlipForCoord(alertData.coords.x, alertData.coords.y, alertData.coords.z)
        SetBlipSprite(blip, 161) -- Warnsymbol
        SetBlipScale(blip, 1.2)
        SetBlipColour(blip, 1) -- Rot
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Sicherheitsalarm: " .. alertData.title)
        EndTextCommandSetBlipName(blip)

        -- Blip nach 30 Sekunden automatisch entfernen
        Citizen.SetTimeout(30000, function()
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end)
    end
end)

-- Akustische Soundeffekte im Umkreis der Tür
RegisterNetEvent('access_control:client:PlayAlarmEffects')
AddEventHandler('access_control:client:PlayAlarmEffects', function(coords, radius)
    local pCoords = GetEntityCoords(PlayerPedId())
    local dist = #(pCoords - vec3(coords.x, coords.y, coords.z))

    if dist <= radius then
        -- Spielt einen nativen Alarm-Sound am Standort ab
        PlaySoundFromCoord(-1, "Alarm_Loop_Building", coords.x, coords.y, coords.z, "PORT_HEIST_FINAL_SOUNDS", true, math.floor(radius), false)
    end
end)