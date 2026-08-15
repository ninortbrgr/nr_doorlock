EventBus = {
    Listeners = {}
}

-- Abonniert ein bestimmtes Event
function EventBus.Subscribe(topic, callback)
    if not EventBus.Listeners[topic] then 
        EventBus.Listeners[topic] = {} 
    end
    table.insert(EventBus.Listeners[topic], callback)
end

-- Löst ein Event für alle Abonnenten aus
function EventBus.Publish(topic, data)
    if not EventBus.Listeners[topic] then return end
    for _, callback in ipairs(EventBus.Listeners[topic]) do
        -- Führe Callbacks asynchron aus, um den Haupt-Thread nicht zu blockieren
        Citizen.CreateThread(function()
            callback(data)
        end)
    end
end