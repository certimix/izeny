export interface User {
  id: string;
  name: string;
  username: string;
  email: string;
  avatar?: string;
  bio?: string;
  country?: string;
  isOnline?: boolean;
  lastSeen?: string;
  created: string;
  updated: string;
}

export interface Post {
  id: string;
  owner: string;
  ownerId?: string;
  username?: string;
  description: string;
  location?: string;
  media?: string | string[];
  mediaUrl?: string;
  likes?: string[];
  created: string;
  updated: string;
  expand?: {
    owner?: User;
  };
}

export interface Comment {
  id: string;
  post: string;
  user: string;
  comment: string;
  created: string;
  updated: string;
  expand?: {
    user?: User;
  };
}

export interface Message {
  id: string;
  chat: string;
  sender: string;
  content: string;
  media?: string;
  type?: string;
  created: string;
  updated: string;
  expand?: {
    sender?: User;
  };
}

export interface Chat {
  id: string;
  users: string[];
  lastMessage?: string;
  lastMessageTime?: string;
  created: string;
  updated: string;
  expand?: {
    users?: User[];
  };
}

export interface NotificationItem {
  id: string;
  user: string;
  fromUser: string;
  post?: string;
  type: 'like' | 'comment' | 'follow' | 'message';
  read: boolean;
  created: string;
  updated: string;
  expand?: {
    fromUser?: User;
    post?: Post;
  };
}
