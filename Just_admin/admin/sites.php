<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';
Auth::requireRole('admin');
$editId = filter_input(INPUT_GET, 'edit', FILTER_VALIDATE_INT) ?: 0;
$editing = null;
if ($editId) {
    $statement = db()->prepare('SELECT * FROM sites WHERE id = ?');
    $statement->execute([$editId]);
    $editing = $statement->fetch() ?: null;
}
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    $operation = Security::clean($_POST['op'] ?? '', 20);
    $id = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT) ?: 0;
    if ($operation === 'delete' && $id) {
        db()->prepare('DELETE FROM sites WHERE id = ?')->execute([$id]);
        audit('site_deleted', 'site', $id);
        redirect('admin/sites.php?msg=deleted');
    }
    if ($operation === 'save') {
        $name = Security::clean($_POST['name'] ?? '', 200);
        if ($name === '') {
            redirect('admin/sites.php?msg=invalid');
        }
        $data = [$name, Security::clean($_POST['client_name'] ?? '', 200), $_POST['work_date'] ?: null, $_POST['start_time'] ?: null, $_POST['end_time'] ?: null, Security::clean($_POST['location'] ?? '', 255), max(0, (float) ($_POST['budget'] ?? 0)), Security::clean($_POST['status'] ?? 'active', 20), filter_var($_POST['manager_id'] ?? null, FILTER_VALIDATE_INT) ?: null, Security::clean($_POST['description'] ?? '', 5000)];
        if ($id) {
            db()->prepare('UPDATE sites SET name=?, client_name=?, work_date=?, start_time=?, end_time=?, location=?, budget=?, status=?, manager_id=?, description=? WHERE id=?')->execute(array_merge($data, [$id]));
            audit('site_updated', 'site', $id);
        } else {
            $codeQuery = db()->prepare("SELECT COALESCE(MAX(CAST(SUBSTRING_INDEX(code, '-', -1) AS UNSIGNED)), 0) FROM sites WHERE code LIKE ?");
            $codeQuery->execute(['SP-' . date('Ymd') . '-%']);
            $nextCode = (int) $codeQuery->fetchColumn() + 1;
            $code = 'SP-' . date('Ymd') . '-' . str_pad((string) $nextCode, 3, '0', STR_PAD_LEFT);
            db()->prepare('INSERT INTO sites (code, name, client_name, work_date, start_time, end_time, location, budget, status, manager_id, description, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')->execute(array_merge([$code], $data, [Auth::id()]));
            audit('site_created', 'site', (int) db()->lastInsertId());
        }
        redirect('admin/sites.php?msg=saved');
    }
}
$engineers = db()->query("SELECT id, full_name FROM users WHERE role = 'engineer' AND is_active = 1 AND approval_status = 'approved' ORDER BY full_name")->fetchAll();
$sites = db()->query('SELECT s.*, u.full_name AS manager_name FROM sites s LEFT JOIN users u ON u.id=s.manager_id ORDER BY s.created_at DESC')->fetchAll();
$pageTitle = 'إدارة المواقع';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>المواقع والمشاريع</h1><p>إدارة بيانات مواقع العمل والمهندسين المسؤولين</p></div><a class="btn btn-primary" href="<?= Security::e(pageUrl('admin/sites.php?action=new')) ?>"><?= icon('plus') ?>موقع جديد</a></div>
<?php if (isset($_GET['action']) || $editing): ?><section class="panel" style="margin-bottom:20px"><h2 class="panel-title"><?= $editing ? 'تعديل الموقع' : 'إنشاء موقع' ?></h2><form method="post" class="form-grid"><?= Security::csrfField() ?><input type="hidden" name="op" value="save"><input type="hidden" name="id" value="<?= (int) ($editing['id'] ?? 0) ?>"><div class="field"><label>اسم الموقع *</label><input name="name" required maxlength="200" value="<?= Security::e($editing['name'] ?? '') ?>"></div><div class="field"><label>اسم العميل</label><input name="client_name" maxlength="200" value="<?= Security::e($editing['client_name'] ?? '') ?>"></div><div class="field"><label>تاريخ العمل</label><input type="date" name="work_date" value="<?= Security::e($editing['work_date'] ?? '') ?>"></div><div class="field"><label>المهندس المسؤول</label><select name="manager_id"><option value="">غير معين</option><?php foreach ($engineers as $engineer): ?><option value="<?= (int) $engineer['id'] ?>" <?= (int) ($editing['manager_id'] ?? 0) === (int) $engineer['id'] ? 'selected' : '' ?>><?= Security::e($engineer['full_name']) ?></option><?php endforeach; ?></select></div><div class="field"><label>وقت البدء</label><input type="time" name="start_time" value="<?= Security::e($editing['start_time'] ?? '') ?>"></div><div class="field"><label>وقت الانتهاء</label><input type="time" name="end_time" value="<?= Security::e($editing['end_time'] ?? '') ?>"></div><div class="field"><label>الموقع الجغرافي</label><input name="location" maxlength="255" value="<?= Security::e($editing['location'] ?? '') ?>"></div><div class="field"><label>الميزانية</label><input name="budget" type="number" min="0" step="0.01" value="<?= Security::e($editing['budget'] ?? '0') ?>"></div><div class="field"><label>الحالة</label><select name="status"><?php foreach (['planning','active','paused','completed','cancelled'] as $status): ?><option value="<?= $status ?>" <?= ($editing['status'] ?? 'active') === $status ? 'selected' : '' ?>><?= Security::e(statusLabel($status)) ?></option><?php endforeach; ?></select></div><div class="field full"><label>وصف المشروع</label><textarea name="description" maxlength="5000"><?= Security::e($editing['description'] ?? '') ?></textarea></div><div class="field full btn-group"><button class="btn btn-primary" type="submit">حفظ الموقع</button><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/sites.php')) ?>">إلغاء</a></div></form></section><?php endif; ?>
<section class="grid-3"><?php foreach ($sites as $site): ?><article class="panel"><div class="flex items-start justify-between gap-3"><div><span class="pill info"><?= Security::e($site['code']) ?></span><h2 class="panel-title" style="margin:10px 0 4px"><?= Security::e($site['name']) ?></h2></div><span class="pill <?= $site['status'] === 'active' ? 'success' : '' ?>"><?= Security::e(statusLabel((string) $site['status'])) ?></span></div><p style="margin:4px 0;color:var(--muted);font-size:13px">العميل: <?= Security::e($site['client_name'] ?: 'غير محدد') ?></p><p style="margin:4px 0;color:var(--muted);font-size:13px">المهندس: <?= Security::e($site['manager_name'] ?: 'غير معين') ?></p><p style="margin:4px 0 15px;color:var(--muted);font-size:12px"><?= Security::e($site['location']) ?></p><div class="btn-group"><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/sites.php?edit=' . (int) $site['id'])) ?>">تعديل</a><form method="post" class="no-print"><?= Security::csrfField() ?><input type="hidden" name="op" value="delete"><input type="hidden" name="id" value="<?= (int) $site['id'] ?>"><button class="btn btn-danger btn-sm" data-confirm="حذف الموقع؟ سيتم حذف الخطط والتقارير المرتبطة به." type="submit">حذف</button></form></div></article><?php endforeach; ?><?php if ($sites === []): ?><div class="panel empty-state">لم تتم إضافة مواقع بعد</div><?php endif; ?></section></div></main><?php require __DIR__ . '/../footer.php'; ?>