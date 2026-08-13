EventBus = {
    _listeners = {}
}

-- Ein Modul registriert sich für ein Event
function EventBus.Subscribe(eventName, callback)
    if type(callback) ~= "function" then
        print(("[EventBus] Error: Callback for %s is not a function."):format(eventName))
        return
    end

    if not EventBus._listeners[eventName] then 
        EventBus._listeners[eventName] = {} 
    end
    
    table.insert(EventBus._listeners[eventName], callback)
    
    if Config.System.Debug then
        print(("[EventBus] Subscribed new listener to event: %s"):format(eventName))
    end
end

-- Ein Modul löst ein Event aus
function EventBus.Publish(eventName, data)
    if not EventBus._listeners[eventName] then return end

    for _, callback in ipairs(EventBus._listeners[eventName]) do
        -- Führt jedes Callback asynchron aus, um den Main-Thread nicht zu blockieren
        Citizen.CreateThread(function()
            local success, err = pcall(callback, data)
            if not success then
                print(("[EventBus] Error executing callback for event %s: %s"):format(eventName, err))
            end
        end)
    end
end

exports('PublishEvent', EventBus.Publish)