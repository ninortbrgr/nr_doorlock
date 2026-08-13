CREATE TABLE IF NOT EXISTS `ac_credentials` (
    `id` VARCHAR(50) PRIMARY KEY, -- z.B. "CARD-8F92A"
    `owner_identifier` VARCHAR(100) NOT NULL,
    `issued_by` VARCHAR(100) NOT NULL, -- Wer hat die Karte erstellt?
    `status` ENUM('ACTIVE', 'DISABLED', 'REVOKED', 'EXPIRED', 'LOST') DEFAULT 'ACTIVE',
    `expires_at` DATETIME NULL, -- Für temporäre Karten
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);