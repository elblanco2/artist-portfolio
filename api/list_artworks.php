<?php
/**
 * List artworks for authenticated use (exhibit picker, etc.)
 */
session_start();
header('Content-Type: application/json');

if (!isset($_SESSION['artist_authenticated']) || !$_SESSION['artist_authenticated']) {
    http_response_code(401);
    echo json_encode(['error' => 'Auth required']);
    exit;
}

$uploads_dir = dirname(__DIR__) . '/uploads';
$meta_file = dirname(__DIR__) . '/artwork_meta.json';
$meta = file_exists($meta_file) ? json_decode(file_get_contents($meta_file), true) : [];

$artworks = [];
if (is_dir($uploads_dir)) {
    foreach (glob($uploads_dir . '/*.{jpg,jpeg,png,gif,webp}', GLOB_BRACE) as $file) {
        $basename = basename($file);
        if (preg_match('/_(large|medium|small|social|map)\.[^.]+$/', $basename)) continue;

        $name = pathinfo($basename, PATHINFO_FILENAME);
        $ext = pathinfo($basename, PATHINFO_EXTENSION);
        $thumb_file = $name . '_small.' . $ext;
        $thumbnail = file_exists($uploads_dir . '/' . $thumb_file) ? '/uploads/' . $thumb_file : '/uploads/' . $basename;

        $m = $meta[$basename] ?? [];
        $artworks[] = [
            'original' => $basename,
            'thumbnail' => $thumbnail,
            'title' => $m['title'] ?? $name
        ];
    }
}

echo json_encode(['artworks' => $artworks]);
