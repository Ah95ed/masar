-- ============================================================
-- Maxlond v2.0.0 - قاعدة البيانات الكاملة
-- MySQL 5.7+ | utf8mb4_unicode_ci
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';
SET time_zone = '+03:00';

-- ============================================================
-- 1) المستخدمون
-- ============================================================
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `full_name` VARCHAR(150) NOT NULL,
    `username` VARCHAR(80) NOT NULL UNIQUE,
    `email` VARCHAR(150) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `role` ENUM('admin','engineer','accountant') NOT NULL DEFAULT 'engineer',
    `phone` VARCHAR(30) DEFAULT NULL,
    `specialization` VARCHAR(100) DEFAULT NULL,
    `signature_path` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `approval_status` ENUM('pending','approved','rejected') DEFAULT 'pending',
    `last_login` DATETIME DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_role` (`role`),
    INDEX `idx_status` (`approval_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 2) بصمات الأجهزة (مطلوب لـ auth.php)
-- ============================================================
DROP TABLE IF EXISTS `device_fingerprints`;
CREATE TABLE `device_fingerprints` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `fingerprint_hash` VARCHAR(128) NOT NULL,
    `user_agent` VARCHAR(500) DEFAULT NULL,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `first_seen` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `last_seen` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_user_fp` (`user_id`, `fingerprint_hash`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 3) المواقع
-- ============================================================
DROP TABLE IF EXISTS `sites`;
CREATE TABLE `sites` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(200) NOT NULL,
    `client_name` VARCHAR(200) DEFAULT NULL,
    `work_date` DATE DEFAULT NULL,
    `start_time` TIME DEFAULT NULL,
    `end_time` TIME DEFAULT NULL,
    `location` VARCHAR(255) DEFAULT NULL,
    `budget` DECIMAL(15,2) DEFAULT 0,
    `status` ENUM('planning','active','paused','completed','cancelled') DEFAULT 'active',
    `manager_id` INT UNSIGNED DEFAULT NULL,
    `description` TEXT,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_status` (`status`),
    FOREIGN KEY (`manager_id`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 4) الآليات
-- ============================================================
DROP TABLE IF EXISTS `machinery`;
CREATE TABLE `machinery` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(200) NOT NULL,
    `plate_number` VARCHAR(50) DEFAULT NULL,
    `operator_name` VARCHAR(150) DEFAULT NULL,
    `status` ENUM('available','in_use','maintenance','out_of_service') DEFAULT 'available',
    `hourly_cost` DECIMAL(10,2) DEFAULT 0,
    `notes` TEXT,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 5) خطط العمل
