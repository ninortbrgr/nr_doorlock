-- Callback für das React UI (Faction Panel / Admin Panel)
lib.callback.register('access_control:server:IssueKeycard', function(source, targetPlayerId, doorsToAllow)
    local issuer = PlayerManager.GetContext(source)
    local target = PlayerManager.GetContext(targetPlayerId)
    
    -- Sicherheitscheck: Darf der Issuer Karten ausstellen?
    -- (Hier kannst du prüfen, ob issuer.rank hoch genug ist)
    if not issuer.faction or issuer.rank < 4 then
        return false, "NOT_AUTHORIZED_TO_ISSUE"
    end

    -- 1. Karte in der DB anlegen
    local newCardId = CredentialManager.Create(target.identifier, issuer.identifier, nil)

    -- 2. Berechtigungen für diese Karte in die DB schreiben (Türen zuweisen)
    for _, doorId in ipairs(doorsToAllow) do
        -- Trägt ein: Diese Karte (CREDENTIAL) darf diese Tür (DOOR) öffnen (ALLOW)
        MySQL.Async.execute([[
            INSERT INTO ac_permissions (subject_type, subject_id, resource_type, resource_id, action)
            VALUES ('CREDENTIAL', @credId, 'DOOR', @doorId, 'ALLOW')
        ]], {
            ['@credId'] = newCardId,
            ['@doorId'] = doorId
        })
    end
    
    -- 3. Cache aktualisieren, damit die Tür sofort nutzbar ist
    EventBus.Publish("PERMISSIONS_UPDATED", {})

    -- 4. Dem Spieler das physische Item geben (ox_inventory)
    exports.ox_inventory:AddItem(targetPlayerId, 'access_card', 1, {
        credential_id = newCardId,
        description = "Zugangskarte ID: " .. newCardId,
        issued_by = issuer.faction
    })

    return true, newCardId
end)