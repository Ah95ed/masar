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
    $statement = db()->prepare('SELECT * FROM warehouse_items WHERE id=?');
    $statement->execute([$editId]);
    $editing = $statement->fetch() ?: null;
}
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    $operation = Security::clean($_POST['op'] ?? '', 20);
    if ($operation === 'category') {
        $categoryId = filter_var($_POST['category_id'] ?? null, FILTER_VALIDATE_INT) ?: 0;
        if (($_POST['category_action'] ?? '') === 'delete' && $categoryId) {
            db()->prepare('DELETE FROM warehouse_categories WHERE id=?')->execute([$categoryId]);
            audit('warehouse_category_deleted', 'warehouse_category', $categoryId);
        } else {
            $categoryName = Security::clean($_POST['category_name'] ?? '', 100);
            if ($categoryName !== '' && $categoryId) {
                db()->prepare('UPDATE warehouse_categories SET name=?,description=? WHERE id=?')->execute([$categoryName, Security::clean($_POST['category_description'] ?? '', 500), $categoryId]);
                audit('warehouse_category_updated', 'warehouse_category', $categoryId);
            } elseif ($categoryName !== '') {
                db()->prepare('INSERT INTO warehouse_categories (name, description) VALUES (?, ?)')->execute([$categoryName, Security::clean($_POST['category_description'] ?? '', 500)]);
                audit('warehouse_category_created', 'warehouse_category', (int) db()->lastInsertId());
            }
        }
        redirect('admin/warehouse_items.php?msg=category');
    }
    $id = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT) ?: 0;
    if ($operation === 'disable' && $id) {
        db()->prepare('UPDATE warehouse_items SET is_active=0 WHERE id=?')->execute([$id]);
        audit('warehouse_item_disabled', 'warehouse_item', $id);
        redirect('admin/warehouse_items.php?msg=saved');
    }
    if ($operation === 'save') {
        $code = Security::clean($_POST['code'] ?? '', 50);
        $name = Security::clean($_POST['name'] ?? '', 200);
        if ($code === '' || $name === '') redirect('admin/warehouse_items.php?msg=invalid');
        $data = [$code, $name, filter_var($_POST['category_id'] ?? null, FILTER_VALIDATE_INT) ?: null, Security::clean($_POST['unit'] ?? 'قطعة', 30), max(0, (float) ($_POST['quantity'] ?? 0)), max(0, (float) ($_POST['min_quantity'] ?? 0)), max(0, (float) ($_POST['unit_price'] ?? 0)), Security::clean($_POST['location'] ?? '', 100), Security::clean($_POST['notes'] ?? '', 5000)];
        if ($id) {
            db()->prepare('UPDATE warehouse_items SET code=?,name=?,category_id=?,unit=?,quantity=?,min_quantity=?,unit_price=?,location=?,notes=? WHERE id=?')->execute(array_merge($data, [$id]));
            audit('warehouse_item_updated', 'warehouse_item', $id);
        } else {
            db()->prepare('INSERT INTO warehouse_items (code,name,category_id,unit,quantity,min_quantity,unit_price,location,notes) VALUES (?,?,?,?,?,?,?,?,?)')->execute($data);
            audit('warehouse_item_created', 'warehouse_item', (int) db()->lastInsertId());
        }
        redirect('admin/warehouse_items.php?msg=saved');
    }
}
$categories = db()->query('SELECT id,name FROM warehouse_categories ORDER BY name')->fetchAll();
$editCategoryId = filter_input(INPUT_GET, 'edit_category', FILTER_VALIDATE_INT) ?: 0;
$editingCategory = null;
if ($editCategoryId) {
    $categoryQuery = db()->prepare('SELECT * FROM warehouse_categories WHERE id=?');
    $categoryQuery->execute([$editCategoryId]);
    $editingCategory = $categoryQuery->fetch() ?: null;
}
$filterLow = ($_GET['filter'] ?? '') === 'low';
$items = db()->query('SELECT i.*, c.name AS category_name FROM warehouse_items i LEFT JOIN warehouse_categories c ON c.id=i.category_id WHERE i.is_active=1' . ($filterLow ? ' AND i.quantity<=i.min_quantity' : '') . ' ORDER BY i.name')->fetchAll();
$pageTitle = 'مواد المخزن';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>مواد المخزن</h1><p>إدارة الأصناف والكميات وحدود إعادة الطلب</p></div><a class="btn btn-primary" href="<?= Security::e(pageUrl('admin/warehouse_items.php?action=new')) ?>"><?= icon('plus') ?>مادة جديدة</a></div>
<section class="grid-2" style="margin-bottom:18px"><div class="panel"><h2 class="panel-title"><?= $editingCategory ? 'تعديل فئة' : 'إضافة فئة' ?></h2><form method="post" class="form-grid"><?= Security::csrfField() ?><input type="hidden" name="op" value="category"><input type="hidden" name="category_id" value="<?= (int) ($editingCategory['id'] ?? 0) ?>"><div class="field"><label>اسم الفئة</label><input name="category_name" required maxlength="100" value="<?= Security::e($editingCategory['name'] ?? '') ?>"></div><div class="field"><label>وصف الفئة</label><input name="category_description" maxlength="500" value="<?= Security::e($editingCategory['description'] ?? '') ?>"></div><div class="field full btn-group"><button class="btn btn-quiet"><?= $editingCategory ? 'حفظ التعديل' : 'إضافة فئة' ?></button><?php if ($editingCategory): ?><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/warehouse_items.php')) ?>">إلغاء</a><?php endif; ?></div></form></div><div class="panel"><h2 class="panel-title">الفئات المسجلة</h2><div class="grid gap-2"><?php foreach ($categories as $category): ?><div class="list-row"><span><?= Security::e($category['name']) ?></span><div class="btn-group"><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/warehouse_items.php?edit_category=' . (int) $category['id'])) ?>">تعديل</a><form method="post"><?= Security::csrfField() ?><input type="hidden" name="op" value="category"><input type="hidden" name="category_action" value="delete"><input type="hidden" name="category_id" value="<?= (int) $category['id'] ?>"><button class="btn btn-danger btn-sm" data-confirm="حذف الفئة؟ ستبقى المواد دون فئة." type="submit">حذف</button></form></div></div><?php endforeach; ?><?php if ($categories === []): ?><span class="empty-state">لا توجد فئات</span><?php endif; ?></div></div></section>
<?php if (isset($_GET['action']) || $editing): ?><section class="panel" style="margin-bottom:18px"><h2 class="panel-title"><?= $editing ? 'تعديل المادة' : 'إضافة مادة' ?></h2><form method="post" class="form-grid"><?= Security::csrfField() ?><input type="hidden" name="op" value="save"><input type="hidden" name="id" value="<?= (int) ($editing['id'] ?? 0) ?>"><div class="field"><label>الكود</label><input name="code" required maxlength="50" value="<?= Security::e($editing['code'] ?? '') ?>"></div><div class="field"><label>الاسم</label><input name="name" required maxlength="200" value="<?= Security::e($editing['name'] ?? '') ?>"></div><div class="field"><label>الفئة</label><select name="category_id"><option value="">بدون فئة</option><?php foreach ($categories as $category): ?><option value="<?= (int) $category['id'] ?>" <?= (int) ($editing['category_id'] ?? 0) === (int) $category['id'] ? 'selected' : '' ?>><?= Security::e($category['name']) ?></option><?php endforeach; ?></select></div><div class="field"><label>الوحدة</label><input name="unit" maxlength="30" value="<?= Security::e($editing['unit'] ?? 'قطعة') ?>"></div><div class="field"><label>الكمية المتاحة</label><input name="quantity" type="number" min="0" step="0.001" value="<?= Security::e($editing['quantity'] ?? '0') ?>"></div><div class="field"><label>الحد الأدنى</label><input name="min_quantity" type="number" min="0" step="0.001" value="<?= Security::e($editing['min_quantity'] ?? '0') ?>"></div><div class="field"><label>سعر الوحدة</label><input name="unit_price" type="number" min="0" step="0.01" value="<?= Security::e($editing['unit_price'] ?? '0') ?>"></div><div class="field"><label>مكان التخزين</label><input name="location" maxlength="100" value="<?= Security::e($editing['location'] ?? '') ?>"></div><div class="field full"><label>ملاحظات</label><textarea name="notes"><?= Security::e($editing['notes'] ?? '') ?></textarea></div><div class="field full btn-group"><button class="btn btn-primary">حفظ المادة</button><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/warehouse_items.php')) ?>">إلغاء</a></div></form></section><?php endif; ?>
<div class="table-panel"><div class="table-toolbar"><h2>قائمة المواد</h2><?php if ($filterLow): ?><a href="<?= Security::e(pageUrl('admin/warehouse_items.php')) ?>">عرض الكل</a><?php endif; ?></div><div class="table-wrapper table-cards"><table><thead><tr><th>الكود والمادة</th><th>الفئة</th><th>الكمية</th><th>الحد الأدنى</th><th>سعر الوحدة</th><th>الإجمالي</th><th>الإجراء</th></tr></thead><tbody><?php foreach ($items as $item): ?><tr><td data-label="الكود والمادة"><?= Security::e($item['code']) ?> · <?= Security::e($item['name']) ?></td><td data-label="الفئة"><?= Security::e($item['category_name'] ?? '—') ?></td><td data-label="الكمية"><span class="pill <?= (float) $item['quantity'] <= (float) $item['min_quantity'] ? 'warning' : 'success' ?>"><?= Security::e($item['quantity'] . ' ' . $item['unit']) ?></span></td><td data-label="الحد الأدنى"><?= Security::e($item['min_quantity']) ?></td><td data-label="سعر الوحدة"><?= Security::e(money($item['unit_price'])) ?></td><td data-label="الإجمالي"><?= Security::e(money((float) $item['quantity'] * (float) $item['unit_price'])) ?></td><td data-label="الإجراء"><div class="btn-group"><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/warehouse_items.php?edit=' . (int) $item['id'])) ?>">تعديل</a><form method="post"><?= Security::csrfField() ?><input type="hidden" name="op" value="disable"><input type="hidden" name="id" value="<?= (int) $item['id'] ?>"><button class="btn btn-danger btn-sm" data-confirm="إيقاف هذه المادة؟">إيقاف</button></form></div></td></tr><?php endforeach; ?><?php if ($items === []): ?><tr><td colspan="7" class="empty-state">لا توجد مواد</td></tr><?php endif; ?></tbody></table></div></div></div></main><?php require __DIR__ . '/../footer.php'; ?>