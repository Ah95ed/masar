<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth.php';

if (!Auth::check()) {
    header('Location: ' . APP_URL . '/login.php');
    exit;
}
$destination = match (Auth::role()) {'admin'=>'admin/dashboard.php','accountant'=>'admin/financial.php',default=>'engineer/dashboard.php'};
header('Location: ' . APP_URL . '/' . $destination);
exit;