<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';
Auth::requireRole('admin');
$planId = filter_input(INPUT_GET, 'plan', FILTER_VALIDATE_INT) ?: 0;
$sql = 'SELECT x.*, p.title, s.name AS site_name, u.full_name FROM work_plan_updates x JOIN work_plans p ON p.id=x.work_plan_id JOIN sites s ON s.id=p.site_id JOIN users u ON u.id=x.engineer_id';
$updates = [];
if ($planId) {
    $statement = db()->prepare($sql . ' WHERE x.work_plan_id = ? ORDER BY x.created_at DESC');
    $statement->execute([$planId]);
    $updates = $statement->fetchAll();
} else {
    $updates = db()->query($sql . ' ORDER BY x.created_at DESC LIMIT 150')->fetchAll();
}
$pageTitle = 'تحديثات المهندسين';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>تحديثات المهندسين</h1><p>سجل تغييرات التقدم والحالة وملاحظات التنفيذ</p></div><span class="pill info"><?= count($updates) ?> تحديث</span></div><div class="table-panel"><div class="table-wrapper table-cards"><table><thead><tr><th>المهندس</th><th>المهمة والموقع</th><th>التقدم</th><th>الحالة</th><th>الملاحظة</th><th>التاريخ</th></tr></thead><tbody><?php foreach ($updates as $update): ?><tr><td data-label="المهندس"><?= Security::e($update['full_name']) ?></td><td data-label="المهمة والموقع"><?= Security::e($update['title']) ?><small style="display:block;color:var(--muted)"><?= Security::e($update['site_name']) ?></small></td><td data-label="التقدم"><?= Security::e($update['old_progress'] === null ? '—' : (string) $update['old_progress'] . '%') ?> ← <?= Security::e($update['new_progress'] === null ? '—' : (string) $update['new_progress'] . '%') ?></td><td data-label="الحالة"><?= Security::e(statusLabel((string) ($update['old_status'] ?? ''))) ?> ← <?= Security::e(statusLabel((string) ($update['new_status'] ?? ''))) ?></td><td data-label="الملاحظة"><?= Security::e($update['note']) ?></td><td data-label="التاريخ"><?= Security::e($update['created_at']) ?></td></tr><?php endforeach; ?><?php if ($updates === []): ?><tr><td colspan="6" class="empty-state">لا توجد تحديثات مسجلة</td></tr><?php endif; ?></tbody></table></div></div></div></main><?php require __DIR__ . '/../footer.php'; ?>