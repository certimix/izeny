import React, { useState, useEffect } from 'react';
import { 
  Sidebar 
} from './components/Sidebar';
import { 
  RightSidebar 
} from './components/RightSidebar';
import { 
  Composer 
} from './components/Composer';
import { 
  PostCard 
} from './components/PostCard';
import { 
  PostModal 
} from './components/PostModal';
import { 
  ProfileView 
} from './components/ProfileView';
import { 
  EditProfileModal 
} from './components/EditProfileModal';
import { 
  MessagesView 
} from './components/MessagesView';
import { 
  AuthModal 
} from './components/AuthModal';
import type { Post, User } from './types';
import { pb, getCurrentUser, isAuthenticated } from './lib/pocketbase';
import { Loader2, RefreshCw, Feather } from 'lucide-react';

export const App: React.FC = () => {
  const [currentUser, setCurrentUser] = useState<User | null>(getCurrentUser());
  const [currentTab, setCurrentTab] = useState<string>('feed');
  const [posts, setPosts] = useState<Post[]>([]);
  const [loadingPosts, setLoadingPosts] = useState<boolean>(true);
  const [feedFilter, setFeedFilter] = useState<'forYou' | 'following'>('forYou');

  // Modals state
  const [activePost, setActivePost] = useState<Post | null>(null);
  const [isComposeOpen, setIsComposeOpen] = useState<boolean>(false);
  const [isAuthOpen, setIsAuthOpen] = useState<boolean>(false);
  const [isEditProfileOpen, setIsEditProfileOpen] = useState<boolean>(false);
  const [targetUsername, setTargetUsername] = useState<string | null>(null);

  // Load feed posts
  const loadPosts = async () => {
    try {
      setLoadingPosts(true);
      const res = await pb.collection('posts').getList<Post>(1, 50, {
        sort: '-created',
        expand: 'owner',
      });
      setPosts(res.items);
    } catch (err) {
      console.warn('Erro ao carregar posts:', err);
    } finally {
      setLoadingPosts(false);
    }
  };

  useEffect(() => {
    loadPosts();

    // Realtime subscription for instant new posts
    pb.collection('posts').subscribe('*', (e) => {
      if (e.action === 'create') {
        setPosts((prev) => [e.record as any, ...prev]);
      } else if (e.action === 'delete') {
        setPosts((prev) => prev.filter((p) => p.id !== e.record.id));
      }
    });

    return () => {
      pb.collection('posts').unsubscribe('*');
    };
  }, []);

  const handleLogout = () => {
    pb.authStore.clear();
    setCurrentUser(null);
  };

  const handleAuthSuccess = (u: User) => {
    setCurrentUser(u);
    loadPosts();
  };

  const handleProfileUpdated = (u: User) => {
    setCurrentUser(u);
  };

  const handleSelectUser = (username: string) => {
    setTargetUsername(username);
    setCurrentTab('profile');
  };

  const handleSelectHashtag = (tag: string) => {
    setCurrentTab('feed');
    // Filter posts containing hashtag
  };

  const handleSearch = (query: string) => {
    setCurrentTab('explore');
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 flex justify-center selection:bg-blue-500 selection:text-white">
      <div className="w-full max-w-7xl flex justify-between relative">
        {/* LEFT COLUMN: NAVIGATION */}
        <Sidebar
          currentTab={currentTab}
          onSelectTab={(tab) => {
            if (tab === 'profile') setTargetUsername(null);
            setCurrentTab(tab);
          }}
          currentUser={currentUser}
          onOpenCompose={() => setIsComposeOpen(true)}
          onLogout={handleLogout}
          onOpenAuth={() => setIsAuthOpen(true)}
        />

        {/* CENTER COLUMN: FEED / PAGES */}
        <main className="flex-1 max-w-2xl min-h-screen bg-white dark:bg-slate-900 border-x border-slate-200 dark:border-slate-800 pb-20 md:pb-8">
          {currentTab === 'feed' && (
            <>
              {/* STICKY FEED HEADER */}
              <header className="sticky top-0 bg-white/85 dark:bg-slate-900/85 backdrop-blur-md border-b border-slate-200 dark:border-slate-800 z-20 flex flex-col select-none">
                <div className="flex items-center justify-between px-4 py-3">
                  <h1 className="font-extrabold text-xl text-slate-900 dark:text-white tracking-tight">
                    Página Inicial
                  </h1>
                  <button 
                    onClick={loadPosts} 
                    title="Atualizar feed"
                    className="p-1.5 text-slate-500 hover:text-blue-500 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition"
                  >
                    <RefreshCw className={`w-4 h-4 ${loadingPosts ? 'animate-spin text-blue-500' : ''}`} />
                  </button>
                </div>

                {/* TABS: PARA VOCÊ / SEGUINDO */}
                <div className="flex border-t border-slate-100 dark:border-slate-800/80 text-sm font-bold text-slate-500 dark:text-slate-400">
                  <button
                    onClick={() => setFeedFilter('forYou')}
                    className={`flex-1 py-3 text-center transition relative ${
                      feedFilter === 'forYou' ? 'text-slate-900 dark:text-white font-extrabold' : ''
                    }`}
                  >
                    <span>Para você</span>
                    {feedFilter === 'forYou' && (
                      <div className="absolute bottom-0 left-1/3 right-1/3 h-1 bg-blue-600 rounded-full"></div>
                    )}
                  </button>
                  <button
                    onClick={() => {
                      if (!currentUser) setIsAuthOpen(true);
                      else setFeedFilter('following');
                    }}
                    className={`flex-1 py-3 text-center transition relative ${
                      feedFilter === 'following' ? 'text-slate-900 dark:text-white font-extrabold' : ''
                    }`}
                  >
                    <span>Seguindo</span>
                    {feedFilter === 'following' && (
                      <div className="absolute bottom-0 left-1/3 right-1/3 h-1 bg-blue-600 rounded-full"></div>
                    )}
                  </button>
                </div>
              </header>

              {/* POST COMPOSER */}
              <Composer
                currentUser={currentUser}
                onPostCreated={loadPosts}
                onOpenAuth={() => setIsAuthOpen(true)}
              />

              {/* FEED POSTS STREAM */}
              <div>
                {loadingPosts ? (
                  <div className="flex flex-col items-center justify-center py-20 text-blue-500">
                    <Loader2 className="w-8 h-8 animate-spin" />
                    <span className="text-xs text-slate-400 mt-2 font-medium">Carregando feed iZeny...</span>
                  </div>
                ) : posts.length === 0 ? (
                  <div className="text-center py-20 px-6">
                    <div className="w-16 h-16 bg-blue-50 dark:bg-blue-950/40 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                      <Feather className="w-8 h-8" />
                    </div>
                    <h3 className="font-extrabold text-lg text-slate-900 dark:text-white mb-1">
                      Nenhuma publicação ainda
                    </h3>
                    <p className="text-sm text-slate-500 dark:text-slate-400 max-w-sm mx-auto mb-5">
                      Compartilhe um procedimento, dica de bancada ou novidade da sua oficina técnica agora mesmo!
                    </p>
                    <button
                      onClick={() => {
                        if (!currentUser) setIsAuthOpen(true);
                        else setIsComposeOpen(true);
                      }}
                      className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-full font-bold text-sm shadow-md transition"
                    >
                      Criar Primeira Publicação
                    </button>
                  </div>
                ) : (
                  posts.map((post) => (
                    <PostCard
                      key={post.id}
                      post={post}
                      currentUser={currentUser}
                      onOpenComments={(p) => setActivePost(p)}
                      onPostDeleted={(id) => setPosts((prev) => prev.filter((p) => p.id !== id))}
                      onOpenAuth={() => setIsAuthOpen(true)}
                      onSelectUser={handleSelectUser}
                    />
                  ))
                )}
              </div>
            </>
          )}

          {currentTab === 'profile' && (
            <ProfileView
              currentUser={currentUser}
              targetUsername={targetUsername}
              onBack={() => setCurrentTab('feed')}
              onOpenEditProfile={() => setIsEditProfileOpen(true)}
              onOpenComments={(p) => setActivePost(p)}
              onOpenAuth={() => setIsAuthOpen(true)}
            />
          )}

          {currentTab === 'messages' && (
            <MessagesView
              currentUser={currentUser}
              onOpenAuth={() => setIsAuthOpen(true)}
            />
          )}

          {currentTab === 'explore' && (
            <div className="p-4">
              <h2 className="font-extrabold text-xl mb-4 text-slate-900 dark:text-white">Explorar Tendências</h2>
              <p className="text-sm text-slate-500 mb-6">Busque por procedimentos técnicos, reparos de hardware, placas e ecossistema ZenyDesk.</p>
              <div className="space-y-3">
                {posts.map((p) => (
                  <PostCard
                    key={p.id}
                    post={p}
                    currentUser={currentUser}
                    onOpenComments={(item) => setActivePost(item)}
                    onPostDeleted={(id) => setPosts((prev) => prev.filter((item) => item.id !== id))}
                    onOpenAuth={() => setIsAuthOpen(true)}
                    onSelectUser={handleSelectUser}
                  />
                ))}
              </div>
            </div>
          )}

          {currentTab === 'notifications' && (
            <div className="p-6 text-center text-slate-500">
              <h2 className="font-extrabold text-xl mb-2 text-slate-900 dark:text-white">Notificações</h2>
              <p className="text-sm">Você está em dia com todas as notificações da sua rede.</p>
            </div>
          )}

          {currentTab === 'settings' && (
            <div className="p-6 space-y-4">
              <h2 className="font-extrabold text-xl text-slate-900 dark:text-white">Configurações</h2>
              <div className="bg-slate-50 dark:bg-slate-800 p-4 rounded-xl border border-slate-200 dark:border-slate-700">
                <p className="font-bold text-sm text-slate-900 dark:text-white mb-1">Versão da Plataforma</p>
                <p className="text-xs text-slate-500">iZeny Web v2.0 &bull; React 19 + TypeScript + Tailwind CSS</p>
              </div>
              {currentUser && (
                <button
                  onClick={handleLogout}
                  className="px-5 py-2.5 bg-red-600 hover:bg-red-700 text-white rounded-full font-bold text-sm transition"
                >
                  Sair da Conta
                </button>
              )}
            </div>
          )}
        </main>

        {/* RIGHT COLUMN: SEARCH & TRENDS */}
        <RightSidebar
          onSearch={handleSearch}
          onSelectUser={handleSelectUser}
          onSelectHashtag={handleSelectHashtag}
          currentUser={currentUser}
        />

        {/* FLOATING MOBILE COMPOSE BUTTON */}
        <button
          onClick={() => {
            if (!currentUser) setIsAuthOpen(true);
            else setIsComposeOpen(true);
          }}
          className="md:hidden fixed bottom-18 right-4 w-14 h-14 bg-blue-600 hover:bg-blue-700 text-white rounded-full shadow-2xl flex items-center justify-center z-40 transition active:scale-95"
        >
          <Feather className="w-6 h-6" />
        </button>
      </div>

      {/* MODALS */}
      {activePost && (
        <PostModal
          post={activePost}
          onClose={() => setActivePost(null)}
          currentUser={currentUser}
          onOpenAuth={() => setIsAuthOpen(true)}
        />
      )}

      {isComposeOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="w-full max-w-lg">
            <Composer
              currentUser={currentUser}
              onPostCreated={() => {
                setIsComposeOpen(false);
                loadPosts();
              }}
              onOpenAuth={() => {
                setIsComposeOpen(false);
                setIsAuthOpen(true);
              }}
              isModal={true}
              onClose={() => setIsComposeOpen(false)}
            />
          </div>
        </div>
      )}

      {isAuthOpen && (
        <AuthModal
          onClose={() => setIsAuthOpen(false)}
          onAuthSuccess={handleAuthSuccess}
        />
      )}

      {isEditProfileOpen && (
        <EditProfileModal
          currentUser={currentUser}
          onClose={() => setIsEditProfileOpen(false)}
          onProfileUpdated={handleProfileUpdated}
        />
      )}
    </div>
  );
};
export default App;
