import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:like_button/like_button.dart';
import 'package:social_media_app/components/voice_bubble.dart';
import 'package:social_media_app/components/video_bubble.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/pages/profile.dart';
import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:social_media_app/screens/comment.dart';
import 'package:social_media_app/screens/view_image.dart';
import 'package:social_media_app/services/post_service.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserPost extends StatelessWidget {
  final PostModel? post;

  UserPost({this.post});

  final PostService services = PostService();

  String currentUserId() {
    return firebaseAuth.currentUser?.uid ?? '';
  }

  bool _isAudio(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.webm') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.m4a') ||
        lower.contains('voice_');
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') && !lower.contains('voice_') ||
        lower.contains('video_');
  }

  @override
  Widget build(BuildContext context) {
    if (post == null) return const SizedBox();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFF1F5F9);

    final mediaUrl = post?.mediaUrl ?? '';
    final hasMedia = mediaUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: dividerColor, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Avatar (Left column)
          _buildAuthorAvatar(context),
          const SizedBox(width: 12.0),

          // Main Post Content (Right column)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Post Header: Name, @username, Location & Timeago
                _buildHeader(context),
                const SizedBox(height: 6.0),

                // 2. Post Description / Text
                if (post?.description != null && post!.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      post!.description!,
                      style: TextStyle(
                        fontSize: 15.0,
                        height: 1.4,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),

                // 3. Post Media (Photo, Voice Message, or Video)
                if (hasMedia) ...[
                  _buildMediaWidget(context, mediaUrl),
                  const SizedBox(height: 12.0),
                ],

                // 4. Action Icons Row (Like, Comment, Share)
                _buildActionsRow(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorAvatar(BuildContext context) {
    final ownerId = post?.ownerId ?? '';
    return StreamBuilder<DocumentSnapshot>(
      stream: ownerId.isNotEmpty ? usersRef.doc(ownerId).snapshots() : null,
      builder: (context, snapshot) {
        String photoUrl = '';
        String initial = 'U';

        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          photoUrl = data['photoUrl'] ?? '';
          final name = data['name'] ?? data['username'] ?? 'U';
          if (name.isNotEmpty) initial = name[0].toUpperCase();
        }

        return GestureDetector(
          onTap: () {
            if (ownerId.isNotEmpty) {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => Profile(profileId: ownerId),
                ),
              );
            }
          },
          child: CircleAvatar(
            radius: 20.0,
            backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
            backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final timeStr = post?.timestamp != null
        ? timeago.format(post!.timestamp!.toDate(), locale: 'pt_BR')
        : '';

    return Row(
      children: [
        Flexible(
          child: Text(
            post?.username ?? 'Técnico ZenyDesk',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6.0),
        if (post?.location != null && post!.location!.isNotEmpty && post!.location != 'IZeny') ...[
          Text(
            '• ${post!.location}',
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(width: 6.0),
        ],
        Text(
          '• $timeStr',
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaWidget(BuildContext context, String url) {
    if (_isAudio(url)) {
      return VoiceMessageBubble(
        audioUrl: url,
        isMe: false,
      );
    }

    if (_isVideo(url)) {
      return VideoMessageBubble(
        videoUrl: url,
        isMe: false,
      );
    }

    // Default: Image / Photo
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => ViewImage(post: post),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 200,
              color: Colors.grey.withOpacity(0.12),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => const SizedBox(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Comment Button
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => Comments(post: post),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 18.0,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6.0),
                StreamBuilder<QuerySnapshot>(
                  stream: commentRef
                      .doc(post!.id!)
                      .collection("comments")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        "${snapshot.data?.docs.length ?? 0}",
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                    return Text(
                      "0",
                      style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // 2. Like Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: likesRef
                .where('postId', isEqualTo: post!.postId)
                .where('userId', isEqualTo: currentUserId())
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              final docs = snapshot.hasData ? (snapshot.data?.docs ?? []) : [];
              final isLiked = docs.isNotEmpty;

              return StreamBuilder<QuerySnapshot>(
                stream: likesRef.where('postId', isEqualTo: post!.postId).snapshots(),
                builder: (context, snapshotCount) {
                  final likeCount = snapshotCount.hasData ? (snapshotCount.data?.docs.length ?? 0) : 0;
                  return Row(
                    children: [
                      LikeButton(
                        size: 18.0,
                        circleColor: const CircleColor(
                          start: Color(0xffe11d48),
                          end: Color(0xffbe123c),
                        ),
                        bubblesColor: const BubblesColor(
                          dotPrimaryColor: Color(0xffe11d48),
                          dotSecondaryColor: Color(0xffbe123c),
                        ),
                        isLiked: isLiked,
                        likeBuilder: (bool isLiked) {
                          return Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? const Color(0xffe11d48) : Colors.grey[600],
                            size: 18.0,
                          );
                        },
                        onTap: (bool isLiked) async {
                          if (isLiked) {
                            if (docs.isNotEmpty) {
                              likesRef.doc(docs[0].id).delete();
                            }
                            services.removeLikeFromNotification(
                              post!.ownerId!,
                              post!.postId!,
                              currentUserId(),
                            );
                          } else {
                            likesRef.add({
                              'userId': currentUserId(),
                              'postId': post!.postId,
                              'dateCreated': Timestamp.now(),
                            });
                            _addLikeNotification();
                          }
                          return !isLiked;
                        },
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        "$likeCount",
                        style: TextStyle(
                          fontSize: 12.0,
                          color: isLiked ? const Color(0xffe11d48) : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),

        // 3. Share / Copy Link Button
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link da publicação copiado!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Icon(
              Icons.share_outlined,
              size: 17.0,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  void _addLikeNotification() async {
    bool isNotMe = currentUserId() != post!.ownerId;
    if (isNotMe) {
      DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
      if (doc.data() != null) {
        UserModel user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
        services.addLikesToNotification(
          "like",
          user.username ?? '',
          currentUserId(),
          post!.postId ?? '',
          post!.mediaUrl ?? '',
          post!.ownerId ?? '',
          user.photoUrl ?? '',
        );
      }
    }
  }
}
