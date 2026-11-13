<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Auth.php';

class PostController
{
    /**
     * Lista posts do feed com paginação e filtros
     */
    public static function index(): void
    {
        $currentUser = Auth::getCurrentUser();
        $tab = $_GET['tab'] ?? 'para_voce'; // 'para_voce' ou 'seguindo'
        $username = $_GET['username'] ?? null;
        $hashtag = $_GET['hashtag'] ?? null;
        $page = max(1, (int)($_GET['page'] ?? 1));
        $limit = min(50, max(1, (int)($_GET['limit'] ?? 20)));
        $offset = ($page - 1) * $limit;

        $pdo = Database::getConnection();
        $params = [];
        $where = [];

        if ($username) {
            $where[] = "u.username = ?";
            $params[] = $username;
        }

        if ($hashtag) {
            $where[] = "p.description LIKE ?";
            $params[] = "%#{$hashtag}%";
        }

        if ($tab === 'seguindo' && $currentUser) {
            $where[] = "p.user_id IN (SELECT following_id FROM follows WHERE follower_id = ?)";
            $params[] = $currentUser['id'];
        }

        $whereClause = $where ? 'WHERE ' . implode(' AND ', $where) : '';

        $sql = "SELECT p.id, p.user_id, p.description, p.location, p.media_json, 
                       p.likes_count, p.comments_count, p.reposts_count, p.created_at,
                       u.name as author_name, u.username as author_username, u.avatar as author_avatar, u.verified as author_verified
                FROM posts p
                INNER JOIN users u ON p.user_id = u.id
                {$whereClause}
                ORDER BY p.created_at DESC
                LIMIT ? OFFSET ?";

        $stmt = $pdo->prepare($sql);
        $idx = 1;
        foreach ($params as $param) {
            $stmt->bindValue($idx++, $param);
        }
        $stmt->bindValue($idx++, $limit, PDO::PARAM_INT);
        $stmt->bindValue($idx++, $offset, PDO::PARAM_INT);
        $stmt->execute();
        $posts = $stmt->fetchAll();

        // Checar se o usuário atual curtiu os posts
        $likedPostIds = [];
        if ($currentUser && $posts) {
            $postIds = array_column($posts, 'id');
            $inClause = implode(',', array_fill(0, count($postIds), '?'));
            $likeStmt = $pdo->prepare("SELECT post_id FROM likes WHERE user_id = ? AND post_id IN ({$inClause})");
            $likeStmt->execute(array_merge([$currentUser['id']], $postIds));
            $likedPostIds = $likeStmt->fetchAll(PDO::FETCH_COLUMN);
        }

        // Formatar resposta
        $items = array_map(function ($p) use ($likedPostIds) {
            $media = json_decode($p['media_json'] ?? '[]', true) ?: [];
            return [
                'id'             => (string)$p['id'],
                'user_id'        => (string)$p['user_id'],
                'description'    => $p['description'],
                'location'       => $p['location'],
                'media'          => $media,
                'likes_count'    => (int)$p['likes_count'],
                'comments_count' => (int)$p['comments_count'],
                'reposts_count'  => (int)$p['reposts_count'],
                'has_liked'      => in_array($p['id'], $likedPostIds),
                'created'        => $p['created_at'],
                'expand'         => [
                    'owner' => [
                        'id'       => (string)$p['user_id'],
                        'name'     => $p['author_name'],
                        'username' => $p['author_username'],
                        'avatar'   => $p['author_avatar'],
                        'verified' => (bool)$p['author_verified'],
                    ]
                ]
            ];
        }, $posts);

        echo json_encode([
            'page'  => $page,
            'items' => $items,
            'total' => count($items),
        ]);
    }

    /**
     * Cria um novo post com foto ou vídeo
     */
    public static function create(): void
    {
        $user = Auth::requireAuth();
        $input = json_decode(file_get_contents('php://input'), true);
        $description = trim($_POST['description'] ?? $input['description'] ?? '');
        $location = trim($_POST['location'] ?? $input['location'] ?? 'iZeny');

        $mediaFiles = [];

        // Upload de mídia
        if (!empty($_FILES['media']['tmp_name'])) {
            $file = $_FILES['media'];
            $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
            $allowed = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'mov', 'webm'];
            if (in_array($ext, $allowed)) {
                $filename = 'post_' . $user['id'] . '_' . uniqid() . '.' . $ext;
                $dest = UPLOAD_DIR . '/' . $filename;
                if (!is_dir(UPLOAD_DIR)) mkdir(UPLOAD_DIR, 0755, true);
                if (move_uploaded_file($file['tmp_name'], $dest)) {
                    $mediaFiles[] = UPLOAD_URL . '/' . $filename;
                }
            }
        }

        if (!$description && empty($mediaFiles)) {
            http_response_code(422);
            echo json_encode(['error' => 'O post não pode estar vazio.']);
            return;
        }

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("INSERT INTO posts (user_id, description, location, media_json) VALUES (?, ?, ?, ?)");
        $stmt->execute([
            $user['id'],
            $description,
            $location,
            json_encode($mediaFiles)
        ]);

        $postId = $pdo->lastInsertId();

        echo json_encode([
            'success' => true,
            'post'    => [
                'id'             => (string)$postId,
                'user_id'        => (string)$user['id'],
                'description'    => $description,
                'location'       => $location,
                'media'          => $mediaFiles,
                'likes_count'    => 0,
                'comments_count' => 0,
                'created'        => date('Y-m-d H:i:s'),
                'expand'         => ['owner' => $user]
            ]
        ]);
    }

    /**
     * Deleta um post próprio
     */
    public static function delete(int $id): void
    {
        $user = Auth::requireAuth();
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("DELETE FROM posts WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $user['id']]);

        if ($stmt->rowCount() > 0) {
            echo json_encode(['success' => true]);
        } else {
            http_response_code(403);
            echo json_encode(['error' => 'Post não encontrado ou você não tem permissão para excluí-lo.']);
        }
    }

    /**
     * Alterna curtida (Like / Unlike)
     */
    public static function toggleLike(int $id): void
    {
        $user = Auth::requireAuth();
        $pdo = Database::getConnection();

        $check = $pdo->prepare("SELECT id FROM likes WHERE post_id = ? AND user_id = ?");
        $check->execute([$id, $user['id']]);
        $like = $check->fetch();

        if ($like) {
            // Descurtir
            $pdo->prepare("DELETE FROM likes WHERE post_id = ? AND user_id = ?")->execute([$id, $user['id']]);
            $pdo->prepare("UPDATE posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = ?")->execute([$id]);
            $hasLiked = false;
        } else {
            // Curtir
            $pdo->prepare("INSERT INTO likes (post_id, user_id) VALUES (?, ?)")->execute([$id, $user['id']]);
            $pdo->prepare("UPDATE posts SET likes_count = likes_count + 1 WHERE id = ?")->execute([$id]);
            $hasLiked = true;
        }

        $count = $pdo->prepare("SELECT likes_count FROM posts WHERE id = ?");
        $count->execute([$id]);
        $newCount = (int)$count->fetchColumn();

        echo json_encode(['success' => true, 'has_liked' => $hasLiked, 'likes_count' => $newCount]);
    }
}
