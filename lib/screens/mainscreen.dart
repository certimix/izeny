import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  Widget _getPage(int index, String currentUid) {
    switch (index) {
      case 0:
        return Feeds();
      case 1:
        return Chats();
      case 2:
        return Search();
      case 3:
        return Activities();
      case 4:
      default:
        return Profile(profileId: currentUid);
    }
  }

  void _openCreatePost() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => CreatePost(),
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
                _buildMobileNavItem(0, CupertinoIcons.house_fill, CupertinoIcons.house, 'Início'),
                _buildMobileNavItem(1, CupertinoIcons.chat_bubble_2_fill, CupertinoIcons.chat_bubble_2, 'Chat'),
                _buildMobileFabItem(),
                _buildMobileNavItem(3, CupertinoIcons.bell_fill, CupertinoIcons.bell, 'Avisos'),
                _buildMobileNavItem(4, CupertinoIcons.person_fill, CupertinoIcons.person, 'Perfil'),
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
            iconActive: CupertinoIcons.house_fill,
            iconInactive: CupertinoIcons.house,
            label: I18n.t('feeds'),
          ),
          _buildSidebarLink(
            index: 1,
            iconActive: CupertinoIcons.chat_bubble_2_fill,
            iconInactive: CupertinoIcons.chat_bubble_2,
            label: I18n.t('chats'),
          ),
          _buildSidebarLink(
            index: 2,
            iconActive: CupertinoIcons.search,
            iconInactive: CupertinoIcons.search,
            label: I18n.t('search'),
          ),
          _buildSidebarLink(
            index: 3,
            iconActive: CupertinoIcons.bell_fill,
            iconInactive: CupertinoIcons.bell,
            label: I18n.t('notifications'),
          ),
          _buildSidebarLink(
            index: 4,
            iconActive: CupertinoIcons.person_fill,
            iconInactive: CupertinoIcons.person,
            label: I18n.t('profile'),
          ),

          const SizedBox(height: 18.0),

          // Primary "Novo Post" Button (Twitter-Style)
          SizedBox(
            width: double.infinity,
            height: 46.0,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
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
                Icon(CupertinoIcons.search, size: 18, color: Colors.grey[400]),
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
                      setState(() => _page = 2);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Active Technicians & Partners Card
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
                                icon: const Icon(CupertinoIcons.chat_bubble_fill, size: 16, color: Color(0xFF2563EB)),
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
