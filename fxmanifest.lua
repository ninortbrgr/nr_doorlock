fx_version 'cerulean'
game 'gta5'

description 'NR Doorlock - Advanced Access Control'
version '1.0.0'

-- UI Pfad (wird erst nach dem npm run build gefunden)
ui_page 'web/dist/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    -- Core
    'core/server/database.lua',
    'core/server/context_manager.lua',
    'core/server/policy_engine.lua',
    -- Modules
    'modules/doors/server/*.lua',
    'modules/credentials/server/*.lua',
    'modules/lockdown/server/*.lua',
    'modules/hacking/server/*.lua'
}

client_scripts {
    -- Core
    'core/client/ui_callbacks.lua',
    -- Modules
    'modules/doors/client/*.lua',
    'modules/credentials/client/*.lua',
    'modules/lockdown/client/*.lua',
    'modules/hacking/client/*.lua'
}

files {
    -- Das ist der Standard-Output-Ordner für Vite (React)
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css'
}

-- Exporte (nur die, die wir wirklich bereits in der main.lua definiert haben)
export 'IsFactionInLockdown'