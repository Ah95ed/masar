<?php
declare(strict_types=1);

define('APP_URL', 'http://localhost/finalmax');
define('APP_NAME', 'Maxlond');
define('APP_VERSION', '2.0.0');
define('APP_TIMEZONE', 'Asia/Baghdad');
define('SESSION_LIFETIME', 14400);
define('MAX_LOGIN_ATTEMPTS', 5);
define('LOCKOUT_TIME', 900);
define('UPLOAD_PATH', __DIR__ . '/uploads/');
define('MAX_FILE_SIZE', 5242880);
date_default_timezone_set(APP_TIMEZONE);
ini_set('session.cookie_httponly', '1');
ini_set('session.cookie_samesite', 'Strict');
ini_set('session.use_strict_mode', '1');
if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') {
    ini_set('session.cookie_secure', '1');
}
error_reporting(E_ALL);
ini_set('display_errors', '0');
ini_set('log_errors', '1');

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}