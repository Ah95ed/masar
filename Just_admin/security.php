<?php
declare(strict_types=1);

class Security
{
    public static function csrfToken(): string
    {
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return (string) $_SESSION['csrf_token'];
    }

    public static function csrfField(): string
    {
        return '<input type="hidden" name="csrf_token" value="' . self::e(self::csrfToken()) . '">';
    }

    public static function verifyCsrf(?string $token): bool
    {
        return $token !== null && $token !== '' && !empty($_SESSION['csrf_token'])
            && hash_equals((string) $_SESSION['csrf_token'], $token);
    }

    public static function requireCsrf(): void
    {
        if (!self::verifyCsrf(isset($_POST['csrf_token']) ? (string) $_POST['csrf_token'] : null)) {
            http_response_code(419);
            exit('انتهت صلاحية الجلسة');
        }
    }

    public static function clean(?string $value, int $max = 5000): string
    {
        $value = trim((string) $value);
        if (function_exists('mb_strlen') && mb_strlen($value, 'UTF-8') > $max) {
            return mb_substr($value, 0, $max, 'UTF-8');
        }
        return strlen($value) > $max ? substr($value, 0, $max) : $value;
    }

    /** @param mixed $value */
    public static function e($value): string
    {
        return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    }

    public static function getClientIp(): string
    {
        foreach (['HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'HTTP_X_REAL_IP', 'REMOTE_ADDR'] as $key) {
            if (!empty($_SERVER[$key])) {
                $candidate = trim(explode(',', (string) $_SERVER[$key])[0]);
                if (filter_var($candidate, FILTER_VALIDATE_IP)) {
                    return $candidate;
                }
            }
        }
        return '0.0.0.0';
    }

    public static function throttle(string $key, int $max, int $window): bool
    {
        $now = time();
        $bucket = isset($_SESSION['_throttle'][$key]) && is_array($_SESSION['_throttle'][$key])
            ? $_SESSION['_throttle'][$key] : [];
        $bucket = array_values(array_filter($bucket, static function ($timestamp) use ($now, $window): bool {
            return is_int($timestamp) && $timestamp > $now - $window;
        }));
        if (count($bucket) >= $max) {
            $_SESSION['_throttle'][$key] = $bucket;
            return false;
        }
        $bucket[] = $now;
        $_SESSION['_throttle'][$key] = $bucket;
        return true;
    }

    public static function fingerprint(?string $clientFingerprint = null): string
    {
        $parts = [
            (string) ($_SERVER['HTTP_USER_AGENT'] ?? ''),
            (string) ($_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? ''),
            self::getClientIp(),
        ];
        $serverFingerprint = hash('sha256', implode('|', $parts));
        if ($clientFingerprint !== null && strlen($clientFingerprint) >= 16) {
            return hash('sha256', $serverFingerprint . '::' . self::clean($clientFingerprint, 128));
        }
        return $serverFingerprint;
    }

    public static function uploadReceipt(array $file): ?array
    {
        if (($file['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) {
            return null;
        }
        if (($file['error'] ?? UPLOAD_ERR_OK) !== UPLOAD_ERR_OK || (int) ($file['size'] ?? 0) > MAX_FILE_SIZE) {
            throw new RuntimeException('الملف غير صالح أو يتجاوز الحجم المسموح');
        }
        $mime = (new finfo(FILEINFO_MIME_TYPE))->file((string) $file['tmp_name']);
        $extensions = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp', 'application/pdf' => 'pdf'];
        if (!isset($extensions[$mime])) {
            throw new RuntimeException('يسمح بصور JPEG وPNG وWebP وملفات PDF فقط');
        }
        $directory = UPLOAD_PATH . 'receipts/';
        if (!is_dir($directory) && !mkdir($directory, 0750, true) && !is_dir($directory)) {
            throw new RuntimeException('تعذر إنشاء مجلد المرفقات');
        }
        $filename = bin2hex(random_bytes(20)) . '.' . $extensions[$mime];
        if (!move_uploaded_file((string) $file['tmp_name'], $directory . $filename)) {
            throw new RuntimeException('تعذر حفظ المرفق');
        }
        return [
            'path' => 'uploads/receipts/' . $filename,
            'name' => self::clean((string) ($file['name'] ?? ''), 255),
            'mime' => $mime,
            'size' => (int) $file['size'],
        ];
    }
}