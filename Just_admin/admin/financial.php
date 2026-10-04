<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';
Auth::requireRole('admin','accountant');
$totals = db()->query('SELECT type, SUM(balance) AS total FROM accounts WHERE is_active=1 GROUP BY type')->fetchAll();
$balances = ['asset'=>0.0,'liability'=>0.0,'equity'=>0.0,'revenue'=>0.0,'expense'=>0.0];
foreach ($totals as $row) $balances[$row['type']] = (float) $row['total'];
$trial = db()->query('SELECT code,name,type,balance FROM accounts WHERE is_active=1 ORDER BY code')->fetchAll();
$daily = db()->query("SELECT DATE(entry_date) AS day, SUM(total_debit) AS debit FROM journal_entries WHERE status='posted' AND entry_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY) GROUP BY DATE(entry_date) ORDER BY day")->fetchAll();
$labels = []; $values = [];
for ($offset=6; $offset>=0; $offset--) {
    $day = date('Y-m-d', strtotime('-' . $offset . ' days'));
    $labels[] = $day;
    $values[] = 0;
    foreach ($daily as $row) if ($row['day'] === $day) $values[count($values)-1] = (float) $row['debit'];
}
$pageTitle = 'التقارير المالية';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>التقارير المالية</h1><p>ملخص الأرصدة وميزان المراجعة</p></div><div class="btn-group"><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/journal.php')) ?>">القيود اليومية</a><a class="btn btn-primary" href="<?= Security::e(pageUrl('admin/export.php?type=accounting')) ?>">تنزيل Excel للمحاسبة</a></div></div>
<section class="grid-stats"><article class="stat-card"><div class="stat-top"><span>الأصول</span><span class="stat-icon"><?= icon('wallet') ?></span></div><div class="stat-value" style="font-size:20px"><?= Security::e(money($balances['asset'])) ?></div></article><article class="stat-card"><div class="stat-top"><span>الالتزامات</span><span class="stat-icon"><?= icon('book') ?></span></div><div class="stat-value" style="font-size:20px"><?= Security::e(money($balances['liability'])) ?></div></article><article class="stat-card"><div class="stat-top"><span>الإيرادات</span><span class="stat-icon"><?= icon('chart') ?></span></div><div class="stat-value" style="font-size:20px"><?= Security::e(money($balances['revenue'])) ?></div></article><article class="stat-card"><div class="stat-top"><span>المصروفات</span><span class="stat-icon"><?= icon('box') ?></span></div><div class="stat-value" style="font-size:20px"><?= Security::e(money($balances['expense'])) ?></div></article></section>
<section class="grid-2" style="margin-bottom:18px"><div class="panel"><h2 class="panel-title">صافي الربح</h2><div class="stat-value" style="font-size:30px;color:<?= $balances['revenue']-$balances['expense'] >= 0 ? 'var(--green)' : 'var(--red)' ?>"><?= Security::e(money($balances['revenue']-$balances['expense'])) ?></div><div class="stat-sub">الإيرادات ناقص المصروفات</div></div><div class="panel"><h2 class="panel-title">الحركة اليومية للقيود</h2><canvas id="journalChart" height="115" aria-label="الحركة اليومية للقيود"></canvas></div></section>
<div class="table-panel"><div class="table-toolbar"><h2>ميزان المراجعة</h2><span class="pill info"><?= count($trial) ?> حساباً</span></div><div class="table-wrapper table-cards"><table><thead><tr><th>الرمز</th><th>الحساب</th><th>التصنيف</th><th>الرصيد</th></tr></thead><tbody><?php foreach ($trial as $account): ?><tr><td data-label="الرمز"><?= Security::e($account['code']) ?></td><td data-label="الحساب"><?= Security::e($account['name']) ?></td><td data-label="التصنيف"><?= Security::e(['asset'=>'أصول','liability'=>'التزامات','equity'=>'حقوق ملكية','revenue'=>'إيرادات','expense'=>'مصروفات'][$account['type']] ?? $account['type']) ?></td><td data-label="الرصيد"><?= Security::e(money($account['balance'])) ?></td></tr><?php endforeach; ?></tbody></table></div></div></div></main>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script><script>new Chart(document.getElementById('journalChart'),{type:'bar',data:{labels:<?= json_encode($labels) ?>,datasets:[{label:'مدين القيود',data:<?= json_encode($values) ?>,backgroundColor:'#078da5',borderRadius:4}]},options:{responsive:true,plugins:{legend:{display:false}},scales:{y:{beginAtZero:true},x:{grid:{display:false}}}}});</script><?php require __DIR__ . '/../footer.php'; ?>