-- ============================================================
DROP TABLE IF EXISTS `work_plans`;
CREATE TABLE `work_plans` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `site_id` INT UNSIGNED NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT,
    `assigned_to` INT UNSIGNED DEFAULT NULL,
    `is_broadcast` TINYINT(1) DEFAULT 0,
    `priority` ENUM('low','medium','high','urgent') DEFAULT 'medium',
    `status` ENUM('pending','in_progress','review','done','cancelled') DEFAULT 'pending',
    `progress` TINYINT UNSIGNED DEFAULT 0,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_status` (`status`),
    INDEX `idx_assigned` (`assigned_to`),
    FOREIGN KEY (`site_id`) REFERENCES `sites`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`assigned_to`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 6) سجل تحديثات المهام
-- ============================================================
DROP TABLE IF EXISTS `work_plan_updates`;
CREATE TABLE `work_plan_updates` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `work_plan_id` INT UNSIGNED NOT NULL,
    `engineer_id` INT UNSIGNED NOT NULL,
    `old_progress` TINYINT UNSIGNED DEFAULT NULL,
    `new_progress` TINYINT UNSIGNED DEFAULT NULL,
    `old_status` VARCHAR(30) DEFAULT NULL,
    `new_status` VARCHAR(30) DEFAULT NULL,
    `note` TEXT,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_plan` (`work_plan_id`),
    FOREIGN KEY (`work_plan_id`) REFERENCES `work_plans`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`engineer_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 7) التقارير اليومية
-- ============================================================
DROP TABLE IF EXISTS `site_daily_reports`;
CREATE TABLE `site_daily_reports` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `site_id` INT UNSIGNED NOT NULL,
    `report_date` DATE NOT NULL,
    `engineer_id` INT UNSIGNED NOT NULL,
    `weather` VARCHAR(80) DEFAULT NULL,
    `temperature` DECIMAL(5,2) DEFAULT NULL,
    `workers_count` INT UNSIGNED DEFAULT 0,
    `machinery_count` INT UNSIGNED DEFAULT 0,
    `work_done` TEXT,
    `issues` TEXT,
    `materials_used` TEXT,
    `safety_notes` TEXT,
    `progress_percent` TINYINT UNSIGNED DEFAULT 0,
    `status` ENUM('draft','submitted','approved','rejected') DEFAULT 'draft',
    `admin_notes` TEXT,
    `approved_by` INT UNSIGNED DEFAULT NULL,
    `approved_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_report` (`site_id`, `report_date`, `engineer_id`),
    INDEX `idx_status` (`status`),
    FOREIGN KEY (`site_id`) REFERENCES `sites`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`engineer_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`approved_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 8) مصروفات التقارير
-- ============================================================
DROP TABLE IF EXISTS `report_expenses`;
CREATE TABLE `report_expenses` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT UNSIGNED NOT NULL,
    `item_name` VARCHAR(200) NOT NULL,
    `category` ENUM('materials','labor','fuel','equipment','transport','other') DEFAULT 'materials',
    `quantity` DECIMAL(12,3) DEFAULT 1,
    `unit_price` DECIMAL(15,2) DEFAULT 0,
    `total` DECIMAL(15,2) DEFAULT 0,
    `notes` VARCHAR(500) DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_report` (`report_id`),
    FOREIGN KEY (`report_id`) REFERENCES `site_daily_reports`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 9) مرفقات التقارير
-- ============================================================
DROP TABLE IF EXISTS `report_receipts`;
CREATE TABLE `report_receipts` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT UNSIGNED NOT NULL,
    `file_path` VARCHAR(500) NOT NULL,
    `original_name` VARCHAR(255) DEFAULT NULL,
    `file_type` VARCHAR(50) DEFAULT NULL,
    `file_size` INT UNSIGNED DEFAULT NULL,
    `uploaded_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_report` (`report_id`),
    FOREIGN KEY (`report_id`) REFERENCES `site_daily_reports`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 10) المخزن
