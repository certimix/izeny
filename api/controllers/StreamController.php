<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../Database.php';

class StreamController
{
    /**
     * Endpoint Server-Sent Events (SSE) nativo em PHP para feeds e notificações em tempo real
     */
    public static function subscribe(): void
    {
        header('Content-Type: text/event-stream');
        header('Cache-Control: no-cache');
        header('Connection: keep-alive');
        header('X-Accel-Buffering: no'); // Para o Nginx não fazer buffer

        $pdo = Database::getConnection();
        $lastPostId = (int)$pdo->query("SELECT MAX(id) FROM posts")->fetchColumn();

        // Envia ping inicial
        echo "data: " . json_encode(['type' => 'connected', 'time' => time()]) . "\n\n";
        ob_flush();
        flush();

        $start = time();
        while (time() - $start < 25) { // Mantém conexão viva por até 25s
            sleep(2);

            $currentMax = (int)$pdo->query("SELECT MAX(id) FROM posts")->fetchColumn();
            if ($currentMax > $lastPostId) {
                $stmt = $pdo->prepare("SELECT p.id, p.user_id, p.description, p.location, p.media_json, p.created_at,
                                              u.name as author_name, u.username as author_username, u.avatar as author_avatar
                                       FROM posts p
                                       INNER JOIN users u ON p.user_id = u.id
                                       WHERE p.id > ? ORDER BY p.id ASC");
                $stmt->execute([$lastPostId]);
                $newPosts = $stmt->fetchAll();

                foreach ($newPosts as $p) {
                    $payload = [
                        'type' => 'new_post',
                        'post' => [
                            'id'          => (string)$p['id'],
                            'user_id'     => (string)$p['user_id'],
                            'description' => $p['description'],
                            'location'    => $p['location'],
                            'media'       => json_decode($p['media_json'] ?? '[]', true) ?: [],
                            'created'     => $p['created_at'],
                            'expand'      => [
                                'owner' => [
                                    'id'       => (string)$p['user_id'],
                                    'name'     => $p['author_name'],
                                    'username' => $p['author_username'],
                                    'avatar'   => $p['author_avatar'],
                                ]
                            ]
                        ]
                    ];
                    echo "data: " . json_encode($payload) . "\n\n";
                    ob_flush();
                    flush();
                }
                $lastPostId = $currentMax;
            } else {
                echo ": heartbeat\n\n";
                ob_flush();
                flush();
            }
        }
    }
}
