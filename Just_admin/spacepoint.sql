-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: 30 سبتمبر 2026 الساعة 11:30
-- إصدار الخادم: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `spacepoint`
--

-- --------------------------------------------------------

--
-- بنية الجدول `accounts`
--

CREATE TABLE `accounts` (
  `id` int(10) UNSIGNED NOT NULL,
  `code` varchar(50) NOT NULL,
  `name` varchar(200) NOT NULL,
  `type` enum('asset','liability','equity','revenue','expense') NOT NULL,
  `parent_id` int(10) UNSIGNED DEFAULT NULL,
  `balance` decimal(15,2) DEFAULT 0.00,
  `description` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `accounts`
--

INSERT INTO `accounts` (`id`, `code`, `name`, `type`, `parent_id`, `balance`, `description`, `is_active`) VALUES
(1, '1000', 'الأصول', 'asset', NULL, 0.00, NULL, 1),
(2, '1100', 'النقدية', 'asset', NULL, 0.00, NULL, 1),
(3, '1200', 'البنك', 'asset', NULL, 0.00, NULL, 1),
(4, '1300', 'المواد والمخزون', 'asset', NULL, -60000.00, NULL, 1),
(5, '1400', 'الآليات والمعدات', 'asset', NULL, 0.00, NULL, 1),
(6, '2000', 'الالتزامات', 'liability', NULL, 0.00, NULL, 1),
(7, '2100', 'الموردون', 'liability', NULL, 0.00, NULL, 1),
(8, '3000', 'حقوق الملكية', 'equity', NULL, 0.00, NULL, 1),
(9, '4000', 'الإيرادات', 'revenue', NULL, 0.00, NULL, 1),
(10, '5000', 'المصروفات', 'expense', NULL, 0.00, NULL, 1),
(11, '5100', 'مصروفات المواد', 'expense', NULL, 60000.00, NULL, 1),
(12, '5200', 'مصروفات العمالة', 'expense', NULL, 0.00, NULL, 1),
(13, '5300', 'مصروفات الوقود', 'expense', NULL, 0.00, NULL, 1),
(14, '5400', 'مصروفات الصيانة', 'expense', NULL, 0.00, NULL, 1),
(15, '5500', 'مصروفات النقل', 'expense', NULL, 0.00, NULL, 1),
(16, '5600', 'مصروفات أخرى', 'expense', NULL, 0.00, NULL, 1),
(17, '2', 'point', 'asset', NULL, 0.00, 'مسار BA12', 1);

-- --------------------------------------------------------

--
-- بنية الجدول `api_logs`
--

CREATE TABLE `api_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED DEFAULT NULL,
  `endpoint` varchar(255) NOT NULL,
  `method` varchar(10) NOT NULL,
  `status_code` int(11) DEFAULT 200,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `api_tokens`
--

CREATE TABLE `api_tokens` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `refresh_token` varchar(255) NOT NULL,
  `device_info` varchar(255) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- إرجاع أو استيراد بيانات الجدول `api_tokens`
--

INSERT INTO `api_tokens` (`id`, `user_id`, `refresh_token`, `device_info`, `ip_address`, `expires_at`, `revoked_at`, `created_at`) VALUES
(1, 1, 'b39f53e776b93c72981f41c43c7c9e7fc95c49f200c573bbd685839de6d0b224', '', '::1', '2026-10-29 00:51:46', NULL, '2026-09-29 00:51:46'),
(2, 1, 'ab917b199b1bba16253242c17d66723bf3761c6f27f32d087caebbbbd1230358', 'Flutter App - Android 14', '::1', '2026-10-29 00:52:10', NULL, '2026-09-29 00:52:10'),
(3, 1, '0fe99058abf67112ce1fa540205f910851426e56812542af2beaf81993c5c8f2', 'Flutter App - Android 14', '::1', '2026-10-29 00:52:16', NULL, '2026-09-29 00:52:16'),
(4, 1, '623dc942daca99653e7a13e0876801054c1af1aa6de85bee9ad73e6662a88816', '', '::1', '2026-10-29 01:00:33', NULL, '2026-09-29 01:00:33');

-- --------------------------------------------------------

--
-- بنية الجدول `audit_log`
--

CREATE TABLE `audit_log` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(50) DEFAULT NULL,
  `entity_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `details` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `audit_log`
--

INSERT INTO `audit_log` (`id`, `user_id`, `action`, `entity_type`, `entity_id`, `ip_address`, `details`, `created_at`) VALUES
(1, 1, 'login_success', 'user', 1, '::1', NULL, '2026-09-30 11:41:32'),
(2, 1, 'logout', 'user', 1, '::1', NULL, '2026-09-30 11:41:44'),
(3, 1, 'login_success', 'user', 1, '::1', NULL, '2026-09-30 11:42:06'),
(4, 1, 'logout', 'user', 1, '::1', NULL, '2026-09-30 11:43:02'),
(5, NULL, 'login_success', 'user', 2, '::1', NULL, '2026-09-30 11:43:02'),
(6, NULL, 'logout', 'user', 2, '::1', NULL, '2026-09-30 11:43:13'),
(7, NULL, 'login_success', 'user', 2, '::1', NULL, '2026-09-30 11:43:26'),
(8, NULL, 'logout', 'user', 2, '::1', NULL, '2026-09-30 11:43:26'),
(9, NULL, 'login_success', 'user', 2, '::1', NULL, '2026-09-30 11:44:01'),
(10, NULL, 'logout', 'user', 2, '::1', NULL, '2026-09-30 11:44:39'),
(11, NULL, 'login_success', 'user', 2, '::1', NULL, '2026-09-30 11:47:17'),
(13, 1, 'login_success', 'user', 1, '::1', NULL, '2026-09-30 11:48:26'),
(14, NULL, 'login_failed', 'user', NULL, '::1', NULL, '2026-09-30 11:52:43'),
(15, 1, 'login_success', 'user', 1, '::1', NULL, '2026-09-30 11:52:55'),
(16, 1, 'user_approved', 'user', 3, '::1', NULL, '2026-09-30 11:55:58'),
(17, 3, 'login_success', 'user', 3, '::1', NULL, '2026-09-30 11:56:03'),
(18, 1, 'site_created', 'site', 1, '::1', NULL, '2026-09-30 11:57:25'),
(19, 1, 'work_plan_created', 'work_plan', 1, '::1', NULL, '2026-09-30 11:57:48'),
(20, 3, 'work_plan_progress_updated', 'work_plan', 1, '::1', NULL, '2026-09-30 11:58:10'),
(21, 3, 'work_plan_progress_updated', 'work_plan', 1, '::1', NULL, '2026-09-30 11:58:22'),
(22, 1, 'warehouse_item_created', 'warehouse_item', 1, '::1', NULL, '2026-09-30 12:05:11'),
(23, 1, 'warehouse_item_updated', 'warehouse_item', 1, '::1', NULL, '2026-09-30 12:05:52'),
(24, 1, 'warehouse_out', 'warehouse_item', 1, '::1', NULL, '2026-09-30 12:06:36'),
(25, 1, 'account_created', 'account', 17, '::1', NULL, '2026-09-30 12:07:21'),
(26, 3, 'daily_report_submitted', 'report', 1, '::1', NULL, '2026-09-30 12:09:42'),
(27, 1, 'report_approved', 'report', 1, '::1', NULL, '2026-09-30 12:10:16'),
(28, 1, 'site_deleted', 'site', 1, '::1', NULL, '2026-09-30 12:12:14');

-- --------------------------------------------------------

--
-- بنية الجدول `device_fingerprints`
--

CREATE TABLE `device_fingerprints` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `fingerprint_hash` varchar(128) NOT NULL,
  `user_agent` varchar(500) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `first_seen` datetime DEFAULT current_timestamp(),
  `last_seen` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `device_fingerprints`
--

INSERT INTO `device_fingerprints` (`id`, `user_id`, `fingerprint_hash`, `user_agent`, `ip_address`, `first_seen`, `last_seen`) VALUES
(1, 1, 'ccc54c7823a726f1e910c560f2225bdd0357d4dcadaa48a0a67bcc15353b4226', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.139.1 Chrome/150.0.7871.250 Electron/43.6.0 Safari/537.36', '::1', '2026-09-30 11:41:32', '2026-09-30 11:41:32'),
(2, 1, '0488790d70201512991b5b28fb3d7543a919e6c952aa09fc070b5236b1982027', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.139.1 Chrome/150.0.7871.250 Electron/43.6.0 Safari/537.36', '::1', '2026-09-30 11:42:06', '2026-09-30 11:42:06'),
(7, 1, '92f1e39f30373dc21a56b09e709d764c8f7c9a2a321f8359ea8d062e259eebe1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.139.1 Chrome/150.0.7871.250 Electron/43.6.0 Safari/537.36', '::1', '2026-09-30 11:48:26', '2026-09-30 11:48:26'),
(8, 1, 'd7d7b2f816d724504a2dfb0ef1e9c347c210b7c6316666dfb2cc700c3afd5f81', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '::1', '2026-09-30 11:52:55', '2026-09-30 11:52:55'),
(9, 3, 'dd9d68a8c98b634747e756b61173b6b2c6b99471395ab26dc78f973ad9f089fc', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '::1', '2026-09-30 11:56:03', '2026-09-30 11:56:03');

-- --------------------------------------------------------

--
-- بنية الجدول `electronic_signatures`
--

CREATE TABLE `electronic_signatures` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `entity_type` varchar(50) NOT NULL,
  `entity_id` bigint(20) UNSIGNED NOT NULL,
  `signature_hash` varchar(255) NOT NULL,
  `signed_data` text DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `signed_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `journal_entries`
--

CREATE TABLE `journal_entries` (
  `id` int(10) UNSIGNED NOT NULL,
  `entry_number` varchar(50) NOT NULL,
  `entry_date` date NOT NULL,
  `description` varchar(500) NOT NULL,
  `reference` varchar(100) DEFAULT NULL,
  `site_id` int(10) UNSIGNED DEFAULT NULL,
  `report_id` int(10) UNSIGNED DEFAULT NULL,
  `total_debit` decimal(15,2) DEFAULT 0.00,
  `total_credit` decimal(15,2) DEFAULT 0.00,
  `status` enum('draft','posted','cancelled') DEFAULT 'posted',
  `signature_hash` varchar(255) DEFAULT NULL,
  `signed_by` int(10) UNSIGNED DEFAULT NULL,
  `signed_at` datetime DEFAULT NULL,
  `created_by` int(10) UNSIGNED NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `journal_entries`
--

INSERT INTO `journal_entries` (`id`, `entry_number`, `entry_date`, `description`, `reference`, `site_id`, `report_id`, `total_debit`, `total_credit`, `status`, `signature_hash`, `signed_by`, `signed_at`, `created_by`, `created_at`) VALUES
(1, 'JE-20260930-120636-996', '2026-09-30', 'حركة مخزن صادر · اسمنت', NULL, NULL, NULL, 60000.00, 60000.00, 'posted', 'fef2db8aa99f0ab25f36d5a863fb053d172b6a2d7619bf9a391decad1c1d003f', 1, '2026-09-30 12:06:36', 1, '2026-09-30 12:06:36');

-- --------------------------------------------------------

--
-- بنية الجدول `journal_entry_lines`
--

CREATE TABLE `journal_entry_lines` (
  `id` int(10) UNSIGNED NOT NULL,
  `entry_id` int(10) UNSIGNED NOT NULL,
  `account_id` int(10) UNSIGNED NOT NULL,
  `debit` decimal(15,2) DEFAULT 0.00,
  `credit` decimal(15,2) DEFAULT 0.00,
  `description` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `journal_entry_lines`
--

INSERT INTO `journal_entry_lines` (`id`, `entry_id`, `account_id`, `debit`, `credit`, `description`) VALUES
(1, 1, 11, 60000.00, 0.00, ''),
(2, 1, 4, 0.00, 60000.00, '');

-- --------------------------------------------------------

--
-- بنية الجدول `machinery`
--

CREATE TABLE `machinery` (
  `id` int(10) UNSIGNED NOT NULL,
  `code` varchar(50) NOT NULL,
  `name` varchar(200) NOT NULL,
  `plate_number` varchar(50) DEFAULT NULL,
  `operator_name` varchar(150) DEFAULT NULL,
  `status` enum('available','in_use','maintenance','out_of_service') DEFAULT 'available',
  `hourly_cost` decimal(10,2) DEFAULT 0.00,
  `notes` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `machinery_repairs`
--

CREATE TABLE `machinery_repairs` (
  `id` int(10) UNSIGNED NOT NULL,
  `machinery_id` int(10) UNSIGNED NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `problem_type` enum('mechanical','electrical','body','tires','other') DEFAULT 'mechanical',
  `status` enum('pending','in_progress','waiting_parts','completed','cancelled') DEFAULT 'pending',
  `priority` enum('low','medium','high','urgent') DEFAULT 'medium',
  `technician_name` varchar(150) DEFAULT NULL,
  `workshop` varchar(200) DEFAULT NULL,
  `labor_cost` decimal(15,2) DEFAULT 0.00,
  `parts_cost` decimal(15,2) DEFAULT 0.00,
  `total_cost` decimal(15,2) DEFAULT 0.00,
  `reported_by` int(10) UNSIGNED NOT NULL,
  `started_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `machinery_repair_parts`
--

CREATE TABLE `machinery_repair_parts` (
  `id` int(10) UNSIGNED NOT NULL,
  `repair_id` int(10) UNSIGNED NOT NULL,
  `part_name` varchar(200) NOT NULL,
  `quantity` decimal(10,2) DEFAULT 1.00,
  `unit_price` decimal(15,2) DEFAULT 0.00,
  `total` decimal(15,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text DEFAULT NULL,
  `type` enum('info','success','warning','danger') DEFAULT 'info',
  `link` varchar(255) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `type`, `link`, `is_read`, `created_at`) VALUES
(1, 1, 'طلب تسجيل جديد', 'طلب المهندس منتظر محمد الموافقة على حسابه', 'warning', 'admin/pending_users.php', 1, '2026-09-30 11:55:37'),
(2, 3, 'تم اعتماد حسابك', 'يمكنك الآن تسجيل الدخول إلى النظام', 'success', NULL, 0, '2026-09-30 11:55:58'),
(3, 3, 'خطة عمل جديدة', 'حفر شارع', 'info', 'engineer/tasks.php', 0, '2026-09-30 11:57:48'),
(4, 1, 'تحديث على خطة عمل', 'منتظر محمد حدّث المهمة: حفر شارع', 'info', 'admin/work_updates.php?plan=1', 1, '2026-09-30 11:58:10'),
(5, 1, 'تحديث على خطة عمل', 'منتظر محمد حدّث المهمة: حفر شارع', 'info', 'admin/work_updates.php?plan=1', 1, '2026-09-30 11:58:22'),
(6, 1, 'تقرير يومي جديد', 'تم إرسال تقرير من منتظر محمد', 'info', 'admin/reports.php?status=submitted', 1, '2026-09-30 12:09:42'),
(7, 3, 'تم اعتماد التقرير', 'شارع1', 'success', 'engineer/dashboard.php', 0, '2026-09-30 12:10:16');

-- --------------------------------------------------------

--
-- بنية الجدول `report_expenses`
--

CREATE TABLE `report_expenses` (
  `id` int(10) UNSIGNED NOT NULL,
  `report_id` int(10) UNSIGNED NOT NULL,
  `item_name` varchar(200) NOT NULL,
  `category` enum('materials','labor','fuel','equipment','transport','other') DEFAULT 'materials',
  `quantity` decimal(12,3) DEFAULT 1.000,
  `unit_price` decimal(15,2) DEFAULT 0.00,
  `total` decimal(15,2) DEFAULT 0.00,
  `notes` varchar(500) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `report_receipts`
--

CREATE TABLE `report_receipts` (
  `id` int(10) UNSIGNED NOT NULL,
  `report_id` int(10) UNSIGNED NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `original_name` varchar(255) DEFAULT NULL,
  `file_type` varchar(50) DEFAULT NULL,
  `file_size` int(10) UNSIGNED DEFAULT NULL,
  `uploaded_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(128) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `fingerprint_hash` varchar(128) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(500) DEFAULT NULL,
  `last_activity` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `fingerprint_hash`, `ip_address`, `user_agent`, `last_activity`) VALUES
('94jred7el58a075le55hpi5sru', 1, 'd7d7b2f816d724504a2dfb0ef1e9c347c210b7c6316666dfb2cc700c3afd5f81', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', 1790759649),
('qt4mhq8fv63nap1nqvji8v1q85', 1, '92f1e39f30373dc21a56b09e709d764c8f7c9a2a321f8359ea8d062e259eebe1', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.139.1 Chrome/150.0.7871.250 Electron/43.6.0 Safari/537.36', 1790758240),
('vulj2mne9ertb1mt142bqu4hg5', 3, 'dd9d68a8c98b634747e756b61173b6b2c6b99471395ab26dc78f973ad9f089fc', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 1790759382);

-- --------------------------------------------------------

--
-- بنية الجدول `sites`
--

CREATE TABLE `sites` (
  `id` int(10) UNSIGNED NOT NULL,
  `code` varchar(50) NOT NULL,
  `name` varchar(200) NOT NULL,
  `client_name` varchar(200) DEFAULT NULL,
  `work_date` date DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `budget` decimal(15,2) DEFAULT 0.00,
  `status` enum('planning','active','paused','completed','cancelled') DEFAULT 'active',
  `manager_id` int(10) UNSIGNED DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_by` int(10) UNSIGNED DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `site_daily_reports`
--

CREATE TABLE `site_daily_reports` (
  `id` int(10) UNSIGNED NOT NULL,
  `site_id` int(10) UNSIGNED NOT NULL,
  `report_date` date NOT NULL,
  `engineer_id` int(10) UNSIGNED NOT NULL,
  `weather` varchar(80) DEFAULT NULL,
  `temperature` decimal(5,2) DEFAULT NULL,
  `workers_count` int(10) UNSIGNED DEFAULT 0,
  `machinery_count` int(10) UNSIGNED DEFAULT 0,
  `work_done` text DEFAULT NULL,
  `issues` text DEFAULT NULL,
  `materials_used` text DEFAULT NULL,
  `safety_notes` text DEFAULT NULL,
  `progress_percent` tinyint(3) UNSIGNED DEFAULT 0,
  `status` enum('draft','submitted','approved','rejected') DEFAULT 'draft',
  `admin_notes` text DEFAULT NULL,
  `approved_by` int(10) UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `username` varchar(80) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('admin','engineer') NOT NULL DEFAULT 'engineer',
  `phone` varchar(30) DEFAULT NULL,
  `specialization` varchar(100) DEFAULT NULL,
  `signature_path` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `approval_status` enum('pending','approved','rejected') DEFAULT 'pending',
  `last_login` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `users`
--

INSERT INTO `users` (`id`, `full_name`, `username`, `email`, `password_hash`, `role`, `phone`, `specialization`, `signature_path`, `is_active`, `approval_status`, `last_login`, `created_at`, `updated_at`) VALUES
(1, 'مدير النظام', 'admin', 'admin@spacepoint.local', '$2y$10$8uZt7zceyMn30HDCMse8ner8YQgWM8DhjT7dcS0xzfWY1Ly2m8ryW', 'admin', NULL, NULL, NULL, 1, 'approved', '2026-09-30 11:52:55', '2026-09-30 11:20:27', '2026-09-30 11:52:55'),
(3, 'منتظر محمد', 'montather', 'montatherm39@gmail.com', '$2y$10$Tc.2Mcfkev.NMcRb.R5O7uFddsKCqjmnxhVmfVFS44wFHpMIUB5Me', 'engineer', '07714992467', 'مشرف موقع', NULL, 1, 'approved', '2026-09-30 11:56:03', '2026-09-30 11:55:37', '2026-09-30 11:56:03');

-- --------------------------------------------------------

--
-- بنية الجدول `warehouse_categories`
--

CREATE TABLE `warehouse_categories` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `warehouse_categories`
--

INSERT INTO `warehouse_categories` (`id`, `name`, `description`, `created_at`) VALUES
(1, 'مواد بناء', 'أسمنت، حديد، رمل، حصى', '2026-09-30 11:20:27'),
(2, 'كهربائيات', 'أسلاك، قواطع، إضاءة', '2026-09-30 11:20:27'),
(3, 'سباكة', 'أنابيب، محابس، وصلات', '2026-09-30 11:20:27'),
(4, 'أدوات', 'عدد يدوية', '2026-09-30 11:20:27'),
(5, 'وقود وزيوت', 'بنزين، ديزل، زيوت', '2026-09-30 11:20:27');

-- --------------------------------------------------------

--
-- بنية الجدول `warehouse_items`
--

CREATE TABLE `warehouse_items` (
  `id` int(10) UNSIGNED NOT NULL,
  `code` varchar(50) NOT NULL,
  `name` varchar(200) NOT NULL,
  `category_id` int(10) UNSIGNED DEFAULT NULL,
  `unit` varchar(30) DEFAULT 'قطعة',
  `quantity` decimal(15,3) DEFAULT 0.000,
  `min_quantity` decimal(15,3) DEFAULT 0.000,
  `unit_price` decimal(15,2) DEFAULT 0.00,
  `location` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `warehouse_items`
--

INSERT INTO `warehouse_items` (`id`, `code`, `name`, `category_id`, `unit`, `quantity`, `min_quantity`, `unit_price`, `location`, `notes`, `is_active`, `created_at`) VALUES
(1, '112', 'اسمنت', 1, 'قطعة', 40.000, 20.000, 6000.00, 'موقعي1', '', 1, '2026-09-30 12:05:11');

-- --------------------------------------------------------

--
-- بنية الجدول `warehouse_transactions`
--

CREATE TABLE `warehouse_transactions` (
  `id` int(10) UNSIGNED NOT NULL,
  `item_id` int(10) UNSIGNED NOT NULL,
  `type` enum('in','out','adjust') NOT NULL,
  `quantity` decimal(15,3) NOT NULL,
  `unit_price` decimal(15,2) DEFAULT 0.00,
  `total_price` decimal(15,2) DEFAULT 0.00,
  `site_id` int(10) UNSIGNED DEFAULT NULL,
  `supplier` varchar(200) DEFAULT NULL,
  `invoice_number` varchar(100) DEFAULT NULL,
  `reason` varchar(500) DEFAULT NULL,
  `created_by` int(10) UNSIGNED NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `warehouse_transactions`
--

INSERT INTO `warehouse_transactions` (`id`, `item_id`, `type`, `quantity`, `unit_price`, `total_price`, `site_id`, `supplier`, `invoice_number`, `reason`, `created_by`, `created_at`) VALUES
(1, 1, 'out', 10.000, 6000.00, 60000.00, NULL, 'اسمنت', '1', 'تكلير مسار الوفود', 1, '2026-09-30 12:06:36');

-- --------------------------------------------------------

--
-- بنية الجدول `work_plans`
--

CREATE TABLE `work_plans` (
  `id` int(10) UNSIGNED NOT NULL,
  `site_id` int(10) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `assigned_to` int(10) UNSIGNED DEFAULT NULL,
  `is_broadcast` tinyint(1) DEFAULT 0,
  `priority` enum('low','medium','high','urgent') DEFAULT 'medium',
  `status` enum('pending','in_progress','review','done','cancelled') DEFAULT 'pending',
  `progress` tinyint(3) UNSIGNED DEFAULT 0,
  `created_by` int(10) UNSIGNED DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `work_plan_updates`
--

CREATE TABLE `work_plan_updates` (
  `id` int(10) UNSIGNED NOT NULL,
  `work_plan_id` int(10) UNSIGNED NOT NULL,
  `engineer_id` int(10) UNSIGNED NOT NULL,
  `old_progress` tinyint(3) UNSIGNED DEFAULT NULL,
  `new_progress` tinyint(3) UNSIGNED DEFAULT NULL,
  `old_status` varchar(30) DEFAULT NULL,
  `new_status` varchar(30) DEFAULT NULL,
  `note` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `idx_type` (`type`);

--
-- Indexes for table `api_logs`
--
ALTER TABLE `api_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_created` (`created_at`);

--
-- Indexes for table `api_tokens`
--
ALTER TABLE `api_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `refresh_token` (`refresh_token`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_token` (`refresh_token`),
  ADD KEY `idx_expires` (`expires_at`);

--
-- Indexes for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_action` (`action`);

--
-- Indexes for table `device_fingerprints`
--
ALTER TABLE `device_fingerprints`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_user_fp` (`user_id`,`fingerprint_hash`);

--
-- Indexes for table `electronic_signatures`
--
ALTER TABLE `electronic_signatures`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_entity` (`entity_type`,`entity_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `journal_entries`
--
ALTER TABLE `journal_entries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `entry_number` (`entry_number`),
  ADD KEY `idx_date` (`entry_date`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `site_id` (`site_id`),
  ADD KEY `signed_by` (`signed_by`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `journal_entry_lines`
--
ALTER TABLE `journal_entry_lines`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_entry` (`entry_id`),
  ADD KEY `account_id` (`account_id`);

--
-- Indexes for table `machinery`
--
ALTER TABLE `machinery`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `machinery_repairs`
--
ALTER TABLE `machinery_repairs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_machinery` (`machinery_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `reported_by` (`reported_by`);

--
-- Indexes for table `machinery_repair_parts`
--
ALTER TABLE `machinery_repair_parts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_repair` (`repair_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_read` (`user_id`,`is_read`);

--
-- Indexes for table `report_expenses`
--
ALTER TABLE `report_expenses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_report` (`report_id`);

--
-- Indexes for table `report_receipts`
--
ALTER TABLE `report_receipts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_report` (`report_id`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user` (`user_id`);

--
-- Indexes for table `sites`
--
ALTER TABLE `sites`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `manager_id` (`manager_id`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `site_daily_reports`
--
ALTER TABLE `site_daily_reports`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_report` (`site_id`,`report_date`,`engineer_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `engineer_id` (`engineer_id`),
  ADD KEY `approved_by` (`approved_by`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_role` (`role`),
  ADD KEY `idx_status` (`approval_status`);

--
-- Indexes for table `warehouse_categories`
--
ALTER TABLE `warehouse_categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `warehouse_items`
--
ALTER TABLE `warehouse_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `idx_category` (`category_id`);

--
-- Indexes for table `warehouse_transactions`
--
ALTER TABLE `warehouse_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_item` (`item_id`),
  ADD KEY `idx_type` (`type`),
  ADD KEY `site_id` (`site_id`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `work_plans`
--
ALTER TABLE `work_plans`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_assigned` (`assigned_to`),
  ADD KEY `site_id` (`site_id`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `work_plan_updates`
--
ALTER TABLE `work_plan_updates`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_plan` (`work_plan_id`),
  ADD KEY `engineer_id` (`engineer_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `api_logs`
--
ALTER TABLE `api_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `api_tokens`
--
ALTER TABLE `api_tokens`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `audit_log`
--
ALTER TABLE `audit_log`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `device_fingerprints`
--
ALTER TABLE `device_fingerprints`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `electronic_signatures`
--
ALTER TABLE `electronic_signatures`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `journal_entries`
--
ALTER TABLE `journal_entries`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `journal_entry_lines`
--
ALTER TABLE `journal_entry_lines`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `machinery`
--
ALTER TABLE `machinery`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `machinery_repairs`
--
ALTER TABLE `machinery_repairs`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `machinery_repair_parts`
--
ALTER TABLE `machinery_repair_parts`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `report_expenses`
--
ALTER TABLE `report_expenses`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `report_receipts`
--
ALTER TABLE `report_receipts`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `sites`
--
ALTER TABLE `sites`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `site_daily_reports`
--
ALTER TABLE `site_daily_reports`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `warehouse_categories`
--
ALTER TABLE `warehouse_categories`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `warehouse_items`
--
ALTER TABLE `warehouse_items`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `warehouse_transactions`
--
ALTER TABLE `warehouse_transactions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `work_plans`
--
ALTER TABLE `work_plans`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `work_plan_updates`
--
ALTER TABLE `work_plan_updates`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- قيود الجداول المُلقاة.
--

--
-- قيود الجداول `api_tokens`
--
ALTER TABLE `api_tokens`
  ADD CONSTRAINT `fk_token_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- قيود الجداول `audit_log`
--
ALTER TABLE `audit_log`
  ADD CONSTRAINT `audit_log_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- قيود الجداول `device_fingerprints`
--
ALTER TABLE `device_fingerprints`
  ADD CONSTRAINT `device_fingerprints_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- قيود الجداول `electronic_signatures`
--
ALTER TABLE `electronic_signatures`
  ADD CONSTRAINT `electronic_signatures_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- قيود الجداول `journal_entries`
--
ALTER TABLE `journal_entries`
  ADD CONSTRAINT `journal_entries_ibfk_1` FOREIGN KEY (`site_id`) REFERENCES `sites` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `journal_entries_ibfk_2` FOREIGN KEY (`signed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `journal_entries_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`);

--
-- قيود الجداول `journal_entry_lines`
--
ALTER TABLE `journal_entry_lines`
  ADD CONSTRAINT `journal_entry_lines_ibfk_1` FOREIGN KEY (`entry_id`) REFERENCES `journal_entries` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `journal_entry_lines_ibfk_2` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`);

--
-- قيود الجداول `machinery_repairs`
--
ALTER TABLE `machinery_repairs`
  ADD CONSTRAINT `machinery_repairs_ibfk_1` FOREIGN KEY (`machinery_id`) REFERENCES `machinery` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `machinery_repairs_ibfk_2` FOREIGN KEY (`reported_by`) REFERENCES `users` (`id`);

--
-- قيود الجداول `machinery_repair_parts`
--
ALTER TABLE `machinery_repair_parts`
  ADD CONSTRAINT `machinery_repair_parts_ibfk_1` FOREIGN KEY (`repair_id`) REFERENCES `machinery_repairs` (`id`) ON DELETE CASCADE;

--
-- قيود الجداول `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- قيود الجداول `report_expenses`
--
ALTER TABLE `report_expenses`
  ADD CONSTRAINT `report_expenses_ibfk_1` FOREIGN KEY (`report_id`) REFERENCES `site_daily_reports` (`id`) ON DELETE CASCADE;

--
-- قيود الجداول `report_receipts`
--
ALTER TABLE `report_receipts`
  ADD CONSTRAINT `report_receipts_ibfk_1` FOREIGN KEY (`report_id`) REFERENCES `site_daily_reports` (`id`) ON DELETE CASCADE;

--
-- قيود الجداول `sessions`
--
ALTER TABLE `sessions`
  ADD CONSTRAINT `sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- قيود الجداول `sites`
--
ALTER TABLE `sites`
  ADD CONSTRAINT `sites_ibfk_1` FOREIGN KEY (`manager_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `sites_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- قيود الجداول `site_daily_reports`
--
ALTER TABLE `site_daily_reports`
  ADD CONSTRAINT `site_daily_reports_ibfk_1` FOREIGN KEY (`site_id`) REFERENCES `sites` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `site_daily_reports_ibfk_2` FOREIGN KEY (`engineer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `site_daily_reports_ibfk_3` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- قيود الجداول `warehouse_items`
--
ALTER TABLE `warehouse_items`
  ADD CONSTRAINT `warehouse_items_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `warehouse_categories` (`id`) ON DELETE SET NULL;

--
-- قيود الجداول `warehouse_transactions`
--
ALTER TABLE `warehouse_transactions`
  ADD CONSTRAINT `warehouse_transactions_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `warehouse_items` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `warehouse_transactions_ibfk_2` FOREIGN KEY (`site_id`) REFERENCES `sites` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `warehouse_transactions_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`);

--
-- قيود الجداول `work_plans`
--
ALTER TABLE `work_plans`
  ADD CONSTRAINT `work_plans_ibfk_1` FOREIGN KEY (`site_id`) REFERENCES `sites` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `work_plans_ibfk_2` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `work_plans_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- قيود الجداول `work_plan_updates`
--
ALTER TABLE `work_plan_updates`
  ADD CONSTRAINT `work_plan_updates_ibfk_1` FOREIGN KEY (`work_plan_id`) REFERENCES `work_plans` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `work_plan_updates_ibfk_2` FOREIGN KEY (`engineer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
