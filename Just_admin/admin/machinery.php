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
    $statement = db()->prepare('SELECT * FROM machinery WHERE id = ?');
    $statement->execute([$editId]);
    $editing = $statement->fetch() ?: null;
}
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    $id = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT) ?: 0;
    $operation = Security::clean($_POST['op'] ?? '', 20);
    if ($operation === 'delete' && $id) {
        db()->prepare("UPDATE machinery SET status = 'out_of_service' WHERE id = ?")->execute([$id]);
        audit('machinery_retired', 'machinery', $id);
        redirect('admin/machinery.php?msg=saved');
    }
    if ($operation === 'save') {
        $code = Security::clean($_POST['code'] ?? '', 50);
        $name = Security::clean($_POST['name'] ?? '', 200);
        if ($code === '' || $name === '') {
            redirect('admin/machinery.php?msg=invalid');
        }
        $data = [$code, $name, Security::clean($_POST['plate_number'] ?? '', 50), Security::clean($_POST['operator_name'] ?? '', 150), Security::clean($_POST['status'] ?? 'available', 30), max(0, (float) ($_POST['hourly_cost'] ?? 0)), Security::clean($_POST['notes'] ?? '', 5000)];
        if ($id) {
            db()->prepare('UPDATE machinery SET code=?, name=?, plate_number=?, operator_name=?, status=?, hourly_cost=?, notes=? WHERE id=?')->execute(array_merge($data, [$id]));
            audit('machinery_updated', 'machinery', $id);
        } else {
            db()->prepare('INSERT INTO machinery (code, name, plate_number, operator_name, status, hourly_cost, notes) VALUES (?, ?, ?, ?, ?, ?, ?)')->execute($data);
            audit('machinery_created', 'machinery', (int) db()->lastInsertId());
        }
        redirect('admin/machinery.php?msg=saved');
    }
}
$items = db()->query('SELECT * FROM machinery ORDER BY created_at DESC')->fetchAll();
$pageTitle = 'إدارة الآليات';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>الآليات والمعدات</h1><p>سجل الأصول وحالتها التشغيلية</p></div><a class="btn btn-primary" href="<?= Security::e(pageUrl('admin/machinery.php?action=new')) ?>"><?= icon('plus') ?>إضافة آلية</a></div>
<?php if (isset($_GET['action']) || $editing): ?><section class="panel" style="margin-bottom:18px"><h2 class="panel-title"><?= $editing ? 'تعديل بيانات الآلية' : 'إضافة آلية' ?></h2><form method="post" class="form-grid"><?= Security::csrfField() ?><input type="hidden" name="op" value="save"><input type="hidden" name="id" value="<?= (int) ($editing['id'] ?? 0) ?>"><div class="field"><label>الكود *</label><input name="code" required maxlength="50" value="<?= Security::e($editing['code'] ?? '') ?>"></div><div class="field"><label>اسم الآلية *</label><input name="name" required maxlength="200" value="<?= Security::e($editing['name'] ?? '') ?>"></div><div class="field"><label>رقم اللوحة</label><input name="plate_number" maxlength="50" value="<?= Security::e($editing['plate_number'] ?? '') ?>"></div><div class="field"><label>اسم المشغل</label><input name="operator_name" maxlength="150" value="<?= Security::e($editing['operator_name'] ?? '') ?>"></div><div class="field"><label>الحالة</label><select name="status"><?php foreach (['available','in_use','maintenance','out_of_service'] as $status): ?><option value="<?= $status ?>" <?= ($editing['status'] ?? 'available') === $status ? 'selected' : '' ?>><?= Security::e(statusLabel($status)) ?></option><?php endforeach; ?></select></div><div class="field"><label>كلفة الساعة</label><input name="hourly_cost" type="number" min="0" step="0.01" value="<?= Security::e($editing['hourly_cost'] ?? '0') ?>"></div><div class="field full"><label>ملاحظات</label><textarea name="notes"><?= Security::e($editing['notes'] ?? '') ?></textarea></div><div class="field full btn-group"><button class="btn btn-primary">حفظ</button><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/machinery.php')) ?>">إلغاء</a></div></form></section><?php endif; ?>
<div class="table-panel"><div class="table-wrapper table-cards"><table><thead><tr><th>الكود</th><th>الآلية</th><th>اللوحة</th><th>المشغل</th><th>الحالة</th><th>كلفة الساعة</th><th>الإجراء</th></tr></thead><tbody><?php foreach ($items as $item): ?><tr><td data-label="الكود"><?= Security::e($item['code']) ?></td><td data-label="الآلية"><?= Security::e($item['name']) ?></td><td data-label="اللوحة"><?= Security::e($item['plate_number']) ?></td><td data-label="المشغل"><?= Security::e($item['operator_name']) ?></td><td data-label="الحالة"><span class="pill <?= $item['status'] === 'available' ? 'success' : '' ?>"><?= Security::e(statusLabel((string) $item['status'])) ?></span></td><td data-label="كلفة الساعة"><?= Security::e(money($item['hourly_cost'])) ?></td><td data-label="الإجراء"><div class="btn-group"><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/machinery.php?edit=' . (int) $item['id'])) ?>">تعديل</a><form method="post"><?= Security::csrfField() ?><input type="hidden" name="op" value="delete"><input type="hidden" name="id" value="<?= (int) $item['id'] ?>"><button class="btn btn-danger btn-sm" type="submit" data-confirm="تعطيل هذه الآلية؟">تعطيل</button></form></div></td></tr><?php endforeach; ?><?php if ($items === []): ?><tr><td colspan="7" class="empty-state">لا توجد آليات مسجلة</td></tr><?php endif; ?></tbody></table></div></div></div></main><?php require __DIR__ . '/../footer.php'; ?>