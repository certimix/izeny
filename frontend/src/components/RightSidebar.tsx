import React, { useEffect, useState } from 'react';
import { Search, ShieldCheck, UserPlus, Check } from 'lucide-react';
import type { User } from '../types';
import { pb, getUserAvatar } from '../lib/pocketbase';

interface RightSidebarProps {
  onSearch: (query: string) => void;
  onSelectUser: (username: string) => void;
  onSelectHashtag: (tag: string) => void;
  currentUser: User | null;
}

export const RightSidebar: React.FC<RightSidebarProps> = ({
  onSearch,
  onSelectUser,
  onSelectHashtag,
  currentUser,
}) => {
  const [searchVal, setSearchVal] = useState('');
  const [users, setUsers] = useState<User[]>([]);
  const [followingMap, setFollowingMap] = useState<Record<string, boolean>>({});

  const trendingTopics = [
    { tag: '#zenydesk', category: 'Ecossistema & Comunidade', posts: '128' },
    { tag: '#dicas_tecnicas', category: 'Bancada, Placas & Hardware', posts: '94' },
    { tag: '#ti_ajuda', category: 'Dúvidas Técnicas & Redes', posts: '76' },
    { tag: '#suporte_direto', category: 'Atendimento Especializado', posts: '52' },
    { tag: '#ordem_servico', category: 'Gestão & Laudos Map-OS', posts: '41' },
    { tag: '#assistencia_tecnica', category: 'Oficinas & Reparos', posts: '35' },
  ];

  useEffect(() => {
    // Fetch users from PocketBase
    pb.collection('users').getList<User>(1, 5, {
      sort: '-created',
    }).then((res) => {
      // Filter out current user if logged in
      const list = res.items.filter((u) => !currentUser || u.id !== currentUser.id);
      setUsers(list.slice(0, 4));
    }).catch((err) => {
      console.warn('Erro ao carregar técnicos recomendados:', err);
    });
  }, [currentUser]);

  const toggleFollow = (userId: string) => {
    setFollowingMap((prev) => ({
      ...prev,
      [userId]: !prev[userId],
    }));
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchVal.trim()) {
      onSearch(searchVal.trim());
    }
  };

  return (
    <aside className="hidden lg:flex flex-col w-80 xl:w-88 h-screen sticky top-0 px-4 py-4 space-y-4 overflow-y-auto z-20 select-none">
      {/* SEARCH BAR */}
      <form onSubmit={handleSearchSubmit} className="sticky top-0 bg-slate-50/95 dark:bg-slate-900/95 backdrop-blur-md pt-1 pb-2 z-10">
        <div className="relative flex items-center bg-slate-200/80 dark:bg-slate-800 rounded-full px-4 py-2.5 focus-within:bg-white dark:focus-within:bg-slate-800 focus-within:ring-2 focus-within:ring-blue-500 transition">
          <Search className="w-4 h-4 text-slate-400 mr-2.5 flex-shrink-0" />
          <input
            type="text"
            value={searchVal}
            onChange={(e) => setSearchVal(e.target.value)}
            placeholder="Buscar no iZeny..."
            className="w-full bg-transparent border-0 focus:outline-none text-sm text-slate-900 dark:text-white placeholder:text-slate-400"
          />
        </div>
      </form>

      {/* TRENDING TOPICS CARD */}
      <div className="bg-white dark:bg-slate-800/60 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm">
        <h3 className="font-extrabold text-base text-slate-900 dark:text-white mb-3">
          Tópicos &amp; Tendências
        </h3>
        <div className="flex flex-col space-y-3">
          {trendingTopics.map((item) => (
            <div
              key={item.tag}
              onClick={() => onSelectHashtag(item.tag)}
              className="flex justify-between items-start cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800 p-2 -mx-2 rounded-xl transition group"
            >
              <div>
                <span className="text-[11px] text-slate-500 dark:text-slate-400 block font-medium">
                  {item.category}
                </span>
                <span className="font-bold text-sm text-slate-900 dark:text-white group-hover:text-blue-500 transition">
                  {item.tag}
                </span>
              </div>
              <span className="text-xs text-slate-400 font-medium">
                {item.posts} posts
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* WHO TO FOLLOW / TÉCNICOS & PARCEIROS */}
      <div className="bg-white dark:bg-slate-800/60 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm">
        <h3 className="font-extrabold text-base text-slate-900 dark:text-white mb-3">
          Técnicos &amp; Parceiros
        </h3>
        <div className="flex flex-col space-y-3">
          {users.map((u) => {
            const isFollowing = followingMap[u.id];
            return (
              <div key={u.id} className="flex items-center justify-between">
                <div 
                  onClick={() => onSelectUser(u.username)}
                  className="flex items-center space-x-2.5 cursor-pointer overflow-hidden flex-1 mr-2"
                >
                  <div className="w-9 h-9 rounded-full bg-blue-600 text-white font-bold flex items-center justify-center overflow-hidden flex-shrink-0 shadow-sm text-xs">
                    {getUserAvatar(u) ? (
                      <img src={getUserAvatar(u)} alt={u.name} className="w-full h-full object-cover" />
                    ) : (
                      <span>{u.name?.[0]?.toUpperCase() || u.username?.[0]?.toUpperCase() || 'T'}</span>
                    )}
                  </div>
                  <div className="flex flex-col truncate">
                    <div className="flex items-center space-x-1 truncate">
                      <span className="font-bold text-xs text-slate-900 dark:text-white hover:underline truncate">
                        {u.name || u.username}
                      </span>
                      <ShieldCheck className="w-3 h-3 text-blue-500 flex-shrink-0" />
                    </div>
                    <span className="text-[11px] text-slate-500 dark:text-slate-400 truncate">
                      @{u.username || 'tecnico'}
                    </span>
                  </div>
                </div>

                <button
                  onClick={() => toggleFollow(u.id)}
                  className={`py-1 px-3 rounded-full text-xs font-bold transition flex items-center space-x-1 ${
                    isFollowing
                      ? 'border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:border-red-500 hover:text-red-500'
                      : 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 hover:opacity-90'
                  }`}
                >
                  {isFollowing ? (
                    <>
                      <Check className="w-3 h-3 mr-0.5" />
                      <span>Seguindo</span>
                    </>
                  ) : (
                    <>
                      <UserPlus className="w-3 h-3 mr-0.5" />
                      <span>Seguir</span>
                    </>
                  )}
                </button>
              </div>
            );
          })}
        </div>
      </div>

      {/* FOOTER LINKS (RULE 16: AORDIC.COM.BR in #f7931a) */}
      <footer className="text-[11px] text-slate-400 dark:text-slate-500 px-2 space-y-1">
        <div className="flex flex-wrap gap-x-3 gap-y-1">
          <a href="https://zenydesk.com" target="_blank" rel="noreferrer" className="hover:underline">ZenyDesk</a>
          <a href="https://os.zenydesk.com" target="_blank" rel="noreferrer" className="hover:underline">ZenyDesk O.S</a>
          <a href="https://erp.zenydesk.com" target="_blank" rel="noreferrer" className="hover:underline">ZenyDesk ERP</a>
        </div>
        <div className="pt-2">
          &copy; {new Date().getFullYear()} iZeny &bull; Desenvolvido por{' '}
          <a 
            href="https://aordic.com.br" 
            target="_blank" 
            rel="noreferrer" 
            className="font-bold hover:underline"
            style={{ color: '#f7931a' }}
          >
            AORDIC.COM.BR
          </a>
        </div>
      </footer>
    </aside>
  );
};
