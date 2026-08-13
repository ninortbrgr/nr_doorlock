Config = {}

Config.System = {
    Debug = true, -- Erzeugt erweiterte Konsolen-Logs
    Language = 'de',
    Framework = 'standalone' -- 'qbcore', 'esx' oder 'standalone'
}

Config.Discord = {
    Enabled = true,
    WebhookURL = 'DEINE_WEBHOOK_URL_HIER', -- Nur Serverseitig auslesbar!
    BotName = 'Access Control System',
    AvatarURL = 'https://i.imgur.com/your_avatar.png',
    RateLimit = 5, -- Max Nachrichten pro Sekunde
    Events = {
        SecurityAlerts = true,
        DoorChanges = true,
        CredentialChanges = true,
        AdminActions = true
    }
}

Config.Doors = {
    InteractDistance = 2.5,
    DefaultAutoLockTime = 0 -- 0 bedeutet disabled
}