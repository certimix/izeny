<?php
// iZeny API - Front Controller PHP 8.3 Nativo

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/Database.php';
require_once __DIR__ . '/Auth.php';

require_once __DIR__ . '/controllers/AuthController.php';
require_once __DIR__ . '/controllers/PostController.php';
require_once __DIR__ . '/controllers/CommentController.php';
require_once __DIR__ . '/controllers/UserController.php';
require_once __DIR__ . '/controllers/MessageController.php';
require_once __DIR__ . '/controllers/TrendController.php';
require_once __DIR__ . '/controllers/StreamController.php';

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

// Normaliza URI removendo prefixo /api se presente
$path = preg_replace('#^/api#', '', $uri);
$path = rtrim($path, '/');
if ($path === '') $path = '/';

try {
    // Rotas de Autenticação
    if ($path === '/auth/register' && $method === 'POST') {
        AuthController::register();
    } elseif ($path === '/auth/login' && $method === 'POST') {
        AuthController::login();
    } elseif ($path === '/auth/me' && $method === 'GET') {
        AuthController::me();
    } elseif ($path === '/auth/profile' && $method === 'POST') {
        AuthController::updateProfile();
    }

    // Rotas de Postagens
    elseif ($path === '/posts' && $method === 'GET') {
        PostController::index();
    } elseif ($path === '/posts' && $method === 'POST') {
        PostController::create();
    } elseif (preg_match('#^/posts/(\d+)$#', $path, $m) && $method === 'DELETE') {
        PostController::delete((int)$m[1]);
    } elseif (preg_match('#^/posts/(\d+)/like$#', $path, $m) && $method === 'POST') {
        PostController::toggleLike((int)$m[1]);
    }

    // Rotas de Comentários
    elseif (preg_match('#^/posts/(\d+)/comments$#', $path, $m) && $method === 'GET') {
        CommentController::index((int)$m[1]);
    } elseif (preg_match('#^/posts/(\d+)/comments$#', $path, $m) && $method === 'POST') {
        CommentController::store((int)$m[1]);
    } elseif (preg_match('#^/comments/(\d+)$#', $path, $m) && $method === 'DELETE') {
        CommentController::delete((int)$m[1]);
    }

    // Rotas de Usuários
    elseif ($path === '/users' && $method === 'GET') {
        UserController::index();
    } elseif (preg_match('#^/users/([a-zA-Z0-9_\-\.]+)$#', $path, $m) && $method === 'GET') {
        UserController::show($m[1]);
    } elseif (preg_match('#^/users/(\d+)/follow$#', $path, $m) && $method === 'POST') {
        UserController::toggleFollow((int)$m[1]);
    }

    // Rotas de Mensagens
    elseif ($path === '/messages' && $method === 'GET') {
        MessageController::conversations();
    } elseif (preg_match('#^/messages/(\d+)$#', $path, $m) && $method === 'GET') {
        MessageController::show((int)$m[1]);
    } elseif (preg_match('#^/messages/(\d+)$#', $path, $m) && $method === 'POST') {
        MessageController::send((int)$m[1]);
    }

    // Rotas de Tendências e Stream SSE
    elseif ($path === '/trends' && $method === 'GET') {
        TrendController::index();
    } elseif (($path === '/stream' || $path === '/realtime') && $method === 'GET') {
        StreamController::subscribe();
    }

    // Health check
    elseif ($path === '/health' || $path === '/') {
        echo json_encode([
            'status'     => 'online',
            'engine'     => 'PHP 8.3 FastCGI (FPM)',
            'database'   => 'MariaDB 10.11 utf8mb4',
            'ecosystem'  => 'ZenyDesk Suite',
            'developer'  => CANONICAL_AUTHOR_NAME,
            'time'       => date('Y-m-d H:i:s'),
        ]);
    } else {
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint não encontrado no backend PHP: ' . $path]);
    }
} catch (\Throwable $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Erro interno no backend PHP: ' . $e->getMessage()]);
}
