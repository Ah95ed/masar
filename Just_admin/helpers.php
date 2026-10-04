<?php
declare(strict_types=1);

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/database.php';
require_once __DIR__ . '/security.php';

function redirect(string $path): void
{
    header('Location: ' . APP_URL . '/' . ltrim($path, '/'));
    exit;
}

function notify(int $userId, string $title, string $message, string $type = 'info', ?string $link = null): void
{
    $statement = db()->prepare('INSERT INTO notifications (user_id, title, message, type, link) VALUES (?, ?, ?, ?, ?)');
    $statement->execute([$userId, Security::clean($title, 255), Security::clean($message, 5000), $type, $link]);
}

function notifyAdmins(string $title, string $message, string $type = 'info', ?string $link = null): void
{
    $statement = db()->prepare("SELECT id FROM users WHERE role = 'admin' AND is_active = 1 AND approval_status = 'approved'");
    $statement->execute();
    foreach ($statement->fetchAll() as $admin) {
        notify((int) $admin['id'], $title, $message, $type, $link);
    }
}

function pageUrl(string $path): string
{
    return APP_URL . '/' . ltrim($path, '/');
}

/** @param int|float|string|null $amount */
function money($amount): string
{
    return number_format((float) $amount, 2, '.', ',');
}

function statusLabel(string $status): string
{
    $labels = [
        'planning' => 'تخطيط', 'active' => 'نشط', 'paused' => 'متوقف', 'completed' => 'مكتمل', 'cancelled' => 'ملغى',
        'available' => 'متاحة', 'in_use' => 'قيد الاستخدام', 'maintenance' => 'صيانة', 'out_of_service' => 'خارج الخدمة',
        'pending' => 'بالانتظار', 'in_progress' => 'قيد التنفيذ', 'review' => 'مراجعة', 'done' => 'منتهية',
        'draft' => 'مسودة', 'submitted' => 'مرسلة', 'approved' => 'معتمدة', 'rejected' => 'مرفوضة',
        'waiting_parts' => 'بانتظار قطع', 'posted' => 'مرحّل', 'adjust' => 'تسوية', 'in' => 'وارد', 'out' => 'صادر',
        'low' => 'منخفضة', 'medium' => 'متوسطة', 'high' => 'عالية', 'urgent' => 'عاجلة',
    ];
    return $labels[$status] ?? $status;
}

function audit(string $action, ?string $entityType = null, ?int $entityId = null, ?string $details = null): void
{
    $userId = array_key_exists('apiUserId', $GLOBALS)
        ? ($GLOBALS['apiUserId'] === null ? null : (int) $GLOBALS['apiUserId'])
        : (class_exists('Auth') ? Auth::id() : null);
    $statement = db()->prepare('INSERT INTO audit_log (user_id, action, entity_type, entity_id, ip_address, details) VALUES (?, ?, ?, ?, ?, ?)');
    $statement->execute([$userId, Security::clean($action, 100), $entityType, $entityId, Security::getClientIp(), $details]);
}

