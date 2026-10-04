<?php
declare(strict_types=1);
$GLOBALS['apiAllowedRoutes'] = ['login','me','logout','warehouse-items','warehouse-moves','warehouse-move-create','warehouse-categories','warehouse-item-save','warehouse-item-status','warehouse-category-save'];
$GLOBALS['apiRequiredRoles'] = ['admin'];
require dirname(__DIR__) . '/api.php';