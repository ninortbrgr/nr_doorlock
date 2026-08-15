RegisterNetEvent('access_control:client:SyncLockdown')
AddEventHandler('access_control:client:SyncLockdown', function(faction, isLocked)
    local playerFaction = "lapd" -- Hier holst du dir am besten die aktuelle Fraktion deines Frameworks (ESX/QBCore)

    if isLocked then
        -- Zeige eine dicke Warnung auf dem Bildschirm an
        if playerFaction == faction then
            lib.notify({
                title = '🚨 SYSTEM-ALARM 🚨',
                description = 'GEBÄUDE-LOCKDOWN WURDE AKTIVIERT! Alle Türen verriegelt.',
                type = 'error',
                duration = 10000,
                position = 'top'
            })
            
            -- Optional: GTA Audio-Alarm abspielen
            PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", true)
        end
    else
        if playerFaction == faction then
            lib.notify({
                title = '✅ ENTWARNUNG',
                description = 'Der Gebäude-Lockdown wurde aufgehoben.',
                type = 'success',
                duration = 5000,
                position = 'top'
            })
        end
    end
end)