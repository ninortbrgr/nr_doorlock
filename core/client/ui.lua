local isUiOpen = false

-- Öffnet das UI (Wird z.B. per Command oder ox_target am PC aufgerufen)
RegisterNetEvent('access_control:client:OpenUI')
AddEventHandler('access_control:client:OpenUI', function(panelType)
    -- panelType = 'ADMIN' oder 'FACTION'
    isUiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openPanel',
        type = panelType
    })
end)

-- UI schließen (Von React getriggert)
RegisterNUICallback('closeUI', function(data, cb)
    isUiOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Holt die Dashboard-Statistiken vom Server (Von React getriggert)
RegisterNUICallback('getDashboardStats', function(data, cb)
    -- Wir nutzen ox_lib callbacks, um den Server zu fragen
    lib.callback('access_control:server:GetDashboardStats', false, function(stats)
        cb(stats)
    end)
end)