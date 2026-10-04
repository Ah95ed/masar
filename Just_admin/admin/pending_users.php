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
    $userId = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);
    $decision = Security::clean($_POST['decision'] ?? '', 10);
    if ($userId && in_array($decision, ['approved', 'rejected'], true)) {
        $statement = db()->prepare("UPDATE users SET approval_status = ? WHERE id = ? AND role = 'engineer' AND approval_status = 'pending'");
        $statement->execute([$decision, $userId]);
        if ($statement->rowCount() > 0) {
            notify((int) $userId, $decision === 'approved' ? 'تم اعتماد حسابك' : 'تم رفض طلب التسجيل', $decision === 'approved' ? 'يمكنك الآن تسجيل الدخول إلى النظام' : 'تواصل مع الإدارة لمزيد من المعلومات', $decision === 'approved' ? 'success' : 'danger');
            audit('user_' . $decision, 'user', (int) $userId);
        }
    }
    redirect('admin/pending_users.php?msg=updated');
}
$users = db()->query("SELECT id, full_name, username, email, phone, specialization, created_at FROM users WHERE role = 'engineer' AND approval_status = 'pending' ORDER BY created_at ASC")->fetchAll();
$pageTitle = 'طلبات التسجيل';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>طلبات التسجيل</h1><p>مراجعة حسابات المهندسين الجديدة</p></div><span class="pill warning"><?= count($users) ?> طلب بانتظار المراجعة</span></div>
<div class="table-panel"><div class="table-wrapper table-cards"><table><thead><tr><th>الاسم</th><th>اسم المستخدم</th><th>البريد الإلكتروني</th><th>الهاتف</th><th>التخصص</th><th>تاريخ الطلب</th><th>الإجراء</th></tr></thead><tbody>
<?php foreach ($users as $user): ?><tr><td data-label="الاسم"><?= Security::e($user['full_name']) ?></td><td data-label="اسم المستخدم"><?= Security::e($user['username']) ?></td><td data-label="البريد الإلكتروني"><?= Security::e($user['email']) ?></td><td data-label="الهاتف"><?= Security::e($user['phone']) ?></td><td data-label="التخصص"><?= Security::e($user['specialization']) ?></td><td data-label="تاريخ الطلب"><?= Security::e($user['created_at']) ?></td><td data-label="الإجراء"><div class="btn-group"><form method="post"><?= Security::csrfField() ?><input type="hidden" name="id" value="<?= (int) $user['id'] ?>"><input type="hidden" name="decision" value="approved"><button class="btn btn-primary btn-sm" type="submit"><?= icon('check') ?>اعتماد</button></form><form method="post"><?= Security::csrfField() ?><input type="hidden" name="id" value="<?= (int) $user['id'] ?>"><input type="hidden" name="decision" value="rejected"><button class="btn btn-danger btn-sm" type="submit" data-confirm="رفض طلب هذا المستخدم؟"><?= icon('close') ?>رفض</button></form></div></td></tr><?php endforeach; ?>
<?php if ($users === []): ?><tr><td colspan="7" class="empty-state">لا توجد طلبات معلقة</td></tr><?php endif; ?></tbody></table></div></div></div></main>
<?php require __DIR__ . '/../footer.php'; ?>