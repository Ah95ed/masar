<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';
Auth::requireRole('admin');
$summary = [
    'items' => (int) db()->query('SELECT COUNT(*) FROM warehouse_items WHERE is_active=1')->fetchColumn(),
    'low' => (int) db()->query('SELECT COUNT(*) FROM warehouse_items WHERE is_active=1 AND quantity<=min_quantity')->fetchColumn(),
    'value' => (float) db()->query('SELECT COALESCE(SUM(quantity*unit_price),0) FROM warehouse_items WHERE is_active=1')->fetchColumn(),
    'categories' => (int) db()->query('SELECT COUNT(*) FROM warehouse_categories')->fetchColumn(),
];
$lowItems = db()->query('SELECT id, code, name, unit, quantity, min_quantity FROM warehouse_items WHERE is_active=1 AND quantity<=min_quantity ORDER BY quantity ASC LIMIT 12')->fetchAll();
$moves = db()->query('SELECT t.*, i.name AS item_name, u.full_name FROM warehouse_transactions t JOIN warehouse_items i ON i.id=t.item_id JOIN users u ON u.id=t.created_by ORDER BY t.created_at DESC LIMIT 8')->fetchAll();
$pageTitle = 'لوحة المخزن';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>المخزن</h1><p>الأرصدة والقيمة والحركات المسجلة</p></div><div class="btn-group"><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/warehouse_items.php')) ?>">إدارة المواد</a><a class="btn btn-primary" href="<?= Security::e(pageUrl('admin/warehouse_moves.php')) ?>"><?= icon('plus') ?>حركة جديدة</a></div></div>
<section class="grid-stats"><article class="stat-card"><div class="stat-top"><span>مواد نشطة</span><span class="stat-icon"><?= icon('box') ?></span></div><div class="stat-value"><?= $summary['items'] ?></div></article><article class="stat-card" style="--accent:var(--amber)"><div class="stat-top"><span>مواد منخفضة</span><span class="stat-icon"><?= icon('chart') ?></span></div><div class="stat-value"><?= $summary['low'] ?></div></article><article class="stat-card"><div class="stat-top"><span>قيمة المخزون</span><span class="stat-icon"><?= icon('wallet') ?></span></div><div class="stat-value" style="font-size:20px"><?= Security::e(money($summary['value'])) ?></div></article><article class="stat-card"><div class="stat-top"><span>فئات</span><span class="stat-icon"><?= icon('grid') ?></span></div><div class="stat-value"><?= $summary['categories'] ?></div></article></section>
<section class="grid-2"><div class="table-panel"><div class="table-toolbar"><h2>مواد عند حد إعادة الطلب</h2><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/warehouse_items.php?filter=low')) ?>">إدارة المواد</a></div><div class="table-wrapper table-cards"><table><thead><tr><th>الكود</th><th>المادة</th><th>الكمية</th><th>الحد الأدنى</th></tr></thead><tbody><?php foreach ($lowItems as $item): ?><tr><td data-label="الكود"><?= Security::e($item['code']) ?></td><td data-label="المادة"><?= Security::e($item['name']) ?></td><td data-label="الكمية"><span class="pill danger"><?= Security::e($item['quantity'] . ' ' . $item['unit']) ?></span></td><td data-label="الحد الأدنى"><?= Security::e($item['min_quantity']) ?></td></tr><?php endforeach; ?><?php if ($lowItems === []): ?><tr><td colspan="4" class="empty-state">جميع المواد فوق الحد الأدنى</td></tr><?php endif; ?></tbody></table></div></div>
<div class="table-panel"><div class="table-toolbar"><h2>آخر الحركات</h2><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/warehouse_moves.php')) ?>">سجل الحركات</a></div><div class="table-wrapper table-cards"><table><thead><tr><th>المادة</th><th>النوع</th><th>الكمية</th><th>المسجل</th></tr></thead><tbody><?php foreach ($moves as $move): ?><tr><td data-label="المادة"><?= Security::e($move['item_name']) ?></td><td data-label="النوع"><?= Security::e(statusLabel((string) $move['type'])) ?></td><td data-label="الكمية"><?= Security::e($move['quantity']) ?></td><td data-label="المسجل"><?= Security::e($move['full_name']) ?></td></tr><?php endforeach; ?><?php if ($moves === []): ?><tr><td colspan="4" class="empty-state">لا توجد حركات مسجلة</td></tr><?php endif; ?></tbody></table></div></div></section></div></main><?php require __DIR__ . '/../footer.php'; ?>