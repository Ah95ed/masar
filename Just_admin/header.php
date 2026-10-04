<?php
declare(strict_types=1);
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/auth.php';

$pageTitle = isset($pageTitle) ? (string) $pageTitle : APP_NAME;
$currentRole = Auth::role() ?? 'engineer';
$notificationPath = $currentRole === 'engineer' ? 'engineer/notifications.php' : 'admin/notifications.php';
$countQuery = db()->prepare('SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0');
$countQuery->execute([Auth::id()]);
$unreadCount = (int) $countQuery->fetchColumn();
$flashMessages = [
    'saved'=>['تم حفظ البيانات بنجاح','success'], 'updated'=>['تم تحديث البيانات بنجاح','success'],
    'deleted'=>['تم الحذف بنجاح','success'], 'account_deleted'=>['تم حذف الحساب غير المستخدم','success'],
    'account_in_use'=>['لا يمكن حذف حساب له قيود أو رصيد','error'], 'account_type_locked'=>['لا يمكن تغيير نوع حساب مستخدم في القيود','error'],
    'account_missing'=>['الحساب المطلوب غير موجود','error'], 'invalid'=>['تحقق من البيانات المدخلة','error'],
    'user_saved'=>['تم تحديث بيانات المهندس','success'], 'user_email_taken'=>['البريد الإلكتروني مستخدم من حساب آخر','error'],
    'user_created'=>['تم إنشاء الحساب ويمكنه تسجيل الدخول الآن','success'],
    'repair_locked'=>['لا يمكن تعديل طلب مكتمل أو مرتبط بقيد محاسبي','error'],
    'already_reviewed'=>['تمت مراجعة التقرير مسبقاً','error'], 'review_failed'=>['تعذرت مراجعة التقرير، حاول لاحقاً','error'],
    'report_saved'=>['تم إرسال التقرير بنجاح','success'], 'category'=>['تم تحديث الفئة','success'],
    'account_created'=>['تم إنشاء الحساب','success'],
];
$flashRaw = $_GET['msg'] ?? '';
$flashKey = Security::clean(is_string($flashRaw) ? $flashRaw : '', 500);
$flash = $flashMessages[$flashKey] ?? null;
if (!$flash && $flashKey !== '') $flash = [$flashKey, 'error'];
$navItems = $currentRole === 'admin' ? [
    ['admin/dashboard.php', 'لوحة التحكم', 'grid'], ['admin/sites.php', 'المواقع', 'pin'],
    ['admin/work_plans.php', 'خطط العمل', 'clipboard'], ['admin/reports.php', 'التقارير اليومية', 'chart'],
    ['admin/machinery.php', 'الآليات', 'truck'], ['admin/repairs.php', 'تصليح الآليات', 'tool'],
    ['admin/warehouse.php', 'المخزن', 'box'], ['admin/accounts.php', 'الحسابات', 'book'],
    ['admin/financial.php', 'التقارير المالية', 'chart'], ['admin/journal.php', 'القيود اليومية', 'clipboard'],
    ['admin/work_updates.php', 'تحديثات المهندسين', 'clipboard'],
    ['admin/users.php', 'المستخدمون', 'users'], ['admin/notifications.php', 'الإشعارات', 'bell'],
] : ($currentRole === 'accountant' ? [
    ['admin/accounts.php', 'دليل الحسابات', 'book'], ['admin/journal.php', 'القيود اليومية', 'clipboard'],
    ['admin/financial.php', 'التقارير المالية', 'chart'], ['admin/notifications.php', 'الإشعارات', 'bell'],
] : [
    ['engineer/dashboard.php', 'لوحة المهندس', 'grid'], ['engineer/tasks.php', 'مهامي', 'clipboard'],
    ['engineer/report.php', 'تقرير يومي جديد', 'chart'], ['engineer/notifications.php', 'الإشعارات', 'bell'],
]);
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <meta name="theme-color" content="#102b3f">
    <title><?= Security::e($pageTitle . ' | ' . APP_NAME) ?></title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<?= Security::e(APP_URL) ?>/assets/css/app.css?v=<?= (int) filemtime(__DIR__ . '/assets/css/app.css') ?>">
</head>
<body>
<?php if ($flash): ?><div class="toast toast-<?= Security::e($flash[1]) ?>" role="status" aria-live="polite" data-toast><?= Security::e($flash[0]) ?><button type="button" class="toast-close" aria-label="إغلاق" onclick="this.parentElement.remove()">×</button></div><?php endif; ?>
<header class="mobile-bar">
    <button type="button" class="menu-btn" onclick="toggleSidebar()" aria-label="فتح القائمة"><?= icon('menu') ?></button>
    <a class="mobile-brand" href="<?= Security::e(APP_URL) ?>/index.php">Maxlond</a>
    <a class="mobile-notifications" href="<?= Security::e(pageUrl($notificationPath)) ?>" aria-label="الإشعارات">
        <?= icon('bell') ?><?php if ($unreadCount > 0): ?><span class="badge" id="notifBadge"><?= $unreadCount ?></span><?php endif; ?>
    </a>
</header>
<div id="overlay" class="overlay" onclick="closeSidebar()"></div>
<aside id="sidebar" class="sidebar">
    <a class="brand-lockup" href="<?= Security::e(APP_URL) ?>/index.php"><span class="brand-mark">ML</span><span><strong>Maxlond</strong><small>إدارة المشاريع المدنية</small></span></a>
    <div class="sidebar-user"><span class="user-avatar"><?= Security::e(function_exists('mb_substr') ? mb_substr((string) ($_SESSION['full_name'] ?? 'م'), 0, 1, 'UTF-8') : substr((string) ($_SESSION['full_name'] ?? 'ML'), 0, 2)) ?></span><span><strong><?= Security::e($_SESSION['full_name'] ?? '') ?></strong><small><?= ['admin'=>'مدير النظام','accountant'=>'قسم الحسابات','engineer'=>'مهندس موقع'][$currentRole] ?? 'مستخدم' ?></small></span></div>
    <nav class="side-nav" aria-label="القائمة الرئيسية">
        <span class="nav-caption">القائمة الرئيسية</span>
        <?php foreach ($navItems as [$path, $label, $symbol]): ?>
            <a href="<?= Security::e(pageUrl($path)) ?>" class="nav-link<?= basename((string) ($_SERVER['SCRIPT_NAME'] ?? '')) === basename($path) ? ' active' : '' ?>"><?= icon($symbol) ?><span><?= Security::e($label) ?></span>
                <?php if ($path === $notificationPath && $unreadCount > 0): ?><span class="nav-count"><?= $unreadCount ?></span><?php endif; ?>
            </a>
        <?php endforeach; ?>
    </nav>
    <a class="nav-link logout-link" href="<?= Security::e(APP_URL) ?>/logout.php"><?= icon('logout') ?><span>تسجيل الخروج</span></a>
    <div class="sidebar-foot"><span>الإصدار <?= Security::e(APP_VERSION) ?></span><span class="online-dot">متصل</span></div>
</aside>