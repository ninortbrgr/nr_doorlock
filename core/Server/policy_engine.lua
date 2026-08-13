PolicyEngine = {}

--[[
    Evaluate wertet aus, ob ein Subject (Spieler) Zugriff auf eine Resource (Tür) hat.
    @param playerSource: Die Server-ID des Spielers
    @param doorId: Die ID der Tür
    @param actionType: 'ACCESS', 'MANAGE', 'HACK'
    @return boolean, string (isAllowed, reason)
]]
function PolicyEngine.Evaluate(playerSource, doorId, actionType)
    -- Platzhalter: Diese Funktionen werden im Caching/DB-Modul implementiert
    local player = PlayerManager.GetContext(playerSource) 
    local door = DoorManager.GetDoor(doorId)

    if not player or not door then
        return false, "SYSTEM_ERROR"
    end

    -- 1. SYSTEM OVERRIDES
    if player.isAdmin then
        EventBus.Publish("AUDIT_LOG", { action = "ADMIN_OVERRIDE", player = player.id, door = doorId })
        return true, "ADMIN_OVERRIDE"
    end

    -- 2. LOCKDOWN CHECK
    local lockdownState = LockdownManager.GetDoorLockdownState(doorId)
    if lockdownState.active then
        if not player.hasEmergencyClearance then
            return false, "DENIED_BY_LOCKDOWN"
        end
    end

    -- 3. EXPLIZITE SPIELER-REGELN (Priorität über alles andere)
    local directPerm = PermissionCache.Get(player.identifier, "DOOR", doorId)
    if directPerm == "DENY" then return false, "EXPLICITLY_DENIED" end
    if directPerm == "ALLOW" then return true, "DIRECT_ACCESS" end

    -- 4. CREDENTIAL CHECK (Keycards)
    if player.credentials and #player.credentials > 0 then
        for _, credId in ipairs(player.credentials) do
            if CredentialManager.IsValid(credId) then
                local credPerm = PermissionCache.Get(credId, "DOOR", doorId)
                if credPerm == "ALLOW" then 
                    return true, "CREDENTIAL_ACCEPTED" 
                end
            end
        end
    end

    -- 5. FRAKTIONS- & PRESET CHECK
    if player.faction and player.rank then
        local rankIdentifier = player.faction .. ":" .. player.rank
        local rankPerm = PermissionCache.Get(rankIdentifier, "DOOR", doorId)
        
        if rankPerm == "ALLOW" then 
            return true, "RANK_AUTHORIZED" 
        end
    end

    -- 6. FALLBACK (Wenn keine Regel greift, bleibt die Tür zu)
    return false, "UNAUTHORIZED"
end

-- Export für andere Scripts
exports('EvaluateAccess', function(source, doorId, actionType)
    return PolicyEngine.Evaluate(source, doorId, actionType)
end)