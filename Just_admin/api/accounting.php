<?php
declare(strict_types=1);
$GLOBALS['apiAllowedRoutes'] = ['login','me','logout','dashboard','accounts','account-save','account-delete','journal','journal-entry','journal-create','financial'];
$GLOBALS['apiRequiredRoles'] = ['admin','accountant'];
require dirname(__DIR__) . '/api.php';