import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ionicons/ionicons.dart';
import 'package:social_media_app/chats/recent_chats.dart';
import 'package:social_media_app/models/post.dart';
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
                    itemCount: docs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return StoryWidget();
                      }
                      PostModel posts =
                          PostModel.fromJson(docs[index - 1].data());
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        child: UserPost(post: posts),
                      );
                    },
                  );
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return circularProgress(context);
                } else {
                  return Center(
                    child: Text(
                      I18n.t('no_posts'),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
