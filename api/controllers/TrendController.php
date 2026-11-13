<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../Database.php';

class TrendController
{
    public static function index(): void
    {
        $pdo = Database::getConnection();

        // Extrai hashtags mais frequentes das postagens recentes
        $stmt = $pdo->query("SELECT description FROM posts ORDER BY created_at DESC LIMIT 200");
        $posts = $stmt->fetchAll(PDO::FETCH_COLUMN);

        $counts = [];
        foreach ($posts as $desc) {
            if (preg_match_all('/#([a-zA-Z0-9_]+)/u', $desc, $matches)) {
                foreach ($matches[1] as $tag) {
                    $tagLower = strtolower($tag);
                    $counts[$tagLower] = ($counts[$tagLower] ?? 0) + 1;
                }
            }
        }

        // Tópicos oficiais padrão do ecossistema ZenyDesk
        $defaults = [
            'zenydesk'            => ['category' => 'Ecossistema & Comunidade', 'posts' => 128],
            'dicas_tecnicas'      => ['category' => 'Bancada, Placas & Hardware', 'posts' => 94],
            'ti_ajuda'            => ['category' => 'Dúvidas Técnicas & Redes', 'posts' => 76],
            'suporte_direto'      => ['category' => 'Atendimento Especializado', 'posts' => 52],
            'ordem_servico'       => ['category' => 'Gestão & Laudos Map-OS', 'posts' => 41],
            'assistencia_tecnica' => ['category' => 'Oficinas & Reparos', 'posts' => 35],
        ];

        $trends = [];
        foreach ($defaults as $tag => $info) {
            $realCount = $counts[$tag] ?? 0;
            $trends[] = [
                'tag'      => "#{$tag}",
                'category' => $info['category'],
                'posts'    => max($info['posts'], $realCount) . ' posts',
            ];
        }

        echo json_encode(['items' => $trends]);
    }
}
