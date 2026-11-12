import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:social_media_app/chats/conversation.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/pages/profile.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/widgets/indicators.dart';

class Search extends StatefulWidget {
  final String? initialQuery;
  const Search({Key? key, this.initialQuery}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin {
  User? user;
  TextEditingController searchController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> users = [];
  List<DocumentSnapshot> filteredUsers = [];
  bool loading = true;

  String currentUserId() {
    return firebaseAuth.currentUser?.uid ?? '';
  }

  getUsers() async {
    try {
      QuerySnapshot snap = await usersRef.get();
      final myUid = currentUserId();
      List<DocumentSnapshot> doc = snap.docs.where((d) => d.id != myUid).toList();
      users = doc;
      if (searchController.text.trim().isNotEmpty) {
        search(searchController.text);
      } else {
        filteredUsers = doc;
      }
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('getUsers error: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        filteredUsers = users;
      });
    } else {
      List<DocumentSnapshot> userSearch = users.where((userSnap) {
        Map user = (userSnap.data() as Map<String, dynamic>?) ?? {};
        String userName = (user['username'] ?? '').toString().toLowerCase();
        String name = (user['name'] ?? '').toString().toLowerCase();
        String bio = (user['bio'] ?? '').toString().toLowerCase();
        return userName.contains(q) || name.contains(q) || bio.contains(q);
      }).toList();
      setState(() {
        filteredUsers = userSearch;
      });
    }
  }

  removeFromList(index) {
    if (index >= 0 && index < filteredUsers.length) {
      filteredUsers.removeAt(index);
    }
  }

  @override
  void initState() {
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      searchController.text = widget.initialQuery!;
    }
    getUsers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Buscar',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20.0,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        onRefresh: () => getUsers(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: buildSearch(isDark),
            ),
            buildUsers(),
          ],
        ),
      ),
    );
  }

  Widget buildSearch(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchController,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (query) {
                search(query);
              },
              decoration: InputDecoration(
                suffixIcon: searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          searchController.clear();
                          search('');
                        },
                        child: const Icon(
                          Ionicons.close_outline,
                          size: 16.0,
                          color: Colors.grey,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                hintText: 'Buscar técnicos, empresas ou tópicos...',
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  buildUsers() {
    if (loading) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: circularProgress(context),
      ));
    }

    if (filteredUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                "Nenhum técnico ou parceiro encontrado",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        itemCount: filteredUsers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          DocumentSnapshot doc = filteredUsers[index];
          UserModel user =
              UserModel.fromJson(doc.data() as Map<String, dynamic>);
          final uName = user.username ?? 'Técnico';
          final uHandle = user.username ?? 'user';
          final uBio = user.bio ?? user.country ?? 'Ecossistema ZenyDesk';
          final uPhoto = user.photoUrl ?? '';
          final uId = user.id ?? doc.id;

          return ListTile(
            onTap: () => showProfile(context, profileId: uId),
            leading: CircleAvatar(
              radius: 20.0,
              backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
              backgroundImage: uPhoto.isNotEmpty ? CachedNetworkImageProvider(uPhoto) : null,
              child: uPhoto.isEmpty
                  ? Text(
                      uName.isNotEmpty ? uName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              uName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '@$uHandle • $uBio',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.chat_bubble, size: 18, color: Color(0xFF2563EB)),
              tooltip: 'Iniciar Conversa',
              onPressed: () {
                final myUid = currentUserId();
                final list = [myUid, uId]..sort();
                final derivedChatId = '${list[0]}-${list[1]}';
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => Conversation(
                      userId: uId,
                      chatId: derivedChatId,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  showProfile(BuildContext context, {String? profileId}) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => Profile(profileId: profileId),
      ),
    );
  }

  //get concatenated list of users
  //this will help us query the chat id reference in other
  // to get the correct user id

  String getUser(String user1, String user2) {
    user1 = user1.substring(0, 5);
    user2 = user2.substring(0, 5);
    List<String> list = [user1, user2];
    list.sort();
    var chatId = "${list[0]}-${list[1]}";
    return chatId;
  }

  @override
  bool get wantKeepAlive => true;
}
