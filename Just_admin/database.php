<?php
declare(strict_types=1);

define('DB_HOST', 'localhost');
define('DB_NAME', 'spacepoint_recovery_20261002');
define('DB_USER', 'root');
define('DB_PASS', '');
define('SIGNATURE_KEY', getenv('SPACEPOINT_SIGNATURE_KEY') ?: hash('sha256', DB_USER . ':' . DB_PASS . ':SpacePoint-Journal-v2', true));

function db(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
                DB_USER,
                DB_PASS,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                ]
            );
        } catch (PDOException $exception) {
            error_log('Maxlond database error: ' . $exception->getMessage());
            http_response_code(500);
            exit('خطأ في الاتصال بقاعدة البيانات');
        }
    }
    return $pdo;
}