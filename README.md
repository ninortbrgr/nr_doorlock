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


Ergänzung für MySql Datenbank:
CREATE TABLE IF NOT EXISTS `ac_terminals` (
  `id` VARCHAR(50) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `faction` VARCHAR(50) DEFAULT NULL,
  `max_access_level` INT DEFAULT 3,
  `coords` LONGTEXT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;