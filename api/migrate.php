<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/Database.php';

echo "=== MIGRATION & SEEDER DO iZeny (MariaDB / PHP 8.3) ===\n";

$pdo = Database::getConnection();

// 1. Executar Schema
$sql = file_get_contents(__DIR__ . '/schema.sql');
$pdo->exec($sql);
echo "Tabelas criadas ou já existentes com sucesso no MariaDB!\n";

// 2. Migrar usuários do SQLite / Seed de técnicos do ecossistema
$sqlitePath = '/var/www/izeny/backend/pb_data/data.db';
$usersCount = 0;

if (file_exists($sqlitePath)) {
    echo "Lendo usuários existentes de {$sqlitePath}...\n";
    $sqlitePdo = new PDO("sqlite:{$sqlitePath}");
    $rows = $sqlitePdo->query("SELECT id, name, username, email, avatar, created FROM users")->fetchAll(PDO::FETCH_ASSOC);

    $stmt = $pdo->prepare("INSERT INTO users (pb_id, name, username, email, password_hash, avatar, location, role, verified)
                           VALUES (?, ?, ?, ?, ?, ?, ?, 'tecnico', 1)
                           ON DUPLICATE KEY UPDATE name = VALUES(name), avatar = VALUES(avatar)");

    // Senha padrão para testes de migração (hash bcrypt de '12345678')
    $defaultPass = password_hash('12345678', PASSWORD_BCRYPT);

    foreach ($rows as $u) {
        $stmt->execute([
            $u['id'],
            $u['name'] ?: $u['username'],
            $u['username'],
            $u['email'],
            $defaultPass,
            $u['avatar'] ? "/uploads/{$u['avatar']}" : null,
            'São Paulo, SP'
        ]);
        $usersCount++;
    }
    echo "{$usersCount} usuários migrados do PocketBase para o MariaDB!\n";
}

$totalUsers = $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
echo "Total de usuários ativos no MariaDB: {$totalUsers}\n";
