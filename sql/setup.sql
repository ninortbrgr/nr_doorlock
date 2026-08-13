CREATE TABLE IF NOT EXISTS `ac_doors` (
    `id` VARCHAR(50) PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `owner_faction` VARCHAR(50) DEFAULT NULL,
    `default_state` ENUM('LOCKED', 'UNLOCKED') DEFAULT 'LOCKED',
    `auto_lock_time` INT DEFAULT 0,
    `security_level` INT DEFAULT 1,
    `model` INT DEFAULT 0,
    `coords` JSON NOT NULL,
    `heading` FLOAT DEFAULT 0.0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `ac_permissions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `subject_type` ENUM('PLAYER', 'FACTION_RANK', 'CREDENTIAL', 'PRESET', 'GROUP') NOT NULL,
    `subject_id` VARCHAR(100) NOT NULL, 
    `resource_type` ENUM('DOOR', 'ZONE', 'GLOBAL') NOT NULL,
    `resource_id` VARCHAR(100) NOT NULL, 
    `action` ENUM('ALLOW', 'DENY', 'MANAGE') NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `ac_audit_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `event_type` VARCHAR(50) NOT NULL,
    `player_identifier` VARCHAR(100),
    `resource` VARCHAR(100),
    `metadata` JSON,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);