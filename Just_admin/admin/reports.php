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
    $reportId = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT);
    $decision = Security::clean($_POST['decision'] ?? '', 10);
    $notes = Security::clean($_POST['admin_notes'] ?? '', 5000);
    if ($reportId && in_array($decision, ['approved', 'rejected'], true)) {
        $pdo = db();
        $pdo->beginTransaction();
        try {
            $statement = $pdo->prepare("SELECT r.*, s.name AS site_name FROM site_daily_reports r JOIN sites s ON s.id=r.site_id WHERE r.id=? AND r.status='submitted' FOR UPDATE");
            $statement->execute([$reportId]);
            $report = $statement->fetch();
            if (!$report) {
                $pdo->rollBack();
                redirect('admin/reports.php?msg=already_reviewed');
            }
            $updated = $pdo->prepare('UPDATE site_daily_reports SET status=?, admin_notes=?, approved_by=?, approved_at=NOW() WHERE id=? AND status="submitted"');
            $updated->execute([$decision, $notes, Auth::id(), $reportId]);
            if ($decision === 'approved') {
                $expenseQuery = $pdo->prepare('SELECT category, SUM(total) AS total FROM report_expenses WHERE report_id=? GROUP BY category');
                $expenseQuery->execute([$reportId]);
                $accountCodes = ['materials'=>'5100','labor'=>'5200','fuel'=>'5300','equipment'=>'5400','transport'=>'5500','other'=>'5600'];
                $accountQuery = $pdo->prepare('SELECT id FROM accounts WHERE code=?');
                $lines = [];
                $sum = 0.0;
                foreach ($expenseQuery->fetchAll() as $expense) {
                    $amount = round((float) $expense['total'], 2);
                    if ($amount <= 0) continue;
                    $accountQuery->execute([$accountCodes[$expense['category']] ?? '5600']);
                    $accountId = (int) $accountQuery->fetchColumn();
                    if (!$accountId) throw new RuntimeException('حساب المصروفات غير موجود');
                    $lines[] = ['account_id'=>$accountId,'debit'=>$amount,'credit'=>0,'description'=>'مصروفات تقرير الموقع'];
                    $sum += $amount;
                }
                if ($sum > 0) {
                    $accountQuery->execute(['1100']);
                    $cashId = (int) $accountQuery->fetchColumn();
                    if (!$cashId) throw new RuntimeException('حساب النقدية غير موجود');
                    $lines[] = ['account_id'=>$cashId,'debit'=>0,'credit'=>$sum,'description'=>'صرف مصروفات التقرير'];
                    createJournalEntry('مصروفات التقرير اليومي · ' . $report['site_name'], $lines, (int) Auth::id(), (int) $report['site_id'], $reportId, 'report-' . $reportId);
                }
            }
            $pdo->commit();
        } catch (Throwable $exception) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            error_log('Maxlond report review: ' . $exception->getMessage());
            redirect('admin/reports.php?msg=review_failed');
        }
        if ($report) {
            notify((int) $report['engineer_id'], $decision === 'approved' ? 'تم اعتماد التقرير' : 'تم رفض التقرير', $report['site_name'] . ($notes !== '' ? ' · ' . $notes : ''), $decision === 'approved' ? 'success' : 'danger', 'engineer/dashboard.php');
            audit('report_' . $decision, 'report', $reportId);
        }
    }
    redirect('admin/reports.php?msg=updated');
}
$status = Security::clean($_GET['status'] ?? '', 20);
$allowedStatus = ['submitted','approved','rejected','draft'];
$query = 'SELECT r.*, s.name AS site_name, u.full_name FROM site_daily_reports r JOIN sites s ON s.id=r.site_id JOIN users u ON u.id=r.engineer_id';
if (in_array($status, $allowedStatus, true)) {
    $statement = db()->prepare($query . ' WHERE r.status=? ORDER BY r.report_date DESC, r.created_at DESC');
    $statement->execute([$status]);
    $reports = $statement->fetchAll();
} else {
    $reports = db()->query($query . ' ORDER BY r.report_date DESC, r.created_at DESC LIMIT 200')->fetchAll();
}
$pageTitle = 'التقارير اليومية';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>التقارير اليومية</h1><p>مراجعة واعتماد تقارير المهندسين والمصروفات</p></div><div class="btn-group"><a class="btn btn-primary" href="<?= Security::e(pageUrl('admin/export.php?type=reports')) ?>">تنزيل تقارير Excel</a><form method="get" class="flex gap-2"><select name="status"><option value="">كل الحالات</option><?php foreach ($allowedStatus as $option): ?><option value="<?= $option ?>" <?= $status === $option ? 'selected' : '' ?>><?= Security::e(statusLabel($option)) ?></option><?php endforeach; ?></select><button class="btn btn-quiet">تصفية</button></form></div></div>
<div class="table-panel"><div class="table-wrapper table-cards"><table><thead><tr><th>التاريخ والموقع</th><th>المهندس</th><th>الإنجاز</th><th>العمال / الآليات</th><th>الحالة</th><th>ملخص العمل</th><th>المراجعة</th></tr></thead><tbody><?php foreach ($reports as $report): ?><tr><td data-label="التاريخ والموقع"><?= Security::e($report['report_date']) ?><small style="display:block;color:var(--muted)"><?= Security::e($report['site_name']) ?></small></td><td data-label="المهندس"><?= Security::e($report['full_name']) ?></td><td data-label="الإنجاز"><?= (int) $report['progress_percent'] ?>%</td><td data-label="العمال / الآليات"><?= (int) $report['workers_count'] ?> / <?= (int) $report['machinery_count'] ?></td><td data-label="الحالة"><span class="pill <?= $report['status'] === 'approved' ? 'success' : ($report['status'] === 'submitted' ? 'warning' : '') ?>"><?= Security::e(statusLabel((string) $report['status'])) ?></span></td><td data-label="ملخص العمل"><?= Security::e($report['work_done']) ?></td><td data-label="المراجعة"><div class="grid gap-2"><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/report_view.php?id=' . (int) $report['id'])) ?>">معاينة التقرير</a><?php if ($report['status'] === 'submitted'): ?><form method="post" class="grid gap-2"><?= Security::csrfField() ?><input type="hidden" name="id" value="<?= (int) $report['id'] ?>"><input name="admin_notes" maxlength="5000" placeholder="ملاحظات المدير"><div class="btn-group"><button class="btn btn-primary btn-sm" name="decision" value="approved">اعتماد</button><button class="btn btn-danger btn-sm" name="decision" value="rejected">رفض</button></div></form><?php else: ?><?= Security::e($report['admin_notes']) ?><?php endif; ?></div></td></tr><?php endforeach; ?><?php if ($reports === []): ?><tr><td colspan="7" class="empty-state">لا توجد تقارير ضمن هذا الاختيار</td></tr><?php endif; ?></tbody></table></div></div></div></main><?php require __DIR__ . '/../footer.php'; ?>