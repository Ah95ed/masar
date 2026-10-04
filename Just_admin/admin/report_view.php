<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';
Auth::requireRole('admin');
$reportId = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT) ?: 0;
$statement = db()->prepare('SELECT r.*, s.name AS site_name, s.code AS site_code, u.full_name, u.username, reviewer.full_name AS reviewer_name FROM site_daily_reports r JOIN sites s ON s.id=r.site_id JOIN users u ON u.id=r.engineer_id LEFT JOIN users reviewer ON reviewer.id=r.approved_by WHERE r.id=?');
$statement->execute([$reportId]);
$report = $statement->fetch();
if (!$report) {
    http_response_code(404);
    exit('التقرير غير موجود');
}
$expenseQuery = db()->prepare('SELECT * FROM report_expenses WHERE report_id=? ORDER BY id');
$expenseQuery->execute([$reportId]);
$expenses = $expenseQuery->fetchAll();
$receiptQuery = db()->prepare('SELECT * FROM report_receipts WHERE report_id=? ORDER BY id');
$receiptQuery->execute([$reportId]);
$receipts = $receiptQuery->fetchAll();
$expenseLabels = ['materials'=>'مواد','labor'=>'عمالة','fuel'=>'وقود','equipment'=>'معدات','transport'=>'نقل','other'=>'أخرى'];
$expenseTotal = array_sum(array_map(static fn(array $expense): float => (float) $expense['total'], $expenses));
$pageTitle = 'معاينة التقرير اليومي';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap">
    <div class="page-header"><div><h1>التقرير اليومي</h1><p><?= Security::e($report['site_name']) ?> · <?= Security::e($report['report_date']) ?> · <?= Security::e($report['full_name']) ?></p></div><div class="btn-group"><span class="pill <?= $report['status'] === 'approved' ? 'success' : ($report['status'] === 'submitted' ? 'warning' : '') ?>"><?= Security::e(statusLabel((string) $report['status'])) ?></span><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/reports.php')) ?>">العودة للتقارير</a></div></div>
    <section class="grid-stats" aria-label="ملخص التقرير"><article class="stat-card"><div class="stat-top"><span>نسبة الإنجاز</span></div><div class="stat-value"><?= (int) $report['progress_percent'] ?>%</div></article><article class="stat-card"><div class="stat-top"><span>عدد العمال</span></div><div class="stat-value"><?= (int) $report['workers_count'] ?></div></article><article class="stat-card"><div class="stat-top"><span>عدد الآليات</span></div><div class="stat-value"><?= (int) $report['machinery_count'] ?></div></article><article class="stat-card"><div class="stat-top"><span>إجمالي المصروفات</span></div><div class="stat-value" style="font-size:20px"><?= Security::e(money($expenseTotal)) ?></div></article></section>
    <section class="grid-2" style="margin-top:18px"><article class="panel"><h2 class="panel-title">بيانات الموقع والظروف</h2><div class="list-row"><strong>الموقع</strong><span><?= Security::e($report['site_name']) ?> (<?= Security::e($report['site_code']) ?>)</span></div><div class="list-row"><strong>المهندس</strong><span><?= Security::e($report['full_name']) ?> · <?= Security::e($report['username']) ?></span></div><div class="list-row"><strong>الطقس</strong><span><?= Security::e($report['weather'] ?: 'غير محدد') ?></span></div><div class="list-row"><strong>درجة الحرارة</strong><span><?= $report['temperature'] === null ? 'غير محددة' : Security::e($report['temperature'] . '°') ?></span></div><div class="list-row"><strong>تاريخ الإرسال</strong><span><?= Security::e($report['created_at']) ?></span></div></article><article class="panel"><h2 class="panel-title">مراجعة الإدارة</h2><div class="list-row"><strong>المراجع</strong><span><?= Security::e($report['reviewer_name'] ?: 'لم تتم المراجعة') ?></span></div><div class="list-row"><strong>وقت الاعتماد</strong><span><?= Security::e($report['approved_at'] ?: '—') ?></span></div><div class="field" style="margin-top:12px"><label>ملاحظات الإدارة</label><div class="report-text"><?= nl2br(Security::e($report['admin_notes'] ?: 'لا توجد ملاحظات')) ?></div></div></article></section>
    <?php foreach ([['الأعمال المنجزة','work_done'],['المشاكل والعوائق','issues'],['المواد المستخدمة','materials_used'],['ملاحظات السلامة','safety_notes']] as [$heading,$field]): ?><section class="panel" style="margin-top:16px"><h2 class="panel-title"><?= Security::e($heading) ?></h2><div class="report-text"><?= nl2br(Security::e($report[$field] ?: 'لا توجد بيانات')) ?></div></section><?php endforeach; ?>
    <section class="table-panel" style="margin-top:16px"><div class="table-toolbar"><h2>تفاصيل المصروفات</h2><strong><?= Security::e(money($expenseTotal)) ?> د.ع</strong></div><div class="table-wrapper table-cards"><table><thead><tr><th>البند</th><th>التصنيف</th><th>الكمية</th><th>سعر الوحدة</th><th>الإجمالي</th><th>ملاحظات</th></tr></thead><tbody><?php foreach ($expenses as $expense): ?><tr><td data-label="البند"><?= Security::e($expense['item_name']) ?></td><td data-label="التصنيف"><?= Security::e($expenseLabels[$expense['category']] ?? $expense['category']) ?></td><td data-label="الكمية"><?= Security::e($expense['quantity']) ?></td><td data-label="سعر الوحدة"><?= Security::e(money($expense['unit_price'])) ?></td><td data-label="الإجمالي"><?= Security::e(money($expense['total'])) ?></td><td data-label="ملاحظات"><?= Security::e($expense['notes'] ?: '—') ?></td></tr><?php endforeach; ?><?php if ($expenses === []): ?><tr><td colspan="6" class="empty-state">لا توجد مصروفات مسجلة</td></tr><?php endif; ?></tbody></table></div></section>
    <section class="panel" style="margin-top:16px"><h2 class="panel-title">الإيصالات والمرفقات</h2><?php if ($receipts === []): ?><div class="empty-state">لا توجد مرفقات</div><?php else: ?><div class="grid gap-2"><?php foreach ($receipts as $receipt): ?><a class="quick-link" href="<?= Security::e(pageUrl((string) $receipt['file_path'])) ?>" target="_blank" rel="noopener noreferrer"><span><?= Security::e($receipt['original_name'] ?: 'مرفق التقرير') ?></span><span class="pill info"><?= Security::e(strtoupper((string) $receipt['file_type'])) ?> · <?= number_format((int) $receipt['file_size'] / 1024, 0) ?> KB</span></a><?php endforeach; ?></div><?php endif; ?></section>
</div></main><?php require __DIR__ . '/../footer.php'; ?>