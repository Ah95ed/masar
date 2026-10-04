<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/database.php';
require_once __DIR__ . '/security.php';
require_once __DIR__ . '/helpers.php';

$error = '';
$success = false;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    if (!Security::throttle('register_' . Security::getClientIp(), 3, 3600)) {
        $error = 'تم تجاوز عدد محاولات التسجيل. حاول لاحقاً';
    } else {
        $name = Security::clean($_POST['full_name'] ?? '', 150);
        $username = Security::clean($_POST['username'] ?? '', 80);
        $email = Security::clean($_POST['email'] ?? '', 150);
        $phone = Security::clean($_POST['phone'] ?? '', 30);
        $specialization = Security::clean($_POST['specialization'] ?? '', 100);
        $password = (string) ($_POST['password'] ?? '');
        if ($name === '' || !preg_match('/^[a-zA-Z0-9_.-]{3,80}$/', $username) || !filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($password) < 10) {
            $error = 'تحقق من البيانات. يجب أن تتكون كلمة المرور من 10 أحرف على الأقل';
        } else {
            try {
                $statement = db()->prepare("INSERT INTO users (full_name, username, email, password_hash, role, phone, specialization, approval_status, is_active) VALUES (?, ?, ?, ?, 'engineer', ?, ?, 'pending', 1)");
                $statement->execute([$name, $username, $email, password_hash($password, PASSWORD_DEFAULT), $phone, $specialization]);
                notifyAdmins('طلب تسجيل جديد', 'طلب المهندس ' . $name . ' الموافقة على حسابه', 'warning', 'admin/pending_users.php');
                $success = true;
            } catch (PDOException $exception) {
                $error = $exception->getCode() === '23000' ? 'اسم المستخدم أو البريد الإلكتروني مستخدم مسبقاً' : 'تعذر إنشاء الحساب حالياً';
                if ($exception->getCode() !== '23000') {
                    error_log('Maxlond registration error: ' . $exception->getMessage());
                }
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>إنشاء حساب | Maxlond</title><script src="https://cdn.tailwindcss.com"></script><link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700&display=swap" rel="stylesheet"><link rel="stylesheet" href="<?= Security::e(APP_URL) ?>/assets/css/app.css?v=<?= (int) filemtime(__DIR__ . '/assets/css/app.css') ?>"></head>
<body class="auth-page"><aside class="auth-aside"><a class="brand-lockup" href="<?= Security::e(APP_URL) ?>"><span class="brand-mark">ML</span><span><strong>Maxlond</strong><small>إدارة المشاريع المدنية</small></span></a><div><h1>ابدأ من موقعك<br>وابقَ على اطلاع</h1><p>أنشئ حساب مهندس لإدارة المهام اليومية ومتابعة تقارير مواقع العمل.</p></div><small>يتم تفعيل الحساب بعد موافقة الإدارة</small></aside><main class="auth-form-area"><section class="auth-card"><h2>إنشاء حساب مهندس</h2><p>أدخل بياناتك لإرسال طلب التسجيل</p><?php if ($success): ?><div class="alert alert-success">تم إرسال طلبك إلى الإدارة. يمكنك تسجيل الدخول بعد الموافقة.</div><a class="btn btn-primary" href="<?= Security::e(APP_URL) ?>/login.php">العودة لتسجيل الدخول</a><?php else: ?><?php if ($error !== ''): ?><div class="alert alert-error"><?= Security::e($error) ?></div><?php endif; ?><form method="post" autocomplete="on"><?= Security::csrfField() ?><div class="field"><label for="full_name">الاسم الكامل</label><input id="full_name" name="full_name" required maxlength="150" value="<?= Security::e($_POST['full_name'] ?? '') ?>"></div><div class="field"><label for="username">اسم المستخدم</label><input id="username" name="username" required minlength="3" maxlength="80" pattern="[a-zA-Z0-9_.-]+" autocomplete="username" value="<?= Security::e($_POST['username'] ?? '') ?>"></div><div class="field"><label for="email">البريد الإلكتروني</label><input id="email" name="email" type="email" required maxlength="150" autocomplete="email" value="<?= Security::e($_POST['email'] ?? '') ?>"></div><div class="field"><label for="phone">رقم الهاتف</label><input id="phone" name="phone" maxlength="30" value="<?= Security::e($_POST['phone'] ?? '') ?>"></div><div class="field"><label for="specialization">التخصص</label><input id="specialization" name="specialization" maxlength="100" value="<?= Security::e($_POST['specialization'] ?? '') ?>"></div><div class="field"><label for="password">كلمة المرور (10 أحرف على الأقل)</label><input id="password" name="password" type="password" required minlength="10" autocomplete="new-password"></div><button class="btn btn-primary" type="submit">إرسال طلب التسجيل</button></form><div class="auth-note"><a href="<?= Security::e(APP_URL) ?>/login.php">لديك حساب؟ تسجيل الدخول</a></div><?php endif; ?></section></main><script src="<?= Security::e(APP_URL) ?>/assets/js/app.js"></script></body></html>