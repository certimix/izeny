import 'package:cached_network_image/cached_network_image.dart';
import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:social_media_app/chats/recent_chats.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/posts/create_post.dart';
import 'package:social_media_app/services/post_service.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/utils/i18n.dart';
import 'package:social_media_app/widgets/indicators.dart';
import 'package:social_media_app/widgets/story_widget.dart';
import 'package:social_media_app/widgets/userpost.dart';

class Feeds extends StatefulWidget {
  final VoidCallback? onOpenChats;
  const Feeds({Key? key, this.onOpenChats}) : super(key: key);

  @override
  _FeedsState createState() => _FeedsState();
}

class _FeedsState extends State<Feeds> with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  int page = 10;
  bool loadingMore = false;
  final ScrollController scrollController = ScrollController();
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _attachedMediaUrl;
  String? _attachedMediaName;
  bool _isUploadingAttachment = false;
  bool _isPublishing = false;

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
  void dispose() {
    _postController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImageAttachment() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() {
        _isUploadingAttachment = true;
      });

      final bytes = await file.readAsBytes();
      final url = await PBClient.uploadBytes(
        bytes,
        file.name,
        collection: 'posts',
        field: 'media',
      );

      setState(() {
        _isUploadingAttachment = false;
        if (url.isNotEmpty) {
          _attachedMediaUrl = url;
          _attachedMediaName = file.name;
        }
      });
    } catch (e) {
      debugPrint('Error picking attachment: $e');
      setState(() {
        _isUploadingAttachment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao anexar imagem: $e')),
      );
    }
  }

  Future<void> _handlePublish() async {
    final text = _postController.text.trim();
    if (text.isEmpty && _attachedMediaUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite uma mensagem ou anexe uma foto antes de publicar.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    final success = await PostService().createPostRaw(
      description: text,
      mediaUrl: _attachedMediaUrl,
    );

    setState(() {
      _isPublishing = false;
    });

    if (success) {
      _postController.clear();
      setState(() {
        _attachedMediaUrl = null;
        _attachedMediaName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicação realizada com sucesso!'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao publicar. Verifique sua conexão.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Feed',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20.0,
            letterSpacing: -0.3,
          ),
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
              Icons.chat_bubble,
              size: 24.0,
            ),
            tooltip: 'Mensagens',
            onPressed: () {
              if (widget.onOpenChats != null) {
                widget.onOpenChats!();
              } else {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => Chats(),
                  ),
                );
              }
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
                        const StoryWidget(),
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
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: docs.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const StoryWidget();
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
                      const StoryWidget(),
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
    final primaryBlue = const Color(0xFF2563EB);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          bottom: BorderSide(color: dividerColor, width: 2.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    backgroundColor: primaryBlue.withOpacity(0.12),
                    backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            initial,
                            style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue),
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _postController,
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'O que está acontecendo na sua oficina ou empresa?',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_isUploadingAttachment) ...[
            const SizedBox(height: 10),
            Row(
              children: const [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Enviando imagem anexa...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ],

          if (_attachedMediaUrl != null && _attachedMediaUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 52.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryBlue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        _attachedMediaName ?? 'Imagem anexada',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _attachedMediaUrl = null;
                          _attachedMediaName = null;
                        });
                      },
                      child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 52.0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _isUploadingAttachment ? null : _pickImageAttachment,
                  icon: const Icon(Icons.image_outlined, size: 18, color: Color(0xFF10B981)),
                  label: const Text('Foto', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: primaryBlue,
                    onPrimary: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    elevation: 0,
                  ),
                  onPressed: _isPublishing ? null : _handlePublish,
                  child: _isPublishing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Publicar',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
