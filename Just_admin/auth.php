<?php
declare(strict_types=1);

require_once __DIR__ . '/database.php';
require_once __DIR__ . '/security.php';

class Auth
{
    public static function login(string $username, string $password): array
    {
        $username = Security::clean($username, 100);
        if ($username === '' || $password === '') {
            return ['ok' => false, 'msg' => 'أدخل اسم المستخدم وكلمة المرور'];
        }
        if (!Security::throttle('login_' . Security::getClientIp(), MAX_LOGIN_ATTEMPTS, LOCKOUT_TIME)) {
            return ['ok' => false, 'msg' => 'محاولات كثيرة. حاول لاحقاً'];
        }
        $statement = db()->prepare('SELECT * FROM users WHERE username = ? OR email = ? LIMIT 1');
        $statement->execute([$username, $username]);
        $user = $statement->fetch();
        if (!$user || !password_verify($password, (string) $user['password_hash'])) {
            self::audit(null, 'login_failed', 'user', $user ? (int) $user['id'] : null);
            return ['ok' => false, 'msg' => 'بيانات الدخول غير صحيحة'];
        }
        if ((int) $user['is_active'] !== 1) {
            return ['ok' => false, 'msg' => 'الحساب معطّل'];
        }
        if ($user['approval_status'] !== 'approved') {
            return ['ok' => false, 'msg' => $user['approval_status'] === 'pending' ? 'بانتظار موافقة المدير' : 'تم رفض الحساب'];
        }

        $fingerprint = Security::fingerprint();
        $pdo = db();
        $pdo->prepare('INSERT INTO device_fingerprints (user_id, fingerprint_hash, user_agent, ip_address, last_seen) VALUES (?, ?, ?, ?, NOW()) ON DUPLICATE KEY UPDATE last_seen = NOW()')
            ->execute([(int) $user['id'], $fingerprint, substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 500), Security::getClientIp()]);
        session_regenerate_id(true);
        $_SESSION['user_id'] = (int) $user['id'];
        $_SESSION['username'] = (string) $user['username'];
        $_SESSION['full_name'] = (string) $user['full_name'];
        $_SESSION['role'] = (string) $user['role'];
        $_SESSION['fingerprint'] = $fingerprint;
        $_SESSION['login_time'] = time();
        $_SESSION['last_activity'] = time();
        $pdo->prepare('INSERT INTO sessions (id, user_id, fingerprint_hash, ip_address, user_agent, last_activity) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE user_id = VALUES(user_id), fingerprint_hash = VALUES(fingerprint_hash), last_activity = VALUES(last_activity)')
            ->execute([session_id(), (int) $user['id'], $fingerprint, Security::getClientIp(), substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 500), time()]);
        $pdo->prepare('UPDATE users SET last_login = NOW() WHERE id = ?')->execute([(int) $user['id']]);
        self::audit((int) $user['id'], 'login_success', 'user', (int) $user['id']);
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        return ['ok' => true, 'user' => $user];
    }

    public static function check(): bool
    {
        if (empty($_SESSION['user_id']) || empty($_SESSION['fingerprint'])) {
            return false;
        }
        if (time() - (int) ($_SESSION['last_activity'] ?? 0) > SESSION_LIFETIME) {
            self::logout();
            return false;
        }
        $currentFingerprint = Security::fingerprint();
        if (!hash_equals((string) $_SESSION['fingerprint'], $currentFingerprint)) {
            self::logout();
            return false;
        }
        $statement = db()->prepare('SELECT 1 FROM sessions s JOIN users u ON u.id = s.user_id WHERE s.id = ? AND s.user_id = ? AND s.fingerprint_hash = ? AND u.is_active = 1 AND u.approval_status = ?');
        $statement->execute([session_id(), (int) $_SESSION['user_id'], (string) $_SESSION['fingerprint'], 'approved']);
        if (!$statement->fetchColumn()) {
            self::logout();
            return false;
        }
        db()->prepare('UPDATE sessions SET last_activity = ? WHERE id = ?')->execute([time(), session_id()]);
        $_SESSION['last_activity'] = time();
        return true;
    }

    public static function requireLogin(): void
    {
        if (!self::check()) {
            header('Location: ' . APP_URL . '/login.php');
            exit;
        }
    }

    public static function requireRole(string ...$roles): void
    {
        self::requireLogin();
        if (!in_array((string) ($_SESSION['role'] ?? ''), $roles, true)) {
            http_response_code(403);
            exit('غير مصرح');
        }
    }

    public static function user(): ?array
    {
        if (empty($_SESSION['user_id'])) {
            return null;
        }
        $statement = db()->prepare('SELECT id, full_name, username, email, role, phone, specialization, signature_path, last_login FROM users WHERE id = ?');
        $statement->execute([(int) $_SESSION['user_id']]);
        $user = $statement->fetch();
        return $user ?: null;
    }

    public static function id(): ?int
    {
        return isset($_SESSION['user_id']) ? (int) $_SESSION['user_id'] : null;
    }

    public static function role(): ?string
    {
        return isset($_SESSION['role']) ? (string) $_SESSION['role'] : null;
    }

    public static function isAdmin(): bool
    {
        return self::role() === 'admin';
    }

    public static function logout(): void
    {
        if (!empty($_SESSION['user_id'])) {
            self::audit((int) $_SESSION['user_id'], 'logout', 'user', (int) $_SESSION['user_id']);
            db()->prepare('DELETE FROM sessions WHERE id = ?')->execute([session_id()]);
        }
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $params = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000, $params['path'], $params['domain'], (bool) $params['secure'], (bool) $params['httponly']);
        }
        if (session_status() === PHP_SESSION_ACTIVE) {
            session_destroy();
        }
    }

    private static function audit(?int $userId, string $action, ?string $entityType = null, ?int $entityId = null): void
    {
        try {
            db()->prepare('INSERT INTO audit_log (user_id, action, entity_type, entity_id, ip_address) VALUES (?, ?, ?, ?, ?)')
                ->execute([$userId, $action, $entityType, $entityId, Security::getClientIp()]);
        } catch (Throwable $exception) {
            error_log('Maxlond audit error: ' . $exception->getMessage());
        }
    }
}