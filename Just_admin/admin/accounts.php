<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';
Auth::requireRole('admin','accountant');
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    $operation = Security::clean($_POST['op'] ?? 'save', 20);
    $id = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT) ?: 0;
    if ($operation === 'delete' && $id) {
        $usage = db()->prepare('SELECT COUNT(*) FROM journal_entry_lines WHERE account_id=?');
        $usage->execute([$id]);
        $accountQuery = db()->prepare('SELECT code,balance FROM accounts WHERE id=?');
        $accountQuery->execute([$id]);
        $account = $accountQuery->fetch();
        if (!$account) redirect('admin/accounts.php?msg=account_missing');
        if ((int) $usage->fetchColumn() > 0 || abs((float) $account['balance']) > 0.005) {
            redirect('admin/accounts.php?msg=account_in_use');
        }
        db()->prepare('DELETE FROM accounts WHERE id=?')->execute([$id]);
        audit('account_deleted', 'account', $id, 'code=' . $account['code']);
        redirect('admin/accounts.php?msg=account_deleted');
    }
    $code = Security::clean($_POST['code'] ?? '', 50);
    $name = Security::clean($_POST['name'] ?? '', 200);
    $type = Security::clean($_POST['type'] ?? '', 20);
    if ($code !== '' && $name !== '' && in_array($type, ['asset','liability','equity','revenue','expense'], true)) {
        if ($id) {
            $oldType = db()->prepare('SELECT type FROM accounts WHERE id=?');
            $oldType->execute([$id]);
            $currentType = $oldType->fetchColumn();
            $usage = db()->prepare('SELECT COUNT(*) FROM journal_entry_lines WHERE account_id=?');
            $usage->execute([$id]);
            if ($currentType === false) redirect('admin/accounts.php?msg=account_missing');
            if ($currentType !== $type && (int) $usage->fetchColumn() > 0) redirect('admin/accounts.php?msg=account_type_locked');
            db()->prepare('UPDATE accounts SET code=?,name=?,type=?,description=?,is_active=? WHERE id=?')->execute([$code,$name,$type,Security::clean($_POST['description'] ?? '',500),isset($_POST['is_active'])?1:0,$id]);
        }
        else db()->prepare('INSERT INTO accounts (code,name,type,description) VALUES (?,?,?,?)')->execute([$code,$name,$type,Security::clean($_POST['description'] ?? '',500)]);
        audit($id ? 'account_updated' : 'account_created', 'account', $id ?: (int) db()->lastInsertId());
    }
    redirect('admin/accounts.php?msg=saved');
}
$accounts = db()->query('SELECT * FROM accounts ORDER BY code')->fetchAll();
$editId = filter_input(INPUT_GET, 'edit', FILTER_VALIDATE_INT) ?: 0;
$editing = null;
foreach ($accounts as $account) if ((int) $account['id'] === $editId) $editing = $account;
$pageTitle = 'دليل الحسابات';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>دليل الحسابات</h1><p>تصنيف الأصول والالتزامات وحقوق الملكية والإيرادات والمصروفات</p></div><div class="btn-group"><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/financial.php')) ?>">التقارير المالية</a><a class="btn btn-primary" href="<?= Security::e(pageUrl('admin/export.php?type=accounting')) ?>">تصدير Excel للمحاسبة</a></div></div>
<section class="panel" style="margin-bottom:18px"><h2 class="panel-title"><?= $editing ? 'تعديل الحساب' : 'إضافة حساب' ?></h2><form method="post" class="form-grid"><?= Security::csrfField() ?><input type="hidden" name="id" value="<?= (int) ($editing['id'] ?? 0) ?>"><div class="field"><label>رمز الحساب</label><input name="code" required maxlength="50" value="<?= Security::e($editing['code'] ?? '') ?>"></div><div class="field"><label>اسم الحساب</label><input name="name" required maxlength="200" value="<?= Security::e($editing['name'] ?? '') ?>"></div><div class="field"><label>النوع</label><select name="type"><?php foreach (['asset'=>'أصل','liability'=>'التزام','equity'=>'حقوق ملكية','revenue'=>'إيراد','expense'=>'مصروف'] as $type=>$label): ?><option value="<?= $type ?>" <?= ($editing['type'] ?? 'asset') === $type ? 'selected' : '' ?>><?= Security::e($label) ?></option><?php endforeach; ?></select></div><div class="field"><label>الوصف</label><input name="description" maxlength="500" value="<?= Security::e($editing['description'] ?? '') ?>"></div><?php if ($editing): ?><div class="field"><label style="display:flex;align-items:center;gap:8px"><input type="checkbox" name="is_active" value="1" style="width:auto" <?= (int) $editing['is_active'] ? 'checked' : '' ?>> حساب نشط</label></div><?php endif; ?><div class="field full btn-group"><button class="btn btn-primary">حفظ الحساب</button><?php if ($editing): ?><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/accounts.php')) ?>">إلغاء</a><?php endif; ?></div></form></section>
<div class="table-panel"><div class="table-wrapper table-cards"><table><thead><tr><th>الرمز</th><th>اسم الحساب</th><th>النوع</th><th>الرصيد</th><th>الحالة</th><th>الإجراء</th></tr></thead><tbody><?php foreach ($accounts as $account): ?><tr><td data-label="الرمز"><?= Security::e($account['code']) ?></td><td data-label="اسم الحساب"><?= Security::e($account['name']) ?></td><td data-label="النوع"><?= Security::e(['asset'=>'أصل','liability'=>'التزام','equity'=>'حقوق ملكية','revenue'=>'إيراد','expense'=>'مصروف'][$account['type']] ?? $account['type']) ?></td><td data-label="الرصيد"><?= Security::e(money($account['balance'])) ?></td><td data-label="الحالة"><span class="pill <?= (int) $account['is_active'] ? 'success' : '' ?>"><?= (int) $account['is_active'] ? 'نشط' : 'موقوف' ?></span></td><td data-label="الإجراء"><div class="btn-group"><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/accounts.php?edit=' . (int) $account['id'])) ?>">تعديل</a><?php if (abs((float) $account['balance']) <= 0.005): ?><form method="post"><?= Security::csrfField() ?><input type="hidden" name="op" value="delete"><input type="hidden" name="id" value="<?= (int) $account['id'] ?>"><button class="btn btn-danger btn-sm" type="submit" data-confirm="حذف هذا الحساب نهائياً؟ لا يمكن حذف حساب مرتبط بقيود أو له رصيد.">حذف</button></form><?php endif; ?></div></td></tr><?php endforeach; ?></tbody></table></div></div></div></main><?php require __DIR__ . '/../footer.php'; ?>