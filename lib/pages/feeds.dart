import 'package:cached_network_image/cached_network_image.dart';
import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ionicons/ionicons.dart';
import 'package:social_media_app/chats/recent_chats.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/posts/create_post.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/utils/i18n.dart';
import 'package:social_media_app/widgets/indicators.dart';
import 'package:social_media_app/widgets/story_widget.dart';
import 'package:social_media_app/widgets/userpost.dart';

class Feeds extends StatefulWidget {
  @override
  _FeedsState createState() => _FeedsState();
}

class _FeedsState extends State<Feeds> with AutomaticKeepAliveClientMixin{
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  int page = 5;
  bool loadingMore = false;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    scrollController.addListener(() async {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        setState(() {
          page = page + 5;
          loadingMore = true;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_dark.png',
              height: 28.0,
              width: 28.0,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
            const SizedBox(width: 8.0),
            Text(
              Constants.appName,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22.0,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, size: 22.0),
            tooltip: 'Idioma / Language / Idioma',
            onSelected: (lang) => I18n.setLang(lang),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'pt', child: Text('🇧🇷 Português')),
              PopupMenuItem(value: 'en', child: Text('🇺🇸 English')),
              PopupMenuItem(value: 'es', child: Text('🇪🇸 Español')),
            ],
          ),
          IconButton(
            icon: const Icon(
              CupertinoIcons.chat_bubble_2_fill,
              size: 24.0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => Chats(),
                ),
              );
            },
          ),
          const SizedBox(width: 10.0),
        ],
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        onRefresh: () =>
            postRef.orderBy('timestamp', descending: true).limit(page).get(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: FutureBuilder(
              future: postRef
                  .orderBy('timestamp', descending: true)
                  .limit(page)
                  .get(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  var snap = snapshot.data;
                  List docs = snap!.docs;
                  if (docs.isEmpty) {
                    return ListView(
                      children: [
                        StoryWidget(),
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            I18n.t('no_posts'),
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: docs.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return StoryWidget();
                      }
                      if (index == 1) {
                        return _buildInlineComposeBox(context);
                      }
                      PostModel posts =
                          PostModel.fromJson(docs[index - 2].data());
                      return UserPost(post: posts);
                    },
                  );
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return circularProgress(context);
                } else {
                  return ListView(
                    children: [
                      StoryWidget(),
                      _buildInlineComposeBox(context),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          I18n.t('no_posts'),
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineComposeBox(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFF1F5F9);
    final currentUid = firebaseAuth.currentUser?.uid ?? '';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: dividerColor, width: 2.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: currentUid.isNotEmpty ? usersRef.doc(currentUid).snapshots() : null,
                builder: (context, snapshot) {
                  String photoUrl = '';
                  String initial = 'U';
                  if (snapshot.hasData && snapshot.data?.data() != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    photoUrl = data['photoUrl'] ?? '';
                    final name = data['name'] ?? data['username'] ?? 'U';
                    if (name.isNotEmpty) initial = name[0].toUpperCase();
                  }

                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
                    backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            initial,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.text,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => CreatePost(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'O que está acontecendo na sua oficina ou empresa?',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => CreatePost(),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.photo, size: 18, color: Color(0xFF10B981)),
                label: const Text('Foto', style: TextStyle(color: Color(0xFF10B981), fontSize: 13)),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => CreatePost(),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.videocam_fill, size: 18, color: Color(0xFFF59E0B)),
                label: const Text('Vídeo', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13)),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => CreatePost(),
                    ),
                  );
                },
                icon: const Icon(Icons.mic, size: 18, color: Color(0xFF6366F1)),
                label: const Text('Voz', style: TextStyle(color: Color(0xFF6366F1), fontSize: 13)),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: const Color(0xFF2563EB),
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => CreatePost(),
                    ),
                  );
                },
                child: const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
