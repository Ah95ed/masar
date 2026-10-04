<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';

Auth::requireRole('admin');
$stats = [];
$stats['sites'] = (int) db()->query("SELECT COUNT(*) FROM sites WHERE status IN ('planning','active','paused')")->fetchColumn();
$stats['engineers'] = (int) db()->query("SELECT COUNT(*) FROM users WHERE role = 'engineer' AND is_active = 1 AND approval_status = 'approved'")->fetchColumn();
$stats['machinery'] = (int) db()->query("SELECT COUNT(*) FROM machinery WHERE status <> 'out_of_service'")->fetchColumn();
$stats['pending_reports'] = (int) db()->query("SELECT COUNT(*) FROM site_daily_reports WHERE status = 'submitted'")->fetchColumn();
$accountValues = db()->query("SELECT code, type, balance FROM accounts WHERE code='1100' OR type IN ('revenue','expense')")->fetchAll();
$balances = [];
foreach ($accountValues as $account) {
    if ($account['code'] === '1100') {
        $balances['1100'] = (float) $account['balance'];
    }
    if ($account['type'] === 'revenue' || $account['type'] === 'expense') {
        $balances[(string) $account['type']] = ($balances[(string) $account['type']] ?? 0.0) + (float) $account['balance'];
    }
}
$stats['cash'] = $balances['1100'] ?? 0.0;
$stats['revenue'] = $balances['revenue'] ?? 0.0;
$stats['expenses'] = $balances['expense'] ?? 0.0;
$stats['inventory'] = (float) db()->query('SELECT COALESCE(SUM(quantity * unit_price), 0) FROM warehouse_items WHERE is_active = 1')->fetchColumn();
$stats['open_repairs'] = (int) db()->query("SELECT COUNT(*) FROM machinery_repairs WHERE status IN ('pending','in_progress','waiting_parts')")->fetchColumn();
$stats['low_stock'] = (int) db()->query('SELECT COUNT(*) FROM warehouse_items WHERE is_active = 1 AND quantity <= min_quantity')->fetchColumn();
$stats['today_entries'] = (int) db()->query("SELECT COUNT(*) FROM journal_entries WHERE entry_date = CURRENT_DATE() AND status = 'posted'")->fetchColumn();
$recentReports = db()->query('SELECT r.id, r.report_date, r.status, r.progress_percent, s.name AS site_name, u.full_name FROM site_daily_reports r JOIN sites s ON s.id = r.site_id JOIN users u ON u.id = r.engineer_id ORDER BY r.created_at DESC LIMIT 5')->fetchAll();
$recentTasks = db()->query('SELECT p.id, p.title, p.status, p.progress, s.name AS site_name, u.full_name FROM work_plans p JOIN sites s ON s.id = p.site_id LEFT JOIN users u ON u.id = p.assigned_to ORDER BY p.updated_at DESC LIMIT 5')->fetchAll();
$recentUpdates = db()->query('SELECT x.note, x.new_progress, x.new_status, x.created_at, p.title, u.full_name FROM work_plan_updates x JOIN work_plans p ON p.id = x.work_plan_id JOIN users u ON u.id = x.engineer_id ORDER BY x.created_at DESC LIMIT 6')->fetchAll();
$todayProgress = [];
$todayReports = db()->query("SELECT r.engineer_id,u.full_name,AVG(r.progress_percent) AS average_progress,COUNT(*) AS activity_count FROM site_daily_reports r JOIN users u ON u.id=r.engineer_id WHERE r.report_date=CURRENT_DATE() AND r.status IN ('submitted','approved') GROUP BY r.engineer_id,u.full_name")->fetchAll();
$todayUpdates = db()->query("SELECT x.engineer_id,u.full_name,AVG(x.new_progress) AS average_progress,COUNT(*) AS activity_count,SUM(x.new_status='done') AS completed_tasks FROM work_plan_updates x JOIN users u ON u.id=x.engineer_id WHERE x.created_at>=CURRENT_DATE() AND x.created_at<DATE_ADD(CURRENT_DATE(),INTERVAL 1 DAY) GROUP BY x.engineer_id,u.full_name")->fetchAll();
foreach ([$todayReports, $todayUpdates] as $activityRows) {
    foreach ($activityRows as $activity) {
        $engineerId = (int) $activity['engineer_id'];
        if (!isset($todayProgress[$engineerId])) $todayProgress[$engineerId] = ['name'=>$activity['full_name'],'progress_total'=>0.0,'activity_count'=>0,'completed_tasks'=>0];
        $count = (int) $activity['activity_count'];
        $todayProgress[$engineerId]['progress_total'] += (float) $activity['average_progress'] * $count;
        $todayProgress[$engineerId]['activity_count'] += $count;
        $todayProgress[$engineerId]['completed_tasks'] += (int) ($activity['completed_tasks'] ?? 0);
    }
}
foreach ($todayProgress as &$activity) $activity['score'] = $activity['activity_count'] ? round($activity['progress_total'] / $activity['activity_count']) : 0;
unset($activity);
usort($todayProgress, static fn(array $left, array $right): int => ($right['score'] <=> $left['score']) ?: ($right['activity_count'] <=> $left['activity_count']));
$topToday = array_slice($todayProgress, 0, 7);
$pageTitle = 'لوحة التحكم';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap">
    <div class="page-header"><div><h1>لوحة التحكم</h1><p>ملخص العمليات والموقف المالي للمشاريع</p></div><span class="pill info"><?= Security::e(date('l، d F Y')) ?></span></div>
    <section class="grid-stats" aria-label="المؤشرات التشغيلية">
        <?php foreach ([['المواقع النشطة', $stats['sites'], 'pin', 'cyan'], ['المهندسون', $stats['engineers'], 'users', 'green'], ['الآليات', $stats['machinery'], 'truck', 'amber'], ['تقارير بانتظار المراجعة', $stats['pending_reports'], 'clipboard', 'red']] as [$label, $value, $symbol, $tone]): ?>
        <article class="stat-card" style="--accent:var(--<?= $tone ?>);--tint:var(--<?= $tone ?>-pale)"><div class="stat-top"><span><?= Security::e($label) ?></span><span class="stat-icon"><?= icon($symbol) ?></span></div><div class="stat-value"><?= number_format((int) $value) ?></div><div class="stat-sub">حتى <?= Security::e(date('H:i')) ?></div></article>
        <?php endforeach; ?>
    </section>
    <section class="grid-stats" aria-label="المؤشرات المالية">
        <?php foreach ([['النقدية', $stats['cash'], 'wallet'], ['الإيرادات', $stats['revenue'], 'chart'], ['المصروفات', $stats['expenses'], 'book'], ['قيمة المخزون', $stats['inventory'], 'box']] as [$label, $value, $symbol]): ?>
        <article class="stat-card"><div class="stat-top"><span><?= Security::e($label) ?></span><span class="stat-icon"><?= icon($symbol) ?></span></div><div class="stat-value" style="font-size:21px"><?= Security::e(money($value)) ?></div><div class="stat-sub">دينار عراقي</div></article>
        <?php endforeach; ?>
    </section>
    <section class="grid-2" style="margin-bottom:19px">
        <div class="panel"><div class="flex items-center justify-between gap-2"><h2 class="panel-title">إنجاز المهندسين اليوم</h2><?php if ($topToday !== []): ?><span class="pill success">الأعلى: <?= Security::e($topToday[0]['name']) ?> · <?= (int) $topToday[0]['score'] ?>%</span><?php endif; ?></div><p class="stat-sub">متوسط نسب الإنجاز المسجلة اليوم في التقارير وتحديثات المهام</p><canvas id="engineerTodayChart" height="145" aria-label="مقارنة متوسط إنجاز المهندسين اليوم"></canvas><?php if ($topToday === []): ?><div class="empty-state">لا توجد تقارير أو تحديثات مسجلة اليوم</div><?php endif; ?></div>
        <div class="table-panel"><div class="table-toolbar"><h2>تقييم الإنجاز اليومي</h2><span class="pill info">من 100</span></div><div class="table-wrapper table-cards"><table><thead><tr><th>الترتيب</th><th>المهندس</th><th>التقييم</th><th>الأنشطة</th><th>مهام منجزة</th></tr></thead><tbody><?php foreach ($topToday as $index => $activity): ?><tr><td data-label="الترتيب"><?= $index + 1 ?></td><td data-label="المهندس"><?= Security::e($activity['name']) ?></td><td data-label="التقييم"><span class="pill <?= $index === 0 ? 'success' : 'info' ?>"><?= (int) $activity['score'] ?>%</span></td><td data-label="الأنشطة"><?= (int) $activity['activity_count'] ?></td><td data-label="مهام منجزة"><?= (int) $activity['completed_tasks'] ?></td></tr><?php endforeach; ?><?php if ($topToday === []): ?><tr><td colspan="5" class="empty-state">لا توجد بيانات لهذا اليوم</td></tr><?php endif; ?></tbody></table></div></div>
    </section>
    <section class="grid-3" style="margin-bottom:19px">
        <a class="quick-link" href="<?= Security::e(pageUrl('admin/repairs.php')) ?>"><span class="stat-icon"><?= icon('tool') ?></span><span>تصليحات مفتوحة <strong><?= $stats['open_repairs'] ?></strong></span></a>
        <a class="quick-link" href="<?= Security::e(pageUrl('admin/warehouse_items.php?filter=low')) ?>"><span class="stat-icon"><?= icon('box') ?></span><span>مواد وصلت للحد الأدنى <strong><?= $stats['low_stock'] ?></strong></span></a>
        <a class="quick-link" href="<?= Security::e(pageUrl('admin/journal.php')) ?>"><span class="stat-icon"><?= icon('book') ?></span><span>قيود اليوم <strong><?= $stats['today_entries'] ?></strong></span></a>
    </section>
    <section class="grid-2" style="margin-bottom:19px">
        <div class="table-panel"><div class="table-toolbar"><h2>آخر التقارير</h2><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/reports.php')) ?>">عرض الكل</a></div><div class="table-wrapper table-cards"><table><thead><tr><th>الموقع</th><th>المهندس</th><th>التاريخ</th><th>الحالة</th></tr></thead><tbody>
        <?php foreach ($recentReports as $row): ?><tr><td data-label="الموقع"><?= Security::e($row['site_name']) ?></td><td data-label="المهندس"><?= Security::e($row['full_name']) ?></td><td data-label="التاريخ"><?= Security::e($row['report_date']) ?></td><td data-label="الحالة"><span class="pill <?= $row['status'] === 'approved' ? 'success' : ($row['status'] === 'submitted' ? 'warning' : '') ?>"><?= Security::e(statusLabel((string) $row['status'])) ?></span></td></tr><?php endforeach; ?>
        <?php if ($recentReports === []): ?><tr><td colspan="4" class="empty-state">لا توجد تقارير بعد</td></tr><?php endif; ?></tbody></table></div></div>
        <div class="table-panel"><div class="table-toolbar"><h2>آخر المهام</h2><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/work_plans.php')) ?>">عرض الكل</a></div><div class="table-wrapper table-cards"><table><thead><tr><th>المهمة</th><th>الموقع</th><th>المسؤول</th><th>التقدم</th></tr></thead><tbody>
        <?php foreach ($recentTasks as $row): ?><tr><td data-label="المهمة"><?= Security::e($row['title']) ?></td><td data-label="الموقع"><?= Security::e($row['site_name']) ?></td><td data-label="المسؤول"><?= Security::e($row['full_name'] ?? 'غير معين') ?></td><td data-label="التقدم"><div class="flex items-center gap-2"><span><?= (int) $row['progress'] ?>%</span><span class="progress"><span style="width:<?= min(100, (int) $row['progress']) ?>%"></span></span></div></td></tr><?php endforeach; ?>
        <?php if ($recentTasks === []): ?><tr><td colspan="4" class="empty-state">لا توجد مهام بعد</td></tr><?php endif; ?></tbody></table></div></div>
    </section>
    <section class="grid-2" style="margin-bottom:19px">
        <div class="panel"><h2 class="panel-title">تحديثات المهندسين</h2><?php foreach ($recentUpdates as $row): ?><div class="list-row"><div><strong><?= Security::e($row['full_name']) ?> · <?= Security::e($row['title']) ?></strong><small><?= Security::e($row['note'] ?: statusLabel((string) $row['new_status'])) ?> · <?= Security::e($row['created_at']) ?></small></div><span class="pill info"><?= (int) $row['new_progress'] ?>%</span></div><?php endforeach; ?><?php if ($recentUpdates === []): ?><div class="empty-state">لا توجد تحديثات بعد</div><?php endif; ?><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/work_updates.php')) ?>" style="margin-top:12px">سجل التحديثات</a></div>
        <div class="panel"><h2 class="panel-title">إجراءات سريعة</h2><div class="grid-2"><a class="quick-link" href="<?= Security::e(pageUrl('admin/sites.php?action=new')) ?>"><?= icon('plus') ?>موقع جديد</a><a class="quick-link" href="<?= Security::e(pageUrl('admin/work_plans.php?action=new')) ?>"><?= icon('plus') ?>خطة عمل</a><a class="quick-link" href="<?= Security::e(pageUrl('admin/warehouse_moves.php')) ?>"><?= icon('box') ?>حركة مخزن</a><a class="quick-link" href="<?= Security::e(pageUrl('admin/journal.php?action=new')) ?>"><?= icon('book') ?>قيد يومي</a></div></div>
    </section>
</div></main>
<?php if ($topToday !== []): ?><script src="https://cdn.jsdelivr.net/npm/chart.js"></script><script>new Chart(document.getElementById('engineerTodayChart'),{type:'bar',data:{labels:<?= json_encode(array_column($topToday,'name'),JSON_UNESCAPED_UNICODE|JSON_HEX_TAG|JSON_HEX_APOS|JSON_HEX_AMP|JSON_HEX_QUOT) ?>,datasets:[{label:'متوسط الإنجاز %',data:<?= json_encode(array_column($topToday,'score')) ?>,backgroundColor:'#13805d',borderRadius:4}]},options:{indexAxis:'y',responsive:true,plugins:{legend:{display:false}},scales:{x:{beginAtZero:true,max:100,ticks:{callback:value=>value+'%'}},y:{grid:{display:false}}}}});</script><?php endif; ?>
<?php require __DIR__ . '/../footer.php'; ?>