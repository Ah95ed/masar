<?php
declare(strict_types=1);
$GLOBALS['apiAllowedRoutes'] = ['login','me','logout','dashboard','sites','site-save','site-cancel','machinery','machinery-save','machinery-status','users','user-save','user-status','tasks','work-plan-save','work-plan-cancel','reports','report-review','accounts','account-save','account-delete','journal','journal-entry','journal-create','financial','warehouse-items','warehouse-categories','warehouse-moves','warehouse-item-save','warehouse-item-status','warehouse-move-create','warehouse-category-save','repairs','repair-create','repair-update','repair-status','notifications','notification-read','notification-read-all'];
$GLOBALS['apiRequiredRoles'] = ['admin'];
require dirname(__DIR__) . '/api.php';