<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';
Auth::requireRole('admin');
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    $itemId = filter_var($_POST['item_id'] ?? null, FILTER_VALIDATE_INT);
    $type = Security::clean($_POST['type'] ?? '', 10);
    $quantity = (float) ($_POST['quantity'] ?? 0);
    $price = max(0, (float) ($_POST['unit_price'] ?? 0));
    if (!$itemId || !in_array($type, ['in','out','adjust'], true) || $quantity <= 0) redirect('admin/warehouse_moves.php?msg=invalid');
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $itemQuery = $pdo->prepare('SELECT * FROM warehouse_items WHERE id=? AND is_active=1 FOR UPDATE');
        $itemQuery->execute([$itemId]);
        $item = $itemQuery->fetch();
        if (!$item) throw new RuntimeException('المادة غير متاحة');
        $current = (float) $item['quantity'];
        if ($type === 'out' && $quantity > $current) throw new RuntimeException('الكمية المطلوبة أكبر من الرصيد المتاح');
        $next = $type === 'in' ? $current + $quantity : ($type === 'out' ? $current - $quantity : $quantity);
        $effectivePrice = $price > 0 ? $price : (float) $item['unit_price'];
        $total = $type === 'adjust' ? abs($next - $current) * $effectivePrice : $quantity * $effectivePrice;
        $pdo->prepare('UPDATE warehouse_items SET quantity=?, unit_price=? WHERE id=?')->execute([$next, $effectivePrice, $itemId]);
        $pdo->prepare('INSERT INTO warehouse_transactions (item_id,type,quantity,unit_price,total_price,site_id,supplier,invoice_number,reason,created_by) VALUES (?,?,?,?,?,?,?,?,?,?)')->execute([$itemId, $type, $quantity, $effectivePrice, $total, filter_var($_POST['site_id'] ?? null, FILTER_VALIDATE_INT) ?: null, Security::clean($_POST['supplier'] ?? '', 200), Security::clean($_POST['invoice_number'] ?? '', 100), Security::clean($_POST['reason'] ?? '', 500), Auth::id()]);
        if ($type === 'in' || $type === 'out') {
            $codes = $type === 'in' ? ['1300', '1100'] : ['5100', '1300'];
            $account = $pdo->prepare('SELECT id FROM accounts WHERE code=?');
            $account->execute([$codes[0]]); $debitAccount = (int) $account->fetchColumn();
            $account->execute([$codes[1]]); $creditAccount = (int) $account->fetchColumn();
            if ($total > 0 && $debitAccount && $creditAccount) {
                createJournalEntry('حركة مخزن ' . statusLabel($type) . ' · ' . $item['name'], [['account_id'=>$debitAccount,'debit'=>$total,'credit'=>0],['account_id'=>$creditAccount,'debit'=>0,'credit'=>$total]], (int) Auth::id(), filter_var($_POST['site_id'] ?? null, FILTER_VALIDATE_INT) ?: null);
            }
        }
        $pdo->commit();
        $low = $pdo->prepare('SELECT quantity,min_quantity FROM warehouse_items WHERE id=?'); $low->execute([$itemId]); $stock=$low->fetch();
        if ((float) $stock['quantity'] <= (float) $stock['min_quantity']) notifyAdmins('مخزون منخفض', 'المادة ' . $item['name'] . ' وصلت إلى الحد الأدنى', 'warning', 'admin/warehouse_items.php?filter=low');
    } catch (Throwable $exception) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        $message = $exception instanceof RuntimeException ? $exception->getMessage() : 'تعذر تسجيل الحركة';
        error_log('Maxlond warehouse movement: ' . $exception->getMessage());
        redirect('admin/warehouse_moves.php?msg=' . rawurlencode($message));
    }
    audit('warehouse_' . $type, 'warehouse_item', $itemId);
    redirect('admin/warehouse_moves.php?msg=saved');
}
$items = db()->query('SELECT id,code,name,quantity,unit,unit_price FROM warehouse_items WHERE is_active=1 ORDER BY name')->fetchAll();
$sites = db()->query("SELECT id,name FROM sites WHERE status NOT IN ('completed','cancelled') ORDER BY name")->fetchAll();
$moves = db()->query('SELECT t.*,i.name AS item_name,s.name AS site_name,u.full_name FROM warehouse_transactions t JOIN warehouse_items i ON i.id=t.item_id LEFT JOIN sites s ON s.id=t.site_id JOIN users u ON u.id=t.created_by ORDER BY t.created_at DESC LIMIT 150')->fetchAll();
$pageTitle = 'حركات المخزن';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>حركات المخزن</h1><p>تسجيل الوارد والصادر وتسوية الرصيد</p></div></div><?php if (isset($_GET['msg']) && $_GET['msg'] !== 'saved'): ?><div class="alert alert-error"><?= Security::e($_GET['msg']) ?></div><?php endif; ?>
<section class="panel" style="margin-bottom:18px"><h2 class="panel-title">تسجيل حركة</h2><form method="post" class="form-grid"><?= Security::csrfField() ?><div class="field"><label>المادة</label><select name="item_id" required><?php foreach ($items as $item): ?><option value="<?= (int) $item['id'] ?>"><?= Security::e($item['code'].' · '.$item['name'].' ('.$item['quantity'].' '.$item['unit'].')') ?></option><?php endforeach; ?></select></div><div class="field"><label>نوع الحركة</label><select name="type"><option value="in">وارد</option><option value="out">صادر</option><option value="adjust">تعديل الرصيد</option></select></div><div class="field"><label>الكمية</label><input name="quantity" type="number" min="0.001" step="0.001" required></div><div class="field"><label>سعر الوحدة</label><input name="unit_price" type="number" min="0" step="0.01" value="0"></div><div class="field"><label>الموقع المرتبط</label><select name="site_id"><option value="">بدون موقع</option><?php foreach ($sites as $site): ?><option value="<?= (int) $site['id'] ?>"><?= Security::e($site['name']) ?></option><?php endforeach; ?></select></div><div class="field"><label>المورد</label><input name="supplier" maxlength="200"></div><div class="field"><label>رقم الفاتورة</label><input name="invoice_number" maxlength="100"></div><div class="field"><label>السبب / الملاحظات</label><input name="reason" maxlength="500"></div><div class="field full"><button class="btn btn-primary">تسجيل الحركة</button></div></form></section>
<div class="table-panel"><div class="table-wrapper table-cards"><table><thead><tr><th>التاريخ</th><th>المادة</th><th>النوع</th><th>الكمية</th><th>القيمة</th><th>الموقع</th><th>المسجل</th></tr></thead><tbody><?php foreach ($moves as $move): ?><tr><td data-label="التاريخ"><?= Security::e($move['created_at']) ?></td><td data-label="المادة"><?= Security::e($move['item_name']) ?></td><td data-label="النوع"><?= Security::e(statusLabel((string) $move['type'])) ?></td><td data-label="الكمية"><?= Security::e($move['quantity']) ?></td><td data-label="القيمة"><?= Security::e(money($move['total_price'])) ?></td><td data-label="الموقع"><?= Security::e($move['site_name']) ?></td><td data-label="المسجل"><?= Security::e($move['full_name']) ?></td></tr><?php endforeach; ?><?php if ($moves === []): ?><tr><td colspan="7" class="empty-state">لا توجد حركات</td></tr><?php endif; ?></tbody></table></div></div></div></main><?php require __DIR__ . '/../footer.php'; ?>