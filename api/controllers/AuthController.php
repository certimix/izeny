<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Auth.php';

class AuthController
{
    public static function register(): void
    {
        $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $name = trim($input['name'] ?? '');
        $username = strtolower(trim($input['username'] ?? ''));
        $email = strtolower(trim($input['email'] ?? ''));
        $password = $input['password'] ?? '';

        if (!$name || !$username || !$email || strlen($password) < 6) {
            http_response_code(422);
            echo json_encode(['error' => 'Preencha todos os campos. Senha mínima de 6 caracteres.']);
            return;
        }

        $pdo = Database::getConnection();

        // Verificar duplicidade
        $check = $pdo->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
        $check->execute([$username, $email]);
        if ($check->fetch()) {
            http_response_code(409);
            echo json_encode(['error' => 'Nome de usuário ou e-mail já cadastrado.']);
            return;
        }

        $hash = password_hash($password, PASSWORD_BCRYPT);
        $stmt = $pdo->prepare("INSERT INTO users (name, username, email, password_hash) VALUES (?, ?, ?, ?)");
        $stmt->execute([$name, $username, $email, $hash]);

        $userId = $pdo->lastInsertId();
        $user = [
            'id'       => $userId,
            'name'     => $name,
            'username' => $username,
            'email'    => $email,
            'avatar'   => null,
            'role'     => 'tecnico',
        ];

        $token = Auth::createToken($user);
        echo json_encode(['token' => $token, 'user' => $user]);
    }

    public static function login(): void
    {
        $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $identity = trim($input['identity'] ?? $input['email'] ?? $input['username'] ?? '');
        $password = $input['password'] ?? '';

        if (!$identity || !$password) {
            http_response_code(422);
            echo json_encode(['error' => 'Informe seu e-mail/usuário e senha.']);
            return;
        }

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT id, name, username, email, password_hash, avatar, role FROM users WHERE email = ? OR username = ?");
        $stmt->execute([$identity, $identity]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($password, $user['password_hash'])) {
            http_response_code(401);
            echo json_encode(['error' => 'Credenciais inválidas. Verifique seu usuário e senha.']);
            return;
        }

        unset($user['password_hash']);
        $token = Auth::createToken($user);
        echo json_encode(['token' => $token, 'user' => $user]);
    }

    public static function me(): void
    {
        $user = Auth::getCurrentUser();
        if (!$user) {
            http_response_code(401);
            echo json_encode(['user' => null]);
            return;
        }
        echo json_encode(['user' => $user]);
    }

    public static function updateProfile(): void
    {
        $user = Auth::requireAuth();
        $pdo = Database::getConnection();

        $name = trim($_POST['name'] ?? $user['name']);
        $bio = trim($_POST['bio'] ?? $user['bio'] ?? '');
        $location = trim($_POST['location'] ?? $user['location'] ?? 'Brasil');
        $avatarPath = $user['avatar'];

        if (!empty($_FILES['avatar']['tmp_name'])) {
            $ext = strtolower(pathinfo($_FILES['avatar']['name'], PATHINFO_EXTENSION));
            if (in_array($ext, ['jpg', 'jpeg', 'png', 'webp', 'gif'])) {
                $filename = 'avatar_' . $user['id'] . '_' . time() . '.' . $ext;
                $dest = UPLOAD_DIR . '/' . $filename;
                if (!is_dir(UPLOAD_DIR)) mkdir(UPLOAD_DIR, 0755, true);
                if (move_uploaded_file($_FILES['avatar']['tmp_name'], $dest)) {
                    $avatarPath = UPLOAD_URL . '/' . $filename;
                }
            }
        }

        $stmt = $pdo->prepare("UPDATE users SET name = ?, bio = ?, location = ?, avatar = ? WHERE id = ?");
        $stmt->execute([$name, $bio, $location, $avatarPath, $user['id']]);

        $user['name'] = $name;
        $user['bio'] = $bio;
        $user['location'] = $location;
        $user['avatar'] = $avatarPath;

        echo json_encode(['success' => true, 'user' => $user]);
    }
}
