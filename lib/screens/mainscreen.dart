import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/chats/conversation.dart';
import 'package:social_media_app/chats/recent_chats.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/pages/feeds.dart';
import 'package:social_media_app/pages/notification.dart';
import 'package:social_media_app/pages/profile.dart';
import 'package:social_media_app/pages/search.dart';
import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:social_media_app/posts/create_post.dart';
import 'package:social_media_app/services/post_service.dart';
import 'package:social_media_app/utils/download_helper.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/utils/i18n.dart';
import 'package:social_media_app/view_models/user/user_view_model.dart';

class TabScreen extends StatefulWidget {
  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  int _page = 0;
  String? _activeSearchQuery;

  Widget _getPage(int index, String currentUid) {
    switch (index) {
      case 0:
        return Feeds(onOpenChats: () => setState(() => _page = 1));
      case 1:
        return const Chats();
      case 2:
        return Search(initialQuery: _activeSearchQuery);
      case 3:
        return Activities();
      case 4:
      default:
        return Profile(profileId: currentUid);
    }
  }

  void _openCreatePost() {
    showDialog(
      context: context,
      builder: (ctx) => _CreatePostDialog(
        onPostCreated: () {
          setState(() {
            _page = 0;
          });
        },
      ),
    );
  }

  void _openChatWithUser(String targetUserId) {
    final currentUid = firebaseAuth.currentUser?.uid ?? '';
    final list = [currentUid, targetUserId]..sort();
    final derivedChatId = '${list[0]}-${list[1]}';
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => Conversation(
          userId: targetUserId,
          chatId: derivedChatId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = firebaseAuth.currentUser?.uid ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    if (isDesktop) {
      return Scaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LEFT SIDEBAR (Desktop)
                SizedBox(
                  width: screenWidth >= 1200 ? 270 : 220,
                  child: _buildDesktopSidebar(context, isDark, currentUid),
                ),

                // 2. CENTER CONTENT (Feed / Active Tab)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: dividerColor, width: 1),
                        right: BorderSide(color: dividerColor, width: 1),
                      ),
                    ),
                    child: _getPage(_page, currentUid),
                  ),
                ),

                // 3. RIGHT WIDGET PANEL (Desktop)
                SizedBox(
                  width: screenWidth >= 1200 ? 330 : 280,
                  child: _buildDesktopRightPanel(context, isDark),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // MOBILE / TABLET LAYOUT (< 960px)
    return Scaffold(
      body: _getPage(_page, currentUid),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: dividerColor, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMobileNavItem(0, Icons.home, Icons.home_outlined, 'Início'),
                _buildMobileNavItem(1, Icons.chat_bubble, Icons.chat_bubble_outline, 'Chat'),
                _buildMobileFabItem(),
                _buildMobileNavItem(3, Icons.notifications, Icons.notifications_none, 'Avisos'),
                _buildMobileNavItem(4, Icons.person, Icons.person_outline, 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DESKTOP SIDEBAR ---
  Widget _buildDesktopSidebar(BuildContext context, bool isDark, String currentUid) {
    final theme = Theme.of(context);
    final primaryBlue = const Color(0xFF2563EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Official Transparent Logo Mark
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 24.0, top: 4.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _page = 0),
                child: Image.asset(
                  isDark ? 'assets/images/logo_white.png' : 'assets/images/logo_dark.png',
                  height: 42.0,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Navigation Links
          _buildSidebarLink(
            index: 0,
            iconActive: Icons.home,
            iconInactive: Icons.home_outlined,
            label: I18n.t('feeds'),
          ),
          _buildSidebarLink(
            index: 1,
            iconActive: Icons.chat_bubble,
            iconInactive: Icons.chat_bubble_outline,
            label: I18n.t('chats'),
          ),
          _buildSidebarLink(
            index: 2,
            iconActive: Icons.search,
            iconInactive: Icons.search,
            label: I18n.t('search'),
          ),
          _buildSidebarLink(
            index: 3,
            iconActive: Icons.notifications,
            iconInactive: Icons.notifications_none,
            label: I18n.t('notifications'),
          ),
          _buildSidebarLink(
            index: 4,
            iconActive: Icons.person,
            iconInactive: Icons.person_outline,
            label: I18n.t('profile'),
          ),

          const SizedBox(height: 18.0),

          // Primary "Novo Post" Button (Twitter-Style)
          SizedBox(
            width: double.infinity,
            height: 46.0,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                primary: primaryBlue,
                onPrimary: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
              ),
              onPressed: _openCreatePost,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: Text(
                I18n.t('create_post'),
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Authenticated User Profile Card at bottom
          _buildCurrentUserCard(context, currentUid, isDark),
        ],
      ),
    );
  }

  Widget _buildSidebarLink({
    required int index,
    required IconData iconActive,
    required IconData iconInactive,
    required String label,
  }) {
    final isSelected = _page == index;
    final primaryBlue = const Color(0xFF2563EB);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: isSelected
            ? primaryBlue.withOpacity(0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(24.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(24.0),
          onTap: () => setState(() => _page = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  isSelected ? iconActive : iconInactive,
                  size: 24.0,
                  color: isSelected ? primaryBlue : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                ),
                const SizedBox(width: 14.0),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? primaryBlue : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard(BuildContext context, String uid, bool isDark) {
    if (uid.isEmpty) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: usersRef.doc(uid).snapshots(),
      builder: (context, snapshot) {
        String name = 'Minha Conta';
        String username = '@usuario';
        String photoUrl = '';

        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? data['username'] ?? 'Usuário';
          username = '@${data['username'] ?? 'user'}';
          photoUrl = data['photoUrl'] ?? '';
        }

        return Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.15),
                backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      username,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                tooltip: 'Sair da Conta',
                onPressed: () async {
                  await firebaseAuth.signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DESKTOP RIGHT PANEL ---
  Widget _buildDesktopRightPanel(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Quick Search Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: Colors.grey[400]),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar na rede...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        setState(() {
                          _activeSearchQuery = val.trim();
                          _page = 2;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Tópicos & Tendências Card (Trending Topics)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tag, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    const Text(
                      'Tópicos & Tendências',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTopicItem(
                  topic: '#zenydesk',
                  category: 'Ecossistema & Comunidade',
                  count: '128 posts',
                ),
                _buildTopicItem(
                  topic: '#dicas_tecnicas',
                  category: 'Bancada, Placas & Hardware',
                  count: '94 posts',
                ),
                _buildTopicItem(
                  topic: '#ti_ajuda',
                  category: 'Dúvidas Técnicas & Redes',
                  count: '76 posts',
                ),
                _buildTopicItem(
                  topic: '#suporte_direto',
                  category: 'Atendimento Especializado',
                  count: '52 posts',
                ),
                _buildTopicItem(
                  topic: '#ordem_servico',
                  category: 'Gestão e Laudos Map-OS',
                  count: '41 posts',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Active Technicians & Partners Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Técnicos & Parceiros',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<QuerySnapshot>(
                  future: usersRef.limit(4).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ));
                    }
                    final users = snapshot.data!.docs;
                    final currentUid = firebaseAuth.currentUser?.uid;

                    return Column(
                      children: users.map((doc) {
                        final u = UserModel.fromJson(doc.data() as Map<String, dynamic>);
                        if (u.id == currentUid) return const SizedBox();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
                                backgroundImage: (u.photoUrl != null && u.photoUrl!.isNotEmpty)
                                    ? CachedNetworkImageProvider(u.photoUrl!)
                                    : null,
                                child: (u.photoUrl == null || u.photoUrl!.isEmpty)
                                    ? Text(
                                        u.username != null && u.username!.isNotEmpty
                                            ? u.username![0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB)),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u.username ?? 'Técnico',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      u.country ?? 'ZenyDesk',
                                      style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble, size: 16, color: Color(0xFF2563EB)),
                                tooltip: 'Enviar Mensagem Direta',
                                onPressed: () => _openChatWithUser(u.id!),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Quick Ecosystem Links Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ecossistema ZenyDesk',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildEcosystemItem(
                  icon: Icons.assignment_outlined,
                  title: 'ZenyDesk O.S.',
                  subtitle: 'Ordens de Serviço e Laudos',
                  url: 'https://os.zenydesk.com',
                ),
                _buildEcosystemItem(
                  icon: Icons.storefront_outlined,
                  title: 'ZenyDesk ERP',
                  subtitle: 'Gestão Fiscal e Financeira',
                  url: 'https://erp.zenydesk.com',
                ),
                _buildEcosystemItem(
                  icon: Icons.android_rounded,
                  title: 'App Android Oficial',
                  subtitle: 'Baixar instalador .apk direto',
                  url: 'https://izeny.zenydesk.com/downloads/IZeny.apk',
                  isApk: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Canonical Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '© 2026 IZeny • Rede Social e Comunidade',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Desenvolvido por AORDIC.COM.BR',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFF7931A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicItem({
    required String topic,
    required String category,
    required String count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _activeSearchQuery = topic;
            _page = 2;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Text(
                      category,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                count,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEcosystemItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
    bool isApk = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (isApk) {
            downloadApk();
          } else {
            // Can be opened in new tab on web
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MOBILE BOTTOM NAVIGATION ITEMS ---
  Widget _buildMobileNavItem(int index, IconData iconActive, IconData iconInactive, String label) {
    final isSelected = _page == index;
    final primaryBlue = const Color(0xFF2563EB);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _page = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconActive : iconInactive,
              size: 22,
              color: isSelected ? primaryBlue : Colors.grey[500],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryBlue : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFabItem() {
    return GestureDetector(
      onTap: _openCreatePost,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFF2563EB),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x402563EB),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

class _CreatePostDialog extends StatefulWidget {
  final VoidCallback onPostCreated;
  const _CreatePostDialog({Key? key, required this.onPostCreated}) : super(key: key);

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _mediaUrl;
  String? _mediaName;
  bool _uploading = false;
  bool _publishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() => _uploading = true);
      final bytes = await file.readAsBytes();
      final url = await PBClient.uploadBytes(
        bytes,
        file.name,
        collection: 'posts',
        field: 'media',
      );

      setState(() {
        _uploading = false;
        if (url.isNotEmpty) {
          _mediaUrl = url;
          _mediaName = file.name;
        }
      });
    } catch (e) {
      setState(() => _uploading = false);
      debugPrint('Dialog pick image error: $e');
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _mediaUrl == null) return;

    setState(() => _publishing = true);
    final ok = await PostService().createPostRaw(
      description: text,
      mediaUrl: _mediaUrl,
    );
    setState(() => _publishing = false);

    if (ok) {
      Navigator.of(context).pop();
      widget.onPostCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicação criada com sucesso!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUid = firebaseAuth.currentUser?.uid ?? '';
    final primaryBlue = const Color(0xFF2563EB);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nova Publicação',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 16),
              StreamBuilder<DocumentSnapshot>(
                stream: currentUid.isNotEmpty ? usersRef.doc(currentUid).snapshots() : null,
                builder: (context, snapshot) {
                  String name = 'Minha Conta';
                  String username = '@usuario';
                  String photoUrl = '';
                  if (snapshot.hasData && snapshot.data?.data() != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    name = data['name'] ?? data['username'] ?? 'Usuário';
                    username = '@${data['username'] ?? 'user'}';
                    photoUrl = data['photoUrl'] ?? '';
                  }
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryBlue.withOpacity(0.12),
                        backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(width: 6),
                      Text(username, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  minLines: 2,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'O que está acontecendo na sua oficina ou empresa?',
                    hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_uploading) ...[
                const SizedBox(height: 10),
                Row(
                  children: const [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Enviando imagem anexa...', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                  ],
                ),
              ],
              if (_mediaUrl != null && _mediaUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
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
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          _mediaName ?? 'Imagem anexada',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() {
                          _mediaUrl = null;
                          _mediaName = null;
                        }),
                        child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _uploading ? null : _pickImage,
                    icon: const Icon(Icons.image_outlined, size: 18, color: Color(0xFF10B981)),
                    label: const Text('Foto', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: primaryBlue,
                      onPrimary: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: _publishing ? null : _submit,
                    child: _publishing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
