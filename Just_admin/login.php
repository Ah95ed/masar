<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/database.php';
require_once __DIR__ . '/security.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/helpers.php';

if (Auth::check()) {
    redirect(match (Auth::role()) {'admin'=>'admin/dashboard.php','accountant'=>'admin/financial.php',default=>'engineer/dashboard.php'});
}
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    $result = Auth::login(Security::clean($_POST['username'] ?? '', 100), (string) ($_POST['password'] ?? ''));
    if ($result['ok']) {
        redirect(match ((string) $result['user']['role']) {'admin'=>'admin/dashboard.php','accountant'=>'admin/financial.php',default=>'engineer/dashboard.php'});
    }
    $error = (string) $result['msg'];
}
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>تسجيل الدخول | Maxlond</title><script src="https://cdn.tailwindcss.com"></script><link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700&display=swap" rel="stylesheet"><link rel="stylesheet" href="<?= Security::e(APP_URL) ?>/assets/css/app.css?v=<?= (int) filemtime(__DIR__ . '/assets/css/app.css') ?>"></head>
<body class="auth-page"><aside class="auth-aside"><a class="brand-lockup" href="<?= Security::e(APP_URL) ?>"><span class="brand-mark">ML</span><span><strong>Maxlond</strong><small>إدارة المشاريع المدنية</small></span></a><div><h1>مساحة واحدة<br>لإدارة أعمالك</h1><p>تابع المواقع والفرق والآليات والتقارير المالية من لوحة عمل موحدة.</p></div><small>نظام إدارة المقاولات والأعمال المدنية</small></aside><main class="auth-form-area"><section class="auth-card"><h2>مرحباً بعودتك</h2><p>سجّل الدخول إلى مساحة العمل</p><?php if ($error !== ''): ?><div class="alert alert-error"><?= Security::e($error) ?></div><?php endif; ?><form method="post" autocomplete="on"><?= Security::csrfField() ?><div class="field"><label for="username">اسم المستخدم أو البريد الإلكتروني</label><input id="username" name="username" required maxlength="100" autocomplete="username" value="<?= Security::e($_POST['username'] ?? '') ?>"></div><div class="field"><label for="password">كلمة المرور</label><input id="password" name="password" type="password" required autocomplete="current-password"></div><button class="btn btn-primary" type="submit">تسجيل الدخول</button></form><div class="auth-note">ليس لديك حساب؟ <a href="<?= Security::e(APP_URL) ?>/register.php" style="color:var(--cyan);font-weight:700">إنشاء حساب مهندس</a></div></section></main><script src="<?= Security::e(APP_URL) ?>/assets/js/app.js?v=<?= (int) filemtime(__DIR__ . '/assets/js/app.js') ?>"></script></body></html>