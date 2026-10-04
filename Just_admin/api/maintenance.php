<?php
declare(strict_types=1);
$GLOBALS['apiAllowedRoutes'] = ['login','me','logout','machinery','machinery-save','machinery-status','repairs','repair-create','repair-update','repair-status'];
$GLOBALS['apiRequiredRoles'] = ['admin'];
require dirname(__DIR__) . '/api.php';