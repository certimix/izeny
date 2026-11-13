import React, { useState, useRef } from 'react';
import { Image, Video, MapPin, Smile, X, Loader2 } from 'lucide-react';
import type { User } from '../types';
import { pb, getUserAvatar } from '../lib/pocketbase';

interface ComposerProps {
  currentUser: User | null;
  onPostCreated: () => void;
  onOpenAuth: () => void;
  isModal?: boolean;
  onClose?: () => void;
}

export const Composer: React.FC<ComposerProps> = ({
  currentUser,
  onPostCreated,
  onOpenAuth,
  isModal = false,
  onClose,
}) => {
  const [text, setText] = useState('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isVideo, setIsVideo] = useState(false);
  const [loading, setLoading] = useState(false);
  const [location, setLocation] = useState('');
  const [showLocationInput, setShowLocationInput] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setSelectedFile(file);
    const url = URL.createObjectURL(file);
    setPreviewUrl(url);
    setIsVideo(file.type.startsWith('video/'));
  };

  const removeMedia = () => {
    setSelectedFile(null);
    if (previewUrl) {
      URL.revokeObjectURL(previewUrl);
      setPreviewUrl(null);
    }
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const handleSubmit = async () => {
    if (!currentUser) {
      onOpenAuth();
      return;
    }
    if (!text.trim() && !selectedFile) return;

    try {
      setLoading(true);
      const formData = new FormData();
      formData.append('description', text.trim());
      formData.append('owner', currentUser.id);
      formData.append('ownerId', currentUser.id);
      formData.append('username', currentUser.username || currentUser.name || 'usuario');
      formData.append('location', location.trim() || 'iZeny');

      if (selectedFile) {
        formData.append('media', selectedFile);
      }

      await pb.collection('posts').create(formData);

      // Reset
      setText('');
      removeMedia();
      setLocation('');
      setShowLocationInput(false);
      onPostCreated();
      if (isModal && onClose) {
        onClose();
      }
    } catch (err: any) {
      console.error('Erro ao publicar:', err);
      alert(err?.message || 'Falha ao publicar post. Tente novamente.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={`p-4 border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 ${isModal ? 'rounded-2xl' : ''}`}>
      <div className="flex space-x-3">
        {/* AVATAR */}
        <div className="w-10 h-10 rounded-full bg-blue-600 text-white font-bold flex items-center justify-center overflow-hidden flex-shrink-0 shadow-sm">
          {getUserAvatar(currentUser) ? (
            <img src={getUserAvatar(currentUser)} alt="Avatar" className="w-full h-full object-cover" />
          ) : (
            <span>{currentUser?.name?.[0]?.toUpperCase() || 'U'}</span>
          )}
        </div>

        {/* INPUT AND ACTIONS */}
        <div className="flex-1 flex flex-col">
          <textarea
            ref={textareaRef}
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="O que está acontecendo na sua oficina ou empresa?"
            rows={isModal ? 3 : 2}
            className="w-full bg-transparent resize-none border-0 focus:outline-none text-slate-900 dark:text-white placeholder:text-slate-400 text-lg py-1 px-0"
          />

          {/* LOCATION INPUT */}
          {showLocationInput && (
            <div className="my-2 flex items-center bg-slate-100 dark:bg-slate-800 rounded-lg px-2.5 py-1 text-sm">
              <MapPin className="w-4 h-4 text-slate-400 mr-1.5" />
              <input
                type="text"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                placeholder="Adicionar localização (ex: São Paulo, SP)"
                className="bg-transparent border-0 focus:outline-none text-slate-800 dark:text-slate-200 w-full text-xs"
              />
              <button onClick={() => setShowLocationInput(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
          )}

          {/* MEDIA PREVIEW */}
          {previewUrl && (
            <div className="relative my-3 rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-800 max-h-80 bg-black flex items-center justify-center">
              <button
                onClick={removeMedia}
                className="absolute top-2.5 right-2.5 p-1.5 bg-black/70 hover:bg-black/90 text-white rounded-full transition z-10"
              >
                <X className="w-4 h-4" />
              </button>
              {isVideo ? (
                <video src={previewUrl} controls className="max-h-80 w-auto rounded-xl" />
              ) : (
                <img src={previewUrl} alt="Preview" className="max-h-80 w-auto object-contain rounded-xl" />
              )}
            </div>
          )}

          {/* FOOTER ACTIONS */}
          <div className="flex items-center justify-between pt-3 border-t border-slate-100 dark:border-slate-800/80">
            <div className="flex items-center space-x-1 text-blue-600 dark:text-blue-400">
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*,video/*"
                onChange={handleFileChange}
                className="hidden"
              />
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                title="Adicionar Foto"
                className="p-2 hover:bg-blue-50 dark:hover:bg-blue-950/40 rounded-full transition"
              >
                <Image className="w-5 h-5" />
              </button>
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                title="Adicionar Vídeo"
                className="p-2 hover:bg-blue-50 dark:hover:bg-blue-950/40 rounded-full transition"
              >
                <Video className="w-5 h-5" />
              </button>
              <button
                type="button"
                onClick={() => setShowLocationInput(!showLocationInput)}
                title="Adicionar Localização"
                className="p-2 hover:bg-blue-50 dark:hover:bg-blue-950/40 rounded-full transition"
              >
                <MapPin className="w-5 h-5" />
              </button>
            </div>

            <div className="flex items-center space-x-3">
              {text.length > 0 && (
                <span className={`text-xs ${text.length > 280 ? 'text-red-500 font-bold' : 'text-slate-400'}`}>
                  {280 - text.length}
                </span>
              )}
              <button
                disabled={loading || (!text.trim() && !selectedFile)}
                onClick={handleSubmit}
                className="px-5 py-2 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white font-bold text-sm rounded-full shadow-sm transition flex items-center space-x-1.5"
              >
                {loading && <Loader2 className="w-4 h-4 animate-spin" />}
                <span>Publicar</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