-- ============================================================
DROP TABLE IF EXISTS `warehouse_categories`;
CREATE TABLE `warehouse_categories` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `warehouse_items`;
CREATE TABLE `warehouse_items` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(200) NOT NULL,
    `category_id` INT UNSIGNED DEFAULT NULL,
    `unit` VARCHAR(30) DEFAULT 'قطعة',
    `quantity` DECIMAL(15,3) DEFAULT 0,
    `min_quantity` DECIMAL(15,3) DEFAULT 0,
    `unit_price` DECIMAL(15,2) DEFAULT 0,
    `location` VARCHAR(100) DEFAULT NULL,
    `notes` TEXT,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_category` (`category_id`),
    FOREIGN KEY (`category_id`) REFERENCES `warehouse_categories`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `warehouse_transactions`;
CREATE TABLE `warehouse_transactions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `item_id` INT UNSIGNED NOT NULL,
    `type` ENUM('in','out','adjust') NOT NULL,
    `quantity` DECIMAL(15,3) NOT NULL,
    `unit_price` DECIMAL(15,2) DEFAULT 0,
    `total_price` DECIMAL(15,2) DEFAULT 0,
    `site_id` INT UNSIGNED DEFAULT NULL,
    `supplier` VARCHAR(200) DEFAULT NULL,
    `invoice_number` VARCHAR(100) DEFAULT NULL,
    `reason` VARCHAR(500) DEFAULT NULL,
    `created_by` INT UNSIGNED NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_item` (`item_id`),
    INDEX `idx_type` (`type`),
    FOREIGN KEY (`item_id`) REFERENCES `warehouse_items`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`site_id`) REFERENCES `sites`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`created_by`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 11) تصليح الآليات
-- ============================================================
DROP TABLE IF EXISTS `machinery_repairs`;
CREATE TABLE `machinery_repairs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `machinery_id` INT UNSIGNED NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT,
    `problem_type` ENUM('mechanical','electrical','body','tires','other') DEFAULT 'mechanical',
    `status` ENUM('pending','in_progress','waiting_parts','completed','cancelled') DEFAULT 'pending',
    `priority` ENUM('low','medium','high','urgent') DEFAULT 'medium',
    `technician_name` VARCHAR(150) DEFAULT NULL,
    `workshop` VARCHAR(200) DEFAULT NULL,
    `labor_cost` DECIMAL(15,2) DEFAULT 0,
    `parts_cost` DECIMAL(15,2) DEFAULT 0,
    `total_cost` DECIMAL(15,2) DEFAULT 0,
    `reported_by` INT UNSIGNED NOT NULL,
    `started_at` DATETIME DEFAULT NULL,
    `completed_at` DATETIME DEFAULT NULL,
    `notes` TEXT,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_machinery` (`machinery_id`),
    INDEX `idx_status` (`status`),
    FOREIGN KEY (`machinery_id`) REFERENCES `machinery`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`reported_by`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `machinery_repair_parts`;
CREATE TABLE `machinery_repair_parts` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `repair_id` INT UNSIGNED NOT NULL,
    `part_name` VARCHAR(200) NOT NULL,
    `quantity` DECIMAL(10,2) DEFAULT 1,
    `unit_price` DECIMAL(15,2) DEFAULT 0,
    `total` DECIMAL(15,2) DEFAULT 0,
    INDEX `idx_repair` (`repair_id`),
    FOREIGN KEY (`repair_id`) REFERENCES `machinery_repairs`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 12) المحاسبة
-- ============================================================
DROP TABLE IF EXISTS `accounts`;
CREATE TABLE `accounts` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(200) NOT NULL,
    `type` ENUM('asset','liability','equity','revenue','expense') NOT NULL,
    `parent_id` INT UNSIGNED DEFAULT NULL,
    `balance` DECIMAL(15,2) DEFAULT 0,
    `description` VARCHAR(500) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    INDEX `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `journal_entries`;
CREATE TABLE `journal_entries` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `entry_number` VARCHAR(50) NOT NULL UNIQUE,
    `entry_date` DATE NOT NULL,
    `description` VARCHAR(500) NOT NULL,
    `reference` VARCHAR(100) DEFAULT NULL,
    `site_id` INT UNSIGNED DEFAULT NULL,
    `report_id` INT UNSIGNED DEFAULT NULL,
    `total_debit` DECIMAL(15,2) DEFAULT 0,
    `total_credit` DECIMAL(15,2) DEFAULT 0,
    `status` ENUM('draft','posted','cancelled') DEFAULT 'posted',
    `signature_hash` VARCHAR(255) DEFAULT NULL,
    `signed_by` INT UNSIGNED DEFAULT NULL,
    `signed_at` DATETIME DEFAULT NULL,
    `created_by` INT UNSIGNED NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_date` (`entry_date`),
    INDEX `idx_status` (`status`),
    FOREIGN KEY (`site_id`) REFERENCES `sites`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`signed_by`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`created_by`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `journal_entry_lines`;
CREATE TABLE `journal_entry_lines` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `entry_id` INT UNSIGNED NOT NULL,
    `account_id` INT UNSIGNED NOT NULL,
    `debit` DECIMAL(15,2) DEFAULT 0,
    `credit` DECIMAL(15,2) DEFAULT 0,
    `description` VARCHAR(500) DEFAULT NULL,
    INDEX `idx_entry` (`entry_id`),
    FOREIGN KEY (`entry_id`) REFERENCES `journal_entries`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`account_id`) REFERENCES `accounts`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `electronic_signatures`;
CREATE TABLE `electronic_signatures` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `entity_type` VARCHAR(50) NOT NULL,
    `entity_id` BIGINT UNSIGNED NOT NULL,
    `signature_hash` VARCHAR(255) NOT NULL,
    `signed_data` TEXT,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `signed_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_entity` (`entity_type`, `entity_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 13) النظام
