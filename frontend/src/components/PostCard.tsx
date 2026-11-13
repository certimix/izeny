import React, { useState } from 'react';
import { 
  MessageCircle, 
  Repeat2, 
  Heart, 
  Share, 
  MapPin, 
  MoreHorizontal, 
  Trash2,
  Check
} from 'lucide-react';
import type { Post, User } from '../types';
import { pb, getUserAvatar, formatRelativeTime, getFileUrl } from '../lib/pocketbase';

interface PostCardProps {
  post: Post;
  currentUser: User | null;
  onOpenComments: (post: Post) => void;
  onPostDeleted: (postId: string) => void;
  onOpenAuth: () => void;
  onSelectUser?: (username: string) => void;
}

export const PostCard: React.FC<PostCardProps> = ({
  post,
  currentUser,
  onOpenComments,
  onPostDeleted,
  onOpenAuth,
  onSelectUser,
}) => {
  const isOwner = currentUser && (currentUser.id === post.owner || currentUser.id === post.ownerId);
  const likesList = Array.isArray(post.likes) ? post.likes : [];
  const [hasLiked, setHasLiked] = useState<boolean>(currentUser ? likesList.includes(currentUser.id) : false);
  const [likesCount, setLikesCount] = useState<number>(likesList.length);
  const [copied, setCopied] = useState<boolean>(false);
  const [showMenu, setShowMenu] = useState<boolean>(false);
  const [isDeleting, setIsDeleting] = useState<boolean>(false);

  // Author details
  const authorName = post.expand?.owner?.name || post.username || 'Usuário ZenyDesk';
  const authorUsername = post.expand?.owner?.username || post.username || 'usuario';
  const authorAvatar = getUserAvatar(post.expand?.owner);

  // Media URLs
  let mediaFiles: string[] = [];
  if (Array.isArray(post.media)) {
    mediaFiles = post.media;
  } else if (typeof post.media === 'string' && post.media.trim()) {
    mediaFiles = [post.media];
  } else if (post.mediaUrl && post.mediaUrl.trim()) {
    mediaFiles = [post.mediaUrl];
  }

  const handleLike = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!currentUser) {
      onOpenAuth();
      return;
    }

    const newLikedState = !hasLiked;
    const newCount = newLikedState ? likesCount + 1 : Math.max(0, likesCount - 1);

    setHasLiked(newLikedState);
    setLikesCount(newCount);

    try {
      const currentLikes = Array.isArray(post.likes) ? [...post.likes] : [];
      let updatedLikes: string[];
      if (newLikedState) {
        updatedLikes = Array.from(new Set([...currentLikes, currentUser.id]));
      } else {
        updatedLikes = currentLikes.filter((id) => id !== currentUser.id);
      }
      await pb.collection('posts').update(post.id, {
        likes: updatedLikes,
      });
    } catch (err) {
      console.error('Erro ao curtir post:', err);
      // Revert on error
      setHasLiked(!newLikedState);
      setLikesCount(likesCount);
    }
  };

  const handleShare = (e: React.MouseEvent) => {
    e.stopPropagation();
    navigator.clipboard.writeText(window.location.origin + '/#/post/' + post.id);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleDelete = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!confirm('Deseja realmente excluir esta publicação?')) return;

    try {
      setIsDeleting(true);
      await pb.collection('posts').delete(post.id);
      onPostDeleted(post.id);
    } catch (err) {
      console.error('Erro ao deletar post:', err);
      alert('Não foi possível excluir a publicação.');
      setIsDeleting(false);
    }
  };

  // Format hashtags inside description
  const renderDescription = (text: string) => {
    if (!text) return null;
    const parts = text.split(/(#[a-zA-Z0-9_]+)/g);
    return parts.map((part, index) => {
      if (part.startsWith('#')) {
        return (
          <span 
            key={index} 
            className="text-blue-500 hover:underline font-medium cursor-pointer"
            onClick={(e) => {
              e.stopPropagation();
              // Future: filter by hashtag
            }}
          >
            {part}
          </span>
        );
      }
      return part;
    });
  };

  return (
    <article 
      onClick={() => onOpenComments(post)}
      className="p-4 border-b border-slate-100 dark:border-slate-800/80 hover:bg-slate-50/70 dark:hover:bg-slate-800/30 transition cursor-pointer select-text"
    >
      <div className="flex space-x-3">
        {/* AVATAR */}
        <div 
          onClick={(e) => {
            e.stopPropagation();
            if (onSelectUser) onSelectUser(authorUsername);
          }}
          className="w-10 h-10 rounded-full bg-blue-600 text-white font-bold flex items-center justify-center overflow-hidden flex-shrink-0 cursor-pointer shadow-sm hover:opacity-90 transition"
        >
          {authorAvatar ? (
            <img src={authorAvatar} alt={authorName} className="w-full h-full object-cover" />
          ) : (
            <span>{authorName[0]?.toUpperCase() || 'U'}</span>
          )}
        </div>

        {/* CONTENT */}
        <div className="flex-1 overflow-hidden">
          {/* HEADER */}
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-1.5 truncate">
              <span 
                onClick={(e) => {
                  e.stopPropagation();
                  if (onSelectUser) onSelectUser(authorUsername);
                }}
                className="font-bold text-slate-900 dark:text-white text-sm hover:underline cursor-pointer truncate"
              >
                {authorName}
              </span>
              <span className="text-slate-500 dark:text-slate-400 text-xs truncate">
                @{authorUsername}
              </span>
              <span className="text-slate-400 text-xs">&bull;</span>
              <span className="text-slate-500 dark:text-slate-400 text-xs flex-shrink-0">
                {formatRelativeTime(post.created)}
              </span>
            </div>

            {/* MORE OPTIONS MENU */}
            <div className="relative">
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setShowMenu(!showMenu);
                }}
                className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 transition"
              >
                <MoreHorizontal className="w-4 h-4" />
              </button>

              {showMenu && (
                <div className="absolute right-0 top-6 w-36 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-xl z-20 py-1">
                  {isOwner ? (
                    <button
                      onClick={handleDelete}
                      disabled={isDeleting}
                      className="w-full px-3 py-2 text-left text-xs text-red-600 hover:bg-red-50 dark:hover:bg-red-950/40 flex items-center space-x-2 font-medium"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      <span>{isDeleting ? 'Excluindo...' : 'Excluir post'}</span>
                    </button>
                  ) : (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setShowMenu(false);
                        alert('Post denunciado com sucesso.');
                      }}
                      className="w-full px-3 py-2 text-left text-xs text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 flex items-center space-x-2 font-medium"
                    >
                      <span>Denunciar post</span>
                    </button>
                  )}
                </div>
              )}
            </div>
          </div>

          {/* LOCATION TAG */}
          {post.location && post.location !== 'iZeny' && (
            <div className="flex items-center space-x-1 text-[11px] text-slate-500 mt-0.5">
              <MapPin className="w-3 h-3 text-slate-400" />
              <span>{post.location}</span>
            </div>
          )}

          {/* POST TEXT */}
          <div className="mt-2 text-sm text-slate-800 dark:text-slate-100 whitespace-pre-wrap leading-relaxed">
            {renderDescription(post.description)}
          </div>

          {/* MEDIA DISPLAY */}
          {mediaFiles.length > 0 && (
            <div className="mt-3 rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-800 bg-slate-900/5">
              {mediaFiles.map((fn, idx) => {
                const url = fn.startsWith('http') ? fn : getFileUrl('posts', post.id, fn);
                const isVid = fn.match(/\.(mp4|mov|webm)$/i);
                if (isVid) {
                  return (
                    <video
                      key={idx}
                      src={url}
                      controls
                      className="w-full max-h-96 rounded-2xl object-cover"
                      onClick={(e) => e.stopPropagation()}
                    />
                  );
                }
                return (
                  <img
                    key={idx}
                    src={url}
                    alt="Mídia"
                    loading="lazy"
                    className="w-full max-h-96 object-cover rounded-2xl hover:opacity-95 transition"
                  />
                );
              })}
            </div>
          )}

          {/* ACTIONS FOOTER */}
          <div className="flex items-center justify-between mt-3 text-slate-500 dark:text-slate-400 max-w-md pt-1">
            {/* COMMENT */}
            <button 
              onClick={(e) => {
                e.stopPropagation();
                onOpenComments(post);
              }}
              className="flex items-center space-x-1.5 hover:text-blue-500 group transition text-xs"
            >
              <div className="p-1.5 rounded-full group-hover:bg-blue-50 dark:group-hover:bg-blue-950/40 transition">
                <MessageCircle className="w-4 h-4" />
              </div>
              <span>0</span>
            </button>

            {/* REPOST */}
            <button 
              onClick={(e) => {
                e.stopPropagation();
              }}
              className="flex items-center space-x-1.5 hover:text-green-500 group transition text-xs"
            >
              <div className="p-1.5 rounded-full group-hover:bg-green-50 dark:group-hover:bg-green-950/40 transition">
                <Repeat2 className="w-4 h-4" />
              </div>
              <span>0</span>
            </button>

            {/* LIKE */}
            <button 
              onClick={handleLike}
              className={`flex items-center space-x-1.5 group transition text-xs ${
                hasLiked ? 'text-pink-600 font-semibold' : 'hover:text-pink-500'
              }`}
            >
              <div className="p-1.5 rounded-full group-hover:bg-pink-50 dark:group-hover:bg-pink-950/40 transition">
                <Heart className={`w-4 h-4 ${hasLiked ? 'fill-pink-600 text-pink-600 scale-110' : ''} transition-transform`} />
              </div>
              <span>{likesCount}</span>
            </button>

            {/* SHARE */}
            <button 
              onClick={handleShare}
              title="Copiar link"
              className="flex items-center space-x-1.5 hover:text-blue-500 group transition text-xs"
            >
              <div className="p-1.5 rounded-full group-hover:bg-blue-50 dark:group-hover:bg-blue-950/40 transition">
                {copied ? <Check className="w-4 h-4 text-green-500" /> : <Share className="w-4 h-4" />}
              </div>
              {copied && <span className="text-[11px] text-green-500 font-bold">Copiado!</span>}
            </button>
          </div>
        </div>
      </div>
    </article>
  );
};
