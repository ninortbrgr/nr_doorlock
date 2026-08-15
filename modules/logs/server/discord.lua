-- Hier deinen Discord Webhook URL eintragen
local WEBHOOK_URL = "DEIN_DISCORD_WEBHOOK_URL_HIER"
local SERVER_NAME = "My Roleplay Server"
local BOT_NAME = "Access Control Audit"
local BOT_AVATAR = "https://i.imgur.com/your_logo.png" -- Optional

-- Farb-Codes für Discord Embeds
local COLORS = {
    SUCCESS = 5763719,  -- Grün
    ERROR = 15548997,   -- Rot
    WARNING = 16776960, -- Gelb
    INFO = 3447003,     -- Blau
    HACK = 15105570     -- Orange
}

-- Kern-Funktion zum Senden an Discord
local function SendDiscordLog(title, description, color, fields)
    if not WEBHOOK_URL or WEBHOOK_URL == "" or WEBHOOK_URL == "DEIN_DISCORD_WEBHOOK_URL_HIER" then 
        return 
    end

    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["fields"] = fields or {},
            ["footer"] = {
                ["text"] = SERVER_NAME .. " • " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(WEBHOOK_URL, function(err, text, headers) 
        if err ~= 204 and err ~= 200 then
            print("^1[Access Control] Fehler beim Senden des Discord Webhooks. Code: " .. tostring(err) .. "^7")
        end
    end, 'POST', json.encode({
        username = BOT_NAME,
        avatar_url = BOT_AVATAR,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- ==========================================
-- EVENT LISTENERS
-- ==========================================

-- 1. Normale Audit-Logs abfangen
EventBus.Subscribe("AUDIT_LOG", function(data)
    local action = data.action
    
    if action == "DOOR_CREATED" or action == "DOUBLE_DOOR_CREATED" then
        SendDiscordLog(
            "➕ Neue Tür registriert",
            "Ein Admin hat eine neue Tür zum System hinzugefügt.",
            COLORS.SUCCESS,
            {
                { name = "Admin (Identifier)", value = data.admin or "Unbekannt", inline = false },
                { name = "Tür ID", value = data.doorId or "N/A", inline = true },
                { name = "Typ", value = (action == "DOUBLE_DOOR_CREATED") and "Doppeltür" or "Einzeltür", inline = true }
            }
        )
    
    elseif action == "DOOR_DELETED" then
        SendDiscordLog(
            "🗑️ Tür gelöscht",
            "Ein Admin hat eine Tür permanent aus der Datenbank entfernt.",
            COLORS.ERROR,
            {
                { name = "Admin (Identifier)", value = data.admin or "Unbekannt", inline = false },
                { name = "Tür ID", value = data.doorId or "N/A", inline = true }
            }
        )
    
    elseif action == "KEYCARD_PROGRAMMED" then
        SendDiscordLog(
            "💳 Keycard beschrieben",
            "Eine neue NFC-Keycard wurde am Terminal codiert.",
            COLORS.INFO,
            {
                { name = "Admin / Fraktionsleitung", value = data.admin or "Unbekannt", inline = false },
                { name = "Inhaber", value = data.targetOwner or "Unbekannt", inline = true },
                { name = "Access Level", value = tostring(data.accessLevel or 1), inline = true }
            }
        )
    end
end)

-- 2. Sicherheitswarnungen und Hacking-Logs abfangen
EventBus.Subscribe("SECURITY_ALERT", function(data)
    local type = data.type
    
    if type == "HACK_SUCCESS" then
        SendDiscordLog(
            "🔓 Sicherheitssystem überbrückt (HACK)",
            "Eine elektronische Verriegelung wurde erfolgreich gehackt.",
            COLORS.HACK,
            {
                { name = "Spieler (Identifier)", value = data.player or "Unbekannt", inline = false },
                { name = "Tür ID", value = data.doorId or "N/A", inline = true }
            }
        )

    elseif type == "ALARM_TRIGGERED" then
        SendDiscordLog(
            "🚨 SICHERHEITSALARM AUSGELÖST",
            "Das automatische Sicherheitssystem hat eine Bedrohung erkannt.",
            COLORS.ERROR,
            {
                { name = "Tür Name", value = data.doorName or "Unbekannt", inline = true },
                { name = "Tür ID", value = data.doorId or "N/A", inline = true },
                { name = "Fraktion", value = data.faction or "Keine", inline = true },
                { name = "Auslöser", value = data.reason or "Unbekannter Grund", inline = false }
            }
        )
    end
end)