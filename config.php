<?php
// ============================================================
// AKNAN ERP — Database Configuration
// ============================================================
// Fill in your cPanel MySQL details below, then save this file.
// You get these details after creating a database in cPanel.
// ============================================================

define('DB_HOST',   'localhost');
define('DB_NAME',   'kinetice_aknan_erp');   // e.g. aknan_erp
define('DB_USER',   'kinetice_aknan_erp');   // e.g. aknan_admin
define('DB_PASS',   '03465567120@aknan');
define('APP_URL',   'https://app.aknans.sa');
define('SECRET_KEY','change-this-to-a-long-random-string-32-chars-minimum');

// Session config
ini_set('session.cookie_httponly', 1);
ini_set('session.cookie_samesite', 'Lax');
ini_set('session.gc_maxlifetime', 28800); // 8 hours

// ── Database connection (do not edit below this line) ──────
function get_db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                'mysql:host='.DB_HOST.';dbname='.DB_NAME.';charset=utf8mb4',
                DB_USER,
                DB_PASS,
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES   => false,
                ]
            );
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Database connection failed. Check config.php settings.']);
            exit;
        }
    }
    return $pdo;
}
