KeycardManager = {}

-- Prüft, ob der Spieler ein valides Item besitzt, das Zugang gewährt
function KeycardManager.HasValidKeycard(source, door)
    -- 1. Prüfe RFID Badge (Basiert auf Fraktion und Mindest-Rank)
    local player = PlayerManager.GetContext(source)
    if door.owner_faction and player.faction == door.owner_faction then
        local badge = exports.ox_inventory:GetItem(source, 'police_badge', nil, true)
        if badge > 0 then
            -- Optional: Hier könnte noch ein min_rank aus door.config geprüft werden
            return true, "RFID_BADGE"
        end
    end

    -- 2. Prüfe programmierbare Keycards im Inventar
    local keycards = exports.ox_inventory:GetSlotsWithItem(source, 'access_keycard')
    if keycards then
        for _, slot in ipairs(keycards) do
            local metadata = slot.metadata
            if metadata then
                -- Fall A: Karte ist direkt für diese Tür-ID ausgestellt
                if metadata.allowed_doors and metadata.allowed_doors[door.id] then
                    return true, "KEYCARD_DIRECT"
                end

                -- Fall B: Karte besitzt ausreichendes globales Access-Level
                if metadata.access_level and door.security_level then
                    if metadata.access_level >= door.security_level then
                        -- Falls die Karte auf eine bestimmte Fraktion beschränkt ist:
                        if not metadata.faction or metadata.faction == door.owner_faction then
                            return true, "KEYCARD_LEVEL"
                        end
                    end
                end
            end
        end
    end

    return false, "NO_VALID_CARD"
end

-- Server-Callback zum Programmieren einer Keycard (z. B. an einem Admin/Fraktions-Terminal)
lib.callback.register('access_control:server:ProgramKeycard', function(source, targetSlot, cardData)
    local player = PlayerManager.GetContext(source)
    
    -- Nur Admins oder Fraktionsleiter dürfen Karten beschreiben
    if not player.isAdmin and player.rank < 4 then
        return false, "UNAUTHORIZED"
    end

    local metadata = {
        label = cardData.label or "Sicherheits-Keycard",
        owner_name = cardData.ownerName or "Unbekannt",
        access_level = cardData.accessLevel or 1,
        faction = cardData.faction or nil,
        allowed_doors = cardData.doors or {}, -- Table: { ["door_123"] = true }
        description = ("Inhaber: %s | Level: %d"):format(cardData.ownerName or "Unbekannt", cardData.accessLevel or 1)
    }

    -- Aktualisiere die Metadaten der Karte im Inventar
    exports.ox_inventory:SetMetadata(source, targetSlot, metadata)
    
    EventBus.Publish("AUDIT_LOG", {
        action = "KEYCARD_PROGRAMMED",
        admin = player.identifier,
        targetOwner = metadata.owner_name,
        accessLevel = metadata.access_level
    })

    return true
end)

exports('HasValidKeycard', KeycardManager.HasValidKeycard)