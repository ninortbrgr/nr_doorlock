-- Adapter-Funktion: Startet das Minispiel basierend auf dem Security-Level
local function PlayHackingMinigame(securityLevel, cb)
    -- Konfiguriere die Schwierigkeit dynamisch nach Security Level (1-5)
    local difficultyMap = {
        [1] = { 'easy', 'easy' },
        [2] = { 'easy', 'medium' },
        [3] = { 'medium', 'medium', 'medium' },
        [4] = { 'medium', 'hard', 'medium' },
        [5] = { 'hard', 'hard', 'hard', 'hard' }
    }

    local selectedDifficulty = difficultyMap[securityLevel] or { 'easy', 'medium' }

    -- ox_lib Skillcheck als Standard-Minispiel
    -- Hinweis: Kann hier leicht durch z.B. 'ps-ui' oder 'mhacking' ausgetauscht werden!
    local success = lib.skillCheck(selectedDifficulty, {'w', 'a', 's', 'd'})
    cb(success)
end

-- Hauptfunktion: Wird aufgerufen, wenn der Spieler im ox_target "Überbrücken" klickt
function InitiateDoorHack(doorId)
    -- 1. Server fragen, ob ein Hack aktuell erlaubt ist
    lib.callback('access_control:server:StartHackAttempt', false, function(allowed, sessionData)
        if not allowed then
            local msg = "Hack nicht möglich."
            if sessionData == "COOLDOWN_ACTIVE" then msg = "Sicherheitssystem befindet sich im Sperrmodus (Cooldown)." end
            if sessionData == "DOOR_NOT_LOCKED" then msg = "Die Tür ist nicht verschlossen." end
            return lib.notify({ type = 'error', description = msg })
        end

        -- 2. Animation & Hacking-Tool Effekt
        local ped = PlayerPedId()
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_MOBILE", 0, true)
        lib.notify({ type = 'inform', description = 'Verbindung zum Türprozessor wird aufgebaut...' })

        Citizen.Wait(2000)
        ClearPedTasks(ped)

        -- 3. Minispiel starten
        PlayHackingMinigame(sessionData.securityLevel, function(success)
            -- 4. Ergebnis an Server senden
            lib.callback('access_control:server:CompleteHack', false, function(completed, resultState)
                if completed and resultState == "BREACHED" then
                    lib.notify({ type = 'success', description = 'Sicherheitssystem erfolgreich überbrückt!' })
                else
                    lib.notify({ type = 'error', description = 'Sicherheitssystem gelöst! ALARM AUSGELÖST!' })
                end
            end, doorId, success)
        end)

    end, doorId)
end

-- Event-Handler für den ox_target Aufruf aus dem Door-Modul
RegisterNetEvent('access_control:client:StartHack')
AddEventHandler('access_control:client:StartHack', function(doorId)
    InitiateDoorHack(doorId)
end)