import 'package:flutter/material.dart';

class I18n {
  static String currentLang = 'pt';
  static final ValueNotifier<String> langNotifier = ValueNotifier<String>('pt');

  static void setLang(String lang) {
    if (['pt', 'en', 'es'].contains(lang)) {
      currentLang = lang;
      langNotifier.value = lang;
    }
  }

  static const Map<String, Map<String, dynamic>> _strings = {
    'pt': {
      'greeting': 'Olá! Bom dia, bem-vindo(a)',
      'welcome_sub': 'À rede social, comunidade e suporte técnico IZeny',
      'bullet_1': 'Conecte-se com técnicos, parceiros e clientes ZenyDesk',
      'bullet_2': 'Compartilhe novidades, fotos e laudos da sua empresa',
      'bullet_3': 'Receba suporte ágil e faça networking qualificado',
      'email': 'E-mail',
      'password': 'Senha',
      'confirm_password': 'Confirmar Senha',
      'username': 'Nome de Usuário',
      'city': 'Cidade / Estado',
      'login_btn': 'ACESSAR',
      'register_btn': 'CRIAR CONTA',
      'forgot_pass': 'Esqueceu sua senha?',
      'no_account': 'Não tem uma conta? Crie sua conta agora!',
      'has_account': 'Já possui uma conta? Acesse agora!',
      'back_home': 'Voltar para a Landing Page',
      'or_continue': 'OU CONTINUE COM',
      'google_continue': 'Continuar com o Google',
      'feeds': 'Feed',
      'search': 'Buscar',
      'notifications': 'Notificações',
      'profile': 'Perfil',
      'chats': 'Mensagens',
      'create_post': 'Novo Post',
      'clear': 'LIMPAR',
      'no_posts': 'Nenhuma publicação ainda. Seja o primeiro a postar!',
      'no_status': 'Nenhum status recente',
      'post_created': 'Publicação criada com sucesso!',
      'download_apk': 'Baixar App Android (.apk)',
    },
    'en': {
      'greeting': 'Hello! Good morning, welcome',
      'welcome_sub': 'To the IZeny social network, community & tech support',
      'bullet_1': 'Connect with ZenyDesk technicians, partners and clients',
      'bullet_2': 'Share business updates, photos and repair worklogs',
      'bullet_3': 'Get fast support and build professional networking',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'username': 'Username',
      'city': 'City / State',
      'login_btn': 'SIGN IN',
      'register_btn': 'CREATE ACCOUNT',
      'forgot_pass': 'Forgot password?',
      'no_account': 'Don\'t have an account? Sign up now!',
      'has_account': 'Already have an account? Sign in here!',
      'back_home': 'Back to Home Page',
      'or_continue': 'OR CONTINUE WITH',
      'google_continue': 'Continue with Google',
      'feeds': 'Feed',
      'search': 'Search',
      'notifications': 'Notifications',
      'profile': 'Profile',
      'chats': 'Messages',
      'create_post': 'New Post',
      'clear': 'CLEAR',
      'no_posts': 'No posts yet. Be the first to share!',
      'no_status': 'No recent status',
      'post_created': 'Post created successfully!',
      'download_apk': 'Download Android App (.apk)',
    },
    'es': {
      'greeting': '¡Hola! Buenos días, bienvenido(a)',
      'welcome_sub': 'A la red social, comunidad y soporte técnico IZeny',
      'bullet_1': 'Conéctate con técnicos, socios y clientes de ZenyDesk',
      'bullet_2': 'Comparte novedades, fotos y reportes de tu empresa',
      'bullet_3': 'Recibe soporte rápido y genera networking profesional',
      'email': 'Correo electrónico',
      'password': 'Contraseña',
      'confirm_password': 'Confirmar Contraseña',
      'username': 'Nombre de Usuario',
      'city': 'Ciudad / Estado',
      'login_btn': 'ACCEDER',
      'register_btn': 'CREAR CUENTA',
      'forgot_pass': '¿Olvidaste tu contraseña?',
      'no_account': '¿No tienes una cuenta? ¡Crea una ahora!',
      'has_account': '¿Ya tienes una cuenta? ¡Inicia sesión!',
      'back_home': 'Volver a la Página de Inicio',
      'or_continue': 'O CONTINÚA CON',
      'google_continue': 'Continuar con Google',
      'feeds': 'Noticias',
      'search': 'Buscar',
      'notifications': 'Notificaciones',
      'profile': 'Perfil',
      'chats': 'Mensajes',
      'create_post': 'Nueva Publicación',
      'clear': 'LIMPIAR',
      'no_posts': 'No hay publicaciones aún. ¡Sé el primero en compartir!',
      'no_status': 'Sin estados recientes',
      'post_created': '¡Publicación creada con éxito!',
      'download_apk': 'Descargar App Android (.apk)',
    },
  };

  static String t(String key) {
    final langMap = _strings[currentLang] ?? _strings['pt']!;
    return langMap[key] ?? _strings['pt']![key] ?? key;
  }
}
