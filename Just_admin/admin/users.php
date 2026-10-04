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
    $editQuery = db()->prepare("SELECT id,full_name,email,phone,specialization FROM users WHERE id=? AND role IN ('engineer','accountant')");
    $editQuery->execute([$editId]);
    $editing = $editQuery->fetch() ?: null;
}
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    $userId = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT) ?: 0;
    $operation = Security::clean($_POST['op'] ?? 'toggle', 20);
    if ($operation === 'create') {
        $fullName = Security::clean($_POST['full_name'] ?? '', 150);
        $username = Security::clean($_POST['username'] ?? '', 80);
        $email = Security::clean($_POST['email'] ?? '', 150);
        $role = Security::clean($_POST['role'] ?? '', 20);
        $password = $_POST['password'] ?? null;
        $phone = Security::clean($_POST['phone'] ?? '', 30);
        $specialization = Security::clean($_POST['specialization'] ?? '', 100);
        if ($fullName === '' || !preg_match('/^[A-Za-z0-9_.-]{3,80}$/', $username) || !filter_var($email, FILTER_VALIDATE_EMAIL) || !in_array($role, ['engineer','accountant'], true) || !is_string($password) || strlen($password) < 10 || strlen($password) > 1024) {
            redirect('admin/users.php?msg=invalid');
        }
        $duplicate = db()->prepare('SELECT COUNT(*) FROM users WHERE username=? OR email=?');
        $duplicate->execute([$username,$email]);
        if ((int) $duplicate->fetchColumn() > 0) redirect('admin/users.php?msg=user_email_taken');
        db()->prepare("INSERT INTO users (full_name,username,email,password_hash,role,phone,specialization,is_active,approval_status) VALUES (?,?,?,?,?,?,?,1,'approved')")
            ->execute([$fullName,$username,$email,password_hash($password,PASSWORD_DEFAULT),$role,$phone,$specialization]);
        $newUserId = (int) db()->lastInsertId();
        audit('user_created','user',$newUserId,'role='.$role);
        redirect('admin/users.php?msg=user_created');
    }
    if ($operation === 'save' && $userId) {
        $fullName = Security::clean($_POST['full_name'] ?? '', 150);
        $email = Security::clean($_POST['email'] ?? '', 150);
        $phone = Security::clean($_POST['phone'] ?? '', 30);
        $specialization = Security::clean($_POST['specialization'] ?? '', 100);
        if ($fullName === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) redirect('admin/users.php?msg=invalid');
        $emailCheck = db()->prepare('SELECT COUNT(*) FROM users WHERE email=? AND id<>?');
        $emailCheck->execute([$email, $userId]);
        if ((int) $emailCheck->fetchColumn() > 0) redirect('admin/users.php?msg=user_email_taken');
        $update = db()->prepare("UPDATE users SET full_name=?,email=?,phone=?,specialization=? WHERE id=? AND role IN ('engineer','accountant')");
        $update->execute([$fullName,$email,$phone,$specialization,$userId]);
        audit('engineer_profile_updated', 'user', $userId);
        redirect('admin/users.php?msg=user_saved');
    }
    if ($operation === 'toggle' && $userId && $userId !== Auth::id()) {
        $statement = db()->prepare("UPDATE users SET is_active = IF(is_active = 1, 0, 1) WHERE id = ? AND role IN ('engineer','accountant')");
        $statement->execute([$userId]);
        audit('user_status_toggled', 'user', (int) $userId);
    }
    redirect('admin/users.php?msg=updated');
}
$users = db()->query('SELECT id, full_name, username, email, phone, specialization, is_active, approval_status, last_login, created_at FROM users ORDER BY role, full_name')->fetchAll();
$pageTitle = 'إدارة المستخدمين';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>إدارة المستخدمين</h1><p>حسابات الإدارة والمهندسين والمحاسبين وصلاحية الدخول</p></div><div class="btn-group"><a class="btn btn-primary" href="<?= Security::e(pageUrl('admin/users.php?action=new')) ?>">إضافة حساب</a><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/pending_users.php')) ?>">طلبات التسجيل</a></div></div>
<?php if (isset($_GET['action']) && !$editing): ?><section class="panel" style="margin-bottom:18px"><h2 class="panel-title">إنشاء حساب موظف</h2><form method="post" class="form-grid"><?= Security::csrfField() ?><input type="hidden" name="op" value="create"><div class="field"><label>الاسم الكامل *</label><input name="full_name" required maxlength="150"></div><div class="field"><label>اسم المستخدم *</label><input name="username" required minlength="3" maxlength="80" pattern="[A-Za-z0-9_.-]+" autocomplete="username"></div><div class="field"><label>البريد الإلكتروني *</label><input name="email" type="email" required maxlength="150" autocomplete="email"></div><div class="field"><label>الدور *</label><select name="role" required><option value="engineer">مهندس موقع</option><option value="accountant">محاسب</option></select></div><div class="field"><label>كلمة مرور مؤقتة *</label><input name="password" type="password" required minlength="10" maxlength="1024" autocomplete="new-password"></div><div class="field"><label>رقم الهاتف</label><input name="phone" maxlength="30"></div><div class="field"><label>التخصص</label><input name="specialization" maxlength="100"></div><div class="field full btn-group"><button class="btn btn-primary">إنشاء الحساب</button><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/users.php')) ?>">إلغاء</a></div></form></section><?php endif; ?>
<?php if ($editing): ?><section class="panel" style="margin-bottom:18px"><h2 class="panel-title">تعديل بيانات المهندس</h2><form method="post" class="form-grid"><?= Security::csrfField() ?><input type="hidden" name="op" value="save"><input type="hidden" name="id" value="<?= (int) $editing['id'] ?>"><div class="field"><label>الاسم الكامل *</label><input name="full_name" required maxlength="150" value="<?= Security::e($editing['full_name']) ?>"></div><div class="field"><label>البريد الإلكتروني *</label><input name="email" type="email" required maxlength="150" value="<?= Security::e($editing['email']) ?>"></div><div class="field"><label>رقم الهاتف</label><input name="phone" maxlength="30" value="<?= Security::e($editing['phone']) ?>"></div><div class="field"><label>التخصص</label><input name="specialization" maxlength="100" value="<?= Security::e($editing['specialization']) ?>"></div><div class="field full btn-group"><button class="btn btn-primary">حفظ البيانات</button><a class="btn btn-quiet" href="<?= Security::e(pageUrl('admin/users.php')) ?>">إلغاء</a></div></form></section><?php endif; ?>
<div class="table-panel"><div class="table-toolbar"><h2>جميع الحسابات</h2><span class="pill info"><?= count($users) ?> مستخدم</span></div><div class="table-wrapper table-cards"><table><thead><tr><th>المستخدم</th><th>الدور</th><th>التواصل</th><th>الحالة</th><th>آخر دخول</th><th>الإجراء</th></tr></thead><tbody>
<?php foreach ($users as $user): ?><tr><td data-label="المستخدم"><strong><?= Security::e($user['full_name']) ?></strong><small style="display:block;color:var(--muted)"><?= Security::e($user['username']) ?> · <?= Security::e($user['email']) ?></small></td><td data-label="الدور"><?= Security::e(['admin'=>'مدير','engineer'=>'مهندس','accountant'=>'محاسب'][$user['role']] ?? $user['role']) ?></td><td data-label="التواصل"><?= Security::e($user['phone']) ?><small style="display:block;color:var(--muted)"><?= Security::e($user['specialization']) ?></small></td><td data-label="الحالة"><span class="pill <?= $user['approval_status'] === 'approved' && (int) $user['is_active'] ? 'success' : 'warning' ?>"><?= Security::e(statusLabel((string) $user['approval_status'])) ?><?= (int) $user['is_active'] ? '' : ' · معطل' ?></span></td><td data-label="آخر دخول"><?= Security::e($user['last_login'] ?: 'لم يسجل الدخول') ?></td><td data-label="الإجراء"><?php if ($user['role'] !== 'admin'): ?><div class="btn-group"><a class="btn btn-quiet btn-sm" href="<?= Security::e(pageUrl('admin/users.php?edit=' . (int) $user['id'])) ?>">تعديل</a><?php if ($user['approval_status'] === 'approved'): ?><form method="post"><?= Security::csrfField() ?><input type="hidden" name="id" value="<?= (int) $user['id'] ?>"><button class="btn <?= (int) $user['is_active'] ? 'btn-danger' : 'btn-primary' ?> btn-sm" type="submit"><?= (int) $user['is_active'] ? 'تعطيل' : 'تفعيل' ?></button></form><?php endif; ?></div><?php else: ?><span class="pill">محمي</span><?php endif; ?></td></tr><?php endforeach; ?>
</tbody></table></div></div></div></main><?php require __DIR__ . '/../footer.php'; ?>