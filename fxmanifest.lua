fx_version 'cerulean'
game 'gta5'

description 'Modular Enterprise Access Control System'
version '1.0.0'
author 'Dein Name'

-- Dependencies
dependencies {
    'oxmysql',
    'ox_target',
    'ox_lib'
}

-- Configs
shared_scripts {
    '@ox_lib/init.lua',
    'config/default_config.lua',
    'core/shared/*.lua'
}

-- Server-Side Core & Modules
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'core/server/event_bus.lua',
    'core/server/database.lua',
    'core/server/policy_engine.lua',
    'core/server/api.lua',
    'modules/discord/server/*.lua',
    'modules/doors/server/*.lua'
}

-- Client-Side Core & Modules
client_scripts {
    'core/client/sync.lua',
    'modules/doors/client/*.lua'
}

-- Web UI Build (Später für React)
ui_page 'web/build/index.html'
files {
    'web/build/index.html',
    'web/build/assets/*.js',
    'web/build/assets/*.css'
}

-- Exports (API für andere Scripte)
export 'HasAccess'
export 'TriggerAlarm'
export 'SetLockdownState'