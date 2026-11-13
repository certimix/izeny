<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/Database.php';

class Auth
{
    /**
     * Gera um token seguro HMAC-SHA256 para o usuário
     */
    public static function createToken(array $user): string
    {
        $header = base64_encode(json_encode(['typ' => 'JWT', 'alg' => 'HS256']));
        $payload = base64_encode(json_encode([
            'sub'      => $user['id'],
            'username' => $user['username'],
            'email'    => $user['email'],
            'role'     => $user['role'] ?? 'tecnico',
            'exp'      => time() + (86400 * JWT_EXPIRY_DAYS),
        ]));

        $signature = hash_hmac('sha256', "$header.$payload", JWT_SECRET, true);
        $sigEncoded = base64_encode($signature);

        return "$header.$payload.$sigEncoded";
    }

    /**
     * Valida o token e retorna o ID do usuário ou null
     */
    public static function validateToken(?string $token): ?array
    {
        if (!$token) return null;

        $parts = explode('.', $token);
        if (count($parts) !== 3) return null;

        [$headerB64, $payloadB64, $sigB64] = $parts;
        $expectedSig = base64_encode(hash_hmac('sha256', "$headerB64.$payloadB64", JWT_SECRET, true));

        if (!hash_equals($expectedSig, $sigB64)) {
            return null;
        }

        $payload = json_decode(base64_decode($payloadB64), true);
        if (!$payload || !isset($payload['exp']) || $payload['exp'] < time()) {
            return null;
        }

        return $payload;
    }

    /**
     * Retorna o usuário logado a partir do cabeçalho Authorization ou Cookie
     */
    public static function getCurrentUser(): ?array
    {
        $token = null;
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
        if (preg_match('/Bearer\s+(\S+)/i', $authHeader, $matches)) {
            $token = $matches[1];
        } elseif (!empty($_COOKIE['izeny_token'])) {
            $token = $_COOKIE['izeny_token'];
        }

        $payload = self::validateToken($token);
        if (!$payload) return null;

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT id, name, username, email, avatar, banner, bio, location, website, role, verified, created_at FROM users WHERE id = ?");
        $stmt->execute([$payload['sub']]);
        return $stmt->fetch() ?: null;
    }

    /**
     * Exige autenticação e encerra com 401 caso não autenticado
     */
    public static function requireAuth(): array
    {
        $user = self::getCurrentUser();
        if (!$user) {
            http_response_code(401);
            echo json_encode(['error' => 'Não autorizado. Faça login para continuar.']);
            exit;
        }
        return $user;
    }
}
