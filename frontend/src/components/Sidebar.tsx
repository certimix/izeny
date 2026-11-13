import React from 'react';
import { 
  Home, 
  Search, 
  Bell, 
  MessageSquare, 
  User as UserIcon, 
  Settings, 
  LogOut, 
  Feather, 
  ShieldCheck,
  CheckCircle2
} from 'lucide-react';
import type { User } from '../types';
import { getUserAvatar } from '../lib/pocketbase';

interface SidebarProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
  currentUser: User | null;
  onOpenCompose: () => void;
  onLogout: () => void;
  onOpenAuth: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  currentUser,
  onOpenCompose,
  onLogout,
  onOpenAuth,
}) => {
  const navItems = [
    { id: 'feed', label: 'Página Inicial', icon: Home },
    { id: 'explore', label: 'Explorar', icon: Search },
    { id: 'notifications', label: 'Notificações', icon: Bell },
    { id: 'messages', label: 'Mensagens', icon: MessageSquare },
    { id: 'profile', label: 'Perfil', icon: UserIcon },
    { id: 'settings', label: 'Configurações', icon: Settings },
  ];

  return (
    <>
      {/* DESKTOP SIDEBAR */}
      <aside className="hidden md:flex flex-col justify-between w-64 xl:w-72 h-screen sticky top-0 px-3 py-4 border-r border-slate-200 dark:border-slate-800 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md z-30 select-none">
        <div className="flex flex-col space-y-2">
          {/* LOGO */}
          <div 
            onClick={() => onSelectTab('feed')} 
            className="flex items-center space-x-3 px-3 py-2 cursor-pointer hover:bg-slate-100 dark:hover:bg-slate-800/60 rounded-2xl transition w-fit"
          >
            <img 
              src="/images/logo.svg" 
              alt="iZeny" 
              className="h-9 w-auto object-contain drop-shadow-sm" 
            />
            <span className="text-2xl font-black tracking-tight text-slate-900 dark:text-white">
              iZeny
            </span>
          </div>

          {/* NAV LINKS */}
          <nav className="flex flex-col space-y-1 pt-2">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = currentTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => {
                    if (item.id === 'profile' && !currentUser) {
                      onOpenAuth();
                    } else {
                      onSelectTab(item.id);
                    }
                  }}
                  className={`flex items-center space-x-4 px-4 py-3 rounded-full text-base font-semibold transition-all duration-150 ${
                    isActive
                      ? 'bg-slate-100 dark:bg-slate-800 text-blue-600 dark:text-blue-400 font-bold'
                      : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800/60'
                  }`}
                >
                  <Icon className={`w-6 h-6 ${isActive ? 'stroke-[2.5px]' : 'stroke-[1.8px]'}`} />
                  <span className="hidden xl:inline">{item.label}</span>
                </button>
              );
            })}
          </nav>

          {/* POST BUTTON */}
          <div className="pt-4">
            <button
              onClick={() => {
                if (!currentUser) onOpenAuth();
                else onOpenCompose();
              }}
              className="w-full py-3.5 px-4 bg-blue-600 hover:bg-blue-700 active:scale-[0.98] text-white font-bold rounded-full shadow-lg shadow-blue-500/25 transition flex items-center justify-center space-x-2 text-base"
            >
              <Feather className="w-5 h-5 xl:hidden" />
              <span className="hidden xl:inline">Publicar</span>
            </button>
          </div>
        </div>

        {/* USER FOOTER PILL */}
        <div className="pt-4 border-t border-slate-100 dark:border-slate-800">
          {currentUser ? (
            <div className="flex items-center justify-between p-2 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800/60 transition group cursor-pointer">
              <div 
                onClick={() => onSelectTab('profile')}
                className="flex items-center space-x-3 overflow-hidden flex-1"
              >
                <div className="w-10 h-10 rounded-full bg-blue-600 text-white font-bold flex items-center justify-center overflow-hidden flex-shrink-0 shadow-sm">
                  {getUserAvatar(currentUser) ? (
                    <img 
                      src={getUserAvatar(currentUser)} 
                      alt={currentUser.name} 
                      className="w-full h-full object-cover" 
                    />
                  ) : (
                    <span>{currentUser.name?.[0]?.toUpperCase() || 'U'}</span>
                  )}
                </div>
                <div className="hidden xl:flex flex-col truncate">
                  <div className="flex items-center space-x-1">
                    <span className="font-bold text-sm text-slate-900 dark:text-white truncate">
                      {currentUser.name || currentUser.username}
                    </span>
                    <ShieldCheck className="w-3.5 h-3.5 text-blue-500 flex-shrink-0" />
                  </div>
                  <span className="text-xs text-slate-500 dark:text-slate-400 truncate">
                    @{currentUser.username || 'usuario'}
                  </span>
                </div>
              </div>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onLogout();
                }}
                title="Sair da conta"
                className="p-2 text-slate-400 hover:text-red-500 rounded-full hover:bg-red-50 dark:hover:bg-red-950/30 transition"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <button
              onClick={onOpenAuth}
              className="w-full py-2.5 px-4 bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-bold rounded-full hover:opacity-90 transition text-sm text-center"
            >
              Entrar ou Cadastrar
            </button>
          )}
        </div>
      </aside>

      {/* MOBILE BOTTOM NAVIGATION BAR */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 h-14 bg-white/95 dark:bg-slate-900/95 backdrop-blur-md border-t border-slate-200 dark:border-slate-800 flex items-center justify-around px-2 z-40">
        {navItems.slice(0, 5).map((item) => {
          const Icon = item.icon;
          const isActive = currentTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => {
                if (item.id === 'profile' && !currentUser) {
                  onOpenAuth();
                } else {
                  onSelectTab(item.id);
                }
              }}
              className={`p-2.5 rounded-full transition ${
                isActive ? 'text-blue-600 dark:text-blue-400' : 'text-slate-500 dark:text-slate-400'
              }`}
            >
              <Icon className={`w-6 h-6 ${isActive ? 'stroke-[2.5px]' : 'stroke-[1.8px]'}`} />
            </button>
          );
        })}
      </nav>
    </>
  );
};
