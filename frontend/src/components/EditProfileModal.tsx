import React, { useState, useRef } from 'react';
import { X, Camera, Loader2, Save } from 'lucide-react';
import type { User } from '../types';
import { pb, getUserAvatar } from '../lib/pocketbase';

interface EditProfileModalProps {
  currentUser: User | null;
  onClose: () => void;
  onProfileUpdated: (user: User) => void;
}

export const EditProfileModal: React.FC<EditProfileModalProps> = ({
  currentUser,
  onClose,
  onProfileUpdated,
}) => {
  if (!currentUser) return null;

  const [name, setName] = useState(currentUser.name || '');
  const [bio, setBio] = useState(currentUser.bio || '');
  const [country, setCountry] = useState(currentUser.country || '');
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const fileRef = useRef<HTMLInputElement>(null);

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setAvatarFile(file);
      setAvatarPreview(URL.createObjectURL(file));
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setSaving(true);
      const formData = new FormData();
      formData.append('name', name.trim());
      formData.append('bio', bio.trim());
      formData.append('country', country.trim());

      if (avatarFile) {
        formData.append('avatar', avatarFile);
      }

      const updated = await pb.collection('users').update<User>(currentUser.id, formData);
      onProfileUpdated(updated);
      onClose();
    } catch (err: any) {
      console.error('Erro ao atualizar perfil:', err);
      alert(err?.message || 'Falha ao atualizar perfil.');
    } finally {
      setSaving(false);
    }
  };

  const displayAvatar = avatarPreview || getUserAvatar(currentUser);

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div 
        onClick={(e) => e.stopPropagation()}
        className="bg-white dark:bg-slate-900 w-full max-w-lg rounded-2xl shadow-2xl flex flex-col overflow-hidden border border-slate-200 dark:border-slate-800"
      >
        {/* HEADER */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center space-x-3">
            <button 
              onClick={onClose}
              className="p-1.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 transition"
            >
              <X className="w-5 h-5" />
            </button>
            <h3 className="font-extrabold text-base text-slate-900 dark:text-white">Editar Perfil</h3>
          </div>
          <button
            onClick={handleSave}
            disabled={saving}
            className="px-5 py-1.5 bg-slate-900 dark:bg-white text-white dark:text-slate-900 text-xs font-bold rounded-full hover:opacity-90 transition flex items-center space-x-1"
          >
            {saving && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
            <span>Salvar</span>
          </button>
        </div>

        {/* FORM */}
        <form onSubmit={handleSave} className="p-4 space-y-4">
          {/* AVATAR PICKER */}
          <div className="flex items-center space-x-4">
            <input 
              ref={fileRef} 
              type="file" 
              accept="image/*" 
              onChange={handleAvatarChange} 
              className="hidden" 
            />
            <div 
              onClick={() => fileRef.current?.click()}
              className="relative w-20 h-20 rounded-full bg-blue-600 text-white font-extrabold text-2xl flex items-center justify-center overflow-hidden cursor-pointer group shadow-md"
            >
              {displayAvatar ? (
                <img src={displayAvatar} alt="Avatar" className="w-full h-full object-cover group-hover:opacity-75 transition" />
              ) : (
                <span>{currentUser.name?.[0]?.toUpperCase() || 'U'}</span>
              )}
              <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition">
                <Camera className="w-6 h-6 text-white" />
              </div>
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900 dark:text-white">Foto de Perfil</p>
              <button
                type="button"
                onClick={() => fileRef.current?.click()}
                className="text-xs text-blue-600 dark:text-blue-400 hover:underline font-semibold"
              >
                Alterar foto
              </button>
            </div>
          </div>

          {/* NAME */}
          <div>
            <label className="block text-xs font-bold text-slate-500 dark:text-slate-400 mb-1">
              Nome de Exibição
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              className="w-full px-3 py-2 border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-900 dark:text-white"
            />
          </div>

          {/* BIO */}
          <div>
            <label className="block text-xs font-bold text-slate-500 dark:text-slate-400 mb-1">
              Biografia
            </label>
            <textarea
              rows={3}
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              placeholder="Fale um pouco sobre você ou sua oficina técnica..."
              className="w-full px-3 py-2 border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-900 dark:text-white resize-none"
            />
          </div>

          {/* COUNTRY / LOCATION */}
          <div>
            <label className="block text-xs font-bold text-slate-500 dark:text-slate-400 mb-1">
              Localização (Cidade / Estado)
            </label>
            <input
              type="text"
              value={country}
              onChange={(e) => setCountry(e.target.value)}
              placeholder="Ex: São Paulo, SP"
              className="w-full px-3 py-2 border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-900 dark:text-white"
            />
          </div>
        </form>
      </div>
    </div>
  );
};
