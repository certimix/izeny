<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Auth.php';

class MessageController
{
    /**
     * Lista conversas recentes do usuário logado
     */
    public static function conversations(): void
    {
        $user = Auth::requireAuth();
        $pdo = Database::getConnection();

        $sql = "SELECT 
                    CASE WHEN m.sender_id = :uid THEN m.receiver_id ELSE m.sender_id END as other_user_id,
                    MAX(m.id) as last_msg_id
                FROM messages m
                WHERE m.sender_id = :uid OR m.receiver_id = :uid
                GROUP BY other_user_id
                ORDER BY last_msg_id DESC";

        $stmt = $pdo->prepare($sql);
        $stmt->execute([':uid' => $user['id']]);
        $convs = $stmt->fetchAll();

        $items = [];
        foreach ($convs as $c) {
            $otherId = $c['other_user_id'];
            $uStmt = $pdo->prepare("SELECT id, name, username, avatar FROM users WHERE id = ?");
            $uStmt->execute([$otherId]);
            $otherUser = $uStmt->fetch();

            $mStmt = $pdo->prepare("SELECT text, created_at, sender_id FROM messages WHERE id = ?");
            $mStmt->execute([$c['last_msg_id']]);
            $lastMsg = $mStmt->fetch();

            $unreadStmt = $pdo->prepare("SELECT COUNT(*) FROM messages WHERE sender_id = ? AND receiver_id = ? AND read_at IS NULL");
            $unreadStmt->execute([$otherId, $user['id']]);
            $unread = (int)$unreadStmt->fetchColumn();

            if ($otherUser && $lastMsg) {
                $items[] = [
                    'other_user'   => $otherUser,
                    'last_message' => $lastMsg['text'],
                    'last_time'    => $lastMsg['created_at'],
                    'is_mine'      => ($lastMsg['sender_id'] == $user['id']),
                    'unread_count' => $unread,
                ];
            }
        }

        echo json_encode(['items' => $items]);
    }

    /**
     * Lista mensagens de uma conversa com outro usuário
     */
    public static function show(int $otherUserId): void
    {
        $user = Auth::requireAuth();
        $pdo = Database::getConnection();

        // Marcar mensagens recebidas como lidas
        $pdo->prepare("UPDATE messages SET read_at = NOW() WHERE sender_id = ? AND receiver_id = ? AND read_at IS NULL")
            ->execute([$otherUserId, $user['id']]);

        $sql = "SELECT id, sender_id, receiver_id, text, media_url, read_at, created_at
                FROM messages
                WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)
                ORDER BY created_at ASC";

        $stmt = $pdo->prepare($sql);
        $stmt->execute([$user['id'], $otherUserId, $otherUserId, $user['id']]);
        $messages = $stmt->fetchAll();

        echo json_encode(['items' => $messages]);
    }

    /**
     * Envia uma mensagem direta
     */
    public static function send(int $otherUserId): void
    {
        $user = Auth::requireAuth();
        $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $text = trim($input['text'] ?? '');

        if (!$text) {
            http_response_code(422);
            echo json_encode(['error' => 'A mensagem não pode estar vazia.']);
            return;
        }

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("INSERT INTO messages (sender_id, receiver_id, text) VALUES (?, ?, ?)");
        $stmt->execute([$user['id'], $otherUserId, $text]);
        $msgId = $pdo->lastInsertId();

        echo json_encode([
            'success' => true,
            'message' => [
                'id'          => (string)$msgId,
                'sender_id'   => (string)$user['id'],
                'receiver_id' => (string)$otherUserId,
                'text'        => $text,
                'created_at'  => date('Y-m-d H:i:s'),
            ]
        ]);
    }
}
