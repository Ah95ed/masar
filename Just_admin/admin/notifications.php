<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';
Auth::requireRole('admin','accountant');
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    Security::requireCsrf();
    $operation = Security::clean($_POST['op'] ?? '', 10);
    if ($operation === 'all') db()->prepare('UPDATE notifications SET is_read=1 WHERE user_id=?')->execute([Auth::id()]);
    else {
        $id = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT);
        if ($id) db()->prepare('UPDATE notifications SET is_read=1 WHERE id=? AND user_id=?')->execute([$id, Auth::id()]);
    }
    redirect('admin/notifications.php');
}
$statement = db()->prepare('SELECT * FROM notifications WHERE user_id=? ORDER BY created_at DESC LIMIT 100');
$statement->execute([Auth::id()]);
$notifications = $statement->fetchAll();
$pageTitle = 'الإشعارات';
require __DIR__ . '/../header.php';
?>
<main class="main-content"><div class="page-wrap"><div class="page-header"><div><h1>الإشعارات</h1><p>آخر التنبيهات المتعلقة بالنظام</p></div><form method="post"><?= Security::csrfField() ?><input type="hidden" name="op" value="all"><button class="btn btn-quiet" type="submit">تعليم الكل كمقروء</button></form></div><section class="panel"><?php foreach ($notifications as $notification): ?><article class="list-row" style="align-items:flex-start"><span class="stat-icon" style="--accent:<?= $notification['type']==='danger'?'var(--red)':($notification['type']==='warning'?'var(--amber)':'var(--cyan)') ?>"><?= icon('bell') ?></span><div style="flex:1"><strong><?= Security::e($notification['title']) ?><?= !(int) $notification['is_read'] ? ' · جديد' : '' ?></strong><small><?= Security::e($notification['message']) ?></small><small><?= Security::e($notification['created_at']) ?></small><?php if (!empty($notification['link']) && preg_match('/^(admin|engineer)\/[a-z_]+\.php(?:\?[a-zA-Z0-9_=&%-]*)?$/', (string) $notification['link'])): ?><a class="btn btn-quiet btn-sm" style="margin-top:8px" href="<?= Security::e(pageUrl((string) $notification['link'])) ?>">فتح</a><?php endif; ?></div><?php if (!(int) $notification['is_read']): ?><form method="post"><?= Security::csrfField() ?><input type="hidden" name="id" value="<?= (int) $notification['id'] ?>"><button class="btn btn-quiet btn-sm">تمت القراءة</button></form><?php endif; ?></article><?php endforeach; ?><?php if ($notifications === []): ?><div class="empty-state">لا توجد إشعارات</div><?php endif; ?></section></div></main><?php require __DIR__ . '/../footer.php'; ?>