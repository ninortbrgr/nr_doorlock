Database = {}
PermissionCache = {}

-- Lädt alle Berechtigungen in den schnellen RAM-Cache
function Database.LoadPermissions()
    local query = "SELECT subject_type, subject_id, resource_type, resource_id, action FROM ac_permissions"
    MySQL.Async.fetchAll(query, {}, function(results)
        PermissionCache = {} -- Cache leeren
        for _, row in ipairs(results) do
            local cacheKey = row.subject_type .. "_" .. row.subject_id .. "_" .. row.resource_type .. "_" .. row.resource_id
            PermissionCache[cacheKey] = row.action
        end
        if Config.System.Debug then
            print(("[Database] Loaded %s permissions into cache."):format(#results))
        end
    end)
end

-- Holt eine Berechtigung aus dem Cache (Wird von der PolicyEngine in Echtzeit genutzt)
function PermissionCache.Get(subjectType, subjectId, resourceType, resourceId)
    local cacheKey = subjectType .. "_" .. subjectId .. "_" .. resourceType .. "_" .. resourceId
    return PermissionCache[cacheKey]
end

-- Startet den Ladevorgang, wenn das Script startet
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    Database.LoadPermissions()
end)

-- Event für das Admin UI: Wenn eine Berechtigung geändert wird, updaten wir den Cache
EventBus.Subscribe("PERMISSIONS_UPDATED", function()
    Database.LoadPermissions()
end)