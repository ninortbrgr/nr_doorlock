PlayerManager = {}

-- Holt alle relevanten Daten eines Spielers, die für die Berechtigungsprüfung nötig sind.
-- (Wird von der PolicyEngine.Evaluate() aufgerufen)
function PlayerManager.GetContext(source)
    local player = {
        source = source,
        identifier = "unknown",
        faction = "none",
        rank = 0,
        isAdmin = false,
        hasEmergencyClearance = false,
        credentials = {}
    }

    -- 1. Framework Daten holen (ESX / QBCore / Qbox)
    -- Hier beispielhaft für QBCore (Kann leicht für ESX adaptiert werden)
    if Config.System.Framework == 'qbcore' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            player.identifier = Player.PlayerData.citizenid
            player.faction = Player.PlayerData.job.name
            player.rank = Player.PlayerData.job.grade.level
            
            -- Simple Admin-Check (kann angepasst werden)
            if QBCore.Functions.HasPermission(source, 'admin') then
                player.isAdmin = true
            end
        end
    end

    -- 2. Credentials aus dem Inventar lesen (ox_inventory Integration)
    -- Wir suchen nach allen Items vom Typ 'keycard', 'access_card' etc.
    local items = exports.ox_inventory:GetInventoryItems(source)
    if items then
        for _, item in pairs(items) do
            -- Angenommen, das Item heißt 'access_card' und hat Metadaten: { credential_id = 'CARD-XYZ' }
            if item.name == 'access_card' and item.metadata and item.metadata.credential_id then
                table.insert(player.credentials, item.metadata.credential_id)
            end
        end
    end

    return player
end