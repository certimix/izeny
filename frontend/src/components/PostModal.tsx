import React, { useState, useEffect } from 'react';
import { X, MessageCircle, Heart, Share, Loader2, Send } from 'lucide-react';
import type { Post, Comment, User } from '../types';
import { pb, getUserAvatar, formatRelativeTime, getFileUrl } from '../lib/pocketbase';

interface PostModalProps {
  post: Post | null;
  onClose: () => void;
  currentUser: User | null;
  onOpenAuth: () => void;
}

export const PostModal: React.FC<PostModalProps> = ({
  post,
  onClose,
  currentUser,
  onOpenAuth,
}) => {
  const [comments, setComments] = useState<Comment[]>([]);
  const [commentText, setCommentText] = useState('');
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);

  useEffect(() => {
    if (!post) return;
    setLoading(true);
    pb.collection('comments').getList<Comment>(1, 50, {
      filter: `post = "${post.id}"`,
      sort: '-created',
      expand: 'user',
    }).then((res) => {
      setComments(res.items);
    }).catch((err) => {
      console.warn('Erro ao carregar comentários:', err);
    }).finally(() => {
      setLoading(false);
    });
  }, [post]);

  if (!post) return null;

  const handleSendComment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentUser) {
      onOpenAuth();
      return;
    }
    if (!commentText.trim()) return;

    try {
      setSending(true);
      const newComment = await pb.collection('comments').create<Comment>({
        post: post.id,
        user: currentUser.id,
        comment: commentText.trim(),
      }, {
        expand: 'user',
      });

      setComments((prev) => [newComment, ...prev]);
      setCommentText('');
    } catch (err: any) {
      console.error('Erro ao enviar comentário:', err);
      alert('Não foi possível enviar o comentário.');
    } finally {
      setSending(false);
    }
  };

  const authorName = post.expand?.owner?.name || post.username || 'Usuário';
  const authorUsername = post.expand?.owner?.username || post.username || 'usuario';
  const authorAvatar = getUserAvatar(post.expand?.owner);

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div 
        onClick={(e) => e.stopPropagation()}
        className="bg-white dark:bg-slate-900 w-full max-w-xl max-h-[90vh] rounded-2xl shadow-2xl flex flex-col overflow-hidden border border-slate-200 dark:border-slate-800"
      >
        {/* HEADER */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-slate-100 dark:border-slate-800">
          <h3 className="font-bold text-base text-slate-900 dark:text-white">Publicação</h3>
          <button 
            onClick={onClose}
            className="p-1.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* SCROLLABLE CONTENT */}
        <div className="overflow-y-auto p-4 space-y-4 flex-1">
          {/* AUTHOR */}
          <div className="flex items-center space-x-3">
            <div className="w-11 h-11 rounded-full bg-blue-600 text-white font-bold flex items-center justify-center overflow-hidden flex-shrink-0 shadow-sm">
              {authorAvatar ? (
                <img src={authorAvatar} alt={authorName} className="w-full h-full object-cover" />
              ) : (
                <span>{authorName[0]?.toUpperCase() || 'U'}</span>
              )}
            </div>
            <div>
              <div className="font-bold text-sm text-slate-900 dark:text-white">{authorName}</div>
              <div className="text-xs text-slate-500">@{authorUsername} &bull; {formatRelativeTime(post.created)}</div>
            </div>
          </div>

          {/* DESCRIPTION */}
          <p className="text-slate-800 dark:text-slate-100 text-base leading-relaxed whitespace-pre-wrap">
            {post.description}
          </p>

          {/* MEDIA */}
          {post.media && (
            <div className="rounded-xl overflow-hidden border border-slate-200 dark:border-slate-800">
              <img 
                src={getFileUrl('posts', post.id, Array.isArray(post.media) ? post.media[0] : post.media)} 
                alt="Post Media" 
                className="w-full max-h-80 object-cover" 
              />
            </div>
          )}

          <div className="border-t border-slate-100 dark:border-slate-800 pt-3">
            <h4 className="font-bold text-xs uppercase tracking-wider text-slate-400 mb-3">
              Respostas ({comments.length})
            </h4>

            {loading ? (
              <div className="flex justify-center py-6">
                <Loader2 className="w-6 h-6 animate-spin text-blue-500" />
              </div>
            ) : comments.length === 0 ? (
              <div className="text-center py-6 text-sm text-slate-400">
                Seja o primeiro a responder esta publicação!
              </div>
            ) : (
              <div className="space-y-3">
                {comments.map((c) => {
                  const cName = c.expand?.user?.name || c.expand?.user?.username || 'Usuário';
                  const cAvatar = getUserAvatar(c.expand?.user);
                  return (
                    <div key={c.id} className="flex space-x-2.5 text-sm">
                      <div className="w-8 h-8 rounded-full bg-slate-300 dark:bg-slate-700 font-bold flex items-center justify-center overflow-hidden flex-shrink-0 text-xs">
                        {cAvatar ? (
                          <img src={cAvatar} alt={cName} className="w-full h-full object-cover" />
                        ) : (
                          <span>{cName[0]?.toUpperCase() || 'U'}</span>
                        )}
                      </div>
                      <div className="flex-1 bg-slate-50 dark:bg-slate-800/60 p-2.5 rounded-xl border border-slate-100 dark:border-slate-800">
                        <div className="flex justify-between items-center mb-1">
                          <span className="font-bold text-xs text-slate-900 dark:text-white">{cName}</span>
                          <span className="text-[10px] text-slate-400">{formatRelativeTime(c.created)}</span>
                        </div>
                        <p className="text-xs text-slate-700 dark:text-slate-300">{c.comment}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>

        {/* REPLY INPUT */}
        <form onSubmit={handleSendComment} className="p-3 border-t border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 flex items-center space-x-2">
          <input
            type="text"
            value={commentText}
            onChange={(e) => setCommentText(e.target.value)}
            placeholder={currentUser ? "Postar sua resposta..." : "Faça login para responder..."}
            className="flex-1 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-full px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-900 dark:text-white"
          />
          <button
            type="submit"
            disabled={sending || !commentText.trim()}
            className="p-2.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white rounded-full transition shadow-sm"
          >
            {sending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
          </button>
        </form>
      </div>
    </div>
  );
};