-- ============================================================
DROP TABLE IF EXISTS `notifications`;
CREATE TABLE `notifications` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `message` TEXT,
    `type` ENUM('info','success','warning','danger') DEFAULT 'info',
    `link` VARCHAR(255) DEFAULT NULL,
    `is_read` TINYINT(1) DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_read` (`user_id`, `is_read`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `sessions`;
CREATE TABLE `sessions` (
    `id` VARCHAR(128) PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `fingerprint_hash` VARCHAR(128) NOT NULL,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `user_agent` VARCHAR(500) DEFAULT NULL,
    `last_activity` INT UNSIGNED NOT NULL,
    INDEX `idx_user` (`user_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `audit_log`;
CREATE TABLE `audit_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED DEFAULT NULL,
    `action` VARCHAR(100) NOT NULL,
    `entity_type` VARCHAR(50) DEFAULT NULL,
    `entity_id` BIGINT UNSIGNED DEFAULT NULL,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `details` TEXT,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user` (`user_id`),
    INDEX `idx_action` (`action`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- API tokens store SHA-256 hashes of opaque Bearer tokens, never the token itself.
DROP TABLE IF EXISTS `api_logs`;
CREATE TABLE `api_logs` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED DEFAULT NULL,
    `endpoint` VARCHAR(255) NOT NULL,
    `method` VARCHAR(10) NOT NULL,
    `status_code` INT DEFAULT 200,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `user_agent` VARCHAR(255) DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_api_user` (`user_id`),
    INDEX `idx_api_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `api_tokens`;
CREATE TABLE `api_tokens` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `refresh_token` VARCHAR(255) NOT NULL UNIQUE,
    `device_info` VARCHAR(255) DEFAULT NULL,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `expires_at` DATETIME NOT NULL,
    `revoked_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_api_token_user` (`user_id`),
    INDEX `idx_api_token_expiry` (`expires_at`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- البيانات الأولية
-- ============================================================

-- المدير الافتراضي: admin / Admin@1234
INSERT INTO `users` (`full_name`, `username`, `email`, `password_hash`, `role`, `approval_status`, `is_active`) VALUES
('مدير النظام', 'admin', 'admin@maxlond.local',
 '$2y$10$8uZt7zceyMn30HDCMse8ner8YQgWM8DhjT7dcS0xzfWY1Ly2m8ryW',
 'admin', 'approved', 1);

-- دليل الحسابات
INSERT INTO `accounts` (`code`, `name`, `type`) VALUES
('1000', 'الأصول', 'asset'),
('1100', 'النقدية', 'asset'),
('1200', 'البنك', 'asset'),
('1300', 'المواد والمخزون', 'asset'),
('1400', 'الآليات والمعدات', 'asset'),
('2000', 'الالتزامات', 'liability'),
('2100', 'الموردون', 'liability'),
('3000', 'حقوق الملكية', 'equity'),
('4000', 'الإيرادات', 'revenue'),
('5000', 'المصروفات', 'expense'),
('5100', 'مصروفات المواد', 'expense'),
('5200', 'مصروفات العمالة', 'expense'),
('5300', 'مصروفات الوقود', 'expense'),
('5400', 'مصروفات الصيانة', 'expense'),
('5500', 'مصروفات النقل', 'expense'),
('5600', 'مصروفات أخرى', 'expense');

-- فئات المخزن
INSERT INTO `warehouse_categories` (`name`, `description`) VALUES
('مواد بناء', 'أسمنت، حديد، رمل، حصى'),
('كهربائيات', 'أسلاك، قواطع، إضاءة'),
('سباكة', 'أنابيب، محابس، وصلات'),
('أدوات', 'عدد يدوية'),
('وقود وزيوت', 'بنزين، ديزل، زيوت');