<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Auth.php';

class UserController
{
    /**
     * Lista técnicos recomendados / busca
     */
    public static function index(): void
    {
        $currentUser = Auth::getCurrentUser();
        $query = trim($_GET['q'] ?? '');
        $limit = min(30, max(1, (int)($_GET['limit'] ?? 10)));

        $pdo = Database::getConnection();
        $params = [];
        $where = ["u.verified = 1"];

        if ($query) {
            $where[] = "(u.name LIKE ? OR u.username LIKE ? OR u.bio LIKE ?)";
            $params[] = "%{$query}%";
            $params[] = "%{$query}%";
            $params[] = "%{$query}%";
        }

        if ($currentUser) {
            $where[] = "u.id != ?";
            $params[] = $currentUser['id'];
        }

        $whereClause = 'WHERE ' . implode(' AND ', $where);

        $sql = "SELECT u.id, u.name, u.username, u.avatar, u.bio, u.location, u.role, u.verified
                FROM users u
                {$whereClause}
                ORDER BY u.id ASC
                LIMIT ?";

        $stmt = $pdo->prepare($sql);
        $idx = 1;
        foreach ($params as $param) {
            $stmt->bindValue($idx++, $param);
        }
        $stmt->bindValue($idx++, $limit, PDO::PARAM_INT);
        $stmt->execute();
        $users = $stmt->fetchAll();

        // Checar se o usuário atual já segue
        $followingIds = [];
        if ($currentUser && $users) {
            $targetIds = array_column($users, 'id');
            $inClause = implode(',', array_fill(0, count($targetIds), '?'));
            $fStmt = $pdo->prepare("SELECT following_id FROM follows WHERE follower_id = ? AND following_id IN ({$inClause})");
            $fStmt->execute(array_merge([$currentUser['id']], $targetIds));
            $followingIds = $fStmt->fetchAll(PDO::FETCH_COLUMN);
        }

        $items = array_map(function ($u) use ($followingIds) {
            return [
                'id'           => (string)$u['id'],
                'name'         => $u['name'],
                'username'     => $u['username'],
                'avatar'       => $u['avatar'],
                'bio'          => $u['bio'],
                'location'     => $u['location'],
                'role'         => $u['role'],
                'verified'     => (bool)$u['verified'],
                'is_following' => in_array($u['id'], $followingIds),
            ];
        }, $users);

        echo json_encode(['items' => $items]);
    }

    /**
     * Retorna perfil do usuário com contagens de posts, seguidores e seguindo
     */
    public static function show(string $username): void
    {
        $currentUser = Auth::getCurrentUser();
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("SELECT id, name, username, email, avatar, banner, bio, location, website, role, verified, created_at FROM users WHERE username = ?");
        $stmt->execute([$username]);
        $user = $stmt->fetch();

        if (!$user) {
            http_response_code(404);
            echo json_encode(['error' => 'Usuário não encontrado.']);
            return;
        }

        $userId = $user['id'];
        $postsCount = (int)$pdo->query("SELECT COUNT(*) FROM posts WHERE user_id = {$userId}")->fetchColumn();
        $followersCount = (int)$pdo->query("SELECT COUNT(*) FROM follows WHERE following_id = {$userId}")->fetchColumn();
        $followingCount = (int)$pdo->query("SELECT COUNT(*) FROM follows WHERE follower_id = {$userId}")->fetchColumn();

        $isFollowing = false;
        if ($currentUser) {
            $check = $pdo->prepare("SELECT id FROM follows WHERE follower_id = ? AND following_id = ?");
            $check->execute([$currentUser['id'], $userId]);
            $isFollowing = (bool)$check->fetch();
        }

        echo json_encode([
            'user'            => $user,
            'posts_count'     => $postsCount,
            'followers_count' => $followersCount,
            'following_count' => $followingCount,
            'is_following'    => $isFollowing,
        ]);
    }

    /**
     * Seguir / Deixar de seguir
     */
    public static function toggleFollow(int $targetId): void
    {
        $user = Auth::requireAuth();
        if ($user['id'] === $targetId) {
            http_response_code(400);
            echo json_encode(['error' => 'Você não pode seguir a si mesmo.']);
            return;
        }

        $pdo = Database::getConnection();
        $check = $pdo->prepare("SELECT id FROM follows WHERE follower_id = ? AND following_id = ?");
        $check->execute([$user['id'], $targetId]);
        $follow = $check->fetch();

        if ($follow) {
            $pdo->prepare("DELETE FROM follows WHERE follower_id = ? AND following_id = ?")->execute([$user['id'], $targetId]);
            $isFollowing = false;
        } else {
            $pdo->prepare("INSERT INTO follows (follower_id, following_id) VALUES (?, ?)")->execute([$user['id'], $targetId]);
            $isFollowing = true;
        }

        $count = (int)$pdo->query("SELECT COUNT(*) FROM follows WHERE following_id = {$targetId}")->fetchColumn();
        echo json_encode(['success' => true, 'is_following' => $isFollowing, 'followers_count' => $count]);
    }
}
