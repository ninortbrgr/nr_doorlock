CredentialManager = {}

-- Hilfsfunktion: Generiert eine eindeutige Karten-ID
local function GenerateCredentialID()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = "CARD-"
    for i = 1, 6 do
        local rand = math.random(1, #charset)
        id = id .. string.sub(charset, rand, rand)
    end
    return id
end

-- 1. Erstelle ein neues Credential (Wird aus dem Leader-Panel getriggert)
function CredentialManager.Create(ownerIdentifier, issuerIdentifier, expiresAt)
    local credId = GenerateCredentialID()
    
    MySQL.Async.execute([[
        INSERT INTO ac_credentials (id, owner_identifier, issued_by, expires_at)
        VALUES (@id, @owner, @issuer, @expires)
    ]], {
        ['@id'] = credId,
        ['@owner'] = ownerIdentifier,
        ['@issuer'] = issuerIdentifier,
        ['@expires'] = expiresAt -- Kann nil sein für permanente Karten
    }, function(rowsChanged)
        if rowsChanged > 0 then
            -- Audit Log & Discord Event triggern
            EventBus.Publish("AUDIT_LOG", { 
                action = "CREDENTIAL_CREATED", 
                credentialId = credId, 
                owner = ownerIdentifier, 
                issuer = issuerIdentifier 
            })
            EventBus.Publish("CREDENTIAL_CREATED", { id = credId, owner = ownerIdentifier })
        end
    end)

    return credId
end

-- 2. Status einer Karte ändern (z.B. Revoke / Als Verloren melden)
function CredentialManager.SetStatus(credId, newStatus, adminIdentifier)
    MySQL.Async.execute([[
        UPDATE ac_credentials SET status = @status WHERE id = @id
    ]], {
        ['@id'] = credId,
        ['@status'] = newStatus
    }, function(rowsChanged)
        if rowsChanged > 0 then
            EventBus.Publish("AUDIT_LOG", { 
                action = "CREDENTIAL_STATUS_CHANGED", 
                credentialId = credId, 
                status = newStatus,
                admin = adminIdentifier 
            })
        end
    end)
end

-- 3. Prüfen, ob die Karte technisch gültig ist (Nicht abgelaufen, nicht gesperrt)
function CredentialManager.IsValid(credId)
    -- Dies sollte idealerweise in einen In-Memory Cache (wie bei den Doors) gepackt werden!
    -- Für das Beispiel fragen wir die DB synchron ab (in Produktion: Cache nutzen!)
    local result = MySQL.Sync.fetchAll("SELECT status, expires_at FROM ac_credentials WHERE id = @id", {
        ['@id'] = credId
    })

    if not result or #result == 0 then return false end
    
    local card = result[1]
    
    if card.status ~= 'ACTIVE' then return false end

    -- Check Expiration (Ablaufdatum)
    if card.expires_at then
        -- Unix Timestamp Vergleich
        local expireTime = math.floor(card.expires_at / 1000) 
        if os.time() > expireTime then
            -- Karte ist abgelaufen, direkt in der DB updaten
            CredentialManager.SetStatus(credId, 'EXPIRED', 'SYSTEM')
            return false
        end
    end

    return true
end

-- API Exports
exports('CreateCredential', CredentialManager.Create)
exports('RevokeCredential', function(credId, adminId)
    CredentialManager.SetStatus(credId, 'REVOKED', adminId)
end)