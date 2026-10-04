<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';
Auth::requireRole('admin');
$editing = null;
$editId = filter_input(INPUT_GET, 'edit', FILTER_VALIDATE_INT) ?: 0;
if ($editId) {
    $statement = db()->prepare('SELECT * FROM work_plans WHERE id = ?');
    $statement->execute([$editId]);
    $editing = $statement->fetch() ?: null;
}
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    $id = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT) ?: 0;
    $operation = Security::clean($_POST['op'] ?? '', 20);
    if ($operation === 'delete' && $id) {
        db()->prepare("UPDATE work_plans SET status = 'cancelled' WHERE id = ?")->execute([$id]);
        audit('work_plan_cancelled', 'work_plan', $id);
        redirect('admin/work_plans.php?msg=saved');
    }
    if ($operation === 'save') {
        $siteId = filter_var($_POST['site_id'] ?? null, FILTER_VALIDATE_INT);
        $title = Security::clean($_POST['title'] ?? '', 255);
        $broadcast = isset($_POST['is_broadcast']) ? 1 : 0;
        $assigned = $broadcast ? null : (filter_var($_POST['assigned_to'] ?? null, FILTER_VALIDATE_INT) ?: null);
        $priority = Security::clean($_POST['priority'] ?? 'medium', 10);
        if (!$siteId || $title === '' || !in_array($priority, ['low', 'medium', 'high', 'urgent'], true)) {
            redirect('admin/work_plans.php?msg=invalid');
        }
        $description = Security::clean($_POST['description'] ?? '', 5000);
        if ($id) {
            db()->prepare('UPDATE work_plans SET site_id=?, title=?, description=?, assigned_to=?, is_broadcast=?, priority=? WHERE id=?')->execute([$siteId, $title, $description, $assigned, $broadcast, $priority, $id]);
            audit('work_plan_updated', 'work_plan', $id);
        } else {
            db()->prepare("INSERT INTO work_plans (site_id, title, description, assigned_to, is_broadcast, priority, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)")->execute([$siteId, $title, $description, $assigned, $broadcast, $priority, Auth::id()]);
            $id = (int) db()->lastInsertId();
            audit('work_plan_created', 'work_plan', $id);
        }
        if ($broadcast) {
            $engineers = db()->query("SELECT id FROM users WHERE role='engineer' AND is_active=1 AND approval_status='approved'")->fetchAll();
            foreach ($engineers as $engineer) {
                notify((int) $engineer['id'], 'خطة عمل جديدة', $title, 'info', 'engineer/tasks.php');
            }
        } elseif ($assigned) {
            notify($assigned, 'خطة عمل جديدة', $title, 'info', 'engineer/tasks.php');
        }
        redirect('admin/work_plans.php?msg=saved');
    }
}
$sites = db()->query("SELECT id, name FROM sites WHERE status NOT IN ('completed','cancelled') ORDER BY name")->fetchAll();
$engineers = db()->query("SELECT id, full_name FROM users WHERE role='engineer' AND is_active=1 AND approval_status='approved' ORDER BY full_name")->fetchAll();
$plans = db()->query('SELECT p.*, s.name AS site_name, u.full_name FROM work_plans p JOIN sites s ON s.id=p.site_id LEFT JOIN users u ON u.id=p.assigned_to ORDER BY p.updated_at DESC')->fetchAll();
$pageTitle = 'خطط العمل';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>خطط العمل</h1><p>توزيع المهام ومتابعة الأولويات والتقدم</p></div><a class="btn btn-primary" href="<?= Security::e(pageUrl('admin/work_plans.php?action=new')) ?>"><?= icon('plus') ?>خطة جديدة</a></div>
<?php if (isset($_GET['action']) || $editing): ?><section class="panel" style="margin-bottom:18px"><h2 class="panel-title"><?= $editing ? 'تعديل الخطة' : 'إنشاء خطة عمل' ?></h2><form method="post" class="form-grid"><?= Security::csrfField() ?><input type="hidden" name="op" value="save"><input type="hidden" name="id" value="<?= (int) ($editing['id'] ?? 0) ?>"><div class="field"><label>الموقع *</label><select name="site_id" required><?php foreach ($sites as $site): ?><option value="<?= (int) $site['id'] ?>" <?= (int) ($editing['site_id'] ?? 0) === (int) $site['id'] ? 'selected' : '' ?>><?= Security::e($site['name']) ?></option><?php endforeach; ?></select></div><div class="field"><label>عنوان المهمة *</label><input name="title" required maxlength="255" value="<?= Security::e($editing['title'] ?? '') ?>"></div><div class="field"><label>المهندس</label><select name="assigned_to"><option value="">غير معين</option><?php foreach ($engineers as $engineer): ?><option value="<?= (int) $engineer['id'] ?>" <?= (int) ($editing['assigned_to'] ?? 0) === (int) $engineer['id'] ? 'selected' : '' ?>><?= Security::e($engineer['full_name']) ?></option><?php endforeach; ?></select></div><div class="field"><label>الأولوية</label><select name="priority"><?php foreach (['low','medium','high','urgent'] as $priority): ?><option value="<?= $priority ?>" <?= ($editing['priority'] ?? 'medium') === $priority ? 'selected' : '' ?>><?= Security::e(statusLabel($priority)) ?></option><?php endforeach; ?></select></div><div class="field full"><label style="display:flex;align-items:center;gap:8px"><input style="width:auto" type="checkbox" name="is_broadcast" value="1" <?= !empty($editing['is_broadcast']) ? 'checked' : '' ?>> تعميم المهمة على جميع المهندسين</label></div><div class="field full"><label>التفاصيل</label><textarea name="description"><?= Security::e($editing['description'] ?? '') ?></textarea></div><div class="field full btn-group"><button class="btn btn-primary">حفظ الخطة</button><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/work_plans.php')) ?>">إلغاء</a></div></form></section><?php endif; ?>
<div class="table-panel"><div class="table-wrapper table-cards"><table><thead><tr><th>المهمة</th><th>الموقع</th><th>المهندس</th><th>الأولوية</th><th>الحالة</th><th>التقدم</th><th>الإجراء</th></tr></thead><tbody><?php foreach ($plans as $plan): ?><tr><td data-label="المهمة"><strong><?= Security::e($plan['title']) ?></strong><small style="display:block;color:var(--muted)"><?= Security::e($plan['is_broadcast'] ? 'تعميم' : '') ?></small></td><td data-label="الموقع"><?= Security::e($plan['site_name']) ?></td><td data-label="المهندس"><?= Security::e($plan['full_name'] ?: 'غير معين') ?></td><td data-label="الأولوية"><span class="pill <?= $plan['priority'] === 'urgent' || $plan['priority'] === 'high' ? 'warning' : '' ?>"><?= Security::e(statusLabel((string) $plan['priority'])) ?></span></td><td data-label="الحالة"><?= Security::e(statusLabel((string) $plan['status'])) ?></td><td data-label="التقدم"><div class="flex items-center gap-2"><span><?= (int) $plan['progress'] ?>%</span><span class="progress"><span style="width:<?= min(100, (int) $plan['progress']) ?>%"></span></span></div></td><td data-label="الإجراء"><div class="btn-group"><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/work_plans.php?edit=' . (int) $plan['id'])) ?>">تعديل</a><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/work_updates.php?plan=' . (int) $plan['id'])) ?>">السجل</a><form method="post"><?= Security::csrfField() ?><input type="hidden" name="op" value="delete"><input type="hidden" name="id" value="<?= (int) $plan['id'] ?>"><button class="btn btn-danger btn-sm" data-confirm="إلغاء هذه الخطة؟">إلغاء</button></form></div></td></tr><?php endforeach; ?><?php if ($plans === []): ?><tr><td colspan="7" class="empty-state">لا توجد خطط عمل</td></tr><?php endif; ?></tbody></table></div></div></div></main><?php require __DIR__ . '/../footer.php'; ?>