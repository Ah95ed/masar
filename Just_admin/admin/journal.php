<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';
Auth::requireRole('admin','accountant');
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    $description = Security::clean($_POST['description'] ?? '', 500);
    $accountIds = $_POST['account_id'] ?? [];
    $debits = $_POST['debit'] ?? [];
    $credits = $_POST['credit'] ?? [];
    $lines = [];
    if (is_array($accountIds) && is_array($debits) && is_array($credits)) {
        foreach ($accountIds as $index => $accountId) {
            $accountId = filter_var($accountId, FILTER_VALIDATE_INT);
            $debit = max(0, (float) ($debits[$index] ?? 0));
            $credit = max(0, (float) ($credits[$index] ?? 0));
            if (!$accountId || ($debit <= 0 && $credit <= 0) || ($debit > 0 && $credit > 0)) continue;
            $lines[] = ['account_id'=>(int) $accountId,'debit'=>$debit,'credit'=>$credit,'description'=>Security::clean((string) ($_POST['line_description'][$index] ?? ''),500)];
        }
    }
    try {
        if ($description === '') throw new InvalidArgumentException('أدخل وصف القيد');
        $entryId = createJournalEntry($description, $lines, (int) Auth::id(), filter_var($_POST['site_id'] ?? null, FILTER_VALIDATE_INT) ?: null);
        audit('journal_created', 'journal_entry', $entryId);
        redirect('admin/journal.php?msg=saved');
    } catch (InvalidArgumentException $exception) {
        $error = $exception->getMessage();
    }
}
$accounts = db()->query('SELECT id,code,name FROM accounts WHERE is_active=1 ORDER BY code')->fetchAll();
$sites = db()->query('SELECT id,name FROM sites ORDER BY name')->fetchAll();
$entries = db()->query('SELECT j.*,u.full_name,s.name AS site_name FROM journal_entries j JOIN users u ON u.id=j.created_by LEFT JOIN sites s ON s.id=j.site_id ORDER BY j.entry_date DESC,j.id DESC LIMIT 150')->fetchAll();
$pageTitle = 'القيود اليومية';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>القيود اليومية</h1><p>قيود مزدوجة متوازنة وموقعة رقمياً</p></div><a class="btn btn-primary" href="#new-entry"><?= icon('plus') ?>قيد جديد</a></div><?php if ($error !== ''): ?><div class="alert alert-error"><?= Security::e($error) ?></div><?php endif; ?>
<section class="panel" id="new-entry" style="margin-bottom:18px"><h2 class="panel-title">إنشاء قيد</h2><form method="post" class="form-grid" id="journalForm"><?= Security::csrfField() ?><div class="field full"><label>وصف القيد</label><input name="description" required maxlength="500"></div><div class="field"><label>الموقع المرتبط</label><select name="site_id"><option value="">بدون موقع</option><?php foreach ($sites as $site): ?><option value="<?= (int) $site['id'] ?>"><?= Security::e($site['name']) ?></option><?php endforeach; ?></select></div><div class="field full"><div class="flex items-center justify-between"><strong>بنود القيد</strong><button type="button" class="btn btn-quiet btn-sm" id="addLine"><?= icon('plus') ?>إضافة بند</button></div><div id="linesList" class="grid gap-3" style="margin-top:10px"></div></div><div class="field full"><button class="btn btn-primary">ترحيل القيد</button></div></form></section>
<div class="table-panel"><div class="table-wrapper table-cards"><table><thead><tr><th>رقم القيد</th><th>التاريخ</th><th>الوصف</th><th>الموقع</th><th>مدين</th><th>دائن</th><th>الحالة</th></tr></thead><tbody><?php foreach ($entries as $entry): ?><tr><td data-label="رقم القيد"><?= Security::e($entry['entry_number']) ?></td><td data-label="التاريخ"><?= Security::e($entry['entry_date']) ?></td><td data-label="الوصف"><?= Security::e($entry['description']) ?></td><td data-label="الموقع"><?= Security::e($entry['site_name']) ?></td><td data-label="مدين"><?= Security::e(money($entry['total_debit'])) ?></td><td data-label="دائن"><?= Security::e(money($entry['total_credit'])) ?></td><td data-label="الحالة"><span class="pill success"><?= Security::e(statusLabel((string) $entry['status'])) ?></span></td></tr><?php endforeach; ?></tbody></table></div></div></div></main>
<script>
(()=>{const list=document.getElementById('linesList');const button=document.getElementById('addLine');if(!list||!button)return;const options=<?= json_encode(array_map(static function(array $row): array{return ['id'=>(int)$row['id'],'label'=>$row['code'].' · '.$row['name']];},$accounts),JSON_HEX_TAG|JSON_HEX_APOS|JSON_HEX_AMP|JSON_HEX_QUOT) ?>;button.addEventListener('click',()=>{const row=document.createElement('div');row.className='grid-2';const select=document.createElement('select');select.name='account_id[]';select.required=true;options.forEach(account=>{const option=document.createElement('option');option.value=String(account.id);option.textContent=account.label;select.appendChild(option)});row.innerHTML='<div class="field"><label>الحساب</label></div><div class="grid-2"><div class="field"><label>مدين</label><input name="debit[]" type="number" min="0" step="0.01" value="0"></div><div class="field"><label>دائن</label><input name="credit[]" type="number" min="0" step="0.01" value="0"></div></div><div class="field full"><label>البيان</label><input name="line_description[]" maxlength="500"></div>';row.querySelector('.field').appendChild(select);list.appendChild(row)});button.click()})();
</script><?php require __DIR__ . '/../footer.php'; ?>