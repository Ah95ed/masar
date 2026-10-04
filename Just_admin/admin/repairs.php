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
$editingParts = [];
if ($editId) {
    $editQuery = db()->prepare("SELECT r.*,m.code AS machine_code,m.name AS machine_name FROM machinery_repairs r JOIN machinery m ON m.id=r.machinery_id WHERE r.id=? AND r.status IN ('pending','in_progress','waiting_parts')");
    $editQuery->execute([$editId]);
    $editing = $editQuery->fetch() ?: null;
    if ($editing) {
        $partsQuery = db()->prepare('SELECT * FROM machinery_repair_parts WHERE repair_id=? ORDER BY id');
        $partsQuery->execute([$editId]);
        $editingParts = $partsQuery->fetchAll();
    }
}
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    $operation = Security::clean($_POST['op'] ?? '', 20);
    $id = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT) ?: 0;
    if ($operation === 'edit' && $id) {
        $title = Security::clean($_POST['title'] ?? '', 200);
        $problemType = Security::clean($_POST['problem_type'] ?? '', 20);
        $priority = Security::clean($_POST['priority'] ?? '', 10);
        if ($title === '' || !in_array($problemType, ['mechanical','electrical','body','tires','other'], true) || !in_array($priority, ['low','medium','high','urgent'], true)) redirect('admin/repairs.php?msg=invalid');
        $partNames = $_POST['part_name'] ?? [];
        $partRows = [];
        $partsCost = 0.0;
        if (is_array($partNames)) foreach ($partNames as $index => $partName) {
            $partName = Security::clean((string) $partName, 200);
            if ($partName === '') continue;
            $quantity = max(0, (float) ($_POST['part_quantity'][$index] ?? 0));
            $unitPrice = max(0, (float) ($_POST['part_price'][$index] ?? 0));
            $total = $quantity * $unitPrice;
            $partsCost += $total;
            $partRows[] = [$partName,$quantity,$unitPrice,$total];
        }
        $labor = max(0, (float) ($_POST['labor_cost'] ?? 0));
        $pdo = db();
        $pdo->beginTransaction();
        try {
            $lock = $pdo->prepare("SELECT status FROM machinery_repairs WHERE id=? FOR UPDATE");
            $lock->execute([$id]);
            if (!in_array($lock->fetchColumn(), ['pending','in_progress','waiting_parts'], true)) throw new DomainException('لا يمكن تعديل طلب مغلق');
            $entryCheck = $pdo->prepare('SELECT COUNT(*) FROM journal_entries WHERE reference=?');
            $entryCheck->execute(['repair-' . $id]);
            if ((int) $entryCheck->fetchColumn() > 0) throw new DomainException('طلب التصليح مرتبط بقيد محاسبي');
            $pdo->prepare('UPDATE machinery_repairs SET title=?,description=?,problem_type=?,priority=?,technician_name=?,workshop=?,labor_cost=?,parts_cost=?,total_cost=?,notes=? WHERE id=?')->execute([$title,Security::clean($_POST['description'] ?? '',5000),$problemType,$priority,Security::clean($_POST['technician_name'] ?? '',150),Security::clean($_POST['workshop'] ?? '',200),$labor,$partsCost,$labor+$partsCost,Security::clean($_POST['notes'] ?? '',5000),$id]);
            $pdo->prepare('DELETE FROM machinery_repair_parts WHERE repair_id=?')->execute([$id]);
            $insertPart = $pdo->prepare('INSERT INTO machinery_repair_parts (repair_id,part_name,quantity,unit_price,total) VALUES (?,?,?,?,?)');
            foreach ($partRows as $part) $insertPart->execute(array_merge([$id],$part));
            audit('repair_updated', 'machinery_repair', $id);
            $pdo->commit();
        } catch (Throwable $exception) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            if ($exception instanceof DomainException) redirect('admin/repairs.php?msg=repair_locked');
            throw $exception;
        }
        redirect('admin/repairs.php?msg=saved');
    }
    if ($operation === 'status' && $id) {
        $status = Security::clean($_POST['status'] ?? '', 30);
        if (in_array($status, ['pending', 'in_progress', 'waiting_parts', 'completed', 'cancelled'], true)) {
            db()->beginTransaction();
            try {
                db()->prepare('UPDATE machinery_repairs SET status=?, started_at=IF(?="in_progress" AND started_at IS NULL,NOW(),started_at), completed_at=IF(?="completed",NOW(),completed_at) WHERE id=?')->execute([$status, $status, $status, $id]);
                $machine = db()->prepare('SELECT machinery_id,title,total_cost FROM machinery_repairs WHERE id=?');
                $machine->execute([$id]);
                $repair = $machine->fetch();
                $machineId = (int) $repair['machinery_id'];
                if ($status === 'completed' && (float) $repair['total_cost'] > 0) {
                    $reference = 'repair-' . $id;
                    $existingEntry = db()->prepare('SELECT id FROM journal_entries WHERE reference=? LIMIT 1');
                    $existingEntry->execute([$reference]);
                    if (!$existingEntry->fetchColumn()) {
                        $account = db()->prepare('SELECT id FROM accounts WHERE code=?');
                        $account->execute(['5400']); $expenseAccount = (int) $account->fetchColumn();
                        $account->execute(['1100']); $cashAccount = (int) $account->fetchColumn();
                        if ($expenseAccount && $cashAccount) {
                            createJournalEntry('تكلفة تصليح · ' . $repair['title'], [['account_id'=>$expenseAccount,'debit'=>(float)$repair['total_cost'],'credit'=>0],['account_id'=>$cashAccount,'debit'=>0,'credit'=>(float)$repair['total_cost']]], (int) Auth::id(), null, null, $reference);
                        }
                    }
                }
                if ($status === 'completed' || $status === 'cancelled') {
                    $open = db()->prepare("SELECT COUNT(*) FROM machinery_repairs WHERE machinery_id=? AND status IN ('pending','in_progress','waiting_parts')");
                    $open->execute([$machineId]);
                    $next = (int) $open->fetchColumn() > 0 ? 'maintenance' : 'available';
                } else {
                    $next = 'maintenance';
                }
                db()->prepare('UPDATE machinery SET status=? WHERE id=?')->execute([$next, $machineId]);
                db()->commit();
            } catch (Throwable $exception) {
                db()->rollBack();
                throw $exception;
            }
        }
        redirect('admin/repairs.php?msg=saved');
    }
    if ($operation === 'create') {
        $machineryId = filter_var($_POST['machinery_id'] ?? null, FILTER_VALIDATE_INT);
        $title = Security::clean($_POST['title'] ?? '', 200);
        if (!$machineryId || $title === '') {
            redirect('admin/repairs.php?msg=invalid');
        }
        $parts = $_POST['part_name'] ?? [];
        if (!is_array($parts)) {
            $parts = [];
        }
        $partRows = [];
        $partsCost = 0.0;
        foreach ($parts as $index => $partName) {
            $partName = Security::clean((string) $partName, 200);
            if ($partName === '') {
                continue;
            }
            $quantity = max(0, (float) ($_POST['part_quantity'][$index] ?? 0));
            $unitPrice = max(0, (float) ($_POST['part_price'][$index] ?? 0));
            $total = $quantity * $unitPrice;
            $partsCost += $total;
            $partRows[] = [$partName, $quantity, $unitPrice, $total];
        }
        $labor = max(0, (float) ($_POST['labor_cost'] ?? 0));
        db()->beginTransaction();
        try {
            db()->prepare('INSERT INTO machinery_repairs (machinery_id, title, description, problem_type, status, priority, technician_name, workshop, labor_cost, parts_cost, total_cost, reported_by, started_at, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?)')->execute([$machineryId, $title, Security::clean($_POST['description'] ?? '', 5000), Security::clean($_POST['problem_type'] ?? 'mechanical', 20), 'pending', Security::clean($_POST['priority'] ?? 'medium', 10), Security::clean($_POST['technician_name'] ?? '', 150), Security::clean($_POST['workshop'] ?? '', 200), $labor, $partsCost, $labor + $partsCost, Auth::id(), Security::clean($_POST['notes'] ?? '', 5000)]);
            $repairId = (int) db()->lastInsertId();
            $insertPart = db()->prepare('INSERT INTO machinery_repair_parts (repair_id, part_name, quantity, unit_price, total) VALUES (?, ?, ?, ?, ?)');
            foreach ($partRows as $part) {
                $insertPart->execute(array_merge([$repairId], $part));
            }
            db()->prepare("UPDATE machinery SET status='maintenance' WHERE id=?")->execute([$machineryId]);
            audit('repair_created', 'machinery_repair', $repairId);
            db()->commit();
        } catch (Throwable $exception) {
            db()->rollBack();
            throw $exception;
        }
        redirect('admin/repairs.php?msg=saved');
    }
}
$machines = db()->query('SELECT id, code, name FROM machinery ORDER BY name')->fetchAll();
$repairs = db()->query('SELECT r.*, m.name AS machine_name, m.code AS machine_code, u.full_name FROM machinery_repairs r JOIN machinery m ON m.id=r.machinery_id JOIN users u ON u.id=r.reported_by ORDER BY r.created_at DESC')->fetchAll();
$pageTitle = 'تصليح الآليات';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>تصليح الآليات</h1><p>طلبات الصيانة والتكلفة وقطع الغيار</p></div><a class="btn btn-primary" href="#new-repair"><?= icon('plus') ?>طلب تصليح</a></div>
<?php if ($editing): ?><section class="panel" style="margin-bottom:18px"><h2 class="panel-title">تعديل طلب التصليح</h2><form method="post" class="form-grid"><?= Security::csrfField() ?><input type="hidden" name="op" value="edit"><input type="hidden" name="id" value="<?= (int) $editing['id'] ?>"><div class="field full"><label>الآلية</label><div class="report-text"><?= Security::e($editing['machine_code'] . ' · ' . $editing['machine_name']) ?></div></div><div class="field"><label>عنوان المشكلة *</label><input name="title" required maxlength="200" value="<?= Security::e($editing['title']) ?>"></div><div class="field"><label>نوع المشكلة</label><select name="problem_type"><?php foreach (['mechanical'=>'ميكانيكية','electrical'=>'كهربائية','body'=>'هيكل','tires'=>'إطارات','other'=>'أخرى'] as $value=>$label): ?><option value="<?= $value ?>" <?= $editing['problem_type'] === $value ? 'selected' : '' ?>><?= Security::e($label) ?></option><?php endforeach; ?></select></div><div class="field"><label>الأولوية</label><select name="priority"><?php foreach (['low','medium','high','urgent'] as $priority): ?><option value="<?= $priority ?>" <?= $editing['priority'] === $priority ? 'selected' : '' ?>><?= Security::e(statusLabel($priority)) ?></option><?php endforeach; ?></select></div><div class="field"><label>الفني</label><input name="technician_name" maxlength="150" value="<?= Security::e($editing['technician_name']) ?>"></div><div class="field"><label>الورشة</label><input name="workshop" maxlength="200" value="<?= Security::e($editing['workshop']) ?>"></div><div class="field"><label>أجور العمل</label><input name="labor_cost" type="number" min="0" step="0.01" value="<?= Security::e($editing['labor_cost']) ?>"></div><div class="field full"><label>الوصف</label><textarea name="description"><?= Security::e($editing['description']) ?></textarea></div><div class="field full"><label>ملاحظات إضافية</label><textarea name="notes"><?= Security::e($editing['notes']) ?></textarea></div><div class="field full"><div class="flex items-center justify-between"><strong>قطع الغيار</strong><button type="button" class="btn btn-quiet btn-sm" id="addEditPart"><?= icon('plus') ?>إضافة قطعة</button></div><div id="editPartsList" class="grid-2" style="margin-top:10px"><?php foreach ($editingParts as $part): ?><div class="grid-2"><div class="field"><label>اسم القطعة</label><input name="part_name[]" maxlength="200" value="<?= Security::e($part['part_name']) ?>"></div><div class="grid-2"><div class="field"><label>الكمية</label><input name="part_quantity[]" type="number" min="0" step="0.01" value="<?= Security::e($part['quantity']) ?>"></div><div class="field"><label>سعر الوحدة</label><input name="part_price[]" type="number" min="0" step="0.01" value="<?= Security::e($part['unit_price']) ?>"></div></div></div><?php endforeach; ?></div></div><div class="field full btn-group"><button class="btn btn-primary">حفظ التعديلات</button><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/repairs.php')) ?>">إلغاء</a></div></form></section><?php else: ?>
<section class="panel" id="new-repair" style="margin-bottom:18px"><h2 class="panel-title">تسجيل طلب تصليح</h2><form method="post" class="form-grid" id="repairForm"><?= Security::csrfField() ?><input type="hidden" name="op" value="create"><div class="field"><label>الآلية *</label><select name="machinery_id" required><?php foreach ($machines as $machine): ?><option value="<?= (int) $machine['id'] ?>"><?= Security::e($machine['code'] . ' · ' . $machine['name']) ?></option><?php endforeach; ?></select></div><div class="field"><label>عنوان المشكلة *</label><input name="title" required maxlength="200"></div><div class="field"><label>نوع المشكلة</label><select name="problem_type"><?php foreach (['mechanical'=>'ميكانيكية','electrical'=>'كهربائية','body'=>'هيكل','tires'=>'إطارات','other'=>'أخرى'] as $value=>$label): ?><option value="<?= $value ?>"><?= Security::e($label) ?></option><?php endforeach; ?></select></div><div class="field"><label>الأولوية</label><select name="priority"><?php foreach (['low','medium','high','urgent'] as $priority): ?><option value="<?= $priority ?>"><?= Security::e(statusLabel($priority)) ?></option><?php endforeach; ?></select></div><div class="field"><label>الفني</label><input name="technician_name" maxlength="150"></div><div class="field"><label>الورشة</label><input name="workshop" maxlength="200"></div><div class="field"><label>أجور العمل</label><input name="labor_cost" type="number" min="0" step="0.01" value="0"></div><div class="field full"><label>الوصف</label><textarea name="description"></textarea></div><div class="field full"><label>ملاحظات إضافية</label><textarea name="notes"></textarea></div><div class="field full"><div class="flex items-center justify-between"><strong>قطع الغيار</strong><button type="button" class="btn btn-quiet btn-sm" id="addPart"><?= icon('plus') ?>إضافة قطعة</button></div><div id="partsList" class="grid-2" style="margin-top:10px"></div></div><div class="field full"><button class="btn btn-primary">حفظ طلب التصليح</button></div></form></section>
<?php endif; ?><div class="table-panel"><div class="table-wrapper table-cards"><table><thead><tr><th>الآلية</th><th>المشكلة</th><th>الفني</th><th>الأولوية</th><th>الحالة</th><th>الكلفة</th><th>تحديث الحالة</th></tr></thead><tbody><?php foreach ($repairs as $repair): ?><tr><td data-label="الآلية"><?= Security::e($repair['machine_code'] . ' · ' . $repair['machine_name']) ?></td><td data-label="المشكلة"><?= Security::e($repair['title']) ?></td><td data-label="الفني"><?= Security::e($repair['technician_name']) ?></td><td data-label="الأولوية"><?= Security::e(statusLabel((string) $repair['priority'])) ?></td><td data-label="الحالة"><?= Security::e(statusLabel((string) $repair['status'])) ?></td><td data-label="الكلفة"><?= Security::e(money($repair['total_cost'])) ?></td><td data-label="تحديث الحالة"><div class="grid gap-2"><?php if (in_array($repair['status'], ['pending','in_progress','waiting_parts'], true)): ?><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/repairs.php?edit=' . (int) $repair['id'])) ?>">تعديل الطلب</a><?php endif; ?><form method="post" class="flex gap-2"><?= Security::csrfField() ?><input type="hidden" name="op" value="status"><input type="hidden" name="id" value="<?= (int) $repair['id'] ?>"><select name="status"><?php foreach (['pending','in_progress','waiting_parts','completed','cancelled'] as $status): ?><option value="<?= $status ?>" <?= $repair['status'] === $status ? 'selected' : '' ?>><?= Security::e(statusLabel($status)) ?></option><?php endforeach; ?></select><button class="btn btn-quiet btn-sm">حفظ</button></form></div></td></tr><?php endforeach; ?><?php if ($repairs === []): ?><tr><td colspan="7" class="empty-state">لا توجد طلبات تصليح</td></tr><?php endif; ?></tbody></table></div></div></div></main>
<script>
(()=>{const list=document.getElementById('partsList');const add=document.getElementById('addPart');if(!list||!add)return;add.addEventListener('click',()=>{const row=document.createElement('div');row.className='grid-2';row.innerHTML='<div class="field"><label>اسم القطعة</label><input name="part_name[]" maxlength="200"></div><div class="grid-2"><div class="field"><label>الكمية</label><input name="part_quantity[]" type="number" min="0" step="0.01" value="1"></div><div class="field"><label>سعر الوحدة</label><input name="part_price[]" type="number" min="0" step="0.01" value="0"></div></div>';list.appendChild(row)})})();
</script><script>(()=>{const list=document.getElementById('editPartsList');const add=document.getElementById('addEditPart');if(!list||!add)return;add.addEventListener('click',()=>{const row=document.createElement('div');row.className='grid-2';row.innerHTML='<div class="field"><label>اسم القطعة</label><input name="part_name[]" maxlength="200"></div><div class="grid-2"><div class="field"><label>الكمية</label><input name="part_quantity[]" type="number" min="0" step="0.01" value="1"></div><div class="field"><label>سعر الوحدة</label><input name="part_price[]" type="number" min="0" step="0.01" value="0"></div></div>';list.appendChild(row)})})();</script><?php require __DIR__ . '/../footer.php'; ?>