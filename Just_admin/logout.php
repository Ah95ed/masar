<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/database.php';
require_once __DIR__ . '/security.php';
require_once __DIR__ . '/auth.php';

Auth::logout();
header('Location: ' . APP_URL . '/login.php');
exit;