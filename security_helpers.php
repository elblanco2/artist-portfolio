<?php
/**
 * Security helpers: CSRF tokens and rate limiting
 * Include after session_start() in files that need CSRF or rate limiting.
 */

/**
 * Get or generate CSRF token for current session
 */
function csrf_token() {
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

/**
 * Generate hidden CSRF form field
 */
function csrf_field() {
    return '<input type="hidden" name="csrf_token" value="' . htmlspecialchars(csrf_token()) . '">';
}

/**
 * Verify CSRF token from request (POST body, JSON body, or X-CSRF-Token header)
 * Returns true if valid, sends 403 and exits if invalid.
 */
function require_csrf() {
    $token = $_POST['csrf_token']
        ?? $_SERVER['HTTP_X_CSRF_TOKEN']
        ?? null;

    // Also check JSON body if not found above
    if (!$token) {
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
        if (strpos($contentType, 'application/json') !== false) {
            $input = json_decode(file_get_contents('php://input'), true);
            $token = $input['csrf_token'] ?? null;
        }
    }

    if (!$token || !isset($_SESSION['csrf_token']) || !hash_equals($_SESSION['csrf_token'], $token)) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Invalid or missing CSRF token']);
        exit;
    }
}

/**
 * Session-based rate limiting
 *
 * @param string $key Unique key for this rate limit
 * @param int $max Maximum attempts allowed
 * @param int $window_seconds Time window in seconds (default 1 hour)
 */
function check_rate_limit($key, $max, $window_seconds = 3600) {
    $count_key = "rl_{$key}_count";
    $window_key = "rl_{$key}_window";
    $current_window = floor(time() / $window_seconds);

    if (!isset($_SESSION[$window_key]) || $_SESSION[$window_key] !== $current_window) {
        $_SESSION[$window_key] = $current_window;
        $_SESSION[$count_key] = 0;
    }

    if ($_SESSION[$count_key] >= $max) {
        http_response_code(429);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Too many requests. Please try again later.']);
        exit;
    }

    $_SESSION[$count_key]++;
}
