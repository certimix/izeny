import React, { useState, useEffect } from 'react';
import { 
  ArrowLeft, 
  Calendar, 
  MapPin, 
  ShieldCheck, 
  Edit3, 
  Camera, 
  Loader2 
} from 'lucide-react';
import type { User, Post } from '../types';
import { pb, getUserAvatar } from '../lib/pocketbase';
import { PostCard } from './PostCard';

interface ProfileViewProps {
  currentUser: User | null;
  targetUsername?: string | null;
  onBack: () => void;
  onOpenEditProfile: () => void;
  onOpenComments: (post: Post) => void;
  onOpenAuth: () => void;
}

export const ProfileView: React.FC<ProfileViewProps> = ({
  currentUser,
  targetUsername,
  onBack,
  onOpenEditProfile,
  onOpenComments,
  onOpenAuth,
}) => {
  const [profileUser, setProfileUser] = useState<User | null>(null);
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'posts' | 'replies' | 'media' | 'likes'>('posts');

  const isOwnProfile = !targetUsername || (currentUser && currentUser.username === targetUsername);

  useEffect(() => {
    async function loadProfile() {
      try {
        setLoading(true);
        let u: User | null = null;
        if (isOwnProfile) {
          u = currentUser;
        } else if (targetUsername) {
          u = await pb.collection('users').getFirstListItem<User>(`username = "${targetUsername}"`);
        }

        setProfileUser(u);

        if (u) {
          const userPosts = await pb.collection('posts').getList<Post>(1, 30, {
            filter: `owner = "${u.id}" || ownerId = "${u.id}"`,
            sort: '-created',
            expand: 'owner',
          });
          setPosts(userPosts.items);
        }
      } catch (err) {
        console.warn('Erro ao carregar perfil:', err);
      } finally {
        setLoading(false);
      }
    }

    loadProfile();
  }, [targetUsername, currentUser]);

  const user = profileUser || currentUser;

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] text-blue-500">
        <Loader2 className="w-8 h-8 animate-spin" />
        <span className="text-xs text-slate-400 mt-2">Carregando perfil...</span>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="p-8 text-center">
        <p className="text-slate-500 text-sm">Usuário não encontrado.</p>
        <button onClick={onBack} className="mt-3 px-4 py-2 bg-blue-600 text-white rounded-full text-xs font-bold">
          Voltar
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col min-h-screen bg-white dark:bg-slate-900 border-x border-slate-200 dark:border-slate-800">
      {/* TOP BAR */}
      <div className="sticky top-0 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md px-4 py-2.5 border-b border-slate-200 dark:border-slate-800 flex items-center space-x-6 z-20">
        <button 
          onClick={onBack}
          className="p-2 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div>
          <div className="flex items-center space-x-1.5">
            <h2 className="font-extrabold text-lg text-slate-900 dark:text-white leading-tight">
              {user.name || user.username}
            </h2>
            <ShieldCheck className="w-4 h-4 text-blue-500" />
          </div>
          <span className="text-xs text-slate-400 font-medium">
            {posts.length} {posts.length === 1 ? 'publicação' : 'publicações'}
          </span>
        </div>
      </div>

      {/* COVER BANNER */}
      <div className="h-36 sm:h-48 bg-gradient-to-r from-blue-600 via-indigo-600 to-sky-500 w-full relative">
        <div className="absolute inset-0 bg-black/10"></div>
      </div>

      {/* PROFILE HEADER & AVATAR */}
      <div className="px-4 pb-4">
        <div className="flex justify-between items-end -mt-16 sm:-mt-20 mb-4">
          {/* LARGE AVATAR */}
          <div className="relative w-28 h-28 sm:w-36 sm:h-36 rounded-full border-4 border-white dark:border-slate-900 bg-blue-600 text-white font-extrabold text-4xl flex items-center justify-center overflow-hidden shadow-md">
            {getUserAvatar(user) ? (
              <img src={getUserAvatar(user)} alt={user.name} className="w-full h-full object-cover" />
            ) : (
              <span>{user.name?.[0]?.toUpperCase() || 'U'}</span>
            )}
          </div>

          {/* EDIT PROFILE OR FOLLOW BUTTON */}
          <div>
            {isOwnProfile ? (
              <button
                onClick={onOpenEditProfile}
                className="px-5 py-2 rounded-full border border-slate-300 dark:border-slate-700 font-bold text-sm text-slate-900 dark:text-white hover:bg-slate-100 dark:hover:bg-slate-800 transition flex items-center space-x-1.5 shadow-sm"
              >
                <Edit3 className="w-4 h-4 mr-1 text-slate-500" />
                <span>Editar Perfil</span>
              </button>
            ) : (
              <button
                className="px-6 py-2 rounded-full bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-bold text-sm hover:opacity-90 transition shadow-sm"
              >
                Seguir
              </button>
            )}
          </div>
        </div>

        {/* BIO DETAILS */}
        <div className="space-y-2">
          <div>
            <div className="flex items-center space-x-1.5">
              <h1 className="font-extrabold text-xl text-slate-900 dark:text-white">
                {user.name || user.username}
              </h1>
              <ShieldCheck className="w-5 h-5 text-blue-500" />
            </div>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              @{user.username || 'usuario'}
            </p>
          </div>

          {user.bio ? (
            <p className="text-sm text-slate-800 dark:text-slate-200 leading-relaxed whitespace-pre-wrap">
              {user.bio}
            </p>
          ) : (
            <p className="text-sm text-slate-400 italic">
              Nenhuma biografia adicionada ainda.
            </p>
          )}

          {/* METADATA (LOCATION & JOINED) */}
          <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-500 dark:text-slate-400 pt-1">
            {user.country && (
              <div className="flex items-center space-x-1">
                <MapPin className="w-3.5 h-3.5" />
                <span>{user.country}</span>
              </div>
            )}
            <div className="flex items-center space-x-1">
              <Calendar className="w-3.5 h-3.5" />
              <span>Entrou em {new Date(user.created).toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' })}</span>
            </div>
          </div>

          {/* STATS */}
          <div className="flex space-x-5 text-xs pt-2">
            <div className="flex space-x-1">
              <span className="font-extrabold text-slate-900 dark:text-white">0</span>
              <span className="text-slate-500">Seguindo</span>
            </div>
            <div className="flex space-x-1">
              <span className="font-extrabold text-slate-900 dark:text-white">0</span>
              <span className="text-slate-500">Seguidores</span>
            </div>
          </div>
        </div>
      </div>

      {/* TABS */}
      <div className="flex border-b border-slate-200 dark:border-slate-800 text-sm font-bold text-slate-500 dark:text-slate-400">
        {[
          { id: 'posts', label: 'Publicações' },
          { id: 'replies', label: 'Respostas' },
          { id: 'media', label: 'Mídia' },
          { id: 'likes', label: 'Curtidas' },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className={`flex-1 py-3 text-center transition hover:bg-slate-50 dark:hover:bg-slate-800/50 relative ${
              activeTab === tab.id
                ? 'text-slate-900 dark:text-white font-extrabold'
                : ''
            }`}
          >
            <span>{tab.label}</span>
            {activeTab === tab.id && (
              <div className="absolute bottom-0 left-1/4 right-1/4 h-1 bg-blue-600 rounded-full"></div>
            )}
          </button>
        ))}
      </div>

      {/* POSTS LIST */}
      <div className="flex-1">
        {posts.length === 0 ? (
          <div className="text-center py-12 px-4 text-slate-400">
            <p className="text-sm">Nenhuma publicação encontrada neste perfil.</p>
          </div>
        ) : (
          posts.map((post) => (
            <PostCard
              key={post.id}
              post={post}
              currentUser={currentUser}
              onOpenComments={onOpenComments}
              onPostDeleted={(id) => setPosts((prev) => prev.filter((p) => p.id !== id))}
              onOpenAuth={onOpenAuth}
            />
          ))
        )}
      </div>
    </div>
  );
};
