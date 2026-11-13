import React, { useState, useEffect, useRef } from 'react';
import { Send, Loader2, MessageSquare, ShieldCheck, User as UserIcon } from 'lucide-react';
import type { User, Message, Chat } from '../types';
import { pb, getUserAvatar, formatRelativeTime } from '../lib/pocketbase';

interface MessagesViewProps {
  currentUser: User | null;
  onOpenAuth: () => void;
}

export const MessagesView: React.FC<MessagesViewProps> = ({
  currentUser,
  onOpenAuth,
}) => {
  const [users, setUsers] = useState<User[]>([]);
  const [activePartner, setActivePartner] = useState<User | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [sending, setSending] = useState(false);

  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Load available technicians/users to chat with
  useEffect(() => {
    if (!currentUser) return;
    setLoadingUsers(true);
    pb.collection('users').getList<User>(1, 30, {
      sort: '-created',
    }).then((res) => {
      const list = res.items.filter((u) => u.id !== currentUser.id);
      setUsers(list);
      if (list.length > 0 && !activePartner) {
        setActivePartner(list[0]);
      }
    }).catch((err) => {
      console.warn('Erro ao carregar lista de conversas:', err);
    }).finally(() => {
      setLoadingUsers(false);
    });
  }, [currentUser]);

  // Load messages with activePartner
  useEffect(() => {
    if (!currentUser || !activePartner) return;
    setLoadingMessages(true);

    pb.collection('messages').getList<Message>(1, 100, {
      filter: `(sender = "${currentUser.id}" && chat = "${activePartner.id}") || (sender = "${activePartner.id}" && chat = "${currentUser.id}")`,
      sort: 'created',
      expand: 'sender',
    }).then((res) => {
      setMessages(res.items);
      setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
    }).catch((err) => {
      console.warn('Erro ao carregar mensagens:', err);
    }).finally(() => {
      setLoadingMessages(false);
    });
  }, [activePartner, currentUser]);

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentUser || !activePartner || !inputText.trim()) return;

    const content = inputText.trim();
    setInputText('');

    try {
      setSending(true);
      const newMsg = await pb.collection('messages').create<Message>({
        chat: activePartner.id,
        sender: currentUser.id,
        content: content,
        type: 'text',
      }, {
        expand: 'sender',
      });

      setMessages((prev) => [...prev, newMsg]);
      setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
    } catch (err: any) {
      console.error('Erro ao enviar mensagem:', err);
      alert('Falha ao enviar mensagem.');
    } finally {
      setSending(false);
    }
  };

  if (!currentUser) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] p-8 text-center bg-white dark:bg-slate-900 border-x border-slate-200 dark:border-slate-800">
        <MessageSquare className="w-12 h-12 text-blue-500 mb-3" />
        <h2 className="text-xl font-bold text-slate-900 dark:text-white mb-2">Mensagens Diretas</h2>
        <p className="text-slate-500 text-sm max-w-sm mb-4">
          Conecte-se e converse instantaneamente com outros técnicos e parceiros da rede ZenyDesk.
        </p>
        <button
          onClick={onOpenAuth}
          className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-full font-bold text-sm shadow-md transition"
        >
          Entrar para Conversar
        </button>
      </div>
    );
  }

  return (
    <div className="flex h-screen bg-white dark:bg-slate-900 border-x border-slate-200 dark:border-slate-800 overflow-hidden">
      {/* LEFT: CONVERSATIONS LIST */}
      <div className="w-2/5 sm:w-1/3 border-r border-slate-200 dark:border-slate-800 flex flex-col h-full">
        <div className="p-4 border-b border-slate-200 dark:border-slate-800">
          <h2 className="text-lg font-extrabold text-slate-900 dark:text-white">Mensagens</h2>
        </div>

        <div className="flex-1 overflow-y-auto divide-y divide-slate-100 dark:divide-slate-800/60">
          {loadingUsers ? (
            <div className="flex justify-center p-8">
              <Loader2 className="w-6 h-6 animate-spin text-blue-500" />
            </div>
          ) : users.length === 0 ? (
            <div className="p-4 text-center text-xs text-slate-400">
              Nenhum outro usuário disponível para conversa.
            </div>
          ) : (
            users.map((u) => {
              const isSelected = activePartner?.id === u.id;
              const avatar = getUserAvatar(u);
              return (
                <div
                  key={u.id}
                  onClick={() => setActivePartner(u)}
                  className={`flex items-center space-x-3 p-3.5 cursor-pointer transition ${
                    isSelected
                      ? 'bg-slate-100 dark:bg-slate-800/80 font-bold'
                      : 'hover:bg-slate-50 dark:hover:bg-slate-800/40'
                  }`}
                >
                  <div className="w-10 h-10 rounded-full bg-blue-600 text-white font-bold flex items-center justify-center overflow-hidden flex-shrink-0 text-sm shadow-sm">
                    {avatar ? (
                      <img src={avatar} alt={u.name} className="w-full h-full object-cover" />
                    ) : (
                      <span>{u.name?.[0]?.toUpperCase() || 'U'}</span>
                    )}
                  </div>
                  <div className="flex-1 truncate">
                    <div className="flex items-center space-x-1">
                      <span className="text-sm font-bold text-slate-900 dark:text-white truncate">
                        {u.name || u.username}
                      </span>
                      <ShieldCheck className="w-3.5 h-3.5 text-blue-500 flex-shrink-0" />
                    </div>
                    <span className="text-xs text-slate-500 truncate block">
                      @{u.username}
                    </span>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* RIGHT: CHAT THREAD */}
      <div className="flex-1 flex flex-col h-full bg-slate-50/50 dark:bg-slate-900/50">
        {activePartner ? (
          <>
            {/* CHAT HEADER */}
            <div className="p-3.5 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 flex items-center space-x-3">
              <div className="w-9 h-9 rounded-full bg-blue-600 text-white font-bold flex items-center justify-center overflow-hidden flex-shrink-0 shadow-sm text-xs">
                {getUserAvatar(activePartner) ? (
                  <img src={getUserAvatar(activePartner)} alt={activePartner.name} className="w-full h-full object-cover" />
                ) : (
                  <span>{activePartner.name?.[0]?.toUpperCase() || 'U'}</span>
                )}
              </div>
              <div>
                <h3 className="font-extrabold text-sm text-slate-900 dark:text-white">
                  {activePartner.name || activePartner.username}
                </h3>
                <span className="text-[11px] text-slate-400">@{activePartner.username}</span>
              </div>
            </div>

            {/* MESSAGES STREAM */}
            <div className="flex-1 overflow-y-auto p-4 space-y-3">
              {loadingMessages ? (
                <div className="flex justify-center p-8">
                  <Loader2 className="w-6 h-6 animate-spin text-blue-500" />
                </div>
              ) : messages.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-full text-center text-slate-400 p-6">
                  <p className="text-sm">Inicie a conversa com {activePartner.name || activePartner.username}!</p>
                </div>
              ) : (
                messages.map((m) => {
                  const isMe = m.sender === currentUser.id;
                  return (
                    <div
                      key={m.id}
                      className={`flex flex-col max-w-[75%] ${isMe ? 'ml-auto items-end' : 'mr-auto items-start'}`}
                    >
                      <div
                        className={`px-4 py-2.5 rounded-2xl text-sm leading-relaxed shadow-sm ${
                          isMe
                            ? 'bg-blue-600 text-white rounded-br-none'
                            : 'bg-white dark:bg-slate-800 text-slate-900 dark:text-white border border-slate-200/80 dark:border-slate-700/80 rounded-bl-none'
                        }`}
                      >
                        {m.content}
                      </div>
                      <span className="text-[10px] text-slate-400 mt-1 px-1">
                        {formatRelativeTime(m.created)}
                      </span>
                    </div>
                  );
                })
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* MESSAGE INPUT */}
            <form onSubmit={handleSendMessage} className="p-3 bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-800 flex items-center space-x-2">
              <input
                type="text"
                value={inputText}
                onChange={(e) => setInputText(e.target.value)}
                placeholder="Enviar mensagem direta..."
                className="flex-1 bg-slate-100 dark:bg-slate-800 border-0 rounded-full px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-900 dark:text-white"
              />
              <button
                type="submit"
                disabled={sending || !inputText.trim()}
                className="p-2.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white rounded-full transition shadow-md"
              >
                {sending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
              </button>
            </form>
          </>
        ) : (
          <div className="flex flex-col items-center justify-center h-full text-slate-400 p-8 text-center">
            <MessageSquare className="w-10 h-10 mb-2 opacity-50" />
            <p className="text-sm">Selecione uma conversa para começar.</p>
          </div>
        )}
      </div>
    </div>
  );
};
