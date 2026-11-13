import React, { useState } from 'react';
import { X, Lock, Mail, User as UserIcon, Loader2, ArrowRight } from 'lucide-react';
import type { User } from '../types';
import { pb } from '../lib/pocketbase';

interface AuthModalProps {
  onClose: () => void;
  onAuthSuccess: (user: User) => void;
}

export const AuthModal: React.FC<AuthModalProps> = ({
  onClose,
  onAuthSuccess,
}) => {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [username, setUsername] = useState('');
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg('');
    setLoading(true);

    try {
      if (isLogin) {
        const authData = await pb.collection('users').authWithPassword(email.trim(), password);
        onAuthSuccess(authData.record as any);
        onClose();
      } else {
        // Register new user
        const cleanUsername = (username.trim() || email.split('@')[0]).replace(/[^a-zA-Z0-9_]/g, '_');
        await pb.collection('users').create({
          email: email.trim(),
          password: password,
          passwordConfirm: password,
          name: name.trim() || cleanUsername,
          username: cleanUsername,
        });

        // Automatically log in after registration
        const authData = await pb.collection('users').authWithPassword(email.trim(), password);
        onAuthSuccess(authData.record as any);
        onClose();
      }
    } catch (err: any) {
      console.error('Auth error:', err);
      setErrorMsg(err?.message || 'Falha ao autenticar. Verifique suas credenciais.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div 
        onClick={(e) => e.stopPropagation()}
        className="bg-white dark:bg-slate-900 w-full max-w-md rounded-2xl shadow-2xl overflow-hidden border border-slate-200 dark:border-slate-800"
      >
        {/* HEADER */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center space-x-2">
            <div className="h-8 w-8 bg-blue-600 rounded-lg flex items-center justify-center text-white font-extrabold text-base">
              iZ
            </div>
            <h3 className="font-extrabold text-lg text-slate-900 dark:text-white">
              {isLogin ? 'Entrar no iZeny' : 'Criar Nova Conta'}
            </h3>
          </div>
          <button 
            onClick={onClose}
            className="p-1.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* FORM */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {errorMsg && (
            <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900 rounded-xl text-xs text-red-600 dark:text-red-400 font-medium leading-relaxed">
              {errorMsg}
            </div>
          )}

          {!isLogin && (
            <>
              <div>
                <label className="block text-xs font-bold text-slate-600 dark:text-slate-400 mb-1">
                  Nome Completo
                </label>
                <div className="relative flex items-center">
                  <UserIcon className="w-4 h-4 text-slate-400 absolute left-3" />
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Ex: Carlos Eduardo"
                    className="w-full pl-9 pr-3 py-2.5 border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-900 dark:text-white"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-600 dark:text-slate-400 mb-1">
                  Nome de Usuário (@handle)
                </label>
                <div className="relative flex items-center">
                  <span className="text-slate-400 absolute left-3 font-bold text-sm">@</span>
                  <input
                    type="text"
                    required
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    placeholder="carlos_suporte"
                    className="w-full pl-8 pr-3 py-2.5 border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-900 dark:text-white"
                  />
                </div>
              </div>
            </>
          )}

          <div>
            <label className="block text-xs font-bold text-slate-600 dark:text-slate-400 mb-1">
              E-mail
            </label>
            <div className="relative flex items-center">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="seuemail@exemplo.com"
                className="w-full pl-9 pr-3 py-2.5 border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-900 dark:text-white"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-600 dark:text-slate-400 mb-1">
              Senha
            </label>
            <div className="relative flex items-center">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Sua senha secreta"
                className="w-full pl-9 pr-3 py-2.5 border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-900 dark:text-white"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-extrabold rounded-full shadow-lg shadow-blue-500/25 transition flex items-center justify-center space-x-2 text-sm mt-2"
          >
            {loading && <Loader2 className="w-4 h-4 animate-spin" />}
            <span>{isLogin ? 'Entrar' : 'Cadastrar'}</span>
            <ArrowRight className="w-4 h-4" />
          </button>

          {/* TOGGLE LOGIN / REGISTER */}
          <div className="text-center pt-2">
            <button
              type="button"
              onClick={() => {
                setIsLogin(!isLogin);
                setErrorMsg('');
              }}
              className="text-xs text-blue-600 dark:text-blue-400 hover:underline font-semibold"
            >
              {isLogin
                ? 'Não tem uma conta? Crie uma agora gratuitamente!'
                : 'Já tem uma conta cadastrada? Clique para entrar!'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
