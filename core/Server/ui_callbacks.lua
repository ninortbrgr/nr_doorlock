lib.callback.register('access_control:server:GetDashboardStats', function(source)
    local player = PlayerManager.GetContext(source)
    
    -- SECURITY CHECK
    if not player.isAdmin and player.rank < 4 then
        -- Hack-Versuch oder unautorisierter Aufruf
        EventBus.Publish("AUDIT_LOG", { action = "UNAUTHORIZED_API_CALL", player = player.identifier, endpoint = "GetDashboardStats" })
        return { error = "Unauthorized" }
    end

    local stats = {
        totalDoors = 0,
        activeCredentials = 0,
        recentAlarms = 0,
        lockedDoors = 0
    }

    -- Admin sieht alles, Leader sieht nur seine eigene Fraktion
    if player.isAdmin then
        stats.totalDoors = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM ac_doors')
        stats.activeCredentials = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM ac_credentials WHERE status = "ACTIVE"')
        
        -- Zähle verschlossene Türen aus dem Live-Cache
        for _, state in pairs(DoorManager.States) do
            if state == 'LOCKED' then stats.lockedDoors = stats.lockedDoors + 1 end
        end
    else
        -- Faction Leader Modus: Nur Türen der eigenen Fraktion laden
        stats.totalDoors = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM ac_doors WHERE owner_faction = ?', {player.faction})
        stats.activeCredentials = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM ac_credentials WHERE issued_by = ? AND status = "ACTIVE"', {player.faction})
    end

    return stats
end)