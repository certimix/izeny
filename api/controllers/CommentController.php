<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Auth.php';

class CommentController
{
    public static function index(int $postId): void
    {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT c.id, c.post_id, c.user_id, c.text, c.created_at,
                                      u.name, u.username, u.avatar
                               FROM comments c
                               INNER JOIN users u ON c.user_id = u.id
                               WHERE c.post_id = ?
                               ORDER BY c.created_at ASC");
        $stmt->execute([$postId]);
        $rows = $stmt->fetchAll();

        $comments = array_map(function ($c) {
            return [
                'id'         => (string)$c['id'],
                'post_id'    => (string)$c['post_id'],
                'user_id'    => (string)$c['user_id'],
                'text'       => $c['text'],
                'created_at' => $c['created_at'],
                'user'       => [
                    'id'       => (string)$c['user_id'],
                    'name'     => $c['name'],
                    'username' => $c['username'],
                    'avatar'   => $c['avatar'],
                ]
            ];
        }, $rows);

        echo json_encode(['items' => $comments]);
    }

    public static function store(int $postId): void
    {
        $user = Auth::requireAuth();
        $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $text = trim($input['text'] ?? '');

        if (!$text) {
            http_response_code(422);
            echo json_encode(['error' => 'O comentário não pode estar vazio.']);
            return;
        }

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("INSERT INTO comments (post_id, user_id, text) VALUES (?, ?, ?)");
        $stmt->execute([$postId, $user['id'], $text]);
        $commentId = $pdo->lastInsertId();

        $pdo->prepare("UPDATE posts SET comments_count = comments_count + 1 WHERE id = ?")->execute([$postId]);

        echo json_encode([
            'success' => true,
            'comment' => [
                'id'         => (string)$commentId,
                'post_id'    => (string)$postId,
                'user_id'    => (string)$user['id'],
                'text'       => $text,
                'created_at' => date('Y-m-d H:i:s'),
                'user'       => $user,
            ]
        ]);
    }

    public static function delete(int $id): void
    {
        $user = Auth::requireAuth();
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("SELECT post_id FROM comments WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $user['id']]);
        $comment = $stmt->fetch();

        if (!$comment) {
            http_response_code(403);
            echo json_encode(['error' => 'Comentário não encontrado ou sem permissão.']);
            return;
        }

        $pdo->prepare("DELETE FROM comments WHERE id = ?")->execute([$id]);
        $pdo->prepare("UPDATE posts SET comments_count = GREATEST(0, comments_count - 1) WHERE id = ?")->execute([$comment['post_id']]);

        echo json_encode(['success' => true]);
    }
}
