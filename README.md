OX Inventory integration:
Füge diese Items in deine ox_inventory/data/items.lua ein:

['police_badge'] = {
    label = 'Polizei Dienstausweis',
    weight = 50,
    stack = false,
    close = true,
    description = 'Offizieller Dienstausweis mit integriertem RFID-Chip.'
},

['access_keycard'] = {
    label = 'Sicherheits-Keycard',
    weight = 20,
    stack = false,
    close = true,
    description = 'Eine programmierbare NFC-Karte für elektronische Türschlösser.'
}