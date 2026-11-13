import type { User, Post, Comment, Message } from '../types';

// =========================================================================
// iZeny PHP 8.3 API Client Adapter
// Conecta 100% das operações ao backend PHP 8.3 nativo rodando em FastCGI (FPM)
// e banco de dados MariaDB corporativo.
// =========================================================================

const TOKEN_KEY = 'izeny_jwt_token';
const USER_KEY = 'izeny_auth_user';

export const pb = {
  authStore: {
    get token(): string {
      return localStorage.getItem(TOKEN_KEY) || '';
    },
    get model(): User | null {
      const u = localStorage.getItem(USER_KEY);
      if (!u) return null;
      try {
        return JSON.parse(u);
      } catch {
        return null;
      }
    },
    get isValid(): boolean {
      return !!this.token && !!this.model;
    },
    save(token: string, model: User) {
      localStorage.setItem(TOKEN_KEY, token);
      localStorage.setItem(USER_KEY, JSON.stringify(model));
    },
    clear() {
      localStorage.removeItem(TOKEN_KEY);
      localStorage.removeItem(USER_KEY);
    }
  },

  collection(name: string) {
    const token = this.authStore.token;
    const authHeaders: Record<string, string> = token ? { Authorization: `Bearer ${token}` } : {};

    return {
      // 1. Autenticação com Senha (PHP /api/auth/login)
      async authWithPassword(identity: string, password: string):Promise<{ token: string; record: User }> {
        const res = await fetch('/api/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ identity, password })
        });
        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.error || 'Credenciais inválidas');
        }
        pb.authStore.save(data.token, data.user);
        return { token: data.token, record: data.user };
      },

      // 2. Listagem genérica (Posts, Users, Comments, Messages)
      async getList<T = any>(page = 1, limit = 20, options: any = {}): Promise<{ items: T[]; totalItems: number }> {
        if (name === 'posts') {
          const tab = options?.filter?.includes('following') ? 'seguindo' : 'para_voce';
          let url = `/api/posts?page=${page}&limit=${limit}&tab=${tab}`;
          if (options?.username) url += `&username=${encodeURIComponent(options.username)}`;
          if (options?.hashtag) url += `&hashtag=${encodeURIComponent(options.hashtag)}`;
          
          const res = await fetch(url, { headers: authHeaders });
          const data = await res.json();
          return { items: (data.items || []) as T[], totalItems: data.total || 0 };
        }

        if (name === 'users') {
          const query = options?.query || '';
          const url = `/api/users?limit=${limit}&q=${encodeURIComponent(query)}`;
          const res = await fetch(url, { headers: authHeaders });
          const data = await res.json();
          return { items: (data.items || []) as T[], totalItems: data.items?.length || 0 };
        }

        if (name === 'comments') {
          // Extrai postId da query filter: 'post = "X"'
          let postId = '0';
          if (options?.filter) {
            const m = options.filter.match(/post\s*=\s*"?([0-9a-zA-Z]+)"?/);
            if (m) postId = m[1];
          }
          const res = await fetch(`/api/posts/${postId}/comments`, { headers: authHeaders });
          const data = await res.json();
          return { items: (data.items || []) as T[], totalItems: data.items?.length || 0 };
        }

        if (name === 'messages') {
          let otherId = '0';
          if (options?.filter) {
            const m = options.filter.match(/receiver\s*=\s*"?([0-9a-zA-Z]+)"?/);
            if (m) otherId = m[1];
          }
          const res = await fetch(`/api/messages/${otherId}`, { headers: authHeaders });
          const data = await res.json();
          return { items: (data.items || []) as T[], totalItems: data.items?.length || 0 };
        }

        return { items: [], totalItems: 0 };
      },

      // 3. Obter primeiro item (Perfil de Usuário)
      async getFirstListItem<T = any>(filter: string): Promise<T> {
        let username = '';
        const m = filter.match(/username\s*=\s*"?([0-9a-zA-Z_\-\.]+)"?/);
        if (m) username = m[1];

        const res = await fetch(`/api/users/${username}`, { headers: authHeaders });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Usuário não encontrado');
        return data.user as T;
      },

      // 4. Criação (Posts, Users, Comments, Messages)
      async create<T = any>(body: any, _options?: any): Promise<T> {
        if (name === 'users') {
          const res = await fetch('/api/auth/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
          });
          const data = await res.json();
          if (!res.ok) throw new Error(data.error || 'Falha ao criar conta');
          pb.authStore.save(data.token, data.user);
          return data.user as T;
        }

        if (name === 'posts') {
          let postBody: any;
          let headers: Record<string, string> = { ...authHeaders };

          if (body instanceof FormData) {
            postBody = body;
          } else {
            postBody = JSON.stringify(body);
            headers['Content-Type'] = 'application/json';
          }

          const res = await fetch('/api/posts', {
            method: 'POST',
            headers,
            body: postBody
          });
          const data = await res.json();
          if (!res.ok) throw new Error(data.error || 'Falha ao criar post');
          return data.post as T;
        }

        if (name === 'comments') {
          const postId = body.post || body.post_id;
          const res = await fetch(`/api/posts/${postId}/comments`, {
            method: 'POST',
            headers: { ...authHeaders, 'Content-Type': 'application/json' },
            body: JSON.stringify({ text: body.text })
          });
          const data = await res.json();
          if (!res.ok) throw new Error(data.error || 'Falha ao comentar');
          return data.comment as T;
        }

        if (name === 'messages') {
          const receiverId = body.receiver || body.receiver_id;
          const res = await fetch(`/api/messages/${receiverId}`, {
            method: 'POST',
            headers: { ...authHeaders, 'Content-Type': 'application/json' },
            body: JSON.stringify({ text: body.text })
          });
          const data = await res.json();
          if (!res.ok) throw new Error(data.error || 'Falha ao enviar mensagem');
          return data.message as T;
        }

        throw new Error(`Collection ${name} não suportada`);
      },

      // 5. Atualização (Curtir post, Atualizar perfil)
      async update<T = any>(id: string, body: any): Promise<T> {
        if (name === 'posts') {
          // Toggle Like
          const res = await fetch(`/api/posts/${id}/like`, {
            method: 'POST',
            headers: authHeaders
          });
          const data = await res.json();
          return data as T;
        }

        if (name === 'users') {
          // Atualizar perfil
          const res = await fetch('/api/auth/profile', {
            method: 'POST',
            headers: authHeaders,
            body: body instanceof FormData ? body : JSON.stringify(body)
          });
          const data = await res.json();
          if (!res.ok) throw new Error(data.error || 'Falha ao atualizar perfil');
          pb.authStore.save(pb.authStore.token, data.user);
          return data.user as T;
        }

        throw new Error(`Update para ${name} não suportado`);
      },

      // 6. Exclusão (Posts e Comentários)
      async delete(id: string): Promise<boolean> {
        const url = name === 'posts' ? `/api/posts/${id}` : `/api/comments/${id}`;
        const res = await fetch(url, {
          method: 'DELETE',
          headers: authHeaders
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Falha ao excluir');
        return true;
      },

      // 7. Realtime Subscription via Server-Sent Events (SSE) nativo em PHP
      subscribe(topic: string, callback: (data: any) => void) {
        if (typeof window === 'undefined') return;
        try {
          const evtSource = new EventSource('/api/stream');
          evtSource.onmessage = (event) => {
            try {
              const payload = JSON.parse(event.data);
              if (payload.type === 'new_post') {
                callback({ action: 'create', record: payload.post });
              }
            } catch {}
          };
          (window as any).__izeny_sse = evtSource;
        } catch {}
      },

      unsubscribe(_topic: string) {
        if (typeof window === 'undefined') return;
        const sse = (window as any).__izeny_sse;
        if (sse && typeof sse.close === 'function') {
          sse.close();
        }
      }
    };
  }
};

// Funções auxiliares utilitárias
export function getFileUrl(_collection: string, _recordId: string, fileName?: string): string {
  if (!fileName) return '';
  if (fileName.startsWith('http://') || fileName.startsWith('https://')) {
    return fileName;
  }
  return fileName.startsWith('/') ? fileName : `/uploads/${fileName}`;
}

export function getUserAvatar(user?: Partial<User> | null): string {
  if (!user) return '';
  if (user.avatar) {
    return getFileUrl('users', user.id || '', user.avatar);
  }
  return '';
}

export function getCurrentUser(): User | null {
  return pb.authStore.model;
}

export function isAuthenticated(): boolean {
  return pb.authStore.isValid;
}

export function formatRelativeTime(dateString: string): string {
  if (!dateString) return '';
  const now = new Date();
  const date = new Date(dateString);
  const diffMs = now.getTime() - date.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHours = Math.floor(diffMin / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffSec < 60) return 'agora';
  if (diffMin < 60) return `${diffMin}m`;
  if (diffHours < 24) return `${diffHours}h`;
  if (diffDays < 7) return `${diffDays}d`;
  return date.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' });
}
