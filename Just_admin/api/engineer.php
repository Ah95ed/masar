<?php
declare(strict_types=1);
$GLOBALS['apiAllowedRoutes'] = ['login','me','logout','dashboard','sites','machinery','tasks','task-update','reports','report-receipt','notifications','notification-read','notification-read-all'];
$GLOBALS['apiRequiredRoles'] = ['engineer'];
require dirname(__DIR__) . '/api.php';