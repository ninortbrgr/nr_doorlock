ALTER TABLE `ac_doors` 
ADD COLUMN `is_double` TINYINT(1) DEFAULT 0 AFTER `heading`,
ADD COLUMN `doors_data` LONGTEXT DEFAULT NULL AFTER `is_double`;