function createJournalEntry(string $description, array $lines, int $createdBy, ?int $siteId = null, ?int $reportId = null, ?string $reference = null): int
{
    $debit = 0.0;
    $credit = 0.0;
    $signedLines = [];
    foreach ($lines as $line) {
        $accountId = (int) ($line['account_id'] ?? 0);
        $lineDebit = round((float) ($line['debit'] ?? 0), 2);
        $lineCredit = round((float) ($line['credit'] ?? 0), 2);
        if ($accountId < 1 || $lineDebit < 0 || $lineCredit < 0 || ($lineDebit > 0 && $lineCredit > 0)) {
            throw new InvalidArgumentException('بيانات أحد بنود القيد غير صالحة');
        }
        $lineDescription = Security::clean((string) ($line['description'] ?? ''), 500);
        $debit += $lineDebit;
        $credit += $lineCredit;
        $signedLines[] = [$accountId, number_format($lineDebit, 2, '.', ''), number_format($lineCredit, 2, '.', ''), $lineDescription];
    }
    if ($lines === [] || abs($debit - $credit) > 0.005) {
        throw new InvalidArgumentException('القيد غير متوازن');
    }
    $pdo = db();
    $ownsTransaction = !$pdo->inTransaction();
    if ($ownsTransaction) {
        $pdo->beginTransaction();
    }
    try {
        $number = 'JE-' . date('Ymd-His') . '-' . random_int(100, 999);
        $signedAt = date('Y-m-d H:i:s');
        $cleanDescription = Security::clean($description, 500);
        $payload = json_encode([$number, $cleanDescription, number_format($debit, 2, '.', ''), number_format($credit, 2, '.', ''), $siteId, $reportId, $reference, $signedLines], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
        $signature = hash_hmac('sha256', $payload, SIGNATURE_KEY);
        $entry = $pdo->prepare('INSERT INTO journal_entries (entry_number, entry_date, description, reference, site_id, report_id, total_debit, total_credit, status, signature_hash, signed_by, signed_at, created_by) VALUES (?, CURRENT_DATE(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $entry->execute([$number, $cleanDescription, $reference, $siteId, $reportId, $debit, $credit, 'posted', $signature, $createdBy, $signedAt, $createdBy]);
        $entryId = (int) $pdo->lastInsertId();
        $insertLine = $pdo->prepare('INSERT INTO journal_entry_lines (entry_id, account_id, debit, credit, description) VALUES (?, ?, ?, ?, ?)');
        $accountType = $pdo->prepare('SELECT type FROM accounts WHERE id = ? FOR UPDATE');
        $updateBalance = $pdo->prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?');
        foreach ($lines as $line) {
            $accountId = (int) $line['account_id'];
            $lineDebit = (float) ($line['debit'] ?? 0);
            $lineCredit = (float) ($line['credit'] ?? 0);
            $insertLine->execute([$entryId, $accountId, $lineDebit, $lineCredit, Security::clean((string) ($line['description'] ?? ''), 500)]);
            $accountType->execute([$accountId]);
            $type = (string) $accountType->fetchColumn();
            $normalDebit = in_array($type, ['asset', 'expense'], true);
            $updateBalance->execute([$normalDebit ? $lineDebit - $lineCredit : $lineCredit - $lineDebit, $accountId]);
        }
        if ($ownsTransaction) {
            $pdo->commit();
        }
        return $entryId;
    } catch (Throwable $exception) {
        if ($ownsTransaction && $pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $exception;
    }
}

function icon(string $name, string $class = 'icon'): string
{
    $paths = [
        'grid' => '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
        'users' => '<path d="M16 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="10" cy="7" r="4"/><path d="M20 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
        'pin' => '<path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0Z"/><circle cx="12" cy="10" r="2.5"/>',
        'truck' => '<path d="M3 7h11v11H3zM14 11h4l3 3v4h-7z"/><circle cx="7.5" cy="19" r="1.5"/><circle cx="17.5" cy="19" r="1.5"/>',
        'tool' => '<path d="M14.7 6.3a5 5 0 0 0-6.4 6.4L3 18l3 3 5.3-5.3a5 5 0 0 0 6.4-6.4L14 13l-3-3z"/>',
        'clipboard' => '<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V2h6v2M8 10h8M8 14h8M8 18h5"/>',
        'chart' => '<path d="M3 3v18h18M8 16v-5M13 16V6M18 16v-8"/>',
        'box' => '<path d="m12 3 9 5-9 5-9-5 9-5Z"/><path d="M3 8v9l9 5 9-5V8M12 13v9"/>',
        'bell' => '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/>',
        'book' => '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2Z"/>',
        'logout' => '<path d="M10 17l5-5-5-5M15 12H3M12 3h6a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-6"/>',
        'menu' => '<path d="M4 6h16M4 12h16M4 18h16"/>',
        'plus' => '<path d="M12 5v14M5 12h14"/>',
        'check' => '<path d="m5 12 4 4L19 6"/>',
        'close' => '<path d="m18 6-12 12M6 6l12 12"/>',
        'search' => '<circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/>',
        'wallet' => '<rect x="3" y="5" width="18" height="15" rx="2"/><path d="M3 9h18M16 15h2"/>',
    ];
    $body = $paths[$name] ?? $paths['grid'];
    return '<svg class="' . Security::e($class) . '" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' . $body . '</svg>';
}