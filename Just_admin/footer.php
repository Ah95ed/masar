<?php
declare(strict_types=1);
?>
<script>window.APP_URL = <?= json_encode(APP_URL, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) ?>;</script>
<script src="<?= Security::e(APP_URL) ?>/assets/js/app.js?v=<?= (int) filemtime(__DIR__ . '/assets/js/app.js') ?>"></script>
</body>
</html>